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
# COMPAT MODEL (R2, no-core-edit): `os` registers through den-hoag's public class registry as a declared
# `den.classes.os`. den v1's os is a CONVENIENCE forwarding class (no terminal — it routes to the host's
# class), so a bare declared class (accepted, but not in core's `classNames`, so den-hoag grows no phantom
# `collect` terminal for it and — since it is never any scope's PRODUCING class — no phantom fold edge) is
# the faithful, no-core-edit model: it enters ingest's `classRegistry`, so `resolveBucket` (classes ∪
# channels) resolves `os` for the route's `fromClass` (R3). (A RESOLVED aspect literally keying `os = {…}`
# additionally needs `os ∈ classNames` for `classifyKey` — the general `extraClassNames` param. This is a
# MANDATORY C8 pre-item — corpus os-keyed aspects are certain (owner ruling, spec §10 R2); a
# declared-classes surface feeding the three-branch dispatch is required before the full-corpus run. No
# synthetic convergence fixture resolves an os-keyed aspect, so it is not built here.)
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
        # R3 — os-class.nix:26-43: route os content to the host's class, gated on a REAL host OS class.
        # v1's body is `{ host, ... }:` (host-required, gated by resolveArgsSatisfied). The compat
        # compilePolicy wrapper is a BARE `ctx:` (it erases formals — compile.nix caveat), so den-hoag
        # dispatch runs this at EVERY scope; the body therefore checks `ctx ? host` ITSELF (the same
        # host-presence gate v1's formals encode) and reads `host.class` only when present. A scope with
        # no host, or a synthetic `user@host` identity with no class, yields `[ ]` — inert, exactly as v1.
        os-to-host =
          ctx:
          let
            host = ctx.host or null;
          in
          prelude.optional
            (
              host != null
              && host ? class
              && builtins.elem host.class [
                "nixos"
                "darwin"
              ]
            )
            (
              deliverLib.route {
                fromClass = "os";
                intoClass = host.class;
                path = [ ];
              }
            );
      };
    };
}
