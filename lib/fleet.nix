# Fleet graph — the registries become gen-product factors, restricted by membership to
# the sparse sub-product of cells that actually exist (Law A5). Membership tuples come
# from `member` declarations (Task 3) and functional dim assignments; Task 1 feeds them as
# fixture data through `den.membership`. Every algorithm here is a gen-product call;
# membership grouping is `gen-prelude.groupBy` (A1 wiring, not machinery).
{
  prelude,
  product,
  errors,
}:
let
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

  # dims = the ordered list of dimension kinds (declared by den.linearization; see Task 6).
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
      # enumeration. `via.membershipDerived` is the caller's classifier verdict (Task 3);
      # Task 1 raises the abort.
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
          cid = "${leafDim}:${leafEntry.name}@${hostNodeId}";
        in
        {
          name = cid;
          value = {
            id = cid;
            type = leafDim;
            parent = hostNodeId;
            decls = {
              ${parentDim} = hostEntry;
              ${leafDim} = leafEntry;
              __entry = leafEntry;
              # Full product coordinates of this cell (all dims → entries), cached for attribute 13's
              # `gen-product.containmentChain` — the settings chain needs every coordinate. `c` is the
              # cell within the host-sliced view, so it carries only the FREE dims (host was fixed by
              # the slice and dropped); re-add the host coordinate for the full product cell. Reserved
              # `__` key: excluded from context/coordDims, so it never leaks into policy ctx or channels.
              __coords = c // {
                ${parentDim} = hostEntry;
              };
              # Containment ancestors (§B4a visibility): the flat root scope id of every non-leaf
              # coordinate of this cell (e.g. env:prod, host:axon). resolved-aspects reads these
              # ancestors' resolved sets top-down — env is a coordinate root, not a P-parent, so
              # aspect radiation from env reaches every cell it contains without a P-tree nesting.
              # Reserved `__` key: excluded from context/coordDims.
              __containment = map (d: "${d}:${c.${d}.name}") (
                builtins.filter (d: d != leafDim) (builtins.attrNames c)
              );
            };
          };
        }
      ) cells
    );
in
{
  inherit factorOf mkFleet cellChildrenFor;
  # The slice-order chain over the fleet product (§2.7) — re-exported so the settings resolution
  # (attribute 13) and output assembly read one den-hoag surface. The algorithm is gen-product's
  # (Law A1); den-hoag only names it.
  inherit (product) containmentChain;
}
