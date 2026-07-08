let
  flake = builtins.getFlake "path://${toString ./.}";
  internal = flake.lib.internal;
in
  builtins.attrNames internal.bind
