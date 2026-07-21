{
  description = "Example den fleet — exposes `den-lsp` (`.enumerate` for the den LSP MCP server, `.options` for a nixd editor worker)";

  # The den-hoag flake (this repo). A real customer pins `github:denful/den` (or their den input); here a
  # relative `path:` keeps the example self-contained. `path:` flakes see only git-tracked files, so the
  # repo's lib/** (incl. lib/lsp/*) must be committed — which it is.
  #
  # NOTE (in-repo relative input): a relative `path:../..` resolves against the flake's *own* tree once
  # it is copied to the store, so this example must be evaluated as a SUBDIRECTORY flake of the repo so
  # the input resolves within the same tree — point the server at:
  #     lsp-mcp --fleet 'path:/abs/path/to/den-hoag?dir=examples/fleet'
  # A real customer whose `den` input is a normal flake ref (github:…) does NOT need `?dir=`; they point
  # `--fleet` straight at their fleet flake.
  inputs.den.url = "path:../..";

  outputs =
    { den, ... }:
    let
      # A tiny fleet: one host and one aspect with two settings — enough to enumerate a non-trivial
      # option tree, an aspect registry, and the gen-lib surface.
      fleetModules = [
        {
          config.den.schema.host.parent = null;
          config.den.host.web = { };
          config.den.aspects.nginx = {
            description = "the nginx web-server aspect";
            settings.port = {
              default = 80;
            };
            settings.root = {
              default = "/var/www";
            };
          };
        }
      ];
      builtDen = (den.lib.mkDen fleetModules).den;
    in
    {
      # ── The den LSP surface — ONE namespaced output, both views of the projection ─────────────────
      # A customer adds ONE output. `enumerate` = the JSON-safe view the MCP server `nix eval --json`s
      # (`den` / `den-aspects` / `gen`); `options` = the RAW projections a nixd editor worker walks
      # in-process (function-carrying types + `getSubOptions`, NOT JSON-serializable — nixd, not the MCP
      # server, consumes it; see lib/lsp/README.md § "Consumer wiring"). Point the server at this fleet
      # (subdir idiom, see the input note above):
      #   lsp-mcp --fleet 'path:/abs/path/to/den-hoag?dir=examples/fleet'
      # then a `den_schema` tool call runs `nix eval --json '(builtins.getFlake "…")."den-lsp".enumerate.den'`.
      den-lsp = {
        enumerate = den.lib.lsp.forNixdJSON {
          den = builtDen;
          inherit (den.lib) internal;
        };
        options = den.lib.lsp.forNixd {
          den = builtDen;
          inherit (den.lib) internal;
        };
      };
    };
}
