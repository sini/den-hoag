# Parity harness runbook — run the diff, read `firstDivergent`, classify

The harness renders both arms (den v1 `edgeTrace` vs den-hoag `graph.edges`) into the frozen
`T | P | S | M` trace (`edge-schema.md`) and diffs on the sort-key string. All commands run from the
den-hoag repo. The synthetic harness runs within the default 8 MB stack — no `ulimit` needed. Only the
real-fleet arm below (evaluating live `nixosConfigurations`) is deep enough to want `ulimit -s unlimited`.

## Run the suites

```
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-structural        # P1
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-trace-stability    # P4
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-first-divergent     # P5
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-identity-negcontrol # P7
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-schema-guards        # frozen-schema + normalizer guards (pure, fast)
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-content              # P2 — content: cross-pipeline hash + contentGate shape
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-class-share          # P8 — class-share invisibility (coreGate)
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-permutation          # P3 — declaration-order independence
nix run github:nix-community/nix-unit -- --flake ./parity#tests.parity-ledger-gate          # P6 — ship gate: corpus diffs ∖ ledger = ∅
```

`parity-schema-guards` is pure (no den eval) and runs in a second — start there to prove the frozen-schema
cross-version refusal and the `hoagNormName` mis-map guard before paying for the heavy dual-den suites.

New files under `parity/` or `lib/compat/parity/` must be `git add`ed before nix sees them (both flakes
read a git tree). See `feedback_stage_new_files`.

## Add a fixture (the full cycle — C8 does this repeatedly)

1. **Write it** in `parity/fixtures/topologies.nix` as `{ name; module; crossArm; hostRoots ? true; flakeRoot ? false; }`. A plain-attrset `module` (`{ den.hosts…; }`) runs on BOTH arms (`crossArm = true`); a FUNCTION module (`{ den, lib, … }: …`) reaches den v1's `den.lib.policy.*` and is v1-ONLY
   (`crossArm = false`, e.g. the negative control).
1. **`git add parity/fixtures/topologies.nix`** — BEFORE any nix command. Both flakes read a git tree, so
   an unstaged fixture is invisible and the harness silently uses the old set (this is the #1 gotcha).
1. **Capture its diff.** Run the same shape the P1 suite uses (`resultOf`), as a one-off:
   ```
   nix eval --impure --json --expr '
     let
       hoag = builtins.getFlake "path:/abs/den-hoag";
       parity = builtins.getFlake "path:/abs/den-hoag/parity";
       npkgs = parity.inputs.nixpkgs; nlib = import "${npkgs}/lib";
       v1flk = parity.inputs.den-v1;
       v1edge = import "${v1flk}/nix/lib/aspects/fx/edges/edge.nix" { lib = nlib; };
       P = hoag.compat.parity;
       v1 = P.oracle.mkV1 { denV1Flake = v1flk; denV1Edge = v1edge; nixpkgsLib = nlib; nixpkgs = npkgs; };
       fx = (import ./parity/fixtures/topologies.nix { }).<yourFixture>;
       keys = t: map (e: e.__sortKey) t;
       h = t: builtins.hashString "sha256" (builtins.toJSON (P.schema.keysOf t));
       tV1 = v1.traceV1 fx; tHoag = P.oracle.traceHoag { denCompat = hoag.compat; } fx;
       p = P.schema.assertEdgeParity { expected = tV1; actual = tHoag; };
     in { v1 = keys tV1; hoag = keys tHoag; matched = P.schema.keysOf p.matched;
          missing = P.schema.keysOf p.missingFromActual; extra = P.schema.keysOf p.extraInActual;
          v1Hash = h tV1; hoagHash = h tHoag; }'
   ```
1. **Write the golden.** Transcribe the JSON into a new `<yourFixture> = { … };` entry in
   `parity/golden/traces.nix` (the seven keys above — `v1`/`hoag`/`matched`/`missing`/`extra`/`v1Hash`/
   `hoagHash`). Every list must be a normalized `<kind>:<name>` sort key.
1. **Wire the tests.** Add the fixture to `parity/tests/parity-structural.nix` (`resultOf` + a
   `test-<name>` asserting `diffOnly` == `goldenDiff golden.<name>`) and to
   `parity/tests/parity-trace-stability.nix` (the two golden-hash tests + a topology-invariance test).
1. **Ledger a row** in `ledger.md` IF the diff introduces a NEW classification (a divergence shape not
   already covered by L1–L5). A fixture whose diff is the same domain-boundary shape needs no new row —
   note it under Scope instead.
1. **Re-run** `parity-structural` + `parity-trace-stability` (green) and re-`git add` the changed files.

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

## P6 ship gate — corpus diffs ∖ ledger = ∅

`parity-ledger-gate` (P6) is the mechanical ship condition: every golden divergence key (the `missing` +
`extra` sets across all cross-arm fixtures) must classify into a LEDGERED family — the ordered matchers in
`parity/tests/parity-ledger-gate.nix`, mirroring the `ledger.md` rows (L4 quirk-fold / class-fold
domain-boundary, residual-n A15 user-as-cell — absorbs the former residual-o hm-fold). An unledgered key classifies into NO
family and FAILS the gate. So a NEW divergence — a regression that shifts an edge, or a re-baselined golden
without a matching ledger row — cannot ship silently: you MUST add the `ledger.md` row AND (if it is a new
family) a matcher in `parity-ledger-gate.nix`. The gate carries a negative-control (a fabricated unledgered
key that must classify into nothing) so its teeth are proven.

## Permutation regression (P3)

`parity-permutation` asserts declaration-order independence end-to-end through the shim: the TRACE half is
UNCONDITIONAL (every include/policy order renders a byte-identical sort-key list — gen-edge Law 2 +
producer-identity tie-break); the CONTENT half is conditional (`contentStable`), comparing the FOLDED
per-root class config (not the raw `outputFor` module list, whose order reflects declaration order — a
harness artifact, not a real divergence). A fixture whose ordered-list channels have same-position
multi-producers (Open Question 6) is content-excluded (`contentStable = false`) and recorded, never skipped.

## The fleet arm (ship-gate, dev-time)

The CI suites run the SYNTHETIC corpus. The full-fleet content arm — the real nix-config corpus
(`nixosConfigurations` + `darwinConfigurations` + standalone home) evaluated under both den arms and diffed
at the toplevel drv-hash level (`contentGate`) — is the SHIP-GATE, run dev-time: it evaluates the `corpus`
flake input and crosses nixpkgs/nix-darwin, so it cannot run in den-hoag's own CI. At ship-gate: pin all
corpus inputs identical except the den input, evaluate each configuration's toplevel `.drvPath` under both
arms (`config.system.build.toplevel.drvPath` for nixos, `.system.drvPath` for darwin), and require the diff
∖ ledger empty — the same P6 discipline over the real corpus.

**How the fleet arm gets a `shimDrvPath` — the terminal seam.** A collect-pinned shim can never produce a
`shimDrvPath` (a collect artifact has no `config`/`system.build.toplevel`). The C9 item-4 seam is the fix:
`denCompat.mkDenWith userModules { nixosTerminal = crossNixos; }` supplies the nixpkgs-bound `crossNixos`
terminal so the shim's `nixosConfigurations` are REAL NixOS systems — the same mechanism a v1 user gets when
they bump the den input for a real build. The harness builds the terminal from the den-hoag source
(`import "${den-hoag}/lib/output/terminal.nix" { inherit (denHoag.internal) bind flake; } { inherit nixpkgs; }`),
and `parity-content-live.nix` proves it at n=1 (both arms cross, `networking.hostName` byte-matches). The
ship-gate script runs `contentGate` over the corpus on this crossed path.

**The drvPath smoke + bootability.** `parity-content-live.nix` compares `networking.hostName` in CI (a config
value, no bootability needed). The stronger `system.build.toplevel.drvPath` comparison (the actual P2 hash at
n=1) rides the ship-gate script: a synthetic smoke fixture must set `boot.isContainer = true` to skip the
`fileSystems`/`boot.loader` assertions a real toplevel asserts. This constraint only affects SYNTHETIC smoke
fixtures — real corpus hosts are bootable, so the full-fleet drvPath diff needs no such trick. Measured
feasibility (cold, eval-only): hostName 0.5s, toplevel drvPath 1.2s per config — a few seconds per host.

## The cross-pin type-mount seam — belt AND suspenders (owner, 2026-07-10)

The corpus mounts gen-schema kind-values into its OWN nixpkgs `lib.evalModules`
(`den.clusters`/`den.environments = mkInstanceRegistry`), so a kind-value's option module carries
gen-merge types across the pin boundary. Two resolutions ship together (composition, not coupling);
the ship-gate verifies BOTH, and their equivalence is a RUNBOOK property, not a unit test.

- **Belt — opaque pass-through** (`bridge.nix`, `passThrough = true` default). The bridge swaps each
  processed kind-value's option `__functor` for the corpus's OWN raw nixpkgs `imports`/`options`, so no
  gen-merge type crosses; the corpus builds instance types at its own pin. Makes UNALIGNED pins work —
  the production-realistic mid-migration state, and the DEFAULT ship-gate path (the fleet arm above run
  with only `--override-input den`). A SEVERABLE seam (one flag, `passThrough`); retire it once the
  consumer is protocol-complete.
- **Suspenders — the nixpkgs optionType protocol completion** (gen-merge `mkOptionType`, the general
  interface gen-types owed nixpkgs consumers). Its pure types then mount unchanged; gen-schema inherits
  it free. The correct long-run fix that lets the belt retire.

**Why the equivalence witness is a runbook property, not a pin-bumped unit test.** The belt is DESIGNED
for unaligned pins; bumping den-hoag's own `gen-merge` lock to unit-test the equivalence would couple
this repo to the suspenders — the exact coupling the belt exists to avoid. So the equivalence is a
property of two PROBE CONFIGURATIONS over the real corpus, spelled out here and re-proven empirically
each time the ship-gate runs both arms:

1. **belt-unaligned** — the fleet arm with only `--override-input den`. The corpus's own (older)
   gen-schema consumes the pass-through kind-values; evaluation reaches the cluster registry into
   materialization and stops at the next rung (the C6 policy-aspect-lambda `resolveAspectRef` gap,
   orthogonal to the cross-pin).

1. **belt-severed + protocol override set** — sever the seam (`passThrough = false`) and align the
   consumer's gen-schema/gen-merge to the protocol-complete revisions:

   ```
   ulimit -s unlimited
   nix eval --no-write-lock-file '.#nixosConfigurations' --apply builtins.attrNames \
     --override-input den path:/abs/den-hoag \
     --override-input gen-schema path:/abs/gen-schema \
     --override-input gen-schema/gen-merge path:/abs/gen-merge \
     --override-input den/gen-schema path:/abs/gen-schema \
     --override-input den/gen-schema/gen-merge path:/abs/gen-merge
   ```

   The protocol-complete types mount directly (no pass-through); evaluation reaches the IDENTICAL next
   rung.

Both configurations converge on the same rung and, past it, the same materialization, so the corpus
drvPath is byte-compared at the gate either way. At real migration the override set becomes a normal
input bump and the belt retires (delete `passThroughSeam`, flip the default). The toggle witness
`compat-schema-processing.test-passthrough-seam-severable` pins the FIRST half (severing yields kind +
structure without the raw nixpkgs option); this override run is the SECOND half (the severed path,
protocol-aligned, still evaluates through to the same rung), and the two together are the equivalence.
