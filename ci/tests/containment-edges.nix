# CONTAINMENT AS EDGES (§B4a) — the witnesses for the cutover from containment-as-payload to a
# `contains` edge pool with three coordinate projections over it.
#
# `den-hoag-akj`'s law governs every witness here: an equivalence assertion between two paths is
# VACUOUS unless the fixture contains an input on which they would differ. So each block below names
# its discriminating input and carries its control IN THE SAME RUN — and the controls are the point,
# because the two constructions this design replaces were each refuted by an input class the witness
# set that produced them could not see.
#
#   A  the coordinate query under BINDING POLLUTION — the `coordDims` kill.
#   B  the coordinate at EVERY node class, including the NON-DIM ROOT — the `dimKinds`-codomain kill.
#   E4 the cascade filter as a SLICE rule rather than its cell-arm TYPE reduction, at a root.
#   G  the `settingsDims` axis guard, shown FIRING rather than merely unreached.
#   O  the traversal ORDER under the real combinator, on fixtures no den fleet authors.
{
  denHoag,
  denHoagSrc,
  ...
}:
let
  inherit (denHoag) declare;
  prelude = denHoag.internal.prelude;
  graph = denHoag.internal.genGraph;
  errors = import "${denHoagSrc}/lib/errors.nix";
  mkCoords = import "${denHoagSrc}/lib/coordinates.nix" { inherit prelude graph errors; };

  sortStr = builtins.sort (a: b: a < b);
  # A slice rendered as `{ dim = entry-name }` — the shape the assertions read, so a wrong ENTRY on the
  # right axis fails as loudly as a wrong axis.
  renderSlice =
    s: builtins.mapAttrs (_: v: if v ? __missing then "MISSING:${v.__missing}" else v.name) s;
  workersAt =
    den: id:
    let
      r = builtins.tryEval (den.structural.eval.get id "resolved-settings").app.value.workers;
    in
    if r.success then r.value else "THROWS";

  # ── THE §2.2b FIXTURE: env <- host <- user (the cell family) + the SIBLING root env <- cluster ─────
  # This is `ci/tests/topology-join.nix`'s own shape, not a synthetic corner. It is the fixture that
  # killed the `dimKinds`-codomain construction: `cluster` and `env` are roots whose TYPE is not a
  # product dimension, and both carry a live settings layer.
  schema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
      cluster.parent = "env";
    };
  };
  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      user.alice = { };
      cluster.k3s = { };
    };
  };
  cellMembership =
    { config, ... }:
    {
      config.den.contentClass.user = "nixos";
      config.den.membership = [
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  # THE POLLUTION VARIABLE, and the only variable between the arms below: how many BINDING keys the
  # `containTo`-marked member carries onto the target root's `decls`. Bindings are user-named, so the
  # retired `removeAttrs decls [ … ]` coordinate derivation could not have been made total against them.
  envToHost =
    bindings:
    { config, ... }:
    {
      config.den.policies.env-to-host = {
        emits = [ "member" ];
        fn =
          { env, ... }:
          [
            (declare.member {
              coords = {
                inherit env;
                host = config.den.host.axon;
              };
              inherit bindings;
              containTo = "host";
            })
          ];
      };
    };
  envToCluster =
    { config, ... }:
    {
      config.den.policies.env-to-cluster = {
        emits = [ "member" ];
        fn =
          { env, ... }:
          [
            (declare.member {
              coords = {
                inherit env;
                cluster = config.den.cluster.k3s;
              };
              containTo = "cluster";
            })
          ];
      };
    };
  appAt =
    { config, ... }:
    {
      config.den.aspects.app.settings.workers.default = 1;
      config.den.include = [
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.app ];
        }
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.app ];
        }
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
        {
          at = config.den.cluster.k3s;
          aspects = [ config.den.aspects.app ];
        }
      ];
    };
  # Witness A's isolating stack: ONE root-scoped layer, at host, value 16.
  layersA =
    { config, ... }:
    {
      config.den.settings.layers = [
        {
          at.host = config.den.host.axon;
          of = config.den.aspects.app;
          set.workers = 16;
        }
      ];
    };
  # Witness B's stack: the §2.2b layers — cluster 22, env 11, host 33.
  layersB =
    { config, ... }:
    {
      config.den.settings.layers = [
        {
          at.cluster = config.den.cluster.k3s;
          of = config.den.aspects.app;
          set.workers = 22;
        }
        {
          at.env = config.den.env.prod;
          of = config.den.aspects.app;
          set.workers = 11;
        }
        {
          at.host = config.den.host.axon;
          of = config.den.aspects.app;
          set.workers = 33;
        }
      ];
    };
  mkFleet =
    bindings: layers:
    (denHoag.mkDen [
      schema
      instances
      cellMembership
      appAt
      (envToHost bindings)
      envToCluster
      layers
    ]).den;

  cellId = "user:alice@host:axon";
  noBindings = { };
  oneBinding = {
    grant = "g";
  };
  twoBindings = {
    grant = "g";
    token = "t";
  };

  # ── WITNESS B's fleet — the POLLUTED arm, so every structural row below is read at the node class
  #    where the retired derivation was demonstrably wrong.
  denB = mkFleet twoBindings layersB;
  nodeB = denB.structural.eval.node;
  coordsB = denB.coords;

  # ── E-ROW-4's fixture: zone <- rack <- blade. One membership tuple names {zone, rack}, so BOTH are
  #    product dims — while `rack` is a PARENT kind and therefore never a candidate cell kind, so
  #    `rack:r2` is a ROOT whose containment ancestor `zone:z1` is ALSO of a dim kind. That single
  #    coordinate is the whole discriminating input: it is the only shape on which the specified SLICE
  #    rule and the cell-arm TYPE reduction give different answers.
  e4 =
    (denHoag.mkDen [
      {
        config.den.schema = {
          zone.parent = null;
          rack.parent = "zone";
          blade.parent = "rack";
        };
      }
      {
        config.den = {
          zone.z1 = { };
          rack.r2 = { };
          rack.r0 = { };
          blade.b1 = { };
        };
      }
      (
        { config, ... }:
        {
          config.den.membership = [
            {
              coords = {
                zone = config.den.zone.z1;
                rack = config.den.rack.r2;
              };
            }
          ];
        }
      )
      (
        { config, ... }:
        {
          config.den.aspects.app.settings.workers.default = 1;
          config.den.include = [
            {
              at = config.den.rack.r2;
              aspects = [ config.den.aspects.app ];
            }
            {
              at = config.den.rack.r0;
              aspects = [ config.den.aspects.app ];
            }
          ];
          config.den.settings.layers = [
            {
              at.zone = config.den.zone.z1;
              of = config.den.aspects.app;
              set.workers = 44;
            }
          ];
        }
      )
    ]).den;
  nodeE4 = e4.structural.eval.node;
  coordsE4 = e4.coords;
  # `rack` and `zone` are the product dims of THIS fleet — pinned below off the tuple's own coord names
  # rather than trusted, because the type reduction is stated in terms of them.
  e4Dims = [
    "rack"
    "zone"
  ];
  rootBaseChain = id: [
    { }
    (coordsE4.coordOf nodeE4 id)
  ];
  axisOf = s: builtins.concatStringsSep "+" (builtins.attrNames s);
  # THE SPECIFIED RULE: keep an ancestor slice `baseChain` does not already carry.
  sliceRuleAt = id: map axisOf (coordsE4.ancestorSlicesOf nodeE4 id (rootBaseChain id));
  # REVISION 2's REDUCTION, evaluated on the SAME closure in the SAME run: keep an ancestor whose TYPE
  # is not a product dim. Valid on the cell arm, UNSOUND at a root — which is what this row exhibits.
  typeRuleAt =
    id:
    map (a: (nodeE4 a).type) (
      builtins.filter (a: !(builtins.elem (nodeE4 a).type e4Dims)) (coordsE4.containAncestorIds id)
    );

  # ── G: the axis guard, re-instantiated with `settingsDims` NARROWED by one kind. An unreachable guard
  #    is indistinguishable from an absent one unless something makes it fire, so this supplies the
  #    input that trips it — and the surviving kind in the same run is what stops it reading as
  #    "the projections abort on everything".
  narrowedCoords = mkCoords {
    inherit (e4) containsEdges;
    settingsDims = [
      "zone"
      "blade"
    ]; # `rack` REMOVED
    dimKinds = e4Dims;
    isCellNode = _: false;
  };
  coordVerdict =
    c: id:
    if (builtins.tryEval (builtins.deepSeq (c.coordOf nodeE4 id) true)).success then
      "RESOLVES"
    else
      "ABORTS";

  # ── O: the traversal ORDER, at the combinator, over pools no den fleet authors ────────────────────
  # §6.7 Witness E rows 1-3 name a BRANCHING and a DIAMOND containment fleet as an input that "does not
  # exist and must be built". At the fleet level that is still true. At the POOL level it is one list of
  # triples, and the projections take the pool as an argument — so the combinator's behaviour on those
  # shapes is measurable here even though no fleet reaches them.
  synthEdge = from: to: {
    id = "contains/${from}->${to}";
    kind = "contains";
    inherit from to;
    stratum = "structural";
  };
  synthNode = id: {
    inherit id;
    type = builtins.head (builtins.match "([^:]*):.*" id);
    decls.__entry = {
      name = builtins.elemAt (builtins.match "[^:]*:(.*)" id) 0;
      id_hash = "h-${id}";
    };
  };
  synthCoords =
    edges:
    mkCoords {
      containsEdges = edges;
      settingsDims = [
        "zone"
        "rack"
        "pod"
        "blade"
      ];
      dimKinds = [ "blade" ];
      isCellNode = _: false;
    };
  # LINEAR — the corpus shape, and the control: on a chain the emission IS least-specific-first.
  linearPool = [
    (synthEdge "zone:g" "rack:a")
    (synthEdge "rack:a" "blade:d")
  ];
  # SIBLING FOREST — `blade:d` has two containment ancestors, neither reachable from the other.
  forestPool = [
    (synthEdge "rack:a" "blade:d")
    (synthEdge "pod:b" "blade:d")
  ];
  # DIAMOND — `zone:g` is reachable from `blade:d` by TWO paths through `rack:a` and `pod:b`.
  diamondPool = [
    (synthEdge "zone:g" "rack:a")
    (synthEdge "zone:g" "pod:b")
    (synthEdge "rack:a" "blade:d")
    (synthEdge "pod:b" "blade:d")
  ];
  closureOf = pool: (synthCoords pool).containAncestorIds "blade:d";
in
{
  flake.tests.containment-edges = {
    # ══ WITNESS A — the coordinate query under binding pollution ═══════════════════════════════════
    # Discriminating input: a `containTo` member carrying binding keys, at a root that has an aspect and
    # a root-scoped settings layer. The retired derivation read the coordinate off `decls` minus a fixed
    # strip list, so each added binding key moved the coordinate; the arm was then chosen by a
    # CARDINALITY match against `|dimKinds|`, which is why one key and two keys failed DIFFERENTLY (a
    # named `unknown-dim` throw at one count, a silent drop to the schema default at the other).
    # A projection indexed on a DECLARED axis set cannot see the variable at all.
    test-witness-a-coordinate-survives-binding-pollution = {
      expr = map (b: workersAt (mkFleet b layersA) "host:axon") [
        noBindings
        oneBinding
        twoBindings
      ];
      expected = [
        16
        16
        16
      ];
    };
    # THE VACUITY CONTROL for A, and it is not decoration: if the layer were inert the three rows above
    # would agree at the SCHEMA DEFAULT instead of at 16, and the witness would pass while measuring
    # nothing. `user:alice@host:axon` has no layer of its own but inherits the host slice (33 in fleet B);
    # here, under the single 16 layer, the cell reads 16 and a node the layer cannot reach reads 1.
    test-witness-a-control-default-is-distinct = {
      expr = {
        unlayered = workersAt (mkFleet twoBindings layersA) "cluster:k3s";
        schemaDefault = 1;
      };
      expected = {
        unlayered = 1;
        schemaDefault = 1;
      };
    };

    # ══ WITNESS B — the coordinate at EVERY node class ═════════════════════════════════════════════
    # Read on the POLLUTED arm throughout. Rows 1-3 are the green-must-stay-green half: `cluster:k3s`
    # and `env:prod` resolve their layers correctly TODAY, so a construction that empties a non-dim
    # root's coordinate fails them immediately — which is exactly how the `dimKinds`-codomain
    # construction was caught.
    test-witness-b-nondim-root-own-coordinate = {
      expr = {
        cluster = renderSlice (coordsB.coordOf nodeB "cluster:k3s");
        env = renderSlice (coordsB.coordOf nodeB "env:prod");
      };
      expected = {
        cluster.cluster = "k3s";
        env.env = "prod";
      };
    };
    # BEHAVIOURAL, and it cannot be satisfied by a map that merely looks right: it reads the value the
    # layer produces at a root whose type is in NEITHER `dimKinds` nor any cell coordinate.
    test-witness-b-nondim-root-values-unchanged = {
      expr = {
        cluster = workersAt denB "cluster:k3s";
        env = workersAt denB "env:prod";
      };
      expected = {
        cluster = 22;
        env = 11;
      };
    };
    # THE DIM-TYPED ROOT, on the arm where the retired derivation was polluted: its own coordinate is
    # the honest singleton, and the two binding keys are absent from it. Pinned STRUCTURALLY, so a fix
    # that moves the resolved number without fixing the map fails here.
    test-witness-b-dim-typed-root-depolluted = {
      expr = renderSlice (coordsB.coordOf nodeB "host:axon");
      expected = {
        host = "axon";
      };
    };
    # THE CELL: its product coordinate is DERIVED from the pool now, not cached at mint time, and it
    # reproduces what the cache held.
    test-witness-b-cell-product-coordinate = {
      expr = renderSlice (coordsB.cellCoordsOf nodeB cellId);
      expected = {
        host = "axon";
        user = "alice";
      };
    };
    # THE ASSERTION THAT KILLS THE "let the graph supply the keys" CONSTRUCTION: the cell's containment
    # closure REACHES `env:prod`, whose type is not a product dimension — and it still contributes no
    # key to the product coordinate. The closure row is in the same test so the axis absence is a
    # property of the projection rather than of an empty walk.
    test-witness-b-nondim-ancestor-never-an-axis = {
      expr = {
        closure = coordsB.containAncestorIds cellId;
        axes = sortStr (builtins.attrNames (coordsB.cellCoordsOf nodeB cellId));
      };
      expected = {
        closure = [
          "env:prod"
          "host:axon"
        ];
        axes = [
          "host"
          "user"
        ];
      };
    };

    # ══ WITNESS E ROW 4 — the cascade filter is a SLICE rule, not a TYPE rule ══════════════════════
    # The two candidate rules evaluated SIDE BY SIDE on the same closure in the same run. They give
    # DIFFERENT answers here, which is what makes the row a witness rather than an assertion: under the
    # type reduction the `zone` slice is dropped at a root and the resolved value falls silently to the
    # schema default. The control (`rack:r0`, same kind, same arm, no containment ancestor) is where the
    # two rules agree — so "the rules disagree" is a property of the input, not of the instrument.
    test-witness-e4-slice-rule-differs-from-type-reduction = {
      expr = {
        subject = {
          slice = sliceRuleAt "rack:r2";
          type = typeRuleAt "rack:r2";
        };
        control = {
          slice = sliceRuleAt "rack:r0";
          type = typeRuleAt "rack:r0";
        };
      };
      expected = {
        subject = {
          slice = [ "zone" ];
          type = [ ];
        };
        control = {
          slice = [ ];
          type = [ ];
        };
      };
    };
    # The behavioural half: the root arm filters NOTHING, so the dim-typed ancestor's layer reaches the
    # root. Under the type reduction this is 1.
    test-witness-e4-dim-typed-ancestor-layer-reaches-root = {
      expr = {
        subject = workersAt e4 "rack:r2";
        control = workersAt e4 "rack:r0";
      };
      expected = {
        subject = 44;
        control = 1;
      };
    };
    # The fixture's own precondition, pinned rather than trusted: the type reduction above is stated in
    # terms of `rack` and `zone` being product dims, and `rack` being a ROOT kind (not a cell kind).
    test-witness-e4-fixture-dims-and-arm = {
      expr = {
        tupleCoords = map (t: sortStr (builtins.attrNames t.coords)) e4.membershipTuples;
        cellKinds = e4.cellKinds;
      };
      expected = {
        tupleCoords = [
          [
            "rack"
            "zone"
          ]
        ];
        cellKinds = [ ];
      };
    };

    # ══ G — the axis guard FIRES ═══════════════════════════════════════════════════════════════════
    # Unreachable at HEAD by an identity (`settingsDims = dimKinds ∪ (allKinds \ cellKinds)` equals
    # `allKinds` as a set for every fleet), which is why it needs an input that trips it: the same
    # projections re-instantiated over the SAME pool with `settingsDims` narrowed by one kind. Three
    # verdicts, one instrument, one run — and the third is what distinguishes a live guard from a
    # projection that aborts on everything.
    test-coordinate-axis-guard-fires-on-a-narrowed-domain = {
      expr = {
        live-rack = coordVerdict coordsE4 "rack:r2";
        narrowed-rack = coordVerdict narrowedCoords "rack:r2";
        narrowed-surviving-zone = coordVerdict narrowedCoords "zone:z1";
      };
      expected = {
        live-rack = "RESOLVES";
        narrowed-rack = "ABORTS";
        narrowed-surviving-zone = "RESOLVES";
      };
    };

    # ══ O — the traversal ORDER under the REAL combinator ══════════════════════════════════════════
    # NEW COVERAGE, not a port: nothing anywhere pinned what the traversal emits, because the closure
    # was previously a walk over a pre-pass payload map that no branching fixture ever populated. These
    # three rows drive `graph.expandPreorder` over a `genGraphLib.transpose` adjacency — the real
    # instrument — on the three containment shapes.
    #
    # (1) LINEAR is the control and it holds: reversing the nearest-first pre-order yields the
    #     least-specific-first emission the cascade fold consumes (`zone` before `rack`).
    test-cascade-order-linear-is-least-specific-first = {
      expr = closureOf linearPool;
      expected = [
        "zone:g"
        "rack:a"
      ];
    };
    # (2) DEDUP REQUIREMENT 2, measured rather than argued: on a diamond the shared grandparent is
    #     emitted ONCE. `foldPreorder` threads one `visited` attrset across ALL roots, so
    #     first-occurrence is global rather than per-root. The forest row in the same test is the
    #     control — two ancestors, two slices — so "one" is a dedup and not an empty walk.
    test-cascade-order-diamond-emits-shared-ancestor-once = {
      expr = {
        diamondOccurrencesOfShared = builtins.length (
          builtins.filter (a: a == "zone:g") (closureOf diamondPool)
        );
        diamondClosureSize = builtins.length (closureOf diamondPool);
        forestClosureSize = builtins.length (closureOf forestPool);
      };
      expected = {
        diamondOccurrencesOfShared = 1;
        diamondClosureSize = 3;
        forestClosureSize = 2;
      };
    };
    # (3) ⚠ THE ORDER CLAIM DOES NOT SURVIVE A DIAMOND, AND THIS ROW PINS WHAT ACTUALLY HAPPENS RATHER
    #     THAN WHAT WAS CLAIMED. `reverseList`'s own comment says it "turns gen-graph's nearest-first
    #     pre-order into the least-specific-first emission the fold consumes". Reverse-of-DFS-pre-order
    #     is a topological order on a TREE, and is not one on a DAG: measured here, the shared
    #     grandparent `zone:g` lands BETWEEN its two children, so its layer would override `rack:a`'s
    #     and be overridden by `pod:b`'s — the opposite of a cascade in which an ancestor is less
    #     specific than everything beneath it.
    #
    #     This is a property of the COMBINATOR, not of this migration: the same
    #     `expandPreorder`/`reverseList` pair produced it before. What the migration changes is
    #     REACHABILITY — merging the two containment spellings into one pool makes a diamond
    #     expressible where a singleton-or-empty pre-pass map could not represent one. The claim is
    #     recorded as measured rather than adjusted to fit, and a fix that gives the traversal a real
    #     topological order should move THIS expectation deliberately.
    test-cascade-order-diamond-is-not-least-specific-first = {
      expr = closureOf diamondPool;
      expected = [
        "rack:a"
        "zone:g"
        "pod:b"
      ];
    };
  };
}
