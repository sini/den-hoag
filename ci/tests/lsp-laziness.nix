# The CONSOLIDATED laziness guarantee (§ options-projection): the WHOLE LSP projection surface — the
# option-declaration tree (`optionsProjection`, incl. every leaf's `declarationPositions`), the aspect
# registry (`aspectsProjection`, incl. each node's `type.getSubOptions {}` forcing its settings records),
# and the gen-lib API surface (`genLibProjection`) — is DECLARATION-ONLY: deep-forcing all three succeeds
# even when the fleet's RESOLVED output carries a live `throw`. This is the single guard that the value a
# nixd `options.<name>.expr` serves (the E0/cache-once tree) NEVER runs den's fx pipeline / materialization.
# It consolidates the per-projection independence probes (lsp-positions / lsp-aspects / lsp-gen-libs) into
# ONE force over `forNixd` — the exact three projections a consumer serves to nixd.
{
  denHoag,
  ...
}:
let
  # A poison-in-output fleet: a live `throw` rides the RESOLVED host output (forcing it throws), declared
  # BESIDE a real aspect with settings (so the aspect-registry `getSubOptions` force is non-vacuous). The
  # three projections read only DECLARATIONS — the schema option tree, the §2.6 settings field-specs, and
  # the gen libs' `attrNames`/`functionArgs` — none of which touch the poisoned resolved output.
  poisonDen =
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.host.h0 = {
          outputs.fam = throw "RESOLVED-OUTPUT-POISON";
        };
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
      }
    ]).den;

  # The consumer entry: the exact three projections keyed for nixd (`den` / `den-aspects` / `gen`). Each is
  # the value a nixd `options.<name>.expr` would serve.
  surface = denHoag.lsp.forNixd {
    den = poisonDen;
    inherit (denHoag) internal;
  };

  # Force one aspect node fully: its own fields PLUS its synthesized settings sub-options (calling the
  # submodule `getSubOptions {}`, which deepSeq alone leaves as an un-applied lambda).
  forceAspectNode = node: builtins.deepSeq (node // { subs = node.type.getSubOptions { }; }) "OK";

  # The consolidated force over the ENTIRE surface: options tree (every leaf incl. `declarationPositions`),
  # aspect registry (every node incl. its settings records), gen-lib surface (every member + formals).
  allProjectionsOk = builtins.deepSeq [
    (builtins.deepSeq surface.den "OK")
    (builtins.deepSeq (builtins.mapAttrs (_: forceAspectNode) surface."den-aspects") "OK")
    (builtins.deepSeq surface.gen "OK")
  ] "OK";

  # The poison is REAL: forcing the resolved host output genuinely throws (the guard is non-vacuous).
  resolvedOutputThrows =
    !(builtins.tryEval (builtins.deepSeq poisonDen.registries.host.h0.outputs "forced")).success;
in
{
  flake.tests.lsp-laziness = {
    # THE GUARANTEE: deep-forcing the WHOLE projected surface (options + positions, aspects + settings,
    # gen-libs) resolves clean, WHILE forcing the poisoned resolved output throws — the whole LSP surface
    # is fx-pipeline-free (declaration-only), so a nixd worker can cache it once and walk it safely.
    test-whole-surface-declaration-only = {
      expr = {
        inherit allProjectionsOk resolvedOutputThrows;
      };
      expected = {
        allProjectionsOk = "OK";
        resolvedOutputThrows = true;
      };
    };

    # `forNixd` returns exactly the three nixd-keyed projections, each the shape a nixd `options.<name>.expr`
    # serves: `den` an option-declaration tree (leaves `_type == "option"`), `den-aspects` keyed by declared
    # aspect name, `gen` keyed by gen-lib name.
    test-fornixd-serves-three-projections = {
      expr = {
        keys = builtins.sort (a: b: a < b) (builtins.attrNames surface);
        denCarriesOptionLeaf = surface.den.den.membership._type;
        aspectsKeyedByName = surface."den-aspects" ? webby;
        genKeyedByLib = surface.gen ? select;
      };
      expected = {
        keys = [
          "den"
          "den-aspects"
          "gen"
        ];
        denCarriesOptionLeaf = "option";
        aspectsKeyedByName = true;
        genKeyedByLib = true;
      };
    };
  };
}
