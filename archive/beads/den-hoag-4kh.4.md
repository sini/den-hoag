# den-hoag-4kh.4 — W4: roadmap realignment — best architecture first

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.4` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:24:16Z by Jason Bowman |
| last updated | 2026-07-27T20:24:16Z |
| description bytes | 1504 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None), `None` (None), `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Re-order the remaining work so kernel-purity items precede compat-materialization items wherever they conflict.

CONSUMES W1 (what actually shipped), W2 (what violates the pure-graph layer) and W3 (what the corpus gets wrong).

MANDATE, owner-stated: best architecture FIRST. This workstream is EXPLICITLY PERMITTED to conclude that shipped work should be REDESIGNED. Sunk cost does not outrank correctness. The specific target is a pure graph representation in the den-hoag KERNEL before the full backwards-compat layer materializes.

THE MEASUREMENT THAT MOTIVATES IT: the v2 design claimed 4-5x compression — an estimated 1,010-1,510 lines replacing ~7,000. The v1 baseline is VERIFIED CORRECT at the spec date (7,029 lines across 37 handler files at den v1 0b250e1). The kernel now measures 13,337 lines, which is 8.8-13.2x over the estimate and a 1.90x EXPANSION against the thing it was to compress 4-5x. On a design whose central claim was compression, that is the signal this arc exists to explain.

OPEN QUESTION THIS MUST ANSWER FIRST: is W2 a criteria sweep, or a PROVENANCE WALK over lib/ by subsystem asking where 12,000 unbudgeted lines came from? Those are different investigations and the second may subsume the first.

CEILING NEEDED: compat is 11,318 lines with a death date. A purity fix that forces compat rework needs a stated limit, or best-architecture-first becomes unbounded.

OUTPUT: a re-ordered dependency graph in beads — not a document. Every re-ordering carries its reason.

## Comments (1)

### 1 — 2026-07-28T01:44:55 · Jason Bowman

★★★ OWNER RULING (2026-07-27) — W4 IS RELEASED FROM HOLD. THE 98.3% FINDING NO LONGER BLOCKS.

OWNER: "we'll deeply review design once we have a functional system, refactor is cheapish"

WHAT THIS OVERTURNS: den-hoag-4kh.5 measured that 98.3% of open beads rest on unreviewed design, and W4 was
held on the reasoning that re-ordering a 98.3%-unvalidated graph yields a roadmap that INHERITS THE
HYPOTHESIS. That reasoning is sound and is NOT retracted — it is OUTRANKED. The owner has ruled that the
cost of being wrong is low (refactor is cheap) and the cost of stalling is high, so the deep architectural
re-review happens ONCE A FUNCTIONAL SYSTEM EXISTS, against something real, rather than against a graph.

THE TRADE, STATED HONESTLY SO IT IS NOT LATER MISREAD AS AN OVERSIGHT: a roadmap built now inherits the
unvalidated shape of the graph it orders. That is accepted knowingly. The bet is that a functional system is
a better subject for deep design review than a bead graph is, AND that refactor cost is low enough to absorb
the rework. Both halves are the owner's call and both are recorded here.

WHAT DOES *NOT* CHANGE — do not read this ruling wider than it is:
 · den-hoag-4kh.5's measurement STANDS. It is a fact about the graph, not a proposal. The 22 unvalidated
   beads, the four "See notes." beads with no recoverable evidence (9xo.16 .18 .21 .22), the wrong
   dependency edge (9xo.16 <- 9xo.20, middle link measured false with a P0 behind it), the five missing
   edges asserted in prose — all remain true and all remain worth fixing when touched.
 · MEASURED DEFECTS STILL ENTER THE GRAPH DIRECTLY. A measured defect is validated fact; that route was
   never gated and is unaffected (den-hoag-4kh.12, den-hoag-m0a, den-hoag-gce).
 · arch-validated remains a POSITIVE label. Absence still means not-yet-validated, never "fine".
 · The gate (den-hoag-4kh.6) is NOT dissolved by this ruling. Its scope for NEW design candidates is a
   separate question put to the owner; this ruling addresses the roadmap hold only.

CONSEQUENCE: den-hoag-4kh.4 (W4 roadmap realignment) is UNBLOCKED and may proceed on its four inputs
(4kh.1 .2 .3 .5), with the standing caveat recorded in its own text that those four are themselves among
the unvalidated set. It should ORDER work, not certify it.
