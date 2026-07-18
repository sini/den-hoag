# The DERIVED suite (§5 resolution facet). `den.derived.<name> = { over; direction; stratum; provides;
# discipline; closure; derive }` is a laws-gated synthesized attribute over the resolution graph, delivered as a
# fleet-level per-node accessor. This suite covers the registry + the 5 field guards (a value-returning
# validator, the relationCollisionMessage/edgesRelationMessage pattern). See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a fleet: one relation `memberOf` (inverse=members) + a no-inverse relation `plainRel`, the `closure` USER
  # stratum (after resolution — every fixture using it must insert it), and one derived `foo` = <deriv>.
  mkFleet =
    deriv:
    denHoag.mkDen [
      (
        { config, ... }:
        {
          config.den.schema.node.parent = null;
          config.den.relations.memberOf = {
            inverse = "members";
          };
          config.den.relations.plainRel = { };
          config.den.strata.insert.closure = {
            after = "resolution";
          };
          config.den.derived.foo = deriv;
        }
      )
    ];

  # clean: over a declared relation, a LATER stratum (closure > resolution), a registered product.
  cleanFleet = mkFleet {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "closure";
    provides = "SystemInfo";
  };
  # (a) over names a relation NOT in den.relations.
  unknownRelFleet = mkFleet {
    over = [ "bogusRel" ];
    direction = "forward";
    stratum = "closure";
  };
  # (b) direction="reverse" over a relation whose inverse is null (the silent-`[]` definition error).
  reverseInverselessFleet = mkFleet {
    over = [ "plainRel" ];
    direction = "reverse";
    stratum = "closure";
  };
  # (c) stratum not in the compiled strata order.
  unknownStratumFleet = mkFleet {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "bogusStratum";
  };
  # (d) stratum NOT LATER than the over relations' strata (resolution == resolution, not strictly later).
  stratumNotLaterFleet = mkFleet {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "resolution";
  };
  # (e) provides names a product NOT registered in den.products.
  providesUnregisteredFleet = mkFleet {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "closure";
    provides = "BogusProduct";
  };
  # (positive) reverse over a relation that HAS an inverse is CLEAN — the reverse guard discriminates on
  # null-inverse only (memberOf's inverse is "members").
  reverseWithInverseFleet = mkFleet {
    over = [ "memberOf" ];
    direction = "reverse";
    stratum = "closure";
  };

  # msgOf — the field validator called DIRECTLY (no fleet → no attr-miss/indexOf crash path), so each guard's
  # message TEXT is asserted in isolation. Two relations: memberOf HAS an inverse, plainRel does not; both sit at
  # `resolution`, so `closure` is a LATER stratum and `resolution` is not.
  msgOf =
    deriv:
    denHoag.internal.derived.derivedFieldMessage {
      deriveds.foo = deriv;
      relationKinds = {
        memberOf = {
          inverse = "members";
          stratum = "resolution";
        };
        plainRel = {
          inverse = null;
          stratum = "resolution";
        };
      };
      strataOrder = [
        "structural"
        "resolution"
        "closure"
      ];
      productNames = [ "SystemInfo" ];
    };
  matches = re: deriv: builtins.match re (msgOf deriv) != null;
in
{
  flake.tests.derived = {
    # the clean derived registers (the guard passes — reading the surface does not throw) and is present.
    test-derived-registers-clean = {
      expr = builtins.attrNames cleanFleet.den.derived;
      expected = [ "foo" ];
    };
    test-derived-clean-no-throw = {
      expr = throws cleanFleet.den.derived;
      expected = false;
    };

    # ── the 5 field guards (NAMED, tryEval-catchable) ──
    test-derived-unknown-relation-throws = {
      expr = throws unknownRelFleet.den.derived;
      expected = true;
    };
    test-derived-reverse-inverseless-throws = {
      expr = throws reverseInverselessFleet.den.derived;
      expected = true;
    };
    test-derived-unknown-stratum-throws = {
      expr = throws unknownStratumFleet.den.derived;
      expected = true;
    };
    test-derived-stratum-not-later-throws = {
      expr = throws stratumNotLaterFleet.den.derived;
      expected = true;
    };
    test-derived-provides-unregistered-throws = {
      expr = throws providesUnregisteredFleet.den.derived;
      expected = true;
    };
    # (positive) reverse over a relation WITH an inverse is clean — the guard discriminates on null-inverse only.
    test-derived-reverse-with-inverse-clean = {
      expr = throws reverseWithInverseFleet.den.derived;
      expected = false;
    };

    # ── message-distinctness: each guard's NAMED message asserted in isolation via the DIRECT validator call
    # (no fleet → no attr-miss/indexOf crash can mask a guard). One distinctive substring pins exactly one guard.
    test-derived-msg-unknown-relation = {
      expr = matches ".*den.derived:.*unknown relation.*" {
        over = [ "bogusRel" ];
        stratum = "closure";
      };
      expected = true;
    };
    test-derived-msg-reverse-inverseless = {
      expr = matches ".*reverse.*inverse.*null.*" {
        over = [ "plainRel" ];
        direction = "reverse";
        stratum = "closure";
      };
      expected = true;
    };
    test-derived-msg-unknown-stratum = {
      expr = matches ".*unknown stratum.*" {
        over = [ "memberOf" ];
        stratum = "bogusStratum";
      };
      expected = true;
    };
    test-derived-msg-not-later = {
      expr = matches ".*not LATER.*" {
        over = [ "memberOf" ];
        stratum = "resolution";
      };
      expected = true;
    };
    test-derived-msg-provides-unregistered = {
      expr = matches ".*not a product registered.*" {
        over = [ "memberOf" ];
        stratum = "closure";
        provides = "BogusProduct";
      };
      expected = true;
    };
  };
}
