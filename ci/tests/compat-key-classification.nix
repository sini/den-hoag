# The fx key-classification surface (ship-gate #49-SLICE) — `keyClassification.structuralKeysSet` is the
# ONE export the corpus reads (schema/_settings-type.nix: `skipKey = k: structuralKeysSet ? k || …`). This
# suite pins three things: (1) the export REPRODUCES v1's literal set exactly (byte-parity source of truth);
# (2) it stays CONSISTENT with the shim's own facet vocabulary on the keys both own (the load-bearing guard
# — if the compat set and the shim's classifyKey facets drift on a shared key, the corpus skipKey and the
# shim three-branch dispatch diverge); (3) the corpus skipKey shape behaves (structural keys skipped, real
# settings kept).
{ denHoag, denCompat, ... }:
let
  inherit (denCompat.keyClassification) structuralKeysSet;
  # the same value the corpus reaches through `den.lib.aspects.fx.keyClassification` (migrationLib alias).
  aliased = denHoag.aspects.fx.keyClassification.structuralKeysSet;
  # the shim's §2.2 facet vocabulary (concern-aspects `facets`), exported for exactly this consistency check.
  shimFacets = denHoag.internal.facets;
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

    # (2) CONSISTENCY with the shim's own facet vocabulary: the OVERLAP of the shim's facets and the compat
    # structural set is EXACTLY the keys both own (name/description/meta/includes/settings). If either side
    # drifts on a shared facet the overlap changes and this fails — the guard against the corpus skipKey and
    # the shim's classifyKey diverging. The shim-only v2 facets (neededBy/tags/projects/key/id_hash) fall
    # outside v1's set BY DESIGN (byte-parity is against v1, which the corpus reads — not the shim's set).
    test-shim-facet-overlap-pinned = {
      expr = sort (builtins.filter (f: structuralKeysSet ? ${f}) shimFacets);
      expected = [
        "description"
        "includes"
        "meta"
        "name"
        "settings"
      ];
    };
    # each shared facet is classified structurally on BOTH sides: structural in the compat set AND a `facet`
    # by the shim's live classifyKey (not just present in the raw list) — the agreement is behavioural.
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

    # (4) SHAPE B — `classifyKey` derives category from the ONE `keySemantics` map (structural facets FIRST,
    # then the map's `category`). A built-in CLASS key → "class"; the keySemantics facet entries
    # (settings/neededBy/id_hash) → "facet"; a structural built-in option (name/includes) → "facet"; an
    # UNREGISTERED key aborts LOUD (the §2.2 typo posture). (Channels need a per-fleet instance — pinned
    # end-to-end by compat-channel-not-freeform, the #8 witness.)
    test-shapeb-classify-categories = {
      expr = {
        classKey = denHoag.internal.classifyKey "probe" "nixos";
        facetSettings = denHoag.internal.classifyKey "probe" "settings";
        facetNeededBy = denHoag.internal.classifyKey "probe" "neededBy";
        facetIdHash = denHoag.internal.classifyKey "probe" "id_hash";
        structuralName = denHoag.internal.classifyKey "probe" "name";
        unknownAborts =
          (builtins.tryEval (denHoag.internal.classifyKey "probe" "totallyUnknownKey")).success;
      };
      expected = {
        classKey = "class";
        facetSettings = "facet";
        facetNeededBy = "facet";
        facetIdHash = "facet";
        structuralName = "facet";
        unknownAborts = false;
      };
    };
  };
}
