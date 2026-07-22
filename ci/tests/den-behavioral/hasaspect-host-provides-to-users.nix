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

    # BLOCKED: function-valued class facet in a `provides.to-users`-delivered aspect. With the user-cell seed
    # `home-manager.users.tux` now materializes, so this gets PAST the old `attribute 'tux' missing`, but the
    # delivered `den.aspects.effect.homeManager = { host, ... }: {...}` is a bare FUNCTION-valued `homeManager`
    # facet, which compile rejects (§2.2: "aspect-include declares key `homeManager` with a function value —
    # neither a facet, a registered class, nor a quirk channel"). Distinct from the `{ host, user }` ctx
    # family this seed delivers — a separate compile restriction on function-valued class facets (the same one
    # that blocks pipe-broadcast.nix test-broadcast-home-pool-to-host). Re-parked; reported to owner.
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
