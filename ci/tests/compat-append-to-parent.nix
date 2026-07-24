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
{ denCompat, nixpkgsLib, ... }:
let
  inherit (denCompat) route compile;

  # Cross a host's built nixos modules through a REAL evalModules (a top-level freeform absorber, the same
  # `lazyAttrsOf raw` the terminal/placer use) and read the resolved `.config` — so a parent-targeted
  # `home-manager.users.<u>` remap is OBSERVED at the crossed config value, not by walking the placed
  # module's attr SHAPE (which the arg-threading rewrite makes a top-level function).
  crossFreeform =
    modules:
    (nixpkgsLib.evalModules {
      modules = [
        { config._module.freeformType = nixpkgsLib.types.lazyAttrsOf nixpkgsLib.types.raw; }
      ]
      ++ modules;
    }).config;

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
        # the cell's home-manager content — what the forward delivers. Authored the v1-SURFACE way
        # (`homeManager`): v1 keys the hm class camelCase; kebab `home-manager` is den-hoag's GROUNDED name, not
        # v1-surface. A parametric aspect's RESULT has no raw-splice, so a kebab class key freeform-mangles; the
        # v1 spelling grounds to `home-manager` at compile (the forward below still reads the grounded class).
        den.aspects.acct =
          { user, ... }:
          {
            homeManager.tag = "hm-${user.name}";
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

  # the host's hm-user projection OBSERVED at the crossed config: the parent-targeted forward's content
  # resolved at `home-manager.users.<n>` on the host terminal.
  hostHm =
    fleet: (crossFreeform (fleet.den.output.systems.nixos.${igloo}.modules or [ ])).home-manager or { };

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
      expr =
        let
          hm = hostHm withParent;
        in
        {
          users = builtins.attrNames (hm.users or { });
          tags = [ (hm.users.tux.tag or "<missing>") ];
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
      expr = builtins.attrNames ((hostHm noParent).users or { });
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
