# Parity deviation ledger (append-only)

Every cross-arm divergence the harness surfaces is classified here, never papered over (the plan's P1
rule). Classifications: **domain-boundary** (v1 folds class content as edges, den-hoag folds quirk
channels + demand + the deliver surface — disjoint until #44 / default-fold reconciliation),
**schema-alignment** (F1/F2 in `edge-schema.md` — id_hash or non-entity naming), **shim-defect** (a real
compilation bug the harness caught). The P6 gate (Task 9) will assert the live diff matches this ledger.

| id | date | fixture | firstDivergent.key (normalized) | classification | disposition | fixed-by |
| --- | ---------- | --------------- | ----------------------------------------------------------------------------------- | ---------------- | --------------------------------------------------------------------------- | -------- |
| L1 | 2026-07-07 | (all) | entity scope `<kind>:<id_hash>` — v1 `dd5c0a82…` ≠ hoag `8bba6f6a…` for `host:igloo` (handled — no live key) | schema-alignment | HANDLED — harness name-normalizes entity scopes to `<kind>:<name>` (F1) | oracle.nix |
| L2 | 2026-07-07 | (all, non-ent) | non-entity scope naming — v1 `mkScopeId` (`""`→`<root>`) vs hoag opaque (handled — no live key) | schema-alignment | HANDLED (seed) — `nonEntityNameMap`; completeness = first full-corpus (F2) | oracle.nix / OQ4 |
| L3 | 2026-07-07 | plainHostUser | `root:host:igloo/homeManager \|  \| collected:host:igloo/homeManager \| merge` | domain-boundary | **R5+R3-CONVERGED (2026-07-09):** BOTH host-scoped edges match — the nixos fold (R5 self-named aspect) AND the os→host route (R3 ambient battery, formal-preserving canTake). matched 0→2, extra 0. Residual (4) = homeManager fold (unported battery) + 3 USER-scoped edges (v1 user-as-root vs hoag user-as-cell). See §L3/L5 notes. | R5+R3 (self-provide + os-class) |
| L4 | 2026-07-07 | quirkChannel | `root:host:igloo/feat \|  \| collected:host:igloo/feat \| merge` (EXTRA on hoag) | domain-boundary | hoag quirk-fold has no v1 counterpart (v1 folds quirk content into classes); the os→host route ALSO matches here now (matched 1) | reconcile |
| L5 | 2026-07-07 | multiHost | `root:host:iceberg/homeManager \|  \| collected:host:iceberg/homeManager \| merge` | domain-boundary | **R5+R3-CONVERGED (2026-07-09):** both hosts' nixos folds + os routes match; matched 0→4, extra 0. Two-host union of the L3 convergence; residual (8) = per-host homeManager fold ×2 + 6 user-scoped edges. See §L3/L5 notes. | R5+R3 (self-provide + os-class) |
| L6 | 2026-07-07 | classFold | `root:host:igloo/nixos \|  \| collected:host:igloo/nixos \| merge` (CONVERGED — now MATCHED) + 5 residual `missing` | domain-boundary | #44 / C7.5: class-content-as-fold-content landed. den-hoag's PRODUCING-class default fold byte-matches v1's nixos class fold (matched 0→1, extra 0). Residual missing = v1's `os` base class + os→nixos / hm→nixos (synthesize) / user→nixos routes + host homeManager default (v1's hierarchical multi-class model vs den-hoag flat one-class-per-scope). | output-modules.nix channelsOf/contentsOf |
| B1 | 2026-07-09 | (battery: define-user) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B2 | 2026-07-09 | (battery: flake-parts) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B3 | 2026-07-09 | (battery: flake-scope) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B4 | 2026-07-09 | (battery: hjem) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B5 | 2026-07-09 | (battery: host-aspects) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B6 | 2026-07-09 | (battery: hostname) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B7 | 2026-07-09 | (battery: import-tree) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B8 | 2026-07-09 | (battery: insecure) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B9 | 2026-07-09 | (battery: maid) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B10 | 2026-07-09 | (battery: primary-user) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B11 | 2026-07-09 | (battery: tty-autologin) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B12 | 2026-07-09 | (battery: unfree) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B13 | 2026-07-09 | (battery: user-shell) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B14 | 2026-07-09 | (battery: vm-autologin) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| B15 | 2026-07-09 | (battery: wsl) | — (non-ported, corpus-unexercised — no live diff) | intentional-v2-semantic | non-ported per §10 R6 corpus-relative scope; re-open if the corpus exercises this battery | C8/C9 |
| p | 2026-07-09 (fixed 2026-07-10) | (classless-host ingest) | ingest classless-host class vs v1's system derivation | bug-in-hoag → **FIXED** | **FIXED 2026-07-10.** In-corpus (most hosts declare no `class`; `patch` = darwin-by-system). v1 is NOT inert on classless hosts — it DERIVES class from system (`host.nix:65-66`, verified on the v1 arm: `igloo`→nixos, `patch`→darwin). The shim's `classOfHost` now reproduces v1's derivation exactly (`hasSuffix "darwin" system ? darwin : nixos`), for both contentClass + the stamped `class` field; explicit `host.class` (`slab`="droid") overrides. Witness `test-p-classless-class-from-system`. SUPERSEDES the review's null-default adjudication (a null default would leave darwin hosts unrouted). | ingest `classOfHost` (this commit) |
| q | 2026-07-10 | (corpus host `slab`) | `den.classes.droid` — a nix-on-droid output class the corpus declares (host `slab`) | intentional-v2-semantic (register at ship-gate) | The corpus uses a `droid` (nix-on-droid) host class — NOT a den-hoag built-in (nixos/darwin/home-manager/k8s-manifests), so an aspect keying it aborts at resolveBucket until registered. Register it the SAME way as darwin (a native output class + its terminal) OR via the declared-classes surface at the corpus arm; item-6 survey finding, not yet built (no synthetic fixture exercises it). | C9 ship-gate / native era |
| n | 2026-07-09 | plainHostUser, quirkChannel, classFold, multiHost | `root:user:<u>/…` (user-scoped os/user/hm-synthesize edges) **+** `root:host:<h>/homeManager \|  \| collected:host:<h>/homeManager \| merge` (v1's host-aggregated hm fold — absorbs former row o) | intentional-v2-semantic | **Law A15 (output-modules isolation): every non-root scope node is its OWN edge-root, so a (user,host) cell is a distinct edge-root from its host — this is a LAW of the v2 model, not a shrug.** v1 resolves a user as its OWN instantiation root (`resolve.to`) and aggregates home-manager at the HOST root; den v2 models a user as a CELL under its host and folds home-manager PER (user,host) CELL (`collected:user:<u>/home-manager`). So (i) the v1 user-scoped edges target a user root that has no v2 counterpart, and (ii) v1's host-scoped `collected:host:<h>/homeManager` fold IS the user-as-root model rendered as an edge — den v2 has no host hm aggregation (a battery port would fabricate a user-cell fold AND still miss the host fold — verified empirically). Each user's hm config instead reaches the host terminal via the C5 **synthesize forward** (`home-manager/users/<u>`). Deliberate scope-MODEL change, NOT a naming artifact — a formal classification, NOT an OQ4 `nonEntityNameMap` entry. Convergence NOT expected; this is the v2 semantics. **SCOPE: EDGE-TRACE (P1) family ONLY.** The P2 host-terminal drv-hash gate STILL asserts FULL content equality: the user's config lands in the SAME final system either way (different graph shape, byte-identical terminal content). **Explicitly for hm content: each user's home-manager config must land byte-identically in the host terminal (the C5 forward path) — P2 asserts it; a P2 divergence in hm content is a bug, never waived by this row.** Do not read residual-n as a content waiver. P6 family `residual-n`. | (v2 semantics — P1 only; P2 proves the content equal) |
| o | 2026-07-09 | plainHostUser, quirkChannel, classFold, multiHost | `root:host:<h>/homeManager \|  \| collected:host:<h>/homeManager \| merge` | intentional-v2-semantic | **RECLASSIFIED 2026-07-09 into `residual-n` (Law A15 scope-model — see row n).** Original read (unported hm battery → converge via a port) was WRONG: den v2 folds home-manager per (user,host) cell, NOT at the host, so no severable battery can emit this host fold — a port would fabricate a user-cell `collected:user:<u>/home-manager` EXTRA and still miss the host fold (empirically verified). This host fold is v1's user-as-root model as an edge; content reaches the host terminal via the C5 synthesize forward (P2 asserts it). P6 family `residual-n` (NOT a separate `residual-o`). | (v2 semantics — reclassified to residual-n; no convergence) |
| u1 | 2026-07-10 | (battery: unfree, PORTED — `den.batteries.unfree`; corpus antigravity.nix:8, fonts/regular.nix:5) | — (no live diff in the synthetic corpus; would surface as MISSING class-content edges if the corpus exercised unfree) | latent-v1-divergence | unfree (`den.batteries.unfree`; corpus antigravity.nix:8, fonts/regular.nix:5) never fires under the shim — its `__fn` requires a `class` coord den-hoag's enriched ctx does not inject (v1 binds `class = entityCls` per-class-resolution, `fx/resolve.nix:181` / `bind.nix:41`; den-hoag `forwardExpand` resolves per entity-node with no per-class `class`, so `callGated` gates it to `{ }`). Classification: **latent-v1-divergence**. Self-announcement: a class-A drvPath on an unfree-carrying host throws at nixpkgs eval (missing `allowUnfree` for the package), so the inert state CANNOT silently produce a wrong artifact — it fails LOUDLY at build depth. Resolution: PAIRED with the cluster-to-nixidy / ctx-coord survey (both are ctx/coord-injection questions); tracked as **board #55** ("Per-class include invocation for class-generic aspects — unfree class-coord; ctx-coord survey"). Pinned by `ci/tests/compat-batteries.nix` `test-unfree-class-coord-inert`. | **board #55** — two candidate resolutions the ctx-coord survey adjudicates: (1) den-hoag CORE per-class include invocation (bind a per-class `class` coord at resolution, v1-parity with `fx/resolve.nix:181`/`bind.nix:41`); OR (2) shim-side per-class EXPANSION of a class-generic include (emit one wrapped include per registered class with the `class` coord baked in) |

## Notes

- **L1/L2 are HANDLED, not open** — the harness normalizes for them (F1 entity names, F2 non-entity map),
  so they do not appear in the live diff. They are recorded because the "entity scopes without
  translation" assumption in the plan was empirically false; the normalization is load-bearing.

- **L3–L5 are the domain boundary** — the expected, classified consequence of den v1 and den-hoag folding
  DIFFERENT things as graph edges (`edge-schema.md` "domain finding"). They are pinned in
  `parity/golden/traces.nix`; a REGRESSION that shifts them fails P1, and a CONVERGENCE (an edge that
  starts matching once #44 lands) also fails P1 and forces a deliberate re-golden + a ledger update here.

- **L6 is the C7.5 CONVERGENCE (#44), the first `matched` row.** The `class-content-as-fold-content`
  mechanism (`output-modules.nix` — class buckets join the graph accessor's `channelsOf`/`contentsOf`)
  makes den-hoag's default fold emit `collected:scope/<producing-class> | merge`, byte-matching v1's class
  fold. WHY L3/L5 did NOT also converge: their fixtures declare NO class content that reaches den-hoag
  (den v1 injects `os`/`homeManager`/`nixos` defaults + a `host.name==key` self-provide-include that the
  shim does not reproduce, so den-hoag's class buckets there are EMPTY). L6 witnesses the mechanism where
  class content is EXPLICITLY included (`den.schema.host.includes`), so its host bucket is non-empty. Full
  L3/L5 convergence additionally needs the v1 default/self-provide injection + the os→nixos class-hierarchy
  routes — the C8/C9 default-fold reconciliation, NOT the C7.5 fold-visibility mechanism.

- **No shim-defect rows** — the C7 corpus surfaced no compilation bug; every divergence is the domain
  boundary (L3–L6) or a handled schema-alignment normalization (L1–L2).

- **§L3/L5-R5 convergence (2026-07-09, appended — the Task 7.5 default-fold reconciliation).** R5
  (self-named-aspect auto-include, spec §10; `lib/compat/legacy/self-provide.nix`) closes the FIRST half
  of the L3/L5 domain boundary WITHOUT rewriting the honest divergence note above. Mechanism: den v1's
  `resolve-entity.nix:48-63` auto-includes the aspect NAMED after an entity at that entity's own scope
  (the `den.aspects.<host>` per-host idiom). The shim reproduces it as a node-local `den.include` seed
  (severable, in `legacy/`), so host:igloo's nixos bucket is non-empty and its producing-class default
  fold emits `collected:host:igloo/nixos | merge` — BYTE-MATCHING v1. Result: L3 matched 0→1, L5 matched
  0→2, **extra stays 0** on both (the producing-class scoping never emits a phantom fold, the L6 guard).
  This is the same fold-visibility mechanism L6 witnessed via an explicit `schema.host.includes`; R5
  reaches it through the implicit self-name path the corpus actually uses. The residual `missing` edges
  (homeManager default fold, os→host routes R3, hm→nixos synthesize, user→nixos nest) are v1's fuller
  built-in radiation — R6 batteries + R3 routes materializing on the hoag arm — the C8/C9 content-oracle
  reconciliation, still classified domain-boundary here, not papered over. The P1 goldens
  (`parity/golden/traces.nix` plainHostUser/multiHost) are re-goldened to the converged state; the
  structural suite's `test-boundary-parity-false` stays green (both still carry residual `missing`).

- **§L3/L5 R3 os-route convergence (Task 8 M1, 2026-07-09, appended).** Building on the R5 nixos-fold
  convergence, the declared-classes core feature (assembly §2.2 — `config.den.classes.<name>` joins the
  registered-class set via `entity.discoverClasses`) + the v1-ambient battery auto-application (os-class /
  os-user apply on every fleet under the full flakeModule) + the host `class` entity field (so the R3 gate
  reads `host.class`) let the built-in **os-to-host route MATERIALIZE**: it byte-matches v1's
  `collected:host:<h>/os | merge` on every host. matched: plainHostUser 1→2, multiHost 2→4, classFold 1→2,
  quirkChannel 0→1. **extra stays 0** on every arm. The route is a FORMAL-PRESERVING canTake policy
  (`compile.nix` `compileCanTake`): a value-conditional emission (`host.class ∈ {nixos,darwin}`) is
  INVISIBLE to concern-policies' value-less stratum probe (it emits nothing → misclassifies as enrich →
  crashes on firing), so the route emits UNCONDITIONALLY given its `{ host, ... }` formals (canTake
  presence gate) and the v1 value-gate moves INTO the `intoClass` field — `intoClass = if elem (host.class or null) [nixos darwin] then host.class else null`, a null target being the `__dropped`
  inert arm. The elem gate is PRESERVED verbatim (a probe-safety transformation of the emission form,
  NOT a relaxation): route iff `host.class ∈ {nixos,darwin}`, inert otherwise, byte-for-byte v1. The REMAINING residual is now purely v1's USER-scoped
  edges (`root:user:<u>/…`) — v1 resolves a user as its OWN instantiation root (v1 `resolve.to`), den-hoag
  as a CELL under the host root, so the user-cell os/user routes DO fire but target the host root, not a
  user root — a scope-MODEL boundary (the C8/C9 spawn/user-root reconciliation) — plus v1's homeManager
  default fold (the home-manager battery, unported R6). NOT-flipped-and-why: those user-root edges are
  C8 oracle input, not a failure. darwin routing is deferred (the darwin OUTPUT class + terminal are
  unregistered until M2; a darwin host aborts LOUDLY at resolveBucket until then). The SYNTHETIC parity
  fixtures are nixos-only; the REAL nix-config corpus HAS darwin hosts (plan P2 "do not filter darwin"),
  so registering the darwin output class is MANDATORY M2 scope — re-verify the PIN.md host survey there.

- **B1–B15 non-ported batteries (§10 R6).** The v1 battery set at the frozen pin has 17 members; the
  compat shim ports only the two the corpus exercises (`os-class` → R2/R3, `os-user` → R2/R6, both in
  `lib/compat/legacy/batteries/`). The other 15 are NON-PORTED under R6's corpus-relative scope — no
  hallucinated content. Each is recorded as an `intentional-v2-semantic` row (B1–B15) so the P6 ship gate
  reads the full accounting from the ledger; the `nonPortedBatteries` Nix list in
  `lib/compat/legacy/defaults.nix` is the code-side cross-reference. A corpus bump that exercises one
  re-opens its port (flip its row to a live divergence + port the battery).

- **u1 vs B12 (unfree — two DIFFERENT surfaces, both recorded).** B12 is the LEGACY-FOLD battery
  (`lib/compat/legacy/batteries/`, the built-in defaults radiation) — non-ported under R6. Row `u1` is the
  distinct `den.batteries.unfree` USER-FACING surface, which IS ported (`lib/compat/batteries.nix`, faithful
  to the v1 pin) but resolves INERT because its `__fn` destructures a `class` coord den-hoag's
  enriched-context never binds (v1 injects it per-class-resolution; den-hoag resolves once per entity-node).
  So `callGated` gates it to `{ }`. This is `latent-v1-divergence`, NOT a shim defect: (a) it is a MISSING
  den-hoag capability (per-class include invocation, board #55), and (b) it SELF-ANNOUNCES — a class-A
  drvPath on an unfree-carrying host throws LOUDLY at nixpkgs eval (missing `allowUnfree`), so the inert
  state can never silently ship a wrong artifact. The inert state is PINNED by
  `ci/tests/compat-batteries.nix` `test-unfree-class-coord-inert` — a LOUD PIN: if den-hoag gains per-class
  `class` injection (#55 candidate 1) or the shim expands per-class (candidate 2), that test FLIPS and must
  be updated together with this row.

- **Scope** — the corpus is the five `parity/fixtures/topologies.nix` topologies (plain host+user, quirk
  channel, class-fold, multi-host, spawn negative-control). The fuller synthetic set (isolated-guest,
  microvm, darwin, fleet-pipe-through-edge, host-aspects-spawn) and the real nix-config corpus arm are
  C8/C9, when the deliver surface can be witnessed on both arms.

## Task 8 M2 — content oracle (P2/P8) + darwin native output class

- **darwin native output class (M2 mandatory-first, resolves the "darwin aborts until M2" note above).**
  `darwin` is now a BUILT-IN den-hoag output class (peer to `nixos`: `lib/default.nix` `classNames` +
  the `crossDarwin` terminal + the `darwinConfigurations` face + the `den.darwin` input). The legacy
  os-class elem-gate `[nixos darwin]` now ROUTES a darwin host (`osEdgeCount "darwin" = 1`,
  `ci/tests/compat-legacy-rules.nix`) instead of aborting at resolveBucket, and a native darwin fleet gets
  `darwinConfigurations` with zero compat surface (`ci/tests/darwin-class.nix`). gen-flake ships no
  `darwinSystem`, so `crossDarwin` calls nix-darwin's `lib.darwinSystem` DIRECTLY — the real crossing is
  exercised at the SHIP-GATE (a corpus with a `den.darwin` input), not in den-hoag's own CI (which uses the
  nixpkgs-free `collect` terminal). This is NOT a divergence — it is a native-class addition; recorded here
  for provenance.

- **P8 `coreGate` (class-share invisibility) — FULLY CI, no divergence.** `parity/tests/parity-class-share.nix`
  runs the §4.6 sub-gate over a shared-core corpus fixture: `allGated` (every member's share-ON artifact
  forces without abort — den-hoag's own `authorize`/A18 byte gate, the shipping authority), `traceEqual`
  (E_hoag byte-identical share on/off), `configInvariant` (config(root) byte-identical), plus the
  deliberately-corrupted-core loud-abort teeth. The fleet-path gate is the authority; the gateCore-digest
  mechanism is covered directly by `ci/tests/class-share-parity.nix` (Arm A). No `intentional-v2-semantic`
  row — class-share is a strategy, any observable diff is a bug-in-hoag.

- **P2 content oracle — CI / SHIP-GATE split (honest scope, not a divergence).** Two arms, per §4.4:
  (1) the CROSS-PIPELINE hoag-materialized content hash (`parity/tests/parity-content.nix`, the two
  mandatory synthetics fleet-pipe-through-edge + host-aspects-spawn) is pinned as a CI regression baseline;
  (2) the v1-materialized side and the FLEET drv-hash gate (`contentGate`) are the SHIP-GATE arm.
  **Finding (why the v1 content arm is ship-gate, not CI):** forcing the v1 arm's materialized content
  (`resolveWithPaths class root → .imports`, folded) triggers the v1 home-manager battery `getModule`, which
  reaches `inputs.home-manager."${host.class}Modules"` — a CORPUS input the parity harness deliberately does
  NOT carry (spec §4.4: "both evaluations pin identical inputs (nixpkgs, home-manager, all corpus inputs)").
  So the v1-vs-hoag content differential + the toplevel drv-hash require the full corpus input set and cross
  nixpkgs/nix-darwin — the one arm that "cannot run purely in den-hoag's own CI" (spec §7.3 / plan Task 8).
  `crossPipelineRecords` computes both arms but Nix laziness keeps `.v1Hash`/`.equal` unforced in CI; the
  `contentGate` mechanism is exercised structurally on a synthetic drvPath corpus. The full v1-vs-hoag run
  is the dev-time ship-gate against the real nix-config corpus. A synthetic v1-vs-hoag content divergence is
  a P2 ledger finding there, classified like the structural suite's matched/extra/missing.

- **Pinned item (p) — classless-host class derivation (IN-CORPUS; FIXED 2026-07-10).** CORRECTED: this is
  NOT out-of-corpus. The earlier note ("every corpus host declares an explicit class") was WRONG — the
  item-6 survey found most corpus hosts declare NO `class` field, carrying it via `system` (e.g. `patch` =
  aarch64-darwin). And v1 is NOT inert on a classless host: verified on the v1 arm, v1 DERIVES the class
  from the system (`nix/lib/entities/host.nix:65-66`: `host.class or (hasSuffix "darwin" system ? "darwin" : "nixos")`) — `igloo` → nixos, `patch` → darwin — so its os route fires. The original `h.class or "nixos"` default would have MISCLASSIFIED `patch` (darwin) as nixos. FIX (this commit): `lib/compat/ ingest.nix` `classOfHost` reproduces v1's derivation EXACTLY, for both the host's own contentClass and
  the stamped `class` field; an explicit `host.class` (corpus `slab` = "droid") still overrides. Witness:
  `ci/tests/compat-legacy-rules.nix` `test-p-classless-class-from-system` (classless linux → nixos routes,
  classless darwin → darwin routes). This SUPERSEDES the review's null-default adjudication — a null default
  would leave darwin hosts unrouted; the parity-correct behavior is v1's system derivation. Row `p`
  classification: `bug-in-hoag` → FIXED.
