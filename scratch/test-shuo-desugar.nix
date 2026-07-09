let
  lib = import <nixpkgs/lib>;
  # Load the entire nix-config user modules
  flake = import ../../sini/nix-config/flake.nix;
  # We can't evaluate the whole flake easily, let's just evaluate evalV1
  flakeModule = import ../lib/compat/flake-module.nix {
    denHoag = { };
    prelude = import ../lib/prelude/default.nix { inherit lib; };
    schema = import ../lib/schema/default.nix {
      prelude = import ../lib/prelude/default.nix { inherit lib; };
      errors = import ../lib/errors.nix;
    };
    compile = { };
    legacy = {
      provides = import ../lib/compat/legacy/provides.nix {
        denHoag = { };
        prelude = import ../lib/prelude/default.nix { inherit lib; };
        errors = import ../lib/compat/errors.nix;
      };
    };
    deliverLib = { };
  };
  v1Decls = {
    aspects.blade = {
      sini = {
        includes = [ ];
      };
      shuo = {
        includes = [ ];
      };
    };
    classes = { };
    quirks = { };
  };
  out = flakeModule.desugarLegacy v1Decls;
in
out.aspects.blade
