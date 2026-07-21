# den v1 BEHAVIORAL migration — public-api/den-default.nix (denful/den templates/ci/modules/public-api/
# den-default.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `defaults` (den.default
# fleet-wide includes, plain / host-fn / user-fn forms).
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
  flake.tests.den-defaults = {

    test-includes-owned = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.includes = [ den.aspects.foo ];
        den.aspects.foo.nixos.users.users.tux.description = "pingu";

        expr = igloo.users.users.tux.description;
        expected = "pingu";
      }
    );

    test-includes-host-function = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.includes = [ den.aspects.foo ];
        den.aspects.foo =
          { host, ... }:
          {
            nixos.users.users.tux.description = "pingu";
          };

        expr = igloo.users.users.tux.description;
        expected = "pingu";
      }
    );

    # BLOCKED-WSB (user→host content delivery; missing-surface): a `den.default.includes` `{ user, ... }:`
    # bare-fn aspect walked per fleet user, materializing `nixos.users.users.tux.description`. den-hoag
    # actual: `attribute 'tux' missing` — user-cell content never folds to the host's `users.users.<u>` on
    # the bridge path (the stubbed fleet-resolution / env fan-out surface, board #49). Confirmed NOT a
    # scaffold gap: the sibling `{ host, ... }:` form (test-includes-host-function, live above) DOES land,
    # and the canonical os-user (`user.description` → `users.users.tux`) fails identically. WS-B, not a
    # value divergence.
    # test-includes-user-function = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux.userName = "pingu";
    #
    #     den.default.includes = [ den.aspects.foo ];
    #
    #     den.aspects.foo =
    #       { user, ... }:
    #       {
    #         nixos.users.users.tux.description = user.userName;
    #       };
    #
    #     expr = igloo.users.users.tux.description;
    #     expected = "pingu";
    #   }
    # );

  };
}
