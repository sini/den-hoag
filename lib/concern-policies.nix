# Compile `den.policies.<name>` into gen-dispatch rules, partitioned into the two feeds the
# structural stratum consumes: `enrich` (attr 2's keyset-ascent fixpoint, B1) and `policy` (attr 4's
# one-shot stratified rule evaluation, B2). A policy value is either a bare `ctx: [decl]` FUNCTION —
# whose `functionArgs` ARE the presence gate (fires only where every destructured ctx key is present;
# a channel-named arg, never a ctx key, therefore never fires) — or a rule RECORD `{ __condition; fn }`
# whose gate is DECLARED explicitly (a `functionArgs`-shaped coord set) over a bare-ctx body. The
# record form is the general policy vocabulary for programmatically-generated policies that cannot
# shape their formals — a generated policy declares its gate as data (den-hoag greenfield D7). `fn`
# is a `ctx: [decl]` body either way; the produce is wrapped to stamp the owning policy (`__policy`).
#
# STRATUM (B2). A rule fires in exactly ONE stratum — gen-dispatch runs each rule only in its group's
# phase and validates that its declarations all classify to that group. The stratum is read by probing
# produce on a sentinel context (every REQUIRED gate coord filled with a sentinel entry), which yields the
# produced kinds' stratum. The probe fills only the REQUIRED coords (a `functionArgs` `false`): a DEFAULTED
# coord (`true`) is OMITTED, so the body's own default applies — a default is the AUTHOR's declared
# probe-safe value, so clobbering it with a sentinel entry is a probe defect, not a policy signal (e.g. a
# `{ accessGroups ? [], … }` body doing `elem g accessGroups` would see a `{ id_hash; name }` SET and throw
# "expected a list but found a set", which tryEval does NOT catch). The probe is FORMAL-PRESERVING for the
# required gate (a record's bare-ctx body sees its required coords) and tryEval-GUARDED: a body doing
# value-work against the sentinel that reaches a `throw`/`assert` (e.g. a constructor's identity-law abort)
# is caught and treated IDENTICALLY to an empty probe — both route to the per-declaration EXPANSION path.
# HONEST LIMIT: `tryEval` cannot catch a non-recoverable eval error (missing attribute, head-of-empty), so a
# body that field-accesses/iterates a REQUIRED sentinel coord bare still fails the probe HARD — loudly,
# pointing at the probe (the documented pre-record failure mode). A value-conditional body reaches its
# coords via `or` defaults / defaulted formals (the corpus idiom), which yields the clean empty-probe path.
#
# EXPANSION (the value-conditional path). When the probe observes no emission the stratum cannot be
# read up front — the policy's emission is gated on a ctx VALUE, so it emits nothing at the value-less
# sentinel. Rather than guess ONE stratum (the silent-partition sin), the policy is expanded into one
# sub-rule per COVERED stratum {structural, resolution, collection}: each fires at the SAME gated nodes
# and keeps only its-stratum declarations, so every declaration is produced in ITS stratum's phase with
# that phase's context — the one-rule/one-stratum law holds PER SUB-RULE while the policy's declarations
# self-route by kind (B2's readers pull `actions.<stratum>` by kind, independent of the producing
# rule). Expansion is the CONSERVATIVE branch: a policy misclassified INTO it still fires correctly at
# real coord values; misclassifying a value-conditional policy OUT of it (as a fixed single stratum)
# would mis-place its declarations. Two conservation limits abort LOUD (`errors.expansion*`): an
# enrich-kind declaration (enrich-feed selection is a probe-time B1 commitment a value-less policy
# cannot make) and a DERIVED/route pipeOp (a channel-shaping DAG or delivery route seeds the ONE fleet
# gen-pipe compose BEFORE eval, from ctx-independent bodies). But a pure SITE-MARK pipeOp on a bare
# channel ref is NOT a compose commitment — site marks are per-node emission wiring fired WHERE the
# policy fires (v1 register-pipe-effect.nix:15 scopedPipeEffects), so it is per-node DATA and rides the
# `#collection` sub-rule (`declare.isSiteMarkData`), seeding no compose op.
{
  prelude,
  dispatch,
  declare,
  errors,
}:
let
  # `compileWith sentinelFields resolveFamilyNames policies` — compile with a CONFIGURABLE probe sentinel
  # AND a CONFIGURABLE resolve-family tag set. Two corpus-facts-as-config knobs (the SAME composition-first
  # precedent — core stays FIELD/NAME-agnostic; the CONSUMER supplies what it knows about its own bodies):
  #   • `sentinelFields` merges onto the universal `{ id_hash; name }` probe stand-in, so a caller that KNOWS
  #     a policy body reads a coord FIELD on the sentinel supplies a TYPE-CORRECT NON-MATCHING value for it —
  #     the body takes its value-conditional FALSE branch (→ expansion) instead of hard-failing.
  #   • `resolveFamilyNames` (R2 REQUIREMENT 2) STAMPS `__resolveFamily = true` on the named compiled
  #     policies — the DECLARED tag a VALUE-CONDITIONAL resolve policy needs (its value-less probe emits no
  #     member/relate, so it cannot be DETECTED). A v1 corpus authors `resolve.to` policies WITHOUT the
  #     den-hoag tag on the value, so the shim flake-module supplies the corpus resolve-emitting names here.
  #     A name NOT supplied that DOES emit member/relate at a root is caught LOUD by the R2 untagged guard
  #     (attributes/structural.nix attr 4 `resolveFamilyUntagged`) — the omission catch, never a silent drop.
  # `compile` = the defaults `{ }` / `[ ]`, byte-identical for every native caller.
  # `excludeFamilyNames` (#72, candidate A — the resolveFamilyNames twin): names whose compiled rules
  # join the EXCLUDE-FAMILY feed the staged pre-pass dispatches for `suppress` collection; a
  # value-conditional excluder (the corpus's droid-gated route exclude) probes empty, so the DECLARED
  # tag is its only path. An omitted name that DOES emit `suppress` in the main run is caught LOUD
  # (attributes/structural.nix `excludeFamilyUntagged`).
  # The SEEDED strata config (§B2): the compiled stratum order with the stratum→ctx-key-groups map EMPTY
  # above the structural stratum. Rule ctx today is entity BINDINGS — inherited/enriched/linked context
  # (structural.nix attributes 1–3), ALL structural — so no ctx key belongs to a stratum above structural
  # and the projection below is a NO-OP for every shipped rule (the 972-suite is the byte proof). The
  # order threads from `den.strata` (declarations.compileStrata) via `compileWithStrata`; a caller that
  # inserts a stratum and tags a ctx key to it gets the capability projection by construction.
  seededStrataCfg = {
    order = declare.strata;
    ctxKeyStrata = { };
  };

  # `compileWithStrata { order; ctxKeyStrata } …` — the strata-aware compiler. `compileWith` is this with
  # the seeded config, so every existing caller is byte-identical (empty map ⇒ identity projection).
  compileWith = compileWithStrata seededStrataCfg;
  compileWithStrata =
    strataCfg: sentinelFields: resolveFamilyNames: excludeFamilyNames: policies:
    let
      # Capability-scoped ctx (A9 stratification-by-construction, spec §5): a rule declared at stratum
      # `ruleStratum` may read ONLY ctx facts of a STRICTLY LOWER stratum. A ctx key whose declared
      # stratum is ≥ the rule's is REPLACED with a NAMED THROW (not omitted — a replaced key aborts
      # CATCHABLY when read, diagnosing better than an attribute-missing read that escapes tryEval). The
      # seeded map is empty above structural, so this is an identity map for every shipped rule.
      stratumIndex = prelude.foldl' (acc: i: acc // { ${builtins.elemAt strataCfg.order i} = i; }) { } (
        builtins.genList (i: i) (builtins.length strataCfg.order)
      );
      # key → its declared stratum (inverting the stratum→keys map); un-tagged keys are structural-safe.
      ctxKeyStratum = prelude.foldl' (
        acc: stratum:
        prelude.foldl' (acc': key: acc' // { ${key} = stratum; }) acc (
          strataCfg.ctxKeyStrata.${stratum} or [ ]
        )
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
          if ks != null && (stratumIndex.${ks} or (-1)) >= r then
            throw "den.strata: ctx fact '${key}' is stratum '${ks}' ≥ rule stratum '${ruleStratum}'"
          else
            v
        ) ctx;
      # A universal entry stand-in: passes requireEntry (has id_hash) so probing a policy that forwards ctx
      # entries into constructors succeeds without touching any real registry. `sentinelFields` enriches it
      # with caller-supplied coord fields. CEILING: a field must be TYPE-CORRECT NON-MATCHING — a string
      # field gets a string sentinel ("«probe»"), an attrset-typed field an empty-attrset sentinel, etc.
      # (a string where an attrset is expected would just move the crash); and a policy reading an
      # UN-ENRICHED field still hard-fails LOUDLY (self-announcing → extend the set).
      probeEntry = {
        id_hash = "«probe»";
        name = "«probe»";
      }
      // sentinelFields;

      # A policy value's gate + body. A record `{ __condition; fn }` declares its gate (a coord set in
      # the `functionArgs` shape); a bare function's gate is its `functionArgs`.
      isRecord = v: builtins.isAttrs v && v ? __condition;
      conditionOf = v: if isRecord v then v.__condition else builtins.functionArgs v;
      fnOf = v: if isRecord v && v ? fn then v.fn else v;

      # The A4 stratum-check + owning-policy stamp (the single-group produce — byte-identical to the
      # pre-expansion path: one policy, one stratum, checked).
      # The capability projection over a rule's base produce: the FINAL (dispatch) produce reads its ctx
      # through `projectCtx stratum`, so a ≥-stratum ctx fact throws named when the body reads it. The
      # PROBE keeps the RAW base produce (stratum-detection runs on the sentinel ctx, pre-projection).
      projectedBase =
        stratum: baseProduce: id: ctx:
        baseProduce id (projectCtx stratum ctx);
      checkedProduce =
        name: baseProduce: id: ctx:
        map (a: a // { __policy = name; }) (declare.checkStratum name (baseProduce id ctx));
      # The stamp-only produce (no single-stratum check — an expansion body may span strata, each
      # declaration self-routing by kind through the per-stratum filter below).
      stampProduce =
        name: baseProduce: id: ctx:
        map (a: a // { __policy = name; }) (baseProduce id ctx);

      # The value-less stratum probe: fill the DECLARED gate coords with a sentinel and deep-force the
      # produce, catching a sentinel-value throw as an empty probe (both → expansion).
      probeOf =
        condition: produce:
        let
          # Sentinel-fill ONLY the REQUIRED gate coords (`functionArgs` `false`). A DEFAULTED coord (`true`,
          # e.g. env-users' `accessGroups ? []`) is OMITTED so the body's declared default applies, instead of
          # a `{ id_hash; name }` sentinel entry that a list-op would choke on ("expected a list but found a
          # set" — uncatchable by tryEval). A default is the author's probe-safe value; filling only required
          # coords is a strict probe-quality improvement with no trade-off.
          requiredCoords = builtins.filter (n: !condition.${n}) (builtins.attrNames condition);
          probeCtx = prelude.genAttrs requiredCoords (_: probeEntry);
          try = builtins.tryEval (
            let
              a = produce "«probe»" probeCtx;
            in
            builtins.deepSeq a a
          );
        in
        if try.success then try.value else [ ];

      coveredStrata = [
        "structural"
        "resolution"
        "collection"
      ];
      # Per-declaration conservation guard (loud). An expansion policy may only produce covered-stratum
      # declarations. Enrich (B1 keyset-ascent feed) is seeded at the probe, which a value-conditional
      # policy never reaches — so it is a silent partition and aborts. The collection stratum is COVERED
      # only for a pure SITE-MARK pipeOp (`declare.isSiteMarkData`): site marks are per-node emission
      # DATA (fired where the policy fires — v1 register-pipe-effect.nix:15 scopedPipeEffects), NOT a
      # compose commitment, so they pass through. A DERIVED/route pipeOp is a genuine probe-time compose
      # commitment (the ONE fleet gen-pipe DAG, seeded before eval) a value-less policy cannot make → it
      # STILL aborts (posture retained for the genuine operator).
      assertCovered =
        name: a:
        let
          s = declare.stratumOf a;
        in
        if s == "collection" then
          (if declare.isSiteMarkData a then a else errors.expansionPipeOp name)
        else if s == "structural" && declare.kindOf a == "enrich" then
          errors.expansionEnrich name
        else if !(builtins.elem s coveredStrata) then
          errors.expansionUncovered name (declare.kindOf a) s
        else
          a;

      # A single-group rule (the probe emitted → its stratum is observed directly). The FINAL produce
      # projects its ctx at the observed group, so a ≥-stratum ctx fact is capability-scoped out.
      mkSingle =
        name: condition: base: probeActs:
        let
          group = declare.stratumOf (builtins.head probeActs);
        in
        {
          inherit (base) nac priority overrides;
          inherit condition group;
          produce = checkedProduce name (projectedBase group base.produce);
          identity = name;
          __isEnrich = prelude.all (
            a: declare.stratumOf a == "structural" && declare.kindOf a == "enrich"
          ) probeActs;
          __pipeOps = builtins.filter (a: (a.__action or null) == "pipeOp") probeActs;
        };

      # The expansion sub-rules (empty or throwing probe): one per covered stratum {structural,
      # resolution, collection}, each keeping only its-stratum declarations. The `__policy` stamp carries
      # the ORIGINAL name (attribution), while a `#<stratum>` identity keeps the sub-rules distinct for
      # gen-dispatch. The `#collection` sub-rule carries a value-conditional policy's per-node SITE-MARK
      # pipeOp (allowed by `assertCovered`); it still sets `__pipeOps = [ ]`, so the compose-seeding
      # producer tie-break never keys a value-conditional policy — the site-mark pipeOp is per-node
      # emission data, not a compose op — and no compiled policy declares overrides.
      mkExpanded =
        name: condition: base:
        map (s: {
          inherit (base) nac priority overrides;
          inherit condition;
          # Each sub-rule projects its ctx at ITS stratum `s` (the FINAL produce), so a value-conditional
          # policy's structural/resolution/collection sub-rules are each capability-scoped by construction.
          produce =
            let
              produce = stampProduce name (projectedBase s base.produce);
            in
            id: ctx: builtins.filter (a: declare.stratumOf a == s) (map (assertCovered name) (produce id ctx));
          identity = "${name}#${s}";
          group = s;
          __isEnrich = false;
          __pipeOps = [ ];
        }) coveredStrata;

      # `__firesAtKinds` (LAW, name-agnostic): a rule may DECLARE the node-kinds it fires at — a list of
      # kind names. The stratum dispatch PRE-FILTERS a rule out at a node whose kind is absent from the list
      # (a rule WITHOUT the annotation fires at every node). It is threaded from the policy VALUE onto EVERY
      # compiled rule (the single-group rule OR each expansion sub-rule) and SURVIVES `strip` below, so the
      # structural-stratum reader can consult it. The core stamps nothing itself — a caller (e.g. an
      # include-arm compiler) supplies the kinds; this only carries the annotation through the compile.
      # `__resolveFamily` (LAW, design note 2026-07-11 §3(ii)): the STAGED ROOT-RESOLUTION pre-pass is the
      # SOLE consumer of resolve-family declarations {member, relate}, so it must dispatch ONLY policies
      # that can emit them — dispatching an arbitrary co-firing policy body at a root risks an UNCATCHABLE
      # eval error (a missing-attribute read of a field absent from the root ctx; `tryEval` cannot catch
      # it). A rule is resolve-family iff (a) its VALUE-LESS probe already EMITTED a member/relate (a
      # single-group resolve policy — DETECTED), or (b) the emitting adapter DECLARES it via
      # `__resolveFamily = true` (the honest keyset principle — a VALUE-CONDITIONAL resolve policy, whose
      # probe is empty, cannot be detected, so intent is declared). Only the STRUCTURAL sub-rule of an
      # expansion carries it (member/relate are structural). A native/corpus fleet with NO resolve policy
      # tags NONE → the pre-pass feed is empty → inert, byte-identical.
      mkRules =
        name: v:
        let
          fn = fnOf v;
          condition = conditionOf v;
          base = dispatch.fromFunction fn;
          # Probe WITHOUT the single-stratum check (stamp only): a genuine mixed-stratum policy must
          # abort below, never be swallowed by the probe's tryEval as an empty result.
          probeActs = probeOf condition (stampProduce name base.produce);
          firesAt = prelude.optionalAttrs (v ? __firesAtKinds) { inherit (v) __firesAtKinds; };
          # DECLARED resolve-family (R2): the policy value's own `__resolveFamily` tag OR the caller-supplied
          # `resolveFamilyNames` set (the shim's corpus tag set — a v1 body carries no den-hoag tag). Either
          # marks a value-conditional resolve policy the pre-pass must dispatch (member/relate cannot be probed).
          explicitRF = (v.__resolveFamily or false) || builtins.elem name resolveFamilyNames;
          # DECLARED exclude-family (#72) — the R2 pattern's twin for `suppress` emitters.
          explicitEF = (v.__excludeFamily or false) || builtins.elem name excludeFamilyNames;
          expanded = probeActs == [ ];
          baseRules =
            if expanded then
              mkExpanded name condition base
            else
              # Non-empty probe → single-group. `checkStratum` enforces the one-stratum law on the observed
              # emission (B2); it runs OUTSIDE the probe's tryEval, so a mixed-stratum policy aborts loud
              # rather than silently expanding.
              builtins.seq (declare.checkStratum name probeActs) [ (mkSingle name condition base probeActs) ];
          # DETECTED (single-group probe emitted a member/relate) OR DECLARED (the value-conditional tag);
          # for an expansion policy only the structural sub-rule bears it (member/relate are structural).
          rfOf =
            r:
            if expanded then
              explicitRF && r.group == "structural"
            else
              explicitRF || prelude.any declare.isResolveFamily probeActs;
          # DETECTED (probe emitted a suppress) OR DECLARED — the exclude-family twin (`suppress` is a
          # structural kind, so an expansion policy's structural sub-rule bears the tag).
          efOf =
            r:
            if expanded then
              explicitEF && r.group == "structural"
            else
              explicitEF || prelude.any declare.isSuppress probeActs;
        in
        map (
          r:
          r
          // firesAt
          // {
            __resolveFamily = rfOf r;
            __excludeFamily = efOf r;
          }
        ) baseRules;

      rules = prelude.concatMap (name: mkRules name policies.${name}) (builtins.attrNames policies);
      strip =
        r:
        removeAttrs r [
          "__isEnrich"
          "__pipeOps"
          "__resolveFamily"
          "__excludeFamily"
        ];
    in
    {
      enrich = map strip (builtins.filter (r: r.__isEnrich) rules);
      policy = map strip (builtins.filter (r: !r.__isEnrich) rules);
      # The STAGED ROOT-RESOLUTION pre-pass feed (design note 2026-07-11 §3(ii)): the structural-group
      # rules that can emit resolve-family {member, relate} — detected (single-group probe) or declared
      # (`__resolveFamily` tag, value-conditional). The pre-pass (lib/staged-resolution.nix) dispatches
      # ONLY these at roots, so an arbitrary co-firing policy body is never run there. Empty for a fleet
      # with no resolve policies (the corpus at R1) → the pre-pass is inert, the fleet byte-identical.
      resolveFamily = map strip (
        builtins.filter (r: (r.__resolveFamily or false) && r.group == "structural") rules
      );
      # The EXCLUDE-FAMILY feed (#72, candidate A): the structural-group rules that can emit `suppress`
      # — detected (probe) or declared (`__excludeFamily` / `den.excludeFamilyNames`). The staged
      # pre-pass dispatches ONLY these for suppression collection; empty for an exclude-free fleet.
      excludeFamily = map strip (
        builtins.filter (r: (r.__excludeFamily or false) && r.group == "structural") rules
      );
      # The fleet-wide pipe operator declarations (collection stratum) — den-hoag threads their
      # `derived` channels + routes into the ONE gen-pipe compose (default.nix `policyOps`). Only
      # single-group (probe-emitting) policies contribute (their `__pipeOps`): the derived-op DAG + the
      # delivery routes are ctx-INDEPENDENT compose commitments seeded before eval. An expansion
      # (value-conditional) policy contributes NOTHING here — `__pipeOps = [ ]` on every sub-rule. A
      # DERIVED/route pipeOp from such a policy aborts (`errors.expansionPipeOp`, ctx-independence
      # contract); a pure SITE-MARK pipeOp is per-node emission data (allowed through the `#collection`
      # sub-rule) and correctly seeds no compose op.
      pipeOps = prelude.concatMap (r: r.__pipeOps) rules;
    };
in
{
  # Default sentinel (the universal `{ id_hash; name }`) + no resolve-family tags — byte-identical to the
  # pre-configurable behavior for every existing caller (native fleets, the unit suites driving
  # `internal.compilePolicies`); a native fleet's resolve-family policies are DETECTED, not tagged.
  compile = compileWith { } [ ] [ ];
  inherit compileWith compileWithStrata;
}
