# Attribute 7 — resolved-aspects (r2 §Resolution Algorithm / §B4). Layer 1 forward expansion seeds
# a joint neededBy+guard monotone LEAST fixpoint; the fixpoint primitive is `gen-scope.circular`
# and aspect identity is `gen-aspects.key`. Every body here is WIRING (field reads, attrset
# assembly, list filters) over exactly one algorithm — the `scope.circular` ascent (Law A1). The
# attribute VALUE is inert data (a deduplicated `[ { key; content; } ]` list), never a loop record.
#
# STRATIFICATION LAW (A9.1): presence resolution reads the graph, never resolved settings. Guards
# receive `{ pathSet, hasAspect }` ONLY. The `seen` set is a keyset (attrset of identity keys); the
# monotone ascent adds keys only, so keyset-eq is a sound convergence test and the least fixpoint is
# unique and arrival-path independent (Knaster–Tarski; the r1 guard-convergence argument, now joint).
#
# Deps: prelude (folds/filters), scope (circular), resolve (attr), aspects (key), select (matches +
# scope adapter for selector-form neededBy). Instance args: allAspects = the compiled aspect
# registry (`config.den.aspects`); directIncludes = the static entity-scoped include list
# (`config.den.include` = [ { at = <entity>; aspects = [ … ]; } ]) — the §370 `directAspects` source.
{
  prelude,
  scope,
  resolve,
  aspects,
  select,
}:
{
  allAspects ? { },
  directIncludes ? [ ],
  # The post-inheritance resolution-ctx enrichment hook `{ id; resolvedAspects; bindings } -> bindings'`
  # (native default = identity, byte-identical). Applied to the enriched-context ONCE per node, producing
  # the ctx handed to `forwardExpand` (seed + fixpoint expansion). A17: it must keep `resolvedAspects`
  # unforced at stamp — see the `ctx` binding in `compute` for the force-boundary law.
  enrichContext ? ({ bindings, ... }: bindings),
}:
let
  keyOf = aspects.key;
  seenEq = a: b: builtins.attrNames a.seen == builtins.attrNames b.seen;
  isSelector = v: builtins.isAttrs v && v ? __sel;

  inherit (import ../dedup-by-key.nix { inherit prelude; }) dedupByKey;

  # `sharedFoldKey` — the v1 STABLE cross-scope dedup key (v1 wrap-classes.nix `computeModuleIdentity` + the
  # ctx suffix, @ pin 11866c16). It discriminates a genuinely SHARED aspect (dedup) from genuinely per-cell
  # content (keep): the A-IDENT `key` plus a ctx-PROJECTION over the aspect's DECLARED formals, by entity
  # `id_hash`. A static aspect reads no ctx ⇒ fully shared (projection `""`). A parametric aspect reading
  # ONLY entity coords projects to those coords' `id_hash`es — invariant across scopes that share the coord
  # (a `{ host, … }:` aspect projects `host=<H>`, identical at the host AND its user cells, so it collapses;
  # a `{ user, … }:` aspect projects the per-cell `user=<u>`, so it stays distinct). A parametric aspect
  # reading a PRESENT non-entity ctx key (an enrichment coord like `isNixos`, no `id_hash`) ⇒ projection
  # `null` ⇒ NEVER deduped (the v1 anon rule, scope-walk.nix:57 — the SAFE DIRECTION: a false-keep never
  # loses content; equal-mergeable duplicate content stays green, and only an option-decl/unique shape on
  # such an enrichment-reading shared aspect would stay doubled — a corpus-zero PRE-EXISTING limitation, not
  # a new regression, and a follow-up widening if a fleet ever needs it). All reads are force-free:
  # `__functionArgs` is a marker, `ctx.<f>.id_hash` is plain data, `aspect ctx` is NOT invoked here (A17 —
  # the node's `content` forces it, this key does not).
  #
  # CONTRACT (v1-faithful): a parametric aspect MUST DECLARE, as a formal, every entity coord it reads. v1's
  # ctx carried only declared coords, so an UNDECLARED `...`/`@`-capture read of a descendant coord (e.g.
  # `{ host, ... }@a: a.user`) is UNSUPPORTED — `__functionArgs` carries only `{ host }`, so such an aspect would
  # project identically at the host and its cells and WRONGLY collapse per-cell content. No corpus/witness
  # aspect relies on it (grep-verified: the only `@`-capture aspect bodies are `meta.guard` presence tests
  # over non-entity keys). A future need is a follow-up (widen the projection), not a silent-loss risk today.
  #
  # NOTE (`{ user, … }:` at a HOST): the host ctx lacks `user`, so `present == entityF == [ ]` and the
  # projection is `""` (not `null`) — a harmless edge: v1-faithfully such an aspect THROWS when resolved at a
  # host (its `user` formal is unbound, so no node materializes to collapse), and `"<key>|"` only ever
  # matches another copy of the SAME aspect (never distinct content).
  ctxProjOf =
    aspect: ctx:
    if !(aspect.__isWrappedFn or false) then
      ""
    else
      let
        # A `__isWrappedFn` aspect is a gen-aspects functor carrying `__functionArgs` (the formal set, the
        # nixpkgs `setFunctionArgs` convention) — read force-free (the body is not invoked here).
        formals = builtins.attrNames aspect.__functionArgs;
        present = builtins.filter (f: ctx ? ${f}) formals;
        entityF = builtins.filter (
          f:
          let
            v = ctx.${f} or null;
          in
          builtins.isAttrs v && v ? id_hash
        ) formals;
      in
      if builtins.length entityF == builtins.length present then
        builtins.concatStringsSep "," (
          prelude.sort (a: b: a < b) (map (f: "${f}=${ctx.${f}.id_hash}") entityF)
        )
      else
        null;

  # A content-free marked node (`meta.__contentless`) exists ONLY to make its A-IDENT key visible above a
  # carrier's target (cond-2). It shares the carrier's key, so a `"${key}|"` foldkey would let the contentless
  # node EVICT the content-bearing carrier at the reach/classSubtreeAt first-wins cross-scope dedup. Null it
  # (dedupByKey's SAFE direction, dedup-by-key.nix): a null-key node is kept AND never enters `seen`, so the
  # node survives (visibility reads `keyOf`, independent of this) but suppresses nothing. Generic — no
  # provides knowledge here; any content-free marked node is nulled.
  sharedFoldKeyOf =
    aspect: ctx: key:
    if (aspect.meta.__contentless or false) then
      null
    else
      let
        p = ctxProjOf aspect ctx;
      in
      if p == null then null else "${key}|${p}";

  # Layer 1 — forward expansion (recursive, evaluates parametrics inline). foldl' over an aspect
  # list: skip already-seen keys, otherwise mark seen, resolve concrete (a parametric __isWrappedFn
  # is invoked with ctx; a static submodule passes through), and recurse its `includes`. Returns
  # { seen; nodes } with seen ⊇ the input seen (monotone). Threads acc.nodes through the fold so
  # sibling roots are all retained. A node is `{ key; content }` — bare, no provenance marker.
  forwardExpand =
    ctx: seen0: aspectList:
    prelude.foldl'
      (
        acc: aspect:
        let
          key = keyOf aspect;
        in
        if acc.seen ? ${key} then
          acc
        else
          let
            concrete = if aspect.__isWrappedFn or false then aspect ctx else aspect;
            newSeen = acc.seen // {
              ${key} = true;
            };
            childResult = forwardExpand ctx newSeen (concrete.includes or [ ]);
          in
          {
            seen = childResult.seen;
            nodes =
              acc.nodes
              ++ [
                {
                  inherit key;
                  content = concrete;
                  # The v1 stable cross-scope dedup discriminator (ADDITIVE — `.key`/`.content` consumers are
                  # unaffected). Computed from the PRE-resolution `aspect` + `ctx` (force-free); the reach +
                  # classSubtreeAt folds dedup a genuinely-shared host+user aspect on it.
                  sharedFoldKey = sharedFoldKeyOf aspect ctx key;
                }
              ]
              ++ childResult.nodes;
          }
      )
      {
        seen = seen0;
        nodes = [ ];
      }
      aspectList;

  # Aspects bound directly on an entity (the §370 `directAspects` seed): the static include list,
  # filtered to entries registered AT this node's own entity. Node-local — an include at an
  # ancestor entity does NOT seed a descendant (each node reads its OWN __entry), which is what
  # makes registration-scope radiation (§B4a) meaningful rather than universal.
  directAspectsFor =
    ownEntry:
    if ownEntry == null then
      [ ]
    else
      prelude.concatMap (inc: inc.aspects) (
        builtins.filter (inc: (inc.at.id_hash or null) == ownEntry.id_hash) directIncludes
      );

  # Aspects added by policy `edge` declarations at this node (resolution stratum of `declarations`).
  policyEdgeAspects =
    resolutionActs: map (a: a.aspect) (builtins.filter (a: a.__action == "edge") resolutionActs);

  # ── The reachability edge model (Phase 1, spec §2). Mirrors policyEdgeAspects/constraintSeen: pure
  #    reads over a node's `resolutionActs`, filtered on `__action`. Unread by any consumer yet (additive
  #    — Phase 2's projection engine consumes them). ──

  # Outgoing POSITIVE reachability edges declared at this node. Each is `{ target; classFilter ? null }` —
  # target resolves to another node whose resolved aspects enter reach(S), optionally restricted to one
  # class slice (F9 class-scoped edge: no classFilter ⇒ null ⇒ all classes).
  reachEdgesOf =
    resolutionActs:
    map (a: {
      inherit (a) target;
      classFilter = a.classFilter or null;
    }) (builtins.filter (a: a.__action == "reach-edge") resolutionActs);

  # Outgoing NEGATIVE (suppression) edges (F3-exclude / u21). Each `{ edge; when }` removes a positive
  # edge from reach(S) when the scope predicate `when` holds (e.g. `host.class == "droid"`).
  reachSuppressOf =
    resolutionActs:
    map (a: { inherit (a) edge when; }) (
      builtins.filter (a: a.__action == "reach-suppress") resolutionActs
    );

  # Scope-level `drop` declarations pre-seed `seen` so forward expansion prunes the dropped aspects'
  # include subtrees (§Constraints, scope-level).
  constraintSeen =
    resolutionActs:
    prelude.foldl' (acc: a: acc // { ${keyOf a.aspect} = true; }) { } (
      builtins.filter (a: a.__action == "drop") resolutionActs
    );

  # §B4a visibility candidate set: the resolved-aspect keys of every scope ABOVE this node in
  # containment — the P-parent chain (`node.parent`) UNION the cell's coordinate roots
  # (`decls.__containment`, e.g. env:prod / host:axon). Each is a flat root or a strict ancestor,
  # so `self.get ancestorId "resolved-aspects"` is a top-down read that never reaches back into a
  # descendant — acyclic along the containment DAG (the §B4a ordering note, over containment rather
  # than the P-tree). O(depth). Reading an ancestor's FINAL resolved set (not the seed) is what
  # gives arrival-path independence across scopes.
  ancestorResolvedKeys =
    self: id:
    let
      node = self.node id;
      parentChain =
        let
          go =
            nid:
            let
              p = (self.node nid).parent;
            in
            if p == null then [ ] else [ p ] ++ go p;
        in
        go id;
      containment = node.decls.__containment or [ ];
      ancestorIds = prelude.unique (parentChain ++ containment);
      keysAt =
        aid: prelude.foldl' (acc: n: acc // { ${n.key} = true; }) { } (self.get aid "resolved-aspects");
    in
    prelude.foldl' (acc: aid: acc // keysAt aid) { } ancestorIds;

  # Static index of neededBy carriers, built once outside the fixpoint. Literal-form carriers are
  # bucketed by TRIGGER key (each aspect their neededBy names); selector-form carriers are a flat
  # residual list. Makes each pass O(matches), not O(allAspects) (the §B4a audit's O(A²) trap).
  indexByNeededBy =
    let
      carriers = builtins.filter (
        a:
        let
          nb = a.neededBy or [ ];
        in
        isSelector nb || (builtins.isList nb && nb != [ ])
      ) (builtins.attrValues allAspects);
      selectors = builtins.filter (a: isSelector a.neededBy) carriers;
      literals = builtins.filter (a: !(isSelector a.neededBy)) carriers;
      byTrigger = prelude.foldl' (
        acc: a:
        prelude.foldl' (
          acc': trigger:
          let
            k = keyOf trigger;
          in
          acc' // { ${k} = (acc'.${k} or [ ]) ++ [ a ]; }
        ) acc a.neededBy
      ) { } literals;
    in
    {
      inherit byTrigger selectors;
    };

  # Literal carriers whose trigger key ∈ visible, concatenated with the selector residual (the
  # latter filtered by `neededByActivates`, which applies cond 1 + cond 2).
  nbCandidates =
    nbIndex: visible:
    prelude.concatMap (trigger: nbIndex.byTrigger.${trigger} or [ ]) (builtins.attrNames visible)
    ++ nbIndex.selectors;

  # neededBy activation: literal form fires when any named trigger key ∈ visible; selector form
  # fires when the selector matches this scope (cond 1) AND the carrier itself is resolved above
  # (its key ∈ visible, cond 2). The carrier of a standalone aspect is itself.
  neededByActivates =
    a:
    {
      id,
      visible,
      selCtx,
    }:
    let
      nb = a.neededBy;
    in
    if isSelector nb then
      select.matches nb id selCtx && (visible ? ${keyOf a})
    else
      builtins.any (t: visible ? ${keyOf t}) nb;

  allConditionalAspects = builtins.filter (a: (a.meta.guard or null) != null) (
    builtins.attrValues allAspects
  );

  # §Constraints, aspect-level: prune nodes whose key is named in any resolved aspect's meta.drop.
  # Also dedups by A-IDENT key (defensive — forward expansion already skips seen keys). `n.key` is ALWAYS
  # non-null, so this reuses the file's own `dedupByKey` (§37) — behavior identical to the prior inline
  # first-occurrence fold (first-wins, order-preserving, over the same `dropped`-filtered list).
  applyConstraints =
    nodes:
    let
      dropped = prelude.foldl' (
        acc: n: acc // prelude.foldl' (a: d: a // { ${keyOf d} = true; }) { } (n.content.meta.drop or [ ])
      ) { } nodes;
      # A `__contentless` visibility stub yields to any contentful node sharing its key: once the co-scoped
      # content carrier has resolved, the stub's job (cond-2 visibility) is spent, and v1's late-dispatch
      # policy materializes nothing at the owner scope. Drop the stub BEFORE dedupByKey — else first-wins
      # would keep the stub and re-drop the carrier. A LONE stub (no contentful same-key node) is KEPT, so a
      # descendant still reads its cond-2 visibility (the to-users host-stub case).
      fulKeys = prelude.foldl' (
        acc: n: if (n.content.meta.__contentless or false) then acc else acc // { ${n.key} = true; }
      ) { } nodes;
      contentlessShadowed = n: (n.content.meta.__contentless or false) && (fulKeys ? ${n.key});
    in
    dedupByKey (n: n.key) (
      builtins.filter (n: !(dropped ? ${n.key}) && !(contentlessShadowed n)) nodes
    );
  # A resolved-aspect node `n` passes an edge's class filter iff the filter is null (all classes) OR the
  # aspect's content carries the class key `C` (Phase 1's dep-free class predicate — the Phase-2 projection
  # engine folds in the full `classifyKey` class/setting discrimination). A nixos-only host aspect has no
  # `home-manager` key ⇒ a `home-manager`-scoped edge excludes it (F9 no over-reach).
  passesClassFilter = classFilter: n: classFilter == null || (n.content or { }) ? ${classFilter};
in
{
  # `reachEdgesOf`/`reachSuppressOf` are INTERNAL (`let`-bound only) — both are now CONSUMED inside `reach`
  # (positive edges + negative-edge suppression), so their behaviour is witnessed THROUGH `reach` (the
  # reach-graph class-scoped / transitive / suppression-both-arms units); no permanent public surface is
  # needed for either.

  # reach(id): the P-PROJECT per-scope single-visit resolved-aspect closure (spec §1/§2). The OWN/structural
  # component is the scope SUBTREE (`[ id ] ++ scope.descendants self id` — own node then descendant cells,
  # subsuming v1's `classSubtreeAt` down-fold, Task 1) FIRST, then each POSITIVE reach-edge's target resolved
  # aspects (class-filtered), transitively
  # over the target's own edges; dedup by A-IDENT key (single-visit, PER this traversal — NOT global, so
  # distinct scopes each run their own). The bare-key dedup applies to the EDGE closure + WITHIN a node ONLY:
  # the structural-subtree component preserves PER-PROVIDER multiplicity (distinct descendant scopes are
  # distinct ctx-eval results — the three cells' `acct` → three nodes, spec §1 refined 2026-07-14), keeping it
  # byte-identical to `classSubtreeAt`. Accumulates as a LIST, dedup preserving first occurrence (own-first
  # order — the merge_ord canonical order Task 5 pins). Acyclic along the edge DAG (a target-id visited-set
  # guards a cycle); reuses the ancestorResolvedKeys top-down `self.get target "..."` cross-scope read.
  # NEGATIVE-EDGE SUPPRESSION (Task 4): each node's positive edges minus the edges its held reach-suppress
  # declarations remove (`when` true for the node's scope), matched by edge identity = `target`.
  reach = resolve.attr {
    name = "reach";
    kind = "circular";
    readsAttrs = [
      "resolved-aspects"
      "declarations"
      "children"
    ];
    compute =
      self: id:
      let
        # Positive edges at a node: the node's own DECLARED (opt-in) reach-edges.
        positiveEdgesAt = nid: reachEdgesOf ((self.get nid "declarations").actions.resolution or [ ]);

        # NEGATIVE-EDGE SUPPRESSION (spec §2 F3-exclude / u21). The suppressed-EDGE set at a node: the
        # `target`s named by every reach-suppress declaration whose scope predicate `when` HOLDS for the
        # node's scope (`self.node nid`). Phase-1 EDGE IDENTITY is the edge's `target` (a positive edge is
        # identified by the node it reaches; `reach-suppress.edge` names that target) — no separate edge-id
        # field yet. A suppress whose `when` is false contributes nothing (the positive edge survives).
        suppressedTargetsAt =
          nid:
          let
            scopeOf = self.node nid;
            held = builtins.filter (s: s.when scopeOf) (
              reachSuppressOf ((self.get nid "declarations").actions.resolution or [ ])
            );
          in
          prelude.foldl' (acc: s: acc // { ${s.edge} = true; }) { } held;

        # A node's positive edges MINUS its held suppressions (matched by edge identity = `target`).
        edgesAt =
          nid:
          let
            suppressed = suppressedTargetsAt nid;
          in
          builtins.filter (e: !(suppressed ? ${e.target})) (positiveEdgesAt nid);

        # Fold one edge's (class-filtered, not-yet-seen) target aspects into the accumulator, recursing into
        # the target's own edges FIRST-occurrence-preserving. `acc = { seen; nodes; visitedIds; }`: seen =
        # keyset for node single-visit, nodes = the ordered result, visitedIds = edge-cycle guard.
        addTarget =
          acc: edge:
          if acc.visitedIds ? ${edge.target} then
            acc
          else
            let
              targetNodes = builtins.filter (passesClassFilter edge.classFilter) (
                self.get edge.target "resolved-aspects"
              );
              acc' = acc // {
                visitedIds = acc.visitedIds // {
                  ${edge.target} = true;
                };
              };
              withNodes = prelude.foldl' addNode acc' targetNodes;
            in
            # transitively follow the target's own edges (same class filter is NOT inherited — each edge
            # carries its own filter; the target's edges apply their own).
            prelude.foldl' addTarget withNodes (edgesAt edge.target);

        # Add a single resolved-aspect node if its key is unseen (single-visit dedup, first-occurrence).
        addNode =
          acc: n:
          if acc.seen ? ${n.key} then
            acc
          else
            {
              seen = acc.seen // {
                ${n.key} = true;
              };
              nodes = acc.nodes ++ [ n ];
              inherit (acc) visitedIds;
            };

        # STRUCTURAL-DESCENDANT EDGE (spec §2, subsumes v1's `classSubtreeAt` down-fold). The OWN/structural
        # component of reach is not node-local: it is the scope SUBTREE `[ id ] ++ scope.descendants self id`
        # (own node FIRST, then descendants in lexicographic-DFS order — the same `[id] ++ scope.descendants
        # result id` walk `classSubtreeAt`/the #62c/#66 folds run, mirrored at the RESOLVED-ASPECT level
        # rather than class buckets), each node contributing its `self.get nid "resolved-aspects"`. This is how
        # a host reaches its descendant CELLS' aspect nodes (the `define-user` nixos@host-from-cell mechanism).
        # `scope.descendants` reads `self.get nid "children"` (declared in readsAttrs) — the lazy id spine,
        # top-down over the containment DAG, so no cycle. The class filter is a PROJECTION concern (Task 2),
        # NOT applied here — reach returns ALL reachable nodes.
        #
        # PER-PROVIDER MULTIPLICITY (spec §1 single-visit refined 2026-07-14, THE ANCHOR ruling). The
        # structural-subtree component emits each provider node's OWN-key-deduped resolved-aspects VERBATIM
        # (`concatMap` over the subtree, NO cross-provider dedup) — because distinct descendant SCOPES are
        # distinct ctx-eval RESULTS (spec §0: "@sini/@dvicory never collapse"; the three cells' one parametric
        # `acct` aspect resolve to `users.users.{amy,pol,tux}`, three nodes sharing the A-IDENT key but NOT one
        # node). A bare-key collapse here would be the u24-class content-loss §5 warns of. This makes reach's
        # structural component BYTE-IDENTICAL to `classSubtreeAt`'s `concatMap ([id] ++ descendants)` (the
        # Task-2 anchor). The single-visit / bare-key dedup law applies to the EDGE closure + WITHIN a node
        # ONLY (own-node dedup is upstream in `applyConstraints`; each descendant's list is already key-unique).
        #
        # EDGE-DEDUP SEEDING: the structural keys STILL seed the `seen` keyset, so the EDGE closure
        # (`addTarget`/`addNode`, bare-key dedup) collapses an aspect reached BOTH structurally AND via an edge
        # to the structural occurrence (spicetify own+opt-in → one node; the radiation-double own+default → one
        # node — spec §3). Own-subtree wins per merge_ord (it is folded first). `seen` is a set (union of all
        # structural keys); the `nodes` list keeps the FULL structural sequence (multiplicity preserved there).
        #
        # CANONICAL merge_ord ORDER (spec §1, Task 5 — LOAD-BEARING for order-semantic content: the zsh
        # ZSH_HIGHLIGHT_HIGHLIGHTERS multiset, persistence entry order — ledger u24). The result list is
        # accumulated OWN-SUBTREE FIRST (own node's forwardExpand order, then each descendant's, in
        # `scope.descendants` order), THEN the edges of `edgesAt id` in precedence order (default edges <
        # opt-in edges). Do NOT reorder these folds — the Phase-2 class-slice merge depends on this sequence.
        subtreeIds = [ id ] ++ scope.descendants self id;
        structuralNodesRaw = prelude.concatMap (nid: self.get nid "resolved-aspects") subtreeIds;
        # CROSS-SCOPE SHARED-ASPECT DEDUP (v1 `wrapPerScope` `dedupByKey (m: m.key)`, resolve.nix:43-66 @ pin
        # 11866c16). A genuinely-shared host+user aspect (`den.default`) resolves to a BYTE-IDENTICAL node at
        # the host AND its cells (same A-IDENT key + same entity-coord projection ⇒ same `sharedFoldKey`);
        # collapse it first-occurrence-wins (own/host first) — the fix for the double-fold (a doubled
        # option-decl aborts / a unique option throws / a list silently doubles). A `null` sharedFoldKey (a
        # static-anon node, or a parametric aspect reading a non-entity enrichment coord) is NEVER deduped
        # (v1 anon rule) — the conservative keep. Genuinely per-cell content (`acct`'s `{ user, … }:` cells,
        # delivered-child/guest content) carries a DISTINCT per-cell `user`/guest `id_hash` ⇒ distinct
        # `sharedFoldKey` ⇒ kept (the #111 no-collapse invariant `class-fold-subtree` pins).
        structuralNodes = dedupByKey (n: n.sharedFoldKey or null) structuralNodesRaw;
        seededOwn = {
          # `seen` = the UNION of every structural node's key over the RAW list (edge closure dedups against
          # it — do NOT narrow to the deduped list, or an edge-reached aspect could re-enter); `nodes` = the
          # cross-scope-deduped structural sequence (per-provider multiplicity kept, shared copies collapsed).
          seen = prelude.foldl' (acc: n: acc // { ${n.key} = true; }) { } structuralNodesRaw;
          nodes = structuralNodes;
          visitedIds = {
            ${id} = true;
          };
        };
        result = prelude.foldl' addTarget seededOwn (edgesAt id);
      in
      result.nodes;
  };

  resolved-aspects = resolve.attr {
    name = "resolved-aspects";
    kind = "circular";
    readsAttrs = [
      "enriched-context"
      "declarations"
      "resolved-aspects"
    ];
    compute =
      self: id:
      let
        # The aspect-fn resolution ctx: the enriched-context, run through the consumer's `enrichContext`
        # hook (native default = identity). Applied ONCE for the whole resolve — both `forwardExpand` sites
        # (the seed below and the fixpoint expansion) receive this same enriched ctx, so a parametric
        # aspect-fn destructuring `host`/`user`/… sees the enrichment uniformly.
        #
        # THE CIRCULAR SELF-READ (sanctioned). `resolvedAspects` is `self.get id "resolved-aspects"` — THIS
        # node's own attribute-7 value (declared in `readsAttrs`, kind=circular). It is passed UNFORCED: the
        # hook must not force it at stamp (A17). A closure the hook stamps (e.g. a projected resolved-aspect
        # accessor) reads it only at a VALUE position — forced at the terminal AFTER the circular fixpoint has
        # converged, so it observes the memoized final set. A read at a KEY/STRUCTURE position (gating
        # `includes` or a dynamic attr name) is forced by `forwardExpand` DURING resolution → the circular
        # attribute black-holes LOUD (`infinite recursion`), the evaluator enforcing the includes-position ban.
        ctx = enrichContext {
          inherit id;
          resolvedAspects = self.get id "resolved-aspects";
          bindings = self.get id "enriched-context";
        };
        resolutionActs = (self.get id "declarations").actions.resolution or [ ];
        ownEntry = (self.node id).decls.__entry or null;

        roots = directAspectsFor ownEntry ++ policyEdgeAspects resolutionActs;
        seed = forwardExpand ctx (constraintSeen resolutionActs) roots;

        ancestorSeen = ancestorResolvedKeys self id;
        nbIndex = indexByNeededBy;
        selCtx = select.adapters.scope.mkContext { inherit (self) node get; };

        fixed =
          scope.circular
            {
              init = seed;
              eq = seenEq;
            }
            (
              _self: _id: prev:
              let
                visible = ancestorSeen // prev.seen;
                # A `__contentless` visibility stub (provides.nix §B4a) seeds its A-IDENT key into `prev.seen`
                # to grant a co-scoped content carrier cond-2 visibility — but that same key then makes the
                # normal `!(prev.seen ? key)` guard filter the carrier itself (the carrier shares the stub's
                # key). The distinguishing signal is in the NODES: a stub resolves as a node whose
                # `content.meta.__contentless` is true. `_onlyCless k` ⇒ k is held ONLY by such stubs (no
                # contentful same-key node yet), so the carrier is allowed past the seen-guard exactly once.
                _clessKeys = prelude.foldl' (
                  acc: n: if (n.content.meta.__contentless or false) then acc // { ${n.key} = true; } else acc
                ) { } prev.nodes;
                _fulKeys = prelude.foldl' (
                  acc: n: if (n.content.meta.__contentless or false) then acc else acc // { ${n.key} = true; }
                ) { } prev.nodes;
                _onlyCless = k: (_clessKeys ? ${k}) && !(_fulKeys ? ${k});
                nbExtras = builtins.filter (
                  a:
                  (!(prev.seen ? ${keyOf a}) || _onlyCless (keyOf a))
                  && neededByActivates a { inherit id visible selCtx; }
                ) (nbCandidates nbIndex visible);
                guardExtras = builtins.filter (
                  a:
                  !(prev.seen ? ${keyOf a})
                  && a.meta.guard {
                    pathSet = prev.seen;
                    hasAspect = k: prev.seen ? ${keyOf k};
                  }
                ) allConditionalAspects;
                # Drop the `_onlyCless` keys from the forwardExpand INPUT so its own seen-skip (:119) does not
                # re-skip the carrier we just un-filtered. Only the input is narrowed.
                _expandSeen = removeAttrs prev.seen (builtins.filter _onlyCless (builtins.attrNames prev.seen));
                expanded = forwardExpand ctx _expandSeen (nbExtras ++ guardExtras);
              in
              {
                # UNION-BACK (monotone ascent, file-head stratification law): `_expandSeen ⊊ prev.seen`, so a
                # lone `_onlyCless` key with no resolving carrier this pass would be dropped by
                # `seen = expanded.seen`, breaking least-fixpoint monotonicity. Union `prev.seen` back in —
                # zero behavioral cost (the carrier already resolved via the narrowed INPUT), keeps seen
                # monotone.
                seen = prev.seen // expanded.seen;
                nodes = prev.nodes ++ expanded.nodes;
              }
            )
            self
            id;
      in
      applyConstraints fixed.nodes;
  };
}
