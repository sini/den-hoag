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
  + `microvm.guests` on hosts — native den-hoag, **not** a forward.

No `forward`-with-derived-children (NTA-spawning) consumer exists in the corpus. **Task 5's scope is
NOT widened; Tier-2 derived-children NTA remains NOT implemented** (the plan's default holds). If a
future corpus bump introduces such a consumer, re-open Open Question 2 here.

## Forward-tier summary (the input to Task 5's witness set)

- **Tier-1 static** (`path`, no `adaptArgs`) → plain `deliver`: the 3 `home-platform.nix` routes.
- **Adapter-bearing complex** (`adaptArgs` present) → `synthesize` record + `interpret.synthesize`:
  the hm delivery (osConfig adapter) and the `devshell` route (`config.allModuleArgs` adapter).
- **Tier-2 derived-children NTA** → NOT implemented: no corpus consumer (census above).
