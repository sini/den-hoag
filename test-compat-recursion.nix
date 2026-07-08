let
  lib = (builtins.getFlake "github:nixos/nixpkgs/nixos-unstable").lib;
  genMerge = builtins.getFlake "github:sini/gen-merge";
  
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

  eval = lib.evalModules {
    modules = [
      {
        options.den.environments = compatOption (
          genMerge.lib.mkOption {
            type = genMerge.lib.types.lazyAttrsOf (
              genMerge.lib.types.submodule (
                { config, name, ... }:
                {
                  options.name = genMerge.lib.mkOption { default = name; };
                  options.secretPath = genMerge.lib.mkOption { };
                  config.secretPath = lib.mkDefault "/.secrets/env/${config.name}";
                }
              )
            );
          }
        );
      }
      {
        den.environments.prod = { };
      }
    ];
  };
in
eval.config.den.environments.prod.secretPath
