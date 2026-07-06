{
  inputs = {
    gen.url = "github:sini/gen";
    den-hoag.url = "path:..";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    inputs@{ gen, den-hoag, ... }:
    let
      denHoag = den-hoag.lib;
      nixpkgsLib = import "${inputs.nixpkgs}/lib";
    in
    gen.lib.mkCi {
      inherit inputs;
      name = "den-hoag";
      testModules = ./tests;
      specialArgs = { inherit denHoag nixpkgsLib; };
    };
}
