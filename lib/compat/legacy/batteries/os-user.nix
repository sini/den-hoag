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

  # R6 — os-user.nix `user-to-host`: route user content to the host's OS `users.users.<name>`,
  # injecting `osConfig = config` (the adapter-bearing route). v1's `{ user, host, ... }:` is a
  # presence gate on BOTH user AND host; the route record is coerced into `den.aspects.defaults.includes`
  # as `{ __isPolicy; name = "user-to-host"; fn }`, and `compilePolicy` reads the fn's `{ user, host, ... }`
  # formals as the gate (den-hoag fires it only at a user cell — both coordinates present). The
  # UNCONDITIONAL route emission classifies as RESOLUTION at the value-less probe. `user.name` = v1's
  # `user.userName` (den-hoag ctx canonicalizes to `.name`).
  #
  # NB: UNLIKE os-class's os-to-host, v1's user-to-host is UNCONDITIONAL — `intoClass = host.class`
  # with NO `elem host.class [nixos darwin]` gate (verified against the frozen pin) — so a user
  # routes to its host's REAL OS class whatever it is (a `wsl` host's user routes to wsl). The shim
  # therefore does NOT add the elem-gate here; `intoClass = host.class or null` only guards the ONE
  # case v1 leaves undefined: a synthetic `user@host` home has NO host OS class, so the null target
  # renders a DEFINED NO-OP (dropped) — INERT (there is no OS to route into), never a crash.
  #
  # Bound in the let (a cleaner desugar body). The eval-time provisioning of `den.policies.user-to-host`
  # (builtins.nix) reconstructs this SAME route value-identically off the shared `deliver.nix` surface —
  # NOT by importing this legacy battery (the single-legacy-import-site invariant, compat-legacy-severed).
  # Because the coerced include carries `.name = "user-to-host"`, `includeReferencedNames` REMOVES that
  # ambient global from the fleet-wide firing set → the route fires ONCE, via the include arm.
  userToHost = {
    name = "user-to-host";
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
    };

  routeInclude = userToHost;
}
