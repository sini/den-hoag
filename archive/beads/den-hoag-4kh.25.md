# den-hoag-4kh.25 — [kernel] placeSlice duplicated at nest.nix:32 and output-modules.nix:441; nestAtPath cited by 2 tests + REFERENCE.md but absent from lib/

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.25` |
| status at evacuation | closed |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:08:58Z by Jason Bowman |
| last updated | 2026-07-31T01:33:04Z |
| closed | 2026-07-31T01:33:04Z |
| close reason | FIXED at 92a9e58 — the FIRST WORKTREE-INTEGRATED landing (branch wt/4kh25 at 38b3b6c, rebased clean onto the moved main, merge-gate suite 2067/2089 + parity 71/71 on the rebased branch, ff-merged). DEDUP: the two placeSlice definitions were ETA-EQUIVALENT, not divergent (sole difference the eta-expansion of the mapped function; same edge threaded to both — verified through the DI chain) — one definition survives at lib/nest.nix (2-dep engine; the reverse would invert the stratum), consumed by the output fold via a new nest arg along the existing DI chain; core-to-core, boundary guard untouched; deliberately NOT widened onto the internal seam. Exactly 1 definition in lib/ after. THE BEAD'S OWN FRAMING CORRECTED (E4 answered via git log -S): nestAtPath was DELIBERATELY RETIRED at 7d28af8 when gen-edge exported setAttrByPath — its live successor is edge.setAttrByPath, NOT placeSlice (different arities: single-value attr-path wrap vs the list map over it); REFERENCE.md's slash-pairing conflated two primitives. All three citations were prose (both tests define their own local twins with a stated non-circularity justification — kept, name and all: a local definition describing itself, not a citation); REFERENCE.md now sites placeSlice alone over gen-edge's setAttrByPath, identical by construction not by twin-agreement. File spread 8-not-3 accounted: the DI threading chain (2 files) + a direct importer of output-modules that would otherwise hard-fail on the new arg + the two false-citation test files. BONUS: bead item (3) freeformProbe = 0 verified with control (freeformAbsorber 3). REGISTER HAZARD self-flagged by the writer with ordering-robustness reasoning recorded: promoting placeSlice to an export is safe against 4kh.16's fold retirement — the surviving home (nest.nix's own content arm) outlives the retiring consumer. REVIEW CANDIDATE noted, not filed: placeSlice may belong upstream in gen-edge as the list twin of setAttrByPath — a gen-lib change needing its own spec under the push gate. |
| description bytes | 1998 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED DEFECT — LIVE DUPLICATION, PLUS THREE DOCUMENTS CITING A SYMBOL THAT DOES NOT EXIST.

(1) `placeSlice` HAS TWO IMPLEMENTATIONS with the same body:
      lib/nest.nix:32
      lib/attributes/output-modules.nix:441
      body both sides: `if at == [ ] then slice else map (edge.setAttrByPath at) slice`
    plus 2 local test twins.

(2) `nestAtPath` HAS ZERO OCCURRENCES IN lib/ — yet three documents describe it as live:
      ci/tests/nest-producers.nix:177   "output-modules.nix's `nestAtPath` is un-exported"
      ci/tests/materialization.nix:439  same sentence
      REFERENCE.md:480                  names it as a live primitive
    So two tests and the public reference explain a symbol the tree does not contain. A reader following
    REFERENCE.md finds nothing; a reader following the test comment mistrusts the test.

(3) The features memory's L2-EXTRACTION candidate says "shared place/freeformProbe primitive [5× dup]" —
    `freeformProbe` is 0 hits repo-wide. POSITIVE CONTROL, same run: `nestAtPath` IS found by the same
    predicate in the same run, so the instrument was working and the symbol is genuinely absent.

★ SEQUENCING NOTE, NOT A BLOCK: both `placeSlice` twins live inside folds that den-hoag-4kh.16 (bucket→query)
may DELETE. Extracting a shared primitive first risks PROMOTING A RETIRING CONSTRUCT — precisely the hazard
den-hoag-4kh.17 (the retiring-constructs register) exists to prevent. This is rework avoidance and COST ONLY;
it is recorded as a note on both beads, deliberately NOT as a dependency edge. The DOC half (2) is
independent of that sequencing and can land at any time.

OPEN QUESTION (E4, unresolved by the audit): whether the `nestAtPath` twin removal from lib/ was DELIBERATE
or a rename whose callers' comments were not updated. The commit was not located. Answer this before writing
the doc fix — the two answers produce different REFERENCE.md text.

PROVENANCE: memory-reconcile audit 2026-07-28, item C10. Untracked before this bead.


## Comments (1)

### 1 — 2026-07-28T06:06:27 · Jason Bowman

★ CORRECTION — MY SEQUENCING NOTE ON THIS BEAD WAS FALSE AT HEAD. THIS IS NOT BLOCKED AND NEVER WAS.

I recorded that both `placeSlice` twins 'live inside folds den-hoag-4kh.16 may delete', so extracting a shared primitive first risked promoting a retiring construct. RE-MEASURED at HEAD by the bucket-design agent: NEITHER TWIN IS INSIDE A FOLD.
  lib/attributes/output-modules.nix:441 is a TOP-LEVEL let, used at :599 inside `remapOver` — the ROUTE path, which the bucket design's decision R leaves untouched.
  lib/nest.nix:32 is a TOP-LEVEL let in the nest-mode engine, used at :169 — nothing to do with class content.
⇒ The bucket-to-seed-query design does NOT remove this duplication, promotes nothing retiring, and imposes no ordering. THIS BEAD CAN LAND AT ANY TIME, IN EITHER ORDER.

★ HOW I GOT IT WRONG, since the shape recurs: I inferred 'inside a fold' from PROXIMITY — both symbols live in files the bucket work touches — and never opened the call sites. A sequencing note is a CLAIM ABOUT A DEPENDENCY and needs the same evidence as any other claim. Mine had none, and it would have delayed independent work for a reason that does not exist. The cost of a false blocker is invisible: nobody reports the work they did not start.
