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
  errors,
}:
let
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
      resolve
      product
      settings
      settingsLib
      projects
      errors
      ;
  };
in
{
  # The full equation map. Structural attributes shape the graph (they never read a resolution
  # attribute — the gen-resolve schedule enforces it); attr 7 (resolution) reads structural +
  # ancestor resolution (top-down, acyclic along containment); the collection attrs (10/11) read the
  # resolution + collection strata (never structural), so they schedule cleanly beneath both.
  equations =
    {
      policiesRules,
      fleetChildren,
      linkTarget ? (_: null),
      allAspects ? { },
      directIncludes ? [ ],
      quirkDag,
      classOfNode,
      channelNames,
      fleet,
      lin,
      settingsLayers ? [ ],
      dimKinds,
      projectors ? [ ],
    }:
    (structural { inherit policiesRules fleetChildren linkTarget; })
    // (resolvedAspects { inherit allAspects directIncludes; })
    // (collections { inherit quirkDag classOfNode channelNames; })
    // (resolvedSettings.mkEquation {
      inherit
        fleet
        lin
        settingsLayers
        dimKinds
        allAspects
        projectors
        ;
    });

  # The narrow accessor (A10) builder — depends only on the aspect registry + the final eval, not the
  # resolved-settings instance args, so den-hoag applies it once at the top level.
  inherit (resolvedSettings) mkNarrowAccessor;

  # Expose the structural builder for the suite's minimal-scenario scaffolding (b2 builds
  # structural equations over hand-built roots/rules).
  inherit structural;

  runResolve =
    {
      roots,
      equations,
      parseParent,
    }:
    resolve.resolve {
      inherit roots equations parseParent;
      declaredEdges = _: [ ];
    };
}
