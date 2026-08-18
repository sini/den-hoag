# den-hoag-4kh.42 — [perf] producesByName guard costs the FAN path +3.8% for a provably-empty residue — 18 of 19 configs take that path

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.42` |
| status at evacuation | open |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T06:18:53Z by Jason Bowman |
| last updated | 2026-07-28T06:18:53Z |
| description bytes | 1822 |
| notes bytes | 0 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED PERFORMANCE DEFECT — THE COMMON PATH PAYS FOR THE RARE PATH.

The producesByName trust guard (design at specs/2026-07-28-produces-declaration-trust-design.md) adds a
residue computation that the FAN PATH pays for and can never use.
MEASURED, and independently REPRODUCED by the re-gate reviewer: nrFunctionCalls 1,850,222 -> 1,920,222 on the
fan path = +3.8%, for a residue that is PROVABLY EMPTY on that path.

★ WHY THIS IS NOT A ROUNDING ERROR: the fan is the path taken by EVERY UNDECLARED VALUE-CONDITIONAL POLICY,
and 18 OF 19 den-configs DEFINE NONE OF THE FIVE KEYS the declared path needs. So essentially the entire
corpus runs the path that pays, to protect a path almost nothing takes. Under the standing rule that
PERFORMANCE IS A DEFECT AND NOT A TRADE-OFF, this is filed rather than absorbed into a disclosure bullet.

The spec DOES disclose it — one bullet — which is why this is a cost-allocation item and not a
correctness finding. C8 passed: no byte identity was purchased with complexity here.

GENUINELY OPEN, and the cheap answer may well be right:
  (a) price a variant that skips the residue when the declaration is absent (`produces = null`), so the fan
      pays nothing — note the fan ALREADY gets the equivalent check free by that same route, which is
      suggestive;
  (b) accept the 3.8% with the measurement recorded, if the branch costs more in complexity than it saves;
  (c) let it dissolve — if the gen-dispatch-layer construction (the C7-a gap) is taken instead, this cost
      may not arise at all, since the check would sit where the trust is rather than where the emission is.
Do NOT resolve this before the C7-a alternative is priced; (c) would make (a) wasted work.

PROVENANCE: re-gate of design 2, 2026-07-28. Reproduced by the reviewer, not inherited from the spec.


## Comments (2)

### 1 — 2026-07-28T06:36:01 · Jason Bowman

★ CORRECTION — THIS BEAD'S OPTION (a) RESTS ON A CLAIM OF MINE THAT IS HALF WRONG. Measured and corrected by the produces-r2 agent, 2026-07-28.

I WROTE: 'the fan ALREADY gets the equivalent check free by that same route (`produces = null`), which is suggestive.'
MEASURED: the fan is CLASSIFIED for free (gen-derive/lib/core/dispatch.nix:111), but THE CHECK IS VACUOUS, NOT FREE. `mkSlice` PRE-FILTERS on EVERY path (concern-policies.nix:267), so `res.actions` is SINGLE-GROUP BY CONSTRUCTION and dispatch's :113/:115 CAN NEVER FIRE — for the fan OR for the declared path. Nothing is being obtained for free; the containment check is simply unreachable on both.
⇒ The fan's totality does NOT come from a check. It comes from `assertCovered` plus full coverage — A THEOREM, not an empirical property.

★ THIS MAKES OPTION (a) SAFE FOR A BETTER REASON THAN I GAVE. Skipping the residue when the declaration is absent is sound because the fan's coverage is PROVED, not because some other check happens to catch it. A justification resting on 'the other path checks it too' would have been false and would have failed the first time someone asked which check.

AND IT SHARPENS THE COST ITSELF: the fan's +3.8% is REDUNDANT work, not merely misallocated. Dispatch already classifies fan actions at dispatch.nix:111 (`classify = declarations.stratumOf`, structural.nix:297), so post-core the fan classifies the same emissions TWICE.

A FOURTH OPTION, ORTHOGONAL TO (a)/(b)/(c), recorded not applied: `prelude.partition` removes one traversal on BOTH paths. Not applied because the design's core is hash-frozen; it belongs to whoever implements.
RESOLUTION REMAINS DEFERRED behind the gen-layer question — options (a) and (c) are not independent, so prescribing (a) now is discarded work if the gen-layer route is taken.

### 2 — 2026-07-28T06:52:04 · Jason Bowman

★ THE DEFERRAL REASON RECORDED ON THIS BEAD IS UNSOUND — corrected by the R2 focused gate, 2026-07-28.

I deferred resolution 'pending the gen-layer question', on the reasoning that options (a) and (c) are not independent and prescribing (a) now would be discarded work if the gen-layer route were taken.
MEASURED AGAINST THE SPEC'S OWN §5(d): that verdict is 'adopting (d) AS WELL AS §3 is coherent and is the recommendation for the gen side; on the den-hoag side §3 stands unchanged either way.' ★ UNDER THAT RECOMMENDED COMBINATION THE RESIDUE STILL RUNS ON THE FAN AND THE +3.8% DOES NOT DISSOLVE. Option (c) as I wrote it requires adopting (d) INSTEAD OF §3 — which §5(d) explicitly rejects, and which the gate separately established is impossible (D7's zero-rules case never reaches dispatch at all).
⇒ THE DEFERRAL RESTED ON AN OPTION THAT THE SAME ANALYSIS HAD ALREADY CLOSED. (c) is not live. This bead is therefore NOT blocked on the gen-layer question in the way recorded.

WHAT SURVIVES: option (a) — skip the residue when the declaration is absent — remains sound and is now sound for a STATED reason rather than an empirical one (the fan's totality is a theorem: assertCovered plus full coverage; see this bead's earlier correction). Option (b) accept-and-record remains available. The genuinely open question is narrower than I framed it: (a) versus (b), a complexity-versus-simplicity judgement on one branch, with no upstream dependency.
NEW, ORTHOGONAL TO BOTH: `prelude.partition` (gen-prelude/lib/default.nix:35,203) removes one traversal on BOTH paths. Recorded, not applied — the design's core is hash-frozen, so it belongs to whoever implements.
★ MEASURED FIGURES CONFIRMED INDEPENDENTLY by the gate: fan 1,850,222 → 1,920,222 = +3.784%; declared 630,224 → 660,224 = +4.760%, thunks +11.34%, env +5.53%. All arithmetic re-checked.
