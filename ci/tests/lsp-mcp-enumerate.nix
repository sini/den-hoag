# The MCP-enumeration JSON CONTRACT (§ enumerate): the three trees the MCP enumeration server serves — one
# per tool (`den_schema` → `den`, `den_aspects_list` → `den-aspects`, `gen_lib_signature` → `gen.<lib>`) —
# are what a `nix eval --json` subprocess over a fleet's `den-lsp.enumerate` output must return. The raw forNixd
# projections are NOT JSON-serializable (an option leaf's `.type` is a function-carrying type record; an
# aspect node's `getSubOptions` is a function — `builtins.toJSON` on either throws "cannot convert a
# function to JSON"). `den.lib.lsp.forNixdJSON` (= `enumerate.fromForNixd ∘ forNixd`) re-projects them into
# JSON-safe records. This suite pins that DATA contract: every tree ROUND-TRIPS through `toJSON`/`fromJSON`
# (the server's exact wire path), keys/`_type`/type-names/aspect-settings/gen-formals hold, and functions
# are provably dropped (a leaf's `.type` is a STRING, not a record). It is the Nix-side twin of the Rust
# server smoke test (which exercises the MCP protocol) — together they cover the server end to end.
{
  denHoag,
  ...
}:
let
  # A fleet with a real option surface (`den.host` from the schema), one aspect carrying two SCALAR settings
  # (so the settings-default round-trip is non-vacuous), and a second settingless aspect (description
  # fallback). This is the same shape lsp-aspects builds; here we read the JSON-SAFE enumeration view of it.
  den =
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.host.h0 = { };
        config.den.aspects.webby = {
          description = "the web aspect";
          settings.port = {
            default = 80;
          };
          settings.host = {
            default = "localhost";
            merge = "replace";
          };
        };
        config.den.aspects.plain = { };
      }
    ]).den;

  # The exact value a fleet exposes at its `den-lsp.enumerate` flake output for the MCP server (`forNixdJSON` =
  # the JSON-safe enumeration over the three forNixd projections).
  view = denHoag.lsp.forNixdJSON {
    inherit den;
    inherit (denHoag) internal;
  };

  # The server's WIRE PATH: `nix eval --json` serializes the selected tree; the agent's MCP client parses it
  # back. `fromJSON ∘ toJSON` reproduces that exactly — it succeeds ONLY if the tree is fully JSON-safe
  # (no function, no un-caught throw survives). Each tool selects one of these.
  roundTrip = v: builtins.fromJSON (builtins.toJSON v);
in
{
  flake.tests.lsp-mcp-enumerate = {
    # `forNixdJSON` serves exactly the three tool-backing trees, keyed as the tools select them.
    test-serves-three-json-trees = {
      expr = builtins.sort (a: b: a < b) (builtins.attrNames view);
      expected = [
        "den"
        "den-aspects"
        "gen"
      ];
    };

    # `den_schema` tool: the whole option tree ROUND-TRIPS through JSON, and a real option leaf projects its
    # `_type`, description, and type-NAME (a STRING — the function-carrying type record is gone). This is the
    # contract that makes `nix eval --json (…)."den-lsp".enumerate.den` return the option surface as data.
    test-den-schema-json-and-leaf-shape = {
      expr =
        let
          rt = roundTrip view.den;
        in
        {
          hostType = rt.den.host.type;
          hostOptionType = rt.den.host._type;
          hostTypeIsString = builtins.isString rt.den.host.type;
          aspectsRootType = rt.den.aspects.type;
        };
      expected = {
        hostType = "attrsOf";
        hostOptionType = "option";
        hostTypeIsString = true;
        aspectsRootType = "aspectsRoot";
      };
    };

    # `den_aspects_list` tool: the aspect registry ROUND-TRIPS to a fully-known JSON shape — each aspect a
    # submodule record whose `settings` list the §2.6 fields with their SCALAR defaults, description
    # fallback (`"Aspect ${name}"`) for a settingless aspect. This is the exact JSON `den_aspects_list` returns.
    test-den-aspects-list-json-shape = {
      expr = roundTrip view."den-aspects";
      expected = {
        webby = {
          _type = "option";
          description = "the web aspect";
          type = "submodule";
          settings = {
            host = {
              _type = "option";
              default = "localhost";
              description = "";
              type = "raw";
            };
            port = {
              _type = "option";
              default = 80;
              description = "";
              type = "raw";
            };
          };
        };
        plain = {
          _type = "option";
          description = "Aspect plain";
          type = "submodule";
          settings = { };
        };
      };
    };

    # `gen_lib_signature` tool: the gen surface ROUND-TRIPS, a known lib/member is present, and a lambda
    # member carries its `functionArgs` formals — the signature payload the tool returns for `lib`+`member`.
    test-gen-lib-signature-json = {
      expr =
        let
          rt = roundTrip view.gen;
        in
        {
          hasSelect = rt ? select;
          entryType = rt.select.entity._type;
          resolveFormals = builtins.sort (a: b: a < b) (builtins.attrNames rt.resolve.resolve.formals);
        };
      expected = {
        hasSelect = true;
        entryType = "option";
        resolveFormals = [
          "declaredEdges"
          "equations"
          "parseParent"
          "roots"
          "settings"
          "strataOrder"
        ];
      };
    };
  };
}
