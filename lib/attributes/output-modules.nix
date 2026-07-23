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
# id-spine walk for the #62c delivery-edge subtree AND the #66 terminal delivery gather), edge (the
# fold), bind (the config-thunk adaptation), merge (the class-share freeform absorber), classShare (the
# A10 gen-class tier-2 build path), errors (the #66 single-path guard — a same-class merge delivery that
# would double with the fold aborts LOUD, never silently).
{
  prelude,
  scope,
  edge,
  bind,
  merge,
  classShare,
  errors,
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
  # The §7 projection filter — `[edges] -> [edges]` keeping only `to ∈ { materialize, both }` kinds (the
  # `edgesLib.materializeEdges <compiledKinds>` closure, wired at mkDen). It formalizes the off-trace seam:
  # relation (`to = query`) edges never reach the materialize trace. Default = identity, so a fixture that
  # instantiates mkOutputModules directly (no filter wired) is byte-identical, and the corpus is unaffected
  # (relation edges live in a separate pool never merged into `edgesForRoot`, so the filter drops nothing).
  materializeFilter ? (edges: edges),
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
  # node's own emissions — `channelGather derivedBaseNames result id -> { <channel> = [ contribution ]; }`,
  # CURRIED on `derivedBaseNames` (the base→terminal map, so the broadcast arm reads a source's transformed
  # terminal) then `result` so the supplier binds it ONCE (`channelGatherR`, hoisted below) and can precompute
  # per-fleet indices shared across every consumer id; applied per node in `channelBindingsAt` (F4: bound =
  # local ++ gathered). The gathered records carry local-collection-data's contribution shape (`.deferred`/
  # `.value`/`.producer`), so they extract through the SAME `deferredToThunk` path (a gathered deferred
  # contribution resolves at ITS OWN producing scope — resolve-at-producing, decision #27). Native den-hoag
  # supplies the empty default (`_: _: _: { }`), so the augmentation is `local ++ [ ]` at every channel — the
  # KNOWN CEILING (`bindingsAt` reads OWN emissions) unchanged, the binding surface byte-identical (the 810
  # identity tests are the proof). An external consumer wires its gather supplier here (e.g. the v1 gather
  # twin, #62b). A17: `result` is the eval passed opaquely; a supplier that walks it must stay lazy over the
  # id spine (never force all descendants' resolved-aspects), and `channelGather … result` must not force it
  # eagerly.
  channelGather ? (
    _: _: _:
    { }
  ),
  # base channel → [ terminal name … ] for the untargeted-deriving supersede (built fleet-wide in
  # lib/default.nix from the renamed pipe terminals). At the binding grain a base channel with an
  # untargeted deriving pipe reads its terminal(s)' collections in place of the raw base (v1
  # `applyPipeEffects` REPLACES the consumed value); multiple policies on one base concatenate,
  # per-policy from the base values. Native default = `{ }` (no untargeted deriving pipe) ⇒ identity.
  derivedBaseNames ? { },
  # THE ONE per-aspect class-slice extraction (Task 2, `attributes/class-modules.nix classSliceOf`, threaded
  # through `attributesLib.mkClassSlice` with the discovered `classifyKey`). `classSliceOf aspect class`
  # returns that aspect's `class`-C bucket contribution as `[ { module; shared; } ]` (0 or 1) — `projectClass`
  # maps `.module` (bare, the classSubtreeAt anchor). Native default reproduces the bucket read locally but is
  # ALWAYS supplied by den-hoag's assembly (the class-modules extraction is the single source); the default is
  # a defensive identity for a caller that constructs `mkOutputModules` standalone without the extraction.
  classSliceOf ? (
    _: _: _:
    [ ]
  ),
  # §2.2 TOTALITY assertion (Task 3, `class-modules.nix assertKeysRegistered`). Forces classification of every
  # non-`_` content key of a REACHED aspect (abort NAMED on a genuinely unregistered typo key); `projectClass`
  # runs it per reached aspect so a typo cannot silently vanish on the drv path (spec §2.2 ruling 2026-07-14).
  # Native default is the no-op identity (standalone callers without the extraction skip the totality check).
  assertKeysRegistered ? (_: _: null),
  # iv-b — the reach's forward-source-class set (`class-modules.nix forwardSourceClassesOf`): the unregistered
  # `fromClass` keys a `meta.__forward` spec on a reached node names, EXEMPTED from the §2.2 typo-abort so
  # their bucket materializes for `routeRemapFor`. Native default = `{ }` (no forward ⇒ byte-identical).
  forwardSourceClassesOf ? (_: { }),
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
  # PRODUCING-CLASS scoping (§2.5, mirrors the terminal): a scope emits its default-fold edge for its ONE
  # PRODUCING class (`producingClassOf`, den-hoag's contentClass model) — a nixos host folds `nixos` (never a
  # phantom k8s edge), a home-manager cell folds `home-manager`. The fold fires on producing-class MEMBERSHIP,
  # NOT on bucket non-emptiness: a bare-channel host (its aspects emit only quirk content, no nixos class body
  # — edge-completeness `axon`) still emits `collected:scope/nixos | merge`, matching v1's `defaultFoldEdges`
  # (which folds a producing class unconditionally). `class-modules` now drops EMPTY class buckets (the typed
  # `{ imports = [ { } ]; }` no-op — `classSliceOf` isEmptyModule, so a delivered bucket carries only REAL
  # content, no double-count), so emptiness can no longer gate the fold; producing-class presence does. Cross-
  # class content movement is the EXPLICIT deliver/inject edge, never the default fold. NO-EFFECT-RUNTIME: one
  # producing-class read (the node's contentClass) — never a module body (deferred content stays A17-lazy).
  isClassName = cn: classesByName ? ${cn};
  classModulesAt = id: result.get id "class-modules";
  # The KEYED class buckets (`{ <class> = [ { module; sharedFoldKey } ]; }`) — `classSubtreeAt` reads THIS
  # (not the bare public `class-modules`) so it can collapse a genuinely-shared host+user aspect cross-scope.
  classModulesKeyedAt = id: result.get id "class-modules-keyed";
  inherit (import ../dedup-by-key.nix { inherit prelude; }) dedupByKey;

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
  # this walks the bucket SPINE (list appends), never a module body. FORCING HONESTY: the gather DOES newly
  # force each descendant's `class-modules` ATTRIBUTE — i.e. the §2.2 key CLASSIFICATION of every content
  # key on the descendant's resolved aspects (the mechanism that surfaced the ledger-u14 `wsl` abort: cells
  # whose class-modules were previously never read now classify at the host's assembly) — while the module
  # BODIES inside each bucket stay unforced (the A17 claim above is about bodies, and stays true). IDENTITY:
  # a cell-less / descendant-less node ⇒ `[ id ]` ⇒ `(classModulesAt id).${class}` exactly (the 820 baseline
  # is the proof — unchanged).
  # CROSS-SCOPE SHARED-ASPECT DEDUP (v1 `wrapPerScope` `dedupByKey`, resolve.nix:43-66 @ pin 11866c16 — the
  # `classSubtreeAt` twin of the reach dedup, resolved-aspects.nix). The keyed subtree buckets are gathered
  # own-first ++ descendants, then a genuinely-shared host+user aspect (same `sharedFoldKey` at the host AND
  # its cell — a `den.default` module) collapses first-occurrence-wins to the host's copy; a `null` key (a
  # node-local inject/reroute, a static-anon or non-entity-ctx aspect) is never deduped (v1 anon rule); and
  # genuinely per-cell content (distinct `user`/guest `id_hash` ⇒ distinct key) is kept — so the output-fold
  # (`contentsOf`/`classBucketsOf`/the default-fold edge) and the `projectClass` anchor stay byte-consistent
  # with the deduped terminal. Map back to the bare `.module` list the readers expect.
  classSubtreeAt =
    id: class:
    map (e: e.module) (
      dedupByKey (e: e.sharedFoldKey or null) (
        prelude.concatMap (nid: (classModulesKeyedAt nid).${class} or [ ]) (
          [ id ] ++ scope.descendants result id
        )
      )
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
    if cn == null then
      [ ]
    else
      # Fire the default fold for the producing class UNCONDITIONALLY (bare-channel hosts fold too), but STILL
      # force the node's class-modules classification — the §2.2 side-effect that aborts a typo'd content key
      # on a reached aspect (`assertKeysRegistered`/`classifyKey`), which the pre-empty-drop emptiness test
      # used to trigger. `seq` forces the bucket spine (classification) without gating the fold on its result.
      builtins.seq (classSubtreeAt id cn) [ cn ];

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
  # The delivery declarations present at a node (the resolution-stratum `delivery` actions). A delivery
  # flagged `__dropped` is a DEFINED NO-OP — its target resolved to an absent/null class, so it renders no
  # edge (a route emitted probe-safe by an emitter that gates value-conditionally, yet INERT at a firing
  # scope whose target is absent). A native fleet emits none; every ordinary delivery has `__dropped`
  # unset, so this filter is byte-identical for one. The firing-scope delivery set the edge renderer
  # (`deliveryEdgesAt`, the trace) reads.
  deliveriesAt =
    id:
    builtins.filter (a: (a.__action or null) == "delivery" && !(a.__dropped or false)) (
      (result.get id "declarations").actions.resolution or [ ]
    );

  # The ROOT a delivery fired at node `id` targets. IDENTITY-DEFAULTED to the firing scope (`id`) — v1's
  # route/forward appends into the target class bucket AT the firing scope. #53c (§9 item 3): a delivery
  # declaring `appendToParent` targets the containment PARENT root — v1's route property (pin 11866c16
  # nix/lib/aspects/fx/edges/route.nix:364 `appendToParent = route.appendToParent or false`, target
  # resolution :370-377 `appendScopeIdOf`), rendered here as the first-class parent-targeting edge
  # gen-edge's derivation already gathers ("a child scope may declare an edge targeting the parent root
  # — the first-class form of v1 appendToParent", derive.nix:67-69). PARENTLESS semantics = v1's:
  # `scopeParent.${sid} or sid` (route.nix:375 and :804) FALLS BACK to the firing scope itself — a
  # defined no-op, never an abort — so a parentless root declaring appendToParent targets itself (the
  # ordinary self-targeted delivery; witnessed). THE RATIFIED TRACE-TARGET CEILING (§9 #53c,
  # accepted-and-ledgered): the parent-target makes the den-hoag edge target the PARENT root where v1's
  # cell-fired synthesize edge targets the CELL — a TRACE-only divergence, drvPath-invisible (the
  # delivered content byte-matches), P1-unexercised; fixture-surfaced re-opener. Read by the edge renderer
  # (`deliveryEdgesAt`) as the fold's target root.
  deliveryTargetRootOf =
    id: d:
    if d.appendToParent or false then
      let
        p = (result.node id).parent;
      in
      if p == null then id else p
    else
      id;

  # nest a module at an attr path — the fold's `place` (gen-edge core.setAttrByPath, materialize.nix:248):
  # `[]` ⇒ the module verbatim (a merge places at the root), else wrap under the path. Pure attrset
  # assembly (A1). den-hoag has no public re-export of gen-edge's core.setAttrByPath, so this is the local
  # twin — the terminal gather must place delivery content EXACTLY where the fold's nest edge would.
  nestAtPath =
    path: value:
    if path == [ ] then value else { ${builtins.head path} = nestAtPath (builtins.tail path) value; };

  # ── #74a (design §10, candidate D — ratified): a delivery's COLLECTED MEMBERS = the firing node's
  # ANCESTOR CHAIN (outermost first) ++ itself ++ its descendants. THE v1 MECHANISM (pin 11866c16
  # nix/lib/aspects/fx/edges/route.nix:556-568 `getCollectedSource`): a cell-fired forward reads
  # `rootModules = perScope[rootScopeId][class] ++ ownModules = perScope[cell][class]` — the ROOT
  # scope's bucket FIRST, then the firing scope's own. That is how the corpus's HOST-attached
  # homeManager content (apps.shell.zsh + persist-home-collector, roles/default.nix:29/:27 — the
  # persistHome mounts ride the SAME bucket, §10 item 5) reaches EVERY user's home-manager.users.<u>.
  # gen-scope `ancestors` (queries.nix:13-28) is the audited co-located dual of `descendants` — no new
  # primitive; it walks NEAREST-first, reversed here to v1's outermost-first order (A12: ancestors
  # first — rootModules ++ ownModules). IDENTITY-DEFAULTED: a ROOT-fired delivery has ancestors = [ ]
  # ⇒ `[ id ] ++ descendants` exactly (the pre-#74 members; the 896/71 baseline unchanged).
  # MULTI-LEVEL-CONTAINMENT CEILING (§10 risk 1, accepted-and-ledgered): v1 reads the rootScopeId
  # bucket ONLY — a deeper chain's INTERMEDIATE ancestors are v1-unread; this generic chain includes
  # them (corpus-inert: a cell's only ancestor is its host). SINGLE-PATH: the ancestor bucket has no
  # terminal of its own at the source class (the nixos host's homeManager bucket builds nothing), so it
  # is consumed once per delivery — disjoint from classSubtreeAt (same-class) and the #66 gather's
  # cross-class law. A17: the lazy id spine (ancestors/descendants are id walks; buckets force at the
  # gather only). This member list is the edge renderer's TRACE identity (`deliveryEdgesAt`); the ancestor
  # SHARED-only restriction the v1 gather applied (`filterRootModules`, route.nix:540-552) belonged to the
  # deleted terminal emission fold, not the trace — projection (`terminalModulesAt = projectClass` over
  # `reach`) supersedes the emission model entirely (spec §1 Corollary: no shared/own marker).
  collectedMembersOf =
    n:
    prelude.foldl' (acc: a: [ a ] ++ acc) [ ] (scope.ancestors result n)
    ++ [ n ]
    ++ scope.descendants result n;

  deliveryEdgesAt =
    id:
    let
      renderDelivery =
        d:
        edge.edge {
          source = edge.sources.collected {
            scope = id;
            class = (if d.module != null then d.targetClass else d.sourceClass).name;
            # #62c + #74a — the firing scope's ANCESTOR CHAIN (v1's rootModules, outermost first) PLUS
            # itself PLUS its descendant cells (Task 5): a host-fired route gathers the user cells'
            # class content; a cell-fired forward gathers its HOST's bucket first (§10). Root-fired ⇒
            # ancestors = [ ] ⇒ the pre-#74 members exactly. This is the TRACE render — it emits edge
            # IDENTITY (the members LIST, `[host, cell]`); the built content is projection's concern
            # (`terminalModulesAt = projectClass`), not this fold.
            members = collectedMembersOf id;
          };
          target = edge.targets.root {
            root = deliveryTargetRootOf id d; # firing scope; the parent root under appendToParent (#53c)
            class = d.targetClass.name;
          };
          inherit (d) path mode;
          adapt = null; # guard/adaptArgs are eval-time terminal transforms (see above), never a fold adapt
          annotations = d.annotations or { };
        };
    in
    map renderDelivery (deliveriesAt id);

  # ── Route class-remap (Phase 4 Task 1, spec §5 (b) — the CONTENT transform layer) ───────────────────
  # A ROUTE is a class→class CONTENT transform on the projected view (NOT a reachability edge — that is
  # the §2 reach model). `routesAt id` LOWERS the firing scope's `delivery` declarations (the SAME
  # resolution actions `deliveriesAt` reads for the trace) to a class-remap record `{ from; to; at; guard }`
  # readable by `projectClass`. `from`/`to` are the source/target CLASS NAMES (the `deliveryEdgesAt` source
  # arm: a MODULE source (provide) collects the TARGET class, a CLASS source (route) collects `from`), `at`
  # is the placement path, `guard` the v1 eval-time closure (or null). `lowerRoute` renders ONE delivery to
  # that record (shared by the OWN-scope routes below and the descendant-driven parent-targeted routes,
  # Task 2). A native fleet emits no delivery ⇒ `[ ]` ⇒ the route-remap is `++ [ ]` (additive identity —
  # `projectClass` byte-identical to the base). A `__dropped` delivery (null target) never reaches here
  # (`deliveriesAt` skips it, exactly as for the trace).
  lowerRoute = d: {
    from = (if d.module != null then d.targetClass else d.sourceClass).name;
    to = d.targetClass.name;
    at = d.path;
    guard = d.guard or null;
    # The ARG-ENVIRONMENT closure (Task 3, bucket c) — carried straight through to the terminal crossing
    # (today the trace records only its PRESENCE as a boolean; the CLOSURE must reach the eval boundary).
    # `null` ⇒ no arg-env transform (the ordinary content route, Tasks 1/2 — the wrapper is identity).
    adaptArgs = d.adaptArgs or null;
    # Parent-targeted (v1 appendToParent) — the route delivers to the containment PARENT (arm 2). Carried so
    # the ensure-target-path seed (remapOver) fires ONLY on a parent-targeted route, excluding the flake-scope
    # devshell route (arm 1) — the den-hoag proxy for v1's `!isFlakeRoute` ensureTargetPath gate.
    appendToParent = d.appendToParent or false;
  };

  # `routesAt id` = the class-remaps of the OWN-scope routes fired at `id` — the deliveries that target the
  # firing scope ITSELF. An `appendToParent` delivery is EXCLUDED here (it targets the containment parent;
  # the HOST gathers it via `parentTargetedRoutesAt`, Task 2) so a cell-fired parent-targeted route is
  # remapped ONCE, at the host, never doubled at the cell.
  routesAt = id: map lowerRoute (builtins.filter (d: !(d.appendToParent or false)) (deliveriesAt id));

  # ── #10 hm-user-detect — the DESCENDANT-DRIVEN parent-targeted route (Phase 4 Task 2, spec §5 (b/d)) ──
  # A cell-fired `appendToParent` route (the v1 hm-user-detect forward: `homeManager → host.class` at
  # `[ home-manager users <u> ]`, emitted by the home-manager battery at every (user,host) cell) targets the
  # CONTAINMENT PARENT root (the host), not the firing cell — so the HOST, projecting its class, gathers these
  # from its DESCENDANT cells (the reach descendant component already brings the cells into the host's view;
  # this is the class-remap SOURCE side). `parentTargetedRoutesAt id` = for each descendant cell `c`, each
  # non-dropped `appendToParent` delivery at `c` whose target root resolves to `id`
  # (`deliveryTargetRootOf`), lowered to a class-remap PLUS its `sourceScope = c` (the cell whose class-`from`
  # slice the route remaps). The route's `at` (the intoPath) is ALREADY concrete — the cell resolved
  # `<u>` = `user.name` at fire time (`[ home-manager users tux ]`), so no per-cell name resolution is needed
  # here. Native identity: a host with no hm cells has no descendant `appendToParent` delivery ⇒ `[ ]`.
  parentTargetedRoutesAt =
    id:
    prelude.concatMap (
      c:
      map
        (d: {
          route = lowerRoute d;
          sourceScope = c;
        })
        (
          builtins.filter (d: (d.appendToParent or false) && deliveryTargetRootOf c d == id) (deliveriesAt c)
        )
    ) (scope.descendants result id);

  # ── Route guard PHASE classification by STATIC FORMALS (owner ruling 2026-07-14) ─────────────────────
  # A route `guard` is a predicate closure; WHEN it can run is decided by WHICH bindings it destructures —
  # via `builtins.functionArgs`:
  #   • CONTENT-TIME — every static formal is satisfiable from the ENRICHED-CONTEXT (the entity bindings:
  #     host/user/system/…, present at PROJECTION). Gated at PROJECTION (`guardHolds`).
  #   • EVAL-TIME — a formal needs a MODULE binding (config/options/pkgs/…) available ONLY at the terminal
  #     `evalModules` crossing. Gated at the crossing (`argEnvWrap`'s config-gate).
  # This DECOUPLES guard-phase from `adaptArgs`: an eval-time guard fires at the crossing WITHOUT adaptArgs,
  # and a content-time guard is gated at projection even WITH adaptArgs. The check is a direct AVAILABILITY
  # test (no hardcoded name list): the enriched-context's OWN keys are the entity/kind bindings, so a formal
  # absent from them needs the crossing. A bare `args:` guard (empty functionArgs) is trivially content-time.
  # CORPUS REALITY (2026-07-14): the frozen corpus has ZERO route guards — home-platform gates at POLICY
  # dispatch (`lib.optional (hasSuffix host.system) route`, so the emitted route is UNGUARDED), and no wsl
  # route guard exists. So this is FRAMEWORK GENERALITY (an END-USER config's guard-bearing route — den is a
  # general framework), validated synthetically; every real fleet route has `guard == null` (drv-invisible).
  # EDGE (ledgered, no corpus instance): a guard with formals in BOTH sets classifies EVAL-TIME (a module
  # formal forces the crossing) but cannot read its entity formals there until entity bindings are threaded
  # into the terminal args — future.
  guardIsContentTime =
    guard: id:
    let
      ctx = result.get id "enriched-context";
      formals = builtins.attrNames (builtins.functionArgs guard);
    in
    prelude.all (f: ctx ? ${f}) formals;

  # A route's CONTENT-TIME guard against the projecting scope. `null` guard ⇒ unconditional. A content-time
  # guard is evaluated HERE against the enriched-context; an EVAL-TIME guard is DEFERRED (true here, gated at
  # the crossing by `argEnvWrap`). Decoupled from adaptArgs: a content-time guard WITH adaptArgs is still
  # gated here; an eval-time guard WITHOUT adaptArgs rides the wrapper.
  guardHolds =
    route: id:
    route.guard == null
    || !(guardIsContentTime route.guard id)
    || route.guard (result.get id "enriched-context");

  # `place at slice`: the fold's nest (`nestAtPath`, gen-edge core.setAttrByPath). `at == []` ⇒ the slice
  # FLAT (bucket b pure remap, #14 home-platform homeLinux→homeManager); `at ≠ []` ⇒ each module wrapped
  # under the path as a content module (`{ <at> = <module>; }`, nest-via-content-module — the shape later
  # tasks place per-cell home-manager.users.<u> content at, #10/#15). Pure attrset assembly (A1).
  placeSlice = at: slice: if at == [ ] then slice else map (m: nestAtPath at m) slice;

  # ── The ARG-ENVIRONMENT crossing hook (Phase 4 Task 3, spec §5 (c) — the HARD bucket) ────────────────
  # A route carrying `adaptArgs` (`{config,...}: config.allModuleArgs` for #15 devshell→flake-parts) rewrites
  # the terminal EVAL-TIME arg environment, and/or an EVAL-TIME `guard` gates content at the crossing.
  # `projectClass` stays a pure CONTENT projection (Task 1 placed the slice); the arg-env/guard transform
  # rides ON that placed module as a FUNCTION-MODULE fired at the terminal `evalModules` crossing (where
  # `args`/`config`/`options` exist). Three shapes (`id` = the projecting scope, for guard classification):
  #
  #   (1) NO adaptArgs AND no eval-time guard → IDENTITY (the placed slice verbatim). A pure-content route,
  #       or a route whose only guard is CONTENT-TIME (already gated at projection by `guardHolds`), evals
  #       plain — byte-identical to Tasks 1/2.
  #   (2) adaptArgs, NO eval-time guard → the arg-env FUNCTION-MODULE `args: { imports = [ placed ];
  #       _module.args = adaptArgs args; }` (v1 `nestWithAdaptArgs`) — injects the adapted args every SIBLING
  #       module reads. No guard gates imports, so no fixpoint cycle.
  #   (3) EVAL-TIME guard (with OR without adaptArgs) → the CONFIG-GATE via a NESTED EVAL (owner ruling
  #       2026-07-14). Gating `imports` on an eval-time guard (which reads `options`/`config`) is a FIXPOINT
  #       CYCLE (imports ← guard(options) ← options ← imports → infinite recursion). v1 sidesteps by gating
  #       CONFIG (`mkIf`), never imports — option DECLARATIONS stay unconditional so `options` is well-defined
  #       independent of the guard. For an OPAQUE slice: the wrapper declares NO options and imports NOTHING
  #       conditionally (→ the outer option-set is guard-independent → NO CYCLE); it NESTED-EVALS the opaque
  #       slice (`args.lib.evalModules`, the terminal's own evaluator; a freeform absorber lets the opaque
  #       slice's config keys land; adaptArgs rides the nested `_module.args`) and `mkIf (guard args)` gates
  #       THAT nested `.config` into the outer. guard-false ⇒ `mkIf false` ⇒ no config contributed (content
  #       absent); guard-true ⇒ the nested config contributed. NO recursion either arm (proven against the
  #       exact `{options,...}: options ? x` case that recursed under an import-gate).
  #
  # ATTACHES to EXACTLY the route's slice (built HERE, where the route↔slice pairing is known — the per-slice
  # attach, never the whole class content). OPTION-DECLARATION BOUND (ledgered, no corpus instance): the
  # config-gate gates the slice's CONFIG contribution — if an eval-time-guarded slice DECLARES options (rare;
  # content slices contribute config: packages/settings, not option declarations), those declarations do NOT
  # reach the outer option-set (they live in the nested eval). This is FUNDAMENTAL to the module system (you
  # cannot conditionally declare an option without the import-cycle), not a den limit — the common case (a
  # slice contributes config, the guard checks an option declared ELSEWHERE, e.g. a wsl module declares
  # `wsl`, the guard gates OTHER content on `options ? wsl`) is sound.
  argEnvWrap =
    route: id: placed:
    let
      evalTimeGuard = route.guard != null && !(guardIsContentTime route.guard id);
    in
    if route.adaptArgs == null && !evalTimeGuard then
      placed # (1) NOT a crossing route — identity (a content-time guard, if any, is handled by guardHolds).
    else if !evalTimeGuard then
      # (2) adaptArgs only — the arg-env wrapper (no guard gating imports ⇒ no cycle).
      args: {
        imports = [ placed ];
        _module.args = route.adaptArgs args;
      }
    else
      # (3) eval-time guard (± adaptArgs) — CONFIG-GATE via a nested eval (no import-cycle). The nested eval
      # uses the terminal's OWN evaluator (`args.lib.evalModules`), a freeform absorber for the opaque slice,
      # and the adaptArgs injection as its `_module.args`. `mkIf (guard args)` gates the nested config.
      args:
      let
        nestedArgs = if route.adaptArgs == null then { } else route.adaptArgs args;
        nested = args.lib.evalModules {
          modules = [
            # freeform absorber in the terminal's OWN type system (`args.lib`), so the opaque slice's config
            # keys land regardless of which terminal (nixpkgs / gen-merge) runs the crossing.
            { config._module.freeformType = args.lib.types.lazyAttrsOf args.lib.types.raw; }
            placed
            { config._module.args = nestedArgs; }
          ];
        };
      in
      {
        config = args.lib.mkIf (route.guard args) nested.config;
      };

  # The route class-remap contribution to `projectClass id C`: for each route TARGETING C whose guard holds
  # at the scope, the guard-gated remap of each REACHED node's class-`from` slice, placed at the route's
  # path. A route whose `to != C` contributes nothing to the C projection (the transform is class-scoped).
  # Additive to the base projection — a scope with no C-targeting route yields `[ ]` (identity).
  #
  # LEDGERED — THE PRODUCING-CLASS OVER-REPORT, UNMASKED BY A CROSS-CLASS ROUTE (accept-and-ledger, owner
  # ruling 2026-07-14). `class-modules` OVER-REPORTS: gen-aspects' freeform gives EVERY class key a trivial
  # `{ imports = [ { } ]; }` DEFAULT body even for an aspect that declares no content there (the documented
  # §2.5 over-report, output-modules.nix:118-126). The BASE fold masks this via producing-class scoping
  # (`classBucketsOf` folds only a node's OWN producing class); a ROUTE is an EXPLICIT cross-class read, so
  # `classSliceOf n route.from` over a `from` the reached node never declared yields that phantom default
  # slice. The corpus's built-in os→nixos route surfaces it (an `acct`-shaped cell declares nixos+home-manager,
  # never `os`, yet its phantom `os` default slice remaps into nixos). This is DRVPATH-HARMLESS (the phantom
  # body is `{ imports = [ { } ]; }` — an empty no-op module the terminal merge absorbs to nothing) and is
  # NOT filtered here: the only phantom signal is the nixpkgs `_file = "<default>"` presentation marker on the
  # INNER module (not a robust gen-aspects "was-never-declared" contract), so dropping on it would be the
  # emptiness-by-another-name fragile filter the spec §5 silent-content-loss warns against. `classSliceOf`
  # already drops a LITERAL `{ }` body; the freeform default is not literal-`{ }`, so it rides through — the
  # accepted, ledgered over-report. The routed-delta anchor witness (`ci/tests/projection.nix`) pins the
  # invariant `projectClass id C == classSubtreeAt id C ++ <route remap delta>` (exact-equal only for a
  # route-FREE class), so the phantom is asserted BOUNDED (harmless empties), never silently unaccounted.
  # Remap the class-`from` slice of every node in `reach srcScope`, placed at `at` — the shared body of both
  # the own-scope route (srcScope = the projecting scope) and the descendant-driven parent-targeted route
  # (srcScope = the descendant cell). `guardHolds route srcScope` gates against the SOURCE scope's bindings.
  # ── placeRemapped — v1 `nestWithAdaptArgs`/`nestPlain` (route.nix:78-126 @ pin 11866c16), den-hoag-native.
  # For a route with `at ≠ []` and NO eval-time guard (cases 1/2), a route-remapped slice becomes a
  # TOP-LEVEL module in the terminal `evalModules` — `args: { config = setAttrByPath at (nestedEval).config }`
  # — so it receives the terminal's top-level args (`pkgs`/`lib`/`config`), and its slice is resolved in a
  # NESTED `evalModules` whose `specialArgs` thread BOTH provenances a parametric slice may read: the host
  # top-level args (fixes `pkgs` at `users.users.<u>`) AND the SOURCE scope's channel/entity bindings
  # (`bindingsAt srcScope` — fixes `peer-dev` at `home-manager.users.<u>`). This replaces the old nest-as-
  # VALUE placement (`placeSlice` nested the wrapper as the submodule value, so gen-bind's wrapAll saw the
  # outer attrset as content and never wrapped the inner fn → its args were the bare submodule's, missing
  # pkgs/peer-dev). Case-3 (eval-time guard) is DELIBERATELY NOT handled here — it stays on the
  # `argEnvWrap`+`placeSlice` path (below), because its guard reads the SUBMODULE's options (`options ?
  # marker` declared inside the target submodule), which a top-level guard would not see.
  #
  # LEDGER (per-module vs v1's #572 COMBINED eval): v1 does ONE `nestWithAdaptArgs` over `{ imports =
  # adapted }` for a MULTI-SOURCE route; this evals each slice module SEPARATELY. Corpus-inert — the only
  # routed multi-source case (test-forwards-mergeable-option) merges LIST-valued content (associative concat,
  # order-free), so per-module vs combined agree. A future multi-source route delivering a SCALAR or a
  # priority-annotated field would need the combined `{ imports = slices }` eval (spread here) to match v1.
  #
  # LEDGER (priority-annotation collapse): the nested `evalModules` RESOLVES the slice before the outer merge
  # sees it, so a `mkDefault`/`mkForce`/`mkMerge` annotation in a routed slice is COLLAPSED to its resolved
  # value at the nested boundary. No active routed slice carries one (verified); the parked
  # issue-311-nested-includes-are-parametric `homeManager.home.keyboard.model` mkDefault/mkForce pair rides
  # the hm-user-detect route — when it is un-parked (a later rung), that rung must check whether the
  # nested-eval collapse changes its cross-scope priority resolution.
  placeRemapped =
    route: srcScope: sliceMod:
    let
      srcBindings = bindingsAt srcScope; # den channel + entity + settings values (peer-dev lives here).
    in
    args:
    let
      # host top-level args (pkgs/lib/config) ++ terminal-published module args ++ source-scope den bindings
      # (den channel values win — they are the authoritative resolved bindings).
      fullArgs = args // (args.config._module.args or { }) // srcBindings;
      special = if route.adaptArgs == null then fullArgs else route.adaptArgs fullArgs;
      nested = args.lib.evalModules {
        specialArgs = special;
        modules = [
          # Freeform absorber in the TERMINAL's own type system (`args.lib`), so the opaque slice's config
          # keys land regardless of which terminal (nixpkgs / gen-merge) runs the crossing — matching the
          # argEnvWrap case-3 absorber.
          { config._module.freeformType = args.lib.types.lazyAttrsOf args.lib.types.raw; }
          sliceMod
        ];
      };
    in
    {
      config = args.lib.setAttrByPath route.at (
        builtins.removeAttrs nested.config [
          "_module"
          "warnings"
          "assertions"
        ]
      );
    };

  # `exempt` = the srcScope's forward-source-class set, threaded in by the caller (`routeRemapFor`) so the
  # per-node `classSliceOf` collects an unregistered forward SOURCE class (a plain corpus route's `from` is a
  # registered class ⇒ `{ }` exemption ⇒ unaffected).
  remapOver =
    exempt: srcScope: route:
    let
      evalTimeGuard = route.guard != null && !(guardIsContentTime route.guard srcScope);
      placed = prelude.concatMap (
        n:
        let
          slices = map (e: e.module) (classSliceOf exempt n route.from);
        in
        if route.at == [ ] then
          # at=[] — flat merge into the target class (home-platform bucket b). No placement path, so no
          # top-level threading is needed; keep the arg-env wrapper so a future at=[] adaptArgs/guard route
          # still crosses correctly (FIX-3: not the bare slice).
          map (m: argEnvWrap route srcScope m) slices
        else if evalTimeGuard then
          # at≠[] WITH an eval-time guard (case-3) — UNCHANGED: the guard reads the target submodule's own
          # options, so it must stay nested-as-value (`argEnvWrap` case-3 runs the guard as that submodule).
          placeSlice route.at (map (m: argEnvWrap route srcScope m) slices)
        else
          # at≠[] with NO eval-time guard (cases 1/2) — the v1-shape top-level placer threading host args +
          # source-scope bindings + adaptArgs (fixes pkgs + peer-dev at the placed submodule).
          map (m: placeRemapped route srcScope m) slices
      ) (result.get srcScope "reach");
      # v1 ensureTargetPath (pin 11866c16 route.nix:671 derived predicate → :283 `optional … { config =
      # setAttrByPath path { }; }`): a parent-targeted (user→host) route with `adaptArgs`, a non-empty `at`,
      # and ZERO whole-route content still SEEDS its target path — so the empty cell's `users.users.<u> = { }`
      # entry EXISTS (content-driven placement would otherwise DROP the entry when the cell has no `.user`
      # content). Computed on the WHOLE-route contribution (`placed == [ ]`), so the seed lands ONCE at
      # `route.at` (not per reached node), riding the SAME arm-2 delivery to the HOST. `appendToParent` gates
      # to the arm-2 (containment-parent) route, excluding the flake-scope devshell route (v1's `!isFlakeRoute`
      # proxy); `adaptArgs != null` excludes hm-user-detect. In the corpus this reduces to the user→host route.
      ensureSeed =
        if
          (route.appendToParent or false) && route.adaptArgs != null && route.at != [ ] && placed == [ ]
        then
          [ { config = nestAtPath route.at { }; } ]
        else
          [ ];
    in
    placed ++ ensureSeed;

  # iv-b / §2-ii/iii — the FORWARD module contributions to `projectClass id class`, derived REACH-SOURCED
  # from the `meta.__forward` specs (den.provides.forward). A forward is a CLASS-REROUTE: the collected
  # `fromClass` bucket → `intoClass` at `intoPath` (v1 compile-forward.nix: the collected source bucket IS
  # the content; `aspect-chain` a locality tag). Reach-sourced (not an emitted delivery declaration) because
  # a forward is authored as an ASPECT INCLUDE — its spec rides resolved-aspects, not the policy-dispatch
  # declarations `deliveriesAt` reads. Built HERE (not via `remapOver`) because the v1 GUARD (`guardFn`,
  # forward.nix:73-86) wraps the PLACEMENT (`optionalAttrs`/`mkIf` over `setAttrByPath intoPath content`), so
  # an option-existence guard false SUPPRESSES the whole path — `remapOver`'s case-3 nests the guard UNDER
  # the path, which sets the (nonexistent) target option unconditionally. v1 mechanism:
  #   • TIER-1 (no guard/adaptArgs): the plain nested slice `nestAtPath intoPath slice`.
  #   • COMPLEX: a TOP-LEVEL function-module `args: { config = guardFn args (nestAtPath intoPath slice);
  #     _module.args = adaptArgs args; }` — `guardFn` item-applied at the crossing (bool ⇒ optionalAttrs,
  #     fn ⇒ `res item` e.g. `mkIf`), `adaptArgs` threaded as the slice's module args (v1 nestWithAdaptArgs).
  # A node with no matching forward spec ⇒ `[ ]` ⇒ identity (byte-parity: corpus emits no meta.__forward).
  # `reach`/`exempt` are threaded in from `projectClass` (computed ONCE there — no recompute).
  #
  # CEILING (adaptArgs, unverified): the `adaptArgs` arm here threads `_module.args = adaptArgs args` at the
  # target module, whereas v1 (route.nix `nestWithAdaptArgs`) rewrites the args the SOURCE slice sees. Every
  # target-class case witnessed so far carries `adaptArgs = null`, so the arm is inert on the green set; the
  # adaptArgs-bearing forwards all target homeManager-at-cell (a separate lift composition), so this arm's
  # v1-fidelity is RE-VERIFIED when that path is built — a documented ceiling, not a live divergence.
  forwardModulesFor =
    reach: exempt: class:
    let
      specs = prelude.concatMap (
        n:
        let
          f = (n.content.meta or { }).__forward or null;
        in
        if f == null || f.intoClass != class then [ ] else [ f ]
      ) reach;
    in
    prelude.concatMap (
      spec:
      let
        srcSlices = prelude.concatMap (n: map (e: e.module) (classSliceOf exempt n spec.fromClass)) reach;
        hasAdapter = spec.guard != null || spec.adaptArgs != null;
        # v1 `guardFn` (forward.nix:73-86), item-applied: a FN guard result → `res item` (e.g. `mkIf cond`)
        # applied to the placed content; a BOOL result → gate the whole placement (`optionalAttrs`, v1's
        # `assert builtins.isBool res` — a non-bool, non-fn guard result is a NAMED authoring error).
        guardApply =
          args: content:
          if spec.guard == null then
            content
          else
            let
              res = spec.guard args;
            in
            if builtins.isFunction res then
              (res spec.item) content
            else
              assert builtins.isBool res;
              if res then content else { };
        buildModule =
          slice:
          if !hasAdapter then
            nestAtPath spec.intoPath slice
          else
            args:
            {
              config = guardApply args (nestAtPath spec.intoPath slice);
            }
            // prelude.optionalAttrs (spec.adaptArgs != null) {
              _module.args = spec.adaptArgs args;
            };
      in
      map buildModule srcSlices
    ) specs;

  # `exempt` = `id`'s forward-source set (threaded from `projectClass`, own-scope leg). The parent-targeted
  # leg's source is a DESCENDANT cell, so it carries its OWN per-cell exemption.
  routeRemapFor =
    exempt: id: class:
    # (1) OWN-scope routes fired at `id` (Task 1) — the source node set is `reach id`.
    prelude.concatMap (
      route: if route.to == class && guardHolds route id then remapOver exempt id route else [ ]
    ) (routesAt id)
    # (2) DESCENDANT-DRIVEN parent-targeted routes (Task 2, #10 hm-user-detect) — a cell-fired
    #     `appendToParent` route targeting THIS host: the SOURCE is the descendant cell (`sourceScope`), so
    #     the cell's class-`from` (`home-manager`) slice remaps to `class` (`nixos`) at the route's per-cell
    #     `at` (`[ home-manager users <u> ]`). `reach sourceScope` = the cell's OWN subtree (no host edge),
    #     so the cell's OWN hm content is delivered (the v1 filterRootModules R-ROOT-FILTER: host scope-own
    #     hm does NOT ride the cell's gather), and the guard is evaluated at the CELL.
    ++ prelude.concatMap (
      pt:
      if pt.route.to == class && guardHolds pt.route pt.sourceScope then
        remapOver (forwardSourceClassesOf (result.get pt.sourceScope "reach")) pt.sourceScope pt.route
      else
        [ ]
    ) (parentTargetedRoutesAt id);

  # ── projectClass (Phase 2 Task 2, spec §1/§3): the class-slice PROJECTION over `reach` ───────────────
  # `projectClass id class` = the class-`C` module slice of EVERY resolved-aspect node in `reach id`, in
  # reach's canonical order (own-subtree → descendant cells → default edges → opt-in edges — the merge_ord
  # Task 5 pins). Each reach node's `content` is already ctx-resolved at ITS OWN scope (the P-PROJECT
  # closure resolves per-provider), so the slice is ctx-correct across scopes. `classSliceOf` is THE ONE
  # extraction the `class-modules` buckets use (0/1 `{ module; shared }` per aspect); `.module` strips to the
  # bare deferredModule.
  #
  # THE ANCHOR (Task 2 subsume proof): for a node with NO reach edges, reach = its OWN scope subtree
  # (`[ id ] ++ scope.descendants`, Task 1) and `projectClass id class == classSubtreeAt id class`
  # byte-identically — projection reproduces the fold on own-content BEFORE it replaces the emission (Task 3).
  # `reach` single-visit-dedups by A-IDENT key, so an aspect reachable twice contributes its slice ONCE.
  # CONSUMED by `terminalModulesAt` (Task 3, below) — projection is now the terminal's content source.
  # §2.2 TOTALITY (ruling 2026-07-14): each reached aspect's non-`_` keys are ALL classified
  # (`assertKeysRegistered`, forced via `seq`) before its projected-class slice is taken — a genuinely
  # unregistered typo key on a REACHABLE aspect aborts NAMED (never silently vanishes on the drv path,
  # the §5 content-loss failure that `classSliceOf class` alone — classifying only the projected key —
  # would let through). Totality covers reached content (edges/descendants), not just the own node.
  #
  # ROUTE CLASS-REMAP (Phase 4 Task 1, spec §5 (b)). The base class-slice projection over `reach` PLUS the
  # additive route-remap layer (`routeRemapFor`): a route `{ from=D; to=C; at; guard }` lowered at the
  # projecting scope contributes the guard-gated remap of each reached node's class-D slice, placed at `at`,
  # into the class-C projection. A native fleet emits no route ⇒ `routeRemapFor id class == [ ]` ⇒
  # `projectClass` is byte-identical to the base (identity — the anchor + all Phase 1/2/3 witnesses green).
  projectClass =
    id: class:
    let
      reach = result.get id "reach";
      # iv-b: the reach-sourced forward-source exemption, computed ONCE per (id,class) projection and threaded
      # to the §2.2 totality assertion, the class-slice extraction, `routeRemapFor` (own-scope leg), AND
      # `forwardModulesFor` — so a live forward SOURCE materializes (collectable) instead of aborting. `{ }`
      # on every non-forward node ⇒ byte-identical.
      exempt = forwardSourceClassesOf reach;
    in
    prelude.concatMap (
      n: builtins.seq (assertKeysRegistered exempt n) (map (e: e.module) (classSliceOf exempt n class))
    ) reach
    ++ routeRemapFor exempt id class
    ++ forwardModulesFor reach exempt class;

  # The per-class TERMINAL assembly (spec §3/§4, Phase 2 Task 3 — THE PIVOT). Projection over `reach`
  # REPLACES the v1 emission model: `terminalModulesAt id class = projectClass id class` (the class-`C`
  # slice of every aspect in `reach id`, canonical merge_ord). This subsumed BOTH halves of the old
  # `classSubtreeAt id class ++ deliveryModulesAt id class` emission model (both DELETED in Phase 3):
  #   • the same-class subtree fold (`classSubtreeAt`) → reach's STRUCTURAL-DESCENDANT component (Task 1;
  #     the anchor proved projectClass == classSubtreeAt byte-identically on own+descendant content), and
  #   • the cross-class delivery emission → reach's positive EDGES (opt-in reach-edge + framework default
  #     edge, class-scoped F9).
  # Consumed at the three terminal reads (`hostModules`/`deltaOf`/`contentIdsOf`). The v1 emission fold
  # (`deliveryModulesAt`/`deliveryModulesChain`) is DELETED; `classSubtreeAt` STAYS as the projection's
  # own-content leaf + the anchor oracle, and `collectedMembersOf` STAYS LIVE (the edge renderer
  # `deliveryEdgesAt` still calls it for the trace).
  #
  # THE RED WINDOW (spec §Phase-2 scope, INTENTIONAL — documented, not silent): the corpus has NO
  # reach-edge / reach-suppress / default-edge PRODUCERS until Phase 5 (corpus migration wires host-aspects
  # → opt-in edge + the framework default edge). So on the real fleet `reach` = the STRUCTURAL SUBTREE ONLY
  # — the emission half (baseline home content + host-aspects cross-class delivery) is MISSING until Phase 5,
  # and full-fleet byte/functional validation is Phase 6. Projection is therefore validated SYNTHETICALLY
  # here (ci/tests/projection.nix drives the edges through a synthetic reach graph — the complete-reach
  # semantics witnesses: spicetify-once, intel-both, define-user nixos@host+hm@cell). The fleet golden
  # suites that lose the emission content are MARKED PENDING (`# Phase 5: needs corpus edge producers`),
  # never faked green.
  terminalModulesAt = id: class: projectClass id class;

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
  # graph accessor) PLUS the fleet-global demand edges, PROJECTED to the materialization trace (§7). The
  # `materializeFilter` keeps only `to ∈ { materialize, both }` kinds — a `to = query` relation edge is off
  # the trace. It is INERT on the corpus (relation edges live in a separate pool never merged in here; the
  # content edges are unlabeled → materialize, the demand edges are `kind = "demand"` → materialize), so it
  # FORMALIZES the off-trace seam rather than creating it. Concatenation is A1 wiring; the derivation is the
  # lib call. This is the single edge set both `outputFor` (materialize) and `traceFor` (the frozen trace)
  # consume, so the demand edges join the fleet edge set exactly once and consistently in both views.
  edgesForRoot =
    root:
    materializeFilter (
      edge.edgesFor {
        graph = graphAccessor;
        inherit root;
      }
      ++ demandEdges
    );

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
  # The producer-config map KEY: the producing entry's `id_hash` + producing CLASS name (§5 — a scope with
  # multiple class terminals needs the class to pick host→nixos vs user-cell→home-manager). gen-pipe
  # preserves the contribution's `producer.entity` (its `contribute` reconstructs `{ entity; scope; aspect }`
  # — dropping any extra field), so `producer.entity.id_hash` is the stable, JSON-safe producer identity
  # (unlike `producer.scope`/coordDims, which can carry function-valued decls). The thunk stamp
  # (`deferredToThunk`, from `producer.entity.id_hash`) and the map build (`producerConfigs`, from each
  # node's `__entry.id_hash`) derive the SAME key. NOTE: the node's OWN id is a readable coord-path
  # (`host:iceberg`), NOT the id_hash — so the map keys by the entry hash but looks the config up by node id.
  producerKeyOf =
    entryHash: classEntry: "${entryHash}::${if classEntry == null then "" else classEntry.name}";

  # Adapt a deferred gen-pipe contribution to a gen-bind config-thunk (resolve-at-producing-scope, PR
  # #623 parity): the thunk carries the producing scope+class as `__sourceScope`; gen-bind's `wrapAll`
  # resolves its `fn` against the PRODUCING terminal's config (`producerConfigs.<key>`) when the terminal
  # forces it — CHORAG §5.1, the host's lazy fixpoint as the cross-terminal solver. Absent a producer key
  # (default map) it falls back to the consumer config, byte-identical.
  deferredToThunk =
    c: bind.mkThunkFrom (producerKeyOf (c.producer.entity.id_hash or "") c.class) c.fn;

  # Lower a §4.8 R6 defer contribution (`executeDefer`'s `{ mode="defer"; needs; thenFn; fn }`) onto a gen-bind
  # config-thunk: `mkThunkFrom <producingScope>` wraps the contribution's config-adapter `fn` so wrapAll
  # resolves it against the terminal's config, with `__sourceScope` recording the producing scope. This is the
  # deferredToThunk twin for the R6 record (which carries `fn` but no `producer.scope` — the scope is supplied
  # at the mount). The LIVE routing — GATHERING the defer contribution at ITS producing terminal so that
  # terminal's config feeds the resolution (decision #27, resolve-at-producing-scope) — is the retire-into-one
  # step; this lowering + the `__sourceScope` marker are its prerequisites (no live producer emits an R6 defer
  # record today, so this is synthetic).
  lowerDefer = scope: c: bind.mkThunkFrom scope c.fn;

  # A single contribution → its terminal-binding value: a deferred emission becomes a gen-bind config-thunk
  # (resolved at THAT contribution's producing config), a plain emission its value. gen-bind's wrapAll
  # auto-detects the thunk list entries and resolves them at eval (the terminal). Used for BOTH the node's
  # own emissions AND the gathered ones (#62a) — a gathered deferred contribution keeps its OWN producer
  # scope, so it resolves where it was produced, not at the consuming node.
  extractContribution = c: if c.deferred then deferredToThunk c else c.value;

  # A member's channel bindings: the channel value VISIBLE AT THIS POSITION (attribute 11,
  # `received-collections` — the neron self→imports→parent fold, so a cell INHERITS its ancestors'
  # contributions exactly as a v1 child scope reads its parent's pipe value; a ROOT has no parent, so
  # received ≡ local there — the pre-#74 host surface byte-identical) AUGMENTED by the per-node gather
  # (#62a). Per channel the bound value is `received ++ gathered` (F4 — v1 `mkCombinedBase`'s
  # `markedBase ++ markedExposed`, assemble-pipes.nix:935-948). #74b: this closed the u9 KNOWN CEILING
  # (the old own-emissions read) — the corpus's persist-home-collector, DELIVERED per-user by #74a,
  # destructures `persistHome`/`cacheHome` whose emissions live at the HOST (apps/shell/zsh.nix:126) —
  # v1's user-scope pipe ctx carries them by inheritance. The VALUE LIST is FLAT (v1
  # `flattenAndExtract`, assemble-pipes.nix — a LIST emission spreads into elements; an attrset/deferred
  # emission is one element), so a corpus consumer's `concatMap (e: e.directories) persistHome` reads
  # v1's shape. The key set is TOTAL over both maps (`resolved-users` at a host — the ship-gate shape).
  #
  # `channelGather derivedBaseNames result` is applied ONCE here (not per node): the supplier binds
  # `derivedBaseNames` + `result` and precomputes its per-fleet indices, so `channelGatherR id` per node
  # reuses them (A17: WHNF is the `id` lambda — the indices are lazy thunks in its closure, forced only when
  # a consumer demands them).
  channelGatherR = channelGather derivedBaseNames result;
  channelBindingsAt =
    id:
    let
      received' = received id;
      local0 = builtins.mapAttrs (_: out: out.contributions or [ ]) received';
      # Untargeted-deriving supersede: a base with a deriving pipe reads its terminal(s)' collections in
      # place of the raw base (v1 `applyPipeEffects` REPLACES). Force-safe because the terminal aliases
      # `received[terminal].contributions` (POST-adapter — the derive chain already ran through gen-pipe's
      # run), and the v1 value-predicate filter adapter unwraps the provenance view. Multiple policies on
      # one base concatenate, each from the base values (v1 per-policy concat).
      local =
        local0
        // builtins.listToAttrs (
          map (
            base:
            prelude.nameValuePair base (prelude.concatMap (t: local0.${t} or [ ]) derivedBaseNames.${base})
          ) (builtins.attrNames derivedBaseNames)
        );
      gathered = channelGatherR id;
      # attribute 10 — the node's OWN emissions per channel (no ancestor inheritance).
      ownData = result.get id "local-collection-data";
      flatten =
        c:
        let
          v = extractContribution c;
        in
        if builtins.isList v then v else [ v ];
      # v1 bindsPipeLocally (assemble-pipes.nix:918-923 / pipeData :1046-1054): a channel that RECEIVES an
      # expose/broadcast value here (`gathered.<ch> ≠ [ ]`) binds LOCALLY — the node reads its OWN value plus
      # the received value and does NOT fall through to the attr-11 ancestor-inheritance fold. The own base is
      # the derived terminal when a local deriving pipe supersedes the channel (`local`, already own-scoped —
      # the terminal is produced only where the pipe fires, so it carries no host inheritance), else the raw
      # own emission (attribute 10). A pure CONSUMER (no gather) keeps the inherited `received` base — #74b
      # persist-home, where a user reads its host's inherited value. The gate is `gathered ≠ [ ]` ALONE (an
      # `ownContribs ≠ [ ]` disjunct would drop the inherited half of a plain cell's #74b binding).
      baseOf =
        ch:
        if (gathered.${ch} or [ ]) != [ ] then
          if derivedBaseNames ? ${ch} then (local.${ch} or [ ]) else (ownData.${ch} or [ ])
        else
          (local.${ch} or [ ]);
    in
    prelude.genAttrs (builtins.attrNames (local // gathered)) (
      ch: prelude.concatMap flatten ((baseOf ch) ++ (gathered.${ch} or [ ]))
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
  # ── Axis-6 settings-injection seam (§2.10 attribute 13 → the terminal) ─────────────────────────────
  # The resolved settings-product (`resolved-settings`, attribute 13) delivered as a `settings` module
  # arg, MIRRORING path-B's `host` harvest below: a SIBLING key in the binding set, purely ADDITIVE.
  # gen-bind's `wrapAll` binds a module arg IFF its key exists AND the module declares it (`boundArgNames`),
  # so a class-content module that declares no `settings` arg is byte-unwrapped — a corpus with no such
  # consumer is byte-unchanged, and this thunk (below) is never forced there (a node that never demands
  # `settings` never folds resolved-settings through this surface). The value is the per-node fold of every
  # PRESENT aspect's resolved `.value`: for a SINGLE-aspect consumer (the seam) exactly that aspect's folded
  # settings; multi-aspect field COMPOSITION is the productions-substrate per-host union (P5b), not here.
  settingsBindingAt =
    id:
    prelude.foldl' (acc: a: acc // a.value) { } (
      builtins.attrValues (result.get id "resolved-settings")
    );

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
        // channelBindingsAt id
        // {
          settings = settingsBindingAt id;
        };
    };

  memberClassName =
    id:
    let
      c = classOfNode (result.node id);
    in
    if c == null then null else c.name;

  # The member (scope node) ids that carry NON-EMPTY content for a class — the class-major output map's
  # spine, and the class-share member set. Content-driven (a member with no content for `name` is absent).
  # #66: content presence is the TERMINAL assembly (fold ++ delivery) — a member whose only class content
  # arrives by a cross-class delivery still builds a system.
  contentIdsOf =
    name:
    prelude.filter (id: memberClassName id == name && terminalModulesAt id name != [ ]) allNodeIds;

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
  # The producer-scoped config-thunk map (CHORAG §5.1): `<scope-coords ::class> = <that scope's producing
  # terminal config>`. A `__sourceScope`-keyed config-thunk resolves against the PRODUCER's config, not the
  # consumer's (broadcast/expose/route a config-DEPENDENT emit across terminals). Keyed to match
  # `deferredToThunk`'s stamp (coords + class name). The value is the producing scope's terminal config:
  #   • host (nixos)         → its own nixos terminal config.
  #   • user cell (home-manager) → the host's nixos config nested at `home-manager.users.<user>` (den-hoag
  #     mounts hm INSIDE the host's nixos terminal; there is no standalone hm system here).
  # THE FIXPOINT KNOT: this map is built FROM `systems`, and `systems`' terminal `wrapAll` consumes it — a
  # mutually-recursive `let` (Nix's own fixpoint). It stays LAZY: the SPINE (keys) reads node decls + class
  # (the hm branch also reads `enriched-context.user.name` for the nesting key — still TERMINAL-FREE, a
  # pre-config `resolve.attr` that can't cycle with terminal-config resolution), so building the spine never
  # forces a TERMINAL; each VALUE is an unforced ref to a `systems.<class>.<member>.config`, forced only when
  # a consumer's thunk indexes it, to the depth the thunk reads (A17's strong guarantee — no eager terminal-
  # config force — holds, and nothing `deepSeq`s this map or the systems values). An acyclic-at-use
  # cross-terminal read resolves via the knot; a genuine cross-terminal cycle surfaces as LOUD `infinite
  # recursion` (never a silent read).
  producerConfigs = builtins.listToAttrs (
    prelude.concatMap (
      id:
      let
        node = result.node id;
        classEntry = classOfNode node;
        entryHash = node.decls.__entry.id_hash or null;
      in
      if classEntry == null || entryHash == null then
        [ ]
      else
        let
          key = producerKeyOf entryHash classEntry;
        in
        # A producer key is added ONLY when the producing terminal exposes a REAL `.config` (a nixpkgs
        # crossing). The nixpkgs-free `collect` terminal has no `.config`; omitting the key lets the thunk
        # FALL BACK to the consumer config (byte-identical to the pre-Tier-1 resolution). So a collect fleet
        # (no `den.nixpkgs`) contributes an EMPTY map ⇒ every config-thunk resolves at the consumer, exactly
        # as before — the byte-parity guarantee.
        #
        # The WHERE is data-carried: the class registration's `producerConfig` locator (concern-classes.nix,
        # seeded from `builtinClassDefaults`) names the member's `.config` position, so this fold is class-name
        # AGNOSTIC. A `null` locator (darwin/k8s/declared classes, no nixpkgs crossing) contributes no key; a
        # `null` RETURN means "this member exposes no producer key" (the fall-back above) — config VALUES are
        # never legitimately null (nixos `.config` is never null; the hm read is `or { }`-guarded).
        let
          locator = classesByName.${classEntry.name}.producerConfig or null;
        in
        if locator == null then
          [ ]
        else
          let
            cfg = locator {
              inherit
                systems
                node
                id
                result
                ;
            };
          in
          if cfg == null then [ ] else [ (prelude.nameValuePair key cfg) ]
    ) allNodeIds
  );
  deltaOf =
    name: classCfg: id:
    [ freeformAbsorber ]
    ++ (bind.wrapAll {
      modules = terminalModulesAt id name; # projectClass over reach (Phase 2 Task 3)
      bindings = bindingsAt id;
      defaultMergeStrategy = classCfg.defaultMergeStrategy;
      inherit producerConfigs;
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
            hostModules = terminalModulesAt id name; # projectClass over reach (Phase 2 Task 3)
            inherit classCfg;
            bindings = bindingsAt id;
            inherit producerConfigs; # CHORAG §5.1 producer-scoped config-thunk map (the fixpoint knot)
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
    lowerDefer
    # Phase 2 Task 2/3: the class-slice projection over `reach` (now the terminal's content source via
    # `terminalModulesAt = projectClass`) + the `classSubtreeAt` down-fold it subsumes, both exposed so the
    # ANCHOR witness (`projectClass id class == classSubtreeAt id class` on a no-edge node) compares them.
    projectClass
    classSubtreeAt
    ;
}
