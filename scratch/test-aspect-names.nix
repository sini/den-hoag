let
  flake = builtins.getFlake (toString ../../sini/nix-config);
  inputs = flake.inputs // {
    den = {
      compat = compat;
    };
  };
  modules = inputs.import-tree ../../sini/nix-config/modules;
  lib = inputs.nixpkgs-unstable.lib;

  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  fetch = name: builtins.fetchTree lock.nodes.${lock.nodes.root.inputs.${name}}.locked;
  dep = name: (v: if builtins.isFunction v then v { } else v) (import (fetch name));

  prelude = dep "gen-prelude";
  schema = dep "gen-schema";
  edge = dep "gen-edge";
  edgeCore = edge.core or edge;

  denHoag = import ../default.nix {
    inherit prelude schema edge;
  };

  compat = import ../lib/compat {
    inherit
      denHoag
      prelude
      schema
      edge
      edgeCore
      ;
  };

  # Evaluate v1Decls
  v1Decls = compat.evalV1 [
    modules
    {
      _module.args = {
        inherit inputs lib;
        self = flake;
        rootPath = flake.outPath;
      };
    }
  ];

  compiled = compat.compileFull v1Decls;

  built = denHoag.mkDen [
    (compat.mkFleetModule compiled.entities.instances compiled { })
  ];
in
map (name: {
  inherit name;
  key = built.den.aspects.${name}.key;
  hasName = built.den.aspects.${name} ? name;
}) (builtins.attrNames built.den.aspects)
