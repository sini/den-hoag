# Two-stratum partition (Law A4 / r2 §B2) + the rule-evaluation surface.
#
# The SCHEDULE half — a structural attribute may not demand a resolution attribute. The gen-resolve
# schedule (Vogt gate + stratum assert) is forced at resolve construction, so a violating grammar
# throws there; the real structural equations are all structural and schedule cleanly.
#
# The POLICY half — the compiled policy surface: (a) a policy whose declarations span two strata
# aborts naming both kinds/strata (A4); (b) a policy guarded on a channel-named arg never fires
# (channel names are never ctx keys); (c) forcing a structural attribute at a cell does NOT force
# the resolution stratum (demand-laziness) — proven by a poison policy whose edge subject throws
# only when the `declarations` (resolution) attribute is forced.
{ denHoag, ... }:
let
  inherit (denHoag) sel;
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

  # ── real entries from a policy-free den.
  den = (denHoag.mkDen fx.base).den;
  H = den.registries.host.axon;
  U = den.registries.user.alice;

  # (a) A4 declaration-stratum separation. The policy DECLARES a codomain spanning two strata
  # (`edge` is resolution, `member` is structural), which is refused AT REGISTRATION — one rule, one
  # stratum is gen-dispatch's core invariant, discharged through `deriveGroup` for every rule.
  mixedPolicies = {
    bad = {
      emits = [
        "edge"
        "member"
      ];
      selects = sel.star;
      fn = _ctx: [
        (declare.edge H)
        (declare.member {
          user = U;
          host = H;
        })
      ];
    };
  };
  # The validator as a VALUE: `null` when clean, else the FIRST named message. Asserting its TEXT is the
  # whole reason it returns rather than throws — Nix cannot recover a throw's text from a caught eval.
  mixedMessage = I.policyMessage mixedPolicies;

  # (b) a policy guarded on a channel-named arg. It reaches the `policy` feed (its edge is a
  # resolution declaration) but fires only when its guard key is a ctx key — which a channel
  # name never is.
  chan = compilePolicies {
    needsChan = {
      emits = [ "edge" ];
      selects = sel.star;
      fn = { someChannel }: [ (declare.edge H) ];
    };
  };
  firedAt =
    ctx:
    (dispatch.dispatch {
      rules = chan.policy;
      id = "n";
      context = ctx;
      match = dispatch.fromFunctionMatch;
      classify = declare.stratumOf;
      groupOrder = declare.strata;
    }).actions;

  # (c) demand-laziness — a poison policy edges a sentinel entry whose id_hash throws. Forcing the
  # structural stratum (enriched-context) at a cell must stay clean; forcing the resolution
  # stratum (declarations) must hit the poison.
  poisonEntry = {
    id_hash = throw "b2c: resolution stratum forced";
    name = "poison";
  };
  poisonMod = {
    config.den.policies.poison = {
      emits = [ "edge" ];
      selects = sel.star;
      fn = _ctx: [ (declare.edge poisonEntry) ];
    };
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
        linkEnv = {
          emits = [ "link" ];
          selects = sel.star;
          fn = _ctx: [ (declare.link { target = config.den.env.prod; }) ];
        };
        captureEnv = {
          emits = [ "configure" ];
          selects = sel.star;
          fn =
            { env, ... }:
            [
              (declare.configure {
                of = config.den.host.axon;
                set = {
                  seen = env;
                };
              })
            ];
        };
        structSeesEnv = {
          emits = [ "emit" ];
          selects = sel.star;
          fn = { env, ... }: [ (declare.emit { marker = "struct-saw-env"; }) ];
        };
      };
    };
  denB3 = (denHoag.mkDen (fx.base ++ [ b3Mod ])).den;
  getB3 = denB3.structural.eval.get;
  axonDecls = getB3 "host:axon" "declarations";
  axonResolution = axonDecls.actions.resolution or [ ];
  axonStructural = axonDecls.actions.structural or [ ];
  captured = (builtins.head (builtins.filter (a: a.__action == "configure") axonResolution)).set.seen;

  # (e) §B3 shadow direction — `combine = linkedFrom // ctx` means a node whose enriched-context
  # ALREADY binds the linked kind's key keeps its OWN value; the link only ADDS a not-yet-present
  # key. Here an enrich policy seeds `env = "OWN"` at host:axon, so the link to env:prod does NOT
  # overwrite it — the captured `env` is the own value, not the target's context.
  shadowMod =
    { config, ... }:
    {
      config.den.policies = {
        seedEnv = {
          emits = [ "enrich" ];
          selects = sel.star;
          fn = _ctx: [
            (declare.enrich {
              key = "env";
              value = "OWN";
            })
          ];
        };
        linkEnv = {
          emits = [ "link" ];
          selects = sel.star;
          fn = _ctx: [ (declare.link { target = config.den.env.prod; }) ];
        };
        captureEnv = {
          emits = [ "configure" ];
          selects = sel.star;
          fn =
            { env, ... }:
            [
              (declare.configure {
                of = config.den.host.axon;
                set = {
                  seen = env;
                };
              })
            ];
        };
      };
    };
  denShadow = (denHoag.mkDen (fx.base ++ [ shadowMod ])).den;
  shadowResolution =
    (denShadow.structural.eval.get "host:axon" "declarations").actions.resolution or [ ];
  capturedShadow =
    (builtins.head (builtins.filter (a: a.__action == "configure") shadowResolution)).set.seen;

  # (f) A4 strip regression — the generic binding context must not leak the machinery keys the
  # inherited-context `extract` strips (structural.nix attribute 1).
  #
  # RE-ARMED. This guarded `__containment`, the cell's coordinate-root visibility aid; the
  # coordinate-payload cutover deleted that key from the cell mint outright, so the assertion survived
  # as one nothing could violate. The strip list now holds exactly two keys, and only one of them can
  # be on a den-hoag node's `decls`: `__edges` is gen-scope's OWN reserved key, written by its
  # `buildNodes`, which den-hoag never calls — it mints its own nodes (`build-roots.nix`, `fleet.nix`),
  # so nothing puts `__edges` there. `suppressedPolicies` IS written: `default.nix` folds the staged
  # pre-pass' per-root suppression set onto that root's `decls`, and it must stay out of the generic
  # context because it rides its OWN inherited carrier (`suppressed-policies`, attribute 1s) and is
  # re-injected at the dispatch alone. So this is the same invariant on the only key that can still
  # break it, and the control below proves the key is really there to be stripped.
  suppressMod = {
    config.den.policies = {
      # the suppression TARGET — a declared policy for the suppressor to name.
      quiet = {
        emits = [ ];
        selects = sel.star;
        fn = _ctx: [ ];
      };
      # the exclude family (`group == "structural"` and `emits` ∋ `suppress`, concern-policies.nix).
      # Its gate is the `host` binding, so it fires at every host root and the pre-pass records a
      # suppression there.
      hush = {
        emits = [ "suppress" ];
        selects = sel.star;
        suppresses = [ "quiet" ];
        fn =
          { host, ... }:
          builtins.seq host [ (declare.suppress { name = "quiet"; }) ];
      };
    };
  };
  denSuppress = (denHoag.mkDen (fx.base ++ [ suppressMod ])).den;
  suppressRootDecls = builtins.attrNames denSuppress.scopeRoots."host:axon".decls;
  cellEnriched = denSuppress.structural.eval.get "user:alice@host:axon" "enriched-context";
in
{
  flake.tests.b2-two-stratum = {
    # the real structural stratum schedules without a stratum/circularity throw.
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

    # (a) — A4 declaration-stratum separation. The predicate DISCRIMINATES on the rejection's identity:
    # a bare `tryEval …success == false` goes green for ANY abort, including ones from three migrations
    # hence, so it would keep reporting green while testing something else entirely. Asserting the named
    # message pins THIS law, and asserting the compile aborts too pins that the message is not merely
    # advisory.
    test-mixed-stratum-aborts = {
      expr = {
        named = builtins.match ".*emits kinds spanning strata.*" mixedMessage != null;
        namesBothStrata =
          builtins.match ".*resolution.*" mixedMessage != null
          && builtins.match ".*structural.*" mixedMessage != null;
        compileAborts = (builtins.tryEval (builtins.length (compilePolicies mixedPolicies).policy)).success;
      };
      expected = {
        named = true;
        namesBothStrata = true;
        compileAborts = false;
      };
    };
    # The validator's negative control, in the SAME run: a single-stratum codomain is clean, so the
    # message above discriminates on CONTENT rather than on any policy being present.
    test-single-stratum-message-clean = {
      expr = I.policyMessage {
        fine = {
          emits = [ "edge" ];
          selects = sel.star;
          fn = _ctx: [ (declare.edge H) ];
        };
      };
      expected = null;
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

    # (e) — §B3 shadow direction: the node's own `env` binding shadows the linked target's context.
    test-b3-own-binding-shadows-link = {
      expr = capturedShadow;
      expected = "OWN";
    };

    # (f) — the A4 strip holds. CONTROL first: the emitting root's decls genuinely carry the key, so
    # the assertion below has something to strip…
    test-suppression-lands-on-root-decls = {
      expr = builtins.elem "suppressedPolicies" suppressRootDecls;
      expected = true;
    };
    # …and the cell's enriched-context does not carry it — the strip is what makes the difference.
    test-enriched-context-no-suppressed-policies = {
      expr = cellEnriched ? suppressedPolicies;
      expected = false;
    };
  };
}
