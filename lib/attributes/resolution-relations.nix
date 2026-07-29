# Resolution-stratum relation accessors as gen-resolve equations (Productions-substrate §11 Phase 1). The
# shipped resolution facet delivered `relAt`/`derivedAt` as TOP-LEVEL per-mkDen closures built beside the final
# `structural.eval` — a second delivery-context OUTSIDE gen-resolve's schedule / warm-serve / classKey. This
# module folds that DELIVERY into the ONE equations map: `rel-accessor` and `derived-accessor` become
# resolution-stratum `resolve.attr` records, so `den.relAt` / `den.derivedAt` read ONE scheduled, warm-served
# eval (`structural.eval.get id …`). The accessor BODIES are unchanged substrate (`relations.mkRelAccessor` /
# `derived.mkDerived`); this file only wraps them. The 7 field guards, the `node` handle, the stratum-gate
# (`gatedRel`/`scopedEdges`), and the `deps` placeholder all stay inside `mkDerived` (GAP-1/GAP-3/GAP-4: not
# expressible as gen-resolve `reference` or foldable into the 2-way schedule yet).
#
# Both attrs are `resolution` stratum: `rel-accessor` reads no attribute (the producer is the static,
# registry-derived `relationEdges` pool — GAP-5, so the compute ignores `self`); `derived-accessor` reads
# `rel-accessor` at its OWN node (the `node.rel = relAt id` handle) — an INTRA-stratum positive read
# (Apt–Blair–Walker), which the two-way schedule permits (its assert only fires structural→resolution).
# Corpus-inert: empty `relationEdges`/`derivedTable` ⇒ empty records for every node ⇒ byte-identical to the
# pre-Phase-1 output (neither attr is read by the structural or output strata, so neither reaches the trace).
{
  resolve,
  relations,
  derived,
  query,
  strataScope,
}:
{
  relationEdges ? [ ],
  relationEdgeKinds ? { },
  strataOrder ? [ ],
  derivedTable ? { },
}:
let
  # THE RELATION ACCESSOR, BUILT ONCE PER MKDEN — and the placement is the whole point, not a tidiness
  # preference. This module is applied once per mkDen, so a `let` here is evaluated once; `mkRelAccessor`
  # returns `id: …` after binding its pool's adjacency, so building it here and applying it per id inside
  # `compute` collapses the per-node rebuild that made the adjacency cost O(E) per (node × kind × field).
  # Constructing it inside `compute` — as this did — re-ran the accessor's entire outer `let`, its pool
  # scoping and its adjacency build, for every node in the fleet.
  #
  # Nothing is forced eagerly by moving it: `mkRelAccessor` binds thunks and returns a function, so a fleet
  # that never reads a relation still pays nothing, and a fleet that reads many shares one build.
  relAccessor = relations.mkRelAccessor {
    inherit (query) denQuery kindGraphOf;
    inherit relationEdges strataOrder;
    relationKinds = relationEdgeKinds;
    # The accessor's capability ceiling is its OWN stratum (§2.3) — the posture `claim-accessor.nix` already
    # takes for the claim pool. It is armed rather than null because the reason it was switched off no longer
    # holds: that reason was that the accessor and its relations both sat at `resolution`, so a strictly-below
    # ceiling would have excluded every relation. §5 L2 has since minted each relation at its own `rel:<name>`
    # stratum inserted after `structural`, which lands every relation strictly below `resolution`.
    #
    # Arming it is observably inert on the shipped surface — the accessor only ever maps over `relationKinds`
    # keys, so the non-relation (production claim) edges the ceiling drops were already unreachable through it.
    # The value is that the source becomes stratum-scoped BY CONSTRUCTION rather than by that accident, which
    # is what makes the per-relation reader-stratum ceiling of §11 L2 a parameter change, not a new mechanism.
    ceiling = strataScope.indexOf strataOrder "resolution";
  };
in
{
  # relAt (§5) as a scheduled attribute — the per-node `{ <kind> = { targets; inverse; closure; paths }; }`
  # relation accessor. `readsAttrs = [ ]`: the producer is the static `relationEdges` pool, so the compute
  # ignores `self` (GAP-5). `den.relAt id` = `structural.eval.get id "rel-accessor"`.
  rel-accessor = resolve.attr {
    name = "rel-accessor";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [ ];
    compute = _self: id: relAccessor id;
  };

  # derivedAt (§5) as a scheduled attribute — the per-node name→value map of every declared derive. `node.rel`
  # is built from the SCHEDULED `rel-accessor` (`self.get id "rel-accessor"`, the intra-node read), so the
  # stratum-gate, `scopedEdges`, and the `deps` placeholder inside `mkDerived` are unchanged. `mapAttrs` keeps
  # each name lazy (forcing one derive never forces the others); `derivedFn` is built once per node so the
  # `inverseToRelation` index is shared across names. `den.derivedAt name id` =
  # `(structural.eval.get id "derived-accessor").${name}` (the top-level exposure adds the unknown-name NAMED
  # throw BEFORE touching the eval, keeping a typo'd name catchable on an inert node).
  derived-accessor = resolve.attr {
    name = "derived-accessor";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [ "rel-accessor" ];
    compute =
      self: id:
      let
        derivedFn = derived.mkDerived {
          relAt = innerId: self.get innerId "rel-accessor";
          derivedIndex = derivedTable;
          relationKinds = relationEdgeKinds;
          inherit (query) denQueryOverEdges;
          inherit strataOrder relationEdges;
        };
      in
      builtins.mapAttrs (name: _spec: derivedFn name id) derivedTable;
  };
}
