# P4 — each arm's trace is a pure, stably-sorted function of the TOPOLOGY. Two checks per fixture:
#
#   (1) golden hash — the trace's normalized-key-list hash equals a checked-in golden (the stability pin;
#       gen-edge's `hashTrace` analogue over the frozen keys). A reordering, a dropped edge, or a
#       normalization change moves the hash.
#   (2) topology invariance — wrapping the fixture module in an inert `{ imports = [ … ]; }` (same
#       topology, different module TREE) yields a byte-equal trace. Because the trace is derived from the
#       edge SET (permutation-invariant, Laws E2/E4), module-structure noise cannot perturb it.
{ harness, ... }:
let
  inherit (harness)
    schema
    traceHoag
    traceV1
    fixtures
    golden
    ;
  hashKeys = t: builtins.hashString "sha256" (builtins.toJSON (schema.keysOf t));
  # Same topology, re-nested through an inert import — a genuine module-tree permutation.
  wrap =
    fx:
    fx
    // {
      module = {
        imports = [ fx.module ];
      };
    };
in
{
  flake.tests.parity-trace-stability = {
    # ── golden hashes (both arms, every cross-arm fixture) ──
    test-plain-v1-hash = {
      expr = hashKeys (traceV1 fixtures.plainHostUser);
      expected = golden.plainHostUser.v1Hash;
    };
    test-plain-hoag-hash = {
      expr = hashKeys (traceHoag fixtures.plainHostUser);
      expected = golden.plainHostUser.hoagHash;
    };
    test-quirk-v1-hash = {
      expr = hashKeys (traceV1 fixtures.quirkChannel);
      expected = golden.quirkChannel.v1Hash;
    };
    test-quirk-hoag-hash = {
      expr = hashKeys (traceHoag fixtures.quirkChannel);
      expected = golden.quirkChannel.hoagHash;
    };
    test-multi-v1-hash = {
      expr = hashKeys (traceV1 fixtures.multiHost);
      expected = golden.multiHost.v1Hash;
    };
    test-multi-hoag-hash = {
      expr = hashKeys (traceHoag fixtures.multiHost);
      expected = golden.multiHost.hoagHash;
    };

    # ── topology invariance: same topology, different module tree → byte-equal trace ──
    test-plain-hoag-topology-invariant = {
      expr = traceHoag fixtures.plainHostUser == traceHoag (wrap fixtures.plainHostUser);
      expected = true;
    };
    test-plain-v1-topology-invariant = {
      expr = traceV1 fixtures.plainHostUser == traceV1 (wrap fixtures.plainHostUser);
      expected = true;
    };
    test-quirk-hoag-topology-invariant = {
      expr = traceHoag fixtures.quirkChannel == traceHoag (wrap fixtures.quirkChannel);
      expected = true;
    };
  };
}
