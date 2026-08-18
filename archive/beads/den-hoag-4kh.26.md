# den-hoag-4kh.26 — [meta] systematic re-anchor pass over cited sites — 3 of 5 sampled beads carried expired claims, ~54 unchecked

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.26` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:10:52Z by Jason Bowman |
| last updated | 2026-08-05T20:48:32Z |
| description bytes | 2173 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

SYSTEMATIC RE-ANCHOR PASS over cited sites in the bead graph. Filed because a sample of FIVE produced drift in
THREE, one of them total.

MEASURED 2026-07-28 (memory-reconcile audit), cited sites checked for 5 beads at HEAD a40cc96:
  den-hoag-7pt     sites RESOLVE EXACTLY (den-brackets.nix:41-46/:44/:66/:73/:92, bridge.nix:171)
  den-hoag-4kh.18  sites RESOLVE EXACTLY (default.nix:1074/:1083/:1098)
  den-hoag-4kh.16  EVIDENCE STALE — cites two retired symbols; re-anchored, see that bead
  den-hoag-9xo.9   MECHANISM FALSIFIED by the landed topology arc; re-grounded, see that bead
  den-hoag-9xo.8   ★ THREE OF THREE CITATIONS DRIFTED, plus a false "no change since" premise

⇒ 3 of 5 sampled beads carried at least one claim that no longer holds. THE OTHER ~54 OPEN BEADS ARE
UNCHECKED. At the observed rate that is a substantial body of work resting on expired citations, and the
failure is silent in the dangerous direction: a stale `file:line` reads as precision.

★ WHAT THIS PASS MUST NOT BECOME: a mechanical line-number refresh. The 9xo.8 case shows why — its line
numbers moved AND its premise expired AND its root cause closed upstream. Only one of those three is visible
to a line-number check. Each bead needs: do the sites resolve, does the mechanism still hold, and has any
cited upstream/commit-range claim expired.

METHOD NOTES, earned:
  - EXCLUDE `.worktrees/` on every search. Four worktrees exist and TWO are pinned at c0aa7be — the exact
    stale rev the old records cite, so a careless search will CONFIRM a stale claim from a stale tree.
  - A "no change since <rev>" claim is a measurement with a SILENT expiry; re-run the range, never read the
    sentence. Record ranges closed (`a..b`), not open-ended.
  - `grep A | grep B` is a single-line conjunction and Nix constructs are multi-line — see den-hoag-4kh.20.

BLOCKED ON the jsonl-comments defect: an audit that reads `.beads/beads.jsonl` as the record cannot see
comments, and corrections like the three above live IN comments. Re-anchoring against a lossy export would
re-introduce exactly what it is meant to remove.

PROVENANCE: memory-reconcile audit 2026-07-28, coverage section.


## Comments (1)

### 1 — 2026-07-28T05:39:28 · Jason Bowman

SCOPE REFINEMENT FROM AN INDEPENDENT MEASUREMENT — this pass should not assume uniform drift.

den-hoag-4kh.25 was re-checked at HEAD by the log-reconcile agent and has NO DRIFT: lib/nest.nix:32 and lib/attributes/output-modules.nix:441 both define `placeSlice` exactly as cited, and `nestAtPath` = 0 in lib/, exactly as the bead states.
⇒ The 3-of-5 drift rate that motivated this bead is real but is NOT uniform. Beads written recently and from direct measurement hold; the drifted ones (9xo.8, 9xo.9, 4kh.16) were older and carried INHERITED citations. Prioritise by AGE and by whether the bead's evidence was measured or inherited, rather than sweeping in id order.

ALSO: the standing 'exclude .worktrees/' rule now has a second, sharper justification recorded at den-hoag-d0g — 7 stale ref-audit worktrees across the gen repos, plus den-hoag's own 4 (two pinned at c0aa7be). A re-anchor pass that forgets the exclusion will CONFIRM the very citations it is meant to re-verify.
