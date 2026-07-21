# WITNESS 2 — the CONSOLIDATED end-to-end claim/provide engine (spec §10 headline deliverable, §5 resolution
# facet / productions substrate). The sibling suites each proved ONE piece in ISOLATION: claim-pool.nix (EDB
# leaf claims + cyclic connect), claim-route-desugar.nix (composite → sub-claim fold), claim-provider.nix (§9
# transpose reverse-read → provider/consumer wiring), claim-dedup.nix (emit = nodes two-equation content-
# addressed collapse), claim-negation.nix (stratified L4 lockdown). THIS suite proves they COMPOSE: a SINGLE
# synthetic media-style fleet declares ALL of them in ONE `den.productions` + ONE `strataChain`, resolved
# through the ONE `structural.eval`. The value over the per-piece suites is the composed end-state — the pool
# holds every claim kind at once, the ONE claim-accessor delivers the whole pool's reverse-read, and every
# resolution production (provider / consumer / dedup gather+spawn / lockdown) resolves at its node WITHOUT
# interference. Where pieces share a claim kind they compose by TARGET NODE (a leaf `connect` claim and the
# route-desugared `connect` sub-claim coexist in one pool, disambiguated by endpoint — see
# test-compose-forward-connect). Header mirrors claim-provider.nix's — ci specialArgs provides `denHoag`.
{
  denHoag,
  nixpkgsLib,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # content-address a dedupKey exactly as the dedup production's `spawnNode` does — the Vogt 1989 bounded-NTA
  # finiteness witness key (a pure content-function of the dedupKey ONLY, so N claimants collapse to ONE id).
  cid = k: "cnode:${builtins.hashString "sha256" k}";

  # THE DEDUP PRODUCTION (§5, emit = nodes), declared ONCE + reused: in the fleet AND in the standalone
  # `compile` for the structural-closure proof (the spawn reads ONLY the gather). Shape drawn from
  # claim-dedup.nix: stratum = resolution (the gather reads claim-accessor INTRA-stratum, A9); `from` names the
  # claim stratum strictly below (L2-clean); identity = content + keyspace + mode = all satisfy the L5 guard.
  dedupProd = {
    stratum = "resolution";
    from = [
      {
        kind = "reverse-query";
        stratum = "connect";
      }
    ];
    emit = "nodes";
    mode = "all";
    identity = "content";
    keyspace = "shared-nodes";
    readsAttrs = [ "claim-accessor" ];
    # the GATHER: this node's dedup bucket. dedupKey ≡ the shared-resource node id; sharers = its reverse
    # claimants (who-shares-me via the §9 transpose over the `sharedsecret` claim kind).
    compute = self: id: {
      dedupKey = id;
      sharers = builtins.sort builtins.lessThan ((self.get id "claim-accessor").query "sharedsecret");
    };
    # the CONTENT-ADDRESSED spawn-builder: gather → ONE node keyed by a content hash of the dedupKey. A node
    # with NO claimants (empty sharers) spawns NOTHING. Receives ONLY the gather value (never self/id/the pool).
    spawnNode =
      g:
      if g.sharers == [ ] then
        { }
      else
        {
          ${cid g.dedupKey} = {
            inherit (g) dedupKey sharers;
          };
        };
  };

  # THE ONE FLEET — a synthetic media-style deployment where every claim/provide piece COEXISTS:
  #   apps arr/prowlarr        — the cyclic `connect` pair (arr↔prowlarr, two facts at one acyclic stratum).
  #   apps sonarr/radarr       — both share the `apitoken` secret (the N = 2 dedup collapse).
  #   nodes hub/rootapp/midapp — the `member` group for the lockdown negation.
  #   node gateway             — the route composite's front-host (secret + connect sub-claims desugar here).
  #   node apitoken            — the shared-secret node the dedup collapses onto.
  #   node lonely              — claimed by nobody (the empty-reverse / empty-spawn witness).
  # Claim strata sit densely below `resolution` via `strataChain` (structural < connect < secret < database <
  # route < resolution), so every resolution-level provider/dedup/lockdown reverse-reads its claim strata
  # strictly below (§2.3 L2) and the whole pool is in scope for the ONE claim-accessor.
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
      config.den.node.prowlarr = { };
      config.den.node.sonarr = { };
      config.den.node.radarr = { };
      config.den.node.gateway = { };
      config.den.node.apitoken = { };
      config.den.node.hub = { };
      config.den.node.rootapp = { };
      config.den.node.midapp = { };
      config.den.node.lonely = { };

      # ── LEAF claims (emit = edges, from = ∅ EDB — pure ground facts, off-trace §7) ──
      # the cyclic `connect` pair: arr claims prowlarr AND prowlarr claims arr = TWO distinct facts at ONE
      # acyclic stratum (a cycle in who-connects-whom is NOT a stratum cycle, so the fleet builds).
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
      # a `secret` leaf claim + a `database` leaf claim — EDGE-UNIFORM across kinds (one CONSTANT ⇒ N pool
      # edges, lowered identically regardless of kind).
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
      # the `sharedsecret` leaf claim (at `connect`, strictly below `resolution`): sonarr + radarr BOTH claim
      # `apitoken` (the N = 2 collapse the dedup production folds onto ONE shared node).
      config.den.productions.sharedsecret = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:sonarr";
            to = "node:apitoken";
          }
          {
            from = "node:radarr";
            to = "node:apitoken";
          }
        ];
      };
      # the `member` leaf claim (at `connect`) for the lockdown negation: rootapp (a ROOT — nobody claims it),
      # midapp (a NON-root — hub claims it back), and hub itself (the `@self` self-claim) all claim hub.
      config.den.productions.member = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:rootapp";
            to = "node:hub";
          }
          {
            from = "node:midapp";
            to = "node:hub";
          }
          {
            from = "node:hub";
            to = "node:hub";
          }
          {
            from = "node:hub";
            to = "node:midapp";
          }
        ];
      };
      # an OUT-OF-SCOPE claim declared AT the accessor's own stratum (`resolution`) — NOT strictly below it, so
      # `.query` hides it (silent) and `.rel` NAMED-throws (the L4 capability boundary the negation consumes to
      # tell out-of-scope from absent).
      config.den.productions.oosclaim = {
        stratum = "resolution";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:rootapp";
            to = "node:hub";
          }
        ];
      };

      # ── the COMPOSITE `route` claim (emit = edges, a pure COMPILE-TIME desugar fold, §G static pool) ──
      # ONE route (app fronted at a gateway host) folds into a `secret` sub-claim + a `connect` sub-claim, each
      # tagged at its OWN kind/stratum STRICTLY BELOW `route`. The composite desugars AWAY (no `route`-kind fact
      # lands); both sub-claims target `gateway`, so they compose with the leaf `connect`/`secret` by endpoint.
      config.den.productions.route = {
        stratum = "route";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute =
          _self: _id:
          let
            routes = [
              {
                app = "node:arr";
                host = "node:gateway";
              }
            ];
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

      # ── resolution-level productions — every one reads the ONE claim-accessor INTRA-stratum (A9) ──
      # the PROVIDER: reverse-reads who-claims-me under `connect` at its OWN node → a provider-config.
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
        };
      };
      # the CONSUMER: reads the PROVIDER attr intra-stratum (from = ∅, L2-vacuous) → an appWiring.
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
      # the DEDUP (§5, emit = nodes) — the content-addressed collapse (declared above, reused for the closure proof).
      config.den.productions.dedup = dedupProd;
      # the LOCKDOWN negation (§5, L4, Apt–Blair–Walker) — reads the negated `member` claim via the THROWING
      # `.rel` gate (strictly-above the negated stratum, L2-clean). NON-MONOTONE: EXCLUDES `@self` and non-roots
      # (a claimant whose OWN reverse view is non-empty), so only ROOT claimants survive.
      config.den.productions.lockdown = {
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
        compute =
          self: id:
          let
            claimants = (self.get id "claim-accessor").rel.member;
            isRoot = c: ((self.get c "claim-accessor").rel.member) == [ ];
            survivors = builtins.filter (c: c != id && isRoot c) claimants;
          in
          {
            lockdown = builtins.sort builtins.lessThan survivors;
          };
      };
    }
  ];

  eval = fleet.den.structural.eval;
  handleAt = id: eval.get id "claim-accessor";

  # the off-trace pool (the composed EDB): the witness declares NO `den.relations`, so the pool holds EXACTLY
  # the production leaf-claim + desugared-sub-claim facts across ALL kinds at once.
  pool = fleet.den.relationEdges;
  proj = e: {
    inherit (e)
      id
      kind
      from
      to
      ;
  };
  # facts filtered by their production-keyed id prefix (`claim:<production>:<index>`), so a kind shared by two
  # productions (e.g. `connect` from the leaf AND the route desugar) is disambiguated by SOURCE production.
  factsByPrefix =
    p:
    builtins.sort (a: b: a.id < b.id) (
      map proj (builtins.filter (e: nixpkgsLib.strings.hasPrefix p e.id) pool)
    );

  # ── the structural-closure proof (the ★ integration-level assertion, replicated from claim-dedup.nix) ──
  # compile the dedup production STANDALONE and grab the raw spawn equation's compute — the framework-authored
  # `self: id: prod.spawnNode (self.get id "dedup")`. Applied against a stub `self` returning the canned gather
  # for the "dedup" attr and THROWING for anything else: it succeeds ⇒ the spawn read EXCLUSIVELY its gather
  # (else the emit = nodes two-equation MR-hole re-opens — a schedule-invisible below-stratum read in the nta).
  lowered = denHoag.internal.productions.compile { productions.dedup = dedupProd; };
  spawnFn = lowered.equations."dedup__spawn".compute;
  cannedGather = {
    dedupKey = "node:apitoken";
    sharers = [
      "node:radarr"
      "node:sonarr"
    ];
  };
  stubSelf = {
    get =
      _id: attr:
      if attr == "dedup" then
        cannedGather
      else
        throw "emit=nodes spawn read a non-gather attr '${attr}' — it must read exclusively its gather";
  };
in
{
  flake.tests.claim-provide-witness = {
    # ── (1) EDB leaf claims land in the composed pool (queryable), edge-uniform across kinds ──
    test-edb-connect-leaf-lands = {
      expr = factsByPrefix "claim:connect:";
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
    test-edb-secret-leaf-lands = {
      expr = factsByPrefix "claim:secret:";
      expected = [
        {
          id = "claim:secret:0";
          kind = "secret";
          from = "node:arr";
          to = "secret:arr-apikey";
        }
      ];
    };
    test-edb-database-leaf-lands = {
      expr = factsByPrefix "claim:database:";
      expected = [
        {
          id = "claim:database:0";
          kind = "database";
          from = "node:arr";
          to = "db:main";
        }
      ];
    };

    # ── (2) the route composite DESUGARS to secret + connect sub-claims AT their kinds/strata (not "route") ──
    test-route-desugar-subclaims = {
      expr = factsByPrefix "claim:route:";
      expected = [
        {
          id = "claim:route:0";
          kind = "secret";
          from = "node:arr";
          to = "node:gateway";
        }
        {
          id = "claim:route:1";
          kind = "connect";
          from = "node:arr";
          to = "node:gateway";
        }
      ];
    };
    # the composite desugars AWAY — no pool fact carries the composite kind `route`.
    test-route-desugar-no-route-kind = {
      expr = builtins.filter (e: e.kind == "route") pool;
      expected = [ ];
    };

    # ── (3) the PROVIDER reverse-reads who-claims-me via the claim-accessor → a provider-config (RESOLVED) ──
    # prowlarr's reverse `connect` view = [arr] (from the leaf cyclic arr→prowlarr); the route sub-claim targets
    # gateway, NOT prowlarr, so it does not pollute — the pieces compose by endpoint.
    test-provider-reverse-config = {
      expr = eval.get "node:prowlarr" "provider";
      expected = {
        connectClaimedBy = [ "node:arr" ];
      };
    };
    # gateway's reverse `connect` view = [arr] (from the DESUGARED route sub-claim) — the composite piece,
    # reverse-read through the SAME provider that serves the leaf piece.
    test-provider-reverse-desugared = {
      expr = eval.get "node:gateway" "provider";
      expected = {
        connectClaimedBy = [ "node:arr" ];
      };
    };
    # a node claimed by NOBODY sees an EMPTY reverse view (the silent posture) — never an attr-miss.
    test-provider-unclaimed-empty = {
      expr = eval.get "node:lonely" "provider";
      expected = {
        connectClaimedBy = [ ];
      };
    };

    # ── (4) the CONSUMER reads the provider-config intra-stratum → the appWiring (RESOLVED via eval.get) ──
    test-consumer-appwiring = {
      expr = eval.get "node:prowlarr" "consumer";
      expected = {
        appWiring = [ "wire:node:arr" ];
      };
    };

    # ── (5) DEDUP: N = 2 claimants of ONE dedupKey collapse to ONE content-addressed shared node (RESOLVED) ──
    test-dedup-collapse-one-node = {
      expr = builtins.length (builtins.attrNames (eval.get "node:apitoken" "dedup__spawn"));
      expected = 1;
    };
    test-dedup-shared-node-value = {
      expr = eval.get "node:apitoken" "dedup__spawn";
      expected = {
        ${cid "node:apitoken"} = {
          dedupKey = "node:apitoken";
          sharers = [
            "node:radarr"
            "node:sonarr"
          ];
        };
      };
    };
    # a node shared by NOBODY spawns the empty content-image — never an attr-miss.
    test-dedup-unclaimed-empty = {
      expr = eval.get "node:lonely" "dedup__spawn";
      expected = { };
    };

    # ── (6) the LOCKDOWN negation EXCLUDES correctly (throwing `.rel`, strictly-above, `@self` excluded) ──
    # hub is claimed by rootapp (root), midapp (non-root), hub (@self) — only rootapp survives the lockdown.
    test-lockdown-survivors = {
      expr = (eval.get "node:hub" "lockdown").lockdown;
      expected = [ "node:rootapp" ];
    };
    # `@self` (the self-claim) is EXCLUDED — hub is not in its own survivors.
    test-lockdown-excludes-self = {
      expr = builtins.elem "node:hub" (eval.get "node:hub" "lockdown").lockdown;
      expected = false;
    };
    # the THROWING gate: an out-of-scope `.rel` read NAMED-throws (capturable) while the silent `.query` on the
    # SAME kind is empty — the L4 routing distinction a sound negation consumes.
    test-lockdown-rel-oos-throws = {
      expr = throws (handleAt "node:hub").rel.oosclaim;
      expected = true;
    };
    test-lockdown-query-oos-silent = {
      expr = (handleAt "node:hub").query "oosclaim";
      expected = [ ];
    };

    # ── (7) the cyclic connect pair = TWO distinct facts; the whole composed fleet EVALUATES (no divergence) ──
    test-cyclic-two-distinct-facts = {
      expr =
        let
          cs = factsByPrefix "claim:connect:";
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
    # forcing the ENTIRE composed pool (every claim kind at once) computes with no eval divergence.
    test-composed-pool-terminates = {
      expr = (builtins.tryEval (builtins.deepSeq pool true)).success;
      expected = true;
    };

    # ── (8) ★ the structural closure: the dedup spawn reads EXCLUSIVELY its gather (throw-on-pool stub) ──
    test-spawn-reads-only-gather = {
      expr = spawnFn stubSelf "node:apitoken";
      expected = {
        ${cid "node:apitoken"} = cannedGather;
      };
    };

    # ── COMPOSITION: the pieces do not INTERFERE when all present in ONE fleet ──
    # a shared claim kind composes by ENDPOINT: arr's forward `connect` egress now unions the leaf target
    # (prowlarr) with the route-desugared target (gateway) — both facts live in the one pool, one query spine.
    test-compose-forward-connect = {
      expr = builtins.sort builtins.lessThan (
        denHoag.query {
          edges = pool;
          from = "node:arr";
          follow = "connect";
          mode = "all";
        }
      );
      expected = [
        "node:gateway"
        "node:prowlarr"
      ];
    };
    # the WHOLE claim-strata set orders the composed fleet (structural < connect < secret < database < route <
    # resolution) — the ONE strataChain governs every piece.
    test-compose-strata-order = {
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
    # the headline: EVERY piece resolves TOGETHER through the ONE structural.eval — the route-desugared
    # provider, the dedup collapse, the lockdown negation, and the leaf-fed consumer all warm-served at once,
    # each at its node, with no cross-piece interference.
    test-compose-all-pieces-coresolve = {
      expr = {
        routeProvider = (eval.get "node:gateway" "provider").connectClaimedBy;
        dedupCollapse = builtins.attrNames (eval.get "node:apitoken" "dedup__spawn");
        lockdownSurvivors = (eval.get "node:hub" "lockdown").lockdown;
        leafConsumer = (eval.get "node:prowlarr" "consumer").appWiring;
      };
      expected = {
        routeProvider = [ "node:arr" ];
        dedupCollapse = [ (cid "node:apitoken") ];
        lockdownSurvivors = [ "node:rootapp" ];
        leafConsumer = [ "wire:node:arr" ];
      };
    };
  };
}
