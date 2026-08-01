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
#   O  the closure ORDER under the real combinator, on fixtures no den fleet authors — and, since the
#      order is only ever a means, the resolved CASCADE VALUE the order decides (rows 4-5). The DIAMOND
#      is the discriminating input for all of them: every construction ever proposed here agrees on a
#      tree, so a corpus-shaped fixture cannot tell a topological order from a reversed pre-order.
{
  denHoag,
  denHoagSrc,
  ...
}:
let
  inherit (denHoag) sel;
  inherit (denHoag) declare;
  prelude = denHoag.internal.prelude;
  graph = denHoag.internal.genGraph;
  errors = import "${denHoagSrc}/lib/errors.nix";
  settings = denHoag.internal.settings;
  settingsLib = denHoag.internal.settingsLib;
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
        selects = sel.star;
        # The binding codomain is read off the very attrset the body emits, so the declaration cannot
        # disagree with the emission for any argument this fixture is instantiated with.
        binds = builtins.attrNames bindings;
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
        selects = sel.star;
        binds = [ ];
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

  reverseL =
    xs:
    let
      l = builtins.length xs;
    in
    builtins.genList (n: builtins.elemAt xs (l - n - 1)) l;

  # ── O2: is the CASCADE VALUE order-sensitive across a diamond? ────────────────────────────────────
  # The order rows above measure a SEQUENCE. This block measures the thing the sequence is FOR: the
  # resolved settings value. It exists because "does the cascade require a topological order, or only
  # determinism plus dedup?" is answerable by construction — put the SAME settings key at two ancestors
  # and see whether the resolved value moves when their emission order does — and answering it by
  # reading gen-settings' fold would have been an argument, not a measurement.
  #
  # The layer pair is the DISCRIMINATING input: `zone:g` and `rack:a` are COMPARABLE (`zone:g` contains
  # `rack:a`), so a cascade owes a definite answer here — the contained one is more specific and must
  # win. Two incomparable ancestors would not discriminate: nothing orders them, so either answer is
  # admissible and the fixture could not tell a topological order from an arbitrary one.
  #
  # `at = { zone = … }` validates because the layer domain is `settingsDims` (`unique (dimKinds ++
  # rootScopeKinds)`, lib/default.nix), NOT `dimKinds` — a containment ancestor that is no product axis
  # still carries a layer. That is what closes the "the two are always separated by some other
  # mechanism" escape: nothing keeps a grandparent's layer and a child's layer out of one fold.
  probeAspect = {
    name = "cascade";
    id_hash = "h-cascade";
  };
  probeSchema = settingsLib.mkSchemaFor probeAspect {
    workers = {
      default = "DEFAULT";
    };
  };
  probeLayers = settingsLib.compileLayers {
    productDims = [
      "zone"
      "rack"
      "pod"
      "blade"
    ];
    layers = [
      {
        at = {
          zone = (synthNode "zone:g").decls.__entry;
        };
        of = probeAspect;
        set.workers = "FROM-zone";
      }
      {
        at = {
          rack = (synthNode "rack:a").decls.__entry;
        };
        of = probeAspect;
        set.workers = "FROM-rack";
      }
    ];
  };
  # resolved-settings' ROOT-arm chain, verbatim (`synthCoords` tags every node a non-cell): the empty
  # slice, then the ancestor slices, then the node's own. `reorder` is the experimental variable and
  # the ONLY thing that differs between the rows — same pool, same layers, same fold.
  probeResolveAt =
    pool: reorder:
    let
      c = synthCoords pool;
      baseChain = [
        { }
        (c.coordOf synthNode "blade:d")
      ];
      ancSlices = reorder (c.ancestorSlicesOf synthNode "blade:d" baseChain);
      chain = [ (builtins.head baseChain) ] ++ ancSlices ++ (builtins.tail baseChain);
      layersAtSlice =
        sliceFixed:
        let
          here = builtins.filter (
            l: l.of.id_hash == probeAspect.id_hash && c.coordsEq l.atCoords sliceFixed
          ) probeLayers;
        in
        map settingsLib.toGenLayer (
          builtins.filter (l: l.via != null) here ++ builtins.filter (l: l.via == null) here
        );
      layers = prelude.concatMap layersAtSlice chain;
      resolved = settings.resolveAll {
        batch = [
          {
            schema = probeSchema;
            inherit layers;
            key = probeAspect.name;
          }
        ];
      };
    in
    {
      # ★ THE VACUITY GUARDS RIDE IN THE ANSWER. A fold over zero layers resolves to the schema default
      # and would report "the order does not matter" for the wrong reason, so the chain length and the
      # layer count are asserted beside the winner rather than trusted.
      winner = resolved.value.${probeAspect.name}.workers;
      chainLen = builtins.length chain;
      layerCount = builtins.length layers;
    };

  # ── O3: the OTHER consumer of the ancestor sequence (acceptance criterion e) ───────────────────────
  # `containAncestorIds` has three readers. `ancestorSlicesOf` → the settings cascade is measured above
  # and IS order-sensitive. `cellCoordsOf` reduces its ancestor list to the UNIQUE type-`d` member (a
  # singleton or a NAMED collision abort), so its answer is a function of the SET — and the suite pins it
  # (witness B) across this change. The third is `resolved-aspects`' §B4a visibility set, and it is the
  # one that takes the sequence as an INSTANCE ARGUMENT, so it can be driven under a permutation.
  #
  # THE PREDICATE IS "the computed value moves when the ancestor SEQUENCE is permuted", and the row below
  # carries its own POSITIVE CONTROL on that same predicate in the same run: `oneAncestorOnly` drops an
  # ancestor from the SET, and the answer moves. An instrument that cannot see the ancestor set at all
  # would report "order-independent" identically, which is the shape this control exists to exclude.
  eAspect = name: { inherit name; };
  eCarrier = {
    name = "carrier";
    neededBy = [ (eAspect "alpha") ];
  };
  eNode = {
    parent = null;
    decls = { };
  };
  # A stub `self` for `resolved-aspects.compute`: two ancestors each holding one resolved aspect, and a
  # target holding none of its own — so every key in `visible` arrives through the ancestor query.
  eStub = {
    get =
      id: attr:
      if attr == "resolved-aspects" then
        {
          "anc:1" = [
            {
              key = "alpha";
              content = eAspect "alpha";
            }
          ];
          "anc:2" = [
            {
              key = "beta";
              content = eAspect "beta";
            }
          ];
        }
        .${id} or [ ]
      else if attr == "enriched-context" then
        { }
      else if attr == "declarations" then
        { actions.resolution = [ ]; }
      else
        throw "containment-edges stub: unexpected attr ${attr}";
    node = _id: eNode;
  };
  eResolvedKeysWith =
    ancestorIds:
    map (n: n.key) (
      (import "${denHoagSrc}/lib/attributes/resolved-aspects.nix"
        {
          inherit prelude graph;
          inherit (denHoag.internal)
            scope
            resolve
            aspects
            select
            ;
        }
        {
          allAspects.carrier = eCarrier;
          directIncludes = [ ];
          containAncestorIds = _nid: ancestorIds;
        }
      ).resolved-aspects.compute
        eStub
        "tgt:d"
    );
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

    # ══ O — the closure ORDER, and the cascade VALUE it decides, under the REAL combinators ═════════
    # NEW COVERAGE, not a port: nothing anywhere pinned what the closure emits, because it was
    # previously a walk over a pre-pass payload map that no branching fixture ever populated. These rows
    # drive `graph.expandPreorder` + `graph.coneRank` over a `genGraphLib.transpose` adjacency — the real
    # instruments — on the three containment shapes, and then drive `gen-settings.resolveAll` over the
    # result, because a claim about an order is only ever a claim about the value the order produces.
    #
    # (1) LINEAR is the control and it holds: the closure is least-specific-first (`zone` before `rack`),
    #     which is what the cascade fold consumes. It is also the row that CANNOT discriminate — every
    #     construction proposed for this closure agrees on a chain, which is why rows 3-4 exist.
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
    # (3) THE ORDER HOLDS ON A DIAMOND — and this expectation MOVED, deliberately, when it was made to.
    #     Its predecessor pinned `[ rack:a, zone:g, pod:b ]` under the caption "the order claim does not
    #     survive a diamond": the closure was the DFS pre-order reversed, which is a topological order on
    #     a TREE and is not one on a DAG, so the shared grandparent `zone:g` landed BETWEEN its own two
    #     children. That row existed to make installing a real order a VISIBLE decision rather than a
    #     silent change, and this is that decision — the reversal is gone and `coneRank` (gen-graph, a
    #     producers-first rank over the ancestor cone) supplies the order, with `expandPreorder` left
    #     answering membership only.
    #
    #     `zone:g` now leads, ahead of BOTH the children that contain `blade:d`. The residual freedom is
    #     between `pod:b` and `rack:a` — genuinely incomparable, so no topological order fixes them
    #     relative to each other; `coneRank`'s `(depth, name)` sort is what makes that residue canonical
    #     rather than an artefact of the walk.
    test-cascade-order-diamond-is-least-specific-first = {
      expr = closureOf diamondPool;
      expected = [
        "zone:g"
        "pod:b"
        "rack:a"
      ];
    };
    # (4) ★ THE CASCADE IS ORDER-SENSITIVE ACROSS A DIAMOND — the measurement that decides whether a
    #     topological order is REQUIRED or whether determinism plus dedup would do. Same pool, same two
    #     layers, same fold; the ancestor sequence is the only variable.
    #
    #       `diamondShipped`  the shipped order   → the CONTAINED node's layer wins
    #       `diamondPermuted` the same two layers, ancestor sequence reversed → the CONTAINER's wins
    #
    #     Two different values from one containment relation ⇒ the resolved value is a function of the
    #     emission order, so a merely deterministic order would be deterministically WRONG on half the
    #     diamonds. gen-settings is explicit that it will not rescue this: its fold is positional ("for
    #     `replace`, the last contributor wins") and it deliberately does not reorder — the ORDER IS THE
    #     SEMANTICS, and supplying a correct one is this layer's obligation.
    #
    #     `linearControl` is the same relation `zone:g ⊃ rack:a` drawn as a CHAIN, where the answer was
    #     never in doubt. Agreement between it and `diamondShipped` is the statement that a second path
    #     to a grandparent no longer changes what a cascade means; under the pre-`coneRank` order the two
    #     disagreed (the chain resolved `FROM-rack`, the diamond `FROM-zone`).
    #
    #     ★ AND DETERMINISM WAS NEVER THE MISSING HALF — measured, not assumed. Re-running these rows
    #     against the pre-`coneRank` closure gives `diamondShipped = FROM-zone` / `diamondPermuted =
    #     FROM-rack`: the two branches swap, so the OLD order was wrong, but it was not UNSTABLE. It could
    #     not be: gen-graph's `transpose` materializes through `builtins.attrNames`, which sorts, so
    #     `containEdges` answers in id order and the DFS root order is canonical however the triples were
    #     declared — a permutation of the pool is a no-op on BOTH constructions, which is why no such row
    #     appears here (it would assert an equivalence with no input that could break it, the vacuity this
    #     file's header forbids). "Determinism plus dedup" was already satisfied and was already wrong.
    #     TOPOLOGICALITY is the property that was missing, and only a DAG separates the two.
    test-cascade-value-is-order-sensitive-across-a-diamond = {
      expr = {
        diamondShipped = probeResolveAt diamondPool (xs: xs);
        diamondPermuted = probeResolveAt diamondPool reverseL;
        linearControl = probeResolveAt linearPool (xs: xs);
      };
      expected = {
        diamondShipped = {
          winner = "FROM-rack";
          chainLen = 5;
          layerCount = 2;
        };
        diamondPermuted = {
          winner = "FROM-zone";
          chainLen = 5;
          layerCount = 2;
        };
        linearControl = {
          winner = "FROM-rack";
          chainLen = 4;
          layerCount = 2;
        };
      };
    };
    # (5) ACCEPTANCE CRITERION (e): the OTHER consumer of the ancestor sequence does not read the order.
    #     `resolved-aspects` folds the closure into the §B4a visibility KEYSET (`acc // keysAt aid` over
    #     `{ key = true; }` attrsets), so the sequence cannot survive into it. Measured rather than read:
    #     the same ancestor SET in both orders resolves the same carrier, and `oneAncestorOnly` — the
    #     POSITIVE CONTROL on the same predicate in the same run — drops `anc:1` from the SET and the
    #     answer moves, which is what distinguishes "order-independent" from "blind to its ancestors".
    test-ancestor-sequence-is-read-only-by-the-settings-cascade = {
      expr = {
        forward = eResolvedKeysWith [
          "anc:1"
          "anc:2"
        ];
        reversed = eResolvedKeysWith [
          "anc:2"
          "anc:1"
        ];
        oneAncestorOnly = eResolvedKeysWith [ "anc:2" ];
      };
      expected = {
        forward = [ "carrier" ];
        reversed = [ "carrier" ];
        oneAncestorOnly = [ ];
      };
    };
  };
}
