let
  pkgs = import <nixpkgs> {};
  system = pkgs.lib.nixosSystem {
    modules = [
      { _type = "bind"; foo = "bar"; }
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };
in
  system.config.nixpkgs.hostPlatform
