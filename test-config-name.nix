let
  genMerge = builtins.getFlake "github:sini/gen-merge";
  schema = builtins.getFlake "github:sini/gen-schema";
  eval = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den.schema = schema.lib.mkSchemaOption { };
        config.den.schema = { env = { parent = null; }; };
      }
      (
        { config, ... }:
        {
          options.den.env = schema.lib.mkInstanceRegistry config.den.schema.env { };
          config.den.env.prod = { };
        }
      )
    ];
  };
in
eval.config.den.env.prod.name
