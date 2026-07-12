# THE CORPUS RESOLVE-FAMILY TAG SET (user-delivery R2 REQUIREMENT 2) — the SINGLE source of the
# `den.resolveFamilyNames` knob, consumed by TWO callers that must agree:
#   • flake-module.nix `resolveFamilyModule` — sets `config.den.resolveFamilyNames`, which default.nix
#     threads to concern-policies (`v.__resolveFamily` OR `name ∈ resolveFamilyNames`). Catches a
#     resolve policy authored DIRECTLY under `den.policies.<name>` (the KEY is the v1 name → matches here).
#   • compile.nix `kindInclude`/`defaultInclude` policy arms — a resolve policy wired via
#     `den.schema.<kind>.includes` compiles to a SYNTHETIC key (`__kindInclude__<kind>__policy__<i>`), so
#     concern-policies' `name ∈ resolveFamilyNames` NEVER matches it. compile therefore stamps
#     `__resolveFamily = true` on a compiled include-policy whose SOURCE REF's v1 `name` ∈ this set (match
#     at the coerced `{ __isPolicy; name; fn }` ref, not the synthetic attr name), so concern-policies'
#     `v.__resolveFamily` detection catches it. All five corpus resolve policies ride kind-includes, so
#     WITHOUT this stamp the pre-pass feed is empty and the corpus resolve chain never fires.
#
# A v1 corpus authors `resolve.to` policies with NO den-hoag `__resolveFamily` tag on the value, and every
# corpus resolve policy is VALUE-CONDITIONAL (it emits member/relate only once a ctx value — accessGroups,
# an env/host match — is present), so its value-less stratum probe emits nothing and it cannot be DETECTED.
# The shim therefore DECLARES the tag here, naming the corpus's resolve-emitting policies (census
# nix-config @ b0b20769, modules/den/policies/):
#   • env-users       (users.nix:107)     — resolve.to "user"        → member (host→users)
#   • env-to-hosts    (fleet.nix:42)      — resolve.to "host"        → relate (env→host, carries accessGroups)
#   • env-to-clusters (clusters.nix:22)   — resolve.to "cluster"     → member (env→cluster)
#   • to-fleet        (fleet.nix:23)      — resolve.to "fleet"       → relate (flake→fleet)
#   • fleet-to-envs   (fleet.nix:36)      — resolve.to "environment" → relate (fleet→env)
# These live COMPAT-side (the field/name is a v1-CORPUS FACT, not field-agnostic core). THE OMISSION CATCH:
# a resolve-emitting policy omitted here that fires member/relate at a root aborts LOUD (the R2
# `resolveFamilyUntagged` guard), so a forgotten name self-announces rather than silently dropping.
[
  "env-users"
  "env-to-hosts"
  "env-to-clusters"
  "to-fleet"
  "fleet-to-envs"
]
