let
  f = { host, ... }: host;
  res = builtins.tryEval (f { });
in
  res
