# den v1 BEHAVIORAL migration — public-api/primary-user.nix (denful/den templates/ci/modules/public-api/
# primary-user.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertion are BYTE-IDENTICAL to v1 EXCEPT the R-rewrite below. Concern:
# `batteries` (the primary-user battery: wheel + networkmanager groups on NixOS).
#
# R-REWRITE (mechanical, per migration rule 3): v1 `den.provides.primary-user` → `den.batteries.primary-user`
# — den-hoag exposes ported battery content at `config.den.batteries.<name>` only
# (lib/compat/batteries.nix `config.den.batteries = { primary-user = primaryUser; ... }`).
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
  flake.tests.den-batteries = {

    # A user self-aspect `den.aspects.tux` (at the user entity "tux") includes the `{ user, host, ... }:`
    # primary-user battery, which emits `nixos.users.users.tux.extraGroups` — the cell's nixos content folds
    # up its containment subtree to the host's assembly (a host-parented user cell carries both coords).
    test-on-nixos-included-at-user = denTest (
      {
        den,
        lib,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.tux.includes = [ den.batteries.primary-user ];
        expr = igloo.users.users.tux.extraGroups;
        expected = [
          "wheel"
          "networkmanager"
        ];
      }
    );

  };
}
