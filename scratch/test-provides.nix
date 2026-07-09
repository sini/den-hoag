let
  lib = import <nixpkgs/lib>;
  prelude = import ../../sini/nix-config/flake.nix;
in
builtins.trace "hello" "world"
