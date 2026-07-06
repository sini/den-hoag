# Two-stratum partition (Law A4 / r2 §B2) + Task 3's rule-evaluation surface.
#
# Task 2 half — a structural attribute may not demand a resolution attribute. The gen-resolve
# schedule (Vogt gate + stratum assert) is forced at resolve construction, so a violating grammar
# throws there; the real structural equations are all structural and schedule cleanly.
#
# Task 3 half — the compiled policy surface: (a) a policy whose declarations span two strata
# aborts naming both kinds/strata (A4); (b) a policy guarded on a channel-named arg never fires
# (channel names are never ctx keys); (c) forcing a structural attribute at a cell does NOT force
# the resolution stratum (demand-laziness) — proven by a poison policy whose edge subject throws
# only when the `declarations` (resolution) attribute is forced.
{ denHoag, ... }:
let
  I = denHoag.internal;
  inherit (I)
    runResolve
    resolve
    parseParent
    dispatch
    ;
  declare = denHoag.declare;
  inherit (I) compilePolicies;
  fx = import ./_fixtures/fleet.nix;

  roots = {
    "r:x" = {
      id = "r:x";
      type = "r";
      parent = null;
      decls = {
        __entry = { };
      };
    };
  };
  buildWith = equations: runResolve { inherit roots equations parseParent; };

  # a lone structural attribute schedules fine.
  goodEqs = {
    a = resolve.attr {
      name = "a";
      kind = "synthesized";
      stratum = "structural";
      readsAttrs = [ ];
      compute = _self: _id: 1;
    };
  };

  # a structural attribute that reads a resolution attribute violates the partition.
  badEqs = {
    res = resolve.attr {
      name = "res";
      kind = "synthesized";
      stratum = "resolution";
      readsAttrs = [ ];
      compute = _self: _id: 1;
    };
    bad = resolve.attr {
      name = "bad";
      kind = "synthesized";
      stratum = "structural";
      readsAttrs = [ "res" ];
      compute = self: id: self.get id "res";
    };
  };

  # ── Task 3 — real entries from a policy-free den.
  den = (denHoag.mkDen fx.base).den;
  H = den.registries.host.axon;
  U = den.registries.user.alice;

  # (a) a policy mixing resolution (edge) + structural (member) aborts at compile-time probe.
  mixed = compilePolicies {
    bad = _ctx: [
      (declare.edge H)
      (declare.member {
        user = U;
        host = H;
      })
    ];
  };

  # (b) a policy guarded on a channel-named arg. It reaches the `policy` feed (its edge is a
  # resolution declaration) but fires only when its guard key is a ctx key — which a channel
  # name never is.
  chan = compilePolicies { needsChan = { someChannel }: [ (declare.edge H) ]; };
  firedAt =
    ctx:
    (dispatch.dispatch {
      rules = chan.policy;
      id = "n";
      context = ctx;
      match = dispatch.fromFunctionMatch;
      classify = declare.stratumOf;
      phaseOrder = declare.strata;
    }).actions;

  # (c) demand-laziness — a poison policy edges a sentinel entry whose id_hash throws. Forcing the
  # structural stratum (enriched-context) at a cell must stay clean; forcing the resolution
  # stratum (declarations) must hit the poison.
  poisonEntry = {
    id_hash = throw "b2c: resolution stratum forced";
    name = "poison";
  };
  poisonMod = {
    config.den.policies.poison = _ctx: [ (declare.edge poisonEntry) ];
  };
  denP = (denHoag.mkDen (fx.base ++ [ poisonMod ])).den;
  getP = denP.structural.eval.get;
  cellId = "user:alice@host:axon";

  # (d) §B3 positive path — linked-context reaches the resolution stratum but not the structural
  # one. At host:axon: a structural `link` to the env:prod root, a resolution policy that captures
  # the linked kind's context (ctx.env → configure.set.seen), and a structural policy guarded on
  # the same key (it must NOT fire, since the structural phase precedes linked-context injection).
  b3Mod =
    { config, ... }:
    {
      config.den.policies = {
        linkEnv = _ctx: [ (declare.link { target = config.den.env.prod; }) ];
        captureEnv =
          { env, ... }:
          [
            (declare.configure {
              of = config.den.host.axon;
              set = {
                seen = env;
              };
            })
          ];
        structSeesEnv = { env, ... }: [ (declare.emit { marker = "struct-saw-env"; }) ];
      };
    };
  denB3 = (denHoag.mkDen (fx.base ++ [ b3Mod ])).den;
  getB3 = denB3.structural.eval.get;
  axonDecls = getB3 "host:axon" "declarations";
  axonResolution = axonDecls.actions.resolution or [ ];
  axonStructural = axonDecls.actions.structural or [ ];
  captured = (builtins.head (builtins.filter (a: a.__action == "configure") axonResolution)).set.seen;
in
{
  flake.tests.b2-two-stratum = {
    # the real Task 2 structural stratum schedules without a stratum/circularity throw.
    test-real-structural-schedules = {
      expr = (builtins.tryEval (denHoag.mkDen [ ]).den.structural.schedule).success;
      expected = true;
    };

    # a purely structural grammar schedules.
    test-structural-only-ok = {
      expr = (builtins.tryEval (buildWith goodEqs).schedule).success;
      expected = true;
    };

    # A4 — a structural attr demanding a resolution attr aborts at schedule time.
    test-structural-demands-resolution-aborts = {
      expr = (builtins.tryEval (buildWith badEqs).schedule).success;
      expected = false;
    };

    # (a) — A4 declaration-stratum separation: a two-stratum policy aborts (naming edge + member).
    test-mixed-stratum-aborts = {
      expr = (builtins.tryEval (builtins.length mixed.policy)).success;
      expected = false;
    };

    # (b) — a channel-named guard is never satisfied (no ctx key), so the policy never fires…
    test-channel-arg-never-fires = {
      expr = (firedAt { host = H; }).resolution or [ ] == [ ];
      expected = true;
    };
    # …but the SAME rule fires once its guard key IS present, proving the guard is the only gate.
    test-channel-arg-fires-when-present = {
      expr = builtins.length ((firedAt { someChannel = H; }).resolution or [ ]);
      expected = 1;
    };

    # (c) — forcing the structural stratum at a cell stays clean (resolution not demanded)…
    test-structural-stratum-forces-clean = {
      expr = (builtins.tryEval (builtins.deepSeq (getP cellId "enriched-context") true)).success;
      expected = true;
    };
    # …while forcing the resolution stratum hits the poison, so the two are genuinely distinct.
    test-resolution-stratum-poisoned = {
      expr = (builtins.tryEval (builtins.deepSeq (getP cellId "declarations") true)).success;
      expected = false;
    };

    # (d) — §B3: the resolution declaration received the link target's enriched-context under the
    # target's kind name (`env`), i.e. linked-context reached the resolution stratum.
    test-b3-linked-context-reaches-resolution = {
      expr = captured.env.name;
      expected = "prod";
    };
    # …and the structural stratum was blind to it — the `env`-guarded structural policy never
    # fired, so no `emit` declaration is present (structural saw `ctx` alone).
    test-b3-structural-blind-to-linked = {
      expr = builtins.filter (a: a.__action == "emit") axonStructural == [ ];
      expected = true;
    };
  };
}
