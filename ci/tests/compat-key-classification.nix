# The fx key-classification surface (ship-gate #49-SLICE) — `keyClassification.structuralKeysSet` is the
# ONE export the corpus reads (schema/_settings-type.nix: `skipKey = k: structuralKeysSet ? k || …`). This
# suite pins three things: (1) the export REPRODUCES v1's literal set exactly (byte-parity source of truth);
# (2) it stays CONSISTENT with the shim's routing on the keys both own — each shared structural key classifies
# as `facet` via the live `classifyKey` (which reads the schema, the single authority), so the corpus skipKey
# and the shim's routing agree; (3) the corpus skipKey shape behaves (structural keys skipped, real settings
# kept).
{ denHoag, denCompat, ... }:
let
  inherit (denCompat.keyClassification) structuralKeysSet;
  # the same value the corpus reaches through `den.lib.aspects.fx.keyClassification` (migrationLib alias).
  aliased = denHoag.aspects.fx.keyClassification.structuralKeysSet;
  sort = builtins.sort (a: b: a < b);

  # den v1's full structuralKeysSet key set at the pin: builtinStructuralKeys (key-classification.nix:9-32)
  # + the corpus's `den.reservedKeys = [ "settings" ]` (defaults.nix:4).
  v1Keys = [
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
    "settings"
  ];
in
{
  flake.tests.compat-key-classification = {
    # (1) GOLDEN: the export reproduces v1's literal set exactly — a drift in the compat list fails HERE,
    # before the corpus's settings tree (and its drvPath) can diverge.
    test-reproduces-v1-set = {
      expr = sort (builtins.attrNames structuralKeysSet);
      expected = sort v1Keys;
    };
    # membership set: every value is `true` (v1's `genAttrs … (_: true)`), read only via `? ${k}`.
    test-membership-values-true = {
      expr = builtins.all (v: v == true) (builtins.attrValues structuralKeysSet);
      expected = true;
    };
    # the migrationLib alias (`den.lib.aspects.fx.keyClassification`) is the SAME value the corpus reaches.
    test-migrationlib-alias-matches = {
      expr = sort (builtins.attrNames aliased) == sort v1Keys;
      expected = true;
    };

    # (2) CONSISTENCY with the shim's routing: each key both sides own (name/description/meta/includes/settings)
    # is structural in the compat set AND routes to `facet` by the shim's live `classifyKey` — the agreement is
    # behavioural, read from the single authority (the schema), so there is no static facet list to drift.
    test-shared-facets-agree-both-sides = {
      expr =
        builtins.all (k: (structuralKeysSet ? ${k}) && denHoag.internal.classifyKey "probe" k == "facet")
          [
            "name"
            "description"
            "meta"
            "includes"
            "settings"
          ];
      expected = true;
    };

    # (3) corpus skipKey shape (`structuralKeysSet ? k`): a structural key is skipped, a real settings key
    # (e.g. a `services.bgp.localAsn`-style leaf) is kept — the classification the settings mirror relies on.
    test-corpus-skipkey-shape = {
      expr = {
        metaSkipped = structuralKeysSet ? "meta";
        settingsSkipped = structuralKeysSet ? "settings";
        classesSkipped = structuralKeysSet ? "classes";
        realSettingKept = !(structuralKeysSet ? "localAsn");
      };
      expected = {
        metaSkipped = true;
        settingsSkipped = true;
        classesSkipped = true;
        realSettingKept = true;
      };
    };

    # (4) SHAPE B — `classifyKey` is ROUTING-ONLY: it reads the key's category from the schema (the single
    # authority) and maps it to a routing bucket. A built-in CLASS key → "class"; the keySemantics facet
    # entries (settings/neededBy/id_hash) → "facet"; a structural built-in option (name/includes) → "facet";
    # an UNREGISTERED key routes to "facet" (behaviour-skip) and NEVER throws — typo protection is the closed
    # gate's job now, not the kernel's. (Channels need a per-fleet instance — pinned end-to-end by
    # compat-channel-not-freeform, the #8 witness.)
    test-shapeb-classify-categories = {
      expr = {
        classKey = denHoag.internal.classifyKey "probe" "nixos";
        facetSettings = denHoag.internal.classifyKey "probe" "settings";
        facetNeededBy = denHoag.internal.classifyKey "probe" "neededBy";
        facetIdHash = denHoag.internal.classifyKey "probe" "id_hash";
        structuralName = denHoag.internal.classifyKey "probe" "name";
        # Routing-only: an unregistered key resolves cleanly to "facet" (no throw) — the "is this a typo"
        # oracle is the closed gate now, not classifyKey.
        unknownRoutesToFacet = denHoag.internal.classifyKey "probe" "totallyUnknownKey";
      };
      expected = {
        classKey = "class";
        facetSettings = "facet";
        facetNeededBy = "facet";
        facetIdHash = "facet";
        structuralName = "facet";
        unknownRoutesToFacet = "facet";
      };
    };
  };
}
