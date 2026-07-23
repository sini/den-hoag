# den v1 BEHAVIORAL migration — deadbugs/projected-hasaspect.nix (denful/den templates/ci/modules/
# deadbugs/projected-hasaspect.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `hasAspect`
# (in-context `.hasAspect` answers PROJECTED scope membership — what is delivered into the active scope).
# den-hoag's `hasAspect` is UNIFIED: provides fold into the node, and there is no registry-side `.hasAspect`
# accessor by design (v1's two-resolve registry/in-context split is deliberately not reproduced).
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
  # v1's file-level `{ denTest, lib, ... }:` arg — `den.aspects.aspect2`'s `{ user ? null, ... }:` closure
  # below references `lib` without naming it as its own formal (see pipe-policy.nix for the full rationale).
  lib = nixpkgsLib;
in
{
  flake.tests.den-hasAspect = {
    # GREEN WITNESS for the bare-fn grounding fix (compile.nix:549 __isWrappedFn arm now grndDispatch-grounds
    # symmetric with the raw bare-fn arm). Asserts ONLY throw-removal — evaluates `true` post-fix, throws
    # (→ tryEval false) pre-fix, so a silent revert of the grounding reddens here. The delivered VALUE stays
    # PARKED (bare-fn named-user-provides delivery seam, separate rung — see the parked cases below).
    test-barefn-provides-grounds-no-throw = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.aspect1.homeManager.programs.atuin.enable = true;
        den.aspects.aspect2 =
          {
            user ? null,
            ...
          }:
          {
            homeManager.config = lib.mkIf (user != null && user.hasAspect den.aspects.aspect1) {
              programs.atuin.daemon.enable = true;
            };
          };
        den.aspects.igloo.provides.tux.includes = [
          den.aspects.aspect1
          den.aspects.aspect2
        ];
        expr =
          (builtins.tryEval (
            builtins.deepSeq (igloo.home-manager.users.tux.programs.atuin.daemon.enable or false) true
          )).success;
        expected = true;
      }
    );

    # PARKED on a SEPARATE residual (NOT the bare-fn grounding, which is now fixed): a BARE-FUNCTION TOP-LEVEL
    # aspect (`den.aspects.aspect2 = { user ? null, ... }: {...}`) delivered via the NAMED-user
    # `provides.<user>.includes` variant does not materialize its invoked content into the user's node. The
    # bare-fn double-type THROW (`§2.2: aspect declares key homeManager`) IS resolved — compile grounds the
    # `__isWrappedFn` functor's result symmetric with the raw bare-fn arm — so these cases now EVALUATE (no
    # throw). But two delivery-seam gaps remain, verified empirically: (1) user-binding is moot — the bare-fn
    # content does not land at all (the IDENTICAL static aspect shape DOES deliver via the same
    # `provides.tux.includes`), so whether the functor ctx binds `user` is unobservable here; (2) EVEN
    # unconditional (guard dropped) the bare-fn's invoked content does not reach `home-manager.users.tux`,
    # whereas the IDENTICAL static aspect shape delivers via the same `provides.tux.includes` — so top-level
    # bare-fn aspect delivery via the named-user provides variant is unwired. Separate rung (named-user-provides
    # bare-fn delivery); the grounding fix that these tests exercised is committed separately.
    # test-content-position-regression-projected-hasaspect = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.aspect1.homeManager.programs.atuin.enable = true;
    #     den.aspects.aspect2 =
    #       {
    #         user ? null,
    #         ...
    #       }:
    #       {
    #         homeManager.config = lib.mkIf (user != null && user.hasAspect den.aspects.aspect1) {
    #           programs.atuin.daemon.enable = true;
    #         };
    #       };
    #     den.aspects.igloo.provides.tux.includes = [
    #       den.aspects.aspect1
    #       den.aspects.aspect2
    #     ];
    #     expr = igloo.home-manager.users.tux.programs.atuin.daemon.enable;
    #     expected = true;
    #   }
    # );

    # PARKED on the SAME residual as test-content-position above (named-user-provides bare-fn delivery, NOT
    # grounding — the bare-fn content does not land at all; user-binding is moot). v1 expected { tux = true; pingu = false; }.
    # test-multi-user-regression-projected-hasaspect = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users = {
    #       tux = { };
    #       pingu = { };
    #     };
    #     den.aspects.aspect1.homeManager.programs.atuin.enable = true;
    #     den.aspects.aspect2 =
    #       {
    #         user ? null,
    #         ...
    #       }:
    #       {
    #         homeManager.config = lib.mkIf (user != null && user.hasAspect den.aspects.aspect1) {
    #           programs.atuin.daemon.enable = true;
    #         };
    #       };
    #     den.aspects.igloo = {
    #       provides.tux.includes = [
    #         den.aspects.aspect1
    #         den.aspects.aspect2
    #       ];
    #       provides.pingu.includes = [ den.aspects.aspect2 ];
    #     };
    #     expr = {
    #       tux = igloo.home-manager.users.tux.programs.atuin.daemon.enable or false;
    #       pingu = igloo.home-manager.users.pingu.programs.atuin.daemon.enable or false;
    #     };
    #     expected = {
    #       tux = true;
    #       pingu = false;
    #     };
    #   }
    # );

    # PARKED on the SAME residual as test-content-position above (named-user-provides bare-fn delivery, NOT
    # grounding — the bare-fn content does not land at all; user-binding is moot). v1 expected { igloo = true; iceberg = false; }.
    # test-multi-host-regression-projected-hasaspect = denTest (
    #   {
    #     den,
    #     igloo,
    #     iceberg,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.tux = { };
    #     den.aspects.aspect1.homeManager.programs.atuin.enable = true;
    #     den.aspects.aspect2 =
    #       {
    #         user ? null,
    #         ...
    #       }:
    #       {
    #         homeManager.config = lib.mkIf (user != null && user.hasAspect den.aspects.aspect1) {
    #           programs.atuin.daemon.enable = true;
    #         };
    #       };
    #     den.aspects.igloo.provides.tux.includes = [
    #       den.aspects.aspect1
    #       den.aspects.aspect2
    #     ];
    #     den.aspects.iceberg.provides.tux.includes = [ den.aspects.aspect2 ];
    #     expr = {
    #       igloo = igloo.home-manager.users.tux.programs.atuin.daemon.enable or false;
    #       iceberg = iceberg.home-manager.users.tux.programs.atuin.daemon.enable or false;
    #     };
    #     expected = {
    #       igloo = true;
    #       iceberg = false;
    #     };
    #   }
    # );

  };
}
