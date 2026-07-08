let
  f = builtins.getFlake "path:///home/sini/Documents/repos/sini/nix-config";
in
  builtins.attrNames (f.flake-parts-config or f.config).den.classes
