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
  # scope by the engine itself (§14.2).
  deliverLib = import ./deliver.nix { inherit prelude ingest errors; };

  injectRelationships =
    ing: ctx:
    let
      # Hoist fields out of listified link contexts (from structural.nix fix)
      # e.g., if context.user = [ { resolved-users = <val>; }, ... ], then context.resolved-users = [ <val>, ... ]
      schemaNames = builtins.attrNames (ing.schema or { });
      reservedKeys = [
        "system"
        "identity"
        "uid"
        "gid"
        "linger"
        "name"
        "hasAspect"
      ]
      ++ schemaNames;
      hoistedFields = prelude.foldl' (
        acc: k:
        if builtins.isList (ctx.${k} or null) && builtins.elem k schemaNames then
          prelude.foldl' (
            acc2: ctxItem:
            if builtins.isAttrs ctxItem then
              prelude.foldl' (
                acc3: fieldK:
                if !(builtins.elem fieldK reservedKeys) then
                  acc3 // { ${fieldK} = (acc3.${fieldK} or [ ]) ++ [ ctxItem.${fieldK} ]; }
                else
                  acc3
              ) acc2 (builtins.attrNames ctxItem)
            else
              acc2
          ) acc ctx.${k}
        else
          acc
      ) { } (builtins.attrNames ctx);

      ctxWithHoisted = hoistedFields // ctx;

      step =
        currCtx:
        let
          findRelation =
            k: e:
            if builtins.isAttrs e then
              let
                entityName =
                  if e ? name then
                    e.name
                  else if e ? id_hash then
                    e.name
                  else
                    null;
                orig =
                  if entityName != null && ing.instances ? ${k} && ing.instances.${k} ? ${entityName} then
                    ing.instances.${k}.${entityName}
                  else
                    { };
                relKeys = builtins.filter (
                  attr:
                  let
                    val = orig.${attr} or null;
                  in
                  ing.registries ? ${attr}
                  && builtins.isString val
                  && ing.registries.${attr} ? ${val}
                  && !(currCtx ? ${attr})
                ) (builtins.attrNames orig);
              in
              prelude.foldl' (acc: attr: acc // { ${attr} = ing.registries.${attr}.${orig.${attr}}; }) { } relKeys
            else
              { };
          relationsList = map (k: findRelation k currCtx.${k}) (builtins.attrNames currCtx);
          allRelations = prelude.foldl' (acc: r: acc // r) { } relationsList;
        in
        if allRelations == { } then currCtx else step (currCtx // allRelations);
    in
    step ctxWithHoisted;

  setFunctionArgs = f: args: {
    __functor = self: f;
    __functionArgs = args;
  };

  # SOURCE ARM (v1-faithful): a class source → `collected` of the `from` class (edges/route.nix); a
  # MODULE source (provide) → `collected` of the TARGET class (edges/provides.nix:121-122 — the provided
  # module rides the target scope's OWN bucket and is carried by the default fold, hence `mergeHalf =
  # "default-fold"`). NEVER `synthesize` (that is only v1's __complexForward adapter arm, Task 5) and
  # NEVER `value` (v1's frozen sourceKey has no value arm — a value edge could never byte-match, P1).
  # Class-name strings resolve to registrations HERE (C6, unknown → named abort); names never survive on.
  translateDelivery =
    ing: d:
    let
      isModule = d.sourceClass == null;
      toEntry = ing.resolveBucket "deliver" d.target;
      annotations =
        prelude.optionalAttrs (d.adaptArgs != null) { adaptArgs = true; }
        // prelude.optionalAttrs (d.guard != null) { guard = true; }
        // prelude.optionalAttrs isModule { mergeHalf = "default-fold"; };

      # Wrap the module for eval-time application of guard and adaptArgs (Gap 2)
      wrapModule =
        m:
        if d.guard == null && d.adaptArgs == null then
          m
        else
          # A nixpkgs-free wrapper (the terminal crosses nixpkgs, so args exist there)
          args:
          let
            a = if d.adaptArgs != null then d.adaptArgs args else args;
            g = if d.guard != null then d.guard a else true;
            evaluated = if builtins.isFunction m then m a else m;
          in
          if g then evaluated else { };

      delivDecl = declare.delivery {
        sourceClass = if isModule then toEntry else ing.resolveBucket "deliver" d.sourceClass;
        targetClass = toEntry;
        module = d.moduleSource;
        inherit (d)
          path
          mode
          guard
          adaptArgs
          ;
        inherit annotations;
      };

      injectDecl = declare.inject {
        class = toEntry;
        module = wrapModule d.moduleSource;
      };
    in
    if isModule then
      [
        delivDecl
        injectDecl
      ]
    else
      [ delivDecl ];

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

  # Aspect identity check.
  hasId = a: builtins.isAttrs a && a ? id_hash;

  # V1 structural keys (those that are not class or channel content).
  structuralKeysSet = {
    settings = true;
    includes = true;
    neededBy = true;
    meta = true;
    tags = true;
    projects = true;
    name = true;
    description = true;
    id_hash = true;
  };

  # Recursive sanitization for aspect `includes`. In den-hoag V1, `includes` could contain bare
  # lambdas (like `userContext`) that gen-merge conditionally evaluated. In gen-hoag V2, the
  # `resolved-aspects` fixpoint's `forwardExpand` expects either concrete aspects or wrapped
  # functors (`__isWrappedFn = true`). This walks the `includes` tree and wraps lambdas.
  sanitizeAspect =
    ing: aspectRec: v1Classes: v1Quirks: name: aspect:
    if
      builtins.isFunction aspect
      || (builtins.isAttrs aspect && aspect ? __functor && !(aspect.__isWrappedFn or false))
    then
      {
        __isWrappedFn = true;
        id_hash = (ing.aspectEntry name).id_hash or null;
        name = "${name}-wrapper";
        __aspectName = name;
        __functionArgs =
          if builtins.isFunction aspect then
            builtins.functionArgs aspect
          else if builtins.isAttrs aspect && aspect ? __functionArgs then
            aspect.__functionArgs
          else if builtins.isAttrs aspect && aspect ? __functor then
            builtins.functionArgs (aspect.__functor aspect)
          else
            { };
        __functor =
          self: ctx:
          let
            args = self.__functionArgs;
            ctxWithExtras = injectRelationships ing (
              (prelude.optionalAttrs (ing ? secretsConfig) { inherit (ing) secretsConfig; })
              // (prelude.optionalAttrs (ing ? lib) { inherit (ing) lib; })
              // ctx
            );
            _traceArgs = builtins.trace "FUNCTOR ARGS FOR ${self.__aspectName or "MISSING"}: args=${builtins.toJSON args}, ctxKeys=${builtins.toJSON (builtins.attrNames ctxWithExtras)}" null;
          in
          builtins.seq _traceArgs (
            let
              missingArgs = builtins.filter (k: !args.${k} && !(ctxWithExtras ? ${k})) (builtins.attrNames args);
              augmentEntity =
                k: e:
                let
                  entityName =
                    if builtins.isAttrs e && e ? name then
                      e.name
                    else if builtins.isAttrs e && e ? id_hash then
                      e.name
                    else
                      null;
                  rawOrig =
                    if k == "user" && entityName != null && ing.v1UsersRegistry ? ${entityName} then
                      ing.v1UsersRegistry.${entityName}
                    else if
                      entityName != null && ing.hydratedInstances ? ${k} && ing.hydratedInstances.${k} ? ${entityName}
                    then
                      ing.hydratedInstances.${k}.${entityName}
                    else
                      { };
                  orig = rawOrig;
                  base =
                    e
                    // orig
                    // (prelude.optionalAttrs (entityName != null) {
                      ${k + "Name"} = entityName;
                      name = entityName;
                      hasAspect = e.hasAspect or (activeHasAspect ing k entityName);
                    });
                in
                if k == "host" && !(base ? class) then base // { class = "nixos"; } else base;
              augmentedCtx = builtins.mapAttrs augmentEntity ctxWithExtras;
              evaluateQuirks =
                attrs:
                if builtins.isAttrs attrs then
                  builtins.mapAttrs (
                    k: v: if v1Quirks ? ${k} && builtins.isFunction v then v augmentedCtx else v
                  ) attrs
                else
                  attrs;
            in
            if missingArgs == [ ] then
              let
                res = evaluateQuirks (aspect augmentedCtx);
                resWithName =
                  if self.__aspectName != null && builtins.isAttrs res then
                    res
                    // {
                      name = self.__aspectName;
                    }
                    // (prelude.optionalAttrs (self ? id_hash) { inherit (self) id_hash; })
                  else
                    res;
              in
              if builtins.isAttrs resWithName then
                let
                  rewritten = prelude.foldl' (
                    acc: k:
                    let
                      k' = v1ClassKeyMap.${k} or k;
                    in
                    acc // { ${k'} = resWithName.${k}; }
                  ) { } (builtins.attrNames resWithName);
                in
                sanitizeAspect ing aspectRec v1Classes v1Quirks self.__aspectName rewritten
              else
                resWithName
            else
              let
                _traceMissingArgs =
                  if self.__aspectName or "" == "core.users.resolved-user-emitter" then
                    builtins.trace "CHECKING WRAPPER FOR ${self.__aspectName}: missingArgs=${builtins.toJSON missingArgs}, hasHost=${builtins.toJSON (ctxWithExtras ? host)}" null
                  else
                    null;
              in
              builtins.seq _traceMissingArgs (
                if missingArgs == [ "user" ] && ctxWithExtras ? host then
                  let
                    myUsers = builtins.filter (m: (m.coords.host.name or null) == ctxWithExtras.host.name) (
                      ing.membership or [ ]
                    );
                    myUserNames = map (m: m.coords.user.name) myUsers;
                  in
                  if myUserNames == [ ] then
                    {
                      id_hash = "noop-skip-no-users";
                      name = "noop";
                    }
                  else
                    {
                      __isWrappedFn = true;
                      id_hash = (ing.aspectEntry self.__aspectName).id_hash or null;
                      name = "${self.__aspectName}-wrapper";
                      __aspectName = self.__aspectName;
                      __functionArgs = {
                        host = true;
                      };
                      __functor =
                        self: ctx:
                        let
                          _trace = builtins.trace "MULTI-USER-WRAPPER FIRING FOR ${ctx.host.name} ON ${self.__aspectName} with users ${builtins.toJSON myUserNames}" null;
                          expandedIncludes = map (
                            uName:
                            let
                              fullUser = ing.users.registry.${uName} or { name = uName; };
                              userCtx = ctx // {
                                user = fullUser // {
                                  name = uName;
                                };
                              };
                            in
                            aspect userCtx
                          ) myUserNames;
                        in
                        builtins.seq _trace {
                          includes = expandedIncludes;
                        };
                    }
                else
                  {
                    id_hash = "noop-skip-${builtins.hashString "sha256" (builtins.toJSON args)}";
                    name = "noop";
                  }
              )
          );
      }
    else if builtins.isAttrs aspect then
      let
        hasQuirkFn = builtins.any (k: v1Quirks ? ${k} && builtins.isFunction aspect.${k}) (
          builtins.attrNames aspect
        );
      in
      if hasQuirkFn then
        let
          quirkFnKeys = builtins.filter (k: v1Quirks ? ${k} && builtins.isFunction aspect.${k}) (
            builtins.attrNames aspect
          );
          quirkArgsList = map (k: builtins.functionArgs aspect.${k}) quirkFnKeys;
          combinedArgs = prelude.foldl' (
            acc: args:
            acc // builtins.mapAttrs (name: req: if acc ? ${name} then acc.${name} && req else req) args
          ) { } quirkArgsList;
          wrapped = sanitizeAspect ing aspectRec v1Classes v1Quirks name (_ctx: aspect);
        in
        wrapped // { __functionArgs = combinedArgs; }
      else
        aspect
        // (
          if aspect ? includes then
            { includes = map (resolveAspectRef ing aspectRec v1Classes v1Quirks) aspect.includes; }
          else
            { }
        )
    else
      aspect;

  # Resolve a v1 aspect REFERENCE to the den-hoag aspect record den-hoag's resolution consumes. Accepts
  # an already-resolved record (pass through), a `{ name; … }` record, or a bare name string. `aspectRec`
  # (threaded from the inner block) maps a name to the FULL compiled aspect record — content + id_hash +
  # name — NOT a bare `{ id_hash; name }` stub: `resolved-aspects.nix` `policyEdgeAspects` uses the
  # edge's aspect record DIRECTLY as content (it never re-looks-up a registry), so a stub would resolve
  # to an EMPTY aspect and a compat-included aspect would contribute no class/channel content (the C1
  # gap the delivery content path exposed). The full record's `name` gives `gen-aspects.key` the same
  # key a `neededBy` inclusion produces (dedup-coherent), and `id_hash` satisfies `declare.edge`'s A2.
  resolveAspectRef =
    ing: aspectRec: v1Classes: v1Quirks: ref:
    let
      foundName = (ing.findAspectName or (_: null)) ref;
      refName =
        if builtins.isAttrs ref && ref ? name then
          ref.name
        else if builtins.isString ref then
          ref
        else
          "anon";
      _traceRef = builtins.trace "RESOLVE ASPECT REF FOR: ${refName}, foundName: ${if foundName != null then foundName else "null"}" null;
    in
    builtins.seq _traceRef (
      if foundName != null then
        aspectRec foundName
      else if builtins.isAttrs ref && ref ? id_hash then
        ref
      else if
        builtins.isAttrs ref
        && ref ? name
        && (ing._originalFlatAspects ? ${ref.name} || ref.name == "__default")
      then
        aspectRec ref.name
      else if builtins.isAttrs ref && ref ? name then
        let
          translated = translateAspect ing aspectRec v1Classes v1Quirks ref.name ref;
        in
        translated // ing.aspectEntry ref.name
      else if builtins.isString ref then
        aspectRec ref
      else if builtins.isFunction ref || (builtins.isAttrs ref && ref ? __isWrappedFn) then
        let
          dummyName =
            "inline-aspect-fn-"
            + builtins.hashString "sha256" (
              builtins.toJSON (ref.__functionArgs or (builtins.functionArgs ref))
            );
          translated = translateAspect ing aspectRec v1Classes v1Quirks dummyName ref;
        in
        translated // ing.aspectEntry dummyName
      else if builtins.isAttrs ref then
        let
          dummyName =
            "inline-aspect-"
            + builtins.hashString "sha256" (builtins.concatStringsSep "-" (builtins.attrNames ref));
          translated = translateAspect ing aspectRec v1Classes v1Quirks dummyName ref;
        in
        translated // ing.aspectEntry dummyName
      else
        errors.identityLaw "policy aspect reference" ref
    );

  activeHasAspect =
    ing: k: entityName: ref:
    let
      nodeId = "${k}:${entityName}";
      targetKey = (ing.findAspectName or (_: null)) ref;
      resolvedList =
        if ing ? _lazyDatabase && ing._lazyDatabase != null && ing._lazyDatabase ? structural then
          ing._lazyDatabase.structural.eval.get nodeId "resolved-aspects"
        else
          [ ];
    in
    if targetKey == null then false else builtins.any (n: n.key == targetKey) resolvedList;

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
    ing: aspectRec: v1Classes: v1Quirks: name: aspect:
    builtins.seq (sentinels.provides name aspect) (
      builtins.seq (noBatteriesForward name aspect) (
        let
          sanitized = sanitizeAspect ing aspectRec v1Classes v1Quirks name aspect;
        in
        if builtins.isFunction sanitized || (builtins.isAttrs sanitized && sanitized ? __isWrappedFn) then
          { includes = [ sanitized ]; }
        else
          let
            excludes = sanitized.excludes or [ ];
            withoutDropped = builtins.removeAttrs sanitized droppedAspectKeys;
            validKeys = builtins.filter (
              k:
              structuralKeysSet ? ${k}
              || v1Classes ? ${v1ClassKeyMap.${k} or k}
              || (builtins.elem (v1ClassKeyMap.${k} or k) [
                "nixos"
                "darwin"
                "home-manager"
                "colmena"
                "nix-on-droid"
                "disko"
              ])
              || v1Quirks ? ${k}
              || k == "os"
            ) (builtins.attrNames withoutDropped);
            grounded = prelude.foldl' (
              acc: k:
              if k == "os" then
                let
                  recursiveUpdate =
                    lhs: rhs:
                    if builtins.isAttrs lhs && builtins.isAttrs rhs then
                      builtins.foldl' (
                        a: k2:
                        a
                        // {
                          ${k2} = if a ? ${k2} then recursiveUpdate a.${k2} rhs.${k2} else rhs.${k2};
                        }
                      ) lhs (builtins.attrNames rhs)
                    else
                      rhs;
                in
                acc
                // {
                  nixos = if acc ? nixos then recursiveUpdate acc.nixos sanitized.os else sanitized.os;
                  darwin = if acc ? darwin then recursiveUpdate acc.darwin sanitized.os else sanitized.os;
                }
              else
                let
                  k' = v1ClassKeyMap.${k} or k;
                in
                acc // { ${k'} = sanitized.${k}; }
            ) { } validKeys;
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
    ing: aspectRec: v1Classes: v1Quirks: ctx: effect:
    let
      kind = if builtins.isAttrs effect then effect.__policyEffect or null else null;
    in
    # A delivery descriptor (deliver/route/provide, deliver.nix) → a den-hoag `delivery` declaration
    # (intent; the gen-edge record is rendered at the firing node by output-modules' edgesAt).
    if effect.__delivery or false then
      translateDelivery ing effect
    else if kind == "include" then
      let
        ref =
          if
            builtins.isFunction effect.value || (builtins.isAttrs effect.value && effect.value ? __isWrappedFn)
          then
            effect.value ctx
          else
            effect.value;
      in
      if builtins.isAttrs ref && ref ? name && !(ref ? id_hash) then
        # Inline aspect definition inside an include effect.
        let
          translated = translateAspect ing aspectRec v1Classes v1Quirks ref.name ref;
          fullAspect = translated // ing.aspectEntry ref.name;
        in
        [ (declare.edge fullAspect) ]
      else
        [ (declare.edge (resolveAspectRef ing aspectRec v1Classes v1Quirks ref)) ]
    else if kind == "exclude" then
      [ (declare.drop (resolveAspectRef ing aspectRec v1Classes v1Quirks effect.value)) ]
    else if kind == "resolve" then
      # A fan-out: a new instantiation node (`spawn`, or `spawnShared` for a non-isolated branch).
      # den-hoag (v2) treats `resolve.shared { user }` as a structural link to the user cell,
      # as the user cell is already instantiated via gen-product.
      let
        shared = effect.__shared or false;
        kindClasses =
          if effect ? __resolveKind && ing._rawSchema ? ${effect.__resolveKind} then
            ing._rawSchema.${effect.__resolveKind}.classes or [ ]
          else
            [ ];
        bindings = effect.value;
        # If there is exactly one binding and it's an entity, emit a link edge.
        bindingKeys = builtins.attrNames bindings;
        singleBindingKey = if builtins.length bindingKeys == 1 then builtins.elemAt bindingKeys 0 else null;
        targetEntry =
          if
            singleBindingKey != null
            && builtins.isAttrs bindings.${singleBindingKey}
            && bindings.${singleBindingKey} ? id_hash
          then
            bindings.${singleBindingKey}
          else
            null;

        decl =
          if shared && targetEntry != null then
            declare.link { target = targetEntry; }
          else
            (if shared then declare.spawnShared else declare.spawn) {
              classes = (effect.includes or [ ]) ++ kindClasses;
              inherit bindings;
            };
      in
      [ decl ]
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
      if builtins.isAttrs effect && effect ? name then
        # Inline aspect definition (a policy function evaluated to an aspect).
        # Translate it, stamp an id_hash, and emit an edge carrying the full record.
        let
          translated = translateAspect ing aspectRec v1Classes v1Quirks effect.name effect;
          fullAspect = translated // ing.aspectEntry effect.name;
        in
        [ (declare.edge fullAspect) ]
      else if builtins.isAttrs effect then
        # Unnamed inline module/aspect
        let
          dummyName =
            "inline-aspect-"
            + builtins.hashString "sha256" (builtins.concatStringsSep "-" (builtins.attrNames effect));
          translated = translateAspect ing aspectRec v1Classes v1Quirks dummyName effect;
        in
        [ (declare.edge (translated // ing.aspectEntry dummyName)) ]
      else
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
      throw "den-compat: policy: expected a function or a policy record (from for/when), got ${builtins.typeOf value}: ${
        if builtins.isAttrs value then
          builtins.toJSON (builtins.attrNames value)
        else
          builtins.toString value
      }";

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
  # MUST bypass this wrapper — it erases the formals. See `defaultPolicy` (__denDefault) below.
  # (Fixed: compilePolicy guards evaluation based on the policy's required arguments.
  # If the context lacks a required argument, it returns `[ ]` instead of throwing.)
  compilePolicy =
    ing: aspectRec: v1Classes: v1Quirks: value: ctx:
    let
      fn = innerFn value;
      getFunctionArgs =
        f:
        if builtins.isFunction f then
          builtins.functionArgs f
        else if builtins.isAttrs f && f ? __functionArgs then
          f.__functionArgs
        else
          { };
      args = getFunctionArgs fn;
      ctxWithExtras = injectRelationships ing (
        (prelude.optionalAttrs (ing ? secretsConfig) { inherit (ing) secretsConfig; })
        // (prelude.optionalAttrs (ing ? lib) { inherit (ing) lib; })
        // ctx
      );
      missingArgs = builtins.filter (k: !args.${k} && !(ctxWithExtras ? ${k})) (builtins.attrNames args);
      isProbe = ctx.__isProbe or false;

      augmentEntity =
        k: e:
        let
          entityName =
            if builtins.isAttrs e && e ? name then
              e.name
            else if builtins.isAttrs e && e ? id_hash then
              e.name
            else
              null;
          orig =
            if entityName != null && ing.instances ? ${k} && ing.instances.${k} ? ${entityName} then
              ing.instances.${k}.${entityName}
            else
              { };
          base =
            e
            // orig
            // (prelude.optionalAttrs (entityName != null) {
              ${k + "Name"} = entityName;
              name = entityName;
              hasAspect = e.hasAspect or (activeHasAspect ing k entityName);
            });
        in
        if k == "host" && !(base ? class) then base // { class = "nixos"; } else base;

      augmentedCtx =
        if isProbe then
          prelude.genAttrs (builtins.attrNames args) (k: {
            id_hash = "«probe»";
            name = "«probe»";
            class = "nixos";
            settings = { };
          })
        else
          builtins.mapAttrs (k: v: if builtins.isAttrs v then augmentEntity k v else v) ctxWithExtras;
    in
    if isProbe || missingArgs == [ ] then
      let
        res = fn augmentedCtx;
      in
      if builtins.isList res then
        prelude.concatMap (translateEffect ing aspectRec v1Classes v1Quirks augmentedCtx) res
      else
        translateEffect ing aspectRec v1Classes v1Quirks augmentedCtx res
    else
      [ ];

  compilePolicies =
    ing: aspectRec: v1Classes: v1Quirks: policies:
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
      policies = prelude.genAttrs policyNames (
        name: compilePolicy ing aspectRec v1Classes v1Quirks policies.${name}
      );
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
  _rawIng = ingest.ingest v1Decls // {
    inherit findAspectName;
    _originalFlatAspects = v1Decls._originalFlatAspects or (v1Decls.aspects or { });
    secretsConfig = v1Decls.secretsConfig or { };
    _lazyDatabase = v1Decls._lazyDatabase or null;
    _evalModules = v1Decls._evalModules or null;
    _rawSchema = v1Decls._rawSchema or null;
    v1UsersRegistry = (v1Decls.den.users.registry or { }) // (v1Decls.users.registry or { });
  };

  ing =
    _rawIng
    // {
      hydratedInstances =
        if _rawIng ? _evalModules && _rawIng ? _rawSchema then
          builtins.mapAttrs (
            k: instancesOfKind:
            if (_rawIng._rawSchema or { }) ? ${k} && _rawIng._rawSchema.${k} ? imports then
              builtins.mapAttrs (
                entityName: rawOrig:
                (_rawIng._evalModules {
                  modules = _rawIng._rawSchema.${k}.imports ++ [
                    (rawOrig // { name = entityName; })
                    ({ lib, ... }: { freeformType = lib.types.lazyAttrsOf (lib.types.raw or lib.types.unspecified); })
                  ];
                }).config
              ) instancesOfKind
            else
              instancesOfKind
          ) _rawIng.instances
        else
          _rawIng.instances;
    }
    // (prelude.optionalAttrs (v1Decls ? lib) { inherit (v1Decls) lib; });
  v1Aspects = v1Decls.aspects or { };
  v1Policies = v1Decls.policies or { };
  v1Classes = v1Decls.classes or { };
  v1Quirks = v1Decls.quirks or { };

  _originalFlatAspects = ing._originalFlatAspects;
  flatAspectsList = map (name: {
    inherit name;
    val = _originalFlatAspects.${name};
  }) (builtins.attrNames _originalFlatAspects);

  findAspectName =
    ref:
    if builtins.isAttrs ref && ref ? _aspectPath then
      ref._aspectPath
    else if builtins.isString ref then
      if _originalFlatAspects ? ${ref} then ref else null
    else if builtins.isAttrs ref && ref ? name && _originalFlatAspects ? ${ref.name} then
      ref.name
    else
      # Find in flatAspectsList
      let
        stripMeta =
          x:
          if builtins.isAttrs x then
            removeAttrs x [
              "_aspectPath"
              "name"
              "id_hash"
            ]
          else
            x;
        targetVal = stripMeta ref;
        matches = builtins.filter (item: stripMeta item.val == targetVal) flatAspectsList;
      in
      if matches != [ ] then (builtins.head matches).name else null;

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
  defaultIncludes = (v1Decls.default or { }).includes or [ ];
  defaultModuleIncludes = builtins.filter (
    v: !(builtins.isFunction v || (builtins.isAttrs v && v ? __policyEffect))
  ) defaultIncludes;
  defaultPolicyIncludes = builtins.filter (
    v: builtins.isFunction v || (builtins.isAttrs v && v ? __policyEffect)
  ) defaultIncludes;

  defaultAspects =
    if hasDefault then
      {
        __default = translateAspect ing aspectRec v1Classes v1Quirks "__default" (
          v1Decls.default // { includes = defaultModuleIncludes; }
        );
      }
    else
      { };

  defaultPolicies =
    if hasDefault then
      {
        __denDefault_host = { host, ... }: [
          (declare.edge (resolveAspectRef ing aspectRec v1Classes v1Quirks { name = "__default"; }))
        ];
        __denDefault_user = { user, ... }: [
          (declare.edge (resolveAspectRef ing aspectRec v1Classes v1Quirks { name = "__default"; }))
        ];
        __denDefault_home = { home, ... }: [
          (declare.edge (resolveAspectRef ing aspectRec v1Classes v1Quirks { name = "__default"; }))
        ];
      }
      // builtins.listToAttrs (
        prelude.concatMap (
          idx:
          let
            ref = builtins.elemAt defaultPolicyIncludes idx;
          in
          [
            {
              name = "__defaultPolicy_host_${toString idx}";
              value = { host, ... }@ctx: compilePolicy ing aspectRec v1Classes v1Quirks ref ctx;
            }
            {
              name = "__defaultPolicy_user_${toString idx}";
              value = { user, ... }@ctx: compilePolicy ing aspectRec v1Classes v1Quirks ref ctx;
            }
            {
              name = "__defaultPolicy_home_${toString idx}";
              value = { home, ... }@ctx: compilePolicy ing aspectRec v1Classes v1Quirks ref ctx;
            }
          ]
        ) (builtins.genList (i: i) (builtins.length defaultPolicyIncludes))
      )
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

  compiledPolicies = compilePolicies ing aspectRec v1Classes v1Quirks v1Policies;

  # Kind-attached includes (`den.schema.<kind>.includes`) → fire-at-kind policies: an aspect radiated to
  # kind's own scope. The policy destructures the kind arg so it fires only at that kind's nodes.
  # We generate one policy PER item in `includes` to satisfy gen-hoag's rule that a single policy
  # must only produce declarations for a single stratum (e.g. `edge` vs `pipeOp`).
  kindIncludePolicies =
    let
      imap0 = f: l: builtins.genList (i: f i (builtins.elemAt l i)) (builtins.length l);
      policyPairs = prelude.concatMap (
        kind:
        let
          aspectRefs = ing.kindIncludes.${kind};
          processRef =
            ref: ctx:
            let
              _traceProcessRef = builtins.trace "processRef kind=${kind}, ctx keys=${builtins.toJSON (builtins.attrNames ctx)}" null;
            in
            builtins.seq _traceProcessRef (
              if builtins.isFunction ref || (builtins.isAttrs ref && ref ? __policyEffect) then
                # It's a policy function or an effect record. Compile it as a policy.
                compilePolicy ing aspectRec v1Classes v1Quirks ref ctx
              else if builtins.isAttrs ref && !(ref ? name) && !(ref ? id_hash) then
                # Unnamed inline module/aspect
                let
                  dummyName =
                    "inline-aspect-"
                    + builtins.hashString "sha256" (builtins.concatStringsSep "-" (builtins.attrNames ref));
                  translated = translateAspect ing aspectRec v1Classes v1Quirks dummyName ref;
                in
                [ (declare.edge (translated // ing.aspectEntry dummyName)) ]
              else
                # It's a standard aspect reference.
                [ (declare.edge (resolveAspectRef ing aspectRec v1Classes v1Quirks ref)) ]
            );

          mkPolicyForRef =
            ref:
            if kind == "env" then
              {
                env ? null,
                ...
              }@ctx:
              if ctx ? env then processRef ref ctx else [ ]
            else if kind == "host" then
              {
                host ? null,
                ...
              }@ctx:
              if ctx ? host then processRef ref (ctx // { accessGroups = ctx.host.accessGroups or [ ]; }) else [ ]
            else if kind == "user" then
              {
                user ? null,
                ...
              }@ctx:
              if ctx ? user then processRef ref ctx else [ ]
            else
              { ... }@ctx:
              if ctx ? ${kind} then
                processRef ref ctx
              else if ctx == { } then
                [
                  (declare.edge {
                    id_hash = "«probe»";
                    name = "«probe»";
                  })
                ]
              else
                [ ];
        in
        imap0 (idx: ref: {
          name = "__kindInclude__${kind}__${toString idx}";
          value = mkPolicyForRef ref;
        }) aspectRefs
      ) (builtins.attrNames ing.kindIncludes);
    in
    builtins.listToAttrs policyPairs;

  # selfProvideInclude (Gap 1): a v1 `host.name==key` implicit auto-inclusion.
  # If an aspect's name EXACTLY matches the host's name, it is automatically included.
  # Represented as a fleet-wide policy matching the host name.
  selfProvideInclude = {
    __selfProvideInclude =
      {
        host ? null,
        ...
      }:
      if host != null then
        if host.name == "«probe»" then
          [
            (declare.edge {
              id_hash = "«probe»";
              name = "«probe»";
            })
          ]
        else if v1Aspects ? ${host.name} then
          [ (declare.edge (resolveAspectRef ing aspectRec v1Classes v1Quirks host.name)) ]
        else
          [ ]
      else
        [ ];
  };

  aspects =
    builtins.mapAttrs (translateAspect ing aspectRec v1Classes v1Quirks) v1Aspects
    // defaultAspects
    // compiledPolicies.conditionalAspects;

  # Generate a den-hoag policy for every aspect that returns non-structural keys.
  # This ensures custom data (e.g., `resolved-users`) evaluates at the `enrichments` stratum
  # and populates `enriched-context` (making it visible across `link` edges).
  compatEnrichPolicies =
    let
      structuralKeysSet = {
        settings = true;
        includes = true;
        neededBy = true;
        meta = true;
        tags = true;
        projects = true;
        name = true;
        description = true;
        id_hash = true;
      };

      aspectEnrichPolicy =
        name: aspectFields:
        let
          # Only include keys that are defined, not structural, and not from the legacy class surface
          v1ClassKeyMap = {
            homeManager = "home-manager";
          };
          customKeys = builtins.filter (
            k:
            !(structuralKeysSet ? ${k})
            && !(v1Classes ? ${v1ClassKeyMap.${k} or k} || v1Classes ? ${k})
            && !(v1Quirks ? ${k})
            && (builtins.isAttrs aspectFields.${k} || builtins.isFunction aspectFields.${k})
          ) (builtins.attrNames aspectFields);
        in
        if customKeys == [ ] then
          null
        else
          {
            "__compatEnrich__${name}" =
              { ... }@ctx:
              builtins.map (
                k:
                declare.enrich {
                  key = k;
                  value = aspectFields.${k};
                }
              ) customKeys;
          };

      policiesList = builtins.filter (x: x != null) (prelude.mapAttrsToList aspectEnrichPolicy v1Aspects);
    in
    prelude.foldl' (acc: p: acc // p) { } policiesList;

  # The synthetic `__kindInclude__<kind>` / `__denDefault` / `__selfProvideInclude` / `__compatEnrich__*`
  # policy names cannot collide with a compiled `den.policies.<name>`: den reserves the `__` prefix for
  # internal keys, and a v1 policy name is a user-authored identifier that never uses it — so this
  # namespace is disjoint from `compiledPolicies`.
  policies =
    compiledPolicies.policies
    // defaultPolicies
    // selfProvideInclude
    // kindIncludePolicies
    // compatEnrichPolicies;

  # SURFACE TOTALITY (C1): every top-level `den.<key>` is accounted — compiled, legacy-desugared, or a
  # named abort. The permissive v1 eval (flake-module.nix freeformType) absorbs UNKNOWN `den.*` keys
  # silently; this is the promised downstream enforcement of that trade-off (errors.nix
  # `unknownSurfaceKey`). Known = the recognised concern surfaces + `den.default` + the declared custom
  # kinds (whose instances ride at `den.<kind>`). `_`-prefixed keys are den-internal (reserved), never a
  # user surface, so they are exempt. A typo'd/unknown key aborts named, never silently drops.
  declaredKinds = builtins.attrNames (v1Decls.schema or { });
  pluralizedKinds = map (k: k + "s") declaredKinds;
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
    "nixpkgs"
    "reservedKeys"
    "secretsConfig"
    "batteries"
    "lib"
  ]
  ++ declaredKinds
  ++ pluralizedKinds;
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
      membership
      contentClass
      systemFor
      channelFor
      instantiateFor
      ;
    instances = ing.hydratedInstances;
  };
  inherit aspects policies;
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
  classes =
    let
      customClasses = builtins.mapAttrs translateClass v1Classes;
      defaultClasses = {
        nixos = translateClass "nixos" { };
        darwin = translateClass "darwin" { };
        "home-manager" = translateClass "home-manager" { };
        colmena = translateClass "colmena" { };
        "nix-on-droid" = translateClass "nix-on-droid" { };
        disko = translateClass "disko" { };
      };
    in
    defaultClasses // customClasses;
}
