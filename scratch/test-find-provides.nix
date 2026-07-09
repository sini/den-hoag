let
  res = import ./test-compiled.nix;

  findProvides =
    path: val:
    if !builtins.isAttrs val then
      [ ]
    else
      (
        if val ? provides then
          [
            {
              inherit path;
              providesKeys = builtins.attrNames val.provides;
            }
          ]
        else
          [ ]
      )
      ++ builtins.concatMap (k: findProvides (if path == "" then k else "${path}.${k}") val.${k}) (
        builtins.attrNames val
      );
in
findProvides "" res.v1Decls.aspects
