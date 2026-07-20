# The PHASE-1 re-founding certificate (Productions-substrate §11). The relation/derived accessors are SCHEDULED
# resolution-stratum attributes in gen-resolve's ONE equations map (not a second top-level eval-context), and the
# warm-serve `declaredEdges` is soundly populated from the relation graph (GAP-2). See REFERENCE.md / the spec §11.
{
  denHoag,
  ...
}:
let
  sort = builtins.sort builtins.lessThan;

  # a memberOf chain a → b → c + one forward derive reading the transitive closure, so both scheduled attrs
  # have a non-trivial value to witness.
  fleet = denHoag.mkDen [
    (
      { config, ... }:
      {
        config.den.schema.node.parent = null;
        config.den.relations.memberOf = {
          inverse = "members";
        };
        config.den.strata.insert.closure = {
          after = "resolution";
        };
        config.den.resolutionProducts.ReachInfo = { };
        config.den.node.a.edges.memberOf = [ config.den.node.b ];
        config.den.node.b.edges.memberOf = [ config.den.node.c ];
        config.den.node.c = { };
        config.den.derived.reach = {
          over = [ "memberOf" ];
          direction = "forward";
          stratum = "closure";
          provides = "ReachInfo";
          derive = node: _: node.rel.memberOf.closure;
        };
      }
    )
  ];

  # a relation-free fleet — the declaredEdges corpus-inert gate (byte-identical to the empty default).
  bareFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.host.h = { };
    }
  ];
in
{
  flake.tests.resolution-refound = {
    # rel-accessor is a scheduled attribute — eval.get id "rel-accessor" yields the per-kind record (the
    # DELIVERY moved INTO the equations map, not a top-level closure).
    test-rel-accessor-scheduled = {
      expr = builtins.attrNames (fleet.den.structural.eval.get "node:a" "rel-accessor");
      expected = [ "memberOf" ];
    };
    test-rel-accessor-value = {
      expr = (fleet.den.structural.eval.get "node:a" "rel-accessor").memberOf.targets;
      expected = [ "node:b" ];
    };
    # derived-accessor is a scheduled attribute — its `reach` reads rel-accessor@node:a (an intra-node
    # resolution read) → the transitive closure {b, c}.
    test-derived-accessor-scheduled = {
      expr = sort (fleet.den.structural.eval.get "node:a" "derived-accessor").reach;
      expected = [
        "node:b"
        "node:c"
      ];
    };
    # GAP-2: declaredEdges (accessor.edges) is populated soundly from the relation endpoints — warm-serve is
    # incremental, not the empty-default half-refactor.
    test-declared-edges-populated = {
      expr = sort (fleet.den.structural.accessor.edges "node:a");
      expected = [
        "node:a"
        "node:b"
        "node:c"
      ];
    };
    # corpus-inert: a relation-free fleet declares no edges (byte-identical to the empty default).
    test-declared-edges-corpus-inert = {
      expr = bareFleet.den.structural.accessor.edges "host:h";
      expected = [ ];
    };
  };
}
