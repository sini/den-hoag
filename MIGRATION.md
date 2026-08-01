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

## BREAKING: an aspect may not be NAMED after a class

This is the one rename den v2 requires of a v1 config, and it is a genuine breaking change rather than a
cleanup. If you hit it, the shim says so by name:

```
den-compat: reserved class name (C1): `den.aspects.virtualization.microvm` is included as an aspect at
`den.aspects.cortex.includes[17]`, but `microvm` names a declared class …
```

**What it means.** A class name is RESERVED in the aspect tree. An aspect key whose leaf spells a registered
class — `den.aspects.<anything>.<class>` — is that class's CONTENT, not a nested aspect, and it is so by name
alone: no inspection of what you put inside it. So `den.aspects.virtualization.microvm` declares microvm
class content on the `virtualization` aspect, even when you wrote it intending a role named `microvm`.

**Why the shim refuses instead of guessing.** den v1 classified an aspect's keys only when that aspect was
RESOLVED, so a key like this stayed unclassified — and therefore harmless — as long as nothing included its
parent. den v2 classifies EAGERLY, by name, at declaration: a name's meaning no longer depends on which
aspects a given host happens to pull in. The consequence is that `with den.aspects; [ virtualization.microvm ]`
navigates to a class-content module — a `{ imports = [ … ]; }` bucket with no aspect identity — and an
`includes` list needs an aspect. Accepting the bucket anyway would re-type its contents as host module
config and silently drop any quirk channels it emitted, so the shim refuses at the declaration, naming both
the aspect path and the class it collides with.

**The remedy is a rename**, and it is mechanical: give the aspect a name no class holds. Reference config
`nix-config` took exactly this route in commit `fddab954` — `den.aspects.virtualization.microvm` became
`virtualization.microvm-host` (the `den.classes.microvm` registration is untouched), with the matching edits
at the aspect's other attrpaths and at the one host that included it. The suffix is a convention, not a
requirement; any non-class name works. If the key really is class content, include its OWNING aspect
(`den.aspects.virtualization`) rather than the key, or drop the `den.classes.<name>` registration if that
class was never wanted.

**Where to look in your own config.** Grep your `den.classes` registrations, then grep `den.aspects` for the
same names as leaf keys. Remember that the registered class set is larger than what you declare yourself: it
includes den's built-in classes and the v1 battery classes the shim provisions (`wsl`, `maid`, `hjem`,
`flake-parts`, `os`, `user`, …), so a config that never writes `den.classes` at all can still collide. Two
sites of this shape are already known across the wider den config corpus — an aspect keyed `aliases` beside a
declared `den.classes.aliases`, and one keyed `wsl` beside the built-in WSL battery class.

## Value-conditional policies declare their codomain (`binds`, `suppresses`)

Bare-lambda policies remain the normal form — nothing changes for most configs. The shim discovers what a
v1 policy emits by firing its body once against a probe entry, and for an unconditional body that recovery
is complete. But a body that gates its emissions on a real entity value — say, on the host's environment
matching —

```nix
den.policies.env-to-hosts = { environment, ... }:
  # emissions guarded by: hostCfg.environment == environment.name
```

takes the false branch at the probe (the probe entry matches nothing real), so the shim observes an empty
codomain. The policy's first real emission is then refused, by name:

```
den-hoag: binding codomain: policy 'env-to-hosts' emitted a 'member' binding 'accessGroups',
which is not in its declared 'binds' = [ ]
```

**Why the shim refuses instead of guessing.** The codomain is not just a check — it feeds the schedule.
A declared `binds` becomes a positive dependency edge in the stratification that orders policy evaluation
(a policy binding `accessGroups` must run before one whose formals destructure it). Firing the body in real
context to observe the emission is circular — the schedule produces that context. And a shim-side table of
known policy names is the one mechanism measured to drift: the `emits` table gained its darwin entry only
after the linux-only entry left darwin hosts silently unrouted, then missed the third sibling the same way.
Admitting the emission unchecked would trade a named refusal for a silent drop.

**The remedy is one field, and it is valid v1 today.** Give the policy the record form and state the fact
only its author knows:

```nix
den.policies.env-to-hosts = {
  __isPolicy = true;
  binds = [ "accessGroups" ];   # or `suppresses = [ ... ]` for a value-conditional excluder
  fn = { environment, ... }: ...;
};
```

den v1 accepts this form as-is — its policy type checks `__isPolicy`, its merge preserves the extra field,
and dispatch reads only `.fn` — so the declaration can land **before** the pin bump, byte-inert under v1.
Reference config `nix-config` took exactly this route in commit `43c48473`, declaring `binds` on its
environment-gated member policy and `suppresses` on its droid-conditional excluder.

**Where to look in your own config.** Only emitting policies whose bodies guard emissions on entity values
need this — a `resolve`/`include` that fires unconditionally recovers fine. You do not need to find them in
advance: the refusal names the policy, the field, and the missing key, and each is a one-field remedy at the
named site.

## `provides` / `forwards` migrate LAST

`provides` and `forwards` are legacy — den v2 has no native equivalent (policies define relationships,
quirks describe data; the string-keyed `provides`/`forwards` grammar is retired in favor of registry-entry
relationships). They ship in the shim as self-contained, severable legacy modules (`lib/compat/legacy/`),
tagged and removable without touching the rest. Migrate them last: restate each in concern vocabulary — a
`provide` becomes an aspect delivered by a policy to the target's scope; a `forward` becomes an explicit
`deliver`/`route` relationship. The legacy modules' own desugar (`legacy/provides.nix`, `legacy/forwards.nix`)
shows the exact target shape.

## Users, accounts, and home-manager: the native model

den v1 resolves each user as its own instantiation root and AGGREGATES home-manager at the HOST — so a v1
edge trace shows a host-scoped `collected:host:<h>/homeManager` fold. den v2 models a user as a first-class
CELL under its host (Law A15: every non-root scope node is its own edge-root), and folds home-manager PER
(user, host) CELL — `collected:user:<u>/home-manager`. So when you migrate and inspect edge traces, you WILL
see the host-scoped home-manager fold DISAPPEAR and a per-cell fold APPEAR. **This is intentional** — not a
regression.

You are migrating TO a decided destination model, not merely away from v1's shape — see the den-hoag native
user/host integration model (spec `2026-07-10-den-hoag-user-host-integration-model.md`, decisions D1–D6). In
that model a **user** is a decoupled registry identity — a root kind bound to hosts by MEMBERSHIP, not
parented under a host; the **(user, host) cell** is the localized ACCOUNT, a child of the host under B4a
containment, whose `users.users.<name>` config is derived from that binding; and **home-manager is a nixos
INTEGRATION module** — one consumer of the account (hjem, nix-darwin, and standalone home are siblings), NOT
a scope model of its own. Backwards compatibility is load-bearing: the `home-manager` class and existing
`contentClass` keys keep working through the shim, and an opt-in auto-registry from `host.users` is a planned
convenience. `den.homes` is the SAME cell model with a hostless binding (a standalone home).

The CONTENT guarantee is unchanged: each user's home-manager configuration still lands byte-identically in
the final host system. den v2 delivers it via the compat forward (`home-manager/users/<u>`), exactly where v1
merged the user-root instantiation. The P2 drv-hash gate asserts this — a home-manager content divergence at
the host terminal is a real bug, never waived by the scope-model reclassification. So: the graph SHAPE
changes (host fold → cell fold), the delivered SYSTEM does not.

## Deprecation policy — on evidence, per module

A legacy surface or compat behavior is deprecated only on evidence, per module:

1. **The fleet corpus no longer exercises it** — the parity corpus (your migrated fleet + the synthetic set)
   has no remaining consumer.
2. **No known community consumer** — the surface is not in use downstream (the census that drove which
   batteries were ported in the first place).
3. **A warning for ≥ one minor release** — a deprecation warning ships at least one minor release before
   removal, so consumers have a migration window.

Only when all three hold is the module removed. The shim never ships a runtime dependency on den v1 — the
frozen v1 pin is dev-time (the parity harness) only.

## Running the parity gates during migration

See `lib/compat/parity/runbook.md`. In short: after each migration step run
`nix-unit --flake ./parity#tests` (the whole harness) — the P1 edge-trace + P2 content gates must stay green,
and the P6 ship gate (`parity-ledger-gate`) requires every remaining divergence to be classified in
`ledger.md`. The synthetic harness runs within the default 8 MB stack. The full-fleet drv-hash gate runs
dev-time against your real corpus (the ship-gate arm); evaluating an entire live NixOS fleet is genuinely
deep, so raise the stack (`ulimit -s unlimited`) for that arm only.
