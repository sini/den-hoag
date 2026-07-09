# compat-legacy-rules (R-set, spec §10) — one test group per legacy-surface rule R1–R9, each citing its
# rule number + den v1 source (frozen pin 11866c16). This is Task 7.5's per-rule acceptance: every rule
# has an implementation confined to lib/compat/ (+legacy/), a witness-map row (parity/fixtures/
# witness-map.nix `ruleWitnesses`), and ≥1 test here. The L3/L5 default-fold CONVERGENCE the R-set drives
# is pinned by the parity suites (parity-structural / the golden); this suite pins the per-rule mechanics.
{
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  wm = import "${denHoagSrc}/parity/fixtures/witness-map.nix" { inherit denCompat; };
  inherit (wm) ruleWitnesses;
  ruleIds = [
    "R1"
    "R2"
    "R3"
    "R4"
    "R5"
    "R6"
    "R7"
    "R8"
    "R9"
  ];

  aborts = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;

  # ── R1 — legacy binding environment (nixModule/default.nix:3: _module.args.den = config.den) ──────────
  # A v1 module body referencing `{ den, ... }` compiles only because evalV1 binds `den` (= config.den).
  r1Den = denCompat.evalV1 [ ({ den, ... }: { config.den.classes.__r1.present = den ? aspects; }) ];

  # ── R2 — legacy class registry (os/user via the public class registry, no core classNames edit) ───────
  batteriesDesugar = denCompat.legacy.defaults.desugar;
  r2Desugared = batteriesDesugar { };
  r2Compiled = denCompat.compile r2Desugared;

  # ── R3 — os → host.class routing (os-class.nix:26-43), a FORMAL-PRESERVING canTake route ──────────────
  # The compiled policy is `{ host, ... }@ctx:` — its formals ARE the canTake gate (den-hoag fires it only
  # where a host coordinate is in scope). It routes os → the host's OS class (`host.class or null`).
  r3Route = r2Compiled.policies.os-to-host;
  r3CanTake = builtins.functionArgs r3Route; # { host = false; } — the canTake condition
  r3ToNixos = r3Route {
    host = {
      name = "h";
      class = "nixos";
    };
  };
  # v1's `host ? class` gate: a synthetic `user@host` home (no class FIELD) or an explicit null class must
  # stay INERT — the route renders a `__dropped` no-op delivery, NEVER a misroute to a default (ruling B2).
  r3SyntheticInert = builtins.head (r3Route {
    host = {
      name = "laptop";
    };
  });
  r3NullClassInert = builtins.head (r3Route {
    host = {
      name = "h";
      class = null;
    };
  });

  # ── R4 — den.default radiation (defaults.nix genAttrs [host user home]) + built-in membership ─────────
  r4Compiled = denCompat.compileFull ruleWitnesses.R4.decls;

  # ── R5 — self-named-aspect auto-include (resolve-entity.nix:48-63) + SEVERABILITY ─────────────────────
  r5Decls = ruleWitnesses.R5.decls;
  # Full wiring (legacy set carries self-provide) → the self-named aspect auto-includes at its host.
  r5Full = denCompat.mkDen [ { config.den = r5Decls; } ];
  r5FullResolved = map (n: n.key) (r5Full.den.structural.eval.get "host:igloo" "resolved-aspects");
  # SEVERED wiring (no self-provide) → NO self-includes: a byte-identical no-op (Law C5).
  severedWiring = denCompat.mkWiring { inherit (denCompat.legacy) provides forwards; };
  r5FullInclude = (denCompat.compileFull r5Decls).include;
  r5SeveredInclude = (severedWiring.compileFull r5Decls).include;

  # ── R6 — built-in battery aspects (os-user: user class + adapter-bearing user-to-host route) ──────────
  r6UserRoute = r2Compiled.policies.user-to-host;
  r6RouteOut = r6UserRoute {
    user = {
      name = "alice";
    };
    host = {
      name = "h";
      class = "nixos";
    };
  };
  # The user-to-host route is ADAPTER-BEARING (adaptArgs osConfig) — its descriptor carries adaptArgs.
  r6RouteDesc = builtins.head r6RouteOut;

  # ── R7 — v1 lambda arg adaptation (loud): the lambda is PRESERVED (never _:{}-substituted) ────────────
  # A satisfied policy lambda runs verbatim → yields its effect. A _:{} substitution would yield [ ].
  r7Compiled = denCompat.compile {
    aspects.a = { };
    policies.p =
      { host, ... }:
      [
        {
          __policyEffect = "include";
          value = {
            name = "a";
          };
        }
      ];
  };
  r7Out = r7Compiled.policies.p {
    host = {
      name = "h";
    };
  };

  # ── R8 — host→user resolve semantics (PR #589/#624): each (user,host) is one membership cell ──────────
  r8Compiled = denCompat.compile ruleWitnesses.R8.decls;

  # ── R9 — no strictness escape: an unknown aspect-content key aborts named (three-branch dispatch) ─────
  mkR9 =
    key:
    let
      b = denCompat.mkDen [
        {
          config.den = {
            hosts.x86_64-linux.igloo.users.tux = { };
            aspects.igloo.${key} = { };
          };
        }
      ];
      den = b.den;
    in
    builtins.concatMap (r: den.graph.edges r) (builtins.attrNames den.scopeRoots);
in
{
  flake.tests.compat-legacy-rules = {
    # ── coverage: every rule R1–R9 is present + witnessed in the map ──────────────────────────────────
    test-rset-coverage = {
      expr = builtins.all (r: ruleWitnesses ? ${r}) ruleIds;
      expected = true;
    };
    test-rset-count = {
      expr = builtins.length (builtins.attrNames ruleWitnesses);
      expected = 9;
    };
    # every rule row cites a v1 source (the theory-citation convention).
    test-rset-all-cite-v1 = {
      expr = builtins.all (r: (ruleWitnesses.${r}.v1Source or "") != "") ruleIds;
      expected = true;
    };

    # ── R1 ────────────────────────────────────────────────────────────────────────────────────────────
    # `den` is bound in the v1-surface eval (a `{ den, ... }:` module compiles + reads config.den).
    test-r1-den-bound = {
      expr = r1Den.classes.__r1.present or false;
      expected = true;
    };

    # ── R2 ────────────────────────────────────────────────────────────────────────────────────────────
    # the os/user convenience classes register through the public class registry (compiled classes).
    test-r2-registers-os-user = {
      expr = {
        os = r2Compiled.classes ? os;
        user = r2Compiled.classes ? user;
        registered = denCompat.legacy.defaults.registeredClasses;
      };
      expected = {
        os = true;
        user = true;
        registered = [
          "os"
          "user"
        ];
      };
    };
    # a registered class resolves through resolveBucket for a route's fromClass (no unknown-class abort).
    test-r2-resolveBucket-os = {
      expr = ok (r3Route {
        host = {
          name = "h";
          class = "nixos";
        };
      });
      expected = true;
    };
    # R2 CLOSURE (the earlier deferral): under the FULL flakeModule the batteries auto-apply, so `os`
    # registers as a declared class (assembly §2.2 declared-classes) and an aspect keying `os = {…}` now
    # CLASSIFIES (its content forced through class-modules) — with NO core `classNames` edit; an unknown
    # key still aborts (three-branch strictness, R9).
    test-r2-os-aspect-key-classifies = {
      expr = {
        os = ok (mkR9 "os");
        unknown = aborts (mkR9 "totallyUnknownKey");
      };
      expected = {
        os = true;
        unknown = true;
      };
    };

    # ── R3 ────────────────────────────────────────────────────────────────────────────────────────────
    # os-to-host is a FORMAL-PRESERVING canTake route: its `{ host, ... }` formals are the canTake
    # condition (den-hoag dispatch fires it only where a host coordinate is in scope), and it routes os to
    # the host's OS class. The materialization (the `collected:host/os` edge appearing on the fleet) is the
    # parity harness's job (parity/golden/traces.nix — the L3/L5 os-route flip); here we pin the gate + target.
    test-r3-cantake-condition = {
      expr = r3CanTake;
      expected = {
        host = false;
      };
    };
    # routes to the host's OS class: an os → host.class (nixos) delivery. (darwin routing needs the darwin
    # output class registered — deferred, corpus-unexercised: the corpus has only nixos hosts, PIN.md.)
    test-r3-routes-to-host-class = {
      expr = (builtins.head r3ToNixos).targetClass.name;
      expected = "nixos";
    };
    # the fired route is an os→nixos delivery declaration (route sugar → deliver → declare.delivery, C3);
    # the `os`/`nixos` class names resolved to entries at compile (C6), read back via `.name` for display.
    test-r3-route-shape = {
      expr =
        let
          d = builtins.head r3ToNixos;
        in
        {
          delivery = d.__action == "delivery";
          from = d.sourceClass.name;
          to = d.targetClass.name;
        };
      expected = {
        delivery = true;
        from = "os";
        to = "nixos";
      };
    };
    # CLASSLESS-HOST INERT (ruling B2, v1 `host ? class` parity): a synthetic home (no class field) OR an
    # explicit null class → a `__dropped` no-op delivery (dropped at materialization, renders no edge),
    # never a misroute to a default. A real nixos host is NOT dropped (routes).
    test-r3-classless-host-inert = {
      expr = {
        synthetic = r3SyntheticInert.__dropped;
        nullClass = r3NullClassInert.__dropped;
        realHostRoutes = (builtins.head r3ToNixos).__dropped;
      };
      expected = {
        synthetic = true;
        nullClass = true;
        realHostRoutes = false;
      };
    };

    # ── R4 ────────────────────────────────────────────────────────────────────────────────────────────
    # den.default → the reserved __default aspect + the __denDefault radiation policy (compile core), and
    # the built-in battery membership: after the batteries desugar → compile, the pinned membership policies
    # (os-to-host, user-to-host) are STRUCTURALLY present in the compiled policy set (not read back from the
    # battery's own declared name list — a structural check, not a tautology).
    test-r4-radiation-and-membership = {
      expr = {
        defaultAspect = r4Compiled.aspects ? __default;
        radiationPolicy = r4Compiled.policies ? __denDefault;
        osToHost = r2Compiled.policies ? os-to-host;
        userToHost = r2Compiled.policies ? user-to-host;
      };
      expected = {
        defaultAspect = true;
        radiationPolicy = true;
        osToHost = true;
        userToHost = true;
      };
    };

    # ── R5 ────────────────────────────────────────────────────────────────────────────────────────────
    # the self-named aspect `igloo` auto-includes at host:igloo (the L3/L5 convergence driver).
    test-r5-self-named-resolves = {
      expr = builtins.elem "igloo" r5FullResolved;
      expected = true;
    };
    # SEVERABILITY (Law C5): the full wiring emits the self-include; the severed wiring emits none — a
    # byte-identical no-op (never an error; a self-named aspect leaves no residual key to sentinel).
    test-r5-severable = {
      expr = {
        fullEmits = builtins.length r5FullInclude;
        severedEmits = builtins.length r5SeveredInclude;
      };
      expected = {
        fullEmits = 1;
        severedEmits = 0;
      };
    };

    # ── R6 ────────────────────────────────────────────────────────────────────────────────────────────
    # os-user battery: the `user` class registers + the user-to-host route is ADAPTER-BEARING (adaptArgs).
    test-r6-user-battery = {
      expr = {
        userClass = r2Compiled.classes ? user;
        routePresent = r2Compiled.policies ? user-to-host;
        adapterBearing = r6RouteDesc.adaptArgs != null;
        to = r6RouteDesc.targetClass.name;
      };
      expected = {
        userClass = true;
        routePresent = true;
        adapterBearing = true;
        to = "nixos";
      };
    };

    # ── R7 ────────────────────────────────────────────────────────────────────────────────────────────
    # a satisfied v1 lambda runs VERBATIM (yields its effect) — the shim never substitutes `_: { }` (which
    # would yield [ ]). The unmatched-arg case fails as an UNCATCHABLE Nix eval error (genuinely loud) —
    # not asserted here (tryEval cannot catch a missing-required-argument), but that loudness IS R7.
    test-r7-lambda-preserved = {
      expr = builtins.length r7Out;
      expected = 1;
    };

    # ── R8 ────────────────────────────────────────────────────────────────────────────────────────────
    # a host with two users → two membership cells, one per (user, host) (ingest buildMembership).
    test-r8-cells-per-user-host = {
      expr = {
        cells = builtins.length r8Compiled.entities.membership;
        users = builtins.attrNames r8Compiled.entities.registries.user;
      };
      expected = {
        cells = 2;
        users = [
          "alice"
          "bob"
        ];
      };
    };

    # ── R9 ────────────────────────────────────────────────────────────────────────────────────────────
    # an unknown aspect-content key aborts named when its class content is assembled (three-branch
    # dispatch); a known class key does not — no per-kind strict toggle, no silent drop.
    test-r9-unknown-key-aborts = {
      expr = aborts (mkR9 "totallyUnknownKey");
      expected = true;
    };
    test-r9-known-key-ok = {
      expr = ok (mkR9 "nixos");
      expected = true;
    };
  };
}
