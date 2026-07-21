# den v1 BEHAVIORAL migration — public-api/flat-hosts.nix (denful/den templates/ci/modules/public-api/
# flat-hosts.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `aspects-core` (den.hosts
# flat/by-name addressing — the bridge's `flattenHosts` two-level fold, ci/tests/compat-flat-host.nix).
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
  flake.tests.den-aspects-core = {
    test-flat-host-two-level-shape = denTest (
      { den, ... }:
      {
        den.hosts.igloo = {
          system = "x86_64-linux";
          users.tux = { };
        };

        expr = builtins.attrNames den.hosts;
        expected = [ "x86_64-linux" ];
      }
    );

    test-flat-host-name = denTest (
      { den, ... }:
      {
        den.hosts.igloo = {
          system = "x86_64-linux";
          users.tux = { };
        };

        expr = den.hosts.x86_64-linux.igloo.name;
        expected = "igloo";
      }
    );

    test-flat-host-system = denTest (
      { den, ... }:
      {
        den.hosts.igloo = {
          system = "x86_64-linux";
          users.tux = { };
        };

        expr = den.hosts.x86_64-linux.igloo.system;
        expected = "x86_64-linux";
      }
    );

    test-flat-host-coexists-with-legacy = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.legacy-host.users.tux = { };
        den.hosts.flat-host = {
          system = "x86_64-linux";
          users.tux = { };
        };

        expr = builtins.sort (a: b: a < b) (builtins.attrNames den.hosts.x86_64-linux);
        expected = [
          "flat-host"
          "legacy-host"
        ];
      }
    );

    test-flat-host-users-with-module-args = denTest (
      { den, ... }:
      {
        den.hosts.igloo = {
          system = "x86_64-linux";
          users.tux = { };
        };

        expr = den.hosts.x86_64-linux.igloo.users.tux.host.name;
        expected = "igloo";
      }
    );

    test-flat-host-nixos-output = denTest (
      { den, igloo, ... }:
      {
        den.hosts.igloo = {
          system = "x86_64-linux";
          users.tux = { };
        };
        den.aspects.igloo.nixos.networking.hostName = "flat-test";

        expr = igloo.networking.hostName;
        expected = "flat-test";
      }
    );
  };
}
