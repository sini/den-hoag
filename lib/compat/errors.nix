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
    fail "schema" "kind `${kind}` names parent `${parent}`, which is not a declared kind (known kinds are `den.schema.<kind>` + the built-in `host`/`user`)";

  # A v1 `pipe.from` names a stage the shim does not compile: it handles the §2.4 stage vocabulary
  # (filter/transform/fold/for + to/as + append/expose/broadcast/collect/collectAll/withProvenance).
  # Anything else names itself here rather than compiling to a silent no-op (pipe.nix `stageOp`).
  unknownPipeStage =
    kind:
    fail "pipe stage (C3)" "unknown v1 pipe stage `${kind}` — the shim compiles §2.4 (filter/transform/fold/for, to/as, append/expose/broadcast/collect/collectAll/withProvenance)";

  # A name declared as BOTH a class (`den.classes.<name>`) and a quirk channel (`den.quirks.<name>`):
  # den-hoag's `resolveBucket` unions classes ∪ channels, so an overlapping name is ambiguous at
  # dispatch. Named at definition time — the key-overlap check §2.4 preserves from v1.
  quirkClassOverlap =
    name:
    fail "quirks (C3)" "`${name}` is declared as both a class and a quirk channel — a name is one or the other (classes ∪ channels must stay disjoint); rename one";

  # A v1 policy effect the shim does not compile: it handles the structural/resolution vocabulary —
  # include/exclude/resolve and the for/when combinators; deliver/route/provide and pipe land with their
  # own passes (named above). Anything else names itself here rather than being mis-routed.
  unsupportedEffect =
    effect:
    fail "policy effect" "unsupported v1 policy effect `${effect}` — the shim compiles include/exclude/resolve and for/when; deliver/route/provide and pipe land with their own passes";
}
