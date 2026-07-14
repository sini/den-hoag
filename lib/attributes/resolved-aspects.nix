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
  # Shared-vs-own PROVENANCE (Track A rung 1, R-ROOT-FILTER prerequisite). The resolved-aspect keys that
  # ROOT a radiated-SHARED subtree (the `den.default` reserved-aspect key `__default`). A node is
  # SHARED iff it is such a root OR was reached by forward expansion FROM a shared node — the transitive
  # `den.default` subtree, v1's `@default` provider suffix (route.nix `isDenDefaultModule`). The flag
  # rides each node as `__denShared` for class-modules' `__shared` sidecar. Native default `[ ]` ⇒ every
  # node `__denShared = false` (byte-identical; the flag is inert additive data).
  sharedAspectKeys ? [ ],
}:
let
  keyOf = aspects.key;
  sharedKeySet = prelude.foldl' (acc: k: acc // { ${k} = true; }) { } sharedAspectKeys;
  seenEq = a: b: builtins.attrNames a.seen == builtins.attrNames b.seen;
  isSelector = v: builtins.isAttrs v && v ? __sel;

  # Layer 1 — forward expansion (recursive, evaluates parametrics inline). foldl' over an aspect
  # list: skip already-seen keys, otherwise mark seen, resolve concrete (a parametric __isWrappedFn
  # is invoked with ctx; a static submodule passes through), and recurse its `includes`. Returns
  # { seen; nodes } with seen ⊇ the input seen (monotone). Threads acc.nodes through the fold so
  # sibling roots are all retained.
  # `sharedFrom` — the SHARED flag inherited from the expansion parent (a node under a `den.default`
  # subtree is shared; the top-level call passes `false`, so a node is shared iff its own key roots a
  # shared subtree OR an ancestor did). Threaded down the include recursion, stamped as `__denShared`.
  forwardExpand =
    ctx: seen0: sharedFrom: aspectList:
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
            shared = sharedFrom || (sharedKeySet ? ${key});
            newSeen = acc.seen // {
              ${key} = true;
            };
            childResult = forwardExpand ctx newSeen shared (concrete.includes or [ ]);
          in
          {
            seen = childResult.seen;
            nodes =
              acc.nodes
              ++ [
                {
                  inherit key;
                  content = concrete;
                  __denShared = shared;
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
  # Also dedups by key (defensive — forward expansion already skips seen keys).
  applyConstraints =
    nodes:
    let
      dropped = prelude.foldl' (
        acc: n: acc // prelude.foldl' (a: d: a // { ${keyOf d} = true; }) { } (n.content.meta.drop or [ ])
      ) { } nodes;
      dedup =
        prelude.foldl'
          (
            acc: n:
            if acc.have ? ${n.key} then
              acc
            else
              {
                have = acc.have // {
                  ${n.key} = true;
                };
                out = acc.out ++ [ n ];
              }
          )
          {
            have = { };
            out = [ ];
          }
          (builtins.filter (n: !(dropped ? ${n.key})) nodes);
    in
    dedup.out;
in
{
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
        seed = forwardExpand ctx (constraintSeen resolutionActs) false roots;

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
                nbExtras = builtins.filter (
                  a: !(prev.seen ? ${keyOf a}) && neededByActivates a { inherit id visible selCtx; }
                ) (nbCandidates nbIndex visible);
                guardExtras = builtins.filter (
                  a:
                  !(prev.seen ? ${keyOf a})
                  && a.meta.guard {
                    pathSet = prev.seen;
                    hasAspect = k: prev.seen ? ${keyOf k};
                  }
                ) allConditionalAspects;
                expanded = forwardExpand ctx prev.seen false (nbExtras ++ guardExtras);
              in
              {
                seen = expanded.seen;
                nodes = prev.nodes ++ expanded.nodes;
              }
            )
            self
            id;
      in
      applyConstraints fixed.nodes;
  };
}
