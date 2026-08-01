# Entity registries + fleet restricted product (Laws A5, partial A6).
# A6 coherence (P-chain == containmentChain tree-restriction) completes now that
# buildRoots + the structural stratum exist, and adds a scope-adapter (Law E6) sanity check.
{ denHoag, nixpkgsLib, ... }:
let
  aborts = e: !(builtins.tryEval e).success;
  fx = import ./_fixtures/fleet.nix;
  sel = denHoag.sel;
  inherit (denHoag.internal) parseParent scopeAdapter;
  product = denHoag.internal.product;

  den = (denHoag.mkDen fx.base).den;
  denDup = (denHoag.mkDen fx.dup).den;
  denBad = (denHoag.mkDen fx.bad).den;

  # (a) sel.kind consumes den.schema.<kind> and matches every instance of the kind.
  userReg = den.registries.user;
  userCtx = sel.adapters.registry.mkContext {
    nodes = builtins.attrNames userReg;
    data = id: userReg.${id};
    parent = _: null;
    kind = den.schema.user;
  };
  userMatches = map (id: sel.matches (sel.kind den.schema.user) id userCtx) (
    builtins.attrNames userReg
  );

  # (b)/(c) cells reflect membership; render each cell's coords to instance names.
  cellNames = map (c: builtins.mapAttrs (_: e: e.name) c) den.cells;
  aliceCells = builtins.filter (c: (c.user or null) == "alice") cellNames;
  bobCells = builtins.filter (c: (c.user or null) == "bob") cellNames;

  # ── A6 coherence — the scope tree and the product are two views of one containment
  #    structure. For each cell, the buildRoots P-chain (root→leaf fixed-coordinate sets)
  #    must equal the tree-kind restriction of gen-product's containmentChain: the chain
  #    entries whose fixed dims are a nested prefix of the cell's scope-kind order.
  eval = den.structural.eval;
  sortStrs = builtins.sort (a: b: a < b);
  coordDims =
    id:
    sortStrs (
      builtins.filter (k: !(nixpkgsLib.hasPrefix "__" k)) (builtins.attrNames (eval.node id).decls)
    );

  # scope-kind order (root→leaf) derived from the schema topology, independent of the
  # built tree: a cell's parent kind, then the leaf (cell) kind.
  meta = den.meta;
  allKinds = builtins.attrNames meta;
  parentKinds = nixpkgsLib.unique (
    builtins.filter (p: p != null) (map (k: meta.${k}.parent) allKinds)
  );
  leafKind = builtins.head (
    builtins.filter (k: !(builtins.elem k parentKinds) && meta.${k}.parent != null) allKinds
  );
  cellParentKind = meta.${leafKind}.parent;
  treeOrder = [
    cellParentKind
    leafKind
  ];
  # non-empty prefixes of treeOrder, each as a sorted dim-name list.
  treePrefixSets = builtins.genList (i: sortStrs (nixpkgsLib.take (i + 1) treeOrder)) (
    builtins.length treeOrder
  );

  cellNodeId = c: "${leafKind}:${c.${leafKind}.name}@${cellParentKind}:${c.${cellParentKind}.name}";
  pchainRootFirst =
    id:
    let
      walk =
        nid:
        [ nid ]
        ++ (
          let
            p = parseParent nid;
          in
          if p == null then [ ] else walk p
        );
    in
    nixpkgsLib.reverseList (walk id);

  lin = den.linearization;
  chainFixed = c: map coordDims (pchainRootFirst (cellNodeId c));
  ccRestricted =
    c:
    builtins.filter (s: builtins.elem s treePrefixSets) (
      map (r: sortStrs (builtins.attrNames r.fixed)) (product.containmentChain den.fleet c lin)
    );
  a6PerCell = map (c: chainFixed c == ccRestricted c) den.cells;

  # ── Law E6 — the scope adapter reads decls.__entry + node type; sel.kind matches a cell
  #    node by its leaf kind and rejects a non-matching kind.
  aliceCellId = cellNodeId (builtins.head den.cells);

  # ── the null-aware `entryFor` — an entry-less node aborts NAMED where it answered a silent `false` ──
  # `sel.kind` is not a kind test on a node; it is a kind test on a node's REGISTRY ENTRY. The adapter
  # composes `__identity` from `entryFor id`, and gen-select's default reads `decls.__entry or null` and
  # answers a plain `false` when that is null — correct for a library whose contexts may legitimately mix
  # entity-backed and non-entity-backed nodes, wrong for den-hoag, which declares every node entry-backed.
  # The scope adapter therefore supplies a null-aware `entryFor`, narrowing gen-select's domain to
  # den-hoag's own stated invariant through the seam gen-select provides for it.
  #
  # THE VIOLATION IS BUILT THROUGH THE SURFACE THAT REACHES IT, not by hand. `den.systemViews` is
  # `lazyAttrsOf raw` — any key, any value — and the scopeRoots fold merges the system-selected view
  # decls-winning over the minted `decls`, so a view carrying `__entry = null` overwrites the entry
  # `buildRoots` minted on every system-bearing root. What the node then carries is the key PRESENT and
  # its VALUE null, and that distinction is the whole reason the check is written as a test on the value:
  # `e.k or v` fires on a MISSING attribute and never on a present one holding null, so an `or`-written
  # guard is armed only against a shape den-hoag's two minters never produce and walks straight past the
  # one a declared surface does.
  #
  # TWO HOSTS ON TWO SYSTEMS, so the control lives in the SAME fleet as the violation. A system view is
  # selected per system, so nulling one system's `__entry` reaches `host:axon` and leaves `host:blade`
  # entried — which means the admitting control is the same den, the same adapter and the same run as the
  # aborting arm, rather than a second den that might differ for some other reason. `user:alice` sits on
  # blade: it makes (host, user) the cell family, which is what keeps both hosts ROOT nodes (the fold that
  # carries the view runs over roots), and it leaves axon with no cell of its own.
  nvSysA = "x86_64-linux";
  nvSysB = "aarch64-linux";
  nvSchema.config.den.schema = {
    env.parent = null;
    host = {
      parent = "env";
      # the host's own `system` coordinate as a DECLARED option, so it rides on `__entry.system` — the
      # coordinate the scopeRoots fold selects the per-system view by.
      options.system = denHoag.schema.mkOption {
        type = denHoag.schema.types.str;
        default = nvSysA;
      };
    };
    user.parent = "host";
  };
  nvInstances.config.den = {
    env.prod = { };
    host.axon.system = nvSysA;
    host.blade.system = nvSysB;
    user.alice = { };
  };
  nvMembership =
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
            env = config.den.env.prod;
            host = config.den.host.blade;
          };
        }
        {
          coords = {
            host = config.den.host.blade;
            user = config.den.user.alice;
          };
        }
      ];
    };
  nvBase = [
    nvSchema
    nvInstances
    nvMembership
  ];
  nvNulling = {
    config.den.systemViews.${nvSysA}.__entry = null;
  };
  denEntried = (denHoag.mkDen nvBase).den;
  denNulled = (denHoag.mkDen (nvBase ++ [ nvNulling ])).den;

  nvNulledId = "host:axon";
  nvEntriedId = "host:blade";
  nvDeclsAt = d: id: (d.structural.eval.node id).decls;
  nvKindAt = d: id: scopeAdapter.matchId d.structural (sel.kind d.schema.host) id;
  nvAttrsAt = d: id: scopeAdapter.matchId d.structural (sel.attrs { type = "host"; }) id;
in
{
  flake.tests.entity-fleet = {
    # (a) — AC1: den.schema.<kind> is a gen-schema kind value usable by sel.kind.
    test-kind-value-shape = {
      expr = (den.schema.user ? kind) && (den.schema.user ? options);
      expected = true;
    };
    test-sel-kind-matches-all-instances = {
      expr = userMatches;
      expected = [
        true
        true
      ];
    };

    # (b) — AC2: a user with a membership tuple yields a cell; one without yields none.
    test-single-cell = {
      expr = builtins.length den.cells;
      expected = 1;
    };
    test-member-yields-cell = {
      expr = builtins.length aliceCells;
      expected = 1;
    };
    test-nonmember-no-cell = {
      expr = builtins.length bobCells;
      expected = 0;
    };
    test-cell-coords = {
      expr = builtins.head aliceCells;
      expected = {
        env = "prod";
        host = "axon";
        user = "alice";
      };
    };

    # (c) — AC2: duplicate membership tuples are idempotent (relation, not collection).
    test-duplicate-tuple-idempotent = {
      expr = builtins.length denDup.cells;
      expected = 1;
    };

    # (d) — AC3: `member` at a membership-derived scope aborts at definition time.
    test-member-at-cell-aborts = {
      expr = (builtins.tryEval (builtins.length denBad.cells)).success;
      expected = false;
    };

    # (e) — A6: per-cell P-chain equals the tree-kind restriction of containmentChain.
    test-a6-coherence = {
      expr = builtins.all (x: x) a6PerCell;
      expected = true;
    };
    test-a6-covers-every-cell = {
      expr = builtins.length a6PerCell;
      expected = builtins.length den.cells;
    };
    # concrete shape of the coherence for the fixture cell (host-rooted, env is coordinate-only).
    test-a6-fixture-chain = {
      expr = chainFixed (builtins.head den.cells);
      expected = [
        [ "host" ]
        [
          "host"
          "user"
        ]
      ];
    };

    # (f) — Law E6: scope adapter + sel.kind over the built cell node.
    test-scope-adapter-kind-match = {
      expr = scopeAdapter.matchId den.structural (sel.kind den.schema.user) aliceCellId;
      expected = true;
    };
    test-scope-adapter-kind-reject = {
      expr = scopeAdapter.matchId den.structural (sel.kind den.schema.host) aliceCellId;
      expected = false;
    };

    # (g) — the null-aware `entryFor`. THE FIXTURE'S OWN CHECK FIRST: without it the arms below are
    # vacuous, because a fold that failed to fire would leave a perfectly entried node and every
    # assertion would pass for the wrong reason. This pins the exact shape the ruling turns on — the key
    # PRESENT, its value null — against the same node in the un-nulled fleet, where it is a real entry.
    test-null-entry-fixture-is-present-and-null = {
      expr = {
        keyPresent = (nvDeclsAt denNulled nvNulledId) ? __entry;
        nulledValue = (nvDeclsAt denNulled nvNulledId).__entry;
        # the view is selected PER SYSTEM, so the other host in the same fleet keeps its entry — which is
        # what makes the same-den control below a control rather than a coincidence.
        siblingIsAnEntry = builtins.isAttrs (nvDeclsAt denNulled nvEntriedId).__entry;
        # and without the view the same node is entried, so the null is the view's doing.
        unNulledIsAnEntry = builtins.isAttrs (nvDeclsAt denEntried nvNulledId).__entry;
      };
      expected = {
        keyPresent = true;
        nulledValue = null;
        siblingIsAnEntry = true;
        unNulledIsAnEntry = true;
      };
    };
    # THE CONSEQUENCE: a kind selector at the nulled node ABORTS where it answered a silent `false`. The
    # divergence class becomes {correct answer, named abort} and never {silently different}.
    test-null-entry-kind-selector-aborts = {
      expr = aborts (nvKindAt denNulled nvNulledId);
      expected = true;
    };
    # CONTROL, SAME DEN AND SAME RUN: the entried host answers the same selector normally. So the abort
    # above is the nulled entry's doing and not the adapter, the fixture or the selector being broken.
    test-null-entry-control-sibling-admits = {
      expr = nvKindAt denNulled nvEntriedId;
      expected = true;
    };
    # CONTROL on the same NODE across the two dens: without the nulling view, axon admits. Together with
    # the sibling control this pins the abort to one node and one cause.
    test-null-entry-control-same-node-un-nulled-admits = {
      expr = nvKindAt denEntried nvNulledId;
      expected = true;
    };
    # CONTROL on the other axis: `sel.attrs { type = …; }` reads `project`'s output and never forces
    # `__identity`, so it neither gains nor loses an abort — it answers `true` at the SAME nulled node
    # where `sel.kind` aborts. Two things at once: the override is confined to the identity-reading arms
    # (so the compat-produced corpus, which is all `sel.attrs` / `sel.star` / `sel.any [ ]`, is untouched),
    # and the nulled fleet is otherwise evaluable — which is what makes the abort above attributable to
    # the selector rather than to a dead fleet.
    test-null-entry-attrs-selector-unaffected = {
      expr = nvAttrsAt denNulled nvNulledId;
      expected = true;
    };
  };
}
