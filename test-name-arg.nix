let
  genMerge = builtins.getFlake "github:sini/gen-merge";
  eval = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.foo = genMerge.lib.mkOption {
          type = genMerge.lib.types.lazyAttrsOf (genMerge.lib.types.submodule (
            { name, ... }: {
              options.bar = genMerge.lib.mkOption {};
              config.bar = name;
            }
          ));
        };
      }
      { foo.prod = {}; }
    ];
  };
in
eval.config.foo.prod.bar
