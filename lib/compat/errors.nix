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
}
