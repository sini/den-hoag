# den v1 BEHAVIORAL migration — the MULTI-FILE `den.aspects` MERGE regressions (denful/den
# templates/ci/modules/deadbugs/{nested-aspect-merge,deep-nested-multi-file-merge}.nix). Migrated by copy +
# arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + assertions are
# BYTE-IDENTICAL to v1.
#
# THE HARNESS-FIX PROOF (why these live here): each spreads the SAME `den.aspects.<path>` across multiple
# `imports` modules. On the mkDen-direct scaffold path this CONFLICTED — the shim's internal v1-options eval
# declares `den.aspects` as `raw` (single-def), so multi-module contributions collided and the fleet lost
# the host. On the FLAKE-PARTS BRIDGE path the bridge's `options.den` submodule folds them with v1's OWN
# deep-merge (`v1DeepMerge`: colliding attrsets recurse), so every module's contribution survives — exactly
# the v1 `aspectsType` semantics these deadbugs pin. All-ATTRSET merges (no fn-vs-attrset collision), so they
# also exercise the scaffold's intersectAttrs partial-matching on the attrset `expr`/`expected`.
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

    # deadbugs/nested-aspect-merge.nix — two modules defining den.aspects.igloo.base.nixos both contribute
    # (last-win via `//` was the bug; v1DeepMerge recurses).
    test-multi-def-nested-class-key = denTest (
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

    # deadbugs/deep-nested-multi-file-merge.nix — three files each contribute a DIFFERENT child of a shared
    # deeply-nested namespace node (collision one level up at `grp`); all three must survive.
    test-multi-file-colliding-namespace-merge = denTest (
      { den, igloo, ... }:
      {
        imports = [
          { den.aspects.root.sub1.sub2.grp.a.nixos.environment.variables.FROM_A = "yes"; }
          { den.aspects.root.sub1.sub2.grp.b.nixos.environment.variables.FROM_B = "yes"; }
        ];

        den.aspects.root.sub1.sub2.grp.c.nixos.environment.variables.FROM_C = "yes";

        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [
          den.aspects.root.sub1.sub2.grp.a
          den.aspects.root.sub1.sub2.grp.b
          den.aspects.root.sub1.sub2.grp.c
        ];

        expr = {
          hasA = igloo.environment.variables ? FROM_A;
          hasB = igloo.environment.variables ? FROM_B;
          hasC = igloo.environment.variables ? FROM_C;
        };
        expected = {
          hasA = true;
          hasB = true;
          hasC = true;
        };
      }
    );

  };
}
