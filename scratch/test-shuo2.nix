let
  prelude = import ../core/prelude { lib = import <nixpkgs/lib>; };
  desugar = import ../lib/compat/legacy/provides.nix { inherit prelude; };
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
in
desugar.desugar v1Decls
