let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  genMerge = builtins.getFlake "github:sini/gen-merge";
  eval = lib.evalModules {
    modules = [
      { options.den = lib.mkOption { type = genMerge.lib.types.lazyAttrsOf genMerge.lib.types.anything; }; }
      { den.aspects.roles.a = 1; }
      { den.aspects.roles.b = 2; }
      { den.schema.cluster.includes = [ 1 ]; }
      { den.schema.cluster.includes = [ 2 ]; }
    ];
  };
in
eval.config.den
