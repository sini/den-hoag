# den-hoag-4kh.27 — [archive] the 927-line den-hoag features memory, verbatim — superseded, wrong in 10 places, kept for its historical log

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.27` |
| status at evacuation | closed |
| priority | P3 |
| type | chore |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:11:35Z by Jason Bowman |
| last updated | 2026-08-01T19:47:03Z |
| closed | 2026-08-01T19:47:03Z |
| close reason | Archive complete — the 927-line features memory preserved verbatim in this bead's body (its stated purpose). Superseded-and-wrong-in-10-places status was the filing reason; the historical log remains readable in the closed bead. Closing as a completed act of archiving; no work was ever pending here. |
| description bytes | 119466 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

ARCHIVE — the full 927-line project_den_hoag_features memory as it stood at 2026-07-28, before it was
reduced to a pointer. Kept verbatim so nothing in it is lost; SUPERSEDED as a source of truth.
★ IT IS WRONG IN AT LEAST TEN PLACES (audit items D1-D10) — most damagingly it records the LANDED
topology arc as backburnered with 'zero shipped code', and asserts the real repo path does not exist.
DO NOT read this as current state. Current state is the bead graph. This exists so that the historical
log lines 57-927 — which the audit SAMPLED rather than exhausted — remain recoverable if a future
question needs them.
════════════════════════════════════════════════════════════════════════
---
name: den-hoag-feature-targets
description: "Feature set den-hoag must ship beyond den v1 parity — settings engine, matrix composition, user registry, policy extensions, selector-predicate routing"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3d1d912b-97f6-422c-8f8a-13dd70de0e1f
  modified: 2026-07-27T18:09:01.005Z
---

> ★ CURRENT-STATE REDIRECT (2026-07-27, reconciled): this file is a long HISTORICAL project-log — its
> "IN PROGRESS / branch" language below is STALE. den-hoag is on **main @`c0aa7be`**. Everything in the
> docs named here supersedes the historical log below.
>
> **WS-B = implement ALL den→gen-native.** ★ NORTH STAR = **graph-native framework correctness**
> (DL-HS-29, [[feedback_best_framework_first]]): dissolve effect-runtime holdovers
> ([[reference_denhoag_effects_audit]]); corpus-eval is a SYMPTOM, not the bar. v0 alpha, tech debt P1.
>
> **★ COLD-START, in order** — all under `papers/den-architecture/`:
> `STATUS.md` (index → the consolidated `STATUS/` live-tracker set) → the handoff
> `STATUS/RESUME-CHECKPOINT.md` → decision log `specs/2026-07-22-wsb-autonomous-decision-log.md`
> (DL-1..68; LATEST entries carry live state) → `lib/compat/parity/ledger.md`.
> **Tracker = beads**, epic `den-hoag-9xo` in den-hoag `.beads/`.
>
> **★★ SHIPPED — raw/typed-dual + validation-authority dissolution** (DL-HS-66), all 6 rungs: gen-aspects
> main @`1689e41` (deferIncludeResolution + recursiveClosed + rejectBareModuleInclude + keyCategory);
> den-hoag main @`4044ed5` (facets + parametric-gate + full apparatus dissolution, plus the move-to-gen
> cleanup tail: gather G-4/G-5, collections-1→wrapGatedFn, DL-HS-68). The raw/typed dual and the split
> validation apparatus are GONE; gen-aspects' closed `recursiveClosed` gate is the SINGLE validator
> (`keyCategory` = classification surface; `classifyKey` routing-only; terminal walks re-cast as pure
> lazy-gate FORCES, DL-HS-65; parametric results gated via translateAspect-normalize→gate). Model C
> (owner-ratified): closed vocabulary — declare all classes/channels (v1 informal-custom-class leniency
> dissolved, DL-HS-62); scalar-undeclared → typo-abort, attrset-undeclared → nested-aspect-admit-lazily.
> The bucket-root / raw-typed-dual holdover (the audit's declared ROOT) is DISSOLVED.
> Arc spec `specs/2026-07-25-raw-typed-dual-dissolution-design.md` (§9 = validation authority) + plan
> `plans/2026-07-25-raw-typed-dual-dissolution-plan.md` @`5185e0d`.
>
> **★★★ TOPOLOGY ARC (2026-07-26) — BACKBURNERED, deliberately.** den-hoag never built scope parentage:
> `build-roots.nix` hardcoded `parent = null`, so the corpus chain flake→fleet→env→host existed only as
> `ent.meta` metadata — agenix/secrets not materializing was a STRUCTURAL symptom of that, never the thing
> to chase. The attachment primitive was ALREADY BUILT: `containTo` members already produce
> `containmentAncestors` (child→parent), wired only to the settings fold. gen-scope
> `buildNodes`/`parentGraph` NOT needed (eval.nix returns a root's descriptor verbatim).
> ★ OWNER D/I/P RULING: a `containTo` member asserts TWO edges of different arity from one declaration —
> a D injection (many-to-one, `//` union into decls) and a P assertion (one-to-one, Neron partial
> function). That conflation is the defect. Resolution = OPTION 4 NODE MULTIPLICATION: multi-attachment
> multiplies the NODE, never the parent (`rack:r1@zone:z1`) — the mechanism cells already use and v1 uses
> via `mkScopeId scopedCtx`. Rung 1 T1.0-T1.5 SHIPPED green (isCell, parents param, containmentParents);
> pivot T1.6 reverted pending option-4 design (`plans/2026-07-26-node-multiplication-design.md`,
> SHIP-WITH-NITS). **Zero shipped code and every ruling in the arc was overturned by the next
> measurement** — do not resume it without re-measuring against the den TEMPLATES, not `nix-config` alone.
>
> Related: [[feedback_scout_vs_ultracode_audit]] [[feedback_gen_lib_push_gate]]
> [[project_class_bucket_holdover]] [[project_denhoag_kernel_primary_surface]]
> [[feedback_architecture_first]] [[feedback_spec_before_development]]

den-hoag greenfield (design started 2026-07-05) ships these features, not just den v1 parity:

1. **Settings engine** — stratified settings (default < env < host < policy precedence); builds on Spike 5 (gen-algebra foldLayersTraced + injectAspectSettings, see [[settings-stratification]]).
2. **Matrix composition engine** — compose configuration across dimension matrices (e.g. host × user × class × env).
3. **Formal user registry** + enhanced user+host scoped configuration — users become first-class registry entities with proper scoped config, not bolted onto host scope.
4. **Policy system extensions** — beyond den v1 policy effects/synthesize-policies.
5. **Improved quirk/attribute routing engine** with proper selector predicates — replaces den v1 string/kind dispatch with predicate-based selection (gen-select is the candidate substrate).

**Design decisions (user, 2026-07-05):** (1) layout = general GEN-TIER libs + thin den-hoag assembly; (2) matrix engine = GRAPH PRODUCTS as first-class ops (cartesian/tensor/lexicographic, projections, quotients — dimension instantiation + precedence lattices fall out); (3) parity = FLEET BYTE-PARITY via compat shim, nix-config = corpus, edge-trace oracle E(topology) + drv-hash; (4) hola = research-only, UNRELATED to den-hoag; (5) DSL = gen libs build GRAPH-NATIVE DSL, den-hoag surfaces four-concern model as API extension; (6) SHIPS AS den v2 (public denful/den) — API carries community weight, shim = migration path. Expressiveness benchmarks: claim/provide engine (papers/nix-config-architecture/specs/2026-06-13) + settings stratification (Spike 5) must be trivially expressible.

**Canonical concern model (user, 2026-07-05):** policies define RELATIONSHIPS, quirks/attributes describe DATA, classes describe SYSTEMS, aspects describe BEHAVIOR. Forwards and provides are LEGACY — but SHIPPED IN THE COMPAT SHIM (user 2026-07-05) as self-contained modules tagged legacy, removable without touching the rest; parity covers whatever the fleet corpus uses. API identity law: public surfaces pass REGISTRY ENTRIES (den.hosts.axon-01), never "kind:name" strings (external-user pushback on string grammar); strings = internal keys + display only.

**Design philosophy (user, 2026-07-05): REJECT YAGNI for den-hoag design.** Maximize generality and expressiveness — most expressive DSL/framework possible, give users the full power of graphs. Component libs should be general graph-powered primitives, not den-shaped special cases.

**Perf seam (2026-07-06, post A5/module-system ship):** den-hoag = gen-class TIER-3 consumer; classes concern DECLARES host-class boundary; output assembly = applyCoreFixed fixed-input core injection as DEFAULT fleet path; gen-pipe contributions carry static config-dependence flag (arg-shape) → shareable set structural; no global fleet flags (per-cell lazy); parity runs WITH class-share on. Roadmap §9 subsection added; spec update pass (assembly/pipe/compat) queued behind consistency-fixer.

**STATUS 2026-07-06: SPECS COMMITTED den-architecture @81dd978** (roadmap @3da1bfa + 8 component specs, 4438 lines): gen-edge/product/settings/demand/pipe/select-ext + den-hoag-assembly + den-compat-parity. Ultracode wf_ad6793ee-291 done (25 agents, 2.26M tok); 17 cross-consistency findings ALL RESOLVED (rulings: count-major linearization; inert-record legacy-edge seam opt-a; demands on dedicated gen-pipe channel; producer-identity tie-break; hasSetting = den-hoag vocab NOT gen-select; per-entry-lazy provenance refs; fleet-level compose; cellId canonical cell identity; assembleHost takes class ENTRY). Class-seam pass applied (assembly/pipe/compat). **LIBS SHIPPED + PUBLISHED 2026-07-06** (user granted repo-create/push/merge): github:sini/gen-{edge,product,settings,demand,pipe} all public, main pushed; gen-select extensions MERGED to main @f3c047e + pushed (sel.entity/sel.kind, identity/coord adapters, product adapter, 191 tests). 707 tests total, ALL suites independently re-run green (edge 96 nix-build check, others nix-unit: product 125/settings 79/demand 92/pipe 124/select 191). Error-message content unassertable in pure Nix (tryEval boolean) = lib-wide convention. Spec-sync COMMITTED @5b02302; gen-pipe shim DROPPED @15e6981 (pushed; sel = verbatim gen-select re-export) + spec note @70a9b8a.

**Purity directives (owner, 2026-07-06):** (1) NO EFFECT RUNTIME — pure graph walk, not v1 effect topology: declarations are inert data, no queue/router/global accumulator, phases = definition-time strata, only the declared fixpoints, demand-laziness is law; tripwire tests in A11 (throwing-sibling laziness, no-lambda declarations, fixpoint census). (2) TERMINOLOGY GROUNDED in graph primitives — effect→declaration, dispatch→rule evaluation, phase→stratum, lib/effects.nix→lib/declarations.nix, attrs policy-effects→declarations / enrich-effects→enrichments; gen-dispatch names stay behind wrappers. (3) At A2 close, judge fired/identity accumulator — simplify to keyset fixpoint + collision check if ceremony (controller judgment). Plan rules committed @9f72557+@57a2430.

**#624/#625 compat requirement (owner 2026-07-07):** shim must be compatible with den #624 (emit-classes scopeContexts / per-named-entity class keying) + #625 (replicated-home shortfall, draft) fixes; frozen parity pin 11866c16 PREDATES them (#624/#627 landed after) — den-hoag natively keys class content per member/cell (bug class structurally absent) but VERIFY at nix-config integration + decide pin bump at ship gate; PIN.md carries the note.

**COMPAT PHASE IN FLIGHT 2026-07-07:** plan plans/2026-07-07-den-compat.md (10 tasks C0-C9, reviewed; corpus INTERIM pin nix-config @b0b2076, synthetic corpus = follow-up). C0 scaffold DONE @4ce6ca9 (parity flake: den-v1 FROZEN @11866c16 == #623; survey re-validated, OQ2 census = zero tier-2 forward consumers; devshell 2nd adapter route in PIN.md); gen-dispatch boundary bump DONE @dee96d3 (suite 210/210 + parity 3/3); C1 ingestion IN FLIGHT. Loop⊥step COMPLETE ecosystem-wide (gen-dispatch @bf541dd, hub 19 keys wired @01cc791, sql-schema+gen-aspects demos byte-identical). OUTSTANDING (board): C1-C9, #28 synthetic corpus, #40 gen-demand selector pin bump, #41 den-hoag GH-CI+formatter, #42 hub mkGenLibs ci check, #43 den-branch migration (owner-gated). Hygiene rulings: genLibs injector stays curated; gen-resolve spike deleted.

**═══ ASSEMBLY COMPLETE 2026-07-07 ═══** github:sini/den-hoag main @b6d8aab: ALL 12 tasks done, **205/205 tests**, final whole-repo review (opus) APPROVE — "ready to push public as den v2 preview AND serve as den-compat foundation". 22 lib files, A1-A18 law index in REFERENCE.md, fixpoint census = exactly 2 scope.circular (B1+B4), 0 dispatchStep. Key shipped semantics: containment-based B4a visibility (no env-rooted P-tree); count-major linearization; via-carrying projection layers; raw channel keys via probe (§2.2 three-branch); deferred values PR#623 path (pipe.deferred→__configThunk→terminal, gotchas: consumer needs unbound arg for thunk resolution; deferred channel = E6 poison in fold); tier-2 share gen-merge-only; demand edges fleet-global; interpret = REAL param (den.interpret raw option = den-compat entry point); laziness ceiling = spines force/values lazy (static-cone seam open). NEXT: phase-end spec-sync → den-compat plan gate (write-plan + review + user).

**EXECUTION 2026-07-06 (subagent-driven, opus impl + sonnet reviews):** assembly plan APPROVED+COMMITTED (plans/2026-07-06-den-hoag-assembly.md + .tasks.json, 12 tasks; review loop closed). Repo **github:sini/den-hoag PUBLIC** (user request 2026-07-06, in-flight sharing; migrates to a den branch later; push after each task's review closes — reviewed states only): A0 scaffold @16c3b81 + A1 entities/fleet @37986e8 DONE (spec+quality approved, suite 10/10); A2 (B1 dispatchStep-in-circular + A6 coherence) IN FLIGHT; A3-A11 pending per dep graph. Plan-vs-reality fixes: dep roots = functions (normalizer in default.nix), prelude.groupBy NONEXISTENT (inlined; upstream follow-up task), discoverKinds two-eval probe. den-compat plan authored AFTER assembly. Hub wiring (mkGenLibs + flake inputs for 5 new libs) still pending — code change, avoid clashing with other session in gen hub; docs-only hub README registry update dispatched 2026-07-06.

**═══ POST-GAP RECOVERY 2026-07-09 ═══** Token-quota gap 07-07→09: interim agent resumed from plan and flailed (~70 commits). DISCARDED WHOLESALE — preserved reference-only on den-hoag branch `fix/den-hoag-compat-gaps` (+ same-named local-only nix-config branch). Poison inventory: B2 `checkStratum` removed + policies 4-way stratum-partitioned + law test rewritten (aborts→partitions); `entity.nix` filterModule silently swallowed modules (`_: {}`); per-kind `strict` toggle + unregistered-key dropping; 14 v1 classes hardcoded in core `classNames`; corpus EDITED to fit shim (inverts oracle — banned); ledger honesty rewritten to "Gap 3 Closed". Real gaps → **R-set formal rules R1–R9 = den-compat spec §10** (2026-07-05-den-compat-parity-component-spec.md; v1 citations at pin 11866c16: binding env nixModule/default.nix:3 + flake-scope battery; legacy class registry; os-to-host route os-class.nix:26-43; den.default radiation `genAttrs [host user home]` defaults.nix + pinned built-in membership; self-provide resolve-entity.nix:48-63; batteries dir; loud gen-bind arg adaptation, `_: {}`/corpus-edits banned; host→user resolve = resolution-stratum policy not link; no strictness escape) + plan **Task 7.5** (pre-C8 gate; acceptance = L3/L5 ledger rows matched>0, core untouched, 437 baseline green). Quarantine done: den-hoag main = origin/main @0728a51 re-verified 437/437 exit=0; nix-config main = corpus pin b0b20769 tracked-clean, 52 junk files removed; den repo stale .gen-ref-staging removed. **Task 7.5 SHIPPED+PUSHED @43a5d7e+8f9d03d** (R1-R9, 453/453 + all parity suites, dual APPROVE-WITH-FIXES review, manufactured-convergence CLEARED — fixture bodies byte-identical, L3/L5 matched 0→1/0→2 extra=0 via R5; 15 non-ported-battery ledger rows B1-B15). **Task 8 M1 SHIPPED+PUSHED @23272f0 2026-07-09** (478/478 + 5 parity suites, dual reviews APPROVE, L3/L5 matched 2/4 extra=0): declared-classes core surface (user `den.classes` joins three-branch registered class — general, sanctioned core change) + ambient batteries + host.class carry + kind-generic moduleArgs (ZERO kind literals in core) + foreign-topology tripwire (datacenter/rack/blade crosses to real NixOS eval reading custom coords) + boundary.nix mechanical guards (token scan / import direction / seam enum {mkDen, classes, declare, sel, internal.terminal} / legacy sibling isolation / shared-primitive vocabulary) + os-class elem-gate v1-verbatim via the `__dropped` inert-delivery arm (os-user UNGATED — the v1 gate asymmetry is real; probe-safety pattern: unconditional emission, gate in the field). **Task 8 M2 SHIPPED+PUSHED @d65f0dc 2026-07-10 — C8 COMPLETE** (@c4e7ff2+b68ba0c+d65f0dc; dual APPROVE-WITH-FIXES; QUALITY CATCH: hoagConfigAt observed the pre-terminal channel fold → all-null observations/hollow goldens; fixed = evalModules fold + freeform absorber on BOTH arms — bare `_module.check=false` swallows undeclared options — goldens re-derived with non-null evidence; coreGate comment corrected to fleet-path deepSeq force NOT classShareCoreAttr; pin (p) got its formal ledger TABLE row for P6) (ci 484/484 + 8 parity suites incl new class-share 7/7 + content 7/7): (1) darwin NATIVE core output class @c4e7ff2 — peer to nixos, added to lib/default.nix classNames + crossDarwin terminal (gen-flake has NO darwinSystem, calls nix-darwin lib.darwinSystem directly, SHIP-GATE only — CI uses collect) + darwinConfigurations face + den.darwin input + generalized the single `if name=="nixos"` crossing hardcode into a class→crossing map; elem-gate `[nixos darwin]` now routes darwin (osEdgeCount darwin=1); NOT legacy vocab so it's core. (2) content oracle @b68ba0c — coreGate (P8, FULLY CI: fleet-path authority via authorize/A18 allGated + traceEqual + configInvariant + corrupted-core teeth), crossPipelineRecords + contentGate. **KEY SCOPING (flagged for review, ledgered): the v1-materialized content differential + fleet toplevel drv-hash = SHIP-GATE not CI** — empirically confirmed the v1 content arm forces the v1 home-manager battery reaching inputs.home-manager (a corpus input the harness deliberately lacks; spec §4.4 "pin all corpus inputs"); the plan explicitly sanctions this ("one arm that cannot run in den-hoag's own CI"). CI pins the hoag-materialized content hash as regression golden + exercises mechanisms; Nix laziness keeps the v1 thunk unforced. Pinned item (p) classless-host→"nixos" default ledgered (out-of-corpus). **═══ DEN-COMPAT COMPLETE (C0-C9) 2026-07-10, origin/main @3324cf1 ═══** 488/488 + 11 parity suites + **n=1 ship-gate drvPath BYTE-IDENTICAL (v1DrvPath == shimDrvPath)**. C9: P3 permutation (content folds before compare) + P6 mechanical ledger gate (enumerated families, dual negative controls); residual-o RECLASSIFIED into residual-n (Law A15 — den-hoag folds hm at the (user,host) CELL by design; v1's host hm fold = user-as-root rendered; a battery port would fabricate extra; P2 content guard incl hm explicit); v1 content arm needs the FULL nixos crossing (.imports = real nixpkgs modules; freeform fold infinite-recurses) → the CI/ship-gate split is STRUCTURAL; nixos-terminal seam mkDenWith/mkFleetModuleWith (collect-pinned shim can't produce shimDrvPath — ship-gate + migration-product infra); measured 0.5s hostName / 1.2s drvPath (container fixture). CORPUS FINDINGS: **v1 DERIVES host class from system** (v1 host.nix:65-66 hasSuffix darwin → darwin : nixos) — ingest reproduces it exactly (patch aarch64-darwin fixed; explicit class overrides, slab=droid; reviewer's null-default adjudication SUPERSEDED-BY-EVIDENCE); ledger row q = droid class registration needed at corpus; #624 structurally absent on v2; pin material = stay at frozen #623, advance corpus pin separately. impl-c8 RETIRED (shutdown at 80% ctx) after the full C0-C9 arc — 2 real stop-and-flags, self-corrected corpus claims. REMAINING: ship-gate corpus run + darwin/droid corpus registration (owner-gated), #43 migration (owner-gated), ecosystem #40/#41/#42/#45/#48; successor agent spawns FRESH at next dispatch. gen-flake darwinSystem = #48.

**═══ SHIP-GATE LADDER (impl-eco) 2026-07-10 — den-hoag @cc89bfb, corpus reaches MATERIALIZATION ═══** Eco debt sweep DONE first (#40/41/42/45/48 — see gen-package memory). Gate phase 1-2: gap catalog (papers plans/2026-07-10-ship-gate-gap-closure.md, G1-G5 + catalogs v2-v4) → rungs cleared IN ORDER, each survey→classify→sketch→build→re-probe: T1 G1 re-export layer @9fda2df (top-level flakeModule wrap + lib aliases + NAMED THROWING STUBS routing to board tasks — the stub design makes each next rung self-announcing); T3a flakeModule=flakeModuleCore (killed 8-key _denCompat leak class; strict-eval witness) + T3b policy.{include,exclude,mkPolicy,pipe} constructors @a3f258b+c7f473a; M1 OUTPUT BRIDGE @0823eee (flake-parts splice: raw absorption via freeform submodule w/ consumer lib — TYPE-CROSSING DODGE, gen-schema never enters consumer evalModules; nested-eval processing; real nixosConfigurations; mini-fleet drvPath witness); M1.5 custom-kind discovery @b12820b (id_hash = THE kind marker — corpus chooses registry keys freely, mkInstanceRegistry = corpus's OWN gen-schema input; instance-based identityHashFor PERMANENT — option-level identityHashForKind proven NO-GO, shim kind-values option-less by field-less law; gen-schema exports both @74841cc+f6749cb, shared hashIdentity = structural no-drift); M1.75 schema processing @fdcfce5 (apply on options.den.schema: defs→nested mkSchemaOption eval; circularity resolved — apply reads DEFINITIONS never applied value); #50 N1 declared instantiation @2077617 (crossVia + declaration-read crossings/faces) + M2 per-host host.instantiate @4348d64 (corpus declares nixpkgs PER-HOST via channel evaluators = D7 per-entity grain; compile-time id_hash→evaluator map keeps entities field-less); #49-SLICE @5dddf39 (corpus reads ONLY keyClassification.structuralKeysSet — v1 literal set + shim-facet-overlap consistency test; rest of #49 stays stubbed); fix-A includes-concat @e4cc379 (types.anything conflicts ALL lists; def-COLLECTOR outer type feeds per-module defs into nested eval, gen-schema's collections api concats — owning-lib merge semantics, never reimplemented); **CROSS-PIN SEAM (owner: BELT-AND-SUSPENDERS)**: corpus's own registries consume kind-value TYPE OBJECTS cross-pin → BELT = opaque pass-through @00de38e+isolation @cc89bfb (passThroughSeam flag, retirement condition in code, severance witness, boundary-clean — proven: clears BOTH blockers with NO pin alignment) + SUSPENDERS = **gen-merge nixpkgs optionType PROTOCOL COMPLETION @5d5e0de** (mkOptionType stamps all 14 fields purely; leaves get real checks from gen-types verify; substSubModules/functor/typeMerge per nixpkgs contract; byte-identity ANALYTICAL — core reads .merge/.verify never .check; witness = gen-merge types mount in REAL nixpkgs lib.evalModules; gen-schema inherits FREE 403/403 canary intact). **BOTH ARMS CONVERGE at the identical C6 rung** (equivalence = harness/runbook property, NOT pin-coupled unit test). NEXT BLOCKER = the PARAMETRIC-POLICY RUNG — full state in papers plans/2026-07-10-ship-gate-gap-closure.md CATALOG v5 (read it before acting): THREE layers, one root (corpus schema-include policies ARE idiomatic den-hoag `{environment,...}: [...]` — only the shim's formal-erasing compilePolicy breaks them): L1 C6-identity fix VERIFIED but held LOCAL-ONLY @ebd5733 (owner (b): nothing piecemeal, folds into combined change — DO NOT PUSH standalone); L2 formal-erasure → value-less stratum probe throws at empty sentinel (verbatim corpus evidence); L3 value-conditional emission → enrich misclassification (pin-k crash, twin-fixture proven). HARD-DECLARE FALSIFIED: v1 resolve/instantiate→STRUCTURAL spawn, pipe→COLLECTION — corpus policies straddle strata. **PARAMETRIC-POLICY RUNG CLEARED @8e2f8c8 (PUSHED — owner pushed 2026-07-10, origin/main = 8e2f8c8; ebd5733 ABSORBED/superseded)** — catalog v6 in the papers plan has the full landed design: `{__condition; fn}` rule records (`__stratum` DROPPED — stratum is per-DECLARATION); value-less/caught-throw probe → PER-PHASE-FILTER EXPANSION into `name#stratum` sub-rules over {structural, resolution} (each single-stratum, passes dispatch validation; B2 readers consume by kind regardless of producer; all-structural candidate REJECTED — would relax dispatch.nix:104-105 + corpus-only linked-ctx assumption; gen-dispatch UNTOUCHED); conservation LOUD (errors.expansionEnrich/PipeOp/Uncovered — enrich feed + fleet pipeOps are probe-time commitments); probe honesty (tryEval catches throw/assert only; missing-attr still hard-fails; `or` defaults = the idiom); shim compilePolicy→record, kindIncludePolicies per v1 wrapChild taxonomy (C6 fix folded, R9 kept), compileCanTake RETIRED into records, both-declared-AND-included keeps both firings. Gates lead-seen: ci 540/540 + parity 71/71 exit=0. Corpus re-probe: stratum probe PASSES; **NEW RUNG = v1 BUILT-IN PROVISIONING** — `attribute 'system-to-flake-parts' missing` @ corpus devshell.nix:26:40 (v1 ships built-in policies modules/policies/{flake,flake-parts}.nix + built-in kinds like flake-system the corpus references; shim must provide at same attrpaths; D7: compat-side PROVIDED BATTERY, never core constants; relation to #50-N1.5 battery seam must be stated). Post-8e2f8c8 rungs (both LOCAL, pending owner push; origin 8e2f8c8): **de9d64b** built-in provisioning (R15: eval-time builtins.nix — host-to-users inert + user-to-host identity-linked + 3 named flake-output stubs + kinds {flake,flake-system,flake-parts,fleet,hm-host}; excludeOfPolicy named class-B abort; stubs stayed INERT at re-probe = class-A crosses the nixos terminal, not v1's flake-output chain) → **744fcc0** home-env/lib-surface (R17: den.lib.* class CLOSED — faithful home-env trio, isEnabled short-circuit = probe-safety so NO or-null deviation; R14a inline-aspect kind-include HOIST with verified-duplicate .policies drop + guards; hostConf lib-from-module-args = R10 consumer-lib principle; 13 witnesses; ci 559/559 + parity 71/71). SPEC-AS-YOU-GO live: R10-R17 + R14a + assembly A4 refinement in papers specs (#52 DONE). → **867: batteries rung CLEARED @865710f** (catalog v9 has the full arc): gen-aspects PUBLIC wrapFn @ccffbca PUSHED (mkWrapped shared construction site; equivalence witness) + shim recursive wrapChild-normalize (grounded runtime class keys) + 7 faithful batteries at config.den.batteries.* (withSystem-from-module-args = R1) + callGated (v1 can-take.nix verbatim, cited) + spawn constructor. LEAD REVIEW CAUGHT + fixed a silent-drop bug (uniform "<include>" wrap names collided in forwardExpand dedup → positional `<owner>:include:<i>` names + 3 witnesses); unfree = LEDGER ROW u1 latent-v1-divergence (needs per-class `class` coord, board #55 two candidates, LOUD pin witness, self-announces at drvPath). → cluster-to-nixidy rung CLEARED @9b0468b (LOCAL, pending owner push): 3-hypothesis diagnostic arc (catalog v9-addendum) ended with the LEAD-PROVEN trigger — nixpkgs `types.anything.merge` wraps a TOP-LEVEL fn def in a bare `arg:` lambda ERASING functionArgs (nested fns preserved → den.policies = only affected key, batteries safe); fix = bridge `options.policies` def-COLLECTOR (R10 2nd instance) + reproducing-fixture witness class (through the bridge's REAL nixpkgs eval) + ledger row u2 (nixidyEnvs silently empty; instantiate-stub wall = #49/#50). **SESSION SEED DOC (read FIRST on cold start): papers plans/2026-07-11-den-hoag-ship-gate-status.md @03a14ab** — completed-work table (all rungs+commits), remaining-work order (probe closure → #55 wall → drvPath → n=7 → #49/#50 arc → classes B-G → runner/ledger → #53/#54/#56/#43), reference index, operating discipline. **★ HOST-LIST MILESTONE 2026-07-11 @981d401 (catalog v24): corpus nixosConfigurations EVALUATES under den-hoag — all 8 nixos hosts, droid/darwin class-excluded, probe-exit=0 lead-verified.** Subagent-driven rungs post-e394b7d (all local, ~9 commits pending owner push; catalogs v16-v24): flake-parts class 5e1a2d8 → entity fields 30f85ff (u6/#59) → homeManager grounding df086f7 → stub gates 804cf4d → flat-host normalizer 172b1b8 → den.default merge 8cf3f31 → batteries option 075d05a (anything-erasure class closed 4 ways) → aspect-include policy arm 1df5db1 → nested aspects 981d401 (v1 isNestedKey discriminator + scope-coord emission identity; u7; cluster-aspect served by same arm). NEXT RUNG: M2 instantiate-default gap — corpus host.instantiate is a mkDefault inside its OWN den.schema.host submodule (host.nix:325), lost at the raw bridge crossing → members = collect artifacts; fix = materialize the schema-declared defaults for instantiateFor → then the FIRST drvPath + n=7 byte-comparison. → agenix rung CLEARED @ec86bae (absorbs 9b0468b — collector never ships): impl-eco's stop-gate proved agenix = MISCLASSIFICATION not probe hazard (v1 discriminator = den.policies COERCION policyRegistryType: references are {__isPolicy} RECORDS, local bare fns are PARAMETRIC ASPECTS w/ result-TYPE dispatch; __probe=false would have MOVED the crash); landed = bridge coercion (dual: discriminator + formals-by-nesting, subsumes collector) + record-only isPolicyRef + minimal 3rd kind-include arm (synthetic positional aspects, static/record paths byte-stable) + rows r/u3 (u3 → board #57 scope-local firing); R14 CORRECTED in spec (dated block, papers @97a4d58). → **PROBE-HAZARD CLASS CLOSED @ea24665** (LOCAL pending push; 2722795 defaulted-coords + ea24665 configurable sentinel — core compileWith/den.probeSentinelFields field-agnostic default {}, shim supplies {class,system} «probe» strings type-correct-non-matching; userDetectFn or-null RETIRED forward-revert, 8ce1d7c stays published no-rewrite; A4 amended @4058e35, catalog v13). → identity-boundary STATIC arm cleared @669867b (nine content-set refs → positional synthetic aspects; the (b) __provider registry restructure = board #58, dead-as-ruled per the dedup-hinge falsification; cluster-aspect dispatch-twin = pre-authorized small (a)-extension when it fires) → **#50 instantiate rung cleared @e394b7d** (constructor un-stubbed class-A-minimal; spawn proven childless-inert; ledger u4 colmenaHive-latent + u5 nginx-multi-ref→#58; u2 mechanism update). **impl-eco RETIRED at context ceiling 2026-07-11 (catalogs v2-v15, ~15 rungs); SUCCESSOR to be spawned by owner, seeded by the status doc.** CURRENT RUNG: flake-parts deliver-class — `deliver (C6): policy 'deliver' names unknown class 'flake-parts'` (devshell.nix:13 route target; R2 registration territory; expected shape = compat-side class registration + class-F output family latent/ledgered; survey first). Owner's next-push scoping: #53 census then #54 test extraction. **Owner rulings 2026-07-11: continue the composition-first path (refactorability = the insurance; no new gen-lib ratification gate, keep flagging close calls); JOINT OWNER WALKTHROUGH of all changes at arc end (board #56) — preserve the full record: rung catalog, R-set amendments, ledger rows, A4 refinements, board/memory; walkthrough prep = commit-keyed traversal derived at arc end.** Repos: den-hoag origin/main = 8ce1d7c (owner pushed ec86bae+2722795+8ce1d7c 2026-07-11; sentinel-enrichment commit IN FLIGHT as a NEW commit — no amend of pushed history, userDetectFn revert rides it); gen-aspects ccffbca gen-merge 5d5e0de gen-schema f6749cb pushed; corpus untouched b0b20769. impl-eco queue LAGS (use self-contained CURRENT-STATE ANCHOR messages; it acts correctly on anchors + holds committed-not-pushed work).

**Native user/account/integration model DECIDED 2026-07-10** (spec addendum papers 2026-07-10-den-hoag-user-host-integration-model.md @54e44a2, board #49): user = ROOT kind decoupled from hosts (binding via membership cells); the (user,host) cell = the localized ACCOUNT (child of host, B4a containment; binding-derived users.users.<name> route); home-manager = a nixos INTEGRATION module/route, not a scope model (hjem/darwin/standalone = siblings); BACKWARDS COMPAT load-bearing (home-manager class + contentClass keep working; D5 opt-in auto-registry from host.users); den.homes = same cell model, hostless binding (closes OQ5). Layers on shipped mechanisms, no immediate code; native era w/ #43.

**C9 PROGRESS 2026-07-10 (impl-c8, LOCAL/unpushed on origin/main d65f0dc; awaiting combined review + item-3 owner call)** — 1a049a2 (P3/P6): permutationGate (trace order-indep UNCONDITIONAL; content half folds the class module list via nixpkgsLib.evalModules+freeform absorber, NOT raw outputFor which is order-sensitive — the M2 layer lesson) + parity-ledger-gate.nix (P6 "corpus diffs ∖ ledger = ∅", family matchers ENUMERATED not wildcard, host+user negative controls) + runbook append + MIGRATION.md. dc9a4db+80a7dce (item 5 user-root): FORMAL LEDGER ROW residual-n (intentional-v2-semantic, deliberate user-as-cell — NOT OQ4 name map; edges have different TARGETS), scoped P1-ONLY (P2 host-terminal drv-hash still asserts content equality — not a content waiver). **TWO OWNER-RULED STOP-AND-FLAGS reshaped the convergence sequence: (1) item-1 hm-battery port = VOID → f7811a1 reclassified residual-o INTO residual-n citing Law A15 (output-modules isolation: user cell is a distinct edge-root; den v2 folds home-manager PER (user,host) CELL `collected:user:<u>/home-manager`, NOT at host; v1's host `collected:host:<h>/homeManager` fold IS the user-as-root model as an edge; a battery port would fabricate a user-cell EXTRA and still miss the host fold — empirically verified 2 probes). (2) item-3 live-v1-vs-hoag-content-in-CI = VOID → the v1 content fold INFINITE-RECURSES on real nixpkgs nixos modules (`nixos/common.nix` refs config); asymmetry: hoag `.imports`=plain den-hoag class data (freeform-foldable), v1 `.imports`=real NixOS modules (need full module system). So v1 content arm needs the FULL nixos crossing = SHIP-GATE (deeper than M2's home-manager-input reason). Both RESOLVED by owner ruling: (1) reclassify (done); (2) merge item 3→item 4 (option b: parameterize the shim terminal). 6f6d306 (item 2): home-manager wired as pinned parity-flake input + threaded into mkV1 (edge arm never forces it). b8159e6 (MIGRATION supplement, guardrail 4): frames hm change as migration TO the D1-D6 native model. **C9 COMPLETE 2026-07-10 @0ab8062 (9 commits on d65f0dc, unpushed; ci 487/487 + 11 parity suites incl new content-live 2/2): item 4 = the nixos-TERMINAL SEAM (4e49ef6: mkFleetModuleWith/mkDenWith supply the shim's nixos terminal; harness builds the nixpkgs-bound crossNixos from `${den-hoag}/lib/output/terminal.nix` + internal.{bind,flake}; REQUIRED ship-gate infra — a collect-pinned shim can't produce a shimDrvPath for contentGate; default byte-identical, ZERO core edits) + LIVE n=1 comparison (b89a5d9: parity-content-live.nix — both arms CROSS, v1 hostName==hoag hostName + fold==crossed bonus; parity/ship-gate.nix drvPath smoke on boot.isContainer → **v1DrvPath == shimDrvPath BYTE-IDENTICAL at n=1, real P2 drv-hash parity PROVEN**; measured 0.5s hostName / 1.2s drvPath). item 6 (0ab8062, notes): corpus survey found (a) darwin host `patch` (aarch64-darwin) → M2 darwin corpus-required, (b) **pin-(p) CORRECTED — DOES fire on corpus** (most hosts declare NO class field; `patch` = darwin-by-system-no-class → shim `h.class or "nixos"` misclassifies it nixos; reclassified bug-in-hoag; ship-gate fix = derive class from system or default null), (c) new ledger row q = `droid` (nix-on-droid) class host `slab` needs registration, (d) #624/#625 collapse-bug structurally absent on v2 + pin-bump material (stay #623 for the frozen oracle). Closes den-compat C0-C9. **C9 COMBINED REVIEW DONE (both APPROVE-WITH-FIXES) → FINAL ROUND @3324cf1 (10 commits d65f0dc..3324cf1, ci 488/488 + 11 parity suites, ship-gate drvPath byte-identical; impl-c8 RETIRED after this).** Final fixes: (1) pin-(p) FIXED by EVIDENCE not the reviewer's null-default — verified on the v1 arm that v1 DERIVES a classless host's class FROM SYSTEM (`nix/lib/entities/host.nix:65-66`: `host.class or (hasSuffix "darwin" system ? "darwin" : "nixos")`; igloo→nixos, patch→darwin, `host?class`=true so os route fires); shim `ingest.nix classOfHost` reproduces it exactly (contentClass + stamped class field; explicit host.class wins e.g. slab="droid"); a null default would leave darwin hosts UNROUTED; witness test-p-classless-class-from-system; L3/L5 UNCHANGED (fixtures linux-only). (2) ledger Notes+row-p→FIXED. (3) stale residual-o refs dropped. (4) flake.lock hm.nixpkgs pinned to top-level `["nixpkgs"]` (flake-update dedup had left it on corpus/nixpkgs, a DIFFERENT rev; both crossings use top-level) — n=1 drvPath byte-identity survives. **den-compat DONE; awaiting owner push.** Next (post-impl-c8) = migration #43 + the ship-gate corpus arm (patch/droid host-class-from-system, #624 multi-user, full-fleet drv-hash live verification).

Architecture direction (user, 2026-07-05): NOT a den refactor. Identify den v1 functional components + their formal contracts, re-implement as tightly-scoped pure component libraries on the gen substrate, composed — no monolithic evaluator. Existing specs are references only; write fresh component reference specs. Parity/compat shims built progressively. See [[project_hoag_architecture]] [[project_den_hoag_readiness]].

## 2026-07-11 ship-gate session state (compaction checkpoint)
Origin/main = 25c9682 (the full user-delivery arc R1-content-rung published). The IN-FLIGHT rung:
§3c-UNIFIED (topology-following join semantics + tuple-carried bindings, owner-ratified) — the
sole blocker before the first axon-01 drvPath byte-compare. COLD-START READ ORDER:
papers/den-architecture/plans/2026-07-11-den-hoag-ship-gate-status.md (the map) →
plans/2026-07-10-ship-gate-gap-closure.md catalog v2–v57 (canonical, per-commit review
histories) → specs/2026-07-11-user-delivery-arc-design-note.md (§3c-UNIFIED = the live design).
Standing rulings: kind-generic mechanisms/nothing-config-specific; the boundary law (v1-spec
facts vs corpus facts); the escalation line (core → owner note pre-build); review economy
(~75% weekly budget). v1 reference drv: /nix/store/q1vk4s3z8r593mf5sg39pwqaijys7d2p-….drv.

## 2026-07-12 WEEKLY HOLD checkpoint (supersedes the 2026-07-11 compaction checkpoint)
★ THE FIRST REAL drvPath 2026-07-12 (d1bz7nzy…, full assertion gate cleared, ledger u18);
byte-compare ran once: DIFFERENT, two families, both addressed same-day (#68 hm battery —
hm-users populate; #69 U9.2 twins). Ladder u19 (#70 raw side channel, SHIPPED) → u20 (bare
host.users lacks user-kind defaults → TASK #71 = next week's first rung → re-probe → THE
byte-compare). CI 885/885, parity 71/71 every rung; core commits independently reviewed (all
APPROVE). Repo at hold: origin/main pushed through 0de4f17 (owner); local main 304dcfa (3
ahead: 77cb3c8+1541bbe+304dcfa). Catalog now v2–v76. CLASS-D PROBE (v75, owner-prompted):
nixidyEnvs rides the GENERIC instantiate verb (corpus cluster-to-nixidy →
den.lib.policy.instantiate, intoAttr) — #50 declarable-instantiation = the SOLE unlock for
B+D+likely-C output surfaces; class-by-class arc framing RETIRED. Spec amendments current
through v49-v69 (papers aacb064: A5/A12/A15/A16/A17 + R18-R22; residual: confirm A15 §9
anchors = 10bc922). Durable gotchas: the {den.x} // {den.y} fixture attrpath clobber (struck
3×; the "gen-scope reachability artifact" NEVER existed — ledgered); degenerate fresh spawns
(4× — SendMessage-resume of a proven agent is the reliable path). Cold-start read order
unchanged (status doc → catalog → design note §§7-9, all owner-ratified).

## 2026-07-12 FINAL-PUSH close (supersedes the weekly-hold checkpoint)
#71 userType twin + #72 exclude family (candidate A, owner-ratified — scope-local policy
suppression via a SECOND staged-pre-pass family) + #73 droid-arc chase SHIPPED. ★★★ THE
BYTE-COMPARE: drvPath 5iskbzl4… vs q1vk4s3z… = DIFFERENT but **FAMILY B FULLY CONVERGED**
(k3s --server/known_hosts/frr/nftables all closed); residual = ONE root-caused family
(u22/task #72-native): host-attached hm content — corpus attaches user-profile hm AT the
host; v1 reads the host homeManager bucket as per-user BASE; hoag forwards the cell's own
bucket only. Fix shape = the cell's ancestor-chain hm gather (#63's mirror), NEEDS §10
sketch + owner ruling. #50 validation UNBLOCKED (colmenaHive already present free);
nixidyEnvs/nixOnDroid absent pending #50. Local main 7af0429 (10 ahead of 0de4f17), ci
896/896 + parity 71/71. OWED next week: independent review of dc9dfe8 (core); the §10
sketch; then #50; then n=7. Catalog v2–v79.

## 2026-07-12 TRUE WEEK CLOSE (supersedes prior checkpoints)
§10 RATIFIED+BUILT same-day (commits 8b0c5a7..1b49683; ci 904/904, parity 71/71): the u22
hm family DELIVERED as content (host zsh+plugins, package sets EQUAL, persistHome) + three
corpus-only v1 laws chased in-family (authored-spelling class keys kebab≠camel; nest-source
firing-scope binding; inherited+flat channel values — the u9 received-collections ceiling
CLOSED). Byte-compare whf8kalj… vs q1vk4s3z…: NOT EQUAL but ALL content families closed —
residual = (α) ORDER-PARITY (A12-canonical vs v1 include-order; OWNER-GATED §11 sketch;
compat-boundary ordering adapter candidate, ledger u23) + (β) the hm_.zshenv LOCALE_ARCHIVE
leaf (small). Local main 1b49683, 15 ahead of owner-pushed 0de4f17. Catalog v2–v82. RESUME:
plans/2026-07-12-resume-next-session.md (the prompt opens at the §11 sketch + β diagnosis).

## ★★★★ 2026-07-12 THE n=1 SHIP GATE IS MET (supersedes prior checkpoints)
§11 (delivery chaining, C1 source-side chain read) RATIFIED+BUILT @3dd2c31: axon-01 under
den-hoag is ORDER-EQUIVALENT to the v1 reference (order-equivalence-check.py exit 0) under
the owner's C3 ruling ("equivalent config — list ordering isn't a requirement", tool +
waiver family = ledger u24/u25). ci 909/909, parity 71/71. Local main 30fcb32 (18 ahead of
owner-pushed 0de4f17). REMAINING to fleet class-A: task #74-native filterRootModules twin
(blade/cortex duplicate-decl abort — v1 route.nix:534-552 restricts chain-owned fromClass
root modules to den.default-tagged; NOT a #75a regression) → per-host verdicts → n=7 (darwin
patch) → #50 instantiate (nixidyEnvs/nixOnDroid; restore loudness on #73-parked routes) →
B-G diffs → wrap-up (#56 walkthrough, #53/#54, #43 migration). OWED: independent review of
3dd2c31 (core chain law). Resume: plans/2026-07-12-resume-next-session.md (update pending) +
catalog v2-v85.

## ═══ 2026-07-13 TWO-TRACK REFRAME (supersedes prior checkpoints; resume doc = plans/2026-07-13-resume-next-session.md) ═══
The single "task #74-native" frontier DECOMPOSED into two independent parallel tracks after an
architectural correction. **The compat-boundary "value-injection re-plumb" is REJECTED** (spec
`specs/2026-07-13-den-hoag-compat-boundary-value-injection-redesign.md` marked REJECTED; adversarial
review + independent re-probe refuted §6 identity-equivalence AND §7 flake-parts sibling re-bind — do
NOT re-attempt). Root cause of the debt: gen-aspects native `.key` is NAME-ONLY for plain nested aspects
(`hardware.cpu.intel`==`hardware.gpu.intel`==`"intel"`, collide=true, LATENT behind `__provider`); the
`__provider` shadow layer exists to reconstruct the path. Detail = [[project_den_hoag_value_injection]].

**Track A — filterRootModules twin (den-hoag) = the LIVE ship-gate blocker.** Spec
`specs/2026-07-13-den-hoag-filterrootmodules-twin.md` + plan
`plans/2026-07-13-den-hoag-filterrootmodules-twin-plan.md`. Investigation (frm-investigate) found it is
TWO RUNGS: (A1) a shared-vs-own PROVENANCE MARKER on class-modules entries — ABSENT today
(`class-modules.nix:49,53` stores raw identity-less modules; den.default radiates via `__denDefault`
policy compile.nix:1041-1061/1261 but the distinction is discarded); derive from source resolved-aspect
`aspect.key` (retirement-safe, NOT `__provider`). (A2) the twin at the per-member bucket read
`output-modules.nix:379-383` + render twin `:266-290` (fire when member is a PROPER ANCESTOR of firing
cell AND `srcClass == producingClassOf n`; never filter the cell's own bucket; the class-agnostic
`collectedMembersOf` is the WRONG site). (A3) parity gate blade/cortex + docs R-ROOT-FILTER verbatim.
Without A1 the filter over-suppresses host-forwarded content (regresses test-ancestor-bucket-host-first) —
so it is genuinely marker+rule, not "one rule".

**Track B — A-IDENT intrinsic path identity (gen-aspects) → `__provider` retirement (zero-debt).** Spec
`specs/2026-07-13-gen-aspects-intrinsic-path-identity.md` + plan
`plans/2026-07-13-gen-aspects-a-ident-plan.md`. Fix = M1-thread (owner: "born in the type"): SURFACE the
`prefix` gen-merge already computes (= the merge loc) so `.key = pathKey(path)` intrinsically. **B1 DONE:
gen-merge surface prefix via baseArgs, committed `2701d8b`, suite 177 GREEN, REVIEW-PENDING.** B2-B8 open
(2a mount-absolute vs 2b container-relative form probe → aspectSubmodule stamp meta.aspect-chain →
re-baseline gen-aspects tests → docs → den-hoag consume native key → DELETE `__provider` shadow layer).
Owner directive: the identity model must be coherent with future aspect-registry / den-namespace /
cross-flake import-export ORIGIN identity (spec §3a) — mount prefix is a proto-namespace an origin
qualifier extends additively.

Parallelism: A (den-hoag) ∥ B Phase 1-2 (gen-merge/gen-aspects, disjoint repos); B Phase 3 (B6-B8,
den-hoag) SHARES resolved-aspects.nix/output-modules.nix with A → serialize after A.

**Process corrections hit this session (BINDING, folded into resume doc):** OPUS for subagents (sonnet
was wrongly used for B1 — [[feedback-opus-subagents]]/feedback_subagent_model); use RESUMABLE TEAMMATES
(SendMessage-resume) so review feedback goes to the same context, not fire-and-forget; STAGE new files
(git add) before nix eval — untracked test silently didn't run → false GREEN
([[feedback_stage_new_files]]). den-hoag main unchanged 11f17df this session (only gen-merge advanced to
2701d8b). Prior queue (#50, n=7, #56, #53/#54, #61, #49, #43, #28) still valid — see resume doc.

## ═══ 2026-07-14 THE PROJECTION REDESIGN (supersedes the two-track reframe) ═══
Both tracks resolved, then the frontier RE-SHAPED by an owner architectural call.
**Track B A-IDENT SHIPPED** (gen-aspects): owner chose **2b container-RELATIVE** form (NOT 2a
mount-absolute — 2a embeds consumer mount, mismatches den-hoag's root-relative `__provider` + violates the
§3a origin-invariant north star). New `aspectsRoot` container type re-roots each aspect (prefix reset);
`.key = "apps/media/spicetify"`, intel/intel de-collides, guards unified relative, flatten.key==.key exact.
Commits d699c4b/d9833d5/26671c8/c019c15, 115 green (needs `--override-input gen-merge <local>` — 2701d8b
UNPUSHED). Two-stage reviewed SHIP.
**Track A twin** committed as PARITY FALLBACK on den-hoag main (3ede207 A2 + 4c27406 A1), but **SUPERSEDED**
by the redesign below.
**THE REDESIGN (owner: "don't commit to den's v1 model").** filterRootModules is a COMPENSATION for #74a
blanket ancestor-inheritance colliding with the host-aspects projection (denful/den
batteries/host-aspects.nix = a spawn policy projecting host homeManager onto opted-in users). New model =
**CLASS-PROJECTION over the resolved-aspect graph** (spec `specs/2026-07-14-den-hoag-aspect-class-projection-design.md`,
owner-approved + specrev-reviewed SOUND-WITH-REFINEMENTS): classes = VIEWS over one reach-graph, not
emission targets; `output_C(S) = ctxEval_S(merge_ord {aspect.C | aspect ∈ reach(S)})`; single-visit
per-scope dissolves the spicetify double + radiation-double as graph properties. Owner decisions:
RE-BASELINE (no v1 byte parity, new frozen baseline); reachability = OPT-IN edge-gated; NO universal tier
(baseline = framework-injected per-user edge; den.default/radiation dissolves into edges); scope = aspect
multi-class emission ONLY (pipe/value-flow deferred → **inbox/outbox channel pipe delivery** future pass,
noted in resume doc); negative-edge model for `policy.exclude` (folds in u21); forwards/routes = careful
TRANSFORM layer on the projected view (class→class content vs arg-env transform split), NOT deleted.
DELETES #74a collectedMembersOf/deliveryModulesChain/filterRootModules/A1 marker/__provider shadow.
6-phase decomposition (§7); each phase its own writing-plans cycle.
**Phase 1 SHIPPED** (graph + edge model — the `reach` substrate): plan
`plans/2026-07-14-den-hoag-projection-phase1-graph-edge-model.md`, worktree `.worktrees/projection` branch
`feat/projection-graph`, 5 commits (8ef4dd1→35ffcba→7191860→06cc4eb→bf6299a) over twin base 3ede207, **931
tests**, all two-stage reviewed SHIP + final holistic review SUBSTRATE SOUND. reach(id) = per-scope
single-visit class-scoped closure over positive edges (own-subtree + framework default + class-scoped
opt-in) minus negative (suppress) edges, canonical merge_ord order (own→default→opt-in, first-occurrence
dedup). ADDITIVE — reach UNCONSUMED, fleet/golden suites byte-identical. Handoff notes (edge-identity=target
Phase-5 limit; stub-vs-real vocab needs Phase-5 policy verbs emitting reach-edge/reach-suppress; classFilter
dep-free predicate Phase-2 refines) appended to the plan doc. Branch KEPT for Phases 2-6 (NOT merged; main
retains twin fallback). **Phase 2 = the projection engine reading reach = next plan cycle.**
Pending coordination (all local/unpushed, owner's call): gen-merge 2701d8b push + A-IDENT pin-bump; papers
gen-aspects REFERENCE.md uncommitted; twin fallback + feat/projection-graph unpushed.

**PROJECTION Phase 1 + Phase 2 SHIPPED + ecosystem pushed (2026-07-14, "all work approved, proceed").**
Ecosystem: gen-merge 2701d8b PUSHED (github:sini/gen-merge main); gen-aspects A-IDENT 2b + gen-merge
pin-bump PUSHED (github:sini/gen-aspects main @14652a0, 115 green no-override); papers design docs
committed; den-hoag feat/projection-graph PUSHED (origin/feat/projection-graph); den-hoag main twin
(3ede207) NOT pushed (owner-surface + gets reverted Phase 3). **Phase 1** (reach substrate) = plan
`plans/2026-07-14-den-hoag-projection-phase1-graph-edge-model.md`, 5 commits, 931 tests. **Phase 2**
(projection ENGINE) = plan `plans/2026-07-14-den-hoag-projection-phase2-engine.md`, commits e4c713c→
90b95ae→06505de→b4e19c1→ec14928, **934 tests**, all two-stage reviewed SHIP + holistic ENGINE SOUND.
THE THESIS PROVEN synthetically: spicetify double → ONE (single-visit graph property), intel cpu+gpu both
project (native-key de-collision), define-user splits nixos@host + hm@cell. `terminalModulesAt =
projectClass` (own+descendant byte-identical to classSubtreeAt per the ANCHOR; emission half in the RED
WINDOW until Phase 5). Two spec corrections the anchor forced: (1) §1 single-visit refined — bare-key dedup
= EDGE closure + within-node ONLY, structural-descendant preserves per-provider-scope multiplicity (caught
a real content-loss bug: sibling cells' same-key define-user collapsing → dropped users.users.pol/.tux);
(2) §3 §2.2 totality holds at the projection terminal (assertKeysRegistered — a typo'd key aborts named on
the drv path, else silent vanish). **REMAINING phases (each its own plan cycle):** 3 delete dead emission
(deliveryModulesAt/Chain + filterRootModules twin 3ede207 + A1 marker 4c27406; KEEP collectedMembersOf =
live edge-render) + revert twin/A1 + fold __provider retirement; 4 forwards/routes transform layer
(class→class content vs arg-env split); 5 corpus migration (host-aspects→opt-in reach-edge + framework
default edge — turns the 3 mark-pending green + the fleet green); 6 full-fleet re-baseline + functional/
intent validation. Phase-3 note: harden assertKeysRegistered's message robustness if content.name ever
absent (LOW, + a non-repro content.name transient flagged). Full detail in the two Phase plans' completion
sections.
**Phase 4 COMPLETE (2026-07-14, plan `plans/2026-07-14-den-hoag-projection-phase4-transform-layer.md`, 948
tests, all reviewed SHIP + holistic SOUND):** forwards/routes = a TRANSFORM layer on the projected view.
Commits 9024cca (route class-remap bucket-b) → 0095da8 (hm-user-detect descendant, greens the 3 formerly-
pending) → c109706 (arg-env wrapper bucket-c) → 5f1ee02 (synthesize content producer, generality/fleet-inert)
→ ee297d5 (guard config-gate + functionArgs classification). Census (p4-census): only 3 corpus-live routes
(home-platform homeLinux→homeManager fills the LOCALE hole; hm-user-detect homeManager→host-nixos; devshell→
flake-parts+adaptArgs); rest corpus-inert generality. **TWO WINS:** (1) projection SUBSUMES the Track-A
filterRootModules twin FOR FREE (source=reach cell own-subtree, host scope-own hm never leaks — the original
ship-gate blocker is unnecessary in this model). (2) guard-phase = STATIC-FORMAL classification (functionArgs,
owner best-of-both, no adaptArgs-proxy); eval-time gate = CONFIG-GATE via nested eval (owner ruling C — den
is a general framework, eval-time route guards must be sound): gating a slice's nested-eval'd CONFIG via mkIf
(not IMPORTS) breaks the `imports←guard(options)←options←imports` cycle — ADVERSARIALLY PROVEN. Bound
(module-system-fundamental, ledgered): a config-gate can't conditionally DECLARE options; common case sound.
FRAMING FIX: corpus has ZERO route guards (home-platform gates at POLICY dispatch = unguarded route); route
guards are framework-generality (synthetic witnesses). Spec §5 updated with all Phase-4 rulings (wrapper,
config-gate, functionArgs). adaptArgs = terminal-crossing FUNCTION-MODULE wrapper (v1 nestWithAdaptArgs),
terminal.nix untouched. **REMAINING phases (own cycles): native-identity-consumption (unlocks __provider
retirement, §5/§7 precondition); Phase 5 corpus migration (host-aspects → opt-in reach-edge + framework
default edge → turns the fleet green + the pending markers); Phase 6 full-fleet re-baseline.** All on
feat/projection-graph (PUSHED by owner 2026-07-14 through ee297d5; gen-merge/gen-aspects + every gen lib
pushed). **OWNER GRANTED PUSH FREEDOM 2026-07-14 — free to push den-hoag + gen libs yourself (supersedes
the "owner pushes den-hoag" note).** Full detail in the Phase-4 plan completion section.
**PHASES RE-ORDERED 2026-07-14 (owner): native-identity-consumption ships BEFORE corpus migration** (because
__provider is load-bearing UNDER the projection — navigated den.aspects values are "<anon>" natively).
New order: Phase 5 = native-identity + __provider retirement (spec `specs/2026-07-14-den-hoag-native-identity-
consumption.md`, under nident-rev review; open forks = (i)-stamp-tree-key vs (ii)-side-map + the id_hash
divergence risk stamp-provider.nix:34); Phase 6 = corpus migration (host-aspects→reach-edge, TURNS FLEET
GREEN); Phase 7 = re-baseline. RESUME DOC: `plans/2026-07-14-resume-next-session.md`. Old parity queue
(twin/n=7-byte-compare-vs-v1) SUPERSEDED by the re-baseline; #50/droid+darwin-registration/#49/#43/#28
survive.
**Phase 3 = Task 1 ONLY (2026-07-14, `5c537a0`, 932 tests, reviewed PASS/PASS):** deleted the dead
class-emission fold (deliveryModulesAt/Chain + the filterRootModules/R-ROOT-FILTER twin −201 lines + A1
__shared/__denShared/sharedAspectKeys marker + orphaned error ctors) + retired the A1-marker witness +
hardened assertKeysRegistered (content.name-or-<unnamed>, teeth-proven). KEPT live: collectedMembersOf/
deliveryEdgesAt/outputFor/classSubtreeAt (anchor oracle). The twin+A1 are now GONE from feat/projection-graph
(still on main @ 3ede207/4c27406). **Task 2 (__provider retirement) DEFERRED — owner ruling: the PROBE
FAILED.** __provider is NOT a redundant shadow — it's the SOLE identity source for navigated den.aspects.<path>
values (den-hoag declares den.aspects as schema.types.raw, NOT typed through aspectsType, so navigated
values are natively "<anon>"; A-IDENT landed in gen-aspects but den-hoag never CONSUMES it). Deleting it =
board-#58 corpus-zero-content regression (compat-include-identity.nix F1-F5). No deletable subset. Retirement
gated on a NATIVE-IDENTITY-CONSUMPTION prerequisite phase (the §5/§7 precondition, probe-confirmed unmet):
mech (b) flatten/A-IDENT stamp over the raw den.aspects tree in den-hoag's own eval + dedup on native path
key (likely avoids the §7 flake-parts-sibling blocker), or (a) type den.aspects @ bridge (§7-blocked). Spec
§4/§5 updated with the probe finding. **Remaining redesign phases (each own plan cycle):** native-identity-
consumption (before/independent of __provider retirement); Phase 4 forwards/routes transform layer; Phase 5
corpus migration (edge producers → 3 mark-pending + fleet green); Phase 6 full-fleet re-baseline. All on
feat/projection-graph (pushed); den-hoag main twin still unpushed (owner-surface).

## ═══ 2026-07-16 CHECKPOINT — SHAPE B SHIPPED + PROJECTION PHASE 6 IN FLIGHT (supersedes prior) ═══
**SHAPE B (= projection Phase-5 native-identity/__provider retirement) SHIPPED.** The value-injection
debt is ELIMINATED via a per-key `keySemantics` map (gen-schema OPAQUE surface `ec64a35` → gen-aspects
GENERIC dispatch `b19ca92` → den-hoag single typed tree) → compile grounds identity on native gen-aspects
`.key` → `__provider`/annotate/stamp-provider DELETED; byte-parity (`v1DrvPath==shimDrvPath`) held every rung.
Full arc + revs: [[project_den_hoag_value_injection]] (RESOLVED) + [[project_gen_package]] (2026-07-16). Bonus:
gen-schema substSubModules re-release (gen-merge→2701d8b) unblocks nixpkgs-mount consumers.
**PROJECTION PHASE 6 (corpus migration) RE-DECOMPOSED grammar-first** (spec
`specs/2026-07-15-den-hoag-projection-phase6-decomposition.md`; the ambitious integrate-first plan was
SUPERSEDED — plan-review NOT-READY): grammar/gen-aligned first; synthetic-fleet integration at the PROJECTION
level (not nixos builds) is the first-pass oracle, grown INCREMENTALLY per transform; DEFER real-fleet parity
(n=1 igloo ≠ fleet parity — owner correction). Each producer TRANSFORMS a live compat mechanism whose REMOVAL
is part of the same transform (NOT additive). Corrected producer paths (plan-review-verified): host-aspects =
SPAWN path `compile.nix:864` NOT include; baseline = den.default radiation `:1062-1138`; droid = named-suppress
on a ROUTE (§5 layer — 6.2c OPEN ITEM: reach-suppress inert vs a route). SHIPPED on feat/projection-graph:
**6.1 verb grammar `7f72c1a`** (reach-edge/reach-suppress string-id verbs, additive 947→953); **6.2a
host-aspects→class-scoped reach-edge `bcfd99e`** (953→956, the v1 host→cell hm projection now a reach producer,
replaces inert spawn; assertion proven non-tautological). NEXT = 6.2b (radiation→default-edge, folds harness
hoist) → 6.2c (droid, route-vs-edge) → deferred parity reckoning. Resume:
`plans/2026-07-16-resume-projection-phase6.md`. den-hoag main still twin `3ede207`. OWED: purity.nix regex
stack-overflow fix ([[reference_nixunit_regex_stackoverflow]]); Task-6 nix-config bump + _kindNames.

## ═══ 2026-07-16 — 6.2b SHIPPED (den.default → plain den.aspects.defaults), OWNER REDESIGN ═══
6.2b DONE + PUSHED origin/feat/projection-graph (`bcfd99e`→`beb441b`, 4 commits, ci **951** + parity checks
green). **OWNER REDESIGN supersedes the resume's "framework default edge via defaultEdgeTargets":** don't
build a default-EDGE; make defaults an ORDINARY aspect on the general kernel path. `den.default` desugars
COMPAT-SIDE (`legacy/defaults.nix`) → a plain `den.aspects.defaults` wired into `den.schema.{host,user}.includes`
(the general `__kindInclude` path). The two built-in routes (os-to-host/user-to-host) COERCED
`{__denCanTake;fn}`→`{__isPolicy;name;fn}` into `defaults.includes` (compile via the `__aspectInclude__<route>`
arm; `.name` restores `includeReferencedNames` single-fire + the droid named route-suppress). DELETED:
`__default`/`__denDefault` radiation block (`compile.nix`), the `defaultEdgeTargets` default-edge KERNEL tier
(`resolved-aspects.nix`/`default.nix` + 6 reach-graph witnesses), `self-provide` R5 branch. Isolation invariant
HELD (zero `lib/attributes/` edits; all changes compat-side). Spec+quality reviews PASS/APPROVED per task.
**TWO GAPS the flip exposed + fixed (both small, compat-side, NOT deep frontiers):** (A) `compile.nix normalize`
passes a typed `__isWrappedFn` functor UNGATED (:465) — fixed by splicing parametric includes RAW in
`flake-module.nix` `restoreUnregistered` so normalize's bare-fn `wrapGatedFn` arm (:455) gates+grounds
(`homeManager`→`home-manager`); a compile.nix:465 re-gate would drop grounding (wrong). (B) `wireSchemaInclude`
materializing `den.schema.user` SUPPRESSED ingest's built-in `user.parent="host"` (`ingest.nix:164-168` applies
it ONLY when `user` absent from v1Schema) → user became a ROOT, cell unreachable — fixed by carrying
`builtinDefault={parent="host"}` for the user kind.
**STALE STASHES (durable — cold-start MISSED this):** the 2 stashes on the worktree (base `192be55`, "task-B-WIP"
+ "single-tree-classcontent-half") are pre-Shape-B WIP fully SUPERSEDED by shipped Shape B (single typed tree
in-tree @`4661968`/`fcb0230`, __provider deleted). An investigator misread them as live; they are NOT — DROP
them (`git stash clear`), never restore. task-B ≠ shelved; it re-landed AS Shape B ([[project_den_hoag_value_injection]]).
**Task 4 (projection-stub witnesses) SUBSUMED** by the real-fleet compat fixtures (baseline-reach/kind-scope/
droid-drop/single-fire/define-user all green on mkDen fleets). **6.2c likely WITNESS-ONLY now** — user-to-host
suppress rides `defaults.includes` as a named route-suppress in §5, so the reach-suppress-vs-route blocker
dissolves; confirm at 6.2c. Full ship-gate drvPath (v1DrvPath==shimDrvPath) = owner-run, NOT in checks.default
(deferred parity reckoning). Spec `specs/2026-07-15-den-hoag-projection-phase6.2b-defaults-aspect-redesign.md`,
plan `plans/2026-07-15-den-hoag-phase6.2b-defaults-aspect.md`. PROCESS: implementer stream-watchdog stalls on
the silent >600s nix gate → implementers make edits, COORDINATOR runs the gate; ci/parity flakes read den-hoag
via `path:..` (locked) → `--override-input den-hoag path:..` + `--rebuild` to force the working tree.

**DEFERRED PARITY RECKONING SCOPED 2026-07-16** (doc `plans/2026-07-16-parity-reckoning-scoping.md`). Premise
CORRECTED: n=1 is already a REAL corpus host (axon-01 end-to-end order-equivalent, ledger u25) — NOT the igloo
container; crossNixos/`mkDenWith` are fleet-general (n=1 was a fixture choice); the `_kindNames defined 2×`
memory-blocker is a SOLVED seam (`bridge.nix` `__rawSchema` split + `passThrough`), NOT gating. The reckoning =
**4 SEPARABLE arcs**: (1) nixos fleet content = THE substance — the #74 host-attached-hm family (host homeManager
bucket → per-user `home-manager.users.<u>`; axon-01 passes via #75a, **blade/cortex NOT chased** = the live n>1
blocker; projection reading = ambient host-hm→cell reach, producer-shaped); (2) darwin `patch` (small — stamp
per-host instantiate onto darwin class + `den.darwin` input); (3) droid `slab` (bounded — register droid output
class + nixOnDroidConfigurations #50/#73); (4) nix-config formal repoint (input swap + import `bridge.nix`; today
`--override-input den path:/abs/den-hoag`). FIRST MILESTONE = Arc 1 #74 for blade+cortex (n=1→n=3, pure
content-delivery, own brainstorm cycle). Corpus = 8 nixos + patch(darwin) + slab(droid), pin b0b20769; v1 oracle
frozen 11866c16.

**═══ 2026-07-16b INSTANTIATION → UNIFIED LINK/MERGE VOCABULARY: DESIGN RATIFIED ═══**
Brainstorm COMPLETED same-day via ultracode (wf_35a14919: 8 research lenses, 5 candidates, 15 adversarial
verdicts — ~85% independent convergence, ZERO fatals; report papers plans/2026-07-16-instantiation-vocab-
ultracode-report.md @49316b8). **Design spec RATIFIED + COMMITTED: specs/2026-07-16-den-hoag-unified-link-
merge-vocabulary-design.md @13af6e8** — typed-edge kernel (two facets: materialization + resolution, ONE
substrate/identity/query/fold). Key shape: nest = THE materialization edge, FOUR modes (content/artifact/
extend/value) derived from receiver `consumes` product type; receivers on outer KINDS, dispatch SLOT ≻ class
(cuda class=nixos routed by slot vm); renders = D7 promoted; collector entities = aggregates (colmena/nixidy),
family-`members` = sugar → anonymous collector; two-level identity assemblyId/instanceId (nominal
producer-ids); user-extensible strata (capability-scoped ctx = enforcement by construction); override tier
pre-identity-freeze; disciplines registry w/ laws ladder; merge orders = ONE engine + three DECLARED instances
(single global order REJECTED — neron recursive-walk evidence); scope-engine-native = den.relations +
den.derived (acl+settings = 2 registrations). **8 owner fork rulings in spec §10** — F6 CORRECTED from
synthesis: query calculus lands in GEN-GRAPH (labeled-traversal ext; gen-scope edgeGraphs/followEdge = data
half, §B6 split; synthesis's "gen-scope REFERENCE limitations 10-11" claim verified FALSE); F7 root = abstract
root entity PURE-NIX core, flake-parts = outer-kind ADAPTER (kernel never depends on flakes). Sequencing spec
§12: (1) gen-graph labeled query lib → (2) substrate → (3) disciplines/fold unification → (4) materialization →
(5) resolution → (6) compat forwarding. Parity-reckoning arcs (#74/darwin/droid/repoint) = validation cases of
steps 4-6. **SPEC REVIEW CLOSED — APPROVED @d782492 (4 revs, 3 review iterations: 16 findings → 8 regressions
→ approved + 3 residuals folded).** Review-driven design deltas worth knowing: value mode = PREBUILT ARM of the
same receiver row (`ArtifactRef P` wrapper; entity `artifact = <v>` short-circuits assembly; conversions never
cross the wrapper); `data.when` predicate-NAME enters dataFingerprint (predicate-differing edges DISTINCT,
matches shipped multi-suppress); member kind @ resolution stratum (selector-driven membership = §2.3
conditioned emission); output stratum = dogfooded dense insertion NOT a fifth seed; §6 reach instance restated
post-6.2b (default-edge tier retired, dedup gates edges / multiplicity in emitted list); A12 identity term
STAYS aspect id_hash (named golden). Owner APPROVED spec + ruled proceed. **STEP-1 PLAN APPROVED @790a8ec**
(plans/2026-07-16-gen-graph-labeled-query-calculus-plan.md + .tasks.json, 7 TDD tasks, 2 review iterations —
notable catches: raw 0x1F byte in carried code → toJSON keys; findFirstIndex/splitString DON'T exist in
gen-prelude; endOfPath added to order; mode="fixpoint" dispatch-aliases queryFold). **═══ STEP 1 SHIPPED 2026-07-17: gen-graph labeled query calculus ═══** github:sini/gen-graph main
@d110703 PUSHED (12 arc commits 7bfe390..d110703, **214 tests/12 suites**, subagent-driven: 1 resumable
implementer + per-task two-stage reviews + final whole-arc SHIP). Surface: `regex.*` (Brzozowski/ACI kernel +
`parse` string sugar, nested export) + flat `query` (modes all/paths/visible/layers/fixpoint→queryFold),
`labeledFrom`, `queryFold`, `labeledFixtures`. Review-driven hardening beyond plan: assoc pins, dangling-op
pins, non-vacuous poison witness (teeth-proven), linear answer fold, all-vs-paths acyclic-witness divergence
PINNED (paths can't witness node revisits — even self-loop length-1; all can), where/valueOf flow-through pin,
eop-tie co-visibility pin. Papers through ac5aec4 (gen-graph REFERENCE + gen-scope limitations 10-11 REPOINTED
+ spec §3 cross-note + tasks.json complete). DURABLE GOTCHAS: (1) gen-lib formatting = `nix fmt` FROM WITHIN ci/ (the mkCi flake carries the
formatter; the ROOT flake has none — an implementer probing root-only wrongly concluded "no nix fmt";
owner-corrected 2026-07-17); (2) **gen hub mkCi DUAL-GATE DIVERGENCE
(parked upstream item): `checks.default` = homegrown assertTests reading ONLY expr/expected — nix-unit's
`expectedError` UNSUPPORTED there (test throws escape → check build fails) while `nix-unit --flake .#tests`
(pre-commit hook path) supports it**; error-message content stays unassertable via the checks gate (lib-wide
tryEval convention re-confirmed). **STEP-2 PLAN APPROVED @815b180** (plans/2026-07-17-den-hoag-typed-edge-substrate-plan.md + .tasks.json, 8
serial tasks, 3 review iterations). Key review-established facts: parity oracle reads gen-edge's edgeSortKey
through the LIVE pin (oracle.nix:152) → T6's pin-bump ritual IS the oracle mapping, zero oracle edits;
kind-null-=-legacy adjudicated faithful to spec §6 (un-stamped constructors render byte-identically — no
enumerated legacy list anywhere); gen-edge needs kind on THREE surfaces (edge record + edgeSortKey +
trace.nix renderEntry — the second independent renderer); rule ctx today = entity bindings ALL-structural →
strata scoping = declared stratum→ctx-key-groups map seeded no-op, replaced-key NAMED throws (forceThrows-
catchable; attribute-missing escapes tryEval); boundary.nix coreFiles completeness guard + legacy/compat
forbidden-token scan constrain new core files (say "un-labeled" never "legacy" in core comments); demand
retirement = kind stamp on existing records ONLY (assembleEdges lands synthetic-only, zero live producers
this step). **═══ STEP 2 SHIPPED 2026-07-17: typed-edge substrate ═══** den-hoag main @4e98c98 PUSHED (12 commits) +
gen-edge main @d54ad86 PUSHED; suites gen-edge 102 / den-hoag ci 1018 / parity 71 BYTE-UNTOUCHED throughout;
papers @2782048 (spec §12 step-2 SHIPPED note). Landed: gen-edge optional `kind` (kind-null-=-unlabeled on
ALL THREE surfaces: edgeSortKey + traceEntryOf + trace.nix renderEntry; edgeSortKey/traceEntryOf now public);
lib/identity.nix (S1 formulas verbatim; S strict-by-contract, produced-values-never-in-S); den.strata.insert
compiled order + capability-scoped rule ctx (replaced-key named throws, PROBE STAYS RAW by design — probes are
sentinel-only, presence-gated); den.edges 9-kind registry (output stratum dogfooded, demand kind registered at
T7 — plan had an internal inconsistency, T7 registration ruled sound); den.overrides (raw-intent matching,
whole-value from/to, null≡absent, first-match single-step); assembleEdges (synthetic-only, ZERO live
producers); demand retired-by-extension (both toEdges arms stamped; ZERO golden diffs — corpus demand-free).
REFERENCE laws S1-S5. **REVIEW-ARC HIGHLIGHTS (durable):** the fill-graph QUOTIENT lesson — entityId-keying
introduced a probe-proven false positive on legal multi-instance fan-out (A1→B→A2); fix = instance-keyed
nodes + instance-discriminating refs (entity sugar iff-unique, ambiguous throws, literal instanceId refs
visible); the unconstructability premise (mutual instanceIds = infinite hash fixpoint) was CORRECT but the
quotient inference wasn't. **STEP-3+ FORWARD CAVEATS (in code+REFERENCE @4e98c98):** annotations.edgeId enters
trace entries → live producers put sha256s in goldens (double-ripple) — promote to first-class field or
recompute when read semantically; hook-scoping corollary (§2.1) rides "live-producer rewiring" implicitly
(receivers don't exist yet). PARKED (owner items): gen hub assertTests lacks nix-unit expectedError
(checks.default vs nix-unit dual-gate divergence); ~40 pre-existing "(Task N)" comment keys repo-wide need a
dedicated sweep; den-hoag main has pre-existing formatting drift (implementers revert around it — one fmt
sweep commit would end that). **═══ STEP 3 SHIPPED 2026-07-17: disciplines registry + fold-engine unification ═══** den-hoag main
@d2c5b23 PUSHED (13 commits) + gen-pipe main @debd089 PUSHED; suites gen-pipe 138 / den-hoag ci 1072 /
parity 71 byte-untouched throughout; papers @c604ef6 (3 den-hoag spec amendments + gen-pipe spec 7-site
E10 sweep). **DECLARE-NOT-REWIRE** (review-grounded verdict, spec §6 amended): the three fold sites
UNCHANGED; den.disciplines registry ({laws; empty; combine; dedup?; order?; engine?}, 4-rung ladder,
closure gate = registered join-semilattice) + property-law harness (per-rung lawful synthetics + teeth +
orphan-coverage teeth) + THREE framework instances (settings-layers/collections-neron/reach-closure), each
behind the **3-LEG PROOF CHAIN: law harness + order oracle + VALUE-AGREEMENT pin** (the standing instance
pattern — order oracles alone don't catch drifted-but-lawful combines). gen-pipe E10 → real semilattice-set
class (construction-defaults realization — which ARMED a latent gap: the old reserved-throw was lazy/INERT
on the fold path; toJSON key-equality caveat). Risk-register audit: all 7 goldens named + golden-index
inventory w/ teeth (delivery-order golden empirically toothed — ++ swap flips it RED). **REVIEW-ARC
LESSONS (durable):** the planned reach dedup key→id_hash migration was REFUTED VACUOUS (id_hash =
hashString "den-aspect:${key}" — a BIJECTION; Shape B path keys already de-collided) — §12's "reach
bare-string" = reach's EDGE identity (bare target string), port RE-STAGED to the substrate-consumption
step (spec §12 amended); combine references are SIBLING-honest (foldLayers vs production's
foldLayersTraced — value-pinned, not same-object); C-holds-up-to-key-set-quotient documented; Leijen
shadow HALF-CHECK precondition recorded (per-shared-key + disjoint-survival before any real shadow
instance). VOCABULARY PROGRESS: steps 1-3 of 6 SHIPPED (gen-graph query calculus / typed-edge substrate /
disciplines+fold). NEXT = step 4 (materialization facet: products/receivers/renders/output families/
collectors — the biggest step) then step 5 (resolution facet: relations/derived/fn — retires nix-config's
scope-engine) then step 6 (compat forwarding). [Step 4 subsequently DECOMPOSED + shipped through
4c-i — see the 2026-07-17 checkpoints below; the per-step pattern held.]

**[SUPERSEDED 2026-07-17 — the brainstorm COMPLETED: it became the unified link/merge vocabulary
spec (2026-07-16-den-hoag-unified-link-merge-vocabulary-design.md), ratified + shipped through
4c-i. Do NOT resume the seed doc; historical record only.] INSTANTIATION MODEL REDESIGN = the
LEAD arc (owner, 2026-07-16 — supersedes "Arc 1 leads").** Owner: instantiate
is too narrow (1 class→1 render→1 target); wants a general expressive model — NESTED renderings (hm/microvm) +
MULTI-TARGET (nixOnDroid/standalone) via COMPOSABLE VERBS. It TOUCHES home-manager class content materialization,
so #74/darwin/droid/standalone are CASES of it (design the model FIRST, don't point-fix then rework —
[[feedback_architecture_first]]). BRAINSTORM SEEDED (paused, ~7 forks open):
`plans/2026-07-16-instantiation-model-brainstorm-seed.md`. TWO forks DECIDED: (1) locus = GRAPH-NATIVE
(renders/nests/targets as edges/nodes in the projection graph); (2) verbs = **bind**(entity→inputs) /
**render**(→artifact, generalize crossVia + add crossHome) / **nest**(inner→outer, MODE = content-nest[modules
into outer eval, hm] | artifact-nest[rendered value into outer, microvm]) / **target**(→output family, make
intoAttr live). Subsumes back-burner #49 (native user/account, hm as integration module w/ host-embedded/
standalone/droid/darwin siblings) + #50 (declarable instantiation). Resume via the seed doc in a FRESH session
(brainstorm→spec→plan). Current model mapped in the seed (class=render unit; grain-ladder selects 1 evaluator
for 1 terminal call at output-modules.nix:840; nesting bespoke; systemOutputs generic but bridge half-mounts).

**★ MERGED TO MAIN 2026-07-16 — main IS the redesign + the WORKING TARGET (twin/branch/ulimit RETIRED).** The
projection redesign (Shape B + 6.1/6.2a/6.2b + verb-catalog docs) was rebased onto the ulimit/perf fix
(`aba81c4` "genPrelude.hasInfix; drop ulimit") + fast-forward merged to den-hoag `main @ 1fb0ab1` (PUSHED). The
twin fallback (`3ede207`) is RETIRED; the `feat/projection-graph` feature branch is RETIRED (== main). **Work
directly on `main` now.** `ulimit -s unlimited` NO LONGER needed (purity fix landed) — CI 951 + parity 71 green
plain. Run: `cd ~/Documents/repos/den-hoag/{ci,parity} && nix build .#checks.x86_64-linux.default -L`
(parity adds `--override-input den-v2 path:..`; NOTE the repo path is ~/Documents/repos/den-hoag —
an earlier note's repos/sini/den-hoag path does not exist). purity.nix OWED = DONE. Rebase auto-merged 6 files
(mergiraf + lock; gen-aspects rev `b19ca92` kept). [The 2026-07-16-resume-parity-reckoning.md pointer is
SUPERSEDED — the live resume doc is plans/2026-07-17-resume-step4cii-and-beyond.md.]

## ═══ 2026-07-17 — VOCABULARY STEP 4a SHIPPED (materialization registries + live dispatch) ═══
Step 4 (materialization) DECOMPOSED owner-ratified into 3 executing sub-plans: **4a registries+dispatch
(SHIPPED, den-hoag origin/main @3cc1651, 6 commits, ci 1130 + parity 71 byte-untouched)**, 4b nest-mode
execution (content/artifact/extend/value + provide/adapt/defer + singular arity), 4c root+families+
collectors+flake-parts adapter (anchor-oracled vs systemOutputs). Plan
`plans/2026-07-17-den-hoag-step4a-registries-dispatch-plan.md` rev3 (10 review findings incl. 2 blockers:
read-through overlay precedence + kind-include has NO v1 carrier). SHIPPED SEMANTICS: den.products/
den.conversions (§4.1 table; ArtifactRef prefix RESERVED; conversions unique BY KEYING — cross-module =
module-system unique-merge conflict, ruled sufficient); den.renders PER-FLEET compile inside mkDen
(evaluators close over den.nixpkgs/den.darwin; params ? [] not ["system"]); **D7 promotion COMPLETED by
DELETING defaultInstantiations** (quality-review-proven dead; precedence law classes.instantiation ≻
renders row ≻ nothing; equivalence = untouched-corpus anchor); den.kinds.<k>.receives.<slot> (F1 checked
law — user mode field throws; render artifact-only enforced; **includes lives on the KIND ENTRY** sibling
of receives — implementer-caught misparse of "the den.kinds.<k> row", both reviewers missed it, row-level
declaration now throws pointing up; kind named `kinds` reserved at entity discovery); THE DISPATCH = live
gen-graph visible query (where row-presence gate + constant groupBy both load-bearing; diamond node-dedup;
slot ≻ class fallback-on-EMPTY; **unanimous-multi rule** — mixed multiplicity on tied rows = named throw,
review-caught head-only read; only winners forced, reachable-but-shadowed poison witness). den-hoag
internal seam renamed graph→genGraph. REFERENCE "Materialization registries" section (132 lines). Papers
@2bc8e9a (spec §12 step-4 ship note w/ all clarifications). 4b note: mkReceiverResolver hoist seam if
per-edge dispatch profiles hot. Whole-arc review ✅ SOUND (zero fix-now; 3 notes carried to 4b:
live-wire resolveReceiver per nest edge, shape-only fields, cross-module conversions witness) —
recorded in the plan's completion section @9163420. NEXT = the 4b plan cycle. Loop pattern held: resumable impl-mat (amend-in-place, unpushed until
ship) + two-stage review + delta confirms; 2 plan ambiguities caught only at implementation contact.

## ═══ 2026-07-17 — VOCABULARY STEP 4b SHIPPED (nest-mode execution) ═══
**4b SHIPPED den-hoag origin/main @e9fc9fa** (6 commits, ci 1174 + parity 71 byte-untouched; ratified: NO
live nest edges — synthetic executors, live producers = 4c). Plan
`plans/2026-07-17-den-hoag-step4b-nest-mode-execution-plan.md` rev3 (adversarial review killed a CIRCULAR
anchor — content now pins the GRAFT vs the fold's own placeSlice/nestAtPath via authorized local twin, the
gather stays the fold's). lib/nest.nix: executeNest (structural-handles ctx, pinned 7-row contribution
schema, at = singular path []⇒flat payload-stripped), value verbatim + unrealizedCast marker, artifact lazy
render (face; null-face=eval-is-artifact), extend under extendsVia — REQUIRED relaxing 4a's render
artifact-only guard to artifact-OR-extend (adjudicated: spec says extendsVia-on-render 3×; REFERENCE
amended), conversions consult single-step at executor, provide both-arms-one-lazy-result, bindArgs
functionArgs-intersection, executeDefer INERT R6 record reconciled w/ shipped __configThunk (families
lowers or retires both — no third surface; `then` = Nix KEYWORD, quoted/dynamic only), checkSingular
(wiring, post-when, den.nest) + checkSingularDefinition (definition-time unconditional, den.kinds), full
laziness sweep + deepSeq-hardened ctx probe. entity artifact= = facet-category key in concern-aspects
keySemantics, buckets-empty law fired at the terminal gate beside §2.2 totality (adjudicated LOAD-BEARING —
pure-fn-only = vacuous witness). WHNF-only rider presence-gate ruling on record (row ? adapt would misfire:
compiled rows always carry null defaults). materialization suite 58→102. Papers @1814832+completion. Whole-arc review
✅ SOUND (zero fix-now; composition-level parity inertness verified; all 4c seams discoverable). NEXT = 4c: root entity + families + collectors + flake-parts adapter
(anchor-oracled vs systemOutputs), wires the live mount + nest-edge producers + deferred decisions
(unrealizedCast locus, defer lowering, provision/requires/params consumption).

**FLAKE-PARTS INTEGRATION DOCTRINE (owner-ratified 2026-07-17, spec §12 4c note):** NO-TRANSLATION
invariant — ecosystem flake-parts modules ride VERBATIM at every level; only den-side WIRING translates,
opt-in. L0 flake-parts root (mkFlake hosts den module, coexists); L1 den-owned flake HOSTS a flake-parts
eval as a render (mkFlake-as-library, isolated artifact eval, import-tree feeds it); L2 native wiring
where it pays (agenix-rekey template: nixosModules=aspect content, perSystem apps=hosted eval,
read-nixosConfigurations=COLLECTOR consuming members' SystemInfo / provide rider). Subtlety: hosted
eval's `self` = final outputs incl. its own contribution (lazy knot). 4c-iii grounding docket: hosted-eval
render + self knot; collector-consumes-systems; gen-flake re-scope survey (general output-crossing lib,
per-family terminals; flake-parts BESIDE not beneath).

## ═══ 2026-07-17 — VOCABULARY STEP 4c-i SHIPPED (root + output families + systemOutputs replacement) ═══
**4c-i SHIPPED den-hoag origin/main @8dd07e4** (6 commits, ci 1209 + parity 71; FIRST live-output-path
sub-plan, byte-identity anchor HELD). den.outputs.<family> registry + den.systems axis; ROOT = framework
kind, families = its receives rows through the REAL dispatch (knownKinds ++ ["root"], two-vector reserved
throws); built-ins promoted per-fleet via instantiationOf (overlay preserved); the LIVE family mount =
value-arm verbatim injection through resolveReceiver+executeNest; **familyOutputs == systemOutputs proven
then the OLD TIER DELETED** (promote-then-delete #2; byte-identity triad = direct face pin + untouched
corpus + parity-71 source proof); requires definition-time (available=[consumes]++render.produces;
conversion-aware = 4c-ii note) + params fan (fanParams = pre-wired 4c-ii seam) + entity opt-in declaration
(elaboration record; edge emission = 4c-ii). **SETTLED: gen-schema native kinds STRICT by default** — a
plan-reviewer freeform claim FALSIFIED at implementation contact (misread the non-strict compat registry);
the §4.4 surface required a framework-declared universal `outputs` option per kind (raw, identity-neutral).
Papers @6a0019a+completion. Whole-arc review ✅ SOUND (zero fix-now; stricter face→receivesTable
forcing noted; twin consolidation opportunity; all 4c-ii seams discoverable). NEXT = 4c-ii (live mount for NEW nest edges +
producers + edgeId promotion + defer lowering + unrealizedCast locus + conversion-aware requires +
user-family materialization) then 4c-iii (collectors + flake-parts adapter under the integration doctrine).

**GENERICITY MANDATE (owner 2026-07-17, binding 4c-iii, spec §12):** nix-config = PARITY oracle only, NOT
the design oracle — the design oracle is the ECOSYSTEM pattern range. 4c-iii grounding's first-class
deliverable = ecosystem pattern CENSUS → genericity test matrix (synthetic witnesses). Coverage floor:
3 adapters over 1 family surface (flake-parts/plain-flake/pure root); nixosModules-EXPORT family (content
mode, no render/axis — the inversion witness) + overlays/lib/templates params=[] class; USER-DECLARABLE
axes (beyond ["system"]: pkgsCross build≠host, variants, workspaces, multi-cluster); collector
member-record genericity (deploy-rs/Hydra/nixosTests beside colmenaHive — no colmena field leaks into the
kernel contract); a stylix/sops-nix-shaped cross-cutting witness (one declaration spanning nixos+hm).

**RESUME DOC (2026-07-17 session close): papers plans/2026-07-17-resume-step4cii-and-beyond.md** — the
cold-start map for the next session: deliver 4c-ii (live producers, most parity-sensitive) → 4c-iii
(collectors+adapter under BOTH doctrines) → plan steps 5/6 → brainstorm the successor project (candidates:
nix-config native migration, den v2 public release/#43, gen-flake re-scope, deferred infra). Contains the
full operating loop, binding conventions, caught-error classes, and every carried seam.

## ═══ 2026-07-17 — VOCABULARY STEP 4c-ii SHIPPED (live mount + nest-edge producers) ═══
**4c-ii SHIPPED den-hoag origin/main @43954a8** (7 commits fe702a2..43954a8, ci **1236** + parity **71**
byte-identical every rung; whole-arc review ✅ SOUND — cross-task seams + cumulative parity honesty +
REFERENCE-vs-code all verified at the final tree). The MOST parity-sensitive sub-plan (first to touch the
edge-trace domain), held byte-identity by CONSTRUCTION. Plan+completion:
`plans/2026-07-17-den-hoag-step4cii-live-mount-producers-plan.md` (+ .tasks.json). Spec §12 4c-ii ship note
@c4c6bf5. **Three OWNER fork rulings (spec §12 (1)-(4)):** (1) producers CORPUS-INERT/synthetic (family mount
stays the direct familyOutputs fold; corpus emits no new nest edge); (2) edgeId promotion = the intent's
readable `id` as the keyedValue SOURCE key (annotations.edgeId retired, identity.edgeId recompute-on-read, NO
gen-edge change); (3) `den.axes.<name>={values}` + full multi-axis fanParams cartesian (system reserved);
(4) opt-in payload = `classSubtreeAt "<kind>:<name>" contentClass` at ROOT scope + a NEW nullable
`contentClass` family-row field. **Three IMPLEMENTER-CAUGHT forks (each resolved before RED — the stop-and-flag
discipline):** T2 materialization VEHICLE (plan left it unpinned → substrate record via polymorphic
assembleEdges + executeNest content-arm graft, NO bypass; the two-view disjointness mirrors the family mount;
gen-edge whole-list materialize NEVER the content path); T3 opt-in PAYLOAD source (spec/REFERENCE silent →
owner ruling (4)); T6 the defer FINDING — decision #27 resolve-at-producing-scope is ROUTING to the producing
terminal (gen-bind resolveThunks reads the RESOLVING module's config; `__sourceScope` is a MARKER the routing
keys on, NOT a config selector) → the `__sourceScope`-indexed config-map (Option 2) REJECTED as over-reach;
live routing = the step-6 retire-into-one. SHIPPED surface: intent `{id;kind;from;to;data?;when?}` + idless
NAMED guard; assembleEdges POLYMORPHIC mode/path (merge byte-identical, nest = substrate citizen with the
(T,P,S,M,K=nest) trace key); nestProducer/containmentPairs (emit iff resolveReceiver{outerKind=parentKind;
slot=childKind;class=childClass} non-null — corpus receives-only-on-root ⇒ set [] by construction) +
checkSingular-at-mount; opt-in → LIVE ARTIFACT-mode family edge (guarded optIns!=[], classSubtreeAt root scope,
single-instance — cell hm content deferred to steps 5/6); conversion-aware requires (single-step, reads compiled
.from/.to); defer lowering onto __configThunk (bind-free adapter in nest.nix + lowerDefer/mkThunkFrom in
output-modules.nix); unrealizedCast serializable `{from;to;slot}` (row dropped, to==consumes). DURABLE: T1's
idless case + T4's malformed-axis are DEFINITION-TIME NAMED guards (bare attr-miss is tryEval-UNCATCHABLE — the
RED-inversion pattern); den-hoag commit SIGNING needs the configured key loaded (owner ran `ssh-add` at T1;
`${PIPESTATUS[0]}` is bash — zsh gate-exit capture needs `$?` right after the build, not a pipe). CARRIED to
4c-iii: shared `place` primitive extraction (3 nestAtPath + 2 placeSlice twins stay SEPARATE — deferred by
plan-review); "family-members sugar" unnamed in the REFERENCE Forward; the ~40 pre-existing "(Task N)" comment
keys = a separate parked sweep (the arc introduced ZERO). **NEXT = 4c-iii** (collectors + family-members sugar +
flake-parts root-kind adapter, under the FLAKE-PARTS INTEGRATION DOCTRINE + the GENERICITY MANDATE) → plan
steps 5/6 → successor brainstorm. Resume doc plans/2026-07-17-resume-step4cii-and-beyond.md still current
(ARC 2 onward).

## ═══ 2026-07-17 — 4c-iii DECOMPOSED + WS-MODE (sub-arc A) SHIPPED ═══
4c-iii grounding (ground-4ciii) found it is THREE loosely-coupled workstreams + a gen-flake dependency, NOT
one flat sub-plan. TWO settled facts: the family ROW surface (`{at;consumes;render?;params?;requires?;
contentClass?}`) is ALREADY ecosystem-generic (the census PROVED flake-parts-transposition / plain-flake /
bare-root all express through the SAME row — the adapter difference is the root kind + render, NEVER the row;
census floors 1+4 PASS); and the SELF-KNOT is tractable — flake-parts does NOT tie the fixpoint, it leans on
Nix's own lazy flake-`self` (lazy-knot proof: a hosted module reading `self.<family>.<sibling>` resolves +
terminates, eager tie loops). The gaps are all in the MOUNT + render-evaluator + the missing collector kind
(G1-G5), not the row. **OWNER-RATIFIED decomposition (spec §12 @65b528c):** 3 sub-arcs each its own cycle —
**WS-MODE** (mount mode-completeness + axes; FIRST) / **WS-COLLECTOR** (den.collectors concern + members
sugar + selector membership + HiveInfo producer) / **WS-FLAKEPARTS** (self-knot + hosted-eval render +
FlakeInfo + adapter beside bridge.nix). Fork rulings: gen-flake = THIN mkFlakeTerminal slice now, full
output-crossing re-scope its OWN later arc (den consumes only mkSystemTerminal); collectors = a NEW
first-class `den.collectors.<name>` concern (§4.7). Orchestrator-decided: axis rides specialArgs (no
gen-flake arity change); 11-row census sufficient; members desugar mirrors opt-in; §2.3 "collection" vs
shipped `resolution` stratum = docs-reconcile.
**WS-MODE SHIPPED den-hoag origin/main @e4c29be** (4 commits over 4c-ii's 43954a8: 6bd85c1 content mount /
e8d201b axis→specialArgs / b60823f extend families / e4c29be REFERENCE; ci **1243** + parity **71**
byte-identical every rung; whole-arc review SOUND — 4-arm placedValue composes 1:1 with mode dispatch, parity
cumulative, REFERENCE faithful). Plan+completion plans/2026-07-17-den-hoag-step4ciii-a-mode-completeness-plan.md.
The family MOUNT (familyOutputs/placedValue) is now MODE-COMPLETE over all 4 modes (was value+artifact):
CONTENT arm — a content family's face = SINGLE module `{ imports = <raw slice> }` from the RAW un-placed
classSubtreeAt payload placed ONCE (executeNest content arm gained a `raw` field beside its placeSlice-placed
`modules` — avoids the double-placement; nixosModules-EXPORT inversion witness + overlays/lib/templates
params=[] + stylix/sops-nix cross-cutting); axis→EVALUATOR — the render-arm evaluator ALIGNS to gen-flake's
`{modules;specialArgs}` terminal contract with `specialArgs = removeAttrs ctx.paramPoint ["name"]` (the fanned
axis point) so multi-axis renders see their tuple; EXTEND families — rowOf relaxed artifact-OR-extend
(mirrors receivers.nix), placedValue extend arm `c.extended` reuses the 4b extend arm. **`provision` LEFT
SHAPE-ONLY** — §R3's full provisioning record (pkgs/system/specialArgs/charts) is a dedicated LATER arc,
NOT half-wired (the no-half-measure choice was to NOT half-wire it; delta review caught the first fix
mis-modeling §R3 provision as a specialArgs producer). CORPUS-INERT by construction (corpus declares no
content/multi-axis/extend family; optIns==[] → direct value-fold not placedValue; value-mode built-ins never
hit the artifact arm; class-instantiation terminal UNTOUCHED). Plan-review value: caught 2 blockers +
CONFIRMED the T2 byte-identity trap SAFE by code (corpus never reaches the family artifact arm; class
instantiation via crossVia/terminal.nix) BEFORE any code. **NEXT = WS-COLLECTOR** (HiveInfo producerless =
the clean seam) → WS-FLAKEPARTS → gen-flake full re-scope → steps 5/6 → successor. DURABLE: T1's idless/T4
malformed-axis/content RED = eval-CRASH (tryEval-uncatchable → observe raw, don't wrap in throws); §R3
provision is a RECORD not a specialArgs producer (don't half-wire).

## ═══ 2026-07-18 ★ 4c-iii COMPLETE — the whole §4 materialization vocabulary SHIPPED ═══
UNIFIED ROADMAP = papers plans/2026-07-18-den-hoag-unified-roadmap.md (single-source state: 3 sub-arcs +
the forward roadmap). All three 4c-iii sub-arcs shipped, each parity-71 byte-identical every rung, per-task
two-stage + whole-arc reviewed: **WS-MODE** (@e4c29be, mode-completeness) + **WS-COLLECTOR** (@b74b247,
6 commits ci 1281 — collector concern + hasClass + aggregate render→HiveInfo + members sugar + SystemInfo
genericity; SHIPPED+PUSHED) + **WS-FLAKEPARTS** (den-hoag origin/main @7e4b8bc 8 commits [incl pin-bump] plain ci 1297 / gen-flake
origin/main @90960ad mkFlakeTerminal — hosted flake-parts render + FlakeInfo + the self-knot [spine-self-independent,
Case-A/B, independently proven] + at=[] transposition + 3-adapter genericity floor + NO-TRANSLATION +
den.flakeAdapter [COEXIST v1 bridge] + the L2 collector-fed template [fragile self.nixosConfigurations
self-read → an explicit typed edge]; TWO-REPO push 2026-07-18). KEY PROVEN: the render-evaluator SEAM =
stub→real gen-flake mkFlakeTerminal is a 1-LINE evaluator swap (gen-flake re-scope reclaim trivial);
override-gated real-flake-parts witnesses while parity stays PLAIN-green (ship-gate never depends on the
unpushed dep) → pin-bump at ratified push. NEXT (owner-chosen 2026-07-18): **spec steps 5/6** (5=Resolution
facet [relations/derived/fn methods; acl+settings]; 6=Compat forwarding [v1 lowering; parity ladder]).
QUEUED own-arcs: L2-EXTRACTION (promote the now-stable kernel to gen-tier; candidates = shared
place/freeformProbe primitive [5× dup], conditional value-cartesian, render-declares-member-input) +
gen-flake RE-SCOPE ([[project_gen_flake_rescope]], de-risked — inherits the member-map→FlakeInfo aggregate
contract) + successor brainstorm. Detail: spec §12 ship notes + the unified roadmap.

## ═══ 2026-07-18 ★ STEP 5 (Resolution facet) — 3 of 6 sub-arcs SHIPPED ═══
Owner-ratified decomposition: 6 sub-arcs, spine-first, each its own grounding→forks→plan→adversarial-review→
resumable-impl(two-stage-per-task)→whole-arc-review→push cycle. Owner STANDING GO (push each as it clears
whole-arc review, outcome-first, NO per-arc re-ask). Fork rulings R1-R7 (R5 owner: design endpoint-id in 5,
DEFER the reach PORT to 6; R7 owner: den-hoag registrations + synthetic witnesses in-scope, nix-config
repoint downstream). **WS-QUERY SHIPPED+PUSHED @c8eb529** (3 commits, ci 1314 / parity 71): `den.query` = the
§3 calculus over a SUPPLIED source-agnostic edge list, ZERO gen-graph change, dependency-free (F1 where=raw
node→bool, F6 supplied source); the ONE build = `perLabelFromEdges`; the two-graphs footgun navigated (outer
gen-graph engine has .query, inner gen-edge graphEscape doesn't). **WS-RELATIONS SHIPPED+PUSHED @876c817**
(den-hoag origin/main c8eb529..876c817, 6 commits, ci 1340 / parity 71; whole-arc APPROVE w/ forced re-eval +
end-to-end integration fleet): the `den.relations` resolution graph — registry desugars to den.edges@resolution
(★AUTO-CREATE **label-only** inverse = metadata, NO second kind, spec-faithful §5:417/§2.2:151; closure=false
gate no-op; single label-collision guard over {relation names}∪{non-null inverse labels}) → entity `.edges.<rel>`
field (per-kind raw option) + fleet-level undeclared-relation guard (value-returning `edgesRelationMessage`) →
flat `den.relationEdges` producer (memberProducer twin OFF edgesForRoot, plain-string {id;kind;from;to} endpoints
[den.query string-compares], ref→node-id lowering via reused `entityKindOf` id_hash index, SWAPPED inverse edge,
guard WOVEN onto the producer via seq) → `relQuery` (sel→matchId where-adaptation, the shared `matchIdStructural`
= the WS-QUERY-deferred piece) → `ctx.rel`/`den.relAt` per-node accessor {targets;inverse;closure;paths}
(mkNarrowAccessor posture; ★closure transitivity = the `+` one-or-more regex WALK + fixpoint FOLD through a
concrete set-union monoid — gen-graph fixpoint FOLDS queryAll's result, does NOT iterate, proven by review
probe). CORPUS-INERT by construction. TWO step-6 DEFERRALS (R5 posture): assembleEdges STAMPED-ID unification
(w/ reach edge-id) + registry closure CAPABILITY + set-union DISCIPLINE law-gating (WS-ACL consumer). LAYERING:
per-node `ctx.rel` BINDING not yet wired — ships as fleet-level `den.relAt` (aspectsAt precedent); WS-DERIVED/
WS-ACL/WS-FN build ctx.rel on top. **WS-DERIVED SHIPPED+PUSHED @aed1044** (den-hoag origin/main
876c817..aed1044, 6 commits, ci 1370 / parity 71; whole-arc APPROVE w/ forced re-eval + a 9-assertion
integration fleet): `den.derived.<name>={over;direction;stratum;provides;discipline?;closure?;derive}` = a
laws-gated synthesized attr, **Fork A (owner)** = a FLEET-LEVEL LAZY per-node accessor `den.derivedAt <name>
<nodeId>` keyed on scope-node id, NOT a resolve.attr equation (the relation graph it reads is fleet-level
post-eval; **R6 confirmed** = key scope-node-id, instanceId=output-placement fingerprint). ★ this arc LANDS the
per-node `ctx.rel` BINDING (`node.rel = relAt id`). 7 definition-time field guards (value-returning detectors,
CI-testable NAMED): a over∈relations / b reverse-only-over-inverse-bearing / c stratum∈order / d stratum
strictly-LATER-than-over-strata §2.3 / e provides∈products / f closure=true⇒registered-JSL-discipline via the
SHARED `closureMessage`/`closureGate` EXTRACTED from edges.nix entryOf [behavior-preserving byte-identical, ONE
source of truth §2.2, reach-closure JSL witness, subject-param for the locus] / g derive-presence [the
unknown-name + missing-derive uncatchables both NAMED]. node capability-scoped by a STRATUM-GATE (§2.3,
projectCtx throw-on-read mirror: node.rel exposes only kinds at strata strictly BELOW the derive's; ≥-read →
NAMED throw). CORPUS-INERT (greenfield + extraction byte-preserving). DEFERRED to WS-ACL: set-union discipline +
AclInfo product + aclClosure demonstrator + the deps/requires→provides VALUE-composition (deps=throw-on-read
placeholder, provides validated-not-resolved). Fork A ratified via AskUserQuestion (spec-'shadow-graph node' vs
fleet-post-eval reality). plans/2026-07-18-den-hoag-step5-{a-wsquery,b-wsrelations,c-wsderived}-plan.md.
**NEXT = WS-ACL — PLANNED + CLEAR-TO-DISPATCH** (plan 2026-07-18-den-hoag-step5-d-wsacl-plan.md, adversarially
reviewed [no pillar falsified; 1 important + 4 minor applied], execution DEFERRED to next session per owner
wrap-up). ★ OWNER REFRAME 2026-07-18: ACL over-indexes on nix-config's memberOf/group/reverse-closure model →
WS-ACL builds the GENERAL relation-AGNOSTIC resolution-facet capstone, NOT the ACL system: (1) a USER `set-union`
join-semilattice discipline (R2, first non-framework instance = the user-extension witness); (2) a SEPARATE
`den.resolutionProducts` registry (fork-c=b, resolution-facet payloads, materialization products.nix untouched);
(3) the general capability-scoped `node.query` primitive (F-QUERY=CHOICE-STRATUM: a den.query over
den.relationEdges scoped to strata<the derive's, matching node.rel → NO rel/query asymmetry; capability-AIRTIGHT
[denQuery closed over its supplied edge source, proven]; ★falsified my assumption that node.rel.closure was
reverse — it's FORWARD, so the reverse transitive closure ACL needs required the general query primitive);
aclClosure = ONE non-privileged witness + a SECOND non-ACL witness proves agnosticism. deps stays deferred
(no witness composes deriveds). Resume doc: plans/2026-07-19-resume-step5-wsacl-and-beyond.md. ∥ **WS-SETTINGS**
(corpus-HOT cascade relocation → contains* layers query + declared tier, refactor-under-parity, unblocked by
WS-QUERY) → **WS-FN** (`.fn.<method>`, retire schema-side domainFor). Then step 6 (Compat: consumes step 5;
the R5 step-6 deferrals = assembleEdges stamped-id + reach edge-id + the deps value-composition). Detail: spec
§12 item-5 + unified roadmap.

**═══ WS-ACL SHIPPED+PUSHED 2026-07-20 @87cffb5 ═══** (den-hoag origin/main aed1044..87cffb5, 5 commits,
ci 1378 / parity 71; whole-arc review SHIP w/ forced re-eval + a fresh 3-relation/2-inverse-label integration
fleet). **STEP 5 now 4 of 6 sub-arcs SHIPPED** (WS-QUERY @c8eb529 + WS-RELATIONS @876c817 + WS-DERIVED @aed1044 +
WS-ACL @87cffb5). The GENERAL relation-agnostic resolution-facet capstone (owner reframe held — ACL is ONE
non-privileged witness, not the system). Delivered per the 5-rung plan (each rung RED-first TDD + per-rung
two-stage review + amend-in-place): **T1** `set-union` = the FIRST user join-semilattice discipline
(append-then-membership-dedup, overlap-closed property-laws sample; guard-f is name+laws only, no framework
privilege) @772b78f. **T2** `den.resolutionProducts` = a SEPARATE registry (fork-c=b), guard-e validates a
derive's `provides` against it not den.products; materialization products.nix BYTE-UNTOUCHED; cross-facet
(SystemInfo-as-provides) throws NAMED. Review TRIMMED the dead empty-seed reserved-name check (precedent: the
guard lands WITH the framework names it protects) + dropped 2 unconsumed exports @cff28dd. **T3** `node.query` =
the stratum-scoped §3 query on the derive `node` handle (F-QUERY=CHOICE-STRATUM: source = den.relationEdges
filtered to strata STRICTLY BELOW the derive's; capability-AIRTIGHT — `args // { edges = scopedEdges; }` rightmost
wins so a caller can neither widen NOR narrow, proven both directions; ★ the landmine: `relationStratumOf` TOTAL
over BOTH edge arms via an inverse-label→relation index — swapped `kind`=inverse-label ∉ relationKinds, a naive
lookup = tryEval-uncatchable `attribute 'members' missing`, RED-tested) @b970b2e. **T4** two witnesses proving
relation-agnosticism: `aclClosure` (reverse `members+` closure, swapped arm, provides AclInfo) + a forward
`dependsOn+` closure (forward arm, non-membership, provides DepInfo); set-union algebra INLINE in `combine`
(discipline= is the guard-f DECLARATION only — derive gets node/deps, never the disciplines table; proven via a
MARKER-combine probe) @81721ca. **T5** REFERENCE §5 capstone doc + the guard-f comment marked delivered @87cffb5.
The ctx.rel binding (WS-DERIVED) + node.query (WS-ACL) sit beside each other on the node handle. deps STILL
deferred (throw-on-read; no witness composes deriveds). Latent note (whole-arc, for record): indexOf-returns-(-1)
on stratum∉order is UNREACHABLE — all relations forced to `resolution` stratum. **NEXT = WS-SETTINGS ∥ WS-FN**
(WS-SETTINGS = corpus-HOT cascade relocation → contains* layers query + declared tier feeding the shipped
resolveAll fold, R3 minimal, unblocked by WS-QUERY, NOT yet grounded/planned; WS-FN = `.fn.<method>`, retire
schema-side domainFor) → then step 6 (Compat, consumes step 5). impl-4cii ran all 5 rungs (SendMessage-resumed;
its stop-and-flags + the inverse-label landmine caught early). Resume doc: plans/2026-07-19-resume-step5-wsacl-and-beyond.md.

**═══ 2026-07-20 THE PRODUCTIONS SUBSTRATE PIVOT (supersedes WS-SETTINGS narrow framing) ═══**
WS-SETTINGS grounding falsified the roadmap ("lower the cascade to a contains* query" — but the dominant layer
source is a product-powerset lattice, NOT a graph walk; parity-71 doesn't even cover settings, ci-1378 does).
Owner reframed UP repeatedly (reject pragmatism/YAGNI; pre-ship = the window for breaking changes): settings +
the nix-config claim/provide engine are the SAME shape → **den-hoag's resolution facet re-founded on a "productions"
substrate = stratified Datalog with LATTICE-valued predicates** (disciplines ARE the lattices; Datafun/Flix). ONE
primitive `den.productions.<name>={stratum;from;emit=edges|attr|nodes;to=query|materialize|both;discipline;mode}`
subsumes relations(EDB)/derived(attr)/settings(ordered-fold)/claims(cascade). Owner chose **C = full unification,
no half-measures, born-general-built-to-witnesses**.
- **THEORY SETTLED**: workflow wf_dd14e3c9-5b2 (11 agents, SOUND_WITH_REFINEMENTS + 5 registration laws: B1 stratum-
  scoped reads/B2 per-production strata/mode=fixpoint⟹JSL+ACC/stratified-negation-throwing-gate/bounded-NTA guard)
  + research-confluence (cascade terminating+confluent: Datalog-fixpoint + Newman; F-a EDGES-ONLY safer [node-spawn=
  value-invention/chase]; ordered-monoid confluent only w/ total order [A12]; ACC-as-registration-law) + an
  independent adversarial spec-review (no reopened fork).
- **★ ENGINE = EXTEND gen-resolve — NOT a new lib** (corrected via engine-stack + all-21-gen-lib grounding after the
  owner's sharp naming Q). gen-resolve ALREADY IS the demand-driven stratified-fixpoint conductor with the emit
  vocabulary: `attr`(equation.nix:46) / `nta`(=bounded-NTA Vogt'89, :65) / `cascade`(:80) / `reference`; the loop
  (cold+warm, lib.fix lazy memo, resolve.nix:47); N-stratum `buildSchedule`. gen-fixpoint would be ~85% dup.
  Compose gen-graph(query/reachability/transpose) + gen-product(coords) + gen-algebra(foldLayersTraced). Absorb
  gen-demand INTO gen-resolve via **nta+edge** (naming trap: gen-demand's SPAWNING cascade ≠ gen-resolve's
  layer-folding cascade). Reverse read already shipped 3× (transpose/queryReverse/reference) — retire den-hoag's
  label-swap hand-roll.
- **★ THE DEBT (drives Phase 1)**: den-hoag's SHIPPED WS-RELATIONS/DERIVED/ACL are a HAND-ROLLED SECOND EVALUATOR
  beside gen-resolve (flat relationEdges+denQuery, inline indexOf-strataOrder/scopedEdges/gatedRel in mkDerived,
  deps=throw-placeholder — all reimplementing gen-resolve.reference/attr/nta). §6's "eager fold driver + thunk
  fact-store" was WRONG = re-inventing gen-scope's lazy memo (self-inflicted A17). Owner directive: **FIX+DELETE the
  duplicate FIRST** (migration Phase 1, its own review-gated arc) before any new feature, so nothing builds on it.
- **NET-NEW (tiny)**: gen-resolve {JSL/ACI admission (lift the semilattice-set rejection equation.nix:88-89, ACC-
  gated) + N-way strata (schedule.nix:39-50 2→N) + the 5 laws}; gen-product `latticeGraph` accessor (~1 file on
  chain.nix, = feature #2 matrix engine); den-hoag `to=` projection tag (relationEdges-off-trace parity seam) + the
  re-founding. Reachability-closure lattices now; a semiring recurrence = one addable `from` source-kind away (not
  foreclosed). SPEC: papers specs/2026-07-20-den-hoag-productions-substrate-design.md (06f47c0→4b32e6d→ee5e53c).
  Migration: **P1 de-dup collapse onto gen-resolve** → P2 N-strata → P3 JSL disciplines+laws+`to=` → P4 latticeGraph
  ∥ → P5 witnesses (settings then claim/provide).
- **★ P1 PHASE-1 (re-founding) SHIPPED 2026-07-20, main @52b01a9** (ff-merge; worktree removed, branch deleted).
  Plan `plans/2026-07-20-den-hoag-productions-phase1-refound-plan.md` (5 tasks T1-T5, executed via executing-plans).
  Behavior-preserving STRUCTURAL refactor = deleted the SECOND delivery-context: `den.relAt`/`den.derivedAt` were
  TOP-LEVEL per-mkDen closures beside `structural.eval` (OUTSIDE gen-resolve's schedule/warm-serve) → now two
  resolution-stratum `resolve.attr` records `rel-accessor`/`derived-accessor` in the ONE equations map (NEW
  `lib/attributes/resolution-relations.nix` wraps the UNCHANGED `mkRelAccessor`/`mkDerived` bodies). Both exposures
  read one scheduled warm-served eval (`structural.eval.get id …`). `declaredEdges` populated soundly from relation
  endpoints (GAP-2, conservative all-endpoints over-declaration; feeds only warm-serve/DP3-DP4, observably inert on
  ci/parity). **FILES-DISAGREE FINDING (recorded in plan+spec §11):** `relQuery` STAYS a fleet-global helper (param
  by `from` not per-node; its `whereFor=matchIdStructural` is a shared final-eval consumer like aspectsAt, NOT a 2nd
  evaluator; folding it = a function-valued attr violating "attribute value is inert data"). derivedAt indexing = ONE
  map-valued attr (mapAttrs over derivedTable, lazy per name), unknown-name NAMED throw at the exposure guard. ci
  1383/1383 (+5 resolution-refound), parity 71/71, nix fmt idempotent.
- **★ P2 N-STRATA SHIPPED 2026-07-20** — gen-resolve main @`cf2d2ff` (pushed), den-hoag main @`2fcfeef` (pushed).
  Plan `plans/2026-07-20-den-hoag-productions-phase2-nstrata-plan.md` (7 tasks T0-T6, subagent-driven, each rung
  spec+quality two-stage-reviewed; independent plan-review = EXECUTE-WITH-FIXES, B1/B2/M1 applied). **gen-resolve**:
  `schedule.nix` 2-way DP1 assert → positional N-way rule over declared `strataOrder` (index0=base; violation iff
  `pos(b)>pos(a)`; `terminal` sink-exempt; unknown-stratum guard); `scheduleWith {equations,strataOrder}` +
  `buildSchedule`=default-order back-compat shim; `resolve` threads+seals `strataOrder`; both warm-serve hardcodes
  (`resolve.nix trackedAttrs` + `override.nix trackedFor`) → `!= head strataOrder`; single-source
  `schedule.defaultStrataOrder`; 66/66. DP1 = Apt-Blair-Walker 1988 (positive-dep ≤own) + vanAntwerpen 2016 §4.3.
  **den-hoag**: `runResolve` threads `compiledStrata` as `strataOrder` (INERT today — den eq set only uses
  structural/resolution/collection, partition identical; warm-serve set gains 4 collection attrs but verified-benign,
  gates never call warm/override); `strataChain {after,chain}` §B2 on `den.declare` = maps claim precedence
  (route>db>secret>connect, base-ward-ascending) to dense strata.insert chain (Phase-5 claim/provide consumes it);
  ci 1387/1387, parity 71/71. Default `[structural resolution]` reproduces shipped 2-way byte-for-byte.
  **LOCKFILE NOTE**: bumping the pin needs root + ci/ + parity/ flake.lock (nested flakes carry own transitive
  gen-resolve; ci input=`den-hoag`, parity input=`den-v2` — override/update paths differ). gen-resolve clones at
  `~/Documents/repos/sini/gen-resolve` ([[reference_gen_repo_clone_location]]).
- **★ P3 LAWS SHIPPED 2026-07-21 (3-repo arc, all pushed)** — gen-algebra main @`378a565`, gen-resolve main
  @`0ef3617`, den-hoag main @`32c869b`. Plan `plans/2026-07-20-den-hoag-productions-phase3-laws-plan.md` (12 tasks
  T0-T10, subagent-driven; each rung spec+quality two-stage-reviewed; independent plan-review EXECUTE-WITH-FIXES,
  all 5 blockers firmed incl. the 3-repo split). **THE 5 §8 REGISTRATION LAWS** at the registration/schedule layer
  (owner scope: NO premature `den.productions` user surface — that + the witnesses = P5): **L1** `edgesBelowStratum`
  + `ceilingGate` extracted from mkDerived into NEW `lib/stratum-scope.nix` (accessors take `ceiling ? null`;
  behavior-preserving); **L2** per-relation strata — each relation a distinct `rel:<name>` stratum inserted
  `after="structural"` (relations = EDB, bottom-pinned per §5 — NOT after="resolution", which lex-races the shipped
  `closure` derives; parallel compileStrata inserts NOT strataChain), `rel:` namespace reserved, strictly-below reject;
  **L3** `acc` discipline slot (join-semilattice ⇒ acc=true free, else declared) + closure gate JSL∧ACC (shared
  closureGate, new message so regex tests unbroken); **L4** `den.derived.<n>.negates` contract (negated read via
  throwing node.rel not silent node.query; negating derive strictly-above producers — ABW stratified negation);
  **L5** bounded-NTA `emit=nodes` guard (NEW `lib/production-guard.nix`, 4 clauses, fully synthetic — Phase-5 dedup
  seam). Plus **JSL/ACI admission** in gen-resolve (lift equation.nix semilattice-set rejection, ACC-gated, on
  gen-algebra's new `semilattice-set` foldLayersTraced ACI strategy); **`to=` projection tag** (kind-level on
  den.edges: relation kinds → query off-trace, else materialize; materialize filter parity-INERT since relation
  edges are a separate pool never in edgesForRoot); **label-swap → per-kind `gen-graph.transpose`** retirement
  (forward edges reversed+relabeled; relationEdges keeps the inverse edges but transpose-derived not hand-swapped;
  NB dedup asymmetry — inverse set-deduped, forward not, divergent only for malformed dup-target .edges). ci 1441,
  parity 71 EXACT off the real pins. Two design tensions surfaced+resolved by implementers: rel-accessor ceiling=null
  (accessor shares resolution stratum with its relations; gating is the consumer/derive's job), and relations=EDB
  bottom-pin. **NEXT = P4** gen-product `latticeGraph` accessor (feature #2, ~1 file, independent/parallelizable) ∥
  then **P5 witnesses = settings native + claim/provide native = the nix-config-DECOUPLING payload** (sheds the §3c
  compat splice) → step 6 Compat.

## ═══ 2026-07-21 P5b SHIPPED — the PRODUCTIONS SUBSTRATE arc COMPLETE through P5b (STATUS.md authoritative) ═══
P4 (gen-product `latticeGraph` @a2914e7) + P5a (den.productions surface + settings Witness 1 @3209be7) + **P5b
(claim/provide Witness 2)** all SHIPPED. **P5b: den-hoag main == origin/main @`af2d7b3`** (9 commits ff-merged off
3209be7, owner-approved 2026-07-21, ci **1571/1571**, den-only, whole-branch review = SHIP). Proves spec §10 Witness 2
natively expressible — ONE general engine, ZERO per-witness bespoke code, **NO parity bar** (owner: pre-ship synthetic
witness; the claim engine was DESIGN INSPIRATION never in nix-config; nix-config build OUT OF SCOPE — prove native
expressibility via synthetic tests). Built T1-T6, each rung two-stage-reviewed (opus impl + opus spec + opus quality),
resumable-teammate feedback loop, + a whole-branch final review:
- **T1 grew `den.productions` vocab**: emit∈{attr,edges,nodes}, `compile`→`{equations;claimEdges;claimKinds}`, off-trace
  claim pool appended to `den.relationEdges` (`to="query"`), cascade+fixpoint NAMED-rejected, `__spawn` reserved.
- **T2 edge-uniform EDB leaf claims** (`lib/concern-productions.nix` `claimEdgesOf`): from=∅ EDB purity via throw-on-read
  stub self; per-fact kind/stratum; cyclic connect (arr↔prowlarr) = two facts at ONE acyclic stratum; claim strata via
  `strataChain{after="structural"; chain=[connect secret database route]}`.
- **T3 (GAP-3 CRUX) `lib/attributes/claim-accessor.nix`**: `genGraphLib.transpose` reverse-read "who-claims-me" (NOT
  `scope.queryReverse` — hardwired to scope "imports", can't gather a claim pool; the stashed `reference{neededBy}` plan
  was WRONG, corrected at design time). `.query` SILENT + `.rel` THROWING (the L4 gate); readsAttrs=[] static pool;
  provider/consumer read it INTRA-stratum (A9, like derived-accessor→rel-accessor).
- **T4 route-desugar = COMPILE-TIME pure fold** (spec §G, verified: static pool can't see resolve-time nta spawns —
  eval.allNodes joins but not the static pool; Vogt finiteness realized statically). strataChain composite-above-subclaims.
- **T5 dedup `emit=nodes` TWO-equation** (attr-gather reads pool→content-addressed nta-spawn reading ONLY the gather;
  L5 bounded-NTA; gather→spawn ordering DEMAND-guaranteed NOT schedule-verified — documented residual, static fix =
  deferred `resolve.nta` accepting stratum+readsAttrs) + **stratified L4 claim negation** (throwing `.rel` + strictly-
  above, Apt–Blair–Walker; lockdown roots/@self).
- **T6 end-to-end Witness 2 suite** (`ci/tests/claim-provide-witness.nix`): ONE composed fleet, pieces COMPOSE (the
  shared connect-kind seam = leaf cyclic + route-desugar both emit connect, disambiguate by target endpoint).
Design ★REVISIONs (all adversarial-review-driven, in the P5b design doc): edge-uniform model, transpose-only GAP-3,
§G compile-time route-desugar, MR3 two-equation dedup. Honest limits (in REFERENCE): demand-vs-schedule dedup residual;
claim-name⟂relation-kind + cross-production claim-kind DISJOINTNESS assumption (owned by the framework-wide name-
uniqueness pass, NOT re-guarded locally — a local throw would be a half-measure patch); `genGraphLib.roots` follow-on
(lockdown realized via reverse-read predicate). Docs: in-repo REFERENCE.md @`af2d7b3` + papers gen-specs/den-hoag/
REFERENCE.md + STATUS + spec §11 item 5 all stamped SHIPPED. Design `specs/2026-07-21-...-phase5b-claim-provide-
design.md` (§G+★REVISION); plan `plans/2026-07-21-...-phase5b-claim-provide-plan.md` (+.tasks.json all completed).
**NEXT: P5c = nix-config native migration is FUTURE / out-of-this-scope** (owner: "migrate when it's time") → step 6
Compat. STATUS.md is authoritative for live state.

**★ STEP 6 (Compat) — IN PROGRESS (2026-07-21), branch `feat/den-test-migration` (NOT merged). Live resume ledger:
`papers/.../plans/2026-07-21-den-test-migration-EXECUTION.md`.** Design shipped (2 adversarial reviews): two-tier lowering
(materialization=compilation / resolution=forwarding), §D materialization bridge (`terminalModulesAt`+`provided-modules`
reverse-read, S1/S2/S3), behavior-target parity (name-normalized edgeSortKey NOT byte-pin), pin bump 11866c16→99cc0c5.
Target REFRAMED (owner): implement ALL of den → gen-native, gate on den-surface expressibility NOT corpus ([[feedback_den_surface_not_config]]).
Coverage matrix `specs/2026-07-21-den-surface-coverage-matrix.md` (~95 v1 APIs; ~40 absent = WS-B backlog). Test-migration:
den-behavioral scaffold on the flake-parts BRIDGE path (`ci/tests/_lib/den-compat-test.nix`; den-nav from `eval.config.den`;
hm realized per-host; darwin staged-not-realized), ~50 files migrated (batches A/B/C, ci 1628; parked = WS-B signals + few
genuine divergences). gen `testSingletons` single-test-selection PR ready-merge (gen `feat/mkci-single-test-selection`;
nix-unit detects by `test`-prefix, bare-leaf = 0/0 false-pass [[reference_nixunit_test_prefix]]). **WS-B general-system design
(★ AUTHORITATIVE) `specs/2026-07-21-wsb-general-system-design.md`** (grounding wf_0c83f99f-8bf): 3-tier stack (gen-lib
algebra · den-hoag kernel vocab/projection · compat thin-map); LITMUS = recursion/fixpoint/fold-over-graph/edge-walk in compat
= wrong layer; ONLY 2 net-new KERNEL mechanisms (payload-projecting reverse-read = generalize claim-accessor.reverseByKind;
forward battery = productions relation) + 1 seam (`to` per-aspect) + 1 re-layer (gather→gen-graph queryAll, expose=paths-mode
for the ++ order crux, broadcast=push-dual PARAM not a clone) + rest WIRE-existing. NEXT: finish `as` route-wiring → gather
re-layer → 2 kernel mechanisms → wire batteries(gen-aspects mkAspectOption)/settings(foldLayersTraced)/output-family-seeds.
[[feedback_reuse_scan_before_build]] applied to the GENERAL layer, not compat.

**═══ 2026-07-22 WS-B SESSION — 13 RUNGS MERGED TO MAIN (consolidation done) ═══** den-hoag `main` @`a9d68e6` PUSHED
(feat/den-test-migration ff-merged, ci **1664** green no-override); gen-bind `main` @`d33d1bd` PUSHED; den-hoag gen-bind
pin bumped f08a103→d33d1bd (real pin, gate EXIT=0 no override). This session added 2 rungs onto the prior 11 (d34ef44/1660):
(1) **config-thunk Tier-1** (`65bc050`, cross-repo) — a broadcast/expose config-thunk resolves at the PRODUCER terminal not
the consumer. gen-bind gained `producerConfigs` (opaque scopeKey→config map; `resolveThunks` indexes it for a `__sourceScope`
thunk, default `{}`=byte-identical) + isString guard; den-hoag builds a lazy FIXPOINT producer-config map (listToAttrs over
node ids, keyed `<entity.id_hash>::<class>`, host→nixos / user-cell→host-nixos `home-manager.users.<u>`), `deferredToThunk`
stamps the matching key. Load-bearing byte-parity: producer key added ONLY when the terminal has a real `.config` (nixpkgs
crossing); collect terminal → empty map → consumer fallback. Detail [[project_config_thunk_tier1]] (Tier-1 Nix-lazy co-eval,
A17=no-force-not-no-reference, deepSeq-kill-switch is v1-trampoline-only, CHORAG-grounded loud-on-cycle). (2) **parametric-include
late-dispatch** (`080f547`) — radiate bare-fn aspect-includes as synthetic aspect + edge policy carrying board-#57
`__firesAtKinds`, so a `{host,user}` include fires at the descendant CELL not the host. Guard = **`isLateDispatchFn`: a REQUIRED
formal names a DESCENDANT (non-root) kind** (`schema.<k>.parent` non-null) — ruled by the plan-reviewer strictly-stronger AND
more v1-faithful than the naive `firesAt≠[]` (which would radiate `den.default`'s root-only `{host,...}` batteries, breaking the
owner's individual-isolation invariant); proven DAG-tracking by a re-parent adversarial eval (`schema.host.parent=env` → `{host}`
radiates). Both rungs = full plan→plan-review→writer→two-stage-review loop, empirical (nix-eval) review. ★ GATE OVERRIDE TRAP
learned: gen-bind is a TRANSITIVE input → correct override is `--override-input den-hoag/gen-bind <path>`, a bare
`--override-input gen-bind` silently no-ops. STEP 6 still IN PROGRESS (backlog rungs remain: `to` seam, gather re-layer, 2
kernel mechanisms, batteries/settings wiring); EXECUTION ledger + STATUS.md authoritative.


## Comments (1)

### 1 — 2026-07-28T05:39:28 · Jason Bowman

★ ADDENDUM — CATALOGUE OF THIS ARCHIVE'S OWN MISDIRECTIONS, from the exhaustive reconciliation of lines 57-927 (2026-07-28). Read this before acting on anything in the archived log.

D1 ★ THE REPO PATH IS INVERTED, INSIDE A SENTENCE THAT 'CORRECTS' THE TRUE ONE. Lines 495-497: "the repo path is ~/Documents/repos/den-hoag — an earlier note's repos/sini/den-hoag path does not exist".
  MEASURED: ~/Documents/repos/den-hoag -> No such file or directory. ~/Documents/repos/sini/den-hoag -> EXISTS, is this repo.
  The run instruction it decorates (`cd ~/Documents/repos/den-hoag/{ci,parity} && nix build …`) fails immediately. THIRD independent instance of this exact inversion in the corpus, each written AS A CORRECTION — see also the features memory and the gen-schema-bump memory.
D2 Lines 353-354 order a `git stash clear` that would today destroy the one live stash — see den-hoag-4kh.28.
D3 Line 315 claims `__provider` was DELETED; it is still minted — see den-hoag-7pt.
D5 Line 104's v1 reference drv /nix/store/q1vk4s3z8r593mf5sg39pwqaijys7d2p-….drv IS NOT IN THE STORE. Any 'compare against it' instruction is unexecutable; a byte-compare would need a rebuild.

★ AND THE CLOSING BACKLOG IS ITSELF MOSTLY STALE — the direction that matters, because it under-states progress rather than over-stating it. Verified shipped since the log's last entry: `den.relations` (31 live), gather expose re-layered onto gen-graph paths-mode (lib/compat/gather.nix:244), `as` route-wiring (lib/compat/pipe.nix:39,157,165,341 + policy-verbs.nix:133), output-family seeds (lib/outputs.nix:156,173), payload-projecting reverse-read (lib/attributes/claim-accessor.nix:93 + ci/tests/claim-payload-projection.nix), kind-level `to=` projection tag (lib/concern-relations.nix:66,86). That is 6 of ~9 backlog items. Only the consumer-addressed seam (4kh.35), the settings blind // (4kh.37) and the render seeds (9xo.45) survive — plus the forward battery, which the papers trackers DO carry.

⇒ USE THIS ARCHIVE FOR HISTORY, NEVER FOR STATE OR FOR INSTRUCTIONS.
