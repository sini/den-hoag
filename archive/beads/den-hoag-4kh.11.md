# den-hoag-4kh.11 — ABW stratum guards: the cited rule is wrong in 3 kernel/spec sites and implemented as live code; primary text now archived

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.11` |
| status at evacuation | closed |
| priority | P1 |
| type | bug |
| labels | `arch-validated` |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T22:06:03Z by Jason Bowman |
| last updated | 2026-07-29T23:24:41Z |
| closed | 2026-07-29T23:24:41Z |
| close reason | All five requirements discharged: R1+R5 landed earlier (papers 48e9ad7), R2 design gate-VALIDATED then implemented at 7c10bb0 with §9.4 per-guard consumption-controlled checks, R3 exceeded — the re-pins land GREEN with paired controls rather than as a known-fail, because the guard now implements the correct rule instead of being pinned red against the wrong one. R4 honoured (four correct sites untouched; negation-gate green throughout). Docs corrected through papers f14f29c. Unblocks den-hoag-4kh.18. |
| description bytes | 10213 |
| notes bytes | 0 |
| comments | 19 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

den-hoag cites Apt, Blair & Walker (1988) for its stratum guards. ONE spec site states the rule WRONG and
misattributes it; the same wrong rule is implemented as LIVE KERNEL CODE, inert only because one attribute is
empty. THREE other spec sites state it CORRECTLY — including one that already gets the subtle part right.
This is drift, not a typo.

★ PROVENANCE SETTLED. The "ABW paywalled, resting on a third-party restatement" caveat is WITHDRAWN.
  https://ir.cwi.nl/pub/10404/10404D.pdf   sha256 30737c8d…7bd91
  papers/den-architecture/used/{pdf,markdown,summaries}/apt-1988-towards-theory-declarative-knowledge.*
Book chapter, raster scan of the Morgan Kaufmann print, 60 pages, printed pp. 89-148. PRINTED = PDF + 88.
Mathematics verified against 200 dpi raster renders; the text layer mangles it.

════ WHAT ABW ACTUALLY SAY ════
DEFINITION 3, printed p. 96 (NOT 97), section "Stratified Programs" — P is stratified if it partitions into
P1 … Pn such that for i = 1..n:
  1. a relation symbol occurring POSITIVELY in a clause in P_i has its definition within ⋃_{j ≤ i} P_j
  2. a relation symbol occurring NEGATIVELY in a clause in P_i has its definition within ⋃_{j < i} P_j
ABW's prose gloss, same page: "each stratum defines new relations in terms of ITSELF ONLY POSITIVELY and in
terms of the relations from the PREVIOUS STRATA, POSSIBLY NEGATIVELY."
⇒ POSITIVE READS AT THE SAME STRATUM ARE PERMITTED. Strictly-lower is the NEGATIVE rule ONLY.

LEMMA 1, printed p. 97: "A program P is stratified iff in its dependency graph there are no cycles containing
a negative edge." Proof (pp. 97-98) restates it as levels: positive edge ≤, negative edge <. Converse proved
by SCC CONDENSATION; the SCC refinement ("clusters", DEFINITION 12, p. 112) is the FINEST stratification
through which every other factors ⇒ stratifiability is DECIDABLE in graph time, not searched for.

★ THE REAL INVARIANT IS COMPLETENESS, NOT VISIBILITY. Printed p. 108: M_1 = T_{P_1}↑ω(∅), M_i =
T_{P_i}↑ω(M_{i-1}), M_P = M_n. Each stratum reaches ITS OWN FIXED POINT before the next begins. So the
soundness condition for a negative read is "THE NEGATED RELATION HAS FINISHED", not "the reader can see
less". Strictly-below indexing is a CONSERVATIVE SUFFICIENT CONDITION for completeness — not the property.

ATTRIBUTION: ABW stratify PREDICATE (relation) SYMBOLS via a partition of the PROGRAM (DEFINITION 2.2), NOT
ground atoms. "locally stratified" occurs EXACTLY ONCE, printed p. 144, Bibliographic Remarks, as ABW's own
disclaimer: "The notion of stratified programs has been further generalized to LOCALLY STRATIFIED PROGRAMS in
Przymusinski [1988]" (same Minker volume, pp. 193-216). "PERFECT MODEL" IS ALSO PRZYMUSINSKI'S — it occurs
once, p. 144, crediting him; ABW's canonical model is the STANDARD MODEL M_P (their term, p. 108).
ABW HAVE NO NUMBERED SECTIONS. Cite: Apt, Blair & Walker (1988), "Stratified Programs", DEFINITION 3, p. 96;
and LEMMA 1 proof, pp. 97-98, for the ≤/< split in words.

════ SITES — MEASURED, hyphen-tolerant predicates, controls fired ════
WRONG:
  gen-specs/den-hoag/REFERENCE.md:83 — TWO errors in ONE sentence. "This is the local-stratification
    discipline of Apt, Blair & Walker (1988): a predicate may depend only on strictly-lower strata."
    (a) misattribution — local stratification is Przymusinski, over ground atoms;
    (b) promotes the NEGATIVE rule to the GENERAL rule.
    The same sentence governs BOTH stratum-scope primitives, which do not share an answer.
  lib/stratum-scope.nix:2 — "A reader at stratum n may only see facts at strata STRICTLY BELOW n
    (Apt–Blair–Walker stratified-negation discipline)". Same over-restriction, in the KERNEL.
  lib/concern-policies.nix:101-102 — comment restates the strictly-lower rule; :129 IMPLEMENTS it as
    `if ks != null && stratumIndex.${ks} >= r then throw …`, applied by BOTH policy-compile branches.
CORRECT — DO NOT TOUCH:
  REFERENCE.md:89   the L4 negation contract (see below — it is the one that gets the subtle part right)
  REFERENCE.md:101  "positive same-stratum reads are permitted"; a readsAttrs-wide gate "would false-reject"
  REFERENCE.md:959  "same-stratum positive reads are permitted"
  gen-specs/gen-resolve/REFERENCE.md:40  "Positive dependencies at strata <= own are admitted"
CITATION HYGIENE ONLY: lib/concern-derived.nix:55 "(unsound, Apt–Blair–Walker §2.3)" and the milder
  ci/tests/negation-gate.nix:3. §2.3 is DEN-HOAG'S OWN spec section, used correctly at ~60 sites; only the
  adjacency to "Apt–Blair–Walker" misleads, and ABW has no numbered sections.
CONTAMINATION SWEEP: "perfect model" ZERO in repo and specs. "local-stratification" exactly ONE site (:83).
  Only TWO gen-specs files cite ABW by name. Controls fired on every predicate in the same run.

════ ★★ REFERENCE.md:89 ALREADY GETS IT RIGHT — this reframes the design question ════
"A negated predicate must be read through the THROWING gate (`node.rel`), NEVER the silent `node.query` —
negation reads a COMPLETE predicate, so a partial/off-stratum read is a CORRECTNESS ERROR, NOT AN EMPTY SET.
The negating derive must sit STRICTLY ABOVE every producer of a negated relation; a `negates` relation whose
stratum is not strictly below the derive throws at registration."
So den-hoag ALREADY routes negation through the LOUD gate ON PURPOSE — a SILENT empty result cannot
distinguish "absent" from "out of scope", which would make a negative read unsound. L4 enforces ABW's
negative rule EXACTLY WHERE NEGATION HAPPENS, via the declared `negates` surface.
(An earlier orchestrator hypothesis — silent surfaces carry negation, loud ones do not — is REFUTED by this
sentence. Recorded so it is not re-proposed.)

════ THE DESIGN QUESTION ════
Given L4 already enforces the negative rule where negation is DECLARED, what is the BLANKET strictly-below on
ALL reads doing? Exactly two possibilities, and the answer decides the design:
 (i) REDUNDANT with L4 for negation AND OVER-STRICT for positive reads — guarding a property a more precise
     mechanism already guarantees, while rejecting reads ABW permits; or
 (ii) it catches negative reads that DO NOT go through L4 — an UNDECLARED negation, a body branching on
     absence without declaring `negates` (`ctx ? key`, `or` defaults, `x == [ ]` after a silent query, a
     tryEval around a throwing read). IF THAT PATH EXISTS the blanket guard is load-bearing and the
     over-strictness is the price of catching undeclared negation.
SECONDARY: should the guard be the GRAPH PROPERTY instead? ABW's law is negative-edge acyclicity over a
signed dependency graph, decided by SCC condensation — which den-hoag already ships (gen-graph, validated
this session for another design). An index comparison APPROXIMATES the law; the law may be directly
expressible. If so, the index comparison is the v1-shaped answer.

════ LIVENESS ════
Inert ONLY because seededStrataCfg.ctxKeyStrata = { } (concern-policies.nix:90-93). ONE POPULATED ATTRIBUTE
FROM FIRING. Measured: untagged → ok; sameStratum {structural=["host"]} → THROWN (ABW ADMITS this); higher
{resolution=["host"]} → THROWN (correct; the positive control).

════ REQUIREMENTS ════
R1. DOC CORRECTIONS at REFERENCE.md:83 and stratum-scope.nix:2. NO DESIGN NEEDED — :83 contradicts :89, :101
    and :959 in the same document, so it is wrong on internal evidence alone, independent of ABW. Cite
    "Stratified Programs", DEFINITION 3, p. 96 — never "§2.3" as though it were ABW's.
R2. THE GUARD DECISION GOES THROUGH THE GATE (den-hoag-4kh.6, C1-C7) as a DESIGN. No kernel change before
    VALIDATED. Resolve (i) vs (ii) BY MEASUREMENT — the existence of an undeclared-negation path is the
    single fact that decides it.
R3. A TEST. No coverage of the same-stratum arm exists (the guard is inert, so nothing exercises it). The
    fixture must POPULATE ctxKeyStrata and PIN the ADMIT/REJECT split, armed against the CURRENT
    implementation, which it must drive RED for the same-stratum POSITIVE read. Lands as a known-fail with a
    tracked id under the three-state CI ruling.
R4. DO NOT TOUCH the four correct sites.
R5. CITATION HYGIENE at concern-derived.nix:55 and negation-gate.nix:3 — separate the ABW attribution from
    den-hoag's own §2.3.

════ ADJACENT FINDINGS FROM THE PRIMARY TEXT — file separately, do not scope-creep this bead ════
 · THEOREM 11 (p. 116): M_P is INDEPENDENT OF THE STRATIFICATION CHOSEN. The den analogue — output invariant
   under whichever phase assignment the scheduler picked — is ASSUMED, NOT WITNESSED. This is directly a CI
   witness generator: evaluate under two admissible stratifications, require byte-identical output. Stronger
   than the current negation-gate witnesses, which only check that a violation throws.
 · THEOREM 5 (p. 109) + DEFINITION 10: T_P is growing only when a stratum is SEMI-POSITIVE — Neg_P ∩ Def_P =
   ∅, i.e. NO NEGATED RELATION SYMBOL OCCURS IN A HEAD WITHIN THE STRATUM. Whether den-hoag's per-phase
   operators satisfy this is UNVERIFIED, and it is the precondition most easily violated by a derive that
   both `negates` a kind and PRODUCES it.
 · THEOREM 7 (p. 111): SUPPORTEDNESS — every atom in M_P is the head of a ground clause whose body holds.
   den-hoag has NO corresponding check that every materialized fact has a producing rule that fired.

════ INSTRUMENT HAZARDS, all measured ════
 · The archived markdown is OCR. On printed p. 98 the TEXT LAYER SILENTLY RENDERS "j ≤ i" AS "j < i",
   yielding well-formed text that reads as though both conditions were symmetric — and that is exactly the
   passage a grep lands on. Use the marked ARCHIVIST NOTE at the top of the file, or the PDF raster.
   Displayed mathematics is unreliable throughout, worst at printed pp. 102-110 (the M_P construction on
   pp. 107-108 is ABSENT from the text layer entirely).
 · TWO ORCHESTRATOR SWEEPS OF THIS BEAD'S OWN SCOPE WERE VACUOUS: one predicate ('local stratification')
   could not match the hyphenated form actually in the file; another carried `--include='*.nix'` across BOTH
   trees in one command, silently excluding every .md spec. A predicate that cannot match the at-risk path
   is this project's most-repeated false clean.


## Comments (19)

### 1 — 2026-07-28T02:24:43 · Jason Bowman

BODY REWRITTEN 2026-07-28 after the primary text was archived. Corrections to the previous body, each found by an agent re-running a claim rather than accepting it: (1) DEFINITION 3 is printed p. 96, not 97. (2) The 'local stratification = zero hits' framing was the WRONG PREDICATE - 'locally stratified' occurs ONCE, p. 144, and that hit is ABW's own disclaimer naming Przymusinski, so the attribution rests on a POSITIVE STATEMENT rather than an absence. (3) 'perfect model' is ALSO Przymusinski's term; ABW's is the STANDARD MODEL M_P. (4) The orchestrator's silent-vs-loud hypothesis is REFUTED by REFERENCE.md:89, which already routes negation through the THROWING gate precisely because a silent empty read cannot distinguish absent from out-of-scope - recorded so it is not re-proposed. (5) Scope re-measured with hyphen-tolerant predicates: only TWO gen-specs files cite ABW by name, ONE states the rule wrongly, THREE state it correctly. The design question is consequently NOT 'which operator' but 'given L4 already enforces the negative rule where negation is declared, is the blanket guard redundant or does it catch UNDECLARED negation'.

### 2 — 2026-07-28T02:29:39 · Jason Bowman

★★★ Q7 MEASURED — the undeclared-negation question is ANSWERED, and it refutes the case for the current guard.

PROVENANCE: probe q7-escape-routes.nix was AUTHORED BY the strata-analyst agent, which went idle ~2 minutes
after writing it without reporting. THE ORCHESTRATOR RAN IT. Result is a real nix eval against the live libs
(import den-hoag/default.nix {}), synthetic fleet via lib.mkDen. The agent's fuller Q1-Q5 context has NOT
been received, so this is one measurement, not the full analysis it was dispatched for.

  route0  control: loud out-of-scope read through node.rel      THROWN
  route1  builtins.tryEval wrapped around that same read        ESCAPED: false
  route2  silent node.query on an out-of-scope relation, == [ ] ESCAPED: true
  route3  undeclared negation on an IN-SCOPE relation, == [ ]   ESCAPED: true

CONTROL IS VALID: route0 throws, so the gate fires and the predicate discriminates. The three escapes are
real escapes, not a dead probe.

════ WHAT THIS SETTLES ════
The design question was: given L4 already enforces ABW's negative rule where negation is DECLARED
(REFERENCE.md:89 — `negates`, throwing gate, strictly-above at registration), is the blanket
`ks >= r -> throw` at lib/concern-policies.nix:129 (i) redundant-and-over-strict, or (ii) load-bearing
because it catches UNDECLARED negation?

⇒ (ii) IS REFUTED BY MEASUREMENT. The blanket guard does NOT catch undeclared negation.
ROUTE 3 IS DECISIVE: a derive at stratum `resolution` reads relation `memberOf` (at `rel:memberOf`, STRICTLY
BELOW it) and tests `targets == [ ]`. The stratum relation is CORRECT, so `ks >= r` never fires — and the
read is a negation the author never declared. The guard is satisfied and the negation is unchecked. Being
strictly-below does not make a read positive.

⇒ (i) HOLDS. The blanket strictly-below is redundant with L4 for declared negation, over-strict for positive
reads (ABW Definition 3 condition 1 admits ⋃_{j≤i}), and closes none of the undeclared-negation hole.
CONSEQUENCE FOR R2: relaxing `>=` to `>` does not remove a protection that was working. That is now measured
rather than argued.

════ ★ A SEPARATE AND LARGER FINDING — L4's CENTRAL CONTRACT IS UNENFORCED ════
REFERENCE.md:89 states: "A negated predicate must be read through the THROWING gate (`node.rel`), NEVER the
silent `node.query` — negation reads a COMPLETE predicate, so a partial/off-stratum read is a CORRECTNESS
ERROR, NOT AN EMPTY SET."
ROUTE 2 DOES EXACTLY THE FORBIDDEN THING AND RETURNS `true` WITH NO COMPLAINT. An out-of-scope silent query
yields [ ], `== [ ]` succeeds, and the reader cannot distinguish "absent" from "out of scope" — which is the
precise unsoundness the sentence exists to prevent.
THIS IS KERNEL-PURITY CRITERION 6 — an invariant documented but unenforced — IN THE L4 LAW ITSELF. A stated
law with no runtime guard is a comment.
ROUTE 1 compounds it: the LOUD gate is not a boundary a reader must respect. `builtins.tryEval` around
`node.rel.<kind>.targets` converts the named throw into a boolean, recovering observable absence at will.
So "route negation through the throwing gate" is not enforceable by the gate alone — the gate can be
demoted to silent by its caller.

════ WHAT THIS DOES NOT SETTLE ════
· Whether any CORPUS or KERNEL body actually performs an undeclared negation today. The probe shows the path
  is OPEN; it does not show it is TRAVELLED. That distinction matters and is NOT measured here.
· Route 3's soundness. Its stratum relation is ABW-correct, so it is not necessarily unsound — it is
  UNVERIFIED, because the L4 registration check that would confirm the strictly-above relation never runs
  when `negates` is undeclared. Route 2 is the one that is unsound outright.
· Q1/Q2/Q3/Q5 as dispatched — the guard inventory, liveness per guard, and the populated-ctxKeyStrata
  relaxation experiment. The analyst's probes q6-declared-vs-actual / q6-controls / q6-negedge / q6-negcycle
  / q6-usersurface exist in the scratchpad and were NOT run by the orchestrator.

════ CONSEQUENCE FOR THE BEAD ════
R2's deciding fact is now measured: the blanket guard is not load-bearing for undeclared negation. The
over-strictness is therefore correctable without loss.
NEW, and it should NOT be folded into this bead's scope: L4's throwing-gate contract is unenforced, and the
loud gate is tryEval-demotable. That is a distinct defect with its own criterion (6) and its own remedy
space, and it is larger than the strictness question this bead was opened for.


### 3 — 2026-07-28T02:31:56 · Jason Bowman

★★★ Q1-Q5 COMPLETE (strata-analyst, independent, all measured). VERDICT ON THE DESIGN QUESTION: (i).
THE BLANKET GUARD IS NOT LOAD-BEARING. R2 is decided, and it is decided against the current code.

════ Q4 — FOUR undeclared-negation routes, and a THIRD outcome the orchestrator's binary missed ════
The framing was "if such a path exists, the blanket guard is LOAD-BEARING". THE SECOND CLAUSE IS FALSE.
The paths exist AND the guard does not catch the ones that matter.
  route 0 CONTROL  loud out-of-scope node.rel read              THROWN    (gate fires in this fixture)
  route 1          builtins.tryEval AROUND the loud read        ESCAPED -> false
  route 2          undeclared negation via SILENT node.query    ESCAPED -> true
  route 3          undeclared negation node.rel.X == [ ], in-scope, negates = [ ]   ESCAPED -> true
  route 4          `ctx ? key` in a policy body                 ESCAPED -> UNSUPPORTED FACT (see 4kh.13)

★ ROUTE 2 IS THE PATH THAT WOULD MAKE THE GUARD LOAD-BEARING, AND IT IS A PATH THE GUARD CANNOT SEE. It
travels the SILENT surface (edgesBelowStratum), which ceilingGate's strictly-below does not touch; and L4
does not govern it because L4 ranges only over DECLARED `negates`.
ROUTE 1 is not itself unsound (distinguishing out-of-scope from absent is the SOUND direction) but it
refutes the CAPABILITY claim at lib/stratum-scope.nix:85-87 — "enforcement-by-construction, never
introspection ... the reader cannot read a fact at or above its own layer". The reader CAN observe the gate
as a boolean. THE LOUD GATE IS A SPEED BUMP, NOT AN ENFORCEMENT BOUNDARY; the comment overstates it.
ROUTE 3 is undeclared but SOUND (static EDB, strictly below) — it shows `negates` is DECORATIVE: nothing
requires a body to declare the negations it performs.
⇒ Where negation is DECLARED, L4 already enforces it (concern-derived.nix:56 routing + :63 strictly-above).
Where it is UNDECLARED, the blanket guard misses routes 2 and 4, is defeated by route 1, and "catches" only
route 3, which was already sound. And for POSITIVE reads it applies the NEGATIVE rule where ABW Def 3
cond 1 admits ⋃_{j≤i}.

════ Q5 — RELAXATION BREAKS NOTHING, and the control is what makes that credible ════
Full lib/ copy in scratchpad, ONE CHARACTER changed (`>= r` -> `> r` at concern-policies.nix:129). Repo file
NOT modified (diffed both steps). Full CI suite:
    baseline /nix/store/1wa4v9rhi30dazyby37jqmlj9liskfg5-den-hoag-tests
    relaxed  /nix/store/1wa4v9rhi30dazyby37jqmlj9liskfg5-den-hoag-tests    BYTE-IDENTICAL
★ POSITIVE CONTROL THAT THE RELAXED TREE IS GENUINELY CONSUMED — an identical store path invites exactly the
"my patch was never read" trap: line 129 was replaced with `if true then` and THE BUILD FAILED. Patch
restored, identical path returned.
Six-arm matrix, positive controls intact in both columns: same-stratum arms flip THROWN -> OK; strictly-above
arms stay THROWN in both; strictly-below arms OK in both.
WHY NOTHING BREAKS: ctxKeyStrata = { } at both sites, so projectCtx is a total no-op on every fleet. Only
three tests populate it (edge-substrate.nix:596 empty, :619 ks>r, :647 ks<r). ★ NO TEST PINS ks == r —
the arm the whole question is about is untested.
ANALYST'S OWN METHOD CORRECTION, recorded because it is the failure mode this arc keeps paying for: the first
attempt used `builtins.length`, which forces only the list spine, reported OK across the board, and COULD
NOT HAVE CAUGHT THE THROW. Corrected to force the declarations; `sanity-acts-are-forced = true` is now in the
fixture.

════ Q3 — LIVENESS, and a CORRECTION TO THIS BEAD'S OWN TEXT ════
★ projectCtx is NOT "one populated attribute from firing". ctxKeyStrata = { } is a HARDCODED LITERAL at TWO
sites — lib/concern-policies.nix:92 AND lib/default.nix:1453 — and NO `den.*` mkOption feeds it (39 mkOption
in default.nix, none for it). IT IS A KERNEL EDIT AWAY, NOT USER-REACHABLE. The bead's earlier "one
attribute from firing" is corrected by this.
LIVE: #14 gen-resolve DP1 (every mkDen); #7 productions L2 (measured firing — below OK / same THROWN /
above THROWN). LIVE-ON-DECLARATION: ceilingGate, edgesBelowStratum in mkDerived; claim-accessor.
DISABLED AT EVERY SHIPPED CALL SITE: mkRelQuery/mkRelAccessor ceilings — ceiling=null at
resolution-relations.nix:48 and default.nix:2154. ★ THE REASON IS IN-CODE AND IT IS THE OVER-STRICTNESS
ITSELF: "the relation accessor AND its relations both sit at `resolution`, so a strictly-below ceiling would
exclude every relation". THE COST OF THE WRONG RULE IS ALREADY BEING PAID — both shipped call sites of the
silent filter are switched OFF to avoid it.
INERT: bounded-NTA (no emit="nodes" declared); `negates` guards — ZERO kernel negates declarations, guard
plus two tests only.

════ Q1 — 14 GUARDS. Only ONE implements ABW's positive rule correctly ════
#14 gen-resolve/lib/schedule.nix:87 `pb > pa` — STRICTLY-LATER ONLY, on the readsAttrs surface. Every other
scope guard uses `>=`/strictly-below. Full table in the analyst transcript; objects span relation EDGES
(silent), per-kind relation records (loud), ctx fact VALUES (loud), and declared `over`/`negates`/`from`
(loud, definition-time).

════ Q2 — THE LOUD THROW IS CATCHABLE. THREE outcomes, not one ════
  in-scope kind, no edges  -> [ ]                      absence plainly observable
  out-of-scope kind        -> CATCHABLE throw          observable, and DISTINCT from [ ]
  unknown kind             -> attribute miss, UNCATCHABLE (eval exit=1)
The shipped suite already RELIES on catchability: ci/tests/stratum-scope.nix:19 and
ci/tests/claim-provider.nix:229. And the SILENT surface conflates absent with out-of-scope, pinned twice:
claim-provider.nix:218 (out-of-scope -> [ ]) and :223 (missing kind -> [ ]).

════ COMPLETENESS — the reframe holds, and it reinforces (i) ════
den-hoag runs NO bottom-up saturation where the guards are armed (gen-resolve schedule.nix:4-5 "runtime
order is DEMAND"; resolve.nix:60 `lib.fix demand`). Completeness holds for OTHER reasons: relation/claim
predicates are a STATIC EDB assembled before and outside the schedule (default.nix:2127); attributes are
guarded by purity + acyclicity (Knuth gate, badSccs); ctx keys are the ONE real T↑ω (scope.circular,
structural.nix:136-148) — WHICH HAS NO PARTITION AND NO GUARD.
⇒ EVERY ARMED INDEX GUARDS A COMPLETENESS THAT ALREADY HOLDS UNCONDITIONALLY. THE ONE PLACE COMPLETENESS IS
NOT FREE HAS NO INDEX AT ALL. That is 4kh.13.

════ ★★ THE GRAPH IS ALREADY THERE. WHAT IS MISSING IS THE SIGN ════
gen-resolve ALREADY builds ABW's dependency graph and ALREADY condenses it —
schedule.nix:36 `edges = a: filter (b: equations ? b) (equations.a.readsAttrs)`, :41
`cond = graph.condensation attrAccessor`. That is Definition 4's graph and the SCC decomposition Lemma 1's
converse constructs. The existing test is KNUTH CIRCULARITY — UNSIGNED — so it is stricter than ABW in one
direction (forbids positive-only cycles ABW permits) and blind in the other (a negative cycle is invisible).
CONSTRUCTIBILITY BY DOMAIN: attributes — edges YES (readsAttrs), sign NO, graph already built.
derives × relation kinds — edges YES, SIGN YES (over/negates) — THE ONLY SIGNED EDGE SET IN THE SYSTEM.
productions — `from` names a STRATUM not a predicate, sign NO. policies × ctx keys — positive only
(functionArgs), SIGN NOT DERIVABLE, because negatives live inside opaque `ctx: [decls]` bodies and pure Nix
cannot introspect them.
★ AND DECLARED EDGES ARE UNENFORCED IN EVERY DOMAIN (q6-declared-vs-actual.nix): a production with
`readsAttrs = [ ]` successfully self.get'd `resolved-settings`; a derive with `over = [ ]` and
`negates = [ ]` successfully did BOTH a positive read AND a negation. Positive controls that these surfaces
CAN block: self.get of a nonexistent attr BLOCKED; derive reading its own-stratum relation BLOCKED.
⇒ ANY GRAPH BUILT FROM DECLARATIONS UNDER-APPROXIMATES THE REAL EDGES. A signed-graph guard cannot be built
on today's declarations without first making declarations binding.

════ CORRECTIONS TO THE RECORD ════
· REFERENCE.md:959 DOES NOT EXIST — the file is 430 lines. Verified by the orchestrator. The third correct
  site is :121 (claim-accessor: "an INTRA-stratum positive read (A9, Apt–Blair–Walker 1988 — same-stratum
  positive reads are permitted)"). The four rule statements are :83 WRONG, :89 :101 :121 CORRECT. The
  orchestrator propagated :959 from an upstream report without checking it.
· THE ERROR WAS INTRODUCED IN REFERENCE.md, NOT INHERITED FROM THE DESIGN.
  specs/2026-07-20-den-hoag-productions-substrate-design.md:31 states it CORRECTLY: "strata <= its own for
  positive dependencies and strictly below for negated". So :83 is a documentation REGRESSION against a
  design that had it right.
· Contamination, unfiltered re-check: "perfect model" 0 in-repo; "local.stratif" 2 in-repo, BOTH in
  .beads/beads.jsonl (our own issue records describing this finding), NOT source or spec contamination.
  Positive control: 13 unfiltered ABW-citation hits.
· ANALYST CLAIM REFUTED BY THE ORCHESTRATOR: "the ABW primary text was in the archive all along". It was
  NOT — used/markdown/apt-1988-…md is timestamped 2026-07-27 19:14, created that day by the paper-locator;
  arntzenius-2016 dates from 2026-05-23. The analyst read a file written ~10 minutes earlier. The original
  archive check was accurate.

════ NOT COVERED — stated as limits ════
· Whether route 4's unsupported fact PROPAGATES INTO MATERIALIZED OUTPUT. Unmeasured, not guessed. This is
  the fact separating "latent soundness hole" from "observable corpus bug". Carried on 4kh.13.
· No external corpus scan — cannot say whether ANY of the four routes is CURRENTLY TAKEN by real config.
· Relaxation tested for projectCtx ONLY. ceilingGate, productions L2 and claim-accessor untested — and L2 is
  LIVE, so relaxing it WOULD change behaviour.
· Theorem 11 analogue (output invariance across admissible stratum orders): PROBABLE-ABSENT, NOT
  PROVEN-ABSENT — the five strata suites were located but not read in full.
· ABW Theorems 4/5/6/11 and Definitions 10/12 are taken from the orchestrator's messages and the archivist
  note, NOT the analyst's own reading — those pages fall in the range flagged OCR-unreliable for displayed
  mathematics. Its own reading covers Def 2/3/4, Lemma 1 and the Bibliographic Remarks.


### 4 — 2026-07-28T02:38:57 · Jason Bowman

R1 + R5 COMPLETE (independent agent, 2026-07-28). NOT COMMITTED — edits sit in the working tree of two repos.

FOUR SITES CORRECTED, comments and prose only:
1. papers/den-architecture/gen-specs/den-hoag/REFERENCE.md:83 — the two-error sentence replaced. New text
   cites "Stratified Programs", Definition 3, p. 96; states that strictly-below binds NEGATIVE dependencies
   only and that same-stratum positive reads are permitted; and describes den-hoag's blanket ceiling as its
   own CAPABILITY CHOICE, "narrower than stratification alone requires". R2 NOT PREEMPTED — no should/will.
   Reuses the phrasing already at :101/:121 verbatim so the document CONVERGES rather than gaining a fifth
   wording. (The regression at :83 arose precisely from a fresh wording — see the provenance note: the
   2026-07-20 design spec had it right.)
2. lib/stratum-scope.nix:1-4 — the two claims split. The ceiling is attributed to den-hoag; the ABW
   parenthetical now says only what ABW says. "(spec §2.3)" KEPT — that is den-hoag's own section.
3. lib/stratum-scope.nix:86-92 — the measured overstatement removed. "never introspection — the reader
   cannot read a fact at or above its own layer" is GONE, replaced by "the gate withholds the VALUE, not the
   OBSERVATION", naming the tryEval recovery and noting it is the SOUND direction (out-of-scope
   distinguishable from absent). This site would not have been found without the route-1 probe.
4. R5 citation hygiene — lib/concern-derived.nix:55 and ci/tests/negation-gate.nix:3 now lead with §2.3 as
   den-hoag's own reference and name the discipline as "after Apt–Blair–Walker stratified negation", so no
   paper section number is implied.

★ VERIFICATION — AST COMPARISON, NOT A COMMENT GREP.
`nix-instantiate --parse` (which drops comments) run on HEAD vs worktree for all three .nix files:
IDENTICAL (1586 / 4614 / 2281 bytes). That proves NO EXPRESSION MOVED, which a comment-line grep cannot.
POSITIVE CONTROL A: `strataLt`'s `<` flipped to `<=` in a scratch copy — the AST compare FIRED
(`__lessThan a b` vs `! (__lessThan b a)`). The predicate is not blind.
POSITIVE CONTROL B: the comment-only grep, run on the same mutated copy, emitted the `<`/`<=` pair.
nixfmt --check CLEAN on all three; added lines within each file's pre-existing max comment width.

DO-NOT-TOUCH CONFIRMED: the papers diff is EXACTLY ONE LINE (:83). REFERENCE.md :89/:101/:121 untouched;
gen-specs/gen-resolve/REFERENCE.md not in the diff at all.

WORKING-TREE ATTRIBUTION, measured by mtime so nothing is mis-blamed at staging time:
  papers/den-architecture  gen-specs/den-hoag/REFERENCE.md   19:35  R1 (this work)
                           used/INDEX.md                     19:25  orchestrator (ABW archive entry)
                           used/KEYSTONES.md                 19:20  orchestrator (ABW archive entry)
                           gen-specs/gen-schema/REFERENCE.md 10:44  ★ PRE-EXISTING, hours before this arc —
                                                                    NOT from any agent in this session
  den-hoag                 .gitignore / CLAUDE.md / .beads/beads.jsonl — pre-existing at session start
NOTE: ~/Documents/papers is NOT a git repo but ~/Documents/papers/den-architecture IS. An earlier
orchestrator check ran at the parent, got "not a git repository", and wrongly concluded the papers tree was
unversioned. Separately, specs/2026-07-27-class-reroute-confluence-design.md is UNTRACKED, so no committed
baseline for it exists either way.

REMAINING ON THIS BEAD: R2 (the guard design → gate, deciding fact already measured: the blanket guard is
NOT load-bearing) and R3 (the test — and note NO EXISTING TEST PINS ks == r, the arm the question turns on).


### 5 — 2026-07-28T03:33:48 · Jason Bowman

R2 DESIGN SPEC WRITTEN — papers/den-architecture/specs/2026-07-28-stratum-guard-positive-read-design.md
(829 lines). Awaiting gate review. den-hoag untouched by the author; no beads, no commits.

★★ THE ORCHESTRATOR'S FRAMING WAS WRONG AND THE AUTHOR MEASURED IT. The dispatch said the main deliverable
was "does correcting the rule let the disabled ceilings be turned back on", on the premise that the wrong
rule got a feature disabled. MEASURED: THE DISABLEMENT REASON IS STALE, not caused by the operator.
resolution-relations.nix:44-48 says the accessor and its relations both sit at `resolution`, so a
strictly-below ceiling would exclude every relation — AND NAMES ITS OWN UNBLOCK CONDITION ("The per-relation
reader-stratum ceiling arrives with §11 L2"). That condition HAS SHIPPED: concern-relations.nix:22,82,92-96
mint each relation at `rel:<name>` inserted after `structural`, EDB-bottom-pinned below `resolution`.
Probe r2-ceiling-reenable.nix on a one-relation fleet: compiled order
[structural, rel:memberOf, resolution, collection, demand, output]; rel:memberOf idx 1 < resolution idx 2;
at a `resolution` ceiling 2 of 2 relation edges SURVIVE the CURRENT strictly-below filter. Positive control:
at a ceiling equal to the relation's own stratum, 0 survive.
⇒ The comment was TRUE WHEN WRITTEN AND OUTLIVED ITS CONDITION. The cost of the wrong rule is HISTORICAL,
not current. Verified independently by the orchestrator.

PER-CALL-SITE VERDICTS, measured (r2-ceiling-observable.nix, synthetic non-relation pool edge modelling a
claim edge):
 · #13 mkRelAccessor — RE-ENABLE. Ceiling on vs off gives a BYTE-IDENTICAL per-node record, both controls
   firing (non-vacuous; emptied at own stratum). NEEDS NO OPERATOR CHANGE.
 · #12 mkRelQuery — DO NOT re-enable. Following a non-relation kind returns ["node:b"] at ceiling=null and
   [ ] at ceiling=idx(resolution): it silently AMPUTATES THE CLAIM POOL from a surface that has no reader.
   Its stale reason should be replaced with the real one — no reader, therefore no ceiling.
 · COST GATE ON THE RE-ENABLEMENT: resolution-relations.nix:38-49 applies mkRelAccessor INSIDE the per-node
   `compute = _self: id:` lambda. With ceiling=null that is free (concern-relations.nix:201 short-circuits);
   with a ceiling it becomes O(N·|relationEdges|). THE RE-ENABLEMENT MUST HOIST THE PARTIAL APPLICATION OUT
   OF THE id-LAMBDA OR NOT LAND.

THE DESIGN RULE: runtime read guards implement ABW Definition 3 CONDITION 1; condition 2 is enforced exactly
where polarity is DECLARED (`negates`, concern-derived.nix:64 — unchanged). Justification: `node.rel` and
`node.query` differ in LOUDNESS, not POLARITY, and den-hoag conflates the two by giving the loud surface the
negative rule. A GATE THAT CANNOT SEE POLARITY MUST IMPLEMENT THE RULE CORRECT FOR ALL READS.
Decided per guard. L2 (concern-productions.nix:102) and L5 clause 2 (production-guard.nix:43) are UNCHANGED
FOR A REASON DISTINCT FROM "leave it alone": they gate a declared SOURCE contract feeding VALUE INVENTION,
whose theorem is Vogt 1989 / Fagin et al. 2005 well-foundedness — NOT ABW negation-stratification.
production-guard.nix:41-42 already says so in its own words.
HONEST RESIDUAL (§3.1): the change gives up ONE sub-case the current operator catches BY ACCIDENT — an
undeclared negation over a SAME-stratum relation. Bounded, because undeclared negation over anything
strictly below already escapes (route 3).

★ FOUR THINGS THE DISPATCH DID NOT HAVE:
1. TEST BLAST RADIUS, bigger than the missing edge-substrate fixture. ci/tests/stratum-scope.nix tests
   lib/stratum-scope.nix DIRECTLY and PINS THE CURRENT OPERATOR BY ASSERTION. Replaying its own fixtures
   through the proposed core (core-vs-suite.nix): EXACTLY 3 of its 11 tests go RED —
   test-edges-below-s1-empty, test-edges-below-s2, test-gate-blocks-at-ceiling — and the other 8 stay green.
   The blast radius is precisely the assertions encoding the defect.
2. TOTALITY DEFECT IN THE GUARD UNDER CHANGE, measured (r2-totality.nix). concern-policies.nix:122
   `r = stratumIndex.${ruleStratum}` HAS NO FALLBACK: a rule whose stratum is absent from the supplied order
   aborts with `attribute 'structural' missing` and TRYEVAL DOES NOT CATCH IT. Reachable through
   internal.compilePoliciesWithStrata, the seam edge-substrate.nix:16 already binds. The proposed core makes
   it a NAMED throw — the one part of the design that CLOSES a hole rather than widening one.
3. ROUTE 4's MECHANISM SUBSTANTIATED (mechanism only, not propagation). projectCtx is a `mapAttrs`, so it
   replaces VALUES and PRESERVES KEYS. Measured: with `thing` tagged at resolution for a structural rule
   (the throwing case), a body testing `ctx ? thing` WITHOUT FORCING IT produced 1 act and did NOT throw.
   ⇒ PROJECTCTX CANNOT BE A NEGATION GUARD — the only negation-shaped read over an attrset is INVARIANT
   under it. Stronger than "the guard is inert".
4. R1 RESIDUAL, reported not fixed: the introspection overstatement survived verbatim at
   concern-derived.nix:126-127. FIXED AND COMMITTED BY THE ORCHESTRATOR at a40cc96 (comments only, AST
   verified identical with a positive control).

EXECUTABLE CORE: one BEGIN/END-delimited fenced block, extracted, parsed and EVALUATED against the real
den-hoag primitives (core-check.nix). 104 lines, 73 comment-stripped,
sha256 c86793d5ce4884d8aa74c09597a0be0f7d37714a3fa516b711b4aecb563c288a. Guards take an ADMITTANCE
PREDICATE rather than a fixed operator; the negativeGate instantiation is the CONTROL — same lines, opposite
answer on the same-stratum kind — so a positiveGate that admitted everything could not pass unnoticed.
The author confirmed the exact proposed ks==r fixture (linkFoo, ctxKeyStrata.structural=["thing"]) THROWS on
the current tree, so R3's test lands RED as required.

COULD NOT SUBSTANTIATE — the author's own list, carried verbatim so the gate can weigh it:
routes 0-3 and the Q4 matrix (attributed to the analyst, not re-run); the full-CI byte-identical store path
and the `if true then` consumption control (attributed, suite NOT run); the #7 productions-L2 firing matrix
(attributed); the analyst's 14-guard table — NOT ON THE BEAD AND NOT IN THE SCRATCHPAD, the author's own
enumeration is 15 rows (3 shared primitives + 12 call sites) and it COULD NOT RECONCILE 12 AGAINST 14 and
says so in §2; ABW printed pp. 102-110 (taken from the bead and archivist note, in the OCR-unreliable range,
raster not rendered); whether claimKinds strata are validated against the compiled order (relation kinds are,
default.nix:1332-1335); and NO CORPUS SCAN — it cannot say whether any real config declares a derive or
production positioned to be affected.
★ AND THE LIMIT THE GATE SHOULD HOLD IT TO: the byte-identity measurement exists ONLY for projectCtx, WHICH
IS INERT. §9.4 states that node.rel, node.query, `over`, the claim accessor and the re-enabled ceiling EACH
need their own baseline-vs-changed check with a consumption control, and NONE may land on the projectCtx
result.


### 6 — 2026-07-28T03:33:57 · Jason Bowman

R2 DESIGN SPEC WRITTEN — papers/den-architecture/specs/2026-07-28-stratum-guard-positive-read-design.md
(829 lines). Awaiting gate review. den-hoag untouched by the author; no beads, no commits.

★★ THE ORCHESTRATOR'S FRAMING WAS WRONG AND THE AUTHOR MEASURED IT. The dispatch said the main deliverable
was "does correcting the rule let the disabled ceilings be turned back on", on the premise that the wrong
rule got a feature disabled. MEASURED: THE DISABLEMENT REASON IS STALE, not caused by the operator.
resolution-relations.nix:44-48 says the accessor and its relations both sit at `resolution`, so a
strictly-below ceiling would exclude every relation — AND NAMES ITS OWN UNBLOCK CONDITION ("The per-relation
reader-stratum ceiling arrives with §11 L2"). That condition HAS SHIPPED: concern-relations.nix:22,82,92-96
mint each relation at `rel:<name>` inserted after `structural`, EDB-bottom-pinned below `resolution`.
Probe r2-ceiling-reenable.nix on a one-relation fleet: compiled order
[structural, rel:memberOf, resolution, collection, demand, output]; rel:memberOf idx 1 < resolution idx 2;
at a `resolution` ceiling 2 of 2 relation edges SURVIVE the CURRENT strictly-below filter. Positive control:
at a ceiling equal to the relation's own stratum, 0 survive.
⇒ The comment was TRUE WHEN WRITTEN AND OUTLIVED ITS CONDITION. The cost of the wrong rule is HISTORICAL,
not current. Verified independently by the orchestrator.

PER-CALL-SITE VERDICTS, measured (r2-ceiling-observable.nix, synthetic non-relation pool edge modelling a
claim edge):
 · #13 mkRelAccessor — RE-ENABLE. Ceiling on vs off gives a BYTE-IDENTICAL per-node record, both controls
   firing (non-vacuous; emptied at own stratum). NEEDS NO OPERATOR CHANGE.
 · #12 mkRelQuery — DO NOT re-enable. Following a non-relation kind returns ["node:b"] at ceiling=null and
   [ ] at ceiling=idx(resolution): it silently AMPUTATES THE CLAIM POOL from a surface that has no reader.
   Its stale reason should be replaced with the real one — no reader, therefore no ceiling.
 · COST GATE ON THE RE-ENABLEMENT: resolution-relations.nix:38-49 applies mkRelAccessor INSIDE the per-node
   `compute = _self: id:` lambda. With ceiling=null that is free (concern-relations.nix:201 short-circuits);
   with a ceiling it becomes O(N·|relationEdges|). THE RE-ENABLEMENT MUST HOIST THE PARTIAL APPLICATION OUT
   OF THE id-LAMBDA OR NOT LAND.

THE DESIGN RULE: runtime read guards implement ABW Definition 3 CONDITION 1; condition 2 is enforced exactly
where polarity is DECLARED (`negates`, concern-derived.nix:64 — unchanged). Justification: `node.rel` and
`node.query` differ in LOUDNESS, not POLARITY, and den-hoag conflates the two by giving the loud surface the
negative rule. A GATE THAT CANNOT SEE POLARITY MUST IMPLEMENT THE RULE CORRECT FOR ALL READS.
Decided per guard. L2 (concern-productions.nix:102) and L5 clause 2 (production-guard.nix:43) are UNCHANGED
FOR A REASON DISTINCT FROM "leave it alone": they gate a declared SOURCE contract feeding VALUE INVENTION,
whose theorem is Vogt 1989 / Fagin et al. 2005 well-foundedness — NOT ABW negation-stratification.
production-guard.nix:41-42 already says so in its own words.
HONEST RESIDUAL (§3.1): the change gives up ONE sub-case the current operator catches BY ACCIDENT — an
undeclared negation over a SAME-stratum relation. Bounded, because undeclared negation over anything
strictly below already escapes (route 3).

★ FOUR THINGS THE DISPATCH DID NOT HAVE:
1. TEST BLAST RADIUS, bigger than the missing edge-substrate fixture. ci/tests/stratum-scope.nix tests
   lib/stratum-scope.nix DIRECTLY and PINS THE CURRENT OPERATOR BY ASSERTION. Replaying its own fixtures
   through the proposed core (core-vs-suite.nix): EXACTLY 3 of its 11 tests go RED —
   test-edges-below-s1-empty, test-edges-below-s2, test-gate-blocks-at-ceiling — and the other 8 stay green.
   The blast radius is precisely the assertions encoding the defect.
2. TOTALITY DEFECT IN THE GUARD UNDER CHANGE, measured (r2-totality.nix). concern-policies.nix:122
   `r = stratumIndex.${ruleStratum}` HAS NO FALLBACK: a rule whose stratum is absent from the supplied order
   aborts with `attribute 'structural' missing` and TRYEVAL DOES NOT CATCH IT. Reachable through
   internal.compilePoliciesWithStrata, the seam edge-substrate.nix:16 already binds. The proposed core makes
   it a NAMED throw — the one part of the design that CLOSES a hole rather than widening one.
3. ROUTE 4's MECHANISM SUBSTANTIATED (mechanism only, not propagation). projectCtx is a `mapAttrs`, so it
   replaces VALUES and PRESERVES KEYS. Measured: with `thing` tagged at resolution for a structural rule
   (the throwing case), a body testing `ctx ? thing` WITHOUT FORCING IT produced 1 act and did NOT throw.
   ⇒ PROJECTCTX CANNOT BE A NEGATION GUARD — the only negation-shaped read over an attrset is INVARIANT
   under it. Stronger than "the guard is inert".
4. R1 RESIDUAL, reported not fixed: the introspection overstatement survived verbatim at
   concern-derived.nix:126-127. FIXED AND COMMITTED BY THE ORCHESTRATOR at a40cc96 (comments only, AST
   verified identical with a positive control).

EXECUTABLE CORE: one BEGIN/END-delimited fenced block, extracted, parsed and EVALUATED against the real
den-hoag primitives (core-check.nix). 104 lines, 73 comment-stripped,
sha256 c86793d5ce4884d8aa74c09597a0be0f7d37714a3fa516b711b4aecb563c288a. Guards take an ADMITTANCE
PREDICATE rather than a fixed operator; the negativeGate instantiation is the CONTROL — same lines, opposite
answer on the same-stratum kind — so a positiveGate that admitted everything could not pass unnoticed.
The author confirmed the exact proposed ks==r fixture (linkFoo, ctxKeyStrata.structural=["thing"]) THROWS on
the current tree, so R3's test lands RED as required.

COULD NOT SUBSTANTIATE — the author's own list, carried verbatim so the gate can weigh it:
routes 0-3 and the Q4 matrix (attributed to the analyst, not re-run); the full-CI byte-identical store path
and the `if true then` consumption control (attributed, suite NOT run); the #7 productions-L2 firing matrix
(attributed); the analyst's 14-guard table — NOT ON THE BEAD AND NOT IN THE SCRATCHPAD, the author's own
enumeration is 15 rows (3 shared primitives + 12 call sites) and it COULD NOT RECONCILE 12 AGAINST 14 and
says so in §2; ABW printed pp. 102-110 (taken from the bead and archivist note, in the OCR-unreliable range,
raster not rendered); whether claimKinds strata are validated against the compiled order (relation kinds are,
default.nix:1332-1335); and NO CORPUS SCAN — it cannot say whether any real config declares a derive or
production positioned to be affected.
★ AND THE LIMIT THE GATE SHOULD HOLD IT TO: the byte-identity measurement exists ONLY for projectCtx, WHICH
IS INERT. §9.4 states that node.rel, node.query, `over`, the claim accessor and the re-enabled ceiling EACH
need their own baseline-vs-changed check with a consumption control, and NONE may land on the projectCtx
result.


### 7 — 2026-07-28T03:42:57 · Jason Bowman

★ RECORD REPAIR — THE Q1 GUARD TABLE, RESTORED. And an orchestrator failure worth naming.

WHAT WENT WRONG: when the Q1-Q5 analysis was recorded, the orchestrator COMPRESSED the analyst's 14-row
guard table into a one-line class characterization and wrote "Full table in the analyst transcript" — then
STOPPED THAT AGENT. The rows were therefore unrecoverable from the durable record. The orchestrator then
told a downstream author "the table is on the bead" and pinned guard numbers (#1,#2,#3,#10,#11) that had
only ever existed in a dispatch prompt, not in any bead. A grep for guard numbers across this bead returns
exactly four (#7,#12,#13,#14).
⇒ COMPRESSING A MEASURED TABLE INTO PROSE AND THEN DISCARDING THE SOURCE IS A RECORD FAILURE, not an
economy. If a measurement is worth citing later it goes in whole. The bead IS the record; the transcript is
not.

RESTORED BELOW, reconstructed by the R2 spec author from the class characterization, with completeness
positive-controlled. It closes exactly, with no free parameters.

  relation EDGES — SILENT filter (5)
    lib/stratum-scope.nix:83            edgesBelowStratum, `< ceiling`
    lib/concern-derived.nix:147         scopedEdges = strataScope.edgesBelowStratum   (was :146 pre-a40cc96)
    lib/attributes/claim-accessor.nix:52  scopedPool, `<` via edgesBelowStratum
    lib/concern-relations.nix:158       mkRelQuery ceiling            — DISABLED at every shipped call site
    lib/concern-relations.nix:204       mkRelAccessor ceiling         — DISABLED at every shipped call site

  per-KIND relation records — LOUD gate (3)
    lib/stratum-scope.nix:110           ceilingGate, `>= ceilingIdx`
    lib/concern-derived.nix:132-133     gatedRel / ceilingGate application
    lib/attributes/claim-accessor.nix:43  inScope, `< ceiling` over claim KINDS

  ctx fact VALUES — LOUD (1)
    lib/concern-policies.nix:129        projectCtx, `>= r`            — INERT and NOT user-reachable

  declared over / negates / from — LOUD, DEFINITION-TIME (4)
    lib/concern-derived.nix:47          `over` notLater, !strataLt
    lib/concern-derived.nix:64          `negates` strictly-above, !strataLt
    lib/concern-productions.nix:102     productions L2 over declared `from` SOURCES   — LIVE, measured firing
    lib/production-guard.nix:43         bounded-NTA clause 2 over `from` of emit=nodes

  schedule-time (1)
    gen-resolve/lib/schedule.nix:87     DP1, `pb > pa` STRICTLY-LATER ONLY, readsAttrs surface
                                        ★ THE ONLY GUARD IMPLEMENTING ABW's POSITIVE RULE CORRECTLY

                                        5 + 3 + 1 + 4 + 1 = 14

THE 15th ROW, and why the counts differed: `strataLt` at lib/stratum-scope.nix:21-23 is the bare `<`
PREDICATE the four definition-time guards call. It guards nothing on its own. The R2 spec lists it as a
PRIMITIVE; the analyst did not count it. ⇒ 14 vs 15 IS A COUNTING CONVENTION, NOT A DISAGREEMENT ABOUT THE
GUARD SURFACE. Same members, same files, same lines, same operators. The open item in the R2 spec's §2 is
CLOSED.

COMPLETENESS, positive-controlled: a ripgrep sweep over den-hoag/lib plus all 23 gen-*/lib
(`indexOf strata`, `strataLt`, `ceilingGate`, `edgesBelowStratum`, `stratumIndex.`, `posOf strata`,
`pb > pa`) recovered all 15 rows — so the predicate is not blind — and found NO guard outside den-hoag/lib
and gen-resolve/lib. gen-resolve contributes exactly one; gen-rebuild's single hit is a comment
(restabilize.nix:47); the other 21 libs contribute nothing.

CAVEAT, carried because it is the honest limit: this is a RECONSTRUCTION from the compressed class
characterization, not a row-by-row comparison against the analyst's original table, which no longer exists
in readable form. If that table ever resurfaces and its 14 differ from these 14, THAT IS A REAL FINDING and
this record is wrong.

★★ TOOLING TRAP, measured, and it invalidates absence claims made this session through the wrapper:
`grep -rnE` through this session's grep wrapper returned ZERO hits in lib/stratum-scope.nix while a DIRECT
grep on the same file returned 28. The author did not trust the zero and cross-checked with ripgrep. ANY
ABSENCE CLAIM MADE VIA `grep -rnE` IN THIS SESSION NEEDS RE-CHECKING WITH ripgrep OR A DIRECT PER-FILE GREP.

CITATION DRIFT INTRODUCED BY a40cc96 (orchestrator): that commit added a net +1 line at
lib/concern-derived.nix:126-127, shifting citations below it. In the R2 spec, `:146` -> `:147` (five
occurrences), `:132` -> `:132-133`, and §11's R1-residual bullet is now discharged. Prose only; the
executable core cites no line numbers and its hash is unchanged. The gate has the erratum.
⇒ LESSON: FREEZING A SPEC DOES NOT FREEZE THE TREE IT CITES. An anchor must cover both, or a commit landed
between freeze and review silently invalidates every line reference in the document.


### 8 — 2026-07-28T03:44:50 · Jason Bowman

RECONCILIATION CLOSED, with stronger evidence than the previous comment, plus TWO ORCHESTRATOR CORRECTIONS.

★ CORRECTION 1 — THE COMPARISON WAS NEVER "12 AGAINST 14". The orchestrator framed it that way twice,
including in the previous bead comment, and it is CATEGORY-MISMATCHED: the analyst's 14 INCLUDES the
primitives (the orchestrator's own dispatch numbered them #1 `edgesBelowStratum` and #2 `ceilingGate`), so
the analyst counts primitives as guards. THE REAL COMPARISON IS 15 AGAINST 14. DELTA: ONE ROW. The bad
framing made the gap look substantive and sent an author hunting a discrepancy that was largely arithmetic.

★ CORRECTION 2 — THE TABLE'S ABSENCE IS NOW PROVEN AT THE STORAGE LAYER, not inferred from the renderer.
The author considered that `bd show` might be truncating — the charitable reading of the orchestrator's
claim that the table was on the bead — and tested it directly:
 · `bd show --json` CARRIES NO COMMENTS AT ALL (keys: id, title, description, …, comment_count).
 · Read from .beads/beads.jsonl instead: den-hoag-4kh.11 has THREE comments (1151 / 4513 / 10338 chars).
   The "Q1-Q5 COMPLETE" comment is comments[2]; its Q1 section is 419 characters, 6 lines, and consists of
   the count, guard #14, the four object classes, and the words "Full table in the analyst transcript".
   No columns. Rendered and raw AGREE — `bd show` was not hiding anything.
 · EXHAUSTIVE CONTROL: a line-anchored `*.nix:NN` row regex finds 0 rows in comments[0], 0 in comments[1],
   and 5 in comments[2] — all five prose from OTHER sections (Q3 liveness, Q2, the completeness section, the
   graph section). NONE is a Q1 row. A guard-number grep over the whole bead returns exactly four:
   #7, #12, #13, #14. The numbers #1/#2/#3/#10/#11 existed ONLY in an orchestrator dispatch prompt.
⇒ The analyst's table exists in no record that can be reached. The scratchpad copy (q1-q5.txt) is the same
text as comments[2], deferral included.

════ THE ANSWER THAT MATTERED: NO GUARD IS IN ONE ENUMERATION AND ABSENT FROM THE OTHER ════
Checked in BOTH directions with a positive control, not by inspection:
 · A guard the analyst found and the author did not — would have to lie outside the swept surface. Ripgrep
   over den-hoag/lib and ALL 23 gen-*/lib (`indexOf strata`, `strataLt`, `strataLe`, `ceilingGate`,
   `edgesBelowStratum`, `stratumIndex.`, `posOf strata`, `pb > pa`): nothing outside den-hoag/lib and
   gen-resolve/lib. gen-resolve contributes exactly one (schedule.nix:87); gen-rebuild's one hit is a comment
   (restabilize.nix:47); the other 21 libs contribute nothing. POSITIVE CONTROL: the sweep recovers all 15
   rows, so the predicate is not blind to what it claims absence of.
 · A guard the author found and the analyst did not — would show as a leftover after class mapping. NO
   LEFTOVER: all 14 map, and the single extra is `strataLt`, which the analyst's class scheme excludes by
   construction.
⇒ SAME MEMBERS, SAME FILES, SAME LINES, SAME OPERATORS. 14 vs 15 is a counting convention about whether the
bare `<` predicate at stratum-scope.nix:21-23 is a guard: it is the predicate rows 10-13 CALL and it guards
nothing alone. The author enumerated comparison SITES; the analyst enumerated GUARDS. The R2 spec's §2 open
item is CLOSED — conventional, not substantive.

BLAST RADIUS: unaffected. `strataLt` is live only in the sense that its four callers run; it is not an
independent guard and the R2 design does not change it (§6 keeps it as ABW condition 2, the `negates`
guard's predicate). §9.4's stated limit stands unchanged — node.rel, node.query, `over`, the claim accessor
and the re-enabled ceiling each still need their own baseline-vs-changed check with a consumption control.

CAVEAT, carried verbatim because it is the honest limit and the reason the rest is credible: this is a
RECONSTRUCTION from the class characterization, not a row-by-row comparison against the analyst's actual
table, which does not exist in any reachable record. It closes exactly with no free parameters. IF THAT
TRANSCRIPT EVER SURFACES AND ITS 14 DIFFER FROM THE RESTORED 14, THAT IS A REAL FINDING AND THIS RECORD IS
WRONG.

INSTRUMENT NOTE FOR ANY FUTURE READER OF THIS TRACKER: `bd show --json` DOES NOT INCLUDE COMMENTS. To read a
comment programmatically, go to .beads/beads.jsonl. A tool that silently omits the field you are querying is
the same failure class as a grep that cannot match — and it would have made "the table is not on the bead"
unfalsifiable from the JSON alone.


### 9 — 2026-07-28T03:53:48 · Jason Bowman

★★★ GATE REVIEW — R2 stratum-guard design. VERDICT: REDESIGN.
Freeze HELD (md5 d0d79b7b…, 829 lines, unchanged). The a40cc96 citation drift was supplied as an erratum and
correctly judged immaterial to the design.

THE SPINE IS VALIDATED AND MUST BE PRESERVED: runtime read guards take ABW condition 1; condition 2 stays at
the `negates` declaration; well-foundedness guards untouched. Every check the reviewer ran supports it.
THE DELIVERABLE IS NOT ADMISSIBLE: two factual claims refuted by measurement, an executable delta missing two
consumers it elsewhere names, a mandatory mitigation absent from the artefact, and one re-sourcing extended
past its theorem's domain.

════ REPRODUCED INDEPENDENTLY, CONTROLS FIRED ════
· EXECUTABLE CORE EXACT — reviewer's own delimiter extraction byte-identical to the author's; 104 delimited,
  73 comment-stripped, sha256 c86793d5ce4884d8aa74c09597a0be0f7d37714a3fa516b711b4aecb563c288a.
· ★ THE CONTROL DISCRIMINATES, AND THE REVIEWER ADDED ONE THE AUTHOR DID NOT RUN — a third `admitAll` gate
  beside positiveGate/negativeGate and the shipped ceilingGate, on one record:
      kind              shipped  positive  negative  admitAll
      strictly-below    admit    admit     admit     admit
      SAME-stratum      reject   ADMIT     reject    admit
      strictly-above    reject   reject    reject    ADMIT
  discriminates-vs-negative AND discriminates-vs-admitAll both true ⇒ a gate admitting everything could not
  pass unnoticed. Instrument proof in the same run: instrument-deepSeq-forces=true,
  instrument-spineOnly-blind=true (a throw nested two levels deep; `length` sees nothing, deepSeq sees it).
· TOTALITY DEFECT CONFIRMED with a SHARPER TRIGGER: populated key map + order omitting the rule's stratum →
  aborts `attribute 'structural' missing` at concern-policies.nix:122:15, tryEval blind. Positive control
  (full order, same map) → tryEval returns false, so the instrument CAN report catchably on this path.
  ★ EMPTY key map + same missing-stratum order → SURVIVES, because `ks != null` short-circuits before `r` is
  forced. The core converts it to a catchable named throw.
· RE-ENABLEMENT REPRODUCED PLUS A CONTROL THE AUTHOR SKIPPED: the author measured identity only under the
  SHIPPED filter, but the design changes the filter in the same landing — re-run under core.positiveEdges,
  ALSO identical. accNonVacuous, accEmptiedAtOwn, accDiffersFromEmptied all fire, so it is not equality of
  two empties. The in-code disablement reason at resolution-relations.nix:44-48 IS stale.
· C5 ABW COORDINATES — NO DEFECT. DEFINITION 3 under `## Page 8`, running head "96 Apt, Blair, and Walker";
  prose gloss verbatim at file line 477 exactly where cited; Lemma 1 at 527-528/536. The chapter has no
  numbered sections and THE SPEC CITES NONE — named definition + printed page throughout. It correctly flags
  the p.98 ≤→< trap, declines to rely on it, and attributes pp.102-110 to the bead rather than to itself.
· DP1 correct at source (schedule.nix:87 `pb != null && pb > pa`; its own comment states ABW's asymmetry
  correctly). Inertness exact, with a worktree-exclusion positive control (40 matches excluded — filter did
  real work). 3-of-11 RED confirmed with an all-11-green baseline in the same run.

════ DEFECTS ════
★ D1 BLAST RADIUS UNDERSTATED 3.3×, AND USED AS AFFIRMATIVE EVIDENCE. §9.3 says "exactly the three
assertions that encode the defect, and nothing else … that is itself evidence for the design". Reviewer built
a patched lib/ (5 operator edits), verified reference byte-equal and patched divergent, ran 15 suites on both:
210 assertions, baseline all-PASS, TEN DIVERGENT across FOUR suites —
  stratum-scope 3 · derived 3 (gate-same-stratum-throws, msg-not-later, query-capability-bound-empty) ·
  claim-negation 2 · claim-provider 2 · eight other suites 0.
LOWER BOUND: 3 of 15 suites need constructor args the runner does not supply and DID NOT EVALUATE.
★★ THE DECISIVE DETAIL, and it is the answer to the question this gate was told to press hardest on:
edge-substrate.nix — the suite covering projectCtx, THE ONLY GUARD CARRYING A BYTE-IDENTITY MEASUREMENT —
had 82 assertions and ZERO divergent, while ALL SEVEN unanticipated REDs are on the LIVE guards. The
measurement taken on the inert guard covered nothing that actually moves. §9.4's stated limit was correct and
the document's confidence elsewhere exceeded it.
(negation-gate.nix at 0 divergent DOES confirm §6's claim that `negates` stays strict.)

★ D2 §4.5's LIVENESS CLAIM IS FALSE. "…reachable only by an `emit = "edges"` production declaring a claim at
`resolution` itself, WHICH NOTHING DOES." Two CI fixtures do exactly that through the PUBLIC surface —
ci/tests/claim-negation.nix:74-76 and ci/tests/claim-provider.nix:75-77. The supporting probe surveyed only
the four SHIPPED claim strata and never looked at the repository's own fixtures. Four assertions in two
suites pin the opposite of what §4.5 predicts.

D3 §9.2's TEST PLAN IS WRONG IN KIND for the claim arm — it asks to ADD a fixture on the premise the case is
unreachable; four existing assertions already pin the opposite and must be INVERTED. Under the three-state
ruling those are different landings.

★ D4 THE EXECUTABLE DELIVERABLE IS INCOMPLETE — TWO ORPHANED CONSUMERS. §8 names five kernel consumers of the
renamed `edgesBelowStratum` including concern-relations.nix:158 and :204; the §5 call-site delta table — the
artefact the spec DESIGNATES as reviewable — has six rows and contains NEITHER. After the rename the
primitive does not exist. Live, not pedantic: §4.4 arms mkRelAccessor's ceiling in the same landing, so which
predicate its internal filter takes is an unspecified semantic choice ON A NEWLY-ARMED GUARD.

★ D5 C7-b — THE MANDATORY MITIGATION IS ABSENT FROM THE DELIVERABLE. §8 prices the re-enablement honestly and
concludes "Re-enabling the ceiling without the hoist should not be accepted." The §5 delta row for
resolution-relations.nix:48 IS re-enabling the ceiling without the hoist. An implementer following the
executable artefact lands the O(N·|relationEdges|) regression the spec forbids. THE DESIGN STATES ITS PRICE
AND THEN SHIPS THE UNPRICED VERSION.

D6 C2/C2-a — THE L2 RE-SOURCING DOES NOT COVER L2's DOMAIN. The L5 half holds at source (production-guard.nix
:1-10 cites Fagin-Kolaitis-Miller-Popa 2005 weak acyclicity and Vogt 1989; clause 2 is well-foundedness). But
L2 at concern-productions.nix:102 is computed and checked UNCONDITIONALLY OF `emit` — belowOffenders runs for
every production, tested at :122 before any emit discrimination. claim-provider.nix:93-101 is an `emit="attr"`
provider with `from = [{kind="reverse-query"; stratum="route";}]`, L2-gated, WITH NO VALUE INVENTION ANYWHERE.
Structurally `from` is a production's declared POSITIVE SOURCE SET — the same role `over` plays for a derive,
which §4.3 RELAXES on the reasoning that "gating a declared positive set by the negative rule is the same
defect at definition time". THE SPEC ISSUES OPPOSITE VERDICTS ON THE SAME SHAPE AND DOES NOT NOTICE.

D7 §3.1's BOUNDEDNESS MISCLASSIFIES ITS SIBLING. It argues the same-stratum undeclared negation is bounded
because the strictly-below one already escapes. But STRICTLY-BELOW IS ABW-SOUND (condition 2 satisfied there,
escaping costs nothing); SAME-STRATUM IS THE UNSOUND ONE. Correct accounting: runtime coverage of UNSOUND
undeclared negation goes from {s=i, s>i} to {s>i} — A HALVING, not a sibling relation, and s=i is the case
most likely to arise by accident.
★★ THE ARGUMENT THAT WOULD RESCUE IT IS AVAILABLE AND THE SPEC NEVER MAKES IT: EVERY PREDICATE IN THE
FILTERED POOL IS EXTENSIONAL. concern-relations.nix:18 declares a relation EDB; appended claim edges are EDB
BY AN ENFORCED LAW (concern-productions.nix:66-72 — from=∅, readsAttrs=[], compute may not read `self`,
NAMED-rejected otherwise); default.nix:2127 is forward ∪ inverse ∪ claim, all three EDB. ABW condition 2
exists because an IDB predicate at stratum i has NOT REACHED ITS FIXED POINT; an EDB predicate is complete
before stratum 1. ON THAT BASIS THE RESIDUAL IS NOT MERELY BOUNDED — IT IS EMPTY OVER THE CURRENT POOL.
As written this is an unenumerated hypothesis (C1): EDB/IDB status is a precondition of condition 2's
NECESSITY, and neither the spec nor the guards distinguish it.

D8 §2's STATED METHOD CANNOT HAVE PRODUCED ITS OWN TABLE. §2 states the method as grepping five names across
lib/ and ../gen-resolve/lib/. Run exactly: ZERO hits in gen-resolve — schedule.nix:87 is
`pb != null && pb > pa` and matches none of the five — yet row 15 IS schedule.nix:87. A broadened sweep also
fails its own positive control on that line. THE GUARD SURFACE IS ASSERTED COMPLETE, NOT SHOWN COMPLETE.
Same soft spot as the 14-vs-15 reconciliation; the reviewer could not close it either.

════ ★ THE PREMISE IS STILL UNVERIFIED BY TWO AGENTS ════
Routes 0-3 and the Q4 matrix were not re-run by the R2 author OR by this reviewer. ROUTES 2 AND 3 CARRY REAL
LOAD — they are §1.3's whole basis for "the blanket guard is not load-bearing", WHICH IS THE DESIGN'S
PREMISE. Two agents have now declined to verify the foundation of the argument they were evaluating.
(The store-path measurement carries LESS load than it appeared to: the reviewer measured its subject directly
and found 0 divergences in edge-substrate.nix, and D1 shows it could never have covered the guards that move.
The 14-guard table is unrecoverable and D8 makes its reconciliation moot — neither count is established.)

════ WHAT A REDESIGN MUST FIX — recorded so it cannot be silently re-proposed ════
1. §9.3 restates blast radius as MEASURED across the suite corpus (≥10 assertions, 4 suites) and STOPS USING
   THE UNDERSTATED FIGURE AS EVIDENCE.
2. §4.5 retracts "which nothing does" and re-derives claim-accessor liveness from the repository's own
   fixtures; §9.2's claim arm becomes "INVERT four existing assertions", not "add a fixture".
3. The §5 delta table covers concern-relations.nix:158 and :204 with a stated admittance predicate for each,
   AND carries the hoist §8 declares mandatory.
4. L2 is re-sourced for its ACTUAL domain (it fires for emit="attr" too) OR given the same verdict as `over`
   — one or the other, with the reason.
5. §3.1's boundedness is re-argued on the EDB/IDB axis, which is the axis that actually decides it.
6. §2 states the method that genuinely produced its table, or DROPS THE TOTALITY CLAIM.
7. (orchestrator) ROUTES 2 AND 3 GET VERIFIED. The design's premise cannot rest on a measurement no reviewer
   has reproduced.

════ REVIEWER COVERAGE — HONEST ════
READ IN FULL: the spec (829); lib/stratum-scope.nix; ci/tests/stratum-scope.nix; resolution-relations.nix;
the ABW archivist note and printed pp.96-98 of the archived markdown; bead head and tail (NOT the whole body).
GREPPED/PARTIAL: concern-derived, concern-policies, concern-relations, concern-productions, production-guard,
claim-accessor, default.nix, gen-resolve/schedule.nix, ci/tests/{derived,claim-negation,claim-provider,
edge-substrate}.
COULD NOT EVALUATE: 3 of 15 suites (arg shape); no full CI run; no corpus scan; no nixpkgs-level build; DID
NOT RENDER THE ABW PDF RASTER — the C5 check is against the archived markdown plus its ARCHIVIST NOTE, not
the 200 dpi renders.
Probes read-only in scratchpad/rev/: rv-core.nix, rv-totality.nix, rv-ceiling.nix, rv-suite.nix,
runsuite.nix, and the patched/reference trees dh-chg/ and dh-ref/. Repository not modified.


### 10 — 2026-07-28T03:57:18 · Jason Bowman

GATE FOLLOW-UP — errata accepted, verdict UNCHANGED (REDESIGN). One finding DOWNGRADED, one SHARPENED, and
two orchestrator claims CORRECTED. Repair list is now 5 blocking + 1 documentation.

★ THE DRIFT IS CITATION-ONLY, ESTABLISHED FROM THE INSTRUMENT RATHER THAN FROM THE AUTHOR'S WORD.
Every measurement in the review binds to MECHANISM, not position: the patched tree was built by EXACT-
EXPRESSION string replacement with an asserted occurrence count per edit (zero line numbers anywhere in the
patch, so a line shift cannot move it); the probes resolve `denHoag.internal.strataScope` /
`internal.compilePoliciesWithStrata` off the seam; the executable core cites no line and its hash is
unchanged; the per-guard verdicts key on which primitive / which surface / loud-vs-silent. ⇒ errata, not
findings. This is the right way to answer "is the drift cosmetic" — not by assertion but by showing the
instrument never read a line number.

★ ORCHESTRATOR CORRECTION 1 — MY ERRATUM (b) WAS BACKWARDS. At the anchor 6fc4ada, `:132` IS
`strataScope.ceilingGate` and `:131` is `gatedRel =`. So §5's delta row (":132 | strataScope.ceilingGate")
was CORRECT at the anchor and §2's row labelling :132 "(gatedRel)" was the one off by one. a40cc96 SWAPPED
which is accurate. I recorded and dispatched the reverse.

★ ORCHESTRATOR CORRECTION 2 — THE grep-WRAPPER TOOLING FAULT DID NOT REPRODUCE. I recorded a report that
`grep -rnE` returned 0 hits in lib/stratum-scope.nix where a direct grep returned 28, propagated it to three
agents, and wrote it into the bead as a live session-wide instrument fault. The gate could not reproduce it:
`grep -rnE`, direct per-file `grep -nE` and `rg -n` all agree on its tooling (`strataLt` → 3, `strata` → 13),
and it checked the likelier explanation for the original zero (a RELATIVE `../gen-resolve/lib/` path with cwd
resetting between calls) and found the path did resolve. ⇒ I OVER-GENERALISED ONE AGENT'S REPORT INTO A
SESSION-WIDE FAULT. Cross-checking absences with a second instrument remains right on its own merits — it is
how D8 was closed — but prior absence claims in this arc are NOT suspect on that basis.

════ D8 DOWNGRADED: BLOCKING → DOCUMENTATION, and the completeness risk is CLOSED BY MEASUREMENT ════
The gate swept ALL `gen-*/lib` for ordering guards in NON-den-hoag SPELLINGS, with a positive control that
FIRED — it recovered gen-resolve/lib/schedule.nix:87 via `posOf`/`pos`, THE EXACT ROW THE FIVE-NAME PREDICATE
STRUCTURALLY CANNOT SEE. Only other ordering machinery anywhere: gen-graph/lib/query.nix:158-160
(`rankOf`/`rankWordOf`, over edge LABELS) and gen-product/lib/chain.nix:112-147 (`rankOf`/
`firstRankCollision`, over product DIMENSIONS). NEITHER COMPARES STRATA.
⇒ NO STRATUM GUARD EXISTS OUTSIDE den-hoag/lib AND gen-resolve/lib. THE 14+1 TABLE IS COMPLETE.
The gate also reproduced the 14 INDEPENDENTLY, landing on the same five buckets with no free parameters, and
correctly excluded three near-misses as non-guards: claim-accessor:40 (a ceiling DEFINITION),
concern-derived:131 (an index COMPUTATION), concern-policies:122 (the totality defect — not an ordering
guard). It notes concern-derived:133 where the restored table says :132 — the a40cc96 shift.
WHAT REMAINS is only that §2's STATED METHOD provably cannot produce row 15 (the five names give ZERO hits in
gen-resolve/lib, positive control `strataOrder` → 3 files, so the tree is reachable and the search is not
vacuous). ⇒ §2 must state the method that actually produced the table. Totality is now positive-controlled
and must NOT be dropped.

════ D4 SHARPENED — A MISSING AXIS, NOT A MISSING ROW ════
The restored 14-guard table puts concern-relations.nix:158 and :204 in the "relation EDGES (SILENT), 5"
bucket. So TWO OF THE FIVE SILENT-EDGE GUARDS ARE CONSUMERS OF THE PRIMITIVE §8 SAYS GETS RENAMED AND
RE-SHAPED — and §2 gives those rows verdicts on the CEILING axis (#12 not-re-enabled, #13 re-enable) and NO
VERDICT AT ALL on the ADMITTANCE-PREDICATE axis. TWO INDEPENDENT DECISIONS PER ROW, ONE ANSWERED.
⇒ The repair is not "add two rows to §5"; it is "§2's verdict schema needs a second axis, both rows need a
verdict on it, and §5 follows".

════ ★ PATCH FIDELITY — unprompted, and it protects D1 from the obvious rebuttal ════
The D1 measurement patched the PRIMITIVES; §5's delta table patches CALL SITES. A superset on paper — the
gate verified the superset is BEHAVIOURALLY EMPTY: the only two call sites are default.nix:2154 (omits
`ceiling`, takes the `? null` default at concern-relations.nix:151) and resolution-relations.nix:48
(`ceiling = null`), and BOTH SHORT-CIRCUIT at concern-relations.nix:155/:201 before the primitive is reached.
⇒ 10 RED IS A FAITHFUL MEASUREMENT OF THE DESIGN'S OPERATOR CHANGES.
AND THE DIRECTION IS SAFE: the measurement EXCLUDES §4.4's ceiling re-enablement, deliberately not applied.
Arming that ceiling can only ADD to the 10, never subtract. So ≥10 is a lower bound in TWO independent
senses — the three unevaluated suites AND the unapplied re-enablement.

════ REVISED REPAIR LIST ════
BLOCKING (5, all measured, none an erratum):
 1. §9.3 blast radius: ≥10 assertions across 4 suites, stated as a lower bound in both senses; STOP using the
    understated figure as affirmative evidence.
 2. §4.5 retracts "which nothing does" (ci/tests/claim-negation.nix:74-76 and claim-provider.nix:75-77 both
    declare stratum="resolution", emit="edges" through the PUBLIC den.productions surface); §9.2's claim arm
    becomes INVERT FOUR EXISTING ASSERTIONS, not add a fixture.
    ★ THE GATE'S ANSWER TO THE QUESTION IT WAS TOLD TO PRESS HARDEST ON: the only claim resting on evidence
    that could not cover it is about the LIVE CLAIM ACCESSOR — not the inert projectCtx.
 3. §5 delta table covers concern-relations.nix:158 and :204 with a stated admittance predicate each (see D4
    above — §2 needs the second axis first), AND carries the hoist §8 declares mandatory.
 4. L2 re-sourced for its ACTUAL domain (it fires for emit="attr" too — ci/tests/claim-provider.nix:93-101)
    or given the same verdict as `over`.
 5. §3.1 boundedness re-argued on the EDB/IDB axis.
DOCUMENTATION (1, downgraded): §2 states the method that actually produced its table.
ORCHESTRATOR ITEM, still open: routes 0-3 remain unreproduced by author OR gate. They are §1.3's whole basis
for "the blanket guard is not load-bearing" — the design's premise. The redesign re-runs them FIRST.


### 11 — 2026-07-28T04:18:54 · Jason Bowman

★★★ R2 REDESIGN COMPLETE — 1231 lines · md5 e4727faa97bfc90660a79ffbb9eccb39 · core delimited :502-616.
den-hoag untouched (status clean, HEAD a40cc96). Spine preserved. Returning to the gate.

★ R9 — THE PREMISE HOLDS, AND IT IS NOW THE AUTHOR'S OWN CLAIM. It re-ran scratchpad/q7-escape-routes.nix
itself against a40cc96 (`nix-instantiate --eval --strict --json`):
  route0 control loud OOS read : THROWN        ← control fires
  route1 tryEval around gate   : ESCAPED false
  route2 silent query OOS      : ESCAPED true
  route3 undeclared neg in-scope: ESCAPED true
Routes 2 and 3 reproduce. §1.3's "I did not re-run routes 0-3" line is GONE — the design's foundation is no
longer an attribution neither author nor gate had verified.

★★ NEW CORE HASH 7dfa54de1b427977b6ffeef4c465aba5daae41a51414aa04c2ddb26c95a16cb8 (was c86793d5…288a).
115 delimited / 77 stripped (was 104/73). ★ THE METHOD WAS REPRODUCED FROM THE ORIGINAL FIRST — the recipe
regenerates c86793d5…288a from the old core exactly, SO THE TWO HASHES ARE COMPARABLE. That is the right way
to change a hashed artefact.
WHAT CHANGED: EXACTLY FOUR STRIPPED LINES, verified by diffing the two stripped artefacts — the three-line
`strataLe` binding plus its export. Nothing else moved. ★ AND THE REASON IS D4's DISEASE INSIDE THE BLOCK
ITSELF: delta row 3 named `strataLe` while §5 said it "is one line and is not restated in the block" — AN
ARTEFACT REFERRING TO A BINDING IT DOES NOT SUPPLY. So the ~400 added lines are prose; the executable core
grew by exactly what was missing from it.
Core re-run against the real primitives with THREE controls: negativeGate opposite on same-stratum; shipped
`strataLt` beside `strataLe` differing on the equal case; instrument proof (throw two levels deep — deepSeq
sees it, `length` does not).

════ THE EIGHT REPAIRS ════
R1 ★ IT DID NOT TAKE THE GATE'S FIGURES — IT REBUILT AND WIDENED THE MEASUREMENT. dh-ref verified byte-equal
to a40cc96 (`diff -rq`, no output); dh-chg differs in 4 files / 5 operator edits. New harness FLATTENS EVERY
TEST GROUP, not just the first: 144 suites · 42 evaluable · 102 not · 503 assertions · baseline 0 non-PASS ·
TEN divergent across FOUR suites. Same ten, same four. LOWER BOUND IS NOW 102/144, not 3/15, with non-eval
reasons SAMPLED AND STATED (boundary needs genPrelude; compat-surface/projection need denCompat;
stratification needs a store-path flake.lock). §9.3 rewritten as measurement, the "evidence for the design"
inference EXPLICITLY WITHDRAWN, and the decisive point is the pull-quote: edge-substrate 82 assertions / 0
divergent is the projectCtx suite — the only guard with byte-identity — while all seven unanticipated REDs
are on LIVE guards.
R2 ★ RETRACTED, both sites read: claim-negation.nix:74-86 and claim-provider.nix:75-87, both
`stratum="resolution"`, `from=[ ]`, `emit="edges"`, PUBLIC surface. Accessor ceiling is `resolution`
(claim-accessor.nix:39-40) so both are `ks == r` EXACTLY. §4.5 names the failed probe's blind spot (it
surveyed only the four shipped strata) and re-derives liveness from the fixtures.
R3 §9.2's claim arm is now "INVERT four existing assertions", tabulated pins-today → must-become. ★ PLUS AN
OBLIGATION NOBODY ASKED FOR: both suites carry the L4 throwing-gate witness, so `oosclaim` needs a sibling
genuinely above `resolution` or THE INVERSION DELETES THE L4 DEMONSTRATION rather than moving it.
R4 ★ Delta table rebuilt, 10 rows, each with an admittance predicate AND its reason. concern-relations.nix
:204 (row 6) and :158 (row 7) both present, both `admitPositive` — :204 because row 8 arms its filter in the
same landing and AN ACCESSOR CANNOT SEE THE POLARITY OF THE READ IT SERVES; :158 because it is unreachable
today (default.nix:2154 omits `ceiling`, `ceiling ? null` at :151 short-circuits) and taking the same
predicate makes future arming A PARAMETER CHANGE, NOT A DEFERRED DECISION.
R5 ★ Hoist is row 9, PAIRED to row 8 — "land together or neither lands" — and written concretely:
resolution-relations.nix:17-29 is a function returning an attrset with no `let`, so the hoist introduces one
(`relAccessorFn = relations.mkRelAccessor { … };` outside, `compute = _self: id: relAccessorFn id;` inside).
§8 amended to say it previously stated the price and shipped the unpriced version.
R6 ★★ VERDICT UNCHANGED, RE-SOURCED — AND FOR A REASON NOBODY PREDICTED. L2's DOMAIN IS NOT UNIFORM:
concern-productions.nix:215 vs :242-247 SPLIT `emit="edges"` ON `from`. With `from ≠ ∅` it lowers to a
`resolve.nta` SPAWN — real value invention — and L5 IS INERT THERE (production-guard.nix:49-50 returns null
for every emit ≠ "nodes"). ⇒ L2 IS THE ONLY WELL-FOUNDEDNESS GUARD FOR THAT BRANCH, and relaxing it would
SILENTLY UN-GUARD A SPAWN. That is the disanalogy with `over`: strictly-below is LOAD-BEARING for part of
L2's domain, which was never true of the runtime read guards. Residue NAMED not smuggled: for `emit="attr"`
it is (C) capability, `from` is never executed (REFERENCE.md:101 verbatim, echoed claim-provider.nix:91), and
it is EVADABLE by `from = [ ]` — which the repo itself does at claim-provider.nix:112-121. §4.3 carries a
forward pointer so the two verdicts are visibly reconciled rather than accidentally opposite.
R7 ★★ RE-ARGUED ON THE EDB/IDB AXIS, all three sites verified PLUS A FOURTH THE GATE DID NOT NAME.
concern-relations.nix:18-19; default.nix:2043-2066 forward from `ent.registries` `.edges` only, :2076-2100
inverse = transpose of forward; claim EDB by enforced law — AND IT BUILT A PROBE FOR THE LAW RATHER THAN
CITING THE COMMENT (scratchpad/r2b-edb-law.nix: a leaf claim whose compute reads `self.get` is THROWN;
control — same leaf, no read — COMPILED and landed its fact). ★ FOURTH LEG, ITS OWN: the one INVENTING
branch contributes nothing to the pool — concern-productions.nix:248 returns `claimEdges = [ ]`, so the NTA
spawn is an EQUATION, never a pool member. ⇒ POOL HAS NO IDB LEG ⇒ RESIDUAL EMPTY, NOT BOUNDED.
§3.2 carries the corrected accounting (s<i sound; s=i and s>i unsound; coverage halving) and states H-EDB as
enumerated hypothesis C1 WITH ITS FALSIFIER — routing NTA output into default.nix:2127 — and what happens
then (§10's binding declarations, NOT restoring the blanket operator). §9.2 asks for the test that pins it.
R8 WITHDRAWN AND REPLACED. Ran the stated five-name method exactly: 42 hits in lib/, ZERO in gen-resolve —
confirmed. §2.1 now states the method that GENUINELY produces the table: two sweeps, (A) per-file
comparison-operator-plus-stratum-token, name-independent → 5 in lib/ + 1 in gen-resolve (schedule.nix:87,
WHICH IS THE SWEEP'S OWN POSITIVE CONTROL since it uses none of the five names); (B) per-file primitive-name
call sites → 4+1+4. 6+4+1+4 = 15. PLANTED-SITE POSITIVE CONTROL ON BOTH SWEEPS (scratchpad/sweepctl/).
★ TOTALITY CLAIM DROPPED — replaced with a stated blind spot per sweep and "reproducible, not total". 14-vs-15
DECLARED UNRECOVERABLE rather than reconciled.

════ CITATION WORK ════
Header re-pinned to a40cc96, shift DERIVED from `git show 6fc4ada:` vs HEAD rather than assumed. All five
:146→:147; :132→:132-133 at SIX sites (including §4.2's heading and one the orchestrator did not list,
§4.3's "relaxing :132"). §11's R1-residual bullet DELETED, verified discharged.
★ FOUR FURTHER CITATION ERRORS FOUND AND FIXED, ALL ITS OWN TO REPORT: default.nix:1841→:1840
(`claimKinds = productionClaimKinds`; :1841 is `strataOrder`); :1332-1335→:1331-1335 (`edgesLib.compile`);
per-production-strata.nix:62→:62-67; and §4.1's ctxKeyStrata inventory was WRONG ("three test lines / four
consumer lines") — re-counted with ripgrep, NINE source sites, enumerated.

════ TOOLING — A DIFFERENT FAULT THAN THE ONE I WARNED ABOUT ════
`rg -nE` FAILS with "unknown encoding: -e" — ripgrep's `-E` is `--encoding`, not extended-regex. A FLAG
COLLISION, not a traversal fault. Every absence claim in the repair is per-file `grep` looped over `find`,
cross-checked with `rg` where the flag allowed. This is worth noting against the earlier "wrapper returns a
false zero" report, which did not reproduce on a second agent's tooling: A FLAG COLLISION PRODUCES EXACTLY
THE SAME SYMPTOM AS A BROKEN TRAVERSAL and is far more likely.

════ STILL OPEN, stated in §11 ════
No corpus eval. No full `just ci`. ★ THE MEASURED TREE COVERS THE FIVE OPERATOR EDITS ONLY — §4.4's
re-enablement, THE HOIST, THE RENAME and the projectCtx totality fix HAVE NO SUITE MEASUREMENT AT ALL.
claimKinds stratum validation still unverified. ABW pp.102-110 still not the author's own reading. Route 4
propagation still on den-hoag-4kh.13. q6-declared-vs-actual not re-run (§10 depends on it; §4/§5 do not).
New probes for the gate: r2b-edb-law.nix, core2r-check.nix, core2r.nix, core2r-stripped.nix, sweepctl/,
rev/mine/{runsuite2.nix, suites.txt, dh-ref/, dh-chg/}.


### 12 — 2026-07-28T04:21:44 · Jason Bowman

★★★ CROSS-DESIGN COUPLING — den-hoag-4kh.11 AND den-hoag-4kh.13 SHARE A LOAD-BEARING PREMISE WITH OPPOSITE
SIGNS. Found by the 4kh.13 gate. BOTH SPECS MISSED IT AND SO DID THE ORCHESTRATOR. Recorded on both beads.

FILE SETS ARE GENUINELY DISJOINT — verified: `lib/attributes/structural.nix` and `lib/errors.nix` occur ZERO
times in the 4kh.11 spec. That half of 4kh.13 §11's claim holds.

★ "NEITHER CONCLUSION DEPENDS ON THE OTHER" IS REFUTED.
4kh.11 CHANGES `projectCtx` (its §4.1; lib/concern-policies.nix:122,129; its change table marks it CHANGE).
Its proposed code comment, verbatim:
    "(2) condition 1. `mapAttrs` replaces VALUES and preserves KEYS, so THE ONE NEGATION-SHAPED READ
     AVAILABLE HERE (`ctx ? key`) IS INVARIANT UNDER THE PROJECTION — measured. This guard therefore only
     ever sees positive reads…"
⇒ 4kh.11 RELIES ON `ctx ? key` STAYING OBSERVABLE. It is the justification for scoping its guard to positive
reads only.
⇒ 4kh.13's DEFECT EXISTS BECAUSE `ctx ? key` IS OBSERVABLE. A construction-level remedy — denying the
observation — would REMOVE 4kh.11's stated justification for its own guard's scope.
ONE PREMISE, TWO CONCLUSIONS, OPPOSITE SIGNS. And 4kh.11 is changing the very mechanism (`projectCtx`)
through which a construction-level remedy for 4kh.13 would be expressed.

CONSEQUENCES, both directions:
· 4kh.13 §11 must RETRACT "neither conclusion depends on the other" and replace it with the true statement.
· 4kh.11 must know that if 4kh.13 takes the construction route, its §4.1 justification changes underneath it.
  Its VERDICT may survive — a guard that only sees positive reads is still correct if negation becomes
  unrepresentable — but the REASON would no longer be "ctx ? key is invariant under the projection"; it
  would be "there is no negation-shaped read left to be invariant about".
· NEITHER SPEC MAY LAND WITHOUT THE OTHER'S POSITION ON THIS BEING STATED. Two designs landing in the same
  kernel on opposite sides of one premise is exactly the silent interaction the gate exists to catch.

★ THE CONSTRUCTION THE 4kh.13 GATE NAMED, recorded here so it is not re-derived:
"Policies restricted to CLOSED PATTERN LAMBDAS — no `...`, no defaulted formals. `functionArgs` is then the
WHOLE condition; every formal is guaranteed present by the firing predicate (gen-derive/lib/core/rule.nix
:40-48); the body has no `ctx` VALUE to interrogate. `ctx ? k`, `{g ? d, ...}` and `ctx.k or d` all become
UNREPRESENTABLE."
Under it T_P is MONOTONE on the keyset lattice, the least fixpoint exists, the inflationary loop reaches it,
and `published == converged` BECOMES A THEOREM RATHER THAN A CHECK — which is C7's standard. It eliminates
all three measured defect classes: every ★ row of 4kh.13 §7 requires a banned shape.
ABW FLAG THE AXIS ON THE PAGE THE SPEC CITES — printed p.100, verbatim: "we are brought to study the fixed
points of NONMONOTONIC operators." An all-positive surface is the monotone case, where none of this
apparatus is needed.
ITS COST: a BREAKING policy-surface change the corpus uses (~13 sites, bead 4kh.13 Q4). THAT IS A LEGITIMATE
REASON TO REJECT IT — but under the standing bar "the corpus does it" is NOT a theory argument. The argument
must be MADE, not skipped, and the rejection recorded with its reason or it gets re-proposed.

★ AND THE PRECEDENT THE SPEC FAILED TO DISTINGUISH IS AN ORCHESTRATOR COMMIT FROM THIS SESSION.
lib/concern-derived.nix:126 at a40cc96 ("docs(strata): the fifth site of the introspection overstatement"),
verbatim: "The gate withholds the VALUE, not the OBSERVATION: a derive body can wrap the read in
`builtins.tryEval` and recover a boolean … (the SOUND direction for L4)." That commit WALKED BACK 6fc4ada's
"enforcement-by-construction, never introspection". ⇒ THE PROJECT HAS RULED VALUE-WITHHOLDING SOUND FOR L4.
A design proposing to deny observation in the ctx domain must cite that ruling and distinguish its domain, or
it is silently contradicting a position the tree took four commits ago.


### 13 — 2026-07-28T04:50:55 · Jason Bowman

★★★ GATE RE-REVIEW — R2 stratum-guard design. VERDICT: VALIDATED.
Anchor held: md5 b01e55aac3b024fd93f50c5cedf97546, 1352 lines, core :573-687, 115/77, sha256 7dfa54de… —
verified before reading.

════ ★ RETRACTION — THE REVIEWER'S OWN HEADLINE FINDING WAS WRONG, AND THE ORCHESTRATOR HAD RECORDED IT ════
The interim report called §9.3's "unbounded exclusion" classification a REDESIGN-level defect, on the ground
that `ruleStratum` is always drawn from the compiled strata so concern-policies.nix:122 could never miss.
THE CONSTRUCTION BARRIER DOES NOT HOLD. `internal.compilePoliciesWithStrata` takes `{ order; ctxKeyStrata }`
AS AN ARGUMENT, so a caller can supply an order that OMITS the rule's own stratum. Reproduced:
    order omits `structural` + key map POPULATED  → EVALUATION TERMINATED at :122, uncaught by tryEval
    same order, key map EMPTY (the laziness barrier) → SUCCESS, `r` never forced
    full order, populated map (the designed tripwire) → CAUGHT, catchable
The seam is real (lib/default.nix:2766) and ci/tests/edge-substrate.nix:16 binds it. ⇒ THE TOTALITY FIX
CLOSES A GENUINE HOLE, the path is REACHABLE, and "a suite that today dies on that path would begin
reporting instead" is properly CONDITIONAL phrasing, not an unearned assertion. The laziness barrier is real
but is exactly the barrier the author's own fixture defeats by populating the key map — deliberately.
WHAT SURVIVES IS A WORDING NOTE ONLY: §9.3 says "uncatchable abort" where §7 correctly names
`attribute 'structural' missing`. Consistent internal usage; NOT a defect.
★ THE ORCHESTRATOR RECORDED THE INTERIM FINDING AS REDESIGN-LEVEL AND PROPAGATED ITS FRAMING. That record is
hereby corrected. The lesson is the reviewer's own: it reported an absence claim resting on a barrier it had
reasoned to rather than measured, and the measurement was two arms away.

════ VERIFIED BY RE-RUNNING — every figure ════
· R1 BLAST RADIUS EXACT, INCLUDING PER-ASSERTION NAMES. All 144 suites on both trees: 144 · 42 evaluable ·
  102 not · 503 assertions · baseline 0 non-PASS · TEN divergent across FOUR. Same ten names
  (stratum-scope 3, derived 3, claim-negation 2, claim-provider 2), ALL PASS→FAIL, NONE the other way.
  dh-ref/lib byte-equal to a40cc96 (`diff -rq` silent); dh-chg differs in exactly four files; the five
  operator edits are exactly the claimed ones.
· CORE HASH + THE FOUR-LINE DIFF: old c86793d5…/73 → new 7dfa54de…/77, differing by PRECISELY the three-line
  `strataLe` binding and its one export. Both hashes reproduce from the stated recipe, so they are comparable.
· THREE CONTROLS DISCRIMINATE: negGate-same-ok=false vs gate-same-ok=true; strataLt-equal=false vs
  strataLe-equal=true (differ exactly on the equal case); instrument-deepSeq-forces=true with
  instrument-spineOnly-blind=true.
· R9 reproduced exactly. R6 all three sites PLUS the reviewer's own extra — L2 is NOT emit-gated
  (`checkOne` reaches `belowOffenders` for every production while `ntaMessage` is null), AND HAD IT BEEN,
  neither guard would cover the spawn and the verdict would INVERT. R7 probe reproduces, fourth leg
  confirmed. R8's REASON verified; the 176 denominator NOT reproduced (its looser predicate gives 277 —
  different filters, neither confirming nor refuting).
· R2/R3/R4/R5 all present, including §9.2's L4-witness obligation and §5's ten rows each with an admittance
  predicate AND a reason. C5 CLEAN — no "perfect model", no "locally stratified", no Przymusinski
  attribution; ABW cited as "Stratified Programs", Definition 3, p. 96 throughout.

════ ★ C8 — STRONGLY SATISFIED, AND SELF-CAUGHT ════
"This is the document's best feature. It does NOT pick the narrower operator to keep suites green — it
relaxes the operator on ABW grounds and PAYS TEN REDs." And it explicitly retracts the previous revision's
use of a small blast radius as affirmative evidence: "the figure is not evidence for the design"; "the ten
divergences are a cost to be paid deliberately, not a small number to be cited approvingly"; §12's "The blast
radius is a cost accepted deliberately; it is not evidence for the design."
⇒ THE C8 ERROR, CAUGHT BY THE AUTHOR AGAINST ITSELF. Nothing defended on parity grounds; L2 stays strict on
theory (the NTA spawn's only guard), not on oracle grounds. §9.4 deflates its own byte-identity result: "A
byte-identical store path taken over an inert guard is evidence about that guard and about nothing else."
MILD EXPOSURE: §4.4 says arming mkRelAccessor "must be gated on a byte-identity check over the corpus" —
correct as a SUFFICIENT check for inertness, but the document does not state the C8 fallback that a differing
gate is a QUESTION, not a verdict. One sentence; not a blocker.

════ DEFECTS — NONE BLOCKING ════
1. ★ THE COUPLING JUSTIFICATION SHIPS AS SOURCE BUT IS NOT HASH-COVERED. Confirmed at :650-652 INSIDE the
   core block — proposed shipped comment for lib/concern-policies.nix — yet a comment, which the strip
   removes, so 7dfa54de… does not cover it. VERIFIED ONLY TO PROSE STANDARD WHILE SHIPPING AS CODE. A gap in
   what VALIDATED attests, not in the design's logic. (Rubric amendment recorded on den-hoag-4kh.6.)
2. "the one negation-shaped read" UNDERSTATES ITS OWN ARGUMENT — several key-set reads (`?`, `hasAttr`,
   `attrNames`, `intersectAttrs`) are invariant for the same reason, since mapAttrs preserves the key set.
   Conclusion sound and STRONGER than claimed; exhaustiveness asserted rather than enumerated.
3. `ctx-unknownRuleStratum-catchable: false` is an INVERTED-SENSE field name — false means it IS catchable.
   Explained at §5.1:782, but a reproduction hazard in an arc bitten by exactly this.
4. core2r.nix reports 114 lines to the document's "115 delimited" — missing trailing newline on the END
   delimiter; content right, stripped hash matches, but a future reproducer sees a disagreement with no
   stated cause.

════ COUPLING (b) AND (c) — ANSWERED ════
(b) COUNTERFACTUAL, since the sibling declined. Had it taken the construction the VERDICT would survive but
    the REASON would be FALSE AS WRITTEN, not merely vacuous: the sentence asserts "the ONE negation-shaped
    read available here" — under closed pattern lambdas there would be ZERO, so the premise fails and a false
    justification would ship in source.
(c) ★ NOT A C1 DEFECT. The spec asserts a property of the PROJECTION, not of the policy surface — "mapAttrs
    preserves the key set" is a theorem about mapAttrs, true regardless of what policies may express, and
    §1.3 labels it "by construction" correctly. The claim is scoped by "available HERE", present-tense. It
    does NOT assert that observability is stable or guaranteed, so it claims no more than the measurement
    supports. The residual imprecision is defect 2 — asserting "the one" without enumerating — which
    UNDERSTATES rather than overstates.
On the feedback/no-feedback framing: §4.1's reasoning is CONSISTENT with it. Its ground for relaxing
projectCtx is that the guard CANNOT OBSERVE A NEGATION AT ALL — the same distinction reached from the other
side. It does not claim the L4 precedent transfers, and §6 keeps `negates` strict because polarity is
declared there.

════ WHAT VALIDATED ATTESTS ════
THE DESIGN, not an implementation: the executable core at :573-687 (7dfa54de…) and the decision it encodes —
runtime read guards take ABW condition 1; condition 2 is enforced where polarity is DECLARED
(concern-derived.nix:64); well-foundedness guards (L2, L5, DP1) untouched, L2 on a re-sourced and now-correct
reason. C1, C1-a, C2, C2-a, C3, C4, C5, C6, C7, C7-a, C7-b and C8 all pass. The pure-graph criterion is
handled by §10, which names the signed-graph target, its prerequisite (binding declarations), and why
attempting it piecemeal is strictly worse than the status quo.
★ C9 IS UNCHECKED BY THIS REVIEWER — it had no access to the register and C9 was not in its dispatch. C9 must
be run against this document before it drives implementation.

════ COVERAGE — HONEST ════
RE-RAN: anchor, core hash + four-line diff, core-vs-primitives with three controls, R9, R6 (+1), R7, R8's
reason, R1 end-to-end, the five operator edits, dh-ref byte-equality, C5, C8, the projectCtx reachability case.
READ NOT RE-MEASURED: §4.4's two ceiling probes, §9.1's fixture matrix, §2.1's sweeps A/B planted controls.
NOT CLOSED: the 176 denominator; §9.4's store-path result (neither author nor reviewer re-ran it); ABW
pp.102-110 (nobody has read the raster; the document says so); C9; and NO CORPUS EVALUATION, which the
document itself lists as a limit in §11.


### 14 — 2026-07-28T04:53:11 · Jason Bowman

★ TWO ADDITIONS AFTER THE VALIDATED VERDICT — one refutes an orchestrator concern, one is the sharpest open
defect in the document.

════ THE §4.1 "MEASURED ON WHAT?" QUESTION — ANSWERED, AND IT GOES THE AUTHOR'S WAY ════
The orchestrator asked: if projectCtx is the IDENTITY MAP on every shipped fleet, is "`ctx ? key` is
INVARIANT under the projection — measured" true but NEARLY VACUOUS? A no-op projection preserves every read.
MEASURED ON AN ACTIVE PROJECTION, WITH A DISCRIMINATING CONTROL IN THE SAME RUN:
    body FORCES `ctx.thing`, ctxKeyStrata.resolution = ["thing"]   (control) → THROWN
        ⇒ the projection really IS replacing the value in that configuration
    body PRESENCE-TESTS `ctx ? thing`, SAME tagging                        → OK, acts=1, target=PRESENT
    body forces `ctx.thing`, UNTAGGED (identity baseline)                  → OK, target=`t`
THE CONTROL THROWS ON THE IDENTICAL TAGGING, so the projection is demonstrably NOT a no-op where the
invariance was measured. A VACUOUS MEASUREMENT WOULD HAVE SHOWN ARM 1 AS OK. It did not.
⇒ THE ORCHESTRATOR'S KNOCK-ON CONCERN IS REFUTED, and so is the reviewer's own version of it. §1.3's probe
arm tags `thing` DELIBERATELY — precisely the non-vacuous case.
AND ON THE PHRASING: "is invariant … — measured" as a PROPERTY claim rather than "is CURRENTLY invariant" is
CORRECT. Key-preservation under `mapAttrs` is a property of the PROJECTION, not a contingent fact about
today's policy surface. The C1 exposure flagged earlier was real ONLY under the counterfactual where the
sibling took the construction route; it declined, and independently the claim is sound on its own terms.

════ ★ :650-652 UNDER THE AMENDED CONTRACT — ONE REAL DEFECT, AND THE FIX STRENGTHENS THE CLAIM ════
Applying "a comment inside the executable core SHIPS AS SOURCE and must meet the CORE's evidential standard,
not prose's":
 · "`mapAttrs` replaces VALUES and preserves KEYS" — a theorem. MEETS IT.
 · "`ctx ? key` is INVARIANT under the projection — measured" — MEETS IT, now measured above on an ACTIVE
   projection with a control.
 · ★ "THE ONE negation-shaped read available here" — DOES NOT MEET IT. An EXHAUSTIVENESS claim, neither
   enumerated nor measured. AND IT IS UNNECESSARILY WEAK: every negation-shaped read over an attrset —
   `?`, `hasAttr`, `attrNames`, `intersectAttrs`, `removeAttrs` — is a KEY-SET OPERATION, and `mapAttrs`
   preserves the key set, SO ALL OF THEM ARE INVARIANT FOR ONE REASON.
   ⇒ THE FIX STRENGTHENS THE DESIGN: replace "the one negation-shaped read available here" with the KEY-SET
   ARGUMENT, which is PROVABLE and covers the WHOLE CLASS. The current wording understates its own result.
 · SECOND, SMALLER: "— MEASURED" DOES NOT BELONG IN SHIPPED SOURCE. It cites a scratchpad probe that will
   not survive, leaving a DURABLE COMMENT POINTING AT NOTHING. The repo's own idiom is to state the REASON,
   not the EVIDENCE — compare concern-policies.nix:103-104, which gives the mechanism and cites no
   measurement.

════ LEDGER HYGIENE — recorded because the near-miss was the orchestrator's ════
The reviewer's retracted interim finding ("empty as measured / bounded by a decidable predicate /
epistemically convenient / the evidence was already in hand") NEVER REACHED ANY BEAD — verified, zero hits
across 4kh.11 and 4kh.6. The retraction arrived before the verdict was recorded and the RETRACTED version is
what the ledger carries.
BUT THE ORCHESTRATOR TOLD THE REVIEWER "I have recorded it in those words" IN A MESSAGE, WHILE IT HAD NOT YET
BEEN WRITTEN TO A BEAD. That loose statement about the ledger is what triggered a STOP-DO-NOT-RECORD alarm
and a full re-send. ⇒ SAY "I WILL RECORD" BEFORE IT IS WRITTEN AND "RECORDED AT <bead>" AFTER. An
orchestrator's claim about the ledger is itself a claim, and agents act on it.
Also restated by the reviewer and worth keeping attached to the verdict: C9 / the retiring-constructs
register (den-hoag-4kh.17) is UNCHECKED BY IT — no access, not in its dispatch. VALIDATED DOES NOT COVER C9
FOR THIS DOCUMENT.


### 15 — 2026-07-28T05:04:35 · Jason Bowman

C9 / C9-a PASS RUN — reviewer r2-regate, fresh from its own VALIDATED verdict, against the same anchor
(md5 b01e55aac3b024fd93f50c5cedf97546, 1352 lines, core :573-687).

★ VERDICT: C9 FAIL (DOCUMENTATION-LEVEL). C9-a PASS. THE VALIDATED VERDICT ON THE CORE IS UNAFFECTED — C9 is
the one thing it did not cover. Remedy is a paragraph, not a redesign. Both underlying answers are FAVOURABLE,
which is precisely why the omission is worth fixing: as written the design gets credit for neither.

Reviewer reasoned about what the design TOUCHES rather than word-sweeping, per dispatch, and re-verified every
site at HEAD this session under the register's own invalidation rule.

──────── PER-ITEM ────────

ITEM 1 — per-class content buckets (den-hoag-4kh.16). NOT-TOUCHED.
Measured: lib/attributes/class-modules.nix and output-modules.nix consume ZERO of the five changed primitives
(edgesBelowStratum, ceilingGate, strataLt, projectCtx, inScope/scopedPool — 0 hits each). R2 operates on
relation edges, claim edges and policy ctx; it makes no representation decision about class content and
entrenches no bucket vocabulary.

ITEM 2 — value-shape predicates. NOT-TOUCHED, and the entry's WITHDRAWAL IS CONFIRMED AT HEAD.
lib/compat/compile.nix:218 is a comment citing v1's key-classification.nix; :251 reads "The FORMER
looksLikeClassContent" — past tense, no live predicate. Independently R2 introduces no value-shape dispatch:
admitPositive = i: ceiling: i <= ceiling compares integer indices of DECLARED strata. Clean on both counts.

★ ITEM 3 — the 2-stage schedule (den-hoag-4kh.18). TOUCHED, INDIRECTLY — AND R2 LANDS ON THE RETIREMENT'S SIDE.
Site verified LIVE at HEAD: lib/default.nix:1074 carries "THE STAGING THAT BREAKS THE CYCLE (design note §3b)"
verbatim; prePassScopeRoots built :1083, consumed :1098.
R2 does not modify the staging, its ordering, prePassScopeRoots, or add a staged pass. BUT R2's changed
projectCtx EXECUTES INSIDE IT: runPrePass dispatches resolveRules = policiesRules.resolveFamily
(default.nix:1104) through dispatch.dispatch (staged-resolution.nix:192-199), and every compiled rule's
produce routes through projectedBase -> projectCtx (concern-policies.nix:234, :265). Direction matters: the
staging operates on R2's code, not the reverse.
★★ AND R2 WEAKENS ONE OF THE STAGING'S OWN JUSTIFICATIONS RATHER THAN ENTRENCHING IT. lib/default.nix:1103
justifies restricting the pre-pass's rule set as keeping it from a body "which could hit an UNCATCHABLE
MISSING-ATTRIBUTE READ" — precisely the failure class that §7's totality fix converts into a catchable named
throw at concern-policies.nix:122. Same defect the reviewer reproduced earlier in this review.
THEORY survives: ABW condition 1 constrains which strata a read may draw from, not whether its caller is
staged or demanded. MECHANISM survives: a demand-driven successor still hands a ctx to a policy body, so the
projection is unchanged.

★ ITEM 4 — __-prefixed state carriers. TOUCHED, WEAKLY — theory survives, mechanism survives and is INSENSITIVE.
Sites verified at HEAD: lib/fleet.nix:117 (__coords), :125 (__containment), and FOUR strip lists —
staged-resolution.nix:171-176, attributes/structural.nix:61-62, attributes/resolved-settings.nix:48-49,
attributes/collections.nix:75-76.
The connection is real: the pre-pass ctx is baseCtxOf id = removeAttrs scopeRoots.${id}.decls [ … ]
(staged-resolution.nix:169-176), and that ctx is what reaches the policy produce — hence projectCtx.
MECHANISM IS INSENSITIVE: projectCtx is a mapAttrs keyed by NAME lookup in ctxKeyStrata, with untagged keys
passing through identity (ks = … or null). A leaked __ carrier passes through untouched; a retired one simply
is not a key. R2 depends neither on a carrier existing nor on any strip list being complete. Under the
retirement the carriers become graph edges, the four strip lists disappear, and projectCtx is UNCHANGED. R2
names, reads and extends no __ carrier and adds no strip list.
Adjacency worth one line: R2's own changed file carries __isEnrich/__pipeOps/__resolveFamily
(concern-policies.nix:236, :239, :405). These are dispatch metadata, not the graph-position-as-payload the
entry scopes, and R2 modifies none of them — but a design editing that file sits next to the entry's concern.

──────── WHY C9 FAILS ────────
R2 touches items 3 and 4 and CITES NEITHER. The spec contains no reference to den-hoag-4kh.17, .16, .18, the
staging, the pre-pass, or the __ carriers — checked; the only grep hit is :999 using "register" as a verb.
C9 requires naming the construct, citing the record, and stating SEPARATELY whether theory and mechanism
survive. None of that is present.

C9-a PASSES. Vocabulary is ABW's (strata, positive/negative occurrence, admittance predicate, conditions 1/2)
and gen-native (relation edges, claim edges, resolve.nta, resolve.attr). No bucket/class-content vocabulary,
no value-shape vocabulary, no staging/pre-pass vocabulary, no __-carrier vocabulary. ★ The renames move AWAY
from position-encoding names (edgesBelowStratum, ceilingGate) toward law-naming ones (positiveEdges,
positiveGate, admitPositive) — the OPPOSITE of entrenching a doomed shape.

──────── THE REMEDY PARAGRAPH (drop into §6 "What is not changed, and why", or as a §11 limit) ────────

> **Retiring-constructs check (`den-hoag-4kh.17`).** Two register items are adjacent to this design and
> neither changes it.
> **Item 3, the 2-stage schedule** (`den-hoag-4kh.18`; live at `lib/default.nix:1074-1098`): this design does
> not modify the staging, its ordering or `prePassScopeRoots`, but its changed `projectCtx` executes inside it
> — `runPrePass` dispatches `policiesRules.resolveFamily` (`:1104`) and every compiled rule's produce routes
> through `projectedBase` (`lib/concern-policies.nix:234`, `:265`). It lands on the retirement's side:
> `lib/default.nix:1103` justifies restricting the pre-pass's rule set as avoiding "an uncatchable
> missing-attribute read", which is exactly the failure §7's totality fix converts into a catchable named
> throw at `lib/concern-policies.nix:122`. THEORY survives — condition 1 constrains which strata a read may
> draw from, not whether its caller is staged or demand-driven. MECHANISM survives — a demand-driven successor
> still hands a ctx to a policy body, so the projection is unchanged.
> **Item 4, `__`-prefixed state carriers** (`lib/fleet.nix:117-127`; four strip lists at
> `lib/staged-resolution.nix:171-176`, `lib/attributes/structural.nix:61-62`, `resolved-settings.nix:48-49`,
> `collections.nix:75-76`): the ctx this design projects descends from one of them (`baseCtxOf`,
> `staged-resolution.nix:169-176`). THEORY survives — condition 1 is about strata, not carriage. MECHANISM
> survives and is **insensitive**: `projectCtx` is a `mapAttrs` keyed by name lookup in `ctxKeyStrata` with
> untagged keys passing through identity, so it neither requires a carrier to exist nor requires a strip list
> to be complete. Under the retirement the carriers become graph edges and the strip lists disappear;
> `projectCtx` is unchanged.
> **Items 1 and 2 are not touched.** `lib/attributes/class-modules.nix` and `output-modules.nix` consume none
> of the five changed primitives, and this design's admittance predicates compare integer indices of declared
> strata, never a value shape (entry 2 is withdrawn and verified retired at HEAD).

──────── COVERAGE ────────
Verified at HEAD by READING: item 1's two consumer files; item 2's two cited lines; item 3's :1074 / :1083 /
:1098 / :1103-1104; item 4's fleet.nix:117 and :125 plus all four strip lists; the projectedBase routing at
concern-policies.nix:234 and :265; the pre-pass dispatch at staged-resolution.nix:169-199.

──────── DOC DEBT ON THIS BEAD NOW STANDS AT THREE ITEMS ────────
(a) the C9 paragraph above;
(b) core-comment at :650-652 — "the one negation-shaped read" fails the amended no-load-bearing-prose
    standard; strengthen via the key-set argument;
(c) "— measured" does not belong in shipped source.
None blocks implementation of the core; all three land before the design drives it.


### 16 — 2026-07-28T05:54:44 · Jason Bowman

DOC-DEBT ROUND 1 — 3 of 3 corrections APPLIED. File now 1381 lines, md5 0f818706cad250b8059555ff1464ca5d (was 1352 / b01e55aa…).

(A1) The C9 retiring-constructs paragraph is IN, at :874-898, end of §6. ★ The reviewer's anchors were independently SPOT-CHECKED at HEAD by the applying agent and ALL HOLD: default.nix:1103 = 'could hit an uncatchable missing-attribute read'; :1104 = `resolveRules = policiesRules.resolveFamily`; concern-policies.nix:234 `checkedProduce name (projectedBase group …)`, :265 `stampProduce name (projectedBase s …)`, :122 `r = stratumIndex.${ruleStratum};` (a BARE SELECT, no fallback — the totality defect, confirmed); fleet.nix:117-127; staged-resolution.nix:169-176 with its strip list at 171-176. So C9 is now discharged against verified sites, not inherited ones.
(A2) Core comment :650-655 now carries the KEY-SET ARGUMENT instead of a bare uniqueness claim: mapAttrs iterates ctx so EVERY key is projected; a key in `ctxKeyStratum` is admitted-or-throws; a key absent takes `ks == null` and identity; keys are preserved and only values replaced ⇒ no ctx read escapes the projection, and the `ctx ? key` invariant follows as a COROLLARY rather than an assertion.
(A3) '— measured' removed from the core comment; claim kept.

★ EXECUTABLE CORE VERIFIED BYTE-IDENTICAL. All 83 non-comment lines extracted and compared line-by-line against the pre-edit read: identical, not an identifier/operator/string/blank changed. Core is now 573-690 (was 573-687), the +3 being A2's comment lines alone. Neither 'locally stratified' nor 'perfect model' was introduced.

★ A DEFECT MY OWN CORRECTION CREATED, now in round 2: A2/A3 INVALIDATED A CROSS-DOC VERBATIM QUOTE — den-hoag-4kh.13's spec §11.2 (:732) quotes File 1's OLD core comment word-for-word, including the '— measured' that A3 deleted. §11.2's ARGUMENT still holds (the new comment keeps the invariance, and in fact establishes it as a corollary rather than a claim, so §11.2 can cite something stronger), but the QUOTE is now a citation of text that does not exist. Editing a quoted source silently breaks its quoters — the same drift class this arc keeps meeting, and I introduced it while fixing a citation defect.

TWO ITEMS DEFERRED WITH REASONS, not dropped: '— measured' also appears in two PROSE HEADINGS (§1.3 :101, §9.3 :1040); left in place, since A3's rationale is 'text destined for shipped source' and headings ship nowhere. And §1.3 prose at :137 still carries the SAME bare-uniqueness phrasing A2 was raised against — A2 scoped to the core comment, so it survived; it is in round 2.

★ SPELLING DEFECT FOUND IN THE REVIEWER'S OWN TEXT: `ctxKeyStrata` and `ctxKeyStratum` are TWO REAL AND DIFFERENT BINDINGS — `ctxKeyStrata` is the user-config attr (stratum → [key], concern-policies.nix:92,117-118, default.nix:1453); `ctxKeyStratum` is the INVERTED key → stratum map built by the foldl' at :112-118, and it is what `projectCtx` destructures and looks up. The C9 paragraph names the former where it means the latter. Being VERBATIM reviewer text does not protect it — verbatim-preservation protects reasoning, not a typo, and a spec naming the wrong binding sends an implementer to the wrong site. Corrected in round 2.

### 17 — 2026-07-28T05:59:22 · Jason Bowman

DOC-DEBT ROUND 2 — COMPLETE. File 1381 → 1382 lines, md5 9061d1469b608c1e1743530c0d545007.
★ CORE BYTE-IDENTICAL TO ROUND 1, HASH-PROVEN NOT ASSERTED: the 83 code-only lines of the core hash to 7c472a43424a1d3b85d2ec83f0ccd1d6, an EXACT match to round 1. Core markers moved 573-690 → 574-691 (+1) solely because item (4) inserted one line ABOVE the core. Zero code characters changed across both rounds.

(3) APPLIED :892 — `ctxKeyStrata` → `ctxKeyStratum` at the lookup reference. ★ AND THE AGENT ESTABLISHED THE CONVERSE, which is what makes this safe: the PLURAL survives at :396, :409, :996, :1009-1011 and is CORRECT at every one — all user-config uses (`ctxKeyStrata = { }`, `ctxKeyStrata.structural = [ "thing" ]`). Only the lookup reference was wrong. The doc now uses each binding for exactly its own thing. A blind rename would have broken five correct sites.
(4) APPLIED :136-140 — §1.3 prose now DERIVES rather than asserts: the projection preserves the key set exactly and replaces only values, so a presence test returns what it would have returned unprojected, and does so for EVERY key rather than for the one the probe tested. ★ That last clause adds the TOTALITY STEP THE PROBE ALONE CANNOT GIVE — the probe tested one key; the argument covers all. It sits directly under :130-131, which already states the mapAttrs key-set fact, so the argument is now LOCAL AND CHECKABLE rather than resting on a claim made 500 lines away.

★ A DEFECT NEITHER OF US KNEW ABOUT, found while fixing mine: THE OLD CROSS-DOC QUOTE WAS NOT VERBATIM EITHER. den-hoag-4kh.13's spec rendered 'IS INVARIANT UNDER THE PROJECTION' in capitals inside a quote introduced by the word 'verbatim:'; File 1's comment had it lowercase. Emphasis had been ADDED INSIDE A VERBATIM QUOTE — a second, older citation defect hiding under the one I created. The replacement reproduces only the source's own capitalisation (KEYS, VALUES) and was verified MECHANICALLY: File 1 :650-655 extracted, `#` stripped, substring test returned True. Not eyeballed.
⇒ Standing lesson: a quote marked 'verbatim' is a CLAIM, and it can be false in the direction of emphasis, which no reader flags because added capitals read as the quoter's formatting rather than as an alteration of the source.

### 18 — 2026-07-29T23:24:40 · Jason Bowman

★★★ LANDED at den-hoag 7c10bb0 + papers f14f29c. The gate-VALIDATED r2 design (spec md5 9061d1469b608c1e1743530c0d545007, 1382 lines, core :574-691) implemented by a fresh-context worker; orchestrator verified independently.

WHAT LANDED: §5 delta table in full — stratum-scope.nix admittance predicates (admitPositive/admitNegative/strataLe; edgesWithin/gateWithin shipped as positiveEdges/positiveGate/negativeGate), over guard strataLt→strataLe, projectCtx via admitPositive, claim-accessor rows 4-5, concern-relations rows 6-7, row 8 ceiling armed at resolution-relations.nix:54. Row 9 (the mandatory hoist) was ALREADY AT HEAD — the spec's anchor a40cc96 predates it; the pairing obligation is discharged by the tree. §7 totality: the bare stratumIndex select is a named catchable throw (measured on both trees: HEAD aborts uncatchably, changed tree returns CAUGHT-THROW with a firing control). negates guard UNTOUCHED (negation-gate 7/7 green throughout = §6's claim confirmed).

§9.4 DISCHARGED PER GUARD: all seven guards measured baseline-vs-changed with a consumption control each (a perturbation that reverts the behavior); row 7 mkRelQuery unreachability measured not assumed (throw-plant unreached at 1975/1996 unchanged; identical plant at mkRelAccessor moves 10 — the instrument fires).

BLAST RADIUS, ACTUAL vs PREDICTED: §9.3's ten re-pinned with mandatory paired controls (every same-stratum admission has a strictly-above exclusion sibling). THREE assertions moved OUTSIDE the enumerated set, all in the predicted CLASS — claim-provide-witness.nix carried §9.2's shape in a third suite (2 of them; the spec's harness never evaluated that suite, so its 'lower bound in two senses' warning is vindicated), and per-production-strata.nix:98 pinned the row-3 message TEXT (1). All three remedied the same way as their class; a structural class sweep (3 predicates, positive controls each) then found THREE further stale-but-green prose sites plus the papers REFERENCE.md claim-accessor bullet, which was internally self-contradictory (A9 same-stratum-permitted cited two sentences above a strictly-below assertion).

VERIFICATION: ci 1980✅/6❌/12☢️ = 1998 exit 1, non-pass compared as a SET — membership identical to the pre-existing 18 (den-pipe 12☢️, pipe-consume 4, compat-feature-severed 1, compat-scope-local-firing 1). parity 71/71 exit 0. Orchestrator re-ran both suites independently; exit codes observed, not relayed.

TWO ORCHESTRATOR ERRORS, both caught by the worker: (1) the dispatch brief carried a stale core anchor ('83 non-comment lines, md5 7c472a43') from the doc-debt round-1 comment — the spec's own §5.1 recipe (77 lines, sha256 7dfa54de) is correct and reproduced; the 83 figure reproduces under no extraction variant tried and is presumed a derivation error in that comment. (2) A MID-WRITE MEASUREMENT: I diffed the tree while the worker was active and relayed the snapshot as state ('per-production-strata shows no diff' — false minutes later); law-30 shape, refuted by the worker's re-measurement.

COVERAGE LIMITS (worker's, spot-verified): no corpus evaluation (spec §11 limit stands); the 102 harness-unevaluable suites are covered only to the extent the real nix-unit run reaches them; 'postres' as a stratum name checked against nothing but local convention.


### 19 — 2026-07-30T00:22:46 · Jason Bowman

POST-CLOSE REFINEMENT (design author, 2026-07-29, archive verified directly): the body attributes 'the finest stratification through which every other factors' to DEFINITION 12 (p. 112). That property is LEMMA 11(2), printed p. 113 — Definition 12 only defines the cluster. Definition 3 p. 96 and Lemma 1 pp. 97-98 citations stand as written.
