let
  genMerge = builtins.getFlake "github:sini/gen-merge";
  schema = builtins.getFlake "github:sini/gen-schema";
  eval = genMerge.lib.evalModuleTree {
    modules = [
      {
        options.den.schema = schema.lib.mkSchemaOption { };
        config.den.schema = { imports = [ { user = { parent = "host"; }; } ]; };
      }
    ];
  };
in
eval.config.den.schema
