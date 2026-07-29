# Attribute 13 — resolved-settings (r2 §2.10 #13 / §2.7). Per `(node, aspect)` the ordered layer
# list — containment chain (gen-product) × D/I chain (gen-scope) × the terminal policy slot — folded
# by `gen-settings.resolveAll`. Every body here is WIRING (field reads, list filters, attrset
# assembly) over exactly one algorithm: the `gen-product.containmentChain` slice order and the
# `gen-settings.resolveAll` fold (Law A1). The attribute VALUE is inert data
# (`{ <aspectName> = { value; provenance; }; }`), never a loop record.
#
# STRATIFICATION LAW (A9 / A16). resolved-settings is a RESOLUTION-stratum attribute: it reads
# structure (the node's coordinates) and PRESENCE (resolved-aspects, attribute 7) — never the
# reverse. The presence fixpoint (attribute 7) never reads settings (its guards see only
# `{ pathSet, hasAspect }`, A9.1), so there is no cycle and the least fixpoint stays sound. The
# `.value` is byte-identical to a plain `foldLayers` over the same layer list (A16); provenance
# lists every layer in §2.7 order.
#
# LAYER ORDER (§2.7). `[ default ] ++ concatMap (slice: projection ++ direct) chain ++ policy`:
#   - `default`  — the schema defaults, injected by gen-settings' fold as the leading entry
#                  (defaultLabel); den-hoag emits no explicit default layer.
#   - `chain`    — `containmentChain fleet coords lin`, least→most specific; per slice the
#                  projection layers (§2.9, `via != null`) sort immediately before that slice's
#                  direct override layers (`via == null`), both from `den.settings.layers`.
#   - `policy`   — `configure` declarations at this node (attribute 4's resolution group), always in
#                  the terminal slot (A8, authority-wins by position).
#
# Deps: prelude (folds/filters), product (containmentChain), settings (resolveAll),
# settingsLib (schema/layer compilation), errors (absentAspectSetting). The facet is emitted as a
# `den.productions` record (`mkSettingsProduction`); concern-productions' `compile` wraps its `compute`
# in the synthesized `resolve.attr` — no direct `resolve` dep here. Instance args: fleet (the
# restricted gen-product), lin (the linearization record), settingsLayers (compiled den-layer
# records), dimKinds (product dimension names, for the containment chain), coords (the coordinate
# projections over the `contains` edge pool — lib/coordinates.nix, THE derivation of a node's position).
{
  prelude,
  product,
  settings,
  settingsLib,
  projects,
  errors,
}:
let
  # An identity-bearing aspect entry from a resolved aspect's content (id_hash added by the aspect
  # submodule's idModule; name is the display key). gen-settings routes the batch + refs by id_hash.
  entryOf = content: {
    inherit (content) name id_hash;
  };

  # `configure` policy layers at this node for this aspect → the terminal `policy` slot (A8). The
  # layer carries the coordinates the policy fired at (§4.3); `via` is null (den policies are not
  # identity-bearing entries), the `rendered` label marks the terminal slot for goldens.
  policyLayersAt =
    resolutionActs: nodeCoords: aspectEntry:
    map
      (a: {
        scope = nodeCoords;
        rendered = "policy";
        via = null;
        value = a.set;
      })
      (
        builtins.filter (a: a.__action == "configure" && a.of.id_hash == aspectEntry.id_hash) resolutionActs
      );

  # The settings resolution facet AS a den.productions record (§5, Phase 5a — dogfooded through the surface).
  # Instead of a hand-wired `resolve.attr`, the framework SEEDS this production (keyed by the attr it emits,
  # `resolved-settings`) into `den.productions`; concern-productions' `compile` turns it back into the exact
  # same synthesized `resolve.attr` it always was (PASSTHROUGH over this `compute`). Behavior is byte-identical
  # — only the declaration PATH changed (from a bespoke equation to the general production surface). Instance
  # args pin the fleet product + linearization + compiled layers, captured by the `compute` closure.
  mkSettingsProduction =
    {
      fleet,
      lin,
      settingsLayers,
      dimKinds,
      allAspects ? { },
      projectors ? [ ],
      # Is this NODE a CELL? (`build-roots.nix isCellNode` — the constructor TAG test.) Required, not
      # defaulted: the chain builder below picks the cell branch on it, and a defaulted `_: false`
      # would silently make every cell read its OWN containment ancestors instead of its parent root's.
      isCellNode,
      # THE COORDINATE PROJECTIONS over the `contains` edge pool (lib/coordinates.nix), built once per
      # fleet and shared with every other reader of a node's position. Required, not defaulted: this is
      # the only derivation of where a node sits, and a default would be a second one.
      coords,
    }:
    let
      inherit (coords)
        coordOf
        cellCoordsOf
        nodeCoords
        ancestorSlicesOf
        coordsEq
        ;

      # A14 (projects facet) — `projectionLayersAt`: expand every projecting aspect into `via`-carrying
      # den-layer records at its attachment scopes, added to the scoped-override pool. resolved-settings
      # then folds them exactly like a hand-written `via` layer — projection (via != null) sorts
      # immediately before same-slice direct overrides (§2.7 / `layersAtSlice`), and the containment-chain
      # fold applies a fleet-scope projection ONCE per node (A14 constraint 1), never re-emitting it per
      # descendant. The projects lib enforces the static-selector (A14.2) and same-scope collision (A14.3)
      # disciplines during this expansion. Empty when no aspect declares `projects` ⇒ byte-identical to
      # the pre-facet pool (additive/experimental).
      projectionLayersAt = projects.projectionLayers {
        inherit allAspects projectors;
        matchAddresses = builtins.attrNames allAspects;
      };
      poolLayers = settingsLayers ++ projectionLayersAt;

      # den-layer records declared AT one slice, FOR one aspect (batch routing by `of.id_hash`).
      # Projection layers (§2.9, `via != null`) sort immediately before direct overrides at the same
      # slice (§2.7): a direct declaration beats a projection attached at that scope.
      layersAtSlice =
        aspectEntry: sliceFixed:
        let
          here = builtins.filter (
            l: l.of.id_hash == aspectEntry.id_hash && coordsEq l.atCoords sliceFixed
          ) poolLayers;
          projection = builtins.filter (l: l.via != null) here;
          direct = builtins.filter (l: l.via == null) here;
        in
        map settingsLib.toGenLayer (projection ++ direct);
    in
    {
      # §5 production record — the settings resolution facet. LOWER-ONLY: emit = attr @ the `resolution`
      # stratum, mode = all (a within-stratum passthrough, never a fixpoint). `from` is the DECLARED SOURCE
      # CONTRACT (drives the L2 gate for user productions, documents it here): the containment `query` reads
      # STRUCTURAL coordinates (`product.containmentChain`, strictly below `resolution`); the layer `pool` is
      # EDB (`settingsLayers`/projection, no stratum ⇒ compares below every stratum, L2-clean). `readsAttrs`
      # names the compute-internal `self.get` reads — `resolved-aspects` (SAME-stratum, A9-legit) and
      # `declarations` (structural); these are NEVER `from`-sources (L2 gates `from` only, §5 L2).
      stratum = "resolution";
      from = [
        {
          kind = "query";
          stratum = "structural";
        }
        { kind = "pool"; }
      ];
      emit = "attr";
      mode = "all";
      discipline = "settings-layers";
      readsAttrs = [
        "resolved-aspects"
        "declarations"
      ];
      compute =
        self: id:
        let
          node = self.node id;
          nodeOf = self.node;
          isCell = isCellNode node;
          # THE ARM IS THE CONSTRUCTOR TAG, NOT A CARDINALITY. The retired test compared the coordinate
          # key COUNT against `|dimKinds|`, which a root polluted by user bindings passes with the wrong
          # keys — measured, a root whose `containTo` member carries one binding key counts 2 against
          # 2 dims and is routed down the CELL arm. `isCellNode` is right on that same input, and as a
          # node FIELD rather than a `decls` key no user-named binding can write it.
          #
          # `containmentChain` needs the full product coordinate; a root fixes only its own slice, whose
          # subsets (∅ ⊂ own-slice) are ⊆-comparable and need no linearization tie-break.
          baseChain =
            if isCell then
              map (e: e.fixed) (product.containmentChain fleet (cellCoordsOf nodeOf id) lin)
            else
              [
                { }
                (coordOf nodeOf id)
              ];
          # The cascade slices — the containment closure MINUS what `baseChain` already carries, in
          # LEAST-SPECIFIC-FIRST order, prepended AFTER the empty slice so the fold order is
          # default < env < host < user (the owner's cascade). `baseChain` always leads with the empty
          # slice, so [ ∅ ] ++ ancestors ++ tail keeps every product slice in its original relative order.
          #
          # ★ THAT ORDER IS A TOPOLOGICAL ONE AND IT HAS TO BE. This fold is positional — gen-settings
          # gives authority to the LAST contributor and does not reorder — so a containment ancestor
          # emitted after something it contains overrides its own descendant. `lib/coordinates.nix` ranks
          # the closure with gen-graph's `coneRank` rather than reusing the traversal's emission sequence
          # precisely because the two differ on any DAG (`ci/tests/containment-edges.nix`, witness O).
          # A CELL reads its parent root's containment ancestors; a ROOT reads its own. Discriminated by
          # the constructor tag, not by parentage nor by the id's shape — a root carrying a containment
          # parent still owns its own ancestor slices, and a multi-attached root's id carries an '@',
          # so either of those spellings would send such a root to read its parent's instead.
          ancSlices = ancestorSlicesOf nodeOf (if isCell then node.parent else id) baseChain;
          chain = [ (builtins.head baseChain) ] ++ ancSlices ++ (builtins.tail baseChain);

          present = self.get id "resolved-aspects";
          resolutionActs = (self.get id "declarations").actions.resolution or [ ];

          # ONE resolveAll batch over every present aspect at this node (cross-aspect `ref` routing
          # is by id_hash across the batch, §2.8). Keyed by aspect name for the narrow accessor.
          batch = map (
            a:
            let
              aspectEntry = entryOf a.content;
            in
            {
              schema = settingsLib.mkSchemaFor aspectEntry (a.content.settings or { });
              # The terminal policy slot's `scope` is the node's OWN coordinate on whichever arm it is on
              # — the same value `baseChain` already ends with, not a fourth projection. It is PROVENANCE
              # ONLY: policy layers are appended after the chain fold and are never matched (`layersAtSlice`
              # reads a layer's own `atCoords`), and gen-settings passes the value fold its layers and its
              # labels as SEPARATE arguments, so a label cannot reach the fold even in principle.
              layers =
                prelude.concatMap (sliceFixed: layersAtSlice aspectEntry sliceFixed) chain
                ++ policyLayersAt resolutionActs (nodeCoords nodeOf id) aspectEntry;
              key = a.content.name;
            }
          ) present;
          resolved = settings.resolveAll { inherit batch; };
        in
        prelude.foldl' (
          acc: a:
          acc
          // {
            ${a.content.name} = {
              value = resolved.value.${a.content.name};
              provenance = resolved.provenance.${a.content.name};
            };
          }
        ) { } present;
    };

  # The narrow accessor (A10, §2.8) — the `aspects` module arg at output assembly. For every declared
  # aspect NAME, exactly `{ present; settings; }`: `present` = projected/delivered presence at this
  # scope; `settings` = the aspect's resolved settings, or a named abort if absent (check `.present`
  # first). Content→content is unexpressible — only these two fields cross. Independent of the
  # resolved-settings instance args (needs only the aspect registry + the eval), so den-hoag builds it
  # once from `config.den.aspects` and the final eval.
  mkNarrowAccessor =
    allAspects: self: id:
    let
      present = self.get id "resolved-aspects";
      presentNames = map (n: n.content.name) present;
      rs = self.get id "resolved-settings";
    in
    builtins.mapAttrs (name: _def: {
      present = builtins.elem name presentNames;
      settings =
        if builtins.elem name presentNames then rs.${name}.value else errors.absentAspectSetting name id;
    }) allAspects;
in
{
  inherit mkSettingsProduction mkNarrowAccessor;
}
