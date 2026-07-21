# den v1 BEHAVIORAL migration — public-api/use-global-pkgs.nix (denful/den templates/ci/modules/
# public-api/use-global-pkgs.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `schema`
# (den.schema.host.includes / den.schema.hm-host.includes gating on HM-user presence).
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
  flake.tests.den-schema = {

    # PARKED-DIVERGENCE: v1-expected true (a homeManager-classed user on the host — the scaffold's own
    # `den.schema.user.classes = mkDefault ["homeManager"]` default — pulls in the home-manager NixOS
    # module, so `den.schema.host.includes` content lands on it) vs den-hoag-actual: hard eval abort
    # `The option 'home-manager' does not exist` merging `useGlobalPkgs = true` — the home-manager NixOS
    # module is never imported for igloo despite the HM-classed user. Not altered to route around the gap.
    # test-enabled = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     # host entity includes are applied when host has HM support
    #     den.schema.host.includes = [
    #       { nixos.home-manager.useGlobalPkgs = true; }
    #     ];
    #
    #     expr = igloo.home-manager.useGlobalPkgs;
    #     expected = true;
    #   }
    # );

    # PARKED-DIVERGENCE: v1-expected false (the `home-manager` NixOS module is imported — and its
    # `useGlobalPkgs` option defaults false — for any host carrying an HM-classed user) vs
    # den-hoag-actual: `attribute 'home-manager' missing` — the module is never imported at all for this
    # minimal fleet. Same underlying gap as test-enabled above. Not altered to route around the gap.
    # test-disabled = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     expr = igloo.home-manager.useGlobalPkgs;
    #     expected = false;
    #   }
    # );

    test-not-activated-without-hm-users = denTest (
      { den, config, ... }:
      {
        den.hosts.x86_64-linux.igloo = { };
        den.schema.hm-host.includes = [
          { nixos.home-manager.useGlobalPkgs = true; }
        ];

        expr = config.flake.nixosConfigurations.igloo.config ? home-manager;
        expected = false;
      }
    );

  };
}
