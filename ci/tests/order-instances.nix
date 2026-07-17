# The merge-order ORACLES (spec §6) — one file for the three framework discipline instances. Each
# instance DECLARES a merge order (`order = { tiers; withinTier; tieBreak }`); the oracle here proves the
# DECLARATION matches the LIVE fold — the byte-parity proof that "declare, not rewire" is honest. The
# fold code is UNCHANGED (an AC per instance); the oracle reads the production attribute's own provenance
# surface and asserts the order it observes is the order the instance declares. A drifted declaration (or
# a drifted `combine` reference) is caught here. See REFERENCE.md.
#
# T3 lands the `settings-layers` oracle; T4 the collections-neron; T5 the reach-closure oracle.
{
  denHoag,
  denHoagSrc,
  ...
}:
let
  sel = denHoag.sel;
  # the A12 producer sort (scope-adapter.nix `sortByProducer` over `producerLt`) — for the tie-break
  # triple-shape pin (rank < identity < emissionIndex) against the live scope-adapter behavior.
  inherit (denHoag.internal.scopeAdapter) sortByProducer;
  # the reach attribute driven synthetically (the reach-graph.nix precedent): import resolved-aspects.nix
  # with the REAL internal deps and drive `reach.compute stub id` against a stub graph — reach-edges have
  # no policy vocabulary yet, so the closure is exercised as a pure graph function.
  inherit (denHoag.internal)
    prelude
    scope
    resolve
    aspects
    select
    ;
  raReach =
    (import "${denHoagSrc}/lib/attributes/resolved-aspects.nix" {
      inherit
        prelude
        scope
        resolve
        aspects
        select
        ;
    } { }).reach;

  # ── settings-layers (§2.7): the per-(node, aspect) layer fold ────────────────────────────────────
  # A synthetic multi-level fleet: env prod ⊇ host axon ⊇ user alice, with an aspect carrying a schema
  # default and scoped-override layers at EVERY containment level (env, env+host, env+host+user) plus a
  # terminal `configure` policy. The live resolved-settings provenance lists every layer in §2.7 order;
  # the oracle classifies each into its tier and asserts the tier sequence matches the declaration.
  fleetBase = [
    {
      config.den.schema = {
        env.parent = null;
        host.parent = "env";
        user.parent = "host";
      };
    }
    {
      config.den = {
        env.prod = { };
        host.axon = { };
        user.alice = { };
      };
    }
    (
      { config, ... }:
      {
        config.den.membership = [
          {
            coords = {
              env = config.den.env.prod;
              host = config.den.host.axon;
            };
          }
          {
            coords = {
              host = config.den.host.axon;
              user = config.den.user.alice;
            };
          }
        ];
      }
    )
  ];
  mod =
    { config, ... }:
    {
      config.den.aspects.app = {
        neededBy = sel.kind config.den.schema.user; # radiate to the user cell
        settings.level.default = "info"; # the schema-default tier
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
      ];
      # scoped overrides at each containment level (least → most specific) — the `contains` + `slice` tiers.
      config.den.settings.layers = [
        {
          at = {
            env = config.den.env.prod;
          };
          of = config.den.aspects.app;
          set = {
            level = "envlvl";
          };
        }
        {
          at = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
          of = config.den.aspects.app;
          set = {
            level = "hostlvl";
          };
        }
        {
          at = {
            env = config.den.env.prod;
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
          of = config.den.aspects.app;
          set = {
            level = "celllvl";
          };
        }
      ];
      # terminal `configure` policy → the `policy` tier (authority-wins by position, A8).
      config.den.policies.setLvl =
        { user, ... }:
        [
          (denHoag.declare.configure {
            of = config.den.aspects.app;
            set = {
              level = "policylvl";
            };
          })
        ];
    };

  den = (denHoag.mkDen (fleetBase ++ [ mod ])).den;
  settingsInst = den.disciplines.settings-layers;
  cellId = "user:alice@host:axon";
  prov = (den.structural.eval.get cellId "resolved-settings").app.provenance.level;
  renderedOrder = map (e: e.rendered) prov;

  # ── the COMBINE VALUE-AGREEMENT pin (proof comment (iii) is true) ──
  # The order oracle checks the layer ORDER; the law harness checks the LAWS; neither invokes the
  # instance's `combine`. This closes that seam: fold the live per-layer VALUES (the provenance carries
  # them in fold order) through `settingsInst.combine` from `settingsInst.empty`, and assert the result
  # equals the LIVE resolved value. A drifted-but-lawful combine reference (a fold that orders right and
  # obeys the laws but computes a different field merge) is caught HERE, nowhere else. (This is a finite-
  # sample witness on ONE cell's layer values — a point check, not a universal proof; combined with the
  # source-level combine-by-reference it certifies the declaration tracks production.)
  layerValueRecs = map (e: { level = e.value; }) prov;
  foldedViaInstance = builtins.foldl' settingsInst.combine settingsInst.empty layerValueRecs;
  liveValue = (den.structural.eval.get cellId "resolved-settings").app.value;

  # the cell's full product-dimension count (env, host, user) — a slice at the full coords is the cell's
  # OWN slice (`slice` tier); a strict-ancestor slice (fewer coords) is a containment layer (`contains`).
  fullDimCount = builtins.length den.dimKinds;
  # coordinate count of a slice's rendered label ("env=prod,host=axon" → 2). `builtins.split` interleaves
  # the separator matches (empty lists) between the string parts, so the STRING parts are the coordinates.
  coordCount = r: builtins.length (builtins.filter builtins.isString (builtins.split "," r));
  # classify one provenance `rendered` label into its declared tier.
  tierOf =
    r:
    if r == "default" then
      "schema-default"
    else if r == "policy" then
      "policy"
    else if coordCount r == fullDimCount then
      "slice"
    else
      "contains";
  # the tier of each layer, in fold order, with consecutive duplicates collapsed → the TIER SEQUENCE the
  # live fold realizes (e.g. [schema-default, contains, contains, slice, policy] → the 4-tier order).
  lastOf = xs: builtins.elemAt xs (builtins.length xs - 1);
  dedupConsecutive =
    xs: builtins.foldl' (acc: x: if acc != [ ] && lastOf acc == x then acc else acc ++ [ x ]) [ ] xs;
  liveTierSequence = dedupConsecutive (map tierOf renderedOrder);

  # ── the env-tier golden fleet: a ≥3-level containment chain, least-specific-first ────────────────
  # The same fleet exercises it (env ⊃ host ⊃ user is a 3-level chain); the golden pins that the ANCESTOR
  # slices (the `contains` tier) appear least-specific-first — env before host — never most-specific-first.
  # `containsRendered` = the rendered labels classified into the `contains` tier, in fold order.
  containsRendered = builtins.filter (r: tierOf r == "contains") renderedOrder;

  # ── collections-neron (§6 / B5): the channel-contribution fold ───────────────────────────────────
  # A synthetic fleet: env prod ⊇ host axon ⊇ user alice, host producing the nixos class. TWO aspects
  # emit to a plain channel AND a dedup-declaring channel at the SAME position (the host include) — a
  # same-position multi-producer tie the A12 order breaks. The received-collections output at the cell
  # carries `.contributions` (A12-ordered) and `.values` (the folded channel value).
  collInst = den.disciplines.collections-neron;
  collBase = [
    {
      config.den.schema = {
        env.parent = null;
        host.parent = "env";
        user.parent = "host";
      };
    }
    {
      config.den = {
        env.prod = { };
        host.axon = { };
        user.alice = { };
      };
    }
    (
      { config, ... }:
      {
        config.den.membership = [
          {
            coords = {
              env = config.den.env.prod;
              host = config.den.host.axon;
            };
          }
          {
            coords = {
              host = config.den.host.axon;
              user = config.den.user.alice;
            };
          }
        ];
      }
    )
    { config.den.contentClass.host = "nixos"; }
    { config.den.quirks.peers = { }; } # a plain channel (no dedup)
    # a channel that DECLARES dedup keep=first (default channels never exercise dedup — the review trap)
    {
      config.den.quirks.deduped.channel.dedup = {
        key = "identity";
        keep = "first";
      };
    }
  ];
  # two aspects at ONE position (the host include), both emitting to both channels; `includeOrder`
  # permutes the include list (⇒ the resolved-aspects order) to prove A12 is declaration-order-independent.
  collMod =
    includeOrder:
    { config, ... }:
    {
      config.den.aspects = {
        alpha = {
          peers = [ "a" ];
          deduped = [ "a" ];
        };
        beta = {
          peers = [ "b" ];
          deduped = [ "b" ];
        };
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = includeOrder config;
        }
      ];
    };
  collCellId = "user:alice@host:axon";
  rcOf =
    includeOrder:
    (denHoag.mkDen (collBase ++ [ (collMod includeOrder) ])).den.structural.eval.get collCellId
      "received-collections";
  rcFwd = rcOf (config: [
    config.den.aspects.alpha
    config.den.aspects.beta
  ]);
  rcRev = rcOf (config: [
    config.den.aspects.beta
    config.den.aspects.alpha
  ]);
  producersOf = rc: chName: map (c: c.producer.aspect.name or null) rc.${chName}.contributions;

  # the value-agreement pin: fold the peers contributions' VALUES through the INSTANCE's own combine from
  # its empty, and assert it equals the live channel value (the declared algebra computes production's).
  peersContribValues = map (c: c.value) rcFwd.peers.contributions;
  peersFoldedViaInstance = builtins.foldl' collInst.combine collInst.empty peersContribValues;
  peersLiveValue = rcFwd.peers.values;

  # the A12 tie-break TRIPLE shape (rank < identity < emissionIndex): three annotated records that each
  # differ at exactly ONE precedence level, sorted by `sortByProducer`. rank dominates identity dominates
  # emissionIndex — so the sorted contributions come out in the order the triple dictates.
  a12Recs = [
    # differs at emissionIndex only (same rank+identity) — the weakest key
    {
      rank = 0;
      identity = "id-x";
      emissionIndex = 1;
      contribution = "x1";
    }
    {
      rank = 0;
      identity = "id-x";
      emissionIndex = 0;
      contribution = "x0";
    }
    # differs at identity (a later identity, but same rank) — beats emissionIndex
    {
      rank = 0;
      identity = "id-y";
      emissionIndex = 0;
      contribution = "y0";
    }
    # differs at rank (rank 1, policy) — beats everything, sorts LAST
    {
      rank = 1;
      identity = "id-a";
      emissionIndex = 0;
      contribution = "p0";
    }
  ];
  a12Sorted = sortByProducer a12Recs;

  # ── reach-closure (§1/§2): the per-scope single-visit resolved-aspect closure ────────────────────
  # A synthetic reach graph (the reach-graph.nix stub pattern): `src` has an own aspect + a descendant
  # `cell` (the STRUCTURAL subtree) and a positive reach-edge to `ext`. `ext` carries a fresh aspect AND
  # one whose key is ALREADY present structurally (via `cell`) — so the edge closure dedups it (first-
  # occurrence, structural wins). The live reach order is: structural verbatim, then edge, dedup-gated.
  reachInst = den.disciplines.reach-closure;
  mkAspectNode = key: {
    inherit key;
    content = {
      home-manager.tag = key;
    };
  };
  nSrcOwn = mkAspectNode "src-own";
  nShared = mkAspectNode "shared";
  nExtOnly = mkAspectNode "ext-only";
  reachStub = graph: {
    get =
      id: attr:
      if attr == "resolved-aspects" then
        (graph.${id} or { resolved = [ ]; }).resolved or [ ]
      else if attr == "declarations" then
        { actions.resolution = (graph.${id} or { }).edges or [ ]; }
      else if attr == "children" then
        (graph.${id} or { }).children or { }
      else
        throw "reach-order stub: unexpected attr ${attr}";
    node = id: (graph.${id} or { }).node or { };
  };
  reachGraph = {
    src = {
      resolved = [ nSrcOwn ];
      children.cell = { }; # the structural descendant
      edges = [
        {
          __action = "reach-edge";
          target = "ext";
          classFilter = null;
        }
      ];
    };
    cell.resolved = [ nShared ]; # structural subtree carries `shared`
    ext.resolved = [
      nExtOnly
      nShared
    ]; # the edge target: a fresh key + a structurally-seen one
  };
  reachNodes = raReach.compute (reachStub reachGraph) "src";
  reachKeys = map (n: n.key) reachNodes;

  # the components for the VALUE-AGREEMENT pin: the STRUCTURAL subtree nodes (src own ++ cell descendant,
  # emitted verbatim — the u24 multiplicity component, seeding the seen-set) and the reach-EDGE target's
  # contribution. Folding the instance combine from the structural seed over the edge contribution
  # reproduces the live reach (structural verbatim, edge deduped first-occurrence against the structural
  # keys) — the restatement IS the production algebra.
  structuralNodes = reachGraph.src.resolved ++ reachGraph.cell.resolved;
  edgeContribution = reachGraph.ext.resolved;
  reachFoldedViaInstance = builtins.foldl' reachInst.combine structuralNodes [ edgeContribution ];

  # the three-cells structural-multiplicity fixture (the u24 exemption, reach-graph.nix per-provider
  # multiplicity): three DISTINCT cell scopes each carrying the SAME-key aspect all survive via the
  # structural component (distinct ctx-eval results, NOT a bare-key collapse). dedup NEVER applies here.
  nAcct = mkAspectNode "acct";
  threeCellsGraph = {
    host = {
      resolved = [ ];
      children = {
        c1 = { };
        c2 = { };
        c3 = { };
      };
    };
    c1.resolved = [ nAcct ];
    c2.resolved = [ nAcct ];
    c3.resolved = [ nAcct ];
  };
  threeCellsKeys = map (n: n.key) (raReach.compute (reachStub threeCellsGraph) "host");
in
{
  flake.tests.order-instances = {
    # ── settings-layers DECLARATION pins ──
    # the instance declares the ordered-monoid laws (order-bearing last-wins-per-field, NOT commutative).
    test-settings-instance-laws = {
      expr = settingsInst.laws;
      expected = "ordered-monoid";
    };
    # the declared tier order (§2.7): schema defaults, then the containment chain, then the scoped-override
    # slices, then the terminal policy layer.
    test-settings-instance-tiers = {
      expr = settingsInst.order.tiers;
      expected = [
        "schema-default"
        "contains"
        "slice"
        "policy"
      ];
    };
    # within-tier rank is the §2.7 linearization (product count-major in `slice`; containment depth
    # descending in `contains`); no producer ties at the layer fold (one layer per aspect/scope/rendered).
    test-settings-instance-within-tier = {
      expr = {
        withinTier = settingsInst.order.withinTier;
        tieBreak = settingsInst.order.tieBreak;
        dedup = settingsInst.dedup;
      };
      expected = {
        withinTier = "linearization";
        tieBreak = null;
        dedup = null;
      };
    };
    # the nominal engine reference (the fold ENGINE leg): the production fold is gen-algebra's traced fold.
    test-settings-instance-engine = {
      expr = settingsInst.engine;
      expected = "gen-algebra record.foldLayersTraced";
    };

    # ── THE ORDER ORACLE (byte-parity proof): the LIVE fold's layer order matches the DECLARATION ──
    # the raw provenance order the live settings attribute folds (default → containment chain → cell → policy).
    test-settings-oracle-rendered-order = {
      expr = renderedOrder;
      expected = [
        "default"
        "env=prod"
        "env=prod,host=axon"
        "env=prod,host=axon,user=alice"
        "policy"
      ];
    };
    # the DECLARED tier sequence IS the sequence the live fold realizes (each rendered label classified into
    # its tier, consecutive duplicates collapsed) — the declaration matches production, so a drift is caught.
    test-settings-oracle-tier-sequence-matches-declaration = {
      expr = liveTierSequence == settingsInst.order.tiers;
      expected = true;
    };
    # THE COMBINE VALUE-AGREEMENT: folding the live per-layer values through the INSTANCE's own `combine`
    # reproduces the live resolved value — the declared algebra computes what production computes (a
    # drifted-but-lawful combine is caught here; the order oracle and law harness never invoke `combine`).
    test-settings-oracle-combine-value-agreement = {
      expr = foldedViaInstance == liveValue;
      expected = true;
    };

    # ── ENV-TIER GOLDEN (risk register #3): least-specific-first on a ≥3-level containment chain ──
    # the containment (`contains`-tier) slices appear LEAST-SPECIFIC-FIRST — the 1-coord env slice before
    # the 2-coord host slice — the §2.7 "least-specific first" order (an override at a broader scope is
    # laid down before a narrower one, so the narrower wins by position).
    test-golden-settings-env-tier-least-specific-first = {
      expr = containsRendered;
      expected = [
        "env=prod"
        "env=prod,host=axon"
      ];
    };

    # ── collections-neron DECLARATION pins ──
    # the channel fold is order-bearing (the pinned neron sequence), so ordered-monoid.
    test-collections-instance-laws = {
      expr = collInst.laws;
      expected = "ordered-monoid";
    };
    # one tier — the pinned traversal IS the order; the within-tier rank is the neron traversal; the
    # same-position tie-break is the A12 triple. `dedup = null` (no unified default; per-channel declared).
    test-collections-instance-order = {
      expr = {
        tiers = collInst.order.tiers;
        withinTier = collInst.order.withinTier;
        tieBreak = collInst.order.tieBreak;
        dedup = collInst.dedup;
      };
      expected = {
        tiers = [ "neron" ];
        withinTier = "traversal:neron";
        tieBreak = "a12";
        dedup = null;
      };
    };
    # the nominal engine reference: gen-pipe's run (the B5 pinned-sequence ordered fold).
    test-collections-instance-engine = {
      expr = collInst.engine;
      expected = "gen-pipe run (B5 pinned-sequence ordered fold)";
    };
    # the combine folds two contribution lists by association (extensional shape check — that it BEHAVES
    # like the channel append; the reference-ness itself lives in source, `combine = probeChannel.combine`).
    test-collections-instance-combine-is-channel-append = {
      expr =
        collInst.combine [ "x" ] [ "y" ] == [
          "x"
          "y"
        ];
      expected = true;
    };

    # ── THE ORDER ORACLE: the LIVE received-collections order matches the declared neron + A12 order ──
    # two same-position producers land in the plain channel in A12 producer-identity order (beta's aspect
    # id_hash sorts before alpha's) — the neron traversal + tie-break the instance declares. The traversal
    # LEG itself (self → imports → parent) has its own pre-existing oracle in b5-channel-order.nix; this
    # pins the A12 same-position tie-break the instance's `order` declares.
    test-collections-oracle-received-order = {
      expr = producersOf rcFwd "peers";
      expected = [
        "beta"
        "alpha"
      ];
    };
    # THE COMBINE VALUE-AGREEMENT: folding the live contributions' values through the INSTANCE combine from
    # its empty reproduces the live channel value — the declared algebra computes what gen-pipe computes.
    test-collections-oracle-combine-value-agreement = {
      expr = peersFoldedViaInstance == peersLiveValue;
      expected = true;
    };

    # ── A12 GOLDEN (risk register #5): the identity term is the aspect id_hash, declaration-order-free ──
    # permuting the include (aspect DECLARATION) order does NOT reorder the same-position multi-producer
    # tie — the A12 order keys on the aspect id_hash (declaration-order-independent), never include order.
    test-golden-a12-identity-is-id-hash = {
      expr = producersOf rcFwd "peers" == producersOf rcRev "peers";
      expected = true;
    };
    # the tie-break TRIPLE shape (rank < identity < emissionIndex), pinned against scope-adapter.nix:
    # rank dominates (policy after aspect), then identity, then a producer's own emission index.
    test-golden-a12-tiebreak-triple-shape = {
      expr = a12Sorted;
      expected = [
        "x0" # rank 0, id-x, emissionIndex 0 — lowest on every key
        "x1" # rank 0, id-x, emissionIndex 1 — emissionIndex breaks the id-x tie
        "y0" # rank 0, id-y — identity beats emissionIndex
        "p0" # rank 1 — rank beats everything, sorts last
      ];
    };

    # ── KEEP-FIRST GOLDEN (risk register #2): per-channel declared dedup keeps the FIRST occurrence ──
    # a channel that DECLARES `dedup = { keep = "first"; }` collapses the two same-position producers to
    # ONE, keeping the first per the A12 order (beta). Default channels never exercise dedup (the trap);
    # keep-direction is per-channel-declared — there is NO unified default (the plain channel keeps both).
    test-golden-collections-keep-first = {
      expr = {
        dedupedCount = builtins.length rcFwd.deduped.contributions;
        dedupedKept = producersOf rcFwd "deduped";
        plainCount = builtins.length rcFwd.peers.contributions;
      };
      expected = {
        dedupedCount = 1;
        dedupedKept = [ "beta" ];
        plainCount = 2;
      };
    };

    # ── reach-closure DECLARATION pins ──
    # the reach closure is set-semantics (idempotent under re-reach), so join-semilattice — the fixpoint
    # law: idempotence is what makes the reachable-set converge.
    test-reach-instance-laws = {
      expr = reachInst.laws;
      expected = "join-semilattice";
    };
    # the declared order: the structural subtree first (verbatim), then the reach-edge closure; the within-
    # tier rank is the subtree DFS; no producer ties. dedup gates the reach-EDGE tier ONLY (keep first).
    test-reach-instance-order-and-dedup = {
      expr = {
        tiers = reachInst.order.tiers;
        withinTier = reachInst.order.withinTier;
        tieBreak = reachInst.order.tieBreak;
        dedup = reachInst.dedup;
      };
      expected = {
        tiers = [
          "structural"
          "reach-edge"
        ];
        withinTier = "traversal:subtree-dfs";
        tieBreak = null;
        dedup = {
          key = "aspect-ident";
          keep = "first";
          appliesTo = [ "reach-edge" ];
        };
      };
    };
    # the nominal engine reference: the in-attribute ordered fold that lives in resolved-aspects.
    test-reach-instance-engine = {
      expr = reachInst.engine;
      expected = "reach in-attribute ordered fold (resolved-aspects)";
    };

    # ── THE ORDER ORACLE: the LIVE reach attribute's order matches the declared tiers ──
    # structural component VERBATIM first (src own, then the descendant cell), then the reach-edge closure
    # (dedup-gated: `ext`'s `shared` is already seen structurally, so only `ext-only` is added).
    test-reach-oracle-order = {
      expr = reachKeys;
      expected = [
        "src-own" # structural: src's own aspect
        "shared" # structural: the descendant cell's aspect
        "ext-only" # reach-edge: the fresh edge-target aspect (shared was deduped — already seen)
      ];
    };
    # THE COMBINE VALUE-AGREEMENT (the standing pin, here against a RESTATED combine — the proof the
    # restatement matches production): folding the instance combine from the structural seed over the edge
    # contribution reproduces the live reach list (structural verbatim, edge first-occurrence deduped).
    test-reach-oracle-combine-value-agreement = {
      expr = map (n: n.key) reachFoldedViaInstance == reachKeys;
      expected = true;
    };

    # ── THREE-CELLS GOLDEN (risk register #1): the u24 structural-multiplicity exemption ──
    # three DISTINCT cell scopes each carrying the SAME-key `acct` aspect ALL survive via the structural
    # component (distinct ctx-eval results — the three cells' one parametric aspect resolve to three nodes,
    # NOT one). dedup NEVER applies to the structural subtree; a bare-key collapse here would be the u24
    # content-loss the spec warns of (the same law reach-graph.nix per-provider-multiplicity witnesses).
    test-golden-reach-structural-multiplicity = {
      expr = {
        count = builtins.length (builtins.filter (k: k == "acct") threeCellsKeys);
        keys = threeCellsKeys;
      };
      expected = {
        count = 3;
        keys = [
          "acct"
          "acct"
          "acct"
        ];
      };
    };
  };
}
