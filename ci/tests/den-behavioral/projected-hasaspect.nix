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
    # BLOCKED (bare-fn-aspect double-type): the named-user `provides.<user>.includes` variant materializes
    # `home-manager.users.tux` correctly (the ref-key throw is gone now that the bridge binds the annotated
    # view). The residual is `den.aspects.aspect2 = { user ? null, ... }: {...}` — a BARE-FUNCTION top-level
    # aspect captured via `provides.tux.includes`. `annotatedViewNav` types it into a
    # `{ __isWrappedFn; __functor; ... }` record; flowed back into `config.den`, the compile-path provides
    # desugar re-applies its functor and re-classifies the result WITHOUT class-key grounding →
    # `§2.2: aspect declares key homeManager`. A raw bare-fn compiled ONCE grounds `homeManager → home-manager`
    # via `wrapGatedFn`; the nav-capture double-pass loses that grounding. Separate rung (BANKED).
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

    # BLOCKED (bare-fn-aspect double-type): same `aspect2` bare-fn double-type as test-content-position above
    # (nav-captured `{ __isWrappedFn; __functor; ... }` re-classified without class-key grounding →
    # `§2.2: declares key homeManager`; BANKED). v1 expected { tux = true; pingu = false; }.
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

    # BLOCKED (bare-fn-aspect double-type): same `aspect2` bare-fn double-type as test-content-position above
    # (nav-captured `{ __isWrappedFn; __functor; ... }` re-classified without class-key grounding →
    # `§2.2: declares key homeManager`; BANKED). v1 expected { igloo = true; iceberg = false; }.
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
