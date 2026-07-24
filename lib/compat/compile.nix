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
  # gen-schema's content-address FORMULA (schema.hashIdentity) — the SINGLE definition the registry factor
  # nodes hash through (gen-schema identity.nix:16). `idHashOf` routes through it so the resolve-arm's
  # name-preimage aligns to the factor nodes BY CONSTRUCTION, not by a coincident literal copy.
  schema,
  # The `den-aspect:` namespace-identity preimage (§A2), from den-hoag's kernel single-authority
  # (denHoag.aspectIdHash) — the compat aspect-edge sites recompute the SAME id_hash the kernel stamps.
  aspectIdHash,
  # THE RESOLVE-FAMILY TAG SET (user-delivery R2 REQUIREMENT 2, `den.resolveFamilyNames`) — threaded HERE
  # so the KIND-INCLUDE / DEFAULT-INCLUDE policy arms can stamp `__resolveFamily = true` on a compiled
  # include policy whose SOURCE REF's v1 name is in the set. A resolve policy wired via
  # `den.schema.<kind>.includes` compiles to a SYNTHETIC key, so concern-policies' `name ∈ resolveFamilyNames`
  # match never catches it (its key is not the v1 name) — the stamp is the ONLY path for the corpus's five
  # kind-include resolve policies to reach the staged pre-pass's resolve-family feed. The names are a v1
  # CORPUS FACT (the SINGLE source is compat/resolve-family-names.nix, shared with flake-module's
  # `resolveFamilyModule`); native callers pass `[ ]` (the default), byte-identical. ZERO NEW corpus
  # knowledge beyond the existing knob — compile matches the SAME set the knob carries.
  resolveFamilyNames ? [ ],
  # THE EXCLUDE-FAMILY TAG SET (#72, candidate A — `den.excludeFamilyNames`, the resolveFamilyNames
  # twin; single source compat/exclude-family-names.nix). Same posture: the include-arm stamp is the
  # only path for a corpus excluder wired through an include (its compiled key is synthetic).
  excludeFamilyNames ? [ ],
  # den.features compat-desugar-arm gates (Tier-1, register compat-feature-register.md). Both default ON,
  # so a native/non-flag caller keeps the unconditional surface (all-on ≡ pre-feature, byte-identical).
  # `aspectIncludeArm` — the `{ __isPolicy }`-in-a-regular-aspect's-`.includes` diversion arm: off collapses
  # `aspectIncludeRecords → [ ]` so a policy record in an aspect include hits `unregisteredPolicyInclude`
  # (a named abort). AMBIENT-COUPLED: the always-on `defaults` battery coerces os-to-host/user-to-host into
  # this arm, so off REQUIRES `ambientBatteries` off too (the coupling the removability gate names).
  # `lateDispatch` — the descendant-formal bare-fn radiation arm: off makes `radiatedBareFn = _: false`
  # (a `{ host, user }` include stays node-local, firing in place via the shared `normalize` wrap-ground
  # path) and collapses `aspectIncludeBareFns → [ ]`. Clean byte-baseline (no ambient raw late-dispatch fn).
  aspectIncludeArm ? true,
  lateDispatch ? true,
}:
let
  # Stamp `__resolveFamily = true` iff a policy REF's v1 name is in `resolveFamilyNames` — the R2 tag
  # propagation through kind-include / default-include compilation. `ref.name` is the coerced
  # `{ __isPolicy; name; fn }` record's v1 name (a `{ __denCanTake }` route ref carries none → null → no
  # stamp). The match is at the REF, not the synthetic compiled attr name concern-policies would see.
  resolveFamilyStamp =
    ref:
    prelude.optionalAttrs (builtins.elem (ref.name or null) resolveFamilyNames) {
      __resolveFamily = true;
    };
  # The #72 twin — `__excludeFamily` for a `suppress`-emitting corpus excluder wired via an include.
  excludeFamilyStamp =
    ref:
    prelude.optionalAttrs (builtins.elem (ref.name or null) excludeFamilyNames) {
      __excludeFamily = true;
    };
  familyStamps = ref: resolveFamilyStamp ref // excludeFamilyStamp ref;

  # #72 — THE SUPPRESSION GATE (v1 dispatch-policies.nix:15-33: dispatch filters `aspectPolicies` by
  # name against the scoped exclude constraints). den-hoag rendering: the pre-pass's suppression sets
  # ride the emitting root's decls as `__denSuppressedPolicies` (default.nix scopeRoots), inherited-
  # context threads them to descendants, and every compiled rule whose v1 NAME is known consults the key
  # before producing — a suppressed policy fires as `[ ]` at that scope subtree, exactly v1's filter.
  # The v1 NAME (not the synthetic compiled key) is the match, so include-arm rules gate correctly.
  # `null` name (an anonymous include fn) ⇒ ungateable ⇒ identity (v1's filter is name-keyed too).
  gateSuppression =
    v1Name: compiled:
    if v1Name == null then
      compiled
    else
      compiled
      // {
        fn =
          ctx: if builtins.elem v1Name (ctx.__denSuppressedPolicies or [ ]) then [ ] else compiled.fn ctx;
      };
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
        # v1 annotates the parent-targeting flag on the edge (routeEdge baseAnnotations, pin
        # fx/edges/route.nix:813 `optionalAttrs appendToParent { appendToParent = true; }`).
        // prelude.optionalAttrs (d.appendToParent or false) { appendToParent = true; }
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
      # #53c — the parent-targeting flag (v1 route.nix:364 `route.appendToParent or false`);
      # `deliveryTargetRootOf` (output-modules.nix) resolves the containment-parent target from it.
      appendToParent = d.appendToParent or false;
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
  # The SINGLE source is `v1-class-key-map.nix` (shared with flake-module's §2.2 raw-totality `groundK`);
  # a v1 `homeManager` body grounds to den-hoag's registered `home-manager` class here (R2).
  v1ClassKeyMap = import ./v1-class-key-map.nix;

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
  # Under the single typed tree a class-keyed value is a deferredModule WRAP (`{ imports = [ … ]; }`), and
  # gen-aspects materializes EVERY registered class key on EVERY aspect — an UNSET class defaults to the EMPTY
  # wrap `{ imports = [ { } ]; }`. That empty wrap must NOT count as class-like content: else a typo attrset
  # (`nixxos = { networking… }`, typed with all-empty class defaults) would flip `recognizedSubKey` true on
  # its default `nixos` sub-key and mis-classify NESTED (silently stripped) instead of aborting §2.2. The
  # shared `module-shape.nix` helper peels the wrap + judges emptiness (one source with class-modules).
  inherit (import ../module-shape.nix { inherit prelude; }) isEmptyDeferredModule;
  looksLikeClassContent =
    v:
    builtins.isFunction v
    || (builtins.isAttrs v && v ? __contentValues)
    || (
      builtins.isAttrs v
      && !(v ? imports && isEmptyDeferredModule v)
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
      # #74 (the u22-family fix): the PARENT candidate exclusion follows V1'S AUTHORED registry, not the
      # grounded set. v1's `isClassKey k = classRegistry ? k` reads den.classes AS DECLARED (pin
      # key-classification.nix:101 — the hm battery registers camelCase `homeManager`,
      # modules/aspects/batteries/home-manager.nix:33), so the kebab key `home-manager` is NOT a v1
      # class key — it is a nested-aspect CANDIDATE, and the corpus's `core.users.home-manager` aspect
      # (roles/default.nix:16 — an aspect NAMED like the grounded class, carrying os/nixos/darwin
      # sub-keys) classifies NESTED (stripped from `core.users`, activated via its explicit include).
      # The shim's grounded classSet carries BOTH spellings, so the kebab key was wrongly class-excluded
      # and the WHOLE record landed in the host's home-manager bucket — inert until #74a delivered that
      # bucket per-user (`home-manager.users.<u>.darwin` does not exist — the re-probe abort). A
      # grounded-ONLY spelling (a v1ClassKeyMap VALUE that is not also a v1 authored name) is therefore
      # candidate-ELIGIBLE; its content still decides (a plain-content `home-manager` key has no
      # recognized sub-keys ⇒ NOT nested ⇒ class content — the native den-hoag shape unchanged).
      # CEILING (corpus-zero, documented): an authored camelCase `homeManager` key is grounded to kebab
      # BEFORE this test, so a camel-authored key with nested-shaped content would ALSO classify nested
      # where v1 calls it class content — v1's behavior for that shape delivers os/nixos records into
      # the hm bucket (the exact explosion this fix removes), so the shim's treatment is strictly saner.
      v1GroundedOnlySpellings = builtins.filter (v: !(v1ClassKeyMap ? ${v})) (
        builtins.attrValues v1ClassKeyMap
      );
      isCandidate =
        k:
        !(v1StructuralKeysSet ? ${k})
        && !(builtins.elem k hoagOnlyFacets)
        && (!(classSet ? ${k}) || builtins.elem k v1GroundedOnlySpellings)
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
    classNames: quirkNames: divertedPolicyNames: radiatedBareFn:
    let
      # The include-path nested-aspect discriminator (board #58) — the SAME cnf grain as translateAspect's
      # registry-side instance; see `groundRec` for why the include path needs its own split.
      isNested = mkIsNestedAspectKey classNames quirkNames;
      # ── ASPECT-INCLUDE POLICY-RECORD DIVERSION (#65, ledger u16 — v1 children.nix:70-72 parity). ──
      # v1 `processInclude`'s FIRST arm routes ANY `{ __isPolicy }` include to `register-aspect-policy`,
      # never the aspect walk (pin 11866c16 aspect/children.nix:70-72) — at EVERY resolution path
      # (registry record, emitted value, parametric result). The shim twin: a policy record in an aspect
      # `.includes` is FILTERED out of the walk here (pre-#65 it fell to `groundRec` and its `fn` key
      # aborted at §2.2 — the ledger-u15 frontier, corpus users/sini.nix:4 → the host-aspects battery) and
      # fires via its compiled `__aspectInclude__<name>` rule instead (`aspectIncludePolicies` — collected
      # by the STATIC walk over the SAME `den.aspects`/`den.default.includes` trees every arrival path
      # re-reads; the walk seeds `divertedPolicyNames`). A record the walk did NOT collect (a
      # runtime-CONSTRUCTED record reaching normalize from outside those trees — corpus-zero) aborts
      # NAMED: stripping it would silently drop a policy (banned), grounding it would abort on `fn`
      # (misleading). NAME-keyed like v1's own registry (`scopedAspectPolicies.${name}`,
      # handlers/policy.nix:17; per-name fire dedup, dispatch.nix:54) — a nameless record is a v1
      # authoring error there too (`inherit (p) name` throws) and aborts named here.
      isPolicyRecord =
        ref: builtins.isAttrs ref && ((ref.__isPolicy or false) || (ref.__denCanTake or null) != null);
      keepInclude =
        ref:
        # LATE-DISPATCH RADIATION (F2, no node-local double-fire): a RADIATED bare fn (a late-dispatch bare-fn include —
        # `radiatedBareFn`, the SAME predicate the aspect-include walk collects by) is DIVERTED from the
        # node-local walk. It fires ONLY via its `__aspectInclude__bareFn__<i>` synthetic-aspect + edge
        # policy (late-dispatch, board #57 `__firesAtKinds`). Left in the walk it would ALSO fire node-local
        # (`wrapGatedFn` wherever its coords are present), double-counting content and breaking v1 once-only.
        # The synthetic aspect carries its wrapped fn as a `{ __fn; name }` RECORD (not a raw function), so
        # `radiatedBareFn` is false there and this divert never starves the synthetic aspect's own include.
        if radiatedBareFn ref then
          false
        else if !(isPolicyRecord ref) then
          true
        else if divertedPolicyNames ? ${ref.name or "<unnamed>"} then
          false # diverted — compiled at the aspect-include grain, never aspect content
        else
          errors.unregisteredPolicyInclude (ref.name or "<unnamed>");
      # Normalize a `.includes` list, naming each element by its POSITION under `prefix` (distinct keys).
      # The name is built by CONCATENATION (`prefix + ":" + toString i`), NOT by interpolating two values
      # around a colon — that interpolation idiom is the shim's `kind:name` scope-string form, which the
      # compat-identity-boundary lint bans in the core by a blunt byte-match (this is an aspect-include
      # NAME, never a scope-string, but concatenation keeps the core lint-clean regardless).
      # Policy records are filtered BEFORE positional naming — a record-free list keeps today's names
      # byte-stable; a record-carrying list previously ABORTED at expansion, so its post-filter shift has
      # no baseline to drift from.
      normalizeList =
        prefix: refs:
        prelude.imap0 (i: ref: normalize (prefix + ":" + toString i) ref) (
          builtins.filter keepInclude refs
        );
      # STATIC-INCLUDE IDENTITY (board #58 — the "<anon>"-collapse fix, the STATIC twin of the DISTINCT
      # WRAP NAMES fix above). That fix gave the FN arm per-position `meta.loc` keys; the static arm
      # stayed nameless, so every navigated static include keyed `"<anon>"` (gen-aspects `aspectPath`),
      # forwardExpand's seen-dedup kept only the FIRST sibling, transitive chains starved behind their
      # intermediate's key, and the content-driven member spine (output-modules `contentIdsOf`) dropped
      # starved hosts from `nixosConfigurations` entirely — the corpus zero-content diagnosis.
      # Does an include carry REAL content (a non-empty class deferredModule, a non-empty channel value, or
      # non-empty `.includes`)? A CONTENT-BEARING navigated node (`with den.aspects; [ core.systemd.boot ]`)
      # already carries its OWN correct native `.key` (its definition path — `core/systemd/boot`); an
      # identity-only BARE REFERENCE (`{ name = "kid" }` / a provides seed stub) carries ONLY typed defaults
      # (empty class buckets + positional identity). The classSet unwrap uses the shared `isEmptyDeferredModule`.
      hasRealContent =
        ref:
        builtins.isAttrs ref
        && builtins.any (
          k:
          builtins.substring 0 2 k != "__"
          && (
            if builtins.elem (v1ClassKeyMap.${k} or k) classNames then
              !(isEmptyDeferredModule ref.${k})
            else if builtins.elem k quirkNames then
              ref.${k} != null
            else
              k == "includes" && builtins.isList ref.${k} && ref.${k} != [ ]
          )
        ) (builtins.attrNames ref);
      # STATIC-INCLUDE IDENTITY. Under the typed tree a node placed in a container `includes` LIST is
      # A-IDENT-keyed by its OPTION PATH (`withaspect/includes/0`, name = "0", chain `[ withaspect includes ]`)
      # — POSITIONAL. Three cases, in order:
      #   • ANONYMOUS inline literal (`h4.includes = [ { nixos… } ]`, F4) → `name = "0"` (a bare integer index,
      #     the A-IDENT positional default): the per-position FALLBACK (`<parent>:include:<idx>` — v1's
      #     nameless posture). Checked FIRST (an inline literal IS content-bearing but must NOT keep its
      #     positional key).
      #   • CONTENT-BEARING navigated node (`with den.aspects; [ core.systemd.boot ]`, F1/F5) — a non-positional
      #     name AND real content → its native `.key`/`meta.aspect-chain` are ALREADY its real definition path;
      #     use them AS-IS (no re-stamp).
      #   • BARE REFERENCE (`{ name = "kid" }` delivery ref / `{ name = "carrier/to-users" }` provides seed
      #     stub, W1) — a non-positional name with NO content → KEEP the authored name but CLEAR the positional
      #     container chain so the key is the bare name (`kid`, not `withaspect/includes/kid`).
      stampIdentity =
        fallbackName: ref:
        let
          isPositional = builtins.match "[0-9]+" (ref.name or "") != null;
        in
        if !isPositional && (ref ? name) && hasRealContent ref then
          # a content-bearing navigated node: keep its native `name`/`key`/`meta`, but ensure a content-stable
          # `id_hash` (derive from `.key` when the node did not carry one — a manually-emitted value).
          ref
          // prelude.optionalAttrs (!(ref ? id_hash) && ref ? key) {
            id_hash = aspectIdHash ref.key;
          }
        else
          let
            nm = if isPositional || !(ref ? name) then fallbackName else ref.name;
          in
          ref
          // {
            name = nm;
            key = nm;
            id_hash = aspectIdHash nm;
            meta = (ref.meta or { }) // {
              aspect-chain = [ ];
            };
          };
      # COORD GATE + ARG-SHAPING (v1 canTake parity) — RELOCATED UPSTREAM (Task B). The gate + `intersectAttrs`
      # now live in gen-aspects' `wrapGatedFn` (the N-GATE): forwardExpand invokes a wrapped fn UNCONDITIONALLY
      # with the full enriched-context, and `wrapGatedFn`'s applicator replicates v1's `canTake` — a REQUIRED
      # coord (no-default formal) absent (define-user's `{ host, user }` at a HOST scope) ⇒ `{ }` inert (NOT
      # the throw `called without required argument 'user'`); present ⇒ `intersectAttrs` shapes the args so a
      # STRICT fn (no `...`) never chokes on the ctx's extra `__entry`. den-hoag threads its result dispatch via
      # `onResult = grndDispatch` (below). The `callGated` closure is GONE — `normalize` calls `wrapGatedFn`
      # directly (both arms). COORD-SET LIMIT (the `class`-coord gap, ledger row `u1`): the enriched-context
      # carries NO per-class `class` coord (v1 binds `class = entityCls` per-class-resolution, bind.nix:41 /
      # fx/resolve.nix:181), so a class-generic `{ class, … }` include (unfree's `__fn`) has `class`
      # REQUIRED-but-absent and gates to `{ }` — a latent-v1-divergence pinned by `ci/tests/compat-batteries.nix`
      # `test-unfree-class-coord-inert` + ledger row `u1` (UNCHANGED — the gate moved, the semantics are byte-equal).
      # A v1 aspect INCLUDE, normalized to the den-hoag shape under a distinct `name`. TRANSITIVE (matching
      # v1's resolve-children re-dispatch → wrapChild re-normalizes a fn RESULT's `.includes`; den-hoag's
      # forwardExpand likewise re-walks `concrete.includes`): a wrapped fn's RESULT and a static aspect's
      # `.includes` both go back through `normalize` (ground class keys, recurse nested bare fns). No
      # infinite loop — the fn recursion is inside the lazy `callGated` closure, forced only per resolution
      # ctx. A `{ __fn; name }` wrapper (unfree) keeps its OWN v1 name (`ref.name`).
      # Deep-flatten a returned effect list (v1 `lib.flatten` — nested `optional`/conditional lists) so
      # every effect is reached, never silently dropped as an unwalked entry. `prelude` carries no
      # `flatten`; this is the same recursion (`concatMap` over `isList`).
      flattenList = xs: prelude.concatMap (x: if builtins.isList x then flattenList x else [ x ]) xs;
      # Task B — the den-hoag FIRE-PATH result hook (R2), threaded into `wrapGatedFn`'s `onResult`. The
      # gate + `intersectAttrs` arg-shaping now live UPSTREAM in gen-aspects (`wrapGatedFn` — the N-GATE);
      # den-hoag keeps ONLY the result dispatch: an ATTRSET is aspect content → `groundRec` (class-key
      # grounding + nested-split + include recursion). A LIST result is v1's include-effect branch
      # (`mkParametricNext` aspect.nix:72-84): each `include`-effect entry contributes its `.value`, a bare
      # aspect passes through, any OTHER effect kind is a NAMED throw (`toInclude`) — flattened + null-
      # filtered, then fed back through `groundRec`'s SAME `.includes` re-resolve a static aspect's includes
      # take. This is exactly v1's uniform parametric-aspect posture: a parametric include RESULT is
      # re-walked whether it is content or an include list.
      grndDispatch =
        name: result:
        if builtins.isList result then
          let
            toInclude =
              e:
              if builtins.isAttrs e && (e.__policyEffect or null) == "include" then
                e.value
              else if builtins.isAttrs e && e ? __policyEffect then
                errors.parametricNonIncludeEffect name e.__policyEffect
              else
                e;
          in
          groundRec name {
            includes = map toInclude (builtins.filter (e: e != null) (flattenList result));
          }
        else if builtins.isFunction result && isForwardFn result then
          # CURRIED-FORWARD recognition (DYNAMIC-each): a coordinate-parametric OUTER layer
          # (`{ host, user }: { class, aspect-chain }: forward { … }`) FIRED to yield an INNER
          # `{ class, aspect-chain }` forwarder — the outer's cell coords (`host`/`user`) are already CLOSED
          # OVER lexically, so the inner needs only the forward coords. Fire it with them + re-dispatch, so a
          # doubly-curried forwarder (`each` reading walk-time cell coords) stamps its `meta.__forward` EXACTLY
          # like a single-curry static one — no productions relation, no compile change beyond this
          # recognition. Recursion terminates: `forwardEach` returns an ATTRSET.
          # CEILING (corpus-zero): ONLY the exactly-doubly-curried shape is recognized — the re-dispatched
          # inner IS the forward fn. A hypothetical TRIPLE-curry (an outer whose result is ANOTHER non-forward
          # coordinate layer) would abort at `groundRec`-on-a-function, matching the static-each scope (no
          # corpus/witness forwarder curries deeper than the `{ coords }: { class, aspect-chain }:` pair).
          grndDispatch name (result (builtins.intersectAttrs (builtins.functionArgs result) forwardCoords))
        else
          groundRec name result;
      # ── FORWARD-CONTEXT surfacing (§2-iv, u1 close for the `{ class, aspect-chain }` forward shape). ──
      # v1 binds `class = entityCls` + `aspect-chain = [ self ]` onto EVERY aspect-fn ctx (pipeline.nix:39/
      # 211 `defaultHandlers`/`resolve`). den-hoag's enriched-context binds NEITHER (the class-coord gap,
      # ledger u1), so a `{ class, aspect-chain }:` forwarder gates to `{ }` inert and never fires. Surface
      # them HERE — but ONLY for the FORWARD shape (a fn whose formals include `aspect-chain`), so the
      # class-coord PIN (unfree's `{ class, ... }` WITHOUT `aspect-chain`, `test-unfree-class-coord-inert`)
      # stays inert (byte-parity). `class`/`aspect-chain` VALUES are inert for a static-each forward: `each`
      # is a LITERAL (`singleton class`/`[ "nixos" … ]`), the per-item `fromClass`/`intoClass` ignore the
      # item, and `aspect-chain` is a v1 locality tag (compile-forward.nix `sourceIsLocal`), NOT the content
      # source (the collected `fromClass` bucket is). So a present placeholder suffices for the forwarder to
      # fire; the wrap ALWAYS fires (no gate) and intersects to the fn's own formals.
      # `aspect-chain` in the fn's formals is the forward signature. Forward recognition ALSO covers a
      # forwarder nested under a COORDINATE-PARAMETRIC outer layer (`{ host, user }: { class, aspect-chain }:
      # …`, the dynamic-each shape) — `grndDispatch` re-dispatches an outer's forward-fn RESULT through here.
      isForwardFn = fn: builtins.functionArgs fn ? "aspect-chain";
      forwardCoords = {
        class = "<forward>";
        "aspect-chain" = [ ];
      };
      wrapForwardFn =
        wrapName: fn:
        let
          fa = builtins.functionArgs fn;
        in
        {
          __functor =
            _: fnArgs: grndDispatch wrapName (fn (builtins.intersectAttrs fa (forwardCoords // fnArgs)));
          __functionArgs = fa;
          __isWrappedFn = true;
          name = wrapName;
          meta = {
            loc = [ wrapName ];
          };
        };
      normalize =
        name: ref:
        if builtins.isFunction ref && isForwardFn ref then
          # A `{ class, aspect-chain }` forwarder — surface the forward coords + fire unconditionally (§2-iv).
          wrapForwardFn name ref
        else if builtins.isFunction ref then
          # PLAIN bare-fn include (:440): wrap via the gen-aspects GATED fn — its applicator gates on the
          # inner fn's required coords (missing ⇒ `{ }`, no throw) + `intersectAttrs`, then `onResult`
          # grounds. `functionArgs` = the INNER fn's real formals (the load-bearing override); `name` keys
          # the wrap distinctly (the per-position identity, §313-318).
          aspects.wrapGatedFn {
            functionArgs = builtins.functionArgs ref;
            name = name;
            onResult = grndDispatch name;
          } ref
        else if builtins.isAttrs ref && (ref.__isWrappedFn or false) then
          # A PRE-TYPED function-valued aspect (a gen-aspects functor, e.g. a `provides.<u>.includes`
          # capture the desugar annotated via `annotatedViewNav` → `typedCompileTree`). Its INVOCATION
          # RESULT still carries un-grounded v1 class keys (a `homeManager` body), exactly like a raw
          # bare-fn's — so it must ground SYMMETRIC with the raw bare-fn arm above, which threads
          # `onResult = grndDispatch name` through `wrapGatedFn` (:539-548). This arm formerly passed the
          # functor through untouched, so `resolved-aspects` (`aspect ctx`) invoked it to un-grounded
          # `homeManager` content. Re-wrap: ground the functor's applicator RESULT through the SAME
          # `grndDispatch`, preserving the wrapped-fn shape EXACTLY — `ref //` retains `ref.__functionArgs`
          # (the ORIGINAL formals the cross-scope dedup discriminator `ctxProjOf` reads force-free),
          # `__isWrappedFn`, `name`, `meta`; only the `__functor` is overridden to ground. Idempotent +
          # single-pass: `groundKeys` maps `v1ClassKeyMap.${k} or k` (an already-grounded `home-manager`
          # is a VALUE never a KEY → identity), and the fn-arm branches are disjoint.
          ref // { __functor = _: fnArgs: grndDispatch name (ref fnArgs); }
        else if builtins.isAttrs ref && (ref.__fn or null) != null then
          # `{ __fn; name }` record (:444, the unfree shape): gate on `ref.__fn`'s formals, keep the record's
          # OWN v1 name, ground via `onResult`.
          aspects.wrapGatedFn {
            functionArgs = builtins.functionArgs ref.__fn;
            name = ref.name or name;
            onResult = grndDispatch name;
          } ref.__fn
        else if builtins.isAttrs ref && !(ref ? id_hash) then
          # A STATIC aspect attrset (inline content / a `{ name }` reference): GROUND its class keys and
          # recurse its includes. A `{ __isPolicy; fn }` policy record NEVER reaches here — every include
          # arm diverts it at its own grain, mirroring v1 (children.nix:70-72: `processInclude`'s FIRST arm
          # routes an `__isPolicy` include to `register-aspect-policy`, never the aspect walk): a
          # `den.schema.<kind>.includes` record via `isPolicyRef` → `kindIncludePolicies`; a record
          # nested in a REGULAR aspect's `.includes` via `keepInclude` above (#65, ledger u16 — the
          # `normalizeList` filter + the `aspectIncludePolicies` static walk; the old "corpus-zero" claim
          # for this grain was FALSIFIED by corpus users/sini.nix:4 → the host-aspects battery, u15). A
          # MALFORMED fn-bearing attrset that is NOT a policy record (no `__isPolicy`/`__denCanTake` —
          # e.g. `{ name; fn; }`) still grounds here and its `fn` key aborts at the §2.2 three-branch
          # dispatch — self-announcing, never a silent drop. An id_hash-bearing entry is already a
          # resolved record — pass it (and strings) through the `else`.
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
  # legacy module, `policies`/`excludes` are re-expressed here, `_` is the v1 provides/nested child slot.
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
        else if builtins.isAttrs aspect && (aspect.__isWrappedFn or false) then
          # A PRE-TYPED parametric aspect functor: `typeAspects` (typedCompileTree) wraps a
          # `den.aspects.<name> = { … }: …` into a gen-aspects functor BEFORE compile, so it reaches here as a
          # functor (NOT a bare fn — the `isFunction` arm never fires on the compileFull path). Its INVOCATION
          # RESULT carries gen-aspects-materialized class buckets keyed by the v1 SURFACE spelling — the typed
          # view keys class channels that way, and grounding to the kebab kernel class name is compile's job.
          # The static ELSE branch below grounds only the functor's OWN (structural) keys and leaves the RESULT
          # ungrounded, so a materialized `homeManager` bucket (an unset class default gen-aspects mounts on
          # EVERY node) would reach the kernel's §2.2 classifier un-grounded and abort `declares key homeManager`.
          # Ground the RESULT the SAME way `normalize` grounds a `__isWrappedFn` INCLUDE (its `__functor`
          # re-wrapped through `grndDispatch` → `groundKeys`, `homeManager` → `home-manager`), by routing through
          # the one `normalizeList` grounding path and taking the single wrapped functor back — the aspect stays
          # a bare functor (shape preserved; `ref.name`/identity kept).
          builtins.head (normalizeList "${name}:include" [ aspect ])
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
            # `meta.drop`/`neededBy` literal-form refs ride THROUGH as authored — a `keyOf` consumer
            # (resolved-aspects `indexByNeededBy` / `applyConstraints`) reads each ref's native `.key`, the
            # SAME `gen-aspects.key` the resolved nodes carry, so a literal ref matches its resolved node by
            # construction. (The old `stampProvider` map recovered a `__provider`-derived key here; with native
            # `.key` there is nothing to reconstruct — corpus-zero either way, the provides desugar emits
            # SELECTOR-form neededBy and corpus excludes are policy excludes on kinds.)
          in
          parent
          // (if metaWithDrop == null then { } else { meta = metaWithDrop; })
          // prelude.optionalAttrs (parent ? includes) {
            includes = normalizeList "${name}:include" parent.includes;
          }
      )
    );

  # ── DISPATCH-EMITTED content-set include (the census TWIN path — the revived arm). A v1 policy body
  # emits `policy.include den.aspects.<path>` where the navigated value crosses the raw bridge as a BARE
  # content set navigated off the typed `den` arg (so it carries its OWN native `.key`). Two corpus consumers:
  #   • `user-aspect-auto-include` (defaults.nix:14-22) emits `den.aspects.<host>.<user>` at user cells —
  #     the nested sub-aspects the translateAspect split strips (blade/cortex × sini/shuo);
  #   • `cluster-aspect` (policies/clusters.nix:73) emits `den.aspects.<cluster>` at cluster scopes
  #     (`den.aspects.axon`, clusters/axon.nix:101).
  # The emitted value is GROUNDED through the SAME normalizeList machinery translateAspect uses (class keys
  # grounded, `.includes` children wrapped/recursed — so the sub-aspect's firefox/steam/spicetify includes
  # resolve at the cell). IDENTITY: a navigated value carries its OWN native gen-aspects `.key` (v1 wrapChild
  # parity — normalize.nix:95-119), so `mkEmittedAspect` grounds it by that key — CELL-INDEPENDENT (identity is
  # the value's, not the cell's: two emitters at one cell can't collide, one set from two cells dedups to one
  # node per key-space). A closure-captured / SYNTHETIC value with NO `.key` falls back to the DETERMINISTIC
  # SCOPE-COORD identity: name = `<emitted>@<coord names>`, id_hash over the firing cell's entity-coord id_hashes
  # — stable across eval order, distinct per cell. At the value-less stratum probe the coords are sentinel
  # entries (which carry id_hash/name), so the fallback is probe-safe (both corpus emitters emit nothing there).
  # A `policy.include <value>` whose value is a CONTENT SET (not a `{ name }`/`{ id_hash }` reference to a
  # registered aspect): either a NAVIGATED node off the typed `den` arg (carries its OWN native `.key` — the
  # corpus `user-aspect-auto-include` emitting `den.aspects.<host>.<user>`) or a closure-captured / synthetic
  # value with neither `key` nor `name` (the scope-coord fallback). An id_hash-bearing resolved record, a
  # bare `{ name }` reference, a functor, and a policy record are NOT content sets.
  isEmittedContentSet =
    v:
    builtins.isAttrs v
    && !(v ? id_hash)
    && (v ? key || !(v ? name))
    && !(v ? __functor)
    && !((v.__isPolicy or false) || (v.__denCanTake or null) != null);
  mkEmittedAspect =
    normalizeList: ctx: v:
    # NATIVE IDENTITY: an emitted `policy.include den.aspects.<path>` value is a navigated node off the typed
    # tree, so it carries its OWN native `.key`. Gate on `v ? key`: ground it through `normalizeList` (which
    # preserves the native identity). VALUE IDENTITY (board #58): identity is the VALUE's, not the cell's — a
    # content set referenced from two cells dedups to one resolved node per cell key-space, two emitters at one
    # cell cannot collide. A closure-captured / synthetic value with NO `.key` takes the scope-coord fallback.
    if v ? key then
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
      else if builtins.isFunction effect.value then
        # #73 — `policy.include <bare fn>` (v1 wrapBareFn: a bare-fn include is a PARAMETRIC ASPECT,
        # normalize.nix:95-119 — the home-env battery's `classIncludes` include the per-host
        # `hostModule` fn, home-env.nix). Ground it through the SAME normalizeList wrap the static
        # include lists use (the kind-include bare-fn posture, row r); the edged record carries a
        # name-derived id_hash (A2 — resolved-aspects uses the edge record DIRECTLY as content, the C1
        # no-lookup posture, so no registry entry is needed; the positional wrap name keys dedup).
        map (w: declare.edge (w // { id_hash = aspectIdHash (w.name or "policy-include"); })) (
          normalizeList "policy-include" [ effect.value ]
        )
      else
        [ (declare.edge (resolveAspectRef aspectRec effect.value)) ]
    else if kind == "exclude" then
      # An aspect exclude prunes an aspect edge (`drop`). A POLICY exclude suppresses a policy's FIRING
      # (#72, candidate A — v1 `drop-user-to-host-on-droid`, nix-on-droid.nix:98-104, excludes the
      # os-user `user-to-host` route): a NAMED policy target (the bridge-coerced `{ __isPolicy; name;
      # fn }` record — v1's own registry shape) compiles to `declare.suppress { name }`, consumed by the
      # staged pre-pass's exclude family (v1 dispatch-policies.nix:15-33). A NAMELESS policy target (a
      # bare fn / an uncoerced `__denCanTake` record — the name-keyed suppression has nothing to match)
      # aborts NAMED (`excludeOfPolicyNameless`), never a misleading identity-law abort.
      let
        v = effect.value;
        isPolicyTarget =
          builtins.isFunction v
          || (builtins.isAttrs v && ((v.__denCanTake or null) != null || (v.__isPolicy or false)));
        targetName = if builtins.isAttrs v then v.name or null else null;
      in
      if isPolicyTarget then
        (
          if targetName != null then
            [ (declare.suppress { name = targetName; }) ]
          else
            errors.excludeOfPolicyNameless
        )
      else
        [ (declare.drop (resolveAspectRef aspectRec v)) ]
    else if kind == "resolve" then
      # THE RESOLVE ARM (user-delivery, design note 2026-07-11 §3(i) + §3c-UNIFIED). v1 `resolve.to <kind>
      # { … }` → a den-hoag `member` (the UNIFIED resolve-family verb — `relate` DISSOLVED) the STAGED
      # ROOT-RESOLUTION pre-pass consumes. Dispatch on `__targetKind` against the DISCOVERED containment
      # topology (`ing.schema`) + the NODE-CLASS LAW (`ing.registries` — zero kind literals):
      #   • a CELL kind (childless-with-parent AND registry-LESS — v1 has no `user` registry) → a BARE
      #     `member` with coords { <leaf> = the identity-wrapped target entity; <parentDim> = the FIRING
      #     node's own entry (`ctx.<parentDim>`) }. The leaf entity is wrapped to the ingest identity
      #     (sha256 "<kind>|name=<name>", ingest.nix:177) so its id_hash matches the registry factor node /
      #     the pre-pass index; `via` is threaded by the pre-pass off `__policy` (A5). Corpus: env-users'
      #     `resolve.to "user" { user; }` → member { user; host } → a user cell.
      #   • a ROOT kind (REGISTRY-BACKED — host/cluster/environment) → a CONTAINMENT `member` (`containTo`
      #     set). coords { <target> = the identity-wrapped existing root; <parentDim> = the firing node's
      #     own entry }; `bindings` = the emission's NON-ENTITY keyset (the honest B1 keyset — `value` minus
      #     the entity key); `containTo = <target>`. The pre-pass folds `bindings` into the target root's
      #     ctx AND records the firing-node coordinate as the root's containment ANCESTOR (the settings-chain
      #     env slice) — NEVER a product cell (this is what stops `cluster` cross-joining the user family).
      #     Corpus: env-to-hosts' `resolve.to "host" { host; accessGroups; }` → containment member to
      #     host:<name> carrying { accessGroups } + the environment ancestor; env-to-clusters' `resolve.to
      #     "cluster" { cluster; }` → containment member to cluster:<name> + the environment ancestor.
      # `includes` / `__shared`: corpus-UNEXERCISED (census nix-config @ b0b20769: only bare `resolve.to`),
      # so a NAMED abort (never silent) — implement faithfully when a corpus body first exercises them.
      let
        rawTk = effect.__targetKind or null;
        # #73 — v1's TARGET-KIND INFERENCE for a kind-less `resolve`/`resolve.withIncludes` (pin 11866c16
        # fx/policy/schema.nix:21-32 `resolveTargetKind`: the FIRST value key that is a schema entity
        # kind). The corpus emitter: the home-env battery's policyFn (`resolve.withIncludes ([userForward]
        # ++ schemaIncludes) { user = pair.user; }`, home-env.nix — live at droid hosts once #71 opened
        # the droidHome gate). No kind-named value key ⇒ the named abort below stands (v1 falls to the
        # emitting entityKind — a fan-out shape no corpus body reaches).
        inferredTk = prelude.foldl' (
          acc: k:
          if acc != null then
            acc
          else if topo ? ${k} then
            k
          else
            null
        ) null (builtins.attrNames val);
        tk = if rawTk != null then rawTk else inferredTk;
        shared = effect.__shared or false;
        includes = effect.includes or [ ];
        val = effect.value or { };
        # Containment topology, discovered from the ingested schema (no kind literals).
        topo = ing.schema;
        parentOf = k: (topo.${k} or { }).parent or null;
        parentKinds = prelude.unique (
          builtins.filter (p: p != null) (map parentOf (builtins.attrNames topo))
        );
        # THE NODE-CLASS LAW (§3c-UNIFIED): the target's existence SOURCE decides. A kind with an
        # INDEPENDENTLY-DECLARED, NON-EMPTY instance registry — a discovered `mkInstanceRegistry` custom
        # kind (`ing.instanceKeyMap`, e.g. `den.clusters`/`den.environments`) that actually carries entries
        # — is a ROOT → a CONTAINMENT tuple. A kind whose entities arrive ONLY via MEMBERSHIP (`user` — v1
        # declares no user KIND registry; its ingest entries are DERIVED from `den.homes`/`host.users`
        # bindings, NEVER an independent registry) is a CELL → a bare membership tuple. TWO signals, both
        # necessary: (a) registry PROVENANCE — `user` may carry a NON-EMPTY membership-derived registry yet
        # is still a cell, so emptiness alone misfires; `instanceKeyMap` membership (an independently-declared
        # registry) excludes it. (b) NON-EMPTINESS — a declared-but-instance-less custom leaf kind (a synthetic
        # `blade` schema with no instances) is a cell whose coord is a fabricated target entity, so it must
        # NOT classify as a root. Together they keep `cluster` (its own populated `den.clusters` registry,
        # childless under environment) a root — never a cross-joining cell — while `user` and an empty custom
        # leaf stay cells. `host`/`environment` never reach this test (parent kinds, excluded above).
        registryBacked = k: (ing.instanceKeyMap ? ${k}) && (ing.registries.${k} or { }) != { };
        isLeafDim = k: (parentOf k != null) && !(builtins.elem k parentKinds) && !(registryBacked k);
        # The canonical ingest identity for a v1 target entity (name-derived id_hash, ingest.nix:177) — so
        # the coord/target id_hash matches the registry factor node (fleet.nix factorOf) and the pre-pass
        # index.
        idHashOf = k: e: schema.hashIdentity k [ "name" ] (key: e.${key});
        # A CONTAINMENT target is IDENTITY-ONLY (id_hash + name): the tuple merely NAMES an existing target
        # root (the pre-pass index looks it up by id_hash); its payload rides `bindings`, never the record.
        wrapEntry = k: e: {
          id_hash = idHashOf k e;
          inherit (e) name;
        };
        # A MEMBER leaf coord carries the FULL resolved entity, with the canonical ingest id_hash OVERLAID.
        # v1's `resolve.to <leaf> { <leaf> = entity; }` makes the target its OWN instantiation root, so the
        # cell binding IS that entity — its `classes`/`userName`/`system`/`groups`/`identity`/`aspect`/`settings`
        # reach the cell's kind-includes + batteries (the corpus's resolved-user-emitter reads
        # `user.system.uid`/`user.identity.sshKeys`, inputs'/user reads `user.classes`, define-user reads
        # `user.userName`). A minimal `{ id_hash; name }` coord DROPPED them, so every user-cell aspect-fn
        # that destructured a registry field threw `attribute '<field>' missing` at resolved-aspects. `_module`
        # (the module-system evaluation internal, never part of an entity's identity or content — the bridge's
        # own registry stamps exclude it too, registry.nix stampOf) is stripped. Kind-generic: every leaf-dim
        # member (user, cluster, …) carries its resolved entity verbatim.
        wrapLeaf = k: e: builtins.removeAttrs e [ "_module" ] // { id_hash = idHashOf k e; };
      in
      if tk == null then
        errors.resolveNoTargetKind
      else if shared then
        errors.resolveShared tk
      # #73 — `resolve.*.withIncludes`: the resolution routes EXACTLY like `resolve.to` (the member
      # below); the riding `includes` are PARKED (the u4/u2 documented-latent posture, ledger u22). The
      # corpus's ONLY emitter is the droid home arc (home-env policyFn: `[ userForward ] ++ hm-host
      # schemaIncludes` at droid hosts) — class-B: `userForward` is the #49/#50 forward-battery NTA and
      # its delivery target is the nix-on-droid HOME output family, which is den-hoag-ABSENT (the u4
      # intoAttr posture) — so the parked content has NO reachable artifact either way. SELF-ANNOUNCING:
      # the absent `nixOnDroidConfigurations` output (the u2/u4 announcement shape); a class-A fleet is
      # untouched (its resolves carry `includes = [ ]`).
      else if !(topo ? ${tk}) then
        errors.resolveUnknownKind tk
      else if isLeafDim tk then
        # CELL target (registry-less leaf) → a bare membership tuple placing the resolved entity under the
        # firing node (coords = { leaf = the full resolved entity; parent = the firing node's own entry }).
        let
          pd = parentOf tk;
        in
        [
          (declare.member {
            ${tk} = wrapLeaf tk val.${tk};
            ${pd} = ctx.${pd};
          })
        ]
      else
        # ROOT target (registry-backed OR a parent-kind root) → a CONTAINMENT tuple (§3c-UNIFIED, `relate`
        # dissolved): coords = { target = the identity-wrapped existing root; source = the firing node's own
        # entry }; `bindings` = the emission's NON-entity keyset; `containTo` names the target coord. The
        # pre-pass folds the bindings into the target root's ctx AND records the source coordinate as the
        # root's containment ancestor (the settings-chain env slice) — never a product cell. A PARENTLESS
        # root target (a top-level root — no firing-scope coordinate) carries only the target coord: bindings
        # ride, no ancestor (the pre-pass skips an empty source slice).
        let
          pd = parentOf tk;
          sourceCoord = if pd == null then { } else { ${pd} = ctx.${pd}; };
        in
        [
          (declare.member {
            coords = {
              ${tk} = wrapEntry tk val.${tk};
            }
            // sourceCoord;
            bindings = builtins.removeAttrs val [ tk ];
            containTo = tk;
          })
        ]
    else if kind == "spawn" then
      # host-aspects projection (spec §7.1 / §6.2a): a v1 `policy.spawn { classes }` (the corpus host-aspects
      # opt-in) retargets to N class-scoped `reach-edge`s — one per named class — from the FIRING cell to its
      # OWN host root (`host:<name>`). The opted-in (user,host) cell then reaches its host's per-class aspects
      # through the `reach` graph, class-filtered (grounded terminology — `homeManager` → `home-manager`). The
      # old structural spawn payload was UNREAD (pure fleet enumeration), so the v1 host→cell home projection
      # was missing; the reach-edge is the projection producer. A null `classes` desugars to `[ ]` (no edges).
      # instantiate is a SEPARATE arm below (native per-cluster spawn — do NOT conflate).
      let
        cs = effect.value.classes or null;
      in
      map (
        c:
        declare.reach-edge {
          target = "host:${ctx.host.name}";
          classFilter = groundClassName c;
        }
      ) (if cs == null then [ ] else cs)
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

  # Task B — read a fn's formals whether it is a RAW closure or a gen-aspects `__isWrappedFn` FUNCTOR. Under
  # the single typed tree a policy record's `fn` (nested in an aspect's `includes`) is type-wrapped by
  # `aspectType` into a functor (it carries `__functionArgs`, is applied via `__functor`), so a bare
  # `builtins.functionArgs` throws `requires a function`. The functor mirrors nixpkgs' `setFunctionArgs`
  # convention, so `__functionArgs` IS the formal set (gate parity preserved). A raw closure keeps
  # `builtins.functionArgs`. Applying (`fn ctx`) works uniformly — the functor is callable.
  fnArgsOf =
    fn:
    if builtins.isAttrs fn && (fn.__isWrappedFn or false) then
      fn.__functionArgs
    else
      builtins.functionArgs fn;

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
    __condition = fnArgsOf (innerFn value);
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
        # #72: every name-keyed compiled policy consults the suppression key before producing (the v1
        # name IS the attr key here — user-to-host etc.), so a pre-pass-collected exclude suppresses it
        # at the emitting scope + descendants.
        prelude.genAttrs policyNames (
          name: gateSuppression name (compilePolicy ing normalizeList aspectRec policies.${name})
        )
        // prelude.genAttrs canTakeNames (
          name: gateSuppression name (compileCanTake ing normalizeList aspectRec policies.${name})
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
  # A parametric include fn's REQUIRED entity-kind formals — the board #57 `__firesAtKinds` annotation, AND
  # the input `isLateDispatchFn` (the radiate/divert guard) filters for a descendant kind. A DEFAULTED
  # formal (`{ host ? null, … }` → `args.host = true`) is NOT required → excluded, so a defaulted entity
  # formal has an empty `firesAt` (never radiates, and an empty `__firesAtKinds` would drop it at every
  # node). Only formals naming a registered entity kind (`ing.schema ? k`) count — a `{ pkgs, … }` include
  # has an empty `firesAt` and stays node-local. Mirrors `aspectIncludePolicies`' `firesAt` (which reuses
  # this) and `kindInclude`'s `[ kind ]` annotation.
  firesAtOf =
    fn:
    let
      args = fnArgsOf (innerFn fn);
    in
    builtins.filter (k: ing.schema ? ${k}) (builtins.filter (k: !args.${k}) (builtins.attrNames args));
  # Does a bare-fn include genuinely LATE-DISPATCH — i.e. require an entity coord it cannot obtain where it
  # attaches? The signal is a required formal naming a DESCENDANT (non-root) kind (`ing.schema.<k>.parent`
  # non-null — `user` under `host`): such a coord is absent at the aspect's own / ancestor scope, so the fn
  # MUST fire at descendant cells (`{ host, user }` on a host aspect → the host's user CELLS). A fn whose
  # required kinds are all ROOTS (`{ host, … }`, host has no parent) fires IN PLACE where the coord is
  # already present (the `den.default` batteries, wired to `den.schema.{host,user}.includes`) — it keeps its
  # proven node-local `wrapGatedFn` path, NOT radiation. This is STRICTLY STRONGER than `firesAt ≠ [ ]`
  # (F1): a defaulted formal (`{ host ? null }` → empty `firesAt`) still never radiates, AND an in-place
  # root-only fn is not rerouted — so radiating never couples the individually-isolated `den.default`
  # members, and never mis-confines an ancestor-formal include (`{ host }` on a user aspect stays node-local,
  # firing at the cell via the inherited host coord, instead of a wrong `__firesAtKinds = [ host ]` HOST
  # confinement). The radiate GUARD, the node-local divert predicate, and the walk collector all share THIS
  # ONE computation, so they never diverge.
  isLateDispatchFn = fn: builtins.any (k: (ing.schema.${k}.parent or null) != null) (firesAtOf fn);
  normalizeList = mkNormalize allClassNames (builtins.attrNames (v1Decls.quirks or { })) (
    if aspectIncludeArm then aspectIncludeDivertedNames else { }
  ) (if lateDispatch then (ref: builtins.isFunction ref && isLateDispatchFn ref) else (_: false));
  # The nested-aspect discriminator for THIS fleet (same cnf grain as normalizeList): the quirk set is
  # the fleet's declared channels, so `blade.firewall` classifies quirk while `blade.shuo` splits nested.
  isNestedAspectKey = mkIsNestedAspectKey allClassNames (builtins.attrNames (v1Decls.quirks or { }));

  # ── Aspect-include POLICY-RECORD arm, the REGULAR-ASPECT grain (#65, ledger u16 — v1 children.nix:70-72
  # parity, the THIRD and last include grain). v1 routes a `{ __isPolicy }` include to
  # `register-aspect-policy` at ANY walk depth (pin 11866c16 aspect/children.nix:70-72), registering it
  # NAME-keyed at the walking scope (handlers/policy.nix:8-20 `scopedAspectPolicies.${name}`) and firing it
  # there gated on the fn's REQUIRED formals (`resolveArgsSatisfied`, synthesize-policies.nix:7-16;
  # per-name fire dedup, policy/dispatch.nix:54). The two grains above cover `den.schema.<kind>.includes`
  # and TOP-LEVEL `den.default.includes` records; a record NESTED in a regular aspect's `.includes`
  # (corpus: `den.aspects.sini.includes = [ den.batteries.host-aspects ]`, users/sini.nix:4 — the
  # battery's `includes = [ { __isPolicy; name = "host-aspects-project"; fn; } ]`, the compat battery
  # faithful to v1 batteries/host-aspects.nix) previously fell to `groundRec` and aborted §2.2 on `fn`
  # (ledger u15).
  #
  # THE WALK: a STATIC collection over the surfaces every arrival path re-reads — the `den.aspects`
  # registry trees (the translateAspect path AND the dispatch-emitted path, which re-reads the SAME
  # annotated tree off `_module.args.den`, ledger r). Per value:
  # its `.includes` list elements (a policy record collects; an attrset recurses — the battery nesting)
  # and its nested/namespace attrset children (the annotate-walk guard: non-`__`, non-structural,
  # non-class, non-quirk — `den.aspects.<host>.<user>` sub-aspects, `core.systemd` namespace nodes).
  # SEEN-set on element NAMES breaks reference cycles (a.includes=[b], b.includes=[a] — v1's own walk
  # dedups by identity.key the same way); the final per-NAME dedup mirrors v1's name-keyed registry (two
  # DISTINCT same-named records at different aspects would collapse — v1 registers both at their
  # respective scopes; corpus-one-record, a named ceiling). FORCING: attrset WHNF + includes list spines
  # of authored static data — the same grain annotate/translateAspect already force; never a fn call or
  # module body.
  #
  # THE RULES: each record compiles via the SAME `compilePolicy` as the sibling grains, named
  # `__aspectInclude__<name>` (the reserved `__` namespace — collision-free vs user policies, and
  # name-stable because the collection dedups by name). Gate = `compilePolicy`'s own
  # `__condition = functionArgs (innerFn record)` — v1's `resolveArgsSatisfied` REQUIRED-formals presence
  # gate verbatim (host-aspects-project's `{ host, user, ... }` fires at (user,host) cells) — AND
  # `__firesAtKinds` (board #57, below): the record's REQUIRED entity-kind formals, confining the arm to
  # OWNER-KIND nodes so a `{ host }` include no longer over-fires at a user cell that inherits its host's
  # `host` coord. The finer aspect-ATTACHMENT locality (v1 fires ONLY at scopes whose walk REGISTERED the
  # record — e.g. the including user's cell vs all cells) is v1's SECOND confinement, corpus-unexercised,
  # left as a documented residual rung (NOT half-implemented — a distinct confinement).
  aspectIncludeWalk =
    let
      classSet = prelude.genAttrs allClassNames (_: true);
      quirkSet = prelude.genAttrs (builtins.attrNames (v1Decls.quirks or { })) (_: true);
      walkableChild =
        v: k:
        !(prelude.hasPrefix "__" k)
        && !(v1StructuralKeysSet ? ${k})
        && !(classSet ? ${v1ClassKeyMap.${k} or k})
        && !(quirkSet ? ${k})
        && builtins.isAttrs v.${k};
      # seen-set identity (cycle-break): the value's native `.key` — the structural, path-unique identity
      # born in gen-aspects' type (`blade/sini` ≠ `sini`), matching v1's aspect registration keyed by
      # `identity.key` (children.nix), NOT by `.name`. A per-host `<host>.<user>` sub-aspect legitimately
      # shares its `.name` with the top-level `<user>` aspect, so name-first over-dedups: the earlier-walked
      # sub-aspect poisons `seen` and the distinct top-level aspect's includes are skipped. `.name` is only a
      # fallback for a keyless value (e.g. a raw-path node with neither); an inline anonymous literal has
      # neither and terminates by structure (finite authored data).
      idOf =
        v:
        if (v.key or null) != null then
          v.key
        else if (v.name or null) != null then
          v.name
        else
          null;
      go =
        acc: v:
        if !(builtins.isAttrs v) then
          acc
        else if idOf v != null && acc.seen ? ${idOf v} then
          acc
        else
          let
            seen' = if idOf v == null then acc.seen else acc.seen // { ${idOf v} = true; };
            incs =
              let
                i = v.includes or null;
              in
              if builtins.isList i then i else [ ];
            afterIncs = prelude.foldl' (
              a: x:
              if isPolicyRef x then
                a
                // {
                  recs = a.recs ++ [ x ];
                }
              # LATE-DISPATCH RADIATION (§5.2): a bare-fn include that genuinely LATE-DISPATCHES — requires a DESCENDANT
              # entity coord absent where it attaches (`isLateDispatchFn`, the SAME predicate `radiatedBareFn`
              # the node-local walk diverts by) — RADIATES as a synthetic aspect + edge policy (below). An
              # in-place or no-entity-formal bare fn falls to `go` (a no-op on a function) and keeps the
              # node-local `wrapGatedFn` path.
              else if isBareFnRef x && isLateDispatchFn x then
                a
                // {
                  bareRecs = a.bareRecs ++ [ x ];
                }
              else
                go a x
            ) (acc // { seen = seen'; }) incs;
          in
          prelude.foldl' (a: k: go a v.${k}) afterIncs (
            builtins.filter (walkableChild v) (builtins.attrNames v)
          );
      walked = prelude.foldl' go {
        recs = [ ];
        bareRecs = [ ];
        seen = { };
      } (builtins.attrValues v1Aspects);
      # per-NAME dedup (first occurrence wins — deterministic: attrNames order + list order), v1's
      # name-keyed registry posture. A nameless record never collects (it aborts named at the
      # normalizeList filter — v1's own `inherit (p) name` would throw there too).
      dedup =
        prelude.foldl'
          (
            a: r:
            let
              n = r.name or null;
            in
            if n == null || a.seen ? ${n} then
              a
            else
              {
                recs = a.recs ++ [ r ];
                seen = a.seen // {
                  ${n} = true;
                };
              }
          )
          {
            recs = [ ];
            seen = { };
          }
          walked.recs;
    in
    {
      recs = dedup.recs;
      # bare-fn includes (§5.2) — positional (no name to dedup on), collected in walk order. A fn
      # referenced twice radiates twice (the kindInclude content-set positional ceiling; corpus bare-fn
      # aspect-includes are single-referenced).
      bareFns = walked.bareRecs;
    };
  # den.features gates (register compat-feature-register.md): off empties the top-level binding so every
  # downstream consumer cascades inert — `aspectIncludeArm` off drops `aspectIncludeDivertedNames`,
  # `aspectIncludePolicies`, and this arm's `includeReferencedNames` contribution; `lateDispatch` off drops
  # `aspectIncludeBareFnArm.{aspects,policies}`. The walk's internal collection may still run (unused).
  aspectIncludeRecords = if aspectIncludeArm then aspectIncludeWalk.recs else [ ];
  aspectIncludeBareFns = if lateDispatch then aspectIncludeWalk.bareFns else [ ];
  aspectIncludeDivertedNames = prelude.genAttrs (map (r: r.name) aspectIncludeRecords) (_: true);
  aspectIncludePolicies = builtins.listToAttrs (
    map (
      ref:
      let
        # board #57 confinement: `__firesAtKinds` = the record fn's own REQUIRED entity-kind formals (v1
        # `resolveArgsSatisfied`, schema.nix:188-190) — the same source `compilePolicy`'s `__condition`
        # gates on, restricted to kinds. Mirrors `kindInclude`'s `[ kind ]` annotation. A DESCENDANT
        # inherits an ancestor coord down its P edge (a user cell carries its host's `host` coord,
        # structural.nix attr 1), so the formals-presence `__condition` ALONE over-fires a `{ host }`
        # include at every user cell; the kind pre-filter pins v1's fire-AT-the-owner-kind. AND-ed with the
        # `__condition` gate it only NARROWS — never adds a firing. OMITTED when the record has no
        # entity-kind formal (a `{ class, … }` / ungated include keeps its DYNAMIC attachment; an empty
        # `__firesAtKinds` would wrongly drop it at every node — the pre-filter is `elem nodeKind list`).
        # RESIDUAL (documented, not half-done): v1's SECOND confinement — fire only where the aspect walk
        # REGISTERED the record (aspect-attachment locality, e.g. the including user's cell vs all cells) —
        # is a distinct, corpus-unexercised rung, left unimplemented.
        firesAt = firesAtOf ref;
      in
      {
        name = "__aspectInclude__${ref.name}";
        value =
          gateSuppression (ref.name or null) (compilePolicy ing normalizeList aspectRec ref)
          // familyStamps ref
          // prelude.optionalAttrs (firesAt != [ ]) { __firesAtKinds = firesAt; };
      }
    ) aspectIncludeRecords
  );

  # ── Aspect-include BARE-FN arm (parametric-include late-dispatch) — the bare-fn sibling of the
  # policy-record arm above, MIRRORING the shipped kind-include bare-fn arm (`kindInclude`, below). A bare
  # fn nested in a regular aspect's `.includes` that genuinely late-dispatches — requires a DESCENDANT
  # entity coord absent where it attaches (`aspectIncludeBareFns`, collected by the SAME `isLateDispatchFn`
  # guard the node-local walk diverts by) — fires at DESCENDANT
  # cells where they ARE (`{ host, user }` on a host aspect → the host's USER CELLS). It radiates as:
  #   • a SYNTHETIC ASPECT `__aspectInclude__bareFn__<i>__aspect` whose sole include is the wrapped fn —
  #     invoked at forwardExpand with the real cell ctx, its RESULT discriminated by `grndDispatch`
  #     (content → `groundRec`; a list of include effects → the §5.1 branch). The wrapped fn is carried as a
  #     `{ __fn; name }` RECORD (normalize's `__fn` arm) so `radiatedBareFn` is FALSE there and the F2
  #     node-local divert never strips the synthetic aspect's OWN include.
  #   • an EDGE POLICY `__aspectInclude__bareFn__<i>` gated on the fn's formals (`__condition`) AND confined
  #     to the formal-kinds (`__firesAtKinds`, board #57 — proven to fire at the descendant cell, NOT the
  #     attaching host). The edge attaches the synthetic aspect (by name → full record via `aspectRec`).
  # Positional identity (a bare fn has no name); the guard guarantees `firesAt ≠ [ ]` (never an empty
  # `__firesAtKinds`).
  aspectIncludeBareFnArm =
    let
      synths = prelude.imap0 (i: fn: {
        inherit fn;
        synthName = "__aspectInclude__bareFn__${toString i}";
        aspectName = "__aspectInclude__bareFn__${toString i}__aspect";
        firesAt = firesAtOf fn;
      }) aspectIncludeBareFns;
    in
    {
      aspects = builtins.listToAttrs (
        map (s: {
          name = s.aspectName;
          value = {
            includes = normalizeList "${s.aspectName}:include" [
              {
                __fn = s.fn;
                name = "${s.aspectName}:fn";
              }
            ];
          };
        }) synths
      );
      policies = builtins.listToAttrs (
        map (s: {
          name = s.synthName;
          value = {
            __condition = fnArgsOf s.fn;
            __firesAtKinds = s.firesAt;
            fn = _ctx: [ (declare.edge (aspectRec s.aspectName)) ];
          };
        }) synths
      );
    };

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
  #     per-class `${host.class}`), a LIST re-resolves via `grndDispatch`'s §5.1 include-effect branch (the
  #     v1 `mkParametricNext` list arm — each include effect's `.value`, flattened). This routes a content-returning
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
          # SCOPE-LOCAL FIRING (board #57, ledger u3): `__firesAtKinds = [ kind ]` confines the arm to
          # OWNER-KIND nodes at dispatch (concern-policies threads it; structural.nix pre-filters). The KIND
          # coord alone is INSUFFICIENT — a DESCENDANT kind inherits an ancestor coord down its P edge (a user
          # cell carries its host's `host` coord, structural.nix attr 1), so a `{ host }`-gated host include
          # would ALSO fire at every user cell; the kind annotation is what pins v1's fire-AT-the-owner-kind
          # (schema.nix:184-199 `requiredEntityArgs` — a `{host,…}` policy fires at host scopes, NOT user).
          edgeRefs = staticRefs ++ map (n: { name = n; }) (builtins.attrNames synthAspects);
          aspectPolicy = prelude.optionalAttrs (edgeRefs != [ ]) {
            "__kindInclude__${kind}" = {
              __condition = kindCoord;
              __firesAtKinds = [ kind ];
              fn = _ctx: map (ref: declare.edge (resolveAspectRef aspectRec ref)) edgeRefs;
            };
          };
          policyPolicies = builtins.listToAttrs (
            prelude.imap0 (i: ref: {
              name = "__kindInclude__${kind}__policy__${toString i}";
              value =
                let
                  base = gateSuppression (ref.name or null) (compilePolicy ing normalizeList aspectRec ref);
                in
                base
                // {
                  __condition = kindCoord // base.__condition;
                  __firesAtKinds = [ kind ];
                }
                # R2/#72 tag propagation: a SYNTHETIC-keyed include policy whose source ref is a corpus
                # resolve/exclude policy (name ∈ the family sets) carries the `__resolveFamily`/
                # `__excludeFamily` tag concern-policies reads — its synthetic key never matches the
                # name-based check.
                // familyStamps ref;
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
    // compiledPolicies.conditionalAspects
    // kindIncludeAspects
    // aspectIncludeBareFnArm.aspects;

  # ── SCOPE-LOCAL POLICY FIRING (board #57, ledger u3) — v1 `installPolicies` parity. ──
  # v1 fires a policy ONLY where it is REGISTERED — scope-local, via an INCLUDE (den nix/lib/aspects/fx/
  # policy/default.nix:82-113 `installPolicies` "Policies fire where they're registered — scope-local only";
  # subtree fan-out filtered by `requiredEntityArgs`, schema.nix:157-199). A `den.policies.<name>` is a NAMED
  # DEFINITION; presence alone fires NOWHERE — it must be INCLUDED to function. So a policy NAME referenced
  # from an include is REMOVED from the fleet-wide compiled set (`includeReferencedNames`); its firing rides
  # its `__kindInclude__<kind>__policy__<i>` arm ALONE, which `__firesAtKinds`
  # confines to owner-kind nodes (Part 2). INVARIANT: an include-referenced policy fires via EXACTLY its
  # include arms. The removal set covers every arm-creating path — `expandRefs` (which hoists inline-aspect
  # `.includes`) over every kind's raw includes, plus the aspect-include records
  # (`aspectIncludeRecords`, the #65 regular-aspect grain — a `den.policies` record nested in a regular
  # aspect's `.includes` fires via its `__aspectInclude__<name>` arm alone, corpus-zero) — via the SAME
  # `isPolicyRef` filter each arm builder uses, so the arm set and the removal set coincide. A policy `.name` is its
  # `den.policies` KEY (the bridge coercion, policy-type.nix); a reference-only inline record (no
  # `den.policies.<name>`) yields a name `removeAttrs` no-ops on. The SHIM-SYNTHETIC `user-to-host` global
  # (builtins.nix) now rides `defaults.includes` (the desugared `den.default` aspect, legacy/defaults.nix),
  # so it IS include-referenced via `aspectIncludeRecords` and its ambient global entry is REMOVED here
  # (single-fire — the include arm alone). The remaining shim globals (builtins.nix: fleet-context-enrich,
  # host-to-users) are NOT include-referenced, so they SURVIVE as DELIBERATE compat mechanisms (the enrich
  # fixpoint / the ambient os-user route) — verified: neither is a `.includes` reference (host-to-users
  # rides `.excludes`, not scanned here).
  #
  # The synthetic `__kindInclude__<kind>[__policy__<i> | __aspect__<i>]` / `__aspectInclude__<name>` names
  # cannot collide with a compiled `den.policies.<name>` (nor a v1 aspect):
  # den reserves the `__` prefix for internal keys, and a v1 policy/aspect name is a user-authored
  # identifier that never uses it — so this namespace is disjoint from `compiledPolicies` (and each
  # positional arm is disjoint within itself by index). `kindIncludePolicies` is already a flat
  # name→policy set.
  includeReferencedNames =
    let
      kindPolicyRefs = prelude.concatMap (
        kind: builtins.filter isPolicyRef (expandRefs ing.kindIncludes.${kind})
      ) (builtins.attrNames ing.kindIncludes);
    in
    builtins.filter (n: n != null) (map (r: r.name or null) (kindPolicyRefs ++ aspectIncludeRecords));
  policies =
    (builtins.removeAttrs compiledPolicies.policies includeReferencedNames)
    // kindIncludePolicies
    // aspectIncludePolicies
    // aspectIncludeBareFnArm.policies;

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
      # R6: the per-host home-manager NixOS module grain (terminal-side twin of instantiateFor).
      hmModuleFor
      # The bridge-registry passthrough: the per-KIND per-entity ctx-entity field record (the host's
      # structural class/system/hostName trio + every kind's structural-exclusion registry stamp,
      # `den._entityStamps` via the bridge) — flake-module.nix `instanceConfig` stamps it onto EVERY
      # kind's entities.
      entityFields
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
