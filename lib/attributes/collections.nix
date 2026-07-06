# Collection stratum — HOAG attributes 10 and 11 as gen-resolve equations (r2 §2.5 / §B5). The quirks
# concern flows here: attribute 10 (`local-collection-data`) turns this scope's resolved aspects into
# class-tagged gen-pipe contributions, attribute 11 (`received-collections`) folds them along the
# pinned neron traversal via `gen-pipe.run`. Every body is WIRING plus exactly one lib call for any
# algorithm — `scope.collectionAttr` (the neron order), `pipe.contribute` (the tagged emission),
# `scopeAdapter.sortByProducer` (the A12 tie-break sort = one `prelude.sort`), `pipe.run` (the B5
# fold). The channel algebra itself is never re-implemented here (Law A1).
#
# NO EFFECT RUNTIME: an attribute value is inert data — a `{ <channel> = [ contribution ]; }` map (10)
# or gen-pipe's per-channel outputs (11), never a loop record. The only class-dependence is the
# emission tag; contributions of config-independent data are class-neutral by construction (gen-pipe
# T3), so `received-collections` folds them without any resolution environment.
#
# Deps: prelude (folds/filters), scope (collectionAttr neron), resolve (attr), pipe (contribute /
# deferred / run), scopeAdapter (traversal adapter + producer tie-break), errors (classAmbiguity).
# Instance args: quirkDag = the ONE fleet-level `gen-pipe.compose` (its `.channels` carry the validated
# discipline); classOfNode = the producing-scope → class-entry function (null for a class-neutral
# scope, e.g. env); channelNames = the declared quirk channel names (which aspect content keys emit).
{
  prelude,
  scope,
  resolve,
  pipe,
  scopeAdapter,
  errors,
}:
{
  quirkDag,
  classOfNode,
  channelNames,
}:
let
  # A config-demanding aspect channel value (a `{ config, ... }: …` thunk) reaches den as a gen-aspects
  # wrapped functor carrying `__functionArgs`; that is the deferred (per-member) contribution. Plain
  # data (lists/attrsets with no config demand) is class-invariant and rides as-is.
  configArgNames = [
    "config"
    "osConfig"
  ];
  isConfigThunk =
    v:
    builtins.isAttrs v
    && (v.__isWrappedFn or false)
    && builtins.any (a: builtins.elem a configArgNames) (builtins.attrNames (v.__functionArgs or { }));

  # The reserved decls keys are graph machinery, never producing-scope coordinates.
  coordDims =
    node:
    removeAttrs (node.decls or { }) [
      "__entry"
      "__edges"
      "__containment"
      "__coords"
    ];
in
{
  # neron-order — the pinned self → imports → parent node sequence at this position. The ordering
  # algorithm stays in gen-scope (`collectionAttr traverse = "neron"`); den only asks for the node-id
  # list (extract = the visited id). This IS the B5 traversal `gen-pipe.run` walks (attribute 11).
  "neron-order" = resolve.attr {
    name = "neron-order";
    kind = "synthesized";
    stratum = "collection";
    readsAttrs = [ "imports" ];
    compute = scope.collectionAttr {
      traverse = "neron";
      extract = _self: nid: [ nid ];
    };
  };

  # 10. local-collection-data — this scope's resolved aspects' channel contributions, class-tagged at
  #     emission (§2.5). For each resolved aspect and each of its content keys that is a registered
  #     channel, one `pipe.contribute`: the producing scope's class is the explicit tag (T1), so a
  #     host emission is tagged its host class and a user-cell emission `home-manager` — the same
  #     contribution at two inclusion scopes gets two distinct tags (the dual-inclusion answer). A
  #     null-class scope (env) emitting a config-demanding (class-shaped) value is a definition-time
  #     abort (den-framed `classAmbiguity`, the den surface of gen-pipe's E1). The per-position order
  #     is the A12 producer tie-break (`sortByProducer`).
  local-collection-data = resolve.attr {
    name = "local-collection-data";
    kind = "synthesized";
    stratum = "collection";
    readsAttrs = [ "resolved-aspects" ];
    compute =
      self: id:
      let
        node = self.node id;
        cls = classOfNode node; # class entry | null
        ownEntry = node.decls.__entry or null;
        coords = coordDims node;
        positionClasses = if cls == null then [ ] else [ cls ];

        # One annotated contribution record per (aspect, channel-key) emission at this node.
        recordsOfAspect =
          a:
          prelude.concatMap (
            chName:
            let
              v = a.content.${chName} or null;
              deferredV = isConfigThunk v;
            in
            if v == null then
              [ ]
            # den-framed class-ambiguity: a class-shaped (config-demanding) emission at a null-class
            # scope names the aspect, channel, and scope — the producing scope binds no class to
            # resolve its `config` against (surfaces gen-pipe E1 with den names).
            else if cls == null && deferredV then
              errors.classAmbiguity {
                aspect = a.content;
                channel = chName;
                scope = coords;
              }
            else
              [
                {
                  inherit chName;
                  rank = 0; # aspect producer (policy = 1, arriving with fleet-wide pipe ops)
                  identity = a.content.id_hash; # aspect identity (id_hash) — the A12 producer key (§A12)
                  emissionIndex = 0; # one value per channel key ⇒ no intra-producer ordering here
                  contribution = pipe.contribute {
                    channel = quirkDag.channels.${chName};
                    value = if deferredV then pipe.deferred { fn = env: v env; } else v;
                    producer = {
                      entity = ownEntry;
                      scope = coords;
                      aspect = a.content;
                      classes = positionClasses;
                    };
                    class = cls; # T1 explicit class tag = the producing scope's class (null ⇒ neutral)
                  };
                }
              ]
          ) channelNames;

        records = prelude.concatMap recordsOfAspect (self.get id "resolved-aspects");
        # group by channel, then apply the A12 producer-identity order within each channel. The inline
        # group-by fold mirrors lib/fleet.nix's; both collapse onto `gen-prelude.groupBy` once it lands
        # upstream (tracked follow-up, task #23 — add groupBy to gen-prelude, swap the den-hoag copies).
        grouped = prelude.foldl' (
          acc: r: acc // { ${r.chName} = (acc.${r.chName} or [ ]) ++ [ r ]; }
        ) { } records;
      in
      builtins.mapAttrs (_: recs: scopeAdapter.sortByProducer recs) grouped;
  };

  # 11. received-collections — the channel values visible from this position, via `gen-pipe.run` over
  #     the neron traversal adapter (the B5 enforcement point: pinned self → imports → parent order,
  #     associative-only combine, per-channel declared dedup — never silent). The value is gen-pipe's
  #     per-channel output record ({ contributions; values; trace; classInvariant; }) at this node.
  received-collections = resolve.attr {
    name = "received-collections";
    kind = "synthesized";
    stratum = "collection";
    readsAttrs = [
      "neron-order"
      "local-collection-data"
    ];
    compute =
      self: id:
      let
        out = pipe.run {
          dag = quirkDag;
          traversal = scopeAdapter.traversalAdapter {
            result = self;
            localDataOf = pos: chName: (self.get pos "local-collection-data").${chName} or [ ];
            classesOfNode =
              node:
              let
                c = classOfNode node;
              in
              if c == null then [ ] else [ c ];
          };
        };
      in
      out.at id;
  };
}
