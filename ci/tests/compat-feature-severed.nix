# compat-feature-severed — the `den.features` REMOVABILITY GATE, generalised from compat-legacy-severed
# over the `mkWiringWith` front door. It is the load-bearing witness of per-system decoupling: for each
# feature, flip its flag OFF (`mkWiringWith { <feature> = false; }`) → (a) a fixture NOT using the feature
# stays BYTE-BASELINE (declaration set + edge trace `==` the all-on wiring), and (b) the feature's OWN use
# PARKS — a named Law-C5 sentinel abort, or a documented no-op (the emitted surface simply absent) — never
# a silent mis-fire. The complement (feature ON ⇒ the surface fires) keeps every park probe non-vacuous.
#
# Coverage:
#   - LEGACY features (class-(a) legacy-module subset): `provides` · `forwards` (Law-C5 sentinel parks) ·
#     `selfProvide` (documented no-op: the self-named include absent) · `ambientBatteries` (no byte-baseline
#     — the ambient IS the baseline, so its witness is the present/severed route pair, not a byte-diff).
#   - RAW-SEAM Tier-0 features (class (b), rung 2a): `hasAspect` (den.enrichBindings + den.enrichContext,
#     ONE flag) · `gather` (den.channelGather). OMIT-when-off → the kernel identity default stands. Their
#     decl/trace baselines are GREEN-BY-CONSTRUCTION (materialization-only seams — declProj/unionTrace never
#     read the flag); the load-bearing severance teeth are the S1 BEHAVIORAL off-parks (drive a fixture that
#     READS the seam through `off*.mkDen` — ON populates, OFF parks: native missing-attr / empty gather).
#   - PER-BATTERY features (class (b), rung 2b): `battery.<name>` for all 12 gateable batteries — off drops
#     the provision so a `den.batteries.<name>` reference native-misses; a data-driven fold witnesses the
#     severed-absent / on-present / sibling-decoupling triple per battery.
#
# All-on ≡ today: `full = denCompat` is `mkWiringWith { }` (every default), byte-identical to `mkWiring
# legacy`; each `off*` wiring drops exactly one feature via the record. The AMBIENT (defaults + self-provide)
# is held constant across a compared pair for the byte-baseline features — a feature-surface leak still moves
# the projection, but the ambient delta is scoped out (compat-legacy-severed's H/I discipline).
{
  lib,
  denHoag,
  denCompat,
  ...
}:
let
  edge = denHoag.internal.edge;

  # ── the wirings: all-on baseline + one-feature-off per legacy feature (the `mkWiringWith` front door) ──
  full = denCompat; # mkWiringWith { } — every feature on, ≡ today's mkWiring legacy
  offProvides = denCompat.mkWiringWith { provides = false; };
  offForwards = denCompat.mkWiringWith { forwards = false; };
  offSelfProvide = denCompat.mkWiringWith { selfProvide = false; };
  offAmbient = denCompat.mkWiringWith { ambientBatteries = false; };
  # rung 2a raw-seam wirings (class (b)).
  offHasAspect = denCompat.mkWiringWith { hasAspect = false; };
  offGather = denCompat.mkWiringWith { gather = false; };

  # ── byte-baseline oracles (reused verbatim from compat-legacy-severed) ────────────────────────────────
  # declaration-set projection — attrNames + id_hashes only (no function is forced, so a parametric body
  # never enters the comparison).
  declProj = c: {
    kinds = builtins.attrNames c.entities.schema;
    regIds = builtins.mapAttrs (_: r: builtins.mapAttrs (_: e: e.id_hash) r) c.entities.registries;
    members = builtins.length c.entities.membership;
    aspectKeys = builtins.mapAttrs (n: _: builtins.attrNames c.aspects.${n}) c.aspects;
    policyNames = builtins.attrNames c.policies;
    classKeys = builtins.mapAttrs (n: _: builtins.attrNames c.classes.${n}) c.classes;
    channelKeys = builtins.mapAttrs (n: _: builtins.attrNames c.channels.${n}) c.channels;
  };
  # edge-trace projection — mkDen through a wiring, union the per-root traces (the frozen T|P|S|M sort-key
  # strings). (CONTENT / drv-hash byte-identity defers to the parity-content harness.)
  v1mod = fx: { config.den = fx; };
  unionTrace =
    result:
    let
      den = result.den;
    in
    edge.trace (builtins.concatMap (r: den.graph.edges r) (builtins.attrNames den.scopeRoots));

  # (a) DECOUPLING helpers — a fixture NOT using the off feature compiles/traces identically to all-on.
  declEq = offW: fx: declProj (offW.compileFull fx) == declProj (full.compileFull fx);
  traceEq =
    offW: fx: unionTrace (offW.mkDen [ (v1mod fx) ]) == unionTrace (full.mkDen [ (v1mod fx) ]);

  # NON-FEATURE fixtures (no provides / no forwardTo / no self-named overlap): the byte-baseline probes.
  # `edgeRoute` emits real trace edges (the non-vacuous trace half); the other two exercise the include +
  # channel declaration surfaces.
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
  nonFeatureFixtures = [
    edgeRoute
    policyInclude
    quirkChannel
  ];
  declSeverableOn = offW: builtins.all (fx: declEq offW fx) nonFeatureFixtures;

  # (b) PARK probes — a severed feature's own use aborts named (provides/forwards sentinels) or no-ops
  # (self-provide). `provTrips`/`fwdTrips` are `true` when the lazy `seq` sentinel inside translate{Aspect,
  # Class} fires.
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

  # self-provide — a DOCUMENTED NO-OP, not a sentinel: an entity whose instance name also names an aspect
  # gets a node-local self-include (legacy/self-provide.nix). Flag-off ⇒ `selfIncludeFn = _: [ ]` ⇒ the
  # self-include is simply ABSENT (byte-identical no-op, Law C5 — a self-named aspect leaves no residual
  # KEY to sentinel). Probe the count of compiled `include` records: present on, absent off.
  selfProvideFixture = {
    hosts.x86_64-linux.axon.class = "nixos";
    aspects.axon.nixos.services.foo.enable = true; # aspect `axon` overlaps host `axon`
  };
  selfIncludeCount = w: builtins.length ((w.compileFull selfProvideFixture).include or [ ]);

  # ambientBatteries — the v1-ambient os/user batteries (defaults) add os-to-host / user-to-host to EVERY
  # fleet, so there is NO byte-baseline (the ambient IS the baseline). Witness the present/severed route
  # pair instead (the same probe compat-legacy-severed uses for the defaults surface).
  ambientRoutes = w: {
    os = ((w.compileFull { }).policies or { }) ? __aspectInclude__os-to-host;
    user = ((w.compileFull { }).policies or { }) ? __aspectInclude__user-to-host;
  };

  # ── rung 2a: raw-seam probes (class (b)) ──────────────────────────────────────────────────────────────
  # STRUCTURAL seam-presence: the compat override is present at `config.den.<key>` on, ABSENT off (the
  # kernel identity default then stands). Regression-sensitive for the KEY (a seam set unconditionally would
  # stay present off), but does NOT prove present→works / absent→parks — that is the S1 behavioral job.
  seamSet = w: key: (w.mkFleetModule (w.compileFull { })).config.den ? ${key};

  # S1 BEHAVIORAL off-parks — the real severance teeth. The decl/trace baselines are GREEN-BY-CONSTRUCTION:
  # `declProj`/`unionTrace` project compileFull declarations / the T|P|S|M edge graph, NEITHER of which reads
  # `features.hasAspect`/`gather` (the seams gate `config.den` at MATERIALIZATION, in `mkFleetModuleWith`),
  # so those rows are tautologically true regardless of the flag — they witness materialization-only, not
  # decoupling. The rows below drive a fixture that READS the seam through `off*.mkDen` to the TERMINAL
  # binding: flag-ON the value populates, flag-OFF it parks — hasAspect the native missing-attr (the stamp
  # is absent, so a node body's `host.hasAspect` read is an uncatchable substrate miss, the nix-config
  # networking.nix:341 frontier); gather the empty gather (the kernel `_:_:_:{}` returns nothing).
  hasAspectFixture = {
    hosts.x86_64-linux.axon = { };
    aspects.axon.nixos.networking.hostName = "axon"; # self-named aspect (R5) → the host resolves it
    schema.host.includes = [ "axon" ];
  };
  hostBinding =
    w: (w.mkDen [ (v1mod hasAspectFixture) ]).den.output.systems.nixos."host:axon".bindings.host;

  gatherFixture = {
    hosts.x86_64-linux.igloo.users.tux = { };
    hosts.x86_64-linux.igloo.users.pol = { };
    schema.user = {
      parent = "host";
      includes = [
        "emit-ru"
        "expose-ru"
      ];
    };
    aspects.hostc.nixos.networking.hostName = "igloo";
    schema.host.includes = [ "hostc" ];
    quirks.resolved-users = { };
    aspects.emit-ru.resolved-users = { user, ... }: [ { name = user.name or "?"; } ];
    policies.expose-ru = { user, ... }: [
      (denCompat.pipe.from "resolved-users" [ denCompat.pipe.expose ])
    ];
  };
  gatheredNames =
    w:
    builtins.sort (a: b: a < b) (
      map (u: u.name)
        (w.mkDen [ (v1mod gatherFixture) ]).den.output.systems.nixos."host:igloo".bindings.resolved-users
    );

  # ── rung 2b: per-battery provision probes (class (b)) ─────────────────────────────────────────────────
  # `batteriesModule` is a curried flake-parts module; apply a stub arg set (only `lib` + the curried `feat`
  # feed the `filterAttrs` provision — the battery VALUES stay lazy, so the `withSystem`/`inputs`/`self`/`den`
  # stubs are never forced). The 12 gateable names come from the wiring's own `defaultFeatures.battery`.
  batteryStub = {
    inherit lib;
    config = { };
    withSystem = _: { };
    inputs = { };
    self = { };
    den = { };
  };
  provisioned = w: builtins.attrNames (w.batteriesModule batteryStub).config.den.batteries;
  batteryNames = builtins.attrNames denCompat.defaultFeatures.battery;
  fullProvisioned = provisioned full;
  offBattery = name: denCompat.mkWiringWith { battery.${name} = false; };
  # Per battery: severed drops it (park), on keeps it (non-vacuous), and the OTHER 11 survive (no sibling
  # collateral — the filter + nested-merge totality). Data-driven fold, not 12 hand-copies.
  batteryRows = builtins.foldl' (
    acc: name:
    acc
    // {
      "test-battery-${name}-severed-absent" = {
        expr = builtins.elem name (provisioned (offBattery name));
        expected = false;
      };
      "test-battery-${name}-on-present" = {
        expr = builtins.elem name fullProvisioned;
        expected = true;
      };
      "test-battery-${name}-decoupling" = {
        expr = provisioned (offBattery name) == builtins.filter (n: n != name) fullProvisioned;
        expected = true;
      };
    }
  ) { } batteryNames;
in
{
  flake.tests.compat-feature-severed = {
    # ══ FEATURE: provides ─ Law-C5 sentinel ─────────────────────────────────────────────────────────────
    # (a) decoupling — a non-provides fixture is byte-baseline (decl + trace) with provides severed.
    test-provides-decl-baseline = {
      expr = declSeverableOn offProvides;
      expected = true;
    };
    test-provides-trace-baseline = {
      expr = traceEq offProvides edgeRoute;
      expected = true;
    };
    # (b) park — a provides fixture through the severed wiring trips the named sentinel …
    test-provides-severed-parks = {
      expr = provTrips offProvides;
      expected = true;
    };
    # … and the ON wiring compiles it clean (the park probe is non-vacuous).
    test-provides-on-fires = {
      expr = provTrips full;
      expected = false;
    };

    # ══ FEATURE: forwards ─ Law-C5 sentinel ─────────────────────────────────────────────────────────────
    test-forwards-decl-baseline = {
      expr = declSeverableOn offForwards;
      expected = true;
    };
    test-forwards-trace-baseline = {
      expr = traceEq offForwards edgeRoute;
      expected = true;
    };
    test-forwards-severed-parks = {
      expr = fwdTrips offForwards;
      expected = true;
    };
    test-forwards-on-fires = {
      expr = fwdTrips full;
      expected = false;
    };

    # ══ FEATURE: selfProvide ─ documented no-op (self-include absent when severed) ───────────────────────
    test-selfProvide-decl-baseline = {
      expr = declSeverableOn offSelfProvide;
      expected = true;
    };
    test-selfProvide-trace-baseline = {
      expr = traceEq offSelfProvide edgeRoute;
      expected = true;
    };
    # park — the self-named include is ABSENT when severed (no throw; the documented no-op) …
    test-selfProvide-severed-no-include = {
      expr = selfIncludeCount offSelfProvide;
      expected = 0;
    };
    # … and PRESENT when on (non-vacuous: the self-named aspect resolves at its own entity).
    test-selfProvide-on-includes = {
      expr = selfIncludeCount full;
      expected = 1;
    };

    # ══ FEATURE: ambientBatteries ─ present/severed (no byte-baseline: the ambient IS the baseline) ──────
    # severed ⇒ the v1-ambient os-to-host / user-to-host routes are absent from EVERY fleet …
    test-ambientBatteries-severed-routes-absent = {
      expr = ambientRoutes offAmbient;
      expected = {
        os = false;
        user = false;
      };
    };
    # … and present when on (non-vacuous).
    test-ambientBatteries-on-routes-present = {
      expr = ambientRoutes full;
      expected = {
        os = true;
        user = true;
      };
    };

    # ══ SEAM: hasAspect ─ den.enrichBindings + den.enrichContext (ONE flag, rung 2a) ─────────────────────
    # (a) decl/trace baselines — GREEN-BY-CONSTRUCTION (materialization-only seam; kept for shape-uniformity
    # with the legacy rows, NOT severance teeth — see the S1 note in the `let`).
    test-hasAspect-decl-baseline = {
      expr = declSeverableOn offHasAspect;
      expected = true;
    };
    test-hasAspect-trace-baseline = {
      expr = traceEq offHasAspect edgeRoute;
      expected = true;
    };
    # structural seam present/absent (regression-sensitive for the key: OMIT-when-off → kernel identity).
    test-hasAspect-severed-seam-absent = {
      expr = seamSet offHasAspect "enrichBindings";
      expected = false;
    };
    test-hasAspect-on-seam-present = {
      expr = seamSet full "enrichBindings";
      expected = true;
    };
    # (b) S1 BEHAVIORAL teeth — ON the terminal binding carries a resolving `hasAspect` closure (answers the
    # self-named aspect true); OFF the stamp is ABSENT (a node body's `host.hasAspect` read native-misses).
    test-hasAspect-behavioral-on-resolves = {
      expr = (hostBinding full).hasAspect { key = "axon"; };
      expected = true;
    };
    test-hasAspect-behavioral-off-unstamped = {
      expr = (hostBinding offHasAspect) ? hasAspect;
      expected = false;
    };

    # ══ SEAM: gather ─ den.channelGather (rung 2a) ──────────────────────────────────────────────────────
    test-gather-decl-baseline = {
      expr = declSeverableOn offGather;
      expected = true;
    };
    test-gather-trace-baseline = {
      expr = traceEq offGather edgeRoute;
      expected = true;
    };
    test-gather-severed-seam-absent = {
      expr = seamSet offGather "channelGather";
      expected = false;
    };
    test-gather-on-seam-present = {
      expr = seamSet full "channelGather";
      expected = true;
    };
    # (b) S1 BEHAVIORAL teeth — ON the host gathers its user cells' exposed resolved-users; OFF the kernel
    # `_:_:_:{}` default returns nothing (empty gather).
    test-gather-behavioral-on-populates = {
      expr = gatheredNames full;
      expected = [
        "pol"
        "tux"
      ];
    };
    test-gather-behavioral-off-empty = {
      expr = gatheredNames offGather;
      expected = [ ];
    };
  }
  # ══ FEATURE: battery.<name> ─ per-battery provision drop (rung 2b), data-driven over all 12 ─────────────
  // batteryRows;
}
