# den-hoag-4kh.46 — [kernel] the shipped supportedness guard aborts on ANY enrich value containing a lambda — Nix == is false for distinct closures; ec6ba23 HELD UNPUSHED

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.46` |
| status at evacuation | closed |
| priority | P0 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T07:40:12Z by Jason Bowman |
| last updated | 2026-07-28T11:09:01Z |
| closed | 2026-07-28T11:09:01Z |
| close reason | Closed |
| description bytes | 4279 |
| notes bytes | 0 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ MEASURED REGRESSION IN `ec6ba23` — THE SUPPORTEDNESS GUARD REJECTS WELL-FORMED FLEETS. COMMIT IS HELD
UNPUSHED. DO NOT PUSH UNTIL RESOLVED.

MECHANISM: `supported = published == converged`. Nix's `==` is FALSE FOR ANY TWO DISTINCT CLOSURES.
`converged.k` and `published.k` come from two DIFFERENT `enrichAt` calls, so any enrich value that IS a
lambda, or CONTAINS one anywhere in its tree, compares unequal and the guard aborts.

MEASURED, single policy, NO cycle, NO negation:
  fnPol = _: [ (d.enrich { key = "fn"; value = (x: x + 1); }) ];
  at a40cc96 → exit 0, keys ["__entry","fn","node"], forcing `.fn 41` gives 42
  at ec6ba23 → ABORT
BLAST RADIUS at ec6ba23: a nested attrset `{ mod = { pkgs, ... }: {...}; n = 5; }` → ABORT. A list
`[ 1 (x: x) ]` → ABORT. A plain `{ a = 1; b = "two"; }` → exit 0. So: ANY VALUE CONTAINING A LAMBDA ANYWHERE.
★ AND THE MESSAGE MISDIAGNOSES IT — it names the key and its writer, then asserts a negative-edge cycle THAT
DOES NOT EXIST. A user hits an abort blaming a construct they did not write.

WHY NOTHING CAUGHT IT: every b1-supportedness fixture uses scalars or strings, and nothing in-tree enriches a
function today, so 1922/1922 and parity 71/71 are both green and both blind. But `d.enrich`'s `value` has NO
TYPE CONSTRAINT — proved by the a40cc96 arm above, where a function value evaluates and applies fine — and
`den.policies` is the user surface. A deferred module is the obvious thing to enrich with.
POSITIVE CONTROL ON THE COVERAGE CLAIM: `enrich` is den-hoag-native and absent from den v1 — 0 hits across
the den-configs corpus, with 1150 files matching `den.` in the same run. So corpus silence is expected and is
NOT evidence the surface is unused.

★ THIS NEEDS AN OWNER-LEVEL DECISION, NOT A PATCH. Two shapes:
  (a) CONSTRAIN enrich values to a comparison-total domain, and say so in `lib/errors.nix` — rejecting a
      function value FOR ITS OWN REASON, with its own named error, rather than as a false supportedness
      failure. This narrows a public surface.
  (b) MAKE `supported` COMPARE ON A COMPARISON-TOTAL PROJECTION, so incomparable values are excluded from the
      equality rather than failing it. This keeps the surface and weakens the guard on exactly the values it
      cannot judge — and the weakening must then be stated as a limit of the law, not hidden.
Under construction-over-repair, (a) makes the defect unrepresentable and (b) leaves a documented hole. Under
"improve the API rather than preserve it", (a) is defensible only if a function-valued enrich is genuinely
not meant to be expressible — which is an owner question about the surface, not an implementation detail.

SECOND, SMALLER GAP — A THIRD DISAGREEMENT ARM IS UNREPORTED (errs SAFE, under-names). `dropped ∪ drifted`
does not cover "key in `published`, NEVER in `converged`". The bare `ctx:` lambda form always fires and can
branch on VALUES, so `enrichAt converged` can fire a rule `enrichAt prev` did not. Measured with a `lateZ`
rule alongside a drift pair: it aborts, but names only `x`, and `z` appears in NEITHER clause.
And with both lists empty the message names NOTHING — no dangling punctuation, but no key either.

★ THE REMEDY SENTENCE IS A SPEC-LEVEL DEFECT, NOT AN IMPLEMENTATION ONE. The unconditional trailing clause
asserts "a policy whose guard reads the ABSENCE of a context key another policy writes forms a cycle through
a negative edge" — FALSE for the drift case and FALSE for the function-value false positive. It is inherited
VERBATIM from the gate-attested spec (`specs/2026-07-28-ctx-supportedness-design.md`, error builder :329-338),
so the spec must change with the code.

WHAT THE REVIEW CONFIRMED SOUND: spec fidelity is EXACT (token-diff of the extracted core against the impl
shows only nixfmt lambda breaking); the witness is real, with red 1918/1922 exit 1, exactly the four claimed
reds, ★ all four failing `got false, expected true` — i.e. NO ABORT OCCURRED, which is itself the proof they
fail for THIS guard's reason, since an earlier guard aborting first would have produced a false PASS; green
1922/1922 exit 0; parity 71/71; `checks.default` exit 0; kernel hygiene clean with positive controls.

PROVENANCE: independent implementation review of ec6ba23, 2026-07-28, before push.


## Comments (2)

### 1 — 2026-07-28T10:33:13 · Jason Bowman

★ OWNER RULING, 2026-07-28: COMPARE ON A COMPARISON-TOTAL PROJECTION. Option (b).

The guard keeps the surface and excludes incomparable values from the equality rather than failing on them; THE RESULTING HOLE IS A STATED LIMIT OF THE LAW, not a hidden one. `enrich` may still carry a function, a deferred module, or anything containing one.
THE REASONING, recorded because it decides similar cases later: A FUNCTION RE-DERIVED IDENTICALLY IS NOT AN UNSUPPORTED FACT. The law is about whether the fixpoint and the published delta AGREE; Nix's `==` is simply unable to answer that for closures, and answering 'they disagree' when the instrument cannot tell is a FALSE POSITIVE, not a conservative one. ⇒ THE EQUALITY WAS THE WRONG INSTRUMENT — THE VALUE WAS NEVER THE WRONG SHAPE. And narrowing a public surface to fix a guard is backwards: the guard exists to serve the surface.

WHAT THE IMPLEMENTATION OWES:
  1. A projection under which comparison is TOTAL, with the incomparable part named — say what is compared and what is not, in the source, citing theory rather than a bead key.
  2. ★ THE LIMIT STATED IN THE SPEC AS WELL AS THE CODE. specs/2026-07-28-ctx-supportedness-design.md is gate-VALIDATED and its error builder (:329-338) is attested — THE SPEC CHANGES WITH THE CODE. A guard that silently judges less than it claims is the documented-but-unenforced pattern this arc exists to remove.
  3. ★ THE ERROR MESSAGE'S TRAILING REMEDY SENTENCE MUST GO OR BE CONDITIONALISED. It asserts unconditionally that 'a policy whose guard reads the ABSENCE of a context key another policy writes forms a cycle through a negative edge' — FALSE for the drift case and FALSE for this false positive. It is inherited verbatim from the attested spec, so this is a spec-level fix.
  4. THE THIRD DISAGREEMENT ARM, while the message is being touched: `dropped ∪ drifted` does not cover 'key in published, NEVER in converged'. Errs SAFE (still aborts) but names nothing — measured with a `lateZ` rule, where the abort named only `x` and `z` appeared in neither clause.
  5. A WITNESS THAT WOULD HAVE CAUGHT THIS: a fleet enriching a function value, and one enriching a nested attrset containing one, both required to evaluate CLEAN. Red before the fix — measured to abort at ec6ba23 — and green after. ★ Every existing b1-supportedness fixture uses scalars or strings, which is exactly why 1922/1922 and parity 71/71 were both green and both blind.
⇒ ec6ba23 STAYS UNPUSHED until this lands. The law is right and the witness is real; it simply rejects fleets it has no business rejecting.

### 2 — 2026-07-28T11:09:01 · Jason Bowman

★ FIXED AND PUSHED — 6f472d3, alongside ec6ba23 which is now also pushed. Verified independently by the orchestrator with exit status captured directly: ci 1933/1933 EXIT=0, parity 71/71 EXIT=0.

THE PROJECTION, per the owner's ruling: a TAGGED UNION with a single-key wrapper, so no value can forge another's projection — a user's `{ fn = …; }` projects to `{ attrs = { fn = …; }; }`.
  COMPARES: int/float/string/path/bool/null; lists and attrsets ELEMENTWISE TO ANY DEPTH; derivations by `outPath` — ★ which is `==`'s OWN rule, INHERITED rather than invented. So a value that merely CONTAINS a lambda is still compared FIELD BY FIELD; only the lambda itself is exempt.
  DOES NOT COMPARE: a function's BODY. Two functions agree unless their FORMALS differ.
  ★ AND THE HOLE IS WITNESSED, NOT MERELY DESCRIBED — `test-limit-of-the-law-a-lambda-body-is-not-compared` publishes a closure answering 3 while the fixpoint state carried one answering 2, and asserts CLEAN. The limit is a test, so it cannot rot into a claim.
`agree = a: b: a == b || project a == project b` — a fully comparable value costs exactly what the `==`-only law cost it; the projection is paid only where equality already returned false.

★ RESTRUCTURING THE LAW TO EXPOSE THE LIMIT SURFACED A FOURTH ARM I NEVER NAMED. I flagged the third (a key derived only at the converged context, never in state). The agent found a FOURTH: AN INHERITED KEY OVERWRITTEN DURING ITERATION AND INERT AT CONVERGENCE. `dropped` was blind (the published set still has the key — the base's own value) and the drifted scan was blind (it scanned `attrNames added`, and the key is not in `added`). MEASURED AT ec6ba23: IT ABORTS NAMING NOTHING AT ALL and asserts the negative-edge remedy anyway. The law is now three named arms — `dropped` / `unclosed` / `drifted` — each naming its key AND its writer AND carrying its own remedy. `unclosed` keys are exactly what `provenance` cannot attribute (it re-runs the ITERATION), so it falls back to `owners`, already forced for B1 precedence.

★★ ANTI-VACUITY — THE REAL RISK, AND IT IS DISCHARGED PROPERLY. With `supported` stubbed TRUE and the arms still forced: NINE REDS. The four originals plus five new abort guards. ★ ALL NINE ARE ASSERTION FAILURES, ZERO EVALUATION ERRORS — 'got false, expected true', i.e. NO ABORT OCCURRED. An earlier guard firing first would have SATISFIED the assertion and produced a false PASS, so the direction of failure proves each fails for THIS law's reason. THREE of the nine carry a function value in the same context as the disagreement, and ONE puts the disagreement INSIDE the function-carrying value, with a differential control where the same value SHAPE without drift evaluates clean. The projection is not loose enough to admit a genuine disagreement.

COMPLEXITY — ★ STRICTLY LESS FORCING THAN ec6ba23, not merely neutral. Agreement is decided per TOUCHED key (`added ∪ (converged \ base)` — precisely the keys whose two sides are distinct values, which ec6ba23's `==` was descending into anyway), and untouched keys settle under ONE `removeAttrs`-restricted `==` at pointer-check price. `project` runs only where `==` already answered false, one traversal per side, O(size of forced value), each value visited once.
MESSAGE TEXT IS UNWITNESSABLE IN-SUITE (no `expectedError` through checks.default — den-hoag-9mo) so the three arms were verified BY HAND: dropped → `a`/`negA`, unclosed → `z`/`lateN`, drifted → `x`/`driftX`. The unconditional trailing remedy sentence is GONE from code AND spec; an empty clause now renders no remedy.
SPEC UPDATED AND PUSHED (752b2a9): new core hash 7c978b18cdb82243e713a92355153b51, error builder db944941e9bd66a4aa1e371825b5faf8. ★ The recipe was reproduced against the PREVIOUS revision's own recorded values BEFORE recomputing — so the new numbers are anchored to a verified method, not to a fresh guess. Every fenced fragment verified byte-present in the shipped source: the spec blocks are now the SHIPPED TEXT, not a proposal. §8 and §9.2 figures NOT re-measured and stated as such.
