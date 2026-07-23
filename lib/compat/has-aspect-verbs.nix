# den.lib.aspects.{collectPathSet,hasAspectIn,mkEntityHasAspect} — a CONFIG-WIRED ADAPTER over den-hoag's
# ALREADY-NATIVE resolved-aspects output (hasAspect accessors). v1 (den nix/lib/aspects/has-aspect.nix
# @a2f4b60 :37-43,71-102) ran a FRESH isolated fx pipeline over a RAW `{ tree, class }` per call; den-hoag
# instead reads the memoized `reach` closure over the ALREADY-INGESTED fleet graph (`built.den`), so this
# adapter closes over that built den and maps a node HANDLE → the node id its `reach` keys by. The pathSet is
# the SAME native `reach` closure resolveWithPaths already exposes (resolve-verbs.nix `pathSetByScope`).
#
# CONFIG-WIRED (not the config-less migrationLib): it needs the built fleet, so it is bound at the bridge
# seam (bridge.nix `configWiredLib.aspects`) exactly as resolve-verbs.nix binds resolve/resolveWithPaths. The
# migrationLib carries NAMED config-wired stubs (throw on `inputs.den.lib`); the PURE sibling
# `mkProjectedHasAspect` (has-aspect.nix) rides the migrationLib directly. `refKey` (the native-`.key`
# membership lookup) and `augment` (the resolved-aspects node identity projection) are the config-LESS pure
# helpers, threaded in from compat (has-aspect.nix), so this module carries NO identity logic of its own.
#
# ── LATENT ceilings (off-fleet arbitrary-tree resolve — deferred; needs per-call mini-ingest) ──────────
#  (a) OFF-FLEET RAW-TREE resolve. v1's `collectPathSet`/`hasAspectIn`/`mkEntityHasAspect` take a RAW `{ tree,
#      class }` and run a fresh fx pipeline over an ARBITRARY aspect tree. This adapter resolves only a node
#      HANDLE that maps to an INGESTED node (a built-fleet member); an off-fleet arbitrary aspect tree would
#      need a per-call mini-ingest (deferred). This is the SAME LATENT ceiling resolve-verbs.nix:13-18
#      documents (ceiling (a)) — only the ingested-node form maps.
#  (b) SELF-REFERENCE. This adapter closes over `built.den` (the fold over the whole fleet); a corpus policy
#      that calls a hasAspect accessor on its OWN fleet member from WITHIN its own resolution self-references
#      — the SAME stateful-by-construction latent cycle resolve-verbs.nix ceiling (b) documents. No live
#      consumer today (the witness reads an external fixture, never a self-call). LATENT.
#
# The `{ tree, class }` signature itself is v1-internal (the fx off-fleet form); den-hoag's node-form takes a
# handle (the resolve-verbs `resolveEntity` output), so this is a signature-ADAPTED map, not a verbatim port.
{
  den,
  refKey,
  augment,
}:
let
  # A node HANDLE is the resolve-verbs `resolveEntity` output — `{ __denNode = "${kind}:${name}"; }`, the
  # readable coord path the native accessors key by (resolve-verbs.nix `nodeOf`).
  nodeOf = handle: handle.__denNode;

  # The node's resolved-aspects closure (attribute 7 — the deduped `[ { key; content; sharedFoldKey; } ]`
  # list; resolved-aspects.nix `reach`). den-hoag's projected set IS this closure (the v2 dissolution of v1's
  # per-scope re-key bucket), read force-free off the built structural stratum.
  reachAt = id: den.structural.eval.get id "reach";

  # collectPathSet handle → the flat membership set `{ <pathKey> = true; }` (v1 :37 `collectPathSet
  # {tree,class}` → flattenPathSetByScope). SAME construction resolve-verbs.nix uses for
  # resolveWithPaths.pathSetByScope: the native `reach` nodes' `.key`s.
  pathSetOf =
    id:
    builtins.listToAttrs (
      map (n: {
        name = n.key;
        value = true;
      }) (reachAt id)
    );

  collectPathSet = handle: pathSetOf (nodeOf handle);

  # hasAspectIn handle ref → membership (v1 :43 `collectPathSet ? refKey ref`). `refKey` reads the ref's
  # native `.key` (NAMED throw on a keyless ref — never a silent false).
  hasAspectIn = handle: ref: collectPathSet handle ? ${refKey ref};

  # mkEntityHasAspect handle → the entity `hasAspect`/`aspects` surface (v1 :71-102). The MEMBERSHIP arms
  # collapse to class-invariant (v1 :94-96 over a set that is a node's class-invariant union by design —
  # matches the shipped mkEnrich `forClass = _class: mkHas`, has-aspect.nix), so `__functor`/`forClass`/
  # `forAnyClass` all agree over the same `check`. The EXTRA surface is `.aspects`/`.aspectsForClass`/
  # `.allAspects` (v1 :97-101) — the augmented resolved-aspects node list, class-invariant in den-hoag (a
  # node's `reach` is not class-parameterised), so every class projection is the same list.
  mkEntityHasAspect =
    handle:
    let
      id = nodeOf handle;
      pathSet = pathSetOf id;
      check = ref: pathSet ? ${refKey ref};
      augmented = map augment (reachAt id);
    in
    {
      __functor = _: check;
      forClass = _class: check;
      forAnyClass = check;

      # The flat list of resolved aspect nodes, each augmented with `.identity`/`.identityKey`/`.isNamed`
      # (v1 :97). `aspectsForClass`/`allAspects` (v1 :98-101) are class-invariant here (den-hoag `reach` is
      # not class-keyed) — the same augmented list.
      aspects = augmented;
      aspectsForClass = _class: augmented;
      allAspects = augmented;
    };
in
{
  inherit
    collectPathSet
    hasAspectIn
    mkEntityHasAspect
    ;
}
