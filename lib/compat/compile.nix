# den-compat compile core (Law C2 — pure compilation). `compile : v1Decls → den-hoag concern
# DECLARATIONS`: no evaluation machinery, no scope-graph reads, no resolved-state reads, and no edges
# constructed on this path (a `deliver` desugars to a delivery DECLARATION — the firing scope is
# unknowable at compile time). Every algorithm (fold, toposort, traversal, channel run, selector
# match) lives in den-hoag or an L1/L2 lib; this file only rewrites vocabulary.
#
# C1 fills four of the five keys — `entities`/`aspects`/`policies`/`classes` — from the non-legacy,
# non-pipe, non-deliver surface (the structural + resolution vocabulary). `channels` is the pipe stage
# vocabulary (Task 3); the delivery-edge vocabulary (`deliver`/`route`/`provide`) is Task 2. Ingestion
# (the C6 identity boundary) is `ingest.nix`; this file consumes its entry-valued output.
{
  prelude,
  ingest,
  declare,
  errors,
  sentinels,
}:
let
  # The §2.4 pipe stage vocabulary: `den.quirks.<name>` → a channel registration (`channelOf`) and the
  # `pipe.from name [stages]` policy effect → a collection-stratum `pipeOp` declaration (`compilePipe`).
  pipeLib = import ./pipe.nix { inherit prelude errors; };

  # A delivery DESCRIPTOR (`deliver`/`route`/`provide`, deliver.nix) → a den-hoag `delivery` DECLARATION
  # (resolution stratum): the delivery INTENT — resolved class registrations + placement + the
  # trace-facing annotation booleans. The gen-edge record is rendered from this intent at the FIRING
  # NODE by output-modules' `edgesAt` (which owns the firing scope + collected membership); no gen-edge
  # record is built on the compile path (C2 — compile returns policy thunks; den-hoag dispatches them).
  #
  # SOURCE ARM (v1-faithful): a class source → `collected` of the `from` class (edges/route.nix); a
  # MODULE source (provide) → `collected` of the TARGET class (edges/provides.nix:121-122 — the provided
  # module rides the target scope's OWN bucket and is carried by the default fold, hence `mergeHalf =
  # "default-fold"`). NEVER `synthesize` (that is only v1's __complexForward adapter arm, Task 5) and
  # NEVER `value` (v1's frozen sourceKey has no value arm — a value edge could never byte-match, P1).
  # Class-name strings resolve to registrations HERE (C6, unknown → named abort); names never survive on.
  # A NULL-TARGET delivery is a DEFINED NO-OP (materializes to no edge). v1's built-in os/user routes gate
  # on `host ? class` — a synthetic `user@host` home (no OS class) leaves the route INERT — so a route
  # whose `intoClass` resolves to null (an absent/null host class) must stay inert, NOT misroute to a
  # default. The null case is emitted (probe-safe: still a resolution-stratum declaration, so a
  # value-conditional route classifies as resolution, not enrich) but flagged `__dropped`; output-modules
  # `deliveryEdgesAt` skips it. A dummy sentinel entry satisfies `declare.delivery`'s A2 requireEntry
  # without a registry lookup (the edge is never rendered, so its class name is irrelevant).
  droppedTargetSentinel = {
    id_hash = "«dropped-delivery-target»";
    name = "«dropped»";
  };
  translateDelivery =
    ing: d:
    let
      isModule = d.sourceClass == null;
      dropped = d.target == null;
      # `resolveBucket`: from/to name a den-hoag fold bucket (a quirk channel) or a class (§9). A channel
      # delivery flows through the fold now; a class delivery's bucket is empty until class content joins.
      toEntry = if dropped then droppedTargetSentinel else ing.resolveBucket "deliver" d.target;
      annotations =
        prelude.optionalAttrs (d.adaptArgs != null) { adaptArgs = true; }
        // prelude.optionalAttrs (d.guard != null) { guard = true; }
        // prelude.optionalAttrs isModule { mergeHalf = "default-fold"; };
    in
    declare.delivery {
      # A module source collects the TARGET class (v1 provide, provides.nix:121) — so for a module
      # source, sourceClass deliberately CARRIES THE TARGET REGISTRATION (sourceClass == targetClass;
      # deliveryEdgesAt disambiguates on `module != null`, not on the class pair). A class source
      # collects `from`. A dropped delivery renders nothing, so its source is the sentinel too.
      sourceClass =
        if dropped then
          droppedTargetSentinel
        else if isModule then
          toEntry
        else
          ing.resolveBucket "deliver" d.sourceClass;
      targetClass = toEntry;
      module = d.moduleSource;
      inherit (d)
        path
        mode
        guard
        adaptArgs
        ;
      inherit annotations;
      __dropped = dropped;
    };

  # v1 class-key names that differ from den-hoag's (§ grounded terminology): a v1 aspect's class key is
  # renamed to the den-hoag class it targets before passing through, so `classifyKey` recognises it.
  # Identity for every already-grounded name; extended as the corpus surfaces more (harness-driven).
  v1ClassKeyMap = {
    homeManager = "home-manager";
  };

  # v1 aspect STRUCTURAL keys that do NOT pass through as den-hoag aspect content: `provides` rides the
  # legacy module (Task 4), `policies`/`excludes` are re-expressed here, `__*` are v1 pipeline internals.
  droppedAspectKeys = [
    "provides"
    "policies"
    "excludes"
    "classes"
    "_"
  ];

  # Resolve a v1 aspect REFERENCE to the den-hoag aspect record den-hoag's resolution consumes. Accepts
  # an already-resolved record (pass through), a `{ name; … }` record, or a bare name string. `aspectRec`
  # (threaded from the inner block) maps a name to the FULL compiled aspect record — content + id_hash +
  # name — NOT a bare `{ id_hash; name }` stub: `resolved-aspects.nix` `policyEdgeAspects` uses the
  # edge's aspect record DIRECTLY as content (it never re-looks-up a registry), so a stub would resolve
  # to an EMPTY aspect and a compat-included aspect would contribute no class/channel content (the C1
  # gap the delivery content path exposed). The full record's `name` gives `gen-aspects.key` the same
  # key a `neededBy` inclusion produces (dedup-coherent), and `id_hash` satisfies `declare.edge`'s A2.
  resolveAspectRef =
    aspectRec: ref:
    if builtins.isAttrs ref && ref ? id_hash then
      ref
    else if builtins.isAttrs ref && ref ? name then
      aspectRec ref.name
    else if builtins.isString ref then
      aspectRec ref
    else
      errors.identityLaw "policy aspect reference" ref;

  # NOT-IMPLEMENTED-BY-CENSUS (C1 surface totality): an aspect carrying `meta.__forward` is a
  # `den.batteries.forward` manifestation (v1 forward.nix `forwardItem`). The shim has no desugar for it
  # (Tier-2 derived-children NTA, corpus-zero census — PIN.md Open-Question-2). Rather than pass the
  # opaque `meta.__forward` payload through as aspect content (silently wrong), abort named with a
  # migration pointer. `true` when clean, composing under `builtins.seq`.
  noBatteriesForward =
    name: aspect:
    if builtins.isAttrs aspect && ((aspect.meta or { }).__forward or null) != null then
      errors.batteriesForwardUnsupported name
    else
      true;

  # Near-identity aspect translation (§2.2 aspect row). den-hoag's aspect submodule already accepts the
  # v1 shape — `includes`/`neededBy`/`settings`/`meta.{guard,drop}`/`projects`/`tags` and freeform
  # class/quirk keys ride THROUGH untouched (a quirk key becomes a channel contribution at the aspect's
  # producing class+scope, so PR #623 falls out). The only rewrites: a bare parametric FUNCTION coerces
  # to `{ includes = [ fn ]; }` (v1's own coercion), `excludes` folds into `meta.drop`, class keys are
  # grounded, and the v1-only structural keys are dropped.
  translateAspect =
    name: aspect:
    # LEGACY SURFACE SENTINEL (C5): `provides` must have been desugared by legacy/provides.nix (applied
    # by the flakeModule assembly BEFORE compile). If it survives to here the legacy module is severed —
    # fail LOUDLY naming the surface rather than dropping the declaration (sentinels.nix / errors.nix).
    # SURFACE TOTALITY (C1): `meta.__forward` (the batteries.forward manifestation) has no desugar path —
    # a named abort, not a silent passthrough (noBatteriesForward).
    builtins.seq (sentinels.provides name aspect) (
      builtins.seq (noBatteriesForward name aspect) (
        if builtins.isFunction aspect then
          { includes = [ aspect ]; }
        else
          let
            excludes = aspect.excludes or [ ];
            withoutDropped = builtins.removeAttrs aspect droppedAspectKeys;
            grounded = prelude.foldl' (
              acc: k:
              let
                k' = v1ClassKeyMap.${k} or k;
              in
              builtins.removeAttrs acc [ k ] // { ${k'} = aspect.${k}; }
            ) withoutDropped (builtins.attrNames withoutDropped);
            # Fold `excludes` into `meta.drop` (aspect-level constraint) without clobbering a declared drop.
            meta = grounded.meta or { };
            metaWithDrop =
              if excludes == [ ] then
                grounded.meta or null
              else
                meta // { drop = (meta.drop or [ ]) ++ excludes; };
          in
          grounded // (if metaWithDrop == null then { } else { meta = metaWithDrop; })
      )
    );

  # Translate ONE v1 policy effect record → den-hoag declaration(s): the structural/resolution
  # vocabulary (include/exclude/resolve + the instantiate spawn). The delivery-edge vocabulary
  # (deliver/route/provide) and the pipe stages ride named seams until their own passes land. Every
  # entry-typed argument is an entry by here (C6), so the `declare.*` constructors' eager identity
  # checks pass; a stray string would abort named.
  translateEffect =
    ing: aspectRec: effect:
    let
      kind = effect.__policyEffect or null;
    in
    # A delivery descriptor (deliver/route/provide, deliver.nix) → a den-hoag `delivery` declaration
    # (intent; the gen-edge record is rendered at the firing node by output-modules' edgesAt).
    if effect.__delivery or false then
      [ (translateDelivery ing effect) ]
    else if kind == "include" then
      [ (declare.edge (resolveAspectRef aspectRec effect.value)) ]
    else if kind == "exclude" then
      [ (declare.drop (resolveAspectRef aspectRec effect.value)) ]
    else if kind == "resolve" then
      # A fan-out: a new instantiation node (`spawn`, or `spawnShared` for a non-isolated branch). The
      # binding half (`value`) becomes `member` relations for entity-valued bindings; scalar bindings
      # are context data the spawned node carries (the edge-wiring pass reads them off the declaration).
      let
        shared = effect.__shared or false;
        spawnDecl = (if shared then declare.spawnShared else declare.spawn) {
          classes = effect.includes or [ ];
          bindings = effect.value or { };
        };
      in
      [ spawnDecl ]
    else if kind == "spawn" then
      # A v1 `policy.spawn { classes }` (policy-effects.nix `spawn`) — a deferred home-projection spawn
      # (the projected content sees fleet-wide pipe values, PR #623). A den-hoag `spawn` of the named
      # classes with empty bindings; a null `classes` (v1's "default to the drain-site classes") desugars
      # to `[ ]`, letting den-hoag's spawn wiring pick the class set. The producing-scope channel
      # resolution is den-hoag's, not the shim's (Law C2). Surface acceptance here; the shared/isolated
      # projection nuance is a Task 8 parity refinement, recorded in the ledger if it diverges.
      let
        cs = effect.value.classes or null;
      in
      [
        (declare.spawn {
          classes = if cs == null then [ ] else cs;
          bindings = { };
        })
      ]
    else if kind == "pipe" then
      # A v1 `pipe.from name [stages]` → a collection-stratum `pipeOp` declaration: the deriving stages
      # fold left-to-right into a gen-pipe op DAG on the named channel, the delivery/site stages ride as
      # inert markers (pipe.nix `compilePipe`). No value is forced (Law C2); a deferred (config-thunk)
      # channel value crosses the compiled pipe untouched to the terminal (parity-watch items 5, 6).
      [ (pipeLib.compilePipe declare effect.value) ]
    else if kind == "instantiate" then
      # Native per-cluster instantiation (nixidy k8s; PIN.md census) — a spawn of the entity's class
      # content. The entity carries its own instantiate/intoAttr metadata (read at output assembly).
      [ (declare.spawn { instantiate = effect.value; }) ]
    else if kind == null then
      # Not an effect descriptor — a raw declaration a v1 body built directly. Pass it through; a
      # non-declaration surfaces at the den-hoag dispatch, not here.
      [ effect ]
    else
      errors.unsupportedEffect kind;

  # Coerce a v1 `den.policies.<name>` value to the inner `{ gate; fn }` a compiled policy wraps. v1
  # `for`/`when` produce `{ __isPolicy = true; fn; }` records whose `fn` already gates on ctx (entity
  # match / predicate); a bare function is an ungated body; a conditional-aspect record (`when` over an
  # inline aspect) is handled separately (it compiles to an aspect, not a policy — see `compilePolicies`).
  innerFn =
    value:
    if builtins.isAttrs value && (value.__isPolicy or false) then
      value.fn
    else if builtins.isFunction value then
      value
    else
      throw "den-compat: policy: expected a function or a policy record (from for/when), got ${builtins.typeOf value}";

  # A v1 `when`-over-inline-aspect record: `{ name = "<when>"; meta.guard; meta.aspects; includes; }`.
  # These are conditional ASPECTS (the guard reads the in-flight path set, A9.1), not policies — v1
  # emits them precisely to avoid the resolved-state cycle. They compile to den-hoag aspects.
  #
  # The `meta.guard` + `meta.aspects` PAIR is an unambiguous discriminator against the other two
  # `den.policies.<name>` value shapes: a bare policy is a FUNCTION (no `meta` at all), and a v1
  # `for`/`when`-over-a-policy record is `{ __isPolicy = true; name; fn; }` (an `fn`, and no
  # `meta.aspects`). Only the inline-aspect conditional carries BOTH keys, so testing the pair never
  # misclassifies a policy as an aspect (or vice versa).
  isConditionalAspect =
    value: builtins.isAttrs value && (value.meta or { }) ? guard && (value.meta or { }) ? aspects;

  # den-hoag policy: `ctx: [ declaration ]`. Wrap the v1 inner fn so its effects translate to
  # declarations. The wrapper is a bare `ctx:` (no destructuring) — v1 `for`/`when` gating already
  # lives inside `fn`, so den-hoag's dispatch runs it at every scope and `fn`'s own guard decides. The
  # translation of each effect is eager only when the body runs (per ctx); compile itself never runs it.
  # NB: a SYNTHESIZED policy whose own destructuring must gate dispatch (canTake via functionArgs)
  # MUST bypass this wrapper — it erases the formals. See `defaultPolicy` (__denDefault) below.
  compilePolicy =
    ing: aspectRec: value: ctx:
    prelude.concatMap (translateEffect ing aspectRec) (innerFn value ctx);

  # A `__denCanTake` policy — the FORMAL-PRESERVING compile path (the twin of the bare-ctx `compilePolicy`
  # for policies whose OWN destructuring must gate dispatch, not an internal for/when guard). A shim
  # built-in route (os-to-host / user-to-host, legacy/batteries) declares `{ __denCanTake = <shape>; fn =
  # { <coords>, ... }: [ effects ]; }`. This wraps `fn` with the SHAPE's LITERAL formals — so den-hoag's
  # `dispatch.fromFunction` reads them as the canTake condition (the policy fires only where those
  # coordinates are in scope) AND concern-policies' stratum probe fills them with sentinel entries, so the
  # route's UNCONDITIONAL emission classifies as RESOLUTION. (A value-conditional body would emit nothing
  # at the value-less probe → misclassify as enrich → crash on firing.) Nix cannot build a formal set from
  # a runtime list, so the shapes are a small fixed set — the two the corpus's built-in routes need.
  compileCanTake =
    ing: aspectRec: value:
    let
      translate = ctx: prelude.concatMap (translateEffect ing aspectRec) (value.fn ctx);
    in
    if value.__denCanTake == "host" then
      { host, ... }@ctx: translate ctx
    else if value.__denCanTake == "user-host" then
      { user, host, ... }@ctx: translate ctx
    else
      errors.unsupportedEffect "canTake:${value.__denCanTake}";

  compilePolicies =
    ing: aspectRec: policies:
    let
      names = builtins.attrNames policies;
      # Partition: `when`-over-inline-aspect values become aspects (conditional activation); a
      # `__denCanTake` value becomes a FORMAL-PRESERVING policy (canTake-gated built-in route); everything
      # else becomes a bare-ctx policy. A list value (from `for`/`when` over a policy list) stays a policy
      # list — den-hoag flattens a list-valued policy the same way (each element gates itself).
      isAspectValued = name: isConditionalAspect policies.${name};
      isCanTake = name: builtins.isAttrs policies.${name} && policies.${name} ? __denCanTake;
      aspectNames = builtins.filter isAspectValued names;
      canTakeNames = builtins.filter isCanTake names;
      policyNames = builtins.filter (n: !(isAspectValued n) && !(isCanTake n)) names;
    in
    {
      policies =
        prelude.genAttrs policyNames (name: compilePolicy ing aspectRec policies.${name})
        // prelude.genAttrs canTakeNames (name: compileCanTake ing aspectRec policies.${name});
      # The conditional aspects lifted out of `den.policies` (their guard + gated aspects).
      conditionalAspects = prelude.genAttrs aspectNames (
        name:
        let
          v = policies.${name};
        in
        {
          meta.guard = v.meta.guard;
          includes = v.meta.aspects;
        }
      );
    };

  # den-hoag class registration (§2.4): the `{ wrap; instantiate; share; }` surface. A v1 class decl's
  # den-hoag-shaped keys pass through; v1-battery-specific keys (parentArg/parentPath/…) are delivery
  # mechanism, consumed by `legacy.forwards` (Task 5), not the class registration.
  #
  # LEGACY SURFACE SENTINEL (C5): `forwardTo` must have been stripped by legacy/forwards.nix's desugar
  # (applied by the flakeModule assembly BEFORE compile). If it survives to here the legacy module is
  # severed — fail LOUDLY naming the surface rather than silently dropping the forward (a bare
  # `intersectAttrs` would just discard it), parallel to the `provides` sentinel in translateAspect.
  translateClass =
    name: cls:
    builtins.seq (sentinels.forwardTo name cls) (
      builtins.intersectAttrs {
        wrap = null;
        instantiate = null;
        share = null;
      } cls
    );
in
{ ... }@v1Decls:
let
  ing = ingest.ingest v1Decls;
  v1Aspects = v1Decls.aspects or { };
  v1Policies = v1Decls.policies or { };
  v1Classes = v1Decls.classes or { };

  # `den.default` (v1 modules/aspects/defaults.nix:15-19): the default aspect, injected THERE via
  # `lib.genAttrs [ "host" "user" "home" ]` as a schema `includes = [ den.default ]` for EXACTLY the three
  # built-in entity kinds — host, user, home — NOT every kind (custom kinds do NOT receive it). Compiled
  # the same way: registered as the reserved aspect `__default` (translated like any aspect — grounded
  # class keys, provides/forward sentinels apply), then radiated by a single `__denDefault` policy.
  #
  # NARROWING to v1's kind set: den-hoag folds `home` into `user` (ingest.nix §8 — user IS user∪home), so
  # v1's {host, user, home} is den-hoag's {host, user}. The policy destructures `{ host, ... }`, which
  # den-hoag's `dispatch.fromFunctionMatch` reads as a canTake guard (concern-policies.nix): it fires ONLY
  # at scopes carrying a `host` coordinate — every host and every user cell (a user inherits its host
  # coordinate) — and NEVER at a custom-kind scope (env/cluster carry only their own coordinate, no host).
  # The guard rides straight through as the SYNTHESIZED policy's real formals — it is NOT wrapped by
  # `compilePolicy` (which erases the canTake), so unlike a v1 policy body the destructure gates dispatch.
  # `host` is required-but-unused (the guard, not a read).
  # (RESIDUAL: a custom kind BOUND under a host would inherit `host` and match; the corpus census has no
  # host-nested custom kind — clusters are fleet-level — so this never diverges in practice, PIN.md.)
  #
  # One policy, not one-per-kind — a per-kind fan-out would double-radiate at the user cell (which carries
  # both host and user). `__`-prefixed names cannot collide with a user aspect/policy (den reserves `__`).
  # Absent (`den.default` unset) ⇒ no aspect, no policy — byte-identical to a fixture without it.
  hasDefault = (v1Decls.default or { }) != { };
  defaultAspects =
    if hasDefault then { __default = translateAspect "__default" v1Decls.default; } else { };
  defaultPolicy =
    if hasDefault then
      {
        __denDefault =
          { host, ... }:
          [ (declare.edge (resolveAspectRef aspectRec { name = "__default"; })) ];
      }
    else
      { };

  # Name → the FULL compiled aspect record den-hoag's resolution consumes: the compiled content
  # (`aspects.<name>`) plus its `{ id_hash; name }` identity. `resolved-aspects.nix` uses an edge's
  # aspect record directly as content, so an include MUST carry content, not a stub (the C1 gap). An
  # unknown name degrades to the bare identity (empty content), preserving the old no-abort behaviour.
  #
  # NO RECURSION CYCLE (the reference the DAG argument settles): `aspectRec` reads `aspects`; `aspects`
  # reads `compiledPolicies.conditionalAspects`; `compiledPolicies` reads `aspectRec` — but ONLY through
  # its `.policies` field. `.conditionalAspects` is built from the `when`-records alone (it never touches
  # `aspectRec`), and `aspects` reads ONLY `.conditionalAspects`. So the dependency graph is
  # `policies → aspectRec → aspects → conditionalAspects`, a DAG (`conditionalAspects ⊥ aspectRec`);
  # laziness ties the knot without a loop.
  aspectRec = name: (aspects.${name} or { }) // ing.aspectEntry name;

  compiledPolicies = compilePolicies ing aspectRec v1Policies;

  # Kind-attached includes (`den.schema.<kind>.includes`) → fire-at-kind policies: an aspect radiated to
  # every instance of a kind. Re-expressed as a den-hoag policy that emits one `edge` per aspect, gated
  # (by den-hoag dispatch) on the kind's own scope. The policy destructures the kind arg so it fires
  # only at that kind's nodes.
  kindIncludePolicies = builtins.mapAttrs (
    kind: aspectRefs:
    # `ctx: [ edge … ]` — a bare body (den-hoag dispatch runs it fleet-wide); the kind-scoping is the
    # kind arg. Task 2's dispatch wiring narrows it; for C1 this is a declaration-producing policy.
    _ctx:
    map (ref: declare.edge (resolveAspectRef aspectRec ref)) aspectRefs
  ) ing.kindIncludes;

  aspects =
    builtins.mapAttrs translateAspect v1Aspects
    // defaultAspects
    // compiledPolicies.conditionalAspects;

  # The synthetic `__kindInclude__<kind>` / `__denDefault` policy names cannot collide with a compiled
  # `den.policies.<name>`: den reserves the `__` prefix for internal keys, and a v1 policy name is a
  # user-authored identifier that never uses it — so this namespace is disjoint from `compiledPolicies`.
  policies =
    compiledPolicies.policies
    // defaultPolicy
    // builtins.listToAttrs (
      map (kind: {
        name = "__kindInclude__${kind}";
        value = kindIncludePolicies.${kind};
      }) (builtins.attrNames kindIncludePolicies)
    );

  # SURFACE TOTALITY (C1): every top-level `den.<key>` is accounted — compiled, legacy-desugared, or a
  # named abort. The permissive v1 eval (flake-module.nix freeformType) absorbs UNKNOWN `den.*` keys
  # silently; this is the promised downstream enforcement of that trade-off (errors.nix
  # `unknownSurfaceKey`). Known = the recognised concern surfaces + `den.default` + the declared custom
  # kinds (whose instances ride at `den.<kind>`). `_`-prefixed keys are den-internal (reserved), never a
  # user surface, so they are exempt. A typo'd/unknown key aborts named, never silently drops.
  declaredKinds = builtins.attrNames (v1Decls.schema or { });
  # KEEP IN SYNC with flake-module.nix `v1OptionsModule.options` (the declared v1 surface) — a key
  # added there without a row here aborts every fleet; a key here without an option there is dead.
  knownSurfaceKeys = [
    "hosts"
    "homes"
    "schema"
    "aspects"
    "policies"
    "classes"
    "include"
    "quirks"
    "contentClass"
    "default"
  ]
  ++ declaredKinds;
  unknownSurfaceKeys = builtins.filter (
    k: (builtins.substring 0 1 k != "_") && !(builtins.elem k knownSurfaceKeys)
  ) (builtins.attrNames v1Decls);
  surfaceTotalityOk =
    if unknownSurfaceKeys == [ ] then
      true
    else
      errors.unknownSurfaceKey (builtins.head unknownSurfaceKeys);
in
# Force the totality check before ANY concern crosses the boundary (a consumer forcing any output attr
# trips a typo'd/unknown `den.*` key here, never downstream).
builtins.seq surfaceTotalityOk {
  # The entity concern (§8): flat registries (entry-valued), the v1 attrs mkDen rebuilds from, the
  # membership relation, the containment schema, the content-class map, and the kind-attached includes
  # lifted to `include` records. Everything here is entry-valued past ingestion (C6).
  entities = {
    inherit (ing)
      schema
      registries
      instances
      membership
      contentClass
      systemFor
      hostClassName
      ;
  };
  inherit aspects policies;
  # Static entity-scoped aspect inclusions (den-hoag `den.include`, the §370 `directAspects` seed).
  # The compile core emits NONE — this is the seam the LEGACY `self-provide` desugar (R5, spec §10)
  # appends its self-named-aspect includes onto (flake-module.nix `addSelfIncludes`), severable: with
  # the legacy module out of the wiring the list stays empty, byte-identical to a no-R5 compile.
  include = [ ];
  # v1 `den.quirks.<name>` → a den-hoag channel registration `{ channel; ops; adapters; }` (pipe.nix
  # `channelOf`), so an aspect's quirk key resolves to a channel contribution rather than being
  # class-classified or aborting as an unknown key. The pipe STAGE vocabulary (`pipe.from`/filter/fold →
  # the operator DAG on a channel) is a POLICY effect, compiled by `translateEffect` above. KEY-OVERLAP
  # CHECK (§2.4, preserved from v1): a name declared as both a class and a quirk channel is ambiguous
  # under den-hoag's `resolveBucket` (classes ∪ channels) — a named definition-time error.
  channels =
    let
      quirks = v1Decls.quirks or { };
      classNames = builtins.attrNames v1Classes;
      overlap = builtins.filter (n: builtins.elem n classNames) (builtins.attrNames quirks);
    in
    if overlap != [ ] then
      errors.quirkClassOverlap (builtins.head overlap)
    else
      builtins.mapAttrs (_: pipeLib.channelOf) quirks;
  classes = builtins.mapAttrs translateClass v1Classes;
}
