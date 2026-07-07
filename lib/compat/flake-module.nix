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

  # Eval the v1 modules in the v1-shaped tree and read back `config.den` (the v1 declaration surface,
  # verbatim) for `compile` to desugar. Only `flakeModuleCore` (not the legacy tag modules) declares
  # options here; the legacy surfaces join in their own tasks.
  evalV1 =
    userModules: (schema.evalModuleTree { modules = flakeModuleCore ++ userModules; }).config.den;

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
      instanceConfig = builtins.mapAttrs (
        _kind: insts: builtins.mapAttrs (_: _: { }) insts
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
  # Forwards desugars the FULL v1 (it reshapes `classes`); provides desugars the resulting `aspects`.
  # Compose forwards-first so provides sees the post-forward aspect set.
  desugarLegacy =
    v1:
    let
      v1f = legacyForwardsDesugar v1;
    in
    v1f
    // {
      aspects = legacyProvidesDesugar (v1f.aspects or { });
    };

  # `compileFull` — the "through flakeModule" compile: apply this wiring's legacy desugars, then compile.
  # This is what a v1 surface sees when driven by the assembled `flakeModule` (both legacy present) or by
  # a SEVERED wiring (`mkWiring` with a subset). For a non-legacy v1 set the desugars are or-identity, so
  # `compileFull ≡ compile`; that identity is exactly the severability the C5 suite pins (a non-legacy
  # fixture compiles byte-identically with any legacy subset). A legacy fixture through a wiring WITHOUT
  # its module keeps the residual key, which trips compile's sentinel (Law C5).
  compileFull = v1: compile (desugarLegacy v1);
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
      (mkFleetModule (compile (desugarLegacy (evalV1 userModules))))
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
