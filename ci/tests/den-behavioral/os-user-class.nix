# den v1 BEHAVIORAL migration — public-api/os-user-class.nix (denful/den templates/ci/modules/public-api/
# os-user-class.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `class-modules` (the `user` class forwards owned `.user.*` fields to the host's OS `users.users.<u>`).
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
  flake.tests.den-class-modules = {

    # BLOCKED-WSB (user→host content delivery; missing-surface, board #49): every case in this file reads
    # `igloo.users.users.tux.*` after content is authored at the USER-scoped `den.aspects.tux.user`/`.nixos`
    # cell. Empirically confirmed (`attribute 'tux' missing` forcing `igloo.users.users.tux`): user-cell
    # content never folds to the host's `users.users.<u>` on the bridge path (the stubbed fleet-resolution
    # / env fan-out surface — same root as den-default.nix `test-includes-user-function`, primary-user.nix
    # `test-on-nixos-included-at-user`, host-options.nix `test-user-custom-username`). A `{ host, ... }:`
    # write to the same path DOES land (os-class-host.nix, os-class.nix), so this is not a scaffold gap.
    # Left in place, commented, per the parking rule (never altered to route around the gap).

    # test-forwards-user-description = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.tux.user.description = "pinguino";
    #
    #     expr = igloo.users.users.tux.description;
    #     expected = "pinguino";
    #   }
    # );
    #
    # test-forwards-os-args = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.tux.user =
    #       { pkgs, ... }:
    #       {
    #         description = lib.getName pkgs.hello;
    #       };
    #
    #     expr = igloo.users.users.tux.description;
    #     expected = "hello";
    #   }
    # );
    #
    # test-forwards-mergeable-option = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     # via user class
    #     den.aspects.tux.user =
    #       { pkgs, ... }:
    #       {
    #         packages = [ pkgs.hello ];
    #       };
    #
    #     # via user nixos
    #     den.aspects.tux.nixos =
    #       { pkgs, ... }:
    #       {
    #         users.users.tux.packages = [ pkgs.vim ];
    #       };
    #
    #     # via host nixos
    #     den.aspects.igloo.nixos =
    #       { pkgs, ... }:
    #       {
    #         users.users.tux.packages = [ pkgs.tmux ];
    #       };
    #
    #     expr = lib.sort (a: b: a < b) (
    #       lib.filter (
    #         name:
    #         lib.elem name [
    #           "hello"
    #           "vim"
    #           "tmux"
    #         ]
    #       ) (map lib.getName igloo.users.users.tux.packages)
    #     );
    #     expected = [
    #       "hello"
    #       "tmux"
    #       "vim"
    #     ];
    #   }
    # );
    #
    # test-user-class-from-parametric-include = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.tux = {
    #       user.description = "owned-description";
    #       includes = [
    #         (
    #           { host, ... }:
    #           lib.optionalAttrs (host.class == "nixos") {
    #             user.extraGroups = [ "wheel" ];
    #           }
    #         )
    #       ];
    #     };
    #
    #     expr = igloo.users.users.tux.extraGroups;
    #     expected = [ "wheel" ];
    #   }
    # );
  };
}
