let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  eval = lib.evalModules {
    modules = [
      { options.den = lib.mkOption {
          type = lib.types.submodule {
            freeformType = lib.types.lazyAttrsOf lib.types.anything;
          };
        };
      }
      { den.aspects.core.network.syncthing.peer = { a = 1; }; }
      { den.aspects.core.network.syncthing.hub = { b = 2; }; }
    ];
  };
in
eval.config.den.aspects
