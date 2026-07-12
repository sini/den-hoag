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
      # gen-select's `entityKind`) routing to its board task, so a re-probe reads named blockers, not
      # `attribute 'x' missing`. The trivial policy constructors (include/exclude/mkPolicy/pipe) are the
      # v1 `__policyEffect`/`__pipeStage` record constructors, reproduced in compat (`policy-verbs.nix`,
      # ship-gate T3b) and aliased here; the fleet-resolution / instantiation verbs remain stubs (#49/#50).
      stub = ref: task: throw "den-hoag compat: `${ref}` — ${task}";
      # den.lib.home-env (ship-gate lib-surface) — v1's OS-user home battery builder (nix/lib/home-env.nix),
      # reproduced compat-side (lib/compat/home-env.nix). Its droid-path references
      # (`den.batteries.forward`, `den.lib.resolveEntity`, `den.lib.policy.*`) resolve against the migration
      # surface + named stubs; ALL are lazy, reached only when a droid-class host opens the battery gate — a
      # class-A (nixos) host leaves them inert. The `den`-shaped context it closes over: `.lib` = the
      # migration surface (recursive, cycle-free via laziness), `.batteries.forward` = the #49 forward-battery
      # stub, `.aspects` = `{ }` (the optional `os-user-class-fwd` include is absent, so `? …` is false).
      homeEnv = import ./lib/compat/home-env.nix {
        prelude = inputs.gen-prelude.lib;
        den = {
          lib = migrationLib;
          aspects = { };
          # #73: the forward battery rides INERT (an empty aspect — v1's `forwardEach` returns
          # `{ includes = map forwardItem each; }`, batteries/forward.nix/nix/lib/forward.nix at the pin;
          # the inert twin carries no items). Its ONLY corpus consumer is the droid home arc (home-env
          # userForward → the nix-on-droid HOME output family, den-hoag-ABSENT — the u4 intoAttr
          # posture), so a translated forward would have NO reachable artifact either way; the absent
          # `nixOnDroidConfigurations` output is the self-announcement (ledger u22, the u2/u4 shape).
          # The REAL surface is the #49/#50 forward-battery NTA (arc-2 territory).
          batteries.forward = _spec: { includes = [ ]; };
        };
      };
      migrationLib = lib // {
        # den.lib.policy.* — the policy-authoring vocabulary nix-config writes policies with.
        policy = {
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
          # (ledger rows). The intoAttr OUTPUT FAMILY is its own rung (board #50) when the class-C/D arms come up.
          instantiate = spec: {
            __policyEffect = "instantiate";
            value = spec;
          };
        };
        # den.lib.aspects.* / resolveEntity / home / capture — v1 lib surfaces (semantic; escalated).
        aspects = {
          resolve = stub "lib.aspects.resolve" "the aspect-resolution surface (board #49) — not yet available";
          # fx.keyClassification — the #49-SLICE: real, reproducing v1's `structuralKeysSet` (the ONE export
          # the corpus reads). The rest of the #49 semantic surface stays escalated.
          fx.keyClassification = compat.keyClassification;
        };
        resolveEntity = stub "lib.resolveEntity" "the entity-resolution surface (R8; board #49/#50) — not yet available";
        home = stub "lib.home" "the home-entity surface (board #49) — not yet available";
        capture.captureFleet = stub "lib.capture.captureFleet" "the fleet-capture surface (board #49) — not yet available";
        # den.lib.home-env — the OS-user home battery builder {makeHomeEnv, mkDetectHost, mkIntoClassUsers}
        # (v1 nix/lib/home-env.nix), reproduced faithfully compat-side; wired above.
        "home-env" = homeEnv;
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
