# compat-legacy-severed (C5) — legacy SEVERABILITY, both halves. Part 1 (the forwards surface, its two
# tiers, the `den.interpret.synthesize` seam, and the Law-C5 forwards sentinel) landed in Task 5. Part 2
# (C6, this task) lands the SEVERABILITY PROOF proper: `flakeModuleCore` ALONE and each single-legacy
# combination leave every NON-LEGACY fixture byte-identical (declaration set + trace) vs the full
# `flakeModule`; a severed surface's use is a named sentinel abort; and no core/other path IMPORTS a
# legacy module (the modules are wired at exactly one site — default.nix, the assembly).
# Ground truth: the frozen pin denful/den@11866c16 forward system + the PIN.md corpus census.
#
#   TIER-1 (static forward, no adapter) → a plain `deliver` (collected source, reroute-shaped), the same
#     surface the corpus takes — identical to v1's tier-1 classification. Witnesses: the 3 home-platform
#     routes (homeLinux/homeDarwin/homeAarch64 → home-manager, path=[], no adaptArgs).
#   COMPLEX (adapter-bearing) → an INERT gen-edge `synthesize` source record with identity triple
#     (forwardId, fromClass, intoClass) + this module's `interpret.synthesize`. Witnesses: the hm
#     delivery (osConfig-threading adaptArgs) and the devshell route (allModuleArgs adaptArgs) — the two
#     adapter shapes PIN.md records. The record is inert (trace renders identity, never forces content);
#     the interpreter RUNS at materialization, threaded through den.interpret (item 7).
#   SENTINEL — a `den.classes.<c>.forwardTo` reaching compile un-desugared (severed module) is a named
#     definition-time error (Law C5), parallel to the `provides` sentinel.
#
# CONTENT DEFERRAL (checked-in TODO, plan §C5): this suite pins the DECLARATION + TRACE half of C5(a)'s
# byte-identity. The CONTENT half (drv-hash equality of a severed vs full mkDen) rides Task 8's
# `parity-content` (P2), which needs the two-arm harness to exist first — see parity/tests/ (Task 8).
{
  denHoag,
  denCompat,
  denHoagSrc,
  lib,
  ...
}:
let
  fwd = denCompat.legacy.forwards;
  edge = denHoag.internal.edge;

  # ── the corpus forward-tier witnesses (forward SPECS mirroring PIN.md's shapes) ──────────────────────
  # Tier-1: the 3 home-platform static forwards (path=[], no adapter) → plain deliver.
  tier1Specs = {
    homeLinux = {
      fromClass = "homeLinux";
      intoClass = "home-manager";
    };
    homeDarwin = {
      fromClass = "homeDarwin";
      intoClass = "home-manager";
    };
    homeAarch64 = {
      fromClass = "homeAarch64";
      intoClass = "home-manager";
    };
  };

  # Complex: the 2 adapter-bearing routes → synthesize record + interpret.synthesize.
  #   hm delivery — os-user.nix threads osConfig: `adaptArgs = args: args // { osConfig = args.config; }`.
  hmSpec = {
    fromClass = "user";
    intoClass = "nixos";
    adapterKey = "user/nixos/users/users/alice";
    intoPath = [
      "users"
      "users"
      "alice"
    ];
    adaptArgs = args: args // { osConfig = args.config or { }; };
    sourceModule = {
      config.programs.git.enable = true;
    };
  };
  #   devshell route — `adaptArgs = { config, ... }: config.allModuleArgs`.
  devshellSpec = {
    fromClass = "devshell";
    intoClass = "flake-parts";
    adapterKey = "devshell/flake-parts/devshells/default";
    intoPath = [
      "devshells"
      "default"
    ];
    adaptArgs = { config, ... }: config.allModuleArgs or { };
    sourceModule = {
      config.packages = [ "hello" ];
    };
  };

  # ── the desugar outputs ──────────────────────────────────────────────────────────────────────────
  tier1Out = builtins.mapAttrs (_: fwd.forward) tier1Specs;
  hmRecord = fwd.forward hmSpec;
  devshellRecord = fwd.forward devshellSpec;

  # ── (D) the interpreter RUN through gen-edge's materialize fold (item 7) ──────────────────────────
  # A minimal synthesize edge (merge → the target's output cell) folded with the legacy interpreter, to
  # prove interpret.synthesize is a REAL function den-hoag threads into `materialize`, not inert data.
  synEdge = edge.edge {
    source = hmRecord;
    target = edge.targets.root {
      root = "host:h";
      class = "nixos";
    };
    mode = "merge";
  };
  folded = edge.materialize {
    edges = edge.toposort [ synEdge ];
    projection = {
      contents = { };
      universe = [ ];
      dedupMode = "raw";
    };
    interpret = fwd.interpret;
  };
  # the folded content is the composed module (a FUNCTION module — the adaptArgs arm threads args).
  foldedContent = builtins.head folded."host:h".nixos;

  # ── (E) inert: the trace renders the synthesize identity WITHOUT forcing the carried module ────────
  # (records identity, never content — v1's sourceVia="unresolved"). Module = throw ⇒ trace still renders.
  inertEdge = edge.edge {
    source = fwd.synthRecord (
      hmSpec // { sourceModule = throw "content must NOT be forced by trace"; }
    );
    target = edge.targets.root {
      root = "host:h";
      class = "nixos";
    };
    mode = "nest";
    path = hmSpec.intoPath;
    annotations = {
      complexForward = true;
      sourceVia = "unresolved";
    };
  };
  inertTraced = builtins.head (edge.trace [ inertEdge ]);

  # ── (F) the Law-C5 sentinel: a forwardTo reaching compile un-desugared is a named error ────────────
  # Force the compiled class (the sentinel is a lazy `seq` inside translateClass) so the throw is observed.
  # NB: tryEval .success — TRUE means the eval SURVIVED (sentinel did NOT fire); tests expect false.
  forwardToCompilesClean =
    (builtins.tryEval (
      builtins.seq
        (denCompat.compile {
          classes.myclass.forwardTo = {
            class = "other";
            path = [ ];
          };
        }).classes.myclass
        null
    )).success;
  # a class WITHOUT forwardTo compiles clean (the sentinel is surgical, not a blanket class reject).
  cleanClassOk =
    (builtins.tryEval (
      builtins.seq (denCompat.compile { classes.plain.wrap = null; }).classes.plain null
    )).success;

  # ── (G) desugar strips forwardTo (present-module path: the sentinel then passes) ───────────────────
  desugared = fwd.desugar {
    classes = {
      c1.forwardTo = {
        class = "x";
        path = [ ];
      };
      c1.wrap = null;
      c2.share.core = true;
    };
  };

  # ══ SEVERABILITY PROOF (C6) — the wirings share ONE compile core, sentinels, and errors; only
  #    `desugarLegacy` (hence `compileFull` / `mkDen`) differs by which legacy modules are present
  #    (default.nix `mkWiring`). ══════════════════════════════════════════════════════════════════════
  #
  # AMBIENT-DELTA SCOPING (Task 8 M1): the built-in batteries (legacy/defaults.nix — os-class/os-user)
  # are v1's DEFAULT module set, so under the full flakeModule they add os/user classes + os-to-host /
  # user-to-host policies to EVERY fleet (v1's ambient semantics). That is a REAL severable surface — its
  # own severability is witnessed below (`test-defaults-ambient-*`) — but it is ORTHOGONAL to the
  # provides/forwards severance these H/I comparisons pin. So the provides/forwards comparison HOLDS THE
  # AMBIENT CONSTANT: every compared wiring carries `ambient` (defaults + self-provide), and only
  # provides/forwards vary. This scopes the byte-identity to the non-ambient surface WITHOUT weakening it
  # (a provides/forwards leak still moves the projection); the ambient's presence/absence is tested
  # separately. `mkWiring { }` (flakeModuleCore ALONE — no ambient) is exercised by the ambient witness.
  ambient = {
    inherit (denCompat.legacy) defaults self-provide;
  };
  full = denCompat; # the full flakeModule: ambient + provides + forwards
  core = denCompat.mkWiring ambient; # ambient held, provides+forwards severed
  provOnly = denCompat.mkWiring (ambient // { inherit (denCompat.legacy) provides; });
  fwdOnly = denCompat.mkWiring (ambient // { inherit (denCompat.legacy) forwards; });
  wirings = [
    full
    core
    provOnly
    fwdOnly
  ];

  # The ambient witness: a bare wiring (NO legacy at all — flakeModuleCore alone) vs an ambient wiring.
  # Severing legacy/defaults.nix removes the v1-ambient os/user classes + os-to-host/user-to-host routes,
  # so they appear ONLY when defaults is present — the defaults-surface severability, kept honest.
  bare = denCompat.mkWiring { }; # flakeModuleCore ALONE
  ambientWiring = denCompat.mkWiring { inherit (denCompat.legacy) defaults; };
  ambientProbe = w: (w.compileFull { }).policies or { };

  # NON-LEGACY fixtures (no `provides`, no `forwardTo`): the legacy desugars are or-identity on them, so
  # every wiring must compile them byte-identically. `edgeRoute` emits real trace edges (a channel→channel
  # `deliver`, the trace-half witness); `policyInclude` / `quirkChannel` exercise the include + channel
  # surfaces (declaration-half witnesses).
  edgeRoute = {
    hosts.x86_64-linux.axon.class = "nixos";
    quirks.src = { };
    quirks.dst = { };
    aspects.seed.src = [ "hello" ];
    schema.host.includes = [ "seed" ];
    policies.route1 = _ctx: [
      (denCompat.deliver {
        from = "src";
        to = "dst";
      })
    ];
  };
  nonLegacy = {
    inherit edgeRoute;
    policyInclude = {
      hosts.x86_64-linux.axon.class = "nixos";
      aspects.a = { };
      policies.attachA = _ctx: [
        {
          __policyEffect = "include";
          value = {
            name = "a";
          };
        }
      ];
    };
    quirkChannel = {
      quirks.metric = { };
      aspects.svc.metric = [ "x" ];
    };
  };

  # C5(a) DECLARATION-SET byte-identity — attrNames + id_hashes only (no function is forced, so a
  # parametric body never enters the comparison). A fixture's projection must be `==` across all wirings.
  declProj = c: {
    kinds = builtins.attrNames c.entities.schema;
    regIds = builtins.mapAttrs (_: r: builtins.mapAttrs (_: e: e.id_hash) r) c.entities.registries;
    members = builtins.length c.entities.membership;
    aspectKeys = builtins.mapAttrs (n: _: builtins.attrNames c.aspects.${n}) c.aspects;
    policyNames = builtins.attrNames c.policies;
    classKeys = builtins.mapAttrs (n: _: builtins.attrNames c.classes.${n}) c.classes;
    channelKeys = builtins.mapAttrs (n: _: builtins.attrNames c.channels.${n}) c.channels;
  };
  declSeverable =
    fx:
    let
      ps = map (w: declProj (w.compileFull fx)) wirings;
    in
    builtins.all (p: p == builtins.head ps) ps;

  # C5(a) TRACE byte-identity — mkDen through a wiring, union the per-root traces (the frozen T|P|S|M
  # sort-key strings), compare across wirings. (CONTENT / drv-hash defers to Task 8's parity-content.)
  v1mod = fx: { config.den = fx; };
  unionTrace =
    result:
    let
      den = result.den;
    in
    edge.trace (builtins.concatMap (r: den.graph.edges r) (builtins.attrNames den.scopeRoots));
  traceFull = unionTrace (full.mkDen [ (v1mod edgeRoute) ]);
  traceCore = unionTrace (core.mkDen [ (v1mod edgeRoute) ]);
  traceProv = unionTrace (provOnly.mkDen [ (v1mod edgeRoute) ]);
  traceFwd = unionTrace (fwdOnly.mkDen [ (v1mod edgeRoute) ]);

  # C5(b) SENTINELS — a severed surface's use aborts named. Force the offending aspect/class to trip the
  # lazy `seq` sentinel inside translate{Aspect,Class}. `provTrips`/`fwdTrips` are `true` when it aborts.
  providesFixture = {
    aspects.foo.provides.to-users = {
      nixos.services.foo.enable = true;
    };
  };
  fwdFixture = {
    classes.myclass.forwardTo = {
      class = "nixos";
      path = [ ];
    };
  };
  provTrips =
    w: !(builtins.tryEval (builtins.seq (w.compileFull providesFixture).aspects.foo null)).success;
  fwdTrips =
    w: !(builtins.tryEval (builtins.seq (w.compileFull fwdFixture).classes.myclass null)).success;

  # C5(b) STRUCTURAL severance — the legacy modules are IMPORTED at exactly ONE site (default.nix, the
  # assembly); every hand-off past it is by value. Scan the compat source: only default.nix contains an
  # `import ./legacy` / `import ../legacy`. (The core files mention "legacy" only in comments / error
  # strings — never as an import — so the scan targets the import expression, not the word.)
  compatDir = "${denHoagSrc}/lib/compat";
  isNix = n: lib.hasSuffix ".nix" n;
  topNix = builtins.filter isNix (builtins.attrNames (builtins.readDir compatDir));
  legacyNix = map (n: "legacy/${n}") (
    builtins.filter isNix (builtins.attrNames (builtins.readDir "${compatDir}/legacy"))
  );
  importsLegacy =
    rel:
    let
      t = builtins.readFile "${compatDir}/${rel}";
    in
    lib.hasInfix "import ./legacy" t || lib.hasInfix "import ../legacy" t;
  legacyImportSites = builtins.filter importsLegacy (topNix ++ legacyNix);
in
{
  flake.tests.compat-legacy-severed = {
    # ── the tag (severability handle) ────────────────────────────────────────────────────────────────
    test-forwards-tag = {
      expr = fwd._denCompat.legacy;
      expected = "forwards";
    };

    # ── (A) TIER-1: static forward → a plain deliver descriptor ────────────────────────────────────────
    test-tier1-is-not-complex = {
      expr = builtins.any fwd.isComplex (builtins.attrValues tier1Specs);
      expected = false;
    };
    # each tier-1 forward → a `deliver` descriptor: collected source (sourceClass = fromClass, no module),
    # target = intoClass, merge at the root (path=[]) — identical to v1's tier-1 route classification.
    test-tier1-homeLinux-deliver = {
      expr = {
        inherit (tier1Out.homeLinux)
          __delivery
          sourceClass
          moduleSource
          target
          path
          mode
          ;
      };
      expected = {
        __delivery = true;
        sourceClass = "homeLinux";
        moduleSource = null;
        target = "home-manager";
        path = [ ];
        mode = "merge";
      };
    };
    test-tier1-homeDarwin-source = {
      expr = tier1Out.homeDarwin.sourceClass;
      expected = "homeDarwin";
    };
    test-tier1-homeAarch64-target = {
      expr = tier1Out.homeAarch64.target;
      expected = "home-manager";
    };
    # tier-1 never emits a synthesize record (it takes the plain deliver path).
    test-tier1-no-synthesize = {
      expr = tier1Out.homeLinux ? synthesize;
      expected = false;
    };

    # ── (B) COMPLEX: adapter-bearing forward → an inert synthesize record with the identity triple ─────
    test-hm-is-complex = {
      expr = fwd.isComplex hmSpec;
      expected = true;
    };
    test-devshell-is-complex = {
      expr = fwd.isComplex devshellSpec;
      expected = true;
    };
    # the synthesize source record's identity triple (forwardId, fromClass, intoClass) — the frozen schema.
    test-hm-synthesize-triple = {
      expr = hmRecord.synthesize.spec;
      expected = {
        forwardId = "user/nixos/users/users/alice";
        fromClass = "user";
        intoClass = "nixos";
      };
    };
    test-devshell-synthesize-triple = {
      expr = devshellRecord.synthesize.spec;
      expected = {
        forwardId = "devshell/flake-parts/devshells/default";
        fromClass = "devshell";
        intoClass = "flake-parts";
      };
    };
    # forwardId falls back to the scope-free adapterKey FORMULA when no adapterKey is on the spec
    # (fromClass/intoClass/staticIntoPath joined) — never v1's scope-bearing arm (Law C2).
    test-forwardId-formula-fallback = {
      expr = fwd.forwardId {
        fromClass = "a";
        intoClass = "b";
        intoPath = [
          "p"
          "q"
        ];
        adaptArgs = _: { };
      };
      expected = "a/b/p/q";
    };
    # the source record is the synthesize arm (not collected/value) — a real gen-edge source.
    test-hm-source-arm = {
      expr = builtins.attrNames hmRecord;
      expected = [ "synthesize" ];
    };

    # ── (C) the module supplies interpret.synthesize (den-hoag defines none — item 7) ──────────────────
    test-interpret-synthesize-is-fn = {
      expr = builtins.isFunction fwd.interpret.synthesize;
      expected = true;
    };

    # ── (D) the interpreter RUNS through the materialize fold ──────────────────────────────────────────
    # the fold produces content for the target root (the composer ran, item 7).
    test-fold-produces-content = {
      expr = builtins.length folded."host:h".nixos;
      expected = 1;
    };
    # the composed content is a FUNCTION module (the adaptArgs arm threads the cell's args before the
    # source sees them — v1 route.nix adaptModule) — proving the adapter composition, not a bare passthrough.
    test-fold-content-is-adapter-module = {
      expr = builtins.isFunction foldedContent;
      expected = true;
    };
    # the composed module carries the source module (its content survived the composition).
    test-fold-content-imports-source = {
      expr = (foldedContent { config = { }; }).imports or [ ] != [ ];
      expected = true;
    };

    # ── (E) inert: trace renders identity, never forces the carried module (sourceVia unresolved) ──────
    test-inert-trace-identity = {
      expr = inertTraced.source.spec.forwardId;
      expected = "user/nixos/users/users/alice";
    };
    test-inert-trace-arm = {
      expr = inertTraced.source.arm;
      expected = "synthesize";
    };
    test-inert-sourceVia-annotation = {
      expr = inertTraced.annotations.sourceVia;
      expected = "unresolved";
    };

    # ── (F) the Law-C5 sentinel ────────────────────────────────────────────────────────────────────────
    test-sentinel-fires-on-forwardTo = {
      expr = forwardToCompilesClean;
      expected = false;
    };
    test-clean-class-compiles = {
      expr = cleanClassOk;
      expected = true;
    };

    # ── (G) desugar strips forwardTo (present-module path) ─────────────────────────────────────────────
    test-desugar-strips-forwardTo = {
      expr = desugared.classes.c1 ? forwardTo;
      expected = false;
    };
    # …while leaving the rest of the class untouched (surgical strip, not a class rebuild).
    test-desugar-keeps-other-class-keys = {
      expr = (desugared.classes.c1 ? wrap) && desugared.classes.c2.share.core;
      expected = true;
    };

    # ══ (H) C5(a) DECLARATION-SET byte-identity — flakeModuleCore alone + each single-legacy combo == full,
    #    on every NON-LEGACY fixture (the legacy desugars are or-identity ⇒ the compiled declarations match).
    test-decl-severable-edgeRoute = {
      expr = declSeverable nonLegacy.edgeRoute;
      expected = true;
    };
    test-decl-severable-policyInclude = {
      expr = declSeverable nonLegacy.policyInclude;
      expected = true;
    };
    test-decl-severable-quirkChannel = {
      expr = declSeverable nonLegacy.quirkChannel;
      expected = true;
    };

    # ══ (I) C5(a) TRACE byte-identity — the edge trace is identical with EITHER legacy module removed (and
    #    with BOTH removed, `core`) vs the full flakeModule. Non-vacuous (the route emits real edges).
    #    CONTENT (drv-hash) byte-identity defers to Task 8's parity-content (the file-header TODO).
    test-trace-nonvacuous = {
      expr = builtins.length traceFull >= 1;
      expected = true;
    };
    test-trace-severable-core = {
      expr = traceCore == traceFull;
      expected = true;
    };
    test-trace-severable-provOnly = {
      expr = traceProv == traceFull;
      expected = true;
    };
    test-trace-severable-fwdOnly = {
      expr = traceFwd == traceFull;
      expected = true;
    };

    # ══ (J) C5(b) SENTINELS — a severed surface's use is a named definition-time abort ─────────────────
    # provides severed (core = both gone; fwdOnly = provides gone) ⇒ the provides sentinel fires.
    test-provides-severed-core-aborts = {
      expr = provTrips core;
      expected = true;
    };
    test-provides-severed-fwdOnly-aborts = {
      expr = provTrips fwdOnly;
      expected = true;
    };
    # forwards severed (core; provOnly = forwards gone) ⇒ the forwards sentinel fires.
    test-forwards-severed-core-aborts = {
      expr = fwdTrips core;
      expected = true;
    };
    test-forwards-severed-provOnly-aborts = {
      expr = fwdTrips provOnly;
      expected = true;
    };
    # the COMPLEMENT (the sentinel is surgical): a PRESENT legacy module compiles its surface CLEAN.
    test-provides-present-provOnly-ok = {
      expr = !(provTrips provOnly);
      expected = true;
    };
    test-provides-present-full-ok = {
      expr = !(provTrips full);
      expected = true;
    };
    test-forwards-present-fwdOnly-ok = {
      expr = !(fwdTrips fwdOnly);
      expected = true;
    };
    test-forwards-present-full-ok = {
      expr = !(fwdTrips full);
      expected = true;
    };

    # ══ (K) C5(b) STRUCTURAL severance — the legacy modules are imported at EXACTLY one site (default.nix,
    #    the assembly). No core/other path reads them; every hand-off past the assembly is by value.
    test-legacy-import-single-site = {
      expr = legacyImportSites;
      expected = [ "default.nix" ];
    };

    # ══ (L) AMBIENT (defaults) severability (Task 8 M1) — the v1-ambient batteries add os-to-host /
    #    user-to-host ONLY when legacy/defaults.nix is present; severing it (flakeModuleCore alone) drops
    #    them. This is the ambient's OWN severability witness (the H/I comparisons hold it constant).
    test-defaults-ambient-present = {
      expr = {
        os = (ambientProbe ambientWiring) ? os-to-host;
        user = (ambientProbe ambientWiring) ? user-to-host;
      };
      expected = {
        os = true;
        user = true;
      };
    };
    test-defaults-ambient-severed = {
      expr = {
        os = (ambientProbe bare) ? os-to-host;
        user = (ambientProbe bare) ? user-to-host;
      };
      expected = {
        os = false;
        user = false;
      };
    };
  };
}
