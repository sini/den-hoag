# den-hoag class-projection over the resolved-aspect graph (spec §1/§3) — projectClass.
#
# `projectClass id class` = the class-`C` module slice of EVERY resolved-aspect node in `reach id`, in
# reach's canonical order (own-subtree → descendant cells → default edges → opt-in edges), each slice via
# `classSliceOf` (THE ONE extraction the `class-modules` buckets also use). The terminal CONSUMES it:
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
#   • THE RELOCATION INPUT (real fleet, the anchor's NON-TRIVIAL input): the two sides of the anchor are
#     not the same function — `classSubtreeAt` reads `class-seeds`, which APPLIES the node's relocation
#     relation Ρ(n) (`reroute`); `projectClass` reads `classSliceOf` over reach, the RAW extraction. On a
#     relocation-FREE fleet Ρ(n) = ∅, so both sides answer the same for the trivial reason that neither
#     computes a relocation, and the equality is satisfied by an input that cannot distinguish them. This
#     plane declares a relocation over content that arrives BY REACH, which is the input class on which
#     the two sides CAN differ.
#   • SYNTHETIC (stub reach, the edge-replacement proofs): `projectClass` is `concatMap (n: map (e: e.module)
#     (classSliceOf n class)) (reach id)`, so GIVEN a reach list it is a pure class-slice fold — reach's own
#     edge-following (opt-in / structural-descendant / class-scope) is proven in reach-graph.nix. Here we
#     drive projectClass over a STUB `result` serving a synthetic reach list, witnessing the class-slice
#     projection: an opt-in-edge host-hm slice included once, a descendant define-user nixos slice, F9
#     class-scope (no host nixos-only aspect in a home-manager projection), canonical order preserved.
{
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
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
    classSliceOf
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
    # `classSliceOf` straight over reach and answers the raw content. THE EQUIVALENCE HOLDS ONLY WHEN THE
    # PROJECTION APPLIES THE RELOCATION RELATION — this input exhibits the divergence.

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
    #     a nixos-ONLY host aspect does NOT pull the nixos slice — `classSliceOf` selects only the projected
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
