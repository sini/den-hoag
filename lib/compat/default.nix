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
  compile = import ./compile.nix {
    inherit
      prelude
      ingest
      errors
      sentinels
      aspects
      ;
    inherit (denHoag) declare;
    # den-hoag's built-in class set (`denHoag.classes` = nixos/darwin/home-manager/k8s-manifests) — the
    # `cnf.classes` `wrapFn` needs to route a v1 bare-fn include's class content (§339 wrap-ground).
    builtinClasses = builtins.attrNames denHoag.classes;
    # THE R2 RESOLVE-FAMILY TAG SET (`den.resolveFamilyNames`) — the SINGLE source shared with
    # flake-module's `resolveFamilyModule`, so the kind-include compilation stamps `__resolveFamily` on a
    # synthetic-keyed include policy whose source ref is a corpus resolve policy (else the pre-pass feed is
    # empty and the corpus resolve chain never fires).
    resolveFamilyNames = import ./resolve-family-names.nix;
  };
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
  # The BRIDGE-REGISTRY PASSTHROUGH (replaces the per-host instance-eval harvest): v1's built-in
  # `options.den.hosts` registry (pin 11866c16 modules/options.nix:71 / entities/host.nix:26-105)
  # reproduced with the CONSUMER's nixpkgs lib (an inert call argument; the file imports no nixpkgs),
  # plus the STRUCTURAL EXCLUSION classifier + stamp builder the bridge's `_entityStamps` uses for
  # EVERY discovered kind's registry. Consumed by the bridge + the compat-host-registry unit suite.
  registry = import ./registry.nix { };
  # board #58 (Fork A): the post-fold `__provider` annotation walk (v1 annotateDeep, pin
  # types.nix:561-574) — applied by the bridge (corpus path) and the flake-module wiring (direct
  # mkDen path), each idempotently, so every navigated `den.aspects` value carries its provenance
  # path and compile's `stampProvider` can recover v1's include identity. `batteryClassNames` (#67,
  # ledger u17): the legacy batteries' registered classes (os/user) are excluded like the built-ins —
  # v1's guard reads the REGISTERED `den.classes` (types.nix:540), which on a v1 fleet always carries
  # the battery classes; the shim's walk runs pre-desugar, so the static `registersClasses` names are
  # baked here instead (no ordering cycle — battery-module data, not fleet config; lazy let, cycle-free:
  # `legacy` never references `annotateLib`).
  annotateLib = import ./annotate.nix {
    inherit prelude;
    builtinClassNames = builtins.attrNames denHoag.classes;
    batteryClassNames = legacy.defaults.registeredClasses;
  };
  # The projected hasAspect entity surface (v1 PR #602 semantics; the den-hoag dissolution). `stampProvider`
  # is the SINGLE identity source compile.nix's include-grounding ALSO imports (path-cached ⇒ one definition,
  # no duplication), so a `host.hasAspect den.aspects.<path>` ref keys IDENTICALLY to the resolved-aspects
  # node it answers for (W2). `refKey`/`mkEnrich` bind the gen-aspects identity; the schema entity-kind set
  # is bound per-fleet at the bridge (flake-module.nix `mkFleetModuleWith` → `den.enrichBindings`).
  stampProviderLib = import ./stamp-provider.nix { inherit prelude; };
  hasAspect = import ./has-aspect.nix {
    inherit aspects;
    inherit (stampProviderLib) stampProvider;
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
  # The v1 `pipe.expose` ASCENT twin (#62b) — the `den.channelGather` supplier that fills the core #62a
  # channel-augmentation seam with den v1's cross-scope gather (`collectAllExposed`). Imported here so the
  # witness suite reaches the gather algorithm directly (`gatheredAt`), and passed into the wiring.
  exposeGatherLib = import ./expose-gather.nix { inherit prelude; };
  mkWiring =
    legacyArg:
    import ./flake-module.nix {
      inherit
        denHoag
        prelude
        schema
        compile
        ingest
        hasAspect
        ;
      annotate = annotateLib.annotateAspects;
      exposeGather = exposeGatherLib;
      legacy = legacyArg;
    };
  flakeModuleWiring = mkWiring legacy;
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
  # The v1 `pipe.expose` ascent twin (#62b) — the `den.channelGather` supplier + its gated-transitive
  # gather algorithm (`gatheredAt`), exposed for the witness suite's depth-semantics unit tests.
  exposeGather = exposeGatherLib;
  # The bridge-registry passthrough (ship-gate M2's successor architecture) — the v1 hosts-registry
  # declaration + the structural-exclusion stamp machinery the bridge mounts.
  inherit registry;
  # board #58 (Fork A) — the post-fold `__provider` annotation walk; the bridge applies it to the
  # merged corpus tree (both consumers: the `den` module arg + the fleet def).
  inherit (annotateLib) annotateAspects;
  # The projected hasAspect entity surface (v1 PR #602). `stampProvider` is the single include-identity
  # source (shared with compile.nix); `refKey` is the three-branch membership-key law; `mkEnrich` builds the
  # `den.enrichBindings` hook (the bridge binds the schema entity-kind set). Exposed for the witness suite.
  inherit (stampProviderLib) stampProvider;
  inherit (hasAspect) refKey mkEnrich;
  # The compat nixos instantiate wrapper builder (§2.5 carry-in), exposed as a seam: the parity harness
  # supplies `terminal = crossNixos` for a real build; the fleet wiring defaults it to `collect`.
  inherit (flakeModuleWiring) mkNixosInstantiate;
  inherit (flakeModuleWiring)
    mkFleetModule
    mkFleetModuleWith
    mkDen
    mkDenWith
    evalV1
    ;
  # `compileFull` — the "through flakeModule" compile (apply the full legacy desugars, then compile), the
  # entry a v1 surface takes under `flakeModule`. For a non-legacy surface it equals `compile` (or-identity
  # desugars); the C1 witness suite drives every witness through it uniformly. `mkWiring` is the severed-
  # variant builder the C5 suite uses to prove each legacy module removable.
  inherit (flakeModuleWiring) compileFull;
  inherit mkWiring;
  flakeModule = flakeModuleWiring.flakeModule;
  # parity — the two-sided harness (frozen edge schema + the v1/hoag oracle + firstDivergent triage),
  # Task 7. `schema` is fully self-contained; `oracle.traceHoag` needs only this tree; `oracle.mkV1` is a
  # function of the dev-time-only harness inputs (den v1 flake + nixpkgs) the `parity/` flake supplies.
  parity = import ./parity { inherit denHoag prelude edgeCore; };
}
