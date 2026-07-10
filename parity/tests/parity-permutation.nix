# P3 — permutation regression (the fold's declaration-order-independence, end-to-end through the shim).
#
# TRACE HALF (unconditional): permuting the declaration order of a fleet's contributions leaves the rendered
# `T | P | S | M` sort-key list byte-identical on EVERY fixture — gen-edge Law 2 (commutativity of
# incomparable edges) + den-hoag §2.5's producer-identity tie-break, exercised through the whole shim path
# (v1-surface eval → compile → den-hoag fold). CONTENT HALF (conditional): where contribution order on
# ordered-list channels is fully pinned independent of declaration order, the per-root materialized output
# hashes identically too. A fixture whose v1 EFFECTIVE same-position order differs from den-hoag's
# producer-identity order (Open Question 6) is content-EXCLUDED (`contentStable = false`) and recorded —
# never silently skipped.
{
  harness,
  ...
}:
let
  # The same fleet with its `den.schema.host.includes` list in a GIVEN order — the permuted axis. Three
  # aspects (a, b, c) are included at every host; the order they appear in the includes list is the
  # declaration order whose independence P3 asserts. (den v1's `den.schema` is a single-value surface, so
  # the order is carried in ONE module's list, not split across modules — splitting would conflict-merge.)
  fleet = includesOrder: {
    den.hosts.x86_64-linux.igloo.users.tux = { };
    den.quirks.feat = { };
    den.aspects.a.nixos.services.a.enable = true;
    den.aspects.b.nixos.services.b.enable = true;
    den.aspects.c.feat = [ "c" ];
    den.schema.host.includes = includesOrder;
  };

  # Three DISTINCT include orders of the same fleet (a→b→c, c→b→a, mixed). Content is order-STABLE here: the
  # three aspects touch disjoint paths (services.a, services.b, the `feat` channel), so no ordered-list
  # channel has multiple same-position producers (Open Question 6 does not bite).
  base = [
    (fleet [
      { name = "a"; }
      { name = "b"; }
      { name = "c"; }
    ])
  ];
  rev = [
    (fleet [
      { name = "c"; }
      { name = "b"; }
      { name = "a"; }
    ])
  ];
  mix = [
    (fleet [
      { name = "b"; }
      { name = "c"; }
      { name = "a"; }
    ])
  ];

  result = harness.permutationGate {
    permutations = [
      base
      rev
      mix
    ];
    contentStable = true;
  };
in
{
  flake.tests.parity-permutation = {
    # three permutations were compared (the gate is not vacuous).
    test-permutation-count = {
      expr = result.count;
      expected = 3;
    };
    # TRACE HALF (unconditional): every declaration order renders a byte-identical trace.
    test-trace-order-independent = {
      expr = result.allTraceEqual;
      expected = true;
    };
    # CONTENT HALF (precondition holds here — disjoint paths): every order materializes byte-identical content.
    test-content-order-independent = {
      expr = result.allContentEqual;
      expected = true;
    };
    # the content half ran (contentStable = true was honored, not silently skipped).
    test-content-half-ran = {
      expr = result.contentStable && result.allContentEqual != null;
      expected = true;
    };
  };
}
