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
  compile,
  ingest,
  legacy,
}:
let
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
  bindLegacyEnv =
    {
      config,
      ...
    }:
    {
      config._module.args.den = config.den;
    };

  # Eval the v1 modules in the v1-shaped tree and read back `config.den` (the v1 declaration surface,
  # verbatim) for `compile` to desugar. `bindLegacyEnv` (R1) binds `den` so a v1 module body may reference
  # it. Only `flakeModuleCore` (not the legacy tag modules) declares options here.
  evalV1 =
    userModules:
    (schema.evalModuleTree { modules = flakeModuleCore ++ [ bindLegacyEnv ] ++ userModules; })
    .config.den;

  # The compat nixos instantiate wrapper (§2.5 carry-in): v1's per-host `system` never reaches
  # den-hoag's pipeline (den-hoag entities are field-less), so it is injected HERE, at the terminal —
  # the one place the per-host binding (`bindings.host`) is available. The wrapper prepends a
  # `{ nixpkgs.hostPlatform.system = systemFor host; }` module to the host's class-modules, then
  # delegates to the underlying `terminal`. `terminal` is a SEAM: the pure fleet wiring defaults it to
  # den-hoag's nixpkgs-free `collect` (the platform is inspectable in its output modules); the parity
  # harness supplies `crossNixos` for a real NixOS build. A system-less host (systemFor → null) injects
  # nothing — byte-identical to the bare terminal.
  mkNixosInstantiate =
    {
      systemFor,
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
    in
    terminal (args // { hostModules = sysModule ++ hostModules; });

  # The pure bridge: `compile`'s output → a den-hoag `config.den.*` module. Instances become
  # `config.den.<kind>.<name>` FIELD-LESS — den-hoag entities carry no content (it comes from aspects),
  # and its kinds are strict, so only the registry KEY crosses (the id_hash is name-derived, coherent
  # with the boundary entries). The v1 entity fields (class/system/…) stay compile-side metadata
  # (contentClass, systemFor, membership); everything else maps to its den-hoag concern option. The
  # nixos class carries the compat systemFor-injecting instantiate (§2.5 carry-in), so `den.hosts`'
  # per-host platform reaches the built system.
  mkFleetModule =
    compiled:
    let
      # Instances cross FIELD-LESS (den-hoag entities carry no content), EXCEPT the host's `class` field:
      # v1's `host.class` is structural entity data the built-in os/user routes gate on (R3/R6), so the host
      # kind declares it (ingest.nix `buildSchema`) and it is stamped here from the compile-side
      # `hostClassName` map. Every other kind's instances stay `{ }`.
      hostClassName = compiled.entities.hostClassName or { };
      instanceConfig = builtins.mapAttrs (
        kind: insts:
        if kind == "host" then
          builtins.mapAttrs (name: _: { class = hostClassName.${name} or null; }) insts
        else
          builtins.mapAttrs (_: _: { }) insts
      ) compiled.entities.instances;
      nixosInstantiate = mkNixosInstantiate {
        inherit (compiled.entities) systemFor;
        terminal = denHoag.internal.terminal.collect;
      };
    in
    {
      config.den = {
        inherit (compiled.entities) schema membership contentClass;
        aspects = compiled.aspects;
        policies = compiled.policies;
        quirks = compiled.channels;
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

  # The full driver: v1 modules → the den-hoag assembly. `flakeModule` (core + legacy) supplies the v1
  # option declarations for `evalV1`; `compile` desugars; `mkFleetModule` bridges; `denHoag.mkDen` builds.
  flakeModule = flakeModuleCore ++ [
    legacy.provides
    legacy.forwards
  ];

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
  mkDen =
    userModules:
    denHoag.mkDen [
      (mkFleetModule (compileFull (evalV1 userModules)))
      interpretModule
    ];
in
{
  inherit
    mkNixosInstantiate
    flakeModuleCore
    flakeModule
    v1OptionsModule
    evalV1
    mkFleetModule
    mkDen
    desugarLegacy
    compileFull
    ;
}
