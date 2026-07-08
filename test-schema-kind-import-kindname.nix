let
  genMerge = builtins.getFlake "github:sini/gen-merge";
  schema = builtins.getFlake "github:sini/gen-schema";
  eval = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den.schema = schema.lib.mkSchemaOption { };
        config.den.schema = {
          env = {
            parent = null;
            imports = [
              ({ env, ... }: {
                options.foo = genMerge.lib.mkOption {};
                config.foo = env.name;
              })
            ];
          };
        };
      }
      {
        options.den.env = schema.lib.mkInstanceRegistry eval.config.den.schema.env { };
        config.den.env.prod.name = "prod-custom";
      }
    ];
  };
in
eval.config.den.env.prod.foo
