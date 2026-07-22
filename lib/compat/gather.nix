# The v1 cross-scope channel GATHER, re-layered off the two hand-rolled compat recursions it retired — the
# expose ascent (`collectAllExposed`, pin 11866c16 assemble-pipes.nix:701-782) and the collect/collectAll
# candidate gathers (`findMatchingSiblings`/`findMatchingAll` :318-382) — PLUS the previously-unwired
# broadcast arm (`collectAllBroadcast` :794, the push-dual of expose). It fills the core per-node
# channel-augmentation seam (#62a) as the composed `den.channelGather` supplier (flake-module.nix).
#
# THE RE-LAYERING (what this file is, and is NOT). The old `exposedUpBy` gated recursion and the
# `gatherMark` candidate walk are GONE. Only ONE arm is genuinely transitive — the EXPOSE ascent — and it
# is the ONLY thing that touches gen-graph: it routes through `denHoag.query` (`query`, paths mode) so the
# gated-transitive ascent lives in the engine. The other three arms (collect / collectAll / broadcast) are
# NOT transitive — they are ONE-HOP predicate FILTERS over the fleet node set, so they take NO query layer
# at all: a direct `builtins.filter (predicateMatches …) cand`. The candidate set is `allNodeIds result` =
# `attrNames result.allNodes`, ALREADY attrNames-lexicographic, so the filter reproduces v1's
# `filter … (attrNames scopeContexts)` order EXACTLY, with no materialized edge list and no per-node
# re-scan. This file therefore holds ONLY: name→construct maps (`exposeChannelsAt`/`collectMarksAt`/
# `broadcastMarksAt`), v1-dialect selection CLOSURES (`predicateMatches`/`contributionsOf`), flat
# candidate/edge builders (one-level `filter`/`map`/`foldl'` over `allNodeIds`+`childrenIds`), and
# data-merge folds over result lists — no recursion, no fixpoint, no fold-over-graph, no edge-walk, no
# transpose (the sole graph traversal is the expose `queryPaths`).
#
# COMPUTE-ONCE (per fleet, not per consumer). `mkGather` binds `result` BEFORE the per-consumer `id` (the
# seam hoists `channelGather result` once — output-modules.nix), so the three per-fleet indices are built
# ONE time and shared across every consumer:
#   • `exposePoolByNode` — each node's received expose pool (itself channels × `queryPaths`), a lazy
#     per-node-memoized attrset: forced at most ONCE per node, reused by every consumer that matches it as
#     a collect peer (was: recomputed per matched-peer × per collect-mark × per consumer — the dominant
#     cost). The per-channel edge set is likewise built once (`exposeEdgesByChannel`), not per (node,P).
#   • sibling buckets (`siblingBuckets`) — parent → [child ids] in attrNames order, one O(n) pass; a
#     `collect` mark scans only its parent's bucket, not all nodes.
#   • broadcaster index (`broadcastersByChannel`) — channel → [{sid;receiver}] in attrNames order, one O(n)
#     pass; a consumer tests only the (few) actual broadcasters of a channel, not `filter (≠self) allNodes`.
#
# ── EXPOSE ARM (paths-mode + flat `++` fold) — v1 `collectAllExposed`, GATED-TRANSITIVE ────────────────
# v1 is bottom-up and gated: a value bubbles up level-by-level and each hop must RE-EXPOSE the channel for
# it to keep rising; a non-re-exposing intermediate TRAPS its descendants' data (assemble-pipes.nix:770-781,
# `combinedBase = resolvedBase ++ exposedValues`). Rendered as a gate on the EDGE: `parent→child` exists
# iff `child` re-exposes P; `follow = "${P}+"` (one-or-more P-edges) walks the gated-transitive ascent, so
# a trapping intermediate breaks the chain exactly as v1 did. `paths` mode gives parent-before-children
# pre-order with siblings in edge order (= `childrenIds` = id_hash-lexicographic), and the flat `++` fold
# over that ordered result reproduces v1's `localContribs(node) ++ childMerged` per level. NOT `queryFold`:
# its ACI contract is violated by `++`, and its lexicographic order diverges from children-first pre-order
# beyond depth-1. `follow = "${P}+"` requires ≥1 step, so the consumer is excluded from its own pool
# (matching v1's `gatheredAt` = direct-children pool; the consumer's own local emits are prepended by the
# #62a seam). Values cross UNFORCED — a deferred (config-thunk) contribution keeps its producer scope and
# resolves at the consuming terminal (v1's `markConfigThunks` subsumed; the expose producers live in the
# consuming root's OWN subtree, so no cross-host fixpoint arises).
#
# ── COLLECT / collectAll ARM (direct filter + F2 predicate) — v1 findMatchingSiblings/findMatchingAll ──
# collect = same-parent SIBLING candidate set (the sibling bucket); collectAll = ALL nodes. Self-excluded.
# `builtins.filter (predicateMatches …) cand` over the (attrNames-sorted) candidate set = v1's source-node-
# id lexicographic order, no dedup (A12). The F2 gate is `predicateMatches` (`hasRequired` ∧ own-kind
# `extraEntityKinds == []` ∧ `predicate ctx`). `contributionsOf` reads each matched peer's raw emits PLUS
# its received expose pool (`collectTagged` :437-450 — via `exposePoolFor`, the memoized per-node index), a
# config-thunk on a collected channel aborting LOUD (the F6 ceiling — errors.collectedConfigThunk).
#
# ── BROADCAST ARM (direct filter over the broadcaster index) — v1 `collectAllBroadcast` :794 (newly wired)
# Broadcast is collect REVERSED: the PRODUCER carries the receiver predicate, evaluated against the
# CONSUMER. For each channel, the broadcaster index gives its producers; a consumer keeps those whose
# receiver predicate accepts it (`predicateMatches … receiver consumerId` — the SAME F2 closure, applied
# to the consumer's ctx/own-kind). This is what makes a `{ user, … }: true` broadcast reject a HOST
# consumer (host ctx has no `user`, own-kind `host` ∉ predEntityArgs). The gathered value is the producer's
# emits: the DERIVED terminal when the pipe carries a source-side transform before the `broadcast` mark
# (residual #4, read via `derivedBaseNames`), else the RAW `localContribs`. The broadcast pool is a SEPARATE
# map entry — NOT read by `contributionsOf` — so broadcast-injected values are never re-collected (the
# push/pull isolation).
#
# ── PERF. PEER arms (collect / collectAll / broadcast): every avoidable factor is eliminated — no
# materialized edge list / query re-scan (direct filter), no per-peer expose-pool recompute (memoized per
# node), no per-mark sibling re-filter (bucket lookup); `collect` (sibling) is O(bucket), not O(n). Their
# ONLY residual is INHERENT all-pairs predicate matching (collectAll = each such consumer tests every
# producer, broadcast = each tests every broadcaster of a channel — the `where` IS the work, genuinely n²
# PAIRS when many consumers each match many producers), not reducible without cross-consumer predicate
# dedup. The EXPOSE arm's per-channel edge LIST is memoized once (`exposeEdgesByChannel`), AND the shared
# `denHoag.query` facade prebuilds a label→from→targets adjacency once (`perLabelFromEdges`, O(E) via
# `groupBy`) so the per-node-visit out-neighbour lookup during the `queryPaths` DFS is an O(1) index — no
# per-call rescan of the edge list. So the expose ascent is O(E) over its (single, shallow `resolved-users`)
# channel with no residual facade overhead; its only cost is the inherent gated-transitive walk itself.
#
# ── RESIDUALS (shared with the retired files; corpus-zero, documented ceilings, never silent) ──────────
#   (#1) expose-WITH-transform-stages — v1 applies the pipe's `applyTransformStages` at the exposing node
#     before ascent. The corpus's sole expose pipe (`expose-resolved-users`) is BARE, so this moves raw
#     contributions (identity transform). A future deriving expose pipe would need the exposing-node run
#     applied here; not corpus-exercised, carried as a named ceiling.
#   (#4) broadcast source-side transform — WIRED: a broadcast pipe carrying a `transform` before the
#     `broadcast` mark has a DERIVED terminal (the kernel's untargeted-deriving supersede named it, folded by
#     `pipe.run` into the source's received-collections); the broadcast arm reads that terminal (via
#     `derivedBaseNames`, threaded through the gather contract) in place of the raw `localContribs`. A BARE
#     broadcast has no terminal (`Ts == [ ]`) → the raw path, byte-unchanged. Own-vs-received ceiling: v1's
#     source is the producer's OWN emits + transform, this reads the neron-folded terminal; they coincide at
#     a leaf broadcaster inheriting no base (corpus-zero for broadcast). Shares the residual #1 shape for the
#     EXPOSE arm (still unwired there — no corpus deriving expose pipe).
#   Multi-policy DOUBLING (expose) — dedup is by CHANNEL (`exposeChannelsAt`'s `unique`), one push per
#     channel however many policies expose it; v1 pushes once per policy. Corpus's sole expose pipe is one
#     policy on one channel — shapes agree; a multi-policy corpus would surface it as a P2 byte divergence
#     (extra copies on the v1 arm), never silent.
#
# NO EFFECT RUNTIME / A17: every arm reads DECLARED attributes (`children`, `declarations`,
# `local-collection-data`, `enriched-context`, `node`) + the node id spine — no dispatch state, no
# scope-graph mutation, never a resolved-aspects force. The per-fleet indices are LAZY (attrset entries
# forced on demand), so a consumer forces only the peers it matches, exactly as before. KIND-GENERIC: the
# entity-kind set is a PARAMETER; the only literals are the v1-spec mark tags.
#
# Deps: `prelude` (utility base); `query` = `denHoag.query` (`denQuery`, wired with the OUTER gen-graph
# engine — lib/query.nix) — the EXPOSE arm's paths-mode ascent (the sole graph traversal). `errors` for the
# F6 config-thunk abort.
{
  prelude,
  query,
}:
let
  errors = import ./errors.nix { inherit prelude; };

  # ── shared v1-dialect closures (lifted verbatim from the retired expose-gather / collect-gather) ──────
  collectionDeclsAt = result: nid: (result.get nid "declarations").actions.collection or [ ];
  localContribs =
    result: nid: channel:
    (result.get nid "local-collection-data").${channel} or [ ];
  childrenIds = result: nid: builtins.attrNames (result.get nid "children");
  allNodeIds = result: builtins.attrNames result.allNodes;

  # Per-channel list-concat merge of `{ <channel> = [ contribution ]; }` maps (v1's ordered accumulation).
  # Source-order-preserving, no dedup (A12 / v1 concat).
  mergeMaps =
    maps:
    prelude.foldl' (
      acc: m:
      prelude.foldl' (a: ch: a // { ${ch} = (a.${ch} or [ ]) ++ m.${ch}; }) acc (builtins.attrNames m)
    ) { } maps;

  # The channels a node RE-EXPOSES: the `channel` of each `expose` site-mark it carries, deduped by CHANNEL
  # (the multi-policy doubling ceiling — v1 would push once per policy).
  exposeChannelsAt =
    result: nid:
    prelude.unique (
      map (a: a.channel) (
        builtins.filter (
          a:
          (a.__action or null) == "pipeOp"
          && builtins.any (m: (m.__pipeMark or null) == "expose") (a.marks or [ ])
        ) (collectionDeclsAt result nid)
      )
    );

  # The collect/collectAll SITE MARKS at a node: `{ channel; all; predicate; }` per mark (the predicate
  # rides the mark; `all` distinguishes collectAll from collect).
  collectMarksAt =
    result: nid:
    prelude.concatMap (
      a:
      if (a.__action or null) == "pipeOp" then
        prelude.concatMap (
          m:
          if
            builtins.elem (m.__pipeMark or null) [
              "collect"
              "collectAll"
            ]
          then
            [
              {
                channel = a.channel;
                all = m.__pipeMark == "collectAll";
                inherit (m) predicate;
              }
            ]
          else
            [ ]
        ) (a.marks or [ ])
      else
        [ ]
    ) (collectionDeclsAt result nid);

  # The broadcast SITE MARKS at a node: `{ channel; receiver; }` per mark (the receiver predicate rides
  # the mark; the push-dual of the collect predicate).
  broadcastMarksAt =
    result: nid:
    prelude.concatMap (
      a:
      if (a.__action or null) == "pipeOp" then
        prelude.concatMap (
          m:
          if (m.__pipeMark or null) == "broadcast" then
            [
              {
                channel = a.channel;
                receiver = m.receiver;
              }
            ]
          else
            [ ]
        ) (a.marks or [ ])
      else
        [ ]
    ) (collectionDeclsAt result nid);

  # F2 — v1's predicate matching, EXACT (findMatchingSiblings/findMatchingAll share it, :330-352). The
  # scope's OWN creation kind (`.type`, total — v1's null-fallback ctx-scan carried for fidelity) must be
  # covered by the predicate's entity-kind formals (`extraEntityKinds == []`) — what makes `{ host, … }`
  # select host scopes ONLY and reject a (user,host) cell whose ctx also carries `host`.
  predicateMatches =
    entityKinds: result: predicate: sid:
    let
      ctx = result.get sid "enriched-context";
      predArgs = builtins.functionArgs predicate;
      requiredArgs = builtins.filter (k: !predArgs.${k}) (builtins.attrNames predArgs);
      predEntityArgs = builtins.filter (k: entityKinds ? ${k}) requiredArgs;
      hasRequired = builtins.all (k: ctx ? ${k}) requiredArgs;
      ownKind = (result.node sid).type or null;
      scopeOwnEntityKinds =
        if ownKind != null then
          [ ownKind ]
        else
          builtins.filter (k: ctx ? ${k}) (builtins.attrNames entityKinds);
      extraEntityKinds = builtins.filter (k: !(builtins.elem k predEntityArgs)) scopeOwnEntityKinds;
    in
    hasRequired && extraEntityKinds == [ ] && predicate ctx;

  # ── EXPOSE arm — gated-transitive ascent via paths-mode + flat `++` fold (the sole graph traversal) ───
  # Edges: a flat one-level map over all nodes — `parent→child` iff `child` re-exposes P. gen-graph
  # provides the transitivity (`follow = "${P}+"`); this builder is NOT recursive.
  exposeEdgesFor =
    result: P:
    prelude.concatMap (
      nid:
      map (cid: {
        kind = P;
        from = nid;
        to = cid;
      }) (builtins.filter (cid: builtins.elem P (exposeChannelsAt result cid)) (childrenIds result nid))
    ) (allNodeIds result);

  # The candidate channel set = the union of every node's re-exposed channels.
  exposeChannelSet =
    result: prelude.unique (prelude.concatMap (exposeChannelsAt result) (allNodeIds result));

  # The received expose pool at a consumer, given the channel set + a per-channel edge source `edgesOf`.
  # Per P: pre-order DFS over the P-gated edges (`follow = "${P}+"` = the gated-transitive ascent), then the
  # flat `++` fold of each reached descendant's raw emits. `paths` order = parent-before-children, siblings
  # in edge (= id_hash-lex) order = v1 `exposedUpBy`. Empty channels dropped (the augmentation is identity).
  exposePoolCore =
    result: channelSet: edgesOf: consumerId:
    prelude.foldl' (
      acc: P:
      let
        v = prelude.concatMap (r: localContribs result r.node P) (query {
          edges = edgesOf P;
          from = consumerId;
          follow = "${P}+";
          mode = "paths";
        });
      in
      if v == [ ] then acc else acc // { ${P} = v; }
    ) { } channelSet;

  # The standalone expose-pool witness (per-call channel set + edges) — the depth-semantics unit stub path.
  exposePoolAt = result: exposePoolCore result (exposeChannelSet result) (P: exposeEdgesFor result P);

  # collectTagged (:437-450): a matched scope's RAW emits PLUS its received expose pool (via the injected
  # `exposePoolFor` lookup — memoized per node in `mkGather`, per-call in the witness). A DEFERRED
  # contribution on a collected channel aborts LOUD (the F6 ceiling).
  contributionsOf =
    result: exposePoolFor: consumer: channel: sid:
    map
      (
        c:
        if c.deferred or false then
          errors.collectedConfigThunk {
            inherit channel;
            producer = sid;
            inherit consumer;
          }
        else
          c
      )
      (
        ((result.get sid "local-collection-data").${channel} or [ ])
        ++ ((exposePoolFor sid).${channel} or [ ])
      );

  # ── COLLECT / collectAll arm — direct filter over the (attrNames-sorted) candidate set ────────────────
  # One collect mark's gather. `cand` is the candidate set (all nodes for collectAll, the sibling bucket for
  # collect) — both attrNames-sorted, so `builtins.filter (predicate) cand` yields v1's source-node-id
  # lexicographic order with no query layer. `exposePoolFor`/`siblingsOf` are injected (precomputed in
  # `mkGather`, per-call in the witness).
  gatherMarkWith =
    {
      entityKinds,
      result,
      exposePoolFor,
      siblingsOf,
    }:
    nid: mark:
    let
      cand = if mark.all then builtins.filter (sid: sid != nid) (allNodeIds result) else siblingsOf nid;
      matched = builtins.filter (predicateMatches entityKinds result mark.predicate) cand;
    in
    prelude.concatMap (contributionsOf result exposePoolFor nid mark.channel) matched;

  # The collect half at a node: `{ <channel> = [ contribution ]; }` over its collect/collectAll marks.
  collectGatheredWith =
    args@{ result, ... }:
    nid:
    prelude.foldl' (
      acc: mark:
      acc // { ${mark.channel} = (acc.${mark.channel} or [ ]) ++ gatherMarkWith args nid mark; }
    ) { } (collectMarksAt result nid);

  # ── BROADCAST arm — direct filter over the channel's broadcaster set (push-dual) ──────────────────────
  # `broadcastersByChannel` is `{ <channel> = [ { sid; receiver } ]; }`, attrNames-sorted (built once). A
  # consumer keeps those producers whose receiver predicate accepts IT (F2 applied to the consumer's ctx/
  # own-kind), self-excluded, and takes each producer's RAW emits. Empty channels dropped.
  broadcastGatheredWith =
    {
      entityKinds,
      derivedBaseNames,
      result,
      broadcastersByChannel,
    }:
    consumerId:
    prelude.foldl' (
      acc: P:
      let
        producers = builtins.filter (
          b: b.sid != consumerId && predicateMatches entityKinds result b.receiver consumerId
        ) broadcastersByChannel.${P};
        # Source-side transform (residual #4, now wired): a broadcast pipe carrying a `transform` before the
        # `broadcast` mark has a DERIVED terminal (the KERNEL's untargeted-deriving supersede named it, and
        # `pipe.run` already folded it into the source's received-collections). Read that terminal in place of
        # the raw `localContribs` — a THIN wire, one `result.get` swapped for another; the derive-fold stays
        # in the kernel. A BARE broadcast (no source transform) has no terminal for `P` (`Ts == [ ]`) → the
        # raw path, byte-unchanged.
        Ts = derivedBaseNames.${P} or [ ];
        sourceOf =
          b:
          if Ts == [ ] then
            localContribs result b.sid P
          else
            prelude.concatMap (T: (result.get b.sid "received-collections").${T}.contributions or [ ]) Ts;
        v = prelude.concatMap sourceOf producers;
      in
      if v == [ ] then acc else acc // { ${P} = v; }
    ) { } (builtins.attrNames broadcastersByChannel);
in
{
  # The witness surface: `gatheredAt` (the gated-transitive expose ascent, for the depth-semantics unit
  # tests — same `(result, id)` signature as the retired `exposeGather.gatheredAt`).
  gatheredAt = exposePoolAt;

  # The COMPOSED `den.channelGather` supplier, CURRIED on `derivedBaseNames` (the base→terminal map — the
  # broadcast arm reads a source's transformed terminal) then `result` so the per-fleet indices below are
  # built ONCE (the seam hoists `channelGather derivedBaseNames result` — output-modules.nix) and shared
  # across every consumer id. Per channel: the received expose pool FIRST, the collected peers next, the
  # broadcast-injected values last — matching v1's consumption order (`mkCombinedBase` own++exposed
  # :935-948, then the collect stages :455-478, then `collectAllBroadcast` :794; the #62a seam prepends the
  # node's own local emissions). `entityKinds` = the fleet's registered kind set (F2 gating).
  mkGather =
    entityKinds: derivedBaseNames: result:
    let
      allIds = allNodeIds result;

      # (1) per-node expose pool — the per-channel edge set built ONCE per channel, then each node's pool a
      #     lazy attrset entry (forced ≤ once per node, reused across every consumer that matches it).
      channelSet = exposeChannelSet result;
      exposeEdgesByChannel = prelude.genAttrs channelSet (P: exposeEdgesFor result P);
      exposePoolByNode = prelude.genAttrs allIds (
        exposePoolCore result channelSet (P: exposeEdgesByChannel.${P})
      );
      exposePoolFor = sid: exposePoolByNode.${sid} or { };

      # (2) sibling buckets — parent → [child ids] in attrNames order, one O(n) pass. Parentless ROOTS are
      #     mutual siblings (v1 `parentOf sid == parentOf nid` with both null), kept in `rootIds` (a `null`
      #     parent cannot key an attrset).
      siblingBuckets = prelude.foldl' (
        acc: sid:
        let
          p = (result.node sid).parent;
        in
        if p == null then acc else acc // { ${p} = (acc.${p} or [ ]) ++ [ sid ]; }
      ) { } allIds;
      rootIds = builtins.filter (sid: (result.node sid).parent == null) allIds;
      siblingsOf =
        nid:
        let
          p = (result.node nid).parent;
        in
        builtins.filter (sid: sid != nid) (if p == null then rootIds else siblingBuckets.${p} or [ ]);

      # (3) broadcaster index — channel → [{sid;receiver}] in attrNames order, one O(n) pass.
      broadcastersByChannel = prelude.foldl' (
        acc: sid:
        prelude.foldl' (
          a: m:
          a
          // {
            ${m.channel} = (a.${m.channel} or [ ]) ++ [
              {
                inherit sid;
                inherit (m) receiver;
              }
            ];
          }
        ) acc (broadcastMarksAt result sid)
      ) { } allIds;

      collectAt = collectGatheredWith {
        inherit
          entityKinds
          result
          exposePoolFor
          siblingsOf
          ;
      };
      broadcastAt = broadcastGatheredWith {
        inherit
          entityKinds
          derivedBaseNames
          result
          broadcastersByChannel
          ;
      };
    in
    id:
    mergeMaps [
      (exposePoolFor id)
      (collectAt id)
      (broadcastAt id)
    ];
}
