# The coordinate projections over the `contains` edge pool (§B4a topology) — THE one place a node's
# position is derived, and the successor to the `__coords` payload and the `coordDims` negative
# enumeration it selected between.
#
# THE THEORY. A graph fact belongs on an edge; a position is a PROJECTION of that edge set onto a
# DECLARED INDEX. Containment is one Model-Q pool (`contains`, pure adjacency); everything below is a
# projection of it, and every key of every map it produces comes from an index that was declared —
# `settingsDims` for a node's own slice, `dimKinds` for the product coordinate. No `decls` key becomes a
# key of any map here, which is why a user-named binding cannot pollute a coordinate whatever it is
# called: the property is about the KEY DOMAIN, not about avoiding `decls`. Values come from exactly one
# `decls` attribute, `__entry`, at the node the key names.
#
# THREE PROJECTIONS OVER ONE CLOSURE, and the split is the whole correction:
#
#   (1) `coordOf n`        = { type n -> __entry n }        the NODE'S OWN slice. A singleton, indexed on
#                                                           `settingsDims`, TOTAL over every node.
#   (2) `cellCoordsOf n`   = per-axis over `dimKinds`       the PRODUCT coordinate. Read on the CELL arm.
#   (3) `ancestorSlicesOf` = the closure minus baseChain     the CASCADE slices, each of them a (1).
#
# Two earlier constructions are refuted BY these three and the refutations are the reason for the shape.
# Letting the graph supply the keys (`{ type a -> __entry a for a in closure }`) answers `{env, host,
# user}` against `dimKinds = [host, user]` on the corpus topology — a containment ancestor is NOT a
# product dimension. Indexing a node's OWN coordinate on `dimKinds` instead gives every node whose type
# is not an axis an EMPTY coordinate, and `coordsEq` compares key sets first, so a non-dim root carrying
# a live settings layer (`cluster:k3s`, `env:prod`) silently drops to the schema default. The two are one
# error at two ends — one let the graph choose the keys, the other let the axis set choose which nodes
# get a coordinate at all. A node's own coordinate is NEITHER an ancestor's nor a product axis's, so it
# is its own projection, and the partition in (3) applies to the CLOSURE, never to the node.
#
# ABSENCE IS A DECISION, TWICE. (1) is total — every node has a type and an `__entry`, so there is no
# `or (coordDims node)` fallback and no `or [ ]`; a node reaching it without either is a NAMED abort, not
# a sentinel. And in (2) an unmet axis is the STATED value `MISSING`, not an absent key: an omitted key
# is what makes a coordinate compare equal to a coordinate that means something else.
{
  prelude,
  graph,
  errors,
}:
{
  # The Model-Q `contains` triples — `{ id; kind; from; to; stratum }`, `from`/`to` MINTED node ids.
  # Required: an empty pool is a legitimate fleet (nothing contains anything) and is not distinguishable
  # from a forgotten argument, which is the absence-is-a-decision defect this file exists to remove.
  containsEdges,
  # The total axis domain — `unique (dimKinds ++ rootScopeKinds)`, the same set `den.settings.layers`
  # validates an `at` against. A coordinate keyed outside it could name no layer, so `coordOf` aborts.
  settingsDims,
  # The product axes. (2)'s index, and ONLY that: `dimKinds` selects which ARM a node's coordinate is
  # read on; it never decides whether a coordinate EXISTS. That demotion is what keeps the answer set
  # independent of the staged pre-pass `dimKinds` is derived through.
  dimKinds,
  # The cell/root constructor tag (`build-roots.nix isCellNode`) — the arm discriminator. A cardinality
  # test over the coordinate keys is what this replaces: a polluted root whose key count happens to equal
  # `|dimKinds|` passes a count and is NOT a cell, and the tag is right on that same input.
  isCellNode,
}:
let
  # ── the inbound adjacency, built ONCE ─────────────────────────────────────────────────────────────
  # `from -> [ to ]` for the pool, then gen-graph's `transpose` (Mokhov 2017 §5.2 — §4.3 is "Undirected
  # Graphs", which ERASES direction; §5.2's law flips the arguments of `connect` and leaves `overlay`
  # alone) reverses it to `to -> [ from ]`, the ancestor accessor. The same route `inverseRelationEdges`
  # takes for a relation kind, rather than a hand-rolled from/to swap.
  #
  # BUILT HERE, IN THE MODULE'S `let`, NOT INSIDE A PER-NODE COMPUTE. The projections run at EVERY node,
  # so an adjacency rebuilt per call would add a per-node O(E) term to a path that is already cubic in
  # cells. This binding is forced at most once per fleet and every projection shares it.
  forwardAdjacency = builtins.mapAttrs (_: es: map (e: e.to) es) (
    prelude.groupBy (e: e.from) containsEdges
  );
  endpoints = prelude.unique (
    prelude.concatMap (e: [
      e.from
      e.to
    ]) containsEdges
  );
  inbound = graph.transpose {
    edges = nid: forwardAdjacency.${nid} or [ ];
    nodes = endpoints;
  };
  # A node id -> the ids of the nodes that contain it. TOTAL: `transpose` answers `[ ]` off its node
  # domain, so a node that no edge names is not a missing key, it is a node with no containment ancestor.
  containEdges = nid: inbound.edges nid;

  # Dep-free list reversal (gen-prelude keeps its own inside `toposort`): turns gen-graph's nearest-first
  # pre-order into the least-specific-first emission the settings fold consumes.
  reverseList =
    xs:
    let
      l = builtins.length xs;
    in
    builtins.genList (n: builtins.elemAt xs (l - n - 1)) l;

  # ── the closure: a node's containment ancestors, the node EXCLUDED ────────────────────────────────
  # `expandPreorder` visits in first-occurrence PRE-order (nearest-first over `containEdges`); reversing
  # yields the least-specific-first order the cascade fold consumes (default < env < host < user, ORDER
  # load-bearing). `cycles` over the SAME accessor is the loud back-edge guard — a cyclic containment
  # aborts NAMED rather than hanging.
  #
  # ★ THE VISITED SET IS WHAT MAKES A DIAMOND ONE SLICE. `foldPreorder` threads ONE `visited` attrset
  # through the fold across ALL roots, so first-occurrence is GLOBAL rather than per-root, and a node
  # reached by two paths from a shared grandparent is emitted once. That is dedup requirement 2; the
  # first is edge identity (`contains/${from}->${to}`), which collapses one relation declared through two
  # spellings into ONE edge in the pool rather than in a pass someone runs.
  #
  # `emit` CANNOT PRUNE — `expandPreorder`'s fold body appends exactly one entry per visited frame — so
  # (3)'s partition is applied as an ORDER-PRESERVING FILTER after the reversal, never inside `emit`. And
  # the walk must not stop at dim-typed ancestors: a non-dim ancestor reachable only THROUGH a dim one
  # still owes its slice, so the closure is walked in full and partitioned at the end.
  ancestorIdsOf =
    nid:
    let
      walk = graph.expandPreorder {
        roots = containEdges nid;
        key = anc: anc;
        edges = containEdges;
        emit = anc: _payload: anc;
      };
      cyclic = graph.cycles {
        edges = containEdges;
        nodes = builtins.attrNames walk.seen;
      };
    in
    if cyclic == [ ] then reverseList walk.nodes else errors.containmentCycle (builtins.head cyclic);

  # Memoized over the pool's endpoints — the closure is a property of the POOL, not of the reader, and
  # both the settings cascade and the aspect-radiation ancestor read ask for it at the same nodes. A node
  # outside the pool has no containment ancestor by construction (`containEdges` is `[ ]` there), so the
  # fallback is a derivation, not a default.
  closureByNode = prelude.genAttrs endpoints ancestorIdsOf;
  containAncestorIds = nid: closureByNode.${nid} or [ ];

  # ── MISSING: a STATED unmet axis ──────────────────────────────────────────────────────────────────
  # (2) is total over `dimKinds`, so an axis the closure does not meet carries a value rather than losing
  # its key. It is a CODOMAIN sentinel, never a payload — it is not written to any node's `decls`, which
  # is what distinguishes it from the `__`-keyed graph facts this migration deletes.
  missing = dm: { __missing = dm; };

  # The comparable identity of one axis value. `id_hash or null` alone would make a MISSING compare EQUAL
  # to any value that merely LACKS an `id_hash` — a malformed entry and an unmet axis would be the same
  # slice. Tagging the sentinel by its own dim removes that by construction, so nothing here rests on a
  # claim that MISSING is unreachable at a comparison site.
  coordValueId = v: if v ? __missing then "«missing»:${v.__missing}" else (v.id_hash or null);

  # Two coordinate sets denote the same slice iff same dims and same entry identities.
  coordsEq =
    a: b:
    builtins.attrNames a == builtins.attrNames b
    && builtins.all (d: coordValueId a.${d} == coordValueId b.${d}) (builtins.attrNames a);

  # ── (1) the node's own slice ──────────────────────────────────────────────────────────────────────
  # A singleton, total over every node, whatever its type. The `settingsDims` guard is UNREACHABLE at
  # HEAD by an identity — `settingsDims = dimKinds ∪ (allKinds \ cellKinds)`, both sides ⊆ `allKinds`
  # with every kind in one of them, so it equals `allKinds` as a set for every fleet — and that is
  # precisely why it is written: it costs nothing now and it is the one thing that fires if that
  # relationship stops holding, turning a coordinate no layer can name into an abort instead of a silent
  # resolution to schema defaults.
  coordOf =
    node: nid:
    let
      n = node nid;
      t = n.type;
    in
    if !(builtins.elem t settingsDims) then
      errors.unknownAxis nid t settingsDims
    else
      { ${t} = n.decls.__entry or (errors.missingEntry nid); };

  # ── (2) the product coordinate ────────────────────────────────────────────────────────────────────
  # Per axis, the UNIQUE type-`d` member of `{ n } ∪ closure n`. A second member is a NAMED abort rather
  # than an attrset literal's silent last-win — and that abort is also what the cascade's cell-arm
  # reduction rests on, so the guard the reduction needs already exists here rather than being a new
  # obligation stated beside it.
  cellCoordsOf =
    node: nid:
    let
      members = [ nid ] ++ containAncestorIds nid;
    in
    builtins.listToAttrs (
      map (d: {
        name = d;
        value =
          let
            ms = builtins.filter (a: (node a).type == d) members;
            hit = builtins.head ms;
          in
          if ms == [ ] then
            missing d
          else if builtins.length ms > 1 then
            errors.coordCollision nid d ms
          else
            (node hit).decls.__entry or (errors.missingEntry hit);
      }) dimKinds
    );

  # The node's own coordinate ON WHICHEVER ARM IT IS ON — the value a producing scope is labelled with
  # and the value the terminal policy slot records. Not a fourth projection: it is the last slice the
  # cascade's `baseChain` already ends with (`containmentChain` is powerset-complete, so `D` itself is in
  # the chain) on the cell arm, and (1) on the root arm.
  nodeCoords = node: nid: if isCellNode (node nid) then cellCoordsOf node nid else coordOf node nid;

  # ── (3) the cascade slices ────────────────────────────────────────────────────────────────────────
  # The closure partitioned against what `baseChain` already carries, in the traversal's emission order.
  #
  # ★ THE PREDICATE IS A SLICE TEST, NOT A TYPE TEST, and the difference is a wrong answer on the ROOT
  # arm. `containmentChain` runs only on the cell arm; on the root arm `baseChain` is `[ { }, coordOf n ]`
  # and supplies NO ancestor slice at all, so filtering by `type a ∈ dimKinds` there would silently drop
  # the slice of a dim-typed ancestor of a root — an expressible fleet (a kind can be both a product dim
  # and a root kind) whose settings would fall to the schema default with nothing to distinguish that
  # from "no layer applies". The type test is the CELL-ARM REDUCTION of this rule, sound there by
  # `containmentChain`'s powerset-completeness (every subset of `D` is in the chain, for EVERY
  # linearization — so `den.linearization.dims` chooses the chain's ORDER, never its MEMBERSHIP) plus
  # (2)'s uniqueness abort. Stating the rule per-arm is what stops the reduction being applied where it
  # does not hold.
  ancestorSlicesOf =
    node: nid: baseChain:
    let
      slices = map (coordOf node) (containAncestorIds nid);
    in
    builtins.filter (s: !(builtins.any (b: coordsEq b s) baseChain)) slices;
in
{
  inherit
    coordOf
    cellCoordsOf
    nodeCoords
    ancestorSlicesOf
    containAncestorIds
    coordsEq
    ;
}
