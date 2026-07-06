{
  prelude,
  algebra,
  types,
  merge,
  schema,
  aspects,
  graph,
  scope,
  resolve,
  select,
  bind,
  dispatch,
  class,
  edge,
  product,
  settings,
  demand,
  pipe,
  flake,
}:
let
  # threaded into sub-module imports; tasks 1–11 extend
  deps = {
    inherit
      prelude
      algebra
      types
      merge
      schema
      aspects
      graph
      scope
      resolve
      select
      bind
      dispatch
      class
      edge
      product
      settings
      demand
      pipe
      flake
      ;
  };
  errors = import ./errors.nix;
  entity = import ./entity.nix { inherit prelude schema merge; };
  fleet = import ./fleet.nix { inherit prelude product errors; };
  buildRootsLib = import ./build-roots.nix { inherit prelude; };
  scopeAdapter = import ./scope-adapter.nix { inherit prelude select; };
  concernQuirks = import ./concern-quirks.nix { inherit prelude pipe errors; };

  # The `projects` facet (§2.9 / A14): the aspect-schema selector domain (`hasSetting` + schemaContext)
  # and the projection-layer expansion. Pure vocabulary over gen-select; resolved-settings consumes
  # `projectionLayers`, `hasSetting` is exposed at the top for writing `projects` rules standalone.
  projectsLib = import ./projects.nix { inherit prelude select errors; };

  # Settings compilation surface (schema + scoped-override layers + ref re-export, §2.6/§4.3) and the
  # linearization declaration surface (§2.7). Both are pure vocabulary over gen-settings / gen-product.
  settingsLib = import ./settings.nix { inherit prelude settings errors; };
  linearizationLib = import ./linearization.nix { inherit prelude product errors; };

  # den-hoag's output classes — the class-separated content buckets on every aspect, and the
  # class-tag vocabulary for quirk contributions (§2.5). The full class registry (wrap/instantiate/
  # share) is Task 6/A10; Task 5 needs only class ENTRIES to tag with, built here from the class
  # names with a stable identity (id_hash) so gen-pipe's duck-typed entry comparison and den's
  # cross-class discipline both key off a real identity (Law A2), never a bare string.
  classNames = [
    "nixos"
    "home-manager"
    "k8s-manifests"
  ];
  classEntries = prelude.genAttrs classNames (name: {
    id_hash = builtins.hashString "sha256" "den-class:${name}";
    inherit name;
  });

  # The declaration vocabulary (verb `declare`) + the policy compiler. `declare` supplies the
  # tagged constructors, stratum classifier, and identity-law checks the structural stratum reads
  # as its `declarations` DEP; concern-policies compiles `den.policies` onto gen-dispatch rules.
  declare = import ./declarations.nix {
    inherit
      prelude
      dispatch
      pipe
      errors
      ;
  };
  concernPolicies = import ./concern-policies.nix { inherit prelude dispatch declare; };

  # The aspects concern — compiles `den.aspects` onto gen-aspects (the neededBy/guard/drop surface
  # + §2.2 key dispatch). `aspectSchema.mkAspectOption` declares `options.den.aspects`.
  concernAspects = import ./concern-aspects.nix {
    inherit
      prelude
      aspects
      merge
      classNames
      errors
      ;
  };

  # Attribute assembly (structural attrs 1–6 + resolution attr 7) + the gen-resolve seam.
  attributesLib = import ./attributes/default.nix {
    inherit
      prelude
      scope
      resolve
      dispatch
      aspects
      select
      pipe
      product
      settings
      settingsLib
      scopeAdapter
      errors
      ;
    projects = projectsLib;
    declarations = declare;
  };
  structuralAttributes = attributesLib.structural;
  runResolve = attributesLib.runResolve;
  inherit (buildRootsLib) buildRoots parseParent;

  # mkDen assembles the four concerns; Tasks 1–11 extend it. Task 1: entity registries
  # (gen-schema) + the fleet restricted product (gen-product). Task 2: scope roots +
  # structural stratum (attributes 1–6) over gen-resolve/gen-scope.
  mkDen =
    userModules:
    let
      # den-managed module: the fleet membership channel. Task 1 bootstrap surface — the
      # fixture sets these tuples directly. Task 3 dispatches `member` declarations (they land in
      # the `declarations` attribute's structural group); routing them back into this membership
      # channel is part of the Task 4 P-tree/edge wiring.
      membershipDecl = {
        options.den.membership = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Fleet membership tuples { coords; via ? null; } (A5).";
        };
      };

      # den.policies.<name> = ctxFn — the relationships concern. Each value is a context
      # function (opaque, function-valued), so `raw` holds it without a merge attempt.
      policiesDecl = {
        options.den.policies = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Relationship policies: `<name> = ctx: [ declarations ]` (r2 §B).";
        };
      };

      # den.aspects.<name> — the behavior concern (aspectsType). Compiled onto gen-aspects by
      # concern-aspects; each entry carries `key`/`neededBy`/`meta.guard`/`meta.drop`/`includes`.
      aspectsDecl = {
        options.den.aspects = concernAspects.aspectSchema.mkAspectOption { };
      };

      # den.include — the static entity-scoped aspect-inclusion surface (r2 §370 `directAspects`):
      # each `{ at = <entity>; aspects = [ <aspect> ]; }` seeds its aspects at exactly the entity's
      # own scope node (node-local, so an include at an ancestor does not seed descendants).
      includeDecl = {
        options.den.include = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Static entity-scoped aspect inclusions: [ { at = <entity>; aspects = [ <aspect> ]; } ].";
        };
      };

      # den.quirks.<name> — the data concern (§2.5). Each entry declares a gen-pipe channel plus
      # optional dataflow `ops` and cross-class `adapters`; concern-quirks assembles every quirk (and
      # its ops) into ONE fleet-level compose. `raw` holds the (channel/ops/adapters) record unmerged.
      quirksDecl = {
        options.den.quirks = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Quirk channels: `<name> = { channel ? {}; ops ? []; adapters ? []; }` (§2.5).";
        };
      };

      # den.linearization.dims — the slice-order declaration surface (§2.7): a total order on the
      # product DIMENSIONS as KIND entries (identity law A2), least→most specific. Empty (the default)
      # means "canonical" — den-hoag fills it with the name-sorted kind entries, preserving the pre-
      # concern behavior. `raw` holds the entry list unmerged.
      linearizationDecl = {
        options.den.linearization.dims = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Slice-order dimensions (§2.7): [ <kind entry> ], least→most specific (identity law A2).";
        };
      };

      # den.settings.layers — the scoped-override surface (§2.6 source 2), the `at`-record form:
      # [ { at = <partial coords, entries>; of = <aspect entry>; set = { <field> = <value|ref> }; via ? null } ].
      # `raw` holds each layer record unmerged (its `at`/`of` are entries, `set` a patch).
      settingsDecl = {
        options.den.settings.layers = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Scoped settings overrides (§2.6): [ { at; of; set; via ? null } ].";
        };
      };

      # den.contentClass.<kind> — the class-tag vocabulary (§2.1/§2.5): the output class a kind's
      # scopes produce, as a class-name string (resolved to the class entry) or a class entry; a kind
      # with no mapping is class-neutral (e.g. env). den v2's canonical home is
      # `den.schema.<kind>.contentClass`; gen-schema kinds carry no such field, so den-hoag threads it
      # as a parallel den-managed map. Absent for every kind ⇒ a policy-free / quirk-free fleet stays
      # entirely class-neutral, exactly as before this concern existed.
      contentClassDecl = {
        options.den.contentClass = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Kind -> content class (class name or entry): the class a kind's scopes produce (§2.5).";
        };
      };

      denMeta = entity.discoverKinds userModules;
      ent = entity.build {
        userModules = [
          membershipDecl
          policiesDecl
          aspectsDecl
          includeDecl
          quirksDecl
          contentClassDecl
          linearizationDecl
          settingsDecl
        ]
        ++ userModules;
        inherit denMeta;
      };

      # v1 dims = every registered kind, canonical (name-sorted) order. den.linearization
      # takes over the dim order in Task 6.
      dimKinds = prelude.sort (a: b: a < b) (builtins.attrNames ent.registries);
      membershipTuples = ent.config.den.membership;

      theFleet = fleet.mkFleet {
        inherit (ent) registries;
        inherit dimKinds membershipTuples;
      };

      # Scope-tree partition (r2 containment skeleton): a CELL kind is a topology leaf that
      # has a parent (its instances materialize under that parent as `children`); every other
      # kind's instances are flat scope roots. A leaf with no parent (a standalone kind) stays
      # a root. Task 2's fixture has one cell kind (`user`); multi-cell-kind generalization is
      # deferred to the spawn-declaration wiring (Task 3).
      allKinds = builtins.attrNames ent.meta;
      parentKinds = prelude.unique (
        builtins.filter (p: p != null) (map (k: ent.meta.${k}.parent) allKinds)
      );
      cellKinds = builtins.filter (
        k: !(builtins.elem k parentKinds) && ent.meta.${k}.parent != null
      ) allKinds;
      rootScopeKinds = builtins.filter (k: !(builtins.elem k cellKinds)) allKinds;
      leafKind = if cellKinds == [ ] then null else builtins.head cellKinds;
      cellParentKind = if leafKind == null then null else ent.meta.${leafKind}.parent;

      scopeRoots = buildRoots {
        inherit (ent) registries;
        roots = rootScopeKinds;
      };

      # The `children` NTA's fleet arm: a host node spawns its cells; other nodes spawn none.
      fleetChildren =
        self: id:
        let
          node = self.node id;
        in
        if cellParentKind != null && node.type == cellParentKind then
          fleet.cellChildrenFor {
            fleet = theFleet;
            parentDim = cellParentKind;
            hostEntry = node.decls.__entry;
            hostNodeId = id;
            leafDim = leafKind;
          }
        else
          { };

      # Resolve a `link` target entry to the scope node whose enriched-context feeds §B3
      # linked-context. Root-kind targets map to their flat root id `"${kind}:${name}"`; the
      # index is over the entity registries (not scope nodes), so this stays demand-safe. Cell
      # targets resolve through the edge stratum in Task 4 (null here).
      entryNodeIndex = prelude.foldl' (
        acc: kindName:
        prelude.foldl' (
          acc': name:
          let
            e = ent.registries.${kindName}.${name};
          in
          acc'
          // {
            ${e.id_hash} = {
              kind = kindName;
              nodeId = "${kindName}:${name}";
            };
          }
        ) acc (builtins.attrNames ent.registries.${kindName})
      ) { } rootScopeKinds;
      linkTarget = entry: entryNodeIndex.${entry.id_hash} or null;

      # Compile the relationships concern (den.policies) into the enrich / policy rule feeds.
      # The fixture carries no policies, so both feeds are empty and the fleet builds as before.
      policiesRules = concernPolicies.compile ent.config.den.policies;

      # The quirks concern: ONE fleet-level gen-pipe.compose over every declared channel (+ its ops);
      # channel-name uniqueness (E4b) and reference closure (E4a) are therefore fleet-wide. Policy
      # route/join/tee ops are collected fleet-wide with the demand/edge wiring (Task 8+); per-quirk
      # `ops` cover intra-compose shaping until then, so policyOps is empty here.
      quirks = ent.config.den.quirks;
      channelNames = concernQuirks.channelNames quirks;
      quirkDag = concernQuirks.compose {
        inherit quirks;
        policyOps = [ ];
      };

      # classOfNode — the producing-scope → class-entry function (§2.5). Resolve each kind's declared
      # `contentClass` (a class-name string or an entry) to a class entry; a kind with no mapping is
      # class-neutral. Reuses entity.classOf (which also handles the per-host function form) by
      # enriching ent.meta with the resolved contentClass entry.
      resolveClass =
        cc:
        if cc == null then
          null
        else if builtins.isString cc then
          classEntries.${cc}
            or (throw "den-hoag: den.contentClass names unknown class `${cc}` (known: ${builtins.concatStringsSep ", " classNames})")
        else
          cc;
      metaWithClass = builtins.mapAttrs (
        k: m: m // { contentClass = resolveClass (ent.config.den.contentClass.${k} or null); }
      ) ent.meta;
      classOfNode = entity.classOf {
        meta = metaWithClass;
        entityOfNode = node: node.decls.__entry or null;
      };

      equations = attributesLib.equations {
        inherit policiesRules fleetChildren linkTarget;
        allAspects = ent.config.den.aspects;
        directIncludes = ent.config.den.include;
        inherit quirkDag classOfNode channelNames;
        fleet = theFleet;
        inherit
          lin
          settingsLayers
          dimKinds
          projectors
          ;
      };

      structural = runResolve {
        roots = scopeRoots;
        inherit equations parseParent;
      };

      # The narrow accessor (A10, §2.8) at any scope node: `aspects.<name> = { present; settings; }`,
      # over the FINAL eval (`structural.eval`). Consumed as the `aspects` module arg at output
      # assembly (Task 9); exposed here so the settings/cross-aspect surface is readable standalone.
      aspectsAt = attributesLib.mkNarrowAccessor ent.config.den.aspects structural.eval;

      # The fleet channel outputs — one gen-pipe.run over the neron traversal, for the class-relative
      # read (concernQuirks.consumeAt) at output assembly (Task 6). `.at pos` selects any position; it
      # is the same run attribute 11 (received-collections) computes per node inside the schedule.
      # DRIFT NOTE: this traversal adapter MUST stay identical to attribute 11's (lib/attributes/
      # collections.nix received-collections) — both are assembled from the same three
      # `scopeAdapter.traversalAdapter` components (neron order / local-collection-data / classOfNode),
      # differing only in whose eval they read (final `structural.eval` here vs the in-flight `self`
      # there). Divergence would silently make consumeAt and the attribute disagree.
      receivedOutputs = pipe.run {
        dag = quirkDag;
        traversal = scopeAdapter.traversalAdapter {
          result = structural.eval;
          localDataOf = pos: chName: (structural.eval.get pos "local-collection-data").${chName} or [ ];
          classesOfNode =
            node:
            let
              c = classOfNode node;
            in
            if c == null then [ ] else [ c ];
        };
      };

      # Slice-order linearization (§2.7). `den.linearization.dims` declares the dimension order as
      # KIND entries; empty ⇒ canonical (name-sorted kind entries), preserving the pre-concern order.
      # linearizationLib validates totality/identity and renders entries → product dim names (Law A1:
      # the count-major slice key lives in gen-product).
      declaredDims = ent.config.den.linearization.dims or [ ];
      linDims = if declaredDims == [ ] then map (k: ent.kinds.${k}) dimKinds else declaredDims;
      lin = linearizationLib.linearization {
        dims = linDims;
        productDims = dimKinds;
      };

      # Scoped settings overrides (§2.6) compiled to internal den-layer records (validated: `of` an
      # aspect entry, `at` dims ∈ product). resolved-settings folds them per (cell, aspect) by §2.7.
      settingsLayers = settingsLib.compileLayers {
        layers = ent.config.den.settings.layers or [ ];
        productDims = dimKinds;
      };

      # Projecting aspects (§2.9 / A14, the `projects` facet): each aspect declaring a non-empty
      # `projects`, paired with its ATTACHMENT scopes — the containment position `{ <kind> = entity }`
      # of every entity it is directly included at (`den.include`). v1 uses the static include surface
      # as the introduction source; policy / neededBy / edge introduction is deferred: deriving it would
      # require per-node scope derivation inside the resolve loop (projectors are pre-computed as a
      # static list before it) — an implementation-complexity deferral, not a formal A9 violation. The projection
      # LAYERS are expanded in resolved-settings (`projectionLayersAt`); this only resolves attachment.
      entityKindOf =
        let
          index = prelude.foldl' (
            acc: kindName:
            prelude.foldl' (
              acc': name: acc' // { ${ent.registries.${kindName}.${name}.id_hash} = kindName; }
            ) acc (builtins.attrNames ent.registries.${kindName})
          ) { } (builtins.attrNames ent.registries);
        in
        entry: index.${entry.id_hash};
      allAspects = ent.config.den.aspects;
      projectors =
        let
          scopesOf =
            aspect:
            prelude.concatMap (
              inc:
              if builtins.any (x: (x.id_hash or null) == aspect.id_hash) inc.aspects then
                [ { ${entityKindOf inc.at} = inc.at; } ]
              else
                [ ]
            ) (ent.config.den.include or [ ]);
        in
        map (name: {
          aspect = allAspects.${name};
          scopes = scopesOf allAspects.${name};
        }) (builtins.filter (n: (allAspects.${n}.projects or [ ]) != [ ]) (builtins.attrNames allAspects));
    in
    {
      den = {
        schema = ent.kinds;
        inherit (ent) registries meta roots;
        aspects = ent.config.den.aspects;
        fleet = theFleet;
        cells = product.cells theFleet;
        inherit dimKinds;
        linearization = lin;
        scopeRoots = scopeRoots;
        inherit structural;
        # The quirks concern surface: class entries (the class-tag vocabulary), the ONE composed
        # channel DAG, and the fleet channel outputs (`.at pos` → per-position channel values, and the
        # input to the class-relative read `internal.consumeAt`).
        classes = classEntries;
        inherit quirkDag receivedOutputs;
        # Settings resolution surface (§2.6/§2.7/§2.8): the compiled scoped-override layers, and the
        # narrow accessor `aspectsAt <nodeId> = { <aspectName> = { present; settings; }; }` (A10).
        inherit settingsLayers aspectsAt;
      };
    };
in
{
  inherit errors mkDen;
  # den's selector vocabulary (identity-law entry/kind constructors + adapters); used to
  # write declarations, independent of any one mkDen instance.
  sel = select;

  # den's `projects`-facet sugar (§2.9 / A14): `hasSetting <field>` = a STATIC selector matching every
  # aspect that declares `<field>` in its settings schema — the address side of a projection rule
  # (`projects = [ { select = hasSetting "theme"; set = { theme = …; }; } ]`). Independent of any one
  # mkDen instance; the aspect-schema selector domain is den-hoag-owned (see lib/projects.nix).
  inherit (projectsLib) hasSetting;
  # den's class-tag vocabulary (the fixed class entries, identity-law A2): the same entries every
  # mkDen tags contributions with, exposed for writing quirk `adapters` (cross-class coercions) that
  # reference a class by its entry rather than a bare name.
  classes = classEntries;
  # den's declaration vocabulary (verb): the tagged constructors + stratum classifier +
  # identity-law checks, independent of any one mkDen instance. Policies read `declare.member`,
  # `declare.edge`, etc.
  inherit declare;

  # den's settings vocabulary, independent of any one mkDen instance: `ref` (cross-aspect reference
  # data, §2.8) and the linearization declaration helper (§2.7). `settings` re-exports gen-settings'
  # `ref`; `linearization` is the totality-checked dim-order wrapper.
  inherit (settingsLib) ref;
  linearization = linearizationLib.linearization;

  # Internal builders + raw gen libs — for constructing minimal scenarios in the suite
  # (structural equations over hand-built roots/rules), not a public API.
  internal = {
    inherit
      buildRoots
      parseParent
      runResolve
      scopeAdapter
      ;
    structural = structuralAttributes;
    compilePolicies = concernPolicies.compile;
    inherit (concernAspects) classifyKey;
    # The quirks concern's composer + class-relative read, for the suite's channel scenarios.
    inherit (concernQuirks) compose consumeAt;
    # Settings/linearization builders + the raw gen-settings/gen-algebra surfaces, for the suite's
    # A7/A16 direct-function and byte-parity scenarios (foldLayers reference; linearization errors).
    inherit settingsLib linearizationLib;
    inherit
      dispatch
      resolve
      scope
      select
      product
      aspects
      pipe
      settings
      algebra
      ;
  };
}
