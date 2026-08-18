# den-hoag-4kh.53.15 — [N6] four hand-maintained strip-lists for __edges — three distinct sets, against a key den-hoag never writes and gen-scope never reads

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.15` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:04Z by Jason Bowman |
| last updated | 2026-07-29T00:07:04Z |
| description bytes | 1007 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[N6] MEASURED. FOUR NON-IDENTICAL STRIP-LISTS for a key NO REACHABLE PATH WRITES.
`__edges` is stripped at staged-resolution, collections, resolved-settings and structural
-- THREE DISTINCT SETS, hand-maintained. It is written only by `gen-scope.buildNodes`,
WHICH DEN-HOAG NEVER CALLS (0 hits; positive control found seven other `scope.*` entry
points in use, so the predicate was live).
★ AND THE CONVENTION IS WEAKER THAN IT LOOKS (§11): gen-scope HAS NO READER FOR IT
EITHER -- control confirmed gen-scope never reads `decls.<anything>` internally. So this
is a convention with a WRITER, NO READER, AND FOUR CONSUMERS GUARDING AGAINST IT.
⇒ Dissolves when N1 lands (den-hoag starts calling `buildNodes`, so the key becomes real
and one strip-list becomes correct) OR the convention is retired in gen-scope. Decide
which; do not leave four hand-maintained lists against a key nobody writes.
Also listed at X2 as an in-tree comment measured false ("the same `__`-key strip as attr 1"
-- the lists differ).

## Comments (0)

(none)
