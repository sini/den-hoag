# den-compat batteries + the §339 aspect-include WRAP-GROUND (the V1-FLIP). Mechanisms:
#   (1) WRAP-GROUND — a v1 bare-fn include (`den.default.includes = [ ({host,...}: <content>) ]`) is now
#       wrapped into a gen-aspects `__isWrappedFn` functor at the compile boundary (compile.nix
#       `mkNormalize` + gen-aspects `wrapFn`), so it is INVOKED at resolution and its class content
#       MATERIALIZES — the pre-fix failure was a static, never-invoked "<anon>".
#   (1c) DISTINCT KEYS (silent-drop fix) — each wrap is keyed by a per-position NAME PATH
#        (`<owner>:include:<i>`), so sibling includes do NOT collapse onto one dedup key in forwardExpand
#        (the old shared "<include>" dropped every include after the first).
#   (1w) DECLARED-CLASS ROUTING (Fork A) — `den.classes.<x>` joins the wrap cnf, so a bare-fn include
#        emitting that class key (e.g. `wsl`) routes as CLASS content, not a nested aspect.
#   (1t) TRANSITIVE (Fork B) — a wrapped fn's RESULT and a static include's `.includes` are re-normalized
#        (nested bare fns wrapped, nested `homeManager` grounded to `home-manager`).
#   (2) the seven corpus batteries provisioned at `config.den.batteries.<name>` (lib/compat/batteries.nix).
#   (3) host-aspects — its `{ __isPolicy; fn }` include fires a REAL `den.lib.policy.spawn` (Task 3).
#   (4) surface-totality ACCEPTS a `den.batteries` key (inert-by-reference, like `reservedKeys`).
{
  genPrelude,
  denCompat,
  denHoag,
  nixpkgsLib,
  denHoagSrc,
  ...
}:
let
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  bucketAt =
    den: id: cls:
    (den.structural.eval.get id "class-modules").${cls} or [ ];
  hasBucket =
    den: id: cls:
    (den.structural.eval.get id "class-modules") ? ${cls};
  # Force a node's resolved-aspects (invokes every wrapped include at this scope) — `true` iff no throw.
  raOkAt = den: id: (builtins.tryEval (builtins.deepSeq (keysAt den id) true)).success;

  # ── (1) V1-FLIP: a bare-fn include in `den.default.includes` now materializes ───────────────────────
  flip =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [ ({ host, ... }: { nixos.foo = true; }) ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;
  flipKeys = keysAt flip "host:h1";
  flipNixos = bucketAt flip "host:h1" "nixos";

  # ── (1c) NO COLLISION: ONE aspect (defaults) with TWO distinct bare-fn includes — BOTH fire (a shared
  #    "<include>" key would dedup-drop the second, leaving one). ───────────────────────────────────────
  twoInc =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [
            ({ host, ... }: { nixos.aa = "A"; })
            ({ host, ... }: { nixos.bb = "B"; })
          ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # ── (1c') TWO named sub-aspects, each with a bare-fn include, radiated via `den.default` in ONE walk. ─
  twoAsp =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [
            {
              name = "asp1";
              includes = [ ({ host, ... }: { nixos.d1 = "1"; }) ];
            }
            {
              name = "asp2";
              includes = [ ({ host, ... }: { nixos.d2 = "2"; }) ];
            }
          ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # ── (1w + 1t) DECLARED-CLASS ROUTING + TRANSITIVE + COORD-GATE: a declared `wsl` class, a nested-fn
  #    include, and define-user's strict `{ host, user }` include radiated via `den.default`. The host
  #    scope MUST resolve (the `{ host, user }` include is gated OUT there, not thrown); the user cell
  #    carries the grounded `home-manager` content. ─────────────────────────────────────────────────────
  full =
    (denCompat.mkDen [
      {
        config.den = {
          classes.wsl = { };
          default.includes = [
            {
              name = "define-user";
              includes = [
                (
                  { host, user }:
                  {
                    name = "du";
                    nixos.users.users.${user.userName}.isNormalUser = true;
                    homeManager.home.username = user.userName;
                  }
                )
              ];
            }
            ({ host, ... }: { wsl.defaultUser = "x"; })
            ({ host, ... }: { includes = [ ({ host, ... }: { nixos.deep = "D"; }) ]; })
          ];
          hosts.x86_64-linux.h1 = {
            class = "nixos";
            users.alice = {
              classes = [ "homeManager" ];
            };
          };
        };
      }
    ]).den;

  # ── (2) battery provisioning — apply the flake-parts module directly with stub module args. ──────────
  batMod = import "${denHoagSrc}/lib/compat/batteries.nix";
  bat =
    (batMod {
      config = { };
      lib = nixpkgsLib;
      withSystem = _sys: g: g { };
      inputs = { };
      self = { };
      den = {
        lib = denHoag;
      };
    }).config.den.batteries;
  batteryNames = builtins.sort (a: b: a < b) (builtins.attrNames bat);
  expectedNames = builtins.sort (a: b: a < b) [
    "define-user"
    "hostname"
    "primary-user"
    "host-aspects"
    "inputs'"
    "self'"
    "unfree"
  ];

  # ── (3) host-aspects: its `{ __isPolicy; fn }` include fires a real spawn (Task 3 resolves the ctor). ─
  haPolicy = builtins.head bat.host-aspects.includes;
  haSpawn = builtins.head (
    haPolicy.fn {
      host = {
        name = "h";
        class = "nixos";
      };
      user = {
        classes = [ "homeManager" ];
      };
    }
  );
  spawnCompiled = denCompat.compile {
    policies.p = _ctx: [ (denHoag.policy.spawn { classes = [ "homeManager" ]; }) ];
  };
  # The retargeted spawn-arm (spec §7.1 / §6.2a) reads `ctx.host.name` to name the host root node — fire
  # with a real host ctx (an empty ctx would throw). Grounds `homeManager` → `home-manager` (v1ClassKeyMap).
  spawnDecls = spawnCompiled.policies.p.fn {
    host = {
      name = "h";
      class = "nixos";
    };
  };

  # ── (5) unfree `__functor`: `den.batteries.unfree [ names ]` → a parametric `{ __fn }` aspect include. ─
  unfreeAspect = bat.unfree [ "steam" ];

  # ── (6) callGated COORD-GATE (v1 canTake parity, `nix/lib/can-take.nix`): define-user's STRICT
  #    `{ host, user }` userContext radiated via `den.default`. At a HOST scope (ctx = {__entry, host}, NO
  #    `user`) the include is GATED to `{ }` (inert), NOT thrown; at a (user,host) CELL (ctx carries `user`)
  #    it FIRES. The wrapped node's `content.name` discriminates: gated → the merge-default "<function
  #    body>" ({ } carries no name), fired → the fn's returned `name` ("du-fired"). ─────────────────────
  gateFleet =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [
            {
              name = "define-user";
              includes = [
                (
                  { host, user }:
                  {
                    name = "du-fired";
                    nixos.duMarker = true;
                    homeManager.home.username = "alice";
                  }
                )
              ];
            }
          ];
          hosts.x86_64-linux.h1 = {
            class = "nixos";
            users.alice = {
              classes = [ "homeManager" ];
            };
          };
        };
      }
    ]).den;
  ucFiredAt =
    id:
    # The gate relocates UPSTREAM (`wrapGatedFn`): a GATED include returns a CLEAN `{ }` (no fired content),
    # a FIRED one returns the fn's `name = "du-fired"`. Discriminate by the presence of a resolved node
    # carrying that content name — host (gated) → no such node; cell (fired) → the node materializes. (The
    # node's own key is a positional path under the typed `defaults` aspect, so match the content, not the key.)
    builtins.any (n: (n.content.name or null) == "du-fired") (
      gateFleet.structural.eval.get id "resolved-aspects"
    );

  # ── (6b) hostname battery — REAL firing at a host node reading the STAMPED `host.hostName` (the field-
  #    coverage rung; the twin of `class`/`system`). The ACTUAL `bat.hostname` (batteries.nix, v1
  #    modules/aspects/batteries/hostname.nix) radiated via `den.default`; at a real host node its
  #    `setHostname` — `{ host, ... }: … // optionalAttrs (host ? class) { ${host.class}.networking.hostName
  #    = host.hostName; }` — reads `host.hostName` off the stamped ctx entity and emits the class config.
  #    `axon` takes the `config.name` default (v1 `strOpt "Network hostname" config.name`); `gw` authors an
  #    explicit override. This is the EXACT `host.hostName` read that hard-failed pre-stamp at the corpus,
  #    inverted to a passing witness. Filter by the battery's returned `content.name` ("hostname/os"), so the
  #    witness is robust to the resolved-aspects node-key path. ──────────────────────────────────────────
  # The battery is radiated via `den.default` so the fleet BUILDS it: compiling/probing `setHostname`
  # through the value-less sentinel (now carrying `hostName = "«probe»"`, flake-module.nix
  # `probeSentinelModule`) proves the field addition keeps the compile clean (no `attribute 'hostName'
  # missing` at the probe). The emitted VALUE is then read by applying the ACTUAL battery body to the REAL
  # STAMPED ctx host entity (enriched-context.host) — the resolved-aspects node stores it as a compiled
  # module, but the body applied to the real entity yields the clean `${host.class}.networking.hostName`.
  hostnameFleet =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [ bat.hostname ];
          hosts.x86_64-linux.axon.class = "nixos";
          hosts.x86_64-linux.gw = {
            class = "nixos";
            hostName = "gw-net";
          };
        };
      }
    ]).den;
  setHostname = builtins.head bat.hostname.includes;
  hostnameEmittedAt =
    id:
    let
      ctxHost = (hostnameFleet.structural.eval.get id "enriched-context").host;
    in
    (setHostname { host = ctxHost; }).${ctxHost.class}.networking.hostName;

  # ── (7) unfree class-coord PIN (ledger row u1 / board #55) — a LOUD PIN of the latent-v1-divergence.
  #    unfree's `__fn` REQUIRES a `class` coord; den-hoag's enriched-context injects none (v1 binds
  #    class=entityCls per-class-resolution, fx/resolve.nix:181/bind.nix:41), so the shim-wrapped include
  #    gates to `{ }` (no `packages`). WITH a `class` coord it WOULD fire — the gap is EXACTLY the
  #    class-coord injection. If den-hoag gains per-class `class` (#55 cand 1) or the shim expands per-class
  #    (cand 2), `firesWithoutClass`/`hostCtxLacksClass` FLIP and this test must be updated with the row. ─
  unfreeInc = bat.unfree [ "steam" ];
  unfWrapped =
    builtins.head
      (denCompat.compile { aspects.a.includes = [ unfreeInc ]; }).aspects.a.includes;
  # Task B — a GATED `__fn` (missing `class`) returns a clean `{ }` (no `.nixos`); `or { }` keeps `unfFires`
  # false on the gated path (no `packages`), true when it fires. (Pre-Task-B the submodule-merged gated `{ }`
  # carried an empty `.nixos`; the clean `{ }` is the same inert result without the merge scaffolding.)
  unfFires = ctx: genPrelude.hasInfix "packages" (builtins.toJSON ((unfWrapped ctx).nixos or { }));
  unfFleet =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [ unfreeInc ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # ── (8) primary-user (the bare-fn-battery RUNG). The corpus's `den.batteries.primary-user` is a TOP-LEVEL
  #    bare fn `{ user, host, ... }: …` (batteries.nix:134). THROUGH THE BRIDGE freeform it was MANGLED
  #    (nixpkgs `types.anything` lambda-merge → `functionArgs` erased → callGated's required-coord gate
  #    DEFEATED → the RUNG's `userToHostContext called without required argument 'user'` at a host scope). The
  #    bridge's declared `options.batteries` now preserves the bare fn (compat-bridge witnesses prove it
  #    survives the freeform). Here the UNMANGLED value's gate/fire is pinned via mkDen (whose internal
  #    gen-schema `raw` never mangled it): the REAL battery is a strict `{ user, host }` fn, so at a HOST scope
  #    (no `user`) callGated gates it INERT (resolves, no throw), and the primary-user SHAPE (canonical
  #    `user.name` — sidestepping the ORTHOGONAL `user.userName` ctx-field divergence, a further latent rung)
  #    FIRES wheel/networkmanager at a (user,host) cell. ────────────────────────────────────────────────────
  realPuFnArgs = builtins.functionArgs bat.primary-user;
  # host-only fleet with the REAL battery value → gated clean at the host (never reaches the `userName` read).
  realPuHostFleet =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [ bat.primary-user ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;
  realPuHostOk = raOkAt realPuHostFleet "host:h1";
  puShape =
    { user, host, ... }:
    {
      name = "primary-user(${user.name}@${host.name})";
      nixos.users.users.${user.name} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };
    };
  puShapeFleet =
    (denCompat.mkDen [
      {
        config.den = {
          default.includes = [ puShape ];
          hosts.x86_64-linux.h1 = {
            class = "nixos";
            users.alice.classes = [ "homeManager" ];
          };
        };
      }
    ]).den;
  puHasWheel = id: genPrelude.hasInfix "wheel" (builtins.toJSON (bucketAt puShapeFleet id "nixos"));

  # ── R5 (Task B): the RELOCATED coord-gate — `normalize` wraps a bare-fn / `__fn` include via gen-aspects'
  #    `wrapGatedFn` (the gate + intersectAttrs move UPSTREAM; `onResult = grndDispatch` grounds the result).
  #    EQUIVALENCE to the old `callGated`: a required coord MISSING ⇒ `{ }` (inert, no throw); PRESENT ⇒ the
  #    grounded class content, with an EXTRA ctx arg dropped by intersectAttrs. Exercised over BOTH arms —
  #    a plain bare fn (`:440`) and an `{ __fn }` record (`:444`, the unfree shape). ──
  # PLAIN-FN arm (:440): a strict `{ host }:` include → wrapped functor.
  r5PlainInc = { host, ... }: { nixos.r5 = "fired:${host.name or host}"; };
  r5PlainWrapped =
    builtins.head
      (denCompat.compile { aspects.a.includes = [ r5PlainInc ]; }).aspects.a.includes;
  # __fn arm (:444): a `{ __fn }` record (the unfree shape) requiring `class`.
  r5FnInc = {
    name = "r5fn";
    __fn = { class, ... }: { nixos.r5fn = "fired:${class}"; };
  };
  r5FnWrapped =
    builtins.head
      (denCompat.compile { aspects.b.includes = [ r5FnInc ]; }).aspects.b.includes;
  # a ctx WITH the coord (+ an EXTRA `__entry` that intersectAttrs must drop) vs WITHOUT it.
  r5FiredKeys = wrapped: ctx: builtins.attrNames ((wrapped ctx).nixos or { });
in
{
  flake.tests.compat-batteries = {
    # (1) V1-FLIP: the bare-fn include is INVOKED (a wrapped, positionally-keyed include), never the
    #     "<anon>" static aspect.
    test-flip-include-invoked = {
      expr = {
        hasWrapped = builtins.elem "defaults:include:0" flipKeys;
        hasAnon = builtins.elem "<anon>" flipKeys;
      };
      expected = {
        hasWrapped = true;
        hasAnon = false;
      };
    };
    # (1b) MATERIALIZES: the invoked include's class content reaches the host's nixos bucket.
    test-flip-content-materializes = {
      expr = builtins.length flipNixos;
      expected = 1;
    };

    # (1c) NO COLLISION — two sibling bare-fn includes each materialize (nixos bucket == 2, distinct keys).
    #      Under the old shared "<include>" key this would be 1 (the second dropped).
    test-two-includes-no-collision = {
      expr = {
        nixosCount = builtins.length (bucketAt twoInc "host:h1" "nixos");
        key0 = builtins.elem "defaults:include:0" (keysAt twoInc "host:h1");
        key1 = builtins.elem "defaults:include:1" (keysAt twoInc "host:h1");
      };
      expected = {
        nixosCount = 2;
        key0 = true;
        key1 = true;
      };
    };
    # (1c') two SEPARATE sub-aspects each radiated in one walk — both bare-fn includes materialize.
    test-two-aspects-radiated = {
      expr = builtins.length (bucketAt twoAsp "host:h1" "nixos");
      expected = 2;
    };

    # (1w) DECLARED-CLASS ROUTING (Fork A): `den.classes.wsl` in the wrap cnf → `wsl.defaultUser` is CLASS
    #      content (a `wsl` bucket), NOT a nested aspect. Without wsl in the cnf the bucket would be absent.
    test-wsl-class-routing = {
      expr = hasBucket full "host:h1" "wsl";
      expected = true;
    };
    # (1t) TRANSITIVE (Fork B) + COORD-GATE: the host scope resolves (the strict `{ host, user }` include is
    #      gated OUT — no throw), and the NESTED bare fn's `nixos.deep` materializes (proving recursion).
    test-nested-fn-transitive = {
      expr = {
        hostResolves = builtins.isList (keysAt full "host:h1");
        nestedNixosPresent = hasBucket full "host:h1" "nixos";
      };
      expected = {
        hostResolves = true;
        nestedNixosPresent = true;
      };
    };
    # (1t') define-user's `{ host, user }` include fires at the USER cell and its grounded `home-manager`
    #       content (homeManager.home.username → home-manager bucket) materializes (not just nixos).
    test-define-user-hm-grounds = {
      expr = {
        hmBucketPresent = hasBucket full "user:alice@host:h1" "home-manager";
        hmNonEmpty = builtins.length (bucketAt full "user:alice@host:h1" "home-manager") > 0;
      };
      expected = {
        hmBucketPresent = true;
        hmNonEmpty = true;
      };
    };

    # (6a) callGated: define-user's `{ host, user }` include radiated to a HOST scope resolves INERT
    #      (gated on the absent `user` coord, `{ }`), WITHOUT throwing `called without required argument`.
    test-callgated-host-scope-inert = {
      expr = {
        resolves = raOkAt gateFleet "host:h1";
        fired = ucFiredAt "host:h1";
      };
      expected = {
        resolves = true;
        fired = false;
      };
    };
    # (6b) the SAME include at a (user,host) CELL (ctx carries `user`) FIRES — its content materializes.
    test-callgated-user-cell-fires = {
      expr = {
        resolves = raOkAt gateFleet "user:alice@host:h1";
        fired = ucFiredAt "user:alice@host:h1";
      };
      expected = {
        resolves = true;
        fired = true;
      };
    };
    # (6c) hostname battery fires at a real host node, reading the STAMPED `host.hostName`: `axon` emits its
    #      name default, `gw` emits its authored override. The exact batteries.nix `host.hostName` read that
    #      hard-failed pre-stamp, now a passing witness at a real host scope.
    test-hostname-battery-fires = {
      expr = {
        defaulted = hostnameEmittedAt "host:axon";
        overridden = hostnameEmittedAt "host:gw";
      };
      expected = {
        defaulted = "axon";
        overridden = "gw-net";
      };
    };
    # (7) unfree class-coord PIN — latent-v1-divergence (ledger u1 / board #55). The `__fn` REQUIRES a
    #     `class` coord; den-hoag's host enriched-context has none → the shim-wrapped include is INERT (no
    #     `packages`); WITH a `class` coord it WOULD fire (the gap IS the class-coord injection). LOUD PIN:
    #     if den-hoag injects a per-class `class`, `firesWithoutClass`/`hostCtxLacksClass` flip — update
    #     this test together with ledger row `u1`.
    test-unfree-class-coord-inert = {
      expr = {
        fnRequiresClass = (builtins.functionArgs unfreeInc.__fn).class == false;
        firesWithoutClass = unfFires {
          __entry = { };
          host = {
            class = "nixos";
          };
        };
        firesWithClass = unfFires {
          __entry = { };
          host = {
            class = "nixos";
          };
          class = "nixos";
        };
        hostCtxLacksClass = !((unfFleet.structural.eval.get "host:h1" "enriched-context") ? class);
      };
      expected = {
        fnRequiresClass = true;
        firesWithoutClass = false;
        firesWithClass = true;
        hostCtxLacksClass = true;
      };
    };

    # (R5) RELOCATED-GATE EQUIVALENCE (Task B) — `normalize` now wraps via `wrapGatedFn` (gate + intersect
    #      upstream in gen-aspects; `onResult = grndDispatch` grounds). BOTH arms: a required coord MISSING
    #      ⇒ `{ }` (inert, no throw, no class content); PRESENT ⇒ grounded content, with an EXTRA `__entry`
    #      ctx arg dropped by intersectAttrs (the strict fn never chokes). This is the byte-equivalence of
    #      the old inline `callGated` gate, now supplied by the shared gen-aspects gated wrap.
    test-r5-relocated-gate-equivalence = {
      expr = {
        # PLAIN-FN arm (:440), strict `{ host, ... }`:
        plainInertOnMissing = r5FiredKeys r5PlainWrapped { __entry = { }; } == [ ]; # no `host` ⇒ { }
        plainFiresOnPresent = r5FiredKeys r5PlainWrapped {
          __entry = { };
          host = "h";
        }; # `host` present, `__entry` dropped
        # __fn arm (:444), strict `{ class, ... }`:
        fnInertOnMissing = r5FiredKeys r5FnWrapped { __entry = { }; } == [ ]; # no `class` ⇒ { }
        fnFiresOnPresent = r5FiredKeys r5FnWrapped {
          __entry = { };
          class = "nixos";
        };
      };
      expected = {
        plainInertOnMissing = true;
        plainFiresOnPresent = [ "r5" ];
        fnInertOnMissing = true;
        fnFiresOnPresent = [ "r5fn" ];
      };
    };

    # (8a) the REAL `den.batteries.primary-user` is a strict `{ user, host }` bare fn (the shape the bridge
    #      freeform erased); radiated via `den.default` to a HOST scope its `user` coord is absent → callGated
    #      gates it INERT (resolves, NO throw) — the RUNG's blocker resolved, with the EXACT corpus value.
    test-primary-user-host-gated-inert = {
      expr = {
        realFnArgs = realPuFnArgs;
        hostResolves = realPuHostOk;
      };
      expected = {
        realFnArgs = {
          host = false;
          user = false;
        };
        hostResolves = true;
      };
    };
    # (8b) the primary-user SHAPE (canonical user.name) gates OUT at the host (no wheel) and FIRES at the
    #      (user,host) cell → nixos.users.users.<u>.extraGroups carries wheel/networkmanager (the shape).
    test-primary-user-cell-fires-wheel = {
      expr = {
        hostFires = puHasWheel "host:h1";
        cellFires = puHasWheel "user:alice@host:h1";
      };
      expected = {
        hostFires = false;
        cellFires = true;
      };
    };

    # (2) all seven corpus batteries provisioned at config.den.batteries.<name>.
    test-seven-batteries-present = {
      expr = batteryNames;
      expected = expectedNames;
    };

    # (3) host-aspects: its `{ __isPolicy }` include fires a REAL spawn (den.lib.policy.spawn resolves),
    #     self-announcing with a spawn effect — never a silent no-op.
    test-host-aspects-fires-spawn = {
      expr = {
        kind = haSpawn.__policyEffect;
        classes = haSpawn.value.classes;
      };
      expected = {
        kind = "spawn";
        classes = [ "homeManager" ];
      };
    };
    # (3b) that classes-form spawn effect RETARGETS to N class-scoped `reach-edge`s (spec §7.1 / §6.2a): one
    #      per class, each reaching the firing cell's own host root (`host:<name>`), class-filtered (grounded
    #      terminology — `homeManager` → `home-manager`). The old inert `spawn` payload was unread.
    test-spawn-compiles-to-reach-edge = {
      expr =
        let
          edge = builtins.head spawnDecls;
        in
        {
          count = builtins.length spawnDecls;
          action = edge.__action;
          target = edge.target;
          classFilter = edge.classFilter;
        };
      expected = {
        count = 1;
        action = "reach-edge";
        target = "host:h";
        classFilter = "home-manager";
      };
    };

    # (4) surface-totality ACCEPTS a `den.batteries` key (inert-by-reference, like reservedKeys); a bogus
    #     key still aborts (the contrast — totality is not widened).
    test-batteries-key-accepted = {
      expr = {
        batteriesOk =
          (builtins.tryEval (
            builtins.attrNames (
              denCompat.compile {
                batteries.x = {
                  name = "x";
                  includes = [ ];
                };
              }
            )
          )).success;
        bogusAborts =
          !(builtins.tryEval (builtins.attrNames (denCompat.compile { bogusSurfaceKey = 1; }))).success;
      };
      expected = {
        batteriesOk = true;
        bogusAborts = true;
      };
    };

    # (5) unfree `__functor`: `den.batteries.unfree [ names ]` → a parametric `{ __fn }` aspect include.
    test-unfree-functor-parametric = {
      expr = {
        hasFn = unfreeAspect ? __fn;
        name = unfreeAspect.name;
      };
      expected = {
        hasFn = true;
        name = "unfree(steam)";
      };
    };
  };
}
