# den v1 BEHAVIORAL migration — deadbugs/nested-aspect-merge.nix (denful/den templates/ci/modules/
# deadbugs/nested-aspect-merge.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertion are BYTE-IDENTICAL to v1. Concern: `include` (nested
# aspect keys with multiple definitions should merge — collect all class modules — not last-win overwrite).
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
  flake.tests.den-include = {

    # Two modules defining den.aspects.system.base.nixos should both contribute.
    # Before the fix, only the last definition survived (last-win via //).
    test-multi-def-nested-class-key-regression-nested-aspect-merge = denTest (
      { den, igloo, ... }:
      {
        imports = [
          # Module A
          { den.aspects.igloo.base.nixos.environment.variables.FROM_A = "yes"; }
          # Module B
          { den.aspects.igloo.base.nixos.environment.variables.FROM_B = "yes"; }
        ];

        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ den.aspects.igloo.base ];

        expr = {
          hasA = igloo.environment.variables ? FROM_A;
          hasB = igloo.environment.variables ? FROM_B;
        };
        expected = {
          hasA = true;
          hasB = true;
        };
      }
    );

  };
}
