# The frozen parity edge schema — version 1

> The "version 1" in this heading is the SAME number as `schema.nix`'s `version = 1` — one version
> tracked in two places. Any bump changes BOTH (and adds a `ledger.md` entry); see "Version-bump
> discipline" below.

The whole structural oracle is one string: the frozen **`T | P | S | M` sort key**. gen-edge deliberately
froze den v1's `edgeSortKey` byte-for-byte (`gen-edge/lib/core.nix` — "the FROZEN trace sort key, v1 byte
contract"; den v1 `nix/lib/aspects/fx/edges/edge.nix` `edgeSortKey`), so both harness arms render into the
**same** string and the harness diffs on strings alone (`schema.nix` `keyOf = e: e.__sortKey`). This file
is that schema, versioned. `assertEdgeParity` refuses to diff traces tagged with a different `version`; a
change here is a **version bump + a ledger entry** (`ledger.md`).

## The record (§4.1)

A structured trace entry (gen-edge `traceEntryOf`; den v1 carries the raw edge record) is identity-only —
it renders names/keys and never forces resolved content:

```
{ target; path; mode; source; annotations; }
  target (T)  root:  { root = <scope>; class; }      | output: { output = <attrpath>; }
  path   (P)  attrpath   ([] = a merge at the root)
  mode   (M)  "merge" | "nest" | "nest-verbatim"
  source (S)  collected  { scope; class; members }    (default fold / delivery collection)
              rewalk     { aspect; bindings; class }   (v1 spawn re-walk — legacy trace only)
              synthesize { forwardId; fromClass; intoClass }  (adapter-bearing forward)
              value      { key }                        (gen-edge direct value)
```

## The sort key (§4.4 — the diff identity)

```
edgeSortKey e = targetKey e.target | pathKey e.path | sourceKey e.source | e.mode
  targetKey  root  → "root:" + <scope> + "/" + class
             output→ "out:"  + concatStringsSep "." output
  pathKey          → concatStringsSep "/" path
  sourceKey  collected  → "collected:" + <scope> + "/" + class
             rewalk     → "rewalk:" + aspect + "/" + concatStringsSep "+" bindings + "/" + class
             synthesize → "synthesize:" + forwardId + "/" + fromClass + ">" + intoClass   (or "synthesize:" + key)
             value      → "value:" + (key ? key : "_")
```

den v1's `sourceKey` synthesize arm is `forwardId/fromClass>intoClass` (no `key` variant) and has no
`value` arm; gen-edge adds the `key`/`value` arms. The two render **byte-identically for every shared
arm** — so each arm renders with ITS OWN `edgeSortKey` (the record shapes differ: v1 `synthesize = { … }`
vs gen-edge `synthesize.spec = { … }`) and the strings still align.

## Scope naming (§4.4) — and the two schema-alignment findings

The spec's intent was: entity scopes → `"<kind>:<id_hash>"` (parent-blind), non-entity scopes → the
`mkScopeId` string, **on both arms without translation**. The first corpus run (C7) disproved the
"without translation" half and pinned two findings the harness must handle. Both are recorded in
`ledger.md`; the harness normalizes for them in `oracle.nix`.

### F1 — entity id_hash divergence (was assumed absent)

den v1 and gen-schema stamp **different** id_hashes for the same `(kind, name)`:

| entity | den v1 id_hash | den-hoag id_hash |
| ------------- | --------------------- | --------------------- |
| `host:igloo` | `dd5c0a82…cac5a6c9` | `8bba6f6a…ed41103b` |
| `user:tux` | `77e2754f…849e1ac8` | `3edff5b0…bf19b81f` |

So entity scopes **cannot** be diffed on raw id_hash. The harness name-normalizes entity scopes to
`"<kind>:<name>"` on **both** arms before rendering — exactly what den v1's own `delivery-edges` suite
does (`normalizeTrace`, `edge-trace.nix`). Names are stable across both id_hash conventions, so the diff
is meaningful. (This is a HARNESS normalization, not a schema change: the frozen string format is
untouched; only the scope token content is mapped id_hash → name.)

### F2 — non-entity scope naming (Open Question 4)

den v1 names non-entity scopes by its `mkScopeId` string (`""` → `"<root>"`, `system=…`); den-hoag by an
opaque node string. `oracle.nix` `nonEntityNameMap` translates the hoag arm's non-entity strings into
v1's `mkScopeId` form. Seeded minimal (`"" → "<root>"`); its completeness is only provable against the
first FULL-corpus run, so a residual mismatch surfaces as a first-corpus diff and enters `ledger.md` — an
inherent property of the differential method, not a harness gap.

## The domain finding (why cross-arm parity is non-empty at C7)

den v1's `edgeTrace` and den-hoag's `graph.edges` are **largely disjoint edge domains**:

- **den v1** folds **class content** (nixos / homeManager / os / user) as edges, plus routes, forwards,
  spawn and instantiate edges.
- **den-hoag** folds **quirk channels** (+ demand + the explicit `deliver`/`route`/`provide` surface) as
  edges, and delivers class content through the class-module / output path — NOT as graph edges.

So on a plain host+user, v1 renders 6 class-fold/route/forward edges and hoag renders none; on a
quirk-channel fixture, hoag renders the `collected:host/feat` fold that v1 has no counterpart for. The
shared vocabulary is the explicit `deliver` surface, but it is called via **different lib handles** on
each arm (`denCompat.deliver` vs `den.lib.policy.deliver`), so a single static declaration set cannot
witness it on both. Convergence toward parity is gated on the deliver-materialization completion (den-hoag
task #44 / C7.5) plus a default-fold-model reconciliation — tracked as ledger findings, tightened as the
goldens shrink. This is the intended C7 outcome: the harness SURFACES the boundary precisely; it does not
paper it over.

## Version-bump discipline

Bump `version` in `schema.nix` (and this header) only when the record shape, the sort-key format, or the
scope-naming rule changes. Every bump requires a `ledger.md` entry and a regenerated `golden/traces.nix`.
Adding a fixture, or a name-map entry (F2), is NOT a schema change.
