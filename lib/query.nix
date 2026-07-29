# den.query — a pure den-hoag lowering of the §3 query calculus over a SUPPLIED flat labeled edge list onto
# gen-graph's complete query engine. The §3 follow-grammar (`"include*"`, `"contains* nest?"`, labels /
# `( ) | * ? +` / concat) parses via `graph.regex.parse`; the traversal, the five modes, order and the path
# witnesses are gen-graph's — this file only lowers the den surface onto them and supplies the ONE adapter
# gen-graph lacks (a flat edge list → its per-label accessor map).
#
# SOURCE-AGNOSTIC (spec §5): `den.query` operates on plain-string node ids from the supplied edges' `from`/`to`
# — no coupling to any rendered identity, synthetic-testable. It takes the edge list as data; assembling the
# live relation graph (and the scoped `where` a gen-select selector needs) is a caller concern.
#
# TWO ENTRY POINTS, and the split is the cost boundary. `denQuery` takes a BUILT `kindGraph`; a caller that
# owns a static pool builds it ONCE (`kindGraphOf`) and every query over that pool shares it.
# `denQueryOverEdges` takes an edge list and builds the adjacency for the call — correct for an exploratory
# read over a pool assembled on the spot, wrong for a hot per-node reader. They are separate NAMES rather
# than one function with a defaulted argument, so that taking the per-call build is something a caller
# writes down rather than something it gets by omission.
#
# Deps: `prelude` (utility base); `graph` = the OUTER gen-graph engine (`labeledFrom` / `query` / `regex`) —
# NOT the mkDen-local `graphEscape` read-only edge/trace surface, which has no `.query`.
{
  prelude,
  graph,
}:
let
  knownModes = [
    "all"
    "paths"
    "visible"
    "layers"
    "fixpoint"
  ];

  # perLabelFromEdges — the flat-list → per-label accessor adapter gen-graph's `labeledFrom` expects (it takes
  # the accessors already-made). A flat `[{ kind; from; to }]` list becomes `{ <kind> = fromId: [ toId … ]; }`:
  # one accessor per distinct edge kind, returning a node's out-neighbours along that kind.
  #
  # PREBUILT ADJACENCY (O(E) once, O(1) per lookup). The adjacency `{ label → { from → [ to ] } }` is built
  # ONCE with two `builtins.groupBy` passes — `groupBy .kind` for the label spine, then `groupBy .from`
  # within each label — so an accessor call is an `${fromId}` index, not a per-call linear scan of the whole
  # edge list. The `query` traversal invokes each accessor once per node-visit during the DFS, so the old
  # per-call `filter … edges` was O(E) × (nodes visited) — the avoidable O(E²) the gather expose arm
  # inherited through this facade; the groupBy build is O(E) total (gen-graph/lib/global.nix takes the same
  # "O(E) via groupBy instead of O(E²)" route). BYTE-IDENTICAL to the scan: the kind spine is `attrNames`
  # over `groupBy .kind` (Nix-sorted, a duplicated kind collapses into one group — as `listToAttrs` did), and
  # `groupBy` PRESERVES input order within each group, so a node's target list stays in edge-list order.
  perLabelFromEdges =
    edges:
    let
      byLabelFrom = builtins.mapAttrs (
        _kind: kindEdges:
        builtins.mapAttrs (_from: grp: map (e: e.to) grp) (builtins.groupBy (e: e.from) kindEdges)
      ) (builtins.groupBy (e: e.kind) edges);
    in
    builtins.mapAttrs (
      _kind: fromMap: fromId:
      fromMap.${fromId} or [ ]
    ) byLabelFrom;

  # kindGraphOf — the flat edge list → gen-graph labeled-graph adaptation, as its OWN name. Separating it
  # from `denQuery` is the whole of the cost fix: the O(E) two-pass `groupBy` build below is a property of
  # the POOL, not of a query, so it belongs at the site that owns the pool and can be forced once. A caller
  # holding a static pool builds this ONCE and hands the result to every query over it; `denQuery` no longer
  # has the opportunity to rebuild it, because it never sees the edges.
  kindGraphOf = edges: graph.labeledFrom (perLabelFromEdges edges);

  # denQuery — lower the den surface onto `graph.query`. The guards are den-namespaced NAMED throws that
  # PRE-EMPT the tryEval-uncatchable class (an unknown mode reaching gen-graph's raw throw, a `where`/`combine`
  # that is not a function → "attempt to call …", an unparseable follow forced deep inside the traversal).
  #
  # TAKES A BUILT `kindGraph`, REQUIRED — never an edge list, and never a defaulted one. This function used
  # to build its own adjacency inside its `let`, so the O(E) build ran once PER CALL: the relation accessor
  # issues four queries per (node × kind) and Nix has no CSE, so the pool was re-grouped for every field of
  # every kind at every node. Availability was never the obstacle — `relationEdges` is a static
  # registry-derived pool — only call placement was. Making the parameter required rather than defaulting it
  # beside `edges` is deliberate: a defaulted second input is exactly the absence-is-a-decision shape that
  # lets a caller silently reopen the cost, and `output-modules.nix`'s `channelNames` is the in-file
  # precedent for required-not-defaulted. Callers holding an edge list use `denQueryOverEdges` below, which
  # names the adaptation it performs.
  denQuery =
    {
      kindGraph,
      from,
      follow,
      where ? (_: true),
      mode ? "all",
      order ? { },
      empty ? null,
      combine ? null,
      valueOf ? (x: x),
    }:
    if !(builtins.elem mode knownModes) then
      throw "den.query: unknown mode '${mode}' (known: ${builtins.concatStringsSep ", " knownModes})"
    else if !(builtins.isFunction where) then
      throw "den.query: `where` must be a node→bool predicate (the scoped sel→matchId adaptation is a caller concern)"
    else if !(builtins.isString follow) then
      throw "den.query: `follow` must be a §3 follow-grammar string"
    else if mode == "fixpoint" && (empty == null || !(builtins.isFunction combine)) then
      # the fixpoint fold is `foldl' (acc: id: combine acc (valueOf id)) empty …` — a null `combine`/`empty`
      # is the tryEval-uncatchable "attempt to call null" class, so require the monoid up front.
      throw
        "den.query: mode \"fixpoint\" requires the ACI monoid — a `combine` function and a non-null `empty` (§3 fixpoint)"
    else
      let
        # Force the follow parse behind a NAMED guard: gen-graph's grammar throw is catchable, but it fires
        # deep in the traversal, so deep-force it here and re-throw den-namespaced on failure.
        parsedFollow =
          let
            p = graph.regex.parse follow;
          in
          if (builtins.tryEval (builtins.deepSeq p true)).success then
            p
          else
            throw "den.query: unparseable follow '${follow}' (§3 follow-grammar)";
        common = {
          graph = kindGraph;
          inherit from where;
          follow = parsedFollow;
        };
        # THE MODE-APPROPRIATE ARG SET. gen-graph's `queryAll`/`queryPaths` are STRICT-signatured, and
        # `queryVisible`→`queryPaths` / `queryFold`→`queryAll` pass their args through — so an unrelated
        # optional leaks into a strict signature ("unexpected argument"). Pass `empty`/`combine`/`valueOf`
        # ONLY for fixpoint and `order` ONLY for visible/layers; all/paths carry neither.
        perMode =
          if mode == "fixpoint" then
            { inherit empty combine valueOf; }
          else if mode == "visible" || mode == "layers" then
            { inherit order; }
          else
            { };
      in
      # RETURN = the RAW §3 gen-graph shape per mode (all → [id]; paths → [{node;path}]; layers →
      # [[{node;path}]]; visible → {visible;shadowed}; fixpoint → the fold). No node-dedup — that is a
      # caller-specific concern (e.g. resolveKey's diamond dedup), not the general query contract.
      graph.query (common // perMode // { inherit mode; });

  # denQueryOverEdges — the edges-taking adaptation, for a caller that holds a pool rather than a built
  # graph: the EXPLORATORY surface (`den.query`, and a per-derive stratum-scoped pool whose membership is a
  # function of the reader's own stratum). It builds the adjacency for the call, which is the honest cost of
  # querying a pool you have only just scoped. It is a SEPARATE NAME rather than a defaulted argument so
  # that a hot-path caller cannot reach it by omission — choosing the per-call build has to be written down.
  denQueryOverEdges =
    args:
    denQuery (
      removeAttrs args [ "edges" ]
      // {
        kindGraph = kindGraphOf args.edges;
      }
    );
in
{
  inherit
    perLabelFromEdges
    kindGraphOf
    denQuery
    denQueryOverEdges
    ;
}
