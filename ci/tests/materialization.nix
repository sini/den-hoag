# The materialization SUBSTRATE suite (spec §12). Materialization is the read-through side of
# the pipeline: products/renders/receivers are queried, not folded, so the dispatch layer rests on the
# labeled-query calculus (Brzozowski derivatives over a label alphabet — the regular-path-query reading
# of reachability). This suite grows across the materialization arc; the first scenario is the dispatch-substrate
# smoke: den-hoag's OWN gen-graph pin reaches the labeled-query surface (`query`/`labeledFrom`/`regex`).
# See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  # The gen-graph lib, reached through den-hoag's raw-gen-libs seam (the role-named `internal.genGraph` arm).
  inherit (denHoag.internal) genGraph;
  inherit (genGraph) query labeledFrom regex;

  # A tiny labeled relation over a single `hop` edge alphabet: a → b → c. `labeledFrom` adapts one plain
  # accessor per label into the labeled-edge contract the query engine reads.
  rel = labeledFrom {
    hop =
      id:
      {
        a = [ "b" ];
        b = [ "c" ];
        c = [ ];
      }
      .${id} or [ ];
  };
in
{
  flake.tests.materialization = {
    # The dispatch substrate is reachable: run ONE real regular-path query through the pin. `hop` matches
    # exactly one edge label, so from `a` the answer set is `{ b }` (the single-hop derivative is nullable
    # at b, not at c — `hop hop` is not in the language of `hop`).
    test-dispatch-substrate-single-hop = {
      expr = query {
        graph = rel;
        from = "a";
        follow = regex.parse "hop";
        mode = "all";
      };
      expected = [ "b" ];
    };
  };
}
