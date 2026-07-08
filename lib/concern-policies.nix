# Compile `den.policies.<name> = ctxFn` into gen-dispatch rules, partitioned into the two feeds
# the structural stratum consumes: `enrich` (attr 2's keyset-ascent fixpoint) and `policy`
# (attr 4's one-shot, stratified rule evaluation). Each rule is `gen-dispatch.fromFunction` — its
# `functionArgs` are the canTake guard, so a policy fires only when every destructured ctx key is
# present (a channel-named arg, never a ctx key, therefore never fires). The produce is wrapped to
# run the A4 stratum check (`declare.checkStratum`) and stamp the owning policy (`__policy`).
#
# A rule's STRATUM is read once by probing produce on a sentinel context — every guard key filled
# with a sentinel entry, so the constructors' identity-law checks pass and the produced kinds are
# readable. This is a pure, terminating classification (a `map`/`filter`, not a runtime loop): it
# yields the rule's `group` (attr 4 dispatches stratified over `declare.strata`) and whether the
# rule is a pure-enrich writer (all declarations structural `enrich`), which selects its feed.
# FAILURE MODE: this assumes the den pattern — a policy body forwards its ctx entries straight into
# declaration constructors. A body that instead does NON-entry work on a ctx value (list iteration,
# integer math, any type-dependent op) throws against the sentinel entry during this definition-time
# probe, with an error pointing at the probe rather than the real call site.
{
  prelude,
  dispatch,
  declare,
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

      mkRules =
        name: fn:
        let
          base = dispatch.fromFunction fn;
          produceRaw =
            id: ctx:
            map (a: a // { __policy = name; }) (base.produce id ctx);
          
          probeCtx = prelude.genAttrs (builtins.attrNames base.condition) (_: probeEntry) // {
            __isProbe = true;
          };
          res = builtins.tryEval (produceRaw "«probe»" probeCtx);
          probeSuccess = res.success;
          probeActs = if probeSuccess then res.value else [ ];
          
          isEnrich =
            if fn ? __isEnrich then
              fn.__isEnrich
            else if probeSuccess && probeActs != [ ] then
              prelude.all (a: declare.stratumOf a == "structural" && declare.kindOf a == "enrich") probeActs
            else
              false;
              
          mk = suffix: group: filterFn: {
            inherit (base) condition nac priority overrides;
            identity = "${name}_${suffix}";
            inherit group;
            produce = id: ctx: builtins.filter filterFn (produceRaw id ctx);
          };
          
          enrichRules =
            if isEnrich then
              [ (mk "enrich" "structural" (a: declare.stratumOf a == "structural" && declare.kindOf a == "enrich")) ]
            else
              [ ];
              
          policyRules =
            if isEnrich then
              [ ]
            else
              let
                hasStructural = (!probeSuccess) || probeActs == [ ] || prelude.any (a: declare.stratumOf a == "structural") probeActs;
                hasResolution = (!probeSuccess) || probeActs == [ ] || prelude.any (a: declare.stratumOf a == "resolution") probeActs;
                hasCollection = (!probeSuccess) || probeActs == [ ] || prelude.any (a: declare.stratumOf a == "collection") probeActs;
                hasDemand = (!probeSuccess) || probeActs == [ ] || prelude.any (a: declare.stratumOf a == "demand") probeActs;
              in
              (if hasStructural then [ (mk "policy" "structural" (a: declare.stratumOf a == "structural" && declare.kindOf a != "enrich")) ] else [ ]) ++
              (if hasResolution then [ (mk "resolution" "resolution" (a: declare.stratumOf a == "resolution")) ] else [ ]) ++
              (if hasCollection then [ (mk "collection" "collection" (a: declare.stratumOf a == "collection")) ] else [ ]) ++
              (if hasDemand then [ (mk "demand" "demand" (a: declare.stratumOf a == "demand")) ] else [ ]);
              
          __pipeOps = builtins.filter (a: (a.__action or null) == "pipeOp") probeActs;
        in
        {
          inherit enrichRules policyRules __pipeOps;
        };

      rulesSets = prelude.mapAttrsToList mkRules policies;
    in
    {
      enrich = prelude.concatMap (s: s.enrichRules) rulesSets;
      policy = prelude.concatMap (s: s.policyRules) rulesSets;
      # The fleet-wide pipe operator declarations (collection stratum) — den-hoag threads their
      # `derived` channels + `routes` into the ONE gen-pipe compose (default.nix `policyOps`), so a
      # compiled `pipe.from` transform/filter/fold/route is CONSUMED (before this, it compiled but never
      # reached the DAG). Site `marks` (append/expose/collect/broadcast) are per-scope emission wiring,
      # not compose ops, and stay on the per-node declaration.
      pipeOps = prelude.concatMap (s: s.__pipeOps) rulesSets;
    };
}
