let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  genMerge = builtins.getFlake "github:sini/gen-merge";

  # Nixpkgs output
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

  # gen-merge evalV1 equivalent
  eval2 = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den = genMerge.lib.mkOption {
          type = genMerge.lib.types.submodule {
            freeformType = genMerge.lib.types.lazyAttrsOf genMerge.lib.types.anything;
            options.schema = genMerge.lib.mkOption {
              type = genMerge.lib.types.submodule [
                { freeformType = genMerge.lib.types.lazyAttrsOf genMerge.lib.types.anything; }
              ];
            };
          };
        };
      }
      { den = eval1.config.den; }
    ];
  };
in
eval2.config.den.schema
