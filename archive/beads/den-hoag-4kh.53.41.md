# den-hoag-4kh.53.41 — [E2] INVARIANT TO GUARD: identity is name-only only because every non-name entity option is non-primitive — one types.str re-keys every instance on one side

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.41` |
| status at evacuation | open |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:11:19Z by Jason Bowman |
| last updated | 2026-07-29T00:11:19Z |
| description bytes | 796 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[E2] ARGUED. ★★ AN INVARIANT TO STATE AND GUARD, currently held by accident.
`ingest.nix` credits the byte-identity of A and B to the shared `evalModuleTree` shape.
★ THE ACTUAL DECIDER IS THAT `mkIdentityModule` REFLECTS ONLY PRIMITIVE-TYPED OPTIONS
([ "string" "str" "int" "bool" ]). Identity is name-only IFF EVERY OTHER DECLARED OPTION
IS NON-PRIMITIVE -- true today ONLY because everything else is `raw`.
★★ INVARIANT: EVERY NON-`name` ENTITY OPTION STAYS NON-PRIMITIVE.
⇒ ONE `types.str` OPTION ADDED TO A KERNEL OR SHIM KIND SILENTLY RE-KEYS EVERY INSTANCE OF
THAT KIND, ON ONE SIDE ONLY. No error, no test, and the two views stop joining.
Pairs with T8: `stampFieldNamesByKind` lifting corpus fields as `raw` is what preserves
this. A test should assert both together or they drift apart.

## Comments (0)

(none)
