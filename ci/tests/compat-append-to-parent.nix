# #53c (§9 item 3, ratified) — renderDelivery HONORS `appendToParent`: a delivery declaring it targets
# the containment PARENT root (`deliveryTargetRootOf`, output-modules.nix) instead of its firing scope.
# v1 provenance: `appendToParent` is a route property (pin 11866c16 nix/lib/aspects/fx/edges/route.nix:364
# `appendToParent = route.appendToParent or false`; target resolution :370-377 `appendScopeIdOf` =
# `scopeParent.${sid} or sid`), reached only through `route`'s `__extra` mechanism channel (v1
# policy-effects.nix:60 — the `deliver` surface deliberately rejects it; :194 lists it among the route
# mechanism fields). den-hoag renders it as the first-class parent-targeting edge gen-edge's derivation
# already gathers (derive.nix:67-69), consumed at the host terminal by the #66 law (`deliveryModulesAt`
# scans `[ root ] ++ descendants`).
#
# THE RATIFIED TRACE-TARGET CEILING (ledger u18): the parent-target makes the den-hoag edge target the
# HOST root where v1's cell-fired synthesize edge targets the CELL — a TRACE-only divergence,
# drvPath-invisible (the delivered content byte-matches), P1-unexercised; fixture-surfaced re-opener.
#
# Witnesses:
#   (1) a CELL-FIRED parent-targeted forward reaches the HOST terminal — the cell's source-class bucket
#       lands nested at the delivery path in the host's built modules (the #66 consumption law), and the
#       edge joins the HOST root's edge set;
#   (2) the identity companion — the SAME forward without the flag targets the cell root: nothing at the
#       host terminal, the edge stays in the CELL root's edge set (pre-#53c behavior, byte-identical);
#   (3) the PARENTLESS case — v1's semantics at the pin: `scopeParent.${sid} or sid` FALLS BACK to the
#       firing scope itself (route.nix:375, :804 — a defined no-op, never an abort): a parentless-root
#       delivery with the flag renders exactly the self-targeted edge, annotated;
#   (4) the descriptor surface — route's `__extra.appendToParent` sets the field (default false), and
#       the edge annotation mirrors v1's routeEdge (:813).
{ denCompat, ... }:
let
  inherit (denCompat) route compile;

  # every `tag` string reachable in a wrapped deferredModule (the walker the #66/#63 witnesses use),
  # plus the #53c nest wrapper (home-manager.users.<n>).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];

  # ── (1)/(2) a nixos host + one hm user cell; the cell fires a home-manager → host.class forward at
  #    itself (the userDetectFn shape); `withParent` toggles `__extra.appendToParent`. ──
  mkForward =
    withParent:
    denCompat.mkDen [
      {
        den.hosts.x86_64-linux.igloo = {
          class = "nixos";
          users.tux = { };
        };
        den.schema.user.parent = "host";
        den.aspects.hostc.nixos.tag = "nixos-host";
        den.schema.host.includes = [ "hostc" ];
        # the cell's home-manager content — what the forward delivers.
        den.aspects.acct =
          { user, ... }:
          {
            home-manager.tag = "hm-${user.name}";
          };
        den.schema.user.includes = [ "acct" ];
        # the CELL-FIRED forward ({ user, host } formals ⇒ fires at (user,host) cells only) — the
        # userForward shape: fromClass=home-manager, intoClass=host.class, intoPath=home-manager/users/<n>.
        den.policies.hmForward =
          { user, host, ... }:
          [
            (route (
              {
                fromClass = "home-manager";
                intoClass = host.class;
                intoPath = [
                  "home-manager"
                  "users"
                  user.name
                ];
              }
              // (if withParent then { __extra.appendToParent = true; } else { })
            ))
          ];
      }
    ];
  withParent = mkForward true;
  noParent = mkForward false;
  igloo = "host:igloo";
  cell = "user:tux@host:igloo";

  # the hm→nixos delivery edges in a root's frozen trace (the default-fold edges are same-class).
  hmEdgesAt =
    fleet: root:
    builtins.filter (
      e: (e.source.class or null) == "home-manager" && (e.target.class or null) == "nixos"
    ) (fleet.den.graph.trace root);

  # the nested hm module the host terminal carries: modules placing content at home-manager.users.<n>.
  hostNestedHmUsers =
    fleet:
    builtins.concatMap (
      m:
      if builtins.isAttrs m && m ? home-manager then
        builtins.attrNames (m.home-manager.users or { })
      else
        [ ]
    ) (fleet.den.output.systems.nixos.${igloo}.modules or [ ]);
  hostNestedHmTags =
    fleet:
    builtins.concatMap (
      m: if builtins.isAttrs m && m ? home-manager then tags (m.home-manager.users.tux or { }) else [ ]
    ) (fleet.den.output.systems.nixos.${igloo}.modules or [ ]);

  # ── (3) parentless: a cell-less host (a parentless scope root) fires a quirk-channel route on itself
  #    with the flag — v1's `or sid` fallback ⇒ the ordinary self-targeted edge. ──
  mkParentless =
    withFlag:
    denCompat.mkDen [
      {
        den.hosts.x86_64-linux.igloo.class = "nixos";
        den.quirks.src = { };
        den.quirks.dst = { };
        den.aspects.seed.src = [ "hello" ];
        den.schema.host.includes = [ "seed" ];
        den.policies.route1 = _ctx: [
          (route (
            {
              fromClass = "src";
              intoClass = "dst";
            }
            // (if withFlag then { __extra.appendToParent = true; } else { })
          ))
        ];
      }
    ];
  parentlessEdge =
    fleet:
    builtins.head (
      builtins.filter (e: (e.source.class or null) == "src" && (e.target.class or null) == "dst") (
        fleet.den.graph.trace igloo
      )
    );

  # ── (4) the descriptor surface (compile-level, no fleet). ──
  declOf =
    extra:
    builtins.head (
      (compile {
        classes.src = { };
        classes.dst = { };
        policies.p = _ctx: [
          (route (
            {
              fromClass = "src";
              intoClass = "dst";
            }
            // extra
          ))
        ];
      }).policies.p.fn
        { }
    );
in
{
  flake.tests.compat-append-to-parent = {
    # (1) the parent-targeted cell-fired forward reaches the HOST terminal: the cell's hm content lands
    #     nested at home-manager.users.tux in the host's built modules.
    #
    # PHASE 4 DELIVERED (the #10 hm-user-detect descendant-driven route, Task 2): `terminalModulesAt =
    # projectClass`, and the HOST projecting `nixos` gathers the cell-fired `appendToParent` route from its
    # DESCENDANT cell (`parentTargetedRoutesAt`, output-modules.nix) — the cell's `home-manager` slice remaps
    # to `nixos` at `[ home-manager users tux ]`. So the cell's forwarded hm content NOW reaches the host
    # terminal (the delivery half is a projection-view transform, not an emission fold). The mark-pending
    # marker was mis-scoped (this is hm-FORWARD content, not a host-aspects reach-edge — that is Phase 5).
    test-parent-target-reaches-host-terminal = {
      expr = {
        users = hostNestedHmUsers withParent;
        tags = hostNestedHmTags withParent;
      };
      expected = {
        users = [ "tux" ];
        tags = [ "hm-tux" ];
      };
    };
    # …and the edge joins the HOST root's edge set (the ratified trace-target ceiling: v1's synthesize
    #    edge targets the cell; den-hoag's collected edge targets the host — trace-only, ledgered u18).
    test-parent-target-edge-at-host-root = {
      expr = map (e: e.target.root) (hmEdgesAt withParent igloo);
      expected = [ igloo ];
    };
    test-parent-target-edge-not-at-cell-root = {
      expr = builtins.length (hmEdgesAt withParent cell);
      expected = 0;
    };

    # (2) identity companion: WITHOUT the flag the forward targets the cell root — nothing nested at the
    #     host terminal, the edge stays in the cell's edge set (pre-#53c behavior, byte-identical).
    test-no-flag-host-terminal-clean = {
      expr = hostNestedHmUsers noParent;
      expected = [ ];
    };
    test-no-flag-edge-at-cell-root = {
      expr = map (e: e.target.root) (hmEdgesAt noParent cell);
      expected = [ cell ];
    };
    test-no-flag-edge-not-at-host-root = {
      expr = builtins.length (hmEdgesAt noParent igloo);
      expected = 0;
    };

    # (3) parentless: the flag on a parentless firing root falls back to SELF (v1 route.nix:375
    #     `scopeParent.${sid} or sid` — defined no-op, never an abort): the edge is the self-targeted
    #     one, byte-equal to the unflagged companion except the annotation.
    test-parentless-falls-back-to-self = {
      expr = (parentlessEdge (mkParentless true)).target.root;
      expected = igloo;
    };
    test-parentless-only-annotation-differs = {
      expr =
        let
          flagged = parentlessEdge (mkParentless true);
          plain = parentlessEdge (mkParentless false);
        in
        {
          sameTarget = flagged.target == plain.target;
          sameSource = flagged.source == plain.source;
          flaggedAnnotated = flagged.annotations.appendToParent or false;
          plainUnannotated = plain.annotations ? appendToParent;
        };
      expected = {
        sameTarget = true;
        sameSource = true;
        flaggedAnnotated = true;
        plainUnannotated = false;
      };
    };

    # (4) the descriptor surface: `__extra.appendToParent` sets the declaration field (default false);
    #     the annotation mirrors v1's routeEdge (fx/edges/route.nix:813).
    test-descriptor-flag-set = {
      expr = (declOf { __extra.appendToParent = true; }).appendToParent;
      expected = true;
    };
    test-descriptor-flag-defaults-false = {
      expr = (declOf { }).appendToParent;
      expected = false;
    };
    test-descriptor-annotation-mirrors-v1 = {
      expr = (declOf { __extra.appendToParent = true; }).annotations.appendToParent or false;
      expected = true;
    };
  };
}
