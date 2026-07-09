# den-compat LEGACY battery: `os-class` (R2 + R3, spec §10). Port of den v1
# `modules/aspects/batteries/os-class.nix` at the frozen pin (11866c16).
#
# v1's os-class battery does two things:
#   • registers the `os` CONVENIENCE class (`den.classes.os` — a source class with no terminal of its own,
#     forwarding to the host's real class);
#   • registers the built-in `os-to-host` route policy (`den.policies.os-to-host`, os-class.nix:26-43)
#     and self-appends it to `den.default.includes`, so os content routes to the host's class at EVERY
#     scope where a host is bound (host + user cells), gated on `host ? class && host.class ∈ {nixos,darwin}`
#     (a synthetic `user@host` home has no OS class — its route is inert).
#
# COMPAT MODEL (R2): `os` registers through den-hoag's PUBLIC class registry as a declared `den.classes.os`
# — the general declared-classes surface (assembly spec §2.2; `entity.discoverClasses` seeds the fleet's
# registered-class set = built-ins ∪ declared). den v1's os is a CONVENIENCE forwarding class (no terminal
# — it routes to the host's class); a bare declared class is never any scope's PRODUCING class, so it grows
# no phantom fold edge, while joining BOTH `classifyKey`'s class branch AND ingest's `classRegistry`. So an
# aspect keying `os = {…}` now CLASSIFIES (no core `classNames` edit — the declared-classes feature carries
# it), and `resolveBucket` resolves `os` for the route's `fromClass` (R3). (The earlier "os aspect keys
# need an extraClassNames param" deferral is DONE — closed by the declared-classes surface, a general core
# feature, not a compat hack; it is exercised once the batteries auto-apply on the full fleet, defaults.nix.)
#
# SEVERABLE (Law C5): a pure v1 → v1 desugar applied by flake-module.nix `desugarLegacy` when this battery
# is in the wiring's legacy set. Severed ⇒ the identity; an aspect's `os` key then aborts as an unknown
# key (R9's three-branch dispatch), never a silent drop — the honest no-op for an unregistered class.
{
  prelude,
  errors,
  ...
}:
let
  deliverLib = import ../../deliver.nix { inherit prelude errors; };
in
{
  _denCompat.legacy = "battery:os-class";

  # The class this battery registers (R2). `resolveBucket` reads it for the route's `fromClass`.
  registersClasses = [ "os" ];

  # The pure v1 → v1 desugar: register the `os` class (R2) + add the `os-to-host` route policy (R3).
  desugar =
    v1:
    v1
    // {
      classes = (v1.classes or { }) // {
        # A bare declared class — `os` forwards (no wrap/instantiate/share), so it enters ingest's
        # classRegistry (resolveBucket) without a den-hoag terminal or a producing-class fold.
        os = (v1.classes.os or { }) // {
          description = "Convenience class forwarding to both nixos and darwin (den v1 os-class battery)";
        };
      };
      policies = (v1.policies or { }) // {
        # R3 — os-class.nix:26-43: route os content to the host's class. v1's body is `{ host, ... }:`
        # (host-required, gated by `resolveArgsSatisfied` — a canTake PRESENCE gate). The shim compiles it
        # as a `__denCanTake = "host"` policy (compile.nix): its `{ host, ... }` formals are PRESERVED
        # through compilation, so den-hoag's dispatch (a) fires it only where a host coordinate is in scope
        # (host + user cells) and (b) fills the stratum-classification probe with a sentinel host — so the
        # UNCONDITIONAL route emission classifies as RESOLUTION (a value-CONDITIONAL emission would produce
        # nothing at the value-less probe and misclassify as enrich, then crash on firing).
        #
        # `intoClass = host.class or null` routes to the host's OS class (v1 semantics). The v1 value-gate
        # `host ? class` (INERT for a synthetic `user@host` home, which has no OS class) is preserved as a
        # NULL TARGET: an absent/null host class → `intoClass = null` → a DEFINED NO-OP delivery (dropped at
        # materialization, compile.nix `__dropped`), so a classless host stays INERT (never misroutes to a
        # default) exactly as v1. The other half of v1's gate — `host.class ∈ {nixos,darwin}` — is relaxed
        # to canTake host-presence: the corpus has only nixos/darwin hosts (PIN.md), so a corpus host always
        # routes to its real OS class; a non-{nixos,darwin} registered class would route there too (an
        # accepted relaxation), and an UNREGISTERED target class aborts LOUDLY (never a silent misroute).
        os-to-host = {
          __denCanTake = "host";
          fn =
            { host, ... }:
            [
              (deliverLib.route {
                fromClass = "os";
                intoClass = host.class or null;
                path = [ ];
              })
            ];
        };
      };
    };
}
