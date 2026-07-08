let
  genMerge = builtins.getFlake "github:sini/gen-merge";
  schema = builtins.getFlake "github:sini/gen-schema";

  compatOption = opt: opt // {
    type = opt.type // {
      check = v: true;
      deprecationMessage = null;
      emptyValue = { value = { }; };
      getSubModules = null;
      getSubOptions = _: { };
      merge = loc: defs: opt.type.merge loc defs;
    };
  };

  eval = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den.schema = schema.lib.mkSchemaOption { };
        config.den.schema = { env = { parent = null; }; };
      }
      {
        options.den.env = compatOption (schema.lib.mkInstanceRegistry eval.config.den.schema.env { });
        config.den.env.prod.imports = [
          ({ config, ... }: {
            options.foo = genMerge.lib.mkOption {};
            config.foo = config.name;
          })
        ];
      }
    ];
  };
in
eval.config.den.env.prod.foo
