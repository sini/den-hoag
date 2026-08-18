# den-hoag-4kh.16 — [kernel] RESIDUE of the bucket retirement: one binding classBucketsOf and its single reader channelsOf — the scope-coordinate half is REFUTED at HEAD (scope = scopeId landed 1905f1c), original acceptance otherwise DISCHARGED

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.16` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T04:39:38Z by Jason Bowman |
| last updated | 2026-07-31T02:46:52Z |
| description bytes | 5875 |
| notes bytes | 0 |
| comments | 20 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ BODY REWRITTEN 2026-07-30 AT HEAD b0f40de. The previous body was the PRE-SHIP version: it opened "RETIRE
THE PER-CLASS CONTENT BUCKET ... NEVER TRACKED IN THE GRAPH UNTIL NOW" and described a retirement that had
already SHIPPED at 222af84, while the title had been corrected to residue-only. That disagreement is exactly
the register's decay mode ("corrections that land as comments do not reach a dispatch"), and it left a live
P0 (den-hoag-4kh.41) blocked behind an acceptance condition that was already discharged. Body and title now
agree. History and the derivation live in this bead's comments.

════ WHAT IS ACTUALLY LEFT: ONE BINDING, ONE READER ════

`classBucketsOf` in lib/attributes/output-modules.nix, read at exactly ONE site in lib/ —
`graphAccessor.channelsOf`. (The only other repo hits are comments in ci/tests/class-fold-subtree.nix and a
line in lib/compat/parity/ledger.md.)

★ AND IT IS NO LONGER A CONTENT BUCKET. Its body at HEAD is
    if cn == null then [ ] else builtins.seq (classSubtreeAt id cn) [ cn ]
— it returns a channel-NAME list, forcing `classSubtreeAt` only for a classification side effect. Calling it
"the residue of the per-class CONTENT bucket" overstates what remains; a reader expecting a bucket will not
find one. The open question is whether a channel-name producer that forces a subtree query for its side
effect belongs at all, or whether `channelsOf` should ask the graph directly.

ACCEPTANCE, RESTATED TO MATCH: `classBucketsOf` is either removed with `channelsOf` re-expressed as a direct
query, or it SURVIVES WITH A STATED REASON and a stated position on which side of the kernel/compat line it
lands. "The corpus does it" is not a reason under the standing bar.

════ WHAT SHIPPED — the original acceptance, DISCHARGED, with evidence ════

The original acceptance was: the scope doc's open question ANSWERED with evidence, and a decision recorded.
Scope doc: papers/den-architecture/specs/2026-07-24-bucket-to-edge-refactor-scope.md.
Its question: does the aspect/class disambiguation DISSOLVE under an edge model (so the value-shape
predicates become deletable), or does it MOVE TO QUERY TIME?

★ THE DOC ALREADY ANSWERS ITS OWN QUESTION, §(a), verbatim: "It MOVES to the authoring surface. It does not
dissolve from the edge model alone." Its verdict: "the collision dissolves ONLY IF the refactor ALSO adopts
namespace separation (#3) at the gen-aspects surface. The edge model alone RELOCATES the ambiguity." Its
dissolution table marks the collision and the predicates as surviving Bucket-B->edge alone, dissolving only
under {Bucket-A removal + namespace separation}.

AND THE NAMESPACE-SEPARATION ARM SHIPPED. Measured at HEAD:
· `looksLikeClassContent` / `isNestedKey` are COMMENT-ONLY at exactly three sites — lib/module-shape.nix
  (header block) and lib/compat/compile.nix x2. NO live predicate anywhere. CONTROL same run: `classifyKey`
  LIVE, 9 occurrences in class-modules.nix alone. ★ The kernel-vs-compat correction is CONFIRMED:
  lib/module-shape.nix exists (1714 bytes) and lib/compat/module-shape.nix DOES NOT — so the comment residue
  is not confined to compat.
· THE DECISION IS RECORDED IN-TREE, compile.nix verbatim: "The former `looksLikeClassContent` VALUE-shape
  heuristic ... is GONE ... The namespace name-reservation retires that collision — the corpus is de-collided
  (no aspect is named after a class), so class-vs-nested is decided by REGISTRY MEMBERSHIP alone; the
  value-guess is inert and removed."
· THE COLLISION NOW HAS A LIVE LOUD MECHANISM instead of a silent recovery: lib/compat/errors.nix
  "reserved class name (C1)", and lib/compat/flake-module.nix "THE RESERVED-CLASS INCLUDE — the class-name
  reservation's include half, refused AT INGEST" (shipped e1f8a5e, den-hoag-7co).
⇒ Question answered, decision recorded, predicates deleted, collision loud, retirement shipped at 222af84.

★ AND THE OTHER HALF OF THE TITLE IS REFUTED, NOT MERELY DISSOLVED. This bead's 2026-07-29 verification
comment stated "OWNING-scope is INEXPRESSIBLE AT THE CURRENT TYPE — emit carries no owning scope id, so the
query CANNOT ASK." FALSE at HEAD: lib/attributes/resolved-aspects.nix `emit` returns
`{ key; content; sharedFoldKey; scope = scopeId; }` — verified present, landed at 1905f1c ("fix(kernel): bind
projected class modules at their own scope's pool", den-hoag-hrh) for an unrelated reason, and
output-modules.nix's `projectClassScoped` already reads it as `scope = n.scope or id`.

════ THE BLOCKING EDGE TO den-hoag-4kh.41 IS DROPPED ════

Dropped 2026-07-30 by mechanism: (a) `classBucketsOf` is not on 4kh.41's divergence path — that divergence is
`contentsOf`->`classSubtreeAt` versus `projectClass`->`classSliceOf`; (b) the type-level impossibility that
was the real blocker is refuted above. 4kh.41's remedy — unifying both class-content consumers onto one
query — is an UNSHIPPED DESIGN and therefore a gate candidate under den-hoag-4kh.6; it is NOT tracked here
and this bead no longer carries it.

════ WHY THIS BEAD STILL EXISTS ════
Not as a refactor ticket. It is the last named residue of a representation change that shipped, and it
records WHY the retirement was tracked at all: den-hoag-4kh.12's confluence design used "bucket" 52 times,
cited the scope doc ZERO times, and never asked whether the bucket should exist — through three adversarial
gate reviews, because the rubric had no predicate for "does this design ENTRENCH a construct already scoped
for retirement." That gap is now gate check C9. AN UNTRACKED RETIREMENT IS INVISIBLE TO EVERY PROCESS THAT
READS THE GRAPH.

★ RE-VERIFICATION TRAP, MEASURED: scope any check of the retired symbols to lib/ and ci/. Repo-wide,
`keyedBucketsOf`/`classSliceKeyedBaseAt`/`applyInjectReroute` show 6/7/8 hits, ALL in `.beads/beads.jsonl` —
a repo-wide grep reads them as LIVE and "corrects" the record wrongly.


## Comments (20)

### 1 — 2026-07-28T04:46:06 · Jason Bowman

★★★ CORRECTION — THIS BEAD REGISTERED SHIPPED WORK. Filed 2026-07-28 from a 2026-07-24 memory WITHOUT
VERIFYING IT AGAINST THE TREE. Owner caught it within the hour. Two of its three load-bearing claims are
FALSE at HEAD.

════ WHAT SHIPPED, and the bead claimed was open ════
★ THE CLASS / CHANNEL / FACET / ASPECT DISAMBIGUATION IS SOLVED AND SHIPPED — by DECLARATION, via
gen-schema key-semantics + gen-aspects generic dispatch. This is the "Shape B" arc (owner-ruled 2026-07-15),
not the bucket retirement.
  lib/key-semantics.nix, verbatim: "The ONE keySemantics vocabulary builder (gen-aspects `cnf.keySemantics`).
  gen-aspects builds every declared aspect key's option GENERICALLY from this map: `class → deferredModule`,
  `channel → raw passthrough`, `facet → the entry's own option/module`. den-hoag declares its whole aspect
  vocabulary through here, so an aspect key's semantics live in ONE place … from which `classifyKey` also
  reads a key's category." And: "so a quirk-channel key never falls to freeform"; a `.settings` block is
  "never freeform-absorbed as a nested aspect".
  lib/concern-aspects.nix:103-113 — `classifyKey = _aspectName: key: let cat = aspectSchema.keyCategory key;
  in if cat == "class" then "class" else if cat == "channel" then "channel" else "facet"`.
  ⇒ DISPATCH IS ON THE DECLARED CATEGORY. No value shape. The eager-commitment-at-typing problem the bead
  described is gone, and it was solved WITHOUT retiring the bucket.

★ THE VALUE-SHAPE PREDICATES ARE RETIRED, NOT LIVE. The bead cited them at compile.nix:245,263 as existing
"ONLY to recover the aspect interpretation after the fact". At HEAD:
  compile.nix:251 — "The FORMER `looksLikeClassContent`"   ← PAST TENSE
  compile.nix:218 — a comment citing v1's key-classification.nix:69-80 `isNestedKey`, pin 11866c16
  lib/module-shape.nix:6 — a comment referencing the retired guard
  Neither exists as a live predicate. Only comments naming them remain.

⇒ THE "PARKED PENDING THIS" LIST IS STALE. The aspect-name ⟂ class-name collision and both value-shape
predicates were NOT parked on bucket retirement — they were resolved by the key-semantics route. Whether
host.settings rung 5+ is still parked is UNVERIFIED and must not be assumed either way.

════ WHAT REMAINS GENUINELY OPEN — the bead's real scope, narrowed ════
THE BUCKET AS A DATA STRUCTURE. key-semantics declares `class → deferredModule`, i.e. THE PER-CLASS BUCKET
STILL EXISTS — it is now DECLARED rather than INFERRED. Declaration fixed the disambiguation; it did not
change the representation. So the open question is the narrower one:
    SHOULD CLASS CONTENT BE A DIRECT GEN-EDGE GRAPH QUERY RATHER THAN A PER-CLASS ACCUMULATED BUCKET?
That is a REPRESENTATION question, and it stands on its own evidence — output-modules.nix:133 ("gen-edge is
class-coordinate-generic … den's NixOS class buckets are ONE instantiation") and class-modules.nix's
bucket map marked "NO EFFECT RUNTIME" (effect stripped, shape kept). It is NO LONGER load-bearing for a
collision class or for two anti-patterns, because those are closed.
CONSEQUENCE FOR PRIORITY: this is a cleanliness/representation argument, not a defect with a collision class
hanging off it. It should be re-triaged accordingly rather than carried at the priority the stale framing
implied.
THE SCOPE DOC (specs/2026-07-24-bucket-to-edge-refactor-scope.md) PREDATES THE KEY-SEMANTICS LANDING and its
core open question — "does the disambiguation DISSOLVE or MOVE to query time" — HAS BEEN ANSWERED BY A THIRD
ROUTE: it dissolved, via declaration, without the edge model. ANYONE READING THAT DOC MUST BE TOLD SO.

════ CONSEQUENCE FOR den-hoag-4kh.12 ════
The blocking edge 4kh.12 → 4kh.16 was justified on "the mechanism does not survive the retirement". THAT
REASONING IS UNCHANGED — keyedBucketsOf / classSliceKeyedBaseAt / applyInjectReroute are still the
accumulator's shape and would still be deleted rather than amended under an edge model. But the URGENCY
behind it was inflated by the stale collision framing. The edge stays; its priority claim does not.

════ THE PROCESS FAILURE, recorded because it is the same one the owner is auditing elsewhere ════
This bead was created from MEMORY (project_class_bucket_holdover, 2026-07-24) and a SCOPE DOC of the same
date, and NEITHER WAS CHECKED AGAINST THE TREE before filing. The verification took four commands once
someone asked. A memory is a point-in-time observation; a scope doc is a snapshot of intent. NEITHER IS
EVIDENCE ABOUT HEAD.
★ RULE, now in the register (den-hoag-4kh.17): NO RETIREMENT ENTRY MAY BE FILED OR TRUSTED WITHOUT
VERIFYING ITS SITES AT HEAD IN THE SAME SESSION. An entry that names a file:line must have had that line
read. This applies to the register's own contents, which are hereby re-verified — see the correction there.


### 2 — 2026-07-28T05:08:58 · Jason Bowman

SEQUENCING NOTE (cost, not a block) — den-hoag-4kh.25 proposes extracting a shared `placeSlice` primitive. BOTH twins (lib/nest.nix:32, lib/attributes/output-modules.nix:441) live inside folds THIS bead may delete. Extracting first would PROMOTE A RETIRING CONSTRUCT — the hazard den-hoag-4kh.17 exists for. Prefer landing the bucket-to-query work first, or extract only after this bead's scope is settled. Recorded as a note on both beads; deliberately NOT a dependency edge, because it is rework avoidance and nothing here is incorrect if the order is reversed.

### 3 — 2026-07-28T05:09:46 · Jason Bowman

★ EVIDENCE RE-ANCHOR — this bead's TITLE is already correct ("disambiguation half already SHIPPED"), but its
EVIDENCE PARAGRAPH still cites two retired symbols. Re-verified 2026-07-28 at HEAD a40cc96.

STALE CITATION: the body cites "looksLikeClassContent / isNestedKey (lib/compat/compile.nix:245,263)".
AT HEAD BOTH ARE RETIRED:
  lib/compat/compile.nix:251  "The former `looksLikeClassContent` VALUE-shape heuristic … is GONE"
  lib/compat/compile.nix:218  cites v1's `isNestedKey` only as the ported NAME-ONLY discriminator
  Zero live uses anywhere — 3 and 5 files respectively, all comments, test headers or ledger prose.
  POSITIVE CONTROL, same run: `classifyKey` = 23 files, live at lib/concern-aspects.nix:103-106 reading
  `aspectSchema.keyCategory`.

CORRECT ANCHOR — the bead's real subject is the PER-CLASS CONTENT BUCKET, live at:
  lib/attributes/class-modules.nix — bucket vocabulary throughout
  :197  "The keyed bucket map = the direct per-(node,class) query base"
  :131  `inject { class; module }` — appends a module to a class bucket

⇒ The narrow REPRESENTATION question is what remains and it stands on its own evidence: should class content
be a DIRECT gen-edge QUERY rather than a per-class accumulated bucket? No collision class hangs off it — that
half dissolved by DECLARATION (gen-aspects @1689e41, "feat(schema): export keyCategory + structuralKeys"),
not by retiring the bucket.

★ WHY THE RE-ANCHOR MATTERS RATHER THAN BEING PEDANTRY: a reader who checks the cited lines finds retired
symbols and may conclude THE WHOLE BEAD IS STALE — closing live work for a citation's sake. The features
memory made exactly the inverse error in the other direction (recording the root as "dissolved", which would
stop the work this bead exists for). Both failures come from one paragraph carrying two half-truths.


### 4 — 2026-07-28T06:07:16 · Jason Bowman

DESIGN WRITTEN — specs/2026-07-28-bucket-to-edge-design.md, 617 lines, md5 b26937103d8252b6b7804a1395fe9ba1. NOT YET GATED.

DECISION: class content becomes a DEMAND-DRIVEN QUERY per (node, channel), evaluated from Λ(n)+Acts(n) alone. ONE attribute `class-seeds` replaces `class-modules` + `class-modules-keyed`. Successor named in gen-edge's OWN vocabulary — CHANNEL-COORDINATE SEED QUERY (channel / seed / preimage), not the retiring construct's terms.

★ THE SCOPE IS SMALLER THAN THIS BEAD ASSUMED — HALF ALREADY SHIPPED. class-modules.nix:168-171 states the base is ALREADY a direct per-(node,class) query. THE RESIDUE IS TWO WRAPPERS: `applyInjectReroute` (whole-map) and `forceContentKeysAt` (eager O(A·k̄) force on any demand). THOSE TWO ARE THE ACCUMULATOR; THE ATTRSET IS NOT. 'Retire the bucket' as a slogan overstates what remains.

★ THE GATE HOOK IS A CHECKABLE CRITERION, NOT A SLOGAN (E12, §5): TODAY `class-modules-keyed.<C>` CANNOT BE STATED WITHOUT STATING THE WHOLE MAP, because `acc.${t} ++ acc.${f}` READS OTHER KEYS' VALUES. AFTER: `classSeedsAt n c` is closed-form in Λ(n)/Acts(n)/Ch and mentions no other channel's value. The map becomes the MEMO OF A QUERY rather than the DEFINITION. Decidable by inspection.

APPLYINJECTREROUTE IS DELETED, AND ALL THREE den-hoag-4kh.12 FAILURE MODES BECOME INEXPRESSIBLE RATHER THAN CORRECTED: diamond loss — nothing is ever written so nothing is emptied, `pre` reads the RELATION; four-answers/permutation — E1-E4 are set/filter ops and act order does not appear; self-reroute abort — E1 drops from==to before any attrset exists, and the core has ZERO dynamic-key literals.

COMPLEXITY, STATED AND ONE COST REPORTED RATHER THAN ABSORBED: at Ρ(n)=∅ (every corpus node) per-channel and all-channels cost are identical and the EAGER WORK IS STRICTLY BETTER — forceContentKeysAt's O(A·k̄) leaves the class path entirely (E11 moves the totality driver to `resolved-aspects`, one driver instead of two). At Ρ(n)≠∅, Σ|pre(c)| = Σ|nf(d)|, which under multicast is EXPONENTIAL IN THE DECLARED RELOCATION FOREST'S DEPTH. NOT absorbed: §7 reports it and O4 makes `nf` dedup an OBLIGATION with a fixture, bounding it to O(K²·A).
★ THE MEMO IS LOAD-BEARING: replacing `resolve.attr` with a bare function takes `classSubtreeAt` from O(Σ_subtree A) to O(H·Σ_subtree A). Called out so an implementer does not 'simplify' it away.

C9/C9-a SELF-CHECK: register entry 1 IS this retirement — THEORY survives (class-as-coordinate is gen-edge's own, output-modules.nix:133), MECHANISM does not (whole-map fold + eager driver + bare/keyed pair all deleted). Entry 4 hit NAMED rather than swept: `forwardSourceClassesOf` reads `content.meta.__forward` (class-modules.nix:66), carried UNCHANGED with no new reader — its retirement belongs to entry 4's arc. `__action` is a gen-dispatch KIND TAG, not a state carrier. Entries 2/3 untouched. C9-a: §4, the executable core, contains ZERO occurrences of the retiring construct's word, verified by awk-range grep exiting 1.

MIGRATION COST STATED: 15 call sites / 10 CI files read the public `class-modules` attribute. ★ SEVERAL READ IT ONLY TO FORCE CLASSIFICATION (compat-materialized-class-ground.nix:28, declared-classes.nix:54) — under E11 those must force `resolved-aspects` instead, so THAT SUBSET IS NOT A MECHANICAL RENAME and each needs its intent re-read. §9.
Obligations O1-O7 in §10, each with what falsifies it. O6 sharpens the existing projection anchor, which currently RELIES on Ρ=Ι=∅ without ASSERTING it.

★ ONE OWNER RULING REQUIRED (§13 Q1) — see the P0 terminal-divergence bead. Unifying both consumers closes that defect BY CONSTRUCTION, but it CHANGES WHAT A PUBLIC EXPORT DOES (`declare`, lib/default.nix:2730). It makes the export behave as documented; it is still an observable change. Fallback if 'no': keep two disagreeing sources — explicitly not recommended.

★ MY BRIEF WAS WRONG ON ONE POINT THAT MATTERED, and the correction SHRINKS the blast radius: I asserted that retiring the per-node map 'touches a gen-aspects DECLARATION' at gen-aspects lib/types.nix:257-264. THAT RANGE HAS DRIFTED — it is now `gatedFreeformElem`, unrelated. `classOptions` is at :385-392, spread at :484. Reading it settles the substance: it declares that an ASPECT may carry content at a channel-named key — a PER-ASPECT AUTHORING SURFACE, the INPUT to classSliceOf, not a per-node index. Retiring the per-node map neither reads nor changes it. ⇒ BLAST RADIUS IS den-hoag-LOCAL, ZERO GEN-SUBSTRATE. The scope doc had this right at :24-28/:89-91; my brief re-conflated it.

### 5 — 2026-07-28T06:10:17 · Jason Bowman

★ OWNER RULING, 2026-07-28: "the change is acceptable." §13 Q1 IS ANSWERED YES — the design's decision T proceeds, including the observable change to the public `declare` export at lib/default.nix:2730.

This was the design's ONLY flagged owner-level question. Nothing else in the spec is gated on a ruling.
CONSEQUENCE: unifying both content consumers is approved, which closes the P0 terminal-divergence defect BY CONSTRUCTION rather than by adding a second application of the acts. The design no longer needs to carry its fallback branch ('keep two disagreeing sources'); that path is closed and should be marked as such rather than left as a live alternative for a future reader to reconsider.

STILL OWED BEFORE IMPLEMENTATION, unchanged by this ruling:
  - the adversarial gate on this design (in flight);
  - den-hoag-4kh.12's fixtures landed FIRST AND RED, so the replacement is proven against the original defect rather than against its own restatement of it;
  - a NEW witness for the terminal divergence, also red-first, asserting a declared relocation reaches the TERMINAL output (the existing edge-completeness.nix:214 asserts the ATTRIBUTE and is correct — it structurally cannot catch this);
  - obligations O1-O7, in particular O4 (`nf` dedup, bounding the multicast preimage to O(K²·A)) and O6 (assert Ρ=Ι=∅ at the projection anchor rather than relying on it).
★ AND THE MIGRATION SUBSET THAT IS NOT A RENAME: the call sites that read the public attribute ONLY to force classification (compat-materialized-class-ground.nix:28, declared-classes.nix:54, and any others found in the §9 sweep) must force `resolved-aspects` instead under E11. Each needs its intent re-read individually — a mechanical rename over those sites would silently drop the forcing they exist to perform.

### 6 — 2026-07-28T06:24:59 · Jason Bowman

★ GATE VERDICT: REDESIGN. PASS on C1, C2, C7, C8, C9, C9-a. FAIL on C1-a, C2-a, C3, C4, C5, C6, C7-a, C7-b.
★ THE CORE RETIREMENT (E1-E9 + E10a, the SEED path) IS SOUND AND WAS VERIFIED BY EXECUTION. All three defects are in the half that makes it 'one query, TWO consumers'.

★★ C9/C9-a PASS ON SUBSTANCE, VERIFIED OPERATIONALLY NOT BY READING: the successor is genuinely a different construction, not the accumulator renamed. `classSeedsAt n c` computes from the RELATION and never from another channel's value; E8's `genAttrs Ch` is K independent thunks. Proof: 24 act-permutations produced EXACTLY ONE answer — an accumulator gives four. The bead's founding failure did not recur.
★★ BUT THE GATE MEANT TO PROTECT THAT IS BROKEN — C2-a FAIL, and this is the sharpest finding. E12/O1's 'checkable criterion' is a NAME CHECK: 'no occurrence of `classSeedsAt n c'` in the definition of `classSeedsAt n c`'. COUNTEREXAMPLE AT HEAD, verbatim class-modules.nix:219-221: `classSliceKeyedAt = self: id: class: (keyedBucketsOf self id).${class} or [ ];` — no occurrence of itself at another channel. THE RETIRED ACCUMULATOR PASSES O1'S LITERAL CHECK. The real criterion is O1's FALSIFIER ('any cross-channel value read'), a whole-program dataflow property, not 'decidable by inspection'. Check and falsifier are different predicates and the gate can pass while the falsifier holds.

★ C7-a FAIL — BUILD-WHAT-EXISTS, FOURTH INSTANCE, AND THIS TIME AN IN-TREE COMMENT FORBIDS IT BY NAME. §9 asserts 'Substrate: none' with NO SCAN PERFORMED. gen-graph IS ALREADY A den-hoag INPUT (flake.nix:11, bound lib/default.nix:42 `graph = inputs.gen-graph.lib`) and ships exactly the primitives E2/E3/E7 hand-roll: `reachableFrom` (C-level BFS via builtins.genericClosure), `canReach`, `selfReachable`, `cycles`, `transpose`, `condensation` (reps/bottomUp/members/sccs/sccOf/condEdges — the SCC semantics den-hoag-4kh.12 reasoned in).
AND den-hoag ALREADY CALLS `transpose` FOR PRECISELY THE PREIMAGE JOB at lib/default.nix:2067, whose own comment reads: 'THE INVERSE EDGES via gen-graph.transpose (§9) … a per-kind genGraphLib.transpose (Mokhov 2017 §4.3), NOT A HAND-ROLLED FROM/TO SWAP.' ★ E3 IS A HAND-ROLLED FROM/TO SWAP. The tree contains a comment prohibiting the exact construction the design proposes, at a site doing the same job.

★ C3 + C7-b FAIL — THE COMPLEXITY STATEMENT IS REFUTED ON FOUR COUNTS, ALL MEASURED BY INSTRUMENTING E2 AND COUNTING INVOCATIONS ACROSS 7 (h,b) POINTS:
(a) EXACT COST LAW: nf invocations = 2·K·Σ_d |subtree(d)|, verified at every point (2·3·5=30, 2·4·7=56, 2·7·17=238, 2·40·142=11360). Each invocation recomputes `rho n` = O(R) ⇒ Θ(K²·b^h·R).
(b) THE DESIGN'S BOUND IS UNDERSTATED 10-13×: §7 claims K·b^h; at h=3,b=3 that is 1080 vs 11360 MEASURED; at h=4,b=3, 9801 vs 132374. §7's closure term O(K·R)=14520 elementary ops vs actual ~1.59e7 — ~1094×.
(c) ★ THE EXPONENTIAL IS AN IMPLEMENTATION ARTIFACT, NOT THE SEMANTICS, AND §7 SAYS THE OPPOSITE TO LICENSE ABSORBING IT. `pre n c = builtins.filter … Ch` ⇒ |pre(c)| ≤ K ALWAYS ⇒ Σ_c|pre(c)| ≤ K² — the content-replication term CAN NEVER BE EXPONENTIAL. The exponential lives entirely in the unmemoised `nf` re-exploration. §7 locates it in the one term where it cannot be. Under 'performance is a defect, never acceptable cost', this is the FAIL.
(d) ★ O4 IS VACUOUS — MEASURED ZERO EFFECT: 884→884 and 11360→11360. Dedup of the RESULT does not bound the RECURSION. And O4's falsifier tests the ANSWER, which `pre`'s `builtins.elem` already makes path-insensitive, so O4'S FIXTURE PASSES WITHOUT O4 and cannot detect the cost it names. An obligation with no working falsifier.
(e) FREE 2× LEFT ON THE TABLE: E4 evaluates `pre n c` TWICE, unshared; Nix does no CSE. Let-binding halved invocations (11360→5680, 132374→66187) with byte-identical answers.
⇒ (c)+(d) together: the correct fix is MEMOISING THE CLOSURE, which is what gen-graph's `reachableFrom`/`condensation` already do. BY CONSTRUCTION, not by obligation.

C1-a + C5 FAIL — E10(b) IS A TYPE ERROR AND THE TERMINAL HALF HAS NO EXECUTABLE FORM. The two consumers have DIFFERENT ARITIES: the seed path is NODE-indexed; `projectClass` is ASPECT-indexed over `reach`, and `reach` (resolved-aspects.nix:313, emit :126-133) yields `{ key; content; sharedFoldKey; }` with NO SCOPE COORDINATE. E10(b) does `concatMap (n: … classSeedsAt n class) reach` where `classSeedsAt` needs a NODE ID. Internally inconsistent within four lines: the same `let` calls `forwardSourceClassesOf reach` (treating elements as aspect records) then feeds those same elements to `classSeedsAt` (needing ids).
C5.2 — ★ A SECOND, UNSTATED BEHAVIOUR DELTA: the `exempt` set silently changes scope. Today `projectClass` (output-modules.nix:741-745) computes `exempt = forwardSourceClassesOf reach` — REACH-sourced DELIBERATELY (class-modules.nix:56: 'an unregistered fromClass a meta.__forward spec on a REACHED node names'). E6 computes it own-node only, and in E10(b) the reach-sourced exempt is used ONLY by routeRemapFor/forwardModulesFor — the content leg loses it. A `meta.__forward` spec on a reached-but-not-own aspect stops exempting ⇒ classifyKey typo-abort where content materializes today. Unstated anywhere.
C4 FAIL, ERRS UNSAFE: §7 row 2 claims eager work becomes 'O(1) beyond the demanded channel', but E11 puts the totality force on `resolved-aspects` and E6 READS `Λ(n) = self.get n "resolved-aspects"` — so demanding any channel still pays O(A·k̄). Worse and unreported: today `forceContentKeysAt` fires only on the class path; under E11 EVERY reader of resolved-aspects pays it, including `reach`, has-aspect-verbs.nix:41, resolve-verbs.nix:85. A BROADENING of eager classification presented as a reduction.
C6 FAIL: E11 and E7 sit INSIDE 'THE EXECUTABLE CORE' as PROSE COMMENTS WITH NO EQUATION. E11 is load-bearing — E10(b) drops `builtins.seq (assertKeysRegistered exempt n)` (live at output-modules.nix:750) and E11 is the only thing standing in for it. A load-bearing claim living solely in prose is itself a defect, and this one is inside the block the stamp would attest.

CONFIRMED BY EXECUTION, the design's strongest section — CLAIM 2, ALL THREE INEXPRESSIBILITY CLAIMS, no counterexample found: diamond (24 permutations → nDistinct=1, cA present at D); permutation (act order cannot appear — `pre` tests membership with `builtins.elem` and filters over Ch, so srcOrder is Ch-ordered regardless of Acts order); self-reroute ([A→A] is a no-op, A keeps its content, no dynamic-key abort). The E7 cycle throw IS `tryEval`-containable, confirming O2(c).
CLAIM 4 CONFIRMED EXACTLY: 15 occurrences across exactly the 10 named files; zero readers in lib/ (one hit = the definition, class-modules.nix:236 — predicate matches where the string exists, so the absence is real); and the not-mechanical subset confirmed VERBATIM at compat-materialized-class-ground.nix:28 and declared-classes.nix:54, both reading it for CLASSIFICATION not content.
§8 FIXTURE CLAIM CONFIRMED BY EXECUTION: all three class-bucket-query rows replayed through E1-E6 reproduce BYTE-IDENTICALLY to the fixture's expected values at :88-115.
MINOR ERRATUM: §3.2 says classSliceKeyedAt 'is exported for the class-bucket-query fixture (attributes/default.nix:249-253)'. The fixture takes `internal.classModulesBuilder` and calls `cm.class-modules.compute` — IT NEVER CALLS classSliceKeyedAt, WHICH HAS NO LIVE CALLER AT ALL. Harmless (it is on the delete list) but the stated justification is wrong.

### 7 — 2026-07-28T07:03:08 · Jason Bowman

★★ DESIGN FORK POSED — §13 Q2, THE REACH-COORDINATE QUESTION. OWNER RULING OWED. Spec now 1024 lines, md5 7e42a7d7dbd4a51bde91aee527129347 (was 617 / b2693710…). gen-graph adopted.

THE SITUATION: `classSeedsAt` is NODE-indexed (reads Λ(n), Acts(n)). `projectClass` folds over `reach`, whose elements are `{ key; content; sharedFoldKey; }` — NO SCOPE COORDINATE. The shape is fixed at the preorder emit (resolved-aspects.nix:126-133) and preserved through the edge closure's project (:403-411). So 'apply the node's relocations to a reached aspect' HAS NO REFERENT until someone says WHICH node, and the two candidates differ exactly when an aspect reaches a node that did not declare it — the only case where terminal relocation is interesting at all.

READING A — THE PROJECTING SCOPE'S ACTS GOVERN. One relocation relation per projection; Ρ(id) read once at the projecting node and applied uniformly to every aspect in reach id.
  MAKES TRUE: relocation is a property of the ASSEMBLING scope. A host says 'everything reaching me that lands on homeManager should land on nixos instead', holding over content from its cells, its edges and itself alike. Composes with `reach` without changing it.
  COSTS: an aspect's own node's relocations become invisible at the terminal while remaining visible at the edge seed — ★ THE SEED PATH AND THE TERMINAL PATH DISAGREE AGAIN, ON A DIFFERENT AXIS, which is the defect §3.3 (den-hoag-4kh.41) exists to close. And class-seeds (node-indexed) and the terminal (projection-indexed) become two different functions that COINCIDE ONLY WHEN Ρ IS EMPTY — which is every corpus node, so THE DIVERGENCE WOULD BE CORPUS-INVISIBLE, exactly like the one being fixed.

READING B — THE OWNING SCOPE'S ACTS GOVERN. Each reached aspect carries its own node's relocations; the terminal reads class-seeds at each contributing node and concatenates.
  MAKES TRUE: relocation is a property of the DECLARING scope, so an aspect means the same thing wherever it is assembled. The terminal becomes a pure gather over the same per-node query the edge seed reads — THE TWO CONSUMERS ARE THE SAME FUNCTION BY CONSTRUCTION, which is this design's whole premise.
  COSTS: ★ IT REQUIRES `reach` TO CARRY A SCOPE COORDINATE, WHICH IT DOES NOT. That is a change to a shipped, load-bearing attribute whose dedup discipline (sharedFoldKey, per-provider multiplicity, the cross-scope collapse at resolved-aspects.nix:390-399) is delicate and fixture-pinned. Adding an owning-node field to elements DELIBERATELY DEDUPED ACROSS SCOPES needs its own analysis of what 'the owning node' means for a node that survived a cross-scope collapse. Not a casual one-field addition.

★ WHAT DISTINGUISHES THEM — AND WHY PARITY CANNOT SETTLE IT: a cell declares an aspect with homeManager content and `reroute { from = "homeManager"; to = "nixos"; }`; the host reaches that cell structurally and declares no relocation. Under A the host's Ρ = ∅ so content stays on homeManager at the terminal — while the edge seed, reading the cell's own class-seeds, has ALREADY MOVED IT. Under B both move it. The mirror case separates them the other way.
NO CORPUS OR COMPAT SHAPE DISTINGUISHES THEM TODAY: den-hoag-4kh.12 records zero reroute call sites fleet-wide and §3.3 finds no inject producer, so Ρ(n) = Ι(n) = ∅ everywhere and A and B are EXTENSIONALLY EQUAL on everything currently built. ⇒ THE CHOICE IS PURE THEORY AND CANNOT BE SETTLED BY PARITY — precisely the case the north-star ruling anticipates, where corpus-green is a symptom and not the bar.

RECOMMENDATION FROM THE DESIGN AGENT — READING B. EXPLICITLY NOT ADOPTED; THE OWNER RULES.
Its reasoning, and I find it strong: this design's entire claim is 'one query, two consumers', and THAT CLAIM IS ONLY TRUE UNDER B. Under A the two consumers are different functions again — ★ AND THE FACT THAT THEY AGREE ON THE CORPUS IS PRECISELY THE PROPERTY THAT LET THE CURRENT DIVERGENCE SURVIVE THREE GATE REVIEWS. A also puts a scope's declaration in charge of content it did not declare, the direction den-hoag has consistently moved away from — offered SECOND because it is an argument from this codebase's habits, not from theory. The theory argument is first: A DECLARATION'S MEANING SHOULD NOT DEPEND ON WHO ASSEMBLES IT.
★ AND IT ARGUES AGAINST ITSELF HONESTLY: 'the cost of B is real and is a genuine reason to rule the other way; it is a change to `reach`, and it should be scoped as its own piece of work rather than smuggled into this one.'
IF THE RULING IS A, the design still lands: E10(b) becomes `concatMap (n: map (e: e.module) (raw n exempt)) reach` folded over `srcOrder (frameAt id) class`, and §4.3's by-construction claim MUST be downgraded to 'one relation, two indexings' — honestly, in the document.

Q3 IS A SECOND, INDEPENDENT DELTA, not covered by the 2026-07-28 ruling and introduced silently: today projectClass computes `exempt = forwardSourceClassesOf reach` (output-modules.nix:746), REACH-sourced deliberately per class-modules.nix:56, and threads it to the totality assertion, content extraction, routeRemapFor and forwardModulesFor alike. E6 computes it OWN-NODE only, and in the rewritten E10(b) the reach-sourced set survived only on the routeRemapFor/forwardModulesFor legs — THE CONTENT LEG LOST IT. Consequence: a `meta.__forward` spec on an aspect REACHED BUT NOT OWNED stops exempting, so classifyKey aborts where content materializes today.

### 8 — 2026-07-28T07:04:58 · Jason Bowman

REDESIGN COMPLETE — 1024 lines, md5 7e42a7d7dbd4a51bde91aee527129347 (+549/-142). lib/ UNTOUCHED (`git status --short` empty at ec6ba23), nothing committed or staged.

★ COMPLEXITY DISCHARGED BY CONSTRUCTION, NOT BOUNDED BY AN OBLIGATION. All four gate measurements reproduced independently first (cost law 2·K·Σ_d|subtree(d)| at six (h,b) points, (3,3)→11360 and (4,3)→132374; let-bound halves to 5680/66187; diamond Σ|pre|=4 vs Σ|nf|=5 falsifying the identity).
NEW BOUND: the closure term is POLYNOMIAL, bounded by K², INDEPENDENT OF RELOCATION DEPTH AND BRANCHING. MEASURED Σ_c|pre(c)| = 108 at K=40 (bound 1600) and 405 at K=121 (bound 14641). ★ THERE IS NO SHAPE OF THE DECLARED RELOCATION FOREST THAT MAKES IT EXPONENTIAL — the path enumeration that carried the exponential DOES NOT EXIST ANY MORE. §7 is split 7.1 (the refuted statement, KEPT as a record so the rejected argument leaves a trace) / 7.2 (current), and the 'cost is the semantics' licence is WITHDRAWN with the mislocation named.

O4 DELETED — struck but kept VISIBLE with its measured zero effect (884→884, 11360→11360) and the reason its fixture could not fail. REPLACED BY O4', which exists BECAUSE OF the gen-graph rewrite: 'the acyclicity guard is on the DEMANDED path' — declare a cycle, demand an UNINVOLVED channel with no relocations, require a NAMED tryEval-contained abort. ★ IT CAN FAIL AND FAILS FOR ITS OWN REASON: without the guard E3 returns ["Z"] and goes quiet — measured, that exact value — and a positive control in the same run requires the acyclic case to return normally, so an unconditional abort does not pass either. An obligation turned from vacuous into falsifiable.

E12 RESTATED OVER VALUE FLOW: for channels c ≠ c', no value read reachable from `classSeedsAt frame n c` touches any per-channel content map at c'. Other channels' NAMES flow in via `pre` (off the relation); their CONTENT does not. ★ THE SYNTACTIC FORM IS DISQUALIFIED IN THE DOCUMENT ITSELF, with the counterexample quoted verbatim — the doc states plainly that a name-check gate hook WOULD STAMP THE RETIRED ACCUMULATOR GREEN. §5's 'decidable, not rhetorical' claim is removed; both §5 and O1 now say it is a whole-program dataflow property.
★ AND THE ACCUMULATOR NOW FAILS IT — PROVEN, NOT ASSUMED. O1 discharges by finite call-graph enumeration (E6 reaches srcOrder→pre→frame.rel/frame.rev; raw→classSliceOf, Λ, Acts, className — each reading only Λ(n), Acts(n), Ch and the relocation RELATION) AND MANDATES A POSITIVE CONTROL: run the same enumeration on `classSliceKeyedAt` and confirm it FAILS by reaching `keyedBucketsOf`. An enumeration clearing both is not measuring what it claims. That control is IN THE OBLIGATION, not in prose.

E7 AND E11 PROMOTED TO EQUATIONS. ★ E11 IS A SEPARATE ATTRIBUTE, NOT A `seq` ON resolved-aspects, FOR A REASON MY BRIEF DID NOT HAVE: `resolved-aspects` is `kind = "circular"` and NAMES ITSELF in readsAttrs (:420-425), and A17 explicitly requires the self-read be passed UNFORCED — forcing its own output inside its own compute is not obviously well-founded. CONSEQUENCE: ★ THE BROADENING I WARNED ABOUT DOES NOT HAPPEN AT ALL. §7 row 2 now states honestly that eager work is O(A·k̄) RELOCATED AND MEMOISED — not eliminated, not broadened. What the design actually removes on that row is the O(R) whole-map transform.
★ ROOT-CAUSE LINK I DID NOT DRAW: E11 CANNOT replace the terminal's aspect-indexed driver FOR THE SAME REASON E10(b) IS A TYPE ERROR — `reach` carries no coordinate. So the two drivers stay on two indexes UNTIL Q2 IS RULED. Stated in E11 and O5's coverage note; it materially strengthens the fork.

E10(b) IS DELIBERATELY NOT WRITTEN. `projectClass` stays unchanged at output-modules.nix:738-752, and §0/§4.3 say so up front so no reader mistakes this for a closed design. Q1 is recorded ANSWERED YES with the ruling's scope explicitly limited to INTENT.

★ Q3 RECOMMENDATION IS READING A — `exempt` STAYS REACH-SOURCED — WHICH IS A DIFFERENT ANSWER FROM Q2's B, LEGITIMATELY. The reach-sourcing is not incidental: class-modules.nix:56 documents it as a deliberate collect-coupling ('silencing the abort alone delivers nothing'), and the exemption exists so a ROUTE can move content THE PROJECTING SCOPE CAN SEE — projection-scoped by construction, so it should stay projection-scoped even if Q2 rules CONTENT owner-scoped. Different questions, different answers. The resulting asymmetry is FLAGGED not papered over: E6's own-node exempt is correct for the seed path and INSUFFICIENT for the terminal, and the implementation must carry that explicitly. New O8 fixture owed EITHER WAY — nothing currently distinguishes the two behaviours, which is exactly how the delta got introduced silently.
★ AND IT NARROWED Q3 AGAINST MY FRAMING: today's SEED path ALREADY computes exempt OWN-NODE (class-modules.nix:206), so E6 is byte-identical there and THE DELTA IS TERMINAL-ONLY. §2's 'no new reader' claim survives, made precise rather than deleted.

FOUR MORE BRIEF ERRORS OF MINE, all corrected in the doc as §11 R7: compat/has-aspect-verbs.nix:41 and compat/resolve-verbs.nix:85 read "reach", NOT "resolved-aspects" (my conclusion holds transitively through reach; the citation does not — measured direct-reader set is collections.nix:116,225; resolved-settings.nix:228,259,300; reach at resolved-aspects.nix:313; output-modules.nix:1005). ec6ba23 also ADDED ci/tests/b1-supportedness.nix, not only the two files I named — verified rather than assumed that none of the three touches class content, so every citation is stable across a40cc96..ec6ba23. `assertKeysRegistered` is seq'd at :749 not :750. And papers HEAD was f88e6a4, not 06c2f9e (which is the commit that ADDED the spec).
ONE STRENGTHENING OF MY OWN CLAIM: I cited the reach element shape only at emit :126-133; the agent also checked the EDGE-CLOSURE leg (project at :403-411) and it returns the same record with no coordinate. So 'no scope coordinate' holds on BOTH legs — my claim was right but under-evidenced on the leg that matters most for Q2.

### 9 — 2026-07-28T07:22:31 · Jason Bowman

★ GATE 2 VERDICT: REDESIGN — NARROW AND LOCAL. ONE DEFECT. Everything else DISCHARGED, most of it BY EXECUTION.
C1 · C1-a · C2 · C2-a · C5 · C6 · C7 · C7-a · C8 · C9 PASS. **C3 FAIL · C4 FAIL · C7-b PARTIAL FAIL** — all three the same single defect.

★★ THE DEFECT: §7's Ρ(n)=∅ COST CLAIM IS FALSE, AND IT ERRS UNSAFE ON 100% OF THE CORPUS.
§7 states: 'With Ρ(n) = ∅ … the frame is never built (E7's guard and E3's transpose are inside the Ρ(n) ≠ ∅ branch by the rest-position short-circuit) … Both forcing one and forcing all are IDENTICAL to today.' Row 2's 'only when Ρ(n) ≠ ∅' is the same claim.
★ THE SHORT-CIRCUIT RUNS THE OPPOSITE WAY. `if frame.rel.edges c != [ ] then [ ]` — the branch that SKIPS `frame.rev` is taken when a channel HAS out-edges. With Ρ(n)=∅ EVERY channel takes the `else` branch, forcing `frame.rev` AND `frame` itself, hence `graph.cycles`.
PROVEN BY ABORTING SENTINELS at Ρ(n)=∅, one channel demanded: S1 transpose poisoned → {"success":false} FORCED; S2 guard poisoned → {"success":false} FORCED; ★ S3 POSITIVE CONTROL, same poison on the `then` branch → {"success":true}, does NOT fire. The instrument discriminates.
COST MEASURED on a synthetic workload containing NO fixture of either construct (avoiding the trap that made a guard look cheaper earlier in this arc), K=3 (the real classNames at lib/default.nix:128), Ρ(n)=∅, nix-instantiate --strict + NIX_SHOW_STATS:
  N=400: 9,619 → 37,641 calls · 13,046 → 68,432 thunks
  N=800: 19,219 → 75,241 calls · 25,846 → 136,432 thunks
★ 3.91× CALLS, 5.25-5.28× THUNKS. Ratios IDENTICAL at both N ⇒ a per-node constant factor, not setup. Today's Ρ=∅ path does ZERO graph work (`applyInjectReroute [ ]` is two no-op foldl').
AND §7 IS INTERNALLY INCONSISTENT: row 3 charges 'plus the frame' on first demand of ANY channel — CORRECT — while the bullet and row 2's qualifier deny it. ★ SAME CLASS OF ERROR THIS SECTION WAS ALREADY SENT BACK FOR: a cost claim licensed by a mechanism that runs the other way. Under 'performance is a defect, not a trade-off' a 4-5× regression on every corpus node cannot be absorbed.
FIX IS LOCAL — two options: state the cost honestly, or ADD A REAL SHORT-CIRCUIT (`if rho n == [ ] then <today's path>`) that makes the claim true. NOT an argument against the approach.

★ SUBSTRATE ADOPTION — CORRECT, AND IT WAS CHECKED HARDEST. flake.lock has SIX gen-graph nodes; the ROOT input resolves to gen-graph_3 = 231b31944ca55ff3126e94d6cc16895ac19ee686, and the local clone IS that rev (the bare `gen-graph` node is df7c893, a TRANSITIVE dep, not the direct input). Semantics verified against SOURCE then EXECUTED: reachableFrom IRREFLEXIVE (measured ["B"] for A in A→B→A; E3 re-adds `c` via `d == c ||`); transpose returns a TOTAL accessor; cycles names EVERY member (["A","B"]); and all three are TOTAL on unregistered channels — A→X gives preA=[], preB=["B"], cycles=[]; X→A gives preA=["A"], byte-identical to today's `acc.${f} or [ ]` no-op.
★ THE LOST-INVARIANT CHECK CONFIRMED THE DESIGN'S OWN CLAIM: unguarded E3 on A→B,B→A over Ch=[A B C Z] returns ["Z"] for Z and ["C"] for C — A SILENT WRONG ANSWER. The retired `seen`-thread enforced acyclicity for free; the explicit guard is genuinely required.
EQUIVALENCE EXECUTED, NOT ASSERTED: an INDEPENDENT hand-rolled reference (no gen-graph) agrees on all 9 shapes; the wrong-variant control disagrees on 8 OF 9, agreeing only on `empty` where the guard is vacuous.

ALL SIX PRIOR REDESIGN ITEMS DISCHARGED. C7-a: §9.1 scans and names it as a defect in the document itself; default.nix:2067's comment quoted VERBATIM-accurate; ★ R7(a)'s correction of MY brief and of bead 4kh.43 is RIGHT — the binding is flake.nix:42, lib/default.nix RECEIVES `graph` as an argument. C3/C7-b: §7.1's six (h,b) points reproduce arithmetically, and ★ THE K² BOUND IS CONFIRMED BY EXECUTION — Σ_c|pre(c)| = 108 at K=40 (bound 1600) and 405 at K=121 (bound 14641), the design's exact figures; dense acyclic total order at K=32 gives sum=32. NO EXPONENTIAL REMAINS. O4: retired WITH its measurement and reason, not silently deleted. ★ C2-a: the gate RAN O1's enumeration — E6 reaches only Λ(n), Acts(n), Ch and the relation, while classSliceKeyedAt reaches keyedBucketsOf → applyInjectReroute → `acc.${t} ++ acc.${f}`, ANOTHER CHANNEL'S VALUE ⇒ IT FAILS. The positive control genuinely discharges; the criterion separates the two constructs. C6: E7 (:305-319) and E11 (:398-414) are equations in the core.
O4' ARMED AND GENUINELY DISCHARGES: cycle A→B,B→A, demand Z → tryEval {"success":false}, named throw CONTAINED; positive control acyclic same path → {"success":true,"value":["Z"]}.
§6 CONDENSATION NON-TOTALITY CONFIRMED at the exact cited line, gen-graph lib/global.nix:165, and it ESCAPES tryEval. §6's diamond: all 24 permutations — the RETIRED fold gives 2 distinct content sets and LOSES `A` in 8 OF 24; the query gives 1 answer and loses it in 0.
★ DELIBERATE INCOMPLETENESS — STRONG PASS. Disclosed in §0, in an explicit block INSIDE the core, in §4.3, in §9's Unchanged list, in O7, and in Q2/Q3's NOT-ADOPTED recommendations. AND THE GATE CHECKED THE THING I MOST WANTED: NOTHING WRITTEN SILENTLY DEPENDS ON THE UNWRITTEN HALF — E6's own-node exempt is byte-identical to :206 on the seed path, E11 explicitly does not replace the terminal's aspect-indexed driver, E9/E10(a) never touch the terminal, and deleting both attributes does not break projectClass.
C9 PASS WITH NAMED RESIDUE, reasoned not word-swept: THEORY survives, MECHANISM does not (measured non-expressible, not corrected), ARGUMENT survives as inherited SCC theory explicitly not taken with a measured reason. Residues disclosed: E8's `seq <driver> (genAttrs Ch …)` is structurally the same shape as :208-210's, and §7 row 3 says so; and register entry 1's literal target says gen-EDGE while what landed is gen-GRAPH for the relocation index plus an unchanged per-node gather, which §9.1 discloses.
MINOR: E11's justification cites resolved-aspects :420-425 but the self-naming readsAttrs is at :427 (attr is :421-428) — substance TRUE, citation short by two lines. `declarations.nix` is lib/declarations.nix, not lib/attributes/. §4.1's 'agrees with the current fold' needs the 'as a content SET' qualifier §8 supplies (order differs: chain gives query [C,A,B] vs fold [C,B,A], which §8 declares free). §4.1's 'the UNIQUE order-independent extension' is prose-only and unproved.
NO RETRACTIONS.

### 10 — 2026-07-28T07:45:18 · Jason Bowman

★★ CORRECTIONS TO WHAT I RECORDED, AND ONE DEFECT I MISSED ENTIRELY.

(1) ★ MY RECORDED COST FIGURES DO NOT REPRODUCE. I recorded the gate's 3.91× calls / 5.25× thunks with today=9,619. An independent harness measured 1.407× / 1.618× with today=116,006. THE DEFECT AND ITS DIRECTION ARE IDENTICAL; THE MAGNITUDE IS WORKLOAD-DEPENDENT — the graph overhead is a FIXED PER-NODE COST, so a thinner content leg inflates the multiple. Neither number is wrong. ⇒ THE RATIO IS NOT A PROPERTY OF THE DEFECT AND MUST NOT BE QUOTED AS ONE. Quote the absolute per-node overhead, or state the workload with the ratio. Recorded before '3.91×' hardens into a fact about the design.

(2) ★ MY CORRECTION #3 WAS OFF-TARGET, AND THE REAL DEFECT IN THAT CLAUSE IS ONE I DID NOT FLAG. I asked for an 'as a content SET' qualifier on §4.1's agreement claim. But the sentence ALREADY restricted agreement to 'shapes where the fold is confluent', and on the correctly-characterised confluent class agreement is EXACT AT SEQUENCE LEVEL, not merely set level.
THE ACTUAL DEFECT: '(out-degree ≤ 1 forests)' MISCHARACTERISES THE FOLD'S CONFLUENT CLASS. MEASURED by exhausting permutations against the verbatim reroute arm (class-modules.nix:152-164, range verified): `chain` A→B,B→C IS out-degree ≤1 and IS NOT CONFLUENT — 2 permutations give 2 answers differing in WHERE CONTENT LANDS (cA reaches C under one, stops at B under the other). `converge` A→C,B→C likewise gives 2 answers.
★ THE TRUE CONFLUENT CLASS IS PAIRWISE-DISJOINT ENDPOINTS (empty / single / forest) — AND IT EXCLUDES THE CHAIN, WHICH IS THE SHAPE §8's ONE EXISTING WITNESS PINS. So the design was characterising its agreement region by a property that admits a non-confluent shape its own witness exercises. Written up as a three-point correction block with my set-qualifier folded in as point 2.

(3) ★ MY CORRECTION #4 UNDERSTATED IT: §4.1's 'the UNIQUE order-independent extension' is not merely unproved, it is FALSE. Counterexample EXECUTED: the extension that additionally leaves a copy at every intermediate channel (chain: B=[cB,cA], C=[cC,cA,cB]) is order-independent AND agrees with the fold across the whole confluent class — because that class contains no chain to separate them. Word dropped, counterexample recorded.

(4) TWO CITATION DEFECTS, one mine to have caught: §2's `__action` cite points at lib/declarations.nix:54-55, which is the `resolution` GROUP LIST; `__action` as a gen-dispatch kind tag is documented at :7 and read at :166 (`kindOf`). Substance true, citation elsewhere. NOT EDITED — outside the dispatched list, recorded here.
(5) §6's 'four answers' and 'cA never reaches D in 2 of 4 permutations' are den-hoag-4kh.12's FOUR-PERMUTATION SAMPLE. Exhaustive over 24: EIGHT distinct whole-maps, SIX distinct .D, cA lost in 8/24 — the query gives ONE answer over all 24 with cA present. The doc attributes the figures to 4kh.12 so it is not misstating them, but ITS OWN O2(a) DEMANDS 24. Not edited; §6 was discharged.
(6) §13 Q2's fallback code now carries STALE ARITY — `concatMap (n: map (e: e.module) (raw n exempt)) reach`, while `raw` now takes `injects`. One token. Left alone deliberately because §13 awaits the owner's ruling and must not drift under it; fix when Q2 is answered.
THE FOUR DISPATCHED CORRECTIONS ALL APPLIED: E11's cite → :421-428 with the self-reference at :427; `declarations.nix` → `lib/declarations.nix` at all three sites; the §4.1 set-qualifier folded into the correction block; 'unique' dropped.

### 11 — 2026-07-28T07:45:18 · Jason Bowman

★ §7 REPAIR DONE — OPTION 2 (real short-circuit). md5 7e42a7d7… → 6aef27d64f34e647863386a9abaee479, 1024 → 1190 lines. ★★ THE EXECUTABLE CORE MOVED — core md5 e16b09ee9c21c12a819e6b64c77e4925, 265 lines, E2/E4/E5/E6/E7/E8 all changed. THE GATE MUST RE-ATTEST; the header carries a ★ block so it cannot be missed.

THE DEFECT WAS REPRODUCED INDEPENDENTLY BEFORE BEING FIXED — own harness, den-hoag's own pinned gen-graph. ★ AND A REV TRAP WORTH KEEPING: the root `gen-graph` input resolves to lock node `gen-graph_3` = 231b319; the BARE node named `gen-graph` is df7c893, a TRANSITIVE dep. A grep-first lookup gets the wrong rev.
THE FIX: E7 answers `null` when `rho n == [ ]`; E4 branches `if frame == null then [ c ]`; E2's `relAt n` → `relOf es` so `rho n` is SHARED between the emptiness test and the relation — otherwise the fix reintroduces the CSE defect at the frame.
★ EQUIVALENCE PROVEN, NOT ASSUMED, AND THE GUARD SKIP IS SOUND RATHER THAN A LAZINESS ACCIDENT: no edges ⇒ transpose empty ⇒ reachableFrom [ ] ⇒ `pre c` filters Ch to [ c ] ⇒ srcOrder c = [ c ]. And `cycles = filter selfReachable Ch` where `selfReachable c` is `any` over a genericClosure from `edges c = [ ]` ⇒ EMPTY START SET ⇒ false for every c. So `cycles` is PROVABLY [ ] on an edgeless relation — the answer is DECIDED, not suppressed. A cycle-carrying relation always has an edge and always builds the frame, so O4' is untouched and still fails for its own reason.
NOT A TWO-PATH REBUILD — the branch is on ORDER (a list of channel NAMES), never on content; both arms feed the same `concatMap (raw n exempt injects)`. ONE content expression in the core.
EXECUTED OVER 11 SHAPES (empty, selfLoopOnly, twoSelfLoops, chain, deepChain, diamond, multicast, converge, forest, partialDepth, selfLoopPlusReal) — agree on all 11. ★ WRONG-VARIANT CONTROL (fast path answering `Ch` instead of `[ c ]`) disagrees on EXACTLY the 3 Ρ=∅ shapes and agrees on the other 8 — it fails where it is live and is vacuous where it is not, so the battery can actually detect a wrong fast path.

★ SECOND DEFECT FOUND BEYOND THE BRIEF, AND ACCEPTED: THE SHORT-CIRCUIT ALONE DOES NOT RETURN TO TODAY. E6 also rebuilt two NODE-LEVEL values per channel — `exempt = forwardSourceClassesOf (Λ n)` and the `inject` filter over Acts(n) — neither depending on `c`, so `genAttrs Ch` paid them K times. SAME DEFECT CLASS as §7.1 item 4 already records at `pre`. Hoisted into E8's per-node `let`, with `raw`/`classSeedsAt` taking them as params. Value-identical by inspection. ACCEPTED — it is the same finding the section already documents, and leaving it would have shipped a fix that did not fix.

MEASURED (Ρ=∅, K=3, no reroute/inject fixture anywhere, Acts(n) non-empty with unrelated kinds so `rho`'s filter is still paid, deepSeq + FORCED sentinel, min of 3 runs):
  today                 116,006 calls / 115,293 thunks  (N=400)
  query as published    163,218 / 186,589   = 1.407× / 1.618×
  + short-circuit       138,408 / 132,494   = 1.193× / 1.149×
  + hoist               125,208 / 122,894   = 1.079× / 1.066×
Ratios IDENTICAL at N=400 and N=800 ⇒ per-node constant, no scaling term. ★ POSITIVE CONTROL ADDED: the same three poisons on a Ρ≠∅ workload ALL FIRE, so the Ρ=∅ silence is a fact about the code and not a dead sentinel.
★ THE RESIDUAL 1.079×/1.066× IS STATED, NOT CLAIMED AWAY, AND REFUSED FOR THE RIGHT REASON: the query still evaluates `concatMap (raw …) [ c ]` where today calls `classSliceKeyedBaseAt` directly. Closing that last ~7% would mean giving the fast path ITS OWN CONTENT EXPRESSION — which is §3.3 rebuilt. Refused on THOSE grounds, not on cost. The substantive claim is ZERO GRAPH WORK AT Ρ=∅, and that is measured.

### 12 — 2026-07-28T10:33:13 · Jason Bowman

★★ OWNER RULINGS, 2026-07-28 — BOTH FORKS ANSWERED. §13 Q2 AND Q3 ARE CLOSED.

Q2 — READING B. THE OWNING SCOPE'S `Acts` GOVERN A REACH-SOURCED ASPECT.
So a declaration's meaning does not depend on who assembles it, and the terminal becomes a pure gather over the same per-node query the edge seed reads — ⇒ 'ONE QUERY, TWO CONSUMERS' IS NOW TRUE BY CONSTRUCTION, which was this design's whole claim and was only ever true under B.
★ THE COST IS REAL AND WAS RULED ON WITH EYES OPEN: `reach` MUST CARRY A SCOPE COORDINATE IT DOES NOT HAVE. Verified on BOTH legs — the preorder emit (resolved-aspects.nix:126-133) and the edge-closure `project` (:403-411) — both yield `{ key; content; sharedFoldKey; }` with no coordinate. Adding one touches fixture-pinned cross-scope dedup (`sharedFoldKey`, per-provider multiplicity, the collapse at :390-399), and 'the owning node' is NOT WELL-DEFINED for an element that survived a cross-scope collapse. ⇒ SCOPE THE REACH-COORDINATE CHANGE AS ITS OWN PIECE OF WORK. Do not smuggle it into this design; the design agent asked for exactly that and it is the right shape.
Q3 — READING A. `exempt` STAYS REACH-SOURCED AT THE TERMINAL. A DIFFERENT ANSWER FROM Q2, DELIBERATELY: the reach-sourcing is not incidental (class-modules.nix:56 documents it as collect-coupling — 'silencing the abort alone delivers nothing') and the exemption exists so a ROUTE can move content THE PROJECTING SCOPE CAN SEE. That is projection-scoped by construction, and stays so even though CONTENT is now owner-scoped.
★ THE ASYMMETRY IS THE RULING, NOT AN OVERSIGHT: content follows the DECLARING scope, exemption follows the ASSEMBLING scope, because they answer different questions. E6's own-node `exempt` is correct for the seed path and INSUFFICIENT for the terminal, and the implementation must carry that explicitly rather than unify them for tidiness. O8's fixture is owed EITHER WAY — nothing currently distinguishes the two behaviours, which is exactly how the delta got introduced silently.

WHAT THIS UNBLOCKS AND WHAT IT DOES NOT:
  E10(b) can now be WRITTEN — its type error was precisely the missing coordinate, and Q2 says what the coordinate means. But it CANNOT BE COMPLETED until the reach-coordinate work lands, so the terminal half stays unwritten and §0/§4.3's disclosure stays accurate.
  den-hoag-4kh.41 (P0, declare.inject/reroute do not reach the built system) is fixed BY CONSTRUCTION under B — one query, so no second place for the acts to go missing from. Still blocked on this design landing.
  §13 Q2's fallback code (the Reading-A branch) is now DEAD and should be removed rather than left as a live alternative — its stale arity is moot. Record the rejected reading WITH ITS REASON so it is not re-proposed.
NEXT: the core moved with the §7 short-circuit repair (core md5 e16b09ee9c21c12a819e6b64c77e4925, 265 lines) and OWES A FRESH GATE ATTESTATION. Q2/Q3 being answered does not substitute for it.

### 13 — 2026-07-28T10:44:51 · Jason Bowman

★ Q2/Q3 RULINGS APPLIED — md5 6aef27d6… → 278fcbc75b79633652a36ed5aed0e698, 1190 → 1311 lines. ★ EXECUTABLE CORE UNCHANGED, AND PROVEN SO RATHER THAN ASSERTED: 265 lines, diff against the pre-edit extraction EMPTY, with a POSITIVE CONTROL in the same run — commenting one line INSIDE the core changes the hash, so the predicate detects core changes and 'unchanged' is a measurement, not blindness.

BOTH REJECTED READINGS RECORDED WITH THEIR REASONS RATHER THAN DELETED. Q2's Reading-A fallback is kept VERBATIM and tagged REJECTED, with the reason stated: it delivers exactly the property whose absence IS the defect — two functions coinciding only where Ρ=∅, i.e. every corpus node, so the new divergence would be corpus-invisible in the same way and for the same reason as §3.3. Its stale arity is noted as MOOT and explicitly flagged as NOT the reason for rejection. ★ Q3's Reading-B rejection carries the sharper one: 'it matches the other ruling' is TIDINESS, NOT A REASON — recorded so symmetry is not re-proposed as a simplification.
THE ASYMMETRY IS WRITTEN AS THE RULING, in both §4.3 and §13 Q3: content follows the DECLARING scope, exemption follows the ASSEMBLING scope, because they answer different questions. And it states what each wrong unification costs — unifying on own-node reintroduces the silent delta; unifying on reach-sourced pushes a projection concern onto the node query. O8 is now owed BECAUSE OF the ruling rather than pending it: it is what pins the asymmetry against a future tidy-up.
THE INCOMPLETENESS DISCLOSURE IS STILL ACCURATE WITH A CHANGED REASON — was 'a semantic fork is unruled', now 'reach lacks the scope coordinate the ruling requires'. E10(b) can be WRITTEN but not COMPLETED; the terminal expression was correctly NOT written. den-hoag-4kh.41's fixed-by-construction link stated twice.
RE-ATTESTATION EXPLICITLY NOT SUBSTITUTED: a new paragraph says the rulings are PROSE and are not the attestation, so the gate cannot read one for the other.

★★ MY CORE ANCHOR DOES NOT REPRODUCE, AND THE UNDERLYING DEFECT IS WORSE THAN A WRONG NUMBER. I recorded core md5 e16b09ee9c21c12a819e6b64c77e4925 (inherited from the §7-repair agent's report and propagated without re-deriving it — the SAME failure as the produces self-refutation earlier tonight). It appears NOWHERE. The agent tried SIX boundary choices plus an awk fence-extraction on the committed text — 215,481 / 216,480 / 216,481 / 215,480 / 204,481 / 205,481 — and none match. The core is provably unchanged since da871e9, so this is not drift.
★ THE REAL DEFECT: THIS SPEC'S HEADER ★ BLOCK ANNOUNCES THAT THE CORE MOVED AND DEMANDS RE-ATTESTATION, BUT CARRIES NO MD5 AND NO LINE COUNT AND NO EXTRACTION RECIPE. The anchor lives in my tracking rather than in the document, so it is UNVERIFIABLE BY ANY READER. Contrast the produces spec, which carries a SELF-VERIFYING recipe — a reviewer re-runs it and either matches or does not. That is why its three gate rounds could each re-attest the core independently and this one cannot.
⇒ THE FIX IS NOT TO CORRECT MY NUMBER. It is to give this spec the same self-verifying recipe, so the anchor is a property of the artefact rather than of whoever last measured it.

TWO CITATION DRIFTS, both of which the DOCUMENT shared: the collect-coupling phrase is class-modules.nix:58 (the block is :55-60); :56 holds the 'unregistered fromClass' sentence, which the doc quotes correctly. And the cross-scope collapse is resolved-aspects.nix:391 (`structuralNodes = dedupByKey (n: n.sharedFoldKey or null) structuralNodesRaw`, comment :383-390); :393-399 is an unrelated foldReach comment. Corrected in the new text; one pre-existing :390-399 remains in Q2's cost bullet.
JUDGEMENT CALL FLAGGED AND I AM OVERRIDING IT: the core's own comments at :436 ('UNTIL Q2 IS RULED') and :447 ('downstream of §13 Q2') now name the WRONG BLOCKER. The agent left them because the core is the frozen artefact the re-attestation is of — correct reasoning in general. But a re-attestation is ALREADY OWED, so correcting them costs nothing extra, and shipping a core with knowingly-superseded comments to a gate is worse than one more hash change.

### 14 — 2026-07-28T10:52:08 · Jason Bowman

★★ CORE ANCHOR NOW SELF-VERIFYING — and it immediately caught that MY earlier verdict was wrong.

I recorded that core md5 a8a5a18b… 'matches nothing' after a reviewer tried six boundary choices. FALSE. ★ THE HASH WAS RIGHT AND MY RANGE WAS WRONG — off by EXACTLY 16 LINES. The correct range at 98f920b is 232,496 (the content of the nix fence, opener 231, closer 497), which yields exactly 265 lines and a8a5a18b27f2824cbf0213a3097de048. My 216,480 yields 264 lines and e86b96b716f9c5c60d4ecbb2c893beaf. The 16-line shift is the rulings edit growing the header AFTER the anchor was measured.
⇒ THIS IS PRECISELY THE FAILURE THE ANCHOR FIX EXISTS TO KILL, and it demonstrated itself on the way to being fixed. A LINE-NUMBERED ANCHOR DRIFTS WHENEVER ANYTHING ABOVE IT CHANGES — which is every revision — AND IT FAILS LOOKING LIKE CORRUPTION rather than like drift. Both the reviewer and I concluded the hash was bogus when the content was intact and merely moved.

THE ANCHOR IS PRINTED AT :25-46 AND DERIVES ITS BOUNDARIES FROM THE DOCUMENT'S OWN MARKERS, NOT FROM LINE NUMBERS: an awk keying on the §4 heading and the nix fence, so it is immune to anything above or below moving. Yields 269 lines, md5 fbf69ab8a4c998af95db8d1c2eba949e. The recipe was verified by EXTRACTING THE PRINTED BLOCK FROM THE DOCUMENT AND RUNNING IT VERBATIM — not by running the author's shell history. Fence written with four backticks so the inner triple-backticks survive; patterns line-anchored so the recipe cannot self-match. The doc carries the 'RE-RUN IT, DO NOT TRUST THE NUMBER' sentence.
★ TWO CONTROLS, NOT ONE: perturbing a line INSIDE the core moved the hash (fbf69ab8… → a0ddef8c…, restored byte-identical); appending a line OUTSIDE the core left it UNCHANGED. So the recipe both detects core changes AND is genuinely scoped to the core rather than quietly hashing the whole file. The second control is the one I did not ask for and is the one that proves scope.
★ COMMENTS ARE DELIBERATELY IN SCOPE, unlike the sibling spec's comment-stripping recipe — E7 and E11 are EQUATIONS CARRIED AS COMMENTS, so stripping them would drop load-bearing content. Recorded because the two specs now differ and a reviewer moving between them must not assume one recipe.

THE TWO SUPERSEDED CORE COMMENTS ARE CORRECTED, per my override: :463-467 now states Q2 IS RULED (Reading B), that the SEMANTICS are settled and no longer what blocks E10(b), and that THE MISSING COORDINATE ALONE is — with E10(b) remaining `projectClass` unchanged until `reach` carries one. :477-478 likewise re-points the driver-collapse blocker from 'a pending ruling' to 'that coordinate'. Core 265 → 269 lines.
★ AND THE AGENT AMENDED SOMETHING I DID NOT NAME, CORRECTLY: the header's second ★ block asserted the core is 'byte-identical to the revision the demand above names'. Fix (2) FALSIFIES that sentence, and shipping it would have placed A FALSE BYTE-IDENTITY CLAIM DIRECTLY BESIDE A HASH PROVING OTHERWISE. It amended that one sentence, kept the block's point (rulings ≠ re-attestation), and named the two comment edits as the rulings' only core edit. APPROVED — 'do not touch the rulings' meant the ruling records, not a claim the ruling had made false.
CITATION: Q2's cost bullet :390-399 → :391 (comment :383-390). ★ AND THE OTHER HALF OF MY FIX (3) HAD NOTHING TO FIX — zero remaining :56 attributions of the collect-coupling phrase, with a POSITIVE CONTROL in the same run: `class-modules.nix:56` DOES match once, at the 'unregistered fromClass' quote I had said was correct. The predicate could have fired and found only the good one.

### 15 — 2026-07-28T15:36:46 · Jason Bowman

★★ GATE 3 (full re-attestation) — VERDICT: REDESIGN. ONE CORRECTNESS DEFECT IN THE EXECUTABLE CORE, plus one false paragraph about the attested artefact. C1, C1-a, C2, C2-a, C5, C7, C7-a, C7-b, C8, C9, C9-a PASS. C3, C4, C6 FAIL — ALL THREE ARE THE SAME SINGLE DEFECT.

★ THE ANCHOR WORKED. The printed recipe reproduced BOTH hypotheses exactly — 269 lines, fbf69ab8a4c998af95db8d1c2eba949e — and the gate ran FOUR controls, two more than I asked for: perturb INSIDE → 098710b5…, hash MOVES; append at EOF → HOLDS; insert BEFORE the §4 heading → HOLDS; ★ insert INTO §4.1-4.3 PROSE → HOLDS. That fourth control establishes something the spec only asserted: DECISIONS M, R AND T ARE NOT IN THE ATTESTED CORE — they are prose. The self-verifying anchor paid for itself on its first use.
It also verified my 'cited files unchanged ec6ba23..6f472d3' claim itself (empty, exit 0) rather than inheriting it, and resolved the gen-graph pin through the lock's multiple nodes to 231b319, confirming the local clone IS that rev and building its harness from `git archive` rather than the worktree.

★★ FINDING 1 — CORE DEFECT: AN UNREGISTERED **INTERMEDIATE** CHANNEL SILENTLY DROPS CONTENT, DIVERGING FROM BOTH ORACLES.
Acts `[A→X, X→B]` with `X ∉ Ch`, `Ch = [A B C]`:
  today (`applyInjectReroute`)  B = ["cB","cA"]
  retired `nf` (path enumeration) B = ["cB","cA"]
  ★ query (E1-E6)                B = ["cB"]        ⇒ `cA` IS SILENTLY LOST
MECHANISM, ISOLATED: `graph.transpose { edges; nodes = Ch }` materialises via `prelude.genAttrs nodes` (gen-graph edge-maps.nix:3), so X's out-edge X→B IS NEVER MATERIALISED BECAUSE X ∉ nodes — measured `materialize = {A=["X"], B=[], C=[]}`, hence `rev.edges "B" = []`, hence `pre B = ["B"]`. But the RAW accessor sees it: `rel.edges "X" = ["B"]`. And `pre A = []` because A has an out-edge, so cA is orphaned.
★★ THIS ANSWERS THE QUESTION I PUT IN THE BRIEF — what did the hand-rolled version enforce STRUCTURALLY that the library does not? TWO things, and the design found only one. (a) ACYCLICITY: the `seen`-threaded recursion could not step past a cycle; `genericClosure` answers silently. THE DESIGN CAUGHT THIS (E7, O4'). (b) ★ NODE-DOMAIN INDEPENDENCE: the hand-rolled `pre`/`nf` walked the RAW EDGE LIST with no `nodes` domain and traversed THROUGH unregistered channels; `transpose` TRUNCATES to its domain. THE DESIGN MISSED THIS.
IN-DOMAIN, NOT HYPOTHETICAL: `className c = if isAttrs c then c.name else c` (class-modules.nix:31-37) passes bare strings through, THE SHIPPED FIXTURE ci/tests/class-bucket-query.nix:63-74 ALREADY DECLARES REROUTES WITH BARE STRINGS, and no validator anywhere rejects an unregistered endpoint (grep across lib/, positive control `classNames` = 56 hits). E2's own comment admits unregistered channels into the relation.
IT FALSIFIES TWO STATED CLAIMS: E2's 'total for transpose/cycles/reachableFrom' — ★ TOTALITY IS NOT AGREEMENT, transpose does not abort but is not FAITHFUL; and §6's 'byte-identically to the retired formulation', which is TRUE on the ONE-HOP inputs measured (unregistered TARGET and unregistered SOURCE both verified byte-identical) and FALSE AT TWO HOPS.
⇒ C4 FAILS on direction: it errs by SILENTLY DROPPING, where E7's own principle for the analogous case is 'aborting is the only total alternative to inventing one'. C6 FAILS on enumeration: unregistered TARGET ✓, unregistered SOURCE ✓, registered ✓, cycle ✓, self-loop ✓, Ρ=∅ ✓ — ★ UNREGISTERED INTERMEDIATE NOT ENUMERATED, AND IT IS THE ONE THAT DIVERGES. §6 had the right instrument aimed at the right domain AND STOPPED ONE HOP SHORT. C3 FAILS because 'byte-identical' over the whole unregistered domain is licensed by a one-hop measurement plus a non-abort observation — SAME SPECIES as the previous two gates' C3 failure, different site.

★ FINDING 2 — §4.3 (doc :648-653) IS FALSE ABOUT THE ATTESTED CORE ITSELF. It claims E10(b)'s comment reads 'UNTIL Q2 IS RULED', that E11's says 'downstream of §13 Q2', and that 'they are NOT edited here'. MEASURED over the extracted core with a positive control: `grep 'UNTIL Q2 IS RULED'` → NO MATCH; control `grep 'UNTIL'` → 1 match at core line 207, 'UNTIL `reach` CARRIES A SCOPE COORDINATE'; `grep 'downstream of'` → core line 219, 'downstream of THAT COORDINATE, NOT of a pending ruling: §13 Q2 is ruled (Reading B)'. ★ THE COMMENTS WERE EDITED — MY OVERRIDE LANDED — AND THE PROSE SAYS IT DID NOT. The header at :19-25 is the correct one. Consequence: it instructs a future implementer to 'correct' comments that are already correct, and tells a re-attestation gate the frozen core carries stale blockers when it does not. Prose-only; the core is right.

EVERYTHING ELSE RE-ATTESTS GREEN, MOSTLY BY EXECUTION: the short-circuit is SOUND not lazy (`graph.cycles` on an edgeless relation is DECIDED [] — positive control, A→B,B→A gives ["A","B"]); 11-shape battery agrees 11/11 against BOTH an independent reference and the retired `nf`, with two discriminating wrong-variants (fast-path-answers-Ch disagrees on exactly the 3 Ρ=∅ shapes; no-guard disagrees on 8 of 11); K² bound reproduced at all six (h,b) points including the spec's exact 108-at-K=40 and 405-at-K=121; O4' FIRES, is tryEval-CONTAINED, has a positive control, and its FALSIFIER was armed — guard removed, it goes quiet returning ["Z"], exactly as O4' states; O2(b) confirmed — today's self-relocation is UNCATCHABLE, `tryEval` did not contain `dynamic attribute 'A' already defined`; §6's condensation abort reproduced AT THE EXACT CITED LINE with a 3-primitive control; the confluent-class correction confirmed by exhausting permutations (chain and converge both out-degree ≤1 and NOT confluent, 2 answers each; 3-act disjoint IS confluent over 6 perms).
★ E12/O1 DISCHARGES EXECUTABLY, and the gate RETRACTED TWO OF ITS OWN NON-DISCRIMINATING PROBES before finding the separating workload: reroute darwin→nixos, demand `nixos`, poison the per-channel content MAP at `darwin` — the QUERY returns cleanly (it reads aspect content via E5 `raw`), the RETIRED `classSliceKeyedAt`/`keyedBucketsOf` FIRES on `acc.${f}` at class-modules.nix:161, and a liveness control poisoning the demanded channel fires BOTH. Same answer, opposite dataflow. The criterion separates the constructs.
THREE SMALLER ITEMS: §7.3's demand table row 3 column 3 does not reproduce because THE TABLE NEVER NAMES WHICH CHANNEL IS DEMANDED — with darwin→nixos, demanding `darwin` fires and demanding `nixos` does not; the load-bearing conclusion survives because rows 1-2 fire under every choice. The residual-refusal REASON over-generalises: true for the inject term, NOT true for the `concatMap … [c]` term, which dispatches to the same `raw` and would not rebuild §3.3. And a C9 GAP: register entry 1 names THREE parked consumers and the design addresses the collision and the value-shape predicates but NEVER MENTIONS `host.settings` rung 5+ (grep returns nothing; positive control `settings` = 2, both resolved-settings.nix in E11's reader list).

### 16 — 2026-07-28T15:56:29 · Jason Bowman

★ REMEDY 1 TAKEN AND EXTENDED. Core 269 → 314 lines, md5 fbf69ab8… → 2fca0ca41fce5753b16183e1eb7cd4d9. File 1343 → 1525 lines, md5 ecc99fa2f4707d75df10b15213f65bad. The header's printed anchor updated to the new pair, and the anchor held stable across a subsequent prose-only edit — itself a check that the recipe's boundaries are right.

★★ THE ADDITION MY LEAN DID NOT HAVE, AND IT IS LOAD-BEARING: THE ADDED ENDPOINTS MUST BE SORTED. Appending them in ACT ORDER makes `srcOrder` depend on the order of `Acts` — WHICH REINTRODUCES §6's 'four answers for one act set', THE EXACT FAILURE MODE THIS DESIGN EXISTS TO REMOVE. MEASURED on `[inject Y, inject X, Y→B, X→B]`: an act-order domain gives TWO answers across permutations ([cB,iY,iX] and [cB,iX,iY]); sorted gives ONE. Registered channels keep REGISTRY order, which is a semantics; unregistered channels have no registry, so NAME ORDER IS THE ONLY ORDER-FREE CHOICE.
⇒ REMEDY 1 WITHOUT THE SORT IS A DIFFERENT DEFECT, NOT A FIX. Following my lean literally would have traded silent content loss for permutation dependence — repairing the symptom by rebuilding the disease.

★ A SECOND, INDEPENDENT ARGUMENT FOR REMEDY 1 THAT WAS IN NEITHER MY BRIEF NOR THE GATE: THE NARROW DOMAIN MADE THE FRAME INTERNALLY INCONSISTENT. `cycles = filter (selfReachable { inherit edges; }) nodes` (gen-graph lib/global.nix:53-54) passes ONLY `edges` — so `nodes` bounds WHICH CHANNELS ARE TESTED, never the traversal. ⇒ E7's GUARD ALREADY SAW THROUGH UNREGISTERED CHANNELS WHILE E3's PREIMAGE DID NOT. Measured on `A→X→A`: both abort, but the narrow domain names only [A] while the widened one names [A,X]. ★ SO E7's OWN CLAIM TO 'NAME EVERY CHANNEL IN A CYCLE' WAS FALSE UNDER nodes=Ch AND IS TRUE UNDER REMEDY 1 — the fix repairs a latent falsehood the gate had not found.

REMEDY 2 REFUTED ON ITS PREMISE, not on preference: E7's 'aborting is the only total alternative to inventing one' holds BECAUSE A CYCLE HAS PROVABLY NO REST POSITION — no answer exists. AN UNREGISTERED INTERMEDIATE HAS ONE, and both oracles produce it, so the principle does not transfer. It would also be a REGRESSION rather than a consistency, since the target/source arms evaluate fine today. ★ AND THE ANSWER TO MY OWN QUESTION: it would NOT abort the shipped fixture — class-bucket-query.nix:63-74's endpoints are all in its own classNames at :16-21 — WHICH MAKES THE RESTRICTION INVISIBLE TO THE SUITE, and that argues against it rather than for it.

ALL FIVE ARMS MEASURED, answer domain still `genAttrs Ch`: TARGET and SOURCE unchanged from today; ★ INTERMEDIATE now SEQUENCE-IDENTICAL to today ([cB,cA]) where nodes=Ch lost cA entirely; intermediate-plus-inject set-equal in E4 order; cycle-via-X aborts naming both channels. Post-change validation: 11-shape battery agrees on all 11, the wrong-variant control disagrees on exactly empty/selfLoopOnly/twoSelfLoops and agrees on the other 8 — §8's stated signature — and the shipped chain row stays green byte-identically.

★★ THREE ERRORS IN MY BRIEF, AND THE FIRST IS THE ONE THAT MATTERS.
(1) I wrote 'the load-bearing conclusion survives — rows 1-2 fire under every choice.' FALSE FOR ROW 2. Measured: `cycles` fires on all three demands; `transpose` fires on nixos and home-manager and IS SILENT ON darwin; the then-arm fires on darwin ONLY. ★ ROWS 2 AND 3 ARE COMPLEMENTARY BY CONSTRUCTION — `pre` reads `frame.rev` only on the else arm and takes the then arm only otherwise, SO EXACTLY ONE CAN FIRE PER DEMANDED CHANNEL. NO SINGLE DEMAND FIRES ALL THREE POISONS, which means the published column 3 asserts something one demand cannot produce and its positive control is necessarily TWO demands. Columns 1 and 2 measured demand-INDEPENDENT, so the fix is asymmetric: the channel is now named per cell and the complementarity stated.
(2) I said unregistered TARGET and SOURCE were 'already enumerated and measured byte-identical'. ONLY TARGET WAS — SOURCE appears nowhere in the pre-edit file (grep 'unregistered' returns no source arm). ★ THE DOC GENERALISED FROM ONE ARM, NOT TWO, which makes the gate's 'stopped one hop short' finding worse than it looked. SOURCE measured fresh (byte-identical) and all five arms now enumerated.
(3) The acyclicity lesson is recorded in E7 (core) and O4' (§10), NOT §9.1 as I said — §9.1 was substrate reuse only. The pair table went there anyway as the right home for the generalised lesson, cross-referenced to E7/O4'.

FOUR CHANGES BEYOND MY LIST, ALL FLAGGED FOR MY CALL AND ALL APPROVED: the SORT (not optional, above); ★ §7.2's bound K² → K·(K+2R), because REMEDY 1 INVALIDATES K² — `pre` is answered at K channels over a domain of size ≤ K+2R — still polynomial, recovering K² exactly when every endpoint is registered, which is every corpus shape, and at R=0. I had listed the K² bound under DO-NOT-TOUCH; leaving it would have made the doc FALSE, and the agent was right to override me. §7.1's historical ≤K² kept as the record with a forward pointer. New obligation O9 for the unregistered-intermediate arm, carrying the PERMUTATION FALSIFIER that trips a future tidy-up dropping the sort. Header rewritten to 'the core moved TWICE' — short-circuit and domain, both outstanding against the same re-attestation.
§4.3 FIXED AND ITS HISTORY RECORDED: the header now reads 'the executable core already names the right blocker, and this paragraph used to say it did not', quotes what the comments actually read, and records under 'what happened, recorded rather than quietly fixed' that all three prior statements were false, that they contradicted the header, and that the paragraph was written against the PRE-RULING core and never re-read. ★ AND IT QUOTES RATHER THAN CITING BY CORE LINE NUMBER — the numbers moved 207→249 and 219→261 when E2 grew, which would have stranded the correction exactly as the original was stranded.

### 17 — 2026-07-28T16:59:48 · Jason Bowman

★★ SHIPPED — 222af84. Verified independently by the orchestrator: ci 1946/1946 EXIT=0, parity 71/71 EXIT=0, exit status captured directly. All four retired constructs confirmed gone with HEAD as the positive control (`applyInjectReroute`, `keyedBucketsOf`, `forceContentKeysAt`, `classSliceKeyedAt`: present at 6f472d3, zero in the worktree). `projectClass` UNTOUCHED — the single diff hit is a CONTEXT line; `grep -E '^[+-].*projectClass'` returns 0.

FIXTURES LANDED FIRST AND RED, AS RULED: new ci/tests/class-relocation.nix against the OLD core gave 5/13 EXIT=1 — the diamond answering [cD,cB,cA,cC] instead of [cD,cA,cB,cC], EIGHT distinct answers over 24 permutations, content stranded, ★ the self-relocation aborting with `dynamic attribute 'A' already defined` at class-modules.nix:161 AND CONFIRMED UNCATCHABLE BY tryEval, the cycle guard going quiet on an uninvolved demand, and the unregistered-source order-dependence giving 2 answers. After the core: 13/13 EXIT=0.
★ AND EACH WITNESS WAS PROVEN TO FAIL FOR ITS OWN REASON BY ABLATION — one property removed at a time, suite re-run, core restored and md5-verified: guard removed → 12/13, SOLE failure the cycle test, with the acyclic positive control still GREEN so it is not passing off another guard and an unconditional abort would not pass; `nodes = Ch` → 11/13, failures exactly the intermediate and unregistered-source arms while TARGET and SOURCE stayed green; sort dropped → 11/13, failures exactly the order-freedom pair while the intermediate arm stayed green. THREE FALSIFIERS, EACH ISOLATED.
★ AND THE AGENT CAUGHT ITS OWN FALSE GREEN: its first ablation asserted a stale anchor and NEVER WROTE THE FILE, so the run reported 13/13 — which was the UNABLATED core passing, not an ablation surviving. It disbelieved the result and re-ran properly. That is the untracked-file/false-green trap, self-caught.

★★ TWO KERNEL GUARDS FIRED ON THE SPEC'S OWN COMMENT TEXT — a finding about the 'core is the contract' model itself. `boundary.test-no-compat-tokens-in-core` flagged `class-modules.nix:compat` because E11's comment names 'the compat verbs' verbatim; `zero-machinery.test-no-machinery-tokens` flagged `builtins.genericClosure`, which E3 AND E7 both name. ⇒ THE FROZEN CORE'S COMMENT PROSE CANNOT BE TRANSCRIBED INTO THE KERNEL AS-IS. A spec may discuss constructs the kernel's lexical guards forbid it from NAMING. Reworded with substance kept; re-scan clean, positive control 6 hits in gen-graph's own traverse.nix.

MIGRATION — MY BRIEF WAS WRONG THREE WAYS. I named TWO non-mechanical forcing sites; there are THREE — the third is ci/tests/compat-nested-aspects.nix:39 (`cmOkAt`), used at :349/:366/:370, two of them typo-abort fleets. AND BOTH LINE NUMBERS I GAVE POINT AT COMMENT LINES, not the reads (materialized-class-ground's is :32, declared-classes' is :83). All three now force `content-key-totality`; the other 12 became a direct `class-seeds` read, with `hasBucket` and the two `builtins.length` sites left shape-only.
★ AND THE SPEC'S §9 MIGRATION PARAGRAPH MISSES TWO CONSUMERS ENTIRELY: ci/tests/_lib/projection-harness.nix:20 and ci/tests/projection-routes.nix:70 IMPORT class-modules.nix DIRECTLY with `{ inherit prelude resolve; }`, so the new `graph` argument breaks both. Each gained `graph = denHoag.internal.genGraph;`. A migration census that counts ATTRIBUTE READS misses DIRECT IMPORTERS.

COST — MEASURED, and BELOW the prediction. Workload contains none of this change's fixtures; positive control, a sentinel throw in the aspect content, was reached on BOTH trees so the workload really forces content rather than a spine. Marginal per node: +33.0 calls, +19.0 thunks — ★ EXACTLY CONSTANT across n 8→32 and n 32→64, so it is a per-node constant with no scaling term. Ratio ×1.025 calls / ×1.011 thunks against the design's predicted ×1.079 / ×1.066. ★ CAVEAT STATED RATHER THAN CLAIMED AWAY: the denominator is a node's WHOLE evaluation, so if the design divided by class-query cost alone the ratios are not comparable — THE ABSOLUTE DELTAS ARE THE DENOMINATOR-FREE NUMBER.
FOUR ADAPTATIONS, ALL REPORTED: `Acts n`/`Λ n` are NOTATION not bindings and were expanded per E8's own rule; three private renames for file idiom (`rho`→`relocationsOf`, `pre`→`preimageOf`, `raw`→`rawSeedsAt`) with `relOf`/`srcOrder`/`classSeedsAt`/`frameAt` verbatim; `contentsOf` untouched since E9 redefines what it calls; the bead key dropped from E1's comment per the no-temporal-comments rule, with Mokhov 2017 §4.3 and Arntzenius 2016 preserved verbatim.
★ ONE DEMANDED CONTROL IS UNRUNNABLE AND THE AGENT SAID SO: O1's positive control — run the reachability enumeration on `classSliceKeyedAt` and confirm it fails via `keyedBucketsOf` — CANNOT RUN, because both bindings are now deleted. The git-grep presence/absence table is the substitute. An honest 'this control died with its subject' rather than a fabricated pass.
CORRECTION TO den-hoag-4kh.12: its body says the diamond gives FOUR answers. Over all 24 permutations it is EIGHT — four was a four-permutation sample.

### 18 — 2026-07-29T01:22:17 · Jason Bowman

★★★ RE-TRIAGE 2026-07-29. THE HEADLINE QUESTION IS DECIDED IN THE TREE, AND THIS BEAD WAS STILL READING AS OPEN — which is exactly the failure mode that made the retiring-constructs register necessary. Retitled so a dispatch quoting it gets the current state rather than a settled question.

WHAT SHIPPED, verified at HEAD 6f30460 by two independent agents the same session. Commit 222af84 'class content is a query, not an accumulated map'. lib/attributes/class-modules.nix OPENS with the successor property verbatim: 'class content at a channel coordinate is a DEMAND-DRIVEN QUERY over that node's resolved aspects and its own resolution-stratum declarations, evaluated per (node, channel), WITH NO WHOLE-MAP TRANSFORM'. The query binding is class-seeds and its header reads 'THE QUERY. Per (node, channel). Total. Order-free in the act list.' The relocation relation P(n) is declared with the property that its answer is 'a function of the DECLARATION SET and not of the declaration ORDER', built from preimageOf over a TRANSPOSED relation — i.e. it took the gen-graph route rather than hand-rolling, which was den-hoag-4kh.43's demand.
RETIRED SYMBOLS, 0 hits each at HEAD, POSITIVE CONTROL classSliceOf -> 9 hits SAME RUN: keyedBucketsOf, classSliceKeyedBaseAt, applyInjectReroute.
COLLATERAL ALREADY CLOSED ON THIS EVIDENCE: den-hoag-4kh.12 (the reroute fold stranding content on a diamond) — 222af84's own message states the diamond 'gave eight distinct answers across its twenty-four permutations and stranded content in eight of them; the query gives one, and strands nothing'. ★ AND THAT CLOSE REQUIRED REMOVING A blocks EDGE THIS BEAD WAS CARRYING ONTO den-hoag-4kh.41, A LIVE P0 — a fixed P1 was gating real work through this bead.

WHAT IS ACTUALLY LEFT — two items, and they are unrelated to each other:
  (1) RESIDUE, mechanical: the binding classBucketsOf survives in lib/attributes/output-modules.nix, called inside graphAccessor.channelsOf. It is the last bucket-shaped thing in the class-content path. Decide whether it dissolves into the same query or is legitimately different, and say which.
  (2) ★ THE E10(b) OWNER FORK, UNRESOLVED AND NOT TO BE ADOPTED WITHOUT A RULING. reach elements carry NO SCOPE COORDINATE, so there is no way to say WHOSE Acts govern a reach-sourced aspect: the PROJECTING scope's, or the aspect's OWNING scope's. They differ exactly when an aspect reaches a node that DID NOT DECLARE IT. ★ SINCE 222af84 SHIPPED THE SURROUNDING QUERY, THE IMPLEMENTATION MAY HAVE DECIDED THIS SILENTLY — establish which reading is live in the tree BEFORE putting the fork to the owner, because the honest question is now 'is the shipped reading the right one' rather than 'which should we pick'. A second behaviour delta rides along and was recorded when the fork was first raised: exempt narrows from reach-sourced to own-node, turning a meta.__forward typo into an abort where content materializes today.

DEN-HOAG-4kh.41 (P0) IS STILL LIVE AND ITS BODY IS NOW MISLEADING — flagged here because that bead depends on this one's territory. The defect HOLDS: terminalModulesAt = id: class: projectClass id class reads classSliceOf over reach directly and never consults class-seeds, so declare.inject/declare.reroute still do not reach the built system. BUT ITS NAMED MECHANISM applyInjectReroute NO LONGER EXISTS, so the next reader greps for a symbol that is absent and concludes FIXED. Anchor by expression instead: terminalModulesAt = id: class: projectClass id class and projectClass = in lib/attributes/output-modules.nix; the relocation consumer is now the class-seeds query in lib/attributes/class-modules.nix, bindings relocationsOf / frameAt / preimageOf.

### 19 — 2026-07-29T01:57:28 · Jason Bowman

★★★ E10(b) IS DISSOLVED, NOT DECIDED — **NEITHER READING IS LIVE.** The fork presupposed a choice the shipped query does not make. Measured at 4b61112 by an independent read-only verifier; 222af84 is an ancestor and 'git log 222af84..HEAD' over the three relevant files is EMPTY, so the shipped query is verbatim in the tree. NO OWNER RULING IS OWED. Do not re-raise it as a fork.

1. THE reach ELEMENT CARRIES NO SCOPE COORDINATE. Constructing expression, resolved-aspects.nix forwardExpand's emit:
     emit = aspect: concrete: { key = keyOf aspect; content = concrete; sharedFoldKey = sharedFoldKeyOf aspect ctx (keyOf aspect); };
   The file's own comment names it: 'the node is { key; content } (bare, no provenance marker)'. sharedFoldKey is NOT a coordinate — ctxProjOf yields "" for a static aspect, null for one reading a non-entity ctx key, otherwise f=<id_hash> over DECLARED ENTITY FORMALS ONLY. It discriminates instances that should collapse; it cannot answer 'which scope owns this'.
   ★ POSITIVE CONTROL, same file same predicate: reachEdgesOf builds { inherit (a) target; classFilter = ...; } and target IS a node id — so records here DO carry ids when intended. STRONGER STILL: at BOTH reach-node construction sites the scope id IS IN LEXICAL SCOPE AND DISCARDED — structuralNodesRaw = prelude.concatMap (nid: self.get nid "resolved-aspects") subtreeIds, and project = edge: builtins.filter ... (self.get edge.target "resolved-aspects"). The zero is about the data, not the predicate.

2. THE DECIDING EXPRESSION. output-modules.nix:
     projectClass = id: class: let reach = result.get id "reach"; exempt = forwardSourceClassesOf reach; in
       prelude.concatMap (n: builtins.seq (assertKeysRegistered exempt n) (map (e: e.module) (classSliceOf exempt n class))) reach ++ routeRemapFor exempt id class ++ forwardModulesFor reach exempt class;
   classSliceOf is the RAW per-aspect extraction — it reads content.${class} DIRECTLY. ★ frameAt, srcOrder, preimageOf, relocationsOf and rawSeedsAt APPEAR NOWHERE IN projectClass's CALL GRAPH. PREDICATE POSITIVE CONTROL: grepping reroute|relocat|injects over the WHOLE of output-modules.nix returns ONLY PROSE, while the same grep over class-modules.nix hits the live filters.
   ⇒ AN ASPECT ARRIVING BY REACH HAS NO SCOPE'S RELOCATION APPLIED. NOT THE PROJECTING SCOPE'S, NOT THE OWNING SCOPE'S. reroute and inject each have EXACTLY ONE consumer in all of lib/, both inside class-seeds.compute, which is STRICTLY NODE-LOCAL: resolvedAspects = self.get id "resolved-aspects" (OWN aspects, not reach) and acts = (self.get id "declarations").actions.resolution.

3. ★ THE ASYMMETRY THAT PROVES OMISSION RATHER THAN POLICY: routeRemapFor exempt id class DOES read declarations at the PROJECTING scope (routesAt id -> deliveriesAt id -> (result.get id "declarations").actions.resolution). So ROUTE declarations take the projecting-scope reading, while reroute/inject take NEITHER. TWO SIBLING RELOCATION MECHANISMS, TWO DIFFERENT TREATMENTS, AND NO COMMENT RECONCILING THEM.

4. OMISSION, AND PARTLY INEXPRESSIBLE — evidence in ascending weight. No comment anywhere in the three files mentions relocation-under-reach. The emit site shows someone DID deliberate over what a reach node carries and added a dedup key marked 'ADDITIVE', not a coordinate. ★ AND THIS AUTHOR LEDGERS KNOWN GAPS LOUDLY AND BY NAME — output-modules.nix carries SIX: the producing-class over-report, the adaptArgs ceiling, the per-module-vs-combined-eval ledger, the priority-annotation collapse, 'THE RED WINDOW (INTENTIONAL — documented, not silent)', and the isolation-mark ceiling. THE ABSENCE OF A RELOCATION LEDGER AMONG SIX NAMED ONES READS AS NON-AWARENESS, NOT SILENT DECISION.
   ★★ AND THE TWO READINGS WERE NEVER SYMMETRICALLY AVAILABLE: OWNING-scope is INEXPRESSIBLE AT THE CURRENT TYPE — emit carries no owning scope id, so the query CANNOT ASK. PROJECTING-scope IS expressible (id is bound in projectClass, exactly as routeRemapFor uses it) and simply was not written. ⇒ ONE ARM IS A DEFECT, THE OTHER IS A TYPE-LEVEL IMPOSSIBILITY. That is not a fork; it is a missing coordinate plus an unwritten line.

5. THE exempt RIDER — VERIFIED, DIRECTION RIGHT, PHRASING CORRECTED. No single binding 'narrows'. There are TWO INDEPENDENT exempt computations at different scopes: output-modules.nix projectClass has exempt = forwardSourceClassesOf reach (WIDE), while class-modules.nix class-seeds.compute and content-key-totality.compute both have exempt = forwardSourceClassesOf resolvedAspects (NARROW, own node). Narrow aborts where wide materializes. Mechanism: classSliceOf gates on (exempt ? ${class}) || classifyKey ... == "class" ('exempt short-circuits BEFORE classifyKey'), and assertKeysRegistered filters !(exempt ? ${k}) before its WHNF force. A SECOND INDEPENDENT BITE ON THE SAME LEG: srcOrder can hand rawSeedsAt an UNREGISTERED channel, because preimageOf filters frame.rel.nodes and NOT classNames.
   HONEST LIMIT AS REPORTED: verified by reading the bindings; NO failing eval was constructed to witness the abort.

6. ★★ NO TEST — AND THE ANCHOR THAT SHOULD HAVE CAUGHT THIS IS VACUOUS ON EXACTLY THIS PREDICATE. comm -12 over 'grep -rl reroute ci/' and 'grep -rl reachEdge ci/' is EMPTY: no test file contains both, and no fixture declares a reroute at all. ci/tests/class-relocation.nix, the only relocation suite, drives class-seeds.compute directly against a synthetic self — it never builds a reach and never calls projectClass. POSITIVE CONTROL (a related behaviour that IS pinned): ci/tests/projection.nix pins projectClass id C == classSubtreeAt id C ++ <route remap delta>.
   ★★★ THAT ANCHOR IS THE INSTRUMENT THAT SHOULD HAVE CAUGHT THIS AND CANNOT: classSubtreeAt reads class-seeds, WITH RELOCATION APPLIED; projectClass does not. WITH ZERO REROUTES ANYWHERE IN THE CORPUS, BOTH SIDES AGREE TRIVIALLY. It is green on an input class that cannot distinguish them — the same vacuity family as den-hoag-gg8 and den-hoag-6jo, but on the projection anchor rather than a leaf test.

BOUNDED, AS REPORTED: the three terminal reads (contentIdsOf, deltaOf, hostModules) were verified to route through projectClass; it was NOT exhaustively traced whether the gen-edge fold output re-enters deltaOf by another route.

### 20 — 2026-08-02T00:13:55 · Jason Bowman

Sweep-S8 note 2026-08-02: this bead's residue is now MECHANIZED — xfail-core-probe.nix:984 testG3AnchorsRegisterResidue asserts sitesOf "classBucketsOf" == [ "lib/attributes/output-modules.nix" ], so the one-binding-one-reader acceptance is instrumented; any second reader or removal moves a shipped assertion. Status unchanged (the representation question stands); the acceptance check is no longer manual.
