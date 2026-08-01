# den-hoag projection routes/forwards TRANSFORM layer (spec §5 (b)) — the route
# class-remap in `projectClass`.
#
# A ROUTE is a class→class CONTENT transform on the projected view (NOT a reachability edge). A route
# `{ from=D; to=C; at=<path>; guard }` lowered at the projecting scope ADDS, to `projectClass id C`, the
# guard-gated remap of each REACHED node's class-D slice, placed at `at`. The emission model is deleted
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
#
# ── THE TRANSFORM LAYERS UNDER RELOCATION AND INJECTION (spec §14.6/§14.7) ────────────────────────────────
# The witnesses above hold the relocation relation EMPTY, so they measure what the fold does to a route's
# content and never which COORDINATE it reads that content at, or from. Two later groups close that:
#   5. ROUTES AND FORWARDS CARRY INJECTIONS (§4.5a). An `inject` declares content at a scope, so it travels
#      `reach`'s structural payload and both transform layers see it. These rows run on a SECOND instrument
#      (`projectReachOf`) whose `reach` is the kernel's own, because a hand-placed injection element would
#      let the fixture supply the very payload the row is meant to measure.
#   6. THE DESTINATION COORDINATE UNDER RELOCATION (§4.5b). A route's `to` and a forward's `intoClass` name
#      coordinates AT THE PROJECTING SCOPE, read through that scope's relocation. The outgoing arm and its
#      `systems` consequence are native rows in `ci/tests/projection.nix`; the incoming arm and the
#      forward/projecting-scope split are here, where the stub expresses both cleanly.
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
    select
    classShare
    ;
  errors = import "${denHoagSrc}/lib/errors.nix";
  # the §4.2 mode-execution engine — the fold reads its `placeSlice` graft law, so the real engine is
  # instantiated here (same `prelude`/`edge` the assembly threads) rather than stubbed.
  nest = import "${denHoagSrc}/lib/nest.nix" { inherit prelude edge; };

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
    aspectSchema
    ;

  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, built with the extended
  # `classifyKey` — the same functions the assembly threads to `projectClass`. `keyCategory` comes from
  # the SAME instance, so the builder's two classification authorities answer about one class vocabulary:
  # taking it from anywhere else would have this `cm` classify `homeLinux` as a declared class by one
  # function and as an unregistered name by the other.
  cm =
    import "${denHoagSrc}/lib/attributes/class-modules.nix"
      {
        inherit prelude resolve;
        graph = denHoag.internal.genGraph;
      }
      {
        classNames = [ ];
        inherit classifyKey;
        inherit (aspectSchema) keyCategory;
      };
  # `sourceOrderOf` rides along because `mkOutputModules` now reads its ROUTE DESTINATIONS through it: a
  # route's `to` is a coordinate at the target root, relabelled by that root's own relocation exactly as the
  # element arm's sources are. It is a REQUIRED formal there, so this instrument supplies the real query
  # rather than letting a default answer as though no relocation existed.
  inherit (cm) classSliceAt sourceOrderOf assertKeysRegistered;

  # A synthetic content element `{ key; content; scope; assertedClasses }` (the reach node shape
  # `classSliceAt` reads). `scope` and `assertedClasses` are STAMPED because a content element is produced
  # COMPLETE — the extraction projects both fields with a named throw rather than reconstructing either from
  # where the element was read. `scope` is the id these fixtures resolve their relocation memo at, and it is
  # LOAD-BEARING rather than decorative: a scope that declares no `reroute` resolves the empty relation and
  # the element's content rests where it was authored, while a scope that declares one governs that element's
  # content wherever it is projected. `assertedClasses = { }` is the POSITIVE statement "this element asserts
  # nothing", the value every produced aspect element carries — so the fixtures stay semantically identical
  # to what the assembly feeds the extraction.
  # `mkNodeAt` carries the scope EXPLICITLY, because the destination rows turn on WHICH scope's relocation
  # governs a coordinate: a forward spec rides an aspect at a reached node while its placement lands at the
  # projecting scope, so telling the two apart needs a fixture that can put an element at a scope other than
  # the projecting one. `mkNode` is that function at the synthetic sentinel — the value every pre-existing
  # row in this file used, so those rows are byte-identical.
  mkNodeAt = sc: key: content: {
    inherit key content;
    scope = sc;
    assertedClasses = { };
  };
  mkNode = mkNodeAt syntheticScope;
  syntheticScope = "<synthetic>";

  # A `delivery` resolution action (the shape `translateDelivery`/`deliveriesAt` produce/read): a
  # class→class route carries `sourceClass`/`targetClass` entries (`{ name; }`), a `path`, `mode`, and a
  # `guard` closure (or null). `module = null` ⇒ a CLASS source (route case) — `routesAt` reads
  # `from = sourceClass.name`. `appendToParent` (default false) ⇒ the route targets the containment PARENT
  # root (the #10 hm-user-detect forward — gathered by the host via `parentTargetedRoutesAt`).
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

  # The two other RESOLUTION acts a scope's declaration list can carry — the same list `deliveryAct` lands
  # in, because `class-relocation` and `routesAt` read one `actions.resolution` stratum and differ only in
  # the `__action` they filter on. Written as literals for the same reason `deliveryAct` is: these fixtures
  # assert over what the KERNEL does with a declaration, so the declaration itself is data the fixture
  # states, not a value routed through the public constructor (which the native suites exercise).
  rerouteAct = from: to: {
    __action = "reroute";
    inherit from to;
  };
  injectAct = class: module: {
    __action = "inject";
    inherit class module;
  };

  # A STUB `result` for `mkOutputModules`: `reach id` = the reached node list, `declarations` = the route
  # (delivery) actions, `enriched-context` = the guard's scope bindings, `node`/`children` inert. `allNodes`
  # keys the systems spine (unforced by projectClass). Each id in `graph` carries `{ reach; routes ? [];
  # ctx ? {}; node ? {} }`.
  mkResult =
    graph:
    let
      result = {
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
          # ── THE PER-SCOPE RELOCATION MEMO the extraction reads a channel's source order through. Served by
          # driving the KERNEL's own equation over this same stub, so the instrument supplies DATA (the
          # declarations at a scope) and never a second copy of the relocation algorithm — the `mkSelf`
          # shape `ci/tests/class-relocation.nix` already uses for `"content-key-totality"`. Omitting it
          # would not silently pin the un-relocated semantics: `sourceOrderOf` aborts NAMING the scope.
          else if attr == "class-relocation" then
            cm.class-relocation.compute result id
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
    in
    result;

  # Instantiate the REAL `mkOutputModules` over a stub `result` and pull out `projectClass` (the code path
  # under test). classesByName/classOfNode/channelNames are inert for projectClass (it reads only reach +
  # declarations + enriched-context + the relocation memo); `classSliceAt`/`sourceOrderOf`/
  # `assertKeysRegistered` are the real extraction.
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
          nest
          ;
      }
      {
        result = mkResult graph;
        classesByName = { };
        classOfNode = _: null;
        channelNames = [ ];
        inherit classSliceAt sourceOrderOf assertKeysRegistered;
      };

  projectClassOf =
    graph: id: class:
    (mkOut graph).projectClass id class;

  # ── THE SECOND INSTRUMENT: a stub whose `reach` IS THE KERNEL'S OWN REACH ─────────────────────────────
  # `mkResult` above serves `reach` as a hand-written node list, which is the right instrument for the route
  # TRANSFORM rows — they assert what the fold does GIVEN a reach. It is the wrong instrument for the
  # injection rows, and the difference is the whole of what those rows test: an injection reaches a route
  # because `reach`'s STRUCTURAL arm carries the scope's injection elements beside its resolved aspects. A
  # fixture that hand-placed the injection element into the reach list would assert the fold over a payload
  # the fixture itself supplied, and would stay green with that payload deleted from the kernel.
  # So this variant drives the REAL `reach.compute` (the `mkRa` shape `ci/tests/_lib/projection-harness.nix`
  # already uses) over the same stub, and the fixture supplies only DECLARATIONS. `resolved-aspects` moves to
  # its own `aspects` field, because `reach` is now the computed answer rather than the field.
  # ADDITIVE: no pre-existing row reads it, so every fixture above is byte-identical.
  mkRa =
    import "${denHoagSrc}/lib/attributes/resolved-aspects.nix"
      {
        inherit
          prelude
          scope
          aspects
          select
          resolve
          errors
          ;
        graph = denHoag.internal.genGraph;
      }
      {
        # These fixtures author no containment pool; stated rather than defaulted in the kernel, the same
        # choice the projection harness makes for the same reason.
        containAncestorIds = _nid: [ ];
      };
  mkResultReach =
    graph:
    let
      result = {
        allNodes = builtins.mapAttrs (_: _: { }) graph;
        get =
          id: attr:
          let
            g = graph.${id} or { };
          in
          if attr == "reach" then
            mkRa.reach.compute result id
          else if attr == "declarations" then
            { actions.resolution = g.routes or [ ]; }
          else if attr == "class-relocation" then
            cm.class-relocation.compute result id
          else if attr == "enriched-context" then
            g.ctx or { }
          else if attr == "children" then
            g.children or { }
          else if attr == "resolved-aspects" then
            g.aspects or [ ]
          else if attr == "received-collections" then
            { }
          else if attr == "resolved-settings" then
            { }
          else
            throw "projection-routes stub: unexpected attr ${attr}";
        node = id: (graph.${id} or { }).node or { parent = null; };
      };
    in
    result;
  mkOutReach =
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
          nest
          ;
      }
      {
        result = mkResultReach graph;
        classesByName = { };
        classOfNode = _: null;
        channelNames = [ ];
        inherit classSliceAt sourceOrderOf assertKeysRegistered;
      };
  projectReachOf =
    graph: id: class:
    (mkOutReach graph).projectClass id class;

  # every `tag` string reachable in a wrapped deferredModule (gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];

  # nixpkgs lib for the arg-env witnesses — the REAL evalModules crossing (the terminal), where a
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

  # ══ FIXTURES for the injection-payload rows (spec §14.6 — the §4.5a decision) ═══════════════════════════
  # One reached aspect carrying base home-manager content and a homeLinux slice, plus the corpus route
  # `homeLinux → home-manager`. The subject fleet adds ONE `inject` act at the route's `from` class; the
  # control is that fixture with the act removed and nothing else.
  injBaseAspects = [
    (mkNodeAt "scope" "a" {
      home-manager.tag = "hm-base";
      homeLinux.tag = "linux-a";
    })
  ];
  injRoute = deliveryAct {
    from = "homeLinux";
    to = "home-manager";
  };
  gRouteInject.scope = {
    aspects = injBaseAspects;
    routes = [
      injRoute
      (injectAct "homeLinux" { tag = "inj-route"; })
    ];
  };
  gRouteInjectControl.scope = {
    aspects = injBaseAspects;
    routes = [ injRoute ];
  };

  # The corpus route reading its SOURCE through a preimage: one reached element carrying content at BOTH the
  # route's `from` class and a third channel, with a `reroute` at that element's own scope moving the third
  # into `from`. The control is the same element and the same route with the `reroute` act removed, so the
  # difference between the two answers is exactly the relocated slice.
  preimageAspects = [
    (mkNodeAt "scope" "a" {
      homeLinux.tag = "linux-own";
      darwin.tag = "dar-preimage";
    })
  ];
  gRoutePreimage.scope = {
    reach = preimageAspects;
    routes = [
      injRoute
      (rerouteAct "darwin" "homeLinux")
    ];
  };
  gRoutePreimageControl.scope = {
    reach = preimageAspects;
    routes = [ injRoute ];
  };

  # A forward spec whose `fromClass` is the injected channel — no route at all, so the row reads
  # `forwardModulesFor`'s own `srcSlices` fold rather than `remapOver`'s.
  fwdSpecAspects = [
    (mkNodeAt "scope" "fa" {
      meta.__forward = {
        fromClass = "homeLinux";
        intoClass = "home-manager";
        intoPath = [ "placed" ];
        guard = null;
        adaptArgs = null;
        item = null;
      };
    })
  ];
  gForwardInject.scope = {
    aspects = fwdSpecAspects;
    routes = [ (injectAct "homeLinux" { tag = "inj-fwd"; }) ];
  };
  gForwardInjectControl.scope = {
    aspects = fwdSpecAspects;
    routes = [ ];
  };

  # The module an `inject` act carries, shaped so it WOULD declare a forward if it were an aspect's content.
  forwardCarrier = {
    tag = "inj-carrier";
    meta.__forward = {
      fromClass = "home-manager";
      intoClass = "nixos";
      intoPath = [ "leaked" ];
      guard = null;
      adaptArgs = null;
      item = null;
    };
  };
  gInjectCarrier.scope = {
    aspects = [ (mkNodeAt "scope" "a" { home-manager.tag = "hm-base"; }) ];
    routes = [ (injectAct "homeLinux" forwardCarrier) ];
  };
  # the SAME shape as an ASPECT's content — the non-vacuity twin (an aspect at that shape DOES forward).
  gAspectCarrier.scope = {
    aspects = [
      (mkNodeAt "scope" "a" { home-manager.tag = "hm-base"; })
      (mkNodeAt "scope" "carrier" (forwardCarrier // { name = "carrier"; }))
    ];
    routes = [ ];
  };

  # ── the parent-targeted (`appendToParent` + `adaptArgs` + non-empty `at`) route, whose ensure-target-path
  #    seed fires exactly when the whole-route contribution is empty. Four fixtures put content into and out
  #    of that gate by ONE declaration each.
  seedRoute = deliveryAct {
    from = "home-manager";
    to = "nixos";
    at = [
      "home-manager"
      "users"
      "tux"
    ];
    appendToParent = true;
    adaptArgs = _: { };
  };
  seedHost = {
    node.parent = null;
    children.cell = { };
    aspects = [ (mkNodeAt "host" "host-own" { nixos.tag = "nixos-host"; }) ];
  };
  mkSeedFleet = cellAspects: cellActs: {
    host = seedHost;
    cell = {
      node.parent = "host";
      aspects = cellAspects;
      routes = [ seedRoute ] ++ cellActs;
    };
  };
  hmCellAspects = [ (mkNodeAt "cell" "acct" { home-manager.tag = "hm-tux"; }) ];
  hlCellAspects = [ (mkNodeAt "cell" "acct" { homeLinux.tag = "hl-tux"; }) ];
  gSeedInjectOnly = mkSeedFleet [ ] [ (injectAct "home-manager" { tag = "inj-cell"; }) ];
  gSeedNoContent = mkSeedFleet [ ] [ ];
  gSeedOutgoing = mkSeedFleet hmCellAspects [ (rerouteAct "home-manager" "darwin") ];
  gSeedOutgoingControl = mkSeedFleet hmCellAspects [ ];
  gSeedIncoming = mkSeedFleet hlCellAspects [ (rerouteAct "homeLinux" "home-manager") ];
  gSeedIncomingControl = mkSeedFleet hlCellAspects [ ];

  # ══ FIXTURES for the destination rows (spec §14.7 — the §4.5b ruling) ═══════════════════════════════════
  # The route's SOURCE side is held fixed (two reached nodes carrying only `homeLinux`) so every answer below
  # moves for exactly one reason: which coordinate the route's DESTINATION resolves to.
  destReach = [
    (mkNode "a" { homeLinux.tag = "linux-a"; })
    (mkNode "b" { homeLinux.tag = "linux-b"; })
  ];
  destRouteToDarwin = deliveryAct {
    from = "homeLinux";
    to = "darwin";
  };
  gDestIncoming.scope = {
    reach = destReach;
    routes = [
      destRouteToDarwin
      (rerouteAct "darwin" "home-manager")
    ];
  };
  gDestIncomingControl.scope = {
    reach = destReach;
    routes = [ destRouteToDarwin ];
  };

  # A forward spec authored at a DESCENDANT scope (`desc`) while its placement lands at the projecting scope
  # — the pair of fixtures that tells the two scopes apart, which is the whole content of §4.7 row 17.
  destFwdNodes = [
    (mkNodeAt "desc" "fa" {
      homeLinux.tag = "fwd-src";
      meta.__forward = {
        fromClass = "homeLinux";
        intoClass = "home-manager";
        intoPath = [ "placed" ];
        guard = null;
        adaptArgs = null;
        item = null;
      };
    })
  ];
  gFwdDestAtProjecting.scope = {
    reach = destFwdNodes;
    routes = [ (rerouteAct "home-manager" "nixos") ];
  };
  gFwdDestAtDescendant = {
    scope.reach = destFwdNodes;
    desc.routes = [ (rerouteAct "home-manager" "nixos") ];
  };

  # ── the PARENT-TARGETED destination, and it is a third fixture rather than a variant of the two above.
  # A route's destination is matched against the projecting scope's relocation at BOTH gathering arms: the
  # own-scope routes fired at the scope, and the descendant-fired `appendToParent` ones the scope gathers.
  # Every parent-targeted fixture in this suite declares its `to` at a host with no relocation on that
  # channel, where matching through the relocation and matching literally agree — so the second arm's
  # destination read has no fixture that can tell the two apart. This one moves the destination: the cell
  # fires the route, the HOST reroutes the route's `to` away, and the two answers separate.
  ptRouteToNixos = deliveryAct {
    from = "home-manager";
    to = "nixos";
    at = [
      "home-manager"
      "users"
      "tux"
    ];
    appendToParent = true;
  };
  mkPtDestFleet = hostActs: {
    host = {
      node.parent = null;
      children.cell = { };
      reach = [ (mkNodeAt "host" "host-own" { nixos.tag = "nixos-host"; }) ];
      routes = hostActs;
    };
    cell = {
      node.parent = "host";
      reach = [ (mkNodeAt "cell" "acct" { home-manager.tag = "hm-tux"; }) ];
      routes = [ ptRouteToNixos ];
    };
  };
  gPtDestRelocated = mkPtDestFleet [ (rerouteAct "nixos" "darwin") ];
  gPtDestControl = mkPtDestFleet [ ];
in
{
  flake.tests.projection-routes = {
    # ══ (1) THE CONTENT REMAP — homeLinux → homeManager, at=[], guard true (bucket b, #14) ══════════════
    # A route `{ from="homeLinux"; to="home-manager"; at=[] }` fired at the projecting scope: for each
    # reached node, its `homeLinux` slice is remapped INTO the `home-manager` projection (flat, at=[]), in
    # projection order, IN ADDITION to the base `home-manager` slices. This fills the LOCALE_ARCHIVE hole
    # deleted with the emission model — the exact content the u24/u25 β fight delivered.
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

    # ══ (5) #10 hm-user-detect — DESCENDANT-DRIVEN parent-targeted route (spec §5 (b/d)) ══════════════════
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

    # ══ (6) #15 devshell adaptArgs — the ARG-ENV crossing hook (spec §5 (c) — the HARD bucket) ════════════
    # A route `{ from="devshell"; to="flake-parts"; at=[devshells default]; adaptArgs={...}: {pkgs2=...} }`.
    # projectClass places the devshell slice at `devshells.default` (content half); the arg-env
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
    #      function-wrapper: non-adaptArgs content evals verbatim (byte-identical to the base projection, no arg-env
    #      contamination). The homeLinux→home-manager route places a plain module.
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

    # ══ (7) SYNTHESIZE content producer — the interpret/synthesize re-express (spec §5 (c)) ═══════════════
    # A COMPLEX (adapter-bearing) forward re-expressed as a projection CONTENT PRODUCER: `synthesizeProducer
    # spec` COMPOSES a NEW `intoClass` module (adapter + mapModule(sourceModule) + freeform) — DISTINCT from
    # #15's arg-rewrite-on-EXISTING-content. The composed module is a target-class slice; when it carries
    # `adaptArgs` it is the SAME function-module the arg-env crossing produces, so it crosses the
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
          # produced function-module fires `_module.args = adaptArgs args` at this crossing (the arg-env seam),
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

    # ══ (8) ROUTES AND FORWARDS CARRY INJECTIONS — the §4.5a decision, armed (spec §14.6) ═════════════════
    # An `inject` act declares content AT A SCOPE exactly as an aspect's class body does, so it travels
    # `reach`'s structural payload and is therefore visible to EVERY consumer that folds over reach — the
    # element arm, the route remap, and the forward fold alike. The alternative §4.5a rejects unifies only
    # the projection, leaving the two transform layers reading a reach with no injections in it; these rows
    # are what tells the two designs apart. They run on the SECOND instrument (`projectReachOf`), whose reach
    # is the kernel's own, because a hand-placed injection element would assert the fold over a payload the
    # fixture supplied.

    # (a) A ROUTE reads the injected content at its SOURCE class. The `inject` sits at `homeLinux`, the
    #     route is `homeLinux → home-manager`, so the injected module arrives in the home-manager
    #     projection behind the route's other remapped slices (reach order: aspects, then injections).
    test-route-carries-injection-at-source-class = {
      expr = builtins.concatMap tags (projectReachOf gRouteInject "scope" "home-manager");
      expected = [
        "hm-base" # the base element arm's own home-manager slice.
        "linux-a" # the route remap of the reached aspect's homeLinux slice…
        "inj-route" # …and of the INJECTION at that same channel.
      ];
    };

    # (b) THE CONTROL, same run: the byte-identical fixture WITHOUT the `inject` act gives the route's
    #     existing answer, so (a) cannot be satisfied by a change that perturbs every route.
    test-route-injection-free-control = {
      expr = builtins.concatMap tags (projectReachOf gRouteInjectControl "scope" "home-manager");
      expected = [
        "hm-base"
        "linux-a"
      ];
    };

    # (c) A FORWARD reads the injected content at its `fromClass`. No route is declared at all, so the
    #     delivery runs through `forwardModulesFor`'s own `srcSlices` fold — the second of the two transform
    #     layers, and the one an implementation that widened only `remapOver` would leave empty.
    test-forward-carries-injection-at-fromClass = {
      expr = {
        withInjection = projectReachOf gForwardInject "scope" "home-manager";
        control = projectReachOf gForwardInjectControl "scope" "home-manager";
      };
      expected = {
        withInjection = [
          {
            placed = {
              tag = "inj-fwd";
            };
          }
        ]; # placed at the spec's `intoPath`.
        control = [ ]; # no injection ⇒ the forward has no source content.
      };
    };

    # (d) AN INJECTION DECLARES NO FORWARD — §4.7 row 13a's defined limit, and it is a claim about the
    #     ELEMENT's shape rather than about the fixture's. An admitted minted element's `content` is
    #     `{ name; <channel> = module; }`, so a `meta.__forward` written INSIDE the injected module is part
    #     of the module and never reaches the specs fold, which reads `n.content.meta`.
    #     ★ THE NON-VACUITY TWIN IS THE SECOND FIELD, and it is what makes this a checked claim rather than a
    #     restatement: the byte-identical attrset carried as an ASPECT's content DOES produce a live forward
    #     spec (it delivers the reached home-manager content at `leaked` into nixos). The two fixtures differ
    #     only in which producer minted the element, and they answer differently.
    #     ★★ THIS ROW IS HALF OF A PAIR ABOUT THE SAME NAME, and on its own it is the weaker half. It says
    #     `meta` INSIDE an injected module is inert. Its other half —
    #     `projection.test-inject-schema-claimed-channel-meta-refused` — says `meta` AS the injected CHANNEL
    #     is refused named. Only together do they state what the mint does with a claimed key: a fleet
    #     cannot reach the forward surface through an injection by either route, one because the read never
    #     looks there and one because the declaration is refused before it is built. A suite carrying this
    #     row alone would be satisfied by a mint that simply admitted `meta` as a channel.
    test-injection-declares-no-forward = {
      expr = {
        injectionForwards = projectReachOf gInjectCarrier "scope" "nixos";
        aspectForwards = projectReachOf gAspectCarrier "scope" "nixos";
      };
      expected = {
        injectionForwards = [ ]; # the injection contributed no spec…
        aspectForwards = [
          {
            leaked = {
              tag = "hm-base";
            };
          }
        ]; # …where the same shape as an aspect does.
      };
    };

    # (e) THE PARENT-TARGETED SEED IS SUPPRESSED BY AN INJECTION — §4.7 row 12a. The ensure-target-path seed
    #     fires only on a whole-route contribution of `[ ]`, so a cell whose ONLY class-`from` content is an
    #     injection must produce the REMAPPED content and no seed. Its twin — the same fixture with no
    #     content of any kind at the cell — must still produce the seed, so the row cannot be satisfied by a
    #     change that empties or fills the gate unconditionally.
    test-parent-targeted-route-seed-suppressed-by-injection = {
      expr = {
        withInjection = (crossFreeform (projectReachOf gSeedInjectOnly "host" "nixos")).home-manager.users;
        noContent = (crossFreeform (projectReachOf gSeedNoContent "host" "nixos")).home-manager.users;
      };
      expected = {
        withInjection.tux = {
          tag = "inj-cell";
        }; # the injection remapped ⇒ no seed.
        noContent.tux = { }; # nothing at the cell ⇒ the seed.
      };
    };

    # (f) THE SEED FIRES UNDER AN OUTGOING RELOCATION — §4.7 row 12b, the arm that is live in production.
    #     The cell HAS real `home-manager` content and reroutes that channel away at its own scope, so the
    #     route's contribution at `from` is empty and the seed fires. `remapOver` reading the RAW view would
    #     leave `placed` non-empty and the seed silent. Control, same run: the byte-identical fixture without
    #     the `reroute` act delivers the remapped content and no seed.
    test-parent-targeted-route-seed-fires-under-relocation = {
      expr = {
        relocated = (crossFreeform (projectReachOf gSeedOutgoing "host" "nixos")).home-manager.users;
        control = (crossFreeform (projectReachOf gSeedOutgoingControl "host" "nixos")).home-manager.users;
      };
      expected = {
        relocated.tux = { }; # content moved to `darwin` ⇒ the route is empty ⇒ the seed.
        control.tux = {
          tag = "hm-tux";
        }; # no relocation ⇒ the remap ⇒ no seed.
      };
    };

    # (g) THE SEED IS SUPPRESSED BY AN INCOMING RELOCATION — §4.7 row 12c, the same gate's other direction.
    #     The cell has NO `home-manager` content of its own but reroutes `homeLinux` INTO it, so the route's
    #     source resolves through the preimage and the relocated content is remapped instead of the seed.
    test-parent-targeted-route-seed-suppressed-by-incoming-relocation = {
      expr = {
        relocated = (crossFreeform (projectReachOf gSeedIncoming "host" "nixos")).home-manager.users;
        control = (crossFreeform (projectReachOf gSeedIncomingControl "host" "nixos")).home-manager.users;
      };
      expected = {
        relocated.tux = {
          tag = "hl-tux";
        }; # the preimage content arrives through the route.
        control.tux = { }; # no relocation ⇒ nothing at `from` ⇒ the seed.
      };
    };

    # (h) THE ROUTE READS ITS SOURCE THROUGH THE PREIMAGE — §4.7 row 7a, the third relocation cell of the
    #     same read rows (f) and (g) cover, and the one on the CORPUS route shape rather than the
    #     parent-targeted one. A reached element declares content at a third channel and reroutes it INTO
    #     the route's `from` class at its own scope, so that content must arrive through the route. Reading
    #     the raw view would see only the `from` class's own content — which is exactly what the control,
    #     the byte-identical fixture without the `reroute` act, answers.
    test-route-carries-preimage-content-under-incoming-relocation = {
      expr = {
        relocated = builtins.concatMap tags (projectClassOf gRoutePreimage "scope" "home-manager");
        control = builtins.concatMap tags (projectClassOf gRoutePreimageControl "scope" "home-manager");
      };
      expected = {
        relocated = [
          "linux-own" # the route's own `from` content, first — the rest position heads the source order…
          "dar-preimage" # …then its back-reacher, which the raw view does not see at all.
        ];
        control = [ "linux-own" ];
      };
    };

    # ══ (9) THE DESTINATION COORDINATE UNDER RELOCATION — the §4.5b ruling, armed (spec §14.7) ════════════
    # A route's `to` and a forward's `intoClass` are coordinates AT THE PROJECTING SCOPE, so they are read
    # through that scope's relocation exactly as the element arm's sources are read through each element's.
    # §14.7's outgoing row and the member row run on the NATIVE fleet in `ci/tests/projection.nix` (the
    # member half is a `systems` observation, which needs a fleet); the two rows below are the arms this
    # suite's instrument expresses better — an incoming destination, and the forward/projecting-scope split.

    # (a) AN INCOMING RELOCATION ADMITS THE PREIMAGE — §4.7 row 16a, and it is recorded as its own row
    #     because it is the direction in which the two candidate readings AGREE on the declared destination
    #     and differ only on this admission. The target root reroutes `darwin → home-manager`, and a route
    #     declaring `to = "darwin"` therefore contributes to the HOME-MANAGER projection. A suite carrying
    #     the outgoing row alone would be blind to it.
    test-route-destination-admits-preimage-under-incoming-relocation = {
      expr = {
        homeManager = builtins.concatMap tags (projectClassOf gDestIncoming "scope" "home-manager");
        darwin = builtins.concatMap tags (projectClassOf gDestIncoming "scope" "darwin");
        controlHomeManager = builtins.concatMap tags (
          projectClassOf gDestIncomingControl "scope" "home-manager"
        );
        controlDarwin = builtins.concatMap tags (projectClassOf gDestIncomingControl "scope" "darwin");
      };
      expected = {
        # the route's contribution arrives at the channel the declared destination relocates INTO…
        homeManager = [
          "linux-a"
          "linux-b"
        ];
        darwin = [ ]; # …and not at the channel it was declared at, which has an outgoing relocation.
        # CONTROL, same run: without the `reroute` act the route answers at its declared destination.
        controlHomeManager = [ ];
        controlDarwin = [
          "linux-a"
          "linux-b"
        ];
      };
    };

    # (b) A FORWARD'S DESTINATION FOLLOWS THE PROJECTING SCOPE'S RELOCATION — §4.7 row 17, and NOT a
    #     duplicate of the route row. A forward spec rides `meta.__forward` on an aspect at a REACHED node
    #     while its placement lands at the PROJECTING scope, so the question is which of the two scopes'
    #     relocations governs `intoClass`. ★ THE MIRROR FIXTURE IS THE CONTROL AND THE ROW CANNOT BE STATED
    #     WITHOUT IT: with the `reroute` at the projecting scope the destination moves, and with the SAME
    #     `reroute` at the descendant that authored the spec it must stay put. A row asserting only the first
    #     half is satisfied by an implementation reading the spec author's scope.
    test-forward-destination-follows-outgoing-relocation = {
      expr = {
        atProjectingHomeManager = projectClassOf gFwdDestAtProjecting "scope" "home-manager";
        atProjectingNixos = projectClassOf gFwdDestAtProjecting "scope" "nixos";
        atDescendantHomeManager = projectClassOf gFwdDestAtDescendant "scope" "home-manager";
        atDescendantNixos = projectClassOf gFwdDestAtDescendant "scope" "nixos";
      };
      expected = {
        # reroute at the PROJECTING scope: `home-manager` has an outgoing relocation, so the declared
        # destination resolves to nothing there and the forward lands at `nixos` instead.
        atProjectingHomeManager = [ ];
        atProjectingNixos = [
          {
            placed = {
              tag = "fwd-src";
            };
          }
        ];
        # THE MIRROR: the same `reroute` at the DESCENDANT that authored the spec leaves the destination
        # unmoved — the projecting scope declares no relocation, so `intoClass` resolves as written.
        atDescendantHomeManager = [
          {
            placed = {
              tag = "fwd-src";
            };
          }
        ];
        atDescendantNixos = [ ];
      };
    };

    # (c) ★★ A PARENT-TARGETED ROUTE'S DESTINATION FOLLOWS THE GATHERING SCOPE'S RELOCATION — the second
    #     gathering arm, and the one no fixture in this suite could see. The rows above cover the own-scope
    #     arm; the descendant-fired `appendToParent` routes are gathered by the host through a SEPARATE
    #     destination compare, and every parent-targeted fixture here declares `to = nixos` at a host that
    #     reroutes nothing — where matching the destination through the host's relocation and matching it
    #     literally give the same answer. So that compare had no witness at all, and deleting it left every
    #     row green.
    #     The fleets below differ in ONE declaration, at the host: the cell fires the route either way, and
    #     the host either reroutes the route's `to` away or does not. Both halves move, which is what makes
    #     the row discriminating in both directions rather than only where content appears — under a
    #     literal compare the contribution stays at `nixos` and never reaches `darwin`.
    test-parent-targeted-route-destination-follows-relocation = {
      expr = {
        relocatedAtTarget =
          (crossFreeform (projectClassOf gPtDestRelocated "host" "darwin")).home-manager.users;
        relocatedAtDeclared = projectClassOf gPtDestRelocated "host" "nixos";
        controlAtDeclared =
          (crossFreeform (projectClassOf gPtDestControl "host" "nixos")).home-manager.users;
        controlAtTarget = projectClassOf gPtDestControl "host" "darwin";
      };
      expected = {
        # the host reroutes `nixos → darwin`, so the route declared `to = nixos` contributes HERE…
        relocatedAtTarget.tux = {
          tag = "hm-tux";
        };
        relocatedAtDeclared = [ ]; # …and nothing rests at the channel it named.
        # CONTROL, one declaration away: the route answers at its declared destination and nowhere else.
        controlAtDeclared.tux = {
          tag = "hm-tux";
        };
        controlAtTarget = [ ];
      };
    };
  };
}
