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
# records), dimKinds (product dimension names, for the full-cell test), containmentRelations (the
# staged pre-pass's env→host / env→cluster ancestor slices — the §3c-UNIFIED chain extension).
{
  prelude,
  product,
  settings,
  settingsLib,
  projects,
  errors,
  graph,
}:
let
  # Reserved decls keys are graph machinery, never producing-scope coordinates (mirrors
  # collections.nix coordDims; `__coords` is the full-cell coordinate cache added for this attribute).
  coordDims =
    node:
    removeAttrs (node.decls or { }) [
      "__entry"
      "__edges"
      "__containment"
      "__coords"
    ];

  # An identity-bearing aspect entry from a resolved aspect's content (id_hash added by the aspect
  # submodule's idModule; name is the display key). gen-settings routes the batch + refs by id_hash.
  entryOf = content: {
    inherit (content) name id_hash;
  };

  # Two coordinate sets denote the same slice iff same dims and same entry identities (by id_hash).
  coordsEq =
    a: b:
    builtins.attrNames a == builtins.attrNames b
    && builtins.all (d: (a.${d}.id_hash or null) == (b.${d}.id_hash or null)) (builtins.attrNames a);

  # The full product coordinates of a node: a cell caches them at `decls.__coords` (all product
  # dims → entries), a flat root carries only its own single dim (coordDims).
  coordsOfNode = node: node.decls.__coords or (coordDims node);

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
      # §3c-UNIFIED chain extension: the staged pre-pass's containment relations (nodeId -> [ source slice ]).
      # A `containTo`-marked member recorded the target root's SOURCE coordinate (the env→host / env→cluster
      # edge); it is NOT a product dimension, so gen-product's `containmentChain` (over the product dims)
      # cannot produce its slice — den-hoag PREPENDS it here, after the empty slice, giving the settings fold
      # default < env < host < user (the owner's cascade). Default `{ }` ⇒ no env slice, byte-identical.
      containmentRelations ? { },
      # Is this node id a CELL? (`build-roots.nix isCell` — the constructor case analysis over the id
      # shape.) Required, not defaulted: the chain builder below picks the cell branch on it, and a
      # defaulted `_: false` would silently make every cell read its OWN containment ancestors instead
      # of its parent root's.
      isCell,
    }:
    let
      # Transitive containment-relation ancestors of a node (least→most specific `fixed` coord-sets). Each
      # ancestor slice is single-kind ({ <kind> = entry }); the reversed pre-order emission (below) puts
      # the deepest source first, so a multi-level chain (fleet→env→host) resolves least-specific first.
      # Empty for a node with no containment relation (the corpus's environment root, and every native
      # fleet without a containTo member) ⇒ the chain is byte-identical to the pre-§3c product chain.
      # CYCLE GUARD (loud-error discipline): a cyclic `containTo` topology (A contains B contains A)
      # aborts NAMED (`errors.containmentCycle`) instead of hanging. Corpus-unreachable (a v1-surface
      # adapter's source coordinate strictly ascends the acyclic schema topology); a native fixture can
      # author it.
      ancNodeId =
        slice:
        let
          k = builtins.head (builtins.attrNames slice);
        in
        "${k}:${slice.${k}.name}";
      # Containment-edge accessor over the MULTI-VALUED `containmentRelations` map (nid -> [ source
      # slice ]): a node id's upward edges are the ids of its containment-ancestor slices. This is a
      # separate map from the single-parent self-graph P-edge (`node.parent`) — a node may sit under
      # several containment sources — so it is untraversable by a single-parent inherit walk and is a
      # genuine graph accessor. `containEdges`/`sliceById` only touch the containment topology + slice
      # names (id strings), never aspect/settings content.
      containEdges = nid: map ancNodeId (containmentRelations.${nid} or [ ]);
      # Ancestor id back to the single-kind coord-set it names: every slice is an entry in some node's
      # `containmentRelations` list, and its id (`kind:name`) is its identity.
      sliceById = builtins.listToAttrs (
        prelude.concatMap (
          nid:
          map (s: {
            name = ancNodeId s;
            value = s;
          }) (containmentRelations.${nid} or [ ])
        ) (builtins.attrNames containmentRelations)
      );
      # The containment-ancestor upward closure, routed through gen-graph. `expandPreorder` carries the
      # slice payload and visits in first-occurrence PRE-order (nearest-first over `containEdges`);
      # reversing it yields the LEAST-specific-first emission the settings-precedence fold consumes at
      # `chain` (default < env < host < user, ORDER load-bearing). `cycles`/`selfReachable` over the
      # SAME edge accessor is the loud back-edge guard — a cyclic `containTo` topology throws NAMED
      # (`errors.containmentCycle`) rather than hanging. SEMANTICS-NORMALIZING vs the prior hand-rolled
      # path-scoped grey-set DFS over a BRANCHING ancestor forest, on TWO off-corpus deltas: (1) gen-graph's
      # global first-occurrence visited set dedups a diamond (shared-grandparent) slice the path-scoped walk
      # emitted TWICE (a latent duplicate-layer fix); (2) reverse-of-pre-order ≠ the old post-order for
      # SIBLING branches, so two ancestors of one node fold in the opposite relative order (sibling
      # precedence is unspecified either way). Byte-neutral on the corpus, whose containment is single-source
      # / linear / acyclic — `containmentRelations.<nid>` is singleton|empty, so neither a diamond nor a
      # sibling forest is reachable and both deltas are latent.
      # Dep-free list reversal (gen-prelude keeps its own `reverseList` internal to `toposort`): turns
      # gen-graph's nearest-first pre-order into the least-specific-first emission the fold consumes.
      reverseList =
        xs:
        let
          l = builtins.length xs;
        in
        builtins.genList (n: builtins.elemAt xs (l - n - 1)) l;
      ancestorsOf =
        nid:
        let
          walk = graph.expandPreorder {
            roots = containEdges nid;
            key = anc: anc;
            edges = containEdges;
            emit = anc: _payload: sliceById.${anc};
          };
          cyclic = graph.cycles {
            edges = containEdges;
            nodes = builtins.attrNames walk.seen;
          };
        in
        if cyclic == [ ] then reverseList walk.nodes else errors.containmentCycle (builtins.head cyclic);

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
          coords = coordsOfNode node;
          # containmentChain needs a full cell; a flat root fixes ≤1 dim, whose only subsets
          # (∅ ⊂ own-slice) are ⊆-comparable and need no linearization tie-break.
          isFullCell = builtins.length (builtins.attrNames coords) == builtins.length dimKinds;
          baseChain =
            if isFullCell then
              map (e: e.fixed) (product.containmentChain fleet coords lin)
            else
              [
                { }
                coords
              ];
          # §3c-UNIFIED chain extension: prepend the containment-relation ancestor slices (env→host /
          # env→cluster) AFTER the empty slice, so the fold order is default < env < host < user (the
          # owner's cascade). A cell inherits its parent root's ancestors (`node.parent`); a root reads
          # its own (`id`). `baseChain` always leads with the empty slice, so [ ∅ ] ++ ancestors ++ tail
          # keeps every product slice in its original relative order (byte-neutral when ancestors = [ ]).
          # A CELL reads its parent root's containment ancestors; a ROOT reads its own. Discriminated by
          # the constructor test, not by parentage — a root carrying a containment parent still owns its
          # own ancestor slices, and a `parent == null` spelling would send it to read its parent's.
          ancSlices = if isCell id then ancestorsOf node.parent else ancestorsOf id;
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
              layers =
                prelude.concatMap (sliceFixed: layersAtSlice aspectEntry sliceFixed) chain
                ++ policyLayersAt resolutionActs coords aspectEntry;
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
