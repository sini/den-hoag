# den v1 BEHAVIORAL migration — public-api/unfree.nix (denful/den templates/ci/modules/public-api/
# unfree.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `batteries` (the `unfree` `__functor` parametric battery, on both nixos + homeManager targets).
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

    # BLOCKED-WSB (missing-surface, NEW finding — not one of the plan's B1-B10): v1's `den.batteries.unfree`
    # is a `${class}.unfree.packages` WRITER only; the actual `nixpkgs.config.allowUnfreePredicate` wiring
    # is a SEPARATE always-on seed module v1 ships alongside it (denful/den
    # modules/aspects/batteries/unfree/unfree-predicate-builder.nix — a `den.default.includes` aspect that
    # declares `options.unfree.packages` per-class and sets `nixpkgs.config.allowUnfreePredicate` from it).
    # den-hoag's `lib/compat/batteries.nix` ports the writer (`unfree`) but NOT the predicate-builder seed —
    # empirically confirmed: `igloo.nixpkgs.config.allowUnfreePredicate` throws `attribute
    # 'allowUnfreePredicate' missing` (the option is never declared), and the homeManager/user-class cases
    # additionally hit the `users.users.<u>` user-cell-fold gap (board #49, see primary-user.nix /
    # os-user-class.nix). Left in place, commented, per the parking rule.

    # test-unfree-packages-set-on-nixos = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.igloo.includes = [ (den.batteries.unfree [ "discord" ]) ];
    #     expr = igloo.nixpkgs.config.allowUnfreePredicate { pname = "discord"; };
    #     expected = true;
    #   }
    # );
    #
    # test-unfree-packages-set-on-home-manager = denTest (
    #   { den, tuxHm, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.default.homeManager.home.stateVersion = "25.11";
    #     den.aspects.tux.includes = [ (den.batteries.unfree [ "vscode" ]) ];
    #
    #     expr = tuxHm.nixpkgs.config.allowUnfreePredicate { pname = "vscode"; };
    #     expected = true;
    #   }
    # );
    #
    # BLOCKED: .user.* class-module forward — the assertion forces `igloo.users.users.tux`, but nothing in
    # this fleet projects the `den.hosts.<h>.users.<u>` declaration into a nixos `users.users.<u>` entry (the
    # os-user user→host route), so it is `attribute 'tux' missing`. That user→host `users.users.<u>`
    # projection is a SEPARATE rung (os-user-class family), NOT the `{ host, user }` ctx family this seed
    # delivers — the ctx family greens (primary-user's battery, which itself WRITES `users.users.tux`, lands).
    # test-unfree-user-class-works = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.tux.includes = [ (den.batteries.unfree [ "vscode" ]) ];
    #
    #     expr = !(igloo.users.users.tux ? unfree);
    #     expected = true;
    #   }
    # );

  };
}
