# The fx key-classification surface (ship-gate #49-SLICE) — the ONE export the corpus consumes from
# `den.lib.aspects.fx.keyClassification`: `structuralKeysSet`. nix-config's schema/_settings-type.nix
# reads it as `skipKey = k: structuralKeysSet ? k || classKeys ? k || quirkKeys ? k` to decide which
# aspect keys are STRUCTURAL (handled by the pipeline) rather than user settings, when it mirrors the
# `den.aspects` tree into the typed `<entity>.settings` submodule. The set drives that submodule's option
# TYPE, so it must match v1 EXACTLY, or the corpus's settings tree — and its host/cluster drvPath —
# diverges. This is the ONLY read: a corpus-wide grep finds no other `keyClassification` export consumed
# (classifyKeys is read only by v1's own resolve.nix, never the corpus). The rest of the #49 stub family
# stays throwing.
#
# SOURCE OF TRUTH = v1's LITERAL `builtinStructuralKeys` (den nix/lib/aspects/fx/key-classification.nix:9-32
# at the frozen pin 11866c16), NOT the shim's own facet vocabulary. The two genuinely differ: v1 carries
# pipeline internals (`excludes`/`provides`/`policies`/`into`/`classes`/`__*`/`_module`/`_`) that the shim's
# `classifyKey` facet list lacks, and the shim carries v2 facets (`neededBy`/`tags`/`projects`/`key`/
# `id_hash`) that v1 lacks. Byte-parity is against V1, so V1's set is authoritative. The
# compat-key-classification suite's consistency test pins the LOAD-BEARING overlap — the keys BOTH own
# (name/description/meta/includes/settings) stay structural on both sides, so the corpus's skipKey and the
# shim's three-branch classifyKey never diverge on a shared facet.
#
# `settings` is v1's `structuralKeysSet` addition from `den.reservedKeys`: nix-config sets
# `den.reservedKeys = [ "settings" ]` (modules/den/defaults.nix:4), and v1 folds it in
# (`genAttrs (builtinStructuralKeys ++ (den.reservedKeys or [ ])) …`). It is ALSO the shim's universal
# settings facet (concern-aspects `facets`), so it is structural under both. This export BAKES the corpus's
# reservedKeys value: the static `den.lib` surface the bridge splices cannot read the fleet's
# `den.reservedKeys`. A consumer with a non-default reservedKeys would need it folded in dynamically — a
# named limitation; the one corpus at the pin uses exactly `[ "settings" ]`.
{ }:
let
  # den v1 `builtinStructuralKeys`, verbatim (den nix/lib/aspects/fx/key-classification.nix:9-32 @ 11866c16):
  # keys always handled by the pipeline itself, never dispatched as class or nested aspect keys.
  builtinStructuralKeys = [
    "name"
    "description"
    "meta"
    "includes"
    "excludes"
    "provides"
    "policies"
    "into"
    "classes"
    "__fn"
    "__args"
    "__functor"
    "__functionArgs"
    "__scopeHandlers"
    "__ctxId"
    "__entityKind"
    "__parametricResolvedArgs"
    "__contentValues"
    "__provider"
    "__providesForwarded"
    "_module"
    "_"
  ];
  # `den.reservedKeys` from the corpus (modules/den/defaults.nix:4), folded in exactly as v1 does.
  reservedKeys = [ "settings" ];
  allStructuralKeys = builtinStructuralKeys ++ reservedKeys;
in
{
  # `structuralKeysSet` — v1's `genAttrs allStructuralKeys (_: true)`: a membership set (each key -> true),
  # read only for `? ${k}` presence tests by the corpus's skipKey.
  structuralKeysSet = builtins.listToAttrs (
    map (k: {
      name = k;
      value = true;
    }) allStructuralKeys
  );
}
