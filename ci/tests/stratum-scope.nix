# The STRATUM-SCOPE suite (§2.3 capability-scope arithmetic). `lib/stratum-scope.nix` extracts the stratum-
# ceiling machinery that used to live INLINE in `mkDerived`, parameterized by an ADMITTANCE PREDICATE rather
# than a fixed operator: `edgesWithin` is the silent edge filter (= the old `scopedEdges`), `gateWithin` the
# loud throwing projection (= the old `gatedRel`), and `indexOf`/`strataLt`/`strataLe` are the position
# primitives the def-time derive guards read.
#
# The two admittance predicates are Apt, Blair & Walker (1988), "Stratified Programs", Definition 3, p. 96:
# condition 1 admits a POSITIVE occurrence's definition within `⋃_{j ≤ i}`, condition 2 a NEGATIVE one's
# within `⋃_{j < i}`. The shipped runtime instantiations (`positiveEdges`/`positiveGate`) take condition 1,
# because polarity is not observable at a runtime read. `negativeGate` is exercised here as the DISCRIMINATION
# CONTROL: it shares every line with `positiveGate` except the predicate and must answer the OPPOSITE on the
# same-stratum kind — without it, a `positiveGate` that admitted everything would look identical.
#
# This suite tests the module DIRECTLY over synthetic strata/kinds/edges — the extraction's own witnesses,
# beside the behavior-level `derived`/`acl` suites that pin byte-identity through the consumers.
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
  within = ss.positiveEdges { inherit strataOrder relationKinds relationEdges; };
  kindsOf = edges: builtins.sort builtins.lessThan (map (e: e.kind) edges);

  gate = ss.positiveGate { inherit strataOrder relationKinds; };
  # the discrimination control: same construction, ABW condition 2 instead of condition 1.
  negGate = ss.negativeGate { inherit strataOrder relationKinds; };
  at =
    ceilingIdx: g:
    (g {
      name = "d";
      stratum = "s2";
      inherit ceilingIdx;
    } relRecord);
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
    # strictly below — a stratum is NOT below itself. `strataLt` is ABW condition 2 and stays the `negates`
    # guard's predicate, so this assertion pins the NEGATIVE rule and is unaffected by the positive read rule.
    test-strata-lt-equal = {
      expr = ss.strataLt strataOrder "s2" "s2";
      expected = false;
    };
    # `strataLe` beside `strataLt` on identical inputs — ABW condition 1. It agrees with `strataLt` on the
    # strict cases and differs on EXACTLY the equal one, which is what says it is a new predicate and not a
    # rename of the old one.
    test-strata-le-below = {
      expr = ss.strataLe strataOrder "s1" "s2";
      expected = true;
    };
    test-strata-le-above = {
      expr = ss.strataLe strataOrder "s2" "s1";
      expected = false;
    };
    test-strata-le-equal = {
      expr = ss.strataLe strataOrder "s2" "s2";
      expected = true;
    };

    # ── positiveEdges (the silent ABW-condition-1 filter) ──
    # ceiling = idx(s2) = 2 admits the strata AT OR BELOW s2: relA @ s1 + its swapped invA (also relA @ s1),
    # AND relB @ s2 (the same-stratum positive read condition 1 permits). The unknown `bogus` label is still
    # excluded — an edge whose relation cannot be identified has no stratum to compare, under EVERY admittance.
    test-edges-within-s2 = {
      expr = kindsOf (within 2);
      expected = [
        "invA"
        "relA"
        "relB"
      ];
    };
    # ceiling = idx(s1) = 1: relA/invA sit AT s1 and are ADMITTED (same-stratum). This is the assertion the
    # positive-read rule inverts — it pinned `[ ]` under the old strictly-below filter.
    test-edges-within-s1-same-stratum = {
      expr = kindsOf (within 1);
      expected = [
        "invA"
        "relA"
      ];
    };
    # THE PAIRED CONTROL for the assertion above: at that SAME ceiling, relB @ s2 is STRICTLY ABOVE and stays
    # excluded. Without this, re-pinning the same-stratum case would be indistinguishable from a filter that
    # admits everything.
    test-edges-within-s1-excludes-above = {
      expr = builtins.elem "relB" (kindsOf (within 1));
      expected = false;
    };
    # a ceiling BELOW every relation admits nothing — the filter is non-vacuous in the other direction too.
    test-edges-within-structural-empty = {
      expr = within 0;
      expected = [ ];
    };
    # ceiling above the top admits every KNOWN-label edge (relA/relB/invA), still dropping the unknown label.
    test-edges-within-top = {
      expr = kindsOf (within 3);
      expected = [
        "invA"
        "relA"
        "relB"
      ];
    };

    # ── positiveGate (the loud ABW-condition-1 throwing projection) ──
    # at ceilingIdx = idx(s1) = 1: reading relB (@ s2, STRICTLY ABOVE the ceiling) THROWS. This is the
    # violation condition 1 still rejects, and it is what keeps the relaxation from being a deletion.
    test-gate-blocks-above-ceiling = {
      expr = throws (at 1 gate).relB;
      expected = true;
    };
    # THE PAIRED ADMISSION for the assertion above: at ceilingIdx = idx(s2) = 2 the SAME relB read is at the
    # reader's OWN stratum and PASSES — the same-stratum positive read condition 1 permits. This assertion is
    # the one the positive-read rule inverts; it pinned a throw under the old `>= ceilingIdx` gate.
    test-gate-passes-at-ceiling = {
      expr = (at 2 gate).relB;
      expected = "B";
    };
    test-gate-passes-below-ceiling = {
      expr = (at 2 gate).relA;
      expected = "A";
    };
    # at a higher ceiling (idx(s3) = 3) the SAME relB read passes — the gate discriminates BY stratum, never
    # always-throws (the non-vacuity the derived stratum-gate rests on).
    test-gate-passes-at-higher-ceiling = {
      expr = (at 3 gate).relB;
      expected = "B";
    };

    # ── negativeGate: THE DISCRIMINATION CONTROL (ABW condition 2, same construction) ──
    # On the SAME same-stratum input `positiveGate` admits above, `negativeGate` THROWS. The two gates share
    # every line except the admittance predicate, so this is what proves `positiveGate` implements condition 1
    # rather than admitting unconditionally.
    test-neg-gate-blocks-at-ceiling = {
      expr = throws (at 2 negGate).relB;
      expected = true;
    };
    # …and `negativeGate` still admits a STRICTLY BELOW kind, so it is not an always-throw either.
    test-neg-gate-passes-below-ceiling = {
      expr = (at 2 negGate).relA;
      expected = "A";
    };
  };
}
