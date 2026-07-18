# The cell/containment NEST-EDGE PRODUCER suite (vocabulary spec §4.2/§4.6, spec §12 step 4c-ii). A
# producer reads the fleet's containment structure and emits nest intents FOR NEW-VOCAB nest relationships
# only — gated by `resolveReceiver` (the receiver-gate predicate), so it emits ZERO on a corpus-shaped
# receives table (no receives rows on containment kinds). Each intent carries the readable `id` + the inner's
# real content payload in the keyedValue `value`; the graft is proven through `resolveReceiver` + `executeNest`
# (the content arm), and the intents ride `assembleEdges` as substrate citizens (identity/override/
# acyclicity + the trace, which excludes the payload). The singular mount check (`nest.checkSingular`) folds
# in HERE: the producer is the first real singular-mount call site. See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  inherit (denHoag.internal)
    containmentPairs
    nestProducer
    compileProducts
    compileEdges
    receivers
    assembleEdges
    edge
    ;
  frameworkProducts = compileProducts { };

  # A synthetic 2-cell fleet: host `hh` with two user cells (u1, u2). den.fleet + den.meta feed the thin
  # containment accessor; den.kinds (root-only, the corpus shape) proves the receiver gate's corpus-inertness.
  synthFleet = denHoag.mkDen [
    {
      config.den.schema = {
        host.parent = null;
        user.parent = "host";
      };
    }
    {
      config.den = {
        host.hh = { };
        user.u1 = { };
        user.u2 = { };
      };
    }
    (
      { config, ... }:
      {
        config.den.membership = [
          {
            coords = {
              host = config.den.host.hh;
              user = config.den.user.u1;
            };
          }
          {
            coords = {
              host = config.den.host.hh;
              user = config.den.user.u2;
            };
          }
        ];
      }
    )
  ];
  pairs = containmentPairs {
    fleet = synthFleet.den.fleet;
    meta = synthFleet.den.meta;
  };

  # A CONTENT-mode receives row on `host.receives.user` (consumes ModulesInfo, its `at` the nixos-nested
  # home-manager path) — compiled so `mode` is DERIVED (F1). `manyKinds` = arity many (the default);
  # `singularKinds` = arity singular (the mount whose live set must be ≤ 1).
  mkKinds =
    arity:
    receivers.compile {
      rows = {
        host.receives.user = {
          at = point: _inner: [
            "hm"
            "users"
            point.name
          ];
          consumes = "ModulesInfo";
        }
        // arity;
      };
      knownKinds = [
        "host"
        "user"
      ];
      products = frameworkProducts;
      renders = { };
    };
  manyKinds = mkKinds { };
  singularKinds = mkKinds { arity = "singular"; };

  # the containment kind → content-class string map (the child's/parent's content class), supplied to the
  # producer (never re-derived from the fleet — den.meta keeps contentClass den-side null).
  classOf =
    k:
    {
      host = "nixos";
      user = "hm";
    }
    .${k};
  # the child's content payload — a ModulesInfo slice (a one-module list). The producer injects it into the
  # keyedValue `value`; the executor grafts it at the row's `at`.
  payloadFor = childId: [ { hmMod = childId; } ];
  # a POISON payload: forcing any module throws. The trace must stay lazy over it (§2.1 — value.value is
  # excluded from the trace by construction).
  poisonPayloadFor = _childId: [ (throw "payload forced — trace laziness violated") ];

  # the fold's `place` primitive as a LOCAL twin (output-modules.nix's `nestAtPath` is un-exported) — the
  # GRAFT oracle wraps INDEPENDENTLY so the leg is non-circular.
  nestAtPath =
    path: value:
    if path == [ ] then value else { ${builtins.head path} = nestAtPath (builtins.tail path) value; };

  # an edge-kind table carrying the framework `nest` kind (output stratum) — for the substrate/trace leg.
  nestEdgeKinds = compileEdges {
    kinds = { };
    strataOrder = [
      "structural"
      "resolution"
      "collection"
      "demand"
      "output"
    ];
  };

  u1Id = "nest:host:hh/user:u1@host:hh:user";
  u2Id = "nest:host:hh/user:u2@host:hh:user";

  # the shared many-arity production set (the graft + intent + trace oracles all read it). The poison-
  # payload and singular scenarios build their own sets (a distinct payload / a singular receives table).
  manyProds = nestProducer {
    compiledKinds = manyKinds;
    inherit pairs classOf payloadFor;
  };
in
{
  flake.tests.nest-producers = {
    # ── the thin containment accessor (fleet.nix) ──
    # every cell contributes one (immediate parent → child) pair per coordinate dim carrying a parent dim
    # present in the cell; the corpus's scope-root dims (env) contribute none. The 2-cell fleet ⇒ 2 pairs.
    test-containment-pairs = {
      expr = builtins.sort (a: b: a.childId < b.childId) (
        map (p: {
          inherit (p)
            parentId
            parentKind
            childId
            childKind
            childName
            ;
        }) pairs
      );
      expected = [
        {
          parentId = "host:hh";
          parentKind = "host";
          childId = "user:u1@host:hh";
          childKind = "user";
          childName = "u1";
        }
        {
          parentId = "host:hh";
          parentKind = "host";
          childId = "user:u2@host:hh";
          childKind = "user";
          childName = "u2";
        }
      ];
    };

    # ── ORACLE #1: the producer emits EXACTLY the expected nest intents (many arity) ──
    # 2 productions, each parent-targeted (to = host:hh), carrying the child's payload in the keyedValue
    # `value` (intent.data) + a readable id + kind/mode = nest + the resolved `at` path.
    test-nest-producer-emits-expected = {
      expr =
        let
          prods = manyProds;
          byId = builtins.listToAttrs (
            map (p: {
              name = p.id;
              value = p;
            }) prods
          );
          p = byId.${u1Id};
        in
        {
          count = builtins.length prods;
          ids = builtins.sort (a: b: a < b) (map (x: x.id) prods);
          toEntity = p.intent.to.entityId;
          fromEntity = p.intent.from.entityId;
          kind = p.intent.kind;
          mode = p.intent.mode;
          path = p.intent.path;
          data = p.intent.data;
        };
      expected = {
        count = 2;
        ids = [
          u1Id
          u2Id
        ];
        toEntity = "host:hh";
        fromEntity = "user:u1@host:hh";
        kind = "nest";
        mode = "nest";
        path = [
          "hm"
          "users"
          "u1"
        ];
        data = [ { hmMod = "user:u1@host:hh"; } ];
      };
    };

    # ── ORACLE #2: the GRAFT (resolveReceiver + executeNest content arm) ──
    # the production's contribution places the payload at the row's `at` path, byte-identical to an
    # INDEPENDENTLY-constructed placement (the graft leg, NOT id(x)==x).
    test-nest-producer-graft = {
      expr =
        let
          p = builtins.head (builtins.filter (x: x.id == u1Id) manyProds);
          at = [
            "hm"
            "users"
            "u1"
          ];
          expectedModules = map (nestAtPath at) (payloadFor "user:u1@host:hh");
        in
        {
          mode = p.contribution.mode;
          matchesIndependent = p.contribution.modules == expectedModules;
        };
      expected = {
        mode = "content";
        matchesIndependent = true;
      };
    };

    # ── ORACLE #3: the TRACE excludes the content thunk ──
    # a POISON payload rides the keyedValue `value`; deep-forcing the assembleEdges TRACE must NOT throw
    # (only shape/id/path/kind are forced — the payload stays lazy, §2.1 sourceIdentity excludes it).
    test-nest-producer-trace-excludes-payload = {
      expr =
        let
          prods = nestProducer {
            compiledKinds = manyKinds;
            inherit pairs classOf;
            payloadFor = poisonPayloadFor;
          };
          records = assembleEdges {
            kinds = nestEdgeKinds;
            intents = map (p: p.intent) prods;
          };
          tr = edge.trace records;
        in
        (builtins.tryEval (builtins.deepSeq tr true)).success;
      expected = true;
    };
    # …and the trace entries carry the nest KIND + the placement path (substrate citizenship): the sort
    # key's P component is the `at` path and the entry names kind = nest.
    test-nest-producer-trace-carries-nest = {
      expr =
        let
          records = assembleEdges {
            kinds = nestEdgeKinds;
            intents = map (p: p.intent) manyProds;
          };
          entries = edge.trace records;
          e = builtins.head entries;
        in
        {
          kinds = builtins.sort (a: b: a < b) (map (x: x.kind) entries);
          firstMode = e.mode;
          firstPathNonEmpty = e.path != [ ];
        };
      expected = {
        kinds = [
          "nest"
          "nest"
        ];
        firstMode = "nest";
        firstPathNonEmpty = true;
      };
    };

    # ── ORACLE #4: checkSingular at the mount, driven THROUGH the producer ──
    # two `when`-firing intents into ONE singular mount (host receives.user, arity singular) → the producer's
    # mount check throws NAMED (checkSingular names the mount + every tied id).
    test-nest-producer-singular-two-live-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (nestProducer {
            compiledKinds = singularKinds;
            inherit pairs classOf payloadFor;
          }) null
        )).success;
      expected = false;
    };
    # …one intent `when = false` → filtered before the check → a single live intent PASSES (the producer
    # returns exactly the one live production).
    test-nest-producer-singular-one-false-passes = {
      expr =
        let
          whenFor = childId: childId != "user:u2@host:hh";
          prods = nestProducer {
            compiledKinds = singularKinds;
            inherit
              pairs
              classOf
              payloadFor
              whenFor
              ;
          };
        in
        {
          count = builtins.length prods;
          liveId = (builtins.head prods).id;
        };
      expected = {
        count = 1;
        liveId = u1Id;
      };
    };

    # ── ORACLE #5: the CORPUS producer set is [] (the receiver gate, corpus-inert) ──
    # a corpus-shaped receives table (den.kinds = root only — NO receives on host/user) gates every
    # containment pair out (compiledKinds lacks the parent kind), so the producer emits nothing. The parity
    # gate proves the byte-identity that follows (the producer surface is disjoint from the corpus trace).
    test-nest-producer-corpus-inert = {
      expr = builtins.length (nestProducer {
        compiledKinds = synthFleet.den.kinds;
        inherit pairs classOf payloadFor;
      });
      expected = 0;
    };
  };
}
