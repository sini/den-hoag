# The claim-accessor — the REVERSE-READ resolution equation over the off-trace claim pool (spec §5,
# productions substrate). Where the leaf claims (`emit = edges` CONSTANT productions, from = ∅) supply the
# FORWARD adjacency (a source reads its egress, who-do-I-claim), this equation delivers its TRANSPOSE (a
# target reads its ingress, who-claims-me) — the §9 algebraic-graph transpose (Mokhov 2017 §4.3), NOT a
# hand-rolled from/to swap. It is the sibling of `rel-accessor`: a `resolve.attr` at the `resolution` stratum
# with `readsAttrs = [ ]` (the claim pool is the STATIC, registry-derived `relationEdges` — GAP-5, so the
# compute ignores `self`). A later provider reads THIS accessor at its OWN node — an INTRA-stratum positive
# read (A9, Apt–Blair–Walker), the same posture `derived-accessor` reads `rel-accessor`.
#
# The per-node value is a handle with the node.query / node.rel silent-vs-throwing contract (§2.3 capability
# scope, concern-derived.nix):
#   `.query <kind>` (SILENT): the reverse claimers of `<kind>` — a missing OR out-of-scope claim kind yields
#                             `[ ]` (the exploratory-query mode: out-of-capability reach is naturally empty).
#   `.rel.<kind>`   (THROWING): the reverse claimers of `<kind>` — an out-of-scope claim kind is REPLACED
#                             with a NAMED throw (the capability-by-construction gate; a negation over this
#                             throwing read cannot mistake absent for out-of-scope).
# The capability boundary is the accessor's OWN stratum (`resolution`): a claim kind sits IN SCOPE when its
# stratum is STRICTLY BELOW `resolution` (the shipped connect < secret < database < route claim strata all
# qualify); a claim declared AT/above `resolution` is out of scope. Both variants share ONE `edgesBelowStratum`
# ceiling (the query SOURCE side of the boundary — scoping the claim pool scopes the capability).
#
# Corpus-inert: an empty `claimKinds` ⇒ `.query` is constantly `[ ]` and `.rel` is `{ }` for every node, and
# nothing outside a claim/provide fleet reads `claim-accessor`, so it never reaches the trace — byte-identical
# to the pre-claim output (the `rel-accessor` corpus-inert argument, applied to the reverse read).
{
  resolve,
  strataScope,
  prelude,
  transpose,
}:
{
  claimKinds ? { },
  relationEdges ? [ ],
  strataOrder ? [ ],
}:
let
  inherit (strataScope) indexOf;
  # the accessor's own capability ceiling: claim facts at strata STRICTLY BELOW `resolution` are in scope.
  ownStratum = "resolution";
  ceiling = indexOf strataOrder ownStratum;
  claimKindNames = builtins.attrNames claimKinds;
  # a claim kind is in scope when its stratum sits strictly below the accessor's own (§2.3 strictly-below).
  inScope = kind: indexOf strataOrder (claimKinds.${kind}.stratum or null) < ceiling;

  # the STRATUM-SCOPED claim source (§2.3, the SILENT filter): only claim edges whose stratum is strictly
  # below the ceiling survive (`claimKinds` doubles as the edge-kind → stratum index, so a NON-claim relation
  # edge — absent from `claimKinds` — resolves to a null stratum and is excluded: the claim pool alone). This
  # isolation assumes the leaf-claim NAMES are DISJOINT from the den.relations edge-kinds — a relation edge
  # whose kind collided with a claim name would be admitted and mis-scoped by the claim stratum. That name-
  # disjointness is a framework-wide name-uniqueness invariant (owned by the shared registration pass), NOT
  # re-guarded here (a local throw would be a half-measure patch on a global concern).
  scopedPool = strataScope.edgesBelowStratum {
    inherit strataOrder relationEdges;
    relationKinds = claimKinds;
  } ceiling;

  # reverseByKind — the per-claim-kind REVERSE adjacency over an edge pool (§9 transpose). For each claim kind
  # `k`: `k`'s forward edges become `{ edges = from → [to]; nodes = k's endpoints }`; `transpose` reverses the
  # adjacency (to → [from], Mokhov 2017 §4.3), so `(reverseByKind pool).<k> id` = the sources that claim `id`
  # via `k` (who-claims-me). A kind with no forward edges in `pool` ⇒ an empty reverse (never an attr-miss).
  reverseByKind =
    pool:
    builtins.listToAttrs (
      map (
        kind:
        let
          kindEdges = builtins.filter (e: e.kind == kind) pool;
          adjacency = builtins.foldl' (
            acc: e: acc // { ${e.from} = (acc.${e.from} or [ ]) ++ [ e.to ]; }
          ) { } kindEdges;
          nodes = prelude.unique (
            prelude.concatMap (e: [
              e.from
              e.to
            ]) kindEdges
          );
          reversed = transpose {
            edges = id: adjacency.${id} or [ ];
            inherit nodes;
          };
        in
        {
          name = kind;
          value = id: reversed.edges id;
        }
      ) claimKindNames
    );

  # (b) PAYLOAD-PROJECTING reverse-read (§5, additive). `transpose` is adjacency-ONLY (Mokhov 2017 §4.3 —
  # gen-graph reverses id→[id], dropping `e.data`); the payload PROJECTION lives HERE, in the kernel accessor.
  # `projectedByKind pool` builds, per claim kind, a per-TARGET index of `{ from; data }` records (the claimer
  # id PLUS its carried edge payload), so `(projectedByKind pool).<k> id` = `[ { from; data } ]` for id's
  # claimers via `k`. DISTINCT from the id-only `reverseByKind` (which the shipped claim-negation/claim-dedup
  # consume as sort-by-lessThan ID-LISTS): those stay UNCHANGED; this is a NEW handle beside them (§0 additive).
  projectedByKind =
    pool:
    builtins.listToAttrs (
      map (
        kind:
        let
          kindEdges = builtins.filter (e: e.kind == kind) pool;
          payloadByTo = builtins.foldl' (
            acc: e:
            acc
            // {
              ${e.to} = (acc.${e.to} or [ ]) ++ [
                {
                  from = e.from;
                  data = e.data or null;
                }
              ];
            }
          ) { } kindEdges;
        in
        {
          name = kind;
          value = id: payloadByTo.${id} or [ ];
        }
      ) claimKindNames
    );

  # the reverse adjacency over the SCOPED pool — in-scope claim kinds carry their real reverse; out-of-scope
  # kinds resolve to an empty reverse (their edges never entered `scopedPool`). Both handle variants read it.
  scopedReverse = reverseByKind scopedPool;
  # the payload-projecting reverse over the SAME scoped pool (the (b) handle's source).
  scopedReverseProjected = projectedByKind scopedPool;
in
{
  # claim-accessor (§5) as a scheduled attribute — the per-node who-claims-me handle. `readsAttrs = [ ]`: the
  # producer is the static `relationEdges` claim pool, so the compute ignores `self` (GAP-5). `resolution`
  # stratum, so a provider at `resolution` reads it INTRA-stratum (A9). The per-kind transposes are built ONCE
  # (closed over below); the compute only id-applies them, so forcing one node never re-transposes the pool.
  claim-accessor = resolve.attr {
    name = "claim-accessor";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [ ];
    compute = _self: id: {
      # SILENT (node.query posture): a missing OR out-of-scope claim kind yields `[ ]`.
      query = kind: (scopedReverse.${kind} or (_: [ ])) id;
      # (b) SILENT payload-PROJECTING variant (node.query posture): the reverse claimers of `<kind>` as
      # `[ { from; data } ]` records (the id PLUS its carried edge payload) — BESIDE the id-only `.query`/`.rel`
      # (unchanged), for a consumer that needs the claim payload, not just the claimer id. Out-of-scope/missing
      # kind ⇒ `[ ]` (its edges never entered `scopedPool`).
      queryEdges = kind: (scopedReverseProjected.${kind} or (_: [ ])) id;
      # THROWING (node.rel posture): an out-of-scope claim kind is REPLACED with a NAMED throw (the L4
      # throwing-gate a stratified negation consumes — it cannot mistake an out-of-scope read for absent).
      rel = builtins.listToAttrs (
        map (kind: {
          name = kind;
          value =
            if inScope kind then
              scopedReverse.${kind} id
            else
              throw "den.productions: claim-accessor at stratum '${ownStratum}' may not read claim kind '${kind}' — its stratum '${
                claimKinds.${kind}.stratum or "<none>"
              }' is not strictly below the accessor's own (a reverse-read sees claims strictly below its stratum, §2.3)";
        }) claimKindNames
      );
    };
  };
}
