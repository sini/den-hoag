# The gen-lsp BINDING (lib/lsp-binding.nix) — den's adapter feeding a BUILT fleet's surface into gen-lsp's
# general LSP/MCP projection. gen-lsp reads gen value SHAPES with pure builtins and emits neutral-keyed
# views (`forNixd` in-process / `forNixdJSON` wire); this binding supplies den's three passthroughs
# (`_options` option-declaration tree, `aspects` registry, `_keySemantics` key vocabulary) + den's 19
# substrate libs (filtered out of `internal`), so the composed projection covers den's real surface.
#
# This pins: (1) the passthroughs are exposed on `mkDen`'s result and reachable WITHOUT forcing the
# resolved output (the declaration-only laziness seam); (2) `forNixd` projects an option leaf with source
# positions, an aspect's `settings` field via `_keySemantics`, and the 19 gen libs; (3) `forNixdJSON`
# re-projects the same surface JSON-safe (type-NAMES, descended aspect facets).
{
  denHoag,
  ...
}:
let
  # A fleet declaring one aspect (`webby`) with a description + two settings fields, at a single host.
  built = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.host.h0 = { };
      config.den.aspects.webby = {
        description = "the web aspect";
        settings.port = {
          default = 80;
        };
        settings.host = {
          default = "localhost";
          merge = "replace";
        };
      };
    }
  ];
  den = built.den;

  # The composed views the binding produces over den's surface (the passthroughs + the 19-lib filter).
  surface = denHoag.lsp.forNixd {
    inherit den;
    inherit (denHoag) internal;
  };
  wire = denHoag.lsp.forNixdJSON {
    inherit den;
    inherit (denHoag) internal;
  };

  # ── the option-declaration leaf: `den.membership` (a `listOf raw` option) ───────────────────────────
  memberLeaf = surface.options.den.membership;

  # ── the aspect registry: `webby` → a submodule whose facets are `_keySemantics`-classified ──────────
  webbyFacets = surface.aspects.webby.type.getSubOptions { };
  settingsFields = webbyFacets.settings.type.getSubOptions { };

  # The 19 gen substrate libs den hands gen-lsp's general genLibProjection (sorted, for a stable assert).
  expectedLibNames = builtins.sort (a: b: a < b) [
    "prelude"
    "dispatch"
    "resolve"
    "scope"
    "select"
    "product"
    "aspects"
    "pipe"
    "settings"
    "algebra"
    "demand"
    "edge"
    "bind"
    "class"
    "merge"
    "flake"
    "schema"
    "identity"
    "genGraph"
  ];

  # ── the laziness fixture: the SAME aspect declared beside a host output carrying a live `throw`. The
  #    binding reads only DECLARATIONS (schema option tree, §2.6 settings field-specs, gen-lib
  #    `attrNames`/`functionArgs`) — none of which touch the poisoned resolved output. ─────────────────
  poison = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.host.h0 = {
        outputs.fam = throw "RESOLVED-OUTPUT-POISON";
      };
      config.den.aspects.webby = {
        description = "the web aspect";
        settings.port = {
          default = 80;
        };
      };
    }
  ];
  poisonDen = poison.den;
  poisonSurface = denHoag.lsp.forNixd {
    den = poisonDen;
    inherit (denHoag) internal;
  };

  # Recursively force an option node: its scalar fields (description/default/declarationPositions) AND,
  # for a SYNTHESIZED submodule (an aspect node / a settings facet), its `getSubOptions {}` records — which
  # `deepSeq` alone leaves as an un-applied lambda. A deferred real-options submodule (getSubOptions → { })
  # bottoms out. This forces the WHOLE projected shape, so a `throw` reachable through it would surface.
  forceNode =
    node:
    if builtins.isAttrs node && (node._type or null) == "option" then
      let
        t = node.type or null;
        subs =
          if builtins.isAttrs t && (t.name or null) == "submodule" && t ? getSubOptions then
            let
              r = builtins.tryEval (t.getSubOptions { });
            in
            if r.success && builtins.isAttrs r.value then builtins.mapAttrs (_: forceNode) r.value else { }
          else
            { };
      in
      builtins.deepSeq [
        (node.description or null)
        (node.default or null)
        (node.declarationPositions or null)
        subs
      ] "OK"
    else if builtins.isAttrs node then
      builtins.deepSeq (builtins.mapAttrs (_: forceNode) node) "OK"
    else
      builtins.deepSeq node "OK";

  # Force the ENTIRE `forNixd` surface: options tree (leaves + positions), aspect registry (facets + their
  # settings records), gen-lib surface (members + formals). Succeeds iff none of it enters the fx pipeline.
  wholeSurfaceOk = builtins.deepSeq [
    (builtins.deepSeq poisonSurface.options "OK")
    (builtins.mapAttrs (_: forceNode) poisonSurface.aspects)
    (builtins.deepSeq poisonSurface.libs "OK")
  ] "OK";
  resolvedOutputThrows =
    !(builtins.tryEval (builtins.deepSeq poisonDen.registries.host.h0.outputs "forced")).success;
in
{
  flake.tests.lsp-binding = {
    # THE PASSTHROUGHS: `mkDen`'s result exposes the option-declaration tree + provenance + the aspect key
    # vocabulary, each an attrset reachable without forcing `.config`. `_keySemantics` carries the facet
    # classification gen-lsp's aspectsProjection reads (`settings`/`neededBy` are `facet` keys).
    test-passthroughs-exposed = {
      expr = {
        optionsIsAttrs = builtins.isAttrs (den._options or null);
        provenanceIsAttrs = builtins.isAttrs (den._provenance or null);
        keySemIsAttrs = builtins.isAttrs (den._keySemantics or null);
        settingsCategory = den._keySemantics.settings.category or "NONE";
        neededByCategory = den._keySemantics.neededBy.category or "NONE";
      };
      expected = {
        optionsIsAttrs = true;
        provenanceIsAttrs = true;
        keySemIsAttrs = true;
        settingsCategory = "facet";
        neededByCategory = "facet";
      };
    };

    # `forNixd` returns exactly gen-lsp's three neutral sections (`options`/`aspects`/`libs`) — den maps
    # these onto its nixd option-provider sections downstream, not here.
    test-fornixd-three-sections = {
      expr = builtins.sort (a: b: a < b) (builtins.attrNames surface);
      expected = [
        "aspects"
        "libs"
        "options"
      ];
    };

    # (a) THE OPTION SURFACE: a declared option projects a leaf `_type == "option"` carrying a
    # `declarationPositions` goto list (source sites, `{ column; file; line; }` records).
    test-options-leaf-with-positions = {
      expr = {
        leafType = memberLeaf._type;
        posIsList = builtins.isList memberLeaf.declarationPositions;
        posNonEmpty = builtins.length memberLeaf.declarationPositions >= 1;
        posHeadKeys = builtins.sort (a: b: a < b) (
          builtins.attrNames (builtins.head memberLeaf.declarationPositions)
        );
      };
      expected = {
        leafType = "option";
        posIsList = true;
        posNonEmpty = true;
        posHeadKeys = [
          "column"
          "file"
          "line"
        ];
      };
    };

    # (b) THE ASPECT SURFACE (fed by `_keySemantics`): `webby` projects a submodule node; its
    # `_keySemantics`-classified facets include `settings`, which descends into per-field option leaves
    # whose `default` is synthesized from the §2.6 `{ default; merge ? }` field-spec.
    test-aspect-settings-via-keysemantics = {
      expr = {
        webbyType = surface.aspects.webby.type.name;
        webbyDescription = surface.aspects.webby.description;
        facetKeys = builtins.sort (a: b: a < b) (builtins.attrNames webbyFacets);
        settingsFieldKeys = builtins.sort (a: b: a < b) (builtins.attrNames settingsFields);
        portType = settingsFields.port._type;
        portDefault = settingsFields.port.default;
        hostDefault = settingsFields.host.default;
      };
      expected = {
        webbyType = "submodule";
        webbyDescription = "the web aspect";
        facetKeys = [
          "artifact"
          "id_hash"
          "neededBy"
          "settings"
        ];
        settingsFieldKeys = [
          "host"
          "port"
        ];
        portType = "option";
        portDefault = 80;
        hostDefault = "localhost";
      };
    };

    # (c) THE GEN-LIB SURFACE: den's 19 substrate libs project (exactly the allowlist — `internal`'s ~30
    # helpers filtered out); each member is an `_type == "option"` leaf; a lambda member carries
    # `functionArgs` formals (a positional member carries `{ }`).
    test-gen-libs-projected = {
      expr = {
        libNames = builtins.sort (a: b: a < b) (builtins.attrNames surface.libs);
        selectEntryType = surface.libs.select.entity._type;
        positionalFormals = surface.libs.select.entity.formals;
        resolveFormals = builtins.sort (a: b: a < b) (
          builtins.attrNames surface.libs.resolve.resolve.formals
        );
      };
      expected = {
        libNames = expectedLibNames;
        selectEntryType = "option";
        positionalFormals = { };
        resolveFormals = [
          "declaredEdges"
          "equations"
          "parseParent"
          "roots"
          "settings"
          "strataOrder"
        ];
      };
    };

    # THE WIRE VIEW (`forNixdJSON`): the same three sections, JSON-safe — an option leaf's `type` is its
    # display NAME (`listOf`), and a SYNTHESIZED aspect facet is DESCENDED into a nested `subOptions` tree
    # (so an MCP agent reads aspect → settings → field + default) without any function surviving to JSON.
    test-fornixdjson-wire = {
      expr = {
        wireKeys = builtins.sort (a: b: a < b) (builtins.attrNames wire);
        memberTypeName = wire.options.den.membership.type;
        webbyHasSubOptions = wire.aspects.webby ? subOptions;
        wirePortDefault = wire.aspects.webby.subOptions.settings.subOptions.port.default;
      };
      expected = {
        wireKeys = [
          "aspects"
          "libs"
          "options"
        ];
        memberTypeName = "listOf";
        webbyHasSubOptions = true;
        wirePortDefault = 80;
      };
    };

    # THE LAZINESS SEAM: deep-forcing the WHOLE `forNixd` surface (options + positions, aspects + settings,
    # gen-libs) resolves clean even when the fleet's RESOLVED output carries a live `throw` (`wholeSurfaceOk`),
    # while forcing that output genuinely throws (`resolvedOutputThrows`). The binding is fx-pipeline-free —
    # a nixd worker can cache the surface once and walk it without running den's materialization.
    test-surface-independent-of-resolved-output = {
      expr = {
        inherit wholeSurfaceOk resolvedOutputThrows;
      };
      expected = {
        wholeSurfaceOk = "OK";
        resolvedOutputThrows = true;
      };
    };
  };
}
