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
    scope
    aspects
    select
    ;

  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, built with the base
  # `classifyKey` (nixos/darwin/home-manager) — the same functions the assembly threads to
  # `projectClass`.
  cm =
    import "${denHoagSrc}/lib/attributes/class-modules.nix"
      {
        inherit prelude resolve;
      }
      {
        classNames = [ ];
        inherit classifyKey;
      };

  # projectClass replicated over a STUB reach list (byte-identical to output-modules.nix's body — a pure
  # class-slice fold over `reach id`). `reachList` stands in for `result.get id "reach"`.
  projectOver =
    reachList: class:
    let
      exempt = cm.forwardSourceClassesOf reachList;
    in
    prelude.concatMap (n: map (e: e.module) (cm.classSliceOf exempt n class)) reachList;

  # A synthetic resolved-aspect node `{ key; content }` (the reach node shape).
  mkNode = key: content: {
    inherit key content;
  };

  # ── COMPLETE-REACH driver (spec §Phase-2 synthetic-first): reach.compute over a STUB graph with INJECTED
  #    opt-in edges (the reach-graph mkStub approach), then projectClass over the resulting reach — so the
  #    single-visit dedup + structural-descendant + edge closure are exercised end-to-end (NOT a pre-built
  #    reach list). This is how the corpus terminal will behave once Phase 5 wires the real edges; here the
  #    edges are injected synthetically.
  mkRa = import "${denHoagSrc}/lib/attributes/resolved-aspects.nix" {
    inherit
      prelude
      scope
      aspects
      select
      resolve
      ;
  } { };
  # A reach-graph stub `self` (resolved-aspects / declarations / children).
  mkStub = graph: {
    get =
      id: attr:
      if attr == "resolved-aspects" then
        (graph.${id} or { }).resolved or [ ]
      else if attr == "declarations" then
        { actions.resolution = (graph.${id} or { }).edges or [ ]; }
      else if attr == "children" then
        (graph.${id} or { }).children or { }
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
      reachList = mkRa.reach.compute (mkStub graph) id;
      exempt = cm.forwardSourceClassesOf reachList;
    in
    prelude.concatMap (
      n:
      builtins.seq (cm.assertKeysRegistered exempt n) (map (e: e.module) (cm.classSliceOf exempt n class))
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
  inherit (cm) classSliceOf assertKeysRegistered;
}
