# den-hoag-4kh — Kernel purity + roadmap realignment: theory-first audit of the July corpus

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh` |
| status at evacuation | deferred |
| priority | P1 |
| type | epic |
| labels | (none) |
| parent | (none) |
| created | 2026-07-27T20:20:14Z by Jason Bowman |
| last updated | 2026-08-05T20:48:28Z |
| description bytes | 4770 |
| notes bytes | 0 |
| comments | 11 |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

SPEC (pre-review, nothing changed): papers/den-architecture/plans/2026-07-27-kernel-purity-roadmap-realignment-plan.md

OWNER FRAMING (2026-07-27): roadmap aligned against theory-based gen concepts, BEST ARCHITECTURE FIRST. May
require redesigning and re-ordering so the den-hoag KERNEL is a pure graph representation BEFORE the full
backwards-compat layer materializes. Includes auditing what may have been introduced into the kernel that
violates the pure graph / category-theory framework layer from the den feature+compat layer. End vision: an
ALTERNATE den API making graph expressions explicit, companion to and alternative to den's current surface.

THE FRAMING MEASUREMENT — why this cannot be a grep. ci/tests/boundary.nix already enforces kernel/compat
with THREE guards: token scan, import direction, seam enumeration. ALL THREE ARE LEXICAL. None can observe
REPRESENTATION. A kernel file can pass every guard while being a v1-shaped state accumulator with gen-native
naming — which is what the class-bucket holdover and the effects audit already describe. The violation class
is SEMANTIC and the existing detector is LEXICAL: the same shape as every other blind spot found this
session.

CORPUS: 66 specs/2026-07-*.md + 151 plans/2026-07-*.md + STATUS/ (4 files, 939L) + 7 owner-named priority
documents (~3,200L). STATUS/ flagged ESPECIALLY.

WORKSTREAMS: W1 shipped-verification (claims -> commands; STATUS/compat-feature-register + coverage-matrix
are claim registers by construction) · W2 kernel purity audit · W3 drift/lost context · W4 roadmap
realignment (consumes W1-W3, explicitly permitted to conclude shipped work should be redesigned) · W5 the
alternate graph API, DESIGN ONLY and gated on W2+W4 (specifying it earlier designs against the very
representation under question).

§4 IS THE LOAD-BEARING PART — falsifiable criteria for "pure graph representation", each drawn from a
violation this project has ALREADY diagnosed so each has a known-positive: (1) state accumulation instead of
query (class buckets); (2) __-prefixed state carriers in the kernel (the live __provider writer at
den-brackets.nix:41-47); (3) value-shape dispatch (looksLike/isNestedKey — explicitly NOT the type-level test
in y53 rev 3, which is legitimate); (4) bounded-depth traversal (queries are DIRECT or REACHABLE-closure,
never depth-N); (5) effect-runtime holdovers (the A1 runPrePass accumulator); (6) invariants documented but
unenforced (the registry.nix:394 bijection, just promoted to a runtime guard in y53 rev 3). EVERY FINDING
MUST NAME ITS CRITERION AND CITE A SITE; a finding citing no criterion is an opinion.

★ THIS ARC IS THE PARENT OF TODAY'S IN-FLIGHT WORK, NOT A SIBLING. Today entered through m0a (a registry
mis-key) and inherited that entry point's framing, so den-hoag-h5d got scoped as documentation hygiene and
its findings were classified as doc-correctness. Several are architecture signal and are re-read as such:
  - THE LINE-BUDGET MISS IS A KERNEL-PURITY SIGNAL, not a docs row. Estimate 1,010-1,510 for the 12
    attributes; kernel is 13,337; the ~7,000 v1 baseline is VERIFIED CORRECT at the spec date. A 10x miss
    confined entirely to the estimate, on a design whose whole claim was compression, is what §4's criteria
    predict when non-graph-native machinery accumulates. W2 lead.
  - The five documented-but-zero-consumer features are W3 drift, not typos — two were never built anywhere.
  - The live __provider writer under a "layer is DELETED" claim is the first CONFIRMED W2 item (criterion 2).
  - CONFORMANCE.md's 148 rows are W1's INSTRUMENT. Its 30%-vs-73% reproduction split is itself a finding:
    the status surface drifted far more than the architecture prose.

SEQUENCING CONSEQUENCE (spec §8.4, recommendation needing ratification): h5d CONTINUES as W1's instrument.
den-hoag-y53 and den-hoag-8rf PARK until W1/W2 report — both are compat-layer or registry-shape work, and the
directive puts kernel purity first; hardening a compat seam now risks cementing a shape the audit may change.
AGAINST parking: y53 is small, twice-reviewed, and fixes a live silent-data-loss defect (m0a) that is
mis-keying corpus registries TODAY. The honest trade is "a real current defect" vs "possible rework" — owner's
call.

OTHER OPEN: does W5's API belong in den-hoag or is it a den BINDING of a gen-level surface (gen-graph/
gen-select already own query vocabulary)? How far does best-architecture-first reach into shipped work, given
compat is 11,318 lines with a death date? Is STATUS/coverage-matrix a claim register or a forward-looking
plan — if forward-looking, W1 would mis-read its rows wholesale. And does the compression finding change W2's
shape from a criteria sweep into a provenance walk over lib/ by subsystem?

## Comments (11)

### 1 — 2026-07-27T20:21:58 · Jason Bowman

SCOPING MEASUREMENT (2026-07-27) — answers spec §8.3 and RE-POINTS W2 before any dispatch.

THE TWO STATUS TRACKERS ARE DIFFERENT AXES:
  coverage-matrix.md calls itself "the SINGLE AXIS-2 tracker" — den v1 public surface -> gen-native parity,
  "the SYMPTOM axis the north-star demoted", in its own words. It is BOTH a claim register and an
  outstanding-work index: ~48 completion claims (18 SHIPPED + 21 checkmark + 9 DONE) vs 6 OPEN + 1 GAP.
  => W1 can use the completion claims; its OPEN rows are FORWARD-LOOKING and must not be read as shipped.

  route-through-board.md is the AXIS-1 tracker — "graph-native framework correctness; dissolve effect-runtime
  holdovers; corpus-eval = symptom" — and names its roadmap as
  specs/2026-07-24-den-hoag-effects-runtime-audit.md, the first of the owner's seven priority documents.

=> ROUTE-THROUGH-BOARD IS W2'S PRIMARY INPUT, NOT COVERAGE-MATRIX. Aiming the kernel-purity audit at the
coverage matrix would have audited the SYMPTOM axis. The board records 17 SHIPPED route-through rungs —
Tier-B rungs 1-2, A5->G6, A3/B9, the FLAGSHIP A1 runPrePass state-accumulator dissolution @6bef742, compat-1,
B7->G3, the six-rung raw/typed-dual dissolution, gen-link R0-R4 — each asserting that a specific
effect-runtime holdover was dissolved. That is precisely the claim set W1 must verify and W2 must audit for
whether the dissolution is real or renamed.

IT ALSO RECORDS ITS OWN UNFINISHED WORK, and in the sharpest available terms: B15/B20 are "NOT plain
graph.ancestorsOf/circular swaps — still OPEN, each needs a gen-side decision (NOT done; I declined the naive
swap, THE REAL ROUTE-THROUGH IS UNBUILT)". A self-reported W2 gap with a stated reason — and the model for
what W2 output should look like.

DRIFT FOUND BEFORE W3 STARTS: coverage-matrix declares itself LIVE and maintained (last update 2026-07-26)
and pins den-hoag 4044ed5. HEAD is c0aa7be — THIRTY-FOUR COMMITS LATER. A live tracker 34 commits behind
means every "shipped" row in it is a claim about a tree that has since moved, so W1 must re-verify rather
than inherit.

CONSEQUENCE FOR DISPATCH: W2 reads route-through-board + the effects-runtime audit FIRST; coverage-matrix is
W1 input only. This was worth measuring before spending agents — the arc would otherwise have started on the
axis the north star explicitly demoted.

### 2 — 2026-07-27T20:23:13 · Jason Bowman

OWNER DIRECTIVE (2026-07-27) — THE DELIVERABLE IS THE BEAD GRAPH, AND IT MUST CONTAIN ONLY VALIDATED WORK.

"Ensure that beads contains a proper graph of VALIDATED CORRECT work. Some of these specs are self-authored
and haven't gone through review, so when we identify something unshipped, it goes through adversarial
architecture alignment review against pure gen and academic provenance."

PIPELINE — an unshipped finding does NOT become a bead. It becomes a REVIEW CANDIDATE:
  audit finding (unshipped)
    -> adversarial architecture-alignment review, against BOTH:
         (a) the pure-gen criteria in spec §4
         (b) the ACADEMIC RESULT the design claims
    -> VALIDATED : enters the graph, labelled arch-validated, citing criterion + provenance
       REJECTED  : recorded WITH ITS REASON — never silently dropped; a rejected design that leaves no
                   trace gets re-proposed (this session already re-litigated one twice)
       REDESIGN  : design work first; the original does not enter the graph

ACADEMIC PROVENANCE IS A REAL GATE, not a citation ritual. REFERENCE.md names seventeen results (Knuth 1968,
Vogt 1989, Neron 2015, van Antwerpen 2016/2018, Mokhov 2017/2018, Palmer 2024, Reynolds 1972, Sloane 2010,
Arntzenius & Krishnaswami 2016, Madsen 2016, Kahn 1974, Leijen 2005, Bracha & Cook 1990, Apt-Blair-Walker
1988, Fagin 2005). A design claiming one is checked against WHAT THAT RESULT ACTUALLY SAYS. The corpus
already sets the standard both ways: a corrected OVER-CLAIM (the Neron Thm 1 transfer, dropped and replaced
by the Statix 2016 §4.3 two-stratum discharge) and a deliberate INFORMED-BY-ONLY marking (Kahn 1974, because
pipe.gather has multiple writers and violates the single-writer condition that gives KPN its determinism).

LABELLING — the marker is POSITIVE. Validated beads carry `arch-validated`; ABSENCE means not-yet-validated.
Labelling the unvalidated ones instead would fail OPEN: a forgotten label would read as validated. This
session's recurring lesson is that silence must never read as success.

★ HONEST ACCOUNTING — TODAY'S BEADS ARE IN THE UNVALIDATED CLASS. Eleven beads were filed today from
self-authored specs. Only den-hoag-y53 has been adversarially reviewed — twice, REVISE both times, finding
two blocking defects plus one that my own F2 fix INTRODUCED (re-creating .8's silent-registry-loss inside the
fix for .8). The rest — 8rf, h5d, 9w8, deb, 4kh, 00g, bxa, the benchmark bead, the __provider bead, the
queryEdges bead — are self-authored and unreviewed. They must not be presumed correct because they are
recent. A VALIDATION-STATUS PASS OVER THE EXISTING 80 BEADS IS PART OF THIS ARC, not a separate courtesy.

That pass is also a scoping input: if most of the 80 are unvalidated, the graph's current shape is a
hypothesis, and any roadmap re-ordering (W4) built on it inherits that.

### 3 — 2026-07-27T23:06:04 · Jason Bowman

RESUME PROMPT FOR A FRESH SESSION — the arc's cold-start entry point.

FILE: papers/den-architecture/STATUS/RESUME-PROMPT-4kh.md (a paste-able prompt, not a checkpoint; the
existing STATUS/RESUME-CHECKPOINT.md covers the earlier WS-B arc and is NOT superseded — it is a different
arc).

DESIGN INTENT: the prompt reconstitutes from BEADS, not from prose. It opens with `bd show den-hoag-4kh` +
`bd ready` and states plainly that the audit results live in bead COMMENTS because markdown does not survive
compaction. The markdown is the fallback, not the source.

STRUCTURE, two phases as the owner specified:
 PHASE 1 — BRAINSTORM the three blocking designs (each has a measured defect and NO design, so each is
   creative work, not a lookup; the brainstorming skill is named explicitly): W2's non-confluent reroute fold
   (with the graph-native form and the fact that lib/query.nix already lowers that follow-expression); the
   gate's Candidate-A REDESIGN (producesByName has no loud twin where both siblings do); and 4kh.11's ABW
   guard (with the instruction to confirm primary text before touching code, since the finding rests on a
   third-party restatement — while noting the DOC fix is safe now on the internal contradiction alone).
   Each design then passes the gate (4kh.6) before becoming tracked work.
 PHASE 2 — ORCHESTRATE dispatch → review → deliver over `bd ready`, with the four items needing owner input
   named (4kh.7 sequencing, 4kh.10 the 72+671 tests, 4kh.4 W4 held with its reason, 4kh.9 the hook rebuild).

CARRIED FORWARD, because these are what make the next session cheap:
 - The STANDING BAR verbatim (theory over v1-compat and least-effort; orchestrate don't implement; spec
   before development; beads hold only validated work; arch-validated is a POSITIVE label).
 - ALL SIX INSTRUMENT TRAPS, each with its measurement and control — languages field omits Nix; CALLS misses
   attrset-mediated calls; search_graph returns Function nodes only; git log -S is blind to body rewrites;
   Cypher props are on file_path and the loop metrics are useless for Nix; exclude .worktrees/. Plus the `bt`
   body-token technique, which is where the graph beats grep.
 - THE METHOD RULES that each caught a real false result, including the centralized-rationale correction (the
   why lives in the 275K decision log, not in the doc stating the conclusion) and "all three gates green
   settle nothing".
 - "REPORT BEFORE GOING IDLE" as a dispatch requirement — every agent this session went idle without
   reporting and one never answered at all.
 - ★ A "MISTAKES MADE — DO NOT REPEAT" section naming the orchestrator's three: a criterion calibrated on a
   known-positive that did not exist; cost encoded as correctness in two blocking edges; a wrong file path
   propagated into a dispatch with compat-vs-kernel reasoning built on it.

The last section is deliberate. Every one of those three was caught by an independent agent rather than by
review, and a resume prompt that omits them invites their repetition.

### 4 — 2026-07-28T07:24:57 · Jason Bowman

★ SESSION RECORD — 2026-07-27/28. THE ARC SHIPPED ITS FIRST CODE, AND THE TRACKER STOPPED BEING THE ONLY
THING THAT GREW.

SHIPPED — `ec6ba23`, den-hoag, UNPUSHED PENDING INDEPENDENT IMPLEMENTATION REVIEW (in flight):
the ABW supportedness law (`4kh.13`, P0). The enrichment attribute now PUBLISHES THE STATE IT REACHED and
checks it against the re-derivation, instead of assuming they agree. 11 tests, 4 red without it. Suites
1922/1922 and parity 71/71, verified by the orchestrator independently with exit status seen directly.

PUSHED — 7 commits to `papers/den-architecture`: two gate-VALIDATED remedy designs (`6fb0adf`), the
producesByName trust design through three gate rounds (`729e4cb`, `f88e6a4`, `97d1dad`), the bucket-to-seed-
query design and its gen-graph rewrite (`06c2f9e`, `09109f8`), and a cold-start prompt rewritten against a
shipped arc (`85b630d`).

THE GRAPH GREW FROM 94 TO ~118 ISSUES, AND EVERY ADDITION IS A MEASURED FACT — none was taken from a memory
file without re-measuring at HEAD. Notable new entries:
  `4kh.41` P0 — `declare.inject`/`declare.reroute` DO NOT REACH THE BUILT SYSTEM. Two consumers of class
    content; only one applies the acts. Every introspection surface AND THE PARITY ORACLE agree the relocation
    happened; the built configuration does not contain it. Owner-ruled acceptable to fix by unification;
    blocked on `4kh.16`, and a narrower ruling is now owed (see below).
  `4kh.35` — the `to` consumer-addressed delivery seam, THE ONE named net-new kernel binding seam in the WS-B
    design, exists in no tree, no bead and no tracker. A design can lose its only new seam because trackers
    record work that STARTED.
  `4kh.36` — pipe run-wiring: 15 wrong-value divergences, every one commented out, suite green.
  `4kh.37` — settings blind `//`: a design doc calls it a latent correctness bug and an in-tree comment denies
    it; nothing records which is right.
  `4kh.43` P1 — a design hand-rolled `transpose`/reachability that gen-graph already provides AND den-hoag
    already calls, at a site whose comment reads "NOT a hand-rolled from/to swap".
  `4kh.21` — the declared-surface POSTURE decision node: `deps` throws on read, `provision` returns null,
    `excludes` is inert. THREE INCOMPATIBLE POSTURES for one defect class, which is why it is one decision and
    not three tasks.

★ TWO OWNER QUESTIONS OPEN, BOTH ON `4kh.16`, NEITHER BLOCKED BY ANYTHING ELSE:
  Q2 — WHOSE `Acts` GOVERN A REACH-SOURCED ASPECT: the PROJECTING scope's, or the aspect's OWNING scope's?
    Recommendation READING B (owning), on theory: a declaration's meaning should not depend on who assembles
    it, and "one query, two consumers" is only TRUE under B. Under A the two consumers are different functions
    that agree wherever Ρ is empty — which is everywhere on the corpus, and THAT AGREEMENT IS PRECISELY THE
    PROPERTY THAT LET THE CURRENT DIVERGENCE SURVIVE THREE GATE REVIEWS. Cost of B is real: `reach` must carry
    a scope coordinate it does not have, touching delicate fixture-pinned dedup.
  Q3 — DOES `exempt` STAY REACH-SOURCED at the terminal? Recommendation READING A (it stays). A DIFFERENT
    ANSWER FROM Q2 AND LEGITIMATELY SO — they are different questions.
  NOTHING IN THE CORPUS DISTINGUISHES EITHER PAIR. Zero reroute sites, zero inject producers ⇒ the readings
  are extensionally equal on everything currently built. The choice is PURE THEORY and parity cannot settle
  it — exactly the case the north-star ruling anticipates.

★★ WHAT THE ARC LEARNED, recorded because it changed how the work is run:
  1. THE REGISTER MUST BE READ, NOT SWEPT. Both C9 hits were invisible to text search — one lived only in two
     guards' ERROR-MESSAGE TEXT, the other three hops up an inheritance chain. A design is written in ITS OWN
     vocabulary, so the vocabulary is where the link will NOT be.
  2. ASK THEORY, MECHANISM AND ARGUMENT SEPARATELY. They survive a retirement independently. One design's
     mechanism IMPROVED under the retirement (unrecorded, because nobody asked); another's theory and
     mechanism survived while ITS ARGUMENT DID NOT.
  3. "THE LIBRARY EXISTS" DOES NOT MEAN ITS SURFACE HAS YOUR SEMANTICS. Adopting gen-graph would have silently
     deleted a cycle abort the hand-rolled recursion enforced FOR FREE, and one primitive is partial with an
     error that escapes `tryEval`.
  4. A COST COMPARISON WHOSE WORKLOAD CONTAINS THE GUARD'S OWN FIXTURES MEASURES THE FIXTURE — it reported a
     guard as CHEAPER. A trap that FLATTERS is worse, because nobody re-measures a pleasant result.
  5. A DELETED CLAIM SURVIVES WHEREVER IT IS CITED. Killing one option left two dependents re-asserting it.
  6. AN IDLE NOTIFICATION IS EVIDENCE OF NOTHING. Measure the artefact.
  7. NEVER TAKE A LINE NUMBER FROM A DIRTY TREE FOR A BRIEF THAT NAMES A COMMIT — orchestrator-caused, twice.
  8. ★ "TREAT MY FACTS AS REFUTABLE" HAS NOW CAUGHT AN ORCHESTRATOR ERROR IN SEVEN CONSECUTIVE DISPATCHES.
     It is mandatory in every brief, not good practice.

MEMORY WAS RESTRUCTURED (`4kh.19`): ~5914 → ~5250 lines, project STATE migrated into this graph, archives at
`4kh.27`/`4kh.29`/`4kh.31`. The division is now explicit — MEMORY = how to work, BEADS = state and its
dependency graph, CODEBASE-MEMORY = code structure. A 927-line memory had recorded a LANDED arc as
"backburnered, zero shipped code, do not resume", and asserted the real repo path does not exist.
★ `.beads/beads.jsonl` is a passive VIEWER EXPORT carrying no comments; `bd show` is the only complete read.
The Dolt DB has NO REMOTE (`pm3`) — issue rows reach the remote through git, THE REASONING LAYER DOES NOT.


### 5 — 2026-07-28T10:46:31 · Jason Bowman

★★ FOUR OWNER RULINGS, 2026-07-28 — recorded on the epic so a cold session gets them without reconstructing
the reasoning from four separate beads.

1. `4kh.46` — THE SUPPORTEDNESS GUARD'S FALSE POSITIVE: **COMPARE ON A COMPARISON-TOTAL PROJECTION.**
   Keep the `enrich` surface; exclude incomparable values from the equality rather than failing on them, and
   state the resulting hole as a LIMIT OF THE LAW. ★ The reasoning generalises: A FUNCTION RE-DERIVED
   IDENTICALLY IS NOT AN UNSUPPORTED FACT. Nix's `==` cannot answer the law's question for closures, and
   answering "they disagree" when the instrument cannot tell is a FALSE POSITIVE, not a conservative one. The
   equality was the wrong instrument; the value was never the wrong shape. And narrowing a public surface to
   fix a guard is backwards — the guard exists to serve the surface.

2. `4kh.16` Q2 — **READING B: THE OWNING SCOPE'S `Acts` GOVERN A REACH-SOURCED ASPECT.**
   A declaration's meaning does not depend on who assembles it. Makes "one query, two consumers" TRUE BY
   CONSTRUCTION, which was the design's whole claim. ★ Cost accepted with eyes open and SCOPED SEPARATELY:
   `reach` must carry a scope coordinate it does not have, on both legs, and "the owning node" is not
   well-defined for an element that survived a cross-scope collapse. Do not smuggle that into this design.

3. `4kh.16` Q3 — **READING A: `exempt` STAYS REACH-SOURCED AT THE TERMINAL.** Deliberately a DIFFERENT answer
   from Q2. ★ THE ASYMMETRY IS THE RULING: content follows the DECLARING scope, exemption follows the
   ASSEMBLING scope, because they answer different questions. Unifying them for tidiness reintroduces the
   silent delta (own-node) or pushes a projection concern onto the node query (reach-sourced). O8's fixture is
   owed BECAUSE OF the ruling — it is what pins the asymmetry against a future clean-up.

4. `4kh.21` — **NAMED-REJECT AT DEFINITION TIME**, for `deps` and `provision` only. ★ EXPLICITLY REVISABLE:
   owner said "we can change the decision later". Read it as "reject until someone needs it", not "these
   capabilities are refused" — and say so IN the rejection message, since a named error that explains itself
   is the difference between a closed door and a locked one. User impact today is ZERO, which is what made it
   safe to set now.

★ AND THE QUESTION THAT BROKE ITS OWN BEAD: the owner asked what the USER IMPACT of (4) actually was, and the
measurement refuted the bead's premise. `excludes` is NOT the same class as `deps`/`provision` — DEN V1
CONSUMES IT (`nix/lib/resolve-entity.nix:22`, `:72`) and nix-config DEPENDS on it with the author's intent
written beside each line (`modules/den/policies/fleet.nix:85-88`, `:91`). So under den-hoag those policies RUN
while the configuration explicitly disables them — a LIVE PARITY BREAK, silent, on a real fleet. It left the
decision node and is now `9xo.28`, P0, with one answer: honour it.
⇒ THE LESSON, and it is why the question was worth asking: I had classified three surfaces by their SYMPTOM
— declared, accepted, not honoured — and treated a shared symptom as a shared cause. One was a missing v1
behaviour with live consumers; two were unbuilt surfaces with none. **A DEFECT CLASS MUST BE DEFINED BY CAUSE
AND BLAST RADIUS, NEVER BY HOW IT LOOKS FROM OUTSIDE.**


### 6 — 2026-07-28T16:34:13 · Jason Bowman

★ PROCESS CHANGE, 2026-07-28 — GATE TO IMPLEMENTABLE, NOT TO CONVERGENCE. Recorded because it changes how the arc runs, and because the evidence for it is specific rather than a preference.

THE OWNER ASKED FOR AN HONEST ASSESSMENT AND THE HONEST ANSWER WAS THAT THROUGHPUT IS BAD. Measured at the time: 18 spec commits against 6 code commits, ONE kernel defect actually fixed, and the open P0/P1 count HIGHER than at session start. The quality mechanism works; the output rate does not.
AND THE OWNER'S OWN FRAMING WAS THE CORRECTIVE: 'conceptually I'm just envisioning the graph of nodes and their resolution is a query across them — if we have the graph primitives that sounds like it shouldn't be that hard.'
★ I CHECKED THAT AGAINST THE ARTEFACT RATHER THAN REASSURING, AND THE OWNER WAS RIGHT. The bucket design's executable core is 108 LINES OF CODE under 195 LINES OF COMMENT inside a 1525-LINE DOCUMENT — and THE QUERY ITSELF IS TWO LINES:
    classSeedsAt = frame: n: exempt: injects: c:
      prelude.concatMap (raw n exempt injects) (srcOrder frame c);
Content at a channel is the node's own content gathered over the channels that relocate INTO it. Everything else is edge extraction, the preimage, attribute wrappers, and the totality driver — each present for a measured reason, none gratuitous, all of it around a two-line idea.

★ THE JUDGEMENT, WITH THE EVIDENCE BOTH WAYS. Four gate rounds on that design; THREE OF FOUR FOUND REAL CODE DEFECTS, not prose — the gen-graph adoption, the empty-relocation short-circuit, and the node domain. So the rigour was NOT wasted and this is not an argument that gating is theatre.
★ BUT ALL THREE WOULD HAVE BEEN CAUGHT BY A RED TEST, AND FASTER. A two-hop reroute through an unregistered channel is a FIXTURE, not a review finding. The gate found it by reading; a witness would have found it by failing.
⇒ STANDING ADJUSTMENT: GATE A DESIGN UNTIL IT IS IMPLEMENTABLE, THEN LET THE IMPLEMENTATION'S OWN WITNESSES BE THE FINAL CHECK. Reserve full adversarial re-attestation for designs whose defects a test CANNOT express — semantic forks, retiring-construct entanglement, claims about what a guard judges. Those are exactly what C9 and the register are for, and they remain non-negotiable.
WHAT THIS DOES NOT CHANGE: spec before development; measured defects entering the graph directly; rejections recorded with reasons; briefs stating their facts as refutable. The last has caught an orchestrator error in TEN consecutive dispatches and is the single highest-yield rule in the arc.

FIRST APPLICATION: the bucket design went to implementation (`seeds-impl`) rather than to a fifth gate, with 4kh.12's ORIGINAL fixtures landing FIRST AND RED so the replacement is proven against the real defect rather than its own restatement of it.

### 7 — 2026-07-28T20:47:56 · Jason Bowman

★★ STRUCTURAL SURFACE AUDIT — THE REVIEW THIS EPIC WAS CHARTERED FOR, run 2026-07-28 at c42df53 against six
measured witnesses. Read-only, source-read throughout: NO EVALUATION WAS RUN, and the auditor says so.

MY THESIS — "den-hoag stores RESOLVED where v1 stores DEFERRED, in shapes that cannot carry their metadata" —
VERDICT: **PARTIAL**, and both halves are better for being corrected.
 · CLAUSE 2 HOLDS BUT SHARPENED: `den.policies` CAN carry metadata — the record form `{ __condition; fn }`
   ALREADY EXISTS (concern-policies.nix:148-150) and `mkRules` ALREADY READS `__produces`/`__firesAtKinds`/
   `__resolveFamily`/`__excludeFamily` OFF THE VALUE (:340-357). The defect is that THE DOCUMENTED DEFAULT IS
   THE BARE CLOSURE (lib/default.nix:474) AND THE RECORD IS THE EXCEPTION. ⇒ THE FIX IS A PROMOTION, NOT A
   DESIGN.
 · ★ CLAUSE 1 DOES NOT GENERALIZE. Confirmed at EXACTLY ONE SITE, `placeRemapped`. Everywhere else den-hoag is
   scrupulously laziness-preserving AND ITS OWN KERNEL STATES THE CONTRARY LAW — lib/nest.nix:17-23: "the
   engine may not force `inner.payload` during wiring"; "a CONTENT contribution carries the raw module face
   … still open to further merge at the mount". Also lazy by law at class-modules.nix:4 and
   compat/registry.nix:310-312 ("nothing is forced here"). ⇒ WITNESS 4 IS ONE PATH THAT DID NOT GET THE LAW
   THE REPO ALREADY WROTE, NOT A SHAPE. That makes P4 a RE-ROUTING rather than a redesign.

★★ THE SHAPE THE EVIDENCE ACTUALLY FORCES:
    **MISSING INFORMATION IS RECOVERED BY EXECUTION WHERE IT SHOULD HAVE BEEN CARRIED BY DECLARATION.**
FOUR INDEPENDENT PROBE MECHANISMS, EACH WITH ITS FAILURE MODE DOCUMENTED IN ITS OWN COMMENT:
 1. `probeOf` (concern-policies.nix:170-186) fires the user's policy against a FABRICATED SENTINEL CTX to
    learn its stratum and produced kinds. Its own header: "HONEST LIMIT: tryEval cannot catch a
    non-recoverable eval error … a body that field-accesses a REQUIRED sentinel coord bare still fails HARD."
 2. `registryKindOf` (compat/registry.nix:328-344) recomputes id-hashes against widened instances to learn a
    namespace's kind. "THE PROBE MUST BE TOTAL, and tryEval cannot make it so."
 3. `discoverKinds`/`discoverChannels`/`discoverClasses` (entity.nix:22,68,96) — THREE SEPARATE FREEFORM
    MODULE EVALS to learn what the user declared.
 4. `stampTreeOf` (compat/registry.nix:292) walks a PARALLEL OPTION TREE to learn which fields exist.
⇒ SUBSUMES WITNESSES 1, 2, 3 AND 5. And absence-ambiguity is a CONSEQUENCE, not a peer: a probe returns
"nothing", and NOTHING CANNOT SEPARATE not-applicable / threw-and-was-swallowed / genuinely-empty. Measured at
a SECOND independent site — concern-policies.nix:358 `expanded = probeActs == [ ]` carries all three meanings,
with the header conceding a caught throw is "treated IDENTICALLY to an empty probe".
★ NEW DEFECT, IN NO BEAD: THE PROBE IS UNCONDITIONAL. `probeActs` binds at :345 and `expanded` forces at :358
BEFORE every branch of `baseRules` — SO A POLICY THAT FULLY DECLARES `__produces` IS STILL FIRED AGAINST THE
SENTINEL. DECLARATION DOES NOT CURRENTLY BUY YOU OUT OF THE PROBE.

★★ THE ORDER, WITH THE DISSOLUTION MAP — the most valuable output:
 P1 POLICY VALUE BECOMES A DECLARED RECORD. LARGEST DISSOLUTION IN THE GRAPH. Kills `probeOf` + `sentinelFields`
    + the tryEval-swallow ambiguity; kills `mkExpanded`'s 3-WAY BLIND FAN (concern-policies.nix:396-410) —
    ★ ONE DECLARED RULE REPLACES THREE SPECULATIVE ONES, WHICH IS THE 241 SPURIOUS FIRINGS; demotes
    `producesByName`/`resolveFamilyNames`/`excludeFamilyNames` to compat desugar inputs, WHICH IS WHERE THEIR
    OWN HEADERS ALREADY SAY THEY BELONG. Closes den-hoag-9xo.54 OUTRIGHT. Dissolves witness 2 (both meanings
    separate), witness 3 (the hidden predicate in `fireFeedAt` becomes a named function over a named field, so
    the two call sites NAME what they select), and the inert-`excludes` problem.
 P2 NODE RECORD GETS A METADATA SLOT — `{ decls; meta }`. Cheap, same family, and it is the PLACE P3 NEEDS.
    Dissolves the 4-WAY DUPLICATED `removeAttrs [ "__edges" "__containment" "__coords" "__root" ]`
    (staged-resolution.nix:172-175, collections.nix:74-77, resolved-settings.nix:47-50, structural.nix:110-113)
    — a repair maintained in four places replaced by a construction where forgetting is impossible.
 P3 ENTITY RECORD DERIVES FROM THE SCHEMA. BLOCKED ON P2. Dissolves witness 5 (den-hoag-9xo.49) — `aspect`,
    `environment` AND `microvm` AT ONCE — and the user-extended/den-declared distinction vanishes because both
    come from one source. ★ CARRIES AN OWNER-LEVEL QUESTION (below).
 P4 ROUTE PLACEMENT ADOPTS THE CONTRIBUTION LAW. INDEPENDENT OF P1-P3, CAN RUN IN PARALLEL. Dissolves witness
    4 (den-hoag-9xo.51) plus the two ledgered divergences at output-modules.nix:535-546 — including ★ THE
    PRIORITY-ANNOTATION COLLAPSE (mkDefault/mkForce DESTROYED at the nested boundary), which is the sharpest
    measured consequence and IS NOT IN THE BEAD.
 P5 ENTRY POINT DECLARES ITS OUTPUTS. LAST — witness 6 is where six causes converge, and fixing it first only
    moves the failure inward.

★★ WHAT IS ALREADY RIGHT — DO NOT CHURN: the HOAG attribute layer (`readsAttrs` is REALLY ENFORCED, not
documentation — gen-resolve/lib/schedule.nix:35-36 builds the attr-dep graph from it); `lib/compat/ingest.nix`
(single-point, lint-enforced); `lib/nest.nix` + `lib/receivers.nix` (★ P4's ANSWER, ALREADY WRITTEN);
`structural.nix`'s supportedness `project` — the law shipped tonight — called EXEMPLARY for stating its own
limit; and ★ `den.productions` (concern-productions.nix), which is THE TEMPLATE P1 SHOULD BE REBUILT AGAINST.
THE RIGHT PRIMITIVE ALREADY EXISTS IN-REPO.
★ AND THE SHIP-GATE GREEN IS EXPLAINED RATHER THAN EXPLAINED AWAY: its fixture has NO policy, NO route, NO
custom kind, NO entity field beyond defaults — so what it proves byte-green is THE SPINE (ingest → compile →
resolve → class-slice → terminal crossing). ALL SIX WITNESSES LIVE IN SURFACES THAT GATE DOES NOT EXERCISE.
The green is real and its scope is now known.

★ THE OBSERVATION THAT MAKES THE WHOLE REFACTOR TRACTABLE: the surfaces WITH definition-time validators
(`concern-productions`, `concern-derived`, `concern-relations`, `edges`, `production-guard`,
`concern-disciplines`) ARE THE ONES BUILT LATE; the bare-`raw` surfaces (`policies`, `classes`, `quirks`,
`include`, `settings.layers`, `contentClass`, `linearization`) are THE EARLY, v1-FACING ONES.
⇒ den-hoag ALREADY CONVERGED ON THE RIGHT SURFACE DISCIPLINE. THE WRONG PRIMITIVES ARE PRECISELY THOSE THAT
PREDATE THE CONVERGENCE. That is why P1 is a promotion to an existing in-repo standard rather than an
invention — and it is the strongest evidence the refactor is finishing a direction rather than starting one.
SYSTEMIC DATUM: lib/default.nix has 39 `options.den.*` declarations and 35 `merge.types.raw` — the structured
declaration surface is essentially UNTYPED, with its field schema written in the `description` STRING.

CORRECTIONS TO MY BRIEF: `placeRemapped` is output-modules.nix:547-**575**. "Cannot carry its own metadata" was
TOO STRONG. And `lib/entity.nix`'s own header (which I repeated) overstates the sidecar — at HEAD `parent` is
read from gen-schema `_topology` (:56) and only `contentClass` is a genuine sidecar.
COVERAGE, HONEST: NO EVALUATION RUN — every claim is source-read. The auditor did NOT re-measure my numbers
(241 firings, 45-vs-5 definitions, 107 policy names, 0/13 templates); those remain mine. `compat/bridge.nix`
not read; `output-modules.nix` ~140 of 1200 lines; `compile.nix` ~120 of 1979; witness 6's six causes not
enumerated.


### 8 — 2026-07-28T21:22:09 · Jason Bowman

★ TWO CORRECTIONS TO THE STRUCTURAL AUDIT, from the excludedType re-derivation (den-hoag-4kh.49). Both matter for the refactor order.

1. ★ THE AUDIT'S deepSeq CENSUS WAS NOT TOTAL. It enumerated four kernel deepSeqs (concern-policies.nix:185, query.nix:86, default.nix:2607/:2618) plus gen-scope's parentIndex. MISSING: **lib/compat/parity/oracle.nix:504**, a real `builtins.deepSeq` over `denOn.output.systems.<cls>.<id>` in shipped lib/. It is a class-share parity oracle rather than the resolution path, so it does not resurrect the dead justification — but 'no such deepSeq exists' was stated more broadly than the census supported. The finding survives; its scope was overstated.
2. ★★ THE AUDIT'S MECHANISM FOR WITNESS 5 IS WRONG, AND IT WAS THE ONE PIECE I RELAYED MOST CONFIDENTLY. `excludedType` has not dropped fields since 77cb3c8 — it partitions transport, and the declared field set is identical either way (`stampFieldNamesByKind` unions both trees). So P3 is NOT gated on that question, and witness 5's cause is OPEN. See den-hoag-9xo.49.
⇒ P3's CONTENT CHANGES: 'which fields reach the record' is already answered — ALL of them do. The real open question is whether the field set should keep coming from A PARALLEL nixpkgs-lib EVAL OF THE REGISTRY at all, rather than from `den.schema` directly. That is a smaller and better-posed question than the one the audit set.

★ AND ONE FINDING THE AUDIT WOULD HAVE WANTED, because it is the charter in the wild: the dead justification is a TRANSPOSED INHERITANCE, not merely a stale one. v1 GENUINELY HAD the deepSeq the comment names — the nix-effects trampoline deepSeq'd state at every step (denful/den @ 99cc0c5a nix/lib/aspects/fx/pipeline.nix:99-106) — and v1 SOLVED IT BY THUNKING (`scopeContexts = _: { }`, :171), keeping its entity record COMPLETE with raw fields and all. den-hoag re-expressed a constraint on the STATE ACCUMULATOR as a constraint on the RECORD, and solved it by DELETION. Having no accumulator, the constraint has no referent.
THAT IS A SHARPER STATEMENT OF THE AUDIT'S OWN THESIS than 'a v1 shape wearing gen-native naming': the shape was not copied, THE JUSTIFICATION WAS — and it was re-solved against a different object. Worth carrying into P1/P2/P4 as a thing to look for: not 'is this v1's shape' but 'is this v1's REASON, applied to something else'.

### 9 — 2026-07-28T21:40:45 · Jason Bowman

★★ WHERE THIS STANDS RIGHT NOW — written immediately before a compaction. Read this first after a cold start,
then `bd show den-hoag-4kh` for the structural audit and refactor order.

IN FLIGHT AS OF THIS COMMENT — ONE AGENT, `p1-impl`, WRITING TO `lib/`:
Implementing P1 (the policy record) against specs/2026-07-28-policy-record-primitive-design.md (papers
`5ecf52e`, md5 4c89a0b4…, core 229 lines a5f10908…). ★ IT HAS TWO BLOCKING PRECONDITIONS AND MAY STOP ON
EITHER — (1) measure real-context emissions of the 36 probe-classified rows before migrating; if any policy
genuinely spans strata, registration-time rejection turns a silent fan into a loud abort and that is a design
decision, not the implementer's; (2) re-derive C9 independently rather than inheriting the spec's self-check.
★ IF THE TREE IS DIRTY AT COLD START, THAT IS THIS AGENT'S WORK — do not assume it is abandoned; check
`git status` against the acceptance below before discarding anything.

REPO STATE AT WRITING: den-hoag HEAD `c42df53`, tree clean before p1-impl started. papers HEAD `69171f1`,
everything pushed. Nothing is held unpushed.

NEXT ACTIONS, IN ORDER:
 1. Land p1-impl. Acceptance: ci 1946/1946 and parity 71/71 both exit 0 — ★ but a RED IS A QUESTION, NOT A
    VERDICT, because assertions encoding the defect SHOULD fail; six legs of `ci/tests/policy-record.nix`,
    where LEG 5 is legs 2 AND 4 green in the same run (no 2-valued encoding satisfies both) and LEG 3 is
    STRUCTURAL (no node's rule list contains a rule named `q`) — the only leg a gateSuppression-style
    implementation fails.
 2. ★ P4 IS SPEC'D AND QUEUED, NOT FORGOTTEN — specs/2026-07-28-route-contribution-design.md (papers
    `69171f1`, md5 f0e47045…, core 209 lines 0d8f5889…). Its implementation was DELIBERATELY NOT DISPATCHED
    because it also writes `lib/attributes/` and p1-impl is the sole writer there. DISPATCH IT AS SOON AS P1
    LANDS; it is independent of P1 in substance.
 3. P2 (node record gets a `{ decls; meta }` slot) — dissolves a `removeAttrs` maintained in four places.
 4. P3 (entity record derives from schema) — ★ ITS BLOCKER CHANGED. `excludedType` is ANSWERED (den-hoag-4kh.49:
    NOT load-bearing, and it has not dropped fields since 77cb3c8 — it partitions transport). P3's real
    content is whether the field set should keep coming from a PARALLEL nixpkgs-lib EVAL of the registry
    rather than from `den.schema` directly. And den-hoag-9xo.49's defect B (`aspect` is deliberately
    undeclared, registry.nix:34-38) NEEDS A DECISION, not a sentinel.
 5. P5 (entry surface) LAST — six causes converge there. ★ EXCEPT `den.systems` (den-hoag-9xo.55 item 1),
    which is a missing SURFACE DECLARATION rather than a resolution defect and blocks the cheapest ladder
    rung; worth taking out of order IF it is genuinely just a declaration.

★ WHAT P1 DISSOLVES BEYOND ITS OWN BEAD, so nobody works these separately: the probe-sentinel class
(den-hoag-9xo.49 defect A — `environment`/`microvm` fail on a SYNTHETIC probe entity, never on a real host,
because `probeSentinelFields` is a hand-written three-name literal and `tryEval` cannot catch
`attribute 'X' missing`); the 241 spurious firings; the inert `excludes`; den-hoag-4kh.50 (the unconditional
probe); and the hidden predicate inside `fireFeedAt`.

OWNER QUESTIONS: NONE BLOCKING. Four rulings are in force and recorded on this epic — the enrich-projection
fix, Q2 owning-scope, Q3 exempt-stays-reach-sourced, and named-reject posture (explicitly revisable).
Outstanding decisions are downstream of work in flight, not gating it.


### 10 — 2026-07-29T04:14:41 · Jason Bowman

★ SESSION ARC 2026-07-29 — the owner-directive bead **den-hoag-2rh** now carries the full summary: what the topology-first directive produced, the measurements that reorder the roadmap, every bead filed and closed, the method result, the eight new instrument traps and the four C9 hits.
READ ORDER FOR A COLD START, revised: bd show den-hoag-2rh (the directive and its arc) -> this epic -> den-hoag-5ae (the topology as it IS) -> den-hoag-4kh.17 (the register) -> den-hoag-4kh.20 (the trap log) -> den-hoag-4kh.6 (the gate) -> bd ready.
★ THE THREE FACTS THAT CHANGE WHAT TO WORK ON: den-hoag is CUBIC IN CELL COUNT (2.98, two independent implementations, den-hoag-qxz); THE CORPUS CANNOT BUILD A SINGLE TOPLEVEL under den-hoag while it builds fine on den v1 (den-hoag-1kd); and the pure-gen demos CONFIRM the dispatch blowup rather than refuting it (den-hoag-yl3). The critical path is den-hoag-4kh.53.64 — the ops representation — and everything corpus-side sits behind it.

### 11 — 2026-07-29T19:33:04 · Jason Bowman

★★★ SESSION HANDOFF 2026-07-29 — recorded on the epic because the scratchpad is session-scoped and does not survive. A new session should read THIS plus den-hoag-2rh and the memory index; nothing else from that session is durable.

★ THE LENS (owner, after correcting the orchestrator three times) — full statement in memory
feedback_backlog_is_one_defect, one-line form: THE BACKLOG IS NOT A QUEUE. Clustered by failure shape over 243
open beads: 96 = 'something disappears and nothing says so'; 49 = a guard admits what it should refuse; 71 =
order-dependent; 27 = one fact derived two ways; 26 = missing means something, undeclared. Over-match control:
'stylix' -> 2, 'test' -> 87, and 32 carry silent/vanish IN THE TITLE ALONE. The same shape at EVERY layer.
⇒ 'NOTHING HERE' AND 'SOMETHING WAS REMOVED HERE' ARE THE SAME OBSERVATION. Select work by what sharpens the
REPRESENTATION, never by file-disjointness. RED TESTS AND CORPUS FAILURES ARE ACCEPTANCE CRITERIA, NOT WORK ITEMS.
Do not perfect instruments while measured defects sit.

★ FIVE BEADS ARE in_progress WITH LIVE WORKTREE AGENTS whose reports land only in the originating session:
  den-hoag-6p9 + den-hoag-b9k   -> .claude/worktrees/agent-a608b920454800b8c  (1 commit ahead when last checked)
  den-hoag-du2                  -> .claude/worktrees/agent-a5bae2b4a0c2631cb
  den-hoag-4kh.14 + 4kh.15      -> .claude/worktrees/agent-ae38095e5bb8cba2f
IF THE REPORTS WERE LOST: inspect each worktree for commits and re-dispatch from the bead, which carries the
measurement. Do NOT guess what they found. ★ du2's brief asked for a MEASURED answer to 'does the settings cascade
require a topological order, or only determinism plus dedup?' — build a diamond where two incomparable ancestors
set one key to different values. 'NOT ORDER-SENSITIVE' IS A WELCOME ANSWER: then delete the claim from
reverseList's comment rather than manufacturing an order nothing needs. Reverse-POST-order IS topological on a DAG.

★ FOUR SPEC TRACKS PARKED BY OWNER REDIRECT, NOT ABANDONED — all set back to open, all recorded at their last
verdict on their own beads. den-hoag-5ae SHIPPED AND CLOSED. den-hoag-4kh.53.64 ops r9 committed (papers 3b81fdd),
r9 gate 2 blocking RECORDED. den-hoag-9uv CI r9 committed (papers 343a9c5), r9 gate 1 blocking recorded, r10 was
dispatched and STOPPED. den-hoag-qxz witness r8 shipped (papers cde0d56), all 10 findings discharged, NEVER GATED.
Standing ruling if CI resumes, on that bead: STOP ENUMERATING BETTER, DERIVE THE DOMAIN.

★★ TRIAGE YIELD NOT YET APPLIED TO THE GRAPH — 78 beads measured post-migration by two agents on disjoint explicit
id lists. THREE CLOSED (5kt fixed by the migration and verified BY EXECUTION 14/14 EXIT 0; cah fixed upstream; hv9
discharged by c9172dc, an ancestor of the baseline). REMAINING AND UNAPPLIED: 12 COORDINATE DRIFTS and 5 further
RESCOPES. ★ MY HYPOTHESIS THAT THE MIGRATION SLICE WOULD SHOW HIGHER EXPIRY WAS REFUTED — ~3% vs ~4%, statistically
indistinguishable. The migration was surgical; THE REAL YIELD WAS COORDINATE DRIFT, NOT DEATH.
DRIFTS: collections.nix:205 -> :203 (1kd, 3w6, 9xo.61, mu9, 9xo.73) · 1kd errors.nix:190 -> :229 · 4kh.49
query.nix:86 -> :110 and default.nix:2607/2618 -> :2595/:2606 (already wrong pre-migration) · 6jo 32/49 -> 33/50,
STILL EXACTLY 17 UNSCANNED, boundary.nix:374 -> :375 · 1xl edges.nix:175 -> :236 · 4kh.18 default.nix:1074 ->
:1026 · 9xo.33 edges.nix:97 -> :137 · 9xo.40 coordDims GONE, successor default.nix:1947 settingsDims · 4kh.45
default.nix:1111 -> :1061 and staged-resolution.nix:204 -> :201 · h5d default.nix:897 -> :905, line table stale.
★ ALL VERIFIED BY CONTENT, NOT BY OFFSET — offsets move NON-MONOTONICALLY, +0 to +66 AND -2, WITHIN single files.
RESCOPES not yet applied: 4kh.2 (F3 gone by its own named remedy) · 4kh.17 (register entry 4 substantially
retired: four strip lists -> two, both narrowed to ["__edges"]) · 4kh.53.13 (its __root bonus discharged by
76cc601) · 5bp (its deciding question answered by fact) · 4kh.53.52 (G3 dead, G2 and G5 survive in gen-select).
den-hoag-amj GAINS TWO MORE INSTANCES: ci/tests/b2-two-stratum.nix:307-310 and ci/tests/stratification.nix:220-231.

★ GRAPH DEBRIS, unclaimed: 13 stale branches in den-hoag — twelve at ZERO commits ahead of main, and
rejected/isAspectRecord at THREE ahead, named rejected and never resolved. And den-hoag's own codebase-memory
index is STALE (indexed_at 2026-07-28T21:37Z, lib/coordinates.nix = not_tracked), which is why cah's 242-of-320
blast radius could not be re-verified; a reindex is a write and was not done.
