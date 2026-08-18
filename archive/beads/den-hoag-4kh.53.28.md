# den-hoag-4kh.53.28 — [A3] kind-level excludes was unimplemented not starved — and the current tree has moved, plus the subtree-scoping semantics are now ruled

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.28` |
| status at evacuation | open |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:09:40Z by Jason Bowman |
| last updated | 2026-07-29T00:09:40Z |
| description bytes | 1594 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[A3] MEASURED, AND ALREADY PARTLY OVERTAKEN -- see the reconcile bead.
As audited: kind-level `excludes` was UNIMPLEMENTED, not starved. Measured on the
mkDen-direct path where `rawForShim` is NOT involved: `includes` moves the module count
3 -> 4 (POSITIVE CONTROL); adding `excludes` LEAVES IT AT 4. It died at ingest on BOTH
paths -- `buildSchema` kept only `{ parent }`, `kindIncludesOf` lifted `.includes` alone,
and the `ing` record had no `kindExcludes`.
⇒ "FIXING `rawForShim` ALONE WOULD CHANGE NOTHING OBSERVABLE" -- which is why A2's
excludes half cannot be scoped without this one.
★ CURRENT TREE HAS MOVED: `kindExcludesOf` now exists at lib/compat/ingest.nix:243 and
lib/compat/compile.nix consumes `ing.kindExcludes`. RE-DERIVE BEFORE SCOPING.
★ AND THE SEMANTICS ARE NOW RULED, WHICH THE AUDIT DID NOT HAVE: den-hoag-9xo.28 was
amended by measurement -- `den.schema.<K>.excludes` is SUBTREE-SCOPED in den v1 (measured
with two positive controls, including a non-ancestor arm ruling out a merely global
reading), and the "excludes is includes' DUAL" justification was WITHDRAWN as the wrong
reason for a right answer. `includes` fires only at K-nodes; `excludes` reaches K AND ALL
DESCENDANTS. A flat per-kind list CANNOT represent it.
★ NOTE THE CORPUS SAFETY IS ACCIDENTAL: the corpus's single kind-level exclude is safe
ONLY because its TARGET was deliberately neutered (`builtins.nix` `host-to-users = _ctx:
[ ];`, comment "a genuine no-op").
POSTURE per 4kh.21: the ruling should cover `deps` and `provision` in ONE posture --
implement / refuse loudly / delete the surface.

## Comments (0)

(none)
