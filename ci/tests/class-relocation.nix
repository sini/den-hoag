# class-relocation — the resolution-stratum RELOCATION relation (`declare.reroute`/`declare.inject`) as a
# per-(node, channel) query, witnessed over the raw class-content producer (`internal.classModulesBuilder`)
# against a synthetic `self` (relocation is corpus-inert, so the direct witness is synthetic).
#
# The relation Ρ(n) ⊆ Ch × Ch is `{ from; to }` per `reroute` act, self-pairs dropped. A channel's content is
# the concatenation of the RAW seeds of its PREIMAGE — the channels whose content comes to rest at it — so
# the answer is a function of the DECLARATION SET and never of the declaration ORDER, and a channel with an
# outgoing relocation keeps nothing.
#
# Witnesses (a permutation-closed act set is asserted over ALL its permutations, so an order-sensitive
# producer shows up as a distinct-answer COUNT rather than as one unlucky row):
#   (1) DIAMOND `A→B, A→C, B→D, C→D` — one answer over all 4! orders, and A's content reaches the sink. A
#       sequential whole-map fold empties A on its first act, so the second branch carries nothing and the
#       content is destroyed outright on some orders.
#   (2) SELF-RELOCATION `{ from = c; to = c; }` — the identity relocation is a NO-OP and `c` keeps its own
#       content. A whole-map fold writes the same dynamic key twice in one attrset literal, which is a
#       language-level abort `builtins.tryEval` cannot contain.
#   (3) CYCLE `A→B, B→A` — no rest position exists, so there is no content answer and the query ABORTS
#       NAMED, containably. Asserted on an UNINVOLVED channel's demand: the guard belongs to the relation,
#       not to the cycle's own query path.
#   (4) UNREGISTERED INTERMEDIATE `A→X, X→B` with `X ∉ Ch` — content routed THROUGH an unregistered channel
#       still lands. `X` can be a preimage SOURCE and can never be a query ANSWER, which is what keeps the
#       unregistered-TARGET and unregistered-SOURCE arms identical to a registered-only relation.
{ denHoag, denHoagSrc, ... }:
let
  inherit (denHoag.internal) prelude aspects merge;
  cmb = denHoag.internal.classModulesBuilder;

  classNames = [
    "A"
    "B"
    "C"
    "D"
    "Z"
  ];
  # THE CLASSIFICATION AUTHORITY IS A REAL SCHEMA INSTANCE over this fixture's own class names, not a
  # hand-written dispatch. Both functions the producer classifies with come from it, so the fixture cannot
  # hold two authorities that disagree about its own channels — a hand-written `classifyKey` answering
  # `"class"` for `A` beside a schema answering `null` for it is exactly that disagreement. It also keeps
  # the suite testing the kernel's classification rather than a copy of it that is free to drift.
  inherit
    (import "${denHoagSrc}/lib/concern-aspects.nix" {
      inherit
        prelude
        aspects
        merge
        classNames
        ;
      errors = import "${denHoagSrc}/lib/errors.nix";
      kindNames = [ ];
    })
    classifyKey
    aspectSchema
    ;

  # a non-empty deferredModule leaf, tag-marked so the answer reads as plain data (no functions ⇒ `==`
  # comparable, and `unique`-able for the distinct-answer counts).
  mod = tag: {
    imports = [ { inherit tag; } ];
  };
  tagsOf = v: builtins.mapAttrs (_: ss: map (e: (builtins.head e.module.imports).tag) ss) v;

  # one aspect per registered channel except `Z`, which stays registered and content-free (the uninvolved
  # channel the acyclicity witness demands).
  # `scope` and `assertedClasses` are STAMPED: a content element is produced COMPLETE, and the totality
  # assertion projects `assertedClasses` with a named throw rather than reading an absence as a default.
  # `{ }` is the value every produced aspect element carries — "this element asserts nothing" — so these
  # fixtures stay semantically identical to what the assembly feeds the equation.
  resolvedAspects =
    map
      (c: {
        content = {
          name = "asp${c}";
          ${c} = mod "c${c}";
        };
        sharedFoldKey = null;
        scope = "n";
        assertedClasses = { };
      })
      [
        "A"
        "B"
        "C"
        "D"
      ];

  reroute = f: t: {
    __action = "reroute";
    from = f;
    to = t;
  };
  inject = c: tag: {
    __action = "inject";
    class = c;
    module = mod tag;
  };

  # synthetic resolver: `resolved-aspects` = the aspects above; `declarations.actions.resolution` = `acts`;
  # `class-relocation` = the real per-scope memo, serving both fields `class-seeds` now reads through it —
  # `injections` for the element list, `sourceOrder` for each channel's preimage. It is driven from the
  # KERNEL's own equation against this same `self` (the shape the `content-key-totality` arm beside it
  # already uses), so the fixture supplies the ACTS and the kernel supplies the relation; a hand-written
  # memo here would be a second copy of the algorithm under test.
  # A SECOND aspect list, identical to the one above plus one element declaring content at a `_`-prefixed
  # key. `_`-prefixed keys are the module system's own scaffolding, so the extraction's prefix conjunct
  # skips them before any classification runs — which makes `_u` a channel that HAS content and can never
  # answer any query. That is exactly the population the relocation's two endpoint arms are undecided on,
  # and it is why the rows below need an aspect the fixtures above do not carry.
  underscoreAspects = resolvedAspects ++ [
    {
      content = {
        name = "aspU";
        _u = mod "cU";
      };
      sharedFoldKey = null;
      scope = "n";
      assertedClasses = { };
    }
  ];

  mkSelfOver =
    asps: acts:
    let
      self = {
        get =
          id: attr:
          if attr == "resolved-aspects" then
            asps
          else if attr == "declarations" then
            { actions.resolution = acts; }
          else if attr == "content-key-totality" then
            cm.content-key-totality.compute self id
          else if attr == "class-relocation" then
            cm.class-relocation.compute self id
          else
            throw "class-relocation: unexpected attr ${attr}";
      };
    in
    self;

  mkSelf = mkSelfOver resolvedAspects;

  cm = cmb {
    inherit classNames classifyKey;
    inherit (aspectSchema) keyCategory;
  };
  answer = acts: tagsOf (cm.class-seeds.compute (mkSelf acts) "n");
  # the same query over the aspect list carrying the `_`-prefixed channel.
  answerU = acts: tagsOf (cm.class-seeds.compute (mkSelfOver underscoreAspects acts) "n");

  # ── permutations of an act list, so an order-dependent producer is measured rather than sampled ───────
  removeAt =
    i: xs:
    builtins.genList (j: builtins.elemAt xs (if j < i then j else j + 1)) (builtins.length xs - 1);
  permutations =
    xs:
    if xs == [ ] then
      [ [ ] ]
    else
      prelude.concatMap (i: map (p: [ (builtins.elemAt xs i) ] ++ p) (permutations (removeAt i xs))) (
        builtins.genList (i: i) (builtins.length xs)
      );
  answersOver = acts: prelude.unique (map answer (permutations acts));

  diamond = [
    (reroute "A" "B")
    (reroute "A" "C")
    (reroute "B" "D")
    (reroute "C" "D")
  ];
  cycle = [
    (reroute "A" "B")
    (reroute "B" "A")
  ];
  acyclic = [ (reroute "A" "B") ];
  intermediate = [
    (reroute "A" "X")
    (reroute "X" "B")
  ];
  twoUnregisteredSources = [
    (inject "Y" "iY")
    (inject "X" "iX")
    (reroute "Y" "B")
    (reroute "X" "B")
  ];

  # a demand for ONE channel, containment-tested. `deepSeq` forces the tags (strings), never a module body.
  demand = acts: c: (builtins.tryEval (builtins.deepSeq (answer acts).${c} true)).success;
in
{
  flake.tests.class-relocation = {
    # ── (1) the diamond ────────────────────────────────────────────────────────────────────────────────
    # every channel with an outgoing relocation is emptied, and the sink gathers the whole preimage.
    # THE ORDER IS ELEMENT-MAJOR: the query nests element-outer, source-channel-inner, so the answer follows
    # the aspects' own include order (aspA, aspB, aspC, aspD) rather than the sink's channel order
    # (`[D,A,B,C]`, which would answer `[ "cD" "cA" "cB" "cC" ]`). merge_ord is the architecture's content
    # order; under channel-major an EARLIER aspect's relocated content lands after a LATER aspect's, so
    # declaring a relocation between two channels would invert include-order precedence for content in a
    # third. The multiset is identical under both nestings — only the order is pinned here.
    test-diamond-answer = {
      expr = answer diamond;
      expected = {
        A = [ ];
        B = [ ];
        C = [ ];
        D = [
          "cA"
          "cB"
          "cC"
          "cD"
        ];
        Z = [ ];
      };
    };

    # ONE answer for one act set, over all 4! orders.
    test-diamond-permutation-invariant = {
      expr = builtins.length (answersOver diamond);
      expected = 1;
    };

    # and the branch content is never destroyed: A's content reaches the sink on EVERY order.
    test-diamond-content-never-stranded = {
      expr = builtins.all (a: builtins.elem "cA" a.D) (map answer (permutations diamond));
      expected = true;
    };

    # ── (2) the self-relocation ────────────────────────────────────────────────────────────────────────
    # the identity relocation contributes no edge, so `A` is a rest position and keeps its own content.
    test-self-relocation-is-a-noop = {
      expr = answer [ (reroute "A" "A") ];
      expected = {
        A = [ "cA" ];
        B = [ "cB" ];
        C = [ "cC" ];
        D = [ "cD" ];
        Z = [ ];
      };
    };

    # and it is not an abort at all — a fortiori a containable one.
    test-self-relocation-is-containable = {
      expr = demand [ (reroute "A" "A") ] "A";
      expected = true;
    };

    # ── (3) the cycle, demanded at an UNINVOLVED channel ───────────────────────────────────────────────
    # `Z` declares no relocation and is not in the cycle. The abort still fires, and it is containable —
    # a guard wired only into the cycle's own query path answers `Z` and goes quiet.
    test-cycle-aborts-on-uninvolved-demand = {
      expr = demand cycle "Z";
      expected = false;
    };

    # POSITIVE CONTROL for the row above: the same demand on an ACYCLIC relation returns normally, so an
    # unconditional abort does not pass either.
    test-acyclic-uninvolved-demand-returns = {
      expr = demand acyclic "Z";
      expected = true;
    };

    # the abort NAMES every channel in the cycle, not one path through it (the message text is asserted as
    # a VALUE — `tryEval` carries no message channel).
    test-cycle-names-every-member = {
      expr = denHoag.internal.genGraph.cycles {
        edges =
          c: map (e: e.to) (builtins.filter (e: e.from == c) (map (a: { inherit (a) from to; }) cycle));
        nodes = classNames;
      };
      expected = [
        "A"
        "B"
      ];
    };

    # ── (4) the unregistered intermediate ──────────────────────────────────────────────────────────────
    # `A→X, X→B` with `X ∉ Ch`: A's content rides through X and lands at B. Element-major again — B's source
    # order is `[B,A,X]`, but the element list visits aspA before aspB.
    test-unregistered-intermediate-delivers = {
      expr = (answer intermediate).B;
      expected = [
        "cA"
        "cB"
      ];
    };

    # POSITIVE CONTROLS in the same run: an unregistered TARGET and an unregistered SOURCE are both
    # identical to a registered-only relation, so a query that merely admits every name is not passing.
    test-unregistered-target-arm = {
      expr = answer [ (reroute "A" "X") ];
      expected = {
        A = [ ];
        B = [ "cB" ];
        C = [ "cC" ];
        D = [ "cD" ];
        Z = [ ];
      };
    };
    test-unregistered-source-arm = {
      expr = answer [ (reroute "X" "A") ];
      expected = {
        A = [ "cA" ];
        B = [ "cB" ];
        C = [ "cC" ];
        D = [ "cD" ];
        Z = [ ];
      };
    };

    # two unregistered SOURCES converging on one channel: the unregistered endpoints have no registry
    # order, so they are ordered by NAME. Appending them in act order instead makes the answer depend on
    # the order of the act list — measured here as a distinct-answer count over all 4! orders.
    test-unregistered-sources-order-free = {
      expr = builtins.length (answersOver twoUnregisteredSources);
      expected = 1;
    };
    test-unregistered-sources-answer = {
      expr = (answer twoUnregisteredSources).B;
      expected = [
        "cB"
        "iX"
        "iY"
      ];
    };

    # ── (5) the `_`-prefixed key space at the relocation's TWO ENDPOINTS ────────────────────────────────
    # A `_`-prefixed channel is refused where an injection MINTS one, because minting merges a
    # fleet-authored name into a key space the module system already reads. A relocation endpoint mints
    # nothing — it names a channel that either has content or does not — so the same name has to be
    # decided separately at each end, and deciding it by refusing the whole prefix would turn an accepted
    # no-op into an abort. The two rows below are what makes that split a measurement instead of an
    # assumption, and both are stated against the plain-name control that the refusal must not disturb.

    # (a) THE SOURCE END IS INERT, NOT REFUSED. `_u` carries content on this aspect list, and the
    #     extraction's prefix conjunct skips it before any classification — so relocating FROM it moves
    #     nothing and the answer is the no-act baseline, channel for channel. A design discharging the
    #     `_`-prefix class by refusing every occurrence of it turns this row from green to an abort.
    #     ★ THE FIXTURE-SHAPE FIELD IS PART OF THE ROW, because the equality alone is satisfied by an
    #     aspect list that never carried `_u` at all — a fixture whose extra element was empty would make
    #     both sides equal for a reason that has nothing to do with the prefix.
    test-reroute-from-underscore-channel-is-inert = {
      expr = {
        withAct = answerU [ (reroute "_u" "B") ];
        noAct = answerU [ ];
        # the content is really there, and really invisible to the query: the extra element declares `_u`,
        # and the whole answer is unchanged by its presence.
        declaresUnderscore = builtins.any (a: a.content ? _u) underscoreAspects;
        sameAsWithoutTheAspect = answerU [ ] == answer [ ];
      };
      expected = {
        withAct = answerU [ ];
        noAct = answerU [ ];
        declaresUnderscore = true;
        sameAsWithoutTheAspect = true;
      };
    };

    # (b) THE TARGET END BEHAVES LIKE ANY UNREGISTERED NAME. Two claims, because either alone is weaker
    #     than the pair: relocating INTO `_x` answers exactly as relocating into the plain `x` does, and a
    #     two-hop `A → _x → B` delivers A's content to B exactly as the plain-name control does. The
    #     second is what shows `_x` can still be a preimage SOURCE after being a target — the property
    #     that makes an unregistered intermediate work at all — so a change that admitted the target end
    #     while silently dropping content routed through it fails here and passes the first claim.
    test-reroute-to-underscore-channel-matches-plain-control = {
      expr = {
        oneHop = answer [ (reroute "A" "_x") ];
        twoHop = (
          answer [
            (reroute "A" "_x")
            (reroute "_x" "B")
          ]
        ).B;
        # the plain-name control's own value, stated so the equality above cannot be read off two
        # identically-empty answers.
        twoHopControl = (
          answer [
            (reroute "A" "x")
            (reroute "x" "B")
          ]
        ).B;
      };
      expected = {
        oneHop = answer [ (reroute "A" "x") ];
        twoHop = [
          "cA"
          "cB"
        ];
        twoHopControl = [
          "cA"
          "cB"
        ];
      };
    };
  };
}
