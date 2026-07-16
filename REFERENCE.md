# den-hoag REFERENCE

den-hoag is L3 vocabulary and wiring: it names entities, compiles the four concerns onto library
contracts, and wires the HOAG evaluation DAG. **Every algorithm lives in a `gen` library** — den-hoag
contributes only naming, forwarding, and attrset assembly (Law A1). This reference is the law index (the
lib each law delegates to), the theory citations, the grounded-terminology mapping, the two
spec-vs-reality flags, and the honest v1 boundaries.

## Law index (A1–A18)

Each law is discharged by a named library; den-hoag's file only wires it. "den-hoag file" is where the
wiring lives; "delegates to" is the library that owns the algorithm.

| Law | Statement | Delegates to | den-hoag file |
| --- | --- | --- | --- |
| **A1** | Zero machinery — no hand-rolled convergence / toposort / product traversal; every algorithm is a named lib call. | all libs (discipline) | enforced by `ci/tests/zero-machinery` + `end-to-end` census |
| **A2** | Identity law — every entity/aspect/class/kind/channel position is a registry entry (`id_hash`), never a `"kind:name"` string. | `gen-schema` (`mkIdentityModule`) | `lib/declarations.nix` (`requireEntry`), `lib/errors.nix` (`identityLaw`) |
| **A3** | Enrichment — single-writer: an enrich key is written by exactly one policy; the enrichment fixpoint re-dispatches rules on the converging context. | `gen-scope` (`circular`) + `gen-dispatch` (`dispatch`) | `lib/attributes/structural.nix` (`enrichments`), `lib/concern-policies.nix` |
| **A4** | Stratum separation — a structural attribute never demands a resolution attribute; each dispatched rule's declarations classify to ONE stratum (`checkStratum`). A policy whose value-less probe cannot observe its stratum (value-conditional emission, or a throw doing value-work against the sentinel) is compiled into one sub-rule per covered stratum {structural, resolution}, so every declaration is produced in its stratum's phase and the one-rule/one-stratum law holds PER SUB-RULE (enrich/pipeOp from such a policy abort loud). A rule record `{ __condition; fn }` declares its firing gate as data — the general policy vocabulary. | `gen-resolve` (schedule) + `gen-dispatch` (`mkActions` groups) | `lib/declarations.nix` (`checkStratum`), `lib/concern-policies.nix` (per-declaration expansion + record form), `lib/attributes/default.nix` |
| **A5** | Member discipline — `member` is accepted only at membership-independent nodes; the fleet is the membership-restricted product. **Member ROUTING delivered (R1, 2026-07-11):** the STAGED ROOT-RESOLUTION pre-pass dispatches root-node resolve policies in containment-kind topology order BEFORE the fleet product, routing a policy-emitted leaf-dim `member` into `membershipTuples` (= static ∪ derived) and folding a `relate` (source→existing-root) relation's ctx bindings into the target root — the deferred "Task 4" closed. Double-fire discipline: resolve-family {member, relate} is consumed by the pre-pass ONLY; a resolve-family emission at a membership-derived node aborts LOUD (`memberAtCell`), never silently dropped. A native/corpus fleet with no resolve policy is byte-identical (empty feed → inert pass). R2 (the compat `resolve.to` arm) OPEN. Design note: `papers/den-architecture/specs/2026-07-11-user-delivery-arc-design-note.md`. | `gen-product` (`restrict`) + `gen-dispatch` (`dispatch`) | `lib/staged-resolution.nix` (`runPrePass`), `lib/default.nix` (`membershipTuples`/`scopeRoots` wiring), `lib/declarations.nix` (`relate`/`isResolveFamily`), `lib/concern-policies.nix` (`resolveFamily` feed), `lib/attributes/structural.nix` (the A5 cell guard), `lib/fleet.nix` (`mkFleet`), `lib/errors.nix` (`memberAtCell`, `relateNoTarget`) |
| **A6** | Product/scope coherence — the per-cell P-chain equals the tree-kind restriction of the containment chain. | `gen-product` (`containmentChain`) + `gen-scope` | `lib/build-roots.nix`, `lib/fleet.nix` |
| **A7** | Linearization — `den.linearization.dims` is a total, entry-only cover; the derived slice order is independent of policy declaration order. | `gen-product` (`containmentChain` linearization) | `lib/linearization.nix`, `lib/errors.nix` (`linearizationDim`) |
| **A8** | Settings authority — a `configure` policy layer occupies the terminal slot (authority-wins by position); the schema default layer is always first. | `gen-settings` (`resolveAll`) | `lib/attributes/resolved-settings.nix` (`policyLayersAt`) |
| **A9** | Stratification — presence resolution reads the graph, never resolved settings; the resolution/collection/demand strata order beneath the structural stratum. (A9.1: a guard sees `{ pathSet, hasAspect }` ONLY.) | `gen-resolve` (schedule) + `gen-scope` | `lib/attributes/resolved-aspects.nix`, `lib/attributes/resolved-settings.nix` |
| **A10** | Narrow accessor — at any scope node, `aspects.<name> = { present; settings; }`; content→content is unexpressible (only those two fields cross). | (den-hoag-owned projection) | `lib/attributes/resolved-settings.nix` (`mkNarrowAccessor`), `lib/errors.nix` (`absentAspectSetting`) |
| **A11** | Presence fixpoint — the joint neededBy+guard monotone LEAST fixpoint (Layer-1 forward expansion seeds a keyset ascent). | `gen-scope` (`circular`) + `gen-aspects` (`key`) + `gen-select` (`matches`) | `lib/attributes/resolved-aspects.nix` |
| **A12** | Producer tie-break — two contributions at ONE position order by producer identity (aspect rank 0 / policy rank 1, then id_hash, then emission index), permutation-stable. | `gen-pipe` (channel B5) | `lib/scope-adapter.nix` (`sortByProducer` = one `prelude.sort`) |
| **A13** | Class tags — a quirk contribution is tagged its producing scope's class; a cross-class read needs a declared adapter; a null-class class-shaped emission aborts. | `gen-pipe` (`contribute`/`run`) | `lib/attributes/collections.nix`, `lib/errors.nix` (`classAmbiguity`, `crossClassNoAdapter`) |
| **A14** | Projects facet — an aspect projects settings onto OTHER aspects matching a STATIC aspect-schema selector, expanded into `via`-carrying settings layers at its attachment scopes. | `gen-select` (`when`/`matches`) | `lib/projects.nix`, `lib/errors.nix` (`projectionCollision`, `projectionDynamicSelector`) |
| **A15** | Output completeness — `config(root) = materialize (toposort (edgesFor { graph, root }))`; the frozen edge trace E is stable and equal for equal topologies. | `gen-edge` (`edgesFor`/`toposort`/`project`/`materialize`/`trace`) | `lib/attributes/output-modules.nix`, `lib/graph-escape.nix` |
| **A16** | Settings byte-parity — `resolved-settings.value` is byte-identical to a plain `foldLayers` over the same ordered layer values; provenance lists every layer in §2.7 order. | `gen-settings` (`resolveAll`) + `gen-algebra` (`foldLayers`) | `lib/attributes/resolved-settings.nix` |
| **A17** | Per-member laziness — the output map is class-major and content-driven; one instantiate per member, per-cell lazy; NEVER a global fleet switch. | `gen-class` + `gen-flake` (terminal) | `lib/attributes/output-modules.nix` (`systems`), `lib/output/terminal.nix` |
| **A18** | Class-share gate — the tier-2 `applyCoreFixed` spine-skip is byte-identical to the full merge, authorised ONLY by the byte gate; a divergent core aborts LOUD. | `gen-class` (`applyCoreFixed`/`gateCore`) | `lib/output/class-share.nix`, `lib/errors.nix` (`classShareGate`) |

The resolution-algorithm sub-laws **B1** (single-writer enrichment, A3), **B2** (stratum coherence, A4),
**B3** (linked-context — forward-threaded through the dispatch `combine`, never fed back), **B4** (the
joint fixpoint, A11), and **B5** (neron channel order — self → imports → parent, A12) are the internal
mechanics of A3/A4/A11/A12; they are named where they appear in `lib/attributes/structural.nix` and
`lib/attributes/resolved-aspects.nix`.

**A15 legacy-edge seam (the `interpret` parameter).** The output fold's source interpreters are a REAL
parameter: `mkOutputModules` takes `interpret ? { }` and `outputFor` threads it into `gen-edge.materialize`.
Native den-hoag constructs only `collected`/`value` edge sources, so the default `{ }` is complete and
`den.graph`/`output` are unaffected. den-compat teaches the fold its legacy `synthesize`/`rewalk` sources
by setting `den.interpret = { synthesize = …; rewalk = …; }` in a fleet module — **without editing**
`lib/attributes/output-modules.nix`. It rides `raw` (opaque functions), forced only when a legacy source
is actually folded, never for a native fleet.

## Theory citations (§6)

The libraries den-hoag delegates to carry the theory; the citations that matter at this layer:

- **`gen-edge` — Bernstein (1966), "Analysis of Programs for Parallel Processing", IEEE Trans. EC-15.**
  `readsOf`/`writesOf` realize the read/write half of Bernstein's parallel-execution conditions; the
  relaxed output-independence case (same-cell writers) is discharged by canonical cell ordering in
  `materialize`, so conflicting writers commute *as observed*.
- **`gen-edge` — A. B. Kahn (1962), "Topological sorting of large networks", CACM 5(11).** `toposort`
  is Kahn's algorithm over the accumulator dependency relation; the loud-cycle behavior is Kahn's
  residual-queue emptiness check. (This is A. B. Kahn 1962, NOT Gilles Kahn 1974 KPN.)
- **`gen-scope` / `gen-resolve` — demand-driven Reference Attribute Grammars (Vogt et al.).** The HOAG
  evaluation is a demand-driven attribute schedule with `_eval` memoization and circular attributes;
  den-hoag's structural/resolution/collection/demand strata are the attribute layers.
- **Presence fixpoint (A11/B4) — Knaster–Tarski.** The joint neededBy+guard ascent is a monotone LEAST
  fixpoint over a keyset lattice (keys only ever added), so keyset-equality is a sound convergence test
  and the fixpoint is unique and arrival-path independent.
- **Edge algebra — `delivery-edge-unification` §2 (internal).** The `(S,T,P,M)` edge rule and corollaries
  1–3 fix "every content move is one edge; isolation is edge absence; reinstantiate is a mode".

## Grounded terminology (r2 / v1 → graph-native)

den-hoag's public API, file names, attribute names, error messages, tests, and docs use graph-native
vocabulary. den v1's effect/state words are banned from the surface. This table maps the old names an
r2-era reader may look for to what the assembly actually uses:

| r2 / v1 name (what you may look for) | grounded term (what den-hoag uses) |
| --- | --- |
| effect / effect value | **declaration** (an inert, tagged graph fact) |
| effect constructors, `lib/effects.nix` | **declaration constructors**, `lib/declarations.nix` |
| `policy-effects` attribute | **`declarations`** attribute (the facts present at a node) |
| `enrich-effects` attribute | **`enrichments`** attribute (`{ added; owners }`, inert data) |
| policy dispatch / dispatch point | **rule evaluation** (policies are rules evaluated at nodes) |
| phase / `checkPhase` | **stratum** / `checkStratum` (definition-time stratum typing) |
| fired / dispatch accumulator internals | retired from `gen-dispatch` (now rule-evaluation-only) — never surfaced in den-hoag |

`gen-dispatch`'s own exported names (`mkActions`, `dispatch`, …) stay as-is *behind* den-hoag's
wrappers; the wrapper surface uses the grounded terms.

## API Verb Catalog

The two public verb surfaces. `declare.*` (`lib/declarations.nix`) is the native declaration-constructor
vocabulary a policy body calls; `policy.*` (`lib/compat/policy-verbs.nix` + `lib/compat/deliver.nix`, wired
in `flake.nix`) is the v1-compatible surface a den-corpus policy body calls. Every verb produces an INERT,
tagged graph fact — never a callable effect (A1/A2). STRATUM is the mkActions group (structural | resolution
| collection | demand); CONCERN on the compat table is the same axis in v1 words.

### `declare.*` — declaration constructors (`lib/declarations.nix`)

| verb | args | stratum | what it declares |
| --- | --- | --- | --- |
| `member` | `{ <dim> = entry; … }` (bare coords) or `{ coords; bindings ? {}; containTo ? null }` (wrapped) | structural | The SOLE resolve-family tuple (§3c-UNIFIED): a product CELL (bare) or a `containTo`-marked CONTAINMENT tuple carrying ctx `bindings` into an existing root. Coords entry-checked eagerly (A2). Accepted at membership-independent roots only (A5). |
| `suppress` | `{ name }` | structural | Scope-local policy-suppression fact — names a v1 policy whose rules must not fire at this scope or descendants (the v1 `policy.exclude <policy>` constraint). `name` is a plain string, not an entity. |
| `spawn` | `{ … }` | structural | LATENT (mkActions-generated, no consumer): child-node creation, subsumed by `member` fan-out. |
| `spawnShared` | `{ … }` | structural | LATENT: non-isolated fan-out, subsumed by `member`. |
| `emit` | `{ … }` | structural | LATENT: wire-entity-into-output, subsumed by `member` fan-out. |
| `enrich` | `{ key = val; … }` | structural | Add enrichment key-values to the scope's context; consumed by the enrichment fixpoint (`lib/concern-policies.nix`, A3 single-writer). |
| `link` | `{ target }` | structural | An I-edge to an EXISTING entity node (annotates, never creates/re-resolves). `target` entry-checked eagerly (A2); selector fan-out is a policy idiom, not constructor polymorphism. |
| `edge` | `aspect` | resolution | An aspect-delivery edge onto this node. Aspect entry-checked eagerly. |
| `drop` | `aspect` | resolution | Scope-level constraint pruning an aspect (and its include subtree) from the resolved set (§B4). |
| `reroute` | `{ from; to }` | resolution | Moves a class's collected content to another class; consumed by `lib/attributes/class-modules.nix` (`reroutes`). |
| `inject` | `{ class; module }` | resolution | Appends a module to a class bucket; consumed by `lib/attributes/class-modules.nix` (`injects`). |
| `configure` | `{ of; set }` | resolution | Set values on a target entry (`of` entry-checked eagerly). |
| `delivery` | `{ sourceClass; targetClass; module ? null; path ? []; mode; adaptArgs ? null; guard ? null; annotations ? {} }` | resolution | A v1 delivery-edge INTENT (external consumer's `deliver`/`route`/`provide`); the gen-edge record is rendered at the firing node by output-modules. `sourceClass`/`targetClass` entry-checked eagerly. |
| `reach-edge` | `{ target; classFilter ? null }` | resolution | POSITIVE cross-scope reach-edge (spec §7.1). `target` = bare node-id STRING; `classFilter` = predicate on the target's resolved-aspect nodes (null = all). |
| `reach-suppress` | `{ edge; when ? (_: true) }` | resolution | NEGATIVE edge removing the positive reach-edge whose `target == edge` (node-id STRING), gated by `when scope`. |
| `demand` | `{ subject; … }` | demand | A subject entity plus the demand payload (`subject` entry-checked eagerly). |
| `pipe.{map,filter,fold,scan,route,join,tee}` | per gen-pipe | collection | gen-pipe dataflow ops re-exported; concern-quirks wraps them into `pipeOp` collection declarations. |

Note: `den.default` (v1 compat) desugars to a plain `den.aspects.defaults` aspect wired through
`den.schema.{host,user}.includes` — it follows the SAME kernel kind-include path as any user aspect (the
6.2b surface). There is NO bespoke `__default`/`__denDefault` radiation (that block was deleted).

### `policy.*` + pipe — v1-compat vocabulary (`lib/compat/policy-verbs.nix`, `lib/compat/deliver.nix`)

| verb | args | concern | notes |
| --- | --- | --- | --- |
| `include` | `aspect` | resolution | Lowers to `declare.edge` (via `compile.nix` translateEffect). |
| `exclude` | `aspect` | resolution | Lowers to `declare.drop`. |
| `mkPolicy` | `name: fn` | — | Named-policy record `{ __isPolicy; name; fn }` for use in includes. |
| `resolve` | `{ bindings }` | structural | Fan-out; lowers to `member` (a cell tuple). `.shared` (non-isolated), `.to "kind" {…}` (root-target → `containTo`-marked `member`), `.withIncludes includes {…}`, `.shared.to`, `.to.withIncludes`. Only `resolve.to "<kind>" {…}` is corpus-exercised. |
| `route` | `{ fromClass; intoClass; intoPath ? null; path ? null; reinstantiate ? false; guard ? null; adaptArgs ? null; __extra ? {} }` | resolution | **PERMANENT sugar** over `deliver` (`deliver.nix`). `intoPath`/`path` → `at` (both present aborts, §2.3); `reinstantiate = true` → `mode = "verbatim"`; `__extra.appendToParent` overlays the parent-target flag (#53c). Not replaced by `reroute`. |
| `provide` | `{ class; module; path ? [] }` | resolution | **PERMANENT sugar** over a module-source `deliver` (`class` → `to`, `module` → `from.module`, `path` → `at`). Not replaced by `inject`. |
| `deliver` | `{ from; to; at ? []; mode ? "merge"; guard ? null; adaptArgs ? null }` | resolution | The base delivery surface (`deliver.nix`); produces a `{ __delivery = true; … }` descriptor, compiled to a `delivery` declaration at fire time (Law C2). `from` = class name (route case) or `{ module }` (provide case). `mode` ∈ {merge \| nest \| verbatim}; verbatim on a module source aborts. |
| `spawn` | `{ classes }` | structural | v1 home-projection fan-out verb (distinct from `declare.spawn`, which is a latent structural constructor). |
| `instantiate` | `spec` | structural | v1 instantiate verb. |
| `pipe.from` | `nameOrRef: stages` | collection | Heads a channel derivation; stages fold left-to-right (`pipe.nix` compilePipe). |
| `pipe.filter` | `pred` | collection | Stage: keep matching values. |
| `pipe.transform` | `fn` | collection | Stage: map values. |
| `pipe.fold` | `fn init` | collection | Stage: left fold. |
| `pipe.append` | `value` | collection | Stage: append a value. |
| `pipe.for` | `fn` | collection | Stage: per-value branch. |
| `pipe.withProvenance` | — | collection | Stage: carry provenance. |
| `pipe.to` | `aspects` | collection | Stage: targeted delivery to specific aspects (spec name `pipe.target`). |
| `pipe.as` | `targetPipeName` | collection | Stage: redirect to a different channel (spec name `pipe.channel`). |
| `pipe.expose` | — | collection | Stage: data flows UP the P edge, child→parent (spec name `pipe.ascend`). |
| `pipe.broadcast` | `pred` | collection | Stage: push-dual of expose — broadcast to matching scopes. |
| `pipe.collect` | `pred` | collection | Stage: gather from scopes matching predicate (spec name `pipe.gather`). |
| `pipe.collectAll` | `pred` | collection | Stage: collect across all matching scopes (no scope restriction). |

## Spec-vs-reality flags

Two places where the shipped substrate differs from the r2 spec's placeholder names — resolved here,
faithfully to Law A1:

1. **The gen-flake terminal is `realize` + `terminals.nixosSystem`, not `mkSystems.nixos`.** The spec's
   `mkSystems.nixos` is a placeholder. den-hoag makes exactly one nixpkgs crossing, in
   `lib/output/terminal.nix` (`crossNixos` → `gen-flake.terminals.nixosSystem { nixpkgs }`), driven by
   `den.nixpkgs`. Every other `lib/**` file is nixpkgs-lib-free.
1. **The dispatch-coupled fixpoint is `gen-scope.circular` composed DIRECTLY over `gen-dispatch.dispatch`.**
   `gen-resolve` documents the circular∘dispatch pattern but exports no wrapper. The B1 enrichment
   fixpoint is `gen-scope.circular { init = base; eq = keysetEq } (ctx: ctx // extract (dispatch …))` —
   re-dispatch-on-converging-context. The earlier `dispatchStep`/`dispatchInit` accumulator form was
   judged ceremony for the single-stratum enrichment attribute and retired in den-hoag (decision #25);
   `gen-dispatch` has since completed the same retirement lib-side (`dispatchStep`/`dispatchInit` deleted,
   `phase`→`group`), so it owns rule evaluation only and no accumulator export remains. **den-hoag uses
   ZERO `dispatchStep`** (the `end-to-end` fixpoint census asserts it).

A third reality note on the class-share path: **tier-2 share is gen-merge-only; the nixpkgs crossing
cannot coreShortCircuit.** The A18 class-share build (`applyCoreFixed`) is gen-class tier-2 fixed-input
via gen-merge — a byte-gated spine-skip over den-hoag's PURE gen-merge merge. A real NixOS build crosses
through the nixpkgs terminal (`crossNixos`), which is a separate path and does not (cannot) short-circuit
the shared core; the shared build is an inspectable freeform config (below).

## Honest v1 boundaries

Recorded from the A5–A10 review; these are deliberate v1 ceilings, not bugs:

- **Projection ceiling = a member's OWN local classInvariant emissions (A10/A18).** `mkCore` intersects
  the KEYS across members over each member's own channel emissions (attribute 10); a member-varying or
  config-dependent (deferred) value drops out of the shared core. The share reflects only what is
  config-independent and common — it is a build STRATEGY, never semantics.
- **Share output = an inspectable freeform config (A17/A18).** den-hoag's pure gen-merge merge carries no
  nixos option declarations, so the tier-2 shared build absorbs the class-modules' undeclared options
  through a root `freeformType` — an inspectable config, the `collect` terminal's nixpkgs-free
  philosophy. A REAL nixos build crosses through the nixpkgs terminal, not this tier-2 path.
- **Projector attachment = the static `den.include` surface only, v1 (A14).** A projecting aspect's
  attachment scopes are derived from where it is directly included (`den.include`); policy / neededBy /
  edge introduction as a projection source is deferred. Deriving it would require per-node scope
  derivation inside the resolve loop (projectors are pre-computed before it) — an implementation-
  complexity deferral, not a formal A9 stratification violation.
- **Demand edges are fleet-global (A11/A15).** The demand resolution is ONE `resolveAll` per fleet; its
  provider + consumer gen-edge records join EVERY root's edge fold (they are not attributable to a single
  scope subtree — providers target output arms, consumers target a subject-identity root). A demand-free
  fleet's demand-edge set is empty, so the fold is byte-identical to a demand-free output.
- **Per-root laziness ceiling = spines force, values stay lazy (owner tripwire (a)).** gen-edge's
  `universe` computation forces `channelsOf` — the channel-PRESENCE spine of every node in the graph —
  but never `contentsOf` (gen-edge Law E13: bucket content is never forced at derivation). So forcing
  one root's output evaluates sibling roots' presence spines (and the enrichments those spines read)
  while sibling channel VALUES stay unforced. The end-to-end suite proves both directions with a
  poisoned sibling value (`test-laziness-sibling-does-not-block` / `test-laziness-throwing-sibling-is-real`).
  Tightening the spine cost is the declared static-cone / `pipe.reads` optimization seam, out of v1 scope.

## Development

```sh
ulimit -s unlimited                    # deep module-system evals exceed the 8 MB default stack
nix-unit --flake ./ci#tests            # whole suite
nix-unit --flake ./ci#tests.<suite>    # one suite (e.g. end-to-end)
```

The `end-to-end` suite is the integration capstone: it composes the full acceptance fleet through one
`mkDen`, crosses to real `nixosConfigurations`, and pins the three no-effect-runtime tripwires
(per-root demand-laziness, inert declarations, the fixpoint census).
