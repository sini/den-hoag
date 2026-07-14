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
  # THE ONE per-aspect class-slice extraction (Task 2, `attributes/class-modules.nix classSliceOf`, threaded
  # through `attributesLib.mkClassSlice` with the discovered `classifyKey`). `classSliceOf aspect class`
  # returns that aspect's `class`-C bucket contribution as `[ { module; shared; } ]` (0 or 1) — `projectClass`
  # maps `.module` (bare, the classSubtreeAt anchor). Native default reproduces the bucket read locally but is
  # ALWAYS supplied by den-hoag's assembly (the class-modules extraction is the single source); the default is
  # a defensive identity for a caller that constructs `mkOutputModules` standalone without the extraction.
  classSliceOf ? (_: _: [ ]),
  # §2.2 TOTALITY assertion (Task 3, `class-modules.nix assertKeysRegistered`). Forces classification of every
  # non-`_` content key of a REACHED aspect (abort NAMED on a genuinely unregistered typo key); `projectClass`
  # runs it per reached aspect so a typo cannot silently vanish on the drv path (spec §2.2 ruling 2026-07-14).
  # Native default is the no-op identity (standalone callers without the extraction skip the totality check).
  assertKeysRegistered ? (_: null),
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
  # this walks the bucket SPINE (list appends), never a module body. FORCING HONESTY: the gather DOES newly
  # force each descendant's `class-modules` ATTRIBUTE — i.e. the §2.2 key CLASSIFICATION of every content
  # key on the descendant's resolved aspects (the mechanism that surfaced the ledger-u14 `wsl` abort: cells
  # whose class-modules were previously never read now classify at the host's assembly) — while the module
  # BODIES inside each bucket stay unforced (the A17 claim above is about bodies, and stays true). IDENTITY:
  # a cell-less / descendant-less node ⇒ `[ id ]` ⇒ `(classModulesAt id).${class}` exactly (the 820 baseline
  # is the proof — unchanged).
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
  };

  # `routesAt id` = the class-remaps of the OWN-scope routes fired at `id` — the deliveries that target the
  # firing scope ITSELF. An `appendToParent` delivery is EXCLUDED here (it targets the containment parent;
  # the HOST gathers it via `parentTargetedRoutesAt`, Task 2) so a cell-fired parent-targeted route is
  # remapped ONCE, at the host, never doubled at the cell.
  routesAt =
    id: map lowerRoute (builtins.filter (d: !(d.appendToParent or false)) (deliveriesAt id));

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
      map (d: {
        route = lowerRoute d;
        sourceScope = c;
      }) (builtins.filter (d: (d.appendToParent or false) && deliveryTargetRootOf c d == id) (deliveriesAt c))
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
  remapOver =
    srcScope: route:
    prelude.concatMap (
      # argEnvWrap wraps EACH slice module FIRST (so the arg-env `_module.args` lands at the SLICE's eval
      # level), THEN placeSlice nests the wrapper at the route path — the `_module.args = adaptArgs args`
      # must be INSIDE the target submodule's nested eval (e.g. inside `devshells.default`), NOT at the
      # outer level (where it would not reach the nested submodule's args). Order is load-bearing.
      n: placeSlice route.at (map (m: argEnvWrap route srcScope m) (map (e: e.module) (classSliceOf n route.from)))
    ) (result.get srcScope "reach");

  routeRemapFor =
    id: class:
    # (1) OWN-scope routes fired at `id` (Task 1) — the source node set is `reach id`.
    prelude.concatMap (
      route: if route.to == class && guardHolds route id then remapOver id route else [ ]
    ) (routesAt id)
    # (2) DESCENDANT-DRIVEN parent-targeted routes (Task 2, #10 hm-user-detect) — a cell-fired
    #     `appendToParent` route targeting THIS host: the SOURCE is the descendant cell (`sourceScope`), so
    #     the cell's class-`from` (`home-manager`) slice remaps to `class` (`nixos`) at the route's per-cell
    #     `at` (`[ home-manager users <u> ]`). `reach sourceScope` = the cell's OWN subtree (no host edge),
    #     so the cell's OWN hm content is delivered (the v1 filterRootModules R-ROOT-FILTER: host scope-own
    #     hm does NOT ride the cell's gather), and the guard is evaluated at the CELL.
    ++ prelude.concatMap (
      pt: if pt.route.to == class && guardHolds pt.route pt.sourceScope then remapOver pt.sourceScope pt.route else [ ]
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
    prelude.concatMap (
      n: builtins.seq (assertKeysRegistered n) (map (e: e.module) (classSliceOf n class))
    ) (result.get id "reach")
    ++ routeRemapFor id class;

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
  # here (ci/tests/projection.nix injects the edges via defaultEdgeTargets/mkStub — the complete-reach
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
  channelBindingsAt =
    id:
    let
      received' = received id;
      local = builtins.mapAttrs (_: out: out.contributions or [ ]) received';
      gathered = channelGather { inherit id result; };
      flatten =
        c:
        let
          v = extractContribution c;
        in
        if builtins.isList v then v else [ v ];
    in
    prelude.genAttrs (builtins.attrNames (local // gathered)) (
      ch: prelude.concatMap flatten ((local.${ch} or [ ]) ++ (gathered.${ch} or [ ]))
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
  deltaOf =
    name: classCfg: id:
    [ freeformAbsorber ]
    ++ (bind.wrapAll {
      modules = terminalModulesAt id name; # projectClass over reach (Phase 2 Task 3)
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
            hostModules = terminalModulesAt id name; # projectClass over reach (Phase 2 Task 3)
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
    # Phase 2 Task 2/3: the class-slice projection over `reach` (now the terminal's content source via
    # `terminalModulesAt = projectClass`) + the `classSubtreeAt` down-fold it subsumes, both exposed so the
    # ANCHOR witness (`projectClass id class == classSubtreeAt id class` on a no-edge node) compares them.
    projectClass
    classSubtreeAt
    ;
}
