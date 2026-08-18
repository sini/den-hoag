# den-hoag-4kh.53.2 — [compat] rawForShim collapses absent-parent to null and drops isolated/excludes/collisionPolicy — 5 of 13 templates and 15 of 19 external configs carry the trigger, and the isolation guard cannot fire on the bridge path

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.2` |
| status at evacuation | deferred |
| priority | P0 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:04:59Z by Jason Bowman |
| last updated | 2026-08-05T20:48:35Z |
| description bytes | 3006 |
| notes bytes | 810 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ LIVE, MEASURED, USER-FACING. Two defects in ONE expression, both stated intent
silently discarded. den-hoag-4kh.53 §4 items A1 and A2.

THE EXPRESSION -- lib/compat/bridge.nix, the `rawForShim` binding:
    rawForShim = builtins.mapAttrs (_: kv: {
      parent = kv.parent or null; includes = kv.includes or [ ];
    }) perKind;
VERIFIED STILL PRESENT in the current working tree.

★ A1 -- IT COLLAPSES ABSENT-PARENT INTO `parent = null`, AND DEFEATS BOTH
COMPENSATIONS WRITTEN AGAINST THE ABSENT SHAPE.
Both compensations are `//` merges keyed on ABSENCE: ingest.nix:171 (`declared ? user`
becomes TRUE once the key exists) and legacy/defaults.nix:73 (`builtinDefault //
existing`, where `existing.parent = null` SHADOWS "host"). ★ The second was written FOR
THIS HAZARD and its own comment says so.
MEASURED end to end on the real `default` den template with a one-line control arm:
`user.parent` null vs "host" gives scope node `user:tux` (a ROOT) versus
`user:tux@host:igloo` (a CELL). A user becomes a root scope instead of a cell.
★ TRIGGER IS NOT `flakeModules.strict` -- ANY consumer writing `den.schema.user.<x>`
without an explicit parent. `den.schema.user.includes = [ ]` ALONE IS ENOUGH.
★ BLAST RADIUS, MEASURED: the shape is present in 5 OF 13 den templates and 15 OF 19
external configs; ZERO of the 20 declare a parent. nix-config is immune SOLELY because
of modules/den/schema/topology.nix:7. So the one fleet that evaluates is the one fleet
that cannot show this.
RESOLUTION STATED: the `or null` is DEAD CODE -- gen-schema declares `parent` as a
collection with `default = null` and merges it into every kind record before the bridge
sees it. The fix must read the RAW DEFS, which the same file already does twelve lines
earlier (`rawFieldOf` tests `? ${field}`). `parent` additionally needs to be OMITTED
when no def declares it.

★ A2 -- THE SAME PROJECTION CARRIES EXACTLY TWO KEYS, SO `isolated`, `excludes` AND
`collisionPolicy` ARE DROPPED ENTIRELY.
Consequence: ingest.nix:222's isolation guard CANNOT FIRE ON THE BRIDGE PATH -- and
that guard's own comment calls the failure it prevents "a WRONG drv, not a crash -- the
worst failure mode."
MEASURED with control: direct_isolated_aborts TRUE, direct_plain_aborts FALSE (the
control), bridge_isolated_aborts FALSE.
★ The guard explicitly anticipates `buildSchema` stripping the flag DOWNSTREAM and
misses `rawForShim` stripping it UPSTREAM. A guard written against the wrong stage.

★ RECONCILIATION OWED BEFORE SCOPING (see the reconcile bead): `kindExcludesOf` now
exists at ingest.nix:243 and compile.nix consumes `ing.kindExcludes`, so the `excludes`
half of A2 may already route differently. A1 and the `isolated`/`collisionPolicy` halves
are unaffected by that work.

WHY THIS IS FILED P0 WHILE MOST OF THE INVENTORY IS NOT: it is MEASURED, it is LIVE on
the majority of the corpus, its trigger is a single ordinary line a user would write
without thinking, and its symptom is a silently WRONG graph rather than an error.

## Notes



★ PREMISE INVALIDATED BY THE RECONCILIATION (den-hoag-4kh.53.1, closed). The audit's A3
finding -- that kind-level `excludes` has NO downstream consumer, so "fixing rawForShim
alone would change nothing observable" -- IS STALE. Measured at e6c8edc with a four-arm
probe and a positive control: `excludes` moves `selects` from [ "host" ] to [ ], and
the effect is visible in materialized resolved-aspects.
⇒ A `rawForShim` FIX COULD NOW BE OBSERVABLE. RE-SCOPE THIS BEAD rather than inheriting
the audit's framing: the `excludes` half of A2 now has a live consumer, so dropping it at
the bridge is a real loss rather than a no-op feeding a dead end.
★ A1 ITSELF IS UNCHANGED and the bead's description stands: `rawForShim` is at
bridge.nix:609 and `git diff c42df53 e6c8edc -- lib/compat/bridge.nix` is EMPTY.

## Comments (0)

(none)
