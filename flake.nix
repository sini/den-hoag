{
  description = "den-hoag — the four-concern assembly (den v2 public API) over the gen substrate";

  inputs = {
    gen-prelude.url = "github:sini/gen-prelude";
    gen-algebra.url = "github:sini/gen-algebra";
    gen-types.url = "github:sini/gen-types";
    gen-merge.url = "github:sini/gen-merge";
    gen-schema.url = "github:sini/gen-schema";
    gen-aspects.url = "github:sini/gen-aspects";
    gen-graph.url = "github:sini/gen-graph";
    gen-scope.url = "github:sini/gen-scope";
    gen-resolve.url = "github:sini/gen-resolve";
    gen-select.url = "github:sini/gen-select";
    gen-bind.url = "github:sini/gen-bind";
    gen-dispatch.url = "github:sini/gen-dispatch";
    gen-class.url = "github:sini/gen-class";
    gen-edge.url = "github:sini/gen-edge";
    gen-product.url = "github:sini/gen-product";
    gen-settings.url = "github:sini/gen-settings";
    gen-demand.url = "github:sini/gen-demand";
    gen-pipe.url = "github:sini/gen-pipe";
    gen-flake.url = "github:sini/gen-flake";

    # FORMATTER-ONLY input. The lib/ substrate is nixpkgs-lib-free (ci/tests/zero-machinery +
    # boundary enforce it) and never imports this; nixpkgs enters the root ONLY to supply the
    # committed `formatter` output below, so `nix fmt` works at the repo root. The nixos-unstable
    # tarball matches ci/'s nixpkgs (one nixfmt-rfc-style version across root + CI).
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    inputs@{ ... }:
    let
      lib = import ./lib {
        prelude = inputs.gen-prelude.lib;
        algebra = inputs.gen-algebra.lib;
        types = inputs.gen-types.lib;
        merge = inputs.gen-merge.lib;
        schema = inputs.gen-schema.lib;
        aspects = inputs.gen-aspects.lib;
        graph = inputs.gen-graph.lib;
        scope = inputs.gen-scope.lib;
        resolve = inputs.gen-resolve.lib;
        select = inputs.gen-select.lib;
        bind = inputs.gen-bind.lib;
        dispatch = inputs.gen-dispatch.lib;
        # gen-class WITH the tier-2 fixed-input kernel injected (gen-merge): `applyCoreFixed` (the A10
        # class-share build path) requires it; every tier-1 verb works without it. The flake's own
        # `gen-class.lib` is merge-less (its README §tier-2), so den-hoag re-imports the source with
        # `merge` — the same wiring the gen hub's `mkGenLibs.class` does.
        class = import "${inputs.gen-class}/lib" {
          prelude = inputs.gen-prelude.lib;
          merge = inputs.gen-merge.lib;
        };
        edge = inputs.gen-edge.lib;
        product = inputs.gen-product.lib;
        settings = inputs.gen-settings.lib;
        demand = inputs.gen-demand.lib;
        pipe = inputs.gen-pipe.lib;
        flake = inputs.gen-flake.lib;
      };
      # den-compat (L4) — the den v1 compatibility shim + the two-sided parity harness, on top of the
      # assembled `lib`. `denHoag` = the four-concern API (this flake's `lib`); the shim reaches every
      # gen substrate lib through den-hoag vocabulary and needs only `schema` (id_hash at ingestion)
      # and `edge` (inert legacy records + the frozen trace schema) directly.
      compat = import ./lib/compat {
        denHoag = lib;
        prelude = inputs.gen-prelude.lib;
        schema = inputs.gen-schema.lib;
        # gen-aspects — the aspect TAG owner. The shim calls `aspects.wrapFn` to wrap a v1 bare-fn aspect
        # include (which bypasses the option-type merge under R10 raw-absorption) into den-hoag's
        # `__isWrappedFn` functor — the same wrap the type applies to native guard fns. Injected directly
        # (like `schema`/`edge`), not reached through `denHoag`.
        aspects = inputs.gen-aspects.lib;
        edge = inputs.gen-edge.lib;
        # gen-edge's core primitives (`edgeSortKey`/`renderName`/`traceEntryOf`) — the frozen trace
        # renderer the parity harness renders BOTH arms into. gen-edge's public lib deliberately keeps
        # these internal (it exposes `trace`, which uses them), so the harness imports the frozen core
        # by source path — the SAME dev-time pattern the parity flake uses for den v1's `edge.nix`.
        edgeCore = import "${inputs.gen-edge}/lib/core.nix" { prelude = inputs.gen-prelude.lib; };
      };

      # `mkCrossNixos nixpkgs` — build the `nixos` class's real-system terminal from a consumer-supplied
      # nixpkgs flake, the SAME way the parity harness + compat-terminal-seam test do (den-hoag's ONE
      # sanctioned crossing, lib/output/terminal.nix, with `lib.internal.{bind,flake}`). Threaded into the
      # output bridge so its fold can cross a fleet's nixos members when `den.nixpkgs` is set (ship-gate M1).
      mkCrossNixos =
        nixpkgs:
        (import ./lib/output/terminal.nix { inherit (lib.internal) bind flake; } {
          inherit nixpkgs;
        }).crossNixos;

      # ── The output bridge (ship-gate M1) — the flake-parts-side splice (D7/D8) ─────────────────────
      # Replaces the bare option-declaring export: declares `options.den` (nixpkgs-native raw absorption),
      # runs the compat assembly, and sets `config.flake.{nixosConfigurations,darwinConfigurations}`. See
      # lib/compat/bridge.nix for the two-eval type-crossing resolution + the D7 instantiation grain notes.
      bridge = import ./lib/compat/bridge.nix {
        inherit compat mkCrossNixos;
        schema = inputs.gen-schema.lib;
        # the migration lib surface, spliced onto the consumer's `den` arg at `den.lib` (R1). Lazy let: it
        # is defined below and carries no reference back to the bridge, so the forward use is cycle-free.
        denLib = migrationLib;
      };

      # ── Compat built-in provisioning (ship-gate) — presents v1's built-in policies + routing kinds at the
      # v1 attrpaths a consumer references (`den.policies.system-to-flake-parts`, `den.schema.flake-system`,
      # …), merged into the freeform `config.den` via the flakeModule import (mirroring v1's flakeModule
      # importing `modules/policies/*`). PROVIDE (host-to-users inert, user-to-host identity-linked) + STUB
      # (flake-output policies, class-F/G). See lib/compat/builtins.nix.
      builtinsModule = import ./lib/compat/builtins.nix {
        prelude = inputs.gen-prelude.lib;
        errors = import ./lib/compat/errors.nix { prelude = inputs.gen-prelude.lib; };
        # den-hoag's declaration vocabulary — the fleet-context enrichment policy emits `declare.enrich`
        # (there is no v1 vocabulary for enrich; v1's `resolve.to` binding is the stubbed fan-out).
        declare = lib.declare;
      };

      # ── Migration-product re-export layer (ship-gate G1 / T1) ─────────────────────────────────────
      # den's consumers (nix-config) import `inputs.den.flakeModule` and author policies with
      # `inputs.den.lib.policy.*` etc. — den v1's TOP-LEVEL attrpaths. den-hoag exposes the same
      # capabilities under `.compat`/`.lib`; this layer re-exports them at den's expected paths so the
      # shim is a drop-in `den` input. THIN by design: a capability that exists in compat is ALIASED; a
      # semantic verb den-hoag does not yet implement is a NAMED THROWING STUB (never a fake — precedent
      # gen-select's `entityKind`) carrying the missing-capability reason, so a re-probe reads named blockers, not
      # `attribute 'x' missing`. The trivial policy constructors (include/exclude/mkPolicy/pipe) are the
      # v1 `__policyEffect`/`__pipeStage` record constructors, reproduced in compat (`policy-verbs.nix`,
      # ship-gate T3b) and aliased here; the fleet-resolution / instantiation verbs remain stubs.
      stub = ref: task: throw "den-hoag compat: `${ref}` — ${task}";
      # den.lib.home-env (ship-gate lib-surface) — v1's OS-user home battery builder (nix/lib/home-env.nix),
      # reproduced compat-side (lib/compat/home-env.nix). Its droid-path references
      # (`den.batteries.forward`, `den.lib.resolveEntity`, `den.lib.policy.*`) resolve against the migration
      # surface + named stubs; ALL are lazy, reached only when a droid-class host opens the battery gate — a
      # class-A (nixos) host leaves them inert. The `den`-shaped context it closes over: `.lib` = the
      # migration surface (recursive, cycle-free via laziness), `.batteries.forward` = the forward-battery
      # stub, `.aspects` = `{ }` (the optional `os-user-class-fwd` include is absent, so `? …` is false).
      homeEnv = import ./lib/compat/home-env.nix {
        prelude = inputs.gen-prelude.lib;
        den = {
          lib = migrationLib;
          aspects = { };
          # The forward battery rides INERT (an empty aspect — v1's `forwardEach` returns
          # `{ includes = map forwardItem each; }`, batteries/forward.nix/nix/lib/forward.nix at the pin;
          # the inert twin carries no items). Its ONLY corpus consumer is the droid home arc (home-env
          # userForward → the nix-on-droid HOME output family, den-hoag-ABSENT — the u4 intoAttr
          # posture), so a translated forward would have NO reachable artifact either way; the absent
          # `nixOnDroidConfigurations` output is the self-announcement (ledger u22, the u2/u4 shape).
          # The REAL surface is the forward-battery NTA (arc-2 territory).
          batteries.forward = _spec: { includes = [ ]; };
        };
      };
      migrationLib = lib // {
        # den.lib.policy.* — the policy-authoring vocabulary nix-config writes policies with.
        policy = {
          # deliver — v1 `den.lib.policy.deliver` (policy-effects.nix:68): the delivery-surface descriptor
          # a corpus policy body calls. Alias of the compat deliver surface (compat/deliver.nix:49).
          deliver = compat.deliver;
          route = compat.route; # alias — the deliver-surface route descriptor
          provide = compat.provide; # alias — the deliver-surface provide descriptor
          include = compat.include; # alias — v1 `{ __policyEffect = "include"; value = aspect; }`
          exclude = compat.exclude; # alias — v1 `{ __policyEffect = "exclude"; value = aspect; }`
          # spawn — v1 `den.lib.policy.spawn { classes }` (policy-effects.nix): the deferred
          # home-projection spawn effect the host-aspects battery emits. Compile's `translateEffect`
          # already handles `kind == "spawn"` (reads `effect.value.classes`), so this is the matching
          # constructor: `{ __policyEffect = "spawn"; value = { classes = [...]; }; }`.
          spawn = value: {
            __policyEffect = "spawn";
            inherit value;
          };
          mkPolicy = compat.mkPolicy; # alias — v1 `{ __isPolicy = true; name; fn; }`
          pipe = compat.pipe; # alias — v1 pipe.{from,filter,…} constructor bag
          # resolve — v1's fleet-resolution functor bag, faithfully reproduced (policy-effects.nix:128-171)
          # and consumed by the compat `__targetKind` arm (member for leaf-dim targets, relate for existing
          # roots) that the staged root-resolution pre-pass then routes (user-delivery R2, design note
          # 2026-07-11 §3(i)). Un-stubbed: the corpus's env→host→user chain now runs whole.
          resolve = compat.resolve; # alias — v1 `resolve`/`resolve.to`/`.shared`/`.withIncludes` bag
          # instantiate — v1 `den.lib.policy.instantiate spec` (policy-effects.nix:243): request post-pipeline
          # instantiation of an entity's CLASS content into a flake output. Compile's `translateEffect` handles
          # `kind == "instantiate"` (→ `declare.spawn { instantiate = spec }` — a CHILDLESS-INERT resolution
          # declaration: fleetChildren is membership-driven, so a spawn with no `{ host; user }` binding adds no
          # scope node; the spec rides PARKED on the declaration for the future intoAttr output family, never
          # discarded). Takes BOTH v1 call shapes: the spec RECORD (colmena host-modules-capture / clusters
          # cluster-to-nixidy — `{ name; class; instantiate; intoAttr }`) AND the RAW ENTITY (fleet.nix:74
          # `instantiate hostCfg` — the class-A registration; SUBSUMED by den-hoag's native nixos class terminal,
          # so it lands INERT — no double registration). CLASS-A-MINIMAL: nixosConfigurations materialize
          # natively; the class-C/D intoAttr families (colmenaHive / nixidyEnvs) are den-hoag-absent → LATENT
          # (ledger rows). The intoAttr OUTPUT FAMILY is its own rung when the class-C/D arms come up.
          instantiate = spec: {
            __policyEffect = "instantiate";
            value = spec;
          };
        };
        # den.lib.aspects.* / resolveEntity / home / capture — v1 lib surfaces. resolve/resolveWithPaths/
        # resolveImports + resolveEntity are CONFIG-WIRED: v1 ran a fresh fx pipeline per
        # seed, but den-hoag reads the BUILT fleet's memoized fold — so they need `config.den` and cannot be
        # real on the config-less migrationLib. NAMED config-wired stubs here (throw on `inputs.den.lib`);
        # the bridge's `configWiredLib` OVERRIDES them with the applied adapter (lib/compat/resolve-verbs.nix)
        # on the `den` module arg. home/capture stay ESCALATED (separate rungs).
        aspects = {
          resolve = stub "lib.aspects.resolve" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
          resolveWithPaths = stub "lib.aspects.resolveWithPaths" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
          resolveImports = stub "lib.aspects.resolveImports" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
          # resolveWithState (v1 default.nix:114 → the raw `{ value; state; }` fx-trampoline result): NO
          # den-hoag native twin (fx retired). A NAMED LATENT stub, never config-wired.
          resolveWithState = stub "lib.aspects.resolveWithState" "the fx-trampoline resolve state — no den-hoag native twin (fx retired); LATENT";
          # fx.keyClassification — the STRUCTURAL-KEY SLICE: real, reproducing v1's `structuralKeysSet` (the ONE export
          # the corpus reads). The rest of the fx semantic surface stays escalated.
          fx.keyClassification = compat.keyClassification;
          # mkProjectedHasAspect — PURE (config-less): a lookup over an ALREADY-COMPUTED per-scope pathSet
          # (v1 has-aspect.nix @a2f4b60 :45-54). `check` reads only its `pathSetByScope` arg + the config-less
          # `refKey`, so it is REAL here (compat has-aspect.nix) and rides through into the bridge's
          # `configWiredLib.aspects` unchanged (that set starts from `denLib.aspects`).
          mkProjectedHasAspect = compat.mkProjectedHasAspect;
          # collectPathSet/hasAspectIn/mkEntityHasAspect — CONFIG-WIRED: v1 ran a fresh fx pipeline per
          # `{ tree, class }`, but den-hoag reads the BUILT fleet's memoized `reach` — so they need
          # `config.den` and cannot be real on the config-less migrationLib. NAMED config-wired stubs here
          # (throw on `inputs.den.lib`); the bridge's `configWiredLib.aspects` OVERRIDES them with the applied
          # adapter (lib/compat/has-aspect-verbs.nix) on the `den` module arg.
          collectPathSet = stub "lib.aspects.collectPathSet" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
          hasAspectIn = stub "lib.aspects.hasAspectIn" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
          mkEntityHasAspect = stub "lib.aspects.mkEntityHasAspect" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
        };
        resolveEntity = stub "lib.resolveEntity" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
        home = stub "lib.home" "the home-entity surface — not yet available";
        capture.captureFleet = stub "lib.capture.captureFleet" "the retired-fx fleet-topology diagnostic feed (den-diagram) — capability reachable via `built.den.structural`; intentionally absent, not a stub-in-waiting";
        # den.lib.{nh,policyInspect,__findFile,schemaUtil} — CONFIG-WIRED surfaces. v1 loads
        # these `{ lib, den }:` / `{ lib, config }:` reading the fleet config; on the config-LESS migrationLib
        # (= `inputs.den.lib`, v1's unapplied function where `.nh` is missing too) they cannot be real. Named
        # THROWING stubs here (flake.nix stub discipline) — the bridge's `configWiredLib` OVERRIDES them with the
        # applied versions on the `den` module arg, so a corpus read resolves the real fn; a stray
        # `inputs.den.lib.nh` reads a NAMED blocker, not `attribute 'nh' missing`.
        nh = stub "lib.nh" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
        policyInspect = stub "lib.policyInspect" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
        __findFile = stub "lib.__findFile" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
        schemaUtil = stub "lib.schemaUtil" "config-wired — read via the `den` module arg (the bridge), not `inputs.den.lib`";
        # den.lib.home-env — the OS-user home battery builder {makeHomeEnv, mkDetectHost, mkIntoClassUsers}
        # (v1 nix/lib/home-env.nix), reproduced faithfully compat-side; wired above.
        "home-env" = homeEnv;
        # den.lib.canTake — v1's arity predicate (nix/lib/can-take.nix): does a fn accept a given param
        # set? `{ __functor = atLeast; atLeast; exactly; upTo; }`, reproduced compat-side over gen-prelude
        # primitives (the substrate is nixpkgs-lib-free).
        canTake = compat.canTake;
        # den.lib.synthesizePolicies.resolveArgsSatisfied (v1 nix/lib/synthesize-policies.nix:7-16) — the policy-
        # dispatch predicate: does `ctx` supply every REQUIRED formal of `fn`? Maps onto the existing `canTake`
        # (arg-flipped: canTake.atLeast params func = func's requireds ⊆ params). Same predicate den-hoag's compile
        # uses inline for `__condition` (functionArgs gate).
        synthesizePolicies.resolveArgsSatisfied = fn: ctx: compat.canTake.atLeast ctx fn;
        # den.lib.perHost / perUser / perHome — v1's deprecated context guards
        # (modules/context/perHost-perUser.nix). v1 documents `perHost f` as an alias for
        # `{ host, ... }: f { inherit host; }` (the #609 binding-half rewrite dropped the old
        # self-suppression). den-hoag's compile path resolves a plain destructured `{ host, ... }:`
        # lambda the SAME way (functionArgs → __condition gate → bind-once-if-in-ctx / fan-out
        # class-locally / inert-if-misplaced; compile.nix), so the plain-lambda form reproduces v1's
        # semantics WITHOUT the `{ __args; __fn; }` parametric wrapper — pure alias. The substrate is
        # nixpkgs-lib-free (no `lib.warn`), so the deprecation notice rides `builtins.trace` — byte-
        # transparent (returns the value; stderr only) → parity holds. The `!isAttrs` guard mirrors v1
        # perCtx's `__fn` inner arm exactly: a function aspect is applied with the resolved keys; a
        # functor-attrset / bare attrset rides unchanged. perUser requires host+user (v1 perCtx
        # [ "host" "user" ] binds both). `nsTypes` / `parametric` are NOT forwarded here: they couple to
        # the aspect-namespace machinery (mkAspectsType) and the parametric-wrapper mechanism
        # (constantHandler / { __fn; __args; __scopeHandlers }) respectively — deferred to their rungs.
        perHost =
          aspect:
          builtins.trace
            "den.lib.perHost is deprecated — use a plain function ({ host, ... }: ...) instead; handler-based resolution binds context args automatically"
            (
              if builtins.isFunction aspect && !builtins.isAttrs aspect then
                { host, ... }: aspect { inherit host; }
              else
                aspect
            );
        perUser =
          aspect:
          builtins.trace
            "den.lib.perUser is deprecated — use a plain function ({ host, user, ... }: ...) instead; handler-based resolution binds context args automatically"
            (
              if builtins.isFunction aspect && !builtins.isAttrs aspect then
                { host, user, ... }: aspect { inherit host user; }
              else
                aspect
            );
        perHome =
          aspect:
          builtins.trace
            "den.lib.perHome is deprecated — use a plain function ({ home, ... }: ...) instead; handler-based resolution binds context args automatically"
            (
              if builtins.isFunction aspect && !builtins.isAttrs aspect then
                { home, ... }: aspect { inherit home; }
              else
                aspect
            );
        # den.lib.take — v1's deprecated context guards (nix/lib/take.nix). NOT a canTake alias:
        # canTake is a PREDICATE (params: fn: bool), take is a fn→wrapped-fn TRANSFORMER — same member
        # names, different shapes. Overriding nixpkgs `lib.take` (migrationLib = lib // …) is safe and
        # fixes a latent leak (den v1 exposes the guard bag at `den.lib.take`, not the list-take); no
        # internal consumer reads it. atLeast/upTo/unused/__functor are trace+IDENTITY (pure). take.exactly
        # returns fn unchanged for all-optional-arg fns (v1-faithful); for a fn with required keys it needs
        # the exact-match parametric wrapper (`{ __fn; __args; meta.exactMatch }` reading `__scopeKeys`
        # from the compile-parametric handler) — the parked parametric-wrapper mechanism → NAMED throw on
        # that branch only (never a fake wrapper). `builtins.trace` = the lib-free byte-transparent warn.
        take = {
          unused = _unused: used: used;
          atLeast =
            fn: builtins.trace "den.lib.take.atLeast is deprecated — bind.fn resolves args from handlers" fn;
          upTo =
            fn: builtins.trace "den.lib.take.upTo is deprecated — bind.fn resolves args from handlers" fn;
          __functor =
            _: _canTakePred: _argAdapter: fn:
            builtins.trace "den.lib.take custom predicate is deprecated — use plain parametric functions" fn;
          exactly =
            fn:
            builtins.trace "den.lib.take.exactly is deprecated — bind.fn resolves args from handlers" (
              let
                a = builtins.functionArgs fn;
                req = builtins.filter (k: !a.${k}) (builtins.attrNames a);
              in
              if req == [ ] then
                fn
              else
                throw "den.lib.take.exactly: the required-key __scopeKeys parametric mechanism is not yet ported"
            );
        };
        # den.lib.schema — v1's `den.lib.schema` (nix/lib/schema.nix) = the raw gen-schema.lib. den-hoag
        # already has the input in flake scope (no consumer-fallback needed); consumers (host.nix:22 /
        # home.nix:22) use it as `schemaLib` = raw.
        schema = inputs.gen-schema.lib;
        # den.lib.strict — v1's strict freeform-type module (nix/lib/strict.nix), exported UNAPPLIED (the
        # `{ lib, ... }:` fn). The consumer's raw-absorption evalModules injects nixpkgs `lib` when it
        # merges `den.schema.<kind> = den.lib.strict`; the substrate has no `lib.mkOptionType` so it must
        # NOT apply it here.
        strict = import ./lib/compat/strict.nix;
      };
    in
    {
      lib = migrationLib;
      inherit compat;

      # den-v1-compatible TOP-LEVEL flake outputs (the drop-in migration surface). `flakeModule` is what
      # nix-config's `modules/den/flake-parts.nix` imports; `flakeModules.default` is the flake-parts
      # convention alias. Both are the OUTPUT BRIDGE (ship-gate M1): it declares `options.den` with the
      # consumer's nixpkgs `lib` (raw absorption — never a gen-schema type in the strict eval), runs the
      # compat assembly, and sets `config.flake.{nixosConfigurations,darwinConfigurations}`. `flakeModules.
      # dendritic` (a den-diagram optional v1 carried) is intentionally absent — nix-config guards it `or {}`.
      flakeModule = {
        imports = [
          bridge
          builtinsModule
          ./lib/compat/batteries.nix
        ];
      };
      flakeModules.default = {
        imports = [
          bridge
          builtinsModule
          ./lib/compat/batteries.nix
        ];
      };
      # den v1 `flakeModules.strict` (denful/den nix/default.nix:9 → nix/strict.nix): an opt-in flake-parts
      # module a consumer imports to put every den schema kind into STRICT mode — an entity option set with
      # no explicit declaration aborts (`den.lib.strict`, lib/compat/strict.nix). Consumer-eval, additive;
      # den-hoag's own CI never imports it (parity-neutral). See lib/compat/flake-strict.nix for the
      # `.imports = [ den.lib.strict ]` form (vs v1's bare assignment, which den-hoag's schema collector drops).
      flakeModules.strict = import ./lib/compat/flake-strict.nix;
      # den v1 `flakeOutputs` (denful/den nix/flakeOutputs.nix, verbatim): per-family flake-output MERGE
      # modules a consumer imports (`imports = [ inputs.den.flakeOutputs.nixosConfigurations ]`) to give a
      # multi-valued flake output merge semantics — distinct keys combine, a duplicate key aborts NAMED
      # (`types.unique`). 100% nixpkgs-lib, path-free, consumer-eval; sole ext ref `den.schema.flake or {}`.
      flakeOutputs = import ./lib/compat/flake-outputs.nix;

      # The committed formatter config — `nix fmt` at the repo root runs `nixfmt-tree` (treefmt
      # preconfigured with nixfmt-rfc-style, the ecosystem's Nix formatting convention agents
      # formatted by before this pinned it). It traverses the tree and formats `.nix` with the SAME
      # nixfmt the ci/ treefmt + the pre-commit hook run, so root `nix fmt` is idempotent with them.
      # (ci/'s treefmt additionally runs actionlint + mdformat for the CI format gate; this root
      # output is the self-contained `nix fmt` a visitor runs.)
      formatter = inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed (
        system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree
      );
    };
}
