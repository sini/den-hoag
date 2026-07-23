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

    # A function-valued `homeManager` facet delivered via `provides.to-users` compiles cleanly — the delivered
    # `den.aspects.effect.homeManager = { host, ... }: {...}` fn-facet rides raw, grounded/wrapped by compile
    # (the plain-facet variant greens in provides-to-users-fn-facet.nix). The facet body reads
    # `host.hasAspect den.aspects.test`: the bridge now binds the annotated NAVIGATION view
    # (`compat.annotatedViewNav`, bridge.nix:532) rather than the raw den, so `den.aspects.test` reaches the
    # ref carrying native `.key` and `refKey` (has-aspect.nix) resolves it via a single `ref.key` lookup.
    test-host-sees-aspect-it-provides-to-users = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.test.nixos = { };

        den.aspects.effect = {
          homeManager =
            { host, ... }:
            {
              home.username =
                if host.hasAspect den.aspects.test then lib.mkForce "right" else lib.mkForce "wrong";
            };
        };

        den.aspects.igloo = {
          provides.to-users.includes = [
            den.aspects.test
            den.aspects.effect
          ];
        };

        expr = igloo.home-manager.users.tux.home.username;
        expected = "right";
      }
    );

  };
}
