# THE POSITION-DEPENDENT SELECTION, dispatched — a selector whose answer is NOT a function of node kind
# alone, answered per node against the running fleet's own scope graph.
#
# WHAT THIS IS ABOUT. A kind list can name `host`, and it can name `user`, but it cannot say *"`host` and
# everything under a `host`"* — that is a RELATION over the scope graph, not a set of kind names, and
# writing `[ host, user ]` says something different (every user, including ones under no such host). The
# selector domain can say it: `any [ attrs { type = host; }, within (attrs { type = host; }) ]`. Deciding
# it requires the node's POSITION, so the kind memo cannot answer it and the per-node matcher must run —
# against the scope context of the eval the dispatch is running inside.
#
# THE FEED HERE IS THE STRUCTURAL ONE, and the choice is deliberate: the policy declares `emit`, so it is
# neither resolve-family nor exclude-family and is dispatched at attributes 2 and 4 only. A policy
# declaring `suppress` would also be collected by the staged pre-pass, whose matcher reaches the scope
# graph by a different route — measuring both through one policy would leave a failure attributable to
# either.
#
# THE ARMS FAIL FOR DIFFERENT WRONG IMPLEMENTATIONS:
#   (a) the widened selector reaches the descendants — fails if the matcher is never applied, or applied
#       against a context carrying no ancestor accessor;
#   (b) the narrow selector still reaches ONLY the anchors — fails an implementation that answers `true`
#       everywhere once any rule is position-dependent, which (a) alone would pass;
#   (c) `within` is STRICT — the anchors are reached by the `attrs` disjunct and never by `within`, so an
#       implementation whose `within` admitted the node itself is caught here rather than hidden by the
#       union in (a);
#   (d) a kind-determined selector on the SAME fleet is unmoved — the control that says these answers are
#       the selector's doing and not the fixture's shape.
{
  lib,
  denHoag,
  ...
}:
let
  inherit (denHoag) sel declare;

  # A user names its host in a declared field; `den.attach` turns that field into the P edge, so the
  # chain below is real scope parentage rather than a hand-built roots table.
  userOpts = _: {
    options.host = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  anchors = sel.attrs { type = "host"; };
  # The intent "every scope where `host` is bound": the hosts themselves, and every scope under one.
  # `within` is a STRICT ancestor test, which is exactly why the disjunction is needed — `within` alone
  # would select the descendants and drop the anchors.
  anchorsAndBelow = sel.any [
    anchors
    (sel.within anchors)
  ];

  # ONE fleet shape, parameterised by the selector under test. Two hosts and three users, split 1/2, so
  # a per-entity parent resolution is exercised and an implementation attaching every user to the first
  # host cannot pass by coincidence.
  fleet =
    selects:
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.schema.user = {
          parent = "host";
          imports = [ userOpts ];
        };
        config.den.attach.user.ref = "host";
        config.den.host = {
          a = { };
          b = { };
        };
        config.den.user = {
          u1.host = "a";
          u2.host = "b";
          u3.host = "b";
        };
        config.den.policies.P = {
          inherit selects;
          emits = [ "emit" ];
          fn = _ctx: [ (declare.emit { marker = "fired"; }) ];
        };
      }
    ]).den;

  # `declarations` is the node's OWN dispatched declarations — not an inherited set — so a node appears
  # here exactly when the policy was SELECTED at it.
  firedAt =
    den:
    builtins.filter (id: (den.structural.eval.get id "declarations").actions.structural or [ ] != [ ]) (
      builtins.attrNames den.structural.eval.allNodes
    );

  # THE OTHER STRUCTURAL SITE. An `enrich`-only codomain routes the policy to the enrichment fixpoint
  # instead of the stratified dispatch — a different feed, a different attribute, the same selection.
  # The enrichment is a constant, so the keyset it commits to is the same at every node it reaches and
  # the fixpoint's supportedness comparison has nothing conditional to disagree about.
  enrichFleet =
    selects:
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.schema.user = {
          parent = "host";
          imports = [ userOpts ];
        };
        config.den.attach.user.ref = "host";
        config.den.host = {
          a = { };
          b = { };
        };
        config.den.user = {
          u1.host = "a";
          u2.host = "b";
          u3.host = "b";
        };
        config.den.policies.E = {
          inherit selects;
          emits = [ "enrich" ];
          fn = _ctx: [
            (declare.enrich {
              key = "mark";
              value = "fired";
            })
          ];
        };
      }
    ]).den;
  # The enriched context is what the fixpoint publishes, so a node carrying the key is a node the
  # enrich policy was selected at. It is NOT inherited — attribute 1 threads decls, not enrichments.
  enrichedAt =
    den:
    builtins.filter (id: (den.structural.eval.get id "enriched-context") ? mark) (
      builtins.attrNames den.structural.eval.allNodes
    );
in
{
  flake.tests.selects-position-dependent = {
    # (a)+(b) THE PAIR. One fleet shape, two selectors, two dispatch sets — and the widening is exactly
    # the descendants. Asserted as one expression because the DIFFERENCE is the property: a narrow set
    # alone is satisfied by an implementation that never applies the matcher, and a wide set alone by one
    # that selects every node the moment any rule is position-dependent.
    test-the-widened-selector-reaches-the-descendants = {
      expr = {
        narrow = firedAt (fleet anchors);
        wide = firedAt (fleet anchorsAndBelow);
      };
      expected = {
        narrow = [
          "host:a"
          "host:b"
        ];
        wide = [
          "host:a"
          "host:b"
          "user:u1"
          "user:u2"
          "user:u3"
        ];
      };
    };

    # (c) `within` IS STRICT. On its own it selects the descendants and NOT the anchors, which is what
    # makes the disjunction above a requirement rather than a flourish. An implementation whose `within`
    # admitted the node itself would produce the same answer as `wide` and go unnoticed there.
    test-within-is-a-strict-ancestor-test = {
      expr = firedAt (fleet (sel.within anchors));
      expected = [
        "user:u1"
        "user:u2"
        "user:u3"
      ];
    };

    # (d) THE CONTROLS, same fleet, same run. `star` reaches every node and `any [ ]` reaches none, so
    # the instrument can produce both extremes — an arm above returning a proper subset is a measurement
    # rather than an artefact of a predicate that cannot vary.
    test-the-two-absences-still-bound-the-answers = {
      expr = {
        everywhere = firedAt (fleet sel.star);
        nowhere = firedAt (fleet (sel.any [ ]));
      };
      expected = {
        everywhere = [
          "host:a"
          "host:b"
          "user:u1"
          "user:u2"
          "user:u3"
        ];
        nowhere = [ ];
      };
    };

    # (e) THE ENRICHMENT SITE, same selection. Both structural dispatch sites obtain the matcher the same
    # way — from the eval they are running inside — but they are two expressions in two attributes, and a
    # thread connected at one of them is not connected at the other.
    test-the-enrichment-site-selects-the-same-way = {
      expr = {
        narrow = enrichedAt (enrichFleet anchors);
        wide = enrichedAt (enrichFleet anchorsAndBelow);
      };
      expected = {
        narrow = [
          "host:a"
          "host:b"
        ];
        wide = [
          "host:a"
          "host:b"
          "user:u1"
          "user:u2"
          "user:u3"
        ];
      };
    };
  };
}
