# P5 — the `firstDivergent` triage. Inject a KNOWN single-edge mutation into one arm's trace and assert
# the harness names exactly it: the least element of the symmetric difference under the total sort-key
# order, with correct arm attribution (`onlyIn`) and the bracketing matched neighbours (`precededBy` /
# `followedBy`). Two mutations — a DROP (edge unique to `expected`/v1) and an ADD (edge unique to
# `actual`/hoag) — cover both attribution directions.
# `lib` is nixpkgs lib, injected by the gen `mkCi` scaffold (the nix-unit test runner supplies it to every
# test module); used here only for `lib.sublist` to build the drop-mutation.
{ harness, lib, ... }:
let
  inherit (harness) schema traceV1 fixtures;
  # A real, non-empty, stably-sorted trace to mutate (6 edges).
  base = traceV1 fixtures.plainHostUser;
  keyAt = i: (builtins.elemAt base i).__sortKey;

  # DROP the 3rd edge (index 2). It becomes the ONLY symmetric-difference element, hence firstDivergent;
  # it is unique to `expected` (v1), bracketed by its sorted neighbours (indices 1 and 3).
  dropped = lib.sublist 0 2 base ++ lib.sublist 3 (builtins.length base - 3) base;
  pDrop = schema.assertEdgeParity {
    expected = base;
    actual = dropped;
  };

  # ADD a synthetic edge whose key sorts BEFORE every real key ("a…" < "collected…"/"root…"), unique to
  # `actual` (tagged hoag). It is the least symmetric-difference element → firstDivergent, with no
  # predecessor and the smallest real key as successor.
  injected = {
    __sortKey = "aaaa:injected-least |  | value:_ | merge";
    entry = {
      synthetic = true;
    };
    arm = "hoag";
  };
  pAdd = schema.assertEdgeParity {
    expected = base;
    actual = [ injected ] ++ base;
  };
in
{
  flake.tests.parity-first-divergent = {
    # sanity: the base trace is non-empty and sorted, so the mutations are well-defined.
    test-base-nonempty = {
      expr = builtins.length base >= 4;
      expected = true;
    };

    # ── DROP mutation: firstDivergent names the dropped edge, attributed to v1, bracketed correctly ──
    test-drop-firstDivergent = {
      expr = {
        key = pDrop.firstDivergent.key;
        onlyIn = pDrop.firstDivergent.onlyIn;
        precededBy = pDrop.firstDivergent.precededBy;
        followedBy = pDrop.firstDivergent.followedBy;
      };
      expected = {
        key = keyAt 2;
        onlyIn = "v1";
        precededBy = keyAt 1;
        followedBy = keyAt 3;
      };
    };
    test-drop-not-parity = {
      expr = pDrop.parity;
      expected = false;
    };
    test-drop-single-missing = {
      expr = builtins.length pDrop.missingFromActual;
      expected = 1;
    };

    # ── ADD mutation: firstDivergent names the injected edge, attributed to hoag, no predecessor ──
    test-add-firstDivergent = {
      expr = {
        key = pAdd.firstDivergent.key;
        onlyIn = pAdd.firstDivergent.onlyIn;
        precededBy = pAdd.firstDivergent.precededBy;
        followedBy = pAdd.firstDivergent.followedBy;
      };
      expected = {
        key = "aaaa:injected-least |  | value:_ | merge";
        onlyIn = "hoag";
        precededBy = null;
        followedBy = keyAt 0;
      };
    };
    test-add-single-extra = {
      expr = builtins.length pAdd.extraInActual;
      expected = 1;
    };

    # identity: no mutation → firstDivergent is null.
    test-identity-null-firstDivergent = {
      expr =
        (schema.assertEdgeParity {
          expected = base;
          actual = base;
        }).firstDivergent;
      expected = null;
    };
  };
}
