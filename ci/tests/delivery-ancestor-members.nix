# #74a (design §10, candidate D — ratified) — a delivery's collected members widen to the firing
# node's ANCESTOR CHAIN (outermost first) ++ itself ++ its descendants (`collectedMembersOf`,
# output-modules.nix, consumed at BOTH the terminal gather and the edge render). v1 provenance: the
# cell-fired forward's `getCollectedSource` reads `filterRootModules rootModules ++ ownModules` (pin
# 11866c16 fx/edges/route.nix:556-568 — the ROOT scope's bucket FIRST, RESTRICTED to den.default-shared).
#
# R-ROOT-FILTER RE-BASELINE (ledger u23(b) → u25, Track A rung 2): the ancestor (host) bucket is now
# restricted to its SHARED (`den.default`) modules when the firing cell OWNS the delivered class
# (`filterRootModules`, output-modules.nix; v1 route.nix:540-552). Witnesses (1)/(2) were written at
# #74a (pre-twin, the un-built-filter era) asserting HOST-OWN (`schema.host.includes`) hm content reached
# cells — that was the corpus-inert OVER-DELIVERY the ledger u23(b) flagged as a loud re-opener. They are
# re-baselined here to the v1-faithful shape: ancestor-own hm is DROPPED, a den.default-SHARED ancestor
# hm SURVIVES (witness (5)); the corpus reaches users only via den.default-tagged host hm.
#
# Witnesses:
#   (1) the CELL-FIRED forward filters the ancestor (host) bucket to den.default-shared: a host-OWN hm
#       aspect is DROPPED; only the cell's own content survives (R-ROOT-FILTER own-drop);
#   (2) NO SIBLING CROSS-BLEED — two users on one host: each gets ONLY its own cell content (never the
#       sibling's), the host-own hm filtered from both;
#   (3) ROOT-FIRED identity — a host-fired route's members are unchanged (ancestors(root) = [ ]);
#   (4) DELIVERY-FREE identity — no delivery ⇒ the terminal is the fold exactly (the baseline law);
#   (5) SHARED SURVIVES / OWN DROPS — a den.default host hm rides into the cell gather (shared arm); a
#       `schema.host.includes` host hm is dropped (own arm) — both arms of the twin, one fixture;
#   (6) R-ROOT-FILTER clears the double — one hm aspect at host+user (own both) declared ONCE.
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

  # a nixos host with TWO hm user cells; the HOST carries home-manager content SCOPE-OWN (via
  # schema.host.includes — the corpus role shape, pre-den.default); each CELL carries its own; each cell
  # fires the parent-targeted hm forward (the #68/#53c shape). Under R-ROOT-FILTER the host-OWN hm is
  # DROPPED from a cell's gather (the cell owns home-manager); only the cell's own survives. `withForward`
  # toggles the forward.
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
          # HOST-attached hm content, SCOPE-OWN (schema.host.includes): two distinct modules, both
          # filtered out of a cell's gather by R-ROOT-FILTER (own-of-ancestor in the cell's owned class).
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

  # Witness (5) — SHARED SURVIVES / OWN DROPS (both arms of R-ROOT-FILTER, one fixture). The host carries
  # TWO hm aspects: `hmshared` radiated via `den.default` (SHARED at the ancestor → survives the filter)
  # and `hmown` via `schema.host.includes` (SCOPE-OWN → dropped). The cell owns home-manager, so a proper-
  # ancestor member (the host) is filtered: `hm-shared` reaches the cell, `hm-own-host` does not. (NB: a
  # `den.default` aspect also radiates to the CELL, so `hm-shared` can appear twice in the raw gather — the
  # ancestor copy + the cell's own radiated copy; a separate den.default key-dedup concern, out of scope
  # here. This witness asserts PRESENCE/ABSENCE, not multiplicity.)
  sharedMk = denCompat.mkDen [
    (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo = {
          class = "nixos";
          users.tuxA = { };
        };
        den.schema.user.parent = "host";
        den.default.includes = with den.aspects; [ hmshared ];
        den.aspects.hmshared.home-manager.tag = "hm-shared";
        den.aspects.hmown.home-manager.tag = "hm-own-host";
        den.schema.host.includes = with den.aspects; [ hmown ];
        den.aspects.acct =
          { user, ... }:
          {
            home-manager.tag = "hm-${user.name}";
          };
        den.schema.user.includes = with den.aspects; [ acct ];
        den.policies.hm-forward =
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
    )
  ];

  # R-ROOT-FILTER witness (ledger u25, the spicetify double). An hm-declaring aspect included at BOTH host
  # scope (schema.host.includes — SCOPE-OWN there) AND user scope (schema.user.includes) rides the host
  # ANCESTOR bucket AND the cell OWN bucket into the #74a member gather → doubled at the cell terminal.
  # The cell OWNS the home-manager class, so the twin restricts the host (ancestor) bucket to SHARED
  # (`den.default`) modules — dropping the host's own copy — so it is declared ONCE (by the cell). The
  # `dup` aspect is NOT radiated (own at both scopes) ⇒ GREEN drops the host copy entirely: `[dup, hm-u]`.
  dupMk = denCompat.mkDen [
    {
      den = {
        hosts.x86_64-linux.igloo = {
          class = "nixos";
          users.tuxA = { };
        };
        schema.user.parent = "host";
        aspects.dup.home-manager.tag = "dup";
        # `dup` is OWN at BOTH scopes (the roles.media shape — one aspect, two includes).
        schema.host.includes = [ "dup" ];
        aspects.acct =
          { user, ... }:
          {
            home-manager.tag = "hm-${user.name}";
          };
        schema.user.includes = [
          "dup"
          "acct"
        ];
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
      };
    }
  ];

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
    # ── RETIRED (den-hoag projection, Phase 2 Task 3 — terminalModulesAt = projectClass) ──────────────
    # test-ancestor-bucket-host-first / test-no-sibling-cross-bleed (below: test-shared-survives-own-drops /
    # test-root-filter-clears-double) tested the #74a ANCESTOR-MEMBER terminal gather + the R-ROOT-FILTER
    # twin (`collectedMembersOf` at the TERMINAL, `filterRootModules`, output-modules.nix): a cell-fired
    # forward gathered the ancestor (host) bucket, restricted to den.default-shared. The projection pivot
    # REPLACES that emission model — the terminal is `projectClass id class` over `reach`. No-sibling-
    # cross-bleed + the spicetify double (root-filter-clears-double) are now GRAPH properties: distinct cells
    # run distinct per-scope reach traversals (no cross-bleed) and single-visit dedups own+edge to one node
    # (the double dissolves) — witnessed at `ci/tests/projection.nix` (per-scope reach, spicetify-once) and
    # `ci/tests/reach-graph.nix` (per-scope both-present, own∩edge single-visit). The shared-vs-own
    # filterRootModules distinction is DELETED (spec §1 Corollary: "no shared/own marker"); baseline becomes
    # an ordinary framework default edge (Phase 5). The two witnesses BELOW that read the EDGE-render/trace
    # (test-cell-edge-members-ancestors-first — `collectedMembersOf` via the LIVE `deliveryEdgesAt`) and the
    # delivery-free IDENTITY (test-delivery-free-identity) are KEPT — they exercise still-live code.

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
    # (5) test-shared-survives-own-drops + (6) test-root-filter-clears-double: RETIRED — see the retirement
    #     note above. The shared/own filterRootModules distinction is DELETED under projection (spec §1
    #     Corollary), and the spicetify double dissolves as a single-visit graph property (witnessed at
    #     ci/tests/projection.nix + reach-graph.nix). Phase 3 deletes the emission machinery these read.
  };
}
