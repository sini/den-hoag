let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  eval = lib.evalModules {
    modules = [
      { options.foo = lib.mkOption { type = lib.types.anything; }; }
      { foo = { host, ... }: host; }
    ];
  };
in
eval.config.foo { host = "bar"; }
