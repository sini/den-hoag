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
      # den-compat (L4) shim — the v1-surface-accepting compiler + parity helpers, for the shim-law
      # suites (compat-scaffold, C1–C6). Rides den-hoag's own nix-unit CI (den-hoag = `path:..`).
      denCompat = den-hoag.compat;
      nixpkgsLib = import "${inputs.nixpkgs}/lib";
      denHoagSrc = "${inputs.den-hoag}";
      wrapWiring = wiring: wiring // {
        mkDen = userModules: wiring.mkDen (userModules ++ [ { config._module.args.lib = nixpkgsLib; } ]);
        evalV1 = userModules: wiring.evalV1 (userModules ++ [ { config._module.args.lib = nixpkgsLib; } ]);
      };
      denCompatWrapped = wrapWiring denCompat // {
        mkWiring = legacy: wrapWiring (denCompat.mkWiring legacy);
      };
    in
    gen.lib.mkCi {
      inherit inputs;
      name = "den-hoag";
      testModules = ./tests;
      # `nixpkgs` (the FLAKE — carrying `.lib.nixosSystem`) is threaded through for the end-to-end
      # terminal-crossing test (den-hoag's ONE nixpkgs boundary); every other suite ignores it (`...`).
      specialArgs = {
        inherit
          denHoag
          nixpkgsLib
          denHoagSrc
          ;
        denCompat = denCompatWrapped;
        nixpkgs = inputs.nixpkgs;
      };
    };
}
