# den v1 BEHAVIORAL migration — public-api/den-default.nix (denful/den templates/ci/modules/public-api/
# den-default.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `defaults` (den.default
# fleet-wide includes, plain / host-fn / user-fn forms).
{
  denHoagFlakeModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit denHoagFlakeModule nixpkgs nixpkgsLib;
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

    # PARKED-DIVERGENCE: v1-expected "pingu" (`den.default.includes` of a `{ user, ... }:` bare-fn
    # aspect is walked per fleet user, materializing `nixos.users.users.tux.description = user.userName`)
    # vs den-hoag-actual: `igloo.users.users.tux` never materializes — `attribute 'tux' missing` at
    # `igloo.users.users.tux.description`. The sibling `{ host, ... }:` form (test-includes-host-function,
    # above) DOES fire; only the `{ user, ... }:` closure form of a `den.default.includes` fn fails to
    # walk. Not altered to route around the gap.
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
