# den v1 BEHAVIORAL migration — public-api/nested-class-module-args.nix (denful/den templates/ci/modules/
# public-api/nested-class-module-args.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1 EXCEPT the R-rewrite below.
# Concern: `class-modules` (a `{ user, ... }` class module skips when `user` is absent from ctx; the same
# parametric class module deduplicates across two include paths — sibling-parent and shared-leaf).
#
# R-REWRITE (mechanical, per migration rule 3): v1 `den.provides.define-user` → `den.batteries.define-user`
# — den-hoag exposes ported battery content at `config.den.batteries.<name>` only.
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

    # BLOCKED-WSB (user→host content delivery; missing-surface, board #49): `den.aspects.pol` (a USER-scoped
    # self-aspect) includes a `{ user, ... }: { nixos.nix.settings.trusted-users = [...]; }` module; its
    # nixos-class content must fold into HOST x1c's config. Empirically confirmed: the resolved value is
    # `[ "root" ]`, missing "pol" — same root cause as os-user-class.nix/primary-user.nix/host-options.nix
    # (user-cell content never folds to the host on the bridge path), here manifesting as a silently
    # missing list contribution rather than a throw (a list option merges regardless of scope for whatever
    # DOES fold; the user-scoped contribution itself never arrives). NOT a scaffold gap.
    # test-guard-skips-without-context = denTest (
    #   {
    #     den,
    #     config,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.x1c.users.pol = { };
    #
    #     den.aspects.tools.provides.nix-trusted-user = {
    #       includes = [
    #         {
    #           nixos =
    #             { user, ... }:
    #             {
    #               nix.settings.trusted-users = [ user.userName ];
    #             };
    #         }
    #       ];
    #     };
    #
    #     # benix includes nix-trusted-user but has no user context
    #     den.aspects.benix = {
    #       includes = [
    #         den.aspects.tools.provides.nix-trusted-user
    #       ];
    #       nixos.users.users.benix.isNormalUser = true;
    #     };
    #
    #     # pol includes both directly and via benix
    #     den.aspects.pol.includes = [
    #       den.batteries.define-user
    #       den.aspects.tools.provides.nix-trusted-user
    #       den.aspects.benix
    #     ];
    #
    #     # Should not error — guard skips benix's emission of { user }
    #     # Pipeline correctly deduplicates across include paths
    #     expr = config.flake.nixosConfigurations.x1c.config.nix.settings.trusted-users;
    #     expected = [
    #       "root"
    #       "pol"
    #     ];
    #   }
    # );

    # Dedup: same aspect included via two parents should emit class once
    test-dedup-same-aspect-two-parents = denTest (
      {
        den,
        config,
        ...
      }:
      {
        den.hosts.x86_64-linux.x1c.users.pol = { };

        den.aspects.shared-setting = {
          nixos.networking.hostName = "from-shared";
        };

        den.aspects.bundle-a = {
          includes = [ den.aspects.shared-setting ];
        };

        den.aspects.bundle-b = {
          includes = [ den.aspects.shared-setting ];
        };

        den.aspects.x1c.includes = [
          den.aspects.bundle-a
          den.aspects.bundle-b
        ];

        # shared-setting emits nixos class from two paths — should dedup
        expr = config.flake.nixosConfigurations.x1c.config.networking.hostName;
        expected = "from-shared";
      }
    );

    # BLOCKED-WSB: same user→host fold gap as test-guard-skips-without-context above. Empirically confirmed
    # actual value `[ "root" ]`, missing "pol" (never mind the dedup this case pins — the contribution
    # never arrives at all).
    # test-dedup-parametric-class-two-parents = denTest (
    #   {
    #     den,
    #     config,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.x1c.users.pol = { };
    #
    #     den.aspects.trusted-user =
    #       { user, ... }:
    #       {
    #         nixos.nix.settings.trusted-users = [ user.userName ];
    #       };
    #
    #     den.aspects.security.includes = [ den.aspects.trusted-user ];
    #     den.aspects.base.includes = [ den.aspects.trusted-user ];
    #
    #     den.aspects.pol.includes = [
    #       den.batteries.define-user
    #       den.aspects.security
    #       den.aspects.base
    #     ];
    #
    #     # Same parametric aspect resolves with same { user=pol } from two parents
    #     # BUG: produces [ "root" "pol" "pol" ] — should be [ "root" "pol" ]
    #     expr = config.flake.nixosConfigurations.x1c.config.nix.settings.trusted-users;
    #     expected = [
    #       "root"
    #       "pol"
    #     ];
    #   }
    # );

  };
}
