let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  genMerge = builtins.getFlake "github:sini/gen-merge";
  # 1. Nixpkgs eval with deferredModule
  eval1 = lib.evalModules {
    modules = [
      { options.den = lib.mkOption { type = lib.types.deferredModule; default = {}; }; }
      { den.aspects.roles.a = 1; }
      { den.aspects.roles.b = 2; }
    ];
  };
  capturedDen = eval1.config.den;

  # 2. gen-merge eval with the captured module
  eval2 = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den = genMerge.lib.mkOption {
          type = genMerge.lib.types.submodule {
            modules = [ { freeformType = genMerge.lib.types.lazyAttrsOf genMerge.lib.anything; } ];
          };
        };
      }
      { den = capturedDen; }
    ];
  };
in
eval2.config.den
