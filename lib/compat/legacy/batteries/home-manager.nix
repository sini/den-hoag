# den-compat LEGACY battery: `home-manager` (task #68, ledger u18 Family A). Port of den v1's
# v1-AMBIENT home-manager battery at the frozen pin (11866c16
# modules/aspects/batteries/home-manager.nix) — v1 auto-loads it via the flakeModule (nix/flakeModule.nix
# `listFilesRecursive`), and the corpus RELIES on that ambience (corpus defaults.nix:26: "home-manager and
# os-class are support modules … they auto-load via den's flakeModule and wire their own schema/policies").
#
# v1's battery does FOUR things (home-manager.nix:17-37); the shim needs exactly ONE of them:
#   • `den.schema.host.imports = [ result.hostConf ]` — the per-host `home-manager.{enable,module}`
#     OPTION — ALREADY reproduced by the bridge-registry passthrough (registry.nix: "per-host
#     home-manager module (v1 home-env.nix:49-53 via the hm battery hostConf; corpus host.nix:329-334)");
#     and the hostModule IMPORT (v1 home-env.nix:74-86, keyed `den:home-manager-host-module`) is the R6
#     `hmModuleFor` grain (ingest.nix; flake-module.nix:154-176 imports it with v1's EXACT dedup key).
#     Re-emitting it here would double-import — NOT ported.
#   • `den.classes.homeManager.{description,parentPath,parentArg}` — the class registration. `homeManager`
#     grounds to den-hoag's BUILT-IN `home-manager` class (compile.nix v1ClassKeyMap), so no registration
#     is needed; `parentPath`/`parentArg = "osConfig"` are v1 pipe-layer fields whose den-hoag rendering
#     is the config-thunk resolve-at-producing-scope machinery (PR #623 / decision #27 — deferred thunks
#     get config+osConfig at the producing class+scope) — NOT re-ported as class fields.
#   • `den.schema.host.includes = [ result.battery ]` — the HOST-fired emitter (home-env.nix policyFn):
#     gated on `isEnabled && isOsSupported && hostHasClass` where hostHasClass reads `host.users` — the
#     corpus's humans arrive via env-users `resolve.to "user"` (NOT `host.users`), so this emitter is
#     corpus-INERT in v1 too (ledger u14 diagnosed it); its den-hoag rendering is subsumed anyway: a
#     `host.users`-declared hm user materializes as a (user,host) CELL, where the user-scope emitter
#     below fires — the same forward, one mechanism (witnessed: the host-declared-user companion).
#   • `den.schema.user.includes = [ result.userDetect ]` — the USER-scope emitter (home-env.nix
#     userDetectFn) — THE MISSING LINK (u18 Family A): nothing fired the hm userForward at corpus cells,
#     so `home-manager.users` stayed empty. Ported below.
#
# THE POLICY (v1 semantics, cell-rendered):
#   v1 userDetectFn (home-env.nix): `optionals (isOsSupported && hasClass) [ policy.include (userForward
#   { host; user; }) ]` with `isOsSupported = elem host.class supportedOses` (default
#   `[ "nixos" "darwin" ]`, home-env.nix:14-17 — nix-on-droid's droidHome relies on the standard battery
#   skipping droid hosts) and `hasClass = elem className user.classes`. The userForward (home-env.nix:88-100
#   at the pin; the makeHomeEnv instantiation home-manager.nix:17-24) is a `den.batteries.forward` whose
#   per-item fields evaluate STATIC (forward.nix `forwardItem`: `intoPath = fwd.intoPath item` = the
#   `[ "home-manager" "users" userName ]` list, `userHostPath`, home-manager.nix:12-15; no
#   guard/adaptArgs/adapterModule ⇒ `needsAdapter = false`) — i.e. a TIER-1 static forward: fromClass
#   `homeManager` → intoClass `host.class` at that path. Its SOURCE in v1 is `fromAspect =
#   den.lib.resolveEntity "user" …` (the user's resolved aspect tree); in den-hoag the user cell's
#   `home-manager` class bucket IS that resolved content (attribute 9 at the cell — parity row n's P2
#   asserts the byte-equality of exactly this path), so the collected route AT THE CELL carries the same
#   modules. `userName` read: v1's user entity defaults `userName = config.name` (pin
#   nix/lib/entities/host.nix:156) — `user.userName or user.name` is the faithful fallback.
#
#   PARENT TARGET (#53c, ratified §9 item 3): v1's cell-fired forward content reached the host via the
#   NON-ISOLATED NESTING FOLD; den-hoag isolates every cell as its own edge-root, so the forward sets
#   `appendToParent` (v1's route property, fx/edges/route.nix:364/:370-377) and the #66 terminal law
#   consumes it at the host. The trace-target ceiling (host vs v1's cell) is accepted-and-ledgered (u18).
#
#   PROBE-SAFETY (the os-class posture, os-class.nix:60-71): the emission is UNCONDITIONAL — the gates
#   ride the `intoClass` FIELD (`null` ⇒ the `__dropped` defined no-op, translateDelivery) — because a
#   value-conditional body emits nothing at concern-policies' value-less probe and misclassifies as
#   enrich. At the sentinel: `host.class or null` = null ⇒ isOsSupported false ⇒ intoClass null;
#   `user.userName or user.name` reads the sentinel's `name` — never a missing-attr crash.
#
#   `schemaIncludes = config.den.schema.hm-host.includes or [ ]` (home-manager.nix:23): the corpus only
#   READS hm-host.includes (nix-on-droid.nix:71, `or [ ]`) and never writes it — corpus-zero, not ported
#   (the hm-host KIND registration itself is builtins.nix's, u15).
#
# SEVERABLE (Law C5): applied by flake-module.nix `desugarLegacy` when this battery is in the wiring's
# legacy set; severed ⇒ the identity (no hm forward — home-manager.users stays empty, the honest no-op).
# builtins.nix provisions the SAME record for the bridge path (the user-to-host dual-registration
# pattern); the desugar's `//` overwrite is idempotent → ONE firing.
{
  prelude,
  errors,
  ...
}:
let
  deliverLib = import ../../deliver.nix { inherit prelude errors; };

  supportedOses = [
    "nixos"
    "darwin"
  ]; # v1 makeHomeEnv default (home-env.nix:14-17); droid excluded — nix-on-droid's own gate
in
rec {
  _denCompat.legacy = "battery:home-manager";

  # `homeManager` grounds to the built-in `home-manager` class (v1ClassKeyMap) — nothing to register.
  registersClasses = [ ];

  # The user-scope emitter (v1 userDetectFn ∘ userForward, tier-1-rendered — see header). Exported for
  # builtins.nix (the dual-registration pattern: one definition, both paths).
  hmUserDetect = {
    __denCanTake = "user-host";
    fn =
      { user, host, ... }:
      let
        isOsSupported = builtins.elem (host.class or null) supportedOses;
        hasClass = builtins.elem "homeManager" (user.classes or [ ]);
      in
      [
        (deliverLib.route {
          fromClass = "homeManager";
          # the v1 gates as the intoClass value-gate (probe-safe, the os-class posture): a non-OS host
          # (droid/classless) or a non-hm user (identity-only `classes = [ ]`) ⇒ null ⇒ __dropped.
          intoClass = if isOsSupported && hasClass then host.class else null;
          intoPath = [
            "home-manager"
            "users"
            (user.userName or user.name)
          ];
          __extra.appendToParent = true; # #53c — the cell-fired forward targets the containment parent
        })
      ];
  };

  desugar =
    v1:
    v1
    // {
      policies = (v1.policies or { }) // {
        hm-user-detect = hmUserDetect;
      };
    };
}
