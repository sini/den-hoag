# den-hoag-4kh.1 — W1: verify shipped claims against the tree (axis-1 board first)

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.1` |
| status at evacuation | closed |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:23:53Z by Jason Bowman |
| last updated | 2026-07-27T21:53:20Z |
| closed | 2026-07-27T21:53:20Z |
| close reason | COMPLETE. 21/21 axis-1 board checkboxes verified against the tree: 19 SHIPPED-REAL, 2 no-code-claim (R1 document-only, R3 vacuous by the board's own claim), 0 PARTIAL, 0 NOT-SHIPPED. SHIPPED-RENAMED-ONLY bucket EMPTY as a verified result — seven mechanisms survive by name and all seven route to gen in the body.

HEADLINE: A1 runPrePass = SHIPPED-REAL. The accumulator is genuinely gone, not renamed. Decisive property: the pre-image's per-element step read the accumulator (st.relationBindings.${id} at 6bef742^:233); at HEAD no fold in that file reads acc to compute its element.

⇒ This INVALIDATED den-hoag-4kh's own criterion-5 known-positive, which named that accumulator. Corrected on den-hoag-4kh.2 before W2 ran; replacement is the 2-stage schedule at lib/default.nix:1074-1086.

Two false sub-claims found (one later RETRACTED by the agent itself after re-measuring — git log -S is blind to body rewrites that preserve identifier count; that is now TRAP 4 in the tooling memory). One survives: a stale errors.reservedClassInclude reference at ci/tests/compat-nested-class-named-aspect.nix:132.

Two observations routed to the review gate rather than filed: (a) lib/compat/produces-by-name.nix is a five-entry literal map keyed by v1 policy NAME and pinned to a single corpus census, so B7→G3's dissolution is complete for five named policies and structurally incomplete for the surface; (b) probeOf masks errors asymmetrically — a throw is swallowed by tryEval and silently rerouted to the retired fallback fan.

Full evidence in this bead's comments. Superseded the previous session's unresponsive W1. |
| description bytes | 2018 |
| notes bytes | 0 |
| comments | 3 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Verify every SHIPPED claim in the STATUS trackers against the actual tree, by COMMAND.

PRIMARY INPUT: STATUS/route-through-board.md — the AXIS-1 tracker (graph-native correctness). It records 17 shipped route-through rungs: Tier-B rungs 1-2, A5 to G6, A3/B9, the FLAGSHIP A1 runPrePass state-accumulator dissolution at 6bef742, compat-1, B7 to G3, the six-rung raw/typed-dual dissolution, and gen-link R0 through R4. Each asserts a specific effect-runtime holdover was DISSOLVED. Those are the claims that matter.

SECONDARY: STATUS/coverage-matrix.md — the AXIS-2 tracker, which calls itself the symptom axis. Use its ~48 completion claims (18 SHIPPED + 21 checkmark + 9 DONE). Its 6 OPEN + 1 GAP rows are FORWARD-LOOKING and must NOT be read as shipped claims. Also: it declares itself LIVE while pinning den-hoag 4044ed5, and HEAD is 34 commits later — so every row is a claim about a tree that has since moved. Re-verify, do not inherit.

ALSO: STATUS/compat-feature-register.md.

METHOD: one command per claim, recorded beside it, re-runnable. This is the CONFORMANCE.md method applied to a claim set rather than a document. Yield is proven: the same method already found five documented features with zero consumers (sel.entityKind, pipe.withConfig, buildScopeGraphs, meta.substitute, result.nodesOfType), two of which were never built anywhere.

ABSENCE NEEDS A POSITIVE CONTROL. Two false-absence results happened this session and both were caught only by controls: a pipe.<verb> grep over lib/ returns 0 for SHIPPED verbs because they are defined inside a pipe = { } block and used only in ci/.

CRITICAL DISTINCTION for this workstream: a rung claiming a holdover was DISSOLVED can be false in two ways — the code was not changed, OR the code was renamed and the shape survives. The second is the one that matters and grep will not find it. Route those to W2.

OUTPUT: a claim/command/result/verdict table. Unshipped findings do NOT become beads directly — they go to the adversarial review gate (see epic).

## Comments (3)

### 1 — 2026-07-27T20:48:41 · Jason Bowman

W1 IS INCOMPLETE. The agent (fresh context, 2026-07-27) did substantial work, then went idle THREE times
without reporting and did not answer two direct requests — the second cut down to four lines. Treated as
unresponsive; not re-dispatched, because den-hoag-4kh.9 (the Nix-aware relaunch) is the better instrument for
exactly this workstream and re-running now would spend the effort on the weaker one.

SALVAGED FROM ITS ARTIFACTS (read directly off the scratchpad, not reported by the agent):
  ci.out         — /nix/store/1wa4v9rhi30dazyby37jqmlj9liskfg5-den-hoag-tests  => ci gate BUILDS at HEAD
  parity.out     — /nix/store/a97rcwnamlh2is2iq5cb3w1zz4kfdr2v-den-compat-parity-tests => parity BUILDS
  shipgate.json  — allEqual TRUE; emitting channel shimDrvPath == v1DrvPath, byte-identical
                   (q7vk7qda3687g06p2kaaql00raqmpb3x-nixos-system-igloo)
  hashes.txt     — two commit-hash sets extracted from the trackers (39 + 34) for resolution checking. Method
                   was right: verify every commit a tracker cites actually resolves.
  scoperoots.err — its structure probe FAILED: "flake does not provide attribute
                   packages.x86_64-linux.den.scopeRoots". Wrong access path; the working forms are
                   `#nixosConfigurations --apply builtins.attrNames` under an --override-input den, or a
                   __denProbe output added in a den-hoag worktree read through the same override.

★ WHAT THE GREEN GATES DO AND DO NOT SETTLE. All three gates green at HEAD is real information and it settles
NOTHING about this workstream's actual question. den-hoag-9xo.27 already established that the gates CANNOT
fail on discovery/identity/placement changes, and a plausible refactor was demonstrated that keeps ci 0 /
parity 0 / ship-gate 0-true / enumeration exit 0 while emptying the corpus's entire environment registry.
Green gates are consistent with a dissolution having been renamed rather than performed.

★★ THE LOAD-BEARING QUESTION IS STILL OPEN: is the A1 runPrePass state-accumulator dissolution
(route-through-board, SHIPPED @6bef742, "the flagship") SHIPPED-REAL or SHIPPED-RENAMED-ONLY? That single
verdict decides which of two epics is stating a falsehood — den-hoag-9xo says "No effect-runtime duplication
remains" and lists A1 DONE; den-hoag-4kh makes the same A1 accumulator the KNOWN-POSITIVE for criterion 5 of
its kernel-purity audit; den-hoag-7pt measures a live __provider writer. Both epics cannot be right.

⇒ CARRIED TO den-hoag-4kh.9 AS ITS FIRST TARGET. "Is the accumulator gone, or present under a gen-native
name?" is precisely the structural query text search cannot settle and a symbol/call-graph index can. Do not
re-run W1 with grep first; that is the instrument that just failed to produce an answer.

COVERAGE: unknown. The agent never reported how many claims it checked against how many exist, so W1's
coverage is UNMEASURED — not zero, not complete. Any future pass starts from the trackers, not from this one.

### 2 — 2026-07-27T21:48:03 · Jason Bowman

W1 RELAUNCH COMPLETE (graph-instrumented, fresh context, 2026-07-27). 21/21 board checkboxes examined,
read-only. Supersedes the previous session's unresponsive W1.

★★ A1 VERDICT: SHIPPED-REAL. THE ACCUMULATOR IS GONE. NOT A RENAME.
DECISIVE PROPERTY: in the pre-image the per-element step READ the accumulator; at HEAD no fold in the file
does.
  PRE-IMAGE (git show 6bef742^:lib/staged-resolution.nix, saved to scratchpad/prePass-before.nix):
    :233 ctx = baseCtx // (st.relationBindings.${id} or { })   <- the STEP READS st
    :250/:257/:259 threaded foldl' over a { tuples; relationBindings; containmentRelations; suppressions }
    record, plus :53-67 orderRootKinds/depthOf — a parent-before-child N-phase depth schedule. Genuine v1
    shape.
  HEAD: :308 containmentEmissions = concatMap … ; :317 byTarget = prelude.groupBy (e: e.tid) — a per-target
    carrier; :410 deliverCtxOf = id: baseCtxOf id // (containmentBindings.${id} or { }) — demand-read.
  EVERY surviving foldl' audited individually (:93 :95 :344 :350 :430): each is a MONOID MERGE over
    independently-computed elements; none reads acc to compute its element. suppressions (:430) looks
    accumulator-shaped but derives from deliverCtxOf id alone.
  ABSENCE + CONTROL, same run same paths: orderRootKinds 0 · depthOf 0 · relationBindings 1 (a comment at
    :22 saying it is gone) ‖ controls groupBy 40, byTarget 9, containmentRelations 14. The surviving
    containmentRelations is a PARAMETER NAME in resolved-settings.nix:104 fed prePass.containmentAncestors,
    read on demand — a slice map, not an accumulator.

★★★ CONSEQUENCE — den-hoag-4kh IS THE EPIC STATING A FALSEHOOD, NOT den-hoag-9xo.
4kh's criterion-5 KNOWN-POSITIVE IS INVALID: the A1 accumulator does not exist at HEAD, so criterion 5
positive-controls on an ABSENT predicate. W2 as specced would report "clean" for a predicate that could not
have matched — precisely the failure the standing bar exists to prevent, built into the epic by the
orchestrator. A NEW known-positive is required BEFORE W2 runs.
9xo's "No effect-runtime duplication remains" is NOT refuted by A1. It may still be false via 7pt's live
__provider writer — a different holdover.

ADJACENT, NOT A1, AND THE REPLACEMENT CANDIDATE: a coarse 2-STAGE SCHEDULE SURVIVES AT THE CALLER —
lib/default.nix:1074-1086, verbatim header "THE STAGING THAT BREAKS THE CYCLE", prePassScopeRoots fixed
before classification. In-tree, acknowledged, already tracked as den-hoag-9xo.10 — whose cited line range
961-968 HAS DRIFTED; at HEAD it is 1074-1086. Explicitly: do NOT let this be re-filed as an A1 regression.

RUNG TABLE: 17 SHIPPED-REAL · 2 PARTIAL · 2 no-code-claim (R1 document-only; R3 vacuous by the board's own
claim). All 17 cited den-hoag hashes RESOLVE and are ancestors of HEAD; the sole unresolved (cf5c9c3) is
labelled orphaned/superseded by the board itself, which is consistent.
  PARTIAL #2 Tier-B rung 2 @1211231 — only 2 of ~9 constituents verified (gather.nix:393 prelude.groupBy);
    B11/B13/B18/B19/B22/B24 + ingest-dedup NOT individually checked.
  PARTIAL #7 B7→G3 @4eaf8b3 — deriveGroup present and called (22 hits), but RETIREMENT of the
    fire-and-observe classify NOT proven.

★ SHIPPED-RENAMED-ONLY BUCKET: EMPTY — and this is an honest result, not a pass-by-default. Every
name-survivor found (argEnvWrap, resolveParametric, forwardExpand, ancestorResolvedKeys, checkFillAcyclic,
presentAtKind, runPrePass) has a body that genuinely routes to gen. The two rungs that could not be settled
to SHAPE are marked PARTIAL, not SHIPPED.

TWO FALSE SUB-CLAIMS:
 1. G-3 mergeMaps PROVENANCE IS FALSE. The board's move-to-gen tail says G-3 (mergeMaps) ALREADY LANDED
    @08e8e9a/1211231. `git log -S mergeMaps -- lib/compat/gather.nix` returns ONLY c79e2ff, its creation —
    neither cited commit touched it. At HEAD gather.nix:123 mergeMaps routes through a NIX BUILTIN
    (builtins.zipAttrsWith), not gen-prelude. Shape arguably fine; the landed-at attribution is wrong.
 2. ci/tests/compat-nested-class-named-aspect.nix:132 cites errors.reservedClassInclude as a live loud error;
    0 hits outside that comment (retired at fc4a7f0). Comment only.

★★ NEW INSTRUMENT BLIND SPOT — TRAP 3, DISTINCT FROM TRAP 2. search_graph name_pattern returns 0 for
byTarget and nativeEmissions, though both exist (staged-resolution.nix:317 and :268). Cause: they are
non-function `let` VALUE bindings, and only Function nodes are returned. ⇒ GRAPH ABSENCE IS UNINFORMATIVE FOR
ANY NON-FUNCTION BINDING. Using it as the absence instrument on a let-bound carrier would MANUFACTURE FALSE
"DISSOLVED" VERDICTS. Every absence in this report is grep-derived for that reason.

★ WHERE THE GRAPH BEAT GREP — the (ii)-detection use. search_graph returns a `bt` (body-token) list per
Function. For argEnvWrap and resolveParametric — both surviving BY NAME, i.e. exactly the rename-only shape a
name-grep flags as un-dissolved — bt showed adaptArgs/configGate and wrapGatedFn/onResult, answering the
SHAPE question in ONE call. RECOMMENDED as W2's standing first probe for criteria 1/4/5.

INDEX FRESHNESS POSITIVE-CONTROLLED: HEAD-only symbols present in the graph (containmentOf, deliverCtxOf,
attachmentsOf, ownedBy, foldBindings), so the index is at/near HEAD and not stale to the pre-image.

### 3 — 2026-07-27T21:52:36 · Jason Bowman

W1 COMPLETE — both PARTIALs closed, and ONE PRIOR FINDING RETRACTED. Axis-1 board now fully verified.

★ RETRACTION, and its method lesson is the valuable part. The earlier "false sub-claim #1" (G-3 mergeMaps
provenance is FALSE) IS ITSELF FALSE. Commit 1211231 DID rewrite mergeMaps:
    -  mergeMaps = maps: prelude.foldl' (acc: m: prelude.foldl' (a: ch: a // { ${ch} = (a.${ch} or []) ++
       m.${ch}; }) acc (attrNames m)) { } maps;
    +  mergeMaps = maps: builtins.zipAttrsWith (_: prelude.concatLists) maps;
A nested accumulator fold collapsed to a flat zip — a real dissolution. THE BOARD WAS RIGHT.
★★ TRAP 4 — `git log -S <identifier>` COUNTS STRING OCCURRENCES, so it is BLIND to a body rewrite that
preserves the identifier count (once before, once after ⇒ pickaxe reports nothing). Use `git log -G` (regex
over the diff) or read `git show <commit> -- <path>`. This is the same "predicate that cannot match the
at-risk edit" class the standing bar warns about, and it produced a false finding this session. The commit
message named the site explicitly; reading it first would have cost one call.
The second sub-claim (stale errors.reservedClassInclude comment at compat-nested-class-named-aspect.nix:132)
is unaffected and STILL HOLDS.

RUNG #2 Tier-B rung 2 @1211231 → SHIPPED-REAL, 9/9. The commit message enumerates exactly 9 routed sites; all
9 confirmed live at HEAD: inverseRelationEdges (default.nix:2088), indexByNeededBy (resolved-aspects.nix:229),
projectedByKind (claim-accessor.nix:110), reverseByKind (claim-accessor.nix:70), assertNoCollision
(projects.nix:130), assembleEdges (edges.nix:356), fillGraph (edges.nix:384), broadcastersByChannel
(gather.nix:393), mergeMaps (gather.nix:123). Plus ingest-dedup = ingest.nix:287-289 groupBy + prelude.last,
last-wins as claimed. In every case the hand-rolled foldl' bucket accumulator is GONE FROM THE BODY, not
renamed around. Also confirms the board's B14 exclusion is HONEST — 1211231 explicitly skipped localDemandData
for order-sensitivity and the board carries B14 as an open unchecked box; claim and code agree.

RUNG #7 B7→G3 @4eaf8b3 → SHIPPED-REAL but BOUNDED. The replacement is genuine: dispatch.deriveGroup does real
work at concern-policies.nix:313 and :366. The three-way branch at :359-374 bounds it:
  !expanded              -> deriveGroup (mkSingle … probeActs)   probe FIRED then classified
  declaredKinds != null  -> mkDeclaredSlices … declaredKinds     THE REAL DISSOLUTION, no fire
  else                   -> mkExpanded name condition base       the blind per-stratum fan, SURVIVES
RETIRED: the blind per-stratum fan FOR POLICIES CARRYING A DECLARATION (branch 2 stamps the group at
definition time from data). SURVIVES BY DESIGN: mkExpanded as the documented produces == null fallback
(:279, :374). SURVIVES AND RUNS UNIVERSALLY: the fire-and-observe PROBE — probeOf (:171-188) is called at
:345 for EVERY policy and is a literal fire-and-observe (sentinel-fills gate coords, tryEval + deepSeq over
produce "«probe»", reads emissions back).
⇒ The CLASSIFY was retired; the FIRE-AND-OBSERVE was NOT — it was relocated from per-dispatch to definition
time and its output feeds deriveGroup. The commit message says exactly this ("probeOf is narrowed to the
compose-seed value-extract role"); the BOARD'S ONE-LINE COMPRESSION overstates it. Board wording fix, not a
re-open.

★★ TWO OBSERVATIONS ROUTED TO THE ORCHESTRATOR, NOT FILED (they are review candidates, not rung verdicts):
 (a) THE DECLARATION TABLE IS CORPUS-PRESENCE-KEYED — the exact bar the owner says to hold against.
     lib/compat/produces-by-name.nix is a FIVE-ENTRY LITERAL MAP (env-to-hosts, env-to-clusters, env-users,
     cluster-aspect, broadcast-hub-peer) keyed by V1 POLICY NAME, with its own header pinning it to "census
     nix-config @fddab954". A sixth value-conditional policy — or any den user's own — silently takes branch
     3 and gets the UN-DISSOLVED blind fan. The file calls this "THE OMISSION FALLBACK" openly. This is
     gate-on-corpus-presence rather than den-surface-expressibility: the dissolution is complete for five
     NAMED policies and structurally incomplete for the SURFACE. See [[feedback_den_surface_not_config]].
 (b) THE PROBE MASKS ERRORS ASYMMETRICALLY. probeOf wraps the fire in tryEval, so a genuine `throw` is
     SWALLOWED and silently reclassified as "empty probe ⇒ expansion" (:188 `if try.success then try.value
     else [ ]`). Since tryEval cannot catch a missing-attribute error, a body reading a missing attr surfaces
     uncatchably while a body that THROWS is silently rerouted to the fallback fan. A broken policy degrades
     into the retired path instead of aborting named.
 UNVERIFIED, not settleable read-only: whether branch 3 is genuinely corpus-inert. That needs a corpus
 evaluation to enumerate value-conditional policies; produces-by-name.nix ASSERTS the census (5, all mapped)
 but it was not re-run — and it is pinned to ONE revision of ONE witness (fddab954).

FINAL COVERAGE: 21/21 board checkboxes — 19 SHIPPED-REAL · 2 no-code-claim (R1 document-only, R3 vacuous by
the board's own claim) · 0 PARTIAL · 0 NOT-SHIPPED · SHIPPED-RENAMED-ONLY EMPTY, now a VERIFIED result rather
than provisional. Seven mechanisms survive by name and all seven route to gen in the body.

OPERATIONAL: the subagent SessionStart hook STILL injects "NIX IS NOT COVERED — .nix files yield no
Function/Variable nodes". The nix-config source was corrected this session but the running hook comes from the
built store path, so the stale steer SHIPS TO EVERY AGENT until a rebuild/switch. Tracked on den-hoag-4kh.9.
