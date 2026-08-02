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
#       ★★ AND THE CLAIM NO LONGER STOPS THERE. It used to: "emitted nothing" and "returned `[ ]` because
#       a VALUE-CONDITIONAL body took its false branch at a value-less context" reached ONE branch, which
#       recovered an EMPTY codomain — an empty HEAD, so the rule fired, and a body that genuinely emits
#       then violated a codomain this function had invented for it. `classifyDecls` SEPARATES those two
#       facts by construction: the fire is made at a SPY whose every coordinate field is a named throw, so
#       a body that reads one is CAUGHT and refused, and an admitting fire is positive evidence that the
#       `[ ]` is the BODY's answer rather than the sentinel's. The two remaining ways a `[ ]` can be wrong
#       are both key-set properties, stated at `codomainSpy`.
#       ★ The other way a `[ ]` could arrive — a per-node DISPATCH gate answering in the recovery's place —
#       the caller removes structurally by recovering from the UNGATED body (compile.nix `familyStamps` /
#       `mintFleetWide`): a codomain is a static property of a body, so no dispatch concern belongs in its
#       derivation. That is still a property of the CALLER's layering, not of this function.
#   (3) OPT-OUT BY DECLARATION. A v1 fleet whose codomain is declared is never fired at a sentinel at all,
#       and the declaration may be authored on the v1 record, at `den.policyCodomains.<name>`, or in the
#       shim's own corpus tables — PER FIELD, so a policy pays a fire only for a field no source declares.
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

  # A universal entry stand-in: passes the identity law (it carries `id_hash`) so a body forwarding
  # ctx entries into constructors succeeds without touching any real registry.
  valueSentinelOf =
    sentinelFields:
    {
      id_hash = "«sentinel»";
      name = "«sentinel»";
    }
    // sentinelFields;

  # ── THE RECOVERY DOMAIN — WHAT THE CODOMAIN ANSWER ACTUALLY READS ────────────────────────────────
  #
  # The fire's envelope is `tryEval` over EXACTLY the domain, and both bounds are load-bearing.
  #
  # A BARE `tryEval` IS USELESS: a policy body returns a LIST, whose WHNF is the list, so every body
  # reports clean and a refusal built on it is empty by construction.
  #
  # ★★ AND `deepSeq` IS THE OTHER ERROR. It forces the whole returned structure INCLUDING PAYLOADS — and a
  # v1 body that FORWARDS its coordinate entry into a declaration (`member { coords = { host = host; }; }`)
  # puts the coordinate inside a payload, where `deepSeq` drags it out. Such a body is BEHAVIOURALLY
  # UNCONDITIONAL: its emission structure depends on no coordinate VALUE, and refusing it is a false
  # refusal carrying a false reason. It is not a corner case — `lib/declarations.nix` `member`
  # entry-checks its coords EAGERLY, so EVERY `member`-emitting v1 body forwards a coordinate by
  # construction, which is the whole resolve family.
  #
  # ⇒ THE ENVELOPE ALIGNS THE FORCING WITH THE QUESTION rather than filtering the refusal. The recovery
  # answers exactly three things — the KIND SET, the REFINED CODOMAINS, and law (a)'s refusal, which
  # renders a few fields of an unauthorised `pipeCommit`. Force exactly those. A payload the answer never
  # reads is data this question has no business forcing.
  #
  # ★ WHAT THAT DOES NOT LOSE: a body whose kind set, list LENGTH or refined codomain depends on a
  # coordinate still forces something in the domain and is still refused. A read hidden in a PAYLOAD is
  # admitted here and caught ELSEWHERE — by law (a) if the policy is undeclared, and by the commitment
  # fire (which deep-forces, correctly, because a commitment IS a definition-time constant) if it is
  # declared. Two questions, two instruments, two forcing depths.
  #
  # ★★★ THE DOMAIN IS DEFINED BY A BINDING NAME, NOT BY A HAND LIST, and that is the whole of `lawAFields`
  # below: it is EVERY field `errors.commitmentFieldsOf` reads, plus the `channel` that
  # `errors.commitmentUndeclared` renders around it. A hand list drifts from its reader in silence;
  # `commitmentFieldsOf` is therefore a COUPLED SURFACE — a field added to it is a field owed to this
  # domain.
  # ★ These expressions MIRROR those reads rather than approximating them: `.derived.__derived or false`
  # and the two `!= [ ]` comparisons, not `(a.routes or null)`. What `!= [ ]` forces is the list SPINE and
  # not its elements, so the reachable hazard is a coordinate-dependent SPINE — which is exactly what
  # `lib/compat/pipe.nix` builds (`routes = asRoutes`, `targeted = map (c: …)`: mapped lists whose length
  # follows the body's stages). A throwing ELEMENT never reaches the test.
  lawAFields =
    decls:
    map (
      a:
      if declare.kindOf a == "pipeCommit" then
        [
          a.channel
          (a.derived.__derived or false)
          ((a.routes or [ ]) != [ ])
          ((a.targeted or [ ]) != [ ])
        ]
      else
        null
    ) decls;

  recoveryDomain =
    decls:
    builtins.deepSeq (map declare.kindOf decls) (
      builtins.deepSeq (declare.codomainsOf decls) (builtins.deepSeq (lawAFields decls) true)
    );

  # THE FIRE ITSELF, named once. `recoverEmits` is a projection of it, and so is the REFINED-codomain
  # recovery (`suppresses`/`binds`, compile.nix `codomainRecordFor`): a codomain that names dependency EDGES
  # rather than kinds is read off the SAME declarations by the same table's `keysOf`. The caller shares ONE
  # classification across every field it owes (compile.nix `codomainRecordFor`), so the shim fires a body
  # once per codomain question rather than once per field.
  fireIn =
    domain: args: fn:
    builtins.tryEval (
      let
        a = fn args;
      in
      builtins.seq (domain a) a
    );

  # ── THE CODOMAIN SPY — the THROWING TWIN of the value sentinel ───────────────────────────────────
  #
  # The VALUE sentinel is a stand-in, and a value stand-in cannot answer a question ABOUT a value: a body
  # branching on `host.class` takes its FALSE branch at the sentinel, the fire SUCCEEDS, and the recovery
  # reports the false branch's codomain as though it were the body's. That is the measured unsoundness.
  # The spy has the SAME KEY SET and inverted values: every one is bound to a NAMED throw, so a read is a
  # funnel rather than a hole, and the fire's outcome answers a question the value sentinel cannot pose —
  # DID THE EMISSION STRUCTURE READ A COORDINATE VALUE AT ALL.
  #
  # ★ THE KEY SET IS THE WIRING'S IN BOTH, AND THAT IS THE WHOLE SOUNDNESS ARGUMENT. Two fires that differ
  # only in the VALUES bound to a shared key set can differ in outcome only through a read of one of those
  # keys, so an admitting verdict means no key was read. A key ABSENT from the set is absent from BOTH and
  # therefore cannot distinguish them — the residual ceiling, which is a property of the key set and is
  # closed by naming the field in probe-sentinel.nix.
  # ★ THE IDENTITY LAW IS SATISFIED BY PRESENCE, NOT BY VALUE: `requireEntry`'s test is `v ? id_hash`, and
  # `?` does not force, so a throwing `id_hash` still passes it. That same fact is the OTHER ceiling: a
  # PRESENCE test in a body (`host ? class`) cannot be funnelled by a throwing field.
  codomainSpy =
    { sentinelFields }:
    name:
    prelude.genAttrs
      (
        [
          "id_hash"
          "name"
        ]
        ++ builtins.attrNames sentinelFields
      )
      (
        field:
        throw "den-compat: codomain spy: v1 policy `${name}` read the coordinate field `${field}` while its declaration codomain was being recovered"
      );

  # `classifyDecls { sentinelFields } name gate fn` → the verdict, and on the admitting verdict the
  # DECLARATIONS the body produced. Three states where the value sentinel had two:
  #
  #   spy fire SUCCEEDS  ⇒ the emission structure read no coordinate value ⇒ the decls it returned ARE
  #                        its codomain, soundly. This holds for the EMPTY result too, which is the whole
  #                        gain: the empty is now known to be the BODY's answer and not the sentinel's.
  #   spy fire CAUGHT,
  #     value fire OK    ⇒ the body READ a coordinate value ⇒ VALUE-CONDITIONAL. There is no context at
  #                        which the question has an answer, so the caller refuses rather than inventing
  #                        one.
  #   BOTH fires CAUGHT  ⇒ the body cannot be fired AT ALL — a RECOVERY FAILURE, which is a different
  #                        fact and keeps its own diagnostic. Collapsing the two would reinstate exactly
  #                        the "threw and was swallowed" merge this file's header (2) refuses, one level
  #                        up: "could not fire it" and "it decides from a value" have different remedies.
  #
  # ★ THE DOMAIN IS `requiredCoordsOf gate` in every position, matching the shipped recovery: a DEFAULTED
  # coordinate is OMITTED so the body's own default applies, because a default is the AUTHOR's declared
  # probe-safe value and binding a defaulted list-typed formal to either sentinel is what makes the fire
  # itself abort uncatchably.
  classifyDecls =
    { sentinelFields }:
    name: gate: fn:
    let
      required = requiredCoordsOf gate;
      spy = codomainSpy { inherit sentinelFields; } name;
      probeEntry = valueSentinelOf sentinelFields;
      fire = args: fireIn recoveryDomain args fn;
      spyTry = fire (prelude.genAttrs required (_: spy));
    in
    if spyTry.success then
      {
        verdict = "unconditional";
        decls = spyTry.value;
        reads = [ ];
      }
    else if !(fire (prelude.genAttrs required (_: probeEntry))).success then
      errors.policyCodomainUnrecoverable name
    else
      {
        verdict = "value-conditional";
        decls = null;
        # ATTRIBUTION, on the refusing path only, so nothing is paid on the admitting path: one isolated
        # fire per required coordinate, that coordinate bound to the spy and every other to the VALUE
        # sentinel. Best-effort in both directions, so an EMPTY attribution renders the full candidate set
        # rather than degrading to silence — the shipped `commitmentFireFailed` posture, kept.
        reads =
          let
            attributed = builtins.filter (
              c: !(fire (prelude.genAttrs required (n: if n == c then spy else probeEntry))).success
            ) required;
          in
          if attributed == [ ] then required else attributed;
      };

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
  # THE PROBE'S ENVELOPE IS `tryEval` OVER `deepSeq`, never a bare `tryEval` of the application. A policy
  # body returns a LIST, whose WHNF is the list, so a bare `tryEval` would report every coordinate clean
  # and the attribution would be empty by construction.
  # ★ AND IT IS `deepSeq` HERE WHILE THE CODOMAIN FIRE FORCES ONLY `recoveryDomain`, which is a difference
  # of QUESTION and not of caution. A commitment is a definition-time CONSTANT: its payload fields are the
  # answer, so forcing them is forcing what is being asked for. A codomain answer never reads a payload,
  # so forcing one there refuses bodies for reads its own answer does not depend on.
  recoverCommitments =
    { sentinelFields }:
    name: gate: fn:
    let
      twin = commitmentSentinel { inherit sentinelFields; } name;
      probeEntry = valueSentinelOf sentinelFields;
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
  inherit classifyDecls recoverCommitments;

  # `recoverEmits name decls` → the `emits` codomain read off declarations the spy already ADMITTED.
  #
  # THE GATE AND THE FIRE ARE THE CALLER'S, and that is the fire-sharing property: `emits` and the refined
  # codomains are three projections of ONE classification, so the caller (compile.nix `codomainRecordFor`)
  # classifies once and projects three times rather than firing a body per field. Splitting the fire per
  # field would fire a body N times for one static property and give the recoveries a way to disagree with
  # each other.
  #
  # ★ LAW (a) — A `pipeCommit` IN THE DECLS THE RECOVERY FIRE RETURNED, refused BEFORE the kind
  # projection. This projection is reached only when NO source declares `emits` (the caller's chain returns
  # first otherwise), so `undeclared` is a FACT here rather than a guess, and any `pipeCommit` among these
  # decls is unauthorised by construction: the commitment fire is gated on the DECLARED codomain, so
  # nothing will ever collect it.
  # ★ POSITION, and it is a derivation rather than a preference. Three properties select it together:
  #   (1) it is OUTSIDE the fire's `tryEval`, so the refusal's message survives — a throw raised inside
  #       would be caught and rendered as `policyCodomainUnrecoverable`, policy name only;
  #   (2) it is BEFORE `unique (map kindOf …)`, which erases `channel`, `derived`, `routes` and
  #       `targeted` — the very fields the message names;
  #   (3) it is the only position at which the ABSENCE of a declaration is established. The classification
  #       is SHARED — the refined-codomain projections read the same decls for policies whose `emits` IS
  #       declared — so a refusal placed inside it would abort a policy for holding a commitment its own
  #       declaration authorises.
  # ★ The filter is written over `(a.__action or null)`, not `declare.kindOf` — `kindOf` is a bare
  # selection with no default, so a tag-less declaration would raise Nix's own unattributed error from
  # inside the refusal's own test. Running the filter BEFORE the `map` also converts that pre-existing
  # unattributed abort into this named one wherever both are present, and converts none the other way.
  recoverEmits =
    name: decls:
    let
      unauthorised = builtins.filter (a: (a.__action or null) == "pipeCommit") decls;
    in
    if unauthorised != [ ] then
      errors.commitmentUndeclared name (builtins.head unauthorised)
    else
      prelude.unique (map declare.kindOf decls);
}
