# Phase 1 (den-hoag class-projection over the resolved-aspect graph, spec §2) — THE EDGE MODEL.
#
# Task 1: the edge-DECLARATION reads (`reachEdgesOf`/`reachSuppressOf` in resolved-aspects.nix — pure list
# functions over a node's `resolutionActs`, mirroring `policyEdgeAspects` `__action == "edge"` / `constraintSeen`
# `__action == "drop"`): `reachEdgesOf` filters `reach-edge` → `[ { target; classFilter ? null } ]` (POSITIVE
# cross-scope edge, class-scoped F9); `reachSuppressOf` filters `reach-suppress` → `[ { edge; when } ]` (NEGATIVE
# suppression, F3-exclude / u21).
#
# Both `reachEdgesOf` AND `reachSuppressOf` are INTERNAL (`let`-bound) — consumed inside `reach` (positive
# edges + negative-edge suppression), witnessed THROUGH `reach` (below), no public export. `reach` needs the
# REAL prelude/resolve/scope/aspects/select, so the module is imported with denHoag.internal deps and
# `reach.compute self id` is driven against a STUB `self` (the compat-expose-gather.nix mkStub precedent)
# serving synthetic per-node resolved-aspects/declarations — the traversal witnessed as a pure graph function
# (no policy vocabulary for reach-edges/suppresses in Phase 1; Phase-5 corpus wiring authors those).
#
# Witness map: Task 2 = reach closure (identity / class-scope F9 / single-visit / per-scope / transitive);
# Task 3 = framework default-edge (unset-identity / injection / dedup); Task 4 = suppression (droid both-arms
# / when-false + mismatch no-op); Task 5 = canonical merge_ord order ([O D P] / provider include-order / stable).
{
  denHoag,
  denHoagSrc,
  ...
}:
let
  # Import resolved-aspects.nix with the REAL denHoag.internal deps (the `reach` accessor's compute folds +
  # builds a resolve.attr record; `reachSuppressOf` rides the same attrset — see header for the witness plan).
  inherit (denHoag.internal)
    prelude
    scope
    resolve
    aspects
    select
    ;
  # `ra` = the module with NATIVE instance args (defaultEdgeTargets = (_: [ ]) ⇒ no default edges). Task 3
  # witnesses the default-edge PRIMITIVE by re-importing the module with a custom `defaultEdgeTargets`
  # instance arg (`raWith` below), so `reach` folds those injected edges in.
  mkRa =
    instanceArgs:
    import "${denHoagSrc}/lib/attributes/resolved-aspects.nix" {
      inherit
        prelude
        scope
        resolve
        aspects
        select
        ;
    } instanceArgs;
  ra = mkRa { };
  raWith = defaultEdgeTargets: mkRa { inherit defaultEdgeTargets; };

  # A synthetic resolution-action list: one positive reach-edge (class-scoped home-manager), one negative
  # reach-suppress (droid-gated), and unrelated actions (an `edge`/`drop` from the existing strata) the
  # reads MUST ignore — proving the filter selects on `__action` exactly.
  whenDroid = scope: (scope.host.class or null) == "droid";
  acts = [
    {
      __action = "reach-edge";
      target = "host:igloo";
      classFilter = "home-manager"; # the den-hoag class-key convention (hyphenated, per class-modules).
    }
    {
      __action = "reach-edge";
      target = "host:cabin";
      # classFilter omitted ⇒ null (all classes).
    }
    {
      __action = "reach-suppress";
      edge = "user-to-host";
      when = whenDroid;
    }
    {
      __action = "edge";
      aspect = {
        key = "unrelated-policy-edge";
      };
    }
    {
      __action = "drop";
      aspect = {
        key = "unrelated-drop";
      };
    }
  ];

  # ══ Task 2 — the reach(id) closure. Driven against a STUB `self` (the compat-expose-gather mkStub
  #    precedent): a synthetic graph of nodes, each with a `resolved-aspects` list + a `declarations`
  #    resolution stratum carrying reach-edge actions. `reach.compute stub id` is the P-PROJECT reach(S).
  #
  #    A synthetic resolved-aspect node: `{ key; content }`. `content` carries class keys
  #    (nixos/home-manager/…) so the class-filter (n.content ? ${C}) selects; keys are the identity for
  #    single-visit dedup.
  mkNode = key: content: {
    inherit key content;
  };
  # aspect nodes used across the fixtures — a nixos-only host aspect, an hm-defining host aspect, an
  # own cell aspect, and a SHARED aspect present in both a cell's own subtree AND across an edge.
  nHostNixos = mkNode "host-nixos" { nixos.tag = "n"; };
  nHostHm = mkNode "host-hm" { home-manager.tag = "h"; };
  nOwn = mkNode "cell-own" { home-manager.tag = "own"; };
  nShared = mkNode "shared" { home-manager.tag = "s"; };
  nB = mkNode "b-aspect" { home-manager.tag = "b"; };

  reachEdgeAct = target: classFilter: {
    __action = "reach-edge";
    inherit target classFilter;
  };

  # Build a stub `self`: `graph` = { <id> = { resolved = [ nodes ]; edges = [ reach-edge acts ];
  # children = { <childId> = { }; }; }; }.
  # `self.get id "resolved-aspects"` → that node's list; `self.get id "declarations"` → its resolution
  # stratum (the reach-edge acts); `self.get id "children"` → the structural-descendant walk's child map
  # (Task 1 — `scope.descendants self id` DFS reads it); `self.node id` → a minimal node record (scope for
  # suppress predicates).
  mkStub =
    graph:
    let
      self = {
        get =
          id: attr:
          if attr == "resolved-aspects" then
            (graph.${id} or { resolved = [ ]; }).resolved or [ ]
          else if attr == "declarations" then
            { actions.resolution = (graph.${id} or { }).edges or [ ]; }
          else if attr == "children" then
            (graph.${id} or { }).children or { }
          else
            throw "reach-graph stub: unexpected attr ${attr}";
        node = id: (graph.${id} or { }).node or { };
      };
    in
    self;
  # keys of a reach result, for order/membership assertions.
  keysOf = nodes: map (n: n.key) nodes;
  # reach over the NATIVE module instance (no default edges); reachKeysWith drives a specific instance
  # (Task 3's raWith, carrying a custom defaultEdgeTargets).
  reachKeysOn =
    raInst: graph: id:
    keysOf (raInst.reach.compute (mkStub graph) id);
  reachKeys = reachKeysOn ra;
in
{
  flake.tests.reach-graph = {
    # ── Task 1 (a) THROUGH reach (reachEdgesOf demoted to internal): the positive-edge read — target +
    #    classFilter (defaulting null), ignoring the `edge`/`drop`/`reach-suppress` acts — is witnessed via
    #    `reach`. A node declaring the mixed `acts` list reaches ONLY its two reach-edge targets: host:igloo
    #    class-scoped to home-manager (its nixos-only aspect EXCLUDED), host:cabin unfiltered (all present).
    test-reach-edges-read-via-reach = {
      expr =
        let
          g = {
            src.edges = acts; # mixed reach-edge + reach-suppress + edge + drop.
            "host:igloo".resolved = [
              nHostNixos # nixos-only → excluded by the home-manager classFilter.
              nHostHm # home-manager → included.
            ];
            "host:cabin".resolved = [ nB ]; # null filter → included.
          };
          ks = reachKeys g "src";
        in
        {
          iglooHm = builtins.elem "host-hm" ks; # class-scoped target reached.
          iglooNixosExcluded = !(builtins.elem "host-nixos" ks); # F9: nixos-only NOT reached.
          cabinUnfiltered = builtins.elem "b-aspect" ks; # null-filter target reached.
          # the `edge`/`drop` resolution acts contribute nothing (only reach-edge is followed).
          count = builtins.length ks;
        };
      expected = {
        iglooHm = true;
        iglooNixosExcluded = true;
        cabinUnfiltered = true;
        count = 2; # host-hm + b-aspect (src has no own resolved-aspects).
      };
    };

    # (Task 1 (b) `test-reach-suppress-of` — the direct `reachSuppressOf` `when`-predicate witness — is
    #  RETIRED here: suppression is now consumed inside `reach` (Task 4), so it is witnessed through `reach`
    #  by the suppression-both-arms units below, mirroring the reachEdgesOf demotion.)

    # ── Task 1 (c): additive identity — a node whose declarations carry ONLY non-reach-edge acts (edge/
    #    drop) follows NO positive edge ⇒ reach = own subtree only (the reachEdgesOf `[ ]` identity, now
    #    read through `reach`). ──
    test-no-edge-decls-identity = {
      expr =
        let
          g = {
            src = {
              resolved = [ nOwn ];
              edges = [
                {
                  __action = "edge";
                  aspect = {
                    key = "x";
                  };
                }
                {
                  __action = "drop";
                  aspect = {
                    key = "y";
                  };
                }
              ];
            };
          };
        in
        {
          ownOnly = reachKeys g "src"; # no reach-edge ⇒ own subtree only.
        };
      expected = {
        ownOnly = [ "cell-own" ];
      };
    };

    # ══ Task 1 (Phase 2) — the STRUCTURAL-DESCENDANT edge (subsumes classSubtreeAt) ═════════════════════
    #    reach's OWN/structural component is now the scope SUBTREE `[ id ] ++ scope.descendants self id`, not
    #    node-local. A host's reach includes its descendant CELLS' resolved-aspect nodes (the define-user
    #    nixos@host-from-cell mechanism, mirrored at the resolved-aspect level). `scope.descendants` reads the
    #    stub's `children` map (DFS). The class filter is a Task-2 projection concern — reach returns ALL
    #    reachable nodes here regardless of class.

    # ── (a) DESCENDANT PRESENT + CANONICAL POSITION: a host with a descendant cell → reach host includes the
    #    cell's define-user-shaped aspect, AFTER the host's own subtree, BEFORE any edge target. ──
    test-structural-descendant-in-canonical-position = {
      expr =
        let
          nDefineUser = mkNode "define-user" { nixos.tag = "du"; };
          g = {
            host = {
              resolved = [ nHostNixos ]; # host's own aspect (structural, first).
              children.cell = { }; # a descendant cell.
              edges = [ (reachEdgeAct "eprov" null) ]; # an opt-in edge (its target comes AFTER the subtree).
            };
            cell.resolved = [ nDefineUser ]; # the descendant cell's aspect.
            eprov.resolved = [ nB ]; # the edge target.
          };
          ks = reachKeys g "host";
        in
        {
          hasCellAspect = builtins.elem "define-user" ks; # descendant cell's aspect reached.
          keys = ks; # exact canonical order: own subtree (host, cell) THEN edge target.
        };
      expected = {
        hasCellAspect = true;
        keys = [
          "host-nixos" # host's own (structural first)
          "define-user" # descendant cell (structural subtree, after own, before edges)
          "b-aspect" # opt-in edge target (after the whole structural subtree)
        ];
      };
    };

    # ── (b) LEAF IDENTITY (additivity): a childless node (scope.descendants = []) ⇒ structural component ==
    #    its own resolved aspects EXACTLY — proves the subtree walk is additive for leaf nodes. ──
    test-structural-leaf-identity = {
      expr = reachKeys {
        leaf.resolved = [
          nOwn
          nShared
        ]; # no `children` ⇒ scope.descendants = [] ⇒ [ leaf ] subtree only.
      } "leaf";
      expected = [
        "cell-own"
        "shared"
      ];
    };

    # ── (c) PER-PROVIDER MULTIPLICITY across the descendant component (spec §1 single-visit refined
    #    2026-07-14, THE ANCHOR ruling): an aspect present on BOTH the host and a descendant cell is a
    #    DISTINCT ctx-eval result at each DISTINCT scope, so BOTH survive (count 2, host-first) — NOT a
    #    bare-key collapse. This is the law that makes reach's structural component byte-identical to
    #    `classSubtreeAt` (three cells' one parametric `acct` → three `users.users.<n>` nodes, not one); a
    #    bare-key collapse here would be the u24-class content-loss the spec §5 warns of. (Bare-key
    #    single-visit still applies to the EDGE closure + within a node — witnessed by the reach-single-visit
    #    / default-edge-dedup edge cases below.) ──
    test-structural-descendant-per-provider-multiplicity = {
      expr =
        let
          g = {
            host = {
              resolved = [ nShared ]; # host has `shared`.
              children.cell = { };
            };
            cell.resolved = [ nShared ]; # cell ALSO has `shared` (same key, DISTINCT scope).
          };
          ks = reachKeys g "host";
        in
        {
          count = builtins.length (builtins.filter (k: k == "shared") ks); # distinct scopes ⇒ 2.
          keys = ks; # BOTH "shared" nodes: host (first) then cell (structural subtree order).
        };
      expected = {
        count = 2;
        keys = [
          "shared"
          "shared"
        ];
      };
    };

    # ── (d) ALL reachable regardless of CLASS: reach returns descendant nodes irrespective of class — the
    #    class filter is a Task-2 projection concern, not applied in reach. A host reaches a nixos-only cell
    #    aspect AND a home-manager cell aspect alike (no class gate on the structural subtree). ──
    test-structural-descendant-class-agnostic = {
      expr =
        let
          g = {
            host = {
              resolved = [ nHostNixos ];
              children = {
                cellA = { };
                cellB = { };
              };
            };
            cellA.resolved = [ (mkNode "cell-nixos" { nixos.tag = "cn"; }) ];
            cellB.resolved = [ (mkNode "cell-hm" { home-manager.tag = "ch"; }) ];
          };
          ks = reachKeys g "host";
        in
        {
          hasNixosCell = builtins.elem "cell-nixos" ks; # nixos descendant reached.
          hasHmCell = builtins.elem "cell-hm" ks; # home-manager descendant reached (no class gate).
        };
      expected = {
        hasNixosCell = true;
        hasHmCell = true;
      };
    };

    # ══ Task 2 — reach(id) closure witnesses ══════════════════════════════════════════════════════════

    # ── (a) IDENTITY: a node with NO positive edges ⇒ reach id == its own resolved-aspects. ──
    test-reach-identity-no-edges = {
      expr = reachKeys {
        cell = {
          resolved = [ nOwn ];
        };
      } "cell";
      expected = [ "cell-own" ];
    };

    # ── (b) CLASS-SCOPED, no over-reach (F9): a positive edge cell→host classFilter="home-manager" pulls the
    #    host's hm-defining aspect but EXCLUDES the host's nixos-only aspect. ──
    test-reach-class-scoped-no-nixos-overreach = {
      expr =
        let
          g = {
            cell = {
              resolved = [ nOwn ];
              edges = [ (reachEdgeAct "host" "home-manager") ];
            };
            host.resolved = [
              nHostNixos
              nHostHm
            ];
          };
          ks = reachKeys g "cell";
        in
        {
          hasOwn = builtins.elem "cell-own" ks;
          hasHostHm = builtins.elem "host-hm" ks;
          hasHostNixos = builtins.elem "host-nixos" ks; # MUST be false (class-scoped).
        };
      expected = {
        hasOwn = true;
        hasHostHm = true;
        hasHostNixos = false;
      };
    };

    # ── (c) SINGLE-VISIT per reach(S): the SAME aspect (`shared`) reachable via BOTH the cell's own subtree
    #    AND an edge appears EXACTLY ONCE (dedup by key). ──
    test-reach-single-visit-count-1 = {
      expr =
        let
          g = {
            cell = {
              resolved = [
                nOwn
                nShared
              ];
              edges = [ (reachEdgeAct "host" null) ];
            };
            host.resolved = [ nShared ]; # same key "shared" as the cell's own include.
          };
          ks = reachKeys g "cell";
        in
        builtins.length (builtins.filter (k: k == "shared") ks);
      expected = 1;
    };

    # ── (d) PER-SCOPE, not global: two cells each edge to the SAME host aspect; each runs its OWN traversal,
    #    so the shared aspect is present in BOTH reach sets (no global visited-set collapses them). ──
    test-reach-per-scope-both-present = {
      expr =
        let
          g = {
            cellA = {
              resolved = [ (mkNode "own-a" { home-manager.tag = "a"; }) ];
              edges = [ (reachEdgeAct "host" null) ];
            };
            cellB = {
              resolved = [ (mkNode "own-b" { home-manager.tag = "b"; }) ];
              edges = [ (reachEdgeAct "host" null) ];
            };
            host.resolved = [ nShared ];
          };
        in
        {
          aHasShared = builtins.elem "shared" (reachKeys g "cellA");
          bHasShared = builtins.elem "shared" (reachKeys g "cellB");
        };
      expected = {
        aHasShared = true;
        bHasShared = true;
      };
    };

    # ── (e) TRANSITIVE: id→a→b (positive edges) includes b's (class-filtered) aspects in reach id. ──
    test-reach-transitive-b-present = {
      expr =
        let
          g = {
            cell = {
              resolved = [ nOwn ];
              edges = [ (reachEdgeAct "a" null) ];
            };
            a = {
              resolved = [ (mkNode "a-aspect" { home-manager.tag = "a"; }) ];
              edges = [ (reachEdgeAct "b" null) ];
            };
            b.resolved = [ nB ];
          };
          ks = reachKeys g "cell";
        in
        {
          hasA = builtins.elem "a-aspect" ks;
          hasB = builtins.elem "b-aspect" ks; # transitively reached.
        };
      expected = {
        hasA = true;
        hasB = true;
      };
    };

    # ══ Task 3 — framework default-edge (baseline injection) witnesses ═════════════════════════════════
    #    A `defaultEdgeTargets id` supplies per-node default reach-edges (the framework baseline seam). The
    #    baseline graph carries a `baseline` node with an hm aspect; a user cell has NO declared reach-edge.

    # ── (a) IDENTITY / additivity: with the NATIVE module (defaultEdgeTargets = (_: [ ])), a cell with no
    #    declared edge reaches its own subtree ONLY — the default-edge seam is inert (Task 2 byte-unchanged). ──
    test-default-edge-unset-identity = {
      expr = reachKeys {
        cell.resolved = [ nOwn ];
        baseline.resolved = [ (mkNode "baseline-hm" { home-manager.tag = "base"; }) ];
      } "cell";
      expected = [ "cell-own" ]; # baseline NOT reached — no default edge injected.
    };

    # ── (b) INJECTION: defaultEdgeTargets injects a `cell → baseline` default edge on USER CELLS only. Each
    #    cell's reach then includes the baseline's (class-filtered) aspects; a non-user node is unaffected. ──
    test-default-edge-injects-baseline = {
      expr =
        let
          # inject the baseline default edge on ids starting "cell" (the synthetic "is a user cell" test).
          isCell = id: builtins.substring 0 4 id == "cell";
          dget =
            id:
            if isCell id then
              [
                {
                  target = "baseline";
                  classFilter = "home-manager";
                }
              ]
            else
              [ ];
          g = {
            cellA.resolved = [ nOwn ];
            host.resolved = [ nHostNixos ]; # a non-user node — must NOT get the baseline edge.
            baseline.resolved = [
              (mkNode "baseline-hm" { home-manager.tag = "base"; })
              (mkNode "baseline-nixos" { nixos.tag = "bn"; }) # class-filtered OUT (home-manager edge).
            ];
          };
          reachW = reachKeysOn (raWith dget);
        in
        {
          cellHasOwn = builtins.elem "cell-own" (reachW g "cellA");
          cellHasBaselineHm = builtins.elem "baseline-hm" (reachW g "cellA");
          cellBaselineNixosFiltered = !(builtins.elem "baseline-nixos" (reachW g "cellA")); # F9.
          hostUnaffected = reachW g "host"; # non-user ⇒ no default edge ⇒ own only.
        };
      expected = {
        cellHasOwn = true;
        cellHasBaselineHm = true;
        cellBaselineNixosFiltered = true;
        hostUnaffected = [ "host-nixos" ];
      };
    };

    # ── (c) The default edge is an ORDINARY positive edge — single-visit dedups it against an OWN-include of
    #    the SAME baseline aspect (a cell that already includes `baseline-hm` in its own subtree AND reaches
    #    it via the default edge ⇒ the aspect appears ONCE). ──
    test-default-edge-dedup-vs-own = {
      expr =
        let
          dget = _: [
            {
              target = "baseline";
              classFilter = null;
            }
          ];
          shared = mkNode "baseline-hm" { home-manager.tag = "base"; };
          g = {
            cellA.resolved = [
              nOwn
              shared # own-include of the SAME key the default edge also reaches.
            ];
            baseline.resolved = [ shared ];
          };
          ks = reachKeysOn (raWith dget) g "cellA";
        in
        builtins.length (builtins.filter (k: k == "baseline-hm") ks);
      expected = 1;
    };

    # ══ Task 4 — negative-edge suppression (reach-suppress, u21 exclude) witnesses ═════════════════════
    #    A node declares a POSITIVE reach-edge E (→ "host") AND a reach-suppress { edge = "host"; when } —
    #    edge identity is the TARGET (Phase 1 has no separate edge-id). `when` is evaluated against the
    #    node's scope (`self.node id`). The droid predicate is `host.class == "droid"`. Two nodes share the
    #    SAME decls but differ only in scope (`node.host.class`): the droid arm suppresses E, the non-droid
    #    arm keeps it — asserting BOTH arms from one declaration set.

    # ── (a)+(b) BOTH ARMS: droid scope → E suppressed → host aspect ABSENT; non-droid scope → E survives →
    #    host aspect PRESENT. ──
    test-suppression-both-arms = {
      expr =
        let
          whenDroidScope = scope: (scope.host.class or null) == "droid";
          decls = [
            (reachEdgeAct "host" null) # positive edge E → host.
            {
              __action = "reach-suppress";
              edge = "host"; # remove the edge whose target is "host".
              when = whenDroidScope;
            }
          ];
          g = {
            droidCell = {
              resolved = [ nOwn ];
              edges = decls;
              node.host.class = "droid"; # scope handed to `when` ⇒ suppress FIRES.
            };
            nixosCell = {
              resolved = [ nOwn ];
              edges = decls;
              node.host.class = "nixos"; # `when` FALSE ⇒ edge survives.
            };
            host.resolved = [ nHostHm ];
          };
        in
        {
          droidHasHost = builtins.elem "host-hm" (reachKeys g "droidCell"); # suppressed → false.
          droidHasOwn = builtins.elem "cell-own" (reachKeys g "droidCell"); # own subtree unaffected.
          nixosHasHost = builtins.elem "host-hm" (reachKeys g "nixosCell"); # survives → true.
        };
      expected = {
        droidHasHost = false;
        droidHasOwn = true;
        nixosHasHost = true;
      };
    };

    # ── (c) when=FALSE is a NO-OP: a reach-suppress whose `when` never holds leaves the positive edge intact
    #    (the same edge target is reached). Matches by edge identity — a suppress naming a DIFFERENT target
    #    also leaves E intact. ──
    test-suppression-when-false-and-mismatch-noop = {
      expr =
        let
          g = {
            cell = {
              resolved = [ nOwn ];
              edges = [
                (reachEdgeAct "host" null)
                {
                  __action = "reach-suppress";
                  edge = "host";
                  when = _: false; # never holds ⇒ no-op.
                }
                {
                  __action = "reach-suppress";
                  edge = "some-other-target"; # identity mismatch ⇒ never removes E.
                  when = _: true;
                }
              ];
              node = { }; # scope irrelevant (when=false / mismatch).
            };
            host.resolved = [ nHostHm ];
          };
        in
        builtins.elem "host-hm" (reachKeys g "cell");
      expected = true; # E survives both a false-when suppress and a target-mismatch suppress.
    };

    # ══ Task 5 — canonical reach ordering (merge_ord determinism) witnesses ════════════════════════════
    #    P-PROJECT merge_ord: own-subtree FIRST, then default-edge targets, then opt-in-edge targets, each
    #    provider in include order. The Phase-2 class-slice merge relies on this for order-semantic content
    #    (the zsh ZSH_HIGHLIGHT_HIGHLIGHTERS multiset, persistence entry order — ledger u24).

    # ── (a) EXACT ORDER [O D P]: a cell with own aspect O, a DEFAULT edge → provider D, and an OPT-IN
    #    (declared reach-edge) → provider P. reach keys = [ O, D, P ] (own first, default before opt-in). ──
    test-reach-canonical-order = {
      expr =
        let
          # default edge on the cell → node "dprov"; the cell also DECLARES an opt-in reach-edge → "pprov".
          dget =
            id:
            if id == "cell" then
              [
                {
                  target = "dprov";
                  classFilter = null;
                }
              ]
            else
              [ ];
          g = {
            cell = {
              resolved = [ (mkNode "O" { home-manager.tag = "o"; }) ];
              edges = [ (reachEdgeAct "pprov" null) ]; # opt-in edge.
            };
            dprov.resolved = [ (mkNode "D" { home-manager.tag = "d"; }) ];
            pprov.resolved = [ (mkNode "P" { home-manager.tag = "p"; }) ];
          };
        in
        reachKeysOn (raWith dget) g "cell";
      expected = [
        "O" # own subtree first
        "D" # then the default-edge provider
        "P" # then the opt-in-edge provider
      ];
    };

    # ── (b) PROVIDER in INCLUDE ORDER: each provider contributes its own resolved-aspects in list order,
    #    and own-subtree multi-aspect order is preserved (forwardExpand order). ──
    test-reach-provider-include-order = {
      expr =
        let
          dget =
            id:
            if id == "cell" then
              [
                {
                  target = "dprov";
                  classFilter = null;
                }
              ]
            else
              [ ];
          g = {
            cell.resolved = [
              (mkNode "O1" { home-manager.tag = "o1"; })
              (mkNode "O2" { home-manager.tag = "o2"; })
            ];
            dprov.resolved = [
              (mkNode "D1" { home-manager.tag = "d1"; })
              (mkNode "D2" { home-manager.tag = "d2"; })
            ];
          };
        in
        reachKeysOn (raWith dget) g "cell";
      expected = [
        "O1"
        "O2" # own, in include order
        "D1"
        "D2" # default provider, in include order
      ];
    };

    # ── (c) STABLE across re-eval: reach is a pure list-accumulate with first-occurrence dedup — two
    #    independent evaluations of the SAME reach return the byte-identical key sequence (deterministic,
    #    no set-iteration nondeterminism). ──
    test-reach-order-stable = {
      expr =
        let
          dget =
            id:
            if id == "cell" then
              [
                {
                  target = "dprov";
                  classFilter = null;
                }
              ]
            else
              [ ];
          g = {
            cell = {
              resolved = [ (mkNode "O" { home-manager.tag = "o"; }) ];
              edges = [ (reachEdgeAct "pprov" null) ];
            };
            dprov.resolved = [ (mkNode "D" { home-manager.tag = "d"; }) ];
            pprov.resolved = [ (mkNode "P" { home-manager.tag = "p"; }) ];
          };
          once = reachKeysOn (raWith dget) g "cell";
          twice = reachKeysOn (raWith dget) g "cell";
        in
        once == twice
        &&
          once == [
            "O"
            "D"
            "P"
          ];
      expected = true;
    };
  };
}
