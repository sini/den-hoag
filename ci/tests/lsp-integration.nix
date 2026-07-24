# The B2 LSP/MCP AUTO-EXPORT end-to-end witness — a den fleet driven through the REAL flakeModule
# (`lib/compat/bridge.nix`, the module a consumer imports as `inputs.den.flakeModule`), asserting the
# flakeModule EMITS the whole nixd/MCP surface with ZERO hand-wiring: no manual `forNixd` call, no manual
# nixd config. The fleet is evaluated through flake-parts EXACTLY as the nix-config consumer reaches it
# (`_lib/den-compat-test.nix`'s `evalFlakeModule` path), then the auto-exported `config.flake.den-lsp.*` +
# `config.flake.packages.<system>.den-lsp-mcp` outputs are read back and shape-checked.
#
# This pins the B2 contract (distinct from B1's lsp-binding suite, which drives the binding DIRECTLY):
#   (1) `den-lsp.options` — the in-process `forNixd` sections REMAPPED onto den's nixd provider names
#       (`den`/`den-aspects`/`gen`), each an `_type == "option"` tree;
#   (2) `den-lsp.enumerate` — the JSON-safe wire view (`forNixdJSON`, neutral `{ options; aspects; libs; }`)
#       that `builtins.toJSON` serializes cleanly, with an aspect settings field default surfacing;
#   (3) `packages.<system>.den-lsp-mcp` — the re-exported gen-lsp MCP server.
{
  denHoagFlakeModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  flakeParts = genInputs.flake-parts;
  lib = nixpkgsLib;

  # A minimal fleet declaring ONE aspect (`webby`) with a description + two settings fields, at a host kind.
  # No host INSTANCES / no `den.nixpkgs`: the option-declaration tree + aspect registry the LSP surface reads
  # are declaration-only (B1 laziness seam), so the fleet needs no crossing — the `collect` terminal path.
  fleetModule = {
    config.den.schema.host.parent = null;
    config.den.aspects.webby = {
      description = "the web aspect";
      settings.port.default = 80;
      settings.host = {
        default = "localhost";
        merge = "replace";
      };
    };
  };

  # THE BRIDGE EVAL — the real consumer path (`imports = [ inputs.den.flakeModule ]`). `evalFlakeModule`
  # returns the full module-system result, so `eval.config.flake` is the emitted output face — the SAME
  # `config.flake` the behavioral scaffold reads `nixosConfigurations` off, here read for `den-lsp`/`packages`.
  eval =
    flakeParts.lib.evalFlakeModule
      {
        inputs = { inherit nixpkgs; };
        self = {
          inputs = { inherit nixpkgs; };
        };
        moduleLocation = "<lsp-integration>";
      }
      {
        systems = [ "x86_64-linux" ];
        imports = [
          denHoagFlakeModule
          fleetModule
        ];
      };
  flake = eval.config.flake;
  denLsp = flake.den-lsp;
in
{
  flake.tests.lsp-integration = {
    # (1) THE nixd OPTION-PROVIDER TREES: the flakeModule auto-exports `den-lsp.options` keyed by den's
    # provider names (`den`/`den-aspects`/`gen`) — the remap of gen-lsp's neutral `options`/`aspects`/`libs`.
    # Each section is an `_type == "option"` tree: the `den.*` option-declaration tree (a `den.membership`
    # leaf), the aspect registry (the `webby` node), and the gen-lib surface (a `select.entity` leaf).
    test-auto-export-options-providers = {
      expr = {
        providerKeys = builtins.sort (a: b: a < b) (builtins.attrNames denLsp.options);
        denOptionLeafType = denLsp.options.den.den.membership._type;
        aspectNodeType = denLsp.options.den-aspects.webby._type;
        genLibLeafType = denLsp.options.gen.select.entity._type;
      };
      expected = {
        providerKeys = [
          "den"
          "den-aspects"
          "gen"
        ];
        denOptionLeafType = "option";
        aspectNodeType = "option";
        genLibLeafType = "option";
      };
    };

    # (2) THE MCP WIRE VIEW: `den-lsp.enumerate` is the neutral-keyed JSON-safe projection — `builtins.toJSON`
    # serializes the WHOLE view without a function surviving (the mcp server's `nix eval --json` contract),
    # and an aspect settings field default (`webby` -> settings -> port -> 80) surfaces in the descended tree.
    test-auto-export-enumerate-wire = {
      expr = {
        enumerateKeys = builtins.sort (a: b: a < b) (builtins.attrNames denLsp.enumerate);
        jsonSafe = builtins.isString (builtins.toJSON denLsp.enumerate);
        wirePortDefault = denLsp.enumerate.aspects.webby.subOptions.settings.subOptions.port.default;
      };
      expected = {
        enumerateKeys = [
          "aspects"
          "libs"
          "options"
        ];
        jsonSafe = true;
        wirePortDefault = 80;
      };
    };

    # (3) THE MCP SERVER PACKAGE: the flakeModule re-exports gen-lsp's prebuilt MCP server as
    # `packages.<system>.den-lsp-mcp` (its defaults `--namespace den`/`--output-attr den-lsp` read
    # `<flake>.den-lsp.enumerate`, so `den-lsp-mcp --fleet <flake>` needs no wrapper). Key presence is the
    # auto-wire assertion; `pname` confirms it is genuinely gen-lsp's server (`mainProgram = gen-lsp-mcp`).
    test-auto-export-mcp-package = {
      expr = {
        hasMcpKey = flake.packages.x86_64-linux ? den-lsp-mcp;
        mcpPname = flake.packages.x86_64-linux.den-lsp-mcp.pname;
      };
      expected = {
        hasMcpKey = true;
        mcpPname = "gen-lsp-mcp";
      };
    };
  };
}
