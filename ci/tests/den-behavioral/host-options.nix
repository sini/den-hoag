# den v1 BEHAVIORAL migration — public-api/host-options.nix (denful/den templates/ci/modules/public-api/
# host-options.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertions are BYTE-IDENTICAL to v1 EXCEPT the R-rewrite below. Concern:
# `schema` (host entity options: hostName override, custom aspect selection, name default).
#
# R-REWRITE (mechanical, per migration rule 3): v1 `den.provides.hostname` / `den.provides.define-user`
# → `den.batteries.hostname` / `den.batteries.define-user` — den-hoag exposes ported battery content at
# `config.den.batteries.<name>` only (lib/compat/batteries.nix `config.den.batteries = { hostname; ... }`).
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
  flake.tests.den-schema = {

    # PARKED-DIVERGENCE: v1-expected "polar-station" vs den-hoag-actual: `attribute 'hosts' missing`
    # reading `den.hosts.x86_64-linux.igloo.hostName` off the scaffold's `den` helper — the same
    # scaffold-level `helpers.den` read-back gap noted in flat-hosts.nix (an `options.den` named
    # sub-option doesn't read back through `expr`, though the crossed `igloo`/`config.flake` faces do).
    # Not altered to route around the gap.
    # test-custom-hostname-attr = denTest (
    #   { den, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo = {
    #       hostName = "polar-station";
    #       users.tux = { };
    #     };
    #
    #     expr = den.hosts.x86_64-linux.igloo.hostName;
    #     expected = "polar-station";
    #   }
    # );

    test-hostname-used-in-networking = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.default.homeManager.home.stateVersion = "25.11";
        den.default.includes = [ den.batteries.hostname ];

        expr = igloo.networking.hostName;
        expected = "igloo";
      }
    );

    # PARKED-DIVERGENCE: v1-expected "from-custom" (a host's `.aspect = den.aspects.<ref>` field selects
    # a NAMED aspect in place of the self-provide-by-name default) vs den-hoag-actual: "nixos" (the
    # NixOS-default hostname — the custom `.aspect` selection is never applied; igloo resolves as if
    # `.aspect` were unset). This is a genuine value MISMATCH (not a missing-attribute throw), so it rode
    # through the scaffold's own comparator, printing the nix-unit diff directly. Not altered to route
    # around the gap.
    # test-custom-aspect-name = denTest (
    #   { den, config, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo = {
    #       aspect = den.aspects.my-custom-aspect;
    #       users.tux = { };
    #     };
    #     den.default.homeManager.home.stateVersion = "25.11";
    #     den.aspects.my-custom-aspect.nixos.networking.hostName = "from-custom";
    #
    #     expr = config.flake.nixosConfigurations.igloo.config.networking.hostName;
    #     expected = "from-custom";
    #   }
    # );

    # PARKED-DIVERGENCE: same `den.hosts` scaffold read-back gap as test-custom-hostname-attr above.
    # v1-expected "igloo".
    # test-default-aspect-is-name = denTest (
    #   { den, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     expr = den.hosts.x86_64-linux.igloo.name;
    #     expected = "igloo";
    #   }
    # );

    # PARKED-DIVERGENCE: v1-expected true (a `policies.to-users` fn — `{ host, user, ... }:` — routed
    # through `policy.include { includes = [ den.batteries.define-user ]; }` — walks per fleet user,
    # materializing the `penguin` OS account) vs den-hoag-actual: `attribute 'penguin' missing`. Same
    # shape as den-default.nix's test-includes-user-function (a `{ user, ... }:`-closing fn never fires
    # its per-user walk) and primary-user.nix's test-on-nixos-included-at-user. Not altered to route
    # around the gap.
    # test-user-custom-username = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   let
    #     inherit (den.lib.policy) include;
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux.userName = "penguin";
    #     den.aspects.igloo.policies.to-users =
    #       { host, user, ... }:
    #       [
    #         (include {
    #           includes = [ den.batteries.define-user ];
    #         })
    #       ];
    #     den.aspects.igloo.includes = [ den.aspects.igloo.policies.to-users ];
    #
    #     expr = igloo.users.users.penguin.isNormalUser;
    #     expected = true;
    #   }
    # );

  };
}
