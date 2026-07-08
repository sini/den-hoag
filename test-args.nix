let
  f = { host, ... }: host;
  args = builtins.functionArgs f;
  probeCtx = builtins.listToAttrs (map (k: { name = k; value = "probe"; }) (builtins.attrNames args));
in
  f probeCtx
