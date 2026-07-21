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
          nixpkgsLib
          denHoagSrc
          ;
        nixpkgs = inputs.nixpkgs;
      };
    };
}
