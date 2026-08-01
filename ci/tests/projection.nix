# den-hoag class-projection over the resolved-aspect graph (spec §1/§3) — projectClass.
#
# `projectClass id class` = the class-`C` module slice of EVERY resolved-aspect node in `reach id`, in
# reach's canonical order (own-subtree → descendant cells → default edges → opt-in edges), each slice via
# `classSliceAt` (THE ONE extraction the `class-modules` buckets also use). The terminal CONSUMES it:
# `terminalModulesAt = projectClass` — projection is now the terminal's content source (the emission model,
# `classSubtreeAt ++ deliveryModulesAt`, is dead and deleted).
#
# THREE witness planes:
#   • THE ANCHOR (real fleet, the subsume proof): for a node with NO reach edges, `reach id` = its OWN scope
#     subtree (`[id] ++ scope.descendants`), so `projectClass id class == classSubtreeAt id class`
#     byte-identically — projection reproduces the fold (incl. the descendant down-fold it subsumed)
#     BEFORE it replaces the emission. Driven on the `class-fold-subtree` fixture (nixos host + 3 hm cells
#     each emitting a define-user-shaped nixos slice), reached through `fleet.den.output.{projectClass,
#     classSubtreeAt}`.
#   • THE RELOCATION INPUT (real fleet, the anchor's NON-TRIVIAL input): the two sides of the anchor reach
#     the relocation relation Ρ(n) (`reroute`) by different routes — `classSubtreeAt` reads `class-seeds`,
#     which applies it off the node's own frame; `projectClass` reads `classSliceAt` over reach, which
#     applies it off the `class-relocation` memo at each ELEMENT'S OWN scope. On a relocation-FREE fleet
#     Ρ(n) = ∅, so both sides answer the same for the trivial reason that neither moves any content, and
#     the equality is satisfied by an input that cannot distinguish them. This plane declares a relocation
#     over content that arrives BY REACH, which is the input class on which the two sides COULD differ —
#     and the rows are what measure that they do not.
#   • SYNTHETIC (stub reach, the edge-replacement proofs): `projectClass` is `concatMap (n: map (e: e.module)
#     (classSliceAt eval n class)) (reach id)`, so GIVEN a reach list it is a pure class-slice fold — reach's own
#     edge-following (opt-in / structural-descendant / class-scope) is proven in reach-graph.nix. Here we
#     drive projectClass over a STUB `result` serving a synthetic reach list, witnessing the class-slice
#     projection: an opt-in-edge host-hm slice included once, a descendant define-user nixos slice, F9
#     class-scope (no host nixos-only aspect in a home-manager projection), canonical order preserved.
{
  denCompat,
  denHoag,
  denHoagSrc,
  nixpkgsLib,
  ...
}:
let
  inherit (denHoag) sel;
  # Shared reach/projectClass driver bindings, hoisted to a `/_`-skipped module (see the harness header).
  harness = import ./_lib/projection-harness.nix { inherit denHoag denHoagSrc; };
  inherit (harness)
    mkNode
    mkStub
    reachEdgeAct
    projectOver
    projectReach
    projectReachTotal
    tags
    assertKeysRegistered
    ;

  # ── ANCHOR fixture: the class-fold-subtree fleet (nixos host `igloo` + three hm user cells, each cell
  #    emitting a nixos (define-user) slice + a home-manager slice). NO reach edges (corpus has none until
  #    Phase 5), so reach host = the structural subtree — the exact classSubtreeAt domain.
  anchorFleet = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.igloo = {
        class = "nixos";
        users.tux = { };
        users.pol = { };
        users.amy = { };
      };
      den.schema.user.parent = "host";
      den.aspects.hostc.nixos.tag = "nixos-host";
      den.schema.host.includes = [ "hostc" ];
      den.aspects.acct =
        { user, ... }:
        {
          nixos.tag = "nixos-${user.name}";
          # hm class content authored the v1-SURFACE way (`homeManager`) — a parametric aspect's result has no
          # raw-splice, so the kebab (grounded) name would freeform-mangle; the v1 spelling grounds at compile.
          homeManager.tag = "hm-${user.name}";
        };
      den.schema.user.includes = [ "acct" ];
    }
  ];
  igloo = "host:igloo";
  out = anchorFleet.den.output;

  # ── RELOCATION fixture: an env/host/user topology carrying the anchor's non-trivial input ────────────
  #    The user CELL holds the `home-manager` content and the HOST holds the `nixos` content, so the
  #    cell's slice arrives at the host's projection BY REACH (reach's structural-descendant component) —
  #    the arrival path `class-relocation`'s synthetic `self` cannot produce, since it drives the seed
  #    query at one node and never builds a reach.
  #    NATIVE `mkDen`: `reroute` is a resolution verb of the native declaration vocabulary with no v1
  #    spelling (the v1 effect translation emits `edge`/`drop`/`suppress`/`member`/`delivery` only), so
  #    the compat surface the fleet above uses cannot author this input at all.
  relocationSchema.config.den.schema = {
    env.parent = null;
    host.parent = "env";
    user.parent = "host";
  };
  relocationInstances.config.den = {
    env.prod = { };
    host.axon = { };
    user.alice = { };
  };
  relocationMembership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
        }
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  relocationClassing.config.den.contentClass = {
    host = "nixos";
    user = "home-manager";
  };
  relocationContent =
    { config, ... }:
    {
      config.den.aspects.hostc.nixos.tag = "nixos-host";
      config.den.aspects.acct.home-manager.tag = "hm-alice";
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.hostc ];
        }
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.acct ];
        }
      ];
    };
  # Ρ(n) = { home-manager → nixos }, declared at every scope carrying the `host` coordinate — the
  # PROJECTING host and the descendant cell whose slice reach delivers to it.
  relocationMod.config.den.policies.relocate-hm = {
    emits = [ "reroute" ];
    selects = sel.star;
    fn =
      { host, ... }:
      [
        (denHoag.declare.reroute {
          from = denHoag.classes.home-manager;
          to = denHoag.classes.nixos;
        })
      ];
  };
  relocationBase = [
    relocationSchema
    relocationInstances
    relocationMembership
    relocationClassing
    relocationContent
  ];
  # the CONTROL twin — the same fleet with the relocation declaration REMOVED, nothing else.
  relocationFreeOut = (denHoag.mkDen relocationBase).den.output;
  relocatedOut = (denHoag.mkDen (relocationBase ++ [ relocationMod ])).den.output;
  axon = "host:axon";
  alice = "user:alice@host:axon";

  # ── THE TERMINAL-SIDE TWIN: the same topology, content authored through DECLARED OPTIONS ──────────────
  # The rows above stop at `projectClass` / `classSubtreeAt`. The terminal is one alias hop further on
  # (`terminalModulesAt` → `systems.<class>.<member>.modules`), and a module list arriving there is
  # `bindAtSourceScope`- and `bind.wrapAll`-wrapped — a projected foreign-scope slice is a fully-applied
  # attrset or a `setFunctionArgs` functor, so the raw `tags` walk the content rows use does not reach it.
  # The terminal rows therefore assert through an EVALUATION of the resolved configuration, which is also
  # the register the membership argument is made in: what the built system holds, not what a list looks
  # like. An evaluation needs content that sets options which EXIST, so this fixture replaces the `tag`
  # strings with option definitions; every other module is shared with the fixture above, so the two
  # fleets differ in their content and in nothing else.
  #
  # THE HOST AND THE CELL SET DIFFERENT OPTIONS, and that is what lets both markers be `raw` — the
  # one-definition type. A single shared marker would need a merging type, and a merging type would absorb
  # an unexpected second contributor silently; with `raw`, a second definition of either marker is a
  # conflict rather than a longer list. `hostMarker` is the non-vacuity half: it resolves on BOTH fleets,
  # so a control answering the marker's default is a control that reached the terminal and found nothing
  # there, rather than an eval that never ran.
  markerContent =
    { config, ... }:
    {
      config.den.aspects.hostm.nixos.hostMarker = "nixos-host";
      config.den.aspects.acctm.home-manager.marker = "hm-alice";
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.hostm ];
        }
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.acctm ];
        }
      ];
    };
  markerBase = [
    relocationSchema
    relocationInstances
    relocationMembership
    relocationClassing
    markerContent
  ];
  markerFreeOut = (denHoag.mkDen markerBase).den.output;
  markerRelocatedOut = (denHoag.mkDen (markerBase ++ [ relocationMod ])).den.output;

  # Force a member's module list through the REAL module system — the crossing `gen-flake`'s terminal
  # makes — and answer its resolved configuration. `marker2` belongs to the injection rows below; it is
  # declared here because one eval serves every terminal row and a per-row option set would let two rows
  # disagree about what the terminal was asked for. `warnings` is gen-bind's split-return collision
  # channel, which a bare `evalModules` (not a full NixOS eval) does not declare.
  evalMember =
    sys:
    (nixpkgsLib.evalModules {
      modules = sys.modules ++ [
        (
          { lib, ... }:
          {
            options.marker = lib.mkOption {
              type = lib.types.raw;
              default = "unset";
            };
            options.marker2 = lib.mkOption {
              type = lib.types.raw;
              default = "unset";
            };
            options.hostMarker = lib.mkOption {
              type = lib.types.raw;
              default = "unset";
            };
            options.warnings = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          }
        )
      ];
    }).config;

  # ── THE INJECTION INPUT: the second public relocation verb, on the same fixture ───────────────────────
  # `declare.inject` declares content AT A SCOPE with no aspect behind it. It reaches both consumers through
  # the SAME per-scope memo the `reroute` half rides (`class-relocation.injections`), read by `class-seeds`
  # for the fold and by `reach`'s structural arm for the projection — which is why the two sides can be
  # compared here at all, and why an implementation wiring only one of the two reads fails these rows while
  # leaving every `reroute` row above green.
  injectMod.config.den.policies.inject-hm = {
    emits = [ "inject" ];
    selects = sel.star;
    fn =
      { user, ... }:
      [
        (denHoag.declare.inject {
          class = denHoag.classes.home-manager;
          module = {
            tag = "inj-alice";
          };
        })
      ];
  };
  injectedOut = (denHoag.mkDen (relocationBase ++ [ injectMod ])).den.output;

  # The injection at the NIXOS coordinate. The rows above inject at `home-manager`, which is the cell's own
  # producing class and therefore a coordinate that ALREADY HOLDS CONTENT — so an injection landing there
  # is measured as a longer list beside content that was going to be there anyway. The cell holds no
  # `nixos` content at all, so this fleet is the cell-with-no-preexisting-content case: the coordinate's
  # entire answer is the injection, and a design that appends to an existing bucket while failing to
  # create an absent one answers `[ ]` here and stays green on every row above.
  injectNixosMod.config.den.policies.inject-nixos = {
    emits = [ "inject" ];
    selects = sel.star;
    fn =
      { user, ... }:
      [
        (denHoag.declare.inject {
          class = denHoag.classes.nixos;
          module = {
            tag = "inj-nixos";
          };
        })
      ];
  };
  injectNixosOut = (denHoag.mkDen (relocationBase ++ [ injectNixosMod ])).den.output;

  # The injection on the TERMINAL-side fixture, for the alias-hop row. `marker2` is a third option, so the
  # injected module is distinguishable at the resolved configuration from the cell's own `marker`.
  injectMarkerMod.config.den.policies.inject-marker = {
    emits = [ "inject" ];
    selects = sel.star;
    fn =
      { user, ... }:
      [
        (denHoag.declare.inject {
          class = denHoag.classes.home-manager;
          module = {
            marker2 = "inj-alice";
          };
        })
      ];
  };
  injectMarkerOut = (denHoag.mkDen (markerBase ++ [ injectMarkerMod ])).den.output;

  # ── THE INJECTED KEY SPACE: one fleet per cell of the space a channel name can land in ────────────────
  # `declare.inject { class = c; module = m; }` mints a content element whose content is
  # `{ name = "<inject>"; ${c} = m; }`, so the act MERGES A FLEET-AUTHORED NAME INTO A KEY SPACE THE KERNEL
  # READS BY FIXED NAME. Before an injection is rendered a channel name was never a content key; after it,
  # it always is — so what happens on a collision is this rendering's own obligation, and only two answers
  # exist: drop it silently, or refuse it named. The fleets below are one per cell of that space, each
  # paired with a control ONE DECLARATION away, because a refusal measured without its control is
  # indistinguishable from a change that refuses the whole space.
  mkInjectMod =
    class: module:
    {
      config.den.policies.injector = {
        emits = [ "inject" ];
        selects = sel.star;
        fn =
          { user, ... }:
          [ (denHoag.declare.inject { inherit class module; }) ];
      };
    };
  mkRerouteMod =
    from: to:
    {
      config.den.policies.rerouter = {
        emits = [ "reroute" ];
        selects = sel.star;
        fn =
          { user, ... }:
          [ (denHoag.declare.reroute { inherit from to; }) ];
      };
    };
  outOf = mods: (denHoag.mkDen (relocationBase ++ mods)).den.output;
  # `spool` becomes a QUIRK CHANNEL by this one declaration, and by nothing else. It is the only member of
  # the reserved key space a fleet can create, which is why the pair it anchors is the sharpest control
  # here: every other reserved name is a kernel key whose category no fleet can change.
  quirkMod.config.den.quirks.spool = { };

  # (b) an UNREGISTERED channel, routed into a registered one through an unregistered endpoint.
  injectUnregOut = outOf [
    (mkInjectMod "spool" { tag = "inj-unreg"; })
    (mkRerouteMod "spool" denHoag.classes.nixos)
  ];
  # …and the same fleet carrying, at the same cell, an ASPECT with a genuinely unregistered content key of
  # that same name. The injection's exemption is stamped on ITS OWN element, so the aspect's key is not
  # exempted by it and stays a typo.
  typoAspect =
    { config, ... }:
    {
      config.den.aspects.typo.spool.tag = "typo-spool";
      config.den.include = [
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.typo ];
        }
      ];
    };
  injectUnregTypoOut = outOf [
    (mkInjectMod "spool" { tag = "inj-unreg"; })
    (mkRerouteMod "spool" denHoag.classes.nixos)
    typoAspect
  ];
  # the same aspect and the same relocation with NO injection anywhere — the control for the pair above.
  typoOnlyOut = outOf [
    typoAspect
    (mkRerouteMod "spool" denHoag.classes.nixos)
  ];

  # (c) the EMPTY module, and its non-empty twin one declaration away.
  injectEmptyOut = outOf [ (mkInjectMod denHoag.classes.home-manager { }) ];
  injectEmptyMarkerOut = (denHoag.mkDen (markerBase ++ [ (mkInjectMod denHoag.classes.home-manager { }) ]))
    .den.output;

  # (d) the `_`-prefixed channel, and the byte-identical fleet one character away.
  injectUnderscoreOut = outOf [
    (mkInjectMod "_spool" { tag = "inj-underscore"; })
    (mkRerouteMod "_spool" denHoag.classes.nixos)
  ];
  injectPlainOut = outOf [
    (mkInjectMod "spool" { tag = "inj-plain"; })
    (mkRerouteMod "spool" denHoag.classes.nixos)
  ];

  # (g) the SCHEMA-CLAIMED key space, mint side. Three members, two categories, and the one member a fleet
  #     itself creates.
  injectMetaOut = outOf [ (mkInjectMod "meta" { tag = "inj-meta"; }) ];
  injectIncludesOut = outOf [ (mkInjectMod "includes" { tag = "inj-includes"; }) ];
  injectArtifactOut = outOf [ (mkInjectMod "artifact" { tag = "inj-artifact"; }) ];
  injectNameOut = outOf [ (mkInjectMod "name" { tag = "inj-name"; }) ];
  injectQuirkOut = outOf [
    quirkMod
    (mkInjectMod "spool" { tag = "inj-spool"; })
    (mkRerouteMod "spool" denHoag.classes.nixos)
  ];

  # (h) the same key space read from the SOURCE side: an aspect declaring content at the declared quirk
  #     channel, with a relocation carrying it into a registered class.
  quirkSourceAspect =
    { config, ... }:
    {
      config.den.aspects.spoolsrc.spool.tag = "src-spool";
      config.den.include = [
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.spoolsrc ];
        }
      ];
    };
  routeSourceQuirkOut = outOf [
    quirkMod
    quirkSourceAspect
    (mkRerouteMod "spool" denHoag.classes.nixos)
  ];
  routeSourceUnregOut = outOf [
    quirkSourceAspect
    (mkRerouteMod "spool" denHoag.classes.nixos)
  ];

  # ── THE DESTINATION INPUT: a ROUTE targeting the channel the relocation empties ───────────────────────
  # `relocationMod` moves `home-manager` to `nixos`; a route declaring `to = home-manager` at the same scope
  # is the ONE fixture combination that asks whose relocation governs a route's DESTINATION. Neither the
  # relocation fixture above nor the route suites carried it, which is why the question went unasked.
  # The cell gains a `darwin` slice as the route's SOURCE, held fixed across subject and control so the only
  # thing that moves between the two fleets is the presence of the `reroute` act.
  relocationDarwinSource.config.den.aspects.acct.darwin.tag = "dar-alice";
  routeMod.config.den.policies.route-darwin-to-hm = {
    emits = [ "delivery" ];
    selects = sel.star;
    fn =
      { user, ... }:
      [
        (denHoag.declare.delivery {
          sourceClass = denHoag.classes.darwin;
          targetClass = denHoag.classes.home-manager;
          module = null; # a CLASS source (the route case), not a module delivery.
          path = [ ];
          mode = "merge";
        })
      ];
  };
  routedBase = relocationBase ++ [
    relocationDarwinSource
    routeMod
  ];
  routedOut = (denHoag.mkDen routedBase).den.output;
  routedRelocatedOut = (denHoag.mkDen (routedBase ++ [ relocationMod ])).den.output;
in
{
  flake.tests.projection = {
    # ══ THE ANCHOR — projectClass vs classSubtreeAt on a no-edge node (the subsume proof) ═══════════════
    # A real fleet host with descendant cells but NO reach edges: reach = `[id] ++ scope.descendants`, so the
    # BASE class-slice projection over reach reproduces the classSubtreeAt SAME-CLASS down-fold. The route layer
    # REFINED the invariant: `projectClass id C == classSubtreeAt id C` is EXACT only for a route-FREE class
    # (no route targets C at the projecting scope); a routed class gains the route-remap DELTA
    # (`projectClass ⊇ classSubtreeAt`). The corpus's built-in os→nixos route (mkDen os-class battery) routes
    # `nixos` at every host, so the strong exact-equality anchor moves to the route-FREE `home-manager` class,
    # and `nixos` gets the routed-DELTA anchor — together they prove projection = same-class fold PLUS the
    # route transform, precisely (spec §5 (b), owner ruling 2026-07-14).

    # (a) ROUTED-DELTA (the NEW correct invariant for a routed class): `nixos` is routed at igloo by TWO
    #     built-in routes, so `projectClass igloo "nixos"` (the route-MATERIALIZATION path) is the SAME-CLASS
    #     fold `classSubtreeAt igloo "nixos"` PLUS both route remaps — and the equality stays EXACT (not a
    #     superset; the RHS accounts for every route materialization in projectClass's emit order):
    #       • the os→nixos route (at=[], reach==subtree) — its remap is exactly the os-class subtree fold
    #         `classSubtreeAt igloo "os"` (each reached node's os slice, flat); then
    #       • the user→host route (parent-targeted, at=[users users <u>]) — each user cell here emits NO
    #         `.user` content, so the route contributes no remapped module but MATERIALIZES its target path
    #         (v1 ensureTargetPath): an empty `users.users.<u> = {}` seed per cell, in descendant order. This
    #         is why the anchor is ROUTE-AWARE — projectClass carries route materializations that the pure
    #         content fold `classSubtreeAt` does not; the RHS includes them to keep the decomposition EXACT.
    test-anchor-projectClass-nixos-routed-delta = {
      expr =
        out.projectClass igloo "nixos" == out.classSubtreeAt igloo "nixos"
        ++ out.classSubtreeAt igloo "os"
        ++ map (u: { config.users.users.${u} = { }; }) [
          "amy"
          "pol"
          "tux"
        ];
      expected = true;
    };
    # (b) ROUTE-FREE EXACT (the PRESERVED strong same-class subsume proof): `home-manager` is NOT routed at
    #     igloo (the host's own routes target nixos only), so `projectClass id C == classSubtreeAt id C`
    #     holds EXACTLY — projection reproduces the SAME-CLASS down-fold byte-identically (same module list,
    #     same A12 own-first ++ lexicographic-DFS order), the route-remap delta being `[ ]`.
    test-anchor-projectClass-eq-classSubtreeAt-hm-route-free = {
      expr = out.projectClass igloo "home-manager" == out.classSubtreeAt igloo "home-manager";
      expected = true;
    };
    # (c) the projection's actual TAGGED CONTENT + ORDER at nixos — own-first ++ lexicographic-DFS — UNCHANGED
    #     by the route layer: the os→nixos remap contributes only PHANTOM empty os slices (the ledgered §2.5
    #     over-report — an `acct` cell declares no os content, so its os slice is a `{ imports = [ { } ]; }`
    #     no-op carrying NO tag), so the tagged nixos content is exactly the four same-class slices. This
    #     proves the routed-delta above is over the RIGHT value (real nixos content untouched, delta = empties).
    test-anchor-projectClass-nixos-content-order = {
      expr = builtins.concatMap tags (out.projectClass igloo "nixos");
      expected = [
        "nixos-host" # own (self first)
        "nixos-amy" # descendant cells, lexicographic-DFS
        "nixos-pol"
        "nixos-tux"
      ];
    };

    # ══ THE RELOCATION INPUT — the anchor equality on an input whose two sides CAN differ ═══════════════
    # The rows above hold on a fleet whose relocation relation is EMPTY, where `class-seeds`' source order
    # for every channel is `[ c ]` — the identity — so `classSubtreeAt` and `projectClass` agree without
    # either one expressing a relocation. The equality is a property of the two functions only on an input
    # that declares one: content whose channel has an outgoing relocation comes to rest at the target, so
    # the SOURCE channel holds nothing and the TARGET channel carries the moved slice. `classSubtreeAt`
    # folds each scope's `class-seeds` and therefore answers the relocated content; `projectClass` folds
    # `classSliceAt` over reach, which resolves each element's source order at THAT ELEMENT'S OWN scope and
    # therefore answers the relocated content too. THE EQUIVALENCE HOLDS ONLY BECAUSE THE PROJECTION APPLIES
    # THE RELOCATION RELATION — these rows are what measures that it does, and they fail against a
    # projection folding the raw per-channel read.

    # (i) CONTROL, in the same run: the SAME fleet with no relocation declared agrees on both channels, so
    #     the rows below measure the relocation and not the fixture's own shape (native mkDen, the
    #     cell-under-host reach) — a fixture that diverged for a structural reason would fail here too.
    test-anchor-relocation-free-control = {
      expr = {
        home-manager =
          relocationFreeOut.projectClass axon "home-manager"
          == relocationFreeOut.classSubtreeAt axon "home-manager";
        nixos =
          relocationFreeOut.projectClass axon "nixos" == relocationFreeOut.classSubtreeAt axon "nixos";
      };
      expected = {
        home-manager = true;
        nixos = true;
      };
    };

    # (ii) THE ANCHOR EQUALITY on the relocation input, stated as the two SIDES so the failure carries the
    #      value diff. `nixos` is route-free on this native fleet (it declares no delivery edge at all), so
    #      the route-remap delta is `[ ]` on both channels and the decomposition is the EXACT equality of
    #      the (b) row above.
    test-anchor-projectClass-eq-classSubtreeAt-under-relocation = {
      expr = {
        home-manager = relocatedOut.projectClass axon "home-manager";
        nixos = relocatedOut.projectClass axon "nixos";
      };
      expected = {
        home-manager = relocatedOut.classSubtreeAt axon "home-manager";
        nixos = relocatedOut.classSubtreeAt axon "nixos";
      };
    };

    # (iii) the same claim against ABSOLUTE content, so the equality above cannot be satisfied by two sides
    #       broken alike: the cell's `hm-alice` slice comes to rest at the host's `nixos` projection (after
    #       the host's own content, the target's own seeds coming first), and `home-manager` — a channel
    #       with an outgoing relocation — projects nothing.
    test-anchor-projectClass-relocated-content = {
      expr = {
        home-manager = builtins.concatMap tags (relocatedOut.projectClass axon "home-manager");
        nixos = builtins.concatMap tags (relocatedOut.projectClass axon "nixos");
      };
      expected = {
        home-manager = [ ];
        nixos = [
          "nixos-host"
          "hm-alice"
        ];
      };
    };

    # ══ THE RELOCATION AT THE TERMINAL — closing the alias hop ══════════════════════════════════════════
    # The three rows above stop at `projectClass` / `classSubtreeAt`. Both of those are one alias hop short
    # of the surfaces a consumer actually reads: `graphAccessor.contentsOf` on the collection side and
    # `systems.<class>.<member>.modules` on the terminal side. Until the hop is closed, "the introspection
    # surface and the built system agree about a relocation" is a reading of the call chain rather than a
    # measurement, and the two rows below are the measurement — one at each end, on the same fixture.

    # (iv) THE COLLECTION-SIDE END. `contentsOf id class` re-presents the class bucket as seed
    #      contributions, so its `content` is the same deferredModule the rows above walk and the same
    #      `tags` projection applies. It answers the RELOCATED content, which is what makes the accessor
    #      the fold's alias rather than a second reading of the graph.
    test-relocation-reaches-contentsOf = {
      expr = builtins.concatMap (c: tags c.content) (relocatedOut.graphAccessor.contentsOf axon "nixos");
      expected = [
        "nixos-host"
        "hm-alice"
      ];
    };

    # (v) THE TERMINAL-SIDE END, asserted through an EVALUATION rather than over a module list's shape.
    #     `marker` is defined only by the CELL's `home-manager` content and only the relocation brings it
    #     into the host's `nixos` member, so its resolved value is the relocation observed at the built
    #     configuration. The control is the relocation-free twin in the same run, and `hostMarker` is what
    #     makes the control evidence: it resolves on both fleets, so the control's `unset` is the terminal
    #     reached and holding nothing there — not an evaluation that failed to run.
    test-relocation-reaches-terminal-modules = {
      expr = {
        relocated =
          let
            c = evalMember markerRelocatedOut.systems.nixos.${axon};
          in
          {
            inherit (c) marker hostMarker;
          };
        control =
          let
            c = evalMember markerFreeOut.systems.nixos.${axon};
          in
          {
            inherit (c) marker hostMarker;
          };
      };
      expected = {
        relocated = {
          hostMarker = "nixos-host"; # the host's own content, on both fleets…
          marker = "hm-alice"; # …and the cell's, which only the relocation puts here.
        };
        control = {
          hostMarker = "nixos-host";
          marker = "unset";
        };
      };
    };

    # (vi) ★ THE VANISHED CONTENT LANDS IN THE HOST, and the row must assert BOTH halves or it is satisfied
    #      by a design that simply deletes the emptied cell.
    #      (a) MEMBERSHIP IS UNCHANGED at the destination class: the cell never becomes a `nixos` member,
    #          because the member filter's producing-class conjunct excludes it whatever content the
    #          coordinate holds. This is the half that fails if an implementation reads the relocation into
    #          the member spine as well as into the content.
    #      (b) THE HOST'S OWN MODULE COUNT MOVES: the relocated cell content arrives as a second module at
    #          the host's `nixos` projection, against one on the control.
    #      A change that merely deleted the emptied cell would pass (a) and fail (b).
    #
    #      This is the DESTINATION coordinate of the observation the route suite's member row makes at the
    #      SOURCE: that row asserts the cell is GONE from `systems.home-manager`, this one asserts it never
    #      ARRIVES in `systems.nixos` while its content does. Neither implies the other — a design moving
    #      the member along with the content passes the first and fails this one.
    test-relocation-vanished-content-lands-in-the-host = {
      expr = {
        membersRelocated = builtins.attrNames relocatedOut.systems.nixos;
        membersControl = builtins.attrNames relocationFreeOut.systems.nixos;
        modulesRelocated = builtins.length (relocatedOut.projectClass axon "nixos");
        modulesControl = builtins.length (relocationFreeOut.projectClass axon "nixos");
      };
      expected = {
        membersRelocated = [ axon ]; # (a) the cell is not here…
        membersControl = [ axon ];
        modulesRelocated = 2; # (b) …but its content is.
        modulesControl = 1;
      };
    };

    # ══ THE INJECTION INPUT — the second public verb, armed at both consumers ═══════════════════════════
    # `den-hoag-4kh.41` recorded the standing gap in one line: only `reroute` was armed. The rows above
    # measure a relocation; these measure an INJECTION, which is the other half of the same memo and the
    # half with no witness. They are stated in the register the rows above use — the two consumers compared,
    # then the absolute content, then the injection-free control — so a remedy that broke both sides alike
    # cannot satisfy the equality alone.

    # (i) THE TWO CONSUMERS AGREE on an injected channel, at the cell that declares it AND at the host that
    #     reaches it. `classSubtreeAt` folds `class-seeds`, which reads the memo's `injections` directly;
    #     `projectClass` folds `classSliceAt` over `reach`, whose structural arm carries the same elements.
    #     One memo, two reads — and an implementation wiring only the fold leaves the host half red.
    test-inject-projectClass-eq-classSubtreeAt = {
      expr = {
        cell = injectedOut.projectClass alice "home-manager";
        host = injectedOut.projectClass axon "home-manager";
      };
      expected = {
        cell = injectedOut.classSubtreeAt alice "home-manager";
        host = injectedOut.classSubtreeAt axon "home-manager";
      };
    };

    # (ii) THE ABSOLUTE CONTENT, so the equality above cannot be satisfied by two sides broken alike: the
    #      injected module lands AFTER the cell's own aspect content (an injection has no element position
    #      of its own — it follows the scope's resolved aspects), and it reaches the HOST's projection too,
    #      because reach's structural arm draws the descendant cell's elements into the host's view.
    test-inject-projectClass-content = {
      expr = {
        cell = builtins.concatMap tags (injectedOut.projectClass alice "home-manager");
        host = builtins.concatMap tags (injectedOut.projectClass axon "home-manager");
      };
      expected = {
        cell = [
          "hm-alice"
          "inj-alice"
        ];
        host = [
          "hm-alice"
          "inj-alice"
        ];
      };
    };

    # (iii) THE INJECTION-FREE CONTROL, same run: the byte-identical fleet without `injectMod` carries the
    #       aspect content alone on BOTH consumers. Without it the rows above are satisfied by any change
    #       that adds content to every projection.
    test-inject-control-injection-free = {
      expr = {
        projected = builtins.concatMap tags (relocationFreeOut.projectClass alice "home-manager");
        folded = builtins.concatMap tags (relocationFreeOut.classSubtreeAt alice "home-manager");
      };
      expected = {
        projected = [ "hm-alice" ];
        folded = [ "hm-alice" ];
      };
    };

    # (iv) THE INJECTION AT A COORDINATE THAT HOLDS NOTHING. The three rows above inject at the cell's own
    #      producing class, where the injected module lands beside content that was going to be there
    #      anyway — so they cannot tell "appends to a bucket" from "creates one". The cell declares no
    #      `nixos` content at all, so here the coordinate's whole answer IS the injection, on both
    #      consumers, and the same-run control is the injection-free fleet answering nothing there.
    #      ★ The member half is the second reason this coordinate is worth its own row: the cell holds
    #      `nixos` content now and still does not become a `nixos` member — content at a coordinate and
    #      membership of that class are independent, exactly as the relocation rows above assert from the
    #      other direction.
    test-inject-at-empty-coordinate = {
      expr = {
        cell = builtins.concatMap tags (injectNixosOut.projectClass alice "nixos");
        cellFolded = builtins.concatMap tags (injectNixosOut.classSubtreeAt alice "nixos");
        host = builtins.concatMap tags (injectNixosOut.projectClass axon "nixos");
        control = builtins.concatMap tags (relocationFreeOut.projectClass alice "nixos");
        members = builtins.attrNames injectNixosOut.systems.nixos;
      };
      expected = {
        cell = [ "inj-nixos" ]; # the coordinate held nothing; the injection is its whole content…
        cellFolded = [ "inj-nixos" ]; # …on the other consumer too.
        host = [
          "nixos-host"
          "inj-nixos"
        ]; # and reach draws it into the host's projection.
        control = [ ]; # one declaration away, the coordinate is empty.
        members = [ axon ]; # content at `nixos` does not make the cell a `nixos` member.
      };
    };

    # (v) THE INJECTION REACHES THE TERMINAL — the alias hop closed for the inject half, on the same
    #     evaluation predicate the relocation's terminal row uses. `marker2` is defined only by the
    #     injected module, so its resolved value at the cell's built member is the injection observed at
    #     the configuration rather than in a module list. `marker` is the non-vacuity half here: the
    #     cell's own aspect content resolves on both fleets, so the control's `unset` for `marker2` is the
    #     terminal reached and holding no injection.
    test-inject-reaches-terminal-modules = {
      expr = {
        injected =
          let
            c = evalMember injectMarkerOut.systems.home-manager.${alice};
          in
          {
            inherit (c) marker marker2;
          };
        control =
          let
            c = evalMember markerFreeOut.systems.home-manager.${alice};
          in
          {
            inherit (c) marker marker2;
          };
      };
      expected = {
        injected = {
          marker = "hm-alice"; # the cell's own content, on both fleets…
          marker2 = "inj-alice"; # …and the injected module, which only this fleet declares.
        };
        control = {
          marker = "hm-alice";
          marker2 = "unset";
        };
      };
    };

    # ══ THE INJECTED KEY SPACE — where a channel name may land, and where it is refused ═════════════════
    # The rows above inject at a REGISTERED class, which is one cell of the space an injected channel name
    # can occupy. The gate an injection crosses is a sequence, and a suite exercising one cell of it is
    # blind to the others: a fixture injecting only at a registered class cannot see a widening that
    # admits reserved names, and one injecting only a non-empty module cannot see a declared no-op being
    # collected. Every refusal below is paired with a control ONE DECLARATION away that must keep
    # delivering, because a refusal without its control is satisfied by a change that refuses the whole
    # space — the exact failure the per-element assertion exists to avoid.

    # (a) AN UNREGISTERED CHANNEL DELIVERS, and the two consumers agree about it. The injected content is
    #     routed into a registered class through an endpoint that is registered nowhere, which is the
    #     shape a design routing injections through the key classifier alone gets wrong.
    test-inject-unregistered-channel-projectClass-eq-classSubtreeAt = {
      expr = {
        cell = injectUnregOut.projectClass alice "nixos";
        host = injectUnregOut.projectClass axon "nixos";
      };
      expected = {
        cell = injectUnregOut.classSubtreeAt alice "nixos";
        host = injectUnregOut.classSubtreeAt axon "nixos";
      };
    };

    # (b) the ABSOLUTE content, so the agreement above cannot be satisfied by two sides broken alike.
    test-inject-unregistered-channel-content = {
      expr = {
        cell = builtins.concatMap tags (injectUnregOut.projectClass alice "nixos");
        host = builtins.concatMap tags (injectUnregOut.projectClass axon "nixos");
        hostFolded = builtins.concatMap tags (injectUnregOut.classSubtreeAt axon "nixos");
      };
      expected = {
        cell = [ "inj-unreg" ];
        host = [
          "nixos-host"
          "inj-unreg"
        ];
        hostFolded = [
          "nixos-host"
          "inj-unreg"
        ];
      };
    };

    # (c) ★ THE EXEMPTION DOES NOT WIDEN PAST THE ELEMENT THAT CARRIES IT. The injection's exemption is
    #     stamped on its OWN element, whose content is exactly `{ name; spool = <module>; }`, so it reaches
    #     nothing but the injected module. This fleet puts both readings of one name at one cell: an
    #     `inject` at `spool` and an ASPECT declaring content at `spool`, with a relocation carrying that
    #     channel into `nixos`. The injected module arrives; the aspect's does not — the relocation reads
    #     `spool` off the element that asserts it and skips it on the element that does not. An
    #     implementation exempting the channel NODE-WIDE instead answers both, which is what this row
    #     excludes, and its control is the injection-free fleet one declaration away where nothing arrives.
    #
    #     ★ WHAT THIS ROW DOES NOT SAY, stated because the gap is the interesting part: an unregistered
    #     content key on a native aspect is not refused here — it is DROPPED SILENTLY, and measurably so
    #     on a fleet with no injection anywhere and at a channel name no injection shares. So the aspect's
    #     absence below is the classifier's silent drop, not a refusal, and this row is not evidence that
    #     one exists. The named totality abort is witnessed on the synthetic harness rows above, whose
    #     hand-built elements reach it; no native fixture in this file does.
    test-inject-unregistered-channel-no-typo-widening = {
      expr = {
        withInjection = builtins.concatMap tags (injectUnregTypoOut.projectClass alice "nixos");
        control = builtins.concatMap tags (typoOnlyOut.projectClass alice "nixos");
      };
      expected = {
        withInjection = [ "inj-unreg" ]; # the asserting element's content, and only it.
        control = [ ]; # one declaration away, the same key carries nothing across.
      };
    };

    # (d) A DECLARED NO-OP IS DROPPED. An `inject` whose module is empty contributes no content, so the
    #     collected length matches the injection-free control exactly…
    test-inject-empty-module-not-collected = {
      expr = {
        empty = builtins.length (injectEmptyOut.classSubtreeAt alice "home-manager");
        control = builtins.length (relocationFreeOut.classSubtreeAt alice "home-manager");
      };
      expected = {
        empty = 1;
        control = 1;
      };
    };

    # (e) …and its twin, which is what stops a repair from dropping EVERY injection: the same fleet with a
    #     non-empty module collects it. The two rows disagree under any single-sided error.
    test-inject-nonempty-module-collected = {
      expr = {
        nonEmpty = builtins.length (injectedOut.classSubtreeAt alice "home-manager");
        control = builtins.length (relocationFreeOut.classSubtreeAt alice "home-manager");
      };
      expected = {
        nonEmpty = 2;
        control = 1;
      };
    };

    # (f) and the justification for the drop, stated where it is falsifiable: the seed count moves and the
    #     RESOLVED CONFIGURATION does not. Both fleets answer the same marker at the built member, so
    #     dropping the empty injection is measured to change no configuration rather than argued to.
    test-inject-empty-module-resolved-config-unchanged = {
      expr = {
        empty = (evalMember injectEmptyMarkerOut.systems.home-manager.${alice}).marker;
        control = (evalMember markerFreeOut.systems.home-manager.${alice}).marker;
      };
      expected = {
        empty = "hm-alice";
        control = "hm-alice";
      };
    };

    # (g) A `_`-PREFIXED CHANNEL IS REFUSED NAMED. `_`-prefixed keys in a module-shaped attrset are the
    #     module system's own scaffolding, so a channel name there would carry two readings of one value.
    #     The message names the channel, which is what makes this a refusal a fleet author can act on
    #     rather than an anonymous abort somewhere below the declaration.
    test-inject-underscore-channel-refused = {
      expr = builtins.deepSeq (injectUnderscoreOut.classSubtreeAt axon "nixos") true;
      expectedError = {
        type = "ThrownError";
        msg = "declare\\.inject at node '[^']*' names a reserved channel '_spool' \\(a '_'-prefixed content key is module-system scaffolding";
      };
    };

    # (h) ITS CONTROL, one character away: the byte-identical fleet spelling the channel `spool` still
    #     delivers. Without it the row above is satisfied by any change that breaks unregistered
    #     injections wholesale.
    test-inject-underscore-control-plain-channel = {
      expr = builtins.concatMap tags (injectPlainOut.classSubtreeAt axon "nixos");
      expected = [
        "nixos-host"
        "inj-plain"
      ];
    };

    # (i) A CHANNEL THE ASPECT SCHEMA HAS CLAIMED IS REFUSED NAMED, and the message states the CATEGORY as
    #     well as the name — the refusal is about what the name already means in this key space, not about
    #     the name itself. The three members below are armed separately rather than as one parameterised
    #     row because they do not share a category: `meta` and `includes` are structural keys the kernel
    #     reads by fixed name, `artifact` is a facet. A row pinning one member would be blind to a
    #     classifier that answered correctly for its category and wrongly for the other.
    test-inject-schema-claimed-channel-meta-refused = {
      expr = builtins.deepSeq (injectMetaOut.classSubtreeAt axon "nixos") true;
      expectedError = {
        type = "ThrownError";
        msg = "names a reserved channel 'meta' \\(the aspect schema registers it as a 'structural' key";
      };
    };
    test-inject-schema-claimed-channel-includes-refused = {
      expr = builtins.deepSeq (injectIncludesOut.classSubtreeAt axon "nixos") true;
      expectedError = {
        type = "ThrownError";
        msg = "names a reserved channel 'includes' \\(the aspect schema registers it as a 'structural' key";
      };
    };
    test-inject-schema-claimed-channel-artifact-refused = {
      expr = builtins.deepSeq (injectArtifactOut.classSubtreeAt axon "nixos") true;
      expectedError = {
        type = "ThrownError";
        msg = "names a reserved channel 'artifact' \\(the aspect schema registers it as a 'facet' key";
      };
    };

    # (j) ★ `name` — the member that needed a different predicate from every other row here, and the
    #     reason it gets its own. It is the key the mint itself writes into the element it builds, so a
    #     design that renders first and classifies afterwards collides with its own scaffolding and raises
    #     an evaluator error naming neither the declaration nor the node. The refusal is stated at the
    #     mint, before construction, which is what makes this abort CONTAINABLE and named at all.
    test-inject-channel-name-is-refused-before-construction = {
      expr = builtins.deepSeq (injectNameOut.classSubtreeAt axon "nixos") true;
      expectedError = {
        type = "ThrownError";
        msg = "names a reserved channel 'name' \\(the aspect schema registers it as a 'structural' key";
      };
    };

    # (k) ★★ THE QUIRK CHANNEL, and it is the sharpest pair here because the two fleets are ONE
    #     DECLARATION apart. `spool` is reserved only because this fleet declared it a quirk channel —
    #     every other member of the reserved space is a kernel key whose category no fleet can change. So
    #     the pair makes the refusal a finding about the CATEGORY rather than about the name: the fleets
    #     agree on every other declaration and must disagree here. It is also the only row that pins the
    #     refusal's dependence on WHICH aspect-schema instance the predicate reads — a quirk-blind
    #     instance answers `null` for `spool`, admits it, and passes every other row in this block.
    test-inject-quirk-channel-refused = {
      expr = builtins.deepSeq (injectQuirkOut.classSubtreeAt axon "nixos") true;
      expectedError = {
        type = "ThrownError";
        msg = "reserved channel 'spool' \\(the aspect schema registers it as a 'channel' key";
      };
    };
    test-inject-quirk-channel-control-undeclared = {
      expr = builtins.concatMap tags (injectPlainOut.classSubtreeAt axon "nixos");
      expected = [
        "nixos-host"
        "inj-plain"
      ];
    };

    # (l) ★★ THE SAME KEY SPACE ON THE SOURCE SIDE, where the value class is aspect content rather than an
    #     injected module. Every row above mints; this one READS. An implementation refusing relocation
    #     endpoints instead of the read would pass all of them and fail this one, which is why the two
    #     sides are armed separately. The content sits at a present, non-empty key that the source-side
    #     read would otherwise answer past silently.
    test-route-source-at-declared-quirk-channel-refused = {
      expr = builtins.deepSeq (routeSourceQuirkOut.projectClass axon "nixos") true;
      expectedError = {
        type = "ThrownError";
        msg = "class content at scope '[^']*' is read from a reserved channel 'spool' \\(the aspect schema registers it as a 'channel' key";
      };
    };

    # (m) its control, the source-side twin of (k)'s: the byte-identical fleet WITHOUT the quirk
    #     declaration leaves `spool` merely unregistered, and an unregistered source is a legitimate shape
    #     this refusal must not touch. A change refusing non-class sources wholesale satisfies (l) while
    #     emptying every unregistered route in the tree; this row is what excludes it.
    test-route-source-quirk-channel-control-undeclared = {
      expr = builtins.concatMap tags (routeSourceUnregOut.projectClass axon "nixos");
      expected = [ "nixos-host" ];
    };

    # ══ THE DESTINATION COORDINATE UNDER RELOCATION — the §4.5b ruling on a NATIVE fleet ════════════════
    # A route's `to` names a coordinate AT THE TARGET ROOT, so it is read through that root's own relocation
    # exactly as the element arm's sources are read through each element's. The fleet declares BOTH: a
    # `reroute` moving `home-manager` to `nixos`, and a `delivery` whose `targetClass` is `home-manager`.
    # `ci/tests/projection-routes.nix` carries the incoming-destination and forward arms on its stub; this is
    # the OUTGOING arm, and it is native because its consequence — the member row below — is a `systems`
    # observation that only a fleet has.

    # (i) THE DISCRIMINATING ROW, and it must assert BOTH halves. A row asserting only that `home-manager`
    #     is empty is satisfied by a design that drops the route's content outright; a row asserting only
    #     that `nixos` gained it is satisfied by one that delivers it twice. Under the rejected reading —
    #     the destination matched literally — the first half stays populated and the second stays missing.
    test-route-destination-follows-outgoing-relocation = {
      expr = {
        homeManager = builtins.concatMap tags (routedRelocatedOut.projectClass alice "home-manager");
        nixos = builtins.concatMap tags (routedRelocatedOut.projectClass alice "nixos");
      };
      expected = {
        homeManager = [ ]; # the declared destination has an outgoing relocation ⇒ nothing rests there.
        nixos = [
          "hm-alice" # the cell's own relocated content…
          "dar-alice" # …and the ROUTE's contribution, which followed the same relocation.
        ];
      };
    };

    # (ii) THE CONTROL that makes the row above evidence: the byte-identical fleet WITHOUT the `reroute` act
    #      answers at the route's declared destination and adds nothing at `nixos`. Without it the row is
    #      satisfied by any change that re-aims every route.
    test-route-destination-unmoved-without-relocation = {
      expr = {
        homeManager = builtins.concatMap tags (routedOut.projectClass alice "home-manager");
        nixos = builtins.concatMap tags (routedOut.projectClass alice "nixos");
      };
      expected = {
        homeManager = [
          "hm-alice"
          "dar-alice"
        ];
        nixos = [ ];
      };
    };

    # (iii) THE MEMBER VANISHES DESPITE THE ROUTE — §15.1's corrected quantifier, made falsifiable at the
    #       surface the ruling is about. `contentIdsOf` filters on `terminalModulesAt id name != [ ]`, a
    #       THREE-term sum (element fold ++ route remap ++ forwards), so the member leaves `systems.<class>`
    #       only when all three are empty at that coordinate. This fleet declares a route targeting exactly
    #       the emptied channel — the one input on which the sum could be non-empty with the fold empty — so
    #       the row is what tells the ruling apart from a design under which the member survives holding
    #       route content. Its control is the same fleet one declaration away.
    test-member-vanishes-under-outgoing-relocation-despite-route = {
      expr = {
        relocated = builtins.attrNames routedRelocatedOut.systems.home-manager;
        control = builtins.attrNames routedOut.systems.home-manager;
      };
      expected = {
        relocated = [ ]; # all three terms empty at `home-manager` ⇒ the member is gone.
        control = [ alice ]; # one declaration away, the member is there.
      };
    };

    # ══ SYNTHETIC — the class-slice projection over a stub reach list (edge-replacement proofs) ═════════

    # (a) OPT-IN EDGE (the emission replacement): a reach list = [ own-hm, host-hm ] (as reach would return
    #     for a cell→host home-manager edge). projectClass "home-manager" = both hm slices, each ONCE.
    test-synthetic-opt-in-edge-hm-once = {
      expr =
        let
          reachList = [
            (mkNode "cell-own" { home-manager.tag = "own"; })
            (mkNode "host-hm" { home-manager.tag = "host"; }) # reached via the opt-in edge.
          ];
          ts = builtins.concatMap tags (projectOver reachList "home-manager");
        in
        {
          slices = ts; # both hm slices present, in reach order.
          hostOnce = builtins.length (builtins.filter (t: t == "host") ts); # single-visit ⇒ 1.
        };
      expected = {
        slices = [
          "own"
          "host"
        ];
        hostOnce = 1;
      };
    };

    # (b) STRUCTURAL-DESCENDANT (the classSubtreeAt replacement): a reach list = [ host-nixos, define-user ]
    #     (host own ++ a descendant cell's define-user, as reach returns). projectClass "nixos"
    #     includes the descendant cell's define-user nixos slice.
    test-synthetic-descendant-define-user-nixos = {
      expr =
        let
          reachList = [
            (mkNode "host-nixos" { nixos.tag = "host"; })
            (mkNode "define-user" { nixos.tag = "du"; }) # the descendant cell's define-user slice.
          ];
        in
        builtins.concatMap tags (projectOver reachList "nixos");
      expected = [
        "host"
        "du"
      ];
    };

    # (c) F9 CLASS-SCOPE (no over-reach): projecting the `home-manager` class over a reach list that includes
    #     a nixos-ONLY host aspect does NOT pull the nixos slice — `classSliceAt` selects only the projected
    #     class's key. (reach's edge class-filter is the reach-graph companion; this is the projection gate.)
    test-synthetic-class-scope-no-nixos-in-hm = {
      expr =
        let
          reachList = [
            (mkNode "cell-own" { home-manager.tag = "own"; })
            (mkNode "host-nixos" { nixos.tag = "n"; }) # nixos-only — MUST NOT enter the hm projection.
          ];
        in
        builtins.concatMap tags (projectOver reachList "home-manager");
      expected = [ "own" ]; # host-nixos's nixos slice excluded (no home-manager key).
    };

    # (d) ORDER — projectClass preserves reach's canonical order exactly (own → descendant → opt-in),
    #     each provider's slice in include order (projectClass is a straight concatMap over reach).
    test-synthetic-projection-order = {
      expr =
        let
          reachList = [
            (mkNode "O" { nixos.tag = "o"; }) # own
            (mkNode "Desc" { nixos.tag = "desc"; }) # descendant
            (mkNode "OptIn" { nixos.tag = "optin"; }) # opt-in edge
          ];
        in
        builtins.concatMap tags (projectOver reachList "nixos");
      expected = [
        "o"
        "desc"
        "optin"
      ];
    };

    # ══ COMPLETE-REACH projection SEMANTICS (the terminal-content proofs, spec §6 intent) ═══════════════
    #    Drive the REAL reach.compute over a stub with INJECTED opt-in edges, then projectClass —
    #    proving the terminal (terminalModulesAt = projectClass) produces the RIGHT output on a complete
    #    reach (the fleet will match once Phase 5 wires the real corpus edges). These are the outcomes the
    #    spec §6 intent oracle names: spicetify ONCE, intel cpu+gpu BOTH, define-user nixos@host + hm@cell.

    # (a) THE SPICETIFY DOUBLE dissolves — ONE declaration. A user (sini) reaches `roles.media` (→ the
    #     spicetify hm aspect) via BOTH its OWN include AND an opt-in edge to the host that ALSO includes it
    #     (same A-IDENT key). Single-visit collapses own+edge to ONE node ⇒ the spicetify hm slice appears
    #     EXACTLY ONCE in the user's home-manager projection (spec §0/§3: the double dissolves as a graph
    #     property, no dedup rule). RED under v1's blanket host→cell gather (the u25 "already declared" abort).
    test-semantic-spicetify-double-resolves-once = {
      expr =
        let
          spicetify = mkNode "roles.media" { home-manager.tag = "spicetify"; };
          graph = {
            sini = {
              resolved = [
                (mkNode "sini-own" { home-manager.tag = "sini"; })
                spicetify # sini's OWN include of roles.media.
              ];
              edges = [ (reachEdgeAct "host" "home-manager") ]; # opt-in edge to the host…
            };
            host.resolved = [ spicetify ]; # …which ALSO includes roles.media (same key).
          };
          ts = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "sini";
            class = "home-manager";
          });
        in
        {
          spicetifyCount = builtins.length (builtins.filter (t: t == "spicetify") ts); # ONCE.
          hasOwn = builtins.elem "sini" ts;
        };
      expected = {
        spicetifyCount = 1; # own+edge collapsed by single-visit — no double.
        hasOwn = true;
      };
    };

    # (b) A-IDENT DE-COLLISION — `hardware.cpu.intel` AND `hardware.gpu.intel` BOTH present. Two DISTINCT
    #     aspects (distinct A-IDENT keys) whose short names would collide under a name-only identity are
    #     kept as two nodes (native container-relative key), so both nixos slices project (spec §6 Cause-2).
    test-semantic-intel-cpu-and-gpu-both-present = {
      expr =
        let
          graph = {
            host.resolved = [
              (mkNode "hardware.cpu.intel" { nixos.tag = "cpu-intel"; })
              (mkNode "hardware.gpu.intel" { nixos.tag = "gpu-intel"; })
            ];
          };
          ts = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "host";
            class = "nixos";
          });
        in
        {
          cpu = builtins.elem "cpu-intel" ts;
          gpu = builtins.elem "gpu-intel" ts;
          count = builtins.length ts; # BOTH — no key collision collapse.
        };
      expected = {
        cpu = true;
        gpu = true;
        count = 2;
      };
    };

    # (c) DEFINE-USER SPLIT — ONE parametric multi-class aspect (`define-user`) projects nixos@HOST (via the
    #     structural-descendant edge) AND home-manager@CELL (the cell's own include). One reachable
    #     node, projected per-class-per-scope (spec §2 define-user model): the host's nixos projection carries
    #     the define-user nixos slice; the cell's home-manager projection carries the define-user hm slice.
    test-semantic-define-user-nixos-at-host-hm-at-cell = {
      expr =
        let
          defineUser = mkNode "define-user" {
            nixos.tag = "du-nixos"; # the users.users.<n> shape (host class).
            home-manager.tag = "du-hm"; # the cell's own hm content.
          };
          graph = {
            host = {
              resolved = [ (mkNode "host-own" { nixos.tag = "host"; }) ];
              children.cell = { }; # the (user,host) cell nests under the host.
            };
            cell.resolved = [ defineUser ]; # define-user lives on the cell.
          };
          hostNixos = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "host";
            class = "nixos";
          });
          cellHm = builtins.concatMap tags (projectReach {
            inherit graph;
            id = "cell";
            class = "home-manager";
          });
        in
        {
          hostHasDefineUserNixos = builtins.elem "du-nixos" hostNixos; # nixos@host (structural descendant).
          hostNoHmLeak = !(builtins.elem "du-hm" hostNixos); # the hm slice does NOT enter the nixos projection.
          cellHasDefineUserHm = builtins.elem "du-hm" cellHm; # home-manager@cell (own).
        };
      expected = {
        hostHasDefineUserNixos = true;
        hostNoHmLeak = true;
        cellHasDefineUserHm = true;
      };
    };

    # ══ §2.2 TOTALITY over REACHED content (Model C) ══════════════════════════════════════════════════════
    # Projection widened what a scope reaches (edges + descendants), so the content FORCE that fires the closed
    # gate must cover REACHED aspects, not just own-node content — else a scalar typo on an edge-reached aspect
    # would silently vanish on the drv path (the §5 silent-content-loss failure). `projectReachTotal` mirrors
    # output-modules.nix's projectClass (the `assertKeysRegistered` WHNF force per reached aspect). Under Model C
    # a SCALAR undeclared key is a typo (aborts); an undeclared ATTRSET key is a nested-aspect NAMESPACE that
    # ADMITS (its leaves validate only when it is itself resolved — lazy totality).

    # (a) an undeclared ATTRSET key (`nixxos.tag`) on an aspect reached via an OPT-IN EDGE is a nested-aspect
    #     namespace → ADMITTED under projection (not an eager typo). The reached content force is still driven
    #     (a scalar leaf there would abort); the attrset key is a nested aspect, validated only if resolved.
    test-totality-reached-attrset-key-admits-as-nested = {
      expr =
        let
          graph = {
            host = {
              resolved = [ (mkNode "host-own" { nixos.tag = "host"; }) ];
              edges = [ (reachEdgeAct "provider" null) ]; # opt-in edge to the provider…
            };
            provider.resolved = [
              (mkNode "typo-aspect" {
                name = "typo-aspect";
                nixxos.tag = "boom";
              })
            ];
          };
          r = builtins.tryEval (
            builtins.deepSeq (projectReachTotal {
              inherit graph;
              id = "host";
              class = "nixos";
            }) true
          );
        in
        r.success; # the reached attrset key admits as a nested namespace.
      expected = true;
    };

    # (b) NON-VACUOUS companion: the SAME edge-reached aspect with a REGISTERED class key (`nixos`) does NOT
    #     abort — only a genuinely unregistered key does; a registered key of a reached aspect passes
    #     (e.g. define-user's darwin/home-manager keys while projecting nixos are registered, never abort).
    test-totality-registered-key-on-reached-aspect-ok = {
      expr =
        let
          graph = {
            host = {
              resolved = [ (mkNode "host-own" { nixos.tag = "host"; }) ];
              edges = [ (reachEdgeAct "provider" null) ];
            };
            provider.resolved = [
              (mkNode "ok-aspect" {
                name = "ok-aspect";
                nixos.tag = "reached";
              })
            ]; # registered key.
          };
          ts = builtins.concatMap tags (projectReachTotal {
            inherit graph;
            id = "host";
            class = "nixos";
          });
        in
        {
          noAbort = builtins.elem "reached" ts; # the reached registered slice projects, no abort.
          hasOwn = builtins.elem "host" ts;
        };
      expected = {
        noAbort = true;
        hasOwn = true;
      };
    };

    # (c) `assertKeysRegistered` drives the content-key WHNF force (firing the closed gate). Under Model C an
    #     undeclared ATTRSET key (`nixxos.tag`) is a nested-aspect namespace → ADMITS (no eager typo abort); a
    #     registered class key (`nixos.tag`) forces to its deferredModule wrapper → admits. (A SCALAR leaf would
    #     abort at the gate; that split is covered by compat-nested-aspects.)
    test-totality-force-admits-attrset-and-registered = {
      expr =
        let
          namelessAttrset = mkNode "nameless-attrset" { nixxos.tag = "boom"; }; # undeclared attrset → nested.
          r = builtins.tryEval (builtins.seq (assertKeysRegistered { } namelessAttrset) true);
        in
        {
          attrsetAdmits = r.success;
          registeredOk =
            (builtins.tryEval (
              builtins.seq (assertKeysRegistered { } (mkNode "nameless-ok" { nixos.tag = "ok"; })) true
            )).success;
        };
      expected = {
        attrsetAdmits = true;
        registeredOk = true;
      };
    };
  };
}
