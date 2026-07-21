{
  inputs = {
    gen.url = "github:sini/gen";
    den-hoag.url = "path:..";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    # home-manager + nix-darwin: the behavioral-migration scaffold imports
    # `home-manager.nixosModules.home-manager` into every crossed host so a homeManager-classed user's
    # config realizes (`igloo.home-manager.users.<u>` → the `tuxHm`/`pinguHm` helpers), and stages
    # `nix-darwin` for the darwin (`apple`) crossing. Both follow the CI nixpkgs so one nixpkgs spans the
    # crossing.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      gen,
      den-hoag,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      denHoag = den-hoag.lib;
      # The home-manager NixOS module — imported into every crossed host by the migration scaffold's
      # `den.default.nixos.imports`, so `igloo.home-manager.users.<u>` realizes (tuxHm/pinguHm). The
      # nix-darwin flake (carrying `.lib.darwinSystem`) is staged for the darwin (`apple`) crossing.
      homeManagerModule = home-manager.nixosModules.home-manager;
      darwinFlake = nix-darwin;
      # den-compat (L4) shim — the v1-surface-accepting compiler + parity helpers, for the shim-law
      # suites (compat-scaffold, C1–C6). Rides den-hoag's own nix-unit CI (den-hoag = `path:..`).
      denCompat = den-hoag.compat;
      # The den-hoag FLAKE-PARTS BRIDGE (den-hoag's `flakeModule` output = bridge.nix + builtins +
      # batteries) — the REAL consumer path (`imports = [ inputs.den.flakeModule ]`). The behavioral
      # migration scaffold (`ci/tests/_lib/den-compat-test.nix`) drives a fleet through THIS module so it
      # gets the bridge's v1DeepMerge for `den.aspects`/`den.default` (multi-module merge) + the crossed
      # `config.flake.{nixosConfigurations,darwinConfigurations}` output faces — which the mkDen-direct
      # path structurally lacks.
      denHoagFlakeModule = den-hoag.flakeModule;
      nixpkgsLib = import "${inputs.nixpkgs}/lib";
      # Source tree of the den-hoag flake, for the A1 zero-machinery source scan (reads
      # lib/**.nix text). The lib itself is pure/path-free, so the scan needs the store path.
      denHoagSrc = "${inputs.den-hoag}";
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
          denCompat
          denHoagFlakeModule
          homeManagerModule
          darwinFlake
          nixpkgsLib
          denHoagSrc
          ;
        nixpkgs = inputs.nixpkgs;
      };
    };
}
