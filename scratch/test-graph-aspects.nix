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

  resolvedList = built.den.structural.get "host:axon-01" "resolved-aspects";
in
map (a: {
  key = a.key;
  contentName = a.content.name or null;
  contentKey = a.content.key or null;
  contentHasNameOption = a.content ? name;
}) resolvedList
