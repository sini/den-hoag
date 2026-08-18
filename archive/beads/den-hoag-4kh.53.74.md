# den-hoag-4kh.53.74 — [perf] STANDING: den must scale to thousands of hosts — every complexity finding in the inventory was priced against a ~10-host corpus, and at least one downgrade (G22) is four orders of magnitude wrong at target

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.74` |
| status at evacuation | open |
| priority | P0 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:41:27Z by Jason Bowman |
| last updated | 2026-07-29T00:41:27Z |
| description bytes | 4434 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None), `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★★ STANDING CONSTRAINT, OWNER, 2026-07-29: **den MUST SCALE TO THOUSANDS OF HOSTS.**
This is a TARGET, not an aspiration, and it RE-PRICES THE ENTIRE PERFORMANCE CLASS filed
under den-hoag-4kh.53. Every complexity finding in that family was measured or reasoned
against TODAY'S CORPUS -- roughly 10 hosts -- and several were downgraded on that basis.
★ A COST DOWNGRADE JUSTIFIED BY CORPUS SIZE IS INVALID WHEN THE TARGET IS 100x THE CORPUS.

★★ WHAT IT CHANGES IMMEDIATELY, EACH ALREADY FILED AND EACH NOW MIS-PRICED:

1. ★★★ G22 (den-hoag-4kh.53.49) -- THE DOWNGRADE I RECORDED IS WRONG AT TARGET SCALE, AND
   IT IS MINE TO CORRECT. `firstSeenBy` costs N(N-1)/2 + N `toJSON` calls on the LIVE cells
   path, where N = CELLS = hosts x users.
     today   N ~ 70     ->  ~2,485 toJSON calls   (recorded as "worth fixing, modest")
     target  N ~ 7,000  ->  ~24.5 MILLION         (1,000 hosts x 7 users)
   ⇒ THE SAME DEFECT IS A ~2.5k NUISANCE TODAY AND A CATASTROPHE AT TARGET. I corrected the
   figure DOWNWARD from 40,000 to 2,485 using today's corpus size and RECORDED THAT AS THE
   ANSWER. At the stated target it is four orders of magnitude worse than the number I
   replaced. ★ RE-PRICE AND RAISE.

2. ★★ G20 (den-hoag-4kh.53.47, REOPENED) -- THE SCALE TARGET IS NOW THE STRONGEST ARGUMENT
   AGAINST ITS NEGLIGIBILITY CLAIM. That claim rests on a ci census: median N=1, MAX N=24.
   But `unique`'s call sites include `resolved-aspects.nix` `ancestorIds` PER NODE and
   `staged-resolution.nix` PER ATTACHMENT -- both of which SCALE WITH FLEET SIZE. A
   quadratic that is negligible at N=24 is NOT negligible at fleet scale, and ci contains no
   large fleets BY THE MEASURER'S OWN STATEMENT. ⇒ The reopening was right for
   evidentiary reasons; the scale target makes it right for substantive ones too.

3. ★★★ §0.2 / D1 (den-hoag-4kh.53.3) STOPS BEING A TIDINESS ITEM AND BECOMES **THE SCALING
   BLOCKER**. The audit measured den-hoag at EXACTLY |H| x (1 + |U|) dispatches PER POLICY
   -- 210 for one policy on a tiny fleet -- against v1's ~206 TOTAL ACROSS ALL 31 POLICIES.
     target: 1,000 hosts x 7 users = ~8,000 nodes PER POLICY x ~31 policies
             = ~248,000 dispatches, against v1's ~206.
   ⇒ ★ THIS IS NOT A CONSTANT FACTOR. It is the difference between a per-scope candidate set
   (v1's condition (1), which den-hoag does not have) and a GLOBAL RULE SET FILTERED BY
   LABEL. The audit's §0 thesis said the product "becomes necessary to make the model mean
   anything" once dispatch is global. AT THOUSANDS OF HOSTS THAT PRODUCT IS THE ARCHITECTURE.
   ⇒ D1's RESOLUTION (scope-position selectors, and the reconciliation's finding that the
   migration REPLACED ONE KIND-LABEL LIST WITH ANOTHER) is now the highest-priority item in
   the 4kh.53 family, ahead of every absence-collapse defect.

4. G23 (den-hoag-4kh.53.60) -- `toposort` ships CUBIC against a Kahn citation. The audit
   waived it as sitting on the ORACLE path rather than the build path, "but that is an
   accident, and n grows with fleet demand-edge count." ⇒ AT TARGET SCALE THE ACCIDENT IS
   NOT A DEFENCE. Re-price.

5. THE REJECTED DESIGN'S COST CLAIM (den-hoag-9xo.75) WOULD ALSO HAVE BEEN WORSE THAN
   STATED. §7 framed 3x RULE COUNT as "a bounded, measurable performance cost". Rules are
   per-policy, but DISPATCH IS PER-NODE -- so 3x rules multiplies by node count, and node
   count is |H| x (1 + |U|). Bounded in the wrong variable. The design is rejected on other
   grounds; note this so the next draft does not re-use the same framing.

★★ THE GENERAL RULE THIS SETS, AND IT APPLIES TO EVERY FUTURE PERFORMANCE FINDING HERE:
PRICE COMPLEXITY AT THE TARGET, NOT AT THE CORPUS. State the growth VARIABLE, then evaluate
it at ~1,000 hosts. "Negligible on nix-config" is not a verdict -- nix-config is ~10 hosts
and is the ONLY fleet that currently evaluates (den-hoag-4kh.53.73). A finding may be
correctly waived at target scale; it may NEVER be waived at corpus scale without saying so.
★ AND NOTE THE INTERACTION WITH THE MEASUREMENT PROBLEM: ci has no large fleets, parity's
edge arm does not force full enumeration, and the only path reaching fleet scale is
`ship-gate.nix`, a RUNBOOK step. ⇒ AT PRESENT THERE IS NO GATED PATH THAT CAN OBSERVE A
SCALING DEFECT. That is its own finding and it should be fixed before the performance items
are worked, or each will be argued from source counts as G22's was.

## Comments (1)

### 1 — 2026-07-29T17:28:22 · Jason Bowman

★ THREE INBOUND 'blocks' EDGES RETYPED TO relates-to, 2026-07-29 — AND THE LINK IS RECORDED HERE IN PROSE BECAUSE relates-to DOES NOT SURVIVE bd export (measured: 3 links live in the DB, 0 in .beads/beads.jsonl, against a positive control of 223 parent-child rows in the same file).

THE THREE BEADS THAT CITE THIS ONE AS A PREMISE — den-hoag-2rh, den-hoag-qxz, den-hoag-yl3 — WERE ALL FORMALLY
BLOCKED BY IT. None of them was waiting on it. qxz takes its ~7000-cell target figure FROM this bead; yl3 was
dispatched to test a hope stated here; 2rh is the owner directive that cites it. THE BEAD THAT SUPPLIES YOUR
PREMISE IS NOT THE BEAD THAT GATES YOU — and this bead's own first line says 'STANDING CONSTRAINT … This is a
TARGET, not an aspiration', so nothing blocking on it could ever have cleared. qxz was IN PROGRESS with an agent
working it while formally blocked by a bead with no completion condition.

★★ AND THE STRUCTURAL NOTE, WHICH IS THE FIXABLE HALF: THIS BEAD CONFLATES A STANDING CRITERION WITH A COMPLETABLE
WORK LIST. The criterion — 'den must scale to thousands of hosts' — has no completion condition and should stay
visible permanently. The work list — re-price G22 (4kh.53.49), re-price G20 (4kh.53.47), re-price §0.2/D1
(4kh.53.3) — is ordinary work that can close. Because they are one bead, the bead's closability is ambiguous, and
anything downstream inherits that ambiguity rather than a date. ⇒ IF THIS IS SPLIT, the criterion keeps this id and
the three re-pricings become children; then a bead may legitimately block on a re-pricing and never on the target.
NOT DOING THAT UNILATERALLY — it is an owner-stated constraint and the split is a judgement about intent, not a
graph-hygiene fix. Filed as a note, not a plan. See den-hoag-efz for the general defect and the sweep that found
these three.
