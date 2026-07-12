# #74a (design §10, candidate D — ratified) — a delivery's collected members widen to the firing
# node's ANCESTOR CHAIN (outermost first) ++ itself ++ its descendants (`collectedMembersOf`,
# output-modules.nix, consumed at BOTH the terminal gather and the edge render). v1 provenance: the
# cell-fired forward's `getCollectedSource` reads `rootModules ++ ownModules` (pin 11866c16
# fx/edges/route.nix:556-568 — the ROOT scope's bucket FIRST) — how the corpus's HOST-attached
# homeManager content (apps.shell.zsh + persist-home-collector via roles/default.nix; the persistHome
# mounts ride the SAME bucket, §10 item 5) reaches every user's `home-manager.users.<u>`.
#
# Witnesses:
#   (1) the CELL-FIRED forward gathers the ancestor (host) bucket HOST-FIRST — order pinned
#       (v1's rootModules ++ ownModules), including a SECOND host module (the persistHome-shaped
#       companion: host bucket content rides regardless of module count/key shape);
#   (2) NO SIBLING CROSS-BLEED — two users on one host: each gets the host base + ONLY its own cell
#       content (candidate B's host-subtree gather is what this pins against);
#   (3) ROOT-FIRED identity — a host-fired route's members are unchanged (ancestors(root) = [ ]);
#   (4) DELIVERY-FREE identity — no delivery ⇒ the terminal is the fold exactly (the baseline law).
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

  # a nixos host with TWO hm user cells; the HOST carries home-manager content (two modules — the
  # role-attached zsh + the persistHome-shaped collector twin); each CELL carries its own; each cell
  # fires the parent-targeted hm forward (the #68/#53c shape). `withForward` toggles the forward.
  mk =
    withForward:
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.igloo = {
            class = "nixos";
            users.tuxA = { };
            users.tuxB = { };
          };
          schema.user.parent = "host";
          aspects.hostc.nixos.tag = "nixos-host";
          # the HOST-attached hm content (the corpus role shape): two distinct modules.
          aspects.hmbase.home-manager.tag = "hm-host-zsh";
          aspects.hmpersist.home-manager.tag = "hm-host-persist";
          schema.host.includes = [
            "hostc"
            "hmbase"
            "hmpersist"
          ];
          aspects.acct =
            { user, ... }:
            {
              home-manager.tag = "hm-${user.name}";
            };
          schema.user.includes = [ "acct" ];
        }
        // (
          if withForward then
            {
              policies.hm-forward =
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
          else
            { }
        );
      }
    ];
  fleet = mk true;
  plain = mk false;

  # the nested hm modules per user at the host terminal.
  userHmTags =
    f: u:
    builtins.concatMap (
      m: if builtins.isAttrs m && m ? home-manager then tags (m.home-manager.users.${u} or { }) else [ ]
    ) (f.den.output.systems.nixos.${igloo}.modules or [ ]);
  # a host-fired route's trace members (the root-fired identity read).
  rootRouteMembers =
    f:
    map (e: e.source.members) (
      builtins.filter (e: (e.source.class or null) == "home-manager") (f.den.graph.trace igloo)
    );
in
{
  flake.tests.delivery-ancestor-members = {
    # (1) HOST-FIRST order: each user's nested hm content = the host's TWO modules (include order),
    #     THEN the cell's own — v1's rootModules ++ ownModules (route.nix:556-568).
    test-ancestor-bucket-host-first = {
      expr = userHmTags fleet "tuxA";
      expected = [
        "hm-host-zsh"
        "hm-host-persist"
        "hm-tuxA"
      ];
    };
    # (2) no sibling cross-bleed: tuxB gets the host base + ONLY its own content (never tuxA's).
    test-no-sibling-cross-bleed = {
      expr = {
        tuxB = userHmTags fleet "tuxB";
        aHasNoB = builtins.elem "hm-tuxB" (userHmTags fleet "tuxA");
      };
      expected = {
        tuxB = [
          "hm-host-zsh"
          "hm-host-persist"
          "hm-tuxB"
        ];
        aHasNoB = false;
      };
    };
    # (3) the cell-fired edges' members are [host, cell] (ancestors-first) — the trace pin; and the
    #     delivery-free fleet renders NO hm edge at the host root.
    test-cell-edge-members-ancestors-first = {
      expr = rootRouteMembers fleet;
      expected = [
        [
          igloo
          "user:tuxA@host:igloo"
        ]
        [
          igloo
          "user:tuxB@host:igloo"
        ]
      ];
    };
    # (4) delivery-free identity: no forward ⇒ no nested hm content at the terminal (the fold alone —
    #     the 896 baseline law), and no hm edge at the host root.
    test-delivery-free-identity = {
      expr = {
        tuxA = userHmTags plain "tuxA";
        edges = rootRouteMembers plain;
      };
      expected = {
        tuxA = [ ];
        edges = [ ];
      };
    };
  };
}
