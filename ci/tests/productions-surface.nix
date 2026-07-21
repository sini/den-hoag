# The PRODUCTIONS-SURFACE suite (§5 resolution facet). `den.productions.<name> = { stratum; from; emit;
# discipline; mode; readsAttrs; compute }` is a REGISTRATION + CONTRACT + LAWS-GATING surface — NOT a generic
# query+fold DSL. A production SUPPLIES its own PASSTHROUGH `compute` (self: id: value); the surface LOWERS it
# per the P5b taxonomy (§5 ★REVISION): emit = attr → a `resolve.attr` equation; emit = edges with from = ∅ →
# off-trace EDB leaf claim edge FACTS (real from/to) into the relation pool; emit = edges with from = own fields →
# a `resolve.nta` spawn; emit = nodes → a two-equation attr-gather + L5-guarded `nta` spawn. `emit = cascade`/
# unknown and `mode = fixpoint` are NAMED rejections AT REGISTRATION (an explicit boundary, not a silent
# throw-on-force); `from` kinds ∈ { query, pool, reverse-query }. The P3 L2 law gates the declared `from`
# SOURCES ONLY (each reads a stratum STRICTLY BELOW the emit stratum) — NEVER `readsAttrs` (a same-stratum
# positive read is A9-legit; a readsAttrs-wide gate would false-reject). See REFERENCE.md.
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

  # the compile lib called DIRECTLY (the lowering mechanism, independent of a fleet schedule): each production
  # lowers to `{ equations; claimEdges }` per the P5b taxonomy.
  compile =
    prod:
    denHoag.internal.productions.compile {
      productions = {
        p = prod;
      };
    };

  # out-of-vocabulary — a NAMED rejection at registration:
  emitCascadeFleet = mkProdFleet "c" (cleanProd // { emit = "cascade"; });
  modeFixpointFleet = mkProdFleet "f" (cleanProd // { mode = "fixpoint"; });
  fromKindBogusFleet = mkProdFleet "b" (cleanProd // { from = [ { kind = "graph"; } ]; });
  unknownDisciplineFleet = mkProdFleet "d" (cleanProd // { discipline = "bogusDiscipline"; });

  # emit = nodes is now VALID vocabulary, gated by the L5 bounded-NTA law: a BARE emit = nodes (no keyspace /
  # content identity) is L5-rejected; a bounded-NTA-CONFORMANT one (§8 law 5 clauses) registers clean.
  emitNodesBareFleet = mkProdFleet "nBare" (cleanProd // { emit = "nodes"; });
  conformantNodes = cleanProd // {
    emit = "nodes";
    keyspace = "claims";
    identity = "content";
    from = [
      {
        kind = "pool";
        stratum = "structural";
      }
    ];
  };
  emitNodesConformantFleet = mkProdFleet "nOk" conformantNodes;

  # emit = edges CONSTANT (from = ∅) → off-trace EDB leaf claim edge FACTS, landed in the pool. Its constant
  # `compute` returns the ground endpoint records (real from/to); each expands into one pool edge.
  constantEdgeProd = cleanProd // {
    emit = "edges";
    from = [ ];
    readsAttrs = [ ];
    compute = _self: _id: [
      {
        from = "node:src";
        to = "node:tgt";
      }
    ];
  };
  claimFleet = mkProdFleet "seedClaim" constantEdgeProd;
  # emit = edges SPAWN (from = own fields) → an nta equation.
  spawnEdgeProd = cleanProd // {
    emit = "edges";
  };
  # a production literally named `<x>__spawn` collides with the synthesized emit = nodes spawn key → rejected.
  reservedSpawnFleet = mkProdFleet "x__spawn" cleanProd;

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
      # the framework SEEDS its own settings production (`resolved-settings`) through this surface (dogfood),
      # so every fleet's `den.productions` carries it BESIDE the user's declarations.
      expr = builtins.attrNames cleanFleet.den.productions;
      expected = [
        "resolved-settings"
        "x"
      ];
    };
    # ── the settings dogfood: settings is now DECLARED through den.productions, not a hand-wired attr ──
    # The framework re-declares its own settings resolution facet AS a production (keyed by the attr it emits,
    # `resolved-settings`, per the surface's key = emitted-attr invariant), proving the surface hosts the real
    # settings production. settings-attribute.nix stays byte-identical (same compute, same `resolved-settings`).
    test-settings-dogfooded-via-productions = {
      expr = cleanFleet.den.productions ? "resolved-settings";
      expected = true;
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

    # ── P5b lowering taxonomy (the compile mechanism, called directly) ──
    # attr → one synthesized `resolve.attr`, no claim edge (P5a, unchanged).
    test-production-lower-attr = {
      expr = {
        kind = (compile cleanProd).equations.p.kind;
        claims = (compile cleanProd).claimEdges;
      };
      expected = {
        kind = "synthesized";
        claims = [ ];
      };
    };
    # edges CONSTANT (from = ∅) → the EDB leaf claim's ground edge FACTS (real from/to), NO equation.
    test-production-lower-edges-constant = {
      expr = {
        equations = builtins.attrNames (compile constantEdgeProd).equations;
        claims = map (e: {
          inherit (e)
            id
            kind
            from
            to
            ;
        }) (compile constantEdgeProd).claimEdges;
      };
      expected = {
        equations = [ ];
        claims = [
          {
            id = "claim:p:0";
            kind = "p";
            from = "node:src";
            to = "node:tgt";
          }
        ];
      };
    };
    # edges SPAWN (from = own fields) → an `nta` equation (Vogt spawn), no claim edge.
    test-production-lower-edges-spawn = {
      expr = {
        kind = (compile spawnEdgeProd).equations.p.kind;
        claims = (compile spawnEdgeProd).claimEdges;
      };
      expected = {
        kind = "nta";
        claims = [ ];
      };
    };
    # nodes → TWO equations: the emitted attr-gather (`p`) + the `nta` spawn (`p__spawn`).
    test-production-lower-nodes-two-equations = {
      expr = {
        names = builtins.sort (a: b: a < b) (builtins.attrNames (compile conformantNodes).equations);
        spawnKind = (compile conformantNodes).equations."p__spawn".kind;
        gatherKind = (compile conformantNodes).equations.p.kind;
      };
      expected = {
        names = [
          "p"
          "p__spawn"
        ];
        spawnKind = "nta";
        gatherKind = "synthesized";
      };
    };
    # empty ⇒ `{ equations = { }; claimEdges = [ ]; }` (byte-identical to the pre-P5b state).
    test-production-lower-empty = {
      expr = denHoag.internal.productions.compile { productions = { }; };
      expected = {
        equations = { };
        claimEdges = [ ];
      };
    };

    # ── the off-trace claim pool: an emit = edges CONSTANT leaf claim lands its EDB edge FACTS in the pool ──
    test-production-claim-edge-lands = {
      expr = map (e: {
        inherit (e)
          id
          kind
          from
          to
          ;
      }) claimFleet.den.relationEdges;
      expected = [
        {
          id = "claim:seedClaim:0";
          kind = "seedClaim";
          from = "node:src";
          to = "node:tgt";
        }
      ];
    };

    # ── vocabulary + L5 (NAMED rejection AT REGISTRATION) ──
    # emit = cascade is out of vocabulary (constructs compute, breaks passthrough — settings/C8 only).
    test-production-emit-cascade-rejected = {
      expr = throws emitCascadeFleet.den.productions;
      expected = true;
    };
    # a production named `<x>__spawn` clashes with the synthesized emit = nodes spawn key → NAMED reject.
    test-production-reserved-spawn-suffix-rejected = {
      expr = throws reservedSpawnFleet.den.productions;
      expected = true;
    };
    # emit = nodes is valid vocab but L5-gated: a bare spawn (no keyspace / content identity) rejects...
    test-production-emit-nodes-bare-rejected = {
      expr = throws emitNodesBareFleet.den.productions;
      expected = true;
    };
    # ...a bounded-NTA-conformant emit = nodes registers clean (the L5 guard is the identity).
    test-production-emit-nodes-conformant-clean = {
      expr = throws emitNodesConformantFleet.den.productions;
      expected = false;
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
        builtins.match ".*den.productions:.*not supported — constructs compute.*" (msgOf {
          emit = "cascade";
          mode = "all";
          from = [ ];
          stratum = "resolution";
          readsAttrs = [ ];
          compute = _: _: 0;
        }) != null;
      expected = true;
    };
    # the L5 bounded-NTA law is wired into registration: a bare emit = nodes names the content-identity clause.
    test-production-nodes-l5-message-named = {
      expr =
        builtins.match ".*den.productions:.*content-function.*" (msgOf {
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
