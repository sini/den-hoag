# The graph escape hatch (spec §2.11). Concerns are the default surface; the full graph vocabulary is
# one layer down. den-hoag re-exposes it READ-ONLY as `den.graph` — the gen-scope result, the restricted
# gen-product fleet, the per-root gen-edge edge set + frozen trace (the parity-oracle input, Law A15/A7),
# and the gen-demand resolution. No wrapper API, no algorithm — `edges`/`trace` are direct gen-edge calls
# over the same graph accessor attribute 12 folds (Law A1).
{ edge }:
{
  scope,
  fleet,
  graphAccessor,
  demands,
}:
{
  inherit scope fleet demands;
  edges =
    root:
    edge.edgesFor {
      graph = graphAccessor;
      inherit root;
    };
  trace =
    root:
    edge.trace (
      edge.edgesFor {
        graph = graphAccessor;
        inherit root;
      }
    );
}
