# The PROJECTION-TAG suite (§7, the two-projection parity seam). Every edge-kind carries a `to ∈ { query,
# materialize, both }` PROJECTION TARGET — the parity-load-bearing tag: an edge-production declares WHERE its
# edges land. `to = query` is OFF the materialization trace (a relation/query edge — parity-safe); `to =
# materialize` is ON the trace (real config, exactly as today's demandEdges); `to = both` lands on both.
#
# The DEFAULT is per-kind (§4 "Default per emit kind"): a relation-DERIVED kind (the `den.relations` desugar,
# `relationsToEdgeKinds`) stamps `to = "query"` explicitly — a relation edge-production must be query, off the
# trace; EVERY other kind (framework-pre-registered, user den.edges, demand/cascade) defaults `to = "materialize"`
# — on the trace. The materialize edge set (`edgesForRoot`, output-modules.nix) filters to `to ∈ { materialize,
# both }`, so a `to = query` kind's edges never reach the trace.
#
# PARITY IS INERT BY CONSTRUCTION (this suite FORMALIZES it, it does not create it): relation edges live in a
# SEPARATE `relationEdges` pool never merged into `edgesForRoot`; the corpus `edgesForRoot` carries only
# unlabeled content edges (kind = null → materialize) + demand edges (kind = "demand" → materialize). So the
# filter drops NOTHING on the corpus — it pins the already-holding off-trace separation. The frozen-71 parity
# trace is untouched (proved by the parity gate). See REFERENCE.md §7.
{
  denHoag,
  ...
}:
let
  edgeKinds = denHoag.internal.edgeKinds;
  compileEdges = denHoag.internal.compileEdges;
  relationsToEdgeKinds = denHoag.internal.relations.relationsToEdgeKinds;

  # a strata order carrying the full framework vocabulary (structural / resolution / output / demand — the
  # pre-registered kinds' strata) PLUS the per-relation stratum `rel:likes` the relation desugar stamps, so
  # `compile`'s stratum-∈-order validation passes for every seeded + relation kind.
  strataOrder = [
    "structural"
    "resolution"
    "rel:likes"
    "output"
    "demand"
  ];

  # the relation desugar: one relation `likes` → one edge-kind `likes` @ `rel:likes`, carrying `to = "query"`
  # (the off-trace projection target). `userEdgeKinds`/`reservedNames` feed its collision guard.
  relationKinds = relationsToEdgeKinds {
    relations = {
      likes = {
        inverse = "likedBy";
      };
    };
    userEdgeKinds = [ ];
    reservedNames = edgeKinds.reservedNames;
  };

  # a plain USER kind (no relation desugar, no explicit `to`) — defaults `to = "materialize"` (on the trace).
  compiled = compileEdges {
    kinds = relationKinds // {
      deploys = {
        stratum = "resolution";
      };
    };
    inherit strataOrder;
    disciplines = { };
  };

  # synthetic gen-edge-shaped records (a `kind` label is the only field the projection filter reads): a
  # relation edge (to = query, off-trace), a demand edge (to = materialize, on-trace), and an UNLABELED
  # content edge (kind = null → materialize, the corpus majority).
  relationEdge = {
    kind = "likes";
    marker = "R";
  };
  demandEdge = {
    kind = "demand";
    marker = "D";
  };
  unlabeledEdge = {
    kind = null;
    marker = "U";
  };
  bothEdge = {
    kind = "broadcast";
    marker = "B";
  };
  # a compiled table stamping a `to = "both"` kind, to witness `both` lands on the materialize set.
  compiledBoth = compileEdges {
    kinds = {
      broadcast = {
        stratum = "resolution";
        to = "both";
      };
    };
    inherit strataOrder;
    disciplines = { };
  };

  materializeEdges = edgeKinds.materializeEdges;
  markersOf = compiledKinds: edges: map (e: e.marker) (materializeEdges compiledKinds edges);
in
{
  flake.tests.projection-tag = {
    # ── the default: a relation-derived kind's record carries `to = "query"` (off-trace) ──
    test-projection-relation-desugar-to-query = {
      expr = relationKinds.likes.to;
      expected = "query";
    };
    test-projection-relation-compiled-to-query = {
      expr = compiled.likes.to;
      expected = "query";
    };

    # ── the default: a user / demand / framework kind's record carries `to = "materialize"` (on-trace) ──
    test-projection-user-kind-to-materialize = {
      expr = compiled.deploys.to;
      expected = "materialize";
    };
    test-projection-demand-kind-to-materialize = {
      expr = compiled.demand.to;
      expected = "materialize";
    };
    test-projection-member-kind-to-materialize = {
      expr = compiled.member.to;
      expected = "materialize";
    };

    # ── the materialize filter: keeps `to ∈ { materialize, both }`, EXCLUDES `to = query` ──
    # the POSITIVE off-trace assert: the relation edge (marker "R") is ABSENT from the materialize set,
    # while the demand ("D") + unlabeled ("U") edges are PRESENT.
    test-projection-filter-excludes-query = {
      expr = markersOf compiled [
        relationEdge
        demandEdge
        unlabeledEdge
      ];
      expected = [
        "D"
        "U"
      ];
    };
    # the relation edge is present in the INPUT pool (it is a real edge — it just does not project to
    # materialize): the split is a projection, not a deletion.
    test-projection-relation-edge-in-input = {
      expr = builtins.elem "R" (
        map (e: e.marker) [
          relationEdge
          demandEdge
          unlabeledEdge
        ]
      );
      expected = true;
    };
    # `to = both` lands on the materialize set (it is on the trace, and followable off it too).
    test-projection-filter-keeps-both = {
      expr = markersOf compiledBoth [ bothEdge ];
      expected = [ "B" ];
    };
    # an edge whose kind is unregistered in the table defaults on-trace (a safe, parity-preserving default:
    # the filter never silently drops an edge it cannot classify).
    test-projection-filter-unknown-kind-materializes = {
      expr = markersOf compiled [
        {
          kind = "synthesized";
          marker = "S";
        }
      ];
      expected = [ "S" ];
    };
  };
}
