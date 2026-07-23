# The COLLECTOR FRAMEWORK-KIND suite (vocabulary spec §4.7, spec §12 step 4c-iii). A collector is
# a first-class ENTITY of the framework `collector` kind: `den.collectors.<name> = { class; … }` bridges into
# the entity registry (`den.collector.<name>`, an id_hash-bearing root node), so a collector carries its OWN
# class content DISTINCT from any member's. The kind is framework-owned: `discoverKinds` reserves the name
# (a user kind may not be `collector`), and it enters `denMeta` by a `//`-augment GATED on `den.collectors !=
# {}` — so a fleet with no collectors has no collector kind/registry (corpus-inert). The collector's producing
# class is a PER-INSTANCE function of its own `class` field (`contentClass.collector = e: effectiveClassEntries
# .${e.class}`, the shim's per-host function precedent); a collector naming an unregistered class aborts NAMED
# (never a bare attr-miss). See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  inherit (denHoag) hasClass;

  # A class slice is a list of `{ imports = [ … ]; }` modules (den content is module-wrapped), so the
  # marker `meta.tag = "core"` rides nested — deep-search for an attrset carrying `meta.tag == "core"`.
  hasMetaTagCore =
    v:
    if builtins.isAttrs v then
      (builtins.isAttrs (v.meta or null) && (v.meta.tag or null) == "core")
      || builtins.any hasMetaTagCore (builtins.attrValues v)
    else if builtins.isList v then
      builtins.any hasMetaTagCore v
    else
      false;

  # A collector `hive` (class colmena, own content `meta.tag = "core"`) beside an ordinary nixos member `m`
  # carrying plain nixos content with NO `meta.tag`. `colmena` is a user-registered output class (so its
  # aspect key classifies + `contentClass.collector` resolves it); the collector + the member are separate
  # parentless root entities — the contrast that proves the collector's own content is distinct.
  collectorFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.classes.colmena = { };
      config.den.collectors.hive = {
        class = "colmena";
      };
      config.den.host.m = { };
    }
    (
      { config, ... }:
      {
        config.den.aspects.hiveMeta.colmena.meta.tag = "core";
        config.den.aspects.memberPlain.nixos.services.enable = true;
        config.den.include = [
          {
            at = config.den.collector.hive;
            aspects = [ config.den.aspects.hiveMeta ];
          }
          {
            at = config.den.host.m;
            aspects = [ config.den.aspects.memberPlain ];
          }
        ];
      }
    )
  ];

  # A corpus-shaped fleet with NO `den.collectors`: the collector kind must be structurally absent.
  plainFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.host.m = { };
    }
  ];

  # A collector naming a class that is NOT registered (`phantom` ∉ den.classes ∪ built-ins) — the guard's
  # subject: reading the compiled `den.collectors` surface must abort NAMED, not silently attr-miss.
  badClassFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.collectors.ghost = {
        class = "phantom";
      };
    }
  ];

  # A collector with `class` OMITTED — the field is optional (default null), so BOTH guards must null-guard
  # BEFORE any string selector (a null attr selector is a tryEval-uncatchable coercion the `or` never
  # intercepts). Exercised on the compiled surface AND the classOf/materialization path (forcing `systems`
  # computes every node's producing class → the orphan collector's `contentClassFn`).
  omittedClassFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.collectors.orphan = { };
      config.den.host.m = { };
    }
  ];

  collectorSlice = collectorFleet.den.output.classSubtreeAt "collector:hive" "colmena";
  memberSlice = collectorFleet.den.output.classSubtreeAt "host:m" "nixos";

  # ── §4.7: SELECTOR-DRIVEN MEMBERSHIP + the member-edge producer ──
  # `hasClass "nixos"` (the top-level sugar, written literally in config — A1 ergonomics) selects the scope
  # nodes whose PRODUCING class is `nixos`. A fleet with a nixos host `n`, a darwin host `d`, and a class-
  # NEUTRAL env `e` (no contentClass) beside a collector `members = hasClass "nixos"`: the member producer must
  # emit `member` edges `collector→member` targeting ONLY the nixos node — including `n`, EXCLUDING `d` (the
  # selector rejects non-matching) AND `e` (the null-guard: a class-neutral node must not crash the gather).
  memberFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.schema.darwinHost.parent = null;
      config.den.schema.env.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.contentClass.darwinHost = "darwin";
      config.den.classes.colmena = { };
      config.den.collectors.hive = {
        class = "colmena";
        members = hasClass "nixos";
      };
      config.den.nixosHost.n = { };
      config.den.darwinHost.d = { };
      config.den.env.e = { };
    }
  ];
  memberEdges = memberFleet.den.memberEdges;
  memberTargets = map (edge: edge.to.entityId) memberEdges;

  # ── §4.7: the AGGREGATE render → AggregateInfo + the gather-then-render mount ──
  # A collector `cluster` (class colmena, consumes RawModulesInfo) over TWO nixos members (a, b) each carrying
  # DISTINCT resolved content. Its aggregate render `colmenaAgg` (evaluator memberMap → AggregateInfo, tagged
  # `aggregate = true`) is called ONCE over the gathered member map and VALUE-mode nests into root via the
  # render's `output` family `colmenaHive` (consumes AggregateInfo). The stub evaluator proves the aggregate crossing
  # is a swappable `evaluator` FIELD (the seam), never hardcoded in the mount flow.
  mkAggFleet =
    evaluator:
    denHoag.mkDen [
      {
        config.den.schema.nixosHost.parent = null;
        config.den.contentClass.nixosHost = "nixos";
        config.den.classes.colmena = { };
        config.den.collectors.cluster = {
          class = "colmena";
          members = hasClass "nixos";
          consumes = "RawModulesInfo";
          render = "colmenaAgg";
        };
        config.den.renders.colmenaAgg = {
          inherit evaluator;
          produces = "AggregateInfo";
          aggregate = true;
          output = "colmenaHive";
        };
        config.den.outputs.colmenaHive = {
          at = _point: e: [
            "colmenaHive"
            e.name
          ];
          consumes = "AggregateInfo";
        };
        config.den.nixosHost.a = { };
        config.den.nixosHost.b = { };
      }
      (
        { config, ... }:
        {
          config.den.aspects.aContent.nixos.tag = "a-content";
          config.den.aspects.bContent.nixos.tag = "b-content";
          config.den.include = [
            {
              at = config.den.nixosHost.a;
              aspects = [ config.den.aspects.aContent ];
            }
            {
              at = config.den.nixosHost.b;
              aspects = [ config.den.aspects.bContent ];
            }
          ];
        }
      )
    ];
  aggFleet = mkAggFleet (memberMap: {
    built = memberMap;
  });
  aggSwapped = mkAggFleet (memberMap: {
    swapped = memberMap;
  });
  aggHive = aggFleet.outputs.colmenaHive.cluster;

  # ── the three misuse guards (all CATCHABLE-NAMED, never bare crashes) ──
  # a collector whose render is NOT an aggregate render (aggregate defaults false).
  nonAggFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.classes.colmena = { };
      config.den.collectors.cluster = {
        class = "colmena";
        members = hasClass "nixos";
        consumes = "RawModulesInfo";
        render = "perConfig";
      };
      config.den.renders.perConfig = {
        evaluator = _: { };
        produces = "AggregateInfo";
        output = "colmenaHive";
      };
      config.den.outputs.colmenaHive = {
        at = _point: e: [
          "colmenaHive"
          e.name
        ];
        consumes = "AggregateInfo";
      };
      config.den.nixosHost.a = { };
    }
  ];
  # render.produces (AggregateInfo) ≠ family.consumes (SystemInfo) — the mounted-out shape mismatch.
  mismatchFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.classes.colmena = { };
      config.den.collectors.cluster = {
        class = "colmena";
        members = hasClass "nixos";
        consumes = "RawModulesInfo";
        render = "colmenaAgg";
      };
      config.den.renders.colmenaAgg = {
        evaluator = m: m;
        produces = "AggregateInfo";
        aggregate = true;
        output = "mismFam";
      };
      config.den.outputs.mismFam = {
        at = _point: e: [
          "mismFam"
          e.name
        ];
        consumes = "SystemInfo";
      };
      config.den.nixosHost.a = { };
    }
  ];
  # a per-config artifact opt-in family pointed at an AGGREGATE render (the symmetric guard).
  symFleet = denHoag.mkDen [
    {
      config.den.schema.user.parent = null;
      config.den.contentClass.user = "nixos";
      config.den.user.u.outputs.badFam = { };
      config.den.renders.aggR = {
        evaluator = m: m;
        produces = "SystemInfo";
        aggregate = true;
      };
      config.den.outputs.badFam = {
        at = _point: e: [
          "badFam"
          e.name
        ];
        consumes = "SystemInfo";
        render = "aggR";
        contentClass = "nixos";
      };
    }
  ];
  # an aggregate render OMITTING `output` — the compiled render row always carries `output` (default null), so
  # a `.output or (throw)` would be dead and `outputsTable.${null}` a bare `.${null}` crash escaping tryEval;
  # the explicit null-guard makes it CATCHABLE-NAMED.
  noOutputFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.classes.colmena = { };
      config.den.collectors.cluster = {
        class = "colmena";
        members = hasClass "nixos";
        consumes = "RawModulesInfo";
        render = "noOut";
      };
      config.den.renders.noOut = {
        evaluator = m: m;
        produces = "AggregateInfo";
        aggregate = true;
      };
      config.den.nixosHost.a = { };
    }
  ];

  # ── §4.7: the GENERICITY witness (consumes IS the abstraction, genericity floor 4) ──
  # TWO collectors over the SAME member set (a, b) differing ONLY in `consumes` (+ render): `cluster` consumes
  # RawModulesInfo (content → the raw class slice), `deploy` consumes SystemInfo (artifact → the already-built
  # system, the deploy-rs/agenix shape). NO colmena/deploy-rs field anywhere in the kernel — the extraction
  # dispatches on the consumed product's MODE alone, so ONE machine turns the same member set into two payload
  # shapes. Both renders are opaque stubs producing AggregateInfo into their own families.
  # ONE shared `members` selector — so the two collector records are provably identical in `members` (distinct
  # `hasClass "nixos"` calls would be equal-but-incomparable closures), which the structural genericity assert
  # below relies on to prove they differ ONLY in consumes+render.
  genericMembers = hasClass "nixos";
  genericFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.classes.colmena = { };
      config.den.collectors.cluster = {
        class = "colmena";
        members = genericMembers;
        consumes = "RawModulesInfo";
        render = "modAgg";
      };
      config.den.collectors.deploy = {
        class = "colmena";
        members = genericMembers;
        consumes = "SystemInfo";
        render = "sysAgg";
      };
      config.den.renders.modAgg = {
        evaluator = m: {
          built = m;
        };
        produces = "AggregateInfo";
        aggregate = true;
        output = "modHive";
      };
      config.den.renders.sysAgg = {
        evaluator = m: {
          built = m;
        };
        produces = "AggregateInfo";
        aggregate = true;
        output = "sysHive";
      };
      config.den.outputs.modHive = {
        at = _point: e: [
          "modHive"
          e.name
        ];
        consumes = "AggregateInfo";
      };
      config.den.outputs.sysHive = {
        at = _point: e: [
          "sysHive"
          e.name
        ];
        consumes = "AggregateInfo";
      };
      config.den.nixosHost.a = { };
      config.den.nixosHost.b = { };
    }
    (
      { config, ... }:
      {
        config.den.aspects.aContent.nixos.tag = "a-content";
        config.den.aspects.bContent.nixos.tag = "b-content";
        config.den.include = [
          {
            at = config.den.nixosHost.a;
            aspects = [ config.den.aspects.aContent ];
          }
          {
            at = config.den.nixosHost.b;
            aspects = [ config.den.aspects.bContent ];
          }
        ];
      }
    )
  ];
  modHive = genericFleet.outputs.modHive.cluster.built;
  sysHive = genericFleet.outputs.sysHive.deploy.built;

  # a SystemInfo collector over a member with a CLASS (hasClass matches) but NO content — absent from
  # output.systems, so the artifact read must NAMED-throw, never a bare `.${id}` miss (the M1 class).
  missSysFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.classes.colmena = { };
      config.den.collectors.deploy = {
        class = "colmena";
        members = hasClass "nixos";
        consumes = "SystemInfo";
        render = "sysAgg";
      };
      config.den.renders.sysAgg = {
        evaluator = m: {
          built = m;
        };
        produces = "AggregateInfo";
        aggregate = true;
        output = "sysHive";
      };
      config.den.outputs.sysHive = {
        at = _point: e: [
          "sysHive"
          e.name
        ];
        consumes = "AggregateInfo";
      };
      config.den.nixosHost.void = { };
    }
  ];

  # ── §4.7: the `members` family-level SUGAR (desugar → anonymous collector) ──
  # A NAMED collector `hive` vs the family-level SUGAR `den.outputs.hive2.members = { of; consumes }`, both over
  # the SAME member set with the SAME aggregate render evaluator + member product. The sugar synthesizes a REAL
  # anonymous collector `members:hive2` (a registry entity with an id_hash) that flows through the SAME kernel —
  # so the AggregateInfo AGGREGATE VALUE (the member-name-keyed map INSIDE) is byte-identical across named/sugar,
  # though the face keys (family key + leaf name) differ by construction.
  aggEvaluator = memberMap: {
    built = memberMap;
  };
  memberBase = {
    config.den.schema.nixosHost.parent = null;
    config.den.contentClass.nixosHost = "nixos";
    config.den.classes.colmena = { };
    config.den.nixosHost.a = { };
    config.den.nixosHost.b = { };
  };
  memberContent = (
    { config, ... }:
    {
      config.den.aspects.aContent.nixos.tag = "a-content";
      config.den.aspects.bContent.nixos.tag = "b-content";
      config.den.include = [
        {
          at = config.den.nixosHost.a;
          aspects = [ config.den.aspects.aContent ];
        }
        {
          at = config.den.nixosHost.b;
          aspects = [ config.den.aspects.bContent ];
        }
      ];
    }
  );
  namedFleet = denHoag.mkDen [
    memberBase
    memberContent
    {
      config.den.collectors.hive = {
        class = "colmena";
        members = hasClass "nixos";
        consumes = "RawModulesInfo";
        render = "namedAgg";
      };
      config.den.renders.namedAgg = {
        evaluator = aggEvaluator;
        produces = "AggregateInfo";
        aggregate = true;
        output = "hiveFam";
      };
      config.den.outputs.hiveFam = {
        at = _point: e: [
          "hiveFam"
          e.name
        ];
        consumes = "AggregateInfo";
      };
    }
  ];
  sugarFleet = denHoag.mkDen [
    memberBase
    memberContent
    {
      config.den.renders.sugarAgg = {
        evaluator = aggEvaluator;
        produces = "AggregateInfo";
        aggregate = true;
        output = "hive2";
      };
      config.den.outputs.hive2 = {
        at = _point: e: [
          "hive2"
          e.name
        ];
        consumes = "AggregateInfo";
        contentClass = "colmena";
        render = "sugarAgg";
        members = {
          of = hasClass "nixos";
          consumes = "RawModulesInfo";
        };
      };
    }
  ];
  namedAggVal = namedFleet.outputs.hiveFam.hive.built;
  sugarAggVal = sugarFleet.outputs.hive2."members:hive2".built;

  # a family-level members sugar whose synthetic name `members:hive2` collides with a user den.collectors entry.
  collisionFleet = denHoag.mkDen [
    memberBase
    {
      config.den.collectors."members:hive2" = {
        class = "colmena";
        members = hasClass "nixos";
        consumes = "RawModulesInfo";
        render = "sugarAgg";
      };
      config.den.renders.sugarAgg = {
        evaluator = aggEvaluator;
        produces = "AggregateInfo";
        aggregate = true;
        output = "hive2";
      };
      config.den.outputs.hive2 = {
        at = _point: e: [
          "hive2"
          e.name
        ];
        consumes = "AggregateInfo";
        contentClass = "colmena";
        render = "sugarAgg";
        members = {
          of = hasClass "nixos";
          consumes = "RawModulesInfo";
        };
      };
    }
  ];

  # a user schema kind named `collector` — the framework reserved-name collision (aborts NAMED at discovery).
  reservedKindFleet = denHoag.mkDen [ { config.den.schema.collector.parent = null; } ];

  # a members-sugar family with ONE required field omitted — each omission is a distinct NAMED throw in the
  # desugar pre-pass (the collision branch is tested above; these witness the four field-missing guards).
  mkMembersFamFleet =
    {
      of ? null,
      memberConsumes ? null,
      contentClass ? null,
      render ? null,
    }:
    denHoag.mkDen [
      {
        config.den.schema.nixosHost.parent = null;
        config.den.contentClass.nixosHost = "nixos";
        config.den.classes.colmena = { };
        config.den.renders.r1 = {
          evaluator = m: {
            built = m;
          };
          produces = "AggregateInfo";
          aggregate = true;
          output = "f";
        };
        config.den.nixosHost.a = { };
        config.den.outputs.f = {
          at = _point: e: [
            "f"
            e.name
          ];
          consumes = "AggregateInfo";
          members =
            { }
            // (if of != null then { inherit of; } else { })
            // (if memberConsumes != null then { consumes = memberConsumes; } else { });
        }
        // (if contentClass != null then { inherit contentClass; } else { })
        // (if render != null then { inherit render; } else { });
      }
    ];
in
{
  flake.tests.collectors = {
    # the collector is a real entity in its own registry with a name-derived id_hash DISTINCT from the member's
    # (two separate entities, never a shared identity).
    test-collector-is-entity = {
      expr = collectorFleet.den.registries.collector.hive.name;
      expected = "hive";
    };
    test-collector-distinct-id-hash = {
      expr =
        collectorFleet.den.registries.collector.hive.id_hash
        != collectorFleet.den.registries.host.m.id_hash;
      expected = true;
    };

    # the collector carries its OWN class content: its colmena subtree contains `meta.tag = "core"` …
    test-collector-own-content-has-meta-tag = {
      expr = hasMetaTagCore collectorSlice;
      expected = true;
    };
    # … while the member's nixos subtree does NOT (distinct content, no cross-contamination).
    test-member-content-lacks-meta-tag = {
      expr = hasMetaTagCore memberSlice;
      expected = false;
    };

    # the collector's PRODUCING class is its own `class` field (the per-instance `contentClass.collector`
    # function): it surfaces as a colmena-class content node in the terminal crossing (forces `classOfNode`
    # → `contentClassFn` for the collector node).
    test-collector-produces-its-own-class = {
      expr = builtins.hasAttr "collector:hive" collectorFleet.den.output.systems.colmena;
      expected = true;
    };

    # CORPUS-INERT: a fleet declaring no `den.collectors` has no collector kind (no augment, no registry).
    test-no-collectors-no-kind = {
      expr = plainFleet.den.registries ? collector;
      expected = false;
    };

    # a collector naming an unregistered class aborts NAMED when the compiled `den.collectors` surface is read.
    test-collector-unknown-class-aborts = {
      expr = throws badClassFleet.den.collectors;
      expected = true;
    };

    # a collector with `class` OMITTED aborts CATCHABLE-NAMED on the compiled surface …
    test-collector-omitted-class-aborts-surface = {
      expr = throws omittedClassFleet.den.collectors;
      expected = true;
    };
    # … AND on the classOf/materialization path (forcing `systems` runs the orphan's `contentClassFn`) — the
    # null must never reach a string selector (which would be tryEval-uncatchable, crashing the fold).
    test-collector-omitted-class-aborts-materialization = {
      expr = throws omittedClassFleet.den.output.systems;
      expected = true;
    };

    # the `members = hasClass "nixos"` selector INCLUDES the nixos node as a member edge target …
    test-member-includes-matching-class = {
      expr = builtins.elem "nixosHost:n" memberTargets;
      expected = true;
    };
    # … and EXCLUDES the darwin node (the selector rejects non-matching — exclusion, not just inclusion).
    test-member-excludes-nonmatching-class = {
      expr = builtins.elem "darwinHost:d" memberTargets;
      expected = false;
    };
    # the member edges are `collector→member`: from = the collector entity, kind = "member".
    test-member-edges-from-collector = {
      # self-standing: `memberEdges != []` guards the vacuous-truth pass (never leans on the inclusion test).
      expr =
        memberEdges != [ ]
        && builtins.all (edge: edge.from.entityId == "collector:hive" && edge.kind == "member") memberEdges;
      expected = true;
    };
    # the NULL-GUARD: the gather runs over a class-neutral (contentClass-null) env node without crashing —
    # forcing the whole member-edge set evaluates cleanly (the env node is simply not a member).
    test-member-gather-null-safe = {
      expr = throws memberEdges || builtins.elem "env:e" memberTargets;
      expected = false;
    };
    # CORPUS-INERT: a fleet with no `den.collectors` emits an EMPTY member producer set (byte-identical trace).
    test-no-collectors-no-member-edges = {
      expr = plainFleet.den.memberEdges;
      expected = [ ];
    };

    # the aggregate render receives the AGGREGATED member map (BOTH a and b under their names) — ONE render
    # call over the gathered members, not a per-config build. AggregateInfo goes producerless → produced.
    test-aggregate-value-has-both-members = {
      expr = builtins.attrNames aggHive.built;
      expected = [
        "a"
        "b"
      ];
    };
    # NON-VACUITY: each member's payload is its REAL resolved class-subtree content (never a null placeholder) —
    # a's payload == a's own nixos slice, and a's payload differs from b's (distinct resolved content).
    test-aggregate-member-payload-is-real-content = {
      expr =
        aggHive.built.a == aggFleet.den.output.classSubtreeAt "nixosHost:a" "nixos"
        && aggHive.built.a != aggHive.built.b;
      expected = true;
    };
    # SEAM: swapping the render's stub evaluator CHANGES the built AggregateInfo — the aggregate crossing is a
    # pluggable `evaluator` field, never hardcoded in the mount (the top key follows the evaluator).
    test-aggregate-evaluator-is-pluggable = {
      expr = builtins.attrNames aggSwapped.outputs.colmenaHive.cluster;
      expected = [ "swapped" ];
    };
    # GUARD-WIDEN: collectors are ADDITIVE — the nixos members still surface as built-in nixosConfigurations
    # (the widened guard takes the all-three-arms branch without dropping the built-in fold).
    test-aggregate-builtin-arm-intact = {
      expr = builtins.attrNames (aggFleet.nixosConfigurations or { });
      expected = [
        "a"
        "b"
      ];
    };

    # a collector render that is not an aggregate render aborts CATCHABLE-NAMED.
    test-collector-nonaggregate-render-aborts = {
      expr = throws nonAggFleet.outputs.colmenaHive;
      expected = true;
    };
    # render.produces ≠ family.consumes aborts CATCHABLE-NAMED (a silent shape mismatch made loud).
    test-collector-produces-consumes-mismatch-aborts = {
      expr = throws mismatchFleet.outputs.mismFam;
      expected = true;
    };
    # a per-config artifact family pointed at an aggregate render aborts CATCHABLE-NAMED (symmetric guard).
    test-per-config-family-aggregate-render-aborts = {
      expr = throws symFleet.outputs.badFam;
      expected = true;
    };
    # an aggregate render with no `output` family aborts CATCHABLE-NAMED (the null-output uncatchable closed).
    test-collector-no-output-family-aborts = {
      expr = throws noOutputFleet.outputs;
      expected = true;
    };

    # GENERICITY (consumes IS the abstraction): both collectors aggregate the SAME member set (a, b).
    test-generic-same-member-set = {
      expr =
        builtins.attrNames modHive == [
          "a"
          "b"
        ]
        &&
          builtins.attrNames sysHive == [
            "a"
            "b"
          ];
      expected = true;
    };
    # the SystemInfo collector's payload is the already-built SYSTEM (output.systems), read via the artifact arm.
    test-generic-systeminfo-reads-built-system = {
      expr = sysHive.a == genericFleet.den.output.systems.nixos."nixosHost:a";
      expected = true;
    };
    # the RawModulesInfo collector's payload is the raw class SLICE (classSubtreeAt), read via the content arm.
    test-generic-rawmodules-reads-raw-slice = {
      expr = modHive.a == genericFleet.den.output.classSubtreeAt "nixosHost:a" "nixos";
      expected = true;
    };
    # SAME member, DIFFERENT payload shape — `consumes` alone drives the extraction (one machine, no
    # colmena/deploy-rs field in the kernel).
    test-generic-consumes-drives-payload = {
      expr = sysHive.a != modHive.a;
      expected = true;
    };
    # STRUCTURAL genericity (floor 4): the two compiled collector records, minus identity (`name` + its
    # name-derived `id_hash`) and the two intended differences (`consumes`, `render`), are EQUAL — so NO other
    # kernel-contract field distinguishes them (no colmena/deploy-rs field leaked into the collector contract).
    test-generic-differ-only-in-consumes-render = {
      expr =
        let
          strip =
            e:
            removeAttrs e [
              "name"
              "id_hash"
              "consumes"
              "render"
            ];
        in
        strip genericFleet.den.registries.collector.cluster
        == strip genericFleet.den.registries.collector.deploy;
      expected = true;
    };
    # the SystemInfo artifact read NAMED-throws on a selected member with no built system (never a bare miss).
    test-generic-missing-system-aborts = {
      expr = throws missSysFleet.outputs.sysHive;
      expected = true;
    };

    # the family-level `members` sugar synthesizes a REAL anonymous collector ENTITY (with an id_hash) — the
    # SAME kernel as a named collector, not a shadow.
    test-members-sugar-synthesizes-entity = {
      expr = sugarFleet.den.registries.collector ? "members:hive2";
      expected = true;
    };
    test-members-sugar-entity-has-id-hash = {
      expr = builtins.isString (sugarFleet.den.registries.collector."members:hive2".id_hash or null);
      expected = true;
    };
    # the sugar-synthesized collector aggregates the SAME member set (a, b).
    test-members-sugar-same-member-set = {
      expr =
        builtins.attrNames sugarAggVal == [
          "a"
          "b"
        ];
      expected = true;
    };
    # KERNEL-IDENTITY WITNESS: the AggregateInfo AGGREGATE VALUE (member-name-keyed) is BYTE-IDENTICAL across the
    # named collector and the sugar-synthesized one — one kernel, no shadow arm. (The face keys differ by
    # construction: family hiveFam vs hive2, leaf hive vs members:hive2 — so we compare the aggregate value.)
    test-members-sugar-aggregate-byte-identical = {
      expr = sugarAggVal == namedAggVal;
      expected = true;
    };
    # the synthetic name colliding with a user den.collectors entry aborts CATCHABLE-NAMED.
    test-members-sugar-collision-aborts = {
      expr = throws collisionFleet.den.collectors;
      expected = true;
    };

    # the framework `collector` kind name is RESERVED: a user schema kind named `collector` aborts NAMED at
    # discovery (the `kinds`/`root` reserved posture).
    test-collector-reserved-kind-name-aborts = {
      expr = throws reservedKindFleet.den.registries;
      expected = true;
    };
    # the four members-sugar field-missing NAMED guards (each a distinct throw): members.of …
    test-members-sugar-missing-of-aborts = {
      expr =
        throws
          (mkMembersFamFleet {
            memberConsumes = "RawModulesInfo";
            contentClass = "colmena";
            render = "r1";
          }).den.collectors;
      expected = true;
    };
    # … members.consumes …
    test-members-sugar-missing-consumes-aborts = {
      expr =
        throws
          (mkMembersFamFleet {
            of = hasClass "nixos";
            contentClass = "colmena";
            render = "r1";
          }).den.collectors;
      expected = true;
    };
    # … the family's contentClass …
    test-members-sugar-missing-contentclass-aborts = {
      expr =
        throws
          (mkMembersFamFleet {
            of = hasClass "nixos";
            memberConsumes = "RawModulesInfo";
            render = "r1";
          }).den.collectors;
      expected = true;
    };
    # … the family's render.
    test-members-sugar-missing-render-aborts = {
      expr =
        throws
          (mkMembersFamFleet {
            of = hasClass "nixos";
            memberConsumes = "RawModulesInfo";
            contentClass = "colmena";
          }).den.collectors;
      expected = true;
    };
  };
}
