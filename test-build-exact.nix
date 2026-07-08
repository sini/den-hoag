let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  genMerge = builtins.getFlake "github:sini/gen-merge";
  schema = builtins.getFlake "github:sini/gen-schema";

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
      { den.schema.user.parent = "host"; }
    ];
  };

  # build eval
  tree = genMerge.lib.evalModuleTree {
    modules = [
      { options.den.schema = schema.lib.mkSchemaOption { }; }
      { den = eval1.config.den; }
    ];
  };
in
tree.config.den.schema.user
