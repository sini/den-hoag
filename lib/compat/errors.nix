# den-compat named definition-time errors — pure message builders, nixpkgs-lib-free (grows every
# task). Every compile-time failure the shim raises names its concern (C-law) and the surface at
# fault, so a v1 declaration that cannot compile fails at DEFINITION with a legible message rather
# than deep in a later evaluation. No `lib`, only `throw` + string interpolation (Law: nixpkgs-lib-free).
# `prelude` reserved — the compile/error surface grows across Tasks 1–9.
{ prelude }:
let
  fail = ctx: msg: throw "den-compat: ${ctx}: ${msg}";
in
{
  unknownClass =
    policy: name:
    fail "deliver (C6)" "policy `${policy}` names unknown class `${name}` — classes are named channels; register it or fix the name";
  deliverMode = got: fail "deliver (C3)" "invalid mode `${got}` (merge | nest | verbatim)";
  deliverVerbatimModule = fail "deliver (C3)" "mode = \"verbatim\" applies to collected class sources only, not a module source";
  routePathConflict = fail "route (C3)" "`intoPath` and `path` are both present — supply exactly one";
  legacyProvidesAbsent =
    aspect:
    fail "legacy provides (C5)" "aspect `${aspect}` uses legacy `provides` — import denCompat.legacy.provides";
  legacyForwardsAbsent =
    what:
    fail "legacy forwards (C5)" "`${what}` uses legacy `forwards` — import denCompat.legacy.forwards";

  # C6 identity law AT THE INGESTION BOUNDARY — the one place v1 name-strings convert to registry
  # entries, exactly once. A value that should already be an entry (host/user/aspect/class position)
  # is still a bare string (or otherwise lacks `id_hash`) when it crosses `compile`'s output. Names the
  # position and what was found. This is the shim-side twin of den-hoag's A2 `identityLaw` (which
  # guards the declaration constructors); the shim fails EARLIER, at the boundary the string outran.
  identityLaw =
    position: got:
    fail "identity boundary (C6)" "value at `${position}` crossed the compile boundary without an `id_hash` (got ${builtins.typeOf got}${
      if builtins.isString got then " \"${got}\" — pass the entry, not a \"kind:name\" string" else ""
    }); v1 name-strings become registry entries at ingestion, exactly once";

  # A v1 `den.schema.<kind>` names a `parent` kind that no other kind declares — the containment DAG is
  # broken at ingestion. Named at definition time so a schema typo fails legibly, not deep in the fleet
  # product. (den-hoag's built-in `host`/`user` are always present.)
  unknownParentKind =
    kind: parent:
    fail "schema (C1)" "kind `${kind}` names parent `${parent}`, which is not a declared kind (known kinds are `den.schema.<kind>` + the built-in `host`/`user`)";

  # deliver / route / provide are the DELIVERY-edge vocabulary — compiled in C3 (Task 2), not the C1
  # structural/resolution core. A policy that emits one before Task 2 lands hits this named seam rather
  # than a silent drop or an opaque failure. Removed when `compile` learns delivery (deliver.nix).
  deliverInTaskTwo =
    effect:
    fail "deliver family (C3)" "`${effect}` is delivery-edge vocabulary compiled in C3 (Task 2 — deliver.nix); the C1 core handles the structural/resolution vocabulary (include/exclude/resolve/for/when) only";
}
