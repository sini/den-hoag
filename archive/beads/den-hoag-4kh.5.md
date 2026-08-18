# den-hoag-4kh.5 — V1: validation-status pass over the existing bead graph

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.5` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:24:39Z by Jason Bowman |
| last updated | 2026-08-05T20:48:29Z |
| description bytes | 1452 |
| notes bytes | 0 |
| comments | 3 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Establish which beads represent VALIDATED CORRECT work and which are self-authored hypotheses.

OWNER DIRECTIVE: beads must contain a proper graph of validated correct work. Many specs behind existing beads are self-authored and never adversarially reviewed.

LABELLING — the marker is POSITIVE: a validated bead carries arch-validated; ABSENCE means not-yet-validated. Labelling the unvalidated ones instead fails OPEN, because a forgotten label would then read as validated. The standing lesson is that silence must never read as success.

HONEST STARTING POINT — today's beads are themselves in the unvalidated class. Eleven were filed on 2026-07-27 from specs authored by the assistant. Only den-hoag-y53 has been adversarially reviewed, twice, REVISE both times: the reviews found two blocking defects plus one that the assistant's own fix INTRODUCED, re-creating the .8 silent-registry-loss failure mode inside the fix for .8. The others are unreviewed and must not be presumed correct because they are recent.

SCOPE: all ~80 beads. For each, record whether it rests on (i) an adversarially reviewed design, (ii) a self-authored spec, or (iii) a measurement with no design attached. Only (i) is eligible for arch-validated.

WHY THIS GATES W4: if most of the graph is unvalidated, its current SHAPE is a hypothesis, and any roadmap re-ordering built on it inherits that. W4 should not re-order an unvalidated graph and call the result a roadmap.

## Comments (3)

### 1 — 2026-07-27T20:40:23 · Jason Bowman

VALIDATION AUDIT COMPLETE (independent, fresh context, 2026-07-27). All 88 beads covered — the bead said
"~80"; actual is 88 (57 open + 1 in-progress + 30 closed). Read-only.

★ HEADLINE: 57 OF 58 OPEN BEADS — 98.3% — REST ON SOMETHING OTHER THAN AN ADVERSARIALLY REVIEWED DESIGN.
  22 self-authored specs · 32 measurements proposing nothing validated · 3 with no recoverable evidence.
  The single exception is den-hoag-y53 — and it is BLOCKED BY den-hoag-00g, which has no design and whose own
  body says "do not implement from this bead".
  Restricting to open beads that PROPOSE something (23): 1 of 23 validated = 4.3%.

CLASSES: (i) adversarially reviewed = 2 strict + 14 weak, of which 13 of 16 are CLOSED. (ii) self-authored
spec = 24 (22 open). (iii) measurement, no design = 44 (32 open) — uniformly well-instrumented, most carrying
a positive control in the same run, and uniformly proposing nothing validated; fourteen say so outright
("NOT SCHEDULED"). (iv) unclear = 4.

The 14 "weak (i)" (9xo.15 + .15.1-.15.13) rest on a plan over a reviewed design whose body MANDATES
independent review — but NO REVIEW ARTIFACT EXISTS. Contrast y53 and default-attachment, which have six
review documents. The only trace is nit-numbering in a revision header, which a validation pass cannot verify.

★★ FOUR ERRORS OF THE ORCHESTRATOR'S, FOUND BY THE AUDIT:
  C7 — den-hoag-4kh AND den-hoag-4kh.5 both state "eleven beads were filed on 2026-07-27". FIFTY-THREE were
       created that day. The bead scoping the validation pass undercounts its own subject roughly 4x. The
       eleven named omit 9xo.22-.37, 5pv ljr mu9 yp1 wj0 lcz w0a 1qh xf9 56i nn4 m0a cah eq9 c3i xyb 3qi hat,
       and 4kh.1-.8.
  COST EDGES ENCODED AS CORRECTNESS BLOCKS — 4kh.3 <- 9w8 and deb <- 9w8 are hard `blocks` edges, but BOTH
       BEADS SAY THEMSELVES that the dependency is for cheapness, not correctness ("DEPENDS ON den-hoag-9w8
       for cheapness, not for correctness"; "partly INDEPENDENT of den-hoag-9w8"). 9w8 is falsely on W3's
       critical path.
  4kh.7 UNDERSTATES ITS OWN BLOCK — it names the y53/00g dependency but not that 00g HAS NO DESIGN, so the
       sequencing spike reads as more tractable than it is.
  THREE WRONG BEAD IDS IN PROSE — 8rf cites m0a where it means y53 (edge is right, prose wrong); 9xo.13's
       close reason and 9xo.36's body both cite 9xo.31 for the flake-root finding (it is 9xo.34); 9xo.30's
       comment cites 9xo.33 for "templates are the usable witness set" (it is 9xo.37).

★★ CONTRADICTIONS IN THE GRAPH:
  C1 — den-hoag-w0a IS ALREADY FIXED AND OPEN AT P1. Its content (two drifted primitiveTypeNames lists) was
       fixed by gen-schema af3dbe9, plus the exact guard w0a asks for. VERIFIED IN TREE at
       gen-schema/lib/identity.nix:33 — one hoisted list, both locals gone. The fix is credited in lcz's close
       reason. Work landed under a bead about a different defect; the bead describing it is still open at P1.
  C2 — THE TWO EPICS CONTRADICT EACH OTHER ON THE NORTH STAR. 9xo states "No effect-runtime duplication
       remains" and lists the A1 runPrePass dissolution DONE. 4kh names the live __provider writer
       (lib/compat/den-brackets.nix:41-47) as "the first CONFIRMED W2 item" and makes the A1 runPrePass
       accumulator its criterion-5 KNOWN-POSITIVE. 7pt measures the __provider writer live. One epic is wrong
       about the same class of thing.
  C3 — 9xo pins main @4044ed5; HEAD is c0aa7be. The SAME 34-commit staleness 4kh holds against
       coverage-matrix.md applies to the north-star epic itself.
  C4 — 9xo.9 vs 9xo.13, FOUR MINUTES APART: .9 records the ruling "materialisation follows reachability" with
       an acceptance criterion; .13 measures it VACUOUS and records it withdrawn. Both stand, so a reader of
       .9 alone takes a withdrawn ruling as current.
  C5 — 9xo.16 vs 9xo.30: .30's proposal is measured, in .16's OWN comment, to make .16 STRICTLY WORSE
       (blocker B3). Both open, no edge, no shared note.

MISSING DEPENDENCY EDGES — five, asserted in prose, absent from the graph: 9xo.30 blocks 9xo.9 half (1)
(stated in .30 and repeated in the epic's triage comment); 9xo.13 blocks 9xo.9 half (1) — and .13 is CLOSED,
so its correction ("the orchestrator earlier stated .13 was not a blocker; that was wrong, twice asserted and
twice measured against") is UNREACHABLE from .9; 9xo.32 D1 and 9xo.33 D2 are each stated PREREQUISITES of
9xo.30's candidate.

WRONG DEPENDENCY: 9xo.16 <- 9xo.20 rests on a REFUTED causal claim — .20 asserts it is ".16's real cause",
while .16's comment measures the actual defect as a missing `aspect` field on baseEntityModule, unrelated to
v1DeepMerge. A P0 (9xo.9) sits behind .16, behind .20, on a chain whose middle link is measured false.

★ CALIBRATION WARNING — WHAT (i) ACTUALLY BUYS. DL-HS-73 records that a REVIEW APPROVED commit 4986982, which
left the corpus totally unevaluable across four commits: "The review that approved the change read the diff
and the comment and did not ask what happens when the probe reads a field the instance does not have."
Separately, 9xo.15.1's "PREDICTED STOP" was measured wrong INSIDE a reviewed plan (rawOptionsOf empty for all
ten kinds; "R2.2 as written would have shipped a silent no-op and passed"). ⇒ arch-validated is a FLOOR, NOT
A WARRANT. The gate must not be treated as conferring correctness.

(iv) UNCLEAR — 4 beads with body "See notes." and no recoverable evidence: 9xo.21 and 9xo.22 have ZERO
comments (the latter's title claims "measured live" and the measurement is recorded nowhere); 9xo.16's sole
comment REFUTES the bead's own diagnosis ("THE BEAD WAS THE OUTLIER"), leaving no correct claim in the body;
9xo.18 is CLOSED on a claim never recorded.

CONSEQUENCE FOR W4: its own stated premise — "if most of the graph is unvalidated, its current SHAPE is a
hypothesis" — is satisfied AT THE MAXIMUM. W4 must not re-order this graph: its four inputs (4kh.1 .2 .3 .5)
are themselves four of the 22 unvalidated (ii) beads.

### 2 — 2026-07-27T21:40:09 · Jason Bowman

GRAPH CORRECTIONS APPLIED (2026-07-27), all from the den-hoag-4kh.5 validation audit. Recorded here because a
correction with no trace is indistinguishable from drift.

1. den-hoag-w0a CLOSED — already shipped. Verified twice independently: one hoisted primitiveTypeNames list
   at gen-schema/lib/identity.nix:33 (both local copies gone), and the exact guard the bead asks for exists at
   gen-schema/ci/tests/identity-hash-for.nix:88. It was open at P1 describing work that landed under a
   different bead.

2. TWO FALSE BLOCKING EDGES REMOVED — den-hoag-4kh.3 <- den-hoag-9w8 and den-hoag-deb <- den-hoag-9w8.
   THE ORCHESTRATOR'S ERROR: both were hard `blocks` edges encoding a COST dependency, while BOTH BEADS SAY
   IN THEIR OWN TEXT that the dependency is for cheapness not correctness ("DEPENDS ON den-hoag-9w8 for
   cheapness, not for correctness"; "partly INDEPENDENT of den-hoag-9w8"). 9w8 was falsely on W3's critical
   path. W3 and deb are now unblocked and can run at higher cost without the corpus reorganization.

STILL OUTSTANDING FROM THAT AUDIT, deliberately NOT applied — each needs a decision, not a correction:
 - 9xo.16 <- 9xo.20: the chain's MIDDLE LINK IS MEASURED FALSE (.20 asserts it is ".16's real cause"; .16's
   own comment measures the actual defect as a missing `aspect` field on baseEntityModule, unrelated to
   v1DeepMerge), with a P0 (9xo.9) sitting behind it. Rewiring this changes what a P0 waits on.
 - FIVE MISSING EDGES asserted in prose but absent from the graph: 9xo.30 blocks 9xo.9 half (1); 9xo.13 blocks
   9xo.9 half (1) — and .13 is CLOSED, so its correction is unreachable from .9; 9xo.32 D1 and 9xo.33 D2 are
   each stated prerequisites of .30's candidate. Adding unreviewed edges to an already-98.3%-unvalidated
   graph deepens the hypothesis rather than fixing it.
 - FOUR "See notes." BEADS with no recoverable evidence (9xo.16 .18 .21 .22) — .21 and .22 have ZERO comments
   and .22's title claims "measured live" with the measurement recorded nowhere. Each needs its measurement
   produced or the bead closed as unevidenced.
 - C7, the orchestrator's own miscount: den-hoag-4kh and den-hoag-4kh.5 both state "eleven beads were filed
   on 2026-07-27". FIFTY-THREE were created that day.

### 3 — 2026-07-28T01:44:55 · Jason Bowman

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
