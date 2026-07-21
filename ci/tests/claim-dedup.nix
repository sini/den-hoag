# The DEDUP witness (§5 resolution facet / productions substrate, emit = nodes two-equation shape, §8
# law 5 / L5). Where a leaf claim (emit = edges) supplies ground facts and the claim-accessor delivers the §9
# transpose reverse-read, a DEDUP production (emit = nodes) is the ONE genuinely-materialized shared node: N
# claimants of the same dedupKey collapse to ONE content-addressed node (Vogt 1989 bounded-NTA finiteness —
# content-addressing is the finiteness witness: a finite EDB spawns a finite content-image).
#
# THE TWO-EQUATION SPLIT. `resolve.nta` hardcodes readsAttrs = [ ] + stratum = "structural", so an nta
# CANNOT itself read the below-stratum claim pool. So `emit = nodes` lowers to TWO equations:
#   `${name}`        = the attr-GATHER: `prod.compute` (reads the pool via readsAttrs = ["claim-accessor"],
#                      groups the reverse claimants by dedupKey → this node's { dedupKey; sharers }).
#   `${name}__spawn` = the nta-SPAWN: reads EXCLUSIVELY the gather on its OWN node (`self.get id ${name}`) and
#                      hands it to `prod.spawnNode` — the content-addressed builder (gather → the spawned decl,
#                      keyed by a content hash of the dedupKey).
# THE STRUCTURAL CLOSURE (the spawn reads ONLY the gather): `spawnNode`'s signature is `gather → decl` — it
# receives the gather VALUE, never `self`/`id`/the pool, so the spawn STRUCTURALLY cannot introduce a
# schedule-invisible below-stratum read inside the nta. This suite proves that structurally (a stub `self` that
# THROWS on any non-gather read; the spawn succeeds ⇒ it read only the gather). Header mirrors
# claim-route-desugar.nix's — ci specialArgs provides `denHoag`.
{
  denHoag,
  ...
}:
let
  # content-address a dedupKey exactly as the production's `spawnNode` does — the finiteness witness key
  # (a pure content-function of the dedupKey ONLY, never of the sharers, so N claimants collapse to ONE id).
  cid = k: "cnode:${builtins.hashString "sha256" k}";

  # THE DEDUP PRODUCTION (§5, emit = nodes). Declared ONCE + reused: in the fleet (config.den.productions.dedup)
  # AND in the standalone `compile` for the structural-closure proof. stratum = resolution (the gather reads
  # claim-accessor INTRA-stratum, A9); `from` names the claim stratum strictly below (L2-clean); identity =
  # content + keyspace + mode = all satisfy the L5 bounded-NTA guard.
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
    # the GATHER: this node's dedup bucket. dedupKey ≡ the shared-resource node id (the thing being shared —
    # the "shared API secret" node); sharers = its reverse claimants (who-claims-me via the §9 transpose).
    compute = self: id: {
      dedupKey = id;
      sharers = builtins.sort builtins.lessThan ((self.get id "claim-accessor").query "sharedsecret");
    };
    # the CONTENT-ADDRESSED spawn-builder: gather → ONE node keyed by a content hash of the dedupKey. A node
    # with NO claimants (empty sharers) spawns NOTHING (the empty pool). Receives ONLY the gather value.
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

  # the dedup fleet: two apps (appA, appB) BOTH claiming the shared secret `apitoken` (the N = 2 collapse),
  # a second app appC claiming a DISTINCT shared secret `dbpass` (the different-dedupKey witness), and
  # `lonely` claimed by nobody (the empty-spawn witness). The `sharedsecret` leaf claim sits at `connect`
  # (strictly below `resolution`), so the reverse-read is in scope and the dedup gather reads it strictly below.
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
      config.den.node.appA = { };
      config.den.node.appB = { };
      config.den.node.appC = { };
      config.den.node.apitoken = { };
      config.den.node.dbpass = { };
      config.den.node.lonely = { };

      # the sharedsecret leaf claim (emit = edges, from = ∅ EDB): appA + appB claim `apitoken` (N = 2 share ONE
      # dedupKey); appC claims `dbpass` (a distinct dedupKey). All at `connect`, strictly below `resolution`.
      config.den.productions.sharedsecret = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:appA";
            to = "node:apitoken";
          }
          {
            from = "node:appB";
            to = "node:apitoken";
          }
          {
            from = "node:appC";
            to = "node:dbpass";
          }
        ];
      };

      config.den.productions.dedup = dedupProd;
    }
  ];

  eval = fleet.den.structural.eval;

  # ── the structural-closure proof: the spawn reads ONLY the gather ──
  # compile the production STANDALONE (no fleet) and grab the raw spawn equation's compute — the framework-
  # authored `self: id: prod.spawnNode (self.get id "dedup")`. Applied against a stub `self` that returns the
  # canned gather for the "dedup" attr and THROWS for anything else, so a spawn that reached for the pool (or
  # any non-gather attr) would abort. It succeeds ⇒ the spawn read EXCLUSIVELY the gather.
  lowered = denHoag.internal.productions.compile { productions.dedup = dedupProd; };
  spawnFn = lowered.equations."dedup__spawn".compute;
  cannedGather = {
    dedupKey = "node:apitoken";
    sharers = [
      "node:appA"
      "node:appB"
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

  # ── the L5 bounded-NTA guard (value-split: the NAMED message TEXT is CI-testable) over synthetic productions ──
  # a minimal two-stratum order: structural < connect < resolution (connect strictly below resolution).
  strataOrder = [
    "structural"
    "connect"
    "resolution"
  ];
  ntaMsg =
    prod: denHoag.internal.productionGuard.boundedNtaMessage strataOrder (prod // { name = "d"; });
  # the conformant node prod (guard-clean): mode = all, from strictly-below, identity = content, no self-read.
  conformant = {
    emit = "nodes";
    mode = "all";
    stratum = "resolution";
    keyspace = "shared-nodes";
    identity = "content";
    from = [
      {
        kind = "reverse-query";
        stratum = "connect";
      }
    ];
  };
  # (clause 4) a NON-content identity — bounded-NTA finiteness requires content-addressed node identity.
  bareIdentity = conformant // {
    identity = "positional";
  };
  # (clause 3) a from source that reads the very keyspace it spawns — non-monotone / unbounded.
  selfReading = conformant // {
    from = [
      {
        kind = "reverse-query";
        stratum = "connect";
        reads = "shared-nodes";
      }
    ];
  };
  # (clause 1) mode ≠ all — a spawned-node production is a single ordered pass, not a within-stratum fixpoint.
  fixpointMode = conformant // {
    mode = "fixpoint";
  };
  # (clause 2) a from source reading NOT strictly below the emit stratum — the spawned pool is not well-founded.
  # Reachable ONLY via this nta entry: in the productionMessage path the L5 clause-2 filter is shadowed by L2.
  belowFrom = conformant // {
    from = [
      {
        kind = "reverse-query";
        stratum = "resolution";
      }
    ];
  };

  # ── the productionMessage-level spawnNode presence guard (the two-equation contract) ──
  msgOf =
    prod:
    denHoag.internal.productions.productionMessage {
      inherit strataOrder;
      disciplineNames = [ ];
    } { p = prod; };
  # an emit = nodes production MISSING spawnNode — a NAMED reject (else an uncatchable attr-miss in lowerOne).
  noSpawnNode = {
    stratum = "resolution";
    emit = "nodes";
    mode = "all";
    identity = "content";
    keyspace = "shared-nodes";
    readsAttrs = [ "claim-accessor" ];
    compute = _self: _id: { };
    from = [ ];
  };
in
{
  flake.tests.claim-dedup = {
    # ── (1) N = 2 claimants of ONE dedupKey collapse to ONE content-addressed shared node (RESOLVED via eval.get) ──
    # the spawn on the shared `apitoken` node emits EXACTLY ONE node (the two claimants collapsed).
    test-dedup-collapse-one-node = {
      expr = builtins.length (builtins.attrNames (eval.get "node:apitoken" "dedup__spawn"));
      expected = 1;
    };
    # …that ONE node is CONTENT-ADDRESSED by the dedupKey and aggregates BOTH sharers (the shared value).
    test-dedup-shared-node-value = {
      expr = eval.get "node:apitoken" "dedup__spawn";
      expected = {
        ${cid "node:apitoken"} = {
          dedupKey = "node:apitoken";
          sharers = [
            "node:appA"
            "node:appB"
          ];
        };
      };
    };
    # the content id is a pure function of the dedupKey (the finiteness witness key) — it equals cid(dedupKey).
    test-dedup-content-addressed-id = {
      expr = builtins.head (builtins.attrNames (eval.get "node:apitoken" "dedup__spawn"));
      expected = cid "node:apitoken";
    };

    # ── (2) a DIFFERENT dedupKey spawns a DISTINCT node ──
    test-dedup-distinct-node = {
      expr = eval.get "node:dbpass" "dedup__spawn";
      expected = {
        ${cid "node:dbpass"} = {
          dedupKey = "node:dbpass";
          sharers = [ "node:appC" ];
        };
      };
    };
    # the two shared nodes carry DISTINCT content ids (apitoken ≠ dbpass).
    test-dedup-distinct-content-ids = {
      expr =
        (builtins.head (builtins.attrNames (eval.get "node:apitoken" "dedup__spawn")))
        != (builtins.head (builtins.attrNames (eval.get "node:dbpass" "dedup__spawn")));
      expected = true;
    };
    # a node claimed by NOBODY spawns NOTHING (the empty content-image) — never an attr-miss.
    test-dedup-unclaimed-empty = {
      expr = eval.get "node:lonely" "dedup__spawn";
      expected = { };
    };

    # ── (3) the structural closure: the spawn reads EXCLUSIVELY the gather (proof against a throw-on-pool stub) ──
    test-spawn-reads-only-gather = {
      expr = spawnFn stubSelf "node:apitoken";
      expected = {
        ${cid "node:apitoken"} = cannedGather;
      };
    };

    # ── (4) the L5 bounded-NTA guard passes the conformant spawn + NAMED-rejects the malformed ones ──
    test-l5-conformant-clean = {
      expr = ntaMsg conformant;
      expected = null;
    };
    test-l5-non-content-rejected = {
      expr = builtins.match ".*content-addressed.*" (ntaMsg bareIdentity) != null;
      expected = true;
    };
    test-l5-self-reading-rejected = {
      expr = builtins.match ".*may not read its own spawned keyspace.*" (ntaMsg selfReading) != null;
      expected = true;
    };
    test-l5-fixpoint-mode-rejected = {
      expr = builtins.match ".*requires mode = all.*" (ntaMsg fixpointMode) != null;
      expected = true;
    };
    test-l5-from-not-below-rejected = {
      expr = builtins.match ".*not strictly below.*" (ntaMsg belowFrom) != null;
      expected = true;
    };
    # the TWO-equation contract: an emit = nodes production missing `spawnNode` is a NAMED registration reject.
    test-nodes-missing-spawnnode-rejected = {
      expr = builtins.match ".*declares no .spawnNode.*" (msgOf noSpawnNode) != null;
      expected = true;
    };
  };
}
