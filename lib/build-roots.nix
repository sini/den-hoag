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
                  # The constructor TAG: minted here, so it is present on exactly the nodes this
                  # module makes and absent on every cell. `isCellNode` reads it — see below.
                  __root = true;
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

  # Is this NODE a CELL (materialised UNDER a parent), as opposed to a scope ROOT?
  # Exact by case analysis over the two — and only two — node constructors: `buildRoots` above
  # stamps `decls.__root` on everything it mints, and the `children` NTA stamps nothing. gen-scope's
  # walk reaches nothing else — it descends `children`/`derived-children` only, and
  # `derived-children` is unbuilt here — so every node is one or the other and the test is total.
  #
  # It reads the CONSTRUCTOR TAG, not the id's shape, and the difference is now load-bearing rather
  # than theoretical. An id-shape test ("does it contain '@'") rested on no entity NAME containing
  # '@' — a bound this module used to record as unreached. Multi-attachment reached it from the other
  # side: `mintedRootId` puts an '@' in the ids of multiplied ROOTS, so the id shape no longer
  # separates the two constructors and the shape test would call those roots cells. The tag is
  # immune — it is written where the node is made, and it says which constructor made it.
  #
  # It is also immune to the reserved-key strips: those are projections that READ `node.decls` and
  # return a new attrset for some context, never writing `decls` back, so no strip can reach the tag.
  # Stripping `__root` alongside the other machinery keys is hygiene — keeping it out of binding
  # contexts — not a correctness dependency of this predicate.
  #
  # `parseParent` above is unaffected and keeps its own job: recovering a parent id from a cell id.
  isCellNode = node: !(node.decls.__root or false);
in
{
  inherit
    buildRoots
    mintedRootId
    parseParent
    isCellNode
    ;
}
