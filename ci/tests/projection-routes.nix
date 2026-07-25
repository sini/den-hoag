# Phase 4 Task 1 (den-hoag projection routes/forwards TRANSFORM layer, spec §5 (b)) — the route
# class-remap in `projectClass`.
#
# A ROUTE is a class→class CONTENT transform on the projected view (NOT a reachability edge). A route
# `{ from=D; to=C; at=<path>; guard }` lowered at the projecting scope ADDS, to `projectClass id C`, the
# guard-gated remap of each REACHED node's class-D slice, placed at `at`. Phase 3 deleted the emission
# fold, so route content (e.g. home-platform homeLinux→homeManager) was a HOLE; this rebuilds it as a
# transform ADDITIVE to the base projection (identity when no route targets C).
#
# This drives the REAL `mkOutputModules` (`lib/attributes/output-modules.nix`) over a STUB `result` that
# serves `reach` (the reached nodes), `declarations` (the `__action="delivery"` route records `routesAt`
# lowers), `enriched-context` (the guard's scope bindings) and `node`/`children`. The witnesses:
#   1. homeLinux→homeManager (at=[], no guard): the homeManager projection includes the reached nodes'
#      homeLinux slices (in projection order) IN ADDITION to the base homeManager slices. (This IS the
#      corpus home-platform route — UNGUARDED; its platform gate is at POLICY dispatch, not a route guard.)
#   2. SYNTHETIC content-time guard-FALSE (a route guard reading host.system): the route contributes NOTHING
#      (framework generality — the corpus route has no guard; this exercises the guard feature synthetically).
#   3. nested (at=[devshells default]): the remapped slice wrapped under devshells.default, NOT flat.
#   4. no route targeting C ⇒ `projectClass id C` UNCHANGED (identity — the additive base).
# Guard PHASE (functionArgs classification, owner ruling): content-time (entity formals → gated at
# projection) vs eval-time (module formals → config-gated at the crossing via nested eval, no import-cycle).
{
  denHoag,
  denHoagSrc,
  denCompat,
  nixpkgsLib,
  ...
}:
let
  inherit (denHoag.internal)
    prelude
    resolve
    scope
    edge
    bind
    merge
    aspects
    classShare
    ;
  errors = import "${denHoagSrc}/lib/errors.nix";

  # A `classifyKey` (the §2.2 three-branch dispatch) built with the FLEET-DECLARED class names the route
  # fixtures use (`homeLinux`/`devshell`/`flake-parts` are corpus-declared classes, not core built-ins) —
  # the same `concern-aspects.nix` instance the assembly builds, only with an extended `classNames`. This
  # is how the real fleet classifies a home-platform `homeLinux` slice (a declared class key) as `"class"`.
  inherit
    (import "${denHoagSrc}/lib/concern-aspects.nix" {
      inherit
        prelude
        aspects
        merge
        errors
        ;
      classNames = [
        "nixos"
        "darwin"
        "home-manager"
        "homeLinux"
        "devshell"
        "flake-parts"
      ];
      kindNames = [ ];
    })
    classifyKey
    ;

  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, built with the extended
  # `classifyKey` — the same functions the assembly threads to `projectClass`.
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

  # A synthetic resolved-aspect node `{ key; content }` (the reach node shape `classSliceOf` reads).
  mkNode = key: content: {
    inherit key content;
  };

  # A `delivery` resolution action (the shape `translateDelivery`/`deliveriesAt` produce/read): a
  # class→class route carries `sourceClass`/`targetClass` entries (`{ name; }`), a `path`, `mode`, and a
  # `guard` closure (or null). `module = null` ⇒ a CLASS source (route case) — `routesAt` reads
  # `from = sourceClass.name`. `appendToParent` (default false) ⇒ the route targets the containment PARENT
  # root (the #10 hm-user-detect forward — gathered by the host via `parentTargetedRoutesAt`, Task 2).
  # `__action = "delivery"`, not `__dropped`.
  deliveryAct =
    {
      from,
      to,
      at ? [ ],
      guard ? null,
      adaptArgs ? null,
      appendToParent ? false,
    }:
    {
      __action = "delivery";
      sourceClass = {
        name = from;
      };
      targetClass = {
        name = to;
      };
      module = null;
      path = at;
      mode = "merge";
      inherit guard adaptArgs appendToParent;
    };

  # A STUB `result` for `mkOutputModules`: `reach id` = the reached node list, `declarations` = the route
  # (delivery) actions, `enriched-context` = the guard's scope bindings, `node`/`children` inert. `allNodes`
  # keys the systems spine (unforced by projectClass). Each id in `graph` carries `{ reach; routes ? [];
  # ctx ? {}; node ? {} }`.
  mkResult = graph: {
    allNodes = builtins.mapAttrs (_: _: { }) graph;
    get =
      id: attr:
      let
        g = graph.${id} or { };
      in
      if attr == "reach" then
        g.reach or [ ]
      else if attr == "declarations" then
        { actions.resolution = g.routes or [ ]; }
      else if attr == "enriched-context" then
        g.ctx or { }
      else if attr == "children" then
        g.children or { }
      else if attr == "resolved-aspects" then
        g.reach or [ ]
      # Track A's `placeRemapped` threads `bindingsAt srcScope` (source-scope channel/settings bindings) into
      # the nested slice eval; these fixtures declare no channels/settings, so serve them empty (the real
      # fleet serves the neron/settings folds). `enriched-context` (ctx) above already covers the entity half.
      else if attr == "received-collections" then
        { }
      else if attr == "resolved-settings" then
        { }
      else
        throw "projection-routes stub: unexpected attr ${attr}";
    node = id: (graph.${id} or { }).node or { parent = null; };
  };

  # Instantiate the REAL `mkOutputModules` over a stub `result` and pull out `projectClass` (the code path
  # under test). classesByName/classOfNode/channelNames are inert for projectClass (it reads only reach +
  # declarations + enriched-context); `classSliceOf`/`assertKeysRegistered` are the real extraction.
  mkOut =
    graph:
    import "${denHoagSrc}/lib/attributes/output-modules.nix"
      {
        inherit
          prelude
          scope
          edge
          bind
          merge
          classShare
          errors
          ;
      }
      {
        result = mkResult graph;
        classesByName = { };
        classOfNode = _: null;
        channelNames = [ ];
        inherit classSliceOf assertKeysRegistered;
      };

  projectClassOf =
    graph: id: class:
    (mkOut graph).projectClass id class;

  # every `tag` string reachable in a wrapped deferredModule (gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];

  # nixpkgs lib for the Task-3 arg-env witnesses — the REAL evalModules crossing (the terminal), where a
  # projected flake-parts slice reading an adaptArgs-injected arg must resolve. `lib` is den-hoag's ONE
  # sanctioned nixpkgs boundary (mirrors the terminal); the arg-env witnesses cross it explicitly.
  lib = nixpkgsLib;

  # Cross the projected `flake-parts` content through a REAL evalModules with a `devshells.default`
  # submodule option (the corpus #15 shape), returning the resolved `devshells.default.marker` — a slice
  # module sets `marker` from an adaptArgs-injected arg, so a resolved marker PROVES the injection reached
  # the nested submodule eval. `tryEval` so a missing-arg abort (the fails-without-hook teeth) is observable.
  crossFlakeParts =
    projected:
    (lib.evalModules {
      modules = [
        {
          options.devshells = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submoduleWith {
                modules = [
                  {
                    options.marker = lib.mkOption {
                      type = lib.types.str;
                      default = "none";
                    };
                  }
                ];
              }
            );
            default = { };
          };
        }
      ]
      ++ projected;
    }).config.devshells.default.marker;

  # Cross the projected content through a REAL evalModules declaring a LIST-valued `orderLog` option, and
  # return the merged list. A list option's merge PRESERVES module order, so the concat order of `orderLog`
  # contributions observes the `routeRemapFor` delivery order (base own-reach < own-scope remap <
  # parent-targeted remap) through a real terminal — the order-semantic that a placed FUNCTION module makes
  # unobservable by structural attr-walking.
  crossOrderLog =
    projected:
    (lib.evalModules {
      modules = [
        {
          options.orderLog = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        }
      ]
      ++ projected;
    }).config.orderLog;

  # Cross projected class content through a REAL evalModules with a top-level freeform absorber (the same
  # `lazyAttrsOf raw` the terminal/placer use), returning `.config` — so a placed parent-targeted
  # `home-manager.users.<u>` remap is OBSERVED at the crossed config (its resolved value), not by walking the
  # placed module's attr SHAPE (which the arg-threading rewrite makes a top-level function).
  crossFreeform =
    projected:
    (lib.evalModules {
      modules = [
        { config._module.freeformType = lib.types.lazyAttrsOf lib.types.raw; }
      ]
      ++ projected;
    }).config;
in
{
  flake.tests.projection-routes = {
    # ══ (1) THE CONTENT REMAP — homeLinux → homeManager, at=[], guard true (bucket b, #14) ══════════════
    # A route `{ from="homeLinux"; to="home-manager"; at=[] }` fired at the projecting scope: for each
    # reached node, its `homeLinux` slice is remapped INTO the `home-manager` projection (flat, at=[]), in
    # projection order, IN ADDITION to the base `home-manager` slices. This fills the LOCALE_ARCHIVE hole
    # Phase 3 deleted — the exact content the u24/u25 β fight delivered.
    test-route-homeLinux-to-homeManager-remap = {
      expr =
        let
          graph.scope = {
            reach = [
              (mkNode "a" {
                home-manager.tag = "hm-base"; # base home-manager slice.
                homeLinux.tag = "linux-a"; # remapped INTO home-manager by the route.
              })
              (mkNode "b" {
                homeLinux.tag = "linux-b"; # a second reached node's homeLinux slice.
              })
            ];
            routes = [
              (deliveryAct {
                from = "homeLinux";
                to = "home-manager";
              })
            ];
          };
          ts = builtins.concatMap tags (projectClassOf graph "scope" "home-manager");
        in
        ts;
      # base home-manager (hm-base) FIRST, then the route-remapped homeLinux slices in projection order.
      expected = [
        "hm-base"
        "linux-a"
        "linux-b"
      ];
    };

    # ══ (2) GUARD-FALSE — a wrong-host.system content-time guard contributes NOTHING ═══════════════════════
    # A SYNTHETIC content-time route guard (a closure over the enriched-context entity bindings, reading
    # `host.system`) returning false gates the WHOLE remap out — the home-manager projection is the base only.
    # (Framework generality — an END-USER config may put such a guard on a route. NOTE: the corpus's OWN
    # home-platform is NOT this shape: it gates at POLICY dispatch (`lib.optional (hasSuffix host.system)
    # route`), so its emitted homeLinux→homeManager route is UNGUARDED — this witness exercises the guard
    # feature synthetically, not the corpus route.)
    test-route-guard-false-contributes-nothing = {
      expr =
        let
          graph.scope = {
            reach = [
              (mkNode "a" {
                home-manager.tag = "hm-base";
                homeLinux.tag = "linux-a";
              })
            ];
            # guard reads host.system; FALSE here (the scope is not the guarded platform).
            routes = [
              (deliveryAct {
                from = "homeLinux";
                to = "home-manager";
                guard = ctx: (ctx.host.system or "") == "x86_64-linux";
              })
            ];
            ctx.host.system = "aarch64-darwin"; # wrong system ⇒ guard false.
          };
          ts = builtins.concatMap tags (projectClassOf graph "scope" "home-manager");
        in
        ts;
      expected = [ "hm-base" ]; # ONLY the base — the guarded remap dropped.
    };

    # ══ (2b) GUARD-TRUE companion — the SAME guard on the RIGHT system DOES remap (non-vacuous) ══════════
    test-route-guard-true-remaps = {
      expr =
        let
          graph.scope = {
            reach = [
              (mkNode "a" {
                home-manager.tag = "hm-base";
                homeLinux.tag = "linux-a";
              })
            ];
            routes = [
              (deliveryAct {
                from = "homeLinux";
                to = "home-manager";
                guard = ctx: (ctx.host.system or "") == "x86_64-linux";
              })
            ];
            ctx.host.system = "x86_64-linux"; # right system ⇒ guard true.
          };
          ts = builtins.concatMap tags (projectClassOf graph "scope" "home-manager");
        in
        ts;
      expected = [
        "hm-base"
        "linux-a"
      ];
    };

    # ══ (3) NESTED PLACEMENT — at=[devshells default] places the slice UNDER the path, NOT flat ═══════════
    # A route with a non-empty path places the remapped slice at `devshells.default` — OBSERVED at the crossed
    # config: the slice's `tag` lands at `devshells.default.tag`, and does NOT leak flat to the top level.
    # (The placed module is a top-level function under the arg-threading rewrite; its shape is not walked —
    # the crossing resolves it.)
    test-route-nested-path-wraps-slice = {
      expr =
        let
          graph.scope = {
            reach = [ (mkNode "d" { devshell.tag = "shell-slice"; }) ];
            routes = [
              (deliveryAct {
                from = "devshell";
                to = "flake-parts";
                at = [
                  "devshells"
                  "default"
                ];
              })
            ];
          };
          crossed = crossFreeform (projectClassOf graph "scope" "flake-parts");
        in
        {
          nestedTag = crossed.devshells.default.tag or "<missing>"; # the slice content sits UNDER the path.
          notFlat = !(crossed ? tag); # the slice's own `tag` did NOT land flat at the top level.
        };
      expected = {
        nestedTag = "shell-slice";
        notFlat = true;
      };
    };

    # ══ (4) IDENTITY — no route targeting class C ⇒ projectClass id C UNCHANGED (additive) ═══════════════
    # (a) A scope with NO delivery declaration: the home-manager projection is the base reach fold alone —
    #     byte-identical to a scope with no routesAt entry (the route-remap is `++ [ ]`).
    test-route-identity-no-route = {
      expr =
        let
          reach = [
            (mkNode "a" { home-manager.tag = "hm-a"; })
            (mkNode "b" { home-manager.tag = "hm-b"; })
          ];
          withNoRoute = builtins.concatMap tags (
            projectClassOf { scope = { inherit reach; }; } "scope" "home-manager"
          );
          # base-only reference: the same reach with the route machinery present but targeting ANOTHER class.
          otherClassRoute = builtins.concatMap tags (
            projectClassOf {
              scope = {
                inherit reach;
                routes = [
                  (deliveryAct {
                    from = "homeLinux";
                    to = "nixos";
                  })
                ]; # targets nixos, NOT home-manager.
              };
            } "scope" "home-manager"
          );
        in
        {
          noRoute = withNoRoute; # base fold.
          otherClassRouteUnchanged = otherClassRoute; # a route to a DIFFERENT class leaves hm untouched.
        };
      expected = {
        noRoute = [
          "hm-a"
          "hm-b"
        ];
        otherClassRouteUnchanged = [
          "hm-a"
          "hm-b"
        ];
      };
    };

    # ══ (5) #10 hm-user-detect — DESCENDANT-DRIVEN parent-targeted route (Task 2, spec §5 (b/d)) ══════════
    # A cell-fired `appendToParent` route `{ from="home-manager"; to="nixos"; at=[home-manager users tux] }`
    # targets the containment PARENT (the host), NOT the firing cell. The HOST projecting `nixos` gathers it
    # from its DESCENDANT cell (`parentTargetedRoutesAt`): the cell's `home-manager` slice remaps to `nixos`
    # at `[ home-manager users tux ]`. The stub graph: host (children={cell}) + cell (parent=host, carrying an
    # own hm slice `hm-tux` and the appendToParent delivery). `deliveryTargetRootOf cell d` = cell.parent =
    # host, so the host gathers it; the source is `reach cell` (the cell's OWN subtree).
    test-route-hm-user-detect-descendant-at-host = {
      expr =
        let
          graph = {
            host = {
              node.parent = null;
              children.cell = { };
              reach = [ (mkNode "host-own" { nixos.tag = "nixos-host"; }) ]; # host's OWN nixos.
            };
            cell = {
              node.parent = "host";
              reach = [ (mkNode "acct" { home-manager.tag = "hm-tux"; }) ]; # the cell's OWN hm content.
              routes = [
                (deliveryAct {
                  from = "home-manager";
                  to = "nixos";
                  at = [
                    "home-manager"
                    "users"
                    "tux"
                  ];
                  appendToParent = true; # targets the parent (host), gathered by parentTargetedRoutesAt.
                })
              ];
            };
          };
          # Cross the host's nixos projection through a real terminal and OBSERVE the resolved config: the
          # parent-targeted remap lands the cell's hm content at `home-manager.users.tux`, and the host's own
          # nixos slice (`tag = "nixos-host"`) survives — both read off the crossed `.config`.
          crossed = crossFreeform (projectClassOf graph "host" "nixos");
        in
        {
          users = builtins.attrNames (crossed.home-manager.users or { }); # the cell remapped at users.tux.
          tags = [ (crossed.home-manager.users.tux.tag or "<missing>") ]; # carrying the cell's OWN hm-tux.
          hostOwnPresent = (crossed.tag or null) == "nixos-host"; # base host nixos untouched (additive).
        };
      expected = {
        users = [ "tux" ];
        tags = [ "hm-tux" ];
        hostOwnPresent = true;
      };
    };

    # (5b) IDENTITY — a host with NO hm cells (no descendant appendToParent delivery) ⇒ no
    #      home-manager.users.* injection (the parent-targeted remap is `++ [ ]`).
    test-route-hm-user-detect-no-cell-identity = {
      expr =
        let
          graph.host = {
            node.parent = null;
            children = { }; # NO descendant cells.
            reach = [ (mkNode "host-own" { nixos.tag = "nixos-host"; }) ];
          };
          hostNixos = projectClassOf graph "host" "nixos";
          hmUsers = builtins.concatMap (
            m:
            if builtins.isAttrs m && m ? home-manager then
              builtins.attrNames (m.home-manager.users or { })
            else
              [ ]
          ) hostNixos;
        in
        {
          hmUsers = hmUsers; # no injection.
          hostOwn = builtins.concatMap tags hostNixos; # only the host's own nixos.
        };
      expected = {
        hmUsers = [ ];
        hostOwn = [ "nixos-host" ];
      };
    };

    # ══ DELIVERY-ORDER GOLDEN (risk register #7) — routeRemapFor own-scope-then-parent-targeted ══════════
    # `routeRemapFor id class` composes its two legs in a FIXED module-list order: (1) OWN-scope routes fired
    # at `id` (`routesAt id`), THEN (2) descendant-driven PARENT-TARGETED routes (`parentTargetedRoutesAt id`)
    # — so `projectClass` lays the base own reach slice, then the own-scope remap, then the parent-targeted
    # remap. That module-list order is ORDER-INVARIANT under the arg-threading rewrite (each remapped slice is
    # reshaped in place, never repositioned — confirmed empirically + structurally). This witness observes it
    # THROUGH a real terminal: all three legs contribute to ONE shared `listOf` option `orderLog`, and the
    # crossing's merge yields `[ "parent-hm" "ownscope-hl" "base-nixos" ]` — the terminal's `listOf`
    # ACCUMULATION order, which runs REVERSE of the module-list order (a stable property of the merge, not the
    # composition). The load-bearing fact is that this crossed order is IDENTICAL before/after the rewrite.
    test-golden-delivery-order-own-scope-before-parent-targeted = {
      expr =
        let
          graph = {
            host = {
              node.parent = null;
              children.cell = { };
              reach = [
                (mkNode "host-own" { nixos.orderLog = [ "base-nixos" ]; }) # base own nixos (folded first)
                (mkNode "host-hl" { homeLinux.orderLog = [ "ownscope-hl" ]; }) # remapped by the own-scope route
              ];
              routes = [
                (deliveryAct {
                  from = "homeLinux";
                  to = "nixos";
                  at = [ ]; # own-scope: flat-merge the host's own homeLinux slice into nixos.orderLog
                })
              ];
            };
            cell = {
              node.parent = "host";
              reach = [ (mkNode "cell-acct" { home-manager.orderLog = [ "parent-hm" ]; }) ];
              routes = [
                (deliveryAct {
                  from = "home-manager";
                  to = "nixos";
                  at = [ ];
                  appendToParent = true; # parent-targeted: gathered by the host, folded AFTER own-scope
                })
              ];
            };
          };
        in
        crossOrderLog (projectClassOf graph "host" "nixos");
      # the terminal's `listOf` accumulation order (reverse of the base→own-scope→parent-targeted module-list
      # order) — identical before/after the arg-threading rewrite, so the composition order is preserved.
      expected = [
        "parent-hm"
        "ownscope-hl"
        "base-nixos"
      ];
    };

    # ══ (6) #15 devshell adaptArgs — the ARG-ENV crossing hook (Task 3, spec §5 (c) — the HARD bucket) ════
    # A route `{ from="devshell"; to="flake-parts"; at=[devshells default]; adaptArgs={...}: {pkgs2=...} }`.
    # projectClass (Task 1) places the devshell slice at `devshells.default` (content half); the arg-env
    # wrapper rides that placed module so at the TERMINAL evalModules crossing the slice evaluates WITH the
    # adaptArgs-injected arg, injected INTO the `devshells.default` nested submodule eval (v1 nestWithAdaptArgs).
    # The slice module `{ pkgs2, ... }: config.marker = pkgs2` STRICTLY reads `pkgs2` — an arg ONLY the
    # adaptArgs `_module.args` provides. A resolved `marker = "injected-pkgs"` crossing a REAL evalModules is
    # the load-bearing teeth: the injection reached the `devshells.default` NESTED submodule eval. (The
    # module system does NOT honor a formal default under `submoduleWith`, so the strict read is genuinely
    # unsatisfiable WITHOUT the hook — the fails-without is proven STRUCTURALLY in 6b: no hook ⇒ no
    # `_module.args` injection path exists on the placed module at all.)
    test-route-devshell-adaptArgs-injects-at-crossing = {
      expr =
        let
          graph.scope = {
            reach = [
              (mkNode "d" {
                devshell =
                  { pkgs2, ... }:
                  {
                    config.marker = pkgs2; # STRICTLY reads the adaptArgs-injected arg (allModuleArgs-shaped).
                  };
              })
            ];
            routes = [
              (deliveryAct {
                from = "devshell";
                to = "flake-parts";
                at = [
                  "devshells"
                  "default"
                ];
                adaptArgs = _args: { pkgs2 = "injected-pkgs"; }; # the #15 allModuleArgs-shaped injection.
              })
            ];
          };
        in
        crossFlakeParts (projectClassOf graph "scope" "flake-parts");
      expected = "injected-pkgs"; # the slice resolved WITH the injected arg at the crossing.
    };

    # (6b) THE TEETH (fails-without) — the arg-env injection is present IFF the route carries adaptArgs,
    #      proven observationally at the crossing. A NON-STRICT slice reads `args.pkgs2 or "no-injection"`:
    #      WITH adaptArgs the route injects `pkgs2 = "injected-pkgs"` into the placed slice's nested eval →
    #      the crossing resolves "injected-pkgs"; WITHOUT adaptArgs `pkgs2` is absent from the threaded args →
    #      "no-injection". Both cross the SAME real `flake-parts` terminal, so the contrast is the
    #      injection-iff-adaptArgs behavior (not the placed module's internal shape — which is now a top-level
    #      function either way).
    test-route-adaptArgs-injection-present-iff-adaptArgs = {
      expr =
        let
          slice = mkNode "d" {
            devshell = args: {
              config.marker = args.pkgs2 or "no-injection";
            };
          };
          mkGraph = adaptArgs: {
            scope = {
              reach = [ slice ];
              routes = [
                (deliveryAct (
                  {
                    from = "devshell";
                    to = "flake-parts";
                    at = [
                      "devshells"
                      "default"
                    ];
                  }
                  // (if adaptArgs == null then { } else { inherit adaptArgs; })
                ))
              ];
            };
          };
          markerOf = adaptArgs: crossFlakeParts (projectClassOf (mkGraph adaptArgs) "scope" "flake-parts");
        in
        {
          withAdaptArgs = markerOf (_args: {
            pkgs2 = "injected-pkgs";
          });
          withoutAdaptArgs = markerOf null;
        };
      expected = {
        withAdaptArgs = "injected-pkgs";
        withoutAdaptArgs = "no-injection";
      };
    };

    # (6c) NO-adaptArgs IDENTITY — a plain content route's placed slice is a PLAIN module (attrset), NOT a
    #      function-wrapper: non-adaptArgs content evals verbatim (byte-identical to Tasks 1/2, no arg-env
    #      contamination). The homeLinux→home-manager route (Task 1) places a plain module.
    test-route-no-adaptArgs-placed-slice-is-plain = {
      expr =
        let
          graph.scope = {
            reach = [ (mkNode "a" { homeLinux.tag = "linux-a"; }) ];
            routes = [
              (deliveryAct {
                from = "homeLinux";
                to = "home-manager";
              })
            ]; # NO adaptArgs.
          };
          hm = projectClassOf graph "scope" "home-manager";
        in
        {
          isFunction = builtins.isFunction (builtins.head hm); # MUST be false — a plain module.
          tags = builtins.concatMap tags hm; # the content is verbatim.
        };
      expected = {
        isFunction = false;
        tags = [ "linux-a" ];
      };
    };

    # (6d) THE RECURSION WITNESS — an EVAL-TIME guard (`{options,...}`, a MODULE formal) gates content AT THE
    #      CROSSING WITHOUT infinite recursion. This is the EXACT case that recursed under the old import-gate
    #      (`imports = optional (guard args) placed` cycles: imports ← guard(options) ← options ← imports).
    #      The CONFIG-GATE-via-nested-eval (owner ruling 2026-07-14) breaks the cycle: the wrapper declares NO
    #      options + imports NOTHING conditionally (outer `options` guard-independent), nested-evals the opaque
    #      slice, and `mkIf (guard args)` gates its config. guard-TRUE (`options ? marker`, exists) ⇒ the slice
    #      content; guard-FALSE (`options ? nonesuch`, missing) ⇒ gated out → the option default. NO adaptArgs.
    test-route-evaltime-guard-config-gate-no-recursion = {
      expr =
        let
          mkGraph = present: {
            scope = {
              reach = [ (mkNode "d" { devshell.marker = "slice-content"; }) ]; # plain content slice.
              routes = [
                (deliveryAct {
                  from = "devshell";
                  to = "flake-parts";
                  at = [
                    "devshells"
                    "default"
                  ];
                  # EVAL-TIME guard: reads `options` (a module binding absent from enriched-context).
                  guard = { options, ... }: options ? ${if present then "marker" else "nonesuch"};
                })
              ];
            };
          };
          markerWith = present: crossFlakeParts (projectClassOf (mkGraph present) "scope" "flake-parts");
        in
        {
          guardTrue = markerWith true; # options ? marker (exists) ⇒ content gated IN at the crossing.
          guardFalse = markerWith false; # options ? nonesuch (missing) ⇒ mkIf false ⇒ default (no recursion).
        };
      expected = {
        guardTrue = "slice-content";
        guardFalse = "none";
      };
    };

    # (6e) EVAL-TIME guard WITHOUT adaptArgs is STILL wrapped + config-gated — the case the retired adaptArgs-
    #      proxy COULDN'T express (functionArgs decouples guard-phase from adaptArgs). The placed module is a
    #      FUNCTION (the config-gate wrapper) even with NO adaptArgs; it declares NO options and its config is
    #      the nested slice's config under `mkIf`.
    test-route-evaltime-guard-without-adaptArgs-wraps = {
      expr =
        let
          graph.scope = {
            reach = [ (mkNode "d" { devshell.marker = "plain"; }) ];
            routes = [
              (deliveryAct {
                from = "devshell";
                to = "flake-parts";
                at = [
                  "devshells"
                  "default"
                ];
                guard = { options, ... }: options ? marker; # eval-time, NO adaptArgs.
              })
            ];
          };
          placed = (builtins.head (projectClassOf graph "scope" "flake-parts")).devshells.default;
        in
        {
          isFunction = builtins.isFunction placed; # WRAPPED despite no adaptArgs (eval-time guard).
          marker = crossFlakeParts (projectClassOf graph "scope" "flake-parts"); # guard TRUE ⇒ content.
        };
      expected = {
        isFunction = true;
        marker = "plain";
      };
    };

    # (6f) adaptArgs + EVAL-TIME guard — BOTH apply: the config-gate wraps AND the adaptArgs injection rides
    #      the nested `_module.args`, so a guard-gated slice reads the injected arg. guard-TRUE ⇒ the slice's
    #      injected marker; guard-FALSE ⇒ gated out → default.
    test-route-adaptArgs-plus-evaltime-guard = {
      expr =
        let
          mkGraph = present: {
            scope = {
              reach = [
                (mkNode "d" {
                  devshell =
                    { pkgs2, ... }:
                    {
                      marker = pkgs2; # reads the adaptArgs-injected arg (freeform-absorbed).
                    };
                })
              ];
              routes = [
                (deliveryAct {
                  from = "devshell";
                  to = "flake-parts";
                  at = [
                    "devshells"
                    "default"
                  ];
                  adaptArgs = _args: { pkgs2 = "injected-pkgs"; };
                  guard = { options, ... }: options ? ${if present then "marker" else "nonesuch"};
                })
              ];
            };
          };
          markerWith = present: crossFlakeParts (projectClassOf (mkGraph present) "scope" "flake-parts");
        in
        {
          guardTrue = markerWith true; # guard TRUE ⇒ adaptArgs injection resolves in the gated content.
          guardFalse = markerWith false; # guard FALSE ⇒ gated out → default.
        };
      expected = {
        guardTrue = "injected-pkgs";
        guardFalse = "none";
      };
    };

    # (6g) CONTENT-TIME guard (`{host,...}`, an ENTITY formal) gates at PROJECTION, decoupled from adaptArgs.
    #      functionArgs classifies it CONTENT-TIME (host ∈ enriched-context) ⇒ gated by guardHolds BEFORE the
    #      crossing: guard-FALSE ⇒ the WHOLE remap dropped (0 modules, never reaches the crossing); guard-TRUE
    #      ⇒ present (1 module) AND still adaptArgs-wrapped for the crossing. Proves the two concerns decouple.
    test-route-contenttime-guard-gates-at-projection = {
      expr =
        let
          mkGraph = system: {
            scope = {
              ctx.host.system = system; # the enriched-context entity binding the guard reads.
              reach = [
                (mkNode "d" {
                  devshell =
                    { pkgs2, ... }:
                    {
                      config.marker = pkgs2;
                    };
                })
              ];
              routes = [
                (deliveryAct {
                  from = "devshell";
                  to = "flake-parts";
                  at = [
                    "devshells"
                    "default"
                  ];
                  adaptArgs = _args: { pkgs2 = "injected-pkgs"; };
                  guard = { host, ... }: host.system == "x86_64-linux"; # content-time (reads host entity).
                })
              ];
            };
          };
          lenOf = system: builtins.length (projectClassOf (mkGraph system) "scope" "flake-parts");
        in
        {
          matchLen = lenOf "x86_64-linux"; # projection guard PASSES ⇒ remap present.
          matchMarker = crossFlakeParts (projectClassOf (mkGraph "x86_64-linux") "scope" "flake-parts");
          noMatchLen = lenOf "aarch64-darwin"; # projection guard FAILS ⇒ WHOLE remap dropped (0).
        };
      expected = {
        matchLen = 1;
        matchMarker = "injected-pkgs";
        noMatchLen = 0;
      };
    };

    # ══ (7) SYNTHESIZE content producer — the interpret/synthesize re-express (Task 4, spec §5 (c)) ═══════
    # A COMPLEX (adapter-bearing) forward re-expressed as a projection CONTENT PRODUCER: `synthesizeProducer
    # spec` COMPOSES a NEW `intoClass` module (adapter + mapModule(sourceModule) + freeform) — DISTINCT from
    # #15's arg-rewrite-on-EXISTING-content. The composed module is a target-class slice; when it carries
    # `adaptArgs` it is the SAME function-module the Task-3 arg-env crossing produces, so it crosses the
    # terminal evalModules boundary identically (the arg-rewrite applies at the crossing). Zero corpus
    # consumers ⇒ fleet-INERT (7b); this synthetic witness is NON-VACUOUS (the produced module carries real
    # content AND reads an adaptArgs-injected arg, resolved at a REAL evalModules crossing).
    test-synthesize-producer-yields-module-at-target = {
      expr =
        let
          fwd = denCompat.legacy.forwards;
          # a synthesize spec: mapModule TRANSFORMS the source into a NEW module reading an injected arg;
          # adaptArgs injects `injected` (the content-PRODUCER shape — composes a new module, not a rewrite).
          spec = {
            fromClass = "devshell";
            intoClass = "flake-parts";
            sourceModule = {
              tag = "src-seed";
            }; # the source the adapter maps.
            mapModule =
              src:
              (
                { injected, ... }:
                {
                  marker = injected; # the composed module READS the adaptArgs-injected arg (freeform-absorbed).
                  seed = src.tag; # …and carries the mapped source content (non-vacuous).
                }
              );
            adaptArgs = _args: { injected = "synth-injected"; }; # the content-producer arg-env.
          };
          produced = fwd.synthesizeProducer spec;
          # cross via gen-merge's module system (`merge.evalModuleTree`) — den-hoag's OWN module evaluator,
          # the one the inert `flake-parts` collect terminal uses (the composed module carries den-hoag's
          # `freeformMod`, a gen-merge type, so it crosses HERE, not raw nixpkgs lib.evalModules). The
          # produced function-module fires `_module.args = adaptArgs args` at this crossing (Task-3 seam),
          # so the mapped module's `injected` read resolves and the mapped source content is present.
          ev = merge.evalModuleTree { modules = [ produced.module ]; };
        in
        {
          class = produced.class; # the target class the producer contributes to.
          marker = ev.config.marker; # the adaptArgs-injected arg, resolved at the crossing.
          seed = ev.config.seed; # the mapped source content (proves the compose ran).
          moduleIsFunction = builtins.isFunction produced.module; # the arg-env content-producer shape.
        };
      expected = {
        class = "flake-parts";
        marker = "synth-injected"; # the injection resolved at the terminal crossing.
        seed = "src-seed"; # the composed module carries the mapped source (non-vacuous).
        moduleIsFunction = true;
      };
    };

    # (7b) FLEET-INERT — zero corpus consumers: a NO-adapter synthesize spec composes a PLAIN module set
    #      (no adaptArgs ⇒ not a function), and the corpus emits NO synthesize forward ⇒ the producer is
    #      never invoked on a real fleet ⇒ fleet output byte-unchanged (the generality machinery is dormant).
    test-synthesize-producer-no-adapter-plain-module = {
      expr =
        let
          fwd = denCompat.legacy.forwards;
          spec = {
            fromClass = "devshell";
            intoClass = "flake-parts";
            sourceModule = {
              tag = "plain-src";
            };
            # NO adaptArgs / adapterModule / mapModule ⇒ a plain composed module set.
          };
          produced = fwd.synthesizeProducer spec;
        in
        {
          moduleIsFunction = builtins.isFunction produced.module; # plain ⇒ NOT a function.
          hasImports = produced.module ? imports; # a plain module set { imports = [...]; }.
          class = produced.class;
        };
      expected = {
        moduleIsFunction = false;
        hasImports = true;
        class = "flake-parts";
      };
    };
  };
}
