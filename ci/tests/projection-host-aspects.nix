# Phase 6.2a projection witness (spec §7.1 / §6.2a — host-aspects opt-in → class-scoped reach-edge).
#
# The v1 corpus `host-aspects` battery opts a (user,host) CELL into its HOST's home-manager aspects. Under
# projection this is a class-scoped `reach-edge` from the cell to its host root: an opted-in cell REACHES the
# host's home-manager resolved-aspects (class-filtered — no nixos over-reach), a plain cell reaches only its
# own. This witness pins that TARGET behavior over a hand-built reach graph (the edge stands in for the
# retargeted compat producer — compile.nix's `translateEffect kind=="spawn"` classes-form arm); the producer
# is exercised end-to-end in compat-batteries.nix (3b).
#
# The harness `let`-bindings (mkNode/mkStub/reachEdgeAct/mkRa/projectOver/projectReach/tags + the class-slice
# import) are COPIED VERBATIM from projection.nix — they are non-exported locals there.
{
  denHoag,
  denHoagSrc,
  ...
}:
let
  inherit (denHoag.internal)
    prelude
    resolve
    classifyKey
    scope
    aspects
    select
    ;

  # THE ONE per-aspect class-slice extraction (same functions the assembly threads to projectClass).
  cm =
    import "${denHoagSrc}/lib/attributes/class-modules.nix"
      {
        inherit prelude resolve;
      }
      {
        classNames = [ ];
        inherit classifyKey;
      };
  inherit (cm) classSliceOf;

  # projectClass replicated over a reach list (a pure class-slice fold over `reach id`).
  projectOver =
    reachList: class: prelude.concatMap (n: map (e: e.module) (classSliceOf n class)) reachList;

  # A synthetic resolved-aspect node `{ key; content }` (the reach node shape).
  mkNode = key: content: {
    inherit key content;
  };

  mkRa =
    import "${denHoagSrc}/lib/attributes/resolved-aspects.nix" {
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

  # every `tag` string reachable in a wrapped deferredModule (gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];

  # A host root with BOTH a home-manager aspect and a nixos-only aspect; an OPTED-IN cell (amy) carrying a
  # class-scoped home-manager reach-edge to it; a PLAIN cell (bob) with no edge. THE class-scoping is the F9
  # gate: amy reaches host-hm but NOT host-nixos.
  graph = {
    "host:h".resolved = [
      (mkNode "host-hm" { home-manager.tag = "host-hm"; })
      (mkNode "host-nixos" { nixos.tag = "host-nixos"; })
    ];
    "user:amy@host:h" = {
      resolved = [ (mkNode "opted-own" { home-manager.tag = "opted"; }) ];
      edges = [ (reachEdgeAct "host:h" "home-manager") ];
    };
    "user:bob@host:h".resolved = [ (mkNode "plain-own" { home-manager.tag = "plain"; }) ];
  };
  hmTags =
    id:
    builtins.concatMap tags (projectReach {
      inherit graph id;
      class = "home-manager";
    });
in
{
  flake.tests.projection-host-aspects = {
    # An opted-in cell reaches its OWN home-manager slice FIRST (own-subtree order), THEN the host's
    # home-manager slice through the class-scoped reach-edge (spec §7.1 opt-in projection).
    test-opted-reaches-host-hm-class-scoped = {
      expr = hmTags "user:amy@host:h";
      expected = [
        "opted"
        "host-hm"
      ];
    };
    # F9 NO OVER-REACH: the home-manager-scoped edge does NOT pull the host's nixos-only aspect.
    test-opted-no-nixos-overreach = {
      expr = builtins.elem "host-nixos" (hmTags "user:amy@host:h");
      expected = false;
    };
    # A plain cell (no opt-in edge) reaches only its OWN aspects — no host gather.
    test-plain-cell-own-only = {
      expr = hmTags "user:bob@host:h";
      expected = [ "plain" ];
    };
  };
}
