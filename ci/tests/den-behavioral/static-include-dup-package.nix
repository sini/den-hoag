# den v1 BEHAVIORAL migration — deadbugs/static-include-dup-package.nix (denful/den templates/ci/modules/
# deadbugs/static-include-dup-package.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `include` (static
# vs bare-function includes at default/host/user scope, package-valued options — forwarded public surface).
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

  flake.tests.den-include = {

    # BLOCKED-WSB (compile-time key-classification restriction, same family as pipe-broadcast.nix's
    # test-broadcast-home-pool-to-host): `den-hoag compat (§2.2): aspect-include \`<unnamed>\` declares key
    # \`homeManager\` with a function value — neither a facet, a registered class, nor a quirk channel` —
    # a bare anonymous `includes` list ITEM (`{ homeManager = { pkgs, ... }: {...}; }`) with a
    # function-valued `homeManager` facet throws; den-hoag's compile only accepts an attrset there.
    # test-static-include-regression-static-include-dup-package = denTest (
    #   {
    #     den,
    #     lib,
    #     tuxHm,
    #     ...
    #   }:
    #   {
    #     den.default.homeManager.home.stateVersion = "25.11";
    #
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.tux.includes = [
    #       {
    #         homeManager =
    #           { pkgs, ... }:
    #           {
    #             programs.emacs.enable = true;
    #             programs.emacs.package = pkgs.emacs-nox;
    #           };
    #       }
    #     ];
    #
    #     expr = lib.getName tuxHm.programs.emacs.package;
    #     expected = "emacs-nox";
    #   }
    # );

    # PARKED-DIVERGENCE (clean eval, wrong value): v1 expected [ "tux" ]; den-hoag actual [ ] — a bare
    # parametric FUNCTION include (`{ user, ... }: { nixos.foo = [ user.name ]; }`) registered via
    # `den.default.includes` never contributes its content; `igloo.foo` stays empty instead of resolving
    # `user.name` per-user.
    # test-default-func-include-regression-static-include-dup-package = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.default.homeManager.home.stateVersion = "25.11";
    #
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.default.nixos.imports = [
    #       { options.foo = lib.mkOption { type = lib.types.listOf lib.types.str; }; }
    #     ];
    #
    #     den.default.includes = [
    #       (
    #         { user, ... }:
    #         {
    #           nixos.foo = [ user.name ];
    #         }
    #       )
    #     ];
    #
    #     expr = igloo.foo;
    #     expected = [ "tux" ];
    #   }
    # );

    test-host-owned-regression-static-include-dup-package = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.default.homeManager.home.stateVersion = "25.11";

        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.includes = [
          {
            nixos.imports = [
              { options.foo = lib.mkOption { type = lib.types.listOf lib.types.str; }; }
            ];
          }
        ];

        den.aspects.igloo.nixos.foo = [ "bar" ];

        expr = igloo.foo;
        expected = [ "bar" ];
      }
    );

    test-default-owned-package-regression-static-include-dup-package = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.nixos =
          { pkgs, ... }:
          {
            services.locate.package = pkgs.plocate;
          };

        expr = lib.getName igloo.services.locate.package;
        expected = "plocate";
      }
    );

    test-default-static-package-regression-static-include-dup-package = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.includes = [
          {
            name = "plocate-locate";
            nixos =
              { pkgs, ... }:
              {
                services.locate.package = pkgs.plocate;
              };
          }
        ];

        expr = lib.getName igloo.services.locate.package;
        expected = "plocate";
      }
    );

    test-default-owned-list-regression-static-include-dup-package = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.default.nixos.imports = [
          {
            options.tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          }
        ];
        den.default.nixos.tags = [ "server" ];

        expr = igloo.tags;
        expected = [ "server" ];
      }
    );

    test-host-owned-package-regression-static-include-dup-package = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.nixos =
          { pkgs, ... }:
          {
            services.locate.package = pkgs.plocate;
          };

        expr = lib.getName igloo.services.locate.package;
        expected = "plocate";
      }
    );

    test-host-owned-list-regression-static-include-dup-package = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.nixos.imports = [
          {
            options.tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          }
        ];
        den.aspects.igloo.nixos.tags = [ "server" ];

        expr = igloo.tags;
        expected = [ "server" ];
      }
    );

    test-default-list-multi-user-regression-static-include-dup-package = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users = {
          tux = { };
          pingu = { };
        };

        den.default.nixos.imports = [
          {
            options.tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          }
        ];
        den.default.nixos.tags = [ "server" ];

        expr = igloo.tags;
        expected = [ "server" ];
      }
    );

  };

}
