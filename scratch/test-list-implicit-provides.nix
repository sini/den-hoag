let
  res = import ./test-compiled.nix;
  v1Classes = res.v1Decls.classes or { };
  v1Quirks = res.v1Decls.quirks or { };

  structuralKeysSet = {
    settings = true;
    includes = true;
    neededBy = true;
    meta = true;
    tags = true;
    projects = true;
    name = true;
    description = true;
    id_hash = true;
  };
  v1ClassKeyMap = {
    homeManager = "home-manager";
  };

  hasImplicitProvides =
    aName: aspect:
    if !builtins.isAttrs aspect then
      null
    else
      let
        aspectKeys = builtins.attrNames aspect;
        implicitProviderKeys = builtins.filter (
          k:
          builtins.isAttrs aspect.${k}
          && !(v1Classes ? ${k})
          && !(v1Quirks ? ${k})
          && !(structuralKeysSet ? ${k})
          && !(builtins.elem k (builtins.attrValues v1ClassKeyMap))
          && !(builtins.substring 0 2 k == "__")
        ) aspectKeys;
      in
      if implicitProviderKeys != [ ] then { inherit aName implicitProviderKeys; } else null;
in
builtins.filter (x: x != null) (
  map (name: hasImplicitProvides name res.v1Decls.aspects.${name}) (
    builtins.attrNames res.v1Decls.aspects
  )
)
