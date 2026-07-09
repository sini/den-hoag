let
  denCompat = import ../lib/compat {
    denHoag = import ../core;
    deliverLib = import ../lib/compat/deliver-lib.nix;
  };
  v1Decls = {
    aspects.blade = {
      sini = { includes = []; };
      shuo = { includes = []; };
    };
    classes = {};
    quirks = {};
  };
  out = denCompat.legacy.provides.desugar v1Decls;
in
out
