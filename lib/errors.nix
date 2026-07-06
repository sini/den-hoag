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
}
