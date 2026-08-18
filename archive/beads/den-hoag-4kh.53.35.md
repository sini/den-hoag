# den-hoag-4kh.53.35 — [T1] den.lib.strict is parasitic — it enforces only when tied at equal priority, and three one-line changes silently disarm it

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.35` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:10:24Z by Jason Bowman |
| last updated | 2026-08-05T20:48:36Z |
| description bytes | 1376 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[T1] MEASURED. `den.lib.strict` IS PARASITIC. Its throw lives in `typeMerge`, NOT `merge`
(`compat/strict.nix`), and `mkOptionType` DEFAULTS THE OMITTED ONE to
`mergeDefaultOption`. ⇒ IT ENFORCES ONLY WHEN TIED AT EQUAL PRIORITY with another
plain-priority freeformType.
· ALONE: no-op.
· Beside gen-schema's `mkDefault` module: no-op (the mkDefault def loses stage-1 priority
  and is DISCARDED).
· Beside `registry.nix`'s plain freeform: ENFORCES.
★★ THREE ONE-LINE CHANGES SILENTLY DISARM IT, NONE OF WHICH WOULD ERROR: `mkDefault`-ing
`registry.nix`'s freeform, deleting it, or landing `den.lib.strict` anywhere it is the
SOLE freeformType.
★ AND T5(b): THE THREE DELETIONS ARE NOT INDEPENDENT -- the permissive freeform is
LOAD-BEARING; delete it and `den.lib.strict` is a no-op EVEN IF KEPT. Sequence them as
one change.
SUPPORTING MEASUREMENTS (do not re-derive): T2 -- the kernel is ALREADY UNIFORMLY STRICT
(`entity.nix` passes `{ }`, so `strict ? true` falls through; NO PER-KIND SWITCH IS IN USE
ON THE KERNEL PATH). T3 -- gen-schema's `mkStrictModule` is NOT A DROP-IN: priority
inversion (its module is `mkDefault`, DESIGNED TO YIELD, against a plain permissive
freeform -- swapping makes the strict module LOSE AND VANISH), type crossing (it builds a
gen-merge type; this is a nixpkgs evalModules -- the crossing the belt exists to prevent),
and message surface.

## Comments (0)

(none)
