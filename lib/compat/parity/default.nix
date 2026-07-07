# den-compat parity harness — the two-sided differential (v1 oracle vs den-hoag). This entrypoint
# exposes the PURE pieces addressable off `denCompat.parity`:
#
#   schema — the frozen edge schema (version 1): `keyOf`, `assertEdgeParity` + `firstDivergent`, the
#            cross-version diff guard. The whole structural oracle is the frozen sort-key string.
#   oracle — the arm renderers as functions of the harness inputs: `traceHoag { denCompat }` (this tree,
#            reachable from `denHoag`) needs nothing beyond gen-edge; the v1 arm (`oracle.mkV1`) is a
#            function of the DEV-TIME-ONLY harness inputs (the den v1 flake + nixpkgs), supplied by the
#            `parity/` flake — den-hoag's own flake pins no den v1, so the v1 arm cannot be pre-applied
#            here (it is the parity flake's job, spec §5: the shim never ships a runtime den-v1 dep).
#
# nixpkgs-lib-free: `prelude` + `edgeCore` (gen-edge's frozen trace core — `edgeSortKey`/`renderName`).
# `denHoag` is threaded for symmetry with the other compat sub-libs (and so a future in-tree witness can
# build a hoag arm without re-importing the flake).
{
  denHoag,
  prelude,
  edgeCore,
}:
{
  schema = import ./schema.nix { inherit prelude; };
  oracle = import ./oracle.nix { inherit prelude edgeCore; };
}
