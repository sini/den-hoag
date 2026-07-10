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
# produce on a sentinel context (every gate coord filled with a sentinel entry), which yields the
# produced kinds' stratum. The probe is FORMAL-PRESERVING (it fills the DECLARED gate, so a record's
# bare-ctx body sees its coords) and tryEval-GUARDED: a body doing value-work against the sentinel
# that reaches a `throw`/`assert` (e.g. a constructor's identity-law abort) is caught and treated
# IDENTICALLY to an empty probe — both route to the per-declaration EXPANSION path. HONEST LIMIT:
# `tryEval` cannot catch a non-recoverable eval error (missing attribute, head-of-empty), so a body
# that field-accesses/iterates a sentinel coord bare still fails the probe HARD — loudly, pointing at
# the probe (the documented pre-record failure mode). A value-conditional body reaches its coords via
# `or` defaults (the corpus idiom), which yields the clean empty-probe path.
#
# EXPANSION (the value-conditional path). When the probe observes no emission the stratum cannot be
# read up front — the policy's emission is gated on a ctx VALUE, so it emits nothing at the value-less
# sentinel. Rather than guess ONE stratum (the silent-partition sin), the policy is expanded into one
# sub-rule per COVERED stratum {structural, resolution}: each fires at the SAME gated nodes and keeps
# only its-stratum declarations, so every declaration is produced in ITS stratum's phase with that
# phase's context — the one-rule/one-stratum law holds PER SUB-RULE while the policy's declarations
# self-route by kind (B2's readers pull `actions.<stratum>` by kind, independent of the producing
# rule). Expansion is the CONSERVATIVE branch: a policy misclassified INTO it still fires correctly at
# real coord values; misclassifying a value-conditional policy OUT of it (as a fixed single stratum)
# would mis-place its declarations. An expansion policy that produces an enrich- or pipeOp- (or other
# uncovered-stratum) declaration at dispatch aborts LOUD (`errors.expansion*`): those are probe-time
# feed/compose commitments a value-less policy cannot make.
{
  prelude,
  dispatch,
  declare,
  errors,
}:
{
  compile =
    policies:
    let
      # A universal entry stand-in: passes requireEntry (has id_hash) so probing a policy that
      # forwards ctx entries into constructors succeeds without touching any real registry.
      probeEntry = {
        id_hash = "«probe»";
        name = "«probe»";
      };

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
          probeCtx = prelude.genAttrs (builtins.attrNames condition) (_: probeEntry);
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
      ];
      # Per-declaration conservation guard (loud): an expansion policy may only produce covered-stratum
      # declarations. Enrich (B1 keyset-ascent feed) and pipeOp (the fleet compose DAG) are seeded at
      # the probe, which a value-conditional policy never reaches — so either kind is a silent partition.
      assertCovered =
        name: a:
        let
          s = declare.stratumOf a;
        in
        if s == "collection" then
          errors.expansionPipeOp name
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

      # The expansion sub-rules (empty or throwing probe): one per covered stratum, each keeping only
      # its-stratum declarations. The `__policy` stamp carries the ORIGINAL name (attribution), while a
      # `#<stratum>` identity keeps the sub-rules distinct for gen-dispatch (override/tie-break machinery
      # never keys a value-conditional policy: it emits no pipeOp, so the pipe producer tie-break never
      # sees these ids, and no compiled policy declares overrides).
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
      # single-group (probe-emitting) policies contribute; an expansion policy that produces a pipeOp
      # aborts (a value-conditional `pipe.from` breaks the ctx-independence contract).
      pipeOps = prelude.concatMap (r: r.__pipeOps) rules;
    };
}
