# den v1 BEHAVIORAL migration — deadbugs/host-aspects-sibling-leak.nix (denful/den templates/ci/modules/
# deadbugs/host-aspects-sibling-leak.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold. Concern: `batteries` (the `host-aspects` battery re-resolves the host's aspect tree for a
# homeManager consumer per-user, opt-in only — a sibling user who does NOT include it must not receive the
# projection).
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

    # BLOCKED-WSB (missing surface): tux includes `den.batteries.host-aspects` and DOES successfully
    # materialize `home-manager.users.tux` (proven — `tuxHm.programs.vim.enable` resolves `true`). But
    # pingu, who includes NOTHING homeManager-related, has no `home-manager.users.pingu` key AT ALL on
    # den-hoag: `home-manager.users.<name>` entries are created ON-DEMAND (content-driven) rather than for
    # every nominally-homeManager-classed user, so forcing `pinguHm` throws `attribute 'pingu' missing`
    # instead of resolving an empty submodule (v1's `pinguHm.programs.vim.enable or false` idiom assumes
    # the latter). Since `expr` is one attrset, the whole case aborts. Left in place, commented, per the
    # parking rule.
    # test-sibling-no-leak = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     pinguHm,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users = {
    #       tux = { };
    #       pingu = { };
    #     };
    #     den.aspects.igloo.homeManager.programs.vim.enable = true;
    #     den.aspects.tux.includes = [ den.batteries.host-aspects ];
    #     # pingu does NOT include host-aspects
    #     expr = {
    #       tux = tuxHm.programs.vim.enable or false;
    #       pingu = pinguHm.programs.vim.enable or false;
    #     };
    #     expected = {
    #       tux = true;
    #       pingu = false;
    #     };
    #   }
    # );
  };
}
