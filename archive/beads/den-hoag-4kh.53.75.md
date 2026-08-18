# den-hoag-4kh.53.75 — [arch] the ~2k figure is an IMPLEMENTATION not a projection — gen-aspects/gen-scope demos do much of den-hoag in under 2k including data and tests, so §0.4 retire-the-target is wrong at its premise

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.75` |
| status at evacuation | closed |
| priority | P0 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:44:59Z by Jason Bowman |
| last updated | 2026-07-29T22:37:34Z |
| closed | 2026-07-29T22:37:34Z |
| close reason | Closed against den-hoag-yl3's measured answers, executing the adopted option (a) ruling on den-hoag-2rh (comment 8: 'restate item 2 with an enumerated domain or close 53.75 against yl3's answers'). Item 1 (feature coverage): ANSWERED — yl3's census enumerates present/partial/absent with positive controls; coverage is a fraction of den-hoag's (no aspect-in-scope-graph topology, no delivery, no suppression/collision/secrets). Item 3 (scaling): ANSWERED NEGATIVE — the demos are a CONFIRMING instance of the |N| x |R| blowup, two of them worse (sql-schema per-node fleet rescans; nix-config-acl unmemoised (host,user) recomputation). Item 2 (justified delta): premise superseded — the 2k comparison does not price what it was thought to price (no tests in gen-aspects/examples, nixpkgs-tethered, two trees conflated), so per-feature delta pricing against the demos is no longer the sharp question; residual complexity pricing lives under den-hoag-4kh.53.74 (price at target) and den-hoag-4kh.53.3 (D1). The one demand-driven shape worth taking (settings cascade as collectionAttr traverse=neron, O(depth) fleet-independent) is recorded in yl3. |
| description bytes | 3503 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★★ OWNER CORRECTION, 2026-07-29, AND IT INVERTS §0.4 OF THE DESIGN INVENTORY.
"The agent measured the DEMO IMPLEMENTATIONS in gen-aspects and gen-scope against
den-hoag, finding that MUCH OF DEN-HOAG WAS REPLICATED ALREADY IN PURE-GEN IN UNDER 2K
LINES INCLUDING EXAMPLE DATA AND TESTS -- so where it suggests things could be simpler it
is COMPARING AGAINST AN ACTUAL IMPLEMENTATION. There are legitimate reasons for den-hoag to
be more complex than the demos, BUT NOT AT THE SCALE WE'RE CURRENTLY AT."

★ WHAT THIS CHANGES. §0.4 argued the ~2,000-line figure is an ARTEFACT of a stale roadmap:
it was the whole new stack, den's own share was projected at 600-900, compat was outside the
projection entirely, and it was 3x compression of only v1's ~7,000 pipeline-specific lines.
It concluded the target should be RETIRED and that "driving a redesign at 2,000 would push
work into gen that does not belong there." I filed that as an owner decision leaning toward
retirement (den-hoag-4kh.53, anchor bead) AND DID NOT CHALLENGE IT.
⇒ ★★ THAT DIAGNOSIS IS WRONG AT ITS PREMISE. The 2,000 figure is NOT A PROJECTION BEING
COMPARED TO AN IMPLEMENTATION -- IT IS AN IMPLEMENTATION. The gen-aspects and gen-scope demos
DO MUCH OF WHAT den-hoag DOES, in pure gen, under 2k lines INCLUDING EXAMPLE DATA AND TESTS.
A working artefact is not a stale roadmap number, and "the target did not price the surface
or the algebra" cannot stand unexamined against something that runs.

★ THE HONEST QUESTION IS THEREFORE NOT "is the target real" BUT "WHAT IS THE JUSTIFIED
DELTA". Current: kernel 7,710 CODE lines (13,606 total) + compat 6,065 code (11,318 total),
against demos under 2k INCLUDING data and tests. The owner's framing is precise and is the
bar: SOME delta is legitimate; THIS delta is not.
⇒ WHAT MUST BE MEASURED, and this is the work:
1. FEATURE COVERAGE. What do the demos actually implement -- which of den-hoag's concerns,
   which entity/scope/aspect behaviours, which of the four-concern model? Enumerate, do not
   assume. A demo covering 30% at 2k prices differently from one covering 80%.
2. THE JUSTIFIED DELTA. For each thing den-hoag does that the demos do not, state WHY it
   costs what it costs. v1 surface compatibility is a legitimate reason. A second
   materialization engine (G12) is not.
3. ★ AND THE SCALING QUESTION, which may be the most important: DO THE DEMOS HAVE THE
   |H| x (1 + |U|) DISPATCH BLOWUP? They are pure-gen and use gen-scope's evaluator directly.
   If they DO NOT, then the demos are EVIDENCE THAT THE SCALING ARCHITECTURE WAS AVAILABLE
   AND den-hoag DID NOT TAKE IT -- which is exactly the §0 thesis (v1's per-scope candidate
   set versus a global rule set filtered by label) with a WORKING COUNTER-EXAMPLE attached.
   That would make den-hoag-4kh.53.3 (D1) not merely the scaling blocker but a DEMONSTRATED
   one. See den-hoag-4kh.53.74 for the thousands-of-hosts constraint.

★ ORCHESTRATOR ERROR TO OWN: I relayed §0.4's "retire the target" reasoning to the user as
an owner call worth taking seriously, WITHOUT ESTABLISHING WHAT THE 2,000 FIGURE WAS
MEASURED AGAINST. The audit presented it as a projection; it is an implementation. This is
the third time in this arc I have amplified an author's framing without testing its premise
-- the others being the `broadcast-hub-peer` example carried into a gate brief, and the
resolve/enrich asymmetry sharpened in the wrong direction. ★ THE PATTERN IS SPECIFIC: I
CHECK CLAIMS AND I DO NOT CHECK PREMISES.

## Comments (1)

### 1 — 2026-07-29T21:33:21 · Jason Bowman

Measured 2026-07-29 (read-only review of den-hoag-2rh's edges): items 1 and 3 of this bead are ANSWERED by den-hoag-yl3 — demos are a CONFIRMING INSTANCE of the |N|x|R| dispatch blowup, coverage a fraction of den-hoag's — yet this bead remains open P0. Item 2 (the justified delta: per-feature WHY over everything den-hoag does that the demos do not) quantifies over an UNENUMERATED feature set with no stopping point and no bar for enough — non-terminating as written. Needs either an enumerated domain for item 2 or closure against yl3's answers. Flagged in den-hoag-2rh's ruling request.
