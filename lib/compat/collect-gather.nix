# The v1 `pipe.collect` / `pipe.collectAll` GATHER twins (#69 — approved slice U9.2, catalog v33), wired
# with the expose ascent (#62b) as ONE composed `den.channelGather` supplier (flake-module.nix). Fills the
# core per-node channel-augmentation seam (#62a) with den v1's cross-scope SIBLING/FLEET gathers, so a
# multi-node channel consumer (`k3s-nodes`/`host-addrs`/`bgp-peers`/… — the ledger u18 Family B census)
# binds every matching peer's contributions, not its own emissions alone.
#
# THE v1 SEMANTICS (pin 11866c16 nix/lib/aspects/fx/assemble-pipes.nix, F2: EXACT port — v33 ruling):
#   • collect — same-parent SIBLING gather: `findMatchingSiblings` (:318-353) filters the scopes sharing
#     `currentScopeId`'s parent (self-excluded), then per candidate: `hasRequired` (every non-defaulted
#     predicate formal present in the scope's ctx) ∧ `extraEntityKinds == [ ]` (the scope's OWN entity
#     kind — `scopeEntityKind.${sid}`, its creation kind, NOT the inherited ctx kinds — must be covered
#     by the predicate's entity-kind formals: what makes `{ host, … }: true` select host scopes ONLY and
#     reject a (user,host) cell whose ctx also carries `host`) ∧ the predicate itself.
#   • collectAll — the SAME predicate matching over ALL scopes regardless of parent (`findMatchingAll`
#     :355-382; the run arms :455-478).
#   • collected content — `collectTagged` (:437-450): per matched scope, its RAW channel contributions
#     PLUS what its children exposed up into it (`resolved ++ exposed` — BOTH arms share collectTagged,
#     so a peer's collect sees a host's exposed-up user data). Matched-scope order = `attrNames
#     scopeContexts` filtered — source-node-id LEXICOGRAPHIC, no dedup (v33/A12).
#   • the gathered values join the consumer AFTER its own base (`values ++ collectTagged …` over the
#     base fold) — the F4 augment (`local ++ gathered`), which is exactly the #62a seam's contract.
#
# den-hoag rendering: scopeContexts.${sid} = `enriched-context` (the ctx with entity coords);
# scopeParent.${sid} = `(result.node sid).parent`; scopeEntityKind.${sid} = `(result.node sid).type`
# (total — structural.nix: "every node carries a kind", so v1's null-fallback ctx-scan arm is
# unreachable here and carried only for verbatim fidelity); entityKinds = the fleet's registered kind
# set (the same set the wiring hands `hasAspect.mkEnrich` — v1's `schemaEntityKinds` is the
# isEntity-filtered subset, but every INSTANTIATED corpus kind is an entity kind, so the wider set is
# observationally equal on any materialized node; the shim's compiled schema carries no isEntity to
# filter by).
#
# VALUE RESOLUTION: a pipeline-parametric emit is already resolved at its emitting node (U9.1,
# attributes/collections.nix `resolveParametric`), so the gathered contributions cross CONCRETE — no
# re-resolution (the expose twin's posture). A DEFERRED (config-thunk) contribution on a COLLECTED
# channel is THE F6 CEILING (catalog v33, ruled): its producer is a DIFFERENT root, so resolving it at
# the consuming terminal would force the producer host's config from the consumer's eval — the
# cross-host config fixpoint v33 rules OUT. Corpus-zero → LOUD abort (errors.collectedConfigThunk),
# never a silent wrong value. (The EXPOSE twin moves deferred contributions fine — its producers live in
# the consuming root's OWN subtree.)
#
# DERIVING-STAGE CEILING (the expose twin's, shared): every corpus collect pipe is BARE
# (`pipe.from <ch> [ (pipe.collect pred) ]`, nix-config policies/pipes.nix) — no filter/transform/fold
# rides a collect pipe, so the gather moves raw contributions. MULTI-POLICY posture: marks are read
# per-channel off the node's collection declarations; two policies collecting one channel at one node
# gather once per MARK (v1 runs once per policy — same shapes on this corpus: no node carries two
# collect marks for one channel).
#
# NO EFFECT RUNTIME / A17: the gather walks the allNodes id spine + each candidate's enriched-context
# and (for matches) its cheap local-collection-data + expose pool — never a module body, never
# resolved-aspects. KIND-GENERIC: no kind/class literal — the entity-kind set is a PARAMETER; the only
# literals are the v1-spec mark tags (shim knowledge, permitted).
{ prelude }:
let
  exposeGather = import ./expose-gather.nix { inherit prelude; };
  errors = import ./errors.nix { inherit prelude; };

  collectionDeclsAt = result: nid: (result.get nid "declarations").actions.collection or [ ];

  # The collect/collectAll SITE MARKS at a node: `{ channel; all; predicate; }` per mark, read off the
  # compiled `pipeOp` declarations (lib/compat/pipe.nix stageOp "collect"/"collectAll" — the predicate
  # rides the mark).
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

  # F2 — v1's predicate matching, EXACT (findMatchingSiblings/findMatchingAll share it, :330-352).
  predicateMatches =
    entityKinds: result: predicate: sid:
    let
      ctx = result.get sid "enriched-context";
      predArgs = builtins.functionArgs predicate;
      requiredArgs = builtins.filter (k: !predArgs.${k}) (builtins.attrNames predArgs);
      predEntityArgs = builtins.filter (k: entityKinds ? ${k}) requiredArgs;
      hasRequired = builtins.all (k: ctx ? ${k}) requiredArgs;
      # v1 :341-347: the scope's OWN creation kind, not the inherited ctx kinds ("prevents parent
      # grouping entities from causing false rejections"). den-hoag `.type` is total; v1's null
      # fallback (ctx-scan) is carried verbatim for fidelity.
      ownKind = (result.node sid).type or null;
      scopeOwnEntityKinds =
        if ownKind != null then
          [ ownKind ]
        else
          builtins.filter (k: ctx ? ${k}) (builtins.attrNames entityKinds);
      extraEntityKinds = builtins.filter (k: !(builtins.elem k predEntityArgs)) scopeOwnEntityKinds;
    in
    hasRequired && extraEntityKinds == [ ] && predicate ctx;

  # collectTagged (:437-450): a matched scope contributes its RAW channel emissions PLUS its received
  # expose pool. A DEFERRED contribution aborts LOUD (the F6 ceiling — header).
  contributionsOf =
    result: consumer: channel: sid:
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
        (result.get sid "local-collection-data").${channel} or [ ]
        ++ ((exposeGather.gatheredAt result sid).${channel} or [ ])
      );

  # One mark's gather at node `nid`: the matched-scope set (siblings | all), source-node-id
  # lexicographic (attrNames order), each scope's contributions concatenated — no dedup (v33/A12).
  gatherMark =
    entityKinds: result: nid: mark:
    let
      allIds = builtins.attrNames result.allNodes;
      parentOf = sid: (result.node sid).parent;
      candidates =
        if mark.all then
          builtins.filter (sid: sid != nid) allIds
        else
          builtins.filter (sid: sid != nid && parentOf sid == parentOf nid) allIds;
      matched = builtins.filter (predicateMatches entityKinds result mark.predicate) candidates;
    in
    prelude.concatMap (contributionsOf result nid mark.channel) matched;

  # The collect half of the channel gather at a node: `{ <channel> = [ contribution ]; }` over its
  # collect/collectAll marks. Mark order preserved (a node with several marked channels gathers each).
  collectGatheredAt =
    entityKinds: result: nid:
    prelude.foldl' (
      acc: mark:
      acc // { ${mark.channel} = (acc.${mark.channel} or [ ]) ++ gatherMark entityKinds result nid mark; }
    ) { } (collectMarksAt result nid);

  # Per-channel concat of gather maps (the expose twin's mergeMaps — order: earlier map's entries lead).
  mergeMaps =
    maps:
    prelude.foldl' (
      acc: m:
      prelude.foldl' (a: ch: a // { ${ch} = (a.${ch} or [ ]) ++ m.${ch}; }) acc (builtins.attrNames m)
    ) { } maps;
in
{
  inherit collectGatheredAt;

  # The COMPOSED `den.channelGather` supplier (expose ascent #62b + collect/collectAll twins #69):
  # per channel, the received expose pool FIRST, the collected peers after — matching v1's consumption
  # order (mkCombinedBase = own ++ exposed :935-948, then the collect stages append :455-478; the #62a
  # seam prepends the node's own local emissions). `entityKinds` = the fleet's registered kind set
  # (the wiring's hasAspect.mkEnrich twin).
  mkGather =
    entityKinds:
    { id, result }:
    mergeMaps [
      (exposeGather.gatheredAt result id)
      (collectGatheredAt entityKinds result id)
    ];
}
