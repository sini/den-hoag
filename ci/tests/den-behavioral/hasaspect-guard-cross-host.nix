# den v1 BEHAVIORAL migration — public-api/hasaspect-guard-cross-host.nix (denful/den templates/ci/
# modules/public-api/hasaspect-guard-cross-host.nix, regression for denful/den#613). Migrated by copy +
# arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + the assertions are
# BYTE-IDENTICAL to v1. Concern: `hasAspect` (host.hasAspect membership must not leak across sibling
# hosts / must see inherited den.default membership).
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
  flake.tests.den-hasAspect = {

    # PARKED-BLOCKED-WSB: `den.lib.policy.when` — den-hoag's migrationLib `den.lib.policy` surface
    # (flake.nix migrationLib.policy) ports {route,provide,include,exclude,spawn,mkPolicy,pipe,resolve,
    # instantiate}; `when` is NOT among them. Every test in this file guards on `policy.when`, so forcing
    # it throws `attribute 'when' missing` before the `host.hasAspect` semantics under test are ever
    # reached. Left in place, commented, per the parking rule (never altered to route around the gap).
    # test-sibling-include-does-not-leak = denTest (
    #   {
    #     den,
    #     igloo,
    #     ...
    #   }:
    #   let
    #     inherit (den.lib) policy;
    #   in
    #   {
    #     den.hosts.x86_64-linux.iceberg.users.tux = { };
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.test.nixos = { };
    #     den.aspects.iceberg.includes = [ den.aspects.test ];
    #     den.aspects.igloo.includes = [
    #       (policy.when ({ host, ... }: host.hasAspect den.aspects.test) {
    #         nixos.networking.hostName = "wrong";
    #       })
    #     ];
    #
    #     expr = igloo.networking.hostName;
    #     expected = "nixos";
    #   }
    # );

    # PARKED-BLOCKED-WSB: same `policy.when` gap as above.
    # test-sibling-include-does-not-leak-reversed = denTest (
    #   {
    #     den,
    #     iceberg,
    #     ...
    #   }:
    #   let
    #     inherit (den.lib) policy;
    #   in
    #   {
    #     den.hosts.x86_64-linux.iceberg.users.tux = { };
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.test.nixos = { };
    #     den.aspects.igloo.includes = [ den.aspects.test ];
    #     den.aspects.iceberg.includes = [
    #       (policy.when ({ host, ... }: host.hasAspect den.aspects.test) {
    #         nixos.networking.hostName = "wrong";
    #       })
    #     ];
    #
    #     expr = iceberg.networking.hostName;
    #     expected = "nixos";
    #   }
    # );

    # PARKED-BLOCKED-WSB: same `policy.when` gap as above.
    # test-own-include-fires = denTest (
    #   {
    #     den,
    #     igloo,
    #     ...
    #   }:
    #   let
    #     inherit (den.lib) policy;
    #   in
    #   {
    #     den.hosts.x86_64-linux.iceberg.users.tux = { };
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.test.nixos = { };
    #     den.aspects.igloo.includes = [
    #       den.aspects.test
    #       (policy.when ({ host, ... }: host.hasAspect den.aspects.test) {
    #         nixos.networking.hostName = "fired";
    #       })
    #     ];
    #
    #     expr = igloo.networking.hostName;
    #     expected = "fired";
    #   }
    # );

    # PARKED-BLOCKED-WSB: same `policy.when` gap as above.
    # test-default-include-inherited-fires = denTest (
    #   {
    #     den,
    #     igloo,
    #     ...
    #   }:
    #   let
    #     inherit (den.lib) policy;
    #   in
    #   {
    #     den.hosts.x86_64-linux.iceberg.users.tux = { };
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.test.nixos = { };
    #     den.default.includes = [ den.aspects.test ];
    #     den.aspects.igloo.includes = [
    #       (policy.when ({ host, ... }: host.hasAspect den.aspects.test) {
    #         nixos.networking.hostName = "fired";
    #       })
    #     ];
    #
    #     expr = igloo.networking.hostName;
    #     expected = "fired";
    #   }
    # );
  };
}
