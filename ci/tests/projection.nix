# Phase 2 Task 2/3 (den-hoag class-projection over the resolved-aspect graph, spec §1/§3) — projectClass.
#
# `projectClass id class` = the class-`C` module slice of EVERY resolved-aspect node in `reach id`, in
# reach's canonical order (own-subtree → descendant cells → default edges → opt-in edges), each slice via
# `classSliceOf` (THE ONE extraction the `class-modules` buckets also use). Task 3 CONSUMED it:
# `terminalModulesAt = projectClass` — projection is now the terminal's content source (the emission model,
# `classSubtreeAt ++ deliveryModulesAt`, is dead; Phase 3 deletes it).
#
# THREE witness planes:
#   • THE ANCHOR (real fleet, the subsume proof): for a node with NO reach edges, `reach id` = its OWN scope
#     subtree (`[id] ++ scope.descendants`, Task 1), so `projectClass id class == classSubtreeAt id class`
#     byte-identically — projection reproduces the fold (incl. the descendant down-fold Task 1 subsumed)
#     BEFORE it replaces the emission. Driven on the `class-fold-subtree` fixture (nixos host + 3 hm cells
#     each emitting a define-user-shaped nixos slice), reached through `fleet.den.output.{projectClass,
#     classSubtreeAt}`.
#   • SYNTHETIC (stub reach, the edge-replacement proofs): `projectClass` is `concatMap (n: map (e: e.module)
#     (classSliceOf n class)) (reach id)`, so GIVEN a reach list it is a pure class-slice fold — reach's own
#     edge-following (opt-in / structural-descendant / class-scope) is proven in reach-graph.nix. Here we
#     drive projectClass over a STUB `result` serving a synthetic reach list, witnessing the class-slice
#     projection: an opt-in-edge host-hm slice included once, a descendant define-user nixos slice, F9
#     class-scope (no host nixos-only aspect in a home-manager projection), canonical order preserved.
{
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  inherit (denHoag.internal)
    prelude
    resolve
    classifyKey
    scope
    aspects
    select
    ;

  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, built with the base
  # `classifyKey` (nixos/darwin/home-manager/k8s-manifests) — the same functions the assembly threads to
  # `projectClass`.
  cm =
    import "${denHoagSrc}/lib/attributes/class-modules.nix"
      {
        inherit prelude resolve;
      }
      {
        classNames = [ ];
        inherit classifyKey;
      };
  inherit (cm) classSliceOf assertKeysRegistered;

  # projectClass replicated over a STUB reach list (byte-identical to output-modules.nix's body — a pure
  # class-slice fold over `reach id`). `reachList` stands in for `result.get id "reach"`.
  projectOver =
    reachList: class: prelude.concatMap (n: map (e: e.module) (classSliceOf n class)) reachList;

  # A synthetic resolved-aspect node `{ key; content }` (the reach node shape).
  mkNode = key: content: {
    inherit key content;
  };

  # ── COMPLETE-REACH driver (spec §Phase-2 synthetic-first): reach.compute over a STUB graph with INJECTED
  #    default + opt-in edges (the reach-graph mkStub/defaultEdgeTargets approach), then projectClass over
  #    the resulting reach — so the single-visit dedup + structural-descendant + edge closure are exercised
  #    end-to-end (NOT a pre-built reach list). This is how the corpus terminal will behave once Phase 5
  #    wires the real edges; here the edges are injected synthetically.
  mkRa =
    defaultEdgeTargets:
    import "${denHoagSrc}/lib/attributes/resolved-aspects.nix" {
      inherit
        prelude
        scope
        aspects
        select
        resolve
        ;
    } { inherit defaultEdgeTargets; };
  # A reach-graph stub `self` (resolved-aspects / declarations / children).
  mkStub = graph: {
    get =
      id: attr:
      if attr == "resolved-aspects" then
        (graph.${id} or { }).resolved or [ ]
      else if attr == "declarations" then
        { actions.resolution = (graph.${id} or { }).edges or [ ]; }
      else if attr == "children" then
        (graph.${id} or { }).children or { }
      else
        throw "projection stub: unexpected attr ${attr}";
    node = id: (graph.${id} or { }).node or { };
  };
  reachEdgeAct = target: classFilter: {
    __action = "reach-edge";
    inherit target classFilter;
  };
  # projectClass over a COMPLETE reach: reach.compute (with the injected default edges) → the class slice.
  projectReach =
    {
      defaultEdgeTargets ? (_: [ ]),
      graph,
      id,
      class,
    }:
    projectOver ((mkRa defaultEdgeTargets).reach.compute (mkStub graph) id) class;

  # projectClass WITH the §2.2 totality pass (byte-identical to output-modules.nix's projectClass body:
  # `seq (assertKeysRegistered n)` per REACHED aspect before its slice) — for the reached-content totality
  # witness (a typo key on an aspect reached via an EDGE aborts NAMED, not just an own-node key).
  projectReachTotal =
    {
      defaultEdgeTargets ? (_: [ ]),
      graph,
      id,
      class,
    }:
    prelude.concatMap (
      n: builtins.seq (assertKeysRegistered n) (map (e: e.module) (classSliceOf n class))
    ) ((mkRa defaultEdgeTargets).reach.compute (mkStub graph) id);

  # ── ANCHOR fixture: the class-fold-subtree fleet (nixos host `igloo` + three hm user cells, each cell
  #    emitting a nixos (define-user) slice + a home-manager slice). NO reach edges (corpus has none until
  #    Phase 5), so reach host = the structural subtree — the exact classSubtreeAt domain.
  anchorFleet = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.igloo = {
        class = "nixos";
        users.tux = { };
        users.pol = { };
        users.amy = { };
      };
      den.schema.user.parent = "host";
      den.aspects.hostc.nixos.tag = "nixos-host";
      den.schema.host.includes = [ "hostc" ];
      den.aspects.acct =
        { user, ... }:
        {
          nixos.tag = "nixos-${user.name}";
          home-manager.tag = "hm-${user.name}";
        };
      den.schema.user.includes = [ "acct" ];
    }
  ];
  igloo = "host:igloo";
  out = anchorFleet.den.output;

  # every `tag` string reachable in a wrapped deferredModule (gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
in
{
  flake.tests.projection = {
    # ══ THE ANCHOR — projectClass == classSubtreeAt on a no-edge node (the subsume proof) ══════════════
    # A real fleet host with descendant cells but NO reach edges: reach = `[id] ++ scope.descendants`, so
    # the class-slice projection over reach reproduces the classSubtreeAt down-fold BYTE-IDENTICALLY (same
    # module list, same A12 own-first ++ lexicographic-DFS order). This is projection SUBSUMING the fold.

    # (a) byte-identical module list at the host's NIXOS class (own host slice ++ the three cells' nixos).
    test-anchor-projectClass-eq-classSubtreeAt-nixos = {
      expr = out.projectClass igloo "nixos" == out.classSubtreeAt igloo "nixos";
      expected = true;
    };
    # (b) byte-identical at the HOME-MANAGER class too (the cells' hm slices; the per-class companion).
    test-anchor-projectClass-eq-classSubtreeAt-hm = {
      expr = out.projectClass igloo "home-manager" == out.classSubtreeAt igloo "home-manager";
      expected = true;
    };
    # (c) the projection's actual CONTENT + ORDER (not just equality) — own-first ++ lexicographic-DFS,
    #     proving the anchor equality is over the RIGHT value (the subtree fold), not two empties.
    test-anchor-projectClass-nixos-content-order = {
      expr = builtins.concatMap tags (out.projectClass igloo "nixos");
      expected = [
        "nixos-host" # own (self first)
        "nixos-amy" # descendant cells, lexicographic-DFS
        "nixos-pol"
        "nixos-tux"
      ];
    };

    # ══ SYNTHETIC — the class-slice projection over a stub reach list (edge-replacement proofs) ═════════

    # (a) OPT-IN EDGE (the emission replacement): a reach list = [ own-hm, host-hm ] (as reach would return
    #     for a cell→host home-manager edge). projectClass "home-manager" = both hm slices, each ONCE.
    test-synthetic-opt-in-edge-hm-once = {
      expr =
        let
          reachList = [
            (mkNode "cell-own" { home-manager.tag = "own"; })
            (mkNode "host-hm" { home-manager.tag = "host"; }) # reached via the opt-in edge.
          ];
          ts = builtins.concatMap tags (projectOver reachList "home-manager");
        in
        {
          slices = ts; # both hm slices present, in reach order.
          hostOnce = builtins.length (builtins.filter (t: t == "host") ts); # single-visit ⇒ 1.
        };
      expected = {
        slices = [
          "own"
          "host"
        ];
        hostOnce = 1;
      };
    };

    # (b) STRUCTURAL-DESCENDANT (the classSubtreeAt replacement): a reach list = [ host-nixos, define-user ]
    #     (host own ++ a descendant cell's define-user, as Task-1 reach returns). projectClass "nixos"
    #     includes the descendant cell's define-user nixos slice.
    test-synthetic-descendant-define-user-nixos = {
      expr =
        let
          reachList = [
            (mkNode "host-nixos" { nixos.tag = "host"; })
            (mkNode "define-user" { nixos.tag = "du"; }) # the descendant cell's define-user slice.
          ];
        in
        builtins.concatMap tags (projectOver reachList "nixos");
      expected = [
        "host"
        "du"
      ];
    };

    # (c) F9 CLASS-SCOPE (no over-reach): projecting the `home-manager` class over a reach list that includes
    #     a nixos-ONLY host aspect does NOT pull the nixos slice — `classSliceOf` selects only the projected
    #     class's key. (reach's edge class-filter is the reach-graph companion; this is the projection gate.)
    test-synthetic-class-scope-no-nixos-in-hm = {
      expr =
        let
          reachList = [
            (mkNode "cell-own" { home-manager.tag = "own"; })
            (mkNode "host-nixos" { nixos.tag = "n"; }) # nixos-only — MUST NOT enter the hm projection.
          ];
        in
        builtins.concatMap tags (projectOver reachList "home-manager");
      expected = [ "own" ]; # host-nixos's nixos slice excluded (no home-manager key).
    };

    # (d) ORDER — projectClass preserves reach's canonical order exactly (own → descendant → default →
    #     opt-in), each provider's slice in include order (projectClass is a straight concatMap over reach).
    test-synthetic-projection-order = {
      expr =
        let
          reachList = [
            (mkNode "O" { nixos.tag = "o"; }) # own
            (mkNode "Desc" { nixos.tag = "desc"; }) # descendant
            (mkNode "Dflt" { nixos.tag = "dflt"; }) # default edge
            (mkNode "OptIn" { nixos.tag = "optin"; }) # opt-in edge
          ];
        in
        builtins.concatMap tags (projectOver reachList "nixos");
      expected = [
        "o"
        "desc"
        "dflt"
        "optin"
      ];
    };

    # ══ COMPLETE-REACH projection SEMANTICS (Task 3 — the terminal-content proofs, spec §6 intent) ══════
    #    Drive the REAL reach.compute over a stub with INJECTED default + opt-in edges, then projectClass —
    #    proving the terminal (terminalModulesAt = projectClass) produces the RIGHT output on a complete
    #    reach (the fleet will match once Phase 5 wires the real corpus edges). These are the outcomes the
    #    spec §6 intent oracle names: spicetify ONCE, intel cpu+gpu BOTH, define-user nixos@host + hm@cell.

    # (a) THE SPICETIFY DOUBLE dissolves — ONE declaration. A user (sini) reaches `roles.media` (→ the
    #     spicetify hm aspect) via BOTH its OWN include AND an opt-in edge to the host that ALSO includes it
    #     (same A-IDENT key). Single-visit collapses own+edge to ONE node ⇒ the spicetify hm slice appears
    #     EXACTLY ONCE in the user's home-manager projection (spec §0/§3: the double dissolves as a graph
    #     property, no dedup rule). RED under v1's blanket host→cell gather (the u25 "already declared" abort).
    test-semantic-spicetify-double-resolves-once = {
      expr =
        let
          spicetify = mkNode "roles.media" { home-manager.tag = "spicetify"; };
          graph = {
            sini = {
              resolved = [
                (mkNode "sini-own" { home-manager.tag = "sini"; })
                spicetify # sini's OWN include of roles.media.
              ];
              edges = [ (reachEdgeAct "host" "home-manager") ]; # opt-in edge to the host…
            };
            host.resolved = [ spicetify ]; # …which ALSO includes roles.media (same key).
          };
          ts = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "sini";
            class = "home-manager";
          });
        in
        {
          spicetifyCount = builtins.length (builtins.filter (t: t == "spicetify") ts); # ONCE.
          hasOwn = builtins.elem "sini" ts;
        };
      expected = {
        spicetifyCount = 1; # own+edge collapsed by single-visit — no double.
        hasOwn = true;
      };
    };

    # (b) A-IDENT DE-COLLISION — `hardware.cpu.intel` AND `hardware.gpu.intel` BOTH present. Two DISTINCT
    #     aspects (distinct A-IDENT keys) whose short names would collide under a name-only identity are
    #     kept as two nodes (native container-relative key), so both nixos slices project (spec §6 Cause-2).
    test-semantic-intel-cpu-and-gpu-both-present = {
      expr =
        let
          graph = {
            host.resolved = [
              (mkNode "hardware.cpu.intel" { nixos.tag = "cpu-intel"; })
              (mkNode "hardware.gpu.intel" { nixos.tag = "gpu-intel"; })
            ];
          };
          ts = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "host";
            class = "nixos";
          });
        in
        {
          cpu = builtins.elem "cpu-intel" ts;
          gpu = builtins.elem "gpu-intel" ts;
          count = builtins.length ts; # BOTH — no key collision collapse.
        };
      expected = {
        cpu = true;
        gpu = true;
        count = 2;
      };
    };

    # (c) DEFINE-USER SPLIT — ONE parametric multi-class aspect (`define-user`) projects nixos@HOST (via the
    #     structural-descendant edge, Task 1) AND home-manager@CELL (the cell's own include). One reachable
    #     node, projected per-class-per-scope (spec §2 define-user model): the host's nixos projection carries
    #     the define-user nixos slice; the cell's home-manager projection carries the define-user hm slice.
    test-semantic-define-user-nixos-at-host-hm-at-cell = {
      expr =
        let
          defineUser = mkNode "define-user" {
            nixos.tag = "du-nixos"; # the users.users.<n> shape (host class).
            home-manager.tag = "du-hm"; # the cell's own hm content.
          };
          graph = {
            host = {
              resolved = [ (mkNode "host-own" { nixos.tag = "host"; }) ];
              children.cell = { }; # the (user,host) cell nests under the host.
            };
            cell.resolved = [ defineUser ]; # define-user lives on the cell.
          };
          hostNixos = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "host";
            class = "nixos";
          });
          cellHm = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "cell";
            class = "home-manager";
          });
        in
        {
          hostHasDefineUserNixos = builtins.elem "du-nixos" hostNixos; # nixos@host (structural descendant).
          hostNoHmLeak = !(builtins.elem "du-hm" hostNixos); # the hm slice does NOT enter the nixos projection.
          cellHasDefineUserHm = builtins.elem "du-hm" cellHm; # home-manager@cell (own).
        };
      expected = {
        hostHasDefineUserNixos = true;
        hostNoHmLeak = true;
        cellHasDefineUserHm = true;
      };
    };

    # ══ §2.2 TOTALITY over REACHED content (ruling 2026-07-14) ══════════════════════════════════════════
    # Projection widened what a scope reaches (edges + descendants), so the unregistered-key totality abort
    # must cover REACHED aspects, not just own-node content — else a typo on an edge-reached aspect would
    # silently vanish on the drv path (the §5 silent-content-loss failure). `projectReachTotal` mirrors
    # output-modules.nix's projectClass (the `assertKeysRegistered` force per reached aspect).

    # (a) a typo key (`nixxos`) on an aspect reached via an OPT-IN EDGE aborts NAMED under projection —
    #     totality holds for edge-reached content, not just the own node.
    test-totality-unregistered-key-on-reached-aspect-aborts = {
      expr =
        let
          graph = {
            host = {
              resolved = [ (mkNode "host-own" { nixos.tag = "host"; }) ];
              edges = [ (reachEdgeAct "provider" null) ]; # opt-in edge to the provider…
            };
            # …whose aspect carries an UNREGISTERED content key `nixxos` (a typo — neither facet/class/channel).
            # `name` is the aspect name classifyKey reports in the abort (real resolved aspects carry it).
            provider.resolved = [
              (mkNode "typo-aspect" {
                name = "typo-aspect";
                nixxos.tag = "boom";
              })
            ];
          };
          r = builtins.tryEval (
            builtins.deepSeq (projectReachTotal {
              inherit graph;
              id = "host";
              class = "nixos";
            }) true
          );
        in
        r.success; # MUST be false — the reached typo aborts named at projection.
      expected = false;
    };

    # (b) NON-VACUOUS companion: the SAME edge-reached aspect with a REGISTERED class key (`nixos`) does NOT
    #     abort — only a genuinely unregistered key does; a registered key of a reached aspect passes
    #     (e.g. define-user's darwin/home-manager keys while projecting nixos are registered, never abort).
    test-totality-registered-key-on-reached-aspect-ok = {
      expr =
        let
          graph = {
            host = {
              resolved = [ (mkNode "host-own" { nixos.tag = "host"; }) ];
              edges = [ (reachEdgeAct "provider" null) ];
            };
            provider.resolved = [
              (mkNode "ok-aspect" {
                name = "ok-aspect";
                nixos.tag = "reached";
              })
            ]; # registered key.
          };
          ts = builtins.concatMap tags (projectReachTotal {
            inherit graph;
            id = "host";
            class = "nixos";
          });
        in
        {
          noAbort = builtins.elem "reached" ts; # the reached registered slice projects, no abort.
          hasOwn = builtins.elem "host" ts;
        };
      expected = {
        noAbort = true;
        hasOwn = true;
      };
    };

    # (c) NAME ROBUSTNESS (Phase-3 hardening): a reached aspect whose `content` lacks a populated `.name`
    #     (a synthetic/degenerate node) with an UNREGISTERED key must STILL abort NAMED — the
    #     `assertKeysRegistered` `content.name or "<unnamed>"` fallback keeps the abort the intended
    #     `errors.unknownAspectKey`-shaped message, never a raw `attribute 'name' missing` throw that would
    #     mask the real (unregistered-key) fault. Drives the abort path directly on a `.name`-less aspect.
    test-totality-nameless-aspect-unregistered-key-aborts-named = {
      expr =
        let
          namelessTypo = mkNode "nameless-typo" { nixxos.tag = "boom"; }; # NO `name` key in content.
          r = builtins.tryEval (builtins.seq (assertKeysRegistered namelessTypo) true);
        in
        {
          # Aborts (not silently passing) — the fallback name reaches the named-abort branch.
          aborts = !r.success;
          # NON-RAW: had it thrown the raw `attribute 'name' missing`, the aspect below (registered key,
          # still `.name`-less) would ALSO throw — the positive control proves the fallback lets a
          # registered-key `.name`-less aspect pass, so the abort above is the NAMED unregistered-key path.
          namelessRegisteredOk =
            (builtins.tryEval (
              builtins.seq (assertKeysRegistered (mkNode "nameless-ok" { nixos.tag = "ok"; })) true
            )).success;
        };
      expected = {
        aborts = true;
        namelessRegisteredOk = true;
      };
    };
  };
}
