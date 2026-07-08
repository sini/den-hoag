let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  eval = lib.evalModules {
    modules = [
      { options.includes = lib.mkOption { type = lib.types.listOf lib.types.anything; }; }
      { includes = [ ({ name, ... }: name) ]; }
    ];
  };
in
(builtins.elemAt eval.config.includes 0) { name = "foo"; }
