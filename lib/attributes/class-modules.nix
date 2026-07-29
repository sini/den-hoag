# Class-seeds stratum — HOAG attribute 9 (spec §2.10). At each scope node, class content at a channel
# coordinate is a DEMAND-DRIVEN QUERY over that node's resolved aspects and its own resolution-stratum
# declarations, evaluated per (node, channel), with no whole-map transform. The value is inert data —
# `{ <channel> = [ { module; sharedFoldKey } ]; }` — consumed by attribute 12 (`output-modules`) at the
# terminal crossing and at the gen-edge seed accessor.
#
# The `inject`/`reroute` declarations (§2.3 resolution) are the node's RELOCATION RELATION Ρ(n) ⊆ Ch × Ch.
# A channel's content is the concatenation of the RAW seeds of its PREIMAGE — the set of channels whose
# content comes to rest there — which is reverse reachability over Ρ(n) (Arntzenius 2016, Datafun reverse
# reachability) with the reverse index hoisted out of the per-channel loop. The answer is therefore a
# function of the DECLARATION SET and not of the declaration ORDER.
#
# NO EFFECT RUNTIME: the body is field reads + list appends + gen-graph accessor queries. classifyKey is
# table dispatch (no algorithm); a channel key is skipped here (its data flows through the collection
# stratum, attributes 10/11), a facet is behaviour (not content), an unregistered key aborts named
# (Law A1/A2).
#
# Deps: prelude (folds/filters/hasPrefix), resolve (attr), graph (gen-graph's reachability calculus —
# `cycles`, `transpose`, `reachableFrom`). Instance args: classNames (the registered channel coordinates =
# the query's answer domain); classifyKey (the §2.2 three-branch dispatch, which owns the unregistered-key
# abort).
{
  prelude,
  resolve,
  graph,
}:
{
  classNames,
  classifyKey,
  # §4.1 the prebuilt-arm exclusivity (concern-aspects `artifactExclusive`): a pure per-aspect check that an
  # aspect declaring `artifact` carries no non-empty class content. Threaded into `assertKeysRegistered` (the
  # per-aspect totality gate), so a malformed prebuilt aspect aborts on the eval path. Defaults to the
  # identity pass (`_: true`), so a caller not threading it is byte-identical.
  artifactExclusive ? (_: true),
}:
let
  # A class reference on an inject/reroute declaration is an entry (identity law) or, defensively, a
  # bare class-name string; resolve it to the channel coordinate (the class name).
  className =
    c:
    if builtins.isAttrs c then
      (c.name or (throw "den-hoag: class-modules: class reference carries no name (${builtins.toJSON c})")
      )
    else
      c;

  # `isEmptyDeferredModule` — under the single typed tree a class key's body is a deferredModule WRAP
  # `{ imports = [ … ]; }` (gen-merge `{ _file; imports }`), so an empty declaration is `{ imports = [ { } ]; }`
  # — NOT `== { }`. The shared `module-shape.nix` helper peels the wrap and judges emptiness (an empty wrap /
  # raw `{ }` body is a declared no-op; a fn/path leaf is real content). Dropping an empty class body keeps
  # seed counts on REAL content (the F1/F4/F5 no-double-deliver witnesses), byte-parity with the raw walk's
  # `m == { }` drop.
  inherit (import ../module-shape.nix { inherit prelude; }) isEmptyDeferredModule;

  # THE ONE per-aspect class-slice extraction (Phase 2 Task 2) so the seed query AND `projectClass`
  # — the reach-based projection — share EXACTLY one extraction.
  # `classSliceOf aspect class` = the `class`-C contribution of a SINGLE resolved-aspect node
  # (`{ key; content; }`): the aspect's `content.${class}` deferredModule IFF that key is a registered
  # `class` key (via `classifyKey`, §2.2) and its body is a non-empty declaration. Returns a `[ { module; } ]`
  # list (0 or 1 entry — one class = one content key). A `_`-prefixed / channel / facet key is skipped; an
  # EMPTY body (`{ }` raw, or the typed `{ imports = [ { } ]; }` wrap) is a declared no-op, dropped so seed
  # counts reflect real content. `projectClass` maps `.module` (bare, for the classSubtreeAt anchor).
  # ── FORWARD-SOURCE-CLASS ACCEPTANCE (iv-b, reach-sourced exemption). A live forward SOURCE class (an
  # unregistered `fromClass` a `meta.__forward` spec on a REACHED node names — output-modules
  # `forwardSourceClassesAt`) MATERIALIZES its content instead of aborting, so `routeRemapFor` can move it
  # (the collect-coupling: silencing the abort alone delivers nothing). A NON-exempt unregistered key STILL
  # aborts in `classifyKey` (Law A1/A2 typo-protection preserved). The `exempt` set (a keyset attrset) is
  # threaded per-node from the reach's forward specs; `{ }` for every non-forward node ⇒ byte-identical.
  forwardSourceClassesOf =
    nodes:
    prelude.foldl' (
      acc: n:
      let
        f = (n.content.meta or { }).__forward or null;
      in
      if f == null then acc else acc // { ${f.fromClass} = true; }
    ) { } nodes;

  classSliceOf =
    exempt: aspect: class:
    let
      content = aspect.content;
      # exempt short-circuits BEFORE classifyKey (a forward source never trips the typo-abort); a registered
      # non-class key (channel/facet) still yields `[ ]`; a non-exempt unregistered key aborts in classifyKey.
      isCollectable =
        !(prelude.hasPrefix "_" class)
        && content ? ${class}
        && ((exempt ? ${class}) || classifyKey content.name class == "class");
    in
    if !isCollectable then
      [ ]
    else
      let
        m = content.${class};
      in
      if isEmptyDeferredModule m then
        [ ]
      else
        # Carry the owning resolved-aspect node's `sharedFoldKey` (resolved-aspects.nix, ADDITIVE — `.module`
        # readers ignore it) so the `classSubtreeAt` output-fold can dedup a genuinely-shared host+user aspect
        # cross-scope, keyed identically to the reach/terminal fold. `null` for a node with no stamped key.
        [
          {
            module = m;
            sharedFoldKey = aspect.sharedFoldKey or null;
          }
        ];

  # Per-aspect totality force: (a) the §4.1 prebuilt-arm EXCLUSIVITY (`artifactExclusive` — an aspect
  # declaring `artifact` with non-empty class content aborts NAMED); (b) a WHNF force of every non-`_`,
  # non-exempt content key, which FIRES THE CLOSED GATE on a typo — an undeclared non-attrset leaf throws
  # NAMED at the type. Key-typo VALIDATION is the gate's job now (not a classifyKey re-classification), but
  # the gate is lazy — this per-aspect force is what triggers it, so a typo on a RESOLVED aspect aborts while
  # an unresolved aspect is never reached (laziness). WHNF only: a class key forces to its deferredModule
  # wrapper (cheap, no user-content descent); an undeclared attrset key is an admitted nested-aspect namespace
  # (no throw at WHNF — its own content validates only when it is included and resolved). `exempt`
  # forward-source keys materialize via `classSliceOf`, so they are skipped here.
  assertKeysRegistered =
    exempt: aspect:
    let
      content = aspect.content;
      keys = builtins.filter (k: !(prelude.hasPrefix "_" k) && !(exempt ? ${k})) (
        builtins.attrNames content
      );
    in
    builtins.seq (artifactExclusive content) (
      prelude.foldl' (acc: k: builtins.seq content.${k} acc) null keys
    );

  # ── the node's RELOCATION RELATION Ρ(n) ⊆ Ch × Ch, off its resolution-stratum `reroute` acts ───────────
  # A relocation to self is the IDENTITY relocation and is dropped here, by construction: a `from == to`
  # pair contributes no edge, so a self-relocation is a no-op that no attrset literal is ever built from.
  relocationsOf =
    acts:
    builtins.filter (e: e.from != e.to) (
      map (a: {
        from = className a.from;
        to = className a.to;
      }) (builtins.filter (a: a.__action == "reroute") acts)
    );

  # ── Ρ(n) AS A GRAPH, not a list to walk ───────────────────────────────────────────────────────────────
  # gen-graph's primitives take exactly one shape — an accessor `{ edges; nodes }` — and supplying it is the
  # whole of the adaptation.
  # THE NODE DOMAIN IS `Ch ∪ endpoints(Ρ(n))`, NOT `Ch`. Narrowing it to `Ch` is byte-identical for an
  # unregistered TARGET and for an unregistered SOURCE, and LOSES CONTENT for an unregistered INTERMEDIATE:
  # `transpose` materialises through `genAttrs nodes`, so an out-edge from a channel outside `nodes` is never
  # materialised, and content routed `A → X → B` with `X ∉ Ch` reaches nothing. Totality is not agreement —
  # every primitive here is total on the narrow domain, it simply answers a different question there. No
  # validator rejects an unregistered endpoint (`className` passes a bare string straight through), so the
  # wide domain is in-domain.
  # THE ANSWER DOMAIN IS STILL `Ch`: the equation keys over `classNames`, so an unregistered channel can be a
  # preimage SOURCE and can never be a query ANSWER.
  # THE ADDED ENDPOINTS ARE SORTED, AND THE SORT IS LOAD-BEARING. Appending them in act order would make the
  # source order depend on the ORDER of the act list, which is the order-dependence this whole formulation
  # exists to remove. Registered channels keep their REGISTERED order, which is a semantics; unregistered
  # endpoints have no registry order, so name order is the only order-free choice available.
  # It also removes an inconsistency inside the frame itself: `cycles` traverses the RAW accessor, so `nodes`
  # bounds which channels are TESTED and never the traversal — on the narrow domain the guard would already
  # see THROUGH an unregistered channel while the preimage did not, and would name an incomplete witness.
  # TAKES THE EDGE LIST, NOT THE NODE: Ρ(n) must be tested for emptiness before deciding to build a graph at
  # all, and Nix performs no common-subexpression elimination — recomputing it here would reintroduce, at the
  # frame, exactly the unshared-recomputation the preimage's `let` avoids.
  relOf = es: {
    edges = c: map (e: e.to) (builtins.filter (e: e.from == c) es);
    nodes =
      classNames
      ++ builtins.sort builtins.lessThan (
        prelude.unique (
          builtins.filter (d: !(builtins.elem d classNames)) (
            prelude.concatMap (e: [
              e.from
              e.to
            ]) es
          )
        )
      );
  };

  # ── PREIMAGE of a channel: every channel whose content lands here ─────────────────────────────────────
  # Content comes to rest exactly at a channel with NO outgoing relocation, so the preimage is empty unless
  # `c` is such a REST POSITION, and is then `{ c } ∪ { d : d reaches c }`. That second set is
  # `reachableFrom` over the TRANSPOSED relation — reverse reachability (Arntzenius 2016) with the reverse
  # index hoisted out of the per-channel loop, which is what makes the closure shared rather than re-walked.
  # `reachableFrom` is a C-level BFS closure and answers MEMBERSHIP; enumerating PATHS to answer the same
  # membership question is where an exponential lives.
  # The domain-order filter is load-bearing: `reachableFrom` returns traversal order, which is not a
  # semantics. Intersecting in the frame's OWN node order — registered channels in registry order, then the
  # relation's unregistered endpoints in name order — is what makes the source order deterministic in the
  # DECLARATION SET rather than in the traversal. It filters the frame's nodes, NOT `classNames`: filtering
  # `classNames` here would drop an unregistered INTERMEDIATE back out of the preimage and lose its content.
  preimageOf =
    frame: c:
    if frame.rel.edges c != [ ] then
      [ ]
    else
      let
        back = prelude.genAttrs (graph.reachableFrom frame.rev c) (_: true);
      in
      builtins.filter (d: d == c || back ? ${d}) frame.rel.nodes;

  # ── CANONICAL SOURCE ORDER: the target's own content first, then the rest of the preimage in registered-
  # channel order. Deterministic in the DECLARATION SET, independent of declaration ORDER. ────────────────
  # The preimage is LET-BOUND: Nix performs no common-subexpression elimination, so reading it twice would
  # walk the closure twice for a byte-identical answer.
  # THE Ρ(n) = ∅ SHORT-CIRCUIT. `frame == null` is the witness that the node declares no relocation. The fast
  # path is a PROVEN IDENTITY, not a second semantics: with no edges the relation has no endpoints, so the
  # node domain is exactly `classNames`; `transpose` is empty, so `reachableFrom` answers `[ ]`, so the
  # preimage filters that domain down to exactly `[ c ]`. The widened domain therefore costs nothing on this
  # path — it is not merely unused, it is equal to `classNames`.
  # IT BRANCHES ON ORDER, NEVER ON CONTENT. Both arms feed the SAME raw-seed concatMap; what the branch
  # selects is a list of channel NAMES. There is exactly one content expression here — a fast path that
  # computed content by a second expression would be a two-path divergence, and this is not that.
  srcOrder =
    frame: c:
    if frame == null then
      [ c ]
    else
      let
        p = preimageOf frame c;
      in
      (if builtins.elem c p then [ c ] else [ ]) ++ builtins.filter (d: d != c) p;

  # ── RAW seeds of ONE channel at ONE node: aspect content, then node-local injections ──────────────────
  # Injections are raw content at their declared channel, so they relocate exactly as aspect content does
  # (the query concatMaps over the preimage) — reproducing inject-then-relocate ordering by construction.
  # `sharedFoldKey = null` on an injection is the anon rule: node-local content, never cross-scope deduped.
  # `resolvedAspects` and `injects` are PASSED IN, bound once per node by the equation. Neither depends on
  # the channel, so re-reading or re-filtering them here would repeat a node-level value K times per node.
  rawSeedsAt =
    resolvedAspects: exempt: injects: d:
    prelude.concatMap (a: classSliceOf exempt a d) resolvedAspects
    ++ map (a: {
      inherit (a) module;
      sharedFoldKey = null;
    }) (builtins.filter (a: className a.class == d) injects);

  # ── THE QUERY. Per (node, channel). Total. Order-free in the act list. ───────────────────────────────
  # `exempt` and `injects` are PARAMETERS, bound once per node by the equation. Computing either here would
  # rebuild it once per channel, because `genAttrs classNames` calls this K times; neither depends on `c`.
  classSeedsAt =
    frame: resolvedAspects: exempt: injects: c:
    prelude.concatMap (rawSeedsAt resolvedAspects exempt injects) (srcOrder frame c);

  # ── THE ACYCLICITY GUARD ──────────────────────────────────────────────────────────────────────────────
  # THE LAW: Ρ(n) restricted to distinct endpoints is acyclic. A cycle among distinct channels has no rest
  # position and therefore no content answer; aborting is the only total alternative to inventing one.
  # The rest-position formulation has no recursion that a cycle could trip, so it ANSWERS A CYCLIC RELATION
  # SILENTLY unless the guard is explicit — hence the guard sits INSIDE the frame, forced once per node that
  # declares a relocation, before any channel is answered. `graph.cycles` is per-node self-reachability and
  # names EVERY channel in a cycle, which is a stronger abort witness than one path. The throw is
  # `builtins.tryEval`-containable; a Nix `infinite recursion` is not.
  # ORDER IS LOAD-BEARING: the identity-drop runs BEFORE the graph is built, so a self-relocation is
  # invisible here and stays a no-op rather than becoming an abort. With the emptiness test reading the
  # relation's OUTPUT, a node whose only relocation is a self-relocation takes the fast path — the same
  # no-op answer, reached without building a graph.
  # Ρ(n) = ∅ ⇒ NO FRAME. `null` is the witness the source order branches on: with no frame there is no
  # `cycles` call and no `transpose` call, so a node declaring no relocation does no graph work at all.
  # SKIPPING THE GUARD THERE IS SOUND, not a laziness accident: `cycles` is `filter selfReachable nodes` and
  # every `edges c` is `[ ]` on an edgeless relation, so its answer is decided rather than suppressed. A
  # relation that CAN carry a cycle always has an edge and always builds the frame.
  frameAt =
    id: acts:
    let
      es = relocationsOf acts;
    in
    if es == [ ] then
      null
    else
      let
        rel = relOf es;
        cyc = graph.cycles rel;
      in
      if cyc != [ ] then
        throw "den-hoag: class relocation cycle at node '${id}': ${builtins.concatStringsSep ", " cyc} (a relocation cycle has no rest position; declare a relocation forest)"
      else
        {
          inherit rel;
          # Mokhov 2017 §5.2 — the SAME primitive the relation producer (`lib/default.nix`) already uses for
          # the inverse-edge job, whose comment there names the hand-rolled from/to swap as the thing NOT to
          # write. See REFERENCE.md.
          rev = graph.transpose rel;
        };
in
{
  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, exported for `projectClass`
  # (output-modules Task 2/3). NEITHER is an equation record — the assembly (attributes/default.nix) selects
  # the equations below into the equations map and threads these to `mkOutputModules` separately (a bare
  # function would break gen-resolve's two-stratum equation classification if spread into the map).
  inherit
    classSliceOf
    assertKeysRegistered
    forwardSourceClassesOf
    ;

  # THE MEMO. `resolve.attr` memoizes per (node, attribute); `genAttrs` memoizes per channel and forces only
  # the channel demanded. This attrset is the query's MEMO TABLE, not its definition.
  # EVERY NODE-LEVEL VALUE IS BOUND HERE, in the compute's `let`, so each is computed once and shared by
  # every channel `genAttrs` demands: the node's resolved aspects, its act list, the FRAME (so the acyclicity
  # guard fires once and the transposed relation is materialized once), `exempt`, and the filtered `injects`.
  # Binding any of them inside the per-channel query instead would rebuild it K times per node.
  class-seeds = resolve.attr {
    name = "class-seeds";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [
      "resolved-aspects"
      "declarations"
      "content-key-totality"
    ];
    compute =
      self: id:
      let
        resolvedAspects = self.get id "resolved-aspects";
        acts = (self.get id "declarations").actions.resolution or [ ];
        exempt = forwardSourceClassesOf resolvedAspects;
        injects = builtins.filter (a: a.__action == "inject") acts;
        frame = frameAt id acts;
      in
      builtins.seq (self.get id "content-key-totality") (
        prelude.genAttrs classNames (classSeedsAt frame resolvedAspects exempt injects)
      );
  };

  # THE TOTALITY DRIVER. §2.2 key-typo validation is a LAZY gate: in a lazy language a validation happens
  # only when the value is forced, so the gate needs a DRIVER. This is the NODE-indexed one, demanded by
  # `class-seeds`. It does NOT replace the terminal's ASPECT-indexed `seq (assertKeysRegistered exempt n)`
  # in `projectClass`, and cannot: the terminal has no node id to demand this attribute at.
  #
  # IT IS A SEPARATE ATTRIBUTE, NOT A `seq` INSIDE `resolved-aspects`, on two grounds:
  #   (a) `resolved-aspects` is `kind = "circular"` and names ITSELF in `readsAttrs`; forcing its own output
  #       inside its own compute is not obviously well-founded, and the surrounding contract (A17) is
  #       explicit that the self-read is passed UNFORCED.
  #   (b) `resolved-aspects` has readers that want the aspect list and not its classification (the collection
  #       stratum, resolved-settings, the output stratum, and `reach` together with everything reading
  #       through it). A force there would make every one of them pay classification they never asked for —
  #       a BROADENING of eager work, which is the opposite of what a demand-driven query claims.
  content-key-totality = resolve.attr {
    name = "content-key-totality";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [ "resolved-aspects" ];
    # `assertKeysRegistered` is unchanged; only the DEMAND for it moves. Per resolved aspect at the node,
    # WHNF only — reached by demand rather than by a `seq` wired ahead of a whole-map build. It additionally
    # carries the §4.1 `artifactExclusive` check, so the node path gains the terminal's exclusivity abort.
    compute =
      self: id:
      let
        resolvedAspects = self.get id "resolved-aspects";
        exempt = forwardSourceClassesOf resolvedAspects;
      in
      prelude.foldl' (acc: a: builtins.seq (assertKeysRegistered exempt a) acc) null resolvedAspects;
  };
}
