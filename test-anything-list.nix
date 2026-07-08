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
      { den.aspects.core.network.syncthing.peer.includes = [ 1 ]; }
    ];
  };
in
eval.config.den.aspects
