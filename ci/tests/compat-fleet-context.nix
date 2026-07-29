# FLEET-CONTEXT ENRICHMENT (ship-gate rung) — the compat twin of v1's fleet.nix scope-inheritance fan-out
# (lib/compat/fleet-context.nix; nix-config modules/den/policies/fleet.nix:20-82 @ pin 11866c16). The
# policy binds `environment`/`secretsConfig`/`fleet` into every host-bearing node's enriched-context as
# `declare.enrich`, driven through the REAL compat + concern-policies + structural pipeline (the same path
# the corpus takes). Two arms:
#   (A) the ENRICH MECHANISM (structural `buildAt` over hand-built roots, the b1-single-writer convention)
#       — the compiled policy is a SINGLE-GROUP enrich; a host root + a user cell carry all three keys; the
#       default env is `"prod"`; a missing registry entry NAMED-aborts; a `{ host, secretsConfig, ... }`
#       presence-gated consumer (the agenix shape) FIRES once secretsConfig is bound (was inert).
#   (B) the COLLECTION INTEGRATION (native `denHoag.mkDen`, the parametric-emit convention) — with the
#       enrich binding `environment`, a `{ environment, host, ... }` channel emit (the k3s shape) resolves
#       to a SET at the emitting node (U9.1 resolveParametric), while an `{ accessGroups, ... }` emit (the
#       still-unbound key, deferred #49) DROPS inert via the gate miss (no accessGroups bound; the v1
#       ride-raw is dissolved).
{
  lib,
  denHoag,
  denCompat,
  denHoagSrc,
  ...
}:
let
  registry = import ./_lib/instance-registry.nix { inherit denHoag lib; };
  I = denHoag.internal;
  # The structural feeds arrive KIND-INDEXED (`indexPolicyFeed kinds feed` -> `kind -> [rule]`), selecting
  # on each rule's declared `selects`. An empty kind list memoises nothing, so every lookup takes the
  # index's total fallback and computes the real selection — the fixture exercises the shipped predicate
  # rather than a hand-rolled stand-in of it.
  idxFeed = I.indexPolicyFeed [ ];
  inherit (I)
    structural
    runResolve
    parseParent
    ;

  # The REAL policy builder (single source of truth — no shape duplication).
  fleetContext = import "${denHoagSrc}/lib/compat/fleet-context.nix" {
    declare = denHoag.declare;
  };

  # The registries the bridge ingests: `config.den.environments`, built by gen-schema's OWN
  # `mkInstanceRegistry` exactly as a consumer declares it, so the entries carry the identity module's
  # `name`/`id_hash` rather than hand-written stand-ins and the enrich binds what the corpus binds.
  # `config.den.secretsConfig` beside it is a declared NON-kind namespace and stays a plain attrset —
  # there is no kind to build a registry from, and inventing one would model something the corpus lacks.
  envReg = registry.mkRegistry {
    kindName = "environment";
    kind = {
      isEntity = true;
      parent = null;
      imports = [
        (_: {
          options.domain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        })
      ];
    };
    namespace = "environments";
    instances = {
      prod.domain = "example.test";
      dev = { };
    };
  };
  envs = envReg.instances;
  prodEnv = envs.prod;
  secretsConfig = {
    masterIdentities = [ "/pub/master.pub" ];
  };

  policy = fleetContext.mkEnrichPolicy { inherit envs secretsConfig; };

  # A `{ host, secretsConfig, ... }` presence-gated consumer standing in for the agenixHostAspect
  # (batteries/agenix.nix:23) — a POLICY (attr-4) emitting a detectable structural `spawn`, so it fires
  # ONLY where BOTH coords are present. Inert without the enrich (secretsConfig unbound); fires with it.
  agenixShape =
    {
      host,
      secretsConfig,
      ...
    }:
    [
      (denHoag.declare.spawn {
        classes = [ ];
        bindings = { };
      })
    ];

  # Compile a v1 policy SET through the real compat compile + concern-policies (declared codomain → feeds).
  # `selects = null` is restated on each compiled record because THIS suite's subject is the ENRICH
  # FIXPOINT — that a presence-gated consumer becomes live once `secretsConfig` is bound. These fixture
  # decl sets carry no `den.schema.<K>.includes`, so compat's own mint would correctly give every one of
  # them `selects = [ ]` (a registered-but-unincluded policy selects nothing — the defect this design
  # removes). That is the right answer to a question this suite is not asking, and it would make all three
  # rule sets equally inert and the comparison vacuous.
  rulesFor =
    policies:
    I.compilePolicies (
      builtins.mapAttrs (_: v: v // { selects = null; })
        (denCompat.compile { inherit policies; }).policies
    );

  enrichRules = rulesFor { fleet-context-enrich = policy; };
  bothRules = rulesFor {
    fleet-context-enrich = policy;
    agenix = agenixShape;
  };
  agenixOnlyRules = rulesFor { agenix = agenixShape; };

  # ── hand-built roots (the buildAt / b1-single-writer convention) ──
  hostEnt = {
    id_hash = "axon";
    name = "axon";
    environment = "prod";
  };
  hostRoot = id: ent: {
    ${id} = {
      inherit id;
      type = "host";
      parent = null;
      decls = {
        host = ent;
        __entry = ent;
      };
    };
  };
  # host root (environment = prod) + a USER CELL under it (inherits `host` from the parent, attr 1).
  userEnt = {
    id_hash = "u";
    name = "u";
  };
  cellRoots = (hostRoot "host:axon" hostEnt) // {
    "user:u@host:axon" = {
      id = "user:u@host:axon";
      type = "user";
      parent = "host:axon";
      decls = {
        user = userEnt;
        __entry = userEnt;
      };
    };
  };
  # a host with NO `environment` field → the `"prod"` default.
  noEnvRoots = hostRoot "host:h2" {
    id_hash = "h2";
    name = "h2";
  };
  # a host whose env string names a MISSING registry entry → the NAMED abort.
  badRoots = hostRoot "host:h3" {
    id_hash = "h3";
    name = "h3";
    environment = "staging";
  };

  buildAt =
    roots: rules:
    runResolve {
      inherit roots parseParent;
      equations = structural {
        policiesIndex = {
          enrich = idxFeed rules.enrich;
          policy = idxFeed rules.policy;
        };
        fleetChildren = _self: _id: { };
      };
    };
  ctxAt = res: id: res.eval.get id "enriched-context";
  structuralDeclsAt = res: id: (res.eval.get id "declarations").actions.structural or [ ];

  cellRes = buildAt cellRoots enrichRules;
  hostCtx = ctxAt cellRes "host:axon";
  cellCtx = ctxAt cellRes "user:u@host:axon";

  # ── (B) native collection integration (parametric-emit convention) ──
  denInt =
    (denHoag.mkDen [
      {
        config.den.schema = {
          host.parent = null;
        };
      }
      { config.den.host.axon = { }; }
      { config.den.contentClass.host = "nixos"; }
      # the fleet-context enrich, native (binds environment/secretsConfig/fleet at the host).
      {
        config.den.policies.bind-ctx = fleetContext.mkEnrichPolicy { inherit envs secretsConfig; };
      }
      {
        config.den.quirks = {
          k3sish = { };
          groupsish = { };
        };
      }
      (
        { config, ... }:
        {
          config.den.aspects.emit = {
            nixos.marker = "axon"; # trivial class content so the host carries a nixos body
            # the k3s shape: a `{ environment, host, ... }` emit — resolves once `environment` is bound.
            k3sish =
              {
                environment,
                host,
                ...
              }:
              {
                env = environment;
                hn = host.name;
              };
            # a `{ accessGroups, ... }` emit — the key my rung deliberately does NOT bind (deferred #49), so
            # its gate misses and it drops inert (no emission — the v1 ride-raw is dissolved).
            groupsish = { accessGroups, ... }: { g = accessGroups; };
          };
          config.den.include = [
            {
              at = config.den.host.axon;
              aspects = [ config.den.aspects.emit ];
            }
          ];
        }
      )
    ]).den;
  valsOf =
    ch:
    map (c: c.value) ((denInt.structural.eval.get "host:axon" "local-collection-data").${ch} or [ ]);
in
{
  flake.tests.compat-fleet-context = {
    # ── classification: the UNCONDITIONAL emission probes as a SINGLE-GROUP enrich (the probe edge) ──
    test-policy-classified-single-group-enrich = {
      expr = {
        enrichCount = builtins.length enrichRules.enrich;
        policyCount = builtins.length enrichRules.policy;
      };
      expected = {
        enrichCount = 1;
        policyCount = 0;
      };
    };

    # ── (1) a host root's enriched-context carries all THREE keys ──
    test-host-carries-three-keys = {
      expr = {
        environment = hostCtx ? environment;
        secretsConfig = hostCtx ? secretsConfig;
        fleet = hostCtx ? fleet;
      };
      expected = {
        environment = true;
        secretsConfig = true;
        fleet = true;
      };
    };

    # `environment` == the registry ENTITY for the host's env string.
    test-environment-is-registry-entity = {
      expr = hostCtx.environment == prodEnv;
      expected = true;
    };

    # `fleet` == v1's exact value; `secretsConfig` == the bridge-ingested namespace.
    test-fleet-and-secretsConfig-values = {
      expr = {
        fleet = hostCtx.fleet;
        secretsConfig = hostCtx.secretsConfig;
      };
      expected = {
        fleet = {
          name = "fleet";
        };
        secretsConfig = secretsConfig;
      };
    };

    # ── (1b) a host with NO `environment` field gets the `"prod"` default ──
    test-default-env-is-prod = {
      expr = (ctxAt (buildAt noEnvRoots enrichRules) "host:h2").environment == prodEnv;
      expected = true;
    };

    # ── (2) a USER CELL under a host ALSO carries them (the v1-inheritance twin) ──
    test-user-cell-carries-three-keys = {
      expr = {
        environment = cellCtx.environment == prodEnv;
        secretsConfig = cellCtx ? secretsConfig;
        fleet =
          cellCtx.fleet == {
            name = "fleet";
          };
      };
      expected = {
        environment = true;
        secretsConfig = true;
        fleet = true;
      };
    };

    # ── (3) a host whose env string names a MISSING registry entry → NAMED abort (tryEval fails) ──
    test-missing-env-named-abort = {
      expr = (builtins.tryEval (ctxAt (buildAt badRoots enrichRules) "host:h3").environment).success;
      expected = false;
    };

    # ── (4) agenix shape: a `{ host, secretsConfig, ... }` consumer FIRES once secretsConfig is bound ──
    # WITH the enrich (secretsConfig bound via the keyset-ascent fixpoint) the presence-gated policy fires.
    test-agenix-shape-fires-with-enrich = {
      expr = builtins.length (
        structuralDeclsAt (buildAt (hostRoot "host:axon" hostEnt) bothRules) "host:axon"
      );
      expected = 1;
    };
    # WITHOUT the enrich (secretsConfig never bound) the SAME policy is inert — the was-dead baseline.
    test-agenix-shape-inert-without-enrich = {
      expr = builtins.length (
        structuralDeclsAt (buildAt (hostRoot "host:axon" hostEnt) agenixOnlyRules) "host:axon"
      );
      expected = 0;
    };

    # ── (B) integration: a `{ environment, host, ... }` emit resolves to a SET (the k3s shape) ──
    test-k3s-shape-resolves-to-set = {
      expr = valsOf "k3sish";
      expected = [
        {
          env = prodEnv;
          hn = "axon";
        }
      ];
    };
    test-k3s-shape-is-data-not-lambda = {
      expr = builtins.isFunction (builtins.head (valsOf "k3sish"));
      expected = false;
    };

    # ── (B) U9.1 regression: an emit demanding a still-UNBOUND arg (`accessGroups`, deferred #49) DROPS ──
    # the gate is unsatisfied ⇒ the emit contributes nothing (gen-aspects wrapGatedFn inert miss, no ride-raw).
    test-accessGroups-emit-drops = {
      expr = valsOf "groupsish";
      expected = [ ];
    };
  };
}
