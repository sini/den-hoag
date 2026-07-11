# FLEET-CONTEXT ENRICHMENT (ship-gate rung) — the compat twin of den v1's fleet.nix scope-inheritance
# fan-out (nix-config modules/den/policies/fleet.nix:20-82 @ pin 11866c16).
#
# THE LAW. v1 binds `environment`/`secretsConfig`/`fleet`/`accessGroups` into every host scope's ctx by
# SCOPE INHERITANCE: `to-fleet` (fleet.nix:20-29) resolves the fleet entity `{ name = "fleet"; }` +
# `secretsConfig` at flake scope, inherited fleet-wide; `env-to-hosts` (:42-77) resolves each host UNDER
# its environment binding `{ environment = env; }` (:70-72 `resolve.to "host" { host = hostCfg; }`), so a
# host inherits its environment ENTITY. den-hoag compat NEVER runs that fan-out: `den.lib.policy.resolve`
# is STUBBED (R8; flake.nix:159, board #49/#50), hosts are compat-membership ROOTS, and the SCOPE-LOCAL
# FIRING rung (board #57, ledger u3) confines each fan-out policy to its OWNER-KIND scope:
#   - `to-fleet`/`fleet-to-envs` (flake/fleet includes) are `{ self, … }`-gated on a coord the fan-out
#     never binds, so they stay lazily inert regardless;
#   - `env-to-hosts`/`env-to-clusters` (environment includes) are `{ environment, … }`-gated, and THIS
#     module's enrich SATISFIES that gate — but they fire via their `__kindInclude__environment__policy`
#     arm ONLY (their fleet-wide global is REMOVED, `includeReferencedNames`), and `__firesAtKinds =
#     [ "environment" ]` confines that arm to environment-KIND nodes, which do NOT exist in compat (no
#     env→host containment; the env-scope fan-out is the stubbed surface). So the `resolve` stub is NEVER
#     forced — the pre-#57 over-fire (the enriched `{ environment }` gate matching HOST nodes) is closed.
# A host node's enriched-context then carried only `{ __entry, host }`,
# leaving every corpus consumer of these ctx keys DEAD:
#   - the ~40 `{ environment, ... }` channel/module sites (the k3s frontier — k3s.nix:49's
#     `{ environment, host, ... }` emit rode raw on the missing `environment` arg, U9.1's resolveParametric
#     correctly riding it raw; ledger u9);
#   - the agenixHostAspect (`{ host, secretsConfig, ... }`, batteries/agenix.nix:23 — presence-gated,
#     silently inert without the binding).
#
# This module BINDS that ctx surface compat-side, as ENRICH (den-hoag's cross-enrichment fixpoint,
# structural.nix attr 2) rather than v1's scope-inheritance (which needs the stubbed fan-out). The policy
# is `{ host, ... }`-gated, so it fires wherever the host coord is bound — host ROOTS and user CELLS both
# (the user cell inherits `host` from its host parent, structural.nix attr 1) — matching v1's inheritance
# reach. Each firing emits THREE `declare.enrich` declarations. The single-writer guard
# (structural.nix:108-118) protects the keys: ONLY this policy writes them (the corpus fleet.nix fan-out
# that would ALSO bind them stays inert, no collision).
#
# PROBE EDGE (constraint, documented). The emission is UNCONDITIONAL, so concern-policies' value-less
# stratum probe EMITS (a single-group `__isEnrich` rule; the probe rides the sentinel host's DEFAULT env
# `"prod"` — the sentinel carries no `environment` field, so the `or "prod"` default applies — which the
# corpus registry carries). A fleet whose defaulted env is ABSENT from the registry would have the NAMED
# abort below tryEval-caught at the probe → the value-conditional EXPANSION path → `errors.expansionEnrich`
# (an enrich decl cannot ride expansion) — loud but MISDIRECTED (it points at the expansion guard, not the
# missing-env cause). ACCEPTABLE: still loud + self-announcing, and the corpus's default env is always
# registered.
#
# `accessGroups` is NOT bound here — v1's `env-to-hosts` computes it (fleet.nix:63-67) only for
# `resolve.to "host"`, and its lone reader is the resolved-user emitter (users.nix:109), both #49-gated;
# deferred to board #49 (ledger row `accessGroups`).
{
  declare,
}:
{
  # `mkEnrichPolicy { envs; secretsConfig }` — the `{ host, ... }`-gated enrich policy. `envs` is the
  # bridge-ingested `config.den.environments` registry; `secretsConfig` the bridge-ingested
  # `config.den.secretsConfig` (a declared non-kind namespace, `den._declaredKeys`, compile.nix ~:1142).
  mkEnrichPolicy =
    {
      envs,
      secretsConfig,
    }:
    { host, ... }:
    let
      # `host.environment` (the harvest-stamped host field, ingest `harvestedHostFields`) defaulting to
      # v1's schema default `"prod"` (nix-config schema/host.nix:174-178; pin 11866c16 host.nix).
      envName = host.environment or "prod";
      env =
        if envs ? ${envName} then
          envs.${envName}
        else
          # NAMED abort (never a bare `envs.${envName}` attr access): a missing registry entry names the
          # host, the env name, and the available env names. See the module header's PROBE EDGE note for
          # the one misdirected case (a fleet whose DEFAULTED env is absent → tryEval'd at the probe).
          throw
            "den-compat fleet-context enrichment: host `${host.name or "<unnamed>"}` selects environment `${envName}` (its `host.environment` field, defaulting to \"prod\" per the v1 host schema), which is not in the environments registry — available: [${builtins.concatStringsSep ", " (builtins.attrNames envs)}]. Declare `den.environments.${envName}` or fix the host's `environment` field.";
    in
    [
      # environment — v1 `env-to-hosts` binds the env ENTITY per host (fleet.nix:70-72, under the env-scope
      # `{ environment = env; }`); here the direct entity lookup off the bridge-ingested registry.
      (declare.enrich {
        key = "environment";
        value = env;
      })
      # secretsConfig — v1 `to-fleet` binds it at flake scope, inherited fleet-wide (fleet.nix:27
      # `inherit (config.den) secretsConfig`).
      (declare.enrich {
        key = "secretsConfig";
        value = secretsConfig;
      })
      # fleet — v1 `to-fleet` binds `{ name = "fleet"; }` at flake scope (fleet.nix:24-26), inherited
      # fleet-wide. ZERO corpus consumers (lead-censused), but bound for the exact v1 ctx surface.
      (declare.enrich {
        key = "fleet";
        value = {
          name = "fleet";
        };
      })
    ];
}
