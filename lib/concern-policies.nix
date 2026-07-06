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
# yields the rule's `phase` (attr 4 dispatches stratified over `declare.strata`) and whether the
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
          # REQUIRED by gen-dispatch: multi-phase dispatch (attr 4's stratified phaseOrder)
          # throws on rules without an explicit phase — this is lib contract, not metadata.
          phase = stratum;
          __isEnrich = isEnrich;
        };

      rules = prelude.mapAttrsToList mkRule policies;
      strip = r: removeAttrs r [ "__isEnrich" ];
    in
    {
      enrich = map strip (builtins.filter (r: r.__isEnrich) rules);
      policy = map strip (builtins.filter (r: !r.__isEnrich) rules);
    };
}
