# Output stratum — HOAG attribute 12 (spec §2.10, Law A15). Two products over the SAME resolve eval:
#
#   (1) The gen-edge output fold. A graph accessor projects the resolve result into gen-edge's §2.3
#       contract (nodes/childrenOf/parentOf/isolatedAt/channelsOf/edgesAt/nameOf/contentsOf), and
#       `outputFor root = materialize { edges = toposort (edgesFor { graph, root }); projection =
#       project { graph, root, dials }; interpret; }` — THE toposorted fold, the only content path
#       (A15). `contentsOf` adapts gen-pipe channel contributions to gen-edge seeds (§2.10:
#       value→content, dedup identity→key, producer→provenance). `interpret` is a PARAMETER (default
#       `{ }`): native den-hoag constructs no `synthesize`/`rewalk` source, so it never supplies one;
#       den-compat threads its rewalk/synthesize interpreters in through `den.interpret` (mkDen), so the
#       legacy-edge seam is a real parameter here, not a source edit to this file.
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
# DEMAND EDGES (A11 — the A9 staging closed here): `demandEdges` is the fleet's gen-demand resolution
# rendered as inert gen-edge records (lib/demand.nix `toEdges`) — provider edges to output-arm sinks
# (`demands.<kind>.<key>`) and consumer edges to the subject's `wiring` root. They are FLEET-GLOBAL (one
# resolveAll per fleet, not per scope subtree), so `edgesFor`'s per-root subtree walk cannot gather them:
# the provider edges target output ARMS (which `edgesFor` filters out entirely, it keeps only root
# targets), and the consumer edges target a subject-identity root outside any single subtree. They are
# therefore CONCATENATED onto the per-root edge set before the one toposorted fold — `edgesFor {…} ++
# demandEdges` — so both join the fleet edge set (the trace) and materialize into config(root): providers
# under `config.outputs.demands.*`, consumers under `config.<subjectHash>.wiring`. Empty for a demand-free
# fleet ⇒ byte-identical to the pre-A11 fold (the append is `++ [ ]`).
#
# NO EFFECT RUNTIME: every body is field renames + attrset assembly + exactly one gen-edge call per
# algorithm (edgesFor/toposort/project/materialize) — Law A1. Deps: prelude, edge (the fold),
# bind (the config-thunk adaptation), classShare (the A10 gen-class tier-2 build path).
{
  prelude,
  edge,
  bind,
  merge,
  classShare,
}:
{
  result,
  classesByName,
  classOfNode,
  demandEdges ? [ ],
  # The gen-edge source interpreters (`{ synthesize ? …; rewalk ? …; }`), threaded through `den.interpret`.
  # Native den-hoag constructs no synthesize/rewalk edge, so the default `{ }` is complete; den-compat
  # supplies its legacy-edge interpreters here WITHOUT editing this file (spec §2.6, the A15 legacy seam).
  interpret ? { },
}:
let
  allNodeIds = builtins.attrNames result.allNodes;

  # Reserved channels (the demand machinery channel `__den-demands`) are internal wiring, not fleet
  # content — excluded from the edge fold's channel set.
  isReserved = ch: prelude.hasPrefix "__" ch;

  received = id: result.get id "received-collections";

  # Delivery declarations (den-compat's `deliver`/`route`/`provide`, `declare.delivery`) dispatched at a
  # node → gen-edge records, rendered HERE where the firing scope (the node id) and the collected
  # membership are known (the declaration itself is inert intent; C2). A native den-hoag fleet emits no
  # `delivery` declaration, so this is `[ ]` for it — byte-identical to the pre-delivery fold. Per-node
  # so `edgesFor` gathers each into the root it targets (the first-class `appendToParent`), and the
  # frozen trace picks it up (C7 traceHoag). NO-EFFECT-RUNTIME: the record is built from declaration
  # DATA, never stored dispatch state.
  #
  # Source arm mirrors v1: a class source collects the `from` class at the firing scope; a MODULE source
  # (provide) collects the TARGET class (edges/provides.nix:121 — the provided module rides the target
  # scope's own bucket). `members = [ id ]` is the own-scope collection (v1 simple-route default;
  # collectSubtree is Task 5). `adapt` applies to nest modes only (a merge edge carries none, gen-edge E).
  deliveryEdgesAt =
    id:
    let
      deliveries = builtins.filter (a: (a.__action or null) == "delivery") (
        (result.get id "declarations").actions.resolution or [ ]
      );
      renderDelivery =
        d:
        edge.edge {
          source = edge.sources.collected {
            scope = id;
            class = (if d.module != null then d.targetClass else d.sourceClass).name;
            members = [ id ];
          };
          target = edge.targets.root {
            root = id;
            class = d.targetClass.name;
          };
          inherit (d) path mode;
          adapt = if d.mode == "merge" then null else d.adaptArgs;
          annotations = d.annotations or { };
        };
    in
    map renderDelivery deliveries;

  # gen-edge graph accessor (§2.3). Isolation makes every non-root scope node its OWN edge-root: a
  # user cell (home-manager) is a distinct root from its host (nixos), so a host's subtree collects only
  # the host's own channel buckets — matching the direct gen-pipe read (Law A15 "no side channel").
  graphAccessor = {
    nodes = allNodeIds;
    childrenOf = id: builtins.attrNames (result.get id "children");
    parentOf = id: (result.node id).parent;
    isolatedAt = id: (result.node id).parent != null;
    channelsOf = id: builtins.filter (ch: !(isReserved ch)) (builtins.attrNames (received id));
    # den-hoag emits no aspect-scoped content edge natively; the per-node declared edges are den-compat's
    # delivery declarations (rendered above), and the fleet-global demand edges join by concatenation in
    # `outputFor`/`traceFor`. A delivery-free, demand-free fleet keeps `edgesAt id = [ ]`.
    edgesAt = deliveryEdgesAt;
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

  # The full edge set folded at a root: the per-root default-fold edges (gen-edge derivation over the
  # graph accessor) PLUS the fleet-global demand edges. Concatenation is A1 wiring; the derivation is the
  # lib call. This is the single edge set both `outputFor` (materialize) and `traceFor` (the frozen trace)
  # consume, so the demand edges join the fleet edge set exactly once and consistently in both views.
  edgesForRoot =
    root:
    edge.edgesFor {
      graph = graphAccessor;
      inherit root;
    }
    ++ demandEdges;

  # config(root) = the gen-edge fold (Law A15 — the exact E1 signature; `toposort` and `project`'s
  # `graph` are both mandatory). No content path outside this fold.
  outputFor =
    root:
    edge.materialize {
      edges = edge.toposort (edgesForRoot root);
      projection = edge.project {
        graph = graphAccessor;
        inherit root;
        dials = { };
      };
      inherit interpret; # the source-interpreter seam (default { }); den-compat threads legacy interpreters
    };

  # The frozen edge trace of a root — the parity oracle input (Law A15, stable + equal for equal
  # topologies). `den.graph.trace` re-exposes it. Includes the demand edges (they are inert, value-
  # sourced — `trace` renders only their identity, never resolved content, so it stays hashable).
  traceFor = root: edge.trace (edgesForRoot root);

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

  # The member (scope node) ids that carry NON-EMPTY content for a class — the class-major output map's
  # spine, and the class-share member set. Content-driven (a member with no content for `name` is absent).
  contentIdsOf =
    name:
    prelude.filter (
      id: memberClassName id == name && ((result.get id "class-modules").${name} or [ ]) != [ ]
    ) allNodeIds;

  # ── A10 class-share seam (share.core = true) ───────────────────────────────────────────────────────
  # The synthetic loc the shared class-invariant core occupies — `applyCoreFixed`'s sole-def leaf. A
  # member's DELTA (its class-modules) never defines it, so the core is the sole def there (spine skip).
  # NB: exported as `internal.classShareCoreAttr`; the no-fleet-flags suite detects the share path by
  # this exact value — keep in sync through the export, not by re-hardcoding.
  projectionPath = "denClassShareCore";

  # A member's config-independent (classInvariant) projection = the mkCore candidate set. Reads the
  # member's OWN channel emissions (attribute 10); a classInvariant contribution rides as a plain value
  # (gen-pipe E8 soundness), a per-member (deferred) one is excluded. mkCore intersects the KEYS across
  # members, so a member-varying channel value drops out of the core. Cheap channel data — forcing it
  # (for the shared core) never forces a member's class-modules (per-cell laziness, A17).
  projectionOf =
    id:
    let
      # attribute 10 stores, per channel, a list of gen-pipe CONTRIBUTIONS (post producer tie-break) —
      # each carries `classInvariant` (E8-sound: non-deferred ⇒ config-independent) and its plain `value`.
      local = result.get id "local-collection-data";
      invariantValsOf = ch: prelude.map (c: c.value) (prelude.filter (c: c.classInvariant) local.${ch});
    in
    builtins.listToAttrs (
      prelude.concatMap (
        ch:
        let
          vals = invariantValsOf ch;
        in
        if vals == [ ] then [ ] else [ (prelude.nameValuePair ch vals) ]
      ) (builtins.attrNames local)
    );

  # A member's DELTA module list — its wrapped class-modules, the gen-merge modules `applyCoreFixed`
  # merges beside the core. `wrapAll` is the SAME binding DI the ordinary terminal runs (r2 obligation 6);
  # done once, here, for the share path. A root `freeformType` absorbs the class-modules' undeclared
  # (nixpkgs-shaped) options: den-hoag's pure gen-merge merge carries no nixos option declarations, so
  # the shared build is an INSPECTABLE freeform config (the `collect` terminal's nixpkgs-free philosophy)
  # — a REAL nixos build crosses through the nixpkgs terminal, not this tier-2 path.
  freeformAbsorber = {
    freeformType = merge.anything;
  };
  deltaOf =
    name: classCfg: id:
    [ freeformAbsorber ]
    ++ (bind.wrapAll {
      modules = (result.get id "class-modules").${name} or [ ];
      bindings = bindingsAt id;
      defaultMergeStrategy = classCfg.defaultMergeStrategy;
    }).modules;

  # systems.<class>.<member> — the per-member built artifact. Class-major + content-driven (the gen-flake
  # `realize` shape): `builtins.attrNames systems.<class>` IS the member set, forced without forcing any
  # artifact (one build per member, per-cell lazy — Law A17). Per class (NEVER a fleet switch — A17):
  #   • share.core = true  → the A10 gen-class tier-2 path: partition members by class entry id_hash,
  #       compose the class-invariant core once, byte-gate each member (loud on divergence — A18), and
  #       build via `applyCoreFixed`. The shared core forces every member's PROJECTION, never their DELTAS.
  #   • share.core = false → the ordinary terminal crossing (`classCfg.instantiate`, Task 9), unchanged.
  systems = prelude.mapAttrs (
    name: classCfg:
    let
      contentIds = contentIdsOf name;
    in
    if classCfg.share.core then
      let
        shared = classShare.build {
          members = builtins.listToAttrs (
            prelude.map (id: prelude.nameValuePair id (result.node id)) contentIds
          );
          classOf = classOfNode;
          inherit projectionOf projectionPath;
          shareCore = true;
        };
      in
      builtins.listToAttrs (
        prelude.map (id: {
          name = id;
          # Gate BEFORE the build (A18): a divergent core aborts named; a sound one yields the
          # applyCoreFixed config. `seq` forces the authorization ahead of the delta merge.
          value = builtins.seq (shared.authorize id (projectionOf id)) (
            shared.outputFor id (deltaOf name classCfg id)
          );
        }) contentIds
      )
    else
      builtins.listToAttrs (
        prelude.map (id: {
          name = id; # the member (scope node) id keys the class-major output map
          value = classCfg.instantiate {
            name = id; # the terminal contract's `name` is the member id
            hostModules = (result.get id "class-modules").${name} or [ ];
            inherit classCfg;
            bindings = bindingsAt id;
          };
        }) contentIds
      )
  ) classesByName;
in
{
  inherit
    graphAccessor
    edgesForRoot
    outputFor
    traceFor
    systems
    deferredToThunk
    ;
}
