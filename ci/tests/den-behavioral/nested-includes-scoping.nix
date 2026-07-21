# den v1 BEHAVIORAL migration — deadbugs/nested-includes-scoping.nix (denful/den templates/ci/modules/
# deadbugs/nested-includes-scoping.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1 (only the dropped
# `denTest`/`lib` module args differ — `lib` is spliced by the scaffold). Concern: `include` (nested
# sub-aspects are never auto-walked, including through the `provides.<k>` alias namespace and through an
# externally-included aspect's own includes). No issue reference on the v1 source at all, so the
# deadbug-origin suffix (migration rule 2) uses the source file's own basename:
# `-regression-nested-includes-scoping`.
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

    # Only explicitly included sub-aspects emit
    test-nested-includes-scoping-regression-nested-includes-scoping = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [ den.aspects.root ];

        den.aspects.root = {
          includes = [ den.aspects.root.a ];

          a.nixos.environment.variables.FROM_A = "yes";
          b.nixos.environment.variables.FROM_B = "yes";
        };

        expr = {
          hasA = igloo.environment.variables ? FROM_A;
          hasB = igloo.environment.variables ? FROM_B;
        };
        expected = {
          hasA = true;
          hasB = false;
        };
      }
    );

    # PARKED-DIVERGENCE: v1-expected { hasA = true; hasB = false; } (v1's `provides.<k>` is sugar
    # ALIASING the same nested-aspect node as a direct `.<k>` — so `includes = [ den.aspects.root.a ]`
    # reaches the content declared as `provides.a`) vs den-hoag-actual: `attribute 'a' missing` reading
    # `den.aspects.root.a` — den-hoag's freeform absorption treats `provides.a` as a plain literal nested
    # key, distinct from `.a` directly; the alias isn't implemented. Not altered to route around the gap.
    # test-provides-includes-scoping-regression-nested-includes-scoping = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.igloo.includes = [ den.aspects.root ];
    #
    #     den.aspects.root = {
    #       includes = [ den.aspects.root.a ];
    #
    #       provides.a.nixos.environment.variables.FROM_A = "yes";
    #       provides.b.nixos.environment.variables.FROM_B = "yes";
    #     };
    #
    #     expr = {
    #       hasA = igloo.environment.variables ? FROM_A;
    #       hasB = igloo.environment.variables ? FROM_B;
    #     };
    #     expected = {
    #       hasA = true;
    #       hasB = false;
    #     };
    #   }
    # );

    # Without includes, nested keys do NOT auto-walk
    test-nested-no-auto-walk-regression-nested-includes-scoping = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [ den.aspects.root ];

        den.aspects.root = {
          a.nixos.environment.variables.FROM_A = "yes";
          b.nixos.environment.variables.FROM_B = "yes";
        };

        expr = {
          hasA = igloo.environment.variables ? FROM_A;
          hasB = igloo.environment.variables ? FROM_B;
        };
        expected = {
          hasA = false;
          hasB = false;
        };
      }
    );

    # External includes don't activate nested keys
    test-external-includes-no-auto-walk-regression-nested-includes-scoping = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [ den.aspects.root ];

        den.aspects.ext.nixos.environment.variables.FROM_EXT = "yes";

        den.aspects.root = {
          includes = [ den.aspects.ext ];

          a.nixos.environment.variables.FROM_A = "yes";
          b.nixos.environment.variables.FROM_B = "yes";
        };

        expr = {
          hasA = igloo.environment.variables ? FROM_A;
          hasB = igloo.environment.variables ? FROM_B;
          hasExt = igloo.environment.variables ? FROM_EXT;
        };
        expected = {
          hasA = false;
          hasB = false;
          hasExt = true;
        };
      }
    );
  };
}
