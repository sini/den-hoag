# The QUERY suite (§3 query calculus, spec §5 — the resolution facet). `den.query` is a pure den-hoag lowering of the §3
# follow-grammar query over a SUPPLIED flat labeled edge list (`[{ kind; from; to }]`) onto gen-graph's
# complete query engine. Source-agnostic — plain-string ids, synthetic edges, no substrate; the live
# relation-graph source is a downstream concern. See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  inherit (denHoag) query;
  sort = builtins.sort builtins.lessThan;

  # a linear synthetic relation graph  a --rel--> b --rel--> c  (plain-string ids, no substrate).
  edges = [
    {
      kind = "rel";
      from = "a";
      to = "b";
    }
    {
      kind = "rel";
      from = "b";
      to = "c";
    }
  ];
  q =
    args:
    query (
      {
        inherit edges;
        from = "a";
        follow = "rel*";
      }
      // args
    );

  # an ASYMMETRIC fixture: a SHORTCUT  a --rel--> d  PLUS a longer  a --rel--> x --rel--> d  — so the short path
  # to d (rank [0]) genuinely SHADOWS the long one (rank [0,0]); `shadowed ≠ [ ]` is REAL. (A symmetric diamond's
  # equal-rank paths CO-WIN, `shadowed = [ ]`, and exercises no shadowing at all.)
  asymEdges = [
    {
      kind = "rel";
      from = "a";
      to = "d";
    }
    {
      kind = "rel";
      from = "a";
      to = "x";
    }
    {
      kind = "rel";
      from = "x";
      to = "d";
    }
  ];
  qa =
    args:
    query (
      {
        edges = asymEdges;
        from = "a";
        follow = "rel*";
      }
      // args
    );

  # a TWO-LABEL fixture:  a --strong--> d  AND  a --weak--> d  (equal length 1). With the default order the two
  # equal-length paths CO-WIN (label ranking is inert on a single-length alphabet); an explicit
  # `order { labels = [ "strong" "weak" ]; }` ranks strong below weak, so strong WINS and weak is shadowed — the
  # order arg FLIPS the visible winner (a single-label alphabet would leave order-ranking inert).
  twoLabelEdges = [
    {
      kind = "strong";
      from = "a";
      to = "d";
    }
    {
      kind = "weak";
      from = "a";
      to = "d";
    }
  ];
  qt =
    args:
    query (
      {
        edges = twoLabelEdges;
        from = "a";
        follow = "(strong|weak)";
        mode = "visible";
      }
      // args
    );
  labelsOf = anss: map (x: (builtins.head x.path).label) anss;
in
{
  flake.tests.query = {
    # mode "all": rel* from a reaches {a,b,c} — reflexive, since `*` is nullable so the source answers.
    test-query-all-reachable = {
      expr = sort (q {
        mode = "all";
      });
      expected = [
        "a"
        "b"
        "c"
      ];
    };
    # the RAW node→bool `where` filters by id — `n != "c"` drops c (non-vacuous).
    test-query-all-where-filters = {
      expr = sort (q {
        mode = "all";
        where = n: n != "c";
      });
      expected = [
        "a"
        "b"
      ];
    };
    # mode "paths": the per-node path witnesses (each reached node + its edge-path). The depths are 0/1/2
    # (a = source, b = one rel, c = two rels) — a non-vacuous witness of the traversal, not just node presence.
    test-query-paths-nodes = {
      expr = sort (
        map (p: p.node) (q {
          mode = "paths";
        })
      );
      expected = [
        "a"
        "b"
        "c"
      ];
    };
    test-query-paths-depths = {
      expr = map (p: builtins.length p.path) (
        builtins.sort (a: b: a.node < b.node) (q {
          mode = "paths";
        })
      );
      expected = [
        0
        1
        2
      ];
    };
    # mode "fixpoint": fold the reachable set through a synthetic IDEMPOTENT monoid (empty = [ ], combine = ++,
    # valueOf = singleton) — collects {a,b,c}. Exposing the mode ≠ enforcing the join-semilattice law (that
    # discipline is the consumer's).
    test-query-fixpoint-folds-reachable = {
      expr = sort (q {
        mode = "fixpoint";
        empty = [ ];
        combine = a: b: a ++ b;
        valueOf = id: [ id ];
      });
      expected = [
        "a"
        "b"
        "c"
      ];
    };
    # mode "visible" SMOKE (the asymmetric shadowing is witnessed separately): the raw { visible; shadowed } shape, visible
    # covering the reachable nodes; a linear graph shadows nothing (shadowed = [ ]).
    test-query-visible-shape = {
      expr = builtins.attrNames (q {
        mode = "visible";
      });
      expected = [
        "shadowed"
        "visible"
      ];
    };
    test-query-visible-nodes = {
      expr = sort (map (x: x.node) (q { mode = "visible"; }).visible);
      expected = [
        "a"
        "b"
        "c"
      ];
    };

    # ── order + visible/layers on the ASYMMETRIC fixture (green-on-arrival — the order arg is threaded from the
    # query spine; these witness real shadowing + the order flip that the linear/smoke fixtures cannot) ──
    # visible: the SHORT path to d WINS (.visible carries d at path-length 1); the LONG path is SHADOWED
    # (.shadowed carries d at path-length 2) — `shadowed ≠ [ ]`, a REAL shadowing witness (not a co-winning diamond).
    test-query-visible-shadowed-nonempty = {
      expr = map (x: x.node) (qa { mode = "visible"; }).shadowed;
      expected = [ "d" ];
    };
    test-query-visible-short-wins = {
      expr = map (x: builtins.length x.path) (
        builtins.filter (x: x.node == "d") (qa { mode = "visible"; }).visible
      );
      expected = [ 1 ];
    };
    test-query-visible-shadowed-is-long = {
      expr = map (x: builtins.length x.path) (qa { mode = "visible"; }).shadowed;
      expected = [ 2 ];
    };
    # layers: the raw list-OF-layers per the BFS ranks — a at rank 0, {d-short, x} at rank 1, d-long at rank 2
    # (each layer sorted here only for a stable oracle) — the per-path layer witnesses, not collapsed.
    test-query-layers-ranks = {
      expr = map (layer: sort (map (x: x.node) layer)) (qa {
        mode = "layers";
      });
      expected = [
        [ "a" ]
        [
          "d"
          "x"
        ]
        [ "d" ]
      ];
    };
    # order (two-label): the DEFAULT order CO-WINS both equal-length paths (shadowed = [ ] — label ranking inert);
    # an explicit `order.labels` ranks strong below weak, so strong WINS visible and weak is shadowed — the order
    # arg FLIPS the winner (non-vacuous: shadowed goes [ ] → [ "weak" ]).
    test-query-order-default-cowins = {
      expr = {
        visible = sort (labelsOf (qt { }).visible);
        shadowed = labelsOf (qt { }).shadowed;
      };
      expected = {
        visible = [
          "strong"
          "weak"
        ];
        shadowed = [ ];
      };
    };
    test-query-order-flips-winner = {
      expr = {
        visible =
          labelsOf
            (qt {
              order = {
                labels = [
                  "strong"
                  "weak"
                ];
              };
            }).visible;
        shadowed =
          labelsOf
            (qt {
              order = {
                labels = [
                  "strong"
                  "weak"
                ];
              };
            }).shadowed;
      };
      expected = {
        visible = [ "strong" ];
        shadowed = [ "weak" ];
      };
    };

    # ── NAMED den-namespaced guards (tryEval-catchable; pre-validated before gen-graph's raw throw) ──
    test-query-unknown-mode-throws = {
      expr = throws (q {
        mode = "bogus";
      });
      expected = true;
    };
    test-query-where-not-fn-throws = {
      expr = throws (q {
        where = "not-a-fn";
      });
      expected = true;
    };
    test-query-bad-follow-throws = {
      expr = throws (q {
        follow = "(";
      });
      expected = true;
    };
    # mode "fixpoint" with no monoid → a null `combine` is the uncatchable "attempt to call null" class,
    # pre-empted by a NAMED guard.
    test-query-fixpoint-missing-monoid-throws = {
      expr = throws (q {
        mode = "fixpoint";
      });
      expected = true;
    };
  };
}
