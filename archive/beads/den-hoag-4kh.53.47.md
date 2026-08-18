# den-hoag-4kh.53.47 — [G20] [gen-prelude] the dedupByKey remedy is REFUTED (quadratic in a different variable) — but "negligible at den-hoag scale" rests on a ci census that does not bound the real fleet

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.47` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | (none) |
| created | 2026-07-29T00:12:11Z by Jason Bowman |
| last updated | 2026-08-12T08:09:07Z |
| closed | 2026-08-12T08:09:07Z |
| close reason | Discharged as verification by the 34zp implementation landing (gen-prelude 039ca01+db4e8fc, published 59f0d71): unique's compounded superlinear factors retired by the ruled guarded two-path (string path linear; else-branch the incumbent verbatim per the certified expression-identity); dedupByKey linear. The bead's own operating-point figure (1,179 at N=800/K=26; 272x vs old dedupByKey) reproduced to three significant figures twice in the chain, five weeks apart, before retirement. Its listToAttrs direction was adopted by the spec (cited at R§3.2's lineage). |
| description bytes | 1702 |
| notes bytes | 6232 |
| comments | 1 |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ ARGUED, HIGHEST MULTIPLIER IN THE ECOSYSTEM, and PERFORMANCE IS A DEFECT here by
standing rule.
`gen-prelude/lib/default.nix`: `unique = foldl' (acc: x: if elem x acc then acc else acc ++
[ x ]) [ ];`
TWO COMPOUNDED SUPERLINEAR FACTORS: `elem x acc` is a LINEAR SCAN PER ELEMENT, and
`acc ++ [ x ]` COPIES THE ACCUMULATOR ON EVERY APPEND.
★★ THE SAME FILE ALREADY CONTAINS THE LINEAR ALGORITHM 75 LINES ABOVE -- `dedupByKey`,
which uses an ATTRSET for membership (`seen ? ${k}`, O(1)). For string inputs `unique` IS
EXACTLY `dedupByKey (x: x)`.
★ ALL 14 DEN-HOAG `prelude.unique` CALL SITES PASS STRINGS -- kind names, stratum names,
node ids, id_hashes -- INCLUDING PER-NODE CODE: `resolved-aspects.nix` (`ancestorIds`, PER
NODE), `staged-resolution.nix` (per attachment), plus default.nix x3, edges.nix x2,
concern-policies x2, declarations, projects x2, class-modules, claim-accessor.
RESOLUTION: `unique` delegates to `dedupByKey (x: x)` for the string case, or the library
DOCUMENTS it as the general-value fallback and STEERS callers.
★ TODAY THE NAME EVERYONE REACHES FOR IS THE SLOW ONE -- the D3 shape in a different dress.
CAVEAT: no complexity claim in the audit's §9 was measured on a fleet; the asymptotics are
unambiguous from source but the cost at den-hoag's scale is unquantified.

★ SPEC COVERAGE 2026-08-11: the unique-retirement spec (papers specs/2026-08-11-...-spec.md @ 6b3c595,
gate-exited) cites and REPRODUCES this bead's operating-point figure (shipped 1,179 at N=800/K=26,
272.07x vs dedupByKey — three significant figures, five weeks and a different agent apart) and adopts
its listToAttrs direction for the linear path. Closes as VERIFICATION at implementation landing.


## Notes


────────────────────────────────────────────────────────────────────────────
★★ MEASURED 2026-07-29, AND THE BEAD'S RESOLUTION IS REFUTED. THE NAMED FIX IS 272x
WORSE AT DEN-HOAG'S ACTUAL INPUT SHAPE.

INSTRUMENT: `NIX_SHOW_STATS=1 nix-instantiate --eval --strict` on a PLAIN FILE (no flake).
`list.elements` counts the `++`/`tail` copying, `nrOpUpdateValuesCopied` the `//` copying,
`nrPrimOpCalls` the toJSON. Deterministic, and it SIDESTEPS THE 345 ms FLAKE FLOOR that
defeated the earlier attempt -- a plain-file eval is ~7 ms and ★ `cpuTime` STAYED FLAT AT
~0.007 s ACROSS EVERY N, so wall-clock proves nothing here and the counters are the signal.
POSITIVE CONTROL: a genuinely linear dedup measures 303 -> 603 -> 1203 -> 2403 across
N=100..800, EXACTLY 2x PER DOUBLING. The instrument can show linear, so a 4x is a real
quadratic and not an artefact.

THE ASYMPTOTIC IS REAL: `unique` on ALL-DISTINCT input goes 5,252 -> 322,002 list-elems
across N=100..800. Confirmed.

★ BUT DEN-HOAG NEVER PASSES THAT SHAPE. `gen-prelude.unique` instrumented over the WHOLE
ci suite:
    11,418 calls   min N=0   median N=1   p99=10   MAX N=24
    sum(N)=12,104  sum(N^2)=48,478   ONLY 7.8% OF CALLS HAVE N>1
Total quadratic work across 1,937 tests is 48K element-comparisons against 12K for a
linear implementation. REAL, AND NEGLIGIBLE.

★★ AND THE PROPOSED FIX IS DIRECTIONALLY WRONG. `dedupByKey`'s membership is O(1), BUT ITS
RECURSION CALLS `builtins.tail`, WHICH COPIES -- so it is quadratic IN LIST LENGTH
REGARDLESS OF DISTINCT COUNT, where `unique` is quadratic only IN DISTINCT COUNT. At
den-hoag's actual shape (few distinct; K=26, N=800):
    unique       1,179 list-elems
    dedupByKey   320,779 list-elems   ★ 272x WORSE
and `dedupByKey` additionally adds quadratic `//` copying (73 vs 0) that `unique` does not
have.
⇒ THE TWO ARE QUADRATIC IN DIFFERENT VARIABLES, AND THE BEAD ASSUMED ONE DOMINATES BECAUSE
IT READ "O(1) MEMBERSHIP" AND STOPPED. The audit called this "the highest multiplier in the
ecosystem"; measured, it is the smallest of the three and its remedy is a regression.

VERDICT: CLOSE AS MEASURED-NOT-WORTH-FIXING, and record that the named fix must not be
applied for string inputs. If anything is ever done here it is the `listToAttrs` shape, NOT
`dedupByKey`.
★ THE GENERAL LESSON, and it is why spec-before-development covers one-line gen-lib changes:
"the linear algorithm sits 75 lines above" was TRUE AS A STATEMENT ABOUT ASYMPTOTIC CLASS
AND FALSE AS A STATEMENT ABOUT THIS CONSUMER. An asymptotic argument names a growth rate; it
does not name the VARIABLE, and swapping primitives on an unmeasured input shape can invert
the answer.

────────────────────────────────────────────────────────────────────────────
★★ REOPENED BY THE ORCHESTRATOR. THE CLOSURE ABOVE WAS RECORDED WITH LESS SCRUTINY THAN
THIS ARC APPLIES TO ITS GATES, AND ONE OF ITS TWO CLAIMS DOES NOT SURVIVE THE DIFFERENCE.
The closure is NOT retracted wholesale -- it is SPLIT, because its two claims have very
different strength.

★ CLAIM 1 -- "THE NAMED FIX IS DIRECTIONALLY WRONG" -- STANDS. The mechanism is
STRUCTURAL and shape-independent: `dedupByKey`'s recursion calls `builtins.tail`, WHICH
COPIES, so it is quadratic IN LIST LENGTH while `unique` is quadratic IN DISTINCT COUNT.
Two implementations quadratic in DIFFERENT VARIABLES. That is checkable by reading and does
not depend on any input distribution. ⇒ DO NOT APPLY `dedupByKey` HERE ON THE STRENGTH OF
"O(1) MEMBERSHIP". That conclusion is safe.
★ BUT THE 272x FIGURE IS MEASURED AT K=26, N=800 -- A SHAPE THE SAME REPORT SAYS DOES NOT
OCCUR (median N=1, max N=24). It DRAMATISES a real mechanism at an operating point that is
not den-hoag's. At N=24 the gap would be far smaller. THE NUMBER SHOULD NOT BE CITED AS
DEN-HOAG'S EXPOSURE.

★★ CLAIM 2 -- "NEGLIGIBLE AT DEN-HOAG'S SCALE" -- IS UNESTABLISHED, AND THE REPORT ITSELF
CONTAINS THE REASON.
The distribution (11,418 calls, median N=1, max N=24, 7.8% with N>1) WAS MEASURED OVER THE
ci SUITE. ★ THE SAME REPORT STATES, FOR G22, THAT ci HAS NO LARGE FLEETS AND DOES NOT BOUND
THE REAL FLEET -- and does not carry that limitation here, THOUGH BOTH DISTRIBUTIONS COME
FROM THE SAME SUITE.
And `unique`'s call sites are not shape-neutral: `resolved-aspects.nix` `ancestorIds` runs
PER NODE and `staged-resolution.nix` PER ATTACHMENT. Those scale with fleet size, which is
exactly what ci does not exercise.

★★★ AND THE PRECEDENT IS EXACT, FROM THE SAME AGENT HOURS EARLIER: the "10 empty-recoveries,
ALL LEGITIMATELY INERT" claim was WITHDRAWN BY ITS OWN AUTHOR because THE INSTRUMENT COULD
NOT HAVE SEEN THE COUNTEREXAMPLE IT WAS BEING USED TO RULE OUT -- a ci-suite census standing
in for a real-world population. CLAIM 2 IS THE IDENTICAL SHAPE. Recorded at den-hoag-9xo.72
and den-hoag-4kh.20.

★ AND THE EVIDENTIARY STANDARD DIFFERED, WHICH IS THE ORCHESTRATOR'S ERROR TO OWN. Every
gate that earned trust tonight was INDEPENDENT, FRESH-CONTEXT, ADVERSARIALLY FRAMED, and run
by someone WHO DID NOT OWN THE CONCLUSION -- and two of them killed orchestrator designs. This
measurement was SELF-DIRECTED BY THE IMPLEMENTER, non-adversarial, and its conclusion REMOVES
WORK FROM ITS OWN QUEUE. That is not disqualifying and the work was careful; it is a DIFFERENT
STANDARD, and it was recorded as settled anyway.

WHAT IS OWED TO CLOSE THIS PROPERLY:
1. The real fleet's `unique` input distribution, measured where fleet scale is actually
   reached. ★ ci and `parity#tests` ARE BOTH KNOWN INSUFFICIENT -- the full-fleet content gate
   is `ship-gate.nix`, a RUNBOOK step, which is the third time tonight that path has been the
   only one able to witness a corpus-scale fact.
2. Specifically the per-node call sites (`ancestorIds`, the staged-resolution per-attachment
   site), not the aggregate -- an aggregate median over 11,418 calls hides a tail that lives
   entirely in the per-node ones.
3. An INDEPENDENT measurer. Not the agent whose queue the answer clears.
If claim 2 survives that, close again on the same reasoning. If it does not, `unique` is a
live performance defect on the per-node path and the standing rule applies: performance
issues are defects, filed and tracked like wrong answers.

## Comments (1)

### 1 — 2026-07-29T03:53:52 · Jason Bowman

★★ REFRAMED BY MEASUREMENT 2026-07-29: **G20 IS GATEABLE TODAY.** This bead has been carried as 'the remedy is refuted (272x) and negligibility is unestablished'. A gate reviewer measured the REAL gen-prelude unique — fetched from den-hoag's OWN LOCK — across the full counter set:
    n:                 50    100    200    400
    nrFunctionCalls:  153    303    603   1203    <- LINEAR. BLIND.
    nrPrimOpCalls:    110    210    410    810    <- LINEAR. BLIND.
    list.elements:   1399   5274  20524  81024    <- QUADRATIC, q -> 1.988. VISIBLE.
⇒ THE QUADRATIC IS OBSERVABLE. Not by nrFunctionCalls, which is what a scaling witness would naturally declare — and what BOTH shipped arms of the witness spec DO declare — but by , which the same eval already produces.
★ AND THE CALL SITES ARE ON THE MEASURED-CUBIC PATH: ~10 prelude.unique sites in the kernel, including lib/staged-resolution.nix's attachmentsOf and lib/edges.nix's entityInstances / fillGraph, i.e. the cell path den-hoag-qxz measures at exponent 2.98.
⇒ ★ THE OPEN QUESTION ON THIS BEAD CHANGES. It was 'is it negligible' — unanswerable without an instrument. It is now 'WHICH COUNTER, AND AT WHICH CALL SITE'. The allocation half is gateable now; the COMPARISON half remains invisible to every counter (primop-internal work), which is den-hoag-qxz's §7.1 hole and is unfixable by any estimator.
★ NOTE WHAT THIS DOES NOT CHANGE: the 272x refutation of the dedupByKey remedy STANDS. Being able to SEE the defect says nothing about the fix, and this project has now twice shipped a remedy that was worse than the defect. Measure any replacement at den-hoag's real input shapes before proposing it — that is the standing bar on den-hoag-anv.
