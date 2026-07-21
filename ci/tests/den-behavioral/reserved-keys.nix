# den v1 BEHAVIORAL migration — public-api/reserved-keys.nix (denful/den templates/ci/modules/public-api/
# reserved-keys.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertion are BYTE-IDENTICAL to v1. Concern: `schema` (den.reservedKeys marks
# an extra aspect key as structural metadata, skipped by class/nested/pipe dispatch).
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
    test-reserved-key-is-metadata = denTest (
      { den, igloo, ... }:
      {
        den.reservedKeys = [ "settings" ];
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo = {
          settings = {
            theme = "dark";
          };
          nixos.networking.hostName = "reserved-test";
        };

        expr = {
          resolves = igloo.networking.hostName;
          metadata = den.aspects.igloo.settings;
        };
        expected = {
          resolves = "reserved-test";
          metadata = {
            theme = "dark";
          };
        };
      }
    );
  };
}
