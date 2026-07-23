# den-compat BUILT-IN PROVISIONING (spec §10 / ship-gate). den v1's flakeModule imports built-in modules
# (`modules/policies/{flake,flake-parts,core}.nix`, `modules/context/flake-schema.nix`, the os-user battery)
# that DEFINE `den.policies.<name>` + register routing KINDS. A v1 consumer (the corpus) references those
# built-ins by name — `den.schema.flake-system.includes = [ den.policies.system-to-flake-parts ]`
# (nix-config `modules/den/classes/devshell.nix:26`), `den.schema.host.excludes = [ den.policies.host-to-users ]`
# (`modules/den/policies/fleet.nix:91`). Those references are attribute accesses during the CONSUMER's own
# module eval, so the shim must present the built-ins AT EVAL TIME — a flake-parts module merged into the
# freeform `config.den` (mirroring v1's flakeModule imports), NOT a compile-time `desugarLegacy` (which runs
# after config is read). This module IS that provisioning. Reproduced from the frozen pin (11866c16); it is
# v1 VOCABULARY, so it lives COMPAT-side (never den-hoag core — the boundary tripwire holds).
#
# PROVIDE vs STUB (ship-gate, class-A `nixosConfigurations` arm):
#   - `user-to-host` (os-user.nix): the os-user route, reconstructed value-identically off `deliver.nix`
#     (NOT by importing the legacy battery — single-legacy-import-site invariant); the desugar's `//`
#     overwrite is idempotent → ONE firing. Class-A never references the attr (only the droid-gated
#     `drop-user-to-host-on-droid`, class-B/#50); this presents it.
#   - `host-to-users` (core.nix:17): the v1 default host→user resolution the corpus opts OUT of
#     (`den.schema.host.excludes`, "fleet user policies replace it"). den-hoag resolves host→user
#     STRUCTURALLY (`host.users` → `member`, ingest.nix), so there is no such policy to fire — this inert
#     never-emitting definition only satisfies the exclude reference (a genuine no-op).
#   - `system-to-os-outputs`/`system-to-hm-outputs`/`system-to-flake-parts` (flake.nix:53/67,
#     flake-parts.nix:9): v1 flake-OUTPUT built-ins (flake-system → flake / home / flake-parts outputs).
#     den-hoag produces `nixosConfigurations` via the nixos CLASS terminal, NOT the v1 flake→flake-system
#     output chain, so for class-A these are plausibly unreachable; each is a NAMED THROWING STUB routed to
#     the ship-gate class-F/G rows (devShells / packages). The attr EXISTS unconditionally (class-A reads
#     `flake-system.includes` for every artifact), but FIRING throws the routed message — self-announcing:
#     if a class-A re-probe surfaces the throw, the chain IS class-A-reachable and we PROVIDE it then.
#     GATED BY v1's OWN FORMALS (`{ system, ... }`): each stub carries the destructuring pattern its v1
#     policy declares at the pin — `system-to-flake-parts` flake-parts.nix:9-10, `system-to-os-outputs`
#     flake.nix:53-54, `system-to-hm-outputs` flake.nix:67-68, all `{ system, ... }:`. `system` is a v1
#     flake-SYSTEM coord (v1 binds it only at a flake-system node — flake.nix:50 `resolve.to "flake-system"
#     { inherit system; }`, flake-parts.nix:14 `name = "flake-parts-${system}"`), NOT the host's `system`
#     FIELD (`host.system` rides NESTED under the `host` coord, never a top-level ctx key). den-hoag reads a
#     `den.policies.<name>` fn's `functionArgs` as its dispatch gate, and compiles EVERY `den.policies.<name>`
#     into a FLEET-WIDE standalone rule (compile.nix `compiledPolicies` → `policies`; ledger u3 / board #57),
#     so the gate is what bounds its firing. With `{ system, ... }` the fleet-wide rule's condition is
#     `{ system = false; }` → it fires ONLY where a `system` coord is bound = v1's flake-system nodes, which
#     the corpus NEVER spawns (the `flake → flake-system` fan-out `flake-to-systems` is NOT provisioned; hosts
#     arrive via the nixos class terminal). So the stubs are gated-inert for class-A THROUGH THE CORRECT
#     MECHANISM (v1's own gate), self-announcing ONLY at a genuine flake-system node.
#     EVAL-ORDER HISTORY: the stubs were previously `_ctx:` bare fns — EMPTY `functionArgs` ⇒ the fleet-wide
#     rule's condition was `{ }` ⇒ they fired at EVERY node by DISPATCH (not by demand), surfacing the throw at
#     `host:axon-01` class-modules once the class-A arm reached class-modules. Earlier ship-gate probes never
#     crossed class-modules, so the empty gate went unobserved until this rung. The `{ system, ... }` gate is
#     v1's gate verbatim — fire-by-demand restored.
{
  prelude,
  errors,
  declare,
}:
let
  deliverLib = import ./deliver.nix { inherit prelude errors; };
  # FLEET-CONTEXT ENRICHMENT (ship-gate rung) — binds `environment`/`secretsConfig`/`fleet` into every
  # host-bearing node's enriched-context, the compat twin of v1's fleet.nix scope-inheritance fan-out
  # (see fleet-context.nix for the law + v1 cites). Provisioned below as a config-dependent sub-module
  # (`imports`), so it can read the bridge-ingested `config.den.environments` / `config.den.secretsConfig`.
  fleetContext = import ./fleet-context.nix { inherit declare; };
  # The provisioning module (config-dependent — reads the flake-parts `config.den` registries). Kept in
  # `imports` (not the top-level `config` below) so `builtins.nix`'s static `config.den.{classes,schema,
  # policies}` view stays a plain attrset for the unit suites that read it directly.
  fleetContextEnrichModule =
    { config, ... }:
    {
      # SINGLE WRITER of environment/secretsConfig/fleet (structural.nix:108-118): the corpus fleet.nix
      # `to-fleet`/`env-to-hosts` fan-out that would ALSO bind them stays lazily inert (its `self`/
      # `environment` gate coords are never bound by the stubbed resolve surface), so no collision.
      config.den.policies.fleet-context-enrich = fleetContext.mkEnrichPolicy {
        envs = config.den.environments or { };
        secretsConfig = config.den.secretsConfig or { };
      };
    };
  # `user-to-host` — the os-user battery route (os-user.nix `userToHost` @ pin 11866c16), reconstructed
  # here VALUE-IDENTICALLY off the shared `deliver.nix` surface, NOT by importing the legacy battery (the
  # single-legacy-import-site invariant, compat-legacy-severed). For the corpus the desugar's `//` overwrite
  # of this provisioned value is idempotent → ONE firing (no double); if the desugar is severed this real
  # route fires correctly. Class-A never references the attr (only the droid-gated exclude, class-B/#50) —
  # this presents it so that reference resolves + the droid exclude reaches its named class-B abort.
  userToHost = {
    __denCanTake = "user-host";
    fn =
      { user, host, ... }:
      [
        (deliverLib.route {
          fromClass = "user";
          intoClass = host.class or null;
          path = [
            "users"
            "users"
            user.name
          ];
          adaptArgs = args: args // { osConfig = args.config; };
          # PARENT-TARGET the route so the cell-fired user→host remap gathers at the HOST (the containment
          # parent), not the cell's isolated edge-root — `deliveryTargetRootOf cell = host` ⇒
          # `parentTargetedRoutesAt host` picks it up ⇒ the cell's `user`-class slice lands at
          # `<host>.users.users.<name>.*`. Mirrors `hmUserDetect`'s parent-targeted homeManager forward; v1
          # renders the cell→host delivery as an appendToParent forward (the ratified trace-target ceiling).
          __extra.appendToParent = true;
        })
      ];
  };
  # `hm-user-detect` — the v1-AMBIENT home-manager battery's USER-SCOPE emitter (#68, ledger u18 Family
  # A; the FULL v1 census + semantics in legacy/batteries/home-manager.nix — reconstructed here
  # VALUE-IDENTICALLY like userToHost, the single-legacy-import-site invariant). v1 userDetectFn
  # (home-env.nix) gates `isOsSupported && hasClass` and includes the userForward (a TIER-1 static
  # forward: homeManager → host.class at [home-manager users <userName>], home-manager.nix:12-24);
  # probe-safe via the intoClass value-gate (null ⇒ __dropped — the os-class posture), parent-targeted
  # via #53c appendToParent (the ratified trace-target ceiling, u18). `user.userName or user.name` = v1's
  # userName default (entities/host.nix:156 `userName = strOpt … config.name`).
  hmUserDetect = {
    __denCanTake = "user-host";
    fn =
      { user, host, ... }:
      let
        isOsSupported = builtins.elem (host.class or null) [
          "nixos"
          "darwin"
        ];
        hasClass = builtins.elem "homeManager" (user.classes or [ ]);
      in
      [
        (deliverLib.route {
          fromClass = "homeManager";
          intoClass = if isOsSupported && hasClass then host.class else null;
          intoPath = [
            "home-manager"
            "users"
            (user.userName or user.name)
          ];
          __extra.appendToParent = true;
        })
      ];
  };
  # A v1 flake-OUTPUT built-in the class-A arm does not reproduce: exists for the ingest attr access, throws
  # a named, class-F/G-routed message when fired at a real flake-system node. GATED by v1's OWN formals
  # (`{ system, ... }:`, verbatim from the pin — flake-parts.nix:9-10, flake.nix:53-54, flake.nix:67-68), so
  # den-hoag's `functionArgs` gate compiles the fleet-wide rule with condition `{ system = false; }` and it
  # fires ONLY where a `system` flake-system coord is bound (v1's flake-system nodes) — corpus-absent, hence
  # gated-inert for class-A by DEMAND, not the empty `_ctx:` gate that fired everywhere by DISPATCH (header,
  # eval-order history). `system` is a flake-system COORD (v1 `resolve.to "flake-system" { inherit system; }`),
  # NOT the host's nested `host.system` FIELD; a host node's ctx carries no top-level `system` key (empirically
  # verified — a host cell's coords are the fleet product dims host/user/env/cluster, never `system`).
  outputStub =
    name: v1src:
    { system, ... }:
    throw "den-compat builtin: `den.policies.${name}` is a v1 flake-OUTPUT policy (${v1src} @ pin 11866c16); its firing populates flake outputs (packages/devShells/flake-parts) — ship-gate class F/G, not the class-A nixosConfigurations arm (which crosses the nixos class terminal). Reproduce it with the class-F/G rows (needs the fleet-resolution surface, board #49/#50).";

  # ── v1 AMBIENT home-env-family + wsl batteries (modules/aspects/batteries/{maid,hjem,wsl}.nix @ pin
  #    11866c16) ────────────────────────────────────────────────────────────────────────────────────────
  # v1's flakeModule auto-imports every `modules/**.nix` (listFilesRecursive), so maid/hjem/wsl are AMBIENT
  # on every v1 fleet — reproduced here VALUE-IDENTICALLY (the single-legacy-import-site invariant, like
  # userToHost/hmUserDetect above). All three are corpus-INERT: no corpus user carries a maid/hjem class and
  # no corpus host enables wsl, so their emitters null-gate / self-gate to no-ops and their per-host `module`
  # option defaults are THROWING-LAZY (never reference an absent flake input). Provisioning them therefore
  # does not perturb the corpus eval (the corpus-relative INERT posture, ledger B15/q).
  #
  # v1 drives maid/hjem through `den.lib.home-env.makeHomeEnv`; here they are HAND-WRITTEN as tier-1 routes
  # because `den.batteries.forward` is an inert stub (flake.nix), so makeHomeEnv's `userForward` yields no
  # routes — the shipped home-manager port took the same hand-written path (see hmUserDetect above). Each
  # battery SPLITS into a CONTENT ROUTE + a host-scope MODULE IMPORT (mirroring v1's userDetectFn route +
  # classIncludes module import):
  #   • the CONTENT ROUTE — maid/hjem use a `__denCanTake = "user-host"` cell emitter (the hmUserDetect
  #     shape): the class bucket → the host OS class at the forward path, parent-targeted (#53c
  #     appendToParent — a cell-fired route to a DEEP host path lands in the cell's isolated edge-root
  #     without it). wsl instead uses a `host`-scope route (wsl-to-host, below) — it must also capture
  #     HOST-scope wsl content, where appendToParent would drop (see there). Both are probe-safe via the
  #     intoClass null-gate (the os-class posture — a value-conditional emission misclassifies as enrich).
  #   • the host-MODULE IMPORT — a `den.schema.host.includes` policy (v1 makeHomeEnv.hostModule /
  #     wsl-host-aspect), HOST-scope so it reaches the OS terminal directly, gated on the host carrying a
  #     class member (maid/hjem) or `wsl.enable` (wsl). A schema-include policy record tolerates the
  #     value-conditional emission (compile.nix kindIncludePolicies: per-declaration stratum, no enrich
  #     misclassification), so the gate rides the emission (unlike the config.den.policies routes).
  mkInclude = aspect: {
    __policyEffect = "include";
    value = aspect;
  };

  # v1 home-env.nix:47 `host-has-user-with-class` — probe-safe (`or`-guarded) reads.
  hostHasUserWithClass =
    host: class:
    builtins.any (user: builtins.elem class (user.classes or [ ])) (
      builtins.attrValues (host.users or { })
    );

  # v1 makeHomeEnv.hostOptions (home-env.nix:71-93) — the per-host `<optionPath>.{enable,module}` option
  # module, wired via `den.schema.host.imports` (v1 {maid,hjem}.nix:31/29). `lib` from the MODULE ARGS (the
  # compat consumer-lib posture, home-env.nix:77-79 — the shim captures no nixpkgs lib). The `module` default
  # is THROWING-LAZY: v1 threads `inputs.<pkg>."${host.class}Modules".default`, which the compat layer cannot
  # access; the throw fires ONLY if a class-enabled host omits `.module` (the witnesses set it explicitly and
  # the corpus never carries a maid/hjem user, so the read is never reached).
  mkHostConf =
    {
      optionPath,
      className,
      throwMsg,
    }:
    { host, lib, ... }:
    {
      options.${optionPath} = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = hostHasUserWithClass host className;
        };
        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = throw throwMsg;
        };
      };
    };

  maidHostConf = mkHostConf {
    optionPath = "nix-maid";
    className = "maid";
    throwMsg = "den-compat: the maid battery requires `den.hosts.<system>.<name>.nix-maid.module` set explicitly (inputs.nix-maid is not threaded into the compat layer).";
  };
  hjemHostConf = mkHostConf {
    optionPath = "hjem";
    className = "hjem";
    throwMsg = "den-compat: the hjem battery requires `den.hosts.<system>.<name>.hjem.module` set explicitly (inputs.hjem is not threaded into the compat layer).";
  };

  # v1 makeHomeEnv.hostModule (home-env.nix:125-134): import `host.<optionPath>.module` into the host OS
  # body. KEYED for module-system dedup (v1's key), so a repeated include collapses to one import.
  mkHostModuleAspect =
    optionPath:
    { host }:
    {
      ${host.class}.imports = [
        {
          key = "den:${optionPath}-host-module";
          imports = [ host.${optionPath}.module ];
        }
      ];
    };

  # The host-scope module-import policy (`den.schema.host.includes`), gated on the host carrying ≥1 user of
  # the class (v1 makeHomeEnv.mkDetectHost's `hostHasClass`). Conditional emission is tolerated on the
  # schema-include path (kindIncludePolicies per-declaration stratum).
  mkHostModulePolicy =
    {
      name,
      optionPath,
      className,
    }:
    {
      __isPolicy = true;
      inherit name;
      fn =
        { host, ... }:
        if hostHasUserWithClass host className then
          [ (mkInclude (mkHostModuleAspect optionPath { inherit host; })) ]
        else
          [ ];
    };

  # The user-scope CONTENT emitter (v1 makeHomeEnv.userDetectFn ∘ userForward, tier-1-rendered) — the
  # hmUserDetect shape: an UNCONDITIONAL, null-gated, parent-targeted route (fromClass = the battery class →
  # the host OS at the forward path). `user.userName or user.name` = v1's userName default (host.nix:156).
  mkUserDetect =
    {
      className,
      supportedOses,
      forwardPathFn,
    }:
    {
      __denCanTake = "user-host";
      fn =
        { user, host, ... }:
        let
          isOsSupported = builtins.elem (host.class or null) supportedOses;
          hasClass = builtins.elem className (user.classes or [ ]);
        in
        [
          (deliverLib.route {
            fromClass = className;
            intoClass = if isOsSupported && hasClass then host.class else null;
            intoPath = forwardPathFn { inherit user host; };
            __extra.appendToParent = true;
          })
        ];
    };

  maidUserDetect = mkUserDetect {
    className = "maid";
    supportedOses = [ "nixos" ];
    forwardPathFn =
      { user, ... }:
      [
        "users"
        "users"
        (user.userName or user.name)
        "maid"
      ];
  };
  hjemUserDetect = mkUserDetect {
    className = "hjem";
    supportedOses = [
      "nixos"
      "darwin"
    ];
    forwardPathFn =
      { user, ... }:
      [
        "hjem"
        "users"
        (user.userName or user.name)
      ];
  };
  maidHostModulePolicy = mkHostModulePolicy {
    name = "nix-maid-host-module";
    optionPath = "nix-maid";
    className = "maid";
  };
  hjemHostModulePolicy = mkHostModulePolicy {
    name = "hjem-host-module";
    optionPath = "hjem";
    className = "hjem";
  };

  # ── wsl (v1 batteries/wsl.nix @ pin 11866c16) ────────────────────────────────────────────────────────
  wslModuleThrow = "den-compat: the wsl battery requires `den.hosts.<system>.<name>.wsl.module` set explicitly (inputs.nixos-wsl is not threaded into the compat layer).";
  # v1 hostConf (wsl.nix:27-35): `wsl.{enable,module}`. `enable` = mkEnableOption (default false); `module`
  # = deferredModule with a THROWING-LAZY default (v1 defaults `inputs.nixos-wsl.nixosModules.default`).
  wslHostConf =
    { lib, ... }:
    {
      options.wsl = {
        enable = lib.mkEnableOption "Enable WSL on this host";
        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = throw wslModuleThrow;
        };
      };
    };
  # v1 wsl-host-aspect (wsl.nix:37-46): import host.wsl.module into the host OS + set `wsl.enable = true`.
  # The keyed inner import gives module-system dedup. NO top-level `name`: an included attrset carrying a
  # bare `name` (no `key`) is a named REFERENCE in the compat include arm (compile.nix isEmittedContentSet /
  # resolveAspectRef), not emitted CONTENT — v1's trace `name` is redundant here (den-hoag grounds emitted
  # content by scope-coord identity, mkEmittedAspect). `${host.class}` is only forced when included
  # (host-to-wsl-host gates it), never at the value-less probe.
  wslHostAspect =
    { host }:
    {
      ${host.class} = {
        imports = [
          {
            key = "den:wsl-host-module";
            imports = [ host.wsl.module ];
          }
        ];
        wsl.enable = true;
      };
    };
  # v1 host-to-wsl-host (wsl.nix:56-64) → `den.schema.host.includes`, gated on nixos + wsl.enable. The v1
  # `resolve.to "wsl-host"` sibling is DROPPED: `wsl-host` is NOT a registered schema kind (v1 declares no
  # `den.schema.wsl-host`), so den-hoag's resolve arm would abort resolveUnknownKind; its content is
  # delivered by the sibling `include wsl-host-aspect`, not the empty wsl-host scope (a consumer-less,
  # drvPath-invisible scope — the documented ledger ceiling, the #53c-class trace-only divergence).
  hostToWslHost = {
    __isPolicy = true;
    name = "host-to-wsl-host";
    fn =
      { host, ... }:
      if (host.class or null) == "nixos" && ((host.wsl or { }).enable or false) then
        [
          (mkInclude (wslHostAspect {
            inherit host;
          }))
        ]
      else
        [ ];
  };
  # v1 wsl-to-host (wsl.nix:73-82): route wsl class content → the host OS class at [wsl]. Reproduced as an
  # UNCONDITIONAL, null-gated route (the os-class posture — a value-conditional emission misclassifies as
  # enrich; the `host.wsl.enable` gate rides the intoClass field). Fires at host + cells (host coord
  # present), so both host-scope wsl content (a host aspect) AND cell-scope wsl content (primary-user's
  # `wsl.defaultUser` at a (user,host) cell) are captured.
  #
  # NO appendToParent (unlike the user→host / homeManager cell forwards): this route's TARGET is the OS
  # CLASS (nixos), whose content folds cell→host through the ordinary containment nesting (the primary-user
  # precedent — a cell's nixos content folds up its subtree to the host's assembly), so a cell-fired
  # wsl→nixos delivery reaches the host WITHOUT a parent-target. appendToParent would in fact BREAK the
  # host-scope case: at a root (host) firing, the parent target does not resolve to the host itself here, so
  # the host aspect's own wsl content would be dropped. v1's guard (`options ? wsl`) is likewise omitted —
  # the intoClass null-gate already bounds firing to wsl-enabled hosts, and the guard's target-option read
  # filtered the content out before the sibling host-to-wsl-host module import declared `options.wsl`.
  wslToHost = {
    __denCanTake = "host";
    fn =
      { host, ... }:
      [
        (deliverLib.route {
          fromClass = "wsl";
          intoClass =
            if (host.class or null) == "nixos" && ((host.wsl or { }).enable or false) then host.class else null;
          path = [ "wsl" ];
        })
      ];
  };
in
{
  imports = [ fleetContextEnrichModule ];
  config.den = {
    policies = {
      host-to-users = _ctx: [ ];
      user-to-host = userToHost;
      hm-user-detect = hmUserDetect;
      # v1 ambient home-env-family / wsl content routes (see the batteries section above): the maid/hjem
      # user-scope forwards + the wsl class-content route. Corpus-inert (null-gated).
      maid-user-detect = maidUserDetect;
      hjem-user-detect = hjemUserDetect;
      wsl-to-host = wslToHost;
      system-to-os-outputs = outputStub "system-to-os-outputs" "modules/policies/flake.nix:53";
      system-to-hm-outputs = outputStub "system-to-hm-outputs" "modules/policies/flake.nix:67";
      system-to-flake-parts = outputStub "system-to-flake-parts" "modules/policies/flake-parts.nix:9";
    };
    # Routing-kind registration (v1 `modules/context/flake-schema.nix` empty bodies ⇒ isEntity = false;
    # `modules/policies/flake-parts.nix:30` sets flake-parts.isEntity = true; `modules/options.nix:146`
    # `den.schema.fleet`; the home-manager battery's `hm-host`). Registration only — the stubbed output
    # chains spawn no instances, so class-A never resolves through them.
    schema = {
      flake = { };
      flake-system = { };
      flake-parts.isEntity = true;
      fleet = { };
      hm-host = { };
      # v1 ambient home-env-family / wsl HOST wiring (batteries/{maid,hjem,wsl}.nix): the per-host
      # `{nix-maid,hjem,wsl}.{enable,module}` options (imports) + the host-scope module-import policies
      # (includes: maid/hjem gated on a class member, wsl gated on wsl.enable). Both are collections the
      # bridge concatenates across schema defs, so they compose with the corpus's own host schema.
      host = {
        imports = [
          maidHostConf
          hjemHostConf
          wslHostConf
        ];
        includes = [
          maidHostModulePolicy
          hjemHostModulePolicy
          hostToWslHost
        ];
      };
    };
    # CLASS registration (ship-gate rung, CLASS-A-MINIMAL; R2 — the compat-side class-vocabulary registry).
    # `flake-parts` is a v1 flake-level SCOPE class the corpus ROUTES INTO: the `devshell-to-flake-parts`
    # policy emits `route { fromClass = "devshell"; intoClass = "flake-parts"; path = ["devshells" "default"];
    # adaptArgs = …; }` (corpus modules/den/classes/devshell.nix:16), and that policy's empty formals make it
    # fire at every scope, so `translateDelivery` calls `resolveBucket "deliver" "flake-parts"` — which, with
    # `flake-parts` neither a den-hoag built-in class nor a v1-declared one, aborted `unknown class flake-parts`.
    # Registered here through den-hoag's PUBLIC class registry — a bare `den.classes.flake-parts`, the general
    # declared-classes surface (assembly §2.2; `entity.discoverClasses` seeds it into the fleet's registered set
    # = built-ins ∪ declared) — the SAME compat-side mechanism the os-class battery registers `os` with
    # (legacy/batteries/os-class.nix:44-50). Provisioned in THIS module (not a severable legacy desugar) because
    # `flake-parts` is built-in flake-scope vocabulary always present, the peer of its schema-KIND registration
    # above. A bare declared class: (a) enters ingest's `classRegistry` ⇒ `resolveBucket` resolves the route's
    # `intoClass` (C6, the abort's fix); (b) admits `flake-parts` to `classifyKey`'s CLASS branch (an aspect
    # content key routes as class content); (c) is never any scope's PRODUCING class (no host/user produces
    # flake-parts) ⇒ grows NO phantom fold edge; (d) carries NO wrap/instantiate/share ⇒ an INERT, collect-only
    # terminal with NO gen-flake crossing.
    #
    # LATENT OUTPUT (self-announcing, gate class F, board #51; ledger row B2 re-opened): NO flake-level output
    # family is built this rung — the routed devshell content collects into the flake-parts bucket but
    # materializes to no output, so `flake.devShells` stays EMPTY until the devShells output family lands.
    #
    # KIND∪CLASS COEXISTENCE (empirically verified pre-build): `flake-parts` is ALSO the schema KIND above.
    # The two registrations live in DISJOINT config namespaces (`den.schema.*` vs `den.classes.*`) and function
    # together — the `den.schema.flake-parts.includes` kind-include list still processes, and an aspect content
    # key `flake-parts` routes to the CLASS branch (kinds are NOT consulted by `classifyKey`); pinned by
    # `ci/tests/compat-flake-parts-class.nix`.
    #
    # THE FULL v1 BUILT-IN CLASS SET (u15 — the u14 register). den v1's flakeModule imports EVERY
    # `modules/**.nix` (`nix/flakeModule.nix:3` — `listFilesRecursive`, no `/_`), so every built-in module
    # that DECLARES a `den.classes.<name>` is ALWAYS registered on a v1 fleet — regardless of whether the
    # corpus produces content for that class. den-hoag's registered set is the kind-generic core `classNames`
    # (nixos/darwin/home-manager) ∪ the corpus's DECLARED `den.classes`
    # (entity.discoverClasses — droid/microvm/homeLinux/…) ∪ the os/user legacy-desugar classes
    # (legacy/batteries/{os-class,os-user}.nix) ∪ THESE shim-provisioned built-ins. The v1 built-ins the core
    # + desugars do NOT already carry are registered HERE — a bare declared class each (the flake-parts
    # recipe), so a §2.2 `classifyKey` abort on a v1 built-in class name (the u14 `wsl` blocker) NEVER recurs.
    # A bare declared class: (a) enters ingest's `classRegistry` ⇒ `resolveBucket` resolves it; (b) admits the
    # name to `classifyKey`'s CLASS branch (an aspect content key routes as class content, not an abort); (c)
    # is never any scope's PRODUCING class (no host/user produces it) ⇒ grows NO phantom fold edge; (d) carries
    # NO wrap/instantiate/share ⇒ an INERT collect-only terminal, NO gen-flake crossing. Registration only
    # unblocks CLASSIFICATION — a corpus with NO producing member ⇒ NO output entry (the corpus-relative INERT
    # posture, ledger B15/q). v1-SPEC facts (the built-in class LIST is one) belong COMPAT-side; the
    # kind-generic core `classNames` stays UNTOUCHED (the KIND-GENERIC law). Written as LITERALS (no
    # `prelude.genAttrs`) so `config.den.classes` forces without `prelude` — the dummy-args unit read in
    # `ci/tests/{compat-flake-parts-class,compat-builtin-classes}.nix` stays valid.
    classes = {
      # v1 flake-level SCOPE class — the devshell route target (corpus devshell.nix:16); the LATENT devShells
      # output family (gate class F, board #51; ledger row B2). ALSO the schema KIND above (coexistence pinned
      # by ci/tests/compat-flake-parts-class.nix).
      flake-parts = {
        description = "v1 flake-parts scope class — the devshell route target (corpus devshell.nix:16); a bare inert collect-only class (no terminal, no crossing), the LATENT devShells output family (gate class F, board #51).";
      };

      # ── v1 BATTERY convenience/forwarding classes (always-imported battery modules @ pin 11866c16). Each
      # forwards to the host OS in v1 (no terminal of its own); their battery BEHAVIOR (host options, module
      # imports, content routes) is wired in the batteries section above, and stays corpus-inert (no producing
      # member ⇒ the emitted content is DEAD / dropped, as under v1). ──
      #
      # `wsl` (modules/aspects/batteries/wsl.nix:50) — THE u14 BLOCKER (the compat `primary-user` battery,
      # lib/compat/batteries.nix:140, emits `wsl.defaultUser`; `wsl` had to classify). The class forwards to
      # the host OS in v1 (no terminal of its own): its behavior — the `wsl.{enable,module}` host option, the
      # host-scope `host-to-wsl-host` module import, and the `wsl-to-host` content route — is wired in the
      # batteries section above (`hostToWslHost`/`wslToHost`). Corpus-INERT: no corpus host enables wsl, so
      # the routes null-gate and the module import self-gates (as under v1, where wsl-to-host fires only on
      # `host.wsl.enable`). The class registration admits the `wsl` key to `classifyKey`'s CLASS branch.
      wsl = {
        description = "v1 WSL support class forwarding to host OS (batteries/wsl.nix:50); behavior wired above (wsl.{enable,module} host option + host-to-wsl-host module import + wsl-to-host route), corpus-inert (no host enables wsl).";
      };
      # `maid` (batteries/maid.nix:36) + `hjem` (batteries/hjem.nix:34): v1 user-environment classes forwarding
      # to the host OS. Their behavior — the per-host `{nix-maid,hjem}.{enable,module}` option, the host-scope
      # module import, and the user-scope content forward — is wired in the batteries section above
      # (`{maid,hjem}UserDetect`/`{maid,hjem}HostModulePolicy`). Corpus-INERT: no corpus user carries a
      # maid/hjem class, so the forwards null-gate and the module imports self-gate.
      maid = {
        description = "v1 nix-maid user-environment class (batteries/maid.nix:36); behavior wired above (nix-maid.{enable,module} host option + host-module import + maid-user-detect forward), corpus-inert (no user carries the class).";
      };
      hjem = {
        description = "v1 Hjem user-environment class (batteries/hjem.nix:34); behavior wired above (hjem.{enable,module} host option + host-module import + hjem-user-detect forward), corpus-inert (no user carries the class).";
      };

      # ── v1 FLAKE SYSTEM OUTPUT classes (modules/policies/flake.nix:12-16 `systemOutputs`, registered
      # flake.nix:41-46: "Register system output names as classes so aspect keys dispatch correctly"). These are
      # flake-SCOPE output classes. The corpus routes its flake-scope content through the `flake-parts`/`devshell`
      # classes (devshell.nix), NEVER a bare `packages`/`devShells`/… top-level aspect key (verified corpus-wide),
      # so they are inert here. Registered bare so a flake-parts-modules aspect key matching a v1 output name
      # CLASSIFIES (CLASS branch) exactly as under v1, never aborts. A producing member would be the flake-OUTPUT
      # family rung (gate class F/G, board #51 — the flake-parts devShells twin); corpus-absent ⇒ latent. ──
      packages = {
        description = "v1 flake `packages` output class (modules/policies/flake.nix:41); bare inert flake-scope class, corpus-unexercised.";
      };
      apps = {
        description = "v1 flake `apps` output class (modules/policies/flake.nix:41); bare inert flake-scope class, corpus-unexercised.";
      };
      checks = {
        description = "v1 flake `checks` output class (modules/policies/flake.nix:41); bare inert flake-scope class, corpus-unexercised.";
      };
      devShells = {
        description = "v1 flake `devShells` output class (modules/policies/flake.nix:41); bare inert flake-scope class, corpus-unexercised (the corpus routes devshell content through the flake-parts class, not this key).";
      };
      legacyPackages = {
        description = "v1 flake `legacyPackages` output class (modules/policies/flake.nix:41); bare inert flake-scope class, corpus-unexercised.";
      };

      # ── v1 KUBERNETES-MANIFEST output class — a compat-provisioned built-in. NOT a kind-generic core class
      # (a bare generic den has no k8s built-in — k8s is a consumer/compat concern), so it is registered here
      # as a bare inert declared class, exactly like the battery/flake-output built-ins above. With no producing
      # member the emitted content is DEAD (dropped); registration only unblocks CLASSIFICATION. ──
      k8s-manifests = {
        description = "v1 kubernetes-manifest output class; bare inert compat built-in (no kind-generic core class), corpus-unexercised — registration unblocks classification only.";
      };
    };
  };
}
