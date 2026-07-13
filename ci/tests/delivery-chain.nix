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
  flake.tests.delivery-chain = {
    # (1) the chain: the routed `hl` content rides the forward into the host terminal's per-user set,
    #     AFTER the cell's own hm content (base-then-routed, v1's append order).
    test-chain-delivers-through-forward = {
      expr = userHmTags chained;
      expected = [
        "hm-tux"
        "hl-tux"
      ];
    };
    # (2) identity: without the route only the direct hm content arrives (`++ [ ]`).
    test-delivery-free-identity = {
      expr = userHmTags plain;
      expected = [ "hm-tux" ];
    };
    # (3) single-path once-only: the routed content appears EXACTLY once.
    test-chain-once-only = {
      expr = builtins.length (builtins.filter (t: t == "hl-tux") (userHmTags chained));
      expected = 1;
    };
    # (4) a cycle aborts NAMED; the acyclic companion (one leg removed) terminates and carries the
    #     chained content (ca ← cb at the terminal).
    test-cycle-aborts-named = {
      expr = ok (termOf (mkCycle true));
      expected = false;
    };
    test-acyclic-companion-terminates = {
      expr = {
        okEval = ok (termOf (mkCycle false));
        hasChained = builtins.elem "b" (builtins.concatMap tags (termOf (mkCycle false)));
      };
      expected = {
        okEval = true;
        hasChained = true;
      };
    };
    # (5) the diamond evaluates without a false-abort — the shared (igloo, cs) is entered on two
    #     separate branches, each with a path-local seen-set.
    test-diamond-no-false-abort = {
      expr = ok (termOf diamond);
      expected = true;
    };
    # (5) the shared source's content lands ONCE PER BRANCH (cs → cx and cs → cy) — multiplicity 2,
    #     the affirmative dual of no-false-abort (both branches read it, neither is dropped).
    test-diamond-shared-multiplicity = {
      expr = builtins.length (builtins.filter (t: t == "s") (builtins.concatMap tags (termOf diamond)));
      expected = 2;
    };
  };
}
