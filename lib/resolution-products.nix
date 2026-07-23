# The resolution-product registry (`den.resolutionProducts.<name>`, spec §5) — compile + validation.
# A resolution product NAMES a typed payload a resolution-facet synthesizer (a `den.derived`'s `provides`)
# emits — the §5 resolution-graph counterpart of den.products' §4.1 MATERIALIZATION faces. The two
# registries are DISTINCT namespaces: a materialization product (SystemInfo, AggregateInfo …) is not a
# resolution product, and a derived's `provides` validates against THIS registry, never den.products —
# so a cross-facet consumption (a derive claiming to provide a materialization face) fails naturally.
# The registry only DECLARES names (+ an optional payload `schema`); the value-composition that consumes
# a resolution product is a later §5 concern. See REFERENCE.md.
#
# NO EFFECT RUNTIME: `compile` is one `mapAttrs` + field projection — no mode/nestable/ArtifactRef
# machinery (a resolution product is a plain payload name, not a materialization carrier). Law A1; the
# thin sibling of products.nix / concern-disciplines.nix. NO reserved-name guard yet: the resolution facet
# ships no framework payload faces, so there is nothing to reserve — the guard reinstates (with a non-empty
# framework seed) WITH the first framework face, mirroring edges / concern-disciplines / products, where
# the reserved posture lands beside the names it protects (§5).
{
  prelude,
}:
let
  # A registry entry's canonical fields (spec §5). A resolution product is a plain payload name; its only
  # optional field is `schema` (the gen-schema-typed payload record, passed through unvalidated here — the
  # sub-shape check lands with the value-composition that consumes it). Absent ⇒ null.
  entryOf = _name: raw: {
    schema = raw.schema or null;
  };

  # `compile { resolutionProducts }` → the validated resolution-product table (a `mapAttrs` + field
  # projection, mirroring products.nix' compile shape but with no mode/nestable machinery and — until a
  # framework face exists — no reserved-name gate). A USER registration is the only writer for now.
  compile =
    {
      resolutionProducts ? { },
    }:
    prelude.mapAttrs entryOf resolutionProducts;
in
{
  inherit
    compile
    ;
}
