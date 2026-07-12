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
in
{
  imports = [ fleetContextEnrichModule ];
  config.den = {
    policies = {
      host-to-users = _ctx: [ ];
      user-to-host = userToHost;
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
    # (nixos/darwin/home-manager/k8s-manifests, lib/default.nix:59) ∪ the corpus's DECLARED `den.classes`
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
      # forwards to the host OS in v1 (no terminal of its own), so a bare inert registration matches its v1
      # nature exactly — with no producing member the emitted content is DEAD (dropped), as under v1. ──
      #
      # `wsl` (modules/aspects/batteries/wsl.nix:50) — THE u14 BLOCKER. The compat `primary-user` battery
      # (lib/compat/batteries.nix:140) emits `wsl.defaultUser` alongside its assertion-clearing
      # `nixos.users.users.<n>` account content; `wsl` was neither a core class nor corpus-declared, so once
      # the #63 fold FORCED the user cells' class-modules, `classifyKey` aborted on the `wsl` key BEFORE the
      # nixos content could classify. v1 routes wsl content to the host via `wsl-to-host` ONLY when a host sets
      # `wsl.enable` (wsl.nix:73-82 — `lib.optional ((host.wsl or {}).enable or false)`); NO corpus host does,
      # so the `wsl.defaultUser` emission is DEAD in v1 too (never routes). This registration unblocks the
      # SIBLING nixos content's classification; the wsl terminal stays output-less (no wsl-producing member),
      # so NO wsl route policies are ported — inert classification only.
      wsl = {
        description = "v1 WSL support class forwarding to host OS (batteries/wsl.nix:50); bare inert — no corpus host enables wsl, so primary-user's wsl.defaultUser is dead content (as under v1); registration unblocks the sibling nixos classification only.";
      };
      # `maid` (batteries/maid.nix:36) + `hjem` (batteries/hjem.nix:34): v1 user-environment classes forwarding
      # to the host OS. Corpus-unexercised (no aspect emits them), so inert; registered for built-in
      # completeness so the §2.2 abort class never recurs on a v1 built-in.
      maid = {
        description = "v1 nix-maid user-environment class (batteries/maid.nix:36); bare inert, corpus-unexercised.";
      };
      hjem = {
        description = "v1 Hjem user-environment class (batteries/hjem.nix:34); bare inert, corpus-unexercised.";
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
    };
  };
}
