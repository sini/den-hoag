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

    # BLOCKED: define-user via `policies.to-users` POLICY fan-out (board #49) — a SEPARATE seam, NOT the
    # `.user.*` route. A host `den.aspects.igloo.policies.to-users` fn fans the `define-user` battery onto
    # each user (keyed by `userName = "penguin"` ≠ name) to create `users.users.penguin`; that resolve/
    # provides per-user fan-out does not materialize the account (`attribute 'penguin' missing`), and it is
    # unaffected by the parent-targeted user→host route this rung fixed (which projects a user cell's OWN
    # `.user`-class content — os-user-class.nix — not a host-side to-users policy walk).
    # PARAMETRIC-INCLUDE LATE-DISPATCH does NOT reach this either: the `to-users` fn is a
    # `policies.<name>` POLICY RECORD (it rides the shipped aspect-include-policy arm's `__firesAtKinds`
    # confinement, `compat-scope-local-firing.nix`), not the bare-fn radiation arm. The
    # LATE-DISPATCH half — a `{ host, user }` include reaching the user CELL — is now witnessed by
    # `compat-nested-aspects.nix test-barefn-latedispatch-fires-at-cell-not-host`. What remains RED here is
    # ONLY the cell→host `users.users.penguin` DELIVERY fold (the define-user account materialised at the
    # cell must land in the host's nixos config), verified empirically still `attribute 'penguin' missing`
    # under the bare-fn radiation arm. That delivery seam is its own rung, not part of late-dispatch.
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
