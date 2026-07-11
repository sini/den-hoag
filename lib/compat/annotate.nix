# __provider ANNOTATION (board #58, Fork A) — the shim reproduction of den v1's fold-time provenance
# stamp. v1's aspect typing annotates every unregistered attrset child of an aspect-tree node with
# `__provider = providerPrefix ++ [ key ]` at type-merge time (`annotatedMerged`, pin 11866c16
# nix/lib/aspects/types.nix:561-574; the multi-def arm tags "recursively", types.nix:478-500), and
# `wrapChild` (nix/lib/aspects/fx/aspect/normalize.nix:95-119) later derives the aspect's IDENTITY from
# that path — "so it resolves to its OWN identity … regardless of inclusion path. Without this … the
# same aspect included via two paths gets two identities and fails to dedup."
#
# The shim's raw bridge (bridge.nix `v1DeepMerge`) deliberately never reconstructs v1's typed wrappers,
# so navigated aspect values crossed __provider-LESS and the static-include grounding had no identity
# source — the "<anon>" collapse compile.nix `stampIdentity` repairs (the static twin of the fn arm's
# DISTINCT WRAP NAMES fix; diagnosis history in compile.nix `mkNormalize`). This walk restores exactly
# the annotation half: a POST-FOLD recursive pass over a final merged `den.aspects` tree, stamping
# root-relative `__provider` paths.
#
# POST-FOLD BY DESIGN (the fold-integration ruling):
#   • `v1DeepMerge` stays byte-identical — its recurse-only-on-collision property is the load-bearing
#     formals-preservation mechanism (bridge.nix `options.aspects`), and a per-def annotation pass would
#     also stamp paths onto def fragments a later scalar last-def-wins discards (stale annotation).
#   • The walk is a pure function of the final tree (paths from the root), so it inherits the fold's
#     determinism exactly; applied at every consumer of the merged tree, it yields ONE consistent view.
#
# GUARD = v1's `annotatedMerged` guard (BROAD — every unregistered, non-`__`, non-structural, non-class,
# non-quirk ATTRSET child is a potential nested aspect or namespace node and gets a path), NOT the
# narrow `isNestedAspectKey` discriminator — that one demands a recognized sub-key and would skip pure
# namespace nodes (`core.systemd` = `{ boot = …; }`), leaving `core.systemd.boot` path-less. Class,
# quirk and structural interiors are never annotated NOR recursed (content stays untouched, forced only
# to `isAttrs` WHNF — v1's #580 forcing posture: name-based guards first). `!(v ? __provider)` is v1's
# own idempotency guard (types.nix:562), so a second application (a bridge-annotated tree re-crossing
# the direct-path walk) is a no-op. `__provider` is a v1 STRUCTURAL key (key-classification.nix
# `builtinStructuralKeys` — the corpus's own settings-mirror `skipKey` filters it), so an annotated
# tree is MORE v1-shaped than the raw bridge's, never less.
{
  prelude,
  # den-hoag's built-in output class names (`denHoag.classes` attrNames) — baked at wiring time so
  # every call site excludes the same built-in class keys without re-threading them.
  builtinClassNames,
}:
let
  structuralKeysSet = (import ./key-classification.nix { }).structuralKeysSet;
  # KEEP IN SYNC with compile.nix `v1ClassKeyMap`: annotation runs PRE-grounding, so BOTH spellings of
  # a mapped class key must be excluded (v1 tests its own registries the same way, types.nix:540-542).
  v1ClassKeySpellings = [
    "homeManager"
    "home-manager"
  ];
in
{
  # `annotateAspects { classNames; quirkNames } tree` — classNames/quirkNames are the FLEET's declared
  # `den.classes` / `den.quirks` key names (built-ins + both v1 spellings are baked above).
  annotateAspects =
    {
      classNames ? [ ],
      quirkNames ? [ ],
    }:
    let
      classSet = prelude.genAttrs (builtinClassNames ++ v1ClassKeySpellings ++ classNames) (_: true);
      quirkSet = prelude.genAttrs quirkNames (_: true);
      walk =
        prefix: tree:
        builtins.mapAttrs (
          k: v:
          if
            builtins.isAttrs v
            && !(v ? __provider)
            && !(prelude.hasPrefix "__" k)
            && !(structuralKeysSet ? ${k})
            && !(classSet ? ${k})
            && !(quirkSet ? ${k})
          then
            walk (prefix ++ [ k ]) v // { __provider = prefix ++ [ k ]; }
          else
            v
        ) tree;
    in
    walk [ ];
}
