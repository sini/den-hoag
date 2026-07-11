# SCOPE-LOCAL POLICY FIRING (board #57, ledger u3) — v1 `installPolicies` parity. v1 fires a policy ONLY
# where it is REGISTERED — scope-local, via an INCLUDE (den nix/lib/aspects/fx/policy/default.nix:82-113
# `installPolicies` "Policies fire where they're registered — scope-local only"), and the subtree fan-out
# filters by `requiredEntityArgs` (schema.nix:157-199): a `{host,…}` policy fires at HOST scopes, NOT user
# scopes (which inherit host context but are a different kind); a `{self,…}` policy fires ONCE at its own
# scope. The pre-fix shim diverged (ledger u3): every `den.policies.<name>` compiled TWICE — a fleet-wide
# GLOBAL (fires wherever its formals match ANY node) AND per-include kind arms — so an include-referenced
# policy fired at every coord-matching node, and a coord shared by a descendant kind (a user cell carries
# its host's `host` coord) made an include arm OVER-fire at the descendant. The live consequence: the
# corpus `env-to-hosts` (`{environment,…}`, a `den.schema.environment.includes` policy) fired at HOST nodes
# once `environment` was enriched there → hit the stubbed resolve fan-out. The two-part fix:
#   PART 1 — an include-referenced policy's fleet-wide GLOBAL is REMOVED; it fires via its include ARM only.
#   PART 2 — `__firesAtKinds` on each include arm confines it to OWNER-KIND nodes at dispatch (compile.nix
#            stamps it; concern-policies threads it onto every compiled rule; structural.nix pre-filters).
#
# The witnesses, driven through the REAL compat compile + concern-policies + structural pipeline (the same
# path the corpus takes), over hand-built roots (the b1-single-writer / compat-fleet-context convention):
#   (1) an `{environment,…}` environment-include (the env-to-hosts shape, a throwing fan-out body) does NOT
#       fire at a HOST node that CARRIES an enriched `environment` binding → the node resolves CLEAN;
#   (2) the SAME policy DOES fire at an environment-KIND node (the throw surfaces) — owner-kind, not never;
#   (3) a host-include SITE-MARK policy fires at the host but NOT at its user cell (the over-fire closed);
#   (4) the synthetic fleet-context enrich (no `__firesAtKinds`) STILL fires at host root AND user cell;
#   (5) [PART 1] an include-referenced policy name has NO global rule — only its `__kindInclude` arm;
#   (6) a VALUE-CONDITIONAL include's EXPANSION sub-rules each inherit the arm's `__firesAtKinds`.
{
  denHoag,
  denCompat,
  denHoagSrc,
  ...
}:
let
  I = denHoag.internal;
  inherit (I)
    structural
    runResolve
    parseParent
    ;
  inherit (denCompat) pipe;

  # The REAL fleet-context enrich builder (single source of truth — no shape duplication).
  fleetContext = import "${denHoagSrc}/lib/compat/fleet-context.nix" {
    declare = denHoag.declare;
  };

  # ── registries the bridge shape ingests (compat-fleet-context convention) ──
  prodEnv = {
    id_hash = "env-prod";
    name = "prod";
  };
  envs = {
    prod = prodEnv;
  };
  secretsConfig = {
    masterIdentities = [ "/pub/master.pub" ];
  };

  # ── the include SHAPES (v1 policy records; the bridge coercion is applied by hand off the direct compile) ──
  # env-to-hosts shape: an `{environment,…}` fan-out whose body THROWS when applied — modelling the STUBBED
  # `den.lib.policy.resolve` fan-out (the live corpus frontier). Its probe throw is tryEval-caught → the
  # policy EXPANDS; firing it (at an environment-kind node) surfaces the throw.
  envThrowRec = {
    __isPolicy = true;
    name = "env-fanout";
    fn =
      { environment, ... }:
      throw "env-fanout: resolve fan-out stub reached (would fire at ${environment.name})";
  };
  # host-include SITE MARK: an unconditional `{host,…}` `pipe.from` collect — a per-node collection-stratum
  # site mark (the collect/broadcast census class). Fires at host scopes; must NOT over-fire at user cells.
  hostMarkRec = {
    __isPolicy = true;
    name = "host-collect";
    fn = { host, ... }: [ (pipe.from "host-peers" [ (pipe.collect (_: true)) ]) ];
  };

  # The fleet fixture: the two includes + the synthetic fleet-context enrich. No instances are needed — the
  # include ARMS are built from `ing.kindIncludes`, and the nodes are hand-built below.
  fixture = {
    policies.fleet-context-enrich = fleetContext.mkEnrichPolicy { inherit envs secretsConfig; };
    schema.environment = {
      parent = "host";
      includes = [ envThrowRec ];
    };
    schema.host.includes = [ hostMarkRec ];
  };
  compiled = denCompat.compile fixture;
  rules = I.compilePolicies compiled.policies;

  # ── hand-built roots: a host root (env-string "prod") + a user CELL under it + a synthetic ENVIRONMENT
  #    node. The host carries NO `environment` decl — the enrich BINDS it (the faithful axon-01 scenario:
  #    the env arm is confined by KIND despite `environment` being enriched at the host). ──
  hostEnt = {
    id_hash = "h1";
    name = "h1";
    environment = "prod";
  };
  userEnt = {
    id_hash = "alice";
    name = "alice";
  };
  roots = {
    "host:h1" = {
      id = "host:h1";
      type = "host";
      parent = null;
      decls = {
        host = hostEnt;
        __entry = hostEnt;
      };
    };
    "user:alice@host:h1" = {
      id = "user:alice@host:h1";
      type = "user";
      parent = "host:h1";
      decls = {
        user = userEnt;
        __entry = userEnt;
      };
    };
    # a synthetic environment-KIND node — the owner kind of the env-to-hosts include. Compat spawns none
    # (the env fan-out is stubbed), so this exists ONLY to prove the arm's gate is owner-kind, not never.
    "env:prod" = {
      id = "env:prod";
      type = "environment";
      parent = null;
      decls = {
        environment = prodEnv;
        __entry = prodEnv;
      };
    };
  };

  res = runResolve {
    inherit roots parseParent;
    equations = structural {
      policiesRules = {
        inherit (rules) enrich policy;
      };
      fleetChildren = _self: _id: { };
    };
  };
  ctxAt = id: res.eval.get id "enriched-context";
  actionsAt = id: (res.eval.get id "declarations").actions;
  collectionAt = id: (actionsAt id).collection or [ ];
  resolvesClean =
    id: (builtins.tryEval (builtins.deepSeq (res.eval.get id "declarations").actions true)).success;

  # ── (5) PART 1: an include-referenced `den.policies.<name>` has NO fleet-wide global (only its arm) ──
  pRec = {
    __isPolicy = true;
    name = "p";
    fn = _ctx: [
      {
        __policyEffect = "include";
        value = {
          name = "a";
        };
      }
    ];
  };
  w5 = denCompat.compile {
    aspects.a = { };
    policies.p = pRec; # ALSO registered under den.policies — the both-registered case
    schema.k = {
      parent = "host";
      includes = [ pRec ];
    };
    k.k1 = { };
  };

  # ── (6) a VALUE-CONDITIONAL host include (broadcast-hub-peer shape) — EXPANDS; its sub-rules inherit
  #    the arm's `__firesAtKinds`. ──
  vcHostRec = {
    __isPolicy = true;
    name = "vc-host";
    fn =
      { host, ... }:
      if (host.settings.on or false) then [ (pipe.from "c" [ (pipe.broadcast (_: true)) ]) ] else [ ];
  };
  w6 = I.compilePolicies (denCompat.compile { schema.host.includes = [ vcHostRec ]; }).policies;
  w6SubRules = builtins.filter (
    r:
    builtins.elem r.identity [
      "__kindInclude__host__policy__0#structural"
      "__kindInclude__host__policy__0#resolution"
      "__kindInclude__host__policy__0#collection"
    ]
  ) w6.policy;
in
{
  flake.tests.compat-scope-local-firing = {
    # ── (1) the env-to-hosts arm does NOT fire at a HOST node carrying an enriched `environment` ─────────
    # The host's enriched-context DOES carry `environment` (the enrich bound it), yet the `{environment}`-
    # gated env arm — confined to `[ "environment" ]` — is pre-filtered OUT at the host (kind host), so its
    # throwing body is never forced and the node resolves CLEAN. This is the live axon-01 fix in miniature.
    test-env-arm-inert-at-host-with-environment = {
      expr = {
        hostCarriesEnvironment = (ctxAt "host:h1") ? environment;
        hostResolvesClean = resolvesClean "host:h1";
        cellResolvesClean = resolvesClean "user:alice@host:h1";
      };
      expected = {
        hostCarriesEnvironment = true;
        hostResolvesClean = true;
        cellResolvesClean = true;
      };
    };

    # ── (2) the SAME arm DOES fire at an environment-KIND node (the throw surfaces) ──────────────────────
    # Owner-kind, not never-fires: at the environment node the arm passes the kind pre-filter, its
    # `{environment}` gate matches, and forcing declarations hits the fan-out throw (tryEval → false).
    test-env-arm-fires-at-environment-node = {
      expr = resolvesClean "env:prod";
      expected = false;
    };

    # ── (3) a host-include SITE MARK fires at the host but NOT at its user cell (over-fire closed) ───────
    # The `{host}`-gated collect arm — confined to `[ "host" ]` — emits its collection site mark at the
    # host; at the user cell (which INHERITS the host coord, so the bare gate would match) it is pre-
    # filtered out by kind, so the cell carries NO such collection declaration.
    test-host-mark-at-host-not-cell = {
      expr = {
        hostHasMark = builtins.length (collectionAt "host:h1") == 1;
        hostMarkChannel = (builtins.head (collectionAt "host:h1")).channel or null;
        cellHasMark = collectionAt "user:alice@host:h1" != [ ];
      };
      expected = {
        hostHasMark = true;
        hostMarkChannel = "host-peers";
        cellHasMark = false;
      };
    };

    # ── (4) the synthetic fleet-context enrich (no `__firesAtKinds`) STILL fires at host root AND cell ───
    # Unfiltered: it enriches wherever its `{host}` gate matches — the host root AND the user cell — so both
    # carry the enrich signature (`secretsConfig`). (It is gate-bounded, not kind-bounded: the environment
    # node, lacking a `host` coord, is not enriched — but that is the gate, not `__firesAtKinds`.)
    test-fleet-context-enrich-unfiltered = {
      expr = {
        hostEnriched = (ctxAt "host:h1") ? secretsConfig;
        cellEnriched = (ctxAt "user:alice@host:h1") ? secretsConfig;
        envNodeNotEnriched = !((ctxAt "env:prod") ? secretsConfig);
      };
      expected = {
        hostEnriched = true;
        cellEnriched = true;
        envNodeNotEnriched = true;
      };
    };

    # ── (5) PART 1: the both-registered policy has NO fleet-wide global — only its `__kindInclude` arm ────
    test-included-policy-no-global = {
      expr = {
        fleetWideGlobal = w5.policies ? p;
        kindArm = w5.policies ? "__kindInclude__k__policy__0";
        armFiresAtKind = w5.policies."__kindInclude__k__policy__0".__firesAtKinds;
      };
      expected = {
        fleetWideGlobal = false;
        kindArm = true;
        armFiresAtKind = [ "k" ];
      };
    };

    # ── (6) EXPANSION sub-rules inherit `__firesAtKinds` — a value-conditional include is confined too ───
    test-expansion-subrules-inherit-firesAtKinds = {
      expr = {
        subRuleCount = builtins.length w6SubRules;
        allFiresAtHost = builtins.all (r: r.__firesAtKinds == [ "host" ]) w6SubRules;
      };
      expected = {
        subRuleCount = 3;
        allFiresAtHost = true;
      };
    };
  };
}
