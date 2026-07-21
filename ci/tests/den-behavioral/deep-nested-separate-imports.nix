# den v1 BEHAVIORAL migration — deadbugs/deep-nested-separate-imports.nix (denful/den templates/ci/modules/
# deadbugs/deep-nested-separate-imports.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertion are BYTE-IDENTICAL to v1. Concern: `multi-file-merge`
# (a nested `den.aspects` path split across a module `imports` entry and a plain top-level def — a shallow
# `//` would clobber one side; v1's `aspectContentType` deep-merge keeps both).
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
  flake.tests.den-multi-file-merge = {
    test-deep-nested-separate-imports = denTest (
      { den, igloo, ... }:
      {
        imports = [
          { den.aspects.root.sub1.sub2.a.nixos.environment.variables.FROM_A = "yes"; }
        ];

        den.aspects.root.sub1.sub2.b.nixos.environment.variables.FROM_B = "yes";

        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [
          den.aspects.root.sub1.sub2.a
          den.aspects.root.sub1.sub2.b
        ];

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
