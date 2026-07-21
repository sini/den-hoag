//! The three enumeration tools + the `nix` invocation.
//!
//! LOAD-BEARING design principle: **interpreter-agnostic — drive the customer's `nix`, don't embed one.**
//! Every tool shells out to `nix` resolved from `PATH` (CppNix, Lix, or any other interpreter the customer
//! uses), so the enumeration always matches the customer's own evaluator. We NEVER reference a specific
//! interpreter binary or path. Each tool builds a selector expression into the fleet's `den-lsp.enumerate`
//! output (`den.lib.lsp.forNixdJSON`, the JSON-safe enumeration view of the projections) and runs
//! `nix eval --impure --json --expr '<expr>'`, returning the parsed JSON.
//!
//! This server is a DUMB THIN TRANSPORT: it holds no projection logic. All shaping lives in the lib's two
//! views of one projection — `forNixd` (functions intact, for nixd's in-process C++ walk) and `forNixdJSON`
//! (wire-serializable, what this server serves). The server only shells `nix eval --json` and passes bytes.

use serde_json::{json, Value};
use std::process::Command;

/// The configured enumeration server: the customer's fleet reference (a flake ref / path) the tools
/// evaluate the `den-lsp.enumerate` output over.
pub struct Server {
    pub fleet: Option<String>,
}

/// Why building a tool's expression failed — distinguishes a protocol error (unknown tool → JSON-RPC error)
/// from a tool-execution error (bad args / no fleet → an `isError` tool result the model can read).
pub enum BuildErr {
    /// The tool name is not one of the three — a JSON-RPC `-32602` (invalid params).
    UnknownTool,
    /// The arguments are invalid (missing/ill-formed) — reported as an `isError` tool result.
    BadArgs(String),
    /// No fleet was configured (`--fleet` / `DEN_FLEET`) — reported as an `isError` tool result.
    NoFleet,
}

impl Server {
    /// The MCP tool catalogue (`tools/list`): 3 read-only enumeration tools with JSON-Schema input schemas.
    pub fn tool_definitions() -> Value {
        json!([
            {
                // Wire names are underscore-only — MCP / the Anthropic tool API validate tool names against
                // `^[a-zA-Z0-9_-]{1,128}$`, so a dotted name (`den.schema`) is rejected by the very clients
                // (Claude/agents) this server targets. Descriptions keep the conceptual `den.*` phrasing.
                "name": "den_schema",
                "title": "den option schema",
                "description": "Enumerate the den option-declaration tree (den.* options) for the configured fleet, as JSON. Each leaf carries _type, a human description, and its option type name (str/submodule/attrsOf/…). Use this to discover the valid den.<...> option paths for a fleet instead of guessing the den API.",
                "inputSchema": { "type": "object", "properties": {}, "additionalProperties": false }
            },
            {
                "name": "den_aspects_list",
                "title": "den declared aspects",
                "description": "List the fleet's declared aspects and, per aspect, its settings (name, default, type). Use this to discover which aspects a fleet declares and each aspect's §2.6 settings fields.",
                "inputSchema": { "type": "object", "properties": {}, "additionalProperties": false }
            },
            {
                "name": "gen_lib_signature",
                "title": "gen-lib member signature",
                "description": "Return gen substrate library member names and their functionArgs formals. Pass `lib` (e.g. \"select\", \"resolve\", \"scope\") to list that library's members; add `member` to return a single member's signature (formals). Use this instead of guessing gen-lib function names/arguments.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "lib": { "type": "string", "description": "gen library name, e.g. select, resolve, scope, graph" },
                        "member": { "type": "string", "description": "optional member name within the library" }
                    },
                    "required": ["lib"],
                    "additionalProperties": false
                }
            }
        ])
    }

    /// Build the Nix selector expression for a tool call:
    /// `(builtins.getFlake "<fleet>")."den-lsp".enumerate.<sel>`. The fleet ref is Nix-string-escaped;
    /// `lib`/`member` are charset-validated and quoted, so an attr name with a hyphen selects safely and no
    /// argument can inject Nix.
    pub fn build_expr(&self, name: &str, args: &Value) -> Result<String, BuildErr> {
        let fleet = self.fleet.as_deref().ok_or(BuildErr::NoFleet)?;
        let base = format!(
            "(builtins.getFlake \"{}\").\"den-lsp\".enumerate",
            nix_escape_str(fleet)
        );
        match name {
            "den_schema" => Ok(format!("{base}.den")),
            "den_aspects_list" => Ok(format!("{base}.\"den-aspects\"")),
            "gen_lib_signature" => {
                let lib = args
                    .get("lib")
                    .and_then(Value::as_str)
                    .ok_or_else(|| BuildErr::BadArgs("missing required argument `lib`".into()))?;
                if !is_attr_name(lib) {
                    return Err(BuildErr::BadArgs(format!("invalid `lib` name: {lib:?}")));
                }
                let mut expr = format!("{base}.gen.\"{lib}\"");
                if let Some(member) = args.get("member").and_then(Value::as_str) {
                    if !is_attr_name(member) {
                        return Err(BuildErr::BadArgs(format!(
                            "invalid `member` name: {member:?}"
                        )));
                    }
                    expr = format!("{expr}.\"{member}\"");
                }
                Ok(expr)
            }
            _ => Err(BuildErr::UnknownTool),
        }
    }

    /// Evaluate an expression through the customer's `nix` (resolved from `PATH` — interpreter-agnostic) and
    /// parse its JSON. `--extra-experimental-features` is passed so the flake evaluation works regardless of
    /// the customer's nix.conf (additive; it enables the two features `getFlake`/`eval --expr` require).
    /// `--impure` is required to `getFlake` a local/unlocked/dirty path (the dev case); it is harmless for a
    /// locked flake ref (the real customer case), whose `getFlake` is pure — `--impure` permits impurity, it
    /// does not introduce it, and this projection is pure either way.
    pub fn nix_eval(&self, expr: &str) -> Result<Value, String> {
        let output = Command::new("nix")
            .args([
                "eval",
                "--impure",
                "--json",
                "--extra-experimental-features",
                "nix-command flakes",
                "--expr",
                expr,
            ])
            .output()
            .map_err(|e| format!("failed to spawn `nix` from PATH: {e}"))?;
        if !output.status.success() {
            return Err(format!(
                "`nix eval` failed ({}):\n{}",
                output.status,
                String::from_utf8_lossy(&output.stderr).trim()
            ));
        }
        serde_json::from_slice(&output.stdout)
            .map_err(|e| format!("`nix eval` returned non-JSON output: {e}"))
    }
}

/// A safe Nix attribute-name / member charset: identifiers, plus `-` and `'` (gen member names like
/// `inputs'`) — never a quote or interpolation, so the validated string cannot escape the quoted attr-path.
fn is_attr_name(s: &str) -> bool {
    !s.is_empty()
        && s.chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-' || c == '\'')
}

/// Escape a string for a Nix `"..."` literal (backslash + double-quote). The fleet ref is operator-supplied
/// (trusted), but escaping keeps a path containing these characters well-formed.
fn nix_escape_str(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}

/// A successful `tools/call` result: the JSON as a text content block (always) plus `structuredContent`
/// when the value is a JSON object (the MCP structured-output channel). `isError` false.
pub fn tool_result_ok(value: Value) -> Value {
    let text = serde_json::to_string_pretty(&value).unwrap_or_else(|_| value.to_string());
    let mut result = json!({
        "content": [ { "type": "text", "text": text } ],
        "isError": false
    });
    if value.is_object() {
        result["structuredContent"] = value;
    }
    result
}

/// A failed `tools/call` result: the error message as text, `isError` true — visible to the model (the MCP
/// convention for tool-execution failures, as opposed to a JSON-RPC protocol error).
pub fn tool_result_err(message: String) -> Value {
    json!({
        "content": [ { "type": "text", "text": message } ],
        "isError": true
    })
}
