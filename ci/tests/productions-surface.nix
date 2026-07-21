# The PRODUCTIONS-SURFACE suite (§5 resolution facet, Phase 5a). `den.productions.<name> = { stratum; from;
# emit; discipline; mode; readsAttrs; compute }` is a REGISTRATION + CONTRACT + LAWS-GATING surface — NOT a
# generic query+fold DSL. A production SUPPLIES its own PASSTHROUGH `compute` (self: id: value); the surface
# compiles it to a gen-resolve synthesized attr equation (the exact `resolve.attr` shape resolved-settings
# produces) and threads it into the ONE equations map, so `den.structural.eval.get id <name>` reads the
# passthrough on the scheduled / warm-served eval. Phase 5a is LOWER-ONLY: emit = attr, mode = all, `from`
# sources ∈ { query, pool }, discipline ∈ the compiled registry — any other value is a NAMED "Phase 5a
# (Phase 5b)" rejection AT REGISTRATION (an explicit boundary, not a silent throw-on-force). The P3 L2 law
# gates the declared `from` SOURCES ONLY (each reads a stratum STRICTLY BELOW the emit stratum) — NEVER
# `readsAttrs` (a same-stratum positive read is A9-legit; a readsAttrs-wide gate would false-reject). See
# REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a single-node fleet registering one production `<name>` = <prod>.
  mkProdFleet =
    name: prod:
    denHoag.mkDen [
      (
        { config, ... }:
        {
          config.den.schema.node.parent = null;
          config.den.node.a = { };
          config.den.productions.${name} = prod;
        }
      )
    ];

  # the reference LOWER-ONLY production: a resolution-stratum attr, mode = all, a `pool` from source (no
  # stratum ⇒ compares below every stratum, L2-clean), a registered discipline, passthrough compute = 42.
  cleanProd = {
    stratum = "resolution";
    from = [ { kind = "pool"; } ];
    emit = "attr";
    mode = "all";
    discipline = "settings-layers";
    readsAttrs = [ ];
    compute = _self: _id: 42;
  };
  cleanFleet = mkProdFleet "x" cleanProd;

  # non-P5a vocabulary — each a NAMED Phase-5b rejection at registration:
  emitNodesFleet = mkProdFleet "n" (cleanProd // { emit = "nodes"; });
  modeFixpointFleet = mkProdFleet "f" (cleanProd // { mode = "fixpoint"; });
  fromKindBogusFleet = mkProdFleet "b" (cleanProd // { from = [ { kind = "graph"; } ]; });
  unknownDisciplineFleet = mkProdFleet "d" (cleanProd // { discipline = "bogusDiscipline"; });

  # L2: a `from` source reading AT/above the emit stratum → NAMED reject; a strictly-below source → clean.
  fromAtStratumFleet = mkProdFleet "atS" (
    cleanProd
    // {
      from = [
        {
          kind = "pool";
          stratum = "resolution";
        }
      ];
    }
  );
  fromBelowStratumFleet = mkProdFleet "belowS" (
    cleanProd
    // {
      from = [
        {
          kind = "pool";
          stratum = "structural";
        }
      ];
    }
  );

  # the FALSE-REJECT guard: a SAME-stratum `readsAttrs` (resolved-aspects, a resolution attr) is A9-legit —
  # L2 gates the from-SOURCES only, so this registers cleanly (a readsAttrs-wide gate would false-reject).
  sameStratumReadsFleet = mkProdFleet "sameR" (
    cleanProd
    // {
      from = [ ];
      readsAttrs = [ "resolved-aspects" ];
      compute = self: id: builtins.length (self.get id "resolved-aspects");
    }
  );

  # the validator called DIRECTLY (value-split, so the NAMED message TEXT is CI-testable — tryEval cannot
  # capture a throw's text). One synthetic emit = nodes production over a two-stratum order, no disciplines.
  msgOf =
    prod:
    denHoag.internal.productions.productionMessage {
      strataOrder = [
        "structural"
        "resolution"
      ];
      disciplineNames = [ ];
    } { p = prod; };
in
{
  flake.tests.productions-surface = {
    # ── registration + schedule (the passthrough attr production) ──
    test-production-registers = {
      expr = builtins.attrNames cleanFleet.den.productions;
      expected = [ "x" ];
    };
    test-production-clean-no-throw = {
      expr = throws cleanFleet.den.productions;
      expected = false;
    };
    # the compiled attr equation is SCHEDULED + warm-served: get reads the passthrough compute.
    test-production-get-scheduled = {
      expr = cleanFleet.den.structural.eval.get "node:a" "x";
      expected = 42;
    };

    # ── lower-only vocabulary (NAMED Phase-5b rejection AT REGISTRATION) ──
    test-production-emit-nodes-rejected = {
      expr = throws emitNodesFleet.den.productions;
      expected = true;
    };
    test-production-mode-fixpoint-rejected = {
      expr = throws modeFixpointFleet.den.productions;
      expected = true;
    };
    test-production-from-kind-rejected = {
      expr = throws fromKindBogusFleet.den.productions;
      expected = true;
    };
    test-production-unknown-discipline-rejected = {
      expr = throws unknownDisciplineFleet.den.productions;
      expected = true;
    };

    # ── the P3 L2 law: from-SOURCES strictly below the emit stratum ──
    test-production-from-at-stratum-rejected = {
      expr = throws fromAtStratumFleet.den.productions;
      expected = true;
    };
    test-production-from-below-stratum-clean = {
      expr = throws fromBelowStratumFleet.den.productions;
      expected = false;
    };
    # the false-reject guard: L2 gates from-sources, NOT readsAttrs — a same-stratum read registers cleanly.
    test-production-same-stratum-readsattrs-clean = {
      expr = throws sameStratumReadsFleet.den.productions;
      expected = false;
    };

    # ── message locus (the rejection names the surface + the phase boundary) ──
    test-production-emit-message-named = {
      expr =
        builtins.match ".*den.productions:.*Phase 5a.*Phase 5b.*" (msgOf {
          emit = "nodes";
          mode = "all";
          from = [ ];
          stratum = "resolution";
          readsAttrs = [ ];
          compute = _: _: 0;
        }) != null;
      expected = true;
    };
  };
}
