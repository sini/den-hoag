# The closed-gated aspect TREE type — the ONE source for the cnf both the compile view (`typedCompileTree`,
# flake-module.nix) and the parametric-result gate (`gateAspect`, compile.nix) type through. gen-aspects builds
# each declared aspect key's option from `cnf.keySemantics` (class → deferredModule bucket, channel → raw
# passthrough, facet → the entry's option/module); the three gate flags close the freeform fold so an
# undeclared non-attrset leaf throws NAMED at the type (the totality boundary, Model C — Néron/Tolmach/Visser/
# Wachsmuth 2015, a name resolving to no declaration in scope is a type error at that scope) while an
# auto-vivified namespace node recurses gate-retained.
#
# Parameterised by the fleet's declared class + quirk names ONLY — the CALLER supplies the spelling it types
# against (the compile view keys class channels by the v1 SURFACE spelling `homeManager`; the parametric gate
# keys them by the GROUNDED kebab `home-manager` translateAspect produced), so the one cnf shape (facet
# vocabulary + the three flags) serves both without duplicating either.
{
  aspects,
  merge,
  prelude,
}:
let
  # The SHARED class + channel + facet keySemantics builder den-hoag core also uses (one vocabulary source).
  keySemanticsLib = import ../key-semantics.nix { inherit prelude; };
  # The shared base cnf — the module-arg surface the typed aspect bodies bind + empty meta/collections. The
  # same moduleArgs set the nav/compile view uses, so gen-aspects tells a class-content module fn from a
  # parametric guard fn.
  aspectsViewCnf = {
    moduleArgs = {
      settings = true;
      aspects = true;
      lib = true;
      config = true;
      options = true;
      pkgs = true;
    };
    metaModules = [ ];
    collections = { };
  };
  mkCnf =
    {
      classNames,
      quirkChannels,
    }:
    aspectsViewCnf
    // {
      keySemantics =
        (keySemanticsLib.mkClassChannelSemantics {
          inherit classNames quirkChannels;
        })
        # Register the config-free facet vocabulary (neededBy/settings/artifact/excludes/tags/projects) from the
        # SAME source the aspects concern declares — so a `.settings` block types as the kernel's `lazyAttrsOf
        # raw` facet and `excludes`/`tags`/`projects` are recognized OPTIONS (the closed gate admits them
        # without a static list), not freeform nested-aspect submodules.
        // (keySemanticsLib.mkFacetSemantics { inherit merge; });
      # A raw guard closure / `{ __fn; … }` battery record / policy record in an aspect's `includes` passes
      # THROUGH the type opaquely (compile's `normalize` does the registry-aware wrap downstream).
      deferIncludeResolution = true;
      # Close the freeform fold: an auto-vivified namespace node recurses (gate retained), a non-attrset
      # undeclared leaf throws NAMED — the typed pass is the totality boundary.
      closedKeys = true;
      recursiveClosed = true;
    };
in
{
  # The closed-gated aspect TREE type (a map of aspects), built for the given fleet vocabulary.
  mkClosedAspectsType = cnf: aspects.aspectsType (mkCnf cnf);
  # `mkKeyCategory { classNames; quirkChannels } → key: category` — the single classification surface closed
  # over THIS fleet's cnf (gen-aspects `keyCategory`): a native structural option → "structural"; a declared
  # class/channel/facet → that category; an unregistered key (a typo or a freeform nested-aspect child) → null.
  # The gate uses it to force ONLY the undeclared keys (where a typo lives), never a declared key's content
  # (which may carry a module fixpoint).
  mkKeyCategory = cnf: aspects.keyCategory (mkCnf cnf);
}
