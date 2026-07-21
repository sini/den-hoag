# The COMPOSITE claim ROUTE-DESUGAR witness (§5 resolution facet / productions substrate, strataChain
# composite-above-subclaims). Where a LEAF claim (connect/secret/database, claim-pool.nix) supplies its ground
# facts at its OWN kind/stratum, a COMPOSITE claim (`route`) DESUGARS: its constant `compute` is a pure fold
# returning HETEROGENEOUS sub-claim facts — a `secret` fact (at the secret stratum) + a `connect` fact (at the
# connect stratum) — each tagged with its own `kind`/`stratum` STRICTLY BELOW `route`. The desugar is a pure
# COMPILE-TIME fold into the STATIC claim pool (§G — NOT a resolve.nta: the claim pool is materialized BEFORE
# the resolve schedule, so a resolve-time spawn would never join the static pool the §9 transpose reverse-read
# consumes; Vogt 1989 finiteness is realized statically because the spawn tree is finite + a content-function
# of the own decl). The claim strata sit densely below `resolution` via `strataChain` — connect < secret <
# database < route — so `route` is strictly ABOVE database > secret > connect (a composite above its sub-claims)
# and a provider at `resolution` reverse-reads the desugared sub-claims strictly below. Header mirrors
# claim-provider.nix's — ci specialArgs provides `denHoag`. See REFERENCE.md.
{
  denHoag,
  nixpkgsLib,
  ...
}:
let
  # the route composite fleet: ONE `route` composite claim (no leaf connect/secret — the route IS the sole
  # source of the connect/secret sub-claims, so the pool holds exactly the desugared facts) + a
  # provider/consumer reverse-reading them at `resolution`. `gateway` is the connect target; `lonely` is claimed
  # by nobody (the empty-reverse witness). The claim strata sit densely below `resolution` (structural < connect
  # < secret < database < route), so `route` is strictly above its sub-claims and the reverse-read is in scope.
  fleet = denHoag.mkDen [
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
      config.den.node.gateway = { };
      config.den.node.lonely = { };

      # the ROUTE COMPOSITE claim (§5, strataChain composite-above-subclaims). emit = edges, from = ∅ EDB,
      # stratum = route. Its constant `compute` is a pure COMPILE-TIME FOLD (concatMap over the finite route
      # decls — Vogt 1989 finiteness statically) that DESUGARS each route into its sub-claim facts: a `secret`
      # sub-claim (stratum = secret) + a `connect` sub-claim (stratum = connect), each tagged at its OWN
      # kind/stratum strictly below `route`. The composite desugars away — only the sub-claim kinds land.
      config.den.productions.route = {
        stratum = "route";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute =
          _self: _id:
          let
            # the route decls (an app fronted at a gateway host). Finite ⇒ the fold TERMINATES.
            routes = [
              {
                app = "node:arr";
                host = "node:gateway";
              }
            ];
            # the composite-above-subclaims desugar: ONE route (app fronted at host) folds into a secret
            # sub-claim (the app's TLS material, provisioned at the host) + a connect sub-claim (the app→host
            # wiring), each at its OWN kind/stratum (strictly below route). Both target the host node so the
            # reverse-read is evaluable at a real scope node (a claim target must be a reachable node).
            desugarOne = r: [
              {
                kind = "secret";
                stratum = "secret";
                from = r.app;
                to = r.host;
              }
              {
                kind = "connect";
                stratum = "connect";
                from = r.app;
                to = r.host;
              }
            ];
          in
          builtins.concatMap desugarOne routes;
      };

      # the PROVIDER (§5) — a `resolution` attr production reverse-reading the DESUGARED sub-claims at its OWN
      # node (A9 intra-stratum positive read). `from` names a sub-claim stratum strictly below resolution
      # (L2-clean). It reads BOTH reverse sub-claim views (connect + secret), proving each desugared at its kind.
      config.den.productions.provider = {
        stratum = "resolution";
        from = [
          {
            kind = "reverse-query";
            stratum = "connect";
          }
        ];
        emit = "attr";
        mode = "all";
        readsAttrs = [ "claim-accessor" ];
        compute = self: id: {
          connectClaimedBy = (self.get id "claim-accessor").query "connect";
          secretClaimedBy = (self.get id "claim-accessor").query "secret";
        };
      };

      # the CONSUMER (§5) — a `resolution` attr production reading the PROVIDER attr intra-stratum (A9), building
      # an appWiring from the reverse connect claimers (from = ∅, L2-vacuous).
      config.den.productions.consumer = {
        stratum = "resolution";
        from = [ ];
        emit = "attr";
        mode = "all";
        readsAttrs = [ "provider" ];
        compute = self: id: {
          appWiring = map (c: "wire:${c}") (self.get id "provider").connectClaimedBy;
        };
      };
    }
  ];

  pool = fleet.den.relationEdges;
  proj = e: {
    inherit (e)
      id
      kind
      from
      to
      stratum
      ;
  };
  factsOf = k: builtins.sort (a: b: a.id < b.id) (map proj (builtins.filter (e: e.kind == k) pool));
  kindsInPool = builtins.sort builtins.lessThan (nixpkgsLib.unique (map (e: e.kind) pool));

  eval = fleet.den.structural.eval;

  # a DECLARED leaf whose constant `compute` returns ZERO facts — the declared-registry witness. `claimKinds`
  # is the reverse-read's DECLARED-REGISTRY enumeration (the L4 gate a stratified negation reads via `.rel` to
  # tell out-of-scope from absent), so a declared leaf must keep its PRESENT-returning-empty `.rel.<kind>` gate
  # under zero facts — never an attr-miss (which would data-drive the registry off the fact count).
  emptyFleet = denHoag.mkDen [
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
      config.den.productions.emptyclaim = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [ ];
      };
    }
  ];
  emptyHandle = emptyFleet.den.structural.eval.get "node:arr" "claim-accessor";

  # the §2.3 L2 strictly-below gate over a synthetic composite (value-split: the NAMED message TEXT is CI-
  # testable — tryEval cannot capture a throw's text), on the full six-stratum claim order. A composite sits
  # strictly ABOVE its sub-claims: a `route` reading a `secret` sub-claim (strictly below) is clean; a reversed
  # production (`connect` reading `route`, NOT strictly below) is rejected — the composite-above-subclaims order.
  msgOf =
    prod:
    denHoag.internal.productions.productionMessage {
      strataOrder = [
        "structural"
        "connect"
        "secret"
        "database"
        "route"
        "resolution"
      ];
      disciplineNames = [ ];
    } { p = prod; };
  baseComposite = {
    emit = "attr";
    mode = "all";
    readsAttrs = [ "claim-accessor" ];
    compute = _self: _id: { };
  };
  # a composite at `route` reading a sub-claim strictly below (`secret`) — L2-clean (composite-above-subclaims).
  goodComposite = baseComposite // {
    stratum = "route";
    from = [
      {
        kind = "reverse-query";
        stratum = "secret";
      }
    ];
  };
  # the REVERSED direction — a `connect` production reading `route` (NOT strictly below) — the L2 rejection.
  badComposite = baseComposite // {
    stratum = "connect";
    from = [
      {
        kind = "reverse-query";
        stratum = "route";
      }
    ];
  };

  # the compiled strata index (strictly-below-ascending). `route` strictly above database > secret > connect.
  strata = fleet.den.strata;
  idx = s: nixpkgsLib.lists.findFirstIndex (x: x == s) null strata;
in
{
  flake.tests.claim-route-desugar = {
    # ── (1) the route composite EXPANDS to secret + connect facts AT THEIR kinds/strata (not all "route") ──
    # the desugared `secret` sub-claim lands at kind = secret, stratum = secret (NOT route).
    test-route-desugar-secret-fact = {
      expr = factsOf "secret";
      expected = [
        {
          id = "claim:route:0";
          kind = "secret";
          from = "node:arr";
          to = "node:gateway";
          stratum = "secret";
        }
      ];
    };
    # the desugared `connect` sub-claim lands at kind = connect, stratum = connect (NOT route).
    test-route-desugar-connect-fact = {
      expr = factsOf "connect";
      expected = [
        {
          id = "claim:route:1";
          kind = "connect";
          from = "node:arr";
          to = "node:gateway";
          stratum = "connect";
        }
      ];
    };
    # the composite DESUGARS AWAY: NO pool fact is tagged with the composite kind `route` — only the sub-claims.
    test-route-desugar-no-route-kind = {
      expr = factsOf "route";
      expected = [ ];
    };
    # the pool carries EXACTLY the two desugared sub-claim kinds (heterogeneous — the composite emitted both).
    test-route-desugar-pool-kinds = {
      expr = kindsInPool;
      expected = [
        "connect"
        "secret"
      ];
    };

    # ── (2) a provider/consumer reverse-reads the DESUGARED sub-claims strictly-below → RESOLVED values ──
    # (via structural.eval.get, MR6 — warm-served resolution, never a manifest). BOTH sub-claims target
    # gateway (arr → gateway), so gateway's reverse view sees arr as its connect AND secret claimer — proving
    # the composite desugared into BOTH sub-claim kinds, each reverse-readable strictly below `resolution`.
    test-provider-reverse-desugared-connect = {
      expr = (eval.get "node:gateway" "provider").connectClaimedBy;
      expected = [ "node:arr" ];
    };
    test-provider-reverse-desugared-secret = {
      expr = (eval.get "node:gateway" "provider").secretClaimedBy;
      expected = [ "node:arr" ];
    };
    # a node claimed by NOBODY sees an EMPTY reverse view (the silent posture) — never an attr-miss.
    test-provider-reverse-unclaimed-empty = {
      expr = eval.get "node:lonely" "provider";
      expected = {
        connectClaimedBy = [ ];
        secretClaimedBy = [ ];
      };
    };
    # the consumer reads the provider-config intra-stratum → the appWiring over the desugared connect claimers.
    test-consumer-appwiring = {
      expr = (eval.get "node:gateway" "consumer").appWiring;
      expected = [ "wire:node:arr" ];
    };

    # ── (3) strataChain orders route > database > secret > connect (composite strictly-above sub-claims) ──
    # the compiled order places `route` strictly above database > secret > connect (its sub-claims).
    test-strata-route-above-subclaims = {
      expr = {
        routeAboveConnect = idx "route" > idx "connect";
        routeAboveSecret = idx "route" > idx "secret";
        routeAboveDatabase = idx "route" > idx "database";
        databaseAboveSecret = idx "database" > idx "secret";
        secretAboveConnect = idx "secret" > idx "connect";
      };
      expected = {
        routeAboveConnect = true;
        routeAboveSecret = true;
        routeAboveDatabase = true;
        databaseAboveSecret = true;
        secretAboveConnect = true;
      };
    };
    # the full compiled order — the claim strata land densely below resolution.
    test-strata-compiled-order = {
      expr = strata;
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
    # L2: a composite reading a sub-claim strictly below its own stratum is L2-clean (composite-above-subclaims).
    test-composite-l2-clean-below = {
      expr = msgOf goodComposite;
      expected = null;
    };
    # L2: the REVERSED direction (a sub-claim stratum reading the composite, NOT strictly below) is REJECTED.
    test-composite-l2-rejects-not-below = {
      expr = builtins.match ".*not strictly below.*" (msgOf badComposite) != null;
      expected = true;
    };

    # ── a DECLARED leaf with ZERO facts keeps its `.rel.<kind>` throwing gate PRESENT (returning []) ──
    # the declared-registry semantics: `claimKinds` seeds a declared leaf regardless of fact count, so the L4
    # `.rel` gate stays present (empty) rather than an attr-miss — the reverse-read distinguishes absent from
    # out-of-scope by DECLARATION, not by whether the leaf happened to emit facts.
    test-zero-fact-leaf-rel-present = {
      expr = emptyHandle.rel.emptyclaim;
      expected = [ ];
    };

    # ── (4) the fold TERMINATES: forcing the whole desugared pool computes with no divergence (finiteness) ──
    test-route-desugar-fold-terminates = {
      expr = (builtins.tryEval (builtins.deepSeq pool true)).success;
      expected = true;
    };
  };
}
