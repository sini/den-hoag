let
  flake = builtins.getFlake (toString ../../sini/nix-config);
in
builtins.attrNames flake.nixosConfigurations.cortex
