# den v1 BEHAVIORAL migration — public-api/policies.nix (denful/den templates/ci/modules/public-api/
# policies.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*`
# declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `policy` (den.policies + policy.include
# as a den.default.includes target; coexistence with a plain den.default include).
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
  flake.tests.den-policy = {

    test-policy-fires = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.policies.host-to-test-rel =
          _:
          let
            inherit (den.lib.policy) include;
          in
          [
            (include { nixos.users.users.tux.description = "from-rel-target-stage"; })
          ];

        den.default.includes = [ den.policies.host-to-test-rel ];

        expr = igloo.users.users.tux.description;
        expected = "from-rel-target-stage";
      }
    );

    # Both a policy target stage and an into transition contribute
    # to the resolved NixOS config without clobbering each other.
    test-policy-coexists-with-into = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.nixos.users.users.tux.description = "from-default-stage";

        den.policies.host-to-test-rel-coexist =
          _:
          let
            inherit (den.lib.policy) include;
          in
          [
            (include { nixos.networking.hostName = "from-rel-stage"; })
          ];

        den.default.includes = [ den.policies.host-to-test-rel-coexist ];

        expr = [
          igloo.networking.hostName
          igloo.users.users.tux.description
        ];
        expected = [
          "from-rel-stage"
          "from-default-stage"
        ];
      }
    );

  };
}
