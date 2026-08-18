# den-hoag-4kh.53.14 — [N5] [gen-scope] EXTEND: no single-node constructor, so every NTA spawn body re-derives the node shape by convention

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.14` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:04Z by Jason Bowman |
| last updated | 2026-07-29T00:07:04Z |
| description bytes | 515 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[N5] ARGUED. NO SINGLE-NODE CONSTRUCTOR for NTA spawn bodies.
Cells are minted inside a `resolve.nta` spawn, and gen-scope exports NO WAY TO MAKE ONE
NODE -- `buildNodes` is whole-graph only. ⇒ EVERY NTA BODY IN EVERY CONSUMER re-derives
the four-field shape by convention. den-hoag's two constructors agree ONLY BECAUSE
SOMEONE KEEPS THEM IN SYNC (which is N3's three-shapes drift, from the other side).
RESOLUTION -- EXTEND gen-scope: export a single-node constructor, or admit `buildNodes`
on a one-vertex graph.

## Comments (0)

(none)
