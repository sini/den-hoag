let
  f = builtins.getFlake "path:///home/sini/Documents/repos/sini/nix-config";
  cortex = f.nixosConfigurations.cortex;
  compat = f.inputs.den.lib.compat;
  compiled = compat.compileFull (compat.evalV1 [ { den = cortex.config.den; } ]);
in
  builtins.attrNames compiled.classes
