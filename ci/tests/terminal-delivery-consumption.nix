# #66 — the DELIVERY→TERMINAL UNIFICATION (design note §9, the terminal dual of v1's post-route read):
# a node's per-class TERMINAL assembly = `classSubtreeAt id class ++ deliveryModulesAt id class`
# (output-modules.nix, consumed at the three terminal reads hostModules/deltaOf/contentIdsOf — the
# byte-compare path). den-hoag's A15 fold unifies the content-mover with the trace onto ONE edge set, so
# ALL cross-class routed content (the corpus os→nixos `programs.zsh.enable`) lives in the delivery-edge
# stream and reached `outputFor` but NOT the built drv (the terminal read `classSubtreeAt` alone). #66
# widens the terminal INPUT to match the fold's OUTPUT — the routed content is APPENDED after the
# same-class subtree fold (A12 base-first, routed-after — v1's `appendToClass` appends).
#
# Four witnesses:
#   (1) a HOST-ROOTED cross-class delivery lands its source bucket in the host's nixos terminal, AFTER
#       the host's own nixos content (base ++ routed). This is the LITERAL corpus mechanism: the ambient
#       `os→nixos` route (the os-class battery, on every nixos host) delivers the host's `os` bucket
#       content (the corpus `os.programs.zsh.enable`) into the nixos terminal — pre-#66 it reached
#       `outputFor` but NOT the built drv.
#   (2) a DELIVERY-FREE companion — with no `os` content the ambient route gathers an EMPTY bucket, so
#       the terminal is `classSubtreeAt` exactly (byte-identical identity path, the 840 baseline).
#   (3) the SINGLE-PATH guard — a same-class MERGE delivery (from==to==the producing class, at=[]) would
#       double with the fold ⇒ LOUD abort; a same-class NEST delivery (distinct path) is allowed (the
#       non-vacuous companion — the guard is the merge-at-root case, not any same-class delivery).
#   (4) the u4 over-fire stays inert — a CELL-fired delivery targets the CELL (deliveryTargetRootOf keys
#       on the firing node; no appendToParent in #66), so it never reaches the HOST terminal; only
#       host-rooted deliveries do. Uses a `darwin` source (NO ambient darwin route — the ONLY darwin→nixos
#       edge is the cell-fired one, isolating the cell-vs-host rooting; `os` would be confounded by the
#       host's own ambient os→nixos route gathering the cell's os content via the #62c subtree members).
{ denCompat, ... }:
let
  inherit (denCompat) deliver;

  # every `tag` string reachable in a wrapped deferredModule (the gen-aspects `{ imports = [ … ]; }`
  # form) — the same walker the #63 class-fold witness uses.
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
      ++ (if m ? p then tags m.p else [ ]) # the nest-at-["p"] wrapper (witness 3 companion)
    else
      [ ];
  termTags =
    fleet: id: class:
    builtins.concatMap tags (fleet.den.output.systems.${class}.${id}.modules or [ ]);
  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;

  # ── (1)/(2) a nixos host with own nixos content; `withOs` toggles an `os`-class bucket the AMBIENT
  #    os→nixos route (the os-class battery) delivers into the nixos terminal — the corpus os mechanism. ──
  mkOs =
    withOs:
    denCompat.mkDen [
      {
        den.hosts.x86_64-linux.igloo.class = "nixos";
        # the host's OWN nixos content (the A12 base — folds first).
        den.aspects.hostc.nixos.tag = "nixos-host";
        # the host's `os` bucket — delivered to nixos by the ambient os→nixos route (the corpus
        # `os.programs.zsh.enable` shape); `withOs` toggles whether the aspect is included.
        den.aspects.osc.os.tag = "os-delivered";
        den.schema.host.includes = [ "hostc" ] ++ (if withOs then [ "osc" ] else [ ]);
      }
    ];
  withOs = mkOs true;
  noOs = mkOs false;

  # ── (3) the single-path guard: a same-class delivery. `nest` toggles at=["p"] (allowed) vs at=[]
  #    (merge — the doubling case the guard aborts). ──
  mkSameClass =
    nest:
    denCompat.mkDen [
      {
        den.hosts.x86_64-linux.igloo.class = "nixos";
        den.aspects.hostc.nixos.tag = "nixos-host";
        den.schema.host.includes = [ "hostc" ];
        den.policies.self1 = _ctx: [
          (deliver (
            {
              from = "nixos";
              to = "nixos";
            }
            // (if nest then { at = [ "p" ]; } else { })
          ))
        ];
      }
    ];
  sameClassMerge = mkSameClass false;
  sameClassNest = mkSameClass true;

  # ── (4) the u4 over-fire: a CELL-fired darwin→nixos delivery. The host has its own nixos content; the
  #    user cell carries a darwin bucket AND fires the delivery (a `{ user, … }` policy fires at cells). ──
  mkCellFired = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.igloo = {
        class = "nixos";
        users.tux = { };
      };
      den.schema.user.parent = "host";
      den.aspects.hostc.nixos.tag = "nixos-host";
      den.schema.host.includes = [ "hostc" ];
      # the cell's OWN darwin bucket (a user include — resolves at the cell).
      den.aspects.cellc.darwin.tag = "cell-darwin";
      den.schema.user.includes = [ "cellc" ];
      # the delivery FIRES AT THE CELL (a user-coord policy) → targets the cell, not the host.
      den.policies.cellRoute = { user, ... }: [
        (deliver {
          from = "darwin";
          to = "nixos";
        })
      ];
    }
  ];
  igloo = "host:igloo";
  cell = "user:tux@host:igloo";
  crossEdgesAt =
    fleet: root:
    builtins.filter (e: (e.source.class or null) == "darwin" && (e.target.class or null) == "nixos") (
      fleet.den.graph.trace root
    );
in
{
  flake.tests.terminal-delivery-consumption = {
    # ── RETIRED (den-hoag projection, Phase 2 Task 3 — terminalModulesAt = projectClass) ──────────────
    # test-host-rooted-delivery-lands-at-terminal (the #66 os→nixos delivery CONTENT at the terminal) and
    # test-same-class-merge-delivery-aborts (the `errors.sameClassMergeDelivery` guard that lived in the
    # deleted `deliveryModulesChain` terminal gather) both tested the DELETED emission terminal read. The
    # terminal is now `projectClass id class` over `reach`; cross-class delivery (os→nixos) becomes a
    # positive reach-edge (the Phase-4 forwards/routes transform layer emits it, Phase-5 wires the corpus
    # producer), and the same-class-merge double it guarded against cannot arise (projection folds each
    # class slice once via single-visit — no fold+delivery double to guard). Projection-level class-slice
    # semantics are witnessed in ci/tests/projection.nix. The IDENTITY + still-LIVE edge-render witnesses
    # below (delivery-free-terminal-is-fold-only, same-class-nest-allowed, the cell-fired-edge trace trio)
    # are KEPT — they exercise projection identity + the live `deliveryEdgesAt` renderer.

    # (2) delivery-free identity companion: with no `os` content the terminal is the own subtree exactly —
    #     now byte-identical under projection (reach = structural subtree when no edge producer fires).
    test-delivery-free-terminal-is-fold-only = {
      expr = termTags noOs igloo "nixos";
      expected = [ "nixos-host" ];
    };

    # …a same-class NEST delivery (at=["p"]) places at a DISTINCT path,
    #     so it is ALLOWED — the guard is the merge-at-root case specifically, not any same-class delivery.
    test-same-class-nest-delivery-allowed = {
      expr = ok sameClassNest.den.output.systems.nixos;
      expected = true;
    };

    # (4) the u4 over-fire stays inert: a CELL-fired delivery targets the CELL (deliveryTargetRootOf keys
    #     on the firing node), so it never reaches the HOST terminal.
    test-cell-fired-delivery-absent-from-host-terminal = {
      expr = termTags mkCellFired igloo "nixos";
      expected = [ "nixos-host" ];
    };
    # …the host ROOT's edge set carries NO darwin→nixos edge (the cell-fired one targets the cell root)…
    test-cell-fired-edge-not-at-host-root = {
      expr = builtins.length (crossEdgesAt mkCellFired igloo);
      expected = 0;
    };
    # …but the CELL root's edge set DOES (non-vacuous — the delivery fired, it just targets the cell).
    test-cell-fired-edge-at-cell-root = {
      expr = builtins.length (crossEdgesAt mkCellFired cell);
      expected = 1;
    };
  };
}
