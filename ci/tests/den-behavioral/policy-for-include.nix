# den v1 BEHAVIORAL migration — public-api/policy-for-include.nix (denful/den templates/ci/modules/
# public-api/policy-for-include.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `policy`
# (policy.for / policy.when wrapping policy.include and inline aspects, on den.schema.host.includes).
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
    # BLOCKED-WSB: `den.lib.policy.for` — den-hoag's migrationLib `den.lib.policy` surface
    # (flake.nix migrationLib.policy) ports {route,provide,include,exclude,spawn,mkPolicy,pipe,resolve,
    # instantiate} — `for` is NOT among them (v1 policy-effects.nix's `for` combinator was never carried
    # over to the compat lib). Forcing `policy.for` throws `attribute 'for' missing`. Left in place,
    # commented, per the parking rule (never altered to route around the gap).
    # test-for-include-fires = denTest (
    #   { den, config, ... }:
    #   let
    #     inherit (den) aspects;
    #     inherit (den.lib) policy;
    #     yalova = den.hosts.x86_64-linux.yalova;
    #     yalovaConfig = config.flake.nixosConfigurations.yalova.config;
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.yalova.users.tux = { };
    #
    #     den.schema.host.includes = [
    #       (policy.for yalova (policy.include aspects.zed-editor))
    #     ];
    #
    #     den.aspects.zed-editor = {
    #       nixos.networking.hostName = "from-zed";
    #     };
    #
    #     expr = yalovaConfig.networking.hostName;
    #     expected = "from-zed";
    #   }
    # );

    # BLOCKED-WSB: same `policy.for` gap as above.
    # test-for-include-suppressed = denTest (
    #   { den, igloo, ... }:
    #   let
    #     inherit (den) aspects;
    #     inherit (den.lib) policy;
    #     yalova = den.hosts.x86_64-linux.yalova;
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.yalova.users.tux = { };
    #
    #     den.schema.host.includes = [
    #       (policy.for yalova (policy.include aspects.zed-editor))
    #     ];
    #
    #     den.aspects.zed-editor = {
    #       nixos.services.foobar.enable = true;
    #     };
    #
    #     expr = igloo.services.foobar.enable or false;
    #     expected = false;
    #   }
    # );

    # BLOCKED-WSB: `den.lib.policy.when` — same migrationLib surface, same absence (`when` is
    # not ported either). Forcing throws `attribute 'when' missing`.
    # test-when-include-fires = denTest (
    #   { den, igloo, ... }:
    #   let
    #     inherit (den) aspects;
    #     inherit (den.lib) policy;
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.schema.host.includes = [
    #       (policy.when (_: true) (policy.include aspects.zed-editor))
    #     ];
    #
    #     den.aspects.zed-editor = {
    #       nixos.networking.hostName = "from-zed";
    #     };
    #
    #     expr = igloo.networking.hostName;
    #     expected = "from-zed";
    #   }
    # );

    # BLOCKED-WSB: same `policy.when` gap as above.
    # test-when-inline-aspect = denTest (
    #   { den, igloo, ... }:
    #   let
    #     inherit (den.lib) policy;
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.schema.host.includes = [
    #       (policy.when (_: true) {
    #         nixos.networking.hostName = "from-inline";
    #       })
    #     ];
    #
    #     expr = igloo.networking.hostName;
    #     expected = "from-inline";
    #   }
    # );
  };
}
