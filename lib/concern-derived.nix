# den.derived — laws-gated synthesized attributes over the resolution graph (spec §5). A derived
# `<name> = { over; direction; stratum; provides; discipline; closure; negates ? [ ]; derive }` reads the relation graph (via
# the per-node accessor) and synthesizes a value, capability-scoped by its `stratum` and laws-gated by its
# `closure`/`discipline`. This file holds the DEFINITION-TIME field validation — the field guards plus the
# closure/discipline laws-gate (guard f) — the per-node compute engine, and the stratum-gate.
{
  prelude,
  strataScope,
}:
let
  # the strata-order position + strictly-below primitives (§2.3), shared with the relation accessors.
  inherit (strataScope) indexOf strataLt;

  # derivedFieldMessage — the DEFINITION-TIME field validator as a VALUE (`null` = clean, else the NAMED message),
  # so the NAMED contract is CI-testable (Nix's `tryEval` cannot capture a throw's text). It checks each declared
  # derived's fields against the fleet's relations / strata order / resolution products. `relationKinds` is the
  # desugared relation edge-kinds (keyed by relation name, carrying `inverse` + `stratum`). Guards are an ordered
  # chain — `over`-validity first (later guards read `relationKinds.<rel>`), then the stratum guards (the §2.3
  # capability-scope law), the reverse-direction guard, the `provides` resolution-product membership, and a `derive`
  # presence check LAST (a missing `derive` would otherwise be an uncatchable `spec.derive` attr-miss the moment
  # `derivedAt` forces it — the same uncatchable class as the unknown-name guard, made catchable at definition).
  derivedFieldMessage =
    {
      deriveds,
      relationKinds,
      strataOrder,
      resolutionProductNames,
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
          # `negates` (L4) — the relation kinds this derive reads under NEGATION (§2.3 stratified negation). A NEW
          # optional field, default `[ ]`: INERT on a derive that omits it (both negation guards below skip). The
          # precursor Phase-5's `exclude`/lockdown consumes.
          negates = spec.negates or [ ];
          strat = if builtins.isString stratum then stratum else "<none>";
          unknownRel = builtins.filter (r: !(builtins.elem r relationNames)) over;
          # (past guard (a)) the strata the `over` relations sit at; a derive must sit strictly LATER — reject
          # when its stratum is NOT strictly above some `over` relation's (`!(s ≺ stratum)` = `stratum ≼ s`).
          overStrata = map (r: relationKinds.${r}.stratum) over;
          notLater = builtins.any (s: !(strataLt strataOrder s stratum)) overStrata;
          reverseInverseless =
            direction == "reverse" && builtins.any (r: (relationKinds.${r}.inverse or null) == null) over;
          # (L4 (a) throwing-gate routing) a NEGATED predicate must be read through the THROWING gate (node.rel,
          # which throws on out-of-scope), NEVER the silent-empty node.query (an out-of-scope follow yields `[]`).
          # Structurally: a `negates` entry must be a relation KIND (a node.rel key). A non-relation predicate —
          # e.g. an inverse LABEL, query-reachable via swapped edges but NOT a node.rel key — is reachable ONLY via
          # the silent route, and a negation over a silently-empty predicate cannot distinguish "absent" from
          # "out-of-scope" (unsound, Apt–Blair–Walker §2.3). So a non-relation `negates` entry is rejected.
          negatesUnroutable = builtins.filter (r: !(builtins.elem r relationNames)) negates;
          # (L4 (b) strictly-above) a negation reads a COMPLETE predicate, so the derive must sit STRICTLY ABOVE
          # every producer of each negated relation (reading it before it is fully produced is non-monotone). The
          # SAME strictly-below ceiling the positive `over` read enforces, made EXPLICIT for negation — reject when
          # some negated relation's stratum is NOT strictly below the derive's own (only reached once `negates`
          # entries are known relations, so `relationKinds.${r}.stratum` is total).
          negatesStrata = map (r: relationKinds.${r}.stratum) negates;
          negatesNotAbove = builtins.any (s: !(strataLt strataOrder s stratum)) negatesStrata;
        in
        if unknownRel != [ ] then
          "den.derived: '${name}' over names unknown relation '${builtins.head unknownRel}' — not a relation in den.relations (§5)"
        else if !(builtins.isString stratum) || !(builtins.elem stratum strataOrder) then
          "den.derived: '${name}' names unknown stratum '${strat}' — not in the compiled strata order (§2.3)"
        else if notLater then
          "den.derived: '${name}' stratum '${stratum}' is not LATER than the strata its `over` relations sit at — a derive reads strata below its own (§2.3)"
        else if reverseInverseless then
          "den.derived: '${name}' direction = \"reverse\" over a relation whose `inverse` is null — the reverse read would be silently empty; declare the relation's inverse (§5)"
        else if negatesUnroutable != [ ] then
          "den.derived: '${name}' negates '${builtins.head negatesUnroutable}', which is not a relation in den.relations — a negated predicate must be read through the THROWING gate (node.rel), never the silent-empty node.query; a negation over a silently-empty predicate cannot distinguish absent from out-of-scope (§2.3 stratified negation)"
        else if negatesNotAbove then
          "den.derived: '${name}' stratum '${stratum}' is not strictly above the strata its `negates` relations sit at — a negation reads a COMPLETE predicate, so a negated relation must be produced strictly below the derive's own stratum (§2.3 stratified negation)"
        else if provides != null && !(builtins.elem provides resolutionProductNames) then
          "den.derived: '${name}' provides '${provides}', which is not a resolution product registered in den.resolutionProducts (§5)"
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
  # the capability handle `{ rel = relAt id; id = id; query = …; }` (the per-node relation binding); the derive body
  # reads relations via `node.rel.<kind>.{targets;inverse;closure}` (forward = targets, reverse = inverse) and runs
  # arbitrary §3 follow-grammar queries via `node.query`. `over` / `direction` are DECLARATIVE metadata (definition-
  # time validated by derivedFieldMessage); `node.rel` exposes ALL relation kinds regardless of `over`, so the
  # stratum-gate (the gatedRel projection below), not `over`, is the real read-enforcement. `deps` is a throw-on-read
  # placeholder — honest + loud, never a silent `{}`. `derivedIndex` is the name→spec registry (`den.derived`
  # itself), so `spec = derivedIndex.${name}`.
  #
  # `node.query args` (§3 over §2.3): a `denQuery` over `relationEdges` SCOPED to relations at strata STRICTLY BELOW
  # the derive's own — the SAME capability boundary gatedRel enforces per-kind, but applied to the query SOURCE
  # (scoping the edge list scopes the capability). The caller supplies `from`/`follow`/`mode`/… ; the `edges` arg is
  # framework-forced (the rightmost `//` wins), so a caller cannot widen the source. An out-of-scope `follow`
  # yields EMPTY (the edge is silently absent from the scoped source) — the query MODE difference from node.rel,
  # which THROWS: a query is an exploratory read whose out-of-capability reach is naturally empty, not an error.
  mkDerived =
    {
      relAt,
      derivedIndex,
      relationKinds,
      strataOrder,
      relationEdges,
      denQuery,
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
      # fact at or above its own layer). `strataScope.ceilingGate` holds the `>= ceilingIdx` arithmetic; the gate
      # wraps `node.rel` ONLY — `node.id` is a sibling of `rel` (a plain string, never gated), so it always passes.
      deriveStratum = spec.stratum;
      deriveStratumIdx = indexOf strataOrder deriveStratum;
      gatedRel =
        strataScope.ceilingGate
          {
            inherit strataOrder relationKinds;
          }
          {
            inherit name;
            stratum = deriveStratum;
            ceilingIdx = deriveStratumIdx;
          }
          (relAt id);
      # the STRATUM-SCOPED query source (§2.3): every relation edge whose stratum sits STRICTLY BELOW the derive's
      # own — the same boundary gatedRel gates per-kind, applied to the edge list (`strataScope.edgesBelowStratum`).
      # An out-of-scope (≥ own stratum) or unknown-label edge is SILENTLY excluded (no throw — the query mode is
      # exploratory, its out-of-capability reach is naturally empty).
      scopedEdges = strataScope.edgesBelowStratum {
        inherit strataOrder relationKinds relationEdges;
      } deriveStratumIdx;
      node = {
        rel = gatedRel;
        inherit id;
        # `edges` is framework-forced (rightmost `//` wins): the caller cannot widen the scoped source.
        query = args: denQuery (args // { edges = scopedEdges; });
      };
      deps = throw depsPlaceholderMessage;
    in
    spec.derive node deps;

  # derivedClosureMessage — guard (f) as a VALUE-DETECTOR (mirrors derivedFieldMessage): null when every declared
  # derived's `{ closure; discipline }` is lawful, else the first NAMED message. Validated by the SHARED edges
  # `closureMessage` (§2.2 — one source of truth for the closure-capability law: a closure=true derive needs a
  # REGISTERED join-semilattice discipline), with `subject = "den.derived:"` so the message names the derived
  # surface, not the edge registry. A definition-time field gate (run at registry compile, NOT inside the compute
  # engine). The `set-union` discipline, the `AclInfo`/`DepInfo` resolution products, and the `aclClosure`/`depClosure`
  # witnesses that CONSUME a closure derive are DELIVERED — the resolution-facet capstone (§5, `ci/tests/acl.nix`).
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
