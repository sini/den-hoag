# Phase 2 Task 2 (den-hoag class-projection over the resolved-aspect graph, spec §1/§3) — projectClass.
#
# `projectClass id class` = the class-`C` module slice of EVERY resolved-aspect node in `reach id`, in
# reach's canonical order (own-subtree → descendant cells → default edges → opt-in edges), each slice via
# `classSliceOf` (THE ONE extraction the `class-modules` buckets also use). It is UNCONSUMED here (additive)
# — `terminalModulesAt` still folds `classSubtreeAt ++ deliveryModulesAt` (Task 3 wires it).
#
# TWO witness planes:
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
  inherit (denHoag.internal) prelude resolve classifyKey;

  # THE ONE per-aspect class-slice extraction, built with the base `classifyKey` (nixos/darwin/
  # home-manager/k8s-manifests) — the same function the assembly threads to `projectClass`.
  classSliceOf =
    (import "${denHoagSrc}/lib/attributes/class-modules.nix" {
      inherit prelude resolve;
    } { classNames = [ ]; inherit classifyKey; }).classSliceOf;

  # projectClass replicated over a STUB reach list (byte-identical to output-modules.nix's body — a pure
  # class-slice fold over `reach id`). `reachList` stands in for `result.get id "reach"`.
  projectOver = reachList: class: prelude.concatMap (n: map (e: e.module) (classSliceOf n class)) reachList;

  # A synthetic resolved-aspect node `{ key; content; __denShared }` (the reach node shape).
  mkNode = key: content: {
    inherit key content;
    __denShared = false;
  };

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
  };
}
