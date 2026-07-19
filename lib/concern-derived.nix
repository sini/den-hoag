# den.derived — laws-gated synthesized attributes over the resolution graph (spec §5). A derived
# `<name> = { over; direction; stratum; provides; discipline; closure; derive }` reads the relation graph (via
# the per-node accessor) and synthesizes a value, capability-scoped by its `stratum` and laws-gated by its
# `closure`/`discipline`. This file holds the DEFINITION-TIME field validation — the field guards plus the
# closure/discipline laws-gate (guard f) — the per-node compute engine, and the stratum-gate.
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
  # capability-scope law), the reverse-direction guard, the `provides` product membership, and a `derive`
  # presence check LAST (a missing `derive` would otherwise be an uncatchable `spec.derive` attr-miss the moment
  # `derivedAt` forces it — the same uncatchable class as the unknown-name guard, made catchable at definition).
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
        else if !(spec ? derive) then
          "den.derived: '${name}' declares no `derive` — a derived must declare a `derive = node: deps: …` function (§5)"
        else
          null;
      offenders = builtins.filter (m: m != null) (prelude.mapAttrsToList checkOne deriveds);
    in
    if offenders == [ ] then null else builtins.head offenders;

  # the `deps` placeholder message — the requires/provides VALUE-composition (spec §5) has no consumer in this
  # facet, so a derive that reads `deps` aborts with this NAMED throw rather than silently seeing an empty set.
  depsPlaceholderMessage = "den.derived: `deps` — the requires/provides value-composition (§5) has no consumer in this facet; a derive must not read it here";

  # mkDerived — the per-node compute engine (§5): `derivedAt <name> <nodeId>` = `spec.derive node deps`, a LAZY
  # per-node accessor (the mkRelAccessor posture — a plain `name: id:` fn, NOT a cross-call memo table). `node` is
  # the capability handle `{ rel = relAt id; id = id; }` (the per-node relation binding); the derive body reads
  # relations via `node.rel.<kind>.{targets;inverse;closure}` (forward = targets, reverse = inverse). `over` /
  # `direction` are DECLARATIVE metadata (definition-time validated by derivedFieldMessage); `node.rel` exposes
  # ALL relation kinds regardless of `over`, so the stratum-gate (the gatedRel projection below), not `over`, is
  # the real read-enforcement. `deps` is a throw-on-read placeholder — honest + loud, never a silent `{}`. `derivedIndex`
  # is the name→spec registry (`den.derived` itself), so `spec = derivedIndex.${name}`.
  mkDerived =
    {
      relAt,
      derivedIndex,
      relationKinds,
      strataOrder,
    }:
    name: id:
    let
      # a typo'd name is a raw attr-select miss (tryEval-UNCATCHABLE) on a public accessor reachable from user
      # input — convert it to a NAMED catchable throw (the `or (throw …)` idiom, extractMemberProduct's posture).
      spec =
        derivedIndex.${name}
          or (throw "den.derived: no such derived '${name}' — not a name declared in den.derived (§5)");
      # the stratum-gate (§2.3, the projectCtx throw-on-read pattern): node.rel exposes ONLY relation kinds whose
      # stratum sits STRICTLY BELOW the derive's own — reading a kind tagged stratum ≥ the derive's stratum is
      # REPLACED with a NAMED throw (enforcement-by-construction, never introspection: the derive cannot read a
      # fact at or above its own layer). Each kind carries its relation's stratum (relationKinds.${kind}.stratum).
      # The gate wraps `node.rel` ONLY — `node.id` is a sibling of `rel` (a plain string, never routed through
      # gatedRel), so it always passes.
      deriveStratum = spec.stratum;
      deriveStratumIdx = indexOf strataOrder deriveStratum;
      gatedRel = builtins.mapAttrs (
        kind: entry:
        let
          kindStratum = relationKinds.${kind}.stratum or null;
        in
        if kindStratum != null && indexOf strataOrder kindStratum >= deriveStratumIdx then
          throw "den.derived: '${name}' at stratum '${deriveStratum}' may not read relation '${kind}' — it is stratum '${kindStratum}' ≥ the derive's own (a derive reads strata strictly below its own, §2.3)"
        else
          entry
      ) (relAt id);
      node = {
        rel = gatedRel;
        inherit id;
      };
      deps = throw depsPlaceholderMessage;
    in
    spec.derive node deps;

  # derivedClosureMessage — guard (f) as a VALUE-DETECTOR (mirrors derivedFieldMessage): null when every declared
  # derived's `{ closure; discipline }` is lawful, else the first NAMED message. Validated by the SHARED edges
  # `closureMessage` (§2.2 — one source of truth for the closure-capability law: a closure=true derive needs a
  # REGISTERED join-semilattice discipline), with `subject = "den.derived:"` so the message names the derived
  # surface, not the edge registry. A definition-time field gate (run at registry compile, NOT inside the compute
  # engine). The `set-union` discipline + the `AclInfo` product + the `aclClosure` value-composition that CONSUME a
  # closure derive are a downstream resolution-facet concern (§5).
  derivedClosureMessage =
    {
      closureMessage,
      disciplines,
      deriveds,
    }:
    let
      offenders = builtins.filter (m: m != null) (
        prelude.mapAttrsToList (
          name: spec:
          closureMessage disciplines {
            subject = "den.derived:";
            inherit name;
            closure = spec.closure or false;
            discipline = spec.discipline or null;
          }
        ) deriveds
      );
    in
    if offenders == [ ] then null else builtins.head offenders;
in
{
  inherit
    derivedFieldMessage
    derivedClosureMessage
    depsPlaceholderMessage
    mkDerived
    ;
}
