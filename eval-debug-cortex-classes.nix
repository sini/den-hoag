let
  f = builtins.getFlake "path:///home/sini/Documents/repos/sini/nix-config";
  cortex = f.nixosConfigurations.cortex;
in
  builtins.attrNames cortex.config.den.classes
