# den v1 BEHAVIORAL migration — deadbugs/issue-311-nested-includes-are-parametric.nix (denful/den
# templates/ci/modules/deadbugs/issue-311-nested-includes-are-parametric.nix). Migrated by copy +
# arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern: `nested-aspects` (a bare-function
# aspect's OWN `includes` list is itself parametric — the nested include binds `{ user, ... }` just like
# the outer one binds `{ host, ... }`).
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
  flake.tests.den-nested-aspects = {

    # BLOCKED-WSB (missing surface, same family as hasaspect-host-provides-to-users.nix): content is
    # authored at the user's OWN self-aspect (`den.aspects.tux.includes = […]`, a PLAIN self-aspect — not
    # the host-aspects battery). Empirically confirmed: forcing `tuxHm.home.keyboard.model` throws
    # `attribute 'tux' missing` — `home-manager.users.tux` is never materialized via a plain self-aspect's
    # homeManager content (only the `host-aspects` battery's re-resolution path is proven to do so — see
    # host-aspects-sibling-leak.nix). Left in place, commented, per the parking rule.
    # test-nested-includes-are-parametric = denTest (
    #   {
    #     den,
    #     lib,
    #     tuxHm,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.tux.includes = [
    #       (
    #         { host, ... }:
    #         {
    #           homeManager.home.keyboard.model = lib.mkDefault "${host.name}-nested";
    #           includes = [
    #             (
    #               { user, ... }:
    #               {
    #                 homeManager.home.keyboard.model = lib.mkForce "${user.name}-nested";
    #               }
    #             )
    #           ];
    #         }
    #       )
    #     ];
    #
    #     expr = tuxHm.home.keyboard.model;
    #     expected = "tux-nested";
    #   }
    # );

  };
}
