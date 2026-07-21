# The STRATUM-SCOPE suite (§2.3 capability-scope arithmetic). `lib/stratum-scope.nix` extracts the stratum-
# ceiling machinery that used to live INLINE in `mkDerived`: `edgesBelowStratum` (the silent `< ceiling` edge
# filter, = the old `scopedEdges`), `ceilingGate` (the loud `>= ceilingIdx` throwing projection, = the old
# `gatedRel`), and the `indexOf`/`strataLt` position primitives the def-time derive guard reads. This suite
# tests the module DIRECTLY over synthetic strata/kinds/edges — the extraction's own witnesses, beside the
# behavior-level `derived`/`acl` suites that pin byte-identity through the consumers.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  ss = denHoag.internal.strataScope;

  # synthetic fleet: three strata after `structural`; relA sits at s1 (inverse invA), relB at s2 (no inverse).
  strataOrder = [
    "structural"
    "s1"
    "s2"
    "s3"
  ];
  relationKinds = {
    relA = {
      inverse = "invA";
      stratum = "s1";
    };
    relB = {
      inverse = null;
      stratum = "s2";
    };
  };
  # a forward relA edge, a forward relB edge, a SWAPPED invA edge (kind = the inverse LABEL, NOT a relationKinds
  # key — the total-stratum index must resolve it to relA), and an UNKNOWN-label edge (excluded silently).
  relationEdges = [
    {
      kind = "relA";
      from = "a";
      to = "b";
    }
    {
      kind = "relB";
      from = "b";
      to = "c";
    }
    {
      kind = "invA";
      from = "b";
      to = "a";
    }
    {
      kind = "bogus";
      from = "x";
      to = "y";
    }
  ];
  below = ss.edgesBelowStratum { inherit strataOrder relationKinds relationEdges; };
  kindsOf = edges: builtins.sort builtins.lessThan (map (e: e.kind) edges);

  gate = ss.ceilingGate { inherit strataOrder relationKinds; };
  relRecord = {
    relA = "A";
    relB = "B";
  };
in
{
  flake.tests.stratum-scope = {
    # ── indexOf / strataLt (the def-time position primitives) ──
    test-index-of-present = {
      expr = ss.indexOf strataOrder "s2";
      expected = 2;
    };
    test-index-of-absent = {
      expr = ss.indexOf strataOrder "nope";
      expected = -1;
    };
    test-strata-lt-below = {
      expr = ss.strataLt strataOrder "s1" "s2";
      expected = true;
    };
    test-strata-lt-above = {
      expr = ss.strataLt strataOrder "s2" "s1";
      expected = false;
    };
    # strictly below — a stratum is NOT below itself (the `<`, not `<=`, the §2.3 gate rests on).
    test-strata-lt-equal = {
      expr = ss.strataLt strataOrder "s2" "s2";
      expected = false;
    };

    # ── edgesBelowStratum (the silent `< ceiling` filter) ──
    # ceiling = idx(s2) = 2 admits exactly the strata BELOW s2: relA @ s1 + its swapped invA (also relA @ s1);
    # relB @ s2 is NOT strictly below (excluded), and the unknown `bogus` label is excluded (null stratum).
    test-edges-below-s2 = {
      expr = kindsOf (below 2);
      expected = [
        "invA"
        "relA"
      ];
    };
    # ceiling = idx(s1) = 1 admits nothing (relA/invA sit AT s1, relB above) — the `<` is strict.
    test-edges-below-s1-empty = {
      expr = below 1;
      expected = [ ];
    };
    # ceiling above the top admits every KNOWN-label edge (relA/relB/invA), still dropping the unknown label.
    test-edges-below-top = {
      expr = kindsOf (below 3);
      expected = [
        "invA"
        "relA"
        "relB"
      ];
    };

    # ── ceilingGate (the loud `>= ceilingIdx` throwing projection) ──
    # at ceilingIdx = idx(s2) = 2: reading relB (@ s2, ≥ ceiling) THROWS; relA (@ s1, < ceiling) passes through.
    test-gate-blocks-at-ceiling = {
      expr =
        throws
          (gate {
            name = "d";
            stratum = "s2";
            ceilingIdx = 2;
          } relRecord).relB;
      expected = true;
    };
    test-gate-passes-below-ceiling = {
      expr =
        (gate {
          name = "d";
          stratum = "s2";
          ceilingIdx = 2;
        } relRecord).relA;
      expected = "A";
    };
    # at a higher ceiling (idx(s3) = 3) the SAME relB read passes — the gate discriminates BY stratum, never
    # always-throws (the non-vacuity the derived stratum-gate rests on).
    test-gate-passes-at-higher-ceiling = {
      expr =
        (gate {
          name = "d";
          stratum = "s3";
          ceilingIdx = 3;
        } relRecord).relB;
      expected = "B";
    };
  };
}
