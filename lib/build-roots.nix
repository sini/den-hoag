# buildRoots — the bridge from entity declarations to scope roots (r2 buildRoots
# contract). Root kinds' instances become gen-scope root nodes `{ id; type; parent;
# decls }` with the Law E6 registration convention (`decls.<kindName> = entry` so
# `inherited-context` exposes the binding, `decls.__entry = entry` + `type = kindName`
# so gen-select's default scope adapter can read identity/kind). Non-root instances
# (cells) enter via the `children` NTA, never here.
#
# nixpkgs-lib-free: gen-prelude only. The only recursion is attrset assembly (A1 wiring).
{ prelude }:
let
  # roots = a list of root KIND names; every instance of each becomes a flat scope root.
  buildRoots =
    { registries, roots }:
    builtins.listToAttrs (
      prelude.concatMap (
        kindName:
        map (
          name:
          let
            entry = registries.${kindName}.${name};
            id = "${kindName}:${name}";
          in
          {
            name = id;
            value = {
              inherit id;
              type = kindName;
              parent = null;
              decls = {
                ${kindName} = entry;
                __entry = entry;
              };
            };
          }
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
in
{
  inherit buildRoots parseParent;
}
