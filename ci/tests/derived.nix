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
          # a synthetic resolution product (§5) so a clean derive's `provides` validates against the
          # resolution-facet registry (den.resolutionProducts), distinct from the materialization faces.
          config.den.resolutionProducts.ResolvedInfo = { };
          config.den.derived.foo = deriv;
        }
      )
    ];

  # clean: over a declared relation, a LATER stratum (closure > resolution), a registered product. A trivial
  # `derive` satisfies guard (g) — the fixtures below that omit `derive` are the ones testing an EARLIER guard.
  cleanFleet = mkFleet {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "closure";
    provides = "ResolvedInfo";
    derive = node: _: null;
  };
  # (facet violation) `provides` names a MATERIALIZATION product (SystemInfo ∈ den.products, ∉
  # den.resolutionProducts) — guard (e) validates against the resolution registry, so a cross-facet
  # `provides` fails NAMED. Proves the two registries are distinct namespaces (§5 vs §4.1).
  providesMaterializationFleet = mkFleet {
    over = [ "memberOf" ];
    direction = "forward";
    stratum = "closure";
    provides = "SystemInfo";
    derive = node: _: null;
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
  # (e) provides names a product NOT registered in den.resolutionProducts.
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
    derive = node: _: null;
  };
  # (g) a derived that OMITS the required `derive` — an uncatchable `spec.derive` attr-miss the moment
  # `derivedAt` forces it, made a catchable NAMED definition-time error by guard (g).
  noDerivedFleet = mkFleet {
    over = [ ];
    direction = "forward";
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
      resolutionProductNames = [ "ResolvedInfo" ];
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

  # node.query (§3 over §5): the REVERSE transitive closure `members+` (the inverse LABEL of memberOf) folded
  # through the set-union monoid — genuinely multi-hop over the a → b → c chain, so the swapped-edge arm is
  # exercised (an edge whose `kind` is the inverse label `members`, NOT a relation-kind key: the total
  # `relationStratumOf` must resolve it via the inverse index, never a raw `relationKinds.members` attr-miss).
  membersClosureQuery =
    node:
    node.query {
      from = node.id;
      follow = "members+";
      mode = "fixpoint";
      empty = [ ];
      combine = acc: xs: acc ++ builtins.filter (x: !(builtins.elem x acc)) xs;
      valueOf = x: [ x ];
    };
  # at stratum=closure: memberOf sits at resolution (strictly BELOW closure), so its edges are in the scoped
  # source and the reverse closure resolves.
  queryReverseClosureFleet = mkDerivedFleet "reachViaQuery" {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    derive = node: _: membersClosureQuery node;
  };
  # capability bound (§2.3): the SAME query body at the relation's OWN stratum (rel:memberOf) — memberOf sits
  # at that stratum, NOT strictly below the derive's own, so its edges are EXCLUDED from the scoped source. The
  # follow yields EMPTY (silent capability scoping — never a throw, never a leak of a same-stratum relation).
  queryCapabilityBoundFleet = mkDerivedFleet "capViaQuery" {
    over = [ ];
    direction = "forward";
    stratum = "rel:memberOf";
    derive = node: _: membersClosureQuery node;
  };

  # stratum-gate fixtures (§2.3): a derive AT a relation's own stratum (rel:memberOf) reading that relation must
  # be BLOCKED (same-stratum ≥ n → NAMED throw); the SAME body at stratum=closure is exposed (rel:memberOf <
  # closure). over=[] so a stratum=rel:memberOf derive isn't rejected at the field guard FIRST — the gate, not
  # the guard, is under test (node.rel exposes ALL kinds regardless of over).
  gatedSameStratumFleet = mkDerivedFleet "atRelStratum" {
    over = [ ];
    direction = "forward";
    stratum = "rel:memberOf";
    derive = node: _: node.rel.memberOf.targets;
  };
  gatedClosureFleet = mkDerivedFleet "atClosure" {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    derive = node: _: node.rel.memberOf.targets;
  };

  # guard (f) fixtures: a closure=true derive is laws-gated by the SHARED edges closureGate — its discipline must
  # be REGISTERED + join-semilattice. Definition-time (no compute), so mkFleet suffices; `derive` is irrelevant.
  # reach-closure is the pre-registered join-semilattice witness (concern-disciplines.nix); settings-layers is a
  # registered but ordered-monoid (NON-join-semilattice) discipline.
  # a trivial `derive` on every closure fixture so guard (g) passes and the closure laws-gate (guard f), not the
  # missing-derive guard, is what the closure oracles exercise (non-masking).
  closureCleanFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    closure = true;
    discipline = "reach-closure";
    derive = node: _: null;
  };
  closureNoDisciplineFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    closure = true;
    derive = node: _: null;
  };
  closureUnregisteredFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    closure = true;
    discipline = "bogusDiscipline";
    derive = node: _: null;
  };
  closureNonJslFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    closure = true;
    discipline = "settings-layers";
    derive = node: _: null;
  };
  closureFalseFleet = mkFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    closure = false;
    derive = node: _: null;
  };

  # closureMsgOf — the SHARED closure law called DIRECTLY as a VALUE (the value-split makes the NAMED message
  # CI-testable), so the caller's locus prefix is asserted in isolation. Synthetic disciplines: reach-closure
  # (join-semilattice) + settings-layers (ordered-monoid). Call only with UNLAWFUL args (a null message can't be
  # regex-matched).
  closureMsgOf =
    args:
    denHoag.internal.edgeKinds.closureMessage {
      reach-closure.laws = "join-semilattice";
      settings-layers.laws = "ordered-monoid";
    } args;
  closureMatches = re: args: builtins.match re (closureMsgOf args) != null;
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

    # ── the field guards (NAMED, tryEval-catchable) ──
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
    # (g) a missing `derive` aborts NAMED at definition time (else an uncatchable `spec.derive` attr-miss).
    test-derived-no-derive-throws = {
      expr = throws noDerivedFleet.den.derived;
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
    # a derive AT a relation's own stratum reading that relation is BLOCKED (same-stratum ≥ → NAMED throw).
    test-derived-gate-same-stratum-throws = {
      expr = throws (gatedSameStratumFleet.den.derivedAt "atRelStratum" "node:a");
      expected = true;
    };
    # the SAME body at stratum=closure reading the same (below-closure) relation is EXPOSED (rel:memberOf <
    # closure) — non-vacuous: the gate discriminates BY STRATUM (not always-throw), and the exposed value is correct.
    test-derived-gate-later-stratum-ok = {
      expr = gatedClosureFleet.den.derivedAt "atClosure" "node:a";
      expected = [ "node:b" ];
    };

    # ── node.query (§3 follow-grammar over the §2.3 stratum-scoped relation source) ──
    # the REVERSE transitive closure `members+` from node:c over the a → b → c chain is genuinely MULTI-HOP
    # (c ← b ← a): the swapped inverse-label edges are followed and the fixpoint fold accumulates the full
    # reach — a 1-hop or forward-only impl would miss node:a. Also exercises the swapped-arm total-stratum
    # index (the `members`-labelled edges carry a non-relation-kind `kind`).
    test-derived-query-reverse-closure = {
      expr = builtins.sort builtins.lessThan (
        queryReverseClosureFleet.den.derivedAt "reachViaQuery" "node:c"
      );
      expected = [
        "node:a"
        "node:b"
      ];
    };
    # capability bound (§2.3): the SAME query body at the relation's own stratum reads memberOf — NOT strictly
    # below the derive's own stratum, so the edge is EXCLUDED from the scoped source. The result is EMPTY
    # (silent scoping), never a throw and never a same-stratum leak — the source IS the capability.
    test-derived-query-capability-bound-empty = {
      expr = queryCapabilityBoundFleet.den.derivedAt "capViaQuery" "node:c";
      expected = [ ];
    };

    # ── guard (f): the closure/discipline laws-gate (§2.2, the SHARED edges closureGate) ──
    # closure=true + a registered join-semilattice discipline (reach-closure) is lawful.
    test-derived-closure-clean-no-throw = {
      expr = throws closureCleanFleet.den.derived;
      expected = false;
    };
    # closure=true with no discipline → NAMED throw (branch 1).
    test-derived-closure-no-discipline-throws = {
      expr = throws closureNoDisciplineFleet.den.derived;
      expected = true;
    };
    # closure=true naming a discipline absent from the registry → NAMED throw (branch 2).
    test-derived-closure-unregistered-throws = {
      expr = throws closureUnregisteredFleet.den.derived;
      expected = true;
    };
    # closure=true under a registered but NON-join-semilattice discipline (settings-layers) → NAMED throw (branch 3).
    test-derived-closure-non-jsl-throws = {
      expr = throws closureNonJslFleet.den.derived;
      expected = true;
    };
    # closure=false needs no discipline — the gate is a no-op.
    test-derived-closure-false-no-throw = {
      expr = throws closureFalseFleet.den.derived;
      expected = false;
    };
    # the locus message-match (writable via the value-split): the derived caller's message names the den.derived
    # surface…
    test-derived-closure-msg-locus = {
      expr = closureMatches "den.derived: 'foo'.*no discipline.*" {
        subject = "den.derived:";
        name = "foo";
        closure = true;
        discipline = null;
      };
      expected = true;
    };
    # …and NEVER leaks the den.edges surface (the negative half — catches a wrong-subject regression).
    test-derived-closure-msg-not-edges-locus = {
      expr = closureMatches ".*den.edges.*" {
        subject = "den.derived:";
        name = "foo";
        closure = true;
        discipline = null;
      };
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
      expr = matches ".*not a resolution product registered.*" {
        over = [ "memberOf" ];
        stratum = "closure";
        provides = "BogusProduct";
      };
      expected = true;
    };
    # (facet violation) a `provides` naming a MATERIALIZATION product (SystemInfo) throws NAMED — guard (e)
    # validates against den.resolutionProducts, not den.products, so a cross-facet claim fails at definition.
    test-derived-provides-materialization-throws = {
      expr = throws providesMaterializationFleet.den.derived;
      expected = true;
    };
    # …and the NAMED message locates the resolution registry (den.resolutionProducts, §5), not the
    # materialization surface — the value-split makes the cross-facet message CI-testable.
    test-derived-msg-provides-materialization = {
      expr = matches ".*den.resolutionProducts.*" {
        over = [ "memberOf" ];
        stratum = "closure";
        provides = "SystemInfo";
      };
      expected = true;
    };
    test-derived-msg-no-derive = {
      expr = matches ".*den.derived:.*no .derive..*" {
        over = [ ];
        stratum = "closure";
      };
      expected = true;
    };
  };
}
