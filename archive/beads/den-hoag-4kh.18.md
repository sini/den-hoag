# den-hoag-4kh.18 — [kernel] the 2-stage schedule at default.nix:1074 is a live effect-runtime holdover — and was recorded as tracked by a bead that is neither

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.18` |
| status at evacuation | closed |
| priority | P2 |
| type | bug |
| labels | `arch-validated` |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T04:48:33Z by Jason Bowman |
| last updated | 2026-07-30T04:06:31Z |
| closed | 2026-07-30T04:06:31Z |
| close reason | ★★★ U2+U3 LANDED — THE RETIREMENT IS COMPLETE AT ITS ACCEPTANCE. (Implementer fresh-context; orchestrator verified both suites independently before commit.) ci 2011/2029 exit 1 with the non-pass set IDENTICAL in membership to the pre-existing 18; ★ PARITY 71/71 exit 0 — THE SPEC'S FIRST CONTACT WITH THE PARITY ORACLE, green.

WHAT LANDED (spec internal order): u2.a+u2.g together — declared codomains (suppresses/binds required-iff) with registration aborts, and the firing-time twins through ONE kind-keyed table. ★ K1 DISCHARGED BY MERGE, the stronger option: declare.codomainRows with THREE readers (registration required-iff/declaredIn, firing keysOf/fail, and the v1 recovery's codomainsOf) — one statement of the pairing, no agreement assertion needed (an assertion is the verified-repair shape). u2.b — signedGraph over the policies DECLARATION attrset, stratifyOrThrow via graph.condensation, rank = bottomUp index, policyRank forced at registration. u2.e/f/h — per-minted firing both families (lociOf/ctxAt; tuples fire per locus with via.scope = the locus; suppressions the rank-ordered per-locus fold; deliverCtxOf DELETED — 0 hits, control 7 — which dissolves den-hoag-s5h's suppression leg BY REMOVAL and fixes its tuples leg BY CONSTRUCTION). U3 — the comment corrections including 71c45af's now-false "fires once" reason moved with the code; the E2 residual record was already in-tree from U1 (u5.header) and matches; the containmentAncestors dead-export prose corrected (den-hoag-6mf's site, prose half).

FIXTURES: prepass-locus-firing 6/6 (A13 both arms + both confound controls + A13a classification-restoration pinned separately + A14 locus values that ARE nodes); policy-codomain-graph 10/10 (A7 message VALUES, A3b negative-cycle-through-binding abort, A4b cluster-merge PINNED as intended, A4 positive cycle admitted, both firing-time aborts); suppression-stratification 7/7 — ★ den-hoag-5mh DISCHARGED: depth-2 → ["B"], depth-3 → ["B","D" — full landing record in the final comment. |
| description bytes | 3030 |
| notes bytes | 2473 |
| comments | 11 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

EFFECT-RUNTIME HOLDOVER, LIVE AND VERIFIED AT HEAD (a40cc96). Criterion 5's live known-positive, and until now
UNTRACKED — it was believed tracked and was not.

THE SITE, verbatim at lib/default.nix:1074-1098:
  :1074  "# THE STAGING THAT BREAKS THE CYCLE (design note §3b). Naive 'cellKinds <- tuples <- pre-pass <-
          roots <- ...'"
  :1076  "(`prePassScopeRoots`, over the STRUCTURAL non-candidates), derives the membership tuples, and the"
  :1083  prePassScopeRoots = buildRoots { ... }
  :1095  "# values. The pre-pass reads `prePassScopeRoots` (structural, un-injected) + `policiesRules` —
          neither"
  :1098  scopeRoots = prePassScopeRoots;
A STAGED PRE-PASS WHOSE ORDERING EXISTS TO BREAK A DEPENDENCY CYCLE IS THE SHAPE THE HOAG MODEL REPLACES WITH
DEMAND-DRIVEN ATTRIBUTES — and the kernel already owns that idiom (`resolve.attr` / `self.get` throughout
lib/attributes/). The file names the staging itself; this is acknowledged, in-tree, and not disputed.

★ WHY THIS BEAD EXISTS: THE TRACKING CLAIM WAS FALSE. W2's kernel-purity audit (den-hoag-4kh.2) recorded this
as criterion 5's replacement known-positive after the A1 accumulator was measured genuinely dissolved, and
stated "Already tracked as den-hoag-9xo.10. NOTE ITS CITED LINE RANGE HAS DRIFTED — 9xo.10 says 961-968; at
HEAD it is 1074-1086."
den-hoag-9xo.10 IS NOT THIS. It is "TOPOLOGY: parent-chain kinds are membership-INDEPENDENT flat roots", and
it is CLOSED — "RESOLVED by the node-multiplication arc, 84fc117..fc29920". So the holdover was recorded as
tracked, the tracker named was a different bug, and that bug then closed. NOBODY VERIFIED THE CITATION.
An orchestrator then carried the same false claim into the retiring-constructs register (den-hoag-4kh.17,
entry 3) without checking it. Corrected there.

⇒ THE PATTERN, which is the reusable part: "already tracked as X" IS A CLAIM, NOT A CITATION. It must be
checked like any other — read the bead, confirm it is the same construct, confirm it is open. A closed bead
named as a tracker silently converts live work into finished work.

RELATIONSHIP TO A1: den-hoag-4kh.2 verified the A1 `runPrePass` STATE ACCUMULATOR is genuinely gone at HEAD —
in the pre-image (6bef742^) the per-element step READ the accumulator (`st.relationBindings.${id}`); at HEAD
no fold in the file does, and every surviving `foldl'` is a monoid merge over independently-computed
elements. THIS IS A DIFFERENT, ADJACENT HOLDOVER AT THE CALL SITE. Do not re-file it as an A1 regression;
A1 is dissolved.

ACCEPTANCE: either the staging is replaced by demand-driven attributes (the kernel's own idiom), or the
reason it must remain is recorded with the dependency cycle it breaks NAMED and a statement of why laziness
at the attribute cannot break it. "It works" is not a reason under the standing bar.

NOT MEASURED: whether removing the staging is behaviour-preserving, and what the cycle actually is. The
design note §3b it cites should be read first — it may already answer why the naive order fails.


## Notes

★★ NEW BINDING REQUIREMENT ON THIS RETIREMENT, measured 2026-07-28. Recorded here
because it is invisible from every site the retirement would touch.

THE STAGED PRE-PASS IS LOAD-BEARING FOR ABW DEFINITION 3 CONDITION 2, AND NOTHING
IN THE TREE SAYS SO.

The suppression gate (lib/compat/compile.nix gateSuppression) performs a NEGATED
READ -- it fires iff the policy's name is ABSENT from ctx.suppressedPolicies.
Condition 2 requires a negated literal's definition to sit STRICTLY BELOW the
stratum of the rule reading it. That requirement is met today NOT by any check,
but by the STAGING ITSELF: the pre-pass's ctx (baseCtxOf / deliverCtxOf) is built
from prePassScopeRoots, FIXED BEFORE ANY SUPPRESSION EXISTS, so during the
pre-pass the negative literal is evaluated against an EMPTY extension of the very
relation being computed. The suppressions then arrive as inherited EDB.

⇒ REMOVE THE STAGING AND THE READ BECOMES AN UNGUARDED SAME-STRATUM NEGATED READ.
No guard replaces it: den.derived's `negates` and den.productions' `from` range
over RELATIONS, and `suppress` quantifies over POLICY NAMES -- they have no
vocabulary for it (den-hoag-4kh.51 has the full argument and the live witness).

⇒ THIS RETIREMENT NOW OWES A CONDITION-2 STORY, stated before any replacement is
designed: what, after the pre-pass is gone, prevents a suppression from being
derived from the absence of another suppression? A cycle through a negative edge
is ALREADY ADMITTED SILENTLY on this path today (measured: mutual A/B and self-
negating A both produce a suppressed set with NO abort, with positive and negative
controls in the same run) -- so the retirement is not introducing the hazard, it is
removing the accident that bounds it.

★ NOTE THIS IS INDEPENDENT OF den-hoag-9xo.57, which was REJECTED. That design
also touched this pre-pass, and it would be easy to read this requirement as
falling with it. It does not. This one comes from the negation semantics and holds
whatever replaces the schedule.

★ AND NOTE THE PATTERN, because it is the third instance in this arc: the
construct scheduled for retirement is silently discharging an obligation nobody
wrote down. The register's own worked example says the guards exist BECAUSE the
retiring construct fails; this is the converse and it is more dangerous -- the
retiring construct SUCCEEDS at something unrecorded, so its removal looks free.
Before retiring it, enumerate what currently holds only because of the staging.

## Comments (11)

### 1 — 2026-07-28T05:04:35 · Jason Bowman

EVIDENCE FROM THE R2 C9 PASS (den-hoag-4kh.11) — bears directly on this bead's justification, recorded here so
it is not lost in a sibling's comment thread.

STAGING CONFIRMED LIVE AT HEAD: lib/default.nix:1074 carries "THE STAGING THAT BREAKS THE CYCLE (design note
§3b)" verbatim; prePassScopeRoots built :1083, consumed :1098; runPrePass dispatches
policiesRules.resolveFamily at :1104 through staged-resolution.nix:192-199.

★ ONE OF THE STAGING'S STATED JUSTIFICATIONS IS BEING DISSOLVED BY OTHER WORK.
lib/default.nix:1103 justifies restricting the pre-pass's rule set as keeping it from a body "which could hit
an UNCATCHABLE MISSING-ATTRIBUTE READ". That failure class is exactly what the 4kh.11 R2 design's §7 totality
fix converts into a catchable NAMED THROW at lib/concern-policies.nix:122 — and the reviewer independently
reproduced that defect during review.

CONSEQUENCE FOR THIS BEAD: when R2 lands, the staging's own comment will overstate its necessity. That does
not by itself retire the staging — other justifications may stand and have not been audited — but it removes
one, and it means this bead's remedy design must AUDIT THE JUSTIFICATIONS INDIVIDUALLY rather than treating
:1103 as a single load-bearing reason. Sequencing note: this makes 4kh.11's landing an INPUT to this bead's
design, a CORRECTNESS edge, not merely a cost ordering.

Also recorded: R2 does NOT modify the staging, its ordering, or prePassScopeRoots. The direction is that the
staging operates on R2's code, not the reverse. So R2 landing first is safe and strictly informative here.


### 2 — 2026-07-29T23:48:57 · Jason Bowman

★★★ THE TWO "NOT MEASURED" ITEMS ARE NOW MEASURED (read-only analyst, den-hoag 931f274, all probes against git-archive copies, repo untouched). This comment is the design input for the retirement; three new defect beads and one perf bead were filed from the same report and are cited below.

THE CYCLE IS REAL AND ITS EDGES ARE NAMED. Probe: `scopeRoots = scopeRoots;` in place of `scopeRoots = prePassScopeRoots;` → "error: infinite recursion encountered" under deepSeq (positive control: base FORCED-OK, same command; an earlier attrNames probe returned exit 0 on BOTH — spine-only force, the known trap). Edge chain at HEAD: prePass reads attrNames scopeRoots (spine — ORDERING); tuples→tupleDimKinds→cellKinds→rootScopeKinds are DATA on coord NAMES only (§3b's claim, and it holds); baseScopeRoots reads rootScopeKinds (ORDERING, edge 6a) AND prePass.containmentAttachments (DATA ON NODE IDENTITY, edge 6b); scopeRoots closes the loop.

★★ EDGE 6a IS DISSOLVABLE, MEASURED AT ZERO COST. Probe: `prePassRootKinds = nonCandidateKinds;` → `allKinds` (mint the pre-pass universe from the schema alone, never membership). FULL suite 1980/1998 on both trees, failing-name sets compared with comm both directions: EMPTY delta. The classification-derived root subset buys no observable behaviour on the entire current oracle surface. ⇒ (a) "cycle in the representation" CONFIRMED for 6a. BONUS this closes: under nonCandidateKinds, an untargeted candidate root (corpus `cluster`) is in rootScopeKinds for the main run but never fired by the pre-pass, so no suppression can originate there — default.nix documents the resolve-family half and calls it corpus-unreachable; the exclude-family half was undiscussed. allKinds closes both.

★★ EDGE 6b IS THE WHOLE RESIDUAL ORDERING, AND ITS CAUSE IS GEN-SCOPE'S, NOT DEN-HOAG'S. Probe: allKinds PLUS `attachments = prePass.containmentAttachments` on prePassScopeRoots → infinite recursion; allKinds alone → exit 0. The one-line difference isolates it. Cause: `mintedRootId` (build-roots.nix) makes node ID a function of the attachment set because gen-scope buildNodes THROWS on >1 parent edge ("P must be a partial function, Neron §2.2 … use distinct IDs") — while den-hoag's own contains pool represents N parents natively (coordinates.nix `roots = containEdges nid`, list-valued). Multi-parent containment is a problem ONLY for gen-scope's scalar `parent` record; the N-way re-encoding as distinct IDs is what couples node identity to the containment relation, which is what makes the ordering. ⇒ the recorded refutation ("making containment an edge INHERITS the ordering") is CORRECT about its route and is NOT a bar on the general construction; the obstruction is a gen-scope representational commitment. Relates: den-hoag-4kh.53.13 (N4 — buildNodes specifies the @-suffix convention and implements neither half).

CITATION DEFECT IN THE HEADER ITSELF: default.nix's "THE STAGING THAT BREAKS THE CYCLE (design note §3b)" cites §3b (papers specs/2026-07-11-user-delivery-arc-design-note.md:83-103) for a claim it does not make — §3b's only ordering statement is "no new fixpoint" (coord NAMES not VALUES; true, and it holds at HEAD as edge 3). All 8 "cycle" hits in that note are §11's unrelated deliveryChainCycle (control: "fixpoint" hits the §3b line). The real cycle is through the attrset SPINE, which §3b never considers. The retirement design must write the true claim down where it holds, or the fix drops the citation.

COST AT HEAD, PRICED AT THE BAR: the discipline is a TRIPLE dispatch per pre-pass root (staged-resolution: containmentEmissions COLLECT, tuples DELIVER, suppressions DELIVER-exclude), linear in H — 3,003 at 1,000 hosts, not the problem. THE PROBLEM IS QUADRATIC IN H: opUpdCopied = 0.1875·H² + 70.5·H + 1414 (fit on 3 points, PREDICTED H=1000 and H=1600 exactly: 259,414 and 594,214 measured). Filed separately with its isolated cause — see the pre-pass-quadratic bead (rootNodeIndex `acc // {…}` fold over EVERY registry kind including the 7,000 users the pre-pass never fires at = 1/3 of the quadratic, listToAttrs replacement measured; remaining 2/3 unattributed among prelude.groupBy byTarget, containmentBindings fold, prelude.unique in attachmentsOf — the G20/G21 shapes, den-hoag-4kh.53.47/48).

WHAT A REPLACEMENT MUST PRESERVE OR CONSCIOUSLY CHANGE:
1. Suppressions must reach multiplied nodes — TODAY THEY DO NOT (new bead: suppression silent drop at N≥2; the fix construction already exists in-tree as containmentBindings' deliberate re-key onto minted node ids).
2. The cycle guard must be forced on every path consuming containment structure — today only containmentAttachments consults it; tuples/suppressions path admits a cyclic graph silently (new bead).
3. ★ CONDITION-2 STORY REQUIRED: den-hoag-4kh.51 records that the suppression path's ABW soundness is ACCIDENTAL — the pre-pass evaluates the negative literal against an empty extension because prePassScopeRoots is fixed before suppressions exist. Retiring the staging converts that into an unguarded same-stratum negated read. The design must carry a stratification answer, not inherit the accident.
4. mintedRootId stays the single shared definition (pre-pass + buildRoots).
5. The quadratic is independent of the staging question and survives any replacement keeping the fold shapes — do not bill its fix to the retirement.

COVERAGE LIMITS OF THE ANALYSIS (analyst's, relayed): staged-resolution.nix/build-roots.nix/default.nix:990-1230 read in full; default.nix NOT read in full; full suite run on base and the allKinds probe only; parity and corpus NOT evaluated; all scaling constants from ONE synthetic fixture (exponent is the claim, coefficients fixture-specific); Finding-2 corpus reachability NOT assessed.

### 3 — 2026-07-30T00:39:41 · Jason Bowman

★★★ r1 GATE — VALIDATED-WITH-CONDITIONS: 3 BLOCKING (all U2-local, each with a named local edit — the C6 conditions shape, no new position required), 2 NON-BLOCKING. U1 and U4.a independently landable per §12. Reviewer fresh-context, artefact+rubric only, C9 in-dispatch. Anchors verified in and out (.md c0a5311a…/1096, core ee89b1f4…/409, extract == companion byte-for-byte, two samples each). Reviewed at HEAD f44452c (design authored at 931f274; both intervening commits land on U2).

BLOCKING, each measured with controls:
F1 (C6) — THE NORMATIVE CORE REGRESSES den-hoag-bod, WHICH THE SAME CORE REQUIRES. u2.f files suppressions under bare ${id}; u4.b inside the same fence demands minted keying. Two-tree measurement: HEAD (71c45af) delivers ["victim"] at both minted nodes; the core's keying patched in delivers ABSENT at both — N=1 positive and no-suppressor negative controls on BOTH trees. §11's bod escape clause inapplicable: bod landed exactly as u4.b describes and is CLOSED. Edit: export under mintedRootId id (attachmentsOf id).
F2 (C6) — A7's FIRING-TIME codomain abort IS NOT CONSTRUCTED (only the registration missing/spurious pair exists). Without it S is extendable by execution and the Lemma 1 discharge is not total — the core's own `missing` message states why. Edit: suppressesUndeclared mirroring the live errors.emitsUndeclared (errors.nix:237, applied concern-policies.nix:264).
F3 (C6+C2) — u2.e's B-edge guard has an UNPINNED KEY SPACE and is blind at N≥2: containmentBindings is minted-keyed, firing nodes are bare ids, and the only in-tree accessor (deliverCtxOf) indexes bare — the live den-hoag-s5h defect, filed after authorship. A literal implementation reads { } exactly where a multiplied suppressor matters. Edit: pin the key set as the union over mintedRootId id (attachmentsOf id); cite s5h as a SECOND precondition beside c2n. In the design's favour: u2.e removes deliverCtxOf from the exclude path, dissolving s5h's suppression leg by construction; s5h's tuples leg is untouched, and U1 broadens the node set at which that still-buggy fire happens.

NON-BLOCKING: F4 — suite citations stale (HEAD is 1983/2001; the +3 are 71c45af's tests; non-pass 18 unchanged; A1 reproduces). F5 — u4.b mis-locates the bare-key harm: ranks compose consistently at bare ids; the loss is at the EXPORT boundary (lib/default.nix suppressedPolicies = prePass.suppressions.${id}, indexed by main-run minted id).

REPRODUCED INDEPENDENTLY BY THE GATE (own fixtures): the six-arm acyclic T_P witness EXACTLY (den-hoag-5mh stands, gate-corroborated); the NEW third cycle edge at the exact expression (prePassRootKinds = rootScopeKinds → infinite recursion at default.nix:1036:26, base control exit 0); A1 name-set identity (comm empty both directions, live predicate); R2's corrected cause (buildNodes 0 hits / buildRoots 24 refs control — den-hoag never calls buildNodes, the scalar is forced by gen-scope's walks). C5 STRONGEST PART: all five ABW coordinates verified, p.96/p.97/p.112/p.113 verbatim, and the p.108 M_i display — absent from BOTH text layers — CONFIRMED ON THE PDF RASTER (page 20 at 130dpi opens with the exact construction). The p.98 OCR trap confirmed live.

C9 PASS with an independent missed-hit hunt (chased __firesAtKinds → compat-owned, not a kernel carrier here; classBucketsOf off every changed path, corroborated by A1). Minor gap noted, not a finding: the design never names entry 3's double-fire discipline though U1 doubles its universe — measured-inert via A1+§7.

GATE'S COVERAGE LIMITS: cost ladders inherited (exponent-is-the-claim already stated); §3b note NOT read by the gate — U5's premise rests on two prior independent reads (the 4kh.18 analyst and the author), both agreeing; U4.a not prototyped; parity not run by anyone at this revision; corpus censuses inherited as censuses.

NEXT: r2 dispatched to the author — discharge the three blocking as CLASSES (every id-keyed core site against bare-vs-minted, not only u2.f; every fail-if row backed by a constructed check or marked unwritten), fold F4/F5, re-freeze the core, anchors re-measured at implementing HEAD.

### 4 — 2026-07-30T01:07:06 · Jason Bowman

★★ r2 GATE — VALIDATED-WITH-CONDITIONS: 2 BLOCKING, 2 NON-BLOCKING. GATE DOES NOT EXIT (rubric exit = two successive clean-in-the-construction rounds; G1 is in the construction, G2 in the argument — r2 is at best round one of the pair). Anchors held in and out (.md f6dcb61c…/1465, core 985b4536…/623, extract == companion). Tree unchanged at f44452c, so r1 baselines reused legitimately.

r1's THREE BLOCKING ALL DISCHARGED IN SUBSTANCE: F1 via the u0 export boundary (blocked only by G1's arity), F2's suppressesUndeclared verified CONSTRUCTIBLE at the exact conformingProduce chain (concern-policies.nix:258-269 read at HEAD), F3's key-set pinning sound with the guard-vs-ctx question split endorsed. C9 double-fire gap closed with sound reasoning (the exactly-one-consumer split is over declaration KINDS). s5h precondition citation is a strengthening ("inert on an oracle is not absent").

BLOCKING:
G1 (C6, construction) — u0.mintedIdsOf takes THREE parameters (mintedRootId: bareId: parents:) while BOTH core call sites pass TWO — u2.e's keys would be a partially-applied function, u2.f maps over a function. mintedRootId is in lexical scope at u0's stated placement (build-roots.nix, defined :26 exported :115), so the parameter is redundant. r1-F1's exact shape recurring IN THE BINDING INTRODUCED TO CLOSE THE CLASS. A10 clause 3 also only types under the two-parameter form. Edit: drop the parameter.
G2 (C7, argument) — u2.e's headline "reading decls only is the only TOTAL answer available without moving the firing onto the minted nodes (U3/E2 territory)" REFUTED BY CONSTRUCTION: the reviewer patched the pre-pass to fire the exclude family once per minted key against that key's own slice, using only bindings already in the same let (attachmentsOf, mintedRootId, baseCtxOf, containmentBindings — the last ALREADY partitioned per (target, source) by deliberate design, its own comment quoted). Measured: per-minted tree restores ["other","victim"] at BOTH minted nodes with per-node tokens t-z1/t-z2; N=1 control identical on both trees; FULL SUITE 1983/2001, non-pass name sets IDENTICAL, comm empty both ways. The ctx is total per node — no union, no last-wins. NOT U3/E2 territory (needs nothing from the main-run population). ⇒ u2.e as written DELETES a live capability (a binding-gated excluder stops firing at all at N≥2) on an unsupported non-existence claim. Reviewer costs, honestly stated as ITS inferences: forks the "fires once / whole set" semantics into per-node sets (representational ruling), N firings per multiplied root, re-opens the B-edge question for the guard.

NON-BLOCKING: G3 — the idKeySweep omits a row for u0.mintedIdsOf itself, the class's defining expression (covered indirectly by A10; the N/A and correctly-bare rows otherwise PASS the falsifiability test, u4.a's "the containment graph decides minting, a minted key would be circular" the strongest). G4 — the loss-shape statement is right but surface-dependent: ABSENT-KEY at the decls slot, [ ] at the inherited-attribute consumer; both indistinguishable from no-suppressor; ★ AND THE REVIEWER SELF-CORRECTED its own r1 phrasing — the isolating instrument was the N=1 POSITIVE control, not the negative control, at the surface it read.

ORCHESTRATOR RULING ON THE G2 FORK (recorded in the wsb autonomous decision log with REVIEW? flag, theory-resolved not banked): r3 ADOPTS PER-MINTED EXCLUDE FIRING. Grounds: den-hoag-2rh — suppression conditioned on a per-node binding is a per-node fact and the node is its locus; firing once at a bare root evaluates a predicate at a coordinate that names no node, the arc's recurring representational sin (den-hoag-s5h states exactly this one-fire-two-nodes question); no-half-measures — deleting a live measured capability to keep firing single is the least-effort shape; the reviewer's construction is oracle-green; and the once-at-bare-root semantics was never a ruled surface — it is an artifact of the pre-mint staging, i.e. of the construct being retired. r3 must carry the consequences: the stratification statement for binding-gated excluders (S's edges are DECLARED suppresses codomains, so Lemma 1 over S is prima facie unaffected by firing locus — the design must state this precisely or refute it), the N-firing cost row, §10 recording the decls-only narrowing as REJECTED with its reason, and the fate of errors-excludeReadsBinding stated (restriction, guard, or retired).

GATE COVERAGE LIMITS (both rounds): A8 cost ladders never re-run; §3b design note STILL UNREAD BY ANY REVIEWER (two prior independent reads only — author + the 4kh.18 analyst); parity not run at any revision; u2.g verified by reading, not patching; corpus censuses inherited. Reviewer process note kept for the record: one patch attempt failed its indentation anchor and produced an unpatched eval that LOOKED like a valid negative — caught by the anchor assertion, corrected, re-run.

### 5 — 2026-07-30T01:37:55 · Jason Bowman

★★ r3 GATE — VALIDATED-WITH-CONDITIONS: 1 BLOCKING, 2 NON-BLOCKING. GATE DOES NOT EXIT — round one of the fresh pair (author's framing, gate concurs), and it found a construction defect. All three r2 conditions DISCHARGED. Anchors held in and out including the new selfCheck recipe step (gate ran it → true; orchestrator had independently run it before committing). Tree unchanged at f44452c.

★ THE RULING IS RATIFIED. The gate attacked the wsb-log grounds directly (in-dispatch): all four hold, THREE ON ITS OWN MEASUREMENTS (capability-deletion measured in r2; oracle-green measured in r2; containmentBindings partition read at HEAD; the bare-id-names-no-node premise pinned by 71c45af's own test). r3's refutation of the flagged corollary (S locus-independent, sufficiency locus-DEPENDENT) is called a real theoretical advance. H1 is that advance's implementation failing, not the ruling failing. REVIEW? flag for the owner stays on the log entry; adversarial ratification is recorded there.

BLOCKING:
H1 (C6) — THE POSITIVE EDGE FAMILY IS VACUOUS AT THE ONLY CALL SITE; FALSE-ADMIT DIRECTION. Chain, each link read at HEAD: excludeFamily = suppress-emitters exactly (concern-policies.nix:328 verbatim); the core's only kernel call passes rules = excludeRules; signedGraph's names = attrNames rules; u2.a makes binds REQUIRED iff emits contains "member" and SPURIOUS otherwise — so a pure suppressor may not declare binds, every q in names has binds or [ ] = [ ], posOf p = [ ] for ALL p. negOf truncated identically (a suppressor naming a pure member-emitter in suppresses never enumerates that edge). The graph must span suppressors, their targets, AND binding producers; today binds is a breaking user-surface change feeding an empty family, and a genuine positive-edge cycle is ACCEPTED SILENTLY — exactly what A3b claims to catch. ★ WHY THE INSTRUMENT MISSED IT: selfCheck's fixture policy B emits member only, so B can never be in excludeRules — THE FIXTURE MODELS A STATE THE REAL CALL SITE CANNOT PRODUCE, the arc's canonical blind-spot shape, in the instrument built to prevent r2's recurrence. Edit (local): range signedGraph over ALL policy rules, keep excludeRules for classAt/firing; re-fixture selfCheck with a call-site-producible state.

NON-BLOCKING:
H2 (C4) — posOf's direction unstated: formals∩binds is a GLOBAL NAME-COLLISION test with no reachability scoping; common binding keys (host, name, token) collide across unrelated policies, merging clusters ⇒ false REJECTION of a legal program. Safe direction, but the over-strictness the spec itself flags at :1256, and A4's paired control does not guard this case. Reasoned, not measured. C4 wants the direction named with its repairing discipline.
H3 (C6, CLOSED BY THE GATE'S OWN MEASUREMENT) — the stub condensation concern: gate tested gen-graph's REAL condensation against stratifyOrThrow's contract — cyclic pair lands one SCC (rejection arm genuinely fires); acyclic chain gives bottomUp depended-upon-first, matching ABW p.98's numbering. Contract HOLDS; documentation item; design may cite the measurement.

PRESSURE POINTS, ALL CLOSED THIS ROUND:
· Condensation C5/C7-a PASS STRONGLY: graph.condensation live at the ACTUAL pin (gen-graph lib/global.nix:137, exported :242, shape verbatim, Tarjan/Kosaraju + Mokhov §4 header). "bottomUp IS the stratification" TRUE against Definition 12 p.112 + Lemma 11(2) p.113 (raster baselines) + ABW p.98's converse proof; gen-graph's closure-cardinality ordering proven a valid topological sort.
· ★ THE binds CENSUS — THE GATE RAN THE CENSUS THE AUTHOR DECLARED ABSENT: "member" across the 19-config corpus = 0 files 0 occurrences, den v1 = 0, den-hoag ci = 16 files/41 (declare.member 28); same-run control "suppress" corpus 0 / v1 0 / ci 1, matching 4kh.51's census. ⇒ THE CORPUS AUTHORS ZERO NATIVE MEMBER-EMITTING POLICIES; the whole blast radius of binds-required is den-hoag's own 16 ci fixture files. Stated limit, NOT blocking. Caveat: string-match is an upper bound; the load-bearing figure is the corpus ZERO with a firing control.
· coneRank second rejection ground VERIFIED BY CONSTRUCTION (acyclic control exit 0; positive cycle exit 1 inside the memoized recurrence, separate invocations).
· A4's paired control ARMED, not vacuous (bad inspects only negative edges' endpoints; a purely positive cycle collapses to one rank and both members admit — ABW condition 1 exactly).
· ★ §3b DEBT CLOSED, IN THE DESIGN'S FAVOUR: gate read the note itself — the ordering statement is verbatim as quoted, about VALUE fixpoints, silent on the spine; every "cycle" hit is §11's deliveryChainCycle; control fires. U5's factual basis fully verified. BONUS: §3b is where membership-derived classification was PROPOSED — the origin of the E1 edge U1 retires.

GATE SELF-REPORTED NEAR-MISSES, kept for the record: (1) nearly reported the gen-scope/gen-graph lock pins FALSE off nodes.<name>.locked.rev — top-level nodes were transitive duplicates; (getFlake).inputs.<name>.rev is the authoritative instrument and confirms the design. Sound predicate, different proposition, caught before reporting. Filed as a 4kh.20 case. (2) first census run returned 0 everywhere — zsh ate an unquoted --include=*.nix; exposed by the positive control also reading 0 (missing instrument, not absence).

GATE LIMITS (cumulative): A8 ladders never re-run in any round, now including r3's new 10.0-per-root figure; parity never run at any revision; u2.g/u4.a not prototyped; c2n not re-measured; A6's value-specific asymmetry (z1victim fires at z1 not z2) NOT re-run — the gate's r2 construction measured the symmetric case only; H2 reasoned not measured.

NEXT: r4 dispatched — H1 as a class (every quantified claim in the core checked for DOMAIN TRUNCATION; every selfCheck fixture state producible by the real call site), H2's direction named, H3's measurement cited, the census folded as the binds stated limit.

### 6 — 2026-07-30T01:55:23 · Jason Bowman

★ r4 GATE — VALIDATED-WITH-CONDITIONS: 1 BLOCKING, 1 NON-BLOCKING, 1 reviewer self-correction. PAIR RESETS — J1 is a normative expression inside the fence (the gate stated the exit-pair disposition explicitly, as required). Anchors held (.md 9a4ee5d9…/1936, core e7f32913…/785, selfCheck true both sides). Tree unchanged at f44452c.

BLOCKING:
J1 (C7) — u4.a guardedExports IS FAIL-OPEN ON EXPORT ADDITION. The guard is applied once per attribute, five times, in the returned record; a sixth export is silently unguarded. Measured both forms with positive controls: r4form NEW export → UNGUARDED; mapAttrs NEW export → GUARDED (membership implies guarding). The total form is one call — wrap the record in builtins.mapAttrs (_: guarded) — preserving per-value laziness. Export count verified five at HEAD, so the list is right TODAY; the defect is structural, and C7's own note applies verbatim ("a verified repair is precisely the shape that closes this check falsely"). ★ IN-THEME: the arc's thesis is that an invariant maintained by repetition desyncs — guardedExports writes `guarded` five times two sections after u0 was introduced to stop writing mintedIdsOf four times.

NON-BLOCKING:
J2 — the quantifierSweep and idKeySweep have NO ROWS FOR THEMSELVES: both are quantified claims over hand-enumerated domains with no stated derivation, and A12's first clause reaches them. r3 added u0's own row after r2-G3; the new instrument repeats the omission one instrument over. Instrument finding — does not reset the pair.

J3 — GATE SELF-CORRECTION: r3's H1 was reported as "false ADMIT, the unsafe one"; WRONG — the compiled feed is a LIST, so r3's attrNames-on-excludeRules would have thrown LOUD at eval. The conclusion (truncated domain, unreachable fixture) held; the assigned failure mode did not, and the author found the sharper fault the gate missed.

PRESSURE POINTS, ALL CLOSED:
· THE JOIN — SOUND, verified in-tree: one-declaration-many-rules harmless (every sub-rule carries identity = name, concern-policies.nix:297, inside compileOne over attrNames policies); identity ≠ name impossible (repo-wide identity= sweep, no other site builds a dispatch rule); never-compiles = superset rank, inert; ★ THE DANGEROUS DIRECTION — A FIRING RULE WITH NO RANK — IS UNREPRESENTABLE. "The firing set is a projection of the ranked set, never its domain" endorsed.
· Sweep totality: the mechanically-checkable row VERIFIED (function-binding walk over the core returns exactly the four bindings named and applied); the nine-row domain itself is hand-enumerated (J2).
· Second fault (list-vs-attrset) verified; the fix is attrset end-to-end where it must be, list only on the firing side where a list is correct.
· A4b ARMED in the right direction: it asserts the over-approximation HAPPENS, so adding scoping later turns the row red and forces deliberateness. Called good instrument design.
· ★ A6 REPRODUCED BY THE GATE (its last outstanding limit closed): value-specific excluder fires at z1 NOT z2 while any-binding fires at both and decls-gated fires everywhere; N=1 and no-suppressor controls clean. NO SINGLE-FIRING-PLUS-UNION SCHEME CAN PRODUCE THE ASYMMETRY — the ruling's central semantic claim is now independently validated twice.

r3 CONDITIONS ALL DISCHARGED: H1 re-domained with the join sound and the regression arm measured (truncation control: "list of size '1' is not equal to list of size '2'", EXIT 1); H2 = exactly what C4 asks for (FINER, unscoped-for-a-stated-reason, repairing discipline: rename a key or split a codomain, never relax the check); H3 folded; fixture-producibility law + A12 called a genuine addition with two self-found known-positives.

CUMULATIVE UNCLOSED LIMITS across all rounds (the implementation dispatch inherits these): A8 ladders never re-run (incl. U2.e's 10.0/root); parity never run at any spec revision; u2.g/u4.a unevaluated as kernel code; c2n not re-measured; A3b/A4b unwritten as live fixtures (selfCheck exercises checker arms, not a fleet); J2 reasoned not measured.

NEXT: r5 dispatched — J1's one-call edit plus its class (any repeated application whose domain a record can state), J2's self-rows, J3 folded as the corrected severity record.

### 7 — 2026-07-30T02:08:00 · Jason Bowman

★★★ r5 GATE — VALIDATED, ZERO BLOCKING. CLEAN ROUND ONE BANKED (the gate's explicit exit-pair statement). One non-blocking (K1), with the reviewer's below-the-line reasoning written out for overrule. Anchors held (.md 05622647…/2030, core 775e6845…/833, selfCheck true on both sides). Blast radius bounded MECHANICALLY: r4→r5 core diff's non-comment additions = exactly the four claimed changes; the u4.a instruction correction comment-only and read directly. Both prior armed controls re-verified BY THE GATE on the final core. Gate self-reported one instrument slip (ran the tree check in the wrong repo's CWD, caught and re-run) — the wrong-repo-HEAD trap, noted.

VERIFIED THIS ROUND: J1's mapAttrs form (fail-open comparison on BOTH forms — r5 NEW export GUARDED, r4 NEW export UNGUARDED); codomainRows behaviour matches its claim exactly with no overclaim (rowed kind ABORTS LOUD, unrowed kind passes silently and the core SAYS so — unchecked BY DECLARATION); u4.a's retained clause was FALSE under the accessor form and is TRUE under the product-boundary form (all five exports + containEdges guarded, rawContainEdges/byTarget private); the self-rows honest, the quantifierSweep's the sharpest (a binding walk cannot see a prose quantifier — where r3's false claim actually lived; the author volunteered the limit that most undermines its own instrument).

K1 (non-blocking, ACCEPTED below the line — orchestrator concurs with the reviewer's reasoning): the (kind↔codomain-field) pairing appears in policyRecordFields (required-iff) AND codomainRows (declaredIn); a third codomain edits both, forgetting either is silent in opposite directions. Verified agreeing today. Not C7 (no bad intermediate), not A12-live (domain not narrower today), and the total form is a MERGE with design content, not a one-call fix. ⇒ CARRIED AS AN IMPLEMENTATION OBLIGATION: the U2 implementer either merges the tables or lands a selfCheck agreement assertion over the pairing, so the desync is loud. Recorded here so it cannot evaporate.

★★★ ORCHESTRATOR RULING — THE GATE EXITS AT r5. The standing rule (4kh.6: two successive clean-in-construction rounds) is a stopping heuristic whose PURPOSE is met, and the owner lens directive outranks a second confirmation round. Grounds:
1. r5 is the ladder's first zero-blocking VALIDATED verdict; the clean call's scope is stated precisely (four changed regions reviewed directly + mechanical absence of other change + r1-r4 covering the unchanged surface) — not a lucky sample.
2. The rule's own rationale ("a gate reading an instrument will always find something in the instrument") describes exactly what an r6 would buy: K1 is apparatus-adjacent, and the owner correction (feedback_backlog_is_one_defect: "by r8 the gates were finding defects in the documents' own review apparatus... at that point you are reviewing the reviewer") was given three times precisely against that spend.
3. U2 — the only unit that changes resolved configuration — has a NATURAL later checkpoint regardless: it cannot land before the c2n and s5h fixes, and the implementation goes through its own review. The residual risk of exiting one round early is bounded by that checkpoint.
4. Every cumulative unclosed limit transfers to the implementation dispatches as stated preconditions: A8 ladders re-measured at the implementing HEAD (U1's inherited from 931f274; U2.e's 10.0/root from f44452c); parity run at implementation; A3b/A4b written as live fixtures; c2n re-measured by its discharge; K1's assertion-or-merge.

FINAL SPEC ANCHORS (six rounds, r1..r5 + this exit): papers 7ad7229, .md md5 056226477c3f41582f5ff3139833666d / 2030 lines, core md5 775e6845289a5dd1ca8d82dea0f6a30f / 833 lines, selfCheck true. Gate history: r1 3B, r2 2B (G1 construction, G2 argument), r3 1B (H1 construction), r4 1B (J1 construction), r5 0B clean. The design is arch-validated; VALIDATED attests the executable core and the decisions it encodes, per the de Bruijn ruling.

LANDING ORDER (spec §12, now operative): U0 (mintedIdsOf) → U1 (allKinds pre-pass universe) → U4.a (product-boundary cycle guard — DISCHARGES den-hoag-c2n's acceptance) → U2 (per-minted firing + declared codomains + signed-graph stratification; GATED on c2n verified closed and the den-hoag-s5h tuples-leg fix; internal order u2.a/u2.g before u2.b) → U3 documentation. A lander of U1 alone must read §4.4a: U1 widens the reach of s5h's still-open tuples leg.

### 8 — 2026-07-30T02:29:02 · Jason Bowman

★★ U0+U1+U4.a LANDED at 71c11b2 (implementer fresh-context; orchestrator verified suites independently). mintedIdsOf named once with the buildRoots non-redirect reasoned at the definition site; residual-expansion sweep 4 hits all accounted (definer, sanctioned non-redirect, and containmentBindings which produces per-parent VALUES not key sets — outside u0's replaces list, correctly); prePassRootKinds alias DROPPED rather than kept (implementer call, endorsed: a binding named for a schedule position is the rename rationale's own target); the false §3b citation replaced by the true dim-signature law at the successor site with a grep control both sides; §4.4a's s5h-widening disclosure is a code comment at the pre-pass call site. A8 RE-MEASURED at implementing HEAD: flat in H (+238 at H=25/50/100), zero nrOpUpdateValuesCopied at every rung, 34.0 calls per candidate entity at U=7/28/56 — coefficient UNCHANGED from 931f274 despite 71c45af's fold change. c2n CLOSED by U4.a with red-before/green-after isolation. REMAINING: U2 gated on the den-hoag-s5h tuples-leg fix (c2n precondition now met) with the K1 obligation (codomain-table merge or agreement assertion); U3 documentation rides U2. LIMITS carried: s5h tuples leg widened-not-changed by U1, documented at the site, inert on the current oracle; U4.a/U0 costs constant-by-construction across the ladder arms, not separately measured; ladder fixture is the implementer's synthetic, coefficient reproduced to three rungs but fixture identity not claimed.

### 9 — 2026-07-30T03:06:47 · Jason Bowman

★★ u2.h GATE (first round) — VALIDATED. NOTHING FOUND IN THE CONSTRUCTION; two non-blocking, one of them the ORCHESTRATOR'S (L1). Anchors held (.md 7e1779e3…/2262, core 4adc088d…/941, selfCheck true both sides). Tree pinned at 4b40dc9 / lib at 71c11b2; the gate re-derived everything at this HEAD rather than reusing stale baselines.

REPRODUCED BY THE GATE ON ITS OWN FIXTURES: the classification flip EXACT (empty tuples ⇒ empty cellKinds ⇒ candidate instances re-materialize as ROOT nodes; restored under per-minted; same-value confound confirms the keying); ★ BOTH ARMS — ARM-G is no longer inherited by anyone, the gate measured it (required-formal gating and soft-read null branch: different mechanisms, identical observable, both restored); the (b)/(c) interaction (via=id vs via=locus byte-identical on every observable — via is projected away before the product); the direct-parent refutation VERIFIED AUTHORABLE at HEAD (selects zone, rack-parented coords, firing locus a zone while the parent dim is rack); the via.scope single-reader sweep with control (fleet.nix:95, and the reader prints a bare id naming no node at N≥2 — "leave it" was not neutral); oracle neutrality (1988/2006 both trees, comm empty both ways); §12 gating and §9 half-status both checked against the tree and correct; the COLLECT asymmetry endorsed as "the claim, not an omission".

C7 disposition, stated for the record: CONCEDED, honestly and correctly labelled — the gate's own second construction (coord-level dedup at the tuple site) is also produce-then-reduce, so no clean construction is available and the concession stands.

NON-BLOCKING:
L1 (ORCHESTRATOR ARTEFACT, DISCHARGED THIS SESSION): register entry 3 still read "LIVE at d33ce02" after 71c11b2 shipped the classification half — the register's own decay mode #1, violated by the orchestrator in the ship session. Body now edited: HALF RETIRED at 71c11b2 with live anchors re-cited (structuralNodes / baseScopeRoots-with-attachments), tracker line refreshed, "a brief citing this entry must say which half it means."
L2 (C7-b): the unit records and refutes ONE alternative but not the gate's measured cheaper option — coord-level dedup before fromTuples (~4 substrate lines, measured: same-value collapses to 1×N, differing-slice survives intact, control unchanged), which makes the N² intermediate never form at the price of the surviving tuple naming one of N loci. The gate is NOT refuting the concession (its option is also a dedup, C7-fails the same way); C7-b's predicate fires because the dearer binding has no stated reason against this option. → r7 micro-round: record the option in §10 with the decision and its reason. Prose + acceptance only; no construction change.

RULING: grounds re-verified sound; ratification recommended and recorded (both decision-log tuples entries now carry adversarial ratification).

GATE LIMITS (cumulative, transfer to the U2 implementation dispatch): A8 cost figures for u2.h not re-run by the gate (ladders never re-run by any reviewer in any round — the implementer re-measures, as the U0-U4.a implementer did); parity never run at any spec revision; the corpus N=2-everywhere claim inherited; A14's abort-text arm verified by reading, not by triggering; u2.a/u2.g not prototyped in-tree.


### 10 — 2026-07-30T03:11:32 · Jason Bowman

r7 (micro-round) COMPLETE at papers 914c89b — the L2 option recorded in §10 and DECLINED, construction proven byte-identical to the validated r6 core (mechanical diff, comments/notes filtered, remainder EMPTY — no gate look required). The declining reasons, in deciding order: (1) the dedup makes A14 UNSTATEABLE — it runs after via is set, so the surviving tuple keeps an arbitrary one of N loci chosen by fold order, converting an ambiguity the N² path PROJECTS AWAY into one it RECORDS, in the one field this unit just gave a reader; (2) zero C7 credit — both constructions are produce-then-reduce because N firings are how the values are learned, so only the reduction site moves; (3) the saving is N²−N = TWO edge records at corpus scale against qxz's ~1.5e12. NEW CONSEQUENCE the author found: membershipTuples is an EXPOSED SURFACE (control fired), so the dedup is user-visible, raising its bar. Forward line recorded so the rejection cannot be re-proposed bare: settle what via.scope should say when one tuple survives N firings, then the option is clean. FINAL SPEC ANCHORS (seven rounds + u2.h round + two micro-rounds): papers 914c89b, .md md5 c5322b9ddc14490562719fea2afdcd05 / 2318 lines, core md5 71f53e36bbc8b6ec2840784883be853e / 947 lines, selfCheck true. U2+U3 implementation dispatched.

### 11 — 2026-07-30T04:06:31 · Jason Bowman

★★★ U2+U3 LANDED — THE RETIREMENT IS COMPLETE AT ITS ACCEPTANCE. (Implementer fresh-context; orchestrator verified both suites independently before commit.) ci 2011/2029 exit 1 with the non-pass set IDENTICAL in membership to the pre-existing 18; ★ PARITY 71/71 exit 0 — THE SPEC'S FIRST CONTACT WITH THE PARITY ORACLE, green.

WHAT LANDED (spec internal order): u2.a+u2.g together — declared codomains (suppresses/binds required-iff) with registration aborts, and the firing-time twins through ONE kind-keyed table. ★ K1 DISCHARGED BY MERGE, the stronger option: declare.codomainRows with THREE readers (registration required-iff/declaredIn, firing keysOf/fail, and the v1 recovery's codomainsOf) — one statement of the pairing, no agreement assertion needed (an assertion is the verified-repair shape). u2.b — signedGraph over the policies DECLARATION attrset, stratifyOrThrow via graph.condensation, rank = bottomUp index, policyRank forced at registration. u2.e/f/h — per-minted firing both families (lociOf/ctxAt; tuples fire per locus with via.scope = the locus; suppressions the rank-ordered per-locus fold; deliverCtxOf DELETED — 0 hits, control 7 — which dissolves den-hoag-s5h's suppression leg BY REMOVAL and fixes its tuples leg BY CONSTRUCTION). U3 — the comment corrections including 71c45af's now-false "fires once" reason moved with the code; the E2 residual record was already in-tree from U1 (u5.header) and matches; the containmentAncestors dead-export prose corrected (den-hoag-6mf's site, prose half).

FIXTURES: prepass-locus-firing 6/6 (A13 both arms + both confound controls + A13a classification-restoration pinned separately + A14 locus values that ARE nodes); policy-codomain-graph 10/10 (A7 message VALUES, A3b negative-cycle-through-binding abort, A4b cluster-merge PINNED as intended, A4 positive cycle admitted, both firing-time aborts); suppression-stratification 7/7 — ★ den-hoag-5mh DISCHARGED: depth-2 → ["B"], depth-3 → ["B","D"] (the ABW standard models), depth-1 and no-suppressor controls, mutual/selfNeg abort message-matched on errors.negativeCycle, acyclic registration clean. With 5mh's stated limit: the model is right because the fixture body self-gates on suppressedPolicies; a native excluder that does not self-gate still realizes the chain — the PRE-EXISTING no-native-reader asymmetry (4kh.51), not introduced here.

LADDERS RE-MEASURED at implementing HEAD: exponents UNCHANGED (linear in H, linear in U — not a STOP). Coefficients moved (22.0·H+203 without excluder, 40.0·H+533 with; 117.0/candidate-entity) — fixture-specific per the spec, and the implementer's bundle includes u2.g's per-emission check the spec's isolated ladders did not. ★ A8's opUpd-ZERO clause REFUTED for u2.e: ΔopUpd = 1.0·H + 13 — the spec's own suppressionsByLocus writes one attrset update per firing; the r3 prototype measured per-minted firing WITHOUT the rank-ordered ctx injection, and the two were never measured together. Linear, priced, recorded.

FOUR DIVERGENCES, all reported by the implementer, none silent:
1. ★★ THE binds CENSUS WAS FALSE AT HEAD — predicate blindness that survived two reviews (case filed on den-hoag-4kh.20): the census's domain was AUTHORS ("who writes native member-emitters": corpus zero), the property's domain was RECORDS REACHING policyMessage — and the v1 lowering MINTS declare.member from every resolve.to. First landing: 61 red at registration. Closed by policyRecover.recoverDecls — the required codomains recovered from the SAME sentinel fire emits already uses (recoverEmits is now a projection of it), the shim's own non-authoritative contract, with u2.g as the loud backstop.
2. spurious landed NON-EMPTY-BASED, forced: the lowering must stamp static key sets (an emits-conditioned key set forces emits at record-build ⇒ measured uncatchable eval error, the shim's documented tryEval ceiling); presence-based spurious would reject every lowered policy; the [ ] exemption rests on the spec's own empty-head ruling. Native surface unaffected.
3. (the A8 clause above.)
4. Three transplant corrections to the core, each the spec's own prose semantics: classAt's name-list/rule-feed type mismatch (join by identity, as the spec states); conformingProduceArm returning the unstamped record (dropping __policy, load-bearing at two readers); recoverDecls in a non-rec sibling scope (the selfCheck class, caught by the implementer's own transplant discipline).

RESIDUE FILED SEPARATELY: the v1 value-conditional-excluder suppresses-declaration migration requirement (new bead — nix-config's real excluder needs it at the pin bump); den-hoag-cqp's ARM-G interaction still unmeasured; the B-edge census still unrun (predicts A4b merge frequency, not soundness); posOf's short-circuit adds a gate-forcing dependency where binding producers exist, unexercised.

ACCEPTANCE MET, second arm: the schedule that remains (the two-phase mint for edge 6b) is recorded with the cycle NAMED and the reason laziness cannot break it (in-tree at the u5.header site, gate-verified); the classification half is deleted, the firing semantics are per-locus, and the effect-runtime shape this bead names is gone. Register entry 3 updated accordingly. CLOSING.
