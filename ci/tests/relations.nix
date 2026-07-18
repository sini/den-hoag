# The RELATIONS suite (§5 resolution facet, §2.2 one-registry). `den.relations.<name> = { inverse ? null;
# data ? {}; }` desugars to the LIVE `den.edges` registry — ONE edge-kind per relation @resolution
# (closure = false), carrying `inverse` as label-only metadata (NO second kind: the inverse direction is
# materialized downstream by the producer's swapped edges + ctx.rel's label-follow). See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a relation desugars to ONE den.edges kind @resolution, closure=false, carrying inverse="members".
  relFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.relations.memberOf = {
        inverse = "members";
      };
    }
  ];
  # a relation with no inverse — one kind, inverse = null.
  plainFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.relations.plain = { };
    }
  ];

  # ── collision fixtures (the ONE guard over {relation names} ∪ {non-null inverse labels}) ──
  # (a) an inverse label colliding with a USER den.edges kind (the //-merge silent last-wins).
  collideUserEdge = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.relations.memberOf = {
        inverse = "members";
      };
      config.den.edges.members = { };
    }
  ];
  # (b) an inverse label that is a RESERVED framework name (reservedOffenders can't catch a label-only inverse).
  collideReserved = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.relations.memberOf = {
        inverse = "member";
      };
    }
  ];
  # (c) two relations sharing one inverse label.
  collideSharedInverse = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.relations.foo = {
        inverse = "bar";
      };
      config.den.relations.baz = {
        inverse = "bar";
      };
    }
  ];
  # (d) a relation NAME colliding with a user den.edges kind.
  collideRelName = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.relations.foo = { };
      config.den.edges.foo = { };
    }
  ];
in
{
  flake.tests.relations = {
    # the relation registers exactly ONE edge-kind @resolution, closure=false, carrying inverse="members" —
    # and NO auto-created "members" kind (the inverse is label-only metadata).
    test-relation-registers-one-kind = {
      expr = {
        stratum = relFleet.den.edges.memberOf.stratum;
        closure = relFleet.den.edges.memberOf.closure;
        inverse = relFleet.den.edges.memberOf.inverse;
        membersKind = relFleet.den.edges ? members;
      };
      expected = {
        stratum = "resolution";
        closure = false;
        inverse = "members";
        membersKind = false;
      };
    };
    # closure = false ⇒ the registry closure-gate is a NO-OP: the whole compiled table forces WITHOUT a throw.
    test-relation-closure-gate-noop = {
      expr = throws relFleet.den.edges;
      expected = false;
    };
    # `inverse` is optional — a plain relation registers with inverse = null.
    test-relation-no-inverse = {
      expr = plainFleet.den.edges.plain.inverse;
      expected = null;
    };

    # ── the collision guard (NAMED, tryEval-catchable) ──
    test-relation-inverse-collides-user-edge-throws = {
      expr = throws collideUserEdge.den.edges;
      expected = true;
    };
    test-relation-inverse-reserved-throws = {
      expr = throws collideReserved.den.edges;
      expected = true;
    };
    test-relation-shared-inverse-throws = {
      expr = throws collideSharedInverse.den.edges;
      expected = true;
    };
    test-relation-name-collides-user-edge-throws = {
      expr = throws collideRelName.den.edges;
      expected = true;
    };

    # `data` passthrough (edges.nix entryOf reads `raw.data or null`): a relation's `data` defaults to the
    # ratified empty-schema `{}` (the deliberate {}-vs-null choice) and rides onto the edge-kind.
    test-relation-data-passthrough = {
      expr = {
        memberOf = relFleet.den.edges.memberOf.data;
        plain = plainFleet.den.edges.plain.data;
      };
      expected = {
        memberOf = { };
        plain = { };
      };
    };
    # the NAMED contract (not a silent //-last-wins): the collision message carries the `den.relations:` prefix
    # AND buckets the class. tryEval cannot capture a throw's text, so assert the detector's message VALUE — the
    # reserved-inverse case (the one the shipped reservedOffenders cannot catch).
    test-relation-collision-message-named = {
      expr =
        builtins.match ".*den.relations:.*is a reserved framework name.*" (
          denHoag.internal.relations.relationCollisionMessage {
            relations = {
              memberOf = {
                inverse = "member";
              };
            };
            userEdgeKinds = [ ];
            reservedNames = denHoag.internal.edgeKinds.reservedNames;
          }
        ) != null;
      expected = true;
    };
  };
}
