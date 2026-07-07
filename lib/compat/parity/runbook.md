# Parity harness runbook — run the diff, read `firstDivergent`, classify

The harness renders both arms (den v1 `edgeTrace` vs den-hoag `graph.edges`) into the frozen
`T | P | S | M` trace (`edge-schema.md`) and diffs on the sort-key string. All commands run from the
den-hoag repo; **`ulimit -s unlimited` first** (the dual-den module-system evals exceed the 8 MB stack).

## Run the suites

```
ulimit -s unlimited
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-structural       # P1
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-trace-stability   # P4
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-first-divergent   # P5
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-identity-negcontrol # P7
```

New files under `parity/` or `lib/compat/parity/` must be `git add`ed before nix sees them (both flakes
read a git tree). See `feedback_stage_new_files`.

## Inspect a diff by hand

`denCompat.parity` exposes the pure pieces; the `parity/` flake wires the dev-time arms. A one-off:

```nix
let
  hoag   = builtins.getFlake "path:/abs/den-hoag";
  parity = builtins.getFlake "path:/abs/den-hoag/parity";
  npkgs  = parity.inputs.nixpkgs;   nlib = import "${npkgs}/lib";
  v1flk  = parity.inputs.den-v1;
  v1edge = import "${v1flk}/nix/lib/aspects/fx/edges/edge.nix" { lib = nlib; };
  P      = hoag.compat.parity;
  v1     = P.oracle.mkV1 { denV1Flake = v1flk; denV1Edge = v1edge; nixpkgsLib = nlib; nixpkgs = npkgs; };
  fx     = (import ./parity/fixtures/topologies.nix { }).plainHostUser;
  p      = P.schema.assertEdgeParity { expected = v1.traceV1 fx; actual = P.oracle.traceHoag { denCompat = hoag.compat; } fx; };
in { inherit (p) parity; missing = P.schema.keysOf p.missingFromActual; extra = P.schema.keysOf p.extraInActual; first = p.firstDivergent; }
```

## Read `firstDivergent`

`{ key; onlyIn; entry; precededBy; followedBy; }` — the least element of the symmetric difference under
the total sort-key order.

- `key` — the divergent edge's frozen sort key (normalized names).
- `onlyIn` — `"v1"` = present in the oracle only (missing from hoag); `"hoag"` = present in hoag only.
- `precededBy` / `followedBy` — the matched keys bracketing it (null at an end), so you see WHERE in the
  ordered trace the arms first part ways.

## Classify a divergence

For each `missing`/`extra` key, decide and record in `ledger.md`:

1. **domain boundary** — a class-fold edge missing on hoag, or a quirk-fold edge extra on hoag. Expected
   at C7 (`edge-schema.md` "domain finding"); disposition = tracked to #44 / default-fold reconciliation.
1. **schema-alignment (F1/F2)** — an entity scope that failed to name-normalize (id_hash leaked), or a
   non-entity scope with no `nonEntityNameMap` entry. Fix the normalization / extend the map, re-golden.
1. **real shim defect** — a delivery edge the shim compiled wrong (wrong class/path/mode). Fix the shim;
   this is the parity harness earning its keep.

Regenerate the golden after any deliberate change: re-run the capture (the `resultOf`/`crossArm` shape in
`parity/tests/parity-structural.nix`) and update `parity/golden/traces.nix`, then re-classify in
`ledger.md`.
