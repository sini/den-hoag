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
  # THE ROUTE BUILT-INS. Each is a v1 flake-output / delivery route whose body deliberately THROWS when
  # fired at a value-less sentinel — `outputStub`'s informative class-F/G refusal, and the route arms'
  # identity-law aborts on a fabricated target. At HEAD the kernel probe caught those throws and filed the
  # policy as "emits nothing", which is a message written to be READ being used as a classification signal
  # and discarded. Declared here, the shim never fires them: the codomain is a fact about the body, and
  # the body is a delivery route.
  user-to-host = [ "delivery" ];
  route-custom-toplevel = [ "delivery" ];
  route-guarded-false = [ "delivery" ];
  route-phantom = [ "delivery" ];
  route-src-subpath = [ "delivery" ];
  # DEN-COMPAT'S OWN THROWING BUILT-INS (builtins.nix `outputStub` and the home-env forwards), listed here
  # rather than on the value because the surrounding entries are the same KIND of fact: which declaration
  # kinds a policy can produce, for a body that cannot be asked. `outputStub` is a deliberate, informative
  # refusal — a v1 flake-OUTPUT policy is ship-gate class F/G, not the class-A arm — and it throws at ANY
  # context, sentinel or real. Declaring `delivery` (the kind it would produce) keeps the rule ALIVE and
  # gated on its `system` coord, so the refusal still fires LOUDLY where a flake-system node binds one.
  # `emits = [ ]` would be the wrong answer: it compiles to NO rule, replacing a designed refusal with
  # silence.
  system-to-os-outputs = [ "delivery" ];
  system-to-hm-outputs = [ "delivery" ];
  system-to-flake-parts = [ "delivery" ];
  systemToFlakeParts = [ "delivery" ];
  devshell-to-flake-parts = [ "delivery" ];
  homeLinux-to-hm = [ "delivery" ];
  # Its DARWIN twin, identical in shape (`home-platform.nix` — both are `lib.optional (hasSuffix …
  # host.system) (route {…})`). Both are VALUE-conditional on `host.system`, so both emit nothing at a
  # sentinel whose system matches neither suffix: undeclared, the codomain recovers EMPTY and the policy
  # compiles to no rule at all. Declaring the linux arm without the darwin one left the corpus's darwin
  # hosts silently unrouted.
  homeDarwin-to-hm = [ "delivery" ];
  # ★ A LIVE CORPUS DROP, closed. `nixpkgs-overlays.nix:20` is VALUE-conditional on
  # `host.settings.core.users.home-manager-shared.useGlobalPkgs`, which is false at a sentinel built from
  # the settings tree's own defaults — so its codomain recovered EMPTY and the policy compiled to no rule
  # at all, silently. It is selected (`den.schema.user.includes`), so only the codomain was missing.
  # MEASURED before declaring: its emission is a `pipe.expose` on a bare channel, which is SITE-MARK data
  # (`declare.isSiteMarkData`) — so the rule fires, passes `conformingProduce`'s pipeOp arm, and makes no
  # compose commitment. Declaring it therefore does not touch the unbuilt `ops` seam.
  project-user-overlays = [ "pipeOp" ];
  hm-forward = [ "delivery" ];
  hmForward = [ "delivery" ];
}
