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
#   1. homeLinux→homeManager (at=[], guard true): the homeManager projection includes the reached nodes'
#      homeLinux slices (in projection order) IN ADDITION to the base homeManager slices.
#   2. guard-FALSE (wrong host.system): the route contributes NOTHING.
#   3. nested (at=[devshells default]): the remapped slice wrapped under devshells.default, NOT flat.
#   4. no route targeting C ⇒ `projectClass id C` UNCHANGED (identity — the additive base).
{
  denHoag,
  denHoagSrc,
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
  # `from = sourceClass.name`. `__action = "delivery"`, not `__dropped`.
  deliveryAct =
    {
      from,
      to,
      at ? [ ],
      guard ? null,
    }:
    {
      __action = "delivery";
      sourceClass = { name = from; };
      targetClass = { name = to; };
      module = null;
      path = at;
      mode = "merge";
      inherit guard;
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

  projectClassOf = graph: id: class: (mkOut graph).projectClass id class;

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
            routes = [ (deliveryAct { from = "homeLinux"; to = "home-manager"; }) ];
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

    # ══ (2) GUARD-FALSE — a wrong-host.system guard contributes NOTHING ═════════════════════════════════
    # The route's guard is a closure over the scope bindings (home-platform guards on host.system suffix).
    # A guard returning false gates the WHOLE remap out — the home-manager projection is the base only.
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

    # ══ (3) NESTED PLACEMENT — at=[devshells default] wraps the slice, NOT flat (nest-via-content-module) ═
    # A route with a non-empty path places the remapped slice UNDER the path (`{ devshells.default = <slice
    # module>; }`), the fold's nest edge shape. The base flake-parts projection is unchanged; the remapped
    # devshell slice appears nested, so a naive flat `tags` walk still reaches it (through the wrapper attr)
    # but the STRUCTURE carries the `devshells.default` path.
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
          remap = projectClassOf graph "scope" "flake-parts";
          # the remapped module is wrapped: `{ devshells.default = <the devshell slice module>; }`.
          wrapped = builtins.head remap;
        in
        {
          count = builtins.length remap; # exactly the one remapped (nested) module.
          # the wrapper carries the `devshells.default` path (NOT flat — a flat remap would have `.imports`
          # / `.tag` at the top level, never a `devshells` key).
          nestedUnderDevshellsDefault = wrapped ? devshells && wrapped.devshells ? default;
          nested-tag = tags wrapped.devshells.default; # the slice content sits under the path.
          notFlat = !(wrapped ? tag || wrapped ? imports); # top level is the wrapper, not the slice.
        };
      expected = {
        count = 1;
        nestedUnderDevshellsDefault = true;
        nested-tag = [ "shell-slice" ];
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
          withNoRoute = builtins.concatMap tags (projectClassOf { scope = { inherit reach; }; } "scope" "home-manager");
          # base-only reference: the same reach with the route machinery present but targeting ANOTHER class.
          otherClassRoute = builtins.concatMap tags (projectClassOf {
            scope = {
              inherit reach;
              routes = [ (deliveryAct { from = "homeLinux"; to = "nixos"; }) ]; # targets nixos, NOT home-manager.
            };
          } "scope" "home-manager");
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
  };
}
