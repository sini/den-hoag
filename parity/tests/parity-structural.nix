# P1 — the structural oracle. Render each cross-arm fixture through BOTH arms, diff with
# `assertEdgeParity`, and pin the result against the first-corpus golden (parity/golden/traces.nix).
#
# ADJUDICATION (the plan's P1 item + "a divergence enters the ledger, never papered over"): den-hoag's
# containment-based §B4a delivery does NOT byte-equal v1's ancestor-chain delivery at C7 — the two arms
# fold DIFFERENT things as edges (v1: class content; den-hoag: quirk channels + demand + the explicit
# deliver surface). So every cross-arm diff here is non-empty, and the golden is the CLASSIFIED boundary,
# not `parity == true`. This suite's teeth: any REGRESSION that shifts a rendered edge — a normalization
# break, an id-hash leak, a new/absent fold edge — moves a golden list and fails. When the
# deliver-materialization completion (#44) + the default-fold reconciliation land, the goldens shrink
# toward parity (re-classified in parity/ledger.md), and this suite tracks that convergence.
{ harness, ... }:
let
  inherit (harness)
    schema
    traceHoag
    traceV1
    fixtures
    golden
    ;
  keys = t: map (e: e.__sortKey) t;

  # One full v1 + hoag evaluation per fixture (bound once — the `let` thunk is forced a single time
  # across every test below).
  resultOf =
    fx:
    let
      tV1 = traceV1 fx;
      tHoag = traceHoag fx;
      p = schema.assertEdgeParity {
        expected = tV1;
        actual = tHoag;
      };
    in
    {
      v1 = keys tV1;
      hoag = keys tHoag;
      matched = schema.keysOf p.matched;
      missing = schema.keysOf p.missingFromActual;
      extra = schema.keysOf p.extraInActual;
      inherit (p) parity;
    };
  goldenDiff = g: {
    inherit (g)
      v1
      hoag
      matched
      missing
      extra
      ;
  };
  diffOnly = r: {
    inherit (r)
      v1
      hoag
      matched
      missing
      extra
      ;
  };

  results = {
    plainHostUser = resultOf fixtures.plainHostUser;
    quirkChannel = resultOf fixtures.quirkChannel;
    multiHost = resultOf fixtures.multiHost;
  };
in
{
  flake.tests.parity-structural = {
    # Each fixture's full cross-arm diff (both arms' rendered key lists + the matched/missing/extra
    # partition) equals its checked-in golden.
    test-plain-host-user = {
      expr = diffOnly results.plainHostUser;
      expected = goldenDiff golden.plainHostUser;
    };
    test-quirk-channel = {
      expr = diffOnly results.quirkChannel;
      expected = goldenDiff golden.quirkChannel;
    };
    test-multi-host = {
      expr = diffOnly results.multiHost;
      expected = goldenDiff golden.multiHost;
    };

    # The recorded boundary itself: the class-fold vs quirk-fold domains are disjoint at C7, so parity is
    # false on every cross-arm fixture. A change that flips any of these to true is a real convergence
    # event — re-classify the golden + ledger, do not silently accept it.
    test-boundary-parity-false = {
      expr = [
        results.plainHostUser.parity
        results.quirkChannel.parity
        results.multiHost.parity
      ];
      expected = [
        false
        false
        false
      ];
    };

    # The quirk fixture is the sharpest disjoint-domain witness: hoag renders a `collected:host/feat` edge
    # that v1 has NO counterpart for (v1 consumes quirk content into class folds), so it appears as an
    # `extra` on the hoag arm — divergence in the OTHER direction from the missing class folds.
    test-quirk-extra-is-feat-channel = {
      expr = results.quirkChannel.extra;
      expected = [ "root:host:igloo/feat |  | collected:host:igloo/feat | merge" ];
    };
  };
}
