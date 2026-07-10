# Migrating from den v1 to den v2

den v2 (den-hoag) is a ground-up re-implementation of den's four-concern model on the gen substrate. The
**den-compat shim** is the bridge: your existing den v1 configuration evaluates unchanged through it, so you
migrate on your own schedule — one concern at a time — with a parity harness proving each step keeps the
fleet byte-identical.

## The bridge release: bump the input, keep the config

The shim (`den-hoag.compat`) accepts the den v1 surface verbatim: `den.hosts`, `den.aspects`, `den.policies`,
`den.classes`, `den.quirks`, `den.schema`, `den.default`, and the legacy `provides`/`forwards`/battery
surfaces. Point your flake at den v2 + the shim, and your fleet builds as before. This is the community
bridge release — nothing in your config changes on day one.

The parity harness is the trust conversion: "trust the v2 rewrite" becomes "diff two edge lists and two
derivation hashes." Your fleet is the first migration AND the standing corpus — every migration step must
keep the parity gates green (P1 edge trace, P2 drv-hash), so a step that shifts your fleet's output is caught
immediately.

## Migrate concern-by-concern (the §2.2 compile mapping is the table)

The shim's compile mapping (`lib/compat/compile.nix`) doubles as the migration table — it is exactly how each
v1 surface re-expresses as a v2 concern:

| den v1 surface | den v2 (native) concern |
| --- | --- |
| `den.hosts` / `den.homes` / `den.schema.<kind>` | entities — flat registries + the containment schema |
| `den.aspects.<name>` (class keys, `includes`, `neededBy`, `settings`) | aspects — behavior; class keys are class-content buckets, quirk keys are channel contributions |
| `den.classes.<name>` (`wrap`/`instantiate`/`share`) | classes — systems; the output-class registry |
| `den.quirks.<name>` + `pipe.from` stages | quirks/attributes — data; gen-pipe channels + the operator DAG |
| `den.policies.<name>` (`for`/`when`/`resolve`/`include`/`exclude`) | policies — relationships; predicate-gated declaration rules |
| `den.default` | the `__default` aspect + a radiation policy |

Migrate a concern by rewriting its v1 surface into the native v2 vocabulary (the table row), one at a time,
re-running the parity gates after each. Because the native form and the compiled-shim form materialize to the
same edges + content, each step is a no-op to your fleet's output — the gates prove it.

## `provides` / `forwards` migrate LAST

`provides` and `forwards` are legacy — den v2 has no native equivalent (policies define relationships,
quirks describe data; the string-keyed `provides`/`forwards` grammar is retired in favor of registry-entry
relationships). They ship in the shim as self-contained, severable legacy modules (`lib/compat/legacy/`),
tagged and removable without touching the rest. Migrate them last: restate each in concern vocabulary — a
`provide` becomes an aspect delivered by a policy to the target's scope; a `forward` becomes an explicit
`deliver`/`route` relationship. The legacy modules' own desugar (`legacy/provides.nix`, `legacy/forwards.nix`)
shows the exact target shape.

## Deprecation policy — on evidence, per module

A legacy surface or compat behavior is deprecated only on evidence, per module:

1. **The fleet corpus no longer exercises it** — the parity corpus (your migrated fleet + the synthetic set)
   has no remaining consumer.
1. **No known community consumer** — the surface is not in use downstream (the census that drove which
   batteries were ported in the first place).
1. **A warning for ≥ one minor release** — a deprecation warning ships at least one minor release before
   removal, so consumers have a migration window.

Only when all three hold is the module removed. The shim never ships a runtime dependency on den v1 — the
frozen v1 pin is dev-time (the parity harness) only.

## Running the parity gates during migration

See `lib/compat/parity/runbook.md`. In short: after each migration step, `ulimit -s unlimited` then
`nix-unit --flake ./parity#tests` (the whole harness) — the P1 edge-trace + P2 content gates must stay green,
and the P6 ship gate (`parity-ledger-gate`) requires every remaining divergence to be classified in
`ledger.md`. The full-fleet drv-hash gate runs dev-time against your real corpus (the ship-gate arm).
