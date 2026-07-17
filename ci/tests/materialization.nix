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

  # ── the output-families registry seam (lib/outputs.nix, §4.4) ──
  # `outputsLib` = the lib. `compile { registered; renders; products; systems }` compiles the
  # `den.outputs.<family>` rows: the `at` placement fn stored (registry-resident), `consumes` validated
  # via the products table's `checkConsumes` (reused), `render`/`params`/`requires` name-checked. PER-FLEET
  # (the `render` name check reads the per-fleet render rows). The framework seeding is a later task's
  # compile arg (the `builtins` seam is left open here, defaulting `{ }`).
  inherit (denHoag.internal) outputsLib;

  # a well-formed families table: one `nixosConfigurations` family placing each member at `[ ]` (flat,
  # host-keyed by the caller), consuming SystemInfo (artifact), rendered by the built-in nixos row, with a
  # `system` param axis. Reads the framework products + the pure render rows.
  goodOutputs = outputsLib.compile {
    registered = {
      nixosConfigurations = {
        at = _point: e: [ e.name ];
        consumes = "SystemInfo";
        render = "nixos";
        params = [ "system" ];
      };
    };
    renders = pureRenders;
    products = frameworkProducts;
    systems = [ "x86_64-linux" ];
  };

  # a compile helper closing over the standard renders + products + systems, so each throw scenario varies
  # only its rows.
  compileOutputs =
    registered:
    outputsLib.compile {
      inherit registered;
      renders = pureRenders;
      products = frameworkProducts;
      systems = [ "x86_64-linux" ];
    };

  # ── the ROOT-projection seam (§4.4/§4.6) ──
  # `toReceives` projects the raw `den.outputs` config into a raw `den.kinds` entry `{ root = { includes;
  # receives.<family> = <§4.2 receives row>; }; }`: each family becomes a receives row carrying the §4.2
  # contract ONLY (`at`/`consumes`/`render` + the `many`/`error` defaults); the family-specific `params`/
  # `requires` STAY on the family row (not §4.2 fields). Fed through the REAL receivers compile.
  projectedRoot = outputsLib.toReceives {
    nixosConfigurations = {
      at = _point: e: [ e.name ];
      consumes = "SystemInfo";
      render = "nixos";
      params = [ "system" ];
    };
  };
  # the projected root entry, routed THROUGH the receivers compile (its validation applies: mode derivation,
  # render/artifact pairing). `root` is a known outer kind here (the knownKinds augmentation the fleet does).
  rootKinds = receivers.compile {
    rows = projectedRoot;
    knownKinds = [ "root" ];
    products = frameworkProducts;
    renders = pureRenders;
  };

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

  # ── Task 2 fixtures: value mode + the conversions consult ──
  # an ARTIFACT-consuming row (consumes SystemInfo → artifact mode): the row a prebuilt `ArtifactRef
  # SystemInfo` value satisfies (value-mode acceptance) and the target of the conversions consult.
  artifactRow =
    (receivers.compile {
      rows = {
        host.receives.sys = {
          at = _point: _inner: [ "sys" ];
          consumes = "SystemInfo";
          render = "nixos";
        };
      };
      knownKinds = [ "host" ];
      products = frameworkProducts;
      renders = pureRenders;
    }).host.receives.sys;

  # the VALUE-mode inner — the prebuilt arm (§4.1 ArtifactRef wrapper): `inner.product` is the wrapper name
  # (`ArtifactRef <face>`, so modeOf reads value), `inner.artifactRef = { product = <wrapped face>; value; }`
  # carries the underlying face + the prebuilt value (injected verbatim, never evaluated by den).
  cleanValueInner = {
    product = "ArtifactRef SystemInfo";
    artifactRef = {
      product = "SystemInfo"; # matches the row's consumes → definitional acceptance, no unrealizedCast.
      value = {
        __prebuilt = "a-real-system";
      };
    };
    name = "box";
    kind = "host";
  };
  # a WRAPPED-FACE MISMATCH (ArtifactRef Q at consumes = P): the value is STILL injected verbatim (never an
  # eval failure), but the contribution carries the `unrealizedCast` marker — a trace-visible node (§4.1).
  mismatchValueInner = cleanValueInner // {
    product = "ArtifactRef HmInfo";
    artifactRef = {
      product = "HmInfo"; # ≠ the row's consumes (SystemInfo) → unrealizedCast marker, NOT a throw.
      value = {
        __prebuilt = "a-real-hm";
      };
    };
  };

  # a compiled single-step conversion table for the consult: RawModulesInfo → ModulesInfo, `via` a tagging
  # transform (proves the payload flows THROUGH via, and that via is applied lazily). The pair keys the
  # (produces, consumes) mismatch the flat content row (`consumes ModulesInfo`) hits when fed RawModulesInfo.
  nestConversions = compileConversions {
    conversions = {
      "RawModulesInfo->ModulesInfo" = {
        via = mods: map (m: m // { __converted = true; }) mods;
      };
    };
  };
  # a RawModulesInfo inner feeding the flat content row (consumes ModulesInfo) — the (RawModulesInfo,
  # ModulesInfo) mismatch the consult resolves. Its payload is a single trivial module.
  rawInner = tuxInner // {
    product = "RawModulesInfo";
    payload = [ { __seed = true; } ];
  };

  # ── Task 2 fixtures: the entity-side `artifact` facet + the buckets-empty exclusivity throw ──
  # the pure exclusivity decision fn — an aspect declaring `artifact` (the prebuilt arm) must carry NO
  # non-empty class content key (§4.1: "its class buckets must be empty — declaring both throws named").
  inherit (denHoag.internal) artifactExclusive;

  # a fleet with a WELL-FORMED artifact aspect (declares `artifact`, no class content) — the surface exists,
  # the exclusivity holds, so the fleet builds. Synthetic (a `unit` kind, collect-level).
  artifactOkFleet = denHoag.mkDen [
    { config.den.schema.unit.parent = null; }
    {
      config.den = {
        unit.u1 = { };
        aspects.prebuilt.artifact = {
          __prebuilt = "a-face";
        };
      };
    }
    (
      { config, ... }:
      {
        config.den.include = [
          {
            at = config.den.unit.u1;
            aspects = [ config.den.aspects.prebuilt ];
          }
        ];
      }
    )
  ];
  # a fleet DECLARING BOTH — `artifact` AND a non-empty `nixos` class content key on the same aspect: the
  # exclusivity throw must fire when the fleet output is forced (the terminal per-aspect totality gate).
  artifactBothFleet = denHoag.mkDen [
    { config.den.schema.unit.parent = null; }
    {
      config.den = {
        unit.u1 = {
          class = "nixos";
        };
        contentClass.unit = "nixos";
        aspects.prebuilt = {
          artifact = {
            __prebuilt = "a-face";
          };
          nixos.marker = "n"; # a REAL class content key alongside artifact → the both-declared throw.
        };
      };
    }
    (
      { config, ... }:
      {
        config.den.include = [
          {
            at = config.den.unit.u1;
            aspects = [ config.den.aspects.prebuilt ];
          }
        ];
      }
    )
  ];
  # force a fleet's terminal output enough to trigger the per-aspect totality gate (which fires the
  # exclusivity check). `deepSeq` over the class-modules projection at the offending node.
  forceArtifactGate =
    fleet:
    let
      out = fleet.den.output;
    in
    builtins.deepSeq (out.projectClass "unit:u1" "nixos") true;

  # ── Task 2 fixture: a genuine CROSS-MODULE conversions same-pair collision ──
  # two modules registering `den.conversions."A->B"` with DIFFERENT `via` → the module system's unique-merge
  # conflict at `den.conversions."SystemInfo->RawModulesInfo".via` (the raw type never last-wins on non-equal
  # records). Forced by compiling the conversions table off the fleet config.
  collisionFleet = denHoag.mkDen [
    { config.den.schema.unit.parent = null; }
    { config.den.conversions."SystemInfo->RawModulesInfo".via = a: a; }
    { config.den.conversions."SystemInfo->RawModulesInfo".via = b: [ b ]; }
  ];

  # ── Task 3 fixtures: artifact + extend modes (render-row consult) ──
  # a compiled render table with FAKE evaluators (the declared-instantiation fakeEval pattern): `arti`
  # renders an artifact via its evaluator + a `face` projection; `artiNoFace` renders with a null face (the
  # eval IS the artifact); `ext` declares the `extendsVia` capability (a fake handle-extender); `extNoCap`
  # is an extend target with NO extendsVia (the missing-capability throw path). Registered beside the
  # built-ins (produces = SystemInfo, an artifact face — the products table types it).
  nestRenders = renders.compile {
    registered = {
      arti = {
        evaluator = mods: {
          __fakeCrossed = true;
          modules = mods;
        };
        face = eval: {
          __face = true;
          inherit eval;
        };
        produces = "SystemInfo";
      };
      artiNoFace = {
        evaluator = mods: {
          __fakeCrossed = true;
          modules = mods;
        };
        produces = "SystemInfo";
      };
      ext = {
        extendsVia = handle: {
          __extended = handle;
        };
        produces = "SystemInfo";
      };
      extNoCap = {
        produces = "SystemInfo";
      };
    };
    npkgs = null;
    ndarwin = null;
    products = frameworkProducts;
  };

  # ARTIFACT-mode receives rows (consumes SystemInfo → artifact mode), naming the fake render. `artiFaceRow`
  # projects through `face`; `artiNoFaceRow` has a null-face render (eval IS the artifact). `at = [ "sys" ]`.
  mkArtifactRow =
    renderName:
    (receivers.compile {
      rows = {
        host.receives.sys = {
          at = _point: _inner: [ "sys" ];
          consumes = "SystemInfo";
          render = renderName;
        };
      };
      knownKinds = [ "host" ];
      products = frameworkProducts;
      renders = nestRenders;
    }).host.receives.sys;
  artiFaceRow = mkArtifactRow "arti";
  artiNoFaceRow = mkArtifactRow "artiNoFace";

  # an artifact-mode inner: produces SystemInfo directly (exact-match → artifact arm), its payload the
  # module list the render's evaluator crosses in isolation (the forcing boundary).
  artiInner = {
    product = "SystemInfo";
    payload = [ { __seed = "m"; } ];
    name = "box";
    kind = "host";
  };

  # EXTEND-mode receives rows (consumes EvalHandleInfo → extend mode). `extRow` names the `ext` render (has
  # extendsVia); `extNoCapRow` names `extNoCap` (no extendsVia → missing-capability throw); `extNullRenderRow`
  # names no render at all (render = null → the same missing-capability path, criterion 4). An extend-mode row
  # MAY name a render (its extendsVia is read there) — the receivers validation permits render on artifact OR
  # extend rows (relaxed this task; the executor needs the render reference for the extendsVia consult).
  mkExtendRow =
    renderName:
    (receivers.compile {
      rows = {
        host.receives.h = {
          at = _point: _inner: [ "ext" ];
          consumes = "EvalHandleInfo";
        }
        // (if renderName == null then { } else { render = renderName; });
      };
      knownKinds = [ "host" ];
      products = frameworkProducts;
      renders = nestRenders;
    }).host.receives.h;
  extRow = mkExtendRow "ext";
  extNoCapRow = mkExtendRow "extNoCap";
  extNullRenderRow = mkExtendRow null;

  # an extend-mode inner: produces EvalHandleInfo, its payload the extendModules handle the render's
  # `extendsVia` capability extends (lazily).
  extInner = {
    product = "EvalHandleInfo";
    payload = {
      __handle = "an-eval-handle";
    };
    name = "box";
    kind = "host";
  };

  # ── Task 4 fixtures: provide / adapt / defer ──
  # the pure functionArgs binder + the defer executor, reached through the raw-gen-libs seam.
  inherit (denHoag.internal) bindArgs executeDefer;

  # a CONTENT row that also declares `provide` — the provide rider attaches on any mode. `provide outer`
  # returns the args to cross to the inner; the `outer` is the structural ctx handle (no content, §2.1).
  provideRow = flatRow // {
    provide = outer: {
      fromOuter = outer.paramPoint.name;
      pinned = "p";
    };
  };
  # a poison `provide` (throws when called) — the rider must carry it LAZILY (wiring never forces it).
  poisonProvideRow = flatRow // {
    provide = _: throw "provide outer forced — provide laziness violated";
  };

  # a FUNCTION-MODULE declaring exactly `{ osConfig, ... }` — the bindArgs intersection witness: only
  # functionArgs-declared args are bound, an undeclared arg (`unrelated`) is NOT.
  fnModule =
    { osConfig, ... }:
    {
      marker = osConfig.hostName;
    };
  # the arg environment `adapt` binds (an argEnv is a plain attrset of candidate args).
  argEnv = {
    osConfig = {
      hostName = "the-host";
    };
    unrelated = throw "undeclared arg forced — bindArgs bound a non-functionArgs arg";
  };

  # a DEFER record (R6): `{ needs = [paths]; then = vals: config; }`. The legal `then` returns a plain
  # CONFIG payload (no options/imports); the illegal one returns an attrset carrying `options`/`imports`.
  deferRecord = {
    needs = [
      [
        "a"
        "b"
      ]
      [ "c" ]
    ];
    "then" = vals: {
      networking.hostName = vals.host;
    };
  };
  deferIllegalOptions = {
    needs = [ ];
    "then" = _: {
      options.foo = "illegal";
    };
  };
  deferIllegalImports = {
    needs = [ ];
    "then" = _: {
      imports = [ { } ];
    };
  };
  # a poison `then` (throws when applied) — executeDefer must carry `thenFn` INERT (never applied at wiring).
  deferPoison = {
    needs = [ ];
    "then" = _: throw "defer thenFn applied during wiring — defer laziness violated";
  };

  # ── Task 5 fixtures: singular arity (both depths) + the laziness sweep ──
  # the singular / wiring / definition checks, reached through the raw-gen-libs seam.
  inherit (denHoag.internal) checkSingular checkSingularDefinition;

  # a SINGULAR-arity row and a MANY row (the default). `singularRow` is the mount whose live set must be ≤ 1.
  singularRow = flatRow // {
    arity = "singular";
  };
  manyRow = flatRow // {
    arity = "many";
  };

  # WIRING-TIME live-edge sets. Each edge is `{ id; when ? <bool>; }` — `when` is the fired flag (absent ⇒
  # unconditional, always live). `bothFire` = two live edges; `oneFalse` = one edge whose `when` is false
  # (filtered OUT before the check); `singleLive` = one live edge.
  bothFire = [
    { id = "e1"; }
    { id = "e2"; }
  ];
  oneFalse = [
    { id = "e1"; }
    {
      id = "e2";
      when = false;
    }
  ];
  singleLive = [ { id = "e1"; } ];

  # DEFINITION-TIME intent sets. `uncondPair` = two UNCONDITIONAL (no `when`) intents into one singular mount
  # (a static double-mount → throw). `condPair` = intents carrying a `when` (conditional) → PASS definition-
  # time, defer to wiring. `singleIntent` = one unconditional intent (fine).
  uncondPair = [
    { id = "i1"; }
    { id = "i2"; }
  ];
  condPair = [
    {
      id = "i1";
      when = "guardA";
    }
    {
      id = "i2";
      when = "guardB";
    }
  ];
  singleIntent = [ { id = "i1"; } ];

  # THE LAZINESS SWEEP: one row poisoning EVERY surface at once — a `provide` fn whose RESULT throws + an
  # `adapt` argEnv whose CONTENTS throw (the argEnv itself is a non-null attrset so the rider attaches; its
  # values are poison), on a content row, fed an inner whose payload throws. Wiring must build a fine
  # contribution; forcing any payload-bearing field would fire a poison, but the shape (mode + rider
  # presence) is forcible.
  sweepRow = flatRow // {
    provide = _: throw "provide result forced — sweep laziness violated";
    adapt = {
      poison = throw "adapt argEnv contents forced — sweep laziness violated";
    };
  };
  sweepInner = tuxInner // {
    payload = [ (throw "payload forced — sweep laziness violated") ];
  };
  # a ctx carrying an EXTRA content-thunk field beyond the structural handles — executeNest must read ONLY
  # the structural ctx (paramPoint), never this poison field (the structural-handles re-assertion).
  poisonCtx = {
    paramPoint = tuxPoint;
    __poisonContent = throw "ctx content field forced — structural-handles discipline violated";
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
    # a content row forced to ARTIFACT mode but naming NO render aborts NAMED — an artifact consume has no
    # way to build its face without a render row (§4.3). (T1 wrote this as an "unknown mode" stand-in when
    # artifact was unhandled; artifact is handled now, so its TRUE behavior is the missing-render throw — the
    # genuine unknown-mode witness is `test-nest-bogus-mode-throw` below.)
    test-nest-artifact-missing-render-throw = {
      expr = throws (executeNest {
        row = flatRow // {
          mode = "artifact"; # render defaults null on the content row → the missing-render throw.
        };
        inner = tuxInner;
        ctx = {
          paramPoint = tuxPoint;
        };
      });
      expected = true;
    };
    # a GENUINELY unknown mode reaches the defensive dispatch tail (the sibling-registry total-dispatch
    # posture — the tail STAYS): `mode = "bogus"` is none of content/artifact/extend/value, so graftMode's
    # final else fires the named unknown-mode throw.
    test-nest-bogus-mode-throw = {
      expr = throws (executeNest {
        row = flatRow // {
          mode = "bogus";
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
        # forcing the contribution's SHAPE — mode + the module LIST SPINE (`builtins.length`, which walks the
        # list without forcing any element) — must not force the poison module value.
        {
          inherit (contribution) mode;
          moduleCount = builtins.length contribution.modules;
        };
      expected = {
        mode = "content";
        moduleCount = 1;
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

    # ── §4.1 VALUE mode (the prebuilt ArtifactRef arm) ──
    # a clean unwrap: `inner.artifactRef.product` MATCHES the row's consumes (definitional acceptance) → a
    # value contribution carrying the prebuilt value verbatim, NO unrealizedCast, at the row's `at` path.
    test-nest-value-clean-unwrap = {
      expr =
        let
          c = executeNest {
            row = artifactRow;
            inner = cleanValueInner;
            ctx = {
              paramPoint = tuxPoint;
            };
          };
        in
        {
          inherit (c) mode value;
          at = c.at;
          hasCast = c ? unrealizedCast;
        };
      expected = {
        mode = "value";
        value = {
          __prebuilt = "a-real-system";
        };
        at = [ "sys" ];
        hasCast = false;
      };
    };
    # a WRAPPED-FACE MISMATCH (ArtifactRef HmInfo at consumes = SystemInfo): the value is STILL injected
    # verbatim (NOT an eval failure — conversions never apply to the prebuilt arm), and the contribution
    # carries the `unrealizedCast` marker (a trace-visible node, §4.1).
    test-nest-value-mismatch-marker = {
      expr =
        let
          c = executeNest {
            row = artifactRow;
            inner = mismatchValueInner;
            ctx = {
              paramPoint = tuxPoint;
            };
          };
        in
        {
          inherit (c) mode value;
          hasCast = c ? unrealizedCast;
        };
      expected = {
        mode = "value";
        value = {
          __prebuilt = "a-real-hm";
        };
        hasCast = true;
      };
    };
    # LAZINESS: the value arm's `value` is carried lazily — a poison prebuilt is not forced by wiring.
    test-nest-value-laziness-poison = {
      expr =
        (executeNest {
          row = artifactRow;
          inner = cleanValueInner // {
            artifactRef = {
              product = "SystemInfo";
              value = throw "prebuilt value forced — value-arm laziness violated";
            };
          };
          ctx = {
            paramPoint = tuxPoint;
          };
        }).mode;
      expected = "value";
    };

    # ── §4.1 the single-step CONVERSIONS consult (replaces the exact-match throw at a registered pair) ──
    # a (RawModulesInfo, ModulesInfo) mismatch WITH a registered conversion: `via` materializes the payload
    # and the contribution proceeds under the row's mode (content). The via tag proves the payload flowed
    # THROUGH via; the content graft (flat row) still places it.
    test-nest-conversion-found = {
      expr =
        let
          c = executeNest {
            row = flatRow; # consumes ModulesInfo
            inner = rawInner; # produces RawModulesInfo
            ctx = {
              paramPoint = tuxPoint;
            };
            conversions = nestConversions;
          };
        in
        {
          inherit (c) mode;
          converted = map (m: m.__converted or false) c.modules;
        };
      expected = {
        mode = "content";
        converted = [ true ];
      };
    };
    # a mismatch with NO registered conversion → the named throw stays (single-step: an empty table finds
    # nothing, so the throw fires exactly as before the consult).
    test-nest-conversion-not-found-throw = {
      expr = throws (executeNest {
        row = flatRow;
        inner = rawInner;
        ctx = {
          paramPoint = tuxPoint;
        };
        conversions = { }; # no pair registered → mismatch throw.
      });
      expected = true;
    };
    # LAZINESS: via-application is lazy — a poison payload with a matching conversion is not forced by wiring.
    test-nest-conversion-lazy-via = {
      expr =
        (executeNest {
          row = flatRow;
          inner = rawInner // {
            payload = throw "payload forced — conversion via applied eagerly";
          };
          ctx = {
            paramPoint = tuxPoint;
          };
          conversions = nestConversions;
        }).mode;
      expected = "content";
    };

    # ── §4.1 the entity-side `artifact` facet + the buckets-empty exclusivity ──
    # `artifact` is a declared FACET (a keySemantics facet-category key, sibling of settings/neededBy), so
    # classifyKey routes it as "facet" — a fleet aspect declaring only `artifact` builds (no class content).
    test-artifact-facet-well-formed = {
      expr = forceArtifactGate artifactOkFleet;
      expected = true;
    };
    # DECLARING BOTH — `artifact` AND a non-empty class content key on one aspect → the exclusivity throw
    # fires (§4.1: the prebuilt arm's class buckets must be empty; declaring both throws named).
    test-artifact-buckets-both-throw = {
      expr = throws (forceArtifactGate artifactBothFleet);
      expected = true;
    };
    # the pure decision fn directly: `artifactExclusive` on a synthetic aspect content carrying `artifact` +
    # a non-empty class key throws; carrying `artifact` alone (or a class key alone) passes.
    test-artifact-exclusive-pure = {
      expr = {
        both = throws (artifactExclusive {
          artifact = {
            __prebuilt = "x";
          };
          nixos = {
            imports = [ { marker = "n"; } ];
          };
          name = "a";
        });
        artifactOnly = artifactExclusive {
          artifact = {
            __prebuilt = "x";
          };
          name = "a";
        };
        classOnly = artifactExclusive {
          nixos = {
            imports = [ { marker = "n"; } ];
          };
          name = "a";
        };
      };
      expected = {
        both = true;
        artifactOnly = true; # passes → returns its truthy sentinel.
        classOnly = true;
      };
    };

    # ── §4.1 the cross-module conversions same-pair collision ──
    # two modules registering `den.conversions."A->B"` with different `via` → the module system's unique-merge
    # conflict fires at the `.via` key (the raw type never last-wins on non-equal records). Forcing the
    # fleet's own compiled conversion table (`den.conversions`) triggers the merge of the colliding key.
    test-conversions-cross-module-collision = {
      expr = throws (builtins.deepSeq collisionFleet.den.conversions true);
      expected = true;
    };

    # ── §4.2/§4.3 ARTIFACT mode (the render-row consult, isolated inner eval) ──
    # the artifact arm renders the inner through the row's render (`renders.${row.render}`): the evaluator
    # crosses the inner's modules and `face` projects the eval to the artifact. The fake evaluator's
    # `__fakeCrossed` tag + the `__face` projection prove the crossing routed through the render row.
    test-nest-artifact-render-face = {
      expr =
        let
          c = executeNest {
            row = artiFaceRow;
            inner = artiInner;
            ctx = {
              paramPoint = tuxPoint;
            };
            renders = nestRenders;
          };
        in
        {
          inherit (c) mode;
          at = c.at;
          artifact = c.artifact;
        };
      expected = {
        mode = "artifact";
        at = [ "sys" ];
        # face projects the eval: `{ __face = true; eval = <the crossed eval>; }`.
        artifact = {
          __face = true;
          eval = {
            __fakeCrossed = true;
            modules = [ { __seed = "m"; } ];
          };
        };
      };
    };
    # a NULL-FACE render: the eval itself IS the artifact (no projection). The contribution's `artifact` is
    # the raw crossed eval.
    test-nest-artifact-null-face = {
      expr =
        (executeNest {
          row = artiNoFaceRow;
          inner = artiInner;
          ctx = {
            paramPoint = tuxPoint;
          };
          renders = nestRenders;
        }).artifact;
      expected = {
        __fakeCrossed = true;
        modules = [ { __seed = "m"; } ];
      };
    };
    # LAZINESS: the evaluator is NOT called during wiring — a poison evaluator (throws when called) builds a
    # fine contribution; only forcing `.artifact` would fire it. Forcing the SHAPE (mode) does not.
    test-nest-artifact-laziness-poison = {
      expr =
        let
          poisonRenders = nestRenders // {
            arti = nestRenders.arti // {
              evaluator = _: throw "evaluator called during wiring — artifact laziness violated";
            };
          };
        in
        (executeNest {
          row = artiFaceRow;
          inner = artiInner;
          ctx = {
            paramPoint = tuxPoint;
          };
          renders = poisonRenders;
        }).mode;
      expected = "artifact";
    };

    # ── §4.2/§4.3 EXTEND mode (legal only under a render's extendsVia) ──
    # the extend arm wraps the render's `extendsVia` capability applied to the inner's EvalHandleInfo payload
    # (the extendModules handle), LAZILY. The fake `extendsVia` records the extension in `__extended`.
    test-nest-extend-under-capability = {
      expr =
        let
          c = executeNest {
            row = extRow;
            inner = extInner;
            ctx = {
              paramPoint = tuxPoint;
            };
            renders = nestRenders;
          };
        in
        {
          inherit (c) mode;
          at = c.at;
          extended = c.extended;
        };
      expected = {
        mode = "extend";
        at = [ "ext" ];
        extended = {
          __extended = {
            __handle = "an-eval-handle";
          };
        };
      };
    };
    # a render with NO `extendsVia` (extNoCap) → the missing-capability throw (`den.nest:` register): extend
    # is legal ONLY when the consulted render declares the capability.
    test-nest-extend-no-capability-throw = {
      expr = throws (executeNest {
        row = extNoCapRow;
        inner = extInner;
        ctx = {
          paramPoint = tuxPoint;
        };
        renders = nestRenders;
      });
      expected = true;
    };
    # an extend-mode row naming NO render (render = null) → the same missing-capability path (criterion 4:
    # the extend arm needs a render reference to find the extendsVia; a null render is the missing capability).
    test-nest-extend-null-render-throw = {
      expr = throws (executeNest {
        row = extNullRenderRow;
        inner = extInner;
        ctx = {
          paramPoint = tuxPoint;
        };
        renders = nestRenders;
      });
      expected = true;
    };
    # LAZINESS: the extend handle capability is NOT called during wiring — a poison `extendsVia` (throws when
    # called) builds a fine contribution; only forcing `.extended` would fire it.
    test-nest-extend-laziness-poison = {
      expr =
        let
          poisonRenders = nestRenders // {
            ext = nestRenders.ext // {
              extendsVia = _: throw "extendsVia called during wiring — extend laziness violated";
            };
          };
        in
        (executeNest {
          row = extRow;
          inner = extInner;
          ctx = {
            paramPoint = tuxPoint;
          };
          renders = poisonRenders;
        }).mode;
      expected = "extend";
    };

    # ── THE CARRIED WITNESS (value acceptance is mode-independent, §4.1) ──
    # a value-inner (`inner ? artifactRef`) against a row whose mode is NOT content (here artifact mode)
    # STILL succeeds as value — definitional acceptance is mode-independent (the prebuilt arm short-circuits
    # before any mode dispatch). `artiFaceRow` is an artifact-mode row; the clean prebuilt SystemInfo value
    # rides through as a value contribution regardless.
    test-nest-value-mode-independent = {
      expr =
        let
          c = executeNest {
            row = artiFaceRow; # artifact mode
            inner = cleanValueInner; # a prebuilt ArtifactRef SystemInfo
            ctx = {
              paramPoint = tuxPoint;
            };
            renders = nestRenders;
          };
        in
        {
          inherit (c) mode value;
        };
      expected = {
        mode = "value";
        value = {
          __prebuilt = "a-real-system";
        };
      };
    };

    # ── §4.8 PROVIDE (inert lazy args, both delivery arms) ──
    # a row declaring `provide` attaches a `provideArgs` rider carrying BOTH arms: `specialArgs` (the
    # extraSpecialArgs-style thunk, for crossings that expose it) and `argsModule` (the `_module.args`
    # module, the fallback). Both are `provide outer` — the args crossed to the inner from the outer handle.
    test-nest-provide-both-arms = {
      expr =
        let
          c = executeNest {
            row = provideRow;
            inner = tuxInner;
            ctx = {
              paramPoint = tuxPoint;
            };
          };
        in
        {
          hasRider = c ? provideArgs;
          specialArgs = c.provideArgs.specialArgs;
          argsModule = c.provideArgs.argsModule;
        };
      expected = {
        hasRider = true;
        specialArgs = {
          fromOuter = "tux";
          pinned = "p";
        };
        # the module arm places the SAME args under `_module.args`.
        argsModule = {
          _module.args = {
            fromOuter = "tux";
            pinned = "p";
          };
        };
      };
    };
    # LAZINESS: `provide outer` is NOT forced at wiring — a poison provide builds a fine contribution; only
    # forcing `.provideArgs.specialArgs` would fire it. The base content contribution is intact.
    test-nest-provide-laziness-poison = {
      expr =
        let
          c = executeNest {
            row = poisonProvideRow;
            inner = tuxInner;
            ctx = {
              paramPoint = tuxPoint;
            };
          };
        in
        {
          inherit (c) mode;
          hasRider = c ? provideArgs;
        };
      expected = {
        mode = "content";
        hasRider = true;
      };
    };

    # ── §4.8 ADAPT (functionArgs binding) ──
    # `bindArgs argEnv fnModule` binds ONLY the functionArgs-declared args of the fn-module (intersection):
    # `fnModule` declares `{ osConfig, ... }`, so `osConfig` is bound (its body reads `osConfig.hostName`);
    # the undeclared `unrelated` arg (a poison in the argEnv) is NEVER bound, so it never forces.
    test-nest-adapt-bindargs-intersection = {
      expr = (bindArgs argEnv fnModule).marker;
      expected = "the-host";
    };
    # the undeclared arg is not bound: binding `{ osConfig, ... }` against an argEnv whose `unrelated` throws
    # succeeds precisely because `unrelated` is outside the fn's functionArgs (a poison-witness of the
    # intersection). Proven by the intersection test above returning without forcing `unrelated`; here we
    # pin that a fn declaring NO formals binds nothing (empty intersection → the module rides unbound).
    test-nest-adapt-bindargs-undeclared-unbound = {
      expr =
        let
          bare = bindArgs argEnv (_: {
            ran = true;
          });
        in
        bare.ran;
      expected = true;
    };

    # ── §4.8 DEFER (the inert config-only record) ──
    # `executeDefer record` → the INERT `{ mode = "defer"; needs; thenFn; }` record (no terminal consumer
    # yet). The needs paths ride verbatim; `thenFn` is the record's `then`, carried unforced.
    test-nest-defer-inert-record = {
      expr =
        let
          c = executeDefer {
            record = deferRecord;
          };
        in
        {
          inherit (c) mode needs;
          isFn = builtins.isFunction c.thenFn;
        };
      expected = {
        mode = "defer";
        needs = [
          [
            "a"
            "b"
          ]
          [ "c" ]
        ];
        isFn = true;
      };
    };
    # the legal `then` payload (a plain config, no options/imports) is carried LAZILY — applying `thenFn`
    # against the resolved vals yields the config, and the shape-check passes.
    test-nest-defer-legal-config = {
      expr =
        let
          c = executeDefer {
            record = deferRecord;
          };
        in
        (c.thenFn { host = "resolved"; }).networking.hostName;
      expected = "resolved";
    };
    # an ILLEGAL `then` producing `options` → named throw when the payload shape is checked (§4.8: a defer's
    # `then` produces config, never options/imports).
    test-nest-defer-illegal-options-throw = {
      expr = throws (
        (executeDefer {
          record = deferIllegalOptions;
        }).thenFn
          { }
      );
      expected = true;
    };
    # an ILLEGAL `then` producing `imports` → named throw likewise.
    test-nest-defer-illegal-imports-throw = {
      expr = throws (
        (executeDefer {
          record = deferIllegalImports;
        }).thenFn
          { }
      );
      expected = true;
    };
    # LAZINESS: `executeDefer` carries `thenFn` INERT — a poison `then` builds a fine record; only APPLYING
    # `thenFn` would fire it. Forcing the record shape (mode/needs) does not.
    test-nest-defer-laziness-poison = {
      expr =
        let
          c = executeDefer {
            record = deferPoison;
          };
        in
        {
          inherit (c) mode;
          needsLen = builtins.length c.needs;
        };
      expected = {
        mode = "defer";
        needsLen = 0;
      };
    };

    # ── §4.2 SINGULAR arity — WIRING-TIME (the live set, post-`when`) ──
    # the `when` filter is applied BEFORE the check: an edge whose `when` is false is NOT in the live set, so
    # two edges where one is filtered out do NOT throw (only ONE live edge into the singular mount).
    test-nest-singular-wiring-one-when-false = {
      expr = checkSingular {
        row = singularRow;
        edges = oneFalse;
        mount = "host.slot";
      };
      # returns the live edge set unchanged (no throw) when singular holds.
      expected = [ { id = "e1"; } ];
    };
    # both edges FIRE (both live) into a singular mount → named throw naming the mount + both edge ids.
    test-nest-singular-wiring-both-fire-throw = {
      expr = throws (checkSingular {
        row = singularRow;
        edges = bothFire;
        mount = "host.slot";
      });
      expected = true;
    };
    # arity = "many" NEVER throws, regardless of how many edges fire.
    test-nest-singular-wiring-many-never-throws = {
      expr = checkSingular {
        row = manyRow;
        edges = bothFire;
        mount = "host.slot";
      };
      expected = bothFire; # the full set returned, no throw.
    };
    # a single live edge into a singular mount is fine.
    test-nest-singular-wiring-single-ok = {
      expr = checkSingular {
        row = singularRow;
        edges = singleLive;
        mount = "host.slot";
      };
      expected = singleLive;
    };

    # ── §4.2 SINGULAR arity — DEFINITION-TIME (unconditional edges, both depths) ──
    # two UNCONDITIONAL (no `when`) intents into a singular mount throw at DEFINITION time (a static
    # double-mount — the spec's "both depths"). Named, naming the mount + both intent ids.
    test-nest-singular-definition-uncond-pair-throw = {
      expr = throws (checkSingularDefinition {
        row = singularRow;
        intents = uncondPair;
        mount = "host.slot";
      });
      expected = true;
    };
    # CONDITIONAL intents (each carrying a `when`) PASS definition-time and defer to wiring — a static pair of
    # guarded intents is NOT a definition-time violation (they may never co-fire).
    test-nest-singular-definition-conditional-defers = {
      expr = checkSingularDefinition {
        row = singularRow;
        intents = condPair;
        mount = "host.slot";
      };
      expected = condPair; # no throw — the guarded pair defers to wiring.
    };
    # a single unconditional intent is fine at definition time.
    test-nest-singular-definition-single-ok = {
      expr = checkSingularDefinition {
        row = singularRow;
        intents = singleIntent;
        mount = "host.slot";
      };
      expected = singleIntent;
    };
    # arity = "many" never throws at definition time either.
    test-nest-singular-definition-many-never-throws = {
      expr = checkSingularDefinition {
        row = manyRow;
        intents = uncondPair;
        mount = "host.slot";
      };
      expected = uncondPair;
    };

    # ── THE LAZINESS SWEEP (uniform structural-handles / laziness re-assertion) ──
    # ONE executeNest call whose row carries provide + adapt riders AND a poison payload — every payload-
    # bearing surface poisoned at once. Wiring builds a fine contribution: the mode + rider presence are
    # forcible, but no poison fires (the placed modules, the provideArgs, the adaptEnv all stay thunks).
    test-nest-laziness-sweep-combined = {
      expr =
        let
          c = executeNest {
            row = sweepRow;
            inner = sweepInner;
            ctx = {
              paramPoint = tuxPoint;
            };
          };
        in
        {
          inherit (c) mode;
          hasProvide = c ? provideArgs;
          hasAdapt = c ? adaptEnv;
          moduleCount = builtins.length c.modules; # walks the spine, forces no element.
        };
      expected = {
        mode = "content";
        hasProvide = true;
        hasAdapt = true;
        moduleCount = 1;
      };
    };
    # STRUCTURAL-HANDLES re-assertion: executeNest reads ONLY the structural ctx fields (paramPoint). A ctx
    # carrying an EXTRA content-thunk field is never read — FULLY forcing the contribution (`deepSeq` over the
    # clean `flatRow`/`tuxInner`, whose payload is real, not poison) leaves the poison ctx field untouched
    # (the §2.1 structural-handles discipline, engine-wide; the deep force also guards a lazy-field regression).
    test-nest-structural-handles-ctx-probe = {
      expr = builtins.deepSeq (executeNest {
        row = flatRow;
        inner = tuxInner;
        ctx = poisonCtx;
      }) "forced-clean";
      expected = "forced-clean";
    };

    # ── §4.4 the output-families registry (den.outputs) ──
    # a well-formed family row compiles: `at` is carried (a registry-resident placement fn), `consumes` is
    # validated + stored, `render` names a built-in render row, `params` names the `system` axis, and the
    # optional `requires` defaults to `[ ]`.
    test-outputs-row-compiles = {
      expr = {
        hasFamily = goodOutputs ? nixosConfigurations;
        atIsFn = builtins.isFunction goodOutputs.nixosConfigurations.at;
        consumes = goodOutputs.nixosConfigurations.consumes;
        render = goodOutputs.nixosConfigurations.render;
        params = goodOutputs.nixosConfigurations.params;
        requires = goodOutputs.nixosConfigurations.requires;
      };
      expected = {
        hasFamily = true;
        atIsFn = true;
        consumes = "SystemInfo";
        render = "nixos";
        params = [ "system" ];
        requires = [ ];
      };
    };
    # F1 AS A CHECKED LAW (mirrored from receivers): a USER-declared `mode` field on a family row aborts
    # NAMED — mode derives from consumes, so a user `mode` is a definition error (never silently absorbed).
    test-outputs-mode-field-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
          consumes = "SystemInfo";
          mode = "artifact";
        };
      });
      expected = true;
    };
    # a family row declaring no `at` aborts NAMED — the `point: e: <path>` placement is required.
    test-outputs-no-at-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          consumes = "SystemInfo";
        };
      });
      expected = true;
    };
    # a family row declaring no `consumes` aborts NAMED — the product face is required.
    test-outputs-no-consumes-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
        };
      });
      expected = true;
    };
    # `consumes` names an unregistered product → the products table's checkConsumes aborts NAMED (reused,
    # not re-implemented).
    test-outputs-consumes-unregistered-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
          consumes = "NopeInfo";
        };
      });
      expected = true;
    };
    # `consumes` names a non-nestable product (ArgsInfo) → checkConsumes aborts NAMED (never a consumes).
    test-outputs-consumes-non-nestable-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
          consumes = "ArgsInfo";
        };
      });
      expected = true;
    };
    # `render` (when present) names a registered render row — an unregistered render aborts NAMED.
    test-outputs-render-unregistered-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
          consumes = "SystemInfo";
          render = "ghostrender";
        };
      });
      expected = true;
    };
    # `render` is legal ONLY on an artifact-mode family (mirrored from receivers): a render on a content-mode
    # consumes (ModulesInfo) aborts NAMED — the family's render IS the artifact evaluator, and a content
    # family (the future flake-parts transposition path) has none. Sibling parity, no silent divergence.
    test-outputs-render-non-artifact-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
          consumes = "ModulesInfo";
          render = "nixos";
        };
      });
      expected = true;
    };
    # `params` names a KNOWN AXIS — today exactly `"system"`; an unknown axis aborts NAMED.
    test-outputs-params-unknown-axis-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
          consumes = "SystemInfo";
          params = [ "arch" ];
        };
      });
      expected = true;
    };
    # `requires` names a registered product (shape-check only this task) — an unregistered product aborts
    # NAMED. Consumption of requires arrives with a later task.
    test-outputs-requires-unregistered-throw = {
      expr = throws (compileOutputs {
        nixosConfigurations = {
          at = _: e: [ e.name ];
          consumes = "SystemInfo";
          requires = [ "NopeInfo" ];
        };
      });
      expected = true;
    };
    # LAZINESS: compiling a family never forces an UNRELATED family's `at` VALUE — a poison thunk in a
    # sibling family's `at` must not fire when a good family is read (a registry holds functions as thunks).
    test-outputs-laziness-poison = {
      expr =
        (compileOutputs {
          good = {
            at = _: e: [ e.name ];
            consumes = "SystemInfo";
            render = "nixos";
          };
          bad = {
            at = throw "sibling family at forced — outputs laziness violated";
            consumes = "SystemInfo";
          };
        }).good.consumes;
      expected = "SystemInfo";
    };

    # ── §4.4 the `den.systems` axis surface ──
    # `den.systems` is a plain list option (default `[ ]`), surfaced under the den output — the axis whose
    # values the `system` param names. An unset fleet surfaces the empty default.
    test-den-systems-default-empty = {
      expr =
        (denHoag.mkDen [
          { config.den.schema.server.parent = null; }
          { config.den.server.box1 = { }; }
        ]).den.systems;
      expected = [ ];
    };
    # a fleet declaring `den.systems` surfaces the declared list verbatim.
    test-den-systems-declared = {
      expr =
        (denHoag.mkDen [
          { config.den.schema.server.parent = null; }
          {
            config.den = {
              server.box1 = { };
              systems = [
                "x86_64-linux"
                "aarch64-darwin"
              ];
            };
          }
        ]).den.systems;
      expected = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };
    # the per-fleet compile runs inside the mkDen closure: `den.outputs` surfaces the compiled families
    # table. A fleet declaring a family with a `system` param whose axis values are `den.systems` compiles
    # (the param axis validation reads the axis registry, not the values). The compiled row's `consumes` +
    # `render` are validated against the per-fleet products/renders.
    test-den-outputs-compiled-per-fleet = {
      expr =
        let
          fleet = denHoag.mkDen [
            { config.den.schema.server.parent = null; }
            {
              config.den = {
                server.box1 = { };
                systems = [ "x86_64-linux" ];
                outputs.nixosConfigurations = {
                  at = _point: e: [ e.name ];
                  consumes = "SystemInfo";
                  render = "nixos";
                  params = [ "system" ];
                };
              };
            }
          ];
        in
        {
          hasFamily = fleet.den.outputs ? nixosConfigurations;
          consumes = fleet.den.outputs.nixosConfigurations.consumes;
          render = fleet.den.outputs.nixosConfigurations.render;
        };
      expected = {
        hasFamily = true;
        consumes = "SystemInfo";
        render = "nixos";
      };
    };
    # a family declaring a `system` param whose render is unknown aborts NAMED at the per-fleet compile
    # (proving the compile sits inside the closure, reading the fleet's own render rows).
    test-den-outputs-per-fleet-render-throw = {
      expr = throws (
        builtins.deepSeq
          (denHoag.mkDen [
            { config.den.schema.server.parent = null; }
            {
              config.den = {
                server.box1 = { };
                outputs.nixosConfigurations = {
                  at = _point: e: [ e.name ];
                  consumes = "SystemInfo";
                  render = "ghostrender";
                };
              };
            }
          ]).den.outputs
          true
      );
      expected = true;
    };

    # ── §4.4/§4.6 the ROOT kind — families as root receiver rows through the REAL dispatch ──
    # the projection yields a `root.receives.<family>` row carrying the §4.2 contract only. `at`/`consumes`/
    # `render` ride through; `arity`/`multiplicity` default; `params`/`requires` are NOT §4.2 fields (they
    # stayed on the family row) so they are absent on the receives row.
    test-outputs-root-projection = {
      expr = {
        hasRoot = rootKinds ? root;
        hasFamily = rootKinds.root.receives ? nixosConfigurations;
        consumes = rootKinds.root.receives.nixosConfigurations.consumes;
        mode = rootKinds.root.receives.nixosConfigurations.mode;
        render = rootKinds.root.receives.nixosConfigurations.render;
        arity = rootKinds.root.receives.nixosConfigurations.arity;
        multiplicity = rootKinds.root.receives.nixosConfigurations.multiplicity;
        keepsParams = rootKinds.root.receives.nixosConfigurations ? params;
        # `at` (the load-bearing placement fn) rides through — applied to a point + entity it yields the
        # family's `[ <entityName> ]` path (the projection carried the SAME fn, not a stub).
        atPlacement = rootKinds.root.receives.nixosConfigurations.at { } { name = "igloo"; };
      };
      expected = {
        hasRoot = true;
        hasFamily = true;
        consumes = "SystemInfo";
        mode = "artifact"; # DERIVED by the receivers compile from consumes (F1) — the projection didn't set it.
        render = "nixos";
        arity = "many";
        multiplicity = "error";
        keepsParams = false; # params stays on the family row, off the §4.2 receives row.
        atPlacement = [ "igloo" ];
      };
    };
    # (2) DISPATCH: the family resolves through the REAL `resolveReceiver` — slot phase. Resolving `root`'s
    # `nixosConfigurations` slot returns the projected family row (the same machinery a nested receives row uses).
    test-outputs-root-dispatch-slot = {
      expr =
        (resolveReceiver {
          compiledKinds = rootKinds;
          outerKind = "root";
          slot = "nixosConfigurations";
          class = "nixos";
        }).consumes;
      expected = "SystemInfo";
    };
    # a class-fallback witness: `root.receives.<class>` is legal like any kind's — a slot with no row falls
    # back to the class row. Here a `nixos` family row (class-named) resolves when the slot is absent.
    test-outputs-root-dispatch-class-fallback = {
      expr =
        let
          classRoot = receivers.compile {
            rows = outputsLib.toReceives {
              nixos = {
                at = _point: e: [ e.name ];
                consumes = "SystemInfo";
                render = "nixos";
              };
            };
            knownKinds = [ "root" ];
            products = frameworkProducts;
            renders = pureRenders;
          };
        in
        (resolveReceiver {
          compiledKinds = classRoot;
          outerKind = "root";
          slot = "ghostslot";
          class = "nixos";
        }).consumes;
      expected = "SystemInfo";
    };
    # (3) `root` is FRAMEWORK-RESERVED: a user declaring `den.kinds.root` directly aborts NAMED (the sibling
    # reserved posture) — root is the output-side receiver locus, not a user-writable receives entry.
    test-outputs-root-user-kinds-reserved-throw = {
      expr = throws (
        builtins.deepSeq
          (denHoag.mkDen [
            { config.den.schema.server.parent = null; }
            {
              config.den = {
                server.box1 = { };
                kinds.root.receives.x = {
                  at = _: e: [ e.name ];
                  consumes = "SystemInfo";
                };
              };
            }
          ]).den.kinds
          true
      );
      expected = true;
    };
    # a kind literally NAMED `root` declared in den.schema aborts NAMED at kind discovery (mirroring the
    # existing `kinds` guard — same site, same message shape).
    test-outputs-root-schema-kind-reserved-throw = {
      expr = throws (
        denHoag.mkDen [
          { config.den.schema.root.parent = null; }
        ]
      );
      expected = true;
    };
    # the root entry is COMPOSED into the per-fleet receivers compile: a fleet declaring `den.outputs`
    # surfaces its families as `den.kinds.root.receives.<family>` rows (routed through the real receivers
    # compile), so `den.kinds` carries the `root` entry the dispatch resolves against.
    test-outputs-root-composed-in-fleet = {
      expr =
        let
          fleet = denHoag.mkDen [
            { config.den.schema.server.parent = null; }
            {
              config.den = {
                server.box1 = { };
                outputs.nixosConfigurations = {
                  at = _point: e: [ e.name ];
                  consumes = "SystemInfo";
                  render = "nixos";
                };
              };
            }
          ];
        in
        {
          hasRoot = fleet.den.kinds ? root;
          hasFamily = fleet.den.kinds.root.receives ? nixosConfigurations;
          mode = fleet.den.kinds.root.receives.nixosConfigurations.mode;
        };
      expected = {
        hasRoot = true;
        hasFamily = true;
        mode = "artifact";
      };
    };
  };
}
