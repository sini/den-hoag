# den.derived — laws-gated synthesized attributes over the resolution graph (spec §5). A derived
# `<name> = { over; direction; stratum; provides; discipline; closure; derive }` reads the relation graph (via
# the per-node accessor) and synthesizes a value, capability-scoped by its `stratum` and laws-gated by its
# `closure`/`discipline`. This file holds the DEFINITION-TIME field validation (the compute engine + the
# stratum-gate + the closure-gate routing are later rungs).
{
  prelude,
}:
let
  # index of `x` in the ordered list `xs`, or -1 if absent (the strata-order comparison for the §2.3 gate).
  indexOf =
    xs: x:
    let
      go =
        i: rest:
        if rest == [ ] then
          -1
        else if builtins.head rest == x then
          i
        else
          go (i + 1) (builtins.tail rest);
    in
    go 0 xs;

  # derivedFieldMessage — the DEFINITION-TIME field validator as a VALUE (`null` = clean, else the NAMED message),
  # so the NAMED contract is CI-testable (Nix's `tryEval` cannot capture a throw's text). It checks each declared
  # derived's fields against the fleet's relations / strata order / products. `relationKinds` is the desugared
  # relation edge-kinds (keyed by relation name, carrying `inverse` + `stratum`). Guards are an ordered chain —
  # `over`-validity first (later guards read `relationKinds.<rel>`), then the stratum guards (the §2.3
  # capability-scope law), the reverse-direction guard, and the `provides` product membership.
  derivedFieldMessage =
    {
      deriveds,
      relationKinds,
      strataOrder,
      productNames,
    }:
    let
      relationNames = builtins.attrNames relationKinds;
      checkOne =
        name: spec:
        let
          over = spec.over or [ ];
          direction = spec.direction or "forward";
          stratum = spec.stratum or null;
          provides = spec.provides or null;
          strat = if builtins.isString stratum then stratum else "<none>";
          unknownRel = builtins.filter (r: !(builtins.elem r relationNames)) over;
          # (past guard (a)) the strata the `over` relations sit at; a derive must sit strictly LATER.
          overStrata = map (r: relationKinds.${r}.stratum) over;
          notLater = builtins.any (s: indexOf strataOrder stratum <= indexOf strataOrder s) overStrata;
          reverseInverseless =
            direction == "reverse" && builtins.any (r: (relationKinds.${r}.inverse or null) == null) over;
        in
        if unknownRel != [ ] then
          "den.derived: '${name}' over names unknown relation '${builtins.head unknownRel}' — not a relation in den.relations (§5)"
        else if !(builtins.isString stratum) || !(builtins.elem stratum strataOrder) then
          "den.derived: '${name}' names unknown stratum '${strat}' — not in the compiled strata order (§2.3)"
        else if notLater then
          "den.derived: '${name}' stratum '${stratum}' is not LATER than the strata its `over` relations sit at — a derive reads strata below its own (§2.3)"
        else if reverseInverseless then
          "den.derived: '${name}' direction = \"reverse\" over a relation whose `inverse` is null — the reverse read would be silently empty; declare the relation's inverse (§5)"
        else if provides != null && !(builtins.elem provides productNames) then
          "den.derived: '${name}' provides '${provides}', which is not a product registered in den.products (§4.1)"
        else
          null;
      offenders = builtins.filter (m: m != null) (prelude.mapAttrsToList checkOne deriveds);
    in
    if offenders == [ ] then null else builtins.head offenders;
in
{
  inherit derivedFieldMessage;
}
