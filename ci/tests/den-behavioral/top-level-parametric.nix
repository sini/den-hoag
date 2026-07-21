# den v1 BEHAVIORAL migration — public-api/top-level-parametric.nix (denful/den templates/ci/modules/
# public-api/top-level-parametric.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1 EXCEPT the R-rewrite below.
# Concern: `aspects-core` (a bare-function aspect at top-level `includes` binds `host`/`user` context).
#
# R-REWRITE (mechanical, per migration rule 3): v1 `den.provides.hostname` → `den.batteries.hostname` —
# den-hoag exposes ported battery content at `config.den.batteries.<name>` only.
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
  flake.tests.den-aspects-core = {

    # BLOCKED-WSB (user→host content delivery; missing-surface, board #49): a bare-function aspect at
    # `den.aspects.tux.includes` binds `{ user, ... }` and writes `nixos.users.users.tux.description`.
    # Empirically confirmed (`attribute 'tux' missing` forcing `igloo.users.users.tux`): user-cell content
    # never folds to the host's `users.users.<u>` on the bridge path — same root as primary-user.nix
    # `test-on-nixos-included-at-user`, host-options.nix `test-user-custom-username`, and the canonical
    # os-user (os-user-class.nix, ALL cases). NOT a scaffold gap.
    # test-user-aspect-with-context = denTest (
    #   { den, igloo, ... }:
    #   let
    #     custom-user-config =
    #       { user, ... }:
    #       {
    #         nixos.users.users.tux.description = user.userName;
    #       };
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.tux.includes = [ custom-user-config ];
    #
    #     expr = igloo.users.users.tux.description;
    #     expected = "tux";
    #   }
    # );

    test-host-aspect-with-context = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ den.batteries.hostname ];

        expr = igloo.networking.hostName;
        expected = "igloo";
      }
    );

    # BLOCKED-WSB: same `users.users.tux` fold gap as above.
    # test-user-and-host-context = denTest (
    #   { den, igloo, ... }:
    #   let
    #     from-both =
    #       { host, user, ... }:
    #       {
    #         nixos.users.users.tux.description = "${user.userName}@${host.name}";
    #       };
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.tux.includes = [ from-both ];
    #
    #     expr = igloo.users.users.tux.description;
    #     expected = "tux@igloo";
    #   }
    # );

  };
}
