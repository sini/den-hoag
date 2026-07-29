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
  # gen-graph's ordered preorder-fold calculus (`foldPreorder`) — the aspect-include reachability walk
  # (`aspectIncludeWalk`) routes through it: a pre-order DFS fold over an accessor-described graph,
  # threading a caller-owned accumulator + first-occurrence visited set, in place of a hand recursion.
  graph,
  builtinClasses,
  # gen-schema's content-address FORMULA (schema.hashIdentity) — the SINGLE definition the registry factor
  # nodes hash through (gen-schema identity.nix:16). `idHashOf` routes through it so the resolve-arm's
  # name-preimage aligns to the factor nodes BY CONSTRUCTION, not by a coincident literal copy.
  schema,
  # The aspect namespace-identity helper (§A2), from den-hoag's kernel single-authority
  # (denHoag.aspectIdHash, routed onto gen-native's `aspects.aspectId`) — the compat aspect-edge sites
  # recompute the SAME id_hash the kernel stamps.
  aspectIdHash,
  # `mkGateAspect { classNames; quirkChannels }` → `name: aspect: aspect` — the parametric-result gate handle
  # (§9.5). `grndDispatch`'s content terminals type the DESUGARED parametric result through the closed-gated
  # aspect type (built for the fleet's GROUNDED class + quirk vocabulary) so a typo in a parametric body throws
  # NAMED at the gate at resolution, exactly as a static aspect's typo throws at compile — the sole typo
  # boundary for parametric content. Returns the desugared aspect unchanged (a validation seq, byte-neutral).
  mkGateAspect,
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
  # THE PRODUCED-KIND MAP (declared-stratum, `den.producesByName`, single source compat/produces-by-name.nix)
  # — the resolveFamilyNames twin as a `name → [kind]` MAP. Threaded HERE so the kind-include arms stamp
  # `__produces = producesByName.<name>` on a compiled include policy whose SOURCE REF's v1 name is a key
  # (the corpus's value-conditional resolve/include policies ride kind-includes → synthetic keys, so the
  # name-based lookup in concern-policies never catches them — the stamp is the only path). The declared
  # produced-kind family lets `dispatch.deriveGroup` stamp the rule's group at definition time, retiring
  # the fire-and-observe blind fan for these. Native callers pass `{ }` (the default), byte-identical.
  producesByName ? { },
  # The recovery sentinel (formerly the `den.probeSentinelFields` kernel option). It configures the SHIM's
  # codomain recovery, and its own header always said the field NAMES live consumer-side; moving it here
  # makes the code agree with the comment. Native callers pass `{ }`.
  sentinelFields ? { },
  # The codomain recovery desugar (policy-recover.nix), and its removability gate. OFF ⇒ no recovery: a v1
  # bare closure with no declared codomain aborts NAMED, which is STRICTLY MORE STRICT than on.
  policyRecover,
  policyRecovery ? true,
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
  # THE DECLARED CODOMAIN, from the three v1 corpus facts the shim already carries. Each of them was a
  # different name-keyed way of saying the same thing — which declaration kinds a policy can produce — so
  # they fold into ONE `emits` declaration rather than three tags the kernel reads off the value:
  #   • `producesByName.<name>`      the kinds outright (single source compat/produces-by-name.nix);
  #   • `name ∈ resolveFamilyNames`  the policy can emit `member` (single source resolve-family-names.nix);
  #   • `name ∈ excludeFamilyNames`  the policy can emit `suppress` (single source exclude-family-names.nix).
  # The family sets exist precisely because a value-conditional emitter cannot be DETECTED by firing, so
  # each is a codomain fact its consumer knows and the recovery cannot learn. Feed membership then follows
  # by derivation at the kernel — there is no tag to forget. A name with NO declared fact recovers its
  # codomain by firing (policy-recover.nix); one that under-declares is caught LOUD at the emitting site
  # (`emitsUndeclared`) rather than mis-routed.
  declaredEmitsOf =
    name:
    if name == null then
      [ ]
    else
      prelude.unique (
        (producesByName.${name} or [ ])
        ++ prelude.optional (builtins.elem name resolveFamilyNames) "member"
        ++ prelude.optional (builtins.elem name excludeFamilyNames) "suppress"
      );
  declaredEmits = prelude.genAttrs (
    builtins.attrNames producesByName ++ resolveFamilyNames ++ excludeFamilyNames
  ) declaredEmitsOf;
  # `emitsFor v1Name fn` — the codomain for one compiled policy. The v1 NAME is the identity the corpus
  # facts key on; a policy wired through an include compiles to a SYNTHETIC attr key, so the lookup must
  # happen at the REF (here) and never at the compiled key.
  # `emitsFor declared v1Name gate fn` — the codomain, by DECLARATION wherever one exists and by recovery
  # only where none does. `declared` is the SOURCE value's own `emits` (a v1 fleet that already declares
  # its codomain is never fired at a sentinel at all — the shim's opt-out property); then the corpus facts
  # keyed by v1 name; and only then the fire.
  emitsFor =
    declared: v1Name: gate: fn:
    let
      named = if v1Name == null then "«unnamed»" else v1Name;
    in
    if declared != null && declared != [ ] then
      declared
    else if v1Name != null && (declaredEmits.${v1Name} or [ ]) != [ ] then
      declaredEmits.${v1Name}
    else if !policyRecovery then
      errors.policyCodomainUndeclared named
    else
      policyRecover.recoverEmits {
        inherit sentinelFields;
        declaredEmits = { };
      } named gate fn;
  # The include-arm stamp: one `emits` field where three `__`-prefixed tags used to ride.
  # ★ `ungated` is the record BEFORE `gateSuppression` wraps its `fn`. A codomain is a STATIC property of
  # a body; suppression is a PER-NODE DISPATCH concern. Recovering the codomain through the dispatch gate
  # inverts those layers, and the inversion collapses two states that must stay apart: a gated body
  # returns `[ ]` when suppressed, which is indistinguishable from "emits nothing" and compiles to NO
  # rule — silently deleting a policy on the very path whose job is to discover what it does. Recovering
  # from the ungated body makes the question unaskable rather than merely unlikely, and removes an
  # accidental dependence on `gateSuppression`'s fail-open `or [ ]` default (so tightening that default
  # later cannot silently break codomain recovery).
  familyStamps = ref: ungated: {
    emits = emitsFor (ref.emits or null) (ref.name or null) ungated.gate ungated.fn;
  };

  # THE DYNAMIC-ATTACHMENT ABSENCE, said rather than implied. A record with no entity-kind formal keeps
  # its DYNAMIC attachment and must reach every node — which is `selects = null`, NOT `[ ]`. The omission
  # this replaces was load-bearing and its own comment said so; the field makes the two absences different
  # VALUES instead of the same missing key.
  selectsOfFormals = firesAt: if firesAt == [ ] then null else firesAt;

  # #72 — THE SUPPRESSION GATE (v1 dispatch-policies.nix:15-33: dispatch filters `aspectPolicies` by
  # name against the scoped exclude constraints). den-hoag rendering: the pre-pass's suppression sets
  # ride the emitting root's decls as the typed `suppressedPolicies` slot (default.nix scopeRoots), the
  # `suppressed-policies` inherited attribute (gen-scope inheritSet) carries them self ∪ ancestors to
  # descendants, and it is ctx-injected as `suppressedPolicies` at the dispatch. Every compiled rule
  # whose v1 NAME is known consults the set before producing — a suppressed policy fires as `[ ]` at that
  # scope subtree, exactly v1's filter. The v1 NAME (not the synthetic compiled key) is the match, so
  # include-arm rules gate correctly. `null` name (an anonymous include fn) ⇒ ungateable ⇒ identity
  # (v1's filter is name-keyed too).
  gateSuppression =
    v1Name: compiled:
    if v1Name == null then
      compiled
    else
      compiled
      // {
        fn = ctx: if builtins.elem v1Name (ctx.suppressedPolicies or [ ]) then [ ] else compiled.fn ctx;
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
  # key-classification.nix:69-80` `isNestedKey`, pin 11866c16. ──
  #
  # v1 partitions an aspect's non-structural/non-class/non-quirk keys (classifyKeys, :82-111): a key whose
  # ATTRSET value carries ≥1 RECOGNIZED sub-key — structural, quirk, or a registered class NAME — is
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
  # aspectContentType typing the raw bridge never constructs (the same reason `__provider` is absent). The
  # discriminator is now NAME-only (registry membership of the sub-key) — it never forces a sub-VALUE, so
  # the former class-content value-heuristic and its #580 flake-fixpoint WHNF-forcing guard are moot.
  # The v1-verbatim STRUCTURAL key set (`builtinStructuralKeys` + reserved) — the aspect-include walk's
  # structural-key filter (`walkableChild`, below). KEPT: the v1 compat-export SoT, unrelated to the retired
  # raw discriminator.
  v1StructuralKeysSet = (import ./key-classification.nix { }).structuralKeysSet;
  # `isEmptyDeferredModule` (the empty class-wrap peel) — retained here as the single source shared with
  # class-modules (the class-bucket unwrap below at the classSet arm). The former `looksLikeClassContent`
  # VALUE-shape heuristic that also lived here is GONE: it inspected a class-named sub-value's structure to
  # disambiguate class content from a nested aspect at the class/nested COLLISION (a corpus aspect NAMED
  # after a registered class). The namespace name-reservation retires that collision — the corpus is
  # de-collided (no aspect is named after a class), so class-vs-nested is decided by REGISTRY MEMBERSHIP
  # alone; the value-guess is inert and removed.
  inherit (import ../module-shape.nix { inherit prelude; }) isEmptyDeferredModule;
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
  # `aspectRec`/`registry` are threaded from the inner function body so the include arm can RESOLVE a
  # registered nav reference to its canonical grounded record (delegation, not re-grounding) — see the
  # `registry ? ${ref.key}` arm in `normalize`. Both are lazy (functions / an attrset built FROM
  # `normalizeList`); the closure captures them as thunks and forces them only at resolution, acyclically.
  mkNormalize =
    gateAspect: classNames: quirkNames: divertedPolicyNames: radiatedBareFn: aspectRec: registry:
    let
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
          # §9.5 parametric-result gate: normalize the constructed include-list aspect to the static pre-gate
          # shape via `translateAspect` — which subsumes `groundRec`'s grounding + adds the droppedAspectKeys
          # drop / excludes→meta.drop fold / provides sentinel the parametric path was missing — THEN gate, so
          # gated-parametric-shape == gated-static-shape and a typo throws NAMED at the gate at resolution.
          gateAspect name (
            translateAspect normalizeList name {
              includes = map toInclude (builtins.filter (e: e != null) (flattenList result));
            }
          )
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
          # §9.5 parametric-result gate (attrset terminal): `result` is already the aspect attrset, so feed it
          # straight to `translateAspect` (desugar to the static pre-gate shape) THEN gate.
          gateAspect name (translateAspect normalizeList name result);
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
        else if builtins.isAttrs ref && ref ? key && builtins.isString ref.key && registry ? ${ref.key} then
          # A REGISTERED NAV REFERENCE — a `with den.aspects; [ … ]` node carries its native gen-aspects `.key`
          # (the full container-relative slash-path, `core/systemd/boot`), which is a registry key. It is a
          # REFERENCE, not fresh content: RESOLVE it to the ONE canonical grounded record via `aspectRec
          # ref.key` (the same record a `neededBy`/policy-edge reference to it yields — dedup-coherent), rather
          # than re-grounding the reference's own materialized buckets in place. `translateAspect` already
          # ground its class keys, split its nested sub-aspects, and normalized its includes ONCE at the
          # registry mapAttrs site, so this delegates all of that (den-hoag does LESS) and cannot
          # double-process. The record is returned WHNF (its `.includes` thunk is forced later by
          # resolved-aspects, which carries the seen-dedup), so the registry-graph walk never cycles here.
          # The `isString ref.key` guard keeps the membership test's `${ref.key}` interpolation from
          # coerce-THROWING on a malformed non-string `.key` — such a ref falls to the inline `groundRec` arm,
          # whose §2.2 dispatch names the offending key clearly rather than a raw coercion error.
          #
          # THE DISCRIMINATOR IS REGISTRY MEMBERSHIP, NOT `id_hash` (holdover dissolution). This arm formerly
          # gated the STATIC branch on `!(ref ? id_hash)`, reading id_hash-presence as "already a den-hoag
          # RESOLVED record — pass through". gen-aspects now mounts an UNCONDITIONAL `id_hash` option on EVERY
          # typed aspect submodule (the universal `aspectId` content-address) — the `id_hash` submodule option
          # in gen-aspects/lib/types.nix — so a PRE-grounding typed nav node carries id_hash alongside its
          # native `.key` and its v1-spelled un-grounded class buckets (an empty `homeManager` deferredModule
          # on every node, from types.nix `classOptions`) — the old guard then passed it through UN-grounded
          # and `homeManager` aborted §2.2 at `classifyKey` (concern-aspects.nix; the kernel registers only the
          # kebab `home-manager`). den-hoag must NEVER key control flow on an identity marker: a REFERENCE is
          # discriminated by STRUCTURE (its key names a registered aspect), and identity (gen-native aspectId)
          # is orthogonal to the v1ClassKeyMap grounding this arm exists for (a permanent compat-dialect
          # translation). An inline literal ALSO carries a `.key` (a POSITIONAL path, `h4/includes/0`) but is
          # NOT a registry member, so it falls to `groundRec` below — the structural split, not id_hash.
          aspectRec ref.key
        else if builtins.isAttrs ref then
          # INLINE CONTENT with no registry identity (an anonymous `{ nixos… }` literal, a `{ name }` bare
          # reference, an unregistered positional node): GROUND its class keys in place, split off nested
          # sub-aspects, and recurse its includes. A `{ __isPolicy; fn }` policy record NEVER reaches here —
          # every include arm diverts it at its own grain, mirroring v1 (children.nix:70-72: `processInclude`'s
          # FIRST arm routes an `__isPolicy` include to `register-aspect-policy`, never the aspect walk): a
          # `den.schema.<kind>.includes` record via `isPolicyRef` → `kindIncludePolicies`; a record nested in a
          # REGULAR aspect's `.includes` via `keepInclude` above (#65, ledger u16 — the `normalizeList` filter
          # + the `aspectIncludePolicies` static walk; the old "corpus-zero" claim for this grain was FALSIFIED
          # by corpus users/sini.nix:4 → the host-aspects battery, u15). A MALFORMED fn-bearing attrset that is
          # NOT a policy record (no `__isPolicy`/`__denCanTake` — e.g. `{ name; fn; }`) still grounds here and
          # its `fn` key aborts at the §2.2 three-branch dispatch — self-announcing, never a silent drop.
          groundRec name (stampIdentity name ref)
        else
          ref;
      # Ground an aspect attrset's class keys, SPLIT OFF its nested sub-aspect keys, AND recurse its
      # `.includes` under a per-position name path — this grounds inputs'/self's nested static
      # `{ homeManager._module.args… }` → `home-manager` and wraps a nested bare fn (transitive), each
      # child keyed distinctly under `${name}:include`.
      #
      # NO NESTED SPLIT (Model C): v1 never auto-walks a nested sub-aspect ("sub-aspects are never auto-walked
      # … they activate via explicit `includes`", v1 key-classification.nix:67-68 @ pin), and neither does
      # den-hoag — a nested sub-aspect persists as a typed freeform aspect NODE the closed gate admits and the
      # class-modules content walk skips (`classifyKey` routes it `facet`). It is re-reachable by explicit
      # navigation. So `groundRec` grounds the class keys + normalizes `.includes`, leaving nested nodes in
      # place.
      groundRec =
        name: attrs:
        groundKeys attrs
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
    if builtins.isAttrs ref && ref ? key then
      # A typed navigation node (a `den.aspects.<path>` ref off the annotated tree) carries its NATIVE
      # gen-aspects `.key` — the FULL container-relative slash-path (`core/secrets/collector`), the
      # identity born in the type (flake-module.nix typedCompileTree). Resolve by that native key so a
      # NESTED ref grounds to its (path-keyed) registry entry. A top-level node's `.key` equals its
      # `.name` (both the top-level registry key), so this is byte-stable there; only a nested node —
      # whose `.name` is the LAST SEGMENT alone (`collector`) — diverges, and it is exactly the nested
      # node that the `.name` lookup missed (an empty stub → zero content). Prefer `.key` over `.name`.
      #
      # Every navigable REFERENCE resolves via the registry FIRST — `.key` (here), `.name`, then a bare
      # string — and the `id_hash` pass-through is LAST (holdover dissolution): den-hoag must NEVER key
      # control flow on an identity marker. gen-aspects now mounts an UNCONDITIONAL `id_hash` option on EVERY
      # typed aspect submodule (the universal `aspectId` content-address) — the `id_hash` submodule option in
      # gen-aspects/lib/types.nix — so a typed nav node carries id_hash ALONGSIDE its native `.key` and its v1-spelled
      # un-grounded class buckets. With the old id_hash-FIRST order it short-circuited to the pass-through and
      # delivered its RAW un-grounded content (a `homeManager` bucket aborting §2.2 at classifyKey / an empty
      # registry stub). A REFERENCE is discriminated by STRUCTURE (it carries a navigable `.key`/`.name`); the
      # emitted-content-set and bare-fn arms divert upstream (translateEffect ~:843-854), so a key-bearing ref
      # is ALWAYS a registry address — look it up.
      aspectRec ref.key
    else if builtins.isAttrs ref && ref ? name then
      aspectRec ref.name
    else if builtins.isString ref then
      aspectRec ref
    else if builtins.isAttrs ref && ref ? id_hash then
      # A record carrying id_hash but NEITHER a `.key` NOR a `.name` — NOT a navigable reference — pass it
      # through (satisfies declare.edge's A2; the residual case, e.g. a synthetic A2-satisfaction stub). This
      # arm is LAST BY DESIGN: a `.key`/`.name`-bearing reference MUST resolve via the registry arms above and
      # must NEVER reach this pass-through — returning it verbatim would deliver its un-grounded/empty content
      # instead of the canonical registry record (an empty-stub / §2.2 regression). Only a keyless AND nameless
      # record — which no registry lookup could resolve — legitimately passes through here.
      ref
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
  # grounded, and the v1-only structural keys are dropped. A nested sub-aspect is NOT split off — it persists
  # as a typed node the closed gate admits (Model C); the class-modules walk skips it (routes `facet`).
  translateAspect =
    normalizeList: name: aspect:
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
            # Under Model C a nested sub-aspect (blade's `sini`/`shuo`) is NOT stripped — it persists as a typed
            # freeform aspect NODE (identity-bearing) that the closed gate admits and the class-modules content
            # walk skips (`classifyKey` routes it `facet`, since `keyCategory` is null); it is registered
            # separately (`collectNestedAspects`) and re-reachable via explicit `includes`. v1 never auto-walks a
            # nested aspect, and neither does den-hoag — the node just carries no class content at the parent's
            # scope. So the parent's content is the grounded map verbatim.
            parent = grounded;
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
  # value with neither `key` nor `name` (the scope-coord fallback). A bare `{ name }`/`{ id_hash; name }`
  # reference, a functor, and a policy record are NOT content sets.
  #
  # THE DISCRIMINATOR IS `(v ? key || !(v ? name))` (holdover dissolution): a content set is either a
  # key-bearing navigated node or a key-less/name-less synthetic value; every REFERENCE stub carries a `name`
  # WITHOUT a `key`, so it is excluded here and routed to `resolveAspectRef` for registry lookup. This arm
  # formerly ALSO gated `!(v ? id_hash)` as a "not-an-already-resolved-record" proxy — but gen-aspects now
  # mounts an UNCONDITIONAL `id_hash` option on EVERY typed aspect submodule (the universal `aspectId`
  # content-address) — the `id_hash` submodule option in gen-aspects/lib/types.nix — so a navigated content
  # set now carries id_hash and that clause EXCLUDED it — misrouting the emit to `resolveAspectRef`, whose registry
  # lookup MISSES a strip-only nested sub-aspect (`blade/shuo`, never registered) and returns an empty stub
  # (the C1 zero-content gap). The clause was redundant for the reference cases it meant to catch (a
  # `{ id_hash; name }` stub has a `name` and no `key`, so it is already excluded); dropped.
  isEmittedContentSet =
    v:
    builtins.isAttrs v
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
    ing: normalizeList: aspectRec: policyId: ctx: effectIdx: effect:
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
      [ (pipeLib.compilePipe declare policyId effectIdx effect.value) ]
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
  compilePolicy = ing: normalizeList: aspectRec: policyId: value: {
    gate = fnArgsOf (innerFn value);
    # `imap0` threads each effect's within-policy index (its position in the body's effect list) into
    # `translateEffect` alongside the owning policy identity — the per-declaration disambiguator a compiled
    # deriving `pipe.from` folds into its gen-pipe declaration-`site` (pipe.nix `compilePipe`).
    fn =
      ctx:
      builtins.concatLists (
        prelude.imap0 (translateEffect ing normalizeList aspectRec policyId ctx) (innerFn value ctx)
      );
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
  compileCanTake = ing: normalizeList: aspectRec: policyId: value: {
    # The route's fixed SHAPE retires into an explicit `__condition` coord set — the coords it gates
    # on, in the `functionArgs` shape (`false` = required). A hand-written formal lambda per shape is no
    # longer needed now that a rule's gate can be declared as data.
    gate =
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
    fn =
      ctx:
      builtins.concatLists (
        prelude.imap0 (translateEffect ing normalizeList aspectRec policyId ctx) (value.fn ctx)
      );
  };

  compilePolicies =
    ing: normalizeList: aspectRec: selectsFromSchema: policies:
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
      # The fleet-wide mint carries both halves the value could not: what it emits, and where it fires.
      # `mintFleetWide name ungated gated` — the record is the GATED one (suppression is dispatch), but the
      # codomain is recovered from the UNGATED body (a codomain is a static property of the body). See
      # `familyStamps` for why the two must not be the same value.
      mintFleetWide =
        name: ungated: gated:
        gated
        // {
          emits = emitsFor (policies.${name}.emits or null) name ungated.gate ungated.fn;
          # DECLARATION BEATS DERIVATION, and the absence is the thing being decided. `selectsFromSchema`
          # encodes "a v1 policy fires only where its schema INCLUDES it" — true of a v1 USER policy, and
          # false of a shim-synthesised AMBIENT global, which has no includes entry because it is not a v1
          # declaration at all (v1's equivalent binds at flake scope and is inherited fleet-wide). Those
          # mechanisms therefore DECLARE `selects` on their own record, and a declared value wins —
          # including `null`, which is a real value here and not a missing key. Only an UNDECLARED
          # selection is derived from the schema.
          selects = if policies.${name} ? selects then policies.${name}.selects else selectsFromSchema name;
        };
    in
    {
      policies =
        # #72: every name-keyed compiled policy consults the suppression key before producing (the v1
        # name IS the attr key here — user-to-host etc.), so a pre-pass-collected exclude suppresses it
        # at the emitting scope + descendants.
        prelude.genAttrs policyNames (
          name:
          let
            ungated = compilePolicy ing normalizeList aspectRec name policies.${name};
          in
          mintFleetWide name ungated (gateSuppression name ungated)
        )
        // prelude.genAttrs canTakeNames (
          name:
          let
            ungated = compileCanTake ing normalizeList aspectRec name policies.${name};
          in
          mintFleetWide name ungated (gateSuppression name ungated)
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
  # The §9.5 aspect-content gate handle for THIS fleet — `translateAspect` self-applies it to its desugared
  # output so a typo throws NAMED at the closed gate (at resolution, lazily). Built for the GROUNDED class +
  # quirk vocabulary `translateAspect` produces (a legit `home-manager` bucket is recognized, not rejected).
  gateAspect = mkGateAspect {
    classNames = allClassNames;
    quirkChannels = builtins.attrNames (v1Decls.quirks or { });
  };
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
  normalizeList =
    mkNormalize gateAspect allClassNames (builtins.attrNames (v1Decls.quirks or { }))
      (if aspectIncludeArm then aspectIncludeDivertedNames else { })
      (if lateDispatch then (ref: builtins.isFunction ref && isLateDispatchFn ref) else (_: false))
      aspectRec
      aspects;
  # ATTACHMENT-RELATIVE late-dispatch, for the arm that attaches a bare-fn include at a KNOWN kind's
  # nodes (the `den.schema.<K>.includes` synthetic-aspect arm below). The global `isLateDispatchFn`
  # tests `parent != null`, i.e. "the required kind is a descendant of ROOT" — correct only where the
  # include attaches at a root-ish scope (the regular-aspect / `den.default` paths). A kindInclude bare
  # fn instead attaches at K-nodes, where K's OWN coord and every ANCESTOR coord are present (inherited
  # down the P edge, structural.nix). So a required formal grounds IN PLACE iff it names K or an ancestor
  # of K; only a STRICT DESCENDANT of K is absent and must radiate. For a single-rooted schema (the
  # den/corpus case) `isLateDispatchFnFrom <root>` coincides with the global `isLateDispatchFn` — the
  # global is that root-attached case; on a multi-root schema the attachment-relative predicate is
  # strictly more correct (a sibling-root formal radiates, not grounds).
  # The kind-ancestor membership walk routes through gen-graph `ancestorsOf` over the single-parent
  # schema chain (`ing.schema.<K>.parent`): `ancestorsOf` returns baseKind's PROPER ancestors (self
  # excluded), so the `k == baseKind ||` prefix supplies the reflexive case. Consumed inside
  # `builtins.any`, so membership is order-independent and gen's nearest-first traversal is byte-neutral.
  presentAtKind =
    baseKind: k:
    k == baseKind
    || builtins.elem k (graph.ancestorsOf { parent = kk: ing.schema.${kk}.parent or null; } baseKind);
  isLateDispatchFnFrom = baseKind: fn: builtins.any (k: !(presentAtKind baseKind k)) (firesAtOf fn);
  # Per-kind `normalizeList` — MIRRORS the global's four args, swapping ONLY the radiate/divert predicate
  # for the attachment-relative one so a bare-fn `schema.<K>.includes` grounds at its K-nodes instead of
  # being force-radiated. Honours the `lateDispatch` toggle identically (off → never divert).
  normalizeListForKind =
    kind:
    mkNormalize gateAspect allClassNames (builtins.attrNames (v1Decls.quirks or { }))
      (if aspectIncludeArm then aspectIncludeDivertedNames else { })
      (
        if lateDispatch then (ref: builtins.isFunction ref && isLateDispatchFnFrom kind ref) else (_: false)
      )
      aspectRec
      aspects;

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
      # `isAttrs v.${k}` is a READINESS-guarded force: with the gate unmasked, forcing a TYPO freeform child
      # (`bad.nixxos = "x"`) throws — but this STATIC walk runs over EVERY aspect, resolved or not, so an
      # UNRESOLVED typo aspect must not abort the build (the laziness contract). A child that throws when its
      # WHNF is forced is not a walkable namespace here; resolution still aborts on it when the owning aspect is
      # resolved (class-modules content walk). This is the flagged readiness guard, not a value-heuristic.
      childIsWalkableNamespace =
        v: k:
        let
          r = builtins.tryEval (builtins.isAttrs v.${k});
        in
        r.success && r.value;
      walkableChild =
        v: k:
        !(prelude.hasPrefix "__" k)
        && !(v1StructuralKeysSet ? ${k})
        && !(classSet ? ${v1ClassKeyMap.${k} or k})
        && !(quirkSet ? ${k})
        && childIsWalkableNamespace v k;
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
      # UNIFORM-FRAME MAPPING onto gen-graph's ordered `foldPreorder`: policy record, late-dispatch bare
      # fn, and aspect attrset all ride ONE frame type; `expand` classifies by ref type. This REPRODUCES
      # v1's interleave EXACTLY — a nested attrset include recurses inline (DFS pre-order) BEFORE a later
      # sibling policy is collected — because an aspect frame's children are `includes ++ walkableChildren`
      # in that order and the fold is depth-first pre-order (`expand` sees `acc` before any child does).
      # A classify-includes-then-children mapping would REORDER (append every sibling policy after the
      # child recursion) and is NOT faithful.
      isBareFnFrame = f: isBareFnRef f && isLateDispatchFn f;
      # cycle-guard / first-occurrence key. An aspect attrset guards by its structural `.key` (`idOf` —
      # aspect dedup, first occurrence). A policy / late-dispatch bare-fn / inert frame is UNGUARDED
      # (`null` → per-occurrence; a policy is collected wherever it is reached, never deduped by the
      # visited set). `idOf` is only ever computed on an attrset (a non-attrs frame short-circuits to null),
      # mirroring v1's `go`, which read `idOf` only past its `!(isAttrs v)` guard.
      frameKey =
        frame:
        if isPolicyRef frame || isBareFnFrame frame then
          null
        else if builtins.isAttrs frame then
          idOf frame
        else
          null;
      walkableChildFrames = v: map (k: v.${k}) (builtins.filter (walkableChild v) (builtins.attrNames v));
      # An aspect frame's ordered successors: its `.includes` list elements FIRST (the interleave source),
      # then its walkable namespace/sub-aspect children — the exact order v1's `go` folded them in.
      childFrames =
        v:
        (
          let
            i = v.includes or null;
          in
          if builtins.isList i then i else [ ]
        )
        ++ walkableChildFrames v;
      # Classification is path-INDEPENDENT here (every frame is typed by ref, wherever it was reached),
      # vs the pre-`foldPreorder` walk which classified policy/bare-fn refs only inside the includes-fold.
      # Byte-equivalent by invariant: a policy record (`__isPolicy`, an attrs) only ever appears in a
      # `.includes` list — walkable children are sub-aspects/namespaces (`walkableChild` excludes policy
      # records + bare fns), so a policy is never reached as a walkable child. A policy at a namespace key
      # (`den.aspects.foo.<key> = <policy record>`) is malformed and impossible on valid/corpus input.
      expandFrame =
        acc: frame:
        if isPolicyRef frame then
          {
            acc = acc // {
              recs = acc.recs ++ [ frame ];
            };
            children = [ ];
          }
        # LATE-DISPATCH RADIATION (§5.2): a bare-fn include that genuinely LATE-DISPATCHES — requires a DESCENDANT
        # entity coord absent where it attaches (`isLateDispatchFn`, the SAME predicate `radiatedBareFn`
        # the node-local walk diverts by) — RADIATES as a synthetic aspect + edge policy (below). An
        # in-place or no-entity-formal bare fn is inert here (a leaf frame, no children) and keeps the
        # node-local `wrapGatedFn` path.
        else if isBareFnFrame frame then
          {
            acc = acc // {
              bareRecs = acc.bareRecs ++ [ frame ];
            };
            children = [ ];
          }
        else if builtins.isAttrs frame then
          {
            inherit acc;
            children = childFrames frame;
          }
        else
          {
            inherit acc;
            children = [ ];
          };
      walked =
        (graph.foldPreorder {
          roots = builtins.attrValues v1Aspects;
          key = frameKey;
          expand = expandFrame;
          acc = {
            recs = [ ];
            bareRecs = [ ];
          };
        }).acc;
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
          let
            ungated = compilePolicy ing normalizeList aspectRec "__aspectInclude__${ref.name}" ref;
            compiled = gateSuppression (ref.name or null) ungated;
          in
          compiled // familyStamps ref ungated // { selects = selectsOfFormals firesAt; };
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
            gate = fnArgsOf s.fn;
            selects = selectsOfFormals s.firesAt;
            emits = [ "edge" ];
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

  # THE SELECTION ABSENCE, said rather than implied. A `den.policies.<name>` DEFINITION is a registry
  # entry; `den.schema.<K>.includes` is what puts it into DISPATCH. A name in no `includes` list selects
  # NOTHING (`[ ]`) — which is v1's behaviour, where a policy fires only where it is INCLUDED and never by
  # `den.policies` presence alone, and which answers a registered-but-unreferenced policy firing at every
  # node in the fleet. The two absences are now different VALUES: `[ ]` here, against `null` for a record
  # whose formals leave its attachment dynamic (`selectsOfFormals`). The kernel learns no kind NAMES from
  # this — `ing.kindIncludes` is data, and `expandRefs` is the same flattening the include arms use.
  namesRef =
    name: refs:
    builtins.elem name (builtins.filter (n: n != null) (map (r: r.name or null) (expandRefs refs)));
  includedAt =
    name: builtins.attrNames (prelude.filterAttrs (_: refs: namesRef name refs) ing.kindIncludes);
  # Is `k` a STRICT descendant of `anc` under the containment schema? The walk is up `parent`, which is
  # the same relation v1's `foldScopeAncestors` walks when it resolves a subtree-scoped constraint.
  isStrictDescendant =
    anc: k:
    let
      up =
        cur:
        if cur == null then
          false
        else if cur == anc then
          true
        else
          up (ing.kindParent.${cur} or null);
    in
    k != anc && up (ing.kindParent.${k} or null);
  # `den.schema.<K>.excludes` — SUBTREE-scoped in v1, per-KIND here, so only the case where those two
  # extents COINCIDE is honoured: the excluded policy attaches at K itself, and removing K from its
  # selection is exact. A policy attaching at a strict DESCENDANT of K aborts by name rather than being
  # flattened into a fleet-wide kind removal (which would suppress more than the declaration asks). A
  # policy attaching anywhere else is untouched: an exclude at K cannot reach outside K's subtree.
  # The kinds whose `excludes` name this policy.
  excludedAtKinds =
    name:
    builtins.attrNames (prelude.filterAttrs (_: refs: namesRef name refs) (ing.kindExcludes or { }));
  isExcludedAtKind = kind: name: name != null && builtins.elem kind (excludedAtKinds name);
  # THE LOUD GAP, forced ONCE PER FLEET rather than per arm, so a descendant-scoped exclude is refused at
  # the schema even when nothing forces the arm it would have suppressed. `null` when every exclude in the
  # schema is representable per-kind; otherwise the first named violation.
  excludeScopeCheck =
    let
      violations = prelude.concatMap (
        kind:
        prelude.concatMap (
          name:
          map (bad: errors.excludeSubtreeUnrepresentable kind name bad) (
            builtins.filter (isStrictDescendant kind) (includedAt name)
          )
        ) (builtins.filter (n: n != null) (map (r: r.name or null) (expandRefs ing.kindExcludes.${kind})))
      ) (builtins.attrNames (ing.kindExcludes or { }));
    in
    if violations == [ ] then null else builtins.head violations;
  selectsFromSchema = name: builtins.filter (k: !(isExcludedAtKind k name)) (includedAt name);
  compiledPolicies = compilePolicies ing normalizeList aspectRec selectsFromSchema v1Policies;

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
  #     `{ includes = […]; }` sub-aspect). Served by THIS rung: a nested sub-aspect persists as a typed node
  #     (the class-modules walk skips it), and the include arm re-wraps the emitted value with the
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
                    { includes = (normalizeListForKind kind) "${synthName}:include" [ ref ]; }
                  else
                    builtins.head ((normalizeListForKind kind) "${synthName}:content" [ ref ]);
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
              gate = kindCoord;
              selects = [ kind ];
              emits = [ "edge" ];
              fn = _ctx: map (ref: declare.edge (resolveAspectRef aspectRec ref)) edgeRefs;
            };
          };
          policyPolicies = builtins.listToAttrs (
            prelude.imap0 (i: ref: {
              name = "__kindInclude__${kind}__policy__${toString i}";
              value =
                let
                  ungated =
                    compilePolicy ing normalizeList aspectRec "__kindInclude__${kind}__policy__${toString i}"
                      ref;
                  base = gateSuppression (ref.name or null) ungated;
                in
                base
                // familyStamps ref ungated
                // {
                  gate = kindCoord // base.gate;
                  # `den.schema.<kind>.excludes` naming this policy removes it from THIS kind's selection.
                  # Same-kind only; a descendant-scoped exclude has already aborted (`excludeScopeCheck`).
                  selects = if isExcludedAtKind kind (ref.name or null) then [ ] else [ kind ];
                };
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

  # NESTED-ASPECT REGISTRY (the `core.secrets.collector` rung). `translateAspect` STRIPS an aspect's
  # nested sub-aspects from its parent (the §2.2 nested-key split, key-classification.nix:69-80) — so a
  # nested aspect never appears in the top-level `mapAttrs` registry below. But a `den.aspects.<path>`
  # NAMED reference (a typed nav node on `schema.<kind>.includes`, or a policy-emitted ref) resolves via
  # `resolveAspectRef` by the node's NATIVE `.key` — the full slash-path (`core/secrets/collector`).
  # Register every nested aspect under that native path so the ref grounds to REAL content; without it the
  # edge attaches an EMPTY stub (`resolveAspectRef` fell back to the last-segment `.name`, a registry miss)
  # → zero class/channel content (the corpus `age.secrets = {}` drop, and the firewall/resolved-user
  # collectors alongside). Each node is translated by the SAME `translateAspect` the top level uses — so a
  # nested node's v1 class spellings ground and its OWN deeper children recurse to their own path entries.
  # Nested detection reads the TYPE: a freeform child that is itself a typed aspect NODE (identity-bearing,
  # carries a string `.key`) is a nested aspect, enumerated after the same grounding (`droppedAspectKeys`
  # removed + `v1ClassKeyMap` on class keys). The registry key is the TRAVERSAL PATH (parent segments ++ child
  # name, slash-joined): it equals the typed node's native `.key` on the bridge path (the native key is the
  # slash-join of the aspect chain) and is robust on the direct-`compile` path, where raw decls carry no
  # `.key` at all.
  collectNestedAspects =
    segs: aspect:
    if !(builtins.isAttrs aspect) || builtins.isFunction aspect || (aspect.__isWrappedFn or false) then
      { }
    else
      let
        withoutDropped = builtins.removeAttrs aspect droppedAspectKeys;
        grounded = prelude.foldl' (
          acc: k: builtins.removeAttrs acc [ k ] // { ${v1ClassKeyMap.${k} or k} = aspect.${k}; }
        ) withoutDropped (builtins.attrNames withoutDropped);
        # A nested child carrying legacy `provides` (or the `meta.__forward` battery marker) is NOT a
        # registry concern — the legacy `desugar` only rewrites TOP-LEVEL `provides` (legacy/provides.nix),
        # so a nested `hw.amdgpu.provides` survives here and its resolution is owned by the den-brackets /
        # nav-fallback mechanism (`resolveWithProvidesFallback`), NOT this registry. Translating it would
        # trip `translateAspect`'s C5/C1 sentinels (the very abort those legacy paths exist to avoid), so
        # exclude it from BOTH registration and the recursion (its subtree is provides-owned).
        registrable = node: !(node ? provides) && ((node.meta or { }).__forward or null) == null;
        # A nested aspect is a freeform child that is itself a typed aspect NODE (identity-bearing: carries a
        # string `.key`), structurally distinct from a class-bucket deferredModule / channel raw / facet value —
        # enumerated from the TYPE, no value-heuristic. The `tryEval` is a READINESS guard, NOT a value-
        # heuristic: with the gate on, forcing a TYPO freeform child throws (it should — at RESOLUTION), but this
        # EAGER registry fold must not turn that into a compile-time abort of an UNRESOLVED aspect (the laziness
        # contract). A child that throws when forced is not a registrable nested node here; resolution still
        # aborts on it when the owning aspect is resolved (class-modules content walk).
        probe =
          v: builtins.tryEval (builtins.isAttrs v && (v.key or null) != null && builtins.isString v.key);
        isNestedNode =
          v:
          let
            r = probe v;
          in
          r.success && r.value;
        nestedKeys = builtins.filter (k: isNestedNode grounded.${k} && registrable grounded.${k}) (
          builtins.attrNames grounded
        );
      in
      prelude.foldl' (
        acc: k:
        let
          childSegs = segs ++ [ k ];
          path = builtins.concatStringsSep "/" childSegs;
          # A FLAT registry entry whose whole identity is its slash-PATH. `aspectRec path` stamps
          # `name = path` (ingest.aspectEntry), and resolved-aspects re-derives a node's key as
          # `pathKey (meta.aspect-chain ++ [ name ])` (gen-aspects identity; cf. legacy/provides.nix's
          # aspect-chain zeroing). The typed node carries `meta.aspect-chain = <parent segments>`, so
          # WITHOUT zeroing it the derived key DOUBLES the prefix (`grp/sub/` + `grp/sub/coll`). Zero the
          # chain (flat aspect, no container) and set `.key = path` so the derived key is the path itself —
          # the native identity a top-level ref already yields, extended to the nested path.
          translated = translateAspect normalizeList k grounded.${k};
          flatEntry = translated // {
            key = path;
            meta = (translated.meta or { }) // {
              aspect-chain = [ ];
            };
          };
        in
        acc // { ${path} = flatEntry; } // collectNestedAspects childSegs grounded.${k}
      ) { } nestedKeys;
  nestedAspects = prelude.foldl' (
    acc: name: acc // collectNestedAspects [ name ] v1Aspects.${name}
  ) { } (builtins.attrNames v1Aspects);

  # The top-level `mapAttrs` result is folded LAST so a genuine top-level v1 aspect literally NAMED with a
  # slash (a quoted `den.aspects."a/b"`, corpus-zero) always wins over a nested slash-path entry.
  aspects =
    nestedAspects
    // builtins.mapAttrs (translateAspect normalizeList) v1Aspects
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
  # `excludeScopeCheck` is forced on the WHOLE policy set, not on one arm: a policy wired through a
  # kind-include never touches `compiledPolicies`, so seq-ing it there would leave the schema's own
  # violation unforced for exactly the shape it describes.
  policies = builtins.seq excludeScopeCheck (
    (builtins.removeAttrs compiledPolicies.policies includeReferencedNames)
    // kindIncludePolicies
    // aspectIncludePolicies
    // aspectIncludeBareFnArm.policies
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
