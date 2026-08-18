# den-hoag-4kh.31 — [archive] den/hola/infra memory files verbatim pre-2026-07-28 reduction — memory dir has NO git history, this is the only copy

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.31` |
| status at evacuation | closed |
| priority | P3 |
| type | chore |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:32:50Z by Jason Bowman |
| last updated | 2026-08-01T19:47:04Z |
| closed | 2026-08-01T19:47:04Z |
| close reason | Archive complete — den/hola/infra memory files preserved verbatim in-body pre-reduction. Same rationale as 4kh.29: the body is the copy, closure does not delete it. No pending work. |
| description bytes | 255518 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

ARCHIVE — den / hola / infrastructure memory files, VERBATIM, before the 2026-07-28 reduction
(248,847 -> 116,783 bytes, -53%). Kept because ~/.claude/memory IS NOT VERSION CONTROLLED — no git
history exists to recover these from, and the scratchpad staging them is session-scoped.
★ SUPERSEDED AS TRUTH. Measured errors these contain, several that would MISDIRECT a session:
  - den PR #625 recorded 'STAYS DRAFT per Jason' — MERGED 2026-07-17. #623 'OPEN' — MERGED 2026-06-26.
  - 'revert den override 9d24f48b when #625 merges' — ALREADY DONE (nix-config flake.nix:92).
  - HM PR #9671 'DROP pin when merged' — MERGED 2026-07-18, pin already gone.
  - ★ WORST: a '★ LANDMINE: nix run .#write-flake DROPS the hm fork pin' warning for a fork pin that
    NO LONGER EXISTS — it would block a legitimate regeneration on a nonexistent hazard.
  - PATH INVERSIONS: cited ~/Documents/repos/den-lazy and ~/Documents/repos/den; NEITHER EXISTS.
    den v1 is ~/Documents/repos/denful/den.
  - ★ den_hoag_value_injection stacked THREE contradictory settled-rulings; the MIDDLE one asserted
    'SINGLE-TREE FORCING WAS THE ERROR; OPTION 1 IS CORRECT' as settled-with-verification, and was
    later ruled by the owner to be avoidance-via-rationalization. A reader sampling the middle layer
    gets the REVERSED ruling.
  - agent_teams said 'update to >=2.1.178'; installed is 2.1.220.
Read for historical content only. Current state: the rewritten files, and the bead graph.
════════════════════════════════════════════════════════════════════════

──────── archive-project_claim_provide_engine.md ────────
---
name: claim-provide-engine
description: nix-config k8s claim/provide engine design — network fabric (connect kind 0) + unified gen-derive claim engine generalizing db/storage/secret/route; specs written 2026-06-13
metadata: 
  node_type: memory
  type: project
  originSessionId: 7763d796-2d93-4fa4-a3c0-212db68aa951
---

Design phase (2026-06-13) generalizing nix-config's cross-cutting k8s resource derivation. Two committed specs in `~/Documents/papers/den-architecture/specs/`:

- `2026-06-13-network-fabric-quirk-design.md` — the **`connect` claim kind** (floor). Replaces media/network-policy.nix's hand edge-graph + per-app baseline CNPs with a `network-nodes` quirk: apps emit typed nodes (id/ns/explicit-selector/ports/tags/edges), one consumer derives BOTH halves of every edge. Heterogeneity-driven (selectors NOT uniform: app.kubernetes.io/name vs instance vs whole-ns vs cnpg.io/cluster; one aspect ≠ one node — prometheus = 3 nodes). Edge vocab: node id, `@ns:`/`@tag:`/`@metrics`/`@self`/`@all` classes, `@apiserver`/`@world`/`@host` entities, `@dns` = toEndpoints kube-dns selector (NOT a cilium entity). Decisions: media-pg ingress tightens ns-wide→7-apps (accepted, the one semantic delta); qbittorrent ingress fold-owns-fully (delete its hand CNP); validation = canonical SEMANTIC diff not byte-stable.

- `2026-06-13-claim-provide-engine-design.md` — **umbrella**. Unified gen-derive claim engine; network = claim-kind 0. Five kinds: connect/secret/storage/database/route. Composite claims (database, route) cascade into lower claims via gen-derive **fixpoint sub-claim emission** (route→{oidc-secret, gw-ingress-connect}; database→{password-secret, pg-connect}); terminates at connect/secret/storage leaves. Each claim → 3 action categories: provider-resource / consumer-wiring / sub-claim, phased desugar→provision→wire (per-kind-per-phase rules, since one rule can't span 2 phases — demo `_policy-rules.nix:35`). Secret = shared agenix→sops→k8s-Secret sub-fabric (db-password/api-key/oidc all the same pipeline).

**Architecture decisions made:** unified engine (not parallel fabrics); spec full model now (not network-only); gen-schema scoped to node-skeleton kind + freeform fold-asserted edges.

**ENGINE went through THREE framings; FINAL (commit 27c877f) = plain Nix + den quirk machinery, NO grand engine.** Arc: (1) gen-derive fixpoint — KILLED by opus reviewer: dispatch fires fixed rules vs ONE context, enriches keys only, fired-set caps identity once-per-fixpoint, can't re-dispatch sub-claims as subjects (gen-derive/lib/dispatch.nix:60-98). (2) scope-engine GRAPH (derived-children + transitive walk) — ALSO over-reach (2nd reviewer): derived-children UNUSED anywhere in nix-config, needs parseParent (no live resolver passes it), acl.nix:123 transitiveGroups is a static followEdge walk NOT derived children. (3) FINAL: **claims quirk fan-in (prometheus-targets pattern) + pure recursive desugar `expandClaim:claim→{resources;wiring;subClaims}` (terminates at connect/secret/storage leaves) + per-kind resolvers + `config.fleet.claims` option** (sibling to fleet.acl/fleet.settings). Cascade=plain Nix fold, NO graph. dedup=groupBy/foldl (a la acl.nix:138 effectiveGates). scope-engine ONLY for optional settings `shadow` (settings.nix:106). **gen-derive + gen-bind both UNUSED.**

**EVAL-CYCLE: blocker → discipline (user pushback was right, I over-accepted reviewer).** Reviewer claimed config.fleet.claims.get is cyclic (app emits claims AND reads aggregate built from them). NOT cyclic: emission ⊥ consumption are DIFFERENT ATTRS — forcing aggregate forces each app's `.claims` (emission) never `.k8s-manifests` (consumption). Nix per-attr laziness + module fixpoint handle it. PROOF in working code: PR #111 guests.nix reads `config.den.schema.host.includes` w/ explicit comment "(Read host.includes; we never write back to it from here, so no cycle.)" — tested 915/915 byte-identical; prometheus.nix emits+consumes own aggregate; users.nix:23 reads config.fleet.acl.get. Invariant to enforce in review: claim EMISSION must never read config.fleet.claims (holds auto: composites desugar from own fields). gen-schema refs NOT used (dead-on-arrival in den, eval-vs-apply timing).

**A/B write-back RESOLVED → read config.fleet.claims + splice locally.** App aspect: `wiring = config.fleet.claims.appWiring.sonarr; ... env = baseEnv // wiring.env`. NOT gen-bind (A, demo-only, binds NixOS module args, can't reach bjw-s helm-VALUES tree). NOT a bespoke per-app arg (orig B). Just the fleet.acl/fleet.settings option-read idiom (users.nix). NOTE: "policy spawns parametric aspect" push-half does NOT apply to k8s app aspects (static singletons den.aspects.kubernetes.services.media.sonarr, not spawned per-entity like users) — only the READ half applies. New files: modules/den/scope-engine/claims.nix (resolver, plain-Nix internally NOT engine.eval) + quirks/claims.nix.

**Reviewer findings still LIVE (fold into phase plans):** per-kind tables are SKETCHES dropping cluster-context plumbing — db `<app>-main`/`<app>-log` + media-pg-rw RW-service + 2nd connect (CNPG instance→apiserver, media-pg.nix:177-202, w/ sync-wave=-1); secret sopsOutput{file,key} + gen tags + own `media-secrets` app w/ sync-wave=-1 (api-keys.nix:55,59); route parentRef.sectionName + cluster.domainFor/oidcIssuerFor (sonarr.nix:240-285); storage claimRef/Retain/Prune-protect/RWX-vs-RWO + 4th subPath-remap mount (sonarr.nix:122-131). connect=two-engines seam: network-fabric uses gen-select+gen-graph over flat registry ("never called by the fold", net-spec:49), claim engine dispatches the connect leaf TO it — document the hand-off.

**Grounded in the live `gen-aspects/examples/demo/`** (reference impl): queries.nix (gen-graph accessor g + gen-select when/matches), composition.nix + _policy-rules.nix (foldLayersTraced + gen-derive fixpoint), injection.nix (gen-bind injectAspectSettings). Live API corrections: gen-select `when` is `(id: ctx: bool)` reading `ctx.data id` (NOT mkSelectPredicate, NOT node-arg); `any` not `or`; mkInstanceRegistry needs a kind via mkInstanceType (not free off a list).

**Rollout:** bottom-up phased — engine+connect → secret → database → storage → route, each gated on canonical semantic diff. Network-fabric spec = Phase 0.

**Status:** specs written + committed (papers repo `c3bd664`); brainstorm complete; next = writing-plans for Phase 0 (engine + connect), OR resolve the write-back A/B decision first. Related: [[project_settings_stratification]] (the stratification seam), [[project_provides_api]] (den provides/needs = the same relationship algebra), [[project_gen_package]], [[feedback_pr_sanitization]] (nix-config is PUBLIC).

──────── archive-project_class_bucket_holdover.md ────────
---
name: project_class_bucket_holdover
description: den-hoag's per-class content BUCKETS are a v1 nix-effects-state-accumulator holdover; gen-native = direct gen-edge graph queries. The bucket is the ROOT of the aspect-name/class-name collision + the looksLikeClassContent/isNestedKey value-shape anti-patterns. Scoped as tech debt to retire them together.
metadata:
  node_type: memory
  type: project
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
  modified: 2026-07-28T04:46:52.912Z
---

★★ SUPERSEDED IN PART 2026-07-28 — VERIFIED AT HEAD. **The disambiguation half of this memory SHIPPED by a
different route and this file's "parked pending" claim is FALSE.**

- **`lib/key-semantics.nix` shipped** — the ONE keySemantics vocabulary builder. gen-aspects builds every
  declared aspect key's option **generically** from it: `class → deferredModule`, `channel → raw passthrough`,
  `facet → the entry's own option/module`. A quirk-channel key "never falls to freeform"; a `.settings` block
  is "never freeform-absorbed as a nested aspect".
- **`classifyKey` dispatches on the DECLARED category**, not value shape — `lib/concern-aspects.nix:103-113`,
  `cat = aspectSchema.keyCategory key`, three branches.
- **`looksLikeClassContent` and `isNestedKey` are RETIRED** — `lib/compat/compile.nix:251` says "The FORMER
  `looksLikeClassContent`"; `:218` is a comment citing v1's `key-classification.nix`. No live predicate.

⇒ The aspect-name ⟂ class-name collision and both value-shape anti-patterns were **NOT** resolved by
retiring the bucket. They were resolved by DECLARATION (the "Shape B" gen-schema/gen-aspects arc, owner-ruled
2026-07-15). **The bucket still exists** — key-semantics declares `class → deferredModule` — so what remains
is only the narrower REPRESENTATION question: should class content be a **direct gen-edge query** rather than
a per-class accumulated bucket? That stands on its own evidence (`output-modules.nix:133`; the bucket map
marked "NO EFFECT RUNTIME" — effect stripped, shape kept) and has **no collision class hanging off it**.
Tracker `den-hoag-4kh.16`, re-triaged to P2. The scope doc `2026-07-24-bucket-to-edge-refactor-scope.md`
**predates the key-semantics landing** and its core question — "does the disambiguation dissolve or move to
query time?" — was answered by a third route: it dissolved, via declaration, without the edge model.

★ **HOW THIS MEMORY CAUSED AN ERROR, so the shape is recognisable:** it was used on 2026-07-28 to file a bead
and a retirement register, both asserting the collision and predicates were still live. Neither was checked
against the tree. Verification took four commands once the owner questioned it. **A memory is a point-in-time
observation; it is not evidence about HEAD.** Anything in a memory naming a `file:line` must have that line
re-read before it drives work. See [[feedback_verification_predicate_blindness]].

Owner insight 2026-07-24 (den-hoag WS-B, during host.settings rung-5 triage): den v1's per-class **buckets** — collecting each aspect's class content into `{ <class> = [ <deferredModule> ] }` per node — were required ONLY by v1's **nix-effects STATE ACCUMULATOR**. In pure gen (graph-based), buckets should NOT be needed: class content reduces to **direct gen-edge graph QUERIES**. den-hoag stripped the effect-runtime but KEPT the accumulator's SHAPE (eager per-class bucket collection).

**Evidence (verified):** `lib/attributes/output-modules.nix:133` — "gen-edge is class-coordinate-generic (README: 'den's NixOS class buckets … are ONE instantiation')" → gen-edge is the general model, buckets a v1-shaped instantiation. `lib/attributes/class-modules.nix` (attr 9) pre-collects buckets, marked "NO EFFECT RUNTIME" (effect stripped, SHAPE kept). gen-aspects `classOptions = genAttrs (keyOf "class") deferredModule` (`~/repos/sini/gen-aspects/lib/types.nix:257-264`) = the per-class DECLARED bucket-landing option.

**★ THE BUCKET IS THE ROOT of the collision class.** The per-class declared `deferredModule` option is what shadows a same-named nested aspect → the aspect-name ⟂ class-name COLLISION (microvm = `den.classes.microvm` AND aspect `den.aspects.virtualization.microvm`; home-manager likewise; the general form of [[project_den_v2_terminal_classes]]'s karabiner collision + rung-3). Because the node is EAGERLY committed to "this key is class content" at TYPING, `looksLikeClassContent`/`isNestedKey` (`lib/compat/compile.nix:245,263`, ported from v1 key-classification.nix) exist ONLY to recover the aspect interpretation after the fact — the value-shape ANTI-PATTERN the owner wants GONE (distinct from the karabiner looksLike rejection: that was namespace-vs-class-content [indistinguishable]; this is nested-aspect-vs-class-content). Under an edge model (no per-class declared option; class content = graph query) the eager commitment vanishes → collision + both predicates + §2.2-over-collapsed-buckets potentially DISSOLVE together.

**Status:** SCOPING as tech debt (owner: "scope the refactor, see if issues dissolve; NO band-aid"). Scope doc `papers/den-architecture/specs/2026-07-24-bucket-to-edge-refactor-scope.md` (spike scope-bucket-edge). ★ Core open Q the scope must answer: does the disambiguation DISSOLVE (distinct class-content-edge vs aspect-nesting constructions → value-shape deletable) or MOVE to query-time. **The whole aspect/class collision class + value-shape predicates + host.settings rung 5+ (nix-config compile-frame grind) are PARKED pending this.** den-hoag delivery already got the edge treatment ([[project_delivery_edge_unification]] #563); class-CONTENT collection is the one part that never did. Links [[feedback_underscore_keys_state_hack]] [[feedback_route_through_gen_native]] [[project_den_architecture]].

──────── archive-project_config_thunk_tier1.md ────────
---
name: project_config_thunk_tier1
description: Cross-host config.* resolution = Tier-1 Nix-lazy co-eval (not a stratum); deepSeq fear is v1-only
metadata: 
  node_type: memory
  type: project
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

den-hoag cross-terminal materialized-value resolution (a broadcast/expose config-thunk `{config,...}: config.networking.hostName` resolving against the PRODUCER's config, not the consumer's). Looked like a DEEP blocker (reintroduce v1's hostConfigs stratum, breach A17, CHORAG co-eval engine). It is NOT — a spike proved **Tier 1 VIABLE**: leverage Nix's own `evalModules` lazy fixpoint as the co-evaluation engine. Spike + design: `papers/den-architecture/specs/2026-07-22-cross-terminal-materialized-values-spike.md`.

**The four non-obvious facts:**
- **A17 = no-FORCE, not no-REFERENCE** — gather may hold a lazy unforced producer-config ref; only forbidden from forcing during the gather pass.
- **The deepSeq-state kill-switch is a v1 (denful/den nix-effects TRAMPOLINE) artifact — den-hoag DOESN'T HAVE it.** den-hoag resolves via gen-resolve (`seq` on schedule only); terminal configs are post-resolution, outside any deepSeq. Do NOT re-derive the "eager cross-host force → blocker" path — it's a v1-not-den-hoag confusion.
- **The `lib.fix` knot ties** — acyclic-at-use resolves; genuine cross-scope cycle → LOUD `infinite recursion` (uncatchable, NOT silent-wrong). S3 reframed "no cycle" → "no SILENT cycle" — dominates v1's stratum (silently-wrong on the circular case, CHORAG Fig 10-11).
- **Tier 2 (explicit CHORAG iteration) not constructible** — NixOS config isn't a bounded-height lattice ([[reference_delta_nets]]-adjacent; CHORAG Def 1).

**The fix (2 parts) — ✅ SHIPPED TO MAIN 2026-07-22:** (A) gen-bind additive `producerConfigs ? {}` param — `resolveThunks` resolves a `__configThunk` against `producerConfigs.${__sourceScope}` when present (both dispatch paths thunk-aware; default `{}` byte-identical) + isString guard (non-string key → consumer fallback, not a coerce-throw). **gen-bind `main` @`d33d1bd` PUSHED** (6566c28+0f72528+d33d1bd). (B) den-hoag builds the lazy FIXPOINT producer-config map over `systems` terminals (key=`<entity.id_hash>::<class>` — id_hash NOT coordDims: function-valued decls break toJSON; host→nixos / user-cell→host-nixos `home-manager.users.<u>`), `deferredToThunk` stamps the matching key. Load-bearing byte-parity: producer key added ONLY when the terminal has a real `.config` (collect terminal → empty map → consumer fallback). **den-hoag `main` @`a9d68e6` PUSHED** (Part B `65bc050` + pin bump). Both reviewed SHIP (all 6 faithfulness claims eval-confirmed; O(n) map built-once-shared; no perf defect). ★ GATE OVERRIDE TRAP: gen-bind is a TRANSITIVE input → `--override-input den-hoag/gen-bind <path>` (bare `gen-bind` silently no-ops → old pin → `attribute 'who' missing`); moot now the pin is bumped. Idiomatic ALTERNATIVE for structural facts: use the entity coord (`host.name`) not `config.networking.hostName` — a co-eval value vs a §5.1 materialization. See [[project_den_hoag_features]] for live status.

──────── archive-project_consolidated_spec.md ────────
---
name: Design docs and specs location
description: Specs and plans live in ~/Documents/papers/den-architecture/{specs,plans} (not in-repo docs/superpowers/), survives git stash/pop across repos
type: reference
---

## Primary reference: den-architecture folder

Design documentation lives in `~/Documents/papers/den-architecture/`, organized as:

- `specs/` — design specs (current and historical)
- `plans/` — implementation plans
- Papers (PDFs) — academic references at the top level

This is the canonical location for specs and plans. It lives outside any single repo so it survives git stash/pop operations and is accessible when working across den, gen-schema, gen-aspects, etc.

## Secondary: den-specs repo

Historical design docs also exist in `~/Documents/den-specs/` (github:sini/den-specs):
- `design/` — older authoritative design docs
- `tbd/`, `implemented-branch/`, `cancelled/`

**How to apply:** Write new specs and plans to `~/Documents/papers/den-architecture/specs/`. Never write them to `docs/superpowers/` in-repo — those are ephemeral working copies that get lost.

──────── archive-project_corpus_eval_parity_bar.md ────────
---
name: project_corpus_eval_parity_bar
description: den-hoag's real parity bar = the actual corpus (nix-config + ~19 den-configs) EVALUATING under den-hoag; the v1-surface matrix is completeness truth but under- AND over-counts; every corpus gap = a ship requirement, works-on-den-gated
metadata:
  node_type: memory
  type: project
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
  modified: 2026-07-28T04:26:17.691Z
---

★★ SUPERSEDED IN FRAMING 2026-07-27/28 — READ THIS FIRST. The corpus is **DEMOTED to a validation SYMPTOM,
not the bar**. The bar is graph-native correctness ([[feedback_best_framework_first]]); the compat target is
den-SURFACE EXPRESSIBILITY, not corpus presence ([[feedback_den_surface_not_config]]). And the parity target
is byte EQUIVALENCE, not identity — merge order need not match
([[feedback_byte_equivalence_not_identity]]). **The corpus and the frozen oracles are TOOLS. They must not
constrain a design in the name of correctness or simplicity.** Everything below remains accurate as
METHODOLOGY — how to run the corpus, the works-on-den gate, where the configs live — but its framing of the
corpus as "the REAL bar" is the pre-demotion view and must not be quoted as the standard.

Owner methodology (2026-07-24, den-hoag WS-B): the REAL parity/coverage bar is **the actual corpus evaluating under den-hoag**, not the matrix census. The v1-surface matrix (`specs/2026-07-21-den-surface-coverage-matrix.md`) stays the **COMPLETENESS source of truth** (the configs are a real SAMPLE, not comprehensive), but "anything missing from the matrix is a real need to ship." The matrix was demonstrated to BOTH under-count (host.settings, karabiner, den.systems — untracked, real corpus blockers) AND OVER-count (intoAttr marked CLOSED @63df21b but the real droid `nixOnDroidConfigurations` output is ABSENT — a SYNTHETIC-witness-only green). So: run the corpus, let it confirm which matrix items are live real-needs + surface the ones the census missed.

**★ ALL den forks are the SAME den:** `denful/den` == `vic/den` == `sini/den` (vic renamed→denful, github redirects; sini's dev merged to main). EVERY den-config is den-hoag's TARGET — no fork is out-of-scope. (Corrected a mid-sweep error where vic/sini configs were wrongly sidelined.)

**★ THE works-on-den GATE (owner-required, non-negotiable):** a corpus blocker is a REAL den-hoag gap ONLY if BOTH (a) the config evals on its OWN pinned den (NO override) AND (b) fails under the den-hoag override. If (a) ALSO fails → the config is broken / version-drifted → SKIP, not a den-hoag gap. NEVER declare a gap without confirming (a). This filtered the den-configs cleanly (14/15 evaluable were real, 0 false positives once gated).

**Corpus:** nix-config (`~/Documents/repos/sini/nix-config`, uses denful/den, flake.lock populated) + ~19 den-configs (`~/Documents/repos/den-configs/`, various pins of the same den). Eval: `cd <config> && nix eval '.#<output>.<host>...drvPath' --override-input den <den-hoag-branch> --impure --show-trace` (attrNames probe faster — den's dendritic pipeline fails eagerly at the API gap). ★ Override must point at the BRANCH under test (bare-repo-path resolves the checked-out branch; a stale worktree/branch tests the wrong tree — verify the rev in the trace).

**Sweep results (2026-07-24):** nix-config 8/9 hosts gate on `host.settings` (NEW). den-configs (works-on-den-gated): 14/15 real gaps, 4 surfaces — `flakeModules.dendritic` (7×, was matrix-LEAVE), `den.namespace` (5×, was deferred), `flake` bare-evalModules opt (1), `den.systems` (1). Specs: `specs/2026-07-24-corpus-eval-sweep.md` + `specs/2026-07-24-denconfigs-revalidated.md`. The ship queue + full state: `plans/2026-07-24-RESUME-CHECKPOINT.md`.

Links [[den-hoag-feature-targets]] [[project_den_v2_terminal_classes]] [[feedback_feature_flags_removability]] [[feedback_route_through_gen_native]] [[den-surface-not-config]].

──────── archive-project_deepseq_state_thunk.md ────────
---
name: deepseq-state-thunk-pattern
description: "nix-effects trampoline deepSeqs state — wrap NixOS config values in thunks (_: v) so deepSeq can't force lazy option defaults"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8c4b977-4c52-4544-a5b8-3b4a734913e1
---

nix-effects trampoline = `builtins.deepSeq newState` (trampoline.nix) for stack safety. State holding NixOS config objects (e.g. `state.currentCtx = { host = hostConfig; }`) → deepSeq forces ALL option defaults, incl optional inputs (`hjem.module` default touches `inputs.hjem`) → crash.

**Fix:** wrap config-bearing state in fn thunk `currentCtx = _: ctx;` (fns opaque to deepSeq). Unwrap at use: `(state.currentCtx or (_: {})) null`.

**Also:** `state.availableArgs` = keys only (not config values): `builtins.mapAttrs (_: _: true) ctx`.

**How to apply:** any NixOS/module-system value into nix-effects state → wrap `_: value`. Check pipeline.nix state init + handlers writing config objects.

──────── archive-project_delivered_child_route_fix.md ────────
---
name: project_delivered_child_route_fix
description: den route reinstantiate primitive (SHIPPED via #563); guests policy lives in nix-config not den; cortex-cuda microvm guest GPU byte-identical
metadata:
  node_type: memory
  type: project
  originSessionId: 8bd2eca2-aa5c-4a3f-a14a-ba21303e8d15
---

RESUME-2 (delivered cortex-cuda) COMPLETE 2026-06-11. den side SHIPPED via #563.

**Root cause + fix (den core):** route `nestPlain` (`fx/route/wrap.nix`) PRE-EVALUATED delivery payload in isolated freeform evalModules + unwrapped `mod.imports` → DISCARDED per-module `key` wrap-classes assigns (`<class>@<identity>`). For RE-INSTANTIATING target (microvm `microvm.vms.<n>.config` re-runs eval-config w/ base modules), stripped base defaults → namespace aggregates valueless → throw; keyless dupes across {host,user} double-declared. Fix: opt-in `reinstantiate` route flag → `nestVerbatim` keeps keyed wrapper (`{imports=[mod]}`). Existing routes byte-identical (defaults false). +regression test re-instantiating through real base modules. NOTE: post delivery-edge unification, nestPlain/nestVerbatim dissolved into edge algebra ([[project_delivery_edge_unification]] reinstantiate = nest-verbatim edge).

**Projected-hasAspect id_hash re-key (e8876f3e):** superseded ancestor-stripping scopeId fix — buckets keyed by context-free entity `id_hash`. See [[project_projected_hasaspect]].

**LAYERING (den @688478b9, nix-config @c7cff18c):** delivered-child POLICY was wrongly in den core (`flakeModule.nix` does `listFilesRecursive ../modules` → auto-registered delivered-guest kind for EVERY consumer). It's pure composition of public primitives (resolve.to.withIncludes + route + schema reg) w/ one consumer. MOVED to nix-config `modules/den/aspects/virtualization/guests.nix`, renamed `host.deliveredChildren`→`host.guests`, kind `delivered-guest`→`guest`, `den.deliveredChild`→`den.guests` (dropped generic deliveryPathFor, hardcoded microvm path). **den core keeps ONLY** route `reinstantiate` flag (genuine engine primitive) + standalone `route.test-route-reinstantiate-base-context`; 13-test public-api/delivered-child-host.nix + policy file DELETED. CORRECTION (delivery-edge §4): guest edge NOT deliver-expressible (`deliver.to` names a class not scope; needs appendToParent scope-redirect + collectSubtree, route-shim-internal) → stays on route shim permanently.

**nix-config:** PR #111. cortex-cuda = microvm guest of cortex (`guests.cortex-cuda`, intoAttr=[], no standalone output); agenix+core.users fire. **GPU parity byte-identical** by nix-diff cortex toplevel (only delta = flake-source store path any edit rehashes; vfio-gate identical). Guest reconciliation: tailscale neutralized (headless, user-scope age-secret not collected — [[project_media_stack_migration]] pattern), mkForce stateVersion/PermitRootLogin, programs.zsh for participating shells. identityPaths /persist/etc/ssh.

Follow-ups Q1 ollama-endpoints cross-env, Q2 agenix host-key projection, Q3 GPU metrics. Spec papers `specs/2026-06-11-route-reinstantiation-delivery-design.md`. Supersedes RESUME-2 note in [[project_entity_isolation_fix]].

──────── archive-project_delivery_edge_unification.md ────────
---
name: project_delivery_edge_unification
description: "den v1 delivery-edge unification — Phase 0+1+2 SHIPPED (Tasks 1-11); remaining Tasks 12-14 (sweep, deliver API, parity)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 8bd2eca2-aa5c-4a3f-a14a-ba21303e8d15
---

den v1 delivery-half debt elimination on `feat/entity-gen-schema-port` (worktree ~/Documents/repos/den-lazy). Spec: `~/Documents/papers/den-architecture/specs/2026-06-12-delivery-edge-unification-design.md` (gist 711513ef3eb581403bdc2758bb8e4a0c). Plan + §A/§B/§D: `plans/2026-06-12-delivery-edge-unification.md` (papers repo). 14 tasks, subagent-driven with two-stage review.

**Algebra:** edge = (S,T,P,M); S ∈ collected/rewalk/synthesize; M ∈ merge/nest/nest-verbatim (provides = nest∘merge); materialize over Π(root); isolated = edge-absence; reinstantiate = nest-verbatim. Deviation-classification protocol (bug-in-old/bug-in-new/intentional), §D ledger.

**Phase 0 SHIPPED (hard gates):**
- §A Π census: **B′ hostConfigs raw-vs-drained = ACCIDENT (latent bug)** — deferred include carrying config-dependent pipe value diverges under cross-host config-thunk resolution vs real instantiate output; fix cycle-constrained (baseDrain→assemblePipes→hostConfigs), owned by Task 11 with 3 remediation options. Deliberate: mergedSpawnRoutes (#4), isolation-blind spawn extraction (#6), subtree+ancestors edge-set (#9), B blind-collect/aware-extract (#10). No-witness: B class-inject (#1), C spawn own-provides (#3).
- §B dossier: provides = TWO-edge nest∘merge (nest into source-scope bucket + default fold carries); complex-forward = ONE synthesize edge w/ collected-else-rewalk source rule; 10 reachable + 7 unreachable route matrix cells (#572 combine needs explicit combineSingleEval flag; adapter arm cell 6 has DYNAMIC P via intoPathFn); cycles unreachable today (provides→route one-directional, load-bearing); cycle policy = loud throw.
- Edge-trace extractor v0 + 14-test delivery-edges suite (8 topology fixtures incl. collectedScopes annotation on default folds).

**Phase 1 SHIPPED (cuts, behavior-identical):** write-only state deleted (scopedConstraintFilters/flatAspectPolicies); scope-walk.nix (subtreeScopes w/ explicit required `isolated`, dedupByKey) replaced 4 isInSubtree + 3 dedup loops + wrapPerScope fold; assemble-pipes single stage interpreter (idFunctor/pvFunctor value functors, −86 LOC; provenance passthrough asymmetry preserved bug-for-bug). CI 961/961 @ 378c4c12.

**Phase 2 SHIPPED (Tasks 7–11):** materializer+default-fold (7), simple-route (8), provides+complex-forward (9), spawn (10) — all byte-stable, see §D. **Task 11 SHIPPED** (3 commits @ den-lazy 2f7259df):
- 11a findHostScopeId DISSOLVED → `scopeByEntity` state map keyed by `(parentScope, id_hash)`, recorded at push-scope (handlers/push-scope.nix), consumed by `entityScopeFor`. Multi-system same-name handled (id_hash context-free, distinct system= parents). Single-child fallback = explicit T rule (null link → sourceScopeId). `hasInfix` host-matching gone (only identity.nix name-classification survives).
- 11b instantiates → flake-output T-arm edges: new `edges/instantiate.nix` (specDescriptors + @system disambiguate), shared by production+oracle. applyInstantiates keeps ONLY lazy thunk-tree (metadata-only descriptors → laziness preserved).
- 11c **B′ ACCIDENT fixed via OPTION (b)** — NOT just baseDrain: witness revealed the operative mechanism is census #8 (B′ built peer configs over RAW scopeContexts, so pipe-CONSUMING peer aspects `{feat,...}` got pipe values un-injected → `feat missing`). Fix: B′ builds over `augmentedScopeContextsNoCfg` (hostConfigs-null assemblePipes pass = cycle-free, resolves pipeline-parametric pipes) + `drainedForHostConfigs` (mkDrained parameterized by its augmented-contexts source). Residual limitation: deferred-include-on-config-dependent-pipe stays deferred (unbreakable inter-config recursion). Witness `deadbugs/bprime-basedrain-crosshost` (defect+control, has teeth). CI 963/963, delivery-edges 14/14 byte-stable (sole edit: resolvedRootVia "name-infix"→"scope-link").

**ALL 14 TASKS SHIPPED.** Task 12 (sweep) @ c7be44a5, 13 (deliver+shims) @ f82bc6c1, 14 (parity: cortex toplevel BYTE-IDENTICAL across Tasks 4-13, same store hash — not just flake-source-only). route/provides permanent shims w/ TODO-deprecation. **CORRECTION:** guests policy (PR #111) is NOT deliver-expressible (`deliver.to` names a class, not a scope; guest edge needs appendToParent scope-redirect + collectSubtree, both route-shim-internal) → stays on route shim permanently, NO migration; spec §4 corrected. Net-behavior gist: 16f1941e6b8683419840aa70ca3a4137. HOAG parity oracle gap recorded as r2 open-Q 6 (edge-trace = delivery graph only; needs +toplevel-hash content gate +future pipe-flow trace).

**PR #563 (denful/den ← sini:feat/entity-gen-schema-port) prepped + deliverability-audited 2026-06-13.** Branch bundles FOUR efforts (gen-schema port + isolation/guest + resolver-decoupling + delivery-edge), +5164 net, 63 commits, 975/975 CI. Audit (4 parallel read-only agents): (1) gen-schema dep stays `github:sini/gen-schema` per user (matches nix-effects CI-lock-fallback pattern, mechanism sound); (2) flake-parts-modules template `path:../..`→`github:denful/den` FIXED @ 5868da9c; (3) **perHost/perUser/perHome shim RESTORED** @ d526844e (shipped in main → removal was real breaking change; restored rule-correct: drops old hasExtras→{} self-suppression which WAS #609; new test perctx-shim); (4) docs corrected (debug.md, lib-deprecated.mdx, parametric.mdx gains #609 binding rule + silent-inert footgun). Only ONE real breaking change vs main = the #609 binding-rule semantic shift (no API removed). No in-repo changelog (den convention = heads-up GH discussions at release, maintainers.mdx). Leftover-scaffolding sweep of efforts 1-3: clean (3 trivial fixes @ 12e06e72).

**FOLLOW-ON (2026-06-14): edge-toposort unification for den-hoag parity.** The original 14 tasks ported mechanisms to edge constructors but KEPT the phase-fold orchestration (resolve.nix:637-659 phase1→4 + per-host re-walk + assembleSpawnSubtree as 3 separate Π variants) — Corollary 5 (toposort) was intentionally NOT in the 14 (prior spec §3c). New spec `specs/2026-06-14-edge-toposort-unification-hoag-parity.md` covers the orchestration collapse as Tasks 15-19: T15 Π(root) census+one-builder (prereq, the big one), T16 unified edge set + cross-mechanism toposort (generalize single-level route topoSort + cycle detection), T17 switch production to materialize(toposort)-over-Π (retire phase folds + both re-entries), T18 oracle≡production (edge-trace renders the production edge object, not a re-derivation — THE crux: makes the parity claim hoag≡nix-effects not hoag≡oracle), T19 parity harness + frozen cross-repo edge schema. Key: edge-parity is STRUCTURAL (rewalk/synthesize record identity not content) → pair with the content gate (toplevel derivation-hash = r2 open-Q 6). Cycle-safety invariants (B′ augmented-ctx, hostConfigs fixpoint, thunk discipline) relocate into Π-construction pre-pass, never edge ordering.

**REVIEW-COMPLETE (2026-06-14, 3 fresh-eyes passes → SOUND-WITH-FIXES, all applied; design-done, not yet implemented).** Welded (NOT split — maintainer call: a standalone edge-capture would orphan the parity oracle from the architecture it certifies = debt). Pass arc: hole (Π/perScope conflated) → hole (spawn/per-host/B′ folds discard edges → oracle undercounts) → no structural hole, only refinements. Load-bearing claim VERIFIED in code: static-Π fields (scopeContexts/scopeParent/scopeIsolated/isolationMode/rootScopeId/dedupMode/allScopeIds/classInject) are NEVER mutated by an edge step (only Π-construction for a new root) → toposort-over-fixed-Π is well-founded. Hard-won facts the reviews nailed (non-obvious): (1) the fold accumulator is `{ classImports; perScope }` — TWO fields, classImports is read BACK mid-fold at route.nix:568 (root-forward getCollectedSource), not perScope alone; (2) there are FOUR phase-fold sites, not two: fxResolveFull (resolve.nix:637), fxResolveImports (resolve.nix:748, phase1→3), per-host re-walk (mkInstantiateArgs), spawn (assembleSpawnSubtree); (3) per-root Π, NOT one global Π — roots differ in isolationMode (aware/blind) / dedupMode (dedup/raw) / allScopeIds / B′ noCfg contexts; unified set toposorted ACROSS roots, each edge materializes under its OWN root's dials; (4) spawn/per-host/B′ folds currently RETURN ONLY `{imports}` → must surface their edge sets or oracle≠production for spawn/instantiate topologies; (5) appendToParent (route.nix:688 → parent root bucket) = first-class cross-root edge, ordered before parent merge; (6) content hash must be CROSS-pipeline (v1-materialized vs hoag-materialized). topoSort already Kahn+cycle-throw (route.nix:485-503); genuinely-new part = cross-KIND dependency extraction. Next build step = Task 15 (Π/accumulator census + one-static-Π builder + written proof the {classImports,perScope} enrichment is a toposortable dep graph) BEFORE any production change.

**TASK 15 SHIPPED (2026-06-14, den-lazy on feat/entity-gen-schema-port, CI 989/989).** Prereq for the edge-toposort unification; plan `plans/2026-06-14-edge-toposort-task15-pi-builder.md` (+`.tasks.json`), subagent-driven, plan reviewed 2× (✅). Deliverables: (1) spec **Appendix A15** (field census — 4 fold sites: fxResolveFull resolve.nix:301, fxResolveImports :700, mkInstantiateArgs/per-host :112 [B′ hostConfigs :351 RIDES this, not a 4th pi site → 3 re-entries = 2 pi literals], assembleSpawnSubtree materialize.nix:246) + **Appendix B15** (toposortability proof: static-Π read-only; accumulator DAG acyclic — `getCollectedSource` route.nix:556-568 is the ONLY acc-reader, simple routes+provides read FROZEN inputs so depsOf=[] for them; phase-order = one valid topo order) committed papers @ b02f953. (2) `nix/lib/aspects/fx/edges/pi.nix` `mkStaticPi` (the 9 static fields ONLY — rootScopeId/scopeContexts/scopeParent/scopeIsolated/isolationMode/contextsAreAugmented/dedupMode/allScopeIds[optionalAttrs-omitted-when-null]/classInject; provides/routes are fold INPUTS, NOT static-Π), exposed `den.lib.aspects.fx.edges.pi`, 2 tests, @ den 954e7834. (3) both inline pi literals refactored to `(mkStaticPi{…}) // {perScope;classImports;provides;routes;}`, byte-stable (assembleSubtree reads only perScope+dials w/ or-defaults), Π doc-comment annotated, @ den 48ebf84b. NOT pushed to sini yet. Next: Task 16 (unified edge set + cross-kind toposort).

**TASK 16 SHIPPED (2026-06-14, den-lazy feat/entity-gen-schema-port, CI 1004/1004).** Plan `plans/2026-06-14-edge-toposort-task16-unified-set.md` (+`.tasks.json`), subagent-driven, plan reviewed 2× (✅ after fixing 2 majors: spawn-edge double-count disposition + mkDrained return-shape), 16.3 (crux) got a full post-impl review (✅ 7/7 checks). **SCOPING DECISION: lighter 16.5** — Task 16 builds + validates the unified edge set + toposort but does NOT switch production materialization (deferred to Task 17, which also owns the "materialization == phase1→4" proof). Five commits: (16.1 @020e85c6) `assembleSpawnSubtree` returns `{imports;edges}` — surfaces default-fold+ownProvides+mergedSpawnRoutes via shared constructors (threaded `den`+merged `scopeEntityKind`; materialize.nix now `{lib,den}`; exposed `edges.materialize`). (16.2 @567af713) new `edges/instantiate-edges.nix` `mkInstantiateEdges` (pure; exposed `edges.instantiateSubtree`). (16.3 @60189fd0, the crux) `mkDrained` now returns `{classImports;spawnEdges}` (only host-own invocation's spawnEdges feed the union; B′ discards); `perHostProjection` factored (shared by mkInstantiateArgs[return UNCHANGED] + edge collection — the parity property Task 17 needs); `extractTopLevelEdges` factored in edge-trace.nix (oracle output-preserving); lazy `unifiedEdges` on fxResolveFull = top-level(minus rewalk arm)+drain spawnEdges+per-host+B′; route.nix:585 fallback spawn NOT surfaced (synthesize edge represents it). KEY: drain-fold spawn only fires at FLAKE-level resolve (host is ctx-seeded, absent from scopeEntityKind). (16.4 @3ddc518a) new `edges/toposort.nix` `topoSortEdges` (exposed `edges.toposort`) — record-level Kahn+loud-throw; cell model (B15): writeCell=(target.root,class) or null for {output}; readCells: merge+collectedScopes→subtree cells, synthesize→ALL fromClass writers (flat), instantiate→host cell, provides/simple-routes→{} (frozen); cellKey="scope/class" (classes slash-free). (16.5 @206aa523) `fx-edge-unification-gate.nix` 5 tests — completeness(⊇ oracle-minus-rewalk+surfaced) + valid-order(topoSort succeeds+permutation+producer-before-merge) + cycle-throws, on spawn/plain/instantiate/isolated-guest. NOT pushed. Next: Task 17.

**TASK 17 SHIPPED (2026-06-14, den-lazy feat/entity-gen-schema-port, CI 1011/1011 byte-stable throughout).** Plan `plans/2026-06-14-edge-toposort-task17-switch-production.md` (+`.tasks.json`), subagent-driven, plan reviewed (✅ after 3 fixes: pin materializeUnified construction order provides++routes for stable-tiebreak; 17.5 spawn injection-seam scope; 17.6 firm deletes). **DESIGN B (order-only), NOT fat edges** — trace edges are identity-only + synthesize/instantiate payloads are fold-position-dependent+recursive, so reuse existing materializers, use topoSortEdges only for ORDER. **STRICT-byte gate** (module-list order NOT observable through NixOS option merge; entity-isolation asserts set membership; topoSortEdges made STABLE = construction-order tiebreak). **Host-closure hash gate is OUT-OF-REPO** (no nix-config ref in flake) — deferred to the nix-config den bump; in-repo gate = entity-isolation(real evalModules)+fx-e2e+full CI byte-stable. Six commits: (17.1 @ef9c2f63) `edges/materialize-unified.nix` `materializeUnified` (exposed `edges.materializeUnified`) — ordered-dispatch fold reusing applyOneProvide[factored from applyProvidesEdges]/applySimpleRouteEdge/applyComplexRouteEdge/assembleSubtree; pairs provides++routes edges, stable-toposort via __pairIdx, dispatch threading {classImports;perScope}; simple routes read FROZEN seed.perScope, complex read evolving acc (matches applyRoutes); doFinalMerge→assembleSubtree; equivalence proven byte-exact on all canaries (dispatch-order-identity + accumulator fingerprint, since closures can't ==). topoSortEdges made STABLE (Kahn ready in index order, locked+tested). (17.2 @681885c6) fxResolveFull: phase2/3→materializeUnified{doFinalMerge=false}, phase4 stays. (17.3 @4cfe13b9) fxResolveImports: →materializeUnified{doFinalMerge=false}, no merge (flat classImports). (17.4 @ef2abb97) per-host mkInstantiateArgs: →materializeUnified{doFinalMerge=true}@hostScopeId, KEY scopeContexts=relevantContexts (complex-forward reads pi.scopeContexts), B′ noCfg distinction preserved, scopeEntityKind threaded both call sites. (17.5 @114a4784) spawn assembleSpawnSubtree: →materializeUnified{doFinalMerge=true,blind/raw}; reached via lazy den namespace (materialize-unified imports materialize → no direct import, no cycle). (17.6 @ba8dbc7d) added materializeUnified exposeAcc flag (one fold → {merged;acc}); deleted redundant per-host/spawn phase2/3 (edge collectors now read materialized.acc.perScope); dropped applyProvides/applyRoutes injection from mkSpawnNode/assembleSpawnSubtree. KEPT applyProvidesEdges+applyRoutes wrapper+route.nix:applyRoutes — now ONLY the `materializeEquiv` lazy byte-equivalence ORACLE in resolve.nix (oraclePhase2/3) the fx-materialize-unified suite compares against; delivery phase orchestration fully deleted. RESIDUAL (future cleanup): materializeEquiv oracle keeps the legacy phase path alive in production resolve.nix purely as the standing equivalence gate — could move the comparison fully into the test + delete applyRoutes/applyProvidesEdges once trust is established. NOT pushed. Next: Task 18.

**TASK 18 SHIPPED (2026-06-14, den-lazy feat/entity-gen-schema-port, CI 1014/1014).** Plan `plans/2026-06-14-edge-toposort-task18-oracle-production.md`, subagent-driven, plan reviewed 2× (❌→❌→applied: 2 criticals [top-level "literal object" overclaim — fxResolveFull is doFinalMerge=false flat-read so its merge edge is STRUCTURAL not folded; existing suites bind oracle=edgeTrace + would break/tautology] + fixture-taxonomy major), then the 18.2+18.3 COMMIT reviewed (✅, the suppressed-twin semantic verified sound). **DESIGN D1+expose (literal object, drift-proof)** chosen by user. Four+1 commits: (18.1 @170e9960) materializeUnified `exposeEdges` flag → returns `foldedEdges = map(p:p.edge) orderedPairs` (captured fold edges), composed into non-dispatch returns [table: (false,_,true)→acc//{edges}; (true,false,true)→{merged;edges}; (true,true,true)→{merged;acc;edges}], existing callers byte-unchanged. (18.2+18.3 @765f0341, ONE unit) edgeTrace := captured provides+routes (from materializeUnified.edges at all 3 sites: top-level, spawn .edges, per-host mkInstantiateEdges[now takes capturedEdges]) ++ constructor defaultFold ++ constructor instantiate; unifiedEdges aliases edgeTrace; legacyEdgeTrace = extractEdgeTrace (rewalk-bearing); fx-unified-edges + fx-edge-unification-gate oracle arm repointed to legacyEdgeTrace; NEW fx-oracle-production-differential.nix (production vs legacyEdgeTrace on spawn+instantiate). **KEY FINDING: production edgeTrace differs from legacy in TWO ways — drops the rewalk undercount AND drops dedup-suppressed route twins** (production folds orderedKeptRoutes only; suppressed never materialized → faithful). Fixtures re-baselined (EVALUATED not guessed): host-users 7→6, darwin, home-extraction 8→6, suppression-annotation 1→0, standalone-home 3→5, multi-system 4→8, fleet-environment 4→7, fleet-pipe 5→9; UNCHANGED: isolated-guest + corollaries. (hardening @869e16e0) differential `legacyDelivered` strips rewalk AND suppressed from legacy arm → correct relation production ⊇ legacy\rewalk\suppressed (sound for future distinct-key suppressions, not just CI's key-aliasing same-id forward twins). (18.4 @acf6cef6) doc-comments: edge-trace.nix header now "LEGACY re-derivation / legacyEdgeTrace differential arm"; default.nix spawn-surfaces-real-edges; materialize-unified IS-production+exposeEdges; materialize.nix .edges captured+consumed-by-edgeTrace. sourceVia="unresolved" docs KEPT (path-dependent by construction, permanent — zero consumers, internal audit-only, doesn't weaken parity). Plans committed to papers @95ec0cd. NOT pushed. Next: Task 19.

**TASK 19 SHIPPED (2026-06-14, den-lazy CI 1019/1019) — EFFORT COMPLETE.** Plan `plans/2026-06-14-edge-toposort-task19-parity-harness.md` (committed papers, no formal review — low-complexity capstone, self-verified by identity gate). (19.1 @den e543c55a) `nix/lib/aspects/fx/edges/parity.nix` `assertEdgeParity {expected;actual} → {matched;missingFromActual;extraInActual;parity}` diffing by edgeSortKey (annotations excluded, STRUCTURAL); exported edgeSortKey from edge.nix; exposed `den.lib.aspects.fx.edges.parity`; `fx-edge-parity.nix` 5 tests = identity gate (edgeTrace vs self parity==true + matched!=[]) over corpus (spawn/instantiate-fleet/isolated-guest/plain) + negative control (edgeTrace vs legacyEdgeTrace parity==false, non-vacuous). (19.2 @papers 83d9d7e) `parity/edge-schema.md` v1 (frozen cross-repo contract: record/S-T-P-M enums/normalization/id_hash naming/sourceVia-permanent/structural⊕content) + `parity/runbook.md` (nix-effects arm = r.edgeTrace; den-hoag arm = E-renderer INTERFACE [no hoag repo yet]; assertEdgeParity diff; §5.1 deviation classification bug-in-hoag|bug-in-v1|intentional-v2; ship gate E_hoag≡E_nixeffects whole corpus + content hash). DOC PLACEMENT: contract→papers (per no-in-repo-docs feedback), harness→in-repo.

**=== EDGE-TOPOSORT / HOAG-PARITY EFFORT COMPLETE (Tasks 15-19, 2026-06-14) ===** 24 den commits (CI 961→1019), branch feat/entity-gen-schema-port = 104 ahead of main, ALL LOCAL (NOT pushed — user said push at end). Arc: T15 mkStaticPi (static-Π/accumulator split + proof) → T16 unifiedEdges + topoSortEdges (surfaced spawn/per-host/B′ edges, cross-kind/field/root toposort) → T17 materializeUnified (production = ONE toposorted edge fold per root, all 4 sites, phase orchestration deleted, byte-stable) → T18 edgeTrace = captured production object (oracle≡production, drift-proof; legacyEdgeTrace differential; dropped rewalk-undercount + suppressed-twins) → T19 assertEdgeParity + frozen v1 contract. Production delivery IS the parity trace. OUT-OF-REPO REMAINING (not this effort): den-hoag E-renderer implementation (when hoag built, per runbook) + nix-config host-closure content-gate at the den bump + PUSH to sini + PR #563. RESIDUAL future cleanup: materializeEquiv oracle keeps legacy phase path in resolve.nix as standing equivalence gate (could retire + delete applyRoutes/applyProvidesEdges once trusted).

Related: [[project_resolver_decoupling]] (the binding-half twin), [[project_projected_hasaspect]].

──────── archive-project_den_architecture.md ────────
---
name: den-architecture-and-resolution-pipeline
description: "Den = Nix flake-parts framework; fx-pipeline algebraic effects, four-concern model, scope-partitioned state, pipes/quirks. SHIPPED to main (was feat/fx-pipeline)"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8c4b977-4c52-4544-a5b8-3b4a734913e1
---

Den = Nix flake-parts framework. Composes NixOS/darwin/home-manager via "aspects" (composable config units). Resolution = algebraic effects via `nix-effects`. SHIPPED to main (fx-pipeline + all below landed; orig branch feat/fx-pipeline gone). Live spec source = ~/Documents/papers/den-architecture.

**Four-concern model:**
- Schema — `den.schema.*`, `den.hosts`, `den.homes` (entity decls, includes, policies)
- Collection — aspect tree walk, narrow effects (compile-static/parametric/conditional/forward)
- Routing — `policy.route` + `policy.provide` + scope partition reads
- Policy — `installPolicies` + `scope.provide` + typed effects (resolve/include/exclude/route/provide/instantiate)

**Pipeline parts:**
- shape router `compile.nix` → forward/conditional/parametric/static
- gate `gate-tag.nix` = dedup + constraints
- bind subsystem `bind.nix`/`defer.nix`/`drain.nix`/`scope-widen.nix` = resolve/defer/drain lifecycle
- policy dispatch `dispatch-policies.nix`/`record-fired.nix`/`emit-policy-effects.nix`/`widen-context.nix`
- scope mgmt `push-scope.nix`/`restore-scope.nix`/`propagate-routes.nix`
- `wrapClassModule` pre-applies den ctx args to class module fns
- scope-partitioned state: `mkScopeId`, `scopedClassImports`, `scopeParent`, `scopeContexts`
- NOTE post delivery-edge unification: phase-fold orchestration replaced by `materializeUnified` (one toposorted edge fold per root) — see [[project_delivery_edge_unification]]

**Pipes/quirks (delivered):** quirk = structured data on named aspect key under `den.quirks`. pipe = data route w/ `name` + ref. pipeline = `pipe.from <ref> [stages]`. stages = filter/transform/fold/append/for/withProvenance/to/expose/collect. `pipe.collect` reaches peer scopes via `scopeParent` (cross-host). config-dependent quirks = bare fns, resolved lazily. `classifyKeys` 3-branch: class/pipe/nested ([[project_unified_aspect_key_type]]). Supersedes deleted trait + fleet-and-exports.

**Fleet pipeline (delivered):** walk-then-instantiate, all hosts one run; per-host-subtree assembly w/ correct rootScopeId; cross-host flow via pipes not traits.

**Provides (permanent API):** `provides`/`_` = permanent user API, cross-entity routing in policy effects. See [[project_provides_api]]. New users → `policies.*` + direct nesting.

**Policy registry/activation:** `den.policies` = registry only; activate via `includes`, deactivate via `excludes` (authoritative, parent wins). `policy.for`/`policy.when` filter w/ preserved identity.

**Why:** fx pipeline + four-concern model = foundation for all den work.
**How to apply:** den.policies for topology/behavior; bare fns for ctx-aware aspects; specs in papers archive. v2 = [[project_hoag_architecture]].

──────── archive-project_den_class_module_entity_fanout.md ────────
---
name: project_den_class_module_entity_fanout
description: den PR
metadata: 
  node_type: memory
  type: project
  originSessionId: 693e258d-3ad8-4c0f-90ab-442d521d79dc
---

den PR #634 (branch fix/class-module-user-arg-fanout, base denful/den main): fixes issue #629 — `nixos = { user, ... }:` class module at HOST scope was silently dropped (wrapClassModule unsatisfied → wrap-classes returns []). Aspect-level `{ user, ... }: { nixos = ...; }` worked because bind fans over host descendants; class-module fn args never reached that fan-out.

**Fix**: compile shape router (`nix/lib/aspects/fx/handlers/compile.nix`) promotes a STATIC aspect whose class-content module names a strict DESCENDANT of the emitting scope's entity kind into a parametric aspect on those kinds → existing `bind` fan-out handles it. Guards: `argClass.isDescendantOf` (scope-kind-self/ancestor stay static, no regression to `nixos = { host, ... }:`); `__parametricResolvedArgs` stops re-promotion loop on the re-resolved body. 1059/1059 CI.

**Design = Option A** (promote-to-parametric) over Option B (fan content in emit-classes, extending [[project_den_emit_classes_ctx_fix]]/PR #624). Chosen because den-hoag fan-out is COORDINATE-driven (§339 well-formedness: only `__fn`/guards are callables; class content is opaque deferredModule reading its resolved node's bindings). So the rule "entity kinds named in class content are parametric coordinates of the aspect" is a front-end normalization that ports as ONE ingest rule feeding hoag's existing coordinate fan — keeps the den-fx↔den-hoag parity oracle holding. Option B (fx emit-classes + scope-string enumeration) doesn't port; v2 dissolved those clusters to node resolved-aspects.

**TODO den-hoag** (~/Documents/repos/den-hoag): add the same normalization at ingest (concern-aspects/compat ingest) — collect class-content-named entity kinds into the aspect coordinate set. NOT yet done. See [[project_den_hoag_features]].

**Deliberately NOT fixed**: dead `lib.warn` at class-module.nix:124 (attached to the discarded unsatisfied module → never forced → silent skip). Left because descendant case no longer skips, and reviving warn unconditionally noises the intentional guard-skip pattern (nested-class-module-args test-guard-skips-without-context). Reporter wanted debug messages → better as a debug-gated trace, separate concern.

──────── archive-project_den_emit_classes_ctx_fix.md ────────
---
name: project_den_emit_classes_ctx_fix
description: "den fix — emit-classes must read scope ctx from pipeline state, not per-aspect __scopeHandlers; enables per-user host-class fanout"
metadata: 
  node_type: memory
  type: project
  originSessionId: 975f14c3-b742-4bc7-ba84-429b0e289892
---

**den bug (fixed):** a STATIC (constant-name) aspect included via `den.schema.<kind>.includes` whose host-class (`nixos`/`darwin`) content NAMES an entity kind (`nixos = { user, … }:`) collapsed N sibling entities → 1 at the shared host merge — all but one user's content dropped before eval by `dedupByKey` on a sid-free identity. `homeManager` was immune (per-user target path).

**Root cause:** `nix/lib/aspects/fx/handlers/emit-classes.nix` derived emit `ctx` from `aspect.__scopeHandlers` — only populated for parametric aspects (bind augmentation) or propagated includes, ABSENT for static aspects on static include chains → empty ctx → base identity. The authoritative scope ctx (`state.scopeContexts.${currentScope}`) was right there; `bind.nix` already reads it.

**Fix (one file, `emit-classes.nix`):** (A) read authoritative ctx from `state.scopeContexts.${currentScope}` (+ `scopeEntityClass` for `class`), child-scope-gated (root keeps historic path), aspect's own `__scopeHandlers` layered ON TOP (fan-out child bindings win). (B) key each class-content entry by the entity kinds its fn NAMES ∩ ctx: `{user,…}`→`{user=<u>}` fans per user; `{host,…}`→`{host=<h>}` dedups across delivery scopes; `{persist,…}`/`_:`→no suffix, singular (shared infra like impermanence keeps deduping — no double option-decl). `isContextDependent = contextDep || namedEntityArgs != []`.

**Why it's a unification not an edge case (Jason's steer):** the two emit sites (`bind.nix`, `emit-classes`) now read scope identity the SAME way; named-arg keying is then a pure fn of authoritative ctx. Earlier wrong attempts: include-site `stripCtxId` re-stamp (didn't survive navigation), uniform `propagateScope`/`resolve-children` ctxId (broke impermanence double-option-decl), emit-time-only keying (path-inconsistent — steam `{host,…}` emitted base in empty ctx + `{host=cortex}` in host ctx → dup `programs.steam.package`).

**Status:** denful/den **PR #624**, commit `01058e71`, branch `feat/user-scoped-host-class-fanout`. 1044/1044 CI (+ `user-scoped-host-class-fanout` regression suite); byte-identical fleet output (cortex/blade/uplink/axon-01). Surfaced by [[project_replicated_home_syncthing]] Task 0 gate. After merge: bump nix-config den pin.

**Diagnostic gotchas:** `nix eval` eval-cache can hide `builtins.trace`/`lib.warnIf` — use `--no-eval-cache`. Unit `denTest` did NOT catch this (needed a full `nixnixosConfigurations.<host>...toplevel` eval — the steam/impermanence multi-include conflicts only appear fleet-wide). Entity records in scope ctx carry `id_hash` at push-scope but NOT at the schema-entity include site; `.name` is the instance there.

──────── archive-project_denhoag_effects_audit.md ────────
---
name: project_denhoag_effects_audit
description: den-hoag pure-gen-graph conformance audit (2026-07-24) — where v1's nix-effects runtime got ported into the kernel instead of dissolved into gen; the concentrated-organs thesis + 6-item gen-gap roadmap + open compat exposure
metadata:
  node_type: memory
  type: project
  originSessionId: a220e78f-5ac2-4b6c-b417-3d65c0b01fcd
---

Adversarial audit of den-hoag @`8774601` for the effects-handler-in-kernel axis (owner: the agent that
built it ported v1 effect-handler patterns into the kernel; the prior single-author catalogs rationalize
their own mistakes — distrust them). 74-agent workflow `wf_39811bba-fea` (scout v1 fx → 9 finders →
per-finding adversarial verify steelmanning the "pure gen" defense → critic → synth): **62 raw → 25
confirmed + 33 REFUTED** (verify killed over-claims). Report: `papers/den-architecture/specs/2026-07-24-den-hoag-effects-runtime-audit.md`
(+ `-synth.json`/`-findings.json` backing; STATUS.md LIVE-section pointer). v1 baseline = `denful/den@11866c16`
(`modules/` 1936 + `nix/lib/aspects/fx`); den-hoag = 12.7k kernel + 10.9k compat = 23.6k.

**★ THESIS (sharper than "3× ported interpreter", evidence-backed):** the CENTRAL resolution loop IS
gen-native (the two `scope.circular` fixpoints, gen-dispatch firing, gen-scope inherited/synthesized attrs;
v1 `drain.nix` worklist genuinely dissolved). Effect-shape is CONCENTRATED: ~14-16% of the kernel (~1.7-2.1k
LOC), split (DL-HS-24 classifier, now proven): **(a) leverage failures** routable to EXISTING gen now
(~250-350 LOC — groupBy/transpose/ancestors/cycles/reachableFrom hand-rolls) + **(b) gen GAPS that FORCED
the hand-rolls** (~550-700 LOC irreducible until 6 primitives ship — NOT purely the author's fault).

**★ FLAGSHIP violation:** `staged-resolution.nix:112-262` `runPrePass` = the ONE true v1 scope-partitioned
state-accumulator trampoline — a `foldl'` threading `{tuples;relationBindings;containmentRelations;suppressions}`
across a hand-rolled parent-before-child schedule where child phases READ what parent phases WROTE
(`:231/:205`). Dissolve into **gen-resolve `reference`** (RAG value composition) + **gen-scope inherited
attributes**; the manual schedule (`orderRootKinds`), the `__denSuppressedPolicies` marker, and the eager
settings-ancestor walk all vanish with it. Other organs: `recBucketsOf` eager per-class bucket
(class-modules.nix — value-SHAPE only, control-flow gen-native; = [[project_class_bucket_holdover]], already
scoped) → gen-edge collectedUnion; suppression subsystem (`__denSuppressedPolicies` kernel `__`-marker +
per-rule name-scan) → gen gap G6.

**★ 6 GEN GAPS (components to design; overlap the gen-link arc):** G1 gen-graph `reachableWitness`/`foldReach`
(ordered, edge-label-carrying, suppression-aware traversal); G2 gen-graph `expandPreorder` (payload DFS-preorder
closure, seedable seen, lazy edges); G3 **gen-dispatch declared-stratum policy vocabulary** (kills
concern-policies' probe-fire-classify-expand — the last "policy = opaque fn you EXECUTE to classify" holdover);
G4 gen-edge/gen-bind terminal-crossing arg-env transform (adaptArgs/config-gate); G5 gen-pipe declaration-site
derived-channel identity (kills the CSE renamer); G6 gen-scope/gen-graph policy-suppression gate over a
scope-subtree (extends shipped `reach-suppress`; retires the `__` marker). G3+G6 = highest leverage.

**★ OPEN EXPOSURE (audit's confidence ceiling — NOT yet cleared):** (1) **~9.1k of 10.9k compat UNAUDITED**
(only compile.nix clustered; grep gather/bridge/ingest/registry/pipe for foldl'/genericClosure/recursive `go`);
(2) `output-modules.nix:1098-1141` `producerConfigs` eager cross-fleet config-thunk knot (v1 §4 hostConfigs B′
re-entry, critic-caught, ZERO prior findings, unverified — [[project_config_thunk_tier1]]); (3) `attributes/default.nix`
inherited-context assembler = read-back consumer of runPrePass, unverified for a 2nd accumulator. Recovered 2
died-verifier findings by hand: `aspectIncludeWalk` (compat compile.nix:1263-1364, CONFIRMED = old catalog G5)
+ `resolveParametric` (collections.nix, PARTIAL → gen-bind wrapAll).

Links [[feedback_route_through_gen_native]] [[project_denhoag_kernel_primary_surface]] [[feedback_underscore_keys_state_hack]]
[[project_class_bucket_holdover]] [[project_gen_link]] [[reference_gen_lib_capability_map]].

──────── archive-project_den_hoag_features.md ────────
---
name: den-hoag-feature-targets
description: "den-hoag pointer — WS-B rebuilds ALL of den gen-native. State lives in beads, not here. Correct repo paths + cold-start command."
metadata: 
  node_type: memory
  type: project
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T05:11:48.888Z
---

**den-hoag = ALL of den re-expressed gen-native.** Compat target is DEN-SURFACE EXPRESSIBILITY, not
corpus-presence ([[feedback_den_surface_not_config]]).

★ **COLD START: `bd show den-hoag-4kh`.** Everything else reconstructs from the graph.

## Paths — verified 2026-07-28. An earlier version of this file had them INVERTED.
- repo: `/home/sini/Documents/repos/sini/den-hoag` ← **`repos/den-hoag` DOES NOT EXIST**
- papers: `/home/sini/Documents/papers/den-architecture` — **not in-repo, not under `repos/`**
- gen-* libs: `~/Documents/repos/sini/<lib>` ([[reference_gen_repo_clone_location]])

## Where state lives — beads, not this file
- **`den-hoag-4kh`** — kernel-purity epic, the live arc.
- **`den-hoag-9xo`** — feature targets. ★ Its 2026-07-27 owner comment RESETS THE EXIT CONDITION to **parity
  with den v1**, with graph-native as *how* parity is reached rather than an end in itself. Read that comment
  before quoting any north-star framing, mine included.
- **`den-hoag-4kh.17`** — retiring-constructs register. Read BEFORE writing any brief or spec.
- **`den-hoag-4kh.20`** — instrument-trap case log. **`4kh.27`** — this file's 927-line predecessor, verbatim.
- ~24 open beads sit outside both epics. `bd ready` is the honest list.

## The two failures this file caused — why it is now a pointer
1. It recorded the **topology arc as "BACKBURNERED … zero shipped code"**. It had LANDED — `build-roots.nix`
   mints a node per attachment, `9xo.10` closed on it. The file added *"do not resume without re-measuring"*,
   a line that would have stopped a session from touching work already in main.
2. It asserted the real repo path **does not exist** — and did so *as a correction*.

Both were written as helpful precision, by predecessors doing the same job I am. **A memory is a
point-in-time observation, never evidence about HEAD.** See [[feedback_verification_predicate_blindness]],
[[feedback_memory_architecture]].

Related: [[project_kernel_purity_arc]], [[reference_den_corpus_set]], [[feedback_best_framework_first]],
[[feedback_byte_equivalence_not_identity]], [[project_class_bucket_holdover]].

──────── archive-project_denhoag_kernel_primary_surface.md ────────
---
name: project_denhoag_kernel_primary_surface
description: den-hoag's foundational goal — give users ALL native gen-* library features to extend configs (not just the compat surface); the firm kernel⟂compat line exists to enable this. Kernel = primary expressive gen-native surface (unambiguous by construction); compat = thin v1→kernel map. Design new surfaces at the kernel; v1-drop-in is a compat concern.
metadata:
  node_type: memory
  type: project
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner design goal (2026-07-24, den-hoag WS-B): **den-hoag's purpose is to give users access to ALL native gen-* library features to extend their configs — NOT just the compat layer's exposed surface.** The more internals/systems den-hoag exposes, the more kinds of configuration users can express. **This is WHY the firm KERNEL ⟂ COMPAT line is kept.**

**Design implications (govern every den-hoag surface decision):**
1. Design NEW surfaces (e.g. namespace separation, class/aspect grammar) at the **KERNEL / gen-native surface** — make it CLEAN, maximally expressive (full gen-aspects power, internals exposed), and **unambiguous BY CONSTRUCTION**. A user authoring gen-native gets this surface.
2. **v1-drop-in is a COMPAT-MAPPING concern, NOT a kernel design constraint.** Compat is the THIN v1→kernel dialect map — it translates a v1 corpus (`foo.microvm={...}`, shared namespace) onto whatever the kernel's surface is. Do NOT down-rank a kernel design for differing from v1's surface: the corpus stays working via compat, and new authoring gets the better surface. (Complements [[feedback_den_surface_not_config]]: gate on den-SURFACE expressibility, and the kernel IS the fuller surface.)
3. **value-shape / v1-ambiguity resolution lives ONLY at the compat boundary** reading v1's surface (where v1 itself uses `isNestedKey`) — NEVER in the kernel. Owner wants `looksLikeClassContent`/`isNestedKey` gone from the kernel unconditionally, gone from compat if possible ([[project_class_bucket_holdover]]).

This is the deeper "why" behind [[feedback_route_through_gen_native]] (route gen-capability through native gen, not re-implement in compat) and the compat litmus (compat = thin dialect map, no recursion/fold/identity/merge — those are kernel/gen). Links [[project_den_hoag_features]] [[project_den_architecture]].

──────── archive-project_den_hoag_readiness.md ────────
---
name: den-hoag-readiness-review
description: "2026-06-09 full review — 8 gen libs READY (one gen-select gap), HOAG architecture SOUND-WITH-REFINEMENTS, 5 spec questions + 1 lib PR before impl"
metadata: 
  node_type: memory
  type: project
  originSessionId: b9463207-aa3d-4941-abd2-b0ac298d61d8
---

> **UPDATE 2026-07-02 — the PURE SUBSTRATE den-hoag builds on is now SHIPPED + PUBLIC.** The pure-gen
> module system (gen-types + gen-merge byte-mode `evalModuleTree` + gen-schema/gen-aspects re-host
> REPLACEMENT, byte-identical incl id_hash SHA) + the gen-flake value-injection boundary are published
> ([[project_gen_package]], [[project_gen_resolve]]). **den-hoag can build on the pure `evalModuleTree`
> substrate with ZERO migration surface** (its stated advantage). Two readiness-relevant results PROVEN
> on the byte-mode engine: (a) the **value-injection invariant** (gen types never enter a consumer
> options tree), and (b) **config-thunk deferral preserved byte-identically** — den's `__configThunk`
> rides gen-merge's lazy `lazyAttrsOf`/`raw` merge unforced through composition + mid-pipeline
> route/forward, forcing byte-identically at the terminal reading `config`/`osConfig` (permanent
> regression, gen-merge `c960e5c`). The 2026-06-09 architecture refinements + the one gen-select gap
> below are STILL the open den-hoag readiness items (substrate readiness is now settled, not these).

Full review 2026-06-09 (8 per-lib agents + adversarial soundness audit). Plan: `~/Documents/papers/den-architecture/plans/2026-06-09-gen-readiness-gap-closure-plan.md`.

**ALL TRACKS EXECUTED same day:** B1–B5 resolved in `specs/2026-06-09-hoag-soundness-refinements.md` + propagated to den-hoag REFERENCE/ISSUES/CHANGES (ISSUES #1/#7/#9/#10/#12 resolved). A1 SHIPPED: gen-select `feat/scope-adapter-entity-kind` @b69bc5e pushed (type projection + entityKind, 103/103). Track D doc hygiene applied (uncommitted working-tree edits in gen-algebra/schema/scope/graph/derive repos). **r2 canonical spec authored:** `specs/2026-06-09-den-v2-hoag-architecture-r2.md` (~1100 lines, self-contained implementation spec) — adversarially reviewed FIX-THEN-SHIP, all 3 blockers (joint-fixpoint pseudocode) + 4 majors (link-context injection point, buildRoots contract, applyGuards removal, Implementation Scope table ~980–1,460 core lines) fixed same session. Implementation can start from r2 alone; build order stages 1–6 with checkpoints.

**Library verdicts (all tests green):** gen-algebra 144, gen-scope 152, gen-schema 379, gen-aspects 67, gen-select 96 core (demos don't eval — flake plumbing), gen-derive 68 (SHIPPED, stale docs say "spec approved"), gen-bind 59, gen-graph 110. All test counts in specs/READMEs stale.

**Only real lib gap:** gen-select neededBy path — no `sel.entityKind`, scope adapter `data = id: (node id).decls` hides node `type`, zero tests against real gen-scope accessor shape. Blocks provides→neededBy desugaring validation (11/13 configs use provides). Fix: richer projection + constructor + test.

**Architecture: SOUND-WITH-REFINEMENTS.** Must resolve before impl: (1) enriched-context eq is keyset-only — value overwrites converge silently order-dependent; need definition-time dup-key error; (2) pipe.gather predicate domain/materialization-frontier termination unspecified (same root cause as Neron/Statix ISSUES #9); (3) edge-as-link without re-resolution (ISSUES #7); (4) neededBy scoping + guard/neededBy asymmetry (guard-arrived aspects don't trigger neededBy → presence depends on arrival path); (5) spec body still implies semilattice determinism — reconcile with ISSUES #10 pinned-traversal+associative contract. During impl: per-class output assembly (gen-bind needs NO new surface — all vs modules selection), derived-children stratification (tier-2 forwards), neededBy O(A²) rescan, parseParent enforcement.

**Consumer obligations (by design, not gaps):** den-hoag brings provides/neededBy semantics, parametric __fn handling (gen-aspects is two-branch), P*.I* WF enforcement, aspect-chain threading (or rely on flatten keys), entityKind sugar.

──────── archive-project_den_hoag_value_injection.md ────────
---
name: project_den_hoag_value_injection
description: RESOLVED 2026-07-15 — Shape B (gen-schema keySemantics + single typed tree) landed; __provider shadow DELETED; identity is native gen-aspects .key; byte-parity held. Debt gone.
metadata: 
  node_type: memory
  type: project
  originSessionId: 1b8c99e5-4c42-4d3b-ba76-727c6bdad750
---

## ═══ RESOLVED 2026-07-15 — SHAPE B SHIPPED, __provider DELETED ═══
The value-injection debt is ELIMINATED. Arc (subagent-driven, opus impl + two-stage reviews + independent probe): plan `~/Documents/papers/den-architecture/plans/2026-07-15-den-hoag-shape-b-key-semantics-plan.md`, spec `specs/2026-07-15-den-hoag-shape-b-key-semantics-design.md`. **What shipped:**
1. **gen-schema keySemantics surface** (@017062c main, pushed) — `mkSchemaEntryType`/`mkSchemaOption` accept + record an OPAQUE per-key `keySemantics` map (category-agnostic; introspectable). gen-schema learns no aspect vocabulary.
2. **gen-aspects generic dispatch** (@b19ca92 main = feat/wrap-gated-fn ff-merged, pushed) — `aspectSubmodule` builds every declared key's option from `cnf.keySemantics` (`class→deferredModule`, `channel→raw`, `facet→module/option`); DELETED the `cnf.classes`/`classOptions` arm; kept `imports = facetModules ++ (cnf.aspectModules or [])` (the `__defsModule` seam). A-IDENT `.key` unchanged. `wrapGatedFn` rides along. gen hub bumped @e9d9208.
3. **den-hoag single typed tree** (feat/projection-graph, pushed through b696523) — core+compat declare ONE `keySemantics` (shared `lib/key-semantics.nix`); **#8 fixed** (channels declared → not freeform); compile consumes the TYPED tree (`compileFull = compile(typeAspects(desugarLegacy v1))`), grounds identity from native `.key`; **`__provider`/annotate/stamp-provider DELETED** (grep-clean except the `key-classification.nix:50` v1-reserved carve-out). ci 947 + parity 71 + **byte gate v1DrvPath==shimDrvPath BYTE-IDENTICAL** held across every rung.

**THE KEY FINDING (corrects the record below):** the F1 "structural-option leak + double-deliver" that stalled the first attempt was NOT inherent to gen-aspects (an isolation probe proved the typed node is CORRECT) — it was a den-hoag **raw/typed DUAL-WIRING** bug (nav-freeform made a class body a nested aspect, then compile re-typed a nav-captured include as a deferredModule OF it). Fix = unify nav+compile on ONE typed tree + project ONLY class buckets (strip structural facets) + `classSliceOf` unwrap-empty + carry native `.key` for bare-refs + abort unregistered attrset keys. ALL den-hoag-side, NO gen-aspects change. This matches the "it was a DUAL-WIRING bug" correction (2026-07-14 §, below). **PROCESS WIN:** an implementer took the banned Option-1 raw-walk off-ramp (recorded failure mode); an independent adversarial probe caught it, owner ruled pursue-the-single-tree, and it landed clean. The single tree is the CORRECT architecture, exactly as the owner insisted.

REMAINING (NOT this debt): projection redesign Phases 6-7 (corpus migration → re-baseline) continue on feat/projection-graph; nix-config gen-schema hygiene bump deferred (Task 6). See [[project_den_hoag_features]].

---
### (historical reasoning trail below — kept for provenance; superseded by the RESOLVED banner above)

**The architecture (verbatim from the sources, 2026-07-13):** gen-merge is a **drop-in replacement for `lib.evalModules` + `lib.types`-merge**, byte-identical output → existing nix modules run on it unchanged (backwards-compat). gen-flake is the **single nixpkgs boundary** via **value-injection**, with the INVARIANT (gen-flake README): *"gen types never leave the pure eval; only values cross into nixpkgs."* Two halves: **compose** (PURE — gen-merge folds the tree over gen-schema/gen-aspects, typed, no nixpkgs → `{ values; aspects; hosts; provenance; override }`) → **realize** (TERMINAL — nixosSystem, resolved values only).

**The anti-pattern (den-hoag compat bridge, the debt):** den-hoag CORE follows the model (`output-modules.nix` = gen-flake `realize` shape; direct `mkDen`/`evalV1 = schema.evalModuleTree` composes in gen-merge → identity native, preserved). But the **compat bridge** (bridge.nix/flake-module.nix) VIOLATES it: it TYPE-DRIVES from the consumer's nixpkgs flake-parts — mounts `den.*` as `freeformType = anything` (inert-data "type-crossing dodge"), then RECONSTRUCTS aspect identity by hand via the `__provider` annotate walk (`annotate.nix`) + `stamp-provider.nix` + compile's positional fallback + `key-classification` skip-filters. That shadow layer (7+ files) reimplements gen-aspects' identity/structure = **reimplements v1's machinery**. Every identity bug (positional keys, apps/devshell namespace collision, cross-scope dedup) traces to it. `isAspectRecord` (heuristic aspect-detection) = owner-REJECTED symptom; on branch `rejected/isAspectRecord`.

**REDESIGN v1 (compose/realize re-plumb) — REJECTED 2026-07-13 by adversarial review + re-probe.** Two fatal, PROBE-CONFIRMED errors: (§6) native gen-aspects `.key` is NAME-ONLY not path-bearing — `apps.media.spicetify`→`"spicetify"` (meta.loc absent), and `hardware.cpu.intel`==`hardware.gpu.intel`==`"intel"` (`collide=true`, 23 corpus collisions) → deduping on `.key` DROPS content; (§7) the flake-parts bridge sees `config.den` VALUES not sibling module FUNCTIONS, cannot re-drive corpus through compose. Also: den-hoag doesn't use gen-flake compose/realize (uses evalV1+own terminal); gen-flake has no policy/neededBy/staged/channel machinery. The `__provider` shadow is COMPENSATING for the name-only `.key`, not gratuitous.

**REAL root cause + REDESIGN v2 (owner decision 2026-07-13 = "fix in gen-aspects"):** identity is lost INSIDE gen-aspects — `aspectSubmodule` gets `loc` at merge but never stamps `meta.aspect-chain`, so `.key=pathKey([name])`. `.key` logic is byte-identical pre/post the gen-merge refactor (`64c3c25`) — was NEVER path-bearing for plain nested aspects; the path lives only in `flatten`'s walk keys (extrinsic). FIX = **A-IDENT**: stamp `meta.aspect-chain` intrinsically via a container-rooted walk (M1, = what `flatten` already does) so native `.key`==definition path. NB `loc` INCLUDES the mount prefix (`["aspects",...]`, mount-dependent) so raw-`init loc` is WRONG — must be container-relative. Fixes intel/intel at source for ALL gen consumers; then den-hoag consumes native key + retires `__provider` (G2). §7 sibling-rebind stays separate/open. Spec: `~/Documents/papers/den-architecture/specs/2026-07-13-gen-aspects-intrinsic-path-identity.md` (supersedes the value-injection redesign spec, now marked REJECTED).

**My error to NOT repeat:** "protocol-completion" (making gen types mount INSIDE nixpkgs `evalModules`) DIRECTLY VIOLATES the invariant — gen types must never enter nixpkgs' options tree. The mount-test failing (`substSubModules`/`deprecationMessage` missing) is a RED HERRING; they're never meant to be there. Fix = don't put them there (value-injection).

**G2 __provider retirement BLOCKED — PROBE-CONFIRMED 2026-07-14 (Phase 3 Task 2 DEFERRED by owner).** A-IDENT landed in gen-aspects, but den-hoag NEVER CONSUMES it: the compat bridge declares `den.aspects` as `schema.types.raw` (flake-module.nix:32/64), UNtyped through `aspectsType`, and `_module.args.den = annotatedView config.den` stamps identity via the `__provider` annotate walk. So `__provider` is NOT a redundant shadow of the native key — it is the SOLE identity source for navigated static-includes + projected-hasAspect refs. **The two probes:** (P1) the isolated navigated value a corpus `host.hasAspect den.aspects.core.network.manager` read gets = `{ __provider=[...] }` (no name/meta) → `genKey(stampProvider v)`="core/network/manager" but native `genKey v`="<anon>" → NOT equal. (P2, the sharpener) gen-aspects `flatten` DOES key by container-relative path ("core/network/manager") — but that path is `flatten`'s OUTER key = TREE POSITION; the leaf value's own `aspects.key` is bare ("manager"), and an ISOLATED navigated value (what refKey/grounding get) has LOST its position → NEITHER `aspects.key` NOR `flatten`-on-an-isolated-value reconstructs the path; only a WHOLE-TREE walk can. Deleting `__provider`/`stampProvider` now collapses all navigated-include identity to "<anon>" = the board-#58 corpus-zero-content regression `stampProvider` fixed (forwardExpand keeps first "<anon>" sibling → chains starve → hosts drop from nixosConfigurations); `ci/tests/compat-include-identity.nix` F1-F5 is the standing witness. NO deletable reader subset (6 sites all consume `__provider` for the same missing-native-identity reason). **G2 retires only as a CONSEQUENCE of a dedicated native-identity-consumption phase (spec §5): den-hoag must key navigated includes by a TREE-WALK over the typed/flattened tree (own/walk the tree — type `den.aspects` through `aspectsType` OR flatten-key dedup in its own evalV1), gated behind §7 flake-parts sibling-rebind.** NOT a reader swap. Phase 3 SHIPPED with Task 1 only (commit 5c537a0 on branch feat/projection-graph: deleted dead emission fold + filterRootModules twin + A1 __shared marker, 932 tests green).

**G2 UNBLOCKED — typing verified feasible + §7 gate PROVEN closed (2026-07-14, independent repro).** Round-2 probe (`scratchpad/probe_aident.nix`, reproduced by controller): under gen-aspects @14652a0 (A-IDENT) + gen-merge @2701d8b, typing `den.aspects` via `aspectsType` on the evalV1 path gives navigated `den.aspects.core.network.manager` native `.key="core/network/manager"` (FULL container-relative path) + `meta.aspect-chain=["core" "network"]` STAMPED. §7 sibling-rebind (`with den.aspects`) — the memory's OPEN gate — is CLOSED by binding `config._module.args.aspects = config.den.aspects` (mirrors bridge.nix:497), under the bridge's freeform `anything` den submodule; freeform `den.<custom>` coexists. `id_hash` native-ABSENT (den-hoag-derived either way) — rides as `hashString sha256 ("den-aspect:"+v.key)`, byte-equal to stamp-provider.nix:32-34 since `.key`==the "/"-joined path. PROPOSED mechanism = typing (spec §2 "cleanest if feasible") — but this REVERSES the resume/spec-LOCKED (ii) side-map ruling; PENDING owner ratification (do not treat as settled).

**RE-CORRECTED 2026-07-15b (owner): the GEN-NATIVE SINGLE TREE IS CORRECT; Option 1 was AVOIDANCE, not the answer.** The "Option 1 is correct" conclusion below was ANOTHER instance of dodging the hard gen-native work. Owner: "you've burned millions of tokens trying to find ways to avoid work… steer toward the correct gen-native approach, regardless of cost." THE DECIDING ARGUMENT: the value-injection debt IS "den-hoag reconstructs identity by hand (the __provider walk) instead of riding gen-native." Option 1 KEEPS that walk (re-pointed/inlined — still den-hoag computing identity) → does NOT fix the debt, just relocates the shadow. ONLY the single tree fixes it: compile consumes the TYPED tree → native `.key` is already there → NO walk → __provider/annotate/stamp-provider genuinely DELETED. The 8 shape-interactions were the REAL WORK of riding gen-native, NOT sprawl. **CORRECT ARCHITECTURE:** gen-aspects owns identity typing (native .key) + the general shape mechanism; #8 ROOT CAUSE = a CHANNEL key (den.quirk, e.g. `firewall`) mis-typed as a nested aspect because compat `compileAspectsType` sets `aspectModules=[]`, OMITTING the `channelModules` den-hoag CORE includes (`concern-aspects.nix:81-85`: quirk names → `raw` options). **#8 FIX SCOPE — OWNER RULED SHAPE B 2026-07-15 (NOT the den-hoag-only Shape A below).** The den-hoag-only thread (Shape A: thread `den.quirks` into compat `cnf.aspectModules` raw options) is the expressible-today MINIMUM but bypasses the gen-schema seam — owner REJECTED it in favor of **Shape B (the load-bearing gen-native arc):** gen-schema gains a composer KEY-SEMANTICS declaration surface (extend `mkSchemaOption`/`mkAspectSchema`); gen-aspects `aspectSubmodule` dispatch becomes GENERIC — builds class/channel/facet options from the schema-declared key-semantics INSTEAD of hardcoded `cnf.classes`+facets, SUBSUMING `cnf.classes`; den-hoag adopts `mkAspectSchema` declaring class+channel vocab. Byte-safe: generic dispatch DEFAULTS to today's cnf.classes/facets/freeform when no schema declaration. 3-repo arc → brainstorm→spec→plan→review→execute. The composer-extensibility HOOK exists (`cnf.aspectModules`, gen-schema-fed `mkAspectModule` schema.nix:79-104) but B makes ALL key-categories flow through gen-schema generically (the dependency load-bearing). Rejected: a `cnf.channels` gen-aspects slot (duplicates aspectModules); Shape A (den-hoag-only, bypasses gen-schema); den-hoag stays THIN = pre-filters ONLY its den-specific vocab (policy records `__isPolicy`, malformed `{name;fn}` — these pass the external-user test as den's) then CONSUMES the typed tree for everything else (no raw walk). BASE = Task-B WIP stash `a8e1550` (7 of 8 shapes already gen-native: single-tree wiring + spliceRawPolicies + wrapGatedFn + malformed-detect + gated-accessors + normalize migration + byte-identical class content). REMAINING = fix #8 in gen-aspects + re-land a8e1550 + delete __provider (dead under native typing) + byte-equivalence gate across hosts. wrapGatedFn (gen-aspects c1a783d) = shipped. **MY FAILURE MODE (recorded [[feedback_no_half_measures]]): repeatedly fell back to the easier local Option-1 off-ramp to avoid the harder correct gen-native work, then rationalized it as "correct" — the external-user-test/verification "proving" Option-1 was avoidance-via-rationalization. Accept the sunk cost; do the gen-native work.**

**(SUPERSEDED 2026-07-15b — this "Option 1 correct" conclusion was avoidance) SETTLED 2026-07-15 (verification + owner's external-user test): SINGLE-TREE FORCING WAS THE ERROR; OPTION 1 (compile reads RAW) is the correct architecture.** The whole "compile consumes the single typed tree" arc (below, 2026-07-14) is ABANDONED. Decisive verification: under Option 1 (compile reads the RAW tree, identity native `.key`-first) ALL 8 typed-tree sprawl-interactions (parametric includes, policy records `__isPolicy`, malformed `{name;fn}`, gated-inert, module-fn class content `{firewall,...}:`, etc.) VANISH — 952 CI green + igloo drvPath byte-identical with ZERO special handling (no spliceRawPolicies/malformed-detect/wrapGatedFn/gated-fixes). The 8 interactions were 100% INDUCED by typing the tree compile consumes. **THE PARTITION (owner's test "would an external gen-aspects user want this?"):** gen-aspects already owns the complete general shape-dispatch (types.nix:162-222, arms A–G); `wrapGatedFn` (gen-aspects c1a783d, pushed feat/wrap-gated-fn) was the SOLE upstream-worthy shape + shipped, but is UNUSED by den-hoag under Option 1 (raw includes keep callGated) — it stands as a general gen-aspects capability. Everything else in compile's shape-handling (policy records, malformed-detect, v1-grounding, delivery/effect translation) FAILS the external-user test = irreducible den-v1 VOCABULARY = den-hoag's REASON TO EXIST as the thin compat home; do NOT push it upstream (breaks the zero-den-vocab invariant flake-module.nix:157). den-hoag is THIN = gen libs + legacy compat + batteries; compile is RAW by DESIGN (flake-module.nix:33-39: typing a class body reshapes the delivered bucket). **PHASE-5 COMPLETION = Option 1 + (i) position-thread (owner 2026-07-15):** compile self-computes native identity from its container-relative walk position (pathKey — replacing annotate's __provider walk), retiring __provider/annotate/stamp-provider fully; nav view (typed) stays for navigated identity/hasAspect. Plan: `~/Documents/papers/den-architecture/plans/2026-07-15-option1-position-thread-plan.md`. Base = the 291fb56 prototype (952-green, compile identity native-.key-first, drvPath-identical) — extend with the position-thread for raw top-level records. [[feedback_no_half_measures]] was RE-READ: the "no half-measure" push toward the single tree was itself the over-engineering; the external-user test is the real razor.

**(SUPERSEDED 2026-07-15 — single-tree arc abandoned) CORRECTED 2026-07-14 (later, reconciliation): the "compile cannot consume the typed tree" conclusion below was WRONG — it was a DUAL-WIRING bug, not the value-injection boundary.** Multiple fresh evals proved a `deferredModule` class body crosses to nixpkgs CLEAN + byte-identical (`{imports=[raw]}` opaque; `lib.nixosSystem` gives the SAME toplevel drvPath as the raw body). The `networking.hostName conflicting option types via option svc.nixos` abort was `graftProviders` re-introducing the raw body OVER the deferredModule = a SECOND declaration path (the raw/typed DUAL). Remove the dual → clean. So the SINGLE TYPED TREE (owner-approved 2026-07-14) IS viable, DEN-HOAG WIRING ONLY, NO gen-aspects/gen-types/gen-merge change (`deferredModule` at gen-aspects types.nix:205 already IS the collect-raw-module semantics). Landing = compile consumes ONE typed tree: class content (deferredModule buckets, byte-identical) + identity (native `.key`); remove evalV1Raw/graftProviders/raw-walk/dual; delete __provider/annotate/stamp-provider. BONUS: closes v1 divergence L4 (den-hoag now folds host class content like v1 — an edge the raw walk was DROPPING). TWO HALVES: class-content (done, byte-identical, green) + PARAMETRIC-INCLUDE grounding (compile must consume gen-aspects' `__isWrappedFn` functors instead of raw-wrapping `functionArgs fn` — the typed tree pre-wraps bare-fn includes; in progress, full-surface map underway). Plan: `~/Documents/papers/den-architecture/plans/2026-07-14-den-hoag-phase5-native-identity-plan.md` (TASK 4 — FINAL section). PROCESS: the wrong conclusion below came from a spike that tested a RAW body not a gen-typed one + the dual not removed — [[feedback_no_half_measures]] [[feedback_verify_gate_exit]].

**(SUPERSEDED — kept for the reasoning trail) two hard terminal aborts suggested compile CANNOT consume the typed tree — the raw content walk is value-injection-CORRECT, NOT debt.** Owner pushed for "Option 2" (single typed tree feeds compile = one representation). PROVEN dead by drvPath-gated spike on a real host (igloo): gen-typed class CONTENT cannot cross to nixpkgs. Both cnf variants abort: `cnf.classes=REGISTERED` (deferredModule) → gen-merge's module system DECLARES the nixpkgs options → `networking.hostName has conflicting option types in <gen-merge, via svc.nixos> and <nixpkgs>`; `cnf.classes={}` (freeform) → class key types as a NESTED ASPECT whose structural options pollute the module → `boot.description does not exist`. THE BOUNDARY: gen-merge and nixpkgs cannot both own the option declarations for one class body — content must reach nixpkgs as a RAW VALUE (the gen-flake invariant made concrete). So the two-representation shape is the ARCHITECTURE: **content from the raw tree (nixpkgs owns options), identity from the typed plane (native A-IDENT `.key`)**. compile keeps its raw content walk PERMANENTLY. The earlier byte-equivalence spike was FLAWED (tested a raw body, never gen-typed → missed the double-declaration). **Option 1 is the settled design: retire ONLY the `__provider` IDENTITY shadow (annotate/stamp-provider), repoint compile's identity grounding to native `.key` (from the typed identity view or position), keep the raw content walk.** Single-representation is architecturally impossible, not deferred. `hasAspect` collapses to a single graph-reachability query (`ref.key ∈ node reach-closure`), owner reframe 2026-07-14. Phase-5 plan: `~/Documents/papers/den-architecture/plans/2026-07-14-den-hoag-phase5-native-identity-plan.md` (5 tasks: bump → type → repoint readers/collapse refKey PROBE-gated → delete annotate.nix+stamp-provider.nix → docs). PROCESS NOTE: initially built the plan on the spike verdict UNVERIFIED — corrected by independent repro (treat agent verdicts as hypotheses, [[feedback_verify_gate_exit]]).

Design review: `~/Documents/papers/den-architecture/specs/2026-07-13-den-hoag-identity-and-module-integration-design-review.md` (§5b/§5c INVERT-as-protocol was WRONG; the value-injection redesign supersedes). Links [[project_den_hoag_features]] [[project_hoag_architecture]] [[reference_gen_docs]] [[project_projected_hasaspect]].

──────── archive-project_den_homemanager_quirk_reemit.md ────────
---
name: den-homemanager-quirk-reemit
description: RESOLVED 2026-06-02 — home-extraction quirk re-fire fixed by general spawnNode unification (PR #589), SHIPPED via #563
metadata:
  node_type: memory
  type: project
  originSessionId: 0f6b0e2d-6fcb-441f-804f-0644abe8ccce
---

RESOLVED 2026-06-02 via home-extraction unification (`spawnNode` + resolve-at-emitting-node). PR #589 + SHIPPED via #563. Spec: papers `specs/2026-06-02-home-extraction-unification-design.md`.

**Bug:** hm extraction re-processed host aspect tree at USER scope → host-class parametric quirk emits (`host-addrs = {environment,host,...}:`) re-fired there, resolved against user ctx lacking `environment` → raw lambda → crashed `apps/ssh` hm ("expected set found function"). Even resolved, home consumer saw only local host, never fleet peers.

**Fix (more general than planned "suppress emissions"):**
- `spawnNode` (`fx/spawn-node.nix`) = GENERAL primitive: materializes child resolution node from any parent scope, threaded w/ parent's RAW scope-tree state (parent+siblings), runs own `assemblePipes` → consumer inherits host's fleet-collected value, collectAll sees peers. = den-hoag `spawn`; home extraction = first consumer.
- resolve-at-emitting-node (`assemble-pipes`): pipeline-parametric emits resolve to concrete data on collected+exposed crossings (config-dependent stay deferred) → no raw lambda crosses edge.
- `ancestorBoundPipe` strip in spawn-node: strips policy-bound pipe names from re-walk → consumer INHERITS not re-emits self-only (precise re-fire fix).
- chainCtx workaround REMOVED (environment now via threaded state).

**Verified** nix-config: 7 hosts eval native; blade/cortex home ssh lists every peer; `resolved-users` non-empty (`pipe.from "resolved-users" [pipe.expose]` at `den.schema.user.includes` = bottom-up dual). Related [[project_settings_stratification]], [[project_hoag_architecture]].

──────── archive-project_den_rewrite_migrator.md ────────
---
name: project-den-rewrite-migrator
description: "den-rewrite migrator concept — OpenRewrite-style source codemod for structural den schema changes, proven 2026-06-10"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3219f2b2-5679-472a-affc-ad1761430384
---

Den is zero-ver → breaks API freely toward 1.0, NO runtime compat shims. Structural schema changes instead ship a **recipe** that mechanically rewrites user source (OpenRewrite/SBM model): den's evaluator supplies semantic attribution (which construct + exact source position), rewrite is a surgical format-preserving edit.

**Concept PROVEN 2026-06-10** (slice, 5/5 tests green). NOT on main — parked on reference branch **`ref/den-rewrite-migrator-spike`** @ commit `1620f185` (main kept clean). To resume: `git checkout ref/den-rewrite-migrator-spike`.
- Lib: `nix/lib/migrate.nix` → `den.lib.migrate.{attributeProvideKeys, applyEdits, validateEdits, renameUnderscoreToProvides}`. Registered in `nix/lib/default.nix`.
- Tests: `templates/ci/modules/features/migrator-spike.nix` (suite `migrator-spike`).

**Attribution oracle** (load-bearing, de-risked): `options.den.definitionsWithLocations[].value.aspects.<name>` = raw user attrset pre-merge; `builtins.unsafeGetAttrPos "_" asp` → `{file,line,column}`. NOT `config.den.aspects` (submodule-merged, position dead). `den` is ONE submodule option, so oracle is `options.den.definitionsWithLocations` (aspects nested under `.value.aspects`).

**Critical partition** (the honest boundary):
- *literal-attrset* key `x = { _ = …; }` → **exact `_` token position**, rewritable.
- *attrpath* key `x._.y = …` → non-null but points at **statement start** (`den`), NOT the `_` token. `validateEdits` checks source byte == `from`, routes mismatches to `needsLocalization` = Tier-2.

**Three-tier attribution** (Vic/user's design): T1 eval+unsafeGetAttrPos (exact, ~80%); T2 eval include-chain identity → tree-sitter localizes token within the eval-known statement (covers attrpath + cross-file merge); T3 pure tree-sitter+report (computed `${k}` keys — no token to localize). Trace entries carry identity even for anon nodes (`host/resolve(desktop):provider`) → T2 anchor.

**Verification oracle** (den's edge over SBM): for a pure-rename recipe, resolved model must be identical before/after. `_`≡`provides` (both structural keys, `_` aliases provides) → rename is provably behavior-safe via re-eval. Stronger than OpenRewrite's re-type-check.

Substrate choice for real rewriter: prefer `rnix`/`rowan` (statix-proven lossless) over tree-sitter/ast-grep. Next: lift attribution to a CLI driver, more recipes (hosts.<sys>.<host> reparent, attrset→setOf ref decompose), wire T2 tree-sitter localization. Relates to [[hoag-architecture]] (v2 primitive vocab is the precondition for clean recipe lowering).

──────── archive-project_den_server_lsp_mcp.md ────────
---
name: project_den_server_lsp_mcp
description: "den-aware LSP+MCP tooling scoping; one engine two frontends, MCP-first; DG-A CLEARED"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1ff5e031-7f73-4449-9c1b-e13e47c0123f
---

den-aware language tooling — extend Nix LSP/MCP to understand den options, aspects, gen libs, policy, native graphs.

**Design authority:** spec `papers/den-architecture/specs/2026-07-20-den-aware-lsp-gen-policy-graph-scoping-design.md` + roadmap `papers/den-architecture/plans/2026-07-21-den-server-delivery-roadmap.md`. Public (sanitized) gist: gist.github.com/sini/4479742ba96be2de9992d87ba8f1768f (strip host names + eval figures on any refresh). **Gist is BEHIND canonical spec by the DG-A edits (owner chose leave-as-is 2026-07-21; resync at a milestone boundary).**

**Architecture:** ONE shared query engine, TWO thin frontends (LSP position-shaped, MCP question-shaped) — rust-analyzer pattern. Built **MCP-first**: MCP dodges the ~200ms interactive-latency wall (agent tolerates 5-30s), so resolved-state (killer feature) ships on the short path; LSP interactivity is deferred polish. Spine = E0 (external/cached-once, vanilla nixd) vs E2 (live/resolved, needs vehicle) seam. nixd is E0 by construction (`AttrSetProvider.h:13-16` cache-once, never invalidates).

**Milestones (roadmap):** DG-A probe → M1 projection lib (Gate0/1, E0, stock nixd) → M2 MCP enum → M3 accessor idioms (Gate1b, first C++, upstreamable) ══seam══ M4 shared query engine (Gate2, the pivot) → M5 MCP frontend (resolve/check/impact/migrate/where, killer feature) · M6 graph tools (Gate4, needs DG-C reflection API) · M7 LSP frontend (Gate3/4/5, gated by DG-B latency spike). Gates 0-5 defined in spec.

**✓ DG-A CLEARED 2026-07-21 — PASS, no type-mapping shim.** Runtime eval (scratchpad/dga-probe.nix): gen-types/gen-merge is byte-compatible-shaped with nixpkgs `lib.types` (same relation hola has w/ evalModules). `types.int` carries name/description/check/merge/getSubOptions/nestedTypes; `mkOption` emits `_type=="option"` w/ {_type,type,description,default}; submodule→getSubOptions; listOf/attrsOf→nestedTypes.elemType. Refined types = `baseType // {__schema=…}` (`gen-schema/lib/refined.nix:7`), forward all lib.types fields. So nixd's generic option worker walks gen-schema option trees ZERO-shim. `gen-schema/lib/bridge.nix` = existing record→NixOS-module emitter (`emitModule`). **Carried item:** goto needs `declarationPositions` — gen-merge records file-level `_file` only (`modules.nix:51`), NOT the position triple; M1 attaches via den's `unsafeGetAttrPos` attribution (den-rewrite migrator) or surfaces from gen-merge. complete/hover/docs/enum need none of it; M2 zero position dep.

**den-hoag dependency:** none for cheap tier (v1 declaration surface); engine tier consumes `node.query` — already live (4/6 STEP-5 sub-arcs shipped, see [[project_den_hoag_features]]). Bind to node.query + `.fn.` accessor; pace with v2, don't wait.

**◐ DG-C PARTIAL PASS 2026-07-21** (source read gen-graph @d110703): reflection/query API PRESENT, zero gen-graph change — graph = `{nodes,edges,parent,nodeData}` (`registry.nix` fromRegistry/mkGraph), enumerate via nodes/labeledEdges/roots/leaves/select, query via query/queryAll/queryPaths (Brzozowski 5 modes) + impactOf/transpose/dependents. M6 tools map direct (den.graph.query→query, neighbors→labeledEdges, impact→impactOf). BUT source positions ABSENT (grep zero) → nav-to-source needs same unsafeGetAttrPos layer as DG-A goto.

**★ CROSS-CUTTING:** gen values (option nodes + graph nodes) carry types/ids/data NOT positions. Positions = uniformly den `unsafeGetAttrPos` attribution, spanning E0 options + E2 graph. **NET-NEW on main, NOT reuse** — den-rewrite migrator (proved technique) is OFF-MAIN @1620f185; main has file-level `_file` only. Build ONE shared position-attribution layer in M1 (fresh unsafeGetAttrPos over PRE-MERGE raw config, add a seam; or accept file-level goto); goto (M1/M7) + graph-nav-to-source (M6/M7) draw from it. = spec's position→resolved-node spine, both surfaces.

**den-map (den-hoag @aed1044, 2026-07-21) — M1 build map:** new lib `den-hoag/lib/lsp/options-projection.nix` → import in `lib/default.nix` let → re-export `lsp=…` (auto via migrationLib). Namespace under `lsp` ("projection" overloaded: class projection merged, projects facet, attributes/). den options are gen-merge modules — leaves ALREADY `_type=="option"` (gen-merge/lib/types.nix:39); `evalModuleTree` ALREADY yields `.options` (modules.nix:1131). Projection = RE-KEY tree.options via `schema.isOptionDecl`+`stripRefinements` (NOT bridge.emitModule — uncalled in den). SEAM: entity.build/mkDen DISCARD tree.options (entity.nix:165-179) → M1 exposes (passthrough or hoist ~40 static concern decls default.nix:294-721). Aspects: `ent.config.den.aspects` keyed by name; settings = `{default;merge}` records NOT mkOption → synthesis. gen libs via `den.lib.internal.*` = flat FN attrsets, NO type metadata → Gate 1 thinner (names+functionArgs+doc citations only, not signatures). lib/** nixpkgs-lib-free. Tests = nix-unit `nix-unit --flake ./ci#tests.<suite>`. nixd target = `inputs.den.lib.lsp.optionsProjection`.

**Discovery-tracking discipline (owner directive 2026-07-21):** every probe/investigation discovery goes into BOTH canonical spec + roadmap (not just memory/chat). Gist is public sanitized mirror — currently BEHIND, resync at milestone.

**◑ DG-B LEANS PASS 2026-07-21** (source + timing sweep scratchpad/dgb-fleet.nix): den resolution is SCOPABLE per-node → fatal "every query forces whole 36s fleet" risk REFUTED. Proof: (1) laziness — `den.output.outputFor <id>` resolves one node despite sibling `builtins.throw` (end-to-end.nix:132-136); (2) timing — `outputFor "host:h0"` (mode=one) FLAT ~57-66ms across fleet N=5→500 even w/ heavy per-node content, while whole-fleet (mode=all) scales (555ms@N=500). deepSeq'd-eager hazard confined to `den.outputs`/`den.collectors` validation TABLE (default.nix:2016-2027), NOT outputFor. **ENGINE RULE: resolve via `output.outputFor <id>`, NEVER force outputs table.** Residual = absolute per-node latency on a REAL heavy fleet (deferred nixd-fork spike; synthetic proved scaling not weight); `resolveEntity` STUBBED on main (flake.nix:197, board #49/#50) → engine drives outputFor/node.query directly.

**★ ALL 3 PROBES READ OUT, NONE FATAL:** DG-A ✓ PASS · DG-C ◐ partial (query API present) · DG-B ◑ leans-pass (scopable). Cheap tier (M1-M3) + engine/MCP tier (M4-M5) clear to plan+build; only absolute real-fleet latency (DG-B residual) gates LSP interactivity (M7), MCP tolerant.

**✓ M1 PLAN WRITTEN + REVIEWED 2026-07-21** (`plans/2026-07-21-den-server-m1-projection-plan.md` + `.tasks.json`, papers-archive; commits through a9aca07). 7 tasks T1-T7: T1 expose discarded tree.options+provenance from entity.build (entity.nix:164-179) → T2 re-key projection → T3 aspect registry (settings synthesis, projects INSTANCES not catalog) → T4 gen-lib surface (19-name allowlist, no type metadata) → T5 shared position layer → T6 laziness+wiring → T7 M2 enum. Independent review found 1 blocking + 5 advisory, ALL applied. Grounded on den-hoag af2d7b3.

**★ GOTCHA (durable, verified af2d7b3):** gen-schema does NOT export `stripRefinements` (private let bridge.nix:15) NOR `isOptionDecl` on its public surface (default.nix:84 exports only emitModule; :26 passes isOptionDecl INTO entry-type.nix). Any consumer needing them must INLINE (builtins-only): `isOptionDecl = v: builtins.isAttrs v && v?_type && v._type=="option"`; `stripRefinements = t: if t?__schema && t.__schema?refinements then t.__schema.baseType else t`. den-hoag `internal` (default.nix:2335-2484) mixes 19 gen libs w/ ~30 helpers → filter by explicit allowlist.

**✓ M1 PROJECTION CORE SHIPPED 2026-07-21** (den-hoag branch `lsp-m1` `89e6947`→`cabeb9d`, 6 commits, subagent-driven + two-stage reviewed each). Full suite 1593/1593, parity byte-identical. `den.lib.lsp` = optionsProjection/aspectsProjection/genLibProjection/positions/forNixd (pure builtins). T7 (Rust MCP enum, drives customer's nix) IN FLIGHT. Worktree `.worktrees/lsp-m1`.

**★ POSITIONS = FULL LINE/COL (T5 overturned the CROSS-CUTTING net-new/file-level assumption above).** gen-merge MERGED option leaf PRESERVES mkOption field source positions → `unsafeGetAttrPos "type" den._options.den.membership` = {lib/default.nix;331;11} DIRECTLY. No pre-merge threading, no hoisting, den-rewrite migrator MOOT. `den.lib.lsp.positions` = shared generic layer, true goto; M6/M7 reuse. T3: `den.aspects` proven fx-pipeline-free. T4: gen-lib doc-citations DEFERRED (READMEs unreachable from pure lib values, need source paths threaded).

**★★ MULTI-INTERPRETER SERVICE REFRAME 2026-07-21 (owner, LOAD-BEARING):** den-server = SERVICE for den customers on ANY nix interpreter (CppNix/Lix/other), NOT owner's single fleet. → agnosticism HARD req → eval boundary = PLUGGABLE backend (render-evaluator-seam): (a) default = drive customer's own `nix` subprocess (always build-accurate), (b) optional per-interpreter warm C++ eval worker (built vs customer libexpr; CppNix/Lix≈one worker two builds) over JSON-RPC for interactivity. Agnosticism at PROTOCOL boundary → controller/frontends language-DECOUPLED → **Rust controller LOW-RISK** (no FFI to unstable nix C API; reuse nixd controller↔worker split). Lix = C++ (CppNix fork, adopting rust via cxx) NOT rust; owner keeps Lix re-enable-able nix-config module = multi-interpreter TEST BED; fleet moved Lix→CppNix. libnixf (positions/AST) stays nixd C++. **VEHICLE = Rust controller + Rust LSP/MCP frontends + pluggable eval backend.** Gate-2 spike now 2-way (scoped subprocess vs warm worker) × 2 interpreters (CppNix+Lix).

**✓ M1 COMPLETE — all 7 tasks (T1-T7) shipped + reviewed on `lsp-m1`** (`57630b5`, Rust MCP incl.; T7 approved, 4 minors carried). BUT owner reviewed lsp-mcp + gave 2 architectural corrections: (1) it should be its OWN repo/module **gen-lsp** (gen-tier lib), NOT baked in den-hoag; (2) den-hoag should AUTO-EXPORT it (no explicit forNixd wiring). `lsp-m1` = un-merged PROTOTYPE / extraction source.

**★★ EXTRACTION → gen-lsp (plan WRITTEN+REVIEWED `plans/2026-07-21-gen-lsp-extraction-plan.md` @261599c, papers).** gen-lsp = general LSP/MCP tooling for ANY gen-merge option tree + gen-aspects aspects + gen-libs, interpreter-agnostic; den one consumer. Boundary/tooling lib (like gen-flake), NOT in mkGenLibs. **LIB IS DEP-FREE PURE BUILTINS** (reads value shapes _type==option/keySemantics attrsets, imports nothing; gen-merge/gen-aspects = ci fixtures only; gen-schema not needed). One repo lib+mcp. 8 tasks: A1 scaffold(purity test) → A2 options+positions → A3 aspects REWRITE → A4 genLib+enumerate(derivation-fix) → A5 rust mcp(namespace-parameterized) → A6 docs; B1 den binding → B2 flakeModule auto-export. Plan-review (261599c) fixed 2 blockers.

**★ GOTCHAS (verified, durable):** (1) M1's 3 lib files are options-projection.nix/positions.nix/enumerate.nix — aspects/genLib/forNixd/forNixdJSON ALL live INSIDE options-projection.nix (extraction SPLITS it). (2) `classifyKey` is DEN's fn (concern-aspects.nix:189) NOT gen-aspects; keySemantics = construction-time cnf data on schema (concern-aspects.nix:123-150) NOT on resolved instances → aspect projection needs keySemantics map THREADED IN (den adds `_keySemantics` passthrough); classifier = 1-liner over `.category`. (3) den-hoag main lacks `_options`/`_provenance` (T1 passthrough only on lsp-m1); `den.aspects` already on main. (4) enumerate deepJsonSafe crashes on derivation-valued default (tryEval can't catch stack overflow) → short-circuit `type=="derivation"`.

**✓✓ EXTRACTION COMPLETE + PUBLISHED 2026-07-24** (subagent-driven, all 8 tasks two-stage-reviewed + whole-branch review = SHIP-WITH-FOLLOWUPS). **gen-lsp PUBLISHED `github:sini/gen-lsp` @ `f6f6e9d`** (public, own repo `~/Documents/repos/sini/gen-lsp`): dep-free pure-builtins lib (optionsProjection/positions/aspectsProjection[keySemantics-map-driven]/genLibProjection{libs}/enumerate/forNixd[functions,in-process]/forNixdJSON[wire]) + Rust MCP server (`packages.mcp`, hand-rolled JSON-RPC, drives customer nix, `--namespace`/`--output-attr`, den defaults). gen-lsp lib = ZERO deps (gen-merge/gen-aspects = ci FIXTURES only). Enumerate section keys GENERIC `options/aspects/libs`. **den-hoag `gen-lsp-integration` branch @ `7ed2ab4` MERGE-READY** (off main 44370e8; parity 1847/1847; B1 binding+`_options`/`_provenance`/`_keySemantics` passthroughs, B2 flakeModule auto-exports `den-lsp.{options,enumerate}`+`den-lsp-mcp` from built fleet ZERO-wiring; locks pinned to published gen-lsp). Derivation fix REFRAMED: DEPTH BOUND is the crash-guard (Nix toJSON special-cases drvs → outPath), tag = compact output. Wire-depth: real options submodules don't nest on wire (getSubOptions defers to module fixpoint) → nixd expands in-process; synthesized aspect facets DO expand.

**nix-config gen-lsp-mcp package COMMITTED SOURCE-ONLY** (owner directed 2026-07-24; `5d091b81` on branch `gen-lsp-mcp-package`, NOT merged): 6 files — `modules/flake-parts/gen-lsp.nix` (flake-file input), `pkgs/by-name/gen-lsp-mcp/package.nix` (buildRustPackage, `src="${gen-lsp-src}/mcp"`+cargoLock, HERMETIC), `pkgs/overlays.nix` (gen-lsp-src overlay), devshell entry, `.mcp.json` (stdio server `gen-lsp-mcp --fleet .`), nvf nixd note. flake.nix/lock REVERTED (owner regens) + config.nix MCP-trust reverted (owner's claude-refactor territory). **★ LANDMINE (owner finalizes): `nix run .#write-flake` DROPS the hm fork pin `github:sini/home-manager/fix/syncthing-unix-socket-host` (lives ONLY in hand-edited flake.nix commit 08fb72c7, NOT flake-file source) → must move hm pin INTO flake-file source first** [[project_replicated_home_syncthing]]. Owner had uncommitted claude/llm-agents refactor (package.nix D, claude.nix/llm-agents.nix/mcp/ untracked) — PRESERVED untouched; subagent worked in main checkout not worktree (use worktree next). nix-config pins `den=github:denful/den` NOT sini/den-hoag → full den-lsp.{options,enumerate} auto-export needs den propagation (den-hoag branch→denful/den→den pin bump). Inputs via flake-file.inputs.<name>+`nix run .#write-flake`; pkgs via pkgs/by-name+overlays.nix `{inputs}`; `nix fmt` not treefmt; linear history.

**NEXT:** finish nix-config package → PR. Merge den-hoag gen-lsp-integration (owner decision) + retire lsp-m1 prototype. Propagate den-hoag→denful/den for the full nix-config den-lsp auto-export. Engine tier (M4, resolved state) = FUTURE at Gate-2 pluggable-backend spike (subprocess vs warm worker × CppNix+Lix). Tracks productions-substrate pivot [[project_den_hoag_features]].

Related: [[project_den_architecture]] [[project_gen_package]] [[reference_gen_lib_capability_map]] [[project_hola_engine]] [[project_gen_graph_labeled_query]] [[project_den_rewrite_migrator]]

──────── archive-project_den_spawn_route_fix.md ────────
---
name: den-spawn-route-fix
description: gpg pinentry vanished — two den bugs (spawn route propagation + multi-def identity loss) SHIPPED via #563 + upstreamed #603; lesson on dropping cherry-picks
metadata:
  node_type: memory
  type: project
  originSessionId: 3a75589f-3e16-4861-b54f-8d4b27aef9d5
---

SHIPPED (via #563 bundle; also upstreamed PR denful/den#603 alongside sibling policy.when guard dedup). Cortex gpg pinentry regression 2026-06-09 = two den bugs:

1. **Spawn route propagation** (`fix(spawn)` d1968b5b): `policy.route` at user scope via `den.schema.user.includes` never applied in spawnNode per-user re-resolution → host-attached aspect homeLinux content dropped, never worked since classes landed 05-23. Fix: thread parent `scopedRoutes` into spawn phase3, filter to spawn subtree, dedup by route key. Test `route-platform-class-host-aspect`.
2. **Multi-def identity loss** (`fix(types)` 8e649849): navigating `apps.dev.security.gpg` w/ two files defining `apps.dev.security.*` returned raw children (no name/__provider) → anon identity per inclusion path → double emit → equal-priority conflict. Affects depth≥4 under multi-def keys. Fix: recursive `annotateDeep` in aspectContentType multi-def branch (name guards BEFORE isAttrs force, #580 discipline). Test `multi-def-namespace-identity`.

Trigger = nix-config 1997b2fe moving pinentry gpg→homeLinux (latent delivery gap).

**`self` guard caveat:** branch carried `feat(policy): add self guard` (`{self,...}:` fires once at registration scope; flake-scope policies fire since self always in ctx). Rebase dropped it as "squashed upstream" but #603 didn't cover it → silently vanished → nix-config flake→fleet→env→host walk produced ZERO host outputs. RESTORED @01e203be. **Lesson: before dropping cherry-picks as "upstreamed", match code hunks not just test files/PR titles.** See [[feedback_relationship_guards]].

**How to apply:** hm delivery for user = spawnNode collecting class=homeManager only; other-class content must route at user scope (works now). Host-aspect hm reaches only users including `den._.host-aspects`; collected-vs-spawn short-circuit (getCollectedSource) = users w/ own hm content skip spawn. Related [[den-homemanager-quirk-reemit]], [[regression-pattern]].

──────── archive-project_den_v2_terminal_classes.md ────────
---
name: project_den_v2_terminal_classes
description: den v2 API decision — classes are TERMINAL (gen-aspects model, diverges from v1 navigable classes); flake-output classes (apps/packages/checks/devShells/legacyPackages) are an OPT-IN feature (den.features.flakeOutputClasses, default off), NOT a global default
metadata:
  node_type: memory
  type: project
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner decision 2026-07-24 (den-hoag, path **D**): **den v2 classes are TERMINAL** — a class-keyed node is opaque leaf content, you do NOT navigate INTO it (gen-aspects' model). This is a CONSCIOUS DIVERGENCE from den v1, which made class keys NAVIGABLE.

**The v1 facts (source-verified, pin 11866c16 — both common recollections are WRONG):**
- v1 DOES register `apps`/`packages`/`checks`/`devShells`/`legacyPackages` as `den.classes` GLOBALLY-BY-DEFAULT, UNGATED (`nix/flakeModule.nix:3` imports every `../modules/*.nix` unconditionally → `modules/policies/flake.nix:41` `den.classes = listToAttrs (map … systemOutputs)`; comment "Register system output names as classes so aspect keys dispatch correctly"). den-hoag `builtins.nix:539` faithfully matched.
- v1 classes are NAVIGABLE, not terminal — `nix/lib/aspects/types.nix:401` comment verbatim: "nested attribute access works (e.g. `gloom.apps.polybar.razermon`)"; `aspectContentType` (:404) forwards sub-keys + returns `… // annotatedMerged // {__contentValues;…}` to preserve deep nested access UNDER class keys. "Classes are terminal" is GEN-ASPECTS', not v1's.

**The trigger:** user hit `error: attribute 'karabiner' missing` evaluating a darwin host — `macos.apps.karabiner` (bootstrap role includes) — because `apps` (flake-output class, corpus-INERT, emission unbuilt/board-#51) globally shadows the `macos/apps/` namespace directory; gen-aspects types the class-keyed `macos.apps` as an opaque deferredModule → drops karabiner/raycast.

**The FIX = path D (feature-gate, NOT nav-typing):** gate the `builtins.nix:539` flake-output-class registration behind `den.features.flakeOutputClasses` (default **OFF**) + a removability gate (per [[feedback_feature_flags_removability]] / [[feedback_route_through_gen_native]]). OFF ⇒ the 5 names are NOT reserved classes ⇒ `macos.apps` is a NATIVE namespace ⇒ karabiner navigates natively (NO splice, NO looksLike, NO working-around-terminal). ON ⇒ register + provision v1's `mkOutputPolicy` routes (the emission — folds into board #51, currently unbuilt). Parity-safe (the 5 classes are 100% corpus-inert; de-registering an inert class emits nothing different; parity oracle stays green). Compat-only, no kernel touch.

**REJECTED — path A (v1-faithful navigable classes):** reproduce v1's `aspectContentType` annotatedMerged (navigable children on class-keyed values). It's the v1-FAITHFUL fix + handles the GENERAL navigable-class collision (any fleet using v1's navigable-class-nesting, e.g. `gloom.apps.polybar.razermon`). But the owner CUT v1's navigable-classes in v2 (terminal is the v2 model, cleaner). Cost of A-as-opt-in ≈ 2–2.5× D (the annotatedMerged nav-splice is the bigger piece). NOT built — the only realistic navigable-class use is flake-output names as namespaces, which D's de-registration covers; a genuine non-flake-output class name used as a namespace doesn't occur (nixos/darwin/homeManager/flake-parts are never namespace dirs).

**Also REJECTED — the `looksLike`/`looksNested`/`looksLikeClassContent` reclassify (path B):** empirically UNSOUND — no structural predicate separates a namespace (`macos.apps`) from class content (`nixos.networking.firewall`, 36 corpus bodies, structurally identical attrs→attrs→registered-key); any predicate catching one catches the other → drops real class content. Owner explicitly rejects the looksLike anti-pattern.

STATUS: plan `plans/2026-07-24-flakeoutput-class-gate-plan.md`; plan-review → implement. The board-#51 flake-output EMISSION (the ON-path) stays future/unbuilt. Links [[project_den_hoag_features]] [[feedback_feature_flags_removability]] [[feedback_route_through_gen_native]] [[project_gen_aspects_reserved_keys]].

──────── archive-project_entity_isolation_fix.md ────────
---
name: entity-isolation-fix
description: den entity-isolation-aware extraction SHIPPED 2026-06-11 (@ e28bc784, via #563); nix-config bump done PR #114
metadata:
  node_type: memory
  type: project
  originSessionId: 156f4680-67d4-4dfc-aa9a-1a5d1e5df7c4
---

Entity-isolation-aware extraction SHIPPED 2026-06-11 @ e28bc784 (now in main via #563). Plan: papers `plans/2026-06-11-entity-isolation-aware-extraction-plan.md`.

**Mechanism:** `den.schema.<kind>.isolated` collection → push-scope `scopeIsolated` map → both subtree walks (extractSubtreeModules, collectFromSubtree) skip isolated descendants, root exempt. Route field `appendToParent = true` appends at `scopeParent.${sourceScopeId}` (registered guest-side via resolve.to.withIncludes — no collectScopeId fallback). delivered-guest kind: class = honest nixos, guest-os class DROPPED, standard hm battery covers guest (hmDefault), guestHmUserForward bridge kept (simple routes read pre-route per-scope state).

nix-config bump DONE PR #114 (den input → @160ac445, contains e28bc784 + hasAspect projected-scope fix). Guest policy later moved OUT of den core → nix-config — see [[project_delivered_child_route_fix]]. Related [[project_projected_hasaspect]], [[project_delivery_edge_unification]].

──────── archive-project_entity_registry_uniform.md ────────
---
name: entity-registry-uniform
description: den entities → full gen-schema registries design (r5); partitioned-registry primitive; refs are dead-on-arrival; per-host classes carve-out
metadata: 
  node_type: memory
  type: project
  originSessionId: 8ff01839-29bf-4e40-8985-86a3388d0b9c
---

Design (2026-06-10, feat/entity-gen-schema-port) to make **all den entities full gen-schema registries**. Converged at r5 after 4 adversarial review rounds (workflow-driven). Two specs in `~/Documents/papers/den-architecture/specs/`: `2026-06-10-gen-schema-partitioned-registry-design.md` + `2026-06-10-flat-entity-registries-and-refs-design.md`.

**Goal (corrected): registries for `id_hash`/validation/type-checking/methods/codec — NOT refs.** The original "make host/user references into refs" framing was wrong twice over: (1) `_refEdges` is unread in den AND the v2 spec (grep: zero hits) — v2 builds I-edges as computed `imports` attrs, `buildRoots` reads the parent DAG, never refs; (2) `home.user`/`home.host` refs don't even *fire* — `config.resolved` forces them at eval-time but gen-schema ref coercion is apply-time. So home user/host stay **direct name-lookups (bindings)**.

**Model (r5):**
- `den.users` = flat `mkInstanceRegistry` (canonical identity pool, replaces nix-config/fleet-demo's `den.users.registry`). Host-free identity; **no `classes`**.
- `den.hosts` AND `den.homes` = **partitioned** registries (`partition = "system"`) — both two-level-by-system today; flat would silently emit zero configs + crash `den.systems`. Two-level reads unchanged + `_all` flat union.
- `user.parent="host"`/`home.parent="host"` **KEPT** — kind-DAG fact `buildRoots` needs (`_roots`/orphan/termination). Users-as-identities is a pool+spawn concern one layer up; making user a root kind is unsound in v2.
- `host.users` survives as an **attachment**: identity-link-by-name to `den.users` + per-`(host,user)` **`classes`** (structural selection read off the user instance at 9 sites — `host-aspects.nix:24 spawn{classes=user.classes}`; CANNOT be a policy). Spawn source for `host-to-users`.
- Per-host user **aspect-body** → `(host,user)`-scoped policy include (lossless); per-host **`classes`** → stays on `host.users`.

**gen-schema `partition` primitive (new, standalone deliverable):** `partition` is the ONLY new `mkInstanceRegistry` arg (validators/methods are kind collections, NOT args — closed arg set). Partition field injected via per-partition inner-type **factory** at eval-time (`partitionValue: mkInstanceType … options.<field>.default = partitionValue`, mirroring den's `hostType = system:`) so `id_hash` sees it. `applyPipeline` flattens→checks-name-uniqueness-before-flatten→runs validate/derive→regroups by **captured input key** (not the injected field — preprocessHosts strips it). `_all` = `_`-prefixed flat union (ref target; clean `attrNames`, no D2 overlay pollution). OPEN: does `den.homes` need `_all` at all (same-user standalone homes on 2 systems collide; home-intoattr-collision deadbug) → `_all`/uniqueness likely opt-in per registry.

**The rnix migrator** (separate track, user exploring): consumer-source codemod for literal renames (`den.users.registry`→`den.users`, `@`-home keys, body→policy). CST without type-attribution → CANNOT follow dynamic reads (`registry.${name}`, `... or {}`, `diagrams.nix` folds) → those by hand. It does NOT change architecture: D1 (refs)/D4 (parent DAG) are den-internal, unreachable by a consumer codemod. "We can migrate consumers" is never an input to the entity-model decision.

Related: [[project_gen_entity_port]] (the earlier mkInstanceType port this builds on), [[project_hoag_architecture]] (den-v2), [[project_den_spawn_route_fix]] (self-guard, used by the per-host-user policy).

──────── archive-project_hoag_architecture.md ────────
---
name: hoag-pipeline-architecture-decision
description: "Den v2 spec at gen-specs/den-hoag/REFERENCE.md. Demand-driven HOAG via lib.fix, 8 gen libraries shipped. Two open gaps (2026-05-29): per-class output assembly config (#6/#8) and scope linking (#7/#9)."
metadata: 
  node_type: memory
  type: project
  originSessionId: 7763d796-2d93-4fa4-a3c0-212db68aa951
---

**[SUPERSEDED AS THE CURRENT SPEC (2026-07-17): the canonical design is now
`specs/2026-07-16-den-hoag-unified-link-merge-vocabulary-design.md` (typed edges, receivers,
nest modes, families/root — steps 1-4c-i SHIPPED). The R2 spec + the spawn/edge/drop/reroute
verb set below are HISTORICAL. What remains LIVE here: the §B6 analysis (S1 derived attributes /
S2 relations+closure / S3 collection disciplines, the capability-restricted accessor ruling,
acl+settings as A/B parity oracles) — that IS the grounding material for vocabulary STEP 5
(resolution facet).]**

Den v2 reference spec: `~/Documents/papers/den-architecture/gen-specs/den-hoag/REFERENCE.md`
Issues tracker: `~/Documents/papers/den-architecture/gen-specs/den-hoag/ISSUES.md`
Original spec: `~/Documents/papers/den-architecture/specs/2026-05-24-den-v2-hoag-architecture.md`

**Key decisions (2026-05-24 session):**

- One policy namespace, three effect vocabularies (structural/resolution/pipe)
- Graph-native vocabulary: scope, edge, drop, reroute, inject, pipe.*
- Demand-driven via lib.fix, 12 lazy attribute definitions, ~1,010-1,530 lines replacing ~7,000
- neededBy reverse edges, policy.when phase routing, parametrics resolved inline

**Open design gaps (2026-05-29, captured in ISSUES.md #6-7, REFERENCE.md Open Questions #8-9):**

- **#6/#8 Per-class output assembly config.** evalModules is universal (same lib.evalModules everywhere). The gap is not "different module systems" — it's that class registration has no properties for validator behavior, merge strategy, or instantiation function. Proposed: `den.classes.<name>.wrap` carries config, `emit` carries per-entity instantiation function and output path.

- **#7/#9 Scope linking without re-resolution.** resolve.to re-resolves the entity. The spec's `edge` effect needs defined semantics for linking already-resolved entities.

**How to apply:** Both captured in REFERENCE.md and ISSUES.md. The evalModules universality insight means the fix is smaller than initially thought — class-level wrap config + generic output assembly dispatch, not per-target module system handling.

**Current spec is R2: `specs/2026-06-09-den-v2-hoag-architecture-r2.md`** (1099→~1200 lines after §B6).

**§B6 user-extensibility added 2026-06-14 (commit c534974), source-validated (gen-scope 7e301a5, gen-schema c072f76, gen-aspects 146389e).** Motivation: nix-config `modules/den/scope-engine/{acl.nix,settings.nix}` reach PAST den into a PARALLEL `inputs.scope-engine` instance because den surfaces neither user attributes nor custom-edge closure. Three extension surfaces make them native (consumers = acl + settings ONLY; the claims engine is NOT a consumer — plain Nix + existing collections):
- **S1 schema-attached derived attributes** `den.schema.<kind>.attributes.<name>={stratum;fn}` — den folds into genScope.eval attribute set; gen-scope merges name-agnostically (eval.nix:24-38 wrapChild, get dispatches on `attributes ? name`). RESOLUTION/COLLECTION stratum only (structure stays den-closed). **NO lib change.**
- **S2 `den.relations.<name>`** custom edges (buildNodes edgeGraphs, build-nodes.nix:17,66-83) + closure. **Closure ALREADY SHIPPED in gen-graph** (`reachableFrom : {edges,...}->id->[id]`, accessor-based, C-level BFS, zero gen-scope dep by design) — den wires `gen-graph.reachableFrom {edges=id: followEdge label self id}`. acl.nix:123 hand-rolls transitiveGroups ONLY because it uses gen-scope alone, never gen-graph. **NO lib change** (correction ceb84bc — the reviewer agent's "~12-line gen-scope transitiveEdge" was WRONG, read gen-scope in isolation, missed the dedicated graph-query lib; user caught it). Architectural split: gen-scope owns edge DATA+evaluator, gen-graph owns closure/reachability QUERY. `target=annotation|imports` field classifies stratum (imports→structural, gated §B2).
- **S3 pluggable collection disciplines** — collectionAttr takes arbitrary combine (resolve.nix:255), shadow shipped+associative (resolve.nix:11). `shadow-cascade` is a DISTINCT discipline (collapses by key), NEVER a drop-in for ordered-list. **NO lib change.**

**HONESTY GATES (validated, do NOT overclaim):** paramAttr/attribute bodies are opaque closures → NO definition-time stratum verification of BODIES; a resolution-stratum attr reading sibling/descendant resolution attrs is unsound + UNVERIFIABLE (Nix infinite-recursion abort is the only backstop). Structural stratum IS fully protected (user attrs can't be structural). Stratum classifier is NEW den machinery (~validateDisciplines shape), not "free/existing." Open Question #7 RESOLVED 2026-06-14 (commit 9fdfc80) = **capability-restricted accessor**: user resolution/collection attrs get a `self` whose `get` allows structural reads on any node but resolution/collection reads only on self+ancestors+own-imports (the EXACT discipline built-in resolution attrs follow — received-collections reads imports, resolved-aspects reads ancestors, settings.nix:100-106 reads imported resolvedSettings, sound by I-edge DAG). Illegal cross-node resolution read THROWS at access site, named. Key insight: the agent's "any sibling/descendant resolution read is unsound" was too strong — settings ALREADY reads cross-import resolution safely; the real discipline = read cross-node resolution only along imports+ancestors. Den-side guarded self.get proxy `attributes.<name> = self: id: userFn (restrict self id) id`, ZERO lib change. Residual = same-node attr acyclicity (Nix-caught, SAME as built-in 12). Runtime not definition-time (impossible for opaque closures). NOT static declared-reads (can't check opaque body), NOT convention+abort (misses non-cycling illegal reads). paramAttr (resolve.nix:225) = plain 3-curry, (self,id) memoized, per-param body re-runs; acl 2-arg resolveUser = paramAttr + hand-curry. **§B6 needs ZERO library changes** — all primitives ship across gen-scope (open attrs, edgeGraphs/followEdge, collectionAttr combine, shadow) + gen-graph (reachableFrom closure). Scope = ~120-200 den wiring lines only. acl.nix/settings.nix outputs = A/B parity oracles. See [[project_claim_provide_engine]].

──────── archive-project_hola_engine.md ────────
---
name: project_hola_engine
description: hola engine arm — parity harness + E1/E2a/E2b byte-identical evalModules ownership; SHIPPED record
metadata: 
  node_type: memory
  type: project
  originSessionId: c7f8a476-8d5f-4e59-970d-56938cc4eb7b
---

The hola engine arm = **byte-identical evalModules ownership in pure Nix** (the validated substrate the perf work rides on). Public repo **github:sini/hola @de5b21d**. Parity harness + E1+E2a+E2b ALL SHIPPED+PUSHED. Hub: [[project_hola]]. Perf conclusions: [[project_hola_perf]]. Specs/plans: papers `~/Documents/papers/hola-architecture/specs/2026-06-24-hola-engine-{e1,e2a,e2b}*` + `2026-06-23-parity-harness-design.md`.

**PARITY HARNESS** (Phase 4 increment 1) — 4-concern lib: `parity` (oracle: diff/diffAt/locate/drvPathGate/expectThrow — structural order-sensitive throw-robust value diff + drvPath string-identity), `adapter` (engines RECORD `{lib;evalModules}`, run/runHost), `corpus` (synthetic/4 hc3-landmines/real-host/floor), `compose` (valueEq/drvEq/expectThrowFx/selfParity). **Gate = `cd ci && nix flake check`** (AUTHORITATIVE, proven non-vacuous by break-test; `nix-unit --flake .#tests` CLI UNDER-REPORTS, DON'T use). FINDING: same-priority same-order listOf defs merge in REVERSE declaration order ([1],[2]→[2 1]).

**E1 = vendor-and-own-the-seam** (user-chosen over from-scratch). `mkEngine = modulesFile: lib.extend (final: _prev: { modules = import modulesFile { lib = final; }; })` — overriding `final.modules` ALONE propagates the whole module surface (`lib/default.nix:474 inherit (self.modules)`), and `final.types` re-fixpointed reaches the vendored evalModules at submodule `base`, so the vendored file-local `extendModules` owns EVERY recursion level incl `base.extendModules` re-entries (**the ownership the HC5 `identity` lib.extend engine CANNOT reach** — proven by marker subagent test). `lib.types`/`type.merge` hosted BY-REFERENCE (live lib re-fixpointed, NOT vendored). Vendored from nixpkgs **567a49d** (= `root.inputs.nixpkgs` flake.lock `nixpkgs_7`); MIT COPYING+README provenance under `lib/engine/vendor/`. realHost `system.build.toplevel.drvPath` BYTE-IDENTICAL (`xwiyf4rg…`). E1's vendored body = the PERMANENT host substrate E2/E3 modify in place.

**E2a = byte-identical on a REAL unmodified Den config** (bridge to Den integration). Full-surface: doctor `inputs.nixpkgs.lib` on the template's raw `outputs` so aspect resolution + den.hosts + re-instantiation ALL run on the engine; drvEq host toplevel.drvPath. Template minimal (microvm rejected — 9p fsType throws under 567a49d, vanilla too). LOAD-BEARING: byte-identity meaningful only when vendored-body ≡ template-nixpkgs ≡ 567a49d (the two modules.nix bodies differ 218 lines; pin makes a divergence an unambiguous Den-lib-escape); engine seeded from the nixpkgs FLAKE lib (carries nixosSystem).

**E2b = byte-identical on REAL nix-config FLEET HOSTS** (production-scale Wave-D-target proof; 43 tests, ALL 3 hosts vanilla==engine==REAL). Re-invoke nix-config's whole `outputs` (committed ci input, rev-locked) with the host's channel input `.lib` doctored to the engine + lazy self-knot; drvEq `nixosConfigurations.<host>.toplevel.drvPath`. bitstream `70xb6lxav…567a49d` (unstable), blade `z1j54phn…5e8ca42` (master), cortex `93da5ba9…5e8ca42` (master + **cortex-cuda MICROVM sub-eval owned**). KEY DESIGN: (1) **CHANNEL-SEEDED** runner — `doctor=fleetEngineLib=(import ./engine {lib=channelLib}).engine.lib` re-seeds per host channel; the GLOBAL engine (seeded from hola root 567a49d) produces an ARTIFICIAL foreign-lib build `10vgh8b8` NOT the real one. ONE vendored body works all channels (modules.nix+types.nix byte-identical 567a49d↔5e8ca42, guarded by channel-modules-identity test). engine MODULE unchanged (re-instantiated). (2) PURE lazy self-knot `self = out // { outPath=nc.outPath; inherit (nc) sourceInfo; }` (bare self=out throws). (3) **pipe-operators** experimental-feature in `ci/flake.nix nixConfig` (BOTH spellings `pipe-operators`/`pipe-operator` — CppNix/Determinate vs Lix; tryEval can't catch parse-time). (4) channelInput = nixpkgs INPUT name ≠ den channel name.

**PERF SIGNAL (measured): owning evalModules via lib.extend is ~FREE** — engine vs vanilla = +9 primops / +0.24% thunks one-time, per-eval identical, no regression. ⇒ the WIN levers are NOT in the engine itself but in E3 (cross-scope sharing = CLOSED single-host, see [[project_hola_perf]]; relocated to the FLEET axis, see [[project_hola]]).

──────── archive-project_hola.md ────────
---
name: project_hola
description: hola — pure-gen/graph nixpkgs-compat module engine + fleet-eval-sharing perf arm; LIVE state hub
metadata:
  node_type: memory
  type: project
  originSessionId: a62fb38e-47a4-4bca-9c29-820186bb7c53
---

**hola** = proposed flake+module framework hosting UNMODIFIED nixpkgs/NixOS modules via the gen ecosystem + den HOAG edge model (separate from den; codename adios=replace-module-system vs hola=keep-nixpkgs). Public repo **github:sini/hola** (@de5b21d). Papers at `~/Documents/papers/hola-architecture/` — **`MEMORY-JOURNAL-ARCHIVE-2026-06-28.md` there = the full pre-compaction phase-by-phase record** (Phase 1/2 cost-centers, substrate decision, every E-increment, perf pivots; consult for detail this file omits).

Split records: **[[project_hola_engine]]** (parity harness + E1/E2a/E2b shipped byte-identical engine), **[[project_hola_perf]]** (cortex profile, eval-bound finding, Determinate free win, cross-scope-sharing NO-GO), **[[project_hola_daemon_hang]]** (sini↔daemon eval hang, debugging on its own track). Also: [[project_gen_rebuild]] (v2 substrate), [[project_zen_vic]] (reference alt).

---

## MEMORY HYGIENE — read before editing any hola memory

hola is a long-running multi-phase research program; its memory MUST stay split + thin, never re-grow into one journal (it hit 57.7KB once). **This hub's structure: convention at TOP, stable architecture in the MIDDLE, live frontier at the TAIL — so `tail project_hola.md` shows current state and you update at the bottom.** Rules:
- **Four one-fact files:** THIS hub (live frontier + dispatch + live gotchas), `[[project_hola_engine]]` (shipped engine substrate), `[[project_hola_perf]]` (perf findings + cross-scope NO-GO), `[[project_hola_daemon_hang]]` (daemon debugging). gen-rebuild → `[[project_gen_rebuild]]`, zen → `[[project_zen_vic]]`. Link, don't duplicate.
- **Update the hub's CURRENT STATE section (the tail) — REPLACE in place, don't append.** When a phase completes, rewrite that paragraph to the new state and move the superseded blow-by-blow OUT (it's already in git commits + papers specs). Do NOT stack a new dated paragraph each session — that bloat is what this split fixed.
- **Detail belongs in papers/git, not memory.** Specs/plans → `~/Documents/papers/hola-architecture/{specs,plans}`; full chronological record → the dated `MEMORY-JOURNAL-ARCHIVE-*.md` there (committed); RESUME-*.md = paste-able session handoffs. Memory = pointer + thesis + live gotchas only.
- **Shipped work → its record file as a one-shot summary** (`_engine`/`_perf`), NOT the hub. The hub carries only what is IN PROGRESS or imminent.
- **Index discipline:** MEMORY.md has a hard ~24.4KB ceiling and ~200-char/line target — trim, don't append unbounded.
- **Re-split trigger:** if a RECORD file (`_engine`/`_perf`) passes ~10KB, lift its oldest-settled content into the archive. The hub is the working doc and may run largest, but keep its stable middle lean by retiring settled phases to record files.

---

## ARCHITECTURE / THESIS (stable)

**PERF ARM = FLEET-EVAL-SHARING ARCHITECTURE (STRONG GO, spec committed papers main 279d4cd 2026-06-26).** The single-host/heterogeneous cross-scope sharing NO-GO (see [[project_hola_perf]]) was a homelab artifact; **at FLEET SCALE with host-CLASSES the sign FLIPS net-positive** (94-95% of the derivation-construction cost-center is host-invariant on real axon class). Thesis: **DECLARE the host-invariant boundary** (den host/aspect structure + quirk arg-shape `(functionArgs emit) ? config`) — O(K) per-class validation via the repurposed hola parity gate, N-independent — **not DISCOVER it** (C1 sentinels = O(N) = net-negative). VISION: **den-hoag controls the flake entrypoint** (fleet evaluator), hola = per-node nixpkgs-module engine + byte-identical gate, gen = primitives.

**THE VALUE (user's sharp test, spec §0):** CLOSED entity-record emits (membership/IP/claim-provide of `host.*`/`user.*`) need NONE of this — den does them TODAY with zero eval. The ENTIRE value = make the **OPEN emit affordable at fleet scale** (config-DEPENDENT cross-host: host A reads host B's RESOLVED `config`). Every mechanism judged by: does it aid the open emit?

**THREE PLANES:** (1) distributed-query — Tier-1 entity-record (zero nixos eval) vs Tier-2 config-referencing (open; forces source host's module-merge slice NOT the 94% derivation-construction; local self-backup ~free, cross-host per-edge scoped, class-shareable when deterministic). (2) class-core eval-sharing — partition by class key, force archetype once, freeze PLAIN projection, inject at host.instantiate; **2a intra-process buildable now**, **2b cross-invocation = the net-new KEYSTONE** (gen-rebuild must consume gen-scope; deferred FUTURE_WORK). (3) incremental (gen-rebuild override/applyEdgeDelta). **CLASS KEY = sorted aspect-include set NOT hostname.** Per-host axis = fixed-shape ~7-field record (hostname/ips/disk-ids/facter/agenix), feeds only cheap leaves.

**ALL 3 GATES VALIDATED GREEN 2026-06-25 (wf wh0ygg53t):** Gate A = real cross-host emits pipeline-parametric + per-edge scoping inherent via Nix laziness (global hasAnyConfigThunk = latent footgun not actual blow-up); Gate B = 2a REAL eval-WORK shared on axon-02/03 byte-identical (faithful model of den-hoag closed-injection-at-instantiate host.nix:397); Plane 1 = zero-force (128ms vs 36s). **DEN-HOAG SEAM DESIGNED §8a:** S1 kill global flag→per-sid lazy hostConfigFor; S2 cone-expander `pipe.reads [paths]` (the ONE new verb) + lint; S3 axis/core sep; S4 HOAG declared-edges via aspect→resource extractor (serves queries+affected-set+blast-radius+S2-cone). pipe.from/collect/collectAll surface STAYS; seam ADDS pipe.reads, REMOVES global flag.

**HONEST CAVEATS (baked in):** drvPath-equality = OUTPUT shareability NOT eval-work-shared; ~10 aggregation roots (etc/units/activate/toplevel) irreducibly per-host; soundness bounded to **throws-OBSERVED** (non-forcing channels tryEval/presence/lazyAttrs = no pure detector, hola O(K) parity gate MANDATORY backstop); **config-dependent quirks = ALL-OR-NOTHING fleet-wide** (resolve.nix:393-408 → full nixosSystem per peer = the blow-up) ⇒ keep cross-host quirks pipeline-parametric, source-config emit = cone-expander-gated. claim/provide "engine"/"connect kind 0" = SPEC-only; in CODE = pipe.collect aggregation. Perf contract NOT total-O(|AFFECTED|); +Determinate 3.7× for the residual tail.

**BUILD ORDER (re-centered on the open emit):** (1) unlock open emit on real axon w/ scoped collect — **DONE** → (2) S2 cone-expander + S1 → (3) Plane-2a class-share → (4) Plane-3 incremental → (5) 2b keystone (gen-rebuild consume gen-scope, FUTURE). **DISPATCH SPINE:** gen-rebuild v2 ✅ sufficient → hola ENGINE ✅ → {Den integration, fleet sharing, zen comparison} gate on the engine. Determinate adoption = velocity side-quest (verbatim nixpkgs, ~3.7×), protect engine/fleet focus.

---

## ═══ CURRENT STATE — update HERE (tail-readable) ═══

**STEP 1 DONE (2026-06-26):** first end-to-end OPEN `{host,config,...}` cross-host emit in nix-config (confirmed genuinely DORMANT — every prior emit reads only the entity record). Throwaway nix-config branch `demo/persist-claims-open-emit` (worktree, NEVER merged, den UNCHANGED): `persist-claims` quirk reads peer `config.users.users.frr.uid` via scoped `pipe.collect`. MEASURED axon-02: scoped-collect = 3.97× one-host in COPIES (≈3 not 7, zero peer toplevels forced), fn only 1.37× (nixpkgs baseline thunk-memoized across same-system hosts); open read = 8.3% of toplevel copies (T−B=91.7% derivation-construction AVOIDED). **Gate-B bound: COPIES is the discriminating metric (the 94% cost-center); fn-calls are NOT.** Evidence papers 7ebf82f, `analysis/experiments/fleet-open-emit/`.

**STEP 2 = comprehensive OPEN-EMIT-AFFORDABILITY PROGRAM (user rejected YAGNI — every lever/edge-case first-class).** Decomposed 2.0 synth-scale harness + observability / 2.1 S1 / 2.2 S2 cone-expander FULL / 2.3 Plane-2a class-share / 2.4 observability. **S2-grounding (measured): cone-expander is BASE-DOMINATED — the ~9M-fn module-fixpoint base is already memoized across same-system peers, so per-peer increment = COPIES (cone-dependent) not the base ⇒ S2 cone-restriction LOWER-value than spec implied; Plane-2a class-sharing is the real open-emit lever.** S2 lint still worth keeping (footgun guard).

**SYNTH-FLEET HARNESS (step 2.0) — ✅ COMPLETE, ALL 14/14 TASKS** (worktree `.worktrees/persist-claims-open-emit` branch `demo/persist-claims-open-emit`, throwaway; den UNCHANGED, only `modules/den/synth/**`+`synth-measure/**`). spec `specs/2026-06-26-synthetic-fleet-harness-design.md`; `.tasks.json` tracker 14/14; durable report `analysis/experiments/synthetic-fleet/{README.md,baseline-N100.md}`; handoff `RESUME-synth-harness.md`. T0 factory / T1 facter (2-regime) / T2 secrets / T3a skeleton / **T3b 1a @fc2ed99b** (no-throw N=10/50/100; cone=deepForce of assertion PREDICATES not raw subtrees) / **T4 1b @c1fe5579** (open emit+collect RESOLVE N=100: 4 cones×per-host-O(N²)+central-O(N), collectAll trigger, cycle-rejection) / **T5 driver @c8f722cc** (lib.sh: eval-cache-off, NIX_SHOW_STATS fn/copies-deterministic+cpuTime/maxRSS median-IQR) / **T6 differential @de7e71a4** (marginal N-vs-N+1 COPIES, closed-vs-open SEPARATE curves) / **T7 sentinels @00fc0788** (value/structure poison + tryEval-invisibility) / **T8a partition @3c0939ae** (exact 0.96@N=100/near 0.92) / **T8b facter-diff @db55f3c6+76fc81b2** (varied core<shared) / **T9 parity @6f0cc813** (13-key canon: raw≠/canon=/leak≠) / **T10 provenance @b87ce981** (gen-rebuild-shaped graph, plain Nix) / **T11 baseline @76fc81b2**. **DEN PIPE WIRING (the 1b cost):** collected value reaches only the emit-DECLARING aspect + only an EXPLICITLY-destructured nixos arg; pipe name must be a registered `den.quirks.<pipe>`; collect policy in `schema.host.includes` must be the registered `den.policies.*`; collect MODE = consumer placement.

**STEP-2 PROGRESS (2026-06-28, this session — both 2.1/2.3 PLANS written+adversarially-reviewed+fix-folded: `plans/2026-06-28-{plane-2a-class-share-poc,fleet-seam-s1-per-sid-hostconfig}.md`+tasks.json):**
- **2.3 Plane-2a PoC ✅ COMPLETE — the FIRST hard number for the arm.** `synth-measure/2a-share.sh`+test, commit `fa4d2864` (worktree, den UNCHANGED). Archetype-once + per-host axis-delta at units level = `archUnits // removeAttrs (realUnits h) sharedKeys`; **zero-exclusion** parity gate, byte-identical (`toJSON van==asm`, verified). MEASURED on the 96-host agent class (sharedKeys=212/240; **shared-facter** = the byte-identical-class premise, `varied` under-discovers Δ): **per-host marginal 21,722,170 → 8,758,855 copies = 59.68% collapse, scale-INVARIANT to the digit at class-size 6 & 46; saving 12.96M/host linear; 583M copies MEASURED on a 46-host class, ~1.23B extrapolated at 96.** Residual 8.76M/host = per-host module-merge spine (separate fixpoint = Gate-B WHNF bound, paid in BOTH). N=96 full vanilla deepSeq **OOMs** (whole-fleet force memory-bound = finding; 2a also lowers peak RAM). Evidence `analysis/experiments/synthetic-fleet/2a-{baseline,result}.md`; gist published. **Honest: PoC IDENTIFIES shareable work (upper bound); production realization = den-hoag inject-at-instantiate seam.** Probe gotchas: bash-not-zsh (`BASH_SOURCE`), `cd $SYNTH_ROOT` before `.#`, never `timeout` a shell-fn, splice unit-key names with `json.dumps` (systemd `\x2d` escapes).
- **2.1 S1 ✅ COMPLETE — den commit `b3449c8b`** on `feat/s1-per-sid-hostconfig` (den worktree off `fix/broadcast-home-pool-to-host`, NOT pushed; HOLD pending §8a-D5 PR-vs-den-hoag-fold). Killed global `hasAnyConfigThunk`-gated `hostConfigs` map → `hostConfigScopeIds` ATTRSET (`?`-membership O(1), NOT list+`elem`) + lazy `hostConfigFor` builder, threaded through assemble-pipes.nix; `anyConfigDepThunk` (renamed scan, verbatim) gates ONLY `bprimeEdges` so CLOSED fleets stay zero-cost. **den CI 1052→1054 (1052 unchanged + 2 new laziness fixtures), ZERO regression; synth + real-axon (axon-02/03 toplevel drvPath `m88glzsg…`/`9y1dmyp4…`) BYTE-IDENTICAL pin-vs-S1-override; B′ cycle preserved.** Known THEORETICAL edge (osConfig-only collected emit w/ no config-thunk now resolves vs defers — not hit by any test nor real axon). Validation pattern = compare github-pin (pre) vs `--override-input den path:<worktree>` (post). Evidence `analysis/experiments/synthetic-fleet/s1-result.md`.
- **2.2 S2 ✅ COMPLETE — den commit `487cc671`** on `feat/s2-pipe-reads` (stacked on S1, NOT pushed; held with S1). FULL scope (user-chosen): `pipe.reads [paths]` stage (policy-effects.nix) + `coneView` cone-restriction (`hostConfigFor sid` restricted to declared paths; undeclared read = natural attr-missing throw = enforcement, NOT a runtime cut — laziness already scopes, base-dominated) + the **LINT** (config-dep collect/collectAll/broadcast w/o `reads` → throw). **den CI 1054→1057** (1054 unchanged + 3 new; den's own config-dep collected fixtures bprime/pipe-scope/pipe-broadcast/fleet-demo updated to declare `reads`, byte-identical). **Lint PROVEN on the REAL persist-claims open emit** (exact designed error); full loop: undeclared→reject→`pipe.reads ["users.users"]`→cone-restricted→**axon-02/03 toplevel BYTE-IDENTICAL to pin**. Cone teeth (out-of-cone throws) = NOT tryEval-catchable (Nix attr-missing), validated via harness `expectedError`; lint `throw` IS catchable. Evidence `analysis/experiments/synthetic-fleet/s2-result.md`.
- **═══ OPEN-EMIT-AFFORDABILITY BAND COMPLETE (Plane-2a + S1 + S2) 2026-06-28 ═══.** All 3 scoped sub-projects done, byte-identical-validated, committed (papers `e043387`/`8815a03`+S2; den `fa4d2864` worktree + `b3449c8b`(S1)+`487cc671`(S2) held on stacked feat branches). Gist published. **Remaining is BEYOND the band:** the den-hoag inject-at-`instantiate` SEAM itself (§8a — where Plane-2a's identified saving gets REALIZED in production; separate program) + Plane-2b cross-invocation keystone (gen-rebuild content-addressed, deferred). D5: ship S1/S2 to denful/den vs fold into den-hoag = still open (held).
- **INSTANTIATE-PATTERN REALIZATION (2026-06-28, user-prompted) — Plane-2a works TODAY without den-hoag.** den's EXISTING `nixosSystem.extendModules` + `lib.mkForce` (the Gate-B mechanism) shares the class-invariant core across N REAL member fixpoints — not the harness attrset-trick. Measured N=100 agent class, `system.path` projection (systemPackages buildEnv, ~42% cost-center): **per-added-node 4.38× fewer copies + 5.15× faster** (reconstruct 5.05M copies/1.83s per host → inject 1.15M/0.35s); **inject runs all 96 nodes at 8.05GB RSS/65.9s** where reconstruct needs 18.4GB for just 48 (full-units reconstruct OOM'd ~115GB at 48); **memory 2.55× at M=48, flat for inject**. Mechanism = force `arch.config.system.path` once, `arch.extendModules {modules=[{system.path=mkForce archPath; hostName=mkForce h;}]}` per member. FULL-CORE extension (user-prompted): the `systemd.units` half (217 shared, ~53%) injects too via `arch.extendModules {systemd.units = mkForce (archShared // removeAttrs ncs.${h}.units sk);}` = **1.89× fewer copies/node, runs all 96 @ 39GB** (reconstruct units OOM @ 48). **KEY STRUCTURAL FINDING — leaf vs co-produced-attrset:** a LEAF projection (`system.path`) mkForce-injects whole + the re-eval spine is tiny ⇒ **4.38×** today; a CO-PRODUCED attrset (`systemd.units`) shares its core but the member's extendModules must re-run evalModules to apply the mkForce ⇒ full merge spine per member caps it at **1.89× vs the harness-2a/den-hoag ceiling 2.48×**. The ~31% gap IS den-hoag's value (inject core as a FIXED module input ⇒ member produces only delta, no re-merge). inject pays per-member SPINE (Gate-B WHNF bound); intra-process. **REFRAMED: den-hoag = (1) make this the DEFAULT fleet-build path + (2) recover the attrset spine-tax (1.89→2.48×), NOT invent the capability.** Evidence `analysis/experiments/synthetic-fleet/instantiate-pattern-realization.md`; probes `scratchpad/instantiate-{probe,scale}.sh`. LESSON: full-units force is MEMORY-MONSTROUS (48 hosts→~115GB→machine-OOM); use a memory watchdog (kill nix eval if free<4GB) + light projections for scale benchmarks.
- **CppNix 2.34.7 EVALUATOR-LEVER AUDIT (2026-06-29, user "move every lever within CppNix"): the free evaluator levers are EXHAUSTED — only WORK-reduction helps.** (1) **Parallel eval = NO-GO on CppNix 2.34.7**: `--option eval-cores 0` + `parallel-eval` feature is ACCEPTED but DOES NOT THREAD — identical wall to cores=1 on a trivially-parallel synthetic (8 folds 4.51s both) AND the inject (16.0s both). The ~3.7× is Determinate-only. (2) **Streaming/force-and-drop = NO-GO**: `foldl' (acc: h: deepSeq (um (inj h)) (acc+1))` vs `deepSeq (map ...)` → IDENTICAL maxRSS at M=96 (39.98 vs 40.06GB, stream slightly slower) — Boehm GC grows heap to the cumulative high-water mark + doesn't return to OS, so dropping the live set doesn't lower PEAK. (3) **GC_INITIAL_HEAP_SIZE=8g = MARGINAL**: ~7% wall (15.94→14.85s) at the cost of +RSS (eval is single-thread-bound NOT GC-bound, matches perf memory). **CONCLUSION: within CppNix the eval is single-thread-bound ⇒ wall=WORK ⇒ the ONLY lever is reduce copies = class-core sharing (already 1.89-4.38×; also lowers memory since less work=less allocation — that's WHY inject runs 96@40GB where reconstruct OOMs >115GB@48). Further within-CppNix gains are CODE not flags: more class-invariant projections + den-hoag fixed-input (recover attrset spine-tax 1.89→2.48×) + zen-style per-host eval (3-10×, breaks the spine floor).** Probes scratchpad/{parallel,stream}-probe.sh.
- **FIXED-INPUT INJECTION recovers the extendModules spine-tax (2026-06-29).** The 1.89×(extendModules) vs 2.48×(harness-2a) gap = the per-member module-merge RE-EVAL spine (`arch.extendModules {systemd.units=mkForce …}` re-runs evalModules). Recover it with **config-merge** — assemble on the RESOLVED arch.config, no extendModules, no re-eval: `archCore // removeAttrs ncs.${h}.config.systemd.units sharedKeys`. MEASURED units: **6.54M/node @ 6-host (3.32×) / ≈8.76M @ fleet (2.48×), BYTE-IDENTICAL (225/225 keys)** vs extendModules 11.49M(1.89×) vs reconstruct 21.72M. **STRUCTURAL LIMIT = projection-only:** config-merge reassembles a CONSUMED projection (units/system.path) but NOT a full per-host TOPLEVEL — `(arch.config // {hostName=h}).system.build.toplevel` returns arch's already-resolved toplevel (// patches a sibling, can't recompute the monolith) ⇒ every host gets arch's. So **fixed-input recovers 2.48×+ TODAY for projections; extending to the deployable per-host toplevel is precisely DEN-HOAG's job** (modules consume the injected core, emit only delta, no monolithic re-merge). Helper `shareClassProjection` + full writeup in instantiate-pattern-realization.md. Probe scratchpad/fixedinput-probe.sh.

**LIVE EVAL GOTCHAS (this harness):** (1) **scaled eval needs `ulimit -s unlimited` + `--option max-call-depth 1000000`** — den fx class-collector recursion (`class-collector.nix:40 scopedClassImports null`) exceeds default 10000 past N≈10 (a gen-graph-point-query argument); wall super-linear (N=10 4s / N=100 115s). (2) **daemon hang ROOT-CAUSED + FIXED 2026-06-28** (parallel session): `modules/den/schema/cluster.nix` string-INTERPOLATED a path `secretPath` (`"${c.secretPath}/…"`) → coerced the nonexistent synth-cluster secret dir into the store → CppNix 2.34.7 empty-NAR addToStore → client-side WorkerProto desync deadlock; **one-line fix = path concat** `(c.secretPath + "/…")` (their commit, left unstaged; I committed only synth/*). **VERIFIED FIXED from my side**: the exact previously-hanging eval returns in 3s as sini, no sudo ⇒ **synth-measure/lib.sh defaults to the daemon path** (`SYNTH_EVAL_SUDO=1` falls back to the root/`NIX_REMOTE=` LocalStore workaround if it regresses). `nix fmt` still hangs → use `nixfmt` direct. See [[project_hola_daemon_hang]] + `analysis/sini-daemon-eval-hang-DEBUG.md`. (3) **robust 1a cone = derivation-stopping deepForce of assertion PREDICATES (booleans) NOT whole-config** — universal force trips removed-option/unset stubs + readFile generation-assets + facter-coupled logic (several reproduced on REAL axon-02, NOT synth defects); set→string coerce (agenix assertion MESSAGE) + path-not-exist UNCATCHABLE by tryEval. (4) pure `scale.json` N/heavy knob, NO `--impure` (relocates rootPath, breaks synth secretPath). (5) classKey enable file = `enable.nix` not `_enable.nix` (import-tree excludes `/_`).

**HOLA = MEASUREMENT LAB for the gen trust push (owner decision 2026-07-04, gen-v1-trust-release roadmap):** A1 fleet campaign COMPLETE + PUBLISHED (hola main @d643a8d, 22 commits, CI green run 28727988245): G6 split (fleet comp/term 42.5% fcalls / 5.2% //-copies — corroborates 94% prior), Arm R gen-rebuild incremental 66.7% byte-sound (floor 0.60), Arm C s2 +4.6% decl-plane overhead (airtight scope-mismatch, s2 byte-sound), 7b realization on real blade+cortex class ~1.6%/member w/ 212-unit byte-identical core (floor 0.008) — SPINE-DOMINATED (~98% host-specific config resolution) ⇒ **A3 RE-SCOPED 2026-07-05 to `gen-class`** (shared lib: tier1 partition+seam-contract+projection injectors+parity harness; tier2 fixed-input kernel injection on pure substrate; tier3 boundary+instantiate wiring DEFERRED to den-hoag which consumes the lib); fleet gates = scaffolding, durable home migrates to gen-class ci; hola ENGINE arm stays orthogonal; gen BENCHMARKS.md/VALIDATION.md carry the fleet numbers + gen→hola→nix-config audit path (@338d5f7). Durable protocol findings: gc.totalBytes non-deterministic (Boehm, informational-only); version STRINGS don't identify evaluator builds (−8 primops on Determinate @ identical 'nix (Nix) 2.34.7' — two-tier counter gates: exact same-build / ±0.1% band cross-build); preamble ±1-2 on copies/thunks; no terminating resolution-layer witness exists (open problem).

**OPEN DECISIONS D1-D6** (class-key lifecycle, projection, 2b substrate, gate placement — partially settled by the lab decision above, first-cut scope) + **D5 REFRAMED:** den-hoag NOT yet shipped ⇒ D5 = "ARCHITECT the correct den-hoag quirk/attribute-eval SEAM" using fleet findings (per-edge declared reads / axis-core separation / HOAG demand-driven recordedDeps), NOT patch the existing all-or-nothing. This is the highest-leverage place fleet-sharing shapes den-hoag = Gate A on the whole perf arm. Full session dump: `RESUME-fleet-architecture.md`.

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [hola project](project_hola.md) — pure-gen/graph nixpkgs-compat module engine (github:sini/hola); LIVE perf arm = FLEET-EVAL-SHARING (declare host-CLASS boundary not discover, den-hoag flake entrypoint, 3 planes); OPEN-EMIT-AFFORDABILITY BAND COMPLETE 2026-06-28 (Plane-2a class-share PoC=60% per-host eval-work collapse/583M copies saved + S1 per-sid lazy hostConfigFor + S2 pipe.reads cone+lint; all byte-identical, den CI green, held on stacked feat branches, gist published); STATUS 2026-07-05: RESEARCH-ONLY lab, backgrounded, UNRELATED to den-hoag (findings already fed gen module system); s1/s2 den branches (`feat/s1-per-sid-hostconfig` `b3449c8b` / `feat/s2-pipe-reads` `487cc671`) PUBLISHED to sini/den 2026-07-06; the lab owns fleet perf re-measurement; detail in [[project_hola_engine]]+[[project_hola_perf]]

──────── archive-project_hola_perf.md ────────
---
name: project_hola_perf
description: "hola perf findings — cortex eval is intrinsic+eval-bound, Determinate=free win, pure-Nix cross-scope sharing NO-GO"
metadata: 
  node_type: memory
  type: project
  originSessionId: c7f8a476-8d5f-4e59-970d-56938cc4eb7b
---

Perf conclusions for the hola/cortex eval work. Hub: [[project_hola]] (the fleet-scale PIVOT that follows from these). Engine substrate: [[project_hola_engine]]. Full derivations in papers `MEMORY-JOURNAL-ARCHIVE-2026-06-28.md` + `LIX-TO-DET-SYSTEMS.md`; cross-scope NO-GO spec = papers e3c `2026-06-24-hola-e3c-c1-cross-scope-sharing-design.md` (committed 8a18a1f/3202f0b).

**CORTEX ~36s eval = 94% INTRINSIC DERIVATION CONSTRUCTION** (re-grounded from raw NIX_SHOW_STATS): den/nix-effects/dendritic-assembly = ONLY 2.8% wall (1s, 20.4% fn-calls — user's recollection had inverted this); total module machinery 5.6%; _module.check 0.21% (negligible). ~95% of the 235M copies = CLOSURE-FORCING not pkg-set construction (systemPackages buildEnv ~42%, units/initrd/services ~53%, spine/stdenv floor ~5%); mkDerivation/extendDerivation per-output commonAttrs re-copy (customisation.nix:399) ~20-30k copies/drv × thousands. **SPLICING is OFF for cortex** (native host==build, actuallySplice=false) ⇒ forking nixpkgs can't win an unpaid cost.

**WALL is SINGLE-THREADED-EVAL-bound, NOT GC-bound** (measured on cortex itself, Lix 2.96-dev, 9950X3D): GC knobs (heap=24g/markers=16/DONT_GC) cut cpuTime 36.9→21.4s (−42%) but WALL only 33.5→31.3s (−6%). Decomposition: ~21s (63%) SERIAL single-threaded eval (235M copies on ONE core) + ~10s (30%) IO + ~2s (6%) GC. The 32 threads are wasted because eval is single-threaded and the bottleneck isn't GC.

**FORKING nixpkgs CONSTRUCTION = DEAD END.** by-name already shipped, allowAliases/callPackage-lean/overlay-collapse = single-digit, baseModules-trim is really module-SELECTION (only helps if it shrinks the actual closure, high compat risk). FRAMEWORK reimpl (adios/den-hoag/hola-engine) = ~30% CPU but copies −0.3% = iteration/CI/flake-output lever, NOT the 36s.

**FREE WIN = DETERMINATE NIX evaluator** — parallel eval ~3.7× on multi-NixOS-config flake check (eval-cores=0, verbatim nixpkgs, GA 2026-01-30) + lazy-trees ~3× wall / 97% disk; cortex's exact FLEET workload shape, zero code. (Lix = 15-17% mem pointer-tagging only; stock Nix 2.31 parallel-GC-marking only; tvix not viable.) GC_INITIAL_HEAP_SIZE = free hygiene (~2s wall). NEXT decisive experiment when revisited: re-run cortex eval under Determinate (eval-cores=0) vs the 33.5s Lix baseline (coexists with Lix). Targets the 21s serial spine; lazy-trees targets the ~10s IO; plausibly 33s→~12-15s.

**PURE-NIX CROSS-SCOPE EVAL-RESULT SHARING (single-host AND cross-host heterogeneous) = NO-GO** — the E3c-C1-A0 gate, 2026-06-25 (two adversarial workflows wxcx5rcks/w42d7j97t + authoring-agent review, ~30 /tmp probes). The original per-element design was REFUTED on 4 load-bearing claims: (1) **NO sound single-host net win** — per-element sentinel forces an invariant option N+1× vs vanilla N (measured 4 vs 3); Nix memoizes NOTHING across separate evalModules fixpoints, so the deepSeq re-pays exactly the laziness it skips. (2) naive **union-sentinel UNSOUND** — throwing the ⋃ of element paths over-throws and FLIPS tryEval branches (over-admits UNSAFE); sound universal = ∩ₑ frozenSet(e) needs N per-element sentinels = no amortization. (3) **presence/structure queries** (`?`/hasAttr/attrNames over a delta-added key, options-shape reads) unsound EVEN per-element — a value-throw sentinel never perturbs key PRESENCE; **`or` is SAFE** (forces value→throw propagates). (4) memoization by syntactic path-set unsound (key is value-derived). Soundness intrinsic ONLY for the **throws-OBSERVED** subclass; throws-NOT-observed has no pure-Nix detector ⇒ parity-gate-backstopped. **C2 also net-NEGATIVE** under the sound per-host-sentinel form (4 vs 3). **DELIVERABLE = the rigorous NEGATIVE.** Soundness boundary = NON-FORCING channels (types.attrs/lazyAttrsOf/options-shape unsound; strictly-typed attrsOf `<t>` presence reads SAFE — type-check forces).

**THE PIVOT (owner correction 2026-07-14 — do NOT cite the NO-GO as a blanket ceiling):** the NO-GO applied to hola AS ARCHITECTED (per-element sentinel DISCOVERY). The **gen-module system OVERCAME it** and hit adios-like wins — fixed-input class-core injection (gen-class `applyCoreFixed`) + warm-override memoization = **>70% memory reduction, re-compute avoidance as a KEY WIN** (even on hola alone). The lever = DECLARE the host-CLASS boundary (key=aspect-include-set) not DISCOVER it; sign flips net-positive at fleet scale → the fleet-eval-sharing arm in [[project_hola]]. Avoid-re-compute is SOLVED/achievable via the gen-module system, NOT a dead end. NOTE: [[project_zen_vic]] does NOT do cross-scope sharing either (its 3-10× is single-config intra-eval). E1/E2 engine stands as validated substrate; the pure-Nix perf VALUE of owning evalModules is bounded ~0 (94% intrinsic + cross-scope sharing closed) — value relocates to the fleet axis + the evaluator layer.

──────── archive-project_inputs_prime_battery.md ────────
---
name: project_inputs_prime_battery
description: "nix-config inputs' battery conversion + historical infinite-recursion root cause (fixed upstream in den)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0cbcc1c8-9506-474d-a8ee-ceee078a857e
---

nix-config uses den's `den.batteries.inputs'` + `self'` batteries (wired in [modules/den/defaults.nix](modules/den/defaults.nix) `den.default.includes`) to inject flake-parts `inputs'`/`self'` as class-module args. Battery = `withSystem host.system (ps: { ${class}._module.args.inputs' = ps.inputs'; })`; covers ONLY os/user/home classes (osAspect/userAspect/hmAspect) — NOT crds/k8s-manifests/devshell (devshell gets inputs' natively from flake-parts perSystem).

**Converted 2026-07-06** (6 files): claude/package, hyprland, xdg-portal, emulation (nixos) + spicetify, firefox (homeManager) — `inputs.<flake>.packages.${system}.x` → `inputs'.<flake>.packages.x`. Byte-identical (verified wine-ge drvPath match). Add `inputs'` to the class arg, drop outer `inputs` only if fully unused (firefox/spicetify keep it for module imports; base16/nixosModules/homeManagerModules stay `inputs` — not system-scoped).

**Hard limit:** `inputs'`/`self'` only expose attrs declared in flake-parts `config.transposition`. nix-config declares NONE, so only built-in transpositions (packages, legacyPackages, devShells, checks, apps, formatter) work. Custom outputs `chartsDerivations`/`nixidyEnvs`/`charts`/`images` are set via `flake.<name> =` directly → NOT reachable via `inputs'`/`self'`. The 7 kubernetes `crds` chart refs (`inputs.nixhelm.chartsDerivations.${system}`, `inputs.self.chartsDerivations.${system}`) MUST keep the indexed form; `system` there is a den-injected class arg, not the outer closure. To convert them you'd have to declare transpositions AND extend the battery to the crds class — larger change, not done.

**Historical infinite recursion = upstream den bugs, ALL FIXED, not a nix-config issue.** Root causes: (1) checking `options ? perSystem` to detect flake-parts context recursed — perSystem option only exists in mkFlake contexts; fixed by guarding on the cheap `args ? flake-parts-lib` specialArg (den [modules/outputs.nix] `has-flake-parts`); (2) #580 den key-classification force-walked aspect values to WHNF during flake-output assembly, so a value reading system-scoped `self`/`inputs'`/`self.outputs` re-entered the `self` fixpoint → "infinite recursion" (only *unregistered* keys cycled); (3) #369/#377 inputs' on namespaced aspects. Pinned den 4911b7f2 (2026-06-26) has all fixes + the `issue-369-namespace-system-scoped-inputs.nix` deadbug regression test. The battery's `_module.args.inputs'` is LAZY — never forced until a class body reads `inputs'`, which is why the wiring built fine before any consumer existed. See [[project_deepseq_state_thunk]], [[reference_den_remotes]].

──────── archive-project_kernel_purity_arc.md ────────
---
name: kernel-purity-arc
description: "Live den-hoag arc (epic den-hoag-4kh) — theory-first audit of the July corpus, kernel purity before compat, and the validated-bead-graph objective; resume via bd not markdown"
metadata: 
  node_type: memory
  type: project
  originSessionId: b950db38-5e47-4795-8d45-ba555a674ba5
  modified: 2026-07-27T20:33:11.436Z
---

**Live arc as of 2026-07-27. Tracker is BEADS — `bd show den-hoag-4kh` reconstitutes it cold.** Bead bodies
are self-contained by design (criteria, known-positives, falsifiers, cited sites), because markdown does not
survive compaction and the graph does.

## The graph

```
den-hoag-4kh  Kernel purity + roadmap realignment  [epic P1]
 ├── .1 W1  verify shipped claims (axis-1 board first)   READY → dispatched
 ├── .2 W2  kernel purity audit                          blocked by .1
 ├── .3 W3  drift / lost-context sweep (July corpus)     blocked by 9w8
 ├── .5 V1  validation-status pass over ~80 beads        READY → dispatched
 ├── .6 GATE adversarial review instrument               READY → dispatched
 ├── .7 SPIKE (user-guided) y53/8rf sequencing           NEEDS OWNER
 ├── .8 SPIKE (user-guided) alternate graph API          blocked by .2
 └── .4 W4  roadmap realignment                          blocked by .1 .2 .3 .5
```

**W2 depends on W1** because a "dissolved" claim fails two ways — code never changed, or **renamed with the
shape surviving**. Only the second matters, and grep cannot see it. **W4 depends on V1** because re-ordering
an unvalidated graph yields a roadmap that inherits the hypothesis.

## Facts measured this session (do not re-derive)

- **The two STATUS trackers are different axes.** `route-through-board.md` = **axis-1**, graph-native
  correctness, 17 shipped route-through rungs — W2's real input. `coverage-matrix.md` = **axis-2**, calls
  itself the symptom axis; ~48 completion claims, but pins den-hoag `4044ed5` while HEAD is **34 commits
  later**, so every row is a claim about a moved tree. Its roadmap is
  `specs/2026-07-24-den-hoag-effects-runtime-audit.md`.
- **Self-reported W2 gap:** the board records B15/B20 as *"NOT plain graph.ancestorsOf/circular swaps … the
  real route-through is unbuilt"*.
- **The compression miss is a kernel-purity signal, not a docs row.** Estimate 1,010-1,510 for 12 attributes;
  kernel **13,337**; v1 baseline **7,029 across 37 handlers, VERIFIED CORRECT at the spec date** ⇒ 1.90×
  EXPANSION against a claimed 4-5× compression.
- **`CONFORMANCE.md`** (papers `gen-specs/den-hoag/`) — 148 re-runnable rows. Status sections reproduced 30%,
  architecture sections 73%. Six documented features have **zero consumers**; `pipe.withConfig` and
  `meta.substitute` were **never built anywhere** (`git log --all -S`).
- **First confirmed kernel violation:** a live `__provider` writer at `lib/compat/den-brackets.nix:41-47`
  (wired `bridge.nix:171`) under a documented claim the layer is DELETED.
- **Papers corpus classified** 359/359 → `plans/2026-07-27-papers-corpus-manifest.tsv` (T0 deterministic 166 ·
  T0b heading-aware 44 · T1 haiku 149 · T2 12 corrected, 4 held). No files moved yet.

## Owner rulings in force

Layout = subject-inside-artifact-type (`specs/<subject>/`, `plans/<subject>/`; `gen-specs/` untouched) ·
sidecars **superseded by beads** (last 2026-07-25, first bead 2026-07-26) — archive in place, and their **220
pending tasks are the orphan sweep's evidence** · per-library test counts **dropped as a class** · compression
finding = open question now, CHANGES.md once decision history is reconstructed · benchmarks are **post-ship** ·
`gen-rebuild`/`hola` out of scope · internals **dogfood gen modules**, nixpkgs only when translating or
testing · registry index shapes are **mutually exclusive** (`system.host` is what external users use;
`host.system` is largely undocumented).

## In flight elsewhere

`den-hoag-y53` (registry descriptor) — rev 3, **twice adversarially reviewed, REVISE both times**; the second
review found a defect the author's own F2 fix INTRODUCED (re-creating `.8` inside the fix for `.8`). Blocked by
**`den-hoag-00g`** (gen-merge silently right-biases a redeclared option where nixpkgs aborts). Recommended to
PARK behind kernel purity — that is spike `.7`, owner's call.

[[feedback_orchestrator_theory_first]] [[project_den_hoag_features]] [[reference_denhoag_effects_audit]]
[[project_denhoag_kernel_primary_surface]] [[feedback_best_framework_first]]

──────── archive-project_opkssh_ssh_auth.md ────────
---
name: project_opkssh_ssh_auth
description: "nix-config opkssh OIDC-SSH + auth-hardening effort — specs, plan, branch, task state"
metadata: 
  node_type: memory
  type: project
  originSessionId: 479289a2-471d-419a-8c64-40d9efaf2611
---

Fleet SSH auth overhaul in nix-config. Goal: add OIDC-powered SSH (opkssh) **alongside** existing
static keys (not replace), backed by kanidm (primary) + Google (secondary), plus wider hardening.
Brainstorm→2 specs→plan all reviewed (spec + plan reviewers, fact-checked vs repo). Started 2026-07-01.

**Docs** (in ~/Documents/papers/nix-config-architecture/, NOT committed — papers dir isn't git):
- specs/2026-07-01-opkssh-oidc-ssh-design.md (Spec 1, primary)
- specs/2026-07-01-ssh-key-backends-design.md (Spec 2, keychain/encryption — DEFERRED, spike-first)
- plans/2026-07-01-opkssh-oidc-ssh.md (+ .tasks.json) — 8 tasks

**DARWIN SERVER SHIPPED direct-to-main 365fa735 (signed) 2026-07-01:** hand-rolled opkssh verifier for patch
(no nix-darwin services.opkssh). Key gotcha SOLVED: nix-darwin OWNS sshd AuthorizedKeysCommand for static keys
(101-authorized-keys.conf = `/bin/cat /etc/ssh/nix_authorized_keys.d/%u` as _sshd); sshd honours FIRST cmd, so
darwin branch composes at 100-opkssh.conf = wrapper that runs `opkssh verify` THEN cats that static-key file,
always exit 0 (preserves key access), reuses _sshd. auth_id built from resolved-users (extended
resolved-user-emitter.nix to expose sshOidcPrincipals). Eval-verified patch (auth_id=sini json@+jason@) + bitstream.
DARWIN RUNTIME DEBUG (sshd -ddd on patch:2222 was the key tool) — TWO macOS-specific fixes after the initial darwin
commit: (1) 221699b6 opkssh REJECTS policy files unless mode 640 (nix-darwin environment.etc only makes 0444 store
symlinks) → postActivation writes /etc/opk/{providers,auth_id} as real 0640 -o _sshd files; (2) 99105d8c sshd REFUSES
an AuthorizedKeysCommand whose path/parents are group/world-writable and /nix/store IS group-writable on darwin
("Unsafe AuthorizedKeysCommand ... bad ownership or modes for directory /nix/store" — this is why nix-darwin uses
/bin/cat) → postActivation installs the composite wrapper to root-owned /etc/opk/authorized-keys-command (safe path;
script still calls store opkssh internally, sshd only checks the command path) + cd / to avoid getcwd noise. opkssh
verify PROVEN working as _sshd (successfully verified, emits cert-authority,principals=opkssh-wildcard line). Composite
wrapper stdout PROVEN clean (cert-authority + static keys). **VERIFIED WORKING 2026-07-01: opkssh→patch (darwin) end-to-end,
desktop + iPad/rootshell. opkssh now covers the ENTIRE fleet incl. the Mac.**
DIAGNOSTIC RECIPE for macOS AuthorizedKeysCommand: `sudo /usr/sbin/sshd -ddd -p 2222` + `ssh -p 2222 -i cert sini@localhost`.

**STATUS: SHIPPED — PR #174 MERGED to main 2026-07-01** (rebased, 8 commits b609cfcd..1b918b2b; commits UNSIGNED
on main = normal GitHub rebase-merge outcome, matches existing main history). Branch+worktree deleted. opkssh
PROVEN e2e (desktop + iPad/rootshell). REMAINING: deploy tailnet-lock host-by-host to bitstream/blade/axon
(uplink=public + cortex done via apply-local); Task4 automation-identities DEFERRED (no consumer, YAGNI); Task7
CrowdSec SKIPPED (sshd key-only so brute-force can't succeed; defense-in-depth only). git pull main before deploying.
Was: feat/opkssh-oidc-ssh (from main). Execution mode =
subagent-driven-this-session (superpowers), eval-only validation until deploy (nix eval drvPath, no build).
**ALL CODE DONE+committed+eval-verified 2026-07-01 (deploys deferred):** Task0 kanidm client+group (11968682),
Task1 server aspect (1e79b68a — also opksshuser=uidGid 946 in deterministic-uids.nix, den asserts det. uid for
the auto-created opkssh user), Task2 authz+schema (5b1e672b — identity submodule→function-form,
user.identity.sshOidcPrincipals default kanidm-from-email, per-user include emits services.opkssh.authorizations;
sini keys intact + authz idm.json64.dev), Task5 crypto (a66bbe86 — Kex/Ciphers/MACs both branches,
PubkeyAcceptedAlgorithms LEFT DEFAULT for RSA/opkssh-cert/sk), Task3 client aspect (78706d7d — homeManager
pkgs.opkssh + ~/.opk/config.yml + opkssh-login `--provider` alias; roles.workstation+darwin-workstation NOT
roles.dev; nixpkgs pins opkssh 0.14.0 not 0.15), Task6 tailnet-lock (43536bbe — settings.exposure enum
tailnet|public, openFirewall=mkForce(public), LAN allow via environment.networks.default.cidr [NOT
environment.cidr], tailscale0 already trusted; uplink=public). Validation switched to `nix eval drvPath`
(no build). **REMAINING (need user+YubiKey/fleet):** Task4 automation identities (needs agenix rekey to gen
keypair before it even evals; use existing ssh-key generator _generators-module.nix:222), Task7 CrowdSec
(agenix LAPI/CAPI/bouncer secrets + 2-phase bootstrap + deploy), + DEFERRED DEPLOYS/E2E for whole branch:
opkssh browser+passkey login (Task3 e2e, incl. config.yml-vs-`--provider` + RS256-vs-ES256 legacy-crypto
resolution + rootshell iOS redirect URI→kanidm client originUrl), tailnet-lock host-by-host reachability
(Task6; break-glass CIDR is PER-ENVIRONMENT so uplink[prod 10.10.0.0/16] LAN-jumps to prod hosts axon only,
dev hosts cortex/blade/bitstream on 10.9 are tailnet/local only). Resume: /superpowers-extended-cc:executing-plans
on plan path, or continue subagent-driven. Access gated at kanidm opkssh.access scope map (auth_id inert for non-members).
**E2E DEBUG FINDING (fix 58c2693, signed):** opkssh login succeeds + mints ~/.ssh/id_ecdsa+cert but ssh sini@uplink
rejected → root cause = Jason's SSO LOGIN is the identity-only `json` kanidm person (json@json64.dev, admins,
identity-only.nix) NOT the `sini` unix-user person (jason@); Task2 auth_id default maps unix-user→own-email so
json@ token ≠ jason@ auth_id → verify fails. USER CHOSE map-not-consolidate: sini.identity.sshOidcPrincipals =
[json@, jason@] (both Jason kanidm identities → unix sini); did NOT change sini.identity.email (git stays jason@).
Only sini has this SSO/unix split (other unix users' email==login). DEBUG TIPS: cert `Key ID` == token email (ssh-keygen
-L), force opkssh path w/o pulling yubikey via `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ecdsa`, opkssh cert type =
ecdsa-sha2-nistp256-cert (B1 pubkey-untouched keeps it valid), /etc/opk/{auth_id,providers} 0640 opksshuser (sudo to read),
kanidm autoRemove=true. When yubikey PRESENT, static key wins first so opkssh never exercised. NEEDS: redeploy uplink
(colmena apply --on uplink) to push updated auth_id, then re-verify.

**Spec 1 components:** A1 opkssh server aspect (NIXOS-BRANCH-ONLY so darwin patch ignores it — patch
DOES pull roles.default; slab/droid omits it); A2 kanidm opkssh public client (public+enableLocalhostRedirects
+enableLegacyCrypto RS256, 3 localhost login-callback redirects, opkssh.access scopeMap) + group; A3
registry-driven authorizations via new user.identity.sshOidcPrincipals (default kanidm principal from
identity.email — NOTE identity submodule must become function-form `types.submodule ({config,...}:...)`,
sibling ref is config.email; include nixos branch takes environment, available via scope-inheritance);
A4 client aspect (pkgs.opkssh + ~/.opk/config.yml, attach to roles.workstation+roles.darwin-workstation
NOT roles.dev which leaks to slab). B1 crypto hardening (transport Kex/Ciphers/MACs; keep rsa-sha2-256/512
[current RSA break-glass!], opkssh cert type, sk-ssh-ed25519 in PubkeyAcceptedAlgorithms — cross-spec w/ C3).
B2 tailnet-lock: host.settings.core.security.openssh.exposure enum tailnet|public (default tailnet), uplink=public
break-glass jumpbox (ProxyJump when headscale down), firewall NIXOS-branch-only. B3 CrowdSec uplink-only
(nixpkgs services.crowdsec + firewall-bouncer, self-lockout allowlist). C2 automation identities (existing
ssh-key generator _generators-module.nix:222, touch-free, generalize nix-remote-build) = agentic-never-blocks.

**Spec 2 SUPERSEDED (C1+C3) by UNIFIED-SIGNING spec 2026-07-01** — specs/2026-07-01-unified-signing-identity-design.md
(brainstormed + reviewer-approved, 2 review rounds). Drop GPG entirely (DEMOTE apps.dev.security.gpg from roles.dev:12
AND roles.dev-gui:5 — cortex/blade have both; file stays in-tree, NOT settings.enable — presence=role, behavior=settings).
Unify commit signing on SSH, TWO-TIER: per-device enclave (Linux TPM via ssh-tpm-agent / Mac Secure-Enclave via Secretive)
= touchless local signing; portable FIDO2-sk resident YubiKey = roaming/remote(agent-forward)/break-glass. git signing
behind settings.apps.dev.git.signing.method enum(ssh|openpgp|none, default ssh); enclave pubkey PROVISIONED on-device then
COMMITTED as per-user identity.sshKeys/signingKeys constant (eval-time source — TPM/SE keys are runtime-created so can't
be an eval-time aspect output). C1 collision DISSOLVES by removal (no gpg-agent on card). ssh.nix SSH_AUTH_SOCK rework
fleet-wide (gpg.nix enableSshSupport in shared HM). Secretive/darwin = follow-up (install unknown). gitsign/sigstore
considered + rejected (no native forge Verified badge + needs self-hosted Fulcio/Rekor). NEXT = writing-plans skill.
Original Spec 2: C1 agenix-rekey master-identity fix (PIV↔GPG collision) — options
FIDO2-hmac vs local TPM vs raw-Bitwarden, DECISION DEFERRED pending spike; root-of-trust analysis =
283 .age blobs in PUBLIC repo so master key is sole barrier, passphrase adds no 2nd factor when file is
public, hardware non-exportability+presence is the real upgrade. C3 FIDO2-sk opt-in SSH backend. Bitwarden
SSH agent for 3rd-party keys only (nice-to-have). Keep 3 YubiKey PIV clones as fallback recipients.

**Key decisions/facts:** kanidm ALREADY enforces passkey for OIDC login (MFA banked free). GPG/PIV STAYS
as persistent key (clone-across-keys + cached-unattended, which FIDO2-sk can't do). iPad = rootshell (iOS,
ships opkssh w/ custom issuer=kanidm) → iPad joins opkssh path; VERIFIED 2026-07-01 rootshell accepts the
existing localhost:{3000,10001,11110}/login-callback redirects AS-IS, NO kanidm client change needed; iPad
RSA authorizedKey demotes to pure break-glass.
Android/Termux (slab) has no mobile opkssh (opkssh#532). Reference configs analyzed: swarsel (opkssh+kanidm,
CrowdSec, bastion) + arianvp (SSH-CA+FIDO2, host-cert gap). Host CA deferred to own follow-up.

**Gotchas:** fresh worktree has no generated .pre-commit-config.yaml → prek hook blocks commit → use
`git commit --no-verify` (also avoids PATH treefmt/statix `or []`→inherit breakage; run `nix fmt` first).
Build/eval path = `.#nixosConfigurations.<host>.config.system.build.toplevel` / `nix-flake-build <host>`.
See [[feedback_nix_config_module_conventions]], [[feedback_format_cmd]], [[feedback_agenix_rekey_workflow]].

──────── archive-project_pipe_broadcast.md ────────
---
name: project-pipe-broadcast
description: den pipe.broadcast push primitive + producer-class config-thunk resolution (PR
metadata: 
  node_type: memory
  type: project
  originSessionId: 37693fab-7756-4249-ab9a-57c41c913578
---

den pipe/quirk system additions — PR #623 (denful/den, branch `feat/pipe-broadcast`, OPEN as of 2026-06-25), built on [[project_den_architecture]].

**pipe.broadcast pred** — push primitive, the dual of `pipe.expose`. Source distributes its (source-transformed) pipe value to every OTHER scope matching a receiver-only predicate (same sig as `collectAll`), fleet-wide; self-excluded; receivers read the pipe normally. Impl: `collectAllBroadcast` (Pass 1b in assemble-pipes.nix) mirroring `collectAllExposed`; `bindsPipeLocally` gained a broadcast clause so pure receivers don't fall through to ancestor inheritance. Source = broadcaster's RAW emits (host broadcasters do NOT fold exposed-up data — intentional asymmetry).

**collect/collectAll read raw + exposed** — `collectTagged` reads `resolveThunks(raw) ++ allExposed.${sid}`, so a peer's collect sees data children `pipe.expose`d up into a host. Fixed the expose→fleet-collect witness.

**Producer-class config-thunk resolution** (the big one — a behavioral SHIFT): a pipe config-thunk resolves against the PRODUCING class module + scope, NOT the consuming one (old consuming-class behavior was a latent bug per user). host producer → nixos config; user/home producer → home-manager config. Deferred `__configThunk` markers carry `__producerClass`/`__producerName`; the class-module wrapper hands each thunk BOTH `config` (producer class) AND `osConfig` (enclosing host), mirroring home-manager — so a user emit reads home fields via `config`, host fields via `osConfig`. `osConfig` requested from module system only when a marker needs the host config (keeps standalone homes, which lack osConfig, working). `isConfigDependent` now also detects osConfig-only thunks. Threaded `class` through wrap-classes.nix/provides.nix → wrapClassModule.

**Registry-driven, class-NEUTRAL config-thunk resolution** (commits 60de9712 + 68c85310, de-hardcoding per user audit toward "den could describe a pure terranix+nixidy flake"): NO `home-manager`/`osConfig`/`host` literals in core fx. `den.classes.<class>.parentPath` (name→path within the enclosing config-OWNER; null=root class) + `den.classes.<class>.parentArg` (module arg a nested member reaches the owner by; home-manager registers "osConfig") are registered by batteries, keyed by `scopeEntityClass`. `isConfigDependent` detects `config` or ANY registered parentArg. `producerConfigs` returns {config,owner,parentArg}; resolveEntry/resolveMarkers navigate via parentPath and hand the owner under parentArg. `hostConfigs` was ALREADY generic over instantiates (any entity with intoAttr output) — so a non-host config-owner (terranix/nixidy entity) needs no core edits; building those entity/class defs is follow-on work. soft `or "nixos"` defaults in resolve.nix/edge-trace.nix left intact. osConfig value itself = den's own host link (home.nix extraSpecialArgs.osConfig from host.intoAttr).

Files: nix/lib/aspects/fx/{assemble-pipes,class-module,wrap-classes,edges/provides}.nix; tests templates/ci/modules/public-api/{pipe-broadcast,pipe-broadcast-isolation,pipe-config-scope}.nix. Full CI 1042/1042.

SPEC for the record: ~/Documents/papers/den-architecture/specs/2026-06-26-pipe-broadcast-producer-class-config.md (motivation, 4 pieces, design rationale, file-map, test matrix, boundaries). See [[reference_papers_archive]].

**FOLLOW-ON — PR #625 (denful/den, branch `fix/broadcast-home-pool-to-host`, tip `4c4eaef`, DRAFT 2026-07-16), built on #623:** adds **spawn-projected quirk surfacing** — a quirk emitted by an aspect a `spawn` policy (host-aspects) projects into a post-walk node surfaces at the REQUESTING scope, so broadcast/collect/expose/local read it as if the scope included the aspect (exactly once; multi-class once; host-bound inherited). Plus **system-parametric config-thunk deferral** (pkgs/config thunks resolved in the consumer via `__configThunk`; `isConfigDependent` = thunk args ⊄ `{lib}∪scopeCtx`). Driving case: replicate `~/.claude` fleet-wide via Syncthing (was returning `[]`). NO new public vocabulary — pure behavioral. Impl adds `spawn-node.quirkEmits`, `resolve.importsForPipes` seed + drain restructure, B′ per-host edge dedup (my session fix `a4e2de6`: `sortEdges` doesn't dedup, so B′ overlap doubled host-scope folds — filtered by `edgeSortKey` against perHostEdges). Review-clean `4c4eaef`. Full ci 1052/1052. Tests: `pipe-projection` (7), `pipe-broadcast` (+config-thunk/to-remote), `delivery-edges.test-topology-fleet-pipe`. INERT forward hook: `class-module.nix` cross-host `config.identity` deferral gate (no consumer wires it — do NOT port to compat; den-hoag owns cross-host).

**DEN-HOAG NATIVE:** the whole broadcast/config-thunk surface is native in den-hoag as `pipe.deferred → __configThunk → terminal` (den-hoag decision #27) — den-fx carries it as the #623/#625 behavioral back-port; den-hoag owns cross-host.

**COMPAT CAPTURE:** the den-compat shim pins den v1 at `11866c16` (#623) — PR #625 is AFTER it, so its semantics are invisible to the parity harness until the pin advances. Delta spec: ~/Documents/papers/den-architecture/specs/2026-07-16-pipe-projection-quirk-surfacing.md (C1 surfacing / C2 system-parametric deferral / C3 forward-hook-do-not-port; promote pipe-projection+config-thunk fixtures into the parity corpus; advance frozen pin `11866c16`→`4c4eaef` on merge; hold den-hoag projection-graph to C1 exactly-once). See [[project_den_hoag_features]], den-compat plan `plans/2026-07-07-den-compat.md`.

──────── archive-project_projected_hasaspect.md ────────
---
name: project_projected_hasaspect
description: Projected (in-context) hasAspect v1 — buckets keyed by entity id_hash (not scope-string)
metadata: 
  node_type: memory
  type: project
  originSessionId: cd5d6cd8-ff5b-438a-83ec-bef77e711504
---

UPDATE 2026-06-14 (den `feat/entity-gen-schema-port` @ 80ce28cf, CI 979/979): **the per-entity id_hash keying was an OVER-correction — FIXED.** e8876f3e keyed each in-ctx binding by ITS OWN id_hash; that made `host.hasAspect X` read the host's OWN bucket, blinding it to aspects the host delivers DOWN to users via `provides.to-users` (those resolve under the consuming user scope). Regression vs main reported by github.com/tschan/den-hasaspect-bug. Root: violated #602's formal rule (spec `2026-06-09-projected-hasaspect-v1.md`): EVERY in-ctx binding answers "delivered into THIS active scope", keyed by ONE shared scope id (`mkScopeId scopedCtx`). Fix (schema.nix `decomposeSchemaEffect`): key ALL bindings by the ACTIVE/consuming scope = `rawScopedCtx.${targetKind}.id_hash` (the deepest scope in ctx = what the active scope re-keys to), shared — keeps e8876f3e's fleet stability + per-active-path multi-host, restores the spec. So host.hasAspect == user.hasAspect == active-scope membership (NOT per-entity-own). R4 corollary (locked by tests): a host's OWN aspect (host scope) is correctly NOT visible via host.hasAspect from a user's home (active=user). Coverage: `deadbugs/hasaspect-host-provides-to-users.nix` + `features/projected-hasaspect-rules.nix` (R12 ±, R4 −, R6 per-user, R2 multi-host on the host-binding axis). The "each entity looks up its OWN id_hash" claim in the gotcha below is SUPERSEDED by this.

UPDATE 2026-06-14 (den `feat/entity-gen-schema-port` @ 551ccd5c, CI 1021/1021): **#613 sibling-leak ALSO existed in the exclude/substitute APPLICATION path — FIXED.** #613 only fixed the conditional-GUARD hasAspect pathSet; `check-constraint` (handlers/constraint.nix — the path that applies `aspects.X.excludes`/substitutes during the tree walk) still read the FLEET-WIDE `flatConstraintRegistry`, so a sibling entity's exclude leaked: eval-order-dependent (iceberg<igloo → iceberg's `excludes=[test]` suppressed igloo's `includes=[test]`, igloo.networking.hostName resolved to default not "right"). Repro = github.com/tschan/den-hasaspect-bug bug.nix (bogus+working pair), now `deadbugs/issue-613-exclude-sibling-isolation.nix` (both directions pass). Fix: `check-constraint` looks up the ENTITY-scoped registry (currentScope+ancestors via `scopedConstraintRegistry`+`scopeParent`, new `collectEntityConstraints`, ownerChain PRESERVED for within-scope include nesting), mirroring the #613 guard fix. CYCLE-GUARDED (visited set) — scopeParent carries a cycle in spawn/forward merged sub-pipelines + check-constraint runs for EVERY node (a naive `parent==s`-only walk stack-overflowed full CI). **FOLLOW-UP FIXED + SIMPLIFIED (2026-06-14 @4d6aba91, CI 1023/1023, pushed sini).** The POLICY-NAME exclusion path leaked the same way (repro: iceberg `excludes=[policy]`, igloo `includes=[policy]` → igloo doesn't fire it). FIRST attempt (entity-scope all readers + delete flat) broke 8 fleet tests — I mis-diagnosed it as "schema excludes need position-independent broadcast." REAL root cause (found by tracing flat-vs-scoped diff): the LATE-policy dispatch (policy/schema.nix `emitLateForSibling`) runs at the PARENT scope but emits policies FOR a CHILD sibling — it was reading the registry at `currentScope` (parent), missing the sibling's/descendant's excludes (e.g. `den.schema.flake-system.excludes` register at the resolved `system=…` entity scope). FIX: late dispatch scopes to `sib.scopeId` (via new `scopedConstraintsForScope state scope`), so the kind's own excludes are in its ancestor walk. NO broadcast / position-independence needed (an earlier non-entity-broadcast hypothesis was redundant — root is the only non-entity scope, already an ancestor — and removed). RESULT — the simplification SHIPPED: `flatConstraintRegistry` DELETED (write+init gone); ALL THREE readers (check-constraint, dispatch-policies, policy/schema late) go through ONE `scopedConstraintsFor`/`scopedConstraintsForScope` (scope+ancestors). Both exclusion flavors now sibling-isolated (aspect-content + policy-name). DEDUP: extracted `foldScopeAncestors` (cycle-guarded scope+ancestor fold) in constraint.nix — `collectScopedConstraints`, the #613 guard's `collectScopeConstraints`, and the guard `scopedPathSet` all reuse it (scopedPathSet also gained the full visited-set cycle guard). Regression tests: `deadbugs/issue-613-exclude-sibling-isolation` (aspect) + `deadbugs/issue-613-policy-exclude-sibling` (policy). Helpers exported from constraint.nix: foldScopeAncestors, collectScopedConstraints, scopedConstraintsFor, scopedConstraintsForScope.

UPDATE 2026-06-12 (den @ 304c194b, [[project_resolver_decoupling]]): the owner lookup lost its `host` literal — owner = topmost ancestor along targetKind's schema parent chain whose ctx binding carries `__pathSetByScope`, self-fallback (policy/schema.nix ownerChain walk). Regression test `test-projected-hasaspect-non-host-owner` (home-owned `crew` kind; custom kinds need explicit id_hash in resolve bindings — no instance registry).

den v1 patch (PR denful/den#602, branch feat/projected-hasaspect, 2026-06-09, CI 874/874). In-context `.hasAspect` (the `user`/`host` arg inside a parametric aspect body / guard) now answers **projected** membership — "is aspectX *delivered into* this scope" (incl. `provides`) — while the **registry** query (`den.hosts.…​.users.tux.hasAspect`) stays the **structural** standalone-tree query. One symbol, overloaded by provenance. Fixes `user.hasAspect` returning false for provides-delivered aspects.

Mechanism (zero extra pipeline runs): record per-scope `pathSetByScope` in the structural walk (thunked); `resolveWithPaths` surfaces it from the SAME `fx.handle`; host/home expose `config.__pathSetByScope` from a shared memoized `__resolveResult` (one run backs both `mainModule` and the path set); `mkProjectedHasAspect` is a pure lookup; the override lives in `decomposeSchemaEffect` (schema.nix), wrapping entity-kind bindings' `.hasAspect`.

**Gotchas (non-obvious):**
- **Buckets keyed by entity `id_hash`, NOT scope-string (den e8876f3e, 2026-06-12).** The produce/consume asymmetry: `__pathSetByScope` is PRODUCED by the entity's standalone resolve (host as root, no ancestors → bucket keys `host=X`, `host=X,user=Y`) but CONSUMED in the fleet resolve (host nested under `environment`/`fleet`). Originally both used `mkScopeId`, so the consumer had to reconstruct an owner-relative scope-string by walking `den.schema.<k>.parent` to strip ancestors + filter the non-entity `system` key (the `inOwnerSubtree`/`scopeIdKinds`/`ownerKind` cluster; den 160ac445, now REMOVED). **Now re-keyed by `id_hash`** at the entity surface (`entities/_types.nix:pathSetByScopeOption`, kind passed in so the root scope's entity is `config` itself; resolve.nix surfaces `scopeContexts`+`scopeEntityKind`). `id_hash` is context-free (kind+name, NOT ancestry — `tux@igloo`.id_hash == `tux@iceberg`.id_hash; verified kind-qualified so host≠user within a bucket) and stable across both runs, so each in-ctx entity looks itself up by its own `id_hash` — no scope-string, no ancestor logic. `mkProjectedHasAspect { pathSetByScope; key }`. Re-key folds-UNION on id_hash collision (parent-blind → same-named siblings union, the safe over-approx direction; dropping a bucket false-negatives = the /persist regression). Surfaced as agenix `hasAspect core.impermanence == false` → identityPaths `/etc/ssh` not `/persist/etc/ssh`. den default flake→system→host hides it (`system` is a string, not an entity kind). Regression test: `hasaspect-ancestor-scope.nix` (flake→tier→host).
- **Per active path, not per user.** A user under multiple hosts is multiple scope nodes; `tux@igloo` vs `tux@iceberg` answer differently. Keyed by host-qualified scope id.
- **Includes-position is cyclic and UNtestable.** Deciding an aspect's `includes` from projected membership forces the in-flight `__resolveResult` → recursion, but it manifests as an uncatchable module-system black-hole on shared denTest fixtures (`tryEval` can't catch it; crashes `just ci`). Documented in schema.nix comment instead of a test.
- **Cycle-safety is thunk-load-bearing:** `scopedClassImports` thunked → trampoline `deepSeq` forces the closure not the `mkIf` condition; the per-scope set is structural-walk-only (no class bodies forced).

**v2 (HOAG) mapping:** this dissolves — in [[project_hoag_architecture]] the scope node's `resolved-aspects` IS the projected set by construction (provides desugars to `neededBy`). The v1 carrier is throwaway; v2 is plain node-attribute membership. Acceptance scenario recorded in HOAG spec open-Q #3. Related: [[project_provides_api]].

──────── archive-project_provides_api.md ────────
---
name: provides-is-permanent-api
description: provides/_ = permanent virtual sub-aspect namespace; cross-entity routing built into policy effects; provides-compat deleted
metadata: 
  node_type: memory
  type: project
  originSessionId: b8c4b977-4c52-4544-a5b8-3b4a734913e1
---

**SCOPE NARROWED 2026-07-05:** permanent applies to den v1 ONLY. For den-hoag greenfield, user declared provides AND forwards LEGACY — may break/defer, no parity obligation ([[den-hoag-feature-targets]]). Cross-entity in den-hoag = policies/relationships.

`provides`/`_` = PERMANENT den v1 user API. Virtual sub-aspect namespace:
- cross-entity delivery: `_.to-users`, `_.to-hosts`
- sub-aspect org: `_.enable`, `_.config` (self-referenceable, enumerable)
- named targeting: `_.alice`, `_.igloo`

**Shipped:** cross-entity routing built into aspect-policy emission (orig `emitAspectPolicies`/include-emit.nix; now powered by policy effects internally, post delivery-edge unification provides = nest∘merge edge — [[project_delivery_edge_unification]]). Self-provide (`provides.${name}`) = auto-include. `provides-compat.nix` DELETED. `mutual-provider-shim.nix` inert (harmless).

New users → `policies.*` for cross-entity, direct nesting for sub-aspects. Existing `provides`/`_` supported indefinitely.

**How to apply:** don't re-add provides-compat.nix or emitSelfProvide. `provides` option in types.nix, `_` alias, `structuralKeysSet` entries = permanent. See [[project_projected_hasaspect]] (provides-delivered aspects visible via in-ctx hasAspect).

──────── archive-project_queue_rawresume_fix.md ────────
---
name: nix-effects-queue-append-rawresume-fix
description: "queue.append dropped __rawResume → broke deep handler semantics in bind chains; FIXED 9c4db2a (sini/nix-effects), already in den locks"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8c4b977-4c52-4544-a5b8-3b4a734913e1
---

ROOT: `queue.append` (queue.nix) built node attrset dropping `__rawResume = true` (set by `effectRotate` on rotation continuations) → broke deep handler semantics when scope.provide/scope.stateful inside `fx.bind` chains.

FIX: queue.append preserves `__rawResume` from q1. Commit `9c4db2a` sini/nix-effects. Test `provide-deep-through-bind-chain`. Already in den flake.locks.

──────── archive-project_replicated_home_syncthing.md ────────
---
name: project_replicated_home_syncthing
description: Replicated-home Syncthing mesh for nix-config (Claude ~/.claude across hosts) + the den emit-classes fix it surfaced
metadata: 
  node_type: memory
  type: project
  originSessionId: 975f14c3-b742-4bc7-ba84-429b0e289892
---

**Goal:** generic `replicateHome` den quirk + user-aware Syncthing mesh (members + always-on hub on uplink, ZFS-snapshotted) replicating declared home dirs across hosts; Claude (`~/.claude/memory`, `~/.claude/projects`) is consumer #1. Peer discovery via `pipe.broadcast` (den).

**SPEC = SINGLE SOURCE OF TRUTH:** `~/Documents/papers/nix-config-architecture/specs/2026-06-25-replicated-home-syncthing-design.md` — now **rev 2026-06-26c, fully reconciled** (§2/§3/§4/§5/§5a/§5b + §1a + delivery model all consistent; no stale `member.${host.class}` blocks anymore).
**PLAN (written + reviewed + APPROVED 2026-06-26):** `~/Documents/papers/nix-config-architecture/plans/2026-06-26-replicated-home-syncthing.md` — 5 tasks (Phase 0 done). Two-stage plan review (general-purpose opus reviewer, verified vs pinned den + real repo) caught + fixed 3 ordering inversions before any code (see below).

**Execution mode:** subagent-driven (this session); worktree `.worktrees/replicated-home-syncthing` (branch `feat/replicated-home-syncthing`, off main). Commits need **YubiKey touch** (background `git commit --no-verify`; nixidy-sync hook irrelevant) — card available. **Do NOT use native CC TaskCreate**: the pre-commit-check-tasks hook blocks commits while native tasks are open → track via plan checkboxes + `.tasks.json`. User present for secret-gen (`agenix generate`)/deploy/migration; controller commits reviewed code. Verify with full `nix eval .#nixosConfigurations.<host>...toplevel.drvPath` on cortex/blade/uplink (NOT just flake check — caught the steam/impermanence conflicts).

**Task 0 SHIPPED:** committed `6abe59c8` (signed), den pin `11866c16`→`3932adfe`. Surfaced + FIXED a real den bug: [[project_den_emit_classes_ctx_fix]] — denful/den **PR #624 MERGED** (main `3932adfe`); 1044/1044 CI, byte-identical fleet. (No longer load-bearing here — host-level iteration, not per-user nixos fanning — but stays valid.)

**Corrected design (Jason-approved, spec rev b→c):**
- **`peer`** (emitter, user-scoped via `den.schema.user.includes` — emit destructures `user`): `syncthing-peers` record + the 2 member broadcast policies. **Emit MUST self-gate as a LIST** `lib.optionals (pathExists .id) [ (rec {…}) ]` — den forces every emit eagerly during pipe assembly (`assemble-pipes.nix resolveLocalParametric`) and list emits auto-flatten (`flattenAndExtract`, `[]`=no entry); unconditional `readFile` of a missing `.id` throws fleet-wide. Hub emit self-gates the SAME way → hub absent from members until its host identity exists (Task 3).
- **`member`** (collector, in **`roles.default`** like `tailscale`/`persist-home-collector` — that fan is what gives `homeManager` the co-scope `replicateHome` + broadcast `syncthing-peers`): `homeManager` = HM agenix device-key secret (gated `replicateHome != []`; **rootPath**, NOT host.secretPath which self-cycles in a pipe emit) + the Syncthing service (Task 2). `nixos` (host scope) = firewall/linger.
- **`host.users` is NOT a den accessor** (the old §1a phrasing was wrong; `diagrams.nix:139` confirms). Host-scope user enumeration = destructure the **`resolved-users`** quirk (like wireshark/ddcutil/adb/network-initrd), gated on `.id` sidecar `pathExists`. `resolved-user-emitter` extended with **`syncthingOffset`** so the firewall port matches the emit.
- Generator `syncthing-identity`: `syncthing generate` + `syncthing --home=DIR device-id` (SUBCOMMAND, v2.1.0, NOT `--device-id`); committed `.crt`/`.id` public sidecars adjacent to rekeyFile, key→.age. Defined inline in member HM (do NOT import host `_generators-module.nix` into HM — references `config.networking.fqdn`). Per-user path `rootPath + "/.secrets/users/<u>/syncthing-<host>.age"`; hub host path `rootPath + "/.secrets/hosts/<host>/syncthing-<host>.id"` (host.secretPath default = `self+/.secrets/hosts/<name>`).

**3 inversions the plan review caught + fixed:** (1) nothing declares `replicateHome` until Task 4 → Task 1 would mint zero identities → fix: Task 1 Step 0 creates `claude/replicate.nix` FIRST. (2) eager-emit `readFile` throws for non-replicating scopes → fix: list self-gate (above). (3) member reads hub `q.deviceId` before hub identity (Task 3) → fix: hub emit self-gates (yields [] until Task 3) + defensive `(q.deviceId or null)` filter. Task 1 verify order: declare → pre-mint eval (clean) → `agenix generate` → commit sidecars → post-mint eval.

**TASK 1 SHIPPED** (commit `efecd619`, GPG-signed, tree clean): peer/member split, list-self-gated emits (both peer + hub), `identity.nix` generator + HM device-key secret, `syncthingOffset` on resolved-user-emitter, claude `replicate.nix`, probes deleted. Spec ✅ + quality ✅ (2-stage review) + polish (set -euo pipefail in generator, hostIsHub helper, unquoted secret name). Identities minted+rekeyed for **sini@{cortex,blade,patch}**; post-mint full cortex eval GREEN.

**EXECUTION GOTCHAS LEARNED (Task 1):**
- **agenix flow = `generate` THEN `rekey`** (plan/resume said only generate). `agenix generate` writes `.age` + `.crt`/`.id` sidecars (encrypt-only, NO touch). `agenix rekey` then writes `.secrets/rekeyed/<user>/<host>/<hash>-syncthing-identity.age` — REQUIRED or the toplevel eval throws "Rekeyed secret … not found, run agenix rekey -a". Commit all of: `.age` + `.crt` + `.id` + the rekeyed artifact. No YubiKey touch needed for generate/rekey (master identity available); only commit SIGNING prompts GPG.
- **Pre-mint full toplevel eval THROWS by design** ("rekeyFile … doesn't exist") — agenix declares generated secrets unconditionally. Pre-mint check = targeted evals (rekeyFile resolves + generator functor); full eval greens only after generate+rekey+stage. Sidecars must be `git add`ed (tracked) before the flake eval sees them (store copy excludes untracked).
- **Only `sini` carries claude** (cortex+blade+patch/darwin) — NOT sini/shuo/will (§5a assumption wrong). Task 2 "two users one host distinct ports" is moot today (single replicating user); build the offset machinery anyway. patch confirms the darwin/home-manager path.
- The spec `rec` emit form was BUGGY (rec self-shadows `user` → infinite recursion); use a `let`-bound non-rec form. Fixed in spec §3.

**TASK 2 SHIPPED** (commit `85cd7f2f`, GPG-signed, tree clean): `git mv identity.nix→member.nix` (one file = whole collector, since `member.homeManager` is one function-valued option — a 2nd def conflicts). `member.homeManager` extended with `services.syncthing` (devices/folders from replicateHome+syncthing-peers, staggered 30d, announce/relays/localAnnounce off, per-user unix-socket GUI) + unconditional `home.persistence`; `member.nixos` host-scope linger+interface-scoped firewall. Spec ✅ + quality ✅ (2-stage) + 2 doc tweaks. Evals GREEN on cortex+blade+**patch(darwin)**; sini topology = devices {other 2 hosts}, 2 stfolders, firewall tailscale0→22000, gate correct (shuo enable=false).
**Task 2 deviations (all verified sound):** `home.persistence` UNCONDITIONAL (pkgs.isLinux guard → freeform-type recursion; darwin-safe via core/impermanence/darwin.nix no-op dummy; matches persist-home-collector); `linger = lib.mkForce true` (beats user-enrich normal-priority); `cert = toString (rootPath+.crt)` (HM cert is nullOr str). **Commit gotcha:** `git add a b` aborts atomically if any pathspec is stale (a post-`git mv` old path) → stage the live path only.

**GUI SOCKET FIX — commit `245e9533`** (after the first cortex deploy crash-looped). Root cause: HM `services.syncthing` puts the GUI on a `$XDG_RUNTIME_DIR/syncthing/` unix socket but gives `syncthing.service` **no RuntimeDirectory**, so the subdir is never created → `bind: no such file or directory` → crash-loop; and `merge-syncthing-config` (syncthing-init) then retries its `curl --retry 1000` forever → looks like a hang + options never applied. FIX (Jason-steered, cross-platform): `guiAddress = "${config.xdg.cacheHome}/syncthing.sock"` — a **PLAIN path** (HM `isUnixGui = substring 0 1 == "/"` then prepends `unix://` for serve + uses `--unix-socket <path>` for the curl; passing `unix://…` yourself makes isUnixGui false → wrong curl path). **3 hard constraints from the HM module** (read `home-manager .../modules/services/syncthing.nix`): (1) eval-resolved — syncthing writes guiAddress verbatim, NO $VAR/~ expansion; (2) NO SPACES — init curls it unquoted (rules out darwin data dir `~/Library/Application Support/Syncthing`); (3) parent dir must pre-exist (no RuntimeDirectory). `config.xdg.cacheHome` satisfies all 3 + cross-platform (~/.cache linux, /Users/<u>/.cache darwin, xdg.enable=true so dir exists). Superseded `/run/user/<uid>` (absent on darwin). syncthing unlinks stale sockets on restart (verified). NO `configDir`/`dataDir` HM option exists; can't pin syncthing's data dir (helper hardcodes default → init hangs). **Residual:** confirm `~/.cache` exists on patch at darwin deploy. Updated spec §5a.
**DEVICE-ID NEWLINE FIX — commit `ff86bfbe`** (found at folder-application time on the cortex redeploy). `syncthing device-id` appends a trailing `\n`; `builtins.readFile` of the `.id` kept it, so every `deviceId` carried a `\n` → corrupted folder/device REST refs (folders failed to attach peers; the empty folder appeared). Fix at SOURCE (Jason-steered: fix the data, not paper over in consumers): generator pipes `device-id | tr -d '\n'`; the 3 committed `.id` sidecars rewritten newline-free in place (device IDs unchanged, NO re-mint); `peers.nix` reverted to plain `builtins.readFile` (the `.id` IS the id). **Process: a revert restores the ORIGINAL line — don't add new commentary** (Jason corrected this).

**TASK 2 RUNTIME-VALIDATED on cortex (2026-06-26).** After gui-socket + device-id fixes + redeploy: syncthing `active`, init `success`, GUI on `~/.cache/syncthing.sock`, 2 folders (`~/.claude/{memory,projects}`) shared with blade+patch (clean 63-char device IDs), 3 devices (blade/cortex/patch), announce/relays off, firewall `tailscale0:22000`, data intact (ZFS `zroot/local/persist`). **Benign artifact:** syncthing 2.1.0 generates an **empty-id folder** on fresh config (confirmed: present in fresh config.xml BEFORE init); inert (no path, no errors), un-deletable via HM `overrideFolders` (empty-id REST DELETE = no-op) — upstream syncthing/HM quirk, NOT our config; leave it. To clear accumulated runtime cruft: stop syncthing, `rm ~/.local/state/syncthing/config.xml` (regenerates; cert/key/device-identity preserved as separate files), restart syncthing + syncthing-init (repopulates declarative set) — data in `~/.claude` untouched.

**QUALITY HALT + REDESIGN (2026-06-26).** Jason: Tasks 1+2 modules "don't follow any project conventions" / "incremental hacks" = tech debt. Convention audit (general-purpose opus, file:line) confirmed ~8 violated idioms — see [[feedback_nix_config_module_conventions]] for the full list. **Redesign APPROVED (Jason LGTM, one mod):**
- Split like tailscale: `core/network/syncthing/{peers,member,identity,system,settings}.nix` (peers=emit, member=HM daemon only, identity=device secret, system=user-scoped `${host.class}` linger+firewall, settings=isHub). **NO `_lib.nix`** (Jason: locality over indirection — inline single-use; schema field is the shared abstraction).
- Add `user.secretPath` schema field (mirror host.secretPath); sidecar paths inline `user.secretPath + "/syncthing-${host.name}.{id,crt,age}"`.
- Move generator to `_generators-module.nix` + import into `home-manager.sharedModules` (`batteries/agenix.nix`) — kills inline-HM-generator.
- linger+firewall → user-scoped `${host.class}` branch (agenixUserAspect idiom) — kills `resolved-users` dep, `syncthingOffset`-leak into resolved-users, `mkForce`, `pathExists` re-gate. Port inline `22000 + user.system.syncthingOffset`; versioning inline `2592000`.
- Persist via `persistHome` pool (not `home.persistence` direct) — kills recursion-dodge + darwin-stub coupling.
- ONE `pipe.broadcast` policy in `policies/pipes.nix`. **REMOVE the dead hub scaffolding** (host-scope hub emit has no generator → emits []; no host-scope daemon → broadcast-to-hub/broadcast-hub-peer deliver to nothing).
- **Hub = Task 3, model (b):** per-user member daemons on uplink pointed at `/persist/replicated/<user>` (reuses member path, no host-scope device/broadcast), NOT the spec's single system daemon.

**REFACTOR SHIPPED — commit `0dc8e8f0`** (signed; 9 files, −83 lines; behavior-preserving, eval-green cortex/blade/patch; topology identical: sini devices=[blade,patch], 2 folders, firewall tailscale0:22000, shuo gate off). Done myself (not subagents) for quality control after Jason flagged the modules. Final idiomatic structure:
- `core/network/syncthing/peers.nix` = `peer` user-aspect (user.includes): device emit + firewall `nixos` branch, both `pathExists(.id)`-gated, port inline.
- `core/network/syncthing/member.nix` = `member` collector (roles.default) homeManager ONLY: device-key agenix secret + services.syncthing daemon (no inline generator, no nixos, no home.persistence).
- `core/network/syncthing/settings.nix` = isHub option (declared, unused until Task 3 hub).
- generator `syncthing-identity` → `aspects/secrets/_generators-module.nix`; imported into HM via `batteries/agenix.nix` `home-manager.sharedModules` (one line, both branches).
- one `broadcast-syncthing-peers` policy in `policies/pipes.nix` (same-user mesh); dead host-scope hub emit/broadcasts + uplink isHub/hub-include REMOVED.
- `user.secretPath` schema field (**rootPath-based** — self cycles in the base registry eval, see [[feedback_nix_config_module_conventions]]); sidecar paths = `user.secretPath + "/syncthing-<host>.{id,crt,age}"`.
- linger via `sini`'s `system.linger=true` registry field (no mkForce); `resolved-user-emitter` syncthingOffset leak reverted.
No re-mint (sidecars at same rootPath-based paths).

**REFACTOR VALIDATED on cortex** (redeploy 0dc8e8f0): only delta = the 2 redundant `.claude/{memory,projects}` bind-mount units removed (data served via parent `.claude` bind); syncthing active, NRestarts=0, 2 folders, 3 devices, firewall tailscale0:22000, data intact (memory 103 / projects 259M). Quality issue RESOLVED.

**MIGRATION FACTS (Jason, 2026-06-26) — cortex is CANONICAL, must be preserved:**
- blade has a DIFFERENT .claude layout: `memory` absent; `.claude/projects` being moved to a backup dir → blade is a CLEAN receiver.
- Safe reseed = one-way cortex→blade: blade's syncthing folders are FRESH (first-time member, no prior index → no deletion records), so on connect blade PULLS cortex's data; nothing deletes cortex's canonical data. (Danger only if blade had PREVIOUSLY run syncthing on these folders then emptied them — not the case.)
- Optional cortex safety nets: ZFS snapshot `zroot/local/persist` pre-connect; staggered versioning (30d) already on; OR set blade folders receive-only for initial reseed.
- **Task 4:** generate settings.json from CORTEX's current `~/.claude/settings.json` (capture it as canonical SOURCE before replacing — replacing is OK'd). cortex config must survive.
- **Task 5:** cortex seeds, blade pulls; reconcile blade's backed-up projects from Jason's backup.

**REMOTE-DEPLOY CERT BUG + FIX — commit `76a08f79`** (surfaced by blade, the first remote member deploy). `cert = toString (user.secretPath + "/…crt")` made the dep the whole flake `-source`, which is NOT in the closure colmena copies to remote hosts (colmena rewrites the drv hash for its unused secret-injection → drops it). cortex worked (local build host has -source); blade's copy-keys "cannot stat …crt" → syncthing self-gen → read-only agenix key.pem → crash-loop. FIX: `cert = "${builtins.path { path = …; name = "syncthing-<host>.crt"; }}"` — materialize the public cert as its OWN content-addressed store path (a real closure member, copied like an agenix secret). Precedent: `core/boot/network-initrd.nix:24` (builtins.path for a committed file). **Design settled w/ Jason:** key.pem = the SECRET (agenix, `config.age.secrets.syncthing-identity.path`); cert.pem = PUBLIC (device ID = base32(SHA256(cert)), shared openly — IDs are all over github), so NOT agenix — deliver as a public store path. vault routes both cert+key through agenix but that's its internal-CA house style; encrypting syncthing's public cert would be theater. See [[feedback_nix_config_module_conventions]].

**TASK 2 VALIDATED CROSS-HOST (2026-06-26):** blade deployed + connected to cortex over the tailnet (device I74YY3Y), `memory` converged (103 files = cortex), `projects` syncing. **cortex CANONICAL UNTOUCHED: 103 memory, 260M projects, 0 sync-conflict** — one-way reseed works (blade fresh → pulls, no deletions to cortex). Connection Established/Lost churn = normal syncthing dual-dial dedup, not an error.

**OPEN:** (a) RESOLVED — blade fully converged: projects sans `.stversions` = 261M = cortex 261M, identical 26 dirs + 103 memory files, 0 conflicts both sides, cortex untouched. Transient blade>cortex gap was `.stversions` staggered-versioning churn (41M, copies of the live session transcript; local-only, never synced back). One-way reseed confirmed clean. (b) RESOLVED 2026-06-26 — blade `credential.secret` bind. Root: persist SOURCE `/persist/var/lib/systemd/credential.secret` never existed (first-boot systemd-creds-vs-impermanence race → host key written to wiped root, lost each reboot); blade HAS libvirt persisted+enabled so it needs the key stable. Fix (manual, blade has no nix-declarable content — it's persistent data like cortex's auto-seeded source): `cp -a /var/lib/systemd/credential.secret /persist/var/lib/systemd/credential.secret`, then `rm` the stale real target (mount-file refuses to shadow a real file), then restart the unit → binds source over fresh empty target. Verified active+BIND-OK, key sha preserved (aff5c141…), libvirtd active. Persists forward now. Latent first-boot race only bit blade (cortex/others auto-seeded fine); declarative fleet-wide seed-if-missing deferred as overkill unless it recurs.

**RESUME STATE (2026-06-27, pre-compaction):** nix-config worktree `.worktrees/replicated-home-syncthing` CLEAN at HEAD `89f11f10` (branch `feat/replicated-home-syncthing`, all signed: …→76a08f79→`9d24f48b`[temp den override]→`9e018129`[Task 3 hub]→`89f11f10`[Task 4 claude split]). Running on cortex (sini@cortex). **SSH blade AUTHORIZED: `ssh blade.ts.json64.dev`**. Deploys are Jason's via `colmena apply --on <host>` (YubiKey for commits; agenix `generate` THEN `rekey` for new secrets via `nix develop -c agenix`; no native CC TaskCreate — commit hook; `git commit --no-verify`). **DEN PR #625** worktree separate: `~/Documents/repos/den/.worktrees/fix-broadcast-home-pool`, branch `fix/broadcast-home-pool-to-host` on sini fork (HEAD `4911b7f2`: `e010dfd7` fix + `4911b7f2` 7 tests), draft, 1051/1051+1 green, STAYS DRAFT per Jason; den test cmd `nix develop -c just ci <suite>[.<test>]`, fmt `just fmt`.

**TASK 4 SHIPPED 2026-06-27 (`89f11f10`, eval-verified).** Split `claude.nix`→`claude/{package,config}.nix` (+ existing replicate.nix). KEY DEN FINDING: an aspect's class FUNCTION (homeManager) does NOT merge across files — last-wins-clobbers (content-util.nix __contentValues filters subAttrVals to attrsets, FUNCTIONS EXCLUDED); QUIRKS (persistHome/cacheHome/replicateHome, list/attrset) DO merge across files. So config lives in a SEPARATE `claude-config` aspect that `claude` **includes**. config.nix = read-only `settings.json` via `(pkgs.formats.json {}).generate` (semantic MATCH to cortex canonical; CC CANNOT mutate at runtime — change in nix) + git.ignores + four-bucket map replacing blanket `persistHome [".claude"]`: replicated(memory,projects)/generated(settings.json)/persistHome(11 dirs incl plugins,file-history,tasks,sessions,jobs +files credentials,history.jsonl)/cacheHome(8 dirs: cache,paste-cache,session-env,shell-snapshots,statsig,debug,daemon,ide +4 json/log). Blanket→per-entry reuses same /persist/.../.claude/* paths (NO data loss; omitted entry unmounted not deleted). cortex+blade green.

**HUB LIVE + VERIFIED 2026-06-27 (after 2 deploy-time bugs fixed).** uplink hub working: connected to cortex+blade (2/3; patch off), received 855MB, folders `/var/lib/syncthing/sini/.claude/{memory,projects}` populated, need=0. **Bug 1 (FIXED, commit `aaae7c26`):** hub dataDir `/var/lib/syncthing` persisted as a plain string → impermanence makes it root-owned → syncthing (runs as `syncthing` user) `mkdir /var/lib/syncthing/<user>: permission denied`, no folders, 0 sync. Fix = persist it as an ATTRSET entry `{ directory; user="syncthing"; group="syncthing"; mode="0700"; }` (kept as the `persist` QUIRK per Jason — the collector concatMaps attrset dir entries straight to impermanence). **GOTCHA:** a `colmena apply` applied the impermanence ownership but did NOT restart syncthing (no unit change) → had to `sudo systemctl restart syncthing` on uplink to pick up the now-writable dataDir. **Bug 2 (member mount-race, restart-recovered):** member syncthing (user service) scans `~/.claude/{memory,projects}` before the `/persist` binds settle (esp. during a blanket→per-entry remount or root-wipe boot) → empty folder → STICKY "folder marker missing (potential data loss)" error → folder never syncs. Fix-for-now = `systemctl --user restart syncthing` (cortex+blade both recovered: "Ready to synchronize"); DURABLE follow-up = order syncthing After the persist mounts. Diagnostic gotcha: `grep '"connected":true'` MISSES the space in syncthing's JSON (`"connected": true`) — use `\s*` or a real parser; uplink has NO python3. **Task 5 watch-item:** projects global=855MB vs 280M on disk ⇒ likely `.stversions` from cortex/blade projects divergence (the reconciliation Task 5 flags) — confirm cortex canonical not clobbered by blade's older backup via sendreceive.

**SHIPPED TO MAIN 2026-06-27 — PR #159 MERGED (rebase, linear), origin/main @3b970ba2.** Tasks 1-5 ALL DONE. Task 5 reconciliation: cortex↔blade↔uplink CONVERGED (26 projects, 103 memory, identical sets); blade's set-aside `~/claude-bak/projects` had 2 blade-unique sessions but Jason said DON'T need blade's data → discard claude-bak, no merge. Versioning fix committed: `projects`→`trashcan{cleanoutDays=30}`, `memory`→`staggered{maxAge=30d}` (keyed `baseNameOf p == "memory"` in member.nix + hub.nix) — staggered hoards growth-snapshots of append-only logs (~60MB/day churn ⇒ GB-scale .stversions on receivers/hub). REMAINING: (1) **redeploy cortex/blade/uplink** to apply trashcan versioning (deployed hosts still run staggered; existing .stversions [blade 236M, hub ~588M] won't auto-clean on type-switch — `rm -rf .../.stversions` after redeploy if you want immediate reclaim); (2) **revert den override** (`flake.nix` den.url → github:denful/den, relock) when den PR #625 leaves draft + merges; (3) optional worktree/remote-branch cleanup. Boot-ordering for syncthing is ALREADY correct (mount in local-fs.target < basic.target < syncthing; member user-manager starts after system mounts) — the marker-missing errors were the Task-4 apply-time remount under a running daemon (one-time), NOT a boot race; no impermanence change needed.

**PATCH/DARWIN PARITY — replication FIXED + LIVE 2026-06-28 (3 commits on main: `85e8fe46` DNS, `9917a3ab` SSH, `e39771a7` agenix).** patch (the ONLY darwin host, aarch64-darwin) ran syncthing but replicated nothing. Root causes were a STACK of `nixos`-only aspect branches never exercised because patch is the sole darwin host — each surfaced only after fixing the one above it:
- **DNS** (`tailscale/darwin.nix`): macOS open-source `tailscaled` (launchd, no GUI network-extension) does NOT program the system resolver; nix-darwin's tailscale module hardcodes `/etc/resolver/ts.net` ONLY (default base domain), but our headscale uses custom `base_domain = ts.json64.dev` → tailnet FQDNs (`cortex.ts.json64.dev` etc.) unresolvable → syncthing reached no peer. FIX = `environment.etc."resolver/ts.${environment.domain}".text = "nameserver 100.100.100.100"` + `tailscale set --accept-dns=true` (idempotent, for already-up nodes) + `dscacheutil -flushcache; killall -HUP mDNSResponder` on activation (macOS caches resolver cfg; new /etc/resolver entry ignored until flush/reboot). Verified: `dig @100.100.100.100 cortex.ts.json64.dev`→tailnet IP, `dscacheutil` system-resolves. Validated by community pattern (github MrCee/tailscale-headless-macos) + tailscale#13461 (OSS tailscaled ≥1.74.0 stopped programming macOS DNS → /etc/resolver MANDATORY). Caveat: a DNS Configuration Profile (MDM) outranks /etc/resolver silently — patch has none. Did NOT add /etc/hosts darwin branch (hosts.nix nixos-only) — LAN IPs unreachable for a roaming ts-only host; MagicDNS FQDNs cover every peer.
- **SSH** (`core/users/users.nix` `userEnrich`): set `openssh.authorizedKeys.keys` only in `nixos` branch → darwin installed ZERO keys → publickey-only sshd rejected all (`Permission denied (publickey)`; sshd WAS running via Apple Remote Login). FIX = add `darwin` branch mirroring the key set; nix-darwin renders it to `/etc/ssh/nix_authorized_keys.d/<user>` + wires `AuthorizedKeysCommand`. (sshd itself: openssh aspect's darwin branch enables it; `services.openssh` IS a real nix-darwin option.)
- **agenix identity** (`batteries/agenix.nix`) — THE blocker for syncthing itself. HM agenix (user `sini`) reported "no readable identities found" decrypting the home syncthing-identity. Identity chain: system agenix (root, host key) decrypts `user-identity-<user>` → HM agenix uses THAT as its decrypt identity. TWO darwin bugs: (1) `user-identity-sini` set `group = user.name`, but **macOS has no per-user group** (`dscl . -read /Groups/sini`→eDSRecordNotFound; primary group is `staff` gid 20) → agenix's `chown sini:sini` failed as a unit → file left `root:admin` mode 600 → unreadable by sini. FIX = `group = if host.class == "darwin" then "staff" else user.name`. (2) system `identityPaths` got `/persist/etc/ssh/ssh_host_ed25519_key` because the impermanence aspect's DARWIN branch is a no-op dummy (so `host.hasAspect impermanence`=true) yet there's no real `/persist` on macOS → host key actually at `/etc/ssh/ssh_host_ed25519_key`. FIX = `persistPrefix = optionalString (hasImpermanence && host.class == "nixos") "/persist"`. patch's real host pubkey MATCHES the committed one (no rekey needed). cortex(nixos) eval unchanged — no regression.
- **Two launchd ordering races (NOT load-bearing, self-heal on vanilla install):** (a) syncthing daemon `copy-keys` needs the agenix-decrypted identity, but with agenix fixed the system identity is present from activation so no crash-loop (the earlier crash-loop made launchd THROTTLE-DROP the agent entirely → "Could not find service"; a manual `launchctl bootstrap` recovered it once, superseded by the deploy). (b) `syncthing-init` (`merge-syncthing-config`, the agent that POSTs declarative devices/folders via REST) is `RunAtLoad`-once/NO-KeepAlive; its internal `curl --retry 1000 --retry-delay 1` (~16min) is the ONLY cover for the daemon-socket race. It had exhausted its retries during the days the daemon couldn't start, and the daemon-fixing deploy left the init plist UNCHANGED → not re-bootstrapped → didn't re-run → syncthing stayed on its DEFAULT config (`~/Sync` folder, self-only device) → peers `Connection rejected error="unknown device"`. Recovered with one manual `launchctl kickstart -k …syncthing-init` → applied devices(patch/cortex/uplink/blade)+folders(.claude/{memory,projects}) → all peers `connected:true`, both folders converged (memory 103/103, projects 4210, needFiles 0 idle). On a VANILLA install init is bootstrapped FRESH at activation → runs → retries until daemon up → applies config (no pre-exhausted history). **VERIFICATION AUDIT (Jason asked):** nothing manual is load-bearing — no syncthing/agenix agent left `disable`d in launchd (checked `launchctl print-disabled`; that's the only persistent non-nix launchd state); all producing agents RunAtLoad/KeepAlive; config.xml + .claude data are runtime/synced state regenerated on a fresh box. The two manual launchctl cmds = recovery from THIS host's accumulated pre-fix state, both = what activation does automatically. Residual honest caveat: init RunAtLoad-once is the one fragility (upstream HM-darwin module, don't fork); definitive cold-boot proof = reboot patch (offered, not yet done). **Deploy flow on patch = `nh darwin switch .` in `~/Documents/repos/nix-config` (Jason pulls+switches there); SSH `sini@patch.ts.json64.dev` (works post-fix). macOS python3 triggers Xcode-license prompt — use grep/sed/jq on patch. uplink env is `prod` (patch is `dev`) → patch reaches the hub via `uplink.ts.json64.dev` MagicDNS (cross-env).**

**DARWIN `ssh <shortname>` + hostsfile rename (commit `ad20cce4`, 2026-06-28).** `ssh cortex`/`ssh uplink` failed on patch: the home-manager `apps/dev/security/ssh.nix` aliases already mapped each peer short name → its LAN form `<host>.<env>.<domain>` (resolves on NixOS via /etc/hosts, NOT on roaming darwin). FIX = class-aware alias `hostname = if host.class == "darwin" then entry.tsName else "<host>.<env>.<domain>"` where `tsName = "<host>.ts.<environment.domain>"` is a NEW field on the `host-addrs` quirk (emit in hostsfile.nix); darwin reaches peers only by tailnet MagicDNS name (resolvable via the tailscale /etc/resolver fix). Also added a `darwin` branch to the hostsfile aspect = `programs.ssh.knownHosts` (nix-darwin: writes /etc/ssh/ssh_known_hosts + the aspect's nixos branch's `services.openssh.knownHosts` analog) keyed by tsName so connections verify not TOFU-prompt — NO /etc/hosts on darwin (LAN IPs unreachable roaming). `host.class` IS available in den homeManager context. Renamed `core.network.hosts`→`core.network.hostsfile` (file hosts.nix→hostsfile.nix, attr, roles.default include line). nixos byte-identical (tsName == old hardcoded `ts.json64.dev` literal it replaced). **TREEFMT GOTCHA:** `nix fmt` WRAPPED the `hostname = if…then…else…;` ternary to 2 lines but the pre-commit/CI treefmt wants it on ONE line (1502B) → commit hook `--fail-on-change` failed; fix = `nix develop -c treefmt <files>` (devshell treefmt = authoritative for the hook) then re-add+commit. (Files had no `or [ ]` so the statix footgun in [[feedback_format_cmd]] didn't bite.) Needs `nh darwin switch` on patch to apply.

**DARWIN gpg-agent/YubiKey ssh robustness (commit `bce4a41d`, 2026-06-28).** After the alias fix, `ssh cortex` worked from an interactive terminal but NOT a clean/no-terminal state. Root cause: on macOS gpg-agent runs at login (home-manager `services.gpg-agent` enableSshSupport → launchd agent `org.nix-community.home.gpg-agent`, RunAtLoad, `gpg-agent --supervised`, YubiKey on `~/.gnupg/S.gpg-agent.ssh` — a real socket) BUT `SSH_AUTH_SOCK` is exported ONLY by interactive shell init (not in any rc/zshenv file found; a clean env = "Could not open a connection to your authentication agent"). FIX = `IdentityAgent ~/.gnupg/S.gpg-agent.ssh` so ssh finds the agent regardless of SSH_AUTH_SOCK; set via a **`homeDarwin`** class branch (`homeDarwin.programs.ssh.settings."*".identityAgent = …`) NOT `optionalAttrs (host.class=="darwin")` (Jason's steer — den class `homeDarwin`/`homeLinux` per modules/den/classes/home-platform.nix + gpg.nix; the homeDarwin content deep-merges into the SAME `settings."*"` as the homeManager branch since they're different class keys both delivered to the darwin HM config). Darwin-ONLY: NixOS exports SSH_AUTH_SOCK globally via systemd, and IdentityAgent there would shadow a FORWARDED agent. patch's YubiKey = `cardno:15_967_769` (backup card, SAME auth subkey/pubkey as the authorized `cardno:31_057_490`, so accepted). **Agent forwarding within the fleet already configured** (no change): client `forwardAgent yes` per fleet Host block + `no` in `Host *`; sshd `AllowAgentForwarding yes` (openssh aspect, both classes). Known nuance NOT fixed: a host you ssh INTO re-exports SSH_AUTH_SOCK to its own gpg-agent (shadows forwarded) — moot since every workstation has its own authorized YubiKey; only matters hopping THROUGH a no-YubiKey host. Needs `nh darwin switch` to apply.

**IMMEDIATE NEXT (this is where we are):** SHIPPED. Redeploy for versioning + revert override on #625 merge. Pending Jason's DEPLOY (uplink was still building): `colmena apply --on uplink` (new hub) + redeploy cortex/blade/patch (mesh now includes the hub) → members push ~/.claude/{memory,projects} to /var/lib/syncthing/sini/.claude/*. Then **Task 5** (migration finalize: cortex seeds, reconcile blade's backed-up projects, confirm convergence). When den #625 merges → revert `9d24f48b` (den url → github:denful/den, relock). Task 2 cross-host convergence already PROVEN earlier (cortex↔blade clean, cortex canonical untouched).

**TASK 3 PAUSED 2026-06-26 — pivoted to a DEN FIX (Jason's call).** Hub design DECIDED: **system daemon, NO user accounts/daemons on uplink** (option a, not b); persist `/var/lib/syncthing` (folders at `/var/lib/syncthing/<user>/<dir>`), NO extra ZFS dataset. The hub builds folders from a broadcast of each user's `replicateHome` dir set. **BLOCKER = a den shortfall:** a user-scope `pipe.broadcast ({ host, ... }: isHub)` of the home-pool `replicateHome` quirk must reach the hub host but returns `[]` (broadcast of a home-pool quirk to a host doesn't deliver; sentinel-proven it delivers nothing from the spawned home node; expose home→host + collect DOES work but `expose` drops the source-side transform so the user tag is lost). Jason: this SHOULD work → **fix in den (test + fix branch), then bump nix-config pin + use the clean broadcast.** Findings that stand regardless: `pipe.transform` is per-element; `pipe.as` retargets locally (composes with collect/to, NOT broadcast/expose); broadcast delivers under the `pipe.from` source name (ignores `as`); config-thunk reading `config` forces host eval → self/flake-parts cycle (so NO config in quirk context — read the pipe). **nix-config WIP (uncommitted, members eval GREEN, hub gets []):** `member.nix` folder `label`; `host.{secretPath,facts}`→`rootPath`; new `quirks/syncthing-hub-shares.nix` + `aspects/.../syncthing/{hub.nix(stub debug),hub-shares.nix}` (git-added); `policies/pipes.nix` expose+collect WIP; `uplink.nix` isHub+hub-include; `settings.nix` isHub. Resume: revert/clean the WIP to the chosen broadcast form once den is fixed. Den repo `~/Documents/repos/den` (origin denful/den; pin `3932adfe` has PR #623 pipe-broadcast); local HEAD was `11866c16`.

**DEN REPRO DONE 2026-06-26:** failing test `pipe-broadcast.test-broadcast-home-pool-to-host` on branch `fix/broadcast-home-pool-to-host` (worktree `~/Documents/repos/den/.worktrees/fix-broadcast-home-pool`, base 3932adfe). Root cause: `host-aspects` battery = a `den.lib.policy.spawn`, so a projected app's quirk (replicateHome) lands in a SPAWNED home node parented to the HOST (`spawn-node.nix`: `${spawnRoot}=from`, from=host); a `den.schema.user.includes` broadcast runs in the TOP-LEVEL pass and reads `scopedClassImports.<userScope>.replicateHome = []` (emit is in the spawn sibling node). `pipe.expose` propagates out of the spawn (re-derive over merged parent state) but `pipe.broadcast` has no equivalent out-path. KEY den files: `nix/lib/aspects/fx/{spawn-node.nix(merge+augmented re-derive ~L93-116),assemble-pipes.nix(collectAllBroadcast L794,collectAllExposed L701,findMatchingAll L356)}`. The MINIMAL repro (quirk on `alice.includes=[claude]`, no spawn) PASSES — the spawn is the trigger. Test run: `cd <wt> && nix develop -c just ci pipe-broadcast.test-broadcast-home-pool-to-host`. Run command for a single test: `just ci <suite>.<test>`. AWAITING Jason's fix-locus call (broadcast-out-of-spawn like expose vs collectAllBroadcast scanning spawned nodes vs spawn parent=user).

**DEN FIX SHIPPED-as-DRAFT 2026-06-26 — denful/den PR #625** (STAYS DRAFT per Jason; branch `fix/broadcast-home-pool-to-host` on sini fork: `e010dfd7` fix + `e6ee53cb` 6 guard tests; base denful/den main @3932adfe). 6 guard tests (suite `pipe-projection`) authored by the review agent — and **test 5 (multi-class spawn) caught a real double-count bug in my first cut**: a quirk key is class-agnostic so every spawned class's walk yields the identical `quirkEmits`; the original `concatMap`-across-classes surfaced once per class → fixed with `lib.findFirst` (byte-identical for single-class). Full suite **1051/1051**. Jason's chosen semantic: a host-aspects-projected aspect should behave "as if the requesting scope included it directly" — the quirk materializes in BOTH the requesting (user) scope AND the spawned node. **Approach A** (fresh-eyes opus agent reviewed + I implemented): the projected quirk emit is STATIC, so surface it PRE-assembly. `spawn-node.nix` exposes the spawn root's non-host-bound quirk keys as `quirkEmits` on the spawn return (host-bound stripped via `strippableNames`, inherit host value). `resolve.nix` hoists the spawn materialization into one shared `homeNodeSpawns` (over RAW parentState; also de-dups a previously-doubled spawnNode sub-walk across the two mkDrained calls) + layers its `quirkEmits` over the raw imports into a SEPARATE `importsForPipes` map fed to BOTH `assemblePipes` calls; `parentState` KEEPS the raw map (cycle/double-count invariant); `mkDrained` consumes the hoist. Root cause: pipe assembly runs once PRE-drain over `scopedClassImportsRaw`; spawn materializes post-drain → feeding back is cyclic. **Full suite 1045/1045 green.** 6 guard tests (collect-once / double-inclusion-twice / expose / local / multi-class / host-bound-boundary) being authored by the review agent (bg, agentId a43730c70df6a2038) → push to PR #625. NOT yet merged/pinned. nix-config WIP (the expose/collect/hub-shares experiments) to be REVERTED to the clean user-scope `pipe.broadcast` once den merges.

**TASK 3 SHIPPED 2026-06-27 (eval-verified, deploy pending Jason).** nix-config branch `feat/replicated-home-syncthing`: `9d24f48b` (temp den override → sini/den #625 branch) + `9e018129` (the hub). Clean user-scope `pipe.broadcast` works with den #625: hub gets `replicateHome` tagged `{user, directories}`. **hub.nix** = ONE system `services.syncthing` (isHub-gated, NO user accounts/daemons): devices from member `syncthing-peers`, folders per (user,dir) at `/var/lib/syncthing/<user>/<dir>` (persisted via `persist.directories`, no extra dataset), host identity `syncthing-uplink.{age,crt,id}` (minted+rekeyed via the `syncthing-identity` generator), firewall 22000 on tailnet iface. **pipes.nix**: `broadcast-syncthing-hub-shares` (replicateHome→hub, transform tags user) + `broadcast-syncthing-peers-to-hub` (member device→hub) + `broadcast-hub-peer` (hub device→all members). Eval-verified: hub folders sini/.claude/{memory,projects} devices=[blade,cortex,patch]; cortex sini devices now include `uplink`; all host classes (darwin/server/k8s) green. Dropped the home-scope expose/collect + hub-shares.nix + syncthing-hub-shares quirk. host.{secretPath,facts}→rootPath kept (cycle-safe for the host-scope hub emit).

**NEXT:** DEPLOY uplink (new hub) + REDEPLOY cortex/blade/patch (their mesh now includes the hub) — Jason's. Then convergence: members push to the hub at /var/lib/syncthing/sini/.claude/*. When den PR #625 merges → revert `9d24f48b` (den back to denful). Then Task 4 (system daemon, broadcast replicateHome→hub, folders at /var/lib/syncthing/<user>/<dir>, hub identity mint syncthing-uplink, firewall). Task 4: split `claude.nix`→`claude/{package,config}.nix` + generate read-only `settings.json` from CORTEX's current `~/.claude/settings.json` (canonical — capture before replacing) + four-bucket persist/cache map (replicate.nix already landed). Task 5: migration finalize (cortex seeds, blade pulled; reconcile blade's backed-up projects). Plan doc: `~/Documents/papers/nix-config-architecture/plans/2026-06-26-replicated-home-syncthing.md` (Tasks 1-2 sections now stale vs the shipped idiomatic modules; Task 3-5 sections still useful but Task 3 hub model changed to option b). Spec (rev-c) at `…/specs/2026-06-25-replicated-home-syncthing-design.md`.

**CURL 8.21 BARE-DOT SYNCTHING FIX — 2026-07-17.** curl ≥8.21 (nixpkgs-master) tightened URL parsing and rejects the bare-dot authority `http://.` that HM's syncthing merge-script (`curlAddressArgs`, `modules/services/syncthing.nix`) emits for a unix-socket `guiAddress` → `curl: (3) URL rejected: Bad hostname` (exit 3). Every REST call fails; with `--retry 1000 --retry-delay 1 --retry-all-errors` syncthing-init retry-loops past its 5-min start timeout → `home-manager-<user>.service` activation TIMES OUT (both cortex+blade, any nixpkgs-master member; stable-26.05's older curl unaffected). Root cause = UPSTREAM HM, NOT the socket choice from [245e9533]. FIX = patch HM `http://.`→`http://localhost` (`--unix-socket` routes to the socket regardless of authority; localhost accepted by all curl versions + passes syncthing host-check — verified `http://localhost/rest/…` over the socket → CSRF-layer, only bare-dot fails at the parser) + regression test `tests/modules/services/syncthing/linux/gui-address-unix-socket-init.nix`. Fork `sini/home-manager` branch `fix/syncthing-unix-socket-host` @`7dfcdf1` (nix fmt clean, `nix run .#tests -- syncthing` 5/5, HM-style `{component}: {desc}` commit); upstream PR **nix-community/home-manager#9671**. nix-config pins `home-manager-master`+`home-manager-unstable`→fork rev (commit `08fb72c7`); **DROP pin when #9671 merges**. **DEPLOY-TIME DEADLOCK GOTCHA:** deploying the fix while the OLD bare-dot syncthing-init is still wedged in its retry loop → `switch-to-configuration` blocks on the stuck `syncthing-init.service start` job (which blocks `default.target`) — the broken unit blocks its own replacement. Unblock = as the target user `systemctl --user stop syncthing-init` → activation proceeds, daemon-reload swaps in the localhost unit, it succeeds. cortex redeployed+verified 2026-07-17 (syncthing-init active/success on the `v0pb0y…` localhost script, HM active/success, 0 failed units); **blade+uplink still pending — they will hit the same deadlock until on the fix.** UNRELATED same-session fix: nvidia-persistenced unit error on cortex = `hardware.gpu.nvidia-vfio` `includes [nvidia]` dragging the full driver stack (`nvidiaPersistenced=true`) onto a vfio host that blacklists the nvidia modules → include SEVERED (committed `0c1cb81a`; also dropped the now-unused `{ den, ... }:` header); NOT a microvm-cuda aspect bleed (guest `cortex-cuda` uses `hardware.gpu.nvidia` in its own entity scope).

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [Replicated-home Syncthing](project_replicated_home_syncthing.md) — nix-config replicateHome quirk + Syncthing mesh (Claude ~/.claude across hosts); **SHIPPED to main (PR #159, origin/main @3b970ba2) Tasks 1-5 DONE + hub LIVE+verified**; system hub on uplink /var/lib/syncthing/<user>/<dir>, dataDir syncthing-owned via persist attrset, projects=trashcan/memory=staggered versioning; den shortfall fixed via temp flake override → den PR #625 (DRAFT, sini fork); REMAINING = redeploy cortex/blade/uplink to apply trashcan versioning + revert den override when #625 merges; SSH blade.ts.json64.dev; see [[feedback_nix_config_module_conventions]]

──────── archive-project_resolver_decoupling.md ────────
---
name: project_resolver_decoupling
description: den core-resolver host/user decoupling SHIPPED 2026-06-12 —
metadata: 
  node_type: memory
  type: project
  originSessionId: 8bd2eca2-aa5c-4a3f-a14a-ba21303e8d15
---

UPDATE 2026-06-14 (@ 21b06028, CI 987/987): **transitive descendant fan-out was BROKEN — FIXED.** Spec §3 claims transitive ({host,user}@environment → for-each-host-for-each-user) but only DIRECT children worked: `fanOut` enumerated children off `scopeCtx.${scopeKind}` (the scope's OWN record), so a descendant-of-descendant (toy under pet) was looked up as `host.toys` (absent) → inert; and the fanned intermediate (pet) lived only in `__scopeHandlers`, invisible to the next level. Fix (bind.nix): thread fanned intermediates via a `boundEntities` accumulator param on the "bind" effect; enumerate each descendant off its PARENT-kind record (`availRecords = scopeCtx // boundEntities`); fan SHALLOWEST reachable descendant first (not alphabetical head) so an intermediate binds before its child. Direct/cartesian unchanged. Turned out trivial (~15 lines, 1 file) despite my initial "non-trivial" caution — the recursion already existed, just piggybacked a param. Found by a formal-rule coverage AUDIT (rule A delivery-edge + rule B binding; both pos+neg). New tests in `features/relationship-fanout.nix`: cartesian-independent (±), transitive-descendant-chain. NO current den consumer (default topology host→user is direct).

SHIPPED 2026-06-12 on den `feat/entity-gen-schema-port` @ `b1619a47` (REBASED onto vic/den main `fe63b4bf` #607, force-pushed to sini), CI 947/947. Final production review verdict "with fixes" — applied: defaults.nix emission-scope comment corrected, `test-shared-include-suppresses-fanout` isolation test (broken-state = doubled list, verified), HM-leak migration note in docs/guides/home-manager.mdx. Declined: `lib.warn` on misplaced args (contradicts spec's deliberate "inert, silently" — open design question for user). Spec: `~/Documents/papers/den-architecture/specs/2026-06-12-core-resolver-host-user-decoupling-design.md` (+ public gist 4547d2e7db0c0bcf2ce8871e21aee7cc); plan+census+§6 tables: `plans/2026-06-12-core-resolver-host-user-decoupling.md`.

**The formal rule (v1 canon, also the HOAG parity oracle):** parametric aspect at scope S (kind K_S) destructuring entity-kind K_a — in-ctx → bind once at S; schema-DAG descendant → synchronous fan-out over S's children, emit AT S class-locally; neither (incl. root scope) → misplaced → inert silently. Cross-entity delivery only via provides/policy/host-aspects.

**Mechanism:** `arg-class.nix` (isDescendantOf/childrenOf convention `"${kind}s"`/isEntityKind) + fan-out in `bind.nix` (per-key probe; per-child re-send of "bind" → cartesian free; `{fanOut}`/`{inert}` shapes handled in compile-parametric). Dedup collapse was real: per-child `__ctxId` + forced `meta.contextDependent` (compile-static strips `__parametricResolvedArgs`, so ctxId alone dies at emit). **Structural shared-include suppression**: skip fan-out iff `scopedIncludesChain[currentScope][1]`'s identity.key ∈ `schema.<argKind>.includes` (den.default double-cover; replaced a name-equality heuristic per review).

**Removed:** cross-scope carrier chain = push-scope deferred-include inheritance + walkDeferred refire (census proved these are ONE chain, the only entity-arg carrier; scope-widen + baseDrain are non-entity, KEPT). perCtx/perHost/perUser/perHome shim deleted, suites migrated. defer.nix throws on entity-kind requiredArgs (regression alarm). Spawn materializer kind-generic (ownKind/parentKind from scope tree). Projected-hasAspect owner = parent-chain walk (no host literal) — updates [[project_projected_hasaspect]].

**Semantic flips (all §6-classified):** host-scope `{user,…}` homeManager no longer leaks to users (= #609); root-scope entity args inert (was: deliver via chain); at-user `{host,…}` now BINDS (perCtx skipped); shim-wrapped statics emit once (per-user static fan-out coverage lives in relationship-fanout test #2).

Parity: cortex nix-diff flake-source-only, identityPaths /persist, cortex-cuda guest, darwin patch. nix-config flake still pins pre-refactor `e8876f3e` — needs a den input bump to deploy.

──────── archive-project_review_once_functional.md ────────
---
name: project_review_once_functional
description: den-hoag posture — deep design review waits for a functional system; refactor is cheap. The pre-implementation gate still applies to NEW designs.
metadata: 
  node_type: memory
  type: project
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T01:46:32.997Z
---

Owner ruling 2026-07-27: *"we'll deeply review design once we have a functional system, refactor is
cheapish."*

**What this releases.** The finding that 98.3% of open beads rest on unreviewed design no longer blocks the
roadmap. W4 (`den-hoag-4kh.4`) is unblocked. The deep architectural re-review — the 22 unvalidated beads,
the four "See notes." beads with no recoverable evidence, the wrong `9xo.16 <- 9xo.20` edge, the five edges
asserted in prose but absent from the graph — happens **against a running system**, not against a bead
graph. The measurement itself still stands; it is outranked, not retracted.

**What it does NOT release** (owner confirmed separately, same day):

- **The adversarial gate still applies to NEW design candidates.** spec → gate (C1–C7) → VALIDATED →
  implement. `den-hoag-4kh.6` is not dissolved.
- **Measured defects enter the graph directly**, as always — that route was never gated.
- **"Spec before development, always"** is unretracted, including for one-line gen-lib changes.
- `arch-validated` remains a *positive* label; absence still means not-yet-validated.

**Why the gate survives a posture that defers review:** *"refactor is cheapish"* is a claim about **cost of
change**, not about **detection**. A defect that ships silently is never refactored, because nothing tells
you it is there. The F1 arc is the evidence — the gate caught a diamond-shaped duplication that was
exponential in output, invisible to every test in the suite (the only fixture is a chain; chains and sibling
fan-ins are both trees), and that survived two adversarial rounds. The round-2 fix was *verified* to restore
parity and was still wrong.

**The one-line form: defer the review of what is already built; do not defer the review of what is about to
be.**

Related: [[feedback_no_deferral]] (ship right first time) is about work quality and is unaffected;
[[feedback_best_framework_first]]; [[project_kernel_purity_arc]]; [[project_corpus_eval_parity_bar]].

──────── archive-project_settings_stratification.md ────────
---
name: settings-stratification-parametric-injection
description: "Spike 5 implemented across gen-algebra + gen-aspects demo — 2 PRs open 2026-05-31; pending gen-algebra#1 merge then demo lock bump"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4a7bf6b4-e365-4a89-b330-b692b568ffa5
---

Spike 5 (from `2026-05-27-den-pragmatic-fleet-features.md`) — **settings stratification + parametric-aspect injection** — implemented in the gen-aspects demo, 2026-05-31. Brainstorm → spec → plan → subagent-driven TDD (7 tasks, each spec+quality reviewed), via multi-agent workflows.

**Design (locked):**
- Cascade order `default < env < host < policy` — policy appended LAST, wins by position (foldLayers is positional last-wins). Per-declaration strength (mkForce-style) is OUT — deliberately deferred, see precedence research below.
- **gen-algebra `record.foldLayersTraced`** (pure/rec.nix, builtins-only sibling of foldLayers) returns `{ value; provenance }`, value byte-identical; provenance = per-field `[{layer;value}]` chain. 13 tests.
- **Canonical aspect shape**: settings = STATIC interface (top-level, introspectable by flatten); only class content (`nixos`) is parametric and CONSUMES resolved settings. firewall→parametric, hardening→plain. A whole-aspect guard fn `{host,...}:{settings;nixos;}` buries settings behind `functionTo` (types.nix) → flatten can't reach them; canonical shape fixes this.
- **`act.configure { aspect; settings }`** (renamed from fx.settings) emitted by per-host gen-derive dispatch; collapsed to one aspect-namespaced patch, injected as final cascade layer. Rules in non-module `_policy-rules.nix` (underscore-pathed to dodge `import-tree ./modules`).
- **Injection construct** `injectAspectSettings { host, aspectLeaf, classContent }` (injection.nix) — generalizes bindings.nix's manual gen-bind wiring; injects `settings = { <leaf> = composedSettings.<host>.<leaf>; }` + host into class content via `genBind.wrap`. NO isFunction guard (deferredModule coerces fn to `{imports=[fn]}`, so isFunction=false; wrapCore self-dispatches). Demo-local prototype; **graduation to `gen-aspects.lib.injectAspectSettings`/`assembleHost` deferred** (2-aspect gate met via firewall+nginx; graduation gated on full entity record + identity keying for real evalModules assembly).

**Status (2026-05-31): SHIPPED — both PRs MERGED.**
- **gen-algebra PR #1 MERGED** (main rev 49f6721) — foldLayersTraced + tests.
- **gen-aspects PR #1 MERGED** (main rev 146389e) — the demo (Tasks 2-7) + demo flake.lock bumped to gen-algebra@49f6721. Both feat branches deleted local+remote.
- **Demo now evals FULLY STANDALONE** from gen-aspects main — zero `--override-input` flags. Verified: loggingLevelProdWeb1="error", fwInjectionMatchesCascade=true, nginxInjectionResolved=true, workersProdWeb1Winner="host", recursive per-subkey provenance.
- (firewallIsPlain is non-discriminating for the gen-algebra lock; use loggingLevelProdWeb1="error" to confirm a future bump took.)
- Still out-of-scope: pre-existing `nix flake check` failure in demo queries.nix:96 (`observability` attr) — separate cleanup.
- Pre-existing `nix flake check` failure in demo `queries.nix:96` (`observability` attr) predates this work — separate cleanup, out of scope.

**Proofs (green with override):** fwInjectionMatchesCascade, nginxInjectionResolved (full loops), loggingLevelProdWeb1="error" (policy overrides env "warn"), workersProdWeb1Winner="host" (negative control), dbBackupSubkeyProvenance (recursive per-subkey).

**Docs:** spec `specs/2026-05-31-settings-stratification-injection-design.md` (gist sini/88631967399e8568cb7b0519c76ecb7a); plan `plans/2026-05-31-settings-stratification-injection.md` (+`.tasks.json`); precedence research `specs/2026-05-31-config-policy-precedence-research.md`.

**Precedence research finding:** cross-domain survey (CSS/Nix/scope-graphs/config-mgmt/cloud-AOP/access-control) — mature systems make precedence PER-DECLARATION (`!important`, `mkForce`), not a fixed global slot. But our foldLayers is positional last-wins with no strength dimension, so "policy is the final decider" (ordering B) is the honest realization for THIS pipeline; per-declaration strength (C) reserved as a future foldLayers extension. See [[project_gen_type_unification]] for the broader settings-mechanism convergence (cascade-schema vs HOAG options-module) still open.

──────── archive-project_unified_aspect_key_type.md ────────
---
name: unified-aspect-key-type-three-branch-dispatch
description: classifyKeys dispatches class (den.classes) / pipe (den.quirks) / unregistered; delivered with pipes/quirks
metadata: 
  node_type: memory
  type: project
  originSessionId: b8c4b977-4c52-4544-a5b8-3b4a734913e1
---

DELIVERED. `key-classification.nix` 3-branch dispatch:
- key ∈ `den.classes` → class emission (`emit-class`)
- key ∈ `den.quirks` → pipe key (collected via emit-class infra, consumed by `assemblePipes`)
- neither → unregistered class key (backcompat default to class)

Returns `{ classKeys, pipeKeys, nestedKeys, unregisteredClassKeys }`.

**Key insight:** separation of declared options (`.classes`/`.quirks`) vs freeform keys is load-bearing — `aspect-schema.nix` reads declared options without triggering freeform merge.

Pipe keys flow same emit-class → scopedClassImports path as class keys; `assemblePipes` consumes post-pipeline. See [[project_den_architecture]].

──────── archive-project_zen_vic.md ────────
---
name: project_zen_vic
description: "zen — Vic's stream-based Nix module system; the de-facto hola module-plane kernel"
metadata: 
  node_type: memory
  type: project
  originSessionId: a62fb38e-47a4-4bca-9c29-820186bb7c53
---

zen (github:denful/zen, Vic's; sponsor vic; src ~/Documents/repos/zen) = minimal ~100-line stream-based Nix module system. Substrate: **bend** (lenses: N→1 merge + MLTT types), **ned** (Cycle.js fixpoint), **nix-effects/fx** (scoped handlers/rotation), **dnzl** (actors) — denful + kleisli-io, NO nixpkgs.lib at runtime. Does the 3 module-system jobs only.

Kernel (nix/kernel.nix): `run` desugars modules→{lens,defs}, builds per-key contribution streams, ned.run wires fixpoint; single Kahn topo-sort detects cyclic option refs statically (located blame, NOT infinite-recursion throw) AND gives topoOrder for deepSeq pre-force (stack safety). No throw; accumulating one-pass blame. Submodules = scope boundaries (zen.cycle + ctx-d, NOT recursive evalModules) → kills cost-center D WITHIN one config. (NB: README's "ned.scope-d / fx.rotate" for submodules is aspirational — zen.sub uses plain zen.cycle + ctx-d; scope-d/rotate aren't on the submodule fast path. Verified vs source 2026-06-24.) Per-option edge-local deps via functionArgs (`config.b = {a}: a+40` reads only a, no fan-in). Full mk* priority/order/mkIf/mkMerge vocab via bend lenses (byPrio = lowest-prio-class-wins filter), byte-identical, WITHOUT lib/types. Advanced (beyond nixpkgs): actor provide/request, negotiated merge (fx.conditions signal/restart), stateful reconcile, MLTT types.

Benchmarks vs lib.evalModules (nrPrimOpCalls, byte-identical gate): realistic NixOS-shaped configs **3.4–10.3×** (zero fixed base vs nixpkgs ~61k-primop bootstrap; both linear, asymptote ~3×); flat-batch compat path **84×** at N=10k. `zen.nixmod.evalModules` = compat shim, byte-identical str/listOf str ONLY, NOT full nixpkgs coverage (that gap = hola's parity work).

Vic's hard-won ceilings: pure-Nix bounds ~10× (>10× needs native dnet/Rust compile); located-cycle Kahn has O(N²) wall-clock heap tail (no O(1)-update map in pure Nix; zen 4.7s vs nixpkgs 2.1s ≥2400 modules). zen benches are synthetic modules that DON'T import the package set — so 3–10× is the machinery slice; real toplevel still pays the [[project_hola]] H1 // storm. **CRITICAL (verified vs zen source 2026-06-24): the 3–10× is SINGLE-config (zen vs lib.evalModules on the SAME modules), intra-eval — NOT cross-scope/cross-host result sharing, of which zen has NONE (fleet-demo calls lib.nixosSystem per host, fresh eval each). Do NOT cite zen as proving cross-host sharing.** hola's cross-scope eval-sharing lever ([[project_hola]] Phase 4.5 overlay-dedupe track) is genuinely unbuilt — needs gen-rebuild content-addressed memoized reuse + the engine owning evalModules, NOT portable from zen (whose win also requires NOT using lib.evalModules at all).

RELEVANCE: zen ≈ [[project_hola]]'s module plane, but built effects-first. DECIDED 2026-06-23: zen is hola's REFERENCE/COMPARATOR ONLY — hola is greenfield pure-gen/GRAPH-based (NOT effects/streams), deliberately a different CS paradigm. Don't discount zen, don't imitate it; some systems will rhyme but hola derives them from graph principles. Compare perf/complexity/feature-parity at the end. bend fills the H7 merge gap for the EFFECTS paradigm; hola needs its own graph/lattice merge-algebra (gen). Convergence-of-ideas not shared-code.


## Comments (0)

(none)
