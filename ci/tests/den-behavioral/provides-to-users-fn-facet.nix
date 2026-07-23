# den-hoag COMPAT witness — a FUNCTION-VALUED class facet (`homeManager = { host, … }: …`) delivered via
# `provides.to-users`. This pins the §2.2 function-valued-facet LIFT: the compat raw-totality discriminator
# GROUNDS a candidate class-facet key (`homeManager` → the registered `home-manager` class, the v1ClassKeyMap
# spelling) before its malformed-fn membership test, so a fn-valued `homeManager` facet rides raw as a legit
# parametric facet (grounded + gated by compile's `wrapGatedFn`) exactly like an attrset-valued `homeManager`
# facet already does — instead of aborting as a malformed `{ name; fn }` policy record.
#
# The facet body is PLAIN (a fn returning fixed content, no `host.hasAspect` read) — the narrowest witness of
# the lift itself. The `hasAspect` variant (a fn facet whose body reads `host.hasAspect`) stays parked in
# `hasaspect-host-provides-to-users.nix` on a SEPARATE bridge-refKey blocker.
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
  flake.tests.den-provides-fn-facet = {

    # A fn-valued `homeManager` facet, delivered host→users via `provides.to-users`, materializes on the
    # delivered user's home-manager config. Before the lift this aborted at compile (§2.2:
    # "aspect-include declares key `homeManager` with a function value — neither a facet, a registered class,
    # nor a quirk channel"); after grounding the key it rides raw and grounds like an attrset facet.
    test-fn-valued-home-manager-facet-delivered-to-users = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.effect = {
          homeManager =
            { host, ... }:
            {
              # `mkForce` over the user cell's own `home.username = "tux"` default — the witness reads the
              # delivered fn-facet's content won (not the read-side of the lift, just that it materialized).
              home.username = lib.mkForce "right";
            };
        };

        den.aspects.igloo = {
          provides.to-users.includes = [
            den.aspects.effect
          ];
        };

        expr = igloo.home-manager.users.tux.home.username;
        expected = "right";
      }
    );

  };
}
