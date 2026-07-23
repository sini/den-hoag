# den v1 BEHAVIORAL migration — public-api/hjem-class.nix (denful/den templates/ci/modules/public-api/
# hjem-class.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `class-modules` (the `hjem` user-environment battery forwards the hjem class bucket to the host OS at
# `hjem.users.<u>`). The hjem battery behavior (host `hjem.{enable,module}` option, the host-scope module
# import gated on a hjem-class user, and the `hjem-user-detect` content forward) is provisioned in
# lib/compat/builtins.nix.
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
  mockHjemModule =
    { lib, ... }:
    {
      options.hjem.users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submoduleWith {
            modules = [
              {
                config._module.freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
              }
            ];
          }
        );
        default = { };
      };
    };
in
{
  flake.tests.den-hjem-class = {

    test-hjem-forwards-to-users = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          users.tux.classes = [ "hjem" ];
          hjem.module = mockHjemModule;
        };

        den.aspects.tux.hjem.theme = "nord";

        expr = igloo.hjem.users.tux.theme;
        expected = "nord";
      }
    );

    test-hjem-merges-with-nixos = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo = {
          users.tux.classes = [ "hjem" ];
          hjem.module = mockHjemModule;
        };

        den.aspects.tux.hjem.tags = [ "from-hjem" ];
        den.aspects.igloo.nixos.hjem.users.tux.tags = [ "from-nixos" ];

        expr = lib.sort (a: b: a < b) igloo.hjem.users.tux.tags;
        expected = [
          "from-hjem"
          "from-nixos"
        ];
      }
    );

    test-no-hjem-without-hjem-class = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          users.tux = { };
          hjem.module = mockHjemModule;
        };

        expr = igloo ? hjem;
        expected = false;
      }
    );

  };
}
