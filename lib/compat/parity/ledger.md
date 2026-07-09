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
| L3 | 2026-07-07 | plainHostUser | `root:host:igloo/homeManager \|  \| collected:host:igloo/homeManager \| merge` | domain-boundary | **R5-CONVERGED (2026-07-09):** the nixos class fold now MATCHES (self-named aspect auto-included, spec §10 R5); matched 0→1, extra 0. firstDivergent moved to the homeManager fold. Residual (5) = the C8/C9 default-fold + forward reconciliation. See §L3/L5-R5 note. | R5 (self-provide) |
| L4 | 2026-07-07 | quirkChannel | `root:host:igloo/feat \|  \| collected:host:igloo/feat \| merge` (EXTRA on hoag) | domain-boundary | hoag quirk-fold has no v1 counterpart (v1 folds quirk content into classes) | reconcile |
| L5 | 2026-07-07 | multiHost | `root:host:iceberg/homeManager \|  \| collected:host:iceberg/homeManager \| merge` | domain-boundary | **R5-CONVERGED (2026-07-09):** both hosts' nixos class folds now MATCH (self-named aspects, R5); matched 0→2, extra 0. Two-host union of the L3 convergence; residual = per-host L3 residual ×2. See §L3/L5-R5 note. | R5 (self-provide) |
| L6 | 2026-07-07 | classFold | `root:host:igloo/nixos \|  \| collected:host:igloo/nixos \| merge` (CONVERGED — now MATCHED) + 5 residual `missing` | domain-boundary | #44 / C7.5: class-content-as-fold-content landed. den-hoag's PRODUCING-class default fold byte-matches v1's nixos class fold (matched 0→1, extra 0). Residual missing = v1's `os` base class + os→nixos / hm→nixos (synthesize) / user→nixos routes + host homeManager default (v1's hierarchical multi-class model vs den-hoag flat one-class-per-scope). | output-modules.nix channelsOf/contentsOf |

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

- **Scope** — the corpus is the five `parity/fixtures/topologies.nix` topologies (plain host+user, quirk
  channel, class-fold, multi-host, spawn negative-control). The fuller synthetic set (isolated-guest,
  microvm, darwin, fleet-pipe-through-edge, host-aspects-spawn) and the real nix-config corpus arm are
  C8/C9, when the deliver surface can be witnessed on both arms.
