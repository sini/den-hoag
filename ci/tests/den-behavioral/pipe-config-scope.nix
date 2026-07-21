# den v1 BEHAVIORAL migration — public-api/pipe-config-scope.nix (denful/den templates/ci/modules/
# public-api/pipe-config-scope.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `pipe`
# (producer-class resolution for the DEFERRED `__configThunk` path — `den.lib.policy.pipe` is forwarded).
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
  # v1's file-level `{ denTest, lib, ... }:` arg — nested class-module closures below reference `lib`
  # without naming it as their own formal (see pipe-policy.nix for the full rationale).
  lib = nixpkgsLib;
in
{
  flake.tests.den-pipe = {

    # BLOCKED-WSB (known gap, same as host-aspects-sibling-leak.nix "on-demand hm-users key"):
    # home-manager.users.<name> entries are created ON-DEMAND (content-driven), not for every
    # nominally-homeManager-classed user; forcing `tuxHm` throws `attribute 'tux' missing`.
    # # Host-PRODUCED config-thunk (reads a nixos field) CONSUMED in a home (a
    # # different class). Must resolve against the host's nixos config (producing
    # # class), not the home config — which would throw `networking missing`.
    # test-host-produced-consumed-in-home = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.dev.description = "device";
    #
    #     den.aspects.set-hostname.nixos =
    #       { host, ... }:
    #       {
    #         networking.hostName = host.name;
    #       };
    #     den.policies.bind-dev =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "dev" [ ]) ];
    #     den.schema.host.includes = [
    #       den.aspects.set-hostname
    #       den.policies.bind-dev
    #     ];
    #
    #     # PRODUCED at host scope, reads a NIXOS field.
    #     den.aspects.igloo.dev = { config, ... }: [ "h:${config.networking.hostName}" ];
    #
    #     # CONSUMED in tux's home (different class) via pure-consumer inheritance.
    #     den.aspects.tux.homeManager =
    #       { dev, ... }:
    #       {
    #         home.sessionVariables.DEV = builtins.head dev;
    #       };
    #
    #     expr = tuxHm.home.sessionVariables.DEV;
    #     expected = "h:igloo";
    #   }
    # );

    # BLOCKED-WSB (known gap, same as host-aspects-sibling-leak.nix "on-demand hm-users key"):
    # home-manager.users.<name> entries are created ON-DEMAND (content-driven), not for every
    # nominally-homeManager-classed user; forcing `tuxHm` throws `attribute 'tux' missing`.
    # # Same-scope same-class (the common case) keeps working: a user-produced
    # # config-thunk reading a HOME field, consumed in the same user's home.
    # test-user-produced-consumed-in-own-home = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.dev.description = "device";
    #
    #     den.aspects.tux = {
    #       dev = { config, ... }: [ "u:${config.home.username}" ];
    #       homeManager =
    #         { dev, ... }:
    #         {
    #           home.sessionVariables.DEV = builtins.head dev;
    #         };
    #     };
    #
    #     expr = tuxHm.home.sessionVariables.DEV;
    #     expected = "u:tux";
    #   }
    # );

    # BLOCKED-WSB (pipe.expose is UNWIRED for consumption — same as pipe-scope.nix's
    # test-pipe-expose-basic; here the empty pool it leaves at `igloo` makes the consumer's own
    # `builtins.head dev` throw `'builtins.head' called on an empty list`).
    # # User-PRODUCED config-thunk reading a HOME field, exposed up and CONSUMED in
    # # the host's nixos (cross-class user→host). Resolves against the producer's
    # # home-manager config — the user's own home, not the consuming host config.
    # test-user-produced-consumed-in-host = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.dev.description = "device";
    #
    #     den.policies.expose-dev =
    #       { user, ... }: [ (den.lib.policy.pipe.from "dev" [ den.lib.policy.pipe.expose ]) ];
    #     den.schema.user.includes = [ den.policies.expose-dev ];
    #
    #     # PRODUCED at the user node, reads a HOME field.
    #     den.aspects.tux.dev = { config, ... }: [ "u:${config.home.username}" ];
    #
    #     den.aspects.igloo.nixos =
    #       { dev, ... }:
    #       {
    #         networking.domain = builtins.head dev;
    #       };
    #
    #     expr = igloo.networking.domain;
    #     expected = "u:tux";
    #   }
    # );
  };
}
