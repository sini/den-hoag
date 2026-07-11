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
{
  prelude,
  errors,
}:
let
  deliverLib = import ./deliver.nix { inherit prelude errors; };
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
  # a named, class-F/G-routed message when fired at a real flake-system node.
  outputStub =
    name: v1src: _ctx:
    throw "den-compat builtin: `den.policies.${name}` is a v1 flake-OUTPUT policy (${v1src} @ pin 11866c16); its firing populates flake outputs (packages/devShells/flake-parts) — ship-gate class F/G, not the class-A nixosConfigurations arm (which crosses the nixos class terminal). Reproduce it with the class-F/G rows (needs the fleet-resolution surface, board #49/#50).";
in
{
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
    classes.flake-parts = {
      description = "v1 flake-parts scope class — the devshell route target (corpus devshell.nix:16); a bare inert collect-only class (no terminal, no crossing), the LATENT devShells output family (gate class F, board #51).";
    };
  };
}
