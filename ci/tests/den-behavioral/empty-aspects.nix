# den v1 BEHAVIORAL migration — public-api/empty-aspects.nix (denful/den templates/ci/modules/public-api/
# empty-aspects.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertion are BYTE-IDENTICAL to v1. Concern: `aspects-core` (bare-fleet
# `den.aspects` default shape).
{
  denHoag,
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
      denHoag
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };
in
{
  flake.tests.den-aspects-core = {
    test-no-aspects = denTest (
      { den, ... }:
      {
        expr = den.aspects;
        expected = { };
      }
    );
  };
}
