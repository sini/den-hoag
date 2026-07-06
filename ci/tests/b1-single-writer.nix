# Task 2 — B1 single-writer enrichment (Law A3) + the cross-enrichment convergence of the
# `gen-scope.circular ∘ gen-dispatch.dispatchStep` enrich fixpoint. Drives the REAL structural
# equations over a hand-built root, with enrich rules supplied directly (policy compilation is
# Task 3); no fleet needed, so `fleetChildren` spawns nothing.
{ denHoag, ... }:
let
  I = denHoag.internal;
  inherit (I)
    structural
    runResolve
    parseParent
    effects
    dispatch
    ;

  # one host root carrying a `seed` binding; inherited-context = its own decls.
  roots = {
    "host:h" = {
      id = "host:h";
      type = "host";
      parent = null;
      decls = {
        seed = true;
        __entry = { };
      };
    };
  };
  noChildren = _self: _id: { };

  enrichRule =
    {
      identity,
      condition,
      key,
      value,
    }:
    dispatch.mkRule {
      inherit identity condition;
      phase = "enrich";
      produce = _id: _ctx: [
        {
          __phase = "enrich";
          inherit key value;
          __policy = identity;
        }
      ];
    };

  build =
    enrichRules:
    runResolve {
      inherit roots parseParent;
      equations = structural {
        policiesRules = {
          enrich = enrichRules;
          effects = [ ];
        };
        fleetChildren = noChildren;
      };
    };
  ctxOf = res: res.eval.get "host:h" "enriched-context";
  base = (build [ ]).eval.get "host:h" "inherited-context"; # { seed; __entry; }

  # (1) a single writer resolves — its key lands in enriched-context.
  single = build [
    (enrichRule {
      identity = "setFoo";
      condition = { };
      key = "foo";
      value = 42;
    })
  ];

  # (2) two policies writing the SAME key (same pass) → B1 abort.
  dup = build [
    (enrichRule {
      identity = "A";
      condition = { };
      key = "dup";
      value = 1;
    })
    (enrichRule {
      identity = "B";
      condition = { };
      key = "dup";
      value = 2;
    })
  ];

  # (3) cross-enrichment: setB's guard needs setA's key, so it can only fire on a LATER pass.
  crossRules = [
    (enrichRule {
      identity = "setA";
      condition = { };
      key = "aKey";
      value = 1;
    })
    (enrichRule {
      identity = "setB";
      condition = {
        aKey = false;
      };
      key = "bKey";
      value = 2;
    })
  ];
  crossCtx = ctxOf (build crossRules);

  # A SINGLE dispatch pass over the base context: setB cannot fire (aKey absent yet). Proves
  # the fixpoint genuinely iterates >1 pass rather than resolving cross-enrichment one-shot.
  oneShot = dispatch.dispatch {
    rules = crossRules;
    id = "host:h";
    context = base;
    match = dispatch.fromFunctionMatch;
    classify = effects.classify;
    phaseOrder = [ "enrich" ];
    extract = acts: builtins.foldl' (acc: e: acc // { ${e.key} = e.value; }) { } (acts.enrich or [ ]);
    combine = ctx: delta: ctx // delta;
  };
in
{
  flake.tests.b1-single-writer = {
    # A3 — single writer resolves.
    test-single-writer-resolves = {
      expr = (ctxOf single) ? foo && (ctxOf single).foo == 42;
      expected = true;
    };

    # A3 — duplicate key across two policies aborts at eval.
    test-duplicate-key-aborts = {
      expr = (builtins.tryEval (ctxOf dup)).success;
      expected = false;
    };

    # A3 — cross-enrichment converges: both A's and B's keys appear in enriched-context.
    test-cross-enrichment-converges = {
      expr = (crossCtx ? aKey) && (crossCtx ? bKey);
      expected = true;
    };

    # A single dispatch pass has aKey but NOT bKey — the loop must iterate for bKey to appear.
    test-single-pass-lacks-bkey = {
      expr = (oneShot.context ? aKey) && !(oneShot.context ? bKey);
      expected = true;
    };
  };
}
