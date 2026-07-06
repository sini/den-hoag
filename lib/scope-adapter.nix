# gen-select scope context over a resolve result (Law E6). The nodes buildRoots and
# the `children` NTA emit set `decls.__entry = entry` and `type = kindName`, exactly
# what gen-select's default scope adapter reads (`entryFor` = decls.__entry, kind =
# node.type). Consumed by gen-pipe (Task 5) and containment (Task 6); a thin wrapper,
# no algorithm of its own.
{ select }:
{
  # gen-select context over the scope eval carried on a resolve result.
  selectContext = result: select.adapters.scope.mkContext { inherit (result.eval) node get; };

  # Predicate a selector against a scope node id.
  matchId =
    result: selector: id:
    select.matches selector id (select.adapters.scope.mkContext { inherit (result.eval) node get; });
}
