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
  };
  resolvedAspects = import ./resolved-aspects.nix {
    inherit
      prelude
      scope
      resolve
      aspects
      select
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
      ;
  };
  # §11 Phase 1 — the resolution-stratum relation/derived accessor equations (delivery moved off the top-level
  # closures INTO the ONE equations map). Imports the concern libs directly (like the `classShare` import
  # above) so the equations builder needs no new top-level lib args — only the per-fleet DATA is threaded.
  resolutionRelations = import ./resolution-relations.nix {
    inherit resolve;
    relations = import ../concern-relations.nix { inherit prelude strataScope; };
    derived = import ../concern-derived.nix { inherit prelude strataScope; };
    query = import ../query.nix { inherit prelude graph; };
  };
  # §5 Phase 5a — the resolution-facet production equations. Each `den.productions` entry compiles to a
  # synthesized attr equation (`resolve.attr`, PASSTHROUGH over the production's own `compute`), merged into
  # the ONE equations map like the relation/derived accessors. The vocabulary + laws validation is the
  # definition-time guard (default.nix); this only builds the attr records. See concern-productions.nix.
  resolutionProductions = import ../concern-productions.nix { inherit prelude strataScope resolve; };
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
      policiesRules,
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
      relationEdges ? [ ],
      relationEdgeKinds ? { },
      strataOrder ? [ ],
      derivedTable ? { },
      # §5 Phase 5a — the guard-validated `den.productions` table; each entry compiles to a passthrough attr
      # equation merged into the map. Empty ⇒ `{ }` ⇒ byte-identical to the pre-Phase-5a equation map.
      productions ? { },
    }:
    (structural { inherit policiesRules fleetChildren linkTarget; })
    // {
      # Only the EQUATION records enter the equations map — `resolved-aspects` (attr 7) and `reach` (the
      # Phase-1 P-PROJECT closure, a resolve.attr record). The reach-edge/reach-suppress declaration reads
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
    })
    // {
      # Only the EQUATION record `class-modules` enters the map — `classSliceOf` (the factored per-aspect
      # extraction, exported alongside) is a bare function threaded to `mkOutputModules` (below), never here.
      inherit (classModules { inherit classNames classifyKey; }) class-modules;
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
    // (resolutionProductions.compile { inherit productions; });

  # The narrow accessor (A10) builder — depends only on the aspect registry + the final eval, not the
  # resolved-settings instance args, so den-hoag applies it once at the top level. `mkSettingsProduction`
  # builds the settings resolution facet AS a `den.productions` record (the framework's own seed, §5).
  inherit (resolvedSettings) mkNarrowAccessor mkSettingsProduction;

  # The output builder (attribute 12) — the gen-edge fold's graph accessor + `outputFor`/`traceFor`,
  # and the per-class terminal crossing. Reads the FINAL eval (not an in-flight `self`), so den-hoag
  # applies it once at the top level (like the narrow accessor).
  mkOutputModules = outputModules;

  # THE ONE per-aspect class-slice extraction + §2.2 totality assertion (Task 2/3), built per-mkDen with the
  # DISCOVERED `classifyKey` and threaded to `mkOutputModules` (so `projectClass` and the `class-modules`
  # buckets share exactly one extraction, and `projectClass` enforces the unregistered-key totality abort
  # over every reached aspect). `classNames` is inert for both (they read only `classifyKey` + `prelude`),
  # passed to satisfy the class-modules instance signature.
  mkClassSlice =
    {
      classNames,
      classifyKey,
      # §4.1 the prebuilt-arm exclusivity (concern-aspects `artifactExclusive`), forced inside
      # `assertKeysRegistered` at the projection terminal. Defaults to the identity pass — inert unless threaded.
      artifactExclusive ? (_: true),
    }:
    let
      cm = classModules { inherit classNames classifyKey artifactExclusive; };
    in
    {
      inherit (cm) classSliceOf assertKeysRegistered;
    };

  # Expose the structural builder for the suite's minimal-scenario scaffolding (b2 builds
  # structural equations over hand-built roots/rules).
  inherit structural;

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
