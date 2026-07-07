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
  # deriving ops, collect the delivery routes, and carry the site markers. `from` is the pipe's base
  # channel name (a delivery route needs it as its source). Total over §2.4 — an unknown stage is a
  # named definition-time error, never a silent no-op.
  #
  # deriving → a gen-pipe channel transformer (`ch -> derived channel`): filter→filter, transform→map,
  #   fold→fold (associative-only, B5). for→map — v1 `for` is a whole-list rewrite; gen-pipe `map` is the
  #   per-element list operator, so both are the channel's `map` node, distinguished by the inert
  #   `__derive.wholeList` marker `for` carries (see the `for` branch — it preserves what the run wiring
  #   needs to apply whole-list vs per-element; a byte-identical record would lose it).
  # delivery → a gen-pipe `route` op rooted at `from`: to→a select-route carrying the target aspects
  #   (the value stays on its own channel for them to read); as→a channel→channel route to the named pipe.
  # site → an inert marker the emission/consumption site interprets: append→a contribution at the policy's
  #   scope, expose→ascend to parent, broadcast→#623 push-dual (contributions class-tagged at the producing
  #   class+scope), collect/collectAll→predicate gather (collectAll = raw + exposed), withProvenance→a
  #   provenance-view no-op.
  stageOp =
    declare: from: stage:
    let
      k = stage.__pipeStage or null;
    in
    if k == "filter" then
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
      {
        role = "deliver";
        op = declare.pipe.route {
          inherit from;
          select = stage.aspects;
          to = from;
        };
      }
    else if k == "as" then
      {
        role = "deliver";
        op = declare.pipe.route {
          inherit from;
          select = passAll;
          to = stage.targetPipeName;
        };
      }
    else if k == "append" then
      {
        role = "site";
        mark = {
          __pipeMark = "append";
          inherit (stage) value;
        };
      }
    else if k == "expose" then
      {
        role = "site";
        mark = {
          __pipeMark = "expose";
        };
      }
    else if k == "broadcast" then
      {
        role = "site";
        mark = {
          __pipeMark = "broadcast";
          receiver = stage.fn;
        };
      }
    else if k == "collect" then
      {
        role = "site";
        mark = {
          __pipeMark = "collect";
          predicate = stage.fn;
          exposed = false;
        };
      }
    else if k == "collectAll" then
      {
        role = "site";
        mark = {
          __pipeMark = "collectAll";
          predicate = stage.fn;
          exposed = true;
        };
      }
    else if k == "withProvenance" then
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
      compiled = map (stageOp declare pipeName) (value.stages or [ ]);
      byRole = role: builtins.filter (c: c.role == role) compiled;
      # left-to-right operator composition onto the base channel (§2.4 "select channel + left-to-right op
      # composition"): each deriving stage's transformer is applied to the running channel, in order.
      dag = prelude.foldl' (ch: c: c.apply ch) (channelRef pipeName) (byRole "derive");
    in
    declare.pipeOp {
      channel = pipeName;
      derived = dag;
      routes = map (c: c.op) (byRole "deliver");
      marks = map (c: c.mark) (byRole "site");
    };
}
