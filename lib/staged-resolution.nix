# The STAGED ROOT-RESOLUTION pre-pass (design note 2026-07-11 §2/§3(ii), slice R1) — the ONE
# mechanism that closes the two S1-catalogued gaps under a single pass:
#
#   • MEMBER ROUTING (the codebase's deferred "Task 4"): a `member` declaration emitted by a policy
#     landed in the structural group but was never routed into the fleet (`membershipTuples` was static
#     `den.membership` ONLY). A5's law already anticipates policy-emitted membership from membership-
#     independent nodes — this pass delivers it: leaf-dim `member` emissions become fleet tuples.
#   • RELATION-CARRIED BINDINGS: env/host roots are independent parentless scope roots with NO cross-node
#     data path. A `relate` (source→existing-target) carries ctx bindings the target's ctx folds — for
#     SUBSEQUENT pre-pass phases AND the main run's inherited-context.
#
# STRUCTURE (kind-generic, corpus-inert): a kind-ordered iteration over ROOT nodes, run BEFORE the fleet
# product builds (no attribute-schedule change — the pass is compositional and severable). The kind order
# is DERIVED from the discovered containment-kind topology (`meta.<k>.parent`, the schema `_topology`
# fact — NEVER a hardcoded kind list). Per phase (one root kind, parent-before-child): dispatch that
# kind's roots' resolve-family policies with ctx = node decls + relation bindings accumulated so far; a
# `relate` folds its bindings into the target node's ctx for later phases + the main run; a `member`
# becomes a tuple. Each phase is a MONOTONE pass over a node set fixed before it (A5).
#
# OPEN-ITEM RESOLUTIONS (verified against the codebase before build):
#   (a) PRE-PASS CTX = node decls (a root is parentless, so its `inherited-context` = its own decls, the
#       same `__`-key strip as attributes/structural.nix attr 1) + accumulated relation bindings. The
#       graph-level `enrichments` (attr 2) are NOT folded: computing them pre-fleet would either force
#       `structural.eval` (→ theFleet → membershipTuples → a cycle) or duplicate the attr-2 fixpoint, and
#       the corpus resolution chain (design §1) reads decls + relation-carried accessGroups only, never
#       den-hoag `enrich`-policy enrichments. Minimal and corpus-faithful.
#   (b) DOUBLE-FIRE DISCIPLINE: resolve-family kinds {member, relate} are consumed by THIS pass ONLY;
#       every other kind by the main run — an exactly-one-consumer split. A resolve policy still fires in
#       both passes (a policy is `ctx: [decls]`), but at roots its member/relate were consumed here and the
#       main run's structural consumers (attr 5/6) never read them; at a membership-DERIVED node a
#       resolve-family emission aborts LOUD (`errors.memberAtCell`, attributes/structural.nix attr 4),
#       never a silent drop. Resolve policies scope-restrict via the existing `__firesAtKinds` pre-filter.
#
# Pure gen-prelude + gen-dispatch wiring (Law A1): the ONLY loop is a `foldl'` over a pre-fixed phase list
# — NO `scope.circular`, NO `dispatchStep` (the fixpoint/step machinery stays in the two declared circular
# attributes). `declare`/`errors` are den-hoag vocabulary DEPs.
{
  prelude,
  dispatch,
  declare,
  errors,
}:
let
  # Root-kind order: parent-before-child over the discovered containment topology. The containment DAG is
  # a forest (each kind has at most one `parent`) and a root kind's parent — if any — is itself a root kind
  # (a parent kind is never a leaf/cell), so a depth sort (ancestors ascending, name tiebreak) is a valid
  # topological order. Derived from `parentOf` (= `meta.<k>.parent`); never a literal kind sequence.
  orderRootKinds =
    { rootKinds, parentOf }:
    let
      depthOf =
        k:
        let
          p = parentOf k;
        in
        if p == null || !(builtins.elem p rootKinds) then 0 else 1 + depthOf p;
    in
    prelude.sort (
      a: b:
      let
        da = depthOf a;
        db = depthOf b;
      in
      if da != db then da < db else a < b
    ) rootKinds;

  # entry.id_hash -> "kind:name" scope-node id, over the root kinds only (a `relate` target denotes an
  # existing ROOT node). The flat root id convention matches buildRoots (`"${kind}:${name}"`).
  rootNodeIndex =
    { registries, rootKinds }:
    prelude.foldl' (
      acc: kind:
      prelude.foldl' (
        acc': name:
        let
          e = registries.${kind}.${name};
        in
        acc' // { ${e.id_hash} = "${kind}:${name}"; }
      ) acc (builtins.attrNames registries.${kind})
    ) { } rootKinds;

  # runPrePass — the fold over kind-phases. Returns { tuples; relationBindings } where `tuples` are the
  # derived membership tuples (∪ with static `den.membership` at the call site) and `relationBindings` is
  # a nodeId -> ctx-additions map (injected into the target roots' decls for the main run).
  #
  #   scopeRoots     = the BASE (un-injected) root scope nodes { id; type; parent; decls } (buildRoots).
  #   rootKinds      = the root scope kinds (default.nix `rootScopeKinds`).
  #   parentOf       = k -> parent-kind-or-null (default.nix `ent.meta.<k>.parent`).
  #   registries     = the entity registries (for the relate-target index).
  #   resolveRules   = the RESOLVE-FAMILY feed (concern-policies `policiesRules.resolveFamily`): the
  #                    structural-group rules that can emit member/relate (single-group probe DETECTED, or
  #                    the `__resolveFamily` tag DECLARED for a value-conditional resolve policy). This
  #                    feed — NOT the whole structural feed — is what the pass dispatches, so an arbitrary
  #                    co-firing policy body is never run at a root (which could hit an uncatchable
  #                    missing-attribute read); a resolve-free fleet has an empty feed → the pass is inert.
  runPrePass =
    {
      scopeRoots,
      rootKinds,
      parentOf,
      registries,
      resolveRules,
    }:
    let
      order = orderRootKinds { inherit rootKinds parentOf; };
      index = rootNodeIndex { inherit registries rootKinds; };

      # Fire the resolve-family rules at ONE root and return its MEMBER/RELATE emissions. Only the resolve-
      # family feed is dispatched (see `resolveRules`), so every rule here is a genuine resolve policy —
      # no `tryEval` masking: a broken resolve policy surfaces LOUD (never a silent drop). A single one-
      # shot dispatch (single-group), honoring `__firesAtKinds` (the same scope-local firing pre-filter
      # attr 2/4 apply); the caller partitions member vs relate. A value-conditional resolve policy taking
      # its false branch simply emits nothing here (its member arrives once its ctx value is present).
      fireAt =
        nodeKind: id: ctx:
        let
          applicable = builtins.filter (
            r: !(r ? __firesAtKinds) || builtins.elem nodeKind r.__firesAtKinds
          ) resolveRules;
          acts =
            (dispatch.dispatch {
              rules = applicable;
              inherit id;
              context = ctx;
              match = dispatch.fromFunctionMatch;
              classify = _: "resolve-family";
              groupOrder = [ "resolve-family" ];
            }).actions.resolve-family or [ ];
        in
        builtins.filter declare.isResolveFamily acts;

      stepRoot =
        st: id:
        let
          node = scopeRoots.${id};
          # A root is parentless: its ctx = its own decls (the same `__`-key strip as attr 1) extended by
          # the relation bindings folded onto it in earlier phases.
          baseCtx = removeAttrs node.decls [
            "__edges"
            "__containment"
            "__coords"
          ];
          ctx = baseCtx // (st.relationBindings.${id} or { });
          acts = fireAt node.type id ctx;

          members = builtins.filter (a: declare.kindOf a == "member") acts;
          relates = builtins.filter (a: declare.kindOf a == "relate") acts;

          # A5: emitted at a membership-independent root → `via.membershipDerived = false` (fleet.nix's
          # disciplineOk passes it through). The `via` names the emitting policy + scope for provenance.
          newTuples = map (a: {
            inherit (a) coords;
            via = {
              policy = a.__policy or null;
              scope = id;
              membershipDerived = false;
            };
          }) members;

          foldRelate =
            rb: r:
            let
              tid = index.${r.target.id_hash} or null;
            in
            if tid == null then
              errors.relateNoTarget (r.__policy or "«anonymous»") r.target
            else
              rb // { ${tid} = (rb.${tid} or { }) // r.bindings; };
        in
        st
        // {
          tuples = st.tuples ++ newTuples;
          relationBindings = prelude.foldl' foldRelate st.relationBindings relates;
        };

      phase =
        st: kind:
        let
          ids = builtins.filter (id: scopeRoots.${id}.type == kind) (builtins.attrNames scopeRoots);
        in
        prelude.foldl' stepRoot st ids;
    in
    prelude.foldl' phase {
      tuples = [ ];
      relationBindings = { };
    } order;
in
{
  inherit
    orderRootKinds
    rootNodeIndex
    runPrePass
    ;
}
