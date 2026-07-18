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

  # ── the entity-side `.edges.<rel>` field (§5:419) — declared, raw-stored; the ref→node-id lowering is the
  # producer's (records carry name but not kind, so lowering is fleet-level and producer-intrinsic) ──
  edgesFleet = denHoag.mkDen [
    (
      { config, ... }:
      {
        config.den.schema.group.parent = null;
        config.den.schema.user.parent = null;
        config.den.relations.memberOf = {
          inverse = "members";
        };
        config.den.group.admins = { };
        config.den.user.sini.edges.memberOf = [ config.den.group.admins ];
      }
    )
  ];
  # a `.edges.<rel>` naming a relation NOT in den.relations — the undeclared-relation guard fires.
  undeclaredEdgesFleet = denHoag.mkDen [
    {
      config.den.schema.user.parent = null;
      config.den.user.sini.edges.bogusRel = [ ];
    }
  ];

  # a fleet with NO relations / NO `.edges` — the producer emits `[ ]` (the corpus-inert gate).
  noRelFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.host.h = { };
    }
  ];
  # ── relQuery: the sel→matchId `where`-adaptation over den.query (§5) ──
  # a user relates to a nixos host AND a darwin host; `sel = hasClass "nixos"` must NARROW the followed targets
  # to the nixos one (the source-agnostic den.query spine can't run a scope-requiring selector — relQuery holds
  # the scope, and relation endpoints ARE scope node-ids).
  relQueryFleet = denHoag.mkDen [
    (
      { config, ... }:
      {
        config.den.schema.nixosHost.parent = null;
        config.den.schema.darwinHost.parent = null;
        config.den.schema.user.parent = null;
        config.den.contentClass.nixosHost = "nixos";
        config.den.contentClass.darwinHost = "darwin";
        config.den.relations.memberOf = {
          inverse = "members";
        };
        config.den.nixosHost.a = { };
        config.den.darwinHost.b = { };
        config.den.user.sini.edges.memberOf = [
          config.den.nixosHost.a
          config.den.darwinHost.b
        ];
      }
    )
  ];

  # ── ctx.rel: the per-entity relation accessor (§5, the mkNarrowAccessor posture) ──
  # a memberOf CHAIN a → b → c (so closure is genuinely MULTI-HOP transitive) + a no-inverse relation `plainRel`.
  relAccessorFleet = denHoag.mkDen [
    (
      { config, ... }:
      {
        config.den.schema.node.parent = null;
        config.den.relations.memberOf = {
          inverse = "members";
        };
        config.den.relations.plainRel = { };
        config.den.node.a.edges.memberOf = [ config.den.node.b ];
        config.den.node.b.edges.memberOf = [ config.den.node.c ];
        config.den.node.a.edges.plainRel = [ config.den.node.c ];
        config.den.node.c = { };
      }
    )
  ];

  # the hand-computed relation edge set for `edgesFleet` (memberOf inverse=members, user.sini →[group.admins]):
  # one FORWARD + one SWAPPED inverse edge, plain-string node-id endpoints.
  expectedRelationEdges = [
    {
      id = "rel:memberOf/user:sini->group:admins";
      kind = "memberOf";
      from = "user:sini";
      to = "group:admins";
    }
    {
      id = "rel:members/group:admins->user:sini";
      kind = "members";
      from = "group:admins";
      to = "user:sini";
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

    # ── the entity-side `.edges.<rel>` field + the undeclared-relation guard (§5) ──
    # the field is ACCEPTED (per-kind schema option) and STORES the raw declared edges keyed by relation.
    test-edges-field-accepted = {
      expr = builtins.attrNames edgesFleet.den.registries.user.sini.edges;
      expected = [ "memberOf" ];
    };
    # the raw targets are stored (unlowered — the ref list rides verbatim; lowering to node-ids is the producer's).
    test-edges-field-stores-targets = {
      expr = builtins.length edgesFleet.den.registries.user.sini.edges.memberOf;
      expected = 1;
    };
    # the fleet-level undeclared-relation guard: `.edges.<rel>` naming a relation NOT in den.relations → NAMED throw.
    test-edges-undeclared-relation-throws = {
      expr = throws undeclaredEdgesFleet.den.relations;
      expected = true;
    };
    # the NAMED contract (value-returning detector, as with the collision message): the undeclared-relation
    # message carries the `den.relations:` prefix + names the offending entity + relation.
    test-edges-undeclared-relation-message-named = {
      expr =
        builtins.match ".*den.relations:.*not a relation in den.relations.*" (
          denHoag.internal.relations.edgesRelationMessage {
            edgeRels = [
              {
                entityId = "user:sini";
                rel = "bogusRel";
              }
            ];
            relationNames = [ "memberOf" ];
          }
        ) != null;
      expected = true;
    };

    # ── the FLAT relation producer + den.relationEdges (§5) ──
    # the producer emits FLAT plain-string records — one FORWARD + one SWAPPED inverse edge — byte-equal to the
    # hand-computed set (proving the ref→node-id lowering + the swap + the plain-string leaf).
    test-relation-edges-byte-equal = {
      expr = builtins.sort (a: b: a.id < b.id) edgesFleet.den.relationEdges;
      expected = expectedRelationEdges;
    };
    # the plain-string leaf is den.query-CONSUMABLE: forward memberOf from user:sini → [group:admins].
    test-relation-edges-query-consumable = {
      expr = denHoag.query {
        edges = edgesFleet.den.relationEdges;
        from = "user:sini";
        follow = "memberOf";
        mode = "all";
      };
      expected = [ "group:admins" ];
    };
    # the SWAPPED inverse edge is queryable forward: from group:admins, follow the inverse label → [user:sini].
    test-relation-edges-inverse-consumable = {
      expr = denHoag.query {
        edges = edgesFleet.den.relationEdges;
        from = "group:admins";
        follow = "members";
        mode = "all";
      };
      expected = [ "user:sini" ];
    };
    # CORPUS-INERT: a fleet with no relations / no `.edges` emits `[ ]` (the memberProducer gate).
    test-relation-edges-corpus-inert = {
      expr = noRelFleet.den.relationEdges;
      expected = [ ];
    };
    # THE GUARD IS WOVEN onto the producer's critical path: forcing den.relationEdges fires the undeclared-
    # relation guard (a malformed `.edges` throws NAMED even when only den.relationEdges — not den.relations — is
    # read), making the validate-then-transform contract real for every producer consumer.
    test-relation-edges-guard-woven = {
      expr = throws undeclaredEdgesFleet.den.relationEdges;
      expected = true;
    };

    # ── relQuery: the sel→matchId `where`-adaptation over den.query (§5) ──
    # with no `sel`, relQuery returns ALL the followed memberOf targets (the plain den.query, where = _: true).
    test-relquery-no-sel-all-targets = {
      expr = builtins.sort builtins.lessThan (
        relQueryFleet.den.relQuery {
          from = "user:sini";
          kind = "memberOf";
        }
      );
      expected = [
        "darwinHost:b"
        "nixosHost:a"
      ];
    };
    # `sel = hasClass "nixos"` NARROWS the targets to the nixos host (the structural selector resolves each
    # node-id endpoint back to its scope node via matchId) — non-vacuous: it drops darwinHost:b.
    test-relquery-sel-narrows = {
      expr = relQueryFleet.den.relQuery {
        from = "user:sini";
        kind = "memberOf";
        sel = denHoag.hasClass "nixos";
      };
      expected = [ "nixosHost:a" ];
    };

    # ── ctx.rel.<kind>.{ targets; inverse; closure; paths } — the per-entity relation accessor (§5) ──
    # the accessor is keyed by RELATION KIND (den.relations names) — NO `members` key (the inverse is a
    # label-only query direction on the forward kind, not a separate ctx.rel kind).
    test-ctxrel-keyed-by-kind = {
      expr = builtins.sort builtins.lessThan (builtins.attrNames (relAccessorFleet.den.relAt "node:a"));
      expected = [
        "memberOf"
        "plainRel"
      ];
    };
    # targets = the 1-hop forward (follow = <kind>): a's direct memberOf target is b (NOT c).
    test-ctxrel-targets-1hop = {
      expr = (relAccessorFleet.den.relAt "node:a").memberOf.targets;
      expected = [ "node:b" ];
    };
    # closure = the TRANSITIVE set (fixpoint, follow = <kind>+, concrete set-union monoid): a → {b, c} — a
    # 1-hop-only impl returning just {b} FAILS this; the transitive reach is the `+` (one-or-more) in
    # follow = <kind>+, not fixpoint-mode iteration.
    test-ctxrel-closure-transitive = {
      expr = builtins.sort builtins.lessThan (relAccessorFleet.den.relAt "node:a").memberOf.closure;
      expected = [
        "node:b"
        "node:c"
      ];
    };
    # inverse = den.query for the inverse LABEL (reads the producer's SWAPPED edges): at b, who points to b via
    # memberOf → a (non-empty, genuinely reads the reverse).
    test-ctxrel-inverse-swapped = {
      expr = (relAccessorFleet.den.relAt "node:b").memberOf.inverse;
      expected = [ "node:a" ];
    };
    # inverse == [ ] for a relation with NO inverse (short-circuit — never a den.query with a null follow).
    test-ctxrel-inverse-null-empty = {
      expr = (relAccessorFleet.den.relAt "node:a").plainRel.inverse;
      expected = [ ];
    };
    # paths = the path witnesses (paths mode): a's 1-hop memberOf reaches b.
    test-ctxrel-paths = {
      expr = map (p: p.node) (relAccessorFleet.den.relAt "node:a").memberOf.paths;
      expected = [ "node:b" ];
    };
  };
}
