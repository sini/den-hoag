# P7 — harness soundness. Generalises den v1's shipped `fx-edge-parity` suite:
#
#   IDENTITY GATE — a trace diffed against ITSELF is parity-equal with empty deltas AND non-empty matched
#     (the matched set proves the trace carries real content, so the gate is not vacuously green on an
#     empty trace). Run on BOTH arms: the v1 arm (plain host+user, 6 edges) and the hoag arm (the quirk
#     channel, 1 edge) — each non-empty.
#
#   NEGATIVE CONTROL — the standing proof that `assertEdgeParity` has TEETH: on a spawn topology, v1's
#     production `edgeTrace` vs its `legacyEdgeTrace` (the rewalk-arm undercount + suppressed twins)
#     MUST diverge (`parity == false`), with a non-empty matched set (they agree on the non-spawn edges)
#     and a non-null firstDivergent. Without this, the identity gate alone would pass on a helper that
#     always returned `parity == true`.
{ harness, ... }:
let
  inherit (harness)
    schema
    traceHoag
    traceV1
    traceV1Legacy
    fixtures
    golden
    ;

  identityGate =
    trace:
    let
      diff = schema.assertEdgeParity {
        expected = trace;
        actual = trace;
      };
    in
    {
      parity = diff.parity;
      matchedNonEmpty = diff.matched != [ ];
      noMissing = diff.missingFromActual == [ ];
      noExtra = diff.extraInActual == [ ];
    };
  identityExpected = {
    parity = true;
    matchedNonEmpty = true;
    noMissing = true;
    noExtra = true;
  };

  # The negative control: production vs legacy on the spawn topology (v1-internal — never the hoag arm).
  neg = schema.assertEdgeParity {
    expected = traceV1 fixtures.spawnNegControl;
    actual = traceV1Legacy fixtures.spawnNegControl;
  };
in
{
  flake.tests.parity-identity-negcontrol = {
    # ── identity gate, v1 arm (non-vacuous: 6 edges) ──
    test-identity-v1-plain = {
      expr = identityGate (traceV1 fixtures.plainHostUser);
      expected = identityExpected;
    };
    # ── identity gate, hoag arm (non-vacuous: the quirk-channel fold edge) ──
    test-identity-hoag-quirk = {
      expr = identityGate (traceHoag fixtures.quirkChannel);
      expected = identityExpected;
    };

    # ── negative control: the harness DETECTS the spawn-rewalk divergence ──
    test-negcontrol-diverges = {
      expr = neg.parity;
      expected = false;
    };
    # non-vacuous divergence: the two v1 traces still agree on the non-spawn edges (matched != []) and the
    # legacy undercount surfaces a concrete firstDivergent — not an all-or-nothing mismatch.
    test-negcontrol-matched-nonempty = {
      expr = neg.matched != [ ];
      expected = true;
    };
    test-negcontrol-first-divergent = {
      expr = neg.firstDivergent.key;
      expected = golden.spawnNeg.firstDivergent;
    };
    # the legacy trace genuinely UNDERCOUNTS (fewer edges than production) — the pinned spawn-arm shortfall.
    test-negcontrol-legacy-undercounts = {
      expr =
        builtins.length (traceV1Legacy fixtures.spawnNegControl)
        < builtins.length (traceV1 fixtures.spawnNegControl);
      expected = true;
    };
  };
}
