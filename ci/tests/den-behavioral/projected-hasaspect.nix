# den v1 BEHAVIORAL migration — deadbugs/projected-hasaspect.nix (denful/den templates/ci/modules/
# deadbugs/projected-hasaspect.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `hasAspect`
# (in-context `.hasAspect` answers PROJECTED scope membership — what is delivered into the active scope —
# while the registry query stays structural; one symbol, overloaded by provenance).
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
    # BLOCKED-WSB (missing surface): `den.aspects.igloo.provides.tux.includes` — the NAMED-user variant of
    # provides cross-delivery (distinct from the `provides.to-users` broadcast form parked in
    # hasaspect-host-provides-to-users.nix, same family) — never materializes `home-manager.users.tux`.
    # Forcing `igloo.home-manager.users.tux` throws `attribute 'tux' missing`.
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

    # BLOCKED-WSB (missing surface, second gap in the same test): forcing
    # `den.hosts.x86_64-linux.igloo.users.tux.hasAspect` throws `attribute 'hasAspect' missing` — the
    # REGISTRY-side structural `.hasAspect` accessor is not exposed on a raw `den.hosts.<sys>.<host>.
    # users.<user>` node (distinct from the in-context `.hasAspect` this file's concern is about).
    # test-provenance-split-regression-projected-hasaspect = denTest (
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
    #     expr = {
    #       registry = den.hosts.x86_64-linux.igloo.users.tux.hasAspect den.aspects.aspect1;
    #       inContext = igloo.home-manager.users.tux.programs.atuin.daemon.enable;
    #     };
    #     expected = {
    #       registry = false;
    #       inContext = true;
    #     };
    #   }
    # );

    # PARKED-DIVERGENCE (same provides.tux root cause as test-content-position above, but the `or false`
    # idiom here catches the missing attribute instead of throwing — clean eval, wrong value): v1 expected
    # { tux = true; pingu = false; }; den-hoag actual { tux = false; pingu = false; }.
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

    # PARKED-DIVERGENCE (same provides.tux root cause as test-content-position above, `or false` catches
    # it here too): v1 expected { igloo = true; iceberg = false; }; den-hoag actual
    # { igloo = false; iceberg = false; }.
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
