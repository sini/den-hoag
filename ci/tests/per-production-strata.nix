# The PER-PRODUCTION STRATA suite (§5/§7, L2). Each declared relation desugars to its OWN stratum
# `rel:<name>` — NOT the shipped constant `resolution`. §5 makes relations EDB (extensional base facts,
# BOTTOM-PINNED), so a relation is inserted `after = "structural"`: distinct per-relation strata sitting
# STRICTLY BELOW the `resolution` checkpoint (and thus below the derives, IDB, that read them). This gives
# the schedule + the derive-read ceiling a real inter-relation order to enforce: a derive whose `over` reads
# a relation STRICTLY ABOVE its own stratum is rejected NAMED at registration (the derivedFieldMessage
# `overAbove` rung, §2.3). `over` is the DECLARED POSITIVE read set, so the rung applies Apt, Blair & Walker
# (1988), "Stratified Programs", Definition 3, p. 96, condition 1 — a positive occurrence has its definition
# within `⋃_{j ≤ i}`, so a SAME-stratum `over` is admitted and only an above-stratum one rejects.
# See REFERENCE.md §5.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a fleet: two relations `alpha`, `beta` (distinct per-relation strata rel:alpha < rel:beta, both BELOW
  # resolution), plus an optional derived registry.
  mkFleet =
    deriveds:
    denHoag.mkDen [
      (
        { ... }:
        {
          config.den.schema.node.parent = null;
          config.den.relations.alpha = { };
          config.den.relations.beta = { };
          config.den.derived = deriveds;
        }
      )
    ];

  baseFleet = mkFleet { };
  strata = baseFleet.den.strata;
  idxOf =
    x:
    let
      go =
        i: l:
        if l == [ ] then
          -1
        else if builtins.head l == x then
          i
        else
          go (i + 1) (builtins.tail l);
    in
    go 0 strata;

  # a WELL-ORDERED derive at `resolution` (idx strictly above both rel:alpha, rel:beta) reading BOTH — an
  # at-or-below positive read (§2.3, ABW Definition 3 condition 1): the derive sits at the all-relations-
  # resolved checkpoint above the EDB relations. Registration is clean.
  wellFleet = mkFleet {
    foo = {
      over = [
        "alpha"
        "beta"
      ];
      direction = "forward";
      stratum = "resolution";
      derive = node: _: null;
    };
  };

  # a CROSS-STRATUM derive at `rel:alpha` reading `beta` (at rel:beta, a SIBLING ABOVE rel:alpha) — the
  # relation sits ABOVE the reader, which condition 1 rejects, so registration rejects NAMED when forced.
  crossFleet = mkFleet {
    foo = {
      over = [ "beta" ];
      direction = "forward";
      stratum = "rel:alpha";
      derive = node: _: null;
    };
  };

  # the field validator called DIRECTLY (per-relation relationKinds + strata order), so the reject's message
  # TEXT is asserted in isolation — Nix's `tryEval` cannot capture a real throw's text (the derived.nix
  # `msgOf` posture). Mirrors the per-relation desugar: each relation at its own `rel:<name>` below resolution.
  msgOf =
    deriv:
    denHoag.internal.derived.derivedFieldMessage {
      deriveds.foo = deriv;
      relationKinds = {
        alpha = {
          inverse = null;
          stratum = "rel:alpha";
        };
        beta = {
          inverse = null;
          stratum = "rel:beta";
        };
      };
      strataOrder = [
        "structural"
        "rel:alpha"
        "rel:beta"
        "resolution"
      ];
      resolutionProductNames = [ ];
    };
  # the `over` guard's NAMED message. `over` is the DECLARED POSITIVE read set, so its law is Apt, Blair &
  # Walker (1988), "Stratified Programs", Definition 3, p. 96, condition 1: a derive BELOW its `over` relation
  # is the violation, and the message cites the condition it applied.
  matchesOverAbove =
    deriv:
    builtins.match ".*is BELOW the strata its .over. relations sit at.*condition 1.*" (msgOf deriv)
    != null;
in
{
  flake.tests.per-production-strata = {
    # each declared relation gets its OWN distinct stratum in the compiled order (not the shipped constant
    # "resolution"), and both sit STRICTLY BELOW the `resolution` checkpoint (§5 EDB, bottom-pinned).
    test-per-relation-distinct-strata = {
      expr = {
        hasAlpha = builtins.elem "rel:alpha" strata;
        hasBeta = builtins.elem "rel:beta" strata;
        distinct = (idxOf "rel:alpha") != (idxOf "rel:beta");
        belowResolution =
          (idxOf "rel:alpha") < (idxOf "resolution") && (idxOf "rel:beta") < (idxOf "resolution");
      };
      expected = {
        hasAlpha = true;
        hasBeta = true;
        distinct = true;
        belowResolution = true;
      };
    };
    # a well-ordered derive (stratum strictly-above every `over` relation) forces the registry clean.
    test-well-ordered-derive-green = {
      expr = throws (builtins.deepSeq wellFleet.den.derived true);
      expected = false;
    };
    # a derive reading a relation STRICTLY ABOVE its own stratum → registration rejects when forced.
    test-cross-stratum-read-throws = {
      expr = throws (builtins.deepSeq crossFleet.den.derived true);
      expected = true;
    };
    # …and the reject is the NAMED `over`-guard message (§2.3), not a raw eval crash. `beta` sits at
    # `rel:beta`, STRICTLY ABOVE the derive's own `rel:alpha`, which condition 1 rejects.
    test-cross-stratum-read-named = {
      expr = matchesOverAbove {
        over = [ "beta" ];
        direction = "forward";
        stratum = "rel:alpha";
        derive = node: _: null;
      };
      expected = true;
    };
  };
}
