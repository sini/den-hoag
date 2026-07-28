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
{ denHoag, ... }:
let
  inherit (denHoag.internal) prelude;
  cmb = denHoag.internal.classModulesBuilder;

  classNames = [
    "A"
    "B"
    "C"
    "D"
    "Z"
  ];
  # a registered channel key classifies as `class`; every other content key (e.g. the aspect's own `name`)
  # is a non-collectable `channel`.
  classifyKey = _name: key: if builtins.elem key classNames then "class" else "channel";

  # a non-empty deferredModule leaf, tag-marked so the answer reads as plain data (no functions ⇒ `==`
  # comparable, and `unique`-able for the distinct-answer counts).
  mod = tag: {
    imports = [ { inherit tag; } ];
  };
  tagsOf = v: builtins.mapAttrs (_: ss: map (e: (builtins.head e.module.imports).tag) ss) v;

  # one aspect per registered channel except `Z`, which stays registered and content-free (the uninvolved
  # channel the acyclicity witness demands).
  resolvedAspects =
    map
      (c: {
        content = {
          name = "asp${c}";
          ${c} = mod "c${c}";
        };
        sharedFoldKey = null;
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

  # synthetic resolver: `resolved-aspects` = the aspects above; `declarations.actions.resolution` = `acts`.
  mkSelf =
    acts:
    let
      self = {
        get =
          id: attr:
          if attr == "resolved-aspects" then
            resolvedAspects
          else if attr == "declarations" then
            { actions.resolution = acts; }
          else if attr == "content-key-totality" then
            cm.content-key-totality.compute self id
          else
            throw "class-relocation: unexpected attr ${attr}";
      };
    in
    self;

  cm = cmb { inherit classNames classifyKey; };
  answer = acts: tagsOf (cm.class-seeds.compute (mkSelf acts) "n");

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
    # the sink gathers its own content first, then its preimage in registered-channel order; every channel
    # with an outgoing relocation is emptied.
    test-diamond-answer = {
      expr = answer diamond;
      expected = {
        A = [ ];
        B = [ ];
        C = [ ];
        D = [
          "cD"
          "cA"
          "cB"
          "cC"
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
    # `A→X, X→B` with `X ∉ Ch`: A's content rides through X and lands at B.
    test-unregistered-intermediate-delivers = {
      expr = (answer intermediate).B;
      expected = [
        "cB"
        "cA"
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
  };
}
