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
  };
}
