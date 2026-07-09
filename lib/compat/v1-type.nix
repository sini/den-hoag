{ lib, aspectNames ? [ ] }:
let
  inherit (lib) mkOptionType mapAttrs attrNames foldl' filter concatMap listToAttrs optional all concatLists isList isAttrs isFunction drop;
  
  mergeV1AnythingVals = loc: vals:
    if vals == [ ] then
      throw "v1Anything: no definitions"
    else if all isList vals then
      concatLists vals
    else if all isAttrs vals then
      let
        keys = attrNames (foldl' (acc: v: acc // v) { } vals);
        merged = listToAttrs (
          map (k: {
            name = k;
            value = mergeV1AnythingVals (loc ++ [ k ]) (concatMap (v: optional (v ? ${k}) v.${k}) vals);
          }) keys
        );
        # Inject _aspectPath if we are under den.aspects and the path matches an aspect name
        hasAspectPath = (builtins.length loc >= 2) && (builtins.elemAt loc 0 == "den") && (builtins.elemAt loc 1 == "aspects");
        aspectPath = builtins.concatStringsSep "." (drop 2 loc);
        isAspect = hasAspectPath && builtins.elem aspectPath aspectNames;
      in
      if isAspect then
        merged // { _aspectPath = aspectPath; }
      else
        merged
    else
      lib.last vals;
in
mkOptionType {
  name = "v1Anything";
  merge = loc: defs: mergeV1AnythingVals loc (map (d: d.value) defs);
}
