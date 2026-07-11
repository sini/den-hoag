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
  # The consumer's nixpkgs lib (§2.10 `den.nixpkgs.lib`), inert config DATA threaded from the fleet
  # boundary — null for the pure/nixpkgs-free path (den-hoag's own CI). Injected ONLY into a pipeline-
  # parametric emit that DEMANDS a `lib` arg (see resolveParametric); a null lib leaves such an emit to
  # ride unresolved (the named lib ceiling below). Import-purity holds: lib enters as an opaque value a
  # caller supplies, never imported here (mirrors `den.nixpkgs` threading, lib/default.nix nixpkgsDecl).
  consumerLib ? null,
}:
let
  # A config-demanding aspect channel value (a `{ config, ... }: …` thunk) is the deferred (per-member)
  # contribution. Under the §27 raw channel key it rides as a BARE function (functionArgs directly); the
  # older gen-aspects freeform path wrapped it as a functor carrying `__functionArgs` — both forms are
  # detected here. Plain data (lists/attrsets with no config demand) is class-invariant and rides as-is.
  configArgNames = [
    "config"
    "osConfig"
  ];
  demandsConfigArg = args: builtins.any (a: builtins.elem a configArgNames) (builtins.attrNames args);
  isConfigThunk =
    v:
    (builtins.isFunction v && demandsConfigArg (builtins.functionArgs v))
    || (builtins.isAttrs v && (v.__isWrappedFn or false) && demandsConfigArg (v.__functionArgs or { }));

  # A PIPELINE-PARAMETRIC channel emission is a function over the node's BINDING SURFACE (host/user/env
  # /…, NOT config/osConfig) — e.g. `k3s-nodes = { host, environment, ... }: {…}`. It is the EAGER dual
  # of the config-thunk deferral (§27): a config-thunk defers to the producing class+scope's config, a
  # parametric emit resolves AT THE EMITTING NODE against that node's own context (resolveParametric,
  # attribute 10). Both function forms isConfigThunk recognizes are covered (bare fn + the older gen-
  # aspects `__isWrappedFn` functor), symmetric with it — though a channel emit rides the §27 `raw`
  # option as a BARE fn (the wrapFn functor wraps INCLUDES, never channel CONTENT), so the wrapped arm is
  # defensive parity, never corpus-exercised. v1 twin: nix/lib/aspects/fx/assemble-pipes.nix:52-90
  # (`isPipelineParametric` / `resolveLocalParametric`); den-hoag's `configArgNames` = v1's `readsParentArg`.
  fnArgsOf = v: if builtins.isFunction v then builtins.functionArgs v else (v.__functionArgs or { });
  applyFnLike = v: args: if builtins.isFunction v then v args else v.__fn args;
  isFnLike = v: builtins.isFunction v || (builtins.isAttrs v && (v.__isWrappedFn or false));
  isPipelineParametric = v: isFnLike v && !(isConfigThunk v);

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
  #
  #     PIPELINE-PARAMETRIC RESOLUTION (§27 eager dual). A channel emission that is a FUNCTION over the
  #     node's binding surface (host/user/env, not config) resolves AT THE EMITTING NODE against its
  #     enriched-context (`resolveParametric`) — the eager dual of the config-thunk deferral. A list
  #     result SPLITS into several contributions (one producer, ascending `emissionIndex`, the A12 order
  #     preserved). When the node's context cannot satisfy a required (non-defaulted) arg the raw
  #     function RIDES UNRESOLVED — the consumer supplies the missing arg (v1's documented ceiling, not
  #     a throw). v1 twin: assemble-pipes.nix:52-90.
  local-collection-data = resolve.attr {
    name = "local-collection-data";
    kind = "synthesized";
    stratum = "collection";
    readsAttrs = [
      "resolved-aspects"
      "enriched-context"
    ];
    compute =
      self: id:
      let
        node = self.node id;
        cls = classOfNode node; # class entry | null
        ownEntry = node.decls.__entry or null;
        coords = coordDims node;
        positionClasses = if cls == null then [ ] else [ cls ];

        # The node's enriched-context — the SAME per-node binding surface the terminal reads (output-
        # modules `bindingsAt` = enriched-context // channels), so a parametric emit resolves against
        # exactly what its class-module consumers will be handed (decision §2).
        ctx = self.get id "enriched-context";

        # Resolve a pipeline-parametric emission eagerly against `ctx`, returning a LIST of resolved
        # values (v1 auto-flatten: a list result yields several contributions — the §5 SPLIT below). A
        # non-parametric value (plain data OR a config-thunk) resolves to the singleton `[ v ]`, so its
        # downstream handling is byte-identical to the pre-slice one-emission path. A required arg (non-
        # defaulted) absent from `ctx` makes the raw function RIDE UNRESOLVED — the consumer supplies the
        # missing arg (v1's documented ceiling, NOT a throw). `lib` is a required arg like any other
        # UNLESS the consumer threaded `den.nixpkgs.lib` (`consumerLib`), in which case it is injected (v1
        # always injects den's lib; a nixpkgs-free fleet cannot, so a `lib`-demanding emit self-announces
        # at its consumer — the named lib ceiling). v1 twin: resolveLocalParametric, assemble-pipes.nix:69-90.
        resolveParametric =
          v:
          if !(isPipelineParametric v) then
            [ v ]
          else
            let
              thunkArgs = fnArgsOf v;
              injectLib = consumerLib != null;
              requiredArgs = builtins.filter (k: !(thunkArgs.${k} or false) && !(injectLib && k == "lib")) (
                builtins.attrNames thunkArgs
              );
            in
            if !(builtins.all (k: ctx ? ${k}) requiredArgs) then
              [ v ]
            else
              let
                ctxArgs = prelude.genAttrs (builtins.filter (k: ctx ? ${k}) (builtins.attrNames thunkArgs)) (
                  k: ctx.${k}
                );
                result = applyFnLike v (ctxArgs // (if injectLib then { lib = consumerLib; } else { }));
              in
              if builtins.isList result then result else [ result ];

        # One annotated contribution record per RESOLVED channel value at this node. A parametric emit
        # resolving to a list yields SEVERAL records — the A12 producer-identity SPLIT (§5): one producer
        # (same aspect id_hash, rank 0), ascending `emissionIndex`, so `sortByProducer` keeps the emit
        # order and `channelBindingsAt` reads a flat value list. A plain / config-thunk value yields
        # exactly one record, byte-identical to the pre-slice path.
        recordsOfAspect =
          a:
          prelude.concatMap (
            chName:
            let
              raw = a.content.${chName} or null;
            in
            if raw == null then
              [ ]
            else
              prelude.imap0 (
                emissionIndex: v:
                let
                  deferredV = isConfigThunk v;
                in
                # den-framed class-ambiguity: a class-shaped (config-demanding) value at a null-class
                # scope names the aspect, channel, and scope — the producing scope binds no class to
                # resolve its `config` against (surfaces gen-pipe E1 with den names). A parametric emit is
                # config-INDEPENDENT (class-neutral, T3), so this fires only on a genuine config-thunk.
                if cls == null && deferredV then
                  errors.classAmbiguity {
                    aspect = a.content;
                    channel = chName;
                    scope = coords;
                  }
                else
                  {
                    inherit chName emissionIndex; # ascending within a producer ⇒ the intra-producer A12 order
                    rank = 0; # aspect producer (policy = 1, arriving with fleet-wide pipe ops)
                    identity = a.content.id_hash; # aspect identity (id_hash) — the A12 producer key (§A12)
                    contribution = pipe.contribute {
                      channel = quirkDag.channels.${chName};
                      # `pipe.deferred` takes the config-demanding function ITSELF, so gen-pipe reads its
                      # `argDemand` (functionArgs) to know which config args to supply and den-hoag's
                      # `deferredToThunk` can hand it straight to gen-bind's `__configThunk` (resolve at
                      # the producing class+scope). A resolved parametric value rides as plain data.
                      value = if deferredV then pipe.deferred v else v;
                      producer = {
                        entity = ownEntry;
                        scope = coords;
                        aspect = a.content;
                        classes = positionClasses;
                      };
                      class = cls; # T1 explicit class tag = the producing scope's class (null ⇒ neutral)
                    };
                  }
              ) (resolveParametric raw)
          ) channelNames;

        records = prelude.concatMap recordsOfAspect (self.get id "resolved-aspects");
        # group by channel, then apply the A12 producer-identity order within each channel.
        grouped = prelude.groupBy (r: r.chName) records;
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
