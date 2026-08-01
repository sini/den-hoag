# Shared projection-test harness — the reach/projectClass driver bindings (mkNode/mkStub/reachEdgeAct/
# mkRa/projectOver/projectReach/projectReachTotal/tags + the class-slice import) shared verbatim across the
# projection suites. Under a `/_`-infixed path so import-tree/mkCi skip it as a flake-parts module (it is a
# `{ denHoag, denHoagSrc }:` fn, not a module).
{ denHoag, denHoagSrc }:
let
  inherit (denHoag.internal)
    prelude
    resolve
    classifyKey
    aspectSchema
    scope
    aspects
    select
    ;
  errors = import "${denHoagSrc}/lib/errors.nix";

  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, built with the base
  # `classifyKey` (nixos/darwin/home-manager) — the same functions the assembly threads to
  # `projectClass`. `keyCategory` comes from the SAME instance those two do, which is what keeps the
  # builder's classification authorities from disagreeing; the top-level instance is the right source for
  # THIS harness precisely because it declares no quirk channels, so it and a fleet-aware instance agree
  # on every name the harness uses.
  cm =
    import "${denHoagSrc}/lib/attributes/class-modules.nix"
      {
        inherit prelude resolve;
        graph = denHoag.internal.genGraph;
      }
      {
        classNames = [ ];
        inherit classifyKey;
        inherit (aspectSchema) keyCategory;
      };

  # ── THE EVAL HANDLE THE EXTRACTION READS THE RELOCATION MEMO THROUGH ──────────────────────────────────
  # `classSliceAt` resolves a channel's source order at the ELEMENT'S OWN scope, off that scope's
  # `class-relocation` memo. The instrument supplies DATA, not a copy of the algorithm: this wrapper answers
  # `"class-relocation"` by driving the KERNEL's own equation (`cm.class-relocation.compute`) against the
  # same stub `self` that serves the reach, and delegates every other attribute to it — the `mkSelf` shape
  # `ci/tests/class-relocation.nix` and `ci/tests/class-bucket-query.nix` already use to serve
  # `"content-key-totality"` from the real equation. An instrument that instead hand-wrote a memo would be
  # replicating the relation, and any divergence from the kernel's would be silent.
  # NOT DEFAULTED, and that is the point of the named abort inside `sourceOrderOf`: an eval that does not
  # serve the attribute at all aborts NAMING THE SCOPE rather than quietly handing back the un-relocated
  # identity, so an instrument cannot accidentally pin the old semantics.
  mkRelocEval = self: {
    get =
      id: attr:
      if attr == "class-relocation" then cm.class-relocation.compute self id else self.get id attr;
  };

  # projectClass replicated over a STUB reach list (byte-identical to output-modules.nix's body — a pure
  # class-slice fold over `reach id`). `reachList` stands in for `result.get id "reach"`.
  projectOver =
    reachList: class:
    let
      exempt = cm.forwardSourceClassesOf reachList;
      eval = mkRelocEval (mkStub { });
    in
    prelude.concatMap (n: map (e: e.module) (cm.classSliceAt eval exempt n class)) reachList;

  # A synthetic content element `{ key; content; scope; assertedClasses }` (the reach node shape).
  # `scope` and `assertedClasses` are STAMPED because a content element is produced COMPLETE — the two
  # extraction entry points project both fields with a named throw rather than reconstructing either from
  # where the element was read, so a fixture omitting one is refused rather than silently defaulted.
  # `scope` is the synthetic sentinel these fixtures resolve their relocation memo at (they declare none, so
  # the memo is the empty relation); `assertedClasses = { }` is the POSITIVE statement "this element asserts
  # nothing" — the value every produced aspect element carries, so the fixtures stay semantically identical.
  mkNode = key: content: {
    inherit key content;
    scope = syntheticScope;
    assertedClasses = { };
  };
  syntheticScope = "<synthetic>";

  # ── COMPLETE-REACH driver (spec §Phase-2 synthetic-first): reach.compute over a STUB graph with INJECTED
  #    opt-in edges (the reach-graph mkStub approach), then projectClass over the resulting reach — so the
  #    single-visit dedup + structural-descendant + edge closure are exercised end-to-end (NOT a pre-built
  #    reach list). This is how the corpus terminal will behave once Phase 5 wires the real edges; here the
  #    edges are injected synthetically.
  mkRa =
    import "${denHoagSrc}/lib/attributes/resolved-aspects.nix"
      {
        inherit
          prelude
          scope
          aspects
          select
          resolve
          errors
          ;
        graph = denHoag.internal.genGraph;
      }
      {
        # The projection harness drives `reach` over a STUB graph with no `contains` pool — stated here
        # rather than defaulted in the kernel, so a fleet that authors containment cannot read none.
        containAncestorIds = _nid: [ ];
      };
  # A reach-graph stub `self` (resolved-aspects / declarations / children / class-relocation).
  # ★ THIS STUB SERVES `reach.compute`, WHICH IS A DIFFERENT CONSUMER FROM `mkRelocEval`'s. Both reach call
  # sites below (`projectReach`, `projectReachTotal`) hand `reach.compute` the RAW stub, while
  # `mkRelocEval` wraps it for the EXTRACTION — so the self-referential override above does not cover this
  # demand, and each eval answers the demand of the consumer it is handed to.
  # WHAT `reach` NEEDS IS `injections`, and `[ ]` is DATA rather than hand-pinned semantics: these fixtures
  # declare no `inject` act, so the empty list is the real equation's own answer on their declaration set.
  # `sourceOrder` is deliberately NOT answered here — `mkRelocEval` serves that half from the kernel's
  # equation, and a hand-written identity order at this arm would pin the un-relocated semantics at a
  # second site. The two accessors compose, each naming the field it needs.
  mkStub = graph: {
    get =
      id: attr:
      if attr == "resolved-aspects" then
        (graph.${id} or { }).resolved or [ ]
      else if attr == "declarations" then
        { actions.resolution = (graph.${id} or { }).edges or [ ]; }
      else if attr == "children" then
        (graph.${id} or { }).children or { }
      else if attr == "class-relocation" then
        { injections = [ ]; }
      else
        throw "projection stub: unexpected attr ${attr}";
    node = id: (graph.${id} or { }).node or { };
  };
  reachEdgeAct = target: classFilter: {
    __action = "reach-edge";
    inherit target classFilter;
  };
  # projectClass over a COMPLETE reach: reach.compute (over the opt-in edges) → the class slice.
  projectReach =
    {
      graph,
      id,
      class,
    }:
    projectOver (mkRa.reach.compute (mkStub graph) id) class;

  # projectClass WITH the §2.2 totality pass (byte-identical to output-modules.nix's projectClass body:
  # `seq (assertKeysRegistered n)` per REACHED aspect before its slice) — for the reached-content totality
  # witness (a typo key on an aspect reached via an EDGE aborts NAMED, not just an own-node key).
  projectReachTotal =
    {
      graph,
      id,
      class,
    }:
    let
      stub = mkStub graph;
      reachList = mkRa.reach.compute stub id;
      exempt = cm.forwardSourceClassesOf reachList;
      eval = mkRelocEval stub;
    in
    prelude.concatMap (
      n:
      builtins.seq (cm.assertKeysRegistered exempt n) (
        map (e: e.module) (cm.classSliceAt eval exempt n class)
      )
    ) reachList;

  # every `tag` string reachable in a wrapped deferredModule (gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
in
{
  inherit
    mkNode
    mkStub
    reachEdgeAct
    projectOver
    projectReach
    projectReachTotal
    tags
    ;
  inherit (cm) assertKeysRegistered;
}
