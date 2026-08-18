# den-hoag-4kh.53.49 — [G22] [gen-product] firstSeenBy is O(N^2) toJSON calls on den-hoag live cells path — a 200-cell fleet does 40,000 where 200 would do

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.49` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:12:11Z by Jason Bowman |
| last updated | 2026-08-08T03:43:53Z |
| closed | 2026-08-08T03:43:53Z |
| close reason | Closed |
| description bytes | 1425 |
| notes bytes | 4886 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ ARGUED, AND THIS ONE IS ON DEN-HOAG'S LIVE BUILD PATH.
`gen-product/lib/membership.nix`: `firstSeenBy = keyFn: xs: foldl' (acc: x: if elem (keyFn
x) (map keyFn acc) then acc else acc ++ [ x ]) [ ] xs;`
★ `map keyFn acc` IS RECOMPUTED FOR EVERY ELEMENT, and `keyFn` here is `fullCellId def` =
`toJSON (keyTuple ...)`. ⇒ ENUMERATING N CELLS COSTS O(N^2) toJSON CALLS -- A 200-CELL
FLEET DOES 40,000 WHERE 200 WOULD DO.
LIVE FOR DEN-HOAG: `fleet.nix` builds `relations`, so `enumerateMembers` takes the
`relationsCoverAll` branch -> `joinEnumerate` -> `firstSeenBy`. EVERY `product.cells` CALL
PAYS IT (three call sites).
★ SAME SHAPE TWICE MORE ON THE PATH THE MODULE HEADER ADVERTISES AS THE CHEAP ONE:
`membership.nix` rebuilds the key list PER CALL, and `relationMatch` does it PER RELATION
-- WHICH DEN-HOAG HITS, since its membership is relations-based. `conjoin` NESTS TWO MORE,
so each `restrict o restrict` MULTIPLIES AGAIN.
RESOLUTION: hoist the key sets OUT of the per-call closures into the normalized restriction
record; replace `firstSeenBy` with `prelude.dedupByKey` (DROP-IN -- cell ids are never null).


SUPERSEDED-CLOSE 2026-08-08 (backlog audit, verified at source): FIXED UPSTREAM — firstSeenBy no longer exists in gen-product lib/ at cfebc55; linear firstSeenById (membership.nix:108) replaced it at c3b8f14; old idiom 0 hits w/ live control foldl 5 files; den-hoag-8pbq already recorded CLOSE AS FIXED.


## Notes


────────────────────────────────────────────────────────────────────────────
★ CONFIRMED BY MEASUREMENT 2026-07-29 -- REAL, ON THE LIVE PATH, WORTH FIXING. AND THE
BEAD'S SCALE CLAIM IS ~3x HIGH IN TWO INDEPENDENT WAYS.

MEASURED: `firstSeenBy(toJSON)` nrPrimOpCalls 1,478 -> 5,453 -> 20,903 -> 81,803 across
N=50..400. QUADRATIC, confirmed. `dedupByKey` on the SAME input is LINEAR (253 -> 2,003).
★ SO HERE `dedupByKey` IS THE RIGHT FIX -- the toJSON term DOMINATES and O(1) membership
removes it. Note this is the OPPOSITE conclusion to G20 (closed as refuted, where
`dedupByKey` measured 272x WORSE): the two beads proposed the same remedy for different
input shapes and only one of them is right. THE REMEDY IS NOT TRANSFERABLE BETWEEN THEM.

★★ TWO CORRECTIONS TO THE FILED NUMBERS, both mine to carry:
1. THE COST IS N(N-1)/2 + N, NOT N^2. At N=200 the true figure is 20,100, NOT the 40,000
   this bead states.
2. ★ THE CORPUS IS NOT 200 CELLS. Measured on the main tree: 10 host files x 7 registry
   users = 70 UPPER BOUND, before `env-users` filters by accessGroups.
⇒ AT THE REAL N=70: 2,485 toJSON CALLS AGAINST 70 -- A 36x RATIO, NOT 100x.
VERDICT: worth fixing, at ~2,400 AVOIDABLE toJSON CALLS PER FLEET EVAL, not 40,000.

★ WHERE THE MEASUREMENT IS BOUNDED, STATED BY THE MEASURER: the ci suite showed
`firstSeenBy` MAX N=3, and the parity corpus arm MAX N=2. ★ NEITHER BOUNDS THE REAL FLEET
-- ci has no large fleets, and parity's EDGE arm does not force the full cell enumeration
(the same limitation measured earlier tonight: the full-fleet content gate lives in
`ship-gate.nix`, a RUNBOOK step outside `parity#tests`). ⇒ THE N=70 FIGURE IS DERIVED FROM
SOURCE COUNTS, NOT OBSERVED IN A RUN. Observing it requires the ship-gate path.
That is the second time tonight that `parity#tests` has been shown structurally unable to
witness a corpus-scale fact.

INSTRUMENT NOTE: NIX_SHOW_STATS operation counts on a plain file, which sidesteps the
345 ms flake-eval floor that defeated the earlier attempt -- `cpuTime` stayed flat at
~0.007 s across every N, so WALL-CLOCK PROVES NOTHING HERE and the counters are the signal.
Positive control: a genuinely linear dedup measured exactly 2x per doubling.
★ AND THE WORKTREE TRAP FIRED AGAIN: the first attempt to locate the user registry hit
`.worktrees/media-stack/` and was nearly taken as the answer. Main tree: 8 user files,
7 registry entries.


★★★ THE SCALE CORRECTION IS MINE TO CARRY, AND IT INVERTS THE DOWNGRADE ABOVE.
OWNER, 2026-07-29: **den must scale to THOUSANDS OF HOSTS.**
I corrected this bead's figure DOWNWARD (40,000 -> 2,485) using TODAY'S CORPUS SIZE of ~70
cells and recorded that as the answer. N here is CELLS = hosts x users, and the cost is
N(N-1)/2 + N `toJSON` calls on the LIVE path:
    today   N ~ 70     ->  ~2,485 toJSON calls
    target  N ~ 7,000  ->  ~24,500,000 toJSON calls
⇒ ★ THE SAME DEFECT IS A NUISANCE TODAY AND A CATASTROPHE AT TARGET -- and my 'correction'
made it look SMALLER at exactly the moment the target makes it four orders of magnitude
LARGER than the number I replaced.
★ THE ERROR SHAPE, worth naming: I re-priced a QUADRATIC using the CURRENT value of its
growth variable and reported the result as the finding's size. A quadratic's cost is not a
number, it is a FUNCTION -- and quoting it at one point, without saying which point, reads
as a bound.
⇒ RAISE THE PRIORITY. `dedupByKey` remains the RIGHT fix here (measured: linear on this
input, and the toJSON term dominates) -- note that is the OPPOSITE of G20, where the same
remedy measured 272x worse. Re-derive the target-scale figure properly and state the
variable, not a point value. Standing constraint: den-hoag-4kh.53.74.


════════════════════════════════════════════════════════════
★ APPENDED 2026-08-06 (the note above this line is the ORIGINAL 2026-07-29 measurement, restored after an accidental --notes overwrite; recovered from .beads/issues.jsonl).
════════════════════════════════════════════════════════════
MEASURED 2026-08-06: this bead named the RIGHT site and the defect is FIXED. Per-revision census of gen-product lib/membership.nix — quadratic foldl+elem present at f2c46d5/c265fee/01443aa, renamed to firstSeenById and rewritten with a listToAttrs index at c3b8f14 (2026-07-30, ancestor of cfebc55, verified by git merge-base --is-ancestor). A proposal to re-site this bead to isMember is REFUTED: re-siting would keep an open bead pointed at a discharged defect and drop the fix from the record. ⇒ CANDIDATE DISPOSITION: CLOSE AS FIXED at c3b8f14 (owner's call). Separately and still open: isMember's c2 branch calls relationMatch, which rebuilds pairKeys on EVERY call while isMember runs per candidate — that is a DIFFERENT, unfiled quadratic, and it is the branch den-hoag actually takes if its membership is relations-based (quoted from this bead, not independently re-verified).

## Comments (1)

### 1 — 2026-07-30T05:25:31 · Jason Bowman

★★ THE EXACT MECHANISM AND ITS SHARE, measured (qxz attribution, 2026-07-30, lib=364092a): firstSeenBy (gen-product membership.nix:93) recomputes keyFn over the WHOLE accumulator at every fold step — n(n+1)/2 keyFn calls for n elements, keyFn = fullCellId at 10 calls each. On the node-enumeration path n = H·U joined cells PER SLICE and den-hoag slices once per host, so firstSeenBy owns EXACTLY the 5U²·H³ term of the qxz law — at target (1000,7) that is 2.45e11 of the 2.94e11 total, ~83% of the whole catastrophe. Counterfactual with a seen-set dedup: the 5U² term VANISHES (H³ coefficient becomes exactly 7U, the join's share). This bead's 'O(N²) toJSON calls' framing under-described it — the quadratic is in keyFn applications regardless of key encoding, and its live N is per-slice joined cells, not fleet cells. The 4kh.53.74 re-price this bead demanded is now DONE with the exact law; the fix design goes through the gate with the qxz leads.
