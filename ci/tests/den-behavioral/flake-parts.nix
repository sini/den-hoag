# den v1 BEHAVIORAL migration — public-api/flake-parts.nix (denful/den templates/ci/modules/public-api/
# flake-parts.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `batteries` (the `inputs'`/`self'` flake-parts perSystem-binding batteries).
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

    # BLOCKED-WSB (missing-surface): `den.batteries."inputs'"`/`"self'"` inject `_module.args.inputs'` /
    # `_module.args.self'` into the target class body via `withSystem` (batteries.nix `mkAspect`). On the
    # scaffold's crossed NixOS system that `_module.args` definition never reaches the class module's own
    # arg resolution — empirically confirmed: forcing a class body destructuring `{ inputs', ... }` (resp.
    # `self'`) throws `attribute 'inputs'' missing` (resp. `'self''`) at the crossed nixos module's own
    # `_module.args.${name}` lookup (nixpkgs modules.nix — the arg was never externally provided nor present
    # in `config._module.args`). Left in place, commented, per the parking rule.

    # test-flake-parts-inputs-prime = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.default.homeManager.home.stateVersion = "25.11";
    #
    #     den.default.includes = [ den.batteries."inputs'" ];
    #     den.aspects.igloo.nixos =
    #       { inputs', ... }:
    #       {
    #         environment.systemPackages = [ inputs'.nixpkgs.legacyPackages.hello ];
    #       };
    #
    #     expr = builtins.elem "hello" (map lib.getName igloo.environment.systemPackages);
    #     expected = true;
    #   }
    # );
    #
    # test-flake-parts-self-prime = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.default.homeManager.home.stateVersion = "25.11";
    #
    #     den.default.includes = [ den.batteries."self'" ];
    #     den.aspects.igloo.nixos =
    #       { self', ... }:
    #       {
    #         environment.systemPackages = [ self'.packages.hello ];
    #       };
    #
    #     expr = builtins.elem "hello" (map lib.getName igloo.environment.systemPackages);
    #     expected = true;
    #   }
    # );

  };
}
