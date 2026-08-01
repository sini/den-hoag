# Attribute assembly + resolve seam. `equations` builds the full HOAG equation map — the
# structural stratum (attrs 1–6, structural.nix) merged with the resolution stratum (attr 7,
# resolved-aspects.nix); `runResolve` hands (roots, equations, parseParent) to gen-resolve.resolve,
# which forces the Vogt gate + two-stratum assert at construction (§8-step2). den over-declares
# read-edges via readsAttrs, so the separate declaredEdges accessor stays empty until later tasks
# refine it per attribute.
{
  prelude,
  scope,
  resolve,
  dispatch,
  aspects,
  select,
  pipe,
  product,
  settings,
  settingsLib,
  projects,
  scopeAdapter,
  declarations,
  edge,
  bind,
  class,
  merge,
  errors,
  graph,
  strataScope,
  # The §4.2 nest-mode execution engine (lib/nest.nix), threaded to the output fold for its `placeSlice`
  # graft law — the fold's route placement and nest-mode execution are one placement, not two.
  nest,
}:
let
  # The A10 class-share build path (gen-class tier-2/tier-3). Imported here so the output stratum can
  # route a `share.core = true` class through it; nixpkgs-lib-free like the rest of lib/**.
  classShare = import ../output/class-share.nix { inherit prelude class errors; };
  structural = import ./structural.nix {
    inherit
      prelude
      scope
      resolve
      dispatch
      declarations
      errors
      ;
    # The cell/root discriminator, bound with the libs rather than per fleet — a fixed pure predicate
    # over the id shape, so it has no per-fleet content to thread. See structural.nix's header.
    inherit (import ../build-roots.nix { inherit prelude; }) isCellNode;
    # THE PER-NODE SELECTION MATCHER. A rule and a node id to whether the rule's `selects` admits that
    # node, decided by gen-select in the scope context over the in-flight resolve eval. Bound with the
    # libs for the same reason `isCellNode` is: it carries no per-fleet content — the eval it reads is
    # the `self` its caller applies it to, which is why the eval is the FIRST argument and not a
    # captured one. The ctx extension is empty: selection reads a node's kind and its position in the
    # scope graph, both of which the base scope context already carries.
    matchAt =
      self: r: id:
      scopeAdapter.matchIdWith { eval = self; } { } r.selects id;
  };
  resolvedAspects = import ./resolved-aspects.nix {
    inherit
      prelude
      scope
      resolve
      aspects
      select
      graph
      errors
      ;
  };
  collections = import ./collections.nix {
    inherit
      prelude
      scope
      resolve
      pipe
      scopeAdapter
      errors
      aspects
      ;
  };
  resolvedSettings = import ./resolved-settings.nix {
    inherit
      prelude
      product
      settings
      settingsLib
      projects
      errors
      ;
  };
  classModules = import ./class-modules.nix {
    inherit
      prelude
      resolve
      graph
      ;
  };
  outputModules = import ./output-modules.nix {
    inherit
      prelude
      scope
      edge
      bind
      merge
      classShare
      errors
      nest
      ;
  };
  # §11 Phase 1 — the resolution-stratum relation/derived accessor equations (delivery moved off the top-level
  # closures INTO the ONE equations map). Imports the concern libs directly (like the `classShare` import
  # above) so the equations builder needs no new top-level lib args — only the per-fleet DATA is threaded.
  resolutionRelations = import ./resolution-relations.nix {
    inherit resolve strataScope;
    relations = import ../concern-relations.nix { inherit prelude strataScope; };
    derived = import ../concern-derived.nix { inherit prelude strataScope; };
    query = import ../query.nix { inherit prelude graph; };
  };
  # §5 Phase 5a — the resolution-facet production equations. Each `den.productions` entry compiles to a
  # synthesized attr equation (`resolve.attr`, PASSTHROUGH over the production's own `compute`), merged into
  # the ONE equations map like the relation/derived accessors. The vocabulary + laws validation is the
  # definition-time guard (default.nix); this only builds the attr records. See concern-productions.nix.
  resolutionProductions = import ../concern-productions.nix { inherit prelude strataScope resolve; };
  # den-hoag §5 / §9 — the claim-accessor: the reverse-read (who-claims-me) resolution equation over the off-trace
  # claim pool, the transpose (Mokhov 2017 §5.2) of the leaf-claim forward adjacency. Sibling of the relation
  # accessors; its per-node handle carries the node.query/node.rel silent-vs-throwing contract. See the file.
  claimAccessor = import ./claim-accessor.nix {
    inherit prelude resolve strataScope;
    transpose = graph.transpose;
  };
in
{
  # The full equation map. Structural attributes shape the graph (they never read a resolution
  # attribute — the gen-resolve schedule enforces it); attr 7 (resolution) reads structural +
  # ancestor resolution (top-down, acyclic along containment); the collection attrs (10/11 +
  # `local-demand-data`) read the resolution + collection strata (and the structural `declarations`,
  # like `neron-order` reads `imports`), so they schedule cleanly beneath both. `localDemandData` is
  # the demand concern's collection attribute (lib/demand.nix); it merges in as attribute
  # `local-demand-data`.
  equations =
    {
      policiesIndex,
      fleetChildren,
      linkTarget ? (_: null),
      allAspects ? { },
      directIncludes ? [ ],
      # The post-inheritance resolution-ctx enrichment hook (native default = identity), threaded to
      # resolved-aspects for the aspect-fn ctx enrichment (A17-lazy; see resolved-aspects.nix `ctx`).
      enrichContext ? ({ bindings, ... }: bindings),
      quirkDag,
      classOfNode,
      channelNames,
      # The consumer's nixpkgs lib (`den.nixpkgs.lib`), threaded to collections for pipeline-parametric
      # `lib`-arg injection; null on the pure/nixpkgs-free path (§2.10 inert-config seam).
      consumerLib ? null,
      localDemandData,
      classNames,
      classifyKey,
      # The declared key category (`aspectSchema.keyCategory`) the class-content producer refuses reserved
      # channels on. Threaded from the SAME schema instance `classifyKey` comes from, so one builder never
      # carries two classification authorities.
      keyCategory,
      relationEdges ? [ ],
      relationEdgeKinds ? { },
      strataOrder ? [ ],
      derivedTable ? { },
      # §5 — the guard-validated `den.productions` table; `compile` lowers each entry to the P5b taxonomy
      # (attr / nta / two-equation), whose `.equations` merge into the map (claim-edge intents thread out to
      # the relation pool in default.nix). Empty ⇒ `{ }` ⇒ byte-identical to the pre-productions equation map.
      productions ? { },
      # §9 — the claim-kind → `{ stratum }` index (the names of the `emit = edges` from = ∅ leaf-claim
      # productions, with their strata) driving the claim-accessor reverse-read. Empty ⇒ the claim-accessor's
      # handle is inert (`.query` constantly `[ ]`, `.rel` `{ }`) ⇒ byte-identical.
      claimKinds ? { },
      # THE COORDINATE PROJECTIONS over the `contains` edge pool (lib/coordinates.nix), built once per
      # fleet in `mkDen` and threaded to every reader of a node's position: the settings cascade
      # (`mkSettingsProduction`, seeded through `den.productions`), the §B4a ancestor visibility read
      # (`resolved-aspects`), and the producing-scope coordinate a contribution carries (`collections`).
      # ONE derivation, several callers — which is the point: the retired shape had a payload cache in
      # one file and a negative `removeAttrs` enumeration in two others, and the settings reader chose
      # between them on whether the cache was present.
      coords,
    }:
    (structural { inherit policiesIndex fleetChildren linkTarget; })
    // {
      # Only the EQUATION records enter the equations map — `resolved-aspects` (attr 7) and `reach` (the
      # P-PROJECT closure, a resolve.attr record). The reach-edge/reach-suppress declaration reads
      # (`reachEdgesOf`/`reachSuppressOf`) are fully internal (`let`-bound in resolved-aspects.nix, consumed
      # inside `reach`), witnessed through `reach` — never spread here (gen-resolve iterates equation values
      # as sets; a bare helper lambda would break the two-stratum classification).
      inherit
        (resolvedAspects {
          inherit
            allAspects
            directIncludes
            enrichContext
            ;
          inherit (coords) containAncestorIds;
        })
        resolved-aspects
        reach
        ;
    }
    // (collections {
      inherit
        quirkDag
        classOfNode
        channelNames
        consumerLib
        ;
      inherit (coords) nodeCoords;
    })
    // {
      # Only the EQUATION records enter the map: `class-relocation` (the per-scope relocation relation Ρ(S),
      # resolved once at the OWNING scope so every consumer of that scope's content reads one answer),
      # `class-seeds` (the per-(node, channel) content query, consumed by `classSubtreeAt`'s cross-scope
      # shared-aspect dedup) and `content-key-totality` (its §2.2 classification driver) — `classSliceAt`
      # (the factored relocation-aware extraction, exported alongside) is a bare function threaded to
      # `mkOutputModules` (below).
      inherit (classModules { inherit classNames classifyKey keyCategory; })
        class-relocation
        class-seeds
        content-key-totality
        ;
    }
    // {
      local-demand-data = localDemandData;
    }
    # The settings resolution facet (`resolved-settings`) is no longer a hand-wired equation here — the
    # framework SEEDS it as a `den.productions` entry (mkSettingsProduction, keyed by the attr it emits) and
    # it arrives through the same `resolutionProductions.compile` pass as every other production (below).
    // (resolutionRelations {
      inherit
        relationEdges
        relationEdgeKinds
        strataOrder
        derivedTable
        ;
    })
    // (claimAccessor {
      inherit
        relationEdges
        strataOrder
        claimKinds
        ;
    })
    // (resolutionProductions.compile { inherit productions; }).equations;

  # The narrow accessor (A10) builder — depends only on the aspect registry + the final eval, not the
  # resolved-settings instance args, so den-hoag applies it once at the top level. `mkSettingsProduction`
  # builds the settings resolution facet AS a `den.productions` record (the framework's own seed, §5).
  inherit (resolvedSettings) mkNarrowAccessor mkSettingsProduction;

  # The output builder (attribute 12) — the gen-edge fold's graph accessor + `outputFor`/`traceFor`,
  # and the per-class terminal crossing. Reads the FINAL eval (not an in-flight `self`), so den-hoag
  # applies it once at the top level (like the narrow accessor).
  mkOutputModules = outputModules;

  # THE ONE relocation-aware class-slice extraction + §2.2 totality assertion, built per-mkDen with the
  # DISCOVERED `classifyKey` and threaded to `mkOutputModules` (so `projectClass` and the `class-modules`
  # buckets share exactly one extraction, and `projectClass` enforces the unregistered-key totality abort
  # over every reached aspect). `classNames` is inert for these FOUR bare functions: `classSliceAt` reads
  # `classifyKey`, `prelude`, `keyCategory` (the source-side reserved-channel refusal) and the eval handle
  # it is passed, and the added `sourceOrderOf` reads `keyCategory` and that same handle — neither ever
  # reads `classNames`, which is load-bearing only for the `class-relocation` memo's own domain. It is
  # passed here to satisfy the class-modules instance signature.
  mkClassSlice =
    {
      classNames,
      classifyKey,
      # The declared key category, from the same schema instance as `classifyKey` (see `equations` above).
      keyCategory,
      # §4.1 the prebuilt-arm exclusivity (concern-aspects `artifactExclusive`), forced inside
      # `assertKeysRegistered` at the projection terminal. Defaults to the identity pass — inert unless threaded.
      artifactExclusive ? (_: true),
    }:
    let
      cm = classModules {
        inherit
          classNames
          classifyKey
          keyCategory
          artifactExclusive
          ;
      };
    in
    {
      inherit (cm)
        classSliceAt
        sourceOrderOf
        assertKeysRegistered
        forwardSourceClassesOf
        ;
    };

  # Expose the structural builder for the suite's minimal-scenario scaffolding (b2 builds
  # structural equations over hand-built roots/rules).
  inherit structural;

  # The raw class-content producer builder (`{ classNames; classifyKey; keyCategory; … }` → the
  # `class-relocation` / `class-seeds` / `content-key-totality` equation records), for the
  # class-bucket-query and class-relocation suites' direct per-node class-slice + relocation scenarios.
  # An instrument driving these supplies DATA — its own class names and the schema instance describing
  # them — never a hand-written classifier, which would be a second classification algorithm living in a
  # test and free to drift from the kernel's.
  classModulesBuilder = classModules;

  runResolve =
    {
      roots,
      equations,
      parseParent,
      declaredEdges ? (_: [ ]),
      strataOrder ? [
        "structural"
        "resolution"
      ],
    }:
    resolve.resolve {
      inherit
        roots
        equations
        parseParent
        declaredEdges
        strataOrder
        ;
    };
}
