# compat-feature-severed — the `den.features` REMOVABILITY GATE, generalised from compat-legacy-severed
# over the `mkWiringWith` front door. It is the load-bearing witness of per-system decoupling: for each
# feature, flip its flag OFF (`mkWiringWith { <feature> = false; }`) → (a) a fixture NOT using the feature
# stays BYTE-BASELINE (declaration set + edge trace `==` the all-on wiring), and (b) the feature's OWN use
# PARKS — a named Law-C5 sentinel abort, or a documented no-op (the emitted surface simply absent) — never
# a silent mis-fire. The complement (feature ON ⇒ the surface fires) keeps every park probe non-vacuous.
#
# This rung covers the LEGACY features (the class-(a) legacy-module subset compat-legacy-severed already
# proves severable): `provides` · `forwards` (Law-C5 sentinel parks) · `selfProvide` (documented no-op:
# the self-named include absent) · `ambientBatteries` (no byte-baseline — the ambient IS the baseline, so
# its witness is the present/severed route pair, not a byte-diff). The raw-seam Tier-0 features and the
# sig-entangled Tier-1 arms join as their own rungs wire their flags into `mkWiringWith`.
#
# All-on ≡ today: `full = denCompat` is `mkWiringWith { }` (every default), byte-identical to `mkWiring
# legacy`; each `off*` wiring drops exactly one legacy module via the feature record. The AMBIENT
# (defaults + self-provide) is held constant across a compared pair for the byte-baseline features — a
# feature-surface leak still moves the projection, but the ambient delta is scoped out (the same discipline
# as compat-legacy-severed's H/I comparisons).
{
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
  };
}
