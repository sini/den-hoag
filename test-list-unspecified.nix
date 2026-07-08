let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  eval = lib.evalModules {
    modules = [
      { options.den.schema.cluster.includes = lib.mkOption { type = lib.types.listOf lib.types.unspecified; }; }
      { den.schema.cluster.includes = [ 1 ]; }
      { den.schema.cluster.includes = [ 2 ]; }
    ];
  };
in
eval.config.den.schema.cluster.includes
