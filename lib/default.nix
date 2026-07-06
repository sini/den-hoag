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
  scopeAdapter = import ./scope-adapter.nix { inherit select; };

  # den-hoag's output classes — the class-separated content buckets on every aspect. The classes
  # concern (Task 5/6) will own this list; until then it is den-hoag's default target set.
  classNames = [
    "nixos"
    "home-manager"
    "k8s-manifests"
  ];

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
      errors
      ;
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

      denMeta = entity.discoverKinds userModules;
      ent = entity.build {
        userModules = [
          membershipDecl
          policiesDecl
          aspectsDecl
          includeDecl
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

      equations = attributesLib.equations {
        inherit policiesRules fleetChildren linkTarget;
        allAspects = ent.config.den.aspects;
        directIncludes = ent.config.den.include;
      };

      structural = runResolve {
        roots = scopeRoots;
        inherit equations parseParent;
      };

      lin = product.linearizeByDimOrder dimKinds;
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
      };
    };
in
{
  inherit errors mkDen;
  # den's selector vocabulary (identity-law entry/kind constructors + adapters); used to
  # write declarations, independent of any one mkDen instance.
  sel = select;
  # den's declaration vocabulary (verb): the tagged constructors + stratum classifier +
  # identity-law checks, independent of any one mkDen instance. Policies read `declare.member`,
  # `declare.edge`, etc.
  inherit declare;

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
    inherit
      dispatch
      resolve
      scope
      select
      product
      aspects
      ;
  };
}
