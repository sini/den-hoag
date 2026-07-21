# The NEGATION-GATE suite (§5/§2.3, L4). A `den.derived` may declare `negates = [ <relKind> ]` — the list of
# relation kinds it reads under NEGATION (the precursor Phase-5's `exclude`/lockdown consumes). Negation is
# NON-MONOTONE, so it is disciplined by two soundness laws (Apt–Blair–Walker stratified negation, §2.3):
#   (a) THROWING-GATE ROUTING — a negated predicate must be read through the THROWING gate (node.rel, which
#       throws on out-of-scope), NEVER the silent-empty node.query (an out-of-scope follow yields []). A negation
#       over a silently-empty predicate cannot distinguish "absent" from "out-of-scope" — unsound. Structurally:
#       a `negates` entry must be a relation KIND (a node.rel key); a non-relation predicate (e.g. an inverse
#       LABEL, query-reachable but NOT a node.rel key) is reachable ONLY via the silent route ⇒ rejected NAMED.
#   (b) STRICTLY-ABOVE — a negation reads a COMPLETE predicate, so the derive's stratum must sit STRICTLY ABOVE
#       every producer of each negated relation (reading it before it is fully produced is non-monotone). The
#       SAME strictly-below ceiling the positive `over` read enforces, made EXPLICIT for negation.
# `negates` is a NEW optional field (default `[ ]`): INERT on every current fleet (none declares it). See
# REFERENCE.md §5.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a fleet: one relation `memberOf` (inverse=members) at its own per-relation stratum rel:memberOf (below
  # resolution), plus the `closure` USER stratum (after resolution). One derived `foo` = <deriv>.
  mkFleet =
    deriv:
    denHoag.mkDen [
      (
        { ... }:
        {
          config.den.schema.node.parent = null;
          config.den.relations.memberOf = {
            inverse = "members";
          };
          config.den.strata.insert.closure = {
            after = "resolution";
          };
          config.den.derived.foo = deriv;
        }
      )
    ];

  # (correct) negates a RELATION KIND (memberOf, a node.rel key) whose producer sits STRICTLY BELOW the derive's
  # own stratum (rel:memberOf < closure) — both soundness laws satisfied. Registration is clean.
  correctFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    negates = [ "memberOf" ];
    derive = node: _: null;
  };
  # (routing violation) negates an INVERSE LABEL (`members` — reachable via node.query's swapped edges, but NOT a
  # node.rel key): the ONLY route to it is the silent-empty query, so a negation over it is unsound (a). NAMED.
  silentRouteFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    negates = [ "members" ];
    derive = node: _: null;
  };
  # (strictly-above violation) negates memberOf from a derive AT the relation's OWN stratum (rel:memberOf == the
  # negated relation's stratum, NOT strictly above) — reading a not-yet-complete predicate is non-monotone (b). NAMED.
  belowProducerFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "rel:memberOf";
    negates = [ "memberOf" ];
    derive = node: _: null;
  };

  # msgOf — the field validator called DIRECTLY (synthetic relationKinds + strata order), so each violation's
  # message TEXT is asserted in isolation — Nix's `tryEval` cannot capture a real throw's text (the derived.nix
  # `msgOf` posture). memberOf HAS an inverse `members`; it sits at `rel:memberOf`, strictly below `closure`.
  msgOf =
    deriv:
    denHoag.internal.derived.derivedFieldMessage {
      deriveds.foo = deriv;
      relationKinds = {
        memberOf = {
          inverse = "members";
          stratum = "rel:memberOf";
        };
      };
      strataOrder = [
        "structural"
        "rel:memberOf"
        "resolution"
        "closure"
      ];
      resolutionProductNames = [ ];
    };
  matches = re: deriv: builtins.match re (msgOf deriv) != null;
in
{
  flake.tests.negation-gate = {
    # ── the field surface accepts `negates` (a new optional field) ──
    # a correct negating derive (throwing route + strictly-above) registers clean.
    test-negation-correct-registers = {
      expr = builtins.attrNames correctFleet.den.derived;
      expected = [ "foo" ];
    };
    test-negation-correct-no-throw = {
      expr = throws correctFleet.den.derived;
      expected = false;
    };

    # ── (a) throwing-gate routing: a `negates` predicate reachable ONLY via the silent query route rejects NAMED ──
    test-negation-silent-route-throws = {
      expr = throws silentRouteFleet.den.derived;
      expected = true;
    };
    # …and the reject is the NAMED routing message (cites the throwing gate / node.rel), not a raw eval crash.
    test-negation-silent-route-named = {
      expr = matches ".*den.derived:.*negates.*node.rel.*" {
        over = [ ];
        stratum = "closure";
        negates = [ "members" ];
        derive = node: _: null;
      };
      expected = true;
    };

    # ── (b) strictly-above: negating a relation NOT strictly below the derive's own stratum rejects NAMED ──
    test-negation-below-producer-throws = {
      expr = throws belowProducerFleet.den.derived;
      expected = true;
    };
    # …and the reject is the NAMED negation strictly-above message (distinct from the positive-`over` `notLater`).
    test-negation-below-producer-named = {
      expr = matches ".*negates.*strictly below.*" {
        over = [ ];
        stratum = "rel:memberOf";
        negates = [ "memberOf" ];
        derive = node: _: null;
      };
      expected = true;
    };

    # ── inertness: a `negates`-free derive is untouched by the new guards (the empty default is a no-op) ──
    test-negation-absent-field-clean = {
      expr =
        throws
          (mkFleet {
            over = [ "memberOf" ];
            direction = "forward";
            stratum = "closure";
            derive = node: _: null;
          }).den.derived;
      expected = false;
    };
  };
}
