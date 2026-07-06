# The `projects` facet (§2.9 / A14, v1 experimental) — an aspect P projecting settings onto OTHER
# aspects that match a STATIC selector, expanded into `via`-carrying settings layers at P's attachment
# scopes. den-hoag owns the SELECTOR DOMAIN here: the aspect-schema context (`schemaContext`) and the
# `hasSetting` sugar are DEN-HOAG vocabulary — thin sugar over the shipped generic gen-select
# constructors (`select.when` / `select.attrs`), NOT a gen-select addition. They graduate to
# gen-aspects only if a second consumer appears (the readiness-review ownership rule); until then the
# ownership lives with this, the one consumer.
#
# NO EFFECT RUNTIME / NO NEW ALGORITHM (Law A1). A projection is just extra `den.settings.layers`
# records `{ atCoords; of; set; via }`. The resolved-settings fold already sorts `via`-carrying
# (projection) layers immediately before same-slice direct layers (§2.7) and applies the containment
# chain per node — so a fleet-scope projection is ONE layer folded fleet-wide, never re-emitted per
# descendant (A14 constraint 1). This file only WIRES: it turns the projecting aspects into those
# records and enforces the two definition-time disciplines. The only recursion is selector-tree and
# attrset-assembly glue; no convergence/toposort/product traversal lives here.
#
# A14 v1 constraints enforced here:
#   (1) attachment-scope-only — the caller passes each projector's attachment positions (`scopes`);
#       one layer per matching target per scope. (The fleet-wide fold is resolved-settings', not ours.)
#   (2) static selectors only — `assertStaticSelector` rejects any scope-navigating / identity /
#       coordinate selector (they read resolved graph position, not the aspect's own declared schema);
#       the schema context exposes declared field NAMES only, never resolved values.
#   (3) same-scope same-address collision — two DISTINCT projectors targeting one aspect at one scope
#       is undecidable order ⇒ `errors.projectionCollision` naming both projectors + address + scope.
{
  prelude,
  select,
  errors,
}:
let
  # The static tags a projection selector may use: the aspect's OWN declared schema (name/tags/fields,
  # via `attrs`/`when`) and boolean combinators over those. Scope-navigating tags (within/has/
  # parentMatches) and cross-node identity tags (entity/kind/coord) read graph POSITION or resolved
  # identity — dynamic, banned by A14 constraint 2. A bare `when` is permitted: the schema context we
  # hand it exposes only declared field NAMES (never resolved values), so it CANNOT read a resolved
  # value; `hasSetting` is itself a `when`.
  staticTags = [
    "star"
    "attrs"
    "when"
  ];
  combinatorTags = [
    "and"
    "any"
    "not"
  ];

  # Reject a dynamic selector at definition time (A14 constraint 2), naming the projecting aspect and
  # the offending tag. Recurses through boolean combinators; returns the selector unchanged on success
  # so the caller forces the check by using the result (a leaf abort throws the instant the returned
  # selector is forced; a combinator's children are forced eagerly by the fold).
  assertStaticSelector =
    projectorName: sel:
    let
      tag =
        if builtins.isAttrs sel && sel ? __sel then
          sel.__sel
        else
          errors.projectionDynamicSelector projectorName "<not-a-selector>";
      children = if tag == "not" then [ sel.selector ] else (sel.selectors or [ ]);
    in
    if builtins.elem tag combinatorTags then
      prelude.foldl' (acc: c: builtins.seq (assertStaticSelector projectorName c) acc) sel children
    else if builtins.elem tag staticTags then
      sel
    else
      errors.projectionDynamicSelector projectorName tag;

  # den-hoag-owned selector domain: the aspect-schema context. A selector in a `projects` rule is
  # matched against ASPECTS (as addresses); `data <aspectName>` projects the aspect's declared field
  # NAMES (never resolved values — A14 constraint 2), plus name/tags, so a projection can target
  # "every aspect declaring a `theme` field" without reading any resolved setting. The scope-navigating
  # accessors THROW (defence-in-depth for a hand-rolled `when` — the primary guard is
  # assertStaticSelector); gen-select's `matches` only reaches the ones a static selector never uses.
  schemaContext =
    allAspects:
    let
      dyn =
        _:
        throw "den-hoag: projects (A14): a projection selector navigated the scope tree; projection selectors are static (aspect-schema) only — match declared name/tags/setting fields, never graph position";
      data =
        aspectName:
        let
          a = allAspects.${aspectName};
          fields = builtins.attrNames (a.settings or { });
        in
        {
          inherit (a) name;
          tags = a.tags or [ ];
          inherit fields;
          # declared field NAMES as a presence set — never the resolved values (A14 constraint 2).
          setting = builtins.listToAttrs (
            map (f: {
              name = f;
              value = true;
            }) fields
          );
        };
    in
    {
      inherit data;
      parent = dyn;
      children = dyn;
      ancestors = dyn;
      siblings = dyn;
    };

  # hasSetting — sugar over the shipped generic `select.when`; NOT a new gen-select constructor.
  # Matches an aspect address whose declared field set contains `field`.
  hasSetting = field: select.when (id: ctx: builtins.elem field ((ctx.data id).fields or [ ]));

  # A stable grouping key for a (scope, target-aspect) address — for the collision check. `atCoords`
  # is a `{ <dim> = entry }` attrset; two coords denote one slice iff same dims + same entry id_hashes.
  addressKey =
    layer:
    let
      coords = layer.atCoords;
      dims = prelude.sort (a: b: a < b) (builtins.attrNames coords);
    in
    "${
      builtins.concatStringsSep "|" (map (d: "${d}=${coords.${d}.id_hash}") dims)
    }@${layer.of.id_hash}";

  # A14 constraint 3: a (scope, address) reached by ≥2 DISTINCT projectors is undecidable order.
  # (Multiple layers from ONE projector — several rules matching one target — are fine: they fold in
  # rule order, deterministically.) Groups the layers and aborts on the first cross-projector clash.
  assertNoCollision =
    layers:
    let
      grouped = prelude.foldl' (
        acc: l: acc // { ${addressKey l} = (acc.${addressKey l} or [ ]) ++ [ l ]; }
      ) { } layers;
      check =
        _: group:
        if builtins.length (prelude.unique (map (l: l.via.id_hash) group)) >= 2 then
          errors.projectionCollision {
            projectors = prelude.unique (map (l: l.via.name) group);
            address = (builtins.head group).of.name;
            scope = (builtins.head group).atCoords;
          }
        else
          group;
    in
    prelude.foldl' (acc: g: builtins.seq g acc) layers (
      builtins.attrValues (builtins.mapAttrs check grouped)
    );

  # Expand the projecting aspects into `via`-carrying den-layer records `{ atCoords; of; set; via }`.
  #   allAspects     — the aspect registry (the selector context + the target entries).
  #   projectors     — [ { aspect = <P entry>; scopes = [ <atCoords> ]; } ]: P + its attachment
  #                    positions (A14 constraint 1: computed by the caller from the introduction
  #                    surface; each scope yields one layer per matching target).
  #   matchAddresses — candidate target aspect NAMES (P never projects onto itself).
  projectionLayers =
    {
      allAspects,
      projectors,
      matchAddresses,
    }:
    let
      ctx = schemaContext allAspects;
      layersOf =
        { aspect, scopes }:
        prelude.concatMap (
          scopeCoords:
          prelude.concatMap (
            projection:
            let
              sel = assertStaticSelector aspect.name projection.select;
              targets = builtins.filter (name: name != aspect.name && select.matches sel name ctx) matchAddresses;
            in
            map (name: {
              atCoords = scopeCoords;
              of = allAspects.${name};
              set = projection.set;
              via = aspect;
            }) targets
          ) (aspect.projects or [ ])
        ) scopes;
    in
    assertNoCollision (prelude.concatMap layersOf projectors);
in
{
  # assertStaticSelector stays internal — projectionLayers applies it; nothing external needs it.
  inherit
    hasSetting
    schemaContext
    projectionLayers
    ;
}
