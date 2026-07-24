# den-compat (L4) — the den v1 compatibility shim over the shipped den-hoag assembly. Pure
# vocabulary translation: `compile : v1Decls → den-hoag concern declarations` (Law C2 — no
# evaluation, no scope-graph reads, no resolved-state reads), fed to `denHoag.mkDen`. The legacy
# surfaces (`provides`, `forwards`) ride as self-contained tagged modules, removable without touching
# anything else (§2.1 — the severance surface is the entry-point list).
#
# `flakeModule = flakeModuleCore ++ [ legacy.provides legacy.forwards ]`: importing `flakeModule`
# gives the full v1 declaration surface; importing `flakeModuleCore` gives it MINUS the legacy
# surfaces (using a severed surface then becomes a definition-time error, Law C5).
{
  denHoag,
  prelude,
  schema,
  aspects,
  edge,
  edgeCore,
  ...
}@deps:
let
  errors = import ./errors.nix { inherit prelude; };
  # Legacy-surface sentinels (Law C5's error half): the shim core's knowledge that `provides`/`forwards`
  # EXIST, so compile can refuse an un-desugared key when the legacy module is severed. Core file
  # (references only `errors`, never a legacy module) — severability holds.
  sentinels = import ./sentinels.nix { inherit errors; };
  # The ingestion boundary (Law C6): the ONE place v1 name-strings become id_hash-bearing entries.
  ingest = import ./ingest.nix {
    inherit
      denHoag
      prelude
      schema
      errors
      ;
  };
  # The pure compile core (Law C2): v1 declarations → den-hoag concern declarations. `declare` is
  # den-hoag's declaration-constructor vocabulary (the policy-effect translation targets, including the
  # `delivery` intent kind); the gen-edge record is rendered from that intent later, at the firing node.
  # The constant args (shared by every wiring); the two den.features desugar-arm gates
  # (`aspectIncludeArm`/`lateDispatch`) VARY per wiring, so `mkCompile` bakes them per feature record.
  compileBaseArgs = {
    inherit
      prelude
      ingest
      errors
      sentinels
      aspects
      schema
      ;
    inherit (denHoag) declare aspectIdHash;
    # den-hoag's built-in class set (`denHoag.classes` = nixos/darwin/home-manager; k8s-manifests is
    # compat-provisioned via builtins.nix, arriving through the corpus's `den.classes`) — the
    # `cnf.classes` `wrapFn` needs to route a v1 bare-fn include's class content (§339 wrap-ground).
    builtinClasses = builtins.attrNames denHoag.classes;
    # THE R2 RESOLVE-FAMILY TAG SET (`den.resolveFamilyNames`) — the SINGLE source shared with
    # flake-module's `resolveFamilyModule`, so the kind-include compilation stamps `__resolveFamily` on a
    # synthetic-keyed include policy whose source ref is a corpus resolve policy (else the pre-pass feed is
    # empty and the corpus resolve chain never fires).
    resolveFamilyNames = import ./resolve-family-names.nix;
    # THE #72 EXCLUDE-FAMILY TAG SET (`den.excludeFamilyNames`) — the twin knob's single source
    # (exclude-family-names.nix), shared with flake-module's excludeFamilyModule.
    excludeFamilyNames = import ./exclude-family-names.nix;
  };
  # `mkCompile feat` — the per-feature compile: bakes the two desugar-arm gates from the wiring's feature
  # record (register compat-feature-register.md). All-on (`defaultFeatures`) reduces to the unconditional
  # surface, byte-identical. The external `compile`/`compileFull` API stays 1-arg (the fleet fn is NOT
  # curried) — a per-wiring compile is a distinct closed core, so `compile fx` callers are unaffected.
  mkCompile =
    feat:
    import ./compile.nix (
      compileBaseArgs
      // {
        inherit (feat) aspectIncludeArm lateDispatch;
      }
      # `familyStamps` off ⇒ collapse the resolve/exclude tag sets to the kernel-identity `[ ]` at the
      # compile half (ATOMIC with the flake-module seam-module omit below — see mkDenWith; collapsing one
      # site alone desyncs the two `den.{resolveFamilyNames,excludeFamilyNames}` writers). All-on keeps the
      # `compileBaseArgs` corpus sets, byte-identical.
      // (
        if feat.familyStamps then
          { }
        else
          {
            resolveFamilyNames = [ ];
            excludeFamilyNames = [ ];
          }
      )
    );
  compile = mkCompile defaultFeatures;
  # The `deliver` surface (+ the permanent `route` / `provide` sugar): the v1 delivery-edge vocabulary
  # a corpus policy body calls. Produces inert delivery DESCRIPTORS `compile` desugars (Law C2).
  deliverLib = import ./deliver.nix { inherit prelude errors; };
  # The v1 STRUCTURAL policy verbs (`include`/`exclude`/`mkPolicy`/`pipe`): the constructor siblings of
  # the deliver surface. Inert tagged records `compile`/`pipe` already consume — constructor shape only.
  policyVerbs = import ./policy-verbs.nix { };
  # The fx key-classification surface (#49-slice): the ONE export the corpus reads
  # (`keyClassification.structuralKeysSet`), reproducing v1's literal set. Aliased into migrationLib's
  # `lib.aspects.fx.keyClassification` (flake.nix), replacing that one throwing stub.
  keyClassification = import ./key-classification.nix { };
  # The v1 `den.lib.canTake` arity predicate (den v1 nix/lib/can-take.nix). Wired via `prelude`
  # (`isFunction`/`functionArgs` = the plain builtins) — the substrate is nixpkgs-lib-free, so it closes
  # over its primitives at definition (a plain fn can't defer `lib` to evalModules). Aliased into
  # migrationLib's `canTake` (flake.nix).
  canTake = import ./can-take.nix { inherit prelude; };
  # The BRIDGE-REGISTRY PASSTHROUGH (replaces the per-host instance-eval harvest): v1's built-in
  # `options.den.hosts` registry (pin 11866c16 modules/options.nix:71 / entities/host.nix:26-105)
  # reproduced with the CONSUMER's nixpkgs lib (an inert call argument; the file imports no nixpkgs),
  # plus the STRUCTURAL EXCLUSION classifier + stamp builder the bridge's `_entityStamps` uses for
  # EVERY discovered kind's registry. Consumed by the bridge + the compat-host-registry unit suite.
  registry = import ./registry.nix { };
  # The projected hasAspect entity surface (v1 PR #602 semantics; the den-hoag dissolution). `refKey` reads a
  # ref's NATIVE `.key` directly (has-aspect.nix — no reconstruction), so a `host.hasAspect den.aspects.<path>`
  # ref keys IDENTICALLY to the resolved-aspects node it answers for (W2, both `gen-aspects.key`).
  # `refKey`/`mkEnrich` bind the identity; the schema entity-kind set is bound per-fleet at the bridge
  # (flake-module.nix `mkFleetModuleWith` → `den.enrichBindings`).
  hasAspect = import ./has-aspect.nix {
    inherit aspects prelude;
  };
  legacy = {
    provides = import ./legacy/provides.nix (deps // { inherit errors; });
    forwards = import ./legacy/forwards.nix (deps // { inherit errors; });
    # R5 (spec §10) — self-named-aspect auto-include (den v1 resolve-entity.nix:48-63). A post-compile
    # augmentation (not a pre-compile v1→v1 desugar): it reads the compiled registries + aspect records,
    # so flake-module.nix applies it as `addSelfIncludes`, gated on this module being in the wiring's
    # legacy set (severed ⇒ no self-includes, Law C5). Reproduces the per-host `den.aspects.<host>` idiom.
    self-provide = import ./legacy/self-provide.nix (deps // { inherit errors; });
    # R4 + R2/R3/R6 (spec §10) — den.default built-in MEMBERSHIP: the corpus-exercised battery ports
    # (os-class, os-user) composed into one v1→v1 desugar adding each battery's fold-bucket class (R2) +
    # built-in route policy (R3/R6). Severable — flake-module.nix `desugarLegacy` applies it only when
    # this module is in the wiring's legacy set (den v1 defaults.nix + batteries/).
    defaults = import ./legacy/defaults.nix (deps // { inherit errors; });
  };
  # flakeModuleCore — the module(s) declaring the v1 option surface as `raw`, read by a v1-shaped eval
  # whose config `compile` desugars (the two-eval shape; den-hoag's own `mkDen` owns `den.*` typed, so
  # the v1 surface cannot share its eval). `mkFleetModule`/`mkDen` bridge the compiled output to
  # `denHoag.mkDen` (spec-vs-reality flag 1). Grows the C0 skeleton's empty core to length 1.
  # mkWiring — the den-hoag-facing driver builder PARAMETERISED by a legacy-module subset (the C5
  # severance handle, §2.1). `mkWiring legacy` = the full v1 surface; `mkWiring { }` = flakeModuleCore
  # ALONE (both `desugarLegacy` halves fall back to or-identity, so a residual legacy key trips its
  # compile sentinel); `mkWiring { inherit (legacy) provides; }` = a single-legacy combination. The
  # compile core, sentinels, and errors are SHARED across every wiring — only `desugarLegacy` (hence
  # `compileFull` / `mkDen`) differs. The severability suite (compat-legacy-severed) drives all four.
  # The cross-scope channel GATHER, re-layered off the two retired hand-rolled recursions: ONE litmus-clean
  # 3-arm adapter (expose ascent #62b + collect/collectAll twins #69 + the push-dual broadcast arm). The
  # EXPOSE arm's transitive ascent runs on gen-graph (`denHoag.query`, paths mode); collect/collectAll/
  # broadcast are one-hop predicate filters over the node set (no query layer). Witness surface: `gatheredAt`
  # (expose ascent) + `mkGather entityKinds` (the composed supplier, curried on `derivedBaseNames` then
  # `result`).
  gatherLib = import ./gather.nix {
    inherit prelude;
    # `denHoag.query` — the EXPOSE arm's paths-mode transitive ascent (the sole gen-graph traversal). The
    # collect/collectAll/broadcast arms are one-hop predicate filters (no query layer); `mkGather` curries
    # `derivedBaseNames` then `result` so the per-fleet indices (per-node expose pool, sibling buckets,
    # broadcaster set) build once.
    query = denHoag.query;
  };
  # `battery-names.nix` — the SINGLE source of the gateable battery names, shared with `batteries.nix`'s
  # provisioned set, so a new battery gains its `den.features.battery.<name>` flag (and enters the
  # `unknownBattery` totality boundary) automatically — no separately hand-kept names list to drift.
  batteryNames = import ./battery-names.nix;
  # `batteries.nix` curried by the feature record — `feat.battery.<name>` gates the provision (an off
  # battery drops from `config.den.batteries`, so a reference native-misses LOUD; register §3.1(b)).
  mkBatteriesModule = feat: import ./batteries.nix feat;
  # `builtins.nix` curried by the feature record — `feat.fleetContext` gates the `fleetContextEnrichModule`
  # provision (the enrich policy binding environment/secretsConfig/fleet). Flag-off OMITs the enrich from the
  # provisioning module's `imports`, so `fleet-context-enrich` drops from every fleet (the batteriesModule
  # precedent: the wiring exposes this gated module, and `flake.nix` imports the wiring's version rather than
  # the raw path, so the feature record reaches the flake-parts consumer eval). All-on ≡ the former direct
  # import, byte-identical. `declare` = den-hoag's declaration vocabulary (the enrich constructor).
  mkBuiltinsModule =
    feat:
    import ./builtins.nix {
      inherit prelude errors;
      inherit (denHoag) declare;
      inherit (feat) fleetContext flakeOutputClasses;
    };
  # The shared wiring builder both `mkWiring` (legacy-only signature — `compat-legacy-severed` drives it)
  # and `mkWiringWith` (the `den.features` front door) route through. Threads the seam-gate feature record
  # into `flake-module.nix` and exposes the (gated) battery provisioning module as `.batteriesModule`.
  mkWiringFrom =
    { legacy, feat }:
    (import ./flake-module.nix {
      inherit
        denHoag
        prelude
        schema
        aspects
        ingest
        hasAspect
        ;
      # the per-feature compile (bakes the aspectIncludeArm/lateDispatch desugar-arm gates); all-on ≡ the
      # shared `compile`, byte-identical. flake-module receives an already-feat-baked 1-arg compile.
      compile = mkCompile feat;
      gather = gatherLib;
      inherit legacy;
      features = feat;
    })
    // {
      batteriesModule = mkBatteriesModule feat;
      builtinsModule = mkBuiltinsModule feat;
    };
  mkWiring =
    legacyArg:
    mkWiringFrom {
      legacy = legacyArg;
      feat = defaultFeatures;
    };
  # `den.features` — the COMPILE-TIME feature record that generalises the `mkWiring legacyArg` legacy-subset
  # severance handle (§2.1). It is a DRIVER ARGUMENT, not a `config.den.*` runtime option: the compat
  # two-eval reads `config.den` only AFTER the wiring is already built (flake-module.nix `evalV1Raw`), so a
  # runtime flag would arrive too late to gate the wiring. Each feature defaults ON EXCEPT `flakeOutputClasses`
  # (the den v2 OPT-IN, default OFF). The `mkWiring legacy ≡ mkWiringWith { }` BYTE-IDENTITY still HOLDS — both
  # take `flakeOutputClasses = false`, so the two wirings are identical. What the opt-in changes is that
  # `defaultFeatures` is no longer all-true, so the DEFAULT wiring DE-REGISTERS the five flake-output classes:
  # `den.classes` under `mkWiringWith { }` loses five keys versus the pre-D builtins surface. The corpus stays
  # byte-identical ONLY because those five are INERT (no producing member ⇒ no edge/node/output — NOT because
  # `den.classes` is byte-identical, it is not). Flag-off drops the feature's collapse target to its identity
  # default.
  #
  # Class (a) fan-out — the LEGACY-MODULE SUBSET. Each legacy module rides the wiring iff its feature is on;
  # flag-off drops it from `legacy`, so `desugarLegacy` falls back to or-identity and a residual v1 key trips
  # that surface's Law-C5 sentinel (the `selfIncludeFn` / `interpret` seams already gate on the same
  # `legacy ? <module>` presence, so no further plumbing is needed here).
  #
  # Class (b) kernel raw seams — `hasAspect` (`den.enrichBindings` + `den.enrichContext`, ONE flag) and
  # `gather` (`den.channelGather`). Flag-off OMITS the compat override in `flake-module.nix` so the kernel's
  # own identity default stands (`{bindings,...}:bindings` / `_:_:_:{}`) — a compat-wiring change, NOT a
  # kernel edit. These are NOT legacy modules: they never enter `legacySubset`, only the seam block.
  #
  # Class (b) per-battery — `battery.<name>` (a nested sub-record). Flag-off drops the battery from the
  # provisioned `config.den.batteries`, so a reference native-misses. The names come from `battery-names.nix`.
  #
  # The closed record grows one key per WIRED rung, so an override naming a key not in it is a named totality
  # abort (`den.features` cannot silently no-op a feature it does not gate) — extended to a two-level abort
  # (`unknown` top-level + `unknownBattery` nested) so a typo'd `battery.<name>` is caught, not a silent no-op.
  featureLegacyModule = {
    provides = "provides";
    forwards = "forwards";
    selfProvide = "self-provide";
    ambientBatteries = "defaults";
  };
  legacyModuleFeature = builtins.listToAttrs (
    map (feature: {
      name = featureLegacyModule.${feature};
      value = feature;
    }) (builtins.attrNames featureLegacyModule)
  );
  # Named guard for the class-(a) legacy-module lookup: a legacy module carrying no registered feature flag
  # self-announces (a diagnostic throw, not a raw "attribute missing"). `feat.${feature}` stays safe — every
  # registered legacy feature is in `defaultFeatures`.
  legacyModuleFeatureOf =
    moduleKey:
    legacyModuleFeature.${moduleKey}
      or (throw "den.features: legacy module '${moduleKey}' has no registered feature flag (add it to featureLegacyModule)");
  defaultFeatures = (builtins.mapAttrs (_: _: true) featureLegacyModule) // {
    hasAspect = true; # class (b) — den.enrichBindings + den.enrichContext (ONE flag)
    gather = true; # class (b) — den.channelGather
    aspectIncludeArm = true; # class (c) — compile.nix `{ __isPolicy }`-in-aspect-includes diversion arm
    lateDispatch = true; # class (c) — compile.nix descendant-formal bare-fn radiation arm
    # Rung-5 Tier-2 coupling-review flags (register compat-feature-register.md):
    probeSentinel = true; # class (b) — OMIT probeSentinelModule ⇒ den.probeSentinelFields kernel `{ }`
    familyStamps = true; # class (b) — mkCompile name-sets → `[ ]` + OMIT the resolve/exclude seam modules
    fleetContext = true; # class (b) — OMIT fleetContextEnrichModule from the wiring's builtinsModule
    # The FIRST opt-in (default-OFF) feature (den v2 terminal-classes). OFF ⇒ the builtinsModule OMITs the five
    # v1 flake-SYSTEM-OUTPUT class registrations, so a nested aspect key of one of those names is a plain
    # navigable NAMESPACE. This is a DELIBERATE v1-divergence: v1 registered them unconditionally, so with this
    # default `mkWiringWith { }` de-registers them versus the pre-D builtins surface — output-neutral ONLY
    # because the five are corpus-INERT (no producing member ⇒ no edge/node; NOT because `den.classes` is
    # byte-identical — it loses five keys). `mkWiringWith { flakeOutputClasses = true; }` restores the v1
    # registration (classification for a fleet emitting flake-system outputs).
    flakeOutputClasses = false; # class (b) — OMIT the five flake-output class registrations from builtinsModule
    battery = builtins.mapAttrs (_: _: true) batteryNames; # class (b) — per-battery, nested sub-record
  };
  # Deep-merge the nested `battery` sub-record so a partial `{ battery.hostname = false; }` override keeps the
  # OTHER battery defaults on (a shallow `//` would replace the whole `battery` record with the singleton).
  mergeFeatures = a: b: a // b // { battery = a.battery // (b.battery or { }); };
  mkWiringWith =
    features:
    let
      unknown = builtins.attrNames (builtins.removeAttrs features (builtins.attrNames defaultFeatures));
      unknownBattery = builtins.attrNames (
        builtins.removeAttrs (features.battery or { }) (builtins.attrNames defaultFeatures.battery)
      );
      feat = mergeFeatures defaultFeatures features;
      legacySubset = prelude.filterAttrs (moduleKey: _: feat.${legacyModuleFeatureOf moduleKey}) legacy;
    in
    if unknown != [ ] || unknownBattery != [ ] then
      throw "den.features: unknown feature key(s) ${
        prelude.concatStringsSep ", " (unknown ++ map (b: "battery.${b}") unknownBattery)
      } (known: ${
        prelude.concatStringsSep ", " (
          builtins.attrNames (builtins.removeAttrs defaultFeatures [ "battery" ])
          ++ map (b: "battery.${b}") (builtins.attrNames defaultFeatures.battery)
        )
      })"
    else
      mkWiringFrom {
        legacy = legacySubset;
        inherit feat;
      };
  flakeModuleWiring = mkWiringWith { };
  inherit (flakeModuleWiring) flakeModuleCore;
in
{
  inherit
    compile
    ingest
    flakeModuleCore
    legacy
    ;
  # The v1 delivery-edge surface (`deliver`/`route`/`provide`) a corpus policy body calls; the compat
  # twin of den v1's `den.lib.policy.{deliver,route,provide}`.
  inherit (deliverLib) deliver route provide;
  # The v1 structural policy-verb surface (`include`/`exclude`/`mkPolicy`/`pipe`); the compat twin of
  # den v1's `den.lib.policy.{include,exclude,mkPolicy,pipe}` (policy-effects.nix), consumed by nix-config.
  inherit (policyVerbs)
    include
    exclude
    mkPolicy
    pipe
    # `resolve` — v1's fleet-resolution functor bag (policy-effects.nix:128-171), the faithful un-stub
    # aliased into migrationLib (user-delivery R2); consumed by nix-config's fleet/user/cluster policies.
    resolve
    ;
  # The fx key-classification surface (#49-slice) — `{ structuralKeysSet; }`, aliased into migrationLib.
  inherit keyClassification;
  # The v1 `den.lib.canTake` arity predicate (den v1 nix/lib/can-take.nix) — `{ __functor; atLeast;
  # exactly; upTo; }`, aliased into migrationLib.
  inherit canTake;
  # The re-layered cross-scope channel gather (3-arm adapter) — witness surface: `gatheredAt` (the
  # gated-transitive expose ascent, for the depth-semantics unit tests) + the composed `den.channelGather`
  # supplier `mkGather entityKinds` (curried on `derivedBaseNames` then `result`; expose via gen-graph
  # queryPaths, collect/broadcast as direct one-hop predicate filters with per-fleet indices precomputed once).
  gather = gatherLib;
  # The bridge-registry passthrough (ship-gate M2's successor architecture) — the v1 hosts-registry
  # declaration + the structural-exclusion stamp machinery the bridge mounts.
  inherit registry;
  # The projected hasAspect entity surface (v1 PR #602). `refKey` is a SINGLE native-`.key` lookup (the ref
  # carries its own gen identity, no reconstruction); `mkEnrich` builds the `den.enrichBindings` hook (the
  # bridge binds the schema entity-kind set). Exposed for the witness suite.
  #
  # `mkProjectedHasAspect` (PURE lookup, migrationLib) + `augment` (the resolved-aspects node identity
  # projection, consumed by has-aspect-verbs.nix's config-wired `mkEntityHasAspect` at the bridge) — v1
  # has-aspect.nix @a2f4b60 :45-54 / :56-69. Config-less halves of the accessor family whose config-wired
  # siblings (collectPathSet/hasAspectIn/mkEntityHasAspect) are bound at the bridge over `built.den`.
  inherit (hasAspect)
    refKey
    mkEnrich
    mkProjectedHasAspect
    augment
    ;
  # The compat nixos instantiate wrapper builder (§2.5 carry-in), exposed as a seam: the parity harness
  # supplies `terminal = crossNixos` for a real build; the fleet wiring defaults it to `collect`.
  inherit (flakeModuleWiring) mkNixosInstantiate;
  inherit (flakeModuleWiring)
    mkFleetModule
    mkFleetModuleWith
    mkDen
    mkDenWith
    evalV1
    annotatedViewNav
    ;
  # `compileFull` — the "through flakeModule" compile (apply the full legacy desugars, then compile), the
  # entry a v1 surface takes under `flakeModule`. For a non-legacy surface it equals `compile` (or-identity
  # desugars); the C1 witness suite drives every witness through it uniformly. `mkWiring` is the severed-
  # variant builder the C5 suite uses to prove each legacy module removable.
  inherit (flakeModuleWiring) compileFull;
  # `mkWiring` — the severed-variant builder (a legacy-module subset) the C5 suite drives. `mkWiringWith` —
  # the `den.features` front door: a compile-time feature record (default all-on) whose class-(a) fan-out
  # derives the legacy subset. `mkWiringWith { } ≡ mkWiring legacy` (byte-identical, the parity invariant);
  # `mkWiringWith { <feature> = false; }` severs that feature (the `compat-feature-severed` removability
  # gate drives one row per feature). `defaultFeatures` is the closed all-on set (the totality boundary).
  inherit mkWiring mkWiringWith defaultFeatures;
  # The (all-on) gated battery-provisioning flake-parts module — `flake.nix` imports THIS (not the raw
  # `./lib/compat/batteries.nix` path) so `den.features.battery.<name>` can drop a battery. All-on
  # (`mkBatteriesModule defaultFeatures`, `filterAttrs (_: true)`) ≡ the former direct import, byte-identical.
  inherit (flakeModuleWiring) batteriesModule;
  # The (all-on) gated builtin-provisioning module — `flake.nix` imports THIS (not the raw
  # `./lib/compat/builtins.nix` path) so `den.features.fleetContext` can drop the fleet-context enrich.
  # All-on (`mkBuiltinsModule defaultFeatures`, `fleetContext = true`) ≡ the former direct import,
  # byte-identical (the batteriesModule precedent).
  inherit (flakeModuleWiring) builtinsModule;
  flakeModule = flakeModuleWiring.flakeModule;
  # parity — the two-sided harness (frozen edge schema + the v1/hoag oracle + firstDivergent triage),
  # Task 7. `schema` is fully self-contained; `oracle.traceHoag` needs only this tree; `oracle.mkV1` is a
  # function of the dev-time-only harness inputs (den v1 flake + nixpkgs) the `parity/` flake supplies.
  parity = import ./parity { inherit denHoag prelude edgeCore; };
}
