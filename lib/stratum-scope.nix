# stratum-scope — the capability-scope arithmetic over a stratified relation graph (spec §2.3). The law is
# Apt, Blair & Walker (1988), "Stratified Programs", Definition 3, p. 96, and it is ASYMMETRIC: a relation
# symbol occurring POSITIVELY in a clause at stratum `i` has its definition within `⋃_{j ≤ i}` (condition 1);
# one occurring NEGATIVELY has its definition within `⋃_{j < i}` (condition 2). Same-stratum POSITIVE reads
# are admitted; only negation is pushed strictly downward.
#
# Polarity is NOT observable at a runtime read — `node.rel` and `node.query` differ in LOUDNESS, not in
# polarity — so a runtime guard must implement the rule that is correct for the reads it can actually
# distinguish, and the only reads it can distinguish are all reads, for which condition 1 is the law. The
# guards here therefore take an ADMITTANCE PREDICATE rather than a fixed operator, and every shipped runtime
# instantiation takes condition 1. Condition 2 is enforced where polarity IS written down: the `negates`
# registration check (concern-derived.nix), whose predicate is `strataLt` below.
#
# Two primitives split the boundary: `edgesWithin` is the SILENT filter (an out-of-scope edge is absent, the
# exploratory-query mode) and `gateWithin` is the LOUD projection (reading an out-of-scope relation is
# REPLACED with a NAMED throw, the capability-by-construction mode). Both read a relation's stratum via
# `relationStratumOf`, total over BOTH a forward kind and a swapped inverse LABEL (§2.2 — a relation and its
# inverse share ONE stratum). Extracted from `mkDerived`'s inline block so the accessors
# (`mkRelAccessor`/`mkRelQuery`) and the derive compute share ONE stratum-ceiling primitive (no second copy
# of the admittance arithmetic).
{
  prelude,
}:
let
  # index of `x` in the ordered list `xs`, or -1 if absent (the strata-order position for the §2.3
  # comparison) — `prelude.indexOf` (list-first, `-1` absent).
  inherit (prelude) indexOf;

  # The two admittance predicates, over strata-order INDICES. An absent stratum (indexOf -1) compares below
  # every present one under both. These are the whole of the asymmetry: one expression per ABW condition,
  # so a guard names the law it applies rather than spelling an operator.
  admitPositive = i: ceiling: i <= ceiling; # Definition 3, condition 1
  admitNegative = i: ceiling: i < ceiling; # Definition 3, condition 2

  # strataLt — `a` sits STRICTLY BELOW `b` in the strata order: `admitNegative` lifted to stratum NAMES. This
  # is ABW condition 2 and it stays the predicate of the one guard that knows a read's polarity (`negates`).
  strataLt =
    strataOrder: a: b:
    admitNegative (indexOf strataOrder a) (indexOf strataOrder b);

  # strataLe — `a` sits AT OR BELOW `b`: `admitPositive` lifted to stratum NAMES, the twin of `strataLt`.
  # This is ABW condition 1, the predicate of a DECLARED positive read set (`over`).
  strataLe =
    strataOrder: a: b:
    admitPositive (indexOf strataOrder a) (indexOf strataOrder b);

  # inverse-label → relation-name index (node-independent). A relation registers ONE edge-kind `<name>`; its
  # producer ALSO emits SWAPPED edges labelled `<inverse>` (concern-relations.nix), whose `kind` is therefore
  # NOT a relationKinds key. This index makes `relationStratumOf` TOTAL over BOTH arms — a relation and its
  # inverse label share ONE stratum (the inverse is a query direction on the same edge-kind, §2.2).
  inverseToRelation =
    relationKinds:
    builtins.listToAttrs (
      builtins.filter (x: x != null) (
        prelude.mapAttrsToList (
          rel: row:
          let
            inv = row.inverse or null;
          in
          if inv != null then
            {
              name = inv;
              value = rel;
            }
          else
            null
        ) relationKinds
      )
    );

  # relationStratumOf — the stratum of the relation an edge belongs to, resolving BOTH a forward kind (a
  # relationKinds key) AND a swapped inverse label (via the inverse index). Total: an unknown label ⇒ null
  # (excluded from the scoped source), never a raw `relationKinds.<label>` attr-miss (tryEval-uncatchable).
  relationStratumOf =
    relationKinds:
    let
      inv = inverseToRelation relationKinds;
    in
    e:
    let
      rel = if relationKinds ? ${e.kind} then e.kind else inv.${e.kind} or null;
    in
    if rel != null then relationKinds.${rel}.stratum or null else null;

  # edgesWithin — the STRATUM-SCOPED edge source (§2.3, the SILENT filter), parameterized by ADMITTANCE:
  # every relation edge whose stratum `admit`s against `ceiling` (an index into `strataOrder`). An
  # out-of-scope or unknown-label edge is SILENTLY excluded (no throw — the query mode is exploratory, its
  # out-of-capability reach is naturally empty). An unknown label (stratum null) stays excluded under every
  # admittance: the source is scoped, not total, and an edge whose relation cannot be identified has no
  # stratum to compare. This is the query SOURCE side of the capability boundary `gateWithin` gates per-kind:
  # scoping the edge list scopes the capability.
  edgesWithin =
    admit:
    {
      strataOrder,
      relationKinds,
      relationEdges,
    }:
    ceiling:
    let
      stratumOf = relationStratumOf relationKinds;
    in
    builtins.filter (
      e:
      let
        s = stratumOf e;
      in
      s != null && admit (indexOf strataOrder s) ceiling
    ) relationEdges;

  # gateWithin — the STRATUM-GATE over a per-kind relation record (§2.3, the LOUD projection / the projectCtx
  # throw-on-read pattern), parameterized by ADMITTANCE: a kind whose stratum is NOT admitted against
  # `ceilingIdx` is REPLACED with a NAMED throw. `rule` is the law the rejection cites, so a throw names the
  # ABW condition applied rather than an index.
  # The gate withholds the VALUE, not the OBSERVATION: no out-of-scope fact reaches the reader, but a reader
  # may wrap the read in `builtins.tryEval` inside its own body and recover a boolean saying the read was out
  # of scope. That is the SOUND direction — distinguishing out-of-scope from absent is exactly what a negation
  # needs (L4) — so what the gate claims is value-withholding, not unobservability.
  # `{ name; stratum }` name the reader for the message; a kind carrying no stratum passes untouched.
  # The message is the derive-facet locus (its sole consumer today); the arithmetic is the shared primitive.
  gateWithin =
    admit: rule:
    {
      strataOrder,
      relationKinds,
    }:
    {
      name,
      stratum,
      ceilingIdx,
    }:
    relRecord:
    builtins.mapAttrs (
      kind: entry:
      let
        kindStratum = relationKinds.${kind}.stratum or null;
      in
      if kindStratum != null && !(admit (indexOf strataOrder kindStratum) ceilingIdx) then
        throw "den.derived: '${name}' at stratum '${stratum}' may not read relation '${kind}' at stratum '${kindStratum}' — ${rule} (§2.3)"
      else
        entry
    ) relRecord;

  # The shipped instantiations. `positiveEdges`/`positiveGate` are what every RUNTIME read surface takes:
  # the reader's polarity is not observable there, so condition 1 is the whole of the law available to them.
  # `negativeGate` has no runtime consumer — condition 2 lives at the `negates` registration check, which
  # reads `strataLt` directly — and is kept here so the asymmetry is ONE expression rather than two
  # spellings, and so a test can witness the two gates disagreeing on the same-stratum kind.
  positiveEdges = edgesWithin admitPositive;
  positiveGate = gateWithin admitPositive "a positive read admits strata at or below the reader's own (Apt-Blair-Walker 1988, Definition 3, condition 1)";
  negativeGate = gateWithin admitNegative "a negation reads a COMPLETE predicate, so it admits strata strictly below the reader's own (Apt-Blair-Walker 1988, Definition 3, condition 2)";
in
{
  inherit
    indexOf
    admitPositive
    admitNegative
    strataLt
    strataLe
    inverseToRelation
    relationStratumOf
    edgesWithin
    gateWithin
    positiveEdges
    positiveGate
    negativeGate
    ;
}
