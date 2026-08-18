# den-hoag-4kh.3 — W3: drift and lost-context sweep over the 2026-07 corpus

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.3` |
| status at evacuation | closed |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:24:15Z by Jason Bowman |
| last updated | 2026-07-27T22:12:41Z |
| closed | 2026-07-27T22:12:41Z |
| close reason | SUBSTANTIALLY COMPLETE, one gap declared open.

DONE: triage 218/218 with seven mechanical predicates over all; gap 3 (den v1 symbol scan) CLOSED with zero findings and two false findings averted; gap 1 (lost rationale) CLOSED — all seven priority documents read, 2700/2700 lines on the four largest.

FINDINGS: F1-F10 drift (F8 severe — an arc blocked on a blocker whose three clauses are each false and whose recovery command is unrunnable; F5 the user-facing den.productions option description still advertising the Phase-5a vocabulary; F7 two ci headers stating deleted functions as current law). LR-1 (refined: five sites, basis inferable from the desugar tables but never stated), LR-2 (gen-pipe, no reuse-scan, unrefuted), LR-3, LR-4 (linearization exclusion whose cross-ref goes nowhere), LR-5 (rationale citing a directive to justify its opposite). SB-1..SB-4 standing-bar items, SB-2 the sharpest: a shipped v1 capability unexpressible in the kernel because the corpus does not exercise it.

METHOD RESULT WORTH MORE THAN THE FINDINGS: rationale in this corpus is CENTRALIZED in the 275K decision log, not in the document stating the conclusion. A sweep measuring documents in isolation manufactures findings at scale — caught one step short of filing a false one. Any future rationale pass needs this.

GAP STILL OPEN: the .nix-path citation predicate was abandoned as uninformative (528 paths, 299 absent from den-hoag, because the corpus spans den v1 + nix-config + ~20 gen-* repos so absence from den-hoag proves nothing). The per-repo-scoped replacement was never built, so stale in-repo path citations remain largely unswept beyond F10's line-number drift. Reopen or file separately if that axis matters.

Two cross-references routed into W2 (den-hoag-4kh.2): the kernel forward-routing __marker contradiction, and Law A15's corpus-absence justification. |
| description bytes | 1653 |
| notes bytes | 0 |
| comments | 4 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Sweep 66 specs/2026-07-*.md + 151 plans/2026-07-*.md for design drift, architecture errors and lost context.

LOOK FOR, in order of demonstrated yield:
  - SUPERSEDED DECISIONS STILL STATED AS LIVE. Known instance: REFERENCE.md Chosen #3 says the three resolution layers run sequentially while L214 says they alternate in a joint fixpoint and EXPLICITLY supersedes the sequential rule — the tree matches L214, and Chosen #3 was left standing.
  - THE INVERSE CASE, where the CODE is the stale artifact. Known instance: lib/production-guard.nix:11 states there is NO den.productions user surface yet, while lib/default.nix:656 declares it. Do not assume the document is always the wrong side.
  - DESIGNS WHOSE RATIONALE WAS LOST — a decision recorded with its conclusion but not its reason, which is what makes it get re-litigated.
  - CLAIMS INVERTED. Known instance: the semilattice-set discipline is documented as reserved-but-REJECTED-at-registration; it is shipped and witnessed in two ci tests.

DEPENDS ON den-hoag-9w8 for cheapness, not for correctness: the corpus reorganization manifest already classifies all 359 documents by subject, so a subject-scoped sweep is far cheaper than a flat one. It can proceed without it at higher cost.

OVERLAPS den-hoag-deb (orphaned pre-beads work). Coordinate: deb finds work that was SCOPED and never tracked; W3 finds statements that are WRONG. A document can be both.

OUTPUT: findings classified as (a) document wrong, (b) design intentionally changed, (c) genuinely unimplemented — with the (a)-vs-(b) ambiguities named rather than guessed, since that distinction needs intent no measurement recovers.

## Comments (4)

### 1 — 2026-07-27T21:55:00 · Jason Bowman

W3 DRIFT SWEEP — PARTIAL, honestly declared (independent fresh context, 2026-07-27). Read-only.
Corpus 66 specs + 152 plans = 218 (the bead said 151 plans; actual glob is 152).

★★ F8 — HIGHEST SEVERITY. AN ARC WAS BLOCKED ON A BLOCKER THAT DOES NOT EXIST.
plans/2026-07-21-P5b-claim-provide-grounding-and-blockers.md:11 "Blocker 1 — the design target is off-disk"
claims the two design specs "were NEVER COMMITTED — only STASHED @903508b" in nix-config, with only a resume
summary surviving. ALL THREE CLAUSES ARE FALSE:
  - COMMITTED: c3bd664 (2026-06-13) added specs/2026-06-13-claim-provide-engine-design.md; 2a02b45 added
    specs/2026-06-13-network-fabric-quirk-design.md — both in papers/den-architecture.
  - 903508b IS A COMMIT IN papers/den-architecture (2026-07-05, "stash updates") that DELETED both (173 + 272
    lines). Not a git stash, and NOT in nix-config — `git -C nix-config cat-file -t 903508b` returns
    "Not a valid object name". THE DOC'S OWN RECOVERY COMMAND IS UNRUNNABLE.
  - BOTH FULL SPECS SURVIVE ON DISK at ~/Documents/papers/nix-config-architecture/specs/ — 173 and 272 lines,
    exactly the deleted counts.
F1 shows the work shipped anyway, but the document still misdirects anyone who reads it.

CAT 1 — SUPERSEDED-BUT-LIVE:
 F1 (severe) P5b grounding doc :3 says "PAUSED — blocked on owner. design not started". IT SHIPPED:
   concern-productions.nix:183 claimEdgesOf · default.nix:2125 productionClaimEdges ·
   lib/attributes/claim-accessor.nix (the "net-new handle" the design said does NOT exist yet) · 7 suites
   ci/tests/claim-{pool,provider,dedup,negation,route-desugar,payload-projection,provide-witness}.nix. (a).
 F2 specs/2026-07-21-…-phase5b-claim-provide-design.md SUPERSEDES ITSELF IN THREE PLACES, none flagged at the
   head — :3 "DRAFT, pre adversarial-review" vs :62 "★ REVISION (post adversarial design-review)"; :19-27
   resolves GAP-3 via reference{neededBy} while :68 says DROP it. TREE MATCHES :68 (queryReverse 0 in lib/;
   transpose 53 lib/ + 20 ci/). Trailing Q1-Q5 still live though :62 answers Q1/Q2/Q3/Q5. Same shape as the
   seeded REFERENCE.md Chosen #3 instance. (a).
 F3 plans/2026-07-24-a4-bucket-retirement-plan.md:3 "SHIPPED @ cf5c9c3" — cf5c9c3 RESOLVES IN NO REPO
   (den-hoag + every ~/Documents/repos/sini/*), cited 8x in that doc. route-through-board.md:19 already
   records it as "local, orphaned/superseded"; the plan was left standing. CONTROL: 34/41 corpus SHAs resolve
   in den-hoag, 6 more in gen-aspects/gen-graph — only this one resolves nowhere. (a).
 F4 three superseded resume docs carry NO forward banner while a later doc supersedes them — the cold-start
   hazard, since resume docs are read FIRST. 12 of 15 supersession targets DO carry a banner, so the
   convention exists and these three break it.

CAT 2 — THE CODE IS THE STALE ARTIFACT:
 F5 (severe) lib/default.nix:659 — the USER-FACING den.productions option `description` still says
   "LOWER-ONLY (emit = attr, mode = all, from ∈ { query, pool })". Shipped vocabulary
   (concern-productions.nix:50-59) is supportedEmit { attr; edges; nodes } and supportedFromKinds
   { query; pool; reverse-query }. Same staleness at default.nix:652 and :1404. THIS IS THE OPTION'S OWN
   DOCUMENTATION SURFACE, not a comment.
 F6 (control) the seeded instance reproduced — production-guard.nix:11 denies a surface default.nix:656
   declares. Method confirmed live.
 F7 deliveryModulesAt and classModulesAt have ZERO definitions in the tree, yet two ci headers state them as
   current law (delivery-chain.nix:2, terminal-delivery-consumption.nix:2). delivery-chain.nix:212
   contradicts its own :2, and output-modules.nix:763 agrees they are DELETED. classSubtreeAt is alive
   (output-modules.nix:192).

CAT 5 — CITATIONS: F9 four dangling doc citations (control 157/161 resolve): the coverage-matrix and
route-through-board files moved into STATUS/ at cbf3996 and are still cited by old paths from five sites, one
citing specific line numbers that will not survive the move; plus the two 2026-06-13 specs now under
papers/nix-config-architecture/. F10 line-number drift in the P5b doc (edgesForRoot cited :647, actual :833;
settingsBindingAt cited :757, actual :992) — the bare basename is fine, the line numbers are not.

NEGATIVE RESULTS, each with a control, recorded so they are not re-run: all 22 real bead IDs cited in the
corpus resolve (the four known bead-citation errors live INSIDE beads, not in corpus docs); the 98-line
absence-claims sweep found every symbol-absence claim correctly scoped to v1 rather than den-hoag;
materializeEquiv documented DROPPED and the tree agrees; den.collections genuinely 0/0.

★ THREE EXPLICIT COVERAGE GAPS — this is a PARTIAL sweep and says so:
 1. CATEGORY 4 (LOST RATIONALE) IS EFFECTIVELY UNSWEPT — the one category no mechanical predicate reaches;
    it needs reading a decision and judging whether its WHY survived. Reported as ZERO COVERAGE, not zero
    findings.
 2. The .nix-path predicate was ABANDONED as uninformative (528 paths, 299 absent from den-hoag) because the
    corpus spans den v1, nix-config and ~20 gen-* repos, so absence from den-hoag proves nothing. The
    per-repo-scoped replacement was not built; stale in-repo path citations remain largely unswept beyond F10.
 3. Symbol-absence scanning covered ~/Documents/repos/sini/* ONLY — den v1 was NOT scanned, so byAttachment,
    classifyAllKeysAt, funnyNames, restoreUnregistered, scopeRootIds, siblingBuckets are UNRESOLVED, NOT
    CLEARED. ★ ORCHESTRATOR NOTE: the agent looked for den v1 at ~/Documents/repos/den, which DOES NOT EXIST.
    v1 is at ~/Documents/repos/denful/den. This gap is cheaply closeable.
 Triaged 218/218 with mechanical predicates over all (161 citation targets, 66 bead-ID candidates, 528 .nix
 paths, 41 SHAs, 144 supersession lines, 98 absence claims, 117 shipped-claim identifiers). DEEP-READ: 7.

(a)-vs-(b) AMBIGUITIES NEEDING INTENT: F5 — stale doc-string, or a deliberate public/internal split holding
the PUBLIC surface at Phase-5a? No split found; leans (a), not provable. F4 — resume docs may be an
append-only session log by design. F7 — a test header may legitimately describe the law it replaced. F3 —
re-stamp vs archive is a doc-lifecycle call, not measurable.

STANDING-BAR NOTE: in the 7 deep-read documents, no design was justified by "v1 did it this way" or "this is
the smaller change". A 7-document sample, not a corpus result.

### 2 — 2026-07-27T22:00:26 · Jason Bowman

GAP 3 CLOSED — den v1 symbol scan. ZERO new findings. All six symbols resolve. TWO WOULD HAVE BEEN FALSE
FINDINGS had they been reported from the earlier sini/*-only scan.

SETUP: v1 at ~/Documents/repos/denful/den. BOTH revs scanned — working HEAD cdc95cee (2026-07-17) and the
parity pin 11866c16 (2026-06-25) — via `git grep <rev>`, which reads the commit so .worktrees/ is out of scope
by construction. The filter warning was real: naive find = 2531 .nix files, filtered = 509.

★ THE CONTROL FAILED FIRST, AND THAT WAS REPORTED RATHER THAN HIDDEN. classSubtreeAt and mkDen were declared
as positive controls from CORPUS STATEMENTS about v1; BOTH RETURNED 0, so the run was discarded as unreadable.
Valid controls were then read directly out of nix/denTest.nix BEFORE searching (so the control is not the
search finding itself): evalDen (:48) 2 hits/1 file · denTest (:12) 1323/240 · testModule (:63) 2/1 · negative
zzzNoSuchSymbolAnywhereV1 → 0.
★★ ASIDE WORTH KEEPING, corpus-wide: classSubtreeAt and mkDen ARE NOT V1 IDENTIFIERS, despite the corpus
repeatedly writing things like "v1's classSubtreeAt down-fold". They are DEN-HOAG names for v1 CONCEPTS.
classSubtreeAt = 93 hits in den-hoag, 0 in v1 at both revs. Anyone treating a den-hoag name as a v1 symbol
will build an unreadable control, exactly as happened here.

RESULTS, identical at both revs: funnyNames 125 hits/24 files PRESENT-IN-V1 · byAttachment 0 · classifyAllKeysAt
0 · restoreUnregistered 0 · scopeRootIds 0 · siblingBuckets 0.

DISPOSITIONS — every one is either present in v1, retired at a named den-hoag commit the docs correctly
describe, or a non-symbol. NO ABSENT-EVERYWHERE cases:
 - funnyNames PRESENT in v1; every corpus claim about it is correctly scoped to v1/denTest ⇒ NOT a finding.
 - restoreUnregistered / classifyAllKeysAt — absent from v1, but they EXISTED IN DEN-HOAG and were retired at
   named commits (fc4a7f0 "dissolve raw discriminator + validation apparatus"; also 664da11 "retire the eager
   per-class content bucket for direct/reachable class-slice queries"). The citing documents are the
   DISSOLUTION'S OWN DESIGN and its input catalog, describing the before-state they existed to remove ⇒
   (b) DESIGN INTENTIONALLY CHANGED, not a document defect.
 - siblingBuckets — the doc is exactly right: "G-1 siblingBuckets → gen-scope children — LANDED @08e8e9a" and
   it was retired at precisely that commit ⇒ NOT a finding.
 - scopeRootIds — a row label in a measurement table (a probe-exported field), never claimed as tree code.
 - byAttachment — the doc ASSERTS its absence ("No byAttachment map … were materialized") and the tree agrees.

★★ NEW TRAP — DEN-HOAG'S OWN WORKTREES RESURRECT RETIRED SYMBOLS AT THE EXACT CITED LINE NUMBERS.
.worktrees/gen-lsp-integration/ and .worktrees/lsp-m1/ still carry the PRE-DISSOLUTION
lib/compat/flake-module.nix with mkRawTotality at :163 and restoreUnregisteredTree at :346 — the same line
numbers the audit catalog cites. AN UNFILTERED GREP OF DEN-HOAG "CONFIRMS" A RETIRED SYMBOL AS LIVE, at a
plausible-looking location. Always exclude .worktrees/ in den-hoag, not only in den v1.

SELF-CORRECTION from the agent: its earlier report cited "gen-aspects/flake-module.nix:163-346". That file
does not exist — gen-aspects has no flake-module* at all. The cited file is den-hoag's
lib/compat/flake-module.nix.

★ CROSS-REFERENCE TO W2 (den-hoag-4kh.2), SAME FILE: classifyAllKeysAt was retired by name, but ITS BEHAVIOUR
SURVIVES UNNAMED — lib/attributes/class-modules.nix:192-194 still force-walks every content key via
`builtins.seq content.${k}`, inline, under no function name. That is the same file as W2's F1 (the
non-confluent reroute fold at :130-166 and classSliceKeyedBaseAt at :187-190). A named retirement whose shape
persists inline is precisely the SHIPPED-RENAMED-ONLY class W1 hunted at rung granularity and found empty —
it exists here at SUB-FUNCTION granularity, which no rung-level sweep would catch.

### 3 — 2026-07-27T22:03:13 · Jason Bowman

GAP 1 (LOST RATIONALE) — PARTIAL: 2 of 7 read in full, 1 at its decision section, 4 unread (~2700 of 3177
lines). 3 findings, plus a METHOD CORRECTION that matters more.

★★ THE METHOD CORRECTION — RATIONALE IS CENTRALIZED IN THE DECISION LOG, NOT IN THE DOCUMENT.
The agent's first instinct was that gen-duplication-audit's D-1 had been resolved with no recorded reason.
THAT WOULD HAVE BEEN A FALSE FINDING. The rationale is fully recorded — in
specs/2026-07-22-wsb-autonomous-decision-log.md: :183 DL-HS-11 (root cause), :249 the owner-banked fork,
:251 DL-HS-20 RESOLUTION (owner) Option A with the owner's verbatim reason ("Typo detection is a real value
add and user ask — if that's the only path this is used for, then that's an acceptable trade"), :197 the
honest dissolution verdict.
⇒ ANY LOST-RATIONALE SWEEP THAT MEASURES A DOCUMENT IN ISOLATION WILL MANUFACTURE FINDINGS AT SCALE. The
275K decision log is where the why lives. Whoever takes the remaining 4 documents needs this or the yield is
mostly noise.

FINDINGS — specs/2026-07-05-den-hoag-component-roadmap.md §1 "Decisions (owner, 2026-07-05)". This list is the
right place to look because it sets its own convention: several entries carry their reason inline (#10 "External
users pushed back on the string grammar…"; #11 "research-only, backgrounded…"). THREE ENTRIES BREAK IT.
 LR-1 (STRONGEST) :25 decision #9 — "Legacy (forwards, provides): included in the compat shim as self-contained
   modules tagged legacy — removable without touching the rest; NO NATIVE DEN-HOAG EQUIVALENTS." No why. This
   decides that two v1 USER surfaces get no native model at all — a load-bearing architectural exclusion.
   TREE STATUS: CURRENT-TRUE and faithfully implemented (lib/compat/legacy/provides.nix:1-11 self-contained and
   severable with sentinel errors.legacyProvidesAbsent, Law C5; forwards.nix alongside). So NOT drift — a
   CORRECT decision whose REASON IS UNRECORDED. Re-litigation risk high: "why is provides not native?" is
   exactly the question a future reader asks. (One suspicion checked and dropped: lib/compat/provides-nav.nix
   sits outside legacy/ but is the den._/den.provides root-nav registry, a different concern — not a
   contradiction.)
 LR-2 :28 decision #12 — "A sixth L2 contract lib (gen-pipe) owns the algebra." The conclusion is BUILD A NEW
   LIBRARY with no reason why the algebra could not extend an existing lib. Against this project's standing
   reuse-scan discipline — which exists because it has built-what-already-existed more than once — a new-lib
   decision without its reuse rationale is the re-litigation shape exactly.
 LR-3 (weaker) :22 decision #6 — graph products as the primitive; the parenthetical lists CONSEQUENCES
   (cartesian/tensor/lexicographic, projections, quotients) rather than the reason for choosing products. A
   theory-named primitive carries some implicit justification, so ranked below LR-1/LR-2.

NEGATIVE RESULTS — TWO DOCUMENTS ARE RATIONALE-COMPLETE, and they are the pattern to hold the corpus to:
 specs/2026-07-23-dropped-items-audit.md (74L, full) — every park carries a decision-log ID AND its basis
   (DL-RES-1-CORRECTION:87-88, DL-RES-3:80, DL-NM-1/2, DL-CAP-1, DL-RES-2). ZERO lost rationale.
 specs/2026-07-23-gen-duplication-audit.md (40L, full) — every verdict J-1..J-6 states WHY it is
   justified-compat rather than merely that it is. ZERO lost rationale.

BONUS VERIFICATION (found while reading, not lost-rationale):
 - Dropped-items items 3 and 4 are DONE (task keys gone from has-aspect-verbs.nix and resolve-verbs.nix;
   capture stub reworded at flake.nix:219).
 - ★ RESIDUAL THE AUDIT DID NOT NAME: flake.nix:218 `home = stub "lib.home" "the home-entity surface — not yet
   available"` STILL CARRIES THE EXACT PHRASING DL-CAP-1 REJECTED. The discipline was applied to the named
   instance and skipped its immediate neighbour.
 - ★★ D-1 WAS RESOLVED BY DISSOLUTION, NOT BY EITHER FIX THE AUDIT PRESCRIBED. Both discriminator copies are
   gone (recognizedSubKey/isCandidate/looksNested/v1GroundedOnlySpellings all 0 in lib/; compile.nix:251 reads
   "The FORMER looksLikeClassContent"); lib/compat/aspect-classify.nix was never created. BUT THE AUDIT'S ROOT
   CAUSE IS STILL OPEN: gen-aspects exports no isNestedKey/classifyAspectKey/unregisteredKeys — CONTROL on the
   same grep: flatten at gen-aspects/lib/default.nix:20, canTake at :37, so the predicate reaches the file. The
   audit called the upstream predicate "the clean upstream fix that dissolves the D-1 duplication class AT THE
   SOURCE". THE SYMPTOM IS GONE; THE SOURCE GAP THAT PRODUCED IT IS NOT, SO THE CLASS CAN RECUR.
 - D-3 still open — lib/receivers.nix:181 dedupNodes remains a hand-rolled foldl', matching its cosmetic/low
   ranking.
 - den.features IS present (27 hits) — a post-audit ship, not a contradiction of the audit's scoping.

COVERAGE: full — dropped-items (74L), gen-duplication (40L). Partial — component-roadmap (363L, §1 + structure).
UNREAD — effects-runtime-audit (322L), corpus-eval-sweep (202L), compat-parity-component-spec (698L),
assembly-component-spec (1478L). The four unread include the two largest; the assembly spec (80 decision-ish
markers) is the densest remaining target. A STRUCTURAL MARKER SCAN OVER THE TWO COMPONENT SPECS CAME BACK
NEARLY EMPTY (one hit across 1061 lines) — decisions there are NOT flagged by heading and need READING, not
grepping. The agent stopped rather than claiming a scan.

CAVEAT CARRIED FORWARD: it used `git log -S` (TRAP 4, blind to body rewrites). Where it RETURNED commits the
deletions are real and the conclusions hold; where it returned NOTHING (scopeRootIds, byAttachment) it did NOT
rest on it — both were settled by reading the citing context. `git log -G` is the stronger instrument for any
re-run of that axis.

### 4 — 2026-07-27T22:12:04 · Jason Bowman

GAP 1 CLOSED — the four unread priority documents, ALL READ IN FULL (2700/2700 lines). Read-only.
Decision log (845L) + STATUS/ searched by ~12 predicates. THE METHOD HAS A POSITIVE CONTROL: it FOUND the
reason in four cases (listed below), so the absence claims are not blind by construction.

★★ LR-4 — STRONGEST NEW. An architectural exclusion whose cross-reference goes nowhere.
assembly-component-spec.md:74 "No per-aspect or per-address linearization override (single fleet-global
linearization in v1; SEE §9)." WHERE THE WHY WAS SOUGHT AND NOT FOUND: the spec's own §9 Open Questions Q1-Q6
(Q4 is per-declaration STRENGTH, orthogonal, and says so); roadmap §12 open-Q 3 (that is the DECLARATION
SURFACE, which §2.7 resolves — a different question); roadmap §5/§9; the DECISION LOG (ZERO `lineariz` hits);
STATUS/ (zero); corpus-wide grep = only this line plus the roadmap's layer-derivation paragraph. §2.7's own
reason ("declaring it costs one list — not the exponential subset lattice", :531) justifies the DIMS-LIST
SHAPE, not the PROHIBITION of per-aspect override. CURRENT-TRUE: lib/linearization.nix:2 one fleet-global
den.linearization.dims; lib/errors.nix:180-188 enforces every dim exactly once. Re-litigation risk HIGH — the
reader who asks "why can't one aspect rank host above env?" follows a cross-ref that goes nowhere.

★ LR-1 REFINED — TEMPER THE PRIOR FINDING. The legacy exclusion is stated FIVE TIMES, not once: roadmap :25
(#9), assembly :69-70 and :1419-1420 (§8 table), compat :26 and :423, plus plans/2026-07-07-den-compat.md:629.
No site states a basis. BUT A PARTIAL REASON IS RECOVERABLE and LR-1 should say so: assembly:189 annotates
neededBy = sel.kind den.schema.user with "(replaces v1 provides.to-users)", and compat §2.5/§2.6 show both
surfaces desugaring wholly into native concern vocabulary (provides → neededBy under r2 §B4a; forwards tier-1
→ reroute/deliver). THE IMPLIED BASIS IS SUBSUMPTION — a native duplicate would be redundant vocabulary.
⇒ REVISED VERDICT: not "reason absent everywhere" but "REASON NEVER STATED AS THE DECISION'S BASIS, ONLY
INFERABLE FROM THE DESUGAR TABLES." Searched for an explicit statement in the decision log (every `provides`
hit is a compat IMPLEMENTATION rung — 4c/G1/M2/BANK-2 — none states the exclusion's basis),
STATUS/compat-feature-register.md:37, roadmap §10/§12, r2.
★★ CURRENT-TRUTH NUANCE THAT MATTERS FOR W2: the SURFACE claim holds (lib/compat/legacy/{provides,forwards}.nix;
kernel `provides` hits are the unrelated den.derived.provides resolution-product face). THE FORWARD CROSSING IS
KERNEL: lib/attributes/output-modules.nix:623-634 builds forward class-reroute contributions from
meta.__forward specs stamped COMPAT-SIDE at lib/compat/bridge.nix:133. So "no native den-hoag equivalent" is
TRUE OF THE USER SURFACE AND FALSE OF THE MECHANISM — the kernel carries forward routing driven by a
compat-authored __ marker.

★★ LR-5 — FAILING RATIONALE: a stated reason that its own citation REFUTES.
assembly:708-711 (§2.9 Graduation): "They graduate to gen-aspects … only if a second consumer appears — until
then, keeping them as den-hoag wiring AVOIDS OVER-GENERALIZING A ONE-USE SUGAR (roadmap anti-YAGNI)."
The roadmap's ONLY YAGNI statement is decision #5 at roadmap:21 — "GENERALITY OVER YAGNI for this design:
maximize expressiveness". Every sibling spec reads it that way (gen-demand :22, gen-edge :24, gen-pipe :6,
l2-composition-plane :17 "explicitly REJECT YAGNI"). The owner bar is on the generality side (decision log :3,
:341). SO :711 CITES THE DIRECTIVE TO JUSTIFY THE OPPOSITE OF WHAT THE DIRECTIVE SAYS. Not lost rationale —
WRONG-WAY-ROUND rationale, which re-litigates the moment anyone follows the citation.

STANDING-BAR ITEMS (reported separately from LR, per the bar):
 SB-1 CORPUS-PRESENCE AS THE DECIDING CRITERION, SYSTEMATICALLY. Assembly Open Questions 1/2/3/5 all defer to
   the corpus (:1441 "Deciding data: den-compat migration of nix-config's nixidy plane"; :1447 "the fleet
   corpus should decide"; :1451 "If the fleet corpus never uses non-tree slices, consider restricting `at`";
   :1463). Compat mirrors it (:35, :178, Open-Q 2 :432 gates forward tier-2 on a corpus census). This is the
   criterion the current bar DEMOTES. Both docs are 2026-07-05 and predate the demotion, but they are STILL
   LIVE SPECS stating corpus-presence as the rule.
 SB-2 A KERNEL TRAVERSAL JUSTIFIED BY V1-SHAPE **AND** CORPUS-ABSENCE — both failing forms in one sentence.
   assembly:1109-1113 (Law A15 refinement): classSubtreeAt is a blind scope.descendants walk — "This is v1's
   non-isolated defaultFoldEdges nesting fold (Corollary 1) rendered where a NO-ISOLATED-KIND CORPUS collapses
   the isolation-aware subtree to the blind descendants walk". Its consequence is ledgered honestly (:1121-1125
   isolation ceiling → compat R22 :637-644, errors.isolatedKindUnsupported) — BUT A CAUGHT ERROR IS NOT A
   DESIGN, and v1 SHIPS isolation (modules/options.nix:85-88). A SHIPPED V1 CAPABILITY IS UNEXPRESSIBLE IN THE
   KERNEL BECAUSE THE CORPUS DOES NOT EXERCISE IT.
 SB-3 assembly:644-655 — §2.9 calls its attachment-scope definition "load-bearing", then narrows it to the
   static den.include surface, deferring forward-expansion/neededBy and edge/inject introduction, self-labelled
   "an implementation-complexity deferral, not a formal A9 stratification violation". Honest and well-flagged;
   reported because the bar names the class.
 SB-4 FRAME ONLY. corpus-eval-sweep.md:1 titles itself "the authoritative ship queue" and ranks work by
   hosts-gated (8/9 vs 1/9) — the criterion demoted to a validation SYMPTOM. The measurements themselves are
   exemplary; it is the ORDERING CLAIM that carries the old frame.

RATIONALE-COMPLETE DOCUMENTS (reported per the brief — a sweep that only emits defects cannot tell a clean
document from an unread one):
 - 2026-07-24-den-hoag-effects-runtime-audit.md — THE STRONGEST IN THE CORPUS. Every finding carries its shape
   against a named rubric (V1-V7), the v1 echo, the pure-gen replacement WITH THEORY CITATION (A1 →
   gen-resolve `reference`, Hedin 2000 RAG) and a LOC bound. §2 states why prior audits were insufficient. §8
   is an explicit HONESTY LEDGER — 33 refutations named, five unaudited regions named. §6's six gen gaps each
   state the contract AND what forced the hand-roll. Even the funnel is reported (62 raw → 25 confirmed + 2
   hand-adjudicated + 33 refuted; 3 verifier agents errored, both orphaned findings recovered by hand in §7).
 - 2026-07-24-corpus-eval-sweep.md — every claim is a measurement with its command, pin and control; the
   byte-identical 57,885-byte trace across 8 hosts as single-root-cause evidence; a method note on why a bare-
   path override would have used the wrong tree.
 - 2026-07-05-den-compat-parity-component-spec.md — NEAR-COMPLETE; only the shared LR-1 restatement lacks a
   basis. Model entry :166 ("Resolution-time, DELIBERATELY … compile-time would change v1 semantics … so the
   predicate form is LOAD-BEARING, not an implementation convenience"). R1-R23 each carry v1 file:line at the
   frozen pin, provenance arc, shipped commit. R14 :502-514 records its own misclassification AND why.
 - assembly spec is rationale-DENSE though not complete — credit :328-330 (the hola-lab O(N^2) finding that
   killed sentinel discovery), :245-258, :808-814 ("Rationale — measured context, not a gate"), :1147-1152
   ("killed on STRUCTURAL grounds, not preference"), §6 (every citation labelled realized vs informed-by).

NEGATIVE RESULTS — REASONS SOUGHT AND FOUND (the method's positive controls; do not re-run): the dropped
semilattice framing (reasoned in r2 :604/:887/:1120 — the r1 framing "invited an implementer to fix
determinism with a commutative+idempotent combine"); §2.9's v1 constraints 1-4 (roadmap :294); compat:267
sourceVia="unresolved" permanent-and-correct (plans/2026-06-12-delivery-edge-unification.md:627); effects-audit
A6 producerConfigs (decision log :353 — verified NOT an eager accumulator). Plus assembly:736 dispatchStep
retirement, reasoned inline PLUS a decision-#25 pointer — the centralized-rationale convention working.

LR-2 (gen-pipe as a sixth L2 lib, no recorded reuse-scan) STANDS UNREFUTED from this side: assembly §5
:1313-1315 merely lists it among "the five new L2 contract libs"; roadmap §7 describes what it IS with no
reuse-scan.
