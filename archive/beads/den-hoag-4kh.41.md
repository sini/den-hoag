# den-hoag-4kh.41 — [kernel] P0 LIVE: declare.inject/declare.reroute DO NOT REACH THE BUILT SYSTEM — anchor by expression 'terminalModulesAt = id: class: projectClass id class', NOT by applyInjectReroute which no longer exists

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.41` |
| status at evacuation | open |
| priority | P0 |
| type | bug |
| labels | `arch-validated` |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T06:06:27Z by Jason Bowman |
| last updated | 2026-08-04T19:55:36Z |
| description bytes | 201244 |
| notes bytes | 0 |
| comments | 36 |
| dependencies | `None` (None), `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ BASELINE CORRECTION 2026-08-02 at 9311fbd (closure sweep): the suite is now 2287/2287 EXIT 0 with an EMPTY red set (first all-green since e6c8edc). The gate-round records below cite the historical red window ("ci 2071/2093 EXIT 1, red set 22 BYTE-IDENTICAL to baseline", twice) — those figures are HISTORY, not a diffable baseline. Any future gate re-baselines against the green suite; a non-empty diff against "red set 22" is not evidence of a regression.

★★ MEASURED KERNEL DEFECT, RE-ANCHORED AT HEAD b0f40de (2026-07-30, read-only scout + orchestrator
re-verification of every anchor below). `declare.inject` AND `declare.reroute` ARE PUBLIC VERBS THAT DO NOT
REACH THE BUILT SYSTEM. ★ THE BLOCKING EDGE TO den-hoag-4kh.16 IS DROPPED — see WHY IT IS NOW ACTIONABLE.

★ ANCHOR BY EXPRESSION, NEVER BY LINE. Every line number in the original body had decayed; the corrections
are recorded at the foot of this body so a future reader does not re-derive them.

════ MECHANISM: TWO CONSUMERS OF CLASS CONTENT, ONLY ONE APPLIES THE ACTS ════

CONSUMER A — APPLIES THE RELOCATION. `graphAccessor.contentsOf` (lib/attributes/output-modules.nix) calls
`classSubtreeAt id channel`, whose settling expression is
    classSubtreeSeeds = id: ch: dedupByKey (e: e.sharedFoldKey or null) (
      prelude.concatMap (nid: (classSeedsAt nid).${ch} or [ ]) ([ id ] ++ scope.descendants result id) );
with `classSeedsAt = id: result.get id "class-seeds"`. That demands the `class-seeds` attribute
(lib/attributes/class-modules.nix), which computes `frame = frameAt id acts`, filters
`injects = builtins.filter (a: a.__action == "inject") acts`, and answers through `srcOrder`/`preimageOf`.
SINKS: `edgesForRoot` -> `outputFor` + `traceFor` -> the parity oracle (lib/compat/parity/oracle.nix) and
compat resolve-verbs / `den.graph.trace` (lib/compat/resolve-verbs.nix).

CONSUMER B — DOES NOT. `projectClassScoped`:
    prelude.concatMap (n: builtins.seq (assertKeysRegistered exempt n) (
      map (e: { inherit (e) module; scope = n.scope or id; }) (classSliceOf exempt n class))) reach
    ++ map atProjectingScope (routeRemapFor exempt id class)
    ++ map atProjectingScope (forwardModulesFor reach exempt class);
`classSliceOf` reads `content.${class}` DIRECTLY — no frame, no preimage, no injects. Then `projectClass`,
then `terminalModulesAt = id: class: projectClass id class`.
SINKS: `contentIdsOf`, `deltaOf`, `hostModules` -> lib/output/terminal.nix -> THE BUILT DERIVATION.

⇒ TWO QUERIES, NOT ONE. A user declares a relocation, every introspection surface agrees it happened, and the
actual NixOS configuration does not contain it.

★ SHARPENING NOT IN THE ORIGINAL BODY: THE TWO RELOCATION FAMILIES ARE TREATED ASYMMETRICALLY.
`routeRemapFor` / `forwardModulesFor` — the deliver/route family — DO read the projecting scope's
declarations and DO reach the terminal, in the very same expression that drops inject/reroute. Sibling
mechanisms, opposite treatment, and NO comment in the tree reconciles them. Any remedy must say why the two
families differ or make them agree.

════ POSITIVE CONTROLS — facts about the CODE, not about the instrument ════

ACT CONSUMPTION SITES: exactly TWO, both in lib/attributes/class-modules.nix — the `__action == "reroute"`
filter inside `relocationsOf`, and the `__action == "inject"` filter inside `class-seeds.compute`. They are
NOT in one function (the original body said they were, because they were, before the bucket retirement).
CONTROL, same predicate same run: `__action == "<kind>"` matches 9 sites over 5 files and 8 distinct kinds
(spawn x2, reroute, reach-suppress, reach-edge, inject, edge, drop, configure). The predicate finds consumers;
the ABSENCE OF A THIRD IS MEASURED.
DECLARATION ARM: lib/declarations.nix registers both verbs in `groups.resolution`.
`applyInjectReroute` DOES NOT EXIST at HEAD: 0 in lib/, 0 in ci/. CONTROL same run: `classSliceOf` -> 40 over
13 files. ★ REPO-WIDE that symbol still shows 8 hits, ALL in `.beads/beads.jsonl` — a repo-wide grep will
read it as LIVE. Scope any re-verification to lib/ and ci/.
NOT A THIRD PATH: lib/compat/legacy/forwards.nix tier1 desugars to `deliverLib.deliver { from; to; at }`, a
delivery. Three word-sweep false positives were cleared by READING: that file's "reroute-shaped" comment,
bridge.nix's "class-REROUTE" comment, and policy-verbs.nix's "Inject an aspect" (which is `include`).

════ WHY NO GUARD CAUGHT IT, AND WHAT IS ARMED NOW ════

ci/tests/edge-completeness.nix binds
`injectedNixos = builtins.length (denInject.structural.eval.get axonId "class-seeds").nixos`
and asserts it in `test-inject-applied`, expected 1. That reads the `class-seeds` ATTRIBUTE = CONSUMER A =
THE PATH THAT WORKS. The attribute is correct. GENERAL LESSON: WHEN A VALUE HAS TWO CONSUMERS, A TEST OF
EITHER ONE PROVES NOTHING ABOUT THEIR AGREEMENT.

ARMED REDS EXIST and they DO discriminate — ci/tests/projection.nix, three rows added at e987cee over a
native `mkDen` env/host/user fixture with `den.policies.relocate-hm` emitting
`declare.reroute { from = home-manager; to = nixos; }`:
  · `test-anchor-relocation-free-control` — GREEN control, same fleet with the relocation removed.
  · `test-anchor-projectClass-eq-classSubtreeAt-under-relocation` — THE TWO-CONSUMER AGREEMENT ASSERTION,
    over both real constructions on both channels.
  · `test-anchor-projectClass-relocated-content` — pins ABSOLUTE content, so a repair that breaks both sides
    alike passes the agreement row and fails this one.
This is NOT the edge-completeness mistake.
★ TWO LIMITS THE ARMED SET CARRIES: (1) the rows assert over `projectClass`/`classSubtreeAt`, NOT over
`terminalModulesAt`/`contentsOf` — each link is a single-expression alias, so the gap is one hop, but the
rows witness the PROJECTION layer, not the drv. (2) ★ ONLY `reroute` IS ARMED. **THE `inject` HALF HAS NO
ARMED RED.** A remedy landing green against these rows has not been shown to fix inject.
★ No test file in ci/ mentions this bead id; attribution lives only in the e987cee commit message and
den-hoag-akj's close record.

════ CORPUS COST: ZERO — AND THE OBVIOUS GREP CANNOT ESTABLISH IT ════

Corpus reached: ~/Documents/repos/den-configs, 19 configs. `declare.reroute|declare.inject` -> 0 files.
★ THAT IS NOT EVIDENCE. Control same run: `declare.` ANY -> **0 corpus-wide**, while `den.aspects` -> 993
files and `class` -> 106. The instrument reaches the corpus and finds den vocabulary; the predicate COULD NOT
HAVE MATCHED, because the corpus authors no native `declare.*` at all.
SOUND DERIVATION INSTEAD: the only producers of a reroute/inject act are `declare.reroute`/`declare.inject`;
lib/compat/ emits NEITHER (0 hits; CONTROL same run: the same `declare.<verb>` predicate finds 14 other verbs
in lib/compat/ — edge x8, pipe x6, enrich x4, suppress x3, member, drop, delivery, spawn, reach-edge, ...);
and the corpus is a v1-surface corpus. ⇒ P=0 and I=0 FLEET-WIDE HOLDS, on the STRUCTURAL argument, which
independently confirms den-hoag-akj's "the compat/v1 surface cannot author a reroute".
⇒ The defect is LATENT, and the first user of a documented public verb finds it.
COVERAGE LIMIT: there is no `templates/` directory in den-hoag at HEAD; the 13 den templates live elsewhere
and were NOT checked.

════ ★ WHY THIS IS NOW ACTIONABLE — THE BLOCKING EDGE IS DROPPED ════

This bead was blocked by den-hoag-4kh.16. That edge is RETIRED, by mechanism, not by judgement:
(a) 4kh.16's live scope is the binding `classBucketsOf` and its single reader `graphAccessor.channelsOf`.
    `classBucketsOf` is NOT on the divergence path — at HEAD it returns a channel-NAME list
    (`if cn == null then [ ] else builtins.seq (classSubtreeAt id cn) [ cn ]`), forcing `classSubtreeAt`
    only for a classification side effect. The content divergence is `contentsOf`->`classSubtreeAt` versus
    `projectClass`->`classSliceOf`. Repairing this bead need not touch it.
(b) THE REAL BLOCKER WAS A TYPE-LEVEL IMPOSSIBILITY, AND IT IS REFUTED AT HEAD. 4kh.16's 2026-07-29
    verification comment stated the remedy was partly impossible: "OWNING-scope is INEXPRESSIBLE AT THE
    CURRENT TYPE — emit carries no owning scope id, so the query CANNOT ASK." ★ FALSE at HEAD:
    lib/attributes/resolved-aspects.nix `emit` now returns `{ key; content; sharedFoldKey; scope = scopeId; }`
    — verified `scope = scopeId;` present, landed at **1905f1c** ("fix(kernel): bind projected class modules
    at their own scope's pool", den-hoag-hrh, 2026-07-30) FOR AN UNRELATED REASON. output-modules.nix's
    `projectClassScoped` ALREADY READS it (`scope = n.scope or id`). Both remedy arms — owning-scope and
    projecting-scope — are now expressible.

★ THE REMEDY HAS NO LIVE TRACKER. The original body pointed at 4kh.16 for the by-construction fix ("unifies
BOTH consumers onto one query"). 4kh.16 at HEAD is titled and scoped RESIDUE-ONLY and no longer carries that
unification. The unification is an UNSHIPPED DESIGN and therefore a GATE CANDIDATE (den-hoag-4kh.6), not a
bead — it must be specified and pass the gate before it becomes work. Construction over repair still applies:
applying the acts in a second place is a repair that must be re-applied at every future consumer.

★ OWNER RULING STILL REQUIRED IN SUBSTANCE. `declare` IS public — exported at lib/default.nix (re-exported
twice more) and consumed as `denHoag.declare` from ci/ (b1-supportedness.nix, cell-classification.nix, and
others). Making these verbs reach the terminal makes the export behave AS DOCUMENTED, but it is still an
observable change. ★ WHAT HAS CHANGED SINCE THE RULING WAS FIRST REQUESTED: the blast radius is now MEASURED
ZERO on the structural argument above, so the ruling is about the surface contract, not about breaking a live
fleet. The fallback if the ruling is "no" is to keep two disagreeing sources — explicitly NOT recommended.

════ CITATION CORRECTIONS FROM THE 2026-07-30 RE-ANCHOR (recorded so they are not re-derived) ════
· `terminalModulesAt` binds at output-modules.nix :803, not :776. Substance was correct.
· "it never sees `applyInjectReroute`" -> that function does not exist; the correct statement is that
  Consumer B NEVER DEMANDS THE `class-seeds` ATTRIBUTE, where `relocationsOf`/`frameAt`/`srcOrder` and the
  inject filter live.
· the two act-consumption sites are class-modules.nix :139 and :317, not :133/:152, and they sit in two
  DIFFERENT functions.
· lib/declarations.nix :37-40 is prose; registration is `groups.resolution` at :54-55.
· "DO reach ... the compat resolve-verbs" is true only for a NATIVELY declared relocation: compat can READ
  the relocated answer but cannot AUTHOR either verb.
· edge-completeness.nix binds at :217 and asserts at :347-350, not :214.
· `declare` is at lib/default.nix :180 (re-exported :192/:207), NOT :2730 — that region is now the
  `query = queryLib.denQueryOverEdges;` exploratory-surface comment.

PROVENANCE: found 2026-07-28 by the bucket-to-seed-query design agent while establishing the blast radius of
a different change; it was in NO input — not the scope doc, not a bead, not any papers tracker. Re-anchored
and unblocked 2026-07-30 at b0f40de.


════ ★ REMEDY SPEC — GATE ROUND 1 VERDICT: REVISE (2026-07-30) ════
ARTEFACT: papers/den-architecture/specs/2026-07-30-class-content-consumer-unification-spec.md, FROZEN at
md5 `32c1e9af271878aa9abf718409fce86b` (61945 bytes, md5 verified twice by the orchestrator and once by the
gate). S0 MET. Construction: element-granularity — class content becomes a function of (content ELEMENT,
channel) where an element carries its OWNING scope, and Ρ(S) is applied INSIDE one extraction keyed by that
scope, so the raw un-relocated read stops being an exported name.
RUBRIC: C1/C1-a/C2/C5 PASS · C6 FAIL · C7 FAIL · C7-a FAIL · C7-b PASS · C8 pass-on-posture, fail-on-
completeness · C9 PASS (read entry-by-entry with three independent verdicts; the error-message-text trap
checked directly rather than greped).

THREE FINDINGS IN THE CONSTRUCTION — this round does NOT count toward the two-successive-clean-rounds exit:
· F1 ★★★ MEASURED CONTENT LOSS THE DOCUMENT SAYS CANNOT OCCUR. Today `rawSeedsAt`'s injection arm appends
  injections WITHOUT passing `classifyKey`; the design routes injections through the extraction, whose gate
  `isCollectable` requires `(exempt ? class) || classifyKey content.name class == "class"`. An injection at
  an UNREGISTERED channel fails it. PROBED with a control: the design's exact element shape at an
  unregistered channel → length 0; same rendering at a registered channel → length 1. At HEAD
  `test-unregistered-sources-answer` is GREEN delivering `["cB","iX","iY"]` through reroute; under the design
  that row returns `["cB"]`. Not a fixture artefact — production `classifyKey` returns "facet" for an unknown
  category, so the real path drops too. ★ AND THE SPEC'S OWN ACCEPTANCE SET CANNOT CATCH IT: its inject
  fixture injects at a REGISTERED class, so every proposed row is blind to the failure mode the design
  introduces. Also a C6 fail (silent drop, no abort). Not a local edit — the obvious fix (add the channel to
  `exempt`) widens the A1/A2 typo abort for that node's aspect content at the same key.
· F2 ★★ THE C7 IMPOSSIBILITY CLAIM IS FALSE BY EXHIBITION, from the document's own §4.3 definition:
  `classSliceAt` instantiated at `sourceOrderAt = _: c: [ c ]` IS `rawSliceOf exempt e c`. The un-relocated
  answer is a legal argument to the exported extraction; no access to the private binding is needed. The
  obligation is RETYPED, not removed — from "remember to relocate" to "curry the right sourceOrderAt" — at
  four production sites plus the harness, and both wrong currying are silent. The §14.5 guard is lexical and
  cannot see either. NAMED EDIT: pass the consumer's eval handle instead of a source-order function so
  `sourceOrderAt` is computed internally from `e.scope`.
· F3 ★★ THE INSTRUMENT DOES NOT "INHERIT THE CHANGE". `ci/tests/_lib/projection-harness.nix` does not consume
  `mkOutputModules`; it imports class-modules.nix directly with `classNames = [ ]` and has no
  `class-relocation`. Under the design it must HAND-SUPPLY a source order, and the only value keeping the
  projection suites green is the identity — the un-relocated semantics hand-pinned at a THIRD site, which is
  precisely the divergence the document uses to reject the repair.

SIX IN THE STATED SCOPE: F4 C7-a — 15 gen-graph exports neither bound nor rejected (incl. `reachableWhere`,
whose body is `preimageOf`'s exact shape; `condensation`/`coScc`, on-point for the rest-position question;
`order.entryBefore/After/Between`, on-point for §4.4's ordering decision), and one row rejects internal
`let`-bindings as if they were exports. F5 C6 — `sharedFoldKey`/`content` declared required with no violation
behaviour, and one `or`-fallback deleted on the C9-entry-5 tell while its sibling is preserved. F6 — a
quantifier without its domain, and an unenumerated reach consumer (`has-aspect-verbs.nix` `mkEntityHasAspect`
reads `reachAt` DIRECTLY, so an injection would surface as a pseudo-aspect on the v1 `aspects` surface).
F7 — pseudocode re-wraps a record as a module and drops `sharedFoldKey`. F8 — `classSliceOf` count given as
7 files; actual 13 files / 40 matches (direction is against the document's own case). F9 — the alias-hop-
closing red asserts over BOUND modules and its predicate is unspecified. F10 — the only row discriminating the
§12 asymmetry ruling is vacuous at HEAD, admitted.
WHAT SURVIVED REFUTATION AND MUST BE KEPT: §3 (why B cannot simply demand A's attribute — all four sub-claims
verified at HEAD, the best-supported section), §7 (cost), §10, §12 (the asymmetry is a real type-level
difference: Ρ(n) ⊆ Ch × Ch is total on channel names with no scope, while deliveries carry a target root), and
the element-granularity position itself.
★ F11, FOR THE OWNER: the document records the `declare` public-surface ruling NEITHER as obtained NOR as
outstanding. It is outstanding. Blast radius measured zero (see the corpus section above).


════ ★ THE DEFECT IS NOW MEASURED BY EXECUTION, NOT BY READING (2026-07-30, r2 gate, HEAD b0f40de) ════
Native `mkDen` fleet mirroring ci/tests/projection.nix's relocationBase/relocationMod, single-expression
`nix eval` against `builtins.getFlake`:
    relocatedOut.classSubtreeAt axon "nixos" = [ "nixos-host" "hm-alice" ]   <- Consumer A, relocation APPLIED
    relocatedOut.projectClass   axon "nixos" = [ "nixos-host" ]              <- Consumer B, relocation ABSENT
    systems.nixos."host:axon".modules length = 1 WITH the relocation and 1 WITHOUT it
Every earlier statement of this bead rested on reading the two call chains. IT IS EXECUTED NOW.

════ ★ REMEDY SPEC — GATE ROUND 2 VERDICT: REVISE (2026-07-30) ════
ARTEFACT: same path, revision 2, FROZEN at md5 `6d6a45c2dbb745cd31b209da62628b01` (1211 lines, was 830).
Reviewed by a FRESH gate deliberately walled off from round 1's findings — an author who fixes only the cells
a reviewer exhibited produces a document that reads complete to that same reviewer.
S0 MET. C1/C1-a/C2 PASS · C5 PASS · C6 FAIL (one class) · C7 FAIL · C7-a FAIL · C7-b PASS · C8 PASS · C9 PASS
on substance. ★ THIS ROUND DOES NOT COUNT TOWARD THE TWO-CLEAN-ROUND EXIT — findings are in the CONSTRUCTION.

TWO CONSTRUCTION FINDINGS:
· F1 ★★ `sourceOrderOf`'s `or [ c ]` CONFLATES TWO ABSENCES, and Nix's `or` covers the whole attribute PATH,
  not the final selector. EXECUTED against a `{ get = _: _: { }; }` stub: a MISSING WHOLE MEMO returns the
  IDENTITY silently — i.e. exactly the defect class under repair — while a missing CHANNEL returns the proven
  `[ c ]`. The revision's own §5.3 exhibits the counterexample to its own §5.1: a stub whose memo is
  `genAttrs [ ] ...` returns `{ }`, nothing is fabricated, nothing is visible at the call site. So the residual
  is OMISSION, not the "act of commission" §5.1 claims. And no proposed row exercises a stub eval, while §5.3
  says the stub is precisely what the two instruments must grow.
  NAMED EDIT: let-bind `(eval.get sid "class-relocation").sourceOrder`, abort NAMED if absent, apply `or [ c ]`
  only to the per-channel select.
· F2 ★★ INJECTIONS NEWLY CROSS `isEmptyDeferredModule` AND A DECLARED INJECTION SILENTLY VANISHES. HEAD's
  injection arm applies no emptiness test and no force; the extraction does `if isEmptyDeferredModule m then
  [ ]`. MEASURED at HEAD with `declare.inject { class = nixos; module = { }; }`: the empty injection IS
  emitted today (classSubtreeAt count 2, shapes [["imports"],[]]), and `isEmpty` is true for both a bare `{ }`
  and a wrapped `{ imports = [ { } ]; }`. ⇒ under the design it returns `[ ]` — content that lands today
  vanishes after the change, no abort, no note. §4.7's "enumerated, not sampled" claim is therefore false, and
  §7 item 3's "on exactly the same values" is false. ★ EVERY PROPOSED INJECT FIXTURE USES A NON-EMPTY MODULE,
  SO THE ACCEPTANCE SET IS BLIND TO IT.

STATED SCOPE: F3 gen-prelude enumeration is NOT exhaustive — 51 exports measured, 48 named; missing
`toposort` (on-point: it returns `{ result }` OR `{ cycle; loops; }`, a candidate for BOTH jobs the design
gives `graph.cycles` + `preimageOf`), `hasInfix`, `escapeRegex`. Control: 48/51 named DO appear.
★ F4 THE MEMBERSHIP **SHRINK** IS NOWHERE STATED AND IT IS THE ALARMING HALF OF THE OWNER RULING — measured
on the doc's own fixture, `systems.home-manager` = [ "user:alice@host:axon" ] at HEAD, and under the design
the cell's `sourceOrder."home-manager"` = [ ] so `contentIdsOf`'s non-empty filter DROPS THE MEMBER and
`systems.home-manager` EMPTIES. A home-manager configuration DISAPPEARING from flake outputs belongs in the
section whose job is to bound the ruling; §15.1 states only growth. (The tree's armed row already expects
`home-manager = [ ]`, so the mechanism and the suite agree — the gap is the document's statement of the
ruling.) F5 `injectionElementsAt`'s strictness in `domain` is prose-only and decides whether the new
acyclicity abort reaches the compat `hasAspect` surface, where §13 claims "behaviour preserved". F6 §10 entry
4's "nine `__action` sites" is stale — 9 lines, one a comment ⇒ 8 live over 4 files — against §1's blanket
"every count re-derived by command" claim. F7 the `classNames`-inert comment deletion targets the wrong
comment (`mkClassSlice` genuinely does not read it; the equation-bearing instance does).

★ WHAT THE GATE ESTABLISHED POSITIVELY, worth keeping: §4.3b's totalisation — the design's single riskiest
new mechanism — was VERIFIED BY EXECUTION over 5 relations x 10 channels: identical to HEAD for every
`c ∈ frame.rel.nodes`, and the disagreement set is EXACTLY `c ∉ frame.rel.nodes` (HEAD `[ ]`, new `[ c ]`),
precisely the case it names. gen-graph (all modules) and gen-resolve (17 exports) enumerations are COMPLETE
and their rejections spot-checked correct against source. C8 passes outright. The two-consumer trap is NOT
repeated by the proposed rows — the agreement assertion is paired with an absolute-content twin.
★ AND A FINDING AGAINST THE ECOSYSTEM, NOT THIS SPEC: gen-graph `global.nix`'s transpose header cites
Mokhov 2017 §4.3 where den-hoag lib/coordinates.nix carries the reasoned correction to §5.2 (§4.3 is
"Undirected Graphs", which ERASES direction; §5.2's law flips `connect`'s arguments and leaves `overlay`
alone). One of the two ecosystems is wrong in-tree — tracked separately.

════ ★ REMEDY SPEC — REVISION 3 (2026-07-31) + GATE ROUND 3 VERDICT: REVISE ════
r3 ARTEFACT: same path, FROZEN at md5 `549125b9378c692acc89720d35f33ce5`, 1630 lines (was 1211). Author
discharged r2's F1-F7 in order with class sweeps; the sweep's NEW instances, dispositioned in-doc: the
design's own copy of `.actions.resolution or [ ]` (r2-F1's class, fixed in the copy, 5 pre-existing sites
left and said so); `(n.content.meta or { }).__forward or null` newly in-domain by widening (kept, with the
reason r2 owed); the `_`-prefixed-channel drop decided as a NAMED REFUSAL with three grounds; the force
accounting corrected (the real force is isEmptyDeferredModule, NOT assertKeysRegistered — pointing at the
wrong gate is why r2-F2 was invisible); pathSetOf's listToAttrs-on-null measured as an UNNAMED
non-tryEval-containable abort; gen-graph registry ellipsis closed (6/6 dispositioned — same C7-a class,
second library); toposort REJECTED on three independent grounds; a 13-row §1.1 count register each row with
its command + an explicit carried-not-measured table; r2-F7 resolved as RETARGET-NOT-DELETE (the mkClassSlice
comment is TRUE at HEAD and after; the equation-bearing instance is classModulesBuilder's header).

r3 GATE (fresh, walled from r1 AND r2 verdicts via truncated bead read): **REVISE — does NOT count toward
the two-clean-round exit; F1 is in the CONSTRUCTION.** S0 PASS · C1/C1-a/C2/C2-a/C4/C7/C7-a/C7-b/C8 PASS
(C7-a called exemplary, all three enumerations re-derived exact) · C3 FAIL · C5 FAIL · C6 FAIL · C9 FAIL.

r3-GATE FINDINGS, fix order for r4: F1, F2, F3, F4, F5, F6.
· F1 ★★ CONSTRUCTION — §4.5 puts injection elements into `reach`; `reach` has THREE content-reading
  consumers in output-modules.nix, all verified live: remapOver (`placed = concatMap (n: … classSliceOf
  exempt n route.from) (result.get srcScope "reach")`), forwardModulesFor's specs fold (`srcSlices =
  concatMap (n: map (e: e.module) (classSliceOf exempt n spec.fromClass)) reach`), and projectClassScoped.
  §4.7 dispositions ONLY the third. By the revision's own refinement (a stream is a (value class, gate)
  PAIR) the pair (injection element, remapOver/forward slice fold) is ABSENT: every route and every forward
  newly carries injected content with no stated decision, no §8 totality row, no §13 break row, no
  acceptance row; §15.4 records route × relocation as witness-less and never names route × injection.
  Named local edit: two §4.7 rows + the decision + an acceptance row on the existing projection-routes.nix
  fixtures. ★ ORCHESTRATOR THEORY NOTE FOR r4 (inference, mine): the unification thesis is ONE query all
  consumers agree on — deciding that injections are visible to projection but invisible to routes/forwards
  RE-SPLITS the views, re-creating the defect class under repair; if r4 decides that way it carries that
  burden explicitly.
· F2 CITATION — `forwardSourceClassesAt` DOES NOT EXIST (repo-wide 1 hit = a COMMENT at
  class-modules.nix:65; control forwardSourceClassesOf → 12 hits/5 files same run). The real site is the
  INLINE `(n.content.meta or { }).__forward or null` inside forwardModulesFor's specs fold. The spec
  inherited a stale in-tree comment as an anchor — and §1/§11 claim every anchor is a binding name or
  verbatim expression. ★ The implementation should also correct that stale in-tree comment.
· F3 STATED-SCOPE (C3) — the `_`-refusal is grounded on `isReserved = ch: prelude.hasPrefix "__" ch` — TWO
  underscores; `_spool` is not __-reserved, so the cited law does not cover the refused input. The actual
  single-underscore law is isCollectable's conjunct (i), whose domain is content KEYS inside an aspect's
  content attrset (nixpkgs _module/_file scaffolding), NOT declared channel NAMES — a transfer never
  argued. ★ Sibling left live: `declare.reroute { from = "_x"; }` stays accepted and silently inert.
· F4 STATED-SCOPE (C9) — `__forward` is on register entry 4's UNCLASSIFIED-eight list (ownership pass
  owed); the design WIDENS its reader domain to kernel-minted injection elements and §10 does not disclose
  it (the register rule is touches/names/EXTENDS; "writes no new __ key" is true and insufficient).
  Invisible to text search exactly as the register predicts — the bridge is forwardSourceClassesOf's body.
· F5 INSTRUMENT — the §1 item 6 or-path census is 22, not 20 (output-modules 7 not 5; the single-line
  predicate can only undercount). In-region figure (4 sites / 2 expressions) unaffected and correct.
· F6 STATED-SCOPE minor — §8's "injection at a rest position IS delivered" overstates: class-seeds is
  genAttrs classNames; an unregistered channel can be a preimage SOURCE and can never be a query ANSWER
  (the in-tree relOf comment already states it); reconcile.

★ GATE-VERIFIED POSITIVES r4 MUST NOT REGRESS (keep verbatim): §4.3b's equivalence EXECUTED-TRUE (7
relations × 9 channels; disagreement set exactly c ∉ frame.rel.nodes, old [ ] → new [ c ]); §15.1's shrink
mechanism EXECUTED-TRUE; all three C7-a enumerations exact (gen-graph 49, gen-prelude 51 with 7+3+41
reconciliation, gen-resolve 17); listToAttrs-null NOT tryEval-containable; `${null}` dynamic attrs are
SKIPPED (reach seen0 safe; dedupByKey keeps nulls; injections survive structuralNodes); classifyKey never
throws; the S0 fixture is real and relocationMod fires at every host-coordinate scope.
GATE COVERAGE LIMIT: the author's three fleet-level EXECUTED numbers (empty-inject 3-vs-1, _spool tags,
§15.1 systems listing) were mechanism-verified but NOT independently reproduced; ci suite, 13 templates and
every §14 SPECIFIED-NOT-RUN row remain unexecuted.

NEXT ROUND (r4) NOT YET DISPATCHED — queued behind the 53.64 design author for the papers writer slot.
Fix order: F1 (the decision + two §4.7 rows + §8 row + acceptance on projection-routes.nix), F2, F3, F4,
F5, F6.

════ ★ REMEDY SPEC — REVISION 4 (2026-07-31, at den-hoag 2e44ff5) — GATE ROUND 4 PENDING ════
r4 ARTEFACT: same path, FROZEN at md5 `6ddba8e07a7fea43c63bc63d625cd888`, 2005 lines (was 1630).
· F1 DECIDED: **YES — injections travel every route and every forward** (new §4.5a), three grounds: the
  unification thesis (an extraction answering differently per caller is two queries = this bead one layer
  down); exclusion is INEXPRESSIBLE without a sum-type tag dispatch on the element (would falsify §10 entry
  4's "not dispatched on" and add a filter site to register entry 5's pattern — the cheaper option costs a
  register entry; recorded as a named rejected alternative in §16); the declaration reading (an injection at
  D at a reached node IS class-D content of a reached node).
· ★★ F1's CLASS SWEEP FOUND THE ENUMERATION WAS KEYED ON THE WRONG DOMAIN: `git grep '"reach"'` → 6 STRING
  sites, but forwardModulesFor receives reach as an ARGUMENT and appears in ZERO of them — r2 AND r3 both
  quoted that 6 as the consumer enumeration. Redone over FOLDS: 6 folds, 2 invisible to any name-keyed
  grep. Both numbers recorded (§1.1 #18).
· ★★ NEW INSTANCE 12a, THE ONE TO READ: `remapOver`'s `ensureSeed` fires only on `… && placed == [ ]` — an
  injection at the route's from-class makes placed non-empty and SUPPRESSES the v1 ensure-target-path seed
  (the empty cell's `users.users.<u> = { }` stops being emitted). A gate on the FOLD'S RESULT, invisible to
  any per-element sweep. Plus 13a (an injection can never declare a forward — defined limit, stated) and 14
  (routeRemapFor's parent-targeted arm is a SECOND forwardSourceClassesOf fold over a DESCENDANT's reach).
  Delivered: 5 §4.7 rows, 3 §8 rows, 5 §13 rows, 5th §7 cost item, §14.6 acceptance on projection-routes.nix.
· F2: anchor fixed to the real inline expression; stale in-tree comment (class-modules.nix:65) now an
  implementation-obligation row in §13. Class sweep of EVERY backticked token found a SECOND dead anchor:
  `u5.header` (inherited verbatim from register entry 3) → 0 in lib/+ci/, replaced with entry 3's live
  buildRoots anchors. REGISTER ENTRY 3 CORRECTED IN-BODY THE SAME SESSION (2026-07-31). Sweep's stated blind
  spot: a token-grep proves a name EXISTS, not that it names what the sentence says.
· F3: isReserved citation WITHDRAWN (hasPrefix "__", wrong prefix AND wrong name-set); refusal RE-GROUNDED
  on conjunct (i)'s domain (content KEYS = module scaffolding; module-shape.nix's emptiness peel corroborates)
  with the transfer to channel names owned as THIS DESIGN'S decision (it mints `content = { name; ${channel}
  = module; }`). Sibling class DISCHARGED BY SIX-WAY MEASUREMENT (§4.4c, each vs one-character control):
  inject at `_s` REFUSED NAMED (real bypass measured); reroute.from `_u` ADMITTED (provably inert, identity-
  relocation precedent); reroute.to `_x` ADMITTED (underscore measured irrelevant to a target; delivers
  through the intermediate identically to control). §14.2(f) arms both admissions. Law-domain sweep (§4.4d,
  9 rows) found the empty-body drop law is stated in classSliceOf's HEADER, not over class content generally
  — the empty-injection drop is an EXTENSION BY CONSTRUCTION, argued, not inherited (§4.4b corrected).
· F4: §10 entry 4 discloses the `__forward` widening — 2 kernel reader expressions (body + inline copy),
  folded over a reach at 3 sites, all seeing injection elements after §4.5; lands on the INHERITED side of
  the owed ownership pass.
· F5: 22 re-derived (output-modules 7; the 18 out-of-region now ENUMERATED not subtracted); undercount
  direction stated AND BOUNDED — newline-insensitive re-run → 0 multi-line instances on those three files.
· F6: reconciled BY MEASUREMENT with control (inject at unregistered "spool" → in NO channel's answer;
  control inject at registered "D" → D=["iD"]). §8's row was FALSE IN BOTH HALVES (not delivered at HEAD,
  not after — class-seeds keys genAttrs classNames, the relOf law). Replaced by 3 rows separating ANSWER
  DOMAIN from EXTRACTION; §4.3b's widening fixes unregistered forward SOURCE classes, not injections at rest.
· PARTIAL, stated: all §14 rows including the 5 new §14.6 route rows are DERIVED predictions, not run; ci
  suite not run; r3 gate-verified positives left verbatim (only a table-rendering escape touched in §6.1).

════ ★ GATE ROUND 4 VERDICT: REVISE / ACCEPT-WITH-CONDITIONS (2026-07-31, fresh gate walled from rounds
1-3; probes at 2e44ff5, scratchpad p1/p2/p3.nix, each with a firing positive control) — does NOT count
toward the two-clean-round exit (two CONSTRUCTION findings), BUT CONVERGING: both have NAMED LOCAL EDITS
and neither requires a new position (C6 verdict-mapping ruling ⇒ accept-with-conditions posture). ════
S0 PASS · C1 pass-with-condition · C1-a/C2/C2-a/C3/C4/C5/C7-a/C7-b/C8/C9 PASS (C2 §5.4 called strongest;
C7-a exemplary; C9's __forward disclosure verified complete by an independent sweep of the other seven
unclassified names) · C6 FAIL · C7 FAIL.
r4-GATE FINDINGS, fix order for r5: F1, F2, then F3-F7.
· F1 ★★ CONSTRUCTION — §4.3b's totality widening is DEAD CODE through the design's own memo:
  `sourceOrder = genAttrs domain (srcOrder frame)` with `domain = frame.rel.nodes (or classNames)` can
  never call the widened `c ∉ frame.rel.nodes` branch, and `sourceOrderOf`'s `order.${c} or [ c ]` answers
  every out-of-domain channel without calling srcOrder. EXECUTED: sentinel throw in the widened branch,
  memo force + 50 production-shaped lookups → sentinel fired EXACTLY ONCE, on the direct-call positive
  control. §4.7 stream 3 and §8's row TITLE credit the widening with a fix the `or` performs; stream 2 is
  carried by the domain choice alone. NAMED EDIT: keep §4.3b on its real ground only (fallback PROVABLY
  equal to the function), re-attribute streams 2/3 and the §8 row title. Re-attribution or deletion — no
  new position.
· F2 ★★ CONSTRUCTION — ensureSeed's gate has TWO directions and the doc enumerates ONE. Recorded: injection
  ⇒ placed non-empty ⇒ seed SUPPRESSED. Undeclared mirror: `placed == [ ]` when route.from carries an
  OUTGOING relocation at the owning scope (sourceOrder.A = [ ], the §15.1 shrink shape) ⇒ the seed FIRES
  and EMITS `users.users.<u> = { }` into the built nixos config where HEAD does not. The gate is LIVE in
  production: compat/builtins.nix userToHost (fromClass "user", appendToParent, path [users users <name>])
  through deliver.nix's fromClass→sourceClass→route.from lowering. Latent by the same structural P=0
  derivation as the parent defect. NAMED EDIT: §4.7 row 12b + §8 row + §13 row + §14.6 twin
  test-parent-targeted-route-seed-fires-under-relocation.
· F3 STATED-SCOPE — §11's citation-invariance GROUND is false: executed with a throwing rev accessor,
  reachableFrom IS consulted on the out-of-domain path (`back ? ${d}` forces it); conclusion survives
  (same inputs, [ ] both sides, measured). NAMED EDIT: restate the ground as measured-unchanged.
· F4 STATED-SCOPE — the `_`-prefix REFUSAL reaches the compat hasAspect entry points by the same strict
  injectionElementsAt read the cycle abort rides; §13 stops at "refusal where HEAD delivers". NAMED EDIT:
  extend §13's row + a compat-entry-point arm in §14.2(d) mirroring §14.4.
· F5 STATED-SCOPE — the out-of-domain ordering tail is act-order in a paragraph headed act-order-free; the
  tail is UNOBSERVABLE (rest-position row proves it) but the lemma is never connected. NAMED EDIT: state
  the unobservability lemma at §4.4 citing §8's row, or drop the tail.
· F6 INSTRUMENT — §1.1 #17's control domain: `u5` over lib/+ci/ is 3 files / 5 lines (doc's 2 = lib/-only).
  Conclusion (u5.header → 0) re-derived unaffected.
· F7 INSTRUMENT — rawSeedsAt + classSeedsAt (class-modules) become DEAD under §4.5's rewrite and §14.5's
  zero-reach row omits them; rawSeedsAt's injection arm is the un-gated second injection producer, so
  leaving it resident leaves the split half-alive. NAMED EDIT: add both to §14.5; note output-modules has a
  DIFFERENT classSeedsAt binding that must survive.
★ r4-GATE POSITIVES (add to the must-not-regress set): §4.3b in-domain equivalence EXACT by execution (7
rel × 10 ch, 36 diffs all the named case, differ CAN fire); memo answers match §9.2's predicted rows
(name-sort order X before Y — test-unregistered-sources-order-free survives); foldReach null-safe BOTH
sides; §8's rest-position row RIGHT (r3's claim was wrong); the schedule argument is the SCHEDULER'S ACTUAL
RULE (cyclic SCC admitted iff every member circular — no proxy); classNames = effectiveClassNames reaches
the builder. Gate coverage limit: discharged §4.4b's two measurements by reading rawSeedsAt (weaker than
the doc's own execution); no fleet built, no §14 row run.
NEXT ROUND (r5) NOT YET DISPATCHED — queued behind the ops-seam design round 2 for the papers writer slot.

════ ★ REMEDY SPEC — REVISION 5 (2026-07-31, at 2e44ff5) — GATE ROUND 5 PENDING ════
r5 ARTEFACT: same path, FROZEN at md5 `e85501aa52e523c89e019ac2732a1e48`, 2334 lines (was 2005).
★ AUTHOR'S OWN FLAG: NOT A CLEAN ROUND — F2's class sweep found a CONSTRUCTION member and §4.5 changed
(narrowing, not new position): ONE reach.compute payload expression now, not two.
· F1 discharged BY MEASUREMENT (sentinel reproduced independently: 56 lookups + memo deepSeq, never fired;
  direct-call control fired). §4.7 rows 2/3 re-attributed (domain choice; `or [ c ]`); §4.3b kept on its
  one real ground, now measured (memo == widened fn ≠ HEAD fn). CLASS SWEEP FOUND 5 WRONG ATTRIBUTIONS
  total, registered as §5.4's second table: §11's ground (=F3); §4.4b/§4.4d crediting module-shape's
  emptiness peel with the _spool drop (MEASURED FALSE both sites, 3 controls — conjunct (i) carries it);
  §10 entry 1 crediting class-relocation with content-key-totality's force (mechanism verdict "improves" →
  "survives unchanged"); §4.5a's null-key claim (=the new construction find); §2.2 cited 4× resolves to NO
  heading (a cross-ref is not an identifier — structurally invisible to the token sweep). ★ Stated
  generalisation: 4 of 5 name a mechanism REAL, CORRECTLY QUOTED, and ADJACENT to the one that works.
· F2 discharged (row 12b + §8/§13 rows + §14.6 twin; userToHost's four conjuncts verified at HEAD) AND the
  gate-sweep found: row 11a (=F4 independently); ★★ ROW 15, CONSTRUCTION — foldReach dedups by
  `itemKey = n: n.key` and a NULL key is NEVER deduped ⇒ duplicate ASPECT rejected, duplicate INJECTION
  ADMITTED — EXECUTED against gen-graph 231b319 (scope in subtree AND edge target: aspect ×1, injection
  ×2). Exactly the §3-item-2 doubling re-created for the added value class. DECIDED BY CONSTRUCTION:
  injections travel the STRUCTURAL component (scope-indexed, repeat-free) NOT the edge component
  (aspect-identity-indexed, which they lack). Rejected alternatives recorded in §16 (mint an identity —
  declare.edge grounds + `key = null` would mean two things; post-hoc dedup — C7 repair). Ripple: rows
  4 WITHDRAWN / 6, 11 narrowed edge-reached → structural subtree; §15.2 ANSWERED. r4's "foldReach null-safe
  both sides" positive EXPLICITLY PRESERVED — the INFERENCE from it is what fell.
· F3 restated as measured (both sides consult reachableFrom, same argument, same [ ]); F4 four compat entry
  points + §14.2(d) row with control; F5 tail KEPT with the unobservability lemma PROVED from
  sourceOrderOf's two return shapes (56-lookup run: every out-of-domain answer a singleton); F6 control
  domain fixed at 3 sites (u5 = 3 files/5 lines over lib/+ci/); F7 both bindings added to §14.5 — the
  zero-reach guard is SCOPED (output-modules' classSeedsAt is a DIFFERENT binding; bare-name zero-reach is
  UNSATISFIABLE).
· PARTIAL: no §14 row run; ★ test-parent-targeted-route-seed-fires-under-relocation is BLOCKED on an
  instrument that does not exist (a stub serving "class-relocation" from the real equation) — recorded
  §14.6/§15.4, and it is the ONLY row covering a behaviour change on a route production builds today. Both
  must-not-regress lists intact verbatim (grep-verified). §4.7=22 rows, §8=31, §13=30.
Probes: scratchpad r5p1/r5p2/r5p3.nix; gen-graph 231b319, gen-prelude beab47b.
NEXT: GATE ROUND 5 (fresh, walled) — dispatched.

════ ★ GATE ROUND 5 VERDICT: REVISE / ACCEPT-WITH-CONDITIONS (2026-07-31, fresh walled gate; 8 probes at
2e44ff5 on the real classModulesBuilder harness, scratchpad p1,p3-p8.nix) — does NOT count toward the
two-clean-round exit (F1 in construction) BUT the construction is "the strongest it has been"; all five
§5.4 re-attributions verified correct by instruments built independently of the document's. ════
S0 PASS · C1/C1-a/C2/C3/C4/C5/C7-a/C7-b/C8/C9/C9-a PASS · C6 FAIL (F1) · C7 pass-on-main/fail-on-F1.
r5-GATE FINDINGS, fix order for r6: F1, F2, F3, F4.
· F1 ★★ CONSTRUCTION — THE MINTED ELEMENT COLLIDES WITH ITS OWN RESERVED KEYS. §4.4 mints
  `content = { name = "<inject>"; ${className act.class} = act.module; }` and §4.4b's three-way split
  ("registered/unregistered/`_`-prefixed — total and stated") is NOT total: channel "name" is in-domain,
  unregistered, STATED-ADMITTED — and EXECUTED it aborts `error: attribute 'name' already defined`, NOT
  tryEval-containable, inside strict injectionElementsAt on reach.compute ⇒ aborts every reach consumer
  incl. the four compat hasAspect entry points (HEAD delivers: inject "name"+reroute → ["cB","iNAME"],
  control same run identical shape). Siblings same class: channel "meta" FALSIFIES the stated defined
  limit "an injection can never declare a forward" (minted content.meta IS the user's module — measured
  __forward != null; aspect-shaped control null); channel "artifact" breaks §4.7 row 5's short-circuit
  derivation (hasArtifact true forces classKeys; conclusion survives, derivation wrong). ROOT: §4.4b swept
  the collision against ONE key space (_-scaffolding) not the kernel's fixed-key content reads
  (name/meta/artifact/_). NAMED EDIT at the EXISTING refusal position: extend injectionElementsAt's named
  refusal to the element's reserved key set — "name" refused hard; "meta"/"artifact" DECIDED not silent;
  §8 totality rows; correct rows 5/13a, §13's forward row, §15.2.
· F2 ★★ STATED-SCOPE — §4.7 ROW 7'S ADMISSION CELL MISSING (the doc's own "the second question is the one
  whose answer is an admission" applied everywhere EXCEPT row 7): a route/forward whose `from` is a
  relocation TARGET newly reads preimage-source content — EXECUTED: reroute spool→user ⇒ sourceOrder.user
  = ["user","spool"] (admission, UNSTATED) vs reroute user→nixos ⇒ [ ] (stated 12b) vs control ["user"] —
  membership GROWTH on the production userToHost route, unpriced, unarmed. ALSO the THIRD ensureSeed cell:
  incoming relocation ⇒ placed non-empty where HEAD empty ⇒ seed SUPPRESSED — deletes a users.users.<u> =
  { } entry that projection.nix's test-anchor-projectClass-nixos-routed-delta pins for three cells today.
  NAMED EDITS: row 7 admission cell + third ensureSeed cell + two §8 rows + §13 growth row + §14.6 row
  (blocked on the same §5.3 harness change — STRENGTHENS §15.4's priority argument) + §7 term.
· F3 STATED-SCOPE — §10 entry 4's "nothing anywhere asks whether an element is an aspect or an injection"
  is falsified by the design's OWN §4.5 aspect-identity filters (hasAspectIdentity at four compat sites,
  keyed on `key`; verified ABSENT from the tree today, control identityKey → has-aspect.nix:97). §16's
  second rejection ground therefore unavailable; rejection survives on the thesis alone. NAMED EDITS:
  narrow the clause, disclose the four sites, re-ground §16.
· F4 INSTRUMENT minor — row 5's force accounting correct except channel "artifact"; name the domain.
★ r5-GATE POSITIVES (append to must-not-regress): all five §5.4 re-attributions CORRECT by execution
(sentinel/throwing-rev/foldReach-doubling/module-shape-3-controls/entry-1-downgrade); the count register
ACCURATE (every sampled row re-derived exactly, incl. #10's cannot-match control as load-bearing);
fallback-equals-function measured; §15.1 shrink mechanism sound; applyConstraints reaches every aspect
element; isCollectable conjunct (i) precedes the exempt disjunction; every quoted expression VERBATIM
across seven files. Gate coverage: mechanisms on the synthetic harness + memo, NOT fleet counts; §14 stays
specified-not-run; gen-lib pins used flake-locked (the version this tree actually builds against).
NEXT ROUND (r6) NOT YET DISPATCHED — queued behind the ops-seam design round 3 for the papers slot. Fix
order: F1 (a DECISION about what an element may be named, at the existing refusal position), F2, F3, F4.

════ ★ REMEDY SPEC — REVISION 6 (2026-07-31, at 2e44ff5) — GATE ROUND 6 PENDING ════
r6 ARTEFACT: same path, FROZEN at md5 `f6e6484ef17251559160d0b69585f78f`, 2759 lines (was 2334). Probes
scratchpad r6p1/r6p1b/r6p2/r6p2b/r6p3.nix, flake-locked getFlake at the pinned rev.
· F1 DECIDED — REFUSE `keyCategory c ∉ { "class", null }` at the EXISTING refusal position: "name" hard
  (measured: dynamic-attr collision aborts THE ENCLOSING tryEval; one-char control succeeds); "meta"
  REFUSED (an injected module's arbitrary attribute would reach ${f.fromClass} — the node-wide exempt
  over-reach re-entered through the VALUE; measured: minted meta-channel element produces a forward spec
  IDENTICAL to a genuine aspect's); "artifact" REFUSED (key-semantics fixes the key's meaning;
  artifactExclusive certifies VACUOUSLY while classSliceAt would deliver the same module — two readings of
  one value selected by which gate reads it; ★ STRONGER than the gate stated: hasArtifact's != null FORCES
  the injected module, measured with firing sentinel + non-firing control). PREDICATE READS THE DECLARED
  AUTHORITY, NOT A LIST (a hand-list = the retired negative-enumeration-over-open-key-set shape;
  4kh.17 entry 4 counts two surviving strip lists — a list would add a third). classifyKey CANNOT serve —
  measured: "facet" for name, artifact AND unregistered spool alike (collapses schema-claimed into
  unregistered, which IS the distinction) ⇒ one new arg on classModulesBuilder/mkClassSlice, priced.
  Row 0 and conjunct (i) each have a live member the other misses (_spool measures keyCategory null).
  ★ CENSUS CLOSED, GATE'S WAS ONE SHORT: kernel fixed-key reads off content = SIX names — name, meta,
  artifact, INCLUDES (compat augment's `includes = content.includes or [ ]` — reachable only if §4.5's
  aspect-identity restriction is dropped ⇒ that restriction is load-bearing for a SECOND independent
  reason), settings + id_hash POSITIVELY unreachable (both folds read resolved-aspects, not reach) — plus
  the _ prefix. NEW SWEEP TABLE §4.4e over ALL FIVE minted attrsets: the MERGING literal is the unsafe
  one, the NESTING one (sourceOrder inside { sourceOrder; injections; }) is the design's own worked safe
  form — and merging is exactly where nesting was unavailable. Also corrected: "injection can never
  declare a forward" is a property of the REFUSED SET, not the minting (3 sites); §4.4b's own "split is
  TOTAL" claim was false by its own quantifier.
· F2 ALL THREE CELLS, measured on the REAL gen-graph memo, unregistered AND registered route classes:
  none ["user"] / outgoing [ ] / INCOMING ["user","spool"] (registered: ["nixos"] / [ ] /
  ["nixos","home-manager"]); control same run outgoing ≠ incoming. Delivered rows 7a (admission — growth
  through channels HEAD never visited) + 12c (third ensureSeed cell — SUPPRESSED seed DELETES the
  users.users.<u> = { } entry that test-anchor-projectClass-nixos-routed-delta pins for three cells,
  quoted verbatim) + 2 §8 rows + 2 §13 rows + 2 §14.6 rows + §7 term (Θ(I+P), P bounded by K, zero
  fleet-wide). §15.4 STRENGTHENED: the blocked stub now gates a 3-row table on ONE production route where
  12b and 12c move the built config in OPPOSITE directions. ★ NEW METHOD RECORDED in-doc: rounds 1-5
  quantified over GATES; rows 1c/7a/12c come from "whose names can be KEYS in what the design MINTS" and
  "for a relation-dependent read, ALL its directions" — enumerate the full domain before hunting members.
· F3 verified independently (0 at HEAD, control identityKey 9/6) and the gate's OWN site list corrected:
  3 COMPAT + 1 KERNEL (seen0 is resolved-aspects.nix, kernel). Clause narrowed, four sites disclosed,
  §16 re-grounded on the thesis alone. NEW: "read exactly once" false — TWO sites, both unions, conclusion
  survives, count corrected.
· F4 domain named (true for every ADMITTED channel and no other) + stated that row 1c's refusal is what
  makes the domain total.
· PARTIAL: no §14 row run (the three collisions pinned by the new rows were EXECUTED as measurements
  instead — §1.1 #26-28); TWO §14.6 rows now stub-blocked (up from one);
  test-inject-channel-name-is-refused-before-construction CANNOT express its HEAD side as a row (abort
  escapes tryEval) — recorded as a measurement with control, stated why; §8 row-count predicate differs
  from r5's (23+7 vs 31), both stated with commands, not reconciled. All three must-not-regress lists
  verified item by item (four first-pass misses were the checker's own regex bugs, each re-verified
  literally).
NEXT: GATE ROUND 6 (fresh, walled) — dispatched.

════ ★ GATE ROUND 6 VERDICT: REVISE / ACCEPT-WITH-CONDITIONS (2026-07-31, fresh walled gate; keyCategory
executed over 19 names with firing controls) — does NOT count and RESETS the exit count (two CONSTRUCTION
findings), but every violation class has a named local edit and none needs a new position. ════
S0 PASS · C1/C1-a/C2/C3/C5/C7/C7-a/C8/C9 PASS (C8 strongest) · C4 FAIL · C6 FAIL · C7-b FAIL.
r6-GATE FINDINGS, fix order for r7: F1, F2, F3, F4.
· F1 ★★ CONSTRUCTION — THE REFUSAL PREDICATE'S CLASSIFICATION AUTHORITY DOES NOT EXIST AS A SINGLE OBJECT:
  TWO aspectSchema instances at HEAD — top-level concernAspects (NO quirkChannels; in-tree comment: "used
  ONLY for internal.classifyKey … the eval-load-bearing instance is the per-mkDen denAspects") vs denAspects
  (quirkChannels = channelSet). EXECUTED on internal.aspectSchema.keyCategory (the instance §1.1 #25's
  command names): ports/peers/deduped/ssh-peers → ALL null (controls fire: nixos "class", artifact "facet",
  name "structural") — NO name answers "channel" there, so "a quirk channel → refused" is undetermined by
  the spec; §7 item 6's threading citation is the internal EXPORT block, not the mkClassSlice call site
  (which reads denAspects); the new-arg obligation reaches 2 of 4 instruments (class-relocation.nix:95 +
  class-bucket-query.nix:91 call cmb with HAND-WRITTEN classifyKey stubs — a required field breaks both);
  §14.2(g)'s quirk-channel member has no row and cannot be produced in the named harness. NAMED EDIT:
  thread keyCategory FROM denAspects at the mkClassSlice call site; re-take #25 on that instance; extend
  the obligation to all four instruments; give 14.2(g) a quirk-channel arm on a fleet that has one.
· F2 ★★ CONSTRUCTION — THE CYCLE GUARD REACHES EDGE-REACHED SCOPES; r5/r6 "corrected" a TRUE statement
  into a FALSE one. reach.compute's .injections read is structural-only (right), but the EXTRACTION forces
  the memo on a second path: projectClassScoped folds over ALL of reach; edge-projected elements carry
  scope = edge.target; classSliceAt's first act is sourceOrderOf result (scopeOf n) → the edge-target
  scope's class-relocation → frameAt's cycle throw. Row 11 (compat, reach-only) stays correct; row 6,
  §9.3 and §7 item 2's price do not — and §9.3 is den-hoag-aoh's required statement of where the new abort
  fires; §14.4 is dimensioned to the narrow domain. NAMED EDIT: restore "edge-reached" with the corrected
  MECHANISM (the extraction's memo read), split §7 item 2's price, add an edge-reached §14.4 arm.
· F3 INSTRUMENT — §4.4e's "every attrset this design mints" missed TWO (groupBy partition; exempt //
  assertedOf at two sites) — both safe (gate verified the reasons: no fixed-key reader of exempt in lib/),
  but the table is a totality claim.
· F4 INSTRUMENT — #30's control misreported in both figures (10 lines/5 files, not 9/6 — repo-wide-minus-
  .beads domain error, the same class #17/#23 catalogues, in the row added to close that class). Direction
  favours the claim; the supported finding confirmed.
★ r6-GATE POSITIVES (append to must-not-regress): ten §1.1 rows re-derived exactly; #26 executed with its
one-char control; the ${null} skip; #25's NON-quirk cells all correct on the named instance;
classifyKey-collapses argument sound (concern-aspects.nix:103-113 routes non-class/non-channel to facet);
§4.3b in-domain equivalence hand-checked (relOf's unique+filter makes duplicate domain members impossible);
the three _-prefix sites + conjunct-(i)-precedes-disjunction; artifactExclusive verbatim; §12's asymmetry;
§2(b)'s four-instrument enumeration; §14.5's bound-twice scoping; the stale-comment obligation
(class-modules.nix:64 really names forwardSourceClassesAt). ★ Gate did NOT re-derive #27/#28/#29 — F1's
instance failure is a reason to re-check their instance assumptions in r7.
NEXT ROUND (r7): F1, F2, F3, F4 + re-check #27-29's instance assumptions. Two-clean-round count at ZERO.

════ ★ REMEDY SPEC — REVISION 7 (2026-07-31, at 2e44ff5) — GATE ROUND 7 PENDING ════
r7 ARTEFACT: same path, FROZEN at md5 `71fb3303564e41bfafd13ab3e507ebdc`, 3114 lines (was 2759). Probes
scratchpad r7p1-r7p8.nix, flake-locked (and the lock relationship itself verified: ci/flake.lock's
top-level gen-graph df7c893 is a TRANSITIVE node, not the den-hoag input's — recorded in §1).
· F1 DISCHARGED: authority census = THREE constructions (concernAspects :218 quirk-blind = internal;
  denAspects :458 with quirkChannels = channelSet; compat gatedAspectsType.mkKeyCategory :74). #25 RE-TAKEN
  BY EVALUATION on the denAspects-args instance (quirk names "channel" on D, null on I; control: D rebuilt
  with quirkChannels = { } reproduces I exactly ⇒ the ARGUMENT not the import); #30a validates the
  stand-in. §7 item 6 citation moved to the real mkClassSlice call site; obligation extended to FOUR
  instruments in TWO SHAPES with per-instrument migrations (mkClassSlice: 1 call site, a required field
  defaults nowhere); §14.2(g) quirk arm on a real fleet — #32 MEASURED: quirk member is LIVE at HEAD
  (count 3 with the quirk declared, IDENTICAL with it removed — delivery is independent of declaration
  today) ⇒ FOUR live refused members. Sweep found: the "two instruments" miscount was an INTERNAL
  inconsistency (three sections already said four); the refused set is a strict SUPERSET of the six-name
  census (excludes/tags/projects "facet" refused; guard/drop null ADMITTED — the refusal provably is NOT
  the census written out); a hand-written classifyKey beside internal keyCategory = one cm with TWO
  DISAGREEING AUTHORITIES (why the cmb harnesses must stop hand-writing).
· F2 DISCHARGED with the mechanism corrected AND a new two-field find: #33 (edge elements carry
  scope = edge.target, measured with discriminating control), #34 (the design's extraction forces the
  edge-target memo — sentinel fires at tgt and host, NOT at an unreached scope), ★★ #35 THE MEMO'S TWO
  FIELDS FORCE INDEPENDENTLY — the CYCLE GUARD rides BOTH .sourceOrder and .injections (positive control:
  HEAD's class-seeds aborts on [A→B,B→A], clean on [A→B]) while injectionElementsAt REFUSALS ride ONLY
  .injections ⇒ rows 11/11a do NOT have the same reach (three revisions asserted they did): cycle =
  structural ∪ edge closure; refusals = structural subtree ONLY — an inject at a refused channel at an
  edge-only-reached scope is NOT refused, now STATED as row 11a's narrower domain. #36 closes the compat
  path split (classSliceOf in lib/compat/ = 7 hits ALL COMMENTS, control 19/3 in lib/attributes/). §9.3
  now an EXACT 3-row fire-set table with verbatim throw text (den-hoag-aoh's statement); §7 item 2 split
  into path A/path B; §14.4 gains the edge-target row + compat-stays-clean control + two more controls;
  §15.2: the edge target's RELOCATION applies even though its injections do not (§12 owning-scope uniform).
· F3: §4.4e 5→7 rows; the two added are safe for a THIRD reason (reader's syntactic form) — and that is
  WHY they were the omitted ones (a totality table whose members share a justification closes short on
  members whose safety argument is not on the page). exempt fixed-key read: 0 over lib/+ci/, control
  content\. → 24.
· F4: #30 corrected WITH its domain (10/5 over lib/+ci/; the old 9 matches NO domain); fixed at both sites.
· #26-#29 INSTANCE RE-CHECK, each re-taken: #26 vacuously instance-free; #27 instance-free BY MEASUREMENT;
  #28 SPLIT — conclusion instance-free (the force is the FIRST conjunct) but its positive control is
  instance-SENSITIVE (fires on an effectiveClassNames instance, not on core — row now names the required
  instance); #29 sensitive to classNames not the schema instance, both axes already in the row. Exactly
  ONE of the four was instance-sensitive in a way that mattered, and it was #25.
· PARTIAL: no suite; §14.4's new row + all six §14.2(g) rows specified-not-run (premises/consequences
  executed with controls; #32 is the quirk arm's HEAD side); two §14.6 rows still stub-blocked. All FOUR
  must-not-regress lists verbatim. Edit-only tooling (no Write) — zero deletion risk.
NEXT: GATE ROUND 7 (fresh, walled) — dispatched. Two-clean-round count at ZERO.

════ ★★ GATE ROUND 7 VERDICT: ACCEPT-WITH-CONDITIONS — THIS ROUND COUNTS TOWARD THE TWO-CLEAN-ROUND EXIT
(2026-07-31, fresh walled gate; four nix-eval runs at 2e44ff5 against the tree's own locked gen pins) ════
★ FIRST COUNTING ROUND. NOTHING IN THE CONSTRUCTION. S0 + ALL of C1-C9 PASS. Every executed row the gate
re-took REPRODUCED on the instance it names — including r7's two headline corrections (#25 on both
instances with the quirkChannels={ } control; #35's two-field force structure end-to-end over the real
frameAt/relOf/cycles) and r5's construction change (foldReach null-keyed doubling). The gate also MEASURED
what the doc had only argued (dedupByKey null-keep: three null-keyed items survive, keyed duplicate
collapses) and REFUTED its own worry (contentIdsOf's != [ ] does NOT short-circuit the fire set — list
spine-strictness; §9.3's "every element" is EXACT). Twenty-six register rows re-derived by command, all
correct. Implementability spot-checked: result is module-level in output-modules (eval handle needs NO new
parameter); mkClassSlice's one call site already inherits from denAspects.
THREE FINDINGS, ALL IN THE INSTRUMENT / STATED SCOPE, fix order for r8: F1, F2, F3.
· F1 INSTRUMENT — §1.1 #36 QUOTES A MEASUREMENT THAT DOES NOT EXIST AT HEAD: its own predicate returns
  0 hits (not "7 hits, all comments"); git log -S: classSliceOf has NEVER existed under lib/compat/ at any
  commit. Controls: the row's own lib/attributes/ control reproduces (19/3); the glob reaches the named
  files (50 of 53); nearest transcription candidate (classSubtreeAt) does not reproduce either. THE
  CONCLUSION IS TRUE AND STRICTLY STRONGER — but the figure is quoted at row 11 and §9.3. NAMED EDIT:
  restate #36 as 0-with-controls + never-existed, correct both quote sites. ★ WHY THE DOC'S OWN SWEEPS
  MISS THIS CLASS: item 8 checks a name EXISTS, item 9 checks it denotes ONE object, §5.4 runs cited
  EXPRESSIONS — none RE-EXECUTES A REGISTER ROW'S OWN COMMAND against its stated value. The check §1.1's
  opening sentence already promises.
· F2 STATED-SCOPE — §4.4c's class named wider than enumerated: "the declaration surfaces that name a
  channel" is at least FIVE at HEAD, not three — also reach-edge.classFilter (a membership test in the
  SAME content key space conjunct (i) rules on: a _-prefixed classFilter gates on a _-prefixed content key
  assertKeysRegistered never validates) and meta.__forward's fromClass/intoClass (the binding this design
  widens), plus delivery's sourceClass/targetClass. None changes verdict (derived by READING consumers,
  not execution — gate's stated limit). NAMED EDIT: restate the class as "surfaces whose channel name
  becomes a CONTENT KEY" (exactly one member: inject.class), siblings as relation-endpoint surfaces,
  others dispositioned out with §1 item 6's scoping sentence as the model.
· F3 STATED-SCOPE/INSTRUMENT — §14.4's edge-target row lacks its own NON-VACUITY condition: with no
  aspect at T surviving the edge's classFilter, nothing carries scope = T, the memo is never demanded,
  green both sides. NAMED EDIT: fixture requires ≥1 resolved aspect at T passing the filter + a same-run
  non-empty control under an acyclic T.
★ KEEP: everything in section 4 of the verdict (the reproduced rows, the refusal-totality partition over
keyCategory's measured five-value answer set, the implementability spot-checks).
NEXT ROUND (r8): apply F1/F2/F3 (all local), then GATE ROUND 8 — a second clean round EXITS THE GATE.

════ ★ REMEDY SPEC — REVISION 8 (2026-07-31, at 2e44ff5) — GATE ROUND 8 PENDING (EXIT CANDIDATE) ════
r8 ARTEFACT: same path, FROZEN at md5 `f496cc787515a2397cc44ccfe34cd81e`, 3182 lines (+68, all additions;
9 exact-match Edits, no Write). Surgical round applying r7-gate's three local edits:
· F1: #36 restated as 0-hits with a calibrated instrument (git log -S empty-output artefact caught by a
  nonsense-token negative baseline; positive controls: -S mkEntityHasAspect reaches compat history,
  -S classSliceOf repo-wide → 21 commits) + the never-existed history + ★ THE TRANSCRIPTION ORIGIN FOUND:
  classSubtreeAt under a bare lib/compat/ prefix = EXACTLY 7 hits / 4 files — the stale "7" (and it does
  not reproduce the old cell either: 5 under the row's own glob; forwards.nix carries neither name; one
  hit is an error-message STRING not a comment). Both quote sites corrected. §1.1's self-description gains
  the new check class NAMED: STATED-VALUE DRIFT — a row is admissible only if re-running its command at
  HEAD reproduces its cell — with why the three existing sweeps are blind to it.
· F2: §4.4c's class restated (content-key surfaces: exactly ONE member, inject.class; reroute.from/.to =
  sibling relation-endpoint surfaces) + a disposition block for reach-edge.classFilter (membership test in
  conjunct (i)'s key space, not a mint), meta.__forward fromClass/intoClass (keys the EXEMPT set, not
  content), delivery.sourceClass/targetClass (requireEntry-checked registrations; a bare _-string cannot
  reach them) — all anchors read at HEAD, and the block STATES the dispositions are READ-DERIVED, weaker
  than the section's executed rows.
· F3: §14.4 edge-target row gains its non-vacuity condition (≥1 resolved aspect at T passing the filter) +
  a control that asserts the answer INCLUDES the T-sourced member (a bare non-empty check would be
  satisfied by H's own content).
· ★ TWO EDITS BEYOND THE NAMED LOCI, DISCLOSED BY THE AUTHOR: §14.2(f) and §4.4c's closing both quoted the
  retired three-member framing — left unedited they would contradict the restated class; both reworded
  minimally, neither carries a figure or verdict. Flagged for the gate rather than buried.
· NOT TOUCHED, VERIFIED: §1.1 rows 1-35 + order (table extracted and diffed against seq 1 36 — identical);
  all four must-not-regress sets (none in an edited region); headings 60/60; §5.4/§6/§7/§8/§10/§13/§16.
· Author's instrument self-corrections reported in the round record (the git wc-l artefact; a
  case-sensitive false alarm on the §4.3b heading; a table-bounds rescope).
NEXT: GATE ROUND 8 — dispatched. ROUND 7 COUNTED; A SECOND CLEAN ROUND EXITS THE GATE.

════ ★★ GATE ROUND 8 VERDICT: REVISE — COUNT RESETS TO ZERO (2026-07-31, fresh walled gate; register
rows re-executed across kinds incl. #25/#29/#30a/#35 by nix eval, ALL reproducing their cells — the
strongest evidence yet for the STATED-VALUE DRIFT rule) ════
S0 + C1/C1-a/C2/C3/C4/C5/C7/C7-a/C7-b/C8/C9 PASS · C6 FAIL (Finding 1).
· F1 ★★★ CONSTRUCTION, NEW POSITION REQUIRED — THE ROUTE/FORWARD DESTINATION COORDINATE UNDER Ρ IS NEVER
  ASKED THE RELOCATION QUESTION. §4.5 routes the SOURCE (route.from / spec.fromClass) through
  sourceOrderOf; the DESTINATION stays a literal string compare (`route.to == class` at
  output-modules.nix:699; `f.intoClass != class` at :653; lowerRoute's `to = d.targetClass.name`).
  CONSEQUENCE: reroute { from = D; to = E } at S vacates S's D elements (measured: outgoing → [ ]) while
  any route/forward destined for D keeps landing at D ⇒ projectClass S D holds route content at a
  coordinate the same scope's declaration says is vacated — ONE coordinate, TWO answers, selected by
  whether content arrived as an element or a placement: the §4.5a-rejected shape one layer down. LIVE
  INPUT: to = "home-manager" routes at projection-routes.nix:279/:315/:341/:664 +
  compat-migration-surface.nix:148 + the corpus hm-user-detect shape; §14's relocationMod is
  from = home-manager — ONE fixture-combination apart. ★ AND IT FALSIFIES §15.1's SHRINK QUANTIFIER: on a
  fleet whose cell is TARGETED by a home-manager route, the member does NOT vanish — it survives holding
  route content only (terminalModulesAt is the THREE-term sum). The ruling-bearing paragraph is stated
  without its quantifier. MISSING: §4.7 row, §8 row, §13 row, §15 open item. THE SEMANTIC DECISION (does
  Ρ(S) relabel a route/forward DESTINATION): §12's "a delivery has a target scope and is read where it
  targets" is the material — Ρ is Ch×Ch with no scope, deliveries are scope-targeted; the two principled
  readings are (i) one-declaration-one-answer: leaving destinations unrelabeled re-creates
  two-answers-per-coordinate, so Ρ relabels ALL coordinate references at the owning scope; (ii) Ρ
  relocates CONTENT (elements), while a placement target is a different TYPE (§12's asymmetry) and
  relabeling it silently re-aims a delivery someone declared against the un-relocated name. The decision
  is the author's, against theory, with the full enumeration either way. Method note: the doc's own
  fourth method applied one line above where r7 applied it.
· F2 INSTRUMENT — the line-12 "no line numbers" claim is false 34 TIMES, all from r6/r7 (all principal
  anchors RESOLVE at HEAD — discipline not decay, but it is the register's four-times-decayed class, and
  item 8's sweep is structurally blind to it). EDIT: cite by binding name (every one exists) or delete
  the sentence.
· F3 INSTRUMENT — §4.4e's exempt row miscounts its enumeration (13 reads: 2 membership + 11 pass-throughs,
  SEVEN in output-modules not four; conclusion unaffected — the 0-hit fixed-key measurement re-executed
  with its control reproducing 24).
· F4 STATED-SCOPE minor — the superset illustration is short by two (description, key also "structural").
★ r8-GATE POSITIVES (keep): every re-executed register row reproduced its cell; ★ STRATIFICATION checked
UNASKED and admissible (reach kind="circular" maps to stratum "resolution" = class-relocation's;
schedule's partition assert fires only on a STRICTLY LATER read — a real gap in the document's argument
that turns out safe — ADD IT as a stated discharge); ensureSeed conjuncts verbatim; artifactExclusive
short-circuit real; the reach-edge disposition correct by reading; #32's mechanism read-consistent
(rawSeedsAt's injection arm bypasses classifyKey entirely). Gate's unchecked rows stated: #14/#15
UNCHECKED (its predicate approximation did not converge); #26-28/#32-34 mechanism-read only; §14 unrun.
NEXT ROUND (r9): THE DESTINATION DECISION (new position, both readings weighed against theory) + F2/F3/F4
local edits + the stratification discharge. Count at ZERO.

════ ★★ REMEDY SPEC — REVISION 9 (2026-07-31, at 2e44ff5) — GATE ROUND 9 PENDING ════
r9 ARTEFACT: same path, FROZEN at md5 `cf8e0e2af865ddd4be5301f830cc4e2c`, 3570 lines (was 3182).
★ THE DESTINATION RULING TAKEN — READING (i): Ρ(S) RELABELS THE DESTINATION (new §4.5b/§4.5c). Grounds:
§12's asymmetry fixes WHERE each relation is read and its halves COMPOSE (a delivery names (T,C); Ρ(T)
says what C means at T) — (i) is §12 applied to the destination, (ii) leaves that coordinate governed by
NO scope; (ii) re-creates 4kh.41's shape inside ONE expression (routeRemapFor is an arm of
projectClassScoped — element arm answers VACATED, literal compare answers LIVE, same coordinate); the
readings differ in exactly ONE relation direction (outgoing, 4-cell table measured) and under fan-out (i)
reproduces the element arm exactly — a conservative extension where (ii) never reads the relation.
(ii)'s half-moved-coordinate hazard recorded as §16's rejection reason; what (ii) got right KEPT
(lowerRoute renders the DECLARED destination unchanged — forced, it serves two other consumers; the
relabel lives in the read at the target root). IMPLEMENTATION = the design's own primitive:
`builtins.elem route.to (sourceOrderOf result id class)` at all THREE compare sites (the enumeration
CLOSED: route.to ×2 — a SECOND site the verdict had not named — + f.intoClass; control: source-side
predicate → 5 same run); forwardModulesFor gains `id`. Two obligations discharged by derivation: no new
scope demanded (reach id already forces the memo at id) — REGISTERED AS A CONDITIONAL, the premise does
not exist at HEAD so it cannot be measured today, flagged as the first claim a future round re-derives —
and no schedule edge (output-modules declares no equation, grep 1 hit = comment).
★ §15.1 REPAIRED, not qualified: the three-term sum stated, shrink UNCONDITIONAL under (i); under (ii) the
member would survive holding route content and none of the author's — both cases in the ruling paragraph.
· F2 DISCHARGED BY CONVERSION (rule kept — a stale NAME answers 0 hits, a stale LINE cannot fail loudly):
  author measures 37 not 34 (predicate stated; all 21 distinct anchors resolve at HEAD — "discipline not
  decay" reproduced); 37 → 0 same predicate; all 11 replacement binding names verified in one run,
  negative control mkClassSliceZZ → 0.
· F3 13 reads = 2 membership + 11 pass-throughs (SEVEN in output-modules, 6 in class-modules); predicate
  in-row; 0/24 control re-executed.
· F4 by measurement: description AND key → "structural", refused, 0 fixed-key reads — the superset
  exceeds the census at TWO categories.
· STRATIFICATION DISCHARGE ADDED (§4.5c + register #40), ARMED: subject (reach circular→resolution reads
  class-relocation resolution) SCHEDULES; positive control same builder same run (declarations structural
  reads class-relocation resolution) THREW — the pass is a verdict, not an unarmed instrument. Corollary:
  a LATER stratum on class-relocation would break reach — §4.2's stratum choice load-bearing one way.
· DISCLOSED BEYOND THE LOCI: register #22 edited (its command now re-runs to 6 not 2 — use-vs-mention;
  "in coordinate position" qualifier added; the row was inadmissible as written); ★ the author's OWN new
  register #37 first stated a value its command does not produce — caught BY RE-RUNNING ITS OWN ROW
  (stated-value drift committed and caught inside one round); tooling deviation disclosed (two
  assert-guarded Python exact-match substitutions where Edit could not move text; no Write).
· PARTIAL: §14.7's five rows specified-not-run; r8's unchecked rows (#14/#15, #26-28, #32-34, §14) NOT
  re-taken (outside the order), still unchecked.
NEXT: GATE ROUND 9 — dispatched. Count at ZERO; a clean round starts the fresh count.

════ ★★ GATE ROUND 9 VERDICT: ACCEPT-WITH-CONDITIONS — NOT COUNTING, BY GATE JUDGMENT UPHELD BY THE
ORCHESTRATOR (2026-07-31; six nix evaluations incl. TWO native mkDen fleets; ~30 register rows re-executed,
all reproducing) ════
S0 + C1/C1-a/C2/C3/C4/C5/C7/C7-a/C7-b/C8/C9 PASS · C6 FAIL on one class. THE CONSTRUCTION — one
extraction, eval handle, memo+domain, declared-category refusal, structural-arm narrowing, AND §4.5b's
destination relabel — SURVIVED EVERY PROBE, including a verbatim re-derivation of the ruling's own
four-cell table (all cells reproduce; fan-out conservative-extension HOLDS; the conditional row's
derivation SOUND with every step now measured; T = id verified at all three build-path sites).
★ COUNTING ADJUDICATION: the gate flagged that on a literal reading this round found nothing in the
construction and could count; it recorded NOT-counting because Finding 1 is a false LOAD-BEARING
CONSEQUENCE in the ruling paragraph, not an instrument row. ORCHESTRATOR UPHOLDS: a ruling obtained on a
false consequence statement is corrupted; the exit rule's purpose is discounting instrument noise, not
consequence errors in the owner-facing contract. Count stays at ZERO.
FINDINGS, fix order for r10 (ALL named local edits, none a new position):
· F1 ★★ STATED-SCOPE LOAD-BEARING — contentIdsOf is a TWO-test conjunction (memberClassName id == name &&
  terminalModulesAt != [ ]) and the GROWTH claim swept one cell: an INCOMING relocation into a class the
  member is not REGISTERED as makes terminalModulesAt non-empty and adds NOTHING to systems.C. MEASURED
  at HEAD, native fleet, subject/control one declaration apart (den.contentClass.user = "home-manager" vs
  "nixos": same terminalModulesAt = 1; systems.nixos WITHOUT vs WITH the member). §13's row and §15.1's
  Growth paragraph state the consequence from one conjunct; §15.1's "and it is there" is FALSE on its own
  fixture — measured: after unification the cell's relocated module surfaces inside the HOST's system
  (classSubtreeAt axon 2 vs projectClass axon 1 today), systems.nixos membership UNCHANGED on both
  fleets. ★ THE OWNER RULING'S TRUE OBSERVABLE: a home-manager configuration DISAPPEARS from flake
  outputs AND ITS CONTENT IS MERGED INTO A NIXOS HOST CONFIGURATION — not "the content is there". EDITS:
  add the conjunct to §13 + §15.1-Growth; one sentence on WHERE the vanished member's content surfaces
  (the containment ancestor's projection) + membership-unchanged; §4.4d domain cell corrected
  (shrink/growth split — its own defect class, self-inflicted, inside the table built to catch it); a §14
  row pinning BOTH halves on the §15.1 fixture (membership unchanged AND host module count 1 → 2).
· F2 STATED-SCOPE — §8's destination invariant HAS NO DOMAIN: memberClassName is a naming of a channel
  coordinate at a scope, on the build path, NOT resolved under Ρ — correctly so (a class REGISTRATION,
  same type as delivery.sourceClass/targetClass), but nothing restricts the sentence. EDITS: domain
  "every naming of a channel coordinate as a CONTENT coordinate"; memberClassName joins §4.4c's
  out-of-scope list with its reason.
· F3 INSTRUMENT — #38 (and §4.5c's block) state gen-graph df7c893 where the lib-evaluating node is
  231b319 (every cell reproduces on 231b319 — value right, stated instrument wrong, #38's own rule
  applied to itself); #40's command names stratumOf, NOT EXPORTED (17-member surface re-enumerated) —
  values reproduce through (gen-resolve.lib.attr { … }).stratum + _buildSchedule. EDITS: both rows.
· F4 STATED-SCOPE — #37's second predicate returns FOUR not two; the one that matters: lowerRoute's
  `from = (if d.module != null then d.targetClass else d.sourceClass).name` — for a module-source
  delivery the route's SOURCE coordinate is the declared DESTINATION class name, resolved TWICE under two
  different Ρs (as `to` at the target root, as `from` at each element's owning scope — different scopes
  on the parent-targeted arm). Blast radius ZERO on compat's own construction (compile.nix sets
  sourceClass = toEntry when isModule, in-tree reason quoted); a NATIVE declare.delivery with A ≠ B makes
  it live, no row. EDITS: #37 cell = 4 all named; §4.5b table gains the lowerRoute-from row with the
  compat bound; §13's lowerRoute UNCHANGED row states what the non-change leaves in place.
★ r9-GATE POSITIVES: ~30 rows cell-for-cell; #26 reproduced; #10's control-is-zero correctly recorded as
cannot-match; the two-form §4.3 measurement; #25/#31 instance facts; C1-a's fan-out cell reproduced;
gen-resolve surface re-enumerated (17). NOT re-fired: #32-#35's sentinel runs (read-verified), §14, suite.
NEXT ROUND (r10): F1-F4, ALL LOCAL, surgical (r8 pattern: exact edits, re-run touched rows, disturb
nothing). Count at ZERO — a clean r10 starts the fresh count.

════ ★ REMEDY SPEC — REVISION 10 (2026-07-31, at 2e44ff5) — GATE ROUND 10 PENDING ════
r10 ARTEFACT: same path, FROZEN at md5 `168943617caa7251dbc6d1c541f17599`, 3656 lines (+86; 21 exact-match
Edits with replace_all=false — a non-unique target would have ERRORED, all succeeded ⇒ each matched once).
· F1 APPLIED, 4 sites, with the DECISIVE MEASUREMENT — a 4-arm native fleet (contentClass.user
  home-manager/nixos × reroute present/absent, one declaration apart): content presence HELD FIXED at 1
  while systems.home-manager moves [cell] → [ ] ⇒ the memberClassName conjunct ALONE decides membership;
  classSubtreeAt axon nixos = 2 vs projectClass = 1 (the 1→2 oracle); systems.nixos = ["host:axon"] on
  EVERY arm (membership-unchanged measured, not derived). §15.1's false "and it is there" DELETED; the
  WHERE paragraph added (containment ancestor's projection); the true observable in one sentence. §4.4d
  gains a FIFTH question (a cited CONJUNCTION must have every conjunct discharged). §14.1 gains
  test-relocation-vanished-content-lands-in-the-host with a green-at-HEAD half and a red-at-HEAD half —
  a change that merely deletes the cell passes (a) and fails (b).
· F2 APPLIED: "AS A CONTENT COORDINATE" domain at both sites; memberClassName the 4th §4.4c bullet
  (MEASURED not read — the preamble corrected from "all three read-derived" to "three of the four", the
  count that would otherwise have been false); unprompted precision fix disclosed (three-of-four bullets
  phrasing, meta.__forward named as INSIDE the domain via intoClass).
· F3 APPLIED with corroboration: #38 + §4.5c → 231b319 (root input rev measured by nix eval; the doc
  already said 231b319 in FOUR other places — the two outliers fixed; df7c893 survives only in #38's own
  correction note, grep 1); #40 re-run through the EXPORTED form — SUBJECT SCHEDULES / CONTROL THREW same
  run; the 17-member gen-resolve surface matches §6.3 cell-for-cell; ★ DISCLOSED EXTENSION: §4.5c's
  fenced block + prose ALSO named stratumOf/buildSchedule as executed — corrected to the exported form
  (values unchanged), the F3 defect class inside an executed block. #38's four cells RE-RUN on 231b319 by
  the author, every cell reproducing with the run echoing its own genGraphRev.
· F4 APPLIED: #37 second predicate = FOUR (324 trace-source, 335 trace-target, 356 lowerRoute-from, 357
  lowerRoute-to; the live three of predicate 1 confirmed disjoint); line 356 quoted verbatim; the compat
  bound read at compile.nix:276-302 and its in-tree reason quoted VERBATIM; the live case stated as an
  UNWITNESSED LIVE SHAPE (native delivery, sourceClass ≠ targetClass, non-null module; P=0), not a no-op.
· NOT TOUCHED verified structurally + spot-checked byte-for-byte (#1/#9/#36/#43/#39); §14.2-§14.7, §9-§12,
  §16, §4.7, §8's or-table, §5-§7 untouched; §4.5b's table +2 rows and one label rename, none removed.
· LIMITS: §14.1's new row specified-not-run (both halves' HEAD values measured; the row not executed as a
  test); arm B/D's systems.nixos growth DERIVED (design unimplemented) and stated as such; §14.7/§14.6/
  suite/r8-r9 unchecked rows not re-taken (outside the order).
NEXT: GATE ROUND 10 — dispatched. Count at ZERO; a clean round starts the fresh count.

════ ★★ GATE ROUND 10 VERDICT: ACCEPT-WITH-CONDITIONS — NOT COUNTING, COUNT RESETS (gate recommendation
UPHELD by the orchestrator on the gate's own grounds) (2026-07-31; 27 register rows re-executed, 25
reproduce exactly; 6 original probes incl. a NEW native-fleet construction) ════
S0 + C1/C1-a/C2/C3/C4/C5/C7/C7-a/C7-b/C8/C9 PASS · C6 FAIL (F1).
· F1 ★★ CONSTRUCTION-GRADE CONSEQUENCE ERROR, THE MIRROR OF ROUND 9's: §15.1's SHRINK derivation reads
  the PROJECTING scope's memo ("sourceOrderOf id C = [ ] so classSliceAt concatMaps over the empty list
  at every reached element") where classSliceAt reads THE ELEMENT'S OWNING scope — and the document
  states the correct mechanism in four other places INCLUDING §15.1 ITSELF ~50 lines later.
  MEASURED (native fleet, reroute nixos→darwin at the HOST ONLY, working policy construction
  `fn = { host, user ? null, ... }: if user == null then acts else [ ]`): classSubtreeAt axon nixos =
  [nixos-FROM-CELL] — the member SURVIVES holding the cell's un-relocated element where §15.1 says it
  disappears. Positive control: host's own content moved to darwin. Negative control: both-scopes Ρ → [ ].
  ★ The measurement also settles undocumented ground: §14.3's fixture ("reroute fires only at the host")
  IS constructible, and on it §14.3's assertion and §15.1's derivation contradict — §14.3 CORRECT.
  THE CLASS = FIVE SITES, one sentence shape, uniform error direction (over-claims emptiness; admission
  cells safe): §15.1 term 1; §4.7 rows 7 and 12b + §8's two seed rows; §16's rejection ground (c).
  NAMED EDITS: quantify term 1 over the reach's OWNING scopes with the enabling condition STATED (the
  §15.1 fixture's policy fires at every subtree scope, so the two coincide THERE); "unconditional" →
  "unconditional in terms 2 and 3, quantified in term 1"; same quantifier at the four sibling sites;
  restate §16(c). DISCHARGE THE CLASS.
  COUNTING GROUNDS (gate's, upheld): no command misquoted, no mechanism misattributed — a statement of
  WHAT THE SYSTEM DOES, false on a constructed measured input, in the ruling paragraph, with the enabling
  condition NOWHERE STATED — an unscoped falsehood the corpus happens not to exhibit, the same reason
  4kh.41 sat latent. Against (stated honestly): true on the fixture and on any fleet whose relocation
  fires subtree-wide; P=0 today; strictly read STATED-SCOPE.
· F2 INSTRUMENT — #22 drifts again ON THE ANTI-DRIFT ROW: 7 occurrences not 6; the second
  coordinate-position use is §16 not §14.5. Substantive claim holds. EDIT: both cells.
· F3 INSTRUMENT — ONE line anchor survives #43's predicate: §4.5a's bare `(the v1 :97-101 surface)` —
  no filename prefix, matched by neither predicate; an anchor into a file the doc never names. Sole
  survivor of a full `:NNN(-NNN)` sweep. EDIT: drop it (the sentence already names the surface); widen
  #43 to backticked `:[0-9]`.
· F4 STATED-SCOPE — §4.4e short under its own predicate: §4.3b's code block mints
  `back = genAttrs (reachableFrom frame.rev c) (_: true)` — author-written channel names as keys, absent
  from the seven rows (safe by rows 6/7's justification, and its safety argument IS on the page — the
  table's own r9 rationale demands the row). EDIT: one row.
· F5 INSTRUMENT minor — #26's command uses a LITERAL in dynamic position (parse-time message) while the
  cell quotes the computed-key message; the quoted message IS correct on the at-risk path (verified both).
  EDIT: computed key in the row's command.
· SCOPE NOTE recorded: rows #5/#14/#15/#18/#31 carry prose descriptions, not runnable commands — the
  STATED-VALUE-DRIFT rule's domain is narrower than the table; honest as written.
★ r10-GATE POSITIVES: 25 rows cell-for-cell; the keyCategory instance finding EXACTLY right (both
instances built; kindNames provably irrelevant); §4.5c ARMED same run; #38's four shapes on 231b319;
EVERY fleet measurement reproduces; ★ §4.5's "every element carries scope = id by construction" and
§9.3's "class-seeds fire set: id alone" BOTH HOLD (both forwardExpand call sites checked — the
cross-scope comment refers to the FOLD's dedup) — load-bearing for §9.3 row 3 and stated nowhere; KEEP.
Reusable native fleet at scratchpad/fix.nix.
NEXT ROUND (r11): F1's five-site class + F2/F3/F4/F5, all local, surgical. Count at ZERO.

════ ★ REMEDY SPEC — REVISION 11 (2026-07-31, at 2e44ff5) — GATE ROUND 11 PENDING ════
r11 ARTEFACT: same path, FROZEN at md5 `0469fd55173a1a44a75fb7de64028aac`, 3716 lines (17 exact-match
Edits, no deviations).
· F1 — ★ THE CLASS WAS SIX SITES, NOT FIVE: the author's pre-edit lexical sweep found §13's ensureSeed
  FIRING row ("placed is empty at every reached node" — same shape, same over-claims-emptiness direction)
  beyond the gate's five, plus a weaker seventh inside §15.1's reading-(ii) sentence; and CORRECTED the
  order (§8 carries ONE seed row in the class, not two — its others are safe admission cells). All
  discharged with the quantifier + the enabling condition, which is ALREADY IN THE TREE and now cited:
  projection.nix:134's comment ("declared at every scope carrying the host coordinate — the projecting
  host AND the descendant cell"). Measurement re-run on a REBUILT fleet (two same-class elements with
  DIFFERENT owning scopes): baseline [T-HOST,T-CELL] / host-only [T-CELL] (THE FINDING — member survives)
  / every-scope [ ]; positive, negative AND fold-input controls (HEAD's relocation-blind projectClass
  constant across rows ⇒ only the per-element sourceOrderOf differs). The optional-arg policy form
  documented (a wider destructure fires at the cell too — fix.nix's own relocationHostOnly would NOT have
  produced row 2). §14.3 confirmed not-yet-built with a firing control; recorded as the side that was
  CORRECT. §16(c) restated with the quantifier noted as a property of the REACH, identical under both
  readings ⇒ the rejection of (ii) NOT weakened. Post-edit class sweep: 0 survivors; positive control 5
  quantified replacements present.
· F2 — #22: 7 occurrences (r9 counted LINES); uses 2 (§10 entry 1, §16 — NOT §14.5). ★ Self-inflicted
  drift caught in-round: the first edit quoted the label, pushing the count to 8; re-measured, reworded;
  the cell now flags itself as self-referential.
· F3 — the sole surviving bare anchor dropped; #43 widened; ★ second self-reference trap caught (quoting
  the anchor in the cell made the predicate answer 3); the control moved to a PLANTED scratch file
  exhibiting the widened-vs-narrow asymmetry rather than asserting it. Final: both predicates → 0 over
  the doc.
· F4 — §4.4e row added for §4.3b's `back` mint (safe: one reader, dynamic); counts 5→6 / seven→EIGHT
  forced by the drift rule and verified; a FOURTH miss-reason recorded (the section was outside the
  sweep's domain — the design's one non-verbatim change).
· F5 — #26's command now computed-key, producing exactly the message its cell quotes; the literal form's
  parse-time message documented as the different one; at-risk path confirmed computed.
· NOT TOUCHED: admission cells byte-identical; §15.1's cell-fixture paragraph byte-identical (correct —
  leaf scope, coincidence trivial); §4.5a's correct-mechanism statement byte-identical (served as the
  positive control that the doc already knew the rule).
· DISCLOSED LIMIT: projectClassScoped is NOT exported from den.output (r11f1c.nix failed probe) — the
  owning-scope read cannot be measured DIRECTLY on a native fleet; the oracle is Consumer A
  (classSubtreeAt, relocation-aware at HEAD) with the fold-input control bounding the inference, LABELLED
  as such in the document.
NEXT: GATE ROUND 11 — dispatched. Count at ZERO; a clean round starts the fresh count.

════ ★ GATE ROUND 11 VERDICT: ACCEPT-WITH-CONDITIONS — NOT COUNTING (upheld) (2026-07-31; 26 rows + 6
probes + 4 native-fleet families on the gate's OWN fleets; a 19-name wider keyCategory sweep found NO
missed member) ════
S0 PASS-with-drift · C1-C5/C7/C7-a/C7-b/C8/C9 PASS · C6 FAIL in the STATED SCOPE.
· F1 STATED-SCOPE (construction-describing) — §4.4b conjunct row (ii) states "rejects: NOTHING / at HEAD:
  n/a": FALSE BOTH CELLS. Conjunct (ii) (`content ? ${class}`) IS the REPLACEMENT for HEAD's explicit
  `builtins.filter (a: className a.class == d) injects` — it rejects the element at every source channel
  it does not hold (exhibited verbatim: rawSliceOf U inj "nixos" → 0 / inj "X" → 1, controls
  discriminate), and the two predicates are NOT extensionally equal at d="name" (the minted name STRING
  returned as a module when "name" ∈ exempt — reachable: reroute from="name" is ADMITTED, measured inert
  on a fleet; closed by conjunct (iii) + row 1c, NOT by (ii)). §4.7 therefore carries NO row for the
  (injection element, conjunct (ii)) gate — suppressed by the "n/a". Mechanism verified CORRECT; the
  statement of what it does is wrong. NAMED EDITS: row (ii) restated as the filter's replacement with the
  d="name" non-equality; the §4.7 row with BOTH cells; the name-key non-equality as a third §16 ground.
  COUNTING: not-counting upheld — a false statement of what a construction gate does, on the routine
  input the design serves, suppressing a closure row (the gate's borderline note recorded: §4.4b's own
  header names input classes, not deltas, and "n/a" is what hid the substitution).
· F2 INSTRUMENT SELF-REFERENTIAL — #43 cites its own subject BY LINE NUMBER ("§1 line 12's claim") inside
  the row that measures line anchors and reports 0; both its predicates backtick-scoped, blind to prose
  anchors (prose predicate → 2: the row's own cell + a non-anchor explanatory line as the same-run
  control). EDIT: name the claim by its words; widen the predicate with the exclusion named.
· F3 INSTRUMENT — #24's census blind to `inherit (content) name id_hash` (resolved-settings.nix entryOf) —
  a FORM gap not a domain gap (control: the predicate reproduces 24/6 exactly); conclusion unaffected
  three independent ways. EDIT: add `inherit (content)` + attrNames to the command; state the totality
  rests on the category predicate.
· F4 INSTRUMENT — S0's tracker cell drifted: 4kh.41 is in_progress (the orchestrator's claim at
  dispatch), cited as "OPEN at P0". Benign direction; three neighbouring citations reproduce. EDIT: one
  word.
· COVERAGE OBSERVATIONS (not findings): legacy/forwards.nix synthesizeProducer is a destination-class
  coordinate outside §4.4c's closed enumeration — but exported-unreached (callers only in
  projection-routes fixtures), domain claim survives; §13 doesn't say class-seeds' readsAttrs should DROP
  "declarations" after §4.5 moves acts into the memo — sound either way, declared-dep-no-longer-read.
★ r11-GATE POSITIVES: 22 register rows cell-for-cell; #36 on its STRONGEST form (byte-identical to
nonsense baseline + two firing history controls); #25/#30a/#42 re-taken on rebuilt instances with a
19-name WIDER sweep — NO missed member (imports traced through the whole conjunction: collides with
nothing, rawSliceOf peels content.${class} never the element's content); #26 both messages verified on
both forms; three fleet families on the gate's own fleets (#32 + its one-declaration control; _spool;
empty-inject); §9.2's derivation COMPLETE over both suites; Ground 1's T=id verified against both route
arms; guardHolds class-agnostic; all 11 replacement anchors resolve.
NEXT ROUND (r12): F1-F4, all local, surgical. Count at ZERO. ★ ORCHESTRATOR TRAJECTORY NOTE: r9/r10 found
false FLEET OBSERVABLES; r11 found a mis-described cell of a verified-correct gate — the findings are
narrowing toward the document's self-description. If the r12 gate again resets on a consequence-class
item, the track HOLDS with state banked (the design-track pattern) rather than iterating further this
session.

════ ★ REMEDY SPEC — REVISION 12 (2026-07-31, at 2e44ff5) — GATE ROUND 12 PENDING (DECISIVE PER THE
TRAJECTORY NOTE: a consequence-class reset here HOLDS the track this session) ════
r12 ARTEFACT: same path, FROZEN at md5 `ff2d99ba1608ddfdd25374f0eb746f87`, 3737 lines (9 exact-match Edits).
· F1 landed with 4 ordered + 4 FORCED edits (disclosed): the forced set found THE SOURCE SENTENCE — §4.4b's
  intro said HEAD's arm "applies NONE of them. Every one is therefore a new gate" WHILE QUOTING the
  builtins.filter that refutes it (now "three of the four as new gates" + the fourth identified as the
  quoted filter; flagged in-doc as §4.4d's own class turned on this section); §4.7 domain para +
  consumer table + row 12's "exactly" all corrected for the new row 1d. Probes on HEAD's REAL EXPORTED
  classSliceOf: conjunct (ii) and HEAD's filter answer 0/1 CELL FOR CELL with two-direction controls; the
  d="name" non-equality measured end-to-end (exempt built by HEAD's own forwardSourceClassesOf from a
  meta.__forward fromClass="name"; yield = the minted STRING); reroute from="name" ADMITTED + INERT on a
  native fleet with a moving control; §16's third ground measured BOTH directions same reader same exempt
  same run (design mint yields a string, the alternative mint yields THE USER'S MODULE; controls 0/0 ⇒
  the difference is the MINT).
· F2: #43's cell names the claim BY ITS WORDS; predicate widened with the prose form; after-edit sweep
  0/0/1 exactly as the cell now states (before-edit 2 — the removed match WAS the cell); planted-file
  control exhibits all three predicates firing.
· F3: #24 widened to four forms — NET +3 sites, +0 names (inherit(content) site's both names already
  census members; attrNames sites are the dynamic enumeration already recorded) ⇒ form gap confirmed;
  totality restated on the category predicate.
· F4: S0 cell corrected to in_progress (verified by command); the neighbour citation CHECKED rather than
  assumed (4kh.16 reproduces verbatim, not edited).
· JUDGMENT CALL FLAGGED by the author: §14's acceptance-axes sentence "(rows 1, 1a, 1b)" left
  byte-identical — 1d is a no-behaviour-change stream needing no acceptance axis, reason recorded inside
  row 1d. Orchestrator accepts the judgment; the gate may test it.
· LIMITS: row (ii) equality read off the two predicates, measured at three channels not all six fixed
  names; d="name" reachability measured through reroute only; probes a/b/d use a hand-built classifyKey
  registering {nixos,X} (sound — (ii) precedes classifyKey; probe c carries the native answer).
NEXT: GATE ROUND 12 — dispatched. Count at ZERO.

════ ★★ GATE ROUND 12 VERDICT: REVISE — NOT COUNTING, NOT BORDERLINE — AND THE TRACK HOLDS HERE THIS
SESSION (the recorded trajectory-note trigger fired) (2026-07-31; 23 register rows re-executed, all
reproducing; four native fleets; HEAD's real classSliceOf driven at four channels with controls) ════
S0 + C1/C1-a/C2/C5/C7-a/C7-b/C8/C9 PASS · C3/C4/C6/C7 FAIL. FINDINGS, fix order for r13:
· F1 ★★★ CONSTRUCTION — THE SCHEMA-CLAIMED-KEY REFUSAL SITS AT THE MINT, NOT AT THE READ. reroute's
  `from` becomes rawSliceOf's `class` argument (the key looked up in content.${class}); row 0 refuses that
  key space only inside injectionElementsAt; relOf's own header: "No validator rejects an unregistered
  endpoint … the wide domain is in-domain". MEASURED (memo + classSliceAt verbatim, exempt built by the
  kernel's own forwardSourceClassesOf): reroute from="settings" delivers the settings FACET ATTRSET as
  class content; from="name" + a forward naming it delivers TWO ASPECT NAME STRINGS as modules — every
  downstream consumer expects a deferredModule; both conjuncts required, each control discriminating.
  AT HEAD this reaches Consumer A only; AFTER §4.3/§4.5 classSliceAt loops the source order per element ON
  THE BUILD PATH (projectClassScoped → terminalModulesAt → bindAtSourceScope, read at HEAD — the gate's
  stated limit: extraction-level exhibit, not a drv measurement). §4.7 has NO row (its aspect-side rows
  cover the ANSWER, the guard, the destination — not isCollectable at a schema-claimed SOURCE channel).
  NAMED EDIT, no new position (derivable from §4.4b's own every-key-space argument): apply row 0's
  predicate at the READ (skip/refuse d when keyCategory d ∉ {class, null} in classSliceAt/sourceOrderOf) OR
  refuse reroute's endpoints at the same position; §8 violation row; §4.7 row; §4.4c's class becomes two
  members. Blast radius bounded by the same P=0 structural derivation as the parent.
· F2 STATED-SCOPE — §4.4c's "exactly ONE member" used the WRONG PREDICATE for its own class name (minted-
  attrset test vs becomes-a-content-KEY — reroute.from becomes a content-key SELECTOR). Absence with
  control: keyCategory ×46 and reroute ×94 in the doc, ZERO lines mention both.
· F3 CONSTRUCTION-ADJACENT false consequence — "that cell is closed twice" is false: row 1c refuses the
  DECLARED channel, cannot close a READ at d="name" of an element declared at an admitted channel;
  measured 1 slice with exempt, 0 without ⇒ ONE closure (conjunct iii), the one the row's own sentence
  says exempt opens. EDIT: single closure + priced residual.
· F4 CONSTRUCTION-ADJACENT — §16's THIRD GROUND (an r12 edit) is INVERTED: row 1c's predicate reads the
  DECLARED CATEGORY, independent of the mint, so the alternative's refusal stands; and at the same
  channel/reader/exempt/run the alternative mint yields 0 slices where the design's yields the string —
  STRICTLY SAFER at the cell the ground is about. §16 survives on grounds (i)/(ii). EDIT: withdraw (iii);
  add a §5.4 second-table row (an effect attributed to a refusal whose predicate does not depend on the
  mint).
· F5 INSTRUMENT minor — #19's tail: 2 non-kernel hits are ci comments, neither writer nor guard.
★ r12-GATE POSITIVES: §4.5c ARMED (control throws same run); #25/#30a instance findings load-bearing and
right; 23 rows cell-for-cell incl. #26 verbatim with containment class; both fleet families reproduce
(§14.1 row 3 + §15.1 measured block; the growth conjunct one-declaration pair); §15.1's enabling condition
verbatim in-tree; the project-arm non-move C7-correct; §4.3's named abort is what converts §5.1's residual
omission→commission; §4.5b's ruling + domain bound grounded.

★★★ ORCHESTRATOR HOLD (2026-07-31): TWELVE ROUNDS RECORDED IN THIS BODY; THE TRACK PAUSES HERE THIS
SESSION per the round-11 trajectory note. State: artefact FROZEN at ff2d99ba1608ddfdd25374f0eb746f87
(3737 lines, UNCOMMITTED in papers); exit count ZERO; r13's work order = F1-F5 above (every edit named, F1
derivable from the document's own argument). The CONSTRUCTION'S CORE (one extraction, eval handle, memo,
category refusal at the mint, structural-arm narrowing, destination relabel) has survived six consecutive
gates' probes; the open items are the READ-side application of the refusal and two consequence statements.
WHAT A RESUMED ROUND INHERITS: this verdict + the r11 positives + all four must-not-regress sets.

════ ★ REMEDY SPEC — REVISION 13 + RULING SUPPLEMENT (2026-07-31, session 3, at f631973; lib/ci/flake byte-identical to 2e44ff5 — verified `git diff --quiet 2e44ff5..f631973 -- lib/ ci/ flake.nix flake.lock`) — GATE ROUND 13 PENDING ════
r13 ARTEFACT: same path, FROZEN at md5 `44d7590c763d2f6b15deb7c89c7484cf`, 4058 lines (r13 edits +253, ruling supplement +50, alternatives-table delta +18; every freeze double-sampled; intermediate freezes 938f4e46/d2b6cb4c superseded same-day by supplement crossing).
· ★★★ §15.1 OWNER RULING OBTAINED (2026-07-31): RATIFIED — declare.reroute/inject REACH THE BUILT SYSTEM, owning-scope reading, measured shrink/growth accepted as-is, no loud-shrink variant. Incorporated at 11 ruling-status sites + 3 adjacent-class disambiguations (closing sweep predicate 0-after with 19-hit `owed` control, all read); §15.1 carries the THREE-ARM ALTERNATIVES TABLE — plain ratification CHOSEN, ratify+loud-shrink REJECTED, introspection-only REJECTED — rejection reasons deliberately not supplied (owner's to give), replacing a false 'no loud-shrink variant was asked for' claim; §15.1 now also NAMES THE FOUR QUESTIONS ON THE SAME SURFACE THE RULING DOES NOT REACH (the two refusals, empty-injection drop, key-space closure, §15.7 Ρ fan-out — each still owed) so the OBTAINED heading cannot over-read. §1 item 4 kept in place (positional references); §14.3 stays vacuous at HEAD — a ruling fixes the wanted arm, not the row.
· F1 ARM: READ-SIDE (arm a) — refusal (not skip) in `sourceOrderOf`, inside the ONE extraction. Reason: meta.__forward's fromClass reaches rawSliceOf's class argument with NO reroute in the fleet (measured) ⇒ endpoint refusal cannot close the class; both paths funnel through sourceOrderOf. Class enumerated: (A) preimage members = reroute.from; (B) spec.fromClass at forwardModulesFor's srcSlices = what forwardSourceClassesOf puts in exempt. reroute.to derived out (no outgoing edge ⇒ enters no preimage but its own).
· ★ AUTHOR REFUTED ONE r12 EXHIBIT, WITH MEASUREMENT (recorded in-doc #44/row 3a, not silently complied): «reroute from="settings" delivers the settings facet» is FALSE for the reroute ALONE — classifyKey "settings"="facet"≠"class", conjunct (iii) refuses; measured through HEAD's real class-seeds.compute: reroute-only = byte-identical to baseline; the delivery needs a meta.__forward opening exempt (ONE declaration — path B, the path endpoint refusal cannot reach). F1 SURVIVES STRONGER; r13 gate adjudicates this correction.
· F2: §4.4c predicate fixed (becomes-a-content-KEY), 3-member class table + 2-key-space disposition table. F3: single closure + priced residual (#45: exempt→1 slice=STRING, none→0). F4: §16 ground (iii) WITHDRAWN (#46: alternative mint 0 where design's yields string — strictly safer at that cell); §5.4 second table +2. F5: #19 re-run 20 lines/6 files, old cell had collapsed TWO compat predicates into one.
· §4.3 snippet EXECUTED VERBATIM: admits [nixos]/[nixos,spool]/[nixos,_u]/memo-miss "user"; refuses [nixos,settings]/[nixos,name]/memo-miss "settings"; elem over a refusing order still throws (strictness measured); tryEval-containable.
· REGISTER: +#44/#45/#46; #22, #43, #9 (994), #10 (0) re-run cell-for-cell; item-8 anchor sweep on every new token, negative control 0.
· MUST-NOT-REGRESS all checked: §4.5c armed (4 refs), 23 rows cell-for-cell (#19 mandated change only), §15.1 measured blocks untouched, construction core all six intact — the mint refusal is JOINED by the read-side position, not moved.
· LIMITS: extraction-level measurements via internal.classModulesBuilder + real class-seeds (no drv, no suite run, no native fleet this round); in-tree endpoint sweep bounds the FIXTURE corpus only (single-line literal predicate) — stated in §9.2/#44. §14.2(h)'s four rows SPECIFIED-NOT-RUN (two blocked on §7 item 6 harness migration).
NEXT: GATE ROUND 13 — dispatched. Count at ZERO (r12 was REVISE). New surfaces the gate should probe first (author-flagged): §4.3's refusal now fires from §4.5b's destination read too (one declaration refuses from both arms); the four (h) rows.

════ ★★ GATE ROUND 13 VERDICT: REVISE — COUNT RESETS TO ZERO (2026-07-31, session 3; reviewed md5 44d7590c763d2f6b15deb7c89c7484cf echoed; S0 PASS after a crossed-freeze hold correctly refused at the stale anchor; C6 FAIL via F1 only, all other checks PASS) ════
· ★★★ ITEM-2 ADJUDICATION: THE AUTHOR'S REFUTATION OF r12 IS CORRECT — r12's F1 exhibit RETRACTED BY THE GATE. Independently measured through real class-seeds.compute + real classifyKey, two-factor: reroute-only == baseline (TRUE), forward-only == baseline (TRUE), forward+reroute delivers the facet attrset (FALSE). Path B independently confirmed on output-modules.nix:659's srcSlices over real classSliceOf with NO reroute: exempt(fromClass=settings) delivers the RAW facet, controls 0/0 and registered-nixos discriminating. AN ENDPOINT REFUSAL CANNOT SEE PATH B — the read is the only total position; the r13 arm choice is verified, not trusted.
· F1 (CONSTRUCTION-ADJACENT, the count-resetting finding): §4.4c's CLOSED ENUMERATION IS SHORT ONE MEMBER — den.classes.<name>, the class REGISTRATION surface (creates the content key; reaches rawSliceOf's class argument as the query channel via class-seeds genAttrs classNames + projectClassScoped). LIVE: 17 corpus files declare den.classes.* (control den.aspects 994). THE COLLISION MEASURED: keySemantics = mkClassChannelSemantics // mkFacetSemantics — facets RIGHT, override same-named class; SIX colliding facet names (artifact excludes neededBy projects settings tags); fleet declaring den.classes.settings: AT HEAD class-seeds collects SILENTLY EMPTY {"settings":[]}; UNDER THE DESIGN sourceOrderOf c="settings" THROWS (a fleet evaluating at HEAD aborts under the design). §4.3's EXECUTED block already exhibits the cell but attributes it to "the forward path" — this is a THIRD trigger needing neither reroute nor forward; §13 has no row. P=0 measured (none of the six declared in corpus, per-name grep 0 with live control). Counting per standing adjudication: closure claim is load-bearing (bounds the refusal's domain) and is the same claim F2 already corrected once (one→three; now three→four) ⇒ RESETS.
  NAMED EDITS for r14, all local, no new position: (1) §4.4c fourth member with two-key-space disposition (_-prefixed ⇒ registered-but-inert via conjunct (i); schema-claimed ⇒ the six collide, keyCategory answers facet, §4.3 refuses the QUERY CHANNEL ITSELF); (2) §13 break row (declared class named one of the six: silently-empty → named abort); (3) §4.3 EXECUTED block's memo-miss "settings" row names its third trigger. PLUS carry: route.from's disposition ground is a non-sequitur for the schema-claimed space ("bare _-prefixed string cannot reach them" covers only the _-space) — it survives because the name is a registration; the same edit should carry that reason.
· ITEM 1: §4.3 sourceOrderOf verbatim rows ALL REPRODUCE on real keyCategory (admits/refuses/strictness/containable + named-abort message matches the doc's MESSAGE row exactly); §4.4b row 0 predicate ≡ §4.3 filter (identical); §4.5b destination arm genuinely routes through it — one declaration refuses from both arms, measured.
· ITEM 3: #45 ONE closure CONFIRMED; §16 survivor grounds (i)/(ii) both hold in-tree; #46 reproduces — ground (iii) withdrawal correct, alternative strictly safer at that cell. Gate's own instrument error reported and repaired (assertedClasses missing from its first fixture — cells were right).
· ITEM 4: §14.2(h) honestly presented; rows 1-2's blocking claim TRUE (class-relocation.nix's hand-built classifyKey has no category surface); rows 3-4 runnable (projection-routes imports real concern-aspects).
· ITEM 5: ruling edits — NO OVER-READ. Alternatives table invents no owner reasons (arm 2 bare REJECTED); arm 3's aoh consequence derived at §9.3/§4.7 row 11/§13/§14.4; four not-reached questions still owed at their own sites; §9.1/§1 item 3 explicitly anti-over-read.
· ITEM 6 / REGISTER: #22 7✓ #43 0,1✓ item-8 0✓ #9 994✓ #10 0 with gate-supplied positive control den. → 1185✓ #44-46 reproduce✓. MUST-NOT-REGRESS: all four sets HOLD (9 of 23 rows re-run; 14 not re-run — stated).
· ★ SEPARATE KERNEL DEFECT (not this design's): a declared class colliding with the facet vocabulary is SILENTLY DEAD AT HEAD — filed as its own bead (see den-hoag graph, facet-collision bead, filed this session).
· GATE LIMITS: extraction-level only (no drv/suite/native fleet); forwardModulesFor fold transcribed verbatim (unexported let-binding); C1 academic provenance not re-opened this round; owed-control 20 vs 19 = expected supplement drift.
NEXT: r14 — F1's three named edits + route.from ground carry. COUNT AT ZERO. r14 QUEUED behind the papers-repo writer slot (ops-seam round 4 in flight).
· GATE r13 SUPPLEMENT (same round, verdict unchanged): the +18 ruling delta reviewed AS CONTENT — no construction leakage (loud-shrink mechanism grep 3 hits all status, control 'shrink' 21; §9.1 L2637 and §1 item 3 anti-over-read corroborate); item-5 (a)/(b)/(c) all discharged — no invented owner reasons (arm 2 bare REJECTED), arm 3's grounds verified against the BEAD not just the doc (this body's own "explicitly NOT recommended" line + aoh derivation at four sites), four not-reached questions still-owed at their own sites, fork cross-link consistent. ★ GATE'S TESTIMONY LIMIT, CLOSED BY THE ORCHESTRATOR AS WITNESS: "the owner chose among three arms" is true — the orchestrator presented exactly plain-ratification / ratify+loud-shrink / introspection-only via direct owner question on 2026-07-31 and the owner selected plain ratification; the artefact's account matches the event. The doc's own #10 instrument warning confirmed correct as written (gate's den. → 1185 control agrees).

════ ★ REMEDY SPEC — REVISION 14 (2026-07-31, session 3, at f631973) — GATE ROUND 14 PENDING (count at ZERO; a clean construction round moves 0→1) ════
r14 ARTEFACT: same path, FROZEN md5 `a513464d143107889367fecc66923c9d`, 4165 lines (+107). Orchestrator double-sampled.
· DOMAIN RE-DERIVED INDEPENDENTLY — NO FIFTH SURFACE; the domain EXPRESSION is now in §4.4c so the next gate checks domain not count: provenance of the class arg at every production call site of the one extraction + the key the injection arm mints. Four call sites (rawSeedsAt via genAttrs classNames + relOf's node domain; remapOver route.from off requireEntry-validated entries; forwardModulesFor spec.fromClass; projectClassScoped via the class registry) ⇒ union {registration, reroute.from, reroute.to, inject.class, fromClass}, reroute.to derived out ⇒ FOUR members; three of four call sites take a REGISTRATION — stated as why registration is one member, with delivery.sourceClass/targetClass/memberClassName collapsing INTO it.
· ALL GATE-r13 COLLISION FACTS REPRODUCED with a discriminating control the gate lacked: declared non-colliding class `mine` classifies "class" / undeclared "facet" ⇒ the instrument registers declared classes, ONLY collision suppresses; colliding name IS a memo key collecting silently empty.
· EDITS: §4.3 trigger-3 relabel + derivation; §4.4c four-member table + collision para + den-hoag-39x separation (design's abort improves the SYMPTOM; real fix = refusal at REGISTRATION, upstream, this design does not close it); §13 new break row (the only row whose HEAD behaviour is neither delivery nor abort); route.from carry ground repaired (requireEntry admits only id_hash-carrying entries generated over effectiveClassNames ⇒ always-registered ⇒ collision case is member four's cell, not a fifth member).
· ★ TWO UNREQUESTED REGISTER CORRECTIONS, flagged loudly, both pre-existing, both found by the mandated #22 re-run: (a) #22's "all but one: §2.2" FALSE at HEAD — a second dangling ref `§2b` at §5.3's opening resolves to no heading (r13-gate's "7✓" verified the FIGURE not the claim); cell now "all but TWO", second named by words. (b) #22's own breakdown carried a stale bare `L27` anchor invisible to all three #43 predicates — a live instance of the class #43 catches, inside the register; replaced word-based, residual bare-L anchors 0. (c) own discharge line: cells-vs-rows conflation fixed (five changed cells, four break rows).
· LAW-41 SELF-CATCH IN-ROUND: first #22 edit added a literal occurrence of the counted label (7→8), reworded back to 7 — the self-referential trap, caught by re-running after editing.
· REGISTER FINAL: #22 7✓ (breakdown reproduces) · #43 0/0/1✓ · #9 994✓ · #10 0 with den. 1185 control✓ · item-8: all 24 new binding names resolve, 3 planted negatives 0 · unresolved §refs exactly {§2.2, §2b} matching the corrected cell. MUST-NOT-REGRESS four sets HOLD (§4.5c 4 sites — note grep '§4\.5c'=3 is the WRONG predicate, 4th is the heading; construction core six intact; §15.1 208 lines zero edits; ruling scoping untouched).
· LIMITS: extraction-level (no drv/suite/native fleet); §4.3 snippet NOT re-executed this round (its INPUT measured; refusal rides r13+gate verbatim executions); P=0 sweep bounds the LITERAL den.classes.<name> attrpath corpus only (computed/merged declarations unmatched); other §13 rows not re-run cell-for-cell.
NEXT: GATE ROUND 14 — dispatched.

════ ★★ GATE ROUND 14 VERDICT: REVISE — COUNT RESETS TO ZERO (2026-07-31, session 3; reviewed md5 a513464d143107889367fecc66923c9d echoed; S0 PASS, C6 FAIL via F1; C7/C7-a/C7-b/C8/C9 PASS; C1-family not re-opened, stated) ════
· F1 ★★★ CONSTRUCTION — THE DOMAIN EXPRESSION IS WRONG AT remapOver; A FIFTH SURFACE EXISTS: den.quirks.<name>. Both r14 grounds refuted at source: (a) requireEntry is a SHAPE test not a registration check (declarations.nix:197 `isAttrs v && v ? id_hash`; the tree exploits it — compile.nix's droppedTargetSentinel comment says "passes … BY SHAPE"; measured: hand-built {id_hash;name="settings"} admitted, lowerRoute yields "settings"; bare string throws = control; class entry shape ≡ channel entry shape so requireEntry CANNOT discriminate in principle). (b) the resolver admits QUIRK-CHANNEL entries BY DESIGN: compile.nix:301 resolveBucket over ingest.nix:767 `bucketRegistry = genAttrs channelNames channelEntry // classRegistry`, channelNames = attrNames (v1Decls.quirks or {}); compile's own comment: "from/to name a den-hoag fold bucket (a quirk channel) or a class". ⇒ route.from provenance = den.quirks.<name> ∪ registration ∪ any external {id_hash;name;}. REACHABLE through sourceOrderOf's bad filter; THE CELL'S CATEGORY IS "channel" — a category no source-side row carries. MEASURED on the built instance: keyCategory "host-info"/"devshell" on D = "channel" ⇒ design THROWS; controls class/null ADMIT; instance controls (same name on I, and D with quirkChannels={}) ADMIT ⇒ the refusal is the quirkChannels ARGUMENT. HEAD at the same argument: classSliceOf → 0 SILENTLY (control 1 at "nixos"). Absence control: resolveBucket/bucketRegistry 0 occurrences in the 4165-line doc (positive controls lowerRoute 10, requireEntry 4) — the resolver is genuinely untraced. Corpus P=0 (classes∩quirks = ∅ per-config, 27/27 fromClass literals resolve to den.classes; positive controls fire) — but NO figure in the doc bounds it.
· ★ SECOND COLLISION AXIS, undocumented and NOT 39x's: a name declared BOTH den.classes.<n> AND den.quirks.<n> classifies "channel" (channel half wins inside mkClassChannelSemantics, concern-aspects.nix:69-75) — measured with both/class-only/quirk-only/controls. Filed as its own kernel bead this session (class-vs-channel axis); 39x stays facet-axis only, verified open P1.
· NAMED EDITS r15 (all local, no new position): (1) §4.4c remapOver row → true provenance (resolveBucket/bucketRegistry chain; requireEntry-is-shape with droppedTargetSentinel citation); (2) drop the refuted carry ground — fifth member den.quirks.<name> with its two cells (_-prefixed ⇒ conjunct (i) inert; declared channel ⇒ REFUSED NAMED at read, HEAD silently empty) or a true bound; (3) §4.3 trigger enumeration names the CHANNEL category source-side; (4) §13 new break row (route source at declared quirk channel) + the class-vs-channel axis separated from 39x; (5) §14.2 acceptance arm producing a "channel"-category source (no current arm does). PLUS item-7 minor: the P=0 literal-attrpath limit must sit at the use sites (0 hits in doc; only in the bead entry) — and the SECONDARY statement-level fix: §4.4c's class expression over-generalises (den.aspects.<n>.<key> is admitted-and-inert legitimately; one sentence separating surfaces-that-NAME-a-channel from the body-that-IS-content).
· ITEM-1 READER CENSUS CONFIRMED: exactly 4 production classSliceOf call sites, no fifth READER — the fifth surface is on the ARGUMENT side at call site 2, which is why the domain-expression discipline (not a reader count) was what caught it.
· ITEM-3: r14's carry ground REFUTED — at HEAD the "always a registered class" conclusion survives only via deliveriesAt's __dropped skip, a mechanism the doc does not cite.
· ITEMS 2/4/5/6 PASS: fourth-member substance holds (trigger-3 derivation verified at class-modules.nix:321 + default.nix:1841); 39x separation clean, no quiet fix-claim; all three unrequested register edits verified as content with independent sweeps (unresolved refs exactly {§2.2, §2b}; §2b at L2179; no scope drift at L29/L225/L20); drift re-runs all reproduce (#22 7 breakdown cell-for-cell, no residual self-match; #43 0/0/1 with planted controls 2/1/1; #9 994; #10 0 + den. 1185; item-8 on r14 regions clean — 174 tokens, no dead anchor; #45/#46 reproduce on real exported classSliceOf). MUST-NOT-REGRESS: all four sets HOLD (§4.5c=4 with heading; core six intact — BOTH refusals present, joined not moved; §15.1 anti-over-read verbatim; measured span 207 lines — the 208 in THIS BODY's r13-supplement cell is off by one, bead bookkeeping not artefact).
· GATE'S OWN INSTRUMENT CORRECTIONS, disclosed: first probe used classifyKey (collapses null→"facet") where bad uses aspectSchema.keyCategory — all figures from corrected instrument; first corpus quirk sweep discarded on zero controls (zsh glob-expanded --include); first §2b tree-control run discarded (broken-pipe 0/0), repaired controls 42/108.
· GATE LIMITS: link-wise measurement, NOT composed in one native end-to-end fleet (each link measured: admission, lowerRoute output, keyCategory on D, sourceOrderOf refusal, HEAD silent 0); no drv/suite; ~17 register rows not re-run; 4kh.16 status not re-verified.
NEXT: r15 — the five F1 edits + item-7 limit + secondary sentence. COUNT AT ZERO. QUEUED behind the papers writer slot (O6-C r5 in flight).

════ ★ REMEDY SPEC — REVISION 15 (2026-07-31, session 3, at f631973) — GATE ROUND 15 PENDING (count at ZERO) ════
r15 ARTEFACT: same path, FROZEN md5 `7cd232589fa2e89bf084f55105d75a02`, 4381 lines (+216). Orchestrator double-sampled. Tree: only .beads/beads.jsonl dirty (tracker export, not code).
· ALL SIX r14-gate EDITS LANDED: remapOver row re-grounded (requireEntry-is-shape + resolveBucket registry = classes ∪ quirk channels; always-registered conclusion re-grounded on deliveriesAt's __dropped filter, now cited); FIFTH member den.quirks.<name> both cells (header quantifier corrected 1→3→4→5; discharge: ten cells six change, five break rows); §4.3 TRIGGER 4 with its OWN executed block (prior block's instance was quirk-blind — could not have exhibited it); §13 two new rows (quirk-channel route source; class-vs-channel axis citing den-hoag-bfq, separated from 39x, neither closed by this design); §14.2(h) three new arms; item-7 P=0 limit AT the use sites + the ★★★ name-a-channel-vs-IS-the-content caution.
· ARGUMENT-SIDE RE-DERIVATION: NO SIXTH SURFACE; chains stated in-doc (rawSeedsAt: classNames exactly ONE definition, two contributors, preimage unvalidated; remapOver: the fifth; forwardModulesFor: ONE live producer bridge.nix forwardEach, fromClass = arbitrary user fn, NO REGISTRY ON THAT PATH — already a member but disposition cannot derive from registration, now stated; projectClassScoped: registration only; droppedTargetSentinel not a sixth only because deliveriesAt filters it — stated).
· ★ TWO GATE-r14 CLAIMS CORRECTED IN-DOC: (A) "27/27 fromClass literals resolve to den.classes.*" FALSE — 23/27; four (hmLinux, hmDarwin, niri, mozilla) have NO literal den.classes anywhere = THE COMPUTED/MERGED CASE EXHIBITED — item-7's limit is a measured gap, not a disclaimer. (B) COLLISION AXIS ARM SPLIT — errors.quirkClassOverlap EXISTS AND FIRES on the COMPAT path (compile.nix intersects v1Decls.quirks with class names, aborts named); "channel half wins" is reachable on the NATIVE path only (discoverClasses/discoverChannels probe independently, default.nix unions with no disjointness check). bfq reframed native-arm this session.
· ★ SHARPER CORPUS FACT: vocabularies NOT disjoint — persist is a quirk in megadots AND a class in nixfos, fromClass="persist" in three other configs; zero exposure because no single fleet does both, not because the name spaces are separated.
· OWN MEASUREMENTS (quirk-bearing instance, real exported classSliceOf): the SHARP CONTROL the gate lacked — HEAD channel-source 0 with exempt={}, but ONE ARGUMENT APART exempt={host-info=true} → 1 ⇒ the 0 is conjunct (iii)'s CATEGORY test, not a missing key. Instance control: quirk-BLIND schema answers null ⇒ trigger 4 exists only where the quirk-aware instance is threaded — recorded at §4.3, armed at §14.2(h). Collision four-instances-one-argument-apart table measured.
· DRIFT: #22 7✓ (no self-match; subjects by words); unresolved refs exactly {§2.2, §2b}✓; #43 0/0/1✓; #9 994✓ #10 0 + den. 1185✓; item-8 28 new tokens all resolve, 3 planted negatives 0. ★ Author caught OWN quote-across-line-wrap defect mid-round (requoted to single-line span, re-verified 1 hit). MUST-NOT-REGRESS: all four sets HOLD; #44-46 textually intact (NOT re-executed — stated).
· LIMITS: extraction-level; fifth surface measured LINK-WISE (registry composition + requireEntry by reading; keyCategory/HEAD-0/exempt-control/design-filter by execution), compat→kernel composition derived not run; §14.2 arms specified-not-run; 13 den templates unswept; ★ AUTHOR-FLAGGED LIKELY NEXT FINDING: forward's fromClass is a SECOND route to a channel-category argument (call site 3) with provenance stated unconstrained but NO separate §13 break row.
NEXT: GATE ROUND 15 — dispatched.

════ ★★★ GATE ROUND 15 VERDICT: ACCEPT-WITH-CONDITIONS — NOTHING IN THE CONSTRUCTION, COUNT MOVES 0→1 (2026-07-31, session 3; reviewed md5 7cd232589fa2e89bf084f55105d75a02 echoed; a second clean construction round EXITS THE GATE). S0 PASS; C6 FAIL via F2 but STATED-SCOPE ⇒ accept-with-conditions per the standing C6 mapping; C7/C7-a/C7-b/C8/C9 PASS; C1-family not re-opened (stated). ════
· ITEM-1 (author-flagged forward-at-channel residue): STATED SCOPE NOT CONSTRUCTION — chain derived and measured: fromClass reaches sourceOrderOf's refusal UPSTREAM of conjunct (iii) (exempt never consulted); no uncovered path. ★ HEAD-side direction is DELIVERS not silent-0 (kernel's own forwardSourceClassesOf fills exempt from fromClass — measured 1 slice with kernel-built exempt, 0 with {}); row 3328's domain covers the cell, fixture arm NOT owed (member-three × schema-claimed, armed).
· ITEM-2 SIXTH-SURFACE HUNT: NONE. All five chains walked at source and confirmed (single schema-instance threading at default.nix:440-466→mkClassSlice ~:1898 — other instances NOT threaded; bucketRegistry admissions closed with resolveClass aborting named on anything else; ONE live __forward producer, aspect route refused by noBatteriesForward). ★ COMPUTED CLASS DECLARATIONS PRODUCE NO NEW SURFACE — discoverClasses reads probe.config attr NAMES so computed/nested/merged declarations land in the same effectiveClassNames chain = same member; confirmed live: niri and mozilla ARE declared in forms the literal sweep misses. ★ One chain incompleteness, same member: d.target resolves through the SAME resolveBucket (compile.nix:281) ⇒ a quirk channel as a module-bearing delivery's TARGET is a second inlet to member five.
· ITEM-3: (A) r15 AUTHOR RIGHT, r14 gate's 27/27 WRONG — 23/27 confirmed, four misses exact (gate's own first loop discarded on a zsh word-split defect, disclosed). (B) quirkClassOverlap VERIFIED firing for its OWN reason (errors.nix:146, one caller compile.nix:2195; ground = resolveBucket dispatch ambiguity); native union no check; §13 arm split correct. ★ TREE-INTERNAL ASYMMETRY corroborating bfq: bucketRegistry the CLASS wins (// classRegistry last, commented) while mkClassChannelSemantics the CHANNEL wins — two authorities disagree on a both-declared name (recorded on bfq).
· ITEM-4: trigger-4 block reproduces cell-for-cell incl. both controls; instrument stated (law-38 closure). ★ Gate added the control the doc lacks: quirk-BLIND instance still refuses [nixos,settings] ⇒ blindness is channel-specific, not a dead filter.
· ITEM-5: caution correct, weakens nothing; ONE overstatement (F5): "permanently inert" false at HEAD — a settings body IS delivered when a forward opens exempt (re-measured, doc's own #44); permanent only after the source-side refusal lands.
· FINDINGS (all documentation/stated-scope, named local edits): F1 ★★★ the quirk-channel corpus sweep's domain is short ONE CONFIG AND THREE NAMES by the exact predicate defect the author corrected on the class side THIS ROUND (louisb0 declares persist/secrets/install in nested form; four configs nine names; class-side literal 17 vs any-form 24 files) — instance fixed, class not discharged; conclusion survives (louisb0 has zero endpoint literals of any kind — uses pipe.from, not routes) but P=0 rests on a domain that never included them; EDIT: correct both cells, state louisb0's zero's true ground, RE-RUN EVERY CORPUS SWEEP under a form-widened predicate. F2 ★★ row 3331 records the class-vs-channel collision as a context row while the design turns a native both-declared fleet into a NAMED ABORT (measured: foo ∈ effectiveClassNames demanded as query channel, refused) — add the design-side direction + member-four colliding set = six facet names ∪ every declared quirk name; re-derive the discharge line after (six cells / six rows if 3331 becomes a break row). F3 ★★ row 3330's "no other source-side row carries channel" FALSE (row 3328's domain carries it; triggers 1/2/3 all reach channel) — true discriminator is RESOLVER-PROVENANCE, which §4.4c itself states; drop/requalify both claims, note 3328's HEAD direction is DELIVERS (opposite 3330's silent-0). F4 ★ "the four are exactly the computed case" false for two (hmLinux/hmDarwin declared NOWHERE = unregistered forward sources, §4.7 row 3 case; niri/mozilla the genuine witnesses) — split. F5 ★ wording.
· DRIFT: all re-runs reproduce; #44/#45/#46 RE-EXECUTED (the owed execution) — all three cell-for-cell; gate's own #45 instrument error (omitted assertedClasses) disclosed and repaired. Discharge line counted independently: ten cells / six changed / five rows — consistent. MUST-NOT-REGRESS: all hold; §15.1 207 lines (the 208 in this body's r13 cell stays a bookkeeping off-by-one).
· GATE LIMITS: extraction+schema-instance level, no fleet/drv/suite; design bad filter executed as verbatim transcription (integrated classSliceAt not in-tree); compat→kernel composition read not run; corpus sweeps textual (form-widened predicate still cannot see a name built from a variable); ~17 register rows + 4kh.16 status not re-checked.
NEXT: r16 — F1/F2/F3/F4/F5 edits (documentation only, construction untouched). COUNT AT 1; A SECOND CLEAN CONSTRUCTION ROUND EXITS. QUEUED behind papers writer (O6-C r6 in flight).

════ ★ REMEDY SPEC — REVISION 16 (2026-07-31, session 3, at f631973) — GATE ROUND 16 PENDING (COUNT AT 1; a clean construction round EXITS THE GATE) ════
r16 ARTEFACT: same path, FROZEN md5 `2a1d85f419ca703989e3cd64de0468a7`, 4570 lines (+189). Orchestrator double-sampled. CONSTRUCTION UNTOUCHED — zero mechanism statements altered, zero existing EXECUTED cells altered; additions: 1 new EXECUTED block (§4.3 trigger-category), 2 control rows labelled "added in revision 16", 3 tables. §15.1 still 207 lines byte-untouched.
· F1 DISCHARGED AS A CLASS: form-blindness sub-block in §4.4c — three written forms (literal attrpath / block / nested), 11-row old→new sweep table, per-form positive controls, variable-name limit EXHIBITED (4 measured occurrences). Headline moves: class files 17→23, quirk configs 3→4 (louisb0), quirk names 6→9 (distinct 8), fromClass 45/27→56/35 (FOURTH form found: `fromClass = _: "n"`, 11 occ — invisible to the class-side widening), undeclared fromClass set 4→8 (widened×widened), den.aspects control 994→996. SURVIVING ZEROS: six facet names 0 in all forms; quirk-as-endpoint 0; declare. ANY 0 = STRUCTURAL zero (not form-dependent); corpus meta.__forward 0.
· F2: §13 row 3331 now a BREAK ROW with the design-side direction measured one-declaration-apart (both-declared refuses at c="foo"; class-only admits; nixos control ×4); member-four colliding set = six facet names ∪ every declared quirk name (both halves override by the same // asymmetry). F3: row 3330's false discriminator WITHDRAWN; new EXECUTED block — ALL FOUR TRIGGERS reach "channel" with 5 same-run controls; true discriminator = resolver-provenance; row 3328 gains category + HEAD DELIVERS measured on real exported classSliceOf (kernel exempt → 1, {} → 0) ⇒ the two source-side rows differ by WHETHER ANYTHING FILLS EXEMPT, not category. F4: split landed (niri/mozilla = genuine computed witnesses; hmLinux/hmDarwin declared NOWHERE = unregistered forward sources). F5: "permanently" replaced with the measured short-circuit block. BONUS control added both instance rows.
· DISCHARGE LINE, own count: SIX cells / SIX rows — equality is TWO OFFSETS CANCELLING (cells 3+4 share a row −1; cell 5 realized by two rows +1), stated so it is not read 1:1; rows⊥cells in both directions = the generalisation of the r8-13 defect.
· ★ THREE GATE-r15 CLAIMS CORRECTED IN-DOC: (1) class any-form = 23 files not 24 (two independent derivations); (2) ★★★ megadots shares louisb0's ground — its positive control returns ZERO which INVALIDATES ITS OWN RUN (law 39); substitute measurement: megadots + louisb0 each 0 endpoint literals of ANY name (denix 14, nixfos 19 same run) ⇒ FIVE of nine zeros hold because those fleets declare no endpoints at all; (3) the fourth fromClass form. Also: gate's six/six guess right but derived for a different reason; §15.1 still quotes 994 (now 996) — OUT OF SCOPE for a doc-only round, recorded at register row #9 with the note the widening does not disturb §15.1's argument (its point is #10's structural zero, re-confirmed widened); flagged for whenever §15.1 next opens.
· REGISTER: #22 7 same six sites; unresolved exactly {§2.2, §2b}; #43 0/0/1 with planted controls; #9/#10 re-stated form-widened (996, 0); item-8 14 in-tree + corpus tokens all resolve, 5 planted negatives 0. MUST-NOT-REGRESS: all hold; §13 rows 3-column; tables well-formed.
· LIMITS: sweeps textual (three written forms; variable-bound names evade — 4 quoted); 13 templates unswept; probe vocabulary instrument NARROWER than real aspectSchema on STRUCTURAL keys (null for name/meta/includes/id_hash) — no structural-key claim made from it; F3's DELIVERS used the real exports; ★ F2's ACCEPTANCE ARM STATED BUT NOT WRITTEN (a §14.2 arm is a construction change, r16 is doc-only) — recorded as an explicit coverage limit beside the discharge line with the arm's shape specified, so §14.2(h) cannot be read as covering it.
NEXT: GATE ROUND 16 — dispatched. COUNT AT 1; nothing-in-construction EXITS.


════ ★★ GATE ROUND 16 VERDICT: ACCEPT-WITH-CONDITIONS — COUNT RESETS TO ZERO, GATE DOES NOT EXIT (2026-07-31; reviewed md5 2a1d85f419ca703989e3cd64de0468a7 echoed). S0 PASS · C6 FAIL via F1/F2 stated-scope ⇒ accept-with-conditions · C7/C7-a/C7-b/C8 PASS · C9 PASS STRONGLY · C1-family not re-opened. ════
· THE COUNT LOGIC, explicit: NOTHING WRONG IN THE CONSTRUCTION (core six, both refusal positions, five-member enumeration, six/six discharge, four triggers — all verified under the gate's own independent execution; r16 stayed doc-only, proven by RE-EXECUTION since no frozen r15 copy survives: §15.1 byte-identical — and the 208-vs-207 mystery POSITIVELY RESOLVED, the older extract over-captured §15.2's heading; §4.3/#44/#45/#46 reproduce row for row). BUT F2 IS A CONSEQUENCE-CLAIM — a stated corpus ground false at HEAD by measurement — and standing rules put consequence-claims on the reset side. Count 1→0.
· F2 ★★★ THE FORM-BLINDNESS CLASS IS NOT DISCHARGED — THE THIRD CONSECUTIVE INSTANCE OF ONE SHAPE (r15 fixed classes left quirks; r16 fixed fromClass left the ENDPOINT sweep). louisb0 declares FOUR endpoints in EXACTLY the constant-function form r16 itself discovered this round (classes.nix :11/:12/:21/:22 — fromClass = _: "os"/"hm", intoClass = _: "nixos"/"homeManager"); "megadots and louisb0 each contain ZERO endpoint literals (denix 14, nixfos 19, same predicate same run)" is UNSATISFIABLE BY ANY SINGLE PREDICATE (literal: denix 12/louisb0 0; field-assignment: denix 14/louisb0 4 — the sentence's halves come from different predicates). Conclusion survives, ground STRONGER: all nine quirk-name zeros hold under the widened endpoint predicate with louisb0's own four endpoint names as same-run controls; louisb0's zeros hold because its LIVE endpoint vocabulary {os,nixos,hm,homeManager} misses its quirk names — the ORIGINAL ground; only megadots's TWO rest on the substitute. "Five of the nine" must read TWO. EDIT: re-run the endpoint sweep constant-function-widened; five→two; state the actual predicate; apply the fourth form to EVERY sweep.
· F1 ★★ §13's facet-collision row (3518) closes "Armed by §14.2(h)'s expression on a new input arm" while §4.4c says the arm is an OBLIGATION not-yet-written and NO SUCH ARM EXISTS (27 named arms in §14.2, none builds a class-at-facet-name fleet); cell 5 is realized by TWO rows and NEITHER is armed; rows 3518/3520 carry OPPOSITE coverage statements on the same cell — the exact fail-open the doc names at L1821. EDIT: 3518 matches 3520 (arm OWED, shape at §4.4c); limit covers BOTH arms.
· F3 ★ C9 minor: __dropped named load-bearingly (the always-registered closure rests on it) with no which-side disposition, unlike __forward's exemplary block. One sentence.
· r16's THREE CORRECTIONS ALL ADJUDICATED CORRECT: 23-not-24 (independent brace-aware scan, zero overlap, examples match); megadots law-39 catch right (but the substitute measurement is F2); fourth form exactly 11, 45+11+4=60 fully consistent.
· ALL FIVE r15 CONDITIONS DISCHARGED (independently re-run: 11-row table, six/six with the cancelling-offsets arithmetic RE-DERIVED, four-trigger block cell-for-cell with all five controls + r16's new instance-control-control, F4 split verified — hmLinux/hmDarwin occur ONLY as fromClass literals and aspect content keys, F5 short-circuit measured).
· REGISTER: #9 994 by the row's own command (996 widened; +2 = louisb0 disk/secrets; ★ BONUS: the gitignore-honouring wrapper grep returns 993 — the doc's rev-2 figure now EXPLAINED not just asserted); #10 0 both predicates with a REPAIRED control (den-hoag lib/compat 8 files/15 spellings; first run wrong-cwd zero, law 39, repaired); §15.1's own sub-counts reproduce exactly when scoped .nix (gate's first count caught ledger.md prose — law-38 mirror, caught before reporting); #22 7; unresolved exactly {§2.2, §2b} with two-direction planted controls; #43 0/0/1; item-8 clean. ITEM 4 DISCHARGED: 994→996 does not disturb §15.1 (its point is #10's structural zero, 0 widened).
· C9 EXEMPLARY: __forward disclosure verified to the fact (exactly two live kernel readers); entry-1 residue side stated.
· GATE LIMITS: extraction+schema-instance only; compat chain read not executed; gate's own scanner narrower than the doc's grep (used the rows' own commands for cells); variable-bound names evade all predicates; 13 templates unswept; ~17 rows not re-run; two own-control misfires repaired not reported as absences.
NEXT: r17 — F2 (endpoint re-run + five→two + predicate stated + fourth form over EVERY sweep — and make the sweep inventory a TABLE: every corpus figure, its predicate, its form coverage, so the class discharge is checkable not claimed), F1 (row 3518 coverage statement), F3 (one sentence). COUNT AT ZERO. QUEUED behind papers writer (O6-C r7 in flight).


════ ★ REMEDY SPEC — REVISION 17 (2026-07-31, session 3, at f631973) — GATE ROUND 17 PENDING (COUNT AT ZERO) ════
r17 ARTEFACT: same path, FROZEN md5 `44457d845c7df7e16f8071f0d0fd1119`, 4696 lines (+126). Orchestrator double-sampled. Construction untouched (28 fenced EXECUTED blocks balanced, cells spot-intact; doc-only proven by re-execution).
· F2 DISCHARGED VIA THE SWEEP REGISTER: 20 rows at §4.4c (REPLACES r16's 11-row table — two tables carrying the same figures is itself a drift source), columns what/predicate-verbatim/forms/value/status, ADMISSION RULE at the head (a row is admissible only if its own command reproduces its cell) + two derived rules (never a figure whose halves come from different predicates; editing a row obliges re-running it). FOUR FORMS formalized — A/B/C attrpath, D value (constant-function); n/a cells are RULINGS not blanks (D cannot arise for a declaration; B/C cannot for an endpoint). five→TWO landed with grounds SPLIT BY MEASUREMENT: seven of nine zeros checked against live vocabulary (louisb0's three against {os,nixos,hm,homeManager} each firing 1 — reachable only through form D), megadots's two on the structural no-endpoints ground (0 under EVERY predicate, six of them, denix controls firing on all six same run).
· ★ FIGURES THAT MOVED UNDER FORM D: row 19 residue 4→12 (r16's 4 was fromClass-only under a four-field quantifier — LAW 37, understatement in the dangerous direction; the 8 added are all intoClass ⇒ residue concentrated on the DESTINATION coordinate, §4.5b's, no P=0 rules on it); row 20 in-tree control 252→364 literal / 380 widened (no narrowing reaches 252; three quoted exemplars reproduce; error AGAINST control strength; corrected at #44 + §13's propagation); row 17 persist sharpened (two of the "three other configs" ARE the two declaring persist as a class; only gwenodai-nixos declares it nowhere); row 14 (B-form subsumed by the bare-token predicate — unlike every other row, stated); rows 18/10 predicate hygiene. Thirteen rows unchanged under D.
· F1: row 3518's "Armed by" QUOTED THEN WITHDRAWN in place — matches 3520 (arm OWED, shape at §4.4c); row 3625 (member five) restated ARMED with the contrast stated (cell 5's two rows need a fleet with no reroute and no __forward anywhere); coverage limit widened to BOTH cell-5 arms with shapes and controls. ★ Gate claim measured differently, in-doc: §14.2 has 28 arms under a stated predicate (31 distinct test- tokens, 3 declared elsewhere), not 27 — immaterial (cell-5 coverage zero either way).
· F3: __dropped block beside __forward — inherited side, WEAKER than __forward's (no reader added AND no domain widening; deliveriesAt folds actions.resolution which §4.5 does not touch); the retire-vs-kernel-owned fork stated (retirement takes §4.4c's always-registered ground with it, re-derive from resolveBucket admissions).
· DRIFT: #22 7; unresolved exactly {§2.2, §2b}; #43 0/0/1; item-8 all resolve with planted negatives 0; ALL 20 REGISTER ROWS RE-RUN AT FINAL STATE, every cell reproduces. ★ Author caught TWO own instrument defects mid-run (zsh unquoted-expansion word-split — nine false 0s and a bogus 357; $f[ array-subscript zeroing a loop), repaired via read-loops before reporting; and introduced-then-removed a prose line-anchor that pushed #43 to 2 (the exact self-reference #43 documents).
· MUST-NOT-REGRESS: all four sets hold; 41 tables well-formed 0 mismatches; §15.1 207 lines untouched.
· LIMITS: sweeps textual — variable-bound names evade all four forms, NOW MEASURED AT 12 not asserted at 4; 13 templates unswept; row 20 the only row not corpus-run; no fleet/drv/suite; ~17 §1.1 rows outside dispatch not re-run.
NEXT: GATE ROUND 17 — dispatched. COUNT AT ZERO.


════ ★★ GATE ROUND 17 VERDICT: ACCEPT-WITH-CONDITIONS — COUNT STAYS AT ZERO (2026-07-31; reviewed md5 44457d845c7df7e16f8071f0d0fd1119 echoed). S0 PASS · C6 FAIL via F1 stated-scope ⇒ accept-with-conditions · C7/C7-a/C7-b/C8/C9 PASS · C1-family not re-opened. Construction verified correct AGAIN (core six, both refusals, five members, member-five arm, cell-5 zero-coverage, __dropped disposition, #45/#46 RE-EXECUTED cell-for-cell); F1 is a false consequence-claim ⇒ reset side. ════
· F1 ★★★ FOURTH CONSECUTIVE FORM-BLINDNESS INSTANCE — THE `inherit` SPELLING. Row 19's "residue that evades all four forms = 12" misses inherit-borne endpoints: 6 corpus occurrences, ALL nixfos (route-factories.nix :49/:72/:99, coolercontrol.nix :11, persist classes.nix :39/:59), all genuine route-spec fields ⇒ residue = 18 (fromClass 10 / intoClass 8 / from 0 / to 0). ★ THE STATED CONSEQUENCE INVERTS: "concentrated on the DESTINATION coordinate" is FALSE — ten of eighteen sit on the SOURCE coordinate (§4.3's refusal position, rows 7/13 rule on it). CONCLUSION SURVIVES ON A STRONGER GROUND, verified: nixfos's threading terminates in literal declared class names, none of its quirk names appears as any endpoint under any form (0/0/0 with firing persist control), zero variable-bound endpoints there ⇒ no P=0 breached. ★ THE FORM WAS IN HAND SINCE r12 — §1.1 #24 widened the IN-TREE census to inherit(content) five revisions ago; never carried to the corpus sweeps. Chain: r15 classes→quirks left; r16 fromClass→endpoints left; r17 form-D values→non-= spellings left. EDITS: row 19 widened (or 19b), 18 with per-field controls; limit paragraph rewritten with the 10/8 split + which coordinate each P=0 rules on; §13 row propagation; inherit added as the endpoint family's fifth spelling.
· F2 ★★ row 20 VIOLATES THE REGISTER'S OWN ADMISSION RULE in the row corrected this round for that defect: "glob selects 46 files" — 46 is the PRE-widening matched-file count (row's own command → 50; the glob actually selects 322). Same within-row asymmetry one column over. EDIT: "50 match this row's command (glob selects 322)".
· F3 ★★ two sites still carry the retired 252, BOTH citing the row that retired it (§4.7 row 3a L2510; §9.2 L3272 — both assert it as a same-run measurement). EDIT: 364 (380 widened) or repoint at row 20. (§15.1's 994 correctly frozen-and-disclosed, NOT this.)
· F4 ★ the declaration family has NO residue row and its closing sentence overreaches ("the only forms … can be blind to" — a COMPUTED attrpath den.classes.${n} is a fourth spelling; MEASURED CLEAN with a 20+-hit positive control on neighbouring den surfaces). EDIT: declaration-side residue row carrying the clean measurement; "only literal forms".
· REGISTER-AS-INSTRUMENT AUDIT: (a) ALL TWENTY rows re-run — 19/20 cell-for-cell (row 20's file sub-cell the exception); ★ real strength recorded: among `=` spellings the predicates are EXHAUSTIVE (fromClass 60 = 56+4, intoClass 40 = 32+8, 0 unaccounted — the gap is entirely outside the `=` spelling). (b) n/a rulings TRUE individually (counterexamples hunted with firing controls); the "every n/a is one of those two rulings" closing sentence is what fails — reads as closing both families, closes neither. (c) register's own domain: the two 252s are the only in-doc corpus figures outside it; every P=0 (20 sites) swept.
· ALSO: 28-vs-27 arm count — r17 AUTHOR RIGHT, r16-gate wrong (re-counted 28/31 with the three elsewhere-declared named; §14.1=3 §14.6=8 cross-checks); cell-5 coverage really zero (§14.2 contains no den.classes. at all, control fires 5× elsewhere). Row 3625's ARMED contrast verified (relocationBase IS the relocation-bearing fixture). __dropped verified at output-modules.nix:261-262 verbatim; non-widening holds. Item-8 11 names + 5 planted negatives; #22 7; {§2.2,§2b}; #43 0/0/1. MUST-NOT-REGRESS all four sets hold (41 tables 0 mismatches; §15.1 207).
· GATE'S OWN THREE INSTRUMENT ERRORS DISCLOSED AND REPAIRED (wrapper-grep is a zsh function absent in bash — 993 reproduces; form-B miss in the class extraction — 7→7; escaped-pipes-in-code-spans law-38 mirror — 41/0).
· GATE LIMITS: inherit widening covers inherit f; and inherit (x) f; — did NOT sweep //-merge-borne or function-returned whole specs; no fleet/drv/suite; ~17 §1.1 rows not re-run; 13 templates unswept; row 20 in-tree only.
NEXT: r18 — F1 (row 19→18, coordinate split, §13, fifth spelling), F2 (file cell), F3 (two 252s), F4 (declaration residue row + "only literal"). ★ STRUCTURAL INSTRUCTION FOR r18: the register gains an ENUMERATED-SPELLINGS closure statement honest about open-endedness — per family, list the spellings covered, list the evasion classes EXHIBITED (variable-bound, merge-borne, function-returned), and delete every "only forms" claim; the space of Nix spellings cannot be closed, only enumerated-and-exhibited. COUNT AT ZERO. QUEUED behind papers writer (O6-C r7-fix in flight).


════ ★ REMEDY SPEC — REVISION 18 (2026-07-31, session 3, at f631973) — GATE ROUND 18 PENDING (COUNT AT ZERO) ════
r18 ARTEFACT: same path, FROZEN md5 `7b712a934c2fc07483a18de9ff00c951`, 4831 lines (+135). Orchestrator double-sampled. Construction untouched (28 fenced blocks unchanged).
· ★★★ THE CLOSURE STATEMENT LANDED (new subsection at the register's head, verbatim in the artefact): the closure-shaped claim is WITHDRAWN as a SHAPE — "a claim refuted four times on its own evidence is not a claim to correct once more; it is a shape of claim to withdraw" — replaced per family by two lists and no closing quantifier: spellings COVERED (each with a same-run firing witness) and evasion classes EXHIBITED (measured instance or explicit UNSWEPT). Declaration family: A/B/C covered; computed attrpath exhibited 0/0/0 with a 24-hit control (row 21 NEW); merge-borne and function-returned STATED UNSWEPT (// lib.optionalAttrs ×30 live). Endpoint family: literal/D/E covered; not-a-written-name exhibited at 18; merge-borne SWEPT AT THE 18 policy.route CALL SITES ONLY and settled there (4 //-built arguments read, 6 merged halves, no endpoint field among them — the other 24 occurrences unswept, stated); function-returned not swept as a class, the one load-bearing chain (nixfos factories) traced to 15 literal leaves instead. Every P=0 re-scoped to "no match in the enumerated spellings", never "no fleet can reach this". Future spelling finds land as LIST ADDITIONS, not closure refutations.
· F1 LANDED: row 19 → 18 (fromClass 10 = 4 var + 6 inherit / intoClass 8 / 0 / 0) with per-field AND per-arm controls; limit paragraph rewritten — r17's sentence withdrawn FALSE IN BOTH HALVES (★ beyond the gate: rows 7, 10 AND 20 each rule on BOTH coordinates, so "no P=0 rules on the destination" was also false — r17 offered a gap that does not exist in either direction); nixfos discharge traced END TO END (6 factories → 15 literal leaf sites = exactly nixfos's 15 declared class names; quirk names 0/0/0 with firing persist control; variable-bound arm 0). ★ SECOND EXPOSED CONFIG THE GATE DID NOT HAVE: denix also declares a quirk AND carries residue (2 × intoClass = host.class) — its zero grounded separately, measured arm (wrapper-packages at no endpoint any spelling) + read arm labelled as read (host.class selects a HOST class; denix reaches its quirk channel via pipe.from, the collection-stratum shape). megadots/louisb0 0 in both residue arms ⇒ no other exposed config. Form E added with the ★ paren-form trap recorded: louisb0's `inherit (host) persist;` is a QUIRK NAME in an inherit that is NOT an endpoint — row 7's inherit arm must be an endpoint-FIELD predicate, never name-appears-in-inherit (which would report a phantom quirk endpoint).
· F2/F3/F4 LANDED (50/322 cell with the violation named; both 252 sites → 364/380 repointed, five remaining 252 tokens all historical notes; row 21 + "only LITERAL forms" requalification chain: row 3, §4.4b, §13, §1 item 5 → FOUR consecutive + §4.4c's why-a-register-alone-was-insufficient paragraph).
· ★ THIRD FINDING BEYOND THE GATE: in-tree form E over-matches — 9 occurrences, only ONE an endpoint (compat forwards.nix's inherit (spec) fromClass intoClass); the other 8 are the KERNEL'S GRAPH-EDGE COORDINATES (from/to in synthEdge, cycle map, claim fact, rel record, edges.nix ×2, two query arguments). Row 20's control decomposed (fromClass 59 / intoClass 38 / from 120 / to 147, five `to` matches are proto="tcp|udp" — no word boundary) so 364 cannot be read as a route count.
· ALL 21 REGISTER ROWS RE-RUN at final state, every cell reproduces. Drift: #22 7; #43 0/0/1; {§2.2, §2b} with a heading-extraction control; item-8 6 new anchors + 3 planted negatives 0. MUST-NOT-REGRESS four sets HOLD (§15.1 207 lines md5 f37dde9d… no r18 marker; tables 41/0 with a PLANTED broken row firing — law 39 applied to the table checker itself).
· ★ FOUR OWN INSTRUMENT DEFECTS caught pre-report (row-14's opt-out scoping — law-38 shape; -A6 block scrape undercount; escaped-pipes trap; §15.1 inclusive/exclusive). 
· MICRO-FORK FLAGGED FOR OWNER, deliberately not edited: §1's "every file has a line 1899" is strictly false (only files ≥1899 lines) but is the SINGLE surviving witness that #43's prose predicate fires — rewording takes the predicate's in-doc witness to 0. Author left it; owner may rule either way; zero load bears on it.
· LIMITS: sweeps textual; merge-borne settled only at the route call sites; function-returned only the traced chain; denix's zero part-read; 13 templates unswept; row 20 in-tree; ~17 §1.1 rows not re-run; E's scope excludes `with`-reached and splice-reached fields (stated).
NEXT: GATE ROUND 18 — dispatched. COUNT AT ZERO.


════ ★★ GATE ROUND 18 VERDICT: ACCEPT-WITH-CONDITIONS — COUNT STAYS AT ZERO (2026-07-31; reviewed md5 7b712a934c2fc07483a18de9ff00c951 echoed). S0 PASS · C6 FAIL via F1/F2 stated-scope · C7/C7-a/C7-b/C8/C9 PASS. FIFTH consecutive construction verification, by independent re-execution (member-five block, #45/#46, nixfos trace — all cell-for-cell). ════
· F1 ★★★ (consequence-claim, resets) — the merge settlement's SCOPE SENTENCE is false: "settles the class where the residue actually lives" — but gwenodai carries 5 of row 19's 18 residue occurrences (largest single-config share), has ZERO policy.route sites (its constructor is den._.forward, a surface the doc never names), and TWO of its residue occurrences sit LITERALLY INSIDE its two merge-built forward-spec arguments — which are inside the doc's own 24 "unswept". Sentence 2 contradicts sentence 3 of the same bullet; sentence 3 is true. CONCLUSION SURVIVES STRENGTHENED: gate read both gwenodai merged halves (adapterModule only, no endpoint field) ⇒ the corpus's COMPLETE merge-built spec-construction set = 6 sites / 8 halves (4 route + 2 forward), none carries an endpoint field. Scale: 41 spec-construction sites (26 route + 15 forward) vs stated swept 18. EDITS: drop the scope sentence; extend to the 2 forward merges (reads done); 24→22; name the forward constructor surface in the family definition (defined as "route OR forward spec", swept route-only).
· F2 ★★ (false claim about own EXECUTED evidence, resets) — §4.4c's fifth-member block labels the settings 0 "control: absent key → 0" while ITS OWN LINE THREE ABOVE records settings → "facet" on the same instance: the 0 is conjunct (iii)'s CATEGORY test, same ground as the host-info 0 it contrasts with. Gate measured the true discriminator: exempt={settings=true} → 1 (one argument apart) vs a genuinely absent key 0 UNDER BOTH exempt states. The block's purpose is exactly that separation and it does not exhibit it. Member five stands. EDITS: relabel (registered non-class key, same conjunct); add a genuine absence row (0/0 measured) or drop the claim.
· F3 ★ REGISTER ADDITION, does NOT reset — the sixth spelling is the INHERIT-BOUND CONSTRUCTOR (`inherit (den.lib.policy) route;` then bare `route { }`): 8 further call sites (slashfiles ×4, adda ×2, oceangreendev ×2) ⇒ 26 route sites not 18, all literal-attrset (merge conclusion extends to all 26). ★★ THE ABSORPTION TEST PASSES EXACTLY AS THE CLOSURE STATEMENT PREDICTS: endpoint sweeps are field-quantified and constructor-agnostic, so all 8 sites' endpoints were already counted — NO P=0 MOVES, lands as a row, no claim breaks. The structural fix is doing its job.
· CLOSURE-STATEMENT AUDIT: (a) per-family claims verified (rows 1/4/19/20/21 exact; unswept genuinely unswept, no half-measures; the NEW failure shape is the MIRROR — an unswept admission contradicted by a coverage sentence in the same bullet); (b) 18/4/6 re-derived, "no endpoint field" right, scope sentence the failure; (c) nixfos trace exact; denix read-arm labelling EXEMPLARY (verbatim "Read, and labelled as a read"); (d) sixth-spelling hunt: with/quoted/computed/list/if-let/fn-call/interpolated all 0 with a 636-hit control — the sixth spelling found on the CONSTRUCTOR axis instead (F3).
· DRIFT: rows 1/4/19/20/21 reproduce (row 20 complete incl. the 9/1 form-E split with all 8 non-endpoints located; proto over-match exactly 5); #22 7; {§2.2, §2b}; #43 0/0/1; all five 252 tokens historical (r17-F3 FULLY DISCHARGED); all four r17 edits landed; 41 tables/0; §15.1 207 lines zero r18 markers (gate's own §15.1 md5 differs by extraction boundary — checkable half holds, stated). Beyond-gate findings all adjudicated RIGHT (both-coordinates, denix, form-E decomposition). Micro-fork: zero load confirmed. C9 PASS.
· GATE'S OWN THREE INSTRUMENT ERRORS disclosed and repaired (occurrence-vs-file semantics; a predicate applied to its own extracted output — false absence, law-38 shape; the escaped-pipes trap).
· GATE LIMITS: textual sweeps; forward census used three literal spellings — an inherit-bound forward ALIAS would evade it (the symmetric gap to F3, stated not measured); 15 forward call sites not all read; ~17 rows/13 templates standing.
NEXT: r19 — F1's four edits, F2's relabel+absence row, F3's constructor row (18→26). All documentation; construction untouched. COUNT AT ZERO. QUEUED behind papers main-checkout writer (O6-C r8-fix in flight).



════ ★ REMEDY SPEC — REVISION 19 + OWNER-RATIFIED ARTIFACT SPLIT (2026-07-31, session 4, at 6dc4d44) — GATE ROUND 19 PENDING (COUNT AT ZERO) ════
r19 ARTIFACT SET (all three orchestrator-verified md5): CORE specs/2026-07-30-class-content-consumer-unification-spec.md `0aa663147cb357724f6e8ee19db2410e` 4343 lines · LEDGER …-spec.ledger.md `b795f19ab8b2b782439f84a3036b5a27` 657 lines · SCRIPT …-spec.register.sh `88eeced1686faf86cdaa6fdc010561c1` 273 lines. Pins: den-hoag 6dc4d44, nix-config 425f1d3, papers 4054f67; ★ den-configs is NOT a git repo (plain clone directory) — corpus figures pin to working tree, not a commit.
· F1 LANDED, all four: scope sentence dropped + withdrawal recorded with refutation (gwenodai: 0 route sites both spellings w/ corpus control 18; 6 den._.forward sites; 5 of 18 residue occurrences); merge census extended by the author's OWN reads of gwenodai's two merge halves (both `// lib.optionalAttrs dedup` → adapterModule ONLY, no endpoint field) ⇒ corpus-complete merge-built spec-construction set 6 sites / 8 halves (4 route/6 + 2 forward/2); 24→22 (`// lib.optionalAttrs` corpus-wide 30 − swept 8); endpoint family names THREE forward surfaces (den._.forward 7 / den.batteries.forward 7 / den.provides.forward 1) + scale 41 = 26 route + 15 forward, with WHICH rows needed the constructor stated (only the merge-borne bullet; field-level rows range over field tokens).
· F2 DISCHARGED WITH AN ORCHESTRATOR DECISION PENDING GATE ADJUDICATION: the mislabelled cell sits INSIDE fence #(fifth-member) and the 28-fence freeze was held — relabel discharged in prose immediately BEFORE and AFTER the fence + a NEW measured discriminator table (settings-present 0→1 across exempt states = category test; genuinely-absent 0→0 BOTH states = presence test; nixos 1/1 non-vacuity) — at exempt={} alone the two zeros are INDISTINGUISHABLE, so the mislabel was unfalsifiable from the block's own cells; claim kept and GROUNDED. CLASS SWEEP: 2 members — §13 break row had inherited the false label verbatim, FIXED; §1.1 row 44 clean (already separates the controls). ★ ORCHESTRATOR RULING: in-place one-line relabel inside the fence is the by-construction form — gate 19 adjudicates; if upheld, r20 lands it WITH the invariant restated (27 byte-identical + 1 named one-line delta, new concatenated md5 pinned).
· F3 LANDED as ADDITION: form F (inherit-bound constructor) 8 call sites re-measured (slashfiles ×4 / adda ×2 / oceangreendev ×2, per-file bare `route {` = 1 each), all literal-attrset ⇒ route population 26, merge conclusion extends unchanged; register rows 22-23 + NEW SPEC-CONSTRUCTION family in the closure statement (covered/exhibited/unswept, no closing quantifier). ★ Author did NOT increment "four rounds" — r19 lost on the POPULATION axis (which sites the sweep visits), not the SPELLING axis; collapsing them would hide the new axis. Stated in-doc.
· SYMMETRIC-GAP SWEEP (inherit-bound forward alias): COVERED 0/0/0 three arms each with a FIRING control — ★ arm 2's route control returned 0 too, so a third name (pipe → 1) was found per law 39 before the zero was accepted. EXHIBITED not counted: slashfiles' local fn NAMED forward (both bodies call route — already among the 8); nixfos `class.route = { }` (aspect content key). Two more class members COVERED 0 w/ firing controls (constructor-as-parameter; computed constructor attrpath — corpus's 25 computed den. attrpaths all den.aspects/den.hosts). UNSWEPT stated: constructor bound through a merge or returned by a function.
· POPULATION-TOKEN SWEEP: every other 18/24 in the doc re-derived as a DIFFERENT quantity, left alone deliberately.
· REGISTER MECHANIZED (owner ruling executed): register.sh 79 pass / 0 drift / 0 skipped EXIT=0, pin-guard first (2e44ff5..HEAD and f631973..HEAD lib/ ci/ both byte-identical). ONE GENUINE DRIFT registered not repaired: §1.1 #16 forwardSourceClassesAt repo-wide 1→2 — second hit is .beads/beads.jsonl QUOTING THE NAME (this arc's own export; the register-names-retired-symbols decay mode, entry-1 class); code-side domain unmoved (lib/+ci/ → 1); row carries both figures, script checks both. ★ Script mechanizes TEXT predicates only — nix-eval rows (#25-#46, #30a, #12) NOT covered, stated in the script's own header.
· SPLIT EXECUTED VERBATIM: §1.1 (313 lines) + form-blindness subsection (325) → ledger; NO fenced block moved. Verified two ways (multiset equality 4949=4949 zero missing/extra + per-region byte diff, region B's single delta = terminal-newline artefact, resolved). Invariants post-split: 28 fences concatenated md5 ea492adbcd11647ff0bcb256fbb20376 (315 lines) IDENTICAL to pre-edit; §15.1 207 lines md5 abe461d3c6c99609840db678104bb27b UNCHANGED — both now ASSERTED ROWS in register.sh. Artifact-set table at core head; heading stubs preserve §-numbering.
· AUTHOR'S INSTRUMENT ERRORS disclosed (5, each control-caught): git rev-parse without -C (cwd bleed); zsh `$n[` array-subscript false zeros ×5 in a control loop; `grep -rc | wc -l` counted FILES (gwenodai "128" → true 0); bc absent; --include misapplied to row 14 (988 vs 994).
· LIMITS: nix-eval register rows not mechanized; "four MUST-NOT-REGRESS sets" not named as such in the artefact (author verified the identifiable ones: fences, §15.1, row reproduction); split scope conservative (fifth-member evidence + §4.4c rulings stay in core — judgement call flagged); merge/function-returned constructor binding unswept; suite not run (docs-only).
NEXT: GATE ROUND 19 — first gate over the SPLIT artifact set. Named adjudications: (1) the F2 fence question — prose-guard vs in-place relabel, and what the fence invariant should freeze (construction vs all 28); (2) the split's verbatim-move verification method (multiset + per-region — sound?); (3) the population-axis vs spelling-axis separation in the closure statement; (4) the #16 domain-drift registration. COUNT AT ZERO.



════ ★★★ GATE ROUND 19 VERDICT: ACCEPT-WITH-CONDITIONS — NOTHING IN THE CONSTRUCTION, ★ COUNT ADVANCES TO ONE (2026-07-31, session 4; first gate over the SPLIT artifact set; all six md5 samples match the three frozen values, open AND close; den-hoag 6dc4d44 both samples; ALL SEVEN findings STATEMENT-LEVEL, each naming its discharging instrument). S0 + C1-C9 ALL PASS (C5 on the two live citations; C7-a/C7-b read by extraction). register.sh 79/0/0 exit 0 at open AND close + SIX independent spot-re-derivations of the script itself all reproduce (independent Python fence extractor; independent §15.1 region detect; row-22 form F site-by-site with no false-positive class; #11 with the file split the script omits — 8 live/4 files confirmed; #36 + a STRONGER historical claim the script does not cover: git log --all -S classSliceOf -- lib/compat/ → 0 with control lib/attributes/ → 9; pin guard with the one-file-window control). Failure-mode test: dead-GREP run → 36 pass/43 drift EXIT 1 — fails closed, but liveness carried by non-zero rows de facto, not by construction (F6). ════
· F1 STATEMENT — a SECOND register-row domain reaches build products, and it is THE corpus control every corpus P=0 is read against: rows 9/14 (den.aspects, deliberately no --include) count 994 incl. denix/.git's 2.7MB regenerated pack (993 ex-.git; the row's own rev-2-said-993 note consistent). 18 of 20 corpus dirs are git clones — structural exposure. DISCHARGE: #16's both-domains treatment on rows 9/14, both figures script-checked.
· F2 STATEMENT — the split's verbatim-move verification is RECORDED NOWHERE and now UNREPEATABLE: pre-split doc unrecoverable (specs untracked; no copy of 7b712a93… found in papers/den-hoag/scratchpads — bounded sweep, gate's own instrument-error note). The one load-bearing claim about the split has neither figure nor command in the artifact set. ★ The bead ledger DOES hold pre-split md5+lines (r18 entry, this body). DISCHARGE: ledger head records pre-split md5/lines + the two verification commands; register.sh gains per-region md5s.
· F3 STATEMENT — fence invariant's label narrower than its domain: 28 fences = 17 EXECUTED transcripts + 10 construction + 1 measurement fragment; the check exists to prove the CONSTRUCTION did not move. DISCHARGE: split — construction fences md5-frozen; transcript fences per-block list.
· F4 STATEMENT — one concatenated md5 localizes nothing; gate produced the 28-row per-block list (block 17 = fifth-member, a71de95000322dfd1517ddf2aaaecef2). Precondition for the relabel license.
· F5 STATEMENT, NOT CHARGEABLE — register entry 5 gained the rb0 witness 44s AFTER the core froze (orchestrator edit, this session). Gate verified in-tree the design's path reads no __entry (className reads c.name; requireEntry is isAttrs+id_hash; class-modules has no __entry read) ⇒ no C9 gap. Hygiene note: a register moving under frozen artifacts produces apparent C9 gaps belonging to neither party.
· F6 STATEMENT minor — script has no instrument-liveness assertion (2>/dev/null everywhere; aggregate saves it today).
· F7 STATEMENT — the population axis has no loss counter; without one "population axis" becomes a reclassification that never escalates. DISCHARGE: counter at 1.
· ADJUDICATION 1 (fence question): (a) prose guard holds for the LINEAR reader, fails for the COPYING one — measured: §13's row carried the mislabelled cell verbatim through r18, 1,968 lines from the fence; r19's own remedies split by location (in-place withdraw-and-replace at the copy site, annotation at the origin) — explained entirely by the invariant, by no evidential principle. (b) ★ CONFIRMS the in-place relabel on a STRONGER ground: the mislabel is an authorial GLOSS (same syntactic class as the block's other ← annotations), not an output cell — striking a false gloss falsifies no record of what executed; plus the block was ALREADY edited in r16 (line 1335 says so), plus F3. CONDITION: per-block md5 list ships FIRST; then "27 byte-identical + 1 named delta at block 17" is checked, not asserted. Preferred r20 form specified verbatim in the gate report (strike the false gloss; write "control: present, category facet → 0 (discriminator table below)"; keep the post-fence correction which carries the genuine-absence rows the block never had; restate invariant; pin new concatenated md5 + per-block list).
· ADJUDICATION 2 (verbatim-move method): SOUND (multiset + per-region close each other's blind spots; the surfaced newline artefact is evidence the byte-diff ran) — execution unrepeatable = F2. Gate's substitute: both md5-anchored regions re-derive EXACTLY under independent implementations; cross-reference closure complete (25 §1.1 citations + 12 §4.4c rows all defined, rows 1-46 contiguous). Limit stated: closure proves reachability, not byte-preservation.
· ADJUDICATION 3 (axis separation): SOUND, NOT A DODGE — field-level rows range over field tokens wherever they appear; only call-site-enumerating rows needed the constructor; gate independently read all 8 merged halves (adapterModule/guard/guardArgs, NO endpoint field) — the widening moved the GROUND not the conclusion; form F moves the CALL, not the spec's text; the withdrawn closure statement means nothing live depends on "four". CONDITION = F7.
· ADJUDICATION 4 (#16 treatment): RIGHT, and the general form — register-don't-repair preserves the lesson; F1 is the class's second instance found by asking the class question. Sharpest cell: across the pin window exactly ONE file changed repo-wide = .beads/beads.jsonl, the artefact that moved #16.
· GATE'S OWN INSTRUMENT ERRORS: pipeline $? read tail's exit (re-measured: dead-grep run exits 1); first pre-split search over-restricted (widened; unrecoverability bounded to papers/den-hoag/scratchpads).
· GATE LIMITS: NO nix-eval row re-run (#25-#46, #30a, #12 — largest uncovered surface, incl. keyCategory four-trigger cells + every f631973 quirk-instance figure; pin guard proves them re-runnable in principle); §6/§7/§12/§13/§14/§15.2-8 by targeted extraction only; C9 entries 2-3 anchor sets not independently re-verified.
NEXT: r20 (documentation): F2-fence in-place relabel per the specified form + invariant restated + per-block md5 list in register.sh (F4 first, then the relabel); rows 9/14 both-domains (F1); ledger head records pre-split md5 7b712a934c2fc07483a18de9ff00c951 / 4831 lines + both verification commands (F2); fence-invariant split construction⟂transcript (F3); script instrument-liveness assertion (F6); population-axis counter = 1 (F7). ★ IF GATE 20 FINDS NOTHING IN THE CONSTRUCTION, THE GATE EXITS (two successive clean rounds). COUNT AT ONE. QUEUED behind papers main-checkout writer (o6c-r9fix in flight).



════ ★ REMEDY SPEC — REVISION 20 (2026-07-31, session 4, at 6dc4d44) — GATE ROUND 20 PENDING, ★★ THE EXIT ROUND (COUNT AT ONE) ════
r20 ARTIFACT SET (orchestrator-verified): CORE `b637344f06ff0f84e60a44c32aee9eae` 4380 · LEDGER `64c89f330a348f0ed3a7d07a224eba00` 743 · SCRIPT `9c30d1e2d7a4a423d6a9db3cdfb07f08` 426 (bash -n passes). Author triple-sampled; baseline 79/0 run BEFORE editing; final run 113 pass / 0 drift / 0 skip EXIT=0 (+34 rows: 28 block pins + count + classification + 4 F1 rows).
· F4 FIRST as ordered: per-block pins for all 28 fences, ★ keyed by BLOCK INDEX with positions derived at run time, NOT line ranges (prose edits shift later blocks' lines — a line-range pin would report an unrelated prose edit as a fence change; verified in practice, all 28 resolve after the prose edits). Block 17 re-derived independently = a71de95000322dfd1517ddf2aaaecef2, matches gate.
· THE LICENSED FENCE EDIT LANDED with a ★★ ROUND-TRIP PROOF of the one-line delta (git unavailable — files untracked): reverting only that line in a copy restores block 17's r19 md5 — a sound proof the BLOCK delta is exactly one line. ★ CORRECTED AT GATE 20: the author's whole-file half (r19 md5 also recovered) is REFUTED at the freeze — r20 prose outside the fences (lines 15/37/1343/1373) cannot have existed in r19, so no one-line revert recovers the whole-file md5; it may have held at the author's intermediate state but is unrecoverable and carries no load — the 27 carried per-block pins prove the only-core-change property better. The whole-file arm is DROPPED, never to be re-quoted. Pins moved and recorded both sides: block 17 → fc2fa49404bc6cfbeb1040b28e226a5c; concatenated ea492adb… → 089b45016baa13529527a2d6cc3b27da; other 27 byte-identical vs the r19 list — ★ author states the epistemics plainly: the 27 pins were CARRIED FORWARD not re-derived, so their passing compares against r19's values (a re-derived pin agrees by construction and could not have failed). Invariant restated in the licensed form (construction frozen outright; transcript output cells never editable; glosses editable only under explicit licence); prose both sides of block 17 reconciled ("corrected here rather than in place" was made false by the edit — fixed; discriminator table kept with the why-not-redundant sentence).
· F3: classification re-derived independently — 17 EXECUTED / 10 construction / 1 measurement fragment, matches gate on all three; the fragment is block 10 (§4.3b's fallback-equality cells, "Measured on the same run" context read); ★ script DERIVES the classification from the EXECUTED-header rule and diffs against pins (a block gaining/losing its header is caught, not silently reclassified); block 10 pinned by position, stated why.
· F1 with ★ TWO CORRECTIONS TO GATE FIGURES, both re-derived: corpus clones 18 of 19 NOT 18 of 20 (19 top-level entries, netadr sole non-clone, script-checked); ★★ NEW FINDING — the wrapper's 993 and the .git-excluded 993 are the SAME file set (path-by-path diff, zero both sides) ⇒ the gitignore-honouring wrapper's ENTIRE divergence from system grep on this predicate is the .git exposure, and revision 2's 993 was THIS measurement taken with a tool silently dropping repo internals — the rev-2 mystery solved, recorded in row 14. Lesson sharpened in-row: the pack is a REGENERATED artefact — git gc in any of 18 clones moves the control with no source byte changing. All four figures + the delta-is-that-one-pack assertion script-checked.
· F2: split provenance in the ledger head — pre-split md5 7b712a93… / 4831 + both verification methods WITH the why (multiset invariant under re-partition; byte-diff because multiset is order-blind), labelled RECORDED-AT-SPLIT not re-runnable with the reason (the split consumed its own input). ★ COVERAGE HONESTY: author corroborated md5+4831 in the beads record independently but could NOT find 4949/region-B in the reachable export — those two are labelled TESTIMONY WITH NAMED PROVENANCE (orchestrator dispatch), not mixed into measured rows. (Orchestrator note: 4949 lives in this body's r19 entry — the live bd body, not the passive jsonl export the author searched; the labelling is correct practice regardless.)
· F6: canary() asserts >0 and aborts exit 2 BEFORE any row, ★ THREE families (corpus grep / doc grep / git grep — corpus alone would not catch a dead git grep), ALL THREE positive-controlled (dead GREP, moved CORPUS, unreadable TREE each abort exit 2) — replaces the 36-pass/43-drift shape that indicted 43 rows instead of naming the broken tool.
· F7: population counter at 1 beside spelling 4, two-row table; rule: neither counter absorbs the other's rounds, a reclassification NAMES the counter it moves; ★ the contestable pair flagged explicitly (form F = sixth SPELLING at row 22, its LOSS = population) so a later ruling knows what it must move.
· F5: ledger gains a round-record section (stated purpose: settled facts cheap to state, expensive to re-derive; NOT a changelog) carrying the rb0-witness/44s note as hygiene.
· ★★ INSTRUMENT FINDING (author's, disclosed not mechanized): THE WRAPPER CANNOT BE MECHANIZED — the gitignore-honouring grep is a zsh session FUNCTION, not a PATH binary; a bash script calling grep gets system grep, so the obvious wrapper-identity check compares the system tool to itself and passes VACUOUSLY. Deliberately left as an out-of-band row with the trap explained, rather than a green cell proving nothing.
· LIMITS: nix-eval rows still hand-run (stated in script header, unchanged); corpus pins to working tree (= F1's documented exposure); law 41 observed after every edit (#22 = 7, #43 = 0/0/1 final).
NEXT: GATE ROUND 20 — ★★ THE EXIT ROUND: count is at ONE; if this gate finds nothing in the construction, the gate EXITS (two successive clean rounds). Named adjudications: (1) the round-trip proof — is it sound as a one-line-delta proof; (2) the carried-forward-vs-re-derived pin epistemics; (3) the testimony-labelled split figures; (4) the wrapper vacuity finding — any OTHER register row whose obvious mechanization would be vacuous?



════ ★★★ GATE ROUND 20 VERDICT: ACCEPT-WITH-CONDITIONS — NOTHING IN THE CONSTRUCTION. ★★★ THE GATE EXITS (two consecutive construction-clean rounds: 19 + 20). (2026-07-31, session 4; all six md5 samples match; den-hoag 6dc4d44; register.sh 113/0/0 exit 0, canaries LIVE 1681/6969/638 and all three positive-controlled to exit-2 abort; 28 block hashes independently re-derived, all match; four rows re-derived with independent commands.) S0 + C1/C1-a/C2/C5/C6/C7/C7-a/C7-b/C8 PASS · C9 pass-with-condition (F4). FOUR findings, all STATEMENT-LEVEL, none resets. NOT a soft exit: the gate attacked SIX fresh construction claims by re-execution (fence 11's §4.3b equivalence on real gen-graph 231b319 — 26 in-domain pairs 0 disagreements with 30 out-of-domain firing as the named shape, comparison non-vacuous; fence 2 memo force structure 3/3; fence 4/5 sourceOrderOf verbatim — all four admits + three refusals + STRICT and CONTAINABLE both hold; fence 8 rev-2-vs-3 omission measurement; §4.3a two-selector or; fence 26 rev-consulted) and chased two would-be construction leads that DIED on the document already deriving them (the quirkClassOverlap definition-time guard — §13's break row already scopes to NATIVE with the guard named; the ownEntry one-hop __entry read — ledger :229 already enumerates it not-claimed-clean). Meaning check around the licensed edit: no claim inverted; the edit strengthens the block to a second instance at a second category. ════
· F1 RELAY-LEVEL (charged to the ORCHESTRATOR'S RECORD, not the artefact — the artefacts never claim it; core :36 claims only "the only fence change in revision 20", TRUE and proved): the whole-file round-trip half is false-in-principle at the freeze. r20 entry above CORRECTED IN PLACE this session. Block-level arm re-executed sound.
· F2 STATEMENT — six of the script's 113 rows cannot fail independently (#43's dotted predicate is a strict refinement of the widened one checked above it — containment confirmed with a synthetic 2×/1× control; five others are arithmetic consequences: 18=12+6, 26=18+8, 41=18+8+15, 22=30−8) — "113 pass" overstates discriminating checks by ~6. DISCHARGE: mark derived rows in the script's coverage header.
· F3 STATEMENT — §4.4c fourth-member cell states the colliding set unqualified while the tree refuses class-plus-channel at definition time ON THE COMPAT ARM (errors.quirkClassOverlap, one caller compile.nix:2195) — §13's break row already carries the NATIVE qualifier and the guard; the cell wants the same clause. (The gate's strongest lead; died on §13.)
· F4 STATEMENT — ledger :736 "this design's path reads no __entry at all" contradicted by the ledger's own :229 enumeration (ownEntry at resolved-aspects.nix:481 sits one hop upstream of forwardExpand, whose emit the design edits). C9 consequence NIL, checked not assumed (no expression the design CHANGES reads __entry). DISCHARGE: narrow to "reads no __entry in any expression this design changes".
· ADJUDICATIONS: (1) round-trip half-sound (F1) — drop the whole-file arm; (2) carried-forward pins SUFFICIENT with the inherent chain-limit stated (r19 values rest on gate 19 having checked them — a chain, not a proof; document doesn't claim otherwise); all 28 independently re-derived and matching; (3) testimony figures CONFIRMED in the live bead body by --json (4949 ×4, region-B ×1) and testimony-labelling ruled CORRECT (mixing an unverifiable figure into measured rows is how a register goes stale while reading current); (4) wrapper vacuity VERIFIED by execution (bash comparison answered identical) — class has more members: F2's six entailed rows + row 15's cannot-match control, which the ledger already discloses BY NAME as the correct practice.
· ★ ONE UNRECONCILED HISTORICAL FIGURE, not reported as drift: §4.3b cites the round-4 gate's "36 disagreements"; the gate's grid reproducing the companion 26 exactly measures 30; round-4 parameters recorded nowhere ⇒ label it TESTIMONY WITH NAMED PROVENANCE like the 4949 figure (it currently is not).
· GATE'S OWN ERRORS: flake.lock alias near-miss (nodes.gen-graph vs gen-graph_3 — a law-38-shaped false positive caught by following the alias); unescaped dot in the vacuity test (harmless, same pattern both sides); one cwd-bled git status re-run with -C.
· GATE LIMITS: nix-eval rows (#25-#46, #30a, #12) not re-run wholesale (six hand re-executions; f631973 quirk-instance figures verified for expression behaviour under a stub keyCategory only); §6/§7/§12/§13/§14/§15.2-8/§16 by extraction; C9 entries 2-3 anchor sets not independently re-verified.
NEXT: r21 (the exit conditions, all one-line): F2 derived-row marks in script header; F3 the NATIVE qualifier clause in the §4.4c cell; F4 narrow the round-record sentence; + label §4.3b's 36 as testimony-with-provenance. THEN: the track leaves the gate — the remedy spec is VALIDATED; commit at the round boundary; next work order is IMPLEMENTATION planning against the spec (spec-before-development satisfied; the defect this bead records is now remediable by validated design).



════ ★★★ REVISION 21 — EXIT CONDITIONS DISCHARGED. THE REMEDY SPEC IS GATE-VALIDATED. (2026-07-31, session 4, at 6dc4d44) ════
FINAL ARTIFACT SET (orchestrator-verified, committed at the papers round boundary): CORE `35849d1f6c73b900fc4c2606b7af736c` 4390 · LEDGER `69c5e2a155369949a9c584b99672bf79` 748 · SCRIPT `f4a8c6e61b346d823df0ab7a09c99808` 440 (old script md5 9c30d1e2… recorded). register.sh 113/0/0 exit 0; concatenated fence md5 UNMOVED (089b4501…); 27 blocks at r19 values + block 17 at its r20 value; §15.1 invariants hold.
· F2: coverage header names the derived rows — ★ the author found the FIFTH the dispatch under-specified (row 22's forward 15 = 7+7+1, alternation-partition argument + measured halves) ⇒ six = 18=12+6, 26=18+8, 15=7+7+1, 41=18+8+15, 22=30−8, #43-containment (containment CHECKED not restated: dotted ⊂ widened derived from the string shapes). Recorded-not-counted: row 23 arm-3 reuses $R_F (shared measurement, different limitation class). Two candidates REJECTED as derived with reasons (row 1's union is a corpus fact; F1(a) sums fresh measurements) — the six is not under-tight.
· F3: fourth-member cell carries the NATIVE-arm qualifier; verified in-tree (quirkClassOverlap defined compat/errors.nix, exactly ONE caller in compile.nix's channels binding, both under lib/compat/ — "compat arm" is a measured statement); cites §13's row + den-hoag-bfq. ★ Anchor discipline: cited by ENCLOSING BINDING not file:line — an unbackticked line anchor would evade the register check while violating the rule; the line number stays in the report, out of the document.
· F4: narrowed to "reads no __entry in any expression this design changes" with the ownEntry→roots→forwardExpand neighbourhood stated and the ledger's own census pointed at; verified in-tree by binding name.
· The 36: testimony-with-named-provenance label landed — parameter gap not drift (round-4's channels/relations recorded nowhere; the run is unreproducible by construction); the load-bearing half named as the 26-with-control, which re-executes.
· Law 41: #22 = 7, #43 = 0/0/1 (both new citations backticked, no line numbers — anchor sweep unmoved); 28 pins pass; fence count 56.
· ★ AUTHOR'S ORDERING EXPLANATION for the refuted whole-file arm, accepted: the round-trip ran after the fence edit and BEFORE the head/block-17 prose edits — true when executed, false by the freeze, stated without the ordering qualifier. Matches the gate's diagnosis.
· ★ MTIME NON-TOUCH WITNESS RETIRED for this round: the ops-seam artifacts moved during the session (the o6c-r10fix author, expected) — the author flagged that mtime no longer discriminates rather than repeating the claim on a dead witness.
════ TRACK STATE: the class-content consumer-unification REMEDY SPEC (this bead's fix design) has EXITED the adversarial gate — construction-clean at rounds 19+20, exit conditions landed at r21, all artifacts committed. NEXT WORK ORDER: IMPLEMENTATION against the validated spec, in the spec's own landing order, suite-gated per unit (baseline at 6dc4d44: ci 2071/2093 with 22 red = 9❌+13☢️, parity 71/71 — red set at session scratchpad suite-baseline-redset.txt, restated here: the landing gate is BYTE-IDENTICAL red set, growth or shrink both fail the unit until dispositioned). Spec-before-development SATISFIED. ════



════ ★★ IMPLEMENTATION UNITS 1-2 LANDED GREEN (2026-07-31, session 4) — be721c6 + f56704c, orchestrator-verified ════
· ★ SPEC GAP FOUND AT FIRST CONTACT: the spec declares NO LANDING ORDER (no phasing/sequencing section in 4390 lines; §14's "land" is about where acceptance rows go). Implementer derived the order from the construction's own dependency graph: §4.1 (element fifth field) and §4.3b (preimageOf/srcOrder totality) are the only dependency-free pieces — §4.2 memo needs §4.3b+§4.4; §4.3 needs §4.2; §4.4/§4.5 need §4.3. DERIVED ORDER RATIFIED: §4.1+§4.3b (landed) → §4.2 → §4.3 (+§4.3a's actions abort) → §4.4/§4.4b → §4.5 → §14 acceptance arms.
· UNIT 1 (be721c6): forwardExpand.emit stamps assertedClasses = { } (additive, no reader yet — readers are §4.3's assertedOf + §4.5's union, downstream). Sole-producer claim verified (sharedFoldKey = → 4 hits: 2 seed-record producers in class-modules, 1 comment, 1 emit).
· UNIT 2 (f56704c): §4.3b's preimageOf/srcOrder transcribed VERBATIM from the spec block. Equivalence MEASURED against real gen-graph/gen-prelude from this tree's flake: 25 in-domain pairs / 7 relations / 0 disagreements, control 18-of-21 out-of-domain disagreements firing the named shape (non-vacuous). ★ 25 ≠ the spec's 26 stated as a PARAMETER DIFFERENCE (its seventh relation self-only vs fan-out), own figure reported, no false reproduction claim.
· SUITE GATE: ci 2071/2093 EXIT 1, red set 22 BYTE-IDENTICAL to baseline (diff empty); parity 71/71 EXIT 0. Exit codes captured directly, not through pipes. Spec declares no red-set change for these units; none occurred (consistent — §14's arms test the extraction/injection halves, unbuilt).
· FORMAT GATE: ci arm exit 0 / 353 files / 0 changed. ★★ NEW INSTRUMENT DEFECT FOUND AND FILED (den-hoag-vwm, P2): the PARITY arm is DESTRUCTIVE — stale mdformat rewrites 5 unrelated md files and exits 1; implementer reverted all five by name, committed none. PER-UNIT FORMAT GATE IS CI-ARM-ONLY until vwm's acceptance passes.
· JUDGEMENT CALL RATIFIED: §4.3b's in-tree comment states the standalone theory (Ρ(n) only moves content; a channel outside its domain reads untouched; [ ] there is a drop not a rest) instead of the spec's forward-referencing ground (sourceOrderOf's or [ c ] equality — unbuildable until §4.2/§4.3 exist). Correct under the no-temporal-comments rule; the §4.3b framing lands as a one-hunk follow-up WITH §4.3 if wanted.
· LIMITS: neither unit observable at HEAD (§4.1 no reader; §4.3b's changed branch unreachable from classSeedsAt whose c ⊆ frame.rel.nodes) — the suite proves ABSENCE OF REGRESSION, which is what these units are for; nothing partial started.
NEXT: UNIT 3 = §4.2 (the class-relocation memo), now unblocked. Then §4.3 + §4.3a. Same gates: red set byte-identical (until a §14 arm declares otherwise), ci-arm format only, commit per unit SKIP=ci,treefmt, no push.



════ ★★ IMPLEMENTATION UNIT 3 LANDED GREEN (2026-07-31, session 4) — e90b0b7, 7 files +247/−22, orchestrator-verified ════
· Sections executed: §4.2 (class-relocation memo) + §4.4 (injection element literal) + §4.4b rows 0/(i) (both reserved-channel refusals) + §4.3a #2 (named actions abort — ★ DISPATCH CORRECTION: belongs to unit 3, its expression is inside §4.2's own fence) + §7 item 6 (keyCategory crossing, four-instrument migration).
· ★ THE MEMO IS READ BY NOTHING YET — MEASURED DIRECTLY, not suite-inferred (probe over a synthetic self per §5.3's instrument shape, real schema instance, EVERY row controlled same-run): acyclicity guard behind BOTH fields (cyclic aborts both, acyclic control returns both); .injections strict in domain with no inject acts (the rejected short-circuit's fail-open measurably absent); the two fields forced INDEPENDENTLY (one record: .sourceOrder returns, .injections refuses — the split three revisions asserted wrongly); both refusals fire the spec's EXACT strings, all four admits/aborts correct (A + spool admit; _u/settings/meta/artifact abort); injection order = frame's node domain not act order (both act orders → same [iX iY]); actions split works (no key → named abort; { } → total [ ]); sourceOrder rows exact. §1.1 #25's keyCategory cells independently reproduced at HEAD.
· ★ IMPLEMENTER'S SELF-CAUGHT INSTRUMENT ERROR (the project's recurring class, recorded): first message-capture grep's domain included Nix's SOURCE-LINE ECHO of the throwing expression — reported uninterpolated ${id}/${c} in messages, a defect that did not exist; narrowing to `^ +error: den-hoag` gave the real interpolated strings. A grep over an error trace sees the code as well as the answer.
· SUITE: ci 2071/2093 EXIT 1 red set 22 BYTE-IDENTICAL; parity 71/71 EXIT 0; format ci-arm-only EXIT 0. Spec declares no red-set change at §4.2 (every expectation move sits at §4.5's element-major nesting); none occurred.
· ★★ UNIT 4 IS ATOMIC — MEASURED, NOT ESTIMATED: §4.3 cannot land without §4.5 (its first sentence un-exports classSliceOf, which has 12 LIVE SITES outside its file — 3 production folds in output-modules.nix :590/:659/:769, parameter threading ×3, 6 instrument sites — every one must move to classSliceAt whose eval handle IS §4.5's consumer rewiring; no intermediate state exists). Unit 4 = §4.3+§4.5 together, and THE RED SET MOVES BY DESIGN: §9.2 derives test-diamond-answer → [cA cB cC cD] and test-unregistered-intermediate-delivers → [cA cB], ORDER-ONLY, multiset identical. Stopping green was the instruction; correct call.
· ★ SPEC GAP RESOLVED CONSERVATIVELY, ORCHESTRATOR RATIFIES: where does an injection land whose channel is OUT-OF-DOMAIN (unregistered AND not a Ρ endpoint)? Neither §4.2 nor §9.2 states it; §8's row for that input PRESUPPOSES the element exists ("the extraction would return the module. But nothing ever asks") — and §8 is inside the validated construction. Implementer emits all injections: in-domain ordered by the domain, out-of-domain APPENDED IN NAME ORDER — the same choice relOf's own node domain makes for unregistered endpoints, deterministic by construction, and order-insensitive at every current reader (forwardSourceClassesOf's attrset union; assertKeysRegistered's seq fold). RULING: conforms to the validated spec's own §8 disposition; the ordering is mechanical determinism, not a new semantic. CONSTRAINT FORWARD: if any later unit gives such an element a READER, that unit's gate must adjudicate the position explicitly — the choice is ratified as unobservable, not as load-bearing.
· LIMITS: memo behaviour rests on the probe, not the suite (suite contribution: the builder-argument + third-equation + four-instrument migration moved nothing); the two classifyKey stub replacements agree with the old stubs ON THOSE FIXTURES only (stated); mkClassSlice threads keyCategory unread until §4.3's source-side refusal.
NEXT: UNIT 4 = §4.3 + §4.5 ATOMIC, with §14's acceptance arms becoming expressible and the two order-only expectation moves landed against §9.2's quoted derivation. Then §4.4b's remaining rows + §14 arms + the §4.3b comment follow-up.



════ ★★★ IMPLEMENTATION-CONTACT FINDING IC-1 — SPEC-INTERNAL CONTRADICTION, RE-ENTERS THE GATE (2026-07-31, session 4; unit 4 STOPPED AND REVERTED, tree green at e90b0b7 byte-identical to the gated state) ════
· THE CONTRADICTION (exhibited, all sites): §4.3 (spec line 403) declares scopeOf/assertedOf/sourceOrderOf "let-bound, UN-EXPORTED helpers in class-modules.nix"; §4.5's projectClassScoped fence (:1821-1828, lives in output-modules.nix) calls assertedOf AND scopeOf by name; §4.5b's destination arm (:2076-2082) calls sourceOrderOf at three further output-modules sites. NO EXPRESSION SATISFIES BOTH. And plain export contradicts three MORE pinned sections: §13's mkClassSlice row ("returns exactly … three bare functions"); §7 item 7 prices the destination read as crossing "no module boundary" (true only if exported-and-threaded — a crossing the cost section does not price, beside item 6 which prices its crossing carefully); §14.5's construction guard is written over classSliceOf/rawSliceOf/classSliceAt and exists to guard "the absence of an exported raw read" — six exports would put its own surface outside its predicate. ⇒ TWENTY GATE ROUNDS OF ADVERSARIAL READING DID NOT CATCH A CROSS-SECTION COMPOSITIONAL CONTRADICTION THAT ONE IMPLEMENTATION CONTACT DID. The gate exit stands for what it reviewed; IC-1 enters as a NEW construction finding = spec r22 + gate round 21.
· ★ ORCHESTRATOR RULING (theory-grounds, direction not final wording): EXPORT THE QUERY, KEEP THE PROJECTIONS PRIVATE. sourceOrderOf is a graph QUERY (Ρ-preimage order) — a legitimate kernel surface; scopeOf/assertedOf are element PROJECTIONS whose data the elements ALREADY CARRY (§4.1's emit returns { key; content; sharedFoldKey; scope }; assertedClasses landed at unit 1) — §4.5's fence should read e.scope / e.assertedClasses through the extraction's own elements. mkClassSlice returns FOUR functions (the three §13 names + sourceOrderOf); §13's row, §7's pricing (item 7 must PRICE the one crossing it gains, like item 6 does), and §14.5's guard (predicate widened to cover sourceOrderOf's export as a NON-raw read, its purpose intact) all get consistent edits. ★ OBLIGATION ON THE AUTHOR: establish with evidence whether e.scope ≡ scopeOf n on every element classSliceAt returns for node n — if they can DIFFER (element's emitting scope vs the projected node's scope), the fence rewrite changes semantics and the round must say so and decide; if the author finds the identity fails and no clean form exists, STOP — that becomes a genuine owner fork.
· ★ IMPLEMENTER'S GREEN-SEAM CORRECTION accepted: unit 4a = construction (§4.3+§4.5+§4.5b+§4.5c + instrument migration + the two §9.2 expectation updates; §13 enumerates 13 files) → unit 4b = acceptance (§14.1-14.7; §14.2 alone 28 arm rows). Genuine seam; dispatch separately once r22 gates.
· ★ THREE DESIGN RESOLUTIONS FROM THE DISCARDED WORK, kept for the 4a dispatch: (1) class-seeds readsAttrs KEEPS declarations and ADDS class-relocation (§13 says "gains"; the file's norm is over-declared read edges); (2) the shared aspect-identity projection's real reason: the three aspect-answering reach readers disagree on a null key (seen0 skips silently / pathSetOf listToAttrs aborts unnamed / mkEntityHasAspect maps a pseudo-aspect with null identity) — ONE projection makes them answer alike; (3) reach's edge-closure project arm stays UNTOUCHED while the structural arm gains injections — the asymmetry is load-bearing and easy to "tidy" into a bug.
· LIMITS: the contradiction sweep covered these sites only — the r22 author must sweep the spec for FURTHER helper-visibility mismatches of the same class; no suite run needed (tree byte-identical to the gated commit, git status the evidence).
NEXT: SPEC r22 (papers main checkout) executing the ruling above + the class sweep; then GATE ROUND 21 (adjudicates IC-1's discharge; count resets to ZERO for the re-entry); then units 4a/4b.



════ ★★ REVISION 22 — IC-1 RESOLVED; IC-2 FOUND AND RULED; GATE ROUND 21 PENDS r23 (2026-07-31, session 4; committed papers 813c73e) ════
ARTIFACT SET (orchestrator-verified): CORE `09e18755888b823a17cc429c18f7072c` 4545 · LEDGER `2d37b35b85a39068307cb15963807bb5` 807 · SCRIPT `2a1f8c23a2e49e61ad5ad05408bd16da` 487. register.sh 113/0/0 exit 0. TWO construction fences moved, named + pinned both sides (block 22: 3f1ad8bc…→9bc7b5a3…; block 24: a1160fd6…→610382f2…; concatenated →efee8a24…; cumulative since r19: 25 of 28 byte-identical, 3 moved each under a named finding; all 17 transcripts untouched). Fence invariant restated general-form: construction blocks change only where a NAMED finding requires it.
· ★★★ IC-1's IDENTITY HOLDS — AND THE RULING'S WORDING WAS CORRECTED BY THE AUTHOR: (1) the literal e.scope form is UNWRITABLE (classSliceAt's return carries neither field; the ruling's parenthetical named the RESOLVED-ASPECT element, which the fence binds as n, not e) — the writable rewrite reads the REACH element, and the failed reading is recorded in-doc so no future round re-proposes it; (2) on n the identity is DEFINITIONAL (scopeOf IS `e: e.scope or throw` — same field, same object; they differ only on ABSENCE); (3) absence UNREACHABLE at e90b0b7 on BOTH producers (forwardExpand.emit writes scope+assertedClasses unconditionally in the record literal, with the in-tree totality commitment quoted; injectionElementsAt.elementAt writes both on the admitting branch, refusing branches return NO element) ⇒ no semantics change on any producible element; continuous with §10 entry 5's own deleted-`or id` ruling (producer totality over reader re-check). The emitting-vs-projecting hazard REAL but does not land (element carries EMITTING scope; §4.7 row 6 already measured it; the breaking form is the deleted or-fallback).
· ★★ NEW FINDING BEYOND THE RULING — THE EXPORT MUST BE REQUIRED, NOT DEFAULTED: output-modules receives the existing three as defaulted formals; a defaulted sourceOrderOf would answer [ c ] = HEAD's behaviour at the destination coordinate — an assembly that forgot to thread it SILENTLY REPRODUCES den-hoag-4kh.41 at the three §4.5b sites, and §14.5's lexical guard CANNOT SEE IT (the compare is gone, the read is present, the answer is wrong — the guard's own stated limit becoming load-bearing). Fourth formal REQUIRED; breaks the same four instruments item 6's required argument already breaks — a feature not a cost.
· EDITS ALL LANDED: §4.3 visibility split + IC-1 statement + theory (a graph query is a surface; a field projection is not) + required-not-defaulted derivation; blocks 22/24; §13 row → FOUR functions (inertness preserved); §7 item 7 NOW PRICES its crossing in item 6's terms (evaluation cost nil — threading changes where the name resolves, not how often it runs); §14.5 predicate SPLIT in three (no-exported-RAW-read kept exact — sourceOrderOf returns names not content; export set CLOSED at four; scopeOf/assertedOf zero outside class-modules — the lexical form of the ruling, non-vacuous: at r21 it answered 2) + what the row CANNOT see recorded (the defaulted fail-open — value-level, lexically uncarriable).
· ITEM-5 RESOLUTIONS CARRIED with sharpened grounds: readsAttrs declares OWN dependencies not transitive closure (reach reads declarations directly — dropping it states an edge that does not exist); the aspect-identity projection's three-readers table (seen0 skips SILENTLY / pathSetOf aborts UNNAMED at the evaluator / mkEntityHasAspect maps a null-identity PSEUDO-ASPECT onto a v1-facing surface — three answers, none right ⇒ construction not refactor); reach's project-arm asymmetry tied to the single-visit law being keyed on aspect identity, the field an injection lacks.
· CLASS SWEEP: 476 pairs (17 private symbols × 28 fences), CLEAN after the fix; positive control = byte-exact md5 reconstruction of block 22's pre-fix text (predicate fires 1+1 there, 0+0 after — the zero is a measurement). ★★ IC-2 FOUND BY THE SWEEP, REPORTED NOT FIXED (correct discipline — a wrong fix inside a construction fence is worse than a reported contradiction): block 22's fence still reads `forwardModulesFor reach exempt class` (3-arg HEAD form) while §7 item 7 AND §13 both specify forwardModulesFor TAKES id after the change — same family as IC-1, signature-vs-call-site. ★ ORCHESTRATOR RULING ON IC-2: the fence is the outlier (the two non-fence sections agree); block 22 takes the id-bearing form as §7/§13 specify, priced under item 7's existing crossing (same migration, no new surface). r23 = this one fence edit + its knock-ons, then GATE ROUND 21 attacks both changed-fence rounds together.
· ★★★ AUTHOR'S SILENT INSTRUMENT ERROR, CAUGHT — RECORD FOR EVERY FUTURE REV-PINNED RUN: `git grep pattern -- <rev>` puts the rev in PATHSPEC position — matches nothing, falls back to the WORKING TREE silently; every row read HEAD while appearing rev-pinned; the tell was answers identical to the un-pinned run. Fixed by argument order + a standing HEAD-DRIFT NOTICE control (prints rev answer beside HEAD answer; three rows differ by the landed implementation and are the permanent control: #11 9→10, #16-control 12→13, #36-control 19→20). ★ Pin-guard conversion: rows now read AT THE REV THEY STATE (2e44ff5) — reproduces each cell permanently however far HEAD travels; #16's repo-wide figure deliberately stays at HEAD (its stated domain is the repo incl. the beads export, not the code at a rev).
· LIMITS: the e90b0b7 producer-totality evidence is a READ of both record literals, not an execution (the executed arm named, not run); nix-eval rows hand-run unchanged.
NEXT: r23 (block 22's id-bearing forwardModulesFor + knock-ons) → GATE ROUND 21 (adjudicates IC-1 discharge + IC-2 fix + the two changed-fence rounds; the track re-earns its exit: two construction-clean rounds from zero) → units 4a/4b.



════ ★ REVISION 23 — IC-2 CLOSED (2026-07-31, session 4; committed papers f71a906). TRACK PARKS HERE THIS SESSION (owner directive: no new dispatches) — GATE ROUND 21 IS NEXT SESSION'S OPENER. ════
ARTIFACT SET (orchestrator-verified): CORE `8c7eb755af768919dce1efd093b73dd5` 4577 · LEDGER `40ed6df3bf13881e78033ee1603056e4` 848 · SCRIPT `36029b5fcec6562e9ac6aef70a3773aa` 489. register.sh 113/0/0 exit 0; head-drift controls still firing (#11 9→10, #16 12→13, #36 19→20 — proof the rev-pinned reads still read the rev).
· IC-2's SIGNATURE SOURCE: the three sections AGREE and are ALL SILENT on order ("takes id; today reach: exempt: class" ×3, no new-order depiction anywhere — SILENCE not conflict, the stop case did not fire). ORDER SETTLED BY DERIVATION from the tree's own convention at e90b0b7: both sibling scope-id-taking bindings put id immediately after exempt (routeRemapFor = exempt: id: class; remapOver = exempt: srcScope: route) ⇒ `reach: exempt: id: class` — a pure INSERTION with no existing argument reordered, and the last three arguments become identical to routeRemapFor's entire list, the two called adjacently in the same fold on the same exempt/id/class. ★ RECORDED AS A DERIVATION with the sentence to correct if implementation fixes a different order — a derived order never reads as a quoted one.
· Block 22 moved AGAIN under the named finding: 9bc7b5a3…→89ef6d6d…; concatenated →b022f892…; cumulative ledger now in the core head: 3 distinct blocks / 4 named moves (22 moved twice), 25 of 28 byte-identical to r19, all four concatenated values pinned.
· KNOCK-ONS: §4.5 prose carries the IC-2 statement + derivation; §7 item 7 confirms-and-prices (NO new price — the threading is the one it already charges; the argument is id, which projectClassScoped already holds); sweep re-run 476 pairs clean. ★ TWO SITES DELIBERATELY NOT CHANGED, each checked: §4.5a's parenthetical and §15.1's sum both say "at HEAD 2e44ff5" in their own sentences — rewriting either converts a true HEAD statement into a false one, THE MIRROR OF IC-2 ITSELF; recorded so a later round does not "fix" them.
· ★★ THE ROUND'S KEY LIMIT, WRITTEN INTO THE LEDGER: THE CLASS SWEEP COULD NOT HAVE CAUGHT IC-2 — its population INCLUDED the pair and it reported clean CORRECTLY (visibility predicate: forwardModulesFor is let-bound in block 22's own file). IC-2 is a DIFFERENT PREDICATE on the same population (arity/order agreement between a fence's call and the sections specifying the binding) and nothing in the register asks it — law 37's shape, domain right, predicate narrower than the class. Mechanizing the second predicate = a new instrument = specified before written; correctly declined mid-round.
· LIMITS: order derived-not-quoted (the one chose-rather-than-read in r23, flagged); sweep covers visibility only; den-hoag read-only, two sibling signatures read not executed.
NEXT (next session): GATE ROUND 21 over the r23 set — adjudicates IC-1's discharge (the definitional identity + producer-totality reads), IC-2's derived order, the required-not-defaulted export, the three changed fences across r22+r23, and the arity/order-predicate gap (does it become an instrument or a stated limit). Count ZERO; track re-earns exit from scratch. THEN units 4a (13-file atomic §4.3+§4.5 landing) / 4b (§14 acceptance arms) via the standing implementer.



════ ★★★ SECONDARY-ANCHOR CORRECTION 2026-08-04 — A DEAD CONTROL ON A P0. Orchestrator-reproduced. ════
THE PRIMARY ANCHOR IS SOUND, so this bead is NOT adrift and no re-scoping follows. Verbatim at ffaafb8,
`git grep -n "terminalModulesAt = " ffaafb8 -- lib/`:
    lib/attributes/output-modules.nix:940:  terminalModulesAt = id: class: projectClass id class;
exactly the expression the title cites. Subjects live: `declare.inject` 4 files, `declare.reroute` 2 files.

★ THE SECONDARY CITATION IS DEAD, AND IT IS A LAW-39 TRAP:
    git grep -c "forwardSourceClassesAt" ffaafb8 -- lib/ ci/ | wc -l  →  0 files
    git grep -c "forwardSourceClassesOf" ffaafb8 -- lib/ ci/ | wc -l  →  8 files
The live spelling is `...Of`, not `...At`. ⇒ A VERIFIER USING `forwardSourceClassesAt` AS A POSITIVE CONTROL
GETS A ZERO CONTROL AND AN INVALID RUN THAT READS AS A CLEAN ABSENCE FINDING. Second instance of this exact
shape in one session (the first: `channelBindingsAt` on den-hoag-dcx), and this one sits on a P0.
★★ AND THE SHARPEST PART: `git log --format="%h %s" -S"forwardSourceClassesOf" ffaafb8 -- lib/ ci/` returns
commits tagged **(den-hoag-4kh.41)** — d1ee769, ad5b777, be721c6 among them. THIS BEAD'S OWN LANDING WAVE
INTRODUCED THE SPELLING THIS BEAD DOES NOT USE. A bead can be made stale by its own work.

★ AND A CORRECTION TO A CORRECTION, because the first sweep lumped three zeros together and only one is real:
`reachableWhere` and `coScc` are NOT decayed citations — THEY NEVER EXISTED IN THIS TREE.
    git log -S"reachableWhere" --oneline ffaafb8 -- lib/ ci/          → 0 commits
    git log -S"coScc"          --oneline ffaafb8 -- lib/ ci/          → 0 commits
    CONTROL same instrument same run: -S"forwardSourceClassesOf"      → 5 commits
The control fires, so the instrument finds removals where they happened. Those two are proposed or gen-side
names. ⇒ A `git grep` zero and a `git log -S` zero MEAN DIFFERENT THINGS: the first says "absent now", the
second says "never present here". Only the pair separates a decayed anchor from a name that was never code.


## Comments (36)

### 1 — 2026-07-28T06:10:17 · Jason Bowman

★ OWNER RULING, 2026-07-28: "the change is acceptable."

The design's §13 Q1 is ANSWERED YES. Unifying both class-content consumers onto the single channel-coordinate seed query is APPROVED, including the observable change to what the public `declare` export does (lib/default.nix:2730).

⇒ THIS DEFECT IS FIXED BY CONSTRUCTION, NOT BY REPAIR. The rejected alternative was to apply the inject/reroute acts a SECOND time on the terminal path — which would have been a repair in the precise sense C7 objects to: an invariant that must be re-applied at every future consumer of class content, regressing silently the moment a third consumer appears. Under the approved decision there is ONE query and therefore no second place for the acts to be missing from. The defect cannot recur because the shape that permits it is gone.

THE FALLBACK IS NOW MOOT and should not be revived: 'keep two disagreeing sources' was explicitly not recommended by the design and is not recommended here. Two sources of truth for the same value, with no test comparing them, is what produced this defect.

SEQUENCING: this bead closes when den-hoag-4kh.16's design is IMPLEMENTED, not when it is gated. Until then the defect is LIVE — `declare.inject`/`declare.reroute` remain public verbs that do not reach the built system, and the corpus does not exercise them (Ρ=∅, Ι=∅ fleet-wide), so nothing will surface it in the meantime.
★ A WITNESS IS OWED AND MUST LAND RED FIRST: a fixture that declares a relocation and asserts it is present in the TERMINAL output — not in the attribute. The existing suite cannot catch this because ci/tests/edge-completeness.nix:214 asserts the attribute, which is correct. The new fixture must compare the two consumers against each other, since that is the only thing their agreement is visible in.

### 2 — 2026-07-28T06:25:19 · Jason Bowman

★ CAVEAT ON THE OWNER RULING — THE RULING STANDS, BUT THE DESIGN CANNOT YET EXPRESS THE CHANGE IT AUTHORISES.

The 2026-07-28 ruling ('the change is acceptable') approved unifying both class-content consumers, which closes this defect by construction. The bucket-to-seed-query gate has since found that THE UNIFYING HALF HAS NO EXECUTABLE FORM:
  E10(b) does `concatMap (n: … classSeedsAt n class) reach`, but `reach` (lib/attributes/resolved-aspects.nix:313, emit :126-133) yields records `{ key; content; sharedFoldKey; }` WITH NO SCOPE COORDINATE, while `classSeedsAt` requires a NODE ID. It is internally inconsistent within four lines — the same `let` calls `forwardSourceClassesOf reach` (treating elements as ASPECT records) and then feeds those same elements to `classSeedsAt` (needing IDS).
★ AND THE REPAIR IS NOT MECHANICAL. A reach element carries no coordinate, so there is NO WAY TO SAY WHOSE `Acts` GOVERN A REACH-SOURCED ASPECT. That is an owner-level SEMANTIC question the design never poses: do the PROJECTING SCOPE's acts govern, or the aspect's OWNING SCOPE's? The two give different answers whenever an aspect reaches a node that did not declare it — which is the only case that matters here.

⇒ THE RULING IS NOT INVALIDATED; it authorised the intent and the intent is right. But it was given on a change whose semantics are underdetermined, so a SECOND, NARROWER question is owed before implementation: WHICH SCOPE'S ACTS GOVERN A REACH-SOURCED ASPECT.

★ AND A SECOND BEHAVIOUR DELTA WAS NOT COVERED BY THE RULING AT ALL — it was not in the design when the question was asked. Today `projectClass` (output-modules.nix:741-745) computes `exempt = forwardSourceClassesOf reach`, REACH-sourced deliberately (class-modules.nix:56: 'an unregistered fromClass a meta.__forward spec on a REACHED node names'). The design's E6 computes it OWN-NODE only, and in E10(b) the reach-sourced set is used only by routeRemapFor/forwardModulesFor — the content leg loses it. CONSEQUENCE: a `meta.__forward` spec on a reached-but-not-own aspect stops exempting, so `classifyKey` ABORTS on a typo where content materializes today. That is a compat-fleet-visible regression, unstated in the design and outside what was approved.

THIS DEFECT REMAINS LIVE AND UNCHANGED: `declare.inject`/`declare.reroute` still do not reach the built system. Nothing here alters that; it alters only what the fix must settle first. The witness owed (a fixture asserting a declared relocation reaches the TERMINAL, not the attribute) is unaffected and can be written now — it is red today and should be.

### 3 — 2026-07-29T01:57:28 · Jason Bowman

★★★ MECHANISM CONFIRMED AND EXPLAINED — THIS BEAD AND E10(b) ARE THE SAME DEFECT SEEN FROM TWO SIDES. Independent verification at 4b61112 (222af84 is an ancestor; the three relevant files are unchanged since it).

THIS BEAD SAYS declare.inject / declare.reroute do not reach the built system. THE PRECISE REASON:
    projectClass = id: class: ... prelude.concatMap (n: ... classSliceOf exempt n class) reach ++ routeRemapFor exempt id class ++ forwardModulesFor reach exempt class;
classSliceOf is the RAW per-aspect extraction, reading content.${class} DIRECTLY. ★ frameAt, srcOrder, preimageOf, relocationsOf and rawSeedsAt APPEAR NOWHERE IN projectClass's CALL GRAPH — positive control: grepping reroute|relocat|injects over the whole of output-modules.nix returns ONLY PROSE, while the same grep over class-modules.nix hits the live filters. reroute and inject have EXACTLY ONE consumer each in all of lib/, both inside class-seeds.compute, which is strictly node-local.
So relocation is computed correctly by the shipped query and then NOT CONSULTED by the terminal projection. All three terminal reads — contentIdsOf, deltaOf (modules = terminalModulesAt id name), hostModules — route through projectClass. (NOT exhaustively traced: whether the gen-edge fold output re-enters deltaOf by another route.)

★ AND THE SIBLING ASYMMETRY IS THE STRONGEST EVIDENCE THAT THIS IS AN OMISSION RATHER THAN A DESIGN: routeRemapFor exempt id class DOES read declarations at the projecting scope (routesAt id -> deliveriesAt id -> declarations.actions.resolution). ROUTE declarations are honoured at the projecting scope; reroute/inject are honoured NOWHERE ON THIS PATH. Two sibling relocation mechanisms, two treatments, no comment reconciling them — in a file that ledgers SIX other known gaps loudly and by name. The absence of a seventh ledger reads as non-awareness.

★★ WHY NO INSTRUMENT CAUGHT IT, AND THIS IS THE PART TO ACT ON: ci/tests/projection.nix pins the anchor projectClass id C == classSubtreeAt id C ++ <route remap delta>. classSubtreeAt reads class-seeds — RELOCATION APPLIED. projectClass does not. ★ WITH ZERO REROUTES ANYWHERE IN THE CORPUS OR FIXTURES, BOTH SIDES AGREE TRIVIALLY. comm -12 over 'grep -rl reroute ci/' and 'grep -rl reachEdge ci/' is EMPTY — no test file contains both, and no fixture declares a reroute at all. The anchor that exists precisely to pin this equivalence is GREEN ON AN INPUT CLASS THAT CANNOT DISTINGUISH ITS TWO SIDES.
⇒ THE FIX HAS A PREREQUISITE: a fixture that declares a reroute AND builds a reach. Without it, any repair to projectClass is unfalsifiable and the anchor will stay green through both the defect and the fix. Same vacuity family as den-hoag-gg8 (a green sibling over an empty list) and den-hoag-6jo — but on the projection ANCHOR, which is worse, because an anchor is what a reader trusts INSTEAD of reading.
⇒ AND THE E10(b) CONSEQUENCE FOR ANY REPAIR: the projecting-scope reading is EXPRESSIBLE (id is bound in projectClass, exactly as routeRemapFor already uses it) and the owning-scope reading is NOT — reach elements are { key; content; sharedFoldKey } with no scope coordinate, and at both construction sites the scope id is in lexical scope and DISCARDED. A repair therefore either takes the projecting-scope reading, or first adds a coordinate to the reach element. See den-hoag-4kh.16.

### 4 — 2026-07-30T19:34:19 · Jason Bowman

ACCEPTANCE ARMED at e987cee (den-hoag-akj closed): projection.nix now carries two red rows on a reroute-through-reach fixture — the relational equivalence AND the absolute relocated content — which green exactly when projectClass honours the relocation relation. The repair is now falsifiable; before this, the anchor stayed green through defect and fix alike. TWO FACTS FOR THE REPAIR: (1) the compat/v1 surface CANNOT author a reroute (translateEffect emits edge/drop/suppress/member/delivery only, measured with an inject control) — the repair is native-surface-only witnessable; (2) the fixture exercises reroute ONLY — declare.inject, this bead's other half, needs its own input added when the repair lands (recorded limit on akj's close).

### 5 — 2026-07-31T14:07:47 · Jason Bowman

★★★ OWNER RULING OBTAINED, 2026-07-31 (session 3): §15.1 RATIFIED — declare.reroute/declare.inject REACH THE BUILT SYSTEM (the owning-scope reading the spec installs). Owner accepted the measured membership consequences explicitly: SHRINK — a member whose only class content is relocated away disappears from systems.<class> (HM configuration vanishes from flake outputs, content merged into containment ancestor's nixos configuration); unconditional in route/forward terms, quantified over owning scopes in the element term. GROWTH — gated on class registration (memberClassName conjunct), not content. Presented with alternatives (ratify+loud-shrink; introspection-only status quo); owner chose plain ratification. §15.1's 'OUTSTANDING' is discharged — r13 must record the ruling as OBTAINED in §15.1 and §9.1.

### 6 — 2026-07-31T18:46:24 · Jason Bowman

V1-SPEC TESTIMONY READ (2026-07-31, read-only parallel session, on owner instruction): ~/Documents/repos/sini/den-specs/design/routes-and-forwards.md (fx-pipeline component reference, 753/753 test state, dated 2026-05-07) read against the SS15.1 ruled construction. Consulted as TESTIMONY of v1 intent, never design authority — owner ruling this session: do NOT pollute the graph-based design with the effects architecture; purity and simplicity are the primary objectives.

THREE FINDINGS:

1. V1 CORROBORATES THE RULED ARM. v1 admits no introspection/terminal divergence BY CONSTRUCTION: every relocation family (simple routes AND complex forwards) converges into ONE application site (route/apply.nix applyRoutes, post-pipeline Phase 3) feeding instantiation (Phase 4 applyInstantiates). There is no second consumer to disagree with. The rejected introspection-only arm would have contradicted v1's own design. The body's asymmetry sharpening ("any remedy must say why the two families differ or make them agree") has v1's answer: they agree, always, by construction. Further: the ruled OWNING-SCOPE reading is the by-construction form of v1's "child suppresses root" dedup REPAIR (route/apply.nix dedupRoutes, two passes — child-scope adapterKey suppresses root-scope route; first-occurrence-wins per adapterKey@sourceScopeId). Same semantic outcome, no repair pass to maintain. Ruling and by-construction-over-repair doctrine agree.

2. OPEN VERIFICATION, NAMED — TERM-2/3 RELOCATION COVERAGE. v1 invariant "provides before routes" (routes-and-forwards.md SS8): relocations observe the COMPLETE content contribution set, guaranteed by phase ordering. den-hoag's projectClassScoped is a three-term sum (reach fold ++ routeRemapFor ++ forwardModulesFor) and SS15.1 quantifies term 1 precisely. NEEDS A NAMED YES: does an outgoing relocation at class C also govern content arriving INTO C via routeRemapFor/forwardModulesFor, or only the reach-fold term? If route/forward-delivered content lands in a relocated-away class, that is PARTIAL relocation — a new member of the same silent-divergence family this bead measures. Unification spec SS4.5a may already discharge this; confirm and record the discharge, or file the defect.

3. WEIGHT BEHIND THE MISSING INJECT RED. v1 shipped its forward path unguarded — compile-forward "resumes []; forwards bypass dedup and constraint checking" (routes-and-forwards.md SS2). The unguarded sibling path is exactly where this defect class hides. This bead already records: only reroute is armed, THE INJECT HALF HAS NO ARMED RED. v1 precedent raises arming it from hygiene to priority.

PURITY FILTER VERDICT (4kh SS4 criteria): nothing mechanical in the doc is importable — state.scopedRoutes accumulator (criterion 1), __complexForward/__forward carriers (criterion 2), tier-1/tier-2 value-shape classification (criterion 3), fx.send effect handlers (criterion 5), dedup-as-repair. Extractable content = the three invariants above; two already embodied by the ruled construction, one (finding 2) still to confirm. forwardTo class-default routing (SS6) is v1 surface sugar — long-tail bucket, no simple-form obligation.


### 7 — 2026-07-31T23:29:02 · Jason Bowman

★★ GATE ROUND 21 — unification spec, first gate over the r23 set. VERDICT: REVISE — construction not clean. Artifacts stable across four samples (8c7eb755/40ed6df3/36029b5f at papers 128772d); rev-pin dispatch control armed (classSliceOf lib/attributes/ 19 at 2e44ff5 vs 20 at HEAD). No-auto-settle correction echoed; gate runs until dry.

CONSTRUCTION:
· F1 [C6]: §8 STILL SPECIFIES THE READS IC-1 DELETED. Block 22's fence writes 'builtins.seq (assertKeysRegistered (exempt // n.assertedClasses) n)' and 'scope = n.scope', but §8's or-reconciliation row says DELETED→scopeOf n, and both §8 C6 rows credit named aborts to scopeOf/assertedOf — while §14.5's r22 guard requires scopeOf/assertedOf ZERO outside lib/attributes/class-modules.nix. One expression specified two incompatible ways; one fails the design's own guard. AND the C6 answer moved unrestated: bare selections (no or) give Nix's UNNAMED attribute-missing error, and builtins.seq forces n.assertedClasses BEFORE classSliceAt entry, so the surviving named throw on the extraction path never fires first. Statement-level siblings same class: §5.4's impossible-by-construction row, §10 entry 4's stale 'exempt // assertedOf n' citation (count of two survives, expression does not).
· F2: THE CLAIMED CLASS SWEEP IS NOT IN THE DOCUMENT. Fence-invariant preamble cites 'the class sweep and §14.5's interface guard' as why IC-1/IC-2's class is discharged; grep 'class sweep' = exactly that one sentence. §14.5's guard is tree-side lexical — structurally cannot see that §8/§5.4/§10 of the DOCUMENT still name the accessors. F1 is the demonstration the class has live members. Instrument = the missing document-side sweep: every §8-named replacement expression must appear verbatim in ≥1 construction fence (non-vacuous: scopeOf n / assertedOf n → 0 fence hits; controls n.scope → 1, scopeOf e → 1).

INSTRUMENT:
· F3: REGISTER SCRIPT HAS NEVER PASSED — 103 pass, 10 drift, EXIT 1, all three liveness canaries fired. Cause established not inferred: corpus dir lucasshiva born 2026-07-28 11:34 (clone from lucasshiva/nixconfig.git), a month newer than all others and THREE DAYS BEFORE the script's first commit; every drifted delta equals lucasshiva's own contribution measured alone; the two controls it contributes zero to did not drift. git cat-file at all five commits (c2d6335→128772d) shows stated cells byte-identical ⇒ rounds 19-23 either did not run the script or left EXIT 1 unaddressed. ALL P=0 absence rows re-ran CLEAN over the 20-dir corpus — no absence claim damaged; only population counts and positive controls moved. Remedy: carry r22's own reasoning across — pin the corpus domain (script-checked manifest of member names + drift notice) so a new clone reports as ONE NAMED ADDITION; then re-take the ten cells.
· F7 minor: script banner says 26 fence pins byte-identical + omits block 22's r23 second move; its own comment and the core's ledger say 25.

STATEMENT-LEVEL: F4 [law 42] ledger's closed 'the corpus's 25 computed den. attrpaths are all…' gained an unread member (lucasshiva astra.nix:9, den.aspects.${username}.provides.${hostname} — read: an aspect DECLARATION not constructor position; dispositive claim survives; total 26, split 14/11). F5 [C1-a] IC-2's order derivation states domain 7× wider than needed ('the two sibling bindings that take a scope id' — 14 such bindings, SIX put id first; the set the argument needs is takes-exempt-AND-id = exactly 2, remapOver + routeRemapFor, claim holds 2/2, both verified verbatim at e90b0b7, adjacent call sites same exempt/id/class ⇒ conclusion STANDS, stated domain wrong). F6: ledger row 9's correction-in-waiting stale (should-read-996 now 997 literal/999 widened; §15.1 frozen at abe461d3 still says 994).

★ TERM-2/3 RELOCATION COVERAGE (v1-testimony finding 2): DISCHARGED, NAMED YES — at §4.5b (destination coordinate), not §4.5a. All three terms of projectClassScoped read ONE memo: §4.5b replaces the three literal destination compares (routeRemapFor route.to == class ×2, forwardModulesFor f.intoClass != class) with elem route.to (sourceOrderOf result id class) — outgoing Ρ at C makes sourceOrderOf id C = [], nothing lands at C; at rest position E the same read gives [E,…,C]. §15.1 quantifies: shrink unconditional in terms 2+3, quantified in term 1. Reproduces v1's single-application-site property. The partial-relocation hazard is named and rejected BY NAME (rejected reading (ii)); armed at §14.7 five rows incl. test-member-vanishes-under-outgoing-relocation-despite-route (RED at HEAD, still red under rejected reading); §14.5 requires all three literal compares reach zero. Caveat: nix-eval cells not re-executed by the gate — discharge is STATED, QUANTIFIED, ARMED.

CHECKED CLEAN: IC-1 producer-totality verifies exactly (forwardExpand.emit unconditional scope/assertedClasses; elementAt both refusing branches throw); r23's two declined sites genuinely carry their at-HEAD qualifiers; C9 well discharged (§10 reads all five register entries, discloses __forward/__dropped three-ways, corrects the register's stale __action list — two live kernel readers of __forward confirmed vs firing compat control); S0 satisfied. RETRACTIONS: fourth-export finding withdrawn (classSliceOf becomes un-exported rawSliceOf, classSliceAt same slot renamed); §10 touched-count finding rejected (entry 2 withdrawn ⇒ 3 touched of 4 live is correct).

DEN-HOAG TREE DEFECT found (outside gate scope, filed separately): output-modules.nix formals-block comment says classSliceOf returns [ { module; shared; } ]; actual return is [ { module; sharedFoldKey; } ] — the SPEC is right, the tree comment is stale.

COVERAGE (limits): register script 489L + §1/§4.3/§4.5-fence/§8/§10/§14.5-guard/§14.7/§15.1-quantifier read in full + complete 34a68f4..128772d diff; ledger rows 6-15 + two bullets only (848L total); ALL nix-eval cells unverified (no flake built); §11 academic provenance only at opening claim.

### 8 — 2026-08-01T00:00:46 · Jason Bowman

★★★ ROUND 24 AUTHORED AND INTEGRATED. wt/unification-r24 c1ad06b, cherry-picked to papers main f1c4f3d md5-preserved (core 5c746acc/4604, ledger d7aec1cb/1013, script 2a52a5ed/612). All seven gate-21 findings discharged at class. REGISTER: 129 pass / 0 drift / 0 skip EXIT 0 — FIRST GREEN SINCE THE SCRIPT WAS WRITTEN, re-run post-commit against committed bytes. NO fence moved (concatenated b022f892 + all 28 pins + §15.1 abe461d3/207 carried, script-verified).

★ F1 C6 DISPOSITION — MEASURED, AND THE MEASUREMENT CONTRADICTED THE DISPATCH ON ONE HALF: three outcomes not two. (1) scope: NAMED abort SURVIVES — classSliceAt's first act sourceOrderOf eval (scopeOf e) c forces the scope id BEFORE the fence's lazy n.scope read is demanded (dispatch's 'unnamed for scope' FALSE; author's first harness reproduced the false expectation via a sid-ignoring stub — recorded as instrument finding). (2) assertedClasses: named abort LOST, unnamed attribute-missing — dispatch correct. (3) empty/all-underscore content: NO diagnostic, element answers [] either way — unnamed error covers exactly the observable cells. Positive control: direct classSliceAt call throws the named text on the identical element. DISPOSITION: ACCEPT the unnamed abort on §4.3's measured producer-totality; both candidate repairs are already-ruled-against shapes (named guard at fence = cross-file assertedOf = IC-1 exactly, forbidden by §14.5's own row; field-projection export ruled not-a-surface by §4.3). Written into §8 WITH the measurement. Class sweep: 41 scopeOf/assertedOf lines read against current fences, FIVE stale fixed (§8 or-reconciliation, §8 C6 ×2, §5.4, §4.3 present-tense), route/forward row KEPT with contrast added (those folds' named aborts are correct — nothing in front), §10 entry 4 re-quoted, §4.4e both spellings.

F2: gate's premise partly wrong — the class sweep EXISTS (ledger, uppercase; gate grepped lowercase). Remedy stands on the stronger ground: NEITHER cited instrument can see F1's defect class (sweep is one-off visibility-predicate; §14.5 tree-side). Mechanized register row added: deleted forms 0/0, controls scopeOf e / assertedOf e 1/1, all six replacement expressions present-in-fence 1 each (fences extracted via awk, 262 lines).

F3: lucasshiva cause established (reflog clone 2026-07-28, upstream tip 07-25; --exclude-dir reproduces all ten r23 cells; zero contribution to the two non-drifted controls). Corpus domain pinned to 20-name script-checked manifest; membership change = ONE named row. ★ REPAIR VERIFIED BY FAILURE-MODE CONTROL: synthetic 21st member + manifest at 20 → exactly 1 drifted row naming it, 128 passes. Ten cells re-taken + FOUR unregistered citing sentences re-derived (config 160→167, unswept 22→24, computed-attrpath 24→25, widened den.aspects 996→999 quoted twice). F4: 26 total / 14-11 split / one nested; closed 'are all' converted to covered-list+named-additions; constructor-attrpath dispositive claim unmoved at 0. F5: domain corrected to takes-BOTH-exempt-AND-id = {remapOver, routeRemapFor} 2/2; 14/6 wider figure reproduces under the refuted reading and is recorded as such; ★ both figures derived by PARSING THE LEADING FORMAL RUN (file has two binding forms; author's first line-shape grep read 8 not 14 — same failure family as the finding). Two instruments added: §14.5 formals guard row (non-vacuity itself pinned) + register domain row. Class sweep: 4 derived-not-stated claims — one fixed (this), one had unstated COMPARAND (§4.5b cycle-abort-domain vs §4.7 row 6 — both baselines now written, they agree), two adequate. F6: row 9 → 997/999, §15.1 NOT thawed (stale control sits in a could-not-have-matched argument; not load-bearing). F7: banner 26→25 + r23 move named; full self-count sweep, banner was the only divergence. LAW-41 BIT: first F3 draft's verbatim reflog timestamp tripped #43's line-anchor row 0→1 — caught by full-script re-run, recorded.

OUT-OF-CLASS (reported, unfixed): (1) ★ REPO-WIDE corpus-figure exposure — 2026-07-28-produces-declaration-trust-design.md states '18 of the 19 den-configs'; corpus is 20; every paper quoting a den-configs figure has the same exposure and no manifest (filed separately). (2) liveness canary cannot detect a HOLLOW corpus (author hit it live: failed cross-device cp -rl left empty dirs; canary said LIVE, 42 rows drifted to zero — the exact mass-drift shape canaries were added to prevent; per-member threshold would close it). (3) 'config' control sat in a stated same-run group but only the other three were registered — free to go stale silently. Items 2-3 are next-round register work.

### 9 — 2026-08-01T00:19:41 · Jason Bowman

★★ GATE ROUND 22 — VERDICT: REVISE. Artifacts stable (5c746acc/d7aec1cb/2a52a5ed at f1c4f3d); den-hoag lib/+ci/ byte-identical e90b0b7..HEAD so probes read the pin. REGISTER REPRODUCED 129/0/0 EXIT 0, exit contract verified by injected-drift control (gate's first exit reading was through a pipe and wrong — re-measured directly; $pipestatus class).

CONSTRUCTION:
· F-A [C6 + the C6 verdict-mapping ruling + C7]: §8's assertedClasses ACCEPT rests on a FALSE DICHOTOMY — the stated candidate repairs (cross-file assertedOf = IC-1 forbidden; field-projection export = ruled not-a-surface) are NOT exhaustive. REPAIR R EXISTS AND IS MEASURED: move the union INSIDE assertKeysRegistered (exempt: aspect: let exempt' = exempt // assertedOf aspect; …) and the fence calls assertKeysRegistered exempt n — HEAD's OWN call form at output-modules.nix:765. Confined to class-modules.nix, assertedOf in the same let, export set stays four, §14.5 rows unaffected. Measured (gate22-c6.nix): R-noAsserted → NAMED 'content element carries no assertedClasses'; controls R-control-total=1, R-aspect-parity=true, R-empty=[]. Marginal instrument cost ZERO (hand-built elements must stamp the field regardless; only extra reach is projection.nix's direct calls through the shared harness mkNode §8 already obliges). C7 ANGLE SEPARATELY: the r24 fence's exempt // n.assertedClasses is a SECOND DERIVATION of the union classSliceAt computes internally — the same shape §8's own or-reconciliation deleted scope = n.scope or id for; HEAD's fence has NO union; the r24 design mints both the duplicate union and the unnamed diagnostic in one new expression. Producer totality is TRUE (verified in-tree) but is the WRONG GROUND at C6 — the row's violating input is a hand-built element, exactly the domain producer totality excludes.
· F-B [C6]: 'the unnamed error covers exactly the observable cells' is FALSE — OVER-covers, and the over-covered cell is the MAJORITY cell. Witnesses: content { name; home-manager } queried at nixos → UNNAMED abort while field-present answers []; { name } alone → same. Mechanism: assertKeysRegistered filters on ANY non-_ non-exempt key regardless of queried class, and class-seeds demands genAttrs classNames so every element is queried once per registered class, answering [] on all but its own — the unobservable cell is the COMMON case. True relation: strict superset. (Repair R moots the sentence — the named throw makes the coverage question vanish.)

INSTRUMENT/STATEMENT: F-C minor — F2 register row's stated predicate wider than its rows on two axes: §8 row 3's post-change form (.actions.resolution or [] → SPLIT) has no F2 row (no live defect — §4.2's fence implements it verbatim, verified — but the instrument would not catch a regression); fg reads all 28 fences incl. 17 EXECUTED transcripts while the comment says 'construction fence' (no live mismatch, all ten patterns land in construction fences). F-D minor — §8's mkNode obligation names ONE of TWO definitions: _lib/projection-harness.nix (exported, consumed by projection.nix) AND projection-routes.nix, both key: content: { inherit key content; }, neither stamping either field.

ROUND-24 CALLS THAT STAND (independent harness, negative control reproducing the prior inversion — do not re-litigate): F1 (i) scope named-abort forcing order holds against REAL gen-scope get (dynamic-attribute test forces id; addErrorContext interpolates the same throwing id); (ii) both halves; no consumer path reaches n.scope without classSliceAt first (map/concatMap/sourceOrderOf/memo/eval.get chain). F2 row non-vacuous, cells match. F5 domain CONFIRMED EXACTLY by parsing all 47 top-level bindings (2/2 narrow; 14/6 wider reproduces and would refute; control: only two binder-position exempt: runs in the file). Corpus manifest drift arm fires correctly (synthetic 21st → exactly one named row, 128/1, exit 1; removed, corpus verified back at 20). §15.1 freeze defensible. All six §10 citations status-correct at HEAD. Entries 1/3/5 dispositions hold.

UNITS 4a/4b: ★ 4a PARKED — F-A and F-B touch block 22 and §4.3's binding exactly; landing 4a as written commits the unnamed diagnostic where a named one costs zero. 4b carries NO construction finding of its own (no §14 arm defective; F-D widens its consumed instrument obligation) — blocked by SEQUENCE on 4a only.

Gate coverage limits: harness is per-element reconstruction of §4.5's fold (route/forward arms dropped, two-name classNames, no real fleet — those arms rest on reading except B-direct-noAsserted, run); keyCategory from quirk-blind internal.aspectSchema (adequate for C6 rows, says nothing about channel-category cells); eval stub mirrors production get in the two respects that matter, is not gen-scope; nix-eval register rows and corpus P=0 sweeps not re-taken; §§6/7/11/12/16 read for conflicts only. One reverted state change: synthetic corpus dir for the drift-arm test, removed same run.

### 10 — 2026-08-01T00:52:19 · Jason Bowman

★★★ ROUND 25 AUTHORED AND INTEGRATED. wt/unification-r24 3fd0303, cherry-picked to papers main 9fd7993 md5-preserved (core f9ef158e/4701, ledger bd72571d/1168 pure-append, script d682476f/694). REGISTER 139/0/0 EXIT 0 read from $? unpiped. All four gate-22 findings discharged at class.

F-A: REPAIR R ADOPTED — union inside assertKeysRegistered; §4.5's fence = assertKeysRegistered exempt n, HEAD's own call form (fence unchanged from tree at that position). Gate's measurement NOT taken on trust: e90b0b7 binding extracted verbatim, two-line delta applied mechanically (diffed to exactly two lines), result NAMED abort; controls: field-present admits, empty/all-underscore admit field-absent, exempt short-circuit intact, self-asserting element widens. Export set four; §14.5 rows unaffected. Producer totality kept in the corrected supporting role. CLASS SWEEP: nine §8 ACCEPTs — exactly ONE grounded on a repair enumeration (the fixed row); other eight ground on positive properties no unenumerated construction refutes; two have in-file constructions available and are sound because neither row claimed exhaustiveness; rule installed: an enumeration's domain is CONSTRUCTIONS, never constructions-at-one-call-site.
F-B: measured with rawSliceOf verbatim — restated as containment. ★ SWEEP WENT DOC-WIDE and found TWO MORE in §4.7 (rows 7, 12b) beyond the dispatched §8/§15 — five total, one error class (emptiness over every-reached-node written as equivalence when only ⇐ holds), all now 'whenever', three carry counterexamples; remaining six bare iffs individually verified genuine.
F-C: SPLIT row added citing §4.2's throw-expression; relabelling REFUSED with reason — the two halves want opposite domain corrections, so the extractor is SPLIT (absence over all 28 fences = wider = stronger; presence over 10 construction blocks = narrower = stronger); ★ DISCRIMINATION CONTROL added unprompted (liveness proves non-empty, not narrower — a degenerated extractor passes both): excluded-class strings 14 wide/0 narrow, 7/0. All F2 cells re-derived; two replacement rows added (call form + internal union — either alone satisfiable by a half-applied edit).
F-D: both mkNode definitions named; ★ repair R widens the obligation on a second axis (field now forced at assertKeysRegistered's own sites: harness projectReachTotal + two projection.nix calls).

FENCE LEDGER: block 22 89ef6d6d→530a112a; block 4 gains assertKeysRegistered 4a8839af→0c92aa70; concatenated b022f892→36fa68fd; 56 lines/28 blocks/17-10-1 unchanged; ★ adding to block 4 rather than a new fence DELIBERATE (new fence renumbers 24 index-keyed pins and re-points ledger history); cumulative 4 blocks/6 moves, 24 of 28 byte-identical to r19. §15.1 THAWED by named finding (F-B quantifier, not figure refresh — r22's refusal-to-thaw ruling untouched): 207/abe461d3 → 214/3921ee54, row-9's waiting correction DISCHARGED (994→997, checked as a pair so half-applied fails).

OUT-OF-CLASS (recorded in ledger): (1) anchor rule fired on the round's OWN edits second round running (13 colon-digit strings in F-D's first draft; caught by register re-run not review — re-run after EVERY edit); (2) the $pipestatus class in a new costume: zsh for-loop over unquoted $M does not word-split — manifest became one nonexistent dir, den.aspects answered 0, the dead-instrument shape reproduced BY HAND outside the canaries; bash read -r -a: 997, control 1747; (3) new §14.5 guard row: assertedClasses reaches zero in output-modules.nix, non-vacuity comparand honestly stated as r24's own fence NOT HEAD (the scopeOf/assertedOf row cannot see a bare field read — the precise F-A fail-open); (4) §13 row for assertKeysRegistered's body (in-tree binding this design edits, never before enumerated).

### 11 — 2026-08-01T01:12:20 · Jason Bowman

★★ GATE ROUND 23 — VERDICT: REVISE (two construction-contact, four statement; nothing redesign). Artifacts stable (f9ef158e/bd72571d/d682476f; papers HEAD moved mid-round, these three byte-identical). REGISTER REPRODUCED 139/0/0 EXIT 0 from $? unpiped.

CONSTRUCTION CONTACT (both §4.5):
· F-R1 [C6/C7-a]: §4.5's structuralNodesRaw ++ (self.get nid "class-relocation").injections BREAKS TWO INSTRUMENTS THE ARTIFACT SET NEVER NAMES — ci/tests/reach-graph.nix (15 test- rows, stub throws 'unexpected attr class-relocation' — MEASURED: pre-change control succeeds, §4.5's one-line change aborts on the stub's own throw) and ci/tests/order-instances.nix (reachStub, 4 bindings). Neither name appears in core or ledger (0/0 each; controls same predicate: projection-harness 16, class-relocation 85). ROOT CLASS: §2(b)/§5.3/§7-item-6 quantify over the cm-BUILDING set; the set §4.5 breaks is instruments driving the reach EQUATION against a stub self — never censused (12 files grep resolved-aspects.nix at the pin). §4.5a's own lesson one level out: a census over consumers of the reach VALUE is blind to drivers of the reach EQUATION.
· F-R2 [C6]: the .injections read has NO totality row and NO named abort — on an eval not serving the memo it answers the evaluator's unnamed attribute-missing or a stub's own message, while §8 gives the extraction's eval read AND §4.5b's destination read the named 'no class-relocation memo at scope' abort. §5.1/§5.3's whole argument (named abort converts omission into commission) applies identically and the document does not make it; §4.3a #2 refuses adding a sixth member of the class being repaired; §15.5's no-defect-behind-it ground does not transfer (this read is NEW). ACCEPT-WITH-CONDITIONS shape: named local edit (let-bound accessor in resolved-aspects.nix + one §8 row).

STATEMENT: F-R3 — THE F1 CLASS RECURRING EXACTLY WHERE PREDICTED: §5.4's impossibility register still asserts the r24 asymmetry ('unnamed on the projection fold') that repair R REMOVED — measured under R: projection fold's r25 call form answers the NAMED throw; §8's route/forward row says the opposite of §5.4; neither existing instrument sees it (F2 rows read fences; visibility sweep asks a different question). F-R4 — SIXTH instance of F-B's class in §5.4: 'coincide only on Ρ=∅' — measured false (Ρ={A→B}, element with content only at rest channel B: classSliceAt 1 = rawSliceOf 1; control same Ρ with A content: 2 vs 1). Correct: differ iff non-identity source order AND element carries content at a channel in the difference. F-R5 — §4.7 row 5 names a beneficiary that cannot benefit (content-key-totality folds over resolved-aspects only; forwardExpand.emit writes assertedClasses = {} unconditionally ⇒ exempt // assertedOf a ≡ exempt; true for harness, vacuous for driver). F-R6 minor — §4.4d's forward-limit iff fails ⇒ (measured: meta present, no __forward ⇒ {} ); ⇐ is what's used. Noted: §9.3's fires-iff ambiguous WHNF-vs-field (its own table resolves); §15.1's vanishes-iff true only on the already-in-systems.C population.

SURVIVED REFUTATION (do not re-litigate): repair R reproduces from §4.3's TEXT over the real binding — 12 cells incl. exempt short-circuit preserved, asserted-channel union live and discriminating; ★ CALL-SITE ENUMERATION COMPLETE for assertKeysRegistered (2 production + harness + 2 direct + routes threading; every caller either carries assertedClasses={} ⇒ no semantic change, or is a mkNode product under §5.3's obligation); artifactExclusive-before-filter sub-domain measured both-named (unstated in §8's row — minor); fence claim verified (r25 fence byte-identical to HEAD at that position); document agreement clean EXCEPT F-R3; fence moves verified with an independent extractor (exactly two blocks, 26 pins not re-derived and passing = proof); §15.1 thaw EXACTLY its named finding (three hunks); §14.5 assertedClasses row honest AND checkable (fires 1@r24/0@r25 document-side; tree-side vacuity marked, law 44 satisfied); all cited trackers verify at HEAD; entry-5 rb0 witness does not bind (design touches scope, not __entry).

★ UNITS: 4a PARKED AS A WHOLE — but §4.3 ALONE IS CLEAN: no finding touches §4.3's expressions, repair R verified, call-set complete. GATE RULING: if 4a is split so the §4.3 extraction lands ahead of the §4.5 consumer change, that half MAY DISPATCH against f9ef158e at e90b0b7. 4b not parked by any construction finding but §14 has no reach-stub arm — inherits F-R1's gap.

Gate coverage limits: core+script read in full; LEDGER NOT READ (rows rest on script re-execution); evals against git-archive e90b0b7 lib with real deps (artifactExclusive stubbed _:true in the source-order probe only); NO native mkDen fleet built (all fleet-level cells outside warrant); F-R1 measured on a transcription of the stub shape driving the real reach.compute, nix-unit NOT run.

### 12 — 2026-08-01T01:56:13 · Jason Bowman

*** IMPLEMENTATION CONTACT — §4.3 EXTRACTION LANDED, AND THE ARMED ACCEPTANCE WENT GREEN. Commit d0e9d4b on den-hoag main (fourth unpushed commit, atop the three dcx step-1 commits), from the pinned spec blob f9ef158e at papers 9fd7993 — the revision gate r23 cleared for split dispatch.

THE HEADLINE: red set 22 -> 20. Newly red: NONE. Newly green: projection.test-anchor-projectClass-eq-classSubtreeAt-under-relocation AND projection.test-anchor-projectClass-relocated-content — the two armed reds this bead's ACCEPTANCE ARMED record (e987cee, den-hoag-akj) installed. projectClass now applies the relocation; the two-consumer agreement assertion holds. The core defect (declare.reroute not reaching the built system) is DISCHARGED AT THE PROJECTION LAYER for the reroute half. Remaining per this bead's own limits: the terminal link is one alias hop (witnessed at projection, not drv); THE INJECT HALF STILL HAS NO ARMED RED (v1-testimony finding 3 raised arming it to priority); §4.5's consumer changes (destination compares, forwardModulesFor arity) are PARKED on gate findings F-R1/F-R2.

WHAT LANDED (all verified by the implementer with controls): classSliceOf -> un-exported rawSliceOf (body byte-identical, diffed); private scopeOf/assertedOf with named throws; exported sourceOrderOf (memo, named abort on memo-less eval, or-on-final-selector only, strict bad filter); exported classSliceAt threading exempt // assertedOf e through sourceOrderOf; repair R in assertKeysRegistered (two-line delta, rest byte-unchanged); export set FOUR; three production call sites re-formed (remapOver, forwardModulesFor srcSlices, projectClassScoped) passing the result handle they already close over; mkClassSlice/default.nix threading; doc anchors swept (repo-wide residual classSliceOf zero outside .beads + historical parity ledger). Both mkNode definitions stamped; third mkNode (reach-graph.nix) deliberately unstamped with a measured never-reaches-extraction control. Both projection instruments now drive cm.class-relocation.compute — the kernel's own equation, not a hand-written memo. All five new named throws exhibited firing with admitting controls (statement about callers, not dead predicates). Baselines: before 2083/2105 22 red (sorted-red md5 f94ada4b), after 2085/2105 20 red, parity 71/71 both, format gate 0, exits from $? unpiped.

IC FINDINGS (rulings inline):
- IC-3: base state was three commits not two (my base-update message crossed mid-flight; implementer baselined correctly). No action.
- IC-4 (DISPATCH ERROR, mine): my red-set instruction named §14.7's five arm rows as "staying red" — NONE EXIST IN THE TREE (zero hits, positive control on a present arm name). The actual baseline reds were projection.nix's pre-existing armed acceptance, which §4.3's landing is DESIGNED to green. Implementer's reasoning ratified. LESSON: I quoted spec-side arm names as tree-side test names without a tree check — the exact stated-value-drift class, in a dispatch.
- IC-5: repair R's union is forced at assertKeysRegistered's OWN call sites including the content-key-totality driver -> 13 fixture rows in class-relocation.nix + class-bucket-query.nix needed the two fields (my dispatch enumerated only the two mkNodes; §13 carried both rows). Landed, all 13 recovered. RATIFIED — §13 was right, the dispatch under-enumerated.
- IC-6: boundary.nix's token guard ranges over core-file PROSE — a kernel comment saying "compat's bucket registry" reddened test-no-compat-tokens-in-core (offender message names a file, not a line). Reworded. Recorded as a standing authoring hazard for kernel comments.
- IC-7 (SPEC-FACING, relayed to the r26 author): scopeOf's named throw is LAZY IN THE SCOPE ID — classSliceAt passes scopeOf e as sid, reached only via eval.get sid; an id-IGNORING eval never forces it, so a scope-less element passes undetected. Measured discriminating pair: id-forcing eval (the real result.get shape) THREW; id-ignoring stub admitted. Production safe; exposure is instrument evals. NOT repaired (strictness change outside the cleared surface). §8's scope row owes the sub-domain qualifier.
- IC-8 (ENVIRONMENT): .pre-commit-config.yaml is a dangling symlink to a GC'd store path — the hook cannot load; SKIP has nothing to skip; commit needed PRE_COMMIT_ALLOW_NO_CONFIG=1 SKIP=ci,treefmt. Format gate run explicitly instead (exit 0). Filed separately.

OWED, RECORDED NOT SILENTLY SATISFIED (the implementer's honest ledger): sourceOrderOf NOT added as output-modules' required fourth formal — the required-not-defaulted ruling is justified entirely by §4.5b's parked reads; a required formal with zero readers breaks every caller for no discharge; THE OBLIGATION LANDS WITH §4.5b. §13's class-seeds rewiring NOT landed (two computations of one answer, agree by construction via the same srcOrder on the same frameAt; rewiring moves demand order = red-set hazard outside the cleared surface). §5.3's real-classNames obligation owed (instruments pass [ ] — measured inert here: empty domain => identity order, correct for these fixtures). §14.7's five arms unwritten; §14.2(h) unarmed; the bad filter's refusal exercised only by direct probe (P=0 in suite).

### 13 — 2026-08-01T02:06:03 · Jason Bowman

*** ROUND 26 AUTHORED (integration held for one bounded addendum — IC-7 relay verified NOT landed, zero grep hits in both artifacts; author revived; law 3 in action: a mid-round addition has no slot in a brief-shaped report). wt/unification-r24 13b99b7. Core f9ef158e/4701 -> 8f4ede59/5035; ledger bd72571d/1168 -> bb39ef66/1361; register d682476f/694 -> 11753f2d/848. REGISTER 174/0/0 EXIT 0 (35 rows added, 4 re-pinned). All six gate-23 findings discharged at class.

F-R1: BIGGER THAN THE GATE MEASURED — 4 suites / 27 rows, not 2 (reach-graph 15, projection-host-aspects 3, order-instances 4 of 25, projection 5 of 16 — its other 2 reds are the §14 acceptance rows, correctly excluded). Measured on a git-archive e90b0b7 snapshot through the LOCKED ./ci#nix-unit over the ENTIRE suite: base 2071/2093 -> payload-only 2044/2093 -> with-§13-stub-repair 2071/2093, sorted failing-name lists identical to base IN BOTH DIRECTIONS (comm empty each way). The harness is a THIRD equation driver the gate did not name — already covered by §13's prescribed self-referential stub. Census class discharged: EVERY census stated domain 'constructs a kernel piece directly' while applying test 'builds a cm' — §4.4c's failure shape on the instrument accounting itself; name-keyed censuses still miss order-instances (raReach.compute — reach\.compute grep returns its comment, not the 3 call sites); __action = "inject" 0/0/0 in the three stub fixtures with 1/1 controls.

F-R2: TWO bare .injections reads, not one (reach.compute AND class-seeds) — r25 wrote both bare; a repair at the exhibited one would have been a half-fix. Gate's violating-input cell CORRECTED on measurement: a DECLARED attribute's record carries the producer literal [injections sourceOrder]; an UNdeclared one already answers named + tryEval-contained (gen-scope: unknown attribute); the uncovered population is a HAND-BUILT PARTIAL RECORD, where the bare read's attribute-missing is NOT tryEval-containable (escapes as «error» while a throw in the same run contains). Accessor private-not-exported on a MECHANICAL discriminator (sourceOrderOf reads instance data/keyCategory; injectionsOf reads none). Fence blocks 19+21 moved.

F-R3: the prose-side IC instrument IS constructible and is BUILT — inverse extractor of the fence one, liveness + discrimination controls, absence rows on retired tells, presence rows on replacements, pinned counts (not zeros) where the retired spelling has legitimate history. No manual fallback needed.

F-R4: discharged with a SECOND falsifier the gate did not name — they also DIFFER on Ρ=∅ (injection element's assertedClasses union: classSliceAt 1 vs bare rawSliceOf 0, control 1) — Ρ=∅ neither necessary nor sufficient; two-term condition, marked DERIVED. ★ First run returned 0 in every cell (synthetic class names classifyKey rejects) — discarded as a dead instrument and re-taken; law 39 practiced.

F-R5: split (vacuous for the driver via the emit literal; live for projectReachTotal). F-R6: FOUR sites not three (fourth found: hasArtifact's 'precisely when' short-circuits on artifact = null). §8 assertedClasses row gains the artifactExclusive sub-domain with 4 cells one field apart. F-B sweep WIDENED to a mechanized 11-spelling covered list (r25's domain was 'the rows a finding named' — size 3, chosen by who complained); ★ EIGHTH instance found unreported: §9.2's permutation condition — both conjuncts necessary, JOINTLY INSUFFICIENT (measured); real condition is an INVERSION between element order and source order.

FENCES: first block ADDITION in the freeze's history — executed transcript 13764b0f at §13 index 27, chosen so blocks 1-26 keep BOTH index and pin and old 27/28 move to 28/29 md5-intact; lines 56->58, blocks 29, classification 18/10/1, concatenated 36fa68fd -> 2affb512. §15.1 thawed under F-R6: 214->221, 3921ee54 -> 9a2dc156.

OUT-OF-CLASS: ★★ the author observed den-hoag mid-flight during the §4.3 implementer's work (staged class-modules/output-modules edits at 5d6923c) — its pinned-snapshot discipline held; ORCHESTRATOR NOTE: that state has since committed as d0e9d4b, tree clean; the 'staged modifications' observation is resolved, not a hazard. ★ REGISTER LAW EARNED: §1.1 #16's repo-wide cell read the SHARED WORKING TREE and drifted 2->1 because the implementer's in-flight work had already discharged §13's own comment obligation — a register cell whose domain is a tree another agent shares CANNOT be pinned; it reports that agent's progress, not the document's claim. Re-pinned at e90b0b7 with the working-tree answer as a drift note — the one row whose DOMAIN changed rather than its cell. ★ r23's review-coverage limit carried: the gate did not read the ledger — r23 is a SCRIPT-VERIFIED round for that file, not a READ one; a green register plus an unread ledger reads exactly like a reviewed ledger.

### 14 — 2026-08-01T02:17:09 · Jason Bowman

IC-7 ADDENDUM LANDED (wt/unification-r24 880b8db; core 44b58afa/5062, ledger 1a92fc64/1439, register b97dfc2a/877; REGISTER 181/0/0; construction untouched, concatenated pin 2affb512 unmoved). Author verified IC-7 independently against d0e9d4b's REAL exported classSliceAt and found a THIRD CELL: on an id-ignoring eval the downstream splits — non-empty slice reaches the fence's bare n.scope (unnamed, NOT tryEval-contained, same escape shape as the .injections finding); EMPTY slice (element queried at any class but its own) passes with NO DIAGNOSTIC AT ALL — the silent cell that makes IC-7 a sub-domain statement, not an error-wording note. Discharged at three places without construction change: §8 scope row's domain = id-forcing evals (production's shape); §5.4 loses the unquantified 'throws NAMED on every path' (★ making IC-7 the SIXTH member of a class §5.4 already keeps — an effect credited to the right mechanism outside the domain where it produces it); §5.3 gains the fifth instrument obligation (evals force their id). §4.3 landing RE-MEASURED from two archives (5d6923c 2083/2105 → d0e9d4b 2085/2105, greened exactly the two acceptance rows, comm empty; ★ cross-checked against r26's F-R1 transcript which excluded those two as red-at-pin — they are §14's acceptance, not collateral; ★ suite totals moved between baselines via the other lane's A11 arms — transcripts stated against their own baselines, not row-comparable). Ledger gained its first fenced block (the landing transcript) with the freeze-scope statement corrected (29 FROZEN = core; ledger pinned by count).

★ ORCHESTRATOR RULING on the recorded fork (theory-grounded, standing by-construction-over-repair doctrine — an obligation on every future instrument author is a repair discipline that regresses silently on the next instrument; the construction removes the class): ADOPT THE SEQ — classSliceAt = eval: exempt: e: c: let sid = scopeOf e; in builtins.seq sid (…). Cost measured NIL on production (eval.get forces the string anyway; the seq is redundant there and fires only where nothing does today), Θ(1) per (element, channel). CONSEQUENCES: §5.3's fifth obligation DELETES (the class is gone by construction); §8's scope row returns to an unqualified named-abort domain; the §5.4 sixth-class member note stays as history. Spec application = round 27 (author revived); the TREE edit (one line in class-modules.nix) rides the next unification landing rather than a standalone commit — recorded as an owed line item on the §4.5 unit. Gate 24 reviews the spec WITH the seq applied.

### 15 — 2026-08-01T02:24:53 · Jason Bowman

9b8dee0 BANKED (wt/unification-r24; core ea3df338/5076, ledger e01a2cd7/1479, register 050d5f27/900; REGISTER 186/0/0; core fences untouched, concat 2affb512 unmoved). Born of a crossed/stale message delivery, but the substance is real: ★★ checking the compliant-eval-forms request against the document's OWN §13 prescription found the prescribed instrument arms ('if attr == "class-relocation" then { injections = [ ]; }') test ATTR, never force the id — VIOLATING §5.3's fifth obligation two sections after stating it and DISARMING scopeOf's abort at exactly the three instruments §2(c) censused. Measured three arm shapes against d0e9d4b's real exported classSliceAt, one scope-less element: constant arm ADMITS; seq-id arm THREW; lookup arm THREW; scoped-element controls admit on all three. Both §13 rows now carry builtins.seq id; §5.3 states TWO compliant forms with the branch-level tell ('does every branch the extraction can take force the id' — not 'does the stub have a table'; a constant branch is exactly where the table reading fails). ★ SECOND LAW-38 MIRROR in one round recorded as a general rule: an absence predicate over a document that documents its own retirements must key on the PRESCRIPTIVE use, never the string (the absence row fired on §5.3's own sentence quoting the retired arm to explain the retirement — same shape as the bare-.injections row firing on §13's transcript). ★ 'THE OBLIGATION WAS VIOLATED BY ITS OWN AUTHOR, IN THE SAME DOCUMENT, WITHIN TWO SECTIONS' is now the lead evidence for the standing seq ruling — round 27 (in flight, consolidated work order re-sent) applies the seq to classSliceAt's fence, retires the obligation with a tombstone, keeps 9b8dee0's three-arm table as the exhibit, and re-runs the IC-7 three-cell measurement against the seq'd form (the silent third cell should invert to THROW). Relay-sequence note for the session record: my IC-7 zero-grep ran in the worktree at 13b99b7 BEFORE 880b8db existed — true then; the author's wrong-tree diagnosis of it is itself mistaken but its instinct (verify before re-editing) prevented a duplicate section both times.

### 16 — 2026-08-01T02:36:23 · Jason Bowman

*** ROUND 27 AUTHORED — THE SEQ RULING APPLIED (integration deferred with r26+addenda; gate 24 reviews the worktree). wt/unification-r24 0d34231; core ecf81273/5103, ledger ecf4f09f/1554, register e50bd88e/908; REGISTER 190/0/0. FENCE DELTA EXACTLY ONE, INDEX-PRESERVING: block 3 (§4.3 classSliceAt) 679cae31 -> 486e0b7b; concatenated 2affb512 -> 84ffc00d; count stays 29, classification 18/10/1; ★ the round's measurement rendered as a TABLE not a fenced transcript precisely to keep the pins stable (a block at §4.3 would renumber 4-29). §15.1 not thawed.

THE MEASUREMENT (re-run against the seq'd form, transcribed from the fence with d0e9d4b's real helpers): four eval shapes x scope-less element — LANDED admits on id-ignoring and on §13's plain-constant stub arm; SEQ'D THROWS THE NAMED ABORT ON ALL FOUR. ★ THE CONTROL CARRIES THE ARGUMENT: a scoped element ADMITS on all four shapes under BOTH forms — the seq DISCRIMINATES rather than aborts. Cost statement in the fence: nil on production; seq reaches WHNF of a STRING, so §4.2's forcing paths and §9.3's fire-set table are untouched.

ALL FIVE RULING ITEMS + TWO IMPLIED CONSEQUENCES THE AUTHOR TOOK AND FLAGGED AS DECISIONS: §13's two stub arms and §5.3's fourth obligation REVERT TO THE PLAIN CONSTANT (under the seq'd form the plain-constant arm throws — the fixture-side seq-id from 9b8dee0 now duplicates work the construction does one call earlier; leaving it would leave fixtures carrying a discipline whose rationale was just deleted). RATIFIED — correct reading of the ruling. §5.3's fifth obligation deleted with tombstone; §8's scope row unqualified with r26's sub-domain kept as history; §5.4 resolution line; the owed tree edit is a §13 row naming d0e9d4b as not-yet-carrying (normal order, not a defect).

INSTRUMENT NOTES: three cells re-pinned after re-reading per the trigger's own rule — incl. the retired-form prose count corrected from a GUESSED 3 to a measured 15, with the judgement that a prose absence row on the expression this document has discussed for 27 revisions is MEANINGLESS (trigger only; the load-bearing check is construction-block absence). ★★ LAW-38 MIRROR HIT A THIRD TIME (bare .injections r26; stub arm r26-addendum; retired lazy form now) — rule now stated in the ledger as three-times-earned: in a document that records its own retirements, an absence predicate must be scoped to the PRESCRIPTIVE use, never the string. IC-7 register block REWRITTEN to test the RULING with partial-revert rows (fence losing the seq / obligation returning / fixture arms re-acquiring seq-id each break a row the other two would leave green).

### 17 — 2026-08-01T02:39:59 · Jason Bowman

ROUND 27 AMENDED: 69fd432 (round 27 = 0d34231 + 69fd432; core 4c6c5afc/5103, ledger a48d8ed4/1595, register 4f73d5f6/922; REGISTER 194/0/0; no fence moved by the amendment). The consolidated order's consequence-layering clause caught a STALE EXHIBIT: §13's kept exhibit opened 'the builtins.seq id is LOAD-BEARING' in PRESENT TENSE while the same row, post-ruling, prescribed an arm without it — one cell claiming load-bearing and prescribing its absence. Repaired by RE-TENSING not deletion: claim dated to r26 and marked true against the LANDED extraction; measurement untouched; contrast explicit (ADMITS/THREW/THREW against d0e9d4b's form; plain constant THREW against the seq'd form — same fixture, same element; the difference is one line in the construction instead of a rule at three call sites — the ruling's evidence line now sits AT the exhibit). ★★ THE SHARPER HALF, author's own: the r26 prose instrument exists for EXACTLY this class and DID NOT FIRE — its anchors (assertedOf/unnamed/projection-fold/caller-side-union) are absent from §13's exhibit. 'A prose instrument is only as wide as its anchors, and the F1 class does not confine itself to sentences someone already anchored.' Four rows added on this exhibit; the block reclassified honestly in the script as NAMED TRIPWIRES, NOT A PREDICATE OVER THE CLAIM CLASS — it catches recurrences where someone was already burned, nothing else. FOURTH law-38 mirror (the re-tensed passage quotes the retired claim to date it; absence row keys on the assertive opener). §13 arms simplify to the plain constant — the author's call, ratified: the kept artefact is the EXHIBIT, not the arm. All five ruling items verified at HEAD. COORDINATION NOTE ACCEPTED as standing practice: check the worktree lane's log -1 before dispatching orders to it — three crossings in this round-family each cost a verification cycle; the lane's main-checkout copy reads stale by design until merged. Gate 24 updated in flight with the amended pins.

### 18 — 2026-08-01T02:57:58 · Jason Bowman

★★ GATE ROUND 24 (spec + §4.3 implementation, first impl-in-scope on this track). IMPL d0e9d4b: CONSTRUCTION-CLEAN, PUSH CLEARED UNCONDITIONALLY — every claim verified from clean git-archive builds via the locked runner (2083→2085/2105, red 22→20 = 9+13→7+13, greened set EXACTLY the two armed rows, regressed set empty both directions; repair R's call-site enumeration verified — every assertKeysRegistered caller passes a stamping mkNode product or production elements; stampings measured 10 fields/5 sites/4 files; den-behavioral edits comment-only; entry-1 residue classBucketsOf/channelsOf untouched as expected). PUSHED: d0e9d4b now on origin/main. NAMING NOTE: my dispatch's 'IC-5 (13 rows across two files)' was MY label from the implementer's report (13 = tests reddened by repair R's widened reach), never a spec label — the gate's 10/5/4 is the stamping EDIT count; both true, different measures.

SPEC: REVISE — the r27 measurement's OBJECT MISMATCH family: ★ F1 [instrument+statement, HIGH]: the four-shape table's rows 3/4 are labelled with §13's prescribed arm ({ injections = [ ]; }, no sourceOrder) but measured with a FULL-MEMO stub — handing the prescribed arm to the real exported classSliceAt: LANDED THREW (spec says ADMITS) and THE SCOPED CONTROL THREW (a failed control invalidates the cell outright); cause: sourceOrderOf demands memo.sourceOrder, so a sourceOrder-free arm cannot serve classSliceAt for ANY element — while §5.3 states twice that sourceOrder's absence is 'the load-bearing half'. THE CONFLATION: two instrument populations (reach-stub instruments serving §4.5's injections read vs extraction-driving instruments serving classSliceAt) need DIFFERENT arms; the table conflated them. F2 [HIGH]: the revert's stated ground ('§4.3's seq fires one call earlier') names a call the fixtures NEVER MAKE — reach-graph.nix and order-instances.nix contain zero classSlice occurrences (controls live); reach.compute never enters the extraction; §5.3's own prose says so one bullet earlier. ★ F3 [CONSTRUCTION, MEDIUM]: the REAL ground is unstated and fold-shape-dependent — measured: prescribed arm and seq-arm indistinguishable against §4.5's ACTUAL fold (the sibling self.get nid resolved-aspects in the same lambda forces nid first) but the prescribed arm ADMITS a poisoned id when the injections read is ISOLATED — an implementer who splits or reorders the fold silently re-opens the hole; nothing records the both-reads-one-lambda dependence. Gate names the by-construction discharge: force sid inside injectionsOf ITSELF, one line, exactly parallel to §4.3's seq. F4 [LOW]: 69fd432 re-tensed without re-measuring — carries both erroneous cells verbatim into HEAD.

★ ORCHESTRATOR RULING (same class as the classSliceAt seq — by-construction over a recorded fold-shape dependence): ADOPT the injectionsOf-internal force. Round 28: (1) injectionsOf's fence gains the internal force of its scope id; (2) the four-shape table RE-MEASURED per consumer population with each arm at its actual call position (split the §13 arm prescriptions: reach-stub arm = injections-only, extraction-driving arm = full memo — and state WHY each field set is what its consumer demands); (3) F2's ground replaced by the honest one (now moot for safety via (1), kept as the record of what the revert actually rested on); (4) F4's amendment cells corrected with the new measurements. RULING (a) from the gate: F-R2 discharge CONFIRMED clearing (every cell reproduced incl. the tryEval-containability split); F-R1's census + arms RIGHT, licensing argument fails → §4.5 PARKED ON ROUND 28 ONLY — after it and its gate pass, unit 4a-part-2 dispatches (§4.5 consumer changes + classSliceAt seq tree edit + injectionsOf force + required sourceOrderOf formal + class-seeds rewiring + §14.7 arms). VERIFIED CLEAN: register 190/0/0 at pin + 194/0/0 at amendment; partial-revert rows genuinely discriminating with disjoint row sets (fence revert reconstructs r26's exact concatenated md5 — independent corroboration of the transition record); law-38-mirror three instances hold mechanically. Gate coverage limits: §14.7/§4.5b unarmed until §4.5 lands; nix-eval register rows not individually re-run; third mkNode (reach-graph) correctly out of §5.3's scoped 'two'. Gate's probes in session scratchpad (fourshape/reachpos/fr2).

### 19 — 2026-08-01T03:02:12 · Jason Bowman

** GATE 24 AMENDMENT REVIEW — verdict unchanged (SPEC REVISE), ★ F1 SEVERITY RAISED. Item 2 CONFIRMED independently (29 blocks byte-identical both revs, per-block md5 diff empty, positive control fires on the partial-revert mutation — measurement not inference). Item 1 REFUTED: the tense repair is real, THE MEASUREMENT IS UNTOUCHED AND THE CELL NOW CONTRADICTS ITSELF — two sentences apart the arm is defined sourceOrder-free ('deliberately does NOT answer sourceOrder') and then claimed to give ADMITS/admits-through-all-three against d0e9d4b's real binding; measured: THAT arm gives THREW for the scope-less element AND the scoped control (sourceOrderOf demands memo.sourceOrder); the stated cells reproduce ONLY on a full memo; the exhibit's own table-lookup arm is written over `memo` — the tell. ★ THE AMENDMENT PROMOTES THE TWO UNREPRODUCIBLE CELLS TO THE LOAD-BEARING PAIR ('the pair IS the argument'; 'same fixture, same element' — refuted: reach-graph's mkStub answers no sourceOrder, the measured object does). ★ CHARITABLE READING ALSO FAILS: read as arm-SHAPE with memo as confound control, rows 3/4 are IDENTICAL to row 2 in all four cells (measured) — a redundant restatement carrying a false label. ★★ THE NEW INSTRUMENT TESTS TENSE, NOT TRUTH, BY CONSTRUCTION: all four added rows are string presence/absence; NO register row re-executes the exhibit (mechanically checked — the script shells to git in 10 rows, never runs this; positive control live); it would catch deletion or re-tensing-back, not wrong cells — the failure that actually occurred. The r26 lesson was applied to the anchor's WIDTH, not its KIND. F2 untouched; F3 restated (the revert IS safe; the property — §4.5's fold forces nid via the sibling resolved-aspects read in the same lambda — recorded nowhere); F4 superseded: not merely re-tensed-without-re-measuring but promoted-while-uncheckable. Rulings unchanged: §4.5 parked on round 28 (in flight, work order already covers the re-measure + split + injectionsOf force); d0e9d4b push CLEARED (executed). Gate artifacts in session scratchpad (fences-*, fmd5-* incl. the firing control).

### 20 — 2026-08-01T03:29:37 · Jason Bowman

★★★ ROUND 28 AUTHORED, INTEGRATED (papers 94c3c7a md5-preserved: core b826da0e/5268, ledger 7ab81d0e/1743, register f2ec0280/1008), PUSHED; unification worktree COLLAPSED (wt/unification-r24 branch kept locally as round history, never pushes). REGISTER 215/0/0 (+21). All gate-24 findings discharged at class.

THE RULED FORCE ADOPTED at BOTH injectionsOf fence positions (blocks 19+21 moved, one edit both positions: 2531cb64→21744245, 299faab0→522e2c3a, concatenated 84ffc00d→037345da; count 29, classification 18/10/1, §15.1 untouched; round-28 measurements rendered as TABLES to keep index pins fixed). F3 re-derived with the author's OWN probe (gate's read, not reused): five-row isolated-vs-fold table — the fold column discriminates NOTHING (sibling forces nid first); isolated, the bare form ADMITS a poisoned id; throws separated BY MESSAGE (poisoned raises the id's own, control raises the accessor's); §4.5 carries the ruling + cost statement + WITHDRAWAL of the unqualified no-force-no-domain claim.

F1 AT CLASS: with the extraction-driving arm EVERY r27 cell reproduces (cells right, LABEL wrong); the prescribed injections-only arm handed to classSliceAt throws on EVERY element INCLUDING THE CONTROL — exhibited as DISQUALIFIED, not a fifth shape. Demand table: sourceOrderOf/classSliceAt → sourceOrder; reach.compute → injections; class-seeds → BOTH; content-key-totality → neither. Per-file sweep with in-run controls: reach-graph 1 reach/0 classSlice (prescription correct); order-instances 3/0 correct; projection-routes 0/4 correct + self-referential arm ALREADY LANDED; ★ THE FINDING INSIDE F1: projection-harness has TWO reach sites taking the RAW mkStub (mkRelocEval is bound only for the extraction; projectReachTotal binds both in one let) — §13's 'already discharges' claim WITHDRAWN; two arms at two evals; mkStub gains the plain constant. Negative half measured (compat-expose-gather drives neither 0/0; den-behavioral hits all comments 3/0).

F2: false ground replaced with the two-chain honest one; r27's sentence survives as a dated quotation. F4: both erroneous cells dated history; exhibit re-taken AT ITS OWN CONSUMER with both controls; the recurring mislabel in §8's scope row also fixed. §5.3's 'two definitions' scoped BY MEASUREMENT (third mkNode 0/0 with controls 6 and 4) + recorded DISCHARGED at d0e9d4b. ★ §13's owed rows CONSOLIDATED as ⟨O1⟩-⟨O6⟩ (classSliceAt seq; injectionsOf force ×2; reach payload+readsAttrs; class-seeds re-expression; forwardModulesFor id; instrument arms split by consumer), each stating the tree's current expression, beside the measured ALREADY-DISCHARGED half; d0e9d4b recorded PUSHED (branch -r --contains verified).

PARTIAL-REVERT DISCRIMINATION re-derived with FOUR mutations, disjoint failing sets — incl. the PROSE-ONLY revert that ONLY the two §4.5 prose rows catch (what earns them), and the both-fence revert reconstructing r27's pins EXACTLY (independent corroboration the two fence edits are byte-exact and sole). OUT-OF-CLASS FIXED IN PLACE (justified — editing that exact comment): the freeze narration had never recorded r27's block-3 move (said 6-over-8/22-identical while the block-3 CHECK carried the new pin and passed — narration⟂checks disagreement with nothing failing); corrected to 7-over-11/21 with the omission recorded at the site. PROCESS NOTE: #43's line-anchor row fired on the round's own first draft (nine occurrences, replaced with binding names) — predicate is any :digit between backticks, wider than 'backticked anchor'.

STATE: §4.5's park is DISCHARGED PENDING GATE 25 over the r28 set (papers main 94c3c7a); on a clean verdict, unit 4a-part-2 dispatches and discharges ⟨O1⟩-⟨O6⟩ row by row. Probes + mutation trees in session scratchpad (r28a/r28b/r28mutA-D).

### 21 — 2026-08-01T03:44:55 · Jason Bowman

R28 AMENDMENT (two commits, integrated to papers main d615960 md5-preserved: core 7cc5085b/5311, ledger 319af21f/1907, register 720fe198/1109; PUSHED; the author's fresh worktree collapsed — it had correctly created one off main's tip after finding its lane removed, verifying the r28 integration byte-identical first). REGISTER 225/0/0. All three relayed additions discharged:

(1) F1's residue: the refuted 'pair IS the argument' sentence was STILL ASSERTED IN THE LEDGER's r27 record — r28 had cleaned the core only; now refuted at that site, record kept as dated history. Both readings measured: literal — every cell throws at classSliceAt control included ('same fixture' false in its middle term); charitable — ★ BOTH pairs collapse (plain-constant ≡ id-IGNORING AND seq-id ≡ id-forcing, all four cells) — the four-row table has TWO behaviours; the right word is REDUNDANT, not mislabelled.

(2) ★★ INSTRUMENT KIND: the ledger gains its second fenced block — a runnable PROBE (self-contained pure Nix, no flake/tree/rev) the register extracts, md5-checks, executes, and diffs SEVEN cells; §4.3's four-shape table declared by-hand (needs the real tree) — the checked/by-hand difference now DECLARED instead of both called 'checked'. ★ THE MUTATION MATRIX CORRECTS MY LESSON LINE: probe's force removed → execution cells fire; §4.5's FENCE loses the force with probe untouched → the string rows + pins fire while EVERY PROBE ROW PASSES (the probe carries its own accessor copy — what makes it runnable is what blinds it to whether §4.5 WRITES the forced form). ⇒ AN ANCHOR AND AN EXECUTION TEST DIFFERENT PROPOSITIONS; a claim 'X is written AND X is true' needs ONE OF EACH — recorded with the width/kind line as its correction.

(3) (SF) NAMED — the sibling-force accident stated at §4.5 as what the force replaces (deleting the seq re-opens a NAMED hole). ★ AND MEASURED NOT UNIVERSAL: (SF) holds only while the stub's resolved-aspects arm is keyed on id — served as a CONSTANT (no rule forbids it) the fold ADMITS a poisoned scope id under the bare accessor, same run the keyed arm throws. 'Safe at the actual fold' was true of the stub shapes that happen to exist, not of the fold. The force makes unnecessary an invariant a fixture could already falsify. Cell sf_const_poisoned in the runnable probe.

★ AUTHOR'S OWN DEFECT → INSTRUMENT: 8a236dd split a §13 table row (pasted three-line replacement; continuation lines lost their pipe; every row below silently left the table; NO register row saw it — exposed by an unrelated count accident). TABLE INTEGRITY register row added; ★ its FIRST version failed its own positive control (looked for a single orphan line, the real break was two — answered 0 on the very commit it was written for) — DISCARDED NOT SHIPPED; shipped predicate verified 1 on the broken commit / 1 on synthetic / 0 on repaired, inside the register. The near-miss recorded as the useful part. Law-41 tightening: classSeedsAt figure now states both scopes so it cannot collide with #21's cell. ⟨O1⟩-⟨O6⟩ re-verified still owed at den-hoag 73b18c7. GATE 25 UPDATED with the amended pins — its unpark decision rules on this set.

### 22 — 2026-08-01T03:48:41 · Jason Bowman

★★ GATE (track round 29) over the R28 SET — VERDICT: REVISE, §4.5 NOT UNPARKED. (Gate's END sample matched the pre-amendment md5s b826da0e/7ab81d0e/f2ec0280 — it reviewed r28; the amendment did not touch the finding sites, carry-over to be confirmed by the fix round at d615960.) Register 215/0/0 reproduced at HEAD; origin/main movement past the pin verified beads-only.

ROUND 28's CALLS ALL HELD under independent re-derivation (nothing re-litigated): force adoption — all 20 cells reproduce from scratch incl. the discriminating cell, throws separated by verbatim message; DISQUALIFIED exhibit — every cell reproduces from the verbatim d0e9d4b bindings, label now on the TABLE HEADER attaching to every cell, states a disqualification (dead control) not a measurement; harness withdrawal correct (projectReachTotal's four lines bind both demands at two evals, raw mkStub confirmed); all four mutations reproduce (M2 reconstructs r27's three md5s exactly; M3 prose-only fires exactly the two prose rows with every fence row passing).

NEW FINDINGS — ALL IN THE OWED LIST, the one artifact the register does not exercise:
· ★★ F1 [CONSTRUCTION]: ⟨O3⟩ NAMES THE WRONG ATTRIBUTE AND ITS CURRENT-EXPRESSION CELL SELF-CONFIRMS THE WRONG ANCHOR. The changed payload structuralNodesRaw lives inside the REACH attribute (resolved-aspects.nix :355-462; reach.readsAttrs :358 = [resolved-aspects declarations children]); ⟨O3⟩ quotes RESOLVED-ASPECTS' list (:467, 106 lines below) — byte-exact against the tree, so a verifying implementer gets a CONFIRMATION and edits the wrong list, yielding an undeclared self.get on reach plus a declared-but-absent dependency on resolved-aspects — the precise error class §4.5's own prose names. §4.5c and §13's table row both get it right; the implementer-facing cell is the lone dissenter (the IC-1/IC-2 shape). CORROBORATING: §4.5's 'the list goes from one entry to two' is false under BOTH candidates (each 3→4) — the one-entry list is class-relocation's OWN readsAttrs, a THIRD list; the checking sentence points at a fourth binding. COMPOUNDING: ⟨O4⟩ omits class-seeds' own readsAttrs gain (class-modules.nix :591) that §13's table states two rows above — TWO gains exist, the owed list states one, attributes it wrong, anchors it on a third.
· ★★ F2 [CONSTRUCTION]: TWO FIXTURES BREAK UNDER §4.5 AND §13 PINS THEM GREEN — neither mkSelf in class-bucket-query.nix nor class-relocation.nix has a class-relocation arm (0/0 with the projection-routes control at 1); both drive class-seeds.compute; under the re-expression the chain hits the stub's own throw (accessor's or cannot catch a throw). Measured four cells: LANDED green / design RED on 'unexpected attr class-relocation' / arm-added green both forms. ⟨O6⟩ says the mkSelfs 'keep' the self-referential form — they have NONE TO KEEP, they must GAIN one; §13's rows 4156/4157 list record-field changes only and :4188 pins 13/13 + 3/3 unchanged. The identical mechanism §13 enumerates correctly for reach-graph (15/15→0/15), missed for the sibling family; §5.3's demand table again gets it right — owed list and break enumeration both dissent from the sweep that produced them.
· F3 [INSTRUMENT]: the register re-runs ZERO owed cells (two rows: heading + two name-presence). Gate ran all six by hand: O1✓ O2✓ O4✓ O5✓ O3✗ O6✗ — a 215/0/0 run is compatible with both errors. Law 41's class exactly.
· F4 [STATEMENT]: §5.3's instrument table mixes counting bases (reach column by read expression as stated; extraction column by token incl. comments and inherits — projection-routes' '4' contains ZERO call expressions). No demand classification changes. F5 trivial: mutation-4's row label says F2, fires the r28-§5.3/F1 row.

UNPARK: PARKED. The fix is narrow and mechanical (gate sized it): correct ⟨O3⟩ to reach's list; add class-seeds' gain to ⟨O4⟩; repair/delete the one-to-two sentence; move the mkSelfs keep→gain in ⟨O6⟩ + correct §13 rows 4156/4157/4188; ADD REGISTER ARMS RE-RUNNING EACH OWED CELL'S OWN COMMAND (without them this class recurs silently). Round 29-fix dispatched on papers main. Gate coverage limits: probes stub prelude/classifyKey/etc (sound for scope-force and arm-demand — every cell throws before those matter; not production evaluation); exact red counts inferred from routing, not measured; §6/§7/§11/§12/§14/§15.2-8/§16/§10-entries-2-5 not read closely.

### 23 — 2026-08-01T03:55:04 · Jason Bowman

RE-GATE ON THE AMENDED SET (d615960) — VERDICT UNCHANGED: REVISE, §4.5 not unparked; F1/F2 SURVIVE BYTE-IDENTICAL through an amendment whose one deletion was the exact line carrying both (44+/1−; the owed-list row rewritten for the table re-join, both findings on the + side verbatim; ⟨O4⟩ WAS amended in that row — gains the 5-across-lib qualifier — and still omits the readsAttrs gain: verified programmatically, no occurrence of readsAttrs in the segment).

ALL FOUR AMENDMENT ITEMS PASS INDEPENDENTLY: (1) both pairs collapse confirmed cell-string-exact, refutation written AT the r27 record site with both readings; (2) the middle mutation reproduced exactly (219/6 — four string rows + two pins fire, ALL 8 PROBE ROWS PASS — the different-propositions result holds); (3) ★ (SF) verified with a DIFFERENT instrument (per-cell nix-instantiate with message capture) AND the fenced probe executed verbatim — all seven cells; ★★ THE GATE CORRECTS ITS OWN ROUND-29 REPORT: its 'fold column discriminates nothing' reproduced only because its probe carried ONLY the keyed resolved-aspects arm — the amendment found the case that turns (SF) from untidy into a live hole; credit recorded. (4) TABLE INTEGRITY verified on the integrated tree (1 on the broken commit, 1 on synthetic injected into the repaired core, 0 on both repaired at HEAD — the discard of the first version was correct).

THE POINTED VERSION, banked as the round's lesson: the amendment added a guard for the owed-list row's SHAPE because an edit broke it — the row still has no guard for its CONTENT, and it is the longest, densest, most-edited cell in the spec, now demonstrated TWICE as where errors land. F3 stands verbatim (register checks heading existence + two name-presences; a 225/0/0 run compatible with both errors; gate re-ran all six cells by hand on this set: O1✓ O2✓ O4✓-count-now-correct O5✓ O3✗ O6✗).

The 29-fix author (in flight, papers main) carries the exact fix set item-for-item incl. the owed-cell register arms. Gate coverage limits: by-hand set not re-run (the amendment now DECLARES that split — an improvement over the prior round); §4.3 four-shape cells carried from its round-29 measurement (table text unchanged at the new md5); F1/F2 established by direct revision diff, not inference.

### 24 — 2026-08-01T04:27:45 · Jason Bowman

★★★ ROUND 29-FIX LANDED, papers main b1192b4 PUSHED (core e6981658/5391, ledger bc1407bf/2089, register 2b1006ca/1287). REGISTER 270/0/0 EXIT 0, STDERR NOW EMPTY (was not before — see out-of-class). Every gate finding re-verified at the amended tree before repair — all five reproduce, one WIDENED (F1 gained ⟨O4⟩), one grew a second defect at its own site (F4). Nothing narrowed.

F1 at class, THREE instances: ⟨O3⟩ re-anchored to reach (3→4), the one-entry-to-two sentence repaired (the one-entry list was class-relocation's OWN — a third list; old sentence kept as dated quotation), ⟨O4⟩ widened to BOTH readsAttrs gains. ★ Corroborating control found: containment-edges.nix builds its stub to exactly the resolved-aspects list, drives resolved-aspects.compute, stays 16/16 — the list ⟨O3⟩ named is demonstrably the one that does not move. Class sweep via an ENCLOSURE RESOLVER (quotation → owning binding, not text grep — a text predicate is what F1 defeats since both lists answer 1): 1 of 6 cells mis-anchored.
F2 at class: keep→GAIN, §13 rows corrected, ★★ CENSUS CLOSED BY EXECUTION — archive probe adding only the memo demand: suite 2085→2071, class-relocation 13/13→2/13, class-bucket-query 3/3→0/3, red-NAME delta = 14 rows in exactly two suites, comm EMPTY the other direction. ★★ RECORDED HONESTLY: the probe never consumes the value so the count CANNOT discriminate arm forms — the self-referential form is fixed by §5.3's consumer table, not the green run; nobody may cite the run as that justification. Fixture census: 11 hand-built self stubs in 10 files — five in scope, six out BY MECHANISM (each named); the two mkSelfs were the WHOLE omission. r26 transcript left byte-identical (block 27 pin unmoved); its over-claiming reader-sentence WITHDRAWN in prose per the freeze's own rule; totals restated SIX suites / 41 rows / five instrument files.
F3: owed cells MECHANIZED — each ⟨O⟩ re-runs its own command at the pin, failing alone; ★ the ⟨O3⟩ THE-TRAP row is its own positive control (same helper, same file, same run, requires a DIFFERENT binding back for the list ⟨O3⟩ used to name). All six ✓.
F4 + the defect it surfaced: extraction column restated on the read-expression basis; ★ the projection-routes ZERO forced repair of a neighbouring claim FALSE SINCE REVISION 1 — 'never touch mkOutputModules' is false of projection-routes (imports output-modules at mkOut, drives the real projectClass; controls 0/0 elsewhere); repaired in-round because the F4 cell cannot be written correctly beside it. F5: both r28 headings mutation-verified firing their own rows alone; cell now names the heading (law-41 applied to a mutation cell).
FIVE MUTATIONS, ALL DISCRIMINATE — incl. degenerate-encl firing ALL SEVEN enclosure rows, and delete-the-transcript restoring r28's exact aggregate + sliding 28/29 back (the fifth independently corroborates the fence addition is the ONLY fence change). Fence delta: one ADDITION at index 28 (35f604a6), 1-27 index+pin intact, old 28/29 md5-intact shifted, aggregate → c0c20fb5.

OUT-OF-CLASS: ★★ BACKTICKED LABELS IN check ARE COMMAND SUBSTITUTION — the author's own first row misfired, class-grep found the bug PRE-EXISTING at IC-7's row (emitting 'seq: invalid floating point argument' and a mangled label SINCE IT WAS WRITTEN, while passing); both fixed; cells were unaffected, labels only. ★ #43 fired on the round's own first draft (eight file:NNN cites — on a round whose SUBJECT was anchors pointing at the wrong thing); converted. Five presence rows tightened to prose-only domain per the block's own doctrine.

NEXT: unpark gate dispatched over b1192b4; on a clean owed-list verdict, unit 4a-part-2 dispatches with the corrected ⟨O1⟩-⟨O6⟩.

### 25 — 2026-08-01T04:45:50 · Jason Bowman

★★★ UNPARK GATE — §4.5 CLEARS FOR UNIT 4a-PART-2. No construction finding in §4.3/§4.5/§13's prescriptions; cited at core e6981658/ledger bc1407bf/register 2b1006ca, papers b1192b4, pins d0e9d4b/2e44ff5/e90b0b7. Register 270/0/0 EXIT 0 reproduced, STDERR-EMPTY VERIFIED by stream split. THE WORK ORDER IS IMPLEMENTABLE AS WRITTEN: every ⟨O⟩ cell verified BY HAND against the tree (right binding, right file, right end-state); both readsAttrs gains present and correctly attributed (reach 3→4, class-seeds 3→4); both mkSelf gains typed as GAINS; ★ the gate ran the (c) arm-restoration check UNPROMPTED — the prescribed self-referential arm restores BOTH suites to exact base parity, comm EMPTY in BOTH directions.

ADVERSARIAL RESULTS: enclosure resolver attacked on all three vectors — closed at d0e9d4b BY FACTS ABOUT THE FILES not the helper's construction (no nested-let masquerade at 2-space; zero block comments/multi-line strings; all seven patterns unique — only three uniqueness-asserted, F-B); degenerate-encl mutation fires exactly the seven rows, and the TRAP row is genuinely load-bearing (it degenerated to a DIFFERENT wrong value while three sibling rows degenerated to a coincidentally-correct one). F2 census re-derived from the gate's own archive probe — every figure reproduces including the empty reverse comm. §10's C9 pass verified as read-and-reason (self-refutes twice; discloses two unclassified-eight members no text search would surface).

FINDINGS (none park): ★ F-A [INSTRUMENT, law 42]: ⟨O3⟩'s repair is guarded by a ONE-SPELLING absence row with no presence row — the same wrong claim REWORDED passes 270/0/0 (exhibited M2; sibling ⟨O4⟩ has the right shape and fires on the identical edit class, M3). Remedy: a presence row asserting §13 states reach's OWN readsAttrs gains. F-B minor: five of seven encl rows inherit uniqueness from the tree's current shape rather than asserting it (fail-safe direction). Both queue for the next spec round — an implementer does not read the register. F-C [REGISTER MAINTENANCE]: 4kh.17 entry 1's positive control (classSliceOf → 40) is DEAD IN CODE at HEAD — renamed by this spec's own §4.3 landing; the self-inflicted decay mode the entry documents, on its own control. ★ REPAIRED BY THE ORCHESTRATOR IN THE REGISTER BODY same session (verified by command first: 0 in lib/+ci/ at d0e9d4b; re-pointed at classSliceAt = 19 in lib/attributes/, command stated).

Gate coverage limits: the reach half of the F2 census (27 rows/4 suites at e90b0b7) on the author's word; nix-eval rows not re-run (270/0/0 = text predicates + the probe fence); encl soundness pinned to three files at one pin; its own first red-set extractor returned 0 and was treated as a dead instrument not a finding (failures on stderr — corrected before any count). UNIT 4a-PART-2 DISPATCHED.

### 26 — 2026-08-01T05:06:18 · Jason Bowman

*** UNIT 4a-PART-2 LANDED AT EXACT BASE PARITY — THE P0's IMPLEMENTATION IS COMPLETE AT BOTH CONSUMERS. Commits c373564 (kernel, 4 files) + a5c3c43 (instruments, 6 files) on den-hoag main atop ba2b3cc, UNPUSHED pending the review gate. Baseline 2091/2111 20 red matched expectation; end state 2091/2111, red set BYTE-IDENTICAL (md5 594cf4a2), parity 71/71, format 0; ★ BOTH ACCEPTANCE ROWS STAYED GREEN. All six affected suites at exact base parity (13/13, 3/3, 15/15, 3/3, 25/25, 16/16) — the F2/F-R1 with-the-arms predictions confirmed; the F-R1 projection 14/16 figure correctly identified as predating the §4.3 landing (binding acceptance = restoration-to-base, holds).

PER-⟨O⟩: O1 verbatim (classSliceAt seq); O2 BOTH positions, each named throw naming ITS OWN consumer; O3 reach's list 3→4 with the other list verified untouched (containment-edges 16/16); O4 class-seeds re-expressed onto the memo per §13's row, dead bindings removed (rawSeedsAt/classSeedsAt 0 in class-modules; output-modules' DIFFERENT classSeedsAt survives as required); O5 forwardModulesFor 4-formal + the three §4.5b destination compares onto the memo + scope = n.scope (fallback 0 hits); the REQUIRED sourceOrderOf formal threaded at BOTH invocation sites (enumerated, not assumed: lib/default.nix:1915 + projection-routes:205); O6 six arms split by consumer per §13 (plain constant x3, self-referential GAINED x2, already-landed x2); the two §9.2 order-only red-set moves re-pinned and green.

★★ THREE FALSIFICATION CONTROLS (green alone does not prove the reads are reached; each restored after): reach-graph arm removed → 0/15 on the stub's verbatim throw (O3's read LIVE, exactly F-R1's prediction); mkSelf arm removed → 0/3 (O4's re-expression LIVE, exactly F2's); ★ BOTH destination sites answer-poisoned (seq the memo, empty the answer — memo demand identical, isolates destination-READING from the read) → 46 rows newly red across 16 suites incl. forwardModulesFor's and routeRemapFor's families. Both §4.5b sites heavily exercised.

IC RULINGS (orchestrator): IC-3 — §5.3's classNames-for-projection-instruments sentence vs the owed list: NOT IMPLEMENTED, ruled CORRECTLY HELD — the omission is behaviourally inert by the implementer's derivation (zero reroute acts ⇒ frame null ⇒ domain moot ⇒ the proven-total [ c ] fallback = the same answer), and the same sentence carries a second claim §13's F1 already corrected (the stale-carry suspicion is sound); STATEMENT-LEVEL disposition owed by the next spec round: retire or re-scope the sentence, and state the classNames obligation's true trigger (a fixture gaining reroute acts). IC-4 — class-seeds keeps "declarations" in readsAttrs while the re-expressed compute no longer reads it: implementer correctly landed the spec's STATED end state (4 entries, stated three places); the spec's OWN principle (readsAttrs declares this attribute's reads, not the transitive closure; a non-read entry states a dependency edge that does not exist) argues a SWAP staying at 3 — the spec disagrees with itself; conservative as landed (an over-declared edge cannot lose a schedule constraint; the transitive edge exists via class-relocation anyway). NEXT SPEC ROUND: resolve principle-vs-stated-end-state, one line either way. DEVIATION RATIFIED [C7-b]: builtins.elem hoisted to let-bound destOrder in both folds — same expression, loop-invariant (id/class are formals); inline would re-run sourceOrderOf's filter per route and per reached aspect; the fence is a mapping, not a code block.

HONEST LIMITS BANKED: O1/O2's forces have NO IN-TREE ORACLE (their discriminating populations are hand-built; byte-identical parity is consistent with omitted forces — exactly what the spec predicts at Θ(1)/WHNF; verified = transcription fidelity, not behaviour); ★ §14.5's lexical guard DOES NOT EXIST IN-TREE (checked — no ci/tests file asserts its predicates) AND ITS NON-VACUITY COMPARANDS HAVE NOW MOVED (rawSeedsAt 2→0, classSeedsAt 2→0 in class-modules, forwardModulesFor 3→4 formals) — whoever arms it must re-measure, not quote the spec's HEAD-dated figures; the destination controls prove the sites are reached and the answer matters, NOT that the answer is right under an actual relocation (no green fixture declares a reroute at a route-target root — §14.7's residual, i.e. 4b). Review gate dispatched; push rides its clearance. Remaining on this track after the gate: 4b (§14.7 five arms + §14.5 guard armed at re-measured comparands), the F-A/F-B register items, the IC-3/IC-4 statement dispositions.

### 27 — 2026-08-01T05:27:53 · Jason Bowman

★★ LANDING GATE — VERDICT: REVISE, PUSH HELD ON F1 ALONE. Every claimed figure reproduced from clean archives (base+head 2091/2111, red sets byte-identical BY DIFF — the implementer's red-set md5 recipe unstated, cell unverified-but-immaterial; parity 71/71; six suites exact base parity; ⟨O1⟩-⟨O6⟩ landed as specified with the injectionsOf throws VERBATIM against the fences from disk; §9.2's exactly-two order-only moves; §4.3a stays discharged; both acceptance tables re-run at the landed text with live discriminators — deleting the seq inverts the cells).

★★ F1 [CONSTRUCTION, SPEC+IMPL — THE HOLD]: class-seeds' readsAttrs retains 'declarations' for a read the re-expression DELETED. Measured with a same-run control: poisoning declarations ⇒ class-seeds.compute ADMITS while class-relocation.compute THREW. The list states a dependency edge that does not exist — the exact mirror of §4.5's load-bearing rule one file over. ★ MEASURED INERT IN BOTH DIRECTIONS (dropping it: full suite byte-identical) — WHICH IS THE POINT: criterion 6, documented-but-unenforced; it will never decay into a red test, only into a false statement future work reads as fact. THE SPEC IS THE PRIMARY DEFECT (⟨O4⟩ asked what the list GAINS, never what the re-expression DROPS; the implementer implemented it faithfully — IC-4 was this exact question). ★ ORCHESTRATOR RULING, IC-4 RESOLVED BY THE GATE'S MEASUREMENT: THE SWAP WINS — drop 'declarations', end state [resolved-aspects class-relocation content-key-totality]; §4.5's own doctrine controls; the conservative-direction argument acknowledged and overruled by criterion 6 (a false declaration nothing enforces is this arc's audited class). Fix dispatched: one §13 ⟨O4⟩ line + O4's register arm (papers) + one token in class-modules.nix + suite re-run (den-hoag); push follows.

F2 [INSTRUMENT, spec-sequencing — 4b's GROUND, banked verbatim]: FOUR of six landings unwitnessed by both suites — the removal matrix: O1/O2's seqs, O3's payload, O5's THREE destination compares each removable with the red set identical (parity too for O5); O4's nesting + all four O6 arms witnessed. ⇒ THE TWO BEHAVIOURAL HALVES (§4.5a payload, §4.5b destination ruling) HAVE ZERO WITNESSES; §14.6's 4 + §14.7's 5 rows are exactly their acceptance and none is landed (the spec says so itself). ★ 4b MUST NOT READ THIS UNIT'S GREEN AS EVIDENCE FOR O3/O5 — the matrix is the ground. Not held on F2: outside the owed list; the unit discharged its dispatch.
F3 [INSTRUMENT, pre-existing]: two §14.5 rows unsatisfiable as bare token counts (resolved-aspects binds a DIFFERENT scopeOf; rawSliceOf tokens in comments in 4 files) — the classSeedsAt collision the spec scoped, unscoped for these two. Queue with 4b's arming.

DEVIATIONS ALL VERIFIED SOUND: destOrder hoist (same expression, loop-invariance read at both folds, lazy let = no strictness change, no new abort reach — §4.5b's discharge holds at the landed text); IC-3's inertness premise verified (zero reroute/inject acts in the projection fixtures, the [ ]-is-DATA claim controlled against class-relocation's 6). 4b's MEASURED GROUND recorded: rawSeedsAt 0/0, class-modules classSeedsAt 0 with output-modules' must-survive binding intact at 3 lines, forwardModulesFor 4 formals, rawSliceOf/classSliceAt controls live, classSliceOf 0, assertedOf 0 outside class-modules, export set four.

### 28 — 2026-08-01T05:45:17 · Jason Bowman

★★★ F1 SWAP FIX DISCHARGED AND THE COMPLETED P0 IMPLEMENTATION IS PUSHED. den-hoag a619a8d on origin/main (the chain: ba2b3cc test unit + c373564/a5c3c43 4a-part-2 + a619a8d the swap token — one deleted token, red set byte-identical, parity 71/71); papers 4b983a3 on origin (core 8e82b684/5405, ledger 172287a6/2132, register 8580a67d/1311; REGISTER 275/0/0 stderr empty, re-run after every edit against committed content).

THE FIX, at class: §13's ⟨O4⟩ states the SWAP with the poisoning measurement as evidence and the gain-only framing named as the defect; the class-seeds compat row swept up; ★ §4.5's doctrine paragraph — where 'keeps declarations' is CORRECT for reach — had asserted its verdict GENERALLY: now names reach as its subject with the contrast block (same doctrine, two answers — the re-expression deleted class-seeds' direct read; reach's structural walk keeps its own). That was the class, not the instance. IC-4's disposition recorded as a ledger round record with a dated partial-supersede on r29's two-gains sentence (the r29 FINDING left intact — true as found). ★★ THE ⟨O4⟩ ARM DISPOSITION, better than briefed: the owed arms NOT re-pinned (their subject is the tree-at-d0e9d4b — re-pinning would break the owed measurement); instead a NEW END-STATE BLOCK pinned at a619a8d (3 entries, declarations GONE 0, class-relocation IN 1, with class-relocation's own one-entry list as the same-run dead-extractor control) — the register finally reads the list AT BOTH ENDS; the IC-4 defect was that ⟨O4⟩ was only ever measured at the start pin, where the anchor confirms byte-exactly for a claim it does not reach. Implementer deviation ratified: existing list order kept (single-token diff; no consumer pins order — swept).

BRIEF-MISMATCH ITEMS, two of them MY premises: 'the arm expects 4' was false (all tree-side arms correctly expected 3 at the pin — the 4-entry state lived only in prose, and the literal 4-entry spelling appears NOWHERE in either document, swept with controls); 'criterion 6' is the EPIC's §4 criterion 6 (invariants documented but unenforced — den-hoag-4kh's body), unresolvable from the artifacts the agent could read — the ledger cites it once with the doctrine spelled out in place, correct handling.

TRACK STATE AT PUSH: the P0's core defect is discharged at BOTH consumers and ON ORIGIN — projectClass applies the relocation (acceptance rows green since d0e9d4b), all three projectClassScoped terms read the sourceOrderOf memo (destination compares landed), the extraction is by-construction forced at both accessor layers. REMAINING ON THIS TRACK: 4b (§14.6's 4 + §14.7's 5 rows — THE BEHAVIOURAL WITNESSES for §4.5a/§4.5b per the landing gate's removal matrix, which is 4b's ground; §14.5's guard armed at the RE-MEASURED comparands; F3's two token-collision scopings), the F-A/F-B register items, IC-3's statement disposition, THE INJECT ARMED RED (v1-testimony priority), and the terminal-hop witness. The bead's headline defect is FIXED; the bead stays open on the acceptance tail.

### 29 — 2026-08-01T06:31:26 · Jason Bowman

*** UNIT 4b LANDED — THE BEHAVIOURAL WITNESSES ARE IN AND THE REMOVAL MATRIX IS INVERTED. Commits cfd6a4f (witnesses) + ad5b777 (§14.5 guard) on den-hoag main atop a619a8d, UNPUSHED pending the landing review. Baseline reproduced exactly; end state 2116/2136 (+25 arms all green), RED SET BYTE-IDENTICAL BY DIFF, parity 71/71, format 0.

★★★ THE INVERTED MATRIX, per-mutation kill sets (each applied, full suite run, diffed, restored with git-diff-verified cleanup): M1 payload-removal kills 5 (the four injection-payload arms + the agreement row); M2 destination-compares-to-literal kills 4 (both §14.7 outgoing rows + preimage + forward); M15 raw-view wrap kills 3 (the preimage-content + parent-targeted-seed rows); M3 answer-poisoning kills 397 incl. all 15 behavioural arms (broad, not discriminating — confirms reach; M1/M2 are load-bearing). EVERY non-control arm sits in ≥1 kill set; the 2 controls hold on both sides by construction. NO EMPTY EXHIBITS — the gate-14 F1 class affirmatively absent by measurement.

★★★ THE INJECT HALF IS WITNESSED GREEN (source: §14.2(a), which the spec DOES carry — three of its four rows built; the fourth needs §14.1's unbuilt evalMember, left owed): projectClass-eq-classSubtreeAt under inject at the declaring cell AND the reaching host; content [ hm-alice, inj-alice ] at both consumers; injection-free control. GREEN AT a619a8d — the landed construction already routed inject through the memo; THE GAP WAS THE WITNESS, NOT THE BEHAVIOUR. M1 kills two of the three. The bead's last core-defect gap (v1-testimony finding 3's priority) closes.

ARMS: all five §14.7 (outgoing BOTH-halves + member row on a NATIVE fleet — the member half is a systems observation only a fleet has; incoming preimage + forward mirror-pair on the stub — the mirror is what distinguishes the projecting scope from the authoring descendant); ★ ALL EIGHT §14.6 rows, double the dispatch's four (the four spec-marked-blocked rows armed too — see IC-5); test-injection-declares-no-forward carries its non-vacuity twin in-row (the byte-identical attrset as ASPECT content produces a live forward; as injection, none). New ADDITIVE instrument projectReachOf (drives the real reach.compute; hand-placed elements would let the fixture supply the payload M1 deletes; all 18 prior rows byte-identical).

§14.5 GUARD (ci/tests/class-slice-guard.nix, 9 rows, derived scan): comparands RE-MEASURED not quoted; every row a same-run control + a VERIFIED-FIRING falsifier; ★ F3's two scopings handled BY PREDICATE not file-exclusion (rawSliceOf → code-line scan with the comment-inclusive count as the strip-worked control; scopeOf → binding-ownership with the exemption set asserted exactly); honest limits IN-FILE (lexical — never that a call site passes the right VALUE; substring asymmetry stated: fail-closed on absence rows, under-detects on count rows — the rename falsifier measured BOTH directions after the toward-token rename failed to fire).

IC-5 [SPEC STALE — next spec round with F-A/F-B/IC-3]: §14.6/§14.7 record their rows as BLOCKED on 'a stub serving class-relocation from the real equation' which §15.4 says does not exist — IT EXISTS AT a619a8d IN BOTH SUITES (projection-routes:159; harness mkRelocEval:46); all seven 'blocked' rows armed with NO harness change; §15.4's priority argument rests on the false count. IC-6 [TREE DEFECT, FILED]: declare.delivery documents three fields optional, none are — omission aborts at lowerRoute's bare reads with an unnamed evaluator error tryEval does not contain, naming neither declaration nor node. The arc's signature class (documented-optional/actually-required + unnamed distant absence) in the kernel's own declaration surface.

★ INSTRUMENT LAW EARNED (the author's own near-miss, recorded): TWO mutation attempts silently failed to apply (perl -0pi \Q..\E quoting a backslash-n literally) and reported 9/9 green — MEANINGLESS; caught by git diff --numstat, not by the result. A MUTATION THAT DOES NOT APPLY READS EXACTLY LIKE A CONSTRUCTION THAT SURVIVES IT — verify the mutation landed before trusting its green. (Law-27 family; goes to memory at close.)

OWED AFTER 4b: §14.1 terminal-hop rows (evalMember unbuilt — the P0's last acceptance tail), §14.2(b)-(h) refusal rows, §14.3, §14.4. Parity not re-run under each mutation (baseline+HEAD only). Landing review gate dispatched; push rides it.

### 30 — 2026-08-01T06:50:43 · Jason Bowman

★★ 4b LANDING GATE — PUSH CLEARED AND EXECUTED (cfd6a4f+ad5b777 on origin; both test-only; every claimed figure reproduced from clean archives; M1/M2 re-run with application verified by numstat BEFORE each run — exact kill-set matches; the gate's own M-IDENT mutation (sourceOrderOf → identity, §14.5's named fail-open) killed 14 incl. all of M15's 3 WHILE THE GUARD STAYED 9/9 GREEN — the value-blindness honesty claim MEASURED true). VERDICT REVISE ON THE RECORD, corrections follow per the gate's condition:

★ F1 [CONSTRUCTION, acceptance gap — OWED]: THE THIRD DESTINATION-COMPARE LANDING HAS NO WITNESS and M2's bundling concealed it — the gate flipped ONLY the parent-targeted arm (routeRemapFor arm 2's pt.route.to compare) to literal ==: ZERO newly red. The §14.6 seed fixtures drive arm 2 but all declare to=nixos at hosts with no relocation, so the literal compare agrees. MISSING CELL: a parent-targeted route whose to is relocated AT THE PROJECTING HOST. ⇒ my 4b bank's 'removal matrix INVERTED' is true ARM-indexed, false LANDING-indexed — one of the six landings remains unwitnessed. The fixture is additive; OWED with §14.1's rows.
CORRECTIONS TO THE 4b BANK [F4]: 16 behavioural arms not 15; THREE controls not two (destination-unmoved is a control in the spec's own words); test-injection-declares-no-forward survives M1/M2/M-IDENT — its only kill set is M3 (broad, non-discriminating), so 'every non-control arm in ≥1 kill set' is carried by M3 alone for that row (the row is sound — its in-row twin is real and the M1-killed pairing holds — but the claim needed the qualifier).
F2/F3 [guard disclosure, next spec round]: row 6 guards ONE FILE not a boundary (byte-identical evasion in a NEW lib/attributes file passes 9/9; in output-modules fires — spec bullet and guard header must say the lexical form covers exactly one file); row 5's ownership exemption is a PERMANENT BLIND SPOT in resolved-aspects.nix itself (the binding-name shadow IS caught elsewhere; the exempted file is dark and the comment doesn't carve it out). F5/F6 [fixture narrowings, owed with §14.2's remaining arms]: the inject rows inject at home-manager not the spec's nixos (cell-with-no-preexisting-content case untested); no-forward is half a pair — §14.2(g)'s meta refuse-NAMED row is the other half, unbuilt, and the caption doesn't name it. F7: §14.7 rows 3-4 on the stub not native — disclosed, recorded, not held.
IC-5 SHARPENED: at the spec's dated HEAD 2e44ff5 the instrument really was 0-in-ci; at a619a8d it is 5-over-4-files — CORRECT WHEN WRITTEN, WENT STALE between revs; §15.4's priority argument + the seven BLOCKED markers rest on it (next spec round).
★ CORRECTED OWED LIST (the P0's acceptance tail, gate-verified by name-grep with a live control): §14.1 ALL THREE rows (contentsOf green-control; terminal-modules; ★ vanished-content-lands-in-the-host — NOT subsumed by 4b's member row: §14.1's asserts membership UNCHANGED AT THE DESTINATION systems.nixos, 4b's asserts GONE AT THE SOURCE — complementary coordinates); §14.2(a)'s evalMember row; §14.2(b)-(h); §14.3; §14.4's three cycle rows; F1's parent-targeted fixture. §14.5/§14.6/§14.7 DONE.
Gate coverage limits: M15 corroborated via M-IDENT not reproduced; M3 unverified by the gate; inject-green-at-base by provenance+M1 not by porting; parity not under mutation; string-interpolated/getAttr call sites structurally invisible to the lexical guard (header says so).

### 31 — 2026-08-01T14:47:24 · Jason Bowman

ACCEPTANCE TAIL LANDED (2026-08-01, implementer wt/41-acceptance rebased onto D1 landing 2, FF-pushed, main = d1ee769; six test-only commits, +33 rows over projection.nix/projection-routes.nix/class-relocation.nix; suites projection 22→48, projection-routes 27→32, class-relocation 13→15). GATES ORCHESTRATOR-RE-RUN AT REBASED TIP: ci 2175/2195 exit 1, red 20 (implementer verified byte-identical by red-set md5 diff at every unit), parity 71/71 exit 0. LANDED: §14.1 all three (incl. vanished-content asserting BOTH halves — destination membership unchanged AND projectClass 2-vs-1); §14.2(a) evalMember; (b) 3 rows (one premise-corrected, below); (c) 3; (d) 2 of 3; (e) 2; (f) 2; (g) 5; (h) 4; §14.3 + same-run non-vacuity control; §14.4 row 1 + BOTH controls (named cycle abort message asserted, acyclic clean both surfaces); F1 parent-targeted fixture — MUTATION-WITNESSED: elem→== flip at output-modules.nix:747 applied (numstat 1/1, hunk echoed), kill set EXACTLY test-parent-targeted-route-destination-follows-relocation, revived empty, reverted to numstat-empty; F5 inject-at-empty-nixos-coordinate; F6 twin-naming captions both directions. Refusal rows use msg regex naming CHANNEL AND CATEGORY (fixture-shape, not tryEval-shaped) except the terminal cycle row which is the spec's own tryEval predicate with the NAMING carried by a companion row same fleet same run. STILL OWED, with mechanisms: §14.2(d) row 3 + §14.4 row 2 (compat hasAspect/collectPathSet — reroute has no v1 spelling, cyclic/_spool fleets not authorable through denCompat.mkDen; plumbing question for the spec round); §14.4 row 3 (reach-edge-target cycle — HIGHEST-VALUE remaining cell, distinguishes §9.3's two paths; needs native opt-in reach-edge fleet + 4 controls); §14.2(h) rows 1+7 (spec places them after §7 item 6's migration, not in tree). COVERAGE CLAIMS not rows: inject-registered-class-unaffected (discharged by arm (a) same run); reroute-from-underscore = existing class-relocation.test-reroute-from-underscore-channel-is-inert, cross-referenced. LIMITS: parity not under mutation; M-PT the only mutation applied — the other 32 rows' load-bearingness unmeasured; evalMember rows cross nixpkgsLib.evalModules not full NixOS eval. TWO MEASURED FINDINGS FILED SEPARATELY: the §14.2(b) premise falsification (silent typo drop — new bead) and the forwardSourceClassesOf defaulted-formal fail-open (new bead); the §14.2(b) SPEC premise correction is a next-spec-round item alongside the queued gate-21 set.

### 32 — 2026-08-01T15:58:39 · Jason Bowman

§14.4 ROW 3 LANDED (2026-08-01, implementer wt/144-row3, FF-pushed, main = 329efb9; two test-only commits, projection.nix +278, suite projection 48→55). GATES ORCHESTRATOR-RE-RUN AT TIP: ci 2182/2202 exit 1, red 20 (implementer: red-set md5 identical both ends), parity 71/71 exit 0. THE ROW: test-relocation-cycle-at-edge-target-aborts-at-terminal + 6 companions (compat-clean control asserting KEY LISTS incl. the target's own aspect faraway — compat demonstrably ARRIVES at the cyclic node and declines to force its memo; location control moving the pair to axon aborting all three surfaces; forest control; target-sourced non-vacuity nixos-dendrite authorable only across the edge; PLUS a firing twin for the second compat accessor — with one twin the other arm's clean answer rested on nothing). DISTINGUISHES §9.3's EXTRACTION path (sourceOrderOf resolving a reached element at scope host:dendrite, outside the projecting subtree — injectionsOf can never reach it) and the discrimination is MEASURED IN-RUN: same cyclic fleet, compat accessors clean while the terminal aborts naming the TARGET. SPEC-STATUS FINDING (next spec round, same class as row 1's): §14.4 row 3 predicts true-at-HEAD/false-after — at ef51171 it is ALREADY false (§4.5 extraction resident), landed additive-green not acceptance-red. ★ PARTIAL UNBLOCK of the owed §14.4 row 2 plumbing question: the compat accessor MODULE (has-aspect-verbs.nix) binds over a natively-built den threading denCompat.refKey/augment — behaviour now witnessed; what stays unwitnessed is bridge.nix's own wiring seam; reroute still has no v1 spelling so denCompat.mkDen remains unusable for these fleets. LIMITS: no mutation applied (rows' load-bearingness vs kernel edits unmeasured); regexes pin node+channels+opening clause; class-filtered-edge interaction uncovered. Remaining owed on this bead after this landing: §14.2(d) row 3 + §14.4 row 2 (bridge-seam half), §14.2(h) rows 1+7 (behind §7 item 6's migration).

### 33 — 2026-08-01T16:22:26 · Jason Bowman

UNIFICATION SPEC ROUND 30 LANDED (2026-08-01, papers c631a3f pushed, md5 096a9ed5d08d2f55d1dee551be94debd, 5764 lines, +365/-6; register script 275 pass / 0 drift / 0 skip exit 0 via $pipestatus; zero fenced blocks touched, verified by delimiter count + diff grep). ALL SEVEN MAINTENANCE ITEMS DONE: §14.2(b) premise retracted at the row (verbatim-quoted then corrected; silent drop, totality abort harness-only; 9ue cited as tracked, remedy not imported). ★ PREDICTION-FALSIFICATION DISCHARGED AS A CLASS WITH A STRONGER ANSWER: of the 55 test- names §14 cited at r29 (extracted from PINNED papers rev 208500e), 5 resolve at d0e9d4b (construction landing) and 47 at 329efb9 — NOT ONE §14 acceptance row predates the construction, so NO row's red-at-HEAD side has ever been executed; §14 reclassified in one place as REGRESSION WITNESSES (reliable: after-side verdicts + 4b kill sets; not licensed: pre-change tree would have failed them); per-site restatements incl. §14.3 as the one row the class doesn't fully cover (vacuous-to-non-vacuous gained EVIDENCE not just a witness). Guard disclosures DERIVED from predicates at 329efb9 (row 6 one-file-by-construction via countIn; row 5 bindsOwn file-wide — resolved-aspects.nix dark to itself; homonym shadow caught, file not) — ★ TWO TREE-SIDE GUARD-HEADER EDITS OWED, dispatched this session with xx7. IC-5 four-rev census (0 / 3-2 / 5-4 / 6-4 files, one comment ⇒ 5 code sites); seven BLOCKED markers retired; §15.4's three claims retired SEPARATELY (premise false / priority MOOT-not-wrong / closing universal false today — a closed enumeration written as a universal). xx7's required-not-defaulted extension landed at BOTH ruling sites, sharpened ('? (_: { }) is a WRONG answer, not an absent one'), kernel change tracked-not-landed. §14.4 row 2 + §14.2(d) row 3 both narrowed to the bridge-wiring seam (owed on PLUMBING, not instrument — small scope extension beyond dispatch, adopted). ★ CENSUS CORRECTION TO MY OWED LIST: 8 unresolved names = 4 owed + 1 landed-split-in-three (verified) + 3 cross-referenced coverage claims — stated as arithmetic; §14.2(e) rows live in projection-routes.nix not the named harness. Incidental mis-citation §14.5 (b)→(e) corrected with reason. Register self-caught the author's one line-anchor violation (instrument working). ROUND'S OWN OWED: guard headers tree-side (dispatched); new census figures inline-self-verifying but NOT register-mechanized (follow-up candidate; exactly the IC-5 staleness class).

### 34 — 2026-08-01T16:35:47 · Jason Bowman

SPEC-TEXT FINDING for the next unification round (xx7 implementer, measured): §4.3/§7-item-7's r30 extension states the required forwardSourceClassesOf 'breaks the same four hand-built instruments item 6's required argument breaks' — MEASURED ZERO BREAKS at 3c1fced. The four instruments belong to classModulesBuilder (item 6's keyCategory); forwardSourceClassesOf is a formal of mkOutputModules, whose instantiation set is THREE members (production + two stubs), all already threading. The transfer rode the derivation across builders without re-deriving the caller set — the ruling's ARGUMENT transfers, its PRICE does not. One-cell correction next round. ALSO LANDED this branch: both §14.5 guard-header disclosures (r30's tree-side owed item) at b63b32c — that owed item is DISCHARGED.

### 35 — 2026-08-01T18:00:30 · Jason Bowman

STATUS → open (orchestrator, 2026-08-01): no agent on this bead. This session landed the acceptance tail + §14.4 row 3 + the guard headers (main through f65df25); every remaining owed cell is blocked (bridge-seam plumbing question for §14.2(d)r3 + §14.4r2; §7 item 6 migration for §14.2(h) r1+7) — blocked-waiting work is not in_progress work.

### 36 — 2026-08-01T18:25:38 · Jason Bowman

§14.2(h) ROWS 1+4+7 LANDED (main = d4005e8; full record on den-hoag-8s7's close — incl. GATE 0's premise correction: the §7-item-6 migration was in tree since e90b0b7; the 'migration not in tree' in this bead's earlier comment was a false absence). REMAINING OWED SHRINKS TO THE qni-GATED CELLS ONLY: §14.2(d) row 3 + §14.4 row 2's bridge-seam half (blocker den-hoag-qni — the one edge left on this bead). TWO SPEC-TEXT FINDINGS QUEUED for the next unification round: (1) §14.2(h) row 7's 'passes every other row and fails only this one' sentence REFUTED BY MUTATION (M4 kills row 5, not row 7 — row 5 is the direct observation of the threading; row 7 is diagnostic; §14.2(g)'s identical sentence is coherent there for lack of a separate instrument row); (2) row 2's placement divergence (specced class-relocation.nix, in tree at projection-routes.nix) predates this landing. Also transferable: the builder's caller enumeration is TWO-spelling (internal.classModulesBuilder + direct import) — a one-spelling sweep undercounts by half; boundary.nix and class-slice-guard hold the path as scan TEXT not application.
