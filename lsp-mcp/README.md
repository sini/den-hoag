# `lsp-mcp` — the den LSP enumeration MCP server

A thin, read-only [Model Context Protocol](https://modelcontextprotocol.io) server (stdio) that exposes a
den fleet's **den/gen API surface** to coding agents as enumeration tools. It kills agent den/gen API
hallucination: instead of guessing `den.*` option paths or gen-lib signatures, an agent calls a tool and
gets the real, projected surface for the customer's actual fleet.

## Design principle (load-bearing): interpreter-agnostic — drive the customer's `nix`

The server embeds **no** Nix evaluator. Every tool shells out to `nix` resolved from `PATH` — whatever
interpreter the customer runs (CppNix, Lix, …) — as a subprocess:

```
nix eval --impure --json --extra-experimental-features "nix-command flakes" --expr '<expr>'
```

That is what keeps the enumeration correct for every customer: the surface an agent sees is evaluated by
the same `nix` the customer builds with. The server never references a specific interpreter binary or path.
This is the cheap **E0** tier and the first proof of the "drive-the-customer's-nix" model.

## The three tools

Tool wire names are underscore-only — MCP and the Anthropic tool API validate names against
`^[a-zA-Z0-9_-]{1,128}$`, so a dotted name would be rejected by the clients (Claude/agents) this server
targets.

| tool | args | returns |
| ---- | ---- | ------- |
| `den_schema` | — | the projected den option tree (`den.*` options) as JSON — each leaf carries `_type`, a description, and its option type name. |
| `den_aspects_list` | — | the fleet's declared aspects and, per aspect, its settings (name, default, type). |
| `gen_lib_signature` | `lib` (required), `member` (optional) | gen substrate library member names + their `functionArgs` formals; with `member`, one member's signature. |

Each tool selects into the fleet's `den-lsp.enumerate` output and `nix eval --json`s it:

- `den_schema` → `(builtins.getFlake "<fleet>")."den-lsp".enumerate.den`
- `den_aspects_list` → `(builtins.getFlake "<fleet>")."den-lsp".enumerate."den-aspects"`
- `gen_lib_signature` → `(builtins.getFlake "<fleet>")."den-lsp".enumerate.gen.<lib>[.<member>]`

`lib` / `member` are charset-validated (`[A-Za-z0-9_'-]`) and quoted into the attr-path, so no argument can
inject Nix; the fleet ref is Nix-string-escaped.

## Fleet wiring

The server is configured with the customer's fleet reference (a flake ref / path) via `--fleet <ref>` or the
`DEN_FLEET` env var. The fleet exposes ONE namespaced flake output, `den-lsp`, carrying both views of the
projection — `enumerate` (the JSON-safe view this server reads) and `options` (the raw view a nixd editor
worker walks):

```nix
# the customer's fleet flake.nix
{
  inputs.den.url = "github:denful/den";       # (or their den input)
  outputs = { den, ... }: {
    den-lsp = {
      enumerate = den.lib.lsp.forNixdJSON {
        den = (den.lib.mkDen self.fleetModules).den;   # the built fleet (carries _options + aspects)
        inherit (den.lib) internal;                    # the gen-lib bundle
      };
      options = den.lib.lsp.forNixd {                  # (optional) the nixd editor surface
        den = (den.lib.mkDen self.fleetModules).den;
        inherit (den.lib) internal;
      };
    };
  };
}
```

A locked flake ref (`github:…`, or a committed local flake) is the real customer case — its `getFlake` is
pure; the server passes `--impure` only so an unlocked/dirty local path also works during development.

`den.lib.lsp.forNixdJSON` is the JSON-safe **enumeration view** (`lib/lsp/enumerate.nix`) over the three
`forNixd` projections. It exists because the raw `forNixd` projections are built for a nixd editor worker's
**in-process** walk — an option leaf's `.type` is a function-carrying type record, an aspect node's
`getSubOptions` is a function — so `builtins.toJSON` (what `nix eval --json` runs) cannot serialize them. The
enumeration view re-projects each tree into JSON-safe records (leaf → `_type`/description/type-name/JSON-safe
default/formals; aspect → settings descended one level; gen passes through).

A worked example fleet is in [`examples/fleet/`](../examples/fleet). Because that example pins `den` with a
relative `path:../..` (it lives inside this repo), evaluate it as a **subdirectory flake** of the repo so the
relative input resolves within the same tree:

```
lsp-mcp --fleet 'path:/abs/path/to/den-hoag?dir=examples/fleet'
```

A real customer whose `den` input is a normal flake ref (`github:…`) points `--fleet` straight at their
fleet flake (no `?dir=`).

## Build / run

```
nix build .#lsp-mcp          # build the binary (Nix, hermetic — vendored Cargo.lock)
nix run .#lsp-mcp -- --fleet "path:$PWD?dir=examples/fleet"   # against the worked example
```

For an MCP client, register the binary as a stdio server and pass `--fleet <ref>` (or set `DEN_FLEET`).

## Why hand-rolled (not the `rmcp` SDK)

MCP-over-stdio is newline-delimited JSON-RPC 2.0 (one JSON message per line). This server hand-rolls that
protocol on top of `serde_json` only — no async runtime, no MCP SDK. The reason is the Nix package build:
`buildRustPackage` vendors from a committed `Cargo.lock`, and a tiny dependency tree (serde_json + its few
transitive crates) keeps that build hermetic and fast. `rmcp` pulls in a large `tokio`-based tree; the extra
surface buys nothing for three read-only tools.

The hand-rolled envelope is spec-conformant (checked against the MCP 2025-06-18 spec, not approximated):
`initialize` returns a real `InitializeResult` (negotiated `protocolVersion` — the client's echoed when
supported, else the latest we serve; `capabilities.tools.listChanged = false`; `serverInfo`; `instructions`),
`tools/list` returns `Tool` objects with JSON-Schema `inputSchema`, and `tools/call` returns a `CallToolResult`
(a `text` content block whose text is the serialized JSON, plus `structuredContent`, plus `isError`). Unknown
tools are a JSON-RPC `-32602` protocol error; tool-execution failures are `isError: true` results. Methods
handled: `initialize`, `notifications/initialized`, `ping`, `tools/list`, `tools/call`. The smoke test asserts
these exact wire shapes.

## Tests

- **Server side** — `lsp-mcp/tests/smoke.rs` (a `cargo test` integration test): starts the server against a
  synthetic hermetic fleet flake, drives `initialize` / `tools/list` / a `tools/call` per tool (each a real
  `nix eval` subprocess) + the two error paths, and asserts well-formed responses.
- **Nix side (data contract)** — `ci/tests/lsp-mcp-enumerate.nix` (nix-unit): builds a fleet, runs
  `forNixdJSON`, and asserts the three trees round-trip through `toJSON`/`fromJSON` (the server's wire path)
  with the expected keys / `_type` / type-names / aspect settings / gen formals.
