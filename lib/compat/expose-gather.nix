# The v1 `pipe.expose` ASCENT twin (#62b — approved slice U9.3), wired as the `den.channelGather`
# supplier (flake-module.nix). It fills the core per-node channel-augmentation seam (#62a) with the
# cross-scope EXPOSE gather den v1 performs in `collectAllExposed` (pin 11866c16
# nix/lib/aspects/fx/assemble-pipes.nix:701-782), so a channel a node consumes but never emits locally
# (`resolved-users` at a nixos host, exposed up by its home-manager user cells — the ship-gate corpus
# shape) carries the descendant cells' contributions at the terminal binding.
#
# THE v1 SEMANTICS (faithfully matched — the depth question the build had to settle). `collectAllExposed`
# is bottom-up and GATED-TRANSITIVE, NOT a flat subtree gather: `processTree` folds children first, then a
# scope pushes to its parent ONLY IF it has an expose stage for the pipe, and what it pushes is
# `combinedBase = resolvedBase ++ exposedValues` — its OWN local emits PLUS what its children already
# exposed to it (assemble-pipes.nix:770-781). So a value bubbles up level-by-level, and each hop must
# RE-EXPOSE for it to keep rising; a non-re-exposing intermediate TRAPS its descendants' exposed data
# (`allExposed.${intermediate}` holds it, but it is never pushed further). A blind `descendants`-gather at
# every consumer would OVER-DELIVER here (a grandparent whose child does not re-expose would wrongly
# receive the grandchild's value — e.g. a fleet root receiving user-cell exposes). The gated recursion
# below is v1-exact; gen-scope `descendants` is deliberately NOT used (it is unguarded).
#
# A scope CONSUMES its exposed pool via `mkCombinedBase = markedBase ++ markedExposed` (:935-948) — own
# emissions first, exposed second — which is exactly what the #62a seam does (`local ++ gathered`), so
# this supplier returns only the `gathered` (exposed pool) half, ordered source-node-id lexicographic
# (children `attrNames`), no dedup (v1 concatenates — A12 holds; the consumer's own local emits lead).
#
# VALUES RESOLVE AT THE EXPOSING NODE (v1 `resolveLocalParametric scopeCtx`): den-hoag's
# `local-collection-data` already resolves a pipeline-parametric emit at its emitting node
# (attributes/collections.nix `resolveParametric`), so `localContribs` below IS the exposing-node-resolved
# contribution set — no re-resolution here. A gathered DEFERRED (config-thunk) contribution keeps its own
# producer scope and is resolved at the consuming terminal by output-modules' `deferredToThunk` (the #62a
# extraction path), so v1's `markConfigThunks` is subsumed — this supplier moves contributions UNFORCED.
#
# DERIVING-STAGE CEILING (corpus-verified, documented): v1 applies the pipe's `applyTransformStages` at the
# exposing node before the value ascends. The corpus's SOLE expose pipe (`expose-resolved-users`,
# nix-config policies/pipes.nix:110-116) is BARE — `pipe.from "resolved-users" [ pipe.expose ]`, no
# filter/transform/fold/for — so the transform is the identity and this supplier moves the raw contributions
# unchanged. A future expose pipe carrying deriving stages would need the exposing node's derived-channel
# run applied here; it is not corpus-exercised, so it rides as a named ceiling (not a silent divergence).
#
# NO EFFECT RUNTIME (Law C2 posture, shim side): every body reads the resolve eval's DECLARED attributes
# (`children`, `declarations`, `local-collection-data`) — no dispatch state, no scope-graph mutation. A17:
# the walk is over the children ID SPINE + the exposing nodes' cheap collection data; it never forces a
# descendant's resolved-aspects eagerly (only `local-collection-data`, which the terminal binding demands
# anyway). KIND-GENERIC: the only literal is the v1-spec `expose` mark tag (shim knowledge, permitted) — no
# kind/class name appears.
{ prelude }:
let
  # The channels a node RE-EXPOSES: the `channel` of each expose SITE-MARK it carries — a compiled
  # `pipe.from <channel> [ pipe.expose ]` (lib/compat/pipe.nix `stageOp` "expose" ⇒ a bare-channel `pipeOp`
  # whose `marks` hold `{ __pipeMark = "expose"; }`), read off the node's collection-stratum declarations
  # (`declarations.actions.collection`). Deduped (a channel exposed by several policies ascends once).
  collectionDeclsAt = result: nid: (result.get nid "declarations").actions.collection or [ ];
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

  childrenIds = result: nid: builtins.attrNames (result.get nid "children");
  localContribs =
    result: nid: channel:
    (result.get nid "local-collection-data").${channel} or [ ];

  # Per-channel list-concat merge of a list of `{ <channel> = [ contribution ]; }` maps (v1's ordered
  # accumulation into `afterChildren.${parentId}`). Preserves source order — no dedup (A12 / v1 concat).
  mergeMaps =
    maps:
    prelude.foldl' (
      acc: m:
      prelude.foldl' (a: ch: a // { ${ch} = (a.${ch} or [ ]) ++ m.${ch}; }) acc (builtins.attrNames m)
    ) { } maps;

  # What node `cid` PUSHES to its parent — the gated-transitive bubble. For each channel `cid` re-exposes:
  # its own local emits ++ what its children exposed to it (`combinedBase = resolvedBase ++ exposedValues`).
  # A channel `cid` does NOT re-expose is absent from the result (its descendants' data traps at `cid`).
  exposedUpBy =
    result: cid:
    let
      childMerged = mergeMaps (map (exposedUpBy result) (childrenIds result cid));
    in
    prelude.genAttrs (exposeChannelsAt result cid) (
      ch: localContribs result cid ch ++ (childMerged.${ch} or [ ])
    );

  # The exposed pool a node RECEIVES (`allExposed.${nid}`) — the union over its DIRECT children of what
  # each pushes up. This is the `gathered` half the #62a seam appends after the node's own emissions.
  gatheredAt = result: nid: mergeMaps (map (exposedUpBy result) (childrenIds result nid));
in
{
  inherit gatheredAt;

  # The `den.channelGather` supplier: at any node, its received expose pool `{ <channel> = [ contribution ]; }`.
  # Empty (`{ }`) for a node with no exposing descendants ⇒ the #62a augmentation is the identity there.
  gather = { id, result }: gatheredAt result id;
}
