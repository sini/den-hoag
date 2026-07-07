# The C1 WITNESS MAP — every den v1 §2.2 surface row → its compat mechanism + a witness fixture. This is
# the machine-readable completeness ledger the C7/C8 parity harness reads as input (each fixture is a den
# v1 declaration set the harness compiles on the v2 arm AND runs through den v1 on the oracle arm). It is
# the OTHER half of surface totality: `compile`'s `unknownSurfaceKey` rejects a key the shim does NOT
# know; this map proves the shim DOES know (and witnesses) every key it claims to.
#
# Each fixture is one of:
#   • `{ decls = <v1 decl set>; pin = <suite>; runBodies ? false; legacy ? null; }` — a surface the shim
#     COMPILES. `ci/tests/compat-surface.nix` asserts `denCompat.compileFull decls` accepts it (no shim
#     rejection); `runBodies` additionally runs each compiled policy body (the effect→declaration half);
#     `pin` names the C-suite that pins the surface's DEEP semantics; `legacy` marks a surface desugared
#     by a severable legacy module (so it compiles only through `compileFull`, never bare `compile`).
#   • `{ decls = <v1 decl set>; notImplemented = { census; pointer; }; pin = <suite>; }` — a surface the
#     shim does NOT implement, deliberately (corpus-zero census). `compat-surface.nix` asserts it ABORTS
#     named (never silently absorbed), and records the census + migration pointer. The ONE such surface is
#     `den.batteries.forward` (`meta.__forward`) — PIN.md Open-Question-2.
#
# `denCompat` is threaded so the `deliver`/`route`/`provide` witnesses call the REAL surface functions
# (their bodies desugar to descriptors when run), exactly as a v1 corpus policy body does.
{ denCompat }:
let
  # The §2.4 pipe stage fixtures are shared with compat-compile-golden (one witness set, two readers): the
  # golden pins the stage→op DAG; this map records them as the `pipe.from` row witnesses.
  pipeFx = import ./pipe-stages.nix { };
  inherit (denCompat) deliver route provide;
in
rec {
  # ── the fixtures ────────────────────────────────────────────────────────────────────────────────────
  fixtures = {
    # r1 `den.hosts.<system>.<name>` — the two-level host map, flattened at ingestion (`system` → field).
    hostsTwoLevel = {
      decls = {
        hosts.x86_64-linux.axon = {
          class = "nixos";
        };
        hosts.aarch64-linux.pi = {
          class = "nixos";
        };
      };
      pin = "compat-compile-golden";
    };

    # r2 `den.homes.<system>.<name>` — MANDATORY: multi-system `@system` homes. The same user (`alice`)
    # bound on two hosts across two systems → two membership cells, ONE user registry entry (the NORMAL
    # multi-host case). Exercises the `user@host` name parse + the per-system two-level flatten.
    homesMultiSystem = {
      decls = {
        hosts.x86_64-linux.axon = {
          class = "nixos";
        };
        hosts.aarch64-linux.pi = {
          class = "nixos";
        };
        homes.x86_64-linux."alice@axon" = { };
        homes.aarch64-linux."alice@pi" = { };
      };
      pin = "compat-surface";
    };

    # r3 `den.schema.<kind>` — MANDATORY: custom kinds (topology + kind-attached includes). `env` under
    # host, `cluster` under `env` (a two-deep custom DAG); `cluster` carries a kind-attached include →
    # a fire-at-kind policy. The custom-kind INSTANCES ride at `den.env.*` / `den.cluster.*` (the totality
    # check accepts them because their kinds are declared).
    schemaCustomKind = {
      decls = {
        schema.env = {
          parent = "host";
        };
        schema.cluster = {
          parent = "env";
          includes = [ { name = "clusterBase"; } ];
        };
        aspects.clusterBase = { };
        env.prod = { };
        cluster.k3s = { };
      };
      pin = "compat-surface";
    };

    # r4 `den.aspects.<name>` — parametric class key (a `nixos` body that is a function) + a quirk key +
    # `includes` + `meta.drop`. Near-identity translation: class keys grounded, quirk keys ride raw,
    # `meta` passes through. The parametric body is never forced by surface acceptance (attrNames only).
    aspectParametric = {
      decls = {
        quirks."ssh-peers" = { };
        aspects.system = {
          nixos =
            { host, ... }:
            {
              system.stateVersion = "25.11";
            };
          "ssh-peers" = [ "self-ip" ];
          includes = [ ];
          meta.drop = [ ];
        };
      };
      pin = "compat-compile-golden";
    };

    # r5 `den.policies.<name>` — a function of destructured entity ctx returning an effect list. The
    # destructured `{ host, ... }` body is NOT run here (surface acceptance is the policy SHAPE); the
    # for/when gating that reads ctx is pinned by compat-compile-golden.
    policyFn = {
      decls = {
        aspects.base = { };
        policies.attachBase =
          { host, ... }:
          [
            {
              __policyEffect = "include";
              value = {
                name = "base";
              };
            }
          ];
      };
      pin = "compat-compile-golden";
    };

    # r6 `policy.resolve` / `.shared` — fan-out (`spawn` / `spawnShared`). Both the isolated and shared
    # branches, run to force the spawn declaration.
    policyResolve = {
      decls = {
        policies.fanoutPlain = _ctx: [
          {
            __policyEffect = "resolve";
            __shared = false;
            value = { };
            includes = [ ];
          }
        ];
        policies.fanoutShared = _ctx: [
          {
            __policyEffect = "resolve";
            __shared = true;
            value = { };
            includes = [ ];
          }
        ];
      };
      pin = "compat-compile-golden";
      runBodies = true;
    };

    # r7 `policy.include` / `policy.exclude` — aspect refs → `edge` / `drop`, run to force both.
    policyIncludeExclude = {
      decls = {
        aspects.a = { };
        policies.incl = _ctx: [
          {
            __policyEffect = "include";
            value = {
              name = "a";
            };
          }
        ];
        policies.excl = _ctx: [
          {
            __policyEffect = "exclude";
            value = {
              name = "a";
            };
          }
        ];
      };
      pin = "compat-compile-golden";
      runBodies = true;
    };

    # r8 `deliver { from, to, at, mode, guard, adaptArgs }` — the v1 delivery primitive, called for real
    # (the body desugars to a delivery descriptor when run). `nixos` is a built-in class.
    deliverPrimitive = {
      decls = {
        policies.deliverToNixos = _ctx: [
          (deliver {
            from = "nixos";
            to = "nixos";
            at = [ ];
          })
        ];
      };
      pin = "compat-deliver-matrix";
      runBodies = true;
    };

    # r9 `policy.route` / `policy.provide` — permanent sugar over `deliver`, both called for real.
    routeProvide = {
      decls = {
        policies.routeHm = _ctx: [
          (route {
            fromClass = "home-manager";
            intoClass = "nixos";
            path = [ "users" ];
          })
        ];
        policies.provideMod = _ctx: [
          (provide {
            class = "nixos";
            module = {
              config.programs.foo.enable = true;
            };
            path = [ ];
          })
        ];
      };
      pin = "compat-deliver-matrix";
      runBodies = true;
    };

    # r10 `policy.instantiate` — a native per-cluster instantiation request → `spawn` with `instantiate`.
    policyInstantiate = {
      decls = {
        policies.inst = _ctx: [
          {
            __policyEffect = "instantiate";
            value = {
              intoAttr = "manifests";
            };
          }
        ];
      };
      pin = "compat-surface";
      runBodies = true;
    };

    # r11 `policy.spawn { classes }` — the deferred home-projection spawn (PR #623 producing-scope
    # resolution) → a den-hoag `spawn` of the named classes.
    policySpawn = {
      decls = {
        policies.projectHome = _ctx: [
          {
            __policyEffect = "spawn";
            value = {
              classes = [ "home-manager" ];
            };
          }
        ];
      };
      pin = "compat-surface";
      runBodies = true;
    };

    # r12a `policy.for entities` — entity-gated policy (v1 `{ __isPolicy; fn }`). Run to force the gated
    # include (the fn is ctx-agnostic here, so it fires unconditionally at the probe ctx).
    policyFor = {
      decls = {
        aspects.a = { };
        policies.forAxon = {
          __isPolicy = true;
          name = "forAxon";
          fn = _ctx: [
            {
              __policyEffect = "include";
              value = {
                name = "a";
              };
            }
          ];
        };
      };
      pin = "compat-compile-golden";
      runBodies = true;
    };

    # r12b `policy.when` (non-`hasAspect`) — MANDATORY: a plain rule-guard predicate (reads `host.name`,
    # not `hasAspect`) → a den-hoag policy whose gate is a plain gen-select guard. NOT run (the guard
    # destructures ctx); surface acceptance is the policy shape (compiles to a policy, not an aspect).
    policyWhenPlain = {
      decls = {
        aspects.a = { };
        policies.guardByHost = {
          __isPolicy = true;
          name = "guardByHost";
          fn =
            { host, ... }:
            if (host.name or "") == "axon" then
              [
                {
                  __policyEffect = "include";
                  value = {
                    name = "a";
                  };
                }
              ]
            else
              [ ];
        };
      };
      pin = "compat-surface";
    };

    # r12c `policy.when` (`hasAspect`) — MANDATORY: a predicate over `hasAspect` routes into the joint
    # neededBy+guard FIXPOINT, never policy dispatch (r2 §B4b). Compiles to a CONDITIONAL ASPECT (guard +
    # gated includes), lifted OUT of `den.policies` — the discriminator is the `meta.guard`+`meta.aspects`
    # pair. Surface acceptance asserts it lands in `aspects`, not `policies`.
    policyWhenHasAspect = {
      decls = {
        aspects.a = { };
        aspects.b = { };
        policies.whenHasA = {
          name = "<when>";
          meta.guard = { hasAspect, ... }: hasAspect "a";
          meta.aspects = [ { name = "b"; } ];
          includes = [ ];
        };
      };
      pin = "compat-compile-golden";
    };

    # r13 `pipe.from name [stages]` — MANDATORY: each §2.4 stage. The five pipe-stages fixtures cover
    # deriving (filter/transform/fold/for), delivery (to/as), and site (append/expose/broadcast/collect/
    # collectAll/withProvenance) stages. Run to force each pipeOp declaration.
    pipeDerive = {
      decls = pipeFx.derivePipe;
      pin = "compat-compile-golden";
      runBodies = true;
    };
    pipeDeliverTo = {
      decls = pipeFx.deliverToPipe;
      pin = "compat-compile-golden";
      runBodies = true;
    };
    pipeDeliverAs = {
      decls = pipeFx.deliverAsPipe;
      pin = "compat-compile-golden";
      runBodies = true;
    };
    pipeSite = {
      decls = pipeFx.sitePipe;
      pin = "compat-compile-golden";
      runBodies = true;
    };
    pipeForVsTransform = {
      decls = pipeFx.forVsTransform;
      pin = "compat-compile-golden";
      runBodies = true;
    };

    # r14 `den.quirks.<name>` — a channel registration (+ the class/quirk key-overlap check). A bare
    # marker quirk and one carrying gen-pipe channel options.
    quirksChannel = {
      decls = pipeFx.channelsFixture;
      pin = "compat-compile-golden";
    };

    # r15 `den.classes.<name>` — a class registration (`wrap`/`instantiate`/`share`); v1-battery keys drop.
    classRegistration = {
      decls = {
        classes.myclass = {
          wrap = null;
          instantiate = null;
          share.core = true;
        };
      };
      pin = "compat-compile-golden";
    };

    # r16 `den.default` / `den.batteries.*` — MANDATORY: battery aspects compile as ORDINARY aspects.
    # `den.default` (v1 defaults.nix:15-19) is registered as `__default` and radiated by the `__denDefault`
    # policy, NARROWED to v1's three built-in kinds — host, user, home (`lib.genAttrs [ "host" "user"
    # "home" ]`), NOT all kinds. den-hoag folds home into user, so the target is host + user; the policy's
    # `{ host, ... }` canTake guard fires only where a host coordinate is in scope, excluding custom kinds.
    # `homeManager` class key grounds to `home-manager`. (`den.batteries.*` live at `config.batteries`,
    # NOT `config.den`, so the compat surface only ever sees the value inlined into `den.default.includes`
    # / an aspect's `includes`; there is no separate `den.batteries` surface key to compile.)
    denDefault = {
      decls = {
        default = {
          nixos.system.stateVersion = "25.11";
          homeManager.home.stateVersion = "25.11";
          includes = [ ];
        };
      };
      pin = "compat-surface";
    };

    # r17 `aspect.provides.*` — LEGACY (legacy/provides.nix): desugared to `neededBy` under §B4a. Compiles
    # only through `compileFull` (the desugar strips `provides` before compile); bare `compile` trips the
    # provides sentinel (C5). Deep dispatch parity is compat-provides-desugar's.
    providesLegacy = {
      decls = {
        aspects.foo.provides.to-users = {
          nixos.services.foo.enable = true;
        };
      };
      legacy = "provides";
      pin = "compat-provides-desugar";
    };

    # r18a class `forwardTo` — LEGACY (legacy/forwards.nix): the desugar STRIPS `forwardTo` (inert default
    # metadata, corpus-zero census) before compile. Compiles only through `compileFull`; bare `compile`
    # trips the forwards sentinel (C5).
    forwardToLegacy = {
      decls = {
        classes.myclass = {
          forwardTo = {
            class = "nixos";
            path = [ ];
          };
          wrap = null;
        };
      };
      legacy = "forwards";
      pin = "compat-legacy-severed";
    };

    # r18b `den.batteries.forward` (`meta.__forward`) — NOT IMPLEMENTED BY CENSUS. The forward-battery NTA
    # path has ZERO corpus consumers (PIN.md Open-Question-2). Rather than pass the opaque `meta.__forward`
    # payload through as aspect content, the shim ABORTS named with a migration pointer (surface totality).
    # compat-surface asserts the abort fires; this is the honest witness that the row is accounted-for as
    # unbuilt, not silently absorbed.
    batteriesForward = {
      decls = {
        aspects.userClass = {
          includes = [ ];
          meta.__forward = {
            fromClass = "user";
            intoClass = "nixos";
          };
        };
      };
      notImplemented = {
        census = "zero corpus consumers (PIN.md Open-Question-2 — Tier-2 derived-children NTA deliberately unbuilt)";
        pointer = "migrate the forward to a native den-hoag class + `deliver` (legacy/forwards Tier-1), or build the Tier-2 NTA in legacy/forwards.nix and re-open Open Question 2";
      };
      pin = "compat-surface";
    };
  };

  # ── the §2.2 surface rows (the v1-construct column) → their witness fixture id(s) ────────────────────
  # Coverage obligation (compat-surface.nix): every `specRows` key is present here, and every id it names
  # exists in `fixtures`. A row with no witness is a C1 test-plan gap (tracked under P6 discipline).
  rows = {
    "den.hosts" = [ "hostsTwoLevel" ];
    "den.homes" = [ "homesMultiSystem" ];
    "den.schema" = [ "schemaCustomKind" ];
    "den.aspects" = [ "aspectParametric" ];
    "den.policies" = [ "policyFn" ];
    "policy.resolve" = [ "policyResolve" ];
    "policy.include|exclude" = [ "policyIncludeExclude" ];
    "deliver" = [ "deliverPrimitive" ];
    "policy.route|provide" = [ "routeProvide" ];
    "policy.instantiate" = [ "policyInstantiate" ];
    "policy.spawn" = [ "policySpawn" ];
    "policy.for|when" = [
      "policyFor"
      "policyWhenPlain"
      "policyWhenHasAspect"
    ];
    "pipe.from" = [
      "pipeDerive"
      "pipeDeliverTo"
      "pipeDeliverAs"
      "pipeSite"
      "pipeForVsTransform"
    ];
    "den.quirks" = [ "quirksChannel" ];
    "den.classes" = [ "classRegistration" ];
    "den.default" = [ "denDefault" ];
    "aspect.provides" = [ "providesLegacy" ];
    "batteries.forward|forwardTo" = [
      "forwardToLegacy"
      "batteriesForward"
    ];
  };

  # The canonical §2.2 row list (the spec's v1-construct column). compat-surface asserts `rows` covers it.
  specRows = builtins.attrNames rows;

  # The task's MANDATORY dedicated witnesses (C1) → the fixture id(s) that must exist for each.
  mandatory = {
    "den.schema custom kinds (topology + kind-attached includes)" = [ "schemaCustomKind" ];
    "policy.when non-hasAspect (plain rule-guard)" = [ "policyWhenPlain" ];
    "policy.when hasAspect (fixpoint)" = [ "policyWhenHasAspect" ];
    "each §2.4 pipe stage" = [
      "pipeDerive"
      "pipeDeliverTo"
      "pipeDeliverAs"
      "pipeSite"
      "pipeForVsTransform"
    ];
    "multi-system @system homes" = [ "homesMultiSystem" ];
    "den.default / battery compilation" = [ "denDefault" ];
  };
}
