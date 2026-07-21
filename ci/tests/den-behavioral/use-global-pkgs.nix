# den v1 BEHAVIORAL migration — public-api/use-global-pkgs.nix (denful/den templates/ci/modules/
# public-api/use-global-pkgs.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `schema`
# (den.schema.host.includes / den.schema.hm-host.includes gating on HM-user presence).
{
  denHoagFlakeModule,
  homeManagerModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };
in
{
  flake.tests.den-schema = {

    test-enabled = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        # host entity includes are applied when host has HM support
        den.schema.host.includes = [
          { nixos.home-manager.useGlobalPkgs = true; }
        ];

        expr = igloo.home-manager.useGlobalPkgs;
        expected = true;
      }
    );

    test-disabled = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        expr = igloo.home-manager.useGlobalPkgs;
        expected = false;
      }
    );

    test-not-activated-without-hm-users = denTest (
      { den, config, ... }:
      {
        den.hosts.x86_64-linux.igloo = { };
        den.schema.hm-host.includes = [
          { nixos.home-manager.useGlobalPkgs = true; }
        ];

        expr = config.flake.nixosConfigurations.igloo.config ? home-manager;
        expected = false;
      }
    );

  };
}
