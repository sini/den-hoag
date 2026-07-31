# Fleet graph — the registries become gen-product factors, restricted by membership to
# the sparse sub-product of cells that actually exist (Law A5). Membership tuples come
# from `member` declarations and functional dim assignments, fed as fixture data
# through `den.membership`. Every algorithm here is a gen-product call;
# membership grouping is `gen-prelude.groupBy` (A1 wiring, not machinery).
{
  prelude,
  product,
  errors,
}:
let
  # THE attached-root id rule, taken from the module that owns it rather than re-derived: a pair must
  # name the node `buildRoots` actually minted, and sharing the rule is what makes that true by
  # construction instead of by two spellings happening to agree.
  inherit (import ./build-roots.nix { inherit prelude; }) mintedRootId mintedIdsOf;

  # THE cell id rule, and the only definition of it. `cellChildrenFor` mints cells with it and the
  # containment producer spells child ids with it, so the two agree because they share the rule rather
  # than because two string interpolations happen to match. The root side already had this discipline
  # (`mintedRootId`, above, taken from the module that owns it); the child side did not, and that
  # asymmetry INSIDE THIS FILE is what produced dangling child ids for root-kind children.
  mintedCellId =
    childDim: childName: parentNodeId:
    "${childDim}:${childName}@${parentNodeId}";

  # THE ONE CHILD-ID RULE, dispatched on which constructor will mint the child. A containment child is
  # minted by `cellChildrenFor` when its kind is a cell kind and by `buildRoots` when it is a root kind,
  # and those two mint DIFFERENT ids: the cell rule always suffixes `@<parent>`, while `mintedRootId`
  # keeps the BARE id under <= 1 attachment. Spelling every child with the cell rule — as the previous
  # producer did, unconditionally — therefore names no node whenever the child is a root kind with one
  # attachment. Dispatching here, on the same functions the minters use, is what makes "the pair names a
  # real node" true by construction rather than an invariant someone maintains.
  containmentChildId =
    {
      cellKinds,
      attachments,
    }:
    childDim: childName: parentNodeId:
    let
      bareId = "${childDim}:${childName}";
    in
    if builtins.elem childDim cellKinds then
      mintedCellId childDim childName parentNodeId
    else
      mintedRootId bareId (attachments.${bareId} or [ ]) parentNodeId;

  # A registry -> gen-product factor. `key` maps a public coordinate entry to the factor
  # node id (its id_hash); `entryOf` inverts it. Per the gen-product factor contract the
  # node ids ARE the `key` outputs, so nodes/nodeData/entryOf are keyed by id_hash — an
  # id_hash -> entry index. (The registry is name-keyed; keying the factor by name would
  # make `entryOf (key entry)` — which containmentChain / not-a-node detection round-trips
  # — miss, since `key` yields the hash, not the name.)
  factorOf =
    kindName: registry:
    let
      byHash = builtins.listToAttrs (
        map (e: {
          name = e.id_hash;
          value = e;
        }) (builtins.attrValues registry)
      );
    in
    {
      dim = kindName;
      graph = {
        nodes = builtins.attrNames byHash;
        edges = _: [ ];
        parent = _: null;
        nodeData = id: byHash.${id};
      };
      key = entry: entry.id_hash;
      entryOf = id: byHash.${id};
    };

  # dims = the ordered list of dimension kinds (declared by den.linearization).
  # membershipTuples = [ { coords = { <dim> = <entry>; }; via ? null; } ] from member declarations +
  #   functional assignments (idempotent: gen-product restrict dedups by cellId).
  mkFleet =
    {
      registries,
      dimKinds,
      membershipTuples,
    }:
    let
      # A5 discipline: `member` is accepted only at membership-independent nodes. A tuple
      # whose `via` marks a membership-derived emitting scope aborts, naming policy +
      # scope. Folded (not mapped) so the abort forces at fleet construction, not only on
      # enumeration. `via.membershipDerived` is the caller's classifier verdict; fleet
      # construction raises the abort.
      disciplineOk = prelude.foldl' (
        acc: t:
        let
          v = t.via or null;
        in
        if v != null && (v.membershipDerived or false) then errors.memberAtCell v.policy v.scope else acc
      ) true membershipTuples;

      factors = map (k: factorOf k registries.${k}) dimKinds;
      full = product.productN "cartesian" factors;
      # relations = one per distinct tuple-dim-set; pairs are partial coords.
      byDims = prelude.groupBy (t: builtins.toJSON (builtins.attrNames t.coords)) membershipTuples;
      relations = prelude.mapAttrsToList (_: ts: {
        dims = builtins.attrNames (builtins.head ts).coords;
        pairs = map (t: t.coords) ts;
      }) byDims;
    in
    builtins.seq disciplineOk (product.restrict full { inherit relations; });

  # Cell children of a host scope node (the `children` NTA's fleet arm, r2 attr 5). Slice
  # the fleet to this host (a gen-product call), then map each surviving cell to a leaf
  # scope node `"leaf:name@<hostNodeId>"` carrying both the host and leaf bindings (r2
  # decls = { host; user; }). A childless host (no cell in its slice) yields no children.
  # Enumeration is gen-product; the node assembly is A1 wiring.
  cellChildrenFor =
    {
      fleet,
      parentDim,
      hostEntry,
      hostNodeId,
      leafDim,
    }:
    let
      cells = product.cells (product.slice fleet { ${parentDim} = hostEntry; });
    in
    builtins.listToAttrs (
      map (
        c:
        let
          leafEntry = c.${leafDim};
          # the SHARED cell-id rule (above) — the containment producer spells child ids with the same
          # function, so a pair naming this cell and the cell itself cannot drift apart.
          cid = mintedCellId leafDim leafEntry.name hostNodeId;
        in
        {
          name = cid;
          value = {
            id = cid;
            type = leafDim;
            parent = hostNodeId;
            # ── NO GRAPH FACT RIDES HERE ──────────────────────────────────────────────────────────
            # This mint used to write two: `__coords` (the full product coordinate) and
            # `__containment` (the cell's other coordinate roots). Both were the SAME containment
            # relation the `contains` pool now carries as edges, cached at construction time into the
            # node they describe — and a cache beside a query is two derivations of one fact, selected
            # by whether the cache happens to be present. `resolved-settings` read exactly that:
            # `node.decls.__coords or (coordDims node)`. They are deleted in the commit that points
            # the reads at the pool, because a window in which both exist IS the defect.
            #
            # What is left is what a node genuinely owns: its DIM BINDINGS (policies destructure them,
            # `{ host, user, … }:`) and `__entry`, its own registry entry. `__entry` stays on the
            # corrected grounds of §6.4 — its kernel reads are attribute reads OFF the entry, not
            # traversals, so an edge buys no query; it is an IDENTITY projection rather than a topology
            # fact; and all three coordinate projections read it as the coordinate VALUE, so migrating
            # it would remove the one value source the query depends on. The bindings' accidental
            # second job as the coordinate SOURCE is what ends here.
            decls = {
              ${parentDim} = hostEntry;
              ${leafDim} = leafEntry;
              __entry = leafEntry;
            };
          };
        }
      ) cells
    );
  # ── the containment producer: the containment RELATION, minted into node ids ──────────────────────
  # `containmentRelation { membershipTuples; meta; attachments; cellKinds }` → one record per
  # (parent node, child) containment, carrying both the Model-Q triple and the fields the nest producer
  # reads. ONE producer, two views, so the `contains` edge pool and the nest pairs cannot disagree about
  # what contains what.
  #
  # TOTAL OVER CONTAINMENT, NOT OVER CELLS — this is the second of the two obligations, and it is why
  # the fold is over `membershipTuples` and `attachments` rather than over `product.cells`. A cell is a
  # SURVIVING point of the restricted product; a containment relation can be declared with no cell
  # beneath it at all, and folding over cells silently emitted nothing for it. Two spellings of one
  # relation reach us here:
  #   • a membership TUPLE naming both a child dim and its `meta.<child>.parent` dim — the static
  #     spelling, which is also the only one the cell fold ever saw;
  #   • an ATTACHMENT (`bareId -> [ parent node id ]`), which is what a `containTo`-marked member
  #     produces — the relation spelling, which yields NO cell of its own and so was invisible before.
  # Both are public surface at two declarations, and they described opposite halves of one relation.
  #
  # EDGE IDENTITY IS THE TRIPLE. `id = "contains/${from}->${to}"`, so one relation declared through both
  # spellings is ONE edge: the deduplication lives in the representation rather than in a pass someone
  # runs, which is what lets the settings walk drop its `prelude.unique` over a merged ancestor list.
  containmentRelation =
    {
      membershipTuples,
      meta,
      # Root attachments (bare root id -> [ parent node id ]). REQUIRED, not defaulted: `{ }` means
      # "nothing multiplies", and passing it while roots really ARE attached mints wrong ids on both
      # sides silently. The caller knows its attachments; a default here only lets it forget them.
      attachments,
      # The kinds minted as CELLS (`cellChildrenFor`) rather than as roots (`buildRoots`). Required for
      # the same reason: the child-id rule dispatches on it, and a defaulted `[ ]` would spell every
      # child with the root rule.
      cellKinds,
    }:
    let
      childIdOf = containmentChildId { inherit cellKinds attachments; };
      # the parent coordinate's NODE ids — a parent claimed by several sources is several nodes, and the
      # containment holds under each of them.
      parentNodeIdsOf = parentBareId: mintedIdsOf parentBareId (attachments.${parentBareId} or [ ]);
      mk =
        parentKind: parentName: childKind: childName:
        map (parentId: {
          inherit
            parentId
            parentKind
            childKind
            childName
            ;
          childId = childIdOf childKind childName parentId;
        }) (parentNodeIdsOf "${parentKind}:${parentName}");
      # (a) the TUPLE spelling: every tuple coordinate whose parent dim the same tuple also fixes.
      fromTuples = prelude.concatMap (
        t:
        let
          c = t.coords;
        in
        prelude.concatMap (
          childDim:
          let
            parentDim = meta.${childDim}.parent or null;
          in
          if parentDim != null && (c ? ${parentDim}) then
            mk parentDim c.${parentDim}.name childDim c.${childDim}.name
          else
            [ ]
        ) (builtins.attrNames c)
      ) membershipTuples;
      # (b) the ATTACHMENT spelling: a `containTo`-marked member attached this root to parent NODES
      # directly, so the parent side is already minted and only the child side needs the rule. These are
      # exactly the containments no cell witnesses.
      fromAttachments = prelude.concatMap (
        childBareId:
        let
          m = builtins.match "([^:]*):(.*)" childBareId;
          childKind = builtins.elemAt m 0;
          childName = builtins.elemAt m 1;
        in
        map (parentId: {
          inherit parentId childKind childName;
          parentKind = builtins.head (builtins.match "([^:]*):.*" parentId);
          childId = childIdOf childKind childName parentId;
        }) attachments.${childBareId}
      ) (builtins.attrNames attachments);
      all = fromTuples ++ fromAttachments;
      # first-occurrence dedup ON THE MINTED TRIPLE: the two spellings of one relation collapse here
      # rather than downstream, so `contains` is idempotent under re-declaration by construction.
      byEdgeId = prelude.groupBy (r: "contains/${r.parentId}->${r.childId}") all;
    in
    map (grp: builtins.head grp) (builtins.attrValues byEdgeId);

  # The Model-Q `contains` triples — pure adjacency, ONE registered kind, no per-dim label and no
  # `data`. `data.dim`/`data.entry` would duplicate a fact the endpoints already carry: a node's `type`
  # IS its dim and its `decls.__entry` IS its entry, and putting them on the edge is the precise defect
  # class this migration retires. `stratum = "structural"` matches the kind's registry row.
  containmentEdges =
    args:
    map (r: {
      id = "contains/${r.parentId}->${r.childId}";
      kind = "contains";
      from = r.parentId;
      to = r.childId;
      stratum = "structural";
    }) (containmentRelation args);

  # Containment (immediate parent → child) pairs, for the nest-edge producers (§4.2/§4.6) — a VIEW over
  # `containmentRelation` above, not a second traversal. It used to fold `product.cells` and spell child
  # ids itself, which is where both of its faults came from: a containment with no surviving cell emitted
  # no pair at all, and every child was spelled with the cell rule even when a root minter would mint it
  # bare. Deriving the view from the one producer removes both, and removes the possibility of the pair
  # set and the `contains` pool disagreeing. The child's content class is NOT derived here (den-side
  # `contentClass` stays null on `meta`); the nest producer supplies its own map.
  containmentPairs =
    args:
    map (r: {
      inherit (r)
        parentId
        parentKind
        childKind
        childName
        childId
        ;
    }) (containmentRelation args);
in
{
  inherit
    factorOf
    mkFleet
    mintedCellId
    cellChildrenFor
    containmentRelation
    containmentEdges
    containmentPairs
    ;
  # The slice-order chain over the fleet product (§2.7) — re-exported so the settings resolution
  # (attribute 13) and output assembly read one den-hoag surface. The algorithm is gen-product's
  # (Law A1); den-hoag only names it.
  inherit (product) containmentChain;
}
