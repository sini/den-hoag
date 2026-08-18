# den-hoag-4kh.53 — [inventory] design-defect inventory of the entity/schema entrypoint — anchor bead for the 2026-07-28 audit, its confidence convention, its thesis, and its stated coverage holes

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-29T00:04:11Z by Jason Bowman |
| last updated | 2026-08-05T20:48:34Z |
| description bytes | 5198 |
| notes bytes | 0 |
| comments | 3 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

ANCHOR BEAD for the design-defect inventory produced by an independent audit session
targeting the ENTITY AND SCHEMA entrypoint -- the side the policy work did not cover.

ARTEFACT: ~/Documents/papers/den-architecture/plans/2026-07-28-den-hoag-design-defect-
inventory.md, 1249 lines, md5 0523e0a799151fdb66bc56f35a0a353c, committed at 5f38b96.
Audited against den-hoag c42df53.

★ ITS CONFIDENCE CONVENTION IS LOAD-BEARING AND MUST SURVIVE INTO EVERY CHILD BEAD:
  MEASURED   -- evaluated, with a positive control that moved in the same run
  ARGUED     -- structural reading of quoted code, NOT executed
  UNVERIFIED -- plausible, stated, not established; a lead
Do not promote an ARGUED item to a defect without re-deriving it. Several ARGUED
items in this document are strong; that is not the same as measured.

★ IT CITES BY EXPRESSION, NOT BY LINE, DELIBERATELY -- "line numbers drift; the quoted
text is the anchor." Honour that when acting on any child bead.

THE THESIS (§0), which is what the child beads decompose:
· v1 fires policy P at scope S iff P is in the scope's OWN candidate set -- a per-scope
  map containing only what an include put there. den-hoag has v1's conditions (2) and
  (3) and NOT condition (1): it starts from a GLOBAL rule set and filters by kind label.
· With global dispatch, a cartesian PRODUCT becomes necessary to make the model mean
  anything: rootScopeKinds = allKinds minus cellKinds, and nothing walks from a root.
· SCALE, MEASURED BOTH SIDES: v1 on nix-config = 31 scope nodes, <=12 fires for any
  single policy, ~206 dispatches across all 31 policies. den-hoag = 210 for ONE policy,
  exactly |H| x (1 + |U|).
· THE USABILITY TEST, which is the whole document in one sentence: "scan all matching
  aspects linked to this host and materialize them to a nixos configuration" is a
  two-hop graph query, and today there is NO SINGLE SITE WHERE THAT SENTENCE IS
  EXPRESSIBLE.

★ §0.4 -- THE ~2000-LINE TARGET IS AN ARTEFACT AND THE DOCUMENT ARGUES FOR RETIRING IT.
MEASURED origin (README.md:67). Three facts change what the number meant: it was the
WHOLE NEW STACK (den's own share was projected at 600-900 lines over a ~150-250 line
scope engine); it was 3x compression of v1's ~7,000 PIPELINE-SPECIFIC lines, not of
v1's 17,335; and THERE WAS NO COMPAT LAYER IN THE PROJECTION AT ALL. Every component
overran it -- gen-scope alone is 1,098 against a 150-250 projection.
Diagnosis: it priced the EVALUATOR (which landed -- trampoline, effect rotation and the
25-field state thread are all gone) and did not price the SURFACE or the ALGEBRA.
Stated realistic figure: ~4,000-5,000 kernel code lines, plus compat which is v1-shaped
and does not compress. ⇒ OWNER DECISION, and the document's warning is the point:
"driving a redesign at 2,000 would push work into gen that does not belong there -- and
§9 is evidence that has already started happening."

★ §0.5 -- A PRIOR AUDIT OF THIS QUESTION EXISTS AND OVERLAPS:
specs/2026-07-24-route-through-gen-audit-catalog.md, three-agent, against 44370e8. It
found genuine gen-duplication ~1,085 LOC (~5%) and concluded the path to 2000 is NOT
trimming hand-rolls but "gen absorbing the kernel's production algebra". ITS GAP TABLE
HAS NO ENTRY FOR gen-edge, gen-product OR gen-demand -- the three libraries built for
den-hoag are its blind spot, and this document fills that hole. The two agree on the
~5% figure by different methods. ⇒ RECONCILE THE TWO GAP TABLES rather than assuming
they are disjoint.

★★ COVERAGE HOLES (§13) -- STATE THESE BEFORE TRUSTING ANY COMPLETENESS CLAIM:
· lib/compat/** (~9.1k lines) WAS NEVER READ for hand-rolls -- grepped, not audited.
· lib/output/** and lib/attributes/** out of scope for mutability; attributes is
  attribute EVALUATION and plausibly carries the patch shape.
· ~23 `__` carriers on rules/declarations/thunks unaudited as a class.
· den-hoag's REAL POLICY CORPUS HAS NOT BEEN LOWERED -- the 210->10 demonstration used
  ONE synthetic fleet, three policies whose intent was CHOSEN, and 2 of 3 dispatch sites.
· nix-config was NEVER EVALUATED END-TO-END against den-hoag; v1 numbers come from a
  committed TOPOLOGY.md, den-hoag numbers from synthetic fleets of the same shape.
· ★ 8 of 9 attempted den templates and 0 of 4 sampled external configs WILL NOT EVALUATE
  against den-hoag AT ALL, four separate blockers. ⇒ THE TEMPLATE SUITE IS NOT A LIVE
  GATE ON THE COMPAT LAYER, and nix-config is the only fleet in the corpus immune to A1.
· NO COMPLEXITY CLAIM IN §9 WAS MEASURED ON A FLEET -- G20-G23 are read off source.
· gen-graph's and gen-merge's module bodies were NOT READ; the gen-graph "clean" verdict
  rests on a census, not a read. gen-merge is the larger unswept risk.
· The prior catalog (§0.5) was NOT re-verified.

§11 IS A CORRECTIONS LEDGER of ~24 claims made and refuted DURING the session, recorded
so a fresh session does not re-derive them. Read it before re-investigating anything --
several intuitive-sounding claims are already refuted there, including "__firesAtKinds
is the label-dispatch causing over-firing" (INVERTED -- it is the filter that would
PREVENT it) and "the ~2000-line target is the bar den-hoag missed by 6.7x".

## Comments (3)

### 1 — 2026-07-29T01:37:09 · Jason Bowman

★★★ RE-ANCHOR OF THE CHILDREN, 2026-07-29. 75 children exist (74 open + .53.1 closed); ALL 75 OPENED, 13 DEEP-VERIFIED AGAINST THE TREE, the other 60 got only a mechanical identifier-existence sweep — that tells you the construct still EXISTS, NOT that the claim holds. Treat the 60 as unaudited.

★ FIRST, THE DISPATCH PREMISE WAS WRONG AND IT NARROWS THE JOB. I stated this inventory audited c42df53, 'three commits behind HEAD, two of which are 222af84 and e6c8edc'. MEASURED, and re-derived independently by me: 222af84, ec6ba23 and 6f472d3 are ALL ANCESTORS OF c42df53 — because c42df53 IS ITSELF A chore(beads) EXPORT sitting after them. git log --oneline c42df53..HEAD -- ':!.beads' returns ONE line: e6c8edc. ⇒ THE BASELINE ALREADY SAW the class-content query, the ABW fix and the closure repair. Only e6c8edc is post-baseline, and only 9 of 74 children mention probe/sentinel/fan/firesAtKinds/functionArgs/den.policies at all. CONTROL: keyedBucketsOf / classSliceKeyedBaseAt / applyInjectReroute are 0 in lib/ AND 0 in ci/, and NO child cites any of them.
⇒ THE INVENTORY IS MUCH LESS EXPIRED THAN I ASSUMED. But it contains something worse.

★★ TWO CHILDREN ARE REFUTED AT THEIR OWN BASELINE — claims labelled MEASURED that a single grep at c42df53 disproves. These are CLOSABLE AS INVALID, NOT AS DONE, and that distinction matters because 'done' credits work that never happened:
  .53.4 — claims 'matchIdWith has zero callers' and 'matchId has one grep hit, a comment'. lib/default.nix:1975 IS CODE: matchIdStructural = scopeAdapter.matchIdWith structural { classOf = classNameOf; }; — AND IT EXISTED AT c42df53 as lib/default.nix:2029, IDENTICAL EXPRESSION. matchId has 2 live callers at ci/tests/entity-fleet.nix:165,169, also present at c42df53. SURVIVING NARROWER CLAIM: matchIdWith is unwired INTO THE THREE POLICY-DISPATCH SITES — not unwired.
  .53.7 — claims 'the ctxExt seam is UNEXERCISED / has never been driven'. lib/scope-adapter.nix:26-31 names the second formal LITERALLY ctxExt, and lib/default.nix:1975 DRIVES IT with { classOf = classNameOf; }. The file's own comment cites that exact classOf case as the seam's motivation. NOT REFUTED: that cases (a)/(b) have no selector equivalent.

★ THE EDGE HAZARD, AND IT NEEDS AN EXPLICIT RULING RATHER THAN A DEFAULT. .53.3 (D1) is HALF-EXPIRED BY ITS OWN SELF-DECLARATION (__firesAtKinds now appears 13 times in lib/, ALL COMMENTS — the non-comment predicate returns EMPTY; 0 in ci/) and it BLOCKS THREE OPEN P1s: .53.10 (N1), .53.11 (N2), .53.16 (N7). Read as fully live, someone re-derives a dead measurement. Closed on its expired half, three N-beads unblock on a resolution that .53.1 measured as 'not one step nearer' — the shipped value is selects = [ "host" ], ONE KIND-LABEL LIST SWAPPED FOR ANOTHER. Neither default is right; this is a decision.

OTHER VERDICTS FROM THE 13:
  .53.28 (A3) HEADLINE EXPIRED — kindExcludesOf is 0 at c42df53 and 2 at HEAD (def ingest.nix:243, threaded :789, consumed at compile.nix:1657,1671,1672). Mitigated: the bead already carries '★ CURRENT TREE HAS MOVED — RE-DERIVE BEFORE SCOPING' and its ingest.nix:243 citation is EXACT. The damage is the TITLE. ⇒ THE SAME DEFECT ON AN EXTERNAL P0 IS WORSE AND HAS BEEN FIXED: den-hoag-9xo.28, retitled this session.
  .53.27 DRIFTED — 'the 24 of 40' and 'closes 39 names' counts are stale: 22 of the 24 are still declared in kernel, 2 are gone (probeSentinelFields, producesByName — both kernel=0 compat=0; compile.nix:59 says 'formerly the den.probeSentinelFields KERNEL option' and concern-policies.nix:251-253 says den.producesByName has 'no remaining job'). ★ BUT C2 IS LIVE VERBATIM: entity.nix:48-53 guards exactly 'kinds'/'root'/'collector', and 'collectors' appears in ZERO guard lists.
  .53.8 DRIFTED — sel.kind is 11 hits but 9 COMMENTS / 2 CODE; sel.and is 2 hits, 1 code; both code sites are lib/compat/legacy/provides.nix. Identical at c42df53 and HEAD. Defensible under a kernel-only predicate, undercounts by 2 under the repo-wide reading its own sentence implies.
  .53.65 NOT ESTABLISHABLE AS STATED — its '5,474 lines of kernel prose' against my predicate's 5,371. ★ THE AGENT EXPLICITLY DECLINED TO OFFER 5,371 AS A CORRECTION, calling the ~2% gap a predicate-definition difference rather than evidence of error. That is the right call and worth imitating.
  .53.2 LIVE (rawForShim, 2 hits lib/compat/bridge.nix). .53.64 LIVE. .53.67 LIVE. .53.48 LIVE in den-hoag (26 prelude.groupBy sites; builtins.groupBy used at query.nix:44,45 — both coexist as claimed), quadratic-ness unverifiable here. .53.49 UNVERIFIABLE FROM THIS REPO — firstSeenBy is 0 hits in lib/ AND ci/, reached only through gen-product internals, and its 2,485 / 24.5M figures are ARITHMETIC PROJECTIONS, NOT MEASUREMENTS.
  .53.74 / .53.75 LIVE BY CONSTRUCTION — owner rulings authored AFTER the reconcile closed; no tree claim to expire.

★ FOUR CHILDREN ARE UNVERIFIABLE FROM THIS REPO BY CONSTRUCTION because every symbol they cite is gen-side: .53.54, .53.58, .53.66, .53.49. They need the gen-* sources, and any future audit scoped to den-hoag will report them 'not found' — which is an instrument result, not a finding.
★ POSSIBLE DUPLICATE TO RESOLVE: den-hoag-4kh.36 and .53.64 (O1) look like THE SAME CONSTRUCT TRACKED TWICE — both are 'the compat pipe op DAG / pipe.append/to is built and never applied'.
★ AND .53.74's OWN CLOSING POINT IS THE ONE TO ACT ON: THERE IS NO GATED PATH THAT CAN OBSERVE A SCALING DEFECT. ci has no large fleets and ship-gate.nix is a runbook step. Until that exists, every perf item in this inventory will keep being argued from source counts rather than measured — .53.47's 'negligible' resolution rests on a ci census with MAX N=24, which .53.74 makes SUSPECT rather than settled.

NEVER OPENED FOR VERIFICATION, so unaudited as of this pass: the whole N-series (.10-.16), S-series (.17-.26), A-series (.29-.34), T-series (.35-.39), E-series (.40-.45), most of G (.46, .50-.62), M (.63), the decisions (.66, .68-.72), and .5, .6, .9, .73.

### 2 — 2026-08-04T19:49:39 · Jason Bowman

CROSS-CUTTING AXIS RECORDED, 2026-08-04 — AND A CONSOLIDATION DELIBERATELY **NOT** PERFORMED.

THE OBSERVATION, which `den-hoag-4kh.53.5`'s own body proposes as the shared rule behind D3/G20/G27/G25:
**where a library ships two paths and one is weaker, THE DEFAULT MUST BE THE SAFE ONE.**

WHY NO MERGE. G27 and G25 are NOT free-standing beads — they are already bundled, along a DIFFERENT axis:
  den-hoag-4kh.53.60  [G23+G26+G27]  OPEN — toposort cited to Kahn ships cubic; gen-edge kind byte-cost
  den-hoag-4kh.53.58  [G15+G25]      OPEN — gen-demand surface stops short; demand.adapters permanently empty
Both bundle by AUDIT-ITEM ADJACENCY within the 53.x inventory. Pulling D3/G20/G27/G25 onto one carrier would
require SPLITTING TWO OPEN BEADS to reassemble the pieces. That is a forced consolidation, and a forced
consolidation is worse than none — it destroys a working grouping to build a second one, and the mantle
transfer would have to be invented rather than moved.
⇒ NO CARRIER NAMED. NO MANTLE TRANSFER PROPOSED. The rule is real and cross-cutting; the graph is simply not
bundled on that axis, and the rule does not need a bead to be true.

★ WHY IT IS RECORDED HERE AND NOT ON den-hoag-4kh.17: the register's stated domain is constructs marked for
RETIREMENT, and its entries are checked at dispatch for "does this design touch a doomed shape". A design
PRINCIPLE about safe defaults is a different kind of object, and filing it there would dilute the one
instrument whose value depends on every entry being a retirement. This inventory anchor bead owns the D3/G20/
G23/G25/G26/G27 family and is the natural home.


### 3 — 2026-08-04T19:55:36 · Jason Bowman

★ DECAY-RISK STATEMENT FOR THE 53.x FAMILY, measured 2026-08-04. NO DISPOSITION PROPOSED — this is a fact
being put where it belongs, not a call to re-audit.

This inventory was measured at rev c42df53 (2026-07-28). At ffaafb8:
    git rev-list --count c42df53..ffaafb8 -- lib/ ci/   →  122
    CONTROL same run: git rev-list --count ffaafb8..ffaafb8 -- lib/ ci/  →  0
(The control matters: `git log <empty-range> | wc -l` CANNOT report zero — git log emits a bare newline on no
match — so an empty-range check must use `rev-list --count`, which the control shows does report zero here.)

⇒ HEAD IS 122 CODE-TOUCHING COMMITS PAST THE REV THIS INVENTORY WAS MEASURED AGAINST. This bead's own
confidence convention defines MEASURED as "evaluated, with a positive control that moved in the same run" —
AT THAT REV. Nothing about that convention survives a 122-commit gap automatically, and several 53.x children
have already been found re-anchored or split on exactly this ground.
★ WHAT THIS IS NOT: it is not a claim that any specific 53.x item is stale, and it is not a discharge of
anything. It is the statement that a MEASURED marker in this family now names a historical measurement, so a
child cited from here re-derives at its own rev before its figure carries load.

★ ALSO RECORDED, because it explains why the sweep instrument cannot help here: this bead carries ZERO
backticked identifiers, so the identifier-drift instrument that found the dcx and 4kh.41 dead controls is
STRUCTURALLY BLIND to it. It anchors on a papers artefact and a rev, not on code. Functionally it behaves like
the permanents (an anchor/convention bead) and is not discharged by any landing.
