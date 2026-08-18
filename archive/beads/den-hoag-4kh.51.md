# den-hoag-4kh.51 — [kernel] a cycle through a negative edge is admitted silently on the suppression path — measured live, while b1 aborts the identical shape; soundness rests on the pre-pass staging that is scheduled for retirement

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.51` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T22:20:01Z by Jason Bowman |
| last updated | 2026-08-05T20:48:34Z |
| description bytes | 7069 |
| notes bytes | 4032 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ MEASURED, LIVE, 2026-07-28. A cycle through a negative edge is ADMITTED
SILENTLY on the suppression path, while THE IDENTICAL SHAPE ABORTS on the
enrichment path. Same paper, same condition, two subsystems, opposite behaviour.

THE NEGATED READ. lib/compat/compile.nix gateSuppression:
    fn = ctx: if builtins.elem v1Name (ctx.suppressedPolicies or [ ])
              then [ ] else compiled.fn ctx;
Fires iff its own name is ABSENT from the set. A negative body literal. And the
`or [ ]` FAILS OPEN.

THE WITNESSES, built and run in scratch against the working-tree flake, native
surface, no repo writes:
    mutual  (A |-> not B, B |-> not A)  ->  suppressed-policies = ["B","A"]  NO ABORT
      positive control, same run: single non-cyclic suppressor -> ["B"]
    selfNeg (A |-> not A)               ->  suppressed-policies = ["A"]      NO ABORT
      negative control, same run: no suppressor -> []
Both are ABW Lemma 1's forbidden shape. Neither has a supported model: each
derived atom's sole justification is the other's absence, or its own.

★ AND WE ALREADY REJECT EXACTLY THIS, ONE SUBSYSTEM OVER.
ci/tests/b1-supportedness.nix carries test-self-negative-aborts AND
test-negative-cycle-aborts, both GREEN (suite 22/22 at this tree). The identical
shape on the suppression path is admitted in silence. The difference is not a
judgement about the two paths -- it is that the law was written for one of them.

★★ WHAT KEEPS IT SOUND TODAY IS STAGING, NOT STRATIFICATION -- AND THE STAGING IS
SCHEDULED FOR RETIREMENT. `suppress` facts are produced by the staged pre-pass
(fireExcludeAt, lib/staged-resolution.nix), injected onto root decls, delivered as
an inherited EDB fact. The pre-pass's own ctx (baseCtxOf / deliverCtxOf) is built
from prePassScopeRoots, FIXED BEFORE THE SUPPRESSIONS EXIST -- so during the
pre-pass the negative literal is evaluated against an EMPTY extension of the very
relation being computed. That is what makes the requirement hold.
⇒ RETIRING THE STAGED PRE-PASS CONVERTS AN ACCIDENTALLY-SOUND READ INTO AN
UNGUARDED SAME-STRATUM NEGATED READ. See den-hoag-4kh.18. Nothing in the tree
records that the pre-pass is load-bearing for ABW condition 2, and this is a
SECOND, INDEPENDENT reason its retirement needs a condition-2 story -- unrelated
to the rejected den-hoag-9xo.57.

IS `suppress` NEGATION IN THE ABW SENSE? YES, AND OUR OWN REPRESENTATION DECIDES
IT. Two readings were available. META: suppression selects a subprogram P' subset
P before the semantics is defined -- a program transformation, outside the model,
condition 2 does not apply. OBJECT: fires(P,node) <- gate(P,node) AND NOT
suppressed(P,node) is literally a clause with a negated body literal.
★ v1's mechanism was a DISPATCH FILTER (fx/handlers/dispatch-policies.nix) --
meta-level, defensibly outside the model. DEN-HOAG MOVED IT TO THE OBJECT LEVEL.
`suppress` is a first-class DECLARATION in the same vocabulary as member/edge/link
(declarations.nix groups.structural), produced by a policy BODY, carrying a
STRATUM, collected per-root, delivered by a scheduled INHERITED ATTRIBUTE
(suppressed-policies, stratum = structural), and consumed by a gate on another
rule's body. A meta-level program transformation does not get a stratum, does not
ride an attribute, and is not produced by a rule. Every one of those is an
object-level move. CONDITION 2 APPLIES.

★ THE ASYMMETRY THAT EXPLAINS WHY NOTHING CAUGHT IT, and it is the useful part:
`suppress` names a POLICY. It quantifies over RULES, where ABW's negated literals
range over DOMAIN INDIVIDUALS. So it is object-level in REPRESENTATION while
remaining rule-quantified in CONTENT. The machinery that would enforce condition 2
(den.derived's `negates`, den.productions' `from`) ranges over RELATIONS and has
NO VOCABULARY for a predicate whose argument is a policy name. THE GAP IS NOT AN
OVERSIGHT IN EITHER COMPONENT; IT IS THE SEAM BETWEEN THEM. A fix that only
extends the existing guards will not reach it.

BLAST RADIUS TODAY, stated honestly. `suppressedPolicies` has NO NATIVE READER --
gateSuppression (compat) is its only consumer in lib/. So on the native surface
`suppress` produces and delivers a fact nothing negates against, and the
unsoundness bites only through compat. ★ BUT THE REPRESENTATION THAT ADMITS IT IS
NATIVE. Corpus exposure is believed nil: nix-config has ONE excluder
(drop-user-to-host-on-droid) and one excluder cannot cycle -- ★ that count is from
the parity ledger and was NOT re-verified in this run, so treat it as unconfirmed.

VERIFICATION NOTE ON THE WITNESS ITSELF: the derivation of the unsupported
suppressed set is MEASURED; the downstream bite through gateSuppression is
REASONED from reading it, not run. A compat-path witness showing the gate actually
disabling both policies has NOT been built. State that limit wherever this is cited.

WHERE CONDITION 2 IS ENFORCED, correctly, for contrast -- do not rebuild it:
lib/concern-derived.nix den.derived's `negates` field, with negatesUnroutable (a
negated predicate must route through the THROWING gate node.rel, never the
silent-empty node.query -- absent and out-of-scope must be distinguishable) and
negatesNotAbove = any (s: !(strataLt strataOrder s stratum)) negatesStrata --
STRICTLY below. Witness ci/tests/claim-negation.nix, 8/8 green, header verbatim:
"STRICTLY-ABOVE -- a negation reads a COMPLETE predicate, so the negating
production must sit STRICTLY ABOVE the max claim stratum", and it gets the
positive side right too: "a claim cycle is NOT a stratum cycle".

NOT THE PLACE TO LOOK, recorded so nobody repeats the search:
· ci/tests/b2-two-stratum.nix contains NO negation vocabulary at all -- no nac, no
  suppress, no drop, no reach-suppress. It tests condition-1-shaped properties and
  does not bear on condition 2.
· gen-resolve lib/schedule.nix is condition 1 ONLY and correctly so: readsAttrs is
  UNSIGNED, so condition 2 CANNOT BE STATED there. Convergence is handled by a
  different criterion entirely -- Knuth 1968 circularity -- which is TERMINATION,
  NOT SUPPORTEDNESS. A circular attr reading its own stratum negatively passes both.
· ci/tests/b1-supportedness.nix is a THIRD thing: a post-hoc SEMANTIC check that
  the published interpretation is supported (Theorem 7's CONCLUSION), not a
  syntactic stratification check (Definition 3's PREMISE). It catches a negative
  cycle by its SYMPTOM, is defensibly stronger for admitting non-stratified
  programs with supported models, and covers attribute 2's enrichment keyset ONLY.
· `nac` is UNREACHABLE -- set nowhere in den-hoag or gen-dispatch; the policy
  record has no nac field. Positive control given (the bare pattern matches a
  substring in output-modules.nix, proving the grep was live).
· `drop` / `reach-suppress` SATISFY condition 2 BY CONSTRUCTION, not by check:
  both read their negated facts out of `declarations` (synthesized -> structural)
  while sitting at circular -> resolution, hence strictly below. Nothing checks it;
  it holds because all declaration facts materialise one stratum down first.

## Notes


────────────────────────────────────────────────────────────────────────────
★★ THE DOWNSTREAM BITE IS NOW MEASURED, NOT REASONED -- AND IT IS THE WORSE OF
THE TWO READINGS. Measured 2026-07-28, pinned at the session-end tree
(concern-policies fc30af1e / compat/compile.nix eb540e58; the four files the
suppression path runs through were STABLE all session).

Method: gateSuppression is a let-binding in compile.nix and not exported, so its
expression was reproduced VERBATIM --
    fn = ctx: if builtins.elem v1Name (ctx.suppressedPolicies or [ ]) then [ ] else compiled.fn ctx;
-- and applied to native records. Not a simulation: the gate's exact text on the
same rule shape. Each policy emits a `suppress` for the other PLUS an observable
`emit` marker for itself, so a fired policy is visible and a gated one is not.

    mutual  (A suppresses B, B suppresses A)  markers = [ ]                    supp = ["B","A"]
    oneway  (A suppresses B only)             markers = ["A-fired"]            supp = ["B"]     POSITIVE CONTROL
    neither (no suppression)                  markers = ["A-fired","B-fired"]  supp = [ ]       NEGATIVE CONTROL

IN THE MUTUAL CASE BOTH POLICIES PRODUCE NOTHING. Zero markers. No abort. Clean
eval. `oneway` proves the instrument reads markers and that the gate genuinely
disables; `neither` proves the empty mutual marker list is a real disabling and
not a probe artefact.

★ BLAST RADIUS, PRECISELY. The loss is NOT the `suppress` facts. gateSuppression
wraps the WHOLE fn, so a gated rule returns [ ] for EVERYTHING it would have
produced -- both policies' ENTIRE EMISSION AT EVERY NODE IN THE SUPPRESSED SCOPE
SUBTREE. And it wraps EVERY name-keyed compiled rule: den.policies, canTake
routes, and both include arms. A mutual pair silently removes two complete
policies from the fleet and the eval reports success.

★ AND IT IS SELF-CONCEALING: the suppression set ["B","A"] looks like a correct,
POPULATED result. An operator inspecting it sees evidence that suppression
"worked". There is no surface on which this looks wrong.

★★ THE CORPUS-CARDINALITY LEG: CONFIRMED, BUT THE LEDGER WAS RIGHT BY LUCK.
Re-measured with the broad bare-token `exclude` predicate over every .nix file in
three trees, both `.worktrees/` AND `.claude/worktrees/` pruned (BOTH exist in
nix-config and in denful/den), positive controls in each run.
ONLY ONE CONSTRUCT MINTS A suppress: `declare.suppress` has exactly ONE call site
in the tree, lib/compat/compile.nix:885, the `den.lib.policy.exclude <NAMED
POLICY>` arm. Everything else labelled "exclude" is a different mechanism --
den.schema.<kind>.excludes filters the includes list and mints no suppress;
den.aspects.<name>.excludes folds into meta.drop, the `drop` RESOLUTION kind, the
other negation path, which is condition-2-safe by construction.
    nix-config main   1 policy.exclude call,  1 targeting a NAMED POLICY
    den-configs (19)  0                       0
    den templates     2                       0
★ THE TWO TEMPLATE SITES ARE ONES THE LEDGER NEVER EXAMINED: an ASPECT target
(templates/ci/modules/deadbugs/issue-540-exclude-guard.nix) and INLINE NAMELESS
CONTENT (…/standalone-home-host-context.nix). HAD EITHER TARGETED A NAMED POLICY
THE LEDGER'S CLAIM WOULD HAVE BEEN FALSE AND NOTHING WOULD HAVE CAUGHT IT.
⇒ Treat cardinality-1 as a MEASURED FACT WITH A 3-TREE SCOPE, never as a property.
And it remains a CORPUS fact: the bar is expressibility, and the witnesses above
build the cycle in two POLICY RECORDS with no compat involved.

⇒ BOTH LEGS OF THE P1 PRICING CHECK OUT. One is stronger than filed; one is
confirmed but fragile.

COVERAGE LIMIT TO CARRY: the witness reproduces gateSuppression's EXPRESSION
rather than driving the real v1 shim end to end (den.lib.policy.exclude → bridge →
compile.nix:885). That path was traced by READING and its shape confirmed by the
census; a two-policy mutual-exclusion fleet in v1 SYNTAX was not constructed and
run. The gate's semantics are measured; the v1 AUTHORING path to it is read.

## Comments (2)

### 1 — 2026-07-30T00:22:46 · Jason Bowman

REFUTED IN PART by measurement (2026-07-29, design author on 4kh.18, six arms one eval, controls firing): 'what keeps it sound today is staging' overstates. The staging's empty-extension evaluation does not bound the hazard — it makes DEPTH-1 suppression programs accidentally agree with ABW's fixpoint. On an ACYCLIC depth-2 chain (A⊢¬B, B⊢¬C) the pre-pass yields ["B","C"] where the standard model is ["B"]: one T_P application vs M_i = T_{P_i}↑ω(M_{i-1}). Unsound on well-defined input, no cycle involved, no guard fires. This bead's cycle arms reproduce unchanged. The strictly stronger statement is filed with the measurement — see the T_P-once bead created 2026-07-29; the retirement design at the gate carries the by-construction fix candidate (rank-ordered firing over the declared suppression digraph).

### 2 — 2026-07-30T04:06:30 · Jason Bowman

U2 LANDED at 58160d4 and CHANGES THIS BEAD'S GROUND: declared suppression cycles now abort NAMED at registration (errors.negativeCycle via condensation — the mutual and selfNeg witnesses are pinned aborting in ci/tests/suppression-stratification.nix), and rank-ordered firing computes the standard model on acyclic chains (den-hoag-5mh closed). WHAT SURVIVES OF THIS BEAD: (1) the COMPAT-SURFACE witnesses — gateSuppression's or-[ ]-fail-open read — were measured on the compat path and are NOT re-measured by the landing; the recovered-codomain route now feeds the same registration graph, so the declared-cycle half should be discharged, but this bead's exact arms need one re-run before closing. (2) The no-native-reader asymmetry (suppressedPolicies consulted by gateSuppression only; a native policy cannot be gated) is now the LOAD-BEARING residue — the 5mh close reason states it as the standing limit. Re-scope this bead to those two items on next contact.
