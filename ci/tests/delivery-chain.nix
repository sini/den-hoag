# #75a (design §11, C1 — ratified) — THE DELIVERY CHAIN: a delivery's collected source, per member m
# and source class C, is `(classModulesAt m).C ++ deliveryModulesAt m C` — the cross-class delivery
# output already targeted at (m, C) splices into the source (the #66 gather reused as the chain link;
# no bucket ever touched — deliveryEdgesAt/outputFor/trace unchanged, the M2 terminal-only posture).
# The corpus shape: the home-platform route {homeLinux → homeManager} fires at the USER CELL
# (home-platform.nix:38-42) and the hm userForward's source reads the routed content — v1's
# appendToClass + post-route getCollectedSource, composed here without bucket mutation.
#
# Witnesses:
#   (1) the ROUTE→FORWARD chain (the corpus shape): a cell-fired route delivers a terminal-less class's
#       content into the cell's home-manager, and the parent-targeted hm forward carries it to the host
#       terminal — base-then-routed order (the cell's own hm content first, the routed content after);
#   (2) the DELIVERY-FREE identity companion — without the route, only the direct hm content arrives;
#   (3) SINGLE-PATH once-only — the routed content appears EXACTLY once in the host terminal's nested
#       per-user module set;
#   (4) a delivery CYCLE aborts NAMED (errors.deliveryChainCycle; v1 topoSort route.nix:496) — with the
#       non-vacuous clean companion (the same fixture minus one leg terminates);
#   (5) a DAG DIAMOND never false-aborts (the path-local seen-set): two deliveries source ONE
#       (scope, class) on separate branches reconverging at the terminal — the shared node is entered
#       once per branch (a GLOBAL seen-set would abort the second entry), its content once per branch.
{ denCompat, ... }:
let
  inherit (denCompat) route;

  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
  igloo = "host:igloo";

  # ── (1)-(3): the corpus chain in miniature. `hl` is a declared platform-half class (the homeLinux
  #    twin); the cell carries hm content AND hl content; a cell-fired route hl→home-manager (the
  #    home-platform shape) + the cell-fired parent-targeted hm forward (the #68/#53c shape).
  mk =
    withRoute:
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.igloo = {
            class = "nixos";
            users.tux = { };
          };
          schema.user.parent = "host";
          classes.hl = { };
          aspects.hostc.nixos.tag = "nixos-host";
          schema.host.includes = [ "hostc" ];
          aspects.acct =
            { user, ... }:
            {
              home-manager.tag = "hm-${user.name}";
              hl.tag = "hl-${user.name}";
            };
          schema.user.includes = [ "acct" ];
          policies = {
            hm-forward =
              { user, host, ... }:
              [
                (route {
                  fromClass = "home-manager";
                  intoClass = host.class;
                  intoPath = [
                    "home-manager"
                    "users"
                    user.name
                  ];
                  __extra.appendToParent = true;
                })
              ];
          }
          // (
            if withRoute then
              {
                platform-route =
                  { user, host, ... }:
                  [
                    (route {
                      fromClass = "hl";
                      intoClass = "home-manager";
                    })
                  ];
              }
            else
              { }
          );
        };
      }
    ];
  chained = mk true;
  plain = mk false;

  userHmTags =
    f:
    builtins.concatMap (
      m: if builtins.isAttrs m && m ? home-manager then tags (m.home-manager.users.tux or { }) else [ ]
    ) (f.den.output.systems.nixos.${igloo}.modules or [ ]);

  # ── (4): the cycle — class A's delivery sources B while B's sources A at the same scope; the
  #    terminal's chain read must abort NAMED. The clean companion drops the B→A leg. ──
  mkCycle =
    withBack:
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.igloo.class = "nixos";
          classes.ca = { };
          classes.cb = { };
          aspects.hostc.nixos.tag = "nixos-host";
          aspects.seeds = {
            ca.tag = "a";
            cb.tag = "b";
          };
          schema.host.includes = [
            "hostc"
            "seeds"
          ];
          policies = {
            into-terminal = _ctx: [
              (route {
                fromClass = "ca";
                intoClass = "nixos";
              })
            ];
            a-from-b = _ctx: [
              (route {
                fromClass = "cb";
                intoClass = "ca";
              })
            ];
          }
          // (
            if withBack then
              {
                b-from-a = _ctx: [
                  (route {
                    fromClass = "ca";
                    intoClass = "cb";
                  })
                ];
              }
            else
              { }
          );
        };
      }
    ];
  # ── (5): the DIAMOND. Two deliveries — `cs → cx → nixos` and `cs → cy → nixos` — both source the
  #    same (igloo, cs) on SEPARATE branches, reconverging at the terminal. The chain read enters
  #    `deliveryModulesChain igloo cs` twice, once per branch; each carries its OWN seen' (the parent's
  #    {igloo|nixos} extended by igloo|cx resp. igloo|cy — never each other's), so neither sees
  #    igloo|cs and neither false-aborts. A GLOBAL seen-set would record igloo|cs on the first branch
  #    and abort the second. The `cs` content ("s") therefore lands ONCE PER BRANCH (multiplicity 2). ──
  diamond = denCompat.mkDen [
    {
      den = {
        hosts.x86_64-linux.igloo.class = "nixos";
        classes.cs = { };
        classes.cx = { };
        classes.cy = { };
        aspects.hostc.nixos.tag = "nixos-host";
        aspects.seeds = {
          cs.tag = "s";
          cx.tag = "x";
          cy.tag = "y";
        };
        schema.host.includes = [
          "hostc"
          "seeds"
        ];
        policies = {
          x-to-term = _ctx: [
            (route {
              fromClass = "cx";
              intoClass = "nixos";
            })
          ];
          y-to-term = _ctx: [
            (route {
              fromClass = "cy";
              intoClass = "nixos";
            })
          ];
          s-to-x = _ctx: [
            (route {
              fromClass = "cs";
              intoClass = "cx";
            })
          ];
          s-to-y = _ctx: [
            (route {
              fromClass = "cs";
              intoClass = "cy";
            })
          ];
        };
      };
    }
  ];
  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;
  termOf = f: f.den.output.systems.nixos.${igloo}.modules or [ ];
in
{
  # ── RETIRED (den-hoag projection, Phase 2 Task 3 — terminalModulesAt = projectClass) ────────────────
  # Every witness here tested the #75a DELIVERY-CHAIN terminal read (`deliveryModulesChain`/
  # `deliveryModulesAt`, output-modules.nix): a route's collected source spliced the cross-class delivery
  # output the TERMINAL gathered at (m, C). The projection pivot REPLACES that emission model — the terminal
  # is now `projectClass id class` over `reach` (positive edges + the structural-descendant subtree), so the
  # delivery-chain terminal gather is DEAD (Phase 3 deletes `deliveryModulesChain`/`deliveryModulesAt`).
  # The chain semantics these pinned (routed content once-only, base-then-routed order, cycle-aborts,
  # DAG-diamond multiplicity) are subsumed by the reach EDGE closure + single-visit/merge_ord laws,
  # witnessed at the projection level in `ci/tests/projection.nix` (the reach + projectClass witnesses) and
  # `ci/tests/reach-graph.nix` (edge transitivity, per-scope single-visit, canonical order). The corpus
  # route→forward producer that fed this chain is re-wired as an opt-in reach-edge at Phase 5.
  flake.tests.delivery-chain = { };
}
