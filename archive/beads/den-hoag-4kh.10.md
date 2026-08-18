# den-hoag-4kh.10 — Audit den v1 test-corpus port completeness — every unported test accounted for

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.10` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:51:43Z by Jason Bowman |
| last updated | 2026-08-05T20:48:30Z |
| description bytes | 2780 |
| notes bytes | 0 |
| comments | 3 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Audit whether den v1's test corpus was ported to den-hoag COMPLETELY, and account for every test that was not.

OWNER PRINCIPLE, and it sets the acceptance bar: "I would rather have a ported, valid, correct and FAILING
test than no test." A failing test is SIGNAL. An absent or silently-skipped test is SILENCE — and silence
reading as success is the failure mode this whole arc exists to eliminate. A test that was dropped because it
failed is strictly worse than the same test failing in CI.

THE QUESTION, precisely: is there a mapping from every den v1 test to a den-hoag test, and for each v1 test
with no counterpart, WHY — ported-and-passing / ported-and-failing / deliberately-not-ported-with-a-reason /
silently-dropped. The last category is the deliverable.

MEASURED AT SCOPING (2026-07-27, incomplete — a proper enumeration is part of the task):
  den-hoag ci/tests: 144 .nix files + 56 in den-behavioral/
  markers present in den-hoag ci: 57 "deferred", 9 "skip", 2 "NOT PORTED", 1 "disabled"
  the v1 count needs care — a naive find over ~/Documents/repos/denful/den picks up .worktrees/ copies and
  docs/node_modules; filter to the real corpus.
  REFERENCE.md states v1 shipped "753+ tests"; the den-hoag checkpoint states its ci suite runs 1893. Those
  are DIFFERENT GRANULARITIES (files vs assertions) and must not be compared directly — establish the unit
  before quoting any ratio.

PRIMARY RECORD: papers/den-architecture/archive/2026-07-21-den-test-migration-EXECUTION.md (144 KB) — the
standalone archived EXECUTION ledger for the test migration, referenced by STATUS/coverage-matrix.md, whose
header notes its content is deliberately NOT merged into the matrix. That ledger is the intent; the tree is
the outcome; the gap between them is the finding.

WHAT MAKES THIS MORE THAN COUNTING:
 - A ported test can be VACUOUS. den-hoag has a documented history of tests that could not fail: predicates
   whose string never appears on the at-risk path, `builtins.all f [ ]` passing on an empty set, a guard that
   went green because a DIFFERENT guard aborted first. A test that was ported but cannot fail is closer to
   absent than to present, and should be reported in its own category.
 - A ported test can assert a WEAKER property than the original. Compare what the v1 test pinned against what
   the den-hoag test pins, not merely that both exist.
 - The 57 "deferred" markers need reading. Deferred WITH a recorded reason and a tracking id is a decision;
   deferred silently is a drop wearing a nicer word.

OUT OF SCOPE: fixing anything, and porting anything. Findings do not become beads directly — they go through
the adversarial review gate (den-hoag-4kh.6). Failing ported tests are the DESIRED end state, not a defect to
be resolved by deletion.

## Comments (3)

### 1 — 2026-07-27T21:06:29 · Jason Bowman

V1 TEST-PORT AUDIT COMPLETE (independent fresh context, 2026-07-27). den v1 @cdc95cee, den-hoag @c0aa7be.
Read-only. Scratch artefacts retained: map2.tsv, v1_cases.tsv, hoag_cases.tsv, v1_uncited.txt,
commented_cases.txt, assert_cmp.txt, results.json, perturb.nix, probe_ic.nix.

UNIT, established before any ratio: v1 FILES = 229 (templates/ci/modules/{deadbugs 57, deprecated 15,
features 5, internal-api 83, public-api 69} minus new-test.nix + test-support/eval-den.nix, via git ls-files
so worktrees/node_modules are excluded by construction). v1 CASES = 1089 test*-prefixed leaves (+2
non-prefixed in public-api/flake-parts.nix — inputs'/self' — which nix-unit would silently 0/0). den-hoag =
1911 cases / 170 suites, measured live. "753+" IS STALE PROSE, not a census — it appears only in papers
README describing the v1 ARCHITECTURE. Do not quote it.

★ HEADLINE — THE SUITE IS 100% GREEN AND THAT IS THE DEFECT.
tryEval (expr == expected) over all 1911: PASS 1911, FAIL 0, ERROR 0.
PORTED-FAILING = 0. Not one v1 test was left failing. There are 72 COMMENTED-OUT test cases in
ci/tests/den-behavioral/ — every case that did not pass was converted to a comment block. Against the owner's
bar ("I would rather have a ported, valid, correct and FAILING test than no test") this is the exact
inversion: 72 tests dropped BECAUSE they failed, each strictly worse than the same test failing in CI. They
carry a reason line, but they do not run, cannot fail, and contribute nothing to the 1911.

MAPPING + POSITIVE CONTROL: ported files carry a provenance header naming the v1 path; 51 v1 files cited.
Independent basename matching found 49, ALL inside the 51 and 0 outside. Two methods agree.

BY FILE (229): public-api 32/69 ported · deadbugs 19/57 · internal-api 0/83 · deprecated 0/15 · features 0/5.
TOTAL PORTED 51, UNPORTED 178.
BY CASE (1089): cited files hold 188; 901 uncited. Of those, 245 in 40 internal-api/fx-* files are the
migration plan's DECLARED exclusion. That leaves 656 cases across 138 files that were IN the plan's stated
target with no counterpart and no per-file record. Plus 15 sub-file drops = 671 CASES SILENTLY UNPORTED.

PORTED-PASSING 83 — all name-matched pairs located; 80 source-diffed BYTE-IDENTICAL, 0 differing, 3 unparsed.
Assertion fidelity of what shipped is CLEAN.

PORTED-BUT-VACUOUS 73:
 - den-behavioral/empty-aspects.nix:32 test-no-aspects — PROVEN VACUOUS BY PERTURBATION. Scaffold
   _lib/den-compat-test.nix:275-279 does v1's partial match `expr = intersectAttrs expected expr`; with
   expected = { } that is { } for ANY attrset. Re-run with den.aspects.injected.… added (so "no aspects" is
   FALSE) and it STILL PASSES. Faithful port of an equally vacuous v1 test (denTest.nix:20-24).
 - the 72 commented cases, vacuous by construction.
 - STRUCTURALLY VACUOUS-PRONE: the scaffold's expectedError arm (:265-269) asserts only THAT something threw,
   never WHICH error — and has ZERO consumers. The plan budgeted 4.

PORTED-WEAKER 0 at assertion level, but 3 files ported PARTIALLY with 15 cases silently absent:
public-api/nested-aspects.nix 6→1 (unaccounted: test-multi-level-nesting, test-nested-parametric-parent,
test-provides-backward-compat) · os-class-host.nix 4→2 (unaccounted: test-host-os-forwards-to-both,
test-host-os-from-parametric) · strict.nix 10→2, and the 2 are SYNTHETIC witnesses in flake-strict.nix, not
ports — all 10 v1 names absent.

NOT-PORTED-SILENT — 138 files / 656 cases (671 incl. sub-file). No record in STATUS/, specs/, plans/,
archive/, or beads. `bd search 'test migration'` → NO ISSUES FOUND; nothing in the 80-bead graph tracks it.
 - public-api 36 files / 179 cases — user-facing surface, no exclusion rationale anywhere. Largest:
   include-children(13) schema-registry(12) deliver(11) angle-brackets(10) host-aspects(10)
   policy-context-enrichment(10) user-host-mutual-config(10) pipes(9) schema-base-modules(8).
 - deadbugs 38 files / 99 cases — EVERY ONE IS A REGRESSION WITNESS FOR A FIXED BUG. Dropping a regression
   test is how the bug returns. Largest: standalone-home-host-context(10) issue-588(7)
   external-namespace-deep-aspect(5) issue-525(5).
 - internal-api NON-fx 44 files / 304 cases — OUTSIDE the plan's exclusion, which named only fx-*. These are
   the plan's own "~280 reclassified outcome-tests … reproducing these outcomes is the substrate's entire
   point", scheduled Phase 2, WHICH NEVER RAN. Largest: has-aspect(42) class-module-partial-apply(19)
   edge-trace(14) include-dedup(13) policy-combinators(12).
 - features 5 files / 25 cases — the plan put features IN the target; zero cited.
 - deprecated non-parametric ~10 files / ~20 cases — plan counted "deprecated-clean 10" as in-target.

NOT-PORTED-DECIDED: 40 fx-* files/245 cases (plan §Excluded, category-level, no tracking id) · ~29 deprecated
parametric cases · the 72 parked (each with an in-file reason) · 2 literal "not ported" strings, both real
decisions (hm-host-forward-hm-class.nix:33 corpus-zero; policy-for-include.nix:84 den.lib.policy.when absent).
THE CATEGORY-LEVEL PIVOT: archive/…-den-test-migration-EXECUTION.md:90 "STRATEGIC INFLECTION" — migration
STOPPED after batches A/B/C (41 files) in favour of a WS-B pivot. A recorded decision, but bulk, in a file
whose own line 1 says "STOPPED @2026-07-23 … NOT a live tracker", and it names NOT ONE of the files it dropped.

★★ THE STANDING BAR APPLIED — one drop converted from claim to EVIDENCE. Ran v1's
public-api/include-children.nix::test-include-children-basic VERBATIM through den-hoag's own scaffold:
    error: attribute '_' missing … den.aspects.igloo.includes = [ den.aspects.servers._ ];
`den.aspects.<x>._` (include-all-immediate-children) is LIVE IN V1, DEAD IN DEN-HOAG, UNTESTED, UNRECORDED.
lib/compat/compile.nix:598-605 lists "_" in droppedAspectKeys. Grep with positive controls (hasAspect→17,
den.aspects→124, pipe.expose→5): include-children/includeChildren → 0 in ci/tests/, 0 in lib/, 0 in STATUS/
specs/ plans/ archive/. 13 v1 cases, user-facing, no record. Same shape unprobed: pipe-projection (7 cases,
0 hits), policy-inspect (6 cases, 1 mention).

★ THE ORCHESTRATOR'S SCOPING MEASUREMENT WAS WRONG AND THE AUDIT CORRECTED IT. I reported "57 deferred · 9
skip · 2 not ported · 1 disabled" as port markers. Reading all 84 occurrences: ZERO are port-deferrals. Every
one is den-hoag's own domain vocabulary — a config-demanding channel emission, the R6 defer record/lowerDefer,
the literal field deferred = false, and test NAMES. The single "disabled" is test-disabled, a v1 test name
ported into use-global-pkgs.nix:44. Split: decided 0 / silent 0 / NOT-A-MARKER 84. The real markers are
PARKED (33 lines), PARKED-DIVERGENCE, BLOCKED-WSB, and the 72 commented `# test-… =` lines.

HONEST COVERAGE: file-level 229/229 mapped (100%) by two agreeing methods each with a positive control ·
case-level fidelity of what shipped COMPLETE · case-level property mapping of the 656 uncited SAMPLED NOT
COMPLETE (~12 subjects probed + one full end-to-end perturbation). Several uncited subjects are PLAUSIBLY
re-guarded natively (has-aspect → compat-has-aspect.nix; schema-registry → compat-registry-*; deliver →
compat-deliver-matrix.nix; entity-isolation → compat-isolated-guard.nix) BUT NOT ONE WAS VERIFIED to preserve
the specific property its v1 case pinned. ⇒ TREAT THE 656 AS UNACCOUNTED, NOT AS UNPROTECTED — the
distinction is the point: nobody has done the accounting, which is why silence currently reads as success.

### 2 — 2026-07-28T01:38:16 · Jason Bowman

★★★ OWNER RULING (2026-07-27) — WHAT CI IS. THREE-STATE. THIS UNBLOCKS THE AUDIT.

RULED: CI is THREE-STATE — pass / KNOWN-FAIL (with a tracked id) / UNEXPECTED-FAIL.
LEDGER OVER THE ABSOLUTE, GATE OVER THE DELTA. Green means "NO NEW FAILURES", NOT "correct".
★ AND THE COMPLETING HALF, which is not optional: A KNOWN-FAIL THAT STARTS PASSING MUST ALSO FAIL THE GATE.

THEORY: "CI as gate" treats the suite as a DECISION PROCEDURE — total, yes/no. "CI as ledger" treats it as a
SPECIFICATION WITH UNMET OBLIGATIONS. These are different objects and this project needs both. Choosing one
discards a role that is actually required; three-state SEPARATES the roles instead of collapsing them.

★★ WHY GATE-ONLY IS NOT NEUTRAL — THE DECISIVE ARGUMENT.
A suite that can only contain PASSING tests CANNOT STATE AN OBLIGATION IT HAS NOT MET. So every unmet
obligation must be deleted, weakened, or commented out to keep it green. THE 72 COMMENTED-OUT TESTS AND 671
UNPORTED v1 CASES ARE THAT PRESSURE HAVING ALREADY ACTED. Gate-only does not merely fail to record the gap —
IT MANUFACTURES THE GAP, and then reads green.
That is the same defect class as everything else this epic has found: the answer looks fine because the
thing that would have objected was removed.

THE OWNER'S OWN BAR ALREADY DECIDED THIS: "I would rather have a ported, valid, correct and FAILING test
than no test." A TEST THAT CANNOT BE RED CANNOT BE A SPECIFICATION. A failing test is SIGNAL; an absent or
silently-skipped test is SILENCE; and silence reading as success is the failure mode this whole arc exists
to eliminate.

WHY THE THIRD STATE'S SECOND HALF IS LOAD-BEARING: an expected-failure that starts passing and is not
flagged means THE LEDGER HAS ROTTEN — the record now disagrees with the tree and nobody is told. That is
silence with extra steps, arriving by a different route. A known-fail turning green is a REAL EVENT: either
something was fixed and the ledger must be updated, or the test stopped testing what it tested. Both need a
human. So it fails the gate.

CONSEQUENCES FOR den-hoag-4kh.10, which this unblocks:
 · the audit's deliverable stands unchanged — the mapping from every v1 test to its den-hoag counterpart,
   and for each with no counterpart WHY: ported-and-passing / ported-and-failing / deliberately-not-ported-
   with-a-reason / SILENTLY-DROPPED. The last category is the deliverable.
 · PORTING A TEST THAT FAILS IS NOW A LANDING, NOT A BLOCKER. It lands as known-fail with its tracked id.
 · the 57 "deferred" / 9 "skip" / 2 "NOT PORTED" / 1 "disabled" markers get re-read against this: DEFERRED
   WITH A RECORDED REASON AND A TRACKING ID IS A DECISION; DEFERRED SILENTLY IS A DROP WEARING A NICER WORD.
   Under three-state, the honest form of every one of them is a known-fail with an id.
 · A PORTED TEST THAT CANNOT FAIL IS STILL ITS OWN CATEGORY and is closer to absent than to present — see
   the vacuous-test history (a predicate whose string never appears on the at-risk path; builtins.all f [ ]
   over an empty set; a guard green because a DIFFERENT guard aborted first). Three-state does not rescue a
   vacuous test; it makes room for a real one that is currently red.

MECHANISM IS AN IMPLEMENTATION QUESTION, NOT A RULING: the expected-failure list must be data (id -> test),
so an unexpected pass is detectable. Standard xfail semantics. Design it under the gate like anything else.


### 3 — 2026-07-28T05:39:28 · Jason Bowman

ADDENDUM — INDEPENDENT MARKER COUNT AT HEAD, confirming this bead's own recorded correction.

Counted 2026-07-28 across ci/tests/den-behavioral/:
  PARKED-DIVERGENCE  21
  BLOCKED-WSB        43
  PARKED (any)       31 lines
spread over 29 of 56 files. POSITIVE CONTROL, same run: 27 files carry no marker at all.
This agrees with the comment already on this bead — the original scoping ('57 deferred, 9 skip, 2 NOT PORTED, 1 disabled') named NONE of the real markers, so it was counting a different thing.

★ ROOT-CAUSE CLUSTERS, readable directly from the markers — this is the useful output, because it converts a flat deferral count into an actionable partition:
  - PIPE RUN-WIRING -> now tracked at den-hoag-4kh.36 (15 cases, was untracked)
  - FORWARD MACHINERY -> forward-each-mutual, guarded-forward, forward-from-custom-class, hm-host-forward-hm-class, nixpkgs-forward-positional (the papers trackers DO carry the forward battery)
  - EXCLUDES-VS-POLICY-REFERENCE -> den-hoag-9xo.28
  - NAMED-USER-PROVIDES BARE-FN DELIVERY -> projected-hasaspect.nix, 4 cases
⇒ This audit's remaining work is smaller than the raw count suggests: the markers partition into four causes, three of which now have beads.
