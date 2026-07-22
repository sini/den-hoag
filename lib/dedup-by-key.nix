# First-occurrence-wins dedup by a per-element key — the den-hoag port of v1's `dedupByKey`
# (nix/lib/aspects/fx/scope-walk.nix:41-59 @ pin 11866c16). An element whose key is `null` is ALWAYS kept
# (never deduped) — v1's anon-module rule (wrap-classes.nix:87-94): a module with no stable identity cannot
# be proven a cross-scope duplicate, so keeping it is the SAFE direction (a false-keep of equal content
# equal-merges harmlessly; a false-collapse of distinct content is silent content-loss). Used by the
# cross-scope shared-aspect dedup (resolved-aspects `reach` + output-modules `classSubtreeAt`) keyed on the
# node's `sharedFoldKey`, so both fold sites collapse a genuinely-shared host+user aspect identically.
{ prelude }:
{
  # `dedupByKey getKey list` — keep each element the first time its non-null key is seen; drop a later
  # element whose key was already seen; keep every null-keyed element. Order-preserving (own/host first).
  dedupByKey =
    getKey: list:
    let
      go =
        seen: items:
        if items == [ ] then
          [ ]
        else
          let
            x = builtins.head items;
            rest = builtins.tail items;
            k = getKey x;
          in
          if k != null && seen ? ${k} then
            go seen rest
          else
            [ x ] ++ go (if k != null then seen // { ${k} = true; } else seen) rest;
    in
    go { } list;
}
