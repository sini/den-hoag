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

## Typed-edge substrate laws (S1–S5, spec §2)

The typed-edge substrate (vocabulary spec §2) shares one identity scheme, one edge-kind registry, and one
pre-freeze override tier across both facets (link/merge and relation/derived). Every algorithm delegates to
a named lib (Law A1): the identity hashes to `lib/identity.nix`, the registry/override/assembly to
`lib/edges.nix` (a `mapAttrs` + validation for the registry; the identity module for the hashes; gen-edge's
`edge` for the record), the acyclicity check to the identity module. den-hoag stays nixpkgs-lib-free.

| Law | Statement | Delegates to | den-hoag file |
| --- | --- | --- | --- |
| **S1** | Two-level identity (spec §2.1, F5 nominal producer-ids) — `assemblyId = hash(entityId, class)` (content coordinate; class-share A18 keys here); `instanceId = hash(assemblyId, S)` (placement; `S` = the canonical STRUCTURAL fill map); `edgeId = hash(kind, from.instanceId, to.instanceId, dataFingerprint)`. Hashing is `sha256` of `builtins.toJSON` (attrs sort by key; LISTS preserve order — order-bearing coordinates like mount paths distinguish). | `lib/identity.nix` (`assemblyId`/`instanceId`/`edgeId`/`dataFingerprint`) | `lib/edges.nix` (`assembleEdges` composes them) |
| **S2** | Fingerprint law (spec §2.1) — a FUNCTION VALUE anywhere in `S` or in edge `data` is REJECTED with a named throw (`den.identity: function value in …`); function-valued declaration fields (`provision`/`adapt`/`derive`/`when`/…) live in registries and are referenced from edge data BY NAME (`when` is a NAME string, fingerprinted like any scalar). PRODUCED VALUES never enter `S` — only the producing node's instanceId STRING does — so identity hashing can never force content. `S` is STRICT by contract (structural scalars are forced; forcing them is correct); the discipline is "never put content in `S`", not "hashing is lazy over `S`". | `lib/identity.nix` (`rejectFunctions`) | — |
| **S3** | Strata-by-construction ctx scoping (spec §2.3/§5, A9) — the stratum order is DATA (`den.strata.insert.<name> = { after }`, dense insertion; see the Strata section). A rule declared at stratum *n* may read ONLY ctx facts of a STRICTLY LOWER stratum: a declared stratum→ctx-key map REPLACES a ≥-stratum ctx key with a NAMED THROW (not omitted — a replaced key aborts CATCHABLY when read, whereas attribute-missing escapes `tryEval`). The projection wraps ONLY the rule's FINAL dispatch produce; the value-less stratum PROBE keeps the RAW produce BY DESIGN (the probe is sentinel-only stratum detection, never a value channel). Seeded empty above structural ⇒ a no-op for every shipped rule. | `gen-dispatch` (phase order) + `gen-resolve` | `lib/declarations.nix` (`compileStrata`), `lib/concern-policies.nix` (`compileWithStrata`/`projectCtx`) |
| **S4** | Override-before-freeze (spec §2.4) — framework NEW-substrate edge intents pass through `den.overrides` BEFORE `edgeId`. `match` = pre-hash coordinates `{ kind ?; from ?; to ?; data ? { <field> = v } }` compared against the RAW (as-declared) intent: `kind`/`from`/`to` by WHOLE VALUE, `data` PER-FIELD, an absent coordinate a wildcard; a `null` field value matches both an explicitly-null and an absent field (null≡absent, deliberate); NO function-valued matchers (structural data only — the selector-language upgrade is a later step). `rewrite` = a data-patch shallow-merged into `data` (`//`) or `null` = SUPPRESS. SINGLE-STEP: one pass per edge, FIRST match wins, the rewritten edge is NEVER re-matched. A malformed coordinate throws NAMED at definition time. | `lib/edges.nix` (`applyOverrides`) | — |
| **S5** | Fill-graph acyclicity (spec §2.1) — the fill-reference graph (which producer-ids appear in whose `S`) is declared ACYCLIC, checked ONCE per assembly (`den.identity: structural-fill reference cycle …`). Nodes are PER INSTANCE, keyed by instanceId (computable pre-check — `S` never contains the node's own instanceId, so no hash regress): the check is the WELL-FOUNDEDNESS of identity computation over the declared nominal reference structure. A literal instanceId string leaf in `S` resolves directly; an entityId string leaf is instance-discriminating SUGAR — it resolves iff that entity has EXACTLY ONE instance in the assembly, else it aborts NAMED (ambiguous; resolving to all instances would re-derive the entity quotient and introduce false cycles). References feed ONLY the acyclicity check, never a hash, so the failure direction is a LOUD spurious abort (a string leaf coincidentally equal to an assembly id becomes a spurious fill edge, at worst an over-strict abort), NEVER a silent wrong identity. | `lib/identity.nix` (`checkFillAcyclic`) | `lib/edges.nix` (`assembleEdges` builds the graph) |

**The edge-kind registry (`den.edges.<kind>`, spec §2.2).** One registry describes every typed-edge kind:
`{ data ? null; requires ? null; produces ? null; discipline ? null; inverse ? null; closure ? false; stratum ? "resolution" }`. The framework pre-registers nine kinds with their strata — `contains`,
`include`, `kindOf` (structural); `member`, `reach`, `reach-suppress` (resolution); `nest`, `defer`
(**output** — a stratum the framework itself dense-inserts after `demand` through the SAME
`den.strata.insert` machinery); and `demand` (the demand-stratum kind demand's `toEdges` stamps). A user
registers beside them; re-registering a framework kind name aborts NAMED (`framework-reserved`); a
`stratum` outside the compiled order aborts NAMED; `closure = true` is validated against the disciplines
registry — the named `discipline` must EXIST there and declare `laws == "join-semilattice"` (no
discipline, an unregistered one, or a wrong-laws one each abort NAMED; closure is legal only under a
join-semilattice discipline, see the Disciplines section below). **Deferred (spec §2.2): per-kind `data` schema VALIDATION** — the
registry STORES `data`; enforcing it against edge intents lands when live producers arrive
(`assembleEdges` carries the deferral comment at the intent-validation site).

**The kind-null-=-unlabeled rendering rule (spec §2.2, §6 risk register).** gen-edge's trace key is
`(T, P, S, M[, K])` — target, path, source, mode, and the optional kind label `K`. An UN-LABELED edge
(`kind = null`, gen-edge's default) renders the historical FOUR-component key byte-identically; a LABELED
edge appends ` | <kind>` as the fifth component (and carries a `kind` field on its trace entry). So
"legacy" is simply "un-stamped" — no enumerated legacy list exists anywhere. `demand` is the first live
labeled kind (its `toEdges` records stamp `kind = "demand"`); the demand-free parity corpus is therefore
byte-untouched. This is the extension-in-place by which the demand edge-identity scheme retires.

**`edgeId` placement caveat (S1).** `assembleEdges` currently stamps the computed `edgeId` on the
synthetic record's `annotations` (inert, provenance-only). When live producers route through the pipeline,
`edgeId` must move OFF `annotations`: gen-edge folds annotations into trace entries, so an identity sha256
would enter trace goldens and a `data` change would double-ripple the trace (source key AND edgeId); and
gen-edge annotations are provenance/diagnostics never read by materialize, so a consumer keying on `edgeId`
semantically (dedup/query) needs it as a first-class field or recomputed at the read site.

## Disciplines and merge orders (`den.disciplines`, spec §5/§6)

**The registry.** `den.disciplines.<name> = { laws; empty; combine; dedup ? null; order ? null; }` names
the ALGEBRA a merge site obeys — an identity (`empty`) and a binary operation (`combine`) constrained by a
`laws` class. `compile` is one `mapAttrs` + validation (Law A1, mirroring the class/edge registries): a
missing `empty`/`combine` or an out-of-ladder `laws` aborts NAMED; the framework instance names
(`settings-layers` / `collections-neron` / `reach-closure`) are reserved (a user re-registration aborts,
the `den.edges` posture) and the framework itself seeds them. A `combine` value is a FUNCTION — a registry
holds functions freely; the fingerprint law bans functions from EDGE DATA only, never from a registry.

**The laws ladder + what each class GATES.** A subsumption chain — ordered-monoid ⊂ commutative-monoid ⊂
join-semilattice, plus `shadow` off the chain:

| class | laws | gates |
|---|---|---|
| `ordered-monoid` | associativity + identity | order-BEARING merges (last-wins-per-field / pinned sequence) |
| `commutative-monoid` | + commutativity | order-FREEDOM (ACI minus idempotence) |
| `join-semilattice` | + idempotence (ACI) | fixpoint CLOSURE — `closure = true` on an edge kind is legal ONLY under a registered join-semilattice discipline (idempotence is what makes a reachable-set iteration converge — the Datafun restriction) |
| `shadow` | right-absorption (last-wins on overlapping keys) | Leijen scoped-label record merge |

**DECLARE, not rewire (the architecture).** The three shipped folds are NOT re-wired through a shared
engine. Each is DECLARED as a discipline instance whose `combine` REFERENCES the same algebra its
production fold applies (the fold stays in its owning gen lib — Law A1). A declaration is proven to match
production by a THREE-LEG chain: (i) the property harness law-checks the `{ empty; combine }` against its
declared `laws` (with teeth — an unlawful synthetic per class RED); (ii) an ORDER ORACLE asserts the live
fold's order matches the declared `order.tiers`; (iii) a VALUE-AGREEMENT pin folds the instance's own
`combine` over the live components and reproduces the live value. So a drifted-but-lawful `combine`
reference is caught by (iii), a re-ordered fold by (ii), a false `laws` claim by (i). The `engine` field
names the production fold NOMINALLY (the fold-ENGINE leg, a reference — never a re-wire).

**The three instances.**

| instance | `laws` | `order.tiers` | `withinTier` / `tieBreak` | `dedup` | `engine` |
|---|---|---|---|---|---|
| `settings-layers` | ordered-monoid | `[schema-default, contains, slice, policy]` | `linearization` / — | — | `gen-algebra record.foldLayersTraced` |
| `collections-neron` | ordered-monoid | `[neron]` | `traversal:neron` / `a12` | — | `gen-pipe run (B5 pinned-sequence ordered fold)` |
| `reach-closure` | join-semilattice | `[structural, reach-edge]` | `traversal:subtree-dfs` / — | `{ key = aspect-ident; keep = first; appliesTo = [reach-edge] }` | `reach in-attribute ordered fold (resolved-aspects)` |

**B5 as the canonical form.** `collections-neron`'s `engine` (gen-pipe `run`, the B5 pinned-sequence
ordered fold) is the canonical merge form: every join-semilattice fold IS a valid ordered fold (an
idempotent-commutative combine folded in the pinned traversal order agrees with its unordered value), so an
ordered discipline is the general shape and a stronger-laws channel refines it in place. Stronger laws are
per-new-channel OPT-IN — a channel adopts `semilattice-set` (below) by DECLARING it; an existing instance
never silently gains stronger laws (the risk-register #6 golden pins the current laws).

**`combine`-by-reference.** `settings-layers`'s combine is `algebra.record.foldLayers { strategies = {}; layers = [a b]; }` — the same gen-algebra algebra `gen-settings.resolveAll` applies. Production calls the
TRACED variant `foldLayersTraced`; this references the untraced `foldLayers` — SIBLING implementations,
value-pinned byte-identical by gen-algebra's own suite (`traced.value == untraced`), so either fixes the
same algebra (its per-aspect strategies instantiate a strategy-indexed family of monoids; the declared
combine samples the all-`replace` representative, exact because replace/append/recursive are each
associative per field). `collections-neron`'s combine/init are the COMPILED channel record's
`.combine`/`.init` by value. `reach-closure`'s combine is a documented RESTATEMENT
(append-then-first-occurrence-dedup by `.key` — the edge-closure algebra; the fold is let-bound in the
reach attribute, no separable unit), certified by the same three-leg chain. In every case the registry's
algebra tracks the production one, and a drift is caught by the value-agreement pins.

**The reach dedup-key ruling (declaration-only, no migration).** `reach-closure.dedup.key` STAYS
`aspect-ident`: the key→id_hash migration is VACUOUS because `id_hash = hashString "den-aspect:${key}"` is a
bijection of the key (concern-aspects.nix), so the seen-set is extensionally identical under either — and
Shape B's path-bearing keys already de-collided the nested same-leaf-name shape. `dedup.appliesTo` is
`[reach-edge]` and NEVER structural: the structural-subtree component emits per-provider multiplicity
VERBATIM (distinct descendant scopes are distinct ctx-eval results — the u24 content-loss exemption) and
seeds the seen-set; dedup gates the edge closure only.

**The `shadow` HALF-CHECK precondition (before any real shadow instance).** The property harness's `shadow`
check verifies RIGHT-ABSORPTION only (`combine a b == b` on overlapping keys — total absorption); it does
NOT verify that `a`'s UNIQUE keys survive (the samples carry a full-overlap contract). Before any REAL
shadow instance registers, the check must be strengthened: a per-shared-key clause (`∀ k ∈ keys a ∩ keys b: (combine a b).k == b.k`) AND a disjoint-survival clause (`a`'s unique keys present in `combine a b`) — the
two halves of Leijen's scoped-label merge.

**The provenanceWord vocabulary (order-rendering, forward note).** A merge order renders as the word
`(tier(edgeKind), withinTierRank, A12(rank, id_hash, emissionIndex))` — the tier of the layer's edge kind,
its within-tier rank, and the A12 same-position tie-break triple (aspect rank 0 before policy rank 1, then
the producer's id_hash, then its own emission index). This is the ORDER-RENDERING vocabulary the `order`
records declare; its TRACE rendering (a per-layer provenance word in the output goldens) arrives with the
output-facet work — the declarations here are the vocabulary that consumes.

**The `semilattice-set` opt-in channel class (gen-pipe E10 landed).** A quirk channel declaring
`den.quirks.<name>.channel.merge = "semilattice-set"` gets the idempotent set-union merge: duplicate
contribution VALUES collapse (dedup by `==`), so re-contributing a present value is a no-op — the
join-semilattice ACI laws. It is realized as gen-pipe channel-construction defaults (value-keyed
first-occurrence dedup on the ordered append); the result order is FIRST-OCCURRENCE (pinned-order stable).
Value equality is by the dedup key's `toJSON` serialization — STRUCTURAL values only (`1` and `1.0` do not
collapse; a function-valued contribution is unconvertible and fails). It is OPT-IN: the default
`ordered-list` discipline is unchanged, and a caller may override `dedup`.

## Materialization registries (`den.products`/`den.conversions`/`den.renders`/`den.kinds`, spec §4)

The materialization facet is the read-through side of the pipeline: products/renders/receivers are
QUERIED, not folded. Four registries describe it, each a `mapAttrs` + validation (Law A1, mirroring the
edge/discipline registries); the dispatch rests on the gen-graph labeled-query calculus (`lib/receivers.nix`
imports the gen-graph lib). den-hoag stays nixpkgs-lib-free.

**Typed products (`den.products.<name>`, spec §4.1) — `lib/products.nix`.** A product NAMES a typed
materialization payload and the MODE its receiver consumes it in (the Bazel-provider reading — a typed
carrier flowing producer→consumer). The product→mode derivation is a TOTAL function over the nestable
products (F1's canonical machine form). The framework pre-registers the table:

| product | mode | note |
| --- | --- | --- |
| `ModulesInfo` | content | universal default — unevaluated module list |
| `RawModulesInfo` | content | raw module list, no re-eval by the receiver |
| `SystemInfo` / `HmInfo` / `DroidInfo` / `NixidyEnvInfo` / `ShellInfo` / `TerranixInfo` / `HiveInfo` | artifact | artifact faces (HiveInfo = a collector's built aggregate) |
| `EvalHandleInfo` | extend | extendModules handle; legal only under a render declaring `extendsVia` |
| `ArgsInfo` | content (`nestable = false`) | the arg-environment payload; NEVER a `consumes` |

`ArgsInfo` realizes the spec's "(non-nestable)" marker as `content` mode with `nestable = false` (a mode is
still derivable, but a non-nestable name at a `consumes` position aborts NAMED). The `mode` set is closed —
`{ content artifact extend value }`; re-registering a framework name, or declaring an out-of-set mode,
aborts NAMED. **The `ArtifactRef` WRAPPER (value mode).** `ArtifactRef P` is not a table row: it is the
PREBUILT ARM of any row consuming artifact-face `P` — a production short-circuit stamps `ArtifactRef <face>`
as the product name of the prebuilt value, injected verbatim, never evaluated by den. It is recognized
STRUCTURALLY by the `ArtifactRef ` prefix (so `modeOf "ArtifactRef P" = "value"`), and that prefix is a
RESERVED product-name namespace — a user product named `ArtifactRef …` aborts NAMED (else it would be
silently misclassified as the wrapper). `ArtifactRef` literally in a `consumes` aborts NAMED (same rule as a
non-nestable product). `checkConsumes` is the pure definition-time gate receivers reuse (unregistered /
non-nestable / literal-ArtifactRef all throw there). **Deferred:** the payload gen-schema RECORDS — this
registry holds names + modes; the payload schemas arrive with mode execution.

**Conversions (`den.conversions."<from>-><to>"`, spec §4.1) — `lib/products.nix`.** A conversion `{ via = fn; }`
materializes a `from`-typed product into a `to`-typed one at a (produces, consumes) mismatch. SINGLE-STEP:
no transitive chain search (the MLIR-style multi-hop materialization is rejected for determinism — a needed
composite is registered explicitly as its own pair). Uniqueness is GLOBAL per (from, to) pair BY KEYING:
the registry is one attrset keyed by the pair string, so two registrations of the same pair are the SAME
key — a genuine cross-module collision surfaces as the module system's unique-merge conflict at
`den.conversions."<pair>".via` (the raw type never last-wins on non-equal records → `defined multiple times` at that key path), never a silent shadow. The compile gate enforces KEY WELL-FORMEDNESS: each key
splits on `->` into EXACTLY two non-empty faces, and NEITHER face is an `ArtifactRef` — conversions NEVER
apply to the prebuilt arm (an `ArtifactRef P` accepted by a `consumes = P` row is DEFINITIONAL, no
`"ArtifactRef P->P"` lookup; a wrapped-face mismatch is an unrealized-cast, converting it would force the
prebuilt value). A missing `via`, a malformed key, or an ArtifactRef endpoint each abort NAMED.

**Renders (`den.renders.<name>`, spec §4.3) — `lib/renders.nix`.** A render NAMES how a class materializes.
It is the D7 PROMOTION of the shipped `{ evaluator; output }` instantiation record into a full registry row:

| field | role |
| --- | --- |
| `evaluator` | the ONE nixpkgs crossing (`{ modules, specialArgs } -> system`), inert data |
| `provision` | per-render provisioning data (pkgs/system/specialArgs/…), supplied as data, never a module injection |
| `adapt` | binds only functionArgs-declared args, lazily |
| `face` | builds the artifact from an eval |
| `produces` | the product this render emits (validated ∈ the products table) |
| `requires` | the products it consumes (each validated ∈ the products table; definition-time CONSUMPTION arrives with the families work) |
| `params` | the finite axes — `params ? [ ]` here (NO phantom `["system"]` axis until the axis-validation work lands); names-only in this step |
| `extendsVia` | the extend-mode capability flag (stored; consumed by extend mode later) |
| `compatibleWith` | the compatibility predicate (stored) |
| `output` | the flake-parts target the built systems mount at (D7 field, KEPT; a later families registry supersedes it) |

The compile is PER-FLEET (invoked inside the mkDen closure): the built-in `nixos`/`darwin` rows derive their
evaluators from the fleet's OWN `den.nixpkgs`/`den.darwin` inputs (null input ⇒ null evaluator ⇒ the
nixpkgs-free `collect` fallback), so the lib holds compile + validation and NEVER the evaluators. These
built-in rows are THE single source of the instantiation base — the old separate defaults tier is DELETED.
**The precedence law (read-through):** `classes.instantiation` ≻ renders row ≻ nothing. `instantiationOf`
reads the row's `{ evaluator; output }` as the BASE, with the `den.classes.<name>.instantiation` D4 overlay
on top (a class setting its own `instantiate` overrides everything). The built-in rows are byte-identical to
the deleted defaults, so the promotion is transparent — a fleet declaring nothing is unchanged.

**Receives (`den.kinds.<outerKind>.receives.<slot>`, spec §4.2) — `lib/receivers.nix`.** The graft-site rule
as DATA on the outer kind. A row is
`{ at; consumes; arity ? "many"; render ? null; provide ? null; adapt ? null; identity ? null; shape ? null; multiplicity ? "error"; }`.
`at` is `point: inner: [ …path ]` (paramPoint-first placement). The MODE is DERIVED — `row.mode = modeOf consumes` (F1's canonical machine form; the mode names are a docs/trace taxonomy, never a field). **F1 as a
checked law:** a user-declared `mode` field aborts NAMED. `consumes` passes `checkConsumes` (the products-
table gate). `render` names a registered render AND is legal ONLY on an artifact-mode OR extend-mode row — an
artifact row consults the render's `evaluator`/`face` to build its face, an extend row consults the render's
`extendsVia` capability (spec §4.3 — `extendsVia` lives on the render row, so an extend consume needs a render
reference too); a `render` on a content-mode or value-mode `consumes` aborts NAMED. `arity ∈ { many singular }`
(the singular live-edge enforcement runs at BOTH depths, see Nest-mode execution below — two predicate-
differing edges into one singular mount both firing throws), `multiplicity ∈ { error multi }` — out-of-domain
aborts NAMED. **The
hook-scoping corollary (the row contract):** `at` receives STRUCTURAL handles only (the paramPoint + the
inner's structural face), never resolved graph state; `identity`/`provide`/`adapt` results are LAZY (the
S-hashing law — a produced value never enters the structural fill, only the producing node's structural
reference does). Duplicate slot rows are impossible by attrset construction.

**The kind-include relation (`den.kinds.<kind>.includes`).** `includes` is a list of KIND NAMES — receiver
inheritance BETWEEN KINDS (kind B including kind A inherits ALL of A's receives rows). It sits on the KIND
ENTRY (a sibling of `receives`), never on a receives row — inheritance is a kind→kind relation, and the
dispatch lowers one include-set per kind. It is the receives-registry's OWN relation (NOT v1 schema
`.includes` — aspect-content — nor `ent.meta.parent` — containment). A row-level `includes` aborts NAMED
pointing up ("lives on `den.kinds.<kind>`, not on a receives row"); an unknown include target aborts NAMED.
**The reserved kind name `kinds`.** A kind mounts at `options.den.<kindName>`, so a kind literally named
`kinds` would collide with the framework `den.kinds` concern option — a fleet declaring one aborts NAMED at
kind discovery.

**The dispatch (spec §4.2 ruling F4) — `resolveReceiver { compiledKinds; outerKind; slot; class }`.** The
slot ≻ class lookup executed as NAME RESOLUTION (Néron et al. 2015 — resolution as a reachability query over
a scope graph; the visible declarations are the nearest un-shadowed ones). It is a REAL gen-graph VISIBLE
query over the kind-include graph, no hand-rolled walk: `graph.labeledFrom { include = k: …includes; }`
lowers the graph; `graph.query { follow = regex.parse "include*"; where = <row-presence>; mode = "visible"; groupBy = <constant slot>; }` finds the nearest carrying kind(s). Nearest-wins is the default prefix-wins
word order (a proper prefix beats its extensions). The mechanics:

- **Two-phase slot ≻ class.** Resolve the `receives.<slot>` rows first; on EMPTY (not on ambiguity), fall
  back to `receives.<class>` rows. The containment slot kind beats the inner's class kind — cuda (class
  `nixos`, slot `vm`) fires `receives.vm`, the class row never misroutes it.
- **Inheritance + shadowing.** An included kind's row is inherited; the outer kind's own row (nearer) SHADOWS
  an inherited one.
- **Diamond node-dedup.** Per-path enumeration answers a diamond-reachable kind once PER PATH with equal-rank
  words; the visible answers are deduped BY NODE (first-occurrence, nearest-first order preserved) before the
  precedence check, else a legal diamond throws a false ambiguity.
- **The unanimous-multi rule.** A tie of DISTINCT carrying kinds at the winning depth aborts NAMED naming ALL
  the tied kinds — UNLESS every tied row declares `multiplicity = "multi"` (then they coexist, all returned
  visible-ordered). The opt-out must be UNANIMOUS: a tied set that DISAGREES (some `multi`, some `error`) is
  its own named error (else the outcome would hinge on visible-order position).
- **Legal null + laziness.** No rows anywhere returns `null` — a LEGAL no-receiver result (mode execution
  decides its meaning). Only the WINNER's row value is forced — a reachable-but-shadowed loser's row value
  stays a thunk (`where` probes row PRESENCE, attr names, never the value).

## Nest-mode execution (spec §4.2/§4.3/§4.8) — `lib/nest.nix`

Mode EXECUTION realizes the receives rows on the live nest edges: `resolveReceiver` (above) DECLARES + picks
the graft-site row; `executeNest` EXECUTES it, turning a compiled row + the inner entity's product face into a
mode-tagged CONTRIBUTION the fold places. It is a `mode` dispatch + pure attrset assembly per arm — no
fixpoint, no gen-graph walk (the dispatch already ran). `nest.nix` is NIXPKGS-FREE (the sole nixpkgs crossing
stays `output/terminal.nix` — the engine wires module faces without evaluating them); the per-fleet product /
conversion / render tables are threaded at CALL time (the receivers pattern — the engine holds no tables or
evaluators).

**The executor contract — `executeNest { row; inner; ctx; conversions ? {}; renders ? {} }`.** `row` is a
compiled receives row (or one element of a `resolveReceiver` multi-winners list); `inner` is
`{ product; payload; }` (or the prebuilt `artifactRef` arm) plus the inner's structural FACE fields
(name/kind/…); `ctx` carries STRUCTURAL handles ONLY (the §2.1 corollary — name/kind/slot/ids/paramPoint, NO
content). THE LAZINESS LAW: the engine may not force `inner.payload` (nor call an evaluator / `extendsVia` /
`provide` / `adapt`) during wiring — a contribution's shape (mode + attr names) is forcible while every
payload-bearing field stays a thunk. **The `at` call convention:** `at = point: inner: [ …path ]` returns ONE
path (`[]` ⇒ FLAT, a root merge); `point` is the structural paramPoint HANDLE; the executor STRIPS the payload
before calling `at` (`removeAttrs inner [ "payload" ]`), so `at` sees the inner's structural face, never its
content. The engine builds the contribution; the CALLER places it (the live mount + families/collectors
consume the contributions and arrive with the families work).

Each mode returns exactly its contribution row (`mkContribution mode extra`, so the mode tag is written once):

| mode | contribution | lazy fields |
| --- | --- | --- |
| content | `{ mode = "content"; at = <path>; modules = [ … ]; }` | each placed module |
| artifact | `{ mode = "artifact"; at; artifact = <thunk>; }` | `artifact` (the render call) |
| extend | `{ mode = "extend"; at; extended = <thunk>; }` | `extended` (the `extendsVia` call) |
| value | `{ mode = "value"; at; value = <verbatim>; unrealizedCast ? <marker>; }` | `value` |
| defer | `{ mode = "defer"; needs = [ paths ]; thenFn; }` — INERT record | `thenFn` |
| (provide rider) | `provideArgs = { specialArgs = <thunk>; argsModule = <module>; }` | both |
| (adapt rider) | `adaptEnv = <argEnv>` | the bindings (bound at the mount) |

**Per-mode laws.**

- **content — one shared fixpoint.** The inner's `ModulesInfo` module list grafted at the `at` path (`[]` ⇒
  flat, else each module nested under the path via the fold's own `nestAtPath`/`placeSlice` primitive). THE
  ANCHOR (the sub-plan's oracle): the executor's GRAFT equals the live fold's own placement, byte-identically,
  on the projection fixture — the honest half is PLACEMENT (the executor genuinely performs the at-path wrap; a
  wrong wrap fails the leg); the reach-based gather stays the fold's, not the executor's.
- **artifact — isolated inner eval, the sole forcing boundary.** The render row (`renders.${row.render}`)
  crosses the inner's modules in ISOLATION — the render call is the sole point the inner is forced. The eval is
  `renderRow.evaluator payload`; `face` projects it (`face eval`), or a NULL `face` means the eval ITSELF is
  the artifact. A null `row.render` on an artifact consume aborts NAMED (an artifact has no way to build its
  face without a render). `provision`/`adapt` on the render row stay data (the provisioning + arg-crossing
  wiring is the families step).
- **extend — legal only under `extendsVia`.** The `extended` thunk wraps the consulted render's `extendsVia`
  capability applied to the inner's `EvalHandleInfo` payload (the extendModules handle). Legal ONLY when the
  render declares `extendsVia`; a null `row.render` OR a render without `extendsVia` is ONE named
  missing-capability throw (`extendsVia` lives on the render row, §4.3).
- **value — the prebuilt arm, injected verbatim.** An `inner` carrying the `artifactRef` wrapper is the
  prebuilt value: injected VERBATIM, never evaluated, never converted (ArtifactRef acceptance at `consumes = P`
  is DEFINITIONAL, and value acceptance is MODE-INDEPENDENT — it short-circuits before any mode dispatch, so a
  prebuilt value satisfies an artifact-mode row too). A wrapped-face MISMATCH (`artifactRef.product ≠ consumes`)
  sets the `unrealizedCast` trace marker — a trace-visible node, NEVER an eval failure. The entity-side surface
  is `aspects.<name>.artifact = <value>` (a facet-category key, routed as behaviour by `classifyKey`); its
  EXCLUSIVITY law (`artifactExclusive`): a prebuilt aspect's class buckets must be EMPTY — declaring `artifact`
  alongside non-empty class content aborts NAMED (fired at the projection terminal). Synthetic until the
  families provide a consumer.

**The conversions consult (spec §4.1).** On a (produces, consumes) mismatch the executor does EXACTLY ONE
single-step lookup in the compiled conversion table (`"<from>-><to>"`): found ⇒ `via` applied LAZILY to the
payload, the contribution proceeds under the row's mode; not found ⇒ a named mismatch throw. NO chain search
(the MLIR-style multi-hop materialization is rejected for determinism — a needed composite is its own
registered pair). Conversions NEVER apply to the prebuilt arm (value acceptance is definitional). A
cross-module registration of the same `"<from>-><to>"` pair with a differing `via` surfaces as the module
system's unique-merge conflict at the `.via` key (the `raw` type never last-wins on non-equal records).

**The cross-cutting riders (spec §4.8) — attach to the mode contribution on ANY mode.**

- **provide.** `row.provide = outer: attrs` supplies args crossed from the OUTER to the inner. The rider
  carries BOTH delivery arms of the SAME `provide ctx` result, LAZILY: `specialArgs` (the extraSpecialArgs-
  style arm, for a crossing that exposes special args) and `argsModule = { _module.args = args; }` (the
  fallback). Which arm a crossing uses is the caller's choice (the families step). THE RESTRICTION: `_module.args`
  values are UNUSABLE in `imports` (the module system evaluates `imports` before `_module.args` is available),
  so an arg a downstream module needs in ITS `imports` must ride the `specialArgs` arm.
- **adapt.** `row.adapt` is the arg ENVIRONMENT; the `adaptEnv` rider carries it verbatim (the BINDING happens
  at the mount, the families step). `bindArgs argEnv fnModule` is the pure binder — `intersectAttrs` over
  `builtins.functionArgs` binds ONLY the args the function-module DECLARES, lazily (a `{ osConfig, ... }:`
  module binds `osConfig`; an undeclared arg in `argEnv` is never selected, so it never forces; a non-pattern
  `_:` fn binds nothing). `ArgsInfo` (content-mode, non-nestable — `checkConsumes` blocks it as a `consumes`)
  is the arg-environment product vocabulary; `adapt` is its legal consumer.
- **defer.** `executeDefer { record }` lowers the R6 record `{ needs = [ paths ]; then = vals: config; }` to
  the INERT contribution `{ mode = "defer"; needs; thenFn; }` — no terminal consumer yet (no `mkMerge` splice).
  `then` is a Nix KEYWORD, so the record's field is a QUOTED/DYNAMIC field (`{ "then" = …; }` / `record.${"then"}`),
  never bare, surfaced as the keyword-free `thenFn`. The one executable check: a `then` producing `options`/
  `imports` aborts NAMED (a defer produces config only) — fired when `thenFn` is APPLIED, so the record stays
  inert until a consumer applies it. THE `__configThunk` RELATIONSHIP: den-hoag already ships a deferred
  mechanism (a config-demanding aspect fn rides `deferredToThunk` → gen-bind's `__configThunk`, resolved at the
  producing scope at the terminal); R6 formalizes the same contract, so the families consumer either LOWERS
  this record onto the `__configThunk` path or RETIRES both into one — never a third defer surface.

**Singular arity at both depths (spec §4.2).** "Two predicate-differing edges into one singular mount both
firing throws" is enforced at BOTH depths, one pure check per phase where its data lives:

- **definition-time — `receivers.checkSingularDefinition { row; intents; mount }`** (the `den.kinds:` register).
  Over the UNCONDITIONAL intents (no `when`): two unconditional intents into a singular mount are a static
  double-mount that can never be legal, so they abort NAMED before the identity freeze. A CONDITIONAL intent
  (carrying a `when`) may never co-fire, so it PASSES and defers to wiring.
- **wiring-time — `nest.checkSingular { row; edges; mount }`** (the `den.nest:` register). Over the LIVE edge
  set (post-`when`, the fired edges): a singular mount with more than one live edge aborts NAMED, naming the
  mount + every live edge id.

`arity = "many"` never throws at either depth. RETURN-CONTRACT asymmetry: `checkSingular` returns the post-
`when` live set on the singular path but the input `edges` unchanged on the `many` path (the `when` filter is a
singular-arity concern only); `checkSingularDefinition` returns `intents` unfiltered on every pass path (it
inspects the unconditional subset only to decide the throw, never to reshape the result).

**Forward.** The live mount + output families + collector aggregates consume these contributions and are
receiver-dispatched like every other outer, arriving with the families work; the root entity is one such
outer. `unrealizedCast`'s row/slot locus is decided when the trace consumer lands. Should per-edge dispatch
profile hot, a per-fleet resolver-hoist seam (`mkReceiverResolver`, closing the dispatch once over one fleet's
compiled kinds) is the natural addition.

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
- **Disciplines: join-semilattice fixpoints — Arntzenius & Krishnaswami, "Datafun" (ICFP 2016).** A
  monotone fixpoint's carrier is restricted to a join-semilattice — idempotence is what makes the
  reachable-set iteration converge. `reach-closure`'s `join-semilattice` laws and the `closure = true`
  edge-gate are this restriction.
- **Disciplines: ACI convergence — Shapiro, Preguiça, Baquero & Zawirski, "Conflict-free Replicated Data
  Types" (SSS 2011).** A CRDT is the convergent instance of an associative-commutative-idempotent merge;
  the `semilattice-set` channel class (gen-pipe E10) is that algebra.
- **Disciplines: the `shadow` merge — Leijen, "Extensible records with scoped labels" (TFP 2005).** The
  scoped-label last-wins record merge — right-absorption on overlapping keys with disjoint-key survival.
- **Disciplines: static order declarations — Kastens, "Ordered attribute grammars" (Acta Informatica
  1980).** The `order` records (tiers + within-tier rank) are static evaluation-order declarations over the
  attribute schedule.
- **Dispatch: name resolution as reachability — Néron, Tolmach, Visser & Wachsmuth, "A Theory of Name
  Resolution" (ESOP 2015).** `resolveReceiver` is name resolution over a scope graph: the kind-include
  relation is the include-edge relation, and the slot ≻ class lookup is a visible-declarations query
  (nearest un-shadowed) via gen-graph's `visible` mode. `den.kinds.<kind>.includes` is receiver inheritance.
- **Materialization: typed providers — Bazel's provider model.** Products are typed carriers flowing
  producer→consumer (a render `produces` / a receiver `consumes`); the mode is derived from the product, and
  conversions are the single-step materializations bridging a (produces, consumes) mismatch.

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
| `deliver` | `{ from; to; at ? []; mode ? "merge"; guard ? null; adaptArgs ? null }` | resolution | The base delivery surface (`deliver.nix`); produces a `{ __delivery = true; … }` descriptor, compiled to a `delivery` declaration at fire time (Law C2). `from` = class name (route case) or `{ module }` (provide case). `mode` ∈ {merge, nest, verbatim}; verbatim on a module source aborts. |
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

## Strata (`den.strata`, spec §5)

The stratum order is DATA. The SEEDED order is `structural < resolution < collection < demand`; a fleet
extends it through the module surface:

```nix
den.strata.insert.<name> = { after = "<existing stratum>"; };
```

Each name-keyed insert places a NEW stratum DENSELY — immediately after its `after` anchor
(`lib/declarations.nix` `compileStrata`). The compiled order is what every consumer reads (`kindToStratum`,
the gen-resolve schedule feed, edge-kind `stratum` validation); with zero inserts it is byte-identical to
the seed. Determinism: inserts are placed lexicographically by name, so multiple inserts after the SAME
anchor keep lexicographic order; an insert whose `after` is itself an insert resolves once that anchor is
placed (a ready-set fixpoint over the lex-ordered names). A name colliding with an existing stratum, or an
`after` that never resolves (unknown or cyclic), aborts NAMED at definition time. The framework's own
`output` stratum is registered through THIS mechanism (inserted after `demand`).

**Capability-scoped rule ctx (A9 stratification-by-construction).** A rule declared at stratum *n* may read
ONLY ctx facts of a STRICTLY LOWER stratum. The compiler (`lib/concern-policies.nix` `compileWithStrata`)
carries a DECLARED stratum→ctx-key-groups map; a ctx key whose declared stratum is ≥ the rule's own is
REPLACED with a NAMED THROW (not omitted — a replaced key aborts CATCHABLY when the body reads it, whereas an
attribute-missing read escapes `tryEval`). The projection wraps ONLY the rule's FINAL (dispatch) produce; the
value-less stratum PROBE keeps the RAW base produce BY DESIGN — the probe is sentinel-only stratum detection,
never a value channel, so projecting it would conflate the two. The seeded ctx-key map is empty above the
structural stratum (today's rule ctx is entity BINDINGS — inherited/enriched/linked context — all
structural), so the projection is a no-op for every shipped rule.

**Documented tension.** Once a ctx key carries a ≥-structural stratum tag, per-phase EXPANSION (the
value-conditional policy split into one sub-rule per covered stratum) and a body that READS that tagged key
become mutually exclusive: a sub-rule at a stratum below the key's would throw on the read. Such a rule must
therefore be a DECLARED-stratum rule (a record `{ __condition; fn }` fixing its single stratum), not an
expansion policy — the honest consequence of making ctx capability-scoped.

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
