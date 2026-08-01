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
#       reason" still reach ONE branch, and that branch recovers an EMPTY codomain — an empty HEAD, so the
#       rule fires, and a body that genuinely emits then violates a codomain this function invented for it.
#       The only such other reason would be a per-node DISPATCH gate answering in the recovery's place, and
#       the caller removes that possibility structurally by recovering from the UNGATED body (compile.nix
#       `familyStamps` / `mintFleetWide`) — a codomain is a static property of a body, so no dispatch
#       concern belongs in its derivation. That is a property of the CALLER's layering, not of this
#       function, and a reader must not read (2) as covering it: a `[ ]` reaching here is taken at face
#       value.
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

  # THE FIRE ITSELF, named once. `recoverEmits` is a projection of it, and so is the REFINED-codomain
  # recovery (`suppresses`/`binds`, compile.nix `codomainStamps`): a codomain that names dependency EDGES
  # rather than kinds is read off the SAME declarations by the same table's `keysOf`, so the shim fires a
  # body at most once whatever it has to recover. Splitting the fire per field would fire a body N times
  # for one static property and give the recoveries a way to disagree with each other.
  recoverDecls =
    { sentinelFields }:
    name: gate: fn:
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
    if !try.success then errors.policyCodomainUnrecoverable name else try.value;

  # ── THE COMMITMENT SENTINEL — a THROWING TWIN of `sentinelFields` ────────────────────────────────
  #
  # The shipped sentinel is a VALUE stand-in, and a value stand-in is unsound for a projection that reads
  # a VALUE. A body binding `srcUser = user.name` at the value sentinel gets the string `"«sentinel»"`,
  # the fire SUCCEEDS, and the commitment carries that constant at every node — silently, with no funnel.
  # The twin has the SAME KEYS and inverted values: every one is bound to a NAMED throw, so a read is a
  # funnel rather than a hole. Two measured facts force exactly this shape:
  #   • an `or`-defaulted attrpath whose FIRST step is MISSING defaults SILENTLY, so a field the sentinel
  #     does not carry is a silent hole ⇒ the key set must be NAMED, not invented;
  #   • `or` defaults an ABSENT attribute and does not catch a raised throw, so a field it DOES carry
  #     cannot be `or`-defaulted around ⇒ a bound throw is a total funnel on its own key.
  # ★ THE KEY SET IS THE WIRING'S, NOT A LITERAL. It is a projection of whatever `sentinelFields` the
  # caller passed — 6 keys through the bridge (`settings` included), 5 through `denCompat.compile`, 2 with
  # `probeSentinel` off — so a corpus field added to probe-sentinel.nix for the VALUE sentinel arrives
  # here in the same edit and the two sets cannot drift. Only `attrNames` is read, never the values, so
  # the bridge's lazy `settings` thunk stays unforced.
  # ★ THE IDENTITY LAW IS SATISFIED BY PRESENCE, NOT BY VALUE: `requireEntry`'s test is `v ? id_hash`, and
  # `?` does not force, so a throwing `id_hash` still passes it.
  # ★ TOTAL IN EXTENT, NOT IN BEHAVIOUR. Every named field read raises a CATCHABLE named throw. A
  # coordinate consumed BY TYPE never selects a field at all — Nix's argument-type check inspects the type
  # tag — so it raises an UNCATCHABLE `expected a list but found a set`, exactly as the value sentinel
  # does. That ceiling belongs to both sentinels equally, because it belongs to their being attrsets.
  commitmentSentinel =
    { sentinelFields }:
    name:
    let
      throwing =
        field:
        throw "den-compat: compose commitment: v1 policy `${name}` read the coordinate field `${field}` while building its compose commitment. A commitment is read ONCE at definition time, where no node exists, so there is no value to answer with";
    in
    prelude.genAttrs (
      [
        "id_hash"
        "name"
      ]
      ++ builtins.attrNames sentinelFields
    ) throwing;

  # `recoverCommitments { sentinelFields; } name gate fn` → the `pipeCommit` declarations one v1 body
  # produces at the commitment sentinel. THE FIRE IS DEFINITION-TIME: once per commitment-bearing policy,
  # at the compat record mint. No node, no stratum index, no dispatch, no `projectCtx`.
  #
  # THE FIRE'S DOMAIN IS EVERY COORDINATE — `attrNames gate`, required and DEFAULTED alike. Omitting a
  # defaulted coordinate (the recovery fire's own domain) would let the body take its own default branch
  # and produce the default-branch commitment at every node with no funnel — a silent wrong constant,
  # which is strictly worse than a loud stop.
  #
  # THE PROBE'S DOMAIN IS `requiredCoordsOf gate`, IN BOTH POSITIONS, AND THE ASYMMETRY IS DELIBERATE. On
  # failure the body has ALREADY failed and the only question is which coordinate to name; taking the
  # body's own default branch costs nothing there, while binding a defaulted list-typed formal to either
  # sentinel is what makes the probe itself abort uncatchably. So the probed coordinate and the background
  # bindings take the SAME required-only set, and a defaulted coordinate is bound in neither — which is a
  # stated ceiling on the ATTRIBUTION, not on the refusal.
  #
  # THE PROBE'S ENVELOPE IS `recoverDecls`' OWN — `tryEval` over `deepSeq`, never a bare `tryEval` of the
  # application. A policy body returns a LIST, whose WHNF is the list, so a bare `tryEval` would report
  # every coordinate clean and the attribution would be empty by construction.
  recoverCommitments =
    { sentinelFields }:
    name: gate: fn:
    let
      twin = commitmentSentinel { inherit sentinelFields; } name;
      probeEntry = {
        id_hash = "«sentinel»";
        name = "«sentinel»";
      }
      // sentinelFields;
      fireWith =
        args:
        builtins.tryEval (
          let
            a = fn args;
          in
          builtins.deepSeq a a
        );
      try = fireWith (prelude.genAttrs (builtins.attrNames gate) (_: twin));
      required = requiredCoordsOf gate;
      # On the FAILURE path only, so nothing is paid on the success path: one isolated fire per required
      # coordinate, that coordinate bound to the twin and every other required one to the value sentinel.
      attributed = builtins.filter (
        c: !(fireWith (prelude.genAttrs required (n: if n == c then twin else probeEntry))).success
      ) required;
    in
    if !try.success then
      errors.commitmentFireFailed name null attributed required
    else
      builtins.filter (a: (a.__action or null) == "pipeCommit") try.value;
in
{
  inherit recoverDecls recoverCommitments;

  # `recoverEmits { sentinelFields; declaredEmits; } name gate fn` → the codomain for one v1 policy.
  #
  # The GATE is passed in rather than read off `fn`, and that is not an optimisation. A compiled v1 policy's
  # body is a bare `ctx:` wrapper — the translation erases the inner fn's formals — so its `functionArgs`
  # is EMPTY and a fire driven by it would call the inner body with none of its required coords bound.
  # The gate is the record's DECLARED coord set (compile.nix `gate`), which is exactly the shape the fire
  # must fill, and it is the same source the kernel's dispatch gates on.
  # ★ THE DECLARATION TEST IS PRESENCE, matching `emitsFor`'s: a `declaredEmits` entry of `[ ]` is the
  # EMPTY HEAD stated outright, not a missing entry, and firing a body to replace it would be this
  # function inventing a codomain over its caller's declaration — the one thing (1) says it never does.
  # Inert at the single live caller (which resolves the whole declaration chain itself and passes `{ }`),
  # and that is exactly why the guard has to be right here: the shape is what a future caller inherits.
  # ★ LAW (a) — A `pipeCommit` IN THE DECLS THE RECOVERY FIRE RETURNED, refused BEFORE the kind
  # projection. This branch is reached only when the policy has NO declaration (`emitsFor`'s earlier arms
  # return first otherwise), so `undeclared` is a FACT here rather than a guess, and any `pipeCommit`
  # among these decls is unauthorised by construction: the commitment fire is gated on the DECLARED
  # codomain, so nothing will ever collect it.
  # ★ POSITION, and it is a derivation rather than a preference. Three properties select it together:
  #   (1) it is OUTSIDE `recoverDecls`' `tryEval`, so the refusal's message survives — a throw raised
  #       inside would be caught and rendered as `policyCodomainUnrecoverable`, policy name only;
  #   (2) it is BEFORE `unique (map kindOf …)`, which erases `channel`, `derived`, `routes` and
  #       `targeted` — the very fields the message names;
  #   (3) it is the only position at which the ABSENCE of a declaration is established. `recoverDecls` is
  #       SHARED — `codomainStamps` calls it for policies whose `emits` IS fully declared — so a refusal
  #       placed inside it would abort a policy for holding a commitment its own declaration authorises.
  # It adds no export, no call site, no signature change and no second application of the body: one `let`
  # binding of a value this function already computes, one filter, one refusal.
  # ★ The filter is written over `(a.__action or null)`, not `declare.kindOf` — `kindOf` is a bare
  # selection with no default, so a tag-less declaration would raise Nix's own unattributed error from
  # inside the refusal's own test. Running the filter BEFORE the `map` also converts that pre-existing
  # unattributed abort into this named one wherever both are present, and converts none the other way.
  recoverEmits =
    { sentinelFields, declaredEmits }:
    name: gate: fn:
    if declaredEmits ? ${name} then
      declaredEmits.${name}
    else
      let
        decls = recoverDecls { inherit sentinelFields; } name gate fn;
        unauthorised = builtins.filter (a: (a.__action or null) == "pipeCommit") decls;
      in
      if unauthorised != [ ] then
        errors.commitmentUndeclared name (builtins.head unauthorised)
      else
        prelude.unique (map declare.kindOf decls);
}
