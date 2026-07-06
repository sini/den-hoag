# Task 1 — entity registries + fleet restricted product (Laws A5, partial A6).
# Task 2 completes A6 coherence (P-chain == containmentChain tree-restriction) now that
# buildRoots + the structural stratum exist, and adds a scope-adapter (Law E6) sanity check.
{ denHoag, nixpkgsLib, ... }:
let
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
  };
}
