# The aspect-registry PROJECTION (§ options-projection): `den.lib.lsp.aspectsProjection` synthesizes a
# nixd-walkable submodule option node per DECLARED aspect instance (`den.aspects` = `config.den.aspects`,
# keyed by aspect name), so an LSP completes aspect names as submodules and each aspect's settings (§2.6
# schema) as sub-options. Each settings field is a `{ default; merge ? "replace"; }` record (§2.6 source 1);
# the projection SYNTHESIZES an option leaf from it (leaf `default = record.default`), it is NOT a mkOption
# decl. This reads a real fleet's declared aspect merge — the ONE projection that reads resolved config —
# so it also pins the laziness seam: the read forces only the aspect DECLARATION, never materialization.
{
  denHoag,
  ...
}:
let
  # A fleet declaring one aspect (`webby`) with an explicit description and two settings fields, beside a
  # second aspect (`plain`) with NO description (so its `.description` falls to the `"Aspect ${name}"`
  # default) and no settings — the empty-settings submodule.
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
        config.den.aspects.plain.nixos.services.enable = true;
      }
    ]).den;

  projected = denHoag.lsp.aspectsProjection { aspects = den.aspects; };
  webby = projected.webby;
  webbySubs = webby.type.getSubOptions { };

  # Independence fixture (mirrors the options-surface seam): the SAME aspect declared beside a host output
  # carrying a live `throw`. The aspect-registry walk forces only the §2.6 settings field-specs (static
  # `{ default; merge ? }` records) + the description — never the resolved fleet output — so `deepSeq` of
  # the projection (INCLUDING `getSubOptions`, which reads every settings record) resolves, while forcing
  # that host output config throws. Pins "fx-pipeline-free" as a permanent regression guard.
  poisonDen =
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.host.h0 = {
          outputs.fam = throw "OUTPUT-FORCED";
        };
        config.den.aspects.webby = {
          description = "the web aspect";
          settings.port = {
            default = 80;
          };
        };
      }
    ]).den;
  poisonProjected = denHoag.lsp.aspectsProjection { aspects = poisonDen.aspects; };
  # Force each aspect node's description + its full sub-options tree (settings records).
  forceNode = node: builtins.deepSeq (node // { subs = node.type.getSubOptions { }; }) "OK";
in
{
  flake.tests.lsp-aspects = {
    # The projection returns an attrset keyed by DECLARED aspect name.
    test-projection-keyed-by-aspect-name = {
      expr = builtins.sort (a: b: a < b) (builtins.attrNames projected);
      expected = [
        "plain"
        "webby"
      ];
    };

    # Each aspect projects a submodule option node: `_type == "option"`, `type.name == "submodule"`, and
    # its declared description preserved.
    test-aspect-node-is-submodule-option = {
      expr = {
        optionType = webby._type;
        typeName = webby.type.name;
        description = webby.description;
      };
      expected = {
        optionType = "option";
        typeName = "submodule";
        description = "the web aspect";
      };
    };

    # `getSubOptions` yields each settings field as an `_type == "option"` leaf whose `default` is
    # SYNTHESIZED from the `{ default; merge ? }` record (`record.default`).
    test-settings-synthesized-as-suboptions = {
      expr = {
        subKeys = builtins.sort (a: b: a < b) (builtins.attrNames webbySubs);
        portType = webbySubs.port._type;
        portDefault = webbySubs.port.default;
        hostDefault = webbySubs.host.default;
      };
      expected = {
        subKeys = [
          "host"
          "port"
        ];
        portType = "option";
        portDefault = 80;
        hostDefault = "localhost";
      };
    };

    # An aspect with no explicit description falls back to `"Aspect ${name}"`, and an aspect with no
    # settings projects an empty sub-options set.
    test-description-fallback-and-empty-settings = {
      expr = {
        description = projected.plain.description;
        subKeys = builtins.attrNames (projected.plain.type.getSubOptions { });
      };
      expected = {
        description = "Aspect plain";
        subKeys = [ ];
      };
    };

    # THE LAZINESS SEAM: projecting + fully forcing each aspect node (description + every settings record
    # via `getSubOptions`) succeeds even when the RESOLVED fleet output carries a live `throw`
    # (`walkOk`), while forcing that output config throws (`outputThrows`). The aspect-declaration merge is
    # independent of materialization — the projection never enters the fx pipeline.
    test-projection-independent-of-resolved-output = {
      expr = {
        walkOk = builtins.deepSeq (builtins.mapAttrs (_: forceNode) poisonProjected) "OK";
        outputThrows =
          !(builtins.tryEval (builtins.deepSeq poisonDen.registries.host.h0.outputs "forced")).success;
      };
      expected = {
        walkOk = "OK";
        outputThrows = true;
      };
    };
  };
}
