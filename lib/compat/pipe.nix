# den-compat pipe vocabulary compilation (§2.4, Law C2 — pure). Two surfaces:
#
#   1. `den.quirks.<name>` → a den-hoag channel registration `{ channel; ops; adapters; }` (`channelOf`):
#      the v1 quirk's gen-pipe channel options ride into `channel`; concern-quirks turns the record into
#      the ONE fleet gen-pipe channel. A den v1 quirk is mostly a `{ description = …; }` marker, so the
#      default is an ordered-list channel; a quirk carrying merge/dedup/type/… channel options passes them
#      through (its non-channel keys — `description`, … — are dropped: `pipe.channel` rejects unknown keys).
#
#   2. the v1 `pipe.from name [stages]` policy effect → a den-hoag collection-stratum `pipeOp` declaration
#      (`compilePipe`): the deriving stages (filter/transform/fold/for) fold LEFT-TO-RIGHT into a gen-pipe
#      operator DAG rooted at the named channel (`stageOp`); the delivery (to/as) and site (append/expose/
#      broadcast/collect/collectAll/withProvenance) stages ride as inert markers the emission/consumption
#      site interprets. NOTHING is forced (Law C2, NO EFFECT RUNTIME): the op DAG is BUILT from the stage
#      closures without ever APPLYING them.
#
# DEFERRED-VALUE DISCIPLINE (parity-watch items 5, 6). A config-demanding channel value (`{ config, … }:
# …` / `{ osConfig, … }: …`) is den-hoag's deferred contribution (`attributes/collections.nix`
# `isConfigThunk`): it rides the channel RAW and is resolved ONLY at the terminal, where `deferredToThunk`
# hands it to gen-bind's `__configThunk` (resolve-at-producing-scope, decision #27). The compat obligation
# is (5) to leave that value a bare config-demanding FUNCTION so gen-bind keeps the consuming class
# module's config arg UNBOUND (gen-bind `wrap.nix` `allMatched` — a fully-bound consumer would skip thunk
# resolution) and (6) to never compile a v1 pipe into an operator that FORCES the value mid-fold (a
# value-demanding fold/scan over a deferred value is gen-pipe E6 poison). Both fall out of pure desugar:
# `compile.nix` `translateAspect` passes a quirk-key value through untouched, and `compilePipe` builds
# inert op records here — the deferred marker crosses the compiled v1 pipe intact.
{ prelude, errors }:
let
  # v1 `__pipeStage` field names (den v1 `nix/lib/policy-effects.nix` `pipe`): filter/transform/for/
  # broadcast/collect/collectAll carry `fn`; fold carries `fn` + `init`; append `value`; to `aspects`;
  # as `targetPipeName`. The kind classes drive `compilePipe`'s fold / collect / carry split.
  derivingKinds = [
    "filter"
    "transform"
    "fold"
    "for"
  ];
  deliveryKinds = [
    "to"
    "as"
  ];
  siteKinds = [
    "append"
    "expose"
    "broadcast"
    "collect"
    "collectAll"
    "withProvenance"
  ];

  passAll = _: true;

  # A base-channel REFERENCE by id. gen-pipe's deriving-op constructor reads only `.id` of its input, so a
  # reference stub is a pure, inert seed — the real channel record lives in `channels.<name>` (registered
  # from `den.quirks`); compose resolves the derived DAG's inputs against it by id. Building the DAG over
  # this stub forces no stage closure (Law C2).
  channelRef = name: {
    __genPipeChannel = true;
    __derived = false;
    id = name;
    inherit name;
  };

  # A single v1 pipe stage → its compiled den-hoag form, tagged by ROLE so `compilePipe` can fold the
  # deriving ops, collect the delivery intents, and carry the site markers. Total over §2.4 — an unknown
  # stage is a named definition-time error, never a silent no-op.
  #
  # deriving → a gen-pipe channel transformer (`ch -> derived channel`): filter→filter, transform→map,
  #   fold→fold (associative-only, B5). for→map — v1 `for` is a whole-list rewrite; gen-pipe `map` is the
  #   per-element list operator, so both are the channel's `map` node, distinguished by the inert
  #   `__derive.wholeList` marker `for` carries (see the `for` branch — it preserves what the run wiring
  #   needs to apply whole-list vs per-element; a byte-identical record would lose it).
  # delivery → an INTENT `{kind,select,target}`; `compilePipe` roots the actual gen-pipe `route` at the
  #   derived terminal: as→a channel→channel route to the target channel; to→kept inert on `targeted` (an
  #   aspect is not a gen-pipe channel — the consumer-addressed binding is a separate kernel seam).
  # site → an inert marker the emission/consumption site interprets: append→a contribution at the policy's
  #   scope, expose→ascend to parent, broadcast→#623 push-dual (contributions class-tagged at the producing
  #   class+scope), collect/collectAll→predicate gather (collectAll = raw + exposed), withProvenance→a
  #   provenance-view no-op.
  stageOp =
    declare: stage:
    let
      k = stage.__pipeStage or null;
    in
    if k == "filter" then
      # predicate keep (den v1 `policy-effects.nix:304` builds `{ __pipeStage="filter"; fn; }`; run at
      # `assemble-pipes.nix:281-282` — `builtins.filter (v: passthrough v || stage.fn (unwrap v))`, so a
      # deferred `__configThunk` value passes through unfiltered, item 6). gen-pipe `filter` is the twin.
      {
        role = "derive";
        op = "filter";
        apply = declare.pipe.filter stage.fn;
      }
    else if k == "transform" then
      # per-ELEMENT map (den v1 `assemble-pipes.nix:283-284`: `map (v: … stage.fn (unwrap v)) values`).
      # No `__derive.wholeList` marker ⇒ den-hoag's run wiring treats it as the per-element `map` op
      # (the discriminator against `for` below, which shares this `op = "map"` node).
      {
        role = "derive";
        op = "map";
        apply = declare.pipe.map stage.fn;
      }
    else if k == "fold" then
      # left fold to a single value (den v1 `policy-effects.nix:312` builds `{ fn; init; }`; run at
      # `assemble-pipes.nix:285-286` — `[ (seed (builtins.foldl' (acc: v: stage.fn acc (unwrap v))
      # stage.init values)) ]`). gen-pipe `fold` is the twin; its combine is B5 ASSOCIATIVE-ONLY (gen-pipe
      # channel L1), so a v1 fold whose `fn` is order-dependent is a run-semantics divergence the parity
      # harness surfaces — the compile is faithful, the associativity obligation rides to the run.
      {
        role = "derive";
        op = "fold";
        apply = declare.pipe.fold {
          f = stage.fn;
          inherit (stage) init;
        };
      }
    else if k == "for" then
      # v1 `for` applies fn to the WHOLE LIST (den v1 `assemble-pipes.nix:289-290`:
      # `map seed (stage.fn (map unwrap values))`), whereas gen-pipe `map` is per-ELEMENT (gen-pipe
      # `evaluate.nix:247`: `map (mapC d.f ch.name) …`). Both are the channel's `map` NODE, so the two
      # compiled records would be byte-identical and the whole-list run semantics unrecoverable. The
      # distinction is PRESERVED as an inert `__derive.wholeList` marker (gen-pipe reads `__derive`
      # non-strictly — `deriveSeq` touches only `.op`/`.inputs`/`.f`, so the extra key is ignored by the
      # channel algebra). den-hoag's run wiring (task #44) reads it: whole-list application when `true`,
      # per-element `map` when `false`/absent (transform). No value is forced — the merge keeps `f` a thunk.
      {
        role = "derive";
        op = "map";
        apply =
          ch:
          let
            d = declare.pipe.map stage.fn ch;
          in
          d
          // {
            __derive = d.__derive // {
              wholeList = true;
            };
          };
      }
    else if k == "to" then
      # deliver the pipe value to named ASPECTS (den v1 `policy-effects.nix:327`; `hasToStage`/
      # `getToTargets` at `assemble-pipes.nix:490,494-499`, applied at `:634`). An aspect is NOT a gen-pipe
      # channel, and v1's `__pipeTargeted = { aspectName → values }` is an aspect-INDEXED override read at
      # the consuming WRAP grain — not a producer-side `route{select}` (gen-pipe `matchView` matches a
      # contribution's view, not a delivery TARGET set). So `to` cannot be a channel `route`: it is carried
      # as an inert DELIVER intent (`kind = "to"`, targets in `select`) that `compilePipe` stashes on the
      # `targeted` field for a FUTURE consumption-side aspect-carrier wiring (a separate WS-B kernel seam).
      {
        role = "deliver";
        kind = "to";
        select = stage.aspects;
      }
    else if k == "as" then
      # expose the pipe value under another pipe NAME (den v1 `policy-effects.nix:331`; `hasAsStage`/
      # `getAsTarget` at `assemble-pipes.nix:502,505-510`, applied at `:962`) — a genuine channel→channel
      # move: every contribution of THIS pipe's derived terminal is delivered to the target channel
      # (`select = passAll`). Carried as a DELIVER intent; `compilePipe` builds the gen-pipe `route` record
      # (rooted at the derived terminal, so a preceding transform/filter/fold is applied before delivery).
      {
        role = "deliver";
        kind = "as";
        select = passAll;
        target = stage.targetPipeName;
      }
    else if k == "append" then
      # append a literal value at the policy's scope (den v1 `policy-effects.nix:316`; run at
      # `assemble-pipes.nix:287-288` — `values ++ [ (seed stage.value) ]`, re-tagged to the current scope).
      {
        role = "site";
        mark = {
          __pipeMark = "append";
          inherit (stage) value;
        };
      }
    else if k == "expose" then
      # ascend: push this scope's values UP to the parent for a peer to gather (den v1
      # `policy-effects.nix:335`; `hasExposeStage` at `assemble-pipes.nix:666`, read by `collectAllExposed`
      # at `:701`). The marker carries no payload — the ascend is the whole directive.
      {
        role = "site";
        mark = {
          __pipeMark = "expose";
        };
      }
    else if k == "broadcast" then
      # #623 push-dual of expose: push values to the scopes matching `receiver`, class-tagged at the
      # PRODUCING class+scope (den v1 `policy-effects.nix:338`; `hasBroadcastStage` at
      # `assemble-pipes.nix:669`, resolved by `collectAllBroadcast` at `:794`). `fn` is the receiver predicate.
      {
        role = "site";
        mark = {
          __pipeMark = "broadcast";
          receiver = stage.fn;
        };
      }
    else if k == "collect" then
      # gather peers' values into this scope — RAW contributions only (den v1 `policy-effects.nix:342`;
      # run at `assemble-pipes.nix:457-467` via `collectTagged`, tagging each by its source scope).
      {
        role = "site";
        mark = {
          __pipeMark = "collect";
          predicate = stage.fn;
          exposed = false;
        };
      }
    else if k == "collectAll" then
      # gather RAW + EXPOSED (#623: what peers pushed up via `expose`) — den v1 `policy-effects.nix:346`;
      # run at `assemble-pipes.nix:469-478`. `exposed = true` is the only field distinguishing it from
      # `collect` (den v1's collect-vs-collectAll raw/exposed asymmetry, `assemble-pipes.nix:792`).
      {
        role = "site";
        mark = {
          __pipeMark = "collectAll";
          predicate = stage.fn;
          exposed = true;
        };
      }
    else if k == "withProvenance" then
      # provenance-view no-op: switches the run to the `pvFunctor` so values carry `{ __pv; __ps }` source
      # tags (den v1 `policy-effects.nix:324`; `hasProvenance` at `assemble-pipes.nix:408`, `pvFunctor` at
      # `:257-265`, handled at `:480-486`). No transform — a marker the run reads, inert at compile.
      {
        role = "site";
        mark = {
          __pipeMark = "withProvenance";
        };
      }
    else
      errors.unknownPipeStage (if k == null then "<missing __pipeStage>" else k);

  # The gen-pipe channel options a v1 quirk may carry (the rest — `description`, … — are dropped; class
  # adapters ride the separate `adapters` field, wired by concern-quirks' `channelDeclOf`).
  channelOptKeys = {
    type = null;
    merge = null;
    combine = null;
    init = null;
    dedup = null;
  };
in
{
  inherit
    stageOp
    derivingKinds
    deliveryKinds
    siteKinds
    ;

  # A v1 `den.quirks.<name>` value → a den-hoag channel registration `{ channel; ops; adapters; }`
  # (concern-quirks' input shape). Only the recognised gen-pipe channel options cross into `channel`;
  # any `ops`/`adapters` the quirk declares pass through. `name` is added by concern-quirks' channelDeclOf.
  # A bare marker quirk yields an EMPTY `channel` — gen-pipe's `channel` fills the ordered-list defaults
  # (`merge = "ordered-list"`, list-concat combine, `[ ]` init), so a plain `{ description = …; }` quirk
  # becomes the default ordered-list channel with no options to state.
  channelOf = q: {
    channel = builtins.intersectAttrs channelOptKeys q;
    ops = q.ops or [ ];
    adapters = q.adapters or [ ];
  };

  # Compile a v1 `pipe.from name [stages]` effect value → a collection-stratum `pipeOp` declaration on the
  # named channel: the deriving op DAG (rooted at `name`), the delivery routes, and the site markers — all
  # inert (Law C2, NO EFFECT RUNTIME). den-hoag's collection stratum consumes it at channel wiring.
  compilePipe =
    declare: value:
    let
      pipeName = value.pipeName;
      compiled = map (stageOp declare) (value.stages or [ ]);
      byRole = role: builtins.filter (c: c.role == role) compiled;
      # left-to-right operator composition onto the base channel (§2.4 "select channel + left-to-right op
      # composition"): each deriving stage's transformer is applied to the running channel, in order.
      # `dag` is the DERIVED TERMINAL: the base ref when the pipe has no deriving stages, else the final
      # deriving node. Every delivery route roots HERE (not at the base pipe name), so a route delivers the
      # value AFTER all deriving stages — v1's `stripAsStage` + `applyEffectStages` (assemble-pipes.nix
      # :994-1012) apply the transform chain, then deliver the result.
      dag = prelude.foldl' (ch: c: c.apply ch) (channelRef pipeName) (byRole "derive");
      delivers = byRole "deliver";
      # `as` → a gen-pipe channel→channel `route` rooted at the derived terminal, delivering to the target
      # channel (a registered quirk). `channelRef` stubs both ends by id — compose resolves them against the
      # one fleet declaration set (the terminal is declared via `pipeChainOf`, the target via its quirk).
      asRoutes = map (
        c:
        declare.pipe.route {
          from = dag;
          inherit (c) select;
          to = channelRef c.target;
        }
      ) (builtins.filter (c: c.kind == "as") delivers);
    in
    declare.pipeOp {
      channel = pipeName;
      derived = dag;
      routes = asRoutes;
      # `to` aspect-delivery intents — inert, NOT folded into the compose (an aspect is not a channel; see
      # the `to` branch of `stageOp`). Recorded verbatim for the future consumption-side aspect-carrier
      # wiring; carrying `from = dag` so that wiring reads the post-derive terminal, matching `as`.
      targeted = map (c: {
        inherit (c) select;
        from = dag;
      }) (builtins.filter (c: c.kind == "to") delivers);
      marks = map (c: c.mark) (byRole "site");
    };
}
