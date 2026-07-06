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
in
{
  # The full equation map. Structural attributes shape the graph (they never read a resolution
  # attribute — the gen-resolve schedule enforces it); attr 7 reads structural + ancestor
  # resolution (top-down, acyclic along containment).
  equations =
    {
      policiesRules,
      fleetChildren,
      linkTarget ? (_: null),
      allAspects ? { },
      directIncludes ? [ ],
    }:
    (structural { inherit policiesRules fleetChildren linkTarget; })
    // (resolvedAspects { inherit allAspects directIncludes; });

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
