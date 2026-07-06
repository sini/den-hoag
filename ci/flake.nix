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
      # Source tree of the den-hoag flake, for the A1 zero-machinery source scan (reads
      # lib/**.nix text). The lib itself is pure/path-free, so the scan needs the store path.
      denHoagSrc = "${inputs.den-hoag}";
    in
    gen.lib.mkCi {
      inherit inputs;
      name = "den-hoag";
      testModules = ./tests;
      specialArgs = { inherit denHoag nixpkgsLib denHoagSrc; };
    };
}
