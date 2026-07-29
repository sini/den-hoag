# THE RECOVERY DESUGAR — the only surviving probe, and it is not authoritative.
#
# A v1 `den.policies.<name> = ctx: [ effects ]` value carries no declaration codomain, so the shim must
# RECOVER one before the kernel will schedule it. That is the shim's defined job: a compat layer is a
# total function from an under-specified surface to a fully-specified one, and the recovery's failure
# modes are the SHIM's to carry, never the kernel's. Three properties distinguish it from the kernel
# probe it replaces:
#
#   (1) NON-AUTHORITATIVE. Its output is a DECLARATION the kernel then checks at every firing
#       (`conformingProduce`), so a wrong recovery is caught LOUD instead of silently mis-routing a rule.
#   (2) TOTAL ON ITS THROW PATH, and STATED AS THAT rather than as totality in general. A caught throw is
#       NOT an empty result: it aborts NAMED, naming the policy and the declared escape. So the kernel
#       probe's collapse of "threw and was swallowed" into "emitted nothing" cannot recur.
#       ★ THE CLAIM STOPS THERE, DELIBERATELY. "Emitted nothing" and "returned `[ ]` for some other
#       reason" still reach ONE branch, and that branch compiles to no rule. The only such other reason
#       today would be a per-node DISPATCH gate answering in the recovery's place, and the caller removes
#       that possibility structurally by recovering from the UNGATED body (compile.nix `familyStamps` /
#       `mintFleetWide`) — a codomain is a static property of a body, so no dispatch concern belongs in
#       its derivation. That is a property of the CALLER's layering, not of this function, and a reader
#       must not read (2) as covering it: a `[ ]` reaching here is taken at face value.
#   (3) OPT-OUT BY DECLARATION. A v1 fleet whose codomain is declared is never fired at a sentinel at all.
#
# HONEST CEILING, unchanged in kind from the kernel probe but now confined and avoidable: `tryEval`
# cannot catch a non-recoverable eval error (a missing attribute, head-of-empty), so a body that
# field-accesses a REQUIRED sentinel coord bare still fails hard. `sentinelFields` is how a consumer that
# knows its own bodies supplies a TYPE-CORRECT NON-MATCHING value for such a field; declaring the codomain
# avoids the fire entirely.
{
  prelude,
  declare,
  errors,
}:
let
  # Fill ONLY the REQUIRED gate coords (`functionArgs` `false`). A DEFAULTED coord (`true`) is OMITTED so
  # the body's own default applies: a default is the AUTHOR's declared probe-safe value, and clobbering it
  # with a sentinel entry is a probe defect rather than a policy signal (a `{ accessGroups ? [ ], ... }`
  # body doing `elem g accessGroups` would see a SET and throw "expected a list but found a set", which
  # `tryEval` does not catch).
  requiredCoordsOf = condition: builtins.filter (n: !condition.${n}) (builtins.attrNames condition);
in
{
  # `recoverEmits { sentinelFields; declaredEmits; } name gate fn` → the codomain for one v1 policy.
  #
  # The GATE is passed in rather than read off `fn`, and that is not an optimisation. A compiled v1 policy's
  # body is a bare `ctx:` wrapper — the translation erases the inner fn's formals — so its `functionArgs`
  # is EMPTY and a fire driven by it would call the inner body with none of its required coords bound.
  # The gate is the record's DECLARED coord set (compile.nix `gate`), which is exactly the shape the fire
  # must fill, and it is the same source the kernel's dispatch gates on.
  recoverEmits =
    { sentinelFields, declaredEmits }:
    name: gate: fn:
    if declaredEmits ? ${name} && declaredEmits.${name} != [ ] then
      declaredEmits.${name}
    else
      let
        # A universal entry stand-in: passes the identity law (it carries `id_hash`) so a body forwarding
        # ctx entries into constructors succeeds without touching any real registry.
        probeEntry = {
          id_hash = "«sentinel»";
          name = "«sentinel»";
        }
        // sentinelFields;
        try = builtins.tryEval (
          let
            a = fn (prelude.genAttrs (requiredCoordsOf gate) (_: probeEntry));
          in
          builtins.deepSeq a a
        );
      in
      if !try.success then
        errors.policyCodomainUnrecoverable name
      else
        prelude.unique (map declare.kindOf try.value);
}
