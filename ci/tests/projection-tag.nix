# The PROJECTION-TAG suite (§7, the two-projection parity seam). Every edge-kind carries a `to ∈ { query,
# materialize, both }` PROJECTION TARGET — the parity-load-bearing tag: an edge-production declares WHERE its
# edges land. `to = query` is OFF the materialization trace (a relation/query edge — parity-safe); `to =
# materialize` is ON the trace (real config, exactly as today's demandEdges); `to = both` lands on both.
#
# WHERE A KIND'S `to` COMES FROM, in three tiers (§4 "Default per emit kind"):
#   • the FRAMEWORK pre-registered kinds STATE it at the registry seed (`preRegisteredKinds`), both fields
#     required — a kind is `materialize` IFF IT DELIVERS CONTENT, so contains/include/kindOf/member/reach/
#     reach-suppress are `query` (assertions ABOUT the graph) and nest/defer/demand are `materialize`;
#   • a relation-DERIVED kind (the `den.relations` desugar, `relationsToEdgeKinds`) stamps `to = "query"`
#     explicitly — a relation edge-production must be query, off the trace;
#   • a USER `den.edges` kind DEFAULTS to `materialize` (on the trace) — the one surviving default, and the
#     one this suite still witnesses as a default.
# The materialize edge set (`edgesForRoot`, output-modules.nix) filters to `to ∈ { materialize, both }`, so a
# `to = query` kind's edges never reach the trace.
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
  # the WITNESS-D subject: a framework STRUCTURAL edge. Before the seed became total this rode the trace
  # by defaulting; after it, the seed declares it `query` and the filter drops it.
  containsEdge = {
    kind = "contains";
    marker = "C";
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

    # ── a FRAMEWORK structural/resolution kind is `query`, BY DECLARATION at the seed ──
    # `member` asserts something about the graph; it delivers no content, so it is off the trace. This
    # is stated in `preRegisteredKinds`, not defaulted — which is why it can be pinned here at all: while
    # `to` was a default, nothing in the suite pinned it for any framework kind.
    test-projection-member-kind-to-query = {
      expr = compiled.member.to;
      expected = "query";
    };
    test-projection-contains-kind-to-query = {
      expr = compiled.contains.to;
      expected = "query";
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

    # ── WITNESS D (the seed fix, as a unit witness) ──────────────────────────────────────────────────
    # The discriminating input is the singleton `[ { kind = "contains"; … } ]` handed to the ONE function
    # this decision changes, at the ONE site `to` is read. Before the seed became total, `contains` had no
    # declared `to`, `entryOf`'s default made it `materialize`, and the filter KEPT it; now the seed states
    # `query` and the filter DROPS it.
    #
    # The two controls ride in the SAME call, on the SAME predicate — that is what distinguishes "the
    # filter drops `contains`" from "the filter drops everything". Splitting them into three assertions
    # would lose exactly that: a filter that dropped its whole input would satisfy a lone `contains` row.
    #
    # ⚠ WHAT THIS DOES NOT SHOW, so nobody reads it as more: that no `contains` edge reaches the frozen
    # materialization trace TODAY is true by POOL SEPARATION — `graphAccessor.edgesAt = deliveryEdgesAt`
    # and the only other input is `++ demandEdges`, so a query-pool edge cannot reach `materializeFilter`
    # at all. That holds with or without this change, and nothing in this design can demonstrate a parity
    # divergence. What the witness shows is that the separation now holds BY DECLARATION as well.
    test-projection-witness-d-contains-dropped-controls-kept = {
      expr = markersOf compiled [
        containsEdge
        demandEdge
        unlabeledEdge
      ];
      expected = [
        "D"
        "U"
      ];
    };
  };
}
