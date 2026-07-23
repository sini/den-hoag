# The reserved-vocabulary-table compile combinator (Law A1). Three registries — den.products,
# den.disciplines, den.edges — share ONE shape: a framework `reserved` seed UNIONED under a user
# `table`, each row `mapAttrs`-validated by `entryOf`, with a NAMED abort when a user row re-registers
# a framework-reserved name. The seed's KEYSET is the reserved set (a colliding user name aborts) AND
# the seed VALUES pre-populate the table — one param drives both the offender test and the merge. This
# util holds ZERO product/discipline/edge knowledge (every specific arrives as a param) and closes over
# `prelude` only. NO EFFECT RUNTIME: one mapAttrs + a validation fold, no algorithm.
{
  prelude,
}:
{
  # mkReservedRegistry — the shared reserved-vocabulary-table compile. `extraGuards` are further
  # pre-compile reserved-vocabulary guards (e.g. a reserved prefix namespace), checked AFTER the reserved
  # guard IN ORDER — the first guard with a non-empty `offenders` list aborts with its `message` (a
  # `head -> string` fn, so the offender name lands inside the exact per-site string). A post-compile
  # validation (e.g. edges' stratum check) stays at the CALL SITE, wrapping this result.
  mkReservedRegistry =
    {
      subject, # error prefix, e.g. "den.products"
      noun, # the entity word, e.g. "product"
      reserved, # the framework seed attrset (keyset = reserved set, values = seed rows)
      entryOf, # name: raw: <compiled entry>  (pre-curried with any deps)
      table ? { }, # the user vocabulary table
      extraGuards ? [ ], # [ { offenders = [string]; message = head: string; } ] — extra pre-compile guards
    }:
    let
      reservedGuard = {
        offenders = builtins.filter (n: reserved ? ${n}) (builtins.attrNames table);
        message = h: "${subject}: ${noun} '${h}' is framework-reserved";
      };
      guards = [ reservedGuard ] ++ extraGuards;
      # first guard with a non-empty `offenders` — reproduces the `if … else if …` chain order exactly.
      firstOffense = prelude.foldl' (
        acc: g:
        if acc != null then
          acc
        else if g.offenders != [ ] then
          g
        else
          null
      ) null guards;
      allRaw = reserved // table;
    in
    if firstOffense != null then
      throw (firstOffense.message (builtins.head firstOffense.offenders))
    else
      prelude.mapAttrs entryOf allRaw;
}
