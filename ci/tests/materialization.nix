# The materialization SUBSTRATE suite (spec §12). Materialization is the read-through side of
# the pipeline: products/renders/receivers are queried, not folded, so the dispatch layer rests on the
# labeled-query calculus (Brzozowski derivatives over a label alphabet — the regular-path-query reading
# of reachability). This suite grows across the materialization arc; the first scenario is the dispatch-substrate
# smoke: den-hoag's OWN gen-graph pin reaches the labeled-query surface (`query`/`labeledFrom`/`regex`).
# See REFERENCE.md.
{
  denHoag,
  denCompat,
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

  # ── dispatch fixtures (§4.2 F4) ──
  # resolveReceiver consumes an already-COMPILED kinds table verbatim (it reads `.receives`/`.includes`
  # structure and returns the matched row), so the witnesses hand-build compiled-shape kind entries whose
  # rows carry a `tag` marker to identify which row fired. The gen-graph lib is threaded through
  # resolveReceiver itself; the includes here declare the receiver-inheritance edges the query walks.
  inherit (denHoag.internal) resolveReceiver;
  row = tag: { inherit tag; };

  # (1)+(2) the CUDA kind: a slot row `vm`, a class row `nixos`, a `user` slot row, all on ONE kind.
  cudaKinds = {
    cortex = {
      includes = [ ];
      receives = {
        vm = row "vm-row";
        nixos = row "nixos-row";
        user = row "user-row";
      };
    };
  };
  # (3) inheritance: b includes a; a carries receives.user.
  inheritKinds = {
    a = {
      includes = [ ];
      receives.user = row "a-user";
    };
    b = {
      includes = [ "a" ];
      receives = { };
    };
  };
  # b shadows a's row with its own receives.user.
  shadowKinds = {
    a = {
      includes = [ ];
      receives.user = row "a-user";
    };
    b = {
      includes = [ "a" ];
      receives.user = row "b-user";
    };
  };
  # (4) ambiguity: b includes a1+a2, both carry receives.user, b carries none.
  ambiguousKinds = {
    a1 = {
      includes = [ ];
      receives.user = row "a1-user";
    };
    a2 = {
      includes = [ ];
      receives.user = row "a2-user";
    };
    b = {
      includes = [
        "a1"
        "a2"
      ];
      receives = { };
    };
  };
  # the same, but both rows opt into multiplicity = "multi" (both return, no throw).
  multiKinds = {
    a1 = {
      includes = [ ];
      receives.user = row "a1-user" // {
        multiplicity = "multi";
      };
    };
    a2 = {
      includes = [ ];
      receives.user = row "a2-user" // {
        multiplicity = "multi";
      };
    };
    b = {
      includes = [
        "a1"
        "a2"
      ];
      receives = { };
    };
  };
  # a tied set that DISAGREES on multiplicity: a1 declares multi, a2 declares error (the default). The
  # opt-out must be UNANIMOUS, so this is a named error regardless of visible-order position. Two variants
  # with the tied kinds swapped pin that the outcome does NOT flip on order (the order-flip WAS the bug).
  mixedMultiKinds = {
    a1 = {
      includes = [ ];
      receives.user = row "a1-user" // {
        multiplicity = "multi";
      };
    };
    a2 = {
      includes = [ ];
      receives.user = row "a2-user"; # default multiplicity = "error"
    };
    b = {
      includes = [
        "a1"
        "a2"
      ];
      receives = { };
    };
  };
  # the same disagreement with the include order reversed (a2 first) — must ALSO throw.
  mixedMultiKindsSwapped = mixedMultiKinds // {
    b = {
      includes = [
        "a2"
        "a1"
      ];
      receives = { };
    };
  };
  # (5) diamond: b includes a1+a2, both include c, row on c ONLY.
  diamondKinds = {
    c = {
      includes = [ ];
      receives.user = row "c-user";
    };
    a1 = {
      includes = [ "c" ];
      receives = { };
    };
    a2 = {
      includes = [ "c" ];
      receives = { };
    };
    b = {
      includes = [
        "a1"
        "a2"
      ];
      receives = { };
    };
  };
  # (8) laziness: b INCLUDES a (a is graph-REACHABLE, not orphaned), b carries receives.user (wins at depth
  # 0), and a's receives.user VALUE throws — a reachable-but-SHADOWED row. Resolving b.user must return b's
  # row WITHOUT forcing a's value: `where` probes attr PRESENCE (names) and the result forces only the
  # winner, so a shadowed loser's value stays a thunk. This pins the property against a force-non-winners
  # regression (a graph-unreachable poison could not).
  poisonKinds = {
    b = {
      includes = [ "a" ];
      receives.user = row "b-user";
    };
    a = {
      includes = [ ];
      receives.user = throw "shadowed row value forced — laziness violated";
    };
  };

  # ── the nest-mode EXECUTION engine seam (lib/nest.nix, §4.2 mode taxonomy) ──
  # `executeNest { row; inner; ctx }` dispatches on the resolved row's DERIVED `mode` and returns that
  # mode's contribution row (the Backpack content-vs-artifact distinction: a content contribution carries
  # the raw module face, an artifact one carries a render thunk). Task 1 proves the CONTENT arm: the inner's
  # ModulesInfo module list is grafted at the row's `at` path, placed exactly where the fold's nest edge
  # would place it. Reached through the raw-gen-libs seam.
  inherit (denHoag.internal) executeNest;

  # the fold's `place` primitive as a LOCAL twin — output-modules.nix's `nestAtPath` (its own gen-edge
  # `core.setAttrByPath` twin) is UN-EXPORTED, so the GRAFT-leg oracle wraps with a co-located 3-line copy;
  # the executor performs the real wrap independently, which is what makes the leg non-circular.
  nestAtPath =
    path: value:
    if path == [ ] then value else { ${builtins.head path} = nestAtPath (builtins.tail path) value; };

  # a minimal CONTENT-mode row: consumes ModulesInfo (content), its `at` a paramPoint-first placement fn.
  # `flatRow` grafts flat (`[]` ⇒ the []⇒flat convention); `nestedRow` grafts at the singular nixos-nested
  # home-manager users path. Both compiled through the receivers registry so `mode` is DERIVED (F1), never
  # hand-set — the executor reads the compiled field.
  contentRows = receivers.compile {
    rows = {
      host.receives.flat = {
        at = _point: _inner: [ ];
        consumes = "ModulesInfo";
      };
      host.receives.nested = {
        at = point: _inner: [
          "home-manager"
          "users"
          point.name
        ];
        consumes = "ModulesInfo";
      };
    };
    knownKinds = [ "host" ];
    products = frameworkProducts;
    renders = pureRenders;
  };
  flatRow = contentRows.host.receives.flat;
  nestedRow = contentRows.host.receives.nested;

  # ── THE ANCHOR fleet (denCompat.mkDen, the projection.nix corpus shape): a nixos host `igloo` with three
  #    hm user cells, each emitting a home-manager slice. The executor's graft is proven byte-identically
  #    against the LIVE fold's own placement of a cell's home-manager subtree. ──
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
          home-manager.tag = "hm-${user.name}";
        };
      den.schema.user.includes = [ "acct" ];
    }
  ];
  anchorOut = anchorFleet.den.output;
  # the tux cell's OWN home-manager subtree (a ModulesInfo-shaped module list) — the payload the executor
  # nests; `user:tux@host:igloo` is the cell scope id (host:igloo's descendant, projection.nix's topology).
  tuxHmSubtree = anchorOut.classSubtreeAt "user:tux@host:igloo" "home-manager";
  # a structural paramPoint HANDLE for the tux mount: name/kind/slot — NO content (§2.1 corollary). The row's
  # `at` reads only `point.name` (the singular nixos-nested path `home-manager.users.<u>`).
  tuxPoint = {
    name = "tux";
    kind = "user";
    slot = "users";
  };
  # the inner face: `{ product; payload; }` + the structural fields the executor strips before calling `at`.
  tuxInner = {
    product = "ModulesInfo";
    payload = tuxHmSubtree;
    name = "tux";
    kind = "user";
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

    # ── §4.2 F4 THE DISPATCH: slot ≻ class as a gen-graph visible query ──
    # (1) THE CUDA WITNESS: an outer kind carrying `receives.vm` (a slot row) AND `receives.nixos` (a class
    # row); an inner of class nixos in slot `vm` resolves the VM row — the class row must NOT fire (slot beats
    # class). `tag` distinguishes the resolved row.
    test-dispatch-cuda-slot-beats-class = {
      expr =
        (resolveReceiver {
          compiledKinds = cudaKinds;
          outerKind = "cortex";
          slot = "vm";
          class = "nixos";
        }).tag;
      expected = "vm-row";
    };
    # the same outer kind, an inner in slot `user` (a user row present) resolves the user row.
    test-dispatch-cuda-user-slot = {
      expr =
        (resolveReceiver {
          compiledKinds = cudaKinds;
          outerKind = "cortex";
          slot = "user";
          class = "nixos";
        }).tag;
      expected = "user-row";
    };
    # (2) CLASS FALLBACK: a slot with no row anywhere + a `receives.<class>` row present → the class row.
    test-dispatch-class-fallback = {
      expr =
        (resolveReceiver {
          compiledKinds = cudaKinds;
          outerKind = "cortex";
          slot = "ghostslot";
          class = "nixos";
        }).tag;
      expected = "nixos-row";
    };
    # (3) INHERITANCE: kind B includes kind A; A carries `receives.user`; resolving against B finds A's row.
    test-dispatch-inheritance = {
      expr =
        (resolveReceiver {
          compiledKinds = inheritKinds;
          outerKind = "b";
          slot = "user";
          class = "nixos";
        }).tag;
      expected = "a-user";
    };
    # B declaring its OWN `receives.user` SHADOWS A's — B's row is returned (nearest-wins).
    test-dispatch-inheritance-shadow-wins = {
      expr =
        (resolveReceiver {
          compiledKinds = shadowKinds;
          outerKind = "b";
          slot = "user";
          class = "nixos";
        }).tag;
      expected = "b-user";
    };
    # (4) AMBIGUITY: B includes A1+A2, both carrying `receives.user`, B carries none → named throw naming
    # BOTH A1 and A2 (equal-precedence tie after node-dedup).
    test-dispatch-ambiguity-throw = {
      expr = throws (resolveReceiver {
        compiledKinds = ambiguousKinds;
        outerKind = "b";
        slot = "user";
        class = "nixos";
      });
      expected = true;
    };
    # with `multiplicity = "multi"` on ALL tied rows, both return in visible order (no throw).
    test-dispatch-multiplicity-multi = {
      expr = map (r: r.tag) (resolveReceiver {
        compiledKinds = multiKinds;
        outerKind = "b";
        slot = "user";
        class = "nixos";
      });
      expected = [
        "a1-user"
        "a2-user"
      ];
    };
    # a tied set DISAGREEING on multiplicity (one multi, one error) → named throw; the opt-out is unanimous.
    test-dispatch-multiplicity-mixed-throw = {
      expr = throws (resolveReceiver {
        compiledKinds = mixedMultiKinds;
        outerKind = "b";
        slot = "user";
        class = "nixos";
      });
      expected = true;
    };
    # the SAME disagreement with the tied kinds in reversed include order ALSO throws — the outcome does not
    # flip on visible-order position (the order-flip was the pre-unanimous bug).
    test-dispatch-multiplicity-mixed-throw-swapped = {
      expr = throws (resolveReceiver {
        compiledKinds = mixedMultiKindsSwapped;
        outerKind = "b";
        slot = "user";
        class = "nixos";
      });
      expected = true;
    };
    # (5) DIAMOND: B includes A1+A2, both include C, row on C ONLY → resolves C's row, NO throw (per-path
    # enumeration answers C twice with equal-rank words; the node-dedup prevents a false ambiguity).
    test-dispatch-diamond = {
      expr =
        (resolveReceiver {
          compiledKinds = diamondKinds;
          outerKind = "b";
          slot = "user";
          class = "nixos";
        }).tag;
      expected = "c-user";
    };
    # (6) NO RECEIVER → null (a LEGAL return — the caller's no-receiver case).
    test-dispatch-no-receiver-null = {
      expr = resolveReceiver {
        compiledKinds = cudaKinds;
        outerKind = "cortex";
        slot = "ghostslot";
        class = "ghostclass";
      };
      expected = null;
    };
    # unknown outer kind → named throw.
    test-dispatch-unknown-outer-throw = {
      expr = throws (resolveReceiver {
        compiledKinds = cudaKinds;
        outerKind = "nope";
        slot = "vm";
        class = "nixos";
      });
      expected = true;
    };
    # (8) LAZINESS: resolving one slot never forces an UNRELATED kind's row VALUE. A poison thunk in a
    # sibling kind's row value must not fire — `where` probes row PRESENCE (attr names), never the value.
    test-dispatch-laziness-poison = {
      expr =
        (resolveReceiver {
          compiledKinds = poisonKinds;
          outerKind = "b";
          slot = "user";
          class = "nixos";
        }).tag;
      expected = "b-user";
    };

    # ── §4.2 nest-mode EXECUTION (lib/nest.nix, the content arm + the anchor) ──
    # the engine DISPATCHES on the resolved row's derived mode: a content-mode row returns a content
    # contribution tagged `mode = "content"` (F1's canonical machine form read off the compiled row).
    test-nest-content-dispatch = {
      expr =
        (executeNest {
          row = flatRow;
          inner = tuxInner;
          ctx = {
            paramPoint = tuxPoint;
          };
        }).mode;
      expected = "content";
    };
    # an unknown/unhandled mode aborts NAMED (the `den.nest:` register). Task 1 handles only content; a row
    # wearing another mode (a hand-built compiled-shape row) hits the unknown-mode throw.
    test-nest-unknown-mode-throw = {
      expr = throws (executeNest {
        row = flatRow // {
          mode = "artifact";
        };
        inner = tuxInner;
        ctx = {
          paramPoint = tuxPoint;
        };
      });
      expected = true;
    };
    # the consumes/product mismatch guard: `inner.product` must EXACTLY match `row.consumes` — a mismatch
    # aborts NAMED, naming both products (the seam the single-step conversions consult replaces next task).
    test-nest-consumes-mismatch-throw = {
      expr = throws (executeNest {
        row = flatRow; # consumes ModulesInfo
        inner = tuxInner // {
          product = "RawModulesInfo";
        };
        ctx = {
          paramPoint = tuxPoint;
        };
      });
      expected = true;
    };
    # LAZINESS: a poison thunk in the inner's payload is NOT forced by executeNest — the content contribution
    # carries the module list lazily (the engine wires, never evaluates).
    test-nest-content-laziness-poison = {
      expr =
        let
          poisoned = tuxInner // {
            payload = [ (throw "inner payload forced — nest laziness violated") ];
          };
          contribution = executeNest {
            row = flatRow;
            inner = poisoned;
            ctx = {
              paramPoint = tuxPoint;
            };
          };
        in
        # forcing the contribution's SHAPE (mode + attr names) must not force the poison module value.
        {
          inherit (contribution) mode;
          hasModules = contribution ? modules;
        };
      expected = {
        mode = "content";
        hasModules = true;
      };
    };

    # ══ THE ANCHOR — the executor's graft == the LIVE fold's own placement, byte-identically ═════════════
    # (a) FLAT IDENTITY leg (the passthrough sanity leg, WEAK — NOT the fold anchor): for `at = _: _: [ ]`
    #     (the []⇒flat convention), the content contribution's placed `modules` == the inner's raw module
    #     list. Placement is the identity, so this only witnesses the passthrough, not the at-path wrap.
    test-nest-anchor-flat-identity = {
      expr =
        (executeNest {
          row = flatRow;
          inner = tuxInner;
          ctx = {
            paramPoint = tuxPoint;
          };
        }).modules == tuxHmSubtree;
      expected = true;
    };
    # (b) THE GRAFT leg (the real oracle, non-circular): for the nixos-nested row
    #     `at = point: _: [ "home-manager" "users" point.name ]` (singular path), the executor's grafted
    #     `modules` == `map (nestAtPath [ "home-manager" "users" "tux" ]) (classSubtreeAt cellId "home-manager")`
    #     — the fold's OWN placement of the cell's hm subtree, computed with the local nestAtPath twin. The
    #     executor GENUINELY performs the at-path wrap; equality against the twin proves the graft is right.
    test-nest-anchor-graft-eq-fold-placement = {
      expr =
        (executeNest {
          row = nestedRow;
          inner = tuxInner;
          ctx = {
            paramPoint = tuxPoint;
          };
        }).modules == map (nestAtPath [
          "home-manager"
          "users"
          "tux"
        ]) tuxHmSubtree;
      expected = true;
    };
  };
}
