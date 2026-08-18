# den-hoag-4kh.17 — RETIRING-CONSTRUCTS REGISTER — check before writing any design brief or spec

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.17` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T04:40:42Z by Jason Bowman |
| last updated | 2026-08-12T21:29:31Z |
| description bytes | 24458 |
| notes bytes | 0 |
| comments | 11 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★★ THE RETIRING-CONSTRUCTS REGISTER. READ THIS BEFORE WRITING ANY DESIGN BRIEF OR SPEC.

WHY IT EXISTS: a design was written, adversarially reviewed THREE TIMES and VALIDATED entirely in the
vocabulary of a construct that had been scoped for retirement four days earlier. The scope doc existed. The
memory existed. NOTHING IN THE GRAPH DID — so no process that reads the graph could surface it, and no
reviewer was told to ask. Gate check C9 catches this AT REVIEW; THIS REGISTER CATCHES IT AT DISPATCH, where
it costs nothing.

THE RULE: every design brief and every spec must be checked against this list. If the work TOUCHES, NAMES or
EXTENDS anything on it, the brief must say so and the spec must state which side of the retirement it lands
on. A local improvement inside a doomed shape gets written twice, and the second writing has to unpick the
vocabulary the first entrenched.

★★ THE VERIFICATION RULE, WHICH THIS REGISTER VIOLATED ON DAY ONE AND THREE TIMES SINCE. No entry may be
filed or trusted without verifying its sites AT HEAD IN THE SAME SESSION. An entry naming a file:line must
have had that line READ. A memory is a point-in-time observation; a scope doc is a snapshot of INTENT.
NEITHER IS EVIDENCE ABOUT HEAD. Every entry carries its site, the DATE it was last verified, and the command.
An entry without a verification date is a HYPOTHESIS.
★ CITE BY EXPRESSION OR BINDING NAME, NEVER BY LINE NUMBER. Line ranges here have decayed FOUR times and
been quoted confidently every time — including once by a "correction" that replaced a wrong range with a
different wrong range, which is worse than the original error because it carried the authority of a
verification. A line range is the wrong way to cite a list living inside a function body that keeps growing.
★ AND AN ENTRY CITING A TRACKER MUST RECORD THE TRACKER'S TITLE AND STATUS AT VERIFICATION TIME, not just
its id. "Already tracked as X" is a CLAIM, not a citation. A CLOSED BEAD NAMED AS A TRACKER SILENTLY
CONVERTS LIVE WORK INTO FINISHED WORK — that exact chain has already happened here TWICE (the second time on
this register's own entry 5, whose tracker closed while the entry read "OPEN at P0").
★★ THE THREE DECAY MODES THIS REGISTER HAS ACTUALLY EXHIBITED (census 2026-07-29, 72 anchors: 41 live, 13
drifted, 18 dead — binding-name and verbatim-header anchors survived 113 commits with ZERO decay; everything
dead died another way):
· ANCHORS DIE BY BEING FIXED. A register of retirements has no natural invalidation for a retirement that
  COMPLETES, so a shipped entry reads identically to a live one. ⇒ When a migration ships, the entry's
  STATUS line changes IN THE BODY in the same session the ship is verified.
· TRACKER STATUS DRIFTS SILENTLY, IN BOTH DIRECTIONS (closed under a live entry; retitled to resolved under
  an "undecided" one). ⇒ Every citation of an entry re-verifies its tracker's status+title; a stale one is
  corrected in the body, not in a comment.
· CORRECTIONS THAT LAND AS COMMENTS DO NOT REACH A DISPATCH. When an entry is corrected, THE BODY MUST BE
  EDITED, not annotated — a comment is a supplement for a reader who reaches it; the body is what a dispatch
  quotes. (Stated twice in comments; violated by entry 3 for a day — two owner-refuted claims sat verbatim
  in the body after their refutations were recorded.)
★ AN ENTRY MAY STATE WHAT A CONSTRUCT IS AND WHY IT RETIRES. IT MAY NOT STATE WHAT RETIRING IT WOULD ACHIEVE
ELSEWHERE. Every such cross-entry claim in this register so far has been false (entry 3, both).

════ ACTIVE RETIREMENTS ════

1. ★ PER-CLASS CONTENT BUCKETS → DIRECT GEN-EDGE GRAPH QUERIES.
   STATUS: **SUBSTANTIALLY RETIRED IN FACT — SHIPPED AT 222af84.** Re-verified at HEAD d33ce02 on 2026-07-29
   (third independent pass; all four verbatim anchors LIVE). lib/attributes/class-modules.nix OPENS with the
   successor property, verbatim: "class content at a channel coordinate is a DEMAND-DRIVEN QUERY over that
   node's resolved aspects and its own resolution-stratum declarations, evaluated per (node, channel), with
   no whole-map transform", and declares inject/reroute the relocation relation Ρ(n) whose answer is "a
   function of the DECLARATION SET and not of the declaration ORDER". The query binding is `class-seeds`;
   its header reads "THE QUERY. Per (node, channel). Total. Order-free in the act list."
   RETIRED SYMBOLS: `keyedBucketsOf`, `classSliceKeyedBaseAt`, `applyInjectReroute`. Re-measured at HEAD
   b0f40de on 2026-07-30 with `git grep` (tracked files, worktree-proof): each 0 in lib/ AND 0 in ci/;
   positive control SAME RUN `classSliceOf` → 40 over 13 files (was 38 at d33ce02).
   ★ CONTROL RE-POINTED 2026-08-01 at d0e9d4b (unpark-gate finding F-C, verified by command same session):
   `classSliceOf` is ITSELF RETIRED IN CODE — renamed to the un-exported `rawSliceOf` by the unification
   §4.3 landing — so it now answers 0 in lib/ AND 0 in ci/ and survives repo-wide only in
   `.beads/beads.jsonl`: the self-inflicted decay mode this entry itself documents, now on its own
   control. A future re-verification using it gets a zero control (law 39 invalidates the run) while a
   repo-wide grep reads it alive. USE `classSliceAt` AS THE POSITIVE CONTROL: 19 in lib/attributes/ at
   d0e9d4b, command `git grep classSliceAt d0e9d4b -- lib/attributes/ | wc -l`.
   ★★ SCOPE THE CHECK TO lib/ AND ci/ — A REPO-WIDE GREP READS ALL THREE AS LIVE AND WILL "CORRECT" THIS
   ENTRY WRONGLY. Measured at b0f40de: repo-wide those symbols show 6 / 7 / 8 hits, ALL of them inside
   `.beads/beads.jsonl` — the tracker's own export quoting these very sentences. This is a NEW decay mode for
   this register and it is self-inflicted: an entry that names a retired symbol guarantees future grep hits on
   that symbol, so the more carefully a retirement is recorded the more convincingly it re-appears alive.
   ★ RESIDUE, and it is ALL that remains of this entry: the binding `classBucketsOf` in
   lib/attributes/output-modules.nix, read at exactly ONE site in lib/ — `graphAccessor.channelsOf`. A brief
   touching class content should say which side of THAT binding it lands on; it need not re-litigate the rest.
   ★ AND IT IS NO LONGER A CONTENT BUCKET — do not let the name mislead a brief. Its body at HEAD is
   `if cn == null then [ ] else builtins.seq (classSubtreeAt id cn) [ cn ]`: it returns a channel-NAME list,
   forcing `classSubtreeAt` only for a classification side effect. A reader expecting an accumulated content
   map will not find one, and "the residue of the per-class CONTENT bucket" overstates what is left.
   TRACKER: den-hoag-4kh.16 "[kernel] RESIDUE of the bucket retirement: one binding classBucketsOf and its
   single reader channelsOf — the scope-coordinate half is REFUTED at HEAD (scope = scopeId landed 1905f1c),
   original acceptance otherwise DISCHARGED", OPEN at P2, title and status verified 2026-07-30.
   ★ THE TITLE CHANGED ON 2026-07-30 and the change is substantive, not cosmetic: the entry's other half —
   the reach-element MISSING SCOPE COORDINATE — is not merely dissolved but REFUTED. The 2026-07-29 claim
   "OWNING-scope is INEXPRESSIBLE AT THE CURRENT TYPE" is false at HEAD; lib/attributes/resolved-aspects.nix
   `emit` returns `{ key; content; sharedFoldKey; scope = scopeId; }`, landed at 1905f1c for an unrelated
   reason, and output-modules.nix already reads it as `scope = n.scope or id`. That refutation unblocked a
   live P0 (den-hoag-4kh.41) that had been gated on the impossibility. NO E10(b) OWNER FORK REMAINS.

2. VALUE-SHAPE PREDICATES `looksLikeClassContent` / `isNestedKey` — **WITHDRAWN. ALREADY RETIRED.**
   Re-confirmed at HEAD d33ce02: both names appear ONLY in comments — lib/compat/compile.nix twice, and
   lib/module-shape.nix once. ★ THE THIRD SITE IS A KERNEL FILE, NOT A COMPAT ONE (there is no
   lib/compat/module-shape.nix; earlier versions of this entry said there was — positive control: `ls
   lib/module-shape.nix` → 1714 bytes, `ls lib/compat/module-shape.nix` → no such file). The residue is
   comment-only but it is NOT confined to compat. No live predicate anywhere.
   `classifyKey` dispatches on a DECLARED category (`aspectSchema.keyCategory`), not on value shape — solved
   by the gen-schema key-semantics + gen-aspects generic-dispatch route ("Shape B", owner-ruled 2026-07-15),
   NOT by bucket retirement. Kept in the register as a WITHDRAWN entry on purpose: three agents independently
   re-derived this withdrawal because the body once contradicted its own correction comment.
   ★★ SCOPE CORRECTION 2026-08-02 at 9311fbd (found by the 6s7k spike's register READ — the exact
   no-shared-vocabulary shape this register's own read-don't-sweep section warns about): the two NAMED
   predicates stay retired, but this entry MUST NOT be read as "value-shape dispatch is retired as a
   class". A live kernel instance exists sharing no vocabulary with either name: `isConfigThunk` in
   lib/attributes/collections.nix (bindings `configArgNames` / `demandsConfigArg` / `isConfigThunk`)
   decides what a channel element IS by sniffing `builtins.functionArgs` (and the wrapped
   `__functionArgs` form) against `[ "config" "osConfig" ]` — §4 criterion 3 in nine lines, and the
   classification ambiguity is TOTAL for HM modules (every HM module takes `config`). Verified by
   orchestrator read same session. TRACKER: den-hoag-aw1s "[kernel] isConfigThunk decides what a channel
   element IS from the function's FORMAL NAMES …", OPEN at P1, filed 2026-08-02. Remedy is OWNER-GATED
   through den-hoag-6s7k's F2 fork (declared face — the Shape B direction this entry already records);
   a brief touching channel-element classification says which side of that fork it lands on.

3. THE 2-STAGE SCHEDULE AT THE CALLER. **HALF RETIRED at 71c11b2 (2026-07-30): the CLASSIFICATION half is
   GONE — the pre-pass universe is schema-minted (allKinds), nonCandidateKinds deleted, the false §3b
   citation replaced. THE SCHEDULE HALF IS LIVE: the two-phase mint remains for edge 6b (attachments → node
   identity, the gen-scope scalar-parent obstruction), and the exclude/deliver FIRING semantics retire with
   the validated design's U2, unlanded.** Verified 2026-07-30 by the u2.h gate: old anchors DEAD at HEAD
   ("THE STAGING THAT BREAKS THE CYCLE" 0 hits; `scopeRoots = prePassScopeRoots;` 0; `prePassScopeRoots`
   survives only in lib/compat/parity/ledger.md — controls same run: `structuralNodes` 13, "THE STRUCTURAL
   UNIVERSE" 1).
   LIVE ANCHORS, by expression: `structuralNodes = buildRoots { ... roots = allKinds; }` and its consumption
   in runPrePass; `baseScopeRoots = buildRoots { ... attachments = prePass.containmentAttachments; }` — the
   E2 residual the validated spec records with the cycle NAMED and the reason laziness cannot break it
   (self.get presupposes the key exists; demand defers values, never the key population).
   ★ A BRIEF CITING THIS ENTRY MUST SAY WHICH HALF IT MEANS.
   WHY IT RETIRES: a staged pre-pass whose ordering exists to break a dependency cycle is the shape the HOAG
   model replaces with DEMAND-DRIVEN ATTRIBUTES, and the kernel already owns that idiom throughout
   lib/attributes/ (resolve.attr / self.get).
   ★ WHAT THIS ENTRY MAY NOT SAY, because both claims were written here and both were refuted the same day
   (the refutations now live in the body per the correction rule; comments 019fabd0 and 019faba7 hold the
   full derivations):
   · "entry 5 dissolves entry 3" — REFUTED. Containment edges are not membership edges;
     `baseScopeRoots = buildRoots { ... attachments = prePass.containmentAttachments; }` and edge endpoints
     are node ids, so edges must be built AFTER minting. Making containment an edge INHERITS the ordering.
   · the CI-baseline consequence — WITHDRAWN as a false inference. The twelve compose-commitment aborts are
     COLLECTION stratum; both pre-pass feeds require `r.group == "structural"`. This retirement has NO KNOWN
     CI CONSEQUENCE for them; what would make them green is den-hoag-4kh.53.64.
   MEASURED COST (absent when the entry was written): the pre-pass fires every root TWICE under an explicit
   DOUBLE-FIRE DISCIPLINE — den-hoag-qxz. Any budget calibrated today is wrong the day this retires.
   TRACKER: den-hoag-4kh.18 "the 2-stage schedule ... is a live effect-runtime holdover", **CLOSED
   2026-07-30 at 58160d4, arch-validated** — the retirement is COMPLETE at its acceptance (classification
   half deleted, firing semantics per-minted-locus, the edge-6b schedule residual recorded in-tree with the
   cycle named). This entry's LIVE half is now ONLY that recorded residual; work touching it cites the
   in-tree residual record, not a live retirement arc. ★ ANCHOR CORRECTION 2026-07-31 at 2e44ff5: the
   citation handle "u5.header" is DEAD — `git grep "u5.header" -- lib/ ci/` → 0 (control `u5` → 3 files,
   none a header record). Cite the residual by its LIVE expressions instead: `structuralNodes = buildRoots {`
   and `baseScopeRoots = buildRoots {` (both in lib/default.nix, 2 hits same run) — the same anchors this
   entry's LIVE ANCHORS line already carries. Verified 2026-07-30 (second pass — this line
   decayed once already the same day, the register's decay mode #2, both times under the same orchestrator's
   ship sessions). ★ NOT den-hoag-9xo.10 — that is a DIFFERENT bug ("TOPOLOGY: parent-chain kinds are
   membership-INDEPENDENT flat roots") and it is CLOSED. An earlier version of this entry cited it, which is
   how a live construct nearly became finished work. Related: den-hoag-4kh.51 (suppression-path soundness
   rests on this staging), OPEN P1; den-hoag-9uv (CI three-state), OPEN P0.

4. `__`-PREFIXED STATE CARRIERS IN THE KERNEL. **PARTLY RETIRED — THE COORDINATE HALF SHIPPED between
   6f30460 and d33ce02.** Verified at HEAD d33ce02 on 2026-07-29.
   v1's double-underscore keys hacked the nix-effects state accumulator; ONLY the compat boundary may read
   that surface (positive control: `__provider` → 0 in kernel, 18 in lib/compat/ — the predicate CAN match,
   the kernel really is clean of that one).
   THE KERNEL WRITES SEVEN `__` KEYS OF ITS OWN: `__entry`, `__root`, `__policy`, `__action`,
   `__den-demands`, `__terminal`, `__missing` (lib/coordinates.nix `missing = dm: { __missing = dm; };`),
   plus a `__spawn` name-mangled SUFFIX used as a namespace. `__coords` AND `__containment` ARE GONE —
   0 kernel assignments (predicate `grep -rn "__coords =" lib/ | grep -v '^lib/compat/'`; positive control
   same shape same run: `__root =` and `__terminal =` both hit). lib/fleet.nix carries the tombstone: "This
   mint used to write two ... They are deleted in the commit that points the reads at the pool."
   27 distinct `__` names appear in the kernel. Gen-owned and legitimate from the prior census:
   `__isWrappedFn`/`__functionArgs`/`__fn` (gen-aspects), `__sel` (gen-select),
   `__configThunk`/`__sourceScope` (gen-bind), `__edges` (gen-scope), `__derive`/`__derived` (gen-pipe).
   ★ EIGHT names first seen in the 2026-07-29 census are UNCLASSIFIED — ownership pass owed:
   `__contentless`, `__dropped`, `__firesAtKinds`, `__forward`, `__key`, `__pipeMark`, `__pipeTargeted`,
   `__ud`. Do not cite "the rest are gen-owned" until that pass runs.
   ★ TWO HAND-MAINTAINED STRIP LISTS REMAIN (were four), cited by binding name:
     lib/staged-resolution.nix      `baseCtxOf = id: removeAttrs scopeRoots.${id}.decls [ "__edges" ]`
     lib/attributes/structural.nix  `inherited-context`'s
                                    `extract = node: removeAttrs (node.decls or { }) [ "__edges" "suppressedPolicies" ]`
   Both are single-line now. The resolved-settings.nix and collections.nix lists are DELETED (collections.nix
   carries the tombstone: "It replaces a `removeAttrs decls [ ... ]` negative enumeration whose key set was
   open"). Both `coordDims` bindings and their "graph machinery, never producing-scope coordinates" comment
   are DELETED — `coordDims` survives only in ci/tests fixtures and tombstone comments. The `__entry`-split
   analysis and the four-way-drift reading no longer have referents.
   ★ THIS IS EXACTLY WHAT THIS ENTRY PREDICTED — "they shrink to two keys — `__edges` (gen-scope's own,
   never den-hoag's to remove) and `suppressedPolicies` (a typed control fact on its own `inheritSet`
   carrier). THEY DO NOT DISAPPEAR." — the only forward-looking claim this register has got right.
   ★ THE LESSON THAT GENERALISES, kept from the retired analysis: A SET DIFFERENCE IS NOT A DEFECT UNTIL YOU
   HAVE READ WHAT EACH SITE IS FOR. "These lists disagree" is a shape observation; "these lists were meant
   to agree" is the claim that makes it a defect, and it was never checked.
   ★ INSTRUMENT WARNING, now a GENERAL trap rather than a description of these two sites (both are
   single-line today, so a single-line grep fails for the correct reason): `grep A | grep B` is a single-line
   conjunction; Nix attrsets, lists and arg-lists are multi-line. Use `-A N` or read the range.

5. GRAPH FACTS CARRIED AS NODE PAYLOAD → REAL EDGES. **HALF SHIPPED at HEAD d33ce02, verified 2026-07-29.**
   `__coords` and `__containment` HAVE MIGRATED — position is now a query over the `contains` pool
   (lib/coordinates.nix). THE TELL IS GONE: `coordsOfNode` → 0 repo-wide, positive control same predicate
   same run: `coordDims` → 10, `__coords` → 9 (comments/fixtures). lib/fleet.nix quotes the exact retired
   expression in its tombstone.
   WHAT REMAINS PAYLOAD: `__entry` (the node's registry entry) and `__root` (a constructor tag).
   ★ CONSTRAINT A BRIEF MUST RESPECT, STILL BINDING: lib/scope-adapter.nix states gen-select's adapter reads
   `decls.__entry`, so that shape may be externally pinned even though the NAME is a v1 echo. lib/fleet.nix
   §6.4 records the corrected grounds on which `__entry` STAYS. Establish this before proposing to move it.
   ★ LIVENESS WITNESS 2026-07-31 at 6dc4d44 (den-hoag-rb0, OPEN P1 at filing): the payload carrier FAILS OPEN — den.systemViews (lazyAttrsOf raw) folds decls-winning onto system-bearing roots, so `systemViews.<sys>.__entry = null` silently nulls a minted identity; sel.kind answers false with no abort (adapter default entryFor is or-written and Nix `or` swallows selection on null), and an entry-less cell-family parent kills the fleet with an unattributed type error. Strongest argument yet FOR this migration; a brief touching __entry cites rb0.
   RELATED AND IN THE SAME RETIREMENT: `__policy` stamps PROVENANCE into the value (a source-attribution edge
   written as a field). `__action` is THE TYPE TAG OF A SUM TYPE re-dispatched at NINE tag-filter sites
   across five files (class-modules ×2, output-modules, resolved-settings, resolved-aspects ×4, default) —
   each a linear scan where a labelled edge set would be an index. ★ PRECISION CORRECTION, verified by
   command 2026-07-31 at 2e44ff5: only EIGHT of the nine are the exact spelling `a.__action == "..."`
   (grep `__action ==` → 9 lines / 5 files, one a COMMENT at declarations.nix:32 ⇒ 8 live / 4 files, and
   output-modules has ZERO exact hits); the output-modules site is spelled
   `(a.__action or null) == "delivery" && !(a.__dropped or false)` (deliveriesAt) — same dispatch pattern,
   different predicate spelling. ⇒ A GREP FOR THE EXACT FORM UNDERCOUNTS THE PATTERN BY ONE; a census of
   this entry must use the semantic site list above, not the literal predicate. Control same run:
   `__action ==` in resolved-aspects → 4. ★ ITS TAG SET *IS* ENUMERATED, at lib/declarations.nix `groups` (17 kinds in 4 strata:
   structural/resolution/collection/demand) feeding `dispatch.mkActions groups` — the earlier "enumerated
   nowhere" claim was wrong. `__den-demands` is a reserved channel identified by PREFIX MATCHING
   (`isReserved = ch: prelude.hasPrefix "__" ch`).
   ★★ TRACKER: den-hoag-5ae IS **CLOSED**, retitled "THE TOPOLOGY AS IT IS: TWO EDGE MODELS (delivery vs
   adjacency) and seven disjoint pools — the live query substrate is Model-Q and six framework structural
   kinds have NO producer". THIS ENTRY HAS NO OPEN TRACKER; verified 2026-07-29. Related: den-hoag-5bp,
   ★ NOW **CLOSED** (status corrected 2026-08-02 — this line previously read "OPEN P1" after 5bp closed on
   2026-08-01's closure sweep: decay mode #2 firing ON THIS REGISTER'S OWN ENTRY, caught by a gate round's
   independent tracker re-check). 5bp closed as "QUESTION ANSWERED, SALVAGE DISPOSED" — the dead-or-
   scaffolding question answered DEAD on the Model-D-vs-Model-Q finding; its recorded verdict stands:
   "RESOLVED-DEAD: lib/edges.nix's assembleEdges/nestProducer are a DELIVERY-model construct that erases
   the tail and hashes the head — cannot carry the topology migration; 3 salvage items named". assembleEdges/nestProducer are exported at lib/default.nix on the internal suite
   surface plus 24 ci/tests references, so "unreached" means NO PRODUCTION CALLER, not no reference.

════ HOW TO USE IT ════
· WRITING A BRIEF: name any hit and say what you want the design to do about it. Do not leave it for the gate.
· WRITING A SPEC: cite the tracker bead WITH ITS TITLE AND STATUS, and state whether your THEORY survives the
  retirement, whether your MECHANISM does, AND WHETHER YOUR ARGUMENT DOES — ★ THESE ARE THREE INDEPENDENT
  ANSWERS. On den-hoag-4kh.11 theory and mechanism both survived and the mechanism IMPROVED under the
  retirement — a favourable answer that went unrecorded because nobody asked. On design 2 theory and
  mechanism survived and THE ARGUMENT DID NOT: its precedent, its recommended candidate's title and its
  central asymmetry all rested on two guards that retire with the pre-pass. A design can be fully sound while
  its justification evaporates with the construct it borrowed its precedent from.
· REVIEWING: C9 on den-hoag-4kh.6 (and its S0 selection precondition — an artefact must name the measured
  defect or directive that dispatched it, or the gate bounces it unreviewed).
· ADDING: the moment a retirement is SCOPED, not when work starts.

════ ★★ READ IT, DO NOT SWEEP IT — TWICE-VALIDATED ════
BOTH C9 hits found in this arc were INVISIBLE TO ANY TEXT SEARCH OF THE DESIGN:
· one lived ONLY IN THE ERROR-MESSAGE TEXT of two guards the design named as its precedent — lib/errors.nix
  read "the STAGED PRE-PASS's exclude-family feed", and THE GUARDS EXIST BECAUSE THE RETIRING CONSTRUCT
  FAILS, so extending them extends it. A grep of that spec for 4kh|retir|register|prePass|staging|
  demand-driven returned two false hits and nothing real; positive control at the time: `producesByName` → 3.
  ★ HISTORICAL AS OF d33ce02: the phrase is 0 hits repo-wide because THE TWO GUARDS THEMSELVES RETIRED —
  lib/errors.nix now reads "The resolve-family and exclude-family UNTAGGED guards are RETIRED." The example
  still teaches the shape; it can no longer be re-run. (`producesByName` at HEAD → 16.)
· the other was THREE HOPS UP AN INHERITANCE CHAIN, through a binding sharing no name with its source.
⇒ A DESIGN IS WRITTEN IN ITS OWN VOCABULARY, SO THE VOCABULARY IS EXACTLY WHERE THE LINK WILL NOT BE. Any
dispatch citing this register MUST say "do not word-sweep — read each item and reason about what this design
touches" AND carry a worked example of a hit a grep would have missed. A reviewer told only to "check against
the register" will grep it, report clean, and be wrong for a STRUCTURAL reason rather than a careless one.

════ THE FAILURE THIS PREVENTS, stated plainly so it is not softened later ════
CRITERION 1 ASKS WHETHER A DESIGN *USES* STATE ACCUMULATION. IT DOES NOT ASK WHETHER IT *BUILDS ON* ONE
ALREADY MARKED FOR DELETION. A design can dissolve an accumulator's FOLD — genuinely, measurably, passing
every check green — while keeping the DATA STRUCTURE the fold operated on. That is what happened, and every
instrument read clean because none of them asked.


★ NAME COLLISION, banked from the bootstrap 2026-08-12 (`den-hoag-qrsx`, spec R§5 row 16). TWO beads
self-describe as "THE REGISTER". THIS one is the FROZEN den-hoag track's retiring-constructs
register — the enumerable domain of the 4kh.6 rubric's C9 check, deferred with the rest of that
track under ADR-0002. The other is `den-hoag-rlsm`, the LIVE systems register for the gen-first
consolidation arc. **A gate reviewing a gen-arc artefact wants `rlsm` plus the ADRs, not this bead.**


## Comments (11)

### 1 — 2026-07-28T04:46:34 · Jason Bowman

★★★ REGISTER CORRECTION + A HARD RULE THE REGISTER ITSELF VIOLATED ON DAY ONE.

ENTRY 2 (value-shape predicates `looksLikeClassContent` / `isNestedKey`) IS WITHDRAWN — THE PREDICATES ARE
ALREADY RETIRED. Verified at HEAD: compile.nix:251 reads "The FORMER `looksLikeClassContent`" (past tense);
compile.nix:218 is a comment citing v1's key-classification.nix:69-80, pin 11866c16; module-shape.nix:6 names
the retired guard in a comment. NO LIVE PREDICATE EXISTS. The register listed them as active on the strength
of a 2026-07-24 memory, in an entry written 2026-07-28, WITHOUT READING THE CITED LINES.

ENTRY 1 (per-class buckets) IS NARROWED, not withdrawn. Its "parked on it" clause was FALSE: the
aspect-name ⟂ class-name collision and both value-shape predicates were NOT parked on bucket retirement —
they were solved by a DIFFERENT ROUTE, gen-schema key-semantics + gen-aspects generic dispatch (the "Shape B"
arc, owner-ruled 2026-07-15, SHIPPED). classifyKey now dispatches on a DECLARED category
(concern-aspects.nix:103-113, `aspectSchema.keyCategory`), not on value shape. What remains is the narrower
REPRESENTATION question — should class content be a gen-edge query rather than a per-class accumulated
bucket — with no collision class hanging off it. See den-hoag-4kh.16 for the full correction.

ENTRIES 3 AND 4 ARE UNVERIFIED AND MUST BE TREATED AS SUSPECT UNTIL CHECKED AT HEAD. Entry 3 (the 2-stage
schedule at default.nix:1074-1086) carries a note that its own tracker's line range has already drifted —
which is itself a warning. Entry 4 (`__`-prefixed state carriers) cites fleet.nix:117-127 from a W2 audit
this session, so it is fresher, but it has not been re-read since.

════ ★ THE RULE, and it is the whole point of the register ════
NO ENTRY MAY BE FILED OR TRUSTED WITHOUT VERIFYING ITS SITES AT HEAD IN THE SAME SESSION. An entry naming a
file:line must have had that line READ. A memory is a point-in-time observation; a scope doc is a snapshot of
INTENT. NEITHER IS EVIDENCE ABOUT HEAD.
Every entry must now carry: the site, the DATE IT WAS LAST VERIFIED, and by what command. An entry without a
verification date is a HYPOTHESIS, not a register item, and a brief that hits one must verify before relying
on it.

════ WHY THIS MATTERS MORE THAN THE INDIVIDUAL ERROR ════
The register was created to stop a design being written against a stale picture. IT WAS ITSELF WRITTEN
AGAINST A STALE PICTURE, WITHIN THE HOUR, BY THE PERSON WHO HAD JUST DIAGNOSED THAT EXACT FAILURE. The
verification cost four commands once someone asked for it.
⇒ A REGISTER OF RETIREMENTS IS A CACHE, AND A CACHE WITHOUT AN INVALIDATION RULE IS A LIABILITY — it converts
a stale belief into an authoritative-looking instruction that future briefs are told to obey. The rule above
is the invalidation rule.

★ AND THE BROADER AUDIT THIS IMPLIES, recorded so it is not lost: the same failure mode is suspected across
the beads registered from the papers-repo sweep — work filed as open that has since shipped, and work missed
because the sweep read specs rather than the tree. THE SPECS DESCRIBE INTENT AT THEIR DATE; THE TREE IS THE
ONLY EVIDENCE ABOUT NOW. Any bead whose body rests on a spec or memory rather than on a verified site should
be re-checked against HEAD before it drives work.


### 2 — 2026-07-28T04:48:56 · Jason Bowman

★ REGISTER ENTRY 3 CORRECTED — the construct is LIVE, the tracker named was WRONG.

Entry 3 cited den-hoag-9xo.10 as the tracker for the 2-stage schedule at lib/default.nix:1074-1086.
VERIFIED AT HEAD (a40cc96):
· THE CONSTRUCT IS LIVE. lib/default.nix:1074 carries "THE STAGING THAT BREAKS THE CYCLE (design note §3b)"
  verbatim; prePassScopeRoots is built at :1083 and consumed at :1098. Confirmed by reading, not by memory.
· den-hoag-9xo.10 IS A DIFFERENT BUG AND IT IS CLOSED — "TOPOLOGY: parent-chain kinds are
  membership-INDEPENDENT flat roots", closed with "RESOLVED by the node-multiplication arc,
  84fc117..fc29920".
⇒ NOW TRACKED AT den-hoag-4kh.18, filed with the site verified at HEAD.

★ THE LESSON, and it belongs in this register because it is how a live construct becomes invisible:
"ALREADY TRACKED AS X" IS A CLAIM, NOT A CITATION. It must be checked like any other — read the bead, confirm
it is THE SAME CONSTRUCT, confirm it is OPEN. Here the chain was: an audit recorded the holdover as tracked
by a bead that was a different bug; that bead then CLOSED; the holdover became finished work without anyone
deciding it was. An orchestrator then carried the same false citation into this register without checking.
A CLOSED BEAD NAMED AS A TRACKER SILENTLY CONVERTS LIVE WORK INTO FINISHED WORK.
⇒ ADD TO THE VERIFICATION RULE: an entry citing a tracker must record the tracker's TITLE and STATUS at
verification time, not just its id. An id alone cannot be checked without a lookup nobody performs.


### 3 — 2026-07-28T05:04:35 · Jason Bowman

★ CORRECTION TO ITEM 4's SITE REFERENCE — the register's own drift hazard firing a second time, on the
register itself.

I relayed item 4's strip-list site to a reviewer as `attributes/structural.nix:42-66` with the list
`[ "__edges" "__containment" "__coords" "__root" "suppressedPolicies" ]`. VERIFIED WRONG AT HEAD by r2-regate.

CORRECT SITES — the four hand-maintained strip lists this entry scopes:
  lib/staged-resolution.nix:171-176        <- THE ["__edges" "__containment" "__coords" "__root"] LIST
  lib/attributes/structural.nix:61-62      <- structural's own list; :42-66 is inherited-context's OPENING, not its list
  lib/attributes/resolved-settings.nix:48-49
  lib/attributes/collections.nix:75-76
Carriers: lib/fleet.nix:117 (__coords), :125 (__containment).

This is the exact failure the entry itself warns about: a memory or comment naming a file:line is a
HYPOTHESIS. It cost nothing here because the reviewer re-derived rather than inheriting, which is why briefs
state their facts as REFUTABLE. Third such drift this arc; every one caught by an agent re-running a claim.

★ INSTRUMENT TRAP, NEW AND GENERAL — MULTI-LINE NIX LISTS DEFEAT SINGLE-LINE GREP PIPELINES.
r2-regate's first strip-list search was `grep 'removeAttrs' | grep '__coords…'` — a pipeline that requires
both tokens ON THE SAME LINE. It returned ZERO for lists that demonstrably exist, because the key names sit on
CONTINUATION lines below the removeAttrs call. Caught only by disbelieving a clean result against a register
entry asserting four; re-run with `-A 3` over `find`. Had it been trusted, item 4 would have read NOT-TOUCHED
FOR A FALSE REASON — the worst outcome available, since a false NOT-TOUCHED is indistinguishable from a real
one in the verdict.
GENERAL FORM: in Nix, a two-token predicate over an attrset, list or function-arg is a MULTI-LINE predicate.
Any `grep A | grep B` conjunction over Nix source is unsound unless both tokens are provably on one line. Use
`-A N` / `-B N`, or read the range. This joins the standing trap list; it is the same family as the
`--include=` cross-tree exclusion and the OCR `j ≤ i` rendering — an instrument that answers a DIFFERENT
QUESTION than the one asked, and answers it cleanly.

Positive-control discipline restated for this entry: an absence claim against the register needs a positive
control on the same predicate in the same run. "Zero hits" against a construct the register asserts EXISTS is
a red flag about the instrument, not a finding about the code.


### 4 — 2026-07-28T06:06:27 · Jason Bowman

BODY CORRECTION — ENTRY 1 STILL LISTS THE VALUE-SHAPE PREDICATES AS LIVE SITES, THOUGH THIS BEAD'S OWN CORRECTION COMMENT WITHDREW THEM. Re-confirmed at HEAD a40cc96 by a third independent agent: `looksLikeClassContent` and `isNestedKey` appear ONLY as comments — lib/compat/compile.nix:218, :251, and lib/compat/module-shape.nix:6. No live predicate anywhere.

⇒ Anyone reading entry 1's BODY without also reading its correction comment gets a retiring-constructs register that names two retired symbols as current. That is the register's own failure mode operating on the register: a record whose correction lives in a comment while its body still asserts the original claim.
★ STANDING FIX, beyond this entry: when a register entry is corrected, THE BODY MUST BE EDITED, not annotated. A comment is a supplement for a reader who reaches it; the body is what a dispatch quotes. Three agents have now independently re-derived this same withdrawal, which is three rounds spent re-measuring a fact the record already contained but contradicted.

### 5 — 2026-07-28T06:20:50 · Jason Bowman

★ THE REGISTER'S OWN USAGE RULE, NOW TWICE-VALIDATED — READ IT, DO NOT SWEEP IT.

Both C9 hits found in this arc were INVISIBLE TO ANY TEXT SEARCH OF THE DESIGN, and both were caught the same way: the reviewer read this register's ITEMS and reasoned about what the design TOUCHES.
  HIT 1 (den-hoag-4kh.11, entry 4): the design's projected ctx descended from `inherited-context`, one of the four hand-maintained strip lists, three hops up through a binding sharing no name with it.
  HIT 2 (design 2 / producesByName, entry 3): the link existed ONLY IN THE ERROR-MESSAGE TEXT of two guards the design named as its precedent — lib/errors.nix:49-56 read 'the STAGED PRE-PASS's exclude-family feed'. THE GUARDS EXIST BECAUSE THE RETIRING CONSTRUCT FAILS, so extending them extends it. A grep of that spec for `4kh|retir|register|prePass|staging|demand-driven` returned two false hits and nothing real; POSITIVE CONTROL `producesByName` = 3.

⇒ A DESIGN IS WRITTEN IN ITS OWN VOCABULARY, SO THE VOCABULARY IS EXACTLY WHERE THE LINK WILL NOT BE. Any dispatch citing this register MUST say 'do not word-sweep — read each item and reason about what this design touches', AND carry a worked example of a hit a grep would have missed. A reviewer told only to 'check against the register' will grep it, report clean, and be wrong for a STRUCTURAL reason rather than a careless one.

★ AND ASK FOR THREE ANSWERS, NOT ONE. THEORY, MECHANISM and ARGUMENT survive a retirement INDEPENDENTLY:
  4kh.11: theory survived, mechanism survived AND IMPROVED under the retirement — a favourable answer that went unrecorded because nobody asked.
  Design 2: theory survived, mechanism survived, but THE ARGUMENT DID NOT — its precedent, its recommended candidate's title and its central asymmetry all rest on two guards that retire with the pre-pass, leaving the design's own guard the last member of a retired family and its 'twin' framing without a referent.
A design can be fully sound while its JUSTIFICATION evaporates with the construct it borrowed its precedent from. That is not a defect in the design; it is a defect in the spec, and it is only visible if the question is asked in three parts.

### 6 — 2026-07-28T15:30:40 · Jason Bowman

★★ ITEM 4's SITE IS WRONG AGAIN — AND MY EARLIER CORRECTION OF IT WAS ALSO WRONG. Third measurement, at 6f472d3.

HISTORY: my original relay gave `attributes/structural.nix:42-66` with the list `[ "__edges" "__containment" "__coords" "__root" "suppressedPolicies" ]`. A reviewer corrected that to `:61-62` as 'structural's own list'. ★ NEITHER RANGE IS RIGHT AT HEAD. The five-entry list is at **structural.nix:109-115**, inside the inherited-context compute opening at :97.
★ MY ORIGINAL RELAY'S *CONTENTS* WERE CORRECT — all five keys, in that order. Only the range was wrong. And the correction replaced a wrong range with a different wrong range, which is worse than the original error because it carried the authority of a verification.

⇒ THE REGISTER'S ITEM 4 NEEDS ITS SITES RE-VERIFIED WHOLESALE, not patched a third time. Three ranges have now been asserted for one list and none of them held. That is not bad luck: A LINE RANGE IS THE WRONG WAY TO CITE A LIST THAT LIVES INSIDE A FUNCTION BODY THAT KEEPS GROWING — the same failure that made the bucket spec's core anchor unverifiable, and it was fixed there by keying on the content's own markers rather than on line numbers. The register should cite the four strip lists BY THE EXPRESSION THAT DEFINES THEM (`removeAttrs` plus its key set, or the binding name), so a reader greps for something stable.
★ STANDING CONSEQUENCE FOR THIS BEAD, since it is the document every design brief quotes: A REGISTER ENTRY CITED BY LINE NUMBER DECAYS SILENTLY AND IS QUOTED CONFIDENTLY. Cite by name or by expression.

### 7 — 2026-07-29T01:47:21 · Jason Bowman

★★★ C9 HIT #3 IN THIS ARC, 2026-07-29 — AND IT IS THE THIRD FOUND ONLY BY READING, NEVER BY A TEXT SEARCH. Recorded here because the register's usage rule earns its keep on each one, and because this hit has a NEW SHAPE worth naming.

THE DESIGN: the three-state CI gate spec (den-hoag-9uv, papers 492a533, md5 01bfba783e31c57c245924f40a1c010e). It adopts nix-unit's native expectedError channel and DROPS gen's homegrown assertTests instrument as unable to host the mechanism.
THE HIT: ci/tests/_lib/den-compat-test.nix carries a deviation comment reading VERBATIM 'expectedError -> tryEval (mkCi has no error channel)'. ★ THE WEAK WORKAROUND EXISTS *BECAUSE OF* THE INSTRUMENT THE DESIGN RETIRES. The design removes the CAUSE and leaves the WORKAROUND LOAD-BEARING — and then routes twelve of its eighteen declarations through it, because those twelve live in scaffold-hosted files. Measured consequence: the scaffold lowers to (tryEval (deepSeq expr expr)).success and DISCARDS type AND msg BEFORE NIX-UNIT SEES THE LEAF, so the design's own 'failing differently must FAIL' verdict does not hold for two-thirds of its population.
WHY NO SWEEP COULD FIND IT: the spec DOES name expectedError — repeatedly, as its central mechanism. A grep for its own vocabulary returns hits everywhere and tells you nothing. What was needed was noticing that the file the spec identifies as carrying 'a weaker homonym' and the files it assigns twelve declarations to ARE THE SAME FILES. The spec contains both halves, in different sections, and never joins them.

★★ THE NEW SHAPE, WORTH ADDING TO THIS REGISTER'S REPERTOIRE — **A WORKAROUND OUTLIVES ITS CAUSE.** The three hits so far:
  #1 (4kh.11) — the link was three hops up an INHERITANCE CHAIN, through a binding sharing no name with its source.
  #2 (design 2) — the link lived only in the ERROR-MESSAGE TEXT of two guards the design cited as precedent; the guards existed BECAUSE the retiring construct fails, so extending them extended it.
  #3 (this one) — the link is a COMMENT EXPLAINING WHY A WEAKER MECHANISM WAS BUILT, naming the instrument the design removes. Retiring a construct does not retire the compensations built around it, AND THOSE COMPENSATIONS ARE EXACTLY WHERE A SUCCESSOR DESIGN WILL SILENTLY LAND, because they occupy the successor's own vocabulary.
⇒ ADD TO THE DISPATCH INSTRUCTION: when a design RETIRES OR REPLACES AN INSTRUMENT, enumerate what was built to WORK AROUND that instrument's limitations. Those workarounds do not retire with it, they are usually named after the thing that replaces them, and a text search for the design's vocabulary will hit them without flagging them.

★ AND THE THREE-PART QUESTION PAID OUT AGAIN, THIS TIME ON A SUBSTITUTION. The spec CONCEDED that its ARGUMENT's file-adjacency half dies under entry 3 and substituted GREP-REACHABILITY. ★ THE SUBSTITUTE DIES BY THE SAME MECHANISM, AND THE REVIEWER MEASURED IT: an author retiring entry 3 holds this register's own anchors — the binding prePassScopeRoots and the header 'THE STAGING THAT BREAKS THE CYCLE (design note §3b)'. grep -rn prePassScopeRoots ci/ -> 0, POSITIVE CONTROL SAME RUN 6 hits in lib/default.nix. The spec's prescribed construct value is a PROSE PHRASE matching NEITHER anchor.
⇒ ★★ A CONCESSION IS NOT A DISCHARGE. Conceding that one argument dies, and replacing it, creates a NEW argument that must be tested against the SAME retirement — and here the replacement failed identically. C9 must be re-applied to whatever a design substitutes, not only to what it started with.
⇒ AND IT VINDICATES THIS REGISTER'S 'CITE BY EXPRESSION OR BINDING NAME' RULE FROM AN UNEXPECTED DIRECTION: the rule was written for register ENTRIES, to stop line-number decay. It turns out to bind DESIGNS TOO — a design whose retirement hook is a prose phrase rather than a binding name is not grep-reachable from the code being retired, which is the only direction anyone will ever search from.

### 8 — 2026-07-29T02:14:54 · Jason Bowman

★★★ ENTRY 3'S CI-CONSEQUENCE PARAGRAPH IS WRONG AND IS WITHDRAWN. I WROTE IT, AND IT IS A FALSE INFERENCE
FROM TWO TRUE FACTS JOINED BY "AND". Measured and refuted 2026-07-29 by an independent trace.

WHAT I WROTE: that den-hoag-4kh.51 records a suppression path resting on the staging, AND that twelve of
the known-red are compose-commitment aborts — then concluded "when it retires and those tests pass, a
known-fail-that-starts-passing rule turns a successful retirement into a gate failure."
★ THE INFERENCE DOES NOT FOLLOW FROM EITHER CONJUNCT, AND BOTH CONJUNCTS ARE TRUE. That is what made it
readable: two verified facts, adjacent, with a plausible bridge that nobody had built.

WHY IT IS FALSE, PROVEN STRUCTURALLY RATHER THAN BY GREP:
· 4kh.51's subject is `lib/compat/compile.nix` `gateSuppression`, suppress facts, and `fireExcludeAt` — the
  EXCLUDE FAMILY, structural stratum. The twelve aborts are `pipeOp`, COLLECTION stratum. DISJOINT.
· Both pre-pass feeds require `r.group == "structural"`: `resolveFamily` filters
  `r.group == "structural" && emitsAny r declare.resolveFamilyKinds`, `excludeFamily` the same with
  `[ "suppress" ]`. `runPrePass` is handed ONLY `resolveIndex` and `excludeIndex`.
· The twelve are provably collection-group: the observed error is `opsInBody`, NOT `emitsUndeclared`, so the
  `admitted` test passed ⇒ `pipeOp ∈ emits`; `groups.collection = [ "pipeOp" ]`; and `policyMessage` aborts
  when a policy spans more than one group ⇒ `groupsOf emits == [ "collection" ]`. Confirmed empirically:
  `ci/tests/compat-policy-expansion.nix` `test-declared-sitemark-collection` asserts exactly that and RUNS
  GREEN (EXIT=0, 15/15).
· ACYCLICITY, which settles it without any grep: `runPrePass` READS `ent`, so `ent.config.den.policies`
  cannot read `prePass` — a cycle would black-hole and the suite evaluates. THE COMPOSE SEED IS STRICTLY
  UPSTREAM OF THE PRE-PASS.
⇒ A COLLECTION-STRATUM RULE IS IN NEITHER FEED, SO THE PRE-PASS NEVER FIRES IT, SO `opsInBody` IS NOT
REACHABLE FROM `runPrePass`. Retiring entry 3 does not make these twelve green, and ENTRY 3'S RETIREMENT
DOES NOT NEED TO RETIRE TWELVE BASELINE ENTRIES.

★ THE METHOD LESSON, WHICH IS THE REASON THIS IS RECORDED IN THE REGISTER RATHER THAN QUIETLY DELETED:
TWO VERIFIED FACTS PLACED SIDE BY SIDE PRODUCE A THIRD CLAIM THAT NEITHER SUPPORTS, AND THE ADJACENCY IS
DOING THE ARGUING. Every citation in my paragraph was correct. The word carrying the falsehood was "AND".
⇒ THIS REGISTER'S ENTRIES MUST STATE MECHANISMS, NOT NEIGHBOURHOODS. "X rests on the staging" and "Y is
red" are not a relationship between X and Y. Before writing that a retirement affects something, NAME THE
BINDING THROUGH WHICH IT WOULD PROPAGATE — here that would have been the feed filter, and one look at
`r.group == "structural"` would have stopped the sentence.
★ AND IT IS THE FOURTH TIME THIS REGISTER HAS CARRIED A WRONG CLAIM: three decayed line ranges, one
overstated strip-list "drift", and now one false inference. THE REGISTER IS THE MOST-QUOTED DOCUMENT IN THE
ARC AND HAS THE WORST DEFECT RATE OF ANY ARTEFACT IN IT. That is not irony, it is a consequence: it is the
document written FASTEST, from memory, about work in flight.

WHAT REPLACES IT: entry 3's retirement has NO KNOWN CI CONSEQUENCE for the twelve compose-commitment
aborts. What WOULD make them green is redesigning the `ops` representation — tracked at den-hoag-4kh.53.64,
and see den-hoag-i5m for why declaring them is a live question independent of any retirement.

### 9 — 2026-07-29T02:59:48 · Jason Bowman

★★★ ENTRY 3'S ARCHITECTURAL CLAIM IS **WRONG**, AND IT IS NOW REFUTED TWICE INDEPENDENTLY. THE BODY MUST
CHANGE, NOT CARRY AN ANNOTATION — this register's own standing rule.

THE CLAIM, which I wrote into the entry and then into two dispatch briefs as the thing to stress-test:
"where membership is an EDGE rather than an input to node construction, THERE IS NO ORDERING TO STAGE."
**IT DOES NOT FOLLOW.** Verified by the containment-as-edges author AND independently by its adversarial
reviewer, both by reading the bindings:
· A containment-edge design makes **CONTAINMENT** edges, not **MEMBERSHIP** edges. Cells are STILL minted
  from `product.cells` <- `restrict` <- tuples <- the pre-pass. Necessary, not sufficient.
· ★ AND THE ENTANGLEMENT RUNS THE OTHER WAY: `baseScopeRoots = buildRoots { ... attachments =
  prePass.containmentAttachments; }`, and `mintedRootId bareId parents parent` PUTS `@` INTO ROOT IDS WHEN
  N>1. Edge ENDPOINTS ARE NODE IDS. ⇒ **EDGES MUST BE BUILT AFTER MINTING, SHARING `mintedRootId`.** Making
  containment an edge does not remove the ordering; it INHERITS it.
⇒ THE REGISTER WAS ASSERTING THAT ENTRY 5 DISSOLVES ENTRY 3. IT DOES NOT. They remain two retirements, and
entry 3 needs its own mechanism.

★ WHY THIS ONE WAS EXPENSIVE RATHER THAN MERELY WRONG: I PROMOTED IT TO THE HEADLINE OF A SPEC BRIEF —
"the one argument I most want stress-tested" — so an author spent a spec establishing that the register's own
sentence is false. That is the system working exactly as designed, and it is also two rounds spent on a claim
that one read of `buildRoots`' argument list would have refuted before dispatch.
★★ AND IT IS THE SECOND FALSE CLAIM IN THIS ENTRY IN ONE DAY, both mine: the CI-consequence paragraph (two
true facts joined by "and", withdrawn earlier) and now the architectural claim. Combined with three decayed
line ranges and one overstated strip-list drift, **THIS REGISTER HAS THE WORST DEFECT RATE OF ANY ARTEFACT IN
THE ARC — AND IT IS THE MOST-QUOTED ONE.** That is not irony; it is the direct consequence of being written
fastest, from memory, about work in flight, by whoever has just finished something else.
⇒ STANDING CONSEQUENCE, ADDED TO THIS ENTRY RATHER THAN LEFT AS A LESSON: **AN ENTRY MAY STATE WHAT A
CONSTRUCT IS AND WHY IT RETIRES. IT MAY NOT STATE WHAT RETIRING IT WOULD ACHIEVE ELSEWHERE.** A claim of the
form "retiring X dissolves Y" is a DESIGN CONCLUSION and belongs in a spec that can be reviewed, not in a
cache that is quoted. Every such claim in this register so far has been false.

WHAT ENTRY 3 CORRECTLY STILL SAYS: the staged pre-pass is LIVE at HEAD (`lib/default.nix`, header verbatim
"THE STAGING THAT BREAKS THE CYCLE (design note §3b)", binding `prePassScopeRoots` built and consumed ~15
lines apart — re-verified at HEAD by the witness reviewer at :1016 / :1025 / :1040); a staged pre-pass whose
ordering exists to break a dependency cycle is the shape HOAG replaces with demand-driven attributes; and the
kernel already owns that idiom throughout lib/attributes/. Tracker den-hoag-4kh.18, OPEN P2.
★ AND ITS COST IS NOW MEASURED, WHICH IT WAS NOT WHEN THE ENTRY WAS WRITTEN: the pre-pass fires every root
TWICE under an explicit DOUBLE-FIRE DISCIPLINE, and that constant is baked into every absolute figure the
scaling witness would record (den-hoag-qxz). Any budget calibrated today is wrong the day this retires.

### 10 — 2026-07-29T03:45:22 · Jason Bowman

★★★ C9 HIT #4, AND IT IS THE CLEANEST INSTANCE OF ENTRY 3'S REACH YET MEASURED — the retiring construct
supplies the CODOMAIN of a design that states in writing that it never touches it.

THE DESIGN: containment-as-edges revision 2. Its central claim is that position is a projection of the edge
set onto a DECLARED INDEX, and that the index is `dimKinds`. Its §9 MECHANISM says the partition "consults
the pre-pass nowhere."
MEASURED FALSE. lib/default.nix: `membershipTuples = ent.config.den.membership ++ prePass.tuples` ->
`tupleDimKinds` -> the basis of `dimKinds`. With ONE variable changed — whether a policy-emitted member
carries containTo:
    containTo-marked (a relation, NO tuple)  ->  dimKinds = [ host, user ]        env is an axis? FALSE
    plain policy member (a prePass TUPLE)    ->  dimKinds = [ env, host, user ]   env is an axis? TRUE
⇒ THE PRE-PASS DECIDES WHAT THE COORDINATE QUERY'S CODOMAIN IS.

★ WHY NO WORD-SWEEP COULD FIND IT — the chain is THREE HOPS THROUGH BINDINGS SHARING NO NAME WITH THEIR
SOURCE: `dimKinds` -> `tupleDimKinds` -> `membershipTuples` -> `prePass.tuples`. The design's vocabulary is
"axis", "codomain", "projection", "partition". The register's vocabulary is "staging", "pre-pass",
"prePassScopeRoots". They do not intersect anywhere. ★ AND THE SPEC'S OWN §8 RECORDS THAT `tuples` STAYS
THREADED THROUGH THE PRE-PASS AND NEVER CONNECTS IT TO §9 — both halves present in one document, unjoined,
which is EXACTLY the failure mode of the previous C9 hit (a spec naming `hasExpectedError` as a weaker
homonym in one section and routing twelve declarations through it in another).

★★ THE SHAPE THIS ADDS TO THE REGISTER'S REPERTOIRE, and it is the most dangerous one so far:
  #1 (4kh.11) — the link was three hops up an INHERITANCE CHAIN.
  #2 (design 2) — the link lived only in the ERROR-MESSAGE TEXT of two guards cited as precedent.
  #3 (gate spec) — a WORKAROUND OUTLIVED ITS CAUSE and was named after the thing that replaced it.
  #4 (this one) — ★ **THE RETIRING CONSTRUCT SUPPLIES THE DESIGN'S CODOMAIN — the set of legal ANSWERS, not
  the mechanism.** A design can be entirely correct about its algorithm and still have its RANGE decided by
  the thing being retired. Retiring the pre-pass changes which tuples exist, which changes `dimKinds`, which
  changes what `coordsOf` is even able to return — WITHOUT ANY LINE OF THE DESIGN CHANGING.
⇒ ADD TO THE DISPATCH INSTRUCTION: when a design declares a DOMAIN, an INDEX, a CODOMAIN or a KEY SET, trace
WHERE THAT SET COMES FROM, hop by hop, to a declaration site. "The keys come from the declared axis set" is a
claim about a BINDING, and a binding is not a declaration until you have followed it home.

★ AND A SECOND, INDEPENDENT C9-ADJACENT FAILURE IN THE SAME REVIEW, worth recording beside it: the design's
substitute GUARD — written specifically to discharge the argument that died twice — has a vacuity control
that is ITSELF VACUOUS. Its "positive control" fixture exercises ZERO instances of the path the guard tests,
so it is green on a path it cannot reach. ⇒ **den-hoag-akj's GENERAL FORM FIRED ON THE GUARD WRITTEN TO
DISCHARGE den-hoag-akj.** A vacuity check needs its own vacuity check, and the recursion terminates only when
someone MEASURES that the control takes both values on one instrument.

### 11 — 2026-07-29T21:56:49 · Jason Bowman

BODY REWRITTEN 2026-07-29 (orchestrator), from a fresh-context read-only audit at HEAD d33ce02. This comment is the evidence record; the corrections are IN THE BODY per the correction rule.

WHOLE-REGISTER ANCHOR CENSUS (auditor's segmentation, 72 anchors): 41 LIVE / 13 DRIFTED / 18 DEAD.
Per entry — E1: 11/3/1 · E2: 4/0/1 · E3: 6/1/2 · E4: 14/5/8 · E5: 4/3/5 · footer: 2/1/1.
Binding-name and verbatim-header anchors survived 113 commits with zero decay; line-number decay is largely solved. What decayed instead: (1) anchors died by being FIXED — entries 4/5's migration shipped between 6f30460 and d33ce02; (2) tracker status drifted silently in both directions (5ae CLOSED under entry 5 while the entry said "OPEN at P0"; 4kh.16 and 5bp retitled to their resolved state); (3) two owner-refuted claims sat verbatim in entry 3's body after their refutation comments (019fabd0, 019faba7). All three decay modes now have header rules.

HYPOTHESES TESTED (relayed from another session, verified not inherited):
H1 (entry 4 substantially retired; strip lists 4→2; coordDims deleted): CONFIRMED with one correction — only staged-resolution.nix narrowed to ["__edges"]; structural.nix keeps "suppressedPolicies", which is exactly what entry 4 predicted (its only correct forward claim).
H2 (~6 dead / ~14 drifted in one slice): NOT CONFIRMED AS STATED — it UNDERSTATES. Whole register: 18 dead, 13 drifted. Entry 4 alone: 8 dead, 5 drifted. Neither reading matches.

KEY MEASUREMENTS (all /run/current-system/sw/bin/grep; every DEAD verdict carried a same-run positive control on the same predicate shape):
· `__coords =` / `__containment =` kernel assignments → 0 (control `__root =` / `__terminal =` hit); fleet.nix tombstone quotes the retired expressions.
· coordsOfNode → 0 repo-wide (control coordDims → 10, __coords → 9, all comments/fixtures).
· __action dispatch sites: NINE across five files (was "eleven"); its tag set IS enumerated at lib/declarations.nix groups (17 kinds / 4 strata) — "enumerated nowhere" was wrong.
· lib/compat/module-shape.nix DOES NOT EXIST; the site is lib/module-shape.nix, a KERNEL file (control: ls both paths).
· Stale positive-control figures refreshed: classSliceOf 9→38, producesByName 3→16.
· Footer worked example is HISTORICAL: "the STAGED PRE-PASS's exclude-family feed" → 0 hits repo-wide because the two guards themselves retired (lib/errors.nix: "The resolve-family and exclude-family UNTAGGED guards are RETIRED"). Controls in same file same run: pre-pass → 1, exclude-family → 1.
· Kernel writes SEVEN __ keys + __spawn suffix (was "eight"): __coords/__containment gone, __missing (lib/coordinates.nix) was never listed. 27 distinct __ names (was 26); EIGHT are unclassified as gen-vs-kernel-owned — ownership pass owed, flagged in entry 4.

AUDITOR COVERAGE: bead description + all 10 comments read in full from --json; every anchor of every entry evaluated; lib/default.nix and output-modules.nix grep-located only; CI suite not run (the paragraph containing the 18-red/12-abort figures was withdrawn anyway). Tree untouched, git status clean at d33ce02.
