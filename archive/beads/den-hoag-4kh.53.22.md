# den-hoag-4kh.53.22 — [S8] gen-schema computes the kind-level graph and den-hoag strips it unread, then recomputes a subset with the quadratic unique

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.22` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:52Z by Jason Bowman |
| last updated | 2026-07-29T00:07:52Z |
| description bytes | 691 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S8] MEASURED. THE SUBSTRATE'S KIND-LEVEL GRAPH IS DELETED UNREAD.
gen-schema computes `edges = parentEdges ++ map (e: e // { type = "ref"; }) refEdges`,
described in its own source as "Unified edge view: parent (§ Neron 2015 P) + ref
(§ Neron 2015 I) edges". `_edges`, `_refEdges` and `_leaves` have ZERO READERS outside the
removal list.
★ Replaced by LIST ARITHMETIC OVER THE SIDECAR COPY, USING `prelude.unique` -- WHICH IS
QUADRATIC (see G20). So the substrate ships the answer, den-hoag deletes it, then
recomputes a subset of it by the slowest available primitive.
⇒ Sequence with S1/S3: the derived lists stop being derived once the substrate's own graph
is read instead of stripped.

## Comments (0)

(none)
