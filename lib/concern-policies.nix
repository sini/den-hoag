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

      mkRule =
        name: fn:
        let
          base = dispatch.fromFunction fn;
          produce =
            id: ctx:
            let
              acts = declare.checkStratum name (base.produce id ctx);
            in
            map (a: a // { __policy = name; }) acts;
          probeCtx = prelude.genAttrs (builtins.attrNames base.condition) (_: probeEntry);
          probeActs = produce "«probe»" probeCtx;
          stratum = if probeActs == [ ] then "structural" else declare.stratumOf (builtins.head probeActs);
          isEnrich =
            probeActs == [ ]
            || prelude.all (a: declare.stratumOf a == "structural" && declare.kindOf a == "enrich") probeActs;
        in
        {
          inherit (base)
            condition
            nac
            priority
            overrides
            ;
          inherit produce;
          identity = name;
          # REQUIRED by gen-dispatch: multi-group dispatch (attr 4's stratified groupOrder)
          # throws on rules without an explicit group — this is lib contract, not metadata.
          group = stratum;
          __isEnrich = isEnrich;
          # The collection-stratum `pipeOp` declarations this policy produces (an external consumer's compiled
          # `pipe.from name [stages]`). The gen-pipe op DAG (`derived`/`routes`) rides the SAME sentinel
          # probe already run above — a `pipe.from` body is ctx-INDEPENDENT (its stages are static
          # closures), so the probe yields the pipeOp regardless of where the policy dispatches. Surfaced
          # here (not only per-node) because the fleet gen-pipe `compose` is ONE static DAG, seeded before
          # the eval — the derived channels + routes must join it fleet-wide (the demand-channel seam),
          # exactly like `den.quirks` ops, never per-firing-scope.
          __pipeOps = builtins.filter (a: (a.__action or null) == "pipeOp") probeActs;
        };

      rules = prelude.mapAttrsToList mkRule policies;
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
      # `derived` channels + `routes` into the ONE gen-pipe compose (default.nix `policyOps`), so a
      # compiled `pipe.from` transform/filter/fold/route is CONSUMED (before this, it compiled but never
      # reached the DAG). Site `marks` (append/expose/collect/broadcast) are per-scope emission wiring,
      # not compose ops, and stay on the per-node declaration.
      pipeOps = prelude.concatMap (r: r.__pipeOps) rules;
    };
}
