# den v1 BEHAVIORAL migration — public-api/wsl-class.nix (denful/den templates/ci/modules/public-api/
# wsl-class.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `class-modules` (the `wsl` host-class battery forwards a parametric include). The wsl battery behavior
# (host `wsl.{enable,module}` option, the host-scope `host-to-wsl-host` module import, and the
# `wsl-to-host` class-content route) is provisioned in lib/compat/builtins.nix.
#
# R-REWRITE (mechanical, per migration rule 3): v1 `den.provides.primary-user` → `den.batteries.primary-user`
# (den-hoag exposes ported battery content at `config.den.batteries.<name>`).
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
  mockWslModule =
    { lib, ... }:
    {
      options.wsl.defaultUser = lib.mkOption { type = lib.types.str; };
      options.wsl.enable = lib.mkOption { type = lib.types.bool; };
    };
in
{
  flake.tests.den-class-modules = {

    test-wsl-forwards = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          wsl.enable = true;
          wsl.module = mockWslModule;
          users.tux = { };
        };

        den.aspects.tux.includes = [ den.batteries.primary-user ];

        expr = {
          user = igloo.wsl.defaultUser;
          enabled = igloo.wsl.enable;
        };

        expected = {
          user = "tux";
          enabled = true;
        };
      }
    );

    test-wsl-from-parametric-include = denTest (
      {
        den,
        igloo,
        lib,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo = {
          wsl.enable = true;
          wsl.module = mockWslModule;
          users.tux = { };
        };

        den.aspects.igloo = {
          includes = [
            (
              { host, ... }:
              lib.optionalAttrs (host.class == "nixos") {
                wsl.defaultUser = "tux";
              }
            )
          ];
        };

        expr = igloo.wsl.defaultUser;
        expected = "tux";
      }
    );
  };
}
