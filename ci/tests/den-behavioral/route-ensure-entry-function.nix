# den v1 BEHAVIORAL migration — deadbugs/route-ensure-entry-function.nix (denful/den templates/ci/modules/
# deadbugs/route-ensure-entry-function.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertion are BYTE-IDENTICAL to v1. Concern: `route` (a route
# with `adaptArgs`+`path` and no source modules — the `ensureEntry` placeholder must be an attrset, not a
# function).
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
  flake.tests.den-route = {
    # BLOCKED-WSB (surface-shape mismatch, throw): `function 'route' called with unexpected argument
    # 'collectSubtree'` — den-hoag's `route` sugar (lib/compat/deliver.nix:87) takes `collectSubtree`
    # only nested under `__extra = { collectSubtree = …; }` (its own comment: "route-internal mechanism
    # fields — collectSubtree/adapterKey/appendToParent"), not as v1's bare top-level kwarg; AND even via
    # `__extra` the field only "rides through inert — their consumers are the legacy `forwards` module
    # (Task 5)", so the underlying `collectSubtree` behavior this deadbug exercises is unimplemented
    # either way. Left in place, commented, per the parking rule (never altered to route around the gap).
    # test-empty-route-not-function-regression-route-ensure-entry-function = denTest (
    #   { den, igloo, ... }:
    #   let
    #     inherit (den.lib) policy;
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.classes.custom = { };
    #
    #     den.policies.route-custom = _: [
    #       (policy.route {
    #         fromClass = "custom";
    #         intoClass = "nixos";
    #         collectSubtree = true;
    #         path = [ "services" ];
    #         adaptArgs = _: { };
    #       })
    #     ];
    #
    #     den.schema.host.includes = [
    #       den.policies.route-custom
    #     ];
    #
    #     # No aspects emit into the custom class, so ensureEntry fires.
    #     # The route should produce an empty attrset at the path, not a function.
    #     expr = builtins.isAttrs igloo.services;
    #     expected = true;
    #   }
    # );
  };
}
