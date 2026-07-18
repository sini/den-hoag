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
