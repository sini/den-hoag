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

- **Scope** — the corpus is the five `parity/fixtures/topologies.nix` topologies (plain host+user, quirk
  channel, class-fold, multi-host, spawn negative-control). The fuller synthetic set (isolated-guest,
  microvm, darwin, fleet-pipe-through-edge, host-aspects-spawn) and the real nix-config corpus arm are
  C8/C9, when the deliver surface can be witnessed on both arms.
