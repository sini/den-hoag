{ prelude, ... }:
{
  desugar =
    v1:
    let
      v1Classes = v1.classes or { };
      nixosClass = v1Classes.nixos or { };
      darwinClass = v1Classes.darwin or { };
      homeManagerClass = v1Classes.homeManager or { };
    in
    v1
    // {
      classes = v1Classes // {
        nixos = { forwardTo = "nixos"; } // nixosClass;
        darwin = { forwardTo = "darwin"; } // darwinClass;
        homeManager = { forwardTo = "homeManager"; } // homeManagerClass;
      };
    };
}
