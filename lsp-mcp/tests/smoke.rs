//! MCP protocol smoke test (the SERVER side; the Nix-side JSON contract is `ci/tests/lsp-mcp-enumerate.nix`).
//!
//! Starts the built server pointed at a SYNTHETIC no-input fleet flake (a hermetic `den-lsp.enumerate` stub
//! — no network, no gen fetch), drives the full MCP handshake over stdio, and asserts the responses match the
//! MCP wire shapes (spec 2025-06-18): `initialize` (InitializeResult), `tools/list` (Tool objects with
//! JSON-Schema inputSchema), and a `tools/call` per tool (CallToolResult: `content` text block +
//! `structuredContent`, `isError`) — each returning the projection JSON via a REAL `nix eval` subprocess.
//! Also checks the two error mechanisms: a protocol JSON-RPC error (unknown tool) and an `isError` tool
//! result (missing arg).
//!
//! Requires `nix` on PATH (agnostic — the same subprocess the tools drive in production).

use serde_json::{json, Value};
use std::collections::HashMap;
use std::io::{Read, Write};
use std::process::{Command, Stdio};

/// A synthetic fleet flake: no inputs (hermetic — `builtins.getFlake` on it fetches nothing), exposing the
/// `den-lsp.enumerate` shape `den.lib.lsp.forNixdJSON` produces (beside the `den-lsp.options` nixd surface),
/// so the server's real `nix eval` returns structured JSON without evaluating a full den fleet.
const SYNTH_FLAKE: &str = r#"{
  outputs = _: {
    den-lsp = {
      # options = the raw nixd surface (function-carrying; the MCP server does NOT read it) — a placeholder
      # here since a stub cannot carry the real projection's functions.
      options = { };
      enumerate = {
        den = {
          host = { _type = "option"; description = "host instances"; type = "attrsOf"; };
          aspects = { _type = "option"; description = "Aspects"; type = "aspectsRoot"; };
        };
        "den-aspects" = {
          webby = {
            _type = "option"; description = "the web aspect"; type = "submodule";
            settings = {
              port = { _type = "option"; default = 80; description = ""; type = "raw"; };
            };
          };
        };
        gen = {
          select = {
            entity = { _type = "option"; description = ""; formals = {}; };
          };
        };
      };
    };
  };
}
"#;

fn write_synth_flake() -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(format!("den-lsp-mcp-smoke-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).expect("create temp flake dir");
    std::fs::write(dir.join("flake.nix"), SYNTH_FLAKE).expect("write flake.nix");
    dir
}

/// Drive the server: write every request/notification, close stdin, read all responses, index by `id`.
fn run_session(fleet: &std::path::Path, messages: &[Value]) -> HashMap<i64, Value> {
    let bin = env!("CARGO_BIN_EXE_lsp-mcp");
    let mut child = Command::new(bin)
        .arg("--fleet")
        .arg(fleet)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
        .expect("spawn lsp-mcp");

    {
        let mut stdin = child.stdin.take().expect("child stdin");
        for m in messages {
            writeln!(stdin, "{}", serde_json::to_string(m).unwrap()).expect("write request");
        }
        stdin.flush().expect("flush");
        // Drop stdin → EOF → the server loop ends after processing every buffered message.
    }

    let mut raw = String::new();
    child
        .stdout
        .take()
        .expect("child stdout")
        .read_to_string(&mut raw)
        .expect("read responses");
    child.wait().expect("wait child");

    let mut by_id = HashMap::new();
    for line in raw.lines().filter(|l| !l.trim().is_empty()) {
        let v: Value = serde_json::from_str(line).expect("response is valid JSON");
        if let Some(id) = v.get("id").and_then(Value::as_i64) {
            by_id.insert(id, v);
        }
    }
    by_id
}

#[test]
fn mcp_handshake_and_tools() {
    let fleet = write_synth_flake();
    let responses = run_session(
        &fleet,
        &[
            json!({ "jsonrpc": "2.0", "id": 1, "method": "initialize",
                    "params": { "protocolVersion": "2024-11-05", "capabilities": {},
                                "clientInfo": { "name": "smoke", "version": "0" } } }),
            json!({ "jsonrpc": "2.0", "method": "notifications/initialized" }),
            json!({ "jsonrpc": "2.0", "id": 2, "method": "tools/list" }),
            json!({ "jsonrpc": "2.0", "id": 3, "method": "tools/call",
                    "params": { "name": "den_schema", "arguments": {} } }),
            json!({ "jsonrpc": "2.0", "id": 4, "method": "tools/call",
                    "params": { "name": "den_aspects_list", "arguments": {} } }),
            json!({ "jsonrpc": "2.0", "id": 5, "method": "tools/call",
                    "params": { "name": "gen_lib_signature",
                                "arguments": { "lib": "select", "member": "entity" } } }),
            json!({ "jsonrpc": "2.0", "id": 6, "method": "tools/call",
                    "params": { "name": "does_not_exist", "arguments": {} } }),
            json!({ "jsonrpc": "2.0", "id": 7, "method": "tools/call",
                    "params": { "name": "gen_lib_signature", "arguments": {} } }),
        ],
    );

    let _ = std::fs::remove_dir_all(&fleet);

    // Every response is a well-formed JSON-RPC 2.0 envelope echoing its request id.
    for id in [1, 2, 3, 4, 5, 6, 7] {
        let r = &responses[&id];
        assert_eq!(r["jsonrpc"], "2.0", "jsonrpc version on id {id}");
        assert_eq!(r["id"], json!(id), "id echoed on id {id}");
    }

    // initialize → InitializeResult: version negotiated to the client's (we serve it), the tools capability
    // present with listChanged=false (static list), and serverInfo identifying the server.
    let init = &responses[&1]["result"];
    assert_eq!(
        init["protocolVersion"], "2024-11-05",
        "server echoes the client's supported protocol version"
    );
    assert_eq!(
        init["capabilities"]["tools"]["listChanged"],
        json!(false),
        "tools.listChanged is false (static tool list)"
    );
    assert_eq!(init["serverInfo"]["name"], "den-lsp-mcp", "serverInfo.name");
    assert!(
        init["serverInfo"]["version"].is_string(),
        "serverInfo.version is a string"
    );

    // tools/list → the 3 Tool objects, each with name/description and a JSON-Schema object inputSchema.
    let tools = responses[&2]["result"]["tools"]
        .as_array()
        .expect("tools array");
    let mut names: Vec<&str> = tools.iter().map(|t| t["name"].as_str().unwrap()).collect();
    names.sort_unstable();
    assert_eq!(
        names,
        ["den_aspects_list", "den_schema", "gen_lib_signature"],
        "the 3 tools (underscore wire names — MCP name regex `^[a-zA-Z0-9_-]+$`)"
    );
    for t in tools {
        // Wire name conforms to the MCP / Anthropic tool-name regex `^[a-zA-Z0-9_-]{1,128}$` (a dotted
        // name would be rejected by Claude/agents, the intended clients).
        let name = t["name"].as_str().expect("tool name is a string");
        assert!(
            !name.is_empty()
                && name.len() <= 128
                && name
                    .chars()
                    .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-'),
            "tool name {name:?} is MCP-conformant (dot-free)"
        );
        assert!(t["description"].is_string(), "tool has a description");
        assert_eq!(
            t["inputSchema"]["type"], "object",
            "inputSchema is a JSON-Schema object"
        );
        assert!(
            t["inputSchema"]["properties"].is_object(),
            "inputSchema has a properties object"
        );
    }
    // gen_lib_signature declares `lib` required in its input schema.
    let gen_tool = tools
        .iter()
        .find(|t| t["name"] == "gen_lib_signature")
        .unwrap();
    assert_eq!(
        gen_tool["inputSchema"]["required"],
        json!(["lib"]),
        "gen_lib_signature requires `lib`"
    );

    // Assert a successful CallToolResult is spec-shaped: a text content block whose text parses back to the
    // same JSON as structuredContent (the backwards-compat serialized-JSON block the spec asks for), and the
    // expected projected value inside it. Applied to all three tools.
    let check_ok = |result: &Value, probe: &dyn Fn(&Value)| {
        assert_eq!(result["isError"], json!(false), "not an error");
        let content = result["content"].as_array().expect("content array");
        assert_eq!(content[0]["type"], "text", "first content block is text");
        let text = content[0]["text"].as_str().expect("text is a string");
        let parsed: Value = serde_json::from_str(text).expect("content text is JSON");
        assert_eq!(
            parsed, result["structuredContent"],
            "text block mirrors structuredContent"
        );
        probe(&result["structuredContent"]);
    };

    // den_schema → the option tree; den.host projected with its type name.
    check_ok(&responses[&3]["result"], &|sc| {
        assert_eq!(sc["host"]["type"], "attrsOf", "den.host projected");
    });
    // den_aspects_list → the quoted "den-aspects" selector resolves; settings + scalar default present.
    check_ok(&responses[&4]["result"], &|sc| {
        assert_eq!(
            sc["webby"]["settings"]["port"]["default"],
            json!(80),
            "aspect setting default projected"
        );
    });
    // gen_lib_signature select.entity → a member signature carrying formals.
    check_ok(&responses[&5]["result"], &|sc| {
        assert!(sc["formals"].is_object(), "member formals projected");
    });

    // Unknown tool → a JSON-RPC protocol error (-32602 with a message), and NO `result` member.
    let unknown = &responses[&6];
    assert_eq!(
        unknown["error"]["code"],
        json!(-32602),
        "unknown tool → invalid params"
    );
    assert!(
        unknown["error"]["message"].is_string(),
        "protocol error carries a message"
    );
    assert!(
        unknown.get("result").is_none(),
        "protocol error has no result"
    );

    // Missing required `lib` arg → an isError tool result (a text block), the model-visible error channel.
    let bad = &responses[&7]["result"];
    assert_eq!(bad["isError"], json!(true), "missing arg → isError result");
    assert_eq!(
        bad["content"][0]["type"], "text",
        "isError result still carries a text content block"
    );
}
