# den-hoag-4kh.8 — SPIKE (user-guided): does the alternate graph API belong in den-hoag or gen?

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.8` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:24:58Z by Jason Bowman |
| last updated | 2026-07-27T20:24:58Z |
| description bytes | 1295 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

NEEDS A USER-GUIDED DESIGN DECISION, and it is a design spike, not a lookup.

THE VISION (owner): an alternate den API that makes graph expressions explicit — a companion to, and alternative to, den's current surface.

THE QUESTION: is that a den-hoag surface, or a den BINDING of a gen-level surface? gen-graph already owns accessor-based query combinators (reachableFrom, canReach, dependentsOf, cycles, condensation, phaseOrder) and gen-select owns a selector algebra over graph positions with 12 constructors and adapters for both gen-scope and gen-graph. A new den API that re-expresses those would be the built-what-exists pattern this project has hit three times.

WHY IT IS GATED: specifying this before the kernel purity audit (W2) reports would design against the CURRENT representation, which is the very thing under question. If W2 finds the kernel carries value-shaped machinery, an API designed on top of it inherits the shape.

INPUT WHEN IT RUNS: the reuse-scan on den-hoag-8rf already inventoried all 20 gen libraries for query surface and found that gen-product supplies coordinate-tuple addressing (cells, coordsOf, fiber, slice, restrict) and that uniformity over a lifted graph is a THEOREM of the existing layering rather than new code. That scan is directly reusable here.

## Comments (0)

(none)
