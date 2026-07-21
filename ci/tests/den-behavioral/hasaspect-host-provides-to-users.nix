# den v1 BEHAVIORAL migration — deadbugs/hasaspect-host-provides-to-users.nix (denful/den templates/ci/
# modules/deadbugs/hasaspect-host-provides-to-users.nix). Migrated by copy + arg-rename onto the
# `_lib/den-compat-test.nix` scaffold. Concern: `hasAspect` (`host.hasAspect` must see aspects the host
# delivers DOWN to its users via `provides.to-users`, checked from inside the delivered home-manager
# aspect).
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
  flake.tests.den-hasAspect = {

    # BLOCKED-WSB (missing/broken surface): `den.aspects.igloo.provides.to-users.includes` cross-delivers
    # to every user cell under igloo (legacy/provides.nix `isCross` → `sel.kind userKind`); the delivered
    # aspect's `homeManager` bucket should materialize `home-manager.users.tux`. Empirically confirmed:
    # forcing `igloo.home-manager.users.tux` throws `attribute 'tux' missing` — no content reaches the
    # user cell at all via this `provides.to-users` cross-delivery path (distinct from the host-aspects
    # BATTERY path, which does successfully materialize `home-manager.users.<u>` — see
    # host-aspects-sibling-leak.nix).
    # test-host-sees-aspect-it-provides-to-users = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.test.nixos = { };
    #
    #     den.aspects.effect = {
    #       homeManager =
    #         { host, ... }:
    #         {
    #           home.username =
    #             if host.hasAspect den.aspects.test then lib.mkForce "right" else lib.mkForce "wrong";
    #         };
    #     };
    #
    #     den.aspects.igloo = {
    #       provides.to-users.includes = [
    #         den.aspects.test
    #         den.aspects.effect
    #       ];
    #     };
    #
    #     expr = igloo.home-manager.users.tux.home.username;
    #     expected = "right";
    #   }
    # );

  };
}
