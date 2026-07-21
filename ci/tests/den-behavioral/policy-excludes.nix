# den v1 BEHAVIORAL migration — public-api/policy-excludes.nix (denful/den templates/ci/modules/public-api/
# policy-excludes.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `policy` (`meta.excludes` on `den.lib.policy.include`; parent excludes are authoritative).
#
# ALL THREE cases empirically diverge/block on den-hoag; none currently executable. Left in place,
# commented, per the parking rule (never altered to route around the gap).
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
  flake.tests.den-policy = {

    # PARKED-DIVERGENCE (genuine den-hoag-vs-den value mismatch → owner gate): v1 expected "absent"
    # (excludes on `den.aspects.igloo.excludes = [ den.policies.add-marker ]` suppresses the SAME policy
    # reference in `includes`); den-hoag actual "yes" (the marker fires — the exclude does not suppress a
    # `den.policies.<name>` REFERENCE the way it suppresses an aspect reference). Evaluates cleanly to a
    # wrong final value (no throw), so this is a value divergence, not a missing-surface abort.
    # test-excluded-policy-does-not-fire = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.policies.add-marker = _: [
    #       (den.lib.policy.include {
    #         nixos.environment.variables.EXCLUDED_MARKER = "yes";
    #       })
    #     ];
    #     den.aspects.igloo = {
    #       includes = [ den.policies.add-marker ];
    #       excludes = [ den.policies.add-marker ];
    #     };
    #
    #     expr = igloo.environment.variables.EXCLUDED_MARKER or "absent";
    #     expected = "absent";
    #   }
    # );

    # BLOCKED-WSB (B5, per the plan's table — bare `resolve {}` with no target kind): `den.lib.policy.resolve
    # { myFlag = true; }` has no `__targetKind`. Empirically confirmed: `den-compat: resolve arm (R2): a bare
    # resolve { … } (no __targetKind) has no compat translation — the shim routes resolve.to "<kind>" { … }`.
    # test-non-excluded-policy-fires = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     tuxHm,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.policies.my-enrichment =
    #       { host, ... }:
    #       [
    #         (den.lib.policy.resolve {
    #           myFlag = true;
    #         })
    #       ];
    #     den.aspects.igloo = {
    #       policies.to-users =
    #         {
    #           host,
    #           user,
    #           myFlag ? false,
    #           ...
    #         }:
    #         lib.optional myFlag (
    #           den.lib.policy.include {
    #             homeManager.home.sessionVariables.ENRICHED = "yes";
    #           }
    #         );
    #       includes = [
    #         den.policies.my-enrichment
    #         den.aspects.igloo.policies.to-users
    #       ];
    #     };
    #
    #     expr = tuxHm.home.sessionVariables.ENRICHED or "no";
    #     expected = "yes";
    #   }
    # );

    # PARKED-DIVERGENCE: same excludes-vs-policy-reference root cause as test-excluded-policy-does-not-fire
    # above (v1 "absent" vs den-hoag actual "yes").
    # test-parent-excludes-authoritative = denTest (
    #   { den, igloo, ... }:
    #   let
    #     childAspect = {
    #       includes = [ den.policies.blocked-pol ];
    #     };
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.policies.blocked-pol = _: [
    #       (den.lib.policy.include {
    #         nixos.environment.variables.BLOCKED_MARKER = "yes";
    #       })
    #     ];
    #     den.aspects.igloo = {
    #       includes = [ childAspect ];
    #       excludes = [ den.policies.blocked-pol ];
    #     };
    #
    #     expr = igloo.environment.variables.BLOCKED_MARKER or "absent";
    #     expected = "absent";
    #   }
    # );

  };
}
