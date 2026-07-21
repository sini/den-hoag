# den v1 BEHAVIORAL migration — deadbugs/hm-host-forward-hm-class.nix (denful/den templates/ci/modules/
# deadbugs/hm-host-forward-hm-class.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold. Concern: `delivery` (a `schema.hm-host` include's `homeManager`/`nixos` class keys must route
# to the host + its users).
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
  flake.tests.den-delivery = {

    # BLOCKED-WSB (missing surface, self-documented by den-hoag's OWN compat comment): `den.schema.hm-host`
    # is a v1 schema KIND (modules/aspects/batteries/home-manager.nix `schemaIncludes = config.den.schema.
    # hm-host.includes or [ ]`). den-hoag's `lib/compat/legacy/batteries/home-manager.nix` (its own header
    # comment, ~line 56-58) states: "the corpus only READS hm-host.includes … and never WRITES it —
    # corpus-zero, not ported (the hm-host KIND registration itself is builtins.nix's)". Empirically
    # confirmed: `den.schema.hm-host.includes = […]` content reaches NEITHER the host's nixos class
    # (`igloo.services.openssh.enable` resolves `false`, not `true` — a value mismatch, not a throw) NOR
    # any user's homeManager class (`tuxHm`/`igloo.home-manager.users.tux` throws `attribute 'tux'
    # missing`). Left in place, commented, per the parking rule.

    # test-hm-host-forwards-homemanager-class = denTest (
    #   {
    #     den,
    #     igloo,
    #     tuxHm,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.schema.hm-host.includes = [
    #       {
    #         nixos.services.openssh.enable = true;
    #         homeManager.programs.vim.enable = true;
    #       }
    #     ];
    #
    #     expr = {
    #       ssh = igloo.services.openssh.enable;
    #       vim = tuxHm.programs.vim.enable;
    #     };
    #     expected = {
    #       ssh = true;
    #       vim = true;
    #     };
    #   }
    # );
    #
    # test-hm-host-forwards-hm-to-all-users = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.igloo.users.pingu = { };
    #
    #     den.schema.hm-host.includes = [
    #       { homeManager.programs.vim.enable = true; }
    #     ];
    #
    #     expr = {
    #       tux = igloo.home-manager.users.tux.programs.vim.enable;
    #       pingu = igloo.home-manager.users.pingu.programs.vim.enable;
    #     };
    #     expected = {
    #       tux = true;
    #       pingu = true;
    #     };
    #   }
    # );

  };
}
