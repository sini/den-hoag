let
  flake = builtins.getFlake (toString ../../sini/nix-config);
in
builtins.typeOf flake.nixosConfigurations.cortex.config.den.hosts.cortex.instantiate
