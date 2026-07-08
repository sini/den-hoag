let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  eval = lib.evalModules {
    modules = [
      { options.den = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; }; }
      { den.aspects.roles.a = 1; }
      { den.aspects.roles.b = 2; }
    ];
  };
in
eval.config.den
