let
  resolvedAspects = (import ./test-resolved-aspects.nix);
  present = builtins.filter (a: a.present) (builtins.attrValues resolvedAspects);
in
map (a: {
  key = a.content.key;
  name = a.content.name or null;
}) present
