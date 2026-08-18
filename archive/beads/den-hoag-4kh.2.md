# den-hoag-4kh.2 — W2: kernel purity audit — representation-level violations in lib/ outside compat

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.2` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-27T20:23:53Z by Jason Bowman |
| last updated | 2026-08-05T20:48:29Z |
| description bytes | 2745 |
| notes bytes | 0 |
| comments | 4 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Find representation-level violations of the pure graph / category-theory layer in den-hoag's kernel (lib/ outside lib/compat/).

WHY GREP CANNOT DO THIS: ci/tests/boundary.nix already enforces kernel-vs-compat with three guards — a token scan, an import-direction check, and a seam enumeration. ALL THREE ARE LEXICAL. None can observe REPRESENTATION. A kernel file can pass every guard while being a v1-shaped state accumulator with gen-native naming. The violation class is SEMANTIC; the existing detector is LEXICAL.

PRIMARY INPUTS: STATUS/route-through-board.md (axis-1) and the roadmap it names, specs/2026-07-24-den-hoag-effects-runtime-audit.md.

CRITERIA — every finding MUST name one and cite a site. A finding citing no criterion is an opinion and does not enter the record. Each criterion has a known-positive from a violation this project already diagnosed, so the instrument can be calibrated:
  1. STATE ACCUMULATION INSTEAD OF QUERY — a per-class/per-kind content bucket accumulated across a fold where the graph-native form is a direct gen-edge or gen-graph query at the point of use. Known positive: the class buckets.
  2. UNDERSCORE-PREFIXED STATE CARRIERS IN THE KERNEL — v1 double-underscore keys hacked the nix-effects state accumulator; only the compat boundary may read that surface. Known positive: the LIVE __provider writer at lib/compat/den-brackets.nix:41-47, wired at lib/compat/bridge.nix:171, under a documented claim that the layer is DELETED.
  3. VALUE-SHAPE DISPATCH — looksLike / isNestedKey style predicates classifying by inspecting a value's shape rather than by declared type or graph position. NOTE: a TYPE-level structural test is legitimate and must not be swept up.
  4. BOUNDED-DEPTH TRAVERSAL — graph queries are DIRECT (1 hop) or REACHABLE-closure (infinite). Any depth-N walk names a locus by distance instead of by closure.
  5. EFFECT-RUNTIME HOLDOVERS — trampoline / accumulator / phase-fold shapes surviving as structure where the HOAG model is demand-driven attributes. Known positive: the A1 runPrePass accumulator.
  6. INVARIANTS DOCUMENTED BUT UNENFORCED — a stated law with no runtime guard is a comment. Known positive: the bijection at lib/compat/registry.nix:394.

KNOWN SELF-REPORTED GAP to start from: route-through-board records B15/B20 as NOT plain graph.ancestorsOf/circular swaps, still OPEN, each needing a gen-side decision, with the note that the naive swap was declined and THE REAL ROUTE-THROUGH IS UNBUILT.

FALSIFIER: if this returns zero kernel violations, the criteria were applied too weakly. The effects audit already documents live ones, so zero is a calibration failure, not a clean bill.

DO NOT FIX WHILE AUDITING. Findings become review candidates, not commits.

## Comments (4)

### 1 — 2026-07-27T21:48:30 · Jason Bowman

★★ CRITERION 5's KNOWN-POSITIVE IS INVALID — CORRECTED BEFORE THIS WORKSTREAM RUNS.

W1 (den-hoag-4kh.1, graph-instrumented) measured A1 = SHIPPED-REAL: the runPrePass state-accumulator is
GENUINELY GONE at HEAD, not renamed. Decisive property — in the pre-image (6bef742^) the per-element step
READ the accumulator (`st.relationBindings.${id}`); at HEAD no fold in the file does, and every surviving
foldl' is a monoid merge over independently-computed elements.

⇒ THIS BEAD NAMED "the A1 runPrePass accumulator" AS CRITERION 5's KNOWN-POSITIVE. That predicate CANNOT
MATCH — it calibrates the instrument on something absent. Running W2 as originally specced would produce a
"clean" verdict for criterion 5 that is VACUOUS, which is the exact failure mode this epic exists to detect,
introduced by the orchestrator into the epic itself.

REPLACEMENT KNOWN-POSITIVE FOR CRITERION 5 (effect-runtime holdovers), supplied by the same measurement:
  THE COARSE 2-STAGE SCHEDULE AT THE CALLER — lib/default.nix:1074-1086, carrying the verbatim header
  "THE STAGING THAT BREAKS THE CYCLE", where prePassScopeRoots is fixed BEFORE classification. This is
  in-tree, acknowledged, and is a genuine phase-schedule holdover: a staged pre-pass whose ordering exists to
  break a dependency cycle is the shape the HOAG model replaces with demand-driven attributes.
  Already tracked as den-hoag-9xo.10. NOTE ITS CITED LINE RANGE HAS DRIFTED — 9xo.10 says 961-968; at HEAD it
  is 1074-1086.
  ⇒ W2 MUST NOT re-file this as an A1 regression. A1 is dissolved; this is a DIFFERENT, adjacent holdover at
  the call site.

SECOND CANDIDATE, criterion 2 not 5: the live __provider writer at lib/compat/den-brackets.nix:41-47, wired
at lib/compat/bridge.nix:171, under a documented claim that the layer is DELETED (den-hoag-7pt measures it
live). That remains criterion 2's known-positive and is unaffected.

★ INSTRUMENT GUIDANCE FOR THIS WORKSTREAM, from W1's calibration — three traps now, not two:
  TRAP 1 get_architecture's `languages` field does not list Nix. Confirm coverage by known-positive symbol
    query only.
  TRAP 2 CALLS edges miss attrset-mediated calls (trace_path runPrePass inbound = 0 callers while the real
    call is lib/default.nix:1097). Zero callers is NOT dead code.
  TRAP 3 (NEW) search_graph name_pattern returns 0 for NON-FUNCTION `let` VALUE BINDINGS — byTarget and
    nativeEmissions both exist (staged-resolution.nix:317, :268) and both return 0. ⇒ GRAPH ABSENCE IS
    UNINFORMATIVE FOR ANY NON-FUNCTION BINDING, and using it as the absence instrument on a let-bound carrier
    WOULD MANUFACTURE FALSE "DISSOLVED" VERDICTS. Derive every absence from grep.

★ WHERE THE GRAPH IS THE RIGHT INSTRUMENT, and W2 should lead with it: search_graph returns a `bt`
(body-token) list per Function. For a symbol surviving BY NAME — exactly the shape criteria 1/4/5 are hunting
— bt answers "what does this body actually do" in ONE call. It is what settled argEnvWrap and
resolveParametric as genuinely routed rather than renamed. Use bt as the FIRST probe, grep as the absence
instrument, and treat a disagreement as a finding.

### 2 — 2026-07-27T21:59:18 · Jason Bowman

W2 KERNEL PURITY AUDIT COMPLETE (independent fresh context, 2026-07-27). Read-only. NOT ZERO — 6 primary + 4
secondary findings, every criterion positive-controlled.

★★★ F1 · CRITERION 1 + A CORRECTNESS DEFECT · lib/attributes/class-modules.nix:130-166
THE REROUTE FOLD IS NOT CONFLUENT. :156-166 does acc // { ${t} = (acc.${t} or []) ++ (acc.${f} or []); ${f} = []; }
  [{A→B},{B→C}] ⇒ A's content lands in C
  [{B→C},{A→B}] ⇒ A's content lands in B
SAME DECLARATION SET, DIFFERENT ANSWER, decided by emission order. `reroutes` (:152) is a bare builtins.filter
over resolutionActs — no sort, no normalization — and rule construction iterates builtins.attrNames policies
(concern-policies.nix:400) = ALPHABETICAL ⇒ RENAMING A POLICY CAN CHANGE WHICH CLASS CONTENT LANDS IN.
Half-converted: classSliceKeyedBaseAt (:187-190) genuinely IS a direct per-(node,class) query, but every
consumer reaches it via keyedBucketsOf (:201-213) → applyInjectReroute, a sequential accumulator fold over the
whole per-class bucket map; classSliceKeyedAt (:217-219), documented "DIRECT per-node class-slice query ATOM",
projects off that whole-map fold.
THE CODE JUSTIFIES THE FOLD WITH V1 SEMANTICS VERBATIM (:125-127): "a chained reroute [{A→B},{B→C}] must land
A's content in C via B, which a per-class-INDEPENDENT fold would miss — so this stays a sequential fold over
the whole map." That is the standing bar's target exactly.
GRAPH-NATIVE FORM: reroute is a RELATION on classes, not a sequence of moves. Content of C = union of
classSliceKeyedBaseAt over the reflexive-transitive PREIMAGE CLOSURE of C under the reroute relation. Chains
compose by closure, ORDER-INDEPENDENT BY CONSTRUCTION, and classSliceKeyedAt becomes a real direct query with
no whole-map materialization. The instrument is already in the kernel: lib/query.nix:52-111 lowers onto
graph.query with graph.regex.parse follow-exprs — `reroute*` is exactly such an expression.
REACHABLE. ci/tests/class-bucket-query.nix:99-101 exercises only the ONE order that works.

★★ F2 · CRITERION 3 · lib/concern-policies.nix:167-193 probeOf, consumed :340 / :355-373
Policy classification is decided by SPECULATIVELY EXECUTING the policy body against a FABRICATED sentinel ctx
(probeEntry = { id_hash = "«probe»"; name = "«probe»"; }) inside tryEval+deepSeq, then INSPECTING THE SHAPE OF
THE RESULT: expanded = probeActs == [ ] (:358); group = declare.stratumOf (head probeActs) (:233).
Criterion 3 AT ITS LIMIT — not dispatching on a value's shape but MANUFACTURING A VALUE IN ORDER TO DISPATCH
ON ITS SHAPE. The comments admit it is unsound and hand-maintained (:137 "CEILING: a field must be
TYPE-CORRECT NON-MATCHING"; :139 "a policy reading an UN-ENRICHED field still hard-fails LOUDLY").
THE THEORY-CORRECT ROUTE IS ALREADY IMPLEMENTED ALONGSIDE: declaredKinds = v.__produces or
(producesByName.${name} or null) (:357) → mkDeclaredSlices, whose comment (:227-232) says it "HONORS the
declaration and SKIPS its per-dispatch fire-and-classify VALIDATION ... exactly as gen-resolve trusts an
equation's stratum". So the declared vocabulary EXISTS; the probe is the fallback so authors need not declare
— v1-compat convenience. REACHABLE: the default path for every undeclared policy.
Minor same-file: isRecord = v: isAttrs v && v ? __condition (:148) — dispatch by presence of a magic attr.

★★ F3 · CRITERION 1+2 · lib/fleet.nix:117-127 — GRAPH POSITION CACHED AS PAYLOAD
Writes the cell's full product coordinates (__coords, :117) and containment ancestor scope ids (__containment,
:125) INTO the node's decls payload. Both ARE the node's graph position, precomputed at construction and
carried as data. Read back AS position: resolved-aspects.nix:197 and resolved-settings.nix:67.
THE COST IS VISIBLE AND DUPLICATED: FOUR files each carry a hand-maintained reserved-key STRIP LIST to stop
these carriers leaking into policy ctx / channels / settings — staged-resolution.nix:173-175,
collections.nix:75-77, resolved-settings.nix:48-50, structural.nix:61-63. A GRAPH EDGE NEEDS NO STRIP LIST; a
payload key needs one at every projection, and that list is duplicated 4x with no single source.
fleet.nix:121-124 states why the relation is not in the graph ("env is a coordinate root, not a P-parent") —
the relation is REAL and simply UNREPRESENTED as edges, so it is smuggled through the payload. Graph-native:
a `contains` edge coordinate-root → cell; __containment becomes a graph.query, __coords a product-dim query.
The kernel already does exactly this at receivers.nix:167-176.

★ F4 · CRITERION 5 · lib/default.nix:1074-1086 — CORRECTED KNOWN-POSITIVE CONFIRMED LIVE, verbatim header
"THE STAGING THAT BREAKS THE CYCLE". prePassScopeRoots fixed BEFORE classification, consumed by runPrePass
(:1095). In the HOAG model the cycle is broken by LAZINESS AT THE ATTRIBUTE, not by a schedule at the caller —
and the kernel already owns that idiom (resolve.attr/self.get throughout lib/attributes/).
★ F2 AND F4 ARE COUPLED: the schedule must know which policies to run early (resolveRules, :1099) and finds
out by SPECULATIVELY EXECUTING them (F2's probe). THE STAGING HOLDOVER AND THE SHAPE-DISPATCH HOLDOVER HOLD
EACH OTHER UP. Correctly NOT re-filed as an A1 regression.

F5 · CRITERION 4 · lib/default.nix:331-375 familyMergeAt — names loci by DISTANCE ("bounded to the TWO levels
… FAMILIES at depth 0, MEMBERS at depth 1"). The comment states criterion 4's own diagnosis: there is no TYPE
to stop at ("a built configuration is itself an attrset, so an isAttrs recursion guard cannot tell a family
SUBTREE from a built ARTIFACT"). BUT THE KERNEL ALREADY HAS THE TYPE — lib/products.nix:49 names ArtifactRef
P. Merge stops at the typed leaf; the bound becomes a consequence of representation instead of a constant.
HONEST CAVEAT from the auditor: product-tree merge, not a graph traversal — criterion 4 BY DIAGNOSIS, flagged
as such rather than overstated.

F6 · CRITERION 6 · lib/attributes/resolved-aspects.nix:57-62 — a stated contract (a parametric aspect MUST
declare every entity coord it reads as a formal) whose ENFORCEMENT IS A ONE-TIME AUTHORING GREP
("grep-verified"). Named consequence: SILENT per-cell content collapse. The guard is constructible from data
in hand (ctxProjOf already reads __functionArgs; setFunctionArgs makes ellipsis observable), and the same file
already establishes the safe fallback for this case (:50-51, null ⇒ never deduped, "a false-keep never loses
content"). SAFE DIRECTION AVAILABLE, NOT TAKEN. Dormant vs today's corpus by the author's grep; reachable by
any new aspect.

SECONDARY: demand.nix:70-85 emission-ordinal accumulator (identity from a running fold counter) ·
concern-policies.nix:392-413 __isEnrich/__pipeOps/__resolveFamily riders used as internal transport then
stripped · six consumers each re-filtering one accumulated per-node act bucket by string tag (the __action KEY
is legitimate gen-dispatch protocol; the violation is the bucket-rescan where gen-graph's labeled query
answers by label) · output/terminal.nix:103 __terminal marker with ZERO kernel readers, only ci/tests.

★ CRITERIA THAT FOUND NOTHING — EACH POSITIVE-CONTROLLED, which is what makes the nulls credible:
 C2-as-v1-state-hack: NO in kernel. 615 raw __ hits, but differenced against 9 gen libs most are GEN PROTOCOL.
   Positive control: the __-writer predicate FIRES on the compat known-positive (den-brackets.nix:44
   __provider, wired bridge.nix:171). Predicate works; kernel is cleaner than compat but not clean.
 C4 literal graph queries: CLEAN, and this is discrimination not silence — the kernel's actual graph queries
   are closure-correct (receivers.nix:173 Kleene star; query.nix:84 arbitrary follow-exprs, five modes).
   NEGATIVE CONTROL for the predicate.
 C3 named predicates (looksLike/isNestedKey): ZERO in kernel. Positive control: BOTH live in compat
   (compile.nix:218, :251). module-shape.nix explicitly NOT swept up — a legitimate TYPE-level structural test,
   the bead's carve-out correctly applied.
 C6 known-positive is now a known-NEGATIVE: registry.nix:394 HAS BEEN PROMOTED to the runtime guard
   registryKindsFor. Substituted control: structural.nix:154-157 states a single-writer law AND enforces it
   (errors.singleWriter). The predicate distinguishes enforced from unenforced; F6 is the unenforced one.

COVERAGE — HONEST: MECHANICAL over 100% of all 49 kernel files / 13,337 lines (__-key inventory differenced
against 9 gen libs; W1's accumulator-reading-fold discriminator; __action filter enumeration; bounded-depth
token sweep; __ writer enumeration; graph-native call-site map). The kernel-wide fold sweep returned only SIX
sites total and class-modules.nix:141,161 are the only ORDER-SENSITIVE ones — that sweep isolates F1 and is
complete. SUBSTANTIVELY READ: ~900 lines (~7%). NOT READ, grep/graph only, semantic violations there WOULD BE
MISSED: edges.nix (524) · output-modules.nix (1202) · staged-resolution.nix (454) · declarations.nix (447) ·
nest.nix (314) · outputs.nix (327) · concern-productions.nix (319) · concern-collectors.nix (293) ·
concern-disciplines.nix (248) · concern-relations.nix (264) · concern-derived.nix (193) · ~2,700 of
default.nix. HIGHEST-VALUE UNREAD by the auditor's own judgement: output-modules.nix (the class-bucket
consumer side) and staged-resolution.nix (the pre-pass body F4 schedules).

★★ INSTRUMENT — TRAP 5, NEW: query_graph complexity properties are on `f.file_path`, NOT `f.file`. A clause
`WHERE f.file STARTS WITH 'lib/'` returns 0 ROWS SILENTLY — a manufactured "no accumulators here". Caught by
the control MATCH (f:Function) RETURN count(f), count(f.loop_depth) → 2213/2213 populated. RUN THAT CONTROL
BEFORE TRUSTING ANY CYPHER ABSENCE.
★★ AND THE LOOP/COMPLEXITY METRICS ARE NEAR-USELESS FOR NIX: kernel-wide only 8 functions have any recursion
and ZERO have loop_depth >= 2, because Nix folds are builtins.foldl' CALLS, not syntactic loops. THE
ACCUMULATOR RANKING MUST COME FROM GREP — W1's read-the-`acc` predicate is the working instrument and should
be promoted over loop_depth in any future dispatch. bt settled F2 in one call, as briefed.

### 3 — 2026-07-27T22:00:26 · Jason Bowman

CROSS-REFERENCE FROM W3's gap-3 scan (den-hoag-4kh.3), same file as F1: classifyAllKeysAt was RETIRED BY NAME at 664da11 ('retire the eager per-class content bucket for direct/reachable class-slice queries') — but ITS BEHAVIOUR SURVIVES UNNAMED. lib/attributes/class-modules.nix:192-194 still force-walks every content key via builtins.seq content.${k}, inline, under no function name. Same file as F1's non-confluent reroute fold (:130-166) and classSliceKeyedBaseAt (:187-190). A named retirement whose SHAPE persists inline is the SHIPPED-RENAMED-ONLY class at SUB-FUNCTION granularity — W1 hunted that class at rung granularity and found the bucket empty, and no rung-level sweep would ever catch this. Worth folding into F1's assessment: the file is half-converted in two independent ways.

### 4 — 2026-07-27T22:12:04 · Jason Bowman

CROSS-REFERENCE FROM W3's rationale sweep (den-hoag-4kh.3) — TWO ITEMS FOR W2's CRITERIA:

(1) CRITERION 2, and it contradicts a five-times-stated architectural claim. The roadmap/assembly/compat specs state five times that legacy forwards+provides have 'no native den-hoag equivalents'. TRUE OF THE USER SURFACE, FALSE OF THE MECHANISM: lib/attributes/output-modules.nix:623-634 builds forward class-reroute contributions from meta.__forward specs stamped COMPAT-SIDE at lib/compat/bridge.nix:133. THE KERNEL CARRIES FORWARD ROUTING DRIVEN BY A COMPAT-AUTHORED __ MARKER — a __-prefixed carrier crossing the kernel/compat line, which is criterion 2's shape. Note output-modules.nix (1202L) is one of the two files W2 flagged as highest-value UNREAD.

(2) CRITERION 1 + failing rationale, already in the spec's own words. assembly-component-spec.md:1109-1113 (Law A15): classSubtreeAt is a blind scope.descendants walk, justified as 'v1's non-isolated defaultFoldEdges nesting fold (Corollary 1) rendered where a NO-ISOLATED-KIND CORPUS collapses the isolation-aware subtree to the blind descendants walk' — v1-shape AND corpus-absence in one sentence. Consequence ledgered honestly (isolation ceiling, compat R22, errors.isolatedKindUnsupported) but v1 SHIPS isolation (modules/options.nix:85-88), so a shipped v1 capability is unexpressible in the kernel because the corpus does not exercise it. Same file as W3's classifyAllKeysAt cross-reference and W2's F1.
