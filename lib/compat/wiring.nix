# THE compat wiring — the ONE construction of the shim from substrate libs. Both roots go through it:
# the flake's `compat` output and the standalone `default.nix` entry's `.compat`.
#
# WHY THIS FILE EXISTS. The two roots each hand-wrote the `import ./lib/compat` argument set, and a
# hand-written wiring drifts silently: the standalone one omitted `graph`, so its `.compat` threw
# "called without required argument 'graph'" while the flake path — the one every suite exercises —
# stayed green. A dep list restated per root is only as correct as the least-exercised root. With ONE
# formal list, a dep the shim starts requiring is added here, and a root that cannot supply it fails at
# the same place on every path.
#
# The roots differ only in where the gen substrate comes from (flake inputs vs the lock-fetched dep
# entries), so that — not the shim's dep list — is what they pass: the lib values, plus `edgeSrc`, the
# gen-edge SOURCE root. gen-edge's public lib deliberately keeps `edgeSortKey`/`renderName`/
# `traceEntryOf` internal (it exposes `trace`, which uses them), so the frozen core is imported by path;
# that import is part of this one construction, never a per-root copy.
{
  denHoag,
  prelude,
  # gen-schema — id_hash at ingestion.
  schema,
  # gen-aspects — the aspect TAG owner. The shim calls `aspects.wrapFn` to wrap a v1 bare-fn aspect
  # include (which bypasses the option-type merge under R10 raw-absorption) into den-hoag's
  # `__isWrappedFn` functor — the same wrap the type applies to native guard fns. Injected directly
  # (like `schema`/`edge`), not reached through `denHoag`.
  aspects,
  # gen-merge's mkOption/types — for the compile/nav view's shared facet keySemantics (settings facet).
  merge,
  # gen-graph — the ordered preorder-fold calculus (`foldPreorder`). The compat aspect-include
  # reachability walk routes through it (a graph traversal expressed as gen's primitive, not a
  # hand-rolled recursion), the same substrate the resolved-aspects forward-expansion rides.
  graph,
  # gen-edge — inert legacy records + the frozen trace schema.
  edge,
  # the gen-edge SOURCE root (a flake input's store path, or a fetched lock node) — see the header.
  edgeSrc,
}:
# den-compat (L4) — the den v1 compatibility shim + the two-sided parity harness, on top of an assembled
# den-hoag `lib`. `denHoag` = the four-concern API; the shim reaches every gen substrate lib through
# den-hoag vocabulary and needs only the deps above directly.
import ./default.nix {
  inherit
    denHoag
    prelude
    schema
    aspects
    merge
    graph
    edge
    ;
  # the frozen trace renderer the parity harness renders BOTH arms into — the SAME dev-time pattern the
  # parity flake uses for den v1's `edge.nix`.
  edgeCore = import "${edgeSrc}/lib/core.nix" { inherit prelude; };
}
