let
  f = builtins.getFlake "path:///home/sini/Documents/repos/sini/nix-config";
  cortex = f.nixosConfigurations.cortex;
  compat = f.inputs.den.lib.compat;
  compiled = compat.compileFull (compat.evalV1 [ { den = cortex.config.den; } ]);
  defineUser = builtins.head compiled.aspects.__default.includes;
in
  builtins.typeOf (builtins.head defineUser.includes)
