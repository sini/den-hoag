# Named definition-time errors — pure message builders. Tasks 1–11 extend this set.
# nixpkgs-lib-free: plain `throw`, no prelude needed (add it back only if a future
# builder genuinely uses a prelude helper).
let
  fail = ctx: msg: throw "den-hoag: ${ctx}: ${msg}";
in
{
  identityLaw =
    api: got:
    fail "identity law (A2)" "${api} takes a registry entry (carrying id_hash), got ${builtins.typeOf got}${
      if builtins.isString got then " \"${got}\" — pass the entry, not a \"kind:name\" string" else ""
    }";

  # A5 emission discipline: `member` is accepted only at membership-independent scope
  # nodes. A `member` effect dispatched at a membership-derived node (a fleet cell, or
  # any node beneath one) aborts, naming the policy and the scope. The membership-
  # derived classification is the caller's (Task 3 effect-phase classifier); this
  # builder is the abort it raises.
  memberAtCell =
    policyName: scopeId:
    fail "member discipline (A5)" "policy `${policyName}` emitted `member` at membership-derived scope `${scopeId}`; member is accepted only at membership-independent nodes";

  # B1 single-writer enrichment (A3): two enrich policies writing one context key abort at
  # definition time, naming both policies + the key. Fires on a same-pass collision AND a
  # cross-iteration one (the check runs over the converged enrich accumulation).
  singleWriter =
    key: ownerA: ownerB:
    fail "single-writer enrichment (B1)" "enrich key `${key}` is written by two policies (`${ownerA}` and `${ownerB}`); a key may be enriched by exactly one policy";

  # B2 effect-phase coherence: a policy whose effects do not all classify to one phase aborts,
  # naming the policy and both phases (the effect constructors that produced them). Wired at
  # the effect classifier (Task 3); Task 2 provides the builder.
  mixedPhase =
    policyName: phaseA: phaseB:
    fail "effect phase (B2)" "policy `${policyName}` produced effects in two phases (`${phaseA}` and `${phaseB}`); a policy's effects must all classify to a single phase";
}
