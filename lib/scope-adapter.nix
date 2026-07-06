# gen-select scope context over a resolve result (Law E6) + the gen-pipe traversal adapter (Task 5).
# The nodes buildRoots and the `children` NTA emit set `decls.__entry = entry` and `type = kindName`,
# exactly what gen-select's default scope adapter reads (`entryFor` = decls.__entry, kind = node.type).
# A thin wrapper, no algorithm of its own — the neron ordering lives in gen-scope, the channel fold in
# gen-pipe; this file only projects the resolve eval into the shapes those libs consume.
{ prelude, select }:
let
  # Same-position multi-producer tie-break (A12). gen-pipe's B5 pins order by scope traversal, but two
  # contributions landing at ONE position from distinct producers are ordered here, by producer
  # identity, in a total order independent of the order aspects/policies were declared in and of
  # attrset iteration: aspect (rank 0) before policy (rank 1), then the producer's identity hash, then
  # its own emission index (a producer emitting several at one position keeps its emission order).
  producerLt =
    a: b:
    if a.rank != b.rank then
      a.rank < b.rank
    else if a.identity != b.identity then
      a.identity < b.identity
    else
      a.emissionIndex < b.emissionIndex;
in
{
  # gen-select context over the scope eval carried on a resolve result.
  selectContext = result: select.adapters.scope.mkContext { inherit (result.eval) node get; };

  # Predicate a selector against a scope node id.
  matchId =
    result: selector: id:
    select.matches selector id (select.adapters.scope.mkContext { inherit (result.eval) node get; });

  # gen-pipe's traversal-adapter contract (gen-scope `collectionAttr` shape). `result` is the resolve
  # EVAL (`self` inside an attribute, or `den.structural.eval` at the top level):
  #   order pos            = the pinned self → imports → parent node sequence (the `neron-order`
  #                          collection attribute — the ordering algorithm stays in gen-scope, B5).
  #   contributionsAt      = this position's channel contributions (attribute 10, already tie-break
  #                          sorted below), keyed by channel name.
  #   classesOf pos        = the producing scope's class entries ([ ] for a null-class scope).
  #   render               = display projection of a scope-coordinate bundle.
  traversalAdapter =
    {
      result,
      localDataOf,
      classesOfNode,
    }:
    {
      order = pos: result.get pos "neron-order";
      contributionsAt = pos: chName: localDataOf pos chName;
      classesOf = pos: classesOfNode (result.node pos);
      render = coords: builtins.toJSON coords;
    };

  # Sort the annotated { rank; identity; emissionIndex; contribution; } records by the A12 producer
  # order and project back to the bare contributions gen-pipe folds. Pure — `prelude.sort` is the
  # only algorithm (Law A1).
  sortByProducer = recs: map (r: r.contribution) (prelude.sort producerLt recs);
}
