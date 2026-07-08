let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  genMerge = builtins.getFlake "github:sini/gen-merge";

  # 1. Nixpkgs eval
  eval1 = lib.evalModules {
    modules = [
      { options.den = lib.mkOption {
          type = lib.types.submodule {
            freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
            options.schema = lib.mkOption { type = lib.types.deferredModule; default = {}; };
          };
        };
      }
      { den.schema.user = 1; }
    ];
  };

  # 2. gen-merge eval
  eval2 = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den.schema = genMerge.lib.mkOption {
          type = genMerge.lib.types.submodule [
            { freeformType = genMerge.lib.types.lazyAttrsOf genMerge.lib.types.anything; }
          ];
        };
      }
      { den = eval1.config.den; }
    ];
  };
in
eval2.config.den.schema
