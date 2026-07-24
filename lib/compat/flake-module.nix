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
  # gen-merge's mkOption/types — supplied to `key-semantics.nix mkFacetSemantics` so the compile/nav view
  # mounts the SAME facet option modules the aspects concern declares (a `.settings` block is `lazyAttrsOf raw`
  # on the typed nav surface, not freeform-absorbed as a nested aspect).
  merge,
  compile,
  ingest,
  hasAspect,
  gather,
  legacy,
  # The compile-time seam-gate record (`den.features` class (b)). Off ⇒ OMIT the compat seam override so the
  # kernel's own identity default stands (a compat-wiring change, not a kernel edit). All-on for any direct
  # importer.
  features ? {
    hasAspect = true;
    gather = true;
    probeSentinel = true;
    familyStamps = true;
    fleetContext = true;
  },
}:
let
  # The shared class + channel keySemantics builder. The NAV VIEW declares the fleet's
  # quirk vocabulary — the SAME `key-semantics.nix` helper den-hoag core uses — so a `den.quirks` channel key
  # like `firewall` types as a `raw` channel option instead of falling to freeform / being wrapped as a
  # nested aspect on the navigation surface a `with den.aspects` reader / a `hasAspect` ref consumes.
  keySemanticsLib = import ../key-semantics.nix { inherit prelude; };

  # ── THE TYPED aspect tree — native A-IDENT (the SINGLE typed tree). ────────────────────────
  # gen-aspects (A-IDENT) makes a TYPED aspect node carry its own container-relative identity at merge:
  # `.key` = the full `den/aspects`-relative path (`pathKey prefix`), `meta.aspect-chain` = its ancestors —
  # born in the type, never reconstructed. den-hoag types its aspect tree ONCE (`typedCompileTree`, below):
  # class keys become deferredModule content buckets, channel keys `raw` passthroughs, and every node carries
  # native `.key`. BOTH the navigation surface (`bindLegacyEnv`'s `_module.args.den`, the `evalV1` read-back)
  # AND `compile` read this ONE tree — no raw/typed dual (the dual double-typed a nav-captured include: nav
  # classes-freeform → the class body a NESTED aspect, then compile re-typed it as a deferredModule of that
  # nested aspect → the F1 structural leak). compile consumes the typed node (project class buckets, strip
  # structural facets, carry the include's native identity). `aspectsViewCnf` is the shared base cnf (the
  # module-arg surface + empty meta); `mkCompileAspectsType` adds the fleet's keySemantics.
  aspectsViewCnf = {
    moduleArgs = {
      settings = true;
      aspects = true;
      lib = true;
      config = true;
      options = true;
      pkgs = true;
    };
    metaModules = [ ];
    collections = { };
  };

  # ── The SINGLE TYPED TREE `compile` consumes. ────────────────────────────────────────────
  # The COMPILE view types class bodies as deferredModule content buckets (`nixos = { imports = [ raw ]; }`
  # — opaque, terminal-clean) AND declares the fleet's `den.quirks` channels as `raw` passthroughs (so a
  # channel key is not freeform-absorbed into a nested aspect). ONE gen-native representation, no raw/typed
  # dual — compile reads each node's NATIVE `.key`/`name`/`meta.aspect-chain` (born in the type) and projects
  # its class deferredModule buckets THROUGH by value. `mkCompileAspectsType` is fleet-parameterised (the
  # declared class + channel names come from `den.classes`/`den.quirks`, threaded in `evalV1Raw`), built from
  # the SAME `key-semantics.nix` helper den-hoag core uses — one class + channel vocabulary source.
  # NOTE the v1 `homeManager` spelling is DELIBERATELY EXCLUDED (den-hoag's built-in is grounded `home-manager`;
  # a v1 `homeManager` body rides freeform and is grounded by translateAspect's `groundKeys` downstream).
  # `registeredClasses or [ ]` mirrors the `legacy.defaults.desugar or (v1: v1)` sibling-guard (below):
  # severing `legacy.defaults` (the ambient-batteries subset wiring) drops the whole `defaults` module, so
  # this base read must tolerate its absence — off ⇒ no ambient class names to seed (identity `[ ]`); on ⇒
  # `.registeredClasses` present, the `or` is IDENTITY (byte-neutral).
  compileClassNamesBase =
    builtins.attrNames denHoag.classes ++ (legacy.defaults.registeredClasses or [ ]);
  mkCompileAspectsType =
    {
      declaredClassNames,
      quirkChannelNames,
    }:
    aspects.aspectsType (
      aspectsViewCnf
      // {
        keySemantics =
          (keySemanticsLib.mkClassChannelSemantics {
            classNames = compileClassNamesBase ++ declaredClassNames;
            quirkChannels = quirkChannelNames;
          })
          # Register the config-free facet vocabulary (neededBy/settings/artifact) the aspects concern declares,
          # from the SAME source — so a `.settings` block on this typed tree is the kernel's `lazyAttrsOf raw`
          # facet, not a freeform nested-aspect submodule. Without it a `settings.<field> = mkOption {...}` leaf
          # reflects as an aspectSubmodule and collides with the authored value at merge. `id_hash` is left OUT
          # (its module injects `config.id_hash` onto every node — a shape change with no view consumer).
          // (keySemanticsLib.mkFacetSemantics { inherit merge; });
      }
    );
  # `typedCompileTree { declaredClassNames; quirkChannelNames; } rawAspects` — eval the RAW v1 aspect tree
  # through the compile view, yielding a typed tree whose class keys are deferredModules and whose nodes carry
  # native `.key` (the ONLY identity — compile reads `.key` directly). `evalModuleTree` also rebinds
  # `_module.args.aspects = config` internally, so a `with aspects; …` include inside the tree resolves
  # against its typed siblings. Falls back to `{ }` for an aspect-less fleet (mkOption default).
  # §2.2 TOTALITY under the typed tree (Bug 3). gen-aspects' freeform types ANY undeclared attrset key as a
  # nested aspect — so a TYPO (`nixxos = { networking… }`, neither facet/class/channel and NOT a legit nested
  # aspect) is silently absorbed + gains empty class/structural defaults that mis-classify it NESTED at
  # compile's `isNestedAspectKey` (which then strips it) → the §2.2 abort never fires. FIX: classify over the
  # RAW value (clean, pre-typing defaults) and splice the raw unregistered key BACK onto the typed node, so it
  # reaches class-modules `assertKeysRegistered` as a content key and aborts NAMED — LAZILY (only when the
  # aspect is resolved; a fixture that builds an aspect but never resolves it must not abort — compat-compile-
  # golden `roundTrip`). A legit nested aspect (raw value carries a recognized sub-key — structural/class/
  # channel — recursively) is untouched.
  structuralKeysSet = (import ./key-classification.nix { }).structuralKeysSet;
  # The v1 class-key SPELLING map (camelCase → grounded class name), the SINGLE source shared with
  # compile.nix's `groundKeys`/`groundClassName`. Used by the §2.2 raw-totality discriminator to GROUND a
  # candidate class-facet key (a v1 `homeManager`) to its registered den-hoag class before the malformed-fn
  # membership test — so a fn-valued class facet spelled the v1 way is recognised as a legit parametric
  # facet, not a malformed `{ name; fn }` policy record.
  v1ClassKeyMap = import ./v1-class-key-map.nix;
  # den-hoag facets absent from v1's structural set (KEEP IN SYNC with concern-aspects.nix `facets`).
  hoagFacetsSet = prelude.genAttrs [
    "neededBy"
    "tags"
    "projects"
    "key"
    "id_hash"
    "settings"
  ] (_: true);
  isStructuralRawKey = k: structuralKeysSet ? ${k} || hoagFacetsSet ? ${k};
  # `mkRawTotality { declaredClassNames; quirkChannelNames; }` — the RAW §2.2 discriminator: a candidate key
  # (non-structural/`__`/class/channel) is a LEGIT nested aspect iff its raw value is an attrset carrying a
  # recognized sub-key (structural/class/channel) OR a deeper candidate that recurses to one (the namespace-
  # path shape `core.systemd.boot`). Otherwise it is an UNREGISTERED key (v1's `unregisteredClassKeys`).
  mkRawTotality =
    {
      declaredClassNames,
      quirkChannelNames,
    }:
    let
      classSet = prelude.genAttrs (compileClassNamesBase ++ declaredClassNames) (_: true);
      quirkSet = prelude.genAttrs quirkChannelNames (_: true);
      # Ground a v1 class-key SPELLING to its registered den-hoag name (`homeManager` → `home-manager`)
      # before a class-membership test — the SAME v1ClassKeyMap compile applies. Identity for an
      # already-grounded / non-class key.
      groundK = k: v1ClassKeyMap.${k} or k;
      recognizedSubKey =
        sk:
        builtins.substring 0 2 sk != "__"
        && (isStructuralRawKey sk || quirkSet ? ${sk} || classSet ? ${sk});
      isCandidate =
        k:
        !(isStructuralRawKey k)
        && !(classSet ? ${k})
        && !(quirkSet ? ${k})
        && builtins.substring 0 2 k != "__";
      looksNested =
        v:
        builtins.isAttrs v
        && builtins.any (sk: recognizedSubKey sk || (isCandidate sk && looksNested v.${sk})) (
          builtins.attrNames v
        );
      isUnregistered = raw: k: isCandidate k && !(builtins.isAttrs raw.${k} && looksNested raw.${k});
      # a MALFORMED `{ name; fn }` include — an attrset carrying a FN-VALUED unregistered key (not a
      # structural facet / registered class / `__`-prefixed), bearing NO policy/route/wrapped marker: a
      # typo'd policy record or a mis-keyed content set. The typed tree would WRAP its `fn` into a valid
      # nested include (silent inert-fire); we abort LOUD here (over the RAW element, §2.2 self-announce).
      # CARVE-OUT: the class membership test grounds the key first (`groundK`, the v1ClassKeyMap spelling),
      # so a fn-valued key whose GROUNDED name IS a registered class (a v1 `homeManager = { host, … }: …`
      # parametric FACET) is NOT malformed — it rides raw + is grounded/wrapped by compile's `wrapGatedFn`
      # exactly like an attrset-valued `homeManager` facet already does (an attrset facet reaches compile via
      # the raw-splice; a fn facet must clear this fn-key gate to reach it too).
      # CARVE-OUT (2): a fn-valued key naming a REGISTERED quirk channel (`quirkSet ? ${k}`) is NOT
      # malformed — a v1 channel body may be a `{ ctx… }: <content>` producer, materialized unconditionally
      # by v1 and gathered fn-and-all by the downstream channel-gather seam. The lookup mirrors the sibling
      # `recognizedSubKey`/`isCandidate` predicates (bare `k`, not `groundK` — quirks are not class-grounded)
      # and compile's own `walkableChild` quirk exemption.
      malformedFnKeys =
        inc:
        builtins.filter (
          k:
          builtins.isFunction inc.${k}
          && !(isStructuralRawKey k)
          && !(classSet ? ${groundK k})
          && !(quirkSet ? ${k})
          && builtins.substring 0 2 k != "__"
        ) (builtins.attrNames inc);
      isMalformedFnInclude =
        inc:
        builtins.isAttrs inc
        && !(inc.__isPolicy or false)
        && !((inc.__denCanTake or null) != null)
        && !((inc.__fn or null) != null)
        && !(inc.__isWrappedFn or false)
        && !(inc.__guard or false)
        && malformedFnKeys inc != [ ];
      malformedFnIncludeAbort =
        inc:
        throw "den-hoag compat (§2.2): aspect-include `${inc.name or "<unnamed>"}` declares key `${builtins.head (malformedFnKeys inc)}` with a function value — neither a facet, a registered class, nor a quirk channel. A `{ name; fn; }`-shaped include is a MALFORMED policy record (a typo'd `{ __isPolicy; name; fn }`) or a mis-keyed content set; add the `__isPolicy = true;` marker, or move the fn into the `includes` LIST as a bare parametric include `[ (ctx: <content>) ]`.";
    in
    {
      inherit
        isUnregistered
        isCandidate
        isMalformedFnInclude
        malformedFnIncludeAbort
        ;
      # a legit nested-aspect CHILD to recurse into (raw attrset whose value looks nested).
      isNestedChild = raw: k: isCandidate k && builtins.isAttrs raw.${k} && looksNested raw.${k};
    };
  # A POLICY RECORD (`{ __isPolicy | __denCanTake; fn; … }`) in an aspect's `includes` is NOT aspect content:
  # its `fn` returns a v1 EFFECT LIST, so `aspectOrFn` would wrap it as a guard functor whose merge chokes
  # (`expected a set but found a list`) when compile applies it. It must ride RAW in the typed tree; the
  # markers survive the type wrap, so the restore splices the raw record back over the typed include.
  isPolicyRec =
    v: builtins.isAttrs v && ((v.__isPolicy or false) || (v.__denCanTake or null) != null);
  # splice raw unregistered keys + raw policy-record includes back onto the parallel typed node (+ recurse
  # legit nested children / non-policy includes).
  restoreUnregistered =
    tot: typed: raw:
    if !(builtins.isAttrs typed) || !(builtins.isAttrs raw) then
      typed
    else
      let
        unregistered = builtins.filter (tot.isUnregistered raw) (builtins.attrNames raw);
      in
      builtins.removeAttrs typed unregistered
      // builtins.listToAttrs (
        map (k: {
          name = k;
          value = raw.${k};
        }) unregistered
      )
      //
        prelude.optionalAttrs
          (builtins.isList (typed.includes or null) && builtins.isList (raw.includes or null))
          {
            includes = prelude.imap0 (
              i: tinc:
              let
                rinc = if i < builtins.length raw.includes then builtins.elemAt raw.includes i else null;
              in
              if rinc == null then
                tinc
              else if tot.isMalformedFnInclude rinc then
                tot.malformedFnIncludeAbort rinc
              else if isPolicyRec rinc then
                # a policy record rides RAW (its `fn` returns an effect list, never aspect content).
                rinc
              else if builtins.isFunction rinc || (builtins.isAttrs rinc && (rinc.__fn or null) != null) then
                # a PARAMETRIC include (a bare fn, or a `{ __fn; name }` record — the unfree battery shape)
                # rides RAW: the aspect type wraps a bare fn into a functor whose applicator merges
                # UNCONDITIONALLY (throwing on a missing required coord) and BEFORE class-key grounding, so a
                # v1-spelled body (`homeManager.…`) never grounds, and it would strip the `{ __fn }` record's
                # own gate. Passing the raw value lets compile's `normalize` wrap it via `wrapGatedFn` — v1's
                # canTake gate (missing coord ⇒ `{ }` inert) with `groundKeys` on the plain fn result.
                rinc
              else if builtins.isAttrs rinc && builtins.isAttrs tinc then
                # a STATIC aspect include — recurse so a policy record / bare-fn nested in ITS `.includes`
                # (the battery shape `include.includes = [ { __isPolicy } ]`, or a named sub-aspect carrying a
                # parametric include) is spliced raw too.
                restoreUnregistered tot tinc rinc
              else
                tinc
            ) typed.includes;
          }
      // builtins.listToAttrs (
        map
          (k: {
            name = k;
            value = restoreUnregistered tot (typed.${k} or { }) raw.${k};
          })
          (
            builtins.filter (k: tot.isNestedChild raw k && builtins.isAttrs (typed.${k} or null)) (
              builtins.attrNames raw
            )
          )
      );
  # the aspect CONTAINER top entry — keys are aspect NAMES (not content keys), so classify per-ENTRY only.
  restoreUnregisteredTree =
    tot: typed: raw:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value =
          if builtins.isAttrs (raw.${name} or null) then
            restoreUnregistered tot (typed.${name} or { }) raw.${name}
          else
            typed.${name};
      }) (builtins.attrNames raw)
    );
  typedCompileTree =
    args@{
      declaredClassNames,
      quirkChannelNames,
    }:
    rawAspects:
    let
      typed =
        (schema.evalModuleTree {
          modules = [
            {
              options.aspects = schema.mkOption {
                type = mkCompileAspectsType { inherit declaredClassNames quirkChannelNames; };
                default = { };
              };
              config.aspects = rawAspects;
            }
          ];
        }).config.aspects;
    in
    restoreUnregisteredTree (mkRawTotality args) typed rawAspects;

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
  # The NAVIGATION view — the RAW v1 aspects run through the SAME `typedCompileTree` compile consumes, so a
  # navigated node carries native A-IDENT `.key`/`meta.aspect-chain` (born in the type). This is the surface a
  # v1 module's `with den.aspects; …` include, a policy's emitted `den.aspects.<path>` ref, and the `evalV1`
  # read-back (the native-identity suite) read. Using the ONE typed tree here (not a classes-freeform variant)
  # keeps a `with den.aspects` include IDENTICAL to its compile-tree sibling — no double-type.
  annotatedViewNav =
    den:
    den
    // {
      aspects = typedCompileTree {
        declaredClassNames = builtins.attrNames (den.classes or { });
        quirkChannelNames = builtins.attrNames (den.quirks or { });
      } (den.aspects or { });
    };

  # R1 legacy binding — bind `_module.args.den` to the NAVIGATION view. A `host.hasAspect den.aspects.<path>`
  # ref (the 13-read corpus census) reads a node carrying native `.key`, so `refKey` is a single `ref.key`
  # lookup (has-aspect.nix). A `with den.aspects; …` include CAPTURED off this binding and flowed to `compile`
  # grounds by that SAME native `.key` (the include is a typed node — no reconstruction). The name-ref-in-
  # includes canary (a captured typed node carries a materialized `name` + native `meta.aspect-chain`, so
  # `identity.key` = the full container path natively) is pinned by compat-include-identity F1-F5.
  bindLegacyEnv =
    {
      config,
      ...
    }:
    {
      config._module.args.den = annotatedViewNav config.den;
    };

  # `evalV1Raw` — the compat two-eval read-back: `config.den` with its aspects RAW (class bodies unwalked).
  # The v1→v1 LEGACY DESUGARS (`desugarLegacy`: provides/forwards/defaults) run on THIS raw tree (they read
  # raw `provides`/`schema.<kind>.includes`, which must NOT be freeform-absorbed by typing). The SINGLE TYPED
  # TREE is applied AFTER desugar, in `compileFull` (`typeAspects`), so compile consumes
  # deferredModule class buckets carrying native `.key`.
  evalV1Raw =
    userModules:
    (schema.evalModuleTree { modules = flakeModuleCore ++ [ bindLegacyEnv ] ++ userModules; })
    .config.den;
  # `typeAspects v1Den` — run the (post-desugar) RAW aspect tree through the compile view: compile
  # consumes deferredModule class buckets + native `.key`. Applied in `compileFull` AFTER the legacy desugars.
  typeAspects =
    v1Den:
    v1Den
    // {
      aspects = typedCompileTree {
        declaredClassNames = builtins.attrNames (v1Den.classes or { });
        quirkChannelNames = builtins.attrNames (v1Den.quirks or { });
      } (v1Den.aspects or { });
    };

  # `evalV1` — the PUBLIC read-back (the native-identity suite): the NAVIGATION view, so a navigated
  # `den.aspects.<path>` carries native `.key`/`meta.aspect-chain` (born in the type). This is a READ-ONLY
  # VIEW over the same v1 eval, exposing native identity on the surface a `hasAspect` ref / a `with den.aspects`
  # reader consumes.
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
      # The producer-scoped config-thunk map — forwarded opaquely to the effective terminal's `wrapAll`
      # (default `{ }` ⇒ byte-identical). See lib/output/terminal.nix `crossVia`.
      producerConfigs ? { },
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
      # The projected-hasAspect stamp seams — `den.enrichBindings` (terminal, output-modules `bindingsAt`)
      # AND `den.enrichContext` (RESOLUTION depth, the aspect-fn ctx twin; F2: ONE shared refKey identity,
      # not a forked variant) — so an aspect-fn's `host.hasAspect` (agenix.nix:31, resolution depth)
      # resolves like a content-module's (networking.nix:341). ONE `features.hasAspect` flag gates BOTH;
      # OMITTED when off so the kernel's `{bindings,...}:bindings` identity default stands (no kernel edit).
      // prelude.optionalAttrs features.hasAspect {
        enrichBindings = hasAspect.mkEnrich entityKinds;
        enrichContext = hasAspect.mkEnrich entityKinds;
      }
      # The COMPOSED cross-scope channel gather (#62b expose ascent + #69 collect/collectAll twins + the
      # push-dual broadcast arm), re-layered onto the gen-graph query engine — fills the core #62a
      # channel-augmentation seam with den v1's gathers: the received expose pool (`collectAllExposed` —
      # `resolved-users` at a host, exposed up by its user cells) FIRST, then the sibling/fleet collect
      # gathers (`findMatchingSiblings`/`findMatchingAll` — `k3s-nodes`/`host-addrs`/… peers), then the
      # broadcast-injected values (`collectAllBroadcast`), per channel, at the terminal binding.
      # `entityKinds` feeds v1's predicate entity-kind gating (F2). OMITTED when off ⇒ kernel `_:_:_:{}`.
      // prelude.optionalAttrs features.gather {
        channelGather = gather.mkGather entityKinds;
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
  # `compileFull` — apply the legacy desugars (v1→v1, over the RAW tree), THEN type the aspect tree (the
  # single typed tree), then compile + append R5 self-includes. Typing AFTER desugar keeps the raw `provides`/
  # kind-include grammar readable by the desugars while giving compile the typed class buckets + native `.key`.
  compileFull = v1: addSelfIncludes (compile (typeAspects (desugarLegacy v1)));
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
  # A DEEP field (`settings`) needs a submodule-tree sentinel, not a string. The bridge threads the
  # all-defaults settingsType submodule (materialized at its DEFAULTS, so `.core.users.home-manager.
  # useGlobalPkgs = false`) as the reserved `_probeSentinelFields.settings` (bridge.nix), and this module
  # merges it onto the string sentinels above — so nixpkgs-overlays' un-`or`'d `host.settings.<…>`
  # predicate read reaches a genuine non-matching `false` at the probe (→ FALSE branch → expansion, never
  # a fire) instead of the uncatchable `attribute 'settings' missing`. LAZY: `? settings` / `inherit` never
  # force the submodule, so a settings-policy-free fleet never materializes it (byte-neutral). On the
  # mkDen-DIRECT path (no bridge) `_probeSentinelFields` is absent → the field is omitted → a direct fixture
  # reading bare `host.settings` in a policy still self-announces LOUDLY (the documented CEILING, unchanged).
  probeSentinelModule = rawDen: {
    config.den.probeSentinelFields = {
      class = "«probe»";
      system = "«probe»";
      hostName = "«probe»";
    }
    // prelude.optionalAttrs (rawDen ? _probeSentinelFields && rawDen._probeSentinelFields ? settings) {
      inherit (rawDen._probeSentinelFields) settings;
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
    let
      # Shared across the compile input and the probe-sentinel module (the shim reads the bridge-threaded
      # reserved `_probeSentinelFields` off the freeform raw `den`) — one eval, not two.
      rawDen = evalV1Raw userModules;
    in
    denHoag.mkDen (
      [
        (mkFleetModuleWith (compileFull rawDen) nixosTerminal)
        interpretModule
      ]
      # `probeSentinel` off ⇒ OMIT probeSentinelModule ⇒ `den.probeSentinelFields` unset ⇒ the kernel `{ }`
      # identity default stands (a policy reading a bare coord field at the value-less probe then hard-fails
      # LOUDLY — the documented CEILING, not a silent mis-resolve).
      ++ (if features.probeSentinel then [ (probeSentinelModule rawDen) ] else [ ])
      # `familyStamps` off ⇒ OMIT both seam modules (ATOMIC with the mkCompile name-set collapse — default.nix
      # mkCompile) ⇒ `den.{resolveFamilyNames,excludeFamilyNames}` unset ⇒ the kernel `[ ]` defaults stand
      # (a resolve/exclude policy firing a member/suppress at a root then aborts NAMED — the untagged guards).
      ++ (
        if features.familyStamps then
          [
            resolveFamilyModule
            excludeFamilyModule
          ]
        else
          [ ]
      )
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
    annotatedViewNav
    mkFleetModule
    mkFleetModuleWith
    mkDen
    mkDenWith
    desugarLegacy
    compileFull
    ;
}
