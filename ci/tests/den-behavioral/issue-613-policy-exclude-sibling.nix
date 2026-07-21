# den v1 BEHAVIORAL migration — deadbugs/issue-613-policy-exclude-sibling.nix (denful/den templates/ci/
# modules/deadbugs/issue-613-policy-exclude-sibling.nix). Migrated by copy + arg-rename onto the
# `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1.
# Concern: `include` (#613 analog for POLICY-NAME exclusion — dispatch-policies / policy-schema late
# filter).
#
# Sibling parity: one host excluding a POLICY must not suppress a sibling
# host that includes+fires it. Companion to issue-613-exclude-sibling-isolation
# (aspect-content excludes). Both flavors now route through scopedConstraintsFor
# (entity-scoped + schema-broadcast), so the fleet-wide leak is gone while
# schema-tier (den.schema.KIND.excludes) excludes still broadcast.
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
  flake.tests.den-include = {

    # iceberg excludes the policy, igloo includes it → igloo must still fire it.
    test-sibling-policy-exclude-does-not-suppress-includer-regression-613 = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.iceberg.users.tux = { };
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.policies.add-marker = _: [
          (den.lib.policy.include { nixos.environment.variables.MARKER = "yes"; })
        ];
        den.aspects.iceberg.excludes = [ den.policies.add-marker ];
        den.aspects.igloo.includes = [ den.policies.add-marker ];

        expr = igloo.environment.variables.MARKER or "absent";
        expected = "yes";
      }
    );

    # swapped: igloo excludes, iceberg includes → iceberg must still fire it.
    test-sibling-policy-exclude-does-not-suppress-includer-swapped-regression-613 = denTest (
      { den, iceberg, ... }:
      {
        den.hosts.x86_64-linux.iceberg.users.tux = { };
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.policies.add-marker = _: [
          (den.lib.policy.include { nixos.environment.variables.MARKER = "yes"; })
        ];
        den.aspects.iceberg.includes = [ den.policies.add-marker ];
        den.aspects.igloo.excludes = [ den.policies.add-marker ];

        expr = iceberg.environment.variables.MARKER or "absent";
        expected = "yes";
      }
    );
  };
}
