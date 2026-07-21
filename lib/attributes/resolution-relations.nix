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
}:
{
  relationEdges ? [ ],
  relationEdgeKinds ? { },
  strataOrder ? [ ],
  derivedTable ? { },
}:
{
  # relAt (§5) as a scheduled attribute — the per-node `{ <kind> = { targets; inverse; closure; paths }; }`
  # relation accessor. `readsAttrs = [ ]`: the producer is the static `relationEdges` pool, so the compute
  # ignores `self` (GAP-5). `den.relAt id` = `structural.eval.get id "rel-accessor"`.
  rel-accessor = resolve.attr {
    name = "rel-accessor";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [ ];
    compute =
      _self: id:
      relations.mkRelAccessor {
        denQuery = query.denQuery;
        inherit relationEdges strataOrder;
        relationKinds = relationEdgeKinds;
        # `ceiling = null` = the full relation pool (§2.3). In the shipped single-stratum facet the relation
        # accessor AND its relations both sit at `resolution`, so a strictly-below ceiling would exclude every
        # relation; the derive gate (mkDerived's `ceilingGate`) enforces the boundary per the DERIVE's stratum.
        # The per-relation reader-stratum ceiling arrives with §11 L2 (per-relation strata).
        ceiling = null;
      } id;
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
          denQuery = query.denQuery;
          inherit strataOrder relationEdges;
        };
      in
      builtins.mapAttrs (name: _spec: derivedFn name id) derivedTable;
  };
}
