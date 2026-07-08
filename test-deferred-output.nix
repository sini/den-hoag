let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  eval = lib.evalModules {
    modules = [
      { options.den = lib.mkOption { type = lib.types.deferredModule; default = {}; }; }
      { den.schema.user = 1; }
    ];
  };
in
eval.config.den
