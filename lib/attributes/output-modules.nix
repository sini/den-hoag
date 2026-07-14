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
  # unset, so this filter is byte-identical for one. Shared by the edge renderer (`deliveryEdgesAt`) and
  # the terminal gather (`deliveryModulesAt`) — one source of the firing-scope delivery set.
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
  # delivered content byte-matches), P1-unexercised; fixture-surfaced re-opener. Used by BOTH the edge
  # renderer (the fold's target root) and the terminal gather (the "targets this root" filter), so the
  # two stay in lockstep — the #66 single-path invariant depends on them agreeing.
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
  # gather only). ROOT RESTRICTION: an ancestor member whose class the firing cell OWNS is restricted to
  # its SHARED (`den.default`) modules by `filterRootModules` below (v1 route.nix:540-552, R-ROOT-FILTER)
  # — this is what keeps a host's OWN home-manager content (the corpus's `roles.media`
  # `programs.spicetify`, at host + user scope) from doubling into a user cell's gather (ledger u25).
  collectedMembersOf =
    n:
    prelude.foldl' (acc: a: [ a ] ++ acc) [ ] (scope.ancestors result n)
    ++ [ n ]
    ++ scope.descendants result n;

  # ── R-ROOT-FILTER (the filterRootModules twin, v1 route.nix:532-552; design §B Decision 2) ───────────
  # In a delivery's per-member source gather, for a member `nid` that is a PROPER ANCESTOR of the firing
  # cell `n`, if the bucket class `srcClass == producingClassOf n` (the cell OWNS the class), restrict
  # `nid`'s `srcClass` modules to the SHARED (`den.default`-radiated) ones — drop `nid`'s scope-OWN
  # declarations (they are that entity's OWN content, not aggregation fodder). The cell's OWN bucket
  # (`nid == n`) and its descendants are NEVER filtered; a class the cell does NOT produce keeps `nid`'s
  # full bucket. This is v1's `ownedClasses ∋ fromClass ⇒ filter isDenDefaultModule rootModules`: den-hoag
  # reads the SHARED flag off the class-modules `__shared` sidecar (A1's marker; positionally aligned with
  # the class bucket) rather than v1's `@default` module-key suffix. IDENTITY: a member that is `n` or a
  # descendant, or a class the cell does not own, is returned unfiltered ⇒ byte-identical where the rule
  # is corpus-inert (axon-01 — the twin fires only when an ANCESTOR carries the cell's produced class).
  ancestorSetOf = n: prelude.foldl' (acc: a: acc // { ${a} = true; }) { } (scope.ancestors result n);
  filterRootModules =
    n: nid: srcClass: mods:
    let
      isProperAncestor = (ancestorSetOf n) ? ${nid};
      cellOwnsClass = srcClass == producingClassOf n;
    in
    if isProperAncestor && cellOwnsClass then
      let
        sharedFlags = (classModulesAt nid).__shared.${srcClass} or [ ];
        keepAt = i: i < builtins.length sharedFlags && builtins.elemAt sharedFlags i;
      in
      # Positional zip: keep `mods[i]` iff `sharedFlags[i]` (the A1 sidecar is aligned with the bucket).
      # A missing/short sidecar (defensive) treats the entry as OWN (drop) — the restriction never keeps
      # an unmarked ancestor module, matching v1's "shared-only" ceiling.
      prelude.concatMap (i: if keepAt i then [ (builtins.elemAt mods i) ] else [ ]) (
        prelude.imap0 (i: _: i) mods
      )
    else
      mods;

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
            # ancestors = [ ] ⇒ the pre-#74 members exactly. R-ROOT-FILTER NOTE: this is the TRACE/outputFor
            # render; the per-(member,class) shared-only restriction is a CONTENT filter applied at the
            # TERMINAL gather (`deliveryModulesChain`, the sole drv path), not here — the trace renders edge
            # IDENTITY (the members LIST, unchanged: `[host, cell]`) and `outputFor` is not a shipped
            # artifact (§9/§11: P2 hashes the terminal). So the members list stays whole; the filter never
            # perturbs the frozen trace (the parity oracle) — only the built content.
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

  # ── #66 delivery→terminal unification (design note §9, the terminal dual of v1's post-route read) ────
  # den-hoag's A15 fold unifies the content-mover with the trace onto ONE edge set (`edgesForRoot` feeds
  # BOTH `outputFor` and `traceFor`), so ALL routed/forwarded content lives in the delivery-edge stream.
  # But the TERMINAL crossing reads `classSubtreeAt` alone (same-class buckets), so the CROSS-class routed
  # content (os→nixos `programs.zsh.enable`, home-manager→nixos `home-manager.users`) is present in
  # `outputFor` yet ABSENT from the built drv. v1 SEPARATES the layers — routes `appendToClass` into the
  # target class bucket, the terminal reads POST-route buckets, the trace is a DESCRIPTIVE parallel — so v1
  # never double-counts; den-hoag CANNOT copy that (under the unified edge set the content would
  # materialize TWICE in `outputFor`). Instead the terminal's INPUT widens to match the fold's OUTPUT.
  #
  # `deliveryModulesAt root class` = the CROSS-class delivery module content delivered at (root, class):
  # every CLASS-source delivery TARGETING this root+class, its SOURCE-class bucket gathered across the
  # delivery's `[ firing ] ++ descendants` subtree — the #62c source-members that already aggregate the
  # descendant cells — placed at the delivery path (merge ⇒ direct, nest ⇒ setAttrByPath, the fold's
  # `place`). Own-BUCKET per member (`classModulesAt`, not `classSubtreeAt`) so the subtree aggregates
  # ONCE — the ADDITIVE realization (§9 risk 2: `classSubtreeAt ++` a delivery-only gather, never a
  # wholesale `outputFor` read whose materialize-vs-raw-list shape would perturb the drv). NB (catalog
  # v73 review): this is the CORRECTED single-count, not a mirror of the fold's output — in the general
  # host-fired-delivery-with-cell-carried-content case, `outputFor`'s collected union reads each #62c
  # member's bucket through the members list and can LATENTLY double a descendant's content where this
  # gather counts it once (corpus-vacuous; outputFor is not a shipped artifact surface — P1 traces are
  # identity-level and P2 hashes the terminal, which reads THIS gather). The scan walks `[ root ] ++
  # descendants root` so a #53c cell-fired delivery that `appendToParent`-targets this root is picked up
  # (LIVE since #53c: `deliveryTargetRootOf` resolves the parent target; a delivery without the flag
  # targets its own firing node, so only `root` itself contributes for those).
  #
  # SINGLE-PATH INVARIANT (§9): same-class (the fold) ⊥ cross-class (delivery). A MODULE provide
  # (`module != null`) collects the TARGET class — its provided module rides the target scope's OWN class
  # bucket (translateDelivery, `sourceClass == targetClass`; `classSubtreeAt` already reads it), so it
  # contributes NOTHING NEW here (skip — re-adding would double). A same-class MERGE class-source
  # (from == to == `class`, `mode == "merge"`) gathers the class bucket at the ROOT path exactly where
  # `classSubtreeAt` already placed it ⇒ DOUBLE — the loud guard aborts (corpus emits none; a same-class
  # NEST places at a DISTINCT path, v1-faithful, never a double, so it is allowed through). A17: the scan
  # walks the delivery declaration set + the id spine + class-modules ATTRIBUTE presence, never module
  # bodies. IDENTITY: a delivery-free root ⇒ `[ ]` at every class ⇒ terminal = `classSubtreeAt` exactly
  # (the 840 baseline unchanged).
  # #75a (design §11, C1 — ratified): THE SOURCE-SIDE CHAIN READ, the source dual of #66's terminal
  # read. A delivery's collected source, per member m and source class C, is
  # `(classModulesAt m).C ++ deliveryModulesAt m C` — the cross-class delivery output already targeted
  # at (m, C) SPLICES into the source, reusing this very gather as the chain link (the corpus chain:
  # the home-platform route {homeLinux → homeManager} fires at the user cell, home-platform.nix:38-42,
  # and the hm userForward's source then reads the routed LOCALE content — v1's appendToClass appends
  # at the firing scope and getCollectedSource reads the POST-route bucket; here no bucket is ever
  # touched — the M2 terminal-only posture: deliveryEdgesAt/outputFor/trace UNCHANGED, outputFor stays
  # composition-incomplete by design (P2 hashes the terminal, which reads this gather)). SINGLE-PATH: a
  # chained source class (homeManager) has NO terminal ⇒ its routed content is consumed once, by the
  # forward source alone. A12: base-then-routed (v1's append order; order owner-waived, u24).
  # TERMINATION: the read descends strictly along fromClass edges over the class-target DAG (acyclic on
  # the corpus — the §11 census); a (scope, class) revisit ON THE RECURSION PATH aborts LOUD
  # (errors.deliveryChainCycle — the containmentCycle precedent; v1's own complex-forward topoSort
  # throws on a cycle, route.nix:496). The seen-set is PATH-LOCAL (threaded down, not global), so a DAG
  # diamond — two deliveries legitimately sourcing one (scope, class) on separate branches — never
  # false-aborts. IDENTITY: no cross-class delivery into C ⇒ `++ [ ]` ⇒ byte-identical (the 904/71
  # baseline).
  deliveryModulesAt = deliveryModulesChain { };
  deliveryModulesChain =
    seen: root: class:
    let
      key = "${root}|${class}";
      seen' = seen // {
        ${key} = true;
      };
      forNode =
        n:
        prelude.concatMap (
          d:
          if deliveryTargetRootOf n d != root || d.targetClass.name != class then
            [ ]
          else if d.module != null then
            [ ] # module provide rides the target's OWN class bucket (classSubtreeAt reads it) — no re-add
          else if d.sourceClass.name == class && d.mode == "merge" then
            errors.sameClassMergeDelivery {
              inherit class;
              scope = n;
              root = root;
            }
          else
            let
              srcClass = d.sourceClass.name;
              members = collectedMembersOf n; # #74a — the same member set the edge render names
              # #75a — base-then-routed per member: the member's OWN bucket, then the delivery output
              # already targeted at (member, srcClass) — the chain link (path-local seen-set threaded).
              # CROSS-class only: a same-class NEST delivery (from == to, distinct path — the #66
              # allowance) sources its own target class, so a chain link would SELF-loop by
              # construction (chain(root, class) re-entered from within itself ⇒ the cycle guard);
              # its source stays the pre-#75a base-only read (the pinned witness surface,
              # test-same-class-nest-delivery-allowed).
              # R-ROOT-FILTER: an ANCESTOR member's own `srcClass` bucket is restricted to its SHARED
              # (`den.default`) modules when the firing cell OWNS `srcClass` — v1 filterRootModules
              # (route.nix:540-552). The cell's own bucket and descendants pass unfiltered; the routed
              # chain link (`deliveryModulesChain`) is a distinct-scope delivery, never an ancestor-own
              # copy, so it is not restricted.
              srcMods = prelude.concatMap (
                nid:
                filterRootModules n nid srcClass ((classModulesAt nid).${srcClass} or [ ])
                ++ (if srcClass == class then [ ] else deliveryModulesChain seen' nid srcClass)
              ) members;
            in
            if d.mode == "merge" then
              # merge-mode sources land TOP-LEVEL at the target terminal, whose deltaOf/instantiate
              # wrapAll binds their channel/entity formals wholesale — no wrap here (byte-gate: the
              # os→nixos path stays byte-identical).
              srcMods
            else
              # NEST-mode sources (#74b) are placed UNDER a path, INVISIBLE to the terminal's wholesale
              # wrapAll — their channel/entity formals would go unbound (the corpus's syncthing member
              # hm module demands the `replicateHome` channel arg: `home-manager.users.<u>` cannot
              # supply it — the re-probe abort). v1 evaluates EVERY forward-source module (root + own)
              # in the target hm eval with the FIRING user scope's args (the complex forward's
              # extraArgsFor threading, route.nix — member.nix reads its OWN emission, the F4 raw read),
              # so the wrap binds with the FIRING node's bindings (`bindingsAt n` — the cell), the same
              # gen-bind DI the terminal runs (deltaOf, r2 obligation 6). A formal-less (attrset)
              # module passes through unwrapped — the #53c/#74a witness shapes byte-unchanged.
              map (m: nestAtPath d.path m)
                (bind.wrapAll {
                  modules = srcMods;
                  bindings = bindingsAt n;
                }).modules
        ) (deliveriesAt n);
    in
    if seen ? ${key} then
      errors.deliveryChainCycle {
        scope = root;
        inherit class;
      }
    else
      prelude.concatMap forNode ([ root ] ++ scope.descendants result root);

  # The per-class TERMINAL assembly (the LAW, §9): the same-class subtree fold FIRST (`classSubtreeAt`,
  # A12 base) then the routed cross-class delivery AFTER (`deliveryModulesAt`, v1's `appendToClass`
  # appends). Consumed at the three terminal reads (`hostModules`/`deltaOf`/`contentIdsOf`); the fold
  # accessor (`classBucketsOf`/`contentsOf`) STAYS `classSubtreeAt` — delivery reaches `outputFor` via the
  # edges, so widening the fold read too would double there.
  terminalModulesAt = id: class: classSubtreeAt id class ++ deliveryModulesAt id class;

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
      modules = terminalModulesAt id name; # #66: fold ++ cross-class delivery (identity-defaulted)
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
            hostModules = terminalModulesAt id name; # #66: fold ++ cross-class delivery (identity-defaulted)
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
