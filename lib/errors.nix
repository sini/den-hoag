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
  # nodes. A `member` declaration dispatched at a membership-derived node (a fleet cell, or
  # any node beneath one) aborts, naming the policy and the scope. The membership-
  # derived classification is the caller's (Task 3 declaration-stratum classifier); this
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

  # B2 stratum coherence: a policy whose declarations do not all classify to one STRATUM
  # aborts. Each declaration's stratum is derived from its KIND via the vocabulary's
  # kind->stratum map (Task 2: enrich -> structural is the whole map; Task 3 extends it), so
  # the abort names both offending kinds AND their strata. Wired at the declaration classifier
  # (Task 3); Task 2 provides the builder.
  mixedStratum =
    policyName: kindA: stratumA: kindB: stratumB:
    fail "declaration stratum (B2)" "policy `${policyName}` produced declarations of kind `${kindA}` (stratum `${stratumA}`) and kind `${kindB}` (stratum `${stratumB}`); a policy's declarations must all classify to a single stratum";

  # §2.2 aspect-key dispatch: an aspect key that is neither a declared facet, a registered
  # class, nor a registered quirk channel is a definition-time error, naming the aspect + key.
  unknownAspectKey =
    aspectName: key:
    fail "aspect key (§2.2)" "aspect `${aspectName}` declares key `${key}`, which is neither a facet, a registered class, nor a quirk channel";
}
