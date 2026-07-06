# Attribute 13 — resolved-settings (r2 §2.10 #13 / §2.7). Per `(node, aspect)` the ordered layer
# list — containment chain (gen-product) × D/I chain (gen-scope) × the terminal policy slot — folded
# by `gen-settings.resolveAll`. Every body here is WIRING (field reads, list filters, attrset
# assembly) over exactly one algorithm: the `gen-product.containmentChain` slice order and the
# `gen-settings.resolveAll` fold (Law A1). The attribute VALUE is inert data
# (`{ <aspectName> = { value; provenance; }; }`), never a loop record.
#
# STRATIFICATION LAW (A9 / A16). resolved-settings is a RESOLUTION-stratum attribute: it reads
# structure (the node's coordinates) and PRESENCE (resolved-aspects, attribute 7) — never the
# reverse. The presence fixpoint (attribute 7) never reads settings (its guards see only
# `{ pathSet, hasAspect }`, A9.1), so there is no cycle and the least fixpoint stays sound. The
# `.value` is byte-identical to a plain `foldLayers` over the same layer list (A16); provenance
# lists every layer in §2.7 order.
#
# LAYER ORDER (§2.7). `[ default ] ++ concatMap (slice: projection ++ direct) chain ++ policy`:
#   - `default`  — the schema defaults, injected by gen-settings' fold as the leading entry
#                  (defaultLabel); den-hoag emits no explicit default layer.
#   - `chain`    — `containmentChain fleet coords lin`, least→most specific; per slice the
#                  projection layers (§2.9, `via != null`) sort immediately before that slice's
#                  direct override layers (`via == null`), both from `den.settings.layers`.
#   - `policy`   — `configure` declarations at this node (attribute 4's resolution group), always in
#                  the terminal slot (A8, authority-wins by position).
#
# Deps: prelude (folds/filters), resolve (attr), product (containmentChain), settings (resolveAll),
# settingsLib (schema/layer compilation), errors (absentAspectSetting). Instance args: fleet (the
# restricted gen-product), lin (the linearization record), settingsLayers (compiled den-layer
# records), dimKinds (product dimension names, for the full-cell test).
{
  prelude,
  resolve,
  product,
  settings,
  settingsLib,
  errors,
}:
let
  # Reserved decls keys are graph machinery, never producing-scope coordinates (mirrors
  # collections.nix coordDims; `__coords` is the full-cell coordinate cache added for this attribute).
  coordDims =
    node:
    removeAttrs (node.decls or { }) [
      "__entry"
      "__edges"
      "__containment"
      "__coords"
    ];

  # An identity-bearing aspect entry from a resolved aspect's content (id_hash added by the aspect
  # submodule's idModule; name is the display key). gen-settings routes the batch + refs by id_hash.
  entryOf = content: {
    inherit (content) name id_hash;
  };

  # Two coordinate sets denote the same slice iff same dims and same entry identities (by id_hash).
  coordsEq =
    a: b:
    builtins.attrNames a == builtins.attrNames b
    && builtins.all (d: (a.${d}.id_hash or null) == (b.${d}.id_hash or null)) (builtins.attrNames a);

  # The full product coordinates of a node: a cell caches them at `decls.__coords` (all product
  # dims → entries), a flat root carries only its own single dim (coordDims).
  coordsOfNode = node: node.decls.__coords or (coordDims node);

  # `configure` policy layers at this node for this aspect → the terminal `policy` slot (A8). The
  # layer carries the coordinates the policy fired at (§4.3); `via` is null (den policies are not
  # identity-bearing entries), the `rendered` label marks the terminal slot for goldens.
  policyLayersAt =
    resolutionActs: nodeCoords: aspectEntry:
    map
      (a: {
        scope = nodeCoords;
        rendered = "policy";
        via = null;
        value = a.set;
      })
      (
        builtins.filter (a: a.__action == "configure" && a.of.id_hash == aspectEntry.id_hash) resolutionActs
      );

  # The equation builder. Instance args pin the fleet product + linearization + compiled layers.
  mkEquation =
    {
      fleet,
      lin,
      settingsLayers,
      dimKinds,
    }:
    let
      # den-layer records declared AT one slice, FOR one aspect (batch routing by `of.id_hash`).
      # Projection layers (§2.9, `via != null`) sort immediately before direct overrides at the same
      # slice (§2.7): a direct declaration beats a projection attached at that scope.
      layersAtSlice =
        aspectEntry: sliceFixed:
        let
          here = builtins.filter (
            l: l.of.id_hash == aspectEntry.id_hash && coordsEq l.atCoords sliceFixed
          ) settingsLayers;
          projection = builtins.filter (l: l.via != null) here;
          direct = builtins.filter (l: l.via == null) here;
        in
        map settingsLib.toGenLayer (projection ++ direct);
    in
    {
      "resolved-settings" = resolve.attr {
        name = "resolved-settings";
        kind = "synthesized";
        stratum = "resolution";
        readsAttrs = [
          "resolved-aspects"
          "declarations"
        ];
        compute =
          self: id:
          let
            node = self.node id;
            coords = coordsOfNode node;
            # containmentChain needs a full cell; a flat root fixes ≤1 dim, whose only subsets
            # (∅ ⊂ own-slice) are ⊆-comparable and need no linearization tie-break.
            isFullCell = builtins.length (builtins.attrNames coords) == builtins.length dimKinds;
            chain =
              if isFullCell then
                map (e: e.fixed) (product.containmentChain fleet coords lin)
              else
                [
                  { }
                  coords
                ];

            present = self.get id "resolved-aspects";
            resolutionActs = (self.get id "declarations").actions.resolution or [ ];

            # ONE resolveAll batch over every present aspect at this node (cross-aspect `ref` routing
            # is by id_hash across the batch, §2.8). Keyed by aspect name for the narrow accessor.
            batch = map (
              a:
              let
                aspectEntry = entryOf a.content;
              in
              {
                schema = settingsLib.mkSchemaFor aspectEntry (a.content.settings or { });
                layers =
                  prelude.concatMap (sliceFixed: layersAtSlice aspectEntry sliceFixed) chain
                  ++ policyLayersAt resolutionActs coords aspectEntry;
                key = a.content.name;
              }
            ) present;
            resolved = settings.resolveAll { inherit batch; };
          in
          prelude.foldl' (
            acc: a:
            acc
            // {
              ${a.content.name} = {
                value = resolved.value.${a.content.name};
                provenance = resolved.provenance.${a.content.name};
              };
            }
          ) { } present;
      };
    };

  # The narrow accessor (A10, §2.8) — the `aspects` module arg at output assembly. For every declared
  # aspect NAME, exactly `{ present; settings; }`: `present` = projected/delivered presence at this
  # scope; `settings` = the aspect's resolved settings, or a named abort if absent (check `.present`
  # first). Content→content is unexpressible — only these two fields cross. Independent of the
  # resolved-settings instance args (needs only the aspect registry + the eval), so den-hoag builds it
  # once from `config.den.aspects` and the final eval.
  mkNarrowAccessor =
    allAspects: self: id:
    let
      present = self.get id "resolved-aspects";
      presentNames = map (n: n.content.name) present;
      rs = self.get id "resolved-settings";
    in
    builtins.mapAttrs (name: _def: {
      present = builtins.elem name presentNames;
      settings =
        if builtins.elem name presentNames then rs.${name}.value else errors.absentAspectSetting name id;
    }) allAspects;
in
{
  inherit mkEquation mkNarrowAccessor;
}
