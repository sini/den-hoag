# ROUTE-CLASS-NAME GROUNDING (ship-gate rung; R2 grounded-terminology normalization on delivery fields).
# A v1 `route`/`deliver`/`provide` effect names its from/into CLASSES with v1 SPELLINGS. The corpus's
# home-platform routes (modules/den/classes/home-platform.nix:12/22/32) emit
# `route { fromClass = "home<Plat>"; intoClass = "homeManager"; path = []; }` — but den-hoag registers the
# built-in class as `home-manager`, and v1 keys home-manager content under `homeManager` (pin 11866c16
# nix/lib/entities/home.nix:124 `class = strOpt "…" "homeManager"`; nix/denTest.nix:108
# `den.schema.user.classes = ["homeManager"]`). So `translateDelivery`'s `resolveBucket` lookups aborted
# `unknown class homeManager` until the class-NAME fields (`target` ← intoClass, `sourceClass` ← fromClass)
# were grounded through the SAME `v1ClassKeyMap` translateAspect/groundKeys already use (compile.nix
# `groundClassName`). Grounding is IDENTITY for an already-grounded name (`flake-parts`, `homeLinux`, `src`),
# so the deliver's LOUD abort on a genuinely-unknown class name is preserved (loud fall-through, C6).
#
# WITNESSES: (a) a home-platform-shaped route (intoClass = "homeManager") fires at a real host and its
# delivery edge targets the grounded `home-manager` class; (b) fromClass grounding — a v1-spelled
# `fromClass = "homeManager"` grounds its SOURCE too (the fix grounds BOTH fields, not just target), and an
# already-grounded name passes through IDENTITY (`src` → `src`, corpus `homeLinux`/`flake-parts` unchanged);
# (c) a genuinely-unknown class name still aborts LOUDLY.
{
  denCompat,
  ...
}:
let
  inherit (denCompat)
    route
    compile
    ;

  # ── COMPILE-level (declaration inspection): the grounded class-name resolves to its den-hoag
  #    registration (C6 id_hash-bearing entry), read straight off the `delivery` declaration. `home-manager`
  #    is a den-hoag BUILT-IN class (compile's classRegistry = builtinClasses ∪ declared), so a route grounded
  #    to it resolves with no fixture registration; `homeLinux`/`src`/`dst` are declared for the identity rows.
  groundFixture = {
    classes.homeLinux = { };
    classes.src = { };
    classes.dst = { };
    policies = {
      # v1-spelled intoClass — grounds target `homeManager` → `home-manager` (the blocker shape).
      intoHm = _ctx: [
        (route {
          fromClass = "homeLinux";
          intoClass = "homeManager";
          path = [ ];
        })
      ];
      # v1-spelled fromClass — grounds SOURCE `homeManager` → `home-manager` (symmetric grounding proof).
      fromHm = _ctx: [
        (route {
          fromClass = "homeManager";
          intoClass = "src";
          path = [ ];
        })
      ];
      # already-grounded on BOTH fields — a pure identity passthrough (no map entry touched).
      identity = _ctx: [
        (route {
          fromClass = "src";
          intoClass = "dst";
          path = [ ];
        })
      ];
    };
  };
  compiled = compile groundFixture;
  declOf = name: builtins.head (compiled.policies.${name}.fn { });

  fails = expr: !(builtins.tryEval expr).success;
  # a genuinely-unknown class name (a typo, not a v1 spelling) — grounding is identity, so resolveBucket
  # still aborts when the resolved target is forced (C6 loud fall-through, unchanged by grounding).
  unknownCompile = compile {
    classes.homeLinux = { };
    policies.bad = _ctx: [
      (route {
        fromClass = "homeLinux";
        intoClass = "homeMangler";
        path = [ ];
      })
    ];
  };

  # ── FLEET-level (real node, home-platform-shaped): the route fires at host:igloo and materializes a
  #    delivery edge whose TARGET is the grounded `home-manager` class. Mirrors the corpus emitter: a
  #    declared source class `homeLinux`, an empty-formals policy (fires at every scope), path = [] (merge).
  mkFleet =
    intoClass:
    denCompat.mkDen [
      {
        config.den = {
          hosts.x86_64-linux.igloo.users.tux = { };
          classes.homeLinux = { };
          policies.homeLinux-to-hm = _: [
            (denCompat.route {
              fromClass = "homeLinux";
              intoClass = intoClass;
              path = [ ];
            })
          ];
          # a self-named host aspect so host:igloo carries real nixos content and resolves end-to-end.
          aspects.igloo.nixos.networking.hostName = "igloo";
        };
      }
    ];

  fleet = mkFleet "homeManager";
  den = fleet.den;
  edges = builtins.concatMap (r: den.graph.edges r) (builtins.attrNames den.scopeRoots);
  homeEdges = builtins.filter (e: (e.source.collected.class or null) == "homeLinux") edges;

  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;
  aborts = e: !(ok e);
  forceEdges = f: builtins.concatMap (r: f.den.graph.edges r) (builtins.attrNames f.den.scopeRoots);
in
{
  flake.tests.compat-route-class-grounding = {
    # ── (a) intoClass grounding: the delivery declaration's TARGET resolved to the `home-manager`
    #    registration (grounded from the v1 `homeManager` spelling) ─────────────────────────────────────
    test-into-homeManager-grounds-target = {
      expr = (declOf "intoHm").targetClass.name;
      expected = "home-manager";
    };
    test-target-is-registration = {
      expr = (declOf "intoHm").targetClass ? id_hash;
      expected = true;
    };

    # ── (b) fromClass grounding: a v1-spelled SOURCE grounds too; identity for already-grounded names ────
    test-from-homeManager-grounds-source = {
      expr = (declOf "fromHm").sourceClass.name;
      expected = "home-manager";
    };
    test-already-grounded-identity = {
      expr = {
        source = (declOf "identity").sourceClass.name;
        target = (declOf "identity").targetClass.name;
      };
      expected = {
        source = "src";
        target = "dst";
      };
    };

    # ── (c) a genuinely-unknown class name still aborts LOUDLY (grounding did not relax resolveBucket) ──
    test-unknown-class-still-aborts = {
      expr = fails ((builtins.head (unknownCompile.policies.bad.fn { })).targetClass.name);
      expected = true;
    };

    # ── (a) end-to-end at a REAL node: the home-platform-shaped route fires at host:igloo, NO deliver
    #    abort, and its delivery edge targets the grounded `home-manager` class at the merge root ────────
    test-route-fires-no-abort = {
      expr = {
        forces = ok edges;
        hasHomeDelivery = builtins.length homeEdges >= 1;
      };
      expected = {
        forces = true;
        hasHomeDelivery = true;
      };
    };
    test-delivery-target-is-home-manager = {
      expr =
        let
          e = builtins.head homeEdges;
        in
        {
          target = e.target.class or null;
          mode = e.mode or null;
          path = e.path or null;
          allGrounded = builtins.all (x: (x.target.class or null) == "home-manager") homeEdges;
        };
      expected = {
        target = "home-manager";
        mode = "merge";
        path = [ ];
        allGrounded = true;
      };
    };
    # the fleet resolves end-to-end (nixosConfigurations non-empty) while the grounded route fires.
    test-host-resolution-clean-e2e = {
      expr = {
        resolved = map (n: n.key) (den.structural.eval.get "host:igloo" "resolved-aspects");
        nixosConfigs = builtins.attrNames (fleet.nixosConfigurations or { });
      };
      expected = {
        resolved = [ "igloo" ];
        nixosConfigs = [ "igloo" ];
      };
    };
    # a fleet routing into a genuinely-unknown class still aborts when its edges are forced (loud).
    test-fleet-unknown-class-aborts = {
      expr = aborts (forceEdges (mkFleet "homeMangler"));
      expected = true;
    };
  };
}
