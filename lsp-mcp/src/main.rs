//! den LSP enumeration MCP server (stdio).
//!
//! A thin, read-only Model Context Protocol server that exposes the den/gen API surface to agents so they
//! stop hallucinating den options and gen-lib signatures. It embeds NO Nix evaluator: every tool drives the
//! customer's own `nix` (resolved from `PATH`) as a subprocess (see `tools.rs`), which is what keeps the
//! enumeration correct for every customer on any interpreter (CppNix, Lix, …).
//!
//! Transport: MCP stdio = newline-delimited JSON-RPC 2.0. One complete JSON message per line on stdin;
//! one response line per request on stdout; diagnostics on stderr. Notifications (no `id`) get no response.

mod tools;

use serde_json::{json, Value};
use std::io::{self, BufRead, Write};
use tools::{tool_result_err, tool_result_ok, BuildErr, Server};

fn main() {
    let server = Server {
        fleet: parse_fleet(),
    };
    let stdin = io::stdin();
    let stdout = io::stdout();
    let mut out = stdout.lock();

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        let msg: Value = match serde_json::from_str(trimmed) {
            Ok(v) => v,
            Err(e) => {
                write_msg(
                    &mut out,
                    &json!({
                        "jsonrpc": "2.0",
                        "id": Value::Null,
                        "error": { "code": -32700, "message": format!("parse error: {e}") }
                    }),
                );
                continue;
            }
        };
        if let Some(response) = server_handle(&server, &msg) {
            write_msg(&mut out, &response);
        }
    }
}

/// Dispatch one JSON-RPC message. Returns `Some(response)` for a request (has `id`), `None` for a
/// notification (no `id`) or a message with no `method` (e.g. a stray response).
fn server_handle(server: &Server, msg: &Value) -> Option<Value> {
    let method = msg.get("method").and_then(Value::as_str)?;
    let id = msg.get("id").cloned();
    match method {
        "initialize" => id.map(|id| ok(id, initialize_result(msg))),
        // Lifecycle / control notifications carry no id → no response.
        "notifications/initialized" | "notifications/cancelled" => None,
        "ping" => id.map(|id| ok(id, json!({}))),
        "tools/list" => id.map(|id| ok(id, json!({ "tools": Server::tool_definitions() }))),
        "tools/call" => id.map(|id| tools_call(server, id, msg)),
        _ => id.map(|id| err(id, -32601, format!("method not found: {method}"))),
    }
}

/// The `initialize` result (MCP lifecycle). Version negotiation per spec: if the client sent a protocol
/// version we serve, echo it (the envelope here — `initialize` / `tools/list` / `tools/call` — is stable
/// across 2024-11-05 … 2025-06-18); otherwise advertise the latest we know. `capabilities.tools.listChanged`
/// is `false` — the tool list is static, so we never emit `notifications/tools/list_changed`.
fn initialize_result(msg: &Value) -> Value {
    // The protocol versions whose envelope this server serves; the first is the latest (default).
    const SUPPORTED: [&str; 3] = ["2025-06-18", "2025-03-26", "2024-11-05"];
    let requested = msg
        .pointer("/params/protocolVersion")
        .and_then(Value::as_str);
    let version = match requested {
        Some(v) if SUPPORTED.contains(&v) => v,
        _ => SUPPORTED[0],
    };
    json!({
        "protocolVersion": version,
        "capabilities": { "tools": { "listChanged": false } },
        "serverInfo": {
            "name": "den-lsp-mcp",
            "title": "den LSP enumeration",
            "version": env!("CARGO_PKG_VERSION")
        },
        "instructions": "Enumeration tools for a den fleet's den/gen API surface. Call den_schema to discover valid den.* option paths, den_aspects_list for declared aspects and their settings, and gen_lib_signature for gen-lib member names and formals — instead of guessing the den/gen API. All are read-only and evaluate the customer's own `nix`."
    })
}

/// Run a `tools/call`. Unknown tool → JSON-RPC `-32602`; a bad-args / no-fleet / `nix eval` failure → an
/// `isError` tool result (visible to the model); success → the projection JSON.
fn tools_call(server: &Server, id: Value, msg: &Value) -> Value {
    let name = msg
        .pointer("/params/name")
        .and_then(Value::as_str)
        .unwrap_or("");
    let args = msg
        .pointer("/params/arguments")
        .cloned()
        .unwrap_or_else(|| json!({}));
    let expr = match server.build_expr(name, &args) {
        Ok(expr) => expr,
        Err(BuildErr::UnknownTool) => return err(id, -32602, format!("unknown tool: {name}")),
        Err(BuildErr::BadArgs(m)) => return ok(id, tool_result_err(m)),
        Err(BuildErr::NoFleet) => {
            return ok(
                id,
                tool_result_err(
                    "no fleet configured: pass --fleet <flake-ref> or set DEN_FLEET".into(),
                ),
            )
        }
    };
    match server.nix_eval(&expr) {
        Ok(value) => ok(id, tool_result_ok(value)),
        Err(e) => ok(id, tool_result_err(e)),
    }
}

/// Read the fleet reference from `--fleet <ref>` / `--fleet=<ref>`, falling back to the `DEN_FLEET` env var.
fn parse_fleet() -> Option<String> {
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        if arg == "--fleet" {
            return args.next();
        }
        if let Some(rest) = arg.strip_prefix("--fleet=") {
            return Some(rest.to_string());
        }
    }
    std::env::var("DEN_FLEET").ok()
}

fn ok(id: Value, result: Value) -> Value {
    json!({ "jsonrpc": "2.0", "id": id, "result": result })
}

fn err(id: Value, code: i64, message: String) -> Value {
    json!({ "jsonrpc": "2.0", "id": id, "error": { "code": code, "message": message } })
}

/// Write one JSON-RPC message as a single stdout line (MCP stdio framing), then flush.
fn write_msg(out: &mut impl Write, msg: &Value) {
    let _ = writeln!(out, "{}", serde_json::to_string(msg).unwrap_or_default());
    let _ = out.flush();
}
