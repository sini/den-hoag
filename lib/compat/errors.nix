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

  # A `provides.<key> = <value>` whose value is neither an aspect attrset nor a parametric aspect
  # function (a scalar/string) — it cannot become deliverable content. Named at definition (legacy
  # provides desugar, C4) rather than surfacing as a deep aspect-merge failure.
  provideValueShape =
    got:
    fail "legacy provides (C4)" "a `provides.<key>` value must be an aspect (attrset or parametric function), got ${builtins.typeOf got}";
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

  # A v1 `policy.exclude` whose target is a POLICY (a `__denCanTake`/`__isPolicy`/function record) rather
  # than an aspect. Suppressing a POLICY's firing at a scope (the corpus's droid `drop-user-to-host-on-droid`
  # excludes the os-user `user-to-host` route) is a distinct mechanism from pruning an aspect edge — it is
  # the droid arm's user-route exclude, DEFERRED to class-B / board #50 (the nixOnDroid class). The class-A
  # `nixosConfigurations` arm never reaches it (the exclude is `host.class == "droid"`-gated). Named here so
  # the droid arm greets a self-announcing rung, never a misleading identity-law abort.
  excludeOfPolicy = fail "exclude-of-policy (class-B, board #50)" "`policy.exclude` targets a POLICY record (`__denCanTake`/`__isPolicy`/function), not an aspect; suppressing a policy's firing is the droid arm's user-route exclude, not yet available (class-B / board #50)";

  # INLINE-ASPECT kind-include guards (ship-gate, home-env battery). An inline aspect in a
  # `den.schema.<kind>.includes` list (v1's `{ policies; includes }` battery shape, nix/lib/home-env.nix
  # makeHomeEnv) is EXPANDED by `kindIncludePolicies`: its `.includes` are HOISTED into the kind's ref list
  # (each classified normally) and its `.policies` is DROPPED as a verified duplicate. Two loud guards keep
  # the drop honest (the silent-partition ban applies to the drop, not just to per-declaration strata):
  #
  #   (A) VERIFIED-DUPLICATE — every `.policies.<name>` must be NAME-MATCHED by a `.includes` `__isPolicy`
  #       record (fn-equality is unassertable; name-match is the check). The corpus battery mirrors the same
  #       name both sides (v1's name-keyed registration is why its effective firing is ONE); an inline aspect
  #       whose `.policies` carries a NON-mirrored policy aborts here rather than losing it silently.
  inlineAspectPolicyUnmatched =
    name:
    fail "inline-aspect kind-include" "inline-aspect `.policies.${name}` has no matching `.includes` `__isPolicy` record — refusing to DROP a policy silently (the hoist keeps `.includes` and drops `.policies` ONLY as a verified duplicate; a non-mirrored `.policies` entry would be lost). Mirror it into `.includes` as `{ __isPolicy = true; name = \"${name}\"; fn; }`, or register it as a `den.policies.<name>`";
  #   (B) UNKNOWN-KEY — the shim expands ONLY the `{ policies; includes }` battery shape; any other key on an
  #       inline aspect (class content) is not hoisted. Named abort listing the keys rather than a silent drop.
  inlineAspectUnknownKeys =
    keys:
    fail "inline-aspect kind-include (C1)" "an inline aspect in a `den.schema.<kind>.includes` list carries key(s) beyond {includes, policies}: [${builtins.concatStringsSep ", " keys}] — the shim expands only the v1 `{ policies; includes }` battery shape (nix/lib/home-env.nix); class-content on an inline include is not hoisted. Register it as a named `den.aspects.<name>` and include it by reference (`{ name = \"<name>\"; }`)";

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

  # SURFACE TOTALITY (C1) — a top-level `den.<key>` the shim does not recognise. The permissive v1 eval
  # (flake-module.nix `v1OptionsModule` freeformType) ABSORBS unknown `den.*` keys silently so an arbitrary
  # corpus module evaluates; that absorption's promised downstream enforcement is HERE, over the read-back
  # config. A typo'd or unknown surface key is rejected with a name — never silently dropped (the C1
  # freeform-absorption trade-off). Names the offending key + the surface the shim compiles.
  unknownSurfaceKey =
    key:
    fail "surface totality (C1)" "unknown `den.${key}` — the shim compiles { hosts, homes, schema, aspects, policies, classes, include, quirks, contentClass, default, <declared custom kinds> }; a typo'd or unknown `den.*` key is absorbed by the permissive v1 eval and rejected HERE, never silently dropped. Fix the key or extend the surface";

  # NOT-IMPLEMENTED-BY-CENSUS (C1 surface totality) — an aspect carrying `meta.__forward`, the manifestation
  # of `den.batteries.forward` (v1 `nix/lib/forward.nix` `forwardItem`). The shim does NOT implement the
  # forward-battery NTA path: the corpus census found ZERO consumers (PIN.md Open-Question-2, Tier-2
  # derived-children NTA deliberately unbuilt). Rather than pass `meta.__forward` through as opaque aspect
  # content (silently wrong), the surface aborts named, with a migration pointer. Witness-mapped as
  # not-implemented-by-census (parity/fixtures/witness-map.nix `batteriesForward`).
  batteriesForwardUnsupported =
    aspect:
    fail "batteries.forward (not implemented — corpus-zero census)" "aspect `${aspect}` carries `meta.__forward` (a `den.batteries.forward` manifestation); the shim does not implement the forward-battery NTA path — PIN.md Open-Question-2 records zero corpus consumers. Migrate the forward to a native den-hoag class + `deliver` (the tier-1 path legacy/forwards.nix takes), or, if a corpus consumer appears, build the Tier-2 derived-children NTA in legacy/forwards.nix and re-open Open Question 2";
}
