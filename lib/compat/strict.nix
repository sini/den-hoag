# The v1 `den.lib.strict` module (den v1 nix/lib/strict.nix, VERBATIM): a freeform-type module that
# throws on any option set without an explicit declaration — the consumer merges it into a raw-absorption
# evalModules as `den.schema.<kind> = den.lib.strict`. Exported UNAPPLIED (the `{ lib, ... }:` function):
# den-hoag's substrate has no `lib.mkOptionType`/`pipe`/`head`/`getAttr`/`attrsToList`/`elemAt`/`join`,
# so it cannot instantiate this here; the consumer's evalModules injects nixpkgs `lib` when it merges the
# module, giving the byte-faithful STRICT-MODE throw. NEVER apply it in the substrate.
{ lib, ... }:
{
  _module.freeformType = lib.mkOptionType {
    name = "strict type";
    typeMerge = _outer: {
      merge =
        path: decls:
        (
          let
            decl = lib.pipe decls [
              lib.head
              (lib.getAttr "value")
              lib.attrsToList
              lib.head
            ];

            kind = if (lib.head path) == "flake" then "flake" else lib.elemAt path 1;
          in
          throw ''
            STRICT MODE

            Attempted to set the option "${decl.name}" in "${lib.join "." path}" but no explicit definition exists. If this wasn't a mistake, disable STRICT mode or configure an option. e.g.

            den.schema.${kind}.options.${decl.name} = lib.mkOption { ... };

            See https://documentation.example
          ''
        );
    };
  };
}
