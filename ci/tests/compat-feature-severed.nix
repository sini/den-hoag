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
#   - COMPAT-DESUGAR-ARM features (class (c), rung 3, both gate inside compile.nix): `lateDispatch` (a
#     GENUINE clean byte-baseline — decl/trace baselines + S1 BEHAVIORAL radiate-on/absent-off teeth) ·
#     `aspectIncludeArm` (AMBIENT-COUPLED, NO byte-baseline — the ambient `defaults` battery rides the same
#     arm, so the witness is on-fires + a coupling park on the ambient os-to-host record + ambient-coupled-
#     clean; register: aspectIncludeArm ⊇ ambientBatteries).
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

  # ── FEATURE: flakeOutputClasses (den v2 OPT-IN, default OFF) ──────────────────────────────────────────
  # INVERTED default (opt-in, not removability): `full` (mkWiringWith { }) already has the feature OFF, so the
  # register side drives an explicit-ON wiring. The gate provisions the five flake-output classes in the
  # builtinsModule (the fleetContext precedent), so the STRUCTURAL probe reads
  # `w.builtinsModule.config.den.classes` DIRECTLY — valid + mutation-provable (re-registering `apps` is what
  # turns a `<ns>.apps.<leaf>` namespace opaque). The LOAD-BEARING behavioral off-navigates / on-breaks proof
  # lives in the den-behavioral witness (through the BRIDGE, which wires builtinsModule); `compileFull`/`evalV1`
  # wire only `flakeModuleCore`, so the flag is a NO-OP there — the mkDen-path rows below are FLAG-INVARIANT
  # sanity (a flake-output-NAME namespace compiles + navigates when the name is not a class), NOT the gate proof.
  onFlakeOutput = denCompat.mkWiringWith { flakeOutputClasses = true; };
  flakeOutputClassPresent = w: (w.builtinsModule.config.den.classes or { }) ? apps;
  # a fixture using a flake-output NAME (`apps`) as an aspect NAMESPACE directory (`parent.apps.leaf`); the
  # leaf's content keys are registered (a quirk `q` + the `nixos` class), so it is unmistakably an aspect.
  nsSanityFixture = {
    quirks.q = { };
    aspects.parent.apps.leaf = {
      q = [ "x" ];
      nixos.environment.variables.FROM_LEAF = "yes";
    };
  };
  nsSanityCompiles =
    w: (builtins.tryEval (builtins.deepSeq (w.compileFull nsSanityFixture).aspects null)).success;
  nsSanityNavigates = w: ((w.evalV1 [ (v1mod nsSanityFixture) ]).aspects.parent.apps or { }) ? leaf;

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
  # CONTENT-compilation removability — the present/severed route pair above only route-PRESENCE-probes an
  # EMPTY fleet (`compileFull { }`), which never types a content aspect tree, so it never forced the ambient-
  # off `legacy.defaults` read at the compile class-name base (flake-module `compileClassNamesBase`). A
  # content-bearing fixture typed under ambientBatteries-off must compile THROUGH cleanly — the base tolerates
  # the severed `defaults` via `registeredClasses or [ ]` (the sibling-guard pattern). deepSeq the compiled
  # `.aspects` (forces that class-name base) through tryEval: clean iff no escape. Mutation-provable: without
  # the guard this ambient-off read hard-errors `attribute 'defaults' missing` and ESCAPES tryEval.
  compilesCleanContent =
    w: (builtins.tryEval (builtins.deepSeq (w.compileFull edgeRoute).aspects null)).success;

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

  # ── rung 3: compat-desugar-arm gates (class (c), Tier-1 — both gate inside compile.nix, no kernel edit) ─
  offLateDispatch = denCompat.mkWiringWith { lateDispatch = false; };
  # `aspectIncludeArm` is AMBIENT-COUPLED (NOT a clean byte-baseline): the always-on `defaults` battery
  # coerces its os-to-host / user-to-host routes into the SAME `{ __isPolicy }`-in-aspect-includes arm this
  # flag gates. Arm-off ALONE (ambient still on) makes those ambient records undivertable → the arm's own
  # `unregisteredPolicyInclude` sentinel fires ON the ambient defaults record — the coupling, named. Only
  # dropping `ambientBatteries` too resolves it. So its witness is a present/severed pair PLUS an
  # ambient-coupled-clean row, NOT a decl byte-baseline (aspectIncludeArm ⊇ ambientBatteries consumers).
  offAspectIncludeArm = denCompat.mkWiringWith { aspectIncludeArm = false; };
  offAspectIncludeArmAmbient = denCompat.mkWiringWith {
    aspectIncludeArm = false;
    ambientBatteries = false;
  };

  # every `tag` string reachable in a wrapped deferredModule (the gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];

  # lateDispatch — a CONCRETE descendant-formal radiation fixture: a `{ host, user }` bare-fn include on a
  # HOST aspect carries homeManager content KEYED BY the descendant `user` coord. ON it radiates to the
  # host's user CELL (content lands at `user:tux@host:igloo`); OFF `radiatedBareFn = _: false` keeps it
  # node-local at the host, where the `user` coord is absent → the shared `wrapGatedFn` coord-gate takes its
  # false branch → content ABSENT at the user cell (the documented no-op). Non-vacuous: on ≠ off.
  lateDispatchFixture = {
    hosts.x86_64-linux.igloo = {
      class = "nixos";
      users.tux = { };
    };
    schema.user.parent = "host";
    aspects.carrier.includes = [
      ({ host, user, ... }: { homeManager.tag = "radiated-${user.name}"; })
    ];
    schema.host.includes = [ "carrier" ];
  };
  ldRadiatedTags =
    w:
    builtins.concatMap tags (
      (w.mkDen [ (v1mod lateDispatchFixture) ])
      .den.output.systems.home-manager."user:tux@host:igloo".modules or [ ]
    );

  # aspectIncludeArm — a `{ __isPolicy }` record DIRECTLY in a regular aspect's `.includes` (the corpus
  # host-aspects shape, `den.aspects.sini.includes = [ den.batteries.host-aspects ]`). ON it compiles to a
  # `__aspectInclude__<name>` rule; the coupling park is witnessed off the ambient defaults record instead.
  aspectIncludeFixture = {
    hosts.x86_64-linux.igloo.class = "nixos";
    aspects.injected.nixos.tag = "injected-by-policy";
    aspects.carrier = {
      nixos.tag = "carrier-own";
      includes = [
        {
          __isPolicy = true;
          name = "host-aspects-project";
          fn = { host, ... }: [
            {
              __policyEffect = "include";
              value = {
                name = "injected";
              };
            }
          ];
        }
      ];
    };
    schema.host.includes = [ "carrier" ];
  };
  armFires = w: (w.compileFull aspectIncludeFixture).policies ? __aspectInclude__host-aspects-project;
  # the arm's OWN sentinel (`unregisteredPolicyInclude`) fires on the AMBIENT defaults battery's os-to-host
  # record when the arm is off but ambient stays on — deepSeq the compiled `defaults` aspect to force it.
  armSeveredParks =
    w: !(builtins.tryEval (builtins.deepSeq (w.compileFull { }).aspects.defaults true)).success;
  # clean iff BOTH arm and ambient are off — a bare fleet compiles without the coupling abort, proving the
  # coupling is EXACTLY ambientBatteries (no other ambient consumer of the arm).
  compilesClean = w: (builtins.tryEval (builtins.deepSeq (w.compileFull { }) true)).success;

  # ── rung 5: Tier-2 coupling-review gates (register compat-feature-register.md) ─────────────────────────
  # Empirically-corrected tiering: probeSentinel + familyStamps are CLEAN byte-baseline
  # (the ambient routes read their coord fields GUARDED, `host.class or null`, and the family policies are
  # corpus-#49-gated, absent from the ambient route names); fleetContext is the genuine no-clean-baseline
  # member (the enrich provision rides every fleet at the flake-parts consumer eval).
  inherit (denHoag) declare;
  R = denHoag.policy.resolve;
  offProbeSentinel = denCompat.mkWiringWith { probeSentinel = false; };
  offFamilyStamps = denCompat.mkWiringWith { familyStamps = false; };
  offFleetContext = denCompat.mkWiringWith { fleetContext = false; };

  # trace-baseline severability over the non-feature fixtures — the mkDen-path NET (probeSentinelFields is
  # consumed ONLY at mkDen's value-less stratum probe, NEVER in compile.nix, so `declSeverableOn`/compileFull
  # is tautological for probeSentinel; `traceEq` is its tiering confirmation). The ambient routes read their
  # coord fields `host.class or null` GUARDED, so the sentinel on/off is byte-neutral on these fixtures.
  traceSeverableOn = offW: builtins.all (fx: traceEq offW fx) nonFeatureFixtures;

  # ── probeSentinel (class b): OMIT probeSentinelModule ⇒ den.probeSentinelFields kernel `{ }` ─────────────
  # (a) on-DETECTS / off-PARKS teeth via a coord-PRESENCE-gated enrich. At mkDen's value-less stratum probe
  # the sentinel entry is `{ id_hash; name } // probeSentinelFields`: ON it carries `class`, so `host ? class`
  # is TRUE at the probe → the enrich is DETECTED (a single-group structural rule, clean); OFF the field is
  # absent → `host ? class` FALSE → the policy reads value-conditional → the enrich rides an EXPANSION sub-rule
  # → `errors.expansionEnrich` NAMED throw (an enrich cannot ride expansion). The off-park is thus the ABSENCE
  # of the sentinel field surfaced as a CATCHABLE den throw — NOT a native missing-attr (which would escape
  # tryEval and crash the suite). Mutation-provable: re-provision the field off ⇒ `host ? class` true ⇒
  # detected ⇒ the off-park row reddens.
  probeEnrichFixture = {
    hosts.x86_64-linux.axon.class = "nixos";
    policies.probe-enrich =
      { host, ... }:
      if host ? class then
        [
          (declare.enrich {
            key = "probeMark";
            value = true;
          })
        ]
      else
        [ ];
  };
  probeEnrichParks =
    w:
    !(builtins.tryEval (
      builtins.deepSeq ((w.mkDen [ (v1mod probeEnrichFixture) ]).den.structural.eval.get "host:axon"
        "declarations"
      ) true
    )).success;
  # the CONTENT-CLEAN ON arm (the ambientBatteries lesson): a policy reading a bare coord field UNGUARDED at
  # the probe (`builtins.seq host.class …`, the `host-modules-capture` corpus shape) types THROUGH clean with
  # the sentinel ON (the field present lets the unguarded probe read succeed). OFF the SAME fixture native-
  # misses at the probe and escapes tryEval (the documented LOUD ceiling) — so it is driven ON only.
  probeUnguardedFixture = {
    hosts.x86_64-linux.axon.class = "nixos";
    aspects.seedaspect.nixos.networking.hostName = "axon";
    policies.probe-coord = { host, ... }: [
      (builtins.seq host.class {
        __policyEffect = "include";
        value = {
          name = "seedaspect";
        };
      })
    ];
  };
  probeUnguardedClean =
    w:
    (builtins.tryEval (builtins.deepSeq (unionTrace (w.mkDen [ (v1mod probeUnguardedFixture) ])) true))
    .success;

  # ── familyStamps (class b): mkCompile name-sets → `[ ]` + OMIT the resolve/exclude seam modules, ATOMIC ──
  # (b) the TWO gate sites, each with its own park. resolve half = the COMPILE-side stamp (the mkCompile bake):
  # a resolve policy wired via a kind-include whose source ref's v1 name ∈ resolveFamilyNames gets
  # `__resolveFamily` stamped ON its synthetic-keyed compiled record — ON the bake carries the corpus set ⇒
  # stamped; OFF the bake collapses to `[ ]` ⇒ unstamped (the pre-pass feed goes empty).
  kiResolveFixture = {
    schema = {
      zone.parent = null;
      rack.parent = "zone";
      blade.parent = "rack";
      rack.includes = [
        {
          __isPolicy = true;
          name = "env-to-hosts"; # ∈ resolve-family-names.nix
          fn =
            {
              token ? null,
              ...
            }: # value-conditional (empty probe → expansion), the corpus resolve idiom
            if token != null then [ (R.to "blade" { blade.name = "b1"; }) ] else [ ];
        }
      ];
    };
    policies = { };
  };
  resolveStampOf =
    w:
    ((w.compileFull kiResolveFixture).policies."__kindInclude__rack__policy__0").__resolveFamily
      or false;
  # exclude half = the SEAM-module omit (`den.excludeFamilyNames`): the corpus value-conditional excluder
  # (`drop-user-to-host-on-droid` ∈ exclude-family-names.nix) fires a `suppress` at the droid host — ON the
  # seam names it ⇒ the pre-pass feed consumes it ⇒ benign double-fire; OFF the seam is omitted ⇒ `[ ]` ⇒ its
  # main-run suppress is untagged ⇒ `errors.excludeFamilyUntagged` NAMED throw (catchable). ON/OFF collapse
  # ATOMICALLY (both the bake and the seam) — a lone-site collapse desyncs the two `den.*FamilyNames` writers.
  userToHostRef = {
    __isPolicy = true;
    name = "user-to-host";
    fn = _: [ ];
  };
  excludeFixture = {
    hosts.x86_64-linux.d1 = {
      class = "droid";
      users.tux = { };
    };
    classes.droid = { };
    schema.user.parent = "host";
    aspects.hostc.nixos.tag = "nixos-host";
    schema.host.includes = [ "hostc" ];
    aspects.uacct =
      { user, ... }:
      {
        user = [ "u-${user.name}" ];
      };
    schema.user.includes = [ "uacct" ];
    policies.drop-user-to-host-on-droid =
      { host, ... }:
      if (host.class or null) == "droid" then [ (denCompat.exclude userToHostRef) ] else [ ];
  };
  excludeFamilyParks =
    w:
    !(builtins.tryEval (
      builtins.deepSeq ((w.mkDen [ { den = excludeFixture; } ]).den.structural.eval.get "host:d1"
        "declarations"
      ) true
    )).success;

  # ── fleetContext (class b, the genuine no-clean-baseline member): OMIT fleetContextEnrichModule from the
  # wiring's builtinsModule (the batteriesModule precedent). The enrich provision rides EVERY fleet at the
  # flake-parts consumer eval (never the compat mkDen path), so the witness is at the builtinsModule grain:
  # the provisioned enrich present/severed + a PRESENCE-IS-NOT-REMOVABILITY behavioral binding proof (the
  # ambientBatteries lesson). Evaluate the (gated) provisioning submodule with a synthetic env registry and
  # extract the `fleet-context-enrich` policy (null when severed ⇒ the `imports` is empty).
  enrichPolicyOf =
    w:
    let
      imps = w.builtinsModule.imports or [ ];
    in
    if imps == [ ] then
      null
    else
      ((builtins.head imps) {
        config.den = {
          environments.prod = {
            domain = "prod.example";
          };
          secretsConfig = {
            age = "k1";
          };
        };
      }).config.den.policies.fleet-context-enrich or null;
  # apply the provisioned enrich at a host ctx and project the BOUND keys → values — the S1 behavioral proof
  # the provision is a WORKING binder (not merely present); OFF `enrichPolicyOf` is null ⇒ NOTHING binds the
  # `environment`/`secretsConfig`/`fleet` ctx keys, so the ~40 corpus `{ environment, … }` sites' bindings are
  # ABSENT (the CEILING — asserted as absence, `enrichBoundKeys off == null`, never a forced native-miss).
  enrichBoundKeys =
    w:
    let
      p = enrichPolicyOf w;
    in
    if p == null then
      null
    else
      builtins.listToAttrs (
        map
          (d: {
            name = d.key;
            value = d.value;
          })
          (p {
            host = {
              environment = "prod";
              name = "axon";
            };
          })
      );
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
    # … and a CONTENT-bearing fleet still compiles THROUGH clean with the ambient severed — the removability
    # proof the route-presence rows above miss (they only probe an empty fleet). Pre-guard the ambient-off
    # class-name base read hard-errored and escaped tryEval; post-guard it types the content clean.
    test-ambientBatteries-content-compiles-off = {
      expr = compilesCleanContent offAmbient;
      expected = true;
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

    # ══ ARM: lateDispatch ─ descendant-formal bare-fn radiation (rung 3, compile.nix) ────────────────────
    # (a) decl/trace baselines — a GENUINE clean byte-baseline (unlike aspectIncludeArm): no ambient path
    # carries a raw late-dispatch bare fn (every ambient emitter is a `{ __isPolicy }`/`{ __denCanTake }`
    # record), so a non-late-dispatch fixture is byte-identical with the arm off.
    test-lateDispatch-decl-baseline = {
      expr = declSeverableOn offLateDispatch;
      expected = true;
    };
    test-lateDispatch-trace-baseline = {
      expr = traceEq offLateDispatch edgeRoute;
      expected = true;
    };
    # (b) S1 BEHAVIORAL teeth — ON the `{ host, user }` include RADIATES its homeManager content to the
    # host's user cell; OFF it stays node-local (the `user` coord absent at the host → coord-gate false →
    # nothing at the user cell). Mutation-provable: re-couple the radiation → the off row goes red.
    test-lateDispatch-behavioral-on-radiates = {
      expr = ldRadiatedTags full;
      expected = [ "radiated-tux" ];
    };
    test-lateDispatch-behavioral-off-absent = {
      expr = ldRadiatedTags offLateDispatch;
      expected = [ ];
    };

    # ══ ARM: aspectIncludeArm ─ `{ __isPolicy }`-in-aspect-includes diversion (rung 3, compile.nix) ──────
    # AMBIENT-COUPLED: NO decl byte-baseline row (arm-off-alone aborts the ambient defaults record). The
    # witness is on-fires + the coupling park + the ambient-coupled-clean row that names the coupling.
    # on-fires — the host-aspects record compiles to its `__aspectInclude__` rule under the all-on wiring.
    test-aspectIncludeArm-on-fires = {
      expr = armFires full;
      expected = true;
    };
    # severed-parks — arm-off (ambient STILL ON): the ambient defaults battery's os-to-host `{ __isPolicy }`
    # record is undivertable → the arm's own `unregisteredPolicyInclude` NAMED sentinel fires. This IS the
    # coupling: turning off the arm without ambient aborts on ambient's own records.
    test-aspectIncludeArm-severed-parks = {
      expr = armSeveredParks offAspectIncludeArm;
      expected = true;
    };
    # ambient-coupled-clean — arm-off AND ambient-off: a bare fleet compiles clean, proving the coupling is
    # EXACTLY ambientBatteries (design §6.1 — the removability gate NAMES its coupling).
    test-aspectIncludeArm-ambient-coupled-clean = {
      expr = compilesClean offAspectIncludeArmAmbient;
      expected = true;
    };

    # ══ PROBE: probeSentinel ─ den.probeSentinelFields value-less-probe sentinel (rung 5, clean baseline) ──
    # (a) trace byte-baseline NET — the mkDen-path tiering confirmation (declSeverableOn is tautological here:
    # compile.nix never reads probeSentinelFields). Green because the ambient routes read `host.class or null`
    # GUARDED, so the sentinel on/off is byte-neutral on the non-feature fixtures.
    test-probeSentinel-trace-baseline = {
      expr = traceSeverableOn offProbeSentinel;
      expected = true;
    };
    # (b) on-DETECTS — ON the sentinel carries `class`, so a coord-presence-gated enrich is DETECTED at the
    # value-less probe (single-group, clean).
    test-probeSentinel-on-detects = {
      expr = probeEnrichParks full;
      expected = false;
    };
    # (b) off-PARKS — OFF the field is absent → `host ? class` false at the probe → the enrich rides an
    # expansion sub-rule → `expansionEnrich` NAMED throw (the ABSENCE surfaced as a catchable park).
    test-probeSentinel-off-parks = {
      expr = probeEnrichParks offProbeSentinel;
      expected = true;
    };
    # CONTENT-CLEAN ON arm — a policy reading a bare coord field UNGUARDED at the probe (`builtins.seq
    # host.class …`, the host-modules-capture corpus shape) types THROUGH clean with the sentinel ON. Mutation-
    # provable: strip the field from probeSentinelModule ⇒ this native-misses at the probe (the LOUD ceiling).
    test-probeSentinel-unguarded-on-clean = {
      expr = probeUnguardedClean full;
      expected = true;
    };

    # ══ STAMPS: familyStamps ─ resolve/exclude-family tag sets (rung 5, clean baseline, TWO gate sites) ─────
    # (a) decl + trace byte-baseline — the family policies are corpus-#49-gated, absent from the non-feature
    # fixtures, so both sites collapse byte-neutrally.
    test-familyStamps-decl-baseline = {
      expr = declSeverableOn offFamilyStamps;
      expected = true;
    };
    test-familyStamps-trace-baseline = {
      expr = traceSeverableOn offFamilyStamps;
      expected = true;
    };
    # (b) resolve half = the mkCompile bake site — ON a kind-include resolve policy whose ref name ∈ the set
    # gets `__resolveFamily` stamped; OFF the bake collapses to `[ ]` ⇒ unstamped (the pre-pass feed empties).
    test-familyStamps-resolve-stamp-on = {
      expr = resolveStampOf full;
      expected = true;
    };
    test-familyStamps-resolve-stamp-off = {
      expr = resolveStampOf offFamilyStamps;
      expected = false;
    };
    # (b) exclude half = the seam-module omit site — ON the corpus excluder's main-run `suppress` is benign
    # (the seam names it ⇒ the pre-pass feed consumed it); OFF the seam is `[ ]` ⇒ `excludeFamilyUntagged`
    # NAMED throw. The two sites collapse ATOMICALLY (a lone-site collapse desyncs the two writers).
    test-familyStamps-exclude-benign-on = {
      expr = excludeFamilyParks full;
      expected = false;
    };
    test-familyStamps-exclude-park-off = {
      expr = excludeFamilyParks offFamilyStamps;
      expected = true;
    };

    # ══ FEATURE: fleetContext ─ the fleet-context enrich provision (rung 5, genuine no-clean-baseline) ──────
    # present/severed — ON the wiring's builtinsModule provisions the `fleet-context-enrich` policy; OFF the
    # provision is dropped from `imports` (the enrich rides no fleet).
    test-fleetContext-provision-on = {
      expr = enrichPolicyOf full != null;
      expected = true;
    };
    test-fleetContext-provision-severed = {
      expr = enrichPolicyOf offFleetContext == null;
      expected = true;
    };
    # S1 BEHAVIORAL — the provisioned enrich is a WORKING binder (presence ≠ removability, the ambientBatteries
    # lesson): applied at a host ctx it binds `environment`/`secretsConfig`/`fleet` off the synthetic registry.
    test-fleetContext-behavioral-on-binds = {
      expr = enrichBoundKeys full;
      expected = {
        environment = {
          domain = "prod.example";
        };
        secretsConfig = {
          age = "k1";
        };
        fleet = {
          name = "fleet";
        };
      };
    };
    # ABSENCE — OFF nothing provisions the enrich ⇒ the `environment`/`secretsConfig`/`fleet` ctx bindings
    # are ABSENT (the CEILING the ~40 corpus `{ environment, … }` sites park on), asserted as absence, not a
    # forced native-miss.
    test-fleetContext-behavioral-off-absent = {
      expr = enrichBoundKeys offFleetContext == null;
      expected = true;
    };
    # CONTENT-CLEAN OFF arm — a NON-env fixture compiles THROUGH clean with fleetContext severed (the enrich
    # never rode the compat mkDen path, so a non-consumer fleet is untouched).
    test-fleetContext-content-clean-off = {
      expr =
        (builtins.tryEval (builtins.deepSeq (offFleetContext.compileFull edgeRoute).aspects null)).success;
      expected = true;
    };

    # ══ FEATURE: flakeOutputClasses ─ the five v1 flake-output classes, OPT-IN (default OFF, den v2) ────────
    # STRUCTURAL present/severed (reads builtinsModule directly — the mutation-provable carrier): the DEFAULT
    # (OFF) wiring omits `apps` from the provisioned classes; the explicit-ON wiring registers it. Re-registering
    # `apps` is EXACTLY what turns a `<ns>.apps.<leaf>` namespace opaque (the den-behavioral witness proves that
    # end-to-end through the bridge).
    test-flakeOutputClasses-default-off-absent = {
      expr = flakeOutputClassPresent full;
      expected = false;
    };
    test-flakeOutputClasses-on-present = {
      expr = flakeOutputClassPresent onFlakeOutput;
      expected = true;
    };
    # mkDen-path FLAG-INVARIANT sanity (NOT the gate proof — compileFull/evalV1 wire only flakeModuleCore, so
    # the five classes are absent ON or OFF here): a flake-output-NAME namespace compiles clean and its leaf
    # navigates on the mkDen path. The load-bearing off-navigates / on-breaks gate proof is the bridge witness.
    test-flakeOutputClasses-mkden-namespace-compiles = {
      expr = nsSanityCompiles full;
      expected = true;
    };
    test-flakeOutputClasses-mkden-namespace-navigates = {
      expr = nsSanityNavigates full;
      expected = true;
    };
  }
  # ══ FEATURE: battery.<name> ─ per-battery provision drop (rung 2b), data-driven over all 12 ─────────────
  // batteryRows;
}
