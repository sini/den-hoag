# Compile `den.policies.<name>` into gen-dispatch rules, partitioned into the two feeds the structural
# stratum consumes: `enrich` (attr 2's keyset-ascent fixpoint, B1) and `policy` (attr 4's one-shot
# stratified rule evaluation, B2), plus the two staged pre-pass feeds and the fleet compose seed.
#
# A policy value is a RECORD. It DECLARES the facts the kernel schedules on rather than having them
# recovered by firing its body against a fabricated context:
#
#   { emits :: [Kind]; fn :: ctx -> [Decl]; selects ? null; gate ? functionArgs fn; ops ? [ ]; }
#
# EMITS is the declaration CODOMAIN — the closed set of declaration-kind tags the body may produce
# (declarations.nix `groups`). It is REQUIRED, and it is CHECKED at every firing, so it is a CONTRACT
# rather than an annotation: the declaration cannot drift from the body. Five facts the kernel used to
# obtain by execution are set-membership tests on it — the dispatch group (`declare.stratumOfKind` is
# TOTAL on the kind vocabulary), the produced-kind family, resolve-family membership, exclude-family
# membership, and enrich-only-ness.
#
# `emits = [ ]` IS AN EMPTY HEAD, NOT AN ABSENT RULE, and that is a RULING on what an empty declaration
# means rather than a default nobody chose. The three readings and why two are refused:
#   · EVERYTHING — not expressible, and already refused by a law here: the stratum is DERIVED from the
#     codomain, and a codomain over the whole kind vocabulary spans strata, which `policyMessage`
#     rejects. Ruled out by the representation, not by preference.
#   · NOTHING, i.e. compile the policy away — REFUSED, and this is the ruling that matters. It reads an
#     under-specified declaration as a DELETION ORDER, and the deletion is total and silent: the body
#     fires at no node, and the record's `selects`, `gate` and fleet-wide `ops` go with it, because
#     every feed is a filter over the compiled rules. Nothing reddens, and an absent policy leaves
#     nothing to look at — the worst shape a failure can take. It also conflates two states that must
#     stay apart: "I deliberately produce nothing" and "my codomain could not be determined", which is
#     the same conflation an under-specified declaration always invites.
#   · A RULE WHOSE CONSEQUENCE SET IS EMPTY — the ruling. A clause with an empty head is an ordinary
#     clause form, not the absence of one: it is in the program P, T_P maps over it, and it contributes
#     nothing to the model. Dropping it from P yields a DIFFERENT program. So an `emits = [ ]` policy
#     compiles to a rule like any other, fires where its gate admits, and produces nothing — and the
#     codomain contract already here makes the honest reading enforceable: a body that emits ANYTHING
#     violates an empty codomain and aborts NAMED at the emitting site (`conformingProduce` →
#     `errors.emitsUndeclared`), naming the policy and the kind it produced. The check that catches the
#     drift is the one every other policy already runs; nothing new has to be maintained for this case.
# THE DELETION IS THEREFORE UNREPRESENTABLE rather than merely discouraged: `compileOne` is TOTAL onto
# exactly one rule per declared policy, with no arm that yields none, so no value of `emits` can remove
# a policy from the compiled rule set. A policy disappears only by not being written — which is the one
# spelling of "this fleet has no such rule" that a reader cannot mistake for anything else.
#
# SELECTS is the 3-VALUED dispatch selection, because absence has two DIFFERENT meanings and one value
# cannot carry both: `null` = unconstrained (dynamic attachment — fires wherever the gate admits),
# `[ ]` = selects nothing (in no node's rule list at all), `[ k ... ]` = fires at nodes of those OWN
# kinds (k = 0: the node itself, not descendants inheriting the coordinate). Neither absence is spelled
# by omission. The default is `null`, so a record supplying only `emits` + `fn` keeps a bare closure's
# dispatch reach exactly.
#
# GATE defaults to the body's `functionArgs` — the presence gate (a rule fires only where every
# destructured ctx key is present; a channel-named arg, never a ctx key, therefore never fires). It is
# NOT derived from `emits`: what a policy produces and where its ctx admits it are different questions.
#
# OPS carries the FLEET-WIDE gen-pipe compose commitments as DATA. A derived-channel DAG or a delivery
# route seeds the ONE fleet compose BEFORE the eval and is ctx-INDEPENDENT by contract, so extracting it
# by firing a body was recovering a constant. Only per-node SITE MARKS are emitted from `fn`
# (`declare.isSiteMarkData` — site marks are per-node emission wiring, v1 register-pipe-effect.nix:15
# `scopedPipeEffects`); the two directions are checked at opposite ends.
#
# STRATUM (B2) is DERIVED, never declared. A rule fires in exactly ONE stratum, and `declare.stratumOfKind`
# is a total function from the kind tag, so declaring a stratum beside `emits` would create a second source
# for a derivable fact. A codomain spanning STRATA is rejected at registration: one rule, one stratum is
# gen-dispatch's core invariant (`dispatch.deriveGroup` aborts on a declared family spanning groups, and
# every rule here is discharged through it), so the surface refuses it at its own boundary rather than
# letting it throw deep inside a dispatch. The remedy is to author one policy per stratum — named, rather
# than synthesized behind a `#<stratum>` suffix.
#
# THE LEVEL CONDITION, stated correctly because den-hoag has negated reads (Apt, Blair & Walker 1988,
# `Towards a Theory of Declarative Knowledge`, Stratified Programs Definition 3, p. 96). A stratification
# assigns levels so that, for a clause whose head is in P_i, a relation occurring POSITIVELY in the body is
# defined within ⋃_{j ≤ i} P_j — the SAME stratum is permitted, which is what makes intra-stratum recursion
# legal — while a relation occurring NEGATIVELY must be defined within ⋃_{j < i} P_j, STRICTLY below. The
# paper's own gloss: "each stratum defines new relations in terms of itself only positively and in terms of
# the relations from the previous strata, possibly negatively." The condition is asymmetric, and reading it
# as "a body may not read at or above its own head" forbids what the paper permits.
{
  prelude,
  dispatch,
  declare,
  errors,
}:
let
  # The SEEDED strata config (§B2): the compiled stratum order with the stratum→ctx-key-groups map EMPTY
  # above the structural stratum. Rule ctx today is entity BINDINGS — inherited/enriched/linked context
  # (structural.nix attributes 1–3), ALL structural — so no ctx key belongs to a stratum above structural
  # and the projection below is a NO-OP for every shipped rule. The order threads from `den.strata`
  # (declarations.compileStrata) via `compileWithStrata`; a caller that inserts a stratum and tags a ctx
  # key to it gets the capability projection by construction.
  seededStrataCfg = {
    order = declare.strata;
    ctxKeyStrata = { };
  };

  # A policy value's declared parts. `emits` and `fn` are REQUIRED (validated by `policyMessage` before
  # any rule is built); the rest carry their documented defaults, and each default is the exact semantics
  # the corresponding omission had before it was a field.
  emitsOf = v: v.emits;
  fnOf = v: v.fn;
  selectsOf = v: v.selects or null;
  gateOf = v: v.gate or (builtins.functionArgs v.fn);
  opsOf = v: v.ops or [ ];
  # The group a policy's declared codomain classifies to. `declare.stratumOfKind` is TOTAL on the closed
  # kind vocabulary, so the stratum is DERIVED and never declared twice (a second source can disagree with
  # the first). Stratum-spanning is refused at registration, so this is a singleton wherever the codomain
  # is non-empty; `groupOf` below is the total function `compileOne` reads.
  groupsOf = emits: prelude.unique (map declare.stratumOfKind emits);

  # THE STRATUM OF AN EMPTY HEAD, decided rather than defaulted. ABW's level condition (Apt, Blair &
  # Walker 1988, Stratified Programs Definition 3, p. 96) constrains a clause's level THROUGH THE
  # RELATIONS IN ITS HEAD: a clause whose head is in P_i bounds where its body may read from. An empty
  # head names no relation and so imposes no lower bound, which makes the BOTTOM stratum the canonical
  # assignment — and it is the conservative one on the reading that matters here, because the A9
  # capability projection admits only STRICTLY LOWER ctx facts, so a bottom-stratum rule is granted the
  # least. It also fires earliest, so a body that violates its empty codomain aborts at the first
  # dispatch rather than a later one. `declare.strata` is non-empty by construction (compileStrata seeds
  # the framework strata), so this is total.
  groupOf =
    emits:
    let
      groups = groupsOf emits;
    in
    if groups == [ ] then builtins.head declare.strata else builtins.head groups;

  # policyMessage — the DEFINITION-TIME validator as a VALUE (`null` = clean, else the FIRST named
  # message), so every named contract here is CI-testable: Nix cannot recover a throw's TEXT from a caught
  # evaluation, so a validator that returns its message is the only form a test can assert on.
  # The guard chain is ORDERED — shape first, then vocabulary, then the ops law — so a later guard never
  # reads a field an earlier one has not validated. Rejection is AT REGISTRATION, an explicit boundary,
  # not a throw deep inside a dispatch (the `den.productions` posture, concern-productions.nix:18,82-149).
  policyMessage =
    policies:
    let
      knownKind = k: declare.kindToStratum ? ${k};
      checkOne =
        name: v:
        let
          emits = v.emits or null;
          unknown = builtins.filter (k: !(knownKind k)) (if builtins.isList emits then emits else [ ]);
          ops = v.ops or [ ];
          siteMarkOps = builtins.filter declare.isSiteMarkData ops;
        in
        if !(builtins.isAttrs v) then
          "den.policies: `${name}` is not a record - a policy value is `{ emits; fn; selects ? null; gate ? <formals>; ops ? [ ]; }`. A bare `ctx: [ declarations ]` closure cannot carry the emitted-kind family the kernel schedules on, and recovering it by firing the body against a fabricated context is what this surface replaces"
        else if !(v ? emits) then
          "den.policies: `${name}` declares no `emits` - the declaration codomain is REQUIRED. `emits = [ ]` (an EMPTY HEAD: the rule compiles, fires, and producing anything violates its codomain) is a legal value; an omitted `emits` is not, because silence must not be read as a permission to discover it by execution"
        else if !(builtins.isList emits) then
          "den.policies: `${name}`.emits must be a LIST of declaration-kind tags, got ${builtins.typeOf emits}"
        else if !(v ? fn) || !(builtins.isFunction v.fn) then
          "den.policies: `${name}` declares no function-valued `fn` - the body is `ctx: [ declarations ]`"
        else if !(selectsOf v == null || builtins.isList (selectsOf v)) then
          "den.policies: `${name}`.selects must be `null` (unconstrained), `[ ]` (selects nothing) or a list of kind names; those are three DIFFERENT selections and an omitted field means the first"
        else if unknown != [ ] then
          "den.policies: `${name}` emits unknown declaration kind `${builtins.head unknown}` - the vocabulary is the registered declaration kinds (declarations.nix `groups`)"
        else if builtins.length (groupsOf emits) > 1 then
          "den.policies: `${name}` emits kinds spanning strata ${builtins.concatStringsSep ", " (groupsOf emits)} - a rule's declarations classify to ONE stratum. This is gen-dispatch's core invariant, not only den-hoag's: `dispatch.deriveGroup` (gen-dispatch `mkActions`, the declared-stratum vocabulary) aborts on a declared kind family spanning groups, and `compileOne` discharges every rule through it. Split it into one policy per stratum; the split is authored and named rather than synthesized"
        else if siteMarkOps != [ ] then
          "den.policies: `${name}`.ops carries a SITE-MARK-only pipeOp - site marks are per-node emission data fired WHERE the policy fires, so they belong in the body's emission, not in the fleet-wide compose seed. `ops` carries only ctx-independent commitments (a derived-channel DAG or a delivery route)"
        else
          null;
      offenders = builtins.filter (m: m != null) (prelude.mapAttrsToList checkOne policies);
    in
    if offenders == [ ] then null else builtins.head offenders;

  # THE SELECTION, once per feed: one filtered list per SCHEMA kind, each preserving the feed's OWN ORDER.
  # Dispatch order determines emission order and therefore merge order, so a bucket-concatenation index
  # (`byKind ++ anyKind`) would perturb output; filtering the original list once per kind preserves it
  # exactly. A rule with `selects = [ ]` lands in NO bucket — it is not filtered out at a node, it is
  # ABSENT FROM EVERY NODE'S RULE LIST, so the shape is unrepresentable rather than corrected. A rule with
  # `selects = null` is in every bucket. `kinds` is opaque data supplied by the caller — the kernel learns
  # no kind NAMES.
  #
  # The result is a FUNCTION, not an attrset, and that is deliberate: a table lookup with an `or [ ]`
  # fallback would answer "no rules" for a kind absent from `kinds`, silently dropping every unconstrained
  # rule at that node — the failure mode this whole design exists to remove, reintroduced at the read. The
  # fallback recomputes the same filter instead, so the selection is TOTAL over node kinds by construction
  # and `kinds` is a memoisation hint rather than a correctness precondition.
  indexByKind =
    kinds: feed:
    let
      at = k: builtins.filter (r: r.selects == null || builtins.elem k r.selects) feed;
      table = prelude.genAttrs kinds at;
    in
    k: table.${k} or (at k);

  # `compileWithStrata { order; ctxKeyStrata } policies` — the strata-aware compiler. `compileWith` is
  # this with the seeded config (an empty ctx-key map ⇒ identity projection).
  compileWith = compileWithStrata seededStrataCfg;
  compileWithStrata =
    strataCfg: policies:
    let
      # Capability-scoped ctx (A9 stratification-by-construction, spec §5): a rule declared at stratum
      # `ruleStratum` may read ONLY ctx facts of a STRICTLY LOWER stratum. A ctx key whose declared
      # stratum is ≥ the rule's is REPLACED with a NAMED THROW (not omitted — a replaced key aborts
      # CATCHABLY when read, diagnosing better than an attribute-missing read). The seeded map is empty
      # above structural, so this is an identity map for every shipped rule.
      stratumIndex = prelude.foldl' (acc: i: acc // { ${builtins.elemAt strataCfg.order i} = i; }) { } (
        builtins.genList (i: i) (builtins.length strataCfg.order)
      );
      # key → its declared stratum (inverting the stratum→keys map); un-tagged keys are structural-safe.
      # A stratum name in the map that is absent from the compiled order aborts NAMED (forced at the first
      # projection, since the fold is lazy) — an untagged silent pass would defeat the projection.
      ctxKeyStratum = prelude.foldl' (
        acc: stratum:
        if !(stratumIndex ? ${stratum}) then
          throw "den.strata: ctxKeyStrata names unknown stratum '${stratum}' (not in the compiled order)"
        else
          prelude.foldl' (acc': key: acc' // { ${key} = stratum; }) acc (strataCfg.ctxKeyStrata.${stratum})
      ) { } (builtins.attrNames (strataCfg.ctxKeyStrata or { }));
      projectCtx =
        ruleStratum: ctx:
        let
          r = stratumIndex.${ruleStratum};
        in
        builtins.mapAttrs (
          key: v:
          let
            ks = ctxKeyStratum.${key} or null;
          in
          if ks != null && stratumIndex.${ks} >= r then
            throw "den.strata: ctx fact '${key}' is stratum '${ks}' ≥ rule stratum '${ruleStratum}'"
          else
            v
        ) ctx;
      # The FINAL (dispatch) produce reads its ctx through `projectCtx stratum`, so a ≥-stratum ctx fact
      # throws named when the body reads it.
      projectedBase =
        stratum: baseProduce: id: ctx:
        baseProduce id (projectCtx stratum ctx);

      # THE CONFORMANCE LAW: every declaration the body returns has its kind in the declared codomain, or
      # the run aborts NAMED at the emitting site. This is what makes `emits` a contract — a mis-declared
      # codomain is caught LOUD rather than mis-routing the rule silently. It SUBSUMES
      # `declare.checkStratum` (a conforming emission cannot span strata, because `emits` does not) and the
      # retired resolve-/exclude-family untagged guards (a `member`/`suppress` emitter has DECLARED it, so
      # it is in the feed by derivation and "emitted but untagged" is unrepresentable). The `pipeOp` arm is
      # the body end of the compose-commitment boundary whose other end is `policyMessage`'s ops law. One
      # attrset membership test per emitted declaration, on a list already being materialised.
      conformingProduce =
        name: emits: baseProduce: id: ctx:
        let
          admitted = prelude.genAttrs emits (_: true);
        in
        map (
          a:
          let
            k = declare.kindOf a;
          in
          if !(admitted ? ${k}) then
            errors.emitsUndeclared name k emits
          else if k == "pipeOp" && !(declare.isSiteMarkData a) then
            errors.opsInBody name
          else
            a // { __policy = name; }
        ) (baseProduce id ctx);

      # ONE policy compiles to ONE rule — TOTALLY, with no arm that compiles to none. `group` is stamped
      # from the DECLARED codomain at definition time and `produces` IS that codomain, so gen-dispatch
      # honours it and skips its per-dispatch fire-and-classify validation. There is no probe, no
      # sentinel, no fabricated context and no per-stratum fan. The capability projection over ctx (A9)
      # is unchanged; it now reads a declared group instead of an observed one.
      #
      # THE MAP IS TOTAL, which IS the remedy for the silent-deletion defect rather than a check against
      # it. A `[ ]` arm here would be a policy-shaped hole in the compiled rule set that nothing can
      # observe — no acts, no error, no trace — so there is no such arm: an empty codomain is an empty
      # HEAD (a rule that fires and produces nothing, its emptiness enforced by `conformingProduce`), not
      # an absent rule. `groupOf` is total over codomains, so the group exists for every policy.
      compileOne =
        name: v:
        let
          emits = emitsOf v;
          base = dispatch.fromFunction (fnOf v);
          group = groupOf emits;
        in
        [
          (dispatch.deriveGroup declare.stratumOfKind {
            inherit (base) nac priority overrides;
            inherit group;
            condition = gateOf v;
            produces = emits;
            selects = selectsOf v;
            ops = opsOf v;
            identity = name;
            produce = conformingProduce name emits (projectedBase group base.produce);
          })
        ];

      # Registration rejection is forced BEFORE any rule exists, so a malformed surface is refused at its
      # own boundary rather than at whichever consumer first forces a rule.
      registration = policyMessage policies;
      rules =
        if registration != null then
          errors.policyRegistration registration
        else
          prelude.concatMap (name: compileOne name policies.${name}) (builtins.attrNames policies);

      # Every feed is a set-membership test on the DECLARED codomain. The name-keyed knobs that supplied
      # these by hand (`den.resolveFamilyNames`, `den.excludeFamilyNames`, `den.producesByName`) have no
      # remaining job, and neither does a strip list: there are no `__`-carriers to remove, because the
      # facts they carried are fields.
      emitsAny = r: ks: builtins.any (k: builtins.elem k ks) r.produces;
    in
    {
      enrich = builtins.filter (r: r.produces == [ "enrich" ]) rules;
      policy = builtins.filter (r: r.produces != [ "enrich" ]) rules;
      # The STAGED ROOT-RESOLUTION pre-pass feed (design note 2026-07-11 §3(ii)): the structural-group
      # rules that can emit resolve-family {member}. The pre-pass dispatches ONLY these at roots, so an
      # arbitrary co-firing policy body is never run there. Empty for a fleet with no resolve policies.
      resolveFamily = builtins.filter (
        r: r.group == "structural" && emitsAny r declare.resolveFamilyKinds
      ) rules;
      # The EXCLUDE-FAMILY feed (#72): the structural-group rules that can emit `suppress`. The staged
      # pre-pass dispatches ONLY these for suppression collection; empty for an exclude-free fleet.
      excludeFamily = builtins.filter (r: r.group == "structural" && emitsAny r [ "suppress" ]) rules;
      # The fleet-wide compose commitments, DECLARED. No firing, no probe: a ctx-independent commitment
      # read from a body by firing it was recovering a constant the record can simply carry.
      pipeOps = prelude.concatMap (r: r.ops) rules;
    };
in
{
  compile = compileWith;
  inherit
    compileWith
    compileWithStrata
    indexByKind
    policyMessage
    ;
}
