# den v1 BEHAVIORAL migration — public-api/maid-class.nix (denful/den templates/ci/modules/public-api/
# maid-class.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `class-modules` (the `maid` user-environment battery forwards the maid class bucket to the host OS at
# `users.users.<u>.maid`). The maid battery behavior (host `nix-maid.{enable,module}` option, the
# host-scope module import gated on a maid-class user, and the `maid-user-detect` content forward) is
# provisioned in lib/compat/builtins.nix.
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
  mockMaidModule =
    { lib, ... }:
    {
      options.users.users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.maid = lib.mkOption {
              type = lib.types.submoduleWith {
                modules = [
                  {
                    config._module.freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
                  }
                ];
              };
              default = { };
            };
          }
        );
      };
    };
in
{
  flake.tests.den-maid-class = {

    test-maid-forwards-to-users = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          users.tux.classes = [ "maid" ];
          nix-maid.module = mockMaidModule;
        };

        den.aspects.tux.maid.description = "maid-tux";

        expr = igloo.users.users.tux.maid.description;
        expected = "maid-tux";
      }
    );

    test-maid-merges-with-nixos = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo = {
          users.tux.classes = [ "maid" ];
          nix-maid.module = mockMaidModule;
        };

        den.aspects.tux.maid.tags = [ "from-maid" ];
        den.aspects.igloo.nixos.users.users.tux.maid.tags = [ "from-nixos" ];

        expr = lib.sort (a: b: a < b) igloo.users.users.tux.maid.tags;
        expected = [
          "from-maid"
          "from-nixos"
        ];
      }
    );

    test-no-maid-without-maid-class = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          users.tux = { };
          nix-maid.module = mockMaidModule;
        };

        expr = igloo ? users.tux.maid;
        expected = false;
      }
    );

  };
}
