# THE CORPUS RESOLVE-FAMILY TAG SET (user-delivery R2 REQUIREMENT 2) — the SINGLE source of the
# `den.resolveFamilyNames` knob. default.nix threads it into compile.nix (`compileBaseArgs`), where
# `declaredEmitsOf` folds membership in this set into the compiled policy's DECLARED codomain: a name
# listed here contributes `"member"` to that policy's `emits`. The match is on the SOURCE REF's v1 `name`,
# never on the compiled attr key — a resolve policy wired via `den.schema.<kind>.includes` compiles to a
# SYNTHETIC key (`__kindInclude__<kind>__policy__<i>`) that no name-keyed lookup could match, and all five
# corpus resolve policies ride kind-includes. The staged pre-pass's resolve-family feed is then a
# set-membership test on the compiled rule's `produces` (concern-policies `resolveFamily`), so a name here
# reaches the feed BY DERIVATION from its codomain rather than through a tag riding the value.
#
# A v1 corpus authors `resolve.to` policies with NO den-hoag codomain declaration, and every corpus
# resolve policy is VALUE-CONDITIONAL (it emits a `member` only once a ctx value — accessGroups,
# an env/host match — is present), so the sentinel fire that RECOVERS an undeclared codomain takes the
# false branch and recovers `[ ]`: the fact is unlearnable by firing. The shim therefore DECLARES it
# here, naming the corpus's resolve-emitting policies (§3c-UNIFIED —
# every one compiles to a `member`, `relate` dissolved: a registry-LESS cell target → a bare cell tuple; a
# registry-BACKED root target → a `containTo` CONTAINMENT tuple carrying bindings + a containment ancestor)
# (census MEASURED at nix-config b0b20769, modules/den/policies/ — a historical measurement, not a claim
# about the corpus pin the fleet currently tracks):
#   • env-users       (users.nix:107)     — resolve.to "user"        → CELL member (host→user cell)
#   • env-to-hosts    (fleet.nix:42)      — resolve.to "host"        → CONTAINMENT member (env→host, accessGroups)
#   • env-to-clusters (clusters.nix:22)   — resolve.to "cluster"     → CONTAINMENT member (env→cluster; NO cross-join)
#   • to-fleet        (fleet.nix:23)      — resolve.to "fleet"       → CONTAINMENT member (flake→fleet)
#   • fleet-to-envs   (fleet.nix:36)      — resolve.to "environment" → CONTAINMENT member (fleet→env)
# These live COMPAT-side (the field/name is a v1-CORPUS FACT, not field-agnostic core). THE OMISSION CATCH
# is the CODOMAIN CONTRACT, checked at every firing rather than a tag guard checked once: a resolve-emitting
# policy omitted here recovers `emits = [ ]`, so the `member` it goes on to emit is outside its declared
# codomain and `conformingProduce` aborts NAMED at the emitting site (`errors.emitsUndeclared`); a policy
# that declares `member` but under-declares the binding keys it carries takes the same abort one level
# finer (`errors.bindsUndeclared`).
[
  "env-users"
  "env-to-hosts"
  "env-to-clusters"
  "to-fleet"
  "fleet-to-envs"
  # #73: the home-env battery's HOST-fired emitter (v1 nix/lib/home-env.nix `policies."host-to-${ctxName}-
  # users"`; the corpus's droidHome instantiation, nix-on-droid.nix:61 `ctxName = "droidHm"`, registered
  # via `den.schema.host.includes = [ droidHome.battery ]` :175) — emits `resolve.withIncludes { user }`
  # at droid hosts (live once #71 materialized `host.users` classes). Kind-include-wired ⇒ the compile
  # stamp is its only feed path (the synthetic-key posture above).
  "host-to-droidHm-users"
]
