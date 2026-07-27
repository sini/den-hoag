# The STAGED ROOT-RESOLUTION pre-pass (design note 2026-07-11 §2/§3(ii) + §3c-UNIFIED) — the ONE
# mechanism that closes the S1-catalogued gaps under a single pass, with TUPLE-CARRIED BINDINGS
# (`relate` DISSOLVED — one verb, `member`):
#
#   • CELL ROUTING (the codebase's deferred "Task 4"): a bare `member` emitted by a policy landed in the
#     structural group but was never routed into the fleet (`membershipTuples` was static `den.membership`
#     ONLY). A5's law already anticipates policy-emitted membership from membership-independent nodes —
#     this pass delivers it: a `member` with `containTo = null` (a CELL tuple) becomes a fleet tuple.
#   • CONTAINMENT BINDINGS (was `relate`): env/host roots are independent parentless scope roots with NO
#     cross-node data path. A `member` with `containTo = <root-kind>` carries (a) ctx `bindings` the target
#     root's ctx folds — for the resolution feed-forward AND the main run's inherited-context — AND (b) its
#     SOURCE coordinate as the target root's containment ANCESTOR (the env→host / env→cluster edge, fed to
#     the settings-chain env slice, resolved-settings.nix). It NEVER becomes a product cell — that is what
#     kills the cross-join (a sibling registry-backed root like `cluster` stays a root, never a cell).
#
# THE CARRIER (kind-generic, corpus-inert): a PER-TARGET binding map, materialized by a groupBy/transpose
# of every root's `containTo`-marked emissions keyed by TARGET node id — NOT a fold-threaded state
# accumulator over a kind-ordered phase schedule. The transpose is order-INDEPENDENT: the target-keyed map
# is the same regardless of the order the emissions are collected in, so there is no parent-before-child
# phase sort and none is needed. Each consuming root DEMAND-READS its OWN slice (`containmentBindings.${id}`)
# into the ctx it fires against — delivered exactly where the root fires. This DISSOLVES the accumulator:
# no `{ relationBindings; containmentRelations }` state is threaded across phases, and no schedule is
# derived — the flow falls out of the target keying.
#
# TWO COLLECT/DELIVER FIRINGS (order-independent, no phase schedule):
#   • COLLECT — fire every root against its OWN decls and transpose the `containTo`-marked emissions by
#     target node id into `containmentBindings` (target -> merged bindings) + `containmentAncestors`
#     (target -> [ source slice ]). A containment producer reads its decls + `config.fleet`, never a target
#     slice (the single-level feed the corpus exercises), so firing it against base decls captures its
#     emission faithfully. A slice-DEPENDENT producer (a multi-level chain where a root consumes a slice to
#     compute a DEEPER root's binding) is the demand-stratification ceiling the general case routes through
#     gen-resolve `buildSchedule` — corpus/fixture-zero here.
#   • DELIVER — fire every root against its decls PLUS its own transpose slice (the demand read), keeping
#     the CELL tuples (`containTo = null`) + the per-root SUPPRESSION set. A consuming resolve policy
#     (env-users reading `accessGroups`; the synthetic rack policy reading `authToken`) sees its slice here,
#     exactly where it fires, and emits CELL tuples — those are NOT fed back into `containmentBindings`, so
#     there is no cycle (the map is produced only by containment-emitters that don't themselves consume it).
#
# OPEN-ITEM RESOLUTIONS (verified against the codebase before build):
#   (a) PRE-PASS CTX = node decls (a root is parentless, so its `inherited-context` = its own decls, the
#       same `__`-key strip as attributes/structural.nix attr 1) extended by its own transpose slice. The
#       graph-level `enrichments` (attr 2) are NOT folded: computing them pre-fleet would either force
#       `structural.eval` (→ theFleet → membershipTuples → a cycle) or duplicate the attr-2 fixpoint, and
#       the corpus resolution chain (design §1) reads decls + relation-carried accessGroups only, never
#       den-hoag `enrich`-policy enrichments. Minimal and corpus-faithful.
#   (b) DOUBLE-FIRE DISCIPLINE: the resolve-family kind {member} is consumed by THIS pass ONLY; every
#       other kind by the main run — an exactly-one-consumer split. A resolve policy still fires in both
#       passes (a policy is `ctx: [decls]`), but at roots its `member` was consumed here and the main run's
#       structural consumers (attr 5/6) never read it; at a membership-DERIVED node a resolve-family
#       emission aborts LOUD (`errors.memberAtCell`, attributes/structural.nix attr 4), never a silent
#       drop. Resolve policies scope-restrict via the existing `__firesAtKinds` pre-filter. A resolve policy
#       fired twice (COLLECT base ctx + DELIVER slice ctx) is idempotent for a producer whose emission is
#       slice-independent; the COLLECT firing keeps only its containment arm, the DELIVER firing only its
#       cell arm.
#
# Pure gen-prelude + gen-dispatch wiring (Law A1): the ONLY loops are `concatMap` over the root set + a
# `prelude.groupBy` target-keyed transpose (per-bucket merge) — NO `scope.circular`, NO `dispatchStep` (the
# fixpoint/step machinery stays in the two declared circular attributes). `declare`/`errors` are den-hoag
# vocabulary DEPs.
{
  prelude,
  dispatch,
  declare,
  errors,
  graph,
}:
let
  # A single-kind coordinate slice back to the scope node id it names. THE id convention for a
  # containment source, owned here beside the transpose that produces those slices — the settings
  # chain reads it from this module rather than re-deriving it, so `"${kind}:${name}"` has one
  # definition repo-wide (it must agree with `buildRoots`, which mints roots under the same rule).
  # An EMPTY slice names no source, so it has no id: that case aborts by name rather than falling into
  # `builtins.head [ ]`'s bare out-of-bounds. Empty is a legitimate EMISSION shape (bindings with no
  # attachment) — every consumer filters it out before asking for an id, so this arm is unreachable from
  # the live paths and exists to keep an unnamed throw off the map.
  ancNodeId =
    slice:
    let
      ks = builtins.attrNames slice;
    in
    if ks == [ ] then
      errors.containmentSliceEmpty
    else
      let
        k = builtins.head ks;
      in
      "${k}:${slice.${k}.name}";
  # entry.id_hash -> "kind:name" scope-node id, over ALL registry kinds (a `containTo` target denotes an
  # existing ROOT node — possibly a kind we do NOT fire at, e.g. the corpus's `cluster`). The flat root id
  # convention matches buildRoots (`"${kind}:${name}"`). This is the transpose's target-keying index.
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

  # runPrePass — the transpose carrier. Returns { tuples; containmentBindings; containmentAncestors;
  # suppressions }:
  #   • `tuples`               — the derived CELL membership tuples (∪ with static `den.membership` at the
  #                              call site), from bare (`containTo = null`) `member` emissions.
  #   • `containmentBindings`  — a targetNodeId -> merged-bindings map (a `containTo`-marked `member`'s
  #                              `bindings`, transposed by target), demand-read into the target roots' ctx
  #                              (the DELIVER firing) AND folded onto their decls for the main run.
  #   • `containmentAncestors` — a targetNodeId -> [ sourceSlice ] map (a `containTo`-marked `member`'s
  #                              SOURCE coordinate, the target root's containment ANCESTOR — the
  #                              settings-chain env slice, read by resolved-settings.nix).
  #   • `suppressions`         — a nodeId -> [ policyName ] map (#72: the exclude family's `suppress`
  #                              emissions at each root), injected onto the emitting root's decls as the
  #                              typed `suppressedPolicies` slot (default.nix scopeRoots) which the
  #                              `suppressed-policies` inherited attribute (gen-scope inheritSet) carries
  #                              down the P-edge subtree, delivering v1's scope+descendants suppression.
  #
  #   scopeRoots     = the BASE (un-injected) root scope nodes { id; type; parent; decls } (buildRoots).
  #   registries     = the entity registries; the containment-target index spans ALL registry kinds (a
  #                    containTo target — e.g. `cluster` — may be a root we do NOT fire at, so the index is
  #                    NOT restricted to the fired root kinds).
  #   resolveRules   = the RESOLVE-FAMILY feed (concern-policies `policiesRules.resolveFamily`): the
  #                    structural-group rules that can emit `member` (single-group probe DETECTED, or the
  #                    `__resolveFamily` tag DECLARED for a value-conditional resolve policy). This feed —
  #                    NOT the whole structural feed — is what the pass dispatches, so an arbitrary
  #                    co-firing policy body is never run at a root (which could hit an uncatchable
  #                    missing-attribute read); a resolve-free fleet has an empty feed → the pass is inert.
  runPrePass =
    {
      scopeRoots,
      registries,
      resolveRules,
      # The EXCLUDE-FAMILY feed (#72, candidate A — ledger u21): the structural-group rules that can emit
      # `suppress` (detected or `__excludeFamily`-declared). Dispatched at the SAME roots/ctx as the resolve
      # family in the DELIVER firing, collecting per-root SUPPRESSION SETS — v1's `policy.exclude <policy>`
      # constraint registration (pin 11866c16 fx/handlers/dispatch-policies.nix:15-33: name-keyed at the
      # emitting scope, consulted scope+ancestors ⇒ descendants inherit, siblings isolated per #613). The
      # caller injects each set onto its root's decls (the typed `suppressedPolicies` slot), which the
      # `suppressed-policies` inherited attribute (gen-scope inheritSet) delivers with the v1 semantics.
      # Default `[ ]` → `suppressions = { }` → byte-identical.
      excludeRules ? [ ],
      # kindName -> its schema PARENT kind name, or null for a top-level kind (`ent.meta.<k>.parent`,
      # scalar per kind). The admissible source kind for a containment target of kind K is exactly
      # `kindParent K`, which is what makes the source-kind check total.
      kindParent,
      # NATIVE ATTACHMENT (route 2, `den.attach`): kind -> { ref; unless }. A kind with a row here attaches
      # its instances to the parent instance its `ref` field names, with no policy. Default `{ }` ⇒ no
      # synthetic emissions ⇒ byte-identical to the policy-only fleet.
      nativeAttach ? { },
      # THE attached-root id rule (`build-roots.nix mintedRootId`), threaded rather than re-derived:
      # this pass keys bindings at the node that will carry them, `buildRoots` mints that node, and
      # one definition is what keeps the two from drifting.
      mintedRootId,
    }:
    let
      # The containment-target index spans EVERY registry kind (a containTo target may be a root outside the
      # fired root set — the corpus's `cluster` is a candidate we do not fire at, yet a resolve.to "cluster"
      # containment tuple targets it).
      index = rootNodeIndex {
        inherit registries;
        rootKinds = builtins.attrNames registries;
      };

      ids = builtins.attrNames scopeRoots;

      # A root is parentless: its base ctx = its own decls (the same `__`-key strip as attr 1).
      baseCtxOf =
        id:
        removeAttrs scopeRoots.${id}.decls [
          "__edges"
          "__containment"
          "__coords"
          "__root"
        ];

      # Fire the resolve-family rules at ONE root and return its `member` emissions. Only the resolve-family
      # feed is dispatched (see `resolveRules`), so every rule here is a genuine resolve policy — no `tryEval`
      # masking: a broken resolve policy surfaces LOUD (never a silent drop). A single one-shot dispatch
      # (single-group), honoring `__firesAtKinds` (the same scope-local firing pre-filter attr 2/4 apply);
      # the caller partitions CELL (`containTo == null`) vs CONTAINMENT (`containTo` set) tuples. A
      # value-conditional resolve policy taking its false branch simply emits nothing here (its member
      # arrives once its ctx value is present).
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

      isContainment = a: (a.containTo or null) != null;

      # Resolve ONE `containTo`-marked emission to its { tid; bindings; sourceSlice } record (design note
      # §3c-UNIFIED). The target coordinate is `coords.<containTo>` (an identity entry → its root node id via
      # `index`). The SOURCE coordinate (coords minus the target) becomes the target root's containment
      # ANCESTOR. A PARENTLESS root target has an empty source slice (no firing-scope coordinate).
      containmentOf =
        a:
        let
          containTo = a.containTo;
          targetEntry = a.coords.${containTo} or null;
          tid = if targetEntry == null then null else index.${targetEntry.id_hash} or null;
          policyName = a.__policy or "«anonymous»";
          slice = builtins.removeAttrs a.coords [ containTo ];
          coordNames = builtins.attrNames slice;
          # The source slice's shape decides an id and (downstream) a scope parent edge, so its trichotomy
          # is settled HERE, once, where the slice is computed:
          #   EMPTY       — legitimate: bindings with no attachment (a parentless root target has no
          #                 firing-scope coordinate). Accepted; it mints no source and no ancestor.
          #   SINGLE-COORD — the attachment case. Its kind must be the target kind's schema parent, since
          #                 `parent` is scalar per kind and any other kind asserts a second parent KIND.
          #   MULTI-COORD  — two candidate sources for one edge; the id rule would silently take the
          #                 alphabetically-first, so it aborts instead.
          expectedKind = kindParent containTo;
          sliceOk =
            if coordNames == [ ] then
              true
            else if builtins.length coordNames > 1 then
              errors.containmentSliceAmbiguous policyName tid coordNames
            else if builtins.head coordNames != expectedKind then
              errors.containmentKindMismatch policyName tid expectedKind (builtins.head coordNames)
            else
              true;
        in
        if tid == null then
          errors.containTargetMissing (a.__policy or "«anonymous»") targetEntry
        else
          {
            inherit tid;
            bindings = a.bindings or { };
            sourceSlice = builtins.seq sliceOk slice;
          };

      # COLLECT — fire every root against its OWN decls; the `containTo`-marked emissions, in root-iteration
      # (`attrNames`, alphabetical) then per-root emission order. This flat list is the transpose pre-image.
      # ── NATIVE ATTACHMENT (route 2) ────────────────────────────────────────────────────────────────
      # Synthetic containment emissions derived from `den.attach`, in the SAME record shape a policy
      # emission lowers to (`{ tid; bindings; sourceSlice }`). They are concatenated into
      # `containmentEmissions` — UPSTREAM of `byTarget` — deliberately: `byTarget` is the pre-image of all
      # five products this pass returns (bindings, ancestors, edges, attachments, and the cycle guard over
      # them), so one emission reaches every one of them. Injecting further down, at the caller's
      # `attachments` map, would supply the parent edge while leaving the ancestor slice and the ctx/decls
      # fold without the fact — an attachment whose inheritance silently does not exist.
      #
      # ADDITIVE, not a replacement: a fleet that also attaches by policy emits the same fact twice, and
      # `attachmentsOf` (below) dedups the rendered ids, so the target keeps ONE attachment and its bare
      # node id. `containmentAncestors` does NOT dedup, so a doubly-emitted fact yields a repeated ancestor
      # slice there — harmless for the ancestor WALK (gen-graph visits first-occurrence) but the reason the
      # settings chain is measured rather than assumed.
      #
      # `bindings = { }`: a native attachment asserts containment only. Policy attachments that also bind
      # context (the corpus's `accessGroups`) keep doing so through their own emission.
      nativeEmissions = prelude.concatMap (
        kindName:
        let
          row = nativeAttach.${kindName};
          parentKind = kindParent kindName;
          instances = registries.${kindName} or { };
        in
        # A kind with no declared parent has nothing to attach TO — the row is inert rather than an error,
        # so a fleet may declare attachment for a kind whose parentage is supplied elsewhere.
        if parentKind == null then
          [ ]
        else
          prelude.concatMap (
            name:
            let
              entry = instances.${name};
              # THE OPT-OUT, a VALUE test: absent field ⇒ attaches (absence is not opt-out), present and
              # empty ⇒ withheld. Same shape the placement gate runs, so one declaration governs both.
              optedOut = row.unless != null && (entry ? ${row.unless}) && entry.${row.unless} == [ ];
              refValue = entry.${row.ref} or null;
              parentEntry = (registries.${parentKind} or { }).${toString refValue} or null;
            in
            if optedOut || refValue == null then
              [ ]
            else if parentEntry == null then
              errors.attachRefUnresolved kindName name row.ref parentKind refValue
            else
              [
                {
                  tid = index.${entry.id_hash} or "${kindName}:${name}";
                  bindings = { };
                  sourceSlice = {
                    ${parentKind} = parentEntry;
                  };
                }
              ]
          ) (builtins.attrNames instances)
      ) (builtins.attrNames nativeAttach);

      containmentEmissions =
        prelude.concatMap (
          id:
          map containmentOf (builtins.filter isContainment (fireAt scopeRoots.${id}.type id (baseCtxOf id)))
        ) ids
        ++ nativeEmissions;

      # TRANSPOSE by TARGET node id — `prelude.groupBy` buckets order-preserving (the kernel groupBy idiom,
      # fleet.nix / edges.nix). The transpose is order-independent AS A MAP: no parent-before-child phase
      # schedule materializes it.
      byTarget = prelude.groupBy (e: e.tid) containmentEmissions;

      # target -> merged bindings. Per-bucket `acc // e.bindings` last-wins over the ordered bucket equals the
      # last emission in `containmentEmissions` order — the same global last-wins the pre-transpose flat fold
      # produced (the push's `(acc.${tid} or {}) // a.bindings`). Determinism holds regardless of source kind:
      # both this transpose and the pre-transpose fold consume the identical `attrNames`-ordered
      # `containmentEmissions` pre-image, and groupBy preserves that order within each bucket, so a collision's
      # winner is byte-identical either way. By convention containment sources of a kind-K target are all of
      # kind parent(K) (a scalar parent field), so in practice targets are single-source (the corpus/fixtures)
      # ⇒ no merge at all; the ordering guarantee above is what makes any collision deterministic anyway.
      # target -> its attachment ids, deduped, in emission order. A target may receive SEVERAL
      # emissions from one source (the bucket is per-emission), so it is the distinct rendered
      # sources that count as attachments.
      attachmentsOf = nid: prelude.unique (containEdges nid);

      # minted node id -> merged bindings. Keyed by NODE ID, not by target: at N≥2 the target no
      # longer names a node, and both consumers (`deliverCtxOf` below, and the decls fold at the
      # call site) index by node id under an `or { }`, so a target-keyed map would miss silently.
      #
      # The partition is by (target, SOURCE), which is what retires the cross-source merge: each
      # minted node carries only the bindings of the source that minted it. Two rules survive it:
      #   • same-SOURCE multi-emission still merges — the `//` fold is per bucket, unchanged;
      #   • a bindings-only emission (empty slice, no attachment) goes to ALL of the target's nodes.
      #     D is entity-level, so dropping it would lose data a single-attachment config keeps, and
      #     routing it to one node would be last-wins by another name.
      # Order is the original emission order throughout, so the existing last-wins is preserved.
      # At N≤1 this is a relabelling of the same partition onto the same bare key — byte-identical.
      containmentBindings = prelude.foldl' (acc: m: acc // m) { } (
        builtins.attrValues (
          builtins.mapAttrs (
            tid: es:
            let
              parents = attachmentsOf tid;
              foldBindings = sel: prelude.foldl' (acc: e: acc // e.bindings) { } sel;
              ownedBy = p: builtins.filter (e: e.sourceSlice == { } || ancNodeId e.sourceSlice == p) es;
            in
            if parents == [ ] then
              { ${tid} = foldBindings es; }
            else
              builtins.listToAttrs (
                map (p: {
                  name = mintedRootId tid parents p;
                  value = foldBindings (ownedBy p);
                }) parents
              )
          ) byTarget
        )
      );

      # target -> [ sourceSlice ] (emission order). A parentless-root target's emission has an empty source
      # slice, contributing no ancestor; a bucket of only-empty slices drops out (no ancestor key created).
      containmentAncestors = prelude.filterAttrs (_: slices: slices != [ ]) (
        builtins.mapAttrs (_: es: builtins.filter (s: s != { }) (map (e: e.sourceSlice) es)) byTarget
      );

      # Containment-edge accessor over the transpose: a node id -> the ids of the sources that contain it.
      # LOCAL to this pass and needing no threading — `byTarget` is already in hand here. (The settings walk
      # keeps its own accessor: it reads `containmentRelations`, a slice map, not these emission records.)
      # Empty slices are dropped FIRST: a bindings-only emission names no source, so it contributes no
      # edge — the same filter `containmentAncestors` applies, and what keeps the id rule off an empty slice.
      containEdges =
        nid:
        map (e: ancNodeId e.sourceSlice) (
          builtins.filter (e: e.sourceSlice != { }) (byTarget.${nid} or [ ])
        );

      # target -> the node ids that contain it, deduped. NOT a single parent: scope parentage is a
      # partial function, so a target claimed by N sources is expressed as N NODES of one parent each
      # (`buildRoots`), never as one node of N parents. Reading several attachments here is therefore
      # the normal case, not an error — what would be an error is collapsing them onto one node.
      # A target whose emissions are all bindings-only contributes no attachment and drops out, the
      # same filter `containmentAncestors` applies.
      # CYCLE GUARD, inside this thunk so a fleet that never reads the map pays nothing, and raised
      # before any attachment is yielded: a cyclic `containTo` topology becomes a cyclic P graph, and
      # the inherit/ancestor walks are visited-guarded — they would TERMINATE, silently truncating the
      # chain, where the settings walk aborts loud. Silent truncation is the worse failure. Cost is
      # bounded: id strings only.
      containmentAttachments =
        let
          cyclic = graph.cycles {
            edges = containEdges;
            nodes = builtins.attrNames byTarget;
          };
        in
        if cyclic != [ ] then
          errors.containmentCycle (builtins.head cyclic)
        else
          prelude.filterAttrs (_: parents: parents != [ ]) (
            builtins.mapAttrs (tid: _: attachmentsOf tid) byTarget
          );

      # The DELIVER ctx: base decls extended by the target's OWN transpose slice (the demand read). Delivered
      # exactly where the root fires, so a consuming resolve policy sees its binding at its firing scope.
      deliverCtxOf = id: baseCtxOf id // (containmentBindings.${id} or { });

      # DELIVER (cells) — the bare (`containTo == null`) `member` emissions at every root become CELL tuples.
      # A5: emitted at a membership-independent root → `via.membershipDerived = false` (fleet.nix's
      # disciplineOk passes it through); `via` names the emitting policy + scope for provenance.
      tuples = prelude.concatMap (
        id:
        map (a: {
          inherit (a) coords;
          via = {
            policy = a.__policy or null;
            scope = id;
            membershipDerived = false;
          };
        }) (builtins.filter (a: !(isContainment a)) (fireAt scopeRoots.${id}.type id (deliverCtxOf id)))
      ) ids;

      # DELIVER (suppressions) — the exclude family fired with the SAME slice-extended ctx. A value-
      # conditional excluder taking its false branch emits nothing (the corpus's droid-gated route exclude
      # suppresses only at droid-class roots).
      suppressions = prelude.foldl' (
        acc: id:
        let
          suppressed = map (a: a.name) (fireExcludeAt scopeRoots.${id}.type id (deliverCtxOf id));
        in
        if suppressed == [ ] then acc else acc // { ${id} = suppressed; }
      ) { } ids;
    in
    {
      inherit
        tuples
        containmentBindings
        containmentAncestors
        containmentAttachments
        suppressions
        ;
    };
in
{
  inherit
    ancNodeId
    rootNodeIndex
    runPrePass
    ;
}
