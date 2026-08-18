# den-hoag-4kh.36 — [kernel] 9 parked pipe cases, ALL blocked on run wiring: the codomain surface was cleared for all 8 armable (measured with control) and greened NONE — five named wiring defects gate them (append/to/gather-derive/expose-exclusion/self-route); 3 old park diagnoses falsified and corrected in place

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.36` |
| status at evacuation | open |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:36:44Z by Jason Bowman |
| last updated | 2026-08-02T16:18:24Z |
| description bytes | 7185 |
| notes bytes | 0 |
| comments | 4 |
| dependencies | `None` (None), `None` (None), `None` (None), `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ ARMING CONTACT 2026-08-02 at 3591f8c (supersedes the previous correction one paragraph down): the codomain surface was CLEARED for all 8 (den.policyCodomains records copied from green den-pipe siblings; control — removing one declaration reproduces the compose-commitment abort, restoring it fails on the VALUE) and NONE reached green. "Armable TO GREEN" was this bead's premise and it is FALSIFIED: the next blocker is run wiring, five named defects now gating this bead as blocked-by edges (den-hoag-4m3w append-unread, den-hoag-zvql to-unwired, den-hoag-a5i2 gather-bypasses-derive, den-hoag-mfc5 expose-derive-exclusion, den-hoag-5diw self-route-unguarded). Three old park diagnoses were falsified by discriminating controls and corrected IN THE PARK NOTES (collect-filter: the filter IS applied, to the wrong population; as-with-collect: transform and route BOTH work, the peer entry is missing; multiple-from: the filter half applied). All sharpened assertions + codomain records are preserved inside the parked comments — the next attempt starts from them. Suite 2287/2287 EXIT 0 + parity 73/73 verified by both implementer and orchestrator at 3591f8c, pushed.

★ BASELINE CORRECTION 2026-08-02 at 9311fbd (closure sweep): the suite is now 2287/2287 EXIT 0 — the "suite 2020/2040 with 20 non-pass" figure below is HISTORY, not a diffable baseline. opsInBody is RETIRED (3 comment-only hits, all saying retired) and the r7l fleet-settable surface LANDED, so the 8 are armable TO GREEN (see title).

RE-ANCHOR 2026-08-02 (sweep-S8 at 04d55d6): '9 parked' REPRODUCES EXACTLY (7+2 PARKED). But Construct-I's abort class EXPIRED: opsInBody survives only in two comments saying 'retired'; the LIVE class is commitmentUndeclared (errors.nix, thrown at policy-recover.nix's recovery fire), and conformingProduce moved to concern-policies.nix:825 region — anchor by binding name. ★ THE 8 ARE ARMABLE ONLY AS ATTRIBUTED KNOWN-REDS, NOT TO GREEN, AND THE GREEN-BLOCKER MOVED: IC-6 re-verified at HEAD (producesByName static import at default.nix:158, control resolveFamilyNames :152 same shape) — green is gated on r7l's fleet-settable surface, no longer on 53.64 alone.

RE-ANCHOR 2026-07-30 at b2586e6 (den-hoag-66t settlement scout, read-only; the abort-vs-divergence classification is DERIVED from the guard predicate + stage role assignments, NOT executed — every case is commented out and the scout could not arm them). THE 15 SPLIT BY `declare.isSiteMarkData` (lib/declarations.nix:182-186) INTO TWO CONSTRUCTS:

· 9 WOULD ABORT, NOT DIVERGE (Construct I — the compat ops seam, den-hoag-66t close reason + den-hoag-4kh.53.64 re-anchor): pipe-policy.nix L356, L598, L664, L723, L963, L1167 and L798 (but see mislabel below); pipe-scope.nix L82, L375. Each carries a deriving or delivery stage, so arming one today yields the firing-time errors.opsInBody ☢️ abort (conformingProduce, lib/concern-policies.nix:406, abort :421-422), not a wrong value. The "wrong-value divergence" characterisation is STALE for these — they were measured before the firing-time guard landed.

· 6 ARE SITE-MARK-ONLY (satisfy isSiteMarkData, pass the guard) — AND THE SECOND TRACE (2026-07-30, frozen snapshot at 61be68c) SPLIT THEM AGAIN:
  – CONSTRUCT II PROPER (unconsumed mark) IS NOW ONLY pipe-policy.nix:145 (test-pipe-append). RE-MEASURED at HEAD: `"append"` produced at lib/compat/pipe.nix:169-175, consumers ONLY producer+stage-tag sites; capability control same predicate same run: `"expose"` finds two consumers (gather.nix:134, default.nix:1531). The predicate can find consumers; append has none.
  – THE 5 EXPOSE CASES (pipe-scope.nix L32, L142, L195, L248, L1062) ARE STALE COMMENTS, NOT A CONSTRUCT: the parked comments were written at 9597e7e (2026-07-21) when lib/compat/gather.nix DID NOT EXIST (git cat-file -e negative; flake-module.nix then wired only collectGather) — the composed 3-arm supplier (gather.mkGather, flake-module.nix:420 behind features.gather) since wired the expose arm. Evaluated verbatim at HEAD on a frozen snapshot: L32 "vim", L142 [80 8080], L195 "fish-zsh", L1062 "alice@iceberg,tux@igloo" — all v1-expected values, PASS. Load-bearing control: L32 with the expose policy deleted yields "" = exactly the recorded parked actual, so delivery is the expose arm and the recorded actuals are the pre-gather.nix world. The reach chain is unconditional per fleet (flake-module.nix:420 → default.nix:939-945/:1889 → output-modules.nix:914/:933/:957 → gather.nix:352-361 → exposeChannelsAt :127). ARMED at 8a707d1 — all four green under the suite scaffold; suite 2020/2040 with 20 non-pass.
  – L248 SPLITS: its expose half PASSES (hostCount "2" exact); pinguHost measures "pingu-secret-tux-secret" — a cross-class BINDING-SITE defect (user-scope consumer instantiated at the host node), isolated by a host-only-emission control and tracked at den-hoag-hrh. Armed as a known-red attributed there at 8a707d1 (clean value diff, hostCount matching in the failing assertion).

· MISLABEL: pipe-policy.nix:798 (test-pipe-from-ref) is headed "pipe run-wiring gap, same root cause" but its recorded symptom is `attribute 'name' missing` from the quirk-REF form of pipe.from (lib/compat/policy-verbs.nix:101) — a constructor-arg-shape defect with a distinct root cause, tracked at den-hoag-vhn. It is in neither construct.

Original body below stands as the 2026-07-28 measurement record; its uniform "15 wrong-value divergences" characterisation is superseded by the split above.

════ ORIGINAL BODY (2026-07-28) ════

★ MEASURED — THE PIPE RUN-WIRING GAP: `pipe.append` / `pipe.filter` / `pipe.to` ARE NOT APPLIED AT ALL.
FIFTEEN v1-vs-den-hoag VALUE DIVERGENCES, EVERY ONE COMMENTED OUT SO NONE RUNS. NO BEAD.

VERBATIM from `ci/tests/den-behavioral/pipe-policy.nix`:
  :145 "PARKED-DIVERGENCE (same pipe run-wiring gap as test-pipe-filter above): v1 expected \"a-z\";
        den-hoag actual \"a\" (pipe.append not applied — nothing appended to the pool)."
  :356 v1 "x-y-z--p" vs den-hoag "x-y--p-q" — "neither the alpha pipe.append nor the beta pipe.filter applied"
  :664 v1 "x-y" vs den-hoag ""
  :598 BLOCKED-WSB — "the raw/untransformed pool makes the CONSUMER's own accessor throw"
COUNT: `run-wiring` = 8 in `pipe-policy.nix` + 7 in `pipe-scope.nix` = 15 cases. Every one is a commented-out
`# test-… = denTest` body, so the suite is GREEN and the divergence is invisible to CI.

★ THIS IS NOT COVERED BY den-hoag-9xo.2, AND THE DISTINCTION IS MECHANICAL, NOT SEMANTIC:
  9xo.2's scope is cross-scope `pipe.expose` collection delivering ZERO, and its own NOTES conclude "#52's 0
  is DOWNSTREAM of den-hoag-9xo.8, not an independent bug".
  THIS gap yields WRONG VALUES FROM A NON-EMPTY POOL, on DIFFERENT VERBS. An empty delivery and a
  wrongly-transformed delivery are different failures with different causes; closing 9xo.2 would leave every
  one of these 15 red.

⇒ Fifteen known wrong-value cases sit behind comment markers in a passing suite. Under the three-state CI
ruling these are LANDINGS, not blockers — but they must be ARMED and tracked to be either.

PROVENANCE: log-reconcile exhaustive pass, 2026-07-28, item C2. Untracked before this bead.




## Comments (4)

### 1 — 2026-07-29T02:05:25 · Jason Bowman

★ OWNER DIRECTIVE 2026-07-29, STANDING FOR ALL PIPE WORK: any task taking up a pipe-related item must ALSO verify that den-hoag is PROPERLY LEVERAGING gen-pipe (clone at ~/Documents/repos/sini/gen-pipe/).

WHY IT ATTACHES HERE FIRST: this bead records that pipe.append / pipe.filter / pipe.to are NOT APPLIED — 15 wrong-value divergences, all commented out, suite green. ★ IF gen-pipe ALREADY IMPLEMENTS THAT COMPOSITION, THIS IS A WIRING GAP AND NOT A MISSING CAPABILITY, AND THE REMEDY IS ENTIRELY DIFFERENT. Nobody has established which.

THE SCAN MUST REACH PRIMITIVE GRANULARITY. This project's standing reuse rule exists because it has built-what-already-exists THREE TIMES, and the failure mode that survives review is NOT 'wrong library' — it is ★ RIGHT LIBRARY, WRONG SURFACE: a call that works while bypassing the intended entry point, usually because that entry point had an inconvenient shape. That is invisible to a reviewer who checks only that the dependency is used.
FOUR QUESTIONS FOR ANY SUCH SCAN: (1) enumerate gen-pipe's exported surface with signatures; (2) derive den-hoag's real call sites with a positive-controlled grep rather than trusting a list; (3) ★ enumerate what den-hoag HAND-ROLLS THAT gen-pipe ALREADY PROVIDES; (4) where den-hoag does call gen-pipe, is it the RIGHT primitive.
★ AND READ THE PINNED REV, NOT THE CLONE. ci/flake.lock pins the gen libraries and the local clones run AHEAD — measured today, testSingletons exists in the local gen clone and NOT at the locked rev, so a capability found in a clone is not a capability available to the build. Any gen-pipe claim must name which rev it read.

KNOWN STARTING POINTS, all REFUTABLE: lib/attributes/collections.nix calls pipe.contribute (its header names 'the tagged emission'); lib/compat/pipe.nix is a compat surface; lib/scope-adapter.nix mentions 'gen-pipe's traversal-adapter contract'. Derive the real set rather than inheriting this one.
★ AND THE HIGHEST-VALUE TARGET IS THE COMPOSE SEED: den-hoag's own abort text names 'the ONE fleet gen-pipe compose before the eval'. Whether that compose runs through gen-pipe's composition primitive or through something den-hoag built beside it is unestablished — and if it is re-implemented, that is a fourth build-what-exists instance sitting directly under the twelve known-red aborts (den-hoag-66t) and under the upstream defect lib/errors.nix says must not be worked around in the shim (den-hoag-i5m).

DISPATCHED as added scope to the in-flight upstream-trace task, which was already reading this territory. Related: den-hoag-4kh.53.64 (ops DAG built-never-applied) may describe the SAME construct as this bead — that relationship is also being established rather than assumed.

### 2 — 2026-07-29T04:15:50 · Jason Bowman

★ NOT A DUPLICATE OF den-hoag-4kh.53.64 — established 2026-07-29 by the ops-representation spec, correcting a suspicion I recorded earlier that the two might be one construct.
They are TWO ENDS OF ONE SEAM. den-hoag-4kh.53.64 is the DERIVING/ROUTE half — a pipeOp carrying a derived-channel DAG or a delivery route can never reach the fleet compose seed, because no compat-compiled policy record carries .
★ THIS BEAD IS THE SITE-MARK HALF, AND IT FAILS DIFFERENTLY: **marks DO reach the per-node declaration** via gather.nix's  — **and are then NOT INTERPRETED.** So this is not a delivery gap, it is an interpretation gap, and it survives the ops fix.
⇒ THE ops SPEC CLOSES 4kh.53.64 AND den-hoag-66t AND EXPLICITLY LEAVES THIS BEAD OPEN. Do not expect the pipe reds to clear this one.

### 3 — 2026-08-01T20:00:58 · Jason Bowman

Retitle witnessed at 693919f (closure scout): the arming LANDED — merge-base confirms 8a707d1 ancestor; the four expose cases + the L248 split + the vhn mislabel armed by name (pipe-scope.nix :35/:144/:196/:251, pipe-policy.nix:804); run-wiring markers 15 → 9 (7 pipe-policy + 2 pipe-scope; the extra commented bodies in pipe-scope are outside this bead's 15). Remainder: 8 Construct-I abort cases behind 4kh.53.64 + the append mark. ★ The standing owner directive in C0 (verify den-hoag properly leverages gen-pipe — four questions, read the PINNED rev) has no other home and is now carried in the title so a narrowing cannot drop it.

### 4 — 2026-08-01T22:28:54 · Jason Bowman

★ C0 STANDING DIRECTIVE: EXECUTED 2026-08-01 (read-only scout at gen-pipe pin 5350930 / den-hoag 54492d2). Full report ARCHIVED: papers specs/2026-08-01-gen-pipe-reuse-scan.md @ e9de7e9, md5 7ba0a51ed91d595f34f51153016c9803, 508 lines — all four questions answered with pin-stated cells (surface+signatures; positive-controlled call-site census; hand-rolled-duplication enumeration; right-primitive per site) plus the localKeys naming-semantics question. HEADLINE ANSWERS: (1) the localKeys fixture IS CONSTRUCTIBLE — compose.nix:110 `else if ch.name != null then ch.name` makes a derived channel's final name the caller's arbitrary string; eval witness: pipe.map { f; name = "channels"; } composes to a channel literally named "channels", derived, absent from attrNames den.quirks; the <base>.<op>.<i> shape is only the name==null fallback. Constraint: the fixture must NOT also register a quirk of the colliding name (see den-hoag-847). (2) channel-binding-siblings.nix:33-38's stated blocker ("derived-channel composition path is red") is FALSE at this pin — fix that comment in the localKeys unit. (3) NEW gen-pipe defect filed: den-hoag-847 (explicit-vs-declared collision silently dropped by first-wins id dedup). (4) den-hoag-7n3's cubic confirmed with a sharper two-term mechanism (comment there). Coverage limits in the report (deferred.nix/errors.nix/provenance.nix/ci not read — signature cells for deferred/provenanceOf/traceOf are export-block-derived). The directive's four questions are DISCHARGED for this pin; a gen-pipe rev bump re-opens them.
