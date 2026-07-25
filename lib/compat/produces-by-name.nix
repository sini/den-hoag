# THE CORPUS PRODUCED-KIND MAP (declared-stratum dispatch) — the SINGLE source of the
# `den.producesByName` knob, the `resolveFamilyNames` twin. It names the VALUE-CONDITIONAL corpus
# policies whose declared produced-kind family lets `dispatch.deriveGroup` stamp the rule's `group` at
# DEFINITION time, so concern-policies compiles ONE declared rule per policy instead of the blind
# per-stratum `mkExpanded` fan (the fire-and-observe holdover, retired for these). Consumed by TWO
# callers that must agree:
#   • flake-module.nix `producesModule` — sets `config.den.producesByName`, which default.nix threads to
#     concern-policies; a policy authored DIRECTLY under `den.policies.<name>` matches by attr KEY (the
#     v1 name), so its `name ∈ producesByName` lookup carries the declared kinds.
#   • compile.nix `producesStamp` — a resolve/include policy wired via `den.schema.<kind>.includes`
#     compiles to a SYNTHETIC key (`__kindInclude__<kind>__policy__<i>`), which the name lookup NEVER
#     catches. compile stamps `__produces = producesByName.<name>` on a compiled include policy whose
#     SOURCE REF's v1 name is in this map (the same posture as `resolveFamilyStamp`).
#
# WHY COMPAT OWNS IT. A v1 corpus body is an OPAQUE closure — Nix cannot statically read which
# `declare.*` constructor it calls, and a value-conditional body emits NOTHING at the value-less stratum
# probe, so its produced kinds cannot be DETECTED (the exact precedent of `resolve-family-names.nix`:
# "its value-less stratum probe emits nothing and it cannot be DETECTED"). The compat shim legitimately
# owns v1-corpus FACTS; declaring the produced kinds as DATA eliminates the fire-to-classify. The
# single-group (probe-EMITTING) corpus policies are NOT mapped here — their produced kinds are a FREE
# by-product of the compose-seed probe they already run.
#
# THE FIVE VALUE-CONDITIONAL CORPUS POLICIES (census nix-config @fddab954, modules/den/policies/), each
# SINGLE-stratum (none genuinely spans strata, so each maps to ONE declared rule):
#   • env-to-hosts     (fleet.nix:42)     — resolve.to "host" + instantiate → member + spawn (both structural)
#   • env-to-clusters  (clusters.nix:22)  — resolve.to "cluster"             → member (structural)
#   • env-users        (users.nix:107)    — resolve.to "user"                → member (structural)
#   • cluster-aspect   (clusters.nix:73)  — include                          → edge (resolution)
#   • broadcast-hub-peer (pipes.nix:164)  — pipe (site-mark)                 → pipeOp (collection)
# THE OMISSION FALLBACK: a value-conditional policy NOT mapped here degrades to the proven blind
# `mkExpanded` fan (`produces == null` ⇒ the pre-declared byte-identical behavior), additive and matching
# gen-dispatch's own undeclared-rule design — never a crash.
{
  env-to-hosts = [
    "member"
    "spawn"
  ];
  env-to-clusters = [ "member" ];
  env-users = [ "member" ];
  cluster-aspect = [ "edge" ];
  broadcast-hub-peer = [ "pipeOp" ];
}
