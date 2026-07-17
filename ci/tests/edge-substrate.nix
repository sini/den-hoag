# The typed-edge SUBSTRATE suite (vocabulary spec §2, spec §12 step 2). Witnesses the two-level
# identity scheme (assembly/instance/edge hashes over canonical serialization — the applicative/nominal
# Backpack reading), the fingerprint law (function values never enter a fingerprint; produced values
# never enter the structural fill — only the producing node's instanceId STRING does, so identity
# hashing never forces content), and the fill-graph acyclicity check. See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  inherit (denHoag.internal) identity;
  inherit (denHoag) declare;
  # The strata-aware policy compiler seam (concern-policies.compileWithStrata): compile with an
  # explicit stratum order + a stratum→ctx-key-groups map, so the capability-scoped ctx projection
  # (a ctx key at a stratum ≥ the rule's is replaced by a named throw) can be witnessed synthetically.
  compileWithStrata = denHoag.internal.compilePoliciesWithStrata;
  # The edge-kind registry seam (lib/edges.nix): the compile fn + the framework pre-registration.
  inherit (denHoag.internal)
    compileEdges
    edgeKinds
    applyOverrides
    assembleEdges
    ;
  # gen-edge's frozen sort key (Task 1's public export) — to pin an assembled edge's ` | <kind>` component.
  inherit (denHoag.internal.edge) edgeSortKey;
  # A minimal registered-kind table for the assembly scenarios (reach is a framework kind).
  reachKinds = compileEdges {
    kinds = { };
    strataOrder = edgeStrata;
  };
  # A pre-identity assembly INTENT (kind + typed endpoints + data). Distinct entityIds so the two
  # endpoints get distinct assembly/instance ids.
  mkAsmIntent =
    {
      kind ? "reach",
      fromId ? "host:a",
      toId ? "host:b",
      fromS ? { },
      data ? { },
    }:
    {
      inherit kind data;
      from = {
        entityId = fromId;
        class = "nixos";
        s = fromS;
      };
      to = {
        entityId = toId;
        class = "nixos";
        s = { };
      };
    };
  # The seeded four-stratum order (structural < resolution < collection < demand).
  fourStrata = [
    "structural"
    "resolution"
    "collection"
    "demand"
  ];
  # The order the registry validates against once the framework's `output` stratum is inserted.
  edgeStrata = fourStrata ++ [ "output" ];
  # A pre-identity-freeze edge INTENT (the shape den.overrides matches on): kind + endpoints + data.
  mkIntent =
    {
      kind ? "reach",
      data ? { },
    }:
    {
      inherit kind data;
      from = {
        entityId = "host:a";
        class = "nixos";
      };
      to = {
        entityId = "host:b";
        class = "nixos";
      };
    };
  # A structural rule reading a structural ctx entry (`thing`) via a DECLARED record gate — the probe
  # fills the required `thing` coord with the value-less sentinel, observing the structural `link`.
  # The ctx projection wraps ONLY the FINAL dispatch produce, never the probe.
  linkFoo = {
    __condition = {
      thing = false;
    };
    fn = ctx: [ (declare.link { target = ctx.thing; }) ];
  };

  # A minimal, well-formed structural fill: scalars + a list coordinate + a nested producer-id string.
  s0 = {
    mount = [
      "a"
      "b"
    ];
    render = "nixos";
    args.channel = "producer:xyz";
  };
in
{
  flake.tests.edge-substrate = {
    # ── assemblyId (spec §2.1): content identity of a filled assembly ──
    # order-fixed LIST serialization — the JSON of `[ entityId class ]`, not an attrset (no key-sort
    # ambiguity). Pinned against the literal formula so a serialization drift is caught.
    test-assemblyId-formula = {
      expr = identity.assemblyId {
        entityId = "host:igloo";
        class = "nixos";
      };
      expected = builtins.hashString "sha256" (
        builtins.toJSON [
          "host:igloo"
          "nixos"
        ]
      );
    };
    # same inputs ⇒ same hash across two independent call sites (the identity law).
    test-assemblyId-stable = {
      expr =
        (identity.assemblyId {
          entityId = "e";
          class = "c";
        }) == (identity.assemblyId {
          entityId = "e";
          class = "c";
        });
      expected = true;
    };
    # a change to EITHER coordinate flips the hash.
    test-assemblyId-distinguishes-entity = {
      expr =
        (identity.assemblyId {
          entityId = "e1";
          class = "c";
        }) != (identity.assemblyId {
          entityId = "e2";
          class = "c";
        });
      expected = true;
    };
    test-assemblyId-distinguishes-class = {
      expr =
        (identity.assemblyId {
          entityId = "e";
          class = "c1";
        }) != (identity.assemblyId {
          entityId = "e";
          class = "c2";
        });
      expected = true;
    };

    # ── instanceId (spec §2.1): placement identity = hash of (assemblyId, canonical S) ──
    test-instanceId-stable = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) == (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        });
      expected = true;
    };
    # bit-flip over the `render` scalar field ⇒ a different instanceId.
    test-instanceId-flip-render = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "aaaa";
          s = s0 // {
            render = "darwin";
          };
        });
      expected = true;
    };
    # bit-flip over the `mount` list coordinate (order-bearing) ⇒ a different instanceId.
    test-instanceId-flip-mount = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "aaaa";
          s = s0 // {
            mount = [
              "b"
              "a"
            ];
          };
        });
      expected = true;
    };
    # bit-flip over the nested producer-id fill ⇒ a different instanceId.
    test-instanceId-flip-producer-id = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "aaaa";
          s = s0 // {
            args.channel = "producer:other";
          };
        });
      expected = true;
    };
    # a different assemblyId ⇒ a different instanceId (same fill).
    test-instanceId-flip-assembly = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "bbbb";
          s = s0;
        });
      expected = true;
    };

    # ── the identity laziness law (spec §2.1), stated honestly by three witnesses ──
    test-structural-fill-is-forced = {
      # THE STRICTNESS PIN: S content is forced (structural scalars by contract) — a poison
      # thunk placed IN S therefore aborts; the discipline is "never put content in S",
      # not "hashing is lazy over S"
      expr =
        (builtins.tryEval (
          identity.instanceId {
            assemblyId = "aaaa";
            s = {
              mount = [ "x" ];
              render = builtins.throw "forced";
            };
          }
        )).success;
      expected = false;
    };
    test-identity-producer-id-not-value = {
      # produced VALUES never enter S — only the producing node's instanceId string does.
      # The poison lives BESIDE the id on the producer record; selecting `.instanceId`
      # never forces `.produced`, so hashing succeeds.
      expr =
        let
          producer = {
            instanceId = "aaaa-bbbb";
            produced = throw "content forced";
          };
          id1 = identity.instanceId {
            assemblyId = "aaaa";
            s = {
              mount = [ "m" ];
              render = "nixos";
              args.channel = producer.instanceId;
            };
          };
        in
        builtins.seq id1 true;
      expected = true;
    };
    test-identity-function-in-fill-throws-named = {
      # a function value anywhere in S violates the fingerprint law — named throw
      expr =
        (builtins.tryEval (
          identity.instanceId {
            assemblyId = "aaaa";
            s = {
              mount = [ "m" ];
              render = (x: x);
            };
          }
        )).success;
      expected = false;
    };

    # ── edgeId (spec §2.1): the edge's own identity over kind + endpoints + data fingerprint ──
    test-edgeId-formula = {
      expr = identity.edgeId {
        kind = "demand";
        fromInstanceId = "from";
        toInstanceId = "to";
        dataFingerprint = "df";
      };
      expected = builtins.hashString "sha256" (
        builtins.toJSON [
          "demand"
          "from"
          "to"
          "df"
        ]
      );
    };
    # the kind participates in edge identity (two edges identical but for kind ⇒ distinct ids).
    test-edgeId-distinguishes-kind = {
      expr =
        (identity.edgeId {
          kind = "demand";
          fromInstanceId = "f";
          toInstanceId = "t";
          dataFingerprint = "df";
        }) != (identity.edgeId {
          kind = "reach";
          fromInstanceId = "f";
          toInstanceId = "t";
          dataFingerprint = "df";
        });
      expected = true;
    };

    # ── dataFingerprint (spec §2.1): canonical JSON with function values rejected ──
    # `when` (a demand-condition NAME string) is fingerprinted like any scalar.
    test-dataFingerprint-scalar-and-name = {
      expr = identity.dataFingerprint {
        port = 8080;
        when = "prod";
      };
      expected = builtins.hashString "sha256" (
        builtins.toJSON {
          port = 8080;
          when = "prod";
        }
      );
    };
    test-dataFingerprint-stable = {
      expr = (identity.dataFingerprint { a = 1; }) == (identity.dataFingerprint { a = 1; });
      expected = true;
    };
    test-dataFingerprint-function-rejected = {
      # a function value anywhere in the edge data throws NAMED (the fingerprint law)
      expr = (builtins.tryEval (identity.dataFingerprint { transform = (x: x); })).success;
      expected = false;
    };

    # ── checkFillAcyclic (spec §2.1): fill-reference acyclicity ──
    # a DAG returns null (no cycle).
    test-fill-acyclic-dag = {
      expr = identity.checkFillAcyclic {
        a = [ "b" ];
        b = [ "c" ];
        c = [ ];
      };
      expected = null;
    };
    # an empty fill map is trivially acyclic.
    test-fill-acyclic-empty = {
      expr = identity.checkFillAcyclic { };
      expected = null;
    };
    # a two-node cycle aborts NAMED (naming one member).
    test-fill-cycle-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (identity.checkFillAcyclic {
            a = [ "b" ];
            b = [ "a" ];
          }) null
        )).success;
      expected = false;
    };
    # a self-loop aborts (id ∈ closure(its own references)).
    test-fill-self-loop-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (identity.checkFillAcyclic {
            a = [ "a" ];
          }) null
        )).success;
      expected = false;
    };
    # a diamond (a→b, a→c, b→d, c→d) is ACYCLIC — the classic false-positive trap.
    test-fill-acyclic-diamond = {
      expr = identity.checkFillAcyclic {
        a = [
          "b"
          "c"
        ];
        b = [ "d" ];
        c = [ "d" ];
        d = [ ];
      };
      expected = null;
    };
    # a referenced id absent from the map is a LEAF (or [ ]) — not an error.
    test-fill-missing-ref-is-leaf = {
      expr = identity.checkFillAcyclic {
        a = [ "ghost" ];
      };
      expected = null;
    };

    # ── den.strata: the compiled stratum order (spec §5) ──
    # the seeded order with NO inserts is exactly structural < resolution < collection < demand
    # (the byte-identity anchor — every existing stratum consumer reads THIS list).
    test-strata-seeded-order = {
      expr = declare.compileStrata { inserts = { }; };
      expected = [
        "structural"
        "resolution"
        "collection"
        "demand"
      ];
    };
    # a single insert places its stratum immediately after its anchor (dense insertion).
    test-strata-single-insert = {
      expr = declare.compileStrata {
        inserts.output = {
          after = "demand";
        };
      };
      expected = [
        "structural"
        "resolution"
        "collection"
        "demand"
        "output"
      ];
    };
    # an insert after an interior anchor lands immediately after it, not at the end.
    test-strata-interior-insert = {
      expr = declare.compileStrata {
        inserts.reify = {
          after = "resolution";
        };
      };
      expected = [
        "structural"
        "resolution"
        "reify"
        "collection"
        "demand"
      ];
    };
    # two inserts after the SAME anchor order lexicographically by name (deterministic).
    test-strata-same-anchor-lexicographic = {
      expr = declare.compileStrata {
        inserts.aaa = {
          after = "resolution";
        };
        inserts.zzz = {
          after = "resolution";
        };
      };
      expected = [
        "structural"
        "resolution"
        "aaa"
        "zzz"
        "collection"
        "demand"
      ];
    };
    # a chained insert (after another insert) resolves once its anchor is placed.
    test-strata-chained-insert = {
      expr = declare.compileStrata {
        inserts.mid = {
          after = "demand";
        };
        inserts.tip = {
          after = "mid";
        };
      };
      expected = [
        "structural"
        "resolution"
        "collection"
        "demand"
        "mid"
        "tip"
      ];
    };
    # an insert name colliding with an existing stratum is a definition-time throw.
    test-strata-duplicate-name-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (declare.compileStrata {
            inserts.resolution = {
              after = "structural";
            };
          }) null
        )).success;
      expected = false;
    };
    # an insert naming an unknown `after` anchor is a definition-time throw.
    test-strata-unknown-after-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (declare.compileStrata {
            inserts.output = {
              after = "nowhere";
            };
          }) null
        )).success;
      expected = false;
    };
    # a cyclic insert PAIR (each `after` names the other — neither anchor ever resolves) is a
    # definition-time throw (the "unknown or cyclic" arm of the same guard, pinned distinctly).
    test-strata-cyclic-inserts-throw = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (declare.compileStrata {
            inserts.a = {
              after = "b";
            };
            inserts.b = {
              after = "a";
            };
          }) null
        )).success;
      expected = false;
    };
    # END-TO-END through the OPTION mount: a fleet setting `den.strata.insert` surfaces the compiled
    # order on the `den.strata` output — the seeded four with the user insert placed densely after its
    # anchor, PLUS the framework's own `output` stratum (dogfooded after `demand` for nest/defer).
    test-strata-option-mount-order = {
      expr =
        (denHoag.mkDen [
          {
            config.den.strata.insert.reify = {
              after = "resolution";
            };
          }
        ]).den.strata;
      expected = [
        "structural"
        "resolution"
        "reify"
        "collection"
        "demand"
        "output"
      ];
    };

    # ── capability-scoped rule ctx (spec §5 / A9 stratification-by-construction) ──
    # SEEDED projection is a no-op: with an empty stratum→ctx-key map, the structural rule reading its
    # structural ctx entry produces normally (the full suite is the fleet-wide byte proof; this pins it
    # at the compiler seam directly).
    test-ctx-scoping-seeded-noop = {
      expr =
        let
          c = compileWithStrata {
            order = fourStrata;
            ctxKeyStrata = { };
          } { } [ ] [ ] { foo = linkFoo; };
          rule = builtins.head c.policy;
        in
        map (a: a.__action) (
          rule.produce "n" {
            thing = {
              id_hash = "t";
              name = "t";
            };
          }
        );
      expected = [ "link" ];
    };
    # THE TRIPWIRE (synthetic, never a corpus path): a ctx key DECLARED at a stratum ≥ the rule's own
    # stratum is REPLACED with a named throw — reading it inside the body aborts CATCHABLY (replaced,
    # not attribute-missing, so tryEval+deepSeq catches it). `link` is structural; tagging its ctx key
    # `thing` at the RESOLUTION stratum (structural < resolution) fires the throw at dispatch.
    test-ctx-scoping-tripwire-throws = {
      expr =
        let
          c = compileWithStrata {
            order = fourStrata;
            ctxKeyStrata.resolution = [ "thing" ];
          } { } [ ] [ ] { foo = linkFoo; };
          rule = builtins.head c.policy;
        in
        (builtins.tryEval (
          builtins.deepSeq (rule.produce "n" {
            thing = {
              id_hash = "t";
              name = "t";
            };
          }) null
        )).success;
      expected = false;
    };
    # …and a ctx key at a stratum STRICTLY BELOW the rule's is passed through untouched. `member` is
    # structural too, but here the tagged key belongs to a stratum below a RESOLUTION rule: an `edge`
    # rule (resolution) reading a STRUCTURAL-tagged ctx key produces normally (structural < resolution).
    test-ctx-scoping-lower-stratum-ok = {
      expr =
        let
          edgeFoo = {
            __condition = {
              asp = false;
            };
            fn = ctx: [ (declare.edge ctx.asp) ];
          };
          c = compileWithStrata {
            order = fourStrata;
            ctxKeyStrata.structural = [ "asp" ];
          } { } [ ] [ ] { foo = edgeFoo; };
          rule = builtins.head c.policy;
        in
        map (a: a.__action) (
          rule.produce "n" {
            asp = {
              id_hash = "a";
              name = "a";
            };
          }
        );
      expected = [ "edge" ];
    };

    # ── den.edges: the edge-kind registry (spec §2.2) ──
    # the framework pre-registers exactly the 8 kinds with their strata (contains/include/kindOf
    # structural; member/reach/reach-suppress resolution; nest/defer output).
    test-edges-preregistered-strata = {
      expr = edgeKinds.preRegisteredStrata;
      expected = {
        contains = "structural";
        include = "structural";
        kindOf = "structural";
        member = "resolution";
        reach = "resolution";
        reach-suppress = "resolution";
        nest = "output";
        defer = "output";
      };
    };
    # the framework's own `output` stratum enters through the den.strata insertion mechanism.
    test-edges-framework-strata-insert = {
      expr = edgeKinds.frameworkStrataInserts;
      expected = {
        output = {
          after = "demand";
        };
      };
    };
    # a bare registry (no user kinds) compiles the 8 framework rows with the §2.2 field defaults.
    test-edges-compile-defaults = {
      expr =
        let
          t = compileEdges {
            kinds = { };
            strataOrder = edgeStrata;
          };
        in
        t.reach;
      expected = {
        data = null;
        requires = null;
        produces = null;
        discipline = null;
        inverse = null;
        closure = false;
        stratum = "resolution";
      };
    };
    # a user kind merges beside the framework rows (both present in the compiled table).
    test-edges-user-merge = {
      expr =
        let
          t = compileEdges {
            kinds.memberOf = {
              inverse = "members";
              stratum = "resolution";
            };
            strataOrder = edgeStrata;
          };
        in
        {
          user = t.memberOf.inverse;
          framework = t.reach.stratum;
        };
      expected = {
        user = "members";
        framework = "resolution";
      };
    };
    # re-registering a framework-reserved kind name aborts NAMED at definition time.
    test-edges-reserved-name-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (compileEdges {
            kinds.reach = {
              stratum = "resolution";
            };
            strataOrder = edgeStrata;
          }) null
        )).success;
      expected = false;
    };
    # closure = true with no discipline aborts NAMED (the laws-gating defers to the disciplines registry).
    test-edges-closure-without-discipline-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (compileEdges {
            kinds.aclClosure = {
              closure = true;
              stratum = "resolution";
            };
            strataOrder = edgeStrata;
          }) null
        )).success;
      expected = false;
    };
    # closure = true WITH a declared discipline compiles (the entry carries closure + discipline).
    test-edges-closure-with-discipline-ok = {
      expr =
        (compileEdges {
          kinds.aclClosure = {
            closure = true;
            discipline = "set-union";
            stratum = "resolution";
          };
          strataOrder = edgeStrata;
        }).aclClosure.closure;
      expected = true;
    };
    # a `stratum` outside the compiled order aborts NAMED.
    test-edges-unknown-stratum-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (compileEdges {
            kinds.weird = {
              stratum = "nowhere";
            };
            strataOrder = edgeStrata;
          }) null
        )).success;
      expected = false;
    };
    # END-TO-END: the fleet exposes the compiled kind table on `den.edges`, and the framework's `output`
    # stratum has been dogfooded into the fleet strata order (nest/defer validate against it).
    test-edges-fleet-output-stratum = {
      expr =
        let
          d = denHoag.mkDen [ ];
        in
        {
          nestStratum = d.den.edges.nest.stratum;
          outputInOrder = builtins.elem "output" d.den.strata;
        };
      expected = {
        nestStratum = "output";
        outputInOrder = true;
      };
    };
    # a user insert naming a framework-reserved stratum (`output`) aborts NAMED through the mount — the
    # framework stratum is not overridable (same posture as a reserved edge-kind or a seed-stratum shadow).
    test-edges-reserved-strata-insert-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq
            (denHoag.mkDen [
              {
                config.den.strata.insert.output = {
                  after = "structural";
                };
              }
            ]).den.strata
            null
        )).success;
      expected = false;
    };
    # THE T5-AUTHOR INTERACTION: a user-inserted stratum carries a user edge-kind through the mount —
    # `den.strata.insert.reify` + `den.edges.<k>.stratum = "reify"` compiles end-to-end (the compiled
    # table's kind resolves to the inserted stratum, present in the compiled order).
    test-edges-user-stratum-user-kind = {
      expr =
        let
          d = denHoag.mkDen [
            {
              config.den.strata.insert.reify = {
                after = "resolution";
              };
              config.den.edges.reifyEdge = {
                stratum = "reify";
              };
            }
          ];
        in
        {
          kindStratum = d.den.edges.reifyEdge.stratum;
          inOrder = builtins.elem "reify" d.den.strata;
        };
      expected = {
        kindStratum = "reify";
        inOrder = true;
      };
    };

    # ── den.overrides: the pre-identity-freeze match/rewrite tier (spec §2.4, before edgeId) ──
    # no override touches an edge (empty list) → the intent passes through untouched.
    test-overrides-empty-passthrough = {
      expr = applyOverrides {
        overrides = [ ];
        edges = [ (mkIntent { data.port = 8080; }) ];
      };
      expected = [ (mkIntent { data.port = 8080; }) ];
    };
    # a matching rewrite shallow-merges its patch into the edge's `data` (`//` semantics).
    test-overrides-rewrite-patches-data = {
      expr =
        (builtins.head (applyOverrides {
          overrides = [
            {
              match = {
                kind = "reach";
              };
              rewrite = {
                port = 9090;
              };
            }
          ];
          edges = [ (mkIntent { data.port = 8080; }) ];
        })).data;
      expected = {
        port = 9090;
      };
    };
    # `rewrite = null` SUPPRESSES the edge entirely — a suppressed edge contributes nothing to output.
    test-overrides-suppress-to-null = {
      expr = applyOverrides {
        overrides = [
          {
            match = {
              kind = "reach";
            };
            rewrite = null;
          }
        ];
        edges = [
          (mkIntent { })
          (mkIntent { kind = "member"; })
        ];
      };
      expected = [ (mkIntent { kind = "member"; }) ];
    };
    # a `data` match compares PER-FIELD: an edge whose data carries the stated field value (plus others)
    # matches; every stated field must equal.
    test-overrides-match-data-per-field = {
      expr =
        (builtins.head (applyOverrides {
          overrides = [
            {
              match = {
                data = {
                  when = "prod";
                };
              };
              rewrite = {
                tagged = true;
              };
            }
          ];
          edges = [
            (mkIntent {
              data = {
                when = "prod";
                port = 8080;
              };
            })
          ];
        })).data.tagged;
      expected = true;
    };
    # a stated coordinate that does NOT equal the edge's is a non-match (the edge passes through).
    test-overrides-nonmatch-passthrough = {
      expr =
        (builtins.head (applyOverrides {
          overrides = [
            {
              match = {
                kind = "member";
              };
              rewrite = {
                touched = true;
              };
            }
          ];
          edges = [ (mkIntent { kind = "reach"; }) ];
        })).data;
      expected = { };
    };
    # SINGLE-STEP, first match wins, NO re-matching of the rewritten edge: the first entry rewrites
    # `kind`-less data so it WOULD satisfy the second entry's `data` match — the second must NOT fire.
    test-overrides-single-step-no-rematch = {
      expr =
        (builtins.head (applyOverrides {
          overrides = [
            {
              match = {
                kind = "reach";
              };
              rewrite = {
                phase = "two";
              };
            }
            {
              match = {
                data = {
                  phase = "two";
                };
              };
              rewrite = {
                refired = true;
              };
            }
          ];
          edges = [ (mkIntent { }) ];
        })).data;
      # only the first entry's patch is present; the second never re-matches the rewritten edge.
      expected = {
        phase = "two";
      };
    };
    # APPLIED BEFORE edgeId: a rewrite changing `data` changes the downstream edgeId (via the data
    # fingerprint), so the override tier genuinely participates in identity.
    test-overrides-changes-edgeId = {
      expr =
        let
          e0 = mkIntent { data.port = 8080; };
          e1 = builtins.head (applyOverrides {
            overrides = [
              {
                match = {
                  kind = "reach";
                };
                rewrite = {
                  port = 9090;
                };
              }
            ];
            edges = [ e0 ];
          });
          idOf =
            e:
            identity.edgeId {
              inherit (e) kind;
              fromInstanceId = "f";
              toInstanceId = "t";
              dataFingerprint = identity.dataFingerprint e.data;
            };
        in
        idOf e0 != idOf e1;
      expected = true;
    };
    # a malformed override (a match coordinate outside {kind, from, to, data}) throws NAMED.
    test-overrides-malformed-coordinate-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (applyOverrides {
            overrides = [
              {
                match = {
                  bogus = 1;
                };
                rewrite = { };
              }
            ];
            edges = [ (mkIntent { }) ];
          }) null
        )).success;
      expected = false;
    };
    # `from`/`to` match by WHOLE VALUE, not per-field: a partial `from = { entityId = "host:a"; }`
    # does NOT match an intent whose `from = { entityId = "host:a"; class = "nixos"; }` (they are
    # unequal records). This pins the whole-value contract so a future per-field `from`-matcher is a
    # deliberate change, not a silent drift — protecting T6 edgeId stability.
    test-overrides-partial-from-no-match = {
      expr =
        (builtins.head (applyOverrides {
          overrides = [
            {
              match = {
                from = {
                  entityId = "host:a";
                };
              };
              rewrite = {
                touched = true;
              };
            }
          ];
          edges = [ (mkIntent { }) ];
        })).data;
      expected = { };
    };

    # ── assembleEdges: override → identity → acyclicity → stamped record (§2.1, synthetic-only) ──
    # a well-formed assembly emits one gen-edge record per surviving intent, each STAMPED with its kind.
    test-assemble-stamps-kind = {
      expr =
        (builtins.head (assembleEdges {
          kinds = reachKinds;
          intents = [ (mkAsmIntent { }) ];
        })).kind;
      expected = "reach";
    };
    # the assembled edge's gen-edge sort key ends in ` | <kind>` — the frozen (T,P,S,M,K) key, pinned
    # from the den-hoag side (T1 semantics through the live gen-edge pin).
    test-assemble-sortkey-carries-kind = {
      expr =
        let
          e = builtins.head (assembleEdges {
            kinds = reachKinds;
            intents = [ (mkAsmIntent { }) ];
          });
          key = edgeSortKey e;
          suffix = " | reach";
        in
        builtins.substring (
          builtins.stringLength key - builtins.stringLength suffix
        ) (builtins.stringLength suffix) key;
      expected = " | reach";
    };
    # an unknown kind (absent from the registry table) aborts NAMED.
    test-assemble-unknown-kind-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (assembleEdges {
            kinds = reachKinds;
            intents = [ (mkAsmIntent { kind = "no-such-kind"; }) ];
          }) null
        )).success;
      expected = false;
    };
    # an override changing `data` is applied BEFORE edgeId: the stamped edgeId annotation differs from
    # the un-overridden assembly's (the override tier genuinely participates in identity).
    test-assemble-override-changes-edgeId = {
      expr =
        let
          id =
            overrides:
            (builtins.head (assembleEdges {
              kinds = reachKinds;
              inherit overrides;
              intents = [ (mkAsmIntent { data.port = 8080; }) ];
            })).annotations.edgeId;
        in
        (id [ ]) != (id [
          {
            match = {
              kind = "reach";
            };
            rewrite = {
              port = 9090;
            };
          }
        ]);
      expected = true;
    };
    # a suppressing override (`rewrite = null`) drops the edge — a suppressed intent emits no record.
    test-assemble-override-suppresses = {
      expr = builtins.length (assembleEdges {
        kinds = reachKinds;
        overrides = [
          {
            match = {
              kind = "reach";
            };
            rewrite = null;
          }
        ];
        intents = [
          (mkAsmIntent { })
          (mkAsmIntent { kind = "member"; })
        ];
      });
      expected = 1;
    };
    # THE FILL-GRAPH ACYCLICITY WITNESS: two intents whose endpoint fills reference each other's producer
    # (each side's S carries the OTHER endpoint's entityId as a producer-id) form a 2-cycle — checkFillAcyclic
    # aborts NAMED, once per assembly. (Keyed by the stable entityId producer identity — see edges.nix.)
    test-assemble-fill-cycle-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (assembleEdges {
            kinds = reachKinds;
            intents = [
              (mkAsmIntent {
                fromId = "host:a";
                toId = "host:b";
                fromS.ref = "host:b";
              })
              (mkAsmIntent {
                fromId = "host:b";
                toId = "host:c";
                fromS.ref = "host:a";
              })
            ];
          }) null
        )).success;
      expected = false;
    };
    # an acyclic assembly (an endpoint fill referencing a producer that never references back) succeeds.
    test-assemble-fill-acyclic-ok = {
      expr = builtins.length (assembleEdges {
        kinds = reachKinds;
        intents = [
          (mkAsmIntent {
            fromId = "host:a";
            toId = "host:b";
            fromS.ref = "host:b";
          })
        ];
      });
      expected = 1;
    };
  };
}
