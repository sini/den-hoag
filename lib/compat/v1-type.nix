{ lib }:
let
  inherit (lib) mkOptionType mapAttrs attrNames foldl' filter concatMap listToAttrs optional all concatLists isList isAttrs isFunction;
  
  mergeV1AnythingVals = vals:
    if vals == [ ] then
      throw "v1Anything: no definitions"
    else if all isList vals then
      concatLists vals
    else if all isAttrs vals then
      let
        keys = attrNames (foldl' (acc: v: acc // v) { } vals);
      in
      listToAttrs (
        map (k: {
          name = k;
          value = mergeV1AnythingVals (concatMap (v: optional (v ? ${k}) v.${k}) vals);
        }) keys
      )
    else
      lib.last vals;
in
mkOptionType {
  name = "v1Anything";
  merge = _loc: defs: mergeV1AnythingVals (map (d: d.value) defs);
}
