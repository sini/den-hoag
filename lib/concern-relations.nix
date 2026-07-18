# den.relations — the declarative relation registry (spec §5), desugaring onto the LIVE `den.edges` edge-kind
# registry at the `resolution` stratum (§2.2 one-registry — no parallel graph). A relation
# `<name> = { inverse ? null; data ? {}; }` registers exactly ONE edge-kind `<name>` @resolution
# (closure = false), carrying `inverse` as LABEL-ONLY metadata (the reverse-query label, §2.2).
#
# NO second kind is registered for the inverse. den.query is source-agnostic — it string-compares a flat edge
# list and never consults the edge-kind table — so the inverse label is followable unregistered: the producer
# emits swapped `<inverse>`-labeled edges, and the per-entity accessor follows that label. The forward
# registration IS load-bearing, though: the one-registry is the source of truth the producer iterates to know
# which relations exist and their inverse labels. `closure = false` makes the registry closure-gate a no-op
# (the surface has no closure field); the closure CAPABILITY is a downstream (discipline-registering) concern.
{
  prelude,
}:
let
  # relationCollisionMessage — the collision detector as a VALUE (`null` = clean, else the NAMED message). It is
  # a value (not only a `throw` side-effect) so the NAMED contract is testable — Nix's `tryEval` cannot capture a
  # throw's text. Because the inverse is LABEL-ONLY (not a registered kind), the shipped `reservedOffenders`
  # check (over `attrNames kinds`) cannot catch a reserved INVERSE label — so THIS detector owns the full label
  # set: {relation names} ∪ {non-null inverse labels} must be pairwise-distinct AND disjoint from both the user
  # `den.edges` kinds and the reserved framework names. The message BUCKETS the offender's class (user-edge /
  # reserved / internal-duplicate) for debug UX on a 3-class guard. A collision is otherwise a silent last-wins
  # `//`-overwrite (the tryEval-uncatchable-adjacent class).
  relationCollisionMessage =
    {
      relations,
      userEdgeKinds,
      reservedNames,
    }:
    let
      relNames = builtins.attrNames relations;
      inverseLabels = builtins.filter (x: x != null) (map (n: relations.${n}.inverse or null) relNames);
      allLabels = relNames ++ inverseLabels;
      # frequency over the combined label multiset — a label appearing more than once is an internal collision
      # (a relation name equal to an inverse label, or two relations sharing an inverse label).
      freq = builtins.foldl' (acc: l: acc // { ${l} = (acc.${l} or 0) + 1; }) { } allLabels;
      offenders = builtins.filter (
        l: (freq.${l} > 1) || (builtins.elem l userEdgeKinds) || (builtins.elem l reservedNames)
      ) (builtins.attrNames freq);
      l = builtins.head offenders;
      cls =
        if builtins.elem l userEdgeKinds then
          "collides with a user den.edges kind"
        else if builtins.elem l reservedNames then
          "is a reserved framework name"
        else
          "is a duplicate relation name / inverse label";
    in
    if offenders == [ ] then
      null
    else
      "den.relations: label '${l}' ${cls} — a relation name and its non-null inverse labels must be pairwise-distinct AND disjoint from the user den.edges kinds and the reserved framework names (§2.2 one-registry)";

  # relationsToEdgeKinds — desugar `den.relations` into the edge-kind additions //-merged into the edge
  # compile's `kinds` arg, gated by `relationCollisionMessage` (one clean NAMED throw pre-empting the silent
  # `//`-overwrite). Each relation → one kind @resolution, closure = false, carrying its `inverse` label + `data`.
  relationsToEdgeKinds =
    {
      relations,
      userEdgeKinds,
      reservedNames,
    }@args:
    let
      msg = relationCollisionMessage args;
      edgeKinds = builtins.listToAttrs (
        map (n: {
          name = n;
          value = {
            stratum = "resolution";
            closure = false;
            inverse = relations.${n}.inverse or null;
            data = relations.${n}.data or { };
          };
        }) (builtins.attrNames relations)
      );
    in
    if msg != null then throw msg else edgeKinds;

  # edgesRelationMessage — the fleet-level UNDECLARED-RELATION guard (§5): every relation named in any entity's
  # `.edges` MUST be a declared `den.relations` relation. Value-returning (`null` = clean, else the NAMED
  # message) for testability. `edgeRels` is a flat list of `{ entityId; rel; }` (every declared edge rel-name
  # across all entities); a `rel` not in `relationNames` is undeclared. This is the validate-then-transform
  # contract: once it passes, the producer may assume `.edges` names only declared relations. It needs ONLY
  # `den.relations` + the `.edges` attr-names — no ref→node-id lowering — so it lives here, not in the producer.
  edgesRelationMessage =
    {
      edgeRels,
      relationNames,
    }:
    let
      offenders = builtins.filter (er: !(builtins.elem er.rel relationNames)) edgeRels;
      o = builtins.head offenders;
    in
    if offenders == [ ] then
      null
    else
      "den.relations: entity '${o.entityId}' declares `.edges.${o.rel}`, but '${o.rel}' is not a relation in den.relations (§5)";
in
{
  inherit relationsToEdgeKinds relationCollisionMessage edgesRelationMessage;
}
