# Output stratum — HOAG attribute 12 (spec §2.10, Law A15). Two products over the SAME resolve eval:
#
#   (1) The gen-edge output fold. A graph accessor projects the resolve result into gen-edge's §2.3
#       contract (nodes/childrenOf/parentOf/isolatedAt/channelsOf/edgesAt/nameOf/contentsOf), and
#       `outputFor root = materialize { edges = toposort (edgesFor { graph, root }); projection =
#       project { graph, root, dials }; interpret; }` — THE toposorted fold, the only content path
#       (A15). `contentsOf` adapts gen-pipe channel contributions to gen-edge seeds (§2.10:
#       value→content, dedup identity→key, producer→provenance). `interpret` is a PARAMETER (default
#       `{ }`): native den-hoag constructs no `synthesize`/`rewalk` source, so it never supplies one;
#       an external consumer threads its rewalk/synthesize interpreters in through `den.interpret` (mkDen), so the
#       external source-interpreter seam is a real parameter here, not a source edit to this file.
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
# algorithm (edgesFor/toposort/project/materialize) — Law A1. Deps: prelude, scope (the descendants
# id-spine walk for the #62c delivery-edge subtree), edge (the fold), bind (the config-thunk adaptation),
# classShare (the A10 gen-class tier-2 build path).
{
  prelude,
  scope,
  edge,
  bind,
  merge,
  classShare,
}:
{
  result,
  classesByName,
  classOfNode,
  # The REGISTERED channel names (`attrNames den.quirks`) — the terminal binding surface's totality
  # domain (see `bindingsAt`). Required, not defaulted: the channel-binding law is total over the
  # registration set, so the caller must state it (a defaulted `[ ]` would silently reopen the
  # absent-key defect the law closes).
  channelNames,
  demandEdges ? [ ],
  # The gen-edge source interpreters (`{ synthesize ? …; rewalk ? …; }`), threaded through `den.interpret`.
  # Native den-hoag constructs no synthesize/rewalk edge, so the default `{ }` is complete; an external consumer
  # supplies its external source interpreters here WITHOUT editing this file (spec §2.6, the A15 external-source seam).
  interpret ? { },
  # The POST-RESOLUTION binding-enrichment hook (threaded through `den.enrichBindings`). A consumer may
  # enrich a node's entity bindings AFTER resolution — the hook receives per-node
  # `{ id; resolvedAspects; bindings }` and returns the enriched bindings. `resolvedAspects` is the node's
  # attribute-7 THUNK (`result.get id "resolved-aspects"`); the hook MUST preserve laziness (A17): forcing
  # `bindingsAt`/the systems spine must NOT force `resolvedAspects` — only a closure the hook stamps onto a
  # binding (e.g. a projected `hasAspect`) may, when it is actually called. Native den-hoag supplies the
  # identity default (`{ bindings, ... }: bindings`), so the native binding surface is byte-identical.
  enrichBindings ? ({ bindings, ... }: bindings),
  # The named PER-NODE CHANNEL-AUGMENTATION seam (#62a, threaded through `den.channelGather`). A supplier
  # augments the channel value bound to a class module's formals with contributions GATHERED from beyond the
  # node's own emissions — `channelGather { id; result; } -> { <channel> = [ contribution ]; }`, appended
  # AFTER the node's local emissions in `channelBindingsAt` (F4: bound = local ++ gathered). The gathered
  # records carry local-collection-data's contribution shape (`.deferred`/`.value`/`.producer`), so they
  # extract through the SAME `deferredToThunk` path (a gathered deferred contribution resolves at ITS OWN
  # producing scope — resolve-at-producing, decision #27). Native den-hoag supplies the empty default
  # (`_: { }`), so the augmentation is `local ++ [ ]` at every channel — the KNOWN CEILING (`bindingsAt`
  # reads OWN emissions) unchanged, the binding surface byte-identical (the 810 identity tests are the proof).
  # An external consumer wires its gather supplier here (e.g. the v1 expose-ascent twin, #62b). A17: `result`
  # is the eval passed opaquely; a supplier that walks it must stay lazy over the id spine (never force all
  # descendants' resolved-aspects).
  channelGather ? (_: { }),
}:
let
  allNodeIds = builtins.attrNames result.allNodes;

  # Reserved channels (the demand machinery channel `__den-demands`) are internal wiring, not fleet
  # content — excluded from the edge fold's channel set.
  isReserved = ch: prelude.hasPrefix "__" ch;

  received = id: result.get id "received-collections";

  # ── class content as fold coordinates (§2.10 default-fold reconciliation) ──────────────────────────
  # gen-edge is class-coordinate-generic (its README: "den's NixOS class buckets … are ONE instantiation")
  # — a class bucket IS a fold channel. den-hoag's attribute 9 (`class-modules`) computes, per node, the
  # `{ <class> = [ deferredModule ]; }` map; here it joins the graph accessor's channel view so class
  # content folds through the SAME gen-edge pipeline as quirk channels: a scope emits one
  # `collected:scope/<class> | merge` default-fold edge for its PRODUCING class (matching v1's
  # `defaultFoldEdges` by construction, edges/default.nix Corollary 1), and a `deliver`/`route`/`provide`
  # whose collected source names a CLASS moves that class's real content (before this, a class-source
  # delivery traced but its collected read hit an absent channel ⇒ empty — the C7.5 gap).
  #
  # PRODUCING-CLASS scoping (§2.5, mirrors the terminal): `class-modules` over-reports — the aspect
  # submodule's freeform gives EVERY class key a trivial `{ imports = [ ]; }` body even for an aspect that
  # declares no content there, so a bare-channel aspect at a nixos host shows non-empty nixos/home-manager/
  # k8s-manifests buckets alike. The terminal's `contentIdsOf` already resolves this by keying on the
  # node's OWN producing class (`memberClassName`); the default fold does the SAME here (one class per
  # scope — den-hoag's contentClass model), so a nixos host folds `nixos` (never a phantom k8s edge) and a
  # home-manager cell folds `home-manager`. Cross-class content movement is the EXPLICIT deliver/inject
  # edge, never the default fold. NO-EFFECT-RUNTIME: one attribute read + one list non-emptiness test on
  # the bucket spine (never a module body — deferred class content is a `deferredModule` thunk carried
  # UNFORCED, so presence stays A17-lazy exactly like `channelsOf` over quirks).
  isClassName = cn: classesByName ? ${cn};
  classModulesAt = id: result.get id "class-modules";

  # ── #63 within-class subtree fold (design note §8, the #62c twin for class content) ─────────────────
  # A node's within-class content assembly gathers the SAME class bucket from `[ id ] ++ scope.descendants
  # result id` (own-first ++ lexicographic-DFS descendants — A12; v1 own-first, no dedup). This is v1's
  # `defaultFoldEdges` NESTING fold (edges/default.nix, Corollary 1) rendered where a no-isolated-KIND
  # corpus collapses the isolation-AWARE subtree to the blind descendants walk: `den.schema.user.parent =
  # "host"` (options.nix:112) + `isolated` defaults false (options.nix:85-88; push-scope.nix:64) + the
  # corpus marks no kind isolated, so a user scope nests non-isolated under its host and
  # `collected(subtree, <class>) → (host, <class>)` gathers the descendant cells' class buckets —
  # `define-user` emits nixos+darwin+homeManager class content into a home-manager-PRODUCING user cell
  # (define-user.nix:25-42), and that nixos bucket (`users.users.<n>` + the user shell) rides here to the
  # host's nixos assembly. Consumed at the class-content reads feeding the TERMINAL (`hostModules`/`deltaOf`/
  # `contentIdsOf`) AND the default-fold edge (`classBucketsOf`/`contentsOf`); `projectionOf` STAYS own-scope
  # (class-share's config-invariant core is untouched). Gated to the class in question (same-class buckets
  # only), so cross-class content movement stays the explicit deliver/inject edge, never this fold.
  #
  # ISOLATION-MARK CEILING (§8 risk 2, the #62c twin's ceiling): the walk is BLIND — a future KIND marked
  # `isolated` would need this gather to honor the isolation boundary v1's isolation-aware fold stops at
  # (none is marked in this corpus; the same ceiling `scope.descendants`'s #62c consumer carries).
  # A17: `class-modules` is a deferredModule list carried UNFORCED; `descendants` is the lazy id spine —
  # this walks the bucket SPINE (list appends), never a module body. IDENTITY: a cell-less / descendant-less
  # node ⇒ `[ id ]` ⇒ `(classModulesAt id).${class}` exactly (the 820 baseline is the proof — unchanged).
  classSubtreeAt =
    id: class:
    prelude.concatMap (nid: (classModulesAt nid).${class} or [ ]) (
      [ id ] ++ scope.descendants result id
    );

  producingClassOf =
    id:
    let
      c = classOfNode (result.node id);
    in
    if c == null then null else c.name;
  classBucketsOf =
    id:
    let
      cn = producingClassOf id;
    in
    if cn != null && classSubtreeAt id cn != [ ] then [ cn ] else [ ];

  # Delivery declarations (an external consumer's `deliver`/`route`/`provide`, `declare.delivery`) dispatched at a
  # node → gen-edge records, rendered HERE where the firing scope (the node id) and the collected
  # membership are known (the declaration itself is inert intent; C2). A native den-hoag fleet emits no
  # `delivery` declaration, so this is `[ ]` for it — byte-identical to the pre-delivery fold. Per-node
  # so `edgesFor` gathers each into the root it targets (the first-class `appendToParent`), and the
  # frozen trace picks it up (C7 traceHoag). NO-EFFECT-RUNTIME: the record is built from declaration
  # DATA, never stored dispatch state.
  #
  # Source arm mirrors v1: a class source collects the `from` class at the firing scope; a MODULE source
  # (provide) collects the TARGET class (edges/provides.nix:121 — the provided module rides the target
  # scope's own bucket). SUBTREE COLLECTION (#62c, the flagged Task 5): `members = [ id ] ++ scope.descendants
  # result id` — a host-fired forward/route edge gathers the firing scope's class content AND its descendant
  # cells' (the home-manager.users half: a user cell's home-manager content, delivered at the host terminal).
  # gen-edge isolates each cell as its own edge-root (`isolatedAt`), so this explicit member list is how the
  # collected source reaches ACROSS those isolated roots — the members are named, not walked by the per-root
  # subtree fold. `descendants` is the lazy id-spine walk (self-EXCLUDING; `[ id ] ++ descendants` = the
  # subtree, self first — A17: ids only, never a descendant's forced content). A leaf-scope or childless
  # firing node has an empty descendant set ⇒ `[ id ]`, byte-identical to the pre-#62c own-scope collection.
  #
  # GUARD / ADAPTARGS are EVAL-TIME transforms, NOT fold content-transforms (C7.5). v1 applies them at
  # module assembly: `guardModule` gates config via `optionalAttrs (guard args)` and `adaptArgs` rewrites
  # the module ARGS through a nested `evalModules` (`nestWithAdaptArgs`, route.nix) — both need the module
  # eval environment (`args`/`config`), which the pure fold does not have. gen-edge's `adapt` has the
  # signature `content -> Π -> content` (a content rewriter, e.g. path placement), NOT an arg-adapter:
  # routing a v1 `adaptArgs = args: args // …` through it materializes `adaptArgs content Π`, which aborts
  # ("attempt to call something which is not a function"). So the fold carries NO `adapt`; the closures
  # ride on the declaration (`d.guard`/`d.adaptArgs`) and the trace annotations record their PRESENCE
  # (booleans — hashable, `traceEntryOf` renders `annotations`). Their active application is the terminal
  # crossing (the nixpkgs `evalModules` boundary, where `args` exist) — the C8 content-oracle path; here
  # the edge is the faithful TRACE (the C7.5 deliverable): it always renders, gated or not (v1 parity —
  # a guard gates content, never rule-firing, so the edge is present in both arms' traces).
  deliveryEdgesAt =
    id:
    let
      # A delivery flagged `__dropped` is a DEFINED NO-OP — its target resolved to an absent/null class, so
      # it renders no edge (a route emitted probe-safe by an emitter that gates value-conditionally, yet
      # INERT at a firing scope whose target is absent). A native fleet emits none; every ordinary delivery
      # has `__dropped` unset, so this filter is byte-identical for one.
      deliveries = builtins.filter (a: (a.__action or null) == "delivery" && !(a.__dropped or false)) (
        (result.get id "declarations").actions.resolution or [ ]
      );
      renderDelivery =
        d:
        edge.edge {
          source = edge.sources.collected {
            scope = id;
            class = (if d.module != null then d.targetClass else d.sourceClass).name;
            # #62c — the firing scope PLUS its descendant cells (Task 5): the host-fired route gathers the
            # user cells' class content (self first, lazy ids; empty descendant set ⇒ own-scope, unchanged).
            members = [ id ] ++ scope.descendants result id;
          };
          target = edge.targets.root {
            root = id;
            class = d.targetClass.name;
          };
          inherit (d) path mode;
          adapt = null; # guard/adaptArgs are eval-time terminal transforms (see above), never a fold adapt
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
    channelsOf =
      id: builtins.filter (ch: !(isReserved ch)) (builtins.attrNames (received id)) ++ classBucketsOf id;
    # den-hoag emits no aspect-scoped content edge natively; the per-node declared edges are an external consumer's
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
      if isClassName channel then
        # class coordinate: the node's own class-modules bucket as seed contributions. Each contribution's
        # `content` is a deferredModule (a gen-bind-shaped module, possibly a `{ config, … }` thunk) carried
        # UNFORCED — the fold moves it, the terminal forces it. Null key (class modules are dedup-keyed by
        # the gen-merge/module system at build, not the fold — §4.5 class-neutral null-key contributions).
        map (m: {
          content = m;
          key = null;
          provenance = {
            edge = null;
            source = "seed";
            producer = null;
          };
        }) (classSubtreeAt id channel)
      else
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
      inherit interpret; # the source-interpreter seam (default { }); an external consumer threads external interpreters
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

  # A single contribution → its terminal-binding value: a deferred emission becomes a gen-bind config-thunk
  # (resolved at THAT contribution's producing config), a plain emission its value. gen-bind's wrapAll
  # auto-detects the thunk list entries and resolves them at eval (the terminal). Used for BOTH the node's
  # own emissions AND the gathered ones (#62a) — a gathered deferred contribution keeps its OWN producer
  # scope, so it resolves where it was produced, not at the consuming node.
  extractContribution = c: if c.deferred then deferredToThunk c else c.value;

  # A member's channel bindings: its OWN emissions AUGMENTED by the per-node gather (#62a). Per channel the
  # bound value is `local ++ gathered` (F4 — v1 `mkCombinedBase`'s `markedBase ++ markedExposed`,
  # assemble-pipes.nix:935-948). The key set is TOTAL over both maps so a channel a node NEVER emits locally
  # but RECEIVES by gather (`resolved-users` at a host — the ship-gate corpus shape) is present, not dropped
  # by an own-emissions-only key set. Native default gather (`_: { }`) ⇒ `local ++ [ ]` at every own channel
  # and no extra keys ⇒ byte-identical to the pre-seam `mapAttrs` over local alone.
  channelBindingsAt =
    id:
    let
      local = result.get id "local-collection-data";
      gathered = channelGather { inherit id result; };
    in
    prelude.genAttrs (builtins.attrNames (local // gathered)) (
      ch: map extractContribution ((local.${ch} or [ ]) ++ (gathered.${ch} or [ ]))
    );

  # The binding set handed to a member's class modules: the node's entity bindings (host/user/env
  # entries + enrichments) plus the fleet's channel bindings.
  #
  # CHANNEL TOTALITY (the native law): a REGISTERED channel is a named binding surface whose
  # collected value at any node is TOTAL — the EMPTY collection when nothing is emitted there,
  # analogous to an option's default. The absent key was the defect: gen-bind's `wrapAll` binds a
  # module arg iff the binding KEY exists (gen-bind wrap.nix `boundArgNames`), so a class module
  # destructuring a channel arg (`{ firewall, lib, ... }:`) at a node with zero emissions on that
  # channel was passed through unwrapped and the evaluator called it without its required argument —
  # at the first FORCING terminal only (the nixpkgs crossing; the `collect` terminal never forces,
  # which is why the gap stayed latent). den v1 parity CONFIRMS the law, it is not its source
  # (pin 11866c16 assemble-pipes.nix:951 `lib.genAttrs pipeNames` — every registered pipe is
  # ctx-present at every scope, empty or not).
  #
  # KNOWN CEILING (out of scope here): the per-channel value is the node's OWN emissions
  # (attribute 10). A bare channel-arg consumer of a channel moved by a collect/broadcast POLICY
  # would under-read through this surface — such a consumer needs the received-collections read
  # (`consumeAt`), not the local binding. The corpus's two bare-arg consumers (`firewall`,
  # `age-secrets`) are host-local channels with no collect/broadcast policy (nix-config
  # policies/pipes.nix declares none for either), so local ≡ received for both.
  bindingsAt =
    id:
    # The consumer-supplied post-resolution enrichment (default = identity, native den-hoag untouched).
    # `resolvedAspects` is passed UNFORCED (the attribute-7 thunk): forcing this binding set does not force
    # it — only a stamped closure the hook actually calls does (A17 — the external binding-enrichment seam).
    enrichBindings {
      inherit id;
      resolvedAspects = result.get id "resolved-aspects";
      bindings =
        (result.get id "enriched-context")
        // prelude.genAttrs channelNames (_: [ ])
        // channelBindingsAt id;
    };

  memberClassName =
    id:
    let
      c = classOfNode (result.node id);
    in
    if c == null then null else c.name;

  # The member (scope node) ids that carry NON-EMPTY content for a class — the class-major output map's
  # spine, and the class-share member set. Content-driven (a member with no content for `name` is absent).
  contentIdsOf =
    name: prelude.filter (id: memberClassName id == name && classSubtreeAt id name != [ ]) allNodeIds;

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
      modules = classSubtreeAt id name;
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
            hostModules = classSubtreeAt id name;
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
