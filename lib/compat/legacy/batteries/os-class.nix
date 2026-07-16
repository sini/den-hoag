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

  # The pure v1 → v1 desugar: register the `os` class (R2). The `os-to-host` route (R3) is no longer a
  # `den.policies` entry — it is EXPORTED as `routeInclude` and folded into `den.aspects.defaults.includes`
  # (legacy/defaults.nix), so it reaches entities through the general kind-include path rather than the
  # bespoke `den.default` radiation.
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
    };

  # R3 — os-class.nix:26-43: route os content to the host's class. The route record is coerced into
  # `den.aspects.defaults.includes` as `{ __isPolicy; name = "os-to-host"; fn }`; `compilePolicy` reads
  # the fn's `{ host, ... }` formals as the gate (host-required — fires at host + user cells). The
  # UNCONDITIONAL route emission classifies as RESOLUTION at concern-policies' value-less probe (the
  # sentinel host has no `class`, so `intoClass` resolves to `null`, but the route record is still emitted).
  #
  # EXACT v1 value-gate (os-class.nix:26-43): v1 is
  #   `lib.optional (host ? class && builtins.elem host.class [ "nixos" "darwin" ]) (route {…})`
  # — a route ONLY for a host whose OS class is nixos or darwin, INERT otherwise. The shim reproduces
  # it PROBE-SAFE by moving the gate from the EMISSION (which must be unconditional — a value-
  # conditional body emits nothing at the value-less stratum probe → misclassifies as enrich → crashes
  # on firing) to the `intoClass` FIELD (classification reads `__action`/stratum, not `intoClass`):
  # the route record is always emitted, but its target is `host.class` iff `host.class ∈ {nixos,darwin}`,
  # else `null`. A `null` intoClass is the value-gate's INERT ARM — a DEFINED NO-OP delivery (dropped at
  # materialization). So a classless/synthetic `user@host` home (no class), a null class, AND a non-OS
  # class (e.g. wsl) are ALL inert, matching v1's elem-gate byte-for-byte — no divergence. (darwin routes
  # once its output class is registered; until then a darwin host aborts LOUDLY at resolveBucket.)
  routeInclude = {
    name = "os-to-host";
    fn =
      { host, ... }:
      [
        (deliverLib.route {
          fromClass = "os";
          intoClass =
            if
              builtins.elem (host.class or null) [
                "nixos"
                "darwin"
              ]
            then
              host.class
            else
              null;
          path = [ ];
        })
      ];
  };
}
