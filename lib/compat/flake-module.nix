# The den-hoag-facing wiring (spec-vs-reality flag 1: den-hoag has `mkDen userModules`, not a
# `flakeModule`). Two pieces:
#
#   - `flakeModuleCore` — the module(s) that DECLARE the v1 option surface as `raw`, so the v1 grammar
#     rides untouched through a module eval. den-hoag's own `mkDen` declares `den.aspects`/`den.classes`/
#     `den.schema`/… with its OWN types, so the v1 surface cannot be read in the SAME eval (two typed
#     declarations at one path conflict). It is therefore read in a SEPARATE v1-shaped eval (`evalV1`),
#     whose config `compile` desugars — the "two-eval" shape the spec's "importing den-hoag's flakeModule
#     underneath" resolves to. `flakeModule = flakeModuleCore ++ [ legacy.* ]` is the severance surface.
#   - `mkFleetModule` — the PURE bridge: `compile`'s five-key output → ONE den-hoag module setting
#     `config.den.*`. No option is redeclared here (it EMITS den-hoag config), so no collision. This is
#     what `denHoag.mkDen` consumes.
#
# `mkDen` ties them: eval the v1 modules in the v1-shaped tree, compile, bridge, hand to `denHoag.mkDen`.
{
  denHoag,
  prelude,
  schema,
  aspects,
  compile,
  ingest,
  annotate,
  hasAspect,
  collectGather,
  legacy,
}:
let
  # ── Phase 5 Task 2 — the PARALLEL TYPED NAVIGATION VIEW (native A-IDENT, additive). ────────────────
  # gen-aspects @14652a0 (A-IDENT) makes a TYPED aspect node carry its own container-relative identity at
  # merge: `.key` = the full `den/aspects`-relative path (`pathKey prefix`), `meta.aspect-chain` = its
  # ancestors — born in the type, never reconstructed. The compat two-eval needs that native identity on
  # the NAVIGATION SURFACE (the `den` legacy binding a module's `with den.aspects` reads, and the evalV1
  # read-back Task 3's readers + the native-identity suite consume). But it must NOT reach `compile`:
  # compile reads the RAW aspect tree and does its OWN wrap-ground (compile.nix §339; a class body
  # `nixos = { … }` must stay a raw attrset — a typed tree wraps it as a `deferredModule` `{ imports; }`
  # or leaks the typed node's structural options into the class-modules bucket, reshaping what the
  # terminal delivers). So: ONE raw tree for compile (unchanged, `__provider`-annotated), a PARALLEL
  # typed VIEW for navigation — the same single gen identity system (`aspectsType`), applied where it
  # belongs. Task 3 later repoints the readers onto the native `.key` and retires the `__provider` graft.
  #
  # cnf.classes = { }: `.key`/`meta.aspect-chain` are PATH-derived (identity.nix), class-INDEPENDENT, so
  # an empty class set gives correct native identity WITHOUT making a class key a `deferredModule` option
  # (which would wrap the navigated class body — corrupting a corpus `with den.aspects` reader that reads
  # class content off a navigated node). A class key (`nixos`/`homeManager`/…) then rides the
  # `aspectsRoot`/`aspectSubmodule` freeform as an ordinary nested attrset — navigable, uncorrupted.
  # `aspectModules`/`metaModules` are empty: the view supplies ONLY intrinsic identity (`.key`/`meta`/
  # `name`/`includes`), not den-hoag's concern-option surface (that lives on the compiled bridge output).
  aspectsViewCnf = {
    classes = { };
    moduleArgs = {
      settings = true;
      aspects = true;
      lib = true;
      config = true;
      options = true;
      pkgs = true;
    };
    aspectModules = [ ];
    metaModules = [ ];
    collections = { };
  };
  aspectsViewType = aspects.aspectsType aspectsViewCnf;

  # `typedAspectsView rawAspects` — eval the RAW v1 aspects through `aspectsViewType` (the probe's
  # evDirect shape) so each navigated node carries native `.key`/`meta.aspect-chain`, then GRAFT the raw
  # tree's `__provider` stamps back on (additive: a navigated node carries BOTH the native key AND the
  # legacy provider path this task — Task 4 deletes the graft). The eval also rebinds `_module.args.aspects
  # = config` internally (aspectsType), so a `with aspects; …` include inside the view resolves against
  # the typed siblings. Falls back to `{ }` for an aspect-less fleet (mkOption default).
  graftProviders =
    typed: raw:
    if !(builtins.isAttrs raw) || !(builtins.isAttrs typed) then
      typed
    else
      typed
      // prelude.optionalAttrs (raw ? __provider) { inherit (raw) __provider; }
      // builtins.listToAttrs (
        map (k: {
          name = k;
          value = graftProviders (typed.${k} or { }) raw.${k};
        }) (builtins.filter (k: builtins.substring 0 2 k != "__") (builtins.attrNames raw))
      );
  typedAspectsView =
    rawAspects:
    let
      ev = schema.evalModuleTree {
        modules = [
          {
            options.aspects = schema.mkOption {
              type = aspectsViewType;
              default = { };
            };
            config.aspects = rawAspects;
          }
        ];
      };
    in
    graftProviders ev.config.aspects rawAspects;

  # A `raw` option holds any v1 value unmerged (single-def passthrough) — the v1 grammar (parametric
  # aspects, policy records, two-level host maps) is never type-walked or freeform-mangled.
  rawOpt =
    description:
    schema.mkOption {
      type = schema.types.raw;
      default = { };
      inherit description;
    };
  rawListOpt =
    description:
    schema.mkOption {
      type = schema.types.raw;
      default = [ ];
      inherit description;
    };

  # The v1 option surface as ONE freeform `den` submodule: each v1 concern is a `raw` sub-option (the
  # grammar rides untouched), and the `freeformType` absorbs any v1 config outside them (custom-kind
  # instances, `den.default`, …) so an arbitrary den-scoped corpus module evaluates without a schema
  # edit. Declared as a single submodule (not `options.den.<x>` groups) so it never collides with a
  # `den` leaf — the leaf/group collision the two-eval separation exists to avoid.
  #
  # TRADE-OFF of the freeform: a TYPO in an unknown `den.*` key silently succeeds HERE (it is absorbed,
  # not rejected). That is deliberate — surface-totality (every v1 key is a KNOWN key, else a named
  # error) is enforced downstream at `compile`, over the read-back config, not at this permissive eval.
  # KEEP IN SYNC with compile.nix `knownSurfaceKeys` (the totality gate reads that list).
  v1OptionsModule = {
    options.den = schema.mkOption {
      default = { };
      description = "The den v1 declaration surface (read by the compat two-eval, desugared by compile).";
      type = schema.types.submodule {
        freeformType = schema.types.lazyAttrsOf schema.types.raw;
        options = {
          hosts = rawOpt "v1 `den.hosts.<system>.<name>` (two-level host definitions).";
          homes = rawOpt "v1 `den.homes.<system>.<name>` (standalone home-manager configurations).";
          schema = rawOpt "v1 `den.schema.<kind>` (containment kinds + kind-attached includes).";
          aspects = rawOpt "v1 `den.aspects.<name>` (aspect definitions).";
          policies = rawOpt "v1 `den.policies.<name>` (policy functions / for·when records).";
          classes = rawOpt "v1 `den.classes.<name>` (output class registrations).";
          include = rawListOpt "v1 static entity-scoped aspect inclusions.";
          quirks = rawOpt "v1 `den.quirks.<name>` (quirk channels).";
          contentClass = rawOpt "v1 kind -> content-class overrides.";
        };
      };
    };
  };

  flakeModuleCore = [ v1OptionsModule ];

  # R1 (spec §10) — the LEGACY BINDING ENVIRONMENT. den v1 modules/aspect bodies reference the `den`
  # flake-scope module arg (den v1 `nix/nixModule/default.nix:3`: `_module.args.den = config.den`). The
  # shim reproduces the ALWAYS-bound `den` binding in its OWN v1-surface eval, at the boundary only —
  # `config.den` is the v1 declaration surface, so a v1 module reads its own fleet's `den.aspects`/
  # `den.policies`/… exactly as under den v1. The opt-in flake-scope battery args (`lib`/`inputs`/`self`/
  # `withSystem`/`flake-parts-lib`, den v1 batteries/flake-scope.nix) ride the SAME `_module.args` seam
  # when a consumer supplies them; only `den` is bound unconditionally (the corpus's dominant reference).
  # den-hoag core probes and `concern-aspects` moduleArgs carry ZERO legacy names — this binding lives in
  # the shim's v1 eval, never crosses into den-hoag.
  # board #58 (Fork A): the `__provider`-annotated view of a v1 `den` surface — `annotate` is the
  # post-fold walk (annotate.nix; v1 annotateDeep, pin types.nix:561-574). This is `compile`'s RAW input:
  # a class body rides as an unwalked attrset, `stampProvider` recovers v1's include identity from the
  # provider path. Idempotent on the bridge path — its tree arrives already annotated (`!(v ? __provider)`).
  # The fleet's declared classes/quirks feed the walk's exclusion guard, exactly as v1 reads its own
  # registries at annotation time (types.nix:540-542).
  annotatedViewRaw =
    den:
    den
    // {
      aspects = annotate {
        classNames = builtins.attrNames (den.classes or { });
        quirkNames = builtins.attrNames (den.quirks or { });
      } (den.aspects or { });
    };

  # Phase 5 Task 2 — the NAVIGATION view: the `__provider`-annotated raw aspects run ALSO through
  # `typedAspectsView`, so every navigated node carries native A-IDENT `.key`/`meta.aspect-chain` (born in
  # the type) alongside the grafted `__provider` (additive). This is the surface a v1 module's
  # `with den.aspects; …` include, a policy's emitted `den.aspects.<path>` ref, and the evalV1 read-back
  # (Task 3's readers + the native-identity suite) read. NEVER fed to `compile` (which takes the raw view).
  annotatedViewNav =
    den:
    let
      raw = annotatedViewRaw den;
    in
    raw // { aspects = typedAspectsView raw.aspects; };

  # R1 legacy binding — bind `_module.args.den` to the NAVIGATION view (Task 3). A `host.hasAspect
  # den.aspects.<path>` ref (the 13-read corpus census) now reads a node carrying native `.key`, so
  # `refKey` is a single `ref.key` lookup (has-aspect.nix) — no `__provider` reconstruction. The nav view
  # ALSO carries the grafted `__provider` (additive), so a `with den.aspects; …` include CAPTURED off this
  # binding and flowed to `compile` still grounds byte-identically: compile's `stampProvider` reads
  # `v.__provider` (the graft), unchanged this task (compile-grounding readers move in Task 4 with the
  # `__provider` deletion). The name-ref-in-includes canary (a captured typed node carries a materialized
  # `name` + native `meta.aspect-chain`, so `identity.key` = the full container path natively — NOT the
  # positional collapse Task 2 feared) is pinned by compat-include-identity F1-F5 + the native-identity PROBE.
  bindLegacyEnv =
    {
      config,
      ...
    }:
    {
      config._module.args.den = annotatedViewNav config.den;
    };

  # `evalV1Raw` — the COMPILE input: read back `config.den` with the RAW `__provider` aspects (unwalked
  # class bodies, byte-identical class-modules buckets). Only `flakeModuleCore` declares options here.
  evalV1Raw =
    userModules:
    annotatedViewRaw
      (schema.evalModuleTree { modules = flakeModuleCore ++ [ bindLegacyEnv ] ++ userModules; })
      .config.den;

  # `evalV1` — the PUBLIC read-back (Task 3's readers + the native-identity suite): the NAVIGATION view, so
  # a navigated `den.aspects.<path>` carries native `.key`/`meta.aspect-chain` (born in the type) alongside
  # the grafted `__provider`. This is a READ-ONLY VIEW over the same v1 eval — it is NOT fed to `compile`
  # (which uses `evalV1Raw`) and NOT the `with den.aspects` include-capture binding (`bindLegacyEnv`, raw),
  # so a captured include's compile identity is untouched. It exposes native identity on exactly the surface
  # this task's acceptance reads; Task 3 makes the readers consume it.
  evalV1 =
    userModules:
    annotatedViewNav
      (schema.evalModuleTree { modules = flakeModuleCore ++ [ bindLegacyEnv ] ++ userModules; })
      .config.den;

  # The compat nixos instantiate wrapper (§2.5 carry-in + ship-gate M2): v1's per-host `system` and
  # per-host `instantiate` never reach den-hoag's pipeline (den-hoag entities are field-less), so they are
  # consumed HERE, at the terminal — the one place the per-host binding (`bindings.host`) is available. The
  # wrapper prepends a `{ nixpkgs.hostPlatform.system = systemFor host; }` module to the host's
  # class-modules, then delegates to the EFFECTIVE terminal: the per-host `instantiateFor host` evaluator
  # (D7 M2, the per-entity grain) if the host declares one, else the passed `terminal`. `terminal` is a
  # SEAM: the pure fleet wiring defaults it to den-hoag's nixpkgs-free `collect` (the platform is
  # inspectable in its output modules); the parity harness / the bridge supplies `crossNixos` for a real
  # NixOS build. A system-less host (systemFor → null) injects nothing — byte-identical to the bare
  # terminal — and an instantiate-less host uses the class terminal unchanged (both grains are opt-in).
  mkNixosInstantiate =
    {
      systemFor,
      instantiateFor,
      hmModuleFor,
      crossVia,
      terminal,
    }:
    args@{
      name,
      hostModules,
      bindings,
      classCfg,
    }:
    let
      hostEntry = bindings.host or null;
      sys = if hostEntry == null then null else systemFor hostEntry;
      sysModule = if sys == null then [ ] else [ { nixpkgs.hostPlatform.system = sys; } ];
      # R6 (the home-manager host-module import, terminal-side). Import the host's home-manager NixOS
      # module so a HOST-scope aspect emitting `home-manager.*` content typechecks (corpus agenixHostAspect
      # `home-manager.sharedModules`, batteries/agenix.nix:87 — the u9 re-probe frontier). v1's hm battery
      # imports it via its hostModule `${host.class}.imports = [{ key = "den:home-manager-host-module";
      # imports = [ host.home-manager.module ]; }]` (pin home-env.nix:74-86); here we are ALREADY at the
      # nixos terminal, so it joins hostModules directly (no `${host.class}` wrapper — that selects the class
      # content in v1's fold, which the terminal already scoped). v1's EXACT `key` string dedups a re-import
      # to a no-op. TERMINAL-SIDE, not an aspect: the module is a nixpkgs closure, excluded from deepSeq'd
      # resolution state (ingest.nix:56-58 — the SAME invariant as `instantiate`), so it rides the
      # compile-side `hmModuleFor` id_hash map, forced only here. `hmModuleFor` returns null for a
      # gated/hm-less host (no module or explicit `enable=false`) → no import, drv unshifted (see ingest.nix
      # `hmModuleByHostId` for the gate + the membership CEILING).
      hmFor = if hostEntry == null then null else hmModuleFor hostEntry;
      hmModule =
        if hmFor == null then
          [ ]
        else
          [
            {
              imports = [
                {
                  key = "den:home-manager-host-module";
                  imports = [ hmFor ];
                }
              ];
            }
          ];
      # THREE-GRAIN INSTANTIATION (D7, ship-gate M2). The per-host `host.instantiate` (the per-ENTITY grain)
      # WINS over the class-level `terminal` — which the bridge already resolved from the lower grains (the
      # class N1 declaration / the global `den.nixpkgs` fallback / the pure `collect`). Present ⇒ cross via
      # the host's OWN evaluator (its channel nixpkgs), so a fleet whose hosts each pin a channel builds each
      # host through its declared channel exactly as v1's `resolvedChannel.nixosSystem` did — with NO global
      # `den.nixpkgs` required. Absent ⇒ the class terminal (the lower grains). `crossVia` is nixpkgs-free
      # machinery (only the evaluator carries nixpkgs, as inert threaded data), so lib/** import-purity holds.
      perHostEval = if hostEntry == null then null else instantiateFor hostEntry;
      effectiveTerminal = if perHostEval == null then terminal else crossVia perHostEval;
    in
    effectiveTerminal (args // { hostModules = sysModule ++ hmModule ++ hostModules; });

  # The pure bridge: `compile`'s output → a den-hoag `config.den.*` module. Instances become
  # `config.den.<kind>.<name>` FIELD-LESS — den-hoag entities carry no content (it comes from aspects),
  # and its kinds are strict, so only the registry KEY crosses (the id_hash is name-derived, coherent
  # with the boundary entries). The v1 entity fields (class/system/…) stay compile-side metadata
  # (contentClass, systemFor, membership); everything else maps to its den-hoag concern option. The
  # nixos class carries the compat systemFor-injecting instantiate (§2.5 carry-in), so `den.hosts`'
  # per-host platform reaches the built system.
  # `mkFleetModuleWith compiled nixosTerminal` — the bridge, PARAMETERISED by the nixos class's terminal.
  # `nixosTerminal` is the raw terminal the systemFor-injecting `mkNixosInstantiate` wraps: the default
  # `collect` (nixpkgs-free) is the pure fleet path; the parity harness / a real ship supplies the
  # nixpkgs-bound `crossNixos` so `nixosConfigurations` are REAL NixOS systems (a `shimDrvPath` exists —
  # the P2 contentGate ship-gate arm + the migration product both require it). Shim-side seam, zero core
  # edits; `mkFleetModule` = this with `collect` (byte-identical to the pre-seam bridge, every fixture
  # untouched).
  mkFleetModuleWith =
    compiled: nixosTerminal:
    let
      # Instances cross FIELD-LESS (den-hoag entities carry no content), PLUS each kind's ctx-entity
      # field record (`entityFields`, ingest.nix — the bridge-registry passthrough): the host's
      # structural `class`/`system`/`hostName` trio (the R3/R6 route gates, the home-platform routes,
      # the hostname battery — v1 binds the FULL host config as the ctx entity, so those fields are
      # present at real dispatch there; the probe sentinel carries all three, `probeSentinelModule`)
      # UNIONED with the registry-passthrough stamp — the bridge-eval'd merged registry entry minus
      # the structural exclusion (registry.nix stampTreeOf). v1's ctx entity is the RESOLVED entity
      # config, so corpus aspect bodies read `host.settings.<path>` at the MODULE FIXPOINT (delivery
      # depth, xfs-disk-longhorn.nix:19), policies read `host.settings…isHub or false` at DISPATCH
      # (pipes.nix:166, ledger u6), and cluster/environment aspect fns read `cluster.networks`/
      # `cluster.getAssignment` off THEIR ctx entities (u8 path 2). One stamp DUAL-SERVES both read
      # depths: the entity entry IS the ctx entity at dispatch AND the coord binding at the terminal
      # (bindingsAt reads enriched-context). The loop is KIND-GENERIC — every discovered kind's
      # entities get their record; a kind without one stays field-less (`or { }`).
      entityFields = compiled.entities.entityFields or { };
      instanceConfig = builtins.mapAttrs (
        kind: insts: builtins.mapAttrs (name: _: (entityFields.${kind} or { }).${name} or { }) insts
      ) compiled.entities.instances;
      nixosInstantiate = mkNixosInstantiate {
        inherit (compiled.entities) systemFor instantiateFor hmModuleFor;
        inherit (denHoag.internal.terminal) crossVia;
        terminal = nixosTerminal;
      };
      # THE PROJECTED hasAspect ENTITY SURFACE (v1 PR #602 semantics). The schema entity-kind set — the
      # fleet's `den.schema` kind names (host/user/cluster/environment/…) — bounds the stamp: `mkEnrich`
      # stamps a shared projected `hasAspect` onto every entity-kind binding at each node (v1's
      # `overrideKinds`, schema.nix:77-79), reading the node's OWN resolved-aspects (the v2 dissolution).
      # `secretsConfig`/`fleet`/channel bindings are NOT schema kinds ⇒ never stamped. The hook is A17-lazy
      # (the binding spine forces without forcing resolved-aspects); it rides the shipped `den.enrichBindings`
      # (terminal, output-modules `bindingsAt`) AND `den.enrichContext` (resolution, resolved-aspects `ctx`)
      # raw seams (lib/default.nix), so no den-hoag core edit. F2: ONE hook serves both depths — the terminal
      # binding for a CONTENT-module formal (`nixos = { host, … }:` — networking.nix:341) and the resolution
      # ctx for an ASPECT-FN formal (`agenixHostAspect = { host, … }:` — agenix.nix:31), the SAME `refKey`
      # identity keyed against each node's OWN resolved-aspects.
      entityKinds = prelude.genAttrs (builtins.attrNames compiled.entities.schema) (_: true);
    in
    {
      config.den = {
        inherit (compiled.entities) schema membership contentClass;
        aspects = compiled.aspects;
        policies = compiled.policies;
        quirks = compiled.channels;
        enrichBindings = hasAspect.mkEnrich entityKinds;
        # The SAME hook at RESOLUTION depth — the aspect-fn ctx twin (F2: shared refKey identity, not a
        # forked variant). Enriches the enriched-context a bare-fn kind-include receives so an aspect-fn's
        # `host.hasAspect` (agenix.nix:31, resolution depth) resolves like a content-module's (networking.nix:341).
        enrichContext = hasAspect.mkEnrich entityKinds;
        # The COMPOSED cross-scope channel gather (#62b expose ascent + #69 collect/collectAll twins,
        # U9.2) — fills the core #62a channel-augmentation seam with den v1's gathers: the received
        # expose pool (`collectAllExposed` — `resolved-users` at a host, exposed up by its user cells)
        # FIRST, then the sibling/fleet collect gathers (`findMatchingSiblings`/`findMatchingAll` —
        # `k3s-nodes`/`host-addrs`/… peers), per channel, at the terminal binding. `entityKinds` feeds
        # v1's predicate entity-kind gating (F2).
        channelGather = collectGather.mkGather entityKinds;
        # Static entity-scoped includes (den-hoag `den.include`, §370 directAspects) — the R5
        # self-named-aspect seeds (spec §10) `addSelfIncludes` appended, node-local at each self-named
        # entity. Empty when the legacy self-provide module is severed (byte-identical no-op, Law C5).
        include = compiled.include or [ ];
        classes = compiled.classes // {
          nixos = (compiled.classes.nixos or { }) // {
            instantiate = nixosInstantiate;
          };
        };
      }
      // instanceConfig;
    };
  mkFleetModule = compiled: mkFleetModuleWith compiled denHoag.internal.terminal.collect;

  # `flakeModule` — the flake-parts IMPORT surface (what a consumer's `imports = [ inputs.den.flakeModule ]`
  # merges into its STRICT flake-parts eval). It is ONLY `flakeModuleCore` (the v1-options module): the sole
  # thing a consumer's eval needs is the `den` option DECLARATION, so its `config.den` grammar rides
  # untouched to `mkDen`, which applies the legacy desugars + compiles OUTSIDE that eval. The `legacy.*`
  # entries are NOT flake-parts modules — they are plain data holders (`{ _denCompat.legacy; desugar; … }`)
  # consumed INTERNALLY as attributes (`desugarLegacy` reads `legacy.provides.desugar`; the severance tests
  # read `legacy.provides._denCompat.legacy`), never through a module eval. Importing them into a consumer's
  # strict flake-parts eval leaks their top-level keys (`_denCompat`, `desugar`, the forward primitives) as
  # UNDECLARED options — the G1′ leak the ship-gate strict-eval witness pins. `evalV1` already used
  # `flakeModuleCore` alone and the desugars ride the internal attribute seam, so dropping the legacy modules
  # from this list is a no-op for every mkDen/harness path and removes the entire leak class at once.
  flakeModule = flakeModuleCore;

  # The LEGACY desugars: the ONLY references to `legacy.*` outside `legacy/` (the flakeModule assembly,
  # §2.1 severance) — applied to the v1 surface BEFORE compile so den-hoag sees only grounded vocabulary.
  # Each is an or-identity: severed (no `desugar` ⇒ the identity), a residual legacy key survives to
  # compile and trips that surface's sentinel (Law C5). Both pure (Law C2): v1 → v1 transforms.
  #   • provides → v1-aspects → v1-aspects (§B4a `neededBy`/`includes`/content).
  #   • forwards → v1 → v1: strips `den.classes.<c>.forwardTo` (the compile-visible forward surface).
  legacyProvidesDesugar = legacy.provides.desugar or (aspects: aspects);
  legacyForwardsDesugar = legacy.forwards.desugar or (v1: v1);
  # R4 + R2/R3/R6 (spec §10) — the v1-AMBIENT battery membership (legacy/defaults.nix): den v1's default
  # batteries (os-class, os-user) are part of den's module set, so `den.default.includes` gains os-to-host
  # / user-to-host and `den.classes` gains os/user on EVERY fleet. The shim reproduces that ambient default
  # by folding the batteries' v1→v1 desugar into `desugarLegacy` — so under the FULL `flakeModule` (both
  # legacy present) every compat fleet carries the built-in classes + routes, matching v1. SEVERABLE:
  # severing `legacy.defaults` (a subset wiring, `mkWiring`) drops the fold (`or (v1: v1)`), so the ambient
  # defaults vanish — its own C5 witness. Because the batteries ARE this ambient v1 semantics, the C5
  # core-vs-full byte-identity assertions on non-legacy fixtures are SCOPED to the non-ambient surface
  # (compat-legacy-severed header): severed ⇒ ambient absent, so a full-vs-core diff is EXPECTED to carry
  # the ambient delta, not a severability break.
  legacyDefaultsDesugar = legacy.defaults.desugar or (v1: v1);
  # Compose the pre-compile desugars: batteries FIRST (they add `den.classes`/`den.policies` the compile
  # core then processes as ordinary vocabulary — os/user become REGISTERED classes via `discoverClasses`),
  # then forwards (reshapes `classes`), then provides (reshapes the resulting `aspects`).
  desugarLegacy =
    v1:
    let
      v1b = legacyDefaultsDesugar v1;
      v1f = legacyForwardsDesugar v1b;
    in
    v1f
    // {
      aspects = legacyProvidesDesugar (v1f.aspects or { });
    };

  # R5 (spec §10) self-named-aspect auto-include (legacy/self-provide.nix): a POST-compile augmentation
  # (it reads the compiled registries + aspect records), gated on the self-provide module being in THIS
  # wiring's legacy set — severed ⇒ `_: [ ]`, no self-includes (byte-identical no-op, Law C5). Emits
  # den-hoag `den.include` records appended to `compiled.include`. `ingest.aspectEntry` supplies the
  # id_hash convention so the seeded aspect record matches a `neededBy`/`include` inclusion's (A2).
  selfIncludeFn =
    if legacy ? self-provide then
      (
        compiled:
        legacy.self-provide.selfIncludesOf {
          inherit compiled;
          inherit (ingest) aspectEntry;
        }
      )
    else
      (_compiled: [ ]);
  addSelfIncludes =
    compiled: compiled // { include = (compiled.include or [ ]) ++ selfIncludeFn compiled; };

  # `compileFull` — the "through flakeModule" compile: apply this wiring's legacy desugars, compile, then
  # append the R5 self-named includes. This is what a v1 surface sees when driven by the assembled
  # `flakeModule` (both legacy present) or by a SEVERED wiring (`mkWiring` with a subset). For a
  # non-legacy v1 set the pre-compile desugars are or-identity AND `selfIncludeFn` fires only where an
  # entity name overlaps an aspect name — so `compileFull ≡ compile` on any fixture with no such overlap,
  # exactly the severability the C5 suite pins. A legacy fixture through a wiring WITHOUT its module keeps
  # the residual key, which trips compile's sentinel (Law C5).
  compileFull = v1: addSelfIncludes (compile (desugarLegacy v1));
  # `den.interpret` — the gen-edge source-interpreter seam (item 7): the legacy forwards module's
  # `synthesize`/`rewalk` composers, threaded into den-hoag's single `materialize` via the shipped raw
  # option (lib/default.nix `interpretDecl`, output-modules.nix `interpret ? { }`) WITHOUT editing
  # output-modules.nix. Severed (no forwards module ⇒ `or { }`) ⇒ the native default: no synthesize
  # source is ever folded, so `{ }` is complete. den-hoag constructs no synthesize record and defines
  # no interpreter — both are the legacy module's, supplied here as data + a closure.
  interpretModule = {
    config.den.interpret = legacy.forwards.interpret or { };
  };
  # PROBE-SENTINEL ENRICHMENT (B2, the shim-side half of the configurable core sentinel). concern-policies
  # reads a policy's stratum by producing it against a value-less sentinel `{ id_hash; name }`. Several FROZEN
  # v1 corpus policies read a bare coord FIELD on that entry and would hard-fail: `host.system` (v1
  # home-platform routes — `lib.hasSuffix "-linux" host.system`), `host.class` (colmena `host-modules-capture`
  # `inherit (host) class`; nix-on-droid `drop-user-to-host-on-droid` `host.class == "droid"`), `host.hostName`
  # (the hostname battery `${host.class}.networking.hostName = host.hostName`, an unconditional read whose
  # fake value is discarded after the probe, like `host-modules-capture`). The FIELDS ARE
  # A v1-CORPUS FACT, so they live HERE (the compat layer), not in field-agnostic core: the shim supplies
  # TYPE-CORRECT NON-MATCHING string sentinels ("«probe»"), so each value-conditional body takes its FALSE
  # branch → EXPANSION (the conservative branch, correct at real nodes), and an unconditional body (`host-
  # modules-capture` → instantiate) emits its fixed stratum with the fake value DISCARDED after the probe.
  # CEILING: a corpus policy reading an un-enriched field still hard-fails LOUDLY (self-announcing → add it).
  probeSentinelModule = {
    config.den.probeSentinelFields = {
      class = "«probe»";
      system = "«probe»";
      hostName = "«probe»";
    };
  };
  # THE CORPUS RESOLVE-FAMILY TAG SET (user-delivery R2 REQUIREMENT 2) — the SAME corpus-facts-as-config
  # precedent as `probeSentinelModule`. The names + census live in `resolve-family-names.nix` (the SINGLE
  # source), imported ALSO by default.nix → compile.nix so the kind-include compilation can stamp
  # `__resolveFamily` on a SYNTHETIC-keyed include policy whose SOURCE REF's v1 name is in this set (the
  # `name ∈ resolveFamilyNames` match here only catches a resolve policy authored DIRECTLY under the KEY —
  # a kind-include's key is synthetic). THE OMISSION CATCH: a resolve-emitting policy omitted from the set
  # that fires a `member` at a root aborts LOUD (the R2 `resolveFamilyUntagged` guard).
  resolveFamilyModule = {
    config.den.resolveFamilyNames = import ./resolve-family-names.nix;
  };
  # The #72 exclude-family twin (`den.excludeFamilyNames`, single source exclude-family-names.nix): a
  # value-conditional corpus excluder (drop-user-to-host-on-droid) probes empty, so the declared tag is
  # its only path to the staged pre-pass's exclude feed; omission aborts LOUD (excludeFamilyUntagged).
  excludeFamilyModule = {
    config.den.excludeFamilyNames = import ./exclude-family-names.nix;
  };
  # `mkDenWith userModules { nixosTerminal ? collect; hoagModules ? [] }` — build the shim fleet with the
  # nixos terminal SEAM (the parity harness / a real ship supplies `crossNixos` for real NixOS systems) and
  # optional extra native den-hoag modules. `mkDen` = this at the default (collect, no extra modules) — the
  # pure nixpkgs-free path, byte-identical to before.
  mkDenWith =
    userModules:
    {
      nixosTerminal ? denHoag.internal.terminal.collect,
      hoagModules ? [ ],
    }:
    denHoag.mkDen (
      [
        (mkFleetModuleWith (compileFull (evalV1Raw userModules)) nixosTerminal)
        interpretModule
        probeSentinelModule
        resolveFamilyModule
        excludeFamilyModule
      ]
      ++ hoagModules
    );
  mkDen = userModules: mkDenWith userModules { };
in
{
  inherit
    mkNixosInstantiate
    flakeModuleCore
    flakeModule
    v1OptionsModule
    evalV1
    mkFleetModule
    mkFleetModuleWith
    mkDen
    mkDenWith
    desugarLegacy
    compileFull
    ;
}
