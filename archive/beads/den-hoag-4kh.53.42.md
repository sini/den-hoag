# den-hoag-4kh.53.42 — [E3] INVARIANT TO GUARD: constructor C option-gating is what keeps freeform keys from crossing — and it is also A7 silent drop, so they are one question

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.42` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:11:19Z by Jason Bowman |
| last updated | 2026-08-05T20:48:38Z |
| description bytes | 584 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[E3] ARGUED. ★★ A SECOND INVARIANT TO STATE AND GUARD.
Constructor C's projection is OPTION-GATED (`registry.nix`, leaf branch on `isOption v`),
WHICH IS WHAT KEEPS FREEFORM-ABSORBED KEYS FROM CROSSING TO THE KERNEL.
★ THAT IS ALSO A7's SILENT DROP -- the same gate, seen as a defect from the other side.
⇒ E3 AND A7 ARE ONE DESIGN QUESTION: the projection must distinguish "absorbed and
DELIBERATELY not crossed" from "absorbed because the user MISSPELLED it". Fixing A7 by
removing the gate would delete this invariant; keeping the gate silently drops typos.
Neither alone is right.

## Comments (0)

(none)
