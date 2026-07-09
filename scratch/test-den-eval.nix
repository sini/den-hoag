let
  flake = builtins.getFlake (toString ../../sini/nix-config);
  inputs = flake.inputs;
  modules = inputs.import-tree ../../sini/nix-config/modules;

  eval = inputs.flake-parts.lib.evalFlakeModule { inherit inputs; } {
    imports = [ modules ];
  };
in
eval.config
