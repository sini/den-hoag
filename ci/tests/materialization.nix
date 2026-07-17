# The materialization SUBSTRATE suite (spec §12). Materialization is the read-through side of
# the pipeline: products/renders/receivers are queried, not folded, so the dispatch layer rests on the
# labeled-query calculus (Brzozowski derivatives over a label alphabet — the regular-path-query reading
# of reachability). This suite grows across the materialization arc; the first scenario is the dispatch-substrate
# smoke: den-hoag's OWN gen-graph pin reaches the labeled-query surface (`query`/`labeledFrom`/`regex`).
# See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  # The gen-graph lib, reached through den-hoag's raw-gen-libs seam (the role-named `internal.genGraph` arm).
  inherit (denHoag.internal) genGraph;
  inherit (genGraph) query labeledFrom regex;

  # A tiny labeled relation over a single `hop` edge alphabet: a → b → c. `labeledFrom` adapts one plain
  # accessor per label into the labeled-edge contract the query engine reads.
  rel = labeledFrom {
    hop =
      id:
      {
        a = [ "b" ];
        b = [ "c" ];
        c = [ ];
      }
      .${id} or [ ];
  };

  # ── the typed-product registry seam (lib/products.nix, §4.1) ──
  # `products` = the lib (the framework table + reserved names + the mode-set); `compileProducts` compiles
  # a user registration beside the framework table; `compileConversions` compiles the single-step
  # conversion pairs. `modeOf`/`checkConsumes` are the pure definition-time helpers receivers call.
  inherit (denHoag.internal)
    products
    compileProducts
    compileConversions
    ;
  inherit (products) modeOf checkConsumes;

  # a definition-time throw forced to fire: `mapAttrs`-built registries throw lazily per entry, so force
  # the whole value (the compat-suite `deepSeq e true` precedent) before catching — a caught throw is false.
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a framework-only compiled table (no user registrations) — the base every scenario reads.
  frameworkProducts = compileProducts { };

  # a mixed table: one user artifact face beside the framework rows, and one non-nestable user product.
  userProducts = compileProducts {
    products = {
      CustomInfo = {
        mode = "artifact";
      };
      SidecarArgs = {
        mode = "content";
        nestable = false;
      };
    };
  };

  # a well-formed single-step conversion registry (one pair).
  oneConversion = compileConversions {
    conversions = {
      "SystemInfo->RawModulesInfo" = {
        via = info: info;
      };
    };
  };

  # ── the renders registry seam (lib/renders.nix, §4.3) ──
  # `renders` = the lib (its compile + validation). `compile { registered; npkgs; ndarwin; products; }` is
  # PER-FLEET — the built-in nixos/darwin evaluators close over the fleet's own nixpkgs/darwin inputs, so
  # the lib holds compile + validation and NEVER the evaluators themselves. The compiled table is what the
  # read-through reads.
  inherit (denHoag.internal) renders;

  # a fake `{ modules, specialArgs } -> system` evaluator (the declared-instantiation.nix precedent): tags
  # + reflects, proving a crossing routes THROUGH the declared evaluator without a real nixpkgs.
  fakeEval = args: { __fakeCrossed = true; } // args;

  # the built-in rows on the PURE path (npkgs/ndarwin absent) — null evaluators, the collect fallback. This
  # is the built-in instantiation base the read-through reads directly; produces = SystemInfo (artifact).
  pureRenders = renders.compile {
    registered = { };
    npkgs = null;
    ndarwin = null;
    products = frameworkProducts;
  };

  # a user render row (a synthetic system face) beside the built-ins, resolving its `produces` against the
  # framework products table.
  userRenders = renders.compile {
    registered = {
      fakesys = {
        evaluator = fakeEval;
        produces = "SystemInfo";
        output = "fakeConfigurations";
      };
    };
    npkgs = null;
    ndarwin = null;
    products = frameworkProducts;
  };

  # ── the D7 read-through witnesses (through mkDen) ──
  # (a) the OVERLAY-WINS witness: a fleet promoting the nixos render row AND declaring
  # `classes.nixos.instantiation.evaluator` — the classes.instantiation overlay must win over the row
  # (precedence: classes.instantiation ≻ render row ≻ nothing). Mirrors declared-instantiation.nix's corpus.
  overlayFleet = denHoag.mkDen [
    { config.den.schema.server.parent = null; }
    {
      config.den = {
        server.box1 = { };
        contentClass.server = "nixos";
        aspects.srv.nixos.marker = "n";
        classes.nixos.instantiation.evaluator = fakeEval;
      };
    }
    (
      { config, ... }:
      {
        config.den.include = [
          {
            at = config.den.server.box1;
            aspects = [ config.den.aspects.srv ];
          }
        ];
      }
    )
  ];

  # (b) the user-row D7 witness: a fleet declaring a NEW system class with a `den.renders.<class>` row (a
  # fake evaluator), whose content class routes through the promoted registry to a class terminal — the D7
  # path exercised through the NEW registry (synthetic, collect-level, no real build).
  userRowFleet = denHoag.mkDen [
    { config.den.schema.box.parent = null; }
    {
      config.den = {
        box.node1 = { };
        contentClass.box = "fakeclass";
        classes.fakeclass = { };
        renders.fakeclass = {
          evaluator = fakeEval;
          produces = "SystemInfo";
          output = "fakeConfigurations";
        };
        aspects.a.fakeclass.marker = "m";
      };
    }
    (
      { config, ... }:
      {
        config.den.include = [
          {
            at = config.den.box.node1;
            aspects = [ config.den.aspects.a ];
          }
        ];
      }
    )
  ];

  # ── the receives registry seam (lib/receivers.nix, §4.2) ──
  # `receivers` = the lib. `compile { rows; knownKinds; products; renders }` compiles the
  # `den.kinds.<outerKind>.receives.<slot>` graft-site rows: every §4.2 field stored, mode derived via the
  # products table's `modeOf`/`checkConsumes`, the outer-kind + includes + render names validated. Dispatch
  # EXECUTION is later; this is declaration + validation.
  inherit (denHoag.internal) receivers;

  # a well-formed receives table: one outer kind `host` with a `vms` slot consuming SystemInfo (artifact),
  # rendered by the built-in nixos row; `at` is the paramPoint-first placement fn.
  goodReceives = receivers.compile {
    rows = {
      host.receives.vms = {
        at = _point: inner: [
          "vms"
          inner.name
        ];
        consumes = "SystemInfo";
        render = "nixos";
      };
    };
    knownKinds = [
      "host"
      "vm"
    ];
    products = frameworkProducts;
    renders = pureRenders;
  };

  # a compile helper closing over the standard known-kinds + products + renders, so each throw scenario
  # varies only its rows.
  compileRows =
    rows:
    receivers.compile {
      inherit rows;
      knownKinds = [
        "host"
        "vm"
        "app"
      ];
      products = frameworkProducts;
      renders = pureRenders;
    };
in
{
  flake.tests.materialization = {
    # The dispatch substrate is reachable: run ONE real regular-path query through the pin. `hop` matches
    # exactly one edge label, so from `a` the answer set is `{ b }` (the single-hop derivative is nullable
    # at b, not at c — `hop hop` is not in the language of `hop`).
    test-dispatch-substrate-single-hop = {
      expr = query {
        graph = rel;
        from = "a";
        follow = regex.parse "hop";
        mode = "all";
      };
      expected = [ "b" ];
    };

    # ── §4.1 the framework product table is EXACTLY the spec's rows ──
    # the pre-registered products + their modes, read straight off the compiled framework table.
    test-products-framework-table = {
      expr = builtins.mapAttrs (_: e: e.mode) frameworkProducts;
      expected = {
        ModulesInfo = "content";
        RawModulesInfo = "content";
        SystemInfo = "artifact";
        HmInfo = "artifact";
        DroidInfo = "artifact";
        NixidyEnvInfo = "artifact";
        ShellInfo = "artifact";
        TerranixInfo = "artifact";
        HiveInfo = "artifact";
        EvalHandleInfo = "extend";
        ArgsInfo = "content";
      };
    };
    # ArgsInfo is the non-nestable arg-environment payload — NEVER a consumes (its nestable flag is false).
    test-products-argsinfo-non-nestable = {
      expr = frameworkProducts.ArgsInfo.nestable;
      expected = false;
    };
    # every artifact-face framework row is nestable (a receiver may consume it).
    test-products-artifact-faces-nestable = {
      expr = builtins.all (n: frameworkProducts.${n}.nestable) [
        "SystemInfo"
        "HmInfo"
        "DroidInfo"
        "NixidyEnvInfo"
        "ShellInfo"
        "TerranixInfo"
        "HiveInfo"
      ];
      expected = true;
    };

    # ── §4.1 user registration ──
    # a user product registers beside the framework table with its declared mode.
    test-products-user-registration = {
      expr = userProducts.CustomInfo.mode;
      expected = "artifact";
    };
    # a user product may declare nestable = false (its own non-nestable payload).
    test-products-user-non-nestable = {
      expr = userProducts.SidecarArgs.nestable;
      expected = false;
    };
    # re-registering a framework product name aborts NAMED (the reserved posture, disciplines-registry shape).
    test-products-reserved-throw = {
      expr = throws (compileProducts {
        products = {
          SystemInfo = {
            mode = "artifact";
          };
        };
      });
      expected = true;
    };
    # a user product declaring a mode outside the closed set aborts NAMED.
    test-products-unknown-mode-throw = {
      expr = throws (compileProducts {
        products = {
          BogusInfo = {
            mode = "teleport";
          };
        };
      });
      expected = true;
    };
    # a user product name in the reserved `ArtifactRef ` prefix namespace aborts NAMED — the value-mode
    # wrapper is recognized structurally by that prefix, so a table row wearing it would be silently
    # misclassified (modeOf reads its prefix as value, ignoring its declared mode). The prefix is reserved.
    test-products-artifactref-prefix-throw = {
      expr = throws (compileProducts {
        products = {
          "ArtifactRef Foo" = {
            mode = "artifact";
          };
        };
      });
      expected = true;
    };

    # ── §4.1 modeOf totality + the ArtifactRef wrapper ──
    # modeOf is total over the registered nestable products.
    test-modeof-registered = {
      expr = modeOf frameworkProducts "ModulesInfo";
      expected = "content";
    };
    # `ArtifactRef P` is the value-mode WRAPPER (the prebuilt arm of a row consuming artifact-face P): it is
    # NOT a table row, so modeOf recognizes it structurally and returns value.
    test-modeof-artifactref-value = {
      expr = modeOf frameworkProducts "ArtifactRef SystemInfo";
      expected = "value";
    };

    # ── §4.1 checkConsumes (the definition-time gate receivers call) ──
    # a registered nestable product name passes the consumes gate (returns the name).
    test-checkconsumes-ok = {
      expr = checkConsumes frameworkProducts "SystemInfo";
      expected = "SystemInfo";
    };
    # an unregistered name in a consumes position aborts NAMED.
    test-checkconsumes-unregistered-throw = {
      expr = throws (checkConsumes frameworkProducts "NopeInfo");
      expected = true;
    };
    # a non-nestable product (ArgsInfo) in a consumes position aborts NAMED (never a consumes).
    test-checkconsumes-non-nestable-throw = {
      expr = throws (checkConsumes frameworkProducts "ArgsInfo");
      expected = true;
    };
    # `ArtifactRef` literally in a consumes aborts NAMED (same rule as a non-nestable product) — the wrapper
    # is a production short-circuit, never a receiver's declared consumes.
    test-checkconsumes-artifactref-throw = {
      expr = throws (checkConsumes frameworkProducts "ArtifactRef SystemInfo");
      expected = true;
    };

    # ── §4.1 conversions: single-step, global per-pair uniqueness ──
    # a well-formed conversion compiles to a per-pair entry keyed `<from>-><to>`.
    test-conversions-registered = {
      expr = oneConversion ? "SystemInfo->RawModulesInfo";
      expected = true;
    };
    # the compiled entry carries its `via` function (a registry holds functions freely — the fingerprint
    # law bans functions from edge DATA, never from a registry entry).
    test-conversions-via-present = {
      expr = builtins.isFunction oneConversion."SystemInfo->RawModulesInfo".via;
      expected = true;
    };
    # a malformed pair key — one whose `->` split is not exactly two faces — aborts NAMED at definition
    # time. Per-pair uniqueness is GLOBAL by construction: the registry is one attrset keyed by the pair,
    # so two registrations of the same (from, to) are the SAME key — a genuine cross-module collision is
    # the module system's unique-merge CONFLICT (raw never last-wins on non-equal records), never a silent
    # shadow; the compile gate enforces the KEY WELL-FORMEDNESS that keying relies on.
    test-conversions-malformed-key-throw = {
      expr = throws (compileConversions {
        conversions = {
          "SystemInfo->RawModulesInfo->ShellInfo" = {
            via = x: x;
          };
        };
      });
      expected = true;
    };
    # an empty face — a key with a missing `<from>` or `<to>` side — aborts NAMED.
    test-conversions-empty-face-throw = {
      expr = throws (compileConversions {
        conversions = {
          "->RawModulesInfo" = {
            via = x: x;
          };
        };
      });
      expected = true;
    };
    # a pair declaring no `via` aborts NAMED — the materialization function is required.
    test-conversions-no-via-throw = {
      expr = throws (compileConversions {
        conversions = {
          "SystemInfo->RawModulesInfo" = { };
        };
      });
      expected = true;
    };
    # `ArtifactRef` as a conversion endpoint aborts NAMED (conversions never apply to the prebuilt arm).
    test-conversions-artifactref-endpoint-throw = {
      expr = throws (compileConversions {
        conversions = {
          "ArtifactRef SystemInfo->RawModulesInfo" = {
            via = x: x;
          };
        };
      });
      expected = true;
    };

    # ── §4.3 the renders registry (D7 promoted) ──
    # the built-in nixos/darwin rows are present in the compiled table (the framework's system-class defaults).
    test-renders-builtins-present = {
      expr = (pureRenders ? nixos) && (pureRenders ? darwin);
      expected = true;
    };
    # PER-FLEET derivation: on the pure path (no nixpkgs/darwin input) the built-in evaluators are null —
    # the nixpkgs-free collect fallback (den-hoag's pure path).
    test-renders-builtins-pure-null-evaluator = {
      expr = {
        nixos = pureRenders.nixos.evaluator;
        darwin = pureRenders.darwin.evaluator;
      };
      expected = {
        nixos = null;
        darwin = null;
      };
    };
    # the built-in rows produce SystemInfo (both artifact-mode faces per the products table) and carry their
    # D7 `output` field (the flake-parts target the built systems mount at).
    test-renders-builtins-produces-and-output = {
      expr = {
        nixosProduces = pureRenders.nixos.produces;
        nixosOutput = pureRenders.nixos.output;
        darwinOutput = pureRenders.darwin.output;
      };
      expected = {
        nixosProduces = "SystemInfo";
        nixosOutput = "nixosConfigurations";
        darwinOutput = "darwinConfigurations";
      };
    };
    # a user render row registers beside the built-ins with its declared evaluator + output.
    test-renders-user-row = {
      expr = {
        hasEvaluator = builtins.isFunction userRenders.fakesys.evaluator;
        output = userRenders.fakesys.output;
      };
      expected = {
        hasEvaluator = true;
        output = "fakeConfigurations";
      };
    };
    # a render row whose `produces` names an unregistered product aborts NAMED.
    test-renders-produces-unregistered-throw = {
      expr = throws (
        renders.compile {
          registered = {
            bad = {
              evaluator = fakeEval;
              produces = "NopeInfo";
            };
          };
          npkgs = null;
          ndarwin = null;
          products = frameworkProducts;
        }
      );
      expected = true;
    };
    # a render row whose `requires` names an unregistered product aborts NAMED (shape-checked at compile;
    # definition-time CONSUMPTION arrives with the families work).
    test-renders-requires-unregistered-throw = {
      expr = throws (
        renders.compile {
          registered = {
            bad = {
              evaluator = fakeEval;
              requires = [ "NopeInfo" ];
            };
          };
          npkgs = null;
          ndarwin = null;
          products = frameworkProducts;
        }
      );
      expected = true;
    };
    # a render row whose `params` axis is not a name (a non-string) aborts NAMED (axes are names only here;
    # axis validation arrives with the families/root work).
    test-renders-params-non-name-throw = {
      expr = throws (
        renders.compile {
          registered = {
            bad = {
              evaluator = fakeEval;
              params = [ 42 ];
            };
          };
          npkgs = null;
          ndarwin = null;
          products = frameworkProducts;
        }
      );
      expected = true;
    };

    # ── the D7 read-through (the behavior-adjacent edit) ──
    # (a) OVERLAY WINS: a fleet promoting the nixos render row AND declaring classes.nixos.instantiation.
    # evaluator — the classes.instantiation overlay wins over the render row (precedence law:
    # classes.instantiation ≻ render row ≻ nothing). The fake evaluator's tag proves the OVERRIDE crossed.
    test-renders-read-through-overlay-wins = {
      expr = overlayFleet.nixosConfigurations.box1.__fakeCrossed or false;
      expected = true;
    };
    # (b) USER-ROW D7: a fleet's new system class routes through its den.renders row's fake evaluator to a
    # class terminal — the D7 path exercised through the NEW registry (synthetic, collect-level).
    test-renders-read-through-user-row = {
      expr = userRowFleet.outputs.fakeConfigurations.node1.__fakeCrossed or false;
      expected = true;
    };

    # ── §4.2 the receives registry (declaration + validation) ──
    # a well-formed row compiles: the slot lives under its outer kind, `at` is carried (function), and the
    # field set is present.
    test-receivers-row-compiles = {
      expr = {
        hasSlot = goodReceives.host.receives ? vms;
        atIsFn = builtins.isFunction goodReceives.host.receives.vms.at;
        consumes = goodReceives.host.receives.vms.consumes;
      };
      expected = {
        hasSlot = true;
        atIsFn = true;
        consumes = "SystemInfo";
      };
    };
    # F1: the compiled row's `mode` is DERIVED from consumes (the products table modeOf) — SystemInfo is an
    # artifact face. `mode` is the only mode surface (the mode names are a docs/trace taxonomy, never a field).
    test-receivers-mode-derived = {
      expr = goodReceives.host.receives.vms.mode;
      expected = "artifact";
    };
    # field defaults per §4.2: arity defaults "many", multiplicity defaults "error".
    test-receivers-field-defaults = {
      expr = {
        arity = goodReceives.host.receives.vms.arity;
        multiplicity = goodReceives.host.receives.vms.multiplicity;
      };
      expected = {
        arity = "many";
        multiplicity = "error";
      };
    };
    # F1 AS A CHECKED LAW: a USER-declared `mode` field on a row aborts NAMED — mode derives from consumes.
    test-receivers-mode-field-throw = {
      expr = throws (compileRows {
        host.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "SystemInfo";
          mode = "artifact";
        };
      });
      expected = true;
    };
    # `consumes` names an unregistered product → the products table's checkConsumes aborts NAMED (reused, not
    # re-implemented).
    test-receivers-consumes-unregistered-throw = {
      expr = throws (compileRows {
        host.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "NopeInfo";
        };
      });
      expected = true;
    };
    # `consumes` names a non-nestable product (ArgsInfo) → checkConsumes aborts NAMED (never a consumes).
    test-receivers-consumes-non-nestable-throw = {
      expr = throws (compileRows {
        host.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "ArgsInfo";
        };
      });
      expected = true;
    };
    # a receives table on an UNKNOWN outer kind aborts NAMED.
    test-receivers-unknown-outer-kind-throw = {
      expr = throws (compileRows {
        nope.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "SystemInfo";
        };
      });
      expected = true;
    };
    # THE KIND-INCLUDE RELATION: `includes` is a list of KIND NAMES on the KIND ENTRY (a sibling of
    # `receives`) — the receiver-inheritance relation the dispatch query walks. A known kind resolves.
    test-receivers-includes-known = {
      expr =
        (compileRows {
          host = {
            includes = [ "vm" ];
            receives.vms = {
              at = _: i: [ i.name ];
              consumes = "SystemInfo";
            };
          };
        }).host.includes;
      expected = [ "vm" ];
    };
    # a kind-entry `includes` naming an unknown kind aborts NAMED.
    test-receivers-includes-unknown-throw = {
      expr = throws (compileRows {
        host = {
          includes = [ "ghost" ];
          receives.vms = {
            at = _: i: [ i.name ];
            consumes = "SystemInfo";
          };
        };
      });
      expected = true;
    };
    # `includes` on a receives ROW (the kind/row confusion) aborts NAMED — inheritance is kind→kind, so
    # includes lives on the kind entry, never on a row.
    test-receivers-includes-on-row-throw = {
      expr = throws (compileRows {
        host.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "SystemInfo";
          includes = [ "vm" ];
        };
      });
      expected = true;
    };
    # `arity` outside { many singular } aborts NAMED.
    test-receivers-arity-domain-throw = {
      expr = throws (compileRows {
        host.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "SystemInfo";
          arity = "some";
        };
      });
      expected = true;
    };
    # `multiplicity` outside { error multi } aborts NAMED.
    test-receivers-multiplicity-domain-throw = {
      expr = throws (compileRows {
        host.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "SystemInfo";
          multiplicity = "loud";
        };
      });
      expected = true;
    };
    # `render` (when present) names a registered render row — an unregistered render aborts NAMED.
    test-receivers-render-unregistered-throw = {
      expr = throws (compileRows {
        host.receives.vms = {
          at = _: i: [ i.name ];
          consumes = "SystemInfo";
          render = "ghostrender";
        };
      });
      expected = true;
    };
    # `render` is legal ONLY on an artifact-mode row — a render on a content-mode consumes (ModulesInfo)
    # aborts NAMED (render IS the artifact eval; there is no artifact to render in content mode).
    test-receivers-render-non-artifact-throw = {
      expr = throws (compileRows {
        host.receives.mods = {
          at = _: i: [ i.name ];
          consumes = "ModulesInfo";
          render = "nixos";
        };
      });
      expected = true;
    };
    # THE KIND-NAMED-'kinds' GUARD (the mount reserved-name edge): a fleet declaring a kind literally named
    # `kinds` collides with the framework `den.kinds` concern option — aborts NAMED at kind discovery.
    test-kind-named-kinds-throw = {
      expr = throws (
        denHoag.mkDen [
          { config.den.schema.kinds.parent = null; }
        ]
      );
      expected = true;
    };
  };
}
