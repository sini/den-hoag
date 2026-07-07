# Parity deviation ledger (append-only)

Every cross-arm divergence the harness surfaces is classified here, never papered over (the plan's P1
rule). Classifications: **domain-boundary** (v1 folds class content as edges, den-hoag folds quirk
channels + demand + the deliver surface — disjoint until #44 / default-fold reconciliation),
**schema-alignment** (F1/F2 in `edge-schema.md` — id_hash or non-entity naming), **shim-defect** (a real
compilation bug the harness caught). The P6 gate (Task 9) will assert the live diff matches this ledger.

| id | date | fixture | firstDivergent.key (normalized) | classification | disposition | fixed-by |
| --- | ---------- | --------------- | ----------------------------------------------------------------------------------- | ---------------- | --------------------------------------------------------------------------- | -------- |
| L1 | 2026-07-07 | (all) | entity scope `<kind>:<id_hash>` — v1 `dd5c0a82…` ≠ hoag `8bba6f6a…` for `host:igloo` | schema-alignment | HANDLED — harness name-normalizes entity scopes to `<kind>:<name>` (F1) | oracle.nix |
| L2 | 2026-07-07 | (all, non-ent) | non-entity scope naming — v1 `mkScopeId` (`""`→`<root>`) vs hoag opaque | schema-alignment | HANDLED (seed) — `nonEntityNameMap`; completeness = first full-corpus (F2) | oracle.nix / OQ4 |
| L3 | 2026-07-07 | plainHostUser | `root:host:igloo/homeManager \|  \| collected:host:igloo/homeManager \| merge` | domain-boundary | v1 class-folds (6) absent on hoag (class content rides the class-module path)| #44 / reconcile |
| L4 | 2026-07-07 | quirkChannel | `root:host:igloo/feat \|  \| collected:host:igloo/feat \| merge` (EXTRA on hoag) | domain-boundary | hoag quirk-fold has no v1 counterpart (v1 folds quirk content into classes) | reconcile |
| L5 | 2026-07-07 | multiHost | `root:host:iceberg/homeManager \|  \| collected:host:iceberg/homeManager \| merge` | domain-boundary | two-host union of the L3 class-fold boundary (root enumeration correct) | #44 / reconcile |

## Notes

- **L1/L2 are HANDLED, not open** — the harness normalizes for them (F1 entity names, F2 non-entity map),
  so they do not appear in the live diff. They are recorded because the "entity scopes without
  translation" assumption in the plan was empirically false; the normalization is load-bearing.
- **L3–L5 are the domain boundary** — the expected, classified consequence of den v1 and den-hoag folding
  DIFFERENT things as graph edges (`edge-schema.md` "domain finding"). They are pinned in
  `parity/golden/traces.nix`; a REGRESSION that shifts them fails P1, and a CONVERGENCE (an edge that
  starts matching once #44 lands) also fails P1 and forces a deliberate re-golden + a ledger update here.
- **No shim-defect rows** — the C7 corpus surfaced no compilation bug; every divergence is the domain
  boundary (L3–L5) or a handled schema-alignment normalization (L1–L2).
- **Scope** — the C7 corpus is the four `parity/fixtures/topologies.nix` topologies (plain host+user,
  quirk channel, multi-host, spawn negative-control). The fuller synthetic set (isolated-guest, microvm,
  darwin, fleet-pipe-through-edge, host-aspects-spawn) and the real nix-config corpus arm are C8/C9, when
  the deliver surface can be witnessed on both arms.
