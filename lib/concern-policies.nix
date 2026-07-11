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
  # `compileWith sentinelFields policies` — compile with a CONFIGURABLE probe sentinel. `sentinelFields`
  # merges onto the universal `{ id_hash; name }` stand-in, so a caller that KNOWS a policy body reads a
  # coord FIELD on the sentinel (a consumer's corpus fact) can supply a TYPE-CORRECT NON-MATCHING value for it:
  # the body then takes its value-conditional FALSE branch (→ expansion, the conservative branch) instead of
  # hard-failing on a missing attribute. `compile` = the default `{ }` (the universal sentinel), byte-
  # identical for every native caller. Core stays FIELD-AGNOSTIC (no den field names here); the CONSUMER
  # supplies the fields it knows its own policy bodies read.
  compileWith =
    sentinelFields: policies:
    let
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

      # A single-group rule (the probe emitted → its stratum is observed directly).
      mkSingle = name: condition: base: probeActs: {
        inherit (base) nac priority overrides;
        inherit condition;
        produce = checkedProduce name base.produce;
        identity = name;
        group = declare.stratumOf (builtins.head probeActs);
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
        let
          produce = stampProduce name base.produce;
        in
        map (s: {
          inherit (base) nac priority overrides;
          inherit condition;
          produce =
            id: ctx: builtins.filter (a: declare.stratumOf a == s) (map (assertCovered name) (produce id ctx));
          identity = "${name}#${s}";
          group = s;
          __isEnrich = false;
          __pipeOps = [ ];
        }) coveredStrata;

      mkRules =
        name: v:
        let
          fn = fnOf v;
          condition = conditionOf v;
          base = dispatch.fromFunction fn;
          # Probe WITHOUT the single-stratum check (stamp only): a genuine mixed-stratum policy must
          # abort below, never be swallowed by the probe's tryEval as an empty result.
          probeActs = probeOf condition (stampProduce name base.produce);
        in
        if probeActs == [ ] then
          mkExpanded name condition base
        else
          # Non-empty probe → single-group. `checkStratum` enforces the one-stratum law on the observed
          # emission (B2); it runs OUTSIDE the probe's tryEval, so a mixed-stratum policy aborts loud
          # rather than silently expanding.
          builtins.seq (declare.checkStratum name probeActs) [ (mkSingle name condition base probeActs) ];

      rules = prelude.concatMap (name: mkRules name policies.${name}) (builtins.attrNames policies);
      strip =
        r:
        removeAttrs r [
          "__isEnrich"
          "__pipeOps"
        ];
    in
    {
      enrich = map strip (builtins.filter (r: r.__isEnrich) rules);
      policy = map strip (builtins.filter (r: !r.__isEnrich) rules);
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
  # Default sentinel (the universal `{ id_hash; name }`) — byte-identical to the pre-configurable behavior
  # for every existing caller (native fleets, the unit suites driving `internal.compilePolicies`).
  compile = compileWith { };
  inherit compileWith;
}
