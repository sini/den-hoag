let
  p = { host, ... }: [ { a = 1; } ];
  res = builtins.tryEval (builtins.deepSeq (builtins.mapAttrs (_: p: map builtins.attrNames (p { })) { __selfProvideInclude = p; }) true);
in
  res
