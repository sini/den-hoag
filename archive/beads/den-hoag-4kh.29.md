# den-hoag-4kh.29 — [archive] gen-* memory files verbatim pre-2026-07-28 reduction — memory dir has NO git history, this is the only copy

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.29` |
| status at evacuation | closed |
| priority | P3 |
| type | chore |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:27:47Z by Jason Bowman |
| last updated | 2026-08-01T19:47:03Z |
| closed | 2026-08-01T19:47:03Z |
| close reason | Archive complete — gen-* memory files preserved verbatim in-body pre-reduction (memory dir has no git history; this body is the only copy, and a closed bead's body persists). Completed act of archiving; no pending work. |
| description bytes | 272284 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

ARCHIVE — gen-* memory files, VERBATIM, as they stood before the 2026-07-28 reduction (1216 -> 902 lines,
190,279 -> 62,480 bytes). Kept because ~/.claude/memory IS NOT VERSION CONTROLLED — there is no git
history to recover these from, and the scratchpad they were staged in is session-scoped.
★ SUPERSEDED AS TRUTH. These contain measured errors, several that would MISDIRECT a session:
  - project_gen_link said den-hoag integration 'UNSTARTED' twice; MEMORY.md said 're-point done'. BOTH
    wrong — gen-link is not a den-hoag input at all, yet the load-bearing item (retiring the
    sha256 "den-aspect:${key}" address) LANDED via gen-aspects aspectId.
  - project_gen_theory_audit carried #9/#10 as OPEN; gen-specs/den-hoag/ISSUES.md:35,39 says RESOLVED
    2026-06-09, ~10 days after the memory was written.
  - reference_gen_lib_capability_map called gen-product latticeGraph 'genuinely absent as of
    2026-07-20'; it was added by a2914e7 ON 2026-07-20. Wrong when written, not merely expired.
  - systematic DEAD PATHS: bare ~/Documents/repos/<lib> instead of ~/Documents/repos/sini/<lib>.
    project_gen_schema_bump_nixconfig named the bare path CANONICAL and called sini/ 'a stale dup' —
    inverted. project_gen_spec_audit claimed the nix-config repo is absent on disk; it exists.
  - project_gen_select documented sel.entityKind as live API; it is a THROWING tombstone.
Read for historical content only. Current state: the rewritten files, and the bead graph.
════════════════════════════════════════════════════════════════════════

──────── archive-project_agent_teams.md ────────
---
name: project-agent-teams
description: Claude Code agent teams enabled in user settings (SendMessage/shared tasks); version-update todo
metadata: 
  node_type: memory
  type: project
  originSessionId: 30a8a252-1695-4ae2-84bb-6997b5af77c8
---

Agent teams ENABLED 2026-06-25 in `~/.claude/settings.json`: `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS="1"` + `teammateMode="in-process"` (pinned because terminal is kitty, no tmux/iTerm2 — split panes unsupported). Requires session restart to take effect (env read at startup).

Enables lead/teammate orchestration: SendMessage (teammates message each other + lead by name), shared task list (TaskCreate/TaskUpdate, file-locked claiming, dependencies), plan-approval gate, per-teammate direct messaging. Distinct from subagents (those report back only; teammates are full independent sessions that talk to each other). Source doc: ~/Downloads/Orchestrate teams of Claude Code sessions (Claude Code Docs).

**Why:** user wants proper SendMessage + agent-team workflows for parallel research/review/debugging.

**How to apply:** spawn teammates in natural language ("spawn 3 teammates to..."); name them in the spawn prompt for predictable SendMessage targets; in-process panel ↑/↓ select, Enter to message, x to stop, Ctrl+T task list.

TODO: user on Claude Code **2.1.170**; docs describe **2.1.178+** (zero-setup spawn, auto team cleanup, TeamCreate/TeamDelete removed). Update to ≥2.1.178 for the clean flow. Related: [[feedback_no_parallel_agents]] (one agent per repo — file-conflict discipline applies to teammates too), [[feedback_subagent_model]].

──────── archive-project_gen_aspects_reserved_keys.md ────────
---
name: gen-aspects reserved keys via aspectModules
description: gen-aspects doesn't need reservedKeys — use cnf.aspectModules to declare settings/tags as explicit options on aspects
type: project
---

When migrating from den's current pipeline to gen-aspects, the `den.reservedKeys` mechanism is unnecessary.

**den (current):** Uses `structuralKeysSet` filtering + `den.reservedKeys` option to prevent keys like `settings` from being dispatched as class/pipe/nested-aspect keys. String-based exclusion list.

**gen-aspects:** Uses NixOS module system for aspect types. Classes are declared options, freeform catches the rest as nested aspects. To reserve a key like `settings`, declare it as an explicit option via `cnf.aspectModules`:

```nix
aspectModules = [({ lib, ... }: {
  options.settings = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
  };
})];
```

Declared options take precedence over freeform — `settings` won't be treated as a nested aspect. No string-based exclusion needed.

**How to apply:** When porting to gen-aspects, replace `den.reservedKeys = [ "settings" ]` with an `aspectModules` entry declaring the `settings` option. The dynamic settings discovery in host schema can then read `aspect.settings` as a typed option rather than an untyped attrset.

──────── archive-project_gen_bind.md ────────
---
name: gen-bind design
description: Module binding library — inject external args into NixOS module functions. Full spec at 2026-05-25-gen-bind-design.md. Extracted from den's class-module.nix (~310 lines).
type: project
---

gen-bind: standalone library for injecting external bindings into NixOS/home-manager module functions.

**Spec:** `~/Documents/papers/den-architecture/specs/2026-05-25-gen-bind-design.md`

**Core API:** `gen-bind.wrap { module, bindings, collisionPolicy, identity, thunkResolver }` → `{ module, wrapped, validator }`

**What it does:** Partial application of external args (host, user, isNixos, firewall, etc.) into NixOS module functions. Handles three module shapes (function, imports attrset, plain attrset), collision detection (den-wins/class-wins/error), config thunk deferral, and enrichment arg stripping.

**Extracted from:** den's `class-module.nix` (~250 lines) + `wrap-classes.nix` (~190 lines). ~310 lines become gen-bind; ~230 lines of den-specific routing/identity logic stay in den.

**Zero deps beyond lib.** No dependency on any gen-* library.

**Academic:** Reynolds 1972 (partial application), Findler 2002 (blame/collision), Leijen 2005 (scoped labels for collision resolution).

──────── archive-project_gen_derive.md ────────
---
name: gen-derive-design
description: "Stratified rule dispatch engine — SHIPPED at github:sini/gen-derive, 55 tests, 11 suites. RETE terminology, DAG phases, fixpoint convergence, conflict resolution, NACs, rule composition, gen-select adapter."
metadata: 
  node_type: memory
  type: project
  originSessionId: 52e94a05-8f7d-4c7f-b890-b353a3a1dc84
---

> **RENAMED + RE-CHARTERED 2026-07-01 → gen-dispatch** (github:sini/gen-dispatch, repo `ad633a1`; redirect live; local dir still `~/Documents/repos/gen-derive`). Now the pure dispatch **STEP** only: `fixpoint` DELETED (loop → gen-resolve/`gen-scope.circular`; use new `dispatchStep`/`dispatchInit` to pair a step with a loop), `topoSort`/`entry*` DELETED (ordering → `gen-graph.phaseOrder`). `dispatch` takes a pre-ordered `phaseOrder` list (no internal toposort). 54 tests/10 suites. Details in [[project_gen_resolve]] + [[project_gen_package]]. History below is pre-rename.

gen-derive: stratified rule dispatch with fixpoint convergence. **SHIPPED**, 55 tests across 11 suites.

**Repo:** `~/Documents/repos/gen-derive/` (github:sini/gen-derive)
**Spec:** `~/Documents/papers/den-architecture/specs/2026-05-25-gen-derive-design.md`
**Plan:** `~/Documents/papers/den-architecture/plans/2026-05-25-gen-derive.md`

**Core API:**
- `dispatch` — one-shot: fires matching rules, groups actions by phase in topo order
- `fixpoint` — convergent loop: dispatch → extract feedback → widen context → repeat until stable
- `mkRule` — condition + produce + optional nac/identity/priority/overrides
- `fromFunction` — canTake pattern: `builtins.functionArgs` as condition, detects mkIntensional
- `fromFunctionMatch` — default match impl for fromFunction rules
- `mkActions` — generates tagged action constructors + classify from phase declaration

**Conflict resolution:** override suppression → priority sort → specificity (adapter) → additive ties

**Rule composition:** `restrict` (narrow condition), `override` (replace rule), `chain` (sequential feed)

**Phase DAG:** `entryAnywhere`, `entryAfter`, `entryBefore`, `entryBetween`, `topoSort`

**Two-tier architecture:**
- Core: gen pure tier only. Conditions/actions are opaque.
- Adapter: gen-select bridge — `adapters.select.mkMatch` and `selectorSpecificity`

**Consumers:** den v2 policies, nest-traits CSS rules, sql-schema WHERE-clause rules

**Academic:** Forgy 1982 (RETE), Ehrig 2006 (graph rewriting/NACs), Arntzenius 2016 (stratification), Palmer 2024 (intensional identity), Radul 2009 (propagator convergence), Hedin 2003 (JastAdd), Batory 2005 (AHEAD composition), Berry & Boudol 1990 (CHAM)

──────── archive-project_gen_entity_port.md ────────
---
name: Entity port to gen-schema
description: Two-phase port of den entities to gen-schema. Spec approved 2026-05-20, ready for implementation plan. Defer aspects to scope-engine swap.
type: project
---

Port den.hosts/den.homes to gen-schema registries. Spec at docs/superpowers/specs/2026-05-20-entity-gen-schema-port-design.md.

**Phase 1:** gen-schema registries internally, apply reconstructs two-level external shape. 6 consumers (policies/flake, outputs/systems, aspects/definition, nh.nix, diag/fleet, home cross-lookup) see unchanged two-level `den.hosts.<system>.<name>`. All 753 tests pass.

**Phase 2 (follow-up):** Flatten consumer API, remove apply reconstruction, reserve system keys for legacy compat.

**Key decisions:**
- `mkSchemaOption` with sidecars for includes/excludes, computed isEntity
- `strict = false` on entity registries (preserve freeform)
- User→host via _module.args (structural nesting), not schema.ref
- Home→host via schema.ref (cross-registry reference)
- resolvedCtx/collisionPolicy carried forward as extraModules
- Defer gen-aspects integration until scope-engine replaces the effects pipeline

**Status:** Spec approved, next step is writing-plans skill for implementation plan.

──────── archive-project_gen_flake_rescope.md ────────
---
name: gen-flake-re-scope-design-reference
description: "gen-flake's deferred re-scope (general output-crossing lib); the aggregate-terminal contract WS-COLLECTOR pins, and why the collector crossing stays behind den's render-evaluator seam"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0b896552-113a-47f5-9156-6696201d043e
---

**gen-flake re-scope = a DEFERRED, OWN-ARC design** (owner-ratified split, spec §12 4c-iii; NOT part of
4c-iii). Captured here so the inherited contract + the seam decision don't get lost before that arc runs.

**The north-star (owner):** den subsumes `flake.nix outputs` WHOLESALE — gen-flake becomes the general
OUTPUT-CROSSING lib expressing ANY output (modules/systems/flake-parts/aggregates), weaving any
combination, with flake-parts BESIDE not beneath (honoring the pure-Nix-core fork). Today gen-flake is
mis-scoped: `terminals.mkSystemTerminal` IS already generic (per-config `{ modules; specialArgs } ->
system`; `nixosSystem`/`darwinSystem` = sugar — board #48 darwinSystem already solved at the terminal
level), BUT `flakeModule`/`realize` HARDCODE `nixosConfigurations` (`flakeModule.nix:210` = `flake.nixosConfigurations
= realized.nixos or {}`; other classes hand-wired). The re-scope = per-FAMILY terminals + a plain-attrset
root assembly + all-realized-classes surfacing. den consumes ONLY `mkSystemTerminal` today (not
compose/realize/flakeModule), so the coupling is small. gen-flake local path ~/Documents/repos/gen-flake
(den-hoag lock rev `9812caf`, "generic mkSystemTerminal; nixosSystem as sugar").

**THE INHERITED CONTRACT (from WS-COLLECTOR F2, owner-ratified 2026-07-17 — the note the owner asked to
preserve):** the collector/aggregate render is a NEW terminal SHAPE distinct from per-config. So the
re-scope's terminal taxonomy needs TWO shapes: (1) PER-CONFIG `{ modules; specialArgs } -> one system`
(exists = mkSystemTerminal); (2) AGGREGATE `{ <memberName> = <product>; } -> HiveInfo` (a member MAP ->
one aggregate; e.g. colmena `makeHive`, deploy-rs nodes, Hydra jobsets, nixosTests matrices). WS-COLLECTOR
PINS shape (2)'s contract in den-hoag now.

**WHY the collector crossing stays DEN-HOAG-LOCAL (F2), and how the gen-flake migration stays CLEAN — the
key design fact:** F2 puts two things in den: (a) the gather-then-render MOUNT FLOW (collect the member
map, call the render ONCE — a new `familyOutputs` arm) = genuinely den's mount orchestration, stays in den
REGARDLESS of gen-flake; (b) the aggregate-evaluator CONTRACT (a `den.renders` row's `evaluator` field,
member-map -> HiveInfo) = data BEHIND A SEAM, the SAME seam gen-flake already plugs into (den's CLASS
render evaluator already delegates its nixpkgs crossing to gen-flake: `crossVia` -> `flake.terminals.mkSystemTerminal`,
terminal.nix:40-61; the render-row `evaluator` is a pluggable field). So: NOW the collector evaluator is a
den-local aggregate crossing (stub in tests, real `colmena.lib.makeHive` at corpus/ship time); LATER the
gen-flake re-scope supplies an AGGREGATE TERMINAL that den's collector render delegates to — a ONE-LINE
evaluator swap, exactly as the class render delegates to mkSystemTerminal. NOT a rework, because the
contract is already the right shape. **BINDING CONSTRAINT (baked into the WS-COLLECTOR plan):** the
aggregate crossing MUST stay behind the render-evaluator seam (a swappable `evaluator` field), NEVER
hardcoded into the `familyOutputs` mount flow — that pluggability is what makes the gen-flake reclaim
trivial. The rejected F2 option ("new gen-flake aggregate terminal now") would have front-loaded gen-flake
work into WS-COLLECTOR before the re-scope arc exists; den-hoag-local defers that, cost = the future
evaluator swap (trivial via the seam).

**NET for the gen-flake re-scope arc:** it INHERITS shape (2)'s contract (member-map -> HiveInfo) as a
design input — build the aggregate terminal to that contract, den swaps its collector evaluator to it.
WS-COLLECTOR is effectively DE-RISKING the re-scope (proves the aggregate contract + mount flow first).

**PAIRED QUEUED ARC — the L2 EXTRACTION (owner-ratified 2026-07-17, spec §12 post-step-6).** The whole
materialization vocabulary (products/conversions/renders/receivers/nest/outputs/root+families/collectors)
landed den-hoag-LOCAL consuming the gen libs; a POST-VOCABULARY arc (once the surface stabilises —
post-step-6 / at least post-4c-iii, NOT mid-flight — each sub-arc still grows it) promotes the GENERAL
kernel into a gen-tier L2 lib (`gen-materialize`/`gen-vocab`); den-specific bindings (class terminals,
compat shim, corpus-parity oracle, reach/projection) stay in den-hoag as the thin assembly. Precedent =
gen-bind extracted from class-module.nix. The gen-flake re-scope + the L2 extraction are the TWO
"promote-when-proven" arcs; the GENERICITY MANDATE shapes an extractable target as we write. Companion:
a gen-API-leverage AUDIT (no duplication / no graph-origin drift — e.g. axis cartesian vs gen-product;
placement twins vs gen-edge setAttrByPath; membership must be graph-query over member-edges, not an
ad-hoc selector loop) keeps the eventual extraction a lift not a rewrite.
Related: [[project_den_hoag_features]] (WS-COLLECTOR + the 4c-iii decomposition), [[project_gen_package]]
(gen ecosystem / mkGenLibs).

──────── archive-project_gen_graph_labeled_query.md ────────
---
name: project_gen_graph_labeled_query
description: "gen-graph labeled query calculus SHIPPED — regex-over-labels traversal, 5 query modes, den-hoag §12 step 1"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9ca7f5ed-7ae4-42ab-8273-f2cde8d631a2
---

gen-graph labeled query calculus SHIPPED 2026-07-16 (github:sini/gen-graph main @ d110703; 214 tests / 12 suites). Implements den-hoag unified link/merge vocabulary spec §3/§12 step 1 (plan: ~/Documents/papers/den-architecture/plans/2026-07-16-gen-graph-labeled-query-calculus-plan.md).

Two new lib modules, strictly additive over the label-blind `edges : id → [id]` surface:
- `lib/regex.nix` (nested export `regex.*`): Brzozowski derivative kernel over edge-kind labels — constructors lit/seq/alt/star/opt/plus/any/eps/empty, ACI-normal `stateKey` (Owens-Reppy-Turon finiteness), `deriv`/`nullable`, `parse` string sugar (whitespace=seq, `|`=alt loosest, postfix `*?+`, `_`=any, `[A-Za-z0-9_-]+` labels, named throws). NO builtins.match (backtracking stack-overflow class).
- `lib/query.nix` (flat exports): `labeledFrom` adapter (per-label plain accessor → `labeledEdges : id → [{label;target}]`, the gen-scope followEdge shape); `query` with 5 modes — `all` (genericClosure over node×derivative-state product, scales, terminates on cycles), `paths` (acyclic witness DFS), `visible`/`layers` (per-query label order + `order.endOfPath` rank, default -1 = prefix-wins; van Antwerpen), `fixpoint`→`queryFold` (dispatch-alias); `queryFold` = canonical-order ACI fold (Datafun restriction, lawfulness = consumer contract).

gen-graph does NOT import gen-scope (stays Class B, {prelude} only) — gen-scope adaptation is a RECIPE (labeledFrom over followEdge). Deliberate `all`-vs-`paths` divergence: `all` answers node revisits, witness modes are acyclic-only. Docs: gen-graph README + gen-specs/gen-graph/REFERENCE.md; gen-scope REFERENCE limitations 10-11 repointed here (papers @ ac5aec4). See [[project_hoag_architecture]] [[project_den_hoag_features]]. Harness gotcha: [[reference_gen_ci_asserttests_expectederror]].

Out of scope (later §12 steps): den-hoag `den.edges.<kind>` lowering + `den.query`/`ctx.rel.*` wrappers; discipline-laws gating of folds; data-order (`≤d` over answer DATA).

──────── archive-project_gen_link.md ────────
---
name: project_gen_link
description: gen-link = cross-flake aspect FEDERATION layer (Class-B conductor like gen-resolve; owns origin coordinate + disjoint-union-relabel + resolution manifest, delegates all computation). REPLACES den-hoag namespaces (via the origin coordinate) + establishes the canonical gen-routing targets den-hoag's audit-roadmap points at. den-hoag integration = re-point 4 duplications, no re-architecture.
metadata:
  node_type: memory
  type: project
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

**★ STATUS 2026-07-24 — BUILT & SHIPPING (subagent-driven execution).** Spec + plan (both 3-round adversarial-reviewed) at `papers/den-architecture/gen-specs/gen-link/2026-07-24-gen-link-design.md` + `papers/den-architecture/plans/2026-07-24-gen-link-lib.md` (+ `.tasks.json`). **Plan 1 (kernel enablement) SHIPPED+pushed:** gen-schema `checkRefinements` made public @`c6331f3`; gen-aspects @`5f7e349` = uniform `aspectId` (`origin: aspect: hashIdentity "aspect" ["origin" "key"] valueOf`) + `includes` `keyRef` by-key variant + opt-in `closedKeys`/`freeformKeys` typo-gate. **Plan 2 (the gen-link lib) COMPLETE @`2a4abda` — SHIPPED to `github:sini/gen-link`.** All 14 tasks (scaffold[mirrors gen-graph]/ref/identity/normalize/rewrite/union/facets/contract/wire/link-conductor/oracle/demo/docs/hub-`mkGenLibs`) + a fix-forward (decision-7: an unwired required facet now → a loud NAMED `link` error) landed+pushed. CI-GREEN: **53 tests / 13 suites + treefmt canonical + `purity` nixpkgs-lib-free**; registered in the hub (`gen/lib/mkGenLibs.nix` `link` key, `gen` main pushed); README + papers `gen-specs/gen-link/REFERENCE.md`. Final holistic review **✅ SHIP** (it found + I closed the decision-7 unwired-hole gap; per-task two-stage reviews also caught real bugs: the refined-facet constructor footgun `genSchema.types.refined`→`genSchema.refined`, and facets-need-`.option`). Non-blocking known-limits: `record.assertSatisfies` redundant with the local `record.has` guard (intentional — keeps assertSatisfies load-bearing); refined-facet has no end-to-end `link` test (unit-tested at `checkRefined` only). **den-hoag integration (re-point the 4 duplications below) UNSTARTED.**

**As-built CORRECTIONS to the design prose below (implementation + review superseded these):** (a) holes = declared **facet-requires**, NOT `__functionArgs` (those are CONTEXT args, pipeline-filled — plan-review F1); (b) identity uses `hashIdentity` **directly**, NOT `mkIdentityModule` reflection (reflection would fold `description` → break the partition); (c) manifest = **pure value** returned by `link` (consumer serializes a lock if wanted), NOT gen-link writing `link.lock`; (d) **all 7 Open Qs resolved** — two-edge-kind (`includes` concrete by-value+by-key, `holes`=facet-require), applicative instantiation, explicit-wire base (auto-fill deferred); (e) a **refined**-facet contract needs a `__schema`-tagged `refinedType` (top-level `genSchema.refined`=`mkRefinedType`), NOT a raw refinements list (a plan bug caught + fixed in impl — `checkRefinements` reads `type.__schema.refinements`); (f) **capability** check = gen-algebra `record.has` (`requires ⊆ provides`) + gen-link's OWN named edge-error (`assertSatisfies` secondary/redundant); (g) tooling gotcha: mkCi's treefmt roots at `.git/config`, so `nix fmt` inside a WORKTREE is vacuous — format-verify on the MAIN checkout. NO further kernel changes needed. **den-hoag integration (re-point the 4 duplications below) UNSTARTED.**

**gen-link** (design `papers/den-architecture/gen-specs/gen-link/2026-07-24-gen-link-design.md`, DRAFT 2026-07-24, owner-authored) = the cross-flake **aspect FEDERATION** layer: a downstream flake reuses aspects published by an EXTERNAL flake, with rescope + per-node alias, cross-origin edges pinned like `flake.lock`. Theory-grounded (scope graphs Néron 2015, algebraic graphs Mokhov 2017, Backpack/ML-functors, binding-time analysis, content-address/lock). **Class-B conductor** (the gen-resolve pattern): owns ONLY sequencing + 3 new coordinates — **origin coordinate · disjoint-union+relabel · resolution manifest** — and DELEGATES every computation (hash→gen-schema `hashIdentity`, resolve→gen-resolve `reference`, graph→gen-scope overlay/gmap, materialize→gen-edge). Never hashes/resolves/stores. Ships as a PURE PRIMITIVE; den-hoag INTEGRATION is the orchestrator's job once built ([[feedback_route_through_gen_native]]).

**Elegant core:** origin is JUST ANOTHER identity key — `id_hash = hashIdentity "aspect" (["origin"]++pathKeys++holeKeys) valueOf`; `origin=[]` is PARTITION-preserving by construction (id_hash(a)==id_hash(b) ⟺ today's `.key`(a)==(b)). Holes read off the type (an open aspect's holes ARE its `__functionArgs` on `__isWrappedFn` — no invented vocab). Wires the DEAD `providerPrefix` (threaded but never read) as the origin label. class|channel|facet kept sharp (facet = sole typed port via mkMixin/refined; class = payload-only; channel = verbatim) + fences the `pipe.channel` HOMONYM (keySemantics channel ≠ Kahn pipe.channel — unrelated).

**★ den-hoag INTEGRATION CONTRACT (the spec's "Explicitly NOT reused from den-hoag" table = my re-point list; matches the DL-HS-24 audit roadmap):**
| den-hoag duplication | gen-link canonical target |
|---|---|
| `forwardExpand`/neededBy (resolved-aspects.nix:111) | gen-resolve `reference` (equation.nix:137-158) — CORRECTS audit G2 (I'd proposed gen-graph foldReachable; reference already exists) |
| raw `sha256 "den-aspect:${key}"` (concern-disciplines.nix:160) | gen-schema `hashIdentity` (origin-key preimage) — audit sha256 seed |
| `reserved-registry` union | federation-with-origin |
| namespace scaffold | the **origin coordinate** — VINDICATES the transitional/first-to-cut namespace call ([[project_class_bucket_holdover]] arc) |
gen-link does NOT absorb den-hoag code; it establishes the primitives den-hoag re-points to (no re-architecture, just re-pointing).

**★ Confirmations for den-hoag decisions:** (1) the closed-key **typo-gate** (gen-aspects addition, Open-Q2) IS audit **G1** — gen-aspects strict-totality → `mkRawTotality`/`restoreUnregistered` (DL-HS-23) retires INTO a gen-aspects gate, exactly as deferred. (2) namespace→origin confirms transitional. (3) forwardExpand→gen-resolve reference refines audit G2.

**★ Load-bearing RISK:** the ONLY non-trivial change = **identity re-routing** — `mkIdentityModule` on the aspect submodule (aspects carry a `hashIdentity` id_hash) + `providerPrefix`-as-origin + retire den-hoag's `den-aspect:` hash — under a **PARTITION-regression** bar (NOT literal string; a sha256 can't byte-equal a path string — flagged honestly). Small code, touches every aspect's identity → the partition fixture (same-path/distinct-path) is the real gate. `.key` stays the human NAME; id_hash is the content-address (mirrors gen-schema's name/id_hash split).

**Two early decisions to pin (Open Qs):** manifest as pure value vs committed `link.lock` artifact (lean: `link.lock` for diffable federation edges in den-hoag PRs); hole-ref syntax string vs structured `{origin;path;}` (structured internally, string sugar). Others: API surface (fold rescope into per-source), applicative-vs-generative instantiation default (applicative). Links [[reference_gen_lib_capability_map]] [[project_gen_package]] [[feedback_route_through_gen_native]] [[project_den_v2_terminal_classes]].

──────── archive-project_gen_package.md ────────
---
name: gen-package-ecosystem
description: "gen ecosystem: 14 mkGenLibs keys (incl gen-class + gen-flake) + standalone gen-rebuild/gen-vars, ALL SHIPPED+PUBLIC, core tagged v1.0.0 2026-07-06. Pure-gen module system + value-injection boundary. Next = den-hoag."
metadata: 
  node_type: memory
  type: project
  originSessionId: 8300dd10-a57e-4b54-a9d4-2e37f7aa3890
---

## Update (2026-07-16) — keySemantics surface shipped + gen-schema substSubModules re-release

**Shape B (den-hoag value-injection debt) drove three gen pushes, all on main:**
- **gen-schema `ec64a35`** — (1) `keySemantics` OPAQUE per-key category surface on `mkSchemaEntryType`/`mkSchemaOption` (composer declares `{<key>={category;option?}}`; gen-schema records it, assigns NO meaning — class/channel/facet vocab lives in gen-aspects). (2) gen-merge pin bumped `fa5d5cc2`→`2701d8b` = the **substSubModules fix**: gen-schema had pinned a PRE-`completeType` gen-merge, so consumers mounting gen-schema types into nixpkgs evalModules (nix-config `mkInstanceRegistry` as a NixOS option) hit `substSubModules missing` (nixpkgs modules.nix:1477). 405 tests.
- **gen-aspects `b19ca92`** (feat/wrap-gated-fn ff-merged to main) — `aspectSubmodule` GENERIC dispatch over `cnf.keySemantics` (class→deferredModule / channel→raw / facet→module|option); DELETED the `cnf.classes`→classOptions arm; KEPT `imports = facetModules ++ (cnf.aspectModules or [])` (the `__defsModule` gen-schema seam is load-bearing — dropping it breaks mkAspectModule tests). A-IDENT `.key` untouched. `wrapGatedFn` rides along. 130 tests.
- **gen `e9d9208`** — hub locks bumped.

**GOTCHA (ecosystem-wide):** gen-lib `nix-unit --flake .#tests` stack-overflows at default 8MB from `lib.hasInfix`/`builtins.match ".*x.*"` over readFile'd source — see [[reference_nixunit_regex_stackoverflow]] (fix = splitString; retires the `ulimit -s unlimited` runner workaround). **STILL OPEN in nix-config:** bumping its gen-schema pin past the re-hosting boundary surfaces `den.schema._kindNames defined 2×` (den/gen-schema lock-coherence, effort S) — separate task.

## Update (2026-07-10b) — gen-merge nixpkgs optionType PROTOCOL COMPLETE + gen-schema identity helpers

**gen-merge @5d5e0de (pushed, 175 tests)**: `mkOptionType` stamps the full 14-field nixpkgs optionType protocol PURELY (no nixpkgs import) — pure types now MOUNT inside real nixpkgs `lib.evalModules` (capability the re-hosting silently dropped; nix-config's mkInstanceRegistry-in-flake-parts proved consumers need it). Leaves get real checks from gen-types `verify` (their `.check` is curried — unusable as v->bool); structurals defer-to-merge; substSubModules/functor/typeMerge per nixpkgs contract. Byte-identity ANALYTICAL: gen-merge's own core reads `.merge`/`.verify`, never `.check` — additions invisible. gen-schema INHERITS FREE (403 green, id_hash canary intact). **gen-schema @74841cc+f6749cb (pushed)**: `identityHashFor kind instance` (instance-based — PERMANENT for den-hoag's compat discovery; shim kind-values are option-less by the field-less law) + `identityHashForKind kindValue instance` (option-level exact, honors identity=false — for consumers with REAL kind-values); both route through shared `hashIdentity` (structural no-drift).

## Update (2026-07-10) — ecosystem debt sweep COMPLETE (impl-eco, 5 items, 4 repos, all pushed)

(1) den-hoag PUBLIC CI @04cc751+5e7f70c (GH Actions: format + ci#tests + parity#tests — parity CI-viable, corpus input empirically never forced; root nixfmt-tree formatter, nixpkgs = formatter-only root input). (2) gen hub mkGenLibs check @5fda916 (19-key roster + per-key deepSeq, teeth-verified). (3) **gen-pipe `over` op** @9b850f1 (whole-list derive = v1 `for`; E6 poisons STRUCTURE — cardinality value-dependent; 133 tests) + den-hoag honorWholeList @7c3a76f. (4) **gen-flake `mkSystemTerminal { evaluator }`** @9812caf (NO-BLEED LAW owner 2026-07-10: zero system/nixpkgs names in the generic constructor, fake-evaluator contract test; nixosSystem = thin v1.0.0-compat sugar = the ONE nixpkgs touch; extension recipe: new system class = consumer-side evaluator, gen-flake never changes) + den-hoag crossNixos/crossDarwin consume it @ded0c9f. (5) **gen-demand sel.entity/sel.kind** @121dac3 (ctxFor projects __identity {id_hash; kind=subject.type or null; entry}; kind-blind → loud throw; 93 tests) + papers gen-select REFERENCE aligned @3bd0da7 (entityKind REMOVED). DURABLE GOTCHA: den-hoag ci/+parity/ subflake locks FLATTEN transitive root pins — root pin bump ⇒ `nix flake lock ./ci --update-input den-hoag` + `./parity --update-input den-v2` same commit (README dev section documents it, @7df3a04). ORPHANED trust-release doc work recovered+committed to papers @d99030f ("other session" = ended; constraint retired).

## Update (2026-07-06b) — FIVE den-hoag L2 libs PUBLISHED (not hub-wired)

**github:sini/gen-{edge,product,settings,demand,pipe}** all public, main pushed, built via subagent workflow (opus impl / sonnet review) from the den-hoag component specs, 707 tests total independently re-verified: edge 96 (edge algebra (S,T,P,M), materialization fold, parity trace E), product 125 (graph products over accessor-graphs, cells/slices, restrict, containmentChain, linearizeByDimOrder count-major), settings 79 (Spike-5 layered folds, identity refs, per-entry-lazy provenance, injection), demand 92 (typed cascade, downward-only kind DAG, emission⊥consumption by signature), pipe 124 (scoped channels, dataflow DAG join/tee, class tags + static config-dependence taint, B5). gen-select extensions MERGED @f3c047e (sel.entity/sel.kind, __identity adapters, product adapter; 191 tests; sel.entityKind superseded). gen-pipe consumes upstream gen-select @15e6981 (interim shim dropped). **HUB-WIRED 2026-07-07** (gen @01cc791+2230b3b pushed): mkGenLibs = **19 keys** (verified eval: +edge/product/settings/demand/pipe); hub docs synced (L2 hub-wired status + gen-dispatch rule-eval-only/group rename post loop⊥step completion @bf541dd — dispatchStep/fired RETIRED, gen-resolve README + gen-aspects demo + gen-scope sql-schema oracle all migrated byte-identical). flakeModules/genLibs.nix curated injector deliberately NOT extended (flag open). Consumer: den-hoag assembly ([[den-hoag-feature-targets]]).

## Update (2026-07-06) — gen-class SHIPPED + v1.0.0; ecosystem = 14 mkGenLibs keys + 2 standalone

**gen-class** (`github:sini/gen-class`, v1.0.0 @218c54f, 90 nix-unit tests): the class-share
mechanism as a shared framework lib — tier-1 `partition`/`contract`/`apply`/`gate` (archetype/axis/
core data contract, projection core-appliers, O(K) byte-parity gate) + tier-2 `applyCoreFixed`
(fixed-input core injection via gen-merge's `coreShortCircuit` kernel, ~5.8× spine reduction, hub
`classShare` perf gate). Hub-wired as **`mkGenLibs.class`** (the hub re-imports its lib with the
tier-2 gen-merge kernel injected — gen-class's own flake `.lib` leaves merge=null). den-hoag
consumes it as the class-share seam (Tier 3 = den-hoag wiring, deferred). Naming fence: public
surface FLAT, `inject` banned (r2 owns it). Ecosystem count: **14 mkGenLibs keys** (+class, +flake
since the 13-count below) + standalone gen-rebuild/gen-vars. Ecosystem tables in gen/gen-merge/
gen-flake READMEs carry the gen-class row as of 2026-07-06. A1 fleet gates still in hola —
migration to gen-class ci = trust-release register §6a item (pre-den-hoag). Docs: gen-class README
+ `gen-specs/gen-class/` (REFERENCE + 2026-07-05 design/plan + r2 seam amendment note).

## Update (2026-07-02) — PURE-GEN MODULE SYSTEM + cross-compat SHIPPED + PUBLIC (13 hub libs)

Three NEW module-system libs shipped + published, ecosystem now **13 hub libs** (was 11):
**gen-types** (`github:sini/gen-types`, clean-room MIT structural checker — leaf/poly checkers, `verify: v→null|err`); **gen-merge** (`github:sini/gen-merge` @`c960e5c`, the **byte-mode module MERGE engine** `evalModuleTree` — byte-identical to nixpkgs `lib.evalModules` over the mkIf/mkDefault/mkForce/mkMerge priority subset, no ORDER pass; +nested option-declaration paths #16 +path-leaf import #20 +a permanent config-thunk-deferral regression); **gen-flake** (`github:sini/gen-flake` @`5dd3a41`, NEW repo — **the single nixpkgs boundary**: `.lib`=compose/injectArgs/mkSystems + `.flakeModules.default`; compose gen trees PURELY→inject resolved VALUES into a consumer's nixpkgs eval via `_module.args`→build NixOS systems at a terminal via gen-bind.wrapAll→nixosSystem = **value-injection, not type-driving**). Layering: gen-prelude→gen-types→gen-merge→{gen-schema,gen-aspects}→gen-flake terminal.

**gen-schema + gen-aspects RE-HOSTED onto gen-merge+gen-types = REPLACEMENT (OQ1 owner call):** their `lib/` is now nixpkgs-lib-free, **byte-identical to the old nixpkgs-driven versions incl `id_hash` SHA** (independently re-verified; now a PERMANENT gen-ci byte-parity regression on a pinned `github:nix-community/nixpkgs.lib`). Published gen-schema `7c204e5`, gen-aspects `e68bf4a`, gen hub `2ea13d5` (`mkGenLibs` resolves 13 libs incl merge/types/flake). All 3 type-embedding demos migrated to value-injection (gen-schema/gen-aspects/gen-vars). **nixpkgs.lib = ecosystem POLICY** (lib-only need→pinned nixpkgs.lib; full nixpkgs only for pkgs/nixosSystem). Downstream consumers embedding the gen TYPE break until migrated to value-injection (accepted D6 trade). Two den-hoag results proven: value-injection invariant (gen types never enter a consumer options tree) + **config-thunk deferral byte-identical on gen-merge**. Full record: `gen-specs/2026-07-02-cross-compat-module-expansions-plan.md` + [[project_gen_resolve]].

## Update (2026-07-01d) — EXAMPLES production-ready (pass 2) + ecosystem 100% shipped

Pass 2 (ultracode, agents run nix eval/tests per example): **22 examples across 9 repos made production-ready + PUSHED** — 12 started BROKEN, **0 still broken**. Fixes: gen-aspects/examples/demo (the known breaker) migrated off removed derive.fixpoint/topoSort/entry* → gen-scope.circular + dispatchStep/dispatchInit + gen-graph.phaseOrder + rules declare phase (49 outputs green); sql-schema finished (gen-algebra functor→.lib, gen-schema nix/lib→lib, 167/167); nest-traits modernized (gen-graph.lib, 94/94); gen-vars/multi-target (4/4); **many gen-scope templates had EMPTY 0-byte flake.locks** (regenerated → pinned current published revs, each verified via real nix eval — demo/dep-resolver/feature-flags/nix-config-acl/rbac/module-resolver/config-cascade/type-checker all green); agents also CREATED missing example READMEs (theory-accurate). gen-rebuild + gen-vars root flake.locks bumped to current siblings (ci green). Final: **0 TRACKED local-path leaks ecosystem-wide** (scrubbed last stragglers: gen-algebra/default.nix, gen-schema/flakeModule.nix, gen-derive/ci/tests/conflict.nix comments). All 13 repos synced+clean. **Verified production test counts:** prelude 41, algebra 128, schema 397, aspects 78, scope 167, graph 153, select 104, bind 65, dispatch 55, resolve 58, rebuild 211, vars 47. Ecosystem is foundation-ready for den-hoag. Papers gen-specs/ still UNCOMMITTED (user's call). genx OUT of scope (untouched, keeps its __functor).

## Update (2026-07-01c) — DEEP correctness+conformance pass SHIPPED (eval-verified) + real code fixes

Second, deeper sweep (ultracode, agents ALLOWED to run nix eval/flake check — the first pass forbade it and was too shallow). 12 lib READMEs re-verified against ACTUAL source + real test runs; 67 discrepancies corrected + all 12 committed+PUSHED. Real bugs the eval caught: **gen-schema** wrong test count (379→**397**), invalid test command, **non-evaluating API examples** (`schema.types.refined`→`schema.refined` — flat exports, would've thrown); **gen-prelude** stale "## Status" claiming toposort is a TODO (it's VENDORED+exported since 2026-06-26) + missing toposort/partition from API + wrong surface (45 members) — Status removed, Overview+Provenance added; near-miss headings fixed ecosystem-wide (`## Primitives`/`## API`→`## API Reference`); real verified counts everywhere (prelude 41/2, algebra 128/13, schema 397/100, aspects 78/16, scope 167, graph 153, select 104/9, bind 65, dispatch 55/10, resolve 58/13, rebuild 211/15, vars 47/7). **HARD FAIL enforced (user): NO local/private file-structure refs in any gen public doc OR lib source comment** — scrubbed den-architecture/gen-specs//FUTURE_WORK.md/spike-path refs from READMEs AND lib comments (gen-dispatch dispatch/step/default.nix, gen-rebuild default/drivers.nix, gen-prelude default.nix); final sweep = **0 leaks**. **REAL CODE FIX: gen-vars order enrichment was latently BROKEN** against current gen-graph — default.nix used obsolete `gen-graph { inherit lib; }` functor-call (throws; gen-graph is `.lib`-only now) → fixed to `inputs.gen-graph.lib` (verified mkPlan.impactOf/depsOf) + dropped the last banned `__functor` from gen-vars/flake.nix. genx `__functor` left (out of scope). STILL DEFERRED (pass 2, examples/demos): gen-aspects/examples/demo pins gen-derive + calls removed derive.fixpoint/topoSort/entry* (WILL BREAK); gen-scope/examples/sql-schema README + rules.nix:67 comment.

## Update (2026-07-01b) — ecosystem docs-freshness sweep SHIPPED (pass 1: libs + reference specs)

Ultracode workflow refreshed every gen library's markdown + papers reference specs against current reality. **13 code repos committed + PUSHED** (gen hub `1a38083`, gen-prelude/algebra/schema/aspects/scope/graph/select/bind/dispatch(gen-derive dir)/rebuild/vars + gen-resolve `e786a53`): ecosystem tables now list the current libs (gen-dispatch not gen-derive; +prelude/resolve/rebuild/vars), fixpoint/ordering relocation reflected, purity/dep-class facts corrected, fabricated test totals dropped. **gen-resolve README fully REWRITTEN to the gen convention** (was non-compliant) + **hola stripped** from it AND from gen-resolve lib comments (classkey.nix/override.nix) + ci/tests/purity.nix comment (gen assumes hola doesn't exist; technical rationale preserved, comments-only, ci green). Only hola leak in gen was gen-resolve. **PAPERS gen-specs/ REFERENCE.md + den-hoag + ECOSYSTEM/THEORY-COMPLIANCE/DELTA-NETS updated but UNCOMMITTED (user's call)** — 18 files. mdformat pre-commit hook reformats markdown → needs stage-retry (2-pass commit). **PASS 2 = examples/demos DEFERRED** (deliberately not touched): most consequential = **gen-aspects/examples/demo BREAKS on new gen-dispatch** (flake pins gen-derive + modules call removed derive.fixpoint/topoSort/entry*); also gen-scope/examples/sql-schema/README.md stale (code already migrated) + rules.nix:67 stale "gen-dispatch.fixpoint" comment; gen-vars flake.nix still has banned `__functor` (code-convention pass). Historical spike dirs (gen-resolve/spike, gen-rebuild/spike) intentionally left.

## Update (2026-07-01) — gen-derive → gen-dispatch (loop⊥step refactor SHIPPED)

**gen-derive renamed to gen-dispatch** and re-chartered as the pure relational dispatch STEP. The convergence LOOP (`fixpoint`, deleted) moved to gen-resolve/`gen-scope.circular`; phase ORDERING (`topoSort`/`entry*`, deleted) moved to **gen-graph** as `order.nix` (`entry*`+`phaseOrder` over condensation). New `gen-dispatch.dispatchStep`/`dispatchInit` pair the step with any loop (byte-identical to the old fixpoint). `dispatch` now takes a pre-ordered `phaseOrder` list. Published: gen-graph `3f57be8`, **gen-dispatch `ad633a1`** (github repo renamed, redirect live), gen hub `82d5922` (`mkGenLibs.dispatch`), gen-scope `1bff817` (sql-schema demo migrated, oracle 167/167 byte-identical). Ecosystem is now **11 libs** (prelude/algebra/schema/aspects/scope/graph/select/bind/**dispatch**/resolve + the standalone gen-rebuild/gen-vars). Full detail in [[project_gen_resolve]].

## Update (2026-06-26)

Ecosystem grew past the original eight: **gen-vars** (9th, [[gen-vars-spec]]),
**gen-rebuild** (incremental rebuilder), **gen-resolve** (RAG schedule-conductor —
**SHIPPED+PUBLISHED+HUB-WIRED+4-lens-review-hardened 2026-07-01**, `github:sini/gen-resolve` @56209bb,
hub `mkGenLibs.resolve` @df5baf7; en route fixed gen-bind @4dcdea0 evalModules-safe validator +
added gen-scope @f8ecbef `queryReverse` — [[project_gen_resolve]]), and **gen-prelude** (10th — pure, **nixpkgs-lib-free** utility
base). gen-prelude SCAFFOLDED + PUBLISHED 2026-06-26 (`github:sini/gen-prelude` @892019d,
zero-input flake, 44 exports) and wired into `gen/` mkGenLibs as `prelude`. The
nixpkgs-`lib` purity audit (gen-specs/gen-prelude/) found the `lib.types`/`evalModules`
tether spans **4 of 10 libs** (gen-aspects+gen-schema deep, gen-vars+gen-algebra split;
gen-bind is aware-not-dependent → pure-with-vendoring). The **pure-gen module system**
is the end goal — see [[project_gen_resolve]].

## Current State (2026-05-26)

Eight libraries total. **All eight shipped.**

**Next step:** Begin den v2 integration (HOAG architecture).

**User-facing (library integration):**
- gen-derive (guarded graph rewrite rules) — SHIPPED, 55 tests, 11 suites
- gen-select (selectors/patterns for matching) — SHIPPED, 163 tests, CSS + SQL WHERE demos
- gen-graph (accessor-based graph queries) — SHIPPED, 105 tests, C-level BFS, fleet-scale
- gen-bind (inject bindings into NixOS modules) — SHIPPED, 40+ tests, merge strategies + contracts

**Infrastructure (wired by frameworks, invisible to end users):**
- gen-scope (HOAG evaluator) — SHIPPED, 145 tests, _eval memoization, selective materialization
- gen-schema (typed registries with _introspection) — SHIPPED, 129 tests, decoupled
- gen-aspects (aspect type system) — SHIPPED, 40 tests, cnf.metaModules + identity unification
- gen-algebra (pure primitives, renamed from gen 2026-05-26) — SHIPPED, 40 tests

## Module-tier relocation (2026-06-26)

gen-algebra `module/` (mkIdentityModule/mkStrictModule/mkValidator/runValidators/formatErrors/defaultOnError/mkRefType) **relocated to gen-schema**, its sole consumer → gen-algebra is now **fully pure** (lib.types-free, `{ ... }: { pure=pure; }//pure`, default.nix's `lib` arg unused). New gen-schema lib files `identity.nix`+`strict.nix`; validator base folded into `validate.nix`; all six exported publicly. `mkRefType` **retired** — merged into existing `genSchema.ref` (direct mode = behavioral superset; 3 ref-type fixtures + demo README migrated to `ref`). gen-schema still imports only `genAlgebra.pure.record`. Purity invariant added: `gen-algebra/ci/tests/purity.nix` greps `default.nix`+`pure/` for lib.types/mkOption/evalModules (verified: catches injection). Tests: gen-algebra 129/129 (was 144; identity-standalone STAYS = pure `mkIdentity`), gen-schema 397/397 against PURE gen-algebra (+18 ported unit tests: identity-hash/opt-out/explicit, strict-module, runvalidators). `gen/ci/repl.nix` mkValidator repointed; gen-aspects+den use NO gen-algebra directly. Spec (has full **rollout/push-ordering checklist**): `gen-specs/gen-algebra/2026-06-26-module-tier-relocation.md` + `gen-specs/gen-prelude/2026-06-26-gen-ecosystem-purity-audit.md`. NOT YET COMMITTED/PUSHED. Push order: commit 3 repos → push gen-algebra → bump+push gen-schema (flake.lock + drop --override) → push gen → migrate downstream. **DOWNSTREAM CONSUMER OF RELOCATED mkValidator (missed in first sweep — omnissiah was wrong guess; real nix-config=`~/Documents/repos/sini/nix-config`):** `modules/den/schema/host.nix` (valid-channel) + `group.nix` (posix-needs-gid) call `gen-algebra.mkValidator` → repoint to `schemaLib.mkValidator` (schemaLib=inputs.gen-schema.lib, repo's existing convention) after push; breaks on gen-algebra bump otherwise. Community `den-configs/nixfos` same usage but pinned @49f6721 (informational). gen-schema ci/flake.lock still pins OLD gen-algebra (works either way — only needs pure.record).

## gen-algebra pure-tier consumer analysis (2026-06-26, post-relocation)

After the module relocation, gen-algebra's remaining pure exports have THIN real usage (measured across all gen-* + den + nix-config, lib-code vs tests/demos): **`record` core (Leijen/Bracha)** → gen-schema/lib ONLY (mixin/bridge/entry-type ×3); **`intensionalEq`** → gen-select/lib ONLY (constructors.nix:79); **`mkIntensional`** → tests only (gen-select, gen-derive); **`either`** → 0 lib (gen-schema demo + Vic's zen); **`search` monad (Palmer §3, the headline feature)** → 0 lib (only gen/repl + legacy flake-aspects origin); **`mkIdentity`** (pure standalone) → 0 anywhere = DEAD; **`foldLayers`/`foldLayersTraced` family** → 0 lib (gen-aspects DEMO only). gen-derive/lib/core/rule.nix takes a `genAlgebra` arg it never uses (vestigial). den + nix-config use NO pure component. **Verdict:** NOT one component shared across ≥2 libs in lib-code; gen-algebra ≈ two single-consumer deps (record→gen-schema, intensionalEq→gen-select) + reference search monad + dead/demo surface. gen-prelude promotion = NO for all (it's the nixpkgs-lib UTILITY layer; these are domain algebra). Safe deletes: mkIdentity (+identity-standalone test), gen-derive vestigial arg. Open decisions: search monad fate (den-v2/HOAG consumer? else dead weight), either (wire gen-schema's Either-shaped validate/derive to use it, or leave generic), whether record→gen-schema roll-in is worth it.

## pure→lib rename + ecosystem decoupling (2026-06-26, PUSHED)

Follow-on to the module relocation, all PUSHED to main: **gen-algebra `pure`→`lib`** rename (dir `pure/`→`lib/`, flake output + result attr `{ lib=lib; }//lib`; `genAlgebra.lib.<x>` and top-level `genAlgebra.<x>`; `lib` arg still accepted+unused). Rev **a36f93b**. Consumers repointed `.pure`→`.lib` + lock-bumped: gen-schema **2946aed** (397/397), gen-derive **3abbf5a** (68/68, +picked up orphaned README). **gen-select went ZERO-DEP** (dropped gen-algebra AND nixpkgs.lib; intensionalEq inlined `a:b: a.name==b.name` in constructors.nix; `lib/default.nix` takes `{ ... }`); feat/scope-adapter-entity-kind merged→main **0960170** (104/104). **gen-bind moved nix/lib→lib on gen-prelude** (`{ prelude }`, drops nixpkgs.lib) **b2bb0e7** (64/64). **gen** mkGenLibs wired to all: `import gen-bind/lib {prelude}`, `import gen-select/lib {}`, `algebra.lib`; lock bumped; rev **e6f6f63**; mkGenLibs verified eval (all 9 libs resolve). gen-prelude da654d0. STILL PENDING: **nix-config migration** (host.nix valid-channel + group.nix posix-needs-gid: `gen-algebra.mkValidator`→`schemaLib.mkValidator`=inputs.gen-schema.lib; bump gen-algebra+gen-schema locks; PUBLIC repo→PR+auto-merge per [[feedback_automerge_prs]]). den-configs/nixfos pinned-old (informational).

## Root-file convention cascade (2026-06-27, SHIPPED)

Ecosystem-wide unification of flake.nix/default.nix/lib-layout. Designed by workflow `wirkldmkv` (survey 9 libs → 3 candidates → judge → adversarial critique); spec `gen-specs/2026-06-26-gen-lib-root-convention.md`. **Canonical:** every lib flake exposes a SINGLE `.lib` VALUE output (NO `__functor`); source in `lib/`; `lib/default.nix` a pure fn of NAMED dep VALUES (no `inputs` bag, no in-lib fetchTarball); 4 honest dep classes (A pure `{}` / B prelude `{prelude}` / C nixpkgs-lib `{lib}` / D nixpkgs-lib+gen-dep `{lib,algebra|schema}`); each flake declares its OWN upstream gen inputs; root default.nix = standalone shim pinning deps from own flake.lock via fetchTree. **gen-algebra `{lib=lib}//lib` self-nest DELETED** → consumers use `algebra.record` not `.lib.record`. **Executed via subagent-driven-development (8-step gated cascade, implementer+spec-review+quality-review per step).** Pushed revs: gen-prelude 7f9475a, gen-algebra aaffd3f, gen-graph caf4972, gen-scope e8789db (gained lib/default.nix), gen-bind 52304ce, gen-select 1399f8f (no change), gen-schema e789c33 (nix/lib→lib, flakeModule pins algebra), gen-aspects c7b6e97, **gen hub b2327f6 (mkGenLibs collapsed to flat `genInputs.gen-X.lib` re-export)**. nix-config: PR #160 MERGED (schema validators gen-algebra.mkValidator→`inputs.gen-schema.lib.mkValidator`, the relocation migration folded in). **den step 8 SKIPPED** (convention-clean, no compat change — bumps naturally next routine update). KEY LESSON: the 2-stage review caught the latent-breakage class the design's per-lib lists kept missing — demos/READMEs/ci-tests consuming migrated deps via the now-dead flake-functor `inputs.gen-X { inherit lib; }` form (gen-scope had 10 example flakes; gen-aspects' demo wires all 8). Convention WART (sound): nixpkgs-lib libs (graph/scope/schema/aspects) now use their OWN pinned nixpkgs.lib (self-wired), not a consumer-shared one. FUTURE (deferred): vendor module machinery onto gen-prelude to retire Class C/D→B (zero-nixpkgs ecosystem). gen-derive = active parallel work, EXCLUDED (already Class B conformant). NIX-CONFIG PR POLICY UPDATED → [[feedback_automerge_prs]] (minor diffs = direct main push, not PR).

## Architecture

```
gen-algebra (FULLY PURE primitives, exported as .lib; module tier in gen-schema)
├── gen-schema (imports gen-algebra; typed registries)
├── gen-select (imports gen-algebra pure tier; selector algebra)
│   └── gen-derive (imports gen + gen-select; stratified rule dispatch)

gen-aspects (pure types, independent)
gen-scope (HOAG evaluator, independent) — framework authors only
gen-graph (accessor-based graph queries, independent)
gen-bind (module binding, independent)
```

Coupling point is the CONSUMER (den), not the libraries.

## gen-scope (HOAG) — ~/Documents/repos/gen-scope/

- True HOAG: demand-driven tree expansion via `children`/`derived-children` attributes
- Co-located `_eval` memoization on every node (root + synthesized)
- API: `eval { roots, attributes, parseParent }` → `{ node, get, allNodes, subtreeOf, nodesOfType, allNodesWhere }`
- Selective materialization for fleet-scale: subtreeOf, nodesOfType, allNodesWhere
- `self.node id` (function), `self.get id attrName` (memoized)
- No convergence loop, no `self.nodes` flat map, no `synthesize` parameter
- Import edges are COMPUTED attributes (`self.get id "imports"`)
- `buildNodes` produces minimal `{ id, type, parent, decls }` with `decls.__edges`
- 145 tests including Neron semantics (specificity, WF, ambiguity, custom edges, subtypeOf)
- Spec: `2026-05-24-gen-scope-hoag-redesign.md`
- Plan: `plans/2026-05-25-gen-scope-hoag.md`

## gen-graph (accessor-based) — ~/Documents/repos/gen-graph/

- Queries take accessor functions: `{ edges = id: [...]; }` not node maps
- C-level BFS via `builtins.genericClosure` (~4.5x faster than Nix-level BFS)
- New: `canReach` (point query), `selfReachable`, `dependentsOf` (O(n+reachable) single-target)
- Traversal is lazy (only visits reachable nodes via genericClosure)
- Global ops (cycles, dependents, transpose) materialize internally
- Split: traverse.nix, edge-maps.nix, enumerate.nix, fixpoint.nix, global.nix, mock.nix
- `transitiveReduction` O(1) inner membership via attrset
- Fleet-scale guidance: partitioning, point queries before global ops
- 105 tests
- Plan: `plans/2026-05-25-gen-graph-rewrite.md`

## gen-bind — ~/Documents/repos/gen-bind/

- Injects external bindings into NixOS module functions
- Merge strategies (bind-wins/system-wins/error), lazy contracts (Chitil), provenance (Findler), signature inference (Cardelli), thunk deferral
- Terminology: "merge strategy" NOT "collision policy"; "bind-wins" NOT "den-wins"
- `_mergeStrategy` (single underscore, module-safe), `__configThunk` (double, framework marker)
- `wrapAll` pre-computes shared contracted bindings for batch efficiency
- Laziness preserved: binding values never forced at wrap time
- 40+ tests
- Spec: `2026-05-25-gen-bind-design.md`

## gen-derive — ~/Documents/repos/gen-derive/

- Stratified rule dispatch with fixpoint convergence
- Two-tier: core (gen pure) + adapter (gen-select bridge)
- dispatch (one-shot), fixpoint (convergent loop), mkRule, fromFunction (canTake pattern)
- mkActions generates tagged constructors + classify from phase declarations
- Conflict resolution: override → priority → specificity → additive ties
- Rule composition: restrict, override, chain
- Phase DAG: entryAnywhere/entryAfter/entryBefore/entryBetween/topoSort
- 55 tests, 11 suites

## Specs Index

All at ~/Documents/papers/den-architecture/specs/:
- `2026-05-24-den-v2-hoag-architecture.md` — main den v2 spec (gist: sini/d6596f716e99ab6b0bb2793776c94bb1)
- `2026-05-24-gen-scope-hoag-redesign.md` — HOAG architecture (gist: sini/235c6b141935fdf9a9b18272b0761aab)
- `2026-05-24-unified-vocabulary.md` — ecosystem terminology (gist: sini/6a5188d1f8bb04a8a8c7a425b6dbad7c)
- `2026-05-24-ecosystem-decoupling.md` — decoupling plan (DONE)
- `2026-05-24-gen-select-design-hints.md` — selector algebra hints (gist: sini/a3ad3282d5e5bc30fb70947179062298)
- `2026-05-25-gen-select-design.md` — selector algebra spec (gist: sini/d0a15a78eda49b4d7da7fedf27b3b10f)
- `2026-05-25-gen-bind-design.md` — module binding (gist: sini/6d3b6256fe670f937dd630b13ee27c38)
- `2026-05-25-gen-derive-design.md` — guarded graph rewrite rules (stratified dispatch, fixpoint convergence, NACs)

## Plans Index

All at ~/Documents/papers/den-architecture/plans/:
- `2026-05-25-gen-scope-hoag.md` — gen-scope HOAG rewrite (DONE)
- `2026-05-25-gen-graph-rewrite.md` — gen-graph accessor rewrite (DONE)
- `2026-05-25-gen-select.md` — gen-select selector algebra (DONE)
- `2026-05-25-gen-derive.md` — gen-derive rule dispatch (DONE)

## Key Design Decisions

- gen-scope is infrastructure — framework authors only, never user-facing
- gen-graph + gen-select are the user-facing query layers
- gen-bind bridges scope-computed values into the NixOS module system
- gen-derive replaces hand-rolled policy dispatch (eliminated PRs 408-437 regression class)
- gen-scope's `_eval` memoization is the performance backstop for gen-graph accessor calls
- Nix attrset VALUES are lazy, KEYS are eager — this is why `node` is a function not a map
- `parseParent` is mandatory for fleet scale (O(depth) vs O(n) resolution)
- `allNodes` (Tier 2) forces full tree — use for diagrams/fleet queries only

──────── archive-project_gen_rebuild.md ────────
---
name: project_gen_rebuild
description: "gen-rebuild v1 — pure-Nix incremental rebuilder gen lib, SHIPPED 2026-06-23"
metadata: 
  node_type: memory
  type: project
  originSessionId: 85325dea-fe37-4f8b-af92-9a402cf12e16
---

gen-rebuild v1 SHIPPED 2026-06-23 — new PUBLIC repo `github:sini/gen-rebuild`
(built at ~/Documents/repos/gen-rebuild/), 6 commits on main, 41 tests green.

The **rebuilder** dimension of Mokhov 2018 as a standalone gen lib — answers "given
last eval, must key K be recomputed?" and does minimal recompute + reuse. Composes
gen-graph (topology oracle) + gen-scope (threaded but unused in v1; v1 owns its own
thin store-backed `lib.fix` eval loop — gen-scope's `_eval` memo is welded to its
own `lib.fix self`, so the S1 warm-cache seam is deferred to v2).

**v1 surface:** `build` (flat relocatable id-keyed store + verifying trace +
located-cycle precheck), `override` (reverse-topo splice — authoritative form is
`ctx.store // lib.fix (s: genAttrs cone (id: recompute accessor' (ctx.store // s) id))`,
NOT bare `s`; spec §4 sketch was buggy), `affected`/`impactOf` (dependent cone =
graph.dependentsOf), `dirtySet` (deduped union of cones). Dirty-bit, whole-cone,
eager, intra-eval. Soundness property-tested over 120 seeded random DAGs
(override.store == from-scratch build(acc').store, byte-identical). B demo at
`examples/dag/` (poisoned-recompute proof of cone-only recompute) = the hola
Phase-3 (B) gate.

**Gotchas:** tryEval does NOT catch toJSON-on-function (uncatchable) → detect
function-bearing values structurally for the hash guard (hash=null = always-dirty);
tryEval forces only WHNF (attrset spine) → deepSeq the store to surface value-thunk
throws. ci is the gen mkCi convention (`cd ci && nix flake check`); mkCi uses
import-tree (every ci/tests/*.nix is a flake-parts module — gen.nix exposes the
seeded generator via `_module.args.mkCase`). gen-scope flake exposes only
`__functor` (no `.lib`) → `import gen-scope { inherit lib; }`.

**Deferred (separate plans):** v2 = rebuilder strategies (verify/constructive/
deepConstructive/earlyCutoff) + provenance + drivers + seams S1–S6; v3 = intra-eval
optimality (RTD `O(|AFFECTED|)`, sharing/swapping/switching). Impure cross-eval
shell is OUT of scope (spec §7 — a stateful substrate, not a deferred component).

**v1 verified GO 2026-06-23** (B demo `examples/dag` evals: resultEqualsFullRebuild
+ coneOnlyRecompute + poisonIsReal + cycleIsLocatedBlame all true; ci flake check
green). Paradigm go/no-go PASSED — graph-based incremental override is sound +
inspectable. Caveat surfaced: v1 override is DATA-change only (edges fixed);
topology change = v2.

**v2 FULL-DOMAIN spec authored 2026-06-23** (den-ag-design `aa29a1e`,
`gen-specs/gen-rebuild/2026-06-23-gen-rebuild-v2-design.md`, 1105 lines). Scope
decided w/ user: full v2 multi-plan, 3 repos; seams trimmed to gen-graph S3
(dependentsFrontier) / S4 (seededFixpoint) + gen-scope S1 (evalWarm) / S2
(recordedDeps) — **S6 DROPPED** (O(1) order-maintenance impure-or-O(N²) in pure
Nix; lib.fix already orders); **constructive/deepConstructive DEFERRED to v3/hola**
(= Nix store/IFD). Plan DAG: P0 gen-graph ∥ P1 gen-scope → P2 strategies+provenance
→ P3 drivers+structural(retract/applyEdgeDelta); P4 restabilize after P0(S4).
KEY FINDINGS from the design workflow (7 design→adversarial-verify→synth→3-lens
panel→revise, ~1.9M tok): (a) the v1-sketched evalWarm adapter is WRONG (evalWarm.get
resolves deps via own self, not store-arg) → **NO v2 op consumes S1**, ships
standalone, wired at hola/v3; (b) **null-hash false-clean** (`null!=null==false` →
changed function-bearing node silently reused = unsound) recurs in every
hash-comparing op → single `hashEq`/`hashMoved` guard mandated; 120-seed integer
property can't catch it (needs fn-bearing fixtures); (c) earlyCutoff delivers
per-node recompute-SKIP but only O(|cone|) allocation (true O(|AFFECTED|) = S7/v3);
(d) S3's real consumer is P3 propagate not P2 (P2 uses existing dependentsOf).
Every op gen-theory-conformance **gap-stated** (faithful mechanism, honest pure-Nix
gaps).

**Both forks RESOLVED + spec updated 2026-06-23** (den-ag-design 2nd commit on the
v2 spec): (1) sub-plans = separate milestone-gated PRs, gen-rebuild NOT on hola's
critical path (hola harness proceeds in parallel) → optimize for review quality;
(2) **WIDEN P0** — added a gen-graph `condensation` primitive (closure-based O(n²)
SCC: u,v co-SCC iff each reaches the other via transitiveClosure; NOT Tarjan's
mutable-stack O(V+E) = out-of-substrate). restabilize AUTO-DERIVES the SCC partition;
`fixpoint.lattices` now keyed PER-NODE; precheck relaxed to `set(cycles) ⊆
keys(lattices)`; footgun (consumer-declared sccs) gone. **S4 seededFixpoint demoted**
to standalone gen-graph export (no v2 gen-rebuild consumer — runScc can't reduce to
it; parallels S1's status). Designed+verified via a 4-agent workflow; caught
index-alignment desync (reps must == bottomUp), per-member-lattice runScc body,
bottom-up edge-direction; finalizer confirmed vs live gen-graph tree via
nix-instantiate. **P0 SHIPPED 2026-06-23** — gen-graph PR https://github.com/sini/gen-graph/pull/1
(branch feat/v2-seams, 4 commits: 22c659e _reverseIndex extraction byte-identical,
e4b65a7 dependentsFrontier S3, 8a037c9 seededFixpoint S4, 4c8da99 condensation+coScc).
128 tests (110+18), TDD red-first, all spec+quality reviewed+approved, treefmt+ci
green. Executed via subagent-driven-development (one impl subagent + combined review
per task); plan+tasks.json at den-ag-design gen-specs/gen-rebuild/...-v2-p0-...
PR NOT merged (user reviews/merges). P0 PR MERGED 2026-06-23 (rebase-merge, 4 commits on gen-graph main).

**P1 SHIPPED 2026-06-23** — gen-scope PR https://github.com/sini/gen-scope/pull/1
(branch feat/v2-seams, 3 commits: 41d10d7 eval refactor [evalAttr+warm params,
byte-identical], 7a75deb evalWarm S1, 24c1b1a recordedDeps S2). 163 tests (152+11),
eval byte-identical, evalWarm single-path wrapper, NEITHER consumed by any v2
gen-rebuild op (S1 adapter=v3/hola). TDD red-first, all reviewed+approved. Executed
subagent-driven; plan-review was executable (applied edits to scratch eval.nix,
proved byte-identity + all 11 tests). **PR #1 MERGED 2026-06-23** (gen-scope main).
NOTE: a separate user/agent pass fixed comment style + added API docs + updated
gen-specs/<lib>/REFERENCE.md for gen-graph+gen-scope — P2+ plans MUST include a docs
task per [[feedback_gen_lib_docs]] (theory-cited comments, lib README, REFERENCE.md).
**P2 SHIPPED 2026-06-24** — gen-rebuild main @ 0e27afc (5 commits, self-MERGED ff,
NO PR per user [[feedback_gen_direct_merge]]). 110 tests. hashEq/hashMoved null-safe
gate; strategies verify(Mokhov§4.2)/earlyCutoff(RTD§4.1)/needsEval(RTD§5.3, DISTINCT
not !verify.reuse); affectedSet + override REWRITTEN to needsEval-gated splice
(120-seed soundness PRESERVED byte-identical, failingSeeds==[]; affected⊆cone;
collision⇒[]; null-hash-through sound); provenance support/why/whyNot (why⟺dirtySet
120-seed). dirtySet unchanged. Executed subagent-driven (5 tasks); executable
plan-review proved override-soundness in scratch first; combined review gate before
self-merge. **Pre-work this session: v1-provenance PR #1 MERGED (theory citations to
v1 comments) + a full theory-conformance audit (gen-rebuild FAITHFUL, 0 defects;
audit+citation-worklist at gen-specs/gen-rebuild/2026-06-23-conformance-audit.md).**
PRE-FLIGHT for P3/P4 (citations + algorithms in the conformance-audit doc):
- **P3 (drivers force/applyDelta/batch/propagate + structural retract/applyEdgeDelta)
  needs P0-S3 dependentsFrontier → BUMP gen-rebuild flake's gen-graph input** (P0
  merged on gen-graph main).
- **P4 (restabilize/runScc) needs P0 condensation → same gen-graph bump.**
- **DOCS: write gen-specs/gen-rebuild/REFERENCE.md + lib README in a single pass
  AFTER P4** (deferred per user); theory-cited comments per-task throughout.
**P3 SHIPPED 2026-06-24** — gen-rebuild main @ 52a9613 (self-merged ff, no PR): drivers
(applyDelta/batch/propagate/force/forceCtx + override=propagate∘applyDelta, SINGLE
union-cone form via existing dependentsOf) + structural (retract/applyEdgeDelta +
withNewTopology/reCycleCheck). 155 tests; ALL FOUR 120-seed gates [] (data-change
soundness, fusion-law, edge-varying, retract). KEY: the fusion-law test caught a real
multi-seed propagate soundness bug (only head-seed forced recompute) — committing the
pre-written impl before its multi-seed tests let it land, fusion-law caught it
(LESSON: write multi-seed tests before committing multi-seed impl). DECISION: form-(a)
frontier over dependentsFrontier DEFERRED to v3 (allocation optimization; cortex pivot
de-prioritized allocation perf) — so dependentsFrontier's consumer is v3, and P3 needs
NO gen-graph bump. Executed subagent-driven; executable plan-review + combined review
gates (caught a §5.P3.a working-spec leak).
**P4 SHIPPED 2026-06-24 — gen-rebuild v2 IMPLEMENTATION COMPLETE** (main @ 97c9af3,
self-merged ff, no PR; all of P0-P4 now merged). P4 = the cyclic-fixpoint
re-stabilizer, 3 feature commits (44248a5 runScc, b5b42c4 extended build, 65ded40
restabilize), 155→179 tests. **runScc** = per-member semi-naive SCC solver
(iterate-from-⊥ to per-MEMBER eq-quiescence; widen-after-join; located
`fixpoint-diverged` blame with lastDelta = still-moving members' prev/next; Arntzenius
2016 Lemma 4 for genuine-join, Sloane 2010 §2.2 for overwrite/no-op). **build** gains
`fixpoint ? null`: null = EXACTLY v1 (v1 sub-binding, no fixpoint key); present =
condensation-stratified bottom-up `foldl'` over `graph.condensation`'s `bottomUp`
(producers-first; runScc ONCE per cyclic SCC, recompute for acyclic singletons;
byte-identical to v1 on acyclic) + relaxed precheck (`set(cycles)⊆keys(lattices)` else
located `undeclared-cyclic-node` blame). **restabilize** = incremental cyclic-capable
override: cone re-solve bottom-up, non-cone held at ctx.store, acyclic=override /
cyclic=runScc, fixpoint threaded forward. SOUNDNESS GATE: fixed-point-equality 120-seed
`[]` vs from-scratch `build{accessor';fixpoint}` oracle, with **83/120 seeds genuinely
cyclic** (runScc path non-vacuously exercised). KEY FINDING (empirical, baked into the
plan + build.nix comment): **`builtins.tryEval` does NOT catch `lib.fix` infinite-
recursion (black-hole)** — so the "bare-fix diverges" gate was UNSAFE (would
escape/hang CI); substituted a `bottomUp` producer-before-consumer ordering assertion +
lfp==oracle pin. All divergence guarded by located prechecks + runScc maxIter, NEVER by
catching infinite recursion. Executed subagent-driven (3 impl agents); executable
plan-review (wr98jf6hb) up front + 2-lens adversarial final review (w33s0m038, APPROVED
0.98/0.99, zero blocking) before merge.
**DOCS PASS DONE 2026-06-24:** README full v1+v2 surface (23 exports + Cyclic-fixpoints
subsection; gen-rebuild @ 97c9af3) + NEW gen-specs/gen-rebuild/REFERENCE.md (308 lines,
house format matching gen-graph/REFERENCE.md, paper-grounded; den-ag-design @ 9151d26).
Public surface (23): build affected impactOf affectedSet dirtySet override verify
earlyCutoff needsEval support supportDirect why whyNot applyDelta batch propagate force
forceCtx mkAccessor retract applyEdgeDelta runScc restabilize (hash.nix internal).
**FINAL whole-lib gen-theory-conformance gate PASSED 2026-06-24** (adapted
gen-rebuild-only per user; wrs3asdc1) — 5 paper-cluster verifiers (Mokhov / RTD /
Acar+Forgy+Hammer / Radul / Arntzenius+Sloane+Tarjan) + adversarial challenge of every
blocking finding. EVERY op classified `faithful` or `gap-stated` (the honest posture):
ZERO overclaim/misapplication/unstated-gap, ZERO surviving defects. The honest gaps are
all stated in code+REFERENCE: O(|cone|) not O(|AFFECTED|) (RTD), full-drain force not
Adapton per-edge (S6 dropped), support/retract NAME-faithful-only (no Radul TMS),
runScc UNCHECKED monotonicity+finite-height (only maxIter), condensation closure-O(n²)
not Tarjan-linear, cyclic OUTSIDE RTD envelope. **v2 fully closed.**
**v3 deferred:** form-(a) frontier over dependentsFrontier (allocation opt); true exact-
AFFECTED O(|AFFECTED|) = S7; constructive/deepConstructive (Nix store/IFD); impure
cross-eval shell (out of scope, spec §7). gen-graph S4 seededFixpoint + S1 evalWarm
ship standalone (no v2 consumer).

**v3 MINIMALITY SPIKE COMPLETE 2026-06-24** — gen-rebuild main @ 107986e (13 commits,
self-merged ff, no PR; `spike/` dir + own `spike/ci` flake, lib/ + 179-test suite
BYTE-UNTOUCHED; 59 spike tests). Feasibility spike (NOT production): races 3 propagate
variants on a counted-forces harness to answer "can pure-Nix beat O(|cone|) toward RTD
O(|AFFECTED|), byte-identically?" VERDICT (mechanical §8 bands): **V-push = PARTIAL,
V-summary = NO-GO, baseline = reference** — the spec's pre-committed "honest likely
outcome". LEARNINGS: (a) V-push (rank-ordered eager-push: cone-local depth-rank + DIRECT
reverse-adjacency enqueue + `priorStore//settled` carry) wins on the EXPENSIVE axis
(recompute/hash/alloc) for CUT-HEAVY edits — deep-cut r_x≈0.15, sparse-affected r_x≈0.12,
byte-identical over 120-seed×6-kind — but r_x=1.0 on full-propagation (chain/wide-fan) ⇒
NO O(|AFFECTED|) generalization; (b) TOTAL-axis r_t>1 EVERYWHERE (deep-cut 2.1 even where
r_x=0.15) — the rank precompute + drive sweep are themselves ≥O(|cone|), EMPIRICALLY
CONFIRMING sub-cone-TOTAL is unreachable in a single pure eval (the §2 ordering floor);
breaking it needs cross-eval amortization = the deferred impure/persisted-DCG substrate;
(c) V-summary (deep-constructive-trace summary) NO-GO: summaryForces O(|cone|²) (231 vs
cone 21) per Mokhov §4.2.4 "no early cutoff except at n levels". NEXT: follow-on v3 build
plan = land V-push as a SCOPED cut-heavy fast path (behind the 120-seed gate; cut-heavy-
vs-full-propagation r_x split = its perf contract) — a value call, NOT a GO; the r_t>1
ceiling = quantified input to the [[project_zen_vic]]/[[project_hola]] substrate-
convergence decision. Spec+plan+results in gen-specs/gen-rebuild/2026-06-24-*v3-minimality-
spike-*.md (design reviewed via 31-agent workflow; build executed subagent-driven — 10
tasks, each 2-stage reviewed; §8 collision-band spec defect fixed: collision is a
soundness probe, |cone|=1 ⇒ r_x=1.0, excluded from the perf bands).

**v3 V-PUSH FAST PATH SHIPPED 2026-06-25** (the PARTIAL→land decision executed; user
deprioritized cross-eval, so this is the realized v3) — `genRebuild.propagateEager`, gen-rebuild
main @ 26a5c52 (self-merged ff, no PR). 2-repo plan, subagent-driven (4 tasks, each 2-stage
reviewed): (1) gen-graph PR #2 MERGED (`coneRank` cone-local producers-first rank + `directDependents`
DIRECT reverse-adjacency, exposing private `_reverseIndex`; 141 tests); (2) `lib/eager.nix` —
propagateEager, an OPT-IN cut-heavy fast path returning the standard BuiltCtx (chains like
override/propagate; default unchanged); rank-ordered eager push, DIRECT cone-restricted enqueue,
§4(B) `ctx.store//settled` carry, affected-only trace' re-hash; (3) soundness gate: 120-seed
byte-identity (mkCase) + cutoff-join §4(B) with a JOIN-POISON right-reason proof (Q carried, never
recomputed — the case override's single-id 120-seed can't reach) + chained + deep-cut poison; full
suite 179→210. (4) README + REFERENCE.md, honest perf contract (byte-identical; O(|AFFECTED|+frontier)
constructed on cut-heavy, O(|cone|) drive bookkeeping regardless ⇒ constant-factor EXPENSIVE-axis win,
NOT total-work O(|AFFECTED|); total-axis floor = deferred cross-eval). GOTCHA (now in
[[feedback_gen_lib_docs]]): gen CI treefmt includes **mdformat** run `cd ci && nix fmt -- --ci`;
local root `nix fmt`/`nix flake check` miss it — gen-graph PR #2 first push failed CI on an
unformatted README (`\|`→`|` un-escape). Plan: gen-specs/gen-rebuild/2026-06-24-gen-rebuild-v3-vpush-fastpath-plan.md.
Remaining v3 (per [[project_zen_vic]]/[[project_hola]] substrate-convergence) NOT pursued: true
total-minimality / S7 / deepConstructive all need cross-eval persistence.

Spec + plan: ~/Documents/papers/den-architecture/gen-specs/gen-rebuild/. Part of the
gen ecosystem [[project_gen_package]]; effects-paradigm dual is [[project_zen_vic]];
consumed by [[project_hola]]. Docs root [[reference_gen_docs]].

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [gen-rebuild v1+v2+v3-spike](project_gen_rebuild.md) — pure-Nix incremental rebuilder (Mokhov rebuilder dim) github:sini/gen-rebuild; v2 COMPLETE (P0-P4, 179 tests + REFERENCE.md): build(+fixpoint cyclic)/override/strategies/affectedSet/provenance/drivers/structural/restabilize+runScc, soundness 120-seed; v3 MINIMALITY SPIKE COMPLETE 2026-06-24 (main @ 107986e, spike/ dir + 59 tests, lib untouched): VERDICT V-push=PARTIAL (sub-cone EXPENSIVE-axis win on cut-heavy r_x≈0.12-0.15 byte-identical, but r_t>1 everywhere ⇒ sub-cone-TOTAL unreachable in pure eval = §2 ordering floor) / V-summary=NO-GO (summaryForces O(|cone|²), Mokhov §4.2.4); v3 V-PUSH FAST PATH SHIPPED 2026-06-25 (main @ 26a5c52): genRebuild.propagateEager opt-in cut-heavy fast path (BuiltCtx, chains; gen-graph PR #2 merged = coneRank+directDependents; 210 tests incl 120-seed + cutoff-join §4(B) join-poison; honest perf contract NOT total-O(|AFFECTED|)); remaining v3 (true minimality/S7/deepConstructive) NEEDS cross-eval persistence, NOT pursued (user deprioritized); mdformat CI gotcha → [[feedback_gen_lib_docs]]

──────── archive-project_gen_resolve.md ────────
---
name: project_gen_resolve
description: gen-resolve — pure-Nix RAG schedule-conductor; v1 SHIPPED+PUBLISHED+HUB-WIRED+4-lens-REVIEW-HARDENED 2026-07-01 (github:sini/gen-resolve @56209bb, gen hub @df5baf7)
metadata: 
  node_type: memory
  type: project
  originSessionId: a899d097-53e9-43c6-94cd-81a083cef686
---

**gen-resolve** = a NEW gen library, the demand-driven, incremental, **higher-order reference-attribute-grammar evaluator over algebraic scope graphs** — the "attribute grammar evaluator over algebraic scope graphs" our specs named in passing but no lib owned. Composite/assembler tier (peer of [[project_gen_derive]]).

## ═══ 2026-07-04 MODULE-SYSTEM BENCHMARK VERDICT: KEEP — quantified win + quadratic fixed ═══
Pre-den-hoag audit "perf gain or over-engineering?" ANSWERED with benchmarks (report: `gen-specs/gen-merge/2026-07-04-module-system-benchmarks.md`; harness = parity-oracle P-trick scaled, 3 stacks, digests byte-identical everywhere). **Post-fix pure stack beats pinned nixpkgs.lib on EVERY den shape: aspects-1600 2.80×, registry-2000 2.27×, schemaHosts-1600 1.77×, scalar-16k 1.59× cpu; 2–3.6× less allocation; 936 vs 4225 engine LOC.** Clears the hola-E1 vendoring counterfactual (ownership-for-free but keeps nixpkgs cost profile); consistent with zen's lean-engine ceiling while keeping byte parity. **AUDIT FINDING (fixed): `prelude.unique` key-union was O(k²) in sibling-key count** (scalar-8k pure was 5.4× SLOWER than nixpkgs, 16k=1.76s vs 0.14s) at gen-merge modules.nix cfgKeys + types.nix attrsOfWith/mergeAnythingVals → attrset-fold union, linear (156→6.8µs/item; nixpkgs 11). **gen-merge 976a87a PUSHED to main 2026-07-04**; `prelude.unique` itself left general (order-preserving); gen-schema identity.nix:29 apply-use = small lists, not hot. Honest scope: wins are COMPOSITION-plane (den CI/fleet/dispatch/den-hoag internals); single-host NixOS eval stays terminal-dominated (hola 94%).

**PERF-REGRESSION HARNESS SHIPPED (gen hub 503a3a3, pushed, GH CI green):** `nix run ./ci#perf-bench` = ci/perf-bench.nix corpus (provider-P, pure vs frozen ref) + perf-bench.sh gates — per-cell digest PARITY (fast-but-wrong can't pass), RATIO ceilings (pure cpu ≤0.85×ref, thunks/alloc ≤0.90×; measured 0.35-0.66), LINEARITY (counters ≤5.5× per ×4 step; retro-catches the unique bug class ~11.5×). GH workflow gained `checks` (parity oracles were NOT in any CI job before!) + `perf-bench` jobs; locks bumped to 976a87a. Ratios machine-independent (GH runner 0.346 vs local 0.349 on aspects-1600). Doc: gen/ci/README.md + papers report addendum. **TRUST-RELEASE SLICE 1 COMPLETE 2026-07-05 (all 10 tasks incl owner-added 7b; roadmap `2026-07-04-gen-v1-trust-release-roadmap.md` + plan+tasks.json):** hub BENCHMARKS.md (regenerable `--update`, composition + compat + FLEET sections) + VALIDATION.md (15 libs/1745 tests fresh; §6 fleet gates) @338d5f7 CI-green; gen-merge compat suite @469dcf3; hola A1 campaign PUBLISHED @d643a8d (22 commits, fleet-gates CI green): G6 split 42.5%fc/5.2%copies, Arm-R 66.7% byte-sound, Arm-C +4.6% scope-mismatch, 7b ~1.6%/member + 212-unit core, spine ~98% ⇒ **A3 RE-SCOPED to `gen-class` lib** (owner 2026-07-05; tiers in roadmap; interface = den-hoag r2 seam contract; gates migrate to gen-class ci). Papers: A1 report `2026-07-05-a1-fleet-measurement-report.md` (uncommitted). **GEN-CLASS V1 COMPLETE 2026-07-05 (all 10 plan tasks, two-stage-reviewed):** github:sini/gen-class @218c54f+ (90 tests, purity+fence teeth, synthetic corpus w/ independent oracle pin); gen-merge fixed-input kernel @2ad1099 (coreShortCircuit, sole-def rule, byte-identical 3 ways, 78.7% fcall cut on fixture); hub mkGenLibs.class + perf-bench classShare gate (~5.8× spine reduction, thunk ratio 0.17, floor ≤0.30 = ≥3.33×, byte-gated) @7872817; hola lab re-pointed + Arm-C terminal-pessimal pinned (+1.65% fleet, byte-sound) + precommit override superseded by mkCi wrapper @4bab613; r2 seam-amendment note written (papers gen-specs/gen-class/ — the den-hoag PROPOSAL: Class/Core/Axis records, output-modules/wrap landing, firing contract, tier-3 obligations incl boundary-from-aspects WITHOUT force-probing). Slice-1.5 done (mkCi ulimit @6d259ef, hub precommit fix @d623768). **NEXT = A2 gen-flake observability→v1 redesign (seed: RESUME-trust-release-a2.md in gen-specs) + B3 lint/B4 harness parallel; then A4/B5/A5; den s1/s2 publish = OWNER decision (§8a-D5) still parked.** Protocol findings (durable): gc bytes non-deterministic; version strings ≠ evaluator identity (−8 primops, two-tier gates exact/0.1%-band); resolution-layer witness = open problem. **Q1 flake-parts compat = tiered boundary verdict:** tier1 value-injection (shipped) / tier2 portable byte-mode subset (cheap, on demand) / tier3 full compat NOT viable with speedups — killers = options-introspection (isDefined/definitions = the alloc we shed) + typeMerge functors; flake-parts uses ZERO mkOrder/mkBefore/mkAfter. **Q2 adios lessons:** memoized override w/ reverse-cone diff via genericClosure (validates warmResolve shape; design for gen-flake incremental override); genericClosure keyed module dedup (gen-merge collectModules has NO diamond-import dedup — den-safe boundary, note not code); adios-flake BENCHMARKS.md convention (their real-flake 1.3-1.4× vs our composition 1.6-2.8× = terminal dilution quantified); do NOT take last-wins//no-priority. **Q3 nixpkgs-types compat shim = ZERO adapter code** (nixpkgs types already speak (loc,defs) + property _type tags byte-compatible; `import gen-merge { prelude; types = lib.types; }`), byte-identical, leaf types FREE (0.62×ref = pure) but structural types give the whole win back (submodule.merge runs lib.evalModules per instance → 0.96×ref) → frame as opt-in migration/escape-hatch plugin, not ecosystem fast path.

## ═══ STATUS 2026-07-01: v1 SHIPPED + PUBLISHED + HUB-WIRED + 4-LENS-REVIEW-HARDENED ═══
Built T0→T12 from the plan (`2026-06-30-gen-resolve-v1-plan.md`), then hardened by a 4-lens adversarial review + delta re-review. **`github:sini/gen-resolve` @56209bb** (58 nix-unit tests + 3 §5 examples green, `lib/` nixpkgs-lib-free). **Wired into gen hub** `mkGenLibs.resolve` (@df5baf7, published-ref verified: 15-op resolve surface). **Class B = 5 gen siblings** (scope/graph/rebuild/algebra/bind); **gen-prelude is transitive-only** (the `.lib` takes NO direct prelude — classkey was its only user, now dep-free; input kept for the standalone default.nix shim). Layout mirrors gen-derive; tracker SSOT + REFERENCE.md at `gen-specs/gen-resolve/`.

**CROSS-REPO changes this build (all pushed):** **gen-bind @4dcdea0** — root-caused + fixed a real bug: the collision validator did `builtins.seq checks {warnings=checks}`, forcing `config._module.args` at module-collection WHNF → `.all` infinite-recursed through evalModules (its stated purpose). Fixed to lazy `{warnings=checks}` (+regression test). **gen-scope @f8ecbef** — NEW `queryReverse` (reverse-of-imports gather, dual of queryAll) that powers `reference target=neededBy`.

**4-LENS REVIEW (quality / idiomatic-Nix / theory-conformance / spec+den-hoag) → NO publish blockers; every finding FIXED + DELTA-RE-REVIEWED → all CLOSED.** Substantive fixes: **cascade `combine` made real** (was asserted-then-ignored — now a foldLayersTraced STRATEGY string `{replace(=shadow,default)|append|recursive}` threaded per-field over allKeys; a function combine now throws; design §6 signature updated to match); **`reference target=neededBy`** wired via the new gen-scope.queryReverse (was a no-op); **classkey de-`prelude`'d**; **cross-node warm-serve TESTED** (`override-cross-node.nix`: declared→byte-identical, undeclared→STALE witness = the soundness-(c) proof); **NTA-memo `x==x` tautology dropped everywhere** (memo unobservable in pure Nix); M1 circular+structural + mixed-SCC tested; citation honesty (AFFECTED=sound OVER-APPROXIMATION not "the reverse cone"; Knuth-acyclicity-only gate not "Vogt HOAG"; Neron+den-hoag§B2 anchor not Statix §4.3).

**DEN CARRY-FORWARDS (Phase-1 must honor):** M1 — author `enriched-context` as `attr{kind="circular"; stratum="structural"}` (explicit stratum honored for ANY kind; a "conform stratumOf to synthesized-only" refactor would break all of den, now test-guarded). soundness-(c) — `declaredEdges` MUST over-declare cross-node reads or a consumer outside the cone is served STALE on override. m4 — gen-bind error-strategy collisions now surface only when `config.warnings` is forced → den non-NixOS classes (nixidy/colmena) must force warnings/assertions. m5 — classKey's function-sentinel erases closure arg-shape → defunctionalize parametric args to data before the keyed attr. **Consciously-accepted documented NITs** (not fixed): name-only `why` provenance, schedule `readsAttrs` typo-filter, purity `#`-in-string assumption. **Ecosystem follow-ups:** purity-scanner holes (`#`-in-string + non-leading-`lib`-arg, all libs); gen-scope `resolveNode` unconditional `children` read (den always declares children, so den-safe).

**LOAD-BEARING DECISIONS (DP1-DP6, beyond D1-D14; all HELD in the shipped impl):**
- **DP1** two-stratum labeling = hybrid-B: kind-derived (`{nta,inherited}`→structural, `{cascade,reference,circular}`→resolution); `synthesized` carries explicit `stratum` (default structural, over-declare-safe; `terminal`=sink exempt). gen-resolve owns the CHECK, den owns the LABEL. Closes the hole where structural `imports` reads resolution `resolved-aspects` (van Antwerpen §4.3).
- **DP2** thin `materialize` (forces `output-modules`) + `terminalBind`(=`gen-bind.wrapAll`→.all); binding assembly stays den-side.
- **DP3/DP6** v1 `override`/`warmResolve` = **topological reverse cone** (`gen-graph.dependentsOf`) for `isClean`, NOT `gen-rebuild.affectedSet`/`needsEval`. **FLEET-GROUNDED** (hola, user-directed): exact-AFFECTED hash-detection = 2× the dominant single-thread-bound spine cost intra-eval (E3c NO-GO shape) + only pays cross-eval; cone-restriction base-dominated (hola S2); class-sharing is the fleet lever (Plane-2a 59.7%). Cone = O(|cone|) = design §9's own bound.
- **DP4** `builtCtx` = LAZY unforced `ResolveCtx` field (deferred cross-eval hook); `trace.hash=null` v1 → den's CIRCULAR node graph cold-resolves (gen-rebuild eager cycle-check never trips). **D11 RESCOPED** (design §9+D11 AMENDED 2026-06-30): `needsEval` = cross-INVOCATION reuse gate, not v1 intra-eval `isClean`.
- **DP5** evalModules-equivalence oracle at the TERMINAL (materialized modules vs `lib.evalModules`), NOT the cascade (CSS-last-wins `foldLayersTraced`, deliberately ≠ nixpkgs priority). nixpkgs in `ci/` only.
- **classKey** ships v1 but is a CONSERVATIVE narrowing key (hola E3c-C1): sound reuse needs def-disjoint ∧ fixpoint-closed + a byte-identity (drvPath) gate; contract carries the caveat. `warmResolve` takes `{ edits }` map (design §6 `{changedIds}` can't carry payload in pure eval).

**PRE-DEN-HOAG ROADMAP (current, 2026-07-02): `gen-specs/2026-07-02-pre-den-hoag-roadmap.md`** — supersedes the parallel-paths doc; sequences W0 cleanups / W1 beyond-parity spike / W2 resolve.nix-collision / **W3 pure substrate BYTE-MODE (~1-2 sessions, RECOMMENDED do-first: Korora→evalModuleTree byte-mode→re-host aspects+schema→byte-parity on today's den = zero migration surface for den-hoag)** / W4 readiness residuals (incl #10 pipe-combine now settled by the semilattice-confluence result) / W5 parity slice. The structural/identity FLEET-DEDUP arc is DEFERRED (hola axis, G6 measure-first), NOT pre-work. **NEXT (two parallel paths, older roadmap `gen-specs/2026-07-01-parallel-paths-den-hoag-and-pure-gen.md`, now superseded):** **Path A = CRITICAL = den→den-hoag refactor** — start with the den parity slice (resolve one real structural cone through gen-resolve, diff vs den's intact `materializeUnified` = the parity oracle). **Path B = supporting/parallel = Phase 1 purity** (re-host gen-aspects+gen-schema, Korora + `evalModuleTree` → 10 pure libs; NOT a den-hoag blocker). **den-check 2026-07-01 (verified vs den origin/main):** parity anchor `materializeUnified` CONFIRMED intact in main (#563) → Path A actionable; BUT the hola fleet-sharing *lever* gen-resolve's value points at is **PoC/UNMERGED** (den `feat/s1-per-sid-hostconfig`+`feat/s2-pipe-reads` = `deadbugs/` probes, Plane-2a = gist) → gen-resolve delivers the class KEY, NOT realized fleet sharing (README guardrail softened @70dc4e1); AND Path A's target `nix/lib/aspects/fx/resolve.nix` COLLIDES with the unmerged hola S1 rewrite (~326-line diff) — decide subsume-vs-coordinate before the full swap. **BEYOND-PARITY analysis DONE 2026-07-01 (2 agent passes: spec digest + nix-config harvest), spike DEFERRED to a fresh session:** den-hoag isn't 1:1 parity — it must make relationship/edge/projection patterns (claim/provide cascade, network fabric, host+user projections) TRIVIAL to author. **FINDING = NO new gen library** (substrate sufficient) + at most ONE **deferred** gen-resolve extension (post-resolution `forward` stratum for tier-2 forward adapters — no consumer yet, r2 defers it, keep the two-stratum THROW). The real work is **den-side framework features** dominated by a **k8s-workload archetype** (den classes emit NixOS/home-manager, NOT k8s resource sets; ~23×500-line hand-assembled apps → ~23×30) + reciprocal/provider-push claim + inject-into-workload + typed-collection-with-fold + baseline-edge-emission. Key clarifications: claim cascade = plain downward FOLD not recursive-neededBy (category error); den-hoag has **TWO edge graphs** (gen-resolve attribute-dep DAG vs den/nix-effects delivery `(S,T,P,M)` DAG — DON'T conflate); one gen-adjacent open-Q = k8s resource-set delivery via terminal vs den binding. Immediate wins (no spike): DELETE dead `nix-config/modules/den/scope-engine/settings.nix` (147 lines, 0 consumers); collapse `acl.nix` triple-gate to `sel.groupsClosure`. Full detail: `gen-specs/2026-07-01-beyond-parity-analysis-report.md` (findings) + `2026-07-01-den-hoag-beyond-parity-features.md` (spike seed) + `2026-07-01-parallel-paths-den-hoag-and-pure-gen.md`. Resume seed: `gen-specs/gen-resolve/RESUME-gen-resolve-phase0.md`. Full ecosystem/purity history below (settled).
## ═══ (settled history follows) ═══

**Charter:** owns the attribute-evaluation SCHEDULE — the *static* schedule (attribute-dependency graph + Vogt well-definedness gate + two-stratum partition assert) + the cold/warm fold into `gen-scope.eval` + the intra-eval override chain. Delegates everything else (gen-scope=resolution/warm-eval, gen-graph=topology, gen-rebuild=AFFECTED/cutoff, gen-algebra=`record.foldLayersTraced`, gen-bind=terminal wrap, gen-aspects=grammar/flat-registry=scope nodes).

**Decided:** gen-scope-HOSTED, not a fresh closure resolver (D1). **Intra-eval incremental ONLY** (Reps/Acar warm reuse, pure); cross-edit DEFERRED to gen-rebuild/Adapton-over-gen-scope = the [[project_hola]] fleet plane (D10). Static schedule owned / runtime schedule = demand (Nix laziness = Mokhov §4.1) delegated (D3). attributes consumer-supplied/open via `//` (D4). 14 decisions D1-D14 + 4 open research gates in the spec.

**Theory (CLEAN-ROOM — adios NEVER in the spec):** Knuth 1968 / Vogt 1989 / Hedin 2000 / Hedin&Magnusson 2003 / Néron 2015 (D>I>P) / van Antwerpen 2016 Statix / Reps-Teitelbaum-Demers 1983 / Acar 2002,2006 / Mokhov 2017,2018 / Sloane 2009 / Palmer 2024 **Lemma 5.12** (not Theorem — matches gen-derive REFERENCE+summary) / Lorenzen 2025 / Reynolds 1972.

**gen-derive hierarchy (KEY decision):** loop ⊥ step are orthogonal dimensions (all 4 quadrants occur in den attrs). gen-resolve owns the convergence **LOOP** (circular-attribute Kleene ascent); gen-derive = sibling dispatch **STEP** — **NOT a gen-resolve dependency, no edge either way**; den marries them inside one circular attribute (`resolved-aspects ⇄ policy-effects`). gen-derive was the least-principled gen lib (built loosely to compose libs for demos). **gen-derive REFACTOR + RENAME → gen-dispatch: SHIPPED + PUBLISHED 2026-07-01 (ultracode workflow).** Spike PASSED (byte-identical `gen-derive.fixpoint` == `gen-scope.circular ∘ gen-derive.dispatch`, direct + full-stack, 2 convergence shapes incl the fired-grows-on-converging-pass kill-criterion edge; secondary: `topoSort`/`entry*`==`gen-graph.condensation` reverse-bottomUp). Then a Workflow (map→design→3-lens adversarial verify, 0 blockers) produced the plan (papers `gen-specs/gen-derive/2026-07-01-gen-derive-refactor-plan.md`), executed: **loop=gen-resolve (circular Kleene ascent), step=gen-dispatch (dispatch), ordering=gen-graph (phaseOrder)**. LANDED: **gen-graph** `order.nix` = `entry*`+`phaseOrder` over condensation (reverse-bottomUp; self-loop+non-singleton-SCC throw), pushed `3f57be8`. **gen-derive→gen-dispatch** (github repo RENAMED via `gh repo rename`, redirect live; local dir kept `~/Documents/repos/gen-derive`): `dispatch` takes pre-ordered `phaseOrder` (no internal toposort); `dag.nix`+`fixpoint.nix` DELETED; new `dispatchStep`/`dispatchInit` (driver-agnostic merge fold, prelude-only) pair the step with any loop; 54 tests/10 suites; pushed `ad633a1`. **gen hub** rewired (input+key `derive`→`dispatch`, lock bumped), `mkGenLibs.dispatch` (11 ops), pushed `82d5922`. **sql-schema demo** migrated (loop→gen-scope.circular, order→gen-graph.phaseOrder, rules declare `phase` — required by multi-phase dispatch; the old demo relied on a May-28 gen-derive predating the strict phase-check), **oracle 167/167 byte-identical vs PUBLISHED revs**, pushed gen-scope `1bff817`. Untouched: gen-resolve lib, den, nix-config, nest-traits (nest-traits pins old gen-graph __functor API — do NOT bump). **Spike is a point-in-time proof (baseline needs the now-deleted fixpoint) → kept LOCAL uncommitted at `gen-resolve/spike/gen-derive-loop-step/`; permanent regression = the sql-schema convergence suite.** REMAINING (finish): papers REFERENCE (rename `gen-specs/gen-derive`→`gen-dispatch`, re-charter; gen-resolve REFERENCE gains Sloane 2010 §2.2 loop citations) — UNCOMMITTED, user's call. den marries loop+step inside one circular attr (`resolved-aspects ⇄ policy-effects`) — future den-hoag work (mkDispatchCircular helper deferred there).

**Ecosystem:** den = consumer (`materializeUnified` → a gen-resolve call; den supplies the 12 HOAG attrs, gen-resolve doesn't ship them); hola fleet plane sits ABOVE (host-class key = aspect-include-set = `classKey`, must digest resolved arg-shape not just names — D8). adios (adisbladis) = dev-time **systems reference ONLY**; our model is higher-order + full scope-graph (D>I>P), NOT adios's degenerate single-edge closure. See [[project_hoag_architecture]], [[project_den_hoag_readiness]], [[project_gen_package]], [[reference_gen_docs]].

**Locations:** `~/Documents/papers/den-architecture/gen-specs/gen-resolve/{2026-06-26-gen-resolve-design.md, 2026-06-26-gen-derive-refactor-spike.md}`. Spec independently verified (delegation APIs all real via grep; clean-room clean; sections 1-13; verifier-confirmed fixes applied).

**Open / next:** gen-bind boundary kept as terminal dependency (`wrapAll` is gen-resolve's own terminal op, defensibly ≠ gen-derive's mid-eval step — could still push den-side). NOTHING committed (papers commits = user's call). NEXT = write plan + ship gen-resolve, then run the gen-derive spike.

**Process caveat (durable):** the Workflow `args` global does NOT populate — it renders `"undefined"` in agent prompts. **Inline absolute paths as string literals in workflow scripts; never rely on the `args` global.** This bug caused a sibling-spec corruption (a reviewer wandered out of the target file, the fixer edited the wrong spec); recovered byte-exact from the transcript. Also: scope review/fix agents to a single target path. See [[feedback_gen_lib_docs]] for the lib-docs diligence (REFERENCE + tests cite THEORY) gen-resolve will need on implementation.

**Deferred deliverable — gen-aspects doc-update pass.** When gen-resolve ships, update gen-aspects README + REFERENCE to name gen-resolve as THE canonical pipeline/evaluator (deliberately left OUT of gen-aspects docs until the lib exists — user 2026-06-26). The neededBy overstatement is already refined in gen-aspects README (it's a consumer/den predicate-based reverse-reference, NOT a core edge symmetric with includes).

**⚠ COST RECALIBRATION (2026-07-02) — READ FIRST: the pure-gen module system / Phase-1 re-host is ~1-2 SESSIONS (≈2 days), NOT the "weeks-months" this section repeatedly says below.** The stale estimate was CATEGORY-anchoring ("a custom type + module system sounds huge"); the DELIVERED SHAPE is a Korora vendor (~800-LOC drop-in for the checking half) + a ~7-item `evalModuleTree` merge primitive + a gen-schema registry PROTOCOL-SWAP (collection logic is already pure Nix riding `deferredModule.merge(loc,defs)`; the port swaps the provider to gen-resolve, pure logic untouched — NOT a duration-dominant rewrite), TDD against the evalModules-equivalence oracle, with adios/Korora/zen/nixpkgs-lib as references. Peer-effort proof: gen-resolve (HOAG RAG evaluator over 10+ papers, 58 tests), gen-rebuild (Mokhov, 211 tests), hola (byte-identical `evalModules` ownership) EACH shipped in ~2 days. Only real risk axis = external-oracle SURFACE (7-item may prove 8-9 once den's live usage hits it → maybe +½ session), NOT duration. See [[feedback_estimate_delivered_shape]]. (All inline "weeks-months" below is superseded by this note.)

**⧉ NEW DESIGN ARC (2026-07-02) — structural equivalence + identity-keyed pre-eval dedup.** Composition-plane correctness bar EVOLVED byte-identical → **structural equivalence** (coarsest observational congruence, Reynolds) → unlocks a **confluent merge** → makes a **pre-eval intensional identity key** a congruence → **hash-cons/dedupe the merge graph BEFORE eval** + share resolved sub-cones cross-host (the fleet plane). Byte-identity KEPT only as dev/cut-over conformance oracle + NixOS terminal contract; non-NixOS (k8s archetype) has no byte oracle → structural only. Palmer intension + `itsInspect` wall (theory-audit A1) sidestepped by **defunctionalizing args to data (m5)** → Merkle key `id(n)=H(kind,name,argData,{id(dep):dep∈reads(n)})` over the STATIC scope graph (pre-eval computable; cycles via gen-graph.condensation). `id` = pre-eval PREDICT dual of v1 `classKey` (post-eval CONFIRM). DECISIVE gate = key-cost ≪ node-cost (hola E3c measured ~2×). Falsifiable spike (intra-host = ∆-Nets Rung 2 premise + Rung 4 hoist-by-identity; cross-host arm NEW). Full spec: `gen-specs/gen-resolve/2026-07-02-structural-identity-dedup-spike.md` (Rev 2, theory-discharged). **ADVERSARIAL REVIEW DONE 2026-07-02** (ultracode workflow wji8lny7r, 9 reviewers × full-paper reads, 49 findings upheld / 8 refuted; report `…-REVIEW.md`) → spec CORRECTED. Load-bearing fixes now IN the spec: (1) Merkle key was UNSOUND — flat id-multiset drops D<I<P specificity → false merge; fixed to `sortedMultiset{(labelSeq,rank,id(d))}`. (2) "pre-eval" over-reached — split declared-literal imports (pre-eval reads) vs config-computed/NTA (G2 dynamic tail; Vogt is a counterexample not support). (3) NEW decisive gate **G6 = merge-layer must be a material FRACTION of fleet-total cost** (dominant cost = N evalModules fixpoints per GENEROUS-BUILDS §6 wall-1 / "cortex 36s=94% derivation-construction") — **MEASURE G6 FIRST, it can kill the whole arc cheapest**. (4) confluence re-grounded on Datafun bounded-join-SEMILATTICE (comm+assoc+idempotent → order-independence AND circular-strata least-fixpoint via Lemma 4) + Radul pattern; foldLayersTraced downgraded to "must satisfy the discipline" (last-wins is non-commutative; a++b non-idempotent). (5) CITATION fixes: ≈ₛ was miscited to Reynolds (→ Morris1968/Plotkin/Pitts); ∆-Nets DEMOTED to foil-only ("interior sharing = hash-consing" = the killed IMPACT #13 overclaim; use Wadsworth1971 DAG-sharing + Lévy1978 + Barendregt1987); Lorenzen2025 added as the pre-eval-inspect keystone; Adapton promoted to first-class intra-eval precedent; Reps/Acar are post-eval → classKey not id; static schedule is Kastens1980 not Knuth1968; defunctionalized-data key soundness = Reynolds not Palmer (Palmer §6.1 cross-module dedup is his OPEN question). NEXT = run spike in order: measure G6/H4 (fleet-total split) → Fleet-Sharing-Net observable (Rung 0→1, ~50 LOC) → defunctionalize one heavy aspect + Merkle-key + assert id-collision⟹≈ₛ (H2 must try an order-swapped/ambiguous read). Data-quality: reynolds-1972 full text PULLED 2026-07-02 → H-12 (≈ₛ miscite) + M-2 (defunctionalization anchor) VERIFIED against primary text (0 occurrences of observational/contextual/congruence/equivalence in the whole paper; defunctionalizes FUNVAL→ENV→CONT). Reynolds citations in the spec now primary-text-grounded.

**END GOAL — pure-gen module system (Vic's aspiration; the ORIGIN of this whole journey).** The real aim: a pure-gen module system (à la adios/zen) with NO nixpkgs-module-system dependency — "pure lib, no evalModules" like adios. **CORRECTED FINDING (audit 2026-06-26 — the earlier "one cut / tether isolated to gen-aspects / gen-schema=Korora-equivalent" was WRONG; full audit at gen-specs/gen-prelude/2026-06-26-gen-ecosystem-purity-audit.md):** the lib.types/evalModules tether spans **4 of 10 libs** — gen-aspects (grammar) + gen-schema (registry) DEEP; gen-vars + gen-algebra SPLIT (pure/ clean, module/ tethered). **gen-bind CORRECTED to PURE-with-vendoring** (audit first mis-verdicted it blocked; its setFunctionArgs/setDefaultModuleLocation are module-CONVENTION helpers = AWARE not DEPENDENT, vendor ~6 LOC gen-bind-local; production-bound, remediation note gen-specs/gen-bind/2026-06-26-purity-remediation.md w/ evalModules equivalence-test gate). **gen-schema is NOT the Korora-equivalent — it IS lib.types + evalModules (entry-type.nix:223).** PURE substrate = gen-graph/select/scope/derive/rebuild/**gen-bind** (+gen-algebra/pure), decouple via ~150-LOC vendored **gen-prelude** (CHEAP, hours; builtins cover most, ~18 genuinely-vendored fns). Type/grammar/registry layer (~4 libs) needs a **VENDORED KORORA** type system (~1-2 sessions/≈2 days — NOT weeks-months; see COST RECALIBRATION note + [[feedback_estimate_delivered_shape]]) — gen-schema cannot fill it. adios→gen map: Korora→**vendored Korora (NOT gen-schema)** · loadModule/loadTree→gen-aspects grammar (re-host) · inputs+genericClosure→gen-scope+gen-graph (BETTER: Néron D>I>P, not single-edge) · evalModuleTree+override→gen-resolve · mergeOptionsUnchecked→gen-algebra foldLayers · dispatch→gen-derive · binding→gen-bind. nixpkgs re-enters ONLY at the optional terminal (gen-bind→evalModules, one eval/host, NixOS targets only). UNLOCKS: nixpkgs-independence for composition (escapes hola's immovable //-storm/merge floor — that floor bound only compat-PRESERVING frameworks; pure-gen SHEDS nixpkgs content for composition = the path [[project_hola]] DECLINED); native intra-eval incremental (gen-rebuild); cross-host fleet eval-sharing (the hola fleet plane); a module system for non-NixOS domains; substrate-convergence with [[project_zen_vic]] (zen proved 3-10× intra-eval but has NO cross-scope sharing — pure-gen+gen-resolve generalizes it). PATH: **Phase 0** gen-resolve (eval engine; grammar still on lib.types here) → **Phase 0.5** gen-prelude pure-substrate decouple (CHEAP, hours; gen-specs/gen-prelude/) → **Phase 1 KEYSTONE (~1-2 sessions/≈2 days — NOT weeks-months; see COST RECALIBRATION note + [[feedback_estimate_delivered_shape]])** vendor Korora + re-host gen-aspects grammar onto it **BYPASSING gen-schema** (submodule=nested registry, deferredModule=lazy constructor; merge adios-SIMPLE, NOT nixpkgs lib.types; pure-DEN additionally needs gen-schema's registry engine re-hosted = dominant cost since den entities ARE gen-schema registries) → **Phase 2** terminal bridge (gen-bind→evalModules, opt-in per target) → **Phase 3** zen/adios-scale pure-gen demo + fleet-sharing demo (the artifact for Vic). CAVEAT: the pure composition plane CANNOT directly consume nixpkgs NixOS modules in-composition — they are OUTPUT (deferredModule class content) handed to the terminal; adios accepts this same trade.

**KORORA DECISION 2026-07-02: BUILD `gen-types`, do NOT vendor Korora.** Korora is **LGPL-3** (NOT MIT — earlier note/spec was WRONG; whole gen ecosystem is MIT → vendoring+modifying = copyleft contamination of the type layer) + ~570 LOC of zero-novelty standard structural typing (verify:v→null|err + builtins.is* wrappers + obvious poly combinators) + **gen-schema already owns the checking pieces** (refined.nix/validate.nix are 0 lib.types refs = already pure; strict.nix has 2). So build a clean-room MIT `gen-types` as a **gen-schema `lib/types/` component** (leaf/poly checkers + fold in existing refined/validate/strict), graduate to standalone later only if warranted; clean-room from gen-schema + papers (Leijen/Findler/Chitil/Rondon/Palmer), NOT transcribed. entry-type.nix's lib.types/evalModules is the MERGE engine (→ evalModuleTree), a separate concern. Korora read only to confirm "nothing to vendor." (Below GO/NO-GO framing kept for history; superseded by this.)

**SUBSTRATE BUILD IN PROGRESS 2026-07-02 (module-system Track 1).** Two NEW libs approved + being built by parallel agents: **gen-types** (standalone LEAF lib `~/Documents/repos/gen-types`, MIT clean-room checker, gen-prelude-only, folds in refined/validate/strict) + **gen-merge** (NEW lib `~/Documents/repos/gen-merge` = the byte-mode module MERGE engine `evalModuleTree`; NOT inside gen-resolve — gen-resolve stays the schedule-only CONDUCTOR; docs conflating "gen-resolve's evalModuleTree" are WRONG — gen-merge = within-node def-merge, gen-resolve.foldLayersTraced = cross-node cascade, distinct layers). **Layering: gen-prelude → gen-types → gen-merge → {gen-schema, gen-aspects} → gen-resolve.** gen-types MUST be standalone (a merge engine below gen-schema consumes it → flake-input cycle if nested). B1 design spec `gen-specs/gen-resolve/2026-07-02-evalmoduletree-byte-mode-design.md` (7-item merge primitive + oracle). **PRIORITY-SUBSET WIN (grepped, not assumed):** den+gen use ONLY mkIf/mkDefault/mkForce/mkMerge — ZERO mkOverride/mkOrder/mkBefore/mkAfter → byte-mode = ONE min-priority-wins rule + mkMerge + mkIf, DROP the entire nixpkgs ORDER pass = closed surface, kills the oracle-completeness risk. Meta-plan `gen-specs/2026-07-02-pre-den-hoag-meta-plan.md`; native tasks A2(gen-types)/C1(gen-merge, ID#6)/C2/C3/C4.

**MILESTONE 2026-07-02: 3 of 4 substrate pieces DONE + PROVEN (all uncommitted, local, for review).** (1) **gen-types** — standalone leaf `~/Documents/repos/gen-types`, 105 tests, purity-teeth, gen-prelude-only. (2) **gen-merge** — `~/Documents/repos/gen-merge`, byte-mode merge engine, 46 tests incl a byte-identical-vs-nixpkgs oracle (+nullOr/either/oneOf fixtures); during C3 it fixed 2 REAL gen-merge bugs AT SOURCE = top-level `_module` drop (marker misclassification) + option-decl merge-by-replace (broke ref apply-override), both behind the oracle w/ regression tests. Priority = grepped one-rule subset; **nixpkgs collects defs in REVERSE module order — gen-merge reverses to match**. (3) **gen-schema RE-HOSTED (C3)** — worktree `c3-rehost` @ main 2b7c2d3: 398/398 corpus, lib/ nixpkgs-free, + a byte-parity oracle proving a den-shaped schema byte-identical through re-hosted-vs-nixpkgs incl **id_hash SHA identical** (361953da…, the strongest exactness proof); gen-schema now RE-EXPORTS `genSchema.{mkOption,types,evalModuleTree,mkMerge}` as the facade so den never touches nixpkgs. Corpus migration (93 files) done by a subagent it reviewed. **(4) gen-aspects RE-HOSTED (C2) DONE** — worktree `c2-rehost` @ main 87bf758 (includes A4): 110/110, lib/ nixpkgs-free, + a grammar parity oracle (flatten node-set + guard-fn wrap byte-identical to old nixpkgs grammar, w/ teeth). A4's `__guard` branch + `guardKey` + guard.nix + flatten `__guard`-leaf PRESERVED verbatim. **functionTo DROPPED** → the raw-guard-fn wrap is reproduced as a hand-built FUNCTOR `{__functor; __functionArgs; __isWrappedFn; name; meta}` — the `__functionArgs = ⋃ functionArgs(defs)` detail (nixpkgs setFunctionArgs) is load-bearing (a test checks `args={host=false;user=false}` + `lib.isFunction wrapper`). **ZERO gen-merge changes needed** (the C3-era `_module`/decl-merge source fixes already covered it). **(5) C4 WHOLE-STACK BYTE-PARITY DONE + GREEN** — `~/Documents/repos/gen/ci/rehost-byte-parity.nix` (validation only, den read-only): pure stack (gen-types+gen-merge/evalModuleTree+re-hosted gen-schema+re-hosted gen-aspects) == nixpkgs across 3 fixtures — schemaFleet (host kind + id_hash SHA), aspectTree (class content + guard wrap + flatten), integrated (schema-declared `priority` threaded into aspect instances = the C2×C3 composition) + a den-shaped realism sample, all byte-identical, both-evaluated + mutation-teeth. **⇒ TRACK 1 (pure-gen module system Phase 1) COMPLETE + byte-parity-proven end-to-end, ALL UNCOMMITTED for review.** Corpus finding: gen flake DEMOS are flake-parts TERMINAL-plane (import-tree + `lib.types.lines`), NOT composition-runnable → C4 validates the COMPOSITION plane (what the re-host changed) via the demos' SHAPES + the den sample; the terminal/output plane is unchanged nixpkgs. **REAL-DEN C4 battle-test DONE (`gen/ci/rehost-den-parity.nix`, den READ-ONLY):** den's ACTUAL `mkSchemaOption` registry config (extracted verbatim from `den/modules/options.nix`: 4 collections incl OR-merge isEntity/isolated, the `computed` isEntity, parent topology host←{user,home}, host/user/home import conf) + instances → BYTE-IDENTICAL through re-hosted-vs-original gen-schema incl id_hash SHA + teeth. **3 real-den findings (all consumer-migration, NOT correctness divergences):** (a) **den does NOT use gen-aspects** — it has its OWN native aspect layer (`nix/lib/aspects/`, `den.lib.aspects.types.aspectType`) → the C2 re-host has no real den consumer (validated by its own suite). (b) den imports gen-schema via `import gen-schema { inherit lib; }` (OLD sig) + via `fetchTarball` from `templates/ci/flake.lock` NOT a flake input → the C3 breaking-change is LIVE + full-den `--override-input` is INFEASIBLE. (c) **HEADLINE gen-merge GAP surfaced by real den: NO nested option-declaration support** — den declares `options.den.schema`/`options.den.hosts`/`options.den.classes` (2-level under `den.`); gen-merge is single-level (B1 scope, demand-driven) so `options.den.X = …` leaves the nested submodule unevaluated. Registry LOGIC is byte-parity at single-level; nesting is a den-framework wrapper (den's own evalModules drives it today). **Recommended NEXT gen-merge task = recursive option-path handling (moderate; TDD against the byte-identity oracle so C1-C4 stay green) — needed before den can drive config through evalModuleTree.** FOLLOW-ON (task #14): **flakeModule.nix BREAKING-change** = gen-schema's flake-parts `options.schema` is now a gen-merge type `lib.evalModules` CANNOT drive → nixpkgs/flake-parts consumers embedding `schema` break = the inherent pure-composition-plane trade (compose-plane ≠ nixpkgs-module input); decide deprecate-vs-evalModuleTree-entry at den-migration. + gen-types dedup deferred (gen-schema's refined/validate/strict copies aren't clean drop-ins). + publish-ordering: **github:sini/gen-types@ad180da + github:sini/gen-merge PUBLISHED 2026-07-02** (leaf-first; gen-merge locks+evals vs published gen-types; gen-prelude/gen-algebra already pub). gen-schema/gen-aspects RE-HOSTS **PUBLISHED as REPLACEMENT 2026-07-02** (OQ1 owner call): the pure re-host is now `.lib` (no legacy). Published revs: **gen-merge `fa5d5cc`** (#16 nested option paths + #20 path-leaf), **gen-schema `39d3d5d`**, **gen-aspects `64c3c25`** (gen-schema re-locked→github), **gen hub `af09165`** (`mkGenLibs` now exposes `merge`+`types`, resolves all 12 libs). Byte-parity incl **id_hash SHA** independently re-verified (`rehost-byte-parity`+`rehost-den-parity` all-true). Impl plan `gen-specs/2026-07-02-cross-compat-module-expansions-plan.md` (+`.md.tasks.json`, 13 tasks): **CROSS-COMPAT CORE SHIPPED + PUBLIC.** **gen-flake PUBLISHED** `github:sini/gen-flake 2d47478` (NEW repo — the value-injection nixpkgs boundary: `.lib`=compose/injectArgs/mkSystems + `.flakeModules.default`; compose PURELY→inject resolved VALUES into `_module.args`→build systems at a terminal via gen-bind.wrapAll→nixosSystem; **invariant proven end-to-end**: gen type rides as inert DATA in `_module.args`, never enters a consumer options tree). gen hub `6f29f76` (`mkGenLibs` resolves 13 libs incl merge/types/flake). All 3 ecosystem demos migrated to value-injection + published as the reference pattern (gen-schema `ef4d012`, gen-aspects `7dcdd3f`, gen-vars `42f2e71` multi-target nixos+terranix). import-tree fork = `denful/import-tree/a164a12` (`.addPath dir).files` = bare path list). FOLLOW-ONS: **T9 DONE** — den-hoag prereq PROVEN: **config-thunk deferral preserved BYTE-IDENTICALLY on gen-merge's byte-mode engine** (gen-merge main `c960e5c`, `ci/tests/deferral.nix` permanent regression; den `__configThunk` markers ride unforced through composition + mid-pipeline route/forward, force byte-identically at terminal reading config/osConfig; enabler = gen-merge lazyAttrsOf/raw passthrough + `isProperty` non-forcing → **den-hoag CAN ride gen-merge for config-thunk deferral**). **T10 docs DONE** (papers REFERENCEs gen-merge/gen-flake/gen-types + hub docs pushed `8bdd013`). **T11 C3 DONE** (flakeModule superseded by gen-flake `e706a09`; gen-types dedup deferred-documented; merged worktrees cleaned). **T12 DONE** (gen hub `2ea13d5`): rehost byte-parity oracles refactored to pure functions on **pinned `github:nix-community/nixpkgs.lib`** (policy first application) + wired as PERMANENT gen-ci flake checks (all-true incl id_hash SHA + teeth), stale flag → live `parity-nested` assertion, c3/c2 worktrees removed. **T13 DONE** (audit: all gen-* ci RUNNER-only except the hub oracles; deleted 4 orphaned impure dev-scaffolding files — gen-schema `7c204e5`, gen-aspects `e68bf4a`). T3 gen-types rename CLOSED won't-do. **⇒ ALL 13 cross-compat tasks COMPLETE + PUBLIC** (gen-merge `c960e5c` · gen-schema `7c204e5` · gen-aspects `e68bf4a` · gen-flake `5dd3a41` · gen-vars `2cb0ff0` · gen hub `2ea13d5`; papers REFERENCEs uncommitted for owner). Full record: `gen-specs/2026-07-02-cross-compat-module-expansions-plan.md(.tasks.json)` + meta-plan §5. **NEXT DESIGN ARC (deferred, dedicated session): gen-flake v1 API redesign + adios cross-pollination** — gen-flake is a working PROOF, NOT a stable v1 (do not tag v1 yet); the redesign folds in the "best of both worlds" adios program: adios **performance** (Adapton diff-propagation → wire compose→gen-resolve `override`) + our **compatibility** (keep the byte-parity nixpkgs terminal — compose-vs-terminal split) + **improved observability** (surface provenance/trace/diff on compose/override). Measure-gated (G6 first), then observability, then v1 redesign, then incremental override. adios sys-dependence memoization = reference for the future den-hoag k8s (non-nixpkgs) terminal. Doc: `gen-specs/gen-flake/2026-07-02-v1-remaining-work-and-adios-cross-pollination.md`. **nixpkgs.lib = ECOSYSTEM POLICY** (owner): lib-only need→pinned `github:nix-community/nixpkgs.lib`; full nixpkgs only for pkgs/nixosSystem (runners, gen-flake terminal); tracked as Task 12 (oracle regression, first application) + Task 13 (sweep). Deferred-work register in meta-plan §5. Downstream type-embedding consumers now break until value-injection migration (accepted D6 trade; demos=T8). **CROSS-COMPAT DESIGN 2026-07-02** (spec `gen-specs/2026-07-02-cross-compat-module-expansions-design.md`, brainstorm-approved, under adversarial review): owner target = QUERY resolved VALUES from nixpkgs = **VALUE-INJECTION, not type-driving** + structured options required. SOLUTION = **new gen-flake lib** (.lib+.flakeModule; compose-purely→inject-values→nixosSystem terminal = the ONE nixpkgs boundary; adios-flake-shaped) + gen-merge nested option-paths (#16) + path-modules (import-tree = denful/import-tree, NO fork) + gen-types rename (korora review: adios/korora accept the same trade — no type bridge). State tracker = meta-plan §5. Agent = evalmoduletree-design (built gen-merge+C3, will take C2).

**KORORA GO/NO-GO RESOLVED 2026-06-30 (audit §7 updated, file:line-verified) — Phase-1 keystone was MISLABELED.** Korora (`~/Documents/repos/adios/types/types.nix`, 573 LOC; `lib.nix`=its vendored utils) is a **verify-only** type system (`{name,verify,check}`, `verify:value→null|err`; primitives+option/listOf/attrsOf/union/struct/enum/tuple). **NO merge phase, no defs/loc, no priority (mkMerge/mkDefault), no submodule recursion, no evalModules.** Verdict: **GO but necessary-NOT-sufficient.** Korora vendors in an AFTERNOON + is a drop-in for the CHECKING half (all leaf/poly types these libs use map directly: str/int/bool/listOf/attrsOf/either→union/enum/nullOr→option/path/anything→any/strMatching/raw). **But it does NOT discharge the impurity** — the 3 impure libs use lib.types as the **MERGE ENGINE**, not a checker: gen-aspects/lib/types.nix:44 `aspectType=lib.types.mkOptionType{merge=loc:defs:…}` (custom merge over collected defs, calls mkMerge + submodule.merge); gen-schema/lib/entry-type.nix:223 RUNS `lib.evalModules`. Engine surface: mkOptionType-custom-merge + submodule×10 + lazyAttrsOf×9 + deferredModule×4 + functionTo×1 + evalModules×1 + mkOption×~25. **THE REAL GATE = gen-resolve's `evalModuleTree` merge engine (spec-only), NOT Korora.** Korora + Phase-0.5 Bucket-A decouple can proceed in parallel TODAY; gen-aspects/gen-schema purity is gated on gen-resolve existing + passing the evalModules-equivalence oracle. **Current verified purity state (2026-06-30): tether now 3 libs NOT 4** — gen-algebra FULLY PURE (module tier relocated→gen-schema @aaffd3f), gen-bind/select/derive MIGRATED+PUBLISHED onto gen-prelude. STILL IMPURE: gen-aspects (grammar), gen-schema (registry+evalModules), gen-vars/module-only. PURE substrate = 8 libs. Bucket A (cheap decouple of already-pure-in-substance gen-graph/scope/rebuild/gen-vars-pure-tiers off self-pinned nixpkgs.lib onto gen-prelude) still pending = hours.

**FOOTPRINT-REDUCTION PASS 2026-06-30 (audit §7 "Footprint-reduction pass" subsection):** (A) ISOLATE WIN — all 3 impure libs' merge-engine dependency collapses to ONE `evalModuleTree`-shaped primitive = **gen-resolve Phase 0 spec is bounded to 7 items**: typed-options+defaults, freeformType(lazyAttrsOf/attrsOf), per-key name/_module.args binding, self-referential `config` fixpoint (gen-aspects types.nix:166 + gen-schema instance.nix:50 both `config._module.args.X=config` — siblings cross-ref; NATIVELY gen-resolve's D>I>P scope-graph, the reason it beats single-edge closure), imports merging, the `(loc,defs)` custom-merge escape hatch, deferredModule+functionTo. ONE interface, not 3 integrations. (B) REDUCE — delete 2 bespoke mkOptionTypes BEFORE gen-resolve via Korora: gen-schema/lib/strict.nix(throw-on-unknown)→Korora struct `{unknown=false}`, refined.nix(predicate-in-__schema)→Korora `typedef'` verify; leaf checks→Korora verify. (C) CONSOLIDATE 3 engine-owners→2: gen-vars/module/registry.nix HAND-ROLLS a registry gen-schema already provides + gen-vars does NOT dep gen-schema (inputs=nixpkgs+gen-graph only) → re-express on gen-schema, gen-vars becomes a consumer, drops direct lib.types. **DECISION PENDING (dep-graph change, user's call).** (D) gen-schema already ~411/1789 LOC pure; entry-type collection-merge logic is ALREADY pure Nix riding deferredModule.merge(loc,defs)+evalModules → port = swap protocol provider lib→gen-resolve, pure logic untouched. NET: gen-resolve Phase 0 = the 7-item primitive for 2 clients; Korora discharges checking half + 2 deletions first.

**BUCKET-A PROMOTION REVIEW 2026-06-30 (3 parallel read-only agents, cross-checked vs gen-prelude/lib/default.nix). UNANIMOUS: gen-graph/gen-scope/gen-rebuild all PROMOTABLE to prelude-only, gen-prelude needs ZERO additions** (toposort vendor already closed the gap). Distinct lib.fns: graph 9 / scope 11 / rebuild 14; union of 19 all already exported (genAttrs/unique/mapAttrs/concatMap/fix/filterAttrs/max/listToAttrs/foldl'/optional/optionalAttrs/removePrefix/hasPrefix/tail/init/head/filter/any/all). graph genericClosure=builtins; scope fix=_eval HOAG memoization (prelude fix identical); scope uses NO recursiveUpdate/attrByPath; rebuild `with lib` was a comment false-positive. **EXECUTION: (1) ordering — rebuild's flake BUILDS graph/scope from nixpkgs.lib as inputs, so to drop nixpkgs from rebuild ENTIRELY promote graph+scope FIRST; publish order prelude→graph/scope→rebuild. (2) the ONE non-mechanical spot per lib = repo-root NON-flake default.nix impure `lib ? (import <nixpkgs>{}).lib` fallback (graph+scope) — agents said "no precedent" but gen-bind's standalone default.nix ALREADY derives prelude from its flake.lock via fetchTree{narHash}, reuse it. (3) recipe = convention-strict `{lib}`→`{prelude}` (matches shipped gen-bind/derive) vs minimal-diff (keep `{lib}`, pass lib=prelude in flake). (4) leave ci/+examples on nixpkgs (separate flakes, test-only fns findFirstIndex/splitString/drop/take/recursiveUpdate/attrByPath).** Audit §7 Bucket A updated with full table+findings. Bucket A = pure rewiring, hours, NO vendoring — cheaper than first stated.

**BUCKET A + BARE-ENTRY CONVENTION SWEEP SHIPPED 2026-06-30 (all pushed github:sini).** (1) gen-graph/gen-scope/gen-rebuild migrated to gen-prelude, Class C/D→B, nixpkgs.lib GONE from each (graph fe792d9, scope 2472dd6, rebuild 3c10e15; rebuild also dropped its lone `__functor`). (2) gen-derive FIX-1 (prelude feed via `gen-prelude.lib` not store-path re-import). (3) **CONVENTION: "a file is a function IFF it has dependencies"** — dep-free = BARE VALUE (`import ./x`, NOT `{ }:`/`import ./x { }`); applied to all dep-free submodules (graph traverse.nix, scope graph.nix) AND all 3 Class-A lib ENTRIES (gen-prelude 9e3f4c9, gen-select b92c344, gen-algebra 601a304 — entries now bare; every `import "${gen-prelude}/lib" { }`/`"${gen-select}/lib" { }` consumer dropped the `{ }` across ci/flakes + standalone fetchTree shims + repl.nix + 2 gen-select example flakes + READMEs; ecosystem-wide grep `/lib" { }` = EMPTY). (4) gen-algebra FIX-2/3/4: ci imports ../lib, canonical recursive purity.nix (superset forbidden), `outputs=_:`→`{...}:`; confirmed GENUINELY zero-dep (0 lib. refs). (5) gen hub c7ff00d: 7 locks bumped, mkGenLibs resolves all 9. **RF-1 resolved = (b) gen-algebra stays zero-dep** (sibling foundation to gen-prelude, neither depends on other). **RF-2 = aggregation idiom content-driven** (//-merge iff all-public-flat; curated iff hides/namespaces) — codified, no churn. Convention spec `gen-specs/2026-06-26-gen-lib-root-convention.md` UPDATED (items 8 function⟺deps / 9 aggregation / 10 purity-invariant + Class table A=bare,B+=graph/scope/rebuild,C=empty + warts resolved) — UNCOMMITTED (papers=user's call). Style-review (7 pure libs) drove it; gen-rebuild excluded from review (in-flight) but aligned by construction. NET: 8 pure libs uniform — bare-or-prelude entries, function⟺deps, canonical purity, no __functor; only gen-schema+gen-aspects remain nixpkgs-tethered (the gen-resolve/Korora project).

## SESSION HANDOFF (2026-06-26) — resume in fresh session
**COMMITTED** to papers archive `~/Documents/papers/den-architecture` @ **`25f2fa3`** (main, 4 files, 914 insertions), all in `gen-specs/gen-resolve/`:
1. `2026-06-26-gen-resolve-design.md` — the gen-resolve design spec (Phase 0; verifier-fixed: attr/readsAttrs, override edge-move guard, warmResolve single-engine, Palmer Lemma 5.12, CRAG dropped).
2. `2026-06-26-gen-derive-refactor-spike.md` — gen-derive loop⊥step refactor spike (DEFERRED post-ship).
3. `2026-06-26-pure-gen-module-system-phased-path.md` — the overarching pure-gen module system, phases 0-3 (Vic's end goal).
4. `2026-06-26-phase-1-grammar-rehost-notes.md` — gen-aspects grammar → gen-schema gap analysis.

**Uncommitted, separate repo:** gen-aspects README neededBy-row refinement is DONE but NOT committed in `~/Documents/repos/gen-aspects` (public repo; wants `nix develop -c just fmt`/treefmt before commit — leave for when that repo is next touched).

**Papers working tree (DO NOT touch — both are the user's strays, verified earlier):** `host-aspect-settings-guide.md` (modified, his pre-existing edit, workflow never touched it) + `specs/2026-06-26-pipe-broadcast-producer-class-config.md` (his PR #623 draft, restored byte-exact after a workflow fixer corrupted it).

**NEXT (in order):** (1) **Phase 0** — write the gen-resolve implementation **plan** (bite-sized TDD tasks) then build the lib; the design spec is the source of truth, D1-D14 + the 4 open research gates are stamped in it. (1.5) **Phase 0.5** — gen-prelude **SCAFFOLDED + PUBLISHED + WIRED 2026-06-26** (github:sini/gen-prelude @da654d0, PUBLIC, **zero-input flake** so consumers gain no transitive nixpkgs, 44 exports, **fidelity suite** all 18 utils == nixpkgs lib + boundaries, **CODE-REVIEWED + CI green** (nix flake check), nixfmt'd; wired into gen/ flake + mkGenLibs as `prelude`, gen@3b9f948). REMAINING: vendor `toposort` (currently a throw stub) + migrate the pure libs onto it — **gen-graph/select first** (trivial), then gen-scope/derive/rebuild/bind + gen-algebra/pure, each gated by its tests + the CI purity invariant. gen-bind also vendors its 2 module-convention helpers + an evalModules equivalence test. spec+audit at gen-specs/gen-prelude/. **→ gen-bind purity remediation DONE 2026-06-26 (FIRST lib actually migrated onto gen-prelude; recipe validated for the rest).** nix/lib now `{ prelude }` (genAttrs/optionalString→prelude, mapAttrs→builtins); 2 helpers vendored byte-verbatim from pinned nixpkgs in `nix/lib/module-convention.nix` (setFunctionArgs trivial.nix:1081, setDefaultModuleLocation modules.nix:611). flake.nix drops nixpkgs→adds gen-prelude (root lock = gen-prelude+root ONLY); standalone default.nix + ci/repl.nix derive prelude from flake.lock via `fetchTree{narHash}` (pure, no nixpkgs); ci/flake.nix keeps nixpkgs for the runner + the equivalence gate's real `lib.evalModules`. TWO new tests: `ci/tests/evalmodules-equivalence.nix` (4 cases: binding-inject / residual-args via lib.functionArgs / key-dedup / _file declarations — TDD oracle, teeth-proven by corrupting helpers) + `ci/tests/purity.nix` (§5 invariant: comment-stripped scan of nix/lib+flake.nix+default.nix for forbidden tokens — teeth-proven). 64/64 nix-unit, `nix flake check` ci+root green, treefmt clean. `gen-bind.lib` flake-output consumers (gen-aspects/gen-scope demos) UNAFFECTED. **CROSS-REPO LANDMINE: `gen/lib/mkGenLibs.nix:26` edited locally (`{inherit prelude;}`, verified vs LOCAL gen-bind) but gen pins OLD lib-based gen-bind → gen eval BREAKS until gen-bind PUBLISHED + gen's gen-bind lock bumped; land that edit TOGETHER. Nothing committed (user's call).** ALSO: gen-bind folded `nix/lib/`→`lib/` (git-tracked renames; all import paths + mkGenLibs/README/REFERENCE updated; 64/64 still green). **→ gen-select DONE 2026-06-26 (SECOND migrated; now ZERO-input, even cleaner than gen-bind — needs NO prelude). Decision: did NOT add gen-prelude; instead INLINED the one gen-algebra fn used (`intensionalEq = a:b: a.name==b.name`, Palmer §2.3) into constructors.nix + inlined `mkIntensional` (Palmer §2.2) into ci/tests/when.nix, since gen-select's `lib` param was 100% dead (audit-confirmed — zero `lib.*`).** Result: gen-select depends on NOTHING (root flake.lock = `[root]` only). Dropped nixpkgs+gen-algebra from flake.nix/default.nix/ci/flake.nix/ci/repl.nix; sub-modules (match/scope/registry/constructors) lost their dead `{lib}`/`{genAlgebra}` params; both examples (css/sql-where) dropped gen-algebra input (still use nixpkgs for their own lib + harness); added `ci/tests/purity.nix` (§5, also bans `genAlgebra`/`gen-algebra`). All 4 locks regenerated (examples via `--allow-dirty-locks` — they were already dirty-pinned to local gen-select path, NOT in main CI). 104/104 nix-unit (incl. the 4 `when` tests that were RED pre-change due to a stale gen-algebra `.pure`→`.lib` lock — inlining sidestepped it), `nix flake check` root+ci green, treefmt clean. mkGenLibs select line → `{ }` (same publish-gated landmine as gen-bind). NOTE: gen-algebra is mid-migration (`.pure`→`.lib` flake output + module-tier relocated to gen-schema; gen-algebra/lib is now flat+pure). **→ gen-prelude.toposort VENDORED 2026-06-26 (the keystone) + gen-derive DONE (THIRD migrated).** gen-prelude/lib: replaced the `throw` stub with verbatim nixpkgs `lib.lists.toposort` + its deps `listDfs`/`reverseList` (~55 LOC; also added `partition` builtin re-export listDfs needs); only `toposort` exported, helpers internal; 5 fidelity cases vs nixpkgs lib.toposort (chain/dag/single/empty/cycle) + 2 sanity, replaced the obsolete `toposort-stub-throws` test; gen-prelude 41/41, format clean. **CAVEAT: gen-prelude had NO committed ci/flake.lock — created one (`nix flake lock ./ci`).** gen-derive migration: `{lib,genAlgebra}`→`{prelude}` MECHANICAL `lib`→`prelude` swap (prelude re-exports ALL gen-derive uses: filter/all/foldl'/sort/mapAttrs builtins + filterAttrs/imap0/unique/toposort vendored); **gen-algebra dep was 100% DEAD** (rule.nix took it, never used it — has own inline isIntensional) → dropped, NO inlining in lib; compose.nix `{lib}`→`{...}` (dead); 6 tests used `genAlgebra.mkIntensional` for fixtures → shared `mkIntensional` (Palmer §2.2) via ci specialArgs (3 tests) + 3 had dead genAlgebra param dropped; flake.nix/default.nix/ci drop nixpkgs+gen-algebra→gen-prelude (default.nix+repl fetchTree-from-lock); ci keeps nixpkgs (runner) + gen-select input (adapter test, now zero-arg `{}`); added recursive `ci/tests/purity.nix` (walks core/+adapters/, bans nixpkgs/lib./genAlgebra). 69/69 nix-unit, root+ci `nix flake check` green, format clean. mkGenLibs.derive → `{inherit prelude;}`. **ALSO retrofitted gen-select's purity.nix to recurse** (it had silently skipped lib/adapters/). **CROSS-REPO PUBLISH ORDER (hard): gen-prelude(toposort) → gen-select(zero-input) → gen-derive. gen-derive's root+ci locks are DIRTY-PINNED to local /home/sini gen-prelude+gen-select working trees (file://, `--allow-dirty-locks`) so it evals green NOW; MUST `nix flake update gen-prelude gen-select` to re-pin github revs after publishing. mkGenLibs (gen repo) edits for bind/select/derive all pending publish + lock bump. Nothing committed.** gen-prelude.toposort vendor ALSO unblocks gen-vars (the other toposort consumer). **→ ALL PUBLISHED + WIRED 2026-06-27 (all prior cross-repo landmines RESOLVED — nothing pending).** Pushed to github:sini main in dep order: gen-prelude@4682b7e (toposort) → gen-select@1399f8f (purity-recurse retrofit; zero-dep migration was already @0960170) → gen-derive@075a217 (locks re-pinned dirty-local→published) → gen-bind@31e11e7 (was @b2bb0e7 = fold+prelude, +gen-prelude bump) → gen@d716cd3 (mkGenLibs wired bind`/lib`/select`{}`/derive`{prelude}` + flake.lock bumps all). gen mkGenLibs evals all 9 libs; every repo HEAD==origin, 0 uncommitted. THREE libs now pure-migrated (gen-bind/select/derive) + toposort keystone; REMAINING pure track = gen-scope, gen-rebuild, gen-graph, gen-vars (gen-vars now unblocked by toposort). (2) **Phase 1 keystone (~1-2 sessions/≈2 days — NOT weeks-months; see COST RECALIBRATION note + [[feedback_estimate_delivered_shape]])** — vendor Korora + re-host gen-aspects grammar onto it BYPASSING gen-schema (notes corrected). (3) gen-derive spike runs AFTER gen-resolve ships. (4) **gen-algebra/module → gen-schema relocation** — brief WRITTEN + committed (gen-specs/gen-algebra/2026-06-26-module-tier-relocation.md @ papers 2930162); EXECUTE in a NEW SESSION via dispatched agent. All 5 module/ exports (mkIdentityModule, mkStrictModule, validate.* [gen-schema already re-vendors via validate.nix], mkRefType [reconcile w/ gen-schema ref.nix, NOT dead — used in gen-schema demos]) → gen-schema (sole consumer, already impure); gen-algebra/default.nix drops module merge+moduleFallback → gen-algebra fully pure (lib.types-free). Agent MUST also: update local module docs, migrate ci/tests, sync REFERENCE.md+README in BOTH repos, sweep demos+update imports. Spans 2 repos (gen-algebra+gen-schema), one agent sequential. **Open:** gen-bind boundary (kept as gen-resolve terminal dependency — `wrapAll` is its own terminal op, defensibly ≠ gen-derive's mid-eval step; could still push den-side); lib naming (gen-resolve / the pure-gen system); whether `loadAspects` lives in gen-aspects-v2 or a new `gen-module` lib. Entry point for the fresh session = the 4 committed specs above.

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [gen-resolve library](project_gen_resolve.md) — pure-Nix RAG schedule-conductor (gen-scope-hosted, Class B); **v1 SHIPPED+PUBLISHED 2026-07-01** (@56209bb). ALSO holds the **pure-gen module system + cross-compat arc: SHIPPED+PUBLIC 2026-07-02** (gen-types/gen-merge/gen-flake; gen-schema/gen-aspects re-host REPLACEMENT byte-parity incl id_hash SHA; gen-flake value-injection boundary; config-thunk deferral proven; 13/13 tasks). SLICES 1+2 DONE 2026-07-05: trust docs public; A1 campaign gated (Arm-R 66.7%, spine ~98%); **gen-class v1 SHIPPED** (github:sini/gen-class, tier-2 kernel in gen-merge @2ad1099, ~5.8× spine gate in hub bench). NEXT = A2 gen-flake observability (RESUME-trust-release-a2.md) → A4/B3/B4/B5/A5 → den-hoag.

──────── archive-project_gen_schema_bump_nixconfig.md ────────
---
name: project_gen_schema_bump_nixconfig
description: nix-config gen-schema bump COMPLETE — 3 gen-merge/nixpkgs boundary fixes shipped; PR #175 merged, cortex byte-identical
metadata: 
  node_type: memory
  type: project
  originSessionId: 17a7ab56-6a61-4767-9aae-e5022c239ebb
---

Task: bump nix-config's gen-schema to latest (den-hoag-era enhancements). Started 2026-07-16. **DONE 2026-07-16** — nix-config main pins gen-schema `69dcbb1` (→ gen-merge `f7e3afb`) via PR #175 (commit 91b5fc71); cortex + blade toplevel drvPaths BYTE-IDENTICAL to prior pin. All 3 gen-merge/nixpkgs boundary divergences root-caused + fixed + rolled out. den ci 63→2 failures (2 remaining are PRE-EXISTING, see below).

**Root cause of the `den.schema._kindNames read-only, defined 2 times` error (SOLVED):** gen-schema HEAD re-hosted its registry off nixpkgs `lib.modules` onto gen-merge (pure-gen). den is inputless and resolves gen-schema via `inputs.gen-schema.lib or <ci-lock fallback>` — so den + nix-config share ONE gen-schema instance (no version skew; user's "den internal representation" hunch was wrong). The real bug: `options.den.schema` is declared inside NIXPKGS-evaluated modules (den `modules/options.nix`) but typed with a gen-merge submodule. nixpkgs `fixupOptionType` (modules.nix:1477) calls `type.substSubModules opt.options`, where `opt.options = map (setDefaultModuleLocation _file) type.getSubModules ++ res.options` (already contains the type's own base module, relocated). gen-merge's `substSubModules` did `submodule (mods ++ m)` — CONCAT — re-including the base → base module evaluated twice → readOnly `_kindNames` config emitted twice → throw. nixpkgs `submoduleWith` REPLACES (`modules = m`).

**Fix SHIPPED:** gen-merge `lib/types.nix` `substSubModules = m: submodule (if isList m then m else [ m ])` (replace not concat) + regression test `test-readonly-base-single-eval` in `ci/tests/nixpkgs-protocol.nix`. gen-merge `43c9a9d` pushed (178 tests). gen-schema bumped its gen-merge input → `3686182` pushed (405 tests). Both on origin/main. Local repos: gen-merge `~/Documents/repos/sini/gen-merge`, gen-schema `~/Documents/repos/gen-schema` (canonical, = remote HEAD; a stale dup at `~/Documents/repos/sini/gen-schema`).

gen-merge `43c9a9d` → gen-schema `3686182`. THREE gen-merge/nixpkgs boundary divergences total (gen-schema types consumed by nixpkgs-driven evalModules), surfacing one at a time as eval advances. #1 above SHIPPED. #2 SHIPPED. #3 = OPEN design call.

**Droid domino = divergence #2 (SHIPPED):** `attribute 'droid' missing` at den `host.nix:120` — `intoAttr`/`instantiate` default `{nixos;darwin;systemManager}.${config.class}` (no droid key). nix-config overrides for droid via `den.schema.host.imports = [ (mkIf (config.class=="droid") {...}) ]` (`batteries/nix-on-droid.nix:120`); forcing site = den `policies/fleet.nix:69` guard `hostCfg.intoAttr != []`. ROOT: gen-merge `dischargeProperties` (priority.nix) override branch RECURSED into `v.content` (`dischargeProperties v.content`), force-evaluating EVERY override-wrapped def incl. the LOSING 1500-priority default before `filterOverrides` could drop it. nixpkgs never descends into mkOverride content (its override case is the bare `[ def ]` fall-through). FIX: override branch = `[ { inherit (v) priority; value = v.content; } ]` (stamp priority, keep content lazy). gen-merge `b7e8797` pushed (179 tests, +test-throwing-optionDefault-not-forced-when-overridden in merge.nix). gen-schema bumped → `f3c0f35` pushed (405 tests). Cleared droid on cortex AND 8 of den's 63 ci failures.

**Divergence #3 = `config._module.args` unreadable (SHIPPED):** `attribute '_module' missing` at den `_types.nix:128` — `resolvedCtxModule` reads `config._module.args` to enumerate entity ctx (can't enumerate `...` fn args); gen-schema `mkInstanceType` (instance.nix:53) sets `config._module.args.${kind}=config`. ROOT: nixpkgs makes `config._module.args` readable INSIDE a module (module-visible config fixpoint carries `_module`) but STRIPS `_module` from the RETURNED `(evalModules).config`. gen-merge dropped `_module` from config entirely (modules.nix:990). FIX: split the two views — returned `config` stays `_module`-free (byte parity; oracle at oracle.nix:35 strips `_module`, tests unchanged), a new `moduleConfig` re-surfaces `_module.args` (args-only, guarded to when a module set one) as the config modules close over via `baseArgs.config` (~:888). gen-merge `f7e3afb` pushed (181 tests; +readable-inside-module +returned-config-has-no-module). NOTE: naive "re-inject `_module` on the returned config" is WRONG (breaks dozens of whole-config equality tests + non-serializable self-ref/freeformType `_module` contents) — the split is essential. gen-schema `69dcbb1` pushed (405 tests). Cleared 53 of 55 remaining den failures; has-aspect 42/42.

**Divergence #4 = identity reflection drops nixpkgs-str fields (SHIPPED):** `delivery-edges.test-topology-multi-system` failed — two `den.homes.{x86_64,aarch64}.ben` (same name, differ only by `system`) COLLAPSED to one id_hash (edge `count 13→9`, `collectedScopes` lost the intentional duplicate `home:ben`). ROOT: gen-schema `identity.nix` `isPrimitive` reflects id_hash over options whose `type.name ∈ ["string","int","bool"]` (gen-types names); den declares every entity option with nixpkgs `lib.types.str` (`strOpt`, type.name `"str"`) → str identity fields (incl. `system`) silently dropped → same-name entities collapse. FIX: add `"str"` to `primitiveTypeNames` (identity.nix) so nixpkgs- AND gen-types-typed options reflect identically. gen-schema `e6dbe8e` pushed (406 tests; +test-nixpkgs-str-field-reflected). BYTE-IDENTICAL for cortex (same-name-home collision is den-test-only; verified current main gives `lqcvfd41` under both 69dcbb1 and e6dbe8e — the earlier fddw00xx→lqcvfd41 shift was the concurrent ssh-agent-mux commit 82d0faff, NOT gen-schema). nix-config bumped to e6dbe8e via **PR #176 merged**. den ci → 1051/1052.

**Last failure = PRE-EXISTING (not from bump):** `delivery-edges.test-topology-fleet-pipe` fails on OLD committed gen-schema `4bd0f6eb` too (13/14) — den-author's separate issue on `fix/broadcast-home-pool-to-host`. ALSO: nix-config `slab` (droid) `nixOnDroidConfigurations` infinite-recurses on BOTH old and new gen-schema → pre-existing droid breakage, out of scope; cortex/blade unaffected.

**den working branch** (`fix/broadcast-home-pool-to-host`): its `templates/ci/flake.lock` gen-schema advanced to `69dcbb1` (uncommitted; user's own untracked `fix_*.py`/`diff2.patch` left alone). `just ci` = 989/1052 (3686182) → 997 (f3c0f35) → 1050/1052 (69dcbb1).

**rollout complete:** gen-merge `43c9a9d`→`b7e8797`→`f7e3afb` (pushed, 181 tests); gen-schema `3686182`→`f3c0f35`→`69dcbb1`→`e6dbe8e` (pushed, 406 tests); nix-config PR #175 + #176 MERGED to main (main pins gen-schema `e6dbe8e`, cortex byte-identical). den ci = 1051/1052 (only pre-existing fleet-pipe).

See [[project_nix_config_migration]], [[project_gen_package]], [[project_den_hoag_features]].

──────── archive-project_gen_schema_deferred.md ────────
---
name: gen-schema deferred integration items — RESOLVED
description: Both deferred items shipped in commit 67f546b on feat/contracts-mixins (2026-05-23)
type: project
---

**RESOLVED 2026-05-23.** Both items shipped in commit `67f546b`:

1. **Auto-extract refinements from types** — `entry-type.nix` scans all inline defs for `mkOption` values with `__schema` metadata, extracts refinements, stores on kind result. `instance.nix` reads `schema.${kind}.refinements or {}` when no explicit `refinements` parameter provided.

2. **Auto-apply mixins in mkSchemaEntryType** — when `mixins != []` and `baseModule` is an attrset, `entry-type.nix`'s merge function converts to record algebra form, applies mixins via `applyMixin`, emits through bridge. Sidecar merge strategies applied to bridge-extracted sidecars. Falls back to existing code path when `mixins == []`.

──────── archive-project_gen_select.md ────────
---
name: gen-select design
description: Selector algebra library — spec approved, plan written 2026-05-25. ID-based accessor context, gen pure tier dep, 11 constructors, two adapters, CSS + SQL demos.
type: project
---

gen-select: selector algebra for attributed graph positions. Spec approved and plan written 2026-05-25.

**Spec:** `~/Documents/papers/den-architecture/specs/2026-05-25-gen-select-design.md` (gist: sini/d0a15a78eda49b4d7da7fedf27b3b10f)
**Plan:** `~/Documents/papers/den-architecture/plans/2026-05-25-gen-select.md`

**Key decisions from brainstorming:**
- Context is ID-based accessor functions (not materialized lists) — memory proportional to what selector inspects
- Depends on gen pure tier only (mkIntensional, intensionalEq) — not zero-dep
- `id` is NOT in the context shape — it's the second arg to `matches`, avoids stale ID during structural recursion
- `sel.when` detects intensional functions via three-field check (`name && __functor && closure`)
- `selectorEq` delegates to `genPure.intensionalEq` for identified when selectors
- Adapters ship in-library but don't import gen-scope/gen-graph — pure structural contracts
- CSS and SQL parsers are demo templates, not core library

## Reference implementations

- `~/Documents/repos/gen-scope/templates/nest-traits/lib/selectors.nix` — working selector system with CSS parser, structural matchers, programmatic selectors
- `~/Documents/repos/gen-scope/templates/nest-traits/lib/css.nix` — CSS-like selector string parser
- `~/Documents/repos/gen-scope/templates/sql-schema/lib/rules.nix` — WHERE-clause matching (alternative selector grammar)

## Consumers in den v2

| Use site | Current mechanism | With gen-select |
|----------|-------------------|-----------------|
| `neededBy` | Literal aspect refs | `neededBy = sel.class "nixos"` or `sel.when pred` |
| `pipe.gather pred` | Nix function `{ host, ... }: true` | `pipe.gather (sel.entityKind "host")` |
| `pipe.source pred` | Nix function | `pipe.source (sel.attrs { role = "app"; })` |
| `policy.when pred` | Nix function over entity ctx | Could accept selectors as sugar |
| `provides.to-users` | Hardcoded entity-kind routing | Desugars to `neededBy = sel.entityKind "user"` |
| Rule matching (nest-traits) | CSS selectors | Already uses this pattern |

## Selector constructors (from nest-traits)

```nix
sel.star                          # matches everything
sel.attrs { env = "prod"; }       # matches nodes with these attribute values
sel.or [ selA selB ]              # matches if any selector matches
sel.not selA                      # matches if selector doesn't match
sel.has selChild                  # matches if any CHILD matches selector
sel.within selAncestor            # matches if any ANCESTOR matches selector
sel.when fn                       # matches if fn returns true (programmatic escape hatch)
sel.class "nixos"                 # matches nodes with this output class
sel.child parentSel childSel      # CSS "parent > child" combinator
sel.descendant ancestorSel descSel # CSS "ancestor descendant" combinator
```

## API surface (minimal)

```nix
{
  # Constructors (above)
  inherit star attrs or not has within when class child descendant;

  # Core: does a selector match a node in context?
  matches = selector: node: context: bool;

  # Context builder: takes gen-scope accessor pattern
  mkContext = { node, get }: id: { select, children, ancestors, siblings, parent, ... };

  # Optional: CSS string → selector
  parse = cssString: selector;
}
```

## Design considerations (updated 2026-05-25)

1. **`sel.when` is the escape hatch** — wraps arbitrary Nix functions. den's `canTake`/guard dispatch already uses this pattern. Selectors provide the DECLARATIVE layer; `when` bridges to imperative predicates.

2. **Context uses gen-scope's accessor pattern.** `mkContext` takes `{ node, get }` (gen-scope's result shape). Structural queries use these accessors:
   - `parent` = `(node id).parent` (structural field, always cheap)
   - `children` = `builtins.attrNames (get id "children")` (computed attribute, memoized via `_eval`)
   - `siblings` = children of parent, excluding self
   - `ancestors` = walk parent chain

   All are memoized by gen-scope — "coming from attribute evaluation" IS cheap. No need to pre-build a flat context map.

3. **Selectors are composable.** `sel.and` is implicit (list = conjunction). `sel.or` is explicit. This matches CSS compound selector semantics.

4. **String parsing is optional.** The CSS parser from nest-traits is nice for DSL-like rule definitions. But the constructor API (`sel.attrs`, `sel.has`, etc.) is the primary interface. String parsing is sugar.

5. **Entity-kind selectors are den-specific sugar.** `sel.entityKind "user"` would be `sel.attrs { type = "user"; }` in the generic library. Den wraps it for ergonomics.

6. **Integration with gen-graph.** gen-graph's `select` takes `{ nodes, nodeData }` accessor functions. Composition:
   ```nix
   gen-graph.select {
     nodes = builtins.attrNames result.allNodes;
     nodeData = id: result.node id;
   } (data: gen-select.matches selector data ctx)
   ```
   gen-graph filters a KNOWN set by predicate; gen-select provides the predicate via pattern matching.

7. **Integration with gen-scope's selective materialization.** `allNodesWhere` can use selectors:
   ```nix
   result.allNodesWhere (node: gen-select.matches selector node (mkContext result node.id))
   ```

## Academic provenance

- CSS Selectors spec (W3C) — structural pseudo-classes (:has, :not, :nth-child)
- Datalog/Datafun (Arntzenius 2016) — pattern matching as monotonic queries
- XPath (W3C) — axis-based node selection over trees (ancestor::, child::, descendant::)
- Neron (2015) — scope graph resolution as path-finding (selectors as path predicates)

## How to apply

When brainstorming gen-select, start from the nest-traits `selectors.nix` implementation at `~/Documents/repos/gen-scope/templates/nest-traits/lib/selectors.nix`. It's proven (tests pass), covers the CSS parser, and handles all the structural matching patterns. The main work is: extract, generalize (remove nest-traits-specific coupling), adapt `mkContext` to accept gen-scope's `{ node, get }` accessor pattern, test independently.

──────── archive-project_gen_spec_audit.md ────────
---
name: gen-spec-audit-status
description: Reference synthesis audit — 4 deferred libs resolved+archived 2026-05-30. Only gen-derive (phases impl) + den-hoag (open-question log) remain. Worktrees still live.
metadata: 
  node_type: memory
  type: project
  originSessionId: 36b8bcc7-a209-4796-aba6-bb912be222a8
---

## Gen Ecosystem Reference Synthesis Audit

Spec: `~/Documents/papers/den-architecture/specs/2026-05-28-gen-ecosystem-reference-synthesis-design.md`
Plan: `~/Documents/papers/den-architecture/plans/2026-05-28-gen-ecosystem-reference-synthesis.md`
Output: `~/Documents/papers/den-architecture/gen-specs/{library}/REFERENCE.md`
Staging (artifacts, pre-move): `/home/sini/Documents/repos/den/.gen-ref-staging/`

**Archive convention:** resolved = `git mv` the 5 analysis files (CHANGES/DEVIATIONS/DRIFT/ISSUES/UNDOCUMENTED.md) into the lib's existing `archived/` dir (which already holds source design specs), leaving only `REFERENCE.md` + `archived/` at top level. Original resolve commit: `23318a4 chore: spec analysis result`.

### Resolved + archived (only REFERENCE.md + archived/ at top level)

- **gen-algebra, gen-schema, gen-graph** — resolved in the original 2026-05-28 pass.
- **gen-aspects** (2026-05-30) — 6 REFERENCE.md doc-fixes. Key: aspect-chain threading claim was FALSE — code proves NO auto-threading (identity.nix:4 sole reader, nothing writes it; test-nested-aspect-key proves name-local keys). DEVIATIONS was right. providerPrefix accepted but inert in types.nix.
- **gen-scope** (2026-05-30) — 7 REFERENCE.md doc-fixes (suite/example counts, "cycle detected" msg, evalDebug shape, van-Antwerpen overclaims softened, Neron §2.5 limitation). allowParent/P*.I* WF DROP left as documented consumer-delegation (Dead End #4) — non-blocking; optional human ratification still open. Forwarding (Van Wyk) stays acknowledged-deferred.
- **gen-bind** (2026-05-30) — 4 REFERENCE.md doc-fixes + 1 wrap.nix code-comment cleanup (uncommitted in gen-bind repo). contract.lazy + gen-algebra contract migration stay deferred (belong to gen-type-unification, not gen-bind-local).
- **gen-select** (2026-05-30) — 4 REFERENCE.md doc-fixes (counts now 175, registry adapter documented, selectLib→genSelect, siblings relaxed). **GS-1 resolved by RATIFYING** the shipped `mkSelectPredicate : selector -> context -> attrset -> bool` (data.id) signature — amendment added to `specs/2026-05-25-gen-select-design.md` (Amendments section + adapter section). Locks in data.id convention; zero code change.

### Remaining (NOT archived)

- **gen-derive** — ✅ **SHIPPED 2026-05-30** (gen-derive `main` @ 6b69e80, pushed; 67/67 tests). Full per-phase stratified dispatch: `dispatch` walks `topoSort(phases)` threading context phase→phase via `extract`/`combine`; `fixpoint` owns convergence (`eq ctx dispatch.context`); `mkRule.phase` declared + classify-validated; forward-accumulating override; backward-compatible identity defaults. Built via brainstorm→spec→plan→subagent-driven TDD (4 tasks, each reviewed). Spec archived at `gen-specs/gen-derive/archived/2026-05-30-gen-derive-stratified-phases-design.md`; plan at `plans/2026-05-30-gen-derive-stratified-phases.md`. Arntzenius citation now a faithful `Implements`. NOTE: gen-derive's reference-audit analysis files (CHANGES/DEVIATIONS/DRIFT/ISSUES/UNDOCUMENTED) are still at top level — eligible for archival (move to `archived/`) now that the gap is closed; not yet done.
- **den-hoag** — NOT a shippable lib; it's the den v2 HOAG target architecture. #4 doc-fix done (mkType + neron traverse now SHIPPED — narrowed Spec-Only line; retired ISSUES #2/#4). KEPT as open-design-question log: 5 live design questions remain in ISSUES.md (#1 neededBy scoped-desugaring, #5 fleet-feature sequencing, #6 per-class output assembly, #7 edge no-re-resolution semantics, #8 pipe.withConfig cross-host strictness). #3 (nix-config prototype) un-verifiable — nix-config repo absent on disk. Do NOT archive until HOAG implementation resolves these.

### Uncommitted state (2026-05-30, NOT yet committed)

- Papers repo `~/Documents/papers/den-architecture`: 20 staged renames (archive moves) + 8 modified (7 REFERENCE.md + den-hoag ISSUES.md + specs/2026-05-25-gen-select-design.md amendment).
- gen-bind repo: `nix/lib/wrap.nix` comment change (+1/-1).

### Infrastructure

- Worktrees at `~/Documents/repos/{library}/.worktrees/ref-audit/` — STILL LIVE except gen-algebra (cleaned). HEADs have advanced past audit snapshots (perf/rename commits) but none changed open-issue behavior. Keep gen-derive's worktree until phases impl lands; rest can be cleaned.
- ECOSYSTEM.md at `~/Documents/papers/den-architecture/gen-specs/ECOSYSTEM.md`; newer copy in `.gen-ref-staging/`.

### How to apply

Two items left: (1) implement gen-derive full per-phase stratified dispatch (design→TDD→review; see decision above), then archive gen-derive; (2) den-hoag's 5 open design questions resolve during HOAG implementation, not as audit doc-fixes. For deferred-lib detail read the analysis files now in each lib's `archived/`.

──────── archive-project_gen_theory_audit.md ────────
---
name: gen-theory-conformance-audit
description: "2026-05-30 audit — does each gen lib implement the theory it cites? Verdict: load-bearing theory sound+faithful; problems are provenance overclaims + 3 misattributions + 1 real gap + den-v2 caveats. Fixes NOT yet applied."
metadata: 
  node_type: memory
  type: project
  originSessionId: 36b8bcc7-a209-4796-aba6-bb912be222a8
---

## Gen theory-conformance audit (2026-05-30)

Ran after the reference-synthesis doc audit. Question: not "do docs match code" but "does the code faithfully implement, and soundly apply, the academic theory it CITES?" Method: 9 targets × (verify provenance vs actual paper text vs code) → adversarial challenge of every significant finding. 29 agents, 20 challenges (15 upheld, 5 refined, 0 overturned). Paper texts at `~/Documents/papers/den-architecture/used/markdown/` (+ summaries/, + reference-catalog/markdown/ for AG/AOP/SPL core).

**Headline:** every library's load-bearing theory is faithfully implemented and well-chosen. No core mechanism rests on a misread paper. Problems are provenance HYGIENE, not design.

### Findings to fix (adversarially confirmed)

These overclaims live in BOTH the canonical `gen-specs/{lib}/REFERENCE.md` (papers repo) AND the shipped `~/Documents/repos/{lib}/README.md` (+ 2 code comments). Fixing fully = both places.

1. **Phantom "Theorem 5.12" (gen-aspects, gen-select, gen-derive).** Palmer 2024 has NO Theorem 5.12. Real results: Lemma 5.12 + Theorem 1 (closure consistency) + Def 5.6. Copy-paste error across provenance rows. Global re-cite.
2. **"Implements"→"Informed by" overclaims.** gen-select cites Neron as Implements but only models P-edge traversal axes (parent/child/ancestor), NOT the resolution calculus (no WF/specificity/shadowing/import edges). gen-aspects: identity keys ENABLE dedup, no "fold-based collect" (no fold). gen-scope: README.md:422 still says "per-query visibility/Statix-style" (REFERENCE already softened — sync README). gen-bind: REFERENCE flat 6-row table vs honest README two-tier — port honest one up.
3. **3 genuine misattributions (wrong paper).** gen-graph cycles cites "Vogt 1989 Lemma 3.2 — correct per" (global.nix:33) — Vogt proves no such thing; standard cycle detection; drop. gen-bind DI cites "Bracha & Ungar 2004 Mirrors / mixin combinator" (wrap.nix:8) — construction-time arg injection ≠ Bracha mixins; drop/demote. gen-graph transitiveReduction cites Mokhov §4.5 — that section gives only the equivalence-class notion; algorithm is standard DAG reduction; needs DAG precondition documented.
4. **gen-graph provenance mostly decorative** + stale API doc GG-10 (mock namespace → registry.nix; "five modules plus mock" → six modules; fromNodeMap gone).

### The one real design GAP (already decided to fix)

gen-derive claims Arntzenius stratified phases w/ DAG ordering, but topoSort is never called (dead `phases`, output is alphabetical attrset). Confirmed overclaim/gap (also den-hoag F5). The decided **full per-phase stratified dispatch** build (see [[project_gen_spec_audit]]) converts this citation from aspirational to faithful.

### Deeper den-v2 design-soundness caveats (fold into den-hoag open-question log)

- **Neron completeness doesn't transfer.** Neron Thm 1 (unambiguous resolution) assumes a STATIC scope graph; den v2 interleaves construction with resolution, so completeness doesn't carry — v2 ships a DETECTOR not a GUARANTEE. The needed result is **Statix §4.3 (soundness over INCOMPLETE graphs)** — not currently cited.
- **Pipes-as-Kahn-channels is a stretch.** `gather` has MULTIPLE writers → violates Kahn single-writer (the source of KPN determinism). Determinism actually comes from a commutative/associative `combine` (semilattice / Radul propagator quiescence), not KPN. Re-ground.
- **intensionalEq more aggressive than Palmer's (latent ecosystem footgun).** Name-only equality is a SUPERSET of Palmer's name+closure equality → dedups more than the paper permits; sound only if names are made closure-discriminating. Archived summary's "more conservative / safe by monotonicity" justification is BACKWARDS. Clean fix: closure-aware intensionalEq (Palmer Fig 5). Underpins dedup in gen-aspects/select/derive.

### Genuinely faithful (credit)

gen-algebra (Bracha mixin formulas verbatim; Palmer search monad catch-up/dedup exact), gen-schema (Bracha + Findler/Chitil flat refinement contracts), gen-scope (Mokhov algebraic core near-complete; Neron D<I<P + shadowing), gen-derive CORE (Forgy opaque rules, Ehrig boolean NACs, Datafun/Radul monotone fixpoint), den-hoag AG/HOAG chain (Knuth/Vogt/Hedin/Neron/Mokhov-2018/Sloane).

### Status — docs fixed everywhere (2026-05-30, UNCOMMITTED)

Provenance corrections applied across: papers REFERENCE.md (gen-schema/aspects/graph/bind/select/derive + den-hoag) + shipped READMEs (gen-aspects/scope/graph/select/derive) + 2 code comments (gen-graph `lib/global.nix`, gen-bind `nix/lib/wrap.nix`) + the palmer-2024 summary. den-hoag ISSUES.md gained open questions **#9** (Neron completeness / Statix §4.3), **#10** (pipe determinism / Kahn multi-writer), **#11** (intensionalEq aggressiveness).

**User decision: RAISE code to theory where feasible** (not merely demote claims). Compliance tasks captured in `gen-specs/THEORY-COMPLIANCE-FOLLOWUPS.md`:
- A: A1 closure-aware intensionalEq [✅ RESOLVED 2026-05-30 as DOCUMENTATION, not code — reclassified to "informed-by ceiling". A demo survey + adversarial review found: gen's `closure` is programmer-declared (NOT Palmer's compiler-extracted itsInspect) so neither name-only nor name+closure is Theorem-1-faithful; no consumer needs closure-discrimination (selectorEq/search/gen-derive fired-set all name-only on bare lambdas/empty closures) so a variant would be dead code; toJSON closure-eq is fragile (uncatchable abort on function-in-closure, store-copy on paths, 1≠1.0). Docs now state intensionalEq is a deliberate name-only over-approximation implementing the STRUCTURE of Palmer's intensional functions, not Theorem 1. gen-algebra @ 33943de + papers @ 2248409]. A2 gen-derive stratified phases [✅ SHIPPED 2026-05-30 @ 6b69e80]. A3 gen-aspects fold-dedup [closure-aware dependency now moot — name-only identity is the deliberate ceiling; revisit only the fold-existence question if it matters].
- B (evaluate-worth): Lorenzen mechanism, gen-schema scope-graph integration, gen-select↔gen-scope composition — informed-by may be the honest ceiling.
- C (den-v2): #11 intensionalEq aggressiveness [✅ RESOLVED 2026-05-30 — naming-discipline contract formalized in docs; see A1]. Still open: #9 Neron completeness / Statix §4.3, #10 pipe combine-algebra grounding — tracked in den-hoag ISSUES.md.
- D (no task): gen-graph Vogt/Mokhov + gen-bind Bracha were MISATTRIBUTIONS (wrong cite, not weak code) — correcting the cite IS the fix.

Uncommitted across papers repo + 6 lib repos (gen-algebra clean). Workflows: wb735bbrt (audit, run wf_1fa3114b-d5e), w08uuwjx9 (fixes, run wf_f4ddac08-ec5).

## Reynolds-1972 §6 conformance follow-up (2026-07-02, UNCOMMITTED)

Re-fetched Reynolds 1972 full text (35pp; prior `used/markdown/` + `.pdf` were BOTH a Springer landing-page scrape — the `.pdf` was HTML). Ran a fresh conformance workflow (`wf_299d27a5-5b6`, 25 agents, adversarial verify). **Finding:** the "guard/arg defunctionalization" cite cluster is an OVERCLAIM. `functionTo` wrapping is REFLECTION not §6 defunctionalization — arrow survives inside nixpkgs `__functor` (re-runs original closure), single opaque `__isWrappedFn` tag (not one ctor/lambda site), `__functionArgs`=arg-names not captured free vars → fails obligations O1/O2/O3/O4/O6. Headline defect = INCONSISTENCY: gen-bind honestly files the identical mechanism under "Informed by / not defunctionalization per se," while gen-aspects+gen-resolve upgrade it to "Implements." gen-select's Reynolds cite is the **1983** parametricity paper (out of scope, faithful). gen-resolve README:215 ("consumer must defunctionalize args to data — a Reynolds obligation") is the ONE correct usage — left intact.

**Applied (working-tree, uncommitted):** downgraded 12 citations to Analogy/Informed-by across gen-aspects (README:43/279/285, types.nix:17/76-80), gen-resolve (README:117/354, materialize.nix:2, ci/tests/materialize.nix:8), gen/TERMINOLOGY.md:130/390, gen-bind/lib/strip.nix (dropped bogus §4 anchor — §4 is Abstract Syntax; anchored gen-bind closure-binding to §5 environments). NB: gen-bind wrap.nix/thunk.nix §5 CLOSR/EQ2 provenance cites were adversarially REFUTED to faithful — leave.

**Spec written:** `gen-specs/gen-aspects/2026-07-02-guard-defunctionalization.md` — turn the analogy into a GENUINE §6 transform for a closed guard-constructor vocabulary (`mkGuardVocab` + global `applyGuard` + structural `guardKey = H(form,argData,bodyKey)` replacing the `identity.nix` source-position `meta.loc` key). Raw closures stay as honestly-labeled escape hatch (A1 wall / OQ4 byte-mode fallback). Directly feeds the [[project_gen_resolve]] structural-identity-dedup spike §5.3 (tag=`kind`, argData; OQ2/OQ4/`m5`). ~1 session, no new lib. **Rev 2 (agent review incorporated):** predicate/body split (predicates are pure data → `guardKey` never toJSONs a closure; fixed a real throw on nested `all`/`any`); co-cite Danvy-Nielsen 2001 for the O1-O8 obligation checklist (Reynolds §ETitle "Elimination of Higher-Order Functions" verified verbatim @ md:718, NOT numbered §6 in the reprint); explicit ctx read-set table = §5.4 congruence; §8 flags it edits the SAME types.nix/identity.nix as C2 grammar re-host → must serialize (guards-first, carry `__guard` branch through C2).

**Slotted into the pre-den-hoag meta-plan as task A4** (`gen-specs/2026-07-02-pre-den-hoag-meta-plan.md`): gen-aspects, Wave A, effort M (~1 session), **MUST precede C2** (grammar re-host, same repo — land A4 first so C2's purity sweep folds in guard.nix's nixpkgs.lib uses in one pass; C2's parity oracle must preserve the `__guard` branch + `guardKey`). NOT in concurrent worktrees with C2. Independent-value justification for doing it now (the dedup payoff itself is the DEFERRED G6-gated arc): retires the Reynolds overclaim + unblocks den-hoag guard read-set analysis (meta-plan W4.4 guard/neededBy asymmetry). Implementation plan: `gen-specs/gen-aspects/2026-07-02-guard-defunctionalization-plan.md`. **SHIPPED to gen-aspects `main` @`87bf758` 2026-07-02** (7 commits, 109 nix-unit tests, fast-forward/linear). Executed subagent-driven (writing-plans → subagent-driven-development): per-task spec+quality reviews + a final holistic review, all passed; two adversarial plan reviews first (the toJSON-on-function-is-uncatchable finding drove the `hasFn`-before-`toJSON` design). Delivered: `lib/guard.nix` (predicate vocabulary `toArgData`/`pred`/`guard`/`mkGuardVocab`/`applyGuard`, hardened `guardForms` seam), `identity.nix` `guardKey`/`bodyKey` (structural for first-order bodies, `guard-loc:` source-position fallback for opaque — sound, no false merge), `types.nix` `__guard` pass-through in `aspectType.merge`, `flatten.nix` `__guard`-as-leaf. Raw closures = honest `functionTo` escape hatch (single-def only; multi-def documented-unsupported). NEXT dependency: C2 grammar re-host must preserve the `__guard` branch + `guardKey` (invariant registered in `gen-specs/gen-resolve/2026-06-26-phase-1-grammar-rehost-notes.md` §6/§7). Ledger + all findings: `/tmp/.../tasks/wi5dc28y5.output` (ephemeral).

──────── archive-project_gen_tracker_scope.md ────────
---
name: project_gen_tracker_scope
description: "den-hoag's local beads tracker is THE tracker for ALL gen-* repos, not just den-hoag"
metadata: 
  node_type: memory
  type: project
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T00:27:40.475Z
---

The beads tracker in `~/Documents/repos/sini/den-hoag/.beads/` is the tracker for **all of gen** — every
`gen-*` library, not only den-hoag. A defect found in `gen-graph`, `gen-schema`, `gen-resolve`, etc. gets
filed as a bead HERE. Do not look for (or create) a separate per-repo tracker in each `gen-*` clone.

Stated by the owner 2026-07-27, when a `gen-graph` citation defect surfaced during the den-hoag kernel-purity
arc and was described as "homeless".

**Why:** the gen libraries are developed as one ecosystem with den-hoag as the primary consumer; splitting
issues per repo would fragment a dependency graph that is already cross-repo. It also means the review gate
and the `arch-validated` labelling apply uniformly across gen.

**How to apply:** when an audit turns up a `gen-*` defect, `bd create` it in den-hoag's tracker with the
library named in the title (the existing convention is a bracket prefix — see `den-hoag-00g` "[gen-merge]",
`den-hoag-nn4` "[gen-schema]", `den-hoag-1qh` "[gen-merge]", `den-hoag-cah` "[codebase-memory-mcp]").
Findings still pass the review gate before entering the graph as work — see [[feedback_orchestrator_theory_first]].

Related: [[reference_gen_lib_capability_map]], [[project_gen_package]], [[reference_gen_repo_clone_location]].

──────── archive-project_gen_trust_release.md ────────
---
name: project-gen-trust-release
description: gen v1 trust release SHIPPED 2026-07-06 — v1.0.0 tags, VALIDATION/BENCHMARKS/trust-story public; register remainders + next push
metadata: 
  node_type: memory
  type: project
  originSessionId: 538baea8-244e-4e43-ad95-8c2f2cf34af8
---

**TRUST RELEASE SHIPPED 2026-07-06 — §1 done-bar MET.** v1.0.0 tags: gen @60f3a42 · gen-merge @fdbf140 · gen-flake @88f639c · gen-class @218c54f. Public VALIDATION.md (1988 tests, claims→commands) + BENCHMARKS.md (warm/engine-cost band +3.7-6.3%/B5 3-way fold-ins) + hub README trust-story. Ecosystem inputs unpinned to branch heads; **gen-{schema,aspects}-orig stay PINNED FOREVER** (frozen golden-reference oracle witnesses — rotating breaks/vacates the parity oracle; documented in ci/flake.nix). Register (roadmap §6a) post-release closures 2026-07-06: den s1/s2 PUBLISHED (github:sini/den feat/s1-per-sid-hostconfig + feat/s2-pipe-reads); fleet-gates RE-HOMED by owner principle (**libraries stay unburdened by metrics** — the hola [consistency] roster lives in the HUB trust surface @9157fe8, hola=only re-measurement home @3e449ac, gen-class/gen-rebuild untouched; scoping `gen-specs/gen-class/2026-07-06-fleet-gate-migration-scoping.md`). Still open: tracked invalidation, per-path freeform, disabledModules×warm (all on-demand). Next push: pre-den-hoag roadmap (2026-07-02), W1 spike first.

Arc history (roadmap `gen-specs/2026-07-04-gen-v1-trust-release-roadmap.md`), session 2026-07-05:

**Shipped + pushed:** B3 portable-subset lint (gen-merge @b685718: `lint` verb, {kind;loc;file;detail}, total-on-portable via engine discharge machinery, `unverifiable` kind on fuel exhaustion). B4 harness shapes (hub: deepSubmodule @77b7768; wideFreeform @b4f3196 gated as thunks-only parity band ≤1.3, cpu/alloc keep default win-gates). **Freeform O(n²) FIXED** (gen-merge @f6971db: unmatched defs coalesced per module INSTANCE via modIndex threading — was 117×ref/quadratic, now linear ~1.1×; do NOT "optimize" to foldl'-append group-by: Nix `++` in fold = hidden quadratic, measured 27× cpu, documented in-code). Hub baselines consolidated to single pin 018bafa; BENCHMARKS.md regenerated.

**A2 (gen-flake v1) COMPLETE 2026-07-05** — 7/7 tasks two-stage-reviewed + pushed. gen-merge@2ceedbf: always-on provenance channel (+3.7-4.7% thunks, scalar headroom now 0.018 @0.882/0.90). gen-flake@9488dc6: compose v1 (aspects/hosts/engineArgs/selectHosts), realize + class-keyed terminals (mkSystems retired, iff-non-empty semantics), cold override + the standing two-digest tooth (THE A4/memoization oracle), verbatim provenance projection + lib.diff (perLoc forces the whole changed partition — intrinsic), flakeModule v1 (terminals/injectPerSystem/realized). 3 demos migrated (gen-aspects delta: realize unions aspect content per host). Spec/plan: `gen-specs/gen-flake/2026-07-05-gen-flake-v1-{design,plan}.md`.

**A4 COMPLETE 2026-07-06** (5/5, all pushed): gen-merge @fdbf140 — srcClass classification (function modules DIRTY by default: functionArgs can't see @-patterns/bare lambdas, formals-cleanliness UNSOUND; `pureModule` author-marker recovers), warmFrom+editedModules dirty-footprint memoization (isOptLeaf-only splice, coarse freeform, disabledModules guard, adversarial lying-marker tooth); gen-flake @329a9a7 — warm override (syntactic modules-only fire) + decision `trace`, standing tooth unchanged = the oracle; hub @d2f8d2d — overrideWarm gate (warm/cold thunks 0.168/alloc 0.172, ~5.9× reuse; wideFreeform cpu moved to 0.95 band — 0.85 was load-flaky, counters exonerated classify: the pin shift is the provenance channel); gen-aspects @c46f8f3 showcase (fleet spliced, trace narrated). **B5 COMPLETE** @1747ba6 (drvPath equivalence 15/15 across gen-flake/flake-parts/adios; gen-flake lowest counters). Spec/plan: `gen-specs/gen-flake/2026-07-05-a4-memoized-override-{design,plan}.md` (3-iteration adversarial spec review — editedModules-list API, leaf-splice granularity, freeformType hazard all caught there). **REMAINING: A5 release** (v1 tags, VALIDATION/BENCHMARKS regen incl. warm+B5 fold-ins, trust-story README; §6a register items destined A5). Deferred register = roadmap §6a.

**Ops lessons (binding):** teammate agents' final-turn text NEVER reaches the controller — require SendMessage delivery in every dispatch. Push authorization is per-session explicit ("develop in the open" granted 2026-07-05). gen-merge suite now needs raised stack (ulimit) for nix-unit aggregate — stale ci pin flagged for bump. Related: [[project_gen_package]] [[feedback_estimate_delivered_shape]]

──────── archive-project_gen_type_unification.md ────────
---
name: gen-type-unification-design
description: "SHIPPED (verified 2026-06-09) — gen-aspects ported onto gen-schema (hard dep now), mkType + neron traverse + settings-as-collection all landed; settings injection still demo-only"
metadata: 
  node_type: memory
  type: project
  originSessionId: b9463207-aa3d-4941-abd2-b0ac298d61d8
---

Spec at `~/Documents/papers/den-architecture/specs/2026-05-27-gen-type-unification-design.md`
Gist: https://gist.github.com/sini/b27f327ce5306658e707a755341d9d31

**Status 2026-06-09 (readiness review):** Port COMPLETE — gen-aspects has gen-schema as hard runtime dep (`lib/default.nix` CI-lock fallback, `schema.nix` mkAspectSchema fully implemented, settings-as-collection in demo setup.nix). gen-schema `mkType` shipped (entry-type.nix:28) incl. auto-refinement-extraction + auto-mixin-application (both former deferred items DONE). gen-scope neron traverse shipped. Dependency graph NO LONGER flat: gen-algebra → gen-schema → gen-aspects. Remaining: `injectAspectSettings` is demo-only (examples/demo/modules/injection.nix), not exported from lib — promote if den-hoag wants it as primitive. See [[den-hoag-readiness-review]].

**Regression audit 2026-06-26 (den v0.17.0..v0.18.0 / HEAD 11866c16, multi-agent workflow):** gen-aspects type system has ZERO regressions vs den's recent aspect-module + merge-semantics fixes. 3 SAFE-by-construction (#580 no-force-during-classification, #563 reserved-key reads-back-verbatim, #603 multi-def stable identity — the module-system option/freeform split makes each bug-class UNEXPRESSIBLE; den classifies raw content with an explicit recursive force-walk, gen-aspects offloads to name-based option-vs-freeform routing). 7 OUT_OF_SCOPE (den pipeline/delivery, gen-aspects correctly omits: #589 namespace `_` bundle, #602 projected hasAspect, #623 config-thunk producing-scope, #578 positional-fn includes, #574 route merge, #579 closure-chain perf, #616 Lix flat schema). All adversarial challenges upheld. Immunities now PINNED by 3 new tests `ci/tests/{lazy-classification,reserved-keys,multi-def-identity}.nix` (11 cases, green; flake check + fmt green). Carry-forward landmines for den-hoag PIPELINE recorded in gen-specs den-hoag ISSUES #13: HIGH — (a) `flatten.nix` forces freeform leaves to WHNF, so registry/has-aspect build must run post-fixpoint or #580 self-output recursion returns; (b) parametric dispatch must key on `__isWrappedFn` presence NOT arity (`functionArgs=={}` positional `ctx:` lambdas), else #578; MED — (c) dedup on structural `pathKey` not name-only `identity.key`, else #603 double-emit. See [[project_den_hoag_readiness]].

**Why:** gen-aspects and gen-schema are parallel type systems. Unifying them enables settings (typed config on aspects, composed via scope graph), user metadata on aspects via schema extension, and eliminates `aspect-schema.nix` manual class collection + `den.reservedKeys` string exclusion.

**How to apply:**

Four sections + registry:

1. **gen-schema: pluggable entry types** — `mkType` parameter on `mkSchemaEntryType`, backwards compatible (null default = deferredModule)
2. **gen-aspects on gen-schema** — kind-level infrastructure only (collections, introspection, extension). NOT instance-level (no `mkInstanceRegistry`, no `id_hash`). Aspects use positional identity, not content identity. `mkAspectSchema` returns `{ schemaOption, mkAspectOption, mkNamespaceType }`.
3. **Settings** — gen-schema collection on aspects (schema declarations), values from entity scopes composed via gen-algebra record (Leijen scoped labels), validated lazily (Chitil contracts)
4. **gen-scope neron traverse** — D > I > P ordered collection for `collectionAttr`, ~30-40 lines
5. **Flat registry** — Path A (computed field, pre-scope-engine) + Path B (gen-scope Tier 2, post-swap). Both expose same gen-graph/gen-select query surface.

**Key decisions:**
- gen-schema role for aspects is KIND-LEVEL only — collections, introspection, extension, computed fields
- Aspects use recursive `lazyAttrsOf aspectType`, NOT `mkInstanceRegistry` (flat entity registries)
- `includes`/`excludes`/`provides`/`policies`/`meta` are options on entry type, NOT gen-schema collections
- `settings`/`classes` ARE gen-schema collections (extracted before merge)
- One shared kind definition (`config.schema.aspect`), multiple option points with `providerPrefix`
- gen-aspects consumes gen-schema following gen-schema ← gen-algebra pattern (`inputs ? {}` + CI flake.lock fallback)
- All 16 den aspect patterns verified backwards compatible

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [Gen type unification](project_gen_type_unification.md) — SHIPPED (verified 2026-06-09): gen-aspects ported onto gen-schema (hard dep), mkType+neron traverse landed; injectAspectSettings still demo-only; v0.18 regression audit 2026-06-26 = ZERO type-system regressions (3 SAFE-by-construction #580/#563/#603 pinned by new ci tests, 7 pipeline OUT_OF_SCOPE), carry-forward landmines in den-hoag ISSUES #13

──────── archive-reference_gen_ci_asserttests_expectederror.md ────────
---
name: reference_gen_ci_asserttests_expectederror
description: "gen CI checks.default uses assertTests (expr==expected only), NOT nix-unit — expectedError/throw-message tests crash it"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9ca7f5ed-7ae4-42ab-8273-f2cde8d631a2
---

gen ecosystem CI (gen.lib.mkCi) has TWO non-equivalent test paths:
- `nix build .#checks.x86_64-linux.default` builds `assertTests` in gen/ci/flakeModule.nix — a homegrown `if t.expr == t.expected then true else throw …`. Reads `expr`/`expected` ONLY. A test whose `expr` THROWS with no short-circuiting `expected` forces the throw to top level and crashes the WHOLE check build.
- The REAL nix-unit (`nix-unit --flake ./ci#tests`, run by the pre-commit `ci` hook + devshell `ci` cmd) DOES support `expectedError = { type = "ThrownError"; msg = "…"; }`.

Consequence: `expectedError` / throw-MESSAGE assertions are INCOMPATIBLE with the checks.default gate (and thus GitHub CI which builds checks). Standing gen-lib convention: error-message content is unassertable in pure Nix from the check gate — `(builtins.tryEval expr).success == false` is the only portable throw-pin (boolean, can't see the message). Found during gen-graph labeled-query arc 2026-07-16; parked as a potential upstream item (make checks.default honor expectedError, or converge the two paths). See [[project_gen_graph_labeled_query]] [[reference_gen_docs]].

Formatter note (same repos): gen-graph ROOT flake has no `formatter` output (`nix fmt` errors); the ci/ flake DOES expose `formatter` (treefmt-nix) and the pre-commit treefmt hook formats on commit. Use standalone `nixfmt` (rfc-style) on .nix files + rely on the hook; `./ci#formatter` for markdown (mdformat-gfm).

──────── archive-reference_gen_docs.md ────────
---
name: gen-ecosystem-root-repo
description: "Canonical ecosystem hub — TERMINOLOGY.md, ARCHITECTURE.md, README.md — at ~/Documents/repos/sini/gen/ (github:sini/gen). Renamed from gen-docs 2026-05-26."
metadata: 
  node_type: memory
  type: reference
  originSessionId: b5e2d5ef-3352-4d2e-bf50-79c8c043b3fd
  modified: 2026-07-26T04:33:46.697Z
---

gen ecosystem root at `~/Documents/repos/sini/gen/` (github:sini/gen) contains canonical ecosystem-wide documentation. Moved 2026-07-25 from `~/Documents/repos/gen/` — every clone now sits under the parent matching its git remote root, i.e. `~/Documents/repos/sini/<repo>` (see [[reference_gen_repo_clone_location]]).

- `TERMINOLOGY.md` — unified vocabulary for the gen libraries + den v2, with academic provenance. Supersedes `~/Documents/papers/den-architecture/specs/2026-05-24-unified-vocabulary.md`.
- `ARCHITECTURE.md` — how the libraries compose: dependency graph, data flow, accessor chain, convergence-loop coordination, performance model, design constraints.
- `README.md` — ecosystem overview, library table, core ideas, theoretical foundations.

Created 2026-05-26. Promoted from gen-docs to gen after gen-algebra rename freed the name.

**Current lineup (2026-07-01):** hub `mkGenLibs` = prelude, algebra, scope, graph, bind, schema, aspects, select, **dispatch** (renamed from gen-derive; the pure dispatch STEP), resolve — plus standalone gen-rebuild + gen-vars. The convergence LOOP lives in gen-resolve (gen-scope.circular), NOT in gen-dispatch — see [[project_gen_resolve]] + [[project_gen_package]]. These three hub docs were refreshed 2026-07-01 for the rename + loop⊥step split.

NOTE: `~/Documents/repos/genx` is OLD/DEPRECATED work (not part of the live ecosystem) — ignore it, don't flag it.

──────── archive-reference_gen_gap_integration.md ────────
---
name: reference_gen_gap_integration
description: Consumer integration contracts for the 6 gen-gap primitives (G1-G6) built to dissolve den-hoag's effect-shape hand-rolls — the API + load-bearing caveat each imposes when den-hoag wires it, with ship status/commits. For the den-hoag agent doing the route-through.
metadata:
  node_type: memory
  type: reference
  originSessionId: a220e78f-5ac2-4b6c-b417-3d65c0b01fcd
---

The 6 gen-side primitives from [[project_denhoag_effects_audit]] were BUILT (2026-07-24, one agent per repo, TDD + independent adversarial review each). These are the CONSUMER CONTRACTS for wiring them into den-hoag (the route-through that deletes the hand-rolls). Each primitive is additive/back-compat in its gen lib; the caveats below are what den-hoag must honor.

**Ship status:** ALL SIX PUSHED to main, each TDD'd + independently review-SHIP + papers REFERENCE committed. gen-graph @231b319, gen-dispatch @8f537ec, gen-bind @268d401, gen-pipe @5350930, gen-scope @ceabe5e. Pull any now; the den-hoag route-through (deleting the hand-rolls per each consumer contract below) is the remaining den-hoag-side work.

## G3 — gen-dispatch declared-stratum (github:sini/gen-dispatch @8f537ec, PUSHED)
API: `mkRule { produces ? [tag] }`; `groupOf`/`producesOf` (read stratum WITHOUT firing); `deriveGroup (tag->group) rule` (definition-time classify+stamp `group`; aborts NAMED on kinds-span-multiple-groups / explicit-group≠classified / unknown-kind); `mkActions.groupOfKind`. `dispatch` HONORS a declared rule → skips fire-and-classify.
★ CONTRACT (load-bearing, trust model = mirrors gen-resolve trusting `stratum`): `produces` is a TRUSTED assertion. **den-hoag MUST run `deriveGroup declare.stratumOfKind` at compile time to stamp+validate `group` BEFORE handing rules to dispatch** — dispatch trusts the declaration blindly and SILENTLY mis-stratifies a lie (no diagnostic). deriveGroup validates group≡produces but NOT produces≡body (a body emitting a kind outside declared produces is caught by neither — accept, same as gen-resolve). Do NOT pass `produces = []` (non-null → treated declared/skips-validation, but derives no group).
Retires: concern-policies.nix `probeOf` (155-172) + `mkExpanded` (226-242). A value-conditional policy still yields one rule per stratum, but each is a DECLARED slice (produces filtered to that stratum), NOT a blind N-way fan-out. Bare-function corpus policies that can't declare their kinds stay den-hoag's own concern.

## G1+G2 — gen-graph preorder traversal (github:sini/gen-graph @231b319, PUSHED, lib/preorder.nix)
API: `foldPreorder { roots; key; expand; acc; visited? }` (THE primitive: pre-order DFS fold, caller-owned acc + first-occurrence visited; null key = unguarded); `expandPreorder { roots; key; edges; resolve?; emit?; seen0?; nodes0? }` (payload closure; `edges` reads the RESOLVED payload → demand-generated successors); `foldReach { roots; edges; target; project; itemKey; visited0?; seen0?; nodes0? }` (labeled/suppression-aware reach; `project edge` exposes the edge; dual key sets = target-vertex guard + item-key dedup).
CONSUMER MAPPINGS (review-verified faithful):
- `reach` (resolved-aspects.nix:333-463) → `foldReach`: visited0={id}, seen0=structural keys, nodes0=structural nodes, per-edge classFilter via `project`, negative suppression baked into `edges`, itemKey=`.key`. Byte-faithful.
- `forwardExpand` (resolved-aspects.nix:111-150) → `expandPreorder`: resolve=parametric-invoke (lazy edges), emit receives BOTH frame + resolved payload. Byte-exact order.
- `aspectIncludeWalk` (compat/compile.nix:1263-1364) → `foldPreorder`. ★ USE THE UNIFORM-FRAME MAPPING, not classifyIncludes-then-children (which REORDERS — v1's `go` INTERLEAVES: a non-policy include recurses inline before a later sibling policy). Uniform-frame = treat policy/bareFn/aspect as one frame type, classify in `expand` by type: policy → append rec, `children=[]`, `key=null` (unguarded/per-occurrence); aspect → `children = includes ++ walkableChildKeys`. Reproduces the interleave EXACTLY.
★ `foldReach` is FIRST-EDGE-WINS-PER-TARGET (vertex guard drops a 2nd edge to the same target entirely, incl its projection) — faithful to den-hoag `reach` (same behavior), but two same-target edges with different filters do NOT compose their slices.

## G4 — gen-bind arg-env transform (github:sini/gen-bind @268d401, PUSHED, lib/arg-env.nix)
Owner ratified the CHARTER WIDENING: gen-bind = "binding injection + terminal-crossing arg-env"; arg-env.nix is the sole deliberately-exempted module-EVALUATING file (P1 no-nixpkgs-dependency stays global; P2 "never operates the module system" relaxed for this one crossing file). Placement decided KEEP-in-gen-bind (crossEval imports nothing — operates a threaded lib; no real boundary moves; gen-merge rejected — byte-identity on arbitrary opaque slices needs the terminal's real lib).
API: `adaptArgs { adapt, module } -> args -> module` (inject `_module.args = adapt args`; PURE, module-producing); `crossEval { lib, module, specialArgs?, moduleArgs?, absorb? } -> evalModules result` (nest opaque slice in the terminal's THREADED lib, freeform absorber; read `.config`); `configGate { gate, module, adapt?, absorb? } -> args -> module` (= `mkIf (gate args) (crossEval …).config`).
★ BOUND (module-system fundamental, tested): configGate gates CONFIG via `mkIf`, NEVER `imports` → CANNOT conditionally DECLARE an option (the `imports←guard(options)←options←imports` cycle); the common case (guard reads an option declared ELSEWHERE) is SOUND. Nested crossEval strips `_module` from `.config` → the OUTER terminal must hold the gated keys (real host options in den-hoag).
CONSUMER MAPPING (output-modules.nix:560-765): argEnvWrap case-2 → `adaptArgs`; case-3 (eval-time guard ± adaptArgs) → `configGate`; placeRemapped → `crossEval` then den-hoag PLACES (setAttrByPath route.at + removeAttrs [_module warnings assertions]). Placement/content-strip stay den-hoag. forwardModulesFor's item-applied guardApply is a CONTENT-gate (not this eval-time config-gate) → partial fit, out of scope.

## G5 — gen-pipe declaration-site id (github:sini/gen-pipe @5350930, PUSHED, lib/operators.nix)
API: deriving-op record gains optional `site`; `mkDerived` folds `id = if site==null then "<input>.<op>" else "<input>.<op>#<idOf site>"` (idOf duck-types registry-entry id_hash / string / int).
★ CONTRACT: `site` is a caller-threaded STRUCTURAL token — fully-automatic disambiguation is IMPOSSIBLE in pure Nix (breaks value sharing; lambdas unhashable). Invariant = "share iff same derivation": same value+site dedups everywhere; distinct decls with distinct sites never collide; site propagates through input-id stacking → distinct at EVERY depth. `site` NEVER leaks into the final channel NAME (compose recomputes `<input>.<op>.<declIndex>`). `site=null` ⇒ byte-identical (back-compat).
CONSUMER (default.nix:1368-1422): pass `site = <stable per-pipe-declaration key>` on each deriving stage in compat/pipe.nix `compilePipe` — the owning policy/aspect entry's `id_hash`, or the pipeOp's `imap0` positional index (pure/deterministic, NOT the mutable `ord` fold-accumulator). Deletes `renameChain`/`ord`/`udBaseCount`/`renamedPipes`; `derivedBaseNames` terminal-id→name still resolves.
★ REVIEW FLAGS (review-gen-pipe): (1) dedup is LOAD-BEARING — SAME site on separate constructions = ONE node; two independent pipe decls that must NOT merge need DISTINCT sites even if structurally identical (a per-decl positional index gives that); a genuinely shared derivation must carry the SAME site everywhere. (2) PLACEMENT — one site at each chain ROOT propagates to all depths via input-id stacking; but if two chains share a prefix and DIVERGE, put sites at the divergence point, not just the root. (3) keep site tokens (and base channel names) free of `#` — hex id_hash / int indices are safe; the opaque-string-id model aliases on `#`/`.` under crafted names (N1, PRE-EXISTING latent, unreachable for intended callers). (4) `idOf` interpolates id_hash as a string — non-string id_hash would throw (N2; hex in practice). site never leaks into channel NAMES (E4b / name-reads unaffected).

## G6 — gen-scope inheritSet (github:sini/gen-scope @ceabe5e, PUSHED, lib/resolve.nix)
GAP FINDING: the accumulation MECHANISM already existed — `inheritAll { extract }` (P-edge parent-chain, cycle-safe, demand-driven; den-hoag `inherited-context` already uses it, structural.nix:43). The genuine gap was the SET-discipline sibling (inheritAll is ordered-list, keeps dups).
API: `inheritSet { extract, eq ? (a: b: a == b), _visited ? {} } self id -> [value]` (own ∪ every ancestor's, down P-edges, deduped by `eq`, nearest-first order retained, delegates the walk to inheritAll).
CONSUMER (retire `__denSuppressedPolicies`): declare a kernel attribute `suppressedPolicies = scope.inheritSet { extract = node: node.decls.suppressedPolicies or []; }` fed from a TYPED decls slot (not the `__` marker); gate reads `self.get id "suppressedPolicies"` instead of `ctx.__denSuppressedPolicies` (default.nix:1050 / compat/compile.nix:85).
★ BONUS CORRECTNESS: inheritSet gives true self∪ancestors UNION → fixes the latent bug where the current single-key `//`-shadow only works because suppression is sibling-isolated to ONE root (`inherited-context` merges `layer // acc` at structural.nix:56, so a single-key list `//`-SHADOWS across two suppressing ancestors, dropping the farther). Multiple suppressing ancestors at different depths now compose, matching v1 dispatch-policies.nix:15-33 by construction.
★ WIRING CAVEATS (review-gen-scope, downstream in den-hoag — not defects in the primitive): (1) the typed `suppressedPolicies` decls-slot must NOT re-leak into generic inherited-context — attr 1 (structural.nix) strips only `__edges/__containment/__coords`, so either ADD the slot to that strip list OR read the attribute from an off-decls source. (2) the gate `gateSuppression` reads `ctx.__denSuppressedPolicies` (compat/compile.nix:85) — switching to a typed attribute needs ctx-injection of `suppressedPolicies` at dispatch (attr 4). (3) do NOT conflate with `reachableFrom` at identity.nix:62 — that is instance fill-acyclicity, UNRELATED; inheritSet's own cycle-safety comes from inheritAll's `_visited`. The half-(b) firing-gate reachability (if used) is a separate mechanism, not that call site.

Links [[project_denhoag_effects_audit]] [[reference_gen_lib_capability_map]] [[feedback_route_through_gen_native]] [[project_denhoag_kernel_primary_surface]].

──────── archive-reference_gen_lib_capability_map.md ────────
---
name: reference_gen_lib_capability_map
description: "gen ecosystem capability map — 21 libs, one line each (what to REUSE before building). The reuse-scan lookup for [[feedback_reuse_scan_before_build]]"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9ea92e54-1c53-4d70-b148-681defc591a4
---

The reuse-scan lookup: **before building any engine/mechanism, check here first.** Roles are durable; verify file:line against current code before asserting. Full detail: gen/ARCHITECTURE.md + gen/README.md ([[reference_gen_docs]]).

## The evaluation/resolution stack (the "engine" — most-often-reinvented; check HERE first)
- **gen-resolve** — ★ THE demand-driven **stratified-fixpoint conductor** (the convergence LOOP, `gen-scope.circular`; cold+warm). Equation vocabulary: `attr` (per-node value) / `nta` (bounded-NTA node synthesis, Vogt'89) / `cascade` (folds pre-declared layers) / `reference` (RAG requires→provides value-composition). `buildSchedule` = N-stratum order + strictly-below assert. **If you're about to build a "stratified fixpoint / lattice-Datalog / resolution engine" — it's this, extend it.**
- **gen-scope** — the demand-driven **HOAG/RAG attribute-grammar evaluator** ("Nix IS the evaluator", `lib.fix` lazy memo = free memoization + cycle detection). `buildNodes`, `queryReverse`, `eval`. The evaluation substrate gen-resolve drives.
- **gen-dispatch** — the pure relational **dispatch STEP** (one stratum's rule eval). loop⊥step split: gen-resolve = loop, gen-dispatch = step.
- **gen-graph** — accessor-based **graph queries**: `labeledFrom`/`query`/`regex` (Brzozowski labeled calculus), `fixpoint`/`seededFixpoint` (monotone semi-naive), **`transpose`** (reverse edges — Mokhov 2017), `order`/`phaseOrder`, `transitiveReduction`, genericClosure BFS. **Reverse reads + reachability fixpoints already here.**
- **gen-algebra** — pure primitives: **`foldLayers`/`foldLayersTraced`** (the ordered-monoid discipline folds + traced provenance), `record` (Leijen/Bracha), `intensionalEq`, search monad. **The lattice/merge folds are here — don't hand-roll a parallel layered fold.**

## Concern / L2 libs
- **gen-edge** — edge algebra (S,T,P,M) + **the materialization terminal** (`toposort`+`materialize`) + parity trace E.
- **gen-product** — **graph products** over accessor-graphs (cartesian/tensor/strong/lexicographic adjacency; cells/slices/fiber/restrict/quotient; `containmentChain` = subset powerset + count-major linearization). The matrix/coordinate engine (feature #2). NOTE: the subset lattice is emitted as a sorted LIST, not adjacency — `latticeGraph` accessor was genuinely absent as of 2026-07-20.
- **gen-settings** — layered settings folds (Spike-5; identity refs; per-entry-lazy provenance; `resolveAll`).
- **gen-demand** — typed **cascade**: downward-only kind DAG, SPAWNS sub-demands (route→secret+connect), groupBy dedup, provenance. The DAG-aggregation fragment (no lattice, fire-once); being absorbed into gen-resolve `nta`+edge (2026-07-20). ★ its SPAWNING cascade ≠ gen-resolve's layer-folding `cascade` — don't conflate.
- **gen-pipe** — scoped channels / dataflow DAG (`append`/`fold`/`for` = ORDER-BEARING monoids — never ACI-ify; class tags; static-config-dependence taint).
- **gen-class** — class-share (partition/contract/apply/gate + `applyCoreFixed` fixed-input core injection).

## Module-system substrate + boundary + selectors + standalone
- **gen-prelude** — pure nixpkgs-lib-free utility base (toposort, partition, genAttrs).
- **gen-types** — structural checker (`verify: v→null|err`).
- **gen-merge** — byte-mode `evalModuleTree` (pure `lib.evalModules` reproduction) + the 14-field nixpkgs optionType protocol (pure types mount in real nixpkgs evalModules).
- **gen-schema** — typed registries + `id_hash`/`edgeId` identity + `keySemantics` per-key category surface.
- **gen-aspects** — aspect type system (`aspectSubmodule` generic dispatch over keySemantics; A-IDENT `.key` = intrinsic path identity).
- **gen-select** — selector/predicate algebra (`sel.entity`/`sel.kind`, `intensionalEq`). Use for production `from`/`where` predicates.
- **gen-bind** — inject bindings into NixOS modules (merge strategies, lazy contracts, `wrapAll`, `__configThunk` deferral).
- **gen-flake** — the SINGLE nixpkgs boundary (`compose`/`injectArgs`/`mkSystems`; `mkSystemTerminal{evaluator}`; value-injection not type-driving).
- **gen-rebuild** — pure-Nix incremental rebuilder (standalone).
- **gen-vars** — pure vars/secrets lib (standalone).

──────── archive-reference_gen_repo_clone_location.md ────────
---
name: reference_gen_repo_clone_location
description: All gen-* libraries clone under ~/Documents/repos/sini/ (not ~/Documents/repos/)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 64d6f7c2-8cd7-4b89-9d3f-643302e3b3cf
  modified: 2026-07-26T04:33:52.923Z
---

All gen ecosystem libraries (gen-resolve, gen-graph, gen-product, gen-algebra, gen-schema, etc.) clone under `~/Documents/repos/sini/<lib>`, NOT `~/Documents/repos/<lib>`. Same parent as den-hoag (`~/Documents/repos/sini/den-hoag`). When a gen lib is only a flake input (store src), clone it here for local dev/TDD and test den-hoag against it with `--override-input den-hoag/gen-resolve ~/Documents/repos/sini/gen-resolve` (gen-resolve is transitive under den-hoag's `path:..` ci input).

The rule is: clone parent directory mirrors the git remote root (`github:sini/*` → `~/Documents/repos/sini/*`). This covers the ecosystem hub repo `gen` itself, which moved here 2026-07-25 — see [[reference_gen_docs]].

All 24 repos (`gen` + 23 `gen-*`) plus den-hoag are indexed in the codebase-memory knowledge graph, each as its own project named `home-sini-Documents-repos-sini-<repo>`; pass that as `project` to `search_graph`/`trace_path`/`query_graph`. Cross-repo-intelligence mode yields 0 edges — it matches HTTP/async Routes/Channels, which pure-Nix libs don't have — so cross-lib call chains must be traced per-project, not through the graph.

Related: [[reference_den_remotes]], [[project_gen_resolve]], [[reference_gen_docs]], [[reference_gen_lib_capability_map]].

──────── archive-project_gen_resolve.md ────────
---
name: project_gen_resolve
description: gen-resolve — pure-Nix RAG schedule-conductor; v1 SHIPPED+PUBLISHED+HUB-WIRED+4-lens-REVIEW-HARDENED 2026-07-01 (github:sini/gen-resolve @56209bb, gen hub @df5baf7)
metadata: 
  node_type: memory
  type: project
  originSessionId: a899d097-53e9-43c6-94cd-81a083cef686
---

**gen-resolve** = a NEW gen library, the demand-driven, incremental, **higher-order reference-attribute-grammar evaluator over algebraic scope graphs** — the "attribute grammar evaluator over algebraic scope graphs" our specs named in passing but no lib owned. Composite/assembler tier (peer of [[project_gen_derive]]).

## ═══ 2026-07-04 MODULE-SYSTEM BENCHMARK VERDICT: KEEP — quantified win + quadratic fixed ═══
Pre-den-hoag audit "perf gain or over-engineering?" ANSWERED with benchmarks (report: `gen-specs/gen-merge/2026-07-04-module-system-benchmarks.md`; harness = parity-oracle P-trick scaled, 3 stacks, digests byte-identical everywhere). **Post-fix pure stack beats pinned nixpkgs.lib on EVERY den shape: aspects-1600 2.80×, registry-2000 2.27×, schemaHosts-1600 1.77×, scalar-16k 1.59× cpu; 2–3.6× less allocation; 936 vs 4225 engine LOC.** Clears the hola-E1 vendoring counterfactual (ownership-for-free but keeps nixpkgs cost profile); consistent with zen's lean-engine ceiling while keeping byte parity. **AUDIT FINDING (fixed): `prelude.unique` key-union was O(k²) in sibling-key count** (scalar-8k pure was 5.4× SLOWER than nixpkgs, 16k=1.76s vs 0.14s) at gen-merge modules.nix cfgKeys + types.nix attrsOfWith/mergeAnythingVals → attrset-fold union, linear (156→6.8µs/item; nixpkgs 11). **gen-merge 976a87a PUSHED to main 2026-07-04**; `prelude.unique` itself left general (order-preserving); gen-schema identity.nix:29 apply-use = small lists, not hot. Honest scope: wins are COMPOSITION-plane (den CI/fleet/dispatch/den-hoag internals); single-host NixOS eval stays terminal-dominated (hola 94%).

**PERF-REGRESSION HARNESS SHIPPED (gen hub 503a3a3, pushed, GH CI green):** `nix run ./ci#perf-bench` = ci/perf-bench.nix corpus (provider-P, pure vs frozen ref) + perf-bench.sh gates — per-cell digest PARITY (fast-but-wrong can't pass), RATIO ceilings (pure cpu ≤0.85×ref, thunks/alloc ≤0.90×; measured 0.35-0.66), LINEARITY (counters ≤5.5× per ×4 step; retro-catches the unique bug class ~11.5×). GH workflow gained `checks` (parity oracles were NOT in any CI job before!) + `perf-bench` jobs; locks bumped to 976a87a. Ratios machine-independent (GH runner 0.346 vs local 0.349 on aspects-1600). Doc: gen/ci/README.md + papers report addendum. **TRUST-RELEASE SLICE 1 COMPLETE 2026-07-05 (all 10 tasks incl owner-added 7b; roadmap `2026-07-04-gen-v1-trust-release-roadmap.md` + plan+tasks.json):** hub BENCHMARKS.md (regenerable `--update`, composition + compat + FLEET sections) + VALIDATION.md (15 libs/1745 tests fresh; §6 fleet gates) @338d5f7 CI-green; gen-merge compat suite @469dcf3; hola A1 campaign PUBLISHED @d643a8d (22 commits, fleet-gates CI green): G6 split 42.5%fc/5.2%copies, Arm-R 66.7% byte-sound, Arm-C +4.6% scope-mismatch, 7b ~1.6%/member + 212-unit core, spine ~98% ⇒ **A3 RE-SCOPED to `gen-class` lib** (owner 2026-07-05; tiers in roadmap; interface = den-hoag r2 seam contract; gates migrate to gen-class ci). Papers: A1 report `2026-07-05-a1-fleet-measurement-report.md` (uncommitted). **GEN-CLASS V1 COMPLETE 2026-07-05 (all 10 plan tasks, two-stage-reviewed):** github:sini/gen-class @218c54f+ (90 tests, purity+fence teeth, synthetic corpus w/ independent oracle pin); gen-merge fixed-input kernel @2ad1099 (coreShortCircuit, sole-def rule, byte-identical 3 ways, 78.7% fcall cut on fixture); hub mkGenLibs.class + perf-bench classShare gate (~5.8× spine reduction, thunk ratio 0.17, floor ≤0.30 = ≥3.33×, byte-gated) @7872817; hola lab re-pointed + Arm-C terminal-pessimal pinned (+1.65% fleet, byte-sound) + precommit override superseded by mkCi wrapper @4bab613; r2 seam-amendment note written (papers gen-specs/gen-class/ — the den-hoag PROPOSAL: Class/Core/Axis records, output-modules/wrap landing, firing contract, tier-3 obligations incl boundary-from-aspects WITHOUT force-probing). Slice-1.5 done (mkCi ulimit @6d259ef, hub precommit fix @d623768). **NEXT = A2 gen-flake observability→v1 redesign (seed: RESUME-trust-release-a2.md in gen-specs) + B3 lint/B4 harness parallel; then A4/B5/A5; den s1/s2 publish = OWNER decision (§8a-D5) still parked.** Protocol findings (durable): gc bytes non-deterministic; version strings ≠ evaluator identity (−8 primops, two-tier gates exact/0.1%-band); resolution-layer witness = open problem. **Q1 flake-parts compat = tiered boundary verdict:** tier1 value-injection (shipped) / tier2 portable byte-mode subset (cheap, on demand) / tier3 full compat NOT viable with speedups — killers = options-introspection (isDefined/definitions = the alloc we shed) + typeMerge functors; flake-parts uses ZERO mkOrder/mkBefore/mkAfter. **Q2 adios lessons:** memoized override w/ reverse-cone diff via genericClosure (validates warmResolve shape; design for gen-flake incremental override); genericClosure keyed module dedup (gen-merge collectModules has NO diamond-import dedup — den-safe boundary, note not code); adios-flake BENCHMARKS.md convention (their real-flake 1.3-1.4× vs our composition 1.6-2.8× = terminal dilution quantified); do NOT take last-wins//no-priority. **Q3 nixpkgs-types compat shim = ZERO adapter code** (nixpkgs types already speak (loc,defs) + property _type tags byte-compatible; `import gen-merge { prelude; types = lib.types; }`), byte-identical, leaf types FREE (0.62×ref = pure) but structural types give the whole win back (submodule.merge runs lib.evalModules per instance → 0.96×ref) → frame as opt-in migration/escape-hatch plugin, not ecosystem fast path.

## ═══ STATUS 2026-07-01: v1 SHIPPED + PUBLISHED + HUB-WIRED + 4-LENS-REVIEW-HARDENED ═══
Built T0→T12 from the plan (`2026-06-30-gen-resolve-v1-plan.md`), then hardened by a 4-lens adversarial review + delta re-review. **`github:sini/gen-resolve` @56209bb** (58 nix-unit tests + 3 §5 examples green, `lib/` nixpkgs-lib-free). **Wired into gen hub** `mkGenLibs.resolve` (@df5baf7, published-ref verified: 15-op resolve surface). **Class B = 5 gen siblings** (scope/graph/rebuild/algebra/bind); **gen-prelude is transitive-only** (the `.lib` takes NO direct prelude — classkey was its only user, now dep-free; input kept for the standalone default.nix shim). Layout mirrors gen-derive; tracker SSOT + REFERENCE.md at `gen-specs/gen-resolve/`.

**CROSS-REPO changes this build (all pushed):** **gen-bind @4dcdea0** — root-caused + fixed a real bug: the collision validator did `builtins.seq checks {warnings=checks}`, forcing `config._module.args` at module-collection WHNF → `.all` infinite-recursed through evalModules (its stated purpose). Fixed to lazy `{warnings=checks}` (+regression test). **gen-scope @f8ecbef** — NEW `queryReverse` (reverse-of-imports gather, dual of queryAll) that powers `reference target=neededBy`.

**4-LENS REVIEW (quality / idiomatic-Nix / theory-conformance / spec+den-hoag) → NO publish blockers; every finding FIXED + DELTA-RE-REVIEWED → all CLOSED.** Substantive fixes: **cascade `combine` made real** (was asserted-then-ignored — now a foldLayersTraced STRATEGY string `{replace(=shadow,default)|append|recursive}` threaded per-field over allKeys; a function combine now throws; design §6 signature updated to match); **`reference target=neededBy`** wired via the new gen-scope.queryReverse (was a no-op); **classkey de-`prelude`'d**; **cross-node warm-serve TESTED** (`override-cross-node.nix`: declared→byte-identical, undeclared→STALE witness = the soundness-(c) proof); **NTA-memo `x==x` tautology dropped everywhere** (memo unobservable in pure Nix); M1 circular+structural + mixed-SCC tested; citation honesty (AFFECTED=sound OVER-APPROXIMATION not "the reverse cone"; Knuth-acyclicity-only gate not "Vogt HOAG"; Neron+den-hoag§B2 anchor not Statix §4.3).

**DEN CARRY-FORWARDS (Phase-1 must honor):** M1 — author `enriched-context` as `attr{kind="circular"; stratum="structural"}` (explicit stratum honored for ANY kind; a "conform stratumOf to synthesized-only" refactor would break all of den, now test-guarded). soundness-(c) — `declaredEdges` MUST over-declare cross-node reads or a consumer outside the cone is served STALE on override. m4 — gen-bind error-strategy collisions now surface only when `config.warnings` is forced → den non-NixOS classes (nixidy/colmena) must force warnings/assertions. m5 — classKey's function-sentinel erases closure arg-shape → defunctionalize parametric args to data before the keyed attr. **Consciously-accepted documented NITs** (not fixed): name-only `why` provenance, schedule `readsAttrs` typo-filter, purity `#`-in-string assumption. **Ecosystem follow-ups:** purity-scanner holes (`#`-in-string + non-leading-`lib`-arg, all libs); gen-scope `resolveNode` unconditional `children` read (den always declares children, so den-safe).

**LOAD-BEARING DECISIONS (DP1-DP6, beyond D1-D14; all HELD in the shipped impl):**
- **DP1** two-stratum labeling = hybrid-B: kind-derived (`{nta,inherited}`→structural, `{cascade,reference,circular}`→resolution); `synthesized` carries explicit `stratum` (default structural, over-declare-safe; `terminal`=sink exempt). gen-resolve owns the CHECK, den owns the LABEL. Closes the hole where structural `imports` reads resolution `resolved-aspects` (van Antwerpen §4.3).
- **DP2** thin `materialize` (forces `output-modules`) + `terminalBind`(=`gen-bind.wrapAll`→.all); binding assembly stays den-side.
- **DP3/DP6** v1 `override`/`warmResolve` = **topological reverse cone** (`gen-graph.dependentsOf`) for `isClean`, NOT `gen-rebuild.affectedSet`/`needsEval`. **FLEET-GROUNDED** (hola, user-directed): exact-AFFECTED hash-detection = 2× the dominant single-thread-bound spine cost intra-eval (E3c NO-GO shape) + only pays cross-eval; cone-restriction base-dominated (hola S2); class-sharing is the fleet lever (Plane-2a 59.7%). Cone = O(|cone|) = design §9's own bound.
- **DP4** `builtCtx` = LAZY unforced `ResolveCtx` field (deferred cross-eval hook); `trace.hash=null` v1 → den's CIRCULAR node graph cold-resolves (gen-rebuild eager cycle-check never trips). **D11 RESCOPED** (design §9+D11 AMENDED 2026-06-30): `needsEval` = cross-INVOCATION reuse gate, not v1 intra-eval `isClean`.
- **DP5** evalModules-equivalence oracle at the TERMINAL (materialized modules vs `lib.evalModules`), NOT the cascade (CSS-last-wins `foldLayersTraced`, deliberately ≠ nixpkgs priority). nixpkgs in `ci/` only.
- **classKey** ships v1 but is a CONSERVATIVE narrowing key (hola E3c-C1): sound reuse needs def-disjoint ∧ fixpoint-closed + a byte-identity (drvPath) gate; contract carries the caveat. `warmResolve` takes `{ edits }` map (design §6 `{changedIds}` can't carry payload in pure eval).

**PRE-DEN-HOAG ROADMAP (current, 2026-07-02): `gen-specs/2026-07-02-pre-den-hoag-roadmap.md`** — supersedes the parallel-paths doc; sequences W0 cleanups / W1 beyond-parity spike / W2 resolve.nix-collision / **W3 pure substrate BYTE-MODE (~1-2 sessions, RECOMMENDED do-first: Korora→evalModuleTree byte-mode→re-host aspects+schema→byte-parity on today's den = zero migration surface for den-hoag)** / W4 readiness residuals (incl #10 pipe-combine now settled by the semilattice-confluence result) / W5 parity slice. The structural/identity FLEET-DEDUP arc is DEFERRED (hola axis, G6 measure-first), NOT pre-work. **NEXT (two parallel paths, older roadmap `gen-specs/2026-07-01-parallel-paths-den-hoag-and-pure-gen.md`, now superseded):** **Path A = CRITICAL = den→den-hoag refactor** — start with the den parity slice (resolve one real structural cone through gen-resolve, diff vs den's intact `materializeUnified` = the parity oracle). **Path B = supporting/parallel = Phase 1 purity** (re-host gen-aspects+gen-schema, Korora + `evalModuleTree` → 10 pure libs; NOT a den-hoag blocker). **den-check 2026-07-01 (verified vs den origin/main):** parity anchor `materializeUnified` CONFIRMED intact in main (#563) → Path A actionable; BUT the hola fleet-sharing *lever* gen-resolve's value points at is **PoC/UNMERGED** (den `feat/s1-per-sid-hostconfig`+`feat/s2-pipe-reads` = `deadbugs/` probes, Plane-2a = gist) → gen-resolve delivers the class KEY, NOT realized fleet sharing (README guardrail softened @70dc4e1); AND Path A's target `nix/lib/aspects/fx/resolve.nix` COLLIDES with the unmerged hola S1 rewrite (~326-line diff) — decide subsume-vs-coordinate before the full swap. **BEYOND-PARITY analysis DONE 2026-07-01 (2 agent passes: spec digest + nix-config harvest), spike DEFERRED to a fresh session:** den-hoag isn't 1:1 parity — it must make relationship/edge/projection patterns (claim/provide cascade, network fabric, host+user projections) TRIVIAL to author. **FINDING = NO new gen library** (substrate sufficient) + at most ONE **deferred** gen-resolve extension (post-resolution `forward` stratum for tier-2 forward adapters — no consumer yet, r2 defers it, keep the two-stratum THROW). The real work is **den-side framework features** dominated by a **k8s-workload archetype** (den classes emit NixOS/home-manager, NOT k8s resource sets; ~23×500-line hand-assembled apps → ~23×30) + reciprocal/provider-push claim + inject-into-workload + typed-collection-with-fold + baseline-edge-emission. Key clarifications: claim cascade = plain downward FOLD not recursive-neededBy (category error); den-hoag has **TWO edge graphs** (gen-resolve attribute-dep DAG vs den/nix-effects delivery `(S,T,P,M)` DAG — DON'T conflate); one gen-adjacent open-Q = k8s resource-set delivery via terminal vs den binding. Immediate wins (no spike): DELETE dead `nix-config/modules/den/scope-engine/settings.nix` (147 lines, 0 consumers); collapse `acl.nix` triple-gate to `sel.groupsClosure`. Full detail: `gen-specs/2026-07-01-beyond-parity-analysis-report.md` (findings) + `2026-07-01-den-hoag-beyond-parity-features.md` (spike seed) + `2026-07-01-parallel-paths-den-hoag-and-pure-gen.md`. Resume seed: `gen-specs/gen-resolve/RESUME-gen-resolve-phase0.md`. Full ecosystem/purity history below (settled).
## ═══ (settled history follows) ═══

**Charter:** owns the attribute-evaluation SCHEDULE — the *static* schedule (attribute-dependency graph + Vogt well-definedness gate + two-stratum partition assert) + the cold/warm fold into `gen-scope.eval` + the intra-eval override chain. Delegates everything else (gen-scope=resolution/warm-eval, gen-graph=topology, gen-rebuild=AFFECTED/cutoff, gen-algebra=`record.foldLayersTraced`, gen-bind=terminal wrap, gen-aspects=grammar/flat-registry=scope nodes).

**Decided:** gen-scope-HOSTED, not a fresh closure resolver (D1). **Intra-eval incremental ONLY** (Reps/Acar warm reuse, pure); cross-edit DEFERRED to gen-rebuild/Adapton-over-gen-scope = the [[project_hola]] fleet plane (D10). Static schedule owned / runtime schedule = demand (Nix laziness = Mokhov §4.1) delegated (D3). attributes consumer-supplied/open via `//` (D4). 14 decisions D1-D14 + 4 open research gates in the spec.

**Theory (CLEAN-ROOM — adios NEVER in the spec):** Knuth 1968 / Vogt 1989 / Hedin 2000 / Hedin&Magnusson 2003 / Néron 2015 (D>I>P) / van Antwerpen 2016 Statix / Reps-Teitelbaum-Demers 1983 / Acar 2002,2006 / Mokhov 2017,2018 / Sloane 2009 / Palmer 2024 **Lemma 5.12** (not Theorem — matches gen-derive REFERENCE+summary) / Lorenzen 2025 / Reynolds 1972.

**gen-derive hierarchy (KEY decision):** loop ⊥ step are orthogonal dimensions (all 4 quadrants occur in den attrs). gen-resolve owns the convergence **LOOP** (circular-attribute Kleene ascent); gen-derive = sibling dispatch **STEP** — **NOT a gen-resolve dependency, no edge either way**; den marries them inside one circular attribute (`resolved-aspects ⇄ policy-effects`). gen-derive was the least-principled gen lib (built loosely to compose libs for demos). **gen-derive REFACTOR + RENAME → gen-dispatch: SHIPPED + PUBLISHED 2026-07-01 (ultracode workflow).** Spike PASSED (byte-identical `gen-derive.fixpoint` == `gen-scope.circular ∘ gen-derive.dispatch`, direct + full-stack, 2 convergence shapes incl the fired-grows-on-converging-pass kill-criterion edge; secondary: `topoSort`/`entry*`==`gen-graph.condensation` reverse-bottomUp). Then a Workflow (map→design→3-lens adversarial verify, 0 blockers) produced the plan (papers `gen-specs/gen-derive/2026-07-01-gen-derive-refactor-plan.md`), executed: **loop=gen-resolve (circular Kleene ascent), step=gen-dispatch (dispatch), ordering=gen-graph (phaseOrder)**. LANDED: **gen-graph** `order.nix` = `entry*`+`phaseOrder` over condensation (reverse-bottomUp; self-loop+non-singleton-SCC throw), pushed `3f57be8`. **gen-derive→gen-dispatch** (github repo RENAMED via `gh repo rename`, redirect live; local dir kept `~/Documents/repos/gen-derive`): `dispatch` takes pre-ordered `phaseOrder` (no internal toposort); `dag.nix`+`fixpoint.nix` DELETED; new `dispatchStep`/`dispatchInit` (driver-agnostic merge fold, prelude-only) pair the step with any loop; 54 tests/10 suites; pushed `ad633a1`. **gen hub** rewired (input+key `derive`→`dispatch`, lock bumped), `mkGenLibs.dispatch` (11 ops), pushed `82d5922`. **sql-schema demo** migrated (loop→gen-scope.circular, order→gen-graph.phaseOrder, rules declare `phase` — required by multi-phase dispatch; the old demo relied on a May-28 gen-derive predating the strict phase-check), **oracle 167/167 byte-identical vs PUBLISHED revs**, pushed gen-scope `1bff817`. Untouched: gen-resolve lib, den, nix-config, nest-traits (nest-traits pins old gen-graph __functor API — do NOT bump). **Spike is a point-in-time proof (baseline needs the now-deleted fixpoint) → kept LOCAL uncommitted at `gen-resolve/spike/gen-derive-loop-step/`; permanent regression = the sql-schema convergence suite.** REMAINING (finish): papers REFERENCE (rename `gen-specs/gen-derive`→`gen-dispatch`, re-charter; gen-resolve REFERENCE gains Sloane 2010 §2.2 loop citations) — UNCOMMITTED, user's call. den marries loop+step inside one circular attr (`resolved-aspects ⇄ policy-effects`) — future den-hoag work (mkDispatchCircular helper deferred there).

**Ecosystem:** den = consumer (`materializeUnified` → a gen-resolve call; den supplies the 12 HOAG attrs, gen-resolve doesn't ship them); hola fleet plane sits ABOVE (host-class key = aspect-include-set = `classKey`, must digest resolved arg-shape not just names — D8). adios (adisbladis) = dev-time **systems reference ONLY**; our model is higher-order + full scope-graph (D>I>P), NOT adios's degenerate single-edge closure. See [[project_hoag_architecture]], [[project_den_hoag_readiness]], [[project_gen_package]], [[reference_gen_docs]].

**Locations:** `~/Documents/papers/den-architecture/gen-specs/gen-resolve/{2026-06-26-gen-resolve-design.md, 2026-06-26-gen-derive-refactor-spike.md}`. Spec independently verified (delegation APIs all real via grep; clean-room clean; sections 1-13; verifier-confirmed fixes applied).

**Open / next:** gen-bind boundary kept as terminal dependency (`wrapAll` is gen-resolve's own terminal op, defensibly ≠ gen-derive's mid-eval step — could still push den-side). NOTHING committed (papers commits = user's call). NEXT = write plan + ship gen-resolve, then run the gen-derive spike.

**Process caveat (durable):** the Workflow `args` global does NOT populate — it renders `"undefined"` in agent prompts. **Inline absolute paths as string literals in workflow scripts; never rely on the `args` global.** This bug caused a sibling-spec corruption (a reviewer wandered out of the target file, the fixer edited the wrong spec); recovered byte-exact from the transcript. Also: scope review/fix agents to a single target path. See [[feedback_gen_lib_docs]] for the lib-docs diligence (REFERENCE + tests cite THEORY) gen-resolve will need on implementation.

**Deferred deliverable — gen-aspects doc-update pass.** When gen-resolve ships, update gen-aspects README + REFERENCE to name gen-resolve as THE canonical pipeline/evaluator (deliberately left OUT of gen-aspects docs until the lib exists — user 2026-06-26). The neededBy overstatement is already refined in gen-aspects README (it's a consumer/den predicate-based reverse-reference, NOT a core edge symmetric with includes).

**⚠ COST RECALIBRATION (2026-07-02) — READ FIRST: the pure-gen module system / Phase-1 re-host is ~1-2 SESSIONS (≈2 days), NOT the "weeks-months" this section repeatedly says below.** The stale estimate was CATEGORY-anchoring ("a custom type + module system sounds huge"); the DELIVERED SHAPE is a Korora vendor (~800-LOC drop-in for the checking half) + a ~7-item `evalModuleTree` merge primitive + a gen-schema registry PROTOCOL-SWAP (collection logic is already pure Nix riding `deferredModule.merge(loc,defs)`; the port swaps the provider to gen-resolve, pure logic untouched — NOT a duration-dominant rewrite), TDD against the evalModules-equivalence oracle, with adios/Korora/zen/nixpkgs-lib as references. Peer-effort proof: gen-resolve (HOAG RAG evaluator over 10+ papers, 58 tests), gen-rebuild (Mokhov, 211 tests), hola (byte-identical `evalModules` ownership) EACH shipped in ~2 days. Only real risk axis = external-oracle SURFACE (7-item may prove 8-9 once den's live usage hits it → maybe +½ session), NOT duration. See [[feedback_estimate_delivered_shape]]. (All inline "weeks-months" below is superseded by this note.)

**⧉ NEW DESIGN ARC (2026-07-02) — structural equivalence + identity-keyed pre-eval dedup.** Composition-plane correctness bar EVOLVED byte-identical → **structural equivalence** (coarsest observational congruence, Reynolds) → unlocks a **confluent merge** → makes a **pre-eval intensional identity key** a congruence → **hash-cons/dedupe the merge graph BEFORE eval** + share resolved sub-cones cross-host (the fleet plane). Byte-identity KEPT only as dev/cut-over conformance oracle + NixOS terminal contract; non-NixOS (k8s archetype) has no byte oracle → structural only. Palmer intension + `itsInspect` wall (theory-audit A1) sidestepped by **defunctionalizing args to data (m5)** → Merkle key `id(n)=H(kind,name,argData,{id(dep):dep∈reads(n)})` over the STATIC scope graph (pre-eval computable; cycles via gen-graph.condensation). `id` = pre-eval PREDICT dual of v1 `classKey` (post-eval CONFIRM). DECISIVE gate = key-cost ≪ node-cost (hola E3c measured ~2×). Falsifiable spike (intra-host = ∆-Nets Rung 2 premise + Rung 4 hoist-by-identity; cross-host arm NEW). Full spec: `gen-specs/gen-resolve/2026-07-02-structural-identity-dedup-spike.md` (Rev 2, theory-discharged). **ADVERSARIAL REVIEW DONE 2026-07-02** (ultracode workflow wji8lny7r, 9 reviewers × full-paper reads, 49 findings upheld / 8 refuted; report `…-REVIEW.md`) → spec CORRECTED. Load-bearing fixes now IN the spec: (1) Merkle key was UNSOUND — flat id-multiset drops D<I<P specificity → false merge; fixed to `sortedMultiset{(labelSeq,rank,id(d))}`. (2) "pre-eval" over-reached — split declared-literal imports (pre-eval reads) vs config-computed/NTA (G2 dynamic tail; Vogt is a counterexample not support). (3) NEW decisive gate **G6 = merge-layer must be a material FRACTION of fleet-total cost** (dominant cost = N evalModules fixpoints per GENEROUS-BUILDS §6 wall-1 / "cortex 36s=94% derivation-construction") — **MEASURE G6 FIRST, it can kill the whole arc cheapest**. (4) confluence re-grounded on Datafun bounded-join-SEMILATTICE (comm+assoc+idempotent → order-independence AND circular-strata least-fixpoint via Lemma 4) + Radul pattern; foldLayersTraced downgraded to "must satisfy the discipline" (last-wins is non-commutative; a++b non-idempotent). (5) CITATION fixes: ≈ₛ was miscited to Reynolds (→ Morris1968/Plotkin/Pitts); ∆-Nets DEMOTED to foil-only ("interior sharing = hash-consing" = the killed IMPACT #13 overclaim; use Wadsworth1971 DAG-sharing + Lévy1978 + Barendregt1987); Lorenzen2025 added as the pre-eval-inspect keystone; Adapton promoted to first-class intra-eval precedent; Reps/Acar are post-eval → classKey not id; static schedule is Kastens1980 not Knuth1968; defunctionalized-data key soundness = Reynolds not Palmer (Palmer §6.1 cross-module dedup is his OPEN question). NEXT = run spike in order: measure G6/H4 (fleet-total split) → Fleet-Sharing-Net observable (Rung 0→1, ~50 LOC) → defunctionalize one heavy aspect + Merkle-key + assert id-collision⟹≈ₛ (H2 must try an order-swapped/ambiguous read). Data-quality: reynolds-1972 full text PULLED 2026-07-02 → H-12 (≈ₛ miscite) + M-2 (defunctionalization anchor) VERIFIED against primary text (0 occurrences of observational/contextual/congruence/equivalence in the whole paper; defunctionalizes FUNVAL→ENV→CONT). Reynolds citations in the spec now primary-text-grounded.

**END GOAL — pure-gen module system (Vic's aspiration; the ORIGIN of this whole journey).** The real aim: a pure-gen module system (à la adios/zen) with NO nixpkgs-module-system dependency — "pure lib, no evalModules" like adios. **CORRECTED FINDING (audit 2026-06-26 — the earlier "one cut / tether isolated to gen-aspects / gen-schema=Korora-equivalent" was WRONG; full audit at gen-specs/gen-prelude/2026-06-26-gen-ecosystem-purity-audit.md):** the lib.types/evalModules tether spans **4 of 10 libs** — gen-aspects (grammar) + gen-schema (registry) DEEP; gen-vars + gen-algebra SPLIT (pure/ clean, module/ tethered). **gen-bind CORRECTED to PURE-with-vendoring** (audit first mis-verdicted it blocked; its setFunctionArgs/setDefaultModuleLocation are module-CONVENTION helpers = AWARE not DEPENDENT, vendor ~6 LOC gen-bind-local; production-bound, remediation note gen-specs/gen-bind/2026-06-26-purity-remediation.md w/ evalModules equivalence-test gate). **gen-schema is NOT the Korora-equivalent — it IS lib.types + evalModules (entry-type.nix:223).** PURE substrate = gen-graph/select/scope/derive/rebuild/**gen-bind** (+gen-algebra/pure), decouple via ~150-LOC vendored **gen-prelude** (CHEAP, hours; builtins cover most, ~18 genuinely-vendored fns). Type/grammar/registry layer (~4 libs) needs a **VENDORED KORORA** type system (~1-2 sessions/≈2 days — NOT weeks-months; see COST RECALIBRATION note + [[feedback_estimate_delivered_shape]]) — gen-schema cannot fill it. adios→gen map: Korora→**vendored Korora (NOT gen-schema)** · loadModule/loadTree→gen-aspects grammar (re-host) · inputs+genericClosure→gen-scope+gen-graph (BETTER: Néron D>I>P, not single-edge) · evalModuleTree+override→gen-resolve · mergeOptionsUnchecked→gen-algebra foldLayers · dispatch→gen-derive · binding→gen-bind. nixpkgs re-enters ONLY at the optional terminal (gen-bind→evalModules, one eval/host, NixOS targets only). UNLOCKS: nixpkgs-independence for composition (escapes hola's immovable //-storm/merge floor — that floor bound only compat-PRESERVING frameworks; pure-gen SHEDS nixpkgs content for composition = the path [[project_hola]] DECLINED); native intra-eval incremental (gen-rebuild); cross-host fleet eval-sharing (the hola fleet plane); a module system for non-NixOS domains; substrate-convergence with [[project_zen_vic]] (zen proved 3-10× intra-eval but has NO cross-scope sharing — pure-gen+gen-resolve generalizes it). PATH: **Phase 0** gen-resolve (eval engine; grammar still on lib.types here) → **Phase 0.5** gen-prelude pure-substrate decouple (CHEAP, hours; gen-specs/gen-prelude/) → **Phase 1 KEYSTONE (~1-2 sessions/≈2 days — NOT weeks-months; see COST RECALIBRATION note + [[feedback_estimate_delivered_shape]])** vendor Korora + re-host gen-aspects grammar onto it **BYPASSING gen-schema** (submodule=nested registry, deferredModule=lazy constructor; merge adios-SIMPLE, NOT nixpkgs lib.types; pure-DEN additionally needs gen-schema's registry engine re-hosted = dominant cost since den entities ARE gen-schema registries) → **Phase 2** terminal bridge (gen-bind→evalModules, opt-in per target) → **Phase 3** zen/adios-scale pure-gen demo + fleet-sharing demo (the artifact for Vic). CAVEAT: the pure composition plane CANNOT directly consume nixpkgs NixOS modules in-composition — they are OUTPUT (deferredModule class content) handed to the terminal; adios accepts this same trade.

**KORORA DECISION 2026-07-02: BUILD `gen-types`, do NOT vendor Korora.** Korora is **LGPL-3** (NOT MIT — earlier note/spec was WRONG; whole gen ecosystem is MIT → vendoring+modifying = copyleft contamination of the type layer) + ~570 LOC of zero-novelty standard structural typing (verify:v→null|err + builtins.is* wrappers + obvious poly combinators) + **gen-schema already owns the checking pieces** (refined.nix/validate.nix are 0 lib.types refs = already pure; strict.nix has 2). So build a clean-room MIT `gen-types` as a **gen-schema `lib/types/` component** (leaf/poly checkers + fold in existing refined/validate/strict), graduate to standalone later only if warranted; clean-room from gen-schema + papers (Leijen/Findler/Chitil/Rondon/Palmer), NOT transcribed. entry-type.nix's lib.types/evalModules is the MERGE engine (→ evalModuleTree), a separate concern. Korora read only to confirm "nothing to vendor." (Below GO/NO-GO framing kept for history; superseded by this.)

**SUBSTRATE BUILD IN PROGRESS 2026-07-02 (module-system Track 1).** Two NEW libs approved + being built by parallel agents: **gen-types** (standalone LEAF lib `~/Documents/repos/gen-types`, MIT clean-room checker, gen-prelude-only, folds in refined/validate/strict) + **gen-merge** (NEW lib `~/Documents/repos/gen-merge` = the byte-mode module MERGE engine `evalModuleTree`; NOT inside gen-resolve — gen-resolve stays the schedule-only CONDUCTOR; docs conflating "gen-resolve's evalModuleTree" are WRONG — gen-merge = within-node def-merge, gen-resolve.foldLayersTraced = cross-node cascade, distinct layers). **Layering: gen-prelude → gen-types → gen-merge → {gen-schema, gen-aspects} → gen-resolve.** gen-types MUST be standalone (a merge engine below gen-schema consumes it → flake-input cycle if nested). B1 design spec `gen-specs/gen-resolve/2026-07-02-evalmoduletree-byte-mode-design.md` (7-item merge primitive + oracle). **PRIORITY-SUBSET WIN (grepped, not assumed):** den+gen use ONLY mkIf/mkDefault/mkForce/mkMerge — ZERO mkOverride/mkOrder/mkBefore/mkAfter → byte-mode = ONE min-priority-wins rule + mkMerge + mkIf, DROP the entire nixpkgs ORDER pass = closed surface, kills the oracle-completeness risk. Meta-plan `gen-specs/2026-07-02-pre-den-hoag-meta-plan.md`; native tasks A2(gen-types)/C1(gen-merge, ID#6)/C2/C3/C4.

**MILESTONE 2026-07-02: 3 of 4 substrate pieces DONE + PROVEN (all uncommitted, local, for review).** (1) **gen-types** — standalone leaf `~/Documents/repos/gen-types`, 105 tests, purity-teeth, gen-prelude-only. (2) **gen-merge** — `~/Documents/repos/gen-merge`, byte-mode merge engine, 46 tests incl a byte-identical-vs-nixpkgs oracle (+nullOr/either/oneOf fixtures); during C3 it fixed 2 REAL gen-merge bugs AT SOURCE = top-level `_module` drop (marker misclassification) + option-decl merge-by-replace (broke ref apply-override), both behind the oracle w/ regression tests. Priority = grepped one-rule subset; **nixpkgs collects defs in REVERSE module order — gen-merge reverses to match**. (3) **gen-schema RE-HOSTED (C3)** — worktree `c3-rehost` @ main 2b7c2d3: 398/398 corpus, lib/ nixpkgs-free, + a byte-parity oracle proving a den-shaped schema byte-identical through re-hosted-vs-nixpkgs incl **id_hash SHA identical** (361953da…, the strongest exactness proof); gen-schema now RE-EXPORTS `genSchema.{mkOption,types,evalModuleTree,mkMerge}` as the facade so den never touches nixpkgs. Corpus migration (93 files) done by a subagent it reviewed. **(4) gen-aspects RE-HOSTED (C2) DONE** — worktree `c2-rehost` @ main 87bf758 (includes A4): 110/110, lib/ nixpkgs-free, + a grammar parity oracle (flatten node-set + guard-fn wrap byte-identical to old nixpkgs grammar, w/ teeth). A4's `__guard` branch + `guardKey` + guard.nix + flatten `__guard`-leaf PRESERVED verbatim. **functionTo DROPPED** → the raw-guard-fn wrap is reproduced as a hand-built FUNCTOR `{__functor; __functionArgs; __isWrappedFn; name; meta}` — the `__functionArgs = ⋃ functionArgs(defs)` detail (nixpkgs setFunctionArgs) is load-bearing (a test checks `args={host=false;user=false}` + `lib.isFunction wrapper`). **ZERO gen-merge changes needed** (the C3-era `_module`/decl-merge source fixes already covered it). **(5) C4 WHOLE-STACK BYTE-PARITY DONE + GREEN** — `~/Documents/repos/gen/ci/rehost-byte-parity.nix` (validation only, den read-only): pure stack (gen-types+gen-merge/evalModuleTree+re-hosted gen-schema+re-hosted gen-aspects) == nixpkgs across 3 fixtures — schemaFleet (host kind + id_hash SHA), aspectTree (class content + guard wrap + flatten), integrated (schema-declared `priority` threaded into aspect instances = the C2×C3 composition) + a den-shaped realism sample, all byte-identical, both-evaluated + mutation-teeth. **⇒ TRACK 1 (pure-gen module system Phase 1) COMPLETE + byte-parity-proven end-to-end, ALL UNCOMMITTED for review.** Corpus finding: gen flake DEMOS are flake-parts TERMINAL-plane (import-tree + `lib.types.lines`), NOT composition-runnable → C4 validates the COMPOSITION plane (what the re-host changed) via the demos' SHAPES + the den sample; the terminal/output plane is unchanged nixpkgs. **REAL-DEN C4 battle-test DONE (`gen/ci/rehost-den-parity.nix`, den READ-ONLY):** den's ACTUAL `mkSchemaOption` registry config (extracted verbatim from `den/modules/options.nix`: 4 collections incl OR-merge isEntity/isolated, the `computed` isEntity, parent topology host←{user,home}, host/user/home import conf) + instances → BYTE-IDENTICAL through re-hosted-vs-original gen-schema incl id_hash SHA + teeth. **3 real-den findings (all consumer-migration, NOT correctness divergences):** (a) **den does NOT use gen-aspects** — it has its OWN native aspect layer (`nix/lib/aspects/`, `den.lib.aspects.types.aspectType`) → the C2 re-host has no real den consumer (validated by its own suite). (b) den imports gen-schema via `import gen-schema { inherit lib; }` (OLD sig) + via `fetchTarball` from `templates/ci/flake.lock` NOT a flake input → the C3 breaking-change is LIVE + full-den `--override-input` is INFEASIBLE. (c) **HEADLINE gen-merge GAP surfaced by real den: NO nested option-declaration support** — den declares `options.den.schema`/`options.den.hosts`/`options.den.classes` (2-level under `den.`); gen-merge is single-level (B1 scope, demand-driven) so `options.den.X = …` leaves the nested submodule unevaluated. Registry LOGIC is byte-parity at single-level; nesting is a den-framework wrapper (den's own evalModules drives it today). **Recommended NEXT gen-merge task = recursive option-path handling (moderate; TDD against the byte-identity oracle so C1-C4 stay green) — needed before den can drive config through evalModuleTree.** FOLLOW-ON (task #14): **flakeModule.nix BREAKING-change** = gen-schema's flake-parts `options.schema` is now a gen-merge type `lib.evalModules` CANNOT drive → nixpkgs/flake-parts consumers embedding `schema` break = the inherent pure-composition-plane trade (compose-plane ≠ nixpkgs-module input); decide deprecate-vs-evalModuleTree-entry at den-migration. + gen-types dedup deferred (gen-schema's refined/validate/strict copies aren't clean drop-ins). + publish-ordering: **github:sini/gen-types@ad180da + github:sini/gen-merge PUBLISHED 2026-07-02** (leaf-first; gen-merge locks+evals vs published gen-types; gen-prelude/gen-algebra already pub). gen-schema/gen-aspects RE-HOSTS **PUBLISHED as REPLACEMENT 2026-07-02** (OQ1 owner call): the pure re-host is now `.lib` (no legacy). Published revs: **gen-merge `fa5d5cc`** (#16 nested option paths + #20 path-leaf), **gen-schema `39d3d5d`**, **gen-aspects `64c3c25`** (gen-schema re-locked→github), **gen hub `af09165`** (`mkGenLibs` now exposes `merge`+`types`, resolves all 12 libs). Byte-parity incl **id_hash SHA** independently re-verified (`rehost-byte-parity`+`rehost-den-parity` all-true). Impl plan `gen-specs/2026-07-02-cross-compat-module-expansions-plan.md` (+`.md.tasks.json`, 13 tasks): **CROSS-COMPAT CORE SHIPPED + PUBLIC.** **gen-flake PUBLISHED** `github:sini/gen-flake 2d47478` (NEW repo — the value-injection nixpkgs boundary: `.lib`=compose/injectArgs/mkSystems + `.flakeModules.default`; compose PURELY→inject resolved VALUES into `_module.args`→build systems at a terminal via gen-bind.wrapAll→nixosSystem; **invariant proven end-to-end**: gen type rides as inert DATA in `_module.args`, never enters a consumer options tree). gen hub `6f29f76` (`mkGenLibs` resolves 13 libs incl merge/types/flake). All 3 ecosystem demos migrated to value-injection + published as the reference pattern (gen-schema `ef4d012`, gen-aspects `7dcdd3f`, gen-vars `42f2e71` multi-target nixos+terranix). import-tree fork = `denful/import-tree/a164a12` (`.addPath dir).files` = bare path list). FOLLOW-ONS: **T9 DONE** — den-hoag prereq PROVEN: **config-thunk deferral preserved BYTE-IDENTICALLY on gen-merge's byte-mode engine** (gen-merge main `c960e5c`, `ci/tests/deferral.nix` permanent regression; den `__configThunk` markers ride unforced through composition + mid-pipeline route/forward, force byte-identically at terminal reading config/osConfig; enabler = gen-merge lazyAttrsOf/raw passthrough + `isProperty` non-forcing → **den-hoag CAN ride gen-merge for config-thunk deferral**). **T10 docs DONE** (papers REFERENCEs gen-merge/gen-flake/gen-types + hub docs pushed `8bdd013`). **T11 C3 DONE** (flakeModule superseded by gen-flake `e706a09`; gen-types dedup deferred-documented; merged worktrees cleaned). **T12 DONE** (gen hub `2ea13d5`): rehost byte-parity oracles refactored to pure functions on **pinned `github:nix-community/nixpkgs.lib`** (policy first application) + wired as PERMANENT gen-ci flake checks (all-true incl id_hash SHA + teeth), stale flag → live `parity-nested` assertion, c3/c2 worktrees removed. **T13 DONE** (audit: all gen-* ci RUNNER-only except the hub oracles; deleted 4 orphaned impure dev-scaffolding files — gen-schema `7c204e5`, gen-aspects `e68bf4a`). T3 gen-types rename CLOSED won't-do. **⇒ ALL 13 cross-compat tasks COMPLETE + PUBLIC** (gen-merge `c960e5c` · gen-schema `7c204e5` · gen-aspects `e68bf4a` · gen-flake `5dd3a41` · gen-vars `2cb0ff0` · gen hub `2ea13d5`; papers REFERENCEs uncommitted for owner). Full record: `gen-specs/2026-07-02-cross-compat-module-expansions-plan.md(.tasks.json)` + meta-plan §5. **NEXT DESIGN ARC (deferred, dedicated session): gen-flake v1 API redesign + adios cross-pollination** — gen-flake is a working PROOF, NOT a stable v1 (do not tag v1 yet); the redesign folds in the "best of both worlds" adios program: adios **performance** (Adapton diff-propagation → wire compose→gen-resolve `override`) + our **compatibility** (keep the byte-parity nixpkgs terminal — compose-vs-terminal split) + **improved observability** (surface provenance/trace/diff on compose/override). Measure-gated (G6 first), then observability, then v1 redesign, then incremental override. adios sys-dependence memoization = reference for the future den-hoag k8s (non-nixpkgs) terminal. Doc: `gen-specs/gen-flake/2026-07-02-v1-remaining-work-and-adios-cross-pollination.md`. **nixpkgs.lib = ECOSYSTEM POLICY** (owner): lib-only need→pinned `github:nix-community/nixpkgs.lib`; full nixpkgs only for pkgs/nixosSystem (runners, gen-flake terminal); tracked as Task 12 (oracle regression, first application) + Task 13 (sweep). Deferred-work register in meta-plan §5. Downstream type-embedding consumers now break until value-injection migration (accepted D6 trade; demos=T8). **CROSS-COMPAT DESIGN 2026-07-02** (spec `gen-specs/2026-07-02-cross-compat-module-expansions-design.md`, brainstorm-approved, under adversarial review): owner target = QUERY resolved VALUES from nixpkgs = **VALUE-INJECTION, not type-driving** + structured options required. SOLUTION = **new gen-flake lib** (.lib+.flakeModule; compose-purely→inject-values→nixosSystem terminal = the ONE nixpkgs boundary; adios-flake-shaped) + gen-merge nested option-paths (#16) + path-modules (import-tree = denful/import-tree, NO fork) + gen-types rename (korora review: adios/korora accept the same trade — no type bridge). State tracker = meta-plan §5. Agent = evalmoduletree-design (built gen-merge+C3, will take C2).

**KORORA GO/NO-GO RESOLVED 2026-06-30 (audit §7 updated, file:line-verified) — Phase-1 keystone was MISLABELED.** Korora (`~/Documents/repos/adios/types/types.nix`, 573 LOC; `lib.nix`=its vendored utils) is a **verify-only** type system (`{name,verify,check}`, `verify:value→null|err`; primitives+option/listOf/attrsOf/union/struct/enum/tuple). **NO merge phase, no defs/loc, no priority (mkMerge/mkDefault), no submodule recursion, no evalModules.** Verdict: **GO but necessary-NOT-sufficient.** Korora vendors in an AFTERNOON + is a drop-in for the CHECKING half (all leaf/poly types these libs use map directly: str/int/bool/listOf/attrsOf/either→union/enum/nullOr→option/path/anything→any/strMatching/raw). **But it does NOT discharge the impurity** — the 3 impure libs use lib.types as the **MERGE ENGINE**, not a checker: gen-aspects/lib/types.nix:44 `aspectType=lib.types.mkOptionType{merge=loc:defs:…}` (custom merge over collected defs, calls mkMerge + submodule.merge); gen-schema/lib/entry-type.nix:223 RUNS `lib.evalModules`. Engine surface: mkOptionType-custom-merge + submodule×10 + lazyAttrsOf×9 + deferredModule×4 + functionTo×1 + evalModules×1 + mkOption×~25. **THE REAL GATE = gen-resolve's `evalModuleTree` merge engine (spec-only), NOT Korora.** Korora + Phase-0.5 Bucket-A decouple can proceed in parallel TODAY; gen-aspects/gen-schema purity is gated on gen-resolve existing + passing the evalModules-equivalence oracle. **Current verified purity state (2026-06-30): tether now 3 libs NOT 4** — gen-algebra FULLY PURE (module tier relocated→gen-schema @aaffd3f), gen-bind/select/derive MIGRATED+PUBLISHED onto gen-prelude. STILL IMPURE: gen-aspects (grammar), gen-schema (registry+evalModules), gen-vars/module-only. PURE substrate = 8 libs. Bucket A (cheap decouple of already-pure-in-substance gen-graph/scope/rebuild/gen-vars-pure-tiers off self-pinned nixpkgs.lib onto gen-prelude) still pending = hours.

**FOOTPRINT-REDUCTION PASS 2026-06-30 (audit §7 "Footprint-reduction pass" subsection):** (A) ISOLATE WIN — all 3 impure libs' merge-engine dependency collapses to ONE `evalModuleTree`-shaped primitive = **gen-resolve Phase 0 spec is bounded to 7 items**: typed-options+defaults, freeformType(lazyAttrsOf/attrsOf), per-key name/_module.args binding, self-referential `config` fixpoint (gen-aspects types.nix:166 + gen-schema instance.nix:50 both `config._module.args.X=config` — siblings cross-ref; NATIVELY gen-resolve's D>I>P scope-graph, the reason it beats single-edge closure), imports merging, the `(loc,defs)` custom-merge escape hatch, deferredModule+functionTo. ONE interface, not 3 integrations. (B) REDUCE — delete 2 bespoke mkOptionTypes BEFORE gen-resolve via Korora: gen-schema/lib/strict.nix(throw-on-unknown)→Korora struct `{unknown=false}`, refined.nix(predicate-in-__schema)→Korora `typedef'` verify; leaf checks→Korora verify. (C) CONSOLIDATE 3 engine-owners→2: gen-vars/module/registry.nix HAND-ROLLS a registry gen-schema already provides + gen-vars does NOT dep gen-schema (inputs=nixpkgs+gen-graph only) → re-express on gen-schema, gen-vars becomes a consumer, drops direct lib.types. **DECISION PENDING (dep-graph change, user's call).** (D) gen-schema already ~411/1789 LOC pure; entry-type collection-merge logic is ALREADY pure Nix riding deferredModule.merge(loc,defs)+evalModules → port = swap protocol provider lib→gen-resolve, pure logic untouched. NET: gen-resolve Phase 0 = the 7-item primitive for 2 clients; Korora discharges checking half + 2 deletions first.

**BUCKET-A PROMOTION REVIEW 2026-06-30 (3 parallel read-only agents, cross-checked vs gen-prelude/lib/default.nix). UNANIMOUS: gen-graph/gen-scope/gen-rebuild all PROMOTABLE to prelude-only, gen-prelude needs ZERO additions** (toposort vendor already closed the gap). Distinct lib.fns: graph 9 / scope 11 / rebuild 14; union of 19 all already exported (genAttrs/unique/mapAttrs/concatMap/fix/filterAttrs/max/listToAttrs/foldl'/optional/optionalAttrs/removePrefix/hasPrefix/tail/init/head/filter/any/all). graph genericClosure=builtins; scope fix=_eval HOAG memoization (prelude fix identical); scope uses NO recursiveUpdate/attrByPath; rebuild `with lib` was a comment false-positive. **EXECUTION: (1) ordering — rebuild's flake BUILDS graph/scope from nixpkgs.lib as inputs, so to drop nixpkgs from rebuild ENTIRELY promote graph+scope FIRST; publish order prelude→graph/scope→rebuild. (2) the ONE non-mechanical spot per lib = repo-root NON-flake default.nix impure `lib ? (import <nixpkgs>{}).lib` fallback (graph+scope) — agents said "no precedent" but gen-bind's standalone default.nix ALREADY derives prelude from its flake.lock via fetchTree{narHash}, reuse it. (3) recipe = convention-strict `{lib}`→`{prelude}` (matches shipped gen-bind/derive) vs minimal-diff (keep `{lib}`, pass lib=prelude in flake). (4) leave ci/+examples on nixpkgs (separate flakes, test-only fns findFirstIndex/splitString/drop/take/recursiveUpdate/attrByPath).** Audit §7 Bucket A updated with full table+findings. Bucket A = pure rewiring, hours, NO vendoring — cheaper than first stated.

**BUCKET A + BARE-ENTRY CONVENTION SWEEP SHIPPED 2026-06-30 (all pushed github:sini).** (1) gen-graph/gen-scope/gen-rebuild migrated to gen-prelude, Class C/D→B, nixpkgs.lib GONE from each (graph fe792d9, scope 2472dd6, rebuild 3c10e15; rebuild also dropped its lone `__functor`). (2) gen-derive FIX-1 (prelude feed via `gen-prelude.lib` not store-path re-import). (3) **CONVENTION: "a file is a function IFF it has dependencies"** — dep-free = BARE VALUE (`import ./x`, NOT `{ }:`/`import ./x { }`); applied to all dep-free submodules (graph traverse.nix, scope graph.nix) AND all 3 Class-A lib ENTRIES (gen-prelude 9e3f4c9, gen-select b92c344, gen-algebra 601a304 — entries now bare; every `import "${gen-prelude}/lib" { }`/`"${gen-select}/lib" { }` consumer dropped the `{ }` across ci/flakes + standalone fetchTree shims + repl.nix + 2 gen-select example flakes + READMEs; ecosystem-wide grep `/lib" { }` = EMPTY). (4) gen-algebra FIX-2/3/4: ci imports ../lib, canonical recursive purity.nix (superset forbidden), `outputs=_:`→`{...}:`; confirmed GENUINELY zero-dep (0 lib. refs). (5) gen hub c7ff00d: 7 locks bumped, mkGenLibs resolves all 9. **RF-1 resolved = (b) gen-algebra stays zero-dep** (sibling foundation to gen-prelude, neither depends on other). **RF-2 = aggregation idiom content-driven** (//-merge iff all-public-flat; curated iff hides/namespaces) — codified, no churn. Convention spec `gen-specs/2026-06-26-gen-lib-root-convention.md` UPDATED (items 8 function⟺deps / 9 aggregation / 10 purity-invariant + Class table A=bare,B+=graph/scope/rebuild,C=empty + warts resolved) — UNCOMMITTED (papers=user's call). Style-review (7 pure libs) drove it; gen-rebuild excluded from review (in-flight) but aligned by construction. NET: 8 pure libs uniform — bare-or-prelude entries, function⟺deps, canonical purity, no __functor; only gen-schema+gen-aspects remain nixpkgs-tethered (the gen-resolve/Korora project).

## SESSION HANDOFF (2026-06-26) — resume in fresh session
**COMMITTED** to papers archive `~/Documents/papers/den-architecture` @ **`25f2fa3`** (main, 4 files, 914 insertions), all in `gen-specs/gen-resolve/`:
1. `2026-06-26-gen-resolve-design.md` — the gen-resolve design spec (Phase 0; verifier-fixed: attr/readsAttrs, override edge-move guard, warmResolve single-engine, Palmer Lemma 5.12, CRAG dropped).
2. `2026-06-26-gen-derive-refactor-spike.md` — gen-derive loop⊥step refactor spike (DEFERRED post-ship).
3. `2026-06-26-pure-gen-module-system-phased-path.md` — the overarching pure-gen module system, phases 0-3 (Vic's end goal).
4. `2026-06-26-phase-1-grammar-rehost-notes.md` — gen-aspects grammar → gen-schema gap analysis.

**Uncommitted, separate repo:** gen-aspects README neededBy-row refinement is DONE but NOT committed in `~/Documents/repos/gen-aspects` (public repo; wants `nix develop -c just fmt`/treefmt before commit — leave for when that repo is next touched).

**Papers working tree (DO NOT touch — both are the user's strays, verified earlier):** `host-aspect-settings-guide.md` (modified, his pre-existing edit, workflow never touched it) + `specs/2026-06-26-pipe-broadcast-producer-class-config.md` (his PR #623 draft, restored byte-exact after a workflow fixer corrupted it).

**NEXT (in order):** (1) **Phase 0** — write the gen-resolve implementation **plan** (bite-sized TDD tasks) then build the lib; the design spec is the source of truth, D1-D14 + the 4 open research gates are stamped in it. (1.5) **Phase 0.5** — gen-prelude **SCAFFOLDED + PUBLISHED + WIRED 2026-06-26** (github:sini/gen-prelude @da654d0, PUBLIC, **zero-input flake** so consumers gain no transitive nixpkgs, 44 exports, **fidelity suite** all 18 utils == nixpkgs lib + boundaries, **CODE-REVIEWED + CI green** (nix flake check), nixfmt'd; wired into gen/ flake + mkGenLibs as `prelude`, gen@3b9f948). REMAINING: vendor `toposort` (currently a throw stub) + migrate the pure libs onto it — **gen-graph/select first** (trivial), then gen-scope/derive/rebuild/bind + gen-algebra/pure, each gated by its tests + the CI purity invariant. gen-bind also vendors its 2 module-convention helpers + an evalModules equivalence test. spec+audit at gen-specs/gen-prelude/. **→ gen-bind purity remediation DONE 2026-06-26 (FIRST lib actually migrated onto gen-prelude; recipe validated for the rest).** nix/lib now `{ prelude }` (genAttrs/optionalString→prelude, mapAttrs→builtins); 2 helpers vendored byte-verbatim from pinned nixpkgs in `nix/lib/module-convention.nix` (setFunctionArgs trivial.nix:1081, setDefaultModuleLocation modules.nix:611). flake.nix drops nixpkgs→adds gen-prelude (root lock = gen-prelude+root ONLY); standalone default.nix + ci/repl.nix derive prelude from flake.lock via `fetchTree{narHash}` (pure, no nixpkgs); ci/flake.nix keeps nixpkgs for the runner + the equivalence gate's real `lib.evalModules`. TWO new tests: `ci/tests/evalmodules-equivalence.nix` (4 cases: binding-inject / residual-args via lib.functionArgs / key-dedup / _file declarations — TDD oracle, teeth-proven by corrupting helpers) + `ci/tests/purity.nix` (§5 invariant: comment-stripped scan of nix/lib+flake.nix+default.nix for forbidden tokens — teeth-proven). 64/64 nix-unit, `nix flake check` ci+root green, treefmt clean. `gen-bind.lib` flake-output consumers (gen-aspects/gen-scope demos) UNAFFECTED. **CROSS-REPO LANDMINE: `gen/lib/mkGenLibs.nix:26` edited locally (`{inherit prelude;}`, verified vs LOCAL gen-bind) but gen pins OLD lib-based gen-bind → gen eval BREAKS until gen-bind PUBLISHED + gen's gen-bind lock bumped; land that edit TOGETHER. Nothing committed (user's call).** ALSO: gen-bind folded `nix/lib/`→`lib/` (git-tracked renames; all import paths + mkGenLibs/README/REFERENCE updated; 64/64 still green). **→ gen-select DONE 2026-06-26 (SECOND migrated; now ZERO-input, even cleaner than gen-bind — needs NO prelude). Decision: did NOT add gen-prelude; instead INLINED the one gen-algebra fn used (`intensionalEq = a:b: a.name==b.name`, Palmer §2.3) into constructors.nix + inlined `mkIntensional` (Palmer §2.2) into ci/tests/when.nix, since gen-select's `lib` param was 100% dead (audit-confirmed — zero `lib.*`).** Result: gen-select depends on NOTHING (root flake.lock = `[root]` only). Dropped nixpkgs+gen-algebra from flake.nix/default.nix/ci/flake.nix/ci/repl.nix; sub-modules (match/scope/registry/constructors) lost their dead `{lib}`/`{genAlgebra}` params; both examples (css/sql-where) dropped gen-algebra input (still use nixpkgs for their own lib + harness); added `ci/tests/purity.nix` (§5, also bans `genAlgebra`/`gen-algebra`). All 4 locks regenerated (examples via `--allow-dirty-locks` — they were already dirty-pinned to local gen-select path, NOT in main CI). 104/104 nix-unit (incl. the 4 `when` tests that were RED pre-change due to a stale gen-algebra `.pure`→`.lib` lock — inlining sidestepped it), `nix flake check` root+ci green, treefmt clean. mkGenLibs select line → `{ }` (same publish-gated landmine as gen-bind). NOTE: gen-algebra is mid-migration (`.pure`→`.lib` flake output + module-tier relocated to gen-schema; gen-algebra/lib is now flat+pure). **→ gen-prelude.toposort VENDORED 2026-06-26 (the keystone) + gen-derive DONE (THIRD migrated).** gen-prelude/lib: replaced the `throw` stub with verbatim nixpkgs `lib.lists.toposort` + its deps `listDfs`/`reverseList` (~55 LOC; also added `partition` builtin re-export listDfs needs); only `toposort` exported, helpers internal; 5 fidelity cases vs nixpkgs lib.toposort (chain/dag/single/empty/cycle) + 2 sanity, replaced the obsolete `toposort-stub-throws` test; gen-prelude 41/41, format clean. **CAVEAT: gen-prelude had NO committed ci/flake.lock — created one (`nix flake lock ./ci`).** gen-derive migration: `{lib,genAlgebra}`→`{prelude}` MECHANICAL `lib`→`prelude` swap (prelude re-exports ALL gen-derive uses: filter/all/foldl'/sort/mapAttrs builtins + filterAttrs/imap0/unique/toposort vendored); **gen-algebra dep was 100% DEAD** (rule.nix took it, never used it — has own inline isIntensional) → dropped, NO inlining in lib; compose.nix `{lib}`→`{...}` (dead); 6 tests used `genAlgebra.mkIntensional` for fixtures → shared `mkIntensional` (Palmer §2.2) via ci specialArgs (3 tests) + 3 had dead genAlgebra param dropped; flake.nix/default.nix/ci drop nixpkgs+gen-algebra→gen-prelude (default.nix+repl fetchTree-from-lock); ci keeps nixpkgs (runner) + gen-select input (adapter test, now zero-arg `{}`); added recursive `ci/tests/purity.nix` (walks core/+adapters/, bans nixpkgs/lib./genAlgebra). 69/69 nix-unit, root+ci `nix flake check` green, format clean. mkGenLibs.derive → `{inherit prelude;}`. **ALSO retrofitted gen-select's purity.nix to recurse** (it had silently skipped lib/adapters/). **CROSS-REPO PUBLISH ORDER (hard): gen-prelude(toposort) → gen-select(zero-input) → gen-derive. gen-derive's root+ci locks are DIRTY-PINNED to local /home/sini gen-prelude+gen-select working trees (file://, `--allow-dirty-locks`) so it evals green NOW; MUST `nix flake update gen-prelude gen-select` to re-pin github revs after publishing. mkGenLibs (gen repo) edits for bind/select/derive all pending publish + lock bump. Nothing committed.** gen-prelude.toposort vendor ALSO unblocks gen-vars (the other toposort consumer). **→ ALL PUBLISHED + WIRED 2026-06-27 (all prior cross-repo landmines RESOLVED — nothing pending).** Pushed to github:sini main in dep order: gen-prelude@4682b7e (toposort) → gen-select@1399f8f (purity-recurse retrofit; zero-dep migration was already @0960170) → gen-derive@075a217 (locks re-pinned dirty-local→published) → gen-bind@31e11e7 (was @b2bb0e7 = fold+prelude, +gen-prelude bump) → gen@d716cd3 (mkGenLibs wired bind`/lib`/select`{}`/derive`{prelude}` + flake.lock bumps all). gen mkGenLibs evals all 9 libs; every repo HEAD==origin, 0 uncommitted. THREE libs now pure-migrated (gen-bind/select/derive) + toposort keystone; REMAINING pure track = gen-scope, gen-rebuild, gen-graph, gen-vars (gen-vars now unblocked by toposort). (2) **Phase 1 keystone (~1-2 sessions/≈2 days — NOT weeks-months; see COST RECALIBRATION note + [[feedback_estimate_delivered_shape]])** — vendor Korora + re-host gen-aspects grammar onto it BYPASSING gen-schema (notes corrected). (3) gen-derive spike runs AFTER gen-resolve ships. (4) **gen-algebra/module → gen-schema relocation** — brief WRITTEN + committed (gen-specs/gen-algebra/2026-06-26-module-tier-relocation.md @ papers 2930162); EXECUTE in a NEW SESSION via dispatched agent. All 5 module/ exports (mkIdentityModule, mkStrictModule, validate.* [gen-schema already re-vendors via validate.nix], mkRefType [reconcile w/ gen-schema ref.nix, NOT dead — used in gen-schema demos]) → gen-schema (sole consumer, already impure); gen-algebra/default.nix drops module merge+moduleFallback → gen-algebra fully pure (lib.types-free). Agent MUST also: update local module docs, migrate ci/tests, sync REFERENCE.md+README in BOTH repos, sweep demos+update imports. Spans 2 repos (gen-algebra+gen-schema), one agent sequential. **Open:** gen-bind boundary (kept as gen-resolve terminal dependency — `wrapAll` is its own terminal op, defensibly ≠ gen-derive's mid-eval step; could still push den-side); lib naming (gen-resolve / the pure-gen system); whether `loadAspects` lives in gen-aspects-v2 or a new `gen-module` lib. Entry point for the fresh session = the 4 committed specs above.

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [gen-resolve library](project_gen_resolve.md) — pure-Nix RAG schedule-conductor (gen-scope-hosted, Class B); **v1 SHIPPED+PUBLISHED 2026-07-01** (@56209bb). ALSO holds the **pure-gen module system + cross-compat arc: SHIPPED+PUBLIC 2026-07-02** (gen-types/gen-merge/gen-flake; gen-schema/gen-aspects re-host REPLACEMENT byte-parity incl id_hash SHA; gen-flake value-injection boundary; config-thunk deferral proven; 13/13 tasks). SLICES 1+2 DONE 2026-07-05: trust docs public; A1 campaign gated (Arm-R 66.7%, spine ~98%); **gen-class v1 SHIPPED** (github:sini/gen-class, tier-2 kernel in gen-merge @2ad1099, ~5.8× spine gate in hub bench). NEXT = A2 gen-flake observability (RESUME-trust-release-a2.md) → A4/B3/B4/B5/A5 → den-hoag.

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

──────── archive-project_gen_rebuild.md ────────
---
name: project_gen_rebuild
description: "gen-rebuild v1 — pure-Nix incremental rebuilder gen lib, SHIPPED 2026-06-23"
metadata: 
  node_type: memory
  type: project
  originSessionId: 85325dea-fe37-4f8b-af92-9a402cf12e16
---

gen-rebuild v1 SHIPPED 2026-06-23 — new PUBLIC repo `github:sini/gen-rebuild`
(built at ~/Documents/repos/gen-rebuild/), 6 commits on main, 41 tests green.

The **rebuilder** dimension of Mokhov 2018 as a standalone gen lib — answers "given
last eval, must key K be recomputed?" and does minimal recompute + reuse. Composes
gen-graph (topology oracle) + gen-scope (threaded but unused in v1; v1 owns its own
thin store-backed `lib.fix` eval loop — gen-scope's `_eval` memo is welded to its
own `lib.fix self`, so the S1 warm-cache seam is deferred to v2).

**v1 surface:** `build` (flat relocatable id-keyed store + verifying trace +
located-cycle precheck), `override` (reverse-topo splice — authoritative form is
`ctx.store // lib.fix (s: genAttrs cone (id: recompute accessor' (ctx.store // s) id))`,
NOT bare `s`; spec §4 sketch was buggy), `affected`/`impactOf` (dependent cone =
graph.dependentsOf), `dirtySet` (deduped union of cones). Dirty-bit, whole-cone,
eager, intra-eval. Soundness property-tested over 120 seeded random DAGs
(override.store == from-scratch build(acc').store, byte-identical). B demo at
`examples/dag/` (poisoned-recompute proof of cone-only recompute) = the hola
Phase-3 (B) gate.

**Gotchas:** tryEval does NOT catch toJSON-on-function (uncatchable) → detect
function-bearing values structurally for the hash guard (hash=null = always-dirty);
tryEval forces only WHNF (attrset spine) → deepSeq the store to surface value-thunk
throws. ci is the gen mkCi convention (`cd ci && nix flake check`); mkCi uses
import-tree (every ci/tests/*.nix is a flake-parts module — gen.nix exposes the
seeded generator via `_module.args.mkCase`). gen-scope flake exposes only
`__functor` (no `.lib`) → `import gen-scope { inherit lib; }`.

**Deferred (separate plans):** v2 = rebuilder strategies (verify/constructive/
deepConstructive/earlyCutoff) + provenance + drivers + seams S1–S6; v3 = intra-eval
optimality (RTD `O(|AFFECTED|)`, sharing/swapping/switching). Impure cross-eval
shell is OUT of scope (spec §7 — a stateful substrate, not a deferred component).

**v1 verified GO 2026-06-23** (B demo `examples/dag` evals: resultEqualsFullRebuild
+ coneOnlyRecompute + poisonIsReal + cycleIsLocatedBlame all true; ci flake check
green). Paradigm go/no-go PASSED — graph-based incremental override is sound +
inspectable. Caveat surfaced: v1 override is DATA-change only (edges fixed);
topology change = v2.

**v2 FULL-DOMAIN spec authored 2026-06-23** (den-ag-design `aa29a1e`,
`gen-specs/gen-rebuild/2026-06-23-gen-rebuild-v2-design.md`, 1105 lines). Scope
decided w/ user: full v2 multi-plan, 3 repos; seams trimmed to gen-graph S3
(dependentsFrontier) / S4 (seededFixpoint) + gen-scope S1 (evalWarm) / S2
(recordedDeps) — **S6 DROPPED** (O(1) order-maintenance impure-or-O(N²) in pure
Nix; lib.fix already orders); **constructive/deepConstructive DEFERRED to v3/hola**
(= Nix store/IFD). Plan DAG: P0 gen-graph ∥ P1 gen-scope → P2 strategies+provenance
→ P3 drivers+structural(retract/applyEdgeDelta); P4 restabilize after P0(S4).
KEY FINDINGS from the design workflow (7 design→adversarial-verify→synth→3-lens
panel→revise, ~1.9M tok): (a) the v1-sketched evalWarm adapter is WRONG (evalWarm.get
resolves deps via own self, not store-arg) → **NO v2 op consumes S1**, ships
standalone, wired at hola/v3; (b) **null-hash false-clean** (`null!=null==false` →
changed function-bearing node silently reused = unsound) recurs in every
hash-comparing op → single `hashEq`/`hashMoved` guard mandated; 120-seed integer
property can't catch it (needs fn-bearing fixtures); (c) earlyCutoff delivers
per-node recompute-SKIP but only O(|cone|) allocation (true O(|AFFECTED|) = S7/v3);
(d) S3's real consumer is P3 propagate not P2 (P2 uses existing dependentsOf).
Every op gen-theory-conformance **gap-stated** (faithful mechanism, honest pure-Nix
gaps).

**Both forks RESOLVED + spec updated 2026-06-23** (den-ag-design 2nd commit on the
v2 spec): (1) sub-plans = separate milestone-gated PRs, gen-rebuild NOT on hola's
critical path (hola harness proceeds in parallel) → optimize for review quality;
(2) **WIDEN P0** — added a gen-graph `condensation` primitive (closure-based O(n²)
SCC: u,v co-SCC iff each reaches the other via transitiveClosure; NOT Tarjan's
mutable-stack O(V+E) = out-of-substrate). restabilize AUTO-DERIVES the SCC partition;
`fixpoint.lattices` now keyed PER-NODE; precheck relaxed to `set(cycles) ⊆
keys(lattices)`; footgun (consumer-declared sccs) gone. **S4 seededFixpoint demoted**
to standalone gen-graph export (no v2 gen-rebuild consumer — runScc can't reduce to
it; parallels S1's status). Designed+verified via a 4-agent workflow; caught
index-alignment desync (reps must == bottomUp), per-member-lattice runScc body,
bottom-up edge-direction; finalizer confirmed vs live gen-graph tree via
nix-instantiate. **P0 SHIPPED 2026-06-23** — gen-graph PR https://github.com/sini/gen-graph/pull/1
(branch feat/v2-seams, 4 commits: 22c659e _reverseIndex extraction byte-identical,
e4b65a7 dependentsFrontier S3, 8a037c9 seededFixpoint S4, 4c8da99 condensation+coScc).
128 tests (110+18), TDD red-first, all spec+quality reviewed+approved, treefmt+ci
green. Executed via subagent-driven-development (one impl subagent + combined review
per task); plan+tasks.json at den-ag-design gen-specs/gen-rebuild/...-v2-p0-...
PR NOT merged (user reviews/merges). P0 PR MERGED 2026-06-23 (rebase-merge, 4 commits on gen-graph main).

**P1 SHIPPED 2026-06-23** — gen-scope PR https://github.com/sini/gen-scope/pull/1
(branch feat/v2-seams, 3 commits: 41d10d7 eval refactor [evalAttr+warm params,
byte-identical], 7a75deb evalWarm S1, 24c1b1a recordedDeps S2). 163 tests (152+11),
eval byte-identical, evalWarm single-path wrapper, NEITHER consumed by any v2
gen-rebuild op (S1 adapter=v3/hola). TDD red-first, all reviewed+approved. Executed
subagent-driven; plan-review was executable (applied edits to scratch eval.nix,
proved byte-identity + all 11 tests). **PR #1 MERGED 2026-06-23** (gen-scope main).
NOTE: a separate user/agent pass fixed comment style + added API docs + updated
gen-specs/<lib>/REFERENCE.md for gen-graph+gen-scope — P2+ plans MUST include a docs
task per [[feedback_gen_lib_docs]] (theory-cited comments, lib README, REFERENCE.md).
**P2 SHIPPED 2026-06-24** — gen-rebuild main @ 0e27afc (5 commits, self-MERGED ff,
NO PR per user [[feedback_gen_direct_merge]]). 110 tests. hashEq/hashMoved null-safe
gate; strategies verify(Mokhov§4.2)/earlyCutoff(RTD§4.1)/needsEval(RTD§5.3, DISTINCT
not !verify.reuse); affectedSet + override REWRITTEN to needsEval-gated splice
(120-seed soundness PRESERVED byte-identical, failingSeeds==[]; affected⊆cone;
collision⇒[]; null-hash-through sound); provenance support/why/whyNot (why⟺dirtySet
120-seed). dirtySet unchanged. Executed subagent-driven (5 tasks); executable
plan-review proved override-soundness in scratch first; combined review gate before
self-merge. **Pre-work this session: v1-provenance PR #1 MERGED (theory citations to
v1 comments) + a full theory-conformance audit (gen-rebuild FAITHFUL, 0 defects;
audit+citation-worklist at gen-specs/gen-rebuild/2026-06-23-conformance-audit.md).**
PRE-FLIGHT for P3/P4 (citations + algorithms in the conformance-audit doc):
- **P3 (drivers force/applyDelta/batch/propagate + structural retract/applyEdgeDelta)
  needs P0-S3 dependentsFrontier → BUMP gen-rebuild flake's gen-graph input** (P0
  merged on gen-graph main).
- **P4 (restabilize/runScc) needs P0 condensation → same gen-graph bump.**
- **DOCS: write gen-specs/gen-rebuild/REFERENCE.md + lib README in a single pass
  AFTER P4** (deferred per user); theory-cited comments per-task throughout.
**P3 SHIPPED 2026-06-24** — gen-rebuild main @ 52a9613 (self-merged ff, no PR): drivers
(applyDelta/batch/propagate/force/forceCtx + override=propagate∘applyDelta, SINGLE
union-cone form via existing dependentsOf) + structural (retract/applyEdgeDelta +
withNewTopology/reCycleCheck). 155 tests; ALL FOUR 120-seed gates [] (data-change
soundness, fusion-law, edge-varying, retract). KEY: the fusion-law test caught a real
multi-seed propagate soundness bug (only head-seed forced recompute) — committing the
pre-written impl before its multi-seed tests let it land, fusion-law caught it
(LESSON: write multi-seed tests before committing multi-seed impl). DECISION: form-(a)
frontier over dependentsFrontier DEFERRED to v3 (allocation optimization; cortex pivot
de-prioritized allocation perf) — so dependentsFrontier's consumer is v3, and P3 needs
NO gen-graph bump. Executed subagent-driven; executable plan-review + combined review
gates (caught a §5.P3.a working-spec leak).
**P4 SHIPPED 2026-06-24 — gen-rebuild v2 IMPLEMENTATION COMPLETE** (main @ 97c9af3,
self-merged ff, no PR; all of P0-P4 now merged). P4 = the cyclic-fixpoint
re-stabilizer, 3 feature commits (44248a5 runScc, b5b42c4 extended build, 65ded40
restabilize), 155→179 tests. **runScc** = per-member semi-naive SCC solver
(iterate-from-⊥ to per-MEMBER eq-quiescence; widen-after-join; located
`fixpoint-diverged` blame with lastDelta = still-moving members' prev/next; Arntzenius
2016 Lemma 4 for genuine-join, Sloane 2010 §2.2 for overwrite/no-op). **build** gains
`fixpoint ? null`: null = EXACTLY v1 (v1 sub-binding, no fixpoint key); present =
condensation-stratified bottom-up `foldl'` over `graph.condensation`'s `bottomUp`
(producers-first; runScc ONCE per cyclic SCC, recompute for acyclic singletons;
byte-identical to v1 on acyclic) + relaxed precheck (`set(cycles)⊆keys(lattices)` else
located `undeclared-cyclic-node` blame). **restabilize** = incremental cyclic-capable
override: cone re-solve bottom-up, non-cone held at ctx.store, acyclic=override /
cyclic=runScc, fixpoint threaded forward. SOUNDNESS GATE: fixed-point-equality 120-seed
`[]` vs from-scratch `build{accessor';fixpoint}` oracle, with **83/120 seeds genuinely
cyclic** (runScc path non-vacuously exercised). KEY FINDING (empirical, baked into the
plan + build.nix comment): **`builtins.tryEval` does NOT catch `lib.fix` infinite-
recursion (black-hole)** — so the "bare-fix diverges" gate was UNSAFE (would
escape/hang CI); substituted a `bottomUp` producer-before-consumer ordering assertion +
lfp==oracle pin. All divergence guarded by located prechecks + runScc maxIter, NEVER by
catching infinite recursion. Executed subagent-driven (3 impl agents); executable
plan-review (wr98jf6hb) up front + 2-lens adversarial final review (w33s0m038, APPROVED
0.98/0.99, zero blocking) before merge.
**DOCS PASS DONE 2026-06-24:** README full v1+v2 surface (23 exports + Cyclic-fixpoints
subsection; gen-rebuild @ 97c9af3) + NEW gen-specs/gen-rebuild/REFERENCE.md (308 lines,
house format matching gen-graph/REFERENCE.md, paper-grounded; den-ag-design @ 9151d26).
Public surface (23): build affected impactOf affectedSet dirtySet override verify
earlyCutoff needsEval support supportDirect why whyNot applyDelta batch propagate force
forceCtx mkAccessor retract applyEdgeDelta runScc restabilize (hash.nix internal).
**FINAL whole-lib gen-theory-conformance gate PASSED 2026-06-24** (adapted
gen-rebuild-only per user; wrs3asdc1) — 5 paper-cluster verifiers (Mokhov / RTD /
Acar+Forgy+Hammer / Radul / Arntzenius+Sloane+Tarjan) + adversarial challenge of every
blocking finding. EVERY op classified `faithful` or `gap-stated` (the honest posture):
ZERO overclaim/misapplication/unstated-gap, ZERO surviving defects. The honest gaps are
all stated in code+REFERENCE: O(|cone|) not O(|AFFECTED|) (RTD), full-drain force not
Adapton per-edge (S6 dropped), support/retract NAME-faithful-only (no Radul TMS),
runScc UNCHECKED monotonicity+finite-height (only maxIter), condensation closure-O(n²)
not Tarjan-linear, cyclic OUTSIDE RTD envelope. **v2 fully closed.**
**v3 deferred:** form-(a) frontier over dependentsFrontier (allocation opt); true exact-
AFFECTED O(|AFFECTED|) = S7; constructive/deepConstructive (Nix store/IFD); impure
cross-eval shell (out of scope, spec §7). gen-graph S4 seededFixpoint + S1 evalWarm
ship standalone (no v2 consumer).

**v3 MINIMALITY SPIKE COMPLETE 2026-06-24** — gen-rebuild main @ 107986e (13 commits,
self-merged ff, no PR; `spike/` dir + own `spike/ci` flake, lib/ + 179-test suite
BYTE-UNTOUCHED; 59 spike tests). Feasibility spike (NOT production): races 3 propagate
variants on a counted-forces harness to answer "can pure-Nix beat O(|cone|) toward RTD
O(|AFFECTED|), byte-identically?" VERDICT (mechanical §8 bands): **V-push = PARTIAL,
V-summary = NO-GO, baseline = reference** — the spec's pre-committed "honest likely
outcome". LEARNINGS: (a) V-push (rank-ordered eager-push: cone-local depth-rank + DIRECT
reverse-adjacency enqueue + `priorStore//settled` carry) wins on the EXPENSIVE axis
(recompute/hash/alloc) for CUT-HEAVY edits — deep-cut r_x≈0.15, sparse-affected r_x≈0.12,
byte-identical over 120-seed×6-kind — but r_x=1.0 on full-propagation (chain/wide-fan) ⇒
NO O(|AFFECTED|) generalization; (b) TOTAL-axis r_t>1 EVERYWHERE (deep-cut 2.1 even where
r_x=0.15) — the rank precompute + drive sweep are themselves ≥O(|cone|), EMPIRICALLY
CONFIRMING sub-cone-TOTAL is unreachable in a single pure eval (the §2 ordering floor);
breaking it needs cross-eval amortization = the deferred impure/persisted-DCG substrate;
(c) V-summary (deep-constructive-trace summary) NO-GO: summaryForces O(|cone|²) (231 vs
cone 21) per Mokhov §4.2.4 "no early cutoff except at n levels". NEXT: follow-on v3 build
plan = land V-push as a SCOPED cut-heavy fast path (behind the 120-seed gate; cut-heavy-
vs-full-propagation r_x split = its perf contract) — a value call, NOT a GO; the r_t>1
ceiling = quantified input to the [[project_zen_vic]]/[[project_hola]] substrate-
convergence decision. Spec+plan+results in gen-specs/gen-rebuild/2026-06-24-*v3-minimality-
spike-*.md (design reviewed via 31-agent workflow; build executed subagent-driven — 10
tasks, each 2-stage reviewed; §8 collision-band spec defect fixed: collision is a
soundness probe, |cone|=1 ⇒ r_x=1.0, excluded from the perf bands).

**v3 V-PUSH FAST PATH SHIPPED 2026-06-25** (the PARTIAL→land decision executed; user
deprioritized cross-eval, so this is the realized v3) — `genRebuild.propagateEager`, gen-rebuild
main @ 26a5c52 (self-merged ff, no PR). 2-repo plan, subagent-driven (4 tasks, each 2-stage
reviewed): (1) gen-graph PR #2 MERGED (`coneRank` cone-local producers-first rank + `directDependents`
DIRECT reverse-adjacency, exposing private `_reverseIndex`; 141 tests); (2) `lib/eager.nix` —
propagateEager, an OPT-IN cut-heavy fast path returning the standard BuiltCtx (chains like
override/propagate; default unchanged); rank-ordered eager push, DIRECT cone-restricted enqueue,
§4(B) `ctx.store//settled` carry, affected-only trace' re-hash; (3) soundness gate: 120-seed
byte-identity (mkCase) + cutoff-join §4(B) with a JOIN-POISON right-reason proof (Q carried, never
recomputed — the case override's single-id 120-seed can't reach) + chained + deep-cut poison; full
suite 179→210. (4) README + REFERENCE.md, honest perf contract (byte-identical; O(|AFFECTED|+frontier)
constructed on cut-heavy, O(|cone|) drive bookkeeping regardless ⇒ constant-factor EXPENSIVE-axis win,
NOT total-work O(|AFFECTED|); total-axis floor = deferred cross-eval). GOTCHA (now in
[[feedback_gen_lib_docs]]): gen CI treefmt includes **mdformat** run `cd ci && nix fmt -- --ci`;
local root `nix fmt`/`nix flake check` miss it — gen-graph PR #2 first push failed CI on an
unformatted README (`\|`→`|` un-escape). Plan: gen-specs/gen-rebuild/2026-06-24-gen-rebuild-v3-vpush-fastpath-plan.md.
Remaining v3 (per [[project_zen_vic]]/[[project_hola]] substrate-convergence) NOT pursued: true
total-minimality / S7 / deepConstructive all need cross-eval persistence.

Spec + plan: ~/Documents/papers/den-architecture/gen-specs/gen-rebuild/. Part of the
gen ecosystem [[project_gen_package]]; effects-paradigm dual is [[project_zen_vic]];
consumed by [[project_hola]]. Docs root [[reference_gen_docs]].

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [gen-rebuild v1+v2+v3-spike](project_gen_rebuild.md) — pure-Nix incremental rebuilder (Mokhov rebuilder dim) github:sini/gen-rebuild; v2 COMPLETE (P0-P4, 179 tests + REFERENCE.md): build(+fixpoint cyclic)/override/strategies/affectedSet/provenance/drivers/structural/restabilize+runScc, soundness 120-seed; v3 MINIMALITY SPIKE COMPLETE 2026-06-24 (main @ 107986e, spike/ dir + 59 tests, lib untouched): VERDICT V-push=PARTIAL (sub-cone EXPENSIVE-axis win on cut-heavy r_x≈0.12-0.15 byte-identical, but r_t>1 everywhere ⇒ sub-cone-TOTAL unreachable in pure eval = §2 ordering floor) / V-summary=NO-GO (summaryForces O(|cone|²), Mokhov §4.2.4); v3 V-PUSH FAST PATH SHIPPED 2026-06-25 (main @ 26a5c52): genRebuild.propagateEager opt-in cut-heavy fast path (BuiltCtx, chains; gen-graph PR #2 merged = coneRank+directDependents; 210 tests incl 120-seed + cutoff-join §4(B) join-poison; honest perf contract NOT total-O(|AFFECTED|)); remaining v3 (true minimality/S7/deepConstructive) NEEDS cross-eval persistence, NOT pursued (user deprioritized); mdformat CI gotcha → [[feedback_gen_lib_docs]]


## Comments (0)

(none)
