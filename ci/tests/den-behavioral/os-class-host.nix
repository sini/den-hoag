# den v1 BEHAVIORAL migration — public-api/os-class-host.nix `test-host-os-forwards-to-nixos`
# (denful/den templates/ci/modules/public-api/os-class-host.nix:7-19). Migrated by copy + arg-rename onto
# the `_lib/den-compat-test.nix` scaffold: the `den.*` declarations + the assertion are BYTE-IDENTICAL to
# v1; only the wrapper import (denTest) + the dropped `denTest`/`lib` module args differ. A HOST aspect's
# `os.networking.hostName` forwards through the os-class battery to the host's REAL nixos config (crossed
# via the scaffold's crossNixos terminal — `igloo = result.nixosConfigurations.igloo.config`).
{
  denHoagFlakeModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit denHoagFlakeModule nixpkgs nixpkgsLib;
    flakeParts = genInputs.flake-parts;
  };
in
{
  flake.tests.den-os-class-host = {

    # Host aspect sets os.networking.hostName — should forward to nixos.
    test-host-os-forwards-to-nixos = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo = {
          os.networking.hostName = "from-os-class";
        };

        expr = igloo.networking.hostName;
        expected = "from-os-class";
      }
    );

    # os with module-system function (Tier 3 style).
    test-host-os-module-function = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo = {
          os =
            { lib, ... }:
            {
              environment.variables.OS_CLASS = "works";
            };
        };

        expr = igloo.environment.variables.OS_CLASS;
        expected = "works";
      }
    );

  };
}
