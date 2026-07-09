let
  lib = import <nixpkgs/lib>;
  prelude = import ../core/prelude { inherit lib; };
  deliverLib = import ../lib/compat/deliver-lib.nix;
  errors = import ../lib/compat/errors.nix;
  denHoag = import ../core { inherit prelude lib deliverLib; };
  flakeModuleCore = import ../lib/compat/flake-module.nix { inherit denHoag deliverLib prelude errors; };
  v1Decls = {
    aspects.blade = {
      sini = { includes = []; };
      shuo = { includes = []; };
    };
    classes = {};
    quirks = {};
  };
  out = flakeModuleCore.compileFull v1Decls;
in
out.aspects.blade
