# Output stratum — HOAG attribute 12 (spec §2.10, Law A15). Two products over the SAME resolve eval:
#
#   (1) The gen-edge output fold. A graph accessor projects the resolve result into gen-edge's §2.3
#       contract (nodes/childrenOf/parentOf/isolatedAt/channelsOf/edgesAt/nameOf/contentsOf), and
#       `outputFor root = materialize { edges = toposort (edgesFor { graph, root }); projection =
#       project { graph, root, dials }; interpret = {}; }` — THE toposorted fold, the only content path
#       (A15). `contentsOf` adapts gen-pipe channel contributions to gen-edge seeds (§2.10:
#       value→content, dedup identity→key, producer→provenance). `interpret` is threaded empty here
#       (den-hoag constructs no legacy edge); den-compat supplies rewalk/synthesize interpreters.
#
#   (2) The per-class terminal crossing. `systems.<class>.<member>` instantiates each member (a scope
#       node whose producing class is that class, carrying non-empty `class-modules` content) via the
#       class's terminal (`classCfg.instantiate`). The output map is class-major and content-driven
#       (gen-flake `realize` shape): its SPINE is the member keys, so forcing it counts instantiations
#       without forcing an artifact (one instantiate per member, per-cell lazy — Law A17).
#
# Deferred channel contributions (config-thunks, PR #623) ride the fold's seed content UNFORCED and,
# for the terminal, are adapted to gen-bind `__configThunk` markers (`deferredToThunk`) so the terminal
# resolves them against the PRODUCING class+scope's config — the gen-merge/gen-flake terminal forces
# them there (resolve-at-producing-scope, decision #27).
#
# NO EFFECT RUNTIME: every body is field renames + attrset assembly + exactly one gen-edge call per
# algorithm (edgesFor/toposort/project/materialize) — Law A1. Deps: prelude, edge (the fold),
# bind (the config-thunk adaptation).
{
  prelude,
  edge,
  bind,
}:
{
  result,
  classesByName,
  classOfNode,
}:
let
  allNodeIds = builtins.attrNames result.allNodes;

  # Reserved channels (the demand machinery channel `__den-demands`) are internal wiring, not fleet
  # content — excluded from the edge fold's channel set.
  isReserved = ch: prelude.hasPrefix "__" ch;

  received = id: result.get id "received-collections";

  # gen-edge graph accessor (§2.3). Isolation makes every non-root scope node its OWN edge-root: a
  # user cell (home-manager) is a distinct root from its host (nixos), so a host's subtree collects only
  # the host's own channel buckets — matching the direct gen-pipe read (Law A15 "no side channel").
  graphAccessor = {
    nodes = allNodeIds;
    childrenOf = id: builtins.attrNames (result.get id "children");
    parentOf = id: (result.node id).parent;
    isolatedAt = id: (result.node id).parent != null;
    channelsOf = id: builtins.filter (ch: !(isReserved ch)) (builtins.attrNames (received id));
    edgesAt = _id: [ ]; # v1: no per-node declared content edges; demand-edge materialization is A11
    nameOf = id: id;
    # collection → edge-seed adaptation (§2.10). A deferred contribution's `value` is a poison thunk
    # (gen-pipe E6) — carried here UNFORCED (normalizeSeed never forces content), resolved only at a
    # consuming class terminal. gen-pipe stores no dedup key on a contribution (§4.5), so `key = null`
    # (never deduped), matching the class-neutral / null-key contributions the fixtures produce.
    contentsOf =
      id: channel:
      map (c: {
        content = c.value;
        key = c.__key or null;
        provenance = {
          edge = null;
          source = "seed";
          producer = c.producer;
        };
      }) ((received id).${channel}.contributions or [ ]);
  };

  # config(root) = the gen-edge fold (Law A15 — the exact E1 signature; `toposort` and `project`'s
  # `graph` are both mandatory). No content path outside this fold.
  outputFor =
    root:
    edge.materialize {
      edges = edge.toposort (
        edge.edgesFor {
          graph = graphAccessor;
          inherit root;
        }
      );
      projection = edge.project {
        graph = graphAccessor;
        inherit root;
        dials = { };
      };
      interpret = { }; # threaded from den-compat when present; empty here
    };

  # The frozen edge trace of a root — the parity oracle input (Law A15, stable + equal for equal
  # topologies). `den.graph.trace` re-exposes it.
  traceFor =
    root:
    edge.trace (
      edge.edgesFor {
        graph = graphAccessor;
        inherit root;
      }
    );

  # ── terminal crossing ────────────────────────────────────────────────────────────────────────────
  # Adapt a deferred gen-pipe contribution to a gen-bind config-thunk (resolve-at-producing-scope, PR
  # #623 parity): the thunk carries the producing scope; gen-bind's `wrapAll` resolves its `fn` against
  # the PRODUCING class's config when the terminal forces it. `__sourceScope` records the producing scope.
  deferredToThunk = c: bind.mkThunkFrom c.producer.scope c.fn;

  # A member's own channel emissions, adapted to terminal bindings: a deferred emission becomes a
  # gen-bind config-thunk (resolved at THIS member's producing config), a plain emission its value.
  # gen-bind's wrapAll auto-detects the thunk list entries and resolves them at eval (the terminal).
  channelBindingsAt =
    id:
    let
      local = result.get id "local-collection-data";
    in
    builtins.mapAttrs (
      _: contribs: map (c: if c.deferred then deferredToThunk c else c.value) contribs
    ) local;

  # The binding set handed to a member's class modules: the node's entity bindings (host/user/env
  # entries + enrichments) plus its own resolved channel emissions.
  bindingsAt = id: (result.get id "enriched-context") // channelBindingsAt id;

  memberClassName =
    id:
    let
      c = classOfNode (result.node id);
    in
    if c == null then null else c.name;

  # systems.<class>.<member> — one terminal instantiation per member of the class carrying content.
  # Class-major + content-driven (the gen-flake `realize` shape): a member with no content for a class
  # never appears under it, so `builtins.attrNames systems.<class>` IS the instantiated-member set.
  systems = prelude.mapAttrs (
    name: classCfg:
    builtins.listToAttrs (
      prelude.concatMap (
        id:
        let
          hostModules = (result.get id "class-modules").${name} or [ ];
        in
        if memberClassName id == name && hostModules != [ ] then
          [
            {
              name = id; # the member (scope node) id keys the class-major output map
              value = classCfg.instantiate {
                name = id; # the terminal contract's `name` is the member id
                inherit hostModules classCfg;
                bindings = bindingsAt id;
              };
            }
          ]
        else
          [ ]
      ) allNodeIds
    )
  ) classesByName;
in
{
  inherit
    graphAccessor
    outputFor
    traceFor
    systems
    deferredToThunk
    ;
}
