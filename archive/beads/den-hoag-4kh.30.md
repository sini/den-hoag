# den-hoag-4kh.30 — [kernel] triage 5 declared-blocking readiness refinements, untracked — sharpest: guard-arrived aspects don't trigger neededBy, so presence depends on ARRIVAL PATH

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.30` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:32:25Z by Jason Bowman |
| last updated | 2026-07-28T05:32:25Z |
| description bytes | 1726 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED — FIVE den-hoag READINESS REFINEMENTS WERE DECLARED MUST-RESOLVE-BEFORE-IMPLEMENTATION AND ARE
UNTRACKED. Bead scan: `neededBy` / `enriched` = 0 hits; positive control same run `kernel` = 13.

★ SHARPEST — THE guard/neededBy ASYMMETRY: guard-arrived aspects do NOT trigger `neededBy`, so AN ASPECT'S
PRESENCE DEPENDS ON ITS ARRIVAL PATH. Two evaluations that should agree on the aspect set can disagree
because one arrived through a guard. That is a determinism defect in the surface, not an ergonomics gap.

THE OTHER FOUR:
  - enriched-context equality is KEYSET-ONLY -> a silent order-dependent overwrite; wants a definition-time
    duplicate-key error rather than last-writer-wins.
  - gather-predicate domain and termination are UNSPECIFIED.
  - edge-as-link-without-re-resolution has NO SEMANTICS.
  - the spec body still implies semilattice determinism while the ADOPTED contract is pinned-traversal — the
    document argues for a property the design no longer claims.

★ THIS IS A TRIAGE TASK, NOT A BLIND FILE. The reporting agent explicitly did NOT verify whether the current
design still has these — the vocabulary rewrite may have dissolved some. Filing five defects sight-unseen
would put unvalidated claims in the graph, which this project's standing rule forbids. So: diff the five
refinements against the current unified-link-merge vocabulary spec, then file what survives AS ITS OWN BEAD
with its own evidence, and record what dissolved WITH THE REASON.
SETTLED BY: that diff. Nothing else is needed.

PROVENANCE: mem-den memory audit 2026-07-28, item C5, reported as (C) with an explicit (E) caveat on
liveness. The caveat is preserved deliberately — the item is the TRIAGE, not the five defects.


## Comments (0)

(none)
