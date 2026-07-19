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

  # a fleet with a memberOf CHAIN a → b → c (so the closure read is genuinely multi-hop transitive) + edges, and
  # one derived `<name>` = <deriv>, for exercising the compute engine (den.derivedAt).
  mkDerivedFleet =
    name: deriv:
    denHoag.mkDen [
      (
        { config, ... }:
        {
          config.den.schema.node.parent = null;
          config.den.relations.memberOf = {
            inverse = "members";
          };
          config.den.strata.insert.closure = {
            after = "resolution";
          };
          config.den.node.a.edges.memberOf = [ config.den.node.b ];
          config.den.node.b.edges.memberOf = [ config.den.node.c ];
          config.den.node.c = { };
          config.den.derived.${name} = deriv;
        }
      )
    ];

  # reverse: the derive reads node.rel.memberOf.inverse (node:b's inverse = [node:a] via the producer's swap).
  reverseFleet = mkDerivedFleet "reverseMembers" {
    over = [ "memberOf" ];
    direction = "reverse";
    stratum = "closure";
    derive = node: _: node.rel.memberOf.inverse;
  };
  # closure-flavored: the derive reads node.rel.memberOf.closure (transitive reach from node:a = [b, c]).
  closureFleet = mkDerivedFleet "reachMembers" {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "closure";
    derive = node: _: node.rel.memberOf.closure;
  };
  # a derive that READS `deps` — must abort NAMED (the value-composition placeholder is loud, never silent).
  depsReadFleet = mkDerivedFleet "readsDeps" {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "closure";
    derive = node: deps: deps;
  };

  # stratum-gate fixtures (§2.3): a derive at stratum=resolution reading a resolution relation must be BLOCKED
  # (same-stratum ≥ n → NAMED throw); the SAME body at stratum=closure is exposed (resolution < closure). over=[]
  # so a non-empty over@resolution + stratum=resolution isn't rejected at the field guard FIRST — the gate, not
  # the guard, is under test (node.rel exposes ALL kinds regardless of over).
  gatedResolutionFleet = mkDerivedFleet "atResolution" {
    over = [ ];
    direction = "forward";
    stratum = "resolution";
    derive = node: _: node.rel.memberOf.targets;
  };
  gatedClosureFleet = mkDerivedFleet "atClosure" {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    derive = node: _: node.rel.memberOf.targets;
  };
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

    # ── the per-node compute engine (den.derivedAt) ──
    # the accessor surface EXISTS.
    test-derived-at-present = {
      expr = cleanFleet.den ? derivedAt;
      expected = true;
    };
    # a typo'd name aborts NAMED (a raw attr-select miss would be tryEval-UNCATCHABLE on this public accessor —
    # `spec` forces before `node`, so the nodeId is inert here).
    test-derived-at-unknown-name-throws = {
      expr = throws (cleanFleet.den.derivedAt "noSuchDerived" "node:a");
      expected = true;
    };
    # non-vacuous: the reverse-memberOf derive reads node.rel.memberOf.inverse — node:b's inverse is [node:a].
    test-derived-at-reverse = {
      expr = reverseFleet.den.derivedAt "reverseMembers" "node:b";
      expected = [ "node:a" ];
    };
    # closure-flavored: the transitive reach from node:a over the a → b → c chain.
    test-derived-at-closure = {
      expr = builtins.sort builtins.lessThan (closureFleet.den.derivedAt "reachMembers" "node:a");
      expected = [
        "node:b"
        "node:c"
      ];
    };
    # the deps placeholder is LOUD: a derive that reads `deps` aborts (the value-composition is a later concern).
    test-derived-at-deps-throws = {
      expr = throws (depsReadFleet.den.derivedAt "readsDeps" "node:a");
      expected = true;
    };
    # …and the abort is NAMED (the placeholder message carries the `den.derived:` prefix + cites §5).
    test-derived-at-deps-message-named = {
      expr =
        builtins.match ".*den.derived:.*value-composition.*" denHoag.internal.derived.depsPlaceholderMessage
        != null;
      expected = true;
    };

    # ── the stratum-gate on the node handle (capability scoping, §2.3) ──
    # a derive at stratum=resolution reading a resolution relation is BLOCKED (same-stratum ≥ → NAMED throw).
    test-derived-gate-same-stratum-throws = {
      expr = throws (gatedResolutionFleet.den.derivedAt "atResolution" "node:a");
      expected = true;
    };
    # the SAME body at stratum=closure reading the same resolution relation is EXPOSED (resolution < closure) —
    # non-vacuous: the gate discriminates BY STRATUM (not always-throw), and the exposed value is correct.
    test-derived-gate-later-stratum-ok = {
      expr = gatedClosureFleet.den.derivedAt "atClosure" "node:a";
      expected = [ "node:b" ];
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
