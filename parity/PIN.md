# Frozen den v1 pin + re-validated §2.6 corpus survey

This file discharges the den-compat plan's **blocking pre-gate** (Open Question 3): it records the
exact frozen den v1 reference rev the parity harness pins, and re-validates the §2.6 corpus survey
against that rev + the corpus pin — so the promoted-fixture list (§7.3) and Task 5's forward-tier
scope rest on grep-confirmed reality, not on the pre-pin survey.

## Frozen v1 pin

- **Rev:** `denful/den @ 11866c16` — full: `11866c167f5b4408149a4914966ae1a050054358`

- **Subject:** `feat: pipe.broadcast cross-scope push + collect reads exposed (#623)`

- **Reachability (verified 2026-07-06):** `11866c16` is a reachable ancestor of the current
  `denful/den` main tip `1614f6f8`, so `github:denful/den/11866c16` resolves. The pin is a
  **deliberate freeze**, currently 2 commits behind main:

  - `1614f6f8 fix: preserve source entity binding in forward fallback (#627)`
  - `3932adfe fix: derive class-content emit ctx from authoritative scope state (#624)`

  These land after the frozen surface and do not affect the dev-time dependencies the harness reads.

- **Dev-time only.** The shim never ships a runtime dependency on den v1 (spec §5); this pin exists
  solely for the parity harness. The rev carries every dev-time dependency the harness reads,
  verified present at HEAD:

  - `nix/lib/aspects/fx/edges/edge.nix` — `edgeSortKey` (the `T | P | S | M` byte contract),
    `sources.{collected,rewalk,synthesize}`, `rootTarget`/`outputTarget`. Both arms render into this
    exact sort key (the shared structural oracle). Consumed directly by the harness (`{ lib }`-only).
  - `nix/lib/aspects/fx/edges/parity.nix` — `assertEdgeParity { expected, actual }` →
    `{ matched; missingFromActual; extraInActual; parity; }`. `{ lib }`-only.
  - `nix/lib/aspects/fx/edges/materialize-unified.nix` — `materializeUnified`, `exposeEdges` (the
    single toposorted edge fold per root; Tasks 15–17 shipped).
  - `nix/lib/aspects/fx/resolve.nix` — `productionEdgeTrace`/`edgeTrace` via `exposeEdges`;
    `legacyEdgeTrace` the P7 negative control.
  - `nix/lib/policy-effects.nix` — `deliver`/`route`/`provide`; `nix/lib/forward.nix` +
    `handlers/forward.nix` + `modules/aspects/batteries/forward.nix`;
    `nix/lib/aspects/fx/aspect/provide.nix` (`mkSelfProvideInclude`, the
    `host.name == key || user.name == key` deliverable-scope dispatch); `content-util.nix`
    (`applyProvide`).

## Corpus pin

- **Rev:** `github:sini/nix-config @ b0b207693ce66fb57acf2bb09cf9549e1dbddec7` (INTERIM — see the
  `parity/flake.nix` note; the real harness migrates to a synthetic self-contained corpus, a tracked
  follow-up).

## §2.6 corpus survey — re-validated 2026-07-06

Grepped the corpus canonical tree (`.worktrees/` and `.git` excluded — the worktree copies otherwise
inflate every count) at the pin above, cross-referenced against the frozen v1 batteries.

| Survey claim | Re-check | Verdict |
| --- | --- | --- |
| Zero `batteries.forward` call sites | `grep -rn 'batteries\.forward'` (canonical) → **0** | ✅ confirmed |
| Three `policy.route` sites in `home-platform.nix` = tier 1 | `modules/den/classes/home-platform.nix` lines 10/20/30: `homeLinux/homeDarwin/homeAarch64-to-hm`, each `path = [ ]`, no `adaptArgs` → **tier-1 static forwards → plain `deliver`** | ✅ confirmed |
| hm delivery = adapter-bearing synthesize | den v1 `modules/aspects/batteries/home-manager.nix`: `homeManager` class has `parentArg = "osConfig"` + `parentPath = userHostPath`; `os-user.nix` threads `adaptArgs = args: args // { osConfig = args.config; }` → **arg-adapting ⇒ synthesize record, not plain deliver** | ✅ confirmed |

### Additional finding (Task 5-relevant, not in the original three claims)

`modules/den/classes/devshell.nix` contains a **second adapter-bearing route**:
`route { fromClass = "devshell"; intoClass = "flake-parts"; path = [ "devshells" "default" ]; adaptArgs = { config, ... }: config.allModuleArgs; }`.
This is a complex (adapter-bearing) forward → **synthesize record + `interpret.synthesize`** (Task 5's
implemented path), not a tier-1 static forward. Recorded so Task 5's witness set covers it.

### Open-Question-2 census — tier-2 derived-children NTA forward consumer

**None found.** The corpus's entity-derivation mechanisms are:

- `policy.instantiate` (nixidy: k8s manifest collection per cluster) — a native den-hoag mechanism,
  compiled through the non-legacy surface (Tasks 1–2), **not** the legacy forward surface.
- the `microvm-guests` quirk (`modules/den/quirks/microvm-guests.nix`, explicitly *"provides-free"*)
  - `microvm.guests` on hosts — native den-hoag, **not** a forward.

No `forward`-with-derived-children (NTA-spawning) consumer exists in the corpus. **Task 5's scope is
NOT widened; Tier-2 derived-children NTA remains NOT implemented** (the plan's default holds). If a
future corpus bump introduces such a consumer, re-open Open Question 2 here.

### C7 census — freeform-child → provides synthesis consumer (C4–C6 watch-list item b)

**None found.** `grep -rn --include='*.nix' 'provides\.' <corpus canonical>` (worktrees/.git excluded,
480 `.nix` files) returns **0** declaration sites; the only `provides` tokens in the tree are incidental
prose (comments, package descriptions, the `microvm-guests` *"provides-free"* label). So the v1
freeform-child→provides synthesis pattern (`aspect.docker` ⇒ `provides.docker`) has **zero corpus
consumers**, and the compat `legacy/provides` desugar (C4) is exercised only by synthetic witnesses (the
C1 witness map's `providesLegacy`). This matches Open-Question-2's finding that the legacy severable
surfaces are corpus-dead; if a future corpus bump adds a `provides` site, re-validate the C4 desugar here.

## C7 parity-harness findings (first-corpus run, 2026-07-07)

The C7 harness (`lib/compat/parity/`) evaluates fixtures through BOTH den v1 (`edgeTrace`) and den-hoag
(`graph.edges`) and diffs on the frozen `T | P | S | M` sort key. Two schema-alignment findings + one
domain finding, recorded in full in `lib/compat/parity/edge-schema.md` + `ledger.md`:

- **F1 — entity id_hash divergence.** den v1 and gen-schema stamp DIFFERENT id_hashes for the same
  `(kind, name)` (`host:igloo`: v1 `dd5c0a82…` vs hoag `8bba6f6a…`). The plan's "entity scopes on both
  sides without translation" is empirically false; the harness name-normalizes entity scopes to
  `<kind>:<name>` on both arms (den v1's own `normalizeTrace` precedent). HANDLED in `oracle.nix`.
- **F2 — non-entity scope naming (OQ4).** v1 `mkScopeId` strings vs den-hoag opaque strings; a seeded
  `nonEntityNameMap` translates the hoag arm; completeness is a first-full-corpus finding.
- **Domain boundary.** den v1 folds CLASS content as edges; den-hoag folds QUIRK CHANNELS + demand + the
  explicit deliver surface (class content rides the class-module path). The domains are largely disjoint,
  so cross-arm parity is non-empty at C7 (all v1 class-folds `missing` on hoag, hoag quirk-folds `extra`).
  Convergence is gated on the deliver-materialization completion (#44 / C7.5) + a default-fold
  reconciliation. Pinned in `parity/golden/traces.nix`; the P1 suite tracks the boundary as a regression
  gate.

## Forward-tier summary (the input to Task 5's witness set)

- **Tier-1 static** (`path`, no `adaptArgs`) → plain `deliver`: the 3 `home-platform.nix` routes.
- **Adapter-bearing complex** → `synthesize` record + `interpret.synthesize` — **LABEL CORRECTED
  (C5 review):** this arm belongs to the FORWARD surface (`forward`/`forwardTo`/`__complexForward`,
  route.nix:824-826), which has ZERO corpus consumers. The hm delivery and the `devshell` route are
  adapter-bearing **`policy.route`** sites — in frozen v1 a route-with-`adaptArgs` renders a
  **COLLECTED edge with adapt annotation, NOT synthesize** — and compat compiles them via the
  deliver surface (Task 2's collected+adapt path). The C7 harness must witness them there, never
  through `legacy/forwards`. Task 5's synthesize fixtures are synthetic forward specs mirroring the
  corpus adapter *shapes* for surface-totality coverage.
- **Tier-2 derived-children NTA** → NOT implemented: no corpus consumer (census above).

## Upstream compatibility note (#624 / #625) — owner directive, 2026-07-07

The frozen v1 pin (`11866c16` = #623) PREDATES den #624 (emit-classes reads scope ctx from
`state.scopeContexts`; class content keyed by named entity args — the "N user-scoped nixos
configs collapse to 1" fix), #627, and #625 (replicated-home shortfall; draft on the sini fork
at pin time). The shim must be COMPATIBLE with the #624/#625 semantics: den-hoag natively keys
class content per member/cell (`systems.<class>.<member>`), so the #624 bug class is
structurally absent on the v2 arm — the open question is only whether the SHIM's compilation
reproduces post-#624 delivery shapes. VERIFY at nix-config integration (the C8 corpus arm);
the pin-bump decision (stay at #623 vs advance past #627) is a ship-gate item with ledger
evidence in hand.

## C9 item-4 — the content-arm asymmetry + n=1 ship-gate feasibility (2026-07-10)

The v1 content arm is a SHIP-GATE arm, and the deeper reason is NOT merely the missing home-manager
input (wiring it, C9 item 2, was necessary but NOT sufficient). The two arms' materialized `.imports`
are different KINDS: the hoag arm's are plain den-hoag class DECLARATION data (freeform-foldable — the
M2 hoag hashes); the v1 arm's are REAL nixpkgs nixos modules, meaningful only inside the full
module-system fixpoint (a freeform fold infinite-recurses on `nixos/common.nix`). So a live v1-vs-hoag
CONTENT comparison must CROSS (build a real nixosSystem), not fold.

FEASIBILITY (measured, cold, eval-only — no store build): `config.networking.hostName` 0.5s;
`config.system.build.toplevel.drvPath` 1.2s per config. Well within CI budget → `parity-content-live.nix`
runs the hostName comparison in CI (both arms cross; the item-4 terminal seam supplies the shim's
`crossNixos`). The stronger drvPath comparison is the dev-time `parity/ship-gate.nix` smoke (a
`boot.isContainer` fixture to satisfy bootability). RESULT at n=1: v1DrvPath == shimDrvPath BYTE-IDENTICAL
(the shim's crossed nixosSystem is the same derivation as v1's) — the P2 drv-hash parity, proven at n=1.
The full-fleet drvPath diff over the real corpus is the ship-gate (runbook.md).
