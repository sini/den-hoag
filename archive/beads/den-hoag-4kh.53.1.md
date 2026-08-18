# den-hoag-4kh.53.1 — [reconcile] the inventory is against c42df53 and the policy-record migration moved at least three of its findings — re-derive A3, D1 and the excludes posture before acting on §1/§4/§12

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.1` |
| status at evacuation | closed |
| priority | P0 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:04:59Z by Jason Bowman |
| last updated | 2026-07-29T00:35:19Z |
| closed | 2026-07-29T00:35:19Z |
| close reason | RECONCILED at e6c8edc, all four items measured. A3 is STALE - kind-level excludes is live end-to-end (four-arm probe with positive control, plus a materialized read), so the audit finding is refuted and 4kh.53.2 premise is invalidated. D1 DEFECT CLOSED (4 read sites at c42df53, 0 now, same predicate as control) but its RESOLUTION is untouched - the shipped value is selects = [ "host" ], literally a kind-label list, so the migration replaced one kind-label list with another. 12.2 semantics already encoded in source; the remaining question is narrower and restated on the decision bead. Templates: 8 of 8 comparable are GREEN on v1 and FAIL on den-hoag, all four named blockers reproduce plus two more, so the template suite is still NOT a live gate and the child beads assuming so remain correct. X1-vs-4kh.18 answered by the orchestrator: re-scope the description, keep the bead. |
| description bytes | 3587 |
| notes bytes | 4582 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ BLOCKS EVERY OTHER CHILD OF den-hoag-4kh.53. The inventory was audited against
den-hoag c42df53. A ~67-file policy-record migration has landed in the working tree
SINCE, and at least three of the document's findings have already moved. Nobody should
act on §1, §4 or §12 without re-deriving first.

MEASURED BY THE ORCHESTRATOR, 2026-07-28, against the current working tree:

· ★ A3 ("kind-level `excludes` is UNIMPLEMENTED, not starved") IS PARTIALLY ADDRESSED.
  `kindExcludesOf` now exists at lib/compat/ingest.nix:243 and lib/compat/compile.nix
  consumes `ing.kindExcludes` at three expressions. The migration implements the
  SAME-KIND case and ABORTS BY NAME on a descendant-kind exclusion.
  ⇒ The document's "fixing rawForShim alone would change nothing observable" may no
  longer hold. Re-derive A3 end to end before scoping it.

· ★ D1's KERNEL READS ARE GONE. The document measures `__firesAtKinds` read at three
  kernel sites and populated at zero. Current tree: 15 occurrences, and exactly ONE
  outside lib/compat -- a COMMENT at staged-resolution.nix:51. The record surface's
  `selects` field replaced it (concern-policies 10 occurrences, compat/compile 14).
  ⇒ D1's DEFECT is likely closed; D1's RESOLUTION (use gen-select's scope-position
  combinators rather than a kind-label list) is NOT, and is the live question.

· A1 IS STILL LIVE. `rawForShim` unchanged at lib/compat/bridge.nix:609.

ALREADY-RULED ITEMS THE DOCUMENT LISTS AS OPEN -- reconcile rather than re-decide:
· §12.2 "`excludes` posture" -- den-hoag-9xo.28 was AMENDED by measurement on
  2026-07-28: `den.schema.<K>.excludes` is SUBTREE-SCOPED in v1, measured with two
  positive controls, and the "excludes is includes' DUAL" justification was WITHDRAWN
  as the wrong reason for a right answer. The document does not have that.
· D1a's own note about `9xo.56` / `9xo.57` is CORRECT AND INCOMPLETE: `9xo.57` was
  subsequently REJECTED at the gate (ABW Definition 3 p.96 is asymmetric -- same-stratum
  POSITIVE reads are permitted, only NEGATED reads must be strictly below; and the
  proposed inversion check was a tautology because ctxKeyStrata is empty at every
  production call site). The multi-stratum registration ban STAYS.
· X1 ("bead 4kh.18 is stale, re-scope or close") CONFLICTS with a measurement recorded
  on 4kh.18 the same day: the staged pre-pass is LOAD-BEARING FOR ABW CONDITION 2 --
  its ctx is fixed before suppressions exist, which is the only thing making a negated
  read sound (den-hoag-4kh.51, with a live witness). ⇒ 4kh.18 is NOT simply stale. Its
  DESCRIPTION may be; its subject acquired a new obligation. Re-scope, do not close.

WHAT THIS BEAD OWES:
1. Re-derive A3, D1 and §12.2 against the post-migration tree and record which of the
   document's findings survive, with the same MEASURED/ARGUED discipline.
2. Reconcile X1 against 4kh.51 / 4kh.18's recorded obligation.
3. ★ RE-STATE THE COVERAGE HOLE THAT MATTERS MOST FOR THIS RECONCILIATION: the audit
   states 8 of 9 den templates and 0 of 4 sampled external configs will not evaluate
   against den-hoag at all, so the template suite IS NOT A LIVE GATE. Several beads in
   this family will be tempted to use templates as a witness. Establish first whether
   the migration changed that -- it fixed several evaluation blockers.

DO NOT re-derive the whole document. The three items above are the ones with measured
evidence of movement; everything else is presumed current until someone shows otherwise,
and the document's own §11 corrections ledger should be read before re-investigating
anything.

## Notes


────────────────────────────────────────────────────────────────────────────
★★ RECONCILED AT e6c8edc, ALL FOUR ITEMS MEASURED. Clean tree, no freezing needed.

1. ★ A3 IS STALE -- THE AUDIT'S FINDING NO LONGER HOLDS. Four-arm measurement through
   `denCompat.compile` -> `I.compilePolicies`:
     a_noSchema     [ ]                                      no rule
     b_includeOnly  selects = [ "host" ]                     ← POSITIVE CONTROL
     c_includeExcl  selects = [ ]                            ← ★ THE EXCLUDE MOVES IT
     d_exclOnly     [ ]
   ★ AND MATERIALIZED, because `selects` is an intermediate -- resolved-aspects at a real
   host node: without excludes [ "defaults" "excl-marker" ], with excludes [ "defaults" ].
   `defaults` present in BOTH, so this is DESELECTION, not a wholesale eval failure.
   ⇒ Kind-level `excludes` is LIVE END TO END. The audit's measured claim ("adding
   `excludes` leaves the count unchanged") is REFUTED, arm-a != arm-b as the in-run control.

2. D1 -- DEFECT CLOSED, RESOLUTION UNTOUCHED, both measured.
   Predicate over lib/ (ledger and both worktree dirs excluded): 4 READ SITES AT c42df53,
   0 AT e6c8edc. ★ THAT IS THE POSITIVE CONTROL -- the same predicate matches at the
   audit's own commit and not now, so the absence is real. (The audit said THREE kernel
   sites; the predicate finds FOUR -- the three `elem nodeKind` pre-filters plus
   concern-policies' propagation.) The 1 remaining non-compat hit is a COMMENT, verified.
   ★★ AND THE RESOLUTION QUESTION IS EXACTLY WHERE THE AUDIT LEFT IT, WITH THE A3 PROBE AS
   ITS OWN EVIDENCE: THE SHIPPED VALUE IS `selects = [ "host" ]` -- LITERALLY A KIND-LABEL
   LIST. D1's resolution was to use gen-select's SCOPE-POSITION COMBINATORS *INSTEAD OF* a
   kind-label list. ⇒ THE MIGRATION REPLACED ONE KIND-LABEL LIST WITH ANOTHER. Defect
   closed; resolution open, and not one step nearer.

3. §12.2 -- WHAT THE LANDED CODE IMPLEMENTS. Same-kind: HONOURED (measured above).
   Descendant-kind: ABORTS BY NAME (measured; `tryEval.success = false`), and the message
   is the named guard stating the subtree/kind extent mismatch and that refusing beats
   silently over-applying.
   ★ THE CODE ALREADY ENCODES THE 9xo.28 AMENDMENT -- ingest.nix:238-242 says outright that
   an `includes` entry fires at K-NODES ONLY while an `excludes` entry reaches K AND ITS
   WHOLE SUBTREE, and that "excludes is includes with a minus sign" is the wrong model. The
   withdrawn DUAL justification is already retired IN SOURCE.
   ⇒ ★ THE REMAINING QUESTION IS NARROWER THAN THE AUDIT'S AND MUST BE RESTATED: NOT "what
   should excludes mean" but **DOES DEN-HOAG'S PER-KIND SELECTION REPRESENTATION NEED TO
   BECOME PER-INSTANCE (SUBTREE) SELECTION, OR IS REFUSING THE DESCENDANT CASE THE ACCEPTED
   PERMANENT POSTURE?**

4. ★★ THE COVERAGE HOLE SURVIVES INTACT -- THE MIGRATION FIXED NONE OF THE TEMPLATE
   EVALUATION BLOCKERS. Both arms, `--override-input den` on each, v1 at 99cc0c5a:
   ★ 8 OF 8 COMPARABLE TEMPLATES GREEN ON v1, FAIL ON den-hoag. Arm A passes and arm B
   fails, so every one is a REAL den-hoag blocker, not template rot. All four of the
   audit's named blockers reproduce VERBATIM, plus TWO IT DID NOT NAME (`captureFleet`,
   `__findFile`). (`noflake` fails on BOTH -- harness, excluded, not counted.)
   ⇒ THE TEMPLATE SUITE IS STILL NOT A LIVE GATE ON THE COMPAT LAYER, and the child beads
   that assume so REMAIN CORRECT TO ASSUME SO. Nothing in this family becomes
   testable-by-template yet. Full blocker list at its own bead.
   ★ AND THE CONTROL CORRECTED THE MEASURER MID-RUN: `minimal` and `microvm` fail with
   `The option 'flake' does not exist` / `attribute 'microvm' missing`, which READ LIKE
   TEMPLATE ROT. The v1 arm shows both GREEN, so that reading was wrong -- without the
   control, TWO REAL BLOCKERS WOULD HAVE BEEN DISCOUNTED.

ITEM 2 OF THE OWES LIST (reconcile X1 against 4kh.18) IS NOT A MEASUREMENT and was
correctly not claimed. ORCHESTRATOR ANSWER, recorded here: X1 is RIGHT that 4kh.18's
DESCRIPTION is stale -- the two-stage schedule it describes no longer exists in that form.
It is WRONG that the bead should therefore close: 4kh.51 established the staged pre-pass is
LOAD-BEARING FOR ABW CONDITION 2 (its ctx is fixed before suppressions exist, which is the
only thing making the negated read in `gateSuppression` sound), and that obligation is
already recorded on 4kh.18. ⇒ RE-SCOPE THE DESCRIPTION, KEEP THE BEAD. Its subject did not
disappear; it acquired an obligation nobody had written where it would be seen.

## Comments (0)

(none)
