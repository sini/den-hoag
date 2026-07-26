# buildRoots — the bridge from entity declarations to scope roots (r2 buildRoots
# contract). Root kinds' instances become gen-scope root nodes `{ id; type; parent;
# decls }` with the Law E6 registration convention (`decls.<kindName> = entry` so
# `inherited-context` exposes the binding, `decls.__entry = entry` + `type = kindName`
# so gen-select's default scope adapter can read identity/kind). Non-root instances
# (cells) enter via the `children` NTA, never here.
#
# Root parentage is EDGE-DELIVERED, not inferred: a root is parentless unless the caller
# names its attachments in `attachments` (root id -> [ parent node id ]), which it derives from
# the containment edge relation. This module reads no topology of its own — it only applies the
# map. Absent (`{ }`) ⇒ every root is parentless.
#
# MULTI-ATTACHMENT MULTIPLIES THE NODE, never the parent: scope parentage is a partial function,
# so an entity claimed by N>1 sources becomes N nodes of one parent each, rather than one node of
# N parents. That is the mechanism cells already use — an `@`-suffixed id under the parent that
# minted it. N≤1 keeps the bare id, so the single-attachment path is untouched.
#
# nixpkgs-lib-free: gen-prelude only. The only recursion is attrset assembly (A1 wiring).
{ prelude }:
let
  # THE id rule for an attached root, and the only definition of it: the pre-pass calls it to key
  # bindings at the node that will carry them, `buildRoots` calls it to mint that node, and the two
  # cannot drift. The two facts it needs are DISTINCT and must stay separate arguments — `parents`
  # (all of the target's attachments) decides WHETHER the id multiplies, `parent` decides WHICH node
  # this one is. Collapsing them, e.g. by reading the first of the list, yields one id for all N.
  mintedRootId =
    bareId: parents: parent:
    if builtins.length parents <= 1 then bareId else "${bareId}@${parent}";

  # roots = a list of root KIND names; every instance of each becomes one scope root per attachment
  # (exactly one when it has none, or one).
  buildRoots =
    {
      registries,
      roots,
      attachments ? { },
    }:
    builtins.listToAttrs (
      prelude.concatMap (
        kindName:
        prelude.concatMap (
          name:
          let
            entry = registries.${kindName}.${name};
            bareId = "${kindName}:${name}";
            parents = attachments.${bareId} or [ ];
            mk = id: parent: {
              name = id;
              value = {
                inherit id parent;
                type = kindName;
                decls = {
                  ${kindName} = entry;
                  __entry = entry;
                };
              };
            };
          in
          if parents == [ ] then
            [ (mk bareId null) ]
          else
            map (p: mk (mintedRootId bareId parents p) p) parents
        ) (builtins.attrNames registries.${kindName})
      ) roots
    );

  # "type:name@parent" → the parent id (everything after the FIRST '@'); null for roots.
  # O(1) via a single regex, no split-list allocation (r2 audit caveat 1 / Performance §1).
  parseParent =
    id:
    let
      m = builtins.match "[^@]*@(.*)" id;
    in
    if m == null then null else builtins.head m;

  # Is this id a CELL (a node materialised UNDER a parent), as opposed to a scope ROOT?
  # Exact by case analysis over the two — and only two — node constructors: `buildRoots` above
  # mints roots as "${kind}:${name}" (no '@'), and the `children` NTA mints cells as
  # "${leafDim}:${leaf}@${parentNodeId}" (an '@' by construction). gen-scope's walk reaches
  # nothing else — it descends `children`/`derived-children` only, and `derived-children` is
  # unbuilt here — so every node is one or the other and the test is total.
  # This is the honest predicate for "is a cell". A `parent != null` test answers the same
  # question ONLY while roots are parentless; once a root carries a containment parent the two
  # diverge, and the parentage test starts calling roots cells.
  # BOUND: rests on no entity NAME containing '@'. Corpus-unreachable and unguarded; if a fixture
  # ever authors one, discriminate on the constructor instead (tag the node at mint time) rather
  # than on the id's shape.
  isCell = id: parseParent id != null;
in
{
  inherit
    buildRoots
    mintedRootId
    parseParent
    isCell
    ;
}
