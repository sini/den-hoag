let
  aspect = {
    sini = {
      includes = [ ];
    };
    shuo = {
      includes = [ ];
    };
    includes = [ ];
  };
  aspectKeys = builtins.attrNames aspect;
  v1Classes = { };
  v1Quirks = { };
  structuralKeysSet = {
    includes = true;
  };
  v1ClassKeyMap = { };
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
implicitProviderKeys
