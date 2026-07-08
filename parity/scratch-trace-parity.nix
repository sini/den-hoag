let
  f = builtins.getFlake "path:///home/sini/Documents/repos/den-hoag/parity";
  harness = import /home/sini/Documents/repos/den-hoag/parity/flake.nix;
in
  { }
