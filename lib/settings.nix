# Settings compilation surface (§2.6 / §4.3). Two things den-hoag names, one thing it re-exports:
#
#   mkSchemaFor  — an aspect's declared `settings.<field> = { default; merge ? "replace" }` schema
#                  (§2.6 source 1) → a `gen-settings.mkSchema` (bare-key, static, introspectable).
#   compileLayers — the scoped-override surface (§2.6 source 2): `den.settings.layers`, the
#                  `at`-record form `{ at; of; set; via ? null }`, normalized + validated to internal
#                  den-layer records `{ atCoords; of; set; via }`. (The inline-entity form
#                  `den.hosts.<h>.settings = [ { of; set } ]` is the SAME record with a single-entity
#                  `at`; the at-record form is the general surface and the only one Task 6 wires.)
#   ref          — re-exported from gen-settings unchanged (§2.8): inert, identity-bearing cross-aspect
#                  reference data, never a string.
#
# The one-line compilation den-layer → gen-settings layer `{ scope; rendered; via; value }` (§4.3)
# lives in `toGenLayer`: `of` routes the batch member (it does NOT appear on the gen-settings layer),
# `set` becomes `value`, `at` coords become `scope`, and `rendered` is a display-only projection.
# nixpkgs-lib-free: gen-prelude + builtins only.
{
  prelude,
  settings,
  errors,
}:
let
  # Display-only rendering of a slice's fixed coordinates (§4.3 `rendered`): sorted `dim=name`.
  # Never authoritative — the layer's `scope` carries the entry identities; this is for goldens/UX.
  renderCoords =
    coords:
    if coords == { } then
      "«root»"
    else
      builtins.concatStringsSep "," (
        map (d: "${d}=${coords.${d}.name or coords.${d}.id_hash}") (
          prelude.sort (a: b: a < b) (builtins.attrNames coords)
        )
      );
in
{
  inherit (settings) ref;
  inherit renderCoords;

  # aspect settings schema (§2.6 source 1). `aspectEntry` MUST carry id_hash (identity law); the fold
  # + ref routing key off it. `fields` = `{ <bare-key> = { default; merge ? "replace" }; }`.
  mkSchemaFor =
    aspectEntry: fields:
    settings.mkSchema {
      aspect = aspectEntry;
      inherit fields;
    };

  # Normalize + validate `den.settings.layers`. Definition-time: `of` must be an aspect entry
  # (identity law A2); every `at` dim must be a product dimension (§2.6). `set`'s field-membership is
  # enforced by gen-settings' strict fold (E2, naming the layer + field + aspect), so it is not
  # re-checked here. Returns internal den-layer records the resolved-settings attribute consumes.
  compileLayers =
    {
      layers,
      productDims,
    }:
    map (
      l:
      let
        atCoords = l.at or { };
        badDim = builtins.filter (d: !(builtins.elem d productDims)) (builtins.attrNames atCoords);
      in
      if !(builtins.isAttrs (l.of or null) && (l.of ? id_hash)) then
        errors.identityLaw "den.settings.layers.of" (l.of or null)
      else if badDim != [ ] then
        throw "den-hoag: settings layer (§2.6): `at` names dimension `${builtins.head badDim}` not in the product (product dims: ${builtins.concatStringsSep ", " productDims})"
      else
        {
          inherit atCoords;
          inherit (l) of;
          set = l.set or { };
          via = l.via or null;
        }
    ) layers;

  # den-layer → gen-settings layer `{ scope; rendered; via; value }` (§4.3). `of` is consumed by the
  # caller for batch routing before this point and drops out here.
  toGenLayer = denLayer: {
    scope = denLayer.atCoords;
    rendered = renderCoords denLayer.atCoords;
    inherit (denLayer) via;
    value = denLayer.set;
  };
}
