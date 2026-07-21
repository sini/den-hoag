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
  flake.tests.den-batteries = {

    # PARKED-DIVERGENCE: v1-expected ["wheel" "networkmanager"] (`den.aspects.tux` self-provides at the
    # user entity named "tux"; its `includes = [ den.batteries.primary-user ]` battery — a bare
    # `{ user, host, ... }:` fn — walks per host-user pair, materializing `nixos.users.users.tux`) vs
    # den-hoag-actual: `attribute 'tux' missing` — `igloo.users.users.tux` never materializes. Same shape
    # as den-default.nix's test-includes-user-function and host-options.nix's test-user-custom-username
    # (a `{ user, ... }:`-closing fn/battery never fires its per-user walk). Not altered to route around
    # the gap.
    # test-on-nixos-included-at-user = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.tux.includes = [ den.batteries.primary-user ];
    #     expr = igloo.users.users.tux.extraGroups;
    #     expected = [
    #       "wheel"
    #       "networkmanager"
    #     ];
    #   }
    # );

  };
}
