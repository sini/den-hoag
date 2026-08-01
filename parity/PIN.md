# Frozen den v1 pin + re-validated §2.6 corpus survey

This file discharges the den-compat plan's **blocking pre-gate** (Open Question 3): it records the
exact frozen den v1 reference rev the parity harness pins, and re-validates the §2.6 corpus survey
against that rev + the corpus pin — so the promoted-fixture list (§7.3) and Task 5's forward-tier
scope rest on grep-confirmed reality, not on the pre-pin survey.

## v1 oracle pin

> **CURRENT — `denful/den @ 7f11ba14`** (full `7f11ba1494052fd3ac52c1342915bcb52ba08f07`), subject
> `fix: keep same-username homes on different hosts distinct (#641)`. Advanced from the #623 freeze by
> the **owner directive of 2026-07-30** recorded in the bump section at the foot of this file. The pin
> is still a DELIBERATE pin — it tracks no branch and moves only by recorded ruling — but it is no
> longer the #623 freeze, and the "the oracle must not move under the shim" reasoning below is
> **superseded** for this bump.

### Superseded: the original freeze (in force 2026-07-06 → 2026-07-30)

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

- **Rev (CURRENT, 2026-08-01):** `github:sini/nix-config @ 0d74319dfb39e643f6865497268a2034422d74df`
  — the deliberate-repin cadence; see the 2026-08-01 bump section at the foot of this file.
- **Rev (superseded, 2026-07-30 → 2026-08-01):** `github:sini/nix-config @ 425f1d3b2fcc2c5547ee593a8cb74d5d61192626`
  — advanced by the 2026-07-30 owner directive; see that bump section.
- **Rev (superseded, 2026-07-07 → 2026-07-30):** `github:sini/nix-config @ b0b207693ce66fb57acf2bb09cf9549e1dbddec7`

Still INTERIM either way — see the `parity/flake.nix` note; the real harness migrates to a synthetic
self-contained corpus, a tracked follow-up.

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

## C9 item-6 — corpus host survey, #624/#625, pin-bump material (2026-07-10)

**Darwin confirmed corpus-relevant.** The corpus HAS a darwin host (`patch`, `system = "aarch64-darwin"`),
so M2's darwin native output-class registration is required for corpus parity, not speculative.

**Host-class survey (drives ledger p + q).** Corpus hosts mostly declare NO `class` field; class is carried
by `system` (e.g. `patch` = aarch64-darwin) or defaulted. v1's os-to-host gates on `host ? class`, so a
classless host is inert there; the shim's `hostClassName = h.class or "nixos"` instead gives it nixos —
harmless for genuine nixos hosts but a MISCLASSIFICATION for `patch` (darwin-by-system). Ship-gate fix:
derive the shim host class from `system` (darwin → darwin) or default to null (inert). See ledger row p
(corrected: NOT out-of-corpus). Separately, `slab` declares `class = "droid"` (nix-on-droid) — a non-built-in
output class to register at the ship-gate (ledger row q).

**#624/#625 compatibility.** #624 (emit-classes scopeContexts / per-named-entity class keying; the "N
user-scoped nixos configs collapse to 1" fix) is STRUCTURALLY ABSENT on the v2 arm: den-hoag natively keys
class content per (user,host) cell (`systems.<class>.<member>`), so the collapse bug cannot occur. The C9
item-4 n=1 crossing gives direct evidence in the right direction — the shim's crossed nixosSystem is
BYTE-IDENTICAL (drvPath) to v1's for a single-host fixture. Full #624/#625 verification is the corpus arm at
the ship-gate (multi-user hosts), where the per-cell keying is actually exercised.

**Pin-bump material.** *(SUPERSEDED 2026-07-30 — the owner ruled the other way; the recommendation below is
kept as the reasoning that was on the table, not as current guidance. See the bump section that follows.)*
The frozen pin is 11866c16 (== #623). Decision at ship-gate: stay at #623 vs advance
past #627/#624. Evidence in hand: (a) the P1 edge-trace ledger (residual-n scope-model boundary is the v2
model, not a shim defect); (b) the P2 n=1 drv-hash parity (byte-identical); (c) den-hoag's per-cell keying
makes the #624 bug class structurally absent. Recommendation leans STAY at #623 for the frozen parity oracle
(it predates #624/#627 by design — the oracle must not move under the shim); advance the CORPUS pin
separately if the corpus needs post-#624 fixes, re-running P2 to confirm the drv-hash still holds.

## 2026-07-30 — OWNER-DIRECTED PIN BUMP (both oracles advanced)

**The ruling.** Owner directive, 2026-07-30: *"We should bump both nix-config and the den target, as both
contain bugfixes that will aid in correctness validation."* This OVERRIDES, for this bump, (a) the
frozen-oracle never-bump rule and (b) this file's own C9 item-6 recommendation to STAY at #623 and advance
only the corpus pin. The override is the owner's to make; the superseded recommendation is retained above
rather than deleted, so the reasoning that was on the table stays legible.

| Pin | From | To |
| --- | --- | --- |
| `den-v1` | `11866c16` (#623) | `7f11ba1494052fd3ac52c1342915bcb52ba08f07` (#641) |
| `corpus` | `b0b20769` | `425f1d3b2fcc2c5547ee593a8cb74d5d61192626` |

Both targets re-verified against `git ls-remote … main` at execution time — each was the live branch tip,
so no drift between the directive and the applied rev. Sole pin site: the two inline-rev urls in
`parity/flake.nix`. `ci/flake.nix` carries neither input (measured, with a positive control on the same
instrument in the same run: `den-v1|corpus|nix-config|denful/den` → 0 hits, `nixpkgs|gen` → hits).

### Oracle deltas

**den — 7 commits**, six of them fixes; these are the correctness bugfixes the directive cites:

- `3932adf` fix: derive class-content emit ctx from authoritative scope state (#624)
- `1614f6f` fix: preserve source entity binding in forward fallback (#627)
- `84b5149` docs: fixed typo in custom-classes documentation (#630) — *not a fix*
- `b7bebde` fix: surface spawn-projected quirk emits at the requesting scope (#625)
- `2fcac84` fix: surface the requesting scope's own quirk emits into host-aspects
- `99cc0c5` fix: fan class-module entity args over scope descendants (#629) (#634)
- `7f11ba1` fix: keep same-username homes on different hosts distinct (#641)

`99cc0c5` **is a verified ancestor** of `7f11ba14` (`git merge-base --is-ancestor` → true), so this bump
SUBSUMES the declared-but-unlanded `11866c16 → 99cc0c5` bump; that separate bump is moot.

**corpus — 43 commits**, 31 touching `modules/den/**`. Predominantly MCP/tooling and fleet-config churn
(`gen-lsp-mcp` packaging, ACL/VPN rules, telemetry). The den-shape-relevant ones are the overlay
restructuring (`e34fdc16` nixpkgs-overlays quirk, `ce3e8fb8`, `f84965f7`), `1b81470c` useGlobalPkgs +
user-overlay projection, and `fddab954` renaming microvm/home-manager aspects off a class-name collision.
None of these touch the constructs the parity censuses gate on (verified below).

### Dev-time dep surface at the new den rev — VERIFIED INTACT

Every file and binding this file enumerates is present and contract-shaped at `7f11ba14`. Measured by
dumping each path with `git show <rev>:<path>` to a file and grepping the file (piped `git show | grep`
has failed clean in this repo), with a clean positive/negative control pair on the same instrument
(`edgeSortKey` → 3, `zzzNotARealBindingXyz` → 0).

**8 of the 10 dep-surface files are BYTE-IDENTICAL across the bump** — including, critically,
`edges/edge.nix` and `edges/parity.nix`, the two the harness imports directly as source. So the
`T | P | S | M` sort key and `assertEdgeParity`'s `{ matched; missingFromActual; extraInActual; parity; }`
record are unchanged *by construction*, not merely by grep. `policy-effects.nix` (deliver/route/provide),
the `forward.nix` trio, `provide.nix` (`mkSelfProvideInclude`) and `content-util.nix` (`applyProvide`) are
likewise byte-identical.

The two that changed:

- `edges/materialize-unified.nix` (+2, −0): threads one additional `scopeEntityKind` field through the
  two existing `inherit` lists. Purely additive; `materializeUnified`/`exposeEdges` unchanged.
- `fx/resolve.nix` (+191, −83): the bulk of the #634/#641 work. The edgeTrace family survives with its
  shape intact — `productionEdgeTrace` still a `sortEdges (…)`, `edgeTrace = productionEdgeTrace`, and
  `legacyEdgeTrace` still present as the P7 negative control.

### §2.6 census re-validation at the new corpus rev

Both corpus revs were exported (`git archive`) and measured with the **same instrument in the same run**,
rather than comparing against the numbers recorded above — so "unchanged" is a measurement, not a memory.
The instrument reproduces this file's original 480-`.nix`-file count at the old rev exactly, which
validates it. (New rev: 500 `.nix` files.)

| Census | Old rev | New rev | Verdict |
| --- | --- | --- | --- |
| `batteries.forward` sites | 0 | **0** | unchanged (control `batteries.` → 11 / 13) |
| `policy.route` sites | 4 | **4** | unchanged — the `home-platform.nix` tier-1 triple + the `devshell.nix` adapter-bearing route |
| `provides.` declarations | 0 | **0** | unchanged — the C4 corpus-dead claim HOLDS (control `provide` → 81 / 78) |
| tier-2 NTA forward consumer | none | **none** | OQ2 stays CLOSED (control `policy.` → 33 / 35) |
| entity-derivation mechanisms | instantiate 6, microvm-guests 8 | **6 / 8** | unchanged |
| host class survey | patch darwin-by-system, slab `class="droid"`, rest classless | **identical** | unchanged; host file set identical |

Two findings worth recording beyond the counts:

- `modules/den/classes/home-platform.nix` and `modules/den/classes/devshell.nix` are **byte-identical**
  old→new. The route census is therefore stable in SHAPE, not just in count: the triple is still
  `path = [ ]` with no `adaptArgs` (tier-1 static), and the devshell route still carries
  `adaptArgs = { config, ... }: config.allModuleArgs`.
- `modules/den/batteries/nix-on-droid.nix:67` contains a `forwardPathFn`, which the OQ2 predicate above
  does not match. It is **not** an OQ2 re-opener: it is an argument to `den.lib.home-env.makeHomeEnv`
  (v1 `nix/lib/home-env.nix` consumes it as `intoPath`, the deliver/route surface — the same shape the hm
  and hjem batteries use), NOT the `forward`/`forwardTo`/`__complexForward` NTA-spawning surface. It is
  also present unchanged at the OLD pin, so it cannot be a source of movement either way.

**No re-opened questions.** OQ2 stays closed; the C4 desugar stays corpus-dead.

### Suite outcomes

- **parity: 71/71, exit 0 — ZERO movement.** Before and after logs were diffed at per-test granularity
  (name + status, sorted); the result sets are IDENTICAL. There is nothing to attribute: no test moved,
  so no oracle delta needs to account for one.
- **ci: 2020/2040, exit 1, the same 20 non-pass** — exactly the recorded baseline, i.e. INVARIANT, as
  required (ci consumes neither pin). The 20 are the known parked set: 2 `compat-*`, 13 `den-pipe`,
  5 `pipe-consume`.
- **P2 n=1 drv-hash smoke (`parity/ship-gate.nix`): `allEqual = true`.** All three comparisons are
  BYTE-IDENTICAL across the arms at the new pins — base `nixosConfigurations.igloo`, the M2.5
  emitting-channel host, and the silent-channel totality host. The drv-hash parity therefore SURVIVES an
  oracle that now includes #624/#634/#641 — the fixes that reshape class-content emit ctx, class-module
  entity-arg fanout, and same-username home keying. That is a substantive corroboration of this file's
  standing claim that the #624 bug class is structurally absent on the v2 arm, not merely a re-pass.

### Lock hygiene

Targeted update only (`nix flake lock --update-input den-v1 --update-input corpus`). The resulting
`parity/flake.lock` diff was checked **path-wise, not node-key-wise** — nix renumbers suffixed duplicate
node keys (`gen-merge_10` etc.) when a subtree re-resolves, so a key-keyed diff reports ~67 spurious
"out-of-scope" moves. Resolving each root input's closure to canonical paths instead: **401 changed paths,
400 under `corpus/` and 1 under `den-v1/`, and NONE outside those two subtrees.** The sibling top-level
pins `gen`, `nixpkgs`, `den-v2` and `home-manager` are byte-identical. The §4.4 invariant still holds:
`home-manager`'s `nixpkgs` resolves to the same node as the top-level `nixpkgs` (`nixpkgs_20`). The large
`corpus/` count is the corpus's own transitive lock re-resolving from the new rev — unavoidable when the
corpus input itself moves, and entirely inside its subtree.

## 2026-08-01 — DELIBERATE CORPUS REPIN (corpus only; the v1 oracle does NOT move)

**The cadence.** A deliberate repin, not a follows-main: the corpus pin advances to pick up the corpus-side
**emits/binds declaration class**, and it moves only by this recorded ruling. The `den-v1` oracle is
UNTOUCHED at `7f11ba14` — this bump is one-sided by construction.

| Pin | From | To |
| --- | --- | --- |
| `corpus` | `425f1d3b2fcc2c5547ee593a8cb74d5d61192626` | `0d74319dfb39e643f6865497268a2034422d74df` |
| `den-v1` | `7f11ba1494052fd3ac52c1342915bcb52ba08f07` | *(unchanged)* |

**Target verified, not assumed.** `git ls-remote https://github.com/sini/nix-config.git HEAD refs/heads/main`
returned `0d74319dfb39e643f6865497268a2034422d74df` for BOTH refs — the target is the live branch tip, so no
drift between the intent and the applied rev. Forward move confirmed:
`git merge-base --is-ancestor 425f1d3b 0d74319d` → exit 0.

### What the bump carries — 4 commits

- `0d74319d` den: declare emits codomains for the three remaining value-conditional policies
- `89db884b` den: declare value-conditional policy codomains (binds, suppresses)
- `af8de7cb` chore: disable razerdaemon auto-cpu oc — *not den-shape*
- `83d8253d` chore: update inputs — *not den-shape*

The two den commits are one class: policies whose codomain is **value-conditional** are restated from bare
functions (or `mkPolicy`, which has no field to declare on) into literal policy RECORDS
(`{ __isPolicy = true; emits = […]; binds = […]; fn = …; }`). The stated reason, in the corpus's own words, is
that a body fired at a sentinel takes the false branch and so **cannot surrender its codomain by firing** —
the declaration has to be stated rather than discovered. Affected: `homeAarch64-to-hm`
(`modules/den/classes/home-platform.nix`), `user-aspect-auto-include` and `primary-user-for-owner`
(`modules/den/defaults.nix`), `env-to-hosts` (`modules/den/policies/fleet.nix`).

### §2.6 census re-validation at the new corpus rev

Both revs were exported (`git archive`) and measured with the **same instrument in the same run**. Every
census is UNCHANGED; the only movement is the new declaration surface itself.

| Census | `425f1d3b` | `0d74319d` | Verdict |
| --- | --- | --- | --- |
| `.nix` files | 500 | 500 | unchanged |
| `batteries.forward` sites | 0 | 0 | unchanged (control `batteries.` → 13 / 13) |
| route sites (qualified + inherited) | 4 | 4 | unchanged — the `home-platform.nix` triple + the `devshell.nix` adapter-bearing route |
| `adaptArgs` sites | 1 | 1 | unchanged — `devshell.nix:21`, and that file is BYTE-IDENTICAL across the bump |
| `provides.` declarations | 0 | 0 | unchanged — the C4 corpus-dead claim HOLDS |
| tier-2 NTA forward consumer | none | none | OQ2 stays CLOSED |
| `microvm-guests` refs | 8 | 8 | unchanged |
| `__isPolicy` records | 0 | **5** | THE BUMP |
| `emits =` declarations | 0 | **3** | THE BUMP |
| `binds =` declarations | 1 | **2** | THE BUMP |

Negative control `zzzNotARealTokenXyz` → 0 at both revs on the same instrument, so the zeros above are real
absences rather than a predicate that could not match.

**Instrument correction worth recording.** A first pass counted route sites with `policy\.route` and got
**3**, contradicting this file's recorded 4. The predicate was blind, not the record: `devshell.nix` does
`inherit (den.lib.policy) route;` and then calls bare `route { … }`, which a `policy\.route` predicate
structurally cannot match. The spelling-union predicate reproduces this file's 4 at the old rev, which is
what validates it. `home-platform.nix`'s three route CALLS are unchanged in kind — still `path = [ ]` with no
`adaptArgs`, i.e. tier-1 static; only the surrounding policy WRAPPER became a record.

### Lock hygiene

Targeted update only (`nix flake lock --update-input corpus`). Checked **path-wise, not node-key-wise** (nix
renumbers suffixed node keys, which makes a key-keyed diff report spurious moves): resolving every root
input's closure to canonical paths gives **302 changed paths, all 302 under `corpus/`, ZERO outside**. The
five sibling root inputs — `den-v1`, `gen`, `nixpkgs`, `den-v2`, `home-manager` — resolve to byte-identical
locked revs before and after. The §4.4 invariant holds: `home-manager`'s `nixpkgs` is the follows PATH
`["nixpkgs"]`, which resolves through root to the top-level `nixpkgs` node (`nixpkgs_20`) — not to the
similarly-named `nixpkgs` node, which belongs to the corpus subtree.

### Suite outcomes

- **parity: 71/71, exit 0.** No movement.
- **ci: 2199/2219, exit 1, 20 non-pass** — the same parked set as the recorded baseline (2 `compat-*`,
  13 `den-pipe`, 5 `pipe-consume`), i.e. INVARIANT as required, since `ci/` consumes neither pin. The
  denominator moved (2040 → 2219) only because den-hoag HEAD has gained tests since the last bump; the
  red-set count is the control, and it is unchanged at 20.

### COVERAGE LIMIT — the parity green is not evidence about the corpus

**No parity test consumes the `corpus` specialArg.** `parity/flake.nix` passes `corpus = inputs.corpus`
into `specialArgs`, but a predicate for that binding across `parity/tests/` and `parity/ship-gate.nix`
returns ZERO, while the same predicate in the same run finds `harness` in 10 test files (the positive
control). Every `corpus` token in the suite is either prose or the SYNTHETIC `fakeCorpus` in
`parity-content.nix`. So the corpus input is fetched and locked but never read: the 71/71 above is a
genuine no-regression signal for the HARNESS, and says **nothing** about whether the shim handles the new
policy-record form. Under this repin the parity suite could not have gone red for a corpus reason.

The arm that would actually exercise the new `__isPolicy`/`emits`/`binds` records is the dev-time
full-fleet ship-gate (`runbook.md`) — the real nix-config corpus diff ∖ ledger — which does not run in
den-hoag's own CI. **That gate has NOT been run for this repin.** Whether the compat layer accepts a policy
record where it previously received a bare function is therefore OPEN, and is the natural follow-up.
