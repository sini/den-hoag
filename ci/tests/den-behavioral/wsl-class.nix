# den v1 BEHAVIORAL migration — public-api/wsl-class.nix (denful/den templates/ci/modules/public-api/
# wsl-class.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `class-modules` (the `wsl` host-class battery-module forwards a parametric include).
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
let
  mockWslModule =
    { lib, ... }:
    {
      options.wsl.defaultUser = lib.mkOption { type = lib.types.str; };
      options.wsl.enable = lib.mkOption { type = lib.types.bool; };
    };
in
{
  flake.tests.den-class-modules = {

    # BLOCKED-WSB (missing-surface, same family as B9 hjem/maid bare-inert classes): v1's per-host
    # `den.hosts.<h>.wsl.module` registers a bare-inert CLASS whose module the pipeline imports into that
    # host's class body (like `hjem.module`/`nix-maid.module`). Empirically confirmed: forcing
    # `igloo.wsl.*` throws `attribute 'wsl' missing` — the `wsl` class/option is never wired from
    # `den.hosts.igloo.wsl.module`, so nothing declares the `wsl.*` options at all. Left in place,
    # commented, per the parking rule.

    # test-wsl-forwards = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo = {
    #       wsl.enable = true;
    #       wsl.module = mockWslModule;
    #       users.tux = { };
    #     };
    #
    #     den.aspects.tux.includes = [ den.batteries.primary-user ];
    #
    #     expr = {
    #       user = igloo.wsl.defaultUser;
    #       enabled = igloo.wsl.enable;
    #     };
    #
    #     expected = {
    #       user = "tux";
    #       enabled = true;
    #     };
    #   }
    # );
    #
    # test-wsl-from-parametric-include = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo = {
    #       wsl.enable = true;
    #       wsl.module = mockWslModule;
    #       users.tux = { };
    #     };
    #
    #     den.aspects.igloo = {
    #       includes = [
    #         (
    #           { host, ... }:
    #           lib.optionalAttrs (host.class == "nixos") {
    #             wsl.defaultUser = "tux";
    #           }
    #         )
    #       ];
    #     };
    #
    #     expr = igloo.wsl.defaultUser;
    #     expected = "tux";
    #   }
    # );
  };
}
