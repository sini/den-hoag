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
}:
let
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

  # Resolve a v1 aspect REFERENCE to a den-hoag aspect entry (id_hash). Accepts an entry (pass through),
  # a `{ name; … }` aspect record, or a bare name string — the boundary conversion for the aspect row.
  resolveAspectRef =
    aspectEntry: ref:
    if builtins.isAttrs ref && ref ? id_hash then
      ref
    else if builtins.isAttrs ref && ref ? name then
      aspectEntry ref.name
    else if builtins.isString ref then
      aspectEntry ref
    else
      errors.identityLaw "policy aspect reference" ref;

  # Near-identity aspect translation (§2.2 aspect row). den-hoag's aspect submodule already accepts the
  # v1 shape — `includes`/`neededBy`/`settings`/`meta.{guard,drop}`/`projects`/`tags` and freeform
  # class/quirk keys ride THROUGH untouched (a quirk key becomes a channel contribution at the aspect's
  # producing class+scope, so PR #623 falls out). The only rewrites: a bare parametric FUNCTION coerces
  # to `{ includes = [ fn ]; }` (v1's own coercion), `excludes` folds into `meta.drop`, class keys are
  # grounded, and the v1-only structural keys are dropped.
  translateAspect =
    aspect:
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
      grounded // (if metaWithDrop == null then { } else { meta = metaWithDrop; });

  # Translate ONE v1 policy effect record → den-hoag declaration(s): the structural/resolution
  # vocabulary (include/exclude/resolve + the instantiate spawn). The delivery-edge vocabulary
  # (deliver/route/provide) and the pipe stages ride named seams until their own passes land. Every
  # entry-typed argument is an entry by here (C6), so the `declare.*` constructors' eager identity
  # checks pass; a stray string would abort named.
  translateEffect =
    ing: effect:
    let
      kind = effect.__policyEffect or null;
    in
    if kind == "include" then
      [ (declare.edge (resolveAspectRef ing.aspectEntry effect.value)) ]
    else if kind == "exclude" then
      [ (declare.drop (resolveAspectRef ing.aspectEntry effect.value)) ]
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
    else if kind == "deliver" || kind == "route" || kind == "provide" then
      errors.deliverNotYet kind
    else if kind == "pipe" then
      errors.pipeNotYet
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
  compilePolicy =
    ing: value: ctx:
    prelude.concatMap (translateEffect ing) (innerFn value ctx);

  compilePolicies =
    ing: policies:
    let
      names = builtins.attrNames policies;
      # Partition: `when`-over-inline-aspect values become aspects (conditional activation), everything
      # else becomes a policy. A list value (from `for`/`when` over a policy list) stays a policy list —
      # den-hoag flattens a list-valued policy the same way (each element gates itself).
      isAspectValued = name: isConditionalAspect policies.${name};
      aspectNames = builtins.filter isAspectValued names;
      policyNames = builtins.filter (n: !(isAspectValued n)) names;
    in
    {
      policies = prelude.genAttrs policyNames (name: compilePolicy ing policies.${name});
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
  translateClass =
    cls:
    let
      keep = builtins.intersectAttrs {
        wrap = null;
        instantiate = null;
        share = null;
      } cls;
    in
    keep;
in
{ ... }@v1Decls:
let
  ing = ingest.ingest v1Decls;
  v1Aspects = v1Decls.aspects or { };
  v1Policies = v1Decls.policies or { };
  v1Classes = v1Decls.classes or { };

  compiledPolicies = compilePolicies ing v1Policies;

  # Kind-attached includes (`den.schema.<kind>.includes`) → fire-at-kind policies: an aspect radiated to
  # every instance of a kind. Re-expressed as a den-hoag policy that emits one `edge` per aspect, gated
  # (by den-hoag dispatch) on the kind's own scope. The policy destructures the kind arg so it fires
  # only at that kind's nodes.
  kindIncludePolicies = builtins.mapAttrs (
    kind: aspectRefs:
    # `ctx: [ edge … ]` — a bare body (den-hoag dispatch runs it fleet-wide); the kind-scoping is the
    # kind arg. Task 2's dispatch wiring narrows it; for C1 this is a declaration-producing policy.
    _ctx:
    map (ref: declare.edge (resolveAspectRef ing.aspectEntry ref)) aspectRefs
  ) ing.kindIncludes;

  aspects = builtins.mapAttrs (_: translateAspect) v1Aspects // compiledPolicies.conditionalAspects;

  # The synthetic `__kindInclude__<kind>` policy names cannot collide with a compiled
  # `den.policies.<name>`: den reserves the `__` prefix for internal keys, and a v1 policy name is a
  # user-authored identifier that never uses it — so this namespace is disjoint from `compiledPolicies`.
  policies =
    compiledPolicies.policies
    // builtins.listToAttrs (
      map (kind: {
        name = "__kindInclude__${kind}";
        value = kindIncludePolicies.${kind};
      }) (builtins.attrNames kindIncludePolicies)
    );
in
{
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
      ;
  };
  inherit aspects policies;
  channels = { }; # the pipe stage vocabulary (Task 3)
  classes = builtins.mapAttrs (_: translateClass) v1Classes;
}
