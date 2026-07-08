let
  flake = builtins.getFlake "git+file:///home/sini/Documents/repos/sini/nix-config";
  # We can access `nixosConfigurations.cortex` directly!
  # If it doesn't exist, we can try evaluating flake inputs.
  mkDen = (builtins.getFlake "git+file:///home/sini/Documents/repos/den-hoag").lib.compat.mkDen;
  # Actually, `nix-config` uses `inputs.den.lib.compat.mkDen` internally.
  # If we just want to debug the hoag graph, we need to recreate what `nix-config` does.
in
builtins.attrNames flake.nixosConfigurations
