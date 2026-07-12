# The STAGED ROOT-RESOLUTION pre-pass (design note 2026-07-11 §2/§3(ii) + §3c-UNIFIED) — the ONE
# mechanism that closes the S1-catalogued gaps under a single pass, now with TUPLE-CARRIED BINDINGS
# (`relate` DISSOLVED — one verb, `member`):
#
#   • CELL ROUTING (the codebase's deferred "Task 4"): a bare `member` emitted by a policy landed in the
#     structural group but was never routed into the fleet (`membershipTuples` was static `den.membership`
#     ONLY). A5's law already anticipates policy-emitted membership from membership-independent nodes —
#     this pass delivers it: a `member` with `containTo = null` (a CELL tuple) becomes a fleet tuple.
#   • CONTAINMENT TUPLES (was `relate`): env/host roots are independent parentless scope roots with NO
#     cross-node data path. A `member` with `containTo = <root-kind>` carries (a) ctx `bindings` the target
#     root's ctx folds — for SUBSEQUENT pre-pass phases AND the main run's inherited-context — AND (b) its
#     SOURCE coordinate as the target root's containment ANCESTOR (the env→host / env→cluster edge, fed to
#     the settings-chain env slice, resolved-settings.nix). It NEVER becomes a product cell — that is what
#     kills the cross-join (a sibling registry-backed root like `cluster` stays a root, never a cell).
#
# STRUCTURE (kind-generic, corpus-inert): a kind-ordered iteration over ROOT nodes, run BEFORE the fleet
# product builds (no attribute-schedule change — the pass is compositional and severable). The kind order
# is DERIVED from the discovered containment-kind topology (`meta.<k>.parent`, the schema `_topology`
# fact — NEVER a hardcoded kind list). Per phase (one root kind, parent-before-child): dispatch that
# kind's roots' resolve-family policies with ctx = node decls + relation bindings accumulated so far; a
# `containTo`-marked `member` folds its bindings + ancestor into the target root for later phases + the
# main run; a bare `member` becomes a cell tuple. Each phase is a MONOTONE pass over a node set fixed
# before it (A5).
#
# OPEN-ITEM RESOLUTIONS (verified against the codebase before build):
#   (a) PRE-PASS CTX = node decls (a root is parentless, so its `inherited-context` = its own decls, the
#       same `__`-key strip as attributes/structural.nix attr 1) + accumulated relation bindings. The
#       graph-level `enrichments` (attr 2) are NOT folded: computing them pre-fleet would either force
#       `structural.eval` (→ theFleet → membershipTuples → a cycle) or duplicate the attr-2 fixpoint, and
#       the corpus resolution chain (design §1) reads decls + relation-carried accessGroups only, never
#       den-hoag `enrich`-policy enrichments. Minimal and corpus-faithful.
#   (b) DOUBLE-FIRE DISCIPLINE: the resolve-family kind {member} is consumed by THIS pass ONLY; every
#       other kind by the main run — an exactly-one-consumer split. A resolve policy still fires in both
#       passes (a policy is `ctx: [decls]`), but at roots its `member` was consumed here and the main run's
#       structural consumers (attr 5/6) never read it; at a membership-DERIVED node a resolve-family
#       emission aborts LOUD (`errors.memberAtCell`, attributes/structural.nix attr 4), never a silent
#       drop. Resolve policies scope-restrict via the existing `__firesAtKinds` pre-filter.
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

  # entry.id_hash -> "kind:name" scope-node id, over the root kinds only (a `containTo` target denotes an
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

  # runPrePass — the fold over kind-phases. Returns { tuples; relationBindings; containmentRelations }:
  #   • `tuples`               — the derived CELL membership tuples (∪ with static `den.membership` at the
  #                              call site), from bare (`containTo = null`) `member` emissions.
  #   • `relationBindings`     — a nodeId -> ctx-additions map (a `containTo`-marked `member`'s `bindings`,
  #                              injected into the target roots' decls for the main run).
  #   • `containmentRelations` — a nodeId -> [ sourceSlice ] map (a `containTo`-marked `member`'s SOURCE
  #                              coordinate, the target root's containment ANCESTOR — the settings-chain
  #                              env slice, read by resolved-settings.nix).
  #   • `suppressions`         — a nodeId -> [ policyName ] map (#72: the exclude family's `suppress`
  #                              emissions at each root), injected onto the emitting root's decls as
  #                              `__denSuppressedPolicies` (default.nix scopeRoots) so inherited-context
  #                              delivers v1's scope+descendants suppression.
  #
  #   scopeRoots     = the BASE (un-injected) root scope nodes { id; type; parent; decls } (buildRoots).
  #   rootKinds      = the root scope kinds we FIRE at (default.nix `prePassRootKinds`).
  #   parentOf       = k -> parent-kind-or-null (default.nix `ent.meta.<k>.parent`).
  #   registries     = the entity registries; the containment-target index spans ALL registry kinds (a
  #                    containTo target — e.g. `cluster` — may be a root we do NOT fire at, so the index is
  #                    NOT restricted to `rootKinds`).
  #   resolveRules   = the RESOLVE-FAMILY feed (concern-policies `policiesRules.resolveFamily`): the
  #                    structural-group rules that can emit `member` (single-group probe DETECTED, or the
  #                    `__resolveFamily` tag DECLARED for a value-conditional resolve policy). This feed —
  #                    NOT the whole structural feed — is what the pass dispatches, so an arbitrary
  #                    co-firing policy body is never run at a root (which could hit an uncatchable
  #                    missing-attribute read); a resolve-free fleet has an empty feed → the pass is inert.
  runPrePass =
    {
      scopeRoots,
      rootKinds,
      parentOf,
      registries,
      resolveRules,
      # The EXCLUDE-FAMILY feed (#72, candidate A — ledger u21): the structural-group rules that can emit
      # `suppress` (detected or `__excludeFamily`-declared). Dispatched at the SAME roots/phases/ctx as
      # the resolve family, collecting per-root SUPPRESSION SETS — v1's `policy.exclude <policy>`
      # constraint registration (pin 11866c16 fx/handlers/dispatch-policies.nix:15-33: name-keyed at the
      # emitting scope, consulted scope+ancestors ⇒ descendants inherit, siblings isolated per #613).
      # The caller injects each set onto its root's decls (`__denSuppressedPolicies`), so inherited-
      # context delivers the v1 semantics. Default `[ ]` → `suppressions = { }` → byte-identical.
      excludeRules ? [ ],
    }:
    let
      order = orderRootKinds { inherit rootKinds parentOf; };
      # The containment-target index spans EVERY registry kind (a containTo target may be a root outside
      # the fired `rootKinds` — the corpus's `cluster` is a candidate we do not fire at, yet a resolve.to
      # "cluster" containment tuple targets it).
      index = rootNodeIndex {
        inherit registries;
        rootKinds = builtins.attrNames registries;
      };

      # Fire the resolve-family rules at ONE root and return its `member` emissions. Only the resolve-
      # family feed is dispatched (see `resolveRules`), so every rule here is a genuine resolve policy —
      # no `tryEval` masking: a broken resolve policy surfaces LOUD (never a silent drop). A single one-
      # shot dispatch (single-group), honoring `__firesAtKinds` (the same scope-local firing pre-filter
      # attr 2/4 apply); the caller partitions CELL (`containTo == null`) vs CONTAINMENT (`containTo` set)
      # tuples. A value-conditional resolve policy taking its false branch simply emits nothing here (its
      # member arrives once its ctx value is present).
      fireFeedAt =
        rules: keep: nodeKind: id: ctx:
        let
          applicable = builtins.filter (
            r: !(r ? __firesAtKinds) || builtins.elem nodeKind r.__firesAtKinds
          ) rules;
          acts =
            (dispatch.dispatch {
              rules = applicable;
              inherit id;
              context = ctx;
              match = dispatch.fromFunctionMatch;
              classify = _: "pre-pass";
              groupOrder = [ "pre-pass" ];
            }).actions.pre-pass or [ ];
        in
        builtins.filter keep acts;
      fireAt = fireFeedAt resolveRules declare.isResolveFamily;
      # The exclude-family twin: fire the suppress emitters at the root, keep the `suppress` acts.
      fireExcludeAt = fireFeedAt excludeRules declare.isSuppress;

      # Classify ONE `member` emission (design note §3c-UNIFIED). A BARE member (`containTo == null`) is a
      # CELL tuple → the fleet product. A `containTo`-marked member is a CONTAINMENT tuple → its `bindings`
      # fold into the target root's ctx (relationBindings) AND its SOURCE coordinate (coords minus the
      # target) becomes that root's containment ANCESTOR (containmentRelations). The target coordinate is
      # `coords.<containTo>` (an identity entry → its root node id via `index`).
      classify =
        st: id: a:
        let
          containTo = a.containTo or null;
        in
        if containTo == null then
          # CELL tuple — routed into the fleet. A5: emitted at a membership-independent root →
          # `via.membershipDerived = false` (fleet.nix's disciplineOk passes it through); `via` names the
          # emitting policy + scope for provenance.
          st
          // {
            tuples = st.tuples ++ [
              {
                inherit (a) coords;
                via = {
                  policy = a.__policy or null;
                  scope = id;
                  membershipDerived = false;
                };
              }
            ];
          }
        else
          # CONTAINMENT tuple — bindings + ancestor into the EXISTING target root (never a product cell).
          let
            targetEntry = a.coords.${containTo} or null;
            tid = if targetEntry == null then null else index.${targetEntry.id_hash} or null;
            sourceSlice = builtins.removeAttrs a.coords [ containTo ];
          in
          if tid == null then
            errors.containTargetMissing (a.__policy or "«anonymous»") targetEntry
          else
            st
            // {
              relationBindings = st.relationBindings // {
                ${tid} = (st.relationBindings.${tid} or { }) // (a.bindings or { });
              };
              # A PARENTLESS root target has an empty source slice (no firing-scope coordinate) — bindings
              # ride, but there is no containment ancestor to record (an empty slice has no `ancNodeId`).
              containmentRelations =
                if sourceSlice == { } then
                  st.containmentRelations
                else
                  st.containmentRelations
                  // {
                    ${tid} = (st.containmentRelations.${tid} or [ ]) ++ [ sourceSlice ];
                  };
            };

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
          # #72: collect this root's suppression set (the exclude family fired with the SAME ctx). A
          # value-conditional excluder taking its false branch emits nothing here (the corpus's
          # droid-gated route exclude suppresses only at droid-class roots).
          suppressed = map (a: a.name) (fireExcludeAt node.type id ctx);
          st' =
            if suppressed == [ ] then
              st
            else
              st
              // {
                suppressions = st.suppressions // {
                  ${id} = (st.suppressions.${id} or [ ]) ++ suppressed;
                };
              };
        in
        prelude.foldl' (acc: a: classify acc id a) st' acts;

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
      containmentRelations = { };
      suppressions = { };
    } order;
in
{
  inherit
    orderRootKinds
    rootNodeIndex
    runPrePass
    ;
}
