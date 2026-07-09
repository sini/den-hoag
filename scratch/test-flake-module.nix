let
  denHoag = import ../core {
    prelude = import ../core/prelude { lib = import <nixpkgs/lib>; };
    lib = import <nixpkgs/lib>;
    deliverLib = import ../lib/compat/deliver-lib.nix;
  };
in
denHoag
