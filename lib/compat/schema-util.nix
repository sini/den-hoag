# den.lib.schemaUtil — v1's schema kind-registry predicates (den nix/lib/schema-util.nix, pin a2f4b60),
# ported with ONE adaptation: the kindNames SOURCE. v1 reads `den.schema._kindNames` (a gen-schema
# introspection key), which is ABSENT from den-hoag's bridge-emitted `config.den.schema` (= `emittedKinds //
# { __rawSchema }`, no `_kindNames`). THE MAP (theory-determined, not a fork): den-hoag's kind registry = the
# attr-names of `config.den.schema` minus `_`-prefixed introspection keys — which is PRECISELY what v1's
# `_kindNames` was (gen-schema's sorted names already excluding `_`-prefixed keys). Per-kind `.isEntity` IS
# present (the bridge re-adds it on both belt and severed paths), so `schemaEntityKinds` lands. Pure
# derivation over the kind registry — no `pkgs`, no drvPath. Bound at the bridge (reads `den.schema`).
{
  lib,
  den,
  ...
}:
let
  # Canonical kind list = attr-names of the bridge-emitted `den.schema`, `_`-prefixed stripped (drops
  # `__rawSchema`; the den-hoag map onto v1's `_kindNames`, which was likewise sorted and `_`-excluded).
  kindNames = builtins.filter (k: builtins.substring 0 1 k != "_") (
    builtins.attrNames (den.schema or { })
  );

  # Canonical entity kind predicate: excludes the shared `conf` base and
  # non-entity schema entries (isEntity computed by gen-schema).
  schemaEntityKinds = builtins.filter (
    k: k != "conf" && (den.schema.${k}.isEntity or false)
  ) kindNames;

  # Variant for class-module.nix warnings: all schema-like arg names
  # (excludes conf, aspect) WITHOUT the isEntity check.
  # Used to detect missing den args in class module functions.
  schemaArgKinds = builtins.filter (k: k != "conf" && k != "aspect") kindNames;
  schemaEntityKindsSet = lib.genAttrs schemaEntityKinds (_: true);
in
{
  inherit schemaEntityKinds schemaEntityKindsSet schemaArgKinds;
}
