# den-hoag-4kh.44 — [kernel] concern-policies.nix:11-12 asserts gen-dispatch validates declarations classify to their group — false for the declared path

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.44` |
| status at evacuation | closed |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T06:36:01Z by Jason Bowman |
| last updated | 2026-07-29T17:51:57Z |
| closed | 2026-07-29T17:51:57Z |
| close reason | EXPIRED by measurement with same-run positive controls (gen-lib triage slice, 2026-07-29). hat: the clone directory IS gen-dispatch. 4kh.44: the asserted header sentence was deleted by e6c8edc; the surviving gen-side defect is tracked as den-hoag-cvf. |
| description bytes | 1951 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED — A KERNEL FILE HEADER ASSERTS AN INVARIANT THAT IS FALSE ON ONE OF ITS TWO PATHS.

`lib/concern-policies.nix:11-12` states that gen-dispatch "validates that its declarations all classify to
that group."
MEASURED: FALSE FOR THE DECLARED PATH. `gen-derive/lib/core/dispatch.nix:104-107` SKIPS classify-validation
when `res.declared` — that is the trust this whole arc's design 2 exists to discharge. The header describes
the fan path's behaviour and states it as the file's general contract.

★ WHY THIS IS A DEFECT AND NOT A NIT: this file is KERNEL (`ci/tests/boundary.nix:37` names it), and the
header is what a reader consults to learn what the module guarantees. An invariant asserted in a kernel file
header, false on the path that carries the declaration mechanism, is the documented-but-unenforced pattern
the kernel-purity criteria name explicitly — in its worse form, since the text does not merely fail to
enforce the invariant, it asserts one that does not hold.
It also actively obstructs the fix: anyone auditing the declared path against this header concludes the
validation is already present.

RELATED, and the reason this surfaced: the design's own §9 cites gen-dispatch's trust comment, which points
at gen-resolve `lib/schedule.nix:52-110` as its analogy. That analogy ALSO fails — gen-resolve DOES discharge
its declared `stratum` against the equation's real readsAttrs cone. So the trust is justified in the comment
by an analogy to code that does the opposite, and re-asserted in den-hoag's kernel header as a fact.

ACCEPTANCE: the header states what is actually guaranteed on each path, or the declared path gains the
validation the header claims (which is design 2's core, at which point the header becomes true). Either way
the two must be made to agree, and whichever lands first should not leave the other stale.

PROVENANCE: produces-r2 redesign, 2026-07-28, found while writing the C7-a reuse scan. In no input.


## Comments (1)

### 1 — 2026-07-29T17:51:56 · Jason Bowman

★ EXPIRED — THE ASSERTED SENTENCE WAS DELETED FROM THE KERNEL HEADER. Measured at 7b53777 with TWO positive controls.
CLAIM: lib/concern-policies.nix:11-12 asserts gen-dispatch 'validates that its declarations all classify to that group'.
  git grep -in 'classify to that group\|all classify\|validates that its declarations' 7b53777 -- lib/concern-policies.nix
    -> 0 HITS. (The 3 repo-wide hits are lib/declarations.nix:380 and lib/errors.nix:158,165 — a DIFFERENT
    assertion, about STRATUM coherence, not about gen-dispatch validating group classification.)
  ★ CONTROL A, the predicate reaches the file: git grep -ic 'dispatch' 7b53777 -- lib/concern-policies.nix -> 16.
  ★ CONTROL B, the identical predicate DOES find the sentence at older revs: 222af84:lib/concern-policies.nix:12
    and c42df53:lib/concern-policies.nix:12 both give '# phase and validates that its declarations all classify to
    that group.' Already gone at 6f30460.
WHAT CHANGED: git log 222af84..6f30460 -- lib/concern-policies.nix -> e6c8edc 'feat(kernel): a policy declares what
it emits, and the kernel checks it'. The header now describes emits as a CHECKED contract and the false invariant
is gone — which satisfies this bead's stated acceptance ('the header states what is actually guaranteed on each
path').
★ THE UNDERLYING GEN-SIDE DEFECT SURVIVES AND IS SEPARATELY TRACKED AS den-hoag-cvf, measured STILL-LIVE in the
same run (dispatch.nix ~:102-107, the declared arm still skips classify-validation). CLOSING THIS DOES NOT LOSE IT.
