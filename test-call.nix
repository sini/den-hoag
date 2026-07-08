let
  __selfProvideInclude = { host, ... }: if host != null then host.name else "none";
  probeCtx = { host = { name = "probe"; }; };
in
  __selfProvideInclude probeCtx
