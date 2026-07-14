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
      resolve
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
      fleet,
      lin,
      settingsLayers ? [ ],
      dimKinds,
      projectors ? [ ],
      # The staged pre-pass's containment relations (nodeId -> [ ancestor slice ]) — the settings-chain
      # env slice (§3c-UNIFIED). Default `{ }` ⇒ no env slice (byte-identical to the pre-§3c chain).
      containmentRelations ? { },
      classNames,
      classifyKey,
      # Shared-vs-own provenance (Track A rung 1): the resolved-aspect keys that root a radiated-shared
      # (`den.default`) subtree, passed to resolved-aspects which stamps each node's `__denShared` flag
      # (class-modules reads it for the `__shared` sidecar). Default `[ ]` ⇒ no aspect marked shared.
      sharedAspectKeys ? [ ],
      # Framework default-edge injector (spec §2 baseline, Task 3): `id -> [ { target; classFilter ? null } ]`,
      # threaded to resolved-aspects' `reach`. Native default `(_: [ ])` ⇒ no default edges ⇒ reach unchanged.
      defaultEdgeTargets ? (_: [ ]),
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
            sharedAspectKeys
            defaultEdgeTargets
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
    // (resolvedSettings.mkEquation {
      inherit
        fleet
        lin
        settingsLayers
        dimKinds
        allAspects
        projectors
        containmentRelations
        ;
    });

  # The narrow accessor (A10) builder — depends only on the aspect registry + the final eval, not the
  # resolved-settings instance args, so den-hoag applies it once at the top level.
  inherit (resolvedSettings) mkNarrowAccessor;

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
    }:
    let
      cm = classModules { inherit classNames classifyKey; };
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
    }:
    resolve.resolve {
      inherit roots equations parseParent;
      declaredEdges = _: [ ];
    };
}
