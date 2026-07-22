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

    test-custom-hostname-attr = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          hostName = "polar-station";
          users.tux = { };
        };

        expr = den.hosts.x86_64-linux.igloo.hostName;
        expected = "polar-station";
      }
    );

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

    test-default-aspect-is-name = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        expr = den.hosts.x86_64-linux.igloo.name;
        expected = "igloo";
      }
    );

    # PARKED-DIVERGENCE (genuine den-hoag-vs-den value mismatch → owner gate): a host's `.aspect =
    # den.aspects.<ref>` field selects a NAMED aspect in place of the self-provide-by-name default. v1
    # applies it (hostName "from-custom"); den-hoag resolves as if `.aspect` were unset → the NixOS default
    # "nixos". A real value mismatch (rode the comparator, not a throw), so the host `.aspect` selection
    # semantic genuinely differs. NOT a scaffold/harness gap.
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

    # BLOCKED: .user.* class-module forward via `policies.to-users` cross-delivery. The assertion forces
    # `igloo.users.users.penguin`, materialized by a host `policies.to-users` per-user walk routing the
    # `define-user` battery to create the OS account — but that user→host `users.users.<u>` projection does
    # not land (`attribute 'penguin' missing`). A separate cross-delivery / os-user forward rung, NOT the
    # `{ host, user }` ctx family this seed delivers (a `{ user, host }` battery included DIRECTLY at a user
    # self-aspect and WRITING `users.users.<u>` does land — see primary-user.nix).
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
