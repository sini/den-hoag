# den-hoag-4kh.53.64 — [O1] the compat ops seam RECONCILED with 9xo.62: the consumer's DOMAIN (definition-time, per-fleet) does not contain the value it needs (firing-time, per site x node) — the ARITY is wrong; 7 options enumerated, O3/O4 knot through the ungoverned instance-arg channel

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.64` |
| status at evacuation | closed |
| priority | P0 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:15:00Z by Jason Bowman |
| last updated | 2026-08-02T16:32:07Z |
| closed | 2026-08-02T16:32:07Z |
| close reason | CLOSED on the 53.64 residue check (2026-08-02 at 3591f8c, orchestrator-executed verdicts). THE ARITY DEFECT IS DISCHARGED BY CONSTRUCTION, in the opposite shape from the option list's suggestion: the consumer's domain was NOT widened (opsOf = v: v.ops or [ ] unchanged, concern-policies.nix:121) — the firing-time per-site×node value was made UNEXPRESSIBLE on the commitment route: (1) authored typed TOTAL surface den.policyCodomains (surface-keys.nix, codomainRecord = true, totality on BOTH entry paths — option type + policyCodomainNotTotal for compile-direct); (2) declaration gate declaresCommitOf over the DECLARED codomain only, recovery excluded from the gate's input by construction (compile.nix:291-295, 316-321); (3) definition-time fire ONCE at a throwing sentinel (recoverCommitments + commitmentSentinel, policy-recover.nix:238-302 — a commitment-building coordinate read aborts NAMED via codomainValueConditional instead of seeding empty). Resolved fork: O6 in the O6-C form, NOT the enumerated O6 (ctxKeyStrata still { } at both production sites; policy-recover.nix:256 verbatim 'no node, no stratum index, no dispatch' — den-hoag-9xo.59 stays live and is NO LONGER O6's enabler). The body's central narrowed claim is REFUTED at HEAD: two live ops producers in compat (compile.nix:1523 mintFleetWide, :372 familyStamps; control emits= → 11 files). Dead letters: isSiteMarkData gone from the kernel (0 hits, control kindOf fires — the Construct I/II boundary the body defines by it no longer exists); opsInBody retired (3 past-tense prose hits); the mixed-record split handled by two modes off one record (commitFn once at mint, marks per node). O3/O4 knot NEVER ENTERED: quirkDag has ZERO hits in lib/compat/ (tree-wide control 4 files) — the ungoverned channel itself remains den-hoag-vyn's. Suite 2287/2287 EXIT 0 re-verified by the scout's own unpiped run; xfail census has zero den-behavioral rows. Carry-forwards homed BEFORE this close: den-hoag-mhgf (produces-by-name interim row migration now DUE + §13 Q1 with the 20-vs-29 figure correction). dcx blocking edge MOVED to 9xo.75 (what dcx needed here landed; the gate residue is document work on that lane). |
| description bytes | 170644 |
| notes bytes | 0 |
| comments | 51 |
| dependencies | `None` (None), `None` (None), `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★★ SETTLED 2026-08-01, later same session (supersedes the in-flight tail of the RE-ANCHOR block below; survivor pass complete, papers pushed 2ccda59..a84defd): r17-fix SHIPPED (afd52cf core, a84defd ledger+register; spec md5 6eb8221fe443d7e5c5a9b770d8f4253d @ 4611 lines, ledger c5e06d986a79344c4b90a7d6bfb9e8d4 @ 2951, register be1006157c3afaa572f344436103f3a1 @ 958; register 190 pass / 0 drift / 7 skip EXIT 0 from a clean archive of the pushed commit). ★ THE TWO-CLEAN-ROUNDS STREAK QUESTION IS VOID — ledger :553: the gate's "clean round 1 of 2" exit framing is void per the no-auto-settle ruling; rounds are uncapped, and :682 records that thirteen reading rounds including a clean one missed what one implementer found. THE ARC'S ACTUAL FORWARD STATE IS THE ACCEPTANCE-DEBT LEDGER: THREE → ONE at r16; the survivor is the localKeys debt on the composed-channel arm, "blocked on another defect — the derived-channel path is red — and discharges when that path goes green" (core:4295). ⇒ NEXT IS NOT A READING ROUND — IT IS THE SEAM IMPLEMENTATION MAKING THE DERIVED-CHANNEL PATH GREEN. IC-1 (the `?` attr-path fences constant-in-the-element — the shadow refusal failing OPEN silently at six sites) is DISCHARGED in spec AND code, independently gate-verified (ledger :1099 "complete in the spec AND in the code"), regression-mechanized by the register's three-region `? k)` SUM row. THE IMPLEMENTATION LANE IS ON MAIN, NOT STRANDED: ci/tests/channel-binding-siblings.nix (550 lines at 24c3603), history 21e45e0 → 5d6923c → ba2b3cc → 0f9f316; implementation commits bill to den-hoag-dcx; rulings recorded on THIS bead 2026-08-01 (ledger :681). CORPUS NOTE: nix-config 0d74319d (the parity pin as of den-hoag 24c3603) carries the records class (__isPolicy 0→5, emits 0→3, binds 1→2) — the corpus-side half of the seam is MERGED; parity is STRUCTURALLY BLIND to the corpus (den-hoag-4l0), so only the ci suite and the ship-gate observe the seam.
★★ RE-ANCHOR 2026-08-01 (session 7, orchestrator, cells re-run before filing): THE ROUND-10 GATE REPORT AT THE TAIL OF THIS BODY IS 5+ ROUNDS STALE, and its closing work order "NEXT: ROUND 11-FIX" is DISCHARGED — DO NOT RE-DISPATCH IT (it was re-dispatched once from this body on 2026-08-01; the author's stop-check caught it). Rounds 11-fix through 16-fix are SHIPPED in papers (git log -- specs/2026-07-31-compat-ops-seam-design-spec.{md,ledger.md,register.sh}: 699a697 r11, 4547777 r12, f7102a7 r13, b3045d9+2da287a+4d88280 r14, af3f267+97dc978 r15, 34a83b2+5e992a5 r16). Artifact after round 16-fix: md5 463e7cf3233d345c18933a98afecd5dd, 4608 lines (progression recorded at ledger line 1320). ★ THE LEDGER (specs/2026-07-31-compat-ops-seam-design-spec.ledger.md) IS THE AUTHORITATIVE ROUND STATE; this body carries checkpoints only and decayed exactly the way den-hoag-4kh.17 predicts for tail-anchored NEXT lines. GATE STREAK AS RELAYED (verify in ledger before load-bearing use): round 13 CONSTRUCTION-CLEAN; round 14 was IMPLEMENTATION CONTACT and found IC-1 (a construction defect, addressed with IC-2 in the round-14-fix commits b3045d9/2da287a/4d88280 per their messages) — so the two-clean-rounds gate-exit streak RESET at r14; current streak state is being extracted from the ledger (survivor-verification pass in flight 2026-08-01, which also re-verifies the round-11 F-items against the r16 artifact; one confirmed survivor: core cites lib/fleet.nix:112 for leafEntry, binding is :129 at 6dc4d44 AND 88ca026).
RE-ANCHOR 2026-07-30 at b2586e6 (den-hoag-66t settlement scout, read-only, orchestrator-recorded; full settlement in den-hoag-66t's close record). THE HEADLINE IS STALE: "built and never applied" is FALSE for the declared-`ops` route at HEAD. Application IS wired: lib/default.nix:1541-1555 — pipeTerminals (:1541), pipeChannelOps via pipeChainOf p.derived + honorWholeList (:1542-1544), pipeRouteOps = concatMap (p: p.routes or [ ]) (:1551) — all feeding concernQuirks.compose { policyOps = [ demandChannel ] ++ pipeChannelOps ++ pipeRouteOps; } (:1552-1555), with derivedBaseNames (:1566-1576) THROWING if a terminal id resolves to no composed channel — a live consumption oracle. The in-tree comment at :1473 states it: "CONSUMED, where before it compiled but never reached the fold."

WHAT IS ACTUALLY MISSING, NARROWER: nothing populates a POLICY RECORD's `ops` from compat. Policy-record minting at lib/compat/compile.nix:192 and :1248 sets emits/gate/fn/selects and NO ops (positive control same run: `emits = ` grep hit 8 sites). The only `ops =` in lib/compat/ is pipe.nix:262's `ops = q.ops or [ ]` — the den.quirks channel-registration pass-through, a DIFFERENT seam (concern-quirks). So the wired application receives an empty seed: lib/concern-policies.nix `pipeOps = prelude.concatMap (r: r.ops) rules` (:519, not :512), with `opsOf = v: v.ops or [ ]` (:104). The measured-empty pipe-consume reds (den-hoag-gb9) are this seed observed from the test side.
★★ CORRECTION 2026-07-30 — "UNIVERSALLY empty" IS REFUTED AND THE NARROWER STATEMENT CHANGES THE FORK.
NATIVE, hand-written policy records DO carry `ops`, with live green witnesses: ci/tests/silent-deletion.nix
`ops = [ composeOp ]` (:141, inside test-empty-head-keeps-its-fleet-ops, which asserts `.pipeOps == [ composeOp ]`
— the declared-ops path end to end) and ci/tests/compat-compile-golden.nix `ops = opChain deferredPipeOp.derived`
(:578). VERIFIED AT HEAD b0f40de. The correct statement is: **NO COMPAT-COMPILED RECORD EVER CARRIES `ops`, so
the seed is empty for every fleet whose policies arrive through the shim** — and the compat side of that is
confirmed exactly, `ops = ` over lib/compat/ hits EXACTLY ONE site, pipe.nix:273's quirks pass-through.
⇒ THE DECLARED-OPS ROUTE IS NOT DEAD CODE AWAITING ITS FIRST PRODUCER. It has passing tests. Any option that
DELETES the static field is deleting a path with existing green witnesses, not an unbuilt one, and owes those
tests a disposition.

★★ CORRECTION 2026-07-30 — THE ABORT IS **BOTH**, AND THE EXCLUSIVE DISJUNCTION BELOW IS REFUTED. Measured
by reader census with a control: `derived` and `routes` have ZERO per-node readers — every non-guard reader
(`isUntargetedDeriving`, `pipeRouteOps`, and the pipeTerminals/pipeChannelOps feeds) is FLEET-level over
`policiesRules.pipeOps`, i.e. the declared path. POSITIVE CONTROL, same predicate family same run: `.marks`
finds THREE per-node readers, all reached via `collectionDeclsAt result nid` (gather.nix `exposeChannelsAt`,
`collectMarksAt`, `broadcastMarksAt`). So the predicate CAN find per-node readers of a pipeOp field; it finds
none for derived/routes.
⇒ AS A SPEC it is a real partition invariant — each pipeOp field must be consumed on exactly ONE route, and
every option must preserve that. ⇒ AS SHIPPED CODE its only reachable effect is converting a SILENT DROP into
a NAMED ABORT, which is what errors.nix itself says ("aborts HERE rather than being silently dropped from a
seed that never received it"). It retires the instant a per-node consumer exists. Both readings are load-bearing
and the original sentence below forced a false choice between them.
★ ALSO: the guard predicate is a FOUR-term conjunction (declarations.nix:182-187) — `kindOf == "pipeOp"` ∧
`marks != [ ]` ∧ `!derived.__derived` ∧ `routes == [ ]` — so a MARKLESS pipeOp aborts too. The phrasing below
is right; its cited range clips a term.

ORIGINAL SENTENCE, KEPT FOR THE RECORD: THE ABORT IS A PARTITION INVARIANT, NOT A PLACEHOLDER FOR THE MISSING CONSUMER: conformingProduce (lib/concern-policies.nix:406) tests every emitted decl at every FIRING and aborts errors.opsInBody (lib/errors.nix:294-296) on `pipeOp && !declare.isSiteMarkData` (lib/declarations.nix:182-186). It fires WITH application wired — compat emits pipe results from the policy BODY (compilePipe, lib/compat/pipe.nix:269 returning { derived; routes; marks; } at :352-361), the route the invariant forbids. errors.nix:285-292 records why the body route cannot simply be admitted: `ops` is not ctx-independent (9xo.62's measurement) — the compose seed's construction is wrong UPSTREAM of the shim. This CONFIRMS the original body's closing paragraph; the 9xo.62 reconciliation remains the design fork this bead gates on.

★★ CONSTRUCT MEMBERSHIP — THE SPLIT BELOW IS STALE; RE-CENSUSED AT HEAD b0f40de 2026-07-30. `run-wiring`
markers: pipe-policy.nix 7 + pipe-scope.nix 2 = **9 PARKED, NOT 15**. Classification by the guard predicate
over each commented body (DERIVED, not executed — a read-only pass cannot arm a commented test):
CONSTRUCT I — **8**: pipe-policy test-pipe-multiple-from (:356), test-pipe-to-aspect (:598),
test-pipe-to-same-aspect-concat (:664), test-pipe-to-with-untargeted (:723), test-pipe-as-with-collect (:964,
★ a MIXED single record — mark ∧ derived ∧ route), test-pipe-as-self-error (:1168, ★ BARE `as`: no deriving
stage, so it aborts on the `routes != [ ]` ∧ `marks == [ ]` terms — a DISTINCT sub-shape);
pipe-scope test-pipe-expose-with-transform (:81), test-pipe-collect-filter (:374).
CONSTRUCT II — **1**, not 6: pipe-policy test-pipe-append (:147).
den-hoag-4kh.36's re-anchor is the accurate record; this bead's 9-of-15 / 6-II reading is superseded.
CONFIRMED from 4kh.36: test-pipe-from-ref (the vhn mislabel) is ARMED at HEAD (pipe-policy.nix:804) and out
of the parked set.
★ THE ☢️ COUNT IS UNVERIFIED AT HEAD. "12 den-pipe ☢️ aborts" is carried from b2586e6 across 51 commits and
the suite was not run. The MECHANISM carries — `git diff b2586e6..HEAD` shows `isSiteMarkData` and compilePipe's
return record BYTE-UNCHANGED — but two edits matter: `errors.opsInBody name` became `errors.opsInBody
originName name` (★ THE ABORT'S RENDERED TEXT CHANGED, so any message-regex expectation may have moved), and a
new named refusal `errors.pipeAsTargetNotAName` was added on a non-string `pipe.as` target.
DOES FIXING CONSTRUCT I TOUCH CONSTRUCT II? No — under every option except O3. Construct II's defect is that
`append`'s marks have no per-node consumer, entirely downstream of `collectionDeclsAt`, independent of where
derived/routes come from. ★ EXCEPTION: O3 retires `isSiteMarkData`, which is the predicate DEFINING the I/II
boundary — under O3 alone the two constructs stop being separable.

════ ORIGINAL BODY (2026-07-28; the quoted pipe.nix header remains accurate for the SITE-MARK stages — its generalization to the whole op DAG is what went stale) ════

[O1] ARGUED, AND IT EXPLAINS A KNOWN TRACKER ITEM. THE COMPAT PIPE OPERATOR DAG IS BUILT
AND NEVER APPLIED. `lib/compat/pipe.nix` STATES IT:
"the delivery (to/as) and site (append/expose/broadcast/collect/collectAll/withProvenance)
stages ride as INERT MARKERS the emission/consumption site interprets. NOTHING is forced
(Law C2, NO EFFECT RUNTIME): THE OP DAG IS BUILT FROM THE STAGE CLOSURES WITHOUT EVER
APPLYING THEM."
Consistent with the tracker's record of 15 commented-out wrong-value divergences and a
green suite (den-hoag-4kh.36).
★ TWO THINGS TO KNOW BEFORE SCOPING IT:
· `append` AND `to` ARE NOT GEN-PIPE EXPORTS -- they are v1 pipe VERBS, so the shim's job is
  TRANSLATING them, and THE TRANSLATION STOPS AT DAG CONSTRUCTION.
· ★ GEN-PIPE ITSELF IS PROPERLY LEVERAGED IN THE KERNEL -- `concern-quirks.nix` is 146 lines
  routing through `gen-pipe.compose`, with its header stating the channel algebra lives in
  the library.
⇒ ★★ NO MISSING GEN PRIMITIVE WOULD FIX THIS. IT IS DEN-HOAG COMPAT WORK. Do not file it as
a gen gap; the audit's corrections ledger records "gen-pipe is under-leveraged" as WRONG for
the kernel.
★ RELATES TO den-hoag-9xo.62 (the `ops` gate, REJECTED): that rejection established `ops` is
NOT ctx-independent, so the compose seed's construction is wrong UPSTREAM of the shim.
Reconcile the two before designing either -- they are the same seam from opposite ends.

════ ★★ CONDITION 5 IS DISCHARGED AND THE den-hoag-vyn BLOCKING EDGE IS DROPPED (2026-07-30, HEAD b0f40de) ════

THIS BEAD WAS BLOCKED ON den-hoag-vyn. THAT EDGE IS RETIRED. Condition 5's discharge was stated over
`readsAttrs`; the r-round record on this bead already REPLACED it ("Condition 5 cannot be discharged by ANY
statement over readsAttrs. State it over lib/default.nix's let-scope") and gave the constructive form:
**THE KNOT IS WELL-FOUNDED IFF `policiesRules` STAYS quirkDag-FREE** — state the invariant over WHICH
lib/default.nix LET-BINDINGS AN ATTRIBUTE'S INSTANCE ARGS MAY CAPTURE. That replacement does not require
anything in vyn to be fixed, so vyn is not a blocker; it is context.

★ WHAT WAS ASSERTED THERE IS NOW MEASURED, WITH EXIT CODES (executed 2026-07-30 in an isolated worktree at
b0f40de; full apparatus and controls on den-hoag-vyn). The record said the residual "is an uncatchable
infinite recursion and must be prevented structurally". Both halves now have executed evidence:
· ONE cycle, TWO spellings, run on gen-resolve's lock AND rebuilt through den-hoag's substrate on den-hoag's
  flake.lock (different transitive gen-scope revs) — identical both times.
  DECLARED-ATTRIBUTE spelling: EXIT=1, gate FIRED, `SCC(s) contain non-'circular' attrs: [["a"]]`, and
  `(tryEval (deepSeq v true)).success` → EXIT=0 value `false` — CATCHABLE.
  INSTANCE-ARG spelling, same cycle: EXIT=1, `error: infinite recursion encountered`, no gate, unattributed;
  `(tryEval (deepSeq v true)).success` → EXIT=1, ABORTS. `(tryEval v).success` → EXIT=1. NOT CATCHABLE.
· ★★ THE DECISIVE ARM: `builtins.seq ctxB.schedule ...` → **EXIT=0**, with
  `ctxB.schedule.condensation.sccs = [["b"],["children"],["imports"]]` and `ctxB.schedule.edges "b" = []`.
  **THE GATE RAN, ANALYSED A REAL 3-NODE GRAPH, AND PASSED WHILE THE CYCLE WAS LIVE.** It is not a fixture
  that skipped the check — the check executed and reported success on a graph it cannot see.
· AND THE DECLARATION CHANNEL CANNOT BE MADE TO SEE IT: declaring the real instance-arg names
  `policiesIndex`, `isCellNode`, `linkTarget` in a `readsAttrs` → EXIT=0, silently dropped (gen-resolve's
  schedule filters `builtins.filter (b: equations ? ${b})`). A ONE-CHARACTER typo of a real attribute name →
  EXIT=0. Control, same line, correct spelling → EXIT=1.

⇒ FOR THIS BEAD'S DESIGN THE CONSEQUENCE IS DIRECTIONAL AND FIRM: any knot routed through an INSTANCE ARG is
outside every available guard and fails in the worst mode. It must be prevented by CONSTRUCTION — the
let-scope capture invariant above — never by a probe, a `tryEval` wrapper, or a `readsAttrs` statement.
A design that argues its safety FROM the schedule gate is arguing from an instrument measured blind to
exactly its hazard class.

★ NOTE FOR ANY RE-VERIFIER: den-hoag UNDER-DECLARES NOTHING. A census of all 19 live equations cross-checked
every compute-internal `self.get` against its `readsAttrs` and found every one declared. An earlier claim
that three attributes read their own name undeclared is REFUTED — those were terminal reads through the final
eval, found by a file-level predicate that could not tell a compute read from a terminal one. The defect is
the analysis's SCOPE, not den-hoag's compliance.


════════════════════════════════════════════════════════════════════════════════════════════════
★★★ THE 9xo.62 RECONCILIATION — DONE 2026-07-30 AT HEAD b0f40de. This bead said it "gates on" this
reconciliation and nobody had performed it. Read-only, source-read + git + grep, anchored by expression.
════════════════════════════════════════════════════════════════════════════════════════════════

★★ THE JOINT STATEMENT, AND IT IS NEITHER BEAD'S. The two ends meet at ONE FIELD, `v.ops` — read at `opsOf`
(concern-policies.nix:104), stamped at `ops = opsOf v` (:466), folded at `pipeOps` (:519). This bead says that
field is always empty through compat; 9xo.62 says it cannot be anything else.
⇒ THIS IS NOT AN UNWIRED CONSUMER WITH A MISSING PRODUCER. It is **a consumer whose declared DOMAIN
(definition-time record data, one list per fleet) does not contain the value it needs (firing-time data,
indexed by declaration-site × node). THE ARITY IS WRONG, not merely the content.** Emptiness and unfillability
are two projections of that one mismatch — which is exactly why neither end could be designed alone.

WHAT "ops IS NOT CTX-INDEPENDENT" MEANS MECHANICALLY (the slogan, now with bindings):
compile.nix `prelude.imap0 (translateEffect ...) (innerFn value ctx)` — THE EFFECT LIST IS THE RETURN VALUE OF
FIRING THE BODY WITH ctx → `pipeLib.compilePipe` → compat/pipe.nix `stageOp`, where transform yields
`apply = declare.pipe.map stage.fn` and **`stage.fn` IS THE BODY'S OWN CLOSURE**, having captured ctx.
WHICH ctx: the per-node dispatch context at structural.nix `ctx0 = (self.get id "enriched-context") // {
suppressedPolicies = self.get id "suppressed-policies"; }` — both feeds are PER-NODE gen-resolve attributes.
WHEN available: only inside the `declarations` equation's `compute self id`. There is no earlier point.
EARLIEST CONSTRUCTIBLE POINT for a complete op = that same per-node firing = exactly the route
`conformingProduce` forbids. The seed's construction site (`quirkDag`, default.nix:1552) is a fleet-level
`let` binding with NO NODE IN SCOPE. That is the mismatch stated as coordinates.
★ THE CORPUS COUNTEREXAMPLE SURVIVED A CORPUS REV CHANGE: nix-config is now 425f1d3b (9xo.62 cited 9ebf3316)
and modules/den/policies/pipes.nix still reads `{ user, ... }: let srcUser = user.name; in [ (pipe.from
"replicateHome" [ (pipe.transform (entry: { user = srcUser; ... })) (pipe.broadcast ...) ]) ]`.
★ THE RECORD UNDERSTATES ITSELF TWICE:
(a) It is not only the stage FUNCTION. `pipe.from` takes the channel name and the stage list as ordinary body
    values — NOTHING CONSTRAINS A BODY FROM COMPUTING THE CHANNEL NAME, THE STAGE LIST, OR A ROUTE TARGET
    FROM ctx. The "shape is ctx-independent" premise under every shape/payload split is an UNENFORCED
    EXPECTATION, true of today's corpus by accident, not by construction.
(b) NOTHING NARROWS THE ctx TODAY. A9's `projectCtx` (concern-policies.nix:366-382) would restrict a
    collection-stratum body to facts at or below its stratum, but `ctxKeyStrata = { }` at default.nix:1450,
    so **projectCtx is the IDENTITY for every shipped rule**. The ctx-dependence is unconstrained BY
    CONFIGURATION, not by nature. ⇒ TRACKED: den-hoag-9xo.59 (OPEN P1, "the stratum instrumentation is
    vacuous in production: ctxKeyStrata is empty at every non-test call site") IS THE ENABLER FOR O6.
★ AND A CONSTRAINT NEITHER BEAD MADE EXPLICIT: the corpus policy is a MIXED RECORD — one pipeOp carrying a
deriving DAG (ops-eligible) AND a `broadcast` site mark (per-node, banned from ops). Parked fixture
test-pipe-as-with-collect is the same shape. ⇒ ANY OPTION ROUTING `derived` BY DECLARATION AND `marks` BY BODY
MUST SPLIT ONE compilePipe RECORD ACROSS TWO ROUTES. This discriminates the options more sharply than anything
else measured here.

════ THE STRUCTURALLY DISTINCT JOINS — characterised, DELIBERATELY NOT RANKED ════
Axes: WHERE the op record is produced (definition-time vs per-node firing) × WHERE the fleet DAG is built
(definition-time seed / query over emissions / per-node) × what happens to the ctx-dependence itself.

O1 STATIC RECOVERY WITHOUT FIRING — analyse the unfired v1 body. REFUTED, record it so it is not re-proposed:
   six instruments plus a 118-builtin sweep discriminate no two behaviourally-different closures;
   `unsafeGetAttrPos`+`readFile` recovers SOURCE TEXT only and cannot see a computed name. 9xo.62's candidates
   A/B/C all live in this class. CONSTRUCTION if it worked; it cannot work.
O2 RECOVERY BY ONE FIRING — fire once at a chosen ctx, lift into `ops`. Violates 9xo.62's measurement
   (opsAtAlice ≠ opsAtBob): wrong at every node but one, SILENTLY, since `ops` has no funnel. ★ REPAIR WITH NO
   REPAIR STEP — the bad intermediate forms and there is no correction stage at all. Trap: a v1 body is a
   `ctx:` wrapper with EMPTY formals, so recovery must use the DECLARED gate, never `functionArgs`.
O3 PER-NODE DECLARATION + FLEET QUERY — delete the static field; a pipeOp becomes a per-node collection-stratum
   declaration like site marks already are; the fleet DAG becomes a query over emitted declarations. Under it
   9xo.62's question is NOT ANSWERED — IT IS NOT ASKED, because the op comes from real firing. Handles the
   MIXED record for free. Requires a per-site agreement guard replacing `opsInBody`, and a stable site identity
   (`__kindInclude__<kind>__policy__<i>` is a POSITIONAL index into a module-merged list — measured brittle).
   MIXED construction/repair BY ITS OWN GATES: deleting the field is construction; the agreement guard, carrier
   roster and key-set pins are repair ("pinning deeper does not convert a repair into a construction").
   ★ Retires `isSiteMarkData` and therefore the I/II boundary. ★ Deletes a path with LIVE GREEN TESTS (above).
   ★★ Q7 APPLIES.
O4 TWO ROUTES INTO ONE COMPOSE — keep `ops` for native records, also feed compose from body emissions, replace
   the partition abort with an agreement law over a shared key. REPAIR BY DEFINITION: both routes produce, the
   duplicate forms, a key corrects it. Only option preserving the currently-wired path untouched and the only
   one under which the declared-ops path's existing green tests keep their meaning unchanged. Must split the
   MIXED record. ★★ Q7 APPLIES.
O5 PER-NODE COMPOSE — retire the one-fleet-compose law, compose per node from that node's own emissions.
   Forbids fleet-wide channel-name uniqueness (E4b) and reference closure (E4a), which default.nix:1465-1468
   states as the REASON THE SEAM EXISTS. ★ CORRECTED 2026-07-31 (gen-pipe scout, section below): "cannot
   express a route whose source and target are at different nodes" is TRUE OF THE CURRENT FLEET COMPOSE TOO —
   gen-pipe delivery edges are same-position only (`deliverSeq = edge: p: let src = seqAt edge.from p;`);
   cross-node reach comes entirely from `traversal.order p`. What O5 actually loses is fleet-wide
   NAMING/CLOSURE (E4a/E4b + stable declIndex-embedded channel names, which go NODE-DEPENDENT under per-node
   decls lists), not cross-node delivery. Construction w.r.t. ctx, but it achieves
   that by REMOVING the fleet-wide property rather than preserving it — a narrowing of the domain in which the
   defect is statable, not a correction of it. Bound: den-hoag has ONE `pipe.compose` and TWO `pipe.run` sites
   (re-confirmed at 2e44ff5, refined below: both runs bind the SAME dag, one per-node, one fleet-level with no
   node in scope).
O6 NARROW THE ctx — ★ NEITHER BEAD ENUMERATED THIS. Make `ops` ctx-independent BY CONSTRUCTION rather than by
   assertion: populate `ctxKeyStrata` so a collection-stratum body may read only fleet-level facts, and fire
   pipeOp bodies once per DECLARATION SITE rather than per node. The machinery EXISTS AND IS INERT
   (projectCtx replaces an above-stratum key with a NAMED CATCHABLE throw). CONSTRUCTION — the ctx-dependent op
   becomes UNEXPRESSIBLE, loudly, at the surface. Forbids `user.name` inside a pipe stage, so it REJECTS
   broadcast-syncthing-hub-shares as written. ★ IT IS THE ONLY OPTION THAT MAKES THE POLICY-RECORD SPEC'S OWN
   PREMISE TRUE INSTEAD OF RETIRING IT. 9xo.62's rejection scope ("kills any design making ops a STATIC FIELD")
   DOES NOT REACH IT — O6 changes what a body may READ, not what the field may HOLD. Enabler: den-hoag-9xo.59.
O7 REFUSE — a deriving/route v1 pipe becomes a permanent named compat ceiling; the corpus rewrites.
   Construction by refusal. Violates 9xo's parity bar and the works-on-den gate (axon-01 and cortex abort on
   exactly this while the corpus's pinned v1 builds exit 0). Enumerated because it is the null option that
   makes the others' cost legible.

════ ★★ Q7 — THE SAFETY DIFFERENTIATOR, IN NEITHER BEAD ════
`quirkDag` is an INSTANCE ARG of `attributes` (attributes/default.nix:139), passed ONLY to `collections`
(:189-197); `structural` does not receive it and structural.nix has ZERO textual `quirkDag` references
(positive control same run: lib/default.nix has 10). Direct capture is excluded BY LEXICAL SCOPE. But quirkDag
sits in ONE RECURSIVE `let` (default.nix:424 → `in` at :2566) alongside prePass, fleetChildren, linkTarget,
policiesRules and policiesIndex — Nix `let` is recursive, so textual order proves nothing. Acyclic TODAY only
because `collections` reads quirkDag, quirkDag reads `policiesRules.pipeOps`, and `declarations` reads neither.
⇒ **O3 AND O4 INTRODUCE A KNOT THROUGH AN INSTANCE ARG.** Making compose a function of every node's
`declarations` puts quirkDag downstream of an equation whose compute calls `policiesIndex` unconditionally
(structural.nix:359) — quirkDag's own recursive-let sibling. Per den-hoag-vyn's executed apparatus that channel
is OUTSIDE EVERY AVAILABLE GUARD: the schedule gate RAN, analysed a real 3-node graph and PASSED while the
cycle was live; the failure is a raw `error: infinite recursion encountered`, unattributed and NOT catchable by
`tryEval`; and declaring an instance-arg name in `readsAttrs` is silently dropped at exit 0. **NEITHER OPTION'S
SAFETY CAN BE ESTABLISHED BY ANY AVAILABLE GUARD.** The constructive form the r-rounds reached — "the knot is
well-founded IFF `policiesRules` stays quirkDag-free", stated over WHICH lib/default.nix let-bindings an
attribute's instance args may capture — is the right shape, and its enforcement is SPECIFIED, NOT PROTOTYPED.
★ SUPERSEDED 2026-07-31: the closure IS NOW COMPUTED (see THE Q7 CLOSURE MEASUREMENT below). The invariant
HOLDS AT HEAD, with margin, and the "seven siblings" figure was wrong — the propagation obligation spans
EIGHT bindings ({policiesRules, prePass, ent, compiledStrata, indexFeed, theFleet, cellFamilies,
entryNodeIndex}) out of 162 mkDen-let siblings, 17 of which reach the attributes construction.
⇒ **O5 KNOTS THROUGH A GOVERNED CHANNEL INSTEAD** — `collections`(n) → `declarations`(n) is an
attribute→attribute edge, expressible in `readsAttrs`, INSIDE the schedule's jurisdiction, and its violation is
a NAMED CATCHABLE SCC. That is a real, measured safety difference between O5 and O3/O4.
⇒ O1, O2, O6, O7 introduce no new knot — the seed keeps reading definition-time data only and quirkDag's
dependency direction is unchanged.

════ COVERAGE OF THIS RECONCILIATION ════
The ci suite was NOT run. The Construct I/II classification is DERIVED from the guard predicate over each
commented body, not executed. The r1-r9 spec artefacts were not read — every claim attributed to them here is
second-hand from bead records. parity/, den v1, gen-pipe source, and den-configs beyond nix-config are
UNREACHED. The sibling quirkDag-freedom closure, formerly unreached, is now measured — next section.

════ ★★ THE Q7 CLOSURE MEASUREMENT — 2026-07-31 AT HEAD 2e44ff5 (read-only scout, source-read + git grep
with same-run positive controls; codebase-memory/LSP deliberately unused; orchestrator-recorded, scout
findings NOT independently re-derived by the orchestrator) ════

★★★ **policiesRules IS quirkDag-free TRANSITIVELY at HEAD — by EXHAUSTED FRONTIER, not "no path found".**
Full out-closure of policiesRules = {compiledStrata, reservedInsertOffenders, userStrataInserts,
relationStrataInserts, ent, denMeta, userModules, userModules0, synthCollectors, discoveredCollectors,
hasCollectors, the 34 *Decl bindings, denAspects, channelSet, discoveredChannels, discoveredClasses,
effectiveClassNames, effectiveClassEntries}. quirkDag ∉ it. Instrument: comment-stripped token sweep of the
ent-reachable region ∩ the 162-name sibling list; positive control same instrument same run over the
quirkDag region returned policiesRules/compiledStrata/quirkDag/quirks/policiesIndex. Four alarming survivors
individually EXHIBITED as false positives (three inside `description = "…"` string literals, two
`options.den.<name>` attribute paths) — `derivedBaseNames` was the one that mattered (it genuinely reaches
quirkDag via idToName); its hit is PROSE.

★★ **THE DEPENDENCY DIRECTION IS THE OPPOSITE OF THE FEARED ONE**: quirkDag → pipeChannelOps/pipeRouteOps →
policiesRules (`quirkDag = concernQuirks.compose { inherit quirks; policyOps = [ demandLib.demandChannel ]
++ pipeChannelOps ++ pipeRouteOps; }`, both feeds reading `policiesRules.pipeOps`). Acyclic. The knot is
well-founded by DEPENDENCY DIRECTION, not merely deferred by laziness.

TWO STRONGER RESULTS THE DESIGN MAY LEAN ON:
(a) **All THREE of structural's instance args are quirkDag-free** — policiesIndex, fleetChildren, linkTarget
    each close over {ent, policiesRules, prePass, indexFeed, compiledStrata, theFleet, cellFamilies,
    entryNodeIndex} and nothing else. The invariant holds WITH MARGIN.
(b) **Closed BY CONSTRUCTION, not by discipline**: every path bottoms out at `ent`, whose only non-sibling
    input is `userModules0` — mkDen's own lambda parameter. A user module CANNOT capture a mkDen let-binding,
    so no user config can route quirkDag back into policiesRules.

THE CAPTURE SURFACE (from the one distribution block, lib/attributes/default.nix formals + body, read in
full): collections.nix is the ONLY equation file that receives quirkDag (`(collections { inherit quirkDag
classOfNode channelNames consumerLib; … })` — sole distribution site). structural.nix receives
policiesIndex/fleetChildren/linkTarget, all quirkDag-free. resolved-aspects, class-modules,
resolution-relations, claim-accessor, concern-productions: none can capture it (a file cannot capture what
it is not passed). Non-equation surfaces mkOutputModules (`derivedBaseNames`, which DOES reach quirkDag via
idToName) and receivedOutputs (`dag = quirkDag`) sit OUTSIDE the knot — applied once over the FINAL eval.

CONTEXT-CLAIM VERDICTS: "quirkDag → collections only" CONFIRMED (exhaustive: `git grep -c -w quirkDag --
lib/` = 10 lines in lib/default.nix, all accounted; lib/attributes/ hits only collections.nix + the
distribution site). "structural.nix zero textual quirkDag refs" CONFIRMED (read in full, 482 lines; same-run
control policiesIndex → 4 lines same file). ★ "declarations' compute calls policiesIndex unconditionally"
CONFIRMED AND UNDERCOUNTS: TWO unconditional forcing sites — attr 4 `declarations` (`applicablePolicy =
policiesIndex.policy nodeKind;`) AND attr 2 `enrichments` (`applicableEnrich = policiesIndex.enrich
nodeKind;`, forced unconditionally via `converged`). ⇒ AN INVARIANT STATED OVER "WHICH EQUATIONS FORCE
policiesIndex" MUST NAME `enrichments` AS WELL AS `declarations`.

★ WHAT THIS CHANGES FOR THE OPTIONS: O3/O4's hazard is NOT that the knot is cyclic today — it is that they
would ADD the edge policiesRules→(per-node declarations)→quirkDag-sibling territory where no available guard
can see a cycle (vyn's executed apparatus). The design's obligation is now concrete: preserve the measured
acyclic direction over the EIGHT-binding domain above, by construction, and state it as the let-scope
capture invariant with this measurement as its baseline.

HAZARD FOUND EN ROUTE: `graph` at the mkDen let SHADOWS the outer-let `graph` (gen-graph library); the outer
let carries `genGraphLib = graph;` specifically to survive the shadow and inverseRelationEdges uses
`genGraphLib.transpose` for exactly that reason. Any option adding bindings to the mkDen let inherits this
trap.

SCOUT COVERAGE LIMITS (stated as limits, not hedges): lib/attributes/default.nix and structural.nix read in
full; lib/default.nix read in ranges covering all quirkDag/policiesRules/instance-arg territory;
familyOutputs (the largest binding) GREPPED ONLY — sound because the exhaustive 10-line quirkDag census has
no hit in its range and it is downstream of equations, never an argument; collections.nix bodies beyond
formals + two quirkDag use sites NOT read; other attribute-file bodies NOT read (capture table derives from
the distribution block, exhaustive over what each file CAN receive).

════ ★★ THE GEN-PIPE SEAM MEASUREMENT — 2026-07-31 AT den-hoag 2e44ff5 / gen-pipe 5350930 / den-v1 ecaefcb
(read-only scout, source-read + comment-stripped git-grep census with same-run positive controls;
orchestrator-recorded, not independently re-derived. ★ NOTHING WAS EVALUATED — laziness/forcing claims are
derived from source reading; consumption verdicts and the O5 bound are executed text measurements.) ════

This fills the "gen-pipe source UNREACHED" coverage hole. It is the C7-a reuse-scan for any design here.

★ EXPORT ROSTER — 17 EXPORTS, EXHAUSTIVE (gen-pipe lib/default.nix `in { … }` block read in full; errors/
helpers/view/validateMerge/defaultCombine/isDeferred/poison/resolveTag are internal, never re-exported).
CONSUMED BY den-hoag (11): channel, contribute, deferred, map, filter, fold, over, route, compose, run,
consume. NOT CONSUMED (6): scan/join/tee (re-exported at declare.pipe, lib/declarations.nix, ZERO call
sites), provenanceOf/traceOf/sel (not even re-exported; den-hoag binds gen-select directly — 31 non-comment
`sel.` uses). Control: same census same run returned nine non-zero pipe.* hits. ★ `pipe` is name-OVERLOADED
in den-hoag (gen-pipe lib in kernel vs v1 verb bag in ci/tests/den-behavioral/) — raw `pipe.filter` count 25
collapses to ONE real gen-pipe consumer; disambiguate by call site in any re-census.

THE COMPOSE SEAM (concern-quirks.nix is **111 lines at HEAD, not 146** — the ORIGINAL BODY's figure is
stale): hands compose `channelDecls ++ opDecls ++ policyOps` in ONE expression; compose discriminates per
element by tag only (`__genPipeChannel` / `__genPipeOp`). ★ `policyOps` IS A MISNOMER — pipeChannelOps are
derived CHANNELS, not ops. compose's deepSeq guards force STRUCTURE ONLY (ids, final names, merge/class/
adapter validation), NEVER `__derive.f` — Law C2 holds by construction, not convention.

★★ THE MIXED-RECORD SPLIT, ANSWERED: a compilePipe record CAN be partitioned into (derived-only, marks-only)
without firing any STAGE body — `byRole` forces only `stageOp`'s `.role` read (`k = stage.__pipeStage or
null`) plus ONE eager throw (`pipeAsTargetNotAName`, deliberately compile-time); apply/mark stay thunks. BUT
the record CANNOT exist before firing the POLICY body — compilePipe is reachable only from translateEffect,
applied to `(innerFn value ctx)` / `(value.fn ctx)`, so WHICH ROLES EXIST is ctx-dependent, and flattenBase
branches on `derives == [ ]` so even the flatten root's existence is partition-dependent. ⇒ ANY OPTION
ROUTING `derived` BY DECLARATION MUST OBTAIN IT FROM SOMETHING OTHER THAN compilePipe. ★ THE ASYMMETRY WORTH
DESIGNING ON: the chain's IDENTITY is ctx-independent while its MEMBERSHIP is not — `site =
"${policyId}-${toString effectIdx}"` is built from compilePipe's ARGUMENTS, id-stacked to every depth;
derived-channel ids are STABLE ACROSS NODES, the SET of them is not.

O3/O4's UNGOVERNED FORCING SITE, OBSERVED: lib/attributes/collections.nix `pipe.run { dag = quirkDag; … }`
sits inside `compute = self: id:` with `readsAttrs = [ "neron-order" "local-collection-data" ]` — quirkDag
arrives as an INSTANCE ARG and STRUCTURALLY CANNOT appear in readsAttrs. This is Q7/vyn's channel at its
actual forcing site. O5 additionally: `run` binds ONE dag; no export accepts a position-indexed dag ⇒ O5
needs N runs or a new gen-pipe surface; and of the two run sites, one is per-node (collections, in-flight
self) and one is FLEET-LEVEL WITH NO NODE IN SCOPE (default.nix, final eval, explicit traversal-adapter
drift note) — O5 has one site where a per-node dag is even expressible.

V1 SEMANTICS THE OPTIONS MUST REPRODUCE OR REFUSE (cited by expression in the scout run):
· `append` — injects a LITERAL into the running value list AT THE FIRING SITE, POSITIONALLY LAST
  (`values ++ [ (seed stage.value) ]`, assemble-pipes.nix), untagged on the plain path; ordering relative to
  base is OBSERVABLE. ★ NOT A GEN GAP — `contribute` is already the right primitive; Construct II is den-hoag
  WIRING (no per-node consumer of the `__pipeMark = "append"` mark).
· `to` — resolves targets to FULL IDENTITY PATHKEYS, routes into `pipeTargeted : { aspectName → { pipeName →
  values } }`, consumed at MODULE-WRAP GRAIN as a per-aspect ctx OVERRIDE (attrset REPLACEMENT, not merge) at
  wrap-classes.nix. A per-aspect override is not a channel delivery; whether it belongs in gen-pipe at all is
  a design question, not a gap by default.

GEN-PIPE GAPS (measured-absent against the 17-export control set; ★ ONLY these three would change the
standing "no missing gen primitive would fix this" verdict, and all three are needed only by O3/O4/O5):
1. no position-parameterised compose/run; 2. no dag extension/merge (adding a decl recomposes the full list,
renumbering declIndex ⇒ RENAMING derived channels — bites O3/O4); 3. no collision report on compose's
silently-first-wins id-dedup (`if acc.byId ? ${ch.id} then go rest acc`) — O4's "agreement law over a shared
key" has NO gen-pipe instrument to build on (control: the E4a/E4b/E2/E2b/E3 throw class exists in the same
function). Latent, not option-blocking: `over` has no per-element identity hook (synthetic producer hardcoded
⇒ identity-deduped targets would collapse distinct flattened elements; den-hoag names it at compat/pipe.nix);
`isDeferred` internal (den-hoag re-implements as isConfigThunk).

SCOUT COVERAGE: gen-pipe 11 of 12 lib files + entry read in full (errors.nix grepped; its non-export
established from default.nix read in full); den-hoag concern-quirks.nix + compat/pipe.nix in full, key
ranges of default.nix/collections.nix/declarations.nix/compile.nix; v1 register-pipe-effect.nix in full +
assemble-pipes.nix/wrap-classes.nix in ranges. UNREACHED: gen-pipe README/REFERENCE, den-hoag parity/,
den-configs corpus. ci suites not run.

════ ★★ DESIGN ROUND 1 — O6-T SPEC + GATE VERDICT: REDESIGN (2026-07-31; round does NOT count toward the
two-clean-round exit) ════
ARTEFACT: papers/den-architecture/specs/2026-07-31-compat-ops-seam-design-spec.md, FROZEN at md5
`7e7d129e5b3d2f6e898f19ca9ce4ad0c`, 508 lines, UNCOMMITTED. Selection: O6 corrected form "O6-T" — fire a
commitment-bearing policy body ONCE at definition time against a TOTAL fleet ctx (every per-node key a named
throw); C-1 ctxKeyStrata REQUIRED+TOTAL with normalizing projection; C-2 kind `pipeOp` splits into DECLARED
pipeCommit/pipeMark (lands on register entry 2's RETIRING side — the value-shape isSiteMarkData conjunction
becomes a declared category, C9 hit found by reasoning); C-3 two firings one per route; C-4 provenance
instead of ctx capture. Theory: Knuth 1968 wrong-position attribute; ABW 1988 Def 3 condition 1 only
(P2 honestly marked VIOLATED-AT-HEAD — ctxKeyStratum fail-open `or null` makes the citation vacuous until
the design's first act); Reynolds informed-by-only.

GATE ROUND 1 (fresh): **REDESIGN.** S0 PASS · C2-a/C4/C7-b/C8/C9/C9-a PASS (C7-b and C9 called exemplary) ·
C1/C1-a/C3/C5/C6 FAIL · C7 partial · C7-a pass-form/fail-substance. THREE CONSTRUCTION DEFECTS:
1. ★★★ C-4 REFUTED BY SOURCE — gen-pipe threads provenance AROUND every value-producing operator, never
   INTO it: evaluate.nix `value = f c.value` (map :89; fold :164, scan :186, over :210, join.combine :257
   all apply to `map (c: c.value) seq`); provenance reaches only PREDICATE positions (filter's p, route's
   select, via viewOf). The cited `adapter.fn v c.provenance` is the CONSUME/class-coercion seam, not a
   stage seam (C5 fail). ⇒ broadcast-syncthing-hub-shares is NOT re-expressible under the design as
   written. ★ The spec diagnoses 53.64 as "the consumer's domain does not contain the value it needs", then
   its own remedy has that exact defect shape (C1-a).
2. ★★ POSITIONAL SITE IDENTITY vs NORMALIZED FLEET CTX — `site = "${policyId}-${toString effectIdx}"` where
   effectIdx indexes `(innerFn value ctx)`, THE FIRED BODY'S RETURN LIST; C-1 normalizes the fleet ctx's key
   set while C-3's node firing keeps the full per-node ctx, so a body branching on `ctx ? key`/attrNames
   returns different-shaped lists ⇒ same stage, different effectIdx, different derived-channel id; both-
   resolve-to-something mismatch is SILENT (derivedBaseNames only catches resolve-to-nothing). corpus has
   `lib.optionals`-shaped bodies; positional indices already recorded "measured brittle". No local edit.
   ★ NOTE FOR THE REDESIGN: gen-pipe HEAD 5350930 is literally "feat(operators): declaration-site
   derived-channel identity (site token, L12a)" — a declared (non-positional) site identity may already
   have library support; establish before re-designing identity.
3. ★★ C-2/C-1 CONTRADICTION — projectCtx is STRATUM-indexed (`projectCtx = ruleStratum: ctx:`); §2.2 puts
   BOTH new kinds at the collection stratum, so one stratum ⇒ one projected ctx, while the design needs a
   PER-ROUTE ctx. C-2's own rationale (dodging the stratum-spanning refusal) destroys C-1's route
   distinction. No local edit.
Plus stated-scope: mixed policy with ctx-conditional effect list has NO DEFINED BEHAVIOUR (C6; lib.optionals
forces eagerly at body application, aborting from the mark half the fleet firing should ignore — fixture A6
+ stated behaviour owed); trace/compile-time-throws observable twice under double firing (narrow "anything
observable" to "any consumed value").

★★ THE r9 RECONCILIATION, ADJUDICATED BY FULL READ OF r9's ENFORCEMENT SECTIONS (specs/
2026-07-29-ops-representation.md — a VALIDATED shape/payload-split design at this same seam; its internal
"O3" is an OBLIGATION label about quirkDag capture, NOT this bead's option O3 — name-collision is real,
local edit): the new spec's claim "r9's premise is unenforced and its divergence vanishes silently" is
REFUTED — r9 §3 property 5 runs shapeDisagreement INSIDE the single compose call ("throws its message
before handing the declarations to gen-pipe"), property 2 already pins broadcast-hub-peer's subset firing
BY NAME, and the r9 pass hardened classification to total incl. `targeted` with all four raw-read mutants
dying by name. ★ WHAT SURVIVES, NARROW AND REAL: r9 item 7 (:2405-2412) ADMITS one silent direction — "a key
classified SHAPE that is genuinely per-node payload … rides the first emitter's value onto every position.
No mechanism decides this." A ctx-narrowing design closes exactly that BY CONSTRUCTION (real C7 improvement
over runtime-guard-plus-admitted-residual). Correct statement: O6-family narrowing converts r9's runtime
shape guard and its one admitted residual into a by-construction property — NOT r9's missing precondition.

TWICE-DERIVED AND STANDING (gate re-derived independently, full read, stated predicate): corpus
modules/den/policies/pipes.nix = 16 policies, 15 pure site marks, EXACTLY ONE mixed commitment-bearing
(broadcast-syncthing-hub-shares: pipe.transform closing over `srcUser = user.name` + pipe.broadcast);
broadcast-syncthing-peers reads user.name only in a SITE-MARK broadcast predicate (unaffected by
narrowing); broadcast-hub-peer's effect-list membership is ctx-conditional (`lib.optionals (…isHub)`).
ALSO VERIFIED, MUST NOT REGRESS: A2 (`ops =` exactly one site in lib/compat/, control emits→11/6); the §7
green-witness discriminator (silent-deletion.nix:141, compat-compile-golden.nix:578 both live; O6-family
owes them nothing, O3 deletes a live-green path); §2.1's diagnosis of projectCtx (mapAttrs key-preserving +
`or null` fail-open + both production ctxKeyStrata = { }) CORRECT; provenanceOf/traceOf unconsumed (6 ci
hits all substring false positives); gen-pipe gap 3 first-wins dedup confirmed at compose.nix:66.
INSTRUMENT CORRECTION: ctxKeyStrata census is 13 lines (not 12); edge-substrate.nix populates 5 (its :597
is `= { }`).

★★★ PENDING OWNER RULING — NOW CONCRETE, BANKED HERE (was "anticipated" in the 2026-07-30 handoff). The
deriving-stage ctx-capture trade cannot be resolved by a spec author: the one commitment-bearing corpus
policy is NOT re-expressible under ctx narrowing (measured, defect 1 above), so the fork's arms are now:
 (i) gen-pipe surface change — value-producing operators receive the contribution (a NEW gap 4, beyond the
     three recorded; would change the standing "no missing gen primitive" verdict and needs its own
     high-bar validation);
 (ii) consumer-side rewrite — the hub consumer moves to `consume … mode = "records"` (which does carry
     contribution.provenance); touches nix-config, outside any den-hoag spec's costed scope;
 (iii) permanent named compat ceiling for the class "deriving stage reads dispatch ctx" — one measured
     policy, violates the parity bar knowingly;
 (iv) a different option family entirely (O3/O4 with the r9 instruments — but then defect classes Q7 and
     the positional-identity brittleness re-price).
The design's own stated trigger: USER-GUIDED SPIKE. A redesign round MAY proceed meanwhile on defects 2+3
and the r9-narrow rebase, carrying this fork as a dedicated owner section with all four arms costed —
selection of an arm is the owner's, not the author's.

════ ★★ DESIGN ROUND 2 — O6-S ("stratified"), GATE ROUND 2 PENDING (2026-07-31) ════
ARTEFACT: same path, FROZEN at md5 `85b28e83ae0e47043dd6aa82025a1c09`, 915 lines (was 508). Selection
renamed O6-T → O6-S — the refuted component is the one that changed.
· DEFECT 3 RESOLVED BY CONSTRUCTION, projectCtx UNCHANGED: a genuine bottom stratum `commitment`
  (seedStrata extension — compileStrata cannot insert below the seed head, so not a user-facing insert;
  groups.commitment = [ pipeCommit ], groups.collection = [ pipeMark ]) and TWO RULES minted per v1 policy,
  each projecting compilePipe's record to its own half; checkStratum's A4 refusal SATISFIED not weakened.
  Makes the ABW citation do real work (round 1's co-located form had no ordering for the theorem to supply).
  New fixture A7: a single rule emitting both kinds trips errors.mixedStratum — two-rule minting REQUIRED.
· DEFECT 2 RESOLVED: L12a ESTABLISHED FIRST — gen-pipe mkDerived already takes record-form `site`
  (`base = "${baseName}#${idOf site}"`, idOf duck-types, explicitly NOT content-hash NOT gensym), and
  den-hoag ALREADY BINDS IT at compat/pipe.nix:332 — the defect was the token's CONTENT. Stability (a
  property the in-tree injectivity comment never claimed) obtained by making the id-producing firing
  incapable of varying: pipeMark carries no derived ⇒ ONE producer of ids; commitment ctx normalized +
  higher-stratum throws ⇒ body cannot branch ⇒ effectIdx becomes a syntactic coordinate. Index domain
  narrowed to (policyId, pipeName). RESIDUAL STATED AS COUPLING: weaken C-1 to key-set preservation and the
  token silently goes shape-dependent again — fixture A3 is that coupling's acceptance.
· DEFECT 1 WITHDRAWN NOT REPAIRED — moved to the fork. Refutation re-derived at source (mapC/foldC/scanC/
  overC/joinC all pass values; only filter gets the view; adapter.fn is the class-coercion seam).
★★ THE FORK, RE-COSTED FROM SOURCE (arms i-iii leave §2's construction INTACT; arm iv SUPERSEDES the spec):
 (i) gen-pipe gap 4 = record-form withView on deriving operators (precedent: filter's predicate already
     takes the view); hard part is mapC's DEFERRED arm (argDemand/functionArgs + classInvariant/L13 restate,
     view threading into the thunk); theory inside gen-pipe's own Cheney/Chiticariu/Tan where-provenance
     frame; overturns the standing no-gen-primitive verdict; r9:1410 reached the same five-site enumeration.
 (ii) ★ RECOMMENDED — consumer-side records rewrite BUILDS NOTHING: concernQuirks.consumeAt already takes
     mode ? "values" (concern-quirks.nix:66-108); contribute seeds provenance.base.producer = { entity;
     scope; aspect; } and den-hoag populates scope = nodeCoords (product coordinate on a cell node)
     ⇒ **producer.scope.user.name IS the value srcUser captures**. Producer's transform drops → pure site
     mark; consumer syncthing/hub.nix:70,72 reads r.user; member.nix unaffected. Cost lands in nix-config
     (two named sites; den-hoag-side channelBindingsAt cost LOCATED NOT SIZED). Not byte-compatible — arm
     (ii) chooses WHERE the narrowing is absorbed, it does not avoid it.
 (iii) permanent ceiling = the construction's own projectCtx throw, firing at RUN inside mapC per node —
     selecting it obliges adding declaration coordinates (policy, channel, stage role) to the message.
 (iv) O3/O4 + r9 instruments — supersedes this spec, r9 becomes design of record; re-prices Q7 + gaps 2/3,
     deletes a live-green path, dissolves the I/II boundary; buys r9's property-2 subset firing.
· r9 REBASED to the adjudicated narrow claim; A3's rationale on r9 item 7; O3 label collision fixed.
★★ ROUND 2'S OWN SWEEP FINDINGS (five, the first three re-price round 1):
 1. round 1's C-2 rationale #2 FALSE — `emits` is derived by the VALUE-LESS PROBE (compileCanTake documents
    the misclassification), so it cannot decide which policies get the fleet firing ⇒ the commitment rule
    must be minted TOTALLY (for all 32 compat-compiled policies).
 2. ⇒ corpus cost is TWO rewrites, not one: hub-shares (the fork) + hub-peer. **14 of 16 untouched, not
    15.** C7-b re-priced: F = compat-compiled policy count (32), not 1 — still N-independent.
 3. round 1's central sentence "if the firing completes, its value is the value at every node" FALSE AS
    STATED — Law C2 keeps stage closures unapplied, so hub-shares' commitment firing SUCCEEDS and the
    captured throw fires later at mapC's `f c.value` per node. True invariant is stronger (nothing
    node-varying reachable at all); A1 must assert the abort AT RUN, not at the firing.
 4. the two violating shapes fail at DIFFERENT TIMES (lib.optionals eager at firing; captured value at
    stage application) ⇒ A6 and A1 are DISTINCT fixtures; a single "reads ctx" fixture could pass while one
    timing was wrong.
 5. O6-S is strictly NARROWER than r9 on property-2 subset firing (a case r9 pins by name) — a real trade,
    stated in both directions.
Corrections carried: ctxKeyStrata 13 lines / 5 populated; "anything observable" → "no CONSUMED value";
must-not-regress re-derived with a STRONGER corpus predicate (stage-kind census: pipe.from 16,
pipe.transform 1, pipe.to|as 0, marks 16). ROUND 2 COVERAGE LIMITS: nothing evaluated (the two failure
timings are ARGUED from Law C2 + lib.optionals strictness — A1/A6 settle them); r9 §§4-6/§8/core unread;
evaluate.nix dedup/delivery regions unread; Q7 figures quoted not re-derived; corpus counts are nix-config
counts.

════ ★★ DESIGN GATE ROUND 2 VERDICT: REDESIGN (2026-07-31; round does NOT count) ════
Artefact 85b28e83 verified — ★ WITH CONTAMINATION: the file's last two lines are stray tool-call markup
(`</content>`, `</invoke>`) inside the md5-anchored artefact; next revision strips them. S0 PASS ·
C1-a/C2-a/C4/C5(reached)/C7-a/C8/C9/C9-a PASS (C9 again the strongest section) · C1/C3/C6/C7-b FAIL ·
C7 mixed. FOUR CONSTRUCTION FINDINGS:
1. ★★★ THE COMMITMENT FIRING'S ARITY IS NEVER STATED and the spec claims the benefits of both answers.
   `pipeOps = concatMap (r: r.ops) rules` reads a STATIC FIELD ⇒ populating ops needs a COMPILE-TIME firing
   inside compilePolicy; but §2.3 mints a RULE with stratum/emits and rests on projectCtx/emits-conformance/
   checkStratum — ALL per-node dispatch machinery (`projectedBase = stratum: baseProduce: id: ctx:` is
   node-indexed; projectCtx reachable only through it). Dispatched ⇒ F = N × policies (N-independence
   inverts, per-node pipeCommit = option O3 + the Q7 knot). Compile-time ⇒ reaching projectCtx is a NEW
   CALL SITE, not "falls out of existing indexing". No local edit — THIS IS THE POSITION THE DESIGN MUST
   TAKE. Internal contradiction same seam: §2.1 changes the commitment projection to genAttrs vocabulary
   while §2.3 says "projectCtx is unchanged" — projectCtx IS the mapAttrs projection; stratum-conditional
   key-set behaviour is a new branch.
2. ★★★ THE SEED-HEAD RELOCATION: `groupOf` empty-emits arm is `builtins.head declare.strata` — under
   seedStrata = [ commitment … ] every empty-emits policy SILENTLY MOVES into the all-throws stratum. §2.3's
   derived-consumer enumeration names the dead consumer and misses the live one (derives from ORDER not
   groups). ★★ BOTH pin fixtures (silent-deletion.nix:123, compat-declared-empty-codomain.nix:134) assert
   `group == builtins.head d.strata` — written to be invariant under exactly this change ("so inserting a
   stratum cannot leave this asserting a stale name") — green while behaviour moves: THE SILENT-VANISH CLASS
   REPRODUCED BY THE DESIGN. Named edit: anchor the empty-head arm to a NAMED bottom-dispatch stratum +
   fixture asserting the stratum BY NAME.
3. ★★ C-1's `vocabulary` HAS NO STATED PROVENANCE and its drop direction is unguarded: the ctx key set is a
   per-node STRUCTURAL-STRATUM FIXPOINT OUTPUT (enriched-context = inherited-context // enrichments.added;
   enrich dispatch writes arbitrary keys) — derived vocabulary inverts the stratification (⇒ C1: ABW P1
   marked satisfied is actually UNKNOWN = rejection); authored vocabulary silently drops per-node keys
   outside it (genAttrs cannot throw for a key it does not enumerate; the abort covers only undeclared keys).
4. ★★ NODE-INVARIANCE IS AUTHORED, NOT CONSTRUCTED: `admitPositive = i: ceiling: i <= ceiling`
   (stratum-scope.nix) ⇒ a ctx key DECLARED AT the commitment stratum passes projectCtx unmodified per node;
   nothing forbids or detects it. Named edit: commitment key set empty BY CONSTRUCTION + registration abort.
★★ INSTRUMENT, DECISIVE FOR A7: `checkStratum` has ZERO call sites (3 hits = definition, export, and a
comment saying conformingProduce SUBSUMES it; control same run isSiteMarkData → 9 hits incl. 2 live call
sites) ⇒ errors.mixedStratum is UNRAISABLE, A7 asserts an abort no path can raise, §2.3's "applied per
policy" is quoted from declarations.nix:467's STALE COMMENT. The live law is groupOf + conformingProduce,
and groupOf DOES NOT REFUSE SPANNING (builtins.head groups, silent).
STATED-SCOPE: §6's price census wrong-domain (den.policies. → 32 = 16 defs + 16 includes references;
fleet-wide defs = 28 across 8 files; N-independence survives, the numbers do not). Arm (ii) unstated
den-hoag consequence: dropping the transform makes Ts == [ ] in broadcastGatheredWith ⇒ switches broadcast
from derived-terminal to raw localContribs path (gather.nix:307-337 comment names exactly this shape);
and arm (ii) makes the commitment route CORPUS-EMPTY ⇒ §2 ships with zero corpus witnesses (stated only as
a recommendation ground, never as an evidence cost).
ADVERSARIAL TARGETS: (a) syntactic-coordinate PARTLY REFUTED (constant under normalization, but finding 4's
authored hole); (b) arms i/iii intact CONFIRMED, ii qualified; (c) producer.scope.user.name SUBSTANTIALLY
CONFIRMED (cellCoordsOf → decls.__entry on cell nodes; broadcast preserves source contributions) with one
gap: scope.user is the registry __entry while ctx user is an entity STAMP — value identity asserted, source
of an entry's `name` uncited; producer has FOUR fields not three; (d) REFUTED as above; (e) total-minting
behaviour CONFIRMED (empty commitment half emits nothing; 14/16 untouched correct; stage census reproduces
exactly), price carries the wrong-domain number.
MUST NOT REGRESS (gate-verified): C-4 withdrawal correct at source; both §2.6 failure TIMINGS survive
source reading (lib.optionals forces host at the firing; srcUser stays lazy until stage application);
compileStrata genuinely cannot insert below the seed head (insertAfterRun + dupes guard); consumeAt threads
mode; emits-conformance row right (errors.emitsUndeclared live at concern-policies.nix:427); register
handling reasoned. GATE COVERAGE LIMITS: nothing evaluated; r9 NOT OPENED (its coordinates unverified this
round); Q7 figures quoted; register entry 3's independence plausible-unverified (buildRoots not
stratum-indexed, pre-pass not traced against a new bottom stratum); nix-config found at
~/Documents/repos/sini/nix-config.
ROUND 3 NOT YET DISPATCHED — queued behind the unification r5 author for the papers slot. THE POSITION
ROUND 3 MUST TAKE (finding 1): state the commitment firing's arity. CANDIDATE DIRECTION (orchestrator
inference, unvalidated): if the firing is COMPILE-TIME, it does not need the rule/stratum machinery at all —
a synthetic total-throw fleet ctx built AT THE COMPILE SITE (round 1's original shape) + the declared kind
split retained for ROUTING only; the stratum then buys nothing the collection stratum does not already
provide for marks, and findings 2/3/4's stratum-machinery consequences dissolve with the stratum. Round 3
must also: strip the artefact's tool-markup tail, re-derive the price on the definitions domain (28
fleet-wide / 16 pipes.nix), and state arm (ii)'s gather.nix consequence.

════ ★★ DESIGN ROUND 3 — O6-C (definition-time firing, NO STRATUM), GATE ROUND 3 PENDING (2026-07-31) ════
ARTEFACT: same path, FROZEN at md5 `06ccdeee8221015e9c4d40d9cfaaba31`, 1174 lines (was 915; round-2 tail
markup stripped). Pins: den-hoag 2e44ff5 · nix-config 425f1d3b · gen-pipe 5350930 · gen-schema 6732239.
★ THE STATED ARITY (round-2 gate finding 1 answered): the commitment firing is DEFINITION-TIME, once per
commitment-bearing compat-compiled policy, AT THE COMPAT RECORD MINT — not a rule; no node, no stratum, no
dispatch, no projectCtx. Grounds: (a) the consumer chain is static end to end (compilePolicies has ONE
production call site, a fleet-level let; projectedBase is node-indexed by signature); (b) ★★ the tree
STATES this arity as law — isSiteMarkData's header: "compose commitments … seed the ONE fleet compose
BEFORE eval, from ctx-INDEPENDENT bodies … it IS a probe-time commitment" — so opsInBody was the refusal
of the wrong arity, never a placeholder; (c) ★★★ the definition-time firing ALREADY EXISTS —
policy-recover.nix recoverDecls fires the ungated body at a synthetic ctx with a stated "fire at most
once" projection contract; `ops` is one more projection of that family (round 2 rebuilt from scratch what
was bound at the wrong surface — a C7-a miss).
STRATUM: NONE. seedStrata/compileStrata/groupOf/checkStratum/projectCtx/ctxKeyStrata/admitPositive/
lib/attributes//mkDen-let all on §2.7's NOT-EDITED row. Kind split pipeCommit/pipeMark KEPT, both at
collection, ROUTING only — realised as two TRANSLATION MODES (one dispatched rule + one compile-time
projection), mode baked at translation so neither body can emit the other's kind. Partition table total
over compilePipe's FIVE fields (targeted is fleet-read by isUntargetedDeriving ⇒ commitment field).
ABW DROPPED to informed-by-only (no stratum read ⇒ no P2 owed; ctxKeyStrata stays { }; ★ 9xo.59 is NO
LONGER this design's enabler). Knuth stands alone and supplies the FIX (synthesized root attribute).
ROUND-2 FINDINGS: 2 DOES NOT ARISE (no seed change; both pin fixtures keep their meaning); 3 DISSOLVES
(synthetic ctx key set = requiredCoordsOf gate = the policy's own functionArgs — not derived, not
authored; drop direction closed by Nix scoping; residuals: defaulted coord keeps the author's default,
ctx@{…} alias escapes uncatchably — an EXISTING ceiling, measured 0 instances / control 36); 4 CONSTRUCTED
(no node at the firing site — property of the position). A7 REBUILT on the live law: mixedStratum
unraisable confirmed (0 call sites, control 9/8); the live mechanism is errors.emitsUndeclared
(concern-policies.nix:427); opsInBody AND isSiteMarkData both DELETED, fixture A2 exhibits the replacement
firing.
★★ ROUND 3'S OWN SWEEP (9 findings): (1) a LIVE stratum-span refusal round 2's A7 missed — policyMessage
:197/:199 refuses spanning codomains AND unknown kinds, forced at :474 (round 2 named a dead error while a
real refusal of the same shape would have fired; also the backstop making the kind rename safe); (2) ★★
the SHIPPED sentinel is UNSOUND for a value-bearing projection — at probeEntry, srcUser = "«sentinel»"
rides every node silently (deepSeq does not enter function bodies; Law C2 leaves stages unapplied) = O2
wearing an existing instrument ⇒ C-4 is a present-but-THROWING sentinel; the identity law passes on
PRESENCE (requireEntry v ? id_hash) so a total-throw entry satisfies it; (3) ★★ F = ZERO new body firings
on this corpus — emitsFor tests PRESENCE so the projection inherits the declaration opt-out a rule cannot
have (produces-by-name.nix: 21 entries, two pipeOp both site-mark-only; hub-shares has NO entry and
already reaches recoverDecls today); (4) ⇒ corpus cost ONE rewrite, 15/16 untouched (r1 said 15/16 by
another route, r2's 14/16 was an artefact of minting a rule); (5) missed edit recovered:
produces-by-name.nix's two pipeOp entries → pipeMark (stale kind refused by NAME at :197, never silently);
(6) compilePipe has FIVE fields; (7) contribute recognises FOUR producer fields, stores THREE (classes →
resolveTag, NOT provenance); (8) ★★ producer.scope gap CLOSED BY CONSTRUCTION — decls.__entry and
decls.${dim} are the SAME Nix value bound twice in one attrset literal (build-roots + fleet), and `name`
provenance cited: gen-schema instance.nix:54-57 stamps options.name default = registry attr key (corpus
does not author it); (9) price re-measured on the definitions domain: 16 in pipes.nix, fleet-wide 31
across 9 files — DISAGREES with the round-2 record's 28/8, divergence stated with the exact predicate
rather than adopting an unproduced number.
ARMS re-costed: (i) unchanged; (ii) STRENGTHENED (finding 8) but two costs added — (α) dropping the
transform flips broadcastGatheredWith to raw localContribs and the hub then receives contributions with NO
user field ⇒ the consumer rewrite is what makes the arm correct, both ends land together; (β) corpus-EMPTY
commitment route ⇒ zero live witnesses, derivedBaseNames resolves nothing, ci-only exercise — stated in
both directions now; (iii) the abort is the commitment sentinel's throw, message is this design's to write
(policy, coordinate, stage role, remedy); (iv) buys LESS than round 2 priced (hub-peer needs no rewrite
under O6-C too; the static node-free chain means arm (iv) is the only arm that must argue Q7 at all; real
draw = r9's validated executable core). RECOMMENDATION: arm (ii); selection the owner's; arm (iv) forks
the construction (r9 becomes design of record).
ROUND 3 COVERAGE LIMITS: nothing evaluated except one two-token language probe (select-with-or against a
function falls back — measured); ★ the full compat surface reaching recoverDecls NOT enumerated
(load-bearing for the two-sentinel choice; a later round could reopen it); r9 not re-opened; gen-pipe not
re-read beyond contribute.nix; channelBindingsAt still unread (arm (ii) den-hoag cost located-not-sized);
den v1 and wider corpus carried; Q7 figures quoted. Round-2 fixtures deleted WITH REASONS (its A7, its
A3-normalization half); new A2/A6-companion/A7.

════ ★★ DESIGN GATE ROUND 3 VERDICT: REDESIGN (2026-07-31; round does NOT count; THIRD consecutive) ════
Artefact 06ccdeee verified. S0 PASS · C2/C4/C7-a/C8/C9/C9-a PASS · C1 fail-weak · C2-a FAIL · C3 FAIL ·
C5 mixed · C6 FAIL · C7/C7-b partial. FIVE CONSTRUCTION FINDINGS:
· C-2 ★★★ THE BLOCKING ONE, NO LOCAL EDIT — THE COMMITMENT-FIRE GATE IS CIRCULAR: §2.7 gates the mint on
  the declared/RECOVERED codomain containing pipeCommit, but for an undeclared v1 policy the codomain IS
  the recovery (emitsFor→recoverEmits→recoverDecls) and what it returns depends on WHICH MODE'S fn it
  fires — which is what the gate decides. Recover with markFn ⇒ no undeclared policy ever gets a
  commitment, silently. Recover with commitFn ⇒ a third fire §6 does not count. Declared-only ⇒
  broadcast-syncthing-hub-shares (the SOLE commitment-bearing corpus policy, NO table entry) gets no
  commitment, silently. Every branch reproduces the silent-vanish class. §6's zero-new-firings and §2.6's
  opt-out both rest on it. Closing it = re-deciding whether the fire is gated at all.
· C-1 ★★ the registration-time ops law is ORPHANED: isSiteMarkData has a SECOND live call site
  (concern-policies.nix:184 siteMarkOps feeding the :200-201 ops law — the tree itself names the pairing
  at :394); deleting the predicate breaks compilation as specified, and emitsUndeclared does NOT inherit
  (conformingProduce maps body emissions, never sees ops — disjoint paths). Local edit: restate the ops
  law over the declared kind.
· C-3 ★★ DEFAULTED COORDINATES BYPASS THE THROWING SENTINEL — requiredCoordsOf filters to false entries,
  so a defaulted coord is ABSENT from the synthetic ctx; the body takes its own default branch; the
  commitment is the default-branch value at every node, no funnel — O2's shape, and §2.4 calls it sound
  (confuses defaulted-in-formals with absent-at-every-node; presence is a dispatch fact). Live corpus
  instance: users.nix:109 accessGroups ? [ ] (control: the only ? in modules/den/policies/). Local edit:
  fire the commitment sentinel over ALL coords.
· C-4 ★★ the coordinate-naming obligation is UNDISCHARGEABLE at the chosen site: recoverDecls wraps in
  tryEval and converts failure to policyCodomainUnrecoverable (policy name only) — Nix DISCARDS a caught
  throw's message (the tree states it twice); A3's "named, catchable" cannot have both through one tryEval.
· C-5 ★ edit list incomplete, omissions fail SILENTLY: gather.nix:133/145/174 (the three per-node
  __action == "pipeOp" readers that ARE the marks route in §2.3's own table) + declarations.nix:459 —
  unedited, every site mark silently stops being consumed.
STATED-SCOPE: S-1 Knuth claimed for the FIX it does not supply (a synthesized attribute is computed FROM
the subtree; reads-nothing is intrinsic — the spec's own ABW-drop reasoning applied to one citation,
withheld from the other); S-2 the LAW header's "probe-time" is the retired value-less STRATUM probe, not
policy-recover's sentinel (different sentinel, different layer); S-3 §7's stale-spelling safety cites the
emits validator while composeOp is an OPS-FIELD payload — after the deletion NOTHING validates __action on
an ops element, silently accepted at exactly the surface §7 exempts, falsifying "both keep their exact
meaning" for silent-deletion.nix; S-4 errors.nix:285-292 ("no design that makes ops a static field can
work ... do not work around this in the shim") is neither quoted nor rebutted AND §2.7 deletes it — the
record of the refuted class vanishes, which the register's own rule says gets re-proposed; S-5 A6's
premise unreachable (undeclared ⇒ value-sentinel recovery ⇒ false branch ⇒ gate false ⇒ never fired).
I-1: B3's control misreported (13 lines/8 files not 9/8) — the miscount is what let C-1's second call site
go unnoticed. TARGETS: (a) sentinel split soundly separated (recoverDecls: TWO consumers, TWO mints);
(b) quotes verbatim-accurate, deletion census incomplete; (c) arms verified, opt-IN mirror unstated;
(d) mode bake IS a construction (one declare.pipeOp producer) but channel routes to BOTH under "exactly
once" and the marks-route readers are unedited; (e) both counts reproduce, functionArgs does NOT break on
@-patterns (probed), absence stronger than stated; (f) ★ the spec's 31/9 is RIGHT, prior 28/8 NOT
reproducible — adjudicated in the spec's favour.
POSITIVES TO KEEP: C-4's value-sentinel-unsound insight (requireEntry ? does not force); the recoverDecls
reuse-scan find; the ABW drop; §2.7's not-edited row TRUE (no pipeOp literal under lib/attributes/); the
mode bake; §9's honest both-directions costing. ★ THE OWNER FORK IS NOT THE REASON: three gates have now
confirmed the arms correctly costed, arm-invariance holds ((i)-(iii) intact, (iv) genuinely forks), the
arm (ii) recommendation's grounds sound, and the __entry value-identity argument checks at source.

★★★ ORCHESTRATOR HOLD (2026-07-31): THE DESIGN TRACK PAUSES HERE PENDING THE BANKED OWNER RULING.
Grounds: three consecutive REDESIGNs; the arm choice DETERMINES whether the core construction is needed at
all — arm (ii) (recommended, thrice gate-verified) makes the commitment route CORPUS-EMPTY, and arm (iv)
supersedes this spec with r9 (VALIDATED, executable core); iterating a fourth construction round ahead of
that ruling inverts the dependency. The owner decision surface is COMPLETE and verified: four arms costed
from source, recommendation with grounds, both directions stated. WHAT A RESUMED ROUND INHERITS: this
verdict's C-1..C-5/S-1..S-5/I-1, the round-3 positives, and the unclosed recoverDecls-surface enumeration.

════ ★★ DESIGN ROUND 4 — O6-C UNDER THE ARM-(ii) RULING, GATE ROUND 4 PENDING (2026-07-31, session 3, at f631973; rounds-1-3 coordinates verified unmoved: git diff --name-only 2e44ff5..f631973 -- lib/ ci/ parity/ → 0 files, control whole-tree → 1) ════
ARTEFACT: same path, FROZEN md5 `01b93338aefd2d058885e665e4f87c42`, 1527 lines (was 1174). Orchestrator double-sampled twice.
· ★★★ MECHANISM CORRECTION (B17) — THE ARM-(ii) SURFACE NAMED IN ROUNDS 2-3, THE RULING RECORD, AND den-hoag-dcx WAS WRONG AT HEAD. concernQuirks.consumeAt has ZERO production call sites (definition + re-export + 4 comments in lib/; only exercises = 3 in ci class-tagging; positive control channelBindingsAt → live at output-modules.nix:1036). The hub consumer reaches replicateHome as a CLASS-MODULE FORMAL (hub.nix:56) via bindingsAt → channelBindingsAt, which reads received-collections/local-collection-data DIRECTLY — mode="records" is a parameter on a road this consumer does not drive. REAL MECHANISM ONE STEP SHORTER: channelBindingsAt's final `concatMap flatten ((baseOf ch) ++ (gathered.${ch} or [ ]))` — the ++ operand IS the contribution list; record→value projection is exactly `flatten` over extractContribution. gen-pipe contribute.nix (read in full at 5350930) binds prod TWICE in one literal (`producer = prod` AND `provenance.base.producer = prod`) ⇒ accessor on a raw contribution is c.producer.scope.user.name — same-thunk identity survives, SHORTER than the consume-records path. RULING SUBSTANCE UNAFFECTED (consumer reads provenance, producer transform drops); the SURFACE is re-pointed. dcx body corrected this session.
· ★ channelBindingsAt SIZED (the three-round located-not-sized debt): den-hoag ONE file THREE expressions — output-modules.nix records-form hoist `channelRecordsAt` (1 changed 1 added), one sibling key in bindingsAt (1 added), lib/default.nix ZERO. Seven let bindings shared ⇒ hoist not duplication. Byte-neutral by the tree's own gen-bind wrapAll precedent (binds iff key exists AND module declares — stated in-tree at :1013-1015); population that must not move: 44 channel-formal declarations / 35 corpus files (controls host → 46, replicateHome → 2). Scale: 1 extra attrset per (node, demanded channel), forced only where declared — this corpus ONE module ONE host.
· ★ NEW REFUSAL OWED (found by the sizing, B20/A11): bindingsAt's `// { settings = …; }` sibling silently OVERWRITES a registered channel of the same name — silent-vanish class, reproduced by this very change ⇒ named abort required. channels-collision census 0 with live controls; an earlier control choice (settings) returned 0 = invalidated run, discarded and re-run — recorded in-doc.
· ARM-(ii) EXECUTION SPEC (§9.2-9.4, all sites verified at HEAD): producer pipes.nix broadcast-syncthing-hub-shares drops pipe.transform (+ user formal + let srcUser); consumer hub.nix:70-72 bindings users/dirsForUser (round 3 misnamed dirsFor) move to c.producer.scope.user.name / c.value.directories or [ ]; member.nix unaffected (reads .directories only); hub members :66-68 fed by BARE broadcast (corpus has exactly ONE pipe.transform fleet-wide = hub-shares, B4). THE FLIP: dropping transform → Ts == [ ] → raw localContribs (gather.nix:115-117); the in-tree "byte-unchanged" comment is relative to a bare broadcast NOT today's transformed path — that IS the divergence. ★★ LANDING ORDER, THREE STEPS FORCED BY THE DESIGN'S OWN GUARD: (1) den-hoag records-binding surface (additive, byte-neutral); (2) nix-config BOTH ENDS one change (producer-first breaks users immediately — no user field; consumer-first has nothing to bind); (3) den-hoag §2 construction (before step 2, hub-shares is commitment-bearing AND undeclared ⇒ §2.3.1 mark-mode refusal aborts BY NAME — loud, correct). Steps 1 and 3 both den-hoag main, NOT one commit — merging them makes step 2 unlandable.
· PARITY = EQUIVALENCE, divergence located (§9.3): (user,directories) relation preserved on two same-value arguments; drvPath identity neither claimed nor required. Three divergences: wire path, payload shape, and ARITY closed on THIS corpus only (flatten spreads list-valued contributions; sole corpus emitter claude.nix:330 is an attrset; a list-shaped emitter re-opens it silently — consumer reads .value explicitly for that reason). ★ PRECONDITION STATED NOT MEASURED: producer.scope ? user requires a CELL node (nodeCoords → cellCoordsOf, B21) — acceptance obligation on dcx: missing-user contribution aborts NAMED, never silently drops a member.
· ROUND-3 DISCHARGES, each at CLASS: C-2 gate = DECLARED codomain only, mark-mode refusal (successor to errors.opsInBody) aborts undeclared commitment-bearing records by name — no recursion, forces the rewrite loudly; C-1+S-3 one edit — ops law restated over kindOf a == "pipeCommit" (strictly stronger, catches stale __action too); C-3 fire binds ALL coords (the omit-defaulted rationale is a VALUE-sentinel argument, does not transfer to the THROWING sentinel — two sentinels two domains); C-4 abort synthesized at fire site (per-coordinate re-measure on failure only; empty attribution still aborts, degrading to success forbidden); C-5 exhaustive "pipeOp" census 9 lib / 16 ci / 0 lib/attributes with dispositions; S-1 all four citations audited (Knuth diagnosis-only, ABW dropped stays, Reynolds informed-by, Cheney only inside the ruling record); S-2 ground (b) narrowed to the surviving ctx-independent-seed clause; S-4 errors.nix:285-305 quoted VERBATIM, measurement undisputed, over-quantified conclusion narrowed, record carried onto the refusal message not deleted; S-5 premise reachable by construction; I-1 corrected AND sharpened (isSiteMarkData 13/8, exactly TWO live call sites both concern-policies.nix — round 3 wrong in both directions).
· recoverDecls ENUMERATION CLOSED (§2.4.3/B14, the round-3 open item): TWO call sites exhaustive, both compile.nix familyStamps behind policyRecovery (:133 emitsFor KIND-only projection; :183 codomainStamps keysOf) ⇒ §2.4's no-projection-reads-a-VALUE premise now MEASURED. One-sentinel alternative PRICED: 31 corpus policies, 9 with produces-by-name entry, 0 declaring emits ⇒ 22 reach recovery undeclared vs radius-ONE confined change; coord-field census 78/12 is FILE-level over a BODY-level property — bounds, does not attribute (stated limit).
· ★ HONEST NARROWING round 3 missed (§2.2): isSiteMarkData does NOT retire entirely — routing role retires, SHAPE survives as conformance predicate bearsCommitment (register entry 2 admissible: entry retires value-shape DISPATCH not conformance). bearsCommitment ≠ negation: marks != [] term dropped ⇒ markless commitmentless pipeOp becomes legal — deliberate widening, fixtured (A8).
· REGISTER: entries 1-5 re-checked against new text (entry 5 contact now LIVE via producer.scope transitive __entry read — adds no new reader, does not move it; __pipeMark ownership pass still owed). Drift sweep: every appendix cell re-run by its own command; ONE self-correction B2a = 20 not 21 (round 3's count); all others reproduce. r9 rebase carried (§1.4) — r9's obligation label "O3" never bare, r9 not re-opened (stated limit).
· FIXTURES: A8 (widening), A9 (★ body-route guard replacement — the only thing between the declared-only gate and the silent-vanish class), A10 (restated ops law), A11 (dcx: additive binding + shadow refusal) NEW; §9.5 states why: commitment route corpus-EMPTY ⇒ fixtures carry the whole evidential load.
· LIMITS: nothing evaluated this round; ci suite not run; §2.6 timings argued from Law C2 (A1/A6 settle); §9.3 equivalence argued from source (dcx acceptance settles); cell precondition stated; Q7 figures quoted from scout not re-derived; §5 argues Q7 for both halves SEPARATELY (§9.2 edits output-modules.nix which §2.7 lists not-edited — the two changes must not conflate); den v1 unread; corpus beyond nix-config unreached.
NEXT: GATE ROUND 4 — dispatched. NO round-3 finding measured wrong (I-1 reproduces stronger).

════ ★★ GATE ROUND 4 VERDICT: REVISE — does NOT count toward two-clean exit (2026-07-31, session 3; reviewed md5 01b93338aefd2d058885e665e4f87c42 echoed; NOT REDESIGN — arity C-0, declared-only gate, mode bake, two-sentinel split, kind pair all survive). S0 PASS · C2/C2-a/C3/C5/C7-a/C8/C9/C9-a PASS · C1 pass-weak · C7 partial · C1-a FAIL · C4 FAIL · C6 FAIL · C7-b fail-narrow. ════
· F1 ★★★ CONSTRUCTION BLOCKING — bearsCommitment IS A TAUTOLOGY on the real record shape: compilePipe ALWAYS sets targeted (a LIST, [ ] when no `to` stage, never null/absent; pipe.nix:368-371) so `(a.targeted or null) != null` is TRUE for EVERY compiled pipe record ⇒ mark-mode refusal aborts ALL 16 corpus pipe policies; §2.6's "15 of 16 untouched" inverts to 0 of 16 compiling; A8's widening never occurs. Measured 4 cells with two-direction controls. Tree's own convention one line away: isUntargetedDeriving reads `(p.targeted or [ ]) == [ ]` (default.nix:1534). NAMED EDIT: `|| (a.targeted or [ ]) != [ ]`, cite the convention. ★ A8 as specified would have caught this — fixture contradicts prose; prose is what an implementer writes from.
· F2 ★★★ CONSTRUCTION — THE MARK-MODE REFUSAL IS SWALLOWED BY recoverDecls' tryEval ON THE UNDECLARED PATH — the ONE corpus instance §2.3.1 property 4 and §9.4 step 3 name. Chain read at source: hub-shares has no emits + no produces-by-name entry ⇒ recoverDecls applies the mode-baked markFn inside `builtins.tryEval (deepSeq …)`; den-hoag errors are PLAIN THROW (errors.nix:5, "nixpkgs-lib-free") ⇒ CAUGHT ⇒ user sees policyCodomainUnrecoverable <policy> — channel/field/remedy DESTROYED by the boundary the spec itself describes at §2.4.4. ★★ AND IT IS A REGRESSION THE DESIGN CREATES: today errors.opsInBody fires at conformingProduce (:428) — at DISPATCH, OUTSIDE the envelope, full message; the design moves the refusal INTO the envelope. §2.3.1 property 2 ("same place as today") FALSE. ★ A9 IS STRUCTURALLY BLIND: it fixtures a DECLARED codomain (⇒ no envelope) — arms the refusal on the only path where the envelope is absent. NAMED EDIT (position decision): synthesize the mark-mode diagnostic on the !try.success side per §2.4.4's own closure, OR hoist the bearsCommitment test outside recoverDecls; re-point A9's companion to an UNDECLARED commitment-bearing policy. §9.4 step 3's OUTCOME (loud) survives; its stated mechanism and message do not.
· F3 ★★ CONSTRUCTION-ADJACENT — §9.2's sizing sharing claim FALSE: `channelBindingsAt = mapAttrs … (channelRecordsAt id)` PLUS the sibling `channelRecordsAt id` = TWO applications; Nix memoizes thunks not applications, no CSE ⇒ the seven let bindings incl. gathered = channelGatherR (cross-scope recursion) computed TWICE — the exact shape default.nix:949 warns about; doubled per-node gather at the scale bar. Also `flatten` out of scope as written. NAMED EDIT: one id-application yielding both surfaces bound once at the caller (bindingsAt gains a let = a FOURTH expression; sizing must count it).
· F4 ★★ CONSTRUCTION-ADJACENT — records surface has NO DEFERRED-CONTRIBUTION CONTRACT: flat path normalizes via extractContribution (deferredToThunk); records form drops it; gen-pipe sets value = poison for deferred (contribute.nix:115-120) and `or` does not catch a throw (the spec's own §2.6 shape-2 point). Corpus-safe today (sole emitter attrset, verified) but the sibling is a GENERAL surface and A11 does not fixture deferral. NAMED EDIT: channelRecordsAt yields `c // { value = extractContribution c; }` — provenance kept, deferral discipline kept, byte-neutral for non-deferred; deferred arm added to A11.
· S1 ★★ ITEM-2 ADJUDICATION (hub-peer cardinality): dissolution LEGITIMATE, independently derived — hub-peer HAS a produces-by-name entry (:39) which §2.7 renames to pipeMark ⇒ declared codomain lacks pipeCommit ⇒ never fired at the sentinel; dispatched mark firing gets full ctx (optionals fine); pure mark passes the REPAIRED F1 predicate ⇒ ONE rewrite; round-2's two came from TOTAL minting which the declared-only gate removes. ★ BUT THE RULING RECORD (§9.1) NEVER RECONCILES the owner ruling's banked "TWO rewrites" figure — §0.2 even promises §9 does, and it does not (whole-artefact grep, 10 hub-peer sites, none reconciles). NAMED EDIT: one §9.1 paragraph superseding the cardinality with the two-line derivation. [Orchestrator note: the owner-ruling COMMENT on this bead carries the same two-rewrite figure — superseded to ONE by this derivation; the comment is derivation history, this body entry is the correction.]
· S2 ★ shadow refusal owed-not-designed and scoped too narrow: no message, no forcing position (demand-fired refusal is not a refusal; channelNames in scope at :1035 permits a fleet-level forced check); class WIDER than registered channels — the sibling comes LAST so it shadows enriched-context keys too (open key set from policy dispatch), and the shipped `settings` sibling carries the identical hazard uncovered; the sibling NAME (channels) + records SHAPE appear only in appendix B20. NAMED EDIT: quantify over enriched-context ∪ channelNames, both siblings, forced once, message written; name key+shape in §9.2.
· S3 ★ "one behaviour changes" undercounts — bearsCommitment ≠ ¬isSiteMarkData in BOTH directions: the stated widening (A8) AND a NARROWING — marks!=[] ∧ targeted!=[] ∧ routes==[] ∧ no derived: allowed today, refused unless pipeCommit declared; constructible from v1 surface (pipe.to path), corpus-zero (B4 re-run 0), parked `to` fixtures NOT read (predicate-level derivation, stated). NAMED EDIT: both directions in §2.2 and §6; A8 companion for the narrowing.
· I1 INSTRUMENT: B17's lib/ enumeration undercounts (8 lines not 6; missed concern-quirks.nix:6,:10 comments) — conclusion UNAFFECTED, all 9 read, zero production call sites CONFIRMED.
· ITEM-1 (B17) UPHELD in full with independent measurement: consumeAt zero production sites (positive control channelBindingsAt live at :1036); pipe.consume one internal site; consumer path confirmed; ++ operand confirmed; twice-bound thunk CONFIRMED at contribute.nix (:123 producer, :88-91 provenance.base.producer — same thunk both depths; :97/:119 are error/poison paths); spec ARGUES the survival (ties to §9.1 ground 2's __entry argument). ITEM-6 landing guards: step-3-first outcome yes MESSAGE no (F2); producer-first break CONFIRMED at gather.nix; arity-closed-on-corpus CONFIRMED (sole emitter attrset). ITEM-8 two-halves separation PASS (B16 re-run; channelRecordsAt reads exactly the attribute set channelBindingsAt already reads — no new attribute, no mkDen binding either half). ITEM-7 drift: every re-run cell reproduces; B2a=20 self-correction CORRECT (round 3's 21 wrong).
· GATE LIMITS: only the 4-cell equality probe evaluated; ci suite not run; parked pipe fixtures unread beyond headers; r9 unopened; Q7 figures accepted as labeled; mintFleetWide body unread (F2's ungated.fn claim follows from §2.3 + compile.nix:202).
NEXT: ROUND 5 — minimum: F1 one-token fix, F2 position decision + A9 re-point, F3 single-application sizing, F4 deferred arm, S1 §9.1 reconciliation. QUEUED behind the papers-repo writer slot (r14 in flight). Count stays at ZERO for this track's exit.

════ ★★ DESIGN ROUND 5 — O6-C, GATE ROUND 5 PENDING (2026-07-31, session 3, at f631973) ════
ARTEFACT: same path, FROZEN md5 `bbbaaf8f501a3061ac008eb8c2817ec3`, 2007 lines (was 1527). Orchestrator double-sampled.
· F1 FIXED + DISJUNCT-CLASS AUDIT (§2.2a): third disjunct → `(a.targeted or [ ]) != [ ]` citing isUntargetedDeriving (default.nix:1530-1536). Audit of all 7 disjuncts found a SECOND defect the gate missed: `kindOf = a: a.__action` has NO DEFAULT (declarations.nix:166) — §2.3.2's law as written raises Nix's unattributed attribute-missing instead of its own named refusal; restated over `(a.__action or null)`, A10 third arm. Not a regression (siteMarkOps has the identical hole today) but round 4's sentence claimed to close it.
· B22 (the round's ONLY evaluation, extraction-level MODEL of compilePipe's four fields, 16 corpus policies + 4 controls): round-4 predicate TRUE 20/20 (tautology EXHIBITED); repaired predicate → 1 of 16 = hub-shares, 15 untouched; ★ repaired predicate selects the SAME single policy shipped isSiteMarkData refuses — on this corpus the repair restores exactly today's behaviour; both behaviour changes corpus-zero, visible only in controls (one flips each way — run discriminates).
· ★★ F2 POSITION: HOIST, in a form the gate did not name — markFn NEVER THROWS. Where declaresCommit is false and the record bears commitment, the pipe arm emits declare.pipeCommit (the honest kind) and TWO DECLARATION LAWS refuse OUTSIDE every envelope: undeclared → emitsFor's recovery arm tests the RETURNED KIND SET (computed after recoverDecls returns); declared-lacking-pipeCommit → shipped errors.emitsUndeclared (concern-policies.nix:427). REASON the synthesis fallback was rejected: it repairs the INSTANCE only — MEASURED: codomainStamps (compile.nix:183) ALSO calls recoverDecls for a policy whose emits is fully DECLARED (whenever the declaration names member/suppress and the ref declares no binds/suppresses) ⇒ "declared ⇒ no envelope" is FALSE and any body-side throw is one declaration shape from being swallowed again. §2.3.1 property 2 corrected: position MOVES for the undeclared population (dispatch → codomain recovery); declared stays at dispatch. §2.3.1a = envelope census (B23: 12 tryEval lines lib/, 7 call sites, only TWO fire a body — policy-recover.nix:59 + policy-inspect.nix:24, the latter unreachable by any refusal here, its else [ ] silent degrade pre-existing and named; completeness argued: bare tryEval not in default scope, alias grep 0).
· ★★ OWNER-VISIBLE JUDGEMENT, AUTHOR-FLAGGED FOR GATE SCRUTINY (§8 new starred para): the hoist makes bearsCommitment select WHICH DECLARED KIND markFn emits — reads cold as register entry 2's retired value-shape-dispatch. Author's adjudication: still admissible — the predicate is consulted ONLY on the branch where no declaration authorises anything, outcomes are the-declared-route vs abort, never two live consumers; becomes a violation the day the refusal softens into a second route. §2.3's "neither body can emit the other's kind" WITHDRAWN → "the mark route never emits a commitment a declaration AUTHORISES" with exhaustive two-valued case split. GATE ROUND 5 MUST ADJUDICATE THIS INDEPENDENTLY (C9/C9-a heart).
· F3 FIXED: §9.2 sizing → FOUR expressions, channelSurfacesAt (one id-application, two-key return). ★ Author corrected the gate's citation IN-DOC: default.nix:949 warns about re-applying the curried FLEET prefix (per-fleet indices), round-4's defect re-applied the bound id-lambda (per-node body) — different doubling, same character; F3 substance CONFIRMED. ★ Second defect in round-4's own form the gate missed: concatMap flatten sat OUTSIDE the let defining flatten — unbound identifier. Both fixed by the one-application form.
· F4 FIXED: records yields `c // { value = extractContribution c; }`; normalisation-class audit added; A11 deferred arm. Coordinate correction: value = poison binding at contribute.nix ~110-117; poison DEFINITION (throw of E6) at gen-pipe deferred.nix:22-33.
· S1 FIXED: §9.1 cardinality reconciliation TWO→ONE, 4-step derivation. S2: §9.2.1 new (~55 lines) full shadow-refusal design. S3: both directions in §2.2 + §6 item 5 + §11 + A8 companion. I1: B17 corrected (8 Nix lines + 1 ledger prose).
· REGISTER/APPENDIX RE-RUNS all reproduce (B2a 20 + syncthing 0; B16 9-lib/16-ci; B3c 13/8; B3 3/2; B4 per-kind identical via B22; B20 carried). No self-referential cell.
· LIMITS: ci suite not run, NO fleet evaluated; B22 is a MODEL of compilePipe not compilePipe (four fields' shapes only); §2.3.1's two positions are single-step source reads NOT executed (A9's three arms settle them; A9-undeclared written so round-4's construction fails it); §9.2.1's enriched-context half UNMEASURED (open dispatch-product key set — designed for the hazard, not justified by a count); B23 lib/ only, ci/ unswept; r9/den-v1/parked-to-fixtures/Q7 carried as before; cell precondition stated not measured.
NEXT: GATE ROUND 5 — dispatched. Named adjudications: the §8 entry-2 form, the F2 hoist's two-law totality, B22's model fidelity.

════ ★★ GATE ROUND 5 VERDICT: REVISE — count stays ZERO (2026-07-31, session 3; reviewed md5 bbbaaf8f501a3061ac008eb8c2817ec3 echoed; NOT REDESIGN — arity, declared-only gate, mode bake, two-sentinel split, kind pair AND THE F2 HOIST ITSELF all survive). S0/C1/C2/C2-a/C3/C4/C5/C7/C7-a/C7-b/C8/C9(cond)/C9-a PASS · C1-a FAIL (F5) · C6 FAIL (F5,F6,S5). ════
· F5 ★★★ CONSTRUCTION — THE MIXED RECORD MUST DECLARE TWO KINDS AND EVERY GATE/REMEDY/FIXTURE SAYS ONE. conformingProduce's first arm (admitted = genAttrs emits, :409; !(admitted ? k) → emitsUndeclared :426-427) + markFn emits pipeMark unconditionally per node ⇒ a policy declaring [ "pipeCommit" ] ABORTS AT DISPATCH ON ITS OWN LEGITIMATE MARK. hub-shares is MIXED (§0.1's words) so §2.3.1's remedy string produces a SECOND abort for an author following it verbatim; A9-control as specified DOES NOT COMPILE; two-kind declaration whole-doc grep 0 (the 5 hits are the groups.collection vocabulary list). NAMED EDIT: structural precondition stated once — codomain containing pipeCommit must ALSO contain pipeMark (markFn emits one per node) — carried into §2.3.1 remedy, §2.7 produces-by-name row, §6 item 3, A9-control/A6-companion. Legal by construction: groupsOf [pipeCommit pipeMark] is a singleton (both collection) ⇒ :199 span refusal silent.
· F6 ★★★ CONSTRUCTION — THE HOIST'S REFUSAL CANNOT CARRY ITS PROMISED DIAGNOSTIC: recoverEmits = unique (map declare.kindOf (recoverDecls …)) (policy-recover.nix:89) returns KIND STRINGS — channel and commitment field ERASED BY THE PROJECTION, same truncation class as round 4's tryEval, one layer up. Position claim correct (outside envelope); diagnostic claim not. Deliverable: policy, kind, remedy; NOT channel/field. A9-undeclared as written FAILS the specified implementation. NAMED EDIT (position unchanged): refusal over the returned DECLS not the kind set — inside recoverEmits after recoverDecls returns, or a sibling projection emitsFor calls directly; both outside envelope, both keep channel/derived/routes/targeted in hand.
· S5 ★★ two-law exhaustiveness stated over POPULATIONS, mechanism partitions over EMISSIONS: an undeclared policy whose sentinel firing yields no commitment (hub-peer's own optionals shape — value sentinel evaluates or-false, empty effects, recovered [ ]) takes law (b) at dispatch, not law (a). UNION STILL TOTAL (recovery-with-pipeCommit already aborted at (a)) but not the doc's argument. EDIT: restate by emission; undeclared can take either; fourth A9 arm (undeclared + ctx-conditional ⇒ emitsUndeclared).
· S6 ★★ §2.7's declarations.nix:459 disposition rests on a FALSE CONSEQUENCE inherited unchecked from round-3 C-5: importEdgesOf's route arm returns [ ] identical to else — contributes zero import edges today, and cannot match anyway (pipeOp is a collection kind, acts = structural++resolution). Rename stays (vocabulary hygiene); justification replaced.
· ADJUDICATION 1 (§8 entry-2 form): ADMISSIBLE, independently derived — but admissibility is INHERITED FROM THE REFUSAL'S TOTALITY (a property of emitsFor/conformingProduce, not of bearsCommitment) which F6+S5 both touch. TWO CONDITIONS OWED: (a) THIRD-KIND TRIPWIRE — the day a third commitment kind exists the predicate must return WHICH kind = value-shape dispatch unambiguously; add beside "the day the refusal softens". (b) totality guard verified present (Boolean product, all disjuncts or-defaulted, compilePipe total) — the real hole of this class was §2.3.2's kindOf and the doc closed it this round.
· ADJUDICATION 2 (two-law totality): key ground REPRODUCES at compile.nix:177-197 (declared ⇒ no envelope FALSE at HEAD — the hoist's ground holds, synthesis fallback would have repaired the instance only); law (b) fires FOR ITS OWN REASON and FIRST (arm order :427 before :429; forcing confirmed via __action filter to WHNF); third-population hunt: NO silent path on the probed axes (policyRecovery=false → named abort :130; familyStamps=false WIDENS recovery, doesn't bypass; mintFleetWide calls emitsFor unconditionally :1266; inspect path raw-v1 disposition correct; unregistered records raise at :486-487) — NOT a proof of no fourth axis (stated).
· ADJUDICATION 3 (B22 fidelity): CHECK LANDS ON THE SOURCE SIDE — four field derivations verified against real compilePipe (pipe.nix:352-374, kind tables :31-46); targeted always-list constant-true by reading the constructor (tautology needs no model); corpus rows re-derived BY HAND from B4 + per-policy stage listing (different instrument, same table): shipped isSiteMarkData refuses exactly hub-shares, repaired bearsCommitment selects exactly hub-shares, round-4's selects all 16.
· ALSO: F1 repair + kindOf restatement verified at source; ★ F3 CITATION — AUTHOR RIGHT, GATE ROUND 4 INEXACT (default.nix:949 warns about the curried FLEET prefix; substance unaffected, channelSurfacesAt sound, flatten scoping fixed); S1 reconciliation present and sound (TWO→ONE correct); S2 §9.2.1 satisfies all three counts (message verbatim, fleet-level forced on channelNames a REQUIRED formal, per-node check, both siblings; enriched-context half stated unmeasured AT THE DESIGN SITE); A-set matches prose except A9-control (F5) and A9-undeclared's message (F6) — both consequential; A9-undeclared correctly written as the arm round-4's construction fails.
· DRIFT: every relied-on cell re-run, all reproduce (B2a/B3a/B3c/B4/B6/B9/B14/B16/B17/B20/B21/B23). REGISTER read-not-swept: entry 2 = adjudication 1; entry 3 independence confirmed structurally (both buildRoots anchors live, neither on §2.7's list); entry 4 side-correct; entry 5 contact live, correctly characterised (transitive __entry via nodeCoords→cellCoordsOf, no new reader); entry 1 untouched by positive reasoning.
· GATE LIMITS: NOTHING evaluated (source reads + text measurements only; F5/F6/S5/S6 chains not executed); B22 probe not re-run (hand re-derivation instead); r9/den-v1/Q7/gen-pipe-contribute carried; third-population hunt exhaustive over probed axes only.
NEXT: ROUND 6 minimum — F5 (two-kind obligation everywhere it binds), F6 (refusal over decls), S5 (emission axis + fourth A9 arm), S6 (justification swap), §8 third-kind tripwire. QUEUED behind papers writer slot (r15 in flight).

════ ★★ DESIGN ROUND 6 — O6-C, GATE ROUND 6 PENDING (2026-07-31, session 3, at f631973) ════
ARTEFACT: same path, FROZEN md5 `858e2bafeaa378730a64e28021cdc568`, 2363 lines (was 2007). Orchestrator double-sampled.
· GATE-r5 CLAIMS VERIFIED AT SOURCE before compliance (new B24, one entry per claim): F5 mechanism + legality confirmed (legality DERIVED BY READING deliberately — groups is edited by §2.2, a probe would evaluate the doc's own model); F6 confirmed both directions; S5 confirmed + corroborated; S6 confirmed both halves. ★ ONE GATE CLAIM WRONG, in-doc: F5's "§6 item 3" pointer — item 3 is the ops-law restatement, carries no codomain prescription; the codomain prescriptions are item 5 + new item 7, both fixed. Pointer only.
· ★★ F6 POSITION: INSIDE recoverEmits, over the decls recoverDecls returned, BEFORE the unique(map kindOf) projection. Reason: the ONLY candidate keeping the body applied ONCE — a sibling projection must call recoverDecls itself = second body application per undeclared policy (round-4 F3's doubling class one level up, avoidable only by a signature change to a shipped export). Adds no export/call-site/signature/application: one let of an already-computed value, one filter over (a.__action or null), one refusal errors.commitmentUndeclared taking the DECLARATION RECORD. What-each-layer-can-see table makes it a derivation. STATED LIMIT: the success-path map kindOf still raises unattributed on a tag-less decl — inherited ceiling, named. A9-undeclared's message now discriminates BOTH prior rounds (r4's truncation and r5's channel-less kind set).
· ★ F6 CLASS CHECK — projection audit table over this design's paths: recoverEmits REPAIRED; codomainStamps' codomainsOf CLEAN (row.fail fires at dispatch with record in hand); new recoverCommitments CLEAN by construction; conformingProduce CLEAN; ★ policyMessage's groupsOf IS A PRE-EXISTING INSTANCE (:199 names strata spanned, not the kinds spanning them) — dispositioned, not touched.
· F5 CLASS SWEEP — every codomain prescription found and fixed: precondition stated ONCE in §2.3 (one-way direction guarded: the GATE stays pipeCommit-only or every mark policy fires; legality derivation; codomain-vs-ops-field boundary witnessed at live-green silent-deletion inert). Carried: §2.3.1 remedy, §2.7 row (both renames complete — the row now binds FUTURE pipeCommit entries), §6 items 5+7, A9-control, A6+companion (companion stays one-kind — dropping that kind is what the pair measures). ★ THREE FOUND BEYOND THE GATE'S LIST: (1) A8's narrowing companion compiles only two-kind (its record carries marks by construction); (2) §11's `to` restriction; (3) ★★ A4 ASSERTED THE INVARIANT §2.3 WITHDREW LAST ROUND ("neither body can produce the other's kind") — a fixture asserting unconditional disjointness passes A4 and FORBIDS A9; restated as consequence-of-authorisation, exhibited on the declared branch only.
· S5 BY EMISSION: law (a) = pipeCommit in the returned decls; law (b) = dispatched pipeCommit ∉ admitted; undeclared can take either; fourth A9 arm added. ★★ CORROBORATION FOUND IN THE TREE: policy-recover.nix's own header property (2) (:14-22) already describes the (b)-taking undeclared policy ("a body that genuinely emits then violates a codomain this function invented for it") — quoted verbatim. ★ Round-5 attribution corrected: law (a)'s policy identity is emitsFor's `named` from ref.name (compile.nix:124/:202), not originName (that is law (b)'s dispatch-path mechanism).
· S6: rename kept, justification replaced with the measured one; round-3's false consequence marked. §8: THIRD-KIND TRIPWIRE added (second commitment kind ⇒ markFn's unauthorised branch must decide WHICH kind from field content = value-shape dispatch, adjudication FLIPS); gate condition (b) recorded; round-6's own new constructs re-checked against entry 2 (declared-kind tests, moving AWAY from the entry).
· REGISTER: all re-runs reproduce; ★ B22 RE-RUN FROM ITS KEPT PROBE PATH, every cell reproduces (today 1 = hub-shares; repaired 1 same; r4 16/16; untouched 15; four controls split as tabulated) with the in-doc note it is a drift check not a re-derivation.
· LIMITS: nothing evaluated except B22 re-run; two-kind precondition's markFn half is THIS DESIGN not a shipped fact (A9-control + A6 settle it); §2.3.1 positions single-step reads, A9's four arms settle; projection audit covers THIS DESIGN's paths not all of lib/; carried: r9/den-v1/Q7/gen-pipe-contribute/enriched-context-unmeasured/cell-precondition/B23-lib-only/corpus/parked-to.
NEXT: GATE ROUND 6 — dispatched. Count for this track at ZERO (r5 found construction). Named adjudications: F6's in-recoverEmits form (once-applied claim + the tag-less ceiling), the A4 restatement, the two-kind precondition's guarded direction.

════ ★★ GATE ROUND 6 VERDICT: REVISE — count stays ZERO (2026-07-31; reviewed md5 858e2bafeaa378730a64e28021cdc568 echoed; NOT REDESIGN — arity, declared-only gate, mode bake, two-sentinel split, kind pair, F6 HOIST and TWO-KIND PRECONDITION all survive). S0/C1/C2/C2-a/C7-b/C8/C9(cond)/C9-a PASS · C7-a named-miss · C5 mixed · C1-a/C3/C4/C6 FAIL (all four = F7). ════
· F7 ★★★ CONSTRUCTION — THE THROWING SENTINEL'S FIELD DOMAIN IS UNSPECIFIED AND BOTH READINGS ARE DEFECTIVE. §2.4.1 closed C-3 at the COORDINATE level; the identical class one level down (which FIELDS each synthetic entry carries) is never stated — §2.4.2 names exactly two (id_hash, name). MEASURED (P4/P5/P6): an or-defaulted attrpath whose FIRST step is missing defaults SILENTLY ({id_hash;name}.settings.….isHub or false → false), while a present-but-THROWING attribute is NOT rescued by or (P5: throw fires) — so §2.6 shape 2's stated behaviour is FALSE for the corpus's own read (host.settings.… — settings ∉ the two fields ⇒ commitment fire SUCCEEDS with an empty commitment; two live corpus instances). THE CHARITABLE READING (reuse shipped sentinelFields — probe-sentinel.nix populates class/system/hostName + settings as a MATERIALIZED submodule tree at its own defaults, threaded via _probeSentinelFields, features.probeSentinel default true) IS ALSO DEFECTIVE: host.settings resolves to the REAL DEFAULT ⇒ the body takes its default branch ⇒ the commitment is the default-branch value at every node with no funnel — O2's SHAPE, which §3's table says "never forms". A6 FAILS AS SPECIFIED (asserts named-abort-at-fire over hub-peer's or-false read; under the two-field sentinel: no abort) — FOURTH fixture-vs-prose instance, INVERTED: fixture right, mechanism wrong. §1.3's "every value read on it aborts" false for or-defaulted reads (C3). NAMED EDIT: specify the throwing sentinel as a THROWING TWIN of sentinelFields (probe-sentinel key set + bridge's settings, each a named throw; P5 proves constructible; cite probe-sentinel.nix as the key-set source); STATE THE RESIDUAL (or-defaulted read of a field OUTSIDE the set still defaults silently — the field-level analogue of §2.4.5's ctx ceiling); A6 stands once the set is named; companion for the residual.
· S7 ★★ §7's second green witness MISIDENTIFIED — compat-compile-golden:578's `ops = opChain …` is a TEST-LOCAL deepSeq attrset key over a FIRED declaration, not a policy record's static ops field (B10's predicate cannot separate them — the doc's own §2.2a class applied to an appendix cell, inherited from the bead record through r3-r6). Declared-ops path has ONE witness (silent-deletion:141, verified). §7 consequence 1 points at a line with no kind literal; the line with one (:396 test-pipe-op-kind) is named nowhere. EDITS: one witness; re-point golden row to :396 (successor pipeCommit — shapeMetric bears commitment per pipe-stages.nix:90-100); B10 predicate gains a record-field discriminator.
· S8 ★★ §2.3.1 property 4's GROUND refuted by the tree one comment from a range the doc read: compile.nix:161-172 says surface suites fire UNREGISTERED records ("pays a fire it never asked for"); four call sites in compat-compile-golden do (denCompat.compile fx).policies.<n>.fn { } — under the design those fire markFn on undeclared commitment-bearing shapeMetric and NO LAW REFUSES ON THAT PATH (law (a) lives in recoverEmits; emits never forced there). Conclusion survives on a different ground (pipeOps folds registered rules only ⇒ nothing reaches a fleet consumer) — restate over reachability; note the surface suites are where §7/§10's acceptance renames land.
· S9 ★ hub-peer's value-sentinel mechanism MISATTRIBUTED: at HEAD sentinelFields supplies settings as a materialized tree, so nothing is "missing" — the path RESOLVES to a default that happens to render false; a defaulted-true field would take the TRUE branch silently. Restate; state the defaulted-true direction as inherited.
· S10 ★ two loose one-kind remedy phrasings (:583 must name [ "pipeMark" ] — the two-kind remedy there would CONVERT A WORKING MARK POLICY INTO AN ABORT; :1921 first clause). I-1: the tag-less ceiling has a SECOND unnamed instance in the family (codomainsOf's bare kindOf at declarations.nix:344, reached from compile.nix:183; also conformingProduce :421) — limit narrower than the ceiling.
· ADJUDICATION 1 (F6 form): UPHELD — once-applied SOUND (one recoverEmits call site; sibling = second body fire; cheaper let-at-emitsFor form considered and rejected defensibly); diagnostic totality CONFIRMED AND STRONGER (mkActions constructors ride fields verbatim; channel bound unconditionally at pipe.nix:362; FREE STRENGTHENING: recoverDecls deepSeqs inside the envelope so the refusal's message can never throw; residual: pipeName may be ctx-computed ⇒ sentinel-derived string, attributable never absent); tag-less ceiling pre-existing, filter does NOT widen (P1-P3; masking direction is an IMPROVEMENT, unstated); message specified by content NOT verbatim (asymmetric with §9.2.1 — write it, A9-undeclared needs pinnable elements). QUALIFICATION: the layer table omits a FIFTH candidate (inside recoverDecls over try.value — excluded because codomainStamps shares recoverDecls for DECLARED policies, would abort an authorised commitment) — the discriminating fact lives in §2.3.1's hoist ground, not connected to the table; add the row.
· ADJUDICATION 2 (A4): UPHELD — catches both leak directions on the declared branch; A7-family mapping coherent (mixed STRATUM does not arise under O6-C); A-set sweep clean, no other fixture asserts the withdrawn invariant; fixture-vs-prose consistent across all arms EXCEPT A6 = F7.
· ADJUDICATION 3 (two-kind direction): CONFIRMED pipeCommit-only ×3 gate statements, not re-widened (92 pipeCommit lines, 63 pipeMark-less each READ); boundary witness CONFIRMED AT CI SOURCE (silent-deletion inert, suite membership confirmed, greenness carried not run).
· ★ GATE-r5's §6-item-3 POINTER CLAIM ADJUDICATED IN THE DOC'S FAVOUR (round-6 author was right). Round-6 self-corrections both verified (law-(a) identity at compile.nix:124/:202).
· DRIFT: B2a/B4/B9/B16/B23/B24 all reproduce; B22 NOT re-run (kept probe path is a prior session's scratchpad, unreachable — stated limit; corroborated via B4 re-run + r5 gate's hand re-derivation). GATE LIMITS: suite not run (greenness structural); six language probes = the only evaluation; F7's corpus consequence derived from P4/P5 + source reads, not a fired body; the ci pipeOp census remains a count (S7 dispositioned 1 of 16; the other 15 undispositioned by anyone).
NEXT: ROUND 7 minimum — F7 (field set + residual + A6 companion), S7, S8, S9, S10, I-1 + the fifth-candidate table row. QUEUED behind papers writer (r16 in flight). Count ZERO.

════ ★★ DESIGN ROUND 7 — O6-C, GATE ROUND 7 PENDING (2026-07-31, session 3, at f631973) ════
ARTEFACT: same path, FROZEN md5 `b57de130be592674c0d4bce40896d697`, 2958 lines (was 2363). Orchestrator double-sampled.
· F7 CLOSED (§2.4.1a, ~75 lines): throwing sentinel = THROWING TWIN of shipped sentinelFields — SIX keys (probe-sentinel's class/system/hostName + bridge's settings + probeEntry's id_hash/name), each a named throw; built as a key-projection over attrNames sentinelFields (reads KEYS not values — bridge's lazy submodule thunk stays unforced; cannot be a value-shape predicate, §8 note). P4/P5 quoted as the design's own justification, re-measured (B25). Both round-6 readings exhibited defective in-doc. RESIDUAL STATED + MEASURED (or-defaulted read outside the set defaults silently) in a THREE-LEVEL CEILING TABLE (coordinate CLOSED / field OPEN-bounded / ctx-key OPEN); residual's true domain derived down to declared-two-kind policies reading an unnamed field behind an or. Fixes: §2.6 shape 2 (WHNF story replaced + counterfactual), §1.3 (named-field claim; ABW argument shown unaffected), §3 lead + O2 row (+ new row: the residual is O2's OTHER HALF — single wrong constant, not per-node divergence), A6 stands as the field-set regression test, A6-residual + sub-companion added. CLASS SWEEP: 7 total-abort claims found, all 7 requalified (sweep lexical over the doc, stated).
· ★★★ THE VERBATIM MESSAGE FOUND A ROUND-6 CONSTRUCTION DEFECT: commitmentUndeclared was put in the WRONG FILE — policy-recover.nix's errors formal binds lib/compat/errors.nix (compat/default.nix:25, threaded :119-120; fail renders "den-compat:"), and policyCodomainUnrecoverable (the message it replaces on that path) already lives there (:254). §2.7 split into kernel/compat rows; A9-undeclared's prefix corrected to "den-compat: compose commitment:" with the note that asserting den-hoag: would assert the position did NOT move. Full message written VERBATIM in-doc (commitmentFieldsOf helper + four pinnable elements; empty render unreachable but forbidden from degrading — renders all three candidates, §2.4.4's rule).
· I-1: tag-less ceiling widened to the FAMILY (3-row table: recoverEmits :89 / codomainsOf :344 via compile.nix:183 DECLARED path / conformingProduce :421 every dispatch; root kindOf no-default :166); round 6 understated the family AND overstated the design's exposure (the or-null filter is the only one this doc touches, safe direction); closing the family = defaulting kindOf, explicitly NOT proposed. FIFTH CANDIDATE ROW added with the discriminating fact CONNECTED: the selector is not "outside the envelope" (three rows satisfy that) but "THE ONLY POSITION WHERE THE ABSENCE OF A DECLARATION IS ESTABLISHED" — fidelity narrows 4→3, caller-sharing narrows 3→1. Free strengthening recorded (deepSeq inside envelope ⇒ message-construction throw structurally impossible); pipeName ctx-computed residual recorded (fidelity limit, not totality); masking direction recorded as improvement.
· S7: ONE witness; consequence 1 re-pointed to golden :394-396 (successor pipeCommit; shapeMetric four deriving stages match derivingKinds) + the implied consequence stated: the ci rename is PER-FIXTURE by commitment-bearing, blanket rename either way wrong. B10 predicate REPLACED with a record-field discriminator (authors ∧ read back through pipeOps :519; exactly one fixture; discriminating control). ★ B16 SETTLED S7 INDEPENDENTLY: golden has exactly ONE "pipeOp" literal (:396) ⇒ :578 provably carries none — TWO APPENDIX CELLS CONTRADICTED EACH OTHER FOR FOUR ROUNDS and nothing compared them; recorded as the reason the predicate was replaced.
· S8: property 4 restated over REACHABILITY (pipeOps folds registered rules only ⇒ a fire with no consumer, not an unrefused contradiction); compile.nix:161-172 quoted verbatim. ★ GATE CLAIM CORRECTED: the call-site count is ELEVEN in golden (gate said four; both grep forms return 11 — every .fn in the file is an application; repo-wide ci/ 42 lines / 15 files). Gate's conclusion unaffected and STRENGTHENED. B10a new.
· S9: "defaults the missing selection" struck BOTH sites — nothing is missing; the materialized submodule default RENDERS false; or never exercised; fixture pins the VALUE; defaulted-true direction stated as inherited (property of the VALUE sentinel, which the twin does not govern — twin = commitment fire only).
· S10: :583 names [ "pipeMark" ] with the converse-abort reason written out (F5's defect mirrored — the one place the precondition's one-way direction must be HONOURED not restated); A8-narrowing clause fixed (contradicted its own companion two lines below).
· HYGIENE: seven "new this round" phrasings anchored to absolute round numbers. §6 cost note (twin = |sentinelFields|+2 unforced thunks per FLEET, F unchanged). §2.7 not-edited row names probe-sentinel.nix + bridge.nix positively (twin reads, never edits).
· REGISTER: B16 reproduces cell-for-cell; B10 old cell re-run (grep never wrong, PREDICATE was — domain wider than property, same class as §2.2a/§2.4.3, reached through an appendix cell); B22/B24 carried with the in-doc argument no round-7 edit can move them (predicates read compilePipe's record shape; this round changed the sentinel's field set). B25 = the round's only evaluation, a LANGUAGE-SEMANTICS probe over a hand-built attrset (10 cells discriminating both ways) — settles or/?/deepSeq/selection, settles NOTHING about which corpus bodies read which fields.
· LIMITS: §2.4.1a's residual UNBOUNDED DELIBERATELY (every which-fields-does-a-body-read instrument is file-level over a body-level property — a count would fail to a false positive; A6-residual is an exhibit not a bound); 14 of 16 ci pipeOp lines remain undispositioned (scope statement); F7 sweep lexical; suite not run; carried: r9/den-v1/Q7/gen-pipe-contribute/enriched-context/B23-lib-only/corpus/cell-precondition/parked-to.
NEXT: GATE ROUND 7 — dispatched. Count ZERO. Named adjudications: the errors-file relocation (round-6 defect found by writing the message — does anything else still point at the kernel file?), the six-key set's completeness (is there a SEVENTH key a corpus body reads?), the residual's deliberate unboundedness.


════ ★★ GATE ROUND 7 VERDICT: REVISE — count stays ZERO (2026-07-31; reviewed md5 b57de130be592674c0d4bce40896d697 echoed; NOT REDESIGN — arity, gate, bake, split, kind pair, F6 hoist, two-kind precondition, AND the twin-as-key-projection all survive; "the twin construction is right, and that is precisely why the constant six is wrong"). S0/C1/C2/C2-a/C7/C7-a/C7-b/C8/C9/C9-a PASS · C5 mixed (two coordinate drifts) · C1-a/C3/C4/C6 FAIL = F8. ════
· F8 ★★★ CONSTRUCTION — THE SIX-KEY FIELD SET IS NOT A CONSTANT; IT IS WIRING-INDEXED, AND THE SMALLER WIRING IS THE ONE 32 CI FILES USE. Measured: compat/default.nix:188/:294 pass staticSentinel (= probe-sentinel.nix directly) to the direct denCompat.compile surface — key set ["class","hostName","system"], ? settings FALSE (controls both ways) ⇒ probeEntry = FIVE keys there; sentinelFor (flake-module.nix:652-659, the compileFull/bridge path) is the ONLY producer of the four-key set ⇒ six. Surface split: denCompat.compile 98 lines/32 ci files vs compileFull 44/9. CONSEQUENCES: (1) §2.4.1a's "six keys" holds only bridged — B25 SAYS SO CORRECTLY ("at a bridged fleet"), the construction section dropped the qualifier; (2) §2.6 shape 2's named-abort ⇒ FALSE on the direct surface (settings absent ⇒ P4 ⇒ silent empty-commitment fire — verbatim the sentence that convicts Reading 1); (3) ★★★ A6/A6-residual STOP DISCRIMINATING on the direct surface (both arms become residual instances; the doc never states which surface either fixture is built on); (4) property 3's flag-off "loud, not silent" FALSE for or-defaulted reads (an EIGHTH total-abort claim, missed by the lexical sweep because phrased "loud, not silent"). ★ The mkDen-direct axis is named IN TREE at flake-module.nix:649-650, TWO LINES ABOVE the :651 comment the doc quotes — 0 occurrences in the artefact (control "bridge" 15) — same shape as round-6's defect: a fact one line from a range the doc read. EDITS: wiring-indexed field set (bridged 6 / direct 5 no-settings / flag-off 2) citing :188/:294/:649-650; requalify shape 2 + property 3 (loud for BARE, silent for or-defaulted); ceiling-table field row carries the index; A6 pinned to a stated surface (must build through compileFull or cannot witness settings).
· ADJUDICATION 1 (errors relocation): UPHELD, class hunt CLEAN — all six installed/edited errors.* checked against the file their call path binds (commitmentUndeclared+fire-site→compat ✓; emitsUndeclared+opsInBody→kernel ✓; ops law raises raw string, neither row ✓; §9.2.1 shadow refusal → output-modules errors formal = kernel ⇒ its den-hoag: prefix CORRECT ✓). Two COORDINATE drifts only: policyCodomainUnrecoverable at compat/errors.nix:252 not :254 (cited twice); bridge quote lives at :331-334 not :345-347 (cited twice) — B25 cites both correctly, the BODY cells drifted.
· ADJUDICATION 2 (completeness): ★★★ NO SEVENTH FIELD — all 16 pipes.nix bodies + all 15 other policy bodies READ (196 lines): only forced outer-body formal read on the 16 is hub-peer's host.settings…isHub (in the six); srcUser=user.name binds inside stage closures only (deepSeq never forces at the fire — the doc's own §2.4.2 argument). Across all 31: EXACTLY ONE outside-six or-defaulted formal read — environment.system-access-groups or [ ] (fleet.nix:47, env-to-hosts) — DOUBLY UNREACHABLE (not a pipe policy, no pipeCommit ⇒ gate never fires it; same body forces environment.name, a NAMED field, first). ⇒ THE RESIDUAL HAS ZERO REACHABLE INSTANCES ON TODAY'S CORPUS. Twin construction verified (probeEntry = {id_hash;name} // sentinelFields, key-projection does not force the bridge thunk). ★ INSTRUMENT: a 17TH pipe-bearing policy exists OUTSIDE pipes.nix — project-user-overlays (quirks/nixpkgs-overlays.nix:20, pipe.from + expose, pure site mark ⇒ B22 conclusion unaffected) — B4/B4a/B22's "16" is file-scoped; restate population as 16-in-pipes.nix + 1-in-quirks.
· ADJUDICATION 3 (unboundedness): RIGHT IN GENERAL, WRONG HERE — the doc owns a body-level instrument (B4a reads three bodies) and collapsed "unbounded in general" with "unmeasured on the 16"; the gate performed the bounded read and IT COMES OUT IN THE DESIGN'S FAVOUR (measured-zero). EDIT: keep the general refusal verbatim + add the bounded corpus result with its instrument named + the fleet.nix:47 near-miss and its unreachability. "A residual stated as unmeasurable when it is in fact measured-zero costs the design the strongest sentence it could write."
· OTHER ITEMS: S8 count — AUTHOR RIGHT, gate-6's four refuted (11 confirmed independently; B10a cell-for-cell); B10 replacement isolates one fixture with a live discriminating control; B16 cell-for-cell (S7's :578 settlement confirmed); A9-undeclared's four elements ALL PIN against the verbatim message (derived is the only populated clause for hub-shares); §8 value-shape note HOLDS (F8 does not move it — a wiring-indexed key set is still keys); S9 correct at source (citation drifted); S10 both land; three requalified claims spot-checked, all preserve their load; B25 re-run independently, 10/10 cells; 16 further coordinates spot-verified, only the two named drift. REGISTER: entries 1-5 all correctly dispositioned.
· GATE LIMITS: nothing evaluated except B25 re-run + two key-set evals; suite not run; F8 derived from source + key-set eval, not a fired fixture; 16-body read is nix-config only ("corpus-complete" = THIS corpus; den-configs' 19 + 13 templates unreached); 14 ci pipeOp lines still undispositioned; no A6 exists in tree to check — which is the point.
NEXT: ROUND 7-fix minimum — F8's four edits, two coordinate corrections, adjudication-2's corpus-complete measurement written into §2.4.1a, adjudication-3's bounded-result paragraph, population restated 16+1. QUEUED behind papers writer (r17 in flight). Count ZERO.


════ ★★ DESIGN ROUND 7-FIX — O6-C, GATE ROUND 8 PENDING (2026-07-31, session 3, at f631973) ════
ARTEFACT: same path, FROZEN md5 `a94ad83191096b23e6d6196140511817`, 3405 lines (was 2958). Orchestrator double-sampled.
· F8 LANDED: §2.4.1a wiring-index sub-block (bridged 6 / direct 5 / flag-off 2, key-set EVAL with ? settings control, :649-650 quoted verbatim); ceiling field row carries index + measured-zero; §2.6 shape 2 → 3-row wiring table with the DIRECT surface named as the behaviour not a counterfactual; property 3 requalified (the eighth claim, phrasing-miss recorded); A6 PINNED to compileFull (on direct both arms are residual instances — instrument-returns-a-constant); A6-residual pinned with the mirror reason.
· ADJUDICATION-2 WRITTEN IN with the ★ DISCRIMINATOR that makes it refutable: FORMAL reads count, REGISTRY reads do not — cluster.environment or "" (clusters.nix:29) and hostCfg.environment or "prod" (fleet.nix:69) are outside-set or-defaulted but read let-bound registry lookups; a naive `\.\w+ or` predicate reports 3 residuals where the true count is 0. Positive control stated. ZERO REACHABLE INSTANCES, scope nix-config only. ADJUDICATION-3: general refusal verbatim + bounded paragraph beside it.
· COORDINATES both fixed (:252; comment-quote :331-334 vs code :345-347 — B25's code citation left, now labelled). POPULATION 16+1 restated with B22's conclusion held on a STRUCTURAL ground (pure site mark ⇒ 17-input table reads 1/17, 17/17, 1/17).
· ★★ THREE GATE-r7 FIGURES CORRECTED IN-DOC, each with cause: (1) surface split 86/30 not 98/32 — gate's predicate lacked a word boundary, swallowed its own compileFull control (86+12=98, arithmetic identifies it; conclusion unaffected: 26 exclusive-direct vs 5 exclusive-bridged, overlap 4); (2) LIVE POPULATION 30 NOT 31 — clusters.nix:44's den.policies.cluster-to-hosts is COMMENTED (control: # over the 31 match lines → exactly one) ⇒ 16 + 14; (3) B15 undeclared 21 not 22. ★ SELF-CAUGHT pre-freeze: env-to-hosts guard is fleet.nix:69 not :74 (fixed 4 sites, never shipped).
· CLASS CHECKS: (1) wiring index swept — 12 sites indexed, ★ ONE THE GATE DID NOT NAME: the S9 A9-arm — gate-6's "nothing is missing" fix is TRUE BRIDGED ONLY; on direct, settings IS missing and rounds 5-6's original mechanism is correct THERE; arm's conclusion holds at both but the fixture pins a VALUE bridged and an ABSENCE direct ⇒ pinned to compileFull matching A6 (A-set no longer straddles two surfaces claiming one mechanism). Knuth/ABW shown INVARIANT under the index (which fields are named changes the guarantee, not the citation). (2) sweep re-run with loud/silent/named-abort added: eighth confirmed + five further hits dispositioned — §2.6 shape 1 + A1 HOLD AT EVERY WIRING (funnel through user.name + probeEntry's wiring-invariant literals — the one family member needing no index, stated as a positive result); §2.4.3's "named aborts for any body reading a coordinate field" NEWLY REQUALIFIED (the shipped set is wiring-indexed too). Lesson in-doc: a lexical sweep's output is a list of found sites, never a claim of exhaustion. (3) ★ METHODOLOGICAL: a coordinate-SET diff CANNOT find the bridge drift — body and appendix both cite :345-347, targets differ; the instrument must compare (coordinate, quoted-target) PAIRS; ran that over every quote-bearing body cell — only the gate's two diverge; limit stated.
· ★★ DRIFT: ONE CELL DID NOT REPRODUCE — B15's coord-field census: cell said 78/12, two instruments agree on 88/12 (per-file counts printed and summed). No argument moves (the census bounds nothing; the bound is 21 from the population) — and THAT is written in-doc as the reason it survived four rounds: A FIGURE CARRYING NO LOAD IS A FIGURE NOBODY RE-RUNS. Corrected at 3 sites. B4/B9/B16/B2a/B25 reproduce; B22/B24 carried; NEW B26 (4 parts: key-set eval, wiring read, surface split with the correction arithmetic, corpus-complete body read with discriminator + 3 limits).
· LIMITS: suite not run; only B26 part 1 evaluated; corpus-complete = nix-config only; B26 part 4 answers the or-defaulted-unnamed-field predicate and does NOT discharge B15's bare-read-named-field one (§2.4.3's alternative not re-priced — stated in both cells); 14 ci pipeOp lines undispositioned; carried limits unchanged. Tables 0 misaligned.
NEXT: GATE ROUND 8 — dispatched. Count ZERO. Named adjudications: the S9-arm surface split (does the A-set now claim one mechanism per surface correctly?), the three gate-figure corrections, B15's no-load-figure lesson, the (coordinate, quoted-target) pair instrument.


════ ★★ GATE ROUND 8 VERDICT: REVISE — COUNT RESETS TO ZERO (2026-07-31; reviewed md5 a94ad83191096b23e6d6196140511817 echoed; NOT REDESIGN — all prior survivors incl. wiring index survive). S0/C1/C2/C2-a/C5/C7/C7-a/C8/C9-a PASS · C7-b/C9 fail-narrow · C1-a/C3/C4/C6 FAIL = F9. ════
· F9 ★★★ CONSTRUCTION — THE THROWING SENTINEL HAS EXACTLY THE FAILURE MODE §2.4.1 SAYS IT HAS NOT. §2.4.1's widening ground (":1086-1089 — the throwing sentinel has no such failure mode") is MEASURED FALSE: the twin is itself an attrset; substituting it for a list-typed default yields the SAME UNCATCHABLE type error, and the twin's fields are NEVER FORCED when it does (q2: error shows all five fields as «thunk» — the whole finding in one cell). The asymmetry is FIELD-READ vs VALUE-TYPE consumption; the quoted rationale's own example (elem g accessGroups) is the second and reads no field. CORPUS EXHIBITS THE SHAPE: env-users (users.nix:107-115, accessGroups ? [ ] consumed via lib.elem in the outer body) — REACHABLE ZERO (declared [ "member" ] ⇒ gate never fires it); corpus defaulted-formal population 4, three list-typed. CONSEQUENCES: (1) the widening is now a TRADE priced at zero (C7-b); (2) ceiling table's coordinate row CLOSED → OPEN-UNCATCHABLE (strictly worse than the field residual; the "two closed one bounded" ladder has ONE closed); (3) ★★★ §2.4.4's attribution re-measure is a SECOND INDEPENDENT INSTANCE — its per-coordinate probe binds the VALUE sentinel to the other coordinates, so on a ≥2-coordinate body with a type-consumed defaulted formal the synthesized diagnostic NEVER RENDERS; "the abort fires regardless" is FALSE — same diagnostic-destroyed-by-boundary class as r4-F2/r5-F6, this time in the instrument added to survive that class; (4) "total" = total in EXTENT not behaviour. Absence control: "expected a list" exactly 2 hits in-doc, both the refuted rationale. EDITS (six, named): asymmetry sentence replaced with the q1/q2 pair + «thunk»; totality requalified; ceiling row; §2.4.4 position decision (restrict to requiredCoordsOf — the domain the value sentinel is known safe on — or state the residual) + strike "fires regardless"; C7-b price; coordinate-level ceiling fixture (A3's companion precedents).
· S11 ★★ the THIRTEENTH wiring site = §2.4.1a's own corpus-read headline: "EXACTLY ONE outside-set or-defaulted formal read" is 1 bridged / 2 direct / 2 flag-off (hub-peer's settings read is outside the direct set); the ⇒ paragraph four lines below already names and dispositions the second ⇒ section contradicts itself rather than being wrong; reachable-zero unaffected. EDIT: index headline + B26 cell.
· S12 ★★ A3's disposition rests on the WRONG DOMAIN (grounded on the closed coordinate domain; its abort requires reading a NAMED FIELD = the wiring-indexed field domain; holds at both wirings but under F9 fails outright for a type-consumed defaulted coordinate). EDIT: re-ground + name the field its body reads.
· S13 ★ C9 entry-5 extension undisclosed: the design ADDS two __action tag-filter sites (§2.3.1's unauthorised filter + §2.3.2's law) — refusal-path not consumer dispatch, side defensible, but the register rule requires saying so; entry-5 census re-measured 8 live / 4 files. EDIT: §8 paragraph.
· ADJUDICATIONS: (1) S9-arm split UPHELD — full A-set walk, exactly three settings-dependent arms all pinned, rest surface-invariant by POSITIVE reasoning (the one defect found = S12's ground); (2) all three r7-fix figure corrections RE-DERIVED CORRECT (86+12=98 arithmetic confirmed; the commented line identified; 21 = 30−9) — the doc is right against gate 7 on each; (3) B15's 88 verified per-file cell-for-cell; ★ CLASS AUDIT: every remaining figure carries load or is explicitly marked — THE LESSON IS APPLIED, NOT MERELY STATED; no second no-load figure; (4) pair-instrument spot-checks all verify (both repairs + 6 bare coordinates cold — zero drift beyond the repaired two); (5) sweep completeness: S11 is the thirteenth; a fourth ROUTE to the two-key set found (compile.nix:60's sentinelFields ? { } native-caller default) but same key set ⇒ no claim moves; "sentinelFor is the only producer of the four-key set" CONFIRMED (compileWithSentinel exactly one consumer).
· DRIFT: B26 parts 1/3/4 re-run/verified (part 4's unreachability argument STRONGER than stated — fleet.nix:46 forces environment.name in an attrpath index one line above envGate); B23/B16/B3c/B2a reproduce; S10 + A8-narrowing fixes in place; envelope census accurate. C9 entries 1-4 correctly dispositioned, 5 = S13.
· GATE LIMITS: only two evaluations (9-cell catchability probe — language-semantics class, settles nothing about which bodies reach the shape; corpus attribution is a source read; 5-cell key-set re-run); defaulted-formal census file-level text predicate, four hits read, 30 bodies NOT independently re-read; B22/B24 carried; A-set walk over fixture PROSE (no fixture in tree — still the point); §2.4.4 judged on its TEXT (if intended domain is requiredCoordsOf, consequence 3 dissolves, 1/2/4 stand); suite not run.
NEXT: ROUND 8-fix — F9's six edits + S11 + S12 + S13. COUNT ZERO. QUEUED behind papers main-checkout writer (r18 in flight; d1-spec worktree author independent).


════ ★★ DESIGN ROUND 8-FIX — O6-C, GATE ROUND 9 PENDING (2026-07-31, session 3, at f631973) ════
ARTEFACT: same path, FROZEN md5 `7dbc9c5e81b047f5506d7cef3fef40aa`, 3847 lines (was 3405). Orchestrator double-sampled.
· F9 CONFIRMED CELL-FOR-CELL BEFORE COMPLYING (B27, imports the REAL probe-sentinel.nix): q1/q2 uncatchable (twin's fields all «thunk» — elem's arg check reads the TYPE TAG, selects no attribute, the throws never reached), q3 field-read catchable, q4 value-sentinel success; ★ uncatchability FORCED not printer-inferred (.success re-run: q1/q2 exit 1, q3 prints false exit 0 — nix eval renders errored attrs as «error» either way, so the re-run IS the discrimination). §2.4.4 probe measured on env-users' shape: probe_wide uncatchable ⇒ diagnostic never renders; probe_required runs; ★ the residual is PRE-EXISTING AT HEAD (shipped recoverDecls on a type-consumed REQUIRED formal → uncatchable — inherited, measured).
· ALL SIX F9 EDITS LANDED: asymmetry sentence replaced with the 4-cell table + «thunk» reading; the DOMAIN ANSWER SURVIVES (requiredCoordsOf-only loses the commitment silently = O2; loud-uncatchable beats silent-wrong — what dies is "free", stated); total split EXTENT/BEHAVIOUR; ladder now NONE closed / coordinate open-uncatchable / field open-bounded-measured-zero / ctx-key open, ORDERED by catchability not counted, with the honest framing (the widening converted silent-wrong into loud-uncatchable — an improvement, not a closure); §2.4.4 probe domain DECIDED to requiredCoordsOf with the opposite-failure-directions derivation; "fires regardless" struck, achievable claim stated; §6 item 8 BOUGHT/PAID trade (4 defaulted formals / 3 list-typed / reachable ZERO — ★ env-users is the body the round-3 gate cited TO JUSTIFY the widening, unreachable only because its author declared a codomain); A3-coordinate-residual fixture NEW (asserts the uncatchable case AS the ceiling; wiring-invariant for a NEW reason — the abort precedes any field selection).
· S11/S12/S13 landed (headline indexed 1/2/2; ★ the gate's fleet.nix:46 strengthening carried — attrpath index aborts CATCHABLY, stronger than the :69 guard; A3 re-grounded field-domain with the field NAMED host.class, no pin needed, fails flag-off = the flag's documented ceiling — ★ BOTH halves of r7-fix's disposition were wrong; entry-5 paragraph with the ★ pricing point: both new sites are spelled (a.__action or null), the spelling the register records as UNDERCOUNTED by exact-form greps — naming them is what keeps them findable; census 8 live / 4 files).
· CLASS CHECKS: (1) instrument-cannot claims — 5 sites, 2 changed 3 hold with named domains; ★★ UNCOMFORTABLE LIMIT WRITTEN IN-DOC: F9's site was INSIDE round 7's sweep vocabulary and the sweep READ PAST it (the sentence asserts a negative about a SIBLING mechanism, not totality about its own) — "a sweep that reaches a site and mis-reads it is worse than one that misses it, because it records coverage". (2) over-wide probe domains — 3 found: fire keeps attrNames DELIBERATELY (decided asymmetry); §6's failure-path figure moved DOWN to |requiredCoordsOf|; §3's "a diagnostic never destroyed" claim corrected — §2.4.4 had NOT escaped the destroyed-diagnostic class until the restriction (3rd occurrence of the pattern: r4-F2, r5-F6, here — an instrument added to survive a class reproduces it in the DOMAIN it quantifies over). (3) ladder citations — 4 updated + ★ one the gate did not name: §2.4.5's "The one residual" heading, stale since round 6, retitled.
· ★ TWO ADDITIONS BEYOND THE VERDICT: (a) hub-peer cells corrected — produces-by-name.nix:39 reads [ "pipeOp" ] AT HEAD; [ "pipeMark" ] is the POST-§2.7-rename value; both sites now name HEAD and post-rename separately (neither names pipeCommit ⇒ gate skips it on either side — conclusion never moved, the cell did); (b) B27 part 3's own false positives written in (widened predicate returns 9, two are the ? has-attribute operator — the 4-dir scope excludes them for the right reason).
· DRIFT: B26 parts 1/3 reproduce exactly (86+12=98 holds); §6 renumbering verified sequential 1-8 with the item-3 pointer still resolving; 30 tables 0 misaligned.
· LIMITS: suite not run; B27 parts 1-2 language-semantics (recoverDecls NOT invoked, no corpus body fired — which-bodies-reach-the-shape answered only by the part-3 READ with a read's limits); 30 bodies not re-read this round; fixtures still not in tree incl. the two added; class checks lexical/this-doc's-positions; carried limits unchanged.
NEXT: GATE ROUND 9 — dispatched. Count ZERO. Named adjudications: the domain answer's survival derivation (loud-uncatchable beats silent-wrong — is the DIRECTION argument sound under C4?), the §2.4.4 opposite-failure-directions derivation, the sweep-misread limit's class (does any OTHER negative-about-a-sibling sentence hide a mis-read site?).



════ ★★ GATE ROUND 9 VERDICT: REVISE — COUNT STAYS ZERO (2026-07-31, session 4; reviewed md5 7dbc9c5e81b047f5506d7cef3fef40aa echoed BOTH samples; den-hoag HEAD 6dc4d44, f631973 ancestor, lib/ci/parity diff empty ⇒ anchors live; register MECHANIZED per standing ruling: script re-ran every stated-command row — 85 OK / 0 DIFF / 1 N/A). S0/C1/C1-a/C2/C2-a/C3/C5/C7/C7-a/C8/C9/C9-a PASS · C6 pass-with-condition · C4+C7-b FAIL = F10. Arity/declared-gate/bake/twin/wiring-index/F6-hoist/kind-pair all survive. ════
· F10 ★★★ CONSTRUCTION — §2.4.4 SPECIFIES TWO DIFFERENT PROBE DOMAINS. The mechanism sentence keeps the OUTER LOOP wide ("for each c ∈ attrNames gate") and narrows only the BACKGROUND bindings to requiredCoordsOf; every consequence-carrying restatement (cost bullet, §6 figure, §2.7 edit row, class-sweep 2) reads the domain narrowed outright. MEASURED on B27's own env-users body (attrNames = [accessGroups,host], requiredCoordsOf = [host]): probe_required (c=host) → success; probe_c_is_defaulted (c=accessGroups, the OTHER iteration of the written loop) → UNCATCHABLE «thunk» abort — verbatim the failure probe_wide was measured to convict. B27 part 2's single cell models the NARROW reading while the prose one paragraph above states the wide one — law-37 shape (domain narrower than quantifier) REPRODUCED INSIDE THE ROUND'S OWN NEW INSTRUMENT, fourth occurrence of the class the doc names as third. Under the narrow reading the probe survives but a DEFAULTED COORDINATE IS STRUCTURALLY UNATTRIBUTABLE and no section says so — and the corpus's one price-paying body (env-users, §6 item 8) has its guilty coordinate exactly there. EDITS: state the outer-loop domain ONCE (must be requiredCoordsOf — wide is measurably defeated); correct the mechanism sentence; ceiling-ladder row for defaulted-coordinate-unattributable; fixture arm owed by the doc's own no-undemonstrated-ceiling posture.
· ADJUDICATION 1 (C4 direction): SOUND FOR THE FIRE — gate measured BOTH legs (fire_all → uncatchable refusal; fire_required_only → succeeds SILENTLY with the default-branch value = O2's shape, previously asserted, now reproduced). Refusal is the safe direction; "what dies is free" correct; both repairing disciplines stated (declared codomain without pipeCommit — env-users unreachable by exactly that route, produces-by-name.nix:37 = ["member"]; typed synthetic ctx named and declined). The argument DOES NOT CARRY to the probe: true of the background bindings, silent about the loop = F10.
· ADJUDICATION 2 (opposite-failure-directions): EIGHT STEPS VERIFY at source + eval (requiredCoordsOf policy-recover.nix:41; fire binding :59-64; q1-q4 re-derived independently; twin ? id_hash true; attrNames probeEntry ≡ twin — arms differ only in VALUES; inherited residual confirmed pre-existing at HEAD). The QUANTIFIER step fails: property established for one arm, stated of the loop.
· ADJUDICATION 3 (sibling-negative class hunt): ELEVEN sentences — one mis-read reached site (S14), one true-on-wrong-ground (S15), NINE HOLD (each checked at source; incl. mixedStratum-unraisable scoped to lib/+ci/ with checkStratum on the exported declare surface :495 — scope stated).
· S14 ★★ STATEMENT-LEVEL — §2.4.3 "no existing projection of recoverDecls reads a VALUE" FALSE at source: codomainsOf suppress row keysOf = a: [ a.name ] (declarations.nix:307) + member row attrNames (a.bindings or { }) (:318). ops is NOT the first value-bearing projection; suppress { name = "p-${host.class}"; } recovers "p-«sentinel»" silently TODAY at codomainStamps. B14's own wording is narrower ("contribution VALUE") — the body dropped the qualifier. Construction survives (blast-radius bound 21-vs-1 carries the bullet without the premise); the ARGUMENT fails — the three-way rule. DISCHARGE: register-check row reading declarations.nix:303-320.
· S15 ★ STATEMENT-LEVEL — §9.2.1 restates B4's file-scoped transform cell as a corpus figure AFTER the doc re-scoped that cell (round 7-fix). Fact holds (corpus-wide census: broadcast 4 / collect 9 / collectAll 4 / expose 2 / from 17 / transform 1 — the one transform IS hub-shares), ground does not. The only surviving consumer where the correction did not propagate. DISCHARGE: repoint at the corpus-wide row (now in the gate's register script as adj3).
· S16 ★ STATEMENT-LEVEL — §6 item 8's "stack trace naming the policy file" is unmeasured by its own instrument (B27 never called recoverDecls; the gate confirmed the trace mechanism but its trace named the PROBE file; nothing bridges recoverDecls→deepSeq→gen-pipe). Ranking survives regardless (stopped build beats wrong config). DISCHARGE: armed CI row, or demote to "Nix's own message, attribution unmeasured".
· S17 STATEMENT-LEVEL — B8's positive control ("attrset-pattern lambdas → 36") has NO STATED COMMAND — the half that converts 0 into an absence finding is the half that cannot be re-run; every other absence cell states both. + trivial: header line 3 still reads "Round 7.".
· GATE'S OWN INSTRUMENT ERRORS, disclosed: first pass reported 13 DIFFs, ELEVEN WERE THE GATE'S OWN (grep -c ||echo double-emit ×2; comment hits read as raise/call sites ×2; -A1 against multi-line attrsets; wrong awk anchor; missing head -1 ×2; wrong roster predicate; order-sensitive census diff) — each resolved to the stated cell; a gate shipping those would have manufactured findings. adj2.nix models the DIRECT wiring only (5-key twin); uncatchability is wiring-invariant by the «thunk» argument (type check selects no attribute) but the bridged arm was not independently re-measured.
· GATE LIMITS: output-modules/gather/bridge/flake-module/concern-quirks spot-read by coordinate only — §9.2's four-expression sizing + byte-neutrality NOT independently verified; suite/fleet/recoverDecls/compilePipe not evaluated; B22 carried; r9 doc unread (§1.4 + §9.1 arm-iv coordinates unverified); den-configs 19 + 13 templates unreached; Q7 closure figures not re-derived.
NEXT: ROUND 9-FIX — F10's named edits; S14 requalify (restore B14's dropped qualifier in the body sentence); S15 repoint; S16 demote-or-arm; S17 state the control command; header. COUNT ZERO. QUEUED behind papers main-checkout writer (u-r19 in flight).



════ ★★ DESIGN ROUND 9-FIX + OWNER-RATIFIED SPLIT — O6-C, GATE ROUND 10 PENDING (2026-07-31, session 4, at 6dc4d44) ════
ARTIFACT SET (orchestrator-verified md5s, double-sampled by author): CORE specs/2026-07-31-compat-ops-seam-design-spec.md `93e5ae3396b8d56f2e5d311a494bda17` 3250 lines (was 3847) · LEDGER …-spec.ledger.md `e00314720779a7605a2a509dbb20f6a8` 1220 · SCRIPT …-spec.register.sh `2597b235293afb3b0accf7c351a84a69` 188. Anchor re-pin f631973→6dc4d44 with control (1 real changed file repo-wide = .beads export).
· ★★★ F10-b — NEW CONSTRUCTION DEFECT THE GATE DID NOT REPORT, FOUND BY MEASURING F10: §2.4.4 specified the probe's envelope as bare "under tryEval" — a policy body returns a LIST whose WHNF is the list, so a bare tryEval NEVER REACHES the coordinate read; attribution was EMPTY BY CONSTRUCTION for every policy the recovery can process at all (ground: recoverEmits' own projection requires a map-traversable return — not a corpus survey). Measured 5 cells: attrib_tryOnly true (not attributed) / attrib_tryDeep false (attributed) / both no-read controls true (deepSeq does not turn every arm false) / wide_tryDeep uncatchable. §2.4.4's own forbidden degradation would have been the NORMAL outcome. Envelope now stated in the mechanism sentence: recoverDecls' own `tryEval (let a = fn args; in deepSeq a a)` (policy-recover.nix:59-63).
· F10 ALL FOUR LANDED: domain stated ONCE governing both positions (c ∈ requiredCoordsOf gate; defaulted bound in NEITHER position); wide form STRUCK not deprecated, with B28p1 on env-users' shape (wide arm uncatchable «thunk» ×5 / narrow succeeds / ctl_narrow still attributes a field-read); FOURTH ceiling-ladder row — DEFAULTED COORDINATE AS CAUSE = OPEN-STRUCTURALLY-UNATTRIBUTABLE (the price of the domain that makes the probe run; abort still fires catchably, names policy/channel/remedy, message falls to full-coordinate-set-as-candidates) — ★ and the row is LIVE: env-users' guilty coordinate accessGroups ? [] is defaulted — the coordinate row and the attribution row are the SAME BODY seen from the fire and from the probe; ladder now a LIST not a number (NONE closed / coordinate open-uncatchable / field open-bounded-zero / ctx-key open / attribution open-structural — the count drifted twice before, said in-doc); A3-defaulted-residual fixture MEASURED INTO SHAPE with ★ two candidate bodies REJECTED IN-DOC for passing-for-the-wrong-reason (or-defaulted read → fire succeeds, asserts nothing; empty-default bare read → probe uncatchable, exhibits the WRONG ceiling) — the default must carry the field the body reads; paired with A3, differ in exactly one thing.
· S14 LANDED: qualifier restored ("contribution VALUE"), both prior value-readers named — ★ gate's coords OFF, measured :308 (suppress keysOf [a.name]) / :322 (member attrNames bindings), recorded not adopted; suppress { name = "p-${host.class}"; } recovers "p-«sentinel»" TODAY — O2's shape at the suppression codomain, shipped, neither created nor closed here; §2.4.3 re-grounded on the blast-radius bound alone.
· S15 LANDED as B4-corpus, census RE-RUN corpus-wide: broadcast 4 / collect 9 / collectAll 4 / expose 2 / from 17 / transform 1 (at pipes.nix:143, inside broadcast-syncthing-hub-shares) — ★ TWO figures differ from the file-scoped cell (collect 9 vs 7, expose 2 vs 1); modules/ = whole population (scope check same run).
· S16 WITHDRAWN AND ARMED: trace claim replaced by "attribution unmeasured"; trade re-argued on the surviving ground (a STOP vs a green wrong build); CI ROW A3-coordinate-residual-trace owed (§10) with BOTH outcomes informative.
· S17 REPLACED NOT CORRECTED: 36 reproduces under NO candidate predicate (4 tried; but the finding does not depend on exhaustion — a figure with no command cannot be re-derived OR refuted, which is the defect); new control = SAME regex over a scope where the shape EXISTS (den-hoag lib/+ci/ → 3 hits) — a different regex returning a big number cannot separate "no body uses the shape" from "the regex matches nothing"; ★ hazard measured: 2 of 3 hits BREAK THE LINE after @{ — multi-line spelling confirmed. Header → Round 9.
· CLASS SWEEP 1 (domain-vs-quantifier inside instruments; READ not grepped): LINEAGE PRECISE — §2.4.4's domain stated three ways across the arc, (i) wide/wide struck by F9, (ii) wide/narrow struck by F10 AND IT IS THE REPAIR THAT PRODUCED IT, (iii) narrow/narrow survives; convicts-3-times-produces-3-times written out. TWO further found + repaired: §2.2a's disjunct audit domain FROZEN AT ROUND 5 (four later predicates never entered; three correct, ONE DEFECTIVE →) ★★ §9.2.1's per-node shadow check quantified over `enriched` ALONE, one of THREE operands the // fold shadows — surfaces.values keyed by attrNames (local // gathered) (output-modules.nix:986-988) nowhere established ⊆ channelNames; a channels key arriving that way passes both checks. REPAIRED TO TEST THE FOLD: base = enriched // genAttrs channelNames (_: []) // surfaces.values, then base ? settings || base ? channels — total on keys-of-base, byte-neutral; ★ what it is NOT total over stated (sibling NAMES enumerated literally; third sibling needs third disjunct; construction named). LIMIT: cannot see a loop an implementer writes at landing — both repairs stated as RULES.
· CLASS SWEEP 2 (dropped qualifiers B-cell↔body): 146 citations / 30 distinct cells read; EIGHT found repaired (verbatim both sides in-doc), ★★ SIX OF EIGHT = ONE CELL'S ROUND-7-FIX SCOPE CORRECTION (B4/B22 pipes.nix-scoped) NEVER PROPAGATED TO A SINGLE CITING SENTENCE — a cell can be repaired and leave every consumer wrong; nothing re-reads a citation when its cell moves. Items 3-5 repaired to a MEASUREMENT (pipe.to|as → 0 corpus-wide, control from → 17 same run). LIMIT: sweep reads citation-vs-cell; uncited restatements + wrong cells outside it.
· SPLIT TAKEN, VERBATIM, VERIFIED: core 3250 + ledger 1220 (rounds R1 153 / evaluated-set R2 24 / appendix B1-B28+coverage R3 982 moved); per-region byte-diff IDENTICAL ×3 (md5s in report) + multiset equality (4400 = 4434 − 34 new preamble/pointer lines, EXTRA 0 MISSING 0); every fenced block stayed in core; distinct-cells-cited = 30 before AND after (now a register row); 3 dangling cross-refs repointed. ★ Anti-split argument answered in the ledger preamble: S14's class is body/cell mismatch and distance is neutral — SELF-SUFFICIENCY is the fix (all eight sweep sites now self-sufficient in core).
· REGISTER MECHANIZED: register.sh 60 pass / 0 drift / 8 skip EXIT=0 (skips = nix-eval cells + B20 + B10a, each with reason). ★ Law-41 bit its own author once: the instrument-error bullet's new B-mentions drifted the ledger-citations row 140→150 — caught by re-run. Entry-5 __action census re-run at 6dc4d44: 8 live / 4 files; §8 re-check: all three new constructs move AWAY from entry 2.
· AUTHOR'S INSTRUMENT ERRORS (4+1, all wrong-answer-producing, all disclosed in-doc): zsh unquoted-parameter no-word-split → missing instrument rendered as absence finding (B8's control collapse exposed it); git diff Changes: banner overcounts; grep -c overrides -o (7 vs true 8); ★★★ law-38 INSIDE the register itself — the no-wide-loop row grepped a one-line phrase while the core carries the sentence WRAPPED in a quotation — sound predicate, different proposition, PASSED for the wrong reason; replaced with all-8-occurrences-dispositioned + newline-flattened sentence check; left written out because this is the one failure a register cannot detect about itself.
· LIMITS: B28 language-semantics over hand-built values (recoverDecls NOT invoked, no corpus policy fired, no fixture in tree, ci not run — bounds F10/F10-b to defects OF THE SPECIFICATION, which they are); corpus = nix-config 425f1d3b one witness; ★ B20's 30-channel roster states NO COMMAND, could not be re-derived (32-line neighbouring property found, not adopted), SKIP row — same class as S17, flagged not fixed; B14's "exactly two call sites" is a read over 8 grep lines.
NEXT: GATE ROUND 10 — first gate over the SPLIT set. Count ZERO. Named adjudications: (1) F10-b's envelope claim vs recoverDecls source (is deepSeq-over-tryEval the right reading of :59-63, and does the no-read control really discharge it); (2) the §9.2.1 fold-check repair (byte-neutrality + the stated third-sibling residual); (3) the six-of-eight propagation mechanism — does any OTHER corrected cell have unpropagated citations (the sweep covered citations; check the cells whose wording CHANGED across rounds); (4) the split verification + the B20/S17 no-command class (two members now — is there a third?).



════ ★★ GATE ROUND 10 VERDICT: REVISE — TWO CONSTRUCTION FINDINGS, COUNT STAYS ZERO (2026-07-31, session 4; all six md5 samples match start+end; both repos pinned clean; register 60/0/8 re-run identical at exit; SIX independent spot-re-derivations with a DIFFERENT instrument all agree). S0/C1-family/C3/C4/C5/C6(note)/C7-a/C7-b/C8/C9-a PASS · C7 FAIL=F12 · C9 FAIL=F11. ════
· F11 ★★★ CONSTRUCTION (C9) — THE SPEC TOUCHES __entry AT FIVE SITES AND NEVER CITES rb0, WHICH REGISTER ENTRY 5 NOW REQUIRES ("a brief touching __entry cites rb0" — rule added at THIS HEAD, after this spec froze; orchestrator's edit, the F5-hygiene shape now CHARGEABLE because load-bearing). §9.1 ground 2's central same-value argument rests on cellCoordsOf reading decls.__entry; §9.2 already forbids exactly rb0's failure mode ("a missing-user contribution must abort named, never silently drop a member") and derives its risk ONLY from cell-vs-host-root — rb0 supplies a SECOND independent way for the same precondition to fail, silent and or-swallowed. rb0 → 0 in core AND ledger with a firing bead-id control (6 other ids found). The invisible-to-word-sweep shape again: design vocabulary producer.scope/cellCoordsOf, register vocabulary __entry/systemViews — one hop apart. OWED: cite rb0, state the side, and answer REACHABILITY (is __entry nullable on the user-cell path the replicateHome emitter takes, or is rb0 confined to system-bearing roots?) — gate did not resolve; needs the fleet dcx's acceptance already owes; may land as a stated limit + the citation if the measurement is deferred to dcx WITH the deferral said.
· F12 ★★ CONSTRUCTION (C7) — §9.2.1 enumerates the SIBLING names one level above the fold repair it just made, declining the named construction on a FALSE COST GROUND: builtins.any (k: base ? k) (attrNames siblings) replaces the two-name disjunction at equal expression count; the siblings are already an appended attrset literal (one let); attrNames forces only the WHNF // already forces ⇒ byte-neutral by the section's own argument, net cost ZERO. The document's own convicted class ("recording its output and not its domain makes every later addition invisible") + the convicted owed-to-a-future-author remedy shape. EDIT: adopt the construction at both check levels.
· F13 STATEMENT — F10-b's justification OVER-QUANTIFIED: "every policy whose body returns a list" is refuted by lib.optionals c l (WHNF forces c) — measured 7 cells incl. hub-peer's verbatim shape ATTRIBUTED under bare tryEval at the bridged twin. Construction unaffected (deepSeq right regardless; no cell attributes less); correct scope = bodies whose WHNF forces no coordinate read (literal-list outer expression; 15 of 16 pipes.nix bodies) — conclusion survives at the narrower quantifier. ★ Gate's own first run was a FALSE CONFIRMATION (direct twin: settings absent ⇒ P4 defaulted the condition silently — the document's own wiring index told the gate to re-run bridged). DISCHARGE: the two *_cond_tryOnly cells + controls.
· F14 STATEMENT — B4-corpus's headline HALF COMMENT-CONTAMINATED: comment-excluded census collect 7 not 9 (two comment mentions in aspect files declaring no pipe); expose 2 genuine (nixpkgs-overlays.nix:23). FOURTH comment-blindness instance through an appendix cell, inside the cell minted to repair S15. to/as = 0 verified uninflatable; from 17 all live; transform 1 stands.
· F15 ★★ STATEMENT — THE ROUND-9-FIX CITATION SWEEP REACHED FIVE SITES AND MIS-READ EACH (law 43 inside the law-41 instrument; answers adjudication 3 INVERTED — the uncited complement is CLEAN, hunted via superseded values, zero hits; the defect is that a sweep's READING is unverified and nothing re-runs a reading): (a) ladder ctx-key row quotes control 36 = the one figure S17 struck, while asserting commands exist; (b) §2.3.1 property 4 says FOUR call sites vs B10a's measured SIX (gate re-verified 6 inline; :198 is the other shape); (c) §6a "31 definitions" vs B9's 31-matches-one-commented ⇒ 30 live; (d) §2.2 "16 corpus" = S15's exact class at a sentence outside the sweep's list of eight; (e) B26p4 clusters.nix "×2 live" — measured 4 matches / 1 commented ⇒ 3 live, and the enumeration sums 13 vs its own stated 14 (with 3 it sums correctly) — ★ gate read the third body: cluster-to-nixidy's formal reads are BARE cluster.name (wiring-invariant named field, loud at the twin) ⇒ MEASURED-ZERO SURVIVES, the roster line alone is wrong.
· F16 STATEMENT — ledger's self-referential citation count stale by TEN (:1130 says 140, register's own predicate measures 150, script hardcodes 150 and passes) — script and prose disagree in the exact category the script's header claims to cover.
· F17 STATEMENT — attrNames-gate disposition tally 2+2+3=7 for a count of 8; :1815 carries TWO occurrences (a fire-domain + a negation); true breakdown 2/3/3. Register checks the count, cannot see the breakdown.
· ADJUDICATIONS: (1) F10-b VERIFIED at source :59-64; no-read control SUFFICIENT for its named confound; inter-coordinate discrimination supplied by part 2 (re-run: probe_required false / probe_defaulted true, one-variable pairs); ★ UNSTATED direction found: an intrinsic value-sentinel failure fails EVERY arm and attributes every required coordinate — harmless (degenerates to the documented fallback) but §2.4.4 states incompleteness only (false negatives) — add the false-positive direction. (2) fold repair byte-neutral ✓ for a STRONGER reason than the doc gives (base is literally the left operand of the existing final // at :1025-1040); operand claim ✓ at :986-988; third-sibling residual: C6 SATISFIED (a future sibling is a code change, not an input) but C7 FAILS = F12. (3) propagation complement CLEAN; the sweep's readings are the defect = F15. (4) NO third no-command member — B20 IS re-derivable in one line (all cells reproduce: roster 30, 44/35, channels-formal 0, controls 46/2 — SKIP over-conservative, state the command); §10's parked-fixtures 9 reproduces; Q7's 162/17 are disclosed-and-carried (different category).
· C9 NOTE measured clean: §9.2 edits output-modules.nix (entry-1 residue file) — channelsOf reads received id, not channelBindingsAt (B17 control: exactly one call site :1036) ⇒ no contact; but §8's entry-1 disposition is scoped "§2 reads no class content" while §9 is what edits the file — extend the coverage statement.
· GATE'S OWN ERRORS: first F13 run used the DIRECT twin and produced a false confirmation (re-run bridged on the doc's own wiring index); draft envelope arg-order caught pre-eval; all four known traps checked by construction.
· GATE LIMITS: ★★ SPLIT VERIFICATION UNFALSIFIABLE — all three artifacts UNTRACKED in the papers repo, no archive, pre-split file unreachable ⇒ "moved verbatim" is structure-verified only (citations 133 / cells 30 / defined 35 reproduce). COMMITTING THE ARTIFACTS WOULD MAKE NEXT ROUND'S CHECK POSSIBLE. No fleet/ci; F11 reachability open; nix-eval cross-check partial; corpus one witness.
NEXT: ROUND 10-FIX — F11 (cite rb0 + side + reachability-or-stated-deferral-to-dcx), F12 (adopt attrNames-siblings at both levels), F13 (requalify the universal + add the false-positive direction to §2.4.4's caveat), F14 (comment-excluded census in B4-corpus), F15 (five sites re-read against cells, then RE-READ THE OTHER citing sentences too — a sweep's reading is unverified), F16 (:1130 → 150), F17 (breakdown 2/3/3), B20 command stated + SKIP lifted, §8 entry-1 coverage extended to §9. COUNT ZERO. ★ PROCESS: papers artifacts to be COMMITTED at round boundaries from now on (orchestrator action this session) — two tracks have now hit unfalsifiable-pre-state.



════ ★★ DESIGN ROUND 10-FIX — O6-C, GATE ROUND 11 PENDING (2026-07-31, session 4, at 6dc4d44) ════
ARTIFACT SET (orchestrator-verified, committed at the papers round boundary): CORE `b43702b24f5514f7fbe0c46a06cfb540` 3428 · LEDGER `1e3718cc9cdfdc064b97439881081a17` 1415 · SCRIPT `2fa2f230781d97bc58b35e743be415cd` 266. Register 87/0/7 exit 0 (27 rows added, one skip lifted).
· F11 DISCHARGED, REACHABILITY ANSWERED BY SOURCE READ — NO DEFERRAL TO dcx NEEDED, and the answer is STRONGER than "no": (1) the fold's domain is mapAttrs over baseScopeRoots — ROOTS ONLY (default.nix:1210-1227); (2) cells mint elsewhere from the gen-product cell (fleet.nix:112, __entry = leafEntry :155-159), no fold rewrites cell decls; (3) cellCoordsOf reads one node per axis — the HOST axis of a cell coordinate reads a folded root and IS exposed, the USER axis is not; (4) ★ they cannot come apart in the direction that matters: fleetChildren binds hostEntry = node.decls.__entry POST-fold (:1243) into product.slice — rb0's consequence-2 death fires BEFORE any cell exists. ⇒ ON A NULLED FLEET: abort-before-cells, or clean user coordinate — NO state delivers present-but-null producer.scope.user to the hub. The abort is loud-but-unattributed; that diagnostic is rb0's, not this design's. §9.1 root half NARROWED honestly (same-valued by MINT, not by construction at the read — the fold sits between); cell half survives BY CONSTRUCTION, the half §9 needs. ★★ dcx ACCEPTANCE CHECK STRENGTHENED: producer.scope ? user admits user = null — the check becomes `producer.scope.user or null != null`, presence AND non-nullity, one named abort covering both. rb0 cited with title/status/consequence arms; the design proposes NONE of rb0's remedies — cited as a constraint the design must survive, and it does.
· F12 DISCHARGED at both levels: any (k: elem k channelNames) siblingNames (fleet) / any (k: base ? k) siblingNames (per-node), siblingNames = attrNames siblings, one let; byte-neutrality BY IDENTITY OF EXPRESSION (base IS the left operand of the shipped final // at :1030-1039 — not an equality argument); owed-paragraph DELETED; §2.2a audit +2 rows.
· F13: universal requalified to a property of the OUTER EXPRESSION (literal-list, 15 of 16); refutation grounded at nixpkgs lib/lists.nix:822 (optionals forces cond at WHNF); TEN cells one expression exit 0 — attribution is WIRING-INDEXED (hub-peer's conditional body attributed bare-envelope at the BRIDGED twin, reads NOTHING at the direct twin — ctl pair makes it a measurement); §2.4.4 caveat gains the false-positive direction (best-effort BOTH ways, neither turns refusal into success).
· F14 ★ THE CORRECTION INVERTED ONE OF ITS OWN CLAIMS: comment-excluded census collect 7 = pipes.nix's 7 — the "collect 9 vs 7" divergence was ENTIRELY comment blindness; only expose genuinely differs (2 vs 1, nixpkgs-overlays.nix:23). Conclusion survives on one witness. Fourth comment-blindness instance stated in-cell; both arms checked rows (unfiltered baseline reproduces; filtered non-zero all six spellings ⇒ sed not a universal suppressor).
· F15: five sentences re-verified BY RE-RUNNING each cell's command — (b) was wrong TWICE (:198 is the OTHER B10a group; correct six enumerated, now a checked row); (e) cluster-to-nixidy's formals read INSIDE the map closure (not WHNF-forced) and name is bound at all three wirings ⇒ wiring-invariant loud, measured-zero survives. ★ CLASS RE-READ: ALL 131 citing lines above the Appendix re-read against current cell wording — the full population, not a sample; none beyond the five required change.
· F16: counts re-derived LAST (core 133→144, ledger 140→156, register hardcode→156); distinct-cells 30 UNMOVED (the orphan/invention signal).
· F17: true breakdown 2 fire / 3 negations / 3 quotations = 8 (the miscount: §2.7's edit row carries TWO on one line); register now checks the per-line occurrence PROFILE (1 1 1 1 1 1 2) + one row per disposition class + a computed sum row.
· B20 skip LIFTED as SEVEN rows with the alternation DERIVED from the roster in the same pipeline (halves cannot drift) + the channels-0 second half the prose asserted commandless; §8 round-10 re-check (any/attrNames strictly FURTHER from value-shape; F11 adds a read, no predicate); entry-1 disposition extended past §2 with the measured channelsOf/received-id argument.
· ★★ AUTHOR'S TWO INSTRUMENT ERRORS, both the F17 CLASS RE-COMMITTED INSIDE THE INSTRUMENT BUILT TO DETECT IT, both caught by REGISTER SHAPE (two rows disagreeing over one population): the negations row counted line-wise and missed a wrapped "not `attrNames gate`" (item-4's hazard, recorded four items up, reproduced by an author who had READ it); the quotations row over-counted because the fire row's text CONTAINS the quotation predicate's substring — one occurrence counted twice in one class, zero in another, TOTAL PASSING AT 8 THROUGHOUT. Ledger items 5-6.
· LIMITS: F11 is a source read (no fleet, no systemViews fixture; writer's domain + reader's binding established); B28p1c hand-built bodies (hubpeer cells use the corpus body's TEXT, not its evaluation); comment filter strips from first # (a # inside a string literal would truncate — every removed line READ, three genuine, but the predicate needs a parser for the guarantee); B10a partition still a read (explicit skip); suite not run.
NEXT: GATE ROUND 11. Count ZERO. Named adjudications: (1) the F11 reachability derivation — four steps, each a source claim: verify each at HEAD, and adjudicate whether abort-before-cells is established or an evaluation-order assumption (does ANY path demand a cell before fleetChildren forces hostEntry?); (2) the dcx acceptance strengthening (or-null != null) — sound against S9's materialized-default finding?; (3) F13's wiring-indexed attribution table — re-run the ten cells; (4) the register's new profile rows — do the disposition classes partition (no occurrence in two classes, none in zero)?



════ ★★ GATE ROUND 11 VERDICT: REVISE — TWO CONSTRUCTION FINDINGS, COUNT STAYS ZERO (2026-07-31, session 4; all six md5 samples match; register first-run 87/0/7 exit 0, final-run 2 drifts BOTH the implementation lane moving the working tree past the pin — every source figure re-taken at 6dc4d44 via git show/git grep <rev>; four rows independently re-derived at the pin, all PASS). S0/C1/C1-a/C2/C2-a/C3/C4/C7/C7-a/C7-b/C8/C9/C9-a PASS · C5 FAIL=F-C · C6 FAIL=F-B · + F-A construction. ════
· F-A ★★★ CONSTRUCTION — F12's siblingNames DERIVATION CANNOT BE EVALUATED WHERE CHECK 1 MUST RUN: check 1's stated position is the file's top-level let, once per fleet, BEFORE any node is demanded ("a refusal that fires only when someone demands the sibling is not a refusal"); but siblings = { settings = settingsBindingAt id; channels = surfaces.records; } is NODE-INDEXED (bindingsAt = id: at :1025; settingsBindingAt = id: :1019; channelBindingsAt = id: :944) — not in scope at top level. Neither horn free: moving check 1 into bindingsAt destroys its stated purpose; a different top-level expression re-opens F12's drift. WORKING FIX = a third expression: hoist a node-INDEPENDENT sibling skeleton, derive BOTH the fleet-level key set and the per-node attrset from it — which refutes F12's own "costs one let binding, naming an existing expression" cost claim. ★ The document's recurring shape (decision stated in one position while the mechanism keeps two) REAPPEARING IN THE REPAIR for F10's sibling finding. Round-9's two-literal form WAS top-level-placeable; F12 fixed domain, broke position.
· F-B ★★ CONSTRUCTION (C6) — THE dcx ACCEPTANCE ABORT COLLAPSES THREE DIFFERENTLY-OWNED CAUSES: user absent because the node is a ROOT not a cell (emitter at wrong scope — corpus remedy); PRESENT-BUT-NULL (rb0's fold — rb0's remedy, unchosen); scope ITSELF null (gen-pipe's `scope = producer.scope or null` default fired — third upstream). The predicate is SOUND AND TOTAL (measured, six shapes + controls — see adjudication 2) — the defect is the refusal specified by content only, against the doc's own standard (commitmentFieldsOf written verbatim BECAUSE "the author's next move differs by shape"; §9.2.1's OTHER refusal names which-collision-and-both-remedies "because the two collisions have different owners"). Round-6 I-1's asymmetry recurring. EDIT: verbatim message naming WHICH of the three.
· F-C STATEMENT (C5) — fleet.nix:112 cited for leafEntry binding; :112 is a COMMENT, binding at :129 (claim TRUE, coordinate wrong — the register's own cite-by-binding-name decay mode, on the paragraph added to satisfy entry 5). + two ranges starting one line early (:155-159 → opens :156; :1030-1036 → begins :1034).
· F-D STATEMENT — core:2912 carries the sentence the ledger's own F14 repair INVERTS (collect 9-vs-7 was entirely comment blindness — never re-pointed in core), AND both artifacts undercount the live divergence: expose 1→2 AND from 16→17, BOTH from the single line nixpkgs-overlays.nix:23 (conclusion STRONGER than either states). The register checks cells, not prose conclusions drawn from them — a coverage gap in the instrument built for this class.
· F-E STATEMENT — three probe-provenance overstatements: B28 has NO inlined source (prose tables only, cells not independently reconstructible); "broadcast-hub-peer VERBATIM" — condition verbatim, payload stand-in (cells survive, word does not); the lib.optionals nixpkgs provenance (three nixpkgs in play, byte-identical, citation carries no rev). + probe_required NAMES TWO DIFFERENT CELLS (B27p2 vs B28p2 — disambiguate).
· F-F STATEMENT — F13's 15-of-16 derived from a CLOSED SPELLING LIST (optionals|mkIf) narrower than its property — `map` also WHNF-forces (measured) and is in neither the list nor the literal-list class; FIGURE HOLDS (gate read all 16 outer expressions independently) but the instrument is the enumerate-don't-close shape, over a corpus with 30 live definitions not 16. + the REAL env-users has NO host formal (functionArgs = { accessGroups }; requiredCoordsOf = [ ] ⇒ the narrow loop has ZERO arms) — B28's model adds one; F10's direction SHARPER on the real body (the wide loop has exactly one arm and it is the bad one; empty attribution = row 4's prediction) but "env-users' own shape" overstates a hand-built model.
· ★★★ ADJUDICATION 1 (F11 reachability): ESTABLISHED BY CONSTRUCTION, NOT EVALUATION ORDER — all four steps verified at the pin (leafEntry :129; the only cell-node minter is cellChildrenFor, reached only via fleetChildren through the children NTA; the other product.cells site builds the den.cells OUTPUT — no decls); STRICTNESS MEASURED per link (acc // forces RHS WHNF w/ lazy-values control; listToAttrs forces spine w/ lazy-values control; ★ gen-product view.nix:190 puts baseKeyAt d0 in ATTRIBUTE-NAME POSITION — forced before lookup, or [ ] cannot absorb it, UNCATCHABLE expected-a-set-found-null, reproduces rb0's consequence-2 message character-for-character — STRONGER than the spec's "loud but unattributed"). Two qualifications, neither a hole: "dies before any cell exists" is PER-SYSTEM over-general — the fold applies per nodeSystem; the guarantee is PER-CELL (a cell exists ⇒ its host's __entry forced non-null), stronger AND simpler than the fleet disjunction; step (iv) is belt-and-braces (§9 reads only the user axis, clean by (i)+(ii) alone). Laziness-hole hunt explicit: NO HOLE (containmentRelation mints records not nodes; den.cells is coordinate tuples; production-spawned nodes a separate NTA, not systemViews-reachable).
· ADJUDICATION 2 (dcx or-form): SOUND BOTH QUESTIONS — S9's materialized default CANNOT reach this check's domain (producer.scope = nodeCoords via decls.__entry, never an option default; the one default on the path is name, types.str, cannot render null; ★ the check guards user while the consumer reads user.name — §9.1 closes that gap by construction and says so); the or-form is NOT the D1 swallowing class: D1's class is `or <a value that answers>`; here the default is A SENTINEL THE VERY NEXT OPERATOR TESTS — that IS the null-aware form (a let-spelling is the identical expression with a name). Six shapes measured incl. or-does-not-rescue-a-throw + bare-null-uncatchable control. Residual = F-B's message.
· ADJUDICATION 3: ALL TEN F13 cells reproduce (re-derived from the ledger's PROSE — which is how F-E's no-inlined-source gap was found); uncatchables forced alone with direct exit capture; optionals cited correctly for den-hoag's pin.
· ADJUDICATION 4: THE PARTITION HOLDS at freeze (all 8 hand-classified, 2/3/3, line 1866 the double taking DIFFERENT classes — why the subtraction exists); enforced by the SUM row (arithmetic invariant), NOT by construction; two stated blind spots: a future fire spelled without "total" lands in zero classes (sum catches as bare drift, not named class error); ★ THE SUM IS INVARIANT UNDER A CLASS SWAP — re-wording a quotation into the fire spelling passes the register with a wrong disposition. Instrument enforces against add/remove, not relabel.
· DISCHARGE CHECKS: F12 fold-form verified INCLUDING byte-neutrality-by-identity (:1034-1036 prefix + :1037-1039 sibling) — but F-A; F14 both arms re-run (collect 7=7 confirmed; the lone-divergence claim itself wrong = F-D); F15 all five verified (six-site predicate exact; 30-live reconciles 16+14); F16 three counts PASS (★ F16 lives only in ledger+register, nowhere a core reader looks — defensible, noted); B20 seven rows reproduce with both controls non-zero; §8 census exact at pin AND at f631973 (anchor guarantees agreement; at today's HEAD five of nine have moved); entry-1 one-consumer claim exact; rb0 citation accurate on every element.
· GATE'S OWN ERRORS: first repo-pin check reported the PAPERS HEAD under a DENHOAG label (caught, re-run); full register run pre-reading (correct at that moment, tree moved twice after — all figures re-taken at pin); two probes hid siblings behind an uncatchable cell in a multi-cell attrset (split to single-cell w/ direct exit capture — "{ success = false; } inside an attrset is not the same claim as an uncatchable abort"); one zsh pipestatus index slip (figure unaffected).
· GATE LIMITS: corpus one witness; no fleet/fixture/suite; F11 = source read + strictness probe on the exact expressions, not an end-to-end nulled-fleet eval; systemViews' own type declaration not independently pinned (restatement of rb0's, which carries its coordinate); nix-eval cells beyond F13 unre-run; F-A is a reading of placement sentences (construction unimplemented); prose-conclusion coverage gap = F-D's home.
NEXT: ROUND 11-FIX — F-A (the hoisted node-independent sibling skeleton feeding both levels + correct F12's cost claim); F-B (verbatim three-cause message); F-C coordinates by binding name; F-D re-point core:2912 + the from divergence + a register row for prose-conclusions-of-cells; F-E (inline B28's source; requalify "verbatim"; rev the optionals cite; disambiguate probe_required); F-F (restate 15-of-16's instrument as read-not-grep + model-vs-real env-users). COUNT ZERO. QUEUED behind papers main-checkout writer (unification r22 in flight).




## Comments (51)

### 1 — 2026-07-29T02:05:26 · Jason Bowman

★ Cross-reference, 2026-07-29: an in-flight task is establishing whether THIS bead and den-hoag-4kh.36 (pipe run-wiring: pipe.append/filter/to not applied, 15 commented-out divergences) describe THE SAME CONSTRUCT — both read as 'the compat pipe op DAG is built and never applied'. A defect tracked twice is itself a legibility defect, and this arc has already found a stale bead gating a live P0 through exactly that kind of duplication.
Carrying the same owner directive recorded on 4kh.36: any pipe work must also verify den-hoag is properly leveraging gen-pipe, scanned to PRIMITIVE granularity, against the PINNED rev rather than the local clone. If gen-pipe already provides the composition this bead says is built-and-unapplied, the remedy is wiring rather than construction.

### 2 — 2026-07-29T03:36:32 · Jason Bowman

★★★ THIS CLUSTER IS NOT TWELVE FIXTURES. IT IS WHY THE CORPUS CANNOT BUILD.
MEASURED 2026-07-29 over nix-config 4acf0a1d with den-hoag overridden in, exit codes read directly.
`axon-01` and `cortex` BOTH abort NAMED with the SAME message the twelve known-red den-pipe tests carry:
    den-hoag: compose commitment: policy `__kindInclude__user__policy__8` produced a `pipeOp` declaration
    carrying a derived-channel DAG or a delivery route from its BODY
★ IT IS **NOT** the `nixpkgs.hostPlatform` error a 2026-07-27 comment recorded for this path — a different
error, so that earlier diagnosis is superseded rather than confirmed.
★ AND IT IS IDENTICAL IN BOTH gen-schema ARMS (the current pin and a rollback to c6331f30), so it is NOT
attributable to the registry/getSubOptions work landing.
★★ WORKS-ON-DEN GATE ARM (a) PASSES ON THE SAME HOST: `axon-01` built on the corpus's OWN pinned den v1
(99cc0c5a), no override, EXIT 0, real derivation
`/nix/store/wg8ihlp68m5cbsh47lijk3yxry8wi4mb-nixos-system-axon-01-….drv`.
⇒ THE CORPUS IS FINE. den-hoag IS THE DIFFERENCE. And the difference is this defect.

WHAT THAT CHANGES ABOUT PRIORITY. The `ops`-as-a-static-field defect has been carried as a test-suite
concern: twelve known-red fixtures, an attribution question, and a decision about whether to declare them.
It is not. **IT IS THE THING STOPPING THE CORPUS FROM PRODUCING A SINGLE NixOS TOPLEVEL.** Every other corpus
blocker in the graph sits behind it, because nothing downstream of a toplevel can be measured until one
builds.
⇒ AND IT RETROACTIVELY STRENGTHENS THE ORCHESTRATOR RULING ON den-hoag-i5m (do NOT declare the twelve): they
were already judged an UNIMPLEMENTED SURFACE rather than a known-fail, because the compliant form cannot be
authored — no compat-compiled policy record ever carries `ops`. Declaring them would have pinned as
"correctly refused" the exact construct that blocks the corpus. The ruling was right for a reason weaker than
the one now available.

THE REMEDY REMAINS `4kh.53.64` — the `ops` representation. `lib/errors.nix` states the defect in full and
says plainly *"the fleet compose seed's construction is wrong UPSTREAM of this shim rather than merely
unwired here... Do not work around this in the shim."* The measured reason it cannot be a static field is in
that same comment: nix-config's `broadcast-syncthing-hub-shares` has a `pipe.transform` with
`role = "derive"` whose function closes over `user.name`, so THE OPS OBSERVED AT TWO DIFFERENT USERS DIFFER —
a record field cannot hold a per-node value.

★ NOTE THE POLICY NAME IN THE CORPUS ABORT: `__kindInclude__user__policy__8` — a POSITIONALLY INDEXED
compat-generated name, the same brittleness already recorded for `__kindInclude__user__policy__0` in the
den-pipe cluster. Any diagnostic keyed on that name re-targets silently when the corpus's policy list is
reordered.

### 3 — 2026-07-29T04:17:50 · Jason Bowman

★★★ FIRST SPEC — 454 lines, md5 a28c509b73772c4b327a4fa9f4a436ed, committed papers 7e32364.
★★ AND THE FIRST SPEC THIS SESSION WITH A REAL EXECUTABLE CORE: a SEPARATE file,
`specs/2026-07-29-ops-representation.core.nix`, 297 lines, md5 75429fa5647f94371647b6fb95866565.
**INDEPENDENTLY VERIFIED BY THE ORCHESTRATOR: `nix eval --impure --expr 'import <core>'` -> EXIT 0,
`"core: 6/6"`.** And it carries a MUTATION CONTROL — inverting one assertion gives
`error: core FAILED: guard-silent-when-clean`, exit 1. **The harness discriminates.** Compare the sibling
specs: 51 of 948 lines that did not evaluate at all, and 30 of 720 of which only a third did.

THE DESIGN. **DELETE THE `ops` FIELD.** A pipeOp becomes a per-node COLLECTION-STRATUM DECLARATION — exactly
as site marks already are — and the fleet DAG becomes a QUERY over them, deduped by gen-pipe's L12a
declaration-site id. It splits into SHAPE (strings: channel, derived ids, ops, route targets — ctx-independent
BY CONSTRUCTION, and the only thing `compose` forces) and PAYLOAD (`f`/`p`/`init`, mark payloads —
ctx-dependent, never forced by compose).
★ AND IT IS NOT RECOVERY-BY-EXECUTION: the pipeOp is produced by the node's REAL firing, so den-hoag-9xo.72's
undecidable question is **not answered — it is NOT ASKED.** That is the distinction the whole 9xo.75 thread
was reaching for.
SEED: "ONE fleet compose" SURVIVES and becomes TRUE rather than aspirational — today it contains no pipe ops
at all, since `pipeOps` is always [ ]. The seed is PER-SITE, so single-compose is preserved. It needs exactly
one decoupling: `collections.nix` attribute 10 must take the pre-compose channel decl instead of
`quirkDag.channels.<n>`, which removes the only edge that would make the stratum lowering cyclic.
GUARD: `opsInBody` / `isSiteMarkData` / `opsOf` / `pipeOps` / the field all RETIRE, replaced by
`shapeDisagreement` — same-site shapes must agree, quantified over EMITTERS not all nodes (subset firing is
legal), with a vacuity control in the same run.
COST: growth variable is **DECLARATION SITES, NOT NODES** — corpus 17 sites, one deriving.
WITNESS: the discriminating input EXISTS IN THE CORPUS — `broadcast-syncthing-hub-shares` at two users; old
aborts, new yields two records DIFFERING IN THE `user` FIELD. ★ **The discriminator is the DISTINCTNESS, not
the evaluation** — an "it evaluates" witness would pass on a design that applied one user's `f` to both.

★★★ THE CODOMAIN TRACE — THE RULE I ADDED TO THE REGISTER TODAY PAID OFF IN THE FIRST SPEC WRITTEN AFTER IT,
AND IT CAUGHT A DEFECT THE DESIGN WOULD HAVE **CREATED**. Traced hop by hop:
`site` <- `policyId` <- `"__kindInclude__<kind>__policy__<i>"` from `imap0` over `policyRefs` <-
`den.schema.<kind>.includes`. ⇒ **THE SITE KEY IS A POSITIONAL INDEX INTO A CORPUS-ORDERED LIST.**
den-hoag-1kd records that brittleness about a *diagnostic*; under this design it would have been the
**FLEET-WIDE DEDUP KEY**, so a corpus reorder would SILENTLY RE-ASSOCIATE one node's payload with another
site's channel. Handled as a GUARD, not a concession: `siteOf` derives from `ref.name` — the stable v1
identity `gateSuppression` already keys on — with the positional key surviving only for anonymous include
functions, spelled `«anon»` and recorded as a named ceiling.

C9, THREE PARTS: entry 3 THEORY survives (Apt/Blair/Walker is already the kernel's cited theory; strata are
already declared data); MECHANISM survives and IMPROVES — **the design REMOVES A HOIST rather than adding a
stage**; ARGUMENT explicitly does NOT lean on "the pre-pass already stages" — the register's own distinction
cuts the other way, since the pre-pass breaks a cycle in a REPRESENTATION and this design has no cycle to
break and removes the one edge that would create one. **If the pre-pass retires tomorrow, nothing here
changes.** Entry 5 hit directly with the side stated: the pipeOp STAYS as node payload DELIBERATELY — it is
not an edge, coordinate or provenance stamp, it is a per-node value; its route records ARE edges and already
land post-migration.
★ AND THE HIT A WORD-SWEEP WOULD HAVE MISSED (the document contains neither `__action` nor "sum type"
elsewhere): entry 5 records `__action` re-dispatched at ELEVEN sites as
`builtins.filter (a: a.__action == "…")`. **The obvious way to write the seed query is a TWELFTH.** It is
specified to read the pre-grouped `actions.collection` instead. **That changed the mechanism.**

THREE ITEMS LEFT OPEN, all honest: (1) the ONE gen-pipe surface change — `map`/`filter` operator functions
must receive the evaluation position, which `foldC`/`scanC`/`overC`/`joinC` already take — is SPECIFIED but
its remedy is **NOT MEASURED at den-hoag's real input shapes**, which is den-hoag-anv's bar, so it needs a
measured spike before it ships; no gen-pipe comment defending position-blindness was found, but that is an
absence claim over comments and such claims have been wrong here. (2) "A v1 stage's ctx-dependence is always
position-recoverable" is UNPROVEN — it holds for the corpus's single deriving stage and for any closure over
coords or settings, and no counterexample was found, but no proof there is none. (3) `isUntargetedDeriving`
treats a broadcast+derive pipe as an untargeted-deriving supersede, a v1-SEMANTICS question left unsettled —
★ and `broadcast-syncthing-hub-shares` is exactly that shape, so **the corpus's one deriving pipe lands on the
undecided branch.**
COVERAGE HONESTY AS REPORTED: the twelve den-pipe tests were confirmed IN AGGREGATE (the five pipe-*.nix files
carry 55 uses of transform/filter/fold/for/as), NOT attributed one test at a time.

### 4 — 2026-07-29T04:37:36 · Jason Bowman

★★ GATE REVIEW r1 — ops representation. VERDICT: VALIDATED-WITH-CONDITIONS (3 blocking, 9 conditions).
First spec in this arc NOT to come back REDESIGN. Anchor re-derived by the orchestrator at record time and by
the reviewer at dispatch: spec md5 a28c509b73772c4b327a4fa9f4a436ed / 454 lines; core md5
75429fa5647f94371647b6fb95866565 / 297 lines. Both match. The reviewer reviewed the frozen artefact.

★ AND THE CORE IS THE FIRST ONE IN THIS ARC THAT DISCRIMINATES. Independently re-run: `nix eval --impure`
gives "core: 6/6" EXIT 0, and the mutation (shapeDisagreement fleetOK == null flipped to != null) gives
EXIT 1 with a NAMED failure. Both prior specs' cores had to be rebuilt from the prose by their reviewers.

════ THE THREE BLOCKING FINDINGS ════

B1 — §1's CENTRAL gen-pipe MECHANISM CLAIM IS FALSE, and this is the one that resizes the deliverable.
The spec says foldC/scanC/overC/joinC all take the position p and that map/filter are the only operators whose
function does not receive it. Read as shipped in gen-pipe lib/evaluate.nix: NO DERIVING OPERATOR PASSES THE
POSITION TO THE USER FUNCTION. p reaches the OPERATOR — for seqAt lookups and to stamp position on synthetic
outputs — and never d.f. foldC folds over (map (c: c.value) seq); overC applies d.f to a bare value list;
mapC sees c.value; filter goes through matchView whose viewOf projects producer/class/deferred/value/
provenance/channel/classInvariant and NO position; joinC has no user function at all.
⇒ UNIFORM POSITION-BLINDNESS ACROSS SIX OPERATORS IS EVIDENCE OF A DESIGN PROPERTY, NOT A TWO-OPERATOR GAP.
This deflates §9(1) directly: that section's reading of "gap rather than design choice" rests on an
absence-over-comments claim the spec itself flags as weak, while the POSITIVE evidence points the other way.
"Nothing else in gen-pipe changes" is not the size of this change. The unmeasured-remedy disclosure remains
honest and correct per den-hoag-anv's bar — it is the MECHANISM FRAMING that made it look one-line that is
refuted.

B2 — THE PAYLOAD FALLBACK IS FAIL-OPEN, AND THE CORPUS IS THE ONE PATH WHERE IT WORKS.
f = pos: (payloads.${site}.${keyOf pos} or identity) silently no-ops on a miss. Three paths evaluate the
deriving node at a position that never emitted at that site: (1) `as` routes — seqAt name p goes to
deliverSeq edge p goes to seqAt edge.from p, so the route's SOURCE terminal is evaluated at the CONSUMING
position, and FOUR OF THE TWELVE TARGET TESTS ARE pipe.as (test-pipe-as-basic, -no-emitter-quirk, -with-to,
-with-transform); (2) untargeted-deriving supersede via derivedBaseNames/channelBindingsAt, same shape;
(3) the already-named expose-with-transform gather residual.
★ THE REVIEWER'S SHARPEST HYPOTHESIS IS REFUTED FOR THE CORPUS, AND THAT STRENGTHENS THE DESIGN: gather.nix
broadcastGatheredWith's sourceOf reads (result.get b.sid "received-collections").${T}.contributions — the
SOURCE position b.sid. So at user:a and user:b the map runs with p = user:a / user:b and position-keyed
payload dispatch is CORRECT. §6's witness works.
⇒ The defect is that the spec GENERALISES FROM THE ONE PATH WHERE THE MECHANISM HOLDS to the paths where it
does not, and fails silently there. §6 itself names this exact failure mode — "a design that applied one
user's f to both users' contributions" — as what the witness must exclude. absence-implies-identity is the
shape in feedback_absence_is_a_decision.

B3 — shapeKeyOf OMITS `targeted`. PROVED EXECUTABLY, WITH A POSITIVE CONTROL IN THE SAME RUN.
Two probes added to a copy of the core: two nodes at one site differing only in ROUTE target, and two
differing only in `to` aspect target. Result MUT2_EXIT=1, single named failure PROBE-targeted-divergence-
caught. ONE name means the ROUTE probe PASSED (routes are keyed) and the `targeted` probe FAILED.
shapeDisagreement is SILENT when two nodes at one site emit different pipe.to targets; per-site dedup then
keeps emitter #1's targeted and silently drops #2's delivery intents. compilePipe emits five fields
(channel derived routes targeted marks); shapeKeyOf covers four. The core's own comment claims shapeKeyOf is
"total on the pipeOp vocabulary". §1's SHAPE/PAYLOAD table lists targeted in NEITHER column.
test-pipe-as-with-to is one of the twelve.

════ THE RUBRIC, BY NAME ════
C1 / C1-a HYPOTHESIS + ARITY — PASS. Apt/Blair/Walker Stratified Programs Def. 3 p.96; preconditions are
already-declared data in lib/declarations.nix; strata total over kindToStratum.
C2 / C2-a SINGLE-VIOLATION-IS-TOTAL — PASS. No hypothesis of the cited result is violated; every failure
found is mechanism or prose, not theorem transfer. Stratification is used AS the theorem, not as a pattern.
C3 LICENSING — FAIL. "ctx-independent by construction" licenses an implementer to delete shapeDisagreement;
"the one gen-pipe surface change ... nothing else changes" licenses shipping B1 as a one-liner. Both are the
known-positive shape where prose is load-bearing.
C4 DIRECTION OF APPROXIMATION — FAIL. `or identity` approximates COARSER/UNSOUND: a missing payload silently
applies no transform. Repairing discipline is a throw naming site and position.
C5 COORDINATES — PASS, verified against primary text. compose.nix line 3 reads verbatim "are definition-time
and force DAG STRUCTURE only, never contribution values (L4)"; L12a is operators.nix "DECLARATION-SITE
IDENTITY (§2.3a, L12a)". ★ gen-pipe clone HEAD 535093083069ec2cfe6d373c08b12305939462ee EQUALS the flake.lock
pin — §7's clone-equals-pin claim is CORRECT, which is the citation-invalidation event this project keeps
getting caught by and which was checked here.
C6 TOTALITY OF THE DISCHARGE — FAIL, AND THIS IS THE DECISIVE ONE. What does the system do on the input that
violates the invariant? Shape disagreement in channel/derived/routes: named throw, discharged. Disagreement
in `targeted`: NOTHING — undefined, silent, executably demonstrated (B3). Payload-table miss: `identity` — a
DEFINED behaviour that is the WRONG ANSWER, silently (B2). Two violation classes with no named abort.
C7 CONSTRUCTION-VS-REPAIR — PARTIAL. Deleting the static field genuinely removes the defect class (a record
field cannot hold a per-node value) and that half is construction. But shapeDisagreement is a REPAIR — an
invariant someone must maintain — and it is ALREADY INCOMPLETE at targeted. §1's "by construction" is the
tell that this was believed to be construction throughout.
C7-b REUSE-SCAN — PASS, and unusually well executed: §7 correctly finds append/to/expose/broadcast/collect/
collectAll/withProvenance are NOT gen-pipe exports, re-classifying den-hoag-4kh.36 as den-hoag wiring rather
than a gen gap and correctly separating it from this task.
C8 PARITY TARGET — PASS on selection (den-surface expressibility, twelve tests green honestly per
den-hoag-i5m, no xfail), AT RISK ON DELIVERY: 4 of the 12 are `as` tests on the path B2/B3 break.
C9 REGISTER — PASS on substance, FAIL on the §1 framing. Entry 3 THEORY survives, MECHANISM survives and
genuinely IMPROVES (it REMOVES the stratum-3-above-stratum-1 hoist rather than adding a stage), ARGUMENT
correctly refuses the "pre-pass already stages, so staging is fine" move and cites the register's own
cycle-in-a-representation distinction against itself. Entry 5 hit directly with the side stated.

════ EVERY FAIL-OPEN FOUND ════
1. `or identity` in the payload lookup (B2) — silent wrong value on route / supersede / expose-transform.
2. shapeKeyOf omits targeted (B3) — silently drops a second emitter's pipe.to intents.
3. §1's "ctx-independent by construction" — licenses deleting the guard that makes the design sound.
4. §2's "nothing at or below collection reads a composed channel" — FALSE AT HEAD: received-collections
   declares stratum = "collection" and reads dag = quirkDag wholesale. A maintainer checking the stated
   invariant finds it already red and concludes it is not enforced. ★ THE TRUE REASON NO CYCLE FORMS is the
   checkable one the reviewer verified: declarations.readsAttrs = [ "enriched-context" "suppressed-policies" ],
   neither reaching quirkDag, so the seed never needs a shape before the emitters have fired.
5. §4's guard predicate omits the marks-non-empty conjunct — the elimination rests on it.
6. The «anon» ceiling guards an UNREACHABLE case while the reachable non-injectivity is unstated.

════ CORRECTIONS THAT DO NOT CHANGE THE CONCLUSIONS ════
· THE ELIMINATION ARGUMENT RE-DERIVED EXACTLY and is the spec's strongest work. Real binary, worktrees no
  longer exist: pipe.as 0 (exit 1), from 17, transform 1 (modules/den/policies/pipes.nix:143), collectAll 4,
  broadcast 4, expose 2. Evasion control — `with pipe` / `inherit (pipe)` / `with den.pipe` — ZERO hits, so
  the prefix predicate cannot be dodged. The reviewer ADDED the counts the spec's positive-control row omits
  and which actually carry "exactly one deriving stage": pipe.filter 0, pipe.fold 0, pipe.for 0.
· collect is 9 in the appendix; real pipe.collect STAGES = 7, the other two are prose comments in bgp.nix:17
  and hostsfile.nix:2. A comment counted as a call site in the row presented as the positive control.
· §4 states the guard fires on derived-or-routes. The real predicate ALSO requires marks to be non-empty.
  Closed empirically by printing all 17 from-sites: every one carries at least one mark, so 16/17 pass. The
  conclusion survives; the derivation as written does not.
· THE SITE-KEY TRACE IS VERIFIED HOP BY HOP: site = policyId-effectIdx from compilePipe, policyId built by
  prelude.imap0 over policyRefs in compile.nix perKind, from ing.kindIncludes.${kind}. Positional index into
  a corpus-ordered list, as stated.
· ★ BUT THE «anon» CEILING DESCRIBES A CASE THAT CANNOT ARISE. isPolicyRef is RECORD-ONLY; isBareFnRef routes
  every bare function to the synthetic ASPECT arm, which never reaches compilePolicy/compilePipe. ZERO
  anonymous include functions can reach a policy site. ⇒ THE REAL RESIDUAL THE SPEC MISSES: siteOf DROPS THE
  KIND. ref.name is injective only if v1 policy names are fleet-globally unique across every includes list
  AND every inline-aspect-hoisted policy record. Corpus check: 35 den.policies.<name> references, EVERY ONE
  COUNT 1, so no live collision — and a collision would fail CLOSED (spurious shapeDisagreement), not
  silently. Two more unstated consequences: compilePipe receives policyId not ref, so ref.name must be
  threaded through compilePolicy and translateEffect (the spec presents siteOf as a drop-in); and compose.nix
  says derived NAMES come from declIndex = decls-list position, so re-keying the seed by policy name makes
  derived channel names MOVE when a policy is renamed.
· "THE QUESTION IS NOT ASKED" — HOLDS, and this claim survives intact. Against 9xo.72/9xo.75 the disease is a
  DECLARATION question decided by firing at a FABRICATED ctx. Here the pipeOp comes from real firing, the
  guard compares OBSERVED strings, nothing is fabricated, and it is not re-asked at compose.
· THE SEED DECOUPLING — conclusion HOLDS. Attr 10's only quirkDag read is the channel lookup, and channelNames
  comes from builtins.attrNames over den.quirks at definition time, so removing that one read really does cut
  attr 10's edge.
· C9's eleven sites RE-DERIVE EXACTLY: 11 hits across 5 files (class-modules.nix x2, resolved-settings.nix,
  resolved-aspects.nix x4, default.nix, ci/tests/b2-two-stratum.nix x3), though that counts a CI test among
  "consumer sites". Broader predicates give 12 across 6. ★ AND THE SPEC DOES NOT ADD A TWELFTH — verified:
  lib/declarations.nix has groups.collection = [ "pipeOp" ], pipeOp is the SOLE collection kind, so the
  actions.collection list is homogeneous and needs no tag filter. A genuine register hit, invisible to a
  word-sweep, where the spec's mechanism really did change because of the register.

════ ★★ THE NEW HAZARD THE SPEC NEVER NAMES — A REQUIRED SPIKE ════
After the change quirkDag is a function of result, while attributes/default.nix threads quirkDag INTO result.
Lazy-safe ONLY because declarations never touches it — an invariant nothing enforces. And compose's guard is
builtins.deepSeq, so forcing ANY node's local-collection-data now forces EVERY node's dispatch. §5 measures
compose's cubic in decl count and asserts V is about 17; it does not account for this new FLEET-WIDE FORCING
EDGE. Per den-hoag-4kh.20 a lib.fix black-hole is NOT tryEval-catchable, so this needs a MEASURED spike, not
prose. Performance is a defect by standing rule.

════ THE THREE OPEN ITEMS, JUDGED ════
(a) the gen-pipe map/filter position change — NOT honestly open; it is WORSE than stated. See B1.
(b) "ctx-dependence is always position-recoverable" — honestly open, and STATED OVER THE WRONG VARIABLE.
    B2 shows that even where the fact IS position-recoverable, the position available at evaluation on the
    route/supersede paths is the CONSUMING one, not the producing one. Recoverability is not the binding
    constraint; WHICH position reaches f is.
(c) isUntargetedDeriving — honestly open AND LOAD-BEARING, understated by placement. Verified: the predicate
    is derived-and-no-routes-and-no-targeted-and-no-expose, and broadcast-syncthing-hub-shares satisfies all
    four, so it lands on the undecided branch exactly as the spec says. But this decides whether
    replicateHome's base is REPLACED at the receiving scope via pipeTerminals/derivedBaseNames/
    channelBindingsAt — it GATES §6'S OWN WITNESS. Listing it third under "open for the owner" understates
    it; it is a PRECONDITION OF THE DELIVERABLE.

════ THE NINE CONDITIONS FOR VALIDATED ════
1. `or identity` becomes a named throw; declare the payload table's domain TOTAL over the positions at which
   the node is EVALUATED, not over emitters (B2).
2. shapeKeyOf covers targeted; keep the two probes as shipped checks (B3).
3. Rewrite §1's gen-pipe paragraph against foldC/scanC/overC AS READ — no operator passes position to f (B1).
   §9(1) then sizes the real change.
4. Delete "by construction"; state the invariant as GUARD-ENFORCED.
5. Replace §2's stratum rule with the checkable one (declarations.readsAttrs), and add the quirkDag/result
   knot plus the deepSeq forcing edge as a REQUIRED SPIKE.
6. Fix §4's guard predicate to include the marks conjunct; record that all 17 corpus sites carry >= 1 mark.
7. Re-key siteOf to include the kind, or state the fleet-global name-uniqueness premise and that it fails
   closed. Correct the «anon» ceiling — it guards an unreachable case.
8. Fix the core's fixture to compilePipe's REAL shape or drop the "exactly the shape" claim; add route and
   multi-stage-chain fixtures. (flattenBase prepends an `over` flatten root to EVERY deriving pipe, so a real
   chain is map/over/base; the fixture gives map/base. shapeKeyOf and payloadTable are exercised at a depth
   the real path never produces, and the over root's own f — a payload entry — is missing from the table.
   Every shipped fixture also sets routes empty, so shapeKeyOf's route branch is DEAD in the shipped run
   while routes are 4 of the 12 tests.)
9. Promote open item (c) to a PRECONDITION of §6's witness.

════ COVERAGE — WHAT THE REVIEWER DID NOT EXECUTE, STATED HONESTLY ════
· The corpus abort itself. axon-01/blade/cortex were NOT built under den-hoag or under the corpus's v1 pin;
  §6's "old aborts / v1 exit 0" rests on den-hoag-1kd's recorded double-reproduction, read but not re-run.
  The 12 radioactive plus compose-commitment x12 in ci WERE measured.
· Whether the twelve actually turn green — nobody can, the design is unimplemented.
· ★ THE B2 ROUTE/CONSUMING-POSITION FINDING IS READ, NOT EXECUTED — derived from reading deliverSeq/seqAt/
  baseSeq and broadcastGatheredWith. THE B3 targeted FINDING IS EXECUTED.
· §5's compose-scaling table (2.96 / 0.94, the 248x gap) not re-run; the conclusion drawn from it does not
  depend on the exponent.
· §7 item (2), the per-primitive call-site inventory, the 19-channel-references row, and §8's gateSuppression
  identity claim — read, not re-derived.

### 5 — 2026-07-29T05:02:15 · Jason Bowman

★★ OPS REPRESENTATION r2 AUTHORED. All nine r1 conditions discharged. **B1 RESOLVED VIA ROUTE (b) — THE
GEN-PIPE CHANGE COUNT IS ZERO.** Artefacts re-derived by the orchestrator and MATCHING: spec md5
bec675fa9de45813723d0792c3c8532f / 756 lines; core md5 02d676f0d90e8f4663ce6581c3bdc504 / 654 lines.
CLEAN RUN "core: 13/13" EXIT 0. ★ Exit codes captured WITHOUT A PIPE — the author's first attempt reported
EXIT=0 for a failing run, the trap this arc keeps re-earning.

════ B1 — ROUTE (b): THE POSITION PROJECTION ════
The gate's read of evaluate.nix is confirmed: mapC applies d.f to c.value; foldC/scanC/overC take p ONLY to
stamp position on synthetics; joinC has no user fn; filter gets viewOf c with no position. Six operators,
uniformly position-blind.
★ ADDED FINDING THE GATE DID NOT HAVE: **GEN-PIPE IS NOT UNIFORMLY PRODUCER-BLIND.** view.nix:22-32 viewOf
PROJECTS `producer`. So filter's predicate ALREADY sees the producing node while map's f sees only .value.
POSITION-BLINDNESS AND PRODUCER-BLINDNESS ARE TWO DIFFERENT FACTS — and this matters because it kills the
"just thread it through, filter already has it" instinct before someone acts on it.
THE MECHANISM: position never needs to reach d.f. Within one outputs.at n EVERY derive evaluation is at n
(deriveSeq ch p recurses with the same p; only baseSeq's traversal.order p visits other positions, and for
CONTRIBUTIONS not derivations). And **pipe.run is ALREADY per-node — collections.nix:247, ONE call site** —
while only compose is once-per-fleet. So the payload is selected ONCE, OUTSIDE gen-pipe, at that call site:
   projectAt emissions dag n = dag // {
     channels = mapAttrs (rewrite __derive.f to the emitting node's payload | named throw) dag.channels;
     edges    = filter (e: siteOfName.${e.from} in firedAt n) dag.edges;
   }
Four invariants, ALL IN THE CORE: I1 channel key set is position-invariant (output-modules.nix:964's
channel-totality law needs it); I2 payload domain total over the firing set, miss = NAMED ABORT; I3 one shape
per site; I4 the projection preserves compose (drops edges, adds no declaration, removes no channel — so
acyclicity and ref-completeness survive the restriction).

════ ★★ B2's PREMISE IS REFUTED — AND THE REFUTATION IS v1's, NOT THE AUTHOR'S ════
Read from den v1 directly:
· assemble-pipes.nix:985-1011 — pipe.as: asInbound is FILTERED OUT of scopeEffects, the source base is
  mkCombinedBase AT THIS SCOPE, and applyEffectStages runs with currentScopeId = scopeId.
  ⇒ **v1's `as` HAS NO CROSS-NODE ROUTE AT ALL. THE DECLARING SCOPE IS THE CONSUMING SCOPE.**
· assemble-pipes.nix:790-830 — broadcast applies applyTransformStages at sourceId, the FIRING scope.
  den-hoag's broadcastGatheredWith:328-334 reads at b.sid. SAME.
⇒ THERE IS NO PATH WHERE THE WRONG POSITION REACHES THE PAYLOAD. The gate is RIGHT about WHICH position
arrives and WRONG that its arrival is a defect.
★ ORCHESTRATOR VERIFICATION OF THE ONE COORDINATE RISK: the author read v1 at a2f4b60 (HEAD of
~/Documents/repos/denful/den), NOT at the corpus's own pin 11866c16, and said so. I diffed
lib/assemble-pipes.nix, lib/compile.nix and BOTH policy-type.nix paths across 11866c16..a2f4b60: **ALL
EMPTY**, while the positive control on the same instrument in the same run shows 17 files / 1004 insertions
changed between those revs overall. THE CITED HUNKS DID NOT MOVE. **THE REFUTATION STANDS AT THE CORPUS PIN.**
⇒ r1's ACTUAL defect was not position-correctness but **TOTALITY**: gen-pipe defines a derived channel at
EVERY position, v1 only where declared. ★ THE PROJECTION SUPPLIES THE MISSING PARTIALITY **STRUCTURALLY** —
the edge is ABSENT — rather than by a fallback VALUE. That is construction, not repair.
ROUTE (a) EVALUATED AND REJECTED IN §1 ON THREE GROUNDS: it argues against an observed uniform design
property; it is NOT one line (mapC/foldC/scanC/overC/joinC.combine plus matchView/viewOf, and `select` has
TWO NON-DERIVE CONSUMERS — deliverSeq:292 and traceAt:427 — where a position argument is not even
well-defined); and ★ IT DOES NOT REMOVE THE FAIL-OPEN, because the channel is still defined everywhere and
therefore still needs a fallback.

════ THE NINE CONDITIONS ════
1 DISCHARGED — `or identity` gone; NAMED THROW naming channel + site + node; domain declared total over the
  positions where the node is EVALUATED (the firing set). Core check unfired-position-fails-closed.
2 DISCHARGED — shapeKeyOf reads `targeted` (to:<aspects>@<from.id>). BOTH gate probes shipped as checks:
  shape-key-covers-targeted, shape-key-covers-routes.
3 DISCHARGED — above.
4 DISCHARGED — "by construction" deleted for the shape claim; §1 states GUARD-ENFORCED and says WHY (nothing
  stops a body picking channel/op/route/to from ctx; the guard is the proof obligation). ★ Remaining "by
  construction" occurrences AUDITED — all genuine.
5 DISCHARGED, SPIKE LEFT OPEN AND NOT GUESSED. §2's false rule replaced with the checkable one:
  structural.nix:326-331 declarations.readsAttrs = [ "enriched-context" "suppressed-policies" ], neither
  reaching quirkDag, so the knot is well-founded. Invariant stated generally: NO attribute in quirkDag's
  transitive readsAttrs closure may read quirkDag. ★ BOUNDING EVIDENCE ADDED AND EXPLICITLY LABELLED
  NOT-AN-ANSWER: fleet-wide `declarations` forcing ALREADY EXISTS SHIPPED — gather.nix:382-391
  broadcasterPairs maps broadcastMarksAt over allIds. That BOUNDS THE NOVELTY; it does not settle the depth.
6 DISCHARGED, AND r1's PREDICATE WAS WRONG IN A SECOND WAY. declarations.nix:182-187 isSiteMarkData is a
  THREE-way conjunction and the guard fires on its NEGATION, so a pipeOp with EMPTY marks ALSO aborts. All 17
  `from` sites verified BY READING EVERY ONE: 17/17 carry exactly one mark (7 collect + 4 collectAll +
  4 broadcast + 2 expose). ★★ **COUNT ARITHMETIC WOULD HAVE GOT THIS WRONG**: the pipe.collect census of 9
  includes TWO PROSE COMMENTS (bgp.nix:17, hostsfile.nix:2), real stages 7, so a naive total of 15 marks
  across 17 sites would have implied TWO MARKLESS SITES that do not exist. Also noted: `targeted` is not in
  the conjunction, and corpus pipe.to = 0.
7 DISCHARGED, AND BOTH r1 AND THE GATE WERE OFF. Site = (KIND, v1 name, effectIdx); a nameless record ABORTS,
  with NO positional fallback. ★ The gate said ref.name must be threaded through compilePolicy/translateEffect
  — **IT MUST NOT**: compile.nix:1851 is `gateSuppression (ref.name or null) ungated`, the line immediately
  below the compilePolicy call. THE NAME IS ALREADY IN SCOPE. Recommends passing a SEPARATE site identity
  rather than re-keying policyId — ★ overloading one string by provenance is a failure mode this project has
  already paid for. Kind is included because one policy record may sit in TWO kinds' includes. The «anon»
  ceiling corrected: a bare fn cannot reach a policy site (isPolicyRef is record-only, isBareFnRef routes to
  the synthetic aspect arm) AND den.policies.<n> records always carry a name (v1 policy-type.nix:10-24 stamps
  it from the option location on BOTH merge arms); the real residual is a nameless __denCanTake record, which
  is exactly why :1851 writes `or null`. ★★ AND THE BRITTLENESS IS WORSE THAN r1 SAID: **TEN MODULES write
  den.schema.user.includes in nix-config**, so the index is a position in a MODULE-MERGED list — ADDING AN
  UNRELATED MODULE MOVES IT, no reorder required.
8 DISCHARGED — fixtures rebuilt to compilePipe's REAL shape. flattenBase:322-329 prepends an `over` flatten
  root to EVERY deriving pipe, so the chain is map/over/base and the payload table has TWO slots (the root's
  own f is ctx-INDEPENDENT; r1's table had no slot for it). Pinned by chain-is-compilePipe-shape. Added a
  route fixture (2-stage chain + `as` route, marks non-empty) plus route-divergence and targeted-divergence
  fixtures, ★ so the route branch is LIVE in the shipped run rather than dead.
9 DISCHARGED — promoted to §6 as a PRECONDITION with its own subsection, AND A SECOND FINDING ATTACHED:
  output-modules.nix:946 claims "the terminal is produced only where the pipe fires, so it carries no host
  inheritance" — **NOT TRUE of gen-pipe's evaluation** (the derived channel is defined at every position and
  baseSeq walks the full neron order). The branch is DEAD TODAY (pipeOps == [ ]) so it is never exercised.
  The projection MAKES it true, but only if **derivedBaseNames becomes position-relative IN THE SAME COMMIT**.
  v1 at a scope with no untargeted effects returns combinedBase unchanged (:1013-1020). ★ The v1-semantics
  half — does v1 supersede at a BROADCASTING producer — is left EXPLICITLY UNSETTLED rather than guessed.

════ THE MUTATIONS — MECHANISMS MUTATED, NOT ASSERTIONS FLIPPED ════
MUT-A payload fallback restored to (x: x), i.e. r1 behaviour → EXIT 1, core FAILED: unfired-position-fails-closed
MUT-B `targeted` term deleted from shapeKeyOf, i.e. r1     → EXIT 1, core FAILED: shape-key-covers-targeted
MUT-C edges = dag.edges, i.e. the projection removed        → EXIT 1, core FAILED: unfired-position-fails-closed
MUT-D `targeted` dropped from keyedFields                   → EXIT 1, core FAILED: shape-key-is-total-over-emitted-fields
★ EACH GIVES EXACTLY ONE NAMED FAILURE, and two of them restore r1's actual behaviour — so the core
discriminates against the previous revision, not merely against nonsense.
EXECUTABLE WEIGHT IS ON THE GUARDS: 8 of 13 checks are guard/projection/domain predicates; only 3 are
fact-shaped. That is the corrected balance this arc has been asking for.

════ COVERAGE — WHAT WAS NOT EXECUTED ════
· No corpus host built under den-hoag or v1; §6's "old aborts / v1 exit 0" carried from den-hoag-1kd.
· §5's compose-scaling tables (2.96 / 0.94, 248x) carried from r1, NOT re-run — the conclusion depends only
  on super-linear vs a linear control, not on the exponent.
· §7 item (2)'s per-primitive inventory and the 19-channel-references row carried from r1. The author DID
  re-derive that pipe.run has ONE call site.
· The twelve den-pipe tests confirmed in AGGREGATE only (55 verb uses across 5 files), not attributed one at
  a time. Nobody can confirm they turn green — the design is unimplemented.
· ★★ **THE LARGEST UNEXECUTED GAP: the projection is executed in the CORE against a MODELLED compose**
  (naming and edges reproduced from compose.nix as read, not called — the core takes no gen dependency). IT
  HAS NOT BEEN RUN AGAINST REAL GEN-PIPE compose/run. That is the fixture's job per §6.
· The §2 spike is stated, not measured — by instruction.

### 6 — 2026-07-29T05:09:13 · Jason Bowman

★★ SPIKE MEASURED — the quirkDag/result knot, conditions H1 and H2 of den-hoag-4kh.53.64 condition 5.
Rig at scratchpad/{knot-probe.nix,knot-run.sh,est.py}, arms under arms/{head,knot,knotE,knot0,headU,headD,
headB2,knotB2,headB,knotB}/. Arms copied from lib/ at b8d1073 and `git diff --stat b8d1073..HEAD -- lib/` is
EMPTY at HEAD 94b3bdd, so the arms are current. Repo untouched. Instrument NIX_SHOW_STATS, all six counters
from one json per eval; estimator = MARGINAL Δ with q = log2(Δᵢ₊₁/Δᵢ); axis = CELLS with the declared shape
asserted every rung (nodes = 1+H+H·U, cells = H·U, U=2) and the runner exiting 1 on mismatch.

════ H2 — REAL, THE FACTOR IS UNBOUNDED, BUT NOT ON THE PATH THE REVIEW NAMED ════
(a) ON quirkDag ITSELF: Θ(1) BECOMES CUBIC. Observable den.quirkDag.channels, fixture `plain` (seed value
[ ], so both arms compose a BYTE-IDENTICAL DAG — verified, dagnames reads ["__den-demands","ssh-peers"] on
head AND knot; the arms differ ONLY in the forcing edge).
   cells      head    knot0     knotE       knot   knot/head
       2      7796     7796     24292      24434       3.1x
       4      7796     7796     25779      26022       3.3x
       8      7796     7796     30391      30836       4.0x
      16      7796     7796     51879      52728       6.8x
      32      7796     7796    189607     191264      24.5x
      64      7796     7796   1209639    1212912     155.6x
     128      7796     7796   9152551    9159056    1174.8x
★ head is **Δ = 0 ON ALL SIX COUNTERS ACROSS A 64x FLEET RANGE** — quirkDag is fleet-INDEPENDENT today.
knot reads p_top 2.959 fnCalls / 2.968 list.elements / 2.951 primops / 2.941 thunks — the SAME 2.98 that
den-hoag-qxz records. Spans 0.25-0.49 and still rising, so "cubic" is the TREND, not a converged number.
★ CODE-SHAPE CONTROL: knot0 (identical code, seed node list [ ]) reads EXACTLY head (±1 primop, +2 thunks)
⇒ the delta is THE TRAVERSAL, not the `++`.

(b) ★★ ON THE PATH H2 ACTUALLY NAMED, THE CONVERSION HAS ALREADY HAPPENED AT HEAD. head/one-local-collection
is ALREADY p_top 2.961 at 128 cells. The paired knot−head delta at that observable:
   cells      2    4    8   16    32    64   128
   Δ fnCalls 50  154  362  778  1610  3274  6602      p_top 1.000, span 0.000
Exactly 2x per doubling — **LINEAR**, ~51 fn calls per node, **0.27 % of total at 128 cells**.
⇒ THE REVIEWER'S MECHANISM CLAIM IS TRUE — forcing any node's local-collection-data does force every node's
dispatch — AND ITS MARGINAL COST IS A LINEAR TERM UNDER A PRE-EXISTING CUBIC. It is not the hazard. (a) is.

(c) ★★ ATTRIBUTION — THE CUBIC IS NOT NEW DISPATCH WORK, IT IS `attrNames structural.eval.allNodes`.
knotE (enumerate node ids, read NO declarations) reads p_top 2.961, indistinguishable from knot, and
knot−knotE is exactly linear (p_top 1.000, ~34 fn/node). Independently on head: all-declarations − all-nodes
is ALSO exactly linear (p_top 1.000, ~35 fn/node) ⇒ **ENUMERATING allNodes ALREADY FORCES EVERY NODE'S
`declarations`.**
⇒ ★ CORRECTION TO SPEC §5: "the growth variable is DECLARATION SITES, NOT NODES" is true of the SEED SIZE and
FALSE of the QUERY COST. **99.7 % of the knot's cost is knowing the node set at all**, which the seed cannot
avoid — cells carry pipeOps (the witness is broadcast-syncthing-hub-shares at two USERS), so a roots-only
enumeration is not available.
⇒ **THE DESIGN DOES NOT CREATE A CUBIC. IT INHERITS den-hoag-qxz's AND MOVES quirkDag INSIDE IT.**
REACHABILITY OF THE 1,175x: only a consumer that reads quirkDag WITHOUT the fleet. Measured — EXACTLY TWO:
ci/tests/class-tagging.nix and ci/tests/pipe-consume.nix (grep positive control: 112 files match mkDen).
idToName and derivedBaseNames also read attrNames quirkDag.channels but sit on fleet-forcing paths.
COUNTER-DEPENDENCE STATED HONESTLY: nrOpUpdateValuesCopied p_top 1.804 and sets.elements 1.243 — NOT cubic,
still rising, INCONCLUSIVE on those two.

════ ★★ H1 — DISSOLVES AS ASKED, AND WHAT REPLACES IT IS WORSE ════
**`readsAttrs` IS A DECLARATION THE EVALUATOR DOES NOT ENFORCE.** Source: the pinned gen-resolve at
/nix/store/1gqihxag0ycpqf8crwi89x7ycaxcfr0c-source. readsAttrs occurs ONLY in lib/schedule.nix (Knuth
circularity + stratum analysis), lib/contract.nix (the `why` trace) and lib/equation.nix (the record
constructor). **ZERO occurrences in lib/resolve.nix or lib/materialize.nix — it is NEVER CONSULTED AT
`self.get`.**
EXECUTABLE CONTROL PAIR, same instrument same family:
   headU — `declarations` compute reads self.get id "enrichments", readsAttrs UNCHANGED → **rc 0, SILENT**
   headD — same class of edge but DECLARED (readsAttrs += "local-collection-data") → **rc 1**:
           "gen-resolve: attribute grammar is circular but not convergent (Knuth 1968 circularity test).
            SCC(s) contain non-'circular' attrs: [["declarations","local-collection-data","resolved-aspects"]]"
⇒ **THE GATE IS LIVE AND LOUD ON A DECLARED EDGE AND BLIND TO AN UNDECLARED ONE.**

★★ AND THE REVIEWER'S ENUMERATION IS FACTUALLY RIGHT YET NOT THE COMPLETE DEPENDENCY SURFACE.
`declarations` (lib/attributes/structural.nix:325-435) depends on:
 · attributes enriched-context and suppressed-policies — both declared; plus enriched-context AT ANOTHER NODE
   via linkedFrom (readsAttrs is NAME-keyed, not node-keyed, so still in-set by name). Neither reaches
   quirkDag today.
 · self.node id.
 · ★★ **INSTANCE ARGS, WHICH readsAttrs CANNOT NAME AND THE SCHEDULE NEVER ANALYSES**: `policiesIndex`
   (called UNCONDITIONALLY at line 347), `linkTarget` (conditional), `isCellNode` — ALL THREE BOUND IN
   lib/default.nix's `let`, THE SAME SCOPE AS quirkDag.
MEASURED ON THAT CHANNEL (one-line edit: policiesIndex.policy seqs attrNames quirkDag.channels):
   headB2 (HEAD quirkDag) → **rc 0, clean** ← POSITIVE CONTROL: the edit is harmless without the knot
   knotB2 (KNOT quirkDag) → **rc 1, "error: infinite recursion encountered"** at the seed line
   knotB2 wrapped in builtins.tryEval (builtins.deepSeq v true) → **rc 1, tryEval DOES NOT CATCH IT**
   NO SCHEDULE GATE FIRED — compare headD, where the same cycle spelled as a DECLARED ATTRIBUTE edge aborted
   with a named SCC.
⇒ **H1 VERDICT: readsAttrs IS NOT THE MECHANISM THAT BOUNDS `declarations`.** It is one input to a static
analysis that sees only what the author declares, and the cycle-closing channel under the knot is the
INSTANCE ARGS, which that analysis cannot see at all. Absence discharged with a positive control: unpatched
knot evaluates (rc 0) ⇒ no reaching path today; knotB2 does not ⇒ the instrument CAN detect one.

════ ★ CONSEQUENCE FOR THE IN-FLIGHT SPEC, RELAYED TO ITS REVIEWER ════
ops r2's condition-5 invariant reads "NO attribute in quirkDag's transitive readsAttrs closure may read
quirkDag." **THAT IS NECESSARY AND NOT SUFFICIENT.** The demonstrated cycle-closing channel is outside
readsAttrs entirely, is not analysed, fails as a raw infinite recursion rather than a named SCC, and is not
tryEval-catchable. The invariant must quantify over the instance args bound in lib/default.nix's `let`, or
state that it is enforced by nothing.

════ COVERAGE — WHAT THIS COULD NOT SEE ════
· Counter-based ⇒ BLIND TO PRIMOP-INTERNAL COST; an O(1)-allocation superlinear workload reads linear on
  every counter in the closed set.
· Only what the arms FORCE. ★ `nix-unit --flake ./ci#tests` WAS NOT RUN — no claim about the 1919/1937
  baseline and NO CLAIM THAT THE KNOT LEAVES THE SUITE GREEN.
· NOT CONVERGED: spans 0.25-0.49 at 128 cells, p_top still rising.
· nrOpUpdateValuesCopied (1.804) and sets.elements (1.243) INCONCLUSIVE.
· ONE FIXTURE: dense env/host/user crossing, one quirk channel, one aspect, one enrich policy. NOT the corpus.
· ★ THE linkTarget INSTANCE-ARG BRANCH IS UNCOVERED. A link fixture fires (positive control: 7 link
  declarations, 7 import edges) yet the linkTarget-patched knot arm stayed clean — `combine` appears
  unreached when no later-stratum rules exist. Only the UNCONDITIONAL policiesIndex channel is demonstrated.
· ★ THE FORCING EDGE WAS MEASURED WITH AN EMPTY SEED ONLY. The `ops` fixture (13 pipeOps; seed-predicate
  positive control reads 0 on `plain` and 13 on `ops`, same predicate) could NOT reach compose — the raw
  {__action;channel;marks} lacks `op`, so gen-pipe lib/compose.nix:38 throws "attribute 'op' missing".
  COMPOSE'S OWN COST UNDER A NON-EMPTY SEED — the §5 cubic-in-derived-declarations measurement — WAS NOT
  REPRODUCED.
· ★ FIXTURE-REACH NOTE WORTH KEEPING: an include at the env root reaches THE ENV NODE ONLY (measured: 1
  aspect at env, 0 at hosts and cells). Includes must be placed at every host AND every user for the
  collection stratum to be non-empty fleet-wide — an env-root spelling would have measured an empty path at
  every cell and looked like a clean result.

### 7 — 2026-07-29T05:10:41 · Jason Bowman

★★★ THE CORPUS BLOCKER CHAIN, MEASURED END TO END. **VERDICT ON den-hoag-4kh.53.64's PREMISE: UNSOUND AS
STATED.** Fixing the ops representation clears RUNG 1 ONLY and hands off to a NAMED SUCCESSOR. The corpus
still produces NO TOPLEVEL. ★ **THIS IS THE SAME "MOVED THE FAILURE EARLIER" SHAPE AS den-hoag-1kd, ONE LEVEL
UP** — if 53.64 lands as-is, the arc reads "critical path fixed" while corpus output stays at zero.

════ THE NO-GUARD TREE IS TRUSTWORTHY — ESTABLISHED THREE INDEPENDENT WAYS ════
1. /run/current-system/sw/bin/diff -r dh-head dh-head-noguard = EXACTLY ONE HUNK, lib/concern-policies.nix:209,
   `errors.opsInBody name` replaced by `a // { __policy = name; }`.
2. NOT STALE: diff -rq dh-head/lib <live repo>/lib exit 0 — BYTE-IDENTICAL to current HEAD.
3. The replacement text is byte-identical to (a) the `else` branch two lines below in the same
   conformingProduce, AND (b) c42df53's UNCONDITIONAL stamp at lib/concern-policies.nix:167.
★★ ⇒ **den-hoag-1kd's OWN STATED WOULD-OVERTURN IS CLOSED.** 1kd worried that a non-site-mark pipeOp now
carrying `__policy` would make the guard-off frontier an artefact if anything downstream branches on it.
c42df53 stamped `__policy` on EVERY kind unconditionally, and conformingProduce did not exist then. Guard-off
REPRODUCES PRE-GUARD BEHAVIOUR EXACTLY; it is not a novel state.

════ THE CHAIN ════
RUNG 1 — ALL THREE HOSTS. den-hoag throw, lib/errors.nix:190 opsInBody, raised at concern-policies.nix:209:
  "den-hoag: compose commitment: policy `__kindInclude__user__policy__8` produced a `pipeOp` declaration
   carrying a derived-channel DAG or a delivery route from its BODY..."
★ THEN THE CHAIN FORKS PER HOST.

──── axon-01 / blade ────
RUNG 2 — a NIX-LEVEL ABORT, not a den-hoag throw:
  "error: attribute 'id_hash' missing" at lib/attributes/collections.nix:205:32 — `identity = a.content.id_hash;`
★ NEW BEYOND 1kd/9xo.61 — THE OFFENDER IS PINNED BY NAME, NOT INFERRED. The site was instrumented to dump the
record: `a` keys = ["content","key","sharedFoldKey"]; `a.content` keys = ["home-manager",
"homeManagerModules","name","nixos"] — it carries `name` and NO `id_hash`. Channel homeManagerModules,
coordKinds ["host","user"]. Offenders: axon-01 agenix-identity/{dvicory,pol,sini,theutz,vic}@axon-01;
blade agenix-identity/{shuo,sini,will}@blade.
★★ **`a.key` = "__kindInclude__user__aspect__2:include:0" — IDENTICAL FOR EVERY USER ON A HOST.** So the
obvious repair `aspectIdHash a.key` **COLLIDES ALL PRODUCERS**. Only content.name distinguishes them. This is
the nested-aspect "crosses the bridge as a BARE content set (no id_hash/name)" shape that
ci/tests/compat-nested-aspects.nix:9,20 documents. WHOEVER WRITES THE FIX NEEDS THIS — IT IS A LIVE TRAP.
content.id_hash is read at EXACTLY ONE site in lib/ (positive control: content.name = 4 files), so no second
consumer is being bypassed.

RUNG 3 — reached by substituting a synthetic identity. DIFFERENT PER HOST.
· axon-01: "error: The option `services' was accessed but has no value defined." — nixpkgs lib/modules.nix:1267.
  Localized to the HOME-MANAGER USER SUBMODULE: config.home-manager.users.sini.services reproduces it, while
  config.home-manager.users attrNames SUCCEEDS returning ["dvicory","pol","sini","theutz","vic"].
  builtins.attrNames on the user config also throws.
· blade: "error: attribute 'image' missing" at stylix mk-target.nix:224:28 (`inherit (cfg.${argument})
  override;`), via assertions → core.impermanence.nixos → stylix modules/gnome/hm.nix. stylix.image is
  undelivered into the HM user config.

──── cortex — FORKS EARLIER, AT RUNG 2 ────
RUNG 2: "error: attribute 'aspect' missing" at nix-config/modules/den/aspects/virtualization/
microvm-guests.nix:43:77 — CORPUS CODE calling `den.lib.aspects.resolve "microvm" vm.aspect`. den-hoag DROPS
`aspect` off the microvm-guest entity. Via assertions → microvm.vms → virtualization.microvm-host.nixos.
★ CORTEX NEVER REACHES THE id_hash SITE. Probe trace counts, same predicate, same instrument, same run
family: axon 20 / blade 12 / **cortex 0**.
RUNG 3: with `vm.aspect` stubbed to `vm.aspect or { }` in a scratchpad nix-config copy (whole-tree
`/run/current-system/sw/bin/diff -rq --exclude=.git` = ONE FILE, ONE LINE), the next failure is in
**den-hoag's own** lib/compat/resolve-verbs.nix:44:20 — `nodeOf = handle: handle.__denNode;`,
"attribute '__denNode' missing". A Nix-level abort.

════ DOES THE CHAIN TERMINATE IN A TOPLEVEL? **NO.** ════
Deepest reached: rung 3 on all three hosts, ALL EXIT 1, exit codes read from $? into .exit files and NEVER
through a pipe. ★ **EVERY den-hoag .out IS 0 BYTES ON EVERY HOST AT EVERY DEPTH — no drvPath was ever
produced, so there was nothing to force.**
★ ATTRIBUTION CONTROL: all three hosts build EXIT 0 on the corpus's OWN PINNED den v1 (denful/den rev
99cc0c5a1cc846cb1be681344b10d2731d430e13), with real .drv files VERIFIED TO EXIST ON DISK —
blade /nix/store/a5g05y5rawspvbg1pkabw6p0m8f4vgr6-nixos-system-blade-26.11.20260723.e2587ca.drv and
cortex /nix/store/hvj9k6kdc2yj7bdpfvbx4waj3cddj6ni-nixos-system-cortex-26.11.20260723.e2587ca.drv.
⇒ **EVERY RUNG ≥2 IS A den-hoag DIVERGENCE, NOT A CORPUS BUG.**

════ ★ FOUR HYPOTHESES REFUTED BY THE SCOUT, REPORTED AS RESULTS ════
1. "The no-guard tree is stale or mis-edited" — REFUTED (lib byte-identical to HEAD; one hunk).
2. "__policy on a non-site-mark pipeOp makes guard-off an artefact" — 1kd's OWN stated would-overturn —
   REFUTED by c42df53:167's unconditional stamp.
3. ★ "Rung 3 is an artefact of the synthetic A12 ordering" — REFUTED BY AN ORDERING CONTROL. A second scheme
   (ZZALT| vs PROBE| hash prefix) was VERIFIED TO GENUINELY PERMUTE producer order
   (theutz,vic,sini,dvicory,pol → vic,theutz,dvicory,sini,pol) and axon-01's terminal error is BYTE-IDENTICAL
   under both.
4. "A second lib/ reader of content.id_hash was silently bypassed" — REFUTED, one reader only.

════ COVERAGE — HONEST, AND THE LIMITS MATTER ════
· THREE hosts measured (axon-01, blade, cortex), nix-config ONLY. The 19 external configs in
  ~/Documents/repos/den-configs were NOT measured. 9xo.61's other four hosts NOT measured.
· ★ RUNG 1 WAS GENUINELY DISABLED. **RUNG 2 WAS NOT FIXED ON ANY HOST — IT WAS BYPASSED** (synthetic identity
  on axon/blade, a corpus stub on cortex). So rung 3 is measured UNDER SUBSTITUTION. Mitigated by the
  ordering control and the single-reader grep, but A REAL FIX COULD DIFFER — notably, a correct fix stamps
  id_hash ONTO a.content, whereas the probe left content unchanged.
· ★★ **RUNG 3 COULD NOT BE DISABLED ANYWHERE.** axon's `services` and blade's `stylix.image` live inside
  HM/stylix module eval; cortex's __denNode is a den-hoag compat defect needing a real fix, not a stub.
  ⇒ **CHAIN DEPTH ≥3 PER HOST IS A FLOOR, NOT A CEILING.**
· axon's rung-3 attribution to a den-hoag delivery gap rests on READING plus the den v1 control, NOT on
  isolating the missing module. What declares or reads that `services` was not identified.
· Everything else rests on execution.

### 8 — 2026-07-29T05:23:27 · Jason Bowman

★★ GATE REVIEW r2 — ops representation. **VERDICT: REDESIGN-NARROW.** Hashes re-derived and MATCHING:
bec675fa9de45813723d0792c3c8532f / 756; core 02d676f0d90e8f4663ce6581c3bdc504 / 654. Core "core: 13/13"
EXIT 0 read without a pipe; suite re-run 1919/1937 EXIT 1, matching baseline.

★ **THE REDESIGN IS NARROW AND THE THESIS IS PRESERVED.** §0 and §1's REPRESENTATION half is SOUND and the
reviewer found nothing against it: delete the static `ops` field; pipeOp is a per-node collection-stratum
declaration; the fleet DAG is a query deduped by site; the SHAPE/PAYLOAD split; shapeDisagreement replaces
opsInBody. 9xo.72's undecidable question genuinely is NOT ASKED. **DO NOT RE-LITIGATE THAT.** What fails is
§1's PROJECTION, §2's acyclicity rule, and §5's cost — one layer, four findings.

════ B1 — `pipe.run` HAS TWO CALL SITES AND THE SECOND IS ONCE-PER-FLEET. EXECUTED. ════
The design's whole premise ("only compose is once-per-fleet"; "★ pipe.run has exactly ONE call site
(collections.nix:247), which is why §1's projection is a one-site change"; appendix row ✓r2) is **FALSE.**
  lib/attributes/collections.nix:247 — per node ✓
  **lib/default.nix:1860 — `receivedOutputs = pipe.run { dag = quirkDag; … }`, ENTITY LEVEL, ONCE PER FLEET**,
  with `.at pos` selecting any position.
Present at the spec's OWN stated rev (`git show 6f30460:lib/default.nix` → line 1860), so not a HEAD artefact.
LIVE: exported at default.nix:2609, read by ci/tests/edge-completeness.nix:112, end-to-end.nix:58,
class-tagging.nix:158/164/170, and it is the input to concernQuirks.consumeAt — the class-relative read at
output assembly.
★★ THE FAIL-OPEN: seedDecls takes `(head (atSiteIn emissions s)).pipeOp` — the FIRST emitter's whole pipeOp
INCLUDING its __derive.f. An UNPROJECTED receivedOutputs therefore **applies user a's transform at user b's
position, SILENTLY, with no abort, because the payload is present.** That is precisely the collapse §6's
"collapse control" exists to catch, at a site NO FIXTURE REACHES. The reviewer's MUT-F executes exactly this
behaviour and the core DOES catch it at the projected site — so the core proves the defect is real AND proves
the projection fixes it at ONE OF THE TWO SITES.
★★ den-hoag ALREADY CARRIES AN IN-TREE COMMENT AGAINST THIS, default.nix:1855-1859: "DRIFT NOTE: this
traversal adapter MUST stay identical to attribute 11's ... Divergence would silently make consumeAt and the
attribute disagree." **PROJECTING ONE AND NOT THE OTHER IS THAT DIVERGENCE.**
Not a patch: `consumeAt { outputs, at, … }` takes outputs and at as SEPARATE args, so making receivedOutputs
position-relative changes that contract and turns one fleet run into N runs.

════ B2 — §2's ACYCLICITY RULE IS STATED OVER AN INSTRUMENT THAT CANNOT OBSERVE THE HAZARD. EXECUTED. ════
Condition 5's discharge says the invariant "is a property of declared data, so it is mechanically checkable".
★ **quirkDag is an INSTANCE ARG** (lib/attributes/default.nix:136, threaded :179), **not an attribute.**
readsAttrs lists ATTRIBUTE NAMES only, so "reads quirkDag" is NOT EXPRESSIBLE IN IT.
THE PROOF IS THE SPEC'S OWN CITATION: `received-collections` READS quirkDag (collections.nix:248) and
declares readsAttrs = [ "neron-order" "local-collection-data" ] (:240-243). **The one attribute that violates
the predicate is invisible to the check.** r1's rule was FALSE; r2's rule CANNOT FIRE.
The closure the reviewer walked BY READING the 6 quirkDag sites (not via readsAttrs): declarations →
{enriched-context, suppressed-policies}; enriched-context → {inherited-context, enrichments}
(structural.nix:305-308); suppressed-policies → [ ] (:139). None reaches quirkDag.
⇒ **THE CONCLUSION HOLDS; THE STATED INSTRUMENT DOES NOT ESTABLISH IT.** Converges with den-hoag-vyn.

════ B3 — A BARE `pipe.as` BREAKS THE PROJECTION WITH AN UNNAMED ERROR. EXECUTED. ════
lib/compat/pipe.nix confines the site token to deriving pipes ("an as/to pipe keeps its bare base ref");
derives == [ ] ⇒ flattenBase = channelRef pipeName. So a bare `as` route's `from` is a BASE channel with NO
site token, composeOf's siteOfName is built from derivedOf p which is EMPTY for such a pipe, and projectAt's
`edges = filter (e: elem dag.siteOfName.${e.from} fired) dag.edges` is a raw selection with no `or`.
Executed with a bare-as fixture PLUS a positive control on the same predicate in the same run (the
with-derive `as` DOES project):
  error: attribute 'srcCh' missing, at core-bareas.nix:316:31 — EXIT 1
★ AND IT TOOK DOWN THE WHOLE RUN rather than reporting a named failed check.
LIVE IN DEN-HOAG'S OWN FIXTURES: parity/fixtures/pipe-stages.nix:130 and
ci/tests/den-behavioral/pipe-policy.nix:893. **pipe.as is 4 of the 12 target tests.**
TWO HALVES: (i) I2's "named abort" totality holds for the PAYLOAD path and NOT for the EDGE path; (ii) making
the miss total with `or` would put the bare-as route at EVERY position — the exact totality defect the
projection exists to remove, since v1 fires `as` only at the declaring scope.
★★ INSTRUMENT EARNED HERE, FOR THE REGISTER: **builtins.tryEval does NOT catch `attribute … missing` in this
Nix.** Same-run positive control: tryEval (throw "x") → false, exit 0; tryEval ({}.missing) → error, exit 1.
⇒ **THE CORE'S `(tryEval c.ok).success` HARNESS CANNOT CONTAIN THIS ERROR CLASS.** Sits beside the lib.fix
black-hole entry.

════ B4 — THE PROJECTION IS QUADRATIC IN NODES AGAINST A STATED LINEAR COST. EXECUTED, 3-ARM A/B. ════
§5 states "O(nodes x (|channels| + |edges|)) — linear in both". projectAt does, per (channel, node), a FULL
LINEAR SCAN of the fleet-wide emission list (`head (atSiteIn emissions s)`), plus `firedAt emissions n` (a
fleet scan per node), plus `tbl = payloadTable emissions` REBUILT PER CALL. All three quadratic in N.
Measured with definitions copied VERBATIM from the core, S=17 sites, net of a 49 ms baseline, all EXIT 0:
   nodes    spec form   tbl hoisted   fully indexed
     100       639 ms          294              40
     200      1499            513              36
     400      4286           1995             172
     800     30296          11546            1332
★ At 800 nodes the spec's form is **22.7x** the indexed form, and hoisting the table alone recovers only
~2.6x — **so the dominant term is the atSiteIn scan, not the table rebuild.**
nix-config's 31 scope nodes do not bite today, but §5 explicitly reasons at "2000 hosts" and **REJECTS the
per-(site,node) alternative ON COST, comparing a measured cubic against a cost it states as linear and is
not.** Nothing in the core covers this: seed-size-is-sites-not-nodes pins the SEED size, never the projection.
Performance is a defect by standing rule.

════ CAN A MODELLED compose SUPPORT I4? **NO.** ════
§1 claims "four invariants, ALL IN THE CORE". The core names **I1 only** (lines 262, 312, 607); I2's behaviour
is checked by unfired-position-fails-closed and I3's by the guard checks; **I4 HAS NO CHECK AND IS NOT
MENTIONED.** composeOf models nameOf + edge construction and implements NONE of compose's guards — the real
compose.nix tail is `guards = builtins.deepSeq [ refCheck adapterDupCheck cycleCheck staticClassCheck
(dupCheck…) ] true`. I4 claims exactly those guarantees survive the restriction, so the modelled compose has
**no instrument that could observe a violation.** I4 IS ASSERTED.
The argument is sound as far as it goes for edges (a sub-edge-set of an acyclic graph is acyclic;
ref-completeness is over the untouched channel set) but is stated over the wrong object TWICE: (i) real
compose returns { __genPipeDag; channels; edges; declaredIds; topo; } while the core's projectAt returns
{ channels; edges; siteOfName; } and **DROPS __genPipeDag / declaredIds / topo** — the spec's pseudocode
`dag // { … }` PRESERVES them, so core and spec disagree and the core cannot detect the loss; (ii) B3 is an
input that violates it.

════ ★★ THE REVIEWER'S OWN MUTATIONS — FOUR OF SIX SURVIVE AT 13/13 ════
Instrument positive control first: flipping shape-key-covers-targeted → named failure, EXIT 1. Each mutant
diff-verified non-no-op.
  MUT-K drop `kind` from the site key            → **13/13.** Condition 7's kind term UNCOVERED.
  MUT-N delete siteOf's nameless-record abort     → **13/13.** Condition 7's fail-closed UNCOVERED.
  MUT-C delete the `channel` term from shapeKeyOf → **13/13.** ★ guard-fires-positive-control does NOT
        isolate it: ctxShaped's two nodes differ in channel name AND in derived id (chRef chName ⇒
        id == chName), so the DERIVED-ID term catches it. **The vacuity control is not a control on the term
        it is presented as controlling.**
  MUT-M delete the `marks` term                   → **13/13.** No fixture differs on marks — and
        isSiteMarkData RETIRES under this design, so a site whose nodes emit different marks (collect at one,
        broadcast at another) is EXACTLY the case losing its old guard, untested by the new one.
  MUT-F payload always first-emitter's → named failure, EXIT 1. MUT-R drop routes → named failure, EXIT 1.
⇒ ★ **THE AUTHOR'S FOUR MUTATIONS ALL LAND ON TERMS r1 ALREADY NAMED. THE REVIEWER'S LAND ON r2's OWN
ADDITIONS (kind, nameless abort) AND ON THE TWO shapeKey TERMS NO FIXTURE VARIES.**

════ FIVE REVIEWER HYPOTHESES REFUTED — REPORTED AS RESULTS ════
R1. Expected the B2 refutation's v1 reading to be WRONG. **IT IS CORRECT**, re-verified at the CORPUS PIN:
    scopeEffects = scopedPipeEffects.${scopeId} (:931); asInbound filters that scope-local list (:970-978);
    asResults runs applyEffectStages with currentScopeId = scopeId (:980-998); the second arm
    asTargetedInbound (:1055-1101) is the same; perBroadcaster sourceId transforms at the source (:817,:834).
    **No cross-node route in either arm. B2's premise is genuinely refuted, and by v1.**
R2. ★★ **BUT THE ORCHESTRATOR'S VERIFICATION OF THAT COORDINATE WAS VACUOUS.** I diffed
    `lib/assemble-pipes.nix` and `lib/compile.nix` across 11866c16..a2f4b60, got EMPTY, and reported the
    coordinate verified. **`lib/assemble-pipes.nix` EXISTS IN NEITHER REV** (`git cat-file -e` exit 128 at
    both — re-confirmed by the orchestrator). The real path is `nix/lib/aspects/fx/assemble-pipes.nix`, and
    on it: **92 lines changed, 53 insertions / 39 deletions.** My whole-repo positive control was SOUND BUT
    ON A DIFFERENT PREDICATE (does the repo change) than the conclusion needed (does THIS PATH change) —
    **the register's "a sound predicate can prove a DIFFERENT proposition", exactly.** The conclusion survives
    only because the reviewer re-derived it on the correct path: the `as` and `broadcast` hunks ARE
    byte-identical, line-shifted by 14 (the 53/39 is isConfigDependent/markConfigThunks taking a scopeCtx arg
    plus enrichedScopeContexts).
R3. Expected "no gen-pipe operator passes position to f" to be the weak point. **CORRECT**, and so is what
    follows: deriveSeq ch p recurses via seqAt inName p with the SAME p (evaluate.nix:270-286); the only other
    position enters at baseSeq's traversal.order p and only for a NON-derived channel's contributions
    (:391-396). The no-gen-pipe-change claim is right about GEN-PIPE; it is wrong about den-hoag's change
    count (B1).
R4. Expected channelBindingsAt to be a second silent-wrong-value site. **IT IS NOT SILENT — it is the
    REACHABLE path to I2's abort**, which VINDICATES §6's precondition. `local` at output-modules.nix:928-931
    forces local0.${t} for every base in derivedBaseNames at EVERY node. The spec cites :925-955/:946; **the
    forcing line is :930, uncited.**
R5. output-modules.nix:946 IS false of gen-pipe's evaluation and the branch IS dead (pipeTerminals filters
    policiesRules.pipeOps which is [ ]). Confirmed.

════ THE RUBRIC ════
C1 FAIL — unstated precondition: exactly one pipe.run (B1).
C1-a FAIL — projectAt is PARTIAL over the edge set; dag.siteOfName.${e.from} has no domain for a
  non-deriving as/to route (B3).
C2 **PASS** — r1's B1 was RE-SOURCED, not weakened: r2 read evaluate.nix at the pin, found position-blindness
  uniform across six operators, and chose a mechanism that does not need it. ★ The added
  producer-vs-position distinction (view.nix:22-32 viewOf projects `producer`) is a genuine SECOND FACT that
  kills the "just thread it through" instinct.
C2-a PARTIAL — I4 names a true theorem about an object that is not the object under projection.
C3 **PASS** — condition 4 well discharged: "by construction" deleted for the shape claim, §1 states
  GUARD-ENFORCED **and why** ("precisely the sentence a later reader cites when deleting a guard"). Route (a)
  rejection ground 2 explicitly refuses to call a gen change a one-liner. No sentence licenses deleting a
  guard.
C4 SPLIT — PASS on the payload path (named throw naming channel/site/node; unfired-position-fails-closed pins
  it; MUT-F confirms it discriminates against r1's ACTUAL behaviour). FAIL on the edge path (B3: unnamed,
  harness-uncatchable). The repairing discipline for the payload path is §6's position-relative
  derivedBaseNames gate — PROSE ONLY, with the v1-semantics half explicitly unsettled.
C5 FAIL ON ONE, PASS ON THE REST. FAIL: the pipe.run one-call-site claim. VERIFIED AT PINNED REVS:
  compile.nix:1851 gateSuppression (ref.name or null) adjacent to the compilePolicy call ✓ (**r2's correction
  of the r1 gate is RIGHT — no threading needed**); isPolicyRef record-only / isBareFnRef → aspect arm ✓;
  isSiteMarkData 3-way conjunction ✓; declarations.readsAttrs ✓; compilePipe emits five fields ✓; flattenBase
  prepends `over` ✓; gen-pipe clone HEAD == pin ✓; six operators position-blind + viewOf projects producer ✓;
  v1 as/broadcast at the CORPUS pin ✓ (re-derived, R2); suite baseline ✓.
C6 **FAIL. THREE FAIL-OPENS:** (1) B1 silent wrong value at receivedOutputs/consumeAt, no abort; (2) B2 a
  rule that CANNOT FIRE; (3) B3 unnamed abort, and silent-everywhere if made total.
C7 PARTIAL, AND THE HEADLINE CLAIM IS HALF TRUE. Deleting the static field IS construction. But "it supplies
  it structurally (the edge is absent) rather than by a fallback value" is **TRUE OF EDGES ONLY** — I1
  deliberately keeps the channel KEY SET position-invariant, so at a non-firing position the derived channel
  is STILL DEFINED with a throwing payload: a fallback value that happens to abort. §6 concedes it in its own
  words then requires a GATE to keep the abort unreachable. ★ **A GATE SOMEONE MUST KEEP CORRECT IS A
  REPAIR**, and it is prose-only.
C7-a **PASS, unusually well done** — §7 scans all 17 exports per primitive, names the five unused, sizes the
  two genuine duplications (idToName, pipeChainOf) and correctly classifies them optional, and argues the
  4kh.36-vs-53.64 separation FROM THE EXPORT LIST rather than asserting it. Only correction is the pipe.run
  row.
C7-b FAIL — §5's projection cost stated linear, measures quadratic (B4). Sizing understated: §1 says "one new
  function and one changed argument at collections.nix:247, plus the site→name map", omitting five consumers
  reading off the policiesRules.pipeOps the design DELETES — pipeTerminals (default.nix:1480), pipeChannelOps
  (:1484), pipeRouteOps (:1493), quirkDag's own seed (:1495-1498), derivedBaseNames (:1509) — plus B1's
  second run and §6's own position-relative derivedBaseNames.
C8 PASS on selection, AT RISK on delivery — 4 of the 12 are `as` tests and the bare-`as` shape is B3.
C9 **PASS, AND §8 IS THE STRONGEST SECTION IN THE DOCUMENT.** THEORY survives; MECHANISM survives and
  IMPROVES (the design REMOVES a stratum-3-above-stratum-1 hoist rather than adding a stage); ARGUMENT
  explicitly refuses "the pre-pass already stages, so staging is fine" and turns the register's own
  cycle-in-a-representation distinction against itself — "if the pre-pass retires tomorrow, nothing here
  changes" is the right test. C9-a PASS: retiring constructs named, trackers cited, successor vocabulary
  used, ★ **and the codomain traced hop by hop to den.schema.<kind>.includes — a trace that CAUGHT A DEFECT
  THE DESIGN WOULD HAVE CREATED. The register is working.**

════ COUNT CORRECTIONS (CONCLUSIONS UNAFFECTED) ════
· "TEN separate modules write den.schema.user.includes" — measured **NINE files, 11 occurrences, of which ONE
  (modules/den/aspects/core/security/opkssh.nix:35) is a PROSE COMMENT** ⇒ 10 write sites in 9 modules. The
  enumeration lists nine paths "plus the entry under audit", but policies/pipes.nix IS the entry under audit
  and is already in the list — a double count. Positive control: den.schema. hits 30 files. ★ **THE SAME
  ERROR CLASS THE SPEC ITSELF CATCHES FOR pipe.collect.** Conclusion unaffected and correct.
· "8 of 13 checks are guard/projection/domain … only 3 are fact-shaped" — 8+3 = 11 ≠ 13. Reviewer's
  classification: 9 guard/projection/domain (5-13), 4 fact/fidelity (1-4). Conclusion survives; arithmetic
  does not.

════ NOT BLOCKING BUT UNSTATED (both READ, not executed) ════
· **`targeted` is emitted, read by shapeKeyOf, and NOT PROJECTED** — projectAt's domain is {channels, edges}.
  v1's `to` also resolves at the declaring scope. Unwired today (default.nix:1425 "NOT threaded"), so
  prospective — but the same totality defect returns on that path when 4kh.36 lands, which §7 leaves open.
· **§6's projection control encodes an UNSTATED v1 DIVERGENCE.** v1 pipeData (pin :1031-1039): a scope that
  does NOT bind the pipe locally takes assembled.${policyBoundAncestor}.${pipeName} — the ancestor's
  POST-TRANSFORM value. bindsPipeLocally (:904-909) is true only with own imports/exposed/broadcast/effects.
  So a bare descendant of the firing scope reads the TRANSFORMED value in v1, while §6 asserts the
  non-firing third node "must read the base channel UNCHANGED". §9's open v1-semantics item names only the
  broadcasting-producer supersede, not this.

════ EIGHT CONDITIONS FOR r3 ════
1. Project BOTH pipe.run sites, or state why receivedOutputs may stay fleet-global — and answer consumeAt's
   { outputs; at; } contract and the N-runs cost. Cite default.nix:1855-1859's DRIFT NOTE explicitly.
2. Make the edge filter TOTAL. Either extend compilePipe's site stamp beyond deriving pipes or key the filter
   on the route record. Ship the bare-`as` fixture as a check WITH the derived-`as` positive control beside it.
3. Restate §2's invariant over something that CAN observe a quirkDag read. readsAttrs cannot;
   received-collections is the standing counterexample. (Converges with den-hoag-vyn.)
4. Re-measure the projection with hoisted indices and state the real complexity. §5's rejection of the
   per-(site,node) design compares against a figure that is wrong.
5. I4 needs either a check against REAL compose/run (the §6 fixture's job) or DEMOTION from "all in the core"
   to asserted-and-unexecuted. Also reconcile projectAt's return with `dag // { … }`.
6. Add fixtures varying MARKS and CHANNEL-ALONE at one site, plus a TWO-KINDS-ONE-POLICY-NAME site and a
   NAMELESS-RECORD site — MUT-M/MUT-C/MUT-K/MUT-N all pass today.
7. Fix the two counts; correct §1/§7's pipe.run row and re-size the change against the five
   policiesRules.pipeOps consumers.
8. ★ Record R2 (the vacuous path diff) so the coordinate is NOT re-cited as orchestrator-verified.

════ COVERAGE — NOT EXECUTED ════
No corpus host built under den-hoag or v1 — §6's "old aborts / v1 exit 0" carried from den-hoag-1kd, same
hole as r1 and r2. Design unimplemented, so nothing says the twelve turn green. §5's compose-scaling tables
(2.96 / 0.94 / 248x) NOT re-run — B4 measures the PROJECTION, a different object, and says nothing about the
compose exponent. §4's elimination (17 from-sites, one mark each, collect 7-not-9) NOT re-derived — r1's gate
did, this one did not. B1's silent-wrong-value CONSEQUENCE is READ (design unimplemented); the two call
sites, their scopes and their consumers are EXECUTED. The `targeted` gap and the v1 descendant-inheritance
divergence are READ. lib/compat/** not audited beyond the three files the spec cites.

### 9 — 2026-07-29T05:27:09 · Jason Bowman

★★ GATE ADDENDUM — ops r2, after both orchestrator relays were folded. **VERDICT UNCHANGED: REDESIGN-NARROW.**
Neither relay adds a projection defect. One strengthens B2 to its worst form; the other revises C3 and C8 and
kills ONE SENTENCE in §4. Thesis still preserved. C6's fail-open count STAYS AT THREE — relay 1 makes
fail-open #2 worse, it does not add a fourth.

════ ★★ THE INVERSE TRAP: A RELAYED INSTRUMENT WARNING THAT DID NOT APPLY ════
I relayed "diff on PATH is a wrapper emitting no </> lines". The reviewer CHECKED IT INSTEAD OF ADOPTING IT:
`type diff` in that session resolves to **/run/current-system/sw/bin/diff — the real binary.** Positive control
on the trap's own predicate: two genuinely-differing files give 2 </> lines through PATH diff AND 2 through
the absolute one; `diff -q` exits 1.
It then RE-VERIFIED its mutants on an INDEPENDENT instrument anyway — md5, all six distinct from the original
and from each other (orig 02d676f0…, K 5eaa1f2b…, N abf48f7e…, F bc591395…, C cd2bec54…, M a090666a…,
R 8680f161…), each realdiff_lines=2.
⇒ ★★★ **ADOPTING A RELAYED INSTRUMENT WARNING WITHOUT CHECKING WHETHER IT APPLIES WOULD HAVE "CORRECTED" A
SOUND RESULT.** The warning is real elsewhere; it was not live in that session. A trap log is a set of
CONDITIONAL hazards, and shipping them as unconditional creates a NEW failure mode pointing the other way.
This is the first measured instance in this arc of a correction that would have introduced the error.

════ RELAY 1 — CONFIRMS B2 AND MAKES IT WORSE. B2 PROMOTED. ════
B2 said readsAttrs cannot EXPRESS "reads quirkDag" (instance arg, attributes/default.nix:136), so the rule
cannot fire. The spike adds the half the reviewer did not have: **readsAttrs is NEVER CONSULTED at self.get**
— zero occurrences in gen-resolve lib/resolve.nix / lib/materialize.nix; only schedule.nix (Knuth),
contract.nix (why-trace), equation.nix (constructor). Declared edge → named SCC rc 1. Undeclared edge → rc 0,
SILENT. Residual on the real knot: raw "error: infinite recursion encountered", rc 1, tryEval does NOT catch
it, no schedule gate fires.
⇒ **B2's FAILURE MODE IS NOT "A RULE THAT CANNOT FIRE". IT IS A RULE THAT CANNOT FIRE WHOSE VIOLATION IS AN
UNNAMED, UNCATCHABLE INFINITE RECURSION** — worse than r1's `or identity` on loudness, worse than I2's named
throw on diagnosability.
★ **SECOND UNCATCHABLE CLASS IN THIS DESIGN.** With B3 (attribute-missing, tryEval-uncatchable, measured with
a `tryEval (throw "x") → false` control), condition 5's residual AND the projection's edge-domain residual are
BOTH outside the harness's containment. Neither can be probed defensively; both must be prevented
STRUCTURALLY.
★★ CONSTRUCTIVE REPLACEMENT FOR CONDITION 5, verified first-hand: the well-foundedness fact lives entirely in
lib/default.nix's `let`, not in readsAttrs. policiesIndex = { enrich = indexFeed policiesRules.enrich;
policy = indexFeed policiesRules.policy; } (default.nix:1402-1405) reads policiesRules, NEVER quirkDag, and
declarations calls it unconditionally (structural.nix:347). Today quirkDag → policiesRules.pipeOps and
declarations → policiesIndex → policiesRules.{policy,enrich} share policiesRules as a common ancestor, so no
cycle. Under the design quirkDag stops reading policiesRules.pipeOps and starts reading declarations at every
node ⇒ **THE KNOT IS WELL-FOUNDED IFF policiesRules STAYS quirkDag-FREE.** State the invariant over WHICH
lib/default.nix LET-BINDINGS AN ATTRIBUTE'S INSTANCE ARGS MAY CAPTURE.

★★ THE REVIEWER'S OWN COVERAGE CORRECTION — THE SAME ERROR IT CHARGED IN R2, SELF-REPORTED.
It reported the closure declarations → {enriched-context, suppressed-policies} → {inherited-context,
enrichments} → [ ] reaches no quirkDag, "derived by reading the 6 quirkDag sites in lib/attributes/".
**ITS GREP WAS SCOPED TO lib/attributes/ WHILE THE INSTANCE ARGS ARE BOUND IN lib/default.nix.** Outside that
scope there are 11 further quirkDag references (default.nix:1494/1498/1502/1503/1508/1514/1768/1861/2609,
concern-quirks.nix:58). **THE INSTRUMENT COULD NOT HAVE OBSERVED A CAPTURE WHERE THE HAZARD LIVES.** The
conclusion survives — re-derived directly from policiesIndex's body, and relay 1 corroborates it by having to
EDIT policiesIndex to create the knot — but it was NOT established by the instrument cited. Sound predicate,
different proposition. ★ Recorded rather than quietly fixed.

════ THE THREE GROWTH TERMS, ASSEMBLED FOR THE FIRST TIME ════
Relay 1's H2 measures the KNOT'S FORCING EDGE; B4 measures projectAt's OWN WORK. Different objects, neither
refutes the other.
· **compose term** — cubic in derived-declaration count (§5), but V stays ~17 BY DESIGN because the seed is
  per-SITE. **Does not grow with hosts. THE SPEC'S CLAIM HERE IS CORRECT** and B4 does not touch it.
· **knot forcing term** — Θ(1) → cubic on quirkDag, 99.7% attributed to attrNames structural.eval.allNodes;
  INHERITED from den-hoag-qxz, not created. Relayed, not re-derived.
· **projection term (B4)** — per-(channel,node) atSiteIn fleet scan + per-node firedAt + payloadTable rebuild.
  **QUADRATIC IN HOSTS, NOT BOUNDED BY SITES. THE ONLY TERM THAT GROWS WITH THE FLEET, AND NEITHER THE SPEC
  NOR THE SPIKE MEASURED IT.**

★★ **AND THE SPIKE DOES NOT CLOSE §9 FOR THIS DESIGN.** Its own stated limit: the forcing edge was measured
with an **EMPTY SEED ONLY** — and **the empty seed is exactly the configuration where the design's
contribution is ZERO** (today pipeOps is [ ], which IS the whole defect). The design's seed is non-empty BY
CONSTRUCTION. So "does not create a cubic, inherits qxz's" and "99.7% is knowing the node set at all" are
sound about the KNOT MECHANISM and **CANNOT BE CARRIED TO THE DESIGN'S OWN CONFIGURATION: the predicate was
run on the path where the at-risk contribution is absent.** Same law as R2 and as the reviewer's own
correction above. §9's item is STILL OPEN; the spike establishes a floor and an attribution for the
empty-seed case — genuinely useful, and genuinely not the answer.

════ RELAY 2 — ONE SENTENCE IN §4 IS NOW FALSE ════
Judged sentence by sentence rather than swept:
· §0 "no NixOS toplevel can be produced from the corpus" — **STILL TRUE.** It states the CONSEQUENCE, not the
  remedy. No change.
· §4 "⇒ The entire corpus blockage is one deriving stage in one policy" — **NOW FALSE, AND THE DEFECT IS A
  QUANTIFIER SHIFT INSIDE THE SPEC'S OWN ⇒.** The elimination argument establishes only that ONE CORPUS
  POLICY CAN TRIP **THE GUARD**. The ⇒ promotes that to THE ENTIRE **BLOCKAGE**. The premises support the
  first and not the second, and no measurement in the spec bridges them. ★ **THE ELIMINATION ITSELF IS
  UNTOUCHED AND REMAINS THE SPEC'S STRONGEST WORK** — one word of scope on its conclusion, not a defect in
  the derivation.
· §6's fixture witness — **SURVIVES.** ci/tests/den-behavioral/pipe-per-node-derive.nix is a unit fixture over
  a synthetic two-user fleet with its own vacuity/collapse/projection controls; it never depended on a corpus
  build. Only §6's "Old: aborts … not re-run for r2" bullet carries 1kd's framing and should read rung-1-only.
**C3 REVISED PASS → PASS WITH ONE EXCEPTION.** No sentence licenses deleting a guard or calling a gen change
a one-liner — that holds. §4's ⇒ is the exception, and it licenses the more expensive thing: **CLOSING THE
ARC WHILE OUTPUT STAYS AT ZERO.** The same "moved the failure earlier" shape den-hoag-1kd was retitled for,
now reproduced INSIDE THE SPEC THAT CITES IT.
**C8 — SELECTION STILL PASSES; the IMPLIED DELIVERABLE does not.** The target (den-surface expressibility,
twelve green honestly per den-hoag-i5m, no xfail) is selected from the requirement, and that is what C8
grades. Relay 2 refutes a claim about CONSEQUENCE, not the target. Delivery risk unchanged and still B3.

════ REVISED CONDITIONS FOR r3 ════
UNCHANGED: 1 (project both pipe.run sites / answer consumeAt's contract), 2 (total edge filter + bare-as
fixture with its derived-as control), 4 (re-measure the projection — NOW THE ONLY HOST-GROWING TERM OF THE
THREE), 5 (I4 against real compose/run or demote; reconcile projectAt's return), 6 (marks / channel-alone /
two-kinds / nameless fixtures — MUT-M/C/K/N all pass today), 7 (fix the two counts, re-size against the five
policiesRules.pipeOps consumers), 8 (record R2's vacuous path diff).
**3 — REPLACED, not amended.** Condition 5 cannot be discharged by ANY statement over readsAttrs. State it
over lib/default.nix's let-scope; note the residual is an uncatchable infinite recursion and must be
prevented structurally.
**9 — NEW.** Correct §4's ⇒ to the scope its premises support, and state the rung structure in §0/§6 so the
spec cannot be read as unblocking the corpus.
**10 — NEW.** §9's spike stays OPEN. Re-run on a NON-EMPTY seed before treating the inherited-cubic
attribution as applying to this design.

════ COVERAGE OF THE ADDENDUM ════
EXECUTED: the diff-wrapper check with a positive control; md5 re-verification of all six mutants;
policiesIndex's body and structural.nix:347; the quirkDag reference set outside lib/attributes/ (11 further
sites) establishing its own earlier scope hole.
RELAYED, NOT RE-DERIVED, per instruction: readsAttrs-never-consulted and its rc-0/rc-1 control pair; the
infinite-recursion demonstration; all H2 counters and attributions; the corpus rung chain and its v1 exit-0
control. ★ Their stated limits are carried VERBATIM and NOT leaned past — in particular the empty-seed
attribution is explicitly NOT treated as bearing on the design.
Everything in the original report that neither relay touches STANDS AS FILED: B1, B3, B4, the I4 answer, and
R1/R3/R4/R5.

### 10 — 2026-07-29T06:00:55 · Jason Bowman

★★★ OPS REPRESENTATION r3 SHIPPED — THE CRITICAL PATH. **All eight conditions discharged. Core 24/24 EXIT 0.
13 of 14 mutants KILLED BY A NAMED CHECK; the 14th SURVIVES BY PROOF, not by omission.**
Re-derived and re-run by the orchestrator: .md cd0776ff504ad69576ea0e180bf99b19 / 1157 (was 756);
.core.nix b4a9a7ad0eb9ad46d349068054c39171 / 1146 (was 654); core prints "core: 24/24", EXIT 0.
Anchored den-hoag 5fd3a62 (= HEAD); `git diff 6f30460..5fd3a62` over EVERY cited file is COMMENT-ONLY (the
two Mokhov §4.3→§5.2 edits), so no line number moved.

════ THE EIGHT ════
1 BOTH pipe.run SITES PROJECTED. receivedOutputs → **receivedOutputsAt : pos -> outputs**; consumeAt's
  `outputs` arg → **outputsAt**, computing `outputs = outputsAt at` ITSELF. ★★ **THE CALLER NO LONGER SUPPLIES
  `outputs`, SO IT CANNOT SUPPLY A MISMATCHED PAIR** — by construction, not a rule someone maintains. gen-pipe
  untouched. The DRIFT NOTE at default.nix:1855-1859 is quoted in full and used as the ARGUMENT FOR: it
  permits only "whose eval they read" as a difference, so projecting one and not the other IS the divergence
  it forbids. N-runs cost answered three ways (attr 11 already does N runs; the `.at p` fold is unchanged;
  projectAt is now linear). Sized: consumeAt has **3 external call sites, all in ci/tests/class-tagging.nix —
  no non-test consumer exists today.**
2 EDGE FILTER TOTAL — ★★ **AND BY NEITHER OF THE TWO OPTIONS THE GATE OR I PROPOSED.** Both work, but a THIRD
  needs no new gen field: **compose.nix ALREADY stamps `declIndex = e.i` on every delivery edge** (:225 route
  arm, :235 tee arm) — the index into the decls list THE CALLER PASSED, and den-hoag builds that list.
  ORCHESTRATOR-VERIFIED at both lines, positive control 10 declIndex occurrences. So the filter keys on the
  edge's OWN COORDINATE: no name lookup, nothing a base-channel source can miss. compilePipe additionally
  emits `site` as a pipeOp FIELD (identity belongs on every declaration, deriving or not); the derived-id
  token is untouched. ★ The origin map carries **two explicit values — {site="s"} policy / {site=null}
  fleet-structural — so `null` is a VALUE the route record carries, never an absent key**, and a missing
  declIndex aborts. **NO `or`.** Bare-`as` ships as a check with the derived-`as` control IN THE SAME DAG,
  three arms: fires-both keeps both; **fires-only-derived drops the bare and keeps the derived (a vacuous
  filter FAILS here)**; fires-neither drops both; the quirk edge survives all three.
3 ACYCLICITY INSTRUMENT — ★★ **AND IT IS NOT A DECLARATION AT ALL.** readsAttrs cannot fire; replaced by the
  ARGUMENT SURFACE. The seed closure is declarations → {enriched-context, suppressed-policies} →
  {inherited-context, enrichments} → [ ], **all five in structural.nix**, while attributes/default.nix:158
  calls `structural { policiesIndex, fleetChildren, linkTarget }` and passes quirkDag ONLY to `collections`
  (:177-183). ⇒ **A structural attribute referencing quirkDag is a FREE VARIABLE in a file whose only lexical
  scope is its parameters — a Nix EVAL ERROR, not an unrun check.**
  Positive control same run: `grep -c quirkDag structural.nix` → 0 (exit 1); collections.nix → 4 (exit 0).
  ★ MECHANISM CONTROL, THREE ARMS: {a,quirkDag} exit 0 / {a} + free ref gives "undefined variable 'quirkDag'"
  exit 1 / **the same wrapped in `let quirkDag = 99; in` STILL exit 1** — a separate file has no enclosing
  scope, which is exactly the property the invariant rests on. Construction, not repair.
4 RE-MEASURED — CONFIRMS THE GATE, AND r3 SHIPS THE LINEAR FORM. 3 arms / 4 sizes / 3 samples, one fixture
  generator and one forcing predicate, all arms agreeing on the forced result, all exit 0. Medians net of a
  same-run baseline:
     nodes    r2 form   tbl-hoisted   r3 indexed   ratio
       100     458 ms          286           13      35x
       200    3364           1942           30     112x
       400    8844           3946           62     143x
       800   35556          21009          144     **247x**
  growth 100→800: 2.09 / 2.07 / **1.16**. ★ Hoisting alone recovers only 1.7x — **confirming the gate's
  finding that the table rebuild is NOT the dominant term.** r3 indexed at n=1600/3200: 796/1152 ms.
  ★ HONESTY: the machine was under load and the r2 arm spread to 2.3x at n=800 — **exponent and ratio stable
  across samples, absolute ms not, stated in-spec.** §5's per-(site,node) rejection now compares
  linear-in-nodes against a measured cubic instead of a wrong figure.
5 I4 — SPLIT, PART EXECUTED PART DEMOTED, AND LABELLED AS SUCH. projectAt now returns `dag // {…}` so
  __genPipeDag/declaredIds/topo SURVIVE. EXECUTED: record preservation; **projected edges ⊆ composed edges**
  (the premise r2 asserted the theorem over WITHOUT checking); **refCheck + cycleCheck MODELLED** from
  compose.nix:154-198 / :301-318 and passing on the dag and every projection, **with a vacuity control
  proving both models fire.** Still asserted and labelled: adapterDupCheck / staticClassCheck / dupCheck —
  real-compose check assigned BY NAME to the §6 fixture.
6 FOUR SURVIVORS — THREE KILLED, ONE **PROVED REDUNDANT**. New checks kill MUT-M (shape-key-covers-marks,
  collect-vs-broadcast at one site — the case that loses isSiteMarkData), MUT-K (two-kinds-one-name), MUT-N
  (nameless record).
  ★★ **MUT-C STILL SURVIVES AND NO FIXTURE WAS ADDED FOR A CASE THAT CANNOT ARISE.** compilePipe sets
  `channel = pipeName` AND roots flattenBase at `channelRef pipeName` (compat/pipe.nix:322-329, :351) — **the
  field and the chain base are THE SAME STRING BY CONSTRUCTION**, so no compilePipe output can vary one
  without the other. New check `channel-field-is-coupled-to-chain-base` pins the coupling over every fixture,
  and **MUT-CH (a fixture that BREAKS the coupling) KILLS that check — so the pin is not vacuous.** Term kept
  as defence, redundancy recorded. ★ The gate's ctxShaped note is carried VERBATIM in the fixture comment.
7 COUNTS — one fixed, one NOT PRESENT. den.schema.user.includes re-measured at 4acf0a1d: **11 occurrences /
  9 files, security/opkssh.nix:35 a prose comment ⇒ 10 write sites in 9 modules**; the policies/pipes.nix
  double-count is named; positive control den.schema. → 30 files. The spec now says it is the same error
  class it catches for pipe.collect.
  ★ **"8 of 13 … only 3 fact-shaped" APPEARS IN NEITHER TARGET FILE — it was in the r2 REPORT, not the
  artefact.** Nothing to correct in the spec. Instead the core header now carries an explicit COUNTABLE
  classification of all 24 (6 fact / 7 guard / 2 site-key / 5 projection / 4 I4), verified against 24 `name =`
  entries. §1/§7's pipe.run rows corrected and the change re-sized against all five policiesRules.pipeOps
  consumers plus the second run, the consumeAt contract, `site` on declare.pipeOp, and §6's position-relative
  derivedBaseNames.
8 ★★ R2 RECORDED, AND RE-VERIFIED INDEPENDENTLY. `lib/assemble-pipes.nix` `git cat-file -e` **exit 128 at
  BOTH** revs; the real path exit 0 at 11866c16, a2f4b60 AND corpus pin 99cc0c5a; real-path diff 92 lines
  53+/39−. ★ The byte-identity re-derived WITH ITS OWN CONTROL: `11866c16:970-998` vs `a2f4b60:984-1012` diff
  **exit 0**, and a DELIBERATELY MISALIGNED window `985-1013` **exit 1**. ★ AND A NEW FACT: **99cc0c5a..
  a2f4b60 on that file is EMPTY — the corpus pin and clone HEAD are the same bytes**, so one set of numbers
  serves both. All v1 citations re-derived under nix/lib/aspects/fx/assemble-pipes.nix.

════ THE TWO NON-BLOCKING ITEMS ════
· `targeted` unprojected → §9 open item 4, obligation handed explicitly to den-hoag-4kh.36: **the `site` field
  r3 adds IS already the coordinate 4kh.36 will need.**
· §6's v1 divergence → written into §6 AS A DECISION, not a footnote. pipeData:1045-1053 and assembled:1038
  quoted; **the fixture's third node must be a SIBLING** (where v1 and the projection agree), with the
  descendant case filed as §9 open item 3.

════ ★★ INSTRUMENT NOTE — REMOVED, NOT ACCOUNTED FOR ════
Every possibly-missing lookup now goes through **`mustGet`**, turning `attribute … missing` into a NAMED throw
the harness CAN catch. ★★ **AND A SECOND UNCATCHABLE CLASS THE GATE DID NOT NAME: `tryEval` DOES NOT CATCH A
COERCION ERROR EITHER** — deleting siteOf's abort first produced "cannot coerce null to a string", an unnamed
kill. Restructured so `siteKeyOf` is deliberately TOTAL (a nameless record yields a well-formed UNSTABLE key —
**what the defect actually looks like**) with the abort a SEPARATE GUARD over it, so deleting it yields a
WRONG VALUE a named check observes.
★ EVIDENCE: **r2 had 3 unnamed kills, r3 has 0.**

════ MUTATION BATTERY — every mutant diff-verified non-no-op, exits read from the process ════
MUT-F, MUT-ID, MUT-R, MUT-T, MUT-M, MUT-K, MUT-N, MUT-E (3 checks), MUT-Q, MUT-D (2), MUT-I1 (2), MUT-G,
MUT-CH — all EXIT 1 with their named check. **MUT-C EXIT 0, SURVIVES BY PROOF.**

════ COVERAGE — HONEST, AND MARKED ✓r2/(r1) IN-SPEC ════
NOT re-derived for r3: §4's corpus elimination (17 from-sites / one mark each / collect 7-not-9) — r1 and r2
derived it, r3 did not. §5's compose-scaling tables (2.96/0.94/248x) — **never re-run at ANY revision.**
§6's "old aborts / v1 exit 0" — carried from den-hoag-1kd, never re-run. §7's per-primitive inventory and the
19-channel-references row — carried, only the pipe.run row corrected.
★★ NOT DONE AT ALL: **NO CORPUS HOST BUILT UNDER den-hoag AT ANY REVISION OF THIS DOCUMENT**; the design is
unimplemented, so **nothing establishes that the twelve turn green.** lib/compat/** unaudited beyond cited
files. ★ **The §5 projection table measures THE CORE'S definitions, not den-hoag's wiring — a MODEL of the
projection, stated as such in-spec.**

⇒ NOT YET GATE-REVIEWED. Its r3 gate is the next dispatch on this bead.

### 11 — 2026-07-29T13:23:08 · Jason Bowman

★★ GATE REVIEW r3 — ops representation. **VERDICT: VALIDATED-WITH-CONDITIONS (4 blocking, 2 non-blocking).**
Thesis NOT re-litigated. Artefacts re-derived and matching (cd0776ff…/1157, b4a9a7ad…/1146); core "core:
24/24" EXIT 0 read direct. ★ Anchor-drift handled properly: the spec anchors 5fd3a62, the tree is 0f8c326, and
`git diff 5fd3a62..0f8c326 -- lib/ ci/ parity/` is EMPTY (whole-range diff = .beads/beads.jsonl only) ⇒ every
line number holds at the tree read.
★★ **FOUR OF SIX DISPATCH TARGETS SURVIVED THE ATTACK** — reported below as results, not omissions.

════ ★★★ B1 — THE SPEC ASSERTS CORPUS SCOPE ITS OWN TRACKER MEASURED FALSE, AND NEVER CITES IT ════
§0:62 "no NixOS toplevel can be produced from the corpus" + §4:600 "⇒ **The entire corpus blockage is one
deriving stage in one policy.**" against this bead's OWN comment 6: "VERDICT ON THE PREMISE: UNSOUND AS
STATED. Fixing the ops representation clears RUNG 1 ONLY … CHAIN DEPTH ≥3 PER HOST IS A FLOOR, NOT A CEILING."
Spec grep, same instrument same run: `rung` 0 (exit 1) · `successor` 0 · `id_hash` 0 · `__denNode` 0 ·
`resolve-verbs` 0 · `microvm` 0 · `toplevel` 1 (only §0:62). **Positive control `corpus` = 25, exit 0** ⇒ the
predicate is not under-matching.
★ The spec's honesty note covers what is UNVERIFIED ("nothing here establishes that the twelve turn green").
**It does NOT cover a POSITIVELY MEASURED result that bounds the claim.** Comment 6's own warning: "if 53.64
lands as-is, the arc reads 'critical path fixed' while corpus output stays at zero."
★★ **ORCHESTRATOR CONFIRMATION, INDEPENDENT: THIS IS MY RELAYED CONDITION 9, AND IT NEVER LANDED.** I
re-measured — `rung`/`successor`/`id_hash`/`__denNode`/`microvm` all **0** against a `corpus` control of 25,
and `empty seed` (relayed condition 10) also **0**. The r3 report enumerated the ORIGINAL EIGHT and claimed
"all eight discharged"; **conditions 9 and 10 were never addressed and their absence was invisible because the
report's own structure was the checklist.** See the process note at the end.

════ B2 — THE CORE DISCHARGES A MECHANISM `declare.pipe.route` CANNOT EXPRESS ════
gen-pipe lib/operators.nix:155-164: `route = { from, select, to }: {…}` — **a CLOSED pattern: no `site`, no
`...`**. Probe, exits direct: `route {from;select;to;site="s";}` → "error: function 'route' called with
unexpected argument 'site'" EXIT 1; positive control without `site` → 5 keys, EXIT 0. And den-hoag's emitter
at lib/compat/pipe.nix:343 passes exactly `{ from; select; to; }` ⇒ **no den-hoag route decl carries `site`.**
But core :550-555 defines `route = site: from: to: {… inherit from to site; …}` and :350-366's
`originOfDecl` reads `value = { inherit (d) site; }` OFF THE ROUTE RECORD. Checks 6 and 20
(fleet-structural-edge-is-unconditional) and §1's argument — "★ null is a value the route record carries (a
quirk route passes it deliberately), not a key that happens to be missing" — ALL rest on that shape.
★ THE SPEC'S PROSE SAYS SOMETHING ELSE AND FEASIBLE: the map is keyed "from the same walk that built the
declarations". **That works and needs no gen change** — but under the walk form there IS no site field on the
route record, so the quoted justification for null-as-value EVAPORATES and must be re-derived. Under the
core's form the design needs a gen-pipe change, contradicting §7's "★ This design requires NO gen-pipe change."

════ B3 — CONDITION 3's INSTRUMENT IS SOUND BUT PROVES A NARROWER PROPOSITION THAN THE INVARIANT NEEDS ════
Everything the author claims REPRODUCES: `grep -c quirkDag structural.nix` → 0 exit 1; collections.nix → 4
exit 0; params at :23-31 and :32-40 contain no quirkDag; threading verified. ★ **The three-arm mechanism
control was RE-RUN by the reviewer**: {a,quirkDag} EXIT 0 / {a}+free ref "undefined variable 'quirkDag'"
EXIT 1 / **the same under `let quirkDag = 99; in` STILL EXIT 1.** Confirmed.
★★ **BUT IT EXCLUDES ONLY A DIRECT TEXTUAL REFERENCE INSIDE structural.nix. IT DOES NOT EXCLUDE quirkDag
ARRIVING THROUGH ANY OF THE NINE ARGUMENTS.** Those are minted in lib/default.nix in ONE `let` where quirkDag
is an in-scope SIBLING binding — fleetChildren:1171, linkTarget:1215, policiesIndex:1402, quirkDag:1494 —
and **Nix `let` is RECURSIVE, so textual order gives nothing.** A `policiesIndex` reading quirkDag yields NO
free variable and NO eval error, and the acyclicity hazard returns silently — **the exact failure mode r2's
readsAttrs rule had.**
Currently CLEAN and verified (all quirkDag refs in default.nix are :1494,:1502,:1503,:1508,:1514,:1768,:1861,
:2609, none inside those three bodies) — so the invariant holds today, **MAINTAINED BY NOTHING. That is a
REPAIR WEARING BY-CONSTRUCTION CLOTHING.**

════ B4 — AN UNCATCHABLE ABORT CLASS REMAINS AND IS REACHABLE IN THE SHIPPED CORE ════
tryEval classification with a same-run positive control (`tryEval (throw "x")` → false EXIT 0):
`{}.missing` EXIT 1 (the spec's claim ✓) · **`head []` EXIT 1** · **`elemAt [] 0` EXIT 1** · coercion EXIT 1.
⇒ `head []` and `elemAt`-out-of-range are EQUALLY uncatchable, and the core still uses raw forms at
load-bearing sites: composeOf.idxOf :272-274, projector.slotIx :478, **projector.at.payloadFor :495**.
CONSTRUCTED INPUT — two nodes at ONE site with DIFFERENT CHAIN LENGTHS (node a derives over+map, node b bare):
  ARM 1 `shapeDisagreement em != null` → **true, EXIT 0** — the design's guard SEES it.
  ARM 2 the harness on the same input → **"error: 'builtins.elemAt' called with index 0 on a list of size 0",
  EXIT 1, uncatchable, no check name.**
⇒ **REFUTES "r3 does not account for the class; it removes it" and "r2 had 3 unnamed kills, r3 has 0."** The
class was removed FOR ATTRSET-KEY LOOKUPS ONLY. The 13/14-named mutant result may still be true as measured;
**the GENERALISATION is what fails.**
★ SECOND-ORDER: `projector` NEVER calls `shapeDisagreement`, and `seedDecls` is first-wins `head (atSiteIn …)`.
The ordering obligation "guard before projector" is **UNSTATED and is itself a repair.**

════ NON-BLOCKING ════
N1 — I4's models are FURTHER FROM compose THAN DISCLOSED. All cited coords real, but real compose returns
**5 keys** while core composeOf returns **8**, inventing baseNames / siteOfName / originOfDecl — grep on
compose.nix with a positive control: `baseNames` exit 1, `siteOfName` exit 1, `originOfDecl` exit 1,
`declaredIds` exit 0. **Both modelled guards consume `dag.baseNames` via mustGet, so NEITHER MODEL CAN RUN
AGAINST A REAL DAG AT ALL**, and `projection-preserves-the-dag-record` pins an 8-key record real compose never
produces. concernQuirks.compose is a bare `pipe.compose (…)` so quirkDag IS the raw 5-key output ⇒
siteOfName/originOfDecl must be supplied BESIDE it, not folded in. ★ And the real argument needs no model at
all: **the projection only DROPS edges, and refCheck/cycleCheck are MONOTONE UNDER EDGE REMOVAL.**
N2 — condition 1's residual is not zero. Making consumeAt compute `outputs = outputsAt at` genuinely removes
the mismatched-PAIR class, but a caller supplying an outputsAt that IGNORES its argument (`_: fixedOutputs`)
reproduces the defect one level up, unguarded. Accidental mismatch gone; deliberate is not.

════ ★★ FIVE REVIEWER HYPOTHESES REFUTED — REPORTED AS RESULTS ════
1. "declIndex is an index into the FILTERED op list, not decls" — **REFUTED.** compose.nix:207-212 maps FIRST
   and filters AFTER over `idxs = range 0 (n-1)`, `n = length decls`, so `e.i` IS the caller-passed decls
   position; `declIndex = e.i` confirmed at :225 and :235, control `grep -c declIndex` = 10.
   ★ **STABILITY SOUND FOR A REASON THE SPEC DOES NOT DRAW: declIndex is COMPOSE-LOCAL** — never escapes one
   compose, rebuilt with the map in the same walk — **so the positional-drift hazard §8 correctly flags for
   the SITE key does NOT transfer to it.** Tee sub-edges share one declIndex and one origin; a tee decl with
   no originOfDecl entry aborts via mustGet ⇒ **fail-CLOSED, the right direction.**
2. "MUT-C can be broken" — **REFUTED, could not.** compat/pipe.nix:322-329: BOTH arms of flattenBase root at
   `channelRef pipeName`, and :351 sets `channel = pipeName`. One variable, two uses. ★ **And the redundancy
   is STRONGER than the spec argues**: core chainOf includes the BASE element and shapeKeyOf maps it to
   "${d.id}:base" where chRef's id == name == pipeName, **so the base id term LITERALLY CARRIES the channel
   string.** `join` (the only multi-input op, which would break the head-walk) is unused per §7.
   **MUT-C's survival-by-proof STANDS.**
3. "The cost claim is optimistic" — **REFUTED, re-measured INDEPENDENTLY** on the core's own projector, 17
   sites, forcing every projected __derive.f to WHNF plus `length edges`, net of a same-run baseline, all
   EXIT 0: n=100 75 ms · 200 150 · 400 319 · 800 699 ⇒ **×9.3 over 8×, exponent ≈1.07, per-doubling
   2.00/2.13/2.19. LINEARITY CONFIRMED** (spec claims 1.16; the reviewer's is cleaner).
   ⚠ **The 247× vs the r2 form is NOT independently verified** — r2's projectAt is not in the shipped
   artefact, so that arm could not be built.
4. "Cited coordinates drifted" — **REFUTED, 14/14 spot-checked exist and match at 0f8c326.** C5 PASSES.
5. Relayed-warning check: `type diff` → already the real binary, so the absolute-path remedy was unnecessary
   here; `type grep` → shell function, so /run/current-system/sw/bin/grep used for every count. ★ The
   check-don't-adopt discipline applied correctly.

════ THE RUBRIC ════
C1 FAIL (B1 unstated corpus precondition; B3 unstated arg-purity precondition) · C1-a PASS (siteKeyOf total,
originOfDecl total-with-abort) · C2 PASS · C2-a PASS (the edge-subset premise is now CHECKED, not asserted) ·
C3 PASS · **C4 PASS ON THE DESIGN, FAIL ON THE HARNESS** (B4's silent whole-run kill; repairing discipline
named) · C5 PASS (14/14 + gen-pipe lines) · **C6 FAIL** (B4 executed; B1 on the corpus input) · **C7 FAIL**
(B3, plus B4's unstated ordering obligation) · C7-a PASS — **declIndex is the right primitive and it already
exists** · C7-b PASS, independently re-measured linear · **C8 FAIL** (B1) · C9: THEORY PASS,
**MECHANISM FAIL** (B2 — core and prose implement DIFFERENT mechanisms and the core's is infeasible),
ARGUMENT PARTIAL (B3) · C9-a PASS. Domain→index→codomain traced to declaration sites both ways.

FAIL-OPENS: (1) corpus-scope overclaim, silent [B1] · (2) quirkDag via a `structural` argument — no free
variable, no error [B3] · (3) list-index abort kills the run instead of naming a check [B4] · (4) outputsAt
ignoring its argument [N2]. ★ **The two the design DID close are real and both were verified**:
absent-declIndex⇒everywhere is now a mustGet abort, and `or identity` is gone.

════ COVERAGE ════
EXECUTED: core run; hash/rev re-derivation; anchor-drift diff; the three-arm lexical control; the grep control
pair; the route-constructor probe and its control; the tryEval class matrix and control; the elemAt
reachability probe; an independent 4-point cost harness with a baseline arm; 14 coordinate spot-checks;
gen-pipe reads with absence controls plus a positive control.
READ ONLY: evaluate.nix's six-operator position-blindness NOT re-verified. v1 assemble-pipes byte-identity and
all §1/§6 v1 semantics carried, NOT re-run. §4's corpus elimination marked ✓r2, NOT re-derived. §5's
compose-cubic tables never re-run at any revision.
NOT DONE: den-hoag suite not run; r2's projectAt not reconstructed so 247× and exponent 2.09 are unverified;
lib/compat/** unaudited beyond cited files; **no corpus host built.**

### 12 — 2026-07-29T13:54:52 · Jason Bowman

★★ OPS REPRESENTATION r4 AUTHORED — THE CRITICAL PATH. All six conditions discharged. Re-derived by the
orchestrator: .md 8694744fea01c7f2ec7c0f4d31971c4f / 1493 (was 1157); .core.nix
bbf235b084966aa99fd38b93b117b504 / 1417 (was 1146). Core "core: 28/28" EXIT 0.
★ THE RELAY-VERIFICATION WORKED: the two conditions that silently vanished at r3 are present this time —
rung x15, successor x5, id_hash x2, __denNode x2, "empty seed" x4, vacuous x5, against a `corpus` positive
control of 43.

════ ★★ TWO CORRECTIONS TO THE ORCHESTRATOR, BOTH VERIFIED AGAINST THE FROZEN BLOB ════
1. **MY GREP FOR `monotone` RETURNED 0 AND THE SPEC HAS IT.** Defeated TWICE OVER: by CASE (written MONOTONE)
   and by STEM ("monotonicity" does not contain "monotone"). Measured: lowercase `monoton` = 1,
   case-insensitive = 2. ⇒ Filed to 4kh.20 — **a full-word case-sensitive grep misses both the capitalised
   form and every morphological variant, and returns a clean zero either way.**
2. **CONDITION 6 (record R2) WAS REDUNDANT — R2 ALREADY LANDED IN r3.** Verified against the FROZEN r3 blob at
   papers f7a6a3d: `orchestrator verification was vacuous` = **1 hit**, at r3 lines 1014-1032, with the
   cat-file -e 128 pair, the 92-line 53+/39- diff and the misaligned-window re-derivation. The same blob has
   `rung` = **0**. ⇒ **ONLY THE TWO RELAYED CONDITIONS (the corpus rung structure and the non-empty-seed
   spike) EVER FAILED TO LAND** — the gate's zero-hit grep was for THEIR markers, and I mis-attributed it to
   R2 as well. r4 still adds value there: a greppable label plus the PROHIBITION "this coordinate must not be
   cited as orchestrator-verified; the only sound derivations are the r2 reviewer's and the r3 re-check".

════ THE SIX ════
C1 CORPUS SCOPE DISCHARGED. §0:62 now reads "every v1 pipe policy trips this guard". A new §0 subsection
  carries the rung table VERBATIM with all four successor beads named — rung2 collections.nix:205 id_hash
  (axon/blade) → 3w6; microvm-guests.nix:43 aspect (cortex, never reaches the id_hash site) → c3m; rung3
  resolve-verbs.nix:44 __denNode → xg3; axon `services` + blade `stylix.image` → oh3 — plus three bounding
  facts: forks per host; every rung ≥2 is a den-hoag divergence (v1 99cc0c5a exit 0 with a real .drv);
  **depth ≥3 is a FLOOR because rung 3 could not be disabled anywhere.** §4's ⇒ restated with the quantifier
  shift NAMED, **the elimination itself untouched**; §6's "Old: aborts" marked rung-1-only.
C2/B2 DISCHARGED — ★★ **MECHANISM IS THE WALK; `declare.pipe.route` IS AVOIDED ENTIRELY.** Constructor read
  first-hand (operators.nix:155-164, closed), emitter at compat/pipe.nix:340-347, and a 4-arg probe gives
  "function … called with unexpected argument 'site'" EXIT 1, uncatchable. `seedDeclsWithOrigin` emits
  { decl; origin; } from the per-site walk — **the site is already in hand because the walk IS iterating
  sites** — and composeOf's quirk arm supplies { site = null; }. **No route record is ever read for origin.**
  ★★ AND THE ENFORCEMENT IS THE CONSTRUCTOR ITSELF: the core's fixture `route` now reproduces gen-pipe's
  signature EXACTLY, **so the core cannot drift back to r3's shape without failing to eval.** Deliberately NOT
  a check — that error is uncatchable, so a check could only die of it. null-is-a-value re-grounded as two
  arms of ONE construction rather than two states of one field. ★ The `site` field on den-hoag's OWN pipeOp
  record stays and is still feasible; it was only the GEN-PIPE op record that could not carry one.
C3/B3 DISCHARGED AS **THREE OBLIGATIONS**, and the author stopped calling the whole thing by-construction.
  ★ It is **TEN formals, not nine** (7 library + 3 feeds).
  · O1 no textual reference — by construction (r3's, carried with its 3-arm control).
  · O2 NEW, replacing r3's instrument: **readsAttrs is a declaration gen-resolve NEVER consults at self.get,
    so r3's closure was a LOWER BOUND.** Re-established on the READ EXPRESSIONS: all 7 `self.get` in
    structural.nix read the five names defined in that same file; the only other form is `self.node`.
    Positive control: collections.nix = 3.
  · O3 = the gate's B3, **STATED AS ENFORCED BY NOTHING**, and split: the 7 library args are minted in the
    OUTER let while quirkDag is an INNER formal ⇒ by construction; the 3 feeds are quirkDag's
    recursive-`let` SIBLINGS (1171/1215/1402/**1494**) ⇒ nothing.
  ★ WHAT ENFORCES IT IS A CONSTRUCTION, NOT A RULE: a new lib/structural-feeds.nix minting the three OUTSIDE
  quirkDag's scope, with the free variables measured by reading the three bodies — **11 names, no quirkDag**.
  ★ AND ITS LIMITS ARE STATED: it cannot stop someone adding quirkDag to the 11, and **it PROPAGATES** — the
  knot is well-founded iff policiesRules itself stays quirkDag-free. Residual named as vyn measured it:
  "infinite recursion encountered", rc 1, **not tryEval-catchable, no schedule gate fires** (control: the same
  patch on HEAD quirkDag gives rc 0).
C5 KNOT SPIKE **LANDED (was missing) AND KEPT OPEN.** §9(1) states that the spike measured the forcing edge
  with an EMPTY SEED ONLY — its ops fixture never reached compose (compose.nix:38 "attribute 'op' missing") —
  and that **the empty seed is exactly the configuration where this design's contribution is zero.** So
  "inherits qxz's cubic" and "99.7% is knowing the node set" are **sound about the knot MECHANISM and are not
  results about this configuration; carrying them across is the same error as R2.** Three named re-run
  targets, plus the spike's own fixture trap recorded: **an env-root include reaches the env node ONLY, so an
  env-root spelling measures an empty path and looks clean.**

════ ★★ B4 — THE LIST-INDEX CLASS IS CLOSED IN TWO PLACES ════
All four classes measured in ONE run with a `tryEval (throw "x")` control: `{}.missing`, `head []`,
`elemAt [] 0` and unexpected-arg **ALL EXIT 1**.
**(i) BY CONSTRUCTION** — shapeDisagreement now runs INSIDE composeOf and throws, so **a disagreeing fleet has
no dag and no path reaches the projector with one.** §3 gains property 5 naming lib/concern-quirks.nix's
single `pipe.compose` as the seam. ★ **THIS IS WHAT TURNS "guard before projection" FROM THE GATE'S UNSTATED
ORDERING REPAIR INTO A CONSTRUCTION.**
**(ii) BY NAMED ABORT** — `mustHead` and `mustAt` added beside `mustGet` and applied at all three sites the
gate named plus five more. Remaining raw `elemAt` are only those indexed through `genList` over a list's own
length — total by construction, **and the construction is now written at the site.**
★★ **THE GATE'S EXACT INPUT WAS VERIFIED, AND THE ABORT TEXT PROBED RATHER THAN THE BOOLEAN**: two nodes at
one site with chains of length 2 and 1 give, on the compose arm, "den-hoag: compose shape (per-site):
declaration site 'host/chain-len-0' emits a DIFFERENT pipe shape at node 'host:b' than at node 'host:a'"; and
on the projector arm (dag composed from node a alone), "den-hoag core: payloadTable … index 1 is out of range
on a list of 1". **Both are named throws tryEval catches.** Shipped as checks 14 and 23, the latter with an
**aligned-node control so the failure is attributable to the misalignment rather than to the projection
failing everywhere.**

════ THE 18-MUTANT BATTERY — each md5-verified distinct, exits read direct ════
NAMED KILL (16): MUT-F · MUT-ID · MUT-R · MUT-T · MUT-M · MUT-K · MUT-N · MUT-E · MUT-Q · MUT-D · MUT-I1 ·
MUT-G · MUT-CH · **MUT-GRD** (guard removed from composeOf) · **MUT-IX** (index folded back onto the dag) ·
**MUT-WALK** (the per-site walk supplies null instead of its site).
SURVIVES (1): **MUT-C — still survives BY PROOF after all changes**, with the coupling check re-verified over
the enlarged fixture set including the new chain-len fleet, and MUT-CH still killing it so it is not vacuous.
★★ UNNAMED KILL (1): **MUT-AT — mustAt reverted to raw elemAt. THIS IS DELIBERATE: it is the POSITIVE CONTROL
ON r4's OWN FIX**, reproducing the gate's B4 on demand and establishing that `mustAt` is the edit that changed
the outcome rather than some other r4 change. Recorded in the battery table AS A CONTROL, not as a kill.
⇒ ★ The spec now says plainly that **per-mutant counts measure the HARNESS, not the class** — and that r3's
"13/14 named" was the same statistic pointed the other way.
★ AND IT GRADES ITS OWN CHECKS ON STRENGTH, NOT REACHABILITY: strongest are edge-filter-is-total-over-bare-as
(4 arms including a vacuity-detecting control), fleet-structural-edge-is-unconditional (in-run absence
control), compose-refuses-a-disagreeing-fleet (**third arm is a LEGAL fleet, so an always-throwing compose
fails**), and misaligned-chain-payload-aborts-by-name. **Weakest, stated: shape-key-covers-* are SINGLE-BIT
(they catch a DROPPED term, not a WRONG one); seed-size-is-sites-not-nodes is a two-number pin any fixture
could satisfy; the new monotonicity check is exhaustive over a 3-edge dag and therefore not over the property.**

════ N1 — TAKEN, AND THE CORE RESTRUCTURED ON ITS OTHER HALF ════
I4's PRIMARY argument in §1 is now that **the projection ONLY DROPS EDGES and refCheck/cycleCheck are MONOTONE
UNDER EDGE REMOVAL** (refCheck quantifies over edges so fewer obligations; a cycle is a subgraph and a
subgraph of an acyclic graph is acyclic). **Needs no model.** Its premises are the three already-executed
checks. The models are RETAINED as an explicitly redundant second instrument with r3's gap disclosed.
★ AND composeOf now returns **{ dag; index; baseNames; }** — `dag` is exactly the real 5 keys (pinned by check
24), `index` is den-hoag's coordinates, `baseNames` is model-only and passed EXPLICITLY to the two guards.
Because concernQuirks.compose is a bare pipe.compose, quirkDag IS the 5-key output ⇒ **the coordinates must
sit BESIDE it — and B2's walk reaches the same conclusion independently, which the spec says.** New check
projection-index-is-supplied-beside-the-dag asserts both directions, and
modelled-guards-are-monotone-under-edge-removal ships **with a control (a dag on which the guards demonstrably
CAN fail, recovered by dropping the offending edge) so "every subset is clean" is not clean-by-vacuity.**
N2 named in §1's contract paragraph.

════ COVERAGE — NOT EXECUTED ════
Suite not run. **No corpus host built, at any revision.** §4's corpus elimination not re-derived (r1/r2 only).
§5's compose-scaling cubic tables not re-run. §1's six-operator position-blindness carried from r2, not
re-verified. O3's infinite-recursion residual RELAYED from the vyn spike, not re-run here.
★ **lib/structural-feeds.nix is SPECIFIED, NOT PROTOTYPED** — the 11-name free-var list comes from READING the
three bodies, not from evaluating an extracted file; **if it is wrong the extraction is bigger than sized.**
★ The 247x r2-vs-indexed ratio remains UNREPRODUCED (r2's projectAt is not in the artefact); the LINEAR claim
is doubly measured (author 1.16, gate ≈1.07) but **the COMPARISON rests on one run.**
lib/compat/** unaudited beyond cited files. §9(1) open by design.
★ Anchor-drift note: the author verified `5fd3a62..3ac6443b -- lib/ ci/ parity/` EMPTY and flagged that HEAD
was 3ac6443b, not the 6275e45 my dispatch named — citations hold either way.

⇒ NOT YET GATE-REVIEWED. Its r4 gate is the next dispatch on this bead.

### 13 — 2026-07-29T14:16:55 · Jason Bowman

★★ GATE REVIEW r4 — ops representation. **VERDICT: VALIDATED-WITH-CONDITIONS (3 blocking, 2 non-blocking).**
Thesis NOT re-litigated. Artefacts re-derived and MATCHING; core 28/28 EXIT 0 read direct. ★ Anchor drift
handled with a `cat-file -e` CONTROL PAIR (lib/default.nix exit 0 / lib/NOSUCHFILE.nix exit 128), so every
line number holds at the REVIEWER's tree, not just the author's.
★ **15 distinct mutants/probes, 0 duplicate md5 across all 15 plus the original**: 5 named kills, 6 survivors,
3 unnamed kills, 1 fail-open probe.

════ ★★★ B1 — "THE CONSTRUCTOR IS THE ENFORCEMENT" IS REFUTED ════
THE MECHANISM HALF SURVIVES AND IS CORRECT, verified three ways: gen-pipe operators.nix:155-164 is a CLOSED
`{ from, select, to, }` — probed on the REAL assembled library (control → 5 keys EXIT 0; `+site` → unexpected
argument, **and wrapped in tryEval STILL EXIT 1**, uncatchable, same run). ★ NEW, closing the reachability gap
the r3 probe left: **`declare.pipe.route` is `inherit (pipe) route` at lib/declarations.nix:435-444 — a DIRECT
RE-EXPORT, not a den-hoag wrapper**, so the closed pattern reaches the emitter. Origin-path sweep: every
`site` read is `e.pipeOp.site` (den-hoag's OWN record) or supplied by the walk; **no route field is read for
origin**, and stronger than claimed — composeOf's quirkOps arm supplies `{site = null;}` UNCONDITIONALLY, so
even a quirkOp carrying a site would be ignored.
★★ **BUT THE ENFORCEMENT CLAIM IS FALSE. THE CORE'S `route` IS A HAND-WRITTEN REPLICA AND THE CORE HAS ZERO
IMPORTS** (grep for import/fetchTree/<nixpkgs> hits only the header comment; positive control
`inherit (builtins)` = 1, so the predicate fires). Nothing links it to operators.nix.
· MUT-R1 (`site ? null` re-added and passed) → **28/28 EXIT 0**.
· **MUT-R2, THE FULL r3 SHAPE** — required `site` on the constructor, supplied at all four call sites, and
  `originOfDecl` reverted to read `value = { inherit (d) site; }` OFF THE ROUTE RECORD → **28/28 EXIT 0**.
⇒ **NO CHECK IN THE 28 DISCRIMINATES r4's WALK MECHANISM FROM r3's INFEASIBLE ROUTE-RECORD MECHANISM. B2 IS
DISCHARGED BY DELETION, NOT BY A CHECK**, and the stated enforcement is a REPAIR someone must keep in sync.
★ Same class for the other two gen-surface pins: check 6 asserts `declIndex` on edges **composeOf ITSELF
writes**, and check 24 pins a five-key list **hand-transcribed** — neither can observe compose.nix drift.

════ ★★ B2 — B4(i) IS A REAL CONSTRUCTION AND IT LEAVES A NEW SILENT FAIL-OPEN ════
"Can you reach the projector with a disagreeing fleet by any route?" — **YES.**
`projector = emissions: dag: index:` takes emissions **SEPARATELY FROM THE DAG, WITH NOTHING PAIRING THEM.**
composeOf's guard runs on composeOf's emissions; the projector rebuilds tbl/firedIx/slotIx from ITS OWN
argument. **Check 23 exploits exactly this in-file.** ⇒ §754's "there is no path on which the projector can
see one" is FALSE AS WRITTEN; the true statement (which :1318 does make) is "no path on which it sees a dag
COMPOSED FROM one".
★★ **AND THE MISMATCH CAN BE SILENT, NOT MERELY A NAMED ABORT. PROBE, EXECUTED:** a dag composed from
[hubShares "user:a" "a"] and projected with [hubShares "user:a" "IMPOSTOR"] — same site, same shape, same node
id, different payload owner — gives `{ guard_ran_on_e1 = true; honest_user = "a"; mismatch_user =
"IMPOSTOR"; silently_wrong = true; aborted = false; }`. **NO ABORT. WRONG VALUE.**
★★★ **THIS IS EXACTLY THE `{ outputs; at; }` DEFECT §1 REMOVES BY MAKING consumeAt COMPUTE ITS OWN outputs —
AND THE DESIGN DOES NOT APPLY THAT REMEDY TO `(emissions, dag)`.** It names the analogous N2 residual for
outputsAt and not this one.
★ AND IT IS NOT THE "deliberate misuse" class: in den-hoag the compose is ONE call (concern-quirks.nix:55,
verified) while the projection is TWO SITES READING DIFFERENT EVALS — attribute 11's in-flight `self` versus
default.nix:1860's final `structural.eval`. **That is the spec's OWN QUOTED DRIFT NOTE.** If the two emission
queries ever differ, at least one projector call is projecting a dag composed from the other's emissions.
**THE FAIL-OPEN IS ARCHITECTURAL, NOT HYPOTHETICAL.**

════ ★★ B3 — structural-feeds.nix DOES NOT CLOSE, AND THE PROPAGATION IS 7 NAMES NOT 1 ════
★ **THE 11-NAME LIST IS CORRECT** — the reviewer extracted the three regions itself and ran an independent
lexical free-variable analysis; union is exactly the 11 named, quirkDag absent, **with a per-region control
that FIRES in each region** (its first pass used `prelude`, which is 0 in region C — a non-firing control —
and it redone per-region).
★★ **BUT THE EXTRACTION HAS A CROSS-FILE CYCLE.** 11 reconciles only with the WIDE reading (the file must
also move entryNodeIndex, policyKindNames, indexFeed, since linkTarget/policiesIndex are thin aliases; the
narrow reading is 7 names and leaves the helpers behind as quirkDag's siblings, preserving the hazard). And
structural-feeds.nix must TAKE `prePass`, **while prePass (:1039-1057) IS BUILT FROM `indexFeed`** (:1046,
:1053) ⇒ **the new file would mint what its own argument is constructed from.** Resolvable by splitting in
two, but the r4 hedge lands: the free-var COUNT is right, the SHAPE is not.
★★ **AND THE PROPAGATION OBLIGATION IS UNDERSTATED BY SIX.** The spec names ONE ("the knot is well-founded
iff policiesRules stays quirkDag-free"). Measured: lib/default.nix has ONE recursive let, :406 → in :2504. Of
the 11, **four are outer/by-construction** and **SEVEN are recursive-let SIBLINGS of quirkDag:1494** —
denMeta:942, ent:943, prePass:1039, rootScopeKinds:1079, cellFamilies:1087, theFleet:1109, policiesRules:1390.
**Every one is the identical hazard.** (Direct reads clean today; TRANSITIVE closure NOT computed — a stated
coverage limit.)

════ NON-BLOCKING ════
★★ N1 — **`mustHead` IS NOT LOAD-BEARING ANYWHERE, AND IT REFUTES A STATED MECHANISM CLAIM.** Global
reversion one guard at a time: **MUT-ALLHEAD (every mustHead → raw head) SURVIVES at 28/28**; MUT-ALLAT →
EXIT 1 UNNAMED; **MUT-ALLGET → EXIT 1 UNNAMED with `attribute '"0"' missing` — A SECOND UNNAMED KILL NOT IN
THE BATTERY.** ⇒ No fixture reaches an empty list at any of the ~15 mustHead sites, so core :68's "mustHead
and mustAt are what the r3 gate's input needed" is **REFUTED — mustAt ALONE was needed**, and B4(ii) is
evidenced at **1 of ~22 guarded sites**. MUT-AT itself is SOUND instrumentation, but the unnamed-kill outcome
is a property of reverting ANY of the three guards.
★★ **AND TWO ORDINARY DESIGN EDITS PRODUCE UNNAMED KILLS THE SPEC DOES NOT ENUMERATE**: dropping
`filter hasDerive` gives "expected a list but found a set" (TYPE error) and excluding the base element from
the chain gives "expected a string but found null" (COERCION error). **The core's header enumerates FOUR
classes and claims r4 removes them; type and coercion are not in that list**, though the file's own MUT-N
comment knows coercion is uncatchable. Control: dropping `marks` from keyedFields gives a NAMED kill, so the
totality discipline works.
N2 — **THE SELF-GRADING IS ACCURATE ON TWO OF THREE, WRONG ON THE THIRD, AND MISSES A FOURTH.**
shape-key-covers-* single-bit CONFIRMED **and sharper**: they are covered at TERM granularity, not FIELD
granularity — weakening rather than dropping `t.from.id` or `r.from.id` **SURVIVES at 28/28**, giving **TWO
uncovered sub-terms, both `from` endpoints**, both MUT-C-class survivors by proof. seed-size two-number pin
CONFIRMED. ★ **Monotonicity "exhaustive over a 3-edge dag" is WRONG/OVERSTATED — it is 4 of 8 subsets**; the
reviewer widened it to all 8 and got 28/28, so the property holds and only the self-assessment is inaccurate.
N1's monotonicity ARGUMENT is SOUND, and check 28's control genuinely fires.

════ THE RUBRIC ════
C1 PASS (both r3 failures discharged) · C1-a PASS · C2 PASS · C2-a PASS · **C3 PASS on the statement, FAIL on
the licence granted to the remedy** · **C4 PASS on the design, PARTIAL on the harness** (two design-level
unnamed kills measured) · C5 PASS — 20+ coordinates with existence controls, ★ including `view.nix:22-32`
position-blindness which the spec carried UNVERIFIED and the reviewer VERIFIED · **C6 FAIL** — the input that
violates the pairing invariant gives a SILENT WRONG VALUE · **C7 FAIL** — the guard-inside-compose IS a
construction, but the route-constructor enforcement, the five-key pin and the declIndex pin are HAND-MAINTAINED
REPLICAS, and structural-feeds.nix does not close as specified · C7-a PASS · C7-b PASS (READ, carried) ·
C8 PASS — corpus overclaim withdrawn, GUARD scope stated, four successors named, depth ≥3 floor ·
**C9 THEORY PASS, MECHANISM PASS** (core and prose now implement the SAME mechanism — r3's decisive fail is
CLOSED), **ARGUMENT PARTIAL** (three overstatements refuted) · C9-a PASS.

FAIL-OPENS: (1) `(emissions, dag, index)` unpaired ⇒ silent wrong payload · (2) replica drift on route
signature / five-key record / declIndex, with nothing observing divergence · (3) structural-feeds propagation
to 6 unnamed sibling feeds · (4) type/coercion aborts kill the run unnamed from ordinary design edits ·
(5) outputsAt ignoring its argument, carried. ★ The ones r4 GENUINELY CLOSED and the reviewer verified:
absent-declIndex⇒everywhere is a mustGet abort; `or identity` is gone; a disagreeing fleet has no dag; the
origin never rides the route record.

════ SIX REVIEWER HYPOTHESES REFUTED ════
1 "declare.pipe.route is a den-hoag wrapper so a site IS addable" — REFUTED, it is `inherit (pipe) route`;
**B2's premise is STRONGER than the r3 probe showed.** 2 "the fixture's closed pattern prevents drift" —
REFUTED by construction. 3 "siteOfName's partiality is still load-bearing" — REFUTED, widening it gives 28/28
because the design correctly moved the filter off it. 4 "the 11-name list is wrong" — REFUTED, independent
extraction reproduces it exactly. 5 "widening monotonicity to all 8 breaks it" — REFUTED. ★ 6 **the
reviewer's FIRST route probe was a DEAD INSTRUMENT — both arms EXIT 1 on a missing `prelude` formal — caught
and rebuilt through gen-pipe/default.nix BEFORE concluding.**

════ COVERAGE ════
EXECUTED: hash/rev re-derivation; anchor drift with a cat-file control pair; the core; the real gen-pipe route
probe with control and tryEval arm; declare.pipe.route provenance; the origin-path sweep; 14 mutants plus a
fail-open probe, all md5-distinct, exits read direct; independent free-variable extraction with per-region
firing controls; the let-boundary and the 4-outer/7-inner split; the prePass↔indexFeed cycle; O1 with a
firing control; 20+ coordinate spot-checks; view.nix position-blindness.
READ ONLY: evaluate.nix's other five operators; v1 assemble-pipes semantics; §4's corpus elimination; §5's
cost tables; the vyn residual; the sub-term redundancy argument.
NOT DONE: suite not run; **no corpus host built**; TRANSITIVE quirkDag-freedom of the 7 sibling feeds NOT
computed; lib/compat/** unaudited beyond cited files; §9(1)'s non-empty-seed spike untouched.

### 14 — 2026-07-29T14:48:23 · Jason Bowman

★★ OPS REPRESENTATION r5 AUTHORED — THE CRITICAL PATH. All three blocking and both non-blocking discharged.
Re-derived by the orchestrator: .md 838f3aabf72e4b10d36c46a41af648be / 1768 (was 1493); .core.nix
ee6e3771f461dc22011306990eac2cfc / 1627 (was 1417). Core "core: 31/31" EXIT 0.

════ ★★★ 1. THE PAIRING — DISCHARGED BY CONSTRUCTION. composeOf RETURNS THE PROJECTOR ════
`composeOf { emissions, quirkOps }` now returns `{ dag; index; project; }` where
`project = projectorOf checked theDag theIndex` — **built INSIDE the compose from the same `checked`
emissions the dag was composed from** — and `projectorOf` is a **PRIVATE let binding** (in den-hoag: inside
concern-quirks.nix, NOT a member of the returned attrset).
⇒ ★★★ **A CALLER CANNOT PASS A SECOND EMISSIONS LIST BECAUSE NO MEMBER OF THE SURFACE TAKES ONE.**
Orchestrator-verified at source: core:382 comments "no emissions parameter on the returned surface, and
projectorOf below is a private binding"; :535 is `project = projectorOf checked theDag theIndex`.
Measured by the author: `attrNames (composeOf {…})` = exactly `[ baseNames dag index project ]`, and
`project.at`'s only argument is a position.
★★ **MUT-EXPORT — r4's surface restored, putting `projector = projectorOf` back on the record — IS KILLED BY
NAME** by `compose-pairs-the-projector-with-its-own-emissions`. **That mutant carries the pairing's content.**
★ AND THE GATE'S PROBE IS NOW SHIPPED AS A CHECK: reproduced first-hand BEFORE editing
(`{ aborted = false; honest_owner = "a"; projected_owner = "IMPOSTOR"; silently_wrong = true; }`, exit 0) and
shipped as check 26 with TWO ARMS — the unpaired call succeeds with the impostor payload (**so it is a silent
wrong value, not an abort read as one**) and the paired surface at the same node gives the honest one.
RESIDUAL NAMED ON THE SAME TERMS AS outputsAt's: a caller holding dag/index can still write its own
projector — but that requires **visibly reimplementing the payload table, fired-index and slot-index, not
mis-assembling a pair.** The spec says the ACCIDENTAL mismatch is no longer expressible, and no more.
**§754 FIXED**: it now states r4's sentence was FALSE AS WRITTEN, names the in-file exploit, gives the true r4
statement, and says the strong form becomes true **for a construction reason** under the pairing. ★ And it
states that the two pipe.run sites may still disagree WITH EACH OTHER (the DRIFT NOTE, a separate obligation)
but **neither can be internally wrong.**

════ 2. WITHDRAWN, NOT MADE REAL ════
New §7 subsection "WHAT MAKES THAT TRUE IS DELETION, NOT A CHECK". The mechanism half is retained AND
CREDITED (closed pattern; declare.pipe.route = inherit (pipe) route, a direct re-export; the quirkOps arm
supplying {site = null;} unconditionally). Then: the core has ZERO imports, its `route` is a hand-written
replica, **both mutants survive** ⇒ "B2 is discharged by DELETION, not by a check", and the enforcement would
have been a repair someone keeps in sync.
★ **TRANSCRIPTIONS SAID PLAINLY IN FOUR PLACES**: check 7 asserts declIndex on edges **composeOf itself
writes**; check 27 pins a **hand-transcribed** five-key list; the route signature is a replica. **Neither can
observe compose.nix drift.** ★ The instrument that CAN is the §6 den-hoag fixture calling real pipe.compose —
now given as one more reason **that fixture is a PRECONDITION, not a follow-up.**

════ 3. TWO FILES, AND THE OBLIGATION IS SEVEN ════
The cycle verified directly: prePass:1039 uses indexFeed at :1046/:1053; indexFeed:1401 ← policyKindNames:1400
← denMeta:942; entryNodeIndex:1197 uses prePass at :1204; linkTarget:1215 is a one-line alias over it.
★ SPLIT, WITH THE LAYERING **FORCED, NOT CHOSEN**:
· `lib/policy-index.nix` { concernPolicies, denMeta, policiesRules } → { policyKindNames, indexFeed,
  policiesIndex } — 3 args. **prePass STAYS in default.nix and consumes the indexFeed it exports.**
· `lib/structural-feeds.nix` { prelude, fleet, theFleet, cellFamilies, ent, prePass, mintedRootId,
  rootScopeKinds } → { fleetChildren, linkTarget } — 8 args, **prePass among them, and now prePass is built
  from nothing this file mints.**
3 + 8 = the same 11, **two acyclic surfaces, quirkDag in neither.**
★★ **DIRECTIONAL CONTROL, SAME RUN**: policiesRules's body has **0** prePass; prePass's body has **2**
indexFeed — **the chain runs one way, which is WHY the split falls exactly there.** That is a measured reason
for a design choice, not a preference.
PROPAGATION OVER ALL SEVEN: one recursive let = mkDen's body :406 → in :2504 in a 2,844-line file. FOUR are
outer/by-construction (prelude the file formal, fleet:94, concernPolicies:186, mintedRootId:324-329 — in the
OUTER let, invisible to mkDen's body). **SEVEN are siblings of quirkDag:1494, tabled BY NAME AND LINE**:
denMeta:942 · ent:943 · prePass:1039 · rootScopeKinds:1079 · cellFamilies:1087 · theFleet:1109 ·
policiesRules:1390 — "every one the identical hazard", with policiesRules called out as the one carrying it
substantively. **Transitive closure NOT computed — stated as a limit and filed as §9 item 5.**

════ ★★ 4. THE BATTERY — 29 MUTANTS, 30 md5-DISTINCT DIGESTS, EXITS READ FROM THE PROCESS ════
19 named kills / 6 survivors / 4 unnamed kills.
★★★ **MUT-R2 — THE FULL r3 SHAPE (required `site`, supplied at all four call sites, originOfDecl reverted to
read it off the route record) — SURVIVES, exit 0, "core: 31/31". NOTHING DISCRIMINATES IT.** MUT-R1 likewise.
**Both are TABLED IN §7 AS THE REFUTATION** rather than quietly dropped — which is the correct discharge of
condition 2: the claim was withdrawn, and the mutant proving it must be withdrawn is documented.
NEW NAMED KILLS: MUT-EXPORT, MUT-FROMFIX, MUT-PSET.
★ **MUT-UNPAIR SURVIVES AND IS REPORTED AS INFORMATIVE RATHER THAN HIDDEN**: `project` from raw emissions
rather than `checked` differs only in whether the guard has already thrown, and composeOf throws on that arm
regardless. **The pairing's content is the ABSENT PARAMETER, which MUT-EXPORT kills.**
FOUR UNNAMED KILLS WITH TEXTS VERBATIM IN THE SPEC: MUT-AT (elemAt OOR), **MUT-ALLGET (`attribute '"0"'
missing`)**, **MUT-NODERIVE (`expected a list but found a set`)**, **MUT-NOBASE (`expected a string but found
null`)**.

════ 5. BOTH NON-BLOCKING DISCHARGED ════
★ The core header and Record 2 now enumerate **SIX** classes and state **ONLY THREE ARE CONVERTIBLE** —
attribute-missing / head [] / elemAt-OOR are converted at the sites where the three forms are used, while
**TYPE and COERCION ARE NOT CONVERTIBLE AT ALL**, tabled with the two ordinary design edits that produce them
plus MUT-ALLGET as a third absent from r4's battery. **The header no longer claims the class is removed.**
★ `mustHead` **recorded at its definition and in Record 2 as REFUTED AS LOAD-BEARING** — reverting all ~15
sites survives at 31/31, so **mustAt ALONE was what the r3 gate's input needed and B4(ii) stands at 1 of ~22
guarded sites.** Retained as defence-in-depth, **described as such and not counted as coverage.** ★ Added:
after the pairing even mustAt's site is unreachable from the composed surface — the two checks that still
exercise it reach the PRIVATE builder deliberately.
★★ **N2's FOURTH ITEM ALSO CLOSED BY CONSTRUCTION**: compat/pipe.nix binds ONE variable `dag` (:336) and uses
it as `derived = dag` (:352), `from = dag` in every `as` route (:344) and every `to` intent (:359) — **literal
identity, STRONGER than channel's two-uses-of-one-string.** New check 4 with two in-check controls;
MUT-FROMFIX kills it.
Monotonicity: powerset **8 of 8** with `length subsets == 8` asserted and MUT-PSET killing a narrowing; r4's
"exhaustive" self-assessment corrected to 4-of-8 in the appendix.

════ ★★ THE ORCHESTRATOR'S VACUOUS-CONTROL WARNING, ANSWERED WITH EVIDENCE NOT ASSURANCE ════
**NO FINDING RESTS ON A REV COMPARISON** — every measurement was taken on the working tree directly. ★ The one
rev comparison is the ANCHOR CHECK, **where an EMPTY diff IS the intended finding — and its predicate is shown
to FIRE in the same run**: the unscoped `git diff --name-only` returns `.beads/beads.jsonl`, so the instrument
DID report a changed file, just none under lib/ ci/ parity/. **The emptiness is SCOPE, not a dead instrument.**
The `cat-file -e` pair (exit 0 / exit 128) separately rules out a mistyped path. Both controls are recorded in
the spec.

════ COVERAGE ════
FIRST-HAND THIS REVISION: both pre-edit hashes; the anchor diff and its control pair; the mkDen let boundary
and the 7/4 split by name and line; the prePass↔indexFeed cycle with its directional control; entryNodeIndex's
prePass read; compat/pipe.nix's single `dag`; the unpaired-projector probe; the core; the returned key set;
the powerset; **the 29-mutant battery with every named kill READ FROM THE ABORT TEXT rather than inferred.**
★ RELAYED AND NOT RE-RUN, **labelled as the orchestrator's in the spec**: the gen-pipe probes and view.nix
position-blindness.
NOT DONE: suite not run; **no corpus host built**; transitive quirkDag-freedom of the seven NOT computed;
lib/compat/** unaudited beyond cited files; §9(1)'s non-empty-seed spike untouched; §4's corpus elimination
not re-derived since r2; §5's cost tables and §6's reproduction carried, not re-run.

⇒ NOT YET GATE-REVIEWED. Its r5 gate is the next dispatch on this bead.

### 15 — 2026-07-29T15:06:54 · Jason Bowman

★★ GATE REVIEW r5 — ops representation. **VERDICT: VALIDATED-WITH-CONDITIONS (2 blocking, 3 non-blocking).**
Thesis NOT re-litigated. Anchors re-derived **at start AND end**; core 31/31 EXIT 0. ★ den-hoag HEAD moved
mid-review and every citation was re-resolved at the new HEAD with a firing control.
**7 mutants + 3 core-derived probes + a 17-arm class battery, all md5-distinct.**

════ ★★★ B1 — THE PAIRING IS REAL AS WRITTEN, BUT ITS CHECK IS ONE LEVEL DEEP ════
CONFIRMED, EXECUTED, four fixtures: `attrNames (composeOf {…})` = [baseNames dag index project];
`attrNames okC.project` = [at]; `functionArgs okC.project.at` = {} and `project.at "user:a"` returns a SET,
so **one argument, a position**; `functionArgs composeOf` shows **no emissions seam**. MUT-EXPORT reproduced
independently → EXIT 1, killed by name. **The author's report is accurate.**
★★ **BUT THE CHECK'S CONTENT IS `attrNames okC` — A ONE-LEVEL KEY-LIST PIN, AND TWO MUTANTS RESTORE THE FULL
r4 DEFECT THROUGH THE SURFACE AND SWEEP 31/31:**
· **MUT-HIDE** (`index = theIndex // { projector = projectorOf; }`) → 31/31 EXIT 0, with non-vacuity proved in
  the same run: surface keys still exactly the four, and **reached PURELY THROUGH THE RETURNED SURFACE** —
  `honest.index.projector [… "IMPOSTOR"] honest.dag honest.index` gives value "IMPOSTOR" against honest "a".
  **The r4 silent wrong value, back, unseen.**
· **MUT-VIA** (`project = … // { via = em: projectorOf em theDag theIndex; }`) → 31/31 EXIT 0. **Check 25 pins
  `attrNames okC`, never `attrNames okC.project`.**
★★★ **AND THE MISPAIRING IS STILL EXPRESSIBLE WITHOUT REIMPLEMENTING ANYTHING.** `dag` and `project` remain
separable fields: `{ dag = honest.dag; project = impostor.project; }` from two composes gives
`mixed_aborted = false; mixed_owner = "IMPOSTOR"; silently_wrong = true`. **TWO ATTRIBUTE READS — not
"visibly reimplementing the payload table, fired-index and slot-index".** Worse: the two dags are equal on
attrNames channels AND on edges, **so check 25's own agreement arm PASSES on the mispaired pair.**
⇒ §240's "the ACCIDENTAL mismatch is no longer expressible" is FALSE as an expressibility claim — **the seam
moved from (emissions,dag) to (dag,project).**
★★ **HONEST BOUNDING, AND WHY THIS IS NOT A C6 FAIL:** den-hoag has **ONE** pipe.compose
(concern-quirks.nix:55) and **ONE** quirkDag (default.nix:1494), verified with a firing control. **No second
compose exists to mix with.** A model-level expressibility finding, not a live path — **it goes live the
moment a second compose exists.** ★ The reviewer applied the standing den-hoag-4kh.6 ruling correctly and
typed this as **STATED SCOPE, not construction.**

════ ★★★ B2 — TWO STATED FACTS ARE FALSE, AND BOTH ARE LOAD-BEARING LICENCES ════
★★★ **(a) "Under the pairing the two pipe.run sites each project the dag composed from THEIR OWN emissions"
IS REFUTED BY THE CITED COORDINATES.** ORCHESTRATOR-VERIFIED AT SOURCE: `lib/attributes/collections.nix:248`
is `dag = quirkDag;` and `lib/default.nix:1861` is `dag = quirkDag;` — **THE SAME SINGLE LET-BINDING.** The
two sites differ in the **TRAVERSAL ADAPTER** (`result = self` vs `result = structural.eval`), **NOT in
emissions.** One emissions list, one dag, one project. ★ **And the spec contradicts itself 50 lines later**,
where :309 specifies `dag = quirkDag.project.at pos` at BOTH sites.
⇒ ★★★ **THIS IS THE LICENCE FOR CONDITION 1's REMEDY, AND IT IS MINE.** The r4 gate originated it and **I
relayed it verbatim into the r5 brief as "architectural, not hypothetical"** without measuring it. **THE
REMEDY IS STILL CORRECT AND FREE; THE ARGUMENT FOR ITS NECESSITY IS NOT.** r4 and r5 repeat it identically.
★★ **(b) "TYPE and COERCION ARE NOT CONVERTIBLE AT ALL" — REFUTED BY EXECUTION, one run, control firing.**
`mustList = what: x: if isList x then x else throw …` in front of `filter`, and `mustStr` on the listToAttrs
name, both give `{ success = false; }` EXIT 0 alongside the `tryEval (throw "x")` control, while the raw arms
still EXIT 1. ★ **`mustList "…" xs` wraps the argument EXACTLY AS `mustHead` DOES — it does not "duplicate
the expression".** ⇒ **the design declares a residual class unclosable when the file's OWN discipline closes
it at the same cost**, licensing two uncatchable classes left unnamed **by mis-classification, not by
necessity.**

════ NON-BLOCKING ════
★★ **N1 — MUT-R2 SURVIVES, CONFIRMED, BUT "NOTHING DISCRIMINATES IT" IS TOO STRONG.** Reconstructed from
scratch — ★ and at **FIVE** call sites, not four: :848 :878 :891 :967 **and :1154 inside check 4, which r5
added and the r4 "four call sites" wording no longer covers** → 31/31 EXIT 0.
★★ **BUT THE REVIEWER'S OWN NON-VACUITY CONTROL REFUTES THE GLOSS: MUT-R2-POISON** (same mutant, the
quirkAdapter's record site null → "user:BOGUS") → **EXIT 1, KILLED BY NAME BY TWO CHECKS.** ⇒ **the checks DO
observe the origin VALUES; MUT-R2 is an EQUIVALENT MUTANT on these fixtures, not an untested path.** The
conclusion ("discharged by deletion, not by a check") stands for the ENFORCEMENT claim — **but the gloss
under-claims the harness in a way that would license deleting those two checks.**
★ **N2 — MUT-UNPAIR's REASONING IS SOUND, VERIFIED NOT ACCEPTED.** On fleetBad, BOTH the shipped core and
MUT-UNPAIR throw on project AND on dag — the guard is enforced through theDag, which the projector forces.
**A true equivalent mutant, honestly reported, no hidden gap.**
★★ **N3 — THE ENUMERATION IS AT LEAST NINE, NOT SIX, AND THE DESIGN'S OWN DELIVERABLES PRODUCE TWO OF THE
EXTRAS.** 17-arm battery with two firing controls. The spec's six confirmed; **three more, all EXIT 1**:
· `attempt to call something which is not a function` — **produced by THIS DESIGN'S OWN ARITY CHANGE**
  (`projector e d i` → `project.at pos`); the reviewer hit it accidentally.
· `called without required argument` — **produced by §3's OWN DELIVERABLE**, two new files with 3 and 8
  REQUIRED formals.
· infinite recursion — **the manifestation of §9.5's own stated 7-sibling residual**, unnamed.

════ WHAT THE REVIEWER VERIFIED AND FOUND CORRECT ════
★ **§3's SPLIT IS FORCED, with a FIRING directional control**: prePass's body has indexFeed at :1046 and
:1053 (count 2); policiesRules' body has prePass count **0** with the control `concernPolicies` = 2 **in the
same ten lines**, so the zero is a real absence.
★ **3 + 8 = the same 11 with quirkDag in neither — VERIFIED BY INDEPENDENT FREE-VARIABLE EXTRACTION** of all
four moved regions.
★ **THE SEVEN-SIBLING TABLE IS EXACT BY NAME AND LINE**, by 6-space-indent extraction over the let body; the
four outer confirmed including mintedRootId via `inherit (buildRootsLib)`.
★ **§9.5's DIRECT MEASUREMENT IS CLEAN WITH TWO POSITIVE CONTROLS ON THE SAME PREDICATE IN THE SAME RUN**
(idToName count 3, quirkDag's own body count 2). Transitive closure correctly declared NOT computed.
★ **N2-fourth CLOSED BY CONSTRUCTION — VERIFIED**: `grep -w dag` gives one binding at :336 and literal uses at
:344/:352/:359. MUT-FROMFIX built independently → EXIT 1, killed by name.
★★ **THE ANCHOR-CONTROL REASONING HOLDS — BUT THE OFFERED CONTROL WAS ONE PREDICATE SHORT**, witnessing "the
diff command emits" rather than "the SCOPED lib/ diff would emit if lib/ changed", **and the whole 11-commit
range is chore(beads) only — exactly the byte-identical-input shape.** ★ **THE REVIEWER SUPPLIED THE MISSING
CONTROL**: a diff over a known lib/-touching commit returns 5 files. **The predicate fires; the emptiness IS
scope.**

════ THE RUBRIC ════
C1 PASS (refutable, and two parts refuted) · C1-a PASS · **C2 PASS — the guard is total through theDag,
measured on both arms** · C2-a PASS · **C3 PARTIAL — two licences rest on false premises (B2a, B2b)** ·
**C4 PARTIAL — the uncatchable enumeration is presented CLOSED at six and is short by ≥3, two produced by
this design's own deliverables** · C5 PASS, every coordinate verified at two revs with a cat-file control
pair; ★ one spelling slip (`attributes/collections.nix` exits 128; the real path is
`lib/attributes/collections.nix`) · **C6 PASS-WITH-CONDITION — under the 4kh.6 ruling this is STATED SCOPE,
not construction: the shipped design gives no wrong value on any path it traverses (one compose), and the
(dag,project) seam needs a second compose that does not exist** · **C7 PASS — the enforcement claim is
genuinely withdrawn and the transcriptions labelled in four places; the pairing is a real construction.
★ Residual: its ENFORCEMENT is a lexical depth-1 pin — a repair — and is NOT labelled as one, unlike checks
7 and 27** · C7-a PASS · C7-b READ · C8 PASS · **C9 THEORY PASS, MECHANISM PASS, ARGUMENT PARTIAL** (three
statements refuted) · C9-a PASS.
FAIL-OPENS: (1) the pairing enforced at depth 1 only · (2) (dag,project) mispairable across composes, silent,
**not live at one compose** · (3) type/coercion left unconverted on a false impossibility · (4) ≥3
uncatchable classes outside the enumeration · (5) `targeted` unprojected, carried · (6) transitive
quirkDag-freedom uncomputed, stated.

════ FIVE REVIEWER HYPOTHESES REFUTED ════
"project.at is curried and takes emissions" — REFUTED, returns a set immediately. "MUT-UNPAIR hides a gap" —
REFUTED. "The 11 don't reconcile as 3+8" — REFUTED by independent extraction. ★ **"MUT-R2 survives because
the origin path is unexercised" — REFUTED BY THE REVIEWER'S OWN POISON CONTROL**, two checks kill it by name.
"The anchor's emptiness is a dead instrument" — REFUTED, **and it built the stronger control that confirms
it.**

════ COVERAGE ════
EXECUTED: both hashes at start AND end; HEAD-drift re-check with a firing control; the core; the returned key
set on four fixtures; functionArgs on composeOf and project.at; 7 md5-distinct mutants with exits read from
the process; the cross-compose mispairing probe; the MUT-HIDE surface-reachability probe; the 17-arm
uncatchable battery with two firing controls; the convertibility refutation with control; independent
free-variable extraction of all four moved regions; the sibling extraction and 7/4 split; the directional
control with its firing counter-token; §9.5's absence with two positive controls; the anchor diffs plus the
stronger control; concern-quirks.nix's let/return boundary.
READ ONLY: §4's corpus elimination, §5's cost tables, §6's witness, §8's codomain trace, **the gen-pipe probes
(relayed by the author, NOT re-run)**, view.nix position-blindness.
NOT DONE: suite not run; **no corpus host built**; transitive closure over the seven not computed;
lib/compat/** unaudited beyond pipe.nix; §9.1's non-empty-seed spike untouched.

### 16 — 2026-07-29T15:50:11 · Jason Bowman

★★★ OPS REPRESENTATION r6 AUTHORED. Both blocking and all three non-blocking discharged — **AND WHILE
DISCHARGING CONDITION 1 IT FOUND A DEFECT BIGGER THAN EITHER CONDITION.** Re-derived: .md
c8bf12fbcf714a3563a89d2ab5e3c848 / 2106 · .core.nix 21d34533c595501c0edce83c6f09d97b / 1932; core 34/34 EXIT 0.

════ ★★★ THE NEW FINDING — r5's PROJECTION PUT THE PAYLOAD ON THE WRONG KEY ════
**GEN-PIPE OPERATORS DO NOT SHARE A PAYLOAD KEY.** ORCHESTRATOR-VERIFIED AT SOURCE, operators.nix:
  map :86 `f` · **filter :98 `p`** · **fold :108 / scan :119 `f init`** · over :140 `f` ·
  **join :150 `combine`**
read at evaluate.nix :276/:278/:164/:186/:210/:257, with a firing negative control (`d.NOSUCHKEY` = 0 hits).
★★★ **r5 WROTE `__derive // { f = payloadFor nm; }` UNCONDITIONALLY.** So on a `filter` channel it **ADDED an
`f` NOTHING READS and LEFT `p` AS THE FIRST EMITTER'S PREDICATE.**
MEASURED ON THE SHIPPED r5 CORE with a ctx-dependent predicate, two nodes at one site: at `host:b`,
`p "host:a" = true`, `p "host:b" = false`, keys `[f inputs op p]`, **exit 0, NO ABORT.** r6 gives
`p "host:b" = true`, keys `[inputs op p]`.
★★ **CONTROL, SAME RUN: at `host:a` BOTH revisions are correct** ⇒ the failure is attributable to **the KEY**,
not to the projection failing everywhere.
★★★ **AND IT IS LIVE.** ORCHESTRATOR-VERIFIED: den-hoag emits `declare.pipe.filter` at compat/pipe.nix:95 —
**predicate = `stage.fn`, the v1 policy body's own closure** — and `declare.pipe.fold` at :115 (positive
control: 7 `declare.pipe` calls in that file).
⇒ ★★★ **THIS IS MUT-F, ALIVE, ON EVERY ARM THAT IS NOT map/over. IT SURVIVED FIVE REVISIONS AND TWO GATES
BECAUSE EVERY r5 FIXTURE CARRIED ITS PAYLOAD UNDER `f`.** The fixture reproduced the blind spot.
FIX = §1's OWN RULE APPLIED ONE LEVEL DOWN: `__derive` = SHAPE `{op,inputs}` ⊎ PAYLOAD (everything else),
**TOTAL, written as a PARTITION so a new gen-pipe payload key needs no edit.**
★ AND A LAZINESS CONSTRAINT MEASURED, NOT ASSUMED: `// payloadFor nm` **FORCES the right operand** and turns
I2's lazy abort eager — it fails `projection-preserves-modelled-compose-guards`.

════ ★★★ AND A SECOND COPY OF THAT PAYLOAD WAS EXPORTED ════
The seed is the first emitter's pipeOp **with closures included**, so the composed dag **carries one node's
payload at every position.** MEASURED on r5: `dag.channels.<map>.__derive.f` reads `"a"` EVERYWHERE and
`user:b`'s payload is nowhere — **readable on `default.nix:2609`'s exported `quirkDag`.** r6 seals every
payload key with a NAMED throw, total over `payloadOf` so `p`/`init`/`combine` are covered; SHAPE keys are
untouched so idToName and derivedBaseNames still work.

════ CONDITION 1 — BOTH, AND THE LABEL ════
**DEEPER KEY SETS PINNED** (`attrNames okC.project == ["at"]`, `attrNames okC.index == [originOfDecl
siteOfName]`); MUT-HIDE and MUT-VIA reproduced surviving 31/31 on r5 and are now **KILLED BY NAME.**
★★ **AND THE LIMIT STATED PLAINLY IN THE CORE HEADER AND §1: a key-set pin at ANY depth is a LEXICAL REPAIR,
the same class as checks 7/30 which r5 correctly labelled. "PINNING DEEPER DOES NOT CONVERT A REPAIR INTO A
CONSTRUCTION."**
★★★ (dag,project) REPRODUCED — the mixed record gives "IMPOSTOR" and **the two dags agree on attrNames
channels AND on edges so the agreement arm PASSES.** §240's expressibility claim WITHDRAWN. ★ **WHAT CLOSES IT
IS THE SEAL, NOT A PIN**: the payload existed TWICE, and with one copy a pair cannot disagree. Measured both
ways. ★ RESIDUAL MEASURED AND STATED: mispairing across DIFFERENT fleets still assembles, but the key sets
then visibly differ — **the SILENT case is the one gone.**

════ CONDITION 2 — BOTH REFUTATIONS TAKEN ════
(a) **VERIFIED AT SOURCE BY THE AUTHOR**: `grep -n 'dag = quirkDag'` gives exactly two hits, collections.nix:248
and default.nix:1861, the same `quirkDag:1494`, differing only in `result = self` vs `result =
structural.eval`. **The claim is WITHDRAWN in §1 and in the two-sites table (new column) and relicensed on the
`{outputs;at;}` symmetry plus the model-level seam.** The self-contradiction at :309 is named.
(b) **CONVERTED, NOT RESTATED.** `mustList`/`mustStr` shipped and applied, with a two-sided control in the same
run. **MUT-NODERIVE and MUT-NOBASE go from r5 UNNAMED to r6 NAMED, killing 10 and 6 checks.**

════ NON-BLOCKING ════
N1 TAKEN — five call sites with a firing negative control; **MUT-R2 survives 34/34 while MUT-R2-POISON is
KILLED BY NAME by two checks** ⇒ tabled as an **EQUIVALENT MUTANT on these fixtures, not an untested path**,
with the gloss corrected **and the reason it matters stated** (it would license deleting those two checks).
N2 RECORDED, credited to the gate. N3 TAKEN **AND IT IS NINE**, all measured raw with two firing controls.
★ `assert` IS catchable — recorded. ★★ **And convertibility was MEASURED rather than asserted: EIGHT of nine
convert**, each two-sided; three convert at the CALL SITE and are classified as **application-seam classes the
core does not own**; **(9) infinite recursion alone does not — and it IS §9(1)'s open item**, which is the
honest framing rather than a list.
★ COORDINATE SLIP FIXED (six occurrences; three left as verbatim r2 quotes). ★★ ANCHOR CONTROL — **the
STRONGER FORM ADOPTED**: the scoped diff is empty AND **the same scoped predicate over a known lib/-touching
commit returns 5 files.**
★ AND A REPAIR IN r5's OWN CORE: numeric check cross-references — **two were ALREADY STALE at r5** — all
replaced by NAMES.

════ BATTERY — 36 MUTANTS, 37 md5-DISTINCT DIGESTS ════
**26 named kills / 8 survivors / 2 unnamed.** Unnamed fell 4 → 2, **and the 2 remaining are guard reversions,
the one case where unnamed is correct.**
★★ **Every substitution is exact-match WITH AN ABORT ON MISS — which caught two of the author's own first-pass
mutants written against DEAD ANCHORS, which would otherwise have been reported as SURVIVORS.**
★★ And the spec says 26/36 is **NOT a quality score**: four survivors are *supposed* to survive, and **MUT-R2
was only distinguishable from an untested path by its poison control.**

════ COVERAGE — HONEST ════
NOT DONE: suite not run; **no corpus host built**; §4's elimination not re-derived since r2; **§5's cost
tables now PREDATE the `__derive` split, which changes the payload table from one slot to one attrset per
chain position — NOT re-measured, stated as a limit**; §2's O1/O2 and the seven-sibling work carried from r5
and its gate; **the gen-pipe route probes are still the r4 gate's, RELAYED**; §1's six-operator POSITION-
blindness still carried from r2 — ★ **the author re-read those operators for their payload KEYS, not for
position, and the spec says exactly that.**
★★ **NEW STATED LIMIT THAT BINDS HARDER THAN THE OLD ONES: §1's payload-key table is a FRESH TRANSCRIPTION. A
gen-pipe operator that renamed its payload key would silently reintroduce the defect just removed.** Filed as
§9 item 7 — and **§6's fixture now REQUIRES a ctx-dependent `pipe.filter` arm (plus `fold` for `init`),
because without it the fixture reproduces r5's exact blind spot.**
§9 gains item 6 — (dag,project) as **STATED SCOPE, not construction**, with a "re-open before adding a second
compose" trigger.

⇒ NOT YET GATE-REVIEWED. Its r6 gate is the next dispatch on this bead.

### 17 — 2026-07-29T16:09:08 · Jason Bowman

★★ GATE REVIEW r6 — ops representation. **VERDICT: VALIDATED-WITH-CONDITIONS (2 blocking, 4 non-blocking).**
Thesis NOT re-litigated. Anchors re-derived at START and END, unchanged; baseline 34/34 EXIT 0 read from the
process. **8 probes, 8/8 md5-distinct**, every substitution exact-match with abort-on-miss — ★ **and it fired
once, on a dead anchor, caught rather than reported as a result.**

════ ★★★ B1 BLOCKING — THE PARTITION IS NOT TOTAL, AND THE COUNTEREXAMPLE IS DEN-HOAG'S OWN ════
The brief asked for a gen-pipe key that is neither shape nor payload, or a SHAPE key the partition calls
payload. **It is the second, it is NOT gen-pipe's, and it is den-hoag's own: `__derive.wholeList`.**
ORCHESTRATOR-VERIFIED AT SOURCE:
· WRITTEN at `lib/compat/pipe.nix:139-141` — the v1 `for` arm bolts `wholeList = true` onto a `map` node.
· ★★★ READ at `lib/default.nix:1446+` (`honorWholeList`), which **REWRITES `d.op` AND `d.__derive.op` FROM
  `map` TO `over`**, applied at `:1484` via `builtins.map honorWholeList (…)` — **AFTER the per-site dedup
  picks one pipeOp.** (Positive control: 4 hits in pipe.nix, 3 in default.nix.)
  ⇒ **IT IS NOT AN INERT MARKER. IT DECIDES `op`, THE CANONICAL SHAPE KEY**, and :1442 says so.
· `deriveShapeKeys = [ "op" "inputs" ]` ⇒ `payloadOf` classifies it **PAYLOAD**.
**EXECUTED, two nodes at one site, `for` vs `transform`, both directions**: `guardSeesIt = false`,
`shapeKeysEqual = true` — **`shapeDisagreement` IS BLIND**, with a firing control on `fleetBad` in the same
run. First emitter HAS the marker → the projected record at `host:b` carries a key whose value is
**`attribute 'wholeList' missing`** — **the core's OWN uncatchable class, lazy, detonating at the reader.**
First emitter LACKS it → **SILENTLY DROPPED.**
**EXECUTED END TO END** with `honorWholeList` transcribed verbatim onto `seedDecls`: **`opsA = [over over]`,
`opsB = [over map]`** ⇒ ★★★ **THE WHOLE SITE IS COMPOSED WITH THE FIRST EMITTER'S OPERATOR — a node that
declared `for` runs per-element `map`, or the reverse — and the composed NAME flips too.**
★★ **AND THE LICENCE IS FALSE — IT IS INVERTED.** §1 justifies the partition as "the same reason
`shape-key-is-total-over-emitted-fields` is a totality check rather than a field list". **That check FAILS
CLOSED** — an unclassified field is in neither list and the check FAILS. **The `__derive` partition FAILS
OPEN** — an unclassified key silently becomes payload.
⇒ ★★★ **r6 APPLIED §1's SHAPE/PAYLOAD RULE ONE LEVEL DOWN AND DID NOT APPLY §1's TOTALITY DISCIPLINE ONE
LEVEL DOWN.**
★ HOW IT WAS MISSED, MECHANICALLY: the appendix instrument greps
`declare\.pipe\.(map|filter|fold|scan|over|join)` — sound for "which operators den-hoag emits", **structurally
incapable of seeing a key added to `__derive` AFTER construction.** A sound predicate proving a different
proposition.
★★ **TYPED CONSTRUCTION UNDER den-hoag-4kh.6** — the path is the deliverable's own per-site dedup, and the
defect is **live today, not gated on a second compose**, so it cannot be carried as a stated limit.

════ ★★★ B2 BLOCKING — THE SEAL IS NOT TOTAL, AND "ONE COPY" IS REFUTED ON THE ARTEFACT ════
`sealPayload` seals `channels.<n>.__derive.<payload>` and **does not reach the same payload one hop down
through `__derive.inputs`.** EXECUTED: `inputsAreRecords = true`, **`innerReadable = true`** — the inner `.f`
is a **live callable closure** — while the same node reached as a first-class channel IS sealed, with a
two-sided control.
EXECUTED on a two-stage chain with a ctx-dependent NON-terminal stage and a mispaired record: `viaInputs` and
`viaProject` **DISAGREE**, while **`keySetsAgree = true` and `edgesAgree = true`** ⇒ **structurally
undetectable — r5's EXACT SHAPE, surviving r6's remedy one level down.**
⇒ §1's "the payload existed twice … a pair cannot disagree when there is only one of it" and §9(6)'s "there is
ONE copy" are **FALSE AS WRITTEN.** There are two; measured both ways.
★★ **THE HONEST BOUND, AND IT IS THE INTERESTING PART**: on a REAL dag the second copy does not exist —
**`compose.nix:141-143` rewrites `__derive.inputs` from RECORDS to NAMES.** So **the CONCLUSION probably holds
live; the ARGUMENT does not** — and **the spec never cites that rewrite** (0 hits in both files, with five
firing positive controls). ⇒ **The core's model actively CONTRADICTS the library here, so the file that
"measured both ways" cannot witness the fact its conclusion needs.** Same category r5 failed.

════ NON-BLOCKING ════
★★ **N1 — §9(7) NAMES A RISK THE MECHANISM CLOSED AND OMITS THE ONE IT HAS.** §9(7) calls the payload-key
transcription the hardest-binding limit. **REFUTED BY EXECUTION**: renaming `p` → `pred` leaves the projection
correct — **the partition reads the key set OFF THE RECORD**, so renames and new payload keys need no edit.
⇒ **The transcription risk survives IN THE PROSE TABLE ONLY**, and the mechanism's real residual — a new key
that is NOT payload — is unnamed **and already realized (B1). Both halves need reversing.**
★ **N2 — FIXTURES SPAN 3 OF 6 DERIVING OPERATORS, and the helper cannot express the rest**: it takes **exactly
one** payload key, so `fold`/`scan` (`f` AND `init`) are not constructible with it — **and den-hoag emits
`fold` LIVE.** The reviewer's hypothesis that multi-key payloads break was **REFUTED** (they project and seal
correctly), so it is a coverage gap, not a defect. ★★ **But the SHAPE is r5's again: r5's fixtures were
uniform in key NAME; r6's are uniform in key COUNT.**
★ **N3 — MODEL FIDELITY, UNPINNED BY ANY CHECK**: the core's `__derive.inputs` holds RECORDS where real
compose holds NAMES; and the core's `idxOf` indexes `derivedDecls` while `compose.nix:88-99` indexes `decls`,
**with the core's own comment contradicting its code.** `projection-preserves-the-dag-record` pins the five
top-level keys and neither of these. MINOR: `derivedBaseNames` is `:1509` at HEAD, cited `:1508`; and the
write-back re-evaluates `payloadFor nm` once per payload key (2x on `fold`) — a bounded constant.

════ WHAT WAS VERIFIED AND FOUND CORRECT ════
★ **§1's payload-key table is EXACT — every cell read at source** in operators.nix and evaluate.nix.
★ **MUT-R2 reconstructed independently (5 route sites) → SURVIVES 34/34; MUT-R2-POISON → EXIT 1, killed by
name by TWO checks. Equivalent mutant CONFIRMED; r6's tabling and corrected gloss are right.**
★ `assert` IS catchable, with a two-sided control. ★ Condition 2(a)'s withdrawal is correct — exactly two
`dag = quirkDag` hits, one binding, with a firing negative control; ONE compose.
★ **The seal does not break the cited readers** — idToName and derivedBaseNames read SHAPE only.
★★ **CONDITION 1's LABEL IS APPLIED HONESTLY TO ITS OWN PINS**: the spec states the deeper pins are the same
lexical repair as checks 7/30 and that "pinning deeper does not convert a repair into a construction", and
separates what IS a construction. **No credit taken that was not earned. C7 PASS.**
★ **§5's COST CLAIM SURVIVES the `__derive` split** — judged analytically, not re-measured: the split is
per-slot constant work on a term measured linear, and **the exponent, which is what the decision turns on, is
untouched.** The author's own framing is accurate.

════ THE RUBRIC ════
C1 PASS · C1-a PASS · **C2 FAIL — `shapeDisagreement` is not total over the emitted declaration; a live
discriminator sits outside its domain (B1, controls firing)** · **C2-a FAIL with C2** · **C3 FAIL — two false
licences: the INVERTED totality analogy, and "only one copy of the payload"** · **C4 FAIL — an unclassified
`__derive` key defaults to PAYLOAD (fails OPEN) where the design's other totality discipline fails CLOSED; and
§9(7) approximates in the wrong direction** · C5 PASS, every coordinate re-verified at HEAD with a firing
negative control, one one-line slip · **C6 FAIL — a silent wrong value measured on a LIVE path; typed
CONSTRUCTION under 4kh.6, so it cannot be carried as a stated limit** · **C7 PASS** · C7-a PASS · C7-b
PASS-with-note · C8 PASS · **C9 THEORY PASS · MECHANISM PARTIAL (correct for renames and multi-key, wrong for
a non-payload key) · ARGUMENT FAIL** · C9-a PASS.
FAIL-OPENS: (1) the partition defaults to payload — **realized by `wholeList`** · (2) `shapeKeyOf` blind to
every `__derive` discriminator but `op` · (3) the seal does not reach payload under `inputs`; real compose
erases it, **uncited** · (4) §9(7) inverted · (5) the core model diverges from compose.nix in two places,
unpinned · (6) fixtures 3 of 6 operators, 2-key payload inexpressible in the helper · (7) carried: no corpus
host, suite not run, transitive quirkDag-freedom uncomputed, §9(1) open.

════ ★ FOUR REVIEWER HYPOTHESES REFUTED ════
"Multi-key payloads break the projection" — REFUTED. ★ "A renamed payload key reintroduces the defect, as
§9(7) says" — **REFUTED, and the refutation IS the finding against §9(7).** "join/tee break originOfDecl or
chainOf live" — REFUTED as live: den-hoag emits neither. "The modelled cycleCheck's hasDerive throws on a real
dag" — REFUTED; it is `inp.name` that dies.

════ COVERAGE ════
EXECUTED: both hashes at start and end; the baseline; 8 md5-distinct probes with exits read from the process;
MUT-R2 and MUT-R2-POISON rebuilt from scratch; `assert` and attr-select-on-string with two-sided controls;
**every cell of §1's payload table at source**; compose.nix in full; den-hoag's declare.pipe census and the
`wholeList` census with firing controls; `honorWholeList` and `pipeChannelOps` at source; the quirkDag export;
a spec/core token census with five positive controls.
READ NOT RE-RUN: §4's elimination · §5's cost tables (judged analytically) · §6's witness · §8's codomain
trace · §2's seven-sibling work · **the gen-pipe route probes, still the r4 gate's.**
NOT DONE: suite not run · **no corpus host built** · no timing of the projection · lib/compat/** unaudited
beyond pipe.nix · transitive closure uncomputed · §9(1) untouched.

### 18 — 2026-07-29T16:11:53 · Jason Bowman

★★ LIVENESS CORRECTION AND A CORROBORATION, MEASURED BY THE ORCHESTRATOR AFTER THE r6 GATE.

════ THE GATE'S LIVENESS PHRASING IS IMPRECISE — CORRECTED ════
The r6 gate typed B1 (`__derive.wholeList`) as "live today, not gated on a second compose". **The second
clause is right; the first is not.** Measured:
· `pipeChannelOps = builtins.map honorWholeList (prelude.concatMap (p: pipeChainOf p.derived)
  (policiesRules.pipeOps or [ ]))` — **default.nix:1484, and there is NO per-site dedup in the shipped path.**
  No grouping, no first-wins pick; every pipeOp's chain is mapped independently.
⇒ **THE DEDUP B1's COUNTEREXAMPLE NEEDS IS THE DESIGN'S OWN.** The collision is **live the moment the per-site
dedup lands**, not before. ★ **This does not weaken B1 in any way** — it is still CONSTRUCTION, still on the
deliverable's own path, and the partition must still fail closed. It changes only how the spec should STATE
the liveness, and it means **B1 is NOT a present-tense tree defect and must not be filed as one.**

════ ★★★ AND THE TREE ALREADY DOCUMENTS THE HAZARD CLASS — FIFTEEN LINES FROM THE WRONG CLASSIFICATION ════
`lib/default.nix:1461-1470`, shipped, in the block immediately below `honorWholeList`:
  "gen-pipe's `mkDerived` names a derived channel `<input>.<op>` (**PREDICATE-BLIND**), so TWO policies
   deriving the SAME base+op would collide on one id and compose's first-wins byId dedup would **SILENTLY DROP
   THE LATER POLICY'S PREDICATE** — at EVERY DEPTH of a multi-stage chain (the shared prefix ids collide too)."
★★★ **THE COMMENT NAMES "PREDICATE" SPECIFICALLY — i.e. `filter`'s `p`, THE EXACT KEY r5 MIS-WROTE.** The r6
finding and this comment are **the same hazard class approached from opposite ends**: the comment from ID
COLLISION, r6 from PAYLOAD KEY.
★ AND THE COMMENT RECORDS THAT THE ID-COLLISION HALF IS **ALREADY SOLVED IN SHIPPED CODE** — the
disambiguation "is now routed through gen-pipe's declaration-`site` id", with compilePipe stamping a
per-declaration site on the flatten `over` root and id-stacking propagating it to every depth.

⇒ ★★★ **THE REUSE LESSON, AND IT IS THE ONE WORTH KEEPING: THE ANSWER WAS IN THE CODEBASE, IN A COMMENT
FIFTEEN LINES FROM THE FUNCTION WHOSE CLASSIFICATION WAS WRONG. FIVE REVISIONS AND TWO ADVERSARIAL GATES WENT
PAST IT.** This is the standing reuse-scan rule (inventory before building, scan to PRIMITIVE granularity)
applied to a hazard rather than a capability: **before designing a guard against a class, grep the tree for
the class — the people who hit it first may have written down what they did.**
★ It also strengthens the finding rather than diminishing it: **a defect the tree independently corroborates
is real, not an artefact of the fixtures** — which matters here, because the fixtures were exactly what hid it.

════ ONE UNMEASURED QUESTION HANDED TO r7 ════
The same comment says the site stamp "feeds the internal id ONLY, leaving the composed NAMES the natural
`<input>.<op>.<declIndex>`". ★ **But `honorWholeList` REWRITES `op` — so it changes the composed NAME, not
only the internal id.** Whether that interacts with the site-stamping guarantee is **NOT MEASURED by me** and
is handed to r7 as an open question rather than an assertion.

### 19 — 2026-07-29T16:54:47 · Jason Bowman

★★★ r7 SHIPPED AND HANDED BACK FOR THE GATE. FROZEN ARTEFACT, ANCHORS VERIFIED BY TWO SAMPLES SIX SECONDS APART, IDENTICAL, WITH mtimes STALE AGAINST THE READ:
  specs/2026-07-29-ops-representation.md        md5 64a68400b5bedfd8f69a8c3785d97434   2498 lines
  specs/2026-07-29-ops-representation.core.nix  md5 b2baa49aa7df75ff7c670ed15769821d   2701 lines
  in ~/Documents/papers/den-architecture, committed 3c89181. Core 42/42 EXIT 0, read directly from the process.
  Battery 9 mutants, 9/9 md5-distinct, 9/9 KILLED BY NAME. Suite at baseline 1919/1937 EXIT 1, den-hoag clean.
  Document re-anchored to den-hoag 79c8c63; scoped git diff over lib/ ci/ parity/ across 27bfc01..79c8c63 = 0
  bytes, firing control 67 files over e6c8edc.

BOTH r6 BLOCKING DISCHARGED.
  B1 — payloadOf is no longer removeAttrs. Two DECLARED lists (deriveShapeKeys = op/inputs/wholeList,
  derivePayloadKeys = f/p/init/combine); a key in neither is a named throw. wholeList enters the shape key through
  NORMALIZATION, so the key is taken over the NORMAL FORM: map+marker and native over key alike because they
  compose alike; map+marker and bare map do not. Liveness corrected to 'gated on THIS DESIGN'S per-site dedup, not
  present-tense in the tree' — measured, pipeChannelOps is a flat concatMap with no grouping.
  B2 — resolveInputs models compose.nix:137-146. Inputs are NAMES on the composed dag, so there is nothing to seal
  one hop down; two false sentences replaced by a reachable-set claim, rewrite cited.

★★★ AND THE ORCHESTRATOR'S ONE UNMEASURED QUESTION FOUND A REAL DEFECT IN THE DRAFT. Built the product wholeList ×
ROUTE — a for-marked terminal with a route off it — which NO r7 FIXTURE CARRIED. The dimension table spanned both
axes and not their PRODUCT. Result on the draft: composed channels [wrch.over.0, wrch.over.0.over.1] but edge from
= wrch.over.0.map.1, and the modelled refCheck fired 'references an undeclared channel'. A DANGLING EDGE.
  CAUSE, and it is the model's not the tree's: den-hoag binds dag once (compat/pipe.nix:336) and passes that record
  as every route's from (:344), while pipeRouteOps (default.nix:1489) is built from policiesRules.pipeOps, NOT from
  the honorWholeList'd pipeChannelOps (:1484). The draft's nameOf took a RECORD and read ch.op off it.
  FIXED BY CONSTRUCTION: names resolve BY ID through a transcribed first-wins byId; nameOf reads only .id. New
  check whole-list-route-edge-resolves-to-the-normalized-channel, five arms, with an UNMARKED routed fleet as its
  control so 'refCheck clean' cannot be refCheck gone vacuous. MUT-NAMEREC kills exactly that check.

★★ MEASURED PROPERTY OF THE SHIPPED TREE, FILED §9(9), NOT FIXED BY THIS DESIGN — THIS IS THE TREE'S CALL:
compose.nix:103-115 is nameOf = id: let ch = byId.${id}; … over a first-wins-by-id collection, and honorWholeList
KEEPS THE ID, so the stale route record and the rewritten channel share one id and byId resolves to the rewritten
one. THE SHIPPED PATH IS THEREFORE CORRECT BY AN ORDERING, NOT BY A CONSTRUCTION — default.nix:1485-1488 asks for
it in a comment ('Ordered AFTER pipeChannelOps so the whole-list-rewritten terminal (id-stable) is collected
first'). REVERSE THE TWO AND A v1 'for' SILENTLY BECOMES A PER-ELEMENT 'map'. An invariant someone must maintain,
in the shape this project's standing directive rejects.

★★★ AND THE GATE-SHAPE WARNING CAUGHT A FALSE CLAIM THE AUTHOR HAD JUST WRITTEN — SAME MECHANISM AS THE CI SPEC'S
r6, INDEPENDENTLY REPRODUCED. It wrote 'no other mutant in the battery has a singleton kill set'. FALSE: four do
(MUT-OPEN, MUT-IDX, MUT-TERMSLOT, MUT-NAMEREC). The error was the HARNESS, not the reasoning — it reported the
INTERSECTION of the failing set with a hardcoded WATCH LIST of check names, and that intersection was read as the
kill set. Re-measured by parsing the run's own 'core FAILED:' line: MUT-INPUTREC's kill set is 6, not 3. True kill
sets now stated (3/1/3/6/1/3/3/1/1) with the lower-bound reading written into §1 rather than assumed.
⇒ THE CONTRADICTION WAS INSIDE THE BATTERY'S OWN OUTPUT THE WHOLE TIME AND WAS INVISIBLE BECAUSE THE REPORTING
VOCABULARY HAD NO NUMBER IN IT. Second independent instance of this shape in one session, in different documents,
by different authors. It is not a habit of one author; it is what mutation-battery reporting does by default.

TWO UNNAMED→CONVERTED MUTANTS, AND ONLY ONE CHANGED THE ARTEFACT:
  MUT-TERMSLOT died on 'attribute p missing' INSIDE THE PROJECTION. Converting it required a DESIGN change —
  (payloadFor nm).${k} was a bare selection on a map the design specifies TOTAL over the operator's payload keys,
  so a slot misalignment surfaced as an unnamed abort. Now mustGet.
  MUT-PKEY1 died on the same error INSIDE A CHECK. Converting it required NO design change, only ordering each
  check's arms so the key-set assertion precedes any payload selection. Generalised in §1.

THREE OVERCLAIMS CUT BY THE AUTHOR, one of exactly the warned negative-existential form: 'no amount of adding rows
would have found it' — unfalsifiable, and arguably false since a wholeList × route row IS a row.

STATED LIMITS, CARRIED FORWARD: no corpus host; MUT-R2 not rebuilt on r7 (relabelled r6 in place, coordinates
marked r6's); lib/compat/** unaudited beyond pipe.nix; §5 cost tables analytic only; transitive quirkDag-freedom
uncomputed; §9(1) untouched. NOT SPANNABLE, structural rather than missing: scan/join are not emitted, and join is
multi-input where chainOf assumes one (§9(10)).

NEXT: adversarial gate round on r7. Dispatched.

### 20 — 2026-07-29T17:10:24 · Jason Bowman

★★★ r7 GATE — VALIDATED WITH CONDITIONS: 1 BLOCKING, 5 NON-BLOCKING. Anchors re-derived at START and END, identical (64a68400…/2498, b2baa49a…/2701); core run twice, 42/42 EXIT 0 read from the process; code re-resolved at 79c8c63 with the 79c8c63..01c059b diff verified beads-only. ⚠ THE REVIEWER'S SUMMARY LINE SAID 'REDESIGN-NARROW' AND ITS BODY SAID VALIDATED-WITH-CONDITIONS. TAKING THE BODY — it is detailed and internally consistent — but RECORDING THAT THE RUBRIC READS HARSHER THAN THE LABEL: C2 FAIL, C4 FAIL, C6 FAIL, C9-ARGUMENT FAIL.

BOTH r6 BLOCKING GENUINELY DISCHARGED, MEASURED NOT READ. Six mutants rebuilt from scratch by the reviewer in its
OWN construction, exact-match with abort-on-miss, 7/7 md5-distinct, all killed by name with kill sets read from
'core FAILED:'. MUT-OPEN (r6's removeAttrs partition restored) EXIT 1, 4 by name. MUT-WLPAY 3 by name. MUT-NONORM
3 by name. B2 verified at the pin: git show 53509308:lib/compose.nix :137-146 is exactly the inputs->names rewrite.
★ AND THE FAIL-CLOSED DIRECTION WAS MEASURED RATHER THAN TRUSTED: a fresh unclassified key at one node of a
two-node site leaves the guard blind (shapeDisagreement null, equal shape keys) but EVERY read of __derive on both
the composed and the projected dag THROWS BY NAME.

★★★ BLOCKING — THE PARTITION IS TOTAL ONE LEVEL DOWN AND NOT ACROSS. §1's table (.md:169) names THREE payload
carriers: __derive.f/.p/.init, MARK PAYLOADS, and ROUTE select. The design discharges the FIRST. Route select gets
no shape-key term, no seal, no projection and no fixture, and appears nowhere in either file except the route
constructor's signature.
EXHIBITED, two nodes at one site with a ctx-dependent route select, against a SAME-RUN positive control:
  shapeKeysEqual = true, guardSeesIt = false — shapeDisagreement is BLIND.
  POSITIVE CONTROL: the identical construction on targeted.select, which IS keyed, gives guardSeesIt = TRUE.
  composed dag: select answers true for host:one, false for host:two — the FIRST EMITTER'S.
  ★★★ project.at "host:two" STILL ANSWERS FOR host:one — A SILENT WRONG VALUE ON THE COMPOSE'S OWN PROJECTED
  SURFACE, WITH NO ASSEMBLY AT ALL. Two-sided seal control: derive_f_is_sealed = true, select_is_sealed = FALSE.
  Core stays 42/42 — NOTHING OBSERVES IT.
⇒ THIS FALSIFIES THE DOCUMENT'S NARROWEST DEFENDED CLAIM. .md:651 deliberately withdraws the stronger claims and
keeps 'no assembly of the compose's outputs yields a payload that is silently the wrong node's'. NO ASSEMBLY IS
NEEDED. .md:647 is false the same way.
★ HONEST LIVENESS BOUND, STATED BY THE REVIEWER: den-hoag's route select is passAll = _: true
(lib/compat/pipe.nix:50, passed at :166 -> :345), a module-level constant — SO NO WRONG VALUE IS REALIZED IN THE
TREE, NOR THE DAY THIS LANDS. Strictly less live than B1 was. BLOCKING ANYWAY, and for the right reason: the
design CANNOT BE IMPLEMENTED CORRECTLY AS WRITTEN, because §1's own table tells an implementer select is per-node
and hands them no mechanism, so they ship the hole or stop. MARK PAYLOADS ARE THE SAME UNADDRESSED CELL — believed
safe (gather.nix collectionDeclsAt reads marks per node, never reaching compose) BUT THE DOCUMENT NEVER SAYS SO.

★★★ AND THIS IS r6's B1 EXACTLY ONE CARRIER OVER. r6 applied §1's rule to the pipeOp and not to __derive; r7
applied it to __derive and NOT ACROSS THE TABLE'S OWN THREE ENTRIES. THAT IS THE SESSION'S DEEPEST STRUCTURAL
FINDING AND IT HAS THREE INDEPENDENT INSTANCES IN THIS ONE DOCUMENT:
  · the negative existential was correctly DECLINED at .md:1551-1556 — in the exact place it had burned five
    revisions — AND REAPPEARS ONE SECTION AWAY at .md:651.
  · products were spanned for wholeList × route, r7's own new lesson, and MISSED for route × ctx-dependent
    payload. The table's own closing sentence says 'enumerating axes is necessary and is not sufficient'.
  · §1's rule was applied to one carrier of three.
⇒ EACH LESSON WAS LEARNED AND APPLIED TO ITS INSTANCE RATHER THAN TO ITS CLASS. That is the r8 instruction.

NON-BLOCKING. N1 C5 three coordinate slips, ONE SELF-CONTRADICTORY: pipeRouteOps is :1493 not :1489 (wrong at
.md:392, core.nix:682, core.nix:1700; RIGHT at .md:921 and .md:2168); the 'Ordered AFTER pipeChannelOps' comment is
at :1491-1492 NOT :1485-1488 (.md:410, .md:1967, core.nix:694) — ★ THE ORCHESTRATOR RELAYED THAT WRONG COORDINATE
TWICE; the quoted text IS in the file so §9(9)'s conclusion holds and only the anchor is wrong. r6's N3 slip is
three-quarters fixed (derivedBaseNames still :1508 at .md:948). N2 C6 the two totality checks cover 7/15 and 9/15
fleets and ★ fleetWlRoute — r7's HEADLINE PRODUCT FIXTURE — IS IN NEITHER, so the checks whose stated job is 'a new
key is a failing check rather than an absorption' would not see one from the very fixture family r7 added. N3 C9
the fail-closed throw is LAZY (attrNames dag.channels, dag.edges, dag.topo, dag.declaredIds all evaluate cleanly;
only a __derive demand throws) and the prose reads stronger. N4 C7-b core's nameOfId returns ch.name where
compose.nix:105-108 returns ch.id — divergence neither stated nor pinned; harmless on these fixtures. N5 the
__derive write-site census control fires in 7 files where the appendix lists 5 — an enumeration presented as
complete that is partial.

★ KILL-SET DISCIPLINE HELD, INDEPENDENTLY. MUT-INPUTREC = 6, and THE THREE 'EXTRA' CHECKS r7 NAMES ARE EXACTLY THE
THREE THE REVIEWER GOT — from a DIFFERENTLY CONSTRUCTED mutant, so independent corroboration. MUT-NAMEREC = 1
confirmed. ⚠ MUT-OPEN's claimed singleton COULD NOT be verified (the reviewer's reconstruction reverts both shapeOf
and payloadOf and kills 4) and the reviewer EXPLICITLY DECLINED to cite its own nearby mutant as evidence about
r7's — the rule working as intended.

TWO REVIEWER HYPOTHESES REFUTED BY ITS OWN EXECUTION, RECORDED SO THEY ARE NOT RE-PROPOSED: (a) 'a mid-chain
wholeList defeats the first-wins byId' — REFUTED, derivedOf emits base-first via reverseL so the normalized node is
in acc before the route's stale copy; the construction extends past its own fixtures. (b) 'sealPayload over
resolveInputs'd channels drops or double-counts a shape key' — REFUTED, shapeOf intersects and both ride through.

COVERAGE LIMITS THAT MATTER FOR r8: the reviewer did NOT verify seven checks are non-vacuous (core.nix:1800-1908
FACT/FIDELITY 1-7; :2110-2264 five checks incl. unfired-position-fails-closed and edge-filter-is-total-over-bare-as;
:2420-2495 unpaired-projection-is-silently-wrong-paired-is-not) — read only as names in the check list. Suite not
run; no corpus host; §5 cost tables carried not re-run; lib/compat/** unaudited beyond pipe.nix; r7's own nine
mutants NOT rebuilt in their own construction.

### 21 — 2026-07-29T17:57:57 · Jason Bowman

★★★ r8 HANDED BACK AND GATED. Anchors quiesced, two samples 20s apart with mtimes preceding both: .md 5a34da1ac810b2f7923816e5c4b6d596 / 2890 lines; .core.nix 3a94dc80f43998e9cc4d499a52129541 / 3633. CORE 50/50 EXIT 0 read directly from the process (baseline 42/42). Committed papers 5a16ba0. Re-anchored at f2f50df: the 79c8c63..f2f50df diff is 3 files, NONE cited (grep 0/0 for edges.nix against a positive control of 64 for default.nix); restricted to cited files the diff is 0 bytes with a firing control of 17.

★★★ THE BLOCKING FINDING IS DISCHARGED AND THE DECISION WENT **PAYLOAD** — DECIDED BY EXPRESSIBILITY, AND THE
MEASUREMENT IS THAT **SHAPE IS NOT IMPLEMENTABLE FOR A FUNCTION-VALUED FIELD IN NIX**. select is a function, and
Nix has exactly two discrimination instruments; BOTH FAIL, measured in one nix eval (2.34.8) with string controls
in the same expression:
  toString f / toJSON f -> 'cannot coerce a function to a string' / 'cannot convert a function to JSON',
    ★ AND BOTH ESCAPE tryEval.        control: tryEval (throw "x") -> success=false; tryEval (1+1) -> 2
  f == f, SAME BINDING                 -> FALSE          control: "a"=="a" true, "a"=="b" false
  (mk (_: ctx)) == (mk (_: ctx)), same ctx -> FALSE      control: { x="a"; } == { x="a"; } -> true
  (mk f) == (mk f), one shared thunk   -> true
⇒ A STRING KEY ABORTS UNCATCHABLY, AND RECORD EQUALITY IS NOT REFLEXIVE — it reports disagreement between two
nodes emitting the SAME lambda at the SAME ctx, and answers true ONLY in the shared-thunk case, i.e. EXACTLY THE
CONSTANT IT MUST NOT BE TRUSTED ON. By the contrapositive of §1's own rule ('SHAPE only if shapeKeyOf
DISCRIMINATES it'), select is PAYLOAD. The .md table was right.
★ EXPRESSIBILITY HALF (a): under this design the pipeOp is emitted from a policy BODY, per node, with ctx in
scope, and nothing stops a body writing its route's select from ctx. The v1 translator's passAll = _: true
(compat/pipe.nix:50 -> :166 -> the single declare.pipe.route at :343; control: pipe.map returns 2) is recorded as
a LIVENESS BOUND AND NEVER AS THE REASON — exactly the orchestrator ruling.
★ THE GATE'S EXHIBIT REPRODUCED FIRST-HAND by reverting the two fixing hunks: project.at "host:two" answers TRUE
for host:one's producer under r7 and FALSE under r8; select_is_sealed false -> true; aborted false in both.

★★ AND SWEEPING THE CLASS FOUND A FOURTH CARRIER THE GATE NEVER NAMED: **exposed (collect/collectAll) is a BOOL,
hence DISCRIMINABLE, hence SHAPE — under r7 IT WAS IN NO LIST AT ALL and would have ridden the first emitter's
record silently.** MARK PAYLOADS ARE NOW ARGUED RATHER THAN BELIEVED: complete six-site .marks census in lib/ —
the write (compat/pipe.nix:361), three per-node payload reads via collectionDeclsAt (gather.nix:134/163/186), and
two fleet-grain reads touching NO payload (declarations.nix:185 emptiness, default.nix:1477 tag, both already
SHAPE terms). Marks never reach compose, so they need nothing.
★★★ THE RULE THE THREE ROWS NOW INSTANTIATE, WHICH MAKES A FOURTH CARRIER DERIVABLE RATHER THAN REMEMBERED:
**A PAYLOAD NEEDS A SEAL AND A PROJECTION EXACTLY WHEN A SECOND COPY OF IT REACHES THE COMPOSED RECORD.**

CLASS-NOT-INSTANCE, STRUCTURALLY: r7's classifiedDerive could only ever be applied to __derive. classifierFor is
now the mechanism, payloadCarriers its roster, and payload-carrier-roster-is-total-over-the-table checks the
roster against §1's table. ★ ONE MUTANT, MUT-OPEN2, NOW BREAKS ALL THREE CARRIERS AT ONCE — the observable form of
'there is one rule'. 172 path-bearing citations re-derived against f2f50df/53509308/a2f4b60/4acf0a1d, each target
line printed and read. ★ COORDINATE SELF-CITATIONS REMOVED — a document citing its own .md:NNN lines is wrong on
the next edit; the CI spec reached the same conclusion independently the same day.

★★ IT DID NOT FULLY HOLD, AND THAT IS RECORDED RATHER THAN REPAIRED SILENTLY: §1 has said since r6 that a check
whose first arm selects a payload key reports a wrong-key mutant as an UNNAMED abort. The author WROTE TWO NEW
PAYLOAD CHECKS WITHOUT THAT ORDERING and MUT-RKEY died unnamed until fixed. Written up at composedEdgeKeys and
§9(11). A class fix failing on its own newest instance.

BATTERY — 9 mutants, 10 distinct digests over 10 files, kill sets from each run's own 'error: core FAILED:' line:
MUT-RSEL 2 · MUT-RSEAL 3 · MUT-OPEN2 4 · MUT-RKEY 4 (unnamed until converted) · MUT-EXP 2 · MUT-MSEED 15 (unnamed
until converted, exposing declOpOf as a 4th named selection form) · MUT-CARRIER 1 · MUT-ROSTER 1 — ★ MUT-ROSTER
SURVIVED 50/50 UNTIL THE ROSTER WAS PINNED, which is r7's exact omission · MUT-NAMEID exit 0, an HONEST SURVIVOR
(id == name by construction at both coordinates, so no fixture can discriminate). Union = 23 of 50 checks
demonstrated non-vacuous, stated as a LOWER BOUND.
★★★ THE AUTHOR'S FIRST KILL-SET PARSER WAS WRONG — IT MATCHED THE throw EXPRESSION IN THE STACK TRACE AND REPORTED
EVERY KILL SET AS 1. THAT IS THE SAME DEFECT r7 FOUND IN ITS OWN HARNESS, AND THE THIRD INSTANCE OF THIS SHAPE IN
ONE DAY ACROSS THREE DOCUMENTS AND THREE AUTHORS. Caught by the same rule: read the number off the failure text.

THE NEGATIVE EXISTENTIAL IS GONE — §1's 'no assembly … silently the wrong node's' is replaced by a POSITIVE, TOTAL,
CHECKED enumeration of which composed-record keys throw, plus an enumeration of what the sentence had been
quantifying over — including FOUR QUIRK-STRATUM PAYLOAD CARRIERS (type, combine, dedup, class.adapters[].fn, from
gen-pipe/lib/channel.nix:52-86 via concern-quirks.nix:26-38) that ride the same composed record and are
EXPLICITLY OUTSIDE this design's split. The gate is dispatched to test whether that exclusion is sound or convenient.

NON-BLOCKING ALL FIXED: N1 beyond the four named (pipeRouteOps :1489->:1493 x3, the ordering comment
:1485-1488->:1491-1492 x3 — ★ THE ORCHESTRATOR'S RELAY IS CONFIRMED WRONG AND §9(9)'s CONCLUSION STANDS, the
quoted text is real at :1491-1492; derivedBaseNames :1508->:1509; quirkDag seed :1494-1498->:1494-1497; errors.nix
:188->:179-187; declare.pipe.route :340-347->:343-347 x4; mkDerived comment :1461-1470->:1461-1471; two of r8's OWN
new citations caught by the same sweep before shipping; mk-target.nix:224 deliberately unresolved and labelled
external). N2 fixed AND PINNED — one declared classificationFleets (17 of 20, three excluded WITH REASONS),
fleetWlRoute and fleetRouteSelect in scope; the roster is A LEXICAL REPAIR AND IS LABELLED ONE, because Nix has no
let-scope reflection. N3 fixed by MEASUREMENT not by softening prose — the laziness bound is now an ARM of
composed-record-throwing-keys-are-exactly-the-payload-carriers. N4 fixed, nameOfId returns ch.id. N5 fixed and it
RECURRED TWICE MORE (control fires in 7 files not 5; the quirkDag reference census is 10 not 8; the 'five
consumers' row cites a three-line grep because two are indirect).

STATED LIMITS CARRIED TO THE GATE: r7's own 36-mutant battery NOT re-run, its tables now labelled historical;
r8's union does NOT close unfired-position-fails-closed or edge-filter-is-total-over-bare-as; ★ THE CARRIER ROSTER
IS CHECKED AGAINST §1's TABLE BUT THE TABLE IS PROSE — a fifth pipeOp field would be caught, a new payload carrier
invented OUTSIDE a pipeOp would not; the fleet roster is a pin, not a construction; lib/compat/** unaudited beyond
the cited files; composedEdgeKeys is a NEW hand-transcription of compose.nix:220-227, so r8 widens the
transcription exposure by one record; no suite run, no corpus host, §5 cost tables carried not re-run.

### 22 — 2026-07-29T18:15:17 · Jason Bowman

★★★ r8 GATE — VALIDATED WITH CONDITIONS: 0 BLOCKING, 5 NON-BLOCKING. Anchors verified at start and end, both md5s identical, core 50/50 EXIT 0 read from the process. ~35 path:line citations resolved at f2f50df / 53509308 (pin..HEAD = 0 commits) — ZERO MISSES, which validates r8's 172-coordinate sweep.

★★ AN INSTRUMENT FINDING THAT INVERTS MY OWN QUIESCENCE DISCIPLINE: THE mtimes MOVED DURING THE REVIEW
(10:52/10:47 -> 11:11) WHILE BOTH md5s STAYED IDENTICAL. Something touched the files without changing content.
⇒ MTIME IS NOT EVIDENCE OF MOVEMENT EITHER. I have been treating a stale mtime as a quiescence signal; it is
unsound in BOTH directions, and only the content hash is. The reviewer took a second sample before concluding.

★★★ THE IMPOSSIBILITY CLAIM — CONCLUSION CONFIRMED, STATED GROUND REFUTED, AND THE REPLACEMENT IS BETTER.
The reviewer re-ran it with its own controls and tested FOUR instruments the document does not name —
functionArgs, typeOf, unsafeGetAttrPos, and ★ builtins.toXML. Six instruments total, none discriminates, every
non-discrimination carrying a firing control in the same run. select is PAYLOAD. But two supporting sentences are
FALSE:
  1. 'Nix offers exactly TWO discrimination instruments' — A CLOSED-WORLD ASSERTION WITH NO ENUMERATION METHOD.
     Four more found in one sitting.
  2. 'a STRING term … aborts uncatchably' — ★ builtins.toXML f RETURNS A STRING AT EXIT 0, 431 chars, NO ABORT.
     A string term IS available.
★★★ AND THE CORRECT STATEMENT IS SHARPER AND RUNS IN THE DIRECTION THIS DOCUMENT CARES MOST ABOUT: toXML renders
two BEHAVIOURALLY-DIFFERENT closures IDENTICALLY (toXML_discriminates = false beside behaviour_differs = true,
firing control). ⇒ A STRING SHAPE KEY IS NOT BLOCKED BY AN ABORT — IT IS AVAILABLE, SILENT, AND FAILS OPEN,
admitting exactly the divergence the guard exists to refuse. THAT IS A STRICTLY BETTER ARGUMENT FOR PAYLOAD, AND
IT IS C4 RATHER THAN C1. Also reproduced the shared-thunk trap on den-hoag's own constant:
{ s = passAll; } == { s = passAll; } -> TRUE, so SHAPE would pass TODAY and fail silently the moment a body
computes a per-node select.

★★★ N1 (C6 + C7-a) — THE CLASS BOUNDARY IS WRONG, AND IT IS THE 'exposed' FAILURE MODE EXACTLY ONE CARRIER OVER,
IN THE REVISION WRITTEN TO CLOSE THAT CLASS. The roster {__derive, route, mark} was enumerated from §1's PROSE
PAYLOAD COLUMN (3 rows). ENUMERATING INSTEAD FROM compilePipe's OWN RECORD CONSTRUCTION (compat/pipe.nix:357-361)
GIVES FOUR sub-record carriers: derived.__derive, routes[], marks[], ★ targeted[].
  targeted HAS NO CLASSIFIER AT ALL. classifierFor instantiations = 3 (deriveClass:301, routeClass:344,
  markClass:409); targetedShapeKeys|targetedPayloadKeys|targetedClass -> rc 1, ZERO hits; the same predicate shape
  for route -> 8 hits, so the instrument fires. Core :620-626 takes the route term through routeShapeOf, :641-652
  the mark term through markShapeOf, and ★ :634 READS t.select / t.from.id STRAIGHT OFF THE RAW RECORD.
  EXHIBITED, two nodes at one site, targeted entries agreeing on select and from.id and differing only in a
  per-node function key: unclassified ROUTE key -> THREW; unclassified MARK key -> THREW; unclassified TARGETED
  key -> NO THROW. shapeKeysEqual true, guardSeesIt FALSE, seeded pipeOp's wrap = "ONE" while node two's own is
  "TWO".
  ★★ THE DECISIVE FORM: the reviewer ADDED THAT FLEET TO THE DECLARED ROSTER and ran the whole core -> 'core:
  50/50', EXIT 0. THE TOTALITY APPARATUS IS GREEN ON A THIRD STATE. Contrast the three fleetUnclassified*
  controls, which must be EXCLUDED from the roster because they throw.
  ⇒ FALSIFIES §1's OWN SENTENCE 'A field is read by the key or excluded on the record; there is no third state'
  ONE LEVEL DOWN. ★ AND THE DOCUMENT'S STATED BOUNDARY DOES NOT COVER IT: it says 'a fifth pipeOp field would be
  caught; a new payload carrier invented outside a pipeOp would not'. targeted is NEITHER — it is the FOURTH,
  EXISTING pipeOp field whose SUB-RECORD is unclassified. §9(4) records a targeted PROJECTION obligation, not a
  CLASSIFICATION one, so the deferral does not cover it.
  ★ WHY NOT BLOCKING, STATED SO IT IS NOT READ AS SOFTENED: compilePipe constructs targeted at ONE site with
  exactly { select, from } and shapeKeyOf reads both, so nothing falls through today and the design IS
  implementable as written. Remedy = one classifierFor instantiation + one fixture. THE PRIMITIVE ALREADY EXISTS,
  WHICH IS PRECISELY WHY 'STATED LIMIT' IS NOT AVAILABLE HERE — the document's own rule for permitting one is
  that no construction exists (as it correctly says for the fleet roster: 'Nix cannot enumerate a let scope').

★★ N2 (C1 + C3) — 'exposed' IS OVER-CLAIMED AND ONE CITATION IS FALSE, AND I RELAYED THE OVER-CLAIM MYSELF.
Full lib/ census of 'exposed =' -> EXACTLY TWO HITS, BOTH WRITE SITES (compat/pipe.nix:208 false, :220 true), each
a literal inside the arm that ALSO SETS THE TAG. Positive control 'predicate =' fires. gather.nix DOES NOT READ
IT — collectMarksAt:157 is 'all = m.__pipeMark == "collectAll"', it turns the TAG into all.
  ⇒ .md:334-335 ('it decides which pool the mark joins, gather.nix:141-166 turns it into all') IS FALSE. The range
  is right; the claim about what it reads is wrong. ★ THE CORE STATES THE TRUE FACT AT :385 AND THE FALSE ONE AT
  :2464 — the two files, AND THE CORE ITSELF, disagree on one measured fact.
  ⇒ exposed is REDUNDANT WITH __pipeMark BY CONSTRUCTION at both write sites, so 'under r7 it was in no list at
  all and would have ridden the first emitter's record silently' IS A COUNTERFACTUAL compilePipe CANNOT PRODUCE.
  ★ I REPEATED THAT CLAIM IN MY OWN RECORD OF r8 — IT IS WITHDRAWN. The CLASSIFICATION is still correct (bool ⇒
  discriminable ⇒ SHAPE, fails closed) and the fixture is legitimate under the den-surface-expressibility bar.
  What is wrong is the STATUS: this belongs to the MUT-C / MUT-FROMW 'redundant by proof' class, which the
  document labels scrupulously for those two while presenting exposed as a live silent hole.

★ N3 (C6) — THE QUIRK EXCLUSION IS SOUND BUT THE ENUMERATION IS FOUR WHERE THE SOURCE GIVES FIVE, AND THE
ARGUMENT GIVEN IS NOT THE SOUND ONE. Sound because quirks = ent.config.den.quirks (default.nix:1431) is a SINGLE
FLEET-LEVEL READ — one declaration for the whole fleet, no second copy — i.e. BY THE DESIGN'S OWN RULE, the same
reason the fleet-structural route arm needs nothing. The document instead argues by SCOPE ASSERTION ('§1's split
is a split of a pipeOp; it says nothing about them'), which is convenient where a sound discharge was available in
its own text. ★ AND THE ENUMERATION IS SHORT BY ONE: gen-pipe/lib/channel.nix:52-86 emits type, merge, combine,
INIT, dedup, class, and den-hoag's own authoritative channelOptKeys (compat/pipe.nix:238-244) is the five-element
{ type, merge, combine, init, dedup }. INIT APPEARS IN NO ROW OF §1's TABLE. ★ The omitted member is the sharp
one: init is A PLAIN VALUE, FORCED RATHER THAN APPLIED — the payload KIND this document itself singles out one
level over ('a seal written as a throwing function would leak it'). A successor told 'the same analysis applies
and has not been done' will analyse four and miss the fifth.

N4 (C2-a) — the replacement for the withdrawn existential IS positive and total, quantified over all channels and
all edges with two non-vacuity arms and a two-sided control. BOUND: total over the MODEL's composed record, which
carries none of the quirk keys. ★ A NEW EXISTENTIAL EXISTS — 'Nix offers exactly two discrimination instruments' —
whose truth-maker is the space of instruments one could write. No mutant falsifies it; EXHIBITION does, and the
reviewer's exhibition partly did.
N5 (C9) — §1:379's 'there is no third state' is exhibited FALSE one level down; scope it to pipeOp top-level
fields or make it true by N1's remedy.

★★ FOURTH INSTANCE TODAY OF THE HARNESS-SUMMARY DEFECT, THIS TIME IN THE REVIEWER: its first kill-set parser
matched the throw expression in the stack trace and returned 2 for everything. Re-read off the resolved 'error:
core FAILED:' line, three mutants reproduced EXACT on count AND names (MUT-CARRIER 1, MUT-EXP 2, MUT-RSEL 2).
★ AND IT REFUTED ITS OWN WORKING HYPOTHESIS ON §9(11): it built the siblings for the other two carriers — mark
predicate and derive f misclassified as SHAPE — and BOTH DIE NAMED (kill sets 1 and 10). The author's self-report
that MUT-RKEY was the only occurrence is ACCURATE AND COMPLETE. Rejection recorded so it is not re-proposed.

TWO CLAIMS RE-DERIVED AND CONFIRMED: composedEdgeKeys is a COMPLETE transcription — the tee arm
(compose.nix:230-237) carries the same six keys as the route arm, and :224 is 'inherit (d) select;' verbatim. The
six-site .marks census reconciles exactly: 5 reads + 1 write.
COVERAGE LIMITS: the whole .md read (four passes) but only ~600 of 3633 core lines; NOT verified at all — every
nix-config 4acf0a1d coordinate, every den v1 a2f4b60 coordinate, §5's cost tables, §2's O1/O2/O3 and the
seven-sibling table, the den-hoag suite, r7's historical battery; §0's rung table RELAYED NOT CHECKED; six of
r8's nine kill sets not rebuilt.

### 23 — 2026-07-29T18:54:32 · Jason Bowman

★★★ r9 SHIPPED. Anchors md5-verified in AND out, two samples each, mtime ignored: .md 52db6cc17a1b8c905b20571b7173a990 / 3169 lines; .core.nix 315f5a06f829df71e7b0134f75363516 / 3999. CORE 52/52 EXIT 0 read directly from the process (r8: 50/50). Committed papers 3b81fdd. No index- or worktree-touching git command run in either repo.

★★★ N1 CLOSED BY RE-GROUNDING THE ROSTER'S DOMAIN, NOT BY ADDING A FOURTH ENTRY. THE PRINTED ENUMERATION, FROM
THE EMITTER (lib/compat/pipe.nix:350-361 @ cb04384), each RHS resolved in the same file:
  :351 channel  = pipeName (:272), A STRING              — not a carrier
  :352 derived  = dag (:336)                             — carrier, deriveClass
  :353 routes   = asRoutes (:341)                        — carrier, routeClass
  :357-360 targeted = INLINE { inherit (c) select; from = dag; }  — ★ CARRIER, NO CLASSIFIER AT r8
  :361 marks    = map (c: c.mark) (byRole "site")        — carrier, markClass
PREDICATE CONTROL, same run: the 4-space form on channelOptKeys (:238-244) -> 5; the 6-space form on that same
range -> 0, exit 1. It discriminates.
EXHIBIT REPRODUCED: route_unclassified_key_throws true, mark true, ★ targeted FALSE; keys seen [from select wrap];
shapeKeysEqual true, guardSeesIt false, wrap ONE/TWO; firing control shapeDisagreement fleetTargetedBad != null
-> true. DECISIVE FORM REPRODUCED: that fleet in the declared roster -> core 50/50, exit 0.
★★ THE REMEDY WENT PAST THE INSTANTIATION, WHICH IS THE POINT: carrier-roster-is-total-over-the-emitted-record
DERIVES ITS DOMAIN FROM carrierBearingFields OVER THE PIPEOPS THE FIXTURES EMIT — A FIFTH CARRIER FAILS WHETHER OR
NOT §1's TABLE IS UPDATED. ★ And r8's 'payloadKeys != [ ]' arm WAS THE PROSE COLUMN BAKED INTO THE CHECK; replaced
by a declared carriersWithNoPayload entry with its reason.

★★★ AND BUILDING IT FOUND TWO MORE OF THE SAME CLASS.
1. shape-key-fails-closed-on-every-classified-carrier DID NOT EXIST. r8's route and mark terms ASSERT IN THEIR OWN
   COMMENTS that an unclassified key is 'a NAMED THROW here'. It was — and ★ REVERTING EITHER TO A RAW RECORD READ
   LEFT THE CORE GREEN AT 51/51. NOTHING WENT THROUGH shapeKeyOf. A comment asserting a guarantee with no check
   behind it, where the guarantee happened to hold. Fixed OVER THE ROSTER, fixture carried on the roster entry,
   derive term made uniform so no exemption is declared. Every shape-class read now goes through mustGet — which
   turned MUT-TGTPAY from an UNNAMED 'attribute select missing' into a 7-check NAMED kill (the composedEdgeKeys
   conversion applied to its class this time).
2. ★ IN r9's OWN FIRST DRAFT: targetedShapeKeys is TWO keys and the discriminating pair was built for select ONLY.
   MUT-TGTFROM SURVIVED 52/52, with the pre-fix control green in the same run. Both keys now discharged, with an
   agreement arm.

BATTERY: 10 mutants, 11 distinct md5 digests over 11 files, ALL TEN KILLED BY NAME, kill sets off each run's own
'error: core FAILED:' line. ★ RECORDED IN THE DOC: the first MUT-TGT-RAW / MUT-ROUTE-RAW build mutated the mustGet
WRAPPER and died at exit 1 FOR THE WRONG REASON (a type error in the mutant). Caught by READING THE FAILURE TEXT,
rebuilt, then named kills. Same family as the CI spec's 'rebuilding from the English produced a wrong mutant
first', now twice in one day in two documents.

N4 — toXML RE-RUN WITH ITS OWN CONTROLS AND CONFIRMED. behaviour_differs true (fA 0=1, fB 0=2);
★ toXML_is_a_string TRUE, toXML_length 105, EXIT 0, toXML_discriminates FALSE — identical render. On the
select-shaped pair (ctx: _: ctx.host == "one" vs "two", a_behav true / b_behav false): differs FALSE, len 107,
exit 0. Firing controls: toXML fires on data AND on arity. functionArgs, typeOf, unsafeGetAttrPos also
non-discriminating with controls that fire. toString/toJSON under tryEval -> EXIT 1, control tryEval (throw "x")
-> false at exit 0. { s = passAll; } == { s = passAll; } -> true.
⇒ BOTH r8 SENTENCES WITHDRAWN. Six instruments enumerated; the string term is AVAILABLE, SILENT, FAILS OPEN.
★ THE ENUMERATION IS LABELLED A STATED LIMIT — no construction enumerates builtins from inside Nix — which is the
honest form of a closed-world claim.

N2 relabelled to the MUT-C / MUT-FROMW redundant-by-proof class, both citations corrected in the .md AND at BOTH
core sites; measured: 'exposed =' is 2 write sites each a literal beside the tag (control 'predicate =' fires),
the only .exposed READS in the repo are 2 golden tests, and collectMarksAt reads the TAG.
N3 re-argued from quirks = ent.config.den.quirks (lib/default.nix:1507 @ cb04384) = ONE FLEET-LEVEL READ ⇒ no
second copy — the design's own rule, same as the fleet-structural route arm. channelOptKeys corrected to FIVE;
init called out as the forced-not-applied one. N5 made true at BOTH levels with the two instruments named, rather
than scoped away.

★★★ UNREQUESTED AND IMPORTANT — THE ANCHOR DRIFTED FOR THE FIRST TIME IN FIVE REVISIONS, AND THE CAUSE WAS OUR OWN
KERNEL MIGRATION. 0716eec landed between f2f50df and cb04384. git diff --name-only f2f50df..cb04384 over
lib/ ci/ parity/ = 23 FILES, ★ SIX OF THEM CITED (lib/default.nix 2844->2910, lib/errors.nix,
lib/attributes/{collections,default,structural}.nix, ci/tests/end-to-end.nix). lib/compat/pipe.nix did NOT move.
★★ 148 COORDINATE OCCURRENCES RE-DERIVED FROM **CONTENT**, NOT FROM A LINE OFFSET — a difflib opcode map, because
THE OFFSETS DIFFER PER REGION (+8, +38, +60). 80 full-form + 68 bare, ZERO ANCHOR MISSES, and the rewriter REFUSES
TO WRITE IF ANY ANCHOR FAILS. Re-verified: 196 den-hoag citations, 18 files, 90 distinct (path,range) pairs, 0 out
of range, checker's positive control fires. 19-coordinate content spot-check (15 corrected + 4 unmoved as
control) — all correct. ★ It also caught a substantive error: the quirkDag COMMENT-MENTION COUNT IS THREE, NOT
TWO — r8 fixed the total and mis-stated the split.

★ ORCHESTRATOR NOTE ON THE FIVE HEAD MOVES r9 OBSERVED (37d389b -> cb04384 -> 77bd4ab -> 63bb714 -> e2fa8af):
VERIFIED — ALL SIX COMMITS SINCE 0716eec ARE MINE AND BEADS-ONLY. 'git diff --name-only 0716eec..HEAD' excluding
.beads/ returns NOTHING, against a positive control of 26 non-beads files across the cutover itself. No rogue
writer. The anchor drift was 0716eec, not the beads noise — but the noise is what made r9 see five moves and hit a
transient 'bad revision'.

COVERAGE LIMITS: 119 NON-den-hoag citations (gen-pipe 53509308, den v1 a2f4b60, nix-config 4acf0a1d) UNTOUCHED AND
UNCHECKED; r8's 36- and 9-mutant batteries NOT re-run; §5 cost tables, §2 O1/O2/O3, the seven-sibling table and
den-hoag's own suite NOT run; ★ of the 90 (path,range) pairs, 71 VERIFIED IN-RANGE ONLY, NOT BY CONTENT;
lib/compat/** unaudited beyond cited files.

### 24 — 2026-07-29T19:27:45 · Jason Bowman

★★ r9 GATE — VALIDATED WITH CONDITIONS: 2 BLOCKING, 4 NON-BLOCKING. Anchors md5-verified in and out; core 52/52 EXIT 0. lib/ ci/ parity/ byte-identical cb04384..HEAD. Six mutants, kill sets off each run's own 'error: core FAILED:' line. ★ SPEC TRACK PARKED HERE BY OWNER REDIRECT — recorded so it reconstitutes, not because r10 is dispatched.

B1 (C7-a, C2-a) — TWO OF FOUR routeShapeKeys HAVE NO DISCRIMINATING PAIR. routeShapeKeys = [__genPipeOp op from to]
(:379-384) but shapeKeyOf's route term (:789-796) reads only from and to. EXHIBITED on fleetRoute, one site, each
mutant differing at ONE node: MUT-ROP (op route->tee) -> 52/52 EXIT 0; MUT-RGPO (__genPipeOp true->false) ->
52/52 EXIT 0; CONTROL (to -> a key the term DOES read) -> EXIT 1, 12 named checks. Instrument fires; the survivals
are the keys.
★★ IT IS r9's OWN MUT-TGTFROM FINDING ONE CARRIER OVER, UNAPPLIED — r9 found targetedShapeKeys had two keys with a
pair built for only one, fixed it for targeted, and DID NOT CARRY IT TO route. THE RULE APPLIED TO ITS INSTANCE
AND NOT TO ITS CLASS, IN THE REVISION THAT NAMES THAT PATTERN SIX TIMES.
★ SEVERITY IS REAL: compose's TEE arm carries THE SAME SIX KEYS as the route arm, so route-vs-tee is a genuine
structural divergence with an identical key set — two nodes at one site emitting one of each compose as whichever
emitted first, silently. Under the document's own den-surface-expressibility bar, a policy body can choose
route-vs-tee from ctx.

B2 (C6, C9) — THE DERIVED DOMAIN IS NOT TOTAL AND THE STATED MITIGATION IS BACKWARDS. carrierBearingFields
(:581-589) admits a field only when non-empty. Three mutants on one fixture: M1 (sealed = [{newkey=1;}]) -> EXIT 1,
kill 2 named; M2 (sealed = [ ]) -> EXIT 1, kill 1; ★ M3 (sealed = [ ] PLUS "sealed" added to keyedFields) ->
52/52 EXIT 0. ⇒ A FIFTH CARRIER EMPTY IN EVERY FIXTURE IS ABSORBABLE INTO keyedFields WITH NO CLASSIFIER, NO
PAYLOAD DECISION AND NO carriersWithNoPayload ENTRY. The document NAMES the hazard at :577 and its mitigation
arm (b) quantifies over DECLARED roster entries — so it cannot demand exercise of a carrier that is not on the
roster. PRECISELY INVERTED. ★ LIVE, NOT HYPOTHETICAL: targeted is [ ] in 17 of 22 fixture pipeOps.

★★★ THE DOMAIN-TOTALITY JUDGEMENT, SPLIT THREE WAYS, AND THE SPLIT IS THE FINDING:
(a) the enumeration INSIDE the core is SOUND — emittedFieldsOf = attrNames p is genuinely derived, and an
    unclassified key throws; M1/M2 dying named is the control that it fires.
(b) the 6-space grep over pipe.nix:350-361 is TOTAL OVER THE LITERAL ARGUMENT, NOT OVER THE EMITTED RECORD — the
    emitter is gen-dispatch mkActions, which stamps __action, and the design adds site; NEITHER appears at
    :350-361, and the fixtures carry SEVEN fields not five. Handled correctly in keyExcludedFields, so not a hole
    today — but the grep is not the totality instrument it was presented as. ★ The mark carrier proves the risk is
    real and was handled: append's value enters via 'inherit (stage) value;' — an inherit form the grep cannot see
    — and the core's mark enumeration captured it anyway.
(c) ★ THE FIXTURE SET IS NOT TOTAL OVER THE EMITTER AND STRUCTURALLY CANNOT BE. The core takes zero imports and
    reads no file — measured, with a control: readFile|readDir|import|builtins.path|getEnv|fetch matches ONE line
    (the usage comment); builtins. matches 42. All 22 pipeOps are hand-written literals. NOTHING IN THE CORE
    OBSERVES lib/compat/pipe.nix. ⇒ THE TRANSCRIPTION STEP MOVED FROM THE PROSE TABLE INTO THE FIXTURE LITERALS;
    IT DID NOT DISAPPEAR.

★★★ N3 — THE STATED LIMIT WAS NOT AVAILABLE, AND REFUTING IT MADE THE CONCLUSION STRONGER. The document permitted
its six-instrument enumeration as a stated limit because 'no construction enumerates Nix's builtins from inside
Nix'. MEASURED: builtins.length (builtins.attrNames builtins) -> 118, EXIT 0. THE CONSTRUCTION EXISTS.
★★ SO THE GATE BUILT IT: 118 builtins, four measurements each, EACH IN ITS OWN nix eval so an uncatchable abort in
one cannot kill the sweep, stderr KEPT. ★ Its v1 predicate was DEFECTIVE and it reported so — 'b fA != b fB'
returned true for 48 builtins, ALL ARTEFACTS OF PARTIAL APPLICATION, because closure inequality is trivially true.
v2 adds a REFLEXIVITY ARM: an instrument discriminates only if (b fA) == (b fA) AND (b fA) != (b fB). RESULT: 12
skipped by name, 46 type-inapplicable with stderr confirming, 13 REFLEXIVE, and of those only tryEval reports
discrimination — which is POINTER IDENTITY, not behaviour (two separately-written behaviourally-IDENTICAL closures
compare UNEQUAL). ⇒ ZERO OF 118 BUILTINS DISCRIMINATE TWO BEHAVIOURALLY-DIFFERENT CLOSURES. NOT A STATED LIMIT —
A MEASURED UNIVERSAL OVER THE ENUMERABLE BUILTIN SURFACE. The document should claim the stronger thing.
★ N2 — 'toXML discriminates two arities' is FALSE and the two files disagree about it. Binder name held constant:
(x:x) vs (x:y:x) -> false; vs (x:y:z:x) -> false; attrset arity -> false; BODY invisible. What fires is the OUTER
BINDER NAME. The .md records the actual expression as toXML (x:x) != toXML ({q}:q) — BOTH ARITY 1 — so the .md is
right and THE CORE'S LABEL FOR IT IS WRONG: a verification label substituting for the verification. CORRECT AND
SHARPER: toXML renders a lambda as its OUTERMOST BINDER'S NAME OR PATTERN ONLY. That makes 'available, silent,
fails open' MORE true.
★ N1 — a false citation, and it is '+38 APPLIED TWICE'. .md:1063 cites the quirks read at default.nix:1507; the
read is at 1431 @ f2f50df and 1469 @ cb04384, and 1469+38 = 1507. IN RANGE, so the in-range checker passed it.
⇒ SAMPLING THE IN-RANGE-ONLY SET FOUND A WRONG ONE ON THE FIRST SUBSTANTIVE PASS. IN-RANGE IS NOT CORRECT. The
claim itself is true (quirks = occurs exactly twice: the declaration and one read) — only the coordinate is wrong.
N4 — both withdrawn r8 sentences survive as LIVE PREMISES at core :787 and :3590-3592: the withdrawal was applied
where the argument is MADE and not where it is USED. Control: the .md's two hits are the withdrawal itself,
correctly stated, so it is a core-only defect.
COVERAGE: the .md was GREPPED ONLY, never read end-to-end; §0/§2/§5/§9's obligation list and the seven-sibling
table NOT OPENED; r9's 10-mutant battery and r8's two batteries NOT re-run; 29 of 47 den-hoag (path,range) pairs
content-verified, ONE WRONG; all 18 non-den-hoag citation pairs UNTOUCHED.

### 25 — 2026-07-31T14:07:52 · Jason Bowman

★★★ OWNER RULING OBTAINED, 2026-07-31 (session 3): ARM (ii) SELECTED — consumer-side records rewrite. Owner shown all four arms with costs (i gen-pipe withView gap 4; ii records rewrite; iii permanent ceiling; iv O3/O4+r9 supersession); chose (ii), the thrice-gate-verified recommendation. Consequences now binding on the design: §2 construction stays INTACT; commitment route goes CORPUS-EMPTY (zero live corpus witnesses — §2 ships on synthetic fixtures, stated); TWO nix-config rewrites (hub-shares + hub-peer, per round-2 finding 2), both ends of the gather.nix broadcastGatheredWith flip land together; NOT byte-compatible — arm (ii) chooses where the narrowing is absorbed; den-hoag channelBindingsAt cost is LOCATED NOT SIZED and the next design round must size it. The hold on this track is LIFTED: O6-C proceeds to round 4 with defect 1's fork resolved by this ruling.

### 26 — 2026-07-31T23:17:46 · Jason Bowman

★★ GATE ROUND 11 (re-run) — compat ops-seam design spec. VERDICT: REVISE. Artifacts stable start+end, two samples: core b43702b2/3428, ledger 1e3718cc/1415, script 2fa2f230/266, papers 128772d. Reviewed fresh and UNPRIMED after the prior session's gate-11 findings were lost unpersisted; correspondence checked by orchestrator AFTER the report: lost F-A (sibling skeleton must hoist node-independent) ≈ this run's F2; lost F-B (three-cause verbatim message) ≈ this run's F1 — both re-derived independently, so the re-run corroborates the lost round. The four lost statement-level findings are presumed subsumed/exceeded by F3-F5 (register-script defects the lost summary did not mention).

CONSTRUCTION (both §9.2.1, both left behind by the r9-F10/r10-F12 domain widenings; §2 untouched):
· F1 [C6]: the shadow refusal's message names TWO causes; the widened predicate's domain has THREE. base = enriched-context // genAttrs channelNames // surfaces.values — a key satisfying base ? k through surfaces.values alone (attrNames (local // gathered), unconstrained: den.channelGather is merge.types.raw, owner = gather supplier) renders one of two FALSE causes and neither remedy reaches the owner. Message written r4 for the enriched-only domain, never re-derived across two widenings. Evidence: channelNames = quirks: builtins.attrNames quirks (concern-quirks.nix); channelGather = gather.mkGather entityKinds (compat/flake-module.nix), verified at 6dc4d44.
· F2 [C6+C7 vs F12's 'total on both axes by construction']: check 1 stated 'evaluated once per fleet at the file top-level let' BUT siblingNames = attrNames siblings with siblings = { settings = settingsBindingAt id; channels = surfaces.records; } — id-dependent on both keys, not in scope at top level. As specified check 1 cannot be written. Obvious repairs each surrender a round-10 gain (re-enumeration reinstates the driftable list F12 deleted; per-node fold puts node-invariant work at N≈8000 and drops the refusal on fleets wrapping no class modules). REVIEWER'S PROPOSED third repair (proposal, not measured as landed): derive attrset from name list — siblingNames a file-level constant, siblings = genAttrs siblingNames (…); one enumeration, fleet grain, no-drift by construction.

INSTRUMENT:
· F3 [law 41]: register.sh exits 1: pass=65 drift=22 skip=7. TWENTY drift rows (B4-corpus ×13, B9 ×3, B26 ×2, 2 controls) are corpus-root 'grep -r … .' forms reading TWELVE worktree copies in nix-config (11 .worktrees/ + 1 .claude/worktrees/, not gitignored): stated 4/9/4/2/17/1 vs root-grep 49/124/54/15/197/10. Every stated value reproduces EXACTLY under git grep — cells right, stated instrument wrong, never reproducible as printed. B4-corpus's own safety justification ('root ≡ modules/, --exclude-dir=.git makes it safe') refuted by measurement.
· F4 [law 45-family]: TREE_PIN=6dc4d44 is prose only — every den-hoag row runs git grep with NO rev, silently reads HEAD. B23 stated 12 → 13 at HEAD, E5 stated 9 → 10 at HEAD; both reproduce exactly AT THE PIN. Control: git grep -c '' 6dc4d44 -- lib/attributes/class-modules.nix = 354 vs HEAD 507. Currency note: §8's entry-5 census '8 live across 4 files' is 9 live at HEAD (class-modules.nix from e90b0b7) — pin governs, but an implementer would reuse the stale enumeration.

STATEMENT-LEVEL:
· F5: B23 is the FIFTH comment-blind cell (raw 12 = 7 live + 4 nix comments + 1 ledger.md prose; §2.3.1a's 'seven' derivable from no stated command). The document repaired this exact raw-vs-live split four times and records it as a standing class; B23 carries no comment-excluded arm. At HEAD raw moves 13, live stays 7 — the checked figure is the unstable one.

CLEAN: C9 register read entry-by-entry (entries 1,2,3,5 dispositions verified); sibling symmetry; two-checks asymmetry reconciled; law-(a)/(b) prefix asymmetry derived; §9.1 one-rewrite cardinality reconciliation sound.

COVERAGE (limits): core 3428 read in full; ledger ~lines 240-369 + targeted B9/B23/B26, ~1000 lines unread (figures re-derived by command, not quoted); nix-eval cells (B7,B22,B25,B26p1,B27p1-2,B28) NOT evaluated — register skips all 7, no evaluator ran; r9 ops-representation spec, gen-pipe 5350930, gen-schema 6732239 NOT opened; F1's collision established from type+wiring, no colliding fixture built. Gate does not exit (rounds run until dry per 2026-07-31 economics ruling).

### 27 — 2026-08-01T00:00:46 · Jason Bowman

★★★ ROUND 11-FIX AUTHORED, ON PAPERS MAIN 699a697 (core ea3ae6b2/3584, ledger 0de47941/1663, script 01dba895/390). All five gate-11 findings discharged at class. REGISTER: 118 pass / 0 drift / 7 skip EXIT 0. Baseline at author start was 64/23/7 — one MORE drift than the gate saw, because nix-config HEAD moved off pin between runs (425f1d3b→05c09067); F4's repair covers it.

F1: three-valued discriminator DERIVED FROM THE SAME operands LIST THAT BUILDS base (base = foldl' over operands; originsOf k = filter (o: o.attrs ? k) operands) — cause space and predicate domain are ONE object; totality by construction (base ? k iff originsOf k != []). Three origins each with owner-reaching remedy (enriching policy / den.quirks registration / den.channelGather SUPPLIER). Class sweep over ALL SIX refusal messages vs current domains: found a SECOND DEFECT THE GATE DID NOT NAME — the FLEET-level shadow refusal shared the per-node message, interpolating a <node> its predicate does not have; split into its own arity-1 text. siblingNames now interpolated never spelled (round-4 literal was F12's defect surviving in prose). §11 gains a third acceptance arm (gathered-surface) whose fixture must assert the REMEDY substring.

F2: gate's proposal adopted + sharpened: file-level siblingBuilders attrset, siblingNames = attrNames siblingBuilders (file-level), per-node siblings = mapAttrs application. Both round-10 gains kept AND removes a per-node attrNames round 10 introduced unnoticed (~8000× for an invariant answer). Check 1 rides systems under builtins.seq per the file's own A18 precedent (output-modules.nix 'Gate BEFORE the build') — fires on a fleet wrapping no class modules. Byte-neutrality holds ONLY because the fold seeds with the head operand (foldl' from {} would copy per node) — stated in-doc. §9.2 sizing corrected FOUR→FIVE expressions. Class sweep: 5 placement claims verified at pin, one defective (this), four correct.

F3: refutation reproduced exactly (root vs modules/: 49/4 124/9 54/4 15/2 197/17 10/1; 12 nested checkouts confirmed, now a register row). All corpus commands → git grep 425f1d3b in script AND ledger AND core (core had root forms too at §2.2/§9.2.1 — same class). ★ CORRECTION TO THE GATE: .worktrees/ IS git-excluded — via .git/info/exclude, not .gitignore — which is exactly why git grep is clean while grep -r is not. Recorded shape: a cell can be correct, its command reproducible, and its stated ground refuted, all at once.

F4: every tree row rev-pinned (rev before --), corpus rows too; preflight HEAD checks → informational notices, pin RESOLVABILITY the hard precondition; standing law-45 control printed both ways (354 vs 507). Drift confirmed B23 12/12/13, E5 9/9/10 (stated/pin/HEAD). §8 entry-5 currency: 10 raw / 9 live at HEAD, all-but-two coordinates moved (enumerated); also fixed a false 're-measured at HEAD (f631973)' — f631973 is not HEAD.

F5: B23 split raw 12 / Nix 11 / LIVE 7 + SUM row (7+4+1) so class-migration fails a row even when the total holds. Class sweep found FOUR more un-split raw counts: ★ B15 the significant one (stated answer WAS the raw 88; true 88 matches / 71 live / 17 comments; §2.4.3 corrected; over-count ran the disclaimer's own direction); B3c 13/12/4; B14 8/6 (conclusion rests on per-line read, untouched); B3 3/2; E5 9/8; B8 control 70/68. Measured-zero comment contribution stated as MEASURED for seven more cells; only B2a has a structural argument and was measured anyway.

OUT-OF-CLASS (reported): (1) E5 is a script label with NO ledger cell (only §8 core statements) — pinned per F4, cell NOT minted, next-round item; (2) B3c's bare ':182' reads as concern-policies.nix but is declarations.nix:182 (measured; corrected inside the new split arm); (3) den-hoag .beads/beads.jsonl uncommitted at 02d47bc — expected, orchestrator's session exports, batched at close. INSTRUMENT FAILURES SELF-RECORDED (ledger items 7-9): sed-over-git-grep-n leaves rev:file:lineno: prefix defeating ^ anchors — MANUFACTURED TWO FALSE ABSENCES (B20 formals, B27 defaulted formals scored 0 vs true 44/4), caught because two simultaneous zero-collapses were implausible; alternation without -E matched literally (B14 first command returned 0, caught by law-46 verbatim re-run); zsh no-word-split recurrence. Every newly stated command re-run verbatim post-edit; core md5 stable after final ledger-only edit.

### 28 — 2026-08-01T00:14:08 · Jason Bowman

★★ GATE ROUND 12 — VERDICT: REVISE (C6 mapping: accept-with-conditions — every finding has a named local edit, none needs a new position). Artifacts stable (ea3ae6b2/0de47941/01dba895 at f1c4f3d). REGISTER RE-RUN REPRODUCED: 118/0/7 EXIT 0; law-45 control fires both arms; every tree row verified rev-before--- by reading the helpers; only HEAD reads are E5's labelled currency rows.

CONSTRUCTION (all three in §9.2.1, the round-11 repair's own artifact):
· F1 [C6 + the section's own fails-open rule]: the enriched origin attributes the WHOLE operand to 'the enriching policy' — but enriched-context = inherited-context // enrichments.added, and inherited-context extracts node.decls, which carries framework dims (parentDim/leafDim/__entry), USER-CHOSEN containment binding names, and den.systemViews keys. Only enrichments.added has an enriching policy. den.systemViews.<sys>.channels produces exactly this collision — and the document itself quotes rb0's any-key-type-legal fact two sections earlier. REPAIR (local, tree already computes it): split the enriched origin on (result.get id "enrichments").owners ? k (owners is a key→__policy map, seq-forced; provenance is its error twin). A11's enriched-arm fixture is blind to this by construction — fixture set must gain the decls-writer sub-domain.
· F2: row 3's ALTERNATIVE remedy ('register it as a channel so the first remedy applies') ESCALATES: registration adds k to channelNames hence channelKeys but does NOT remove it from gathered — originsOf k gains a second entry, check 2 still fires, check 1 NOW fires fleet-wide. The document's own sentence three paragraphs down states why. Ordinal also wrong (registering makes row 2's remedy apply, not row 1's). STING: §11's gathered-arm fixture must assert the remedy substring — written against this cell it pins a NON-remedy.
· F3: both checks are builtins.any (Bool, no witness) while both messages interpolate <key>/<origins>/<node> — the section's OWN rule ('a message naming a thing its own predicate does not have'). REPAIR: colliding = builtins.filter … siblingNames; refuse iff colliding != []; render over colliding — also settles the unaddressed both-siblings case.

INSTRUMENT: F4 — ledger's round-11 F4 record states the PIN's E5 live figure as 9; measured at pin 6dc4d44: 9 raw/8 LIVE (HEAD: 10 raw/9 live). §8 core and script both correctly say 8 at pin — the LEDGER PROSE carries the HEAD value: law-41 drift inside the record that was about pinning, and the script cannot catch it (checks core + own literals, never ledger prose). F5 — B23's SUM row telescopes: live + (raw−live) + (all−raw) = all = the first B23 row; substituting live=6 leaves it green. The partition IS pinned by rows 1-4; the caption claims what the row does not check. Controls: B3c and B15's raw−live-vs-constant rows DO discriminate.

STATEMENT: F6 — §8 has no round-11 re-check paragraph against its own standing rule; undispositioned: operands with label/remedy payload (adjacent to entry-5's provenance rule — likely admissible as diagnostic-only on an aborted path, but the entry's rule is a contact leaves a trace), siblingBuilders (round-10's admissibility ground 'attrNames of a SHIPPED attrset' drifted — siblingBuilders is new to the design), originsOf. F7 low — §9.2.1 byte-neutrality cites :1030-1036; operands are :1034-1036 (cite by expression). PLUS gate qualification recorded: F2-placement justification overstates ('the shadowed consumer is precisely the one that never demands it' is not check 1's failure mode — a fleet with no wrapped class modules has no consumer to shadow; placement strictly stronger anyway, argument louder than grounds — temper it).

REFUTATION ATTEMPTS THAT FAILED (carry into ledger so not re-litigated): F1 biconditional HOLDS (// is key-set union, fold over exactly operands; multi-origin message renders every origin so the winning writer is always among them); fold-seeding byte-neutrality HOLDS (head-seeded = exactly two // applications = shipped :1034-1039; {}-seeded adds a third); row-2 remedy executable, key-set claim exact; F2 placement delivers fleet grain (lambdas node-independent), removed per-node attrNames real at 948ebe7, seq-on-systems fires at the real structure (A18 quoted correctly); fleet-split arity-1 correct for its predicate, both-origins key terminates (check 1 aborts first, then check 2 on the residue); B15 correction discharged (88/12 files/71 live/17 comments, §2.4.3 moved with it); E5 provenance disposition SOUND (the F5 class-sweep table row IS its cell; no new cell needed; script's own note understates this).

DOWNSTREAM READINESS: §2 construction UNTOUCHED this round; §9.4 landing order UNAFFECTED. All three construction findings land in the CONTENT of step 1 (dcx's records binding surface). ⇒ dcx does NOT start against §9.2.1 as written; c3m/3w6/1kd/i5m depend on §2 — the gate chain is NOT held by this round's findings.

Gate coverage limits: §9.1-9.5/§8/§2.0/§2.4.3/§2.6/A11/script/ledger-header+F3-F5+sweep-table in full; pin reads output-modules :900-1060/:1225-1290, structural :95-140/:180-330, default :930-960/:1205-1232; §1, §2.1-2.4.5 bulk, §3-§7, §10-beyond-A11, B-cells unread (script-verified only); no fleet evaluated; finding 1 is a source read, no systemViews-channels fixture built.

### 29 — 2026-08-01T00:49:21 · Jason Bowman

★★★ ROUND 12-FIX AUTHORED, papers main 4547777 (core d51b0e6f/3794, ledger a78980fe/1846, script f90dd7e2/453). REGISTER 131/0/7 EXIT 0. All seven gate-12 findings discharged at class.

★ F1: gate's repair adopted AND THE CLASS SWEEP FOUND THE SAME DEFECT ONE ROW OVER — surfaces.values = genAttrs (attrNames (local // gathered)): only gathered has a channelGather supplier; local's key set is EVERY COMPOSED CHANNEL (gen-pipe outputs.at emits per dag.channels), carrying channels a quirk's ops or a policy route/join/tee DERIVED — owned by the op's author, neither round-11 owner. ⇒ THREE OPERANDS, FIVE ORIGINS, split on owners ? k / inherited ? k / gatheredAt ? k / localKeys ? k. Biconditional preserved: added ? k ⟺ owners ? k because both fold the same finalActs on the same e.key (structural.nix:215-216/:288-294); green-case cost zero (both discriminators are already-forced memos). Sweep: 6 origin rows checked against operand construction — only the two //-merged operands failed.
F2: escalating alternative DELETED not reworded; all ten remedies executed against their own predicates, the deleted one the only FAIL; §2.3.1 law (b) one-kind form re-affirmed correct (two-kind would be WRONG, round-6 S10); multi-origin double-remedy rendering = the rule working, not a second F2. F3: both checks now builtins.filter with witness lists; both-siblings case = ONE abort enumerating every colliding sibling (throw takes one string). F4: ledger prose corrected (pin 9 raw/8 live, HEAD 10/9); class sweep re-ran EVERY round-record prose figure at its stated rev — all reproduce, E5 sentence was the sole defect; §8 HEAD phrasing tightened. F5: SUM row deleted; sweep found ONE MORE telescoping row (DOC breakdown vs literal) repaired to compare two measured quantities; ★ BOTH repairs FALSIFIED ON A SCRATCH COPY (injected builtins.any fires the sum row; literal bumped in lockstep leaves it failing ALONE, 128/1); the three raw−live difference rows KEPT with the ERE-vs-BRE divergence argument. F6: round-11+12 re-checks written; siblingBuilders ground restated (key set is a literal the document owns); operands payload admitted diagnostic-only; ★ ONE GENUINE NEW CONTACT: owners.${k} makes §9.2.1 a third reader of __policy — recorded as inside register entry 4's undischarged ownership pass. F7: cited by expression; ★ RE-RUNNING THE CITATION SWEEP FOUND FIVE MORE DRIFTED RANGES, FOUR WRITTEN THIS ROUND WHILE DRAFTING F1 (law 46 live: a sweep's own edits stale its citations); ten further ranges correct, one narrowed.

COLLATERAL (in-class, register-pinned): A11 header 'Four arms' had survived rounds 5-11 while the list grew to seven — now checked rows, arm-count row falsified independently; §9.2 sizing five → SEVEN sites (round 11 specified check 1's seq and never entered it in the sizing table); §2.2a +4 rows, its §9.2 precondition row audited a predicate §9.2.1 had replaced.

OUT-OF-CLASS TREE FINDINGS (filed as beads): channelNames-not-subset hazard; systemViews-shadows-suppressedPolicies silent vanish. Gate's failed refutations carried into the ledger; register's E5 note corrected (the F5 sweep-table row IS the cell).

### 30 — 2026-08-01T01:01:18 · Jason Bowman

★★★ GATE ROUND 13 — VERDICT: CONSTRUCTION-CLEAN (first on this track). Artifacts stable (d51b0e6f/a78980fe/f90dd7e2 at 4547777); REGISTER REPRODUCED 131/0/7 EXIT 0; law-45 control differs both ways (354/507) — pinning live. §2 construction UNFINDINGED THIRD ROUND RUNNING; §9.4 landing order untouched; ★ §9.2.1's checks RULED LANDABLE for dcx step 1 (every edit site in output-modules.nix matching step 1's stated scope; byte-neutrality by identity of the // chain; B20 measures corpus collision surface 0 with two live controls — the refusal does not fire on this corpus). NOTE: the gate's 'clean round 1 of 2' exit-clock framing is void per the economics ruling (no auto-settle; exit is an owner/orchestrator judgement) — its verdict and findings are unaffected.

REFUTATIONS THAT FAILED (verified at source, do not re-litigate): five origins are a COVER not a partition AND THE DOCUMENT CLAIMS COVER — sound: added ? k ⟺ owners ? k holds (both folds over finalActs on e.key; the owners-can-throw asymmetry neutralised by seq at :297); localKeys = keys(local) EXACTLY (keys(received) ∪ keys(derivedBaseNames)); originsOf concatMaps ALL sub-origins of ALL present operands so every overlap pair renders both; all five remedies clear their own origin, none grows the set (derived-channel remedy: renaming the composed channel removes k from received→local→surfaces.values); five origins map bijectively onto §11's five acceptance arms. Witness lists: two-element different-origin case covered (one clause per element over its own originsOf); escaping non-issue in extent (sibling names are keys of a two-key literal the document owns). Round-12's OWN citations swept CLEAN at the pin (17 ranges) + all ten E5 HEAD coordinates verify at 02d47bc — F7's re-drift class did not recur. A11 arm-count row fires ALONE (exhibited on scratch: one inserted bullet = pass 130 drift 1). Scale priced correctly at N≈8000 (sub-origin reads let-lazy, reachable only from an already-aborted render — abort-path only).

FINDINGS (none construction):
· F1 INSTRUMENT: two of three kept raw−live difference rows TELESCOPE and the keeping comment's argument covers only B23 — B3c's pattern has NO metacharacter (BRE≡ERE, raw_c ≡ row (ii) identically); B15's minuend row is cgnE = same ERE as raw_c (not BRE at all). Exhibited: all three pairs agree exactly, B3c/B15 necessarily. The exact class round-12 F5 opened, kept on an argument covering one of three.
· F2 INSTRUMENT: the repaired DOC breakdown SUMS row has no independent failure mode (stated side = another row's actual side; components each pinned) AND its comment claims two failure modes it lacks — falsified by exhibition (compensating relabel: FIRE and NEG rows fire, SUMS row PASSES, 129/2). Weaker than the deleted tautology (conditional on four rows) but same admissibility test.
· F3 STATEMENT: the remedy LAW is quantified at a strength the remedies don't meet ('following it makes base ? k false' — on a multi-origin key NO single remedy does, as the document itself states three paragraphs earlier); the ledger's own sweep table applies the weaker correct version (header names base ? k, cells say CLEARS THAT ORIGIN). Correct operational rule, one sentence, both artifacts: each remedy strictly SHRINKS the origin set, never grows it; the rendered remedy SET followed in full falsifies the predicate. Domain-wider-than-discharge class, landing in the round-12 text that convicted round 11 of the same shape.
· F4 STATEMENT: <siblingNames> interpolated with NO JOIN stated — siblingNames is a LIST; literal "${list}" throws a coercion error, replacing the named refusal with the exact failure shape the section is about; §2.3.1's commitmentFieldsOf spells concatStringsSep for the identical job. Statement-level because every fenced expression is correct and §11's five arms exercise the abort (a coercion error fails the gating fixtures rather than shipping); the F3 discharge table checks SCOPE at render sites, never TYPE — why its own sweep missed it. Minor unranked: §8 entry-4 disposition says __policy is in the EIGHT-unclassified pass; register lists it among the SEVEN kernel-written (conservative direction, fails safe).

DOWNSTREAM: dcx NOT held; §9.2.1 landable content for step 1. Gate coverage limits: §8/§9.2.1/§9.3-9.5/A11 arms/script/ledger-F2-F3-F4 in full; §§0-7+§10 NOT re-read this round (§2's unfindinged status rests on §8 dispositions + round delta, not fresh derivation); 7 nix-eval skips not run; falsifications on scratch copies, papers unmodified.

### 31 — 2026-08-01T01:03:28 · Jason Bowman

GATE ROUND 13 — CORRECTION (from the gate itself, unprompted; verdict and all four findings UNAFFECTED). Its coverage sentence 'papers status clean, md5s unchanged at END' was half-measured: md5s unchanged TRUE and re-verified (the load-bearing half — the reviewed text did not move); 'status clean' FALSE — papers HEAD moved 4547777→088b093 during the review (two sibling-track commits: unification r25, D1 r9; git diff --name-only shows ZERO ops-seam paths) and one pre-existing untracked .bak. Register re-run at the moved HEAD: same 131/0/7. Supported claim, substituted: the gate made no modification (falsification mutations ran on scratchpad copies with DOC_DIR redirected). The gate flagged this itself as finding-3's shape turned on its own report — a statement quantified wider than what discharges it — and law 41 applied to the artifact but not its own coverage section. Recorded as an instance of the class; no re-review needed.

### 32 — 2026-08-01T01:28:41 · Jason Bowman

★★ ROUND 13-FIX AUTHORED, papers main f7102a7 (core 963c6506/3831, ledger 4697c753/1996, script 20ee3387/501). REGISTER 128/0/7 EXIT 0 bare-run (count 131→128: three telescoping rows DELETED per the deletion rule, not patched). All four gate-13 findings + minor discharged at class.

F1: gate confirmed at the pin (B3c BRE≡ERE exhibited on a line a metacharacter difference WOULD split; B15 same ERE both sides) — both rows deleted, partition pinned by rows (i)-(iii); B23 KEPT with its divergence EXHIBITED not asserted ('builtins tryEval' — BRE 1, ERE 0, strict superset, fails alone). Class sweep enumerated MECHANICALLY (grep for command-substitution row forms): every derived row now carries its command pair + can-it-diverge answer; two kept SUMs each have an independent-failure exhibition against the SHIPPED register (127/1, that row alone, both). F2: row + false comment deleted; the gate's compensating-relabel exhibition reproduced exactly (129/2 on the r12 register — figure explicitly marked as measured against the r12 register since the row no longer exists); recorded that a sum row's second claimed mode is impossible by construction. F3: law restated in BOTH artifacts (strictly SHRINKS the origin set, never grows; the rendered SET falsifies the predicate); sweep 14 law sentences — 12 match, 1 the finding, 1 flagged CONSERVATIVE with the measurement anyway (bare-kindOf family is real and wider than the table's three; the proxy predicate itself undercounts — misses the kindOf ( application form at policy-recover.nix:89, one of the table's own three). F4: both placeholders spell concatStringsSep; the two 'joined'-without-naming placeholders now name theirs; sweep over all 12 placeholders with TYPE as the recorded second predicate; ★ positive control from the SHIPPED tree: lib/errors.nix emitsUndeclared renders concatStringsSep at the pin — the kernel's own convention is the one F4 imposes, so the omission was a defect not house style. MINOR: entry-4 lists corrected as written (__policy in the SEVEN kernel-written; __pipeMark noted as one of the EIGHT unclassified).

OUT-OF-CLASS (reported): (1) ★ stated pass=N figures have NO guard — nothing re-runs the register's clean baseline, so adding a row silently drifts every quoting sentence; law 41 one level out; class open. (2) future bare-kindOf census needs a wider predicate (application form). (3) ★ DELETING a register row silently falsifies every ledger sentence that COUNTED it — two such sentences caught and corrected only by re-reading; the pattern named.

SEQUENCING: gate round 14 HELD until impl-ops-seam-step1 (dcx step 1, working from the 4547777 blob with the four erratas) reports — one gate round then reviews the 13-fix text and the implementation contact together.

### 33 — 2026-08-01T01:30:03 · Jason Bowman

★★★ IMPLEMENTATION CONTACT — dcx STEP 1 LANDED GREEN + TWO IC FINDINGS. Commits 4fd8fd5 (feat, 5 files) + 0f9f316 (test, 3 files) on den-hoag main, UNPUSHED pending gate 14. Baseline measured (matches expected): ci 2071/2093 = 9❌+13☢️=22, parity 71/71. After: red set BYTE-IDENTICAL (sorted diff zero lines), ci 2083/2105 (+12 new arms ALL GREEN incl. both decls-writer systemViews arms, gathered ×2 pinning the supplier remedy, escalation exhibit, non-vacuity control), parity 71/71, format gate exit 0. All seven §9.2 sizing rows in output-modules.nix; erratas applied (concatStringsSep renders; no register-it alternative).

★★★ IC-1 (CONSTRUCTION, FAIL-OPEN, survived gates 11-13): every ?-based fenced predicate spelled  — Nix reads the LITERAL key "k", not the variable. Affects colliding, originsOf's filter, all four sub-origin reads. On any base without a key literally named k — every real fleet — witness lists empty, THE WHOLE REFUSAL NEVER FIRES: the exact silent fail-open the section exists to close. Probe with control: over base = { channels = 1; k = 99; },  → both names (wrong);  → channels only (right). Discriminator that it is notation not design: check 1 is spelled , correct. Implementer applied the forced reading  (exactly one spelling under which the predicate computes what its own prose defines) and flagged. ★ ORCHESTRATOR RULING (theory-grounded, no owner fork — no design freedom exists): the forced reading is RATIFIED; the spec's fences carry a notation defect to be corrected at the next fix round; the gates' miss is the reading-gates-verify-sections class — a fence's SEMANTICS were reviewed as prose intended, not as Nix parses.
★★ IC-2 (the §10 A11 gathered-arm CONTROL contradicts check-1's forcing position): 'registering the colliding gathered key must still abort carrying BOTH origins' is UNOBSERVABLE — registration puts the key in channelNames, collidingRegistered goes non-empty, and row 6's systems seq aborts BEFORE bindingsAt is reached; the per-node both-origins message is unreachable on exactly that input. Sections written at different rounds; control never re-derived against row 6. ★ ORCHESTRATOR RULING (theory-grounded): RESTATE THE ARM, keep the forcing position — the design's own remedy law already establishes that registering ESCALATES (the reason the register-it alternative was deleted), so the expected behaviour on that input IS the fleet refusal; the forcing position is load-bearing (fires on fleets wrapping no class modules, the r11 F2 gain). The implementer built the arm's intent as an escalation exhibit — ratified.

SIZING DEVIATION (judged spec-intent, three stated reasons, ACCEPTED): message builders live in lib/errors.nix (fail 'channel binding' writes the exact fenced prefix; errors.nix is the house home per §2.7's own pattern; errors was a dead formal of output-modules now live). Spec's sizing table owes two errors.nix rows. ERRATA for the fix round: A11 lives in §10 not §11 (several round records said §11); the labels/remedies join separators are unstated (implementer chose ' and ' / '; ').

IMPLEMENTER COVERAGE LIMITS (honest): the FIFTH origin (localKeys — derived channels) has NO witness — needs the composition path that is red at this commit (5 pipe-consume ❌ + 13 den-pipe ☢️); a fixture registering the name would exercise channelKeys instead — NOT faked, stated in suite header, discriminator covered only by the source totality argument. Byte-unwrapped not directly observed (indirect via 2083 greens). parity ledger.md deliberately keeps the old name (historical record). §9.2's producer.scope acceptance belongs to step 2 (nix-config), unchecked.

NEXT: round 14-fix (papers) corrects IC-1's fence notation + restates the A11 arm per the IC-2 ruling + absorbs the errors.nix sizing rows + separators; THEN gate 14 reviews 13-fix + 14-fix + this implementation together. Push of 4fd8fd5/0f9f316 held until gate 14.

### 34 — 2026-08-01T01:30:48 · Jason Bowman

CORRECTION TO THE PREVIOUS COMMENT (shell substitution swallowed every backtick-quoted expression — the IC-1 notation itself was lost; this comment carries the exact spellings; instrument note: zsh command-substitutes backticks inside double quotes, so bd comments carrying code must be passed via file):

IC-1's defect, exact: the spec's fences spell the sub-origin predicates as
    attrs ? k
which Nix parses as a test for the LITERAL attribute named "k". The correct spelling, and the one the implementer applied, is
    attrs ? ${k}
i.e. dynamic attribute interpolation. Affected fenced expressions: colliding = builtins.filter (k: base ? k) siblingNames; originsOf's filter (o: o.attrs ? k); and all four sub-origin reads owners ? k / inherited ? k / gatheredAt ? k / localKeys ? k.

Probe with positive control, exact: over base = { channels = 1; k = 99; }:
    builtins.filter (k: base ? k)      [ "channels" "settings" ]  =>  [ "channels" "settings" ]   (WRONG — matches the literal "k" member, both survive the filter)
    builtins.filter (k: base ? ${k})   [ "channels" "settings" ]  =>  [ "channels" ]              (RIGHT)

Discriminator that this is notation not design: check 1 is spelled builtins.elem k channelNames — a function-position use of the variable, immune to the trap — and it is correct in the same fences.

RULING RESTATED (unchanged in substance): the forced reading attrs ? ${k} is RATIFIED; the fence notation is a spec defect for round 14-fix; the miss class is reading-gates-verify-sections (a fence reviewed as the prose intended, not as Nix parses).

### 35 — 2026-08-01T01:33:09 · Jason Bowman

STEP-1 ADDENDUM: third commit 5d6923c (fix(kernel), text-only) — the implementer verified the 4547777 pin blob byte-identical to what it read (everything landed from the pinned content), diffed 4547777→f7102a7 anyway, and aligned two text items the 13-fix settled: the sibling-names join (now the stated concatStringsSep ", " bare-names form) and the remedy-law quantifier in its builder commentary + fixture comment (its CODE was already at the correct strength — no escalating alternative, every origin rendered). Re-verified on the new HEAD: red set byte-identical, ci 2083/2105, parity 71/71, format 0, siblings suite 12/12. den-hoag now carries THREE unpushed step-1 commits: 4fd8fd5, 0f9f316, 5d6923c. Implementer stood down; writer slot passed to the unification §4.3 lane. ORCHESTRATOR PROCESS NOTE (mine, for the close): my amendment message REVIVED the retired implementer into a writer slot I had already reassigned — SendMessage resumes a done agent; a message to a retired implementer whose repo slot moved must carry an explicit stand-down or not be sent. No damage (disjoint files, text-only) — the class is real.

### 36 — 2026-08-01T01:57:45 · Jason Bowman

CORRECTION TO THE STEP-1 ADDENDUM (orchestrator error, caught by the §4.3 implementer's independent measurement — law 46: I relayed the step-1 implementer's "text-only" self-description without measuring it, and my file-set description was wrong):

1. 5d6923c touches lib/errors.nix and ci/tests/channel-binding-siblings.nix — NOT output-modules.nix (zero hits in its stat; my earlier comment named the wrong file).

2. "No predicate or expression moved" is FALSE. lib/errors.nix:53 changed:
   -  renderSiblings = names: builtins.concatStringsSep " and " (map (n: "`${n}`") names);
   +  renderSiblings = names: builtins.concatStringsSep ", " names;
   Both the separator and the per-name backtick wrap moved — the rendered tail of the two shadow-refusal messages (errors.nix:454, :474) changes observably. The change was DELIBERATE (aligning to the 13-fix's stated join) but it is an expression change, not comment wording; the test half of the commit is comment-only, which is where the "text-only" reading came from.

3. "Suite state unchanged" is TRUE (independently verified: 2083/2105, 22 red, parity 71/71) but NOT BECAUSE the commit was text-only — BECAUSE THE RENDER IS UNCOVERED: git grep 'sibling names are' -- ci returns ZERO, while the same suite pins OTHER substrings of those two messages (channel-binding-siblings.nix:207/:219 pin 'binding SIBLING this surface appends') — the instrument can see message text, it just never looks at the join. Accurate statement: AN EXPRESSION CHANGED AND NOTHING MEASURES IT.

CONSEQUENCE (dcx lane): the A11 fixture obligations owe one join-pinning assertion — the spec now states all three joins (siblings ", " bare; labels " and "; remedies "; "), and a stated render with zero coverage is exactly the drift channel the fixtures exist to close. Relayed to the round-14-fix author for the obligation row; the test edit itself lands with the next dcx unit. Nobody may lean on "5d6923c was text-only" to skip re-measuring a render.

### 37 — 2026-08-01T02:11:17 · Jason Bowman

** ROUND 14-FIX AUTHORED (one bounded addendum pending — the mid-round A11 join-pinning obligation did not land, verified by artifact grep, author revived; SECOND missed mid-round relay this session, law 3's verify-the-artifact backstop working as designed). papers main b3045d9 (core aeadce05/4088, ledger f16158ef/2270, script ff564a5e/598). REGISTER 141/0/7 EXIT 0 (+13 rows).

IC-1 DISPOSITIONED: six fenced sites corrected to the interpolated form + the five-origin table's test column (4 cells — executable text, not fence); B29 probe with the discriminating third cell (base with no attr named k = every real fleet: literal form selects NOTHING); corrected fences EVALUATED (parse + semantics). Class sweep 17 rows, every ? in the core with intent stated; positive control: 8 sites already correct (all quotations of shipped tree code); ★ ONE MORE IN-CLASS DEFECT FOUND: §2.3.1 prose disagreed with its own fence 11 lines below — repaired. ★ CONSEQUENCE BEYOND FENCES: §2.2a's TOTAL-ON-BOTH-AXES verdicts for rounds 10-12 were false on the KEY axis — three verdicts struck and re-scored; §2.2a gains a SECOND AUDIT AXIS (value-side loop never asked does-the-expression-as-spelled-compute-it — why six rounds passed over IC-1). Law-42-shaped register block (regional enumeration + sum row EXHIBITED failing alone, 140/1).

IC-2 DISPOSITIONED: arm restated as the fleet-refusal escalation (round 12 added row 6 and the arm in the same round, never composed them). ★ DOMINATION MEASURED AND THE AUTHOR'S OWN FIRST DRAFT OVER-CLAIMED: 'strictly ahead of bindingsAt on every path' FALSE — transitive read over all 9 exports: systems (seq-guarded) AND projectClass (NOT guarded, via projectClassScoped → bindAtSourceScope → bindingsAt) reach it; exception written into §9.2.1 not smoothed. Class sweep: all 15 §10 arms re-derived against CURRENT forcing positions (two changed; positions written down for the first time; standing rule at §10's head).

SIZING RATIFIED seven→NINE sites two files (errors.nix rows 8-9 with the three grounds incl. dead-formal measurement: errors. 0 hits vs prelude. 29 control). ★ OUT-OF-CLASS FOUND AND FIXED IN-CLASS: the sizing HEADING read 'one file, FIVE expressions' rounds 11-13 while the table carried seven — A11's Four-arms drift one heading over; three register rows now (heading/table-count/prose-count), no equality row.

ERRATAS: joins — the real gap was the CLAUSE envelope ('joined' with no separator; F4 swept placeholders not the message, also list-valued); four joins stated (labels ' and ', remedies '; ', siblings ', ', clauses ' '), implementation as referent. §11's-A11 → §10 at four sites with a non-blanket control. ★ Status line said 'unimplemented' after step 1 landed — register checked the round number, never the adjective; now carries implemented SCOPE as a row.

★★ B30 — IMPLEMENTATION RE-MEASURED FROM GIT ARCHIVES, NOT CARRIED, AND THE METHOD IS THE FINDING: in-place nix-unit reads the WORKING TREE — with the concurrent §4.3 writer's dirty class-modules.nix it returned 1277/2105, 806 PHANTOM REDS SILENTLY. (The standing pin-git-archive-snapshots law, rediscovered live at scale.) Archive figures: pre 2071/2093, post-5d6923c 2083/2105, red-set diff EMPTY, A11 12/12, parity 71/71, rename holdout = parity ledger only. ★ The 22 non-green ENUMERATED (13 den-pipe ☢️, 5 pipe-consume, 2 projection relocation anchors, 2 unrelated) so the debt row cannot be read as '18 reds in tree'. Acceptance-debt row written (localKeys witness, evasion named).

REGISTER RESTRUCTURE: law-45 control's HEAD arm was a stated WORKING-TREE figure (concurrent writer moved it 507→639) — both arms now read COMMITTED revs, assertion is INEQUALITY vs 'differ' (the control's actual requirement), figures print as notice. Telescope table extended.

OUT-OF-CLASS (reported): (1) projectClass not seq-guarded — fleet refusal does not dominate bindingsAt absolutely; not a live consumer path (A12 anchor witness export); recorded in §9.2.1+ledger; (2)+(3) the concurrent-writer window and the third step-1 commit — both known and resolved (den-hoag clean at d0e9d4b, .beads only).

### 38 — 2026-08-01T02:14:48 · Jason Bowman

14-FIX ADDENDUM LANDED, papers 2da287a (core 753fce32/4137, ledger de520fb8/2313, script c2ae0a64/616). REGISTER 146/0/7. The relayed gap RE-MEASURED (figures reproduce: 'sibling names are' 0 in ci/, control 2 hits, 7 pinned msg substrings) AND WIDENED: all seven pinned substrings are SINGLE-ORIGIN renders — labels ' and ' and remedies '; ' are unasserted for a stronger reason than oversight: NO LANDED ARM PRODUCES A KEY OF ORIGIN ARITY ≥ 2; the multi-origin render (the message the five-origin split exists to serve, carrying 'moving only one leaves the collision standing') has never been caused to be built by any test. ★ NEAR-MISS RECORDED: :269 pins '…declaration key AND the name of a binding SIBLING' — that AND is the template's own literal between clauses, NOT renderOriginLabels' ' and ' between two labels; reads as join coverage by eye, is not; anyone discharging the obligation hits it first. OBLIGATION ROW written into §10's A11 with three discharge notes: (1) labels+remedies need a NEW FIXTURE (a key both enriched AND inherited — origin rows 1-2, no red path, same grain as the landed enrich arm), not a new assertion; (2) the assertion must SPAN the separator (pinning the sentence around the join reproduces the defect one word over); (3) the clause join needs a two-sibling collision in ONE fleet (landed registration arms collide on channels and settings in SEPARATE fleets — the one-abort enumeration is specified and unwitnessed; highest-value: its failure mode is a MISSING OWNER not a misformatted string). Framed as obligation not defect (5d6923c moved the render TOWARD the stated form; the wrong thing is an expression change to a render shipping with zero measurement — same class as IC-1 and F4, reached through the renderer). Five register rows pin the spec side of the contract; provenance attributed to the §4.3 implementer's independent check; superseded core digest NAMED in the ledger (the round-12 boundary error not repeated). Ops-seam artifact set FINAL for gate 14.

### 39 — 2026-08-01T02:18:20 · Jason Bowman

RECORD CORRECTION + ADDENDUM 2 BANKED. My 'second missed mid-round relay' claim was WRONG — messages CROSSED: the 2da287a report (join obligation + widening) was sent BEFORE my addendum request arrived; the obligation had already landed. Session relay tally corrected: ONE missed relay (unification IC-7) + one crossed pair (this). ★ The author's handling is the model for the crossed case: could not tell whether its report had been seen, so it VERIFIED THE TREE before acting (grep for the obligation block → 1, join rows → 5, tree clean) rather than re-running the edit blind — which would have produced a duplicate obligation block. The addendum request still yielded ONE real delta, landed as 4d88280: 2da287a never used the word DEBT nor named the count it is debt against — now written as 'of the 12 arms landed at 5d6923c, ZERO pin a join; discharges with the next dcx test unit'. ★★ CLASSING SURFACED A STRUCTURE: §10 carries TWO acceptance debts DIFFERENT IN KIND — localKeys (blocked on another defect; its red suite is its own reminder) vs the joins (blocked on NOTHING, fixtures writable today at the landed enrich arm's grain, outstanding only because no round asked) — the UNBLOCKED debt is the more forgettable one, so both are written at the same weight and the debt COUNT is a register row (a debt discharged without label removal, or a third added unlabelled, moves it). Row-vs-prose answered: ROWS — six for the addendum (four join-stated rows, the obligation row, the debt count). FINAL ops-seam artifact set for gate 14 (updated to the gate in flight): core dd4e072f/4146, ledger 81831fe2/2322, script dcecb934/622, papers 4d88280, REGISTER 147/0/7. Core digest re-taken three times this round with both superseded values NAMED as superseded. Commit subject extended by the author to describe the actual commit — correct, no amendment.

### 40 — 2026-08-01T02:33:58 · Jason Bowman

** GATE ROUND 14 (spec + implementation, first impl-in-scope round). SPEC: PROCEDURAL BOUNCE — artifacts moved mid-review (the 4d88280 addendum landed after the gate's START sample; my re-pin message arrived mid-flight; the gate's STOP discipline held). On everything verified at BOTH states: NO construction finding in the spec; both register runs clean (146/0/7 pre, 147/0/7 post; the drift touched only §10's debt paragraph + one row — measured by git show). IMPL: REVISE — one construction finding.

F1 [IMPL, CONSTRUCTION, C6 + §10's own non-vacuity rule]: the IC-2 escalation exhibit (channel-binding-siblings.nix cell registeringEscalatesToTheFleetCheck) is SATISFIED BY AN ABORT IT DOES NOT CAUSE. aborts = bare tryEval boolean, no message channel. Two mutations on a clean 5d6923c archive, suite 12/12 green before each: remove the gather -> STILL GREEN (the abort comes from quirks.channels alone — the same input and abort :198 already pins by message); remove the registration -> STILL GREEN (cannot distinguish fleet from per-node refusal). Both halves of IC-2's restated observable unwitnessed. Verbatim the hazard §10's additive-arm bullet legislates against, landing on the arm IC-2 was written to repair. DISPOSITION: rides the dcx test unit with the join debt; the spec owes a THIRD acceptance debt row (or a fix directive: message assertion on check 1's text + a fleet that does not abort without the gather).

F2 [SPEC, STATEMENT]: IC-2's domination chain is FALSE while its conclusion is exact. Re-derived mechanically over all 50 top-level bindings: nine exports, exactly TWO reach bindingsAt (systems seq-guarded; projectClass not) — conclusion reproduces. But the exhibited path "projectClass -> projectClassScoped -> bindAtSourceScope -> bindingsAt" does not exist: bindAtSourceScope is a CONSUMER of projectClassScoped's output, applied inside the systems machinery. Real chain: projectClass -> projectClassScoped -> routeRemapFor -> remapOver -> placeRemapped -> bindingsAt (:556). NARROWS THE EXCEPTION: placeRemapped is reached only through the route-remap leg, and a native fleet emits no route => on a route-free fleet projectClass does not force bindingsAt at all — the exposure is route-conditional, not unconditional. Same class as IC-1 one level up: reads correctly as English, names a mechanism that is not there.

F3 [INSTRUMENT]: the ledger's boundary digest named dd4e072f as current while 753fce32 shipped — written before the commit it describes; reconciled four minutes later by the addendum. The law-41 corollary is digest-taken-LAST; recorded.

Minor: §9.2.1's unreachable empty-origin render says "names all five as candidates"; the landed fallback emits ONE origin record whose remedy string enumerates the five — substantively discharges, arity differs from wording.

VERIFIED CLEAN (extensive): IC-1's repair complete in spec AND code (zero bare ? <ident> in fences with ?${ control 6; zero executable ? k in lib/+ci/ — 7 hits all comments, control 9 in output-modules alone; THE CODE WAS NOT WRITTEN FROM THE PRE-FIX ERRATAS — carries the correct form throughout); B29 all four cells reproduce; §2.2a strikes/replacements right; all four joins implemented; join debt correctly measured (0 with live controls); all nine sizing sites exist as specified; rename holdout exact; B30 independently reproduced from a clean archive (2083/2105, red composition exact, A11 12/12, parity 71/71 — pre-landing snapshot + byte-identity diff rest on the author's run); register entries 4+5 re-censused ON THE TRUE ISOLATE 02d47bc..5d6923c (step 1 adds ZERO new __ keys in lib/, zero new __action sites; the gate's first census returned a false zero from grep -E '^\+' — an invalid quantifier — caught by positive control and re-run); Q7 census intact; the 15-arm table correct as spec artifact.

★★ §2 READ IN FULL — the four-round disclosed hole CLOSED: no construction finding; "the strongest part of the document" (C6 genuinely discharged per-wiring; C7 no bad intermediates; the ceiling ladder honest — NONE-closed as a list because the arithmetic drifted twice; the law-(a) position a real derivation via message-fidelity + caller-sharing; §2.2a's second axis the right generalisation of IC-1, neither axis subsuming the other).

DOWNSTREAM RULINGS (orchestrator, acting on the gate's clearances): (a) PUSH CLEARED for the step-1 commits — F1 is a test that over-claims, not shipped behaviour; pushing through 5d6923c now; d0e9d4b (the other track's §4.3 landing, disjoint files, not in this gate's scope) HELD for unification gate 24. (b) dcx steps 2-3 not blocked; §9.2's producer.scope precondition correctly a stated obligation on dcx. (c) Of the gated beads, F1 blocks only an unblock conditioned on the gathered-arm control's discharge — none is. Round 15-fix dispatched for F2/F3/third-debt.

Gate coverage limits: bounce dominant; §3-§7/§9.1/§9.3-9.5/§11 + §10's A1-A10 bulk unread; no corpus measurement (nix-config unopened); F2's closure over-approximates reachability (conservative for the seven negatives; both positives confirmed by reading call sites); no fleet eval for the producer.scope precondition.

### 41 — 2026-08-01T02:38:48 · Jason Bowman

GATE 14 ADDENDA PASS — F3 WITHDRAWN BY THE GATE, VERDICT REVISED: SPEC REVISE (no longer a bounce; no construction finding in §2/§9's core), IMPL REVISE (F1 stands alone). The withdrawal: at every commit the ledger matched its own core and never named an unshipped digest — the gate sampled between two legitimate commits and read post-addendum ledger against pre-addendum core; its stated method correction: 'a named commit with a reconciling ledger is not drift; re-sample and diff the commits before classing'. TWO NEW FINDINGS: ★ F4 (CONSTRUCTION, in the addendum's own discharge instruction): §10 note 2's worked example is UNRENDERABLE — backticked order-inverted substring the implementation cannot produce (renderSiblings' backtick wrap was removed BY 5d6923c, the commit the adjacent paragraph endorses; attrNames SORTS → channels, settings); the note whose content is 'span the separator' exhibits a substring that spans nothing because it does not occur — following the practice the note FORBIDS at least matches; following what it PRESCRIBES does not. F5 (INSTRUMENT): the debt-count row's comment states the INVERSE of its predicate's power — both stated triggers (unlabelled third debt; discharged-label-left) are exactly what a fixed-string line count cannot see (first demonstrated empirically); it catches the complements; the forgotten-unlabelled-debt risk it was written for is guarded by nothing. ★★ THE PASS ALSO BUILT BOTH DISCHARGE FIXTURES LIVE on a clean 5d6923c archive and captured real aborts: the ENTIRE join debt is dischargeable by TWO fixtures (multi-origin systemViews+enrich fleet; two-sibling quirks fleet), specified to exact pinnable substrings, with note 1's under-claim corrected (multi-origin covers THREE of four — every check-2 message carries the sibling clause) and note 3 verified live (one abort, two clauses, ' ' join). Two-debt structure VERIFIED (both labels, different kinds, blocker confirmed red; count row's $GREP pin measured load-bearing — GNU lines vs ugrep occurrences on a two-match line). B29 third-cell + register + den-hoag clean re-confirmed. DOWNSTREAM UNCHANGED: push not blocked (already executed through 5d6923c); F1 + join debt share one dcx test-unit discharge slot, now specified to the substring. 15-fix author's brief updated in flight (F3 withdrawn→hygiene, F4/F5 added with the fixtures, the owed §10 exhibited-substring sweep assigned).

### 42 — 2026-08-01T03:02:12 · Jason Bowman

** ROUND 15-FIX REPORT (commit af3f267 already integrated + pushed with the papers batch). REGISTER 157/0/7 EXIT 0 (+10). Core dd4e072f/4146 -> 642e38c6/4299; ledger -> 6aab759b/2502; register -> 2e2d96f8/676.

F1 ACCEPTED + REPRODUCED, and ★★ THE DISCHARGE IS NOT THE DISPATCHED ONE, MEASURED: the dispatch's second half ('a fleet that does not abort without the gather') is UNSATISFIABLE at 5d6923c — check 1's predicate (collidingRegistered = filter (elem k channelNames) siblingNames, output-modules :1077) reads NOTHING any gather writes, so every sibling-registering fleet aborts with or without the gather. The third debt therefore specifies a PAIR OF GRAINS (check-1 text on the registered+gathered fleet, paired with the gather-only fleet's check-2 text = arm 10), with the mutation-control unavailability written into the debt so the next round does not hunt for it. 'Escalates' is a transition and one endpoint is not one. Debt prose+row 2 -> 3.
★ §10.1 NON-VACUITY SWEEP over the 12 landed arms (hand-run commands recorded — the register reads 6dc4d44 only): 7 STATED / 2 PARTIAL / 2 NOT STATED / 1 VACUOUS (arm 11, both cells — its aborted cell is a telescope that cannot fail unless arms 9+10 also fail). Five of twelve carry a green the spec never argued for; arms 8/10 assert MORE than asked. ★ ARM 10 FIRST TO ACT ON: the new debt's second half IS arm 10, resting on an unargued green one level down.
F2 REPRODUCED with the exception narrowed ONE STEP FURTHER (routed fleets force bindingsAt only for a route with non-empty at and NO eval-time guard — remapOver's other two arms go through argEnvWrap/placeSlice; bindingsAt applied at exactly four sites, the last three under systems). ★ CITATION CORRECTION, ORCHESTRATOR ERROR OWNED: my dispatch's :556/:742 were d0e9d4b coordinates presented as 5d6923c pins — at the pin they are :553/:737; the author verified at all three revs and carried the pinned figures. §10.2 path-claim sweep: nine claims, seven HOLD (each written with a call site in hand), one FALSE (the finding — the only one written from reading what the file must be doing), two marked out-of-domain rather than scored; rule adopted: a → between two symbols is a measured cell, not prose.
★★★ F3'S CITED INSTANCE RE-RUN AND NOT REPRODUCED: at every commit touching the ledger, the boundary sentence names the SAME-commit core blob — six sentences, six matches, zero mismatches (the gate had already withdrawn F3; this is the second, commit-by-commit refutation). Rule KEPT (real structural hazard, one command, practised this round — digest read back from the committed blob) with the false justification RECORDED AS FALSE so a later re-check does not delete a sound rule with it. F3-minor repaired (empty-origin render arity aligned + the join-scoring consequence stated: one of six records renders through neither join).
OUT-OF-CLASS: arm 11 is NAMED for an assertion neither cell makes; the fixture's aborts-helper purpose comment describes the one use the file does not have; core status line omitted 5d6923c (fixed in-class; same shape as the sizing heading and Four-arms header). NEXT ON THIS TRACK: dcx step 2 in flight (nix-config); gate 16 held to review spec + step 2 together; the three acceptance debts + arm 8/10/11 fixes ride the dcx test unit.

### 43 — 2026-08-01T03:11:32 · Jason Bowman

dcx STEP 2 STOPPED AT IC-3 — full record on den-hoag-dcx. Headline: nix-config pins den v1 which CANNOT express arm (ii)'s consumer (identity measured unrecoverable from the delivered value — four byte-identical records, «NO-USER-FIELD» folders, devices=[], the exact §9.2 silent-drop, unavoidable under v1); the den-hoag override route is closed by a NEW kernel refusal (env-to-hosts/accessGroups binds=[], filed separately). RULED: no v1-expressible arm (ii) owed (measured impossible + standing bar); step 2 sequenced behind nix-config-evaluating-under-den-hoag — the corpus chain THIS design unblocks (53.64 → c3m/3w6 → 1kd → corpus green → two-site rewrite lands). dcx blocked-by 1kd edge added. IC-4 spec errata for the next round: §9's nix-config-as-den-hoag-witness premise is false at HEAD (it evaluates on v1 only).

### 44 — 2026-08-01T03:18:44 · Jason Bowman

15-FIX ADDENDA LANDED, papers 97dc978 (core 55ac1d7a/4403, ledger b4871795/2639, register 57a421d1/721; REGISTER 165/0/7; boundary digest verified from the committed blob per rule 3). F3 recorded as WITHDRAWAL with the gate's correction, rule kept AS HYGIENE with the reason stated ('a rule carrying a retracted conviction as justification is one the next round deletes with the conviction'); ★ the render-arity erratum kept SEPARATE from the withdrawal (verified against code — bundling a real repair into a retraction is how it gets reverted). ★★★ F4 REPAIRED BY MEASUREMENT NOT WRITING — new cell B31: git-archive snapshot + 13 sweep arms through nix-unit, 25 arms 21 green, the 12 landed arms green throughout as same-run control; ALL FOUR of the gate's substrings verified green; the two fixtures + note-1 correction folded as specified. ★★★ §10.3's CONDITIONAL ROW, found by no finding: arm 8's label substring is SINGLE-ORIGIN-SHAPED (leading 'is ' renders only while inherited is the sole origin) — on the multi-origin fleet the arm FAILS (B31 S5) while the single-origin fleet passes in the same run (S6) ⇒ THE LANDED DECLS-WRITER ARM BREAKS THE DAY ITS FIXTURE GAINS A SECOND ORIGIN — exactly what discharging the join debt at that arm would do; §10 now specifies discharge on a NEW fixture, never a retrofit. Third composition failure (after IC-2, F2), FIRST FOUND BY EVALUATING. ★★ INSTRUMENT FACT pinned as a register literal: expectedError.msg IS A REGEX — a verbatim clause with parens fails (exhibited, S8); pinned substrings must be metacharacter-free or escaped; all four join substrings + F1's are clean on this test. F5: true semantics stated (catches the complements — which is what F1 did this round); ★ residual honestly OPEN: an unlabelled forgotten debt has NO predicate ('the thing to detect is the absence of text nobody wrote'); one PARTIAL guard added (prose tally vs label count) with its remaining hole said plainly. F1's debt now has BOTH endpoints measured (check-1 substring green on F1's exact fleet; check-2's gathered text DOES NOT RENDER — the executable form of 'the fleet refusal preempts the per-node one', which the bare boolean could never say). §10.3 = 14 rows (9 checkable / 5 step-3 marked-not-scored). Register 147→165 (+18); the distinct-cells row exhibited BOTH its law-41 signatures in one round (held at 32 on a re-citation, moved to 33 on the new cell).

★★ OPERATIONAL INCIDENT, ORCHESTRATOR-OWNED: the author's --amend was one race from rewriting MY integration commit (bf9a25e landed between its two commits) — I integrated into a checkout with a live writer after earlier deciding to queue behind it. ADOPTED: no --amend in a shared checkout while any track is writing; follow-up commits only (the digest rule tolerates them). OUT-OF-CLASS still open (visible as VACUOUS in §10.1): arm 11's name/assertion mismatch; the aborts-helper purpose comment. Both ride the dcx test unit.

### 45 — 2026-08-01T04:26:52 · Jason Bowman

*** dcx TEST UNIT LANDED — ALL THREE §10 ACCEPTANCE DEBTS DISCHARGED. Commit ba2b3cc on den-hoag main (one file, +199/-23, UNPUSHED pending the next ops-seam gate). Baseline 2085/2105 20 red matched expectation; after 2091/2111 (+6 arms ALL GREEN), red set BYTE-IDENTICAL, parity 71/71, format 0. Suite census 12→18 arms, expectedError 7→14, expected 5→4, msg 14 (14+4=18 partitions, msg matches expectedError — the positive control survives).

★★ EVERY SUBSTRING RENDERED BEFORE WRITTEN (standalone probe read the actual abort text first — all four §10.3 substrings present exactly as stated; the F1 negative reproduces). JOIN DEBT: four arms, one per join, on the two NEW fleets (arm 8 NOT retrofitted; the S5/S6 single-origin sensitivity now written into arm 8's own header). ★ SEPARATOR SENSITIVITY MEASURED PER JOIN: two mutation runs against lib/errors.nix (restored after; tree verified) — run A kills exactly the labels/remedies/clause arms 15/18; run B (siblings ',' alone) kills the siblings arm AND the clause arm 16/18 (the clause substring carries the sibling separator — why it dies in both). Every join has a demonstrated killing mutation. ESCALATION DEBT: bare boolean GONE; pair of grains landed — check-1 text on the registered+gathered fleet + the executable NEGATIVE (lookahead excluding the per-node text while requiring fleet-wide); arm 10's grain stated (the pair's before-endpoint no longer rests on an unargued green); the two arms deliberately do NOT telescope (the second pins a token the first does not assert); the first is not arm 4's duplicate (arm 4's fleet carries no gather — if check 2 ever won the race, arm 4 stays green and this goes red). The cannot-exist mutation control recorded in-comment, not hunted. ARM 11: now asserts its NAME — lookahead excluding the den.quirks TOKEN (covers every spelling of the non-remedy + excludes registeredChannelOrigin's remedy) while requiring the supplier remedy; non-vacuity control IN-SUITE same-run (den.quirks IS present in arms 4/5 + the escalation pin — both verdicts exhibited on one predicate). ★ BOTH lookahead arms PROVED LIVE by mutation (pointing each at present text reddened exactly those two, 16/18).

DEVIATION RATIFIED: the aborts helper DELETED rather than re-commented — after arm 11's rewrite its use count was zero; a comment for dead code is the repair, deletion is the construction. Correct reading of what the instruction was for.

★★ IC-5 (spec-side, queued): §10.3's regex fact is true but INCOMPLETE IN THE WAY THAT DECIDES EXPRESSIBILITY — measured at the pinned nix-unit 2.34.2 source: std::regex_search with default flags = ECMASCRIPT, not POSIX ERE. Consequences the spec does not state: (a) negative lookahead AVAILABLE — the only reason the escalation negative and arm 11's exclusion are expressible as assertions (under ERE neither is; fallback = fully-escaped whole-message anchor); (b) regex_search is UNANCHORED — ^/$ are the author's to supply. A future round reasoning 'regex ⇒ no lookahead' reaches the wrong conclusion from the sentence as written.

SPEC-SIDE ROWS OWED (enumerated by the implementer for the next ops-seam fix round, queued behind the papers writer): §10.1's domain + 12-row table superseded (four register cells re-run at HEAD: 18/14/4/14, partition + control survive); row 11 rewrite (discharged, message form + its non-vacuity mechanism); rows 10 + 8 spec-side grain sentences; rows 1-2 confirmed spec-side only; the THIRD-DEBT and JOIN-OBLIGATION blocks need discharge records ('zero pin a join' correct as pinned history); §10.3 instrument paragraph gains the grammar (IC-5); §10.3 rows now asserted by landed arms; ★ the origin-rows==acceptance-arms register row could not be located by the implementer — flagged not guessed: if it counts test- lines it now trips at 18 vs 5; if it counts §10's origin bullets it is unaffected (everything added is a RENDER arm, not an origin arm — the five-origin count and Seven-arms header unchanged).

HONEST LIMITS: localKeys debt untouched (still blocked on the red derived-channel path — the cheap registration evasion NOT taken); the negative is the one §10 measured, not whole-message (a third clause added to check 1 passes both escalation arms); arm 11's exclusion is token-scoped (a remedy phrased without den.quirks evades); the mutation controls are measurements run once, not shipped arms — nothing in CI re-checks them. Scratchpad housekeeping: the implementer's first redirect overwrote the shared baseline-ci/red.txt captures before switching to dcx- prefixes — any track relying on those filenames should re-capture.

### 46 — 2026-08-01T04:58:56 · Jason Bowman

ROUND 16-FIX LANDED, papers 34a83b2+5e992a5 PUSHED (core 463e7cf3/4608, ledger 4218055d/2821, register d85b10c4/844; digest from the committed blob, core untouched by the second commit). REGISTER 179/0/7 EXIT 0, STDERR EMPTY captured-to-file; backtick class swept zero with a 103-line positive control. All nine items verified against the ba2b3cc blob before writing.

STANDOUTS: §10.1 re-pinned 12→18 with the four cells re-run AND ★ A BIJECTION CHECK added (both name sets comm-differenced empty both directions — a row count of 18 vs a census of 18 is satisfied by a table that invents one arm and misses another; the check the count cannot make). Row 11's non-vacuity mechanism ★ CORRECTED FROM THE AUTHOR'S OWN FIRST WRITING (no arm pins den.quirks — the renders they abort on CONTAIN it; check 1 carries the den.quirks.channels remedy); evasion limit stated. Debt ledger 3→1 (localKeys sole survivor verified); ★ two-word label vocabulary (ACCEPTANCE DEBT / DEBT DISCHARGE RECORD, both counted — with one label a paid debt could only leave by deletion, traceless). IC-5 verified AT SOURCE (nix-unit-2.34.2 byte-identical to the locked rev; :376-377 no-flags std::regex = ECMAScript + unanchored regex_search) and written as a CAPABILITY with 'regex ⇒ no lookahead' explicitly forbidden. §10.3 re-scored + ★ in-class extension flagged (the escalation discharge's two exhibits were never tabled — §10.3's own stated domain caught skipping them; 16 rows). ★ THE ORIGIN-ROWS ROW LOCATED, NO RE-SCOPING: both sides are CORE-DOCUMENT predicates (origin table rows vs shadow-refusal bullets) — acceptance arms = ORIGIN arms (7 bullets) not RENDER arms (18 tests); distinction now stated at three sites. aborts-helper deletion ratified against both revs.

TWO LAW-41 SELF-COLLISIONS in the round's own text (a tally sentence matching the label predicate it counts — lower-cased with reason; the explaining sentence quoting the label — predicate made POSITIONAL with a total-occurrence control separating label-moved from sentence-added). ★★ OUT-OF-CLASS FOUND+FIXED: the two E5 CURRENCY rows still read the WORKING TREE (no rev) two clean rounds after round-14-fix repaired the law-45 cell ONLY — the fix-the-instance failure, caught because a concurrent writer's 2 dirty den-hoag files dropped the arms 10→9/8 while committed HEAD stood at 10; repaired to committed-rev reads with pin≠HEAD assertion; DEMONSTRATED: final notice prints committed 10 vs working-tree 9. No suite run — the greens are the implementation's and the ledger says so rather than restating them.

TRACK STATE: spec accounting current at the landed test unit; ONE debt open (localKeys, blocked on the derived-channel path); next gate reviews 16-fix + ba2b3cc together and rules the ba2b3cc push.

### 47 — 2026-08-01T18:00:31 · Jason Bowman

STATUS → open (orchestrator, 2026-08-01): stale in_progress inherited from a prior session — no agent on it this session; per the handoff its one debt (localKeys) is blocked on the red derived-channel path, and blocked-waiting is not in_progress. Spec current per the 2026-08-01 handoff; nothing regressed.

### 48 — 2026-08-01T21:37:08 · Jason Bowman

★★★ THE SEAM CONSTRUCTION LANDED AND IS PUSHED, 2026-08-01 session 7: den-hoag main 11e228b..60a6aa1 (post-rebase shas: 4536403 kernel, 0fdf8d9 shim, a5a6a91 acceptance surface, 533b3dc vocabulary, de82dc8 retirement, 60a6aa1 fmt-exemption chore; pre-rebase report shas 878a01e/a95c2f8/a72ea8c are DANGLING — cite only these). §9.4 STEP 3 IS IMPLEMENTED: the pipeOp→pipeCommit+pipeMark kind split, both translation modes, the commitment sentinel, mintFleetWide ops. THE DERIVED-CHANNEL PATH IS GREEN: all 5 pipe-consume tests pass as PLAIN assertions (their five xfail declarations retired IN the landing commit de82dc8, census rowCount 9→4 — the gate's designed retire-with-the-fix flow, exercised for real on its second day). quirkDag.channels on the fixture fleet: ["__den-demands","feat","feat.over.3","feat.over.3.map.2"]. THE 13 den-pipe REDS STAY RED BY DESIGN on law (a): all 13 now den-compat: commitmentUndeclared naming policy+channel+populated field (was den-hoag: opsInBody naming policy only); they wait on the r7l owner fork (IC-6, banked there: the declaration gate is unreachable from bare-lambda v1 policies). VERIFIED AT THE PUSHED TIP BY THE ORCHESTRATOR'S OWN RUN: ci#tests 2224/2238 EXIT 1, red = exactly 13 ☢️ + 1 ❌ probeSentinel; parity 73/73 EXIT 0; gate machinery census 2/2, selftest 11/11, suite-completeness 4/4 all green. IC-7 from the landing: pipe-consume fixtures were den-hoag-native records on the v1 surface, compiling only because nothing forced ungated.gate — moved to v1's own __isPolicy registry idiom.
NEXT UNITS ON THIS ARC, in order: (1) A1-A10 acceptance fixtures — the throwing twin, commitmentSentinel, recoverCommitments attribution probe, errors.commitmentFireFailed and familyStamps ops stamp are ALL LANDED AND ALL UNEXERCISED (every current fixture's gate binds zero args); (2) the localKeys debt: BLOCKER LIFTED (composed channels absent from den.quirks now exist), debt NOT discharged — the fixture needs a route/join/tee target named to collide with a sibling, and gen-pipe's join/tee output-naming semantics must come from den-hoag-4kh.36's standing C0 gen-pipe reuse-scan directive (four questions, pinned rev), NOT from guessing; (3) papers register rows the landing moves (core status lines :3/:6, the four debt-label rows) — next ops-seam papers round; (4) the 13 await den-hoag-r7l.


### 49 — 2026-08-01T22:48:59 · Jason Bowman

NEXT-UNITS ITEM (1) DISCHARGED, 2026-08-01: A1-A10 ALL IMPLEMENTED and integrated to main 54492d2..33fe37c (3 commits, FF+push; full report papers specs/2026-08-01-ops-seam-a-fixtures-report.md @ e3ee594). 32 new leaves in two suites (compat-commitment-fire 11, compat-commitment-declaration 21), all green; suite 2256/2270 EXIT 1 verified by the orchestrator's own run; red set BYTE-IDENTICAL (comm: all 14 in column 3); parity 73/73; census/selftest/completeness green at every commit (completeness verified at BOTH 225 and 226). The previously-dead surfaces are now EXERCISED: throwing twin (fire succeeds under Law C2 / aborts at stage application, split arms), fire-site attribution + three ceilings pinned OPEN, kind-set dispatch, mark-only gathering, commitmentFireFailed (5 arms incl. a direct-wiring control making the pin load-bearing), id stability, widening/narrowing/companion, the two declaration laws (10 arms incl. familyStamps via the include path), foreign/tagless/mark handling. Mutation-proved: 8 lookahead re-points each kill exactly their own arm; bearsCommitment third-disjunct revert reddens exactly the two pure-site-mark records.
FINDINGS: ★ IC-8 filed as den-hoag-57s (P1) — the seam landing REGRESSED the native body-emitted-commitment refusal into a silent unconsumed seed; not r7l-gated; implementer correctly shipped NO arm pinning it. IC-9 (minor, papers): §10's A1 promises the abort names "the stage role"; the twin has no channel to know the stage — landed arm asserts what renders.
PAPERS ROWS THE UNIT MOVES (next ops-seam papers round, full list in the report §9): §10 "A1-A10 are unimplemented (B30)" now FALSE; ★ §10's 18-render-arms figure and §10.1's domain are A11-SCOPED — a later round must NOT read 50 into them; §10.1 gains 32 arms; §10.3 gains 4 escaped-literal + 4 lookahead instances (IC-5 confirmed in a second file); §2.6 wiring row 2 EXECUTED; §2.4.1a's four ladder ceilings each gain a fixture; suite-completeness census 224→226.
REMAINING ON THIS ARC: (2) localKeys fixture — NOW FULLY UNBLOCKED with a known construction (C0 scan: pipe.map { f; name = "channels"; } — see 4kh.36's discharge comment; constraint: no quirk of the colliding name, den-hoag-847; also fix channel-binding-siblings.nix:33-38's false blocker comment in that unit); (3) the ops-seam papers register round (r17 rows + this unit's rows + IC-9); (4) the 13 await den-hoag-r7l; NEW: den-hoag-57s (the native seed regression, own remedy arc via the gate).


### 50 — 2026-08-01T23:08:22 · Jason Bowman

★★★ THE LAST ACCEPTANCE DEBT IS DISCHARGED, 2026-08-01: localKeys landed and integrated to main 38a08d5..3cbf3bd (one commit, FF+push; suite 2260/2274 EXIT 1 verified by the orchestrator's own run, red set byte-identical 13 ☢️ + 1 ❌, parity 73/73; full report papers specs/2026-08-01-ops-seam-localkeys-report.md @ 18be292). The C0 construction worked first try: den.quirks.ch.ops = [ (pipe.map { f; name = "channels"; } (channelRef "ch")) ] — composed channel named to collide with a sibling key, channelNames untouched. Four arms + a one-string control twin proving the evasion (registering the name) was NOT taken; three mutations each redden exactly their stated arms (the discrimination arm dies ALONE under a channelKeys widening; disabling the localKeys optional reddens exactly the three arms resting on it). channel-binding-siblings.nix:33-38's false "path is red" blocker comment REPLACED with current state + the two load-bearing constraints (den-hoag-847's dedup trap; the registration endpoint).
★★ IC-10, RECORD SO NO ROUND RE-BLOCKS THIS: core:4229's stated discharge condition ("discharges the day pipe-consume/den-pipe go green") is a PROXY THAT CAME APART — pipe-consume green, den-pipe deliberately red pending r7l, so the CONDITION is unmet while the REQUIREMENT (the composition path, measured green) is met. The debt is DISCHARGED; a round re-reading :4229 without re-measuring would file it as still blocked with its witness sitting in the suite. The papers round must restate the condition that actually governed.
★ IC-11 (open coverage question, not determined): registeredChannelOrigin's label is asserted by ZERO arms in ci/ (assertion-position census over 92 msg= lines: REGISTERED 0 vs composed 2 / gathered 2 / inherited 2 / enriched 1 / fallback 0); no arm was addable in this file (check 1 preempts on the .systems path — the lookahead would have been vacuous); mutation B proved the label renders, so not dead code. OPEN: does any consumer path reach bindings without forcing check 1? Rides the papers round's coverage rows; promote to a bead if it survives contact.
ARC STATE AFTER THIS: next-units (1) A1-A10 DONE, (2) localKeys DONE. REMAINING: (3) the ops-seam papers register round — now carrying r17's residue + the A-unit's rows + this unit's rows (register :678-699 five-row debt block: DEBT 1→0, DISCHARGE RECORDS 2→3, prose tally + survivor control rewrite; §10.1 census re-pin 18→22/14→17/4→5 measured with the register's own commands; §10 B30 false; A11-scoping guard; core status lines :3/:6; IC-9, IC-10, IC-11) — DISPATCHING NOW; (4) the 13 await den-hoag-r7l (owner); den-hoag-57s (native seed regression) has its own arc.


### 51 — 2026-08-01T23:40:55 · Jason Bowman

PAPERS ROUND (r18-fix) SHIPPED, 2026-08-01: papers 3975497+c0fe1c1 pushed (report archived @ 593839a). Register 200 pass / 0 drift / 7 skip EXIT 0 from a clean archive, r17's 190/0/7 reproduced first. Artefacts: core 7a383b7b99343acbeb75f7cbef8bd48f @ 4821 lines, ledger a7432302038136ffb8e23bc1ac058fee @ 3138, register 66fc88fb258af91d85e515a22f68b7bd @ 1088. Debt block ZEROED as a same-instrument pair (0 open / 3 paid, paid row = the open row's positive control; every discharge record names its paying rev). §10.1 re-pinned at 3cbf3bd (22/17/5, table renumbered — composed-channel set is rows 14-17, joins 18-21). B-cells STAY at 6dc4d44 by design; a LANDED_PIN block prints seven predicates at both revs, one promoted to a CHECKED row (kind split decidable: "pipeOp" 9→0 in lib/, controls pipeCommit 0→9 / pipeMark 0→12). IC-9 struck (third instance of IC-1/F2's class); IC-10's condition rewritten to the one that governed (composition path admitting a channel absent from attrNames den.quirks; den-pipe's reds recorded as never having gated it); IC-11 recorded OPEN with the re-derived census.
★★ NEW INSTRUMENT FINDING (B32, the round found it via the step-1-only sweep): §10.3's metacharacter rule was justified only in the FAILING direction — an unescaped [ … ] is a one-character character class that PASSES VACUOUSLY, proved by pointing the same pattern at the law-(b) message which carries no remedy clause (a widening metacharacter never announces itself). Row 12 and row 14 reddened against the document; a FIFTH verdict row added rather than hiding a vacuous match inside DOES-NOT-RENDER. The needed control class (one assertion against a message that must NOT satisfy it) had never run in this arc.
ARC STATE, FINAL FOR THIS SESSION: units (1) A1-A10, (2) localKeys, (3) papers round ALL DISCHARGED. SURVIVORS, all gated or new arcs: the 13 den-pipe reds await den-hoag-r7l (owner); den-hoag-57s (native seed regression) remedy via the 4kh.6 gate; §9.4 STEP 2 named not-landed as its own core row (§10.3 row 11 waits on it); IC-11's reachability question (papers-recorded, promote on contact); §10.1's domain-vs-class gap (32 A-arms unscored, stated as an open limit); the ledger's coordinate-class sweep still unswept.
