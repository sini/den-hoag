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

  # Minimal declaration vocabulary for the structural stratum (Task 2). Task 3 replaces it
  # with the real declaration constructors + kind classifier. `classify` names a declaration's
  # KIND (enrich/member/configure/edge/demand) from its `__kind` tag — distinct from the B2
  # STRATUM (structural/resolution/collection), which `kindToStratum` maps each kind to.
  # Enough to run the `declarations`/`imports` attributes with empty rule sets. (The
  # enrichments fixpoint uses its own constant single-kind classify.)
  declarationsMin = {
    classify = a: a.__kind or (throw "den-hoag: declaration carries no __kind tag (declarationsMin)");
    # NB: "policy" here is the dispatch GROUP label for the one-shot policy evaluation,
    # not a declaration kind (enrich/member/configure/…) — the real vocabulary replaces this.
    kindOrder = [ "policy" ];
    kindToStratum = {
      enrich = "structural";
    };
    importEdgesOf = _policyDeclarations: [ ];
  };

  structuralAttributes = import ./attributes/structural.nix {
    inherit
      prelude
      scope
      resolve
      dispatch
      errors
      ;
    declarations = declarationsMin;
  };
  runResolve = import ./attributes/default.nix { inherit resolve; };
  inherit (buildRootsLib) buildRoots parseParent;

  # mkDen assembles the four concerns; Tasks 1–11 extend it. Task 1: entity registries
  # (gen-schema) + the fleet restricted product (gen-product). Task 2: scope roots +
  # structural stratum (attributes 1–6) over gen-resolve/gen-scope.
  mkDen =
    userModules:
    let
      # den-managed module: the fleet membership channel. Task 1 bootstrap surface — the
      # fixture sets these tuples directly; Task 3 emits them from `member` declarations at
      # membership-independent nodes.
      membershipDecl = {
        options.den.membership = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Fleet membership tuples { coords; via ? null; } (A5).";
        };
      };

      denMeta = entity.discoverKinds userModules;
      ent = entity.build {
        userModules = [ membershipDecl ] ++ userModules;
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

      # Task 2 threads empty policy rule-sets (Task 3 compiles them from den.policies). The
      # B1 enrich fixpoint is nonetheless real — the b1-single-writer suite drives it with
      # its own rules through the same structural equations.
      equations = structuralAttributes {
        policiesRules = {
          enrich = [ ];
          policy = [ ];
        };
        inherit fleetChildren;
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
    declarations = declarationsMin;
    inherit
      dispatch
      resolve
      scope
      select
      product
      ;
  };
}
