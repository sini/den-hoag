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

  # mkDen assembles the four concerns; Tasks 1–11 extend it. Task 1: entity registries
  # (gen-schema) + the fleet restricted product (gen-product).
  mkDen =
    userModules:
    let
      # den-managed module: the fleet membership channel. Task 1 bootstrap surface — the
      # fixture sets these tuples directly; Task 3 emits them from `member` effects at
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
      membershipTuples = ent.config.den.membership or [ ];

      theFleet = fleet.mkFleet {
        inherit (ent) registries;
        inherit dimKinds membershipTuples;
      };
    in
    {
      den = {
        schema = ent.kinds;
        inherit (ent) registries meta roots;
        fleet = theFleet;
        cells = product.cells theFleet;
      };
    };
in
{
  inherit errors mkDen;
  # den's selector vocabulary (identity-law entry/kind constructors + adapters); used to
  # write declarations, independent of any one mkDen instance.
  sel = select;
}
