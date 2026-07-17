# Task 8 (A8) — the demand channel + gen-demand resolution → gen-edge constructors. Exercises the
# k8s-style cascade (`database` desugars into `secret` + `connect`) end to end over a real fleet:
#
#   cascade / termination — a downward-only kind DAG (database `below` secret+connect) quiesces in
#     maxDepth+1 strata; trace.demands lists every instance in stratum-major order.
#   static ctx only — resolvers receive their demand's own fields plus the STATIC `den.demandContext`
#     verbatim, never resolved graph state (verified by echoing the ctx key set into a resource).
#   order significance — the demand channel's pinned order (A12 producer tie-break at a shared
#     position; sorted node id across the fleet) IS resolveAll's intake, so trace.demands is
#     BYTE-IDENTICAL when the order-significant `den.membership` list is permuted.
#   toEdges — resources become provider-target (output-sink) edges, wiring becomes consumer-target
#     (subject-root) edges; both are inert gen-edge records (Task 9 materializes them).
#   registration — an upward/cyclic `below` aborts at kind registration (downward-only DAG).
{ denHoag, ... }:
let
  declare = denHoag.declare;
  # gen-demand's demand constructor — a kind resolver emits its sub-demands with it (the root demands
  # come from `declare.demand` policies; sub-demands are emitted inside a kind's `resolve`).
  D = denHoag.internal.demand;

  fleetBase = [
    {
      config.den.schema = {
        env.parent = null;
        host.parent = "env";
      };
    }
    {
      config.den = {
        env.prod = { };
        host.axon = { };
      };
    }
    (
      { config, ... }:
      {
        config.den.membership = [
          {
            coords = {
              env = config.den.env.prod;
              host = config.den.host.axon;
            };
          }
        ];
      }
    )
  ];

  # ── the k8s cascade kinds ────────────────────────────────────────────────────────────────────────
  # database (depth 1) desugars into secret + connect (depth 0). secret produces a provider resource
  # (and echoes the static ctx it saw); connect produces consumer wiring. Resource keys are
  # subject-namespaced (group-unique, no cross-group collision).
  cascadeKinds = {
    database = {
      below = [
        "secret"
        "connect"
      ];
      resolve = d: _ctx: {
        resources = {
          "db/${d.subject.id_hash}" = {
            engine = "postgres";
          };
        };
        demands = [
          (D.demand {
            kind = "secret";
            subject = d.subject;
          })
          (D.demand {
            kind = "connect";
            subject = d.subject;
          })
        ];
      };
    };
    secret = {
      resolve = d: ctx: {
        resources = {
          "secret/${d.subject.id_hash}" = {
            seed = ctx.secretSeed or "«no-ctx»";
            # the resolver's whole view of ctx — asserted to be EXACTLY the static demandContext
            # (proves no resolved graph state is threaded in).
            ctxKeys = builtins.attrNames ctx;
          };
        };
      };
    };
    connect = {
      resolve = d: _ctx: {
        wiring = {
          endpoint = "svc/${d.subject.id_hash}";
        };
      };
    };
  };

  cascadeMod =
    { config, ... }:
    {
      config.den.demandKinds = cascadeKinds;
      config.den.demandContext = {
        secretSeed = "from-ctx";
      };
      # one root database demand, emitted by a policy at the host node (subject = the firing host).
      config.den.policies.provisionDb =
        { host, ... }:
        [
          (declare.demand {
            kind = "database";
            subject = host;
          })
        ];
    };
  denCascade = (denHoag.mkDen (fleetBase ++ [ cascadeMod ])).den;
  res = denCascade.demandResolution;
  edges = denCascade.demandEdges;

  secretVal = builtins.head (builtins.attrValues res.resources.secret);
  providerEdges = builtins.filter (e: e.target ? output) edges;
  consumerEdges = builtins.filter (e: e.target ? root) edges;

  # ── same-position tie-break (A12): two producers at ONE node ─────────────────────────────────────
  # provisionA and provisionB each emit a database demand for a DISTINCT subject at the one host cell.
  # Two contributions land at ONE position, so the demand channel pins their order by PRODUCER IDENTITY
  # (the emitting policy) — provisionA before provisionB — not by subject or attrset iteration.
  twoProducers =
    { config, ... }:
    {
      config.den.demandKinds = cascadeKinds;
      config.den.policies = {
        provisionA =
          { host, ... }:
          [
            (declare.demand {
              kind = "database";
              subject = config.den.host.axon;
            })
          ];
        provisionB =
          { host, ... }:
          [
            (declare.demand {
              kind = "database";
              subject = config.den.env.prod;
            })
          ];
      };
    };
  rootSubjects = trace: map (d: d.subject.rendered) (builtins.filter (d: d.stratum == 1) trace);
  twoProducersTrace =
    (denHoag.mkDen (fleetBase ++ [ twoProducers ])).den.demandResolution.trace.demands;

  # ── genuine order-significant permutation absorbed by the fleet pin ───────────────────────────────
  # Two host cells (axon, blade) each carry a database demand from one policy. `den.membership` is an
  # ORDER-SIGNIFICANT list; permuting it must not change the resolved demand order, because the fleet
  # gather keys demands by (sorted) node id, not by membership-declaration order.
  permBase = [
    {
      config.den.schema = {
        env.parent = null;
        host.parent = "env";
      };
    }
    {
      config.den = {
        env.prod = { };
        host.axon = { };
        host.blade = { };
      };
    }
    {
      config.den.demandKinds = cascadeKinds;
      config.den.policies.provision =
        { host, ... }:
        [
          (declare.demand {
            kind = "database";
            subject = host;
          })
        ];
    }
  ];
  permMembership =
    order:
    { config, ... }:
    let
      axon = {
        coords = {
          env = config.den.env.prod;
          host = config.den.host.axon;
        };
      };
      blade = {
        coords = {
          env = config.den.env.prod;
          host = config.den.host.blade;
        };
      };
    in
    {
      config.den.membership =
        if order then
          [
            axon
            blade
          ]
        else
          [
            blade
            axon
          ];
    };
  traceOfPerm =
    order: (denHoag.mkDen (permBase ++ [ (permMembership order) ])).den.demandResolution.trace.demands;
  tracePermAB = traceOfPerm true;
  tracePermBA = traceOfPerm false;

  # ── registration: an upward/cyclic `below` aborts ────────────────────────────────────────────────
  cyclicMod = {
    config.den.demandKinds = {
      a = {
        below = [ "b" ];
        resolve = _d: _ctx: { };
      };
      b = {
        below = [ "a" ];
        resolve = _d: _ctx: { };
      };
    };
  };
  denCyclic = denHoag.mkDen (fleetBase ++ [ cyclicMod ]);
in
{
  flake.tests.demand = {
    # ── cascade / termination (downward-only DAG) ──
    # database desugars into secret + connect ⇒ three resolved instances, quiescent.
    test-cascade-terminates = {
      expr = builtins.length res.trace.demands;
      expected = 3;
    };
    # trace.demands is stratum-major descending: database (stratum 1) before its stratum-0 children.
    test-cascade-kind-order = {
      expr = map (d: d.kind) res.trace.demands;
      expected = [
        "database"
        "secret"
        "connect"
      ];
    };
    # database + secret are the provider (resource) kinds; connect contributes no resource (its kind
    # is present in `resources` with an empty map — gen-demand keys every resolved kind).
    test-resource-kinds = {
      expr = builtins.sort (a: b: a < b) (
        builtins.filter (k: res.resources.${k} != { }) (builtins.attrNames res.resources)
      );
      expected = [
        "database"
        "secret"
      ];
    };
    # connect contributes consumer wiring for exactly the one subject.
    test-wiring-subject-count = {
      expr = builtins.length (builtins.attrNames res.wiring);
      expected = 1;
    };
    test-wiring-kind = {
      expr = builtins.attrNames (builtins.head (builtins.attrValues res.wiring)).byKind;
      expected = [ "connect" ];
    };

    # ── static ctx only (never resolved state) ──
    # the secret resolver saw the static demandContext seed…
    test-static-ctx-seed = {
      expr = secretVal.seed;
      expected = "from-ctx";
    };
    # …and NOTHING else: ctx is exactly `den.demandContext`, no resolved graph state injected.
    test-static-ctx-only = {
      expr = secretVal.ctxKeys;
      expected = [ "secretSeed" ];
    };

    # ── toEdges: provider + consumer edges (inert gen-edge records) ──
    # two provider-target edges (database db-key + secret secret-key), each a terminal output sink.
    test-provider-edge-count = {
      expr = builtins.length providerEdges;
      expected = 2;
    };
    test-provider-edge-output-arm = {
      expr = builtins.all (e: builtins.head e.target.output == "demands") providerEdges;
      expected = true;
    };
    # one consumer-target edge onto the subject's instantiation root (wiring class).
    test-consumer-edge-count = {
      expr = builtins.length consumerEdges;
      expected = 1;
    };
    test-consumer-edge-class = {
      expr = (builtins.head consumerEdges).target.class;
      expected = "wiring";
    };
    # every edge sources a direct value (inert; Task 9 materializes).
    test-edges-are-value-sourced = {
      expr = builtins.all (e: e.source ? value) edges;
      expected = true;
    };
    # DEMAND RETIRES BY EXTENSION (spec §2.2): both toEdges arms stamp the `demand` edge kind — the first
    # live labeled kind. Every demand edge (provider + consumer) carries `kind = "demand"`, so its trace
    # key gains the K component; an un-stamped (legacy) edge is unchanged (pinned in edge-substrate).
    test-edges-stamp-demand-kind = {
      expr = builtins.all (e: e.kind == "demand") edges;
      expected = true;
    };
    # COMPOSITION: the demand edges fold into the fleet edge set (`edgesForRoot` = default-fold ++ fleet
    # demand edges), so the frozen parity-oracle trace `den.graph.trace <root>` carries the stamped `kind`
    # — the K component surfaces end-to-end, not only on the raw records.
    test-graph-trace-carries-demand-kind = {
      expr =
        let
          aRoot = builtins.head (builtins.attrNames denCascade.scopeRoots);
          traceEntries = denCascade.graph.trace aRoot;
        in
        builtins.any (e: (e.kind or null) == "demand") traceEntries;
      expected = true;
    };

    # ── same-position tie-break (A12): pinned by producer identity ──
    # the two root (stratum-1) subjects come out provisionA (axon) before provisionB (prod), pinned by
    # the emitting policy — the demand-channel producer tie-break at the shared position.
    test-order-canonical-winner = {
      expr = rootSubjects twoProducersTrace;
      expected = [
        "axon"
        "prod"
      ];
    };

    # ── genuine permutation: order-significant membership list absorbed by the fleet pin ──
    # permuting `den.membership` (an order-significant list) leaves trace.demands byte-identical: the
    # fleet gather keys demands by node id, not by membership-declaration order.
    test-order-pinned-under-permutation = {
      expr = tracePermAB == tracePermBA;
      expected = true;
    };
    # and the canonical fleet order is axon before blade (sorted node id), independent of that list.
    test-fleet-order-canonical = {
      expr = rootSubjects tracePermAB;
      expected = [
        "axon"
        "blade"
      ];
    };

    # ── registration: cyclic (upward) `below` aborts at kind registration ──
    test-cyclic-kinds-abort = {
      expr = (builtins.tryEval denCyclic.den.demandKinds).success;
      expected = false;
    };
  };
}
