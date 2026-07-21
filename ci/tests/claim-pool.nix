# The CLAIM-POOL witness (§5 resolution facet / productions substrate, edge-uniform ★REVISION). A synthetic
# claim/provide engine's GROUND FACTS: `emit = edges` CONSTANT productions (from = ∅, readsAttrs = []) are EDB
# LEAF CLAIMS — each supplies its ground edge facts as endpoint records, expanded into off-trace pool edges in
# `den.relationEdges` (§7 off-trace; never on the materialization trace). `from = ∅` is LOAD-BEARING: a pure
# EDB constant means the arr↔prowlarr CYCLIC pair is TWO INDEPENDENT facts (arr→prowlarr AND prowlarr→arr),
# both at stratum = connect, an ACYCLIC stratum — a cycle in who-connects-whom is NOT a stratum cycle, so the
# fleet builds with no eval divergence. Edge-uniform across kinds: connect / secret / database leaf claims all
# lower the SAME way (one CONSTANT ⇒ N pool edges). The claim strata are registered fleet-side via
# `strataChain` (structural < connect < secret < database < route < resolution), so a later provider at
# `resolution` reads every claim stratum strictly below (§2.3 L2). The forward view (a source reads its egress)
# is queried NOW over the real §3 query spine (`denHoag.query`); the transpose reverse view (a target reads its
# ingress) is a later task. Header mirrors nway-strata.nix's — ci specialArgs provides `denHoag`. See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  fleet = denHoag.mkDen [
    {
      config.den.schema.node.parent = null;
      # the claim strata inserted densely below resolution: structural < connect < secret < database < route
      # < resolution. A leaf claim sits at its OWN kind's stratum; the L2 gate is vacuous for a from = ∅ EDB.
      config.den.strata.insert = denHoag.declare.strataChain {
        after = "structural";
        chain = [
          "connect"
          "secret"
          "database"
          "route"
        ];
      };
      config.den.node.arr = { };
      config.den.node.prowlarr = { };

      # connect leaf claim — the CYCLIC pair as TWO edge facts at ONE acyclic stratum. from = ∅ EDB, so the
      # cycle in who-connects-whom is not a stratum cycle.
      config.den.productions.connect = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:arr";
            to = "node:prowlarr";
          }
          {
            from = "node:prowlarr";
            to = "node:arr";
          }
        ];
      };
      # secret leaf claim — one edge fact at the secret stratum (edge-uniform across kinds).
      config.den.productions.secret = {
        stratum = "secret";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:arr";
            to = "secret:arr-apikey";
          }
        ];
      };
      # database leaf claim — one edge fact at the database stratum (edge-uniform across kinds).
      config.den.productions.database = {
        stratum = "database";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:arr";
            to = "db:main";
          }
        ];
      };
    }
  ];

  # the off-trace pool. The witness declares NO `den.relations` / entity `.edges`, so forward + inverse
  # relation edges are empty — the pool holds ONLY the production leaf-claim facts.
  pool = fleet.den.relationEdges;
  proj = e: {
    inherit (e)
      id
      kind
      from
      to
      ;
  };
  factsOf = k: builtins.sort (a: b: a.id < b.id) (map proj (builtins.filter (e: e.kind == k) pool));

  # a single-claim fleet sharing the claim strata — the guard/purity witnesses.
  mkLeafFleet =
    prods:
    denHoag.mkDen [
      {
        config.den.schema.node.parent = null;
        config.den.strata.insert = denHoag.declare.strataChain {
          after = "structural";
          chain = [
            "connect"
            "secret"
            "database"
            "route"
          ];
        };
        config.den.node.arr = { };
        config.den.productions = prods;
      }
    ];

  # an IMPURE leaf claim — its constant `compute` READS `self.get` (forbidden: a leaf claim is pure EDB,
  # from = ∅, readsAttrs = []). It must ABORT via edbStubSelf's throw-on-read when the pool fact is forced.
  # The throw TEXT is tryEval-uncatchable, but the success BOOLEAN is — the mechanism witness for edbStubSelf.
  impureLeafFleet = mkLeafFleet {
    connect = {
      stratum = "connect";
      from = [ ];
      emit = "edges";
      mode = "all";
      readsAttrs = [ ];
      compute = self: _id: [
        {
          from = self.get "x" "y";
          to = "z";
        }
      ];
    };
  };

  # the registration-time LIST-shape guard called DIRECTLY (value-split: the NAMED message TEXT is CI-testable —
  # tryEval cannot capture a throw's text). A pure-but-WRONG-shape leaf (compute returns 42, not a list of
  # endpoint records) yields the NAMED value AT REGISTRATION over the seed two-stratum order.
  msgOf =
    prod:
    denHoag.internal.productions.productionMessage {
      strataOrder = [
        "structural"
        "resolution"
      ];
      disciplineNames = [ ];
    } { p = prod; };
  wrongShapeLeaf = {
    stratum = "structural";
    from = [ ];
    emit = "edges";
    mode = "all";
    readsAttrs = [ ];
    compute = _self: _id: 42;
  };
in
{
  flake.tests.claim-pool = {
    # the claim strata land densely below resolution (structural < connect < secret < database < route <
    # resolution < …) — a provider at resolution reads all four claim strata strictly below (§2.3 L2).
    test-claim-strata-below-resolution = {
      expr = fleet.den.strata;
      expected = [
        "structural"
        "connect"
        "secret"
        "database"
        "route"
        "resolution"
        "collection"
        "demand"
        "output"
      ];
    };

    # (a) each leaf claim's ground facts LAND in the off-trace pool with real endpoints + the claim kind.
    test-claim-connect-facts-land = {
      expr = factsOf "connect";
      expected = [
        {
          id = "claim:connect:0";
          kind = "connect";
          from = "node:arr";
          to = "node:prowlarr";
        }
        {
          id = "claim:connect:1";
          kind = "connect";
          from = "node:prowlarr";
          to = "node:arr";
        }
      ];
    };
    test-claim-secret-fact-lands = {
      expr = factsOf "secret";
      expected = [
        {
          id = "claim:secret:0";
          kind = "secret";
          from = "node:arr";
          to = "secret:arr-apikey";
        }
      ];
    };
    test-claim-database-fact-lands = {
      expr = factsOf "database";
      expected = [
        {
          id = "claim:database:0";
          kind = "database";
          from = "node:arr";
          to = "db:main";
        }
      ];
    };

    # (b) the arr↔prowlarr CYCLIC pair = TWO DISTINCT facts (different from/to), NOT a stratum cycle. Forcing
    # the pool computes it with NO eval divergence — the from = ∅ EDB law made real.
    test-claim-cyclic-pair-two-distinct-facts = {
      expr =
        let
          cs = factsOf "connect";
        in
        {
          count = builtins.length cs;
          distinct = (builtins.elemAt cs 0).from != (builtins.elemAt cs 1).from;
        };
      expected = {
        count = 2;
        distinct = true;
      };
    };

    # (c) a node's FORWARD connect view is queryable over the real §3 query spine (denHoag.query over the pool):
    # arr's egress = [prowlarr], prowlarr's egress = [arr]. The cyclic pair reads as two independent directed
    # facts (a forward query from either endpoint terminates — no divergence).
    test-claim-forward-connect-queryable = {
      expr = denHoag.query {
        edges = pool;
        from = "node:arr";
        follow = "connect";
        mode = "all";
      };
      expected = [ "node:prowlarr" ];
    };
    test-claim-forward-connect-reverse-endpoint = {
      expr = denHoag.query {
        edges = pool;
        from = "node:prowlarr";
        follow = "connect";
        mode = "all";
      };
      expected = [ "node:arr" ];
    };
    # the secret leaf claim is queryable the same way (edge-uniform: one query spine over all claim kinds).
    test-claim-forward-secret-queryable = {
      expr = denHoag.query {
        edges = pool;
        from = "node:arr";
        follow = "secret";
        mode = "all";
      };
      expected = [ "secret:arr-apikey" ];
    };

    # ── the EDB-purity + LIST-shape laws (edbStubSelf + the registration guard) ──
    # an impure leaf claim (compute reads `self.get`) ABORTS when its pool fact is forced — the edbStubSelf
    # throw-on-read mechanism, witnessed. Guards against a silent future swap of edbStubSelf → `{ }`.
    test-claim-edb-purity-aborts = {
      expr = (builtins.tryEval (builtins.deepSeq impureLeafFleet.den.relationEdges null)).success;
      expected = false;
    };
    # a pure-but-WRONG-shape leaf (compute returns 42, not a list of endpoint records) is a NAMED rejection AT
    # REGISTRATION — the validator VALUE, not a cryptic length/index throw deep in claimEdgesOf expansion.
    test-claim-wrong-shape-named = {
      expr = builtins.match ".*emit=edges CONSTANT.*must return a LIST.*" (msgOf wrongShapeLeaf) != null;
      expected = true;
    };
  };
}
