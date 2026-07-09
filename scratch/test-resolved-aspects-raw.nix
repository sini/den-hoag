let
  compiled = import ./test-compiled.nix;
  
  denHoag = import ../default.nix {
    inherit (compiled) prelude schema edge;
  };
  
  compat = import ../lib/compat {
    inherit denHoag;
    inherit (compiled) prelude schema edge;
    edgeCore = compiled.edgeCore or compiled.edge;
  };
  
  built = denHoag.mkDen [
    (compat.mkFleetModule compiled.entities.instances compiled { })
  ];
in
builtins.attrNames built.den
