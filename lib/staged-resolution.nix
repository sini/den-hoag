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
#   • DELIVER — fire at every LOCUS a root becomes, against that locus's decls PLUS its OWN transpose
#     slice (the demand read), keeping the CELL tuples (`containTo = null`) + the per-locus SUPPRESSION
#     set. A consuming resolve policy (env-users reading `accessGroups`; the synthetic rack policy reading
#     `authToken`) sees its slice here, exactly where it fires, and emits CELL tuples — those are NOT fed
#     back into `containmentBindings`, so there is no cycle (the map is produced only by
#     containment-emitters that don't themselves consume it).
#     ★ THE LOCUS, NOT THE BARE ROOT, IS THE FIRING SITE. A target claimed by N sources is N NODES of one
#     parent each, carrying N DIFFERENT binding slices; a single firing at the bare id has no well-defined
#     slice to read and silently reads the empty one. Per node each slice is total, so the firing goes
#     where the fact lives. COLLECT keeps its one-per-bare-root firing because it is what PRODUCES the
#     attachments — the loci do not exist until it has run.
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
  #
  # ONE traversal that allocates the index once. The nested `acc // { … }` fold this replaces rebuilt
  # the ENTIRE accumulator per entry — `//` copies every binding it carries — so building an index of
  # n entries copied O(n²) bindings, and the traversal spans every registry kind (including the ones
  # the pre-pass never fires at, which is where the entry count actually grows). `listToAttrs` walks
  # the pair list once and allocates the attrset once.
  #
  # THE ORDER PRECONDITION THE SWAP CARRIES: `listToAttrs` keeps the FIRST binding of a repeated key
  # where the fold kept the LAST, so the two forms agree only while `id_hash` is injective over the
  # indexed entries. It is injective ACROSS KINDS BY CONSTRUCTION: gen-schema content-addresses an
  # instance as `sha256("<kind>|<k>=<v>|…")` over its sorted identity keys (`hashIdentity`,
  # gen-schema/lib/identity.nix) and the KIND NAME is the preimage's first field, so two entries of
  # different kinds cannot share a hash without a sha256 collision. WITHIN one kind it holds only
  # CONDITIONALLY: the `name` option gen-schema injects per instance is a reflected identity key, so
  # distinct entries normally hash distinctly — but an instance pinning `_identity.keys` replaces
  # reflection wholesale and may omit `name`, letting two instances be content-identical. That case is
  # not a choice between first and last: EITHER answer silently gives one entry the other's node id.
  # So the index refuses it by name instead of resolving it by traversal order — the collision is
  # detected by comparing the pair count to the key count, which costs one length compare and no copy.
  rootNodeIndex =
    { registries, rootKinds }:
    let
      pairs = prelude.concatMap (
        kind:
        map (name: {
          name = registries.${kind}.${name}.id_hash;
          value = "${kind}:${name}";
        }) (builtins.attrNames registries.${kind})
      ) rootKinds;
      index = builtins.listToAttrs pairs;
      # Only reached once a collision is known to exist, so the grouping cost is on the abort path.
      collidingHash = builtins.head (
        builtins.filter (h: builtins.length (byHash.${h}) > 1) (builtins.attrNames byHash)
      );
      byHash = builtins.groupBy (p: p.name) pairs;
    in
    if builtins.length pairs == builtins.length (builtins.attrNames index) then
      index
    else
      errors.rootIndexCollision collidingHash (map (p: p.value) byHash.${collidingHash});

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
  #                              emissions at each LOCUS, fired in stratification rank order so a
  #                              negated read sees a COMPLETE predicate), injected onto that node's decls as the
  #                              typed `suppressedPolicies` slot (default.nix scopeRoots) which the
  #                              `suppressed-policies` inherited attribute (gen-scope inheritSet) carries
  #                              down the P-edge subtree, delivering v1's scope+descendants suppression.
  #
  #   scopeRoots     = the BASE (un-injected) root scope nodes { id; type; parent; decls } (buildRoots).
  #   registries     = the entity registries; the containment-target index spans ALL registry kinds (a
  #                    containTo target — e.g. `cluster` — may be a root we do NOT fire at, so the index is
  #                    NOT restricted to the fired root kinds).
  #   resolveIndex   = the RESOLVE-FAMILY feed (concern-policies `policiesRules.resolveFamily`) already
  #                    SELECTED by node kind (`concernPolicies.indexByKind`): a function `kind -> [rule]`
  #                    over the structural-group rules that can emit `member`. This feed — NOT the whole
  #                    structural feed — is what the pass dispatches, so an arbitrary co-firing policy body
  #                    is never run at a root (which could hit an uncatchable missing-attribute read); a
  #                    resolve-free fleet indexes an empty feed → the pass is inert. The selection arrives
  #                    PRE-APPLIED because it is a property of the feed, not of the firing: building it
  #                    here would rebuild it at every root.
  runPrePass =
    {
      scopeRoots,
      registries,
      resolveIndex,
      # The EXCLUDE-FAMILY feed (#72, candidate A — ledger u21) as a RULE LIST rather than a pre-applied
      # index: the structural-group rules that can emit `suppress`. It arrives un-indexed because the
      # firing is STRATIFIED — one pass per rank class of the policy dependency graph — so the selection
      # is built per class here rather than once over the whole feed. v1's `policy.exclude <policy>`
      # constraint registration (pin 11866c16 fx/handlers/dispatch-policies.nix:15-33: name-keyed at the
      # emitting scope, consulted scope+ancestors ⇒ descendants inherit, siblings isolated per #613). The
      # caller injects each set onto its root's decls (the typed `suppressedPolicies` slot), which the
      # `suppressed-policies` inherited attribute (gen-scope inheritSet) delivers with the v1 semantics.
      # Default: an empty feed → `suppressions = { }` → byte-identical.
      excludeRules ? [ ],
      # The by-kind selection CONSTRUCTOR (`concernPolicies.indexByKind kinds`), applied here once per
      # rank class. Threaded rather than rebuilt so the exclude feed's selection is the same expression
      # every other feed's is.
      indexFeed ? (_: (_: [ ])),
      # policy name -> its RANK in the stratification (concern-policies `policyRank`): the position of
      # the policy's cluster in the condensation's reverse-topological order. It spans EVERY declared
      # policy, not just the exclude feed, because the stratification is a property of the whole
      # declaration graph; the feed is the projection of it that fires, joined by the rule's `identity`.
      policyRank ? { },
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
      # …and its SET form (`build-roots.nix mintedIdsOf`), for the keyings that need every node a
      # bare id becomes rather than one of them. Threaded for the same reason.
      mintedIdsOf,
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

      # A root is parentless: its base ctx = its own decls (the same `__`-key strip as attr 1). One key
      # left to strip: `__edges` is gen-scope's OWN reserved key, never den-hoag's to remove. The
      # coordinate keys this list used to name are gone from `decls` entirely — containment is an edge
      # pool and a node's position is a query over it — so the list no longer has to remember them, which
      # is the point of moving a graph fact off the node rather than teaching every reader to skip it.
      baseCtxOf = id: removeAttrs scopeRoots.${id}.decls [ "__edges" ];

      # Fire ONE feed at ONE root. The feed arrives PRE-INDEXED by node kind, so the selection is a lookup
      # rather than a predicate hidden inside a helper that two call sites share without either naming it —
      # which is how a change to one feed's selection used to reach the other unnoticed. Only the named
      # feed is dispatched, so every rule here is a genuine emitter of what `keep` collects: no `tryEval`
      # masking, and a broken policy surfaces LOUD rather than as a silent drop. `keep` is the EMISSION
      # filter (which acts this feed consumes), a different question from selection. The caller partitions
      # CELL (`containTo == null`) vs CONTAINMENT (`containTo` set) tuples. A value-conditional policy
      # taking its false branch simply emits nothing here (its emission arrives once its ctx value is).
      fireFeedAt =
        index: keep: nodeKind: id: ctx:
        let
          acts =
            (dispatch.dispatch {
              rules = index nodeKind;
              inherit id;
              context = ctx;
              match = dispatch.fromFunctionMatch;
              classify = _: "pre-pass";
              groupOrder = [ "pre-pass" ];
            }).actions.pre-pass or [ ];
        in
        builtins.filter keep acts;
      # Each call site NAMES the feed it selects from and the emission it keeps.
      fireAt = fireFeedAt resolveIndex declare.isResolveFamily;

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
      # longer names a node, and every consumer (`ctxAt` below, and the decls fold at the call site)
      # indexes by node id under an `or { }`, so a target-keyed map would miss silently rather than
      # loudly. That silence is why the reader had to move to the locus as well as the writer: a map
      # keyed at the node and read at the bare id yields the EMPTY slice, which is byte-identical to
      # "this node has no bindings".
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
      #
      # PRIVATE. Every reader outside this pair goes through `containEdges` below, which is the same walk
      # behind the cycle guard; the raw form exists so the guard's OWN walk does not re-enter it.
      rawContainEdges =
        nid:
        map (e: ancNodeId e.sourceSlice) (
          builtins.filter (e: e.sourceSlice != { }) (byTarget.${nid} or [ ])
        );

      # THE CONTAINMENT CYCLE GUARD, at the PRODUCT boundary rather than on a demand path.
      #
      # A cyclic `containTo` topology becomes a cyclic P graph, and the inherit/ancestor walks are
      # visited-guarded — they would TERMINATE, silently truncating the chain, where the settings walk
      # aborts loud. Silent truncation is the worse failure, so the cyclic walk must never form.
      #
      # ONE check, computed once and forced by every product this pass returns (`mapAttrs` over the export
      # record below), so MEMBERSHIP IN THE RECORD IMPLIES GUARDING. Guarding each export by a separate
      # application would leave a future export unguarded by default: an invariant maintained in N places
      # desyncs at N+1, and the enumeration being correct today is exactly what makes that silent. Placing
      # it on an accessor is not enough either — `containmentAncestors` reads `byTarget` directly and never
      # calls the accessor, so a consumer of the ancestors map would walk a cyclic topology past it.
      #
      # `mapAttrs` preserves per-value laziness, so a fleet that reads none of the five still pays nothing,
      # and a fleet that reads one pays the check once. Cost is bounded: id strings only.
      cycleChecked =
        let
          cyclic = graph.cycles {
            edges = rawContainEdges;
            nodes = builtins.attrNames byTarget;
          };
        in
        if cyclic != [ ] then errors.containmentCycle (builtins.head cyclic) else null;
      guarded = x: builtins.seq cycleChecked x;
      containEdges = nid: guarded (rawContainEdges nid);

      # target -> the node ids that contain it, deduped. NOT a single parent: scope parentage is a
      # partial function, so a target claimed by N sources is expressed as N NODES of one parent each
      # (`buildRoots`), never as one node of N parents. Reading several attachments here is therefore
      # the normal case, not an error — what would be an error is collapsing them onto one node.
      # A target whose emissions are all bindings-only contributes no attachment and drops out, the
      # same filter `containmentAncestors` applies. The cycle guard is no longer written here: it is
      # forced by every export (see `cycleChecked`), so this map cannot be the one path that carries it.
      containmentAttachments = prelude.filterAttrs (_: parents: parents != [ ]) (
        builtins.mapAttrs (tid: _: attachmentsOf tid) byTarget
      );

      # THE LOCUS SET of a pre-pass root: the nodes that root BECOMES. This pass iterates the BARE ids
      # `structuralNodes` mints (built with no attachments), while `containmentBindings` is keyed by the
      # MINTED node ids — so a rule reading a per-node fact must fire at the locus, not at the bare id. A
      # bare id names no node once its target is claimed by more than one source. `mintedIdsOf` is the one
      # rule for that expansion; spelling it inline here would be a second one.
      lociOf = id: mintedIdsOf id (attachmentsOf id);

      # The ctx a root's rule fires against AT ONE LOCUS: the root's own decls (a property of the
      # un-multiplied root — every node it mints shares its kind and its declarations) extended by THAT
      # LOCUS'S slice of the containment bindings. The slice map is already partitioned per (target,
      # source) by construction, so the per-node ctx exists; the firing simply goes to where it lives.
      # At N≤1 the locus IS the bare id and this is byte-identical to reading the bare slice.
      ctxAt = id: locus: baseCtxOf id // (containmentBindings.${locus} or { });

      # DELIVER (cells) — the bare (`containTo == null`) `member` emissions become CELL tuples, fired ONCE
      # PER LOCUS against that locus's own ctx. A5: emitted at a membership-independent root →
      # `via.membershipDerived = false` (fleet.nix's disciplineOk passes it through).
      #
      # ★ N FIRES, NOT ONE FIRING LABELLED N TIMES, and the difference is the content rather than the
      # mechanism. A suppression set does not depend on which node it lands at, so it may be computed once
      # and filed at each locus. A tuple's COORDS are computed FROM the ctx, and the ctx differs per
      # locus, so the body must actually run at each one. The shared principle is the locus; the mechanism
      # is not shared.
      #
      # ★ COLLECT stays ONE PER BARE ROOT, deliberately: it is what PRODUCES the attachments, so the loci
      # do not exist yet when it runs. The asymmetry is the claim, not an omission.
      #
      # `via.scope` is the LOCUS. It has exactly one reader — fleet.nix's `disciplineOk`, inside the
      # `errors.memberAtCell` abort text — and at a multiplied target a bare id there names no node, so
      # the message would be wrong. `via` is projected away at the product (`byDims` groups on the coord
      # NAMES and the relation is built from `t.coords`), so recording the locus cannot change the fleet.
      tuples = prelude.concatMap (
        id:
        prelude.concatMap (
          locus:
          map (a: {
            inherit (a) coords;
            via = {
              policy = a.__policy or null;
              scope = locus;
              membershipDerived = false;
            };
          }) (builtins.filter (a: !(isContainment a)) (fireAt scopeRoots.${id}.type id (ctxAt id locus)))
        ) (lociOf id)
      ) ids;

      # DELIVER (suppressions) — the exclude family fired PER LOCUS, in RANK ORDER.
      #
      # THE PROGRAM this computes (Apt, Blair & Walker 1988, "Stratified Programs"):
      #   fires(P, n)      <- gate(P, n) AND NOT suppressed(P, n)
      #   suppressed(Q, n) <- fires(P, m) AND emits-suppress(P, Q) AND contains*(m, n)
      # The `contains*` arm is a POSITIVE same-stratum read of `suppressed` (the `suppressed-policies`
      # inheritSet unions self with ancestors), which Definition 3's condition 1 (p. 96) admits. Only the
      # `NOT suppressed` occurrence is negative, and only it is governed by condition 2 — a negated
      # literal's definition must sit STRICTLY BELOW the stratum of the rule reading it.
      #
      # ★★ WHY THE ORDER IS THE WHOLE POINT. Firing the feed once, against a ctx carrying no
      # `suppressedPolicies`, evaluates the negative literal against the EMPTY extension of the very
      # relation being computed. That is ONE application of T_P, where the standard model is a PER-STRATUM
      # fixpoint, M_i = T_{P_i}↑ω(M_{i-1}) (p. 108). The two agree exactly when the suppression graph has
      # depth ≤ 1 and diverge above it: on the acyclic chain A⊢¬B, B⊢¬C the one-shot answer realizes B's
      # suppression of C even though B is itself suppressed — a WRONG MODEL ON STRATIFIED INPUT, which no
      # cycle guard could catch because there is no cycle. Rank-ordered firing is the fixpoint: a policy at
      # rank k fires against the set contributed by ranks strictly below k, which is condition 2 discharged
      # by the schedule rather than by an accident of when the ctx was built.
      #
      # The rank comes from the condensation of the SIGNED policy dependency graph (concern-policies
      # `policyRank`); the acyclicity that makes it a stratification at all is decided there, at
      # registration, before any rule fires.
      #
      # Keyed by minted NODE ID because each firing FILES AT ITS OWN LOCUS: the ctx is that locus's slice,
      # so the fact is a per-node fact and the node is where it belongs. There is no bare→minted
      # translation step left to get wrong — production and consumption share one key space. At N≤1 the
      # locus is the bare id, so this is byte-identical.
      suppressions =
        let
          excludeNames = map (r: r.identity) excludeRules;
          rankOf = n: policyRank.${n} or 0;
          maxRank = prelude.foldl' (
            a: n:
            let
              v = rankOf n;
            in
            if v > a then v else a
          ) 0 excludeNames;
          # The feed's rank class, as RULES: ranking spans every declared policy, firing spans the exclude
          # feed, and the two are joined by the compiled rule's `identity`.
          classAt = k: builtins.filter (r: rankOf r.identity == k) excludeRules;
          step =
            acc: k:
            let
              fireClassAt = fireFeedAt (indexFeed (classAt k)) declare.isSuppress;
            in
            prelude.foldl' (
              a: id:
              prelude.foldl' (
                a': locus:
                let
                  ctx = ctxAt id locus // {
                    suppressedPolicies = a'.${locus} or [ ];
                  };
                  fired = map (x: x.name) (fireClassAt scopeRoots.${id}.type id ctx);
                in
                if fired == [ ] then
                  a'
                else
                  a'
                  // {
                    ${locus} = prelude.unique ((a'.${locus} or [ ]) ++ fired);
                  }
              ) a (lociOf id)
            ) acc ids;
        in
        if excludeRules == [ ] then { } else prelude.foldl' step { } (prelude.range 0 maxRank);
    in
    # Every product of this pass carries the containment cycle guard, by construction: the record is
    # written once and `guarded` is applied across it, so an export added here is guarded because it is
    # a member, not because someone remembered to wrap it.
    builtins.mapAttrs (_: guarded) {
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
