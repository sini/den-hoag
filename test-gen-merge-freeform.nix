let
  genMerge = builtins.getFlake "github:sini/gen-merge";
  eval = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den = genMerge.lib.mkOption {
          type = genMerge.lib.types.submodule [
            { freeformType = genMerge.lib.types.lazyAttrsOf genMerge.lib.types.anything; }
          ];
        };
      }
      { den.schema.user = 1; }
    ];
  };
in
eval.config.den
