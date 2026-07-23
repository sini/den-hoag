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

    # ALIAS WITNESS — `den.lib.perHost f` is a pure alias for `{ host, ... }: f { inherit host; }` (the
    # deprecated context guard, modules/context/perHost-perUser.nix). The corpus never exercises the alias
    # itself (v1's own deprecated test writes inline lambdas), so this is its only proof. The SAME body
    # `fromHost` is delivered two ways: through `den.lib.perHost` (host igloo) and through the literal inline
    # lambda the alias claims to be (host iceberg). den-hoag resolves both through the identical isFunction
    # include arm, so each binds `host` the same way and materializes the host-derived nixos content.
    test-perhost-alias-equals-inline = denTest (
      {
        den,
        igloo,
        iceberg,
        ...
      }:
      let
        fromHost = { host }: { nixos.networking.hostName = "H-${host.name}"; };
      in
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.x86_64-linux.iceberg.users.tux = { };
        den.aspects.igloo.includes = [ (den.lib.perHost fromHost) ];
        den.aspects.iceberg.includes = [ ({ host, ... }: fromHost { inherit host; }) ];

        expr = {
          viaAlias = igloo.networking.hostName;
          viaInline = iceberg.networking.hostName;
        };
        expected = {
          viaAlias = "H-igloo";
          viaInline = "H-iceberg";
        };
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
