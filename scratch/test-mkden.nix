let
  denCompat = import ../lib/compat {
    denHoag = import ../core;
    deliverLib = import ../lib/compat/deliver-lib.nix;
  };
  eval = denCompat.mkDen [ {
    config.den.aspects.blade = {
      sini = { includes = []; };
      shuo = { includes = []; };
    };
  } ];
in
eval.den.nixosConfigurations
