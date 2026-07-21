# The PER-PRODUCTION STRATA suite (§5/§7, L2). Each declared relation desugars to its OWN stratum
# `rel:<name>` — NOT the shipped constant `resolution`. §5 makes relations EDB (extensional base facts,
# BOTTOM-PINNED), so a relation is inserted `after = "structural"`: distinct per-relation strata sitting
# STRICTLY BELOW the `resolution` checkpoint (and thus below the derives, IDB, that read them). This gives
# the schedule + the derive-read ceiling a real inter-relation strictly-below order to enforce: a derive
# whose `over` reads a relation NOT strictly-below its own stratum is rejected NAMED at registration (the
# derivedFieldMessage `notLater` rung, §2.3). See REFERENCE.md §5.
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

  # a WELL-ORDERED derive at `resolution` (idx strictly above both rel:alpha, rel:beta) reading BOTH — the
  # strictly-below positive read (§2.3): the derive sits at the all-relations-resolved checkpoint above the
  # EDB relations. Registration is clean.
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

  # a CROSS-STRATUM derive at `rel:alpha` reading `beta` (at rel:beta, a SIBLING ABOVE rel:alpha) — NOT
  # strictly-below, so registration rejects NAMED (the `notLater` rung fires when forced).
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
  matchesNotLater = deriv: builtins.match ".*is not LATER than.*" (msgOf deriv) != null;
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
    # a derive reading a relation NOT strictly-below its own stratum → registration rejects when forced.
    test-cross-stratum-read-throws = {
      expr = throws (builtins.deepSeq crossFleet.den.derived true);
      expected = true;
    };
    # …and the reject is the NAMED `notLater` message (§2.3), not a raw eval crash.
    test-cross-stratum-read-named = {
      expr = matchesNotLater {
        over = [ "beta" ];
        direction = "forward";
        stratum = "rel:alpha";
        derive = node: _: null;
      };
      expected = true;
    };
  };
}
