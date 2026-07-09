# den-compat LEGACY battery: `os-user` (R2 + R6, spec §10). Port of den v1
# `modules/aspects/batteries/os-user.nix` at the frozen pin (11866c16).
#
# v1's os-user battery registers the `user` CONVENIENCE class (a lightweight OS-user environment) and the
# built-in `user-to-host` route: user-class content routes to the host's OS `users.users.<name>`, with
# `adaptArgs` injecting `osConfig` so user modules reach the parent NixOS/Darwin config
# (os-user.nix `user-to-host`). Like `os`, `user` is a source class with no terminal — it forwards.
#
# COMPAT MODEL: same as os-class (R2) — `user` registers through the public class registry as a declared
# `den.classes.user`, disjoint from the `user` entity KIND (different namespaces: `den.classes.user` the
# class vs `den.schema.user` / `den.user.*` the kind + instances). A bare declared class enters ingest's
# classRegistry so `resolveBucket` resolves `user` for the route's `fromClass`, with no terminal and no
# fold (user is never a producing class — hosts produce nixos, user cells produce home-manager). The route
# is ADAPTER-BEARING (`adaptArgs osConfig`), so — per the forward-tier ruling (PIN.md §Forward-tier) — it
# is a `policy.route` with an adapt annotation on a COLLECTED edge (NOT a synthesize forward); the shim
# compiles it through the deliver surface (Task 2).
#
# SEVERABLE (Law C5): a pure v1 → v1 desugar in the wiring's legacy set; severed ⇒ the identity (an aspect
# `user` key then aborts as unknown, R9 — the honest no-op).
{
  prelude,
  errors,
  ...
}:
let
  deliverLib = import ../../deliver.nix { inherit prelude errors; };
in
{
  _denCompat.legacy = "battery:os-user";

  registersClasses = [ "user" ];

  desugar =
    v1:
    v1
    // {
      classes = (v1.classes or { }) // {
        user = (v1.classes.user or { }) // {
          description = "Lightweight user environment forwarding to OS users.users (den v1 os-user battery)";
        };
      };
      policies = (v1.policies or { }) // {
        # R6 — os-user.nix `user-to-host`: route user content to the host's OS `users.users.<name>`,
        # injecting `osConfig = config` (the adapter-bearing route). v1's `{ user, host, ... }:` is a
        # canTake presence gate on BOTH user AND host, compiled here as `__denCanTake = "user-host"`
        # (compile.nix preserves the `{ user, host, ... }` formals): den-hoag fires it only at a user cell
        # (both coordinates present), and the stratum probe's sentinel user+host make the UNCONDITIONAL
        # route classify as RESOLUTION. `user.name` = v1's `user.userName` (den-hoag ctx canonicalizes to
        # `.name`); `intoClass = host.class` (the corpus's nixos/darwin, `or "nixos"` at the probe).
        user-to-host = {
          __denCanTake = "user-host";
          fn =
            { user, host, ... }:
            [
              (deliverLib.route {
                fromClass = "user";
                intoClass = host.class or "nixos";
                path = [
                  "users"
                  "users"
                  user.name
                ];
                adaptArgs = args: args // { osConfig = args.config; };
              })
            ];
        };
      };
    };
}
