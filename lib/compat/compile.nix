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
  aspects,
  builtinClasses,
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
  # A NULL-TARGET delivery is a DEFINED NO-OP (materializes to no edge) — the canTake-era value-gate's
  # INERT ARM. A built-in route emits UNCONDITIONALLY (probe-safe classification, compileCanTake) but folds
  # v1's value-gate into its `intoClass`: os-to-host's `elem host.class [nixos darwin]` false ⇒ `null`;
  # a synthetic `user@host` home with no OS class ⇒ `null`. That null target must stay INERT, NOT misroute
  # to a default. It is still emitted (a resolution-stratum declaration, so the route classifies as
  # resolution, not enrich) but flagged `__dropped`; output-modules `deliveryEdgesAt` skips it.
  # `droppedTargetSentinel` is a FABRICATED non-registry record: it carries an `id_hash`, so it passes
  # `declare.delivery`'s A2 `requireEntry` BY SHAPE (that check tests for the field, not registry
  # membership) without a registry lookup. This is a DELIBERATE spoof of the identity check, CONFINED to
  # the dropped arm (`dropped = d.target == null`) — harmless precisely because a dropped delivery is NEVER
  # rendered (`deliveryEdgesAt` skips it), so the sentinel's class name is never read. An UNKNOWN (non-null)
  # class name still aborts LOUDLY at resolveBucket — `null` is the ONE defined no-op.
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
      toEntry =
        if dropped then droppedTargetSentinel else ing.resolveBucket "deliver" (groundClassName d.target);
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
          ing.resolveBucket "deliver" (groundClassName d.sourceClass);
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
  # v1 keys home-manager content under `homeManager` (pin 11866c16 nix/lib/entities/home.nix:124
  # `class = strOpt "…" "homeManager"`; nix/denTest.nix:108 `den.schema.user.classes = ["homeManager"]`),
  # so den-hoag's registered `home-manager` class is the grounded terminology this normalizes to (R2).
  v1ClassKeyMap = {
    homeManager = "home-manager";
  };

  # Ground ONE v1 class-NAME string (not an attrset key) through the SAME v1ClassKeyMap — for the
  # class-name FIELDS a translated route/deliver effect resolves against `resolveBucket` (§9 C6):
  # `sourceClass` (v1 `fromClass`) and `target` (v1 `intoClass`). A v1 policy emits v1 spellings
  # (corpus modules/den/classes/home-platform.nix:12/22/32 `intoClass = "homeManager"`), so the raw
  # name would abort `unknown class homeManager` at resolveBucket without this. Identity for an
  # already-grounded name (corpus `flake-parts`, `homeLinux`/…, `devshell`) — a pure passthrough there,
  # so the deliver's LOUD abort on a genuinely-unknown name is preserved. Single v1ClassKeyMap source.
  groundClassName = name: v1ClassKeyMap.${name} or name;

  # Ground a v1 aspect attrset's CLASS keys (the same v1ClassKeyMap translateAspect applies statically) —
  # applied to a wrapped include's RUNTIME result AND to a static include attrset, because a v1 battery fn
  # returns un-grounded v1 class names (e.g. `homeManager`) only at resolution, and inputs'/self's nested
  # static `{ homeManager._module.args… }` carries the un-grounded key too. Single v1ClassKeyMap source.
  groundKeys =
    attrs:
    prelude.foldl' (
      acc: k: builtins.removeAttrs acc [ k ] // { ${v1ClassKeyMap.${k} or k} = attrs.${k}; }
    ) attrs (builtins.attrNames attrs);

  # ── PROVIDER-IDENTITY STAMP (board #58, Fork A) — v1 `wrapChild` parity (pin 11866c16 nix/lib/
  # aspects/fx/aspect/normalize.nix:95-119). A navigated aspect value carries `__provider` (the
  # post-fold annotation walk, annotate.nix; v1 annotateDeep, types.nix:561-574); derive
  # `name = last __provider` and `meta.aspect-chain = init __provider` so gen-aspects `identity.key`
  # (`aspectPath = meta.aspect-chain ++ [ name ]`) equals the FULL provider path — the SAME identity
  # from EVERY inclusion path, so N references of one aspect resolve ONCE (forwardExpand's seen-dedup;
  # the u5 multi-reference dedup, e.g. the corpus's 11× nginx). NO REGISTRY LOOKUP: the stamped value
  # CARRIES its content — identity recovery never resolves a name against a registry (the
  # `resolveAspectRef` no-lookup posture below), so a recovered name can never land on an empty record.
  # A value with its OWN `name` keeps it (v1's `!(child ? name)` gate, normalize.nix:96).
  # `id_hash` rides along by the aspectEntry convention over the provider path: the collection stratum
  # reads `content.id_hash` as the A12 producer key (collections.nix) — a native registry aspect gets it
  # from den-hoag's idModule, a compat-normalized include record gets it HERE, so a quirk-emitting
  # aspect delivered via include has a producer identity. ──
  stampProvider =
    v:
    if
      builtins.isAttrs v && !(v ? name) && builtins.isList (v.__provider or null) && v.__provider != [ ]
    then
      v
      // {
        name = prelude.last v.__provider;
        id_hash =
          v.id_hash
            or (builtins.hashString "sha256" ("den-aspect:" + builtins.concatStringsSep "/" v.__provider));
        meta = (v.meta or { }) // {
          aspect-chain = prelude.init v.__provider;
        };
      }
    else
      v;

  # ── v1 NESTED-ASPECT discriminator (the blade.shuo rung) — v1 `nix/lib/aspects/fx/
  # key-classification.nix:69-80` `isNestedKey` + `:49-56` `looksLikeClassContent`, pin 11866c16. ──
  #
  # v1 partitions an aspect's non-structural/non-class/non-quirk keys (classifyKeys, :82-111): a key whose
  # ATTRSET value carries ≥1 RECOGNIZED sub-key — structural, quirk, or class-with-class-like-content — is
  # a NESTED ASPECT (`nestedKeys`); the rest are `unregisteredClassKeys` (typos). A nested aspect is NEVER
  # emitted at the parent's scope (key-classification.nix:67-68: "sub-aspects are never auto-walked … they
  # activate via explicit `includes`") — v1 routes it to the navigable synthetic `_`/provides child
  # (types.nix mergeWithAspectMeta/aspectContentType) and annotates it with a `__provider` path
  # (types.nix:560-574) that IS its identity when navigated (normalize.nix wrapChild:95-119). The corpus
  # manifestation: `den.aspects.<host>.<user>` per-user sub-aspects (blade.nix:51/61, cortex.nix:175/185
  # `sini`/`shuo` — each `{ includes = [ … ]; }`, whose `includes` sub-key is what classifies it nested),
  # consumed ONLY by the dispatch-emitted `user-aspect-auto-include` (corpus defaults.nix:14-22; the
  # translateEffect content-set include arm below).
  #
  # The shim reproduces the discriminator to SPLIT (translateAspect): nested keys are STRIPPED from the
  # parent — strip-ONLY, no registration (Fork-B ruling): the auto-include emission re-reads the value off
  # the bridge's `config.den.aspects` (bridge.nix `_module.args.den`), never off the compiled registry, so
  # a registered sub-aspect would be unreferenced dead weight. A NON-nested unknown key (a typo — value not
  # an attrset, or an attrset with no recognized sub-key) is LEFT IN PLACE and still aborts at the §2.2
  # three-branch dispatch (v1's `unregisteredClassKeys` posture — never a silent swallow). The split now
  # ALSO runs on the include path (`groundRec`, board #58): with provider identities every navigated
  # value's content reaches §2.2, so nested keys are stripped wherever v1's walk would never walk them —
  # including a parametric RESULT (the old out-of-corpus "no nested arm" ceiling, since closed).
  #
  # v1's `unwrapContentValuesForClassification` pre-step is SKIPPED: `__contentValues` wrappers are v1
  # aspectContentType typing the raw bridge never constructs (the same reason `__provider` is absent).
  # `looksLikeClassContent` forces a sub-value to WHNF only under a CLASS-named sub-key — v1's own forcing
  # posture (key-classification.nix:62-64, the #580 flake-fixpoint guard).
  v1StructuralKeysSet = (import ./key-classification.nix { }).structuralKeysSet;
  # den-hoag-only facets (concern-aspects.nix `facets`) that v1's structural set lacks — a parent key
  # named like these is shim vocabulary, never a nested-aspect candidate. KEEP IN SYNC with that list.
  hoagOnlyFacets = [
    "neededBy"
    "tags"
    "projects"
    "key"
    "id_hash"
  ];
  # v1 key-classification.nix:49-56: class-like content is a fn, a __contentValues wrapper, or an
  # attrset with ≥1 attrset/fn/LIST-valued key (or the EMPTY attrset) — rejects non-empty flat-scalar
  # sets that merely shadow a class name. RAW-BOUNDARY WIDENING (board #58, the `lix`/`etcd` frontier):
  # v1 classifies over its TYPED tree, where every class-keyed value is an aspectContentType wrapper and
  # passes via the `__contentValues` arm unconditionally — so v1's attrset arm never judges raw module
  # bodies. The shim's raw boundary DOES: an imports-only class body (`nixos = { imports = [ … ]; }` —
  # corpus core.nix.lix, core.system.disko) carries only a LIST-valued key, and a declared-no-op body
  # (`nixos = { }` — corpus services.k3s.etcd) carries none at all; both would fail v1's literal attrset
  # arm, leaving the nested sub-aspect on its parent to abort §2.2 at every including scope. List-valued
  # keys and the empty body are accepted as class-like; a non-empty flat-SCALAR shadow set is still
  # rejected (the arm's purpose).
  looksLikeClassContent =
    v:
    builtins.isFunction v
    || (builtins.isAttrs v && v ? __contentValues)
    || (
      builtins.isAttrs v
      && (
        v == { }
        || builtins.any (
          k: builtins.isAttrs v.${k} || builtins.isFunction v.${k} || builtins.isList v.${k}
        ) (builtins.attrNames v)
      )
    );
  # `mkIsNestedAspectKey classNames quirkNames` → `attrs: k: bool` — fleet-parameterised (the class set is
  # builtins + declared classes, the quirk set the fleet's channels; same cnf grain as mkNormalize). The
  # parent key `k` is tested POST-grounding (class keys already den-hoag-spelled); a SUB-key is grounded
  # through the same v1ClassKeyMap before the class test (nested content is untouched by the parent fold).
  mkIsNestedAspectKey =
    classNames: quirkNames:
    let
      classSet = prelude.genAttrs classNames (_: true);
      quirkSet = prelude.genAttrs quirkNames (_: true);
      # `__`-prefixed sub-keys are INVISIBLE to the discriminator (board #58): the annotation walk
      # stamps `__provider` (a v1 STRUCTURAL key) onto every unregistered attrset child, so counting it
      # recognized would flip every annotated typo-attrset to nested (silently stripped) — weakening the
      # §2.2 abort posture this discriminator exists to preserve. v1 classifies over UNWRAPPED values
      # (`unwrapContentValuesForClassification`), so its own annotation never feeds its discriminator
      # either; skipping `__*` reproduces that invisibility at the raw boundary.
      recognizedSubKey =
        val: sk:
        !(prelude.hasPrefix "__" sk)
        && (
          v1StructuralKeysSet ? ${sk}
          || quirkSet ? ${sk}
          || (classSet ? ${v1ClassKeyMap.${sk} or sk} && looksLikeClassContent val.${sk})
        );
      isCandidate =
        k:
        !(v1StructuralKeysSet ? ${k})
        && !(builtins.elem k hoagOnlyFacets)
        && !(classSet ? ${k})
        && !(quirkSet ? ${k})
        && builtins.substring 0 2 k != "__";
    in
    attrs: k:
    isCandidate k
    && builtins.isAttrs attrs.${k}
    && builtins.any (recognizedSubKey attrs.${k}) (builtins.attrNames attrs.${k});

  # ── v1 aspect-include WRAP-GROUND builder (§339; cf. v1 `nix/lib/aspects/fx/aspect/normalize.nix`
  #    `wrapChild`/`wrapBareFn`). den-hoag requires a parametric aspect include to be a gen-aspects
  #    `__isWrappedFn` functor; a v1 bare-fn include (`includes = [ ({host,...}: <content>) ]`) is NOT
  #    that shape, so without the wrap it is treated as a static "<anon>" aspect and never invoked. ──
  #
  # `mkNormalize classNames` → `normalizeList prefix refs` — the wrap cnf is PARAMETERISED by the class set
  # so a DECLARED non-built-in class (e.g. `den.classes.wsl`) routes as CLASS content, not a nested aspect.
  # CEILING: a class visible ONLY at fleet-discovery time (beyond R2 compile-time class registration)
  # renders as an inert nested aspect SILENTLY — out-of-corpus (every corpus class arrives via R2,
  # compile-registered); widening it would mean threading the mkDen fleet cnf (the chicken-egg path),
  # deferred until a consumer needs it.
  #
  # DISTINCT WRAP NAMES (silent-drop fix): gen-aspects `wrapFn` sets `meta.loc = [ name ]`, and
  # `identity.key` for a wrapped fn = `pathKey meta.loc` (gen-aspects identity.nix), while resolved-aspects
  # `forwardExpand` SKIPS already-seen keys. So every wrap sharing ONE name (the old `"<include>"`) would
  # collapse to one key and only the FIRST fires — silently dropping sibling includes (define-user's
  # hmContext, and via den.default radiation hostname/inputs'/… ). We thread a per-position NAME PATH
  # (owning-aspect prefix + list index, recursively) so every wrap has a DISTINCT, traceable key.
  mkNormalize =
    classNames: quirkNames:
    let
      # den-hoag's built-in class set PLUS the fleet's declared classes (`den.classes`), enough to route a
      # battery fn's class content (nixos/darwin/home-manager/wsl/…) at class-A.
      wrapCnf = {
        classes = prelude.genAttrs classNames (_: { });
      };
      # The include-path nested-aspect discriminator (board #58) — the SAME cnf grain as translateAspect's
      # registry-side instance; see `groundRec` for why the include path needs its own split.
      isNested = mkIsNestedAspectKey classNames quirkNames;
      # Normalize a `.includes` list, naming each element by its POSITION under `prefix` (distinct keys).
      # The name is built by CONCATENATION (`prefix + ":" + toString i`), NOT by interpolating two values
      # around a colon — that interpolation idiom is the shim's `kind:name` scope-string form, which the
      # compat-identity-boundary lint bans in the core by a blunt byte-match (this is an aspect-include
      # NAME, never a scope-string, but concatenation keeps the core lint-clean regardless).
      normalizeList =
        prefix: refs: prelude.imap0 (i: ref: normalize (prefix + ":" + toString i) ref) refs;
      # STATIC-INCLUDE IDENTITY (board #58 — the "<anon>"-collapse fix, the STATIC twin of the DISTINCT
      # WRAP NAMES fix above). That fix gave the FN arm per-position `meta.loc` keys; the static arm
      # stayed nameless, so every navigated static include keyed `"<anon>"` (gen-aspects `aspectPath`),
      # forwardExpand's seen-dedup kept only the FIRST sibling, transitive chains starved behind their
      # intermediate's key, and the content-driven member spine (output-modules `contentIdsOf`) dropped
      # starved hosts from `nixosConfigurations` entirely — the corpus zero-content diagnosis. Identity:
      # `stampProvider` (v1 wrapChild, normalize.nix:95-119) when the value is annotated; the DISTINCT
      # POSITIONAL name as the annotation-less inline-literal fallback — v1's own nameless posture
      # (children.nix's `<parent>/<anon>:<idx>` rename).
      stampIdentity =
        fallbackName: ref:
        let
          s = stampProvider ref;
        in
        if s ? name then
          s
        else
          s
          // {
            name = fallbackName;
            # the A12 producer key for the positional-fallback arm (see stampProvider's id_hash note).
            id_hash = s.id_hash or (builtins.hashString "sha256" "den-aspect:${fallbackName}");
          };
      # COORD GATE + ARG-SHAPING (v1 canTake parity): v1 fires a child fn ONLY where its every REQUIRED coord
      # is in scope, and calls it with a PRECISELY-shaped coord set. den-hoag's forwardExpand invokes a
      # wrapped fn UNCONDITIONALLY with the full enriched-context (which carries `__entry` + the scope
      # coords), so we replicate v1 INSIDE the wrapper:
      #   • GATE — a formal with no default is REQUIRED (`gen-aspects functionArgs` marks it `false`); if any
      #     required coord is absent (e.g. define-user's `{ host, user }` userContext radiated via
      #     `den.default` to a HOST scope, whose ctx has `host` but NO `user`) emit `{ }` (inert HERE)
      #     instead of THROWING `called without required argument 'user'`. This is v1's `canTake` verbatim
      #     (v1 `nix/lib/can-take.nix`: `required = filter (n: !args.${n}) …`, `satisfied = all (n: params ?
      #     ${n}) required`) — the SAME required-coord gate.
      #   • SHAPE — pass only the fn's declared formals (`intersectAttrs`), so a STRICT fn (no `...`, e.g.
      #     `{ host, user }` / inputs' `{ host }`) does not choke on the ctx's extra `__entry` coord
      #     (`called with unexpected argument '__entry'`). Also v1 `can-take.nix` (`intersect =
      #     intersectAttrs args params`). No corpus battery uses an `@args` capture, so dropping non-formal
      #     coords is safe (a `{ host, ... }` fn only reads named formals anyway).
      # COORD-SET LIMIT (the `class`-coord gap, ledger row `u1`): the ctx we gate on is den-hoag's
      # enriched-context (scope coords + `__entry`) — it carries NO per-class `class` coord. v1, by contrast,
      # BINDS `class = <resolving entity's class>` into the include ctx during its PER-CLASS resolution (v1
      # `bind.nix:41` / `push-scope.nix:26` `// optionalAttrs (entityClass != null) { class = entityClass; }`,
      # `fx/resolve.nix:181/183` `base // { class = entityCls; }` / `{ class = hostClass; }`). So a
      # class-GENERIC include that destructures `{ class, … }` (den.batteries.unfree's `__fn`) has `class`
      # REQUIRED-but-absent here and gates to `{ }` — a latent-v1-divergence pinned by
      # `ci/tests/compat-batteries.nix` `test-unfree-class-coord-inert` + ledger row `u1`.
      callGated =
        name: fn: ctx:
        let
          fa = builtins.functionArgs fn;
          required = builtins.filter (a: !fa.${a}) (builtins.attrNames fa);
        in
        if builtins.all (a: ctx ? ${a}) required then
          # RESULT-TYPE DISPATCH (v1 `mkParametricNext`, aspect.nix:53-93): a parametric aspect's `__fn`
          # RESULT is an ATTRSET → aspect CONTENT (grounded + include-recursed, the corpus branch: agenix's
          # per-class `${host.class}` content), or a LIST → v1's include-effect-ONLY branch (aspect.nix:72-84,
          # which THROWS on any non-include effect). den-compat has NO corpus consumer of the list branch, so a
          # list result is a NAMED abort (self-announcing) rather than speculative include-effect processing.
          let
            result = fn (builtins.intersectAttrs fa ctx);
          in
          if builtins.isList result then errors.parametricListUnsupported name else groundRec name result
        else
          { };
      # A v1 aspect INCLUDE, normalized to the den-hoag shape under a distinct `name`. TRANSITIVE (matching
      # v1's resolve-children re-dispatch → wrapChild re-normalizes a fn RESULT's `.includes`; den-hoag's
      # forwardExpand likewise re-walks `concrete.includes`): a wrapped fn's RESULT and a static aspect's
      # `.includes` both go back through `normalize` (ground class keys, recurse nested bare fns). No
      # infinite loop — the fn recursion is inside the lazy `callGated` closure, forced only per resolution
      # ctx. A `{ __fn; name }` wrapper (unfree) keeps its OWN v1 name (`ref.name`).
      normalize =
        name: ref:
        if builtins.isFunction ref then
          aspects.wrapFn wrapCnf name (callGated name ref)
        else if builtins.isAttrs ref && (ref.__isWrappedFn or false) then
          ref
        else if builtins.isAttrs ref && (ref.__fn or null) != null then
          aspects.wrapFn wrapCnf (ref.name or name) (callGated name ref.__fn)
        else if builtins.isAttrs ref && !(ref ? id_hash) then
          # A STATIC aspect attrset (inline content / a `{ name }` reference): GROUND its class keys and
          # recurse its includes. A `{ __isPolicy; fn }` policy record must NEVER reach here — an include
          # arm partitions it out at its own grain BEFORE normalize (a `den.schema.<kind>.includes` record
          # via `isPolicyRef` → `kindIncludePolicies`; a `den.default.includes` record via
          # `defaultPolicyRefs` → `defaultIncludePolicies`), mirroring v1 (children.nix:70-72:
          # `processInclude`'s FIRST arm routes an `__isPolicy` include to `register-aspect-policy`, never
          # the aspect walk). A record arriving HERE (nested in a NON-default aspect's `.includes`,
          # corpus-zero) grounds to content whose `fn` key aborts at the §2.2 three-branch dispatch —
          # self-announcing, never a silent drop. An id_hash-bearing entry is already a resolved record —
          # pass it (and strings) through the `else`.
          groundRec name (stampIdentity name ref)
        else
          ref;
      # Ground an aspect attrset's class keys, SPLIT OFF its nested sub-aspect keys, AND recurse its
      # `.includes` under a per-position name path — this grounds inputs'/self's nested static
      # `{ homeManager._module.args… }` → `home-manager` and wraps a nested bare fn (transitive), each
      # child keyed distinctly under `${name}:include`.
      #
      # THE NESTED SPLIT (board #58 follow-through): v1 never auto-walks a nested sub-aspect at ANY
      # resolution path — "sub-aspects are never auto-walked … they activate via explicit `includes`"
      # (v1 key-classification.nix:67-68 @ pin) applies during v1's resolve WALK, i.e. to navigated
      # include values exactly as to registry records. The shim's split lived only on the registry path
      # (translateAspect) because pre-#58 a navigated static include never resolved far enough for its
      # content to be classified (the "<anon>" collapse starved it); with provider identities every
      # navigated value's content now reaches §2.2, so a parent aspect carrying nested sub-aspects
      # (corpus `core.nix` with `linux-builder`/…) would abort `aspect declares key <nested>` at the
      # including scope without the split here. Strip-ONLY, same as the registry side (Fork-B): the
      # nested value is re-reachable by explicit navigation, never registered. This also aligns the
      # parametric-RESULT arm with v1 (a result's nested keys nested-classify at resolution — the old
      # "no nested arm" ceiling comment above is superseded by exactly this).
      groundRec =
        name: attrs:
        let
          grounded = groundKeys attrs;
          nestedKeys = builtins.filter (isNested grounded) (builtins.attrNames grounded);
        in
        (builtins.removeAttrs grounded nestedKeys)
        // prelude.optionalAttrs (attrs ? includes) {
          includes = normalizeList "${name}:include" attrs.includes;
        };
    in
    normalizeList;

  # v1 aspect STRUCTURAL keys that do NOT pass through as den-hoag aspect content: `provides` rides the
  # legacy module (Task 4), `policies`/`excludes` are re-expressed here, `__*` are v1 pipeline internals.
  # `__provider` (board #58): the annotation walk stamps it on every aspect-tree node; the REGISTRY
  # record is keyed by its top-level name already, so the path is stripped here — the compiled registry
  # stays byte-identical to the pre-annotation shim (and never carries an untyped list key into
  # den-hoag's `den.aspects` option). Navigated INCLUDE values keep theirs (identity via stampProvider).
  droppedAspectKeys = [
    "provides"
    "policies"
    "excludes"
    "classes"
    "_"
    "__provider"
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
  # producing class+scope, so PR #623 falls out). The rewrites: a bare parametric FUNCTION coerces
  # to `{ includes = [ fn ]; }` (v1's own coercion), `excludes` folds into `meta.drop`, class keys are
  # grounded, NESTED-ASPECT keys are split off (v1 `isNestedKey` — see mkIsNestedAspectKey; strip-only,
  # the emission path re-reads them off the bridge config), and the v1-only structural keys are dropped.
  translateAspect =
    normalizeList: isNestedAspectKey: name: aspect:
    # LEGACY SURFACE SENTINEL (C5): `provides` must have been desugared by legacy/provides.nix (applied
    # by the flakeModule assembly BEFORE compile). If it survives to here the legacy module is severed —
    # fail LOUDLY naming the surface rather than dropping the declaration (sentinels.nix / errors.nix).
    # SURFACE TOTALITY (C1): `meta.__forward` (the batteries.forward manifestation) has no desugar path —
    # a named abort, not a silent passthrough (noBatteriesForward).
    builtins.seq (sentinels.provides name aspect) (
      builtins.seq (noBatteriesForward name aspect) (
        if builtins.isFunction aspect then
          { includes = normalizeList "${name}:include" [ aspect ]; }
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
            # NESTED-ASPECT SPLIT (v1 key-classification.nix:69-80 `isNestedKey`, applied POST-grounding):
            # strip the nested sub-aspect keys (blade's `sini`/`shuo`) from the parent, so the parent's
            # content is pure facet/class/quirk and never trips the §2.2 dispatch at its own scope (v1
            # never auto-walks a nested aspect). Strip-ONLY (Fork-B): the dispatch-emitted include re-reads
            # the sub-aspect off the bridge config and re-wraps it (translateEffect content-set arm). A
            # typo key fails the discriminator and STAYS — aborting at §2.2, v1's unregisteredClassKeys.
            nestedKeys = builtins.filter (isNestedAspectKey grounded) (builtins.attrNames grounded);
            parent = builtins.removeAttrs grounded nestedKeys;
            # Fold `excludes` into `meta.drop` (aspect-level constraint) without clobbering a declared drop.
            meta = parent.meta or { };
            metaWithDrop =
              if excludes == [ ] then parent.meta or null else meta // { drop = (meta.drop or [ ]) ++ excludes; };
            # board #58 KEY-ALIGNMENT: `keyOf` consumers over v1-NAVIGATED aspect values OUTSIDE the
            # include path — literal-form `neededBy` triggers (resolved-aspects `indexByNeededBy`) and
            # `meta.drop`/`excludes` constraint refs (`applyConstraints`/`constraintSeen`) — must see
            # the SAME provider-derived identity the resolved nodes carry, else a provider-keyed
            # resolved set never matches an `"<anon>"`-keyed trigger/drop. Corpus-zero today (the
            # provides desugar emits SELECTOR-form neededBy, legacy/provides.nix:24; corpus `excludes`
            # are policy excludes on schema kinds), stamped for coherence. Provider-ONLY (no positional
            # fallback): a nameless un-annotated literal ref stays `"<anon>"` — v1's own posture.
            stampRefs = map stampProvider;
            metaStamped =
              if metaWithDrop == null then
                null
              else
                metaWithDrop
                // prelude.optionalAttrs (builtins.isList (metaWithDrop.drop or null)) {
                  drop = stampRefs metaWithDrop.drop;
                };
          in
          parent
          // (if metaStamped == null then { } else { meta = metaStamped; })
          // prelude.optionalAttrs (builtins.isList (parent.neededBy or null)) {
            neededBy = stampRefs parent.neededBy;
          }
          // prelude.optionalAttrs (parent ? includes) {
            includes = normalizeList "${name}:include" parent.includes;
          }
      )
    );

  # ── DISPATCH-EMITTED content-set include (the census TWIN path — the revived arm). A v1 policy body
  # emits `policy.include den.aspects.<path>` where the navigated value crosses the raw bridge as a BARE
  # content set (no id_hash/name — the bridge's `anything` drops v1's `__provider` annotation, the same
  # boundary fact the kind-include contentRefs arm documents). Two corpus consumers:
  #   • `user-aspect-auto-include` (defaults.nix:14-22) emits `den.aspects.<host>.<user>` at user cells —
  #     the nested sub-aspects the translateAspect split strips (blade/cortex × sini/shuo);
  #   • `cluster-aspect` (policies/clusters.nix:73) emits `den.aspects.<cluster>` at cluster scopes
  #     (`den.aspects.axon`, clusters/axon.nix:101).
  # The emitted value is GROUNDED through the SAME normalizeList machinery translateAspect uses (class
  # keys grounded, `.includes` children wrapped/recursed — so the sub-aspect's firefox/steam/spicetify
  # includes resolve at the cell). IDENTITY (board #58 supersession of the old scope-coord Fork-A
  # ruling): an ANNOTATED emitted value (one navigated off a `__provider`-stamped tree — the corpus
  # path, since the bridge's `den` module arg is annotated) takes v1's PROVIDER identity (wrapChild,
  # normalize.nix:95-119 — v1 has no separate emitted-identity class), dissolving both old ceilings
  # (cell-identity collision of two emitters at one cell; double-landing of one set referenced from two
  # cells). An annotation-LESS value (closure-captured/synthetic) falls back to the DETERMINISTIC
  # SCOPE-COORD identity: name = `<emitted>@<coord names>`, id_hash over the firing cell's entity-coord
  # id_hashes — stable across eval order, distinct per cell. At the value-less stratum probe the coords
  # are sentinel entries (which carry id_hash/name), so the fallback derivation is probe-safe — though
  # both corpus emitters gate on a real aspect-name match and emit nothing at the probe (expansion path).
  isEmittedContentSet =
    v:
    builtins.isAttrs v
    && !(v ? id_hash)
    && !(v ? name)
    && !(v ? __functor)
    && !((v.__isPolicy or false) || (v.__denCanTake or null) != null);
  mkEmittedAspect =
    normalizeList: ctx: v:
    if builtins.isList (v.__provider or null) && v.__provider != [ ] then
      # PROVIDER IDENTITY (board #58 — supersedes the scope-coord identity for ANNOTATED values). v1
      # applies provider identity to ANY navigated `__provider`-bearing value regardless of arrival
      # path (wrapChild, normalize.nix:95-119) — the emitted arm is not a separate identity class
      # under v1. Both u7 identity CEILINGS dissolve: identity is the VALUE's, not the cell's — a
      # content set referenced from two cells dedups to one resolved node per cell key-space, and two
      # content-set emitters at one cell cannot collide. `name`/`meta.aspect-chain` come from the
      # normalize static arm's stampProvider (grounding rides the SAME normalizeList), which also
      # stamps `id_hash` — the aspectEntry convention over the provider path, deterministic and
      # eval-order-free.
      builtins.head (normalizeList "<emitted>" [ v ])
    else
      # SCOPE-COORD FALLBACK (annotation-less content sets — closure-captured / synthetic values that
      # never crossed an annotated tree): the deterministic per-cell identity, unchanged.
      let
        coordKeys = builtins.sort builtins.lessThan (
          builtins.filter (
            k: builtins.substring 0 2 k != "__" && builtins.isAttrs ctx.${k} && ctx.${k} ? id_hash
          ) (builtins.attrNames ctx)
        );
        name = "<emitted>@" + builtins.concatStringsSep "." (map (k: ctx.${k}.name or "?") coordKeys);
        id_hash = builtins.hashString "sha256" (
          "den-compat-emitted-include:"
          + builtins.concatStringsSep "," (map (k: "${k}=${ctx.${k}.id_hash}") coordKeys)
        );
      in
      builtins.head (normalizeList "${name}:content" [ v ]) // { inherit name id_hash; };

  # Translate ONE v1 policy effect record → den-hoag declaration(s): the structural/resolution
  # vocabulary (include/exclude/resolve + the instantiate spawn). The delivery-edge vocabulary
  # (deliver/route/provide) and the pipe stages ride named seams until their own passes land. Every
  # entry-typed argument is an entry by here (C6), so the `declare.*` constructors' eager identity
  # checks pass; a stray string would abort named. `ctx` (the firing scope's coords) and `normalizeList`
  # serve ONLY the content-set include arm (the scope-coord emission identity + grounding).
  translateEffect =
    ing: normalizeList: aspectRec: ctx: effect:
    let
      kind = effect.__policyEffect or null;
    in
    # A delivery descriptor (deliver/route/provide, deliver.nix) → a den-hoag `delivery` declaration
    # (intent; the gen-edge record is rendered at the firing node by output-modules' edgesAt).
    if effect.__delivery or false then
      [ (translateDelivery ing effect) ]
    else if kind == "include" then
      if isEmittedContentSet effect.value then
        [ (declare.edge (mkEmittedAspect normalizeList ctx effect.value)) ]
      else
        [ (declare.edge (resolveAspectRef aspectRec effect.value)) ]
    else if kind == "exclude" then
      # An aspect exclude prunes an aspect edge (`drop`). A POLICY exclude (`__denCanTake`/`__isPolicy`/
      # function target) suppresses a policy's FIRING — a distinct mechanism (v1 `drop-user-to-host-on-droid`,
      # nix-on-droid.nix, excludes the os-user `user-to-host` route), deferred to class-B/#50 with a named
      # abort (never a misleading identity-law abort at `resolveAspectRef`).
      let
        v = effect.value;
        isPolicyTarget =
          builtins.isFunction v
          || (builtins.isAttrs v && ((v.__denCanTake or null) != null || (v.__isPolicy or false)));
      in
      if isPolicyTarget then errors.excludeOfPolicy else [ (declare.drop (resolveAspectRef aspectRec v)) ]
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

  # den-hoag policy RECORD `{ __condition; fn }`. `fn` is a bare `ctx:` wrapper translating the v1 inner
  # fn's effects to declarations; `__condition` is the DECLARED gate — the inner fn's own `functionArgs`
  # (v1's destructured coords) — so den-hoag's dispatch fires the policy exactly where those coordinates
  # are present, WITHOUT the bare-ctx wrapper having to carry the formals. (den-hoag reads a rule's gate
  # from a lambda's literal `functionArgs`; a `ctx:` wrapper erases them, so the record declares the gate
  # as DATA instead — the general policy vocabulary for a generated policy that cannot shape its formals.)
  # The translation of each effect is eager only when the body runs (per ctx); compile itself never runs
  # it. A `for`/`when` policy record (`{ __isPolicy; fn }`) contributes its inner `fn`'s formals + effects
  # the same way (`innerFn`). A value-conditional body (emits nothing at concern-policies' value-less
  # probe) has its stratum derived per-declaration there; this compile stays stratum-agnostic.
  compilePolicy = ing: normalizeList: aspectRec: value: {
    __condition = builtins.functionArgs (innerFn value);
    fn = ctx: prelude.concatMap (translateEffect ing normalizeList aspectRec ctx) (innerFn value ctx);
  };

  # A `__denCanTake` policy — the FORMAL-PRESERVING compile path (the twin of the bare-ctx `compilePolicy`
  # for policies whose OWN destructuring must gate dispatch, not an internal for/when guard). A shim
  # built-in route (os-to-host / user-to-host, legacy/batteries) declares `{ __denCanTake = <shape>; fn =
  # { <coords>, ... }: [ effects ]; }`. This wraps `fn` with the SHAPE's LITERAL formals — so den-hoag's
  # `dispatch.fromFunction` reads them as the canTake condition (the policy fires only where those
  # coordinates are in scope) AND concern-policies' stratum probe fills them with sentinel entries, so the
  # route's UNCONDITIONAL emission classifies as RESOLUTION. Nix cannot build a formal set from a runtime
  # list, so the shapes are a small fixed set — the two the corpus's built-in routes need.
  #
  # THE GENERAL PATTERN + HAZARD (not os-specific): concern-policies classifies a policy's stratum by
  # PROBING it at a VALUE-LESS sentinel context. So any policy whose emission is CONDITIONAL on a ctx VALUE
  # (not just coordinate PRESENCE) emits nothing at the probe → is misclassified as an enrich policy → and,
  # when it fires at a real scope and produces a resolution declaration (delivery/edge) in the enrich
  # stratum, CRASHES LOUDLY (`attribute 'key' missing` in the enrich delta). The fix for the built-in
  # routes is this path (emit UNCONDITIONALLY given the canTake coordinates, gate on PRESENCE only; a
  # value-absent target renders a `__dropped` no-op — translateDelivery). A CORPUS USER policy that emits
  # value-conditionally will hit the same misclassification — a C8 watch item: it aborts loudly by design
  # (never silently mis-fires), and the resolution is to rewrite it in the canTake + null-target-drop shape.
  compileCanTake = ing: normalizeList: aspectRec: value: {
    # The route's fixed SHAPE retires into an explicit `__condition` coord set — the coords it gates
    # on, in the `functionArgs` shape (`false` = required). A hand-written formal lambda per shape is no
    # longer needed now that a rule's gate can be declared as data.
    __condition =
      if value.__denCanTake == "host" then
        { host = false; }
      else if value.__denCanTake == "user-host" then
        {
          user = false;
          host = false;
        }
      else
        errors.unsupportedEffect "canTake:${value.__denCanTake}";
    # Emits UNCONDITIONALLY given its coordinates (a single-group probe classifies it as resolution); a
    # value-absent target renders a `__dropped` no-op (translateDelivery).
    fn = ctx: prelude.concatMap (translateEffect ing normalizeList aspectRec ctx) (value.fn ctx);
  };

  compilePolicies =
    ing: normalizeList: aspectRec: policies:
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
        prelude.genAttrs policyNames (name: compilePolicy ing normalizeList aspectRec policies.${name})
        // prelude.genAttrs canTakeNames (
          name: compileCanTake ing normalizeList aspectRec policies.${name}
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
  ing = ingest.ingest v1Decls;
  v1Aspects = v1Decls.aspects or { };
  v1Policies = v1Decls.policies or { };
  v1Classes = v1Decls.classes or { };

  # The include-normalizer for THIS fleet: the wrap cnf carries den-hoag's built-in classes PLUS the
  # fleet's DECLARED classes (`den.classes` — e.g. `wsl`), so a bare-fn include emitting a declared-class
  # key routes as CLASS content, not a nested aspect (Fork A). `v1Classes` is fleet-scoped, so this must
  # live in the function body (where the decls are), not at top level.
  allClassNames = builtinClasses ++ builtins.attrNames v1Classes;
  normalizeList = mkNormalize allClassNames (builtins.attrNames (v1Decls.quirks or { }));
  # The nested-aspect discriminator for THIS fleet (same cnf grain as normalizeList): the quirk set is
  # the fleet's declared channels, so `blade.firewall` classifies quirk while `blade.shuo` splits nested.
  isNestedAspectKey = mkIsNestedAspectKey allClassNames (builtins.attrNames (v1Decls.quirks or { }));

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

  # ── Aspect-include POLICY-RECORD arm (the `den.default.includes` grain). v1: `processInclude`'s FIRST
  # arm routes a `{ __isPolicy }` include to `register-aspect-policy` — never the aspect walk (children
  # .nix:70-72); the registered policy then fires scope-locally where registered (policy/default.nix:96-97
  # "Policies fire where they're registered — scope-local only"). The corpus manifestation: nix-config
  # nix-on-droid.nix:104 puts the bridge-coerced `den.policies.drop-user-to-host-on-droid` record in
  # `den.default.includes`. Without this arm the record fell to translateAspect's static-aspect groundRec
  # branch and its `fn` key aborted at the §2.2 three-branch key dispatch.
  #
  # PARTITION the records out of `__default`'s includes BEFORE translateAspect (a policy record must never
  # become aspect content) and compile each through the SAME `compilePolicy` machinery as the kind-include
  # arm (R3/R14 consistency — the kind-include precedent applies identically at this grain), gated on
  # `{ host = false; }`: the `__default` radiation coord `__denDefault` itself gates on (ONE coord, not a
  # per-kind fan-out — see above, a fan-out double-radiates at the user cell). v1 registers the record at
  # every scope `den.default` radiates to ({host, user, home}) and fires it THERE; for the fleet-radiated
  # default aspect the host-coord gate is the SAME firing set (ledger row u3: kind-scoped == scope-local
  # here; board #57 unmoved — this arm adds no general scope-local mechanism).
  #
  # DOUBLE-FIRE (accepted — the kind-include precedent verbatim, see the `policies` fold note below): a
  # record that is ALSO a `den.policies.<name>` keeps BOTH firings (its fleet-wide `compiledPolicies`
  # entry AND this `__default__policy__<i>` entry); an inline-only record (an mkPolicy value never
  # registered under `den.policies`, corpus-zero) fires solely here — self-documenting coverage for the
  # future inline case.
  defaultIncludes = (v1Decls.default or { }).includes or [ ];
  defaultPolicyRefs = builtins.filter isPolicyRef defaultIncludes;
  defaultNonPolicyDecl =
    (v1Decls.default or { })
    // prelude.optionalAttrs ((v1Decls.default or { }) ? includes) {
      includes = builtins.filter (r: !(isPolicyRef r)) defaultIncludes;
    };
  defaultIncludePolicies = builtins.listToAttrs (
    prelude.imap0 (i: ref: {
      name = "__default__policy__${toString i}";
      value =
        let
          base = compilePolicy ing normalizeList aspectRec ref;
        in
        base
        // {
          __condition = {
            host = false;
          }
          // base.__condition;
        };
    }) defaultPolicyRefs
  );

  defaultAspects =
    if hasDefault then
      { __default = translateAspect normalizeList isNestedAspectKey "__default" defaultNonPolicyDecl; }
    else
      { };
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

  compiledPolicies = compilePolicies ing normalizeList aspectRec v1Policies;

  # Kind-attached includes (`den.schema.<kind>.includes`) → per-kind, per-ref den-hoag declarations,
  # classified PER REF exactly as v1's `wrapChild` (`aspects/fx/aspect/normalize.nix`, @ pin 11866c16). v1's
  # DISCRIMINATOR is the record coercion (a `den.policies.<name>` reference is a `{ __isPolicy }` RECORD,
  # policy-type.nix; a local lambda is a bare fn), so this partitions into THREE arms:
  #   • STATIC aspect refs (an entry / `{ name }` / string, or a `__functor`'d aspect record — v1
  #     `wrapFunctorChild`) → the ONE `__kindInclude__<kind>` edge policy, gated on the KIND coord so it fires
  #     at every instance of the kind (v1's fires-at-kind). An unresolvable ref (not entry/{name}/string NOR a
  #     bare fn NOR a policy record — e.g. an int) keeps `resolveAspectRef`'s named identity abort (R9).
  #   • a POLICY RECORD (`{ __isPolicy; fn }` — `mkPolicy`/`for`/`when`, or a coerced `den.policies` reference;
  #     `{ __denCanTake }` built-in route) → its own `__kindInclude__<kind>__policy__<i>` RECORD via
  #     `compilePolicy`, with the KIND coord UNIONED into its declared gate so it fires at the kind's nodes
  #     even if the fn does not destructure the kind entity. A value-conditional record (env-to-clusters'
  #     cluster-match) emits nothing at the value-less probe → concern-policies derives its stratum per
  #     declaration (no misclassification).
  #   • a BARE FUNCTION → a PARAMETRIC ASPECT (R14 correction; v1 `wrapBareFn` normalize.nix:62-82, NOT a
  #     policy). It wraps through the EXISTING `normalizeList`/`wrapFn`/`callGated` machinery and registers as
  #     a SYNTHETIC ASPECT (`__kindInclude__<kind>__aspect__<i>`, a positional identity — the collision-fix
  #     naming) which the SAME `__kindInclude__<kind>` edge policy then edges. `forwardExpand` invokes the
  #     wrapped fn with the real node ctx (`callGated` gates on coord presence + arg-shapes); its RESULT is
  #     type-dispatched (`callGated`, per v1 `mkParametricNext`): an ATTRSET is aspect CONTENT (agenix's
  #     per-class `${host.class}`), a LIST is a NAMED abort (out-of-corpus). This routes a content-returning
  #     bare-fn kind-include (agenix's `agenixHostAspect`) as CONTENT, never through `compilePolicy` (whose
  #     `concatMap` on effects would choke on it) — the agenix rung.
  isPolicyRef =
    ref: builtins.isAttrs ref && ((ref.__isPolicy or false) || (ref.__denCanTake or null) != null);
  # A bare-fn kind-include (the R14 parametric-aspect arm): a function that is not a policy record.
  isBareFnRef = ref: builtins.isFunction ref && !(isPolicyRef ref);
  # A bare CONTENT-SET kind-include ref: a static aspect VALUE inlined with NO id_hash/name — v1's
  # `den.aspects.<path>` navigation carries a `__provider` annotation (den aspects/types.nix) that the raw
  # bridge (`_module.args.den = config.den`) drops, so the reference arrives as bare class/quirk-keyed
  # content (`{ nixos = …; }` / `{ devshell = …; }` / `{ resolved-users = …; }`). It is not resolvable by
  # resolveAspectRef; it rides the SAME synthetic-aspect arm as a bare fn (positional identity, grounded
  # content). CEILING (positional ≠ v1's __provider name — Fork-A): a content set referenced TWICE would land
  # DUPLICATE content (v1 dedups by provider name; the shim cannot mechanically guard — content-set equality
  # is unassertable with fns inside). OUT-OF-CORPUS: every corpus content-set ref is single-referenced. The
  # UPGRADE PATH is a bridge-side __provider-style annotation recovering v1's identity + dedup (the
  # composition seam if a multi-ref consumer or the dedup need ever surfaces).
  #
  # CORPUS CENSUS (nix-config @ b0b20769) — 9 static content-set kind-include refs (all single-referenced):
  #   host:        core/network/firewall-collector.nix:2, core/secrets (defaults.nix:8-9)
  #   user:        core/users/resolved-user-emitter.nix:4, core/network/syncthing/peers.nix:58
  #   flake-parts: aspects/devshell/{kubernetes.nix:27, secrets.nix:22, images.nix:22}, batteries/{nix-on-droid.nix:217 (deploy-slab), colmena.nix:132}
  # TWIN (the DISPATCH-EMITTED include path — `translateEffect` `kind == "include"` now routes a
  # policy-EMITTED bare `den.aspects.<x>` value through `mkEmittedAspect`, the scope-coord-identity
  # re-wrap; ledger row u7): corpus census — CORRECTED 2026-07-10; the earlier census here claimed
  # `user-aspect-auto-include` was CORPUS-ZERO, FALSIFIED by the blade §2.2 abort (the grep missed the
  # nested keys inside the host-aspect blocks) —
  #   • `user-aspect-auto-include` (defaults.nix:14-22, `den.aspects.<host>.<user>`) FIRES at FOUR corpus
  #     sites: blade.nix:51/61 + cortex.nix:175/185 (hosts blade/cortex × users sini/shuo, each a nested
  #     `{ includes = […]; }` sub-aspect). Served by THIS rung: translateAspect splits the nested keys off
  #     the parent (mkIsNestedAspectKey) and the include arm re-wraps the emitted value with the
  #     deterministic cell identity (`<emitted>@blade.shuo` ≠ `<emitted>@cortex.shuo`).
  #   • `cluster-aspect` (policies/clusters.nix:73 — path corrected from the old `clusters.nix:79` cite,
  #     `den.aspects.<cluster>`) fires for `den.aspects.axon` (clusters/axon.nix:101): the SAME arm,
  #     SINGLE-EMISSION per cluster (identity `<emitted>@axon`; dedup moot).
  #   Multi-reference dedup stays board #58 (the __provider registry restructure, row u5) — the emission
  #   identity here is the CELL's re-wrap, deliberately NOT v1's __provider name.
  isContentRef =
    ref:
    builtins.isAttrs ref
    && !(ref ? id_hash)
    && !(ref ? name)
    && !(ref ? __functor)
    && !(isPolicyRef ref)
    && !(isInlineAspect ref);

  # An INLINE ASPECT ref in a `den.schema.<kind>.includes` list: an attrs carrying content inline (v1's
  # `{ policies; includes }` battery, nix/lib/home-env.nix `makeHomeEnv`) rather than a resolvable
  # REFERENCE (entry / `{ name }` / string) or a policy record. v1 normalize.nix `wrapChild` passes this
  # shape through UNCHANGED (it is not a function, has no `__contentValues`/`__provider`), then the aspect
  # pipeline processes its `.includes` children and NAME-KEYS its `.policies` — the same name in both is
  # why v1's effective firing is ONE. The shim reproduces that: EXPAND the inline aspect — HOIST its
  # `.includes` into the ref list (recursively, so a hoisted `{ __isPolicy; fn }` reaches the policy-ref
  # branch and rides `compilePolicy` → concern-policies' per-declaration expansion — the 8e2f8c8
  # machinery, no new dispatch mechanism) and DROP its `.policies` as a VERIFIED DUPLICATE. Two loud
  # guards keep the drop honest (silent-partition ban): (A) every `.policies.<name>` must be name-matched
  # by a `.includes` `__isPolicy` record; (B) any key beyond {includes, policies} (class content) aborts.
  isInlineAspect =
    ref:
    builtins.isAttrs ref
    && !(ref ? id_hash)
    && !(ref ? name)
    && !(ref ? __functor)
    && !(isPolicyRef ref)
    && (ref ? includes || ref ? policies);
  expandInlineAspect =
    ref:
    let
      unknownKeys = builtins.filter (k: k != "includes" && k != "policies") (builtins.attrNames ref);
      checkedKeys = if unknownKeys == [ ] then true else errors.inlineAspectUnknownKeys unknownKeys;
      # GUARD A: the `.includes` `__isPolicy` record names — the set the `.policies` drop must be covered by.
      includeNames = builtins.filter (n: n != null) (
        map (i: if builtins.isAttrs i && (i.__isPolicy or false) then i.name or null else null) (
          ref.includes or [ ]
        )
      );
      unmatched = builtins.filter (n: !(builtins.elem n includeNames)) (
        builtins.attrNames (ref.policies or { })
      );
      checkedDup =
        if unmatched == [ ] then true else errors.inlineAspectPolicyUnmatched (builtins.head unmatched);
    in
    builtins.seq checkedKeys (builtins.seq checkedDup (ref.includes or [ ]));
  # Recursively hoist inline aspects out of a kind-include ref list (the corpus battery is one level;
  # a nested inline aspect folds). A non-inline ref passes through untouched for the partition below.
  expandRefs =
    rs: prelude.concatMap (r: if isInlineAspect r then expandRefs (expandInlineAspect r) else [ r ]) rs;

  kindInclude =
    let
      perKind =
        kind: rawRefs:
        let
          refs = expandRefs rawRefs;
          kindCoord = {
            ${kind} = false;
          };
          policyRefs = builtins.filter isPolicyRef refs;
          bareFnRefs = builtins.filter isBareFnRef refs;
          contentRefs = builtins.filter isContentRef refs;
          staticRefs = builtins.filter (r: !(isPolicyRef r) && !(isBareFnRef r) && !(isContentRef r)) refs;
          # SYNTHETIC-ASPECT ARM (R14 parametric aspect + the content-set sibling). Each bare FN and each bare
          # CONTENT SET wraps through the SAME normalizeList machinery translateAspect uses and registers as a
          # SYNTHETIC ASPECT under a positional identity (the collision-fix naming — distinct id_hash per index
          # via `ing.aspectEntry`), which the SAME edge policy edges at every kind instance. No new dispatch
          # mechanism:
          #   • a bare FN → `{ includes = normalizeList … [ fn ] }` — the wrapped fn is the aspect's sole
          #     include, invoked with the real node ctx at forwardExpand → callGated → grounded ATTRSET content.
          #   • a bare CONTENT SET → `head (normalizeList … [ set ])` = the GROUNDED content DIRECTLY (a plain
          #     class/quirk-keyed aspect body, the shape a `den.aspects.<x>` reference resolves to in v1) — so
          #     the edge to it folds its class content like any registered aspect (no fn to invoke).
          #   FNs are indexed FIRST, so existing bare-fn synths keep their `__aspect__<i>` names (byte-stable).
          synthRefs = bareFnRefs ++ contentRefs;
          synthAspects = builtins.listToAttrs (
            prelude.imap0 (
              i: ref:
              let
                synthName = "__kindInclude__${kind}__aspect__${toString i}";
              in
              {
                name = synthName;
                value =
                  if builtins.isFunction ref then
                    { includes = normalizeList "${synthName}:include" [ ref ]; }
                  else
                    builtins.head (normalizeList "${synthName}:content" [ ref ]);
              }
            ) synthRefs
          );
          # The kind's ONE edge policy edges the STATIC refs AND the synthetic aspects (by name → full record
          # via aspectRec), gated on the KIND coord so it fires at every instance (unchanged for static-only).
          edgeRefs = staticRefs ++ map (n: { name = n; }) (builtins.attrNames synthAspects);
          aspectPolicy = prelude.optionalAttrs (edgeRefs != [ ]) {
            "__kindInclude__${kind}" = {
              __condition = kindCoord;
              fn = _ctx: map (ref: declare.edge (resolveAspectRef aspectRec ref)) edgeRefs;
            };
          };
          policyPolicies = builtins.listToAttrs (
            prelude.imap0 (i: ref: {
              name = "__kindInclude__${kind}__policy__${toString i}";
              value =
                let
                  base = compilePolicy ing normalizeList aspectRec ref;
                in
                base // { __condition = kindCoord // base.__condition; };
            }) policyRefs
          );
        in
        {
          policies = aspectPolicy // policyPolicies;
          aspects = synthAspects;
        };
      perKinds = map (kind: perKind kind ing.kindIncludes.${kind}) (builtins.attrNames ing.kindIncludes);
    in
    {
      policies = prelude.foldl' (acc: pk: acc // pk.policies) { } perKinds;
      aspects = prelude.foldl' (acc: pk: acc // pk.aspects) { } perKinds;
    };
  kindIncludePolicies = kindInclude.policies;
  # Synthetic aspects for the bare-fn kind-include arm (R14) — registered alongside the v1/default/conditional
  # aspects so aspectRec resolves the edge policy's `{ name }` refs to full records (content + identity). They
  # depend only on normalizeList (⊥ aspectRec), so the `policies → aspectRec → aspects` DAG is preserved.
  kindIncludeAspects = kindInclude.aspects;

  aspects =
    builtins.mapAttrs (translateAspect normalizeList isNestedAspectKey) v1Aspects
    // defaultAspects
    // compiledPolicies.conditionalAspects
    // kindIncludeAspects;

  # The synthetic `__kindInclude__<kind>[__policy__<i> | __aspect__<i>]` / `__denDefault` /
  # `__default__policy__<i>` names cannot collide with a compiled `den.policies.<name>` (nor a v1 aspect):
  # den reserves the `__` prefix for internal keys, and a v1 policy/aspect name is a user-authored
  # identifier that never uses it — so this namespace is disjoint from `compiledPolicies` (and each
  # positional arm is disjoint within itself by index). A v1 policy declared in BOTH `den.policies` AND an
  # includes reference — a `den.schema.<kind>.includes` entry OR a `den.default.includes` entry — keeps
  # BOTH firings (its fleet-wide `compiledPolicies` entry AND its include-scoped `__kindInclude`/
  # `__default__policy` entry); only a reference-only include (an inline record never registered as a
  # `den.policies.<name>`) fires solely via its include arm. `kindIncludePolicies` and
  # `defaultIncludePolicies` are already flat name→policy sets.
  policies =
    compiledPolicies.policies // defaultPolicy // kindIncludePolicies // defaultIncludePolicies;

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
    # `reservedKeys` (den v1 `den.reservedKeys`, key-classification.nix:34) — a CONFIG-only v1 key the shim
    # ACCEPTS and IGNORES: it extends v1's structuralKeysSet, which the compat keyClassification export
    # (#49-slice) reproduces STATICALLY (baked `[ "settings" ]`, the corpus's value). No concern reads it, so
    # it is a known surface (never a typo) but has no ingest/compile handler.
    "reservedKeys"
    # `batteries` (den v1 `den.batteries.<name>`, modules/aspects/batteries/) — the shim provisions the
    # corpus-consumed batteries at `config.den.batteries.<name>` (lib/compat/batteries.nix). Their VALUES
    # are inert data consumed BY REFERENCE via `den.default.includes` / a user aspect's includes (the v1
    # posture — an UNREFERENCED battery is inert in v1 too), so the KEY is accepted and ignored: no concern
    # reads `den.batteries` itself (a referenced battery rides the include list, not this key), exactly like
    # `reservedKeys`.
    "batteries"
  ]
  ++ declaredKinds
  # M1.5: the marker-discovered custom-kind instance namespaces (a v1 config CHOOSES the registry key, e.g.
  # `den.clusters` for kind `cluster` — ingest discovers it by id_hash, never by name), PLUS the
  # bridge-passed DECLARED non-kind config namespaces (`den._declaredKeys`, e.g. `secretsConfig`, extracted
  # from the flake-parts option surface). Both are LEGITIMATE declared surfaces; a typo is neither (it is
  # freeform-absorbed, undeclared, and holds no instance registry), so it still aborts named — strict R9
  # totality preserved, not widened. mkDen-direct fixtures set neither; the discovered set alone classifies.
  ++ ing.discoveredRegistryKeys
  ++ (v1Decls._declaredKeys or [ ]);
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
      instantiateFor
      # fork (i): the full per-host schema-typed harvest (lazy; `_hostHarvest` via the bridge) —
      # `instantiateFor` reads its `.instantiate`; the later per-host grains read the SAME eval.
      hostHarvest
      hostClassName
      hostSystemName
      hostHostName
      # board #59: the harvest-carried per-host field record (settings/networking/ipv4/…) —
      # flake-module.nix `instanceConfig` stamps it onto the host entity beside class/system/hostName.
      hostEntityFields
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
