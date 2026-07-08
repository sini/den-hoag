let
  gen-merge = builtins.getFlake "github:sini/gen-merge/fa5d5cc2f56d54b6cc117b7a4ffd26f5038db7da";
  res = gen-merge.lib.evalModuleTree {
    modules = [
      {
        options.foo = gen-merge.lib.mkOption { default = ""; };
      }
      ({ lib, ... }: {
        config.foo = lib.optional;
      })
      {
        config._module.args.lib = { optional = true; };
      }
    ];
  };
in res.config.foo
