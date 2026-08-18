# den-hoag-4kh.13 — [kernel] a negative-edge cycle in den.policies yields an UNSUPPORTED FACT; nothing guards ctx-key negation

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.13` |
| status at evacuation | closed |
| priority | P0 |
| type | bug |
| labels | `arch-validated` |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T02:30:57Z by Jason Bowman |
| last updated | 2026-07-29T01:11:25Z |
| closed | 2026-07-29T01:11:25Z |
| close reason | EXPIRED — fixed by ec6ba23 + 6f472d3, verified two ways this session. (1) Symbol/site: the bead's own fixtures are bound under their own names in ci/tests/b1-supportedness.nix — negA (emits=["enrich"]; fn = ctx: if ctx ? b then [ ] else [d.enrich{key="a";...}]) and posB (fn = { a, ... }: [d.enrich{key="b";...}]) — and test-negative-cycle-aborts asserts aborts(...) == true. Its quoted premise comment is gone: grep -n KEYSET-MONOTONE lib/attributes/structural.nix -> 0, positive control same run single-writer -> 3 hits. (2) EXECUTION: nix-unit --flake ./ci#tests.b1-supportedness -> EXIT 0 SEEN DIRECTLY (redirected to file, $? read on the adjacent line, not through a pipe), 22/22, with test-negative-cycle-aborts, test-negative-cycle-aborts-at-the-crossing and test-self-negative-aborts all green. The guard the bead asks for exists, fires, and is tested. |
| description bytes | 3050 |
| notes bytes | 0 |
| comments | 11 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED DEFECT IN SHIPPED CODE, REACHABLE FROM PLAIN USER CONFIG, PRODUCING A WRONG ANSWER.
Constructed with `den.policies` only — no internal APIs. Fixture: scratchpad/q6-usersurface.nix.

THE SHAPE — ABW Lemma 1's forbidden configuration, a cycle through a negative edge:

    negA = ctx: if ctx ? b then [ ] else [ (declare.enrich { key = "a"; value = 1; }) ];   # a --NEGATIVE--> b
    posB = { a, ... }:        [ (declare.enrich { key = "b"; value = 2; }) ];              # b --POSITIVE--> a

MEASURED, enriched-context keys:
    no policies        ["__entry","node"]
    negA alone         ["__entry","a","node"]        <- control: negA fires, produces a
    posB alone         [ ]                            <- control: never fires, requires a
    BOTH (the cycle)   ["__entry","b","node"]         <- ★ b IS PRESENT, a IS NOT

★ `b` IS IN THE MODEL AND `a` — b's SOLE JUSTIFICATION — IS NOT. AN UNSUPPORTED FACT.
No abort. No warning. Deterministic under reversed declaration order (so it is not a race).
This is exactly what ABW's stratification exists to prevent, and it violates THEOREM 7 (p. 111,
supportedness): every atom in M_P is the head of a ground clause whose body holds. Here nothing justifies b.

WHY NOTHING CATCHES IT:
· The only ctx-key guard is projectCtx (lib/concern-policies.nix:129). It is an INDEX COMPARISON —
  structurally incapable of observing a CYCLE — and it is NOT USER-REACHABLE (see below), so it is not even
  running.
· L4 (`negates`) ranges only over DECLARED negations on RELATION kinds. A policy body negating a CTX KEY is
  outside its domain entirely.
· `ctx ? key` is the negation, and it is invisible: policy condition edges are derived from
  `builtins.functionArgs`, which yields POSITIVE dependencies only. THE SIGN IS NOT DERIVABLE — negatives
  live inside opaque `ctx: [decls]` bodies and pure Nix cannot introspect them.

★★ IT LANDS ON A STATED-BUT-UNENFORCED PREMISE. lib/attributes/structural.nix:96-99, verbatim:
  "single-writer + KEYSET-MONOTONE GUARDS make a key's value fixed once it appears, so a refire at a grown
   context is idempotent."
That is ABW's no-negative-edge condition stated informally in a comment. A NON-MONOTONE GUARD WAS SUPPLIED
AND ACCEPTED. Kernel-purity criterion 6 — an invariant documented but unenforced.

NOT MEASURED, and it is the one fact separating "latent soundness hole" from "observable corpus bug":
whether the unsupported `b` PROPAGATES INTO MATERIALIZED OUTPUT. Not guessed at. Also unmeasured: whether
any external config in ~/Documents/repos/den-configs currently takes this route.

ACCEPTANCE: a fixture pinning the cycle case. Against the current tree it produces the unsupported fact;
that is the point. Under the three-state CI ruling it lands as a known-fail with a tracked id.

RELATED: den-hoag-4kh.11 (the ABW guard arc that surfaced it). The remedy space overlaps but is NOT the
same — 4kh.11 is about a guard being over-strict on the wrong rule; this is about a guard that does not
exist for a domain that needs one. Do not fold them.


## Comments (11)

### 1 — 2026-07-28T03:22:01 · Jason Bowman

★★★ Q1 ANSWERED: THE UNSUPPORTED FACT REACHES MATERIALIZED OUTPUT. This is not a latent hole.
Measured by an independent agent, read-only. Probes: scratchpad/{qA-propagate.nix,qA-ctx.nix,qB-shape.nix}.

PATH: enriched-context -> lib/attributes/output-modules.nix:1006-1007 `bindingsAt`
(`bindings = (result.get id "enriched-context") // channels // settings`) -> gen-bind wrapAll ->
class-content module arg -> crossNixos -> a real NixOS option. Fleet shape from
ci/tests/binding-totality.nix; den.nixpkgs = root-lock nixpkgs d407951447dc.
Consumer: den.aspects.consumer.nixos = { b, ... }: { networking.domain = "SAW-b-${toString b}"; }

FORCED THROUGH THE REAL CROSSING (nixosConfigurations.bare.config.networking.domain):
    CYCLE (negA+posB)   "SAW-b-2"                       <- MATERIALIZED
    negA alone          error: attribute 'b' missing    <- control
    no policies         error: attribute 'b' missing    <- control
    SENTINEL            error: attribute 'zzz_never_written' missing   <- proves the force reaches the
                                                                          module fn; positive arm not vacuous
builtins.tryEval did NOT catch these — a missing-attribute error escapes it, as expected.
ctx at this fleet (node id host:bare@env:prod): CYCLE -> ["__entry","b","env","host"], ctx.b = 2,
ctx.a = missing-attribute error. Controls: negA alone -> a present; posB alone -> never fires.

════ ★ Q2 — THE SHAPE, and it is worse than "a value that should not exist" ════
The agent sharpened the fixture so b's value DERIVES from a:
    posB = { a, ... }: [ (d.enrich { key = "b"; value = "from-a=${builtins.toJSON a}"; }) ]
    materialized      networking.domain = "SAW-b-from-a=1"
⇒ a = 1 WAS REALLY SUPPLIED to posB during the fixpoint, AND THEN DROPPED.
NOT a missing value, NOT a silent default, NOT a malformed value — A WELL-FORMED, FULLY-TYPED NixOS OPTION
VALUE WHOSE DERIVATION READS A PREMISE THE FINAL GRAPH DOES NOT HOLD. Exactly ABW Theorem 7 (p. 111,
supportedness) violated, and it is observable in a built configuration.
Supporting reads on the same arm: enrichments.added = {"b":"from-a=1"} (a is NOT in the delta);
enrichments.owners = {"b":"posB"} (ONE writer; negA leaves NO trace). Control (negA alone): added = {"a":1}.

════ ★★ MECHANISM LOCATED — lib/attributes/structural.nix:136-149 ════
`converged` (the scope.circular fixpoint value) DOES contain a = 1 — that is why posB fired at all. But
:148-149 RE-DERIVES THE PUBLISHED DELTA FROM SCRATCH at the converged context:
    finalActs = enrichAt converged;  added = delta finalActs
At the converged context `ctx ? b` is TRUE, so negA is INERT in that final dispatch and `a` is never
re-produced. :172 then publishes `enriched-context = inherited-context // enrichments.added` = b WITHOUT a.
⇒ THE FIXPOINT AND THE PUBLISHED DELTA DISAGREE. The value is justified during iteration and unjustified in
the result. That is the precise fix target, and it is one site.

════ Q3 — WHAT DID NOT STOP IT ════
The only guard on this path is the single-writer check, structural.nix:150-158 (`owners`,
errors.singleWriter). It is a per-KEY COLLISION check — it fires when two policies write one key. A key with
exactly ONE writer whose premise has vanished is invisible to it: owners = {"b":"posB"} is a CLEAN PASS.
NOTHING ON THE PATH OBSERVES JUSTIFICATION.

════ ★★★ Q4 — THE ROUTE IS TRAVELLED IN SHIPPED USER CONFIG ════
Trees searched as SEPARATE runs (never one grep across both), no --include filter, .worktrees AND .git
excluded from every grep.
NEGATIVE EDGES IN REAL CONFIG — absence of a ctx key changes the declaration set:
  den-configs/nixfos/modules/den/policies/route-factories.nix:46  `args@{ host, ... }: lib.optional
      (host.class == "nixos" && !(args ? user))`  — and :68, :95 with `!(args ? home)`
  den-configs/nixfos/.../hardware/persist/class/classes.nix:55    same shape
  ★ den-configs/nixfos/modules/den/policies/users.nix:94-98
      den.policies.env-users = { accessGroups ? [ ], ... }: map (...) (matchRegistryUsers accessGroups);
    A DEFAULTED FORMAL — fires regardless; absent ⇒ [ ] ⇒ zero declarations. A NEGATIVE EDGE.
★ AND THE KEY IS ENRICHMENT-CARRIED, IN THE SAME CONFIG:
  den-configs/nixfos/modules/den/policies/fleet.nix:60,69
      den.policies.env-to-hosts = { environment, ... }: (resolve.to "host" { host = bridgedHost;
                                                                            inherit accessGroups; })
  A MIXED resolve — schema key `host` = transition, NON-SCHEMA key `accessGroups` = ENRICHMENT. That
  semantics is pinned by den's own template (denful/den/templates/ci/modules/public-api/
  policy-context-enrichment.nix:104, "the non-schema key should enrich the current context") and den-hoag's
  parity ledger independently records accessGroups as a ctx key (lib/compat/parity/ledger.md).
⇒ A REAL ENRICH-WRITTEN KEY IS READ BY A REAL ABSENCE-BRANCHING POLICY, IN ONE SHIPPED USER CONFIG.
TEMPLATES: 8 further negated-membership sites (route.nix:227, features/entity-isolation.nix:113,
internal-api/fx-edge-parity.nix:137, fx-materialize-unified.nix:232, edge-trace.nix:360 and :977,
fx-edge-unification-gate.nix:318), plus public-api/dynamic-forward.nix:16 and the or-default-on-ctx-read
shape at internal-api/policy-combinators.nix:228 (`den.lib.policy.when (ctx: ctx.flag or false)`).

════ NOT MEASURED — the one thing that would make this a confirmed live corpus bug ════
WHETHER THE nixfos accessGroups PRODUCER/CONSUMER PAIR ACTUALLY CLOSES INTO A FIXPOINT CYCLE AT RUNTIME.
That needs a full corpus build through den-hoag compat, which the parity ledger records as currently blocked
at the exclude-of-policy stub. So: NEGATIVE EDGE ON AN ENRICHMENT-CARRIED KEY = MEASURED PRESENT in shipped
config; CLOSED CYCLE IN THE CORPUS = NEITHER CONFIRMED NOR REFUTED. Do not upgrade the claim past that.
Also: Q1/Q2 measured on the synthetic two-policy fixture, not a corpus fleet. nix-config not searched.

════ INSTRUMENT NOTE — a false clean the agent caught in its own work ════
Its first enrichment-writer sweep used the token `enrich` and returned 0 files across den-configs. WRONG
PREDICATE: v1 spells enrichment `resolve { <non-schema-key> = … }`, so that sweep could not have matched.
Corrected predicate: bare `resolve { … }` = 0 in den-configs with POSITIVE CONTROL `resolve.to ` = 5; = 4 in
templates. It also closed the unparenthesized `!x ? y` form (valid Nix; its first regex required parens) —
0 hits in both trees.

════ CONSEQUENCE ════
This bead is no longer "a latent soundness hole reachable from the user surface". It is a defect that
MATERIALIZES A WRONG NixOS OPTION VALUE, with a located single-site mechanism, and with BOTH INGREDIENTS
(an enrichment-written key, an absence-branching read of it) PRESENT IN ONE SHIPPED CONFIG. Only the closure
is unproven.


### 2 — 2026-07-28T04:00:38 · Jason Bowman

★★★ REMEDY DESIGN WRITTEN — papers/den-architecture/specs/2026-07-28-ctx-supportedness-design.md
619 lines · md5 710fecbceb0b5876588ce4bd55deaf6d · core delimited :234-290, error builder :297-306.
den-hoag and gen-* untouched; no beads, no commits; all patched trees are scratchpad copies. Going to the gate.

════ ★ REPAIR IS IMPOSSIBLE. MEASURED, NOT ARGUED. ════
"Publish the fixpoint instead of re-deriving" was the obvious remedy. IT IS UNSOUND, and the author settled it
by enumerating T_P over the fixture's ENTIRE 2-atom Herbrand base, using THE SHIPPED FIRING PREDICATE
transcribed from gen-derive/lib/core/rule.nix:29-48 (scratchpad/tp.nix):
      {}  → {a}        {a} → {a,b}        {b} → {}        {a,b} → {b}
NO FIXED POINT EXISTS. Both {b} (what den-hoag publishes) and {a,b} (the fixpoint) are MODELS but NEITHER IS
SUPPORTED. Publishing `converged` trades one unsupported fact for another.
⇒ REJECTION IS THE ONLY SOUND REMEDY. This is exactly what ABW predicts for a program that is not stratified,
and it converts the orchestrator's instinct into a measurement.

════ THE HYPOTHESIS HELD — IN A STRONGER FORM THAN POSED ════
The dispatch asked whether per-iteration act sets are recoverable from scope.circular. They are NOT
(gen-scope@ceabe5e lib/resolve.nix:302-322 — `go` returns only `next`, verified by reading).
IT DOES NOT MATTER. The step is `ctx // delta (enrichAt ctx)` (structural.nix:143-144), so THE CONTEXT KEYSET
IS MONOTONE ACROSS ITERATIONS ⇒ keys(converged) \ keys(base) IS the set of keys produced at any iteration.
Both sides ALREADY EXIST at :146 and :149. The detector is a comparison of two values the attribute already
computes — nothing to recover, nothing to instrument.
Measured: a patched copy aborts on the fixture with `dropped=[a<-negA]`. `a` can only come from
`attrNames converged`, so converged demonstrably held `a` while `added` did not.

════ ★★ AND THE AUTHOR REFUTED ITS OWN FIRST SOLUTION ════
The KEYSET form has a MEASURED BLIND SPOT. ABW's minimal+supported model is a FIXED POINT of T_P (p.100
prose) — an identity INCLUDING VALUES. Fixture whose keyset stabilises while values still move:
      driftY = {x ? 0, ...}: y = x + 1 ;   driftX = {y, ...}: x = y * 10
Unpatched publishes {"x":110,"y":11}; THE KEYSET CHECK PASSES; and at that published state driftY yields
y = 111 — y IS UNSUPPORTED WITH THE KEYSET CHECK GREEN.
⇒ THE PROPOSAL IS THE VALUE-LEVEL LAW `published == converged`, one line, with keyset / value-drift /
provenance diagnosis ON THE ERROR PATH ONLY. The keyset form is retained in the document WITH ITS NUMBERS so
a reviewer choosing the cheaper form does so with the blind spot in view.

════ FALSE POSITIVES — ZERO ON 1982 TESTS, AND THE GREEN IS NOT VACUOUS ════
ci#tests 1911/1911 and parity#tests 71/71 on the unpatched tree, on the proposal, and on all three
intermediate forms — the real command ci.yml runs.
★ REACHABILITY CONTROL: the proposal WITH ITS CONDITION INVERTED fails 455/1911 ci and 29/71 parity, naming
≥40 distinct scope ids. The check site is genuinely exercised, so the 1982 green is a measurement and not a
dead branch.
TOTALITY MATRIX — 11 degenerate/legal inputs, byte-identical to unpatched, INCLUDING THE TWO THAT BREAK A
TOO-STRICT DETECTOR: the ABW-legal POSITIVE CYCLE (Definition 3 condition 1 admits same-stratum positive
reads) and the cross-iteration positive chain. Single-writer B1 keeps precedence (owners forced first),
measured on two fixtures.

════ COST, MEASURED ════
+0.4711% nrThunks (+687,906) · +0.4058% nrFunctionCalls · +0.3231% values, over the whole ci set.
Error-path provenance is FREE in the green case (identical nrThunks with and without it). NO WALL-CLOCK CLAIM
— CPU ranges overlap between trees, and the author says so rather than quoting a number.
The keyset form is ~20× cheaper (+0.0223% thunks) and is recorded in full with its numbers.

════ ★ THE ONE HONEST COST, AND IT SPAWNED A SEPARATE FINDING ════
The value-level comparison FORCES enrichment values. Measured with a control: a value that is fine at the
stratum probe but throws at the real context lands SILENTLY UNFORCED today and ABORTS under the proposal; its
non-throwing twin is green everywhere.
BOUNDED BY A SECOND MEASUREMENT: the shipped probe ALREADY forces every enrich value — and on the UNPATCHED
tree, a policy whose enrich value throws has its key SILENTLY DROPPED from the context (force.nix, with
control). ⇒ SEPARATE SILENT-FAILURE DEFECT ON THE SAME FEED at lib/concern-policies.nix:343-345. The author
did NOT fold it in and returned it as a review candidate rather than a bead. FILED AS den-hoag-4kh.14.

════ CITATIONS — CHECKED BY THE AUTHOR AGAINST THE ARCHIVE ════
Theorem 7 p.111 (next page header reads "112 Apt, Blair, and Walker"); the supportedness definition p.95
(prose, intact); Lemma 1 pp.97-98; Definition 3 p.96 via the archivist reconstruction.
★ IT DID NOT TAKE THE INCLUSION DIRECTIONS FROM LEMMAS 2/3 ON p.100 — THE OCR RENDERS BOTH SYMBOLS AS "~"
AND CANNOT BE READ. The spec says so and derives the directions from the p.95 prose instead. That is the
correct handling of the archive's known OCR hazard, applied unprompted to a passage nobody had flagged.

════ COULD NOT SUBSTANTIATE — stated as limits ════
· Whether any den-configs config CLOSES THE CYCLE at runtime. Not re-searched; the bead's "neither confirmed
  nor refuted" stands unchanged. ★ THIS IS THE ONE FACT SEPARATING "1982 tests unaffected" FROM "corpus
  unaffected", and parity#tests deliberately does not force the corpus input, so the FP measurement does not
  cover it.
· The L4/`negates` domain claims — taken from the bead, marked [unverified — bead], left to 4kh.11.
· nix-config not searched.
SCOPE DISCIPLINE: 4kh.11 overlap checked and DISJOINT — its file set (stratum-scope / concern-derived /
claim-accessor / resolution-relations) does not intersect this one (attributes/structural.nix + errors.nix);
§11 states it and neither conclusion depends on the other.


### 3 — 2026-07-28T04:03:31 · Jason Bowman

★ COMMIT HOLD IN FORCE while the supportedness spec is under gate review (md5 710fecbceb0b5876588ce4bd55deaf6d).
Recorded because the same trap already sprang once this arc: a comment-only commit (a40cc96) landed AFTER a
different spec was frozen and shifted every line number it cited. FREEZING A SPEC DOES NOT FREEZE THE TREE IT
CITES.

DO NOT COMMIT TO THESE FIVE FILES UNTIL THE VERDICT:
  lib/attributes/structural.nix        ~20 citations — the concentration is §2
  lib/errors.nix                        5 citations (:124-126 singleWriter, :5 the fail idiom, :21/84/118/209)
  lib/concern-policies.nix              5 citations (:342, :413, and :343-345 — the den-hoag-4kh.14 site)
  lib/attributes/output-modules.nix     :998-1013 bindingsAt — ★ THE PROPAGATION-PATH CITATION, load-bearing
                                        for "the unsupported fact reaches materialized output"
  ci/tests/b1-single-writer.nix         :141-145, the abort-assertion idiom the test plan builds on
The last two were NOT on the orchestrator's list; the author volunteered them.

★★ THE HASHED ARTEFACT IS SAFE, AND THIS WAS CHECKED RATHER THAN ASSUMED. The executable core block cites
structural.nix at spec lines 240-245 — but every one of those citations is INSIDE A `#` COMMENT. The author
ran the gate's own protocol (extract :234-290, strip comments, scan for `:NNN`) and it returns NOTHING; same
for the error builder at :297-306, which carries no line refs at all before or after stripping. ⇒ A
COMMENT-ONLY COMMIT CANNOT MOVE THE COMMENT-STRIPPED HASH OF EITHER BLOCK. The exposure is entirely in prose.
That is the property the reviewable-artefact discipline is supposed to deliver, and here it was verified
instead of hoped for.

★ NOT AT RISK, AND FOR THE RIGHT REASON: gen-scope@ceabe5e/lib/resolve.nix:302-322 and
gen-derive@8f537ec/lib/core/rule.nix:29-48 are cited WITH THEIR PINNED REVISIONS, so no den-hoag commit can
move them — only a flake.lock bump could. ABW citations are printed-page numbers and are immune to
everything. ⇒ GENERAL PRACTICE WORTH ADOPTING: CITE CROSS-REPO REFERENCES WITH THE PINNED REV. A bare
`gen-scope/lib/resolve.nix:302` would have been silently invalidated by an input bump with nothing to detect
it; `gen-scope@ceabe5e/...` cannot be.

ALSO RECORDED BY THE AUTHOR, verified with `git diff --stat`: structural.nix is BYTE-IDENTICAL at 6fc4ada and
a40cc96, and the entire lib/ delta between those revisions is the concern-derived.nix comment block. So this
spec's line numbers are correct against BOTH revisions, and the claim is already in its header — a reviewer
questioning which tree they belong to has the answer in the document.


### 4 — 2026-07-28T04:21:44 · Jason Bowman

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


### 5 — 2026-07-28T04:22:35 · Jason Bowman

★★★ GATE REVIEW — 4kh.13 ctx-supportedness design. VERDICT: REDESIGN (narrow — two additions to §11).
Freeze HELD (md5 710fecbceb0b5876588ce4bd55deaf6d, 619 lines). dh-base verified byte-identical to repo lib/.
EVERY NUMBER IN THE DOCUMENT REPRODUCED. The runtime law is SOUND on everything the reviewer could construct.
It fails C7 — and the evidence that settles C7 was sitting in the sibling spec §11 declared independence from.

════ C7 — THE SPEC NEVER ASKED THE CONSTRUCTION QUESTION ════
§4's proof that rejection is FORCED is airtight GIVEN THE SURFACE. The reviewer hand-derived T_P from
gen-derive/lib/core/rule.nix:29-48 BEFORE looking at tp.nix, then re-ran the probe: all four transitions
match, and it went further than the author — checking the conclusion is not an artefact of the chosen VALUES:
T_P({b=v}) = {} for EVERY v, and T_P({a=v,b=w}) = {b} for EVERY v,w. `a` is never re-derived, SO NO VALUATION
IS A FIXED POINT. No repair exists.
BUT §11 only rules out a static signed-graph DETECTOR. It never asks whether THE SURFACE COULD DENY THE
OBSERVATION. Full construction + the ABW p.100 monotone/nonmonotone axis + the ~13-site corpus cost + the
a40cc96 L4 precedent: recorded in the CROSS-DESIGN COUPLING comment on this bead. Not repeated here.
THREE THINGS MAKE IT A FINDING RATHER THAN A NITPICK: (1) `projectCtx` (lib/concern-policies.nix:119-133) is
NEVER MENTIONED — the shipped per-rule ctx restriction, the natural seat of such a construction, and THIS
BEAD names it as "the only ctx-key guard"; §2.1 enumerates what does not catch the defect and omits it.
(2) the live tree carries a freshly-committed ruling on exactly this axis (a40cc96), neither cited as
precedent nor distinguished. (3) the cost is a legitimate reason to REJECT — but "the corpus does it" is not
a theory argument under the standing bar, and a rejection without its reason gets re-proposed.

════ WHAT REPRODUCED — all from command output ════
· KEYSET BLIND SPOT: dh-weak publishes {"x":110,"y":11} and THE KEYSET CHECK PASSES; dh-final aborts
  `drifted=[x<-driftX]`. Loop traced by hand and agrees (converged {x=10,y=11}, published {x=110,y=11}).
  THE 20×-MORE-EXPENSIVE FORM IS JUSTIFIED.
· TOTALITY: all 13 rows re-run on three trees, per arm. 8 byte-identical, 3 true positives with exact
  messages, both B1 rows abort with the single-writer collision on all three trees INCLUDING the row where an
  unsupported key co-exists. ★ THE TOO-STRICT FAILURE MODE DOES NOT MATERIALIZE on anything constructible —
  the ABW Def-3-cond-1 ungrounded positive cycle, the 3-iteration positive chain and the
  defaulted-formal-converging-supported case are all UNTOUCHED. The reviewer also FAILED TO CONSTRUCT a false
  positive analytically, WITH A REASON: the loop returns `next`, not `prev`, so values get one refresh past
  keyset stabilization, and a key whose value still moves at convergence necessarily sits in a value cycle
  whose members are read.
· SUITES EXACT: dh-base 1911/1911 + 71/71; dh-final identical; dh-ctrl 1456/1911 + 42/71 (455 and 29
  failures) naming EXACTLY 40 distinct scope ids.
· COST MATCHES TO THE UNIT: nrThunks +687,906 (+0.4711%), nrFunctionCalls +436,611, nrPrimOpCalls +223,626,
  nrOpUpdates +41,877, values.number +861,546. ★ The reviewer's cpuTime run had THE PROPOSAL FASTER than base
  (26.63 vs 29.70 s) — "the refusal to make a wall-clock claim was honest". Keyset ratio 28.5× on its
  revision vs the document's "roughly 20×" — THE GAP IS WIDER THAN STATED, cutting in the document's favour.
· CITATIONS: all four verbatim. ★ THE p.100 REFUSAL WAS NECESSARY — Lemma 2 reads "Tp(I) ~ I" and Lemma 3
  "Tp(l) ~I": BOTH inclusions are `~`, direction unreadable, exactly as claimed. And the p.95 derivation DOES
  support the directions used (model: T_P(I) ⊆ I; supported: I ⊆ T_P(I) from "every A ∈ I is the head of a
  firing clause"), so I = T_P(I) is correctly derived. Theorem 7 p.111 verbatim. No numbered section cited.
· PURE-GRAPH CRITERIA CLEAN. Criterion 6 is the one it FIXES — structural.nix:96-99 documented an invariant
  nothing enforced. §5.1's refusal to put this behind a den.features flag is correctly argued: a removability
  gate on a soundness invariant gates whether the kernel may be WRONG.

════ OTHER FINDINGS ════
F3 §9.1's cost MECHANISM is false (the bottom line is not). "Values inherited from `base` are shared pointers
   on both sides and are not re-forced." MEASURED, Nix 2.34.8: `let t = throw "SHARED-SELF"; base = {k=t;};
   in base == base` THROWS — attrset `==` calls forceValue on each attribute BEFORE the pointer-equality
   short-circuit. So the newly-forced set is every enrichment value PLUS EVERY TOP-LEVEL INHERITED-CONTEXT
   VALUE TO WHNF, and the bound offered in §8.3 and on den-hoag-4kh.14 covers only the first half.
   ★ HONEST LIMIT, stated by the reviewer: it could NOT construct a fleet where an inherited-context value is
   an unforced throwing thunk (inherited-context folds node.decls; in a minimal fleet the only top-level ctx
   keys are __entry and node, both attrsets, so WHNF is total). "I claim the statement is false; I do not
   claim a reachable new abort from it."
F4 §8.2 MISDESCRIBES ITS OWN CONTROL. It calls dh-ctrl "the proposal with its condition inverted"; the
   variant script's own comment reads "INVERTED weak" — dh-ctrl inverts the KEYSET predicate, so NOTHING
   MEASURED SHOWED THE VALUE-LEVEL COMPARISON IS EXERCISED. ★ THE REVIEWER BUILT THE MISSING CONTROL
   (dh-vctrl = dh-final with `supported` inverted) and ran it: 1456/1911, 40 scope ids — IDENTICAL. The
   conclusion stands; the artefact was mislabelled, which matters in a document whose §12 stakes itself on
   command output. Related: dh-weak/dh-ctrl sit on 6fc4ada and carry an extra COMMENT-ONLY delta; §9.2
   discloses this for the cost table, §8.1 lists dh-ctrl as though at a40cc96. No non-comment line differs.
F5 ★ C5 VOCABULARY DEFECT THE ARCHIVE EXPLICITLY WARNS AGAINST. §4 says "no PERFECT MODEL exists", attributed
   to ABW's construction. The archive's own TERMINOLOGY WARNING: "perfect model" appears once, p.144,
   CREDITED TO PRZYMUSINSKI; ABW's is the STANDARD MODEL M_P (p.108). The spec uses M_P correctly everywhere
   else. ⇒ THIS IS THE THIRD MIGRATION OF THAT TERM IN THIS ARC — it reached INDEX.md via the orchestrator
   and was corrected there. The archive warning exists precisely because the term travels.
F6 verbatim nits: §2 quotes structural.nix:96-99 as "verbatim" while dropping "(below)"; §1.3 says the p.95
   passage "survives OCR intact" when the load-bearing gloss does but the symbolic first sentence does not;
   §5 cites errors.nix:209 for `concatStringsSep ", "` — that line is `" and "`.

════ CONFIDENCE vs STATED LIMITS — IT HOLDS THEM ════
§8.1's headline is "zero false positives on 1982 tests", NEVER "on the corpus"; §8.3 says outright "the
external corpus is unmeasured". The reviewer confirms `parity#tests` does not force the corpus input. The
[unverified — bead] markings are placed correctly.

════ WHAT WOULD MAKE IT ADMISSIBLE — NOT A RE-MEASUREMENT ════
1. §11 must ASK AND ANSWER the construction question (closed pattern lambdas), state that under it the law is
   a THEOREM, and either take it or state the reason for rejecting it — citing `projectCtx` and the a40cc96
   concern-derived.nix:126 ruling as the precedent being distinguished.
2. §11 must RETRACT "neither conclusion depends on the other" — see the CROSS-DESIGN COUPLING comment.
Plus: correct §9.1 (shared pointers ARE forced to WHNF), relabel dh-ctrl as the inverted KEYSET form, drop
"perfect model", fix the F6 nits.

════ REVIEWER COVERAGE — HONEST ════
READ IN FULL: the spec; beads 4kh.13 and 4kh.14; structural.nix:38-173; concern-policies.nix:100-170,320-430;
gen-derive/lib/core/rule.nix; cited lines of errors.nix, b1-single-writer.nix, output-modules.nix:998-1013;
ABW pp. 95, 97-98, 100, 111 + archivist note; tp.nix, tot.nix, force.nix, strict.nix, mkvariants.py.
GREPPED ONLY: the 4kh.11 spec (86.8K) — file refs, §4.1, and the projectCtx block. NOT read in full.
★ COULD NOT EVALUATE: whether any den-configs config closes the cycle at runtime (the spec's own named gap);
nix-config; the L4/negates domain claims; AND — IT DID NOT RE-FORCE
`nixosConfigurations.bare.config.networking.domain`. It verified BY READING that output-modules.nix:998-1013
is the propagation site, but "IT REACHES MATERIALIZED OUTPUT" RESTS ON THE BEAD'S RECORD, NOT ON ITS OWN RUN.
New probes: rev-basestrict.nix, rev-basestrict2.nix, dh-vctrl/, rev-tot/, rev-suites/, rev-stats/.


### 6 — 2026-07-28T04:52:01 · Jason Bowman

★★★ GATE RE-REVIEW — 4kh.13 ctx-supportedness, revision 2. VERDICT: VALIDATED.
Integrity self-checked: md5 ef754f752ed8a932e19be54723a8b005 · 832 lines · core :266-322 →
f0010113ac88b82ff2befa4414f9efe3 · error builder :329-338 → 054cdef94788917f52a0d34f5aeb92a8 · HEAD a40cc96.
★ IT DID NOT TAKE "CORE UNMOVED" ON THE HASH RELAY — it TOKEN-COMPARED rev2's core against `dh-final`, the
tree it ran the suites, matrix and counters on. Bindings token-identical (`published`, `supported`, `dropped`,
`drifted`, `provenance` one-for-one); only deltas are the disclosed probe-throw tail and an inline-vs-named
`whoWrote`. ⇒ ITS ROUND-1 MEASUREMENTS TRANSFER IN FULL; no re-run needed and none was done.

WHAT IS VALIDATED: THE DESIGN — the runtime law `published == converged` at structural.nix attribute 2, its
rejection semantics, and §11.1's rejection-with-reasons of the construction. NOT an implementation. Three
DOCUMENTATION corrections owed before landing; none touches core, theory or decision.

════ ★ C7 — THE REJECTION HOLDS. THE REVIEWER ATTACKED IT AND FAILED. ════
(d) VERIFIED BY THE REVIEWER ITSELF, and it refutes the reviewer's OWN round-1 finding at its foundation:
`p = { node }: [ … ]` → "error: function 'p' called with unexpected argument '__entry'"; open twin →
["__entry","node","z"] as control. gen-derive/lib/core/rule.nix:36 is `produce = _id: ctx: fn ctx` — THE BODY
IS APPLIED TO THE WHOLE CONTEXT. "My round-1 construction was UNDER-SPECIFIED: I wrote it as 'ban ... and
defaults' while silently assuming a projection that does not exist." It requires projectCtx to become
key-restricting first — materially larger, and landing on the mechanism 4kh.11 is concurrently changing.
(a) HOLDS, AND IS SUPPORTED FROM THE DOCUMENT'S OWN MATRIX — STRONGER THAN ITS PROSE. Two §7 rows are LEGAL
STRATIFIED PROGRAMS WITH NEGATION that the construction would make INEXPRESSIBLE:
  · t-one-negative — `ctx: if ctx ? b …` with no writer of b. Negative edge, no cycle ⇒ stratified by
    Lemma 1 ⇒ Theorem 7 applies. Measured identical on both trees.
  · t-defaulted-formal — `{ g ? "DEFAULT", ... }` with a writer of g; the spec's own label is "a negative
    edge that converges supported". ★ THIS IS THE SHAPE BEAD 4kh.13 Q4 RECORDS IN SHIPPED CONFIG
    (nixfos users.nix:94-98).
  ⇒ THE CONSTRUCTION FAILS C4 IN THE OVER-STRICT DIRECTION AT THE LANGUAGE LEVEL: it rejects programs
  Theorem 7 CERTIFIES. That is the decisive form of (a), and it is a theory argument.
★★ AND THE REVIEWER'S OWN p.100 CITATION WAS WRONG — the author was right to turn it around. Re-read in
context: "Several results concerning positive programs depend critically on the properties (a), (b), and (c).
Fortunately, a very important property remains true. [LEMMA 2] … In view of Lemmas 2 and 3 … minimal fixed
points … Thus, we are brought to study the fixed points of NONMONOTONIC operators." THE PASSAGE IS ABW
COMMITTING TO THE NONMONOTONIC SETTING — moving PAST the positive fragment, not endorsing a retreat to it.
"I cited it for the opposite of what it says." ★ THE ORCHESTRATOR PROPAGATED THAT CITATION IN THE DISPATCH.
§11.1 nevertheless GRANTS the observation as "the strongest form of the construction's case" before
rebutting it — the right handling.
(b) HOLDS — stratification is the theory-preferred construction, needs signed edges, sign not derivable. (c)
HOLDS and is honest about being CONTINGENT — true while a compat layer exists, and §11.1 records the
construction as a COMPATIBLE NARROWING under which the check would guard the compat boundary.
★ THE REVIEWER PRESSED FOR A FIFTH OPTION AND IT COLLAPSES INTO (d): declared negative edges
(`{ __negates = [...]; fn = …; }`) DO exist as a surface (concern-policies.nix:146-150) and would permit
compile-time stratification — but A DECLARATION IS ADVISORY UNLESS ENFORCED, and VALUE-replacement cannot
enforce it: poisoning a value does not stop `ctx ? k`. ONLY KEY-RESTRICTION DOES. So (b) and (d) jointly
close the space. "The rejection is more robust than I expected."

════ THE a40cc96 PRECEDENT DISTINCTION — VERIFIED SOUND, with one precision point ════
Each leg checked: `enrichments` carries stratum="structural" (structural.nix:108) ✓; `base` is
inherited-context, extracting from ancestors' node.decls (:42-66) — no derive output enters it ✓;
`declarations` dispatches over enriched-context, strictly downstream, and :175-187 records linked-context
reaching resolution and beyond only ✓. ⇒ A DERIVE'S OBSERVATION CANNOT FEED THE ENRICHMENT FIXPOINT: no cycle
is constructible there, so preserving the observation is SOUND in L4 and UNSOUND here. Downstream vs upstream
of itself. The distinction is real and correctly drawn.
PRECISION POINT: the ruling lives at lib/concern-derived.nix:126 (the L4 CEILING GATE) while projectCtx is
lib/concern-policies.nix:119-133. TWO GATES, ONE PHILOSOPHY. §11.1(d) argues by analogy and does present the
ruling as distinguishable rather than identical, so it is fair — but should say "the same philosophy applied
to a SIBLING GATE" so a reader does not infer the ruling was about projectCtx itself.

════ THE FOUR CORRECTIONS — ALL APPLIED, TWO EXCEED WHAT WAS ASKED ════
§9.1 corrected AND the author reproduced the Nix `==` forcing independently; the reviewer re-ran their second
expression (the proposal's own shape with a shared throwing base value) — throws, non-throwing twin returns
true ✓. §8.1/§8.2 relabelled, dh-vctrl credited to the reviewer and marked not-built-not-run, † footnote now
discloses which trees sit on 6fc4ada ✓. "perfect model" → "no standard model M_P" with p.108 attribution and
the p.144 Przymusinski warning quoted in-line ✓. F6 nits all fixed ✓.
★ §2.1's projectCtx entry is BETTER THAN REQUESTED — it adds a new verified fact: ctxKeyStrata is seeded { }
at BOTH production sites, non-empty only in tests, so projectCtx is THE IDENTITY ON EVERY SHIPPED FLEET. The
reviewer verified all sites with rg AND cross-checked with grep (10 sites both): production
concern-policies.nix:92 and default.nix:1453 both `= { }`; non-empty only at edge-substrate.nix:619,647
(:596 is `= { }`). MORE PRECISE THAN 4kh.11's "three test sites".

════ C8 — PASS, NO FINDINGS ════
(a) No construction chosen to reproduce current output — it picks the MORE EXPENSIVE, MORE THEORY-FAITHFUL
value-level form over the cheaper keyset one. §5.1 leaves the loop's `eq` alone on a DIAGNOSTIC-QUALITY
ground, not a parity ground. (b) "parity" appears only as a test-suite name; no "would break parity"
defence, no drvPath or oracle appeal. (c) Suite green framed as false-positive EVIDENCE with a reachability
control, not as acceptance; §10 deliberately lands known-fails and §7's three ★ rows are intended behaviour
changes — the symmetry clause working. (d) §7 names its notion explicitly. ★ THE IDENTITY HERE IS
STRUCTURALLY FREE — the check returns the same value when it holds, adding no attribute and no node state —
which is exactly the priority order's case 2. Worth a sentence saying identity is OBSERVED, not PURCHASED.

════ ★ C9 — ONE FINDING, AND THE ANSWER IS FAVOURABLE ════
The reviewer READ the register (den-hoag-4kh.17) rather than relying on a word sweep. Items 1, 2, 3 clean.
★ ITEM 4 — `__`-PREFIXED STATE CARRIERS — IS TOUCHED. `inherited-context` is one of the four hand-maintained
strip lists: structural.nix:42-66,
`removeAttrs (node.decls or { }) [ "__edges" "__containment" "__coords" "__root" "suppressedPolicies" ]`.
That strip list is the DIRECT SOURCE of the design's `base`; dropped/drifted range over `attrNames converged`
whose composition it governs; and the surviving `__entry` carrier is forced to WHNF at every node by the law.
§6 dismisses this in ONE CLAUSE — "it does not re-open the __-key or bucket holdover questions" — CITING NO
TRACKER AND STATING NEITHER THEORY NOR MECHANISM SURVIVAL, which is precisely the shape C9 exists to catch.
THE SUBSTANTIVE ANSWER IS GOOD AND SHOULD BE RECORDED RATHER THAN ASSUMED: theory survives untouched
(`published == converged` is indifferent to which keys are carriers); MECHANISM SURVIVES AND IMPROVES — under
retirement 4 the carriers become graph edges, the ctx keyset shrinks to actual facts, the comparison gets
cheaper, and ★ §9.1's newly-corrected forcing set COLLAPSES BACK TO THE ENRICHMENT VALUES ALONE, exactly the
half §8.3's bound already covers. RETIREMENT 4 RETIRES THIS DESIGN'S ONE OPEN COST CAVEAT.
FAIRNESS: 4kh.17 was created the same day as the spec, so the register may postdate authoring. The
requirement still stands at review; the remedy is a paragraph. C9-a PASS — vocabulary is
published/converged/supported/dropped/drifted/provenance, no bucket or accumulator vocabulary.

════ ★ ONE MEASURED FIGURE DOES NOT REPRODUCE — §9.2's SECOND TABLE IS CONFOUNDED ════
§9.2 concludes "the provenance diagnosis is FREE in the green case — identical nrThunks to the form without
it". THE PAIR IT DRAWS THAT FROM DIFFERS BY TWO CHANGES IN OPPOSITE COST DIRECTIONS, not by provenance:
dh-weak2 DROPS the `published = base // added` binding AND adds provenance. Measured against a common base:
    dh-weak  (keyset, published bound, no provenance)      +24,112 thunks / +11,446 calls
    dh-weak2 (keyset via base/added, no published, +prov)  +32,523 thunks / +16,982 calls
The document reports BOTH rows at +32,523. ★ THE REVIEWER RAN THE CLEAN ISOLATION THE DOCUMENT LACKS —
dh-strong (value compare, no diagnosis) vs dh-final (value compare + full diagnosis), differing ONLY by the
error-path bindings: VALUE-LEVEL COMPARISON ALONE +684,146 thunks (99.45% of the proposal's total); THE
ENTIRE ERROR-PATH DIAGNOSIS +3,760 thunks / +240 calls — 0.55% of the delta, 0.0026% of evaluation.
⇒ THE CONCLUSION IS TRUE AND NOW BETTER SUPPORTED THAN THE DOCUMENT SUPPORTS IT. Swap the confounded pair for
dh-strong/dh-final and the claim is airtight. Related: the keyset-vs-value ratio on a common base is 28×, not
"roughly 20×" — IN THE DOCUMENT'S OWN DISFAVOUR, and it does not change §9.3.
The headline cost table is UNAFFECTED — every absolute delta reproduced to the unit in round 1.

════ WORDING PRECISION ════
§6 says the check "adds no node state, no accumulator". `provenance.step` IS an accumulating fold
(`acc = { ctx; own }`) over iterations. It adds no NODE state — nothing lands on the graph — and the
accumulator is local, lazy, error-path-only and provably necessary (scope.circular discards intermediates,
gen-scope/lib/resolve.nix:302-322). GIVEN C9's STATED LESSON IS "CRITERION 1 APPLIED ONE LEVEL TOO SHALLOW",
A DOCUMENT ABOUT TO BE VALIDATED SHOULD NOT LEAVE A BARE "NO ACCUMULATOR" STANDING.

════ OWED BEFORE LANDING — DOCUMENTATION ONLY ════
1. §9.2 — replace the confounded dh-weak/dh-weak2 pair with dh-strong/dh-final (+3,760 thunks / +240 calls);
   correct "roughly 20×" to 28×.
2. §6 — cite den-hoag-4kh.17 item 4, state theory-survives / mechanism-improves, tighten "no accumulator".
3. §11.1(d) — say the a40cc96 ruling is a SIBLING GATE, not projectCtx itself.

════ COVERAGE ════
READ IN FULL: rev2 all 832 lines; the register; 4kh.6's C8 and C9; ABW p.100 IN CONTEXT.
RAN: the closed-lambda probe; the §9.1 expression plus a non-throwing control; NIX_SHOW_STATS on dh-weak2 and
dh-strong (new); rg+grep cross-check of all ctxKeyStrata sites; token comparison of rev2's core against
dh-final.
NOT RE-RUN, DELIBERATELY: suites, totality matrix, T_P enumeration, headline counters — the core is
token-identical to the tree those were taken from, so they transfer.
★ STILL UNMEASURED BY ANYONE, correctly named in §12: whether any den-configs config closes the cycle at
runtime; nix-config; the L4/negates domain claims. AND the reviewer did NOT re-run qA-propagate/qB-shape, so
§1.2's MATERIALIZATION claim still rests on the bead's record and a reading of output-modules.nix:998-1013,
not on its own force.


### 7 — 2026-07-28T05:54:44 · Jason Bowman

DOC-DEBT ROUND 1 — 2 of 3 corrections APPLIED, 1 WITHDRAWN AS TARGETLESS. File now 842 lines, md5 e19cb98f191995aa5cb47905ad14b0d4 (was 832 / ef754f75…). Core :266-322 and the error builder :329-338 are at the SAME line numbers and BYTE-UNTOUCHED — every edit landed at :365+.

(B1) APPLIED, :552-568. The confounded pair is split: row 3 relabelled `dh-strong`, rows 1/2 given their `dh-weak`/`dh-weak2` labels so the split reads, and a new paragraph names both configurations and attributes **dh-final = +3,760 nrThunks / +240 nrFunctionCalls over dh-strong**. values.number for that step is stated UNMEASURED rather than estimated.
  ★ A NECESSARY ADJACENT CORRECTION, accepted: §9.2 had claimed the provenance diagnosis is 'FREE in the green case — identical nrThunks'. Once dh-final is attributed at +3,760 thunks that is FALSE unqualified. Now split: free in nrThunks AT THE KEYSET LEVEL (dh-weak2 == dh-weak, expressions never forced), NOT free at the value level. Leaving 'free' would have been a load-bearing prose claim contradicted by the table immediately above it.
(B3) part 1 APPLIED, §6 :370-371 — den-hoag-4kh.17 item 4 now cited at the `__`-key sentence. No prior 4kh.17 citation existed in either spec.
(B3) part 2 ★ WITHDRAWN — NOT-FOUND, and correctly not forced. I asked for §11.1(d) to read 'sibling gate'. THERE IS NO SUCH TARGET: §11.1(d) is :668-696 and its only 'gate' is inside a VERBATIM quote of lib/concern-derived.nix:126. A regex over BOTH specs for (sibling|twin|parent|child|cousin|peer|companion|adjacent) within 40 chars of (gate|guard), both directions, returned ZERO. 'sibling' occurs twice in this file (:8, :578) and neither is in §11.1(d) nor wrong. I cannot produce the sentence the correction was meant to fix, so it is withdrawn rather than re-aimed. Recorded so it is not re-proposed.

(B2) ★ APPLIED AS INSTRUCTED AND THE INSTRUCTION WAS WRONG — now in round 2. I asked for 'roughly 20×' → 28×. Two problems, both found by the applying agent: the figure occurs TWICE (:568 and :572, the second as '~20× cheaper'), so a single-site edit would have made the doc self-contradictory — both were changed. And **28× IS NOT DERIVABLE FROM ANY FIGURE PRINTED IN EITHER TABLE.** The printed ratios are nrThunks 692,557/32,523 = 21.3×, nrFunctionCalls 441,697/16,772 = 26.3×, values.number 868,266/35,012 = 24.8×. Nothing yields 28.
  ⇒ MY CORRECTION MADE THE DOC ASSERT A RATIO A READER CANNOT CHECK — the exact defect class den-hoag-4kh.11's A2 was raised to remove. Round 2 replaces both sites with the three derivable ratios, named by counter and stated as a 21–26× range, so every figure is checkable against the table on the same page.

ALSO IN ROUND 2, flagged by the agent and pre-existing: :549-550 says the comparison table was taken 'against a base run on the immediately preceding revision', while §8.1 puts `dh-weak2` at a40cc96 and only `dh-weak`/`dh-strong` at 6fc4ada. Those cannot both hold; a measurement with self-contradictory provenance cannot be reproduced.

### 8 — 2026-07-28T05:59:22 · Jason Bowman

DOC-DEBT ROUND 2 — COMPLETE. File 842 → 852 lines, md5 78eba65543ca5a3b1bc75b0576f917d0.
★ CORE + ERROR BUILDER BYTE-IDENTICAL, HASH-PROVEN: (266-322, 329-338) hash to e343805a1de0c77f5edaab4446f21de5, EXACT match to round 1, line numbers UNMOVED — every round-2 edit landed at 549+ and 738+.

(1) APPLIED :738-746 — re-quoted against den-hoag-4kh.11's new comment, verified mechanically rather than by eye. §11.2's argument is preserved and is now stronger: the invariance it depends on is a COROLLARY of a key-set argument (mapAttrs iterates ctx, every key projected, none escapes) instead of a bare uniqueness claim. The 'this defect exists BECAUSE `ctx ? key` is observable' pivot is untouched. :750-751's paraphrase re-checked against the new wording and still accurate.
(2) APPLIED :572-575, :579 — 28× REMOVED EVERYWHERE, 20× not reinstated (grep: zero hits for 28×, 20×, ~20, 'roughly 20'). ★ The three ratios were INDEPENDENTLY RECOMPUTED before use and all confirmed: 692,557/32,523 = 21.29 → 21.3× · 868,266/35,012 = 24.80 → 24.8× · 441,697/16,772 = 26.34 → 26.3×. Now reads '21–26× the keyset form, depending on which counter is read', with all three named and their divisions printed inline — every figure checkable against the table on the same page.
(5) APPLIED :549-554 — §8.1 wins: `dh-weak`/`dh-strong` at 6fc4ada, `dh-weak2` at a40cc96, the two revisions differing by COMMENT TEXT ONLY (§8.1 †), so a base run at either is the same measurement and the rows are comparable. ★ AND THE AGENT DECLINED TO INVENT THE MISSING HALF: that `dh-weak2` was differenced against `dh-base@a40cc96` is the natural reading, but NOTHING IN THE TREE STATES IT, so the doc now records the tree revision of each run AND flags which individual base run each delta was differenced against as UNRECORDED. That is the right answer — a plausible reconstruction written as fact is how the confounded pair happened in the first place.
(6) Withdrawn item: no action, settled.

★ RESIDUAL, FLAGGED AND DELIBERATELY NOT PAPERED OVER — THE TWO §9.2 TABLES CANNOT BE RECONCILED ARITHMETICALLY. Table 1 (proposal vs unpatched, at a40cc96) gives +687,906 thunks / +436,611 calls. Table 2's `dh-strong` row gives +692,557 / +441,697. And `dh-final` is now stated as dh-strong +3,760, predicting ~696,317 — not 687,906. THE THREE FIGURES CANNOT ALL BE DIFFERENCES AGAINST A COMMON BASE.
Nothing in the doc is FALSE — post-(5) it explicitly does not claim a common base, and names the pairing as unrecorded. But anyone later attempting to reconcile the two tables WILL FAIL, and will not know whether the fault is theirs. NOT FIXABLE WITHOUT THE RAW RUNS. Settled by re-running all three configurations against one recorded base and reprinting both tables; until then this note is the record that the discrepancy is known and expected rather than an undetected error.
ACCEPTED JUDGMENT CALL: a clause was added beyond instruction — 'Both rows are at 6fc4ada, so the ratio is revision-controlled.' True per §8.1 and it is what keeps the ratio clean now that (5) exposes the tree revisions. Kept.

### 9 — 2026-07-28T06:23:28 · Jason Bowman

★ SHIPPED — ec6ba23. The P0 is FIXED. Verified independently by the orchestrator, not accepted on report.

INDEPENDENT VERIFICATION, exit status captured directly rather than through a pipe: witness suite 11/11 EXIT=0; `nix-unit --flake ./ci#tests` 1922/1922 CI_EXIT=0; `nix-unit --flake ./parity#tests` 71/71 PARITY_EXIT=0.
★ MY FIRST ATTEMPT AT THAT VERIFICATION WAS ITSELF BROKEN, and it is the trap I brief every agent about: I read `${PIPESTATUS[0]}` after an intervening `echo`, which had already reset it, so the exit status came back EMPTY and I nearly recorded '11/11' as green without an exit code. Re-run writing to a file and reading `$?` directly. 'runner | tail && commit' masks failure; so does any exit-status read that is not immediately adjacent to the command.

CORE FIT THE TREE UNCHANGED, and was verified STRUCTURALLY rather than by line-number trust: the pristine `lib/attributes/structural.nix` is byte-identical to HEAD's, and every binding the core names sits where the spec says — base :113, enrichAt :125-134, delta :135, converged :136-147, finalActs :148, added :149, owners :150-158, final expr :159-160. Implemented verbatim; `whoWrote` passed inline as the core writes it.

WITNESS, both halves RUN: pristine lib (law reverted, test file kept) 7/11 EXIT=1, with four reds each failing for the defect's own reason — test-negative-cycle-aborts, test-self-negative-aborts, test-value-drift-aborts, test-negative-cycle-aborts-at-the-crossing. Law applied: 11/11 EXIT=0. The seven green rows pass on BOTH trees and are the false-positive surface.
POSITIVE CONTROL, TWO INDEPENDENT ARMS: (1) differential — test-value-drift-aborts has a converging keyset and a single writer per key, so neither the keyset check nor B1 can fire, and on the pristine tree it aborts NOWHERE (it publishes {"x":110,"y":11}, measured); an abort there is this law's and no other's. (2) By message, out-of-suite — the drift case names 'context supportedness (ABW p.95)' with the drifted key and its writer and NO empty dropped-clause (renderKeys correct), the cycle case names the dropped key and its writer, and the two-writer case still yields the B1 single-writer error, so THE NEW GUARD DID NOT PREEMPT B1. The crossing arm has its own control: test-crossing-materializes-supported-key materializes on BOTH trees, so the crossing abort is the cycle's and not the crossing's.

COST, measured law-only with the same test set on both sides: nrThunks +0.4762%, nrFunctionCalls +0.4110%, nrPrimOpCalls +0.4363%, nrOpUpdates +0.4505%, values.number +0.3269% — reproducing spec §9.2 (+0.4711/+0.4058/+0.4305/+0.4452/+0.3231%). No wall-clock claim made; cpuTime varied 27.05s vs 31.90s on single runs and was correctly not quoted. Instrument non-vacuity proven by deepSeq PLUS an aborting sentinel injected at depth 3.
COMPLEXITY STATED: one extra attrset update O(|base|+|added|) that attribute 3 already computes, plus `published == converged` which is O(|converged|) spine and FORCES EVERY TOP-LEVEL VALUE ON BOTH SIDES TO WHNF (Nix's attrset == forces before the pointer-equality short-circuit, so sharing does not save it). No extra dispatch pass, no extra fixpoint iteration, no new attribute, no node state. The error path's `provenance` re-runs the iteration, O(iterations × |enrich rules|), paid only while already aborting.

TWO DEVIATIONS FROM THE SPEC, both flagged rather than silently absorbed:
  §10's row `test-negative-cycle-names-dropped-key` IS NOT IMPLEMENTABLE IN-SUITE — mkCi's asserter has no message-text channel (ci/tests/_lib/den-compat-test.nix:27, ci/tests/compat-nested-class-named-aspect.nix:209) and `builtins.tryEval` yields only a bool. NOT shipped as a fake in-suite assertion; the naming is pinned out-of-suite and the file header records why. This is den-hoag-9mo (expectedError unassertable through checks.default) biting a real design.
  The materialization witness went in ci/tests/b1-supportedness.nix rather than binding-totality.nix, because that file's fleet already defines networking.domain from the collector aspect and a second consumer writing the same option collides. §10's stated reason for that file was fixture reuse, reproduced inline instead.
SPEC ERRATUM: §7's `t-positive-chain` expected JSON is mangled in the table (a backslash lost to markdown rendering). The measured value, identical on both trees, was pinned instead of the printed one.

NOT CLAIMED: the external corpus was NOT run — spec §12 records it unmeasured and blocked at the exclude-of-policy stub. So 'sound fleets unaffected' rests on 1993 suite tests, not on the corpus.

### 10 — 2026-07-28T07:40:45 · Jason Bowman

★ CORRECTION TO THIS BEAD'S DEVIATION-1 REASON, AND A COST FIGURE THAT DID NOT REPRODUCE.

(1) THE DEVIATION STANDS, ITS REASON DOES NOT. I recorded that §10's `test-negative-cycle-names-dropped-key` is 'NOT IMPLEMENTABLE IN-SUITE' because mkCi has no message-text channel and tryEval yields only a bool. MEASURED FALSE: nix-unit supports `expectedError` and it WORKS on `nix-unit --flake ./ci#tests` (probe green at 1923/1923; negative control with a changed msg RED at 1922/1923 — it discriminates). The real blocker is that gen's homegrown asserter evaluates `t.expr == t.expected` unconditionally, so such a test CRASHES `checks.default` (measured: exit 1 with the probe, exit 0 without). ⇒ The test could not have landed as specified WITHOUT BREAKING THE BATCH GATE, so the out-of-suite pinning was the right call — but for a different and narrower reason, and one with a known fix (teach assertTests to skip expectedError tests). Recorded at den-hoag-9mo.

(2) THE +0.48% COST FIGURE DID NOT REPRODUCE, AND THE SIGN DISAGREES. On a FIXTURE-FREE-BY-CONSTRUCTION workload (`parity#tests` — a separate flake that does not import ci/tests, so it cannot contain the guard's own fixtures), with deepSeq plus an aborting sentinel proving the force is real and stats deterministic across runs:
  nrThunks 5,010,008 → 5,005,455 = −0.0909%
  nrFunctionCalls 4,193,372 → 4,189,446 = −0.0936%
The commit's +0.48% traces to the spec's §9.2 corpus workload (146,022,298 → 146,710,204 = +0.4711%), which is ~29× larger. BOTH FIGURES ARE NEGLIGIBLE and the reviewer explicitly neither reproduces nor refutes the corpus number. Flagged because the commit message states a sign that a fixture-free spot-check does not show — and because this arc has already been bitten once by a cost comparison whose workload contained the guard's own fixtures.

(3) DEVIATION 2 (witness placement) CONFIRMED JUSTIFIED: ci/tests/binding-totality.nix:77 already binds `networking.domain` on its single crossed fleet, read at :131, so a second consumer would collide.
(4) SPEC FIDELITY EXACT: the extracted core token-diffs against the implementation with only nixfmt lambda breaking. No attested decision changed.
(5) ★ THE ERROR MESSAGE'S TRAILING REMEDY SENTENCE IS A SPEC-LEVEL DEFECT — it asserts a negative-edge cycle unconditionally, which is false for the drift case and false for the function-value false positive (den-hoag-4kh.46). It is inherited VERBATIM from the attested spec's error builder, so the SPEC must change with the code.
★ THIS BEAD IS NOW BLOCKED ON den-hoag-4kh.46. The law is right and the witness is real, but ec6ba23 is HELD UNPUSHED because the guard rejects well-formed fleets.

### 11 — 2026-07-28T11:09:01 · Jason Bowman

★ UNBLOCKED AND SHIPPED — den-hoag-4kh.46 is fixed at 6f472d3 and BOTH commits are now PUSHED (a40cc96..6f472d3). Verified independently: ci 1933/1933 EXIT=0, parity 71/71 EXIT=0.
The P0 this bead tracks is closed: a negative-edge cycle in plain den.policies can no longer publish an unsupported fact, and the guard no longer rejects well-formed fleets on its way to catching them. The law now reports FOUR distinct disagreements where it originally reported two, each naming its key, its writer and its own remedy.
REMAINING, both recorded elsewhere and neither blocking: the §10 row `test-negative-cycle-names-dropped-key` is still out-of-suite because message text is unassertable through checks.default (den-hoag-9mo, which now has a named fix — teach assertTests to skip expectedError tests); and §8/§9.2's figures were not re-measured after the projection landed, stated as such in the spec header.
