# den-hoag-4kh.53.39 — [T8] stampFieldNamesByKind becomes the only thing between a corpus field and a strict rejection — and it has no test for the C-to-A crossing

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.39` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:10:25Z by Jason Bowman |
| last updated | 2026-07-29T00:10:25Z |
| description bytes | 803 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[T8] ARGUED. `stampFieldNamesByKind` BECOMES MORE LOAD-BEARING UNDER THE ALWAYS-ON RULING.
`ingest.nix` lifts C's OBSERVED FIELD NAMES into the schema as `raw`+`null` options, which
is what makes CORPUS FIELDS LEGAL AT THE STRICT KERNEL BOUNDARY *and* keeps them OUT OF
IDENTITY REFLECTION.
⇒ UNDER ALWAYS-ON STRICT IT IS THE ONLY THING STANDING BETWEEN A CORPUS FIELD AND A STRICT
REJECTION.
★ IT WANTS A TEST THAT A NEWLY-DECLARED CORPUS HOST FIELD SURVIVES THE C->A CROSSING.
There is no such test today, and the ruling makes its absence load-bearing.
Interacts with E2: identity is name-only IFF every non-`name` entity option stays
NON-PRIMITIVE. `stampFieldNamesByKind` lifting fields as `raw` is what preserves that --
so the test should assert BOTH properties, or the two invariants drift apart.

## Comments (0)

(none)
