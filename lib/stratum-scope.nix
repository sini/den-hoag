# stratum-scope — the capability-scope arithmetic over a stratified relation graph (spec §2.3). A reader at
# stratum n may only see facts at strata STRICTLY BELOW n (Apt–Blair–Walker stratified-negation discipline):
# `edgesBelowStratum` is the SILENT filter (an out-of-scope edge is absent, the exploratory-query mode) and
# `ceilingGate` is the LOUD projection (reading an out-of-scope relation is REPLACED with a NAMED throw, the
# capability-by-construction mode). Both read a relation's stratum via `relationStratumOf`, total over BOTH a
# forward kind and a swapped inverse LABEL (§2.2 — a relation and its inverse share ONE stratum). Extracted
# from `mkDerived`'s inline block so the accessors (`mkRelAccessor`/`mkRelQuery`) and the derive compute share
# ONE stratum-ceiling primitive (no second copy of the `< ceilingIdx` / `>= ceilingIdx` arithmetic).
{
  prelude,
}:
let
  # index of `x` in the ordered list `xs`, or -1 if absent (the strata-order position for the §2.3 comparison).
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

  # strataLt — `a` sits STRICTLY BELOW `b` in the strata order (the §2.3 strictly-below primitive). An absent
  # stratum (indexOf -1) compares below every present one, matching the raw `indexOf` comparison it lifts.
  strataLt =
    strataOrder: a: b:
    indexOf strataOrder a < indexOf strataOrder b;

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

  # edgesBelowStratum — the STRATUM-SCOPED edge source (§2.3, the SILENT filter): every relation edge whose
  # stratum sits STRICTLY BELOW `ceiling` (an index into `strataOrder`). An out-of-scope (≥ ceiling) or
  # unknown-label edge is SILENTLY excluded (no throw — the query mode is exploratory, its out-of-capability
  # reach is naturally empty). This is the query SOURCE side of the capability boundary `ceilingGate` gates
  # per-kind: scoping the edge list scopes the capability.
  edgesBelowStratum =
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
      s != null && indexOf strataOrder s < ceiling
    ) relationEdges;

  # ceilingGate — the STRATUM-GATE over a per-kind relation record (§2.3, the LOUD projection / the projectCtx
  # throw-on-read pattern): a kind whose stratum sits at or above `ceilingIdx` is REPLACED with a NAMED throw
  # (enforcement-by-construction, never introspection — the reader cannot read a fact at or above its own
  # layer). `{ name; stratum }` name the reader for the message; a kind carrying no stratum passes untouched.
  # The message is the derive-facet locus (its sole consumer today); the arithmetic is the shared primitive.
  ceilingGate =
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
      if kindStratum != null && indexOf strataOrder kindStratum >= ceilingIdx then
        throw "den.derived: '${name}' at stratum '${stratum}' may not read relation '${kind}' — it is stratum '${kindStratum}' ≥ the derive's own (a derive reads strata strictly below its own, §2.3)"
      else
        entry
    ) relRecord;
in
{
  inherit
    indexOf
    strataLt
    inverseToRelation
    relationStratumOf
    edgesBelowStratum
    ceilingGate
    ;
}
