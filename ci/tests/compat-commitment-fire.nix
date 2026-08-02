# THE COMMITMENT FIRE — the throwing twin, its attribution probe, and the two ceilings it does not close.
#
# A compose commitment is read ONCE, at DEFINITION time, where no node exists. The shim therefore fires a
# commitment-declaring v1 body against a sentinel whose every coordinate field is bound to a NAMED THROW
# (`policy-recover.nix` `commitmentSentinel`), so a body reaching for a per-node value hits a funnel rather
# than a hole — the shipped VALUE sentinel would hand it a constant and let the wrong value ride to every
# node in silence.
#
# Nothing here is reachable from a body whose gate binds no coordinate: `recoverCommitments` binds the twin
# through `genAttrs (attrNames gate)`, so a `_ctx:` body forces the twin at no key and every arm below
# would pass vacuously. EVERY policy in this file destructures at least one formal, which is what puts the
# twin in the evaluation at all.
#
# THE ARMS COME IN PAIRS, and the pairing is the measurement:
#
#   • A1 — the TIMING pair. A deriving stage that CAPTURES a coordinate does not fail at the fire: Law C2
#     builds the op DAG without applying the stage closure, and `deepSeq` does not enter a function body.
#     The fire SUCCEEDS and the abort arrives later, when gen-pipe applies the stage. An arm asserting an
#     abort at the FIRING would pass for the wrong reason and mask exactly that timing, so the two halves
#     are two arms over the same policy.
#   • A3 — the ATTRIBUTION pair. A REQUIRED coordinate read by field is named; a DEFAULTED one cannot be,
#     because the per-coordinate probe ranges over `requiredCoordsOf` in both positions, and the message
#     falls to its documented candidate-set fallback instead of degrading to silence.
#   • A3's two CEILINGS, each pinned open rather than claimed closed: a `ctx@{ … }` alias read and a
#     coordinate consumed BY TYPE both fail UNCATCHABLY — `tryEval` never returns, so no den-compat
#     diagnostic is produced at all. Their discriminating partner is A3 itself: the bodies differ in how
#     the coordinate is consumed and return opposite verdicts on catchability.
#   • A6 — the FIELD-SET pair, plus its wiring control. The twin's key set is the WIRING's, not a literal:
#     `settings` is threaded by the bridge and by nothing else. So the same body aborts where `settings` is
#     in the set and takes its default branch silently where it is not, and a fixture that did not say
#     which wiring it runs on would be asserting a mechanism that holds on one of the two surfaces it might
#     run on. All three A6 arms name their wiring in the fleet they build.
#
# ★ EVERY EXCLUSION HERE IS PROVED LIVE BY EXHIBITION, not by assertion. `expectedError.msg` is matched as
# an ECMAScript regular expression by an unanchored `regex_search`, so a negative lookahead over the whole
# message is expressible — and an exclusion that could never have matched is a green that measures nothing.
# Re-pointing each lookahead at text the SAME message does carry reddens exactly its own arm and no other:
# four exclusions, four kills, the other seven arms green in the same run.
#
# WIRING, stated once: the `_probeSentinelFields.settings` key IS the bridge's own reserved channel
# (`bridge.nix` threads it; `flake-module.nix` `sentinelFor` merges it onto `probe-sentinel.nix`'s
# constants), so a raw tree carrying it compiles through `compileFull` with the SIX-key sentinel a bridged
# consumer gets. A tree omitting it gets the five-key direct one. Both are built here, and the difference
# between them is the A6 control's whole content.
{ denCompat, ... }:
let
  p = denCompat.pipe;

  # ── the fleet, in two wirings ────────────────────────────────────────────────────────────────────────
  # One nixos host, one registered channel `feat` with an emitting aspect, so a compiled commitment has a
  # real base channel to root on and a real node to be forced at.
  base = policies: {
    inherit policies;
    hosts.x86_64-linux.igloo = {
      class = "nixos";
    };
    quirks.feat = { };
    aspects.seed.feat = [ "hello" ];
    aspects.hostc.nixos.networking.hostName = "igloo";
    schema.host.includes = [
      "seed"
      "hostc"
    ];
  };
  # BRIDGED — `settings` present, materialized at its own defaults (an override-free host, so every leaf
  # is its real default). `isHub` is written `false` deliberately: A6's mechanism is that the value
  # RESOLVES to a genuine non-matching value, not that the field is missing.
  bridgedV1 =
    policies:
    base policies
    // {
      _probeSentinelFields.settings.isHub = false;
    };
  # DIRECT — no bridge, so `settings` is outside the twin's key set (the documented, self-announcing
  # ceiling), which is the A6 control's input.
  directV1 = base;

  compiledB = policies: (denCompat.compileFull (bridgedV1 policies)).policies;
  compiledD = policies: (denCompat.compileFull (directV1 policies)).policies;

  # the per-node binding surface, forced — where a captured stage closure is finally applied.
  bindingsOf =
    policies:
    (denCompat.mkDen [ { config.den = base policies; } ])
    .den.output.systems.nixos."host:igloo".bindings;

  optionals = c: xs: if c then xs else [ ];
  bothKinds = [
    "pipeCommit"
    "pipeMark"
  ];

  # ── A1 — a deriving stage CAPTURING a per-node coordinate ────────────────────────────────────────────
  # The stage closure interpolates `host.class`. `stageOp`'s transform arm stores `f = stage.fn` UNAPPLIED,
  # so the fire never forces it.
  capturesInStage = {
    __isPolicy = true;
    emits = bothKinds;
    fn =
      { host, ... }:
      [ (p.from "feat" [ (p.transform (x: "${x}-${host.class}")) ]) ];
  };

  # ── A6 / A6-residual — ONE body shape, ONE field name apart ──────────────────────────────────────────
  # The conditional decides WHICH CHANNEL the commitment is rooted on, so the default branch produces a
  # commitment that can be READ rather than an empty list that cannot be told from "never fired".
  #
  # ★ EACH BODY IS WRITTEN WITH ITS OWN FORMALS AND IS NOT BUILT FROM A `ctx:` WRAPPER AROUND A PREDICATE.
  # The gate is `functionArgs` of the body, so a wrapper erases it, `recoverCommitments` then binds the
  # twin at NO key, and every arm below would report the wrapper's own arity error instead of the property
  # it names. Three bodies, three formals, one field path apart.
  commitPolicy = fn: {
    __isPolicy = true;
    emits = bothKinds;
    inherit fn;
  };
  channelFor = c: [ (p.from (if c then "hub" else "feat") [ (p.transform (x: x)) ]) ];
  # `settings` — in the twin's key set on the BRIDGED wiring, absent on the direct one.
  hubPeer = commitPolicy ({ host, ... }: channelFor (host.settings.isHub or false));
  # `tags` — outside the key set at EVERY wiring, read behind `or`.
  tagPeer = commitPolicy ({ host, ... }: channelFor (host.tags.role or false));
  # …and the same field read BARE — §2.4.5's ceiling reached through a field instead of an alias.
  tagPeerBare = commitPolicy ({ host, ... }: channelFor host.tags.role);
in
{
  flake.tests.compat-commitment-fire = {
    # ── A1 — the timing pair ──────────────────────────────────────────────────────────────────────────
    # (i) THE FIRE SUCCEEDS. Law C2: the op DAG is built from the stage closures WITHOUT applying them,
    # and `deepSeq` does not enter a function body — so the captured twin field is never forced here. The
    # commitment is built, rooted on `feat`, and carries the declaration-site token.
    test-a1-capturing-stage-fires-clean = {
      expr =
        let
          ops = (compiledB { capturesInStage = capturesInStage; }).capturesInStage.ops;
          o = builtins.head ops;
        in
        {
          count = builtins.length ops;
          kind = o.__action;
          channel = o.channel;
          derived = o.derived.__derived;
          # the site token is the owning policy, the channel, and the within-pair ordinal
          rootedOnItsSite = o.derived.id == "feat.over#capturesInStage-feat-0.map";
        };
      expected = {
        count = 1;
        kind = "pipeCommit";
        channel = "feat";
        derived = true;
        rootedOnItsSite = true;
      };
    };
    # (ii) …AND THE ABORT IS AT THE STAGE APPLICATION, per node — the same policy, forced through a real
    # node's binding surface, where gen-pipe applies `f` and the captured twin field finally raises. The
    # message is the TWIN's, naming the policy and the coordinate FIELD. Asserting this at the firing
    # instead would have passed against a design that forced stage closures eagerly, which is the timing
    # this pair exists to hold apart.
    test-a1-capturing-stage-aborts-at-the-stage-application = {
      expr = builtins.deepSeq (bindingsOf { capturesInStage = capturesInStage; }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "v1 policy `capturesInStage` read the coordinate field `class` while building its compose commitment";
      };
    };

    # ── A3 — a REQUIRED coordinate read by field is ATTRIBUTED at the fire site ───────────────────────
    # `host.class` is a `probe-sentinel.nix` constant, so it is in the twin's key set at BOTH production
    # wirings and this arm needs no surface pin. The read raises the twin's named throw, the recovery fire's
    # `tryEval` catches it — destroying its text — and the diagnostic is SYNTHESIZED on the caller's side
    # of that boundary from the policy name and the probe's verdict. Asserting the twin's own text here
    # would assert something no envelope can deliver.
    test-a3-field-read-is-attributed-at-the-fire-site = {
      expr =
        (compiledB {
          readsField = {
            __isPolicy = true;
            emits = bothKinds;
            fn =
              { host, ... }:
              optionals (host.class == "hub") [ (p.from "feat" [ (p.transform (x: x)) ]) ];
          };
        }).readsField.ops;
      expectedError = {
        type = "ThrownError";
        msg = "firing v1 policy `readsField` at the commitment sentinel raised an error while building its compose commitment. The coordinate\\(s\\) it reads: host";
      };
    };

    # ── A3-defaulted-residual — the ATTRIBUTION ceiling, pinned OPEN ──────────────────────────────────
    # The fire binds EVERY coordinate; the probe binds only the REQUIRED ones. So a DEFAULTED coordinate
    # fails the fire (catchably — the abort renders) and is invisible to the probe, whose only arm lets
    # `tuning` take its own default and passes. The attributed set comes back EMPTY.
    #
    # THE SECOND HALF IS THE ONE THAT MATTERS: an empty attribution is forbidden to degrade to silence, so
    # the message falls to the full candidate set. The lookahead asserts the ceiling honestly — `tuning`
    # is the coordinate that failed and it is NEVER NAMED. An arm asserting only that the abort fires
    # could not tell this ceiling from A3's success.
    #
    # ★ The default must CARRY the field the body reads. `tuning ? { }` with a bare `tuning.class` dies in
    # the PROBE on `attribute 'class' missing`, uncatchably, and the fixture would then exhibit the
    # COORDINATE ceiling below while claiming the attribution one.
    test-a3-defaulted-residual-attribution-is-empty-and-falls-back = {
      expr =
        (compiledB {
          readsDefaulted = {
            __isPolicy = true;
            emits = bothKinds;
            fn =
              {
                host,
                tuning ? {
                  class = "none";
                },
                ...
              }:
              optionals (tuning.class == "hub") [ (p.from "feat" [ (p.transform (x: x)) ]) ];
          };
        }).readsDefaulted.ops;
      expectedError = {
        type = "ThrownError";
        msg = "^(?![\\s\\S]*tuning)[\\s\\S]*No single coordinate could be attributed, so the full candidate set is named: host";
      };
    };

    # ── A3-coordinate-residual — the CATCHABILITY ceiling, pinned OPEN ────────────────────────────────
    # A defaulted, list-typed formal consumed BY TYPE never selects a field at all: Nix's argument-type
    # check inspects the type tag, sees an attrset where a list is required, and raises its OWN error —
    # which `tryEval` cannot catch. `classifyDecls` never returns, the fire-site attribution never runs,
    # and NO den-compat diagnostic is produced. The lookahead is what makes that an assertion rather than
    # a hope: the absence of the shim's own prefix is the ceiling's content.
    #
    # Paired with A3 above, the two bodies differ in ONE thing — field read vs type assertion — and return
    # opposite verdicts on catchability. The pair fails the day the fire gains a typed synthetic ctx,
    # which is the correct signal that the ceiling closed.
    test-a3-coordinate-residual-type-consumption-is-uncatchable-and-unnamed = {
      expr =
        (compiledB {
          typeConsumes = {
            __isPolicy = true;
            emits = bothKinds;
            fn =
              {
                host,
                accessGroups ? [ ],
                ...
              }:
              optionals (builtins.elem "member" accessGroups) [
                (p.from "feat" [ (p.transform (x: x)) ])
              ];
          };
        }).typeConsumes.ops;
      expectedError = {
        type = "TypeError";
        msg = "^(?![\\s\\S]*den-compat)[\\s\\S]*expected a list but found a set";
      };
    };

    # ── A3's alias companion — §2.4.5's ceiling, reached through a ctx KEY ────────────────────────────
    # A `ctx@{ … }` body reading a key the synthetic ctx does not carry raises `attribute … missing`,
    # which `tryEval` likewise cannot catch. Asserted AS the ceiling: the honest statement of the residual
    # rather than a pretence that it is closed.
    test-a3-ctx-alias-read-fails-uncatchably = {
      expr =
        (compiledB {
          aliasReader = {
            __isPolicy = true;
            emits = bothKinds;
            fn = ctx@{ host, ... }: optionals (ctx.zzz == "x") [ (p.from "feat" [ (p.transform (x: x)) ]) ];
          };
        }).aliasReader.ops;
      expectedError = {
        type = "EvalError";
        msg = "^(?![\\s\\S]*den-compat)[\\s\\S]*attribute 'zzz' missing";
      };
    };

    # ── A6 — a ctx-CONDITIONAL effect list, on a field IN the twin's set ──────────────────────────────
    # Distinct from A1 because the two shapes fail at DIFFERENT TIMES: A1 at the stage application, A6 at
    # the fire. A single "reads ctx" fixture would conflate them and could pass while one timing was
    # wrong. The list spine forces the condition, whose first step selects `settings` — bound to a named
    # throw on this wiring — so the fire aborts. `… or false` does not rescue it: `or` defaults an ABSENT
    # attribute, it does not catch a raised throw.
    #
    # ★ THIS IS A REGRESSION TEST FOR THE FIELD SET, not only for the fire. It fails against a twin built
    # from the two-key sentinel, and the control two arms below exhibits that failure directly.
    test-a6-conditional-commitment-aborts-at-the-fire = {
      expr = (compiledB { inherit hubPeer; }).hubPeer.ops;
      expectedError = {
        type = "ThrownError";
        msg = "firing v1 policy `hubPeer` at the commitment sentinel raised an error while building its compose commitment. The coordinate\\(s\\) it reads: host";
      };
    };
    # A6's COMPANION — the same body with `pipeCommit` dropped from the declared codomain. The commitment
    # gate is a presence test over the DECLARED codomain, so this policy is never fired at the sentinel at
    # all and compiles clean with an empty seed: the declaration opt-out, priced at zero. The pair differs
    # in exactly one kind, which is what makes it a measurement of the gate rather than of the body.
    test-a6-companion-mark-only-declaration-is-never-fired = {
      expr =
        (compiledB {
          hubPeer = hubPeer // {
            emits = [ "pipeMark" ];
          };
        }).hubPeer.ops;
      expected = [ ];
    };
    # ★ THE WIRING CONTROL, same instrument same run — and it is what stops A6 being an arm that could
    # have passed for either reason. The SAME body on the DIRECT wiring finds `settings` OUTSIDE the key
    # set, so the `or` supplies the default, the condition reaches `false` SILENTLY, and the fire succeeds
    # with the default-branch commitment. That is the residual §2.4.1a owns, and it is the behaviour of
    # every `denCompat.compile` consumer — not a hypothetical about a sentinel nobody builds.
    test-a6-on-the-direct-wiring-defaults-silently = {
      expr =
        let
          ops = (compiledD { inherit hubPeer; }).hubPeer.ops;
        in
        {
          count = builtins.length ops;
          channel = (builtins.head ops).channel;
        };
      expected = {
        count = 1;
        channel = "feat";
      };
    };

    # ── A6-residual — the FIELD-SET ceiling, pinned OPEN ──────────────────────────────────────────────
    # The same body shape as A6 with ONE field name changed, to a field that is outside the twin's key set
    # at ALL THREE wirings. The fire SUCCEEDS, the conditional takes its default branch, and the policy
    # compiles with a DEFAULT-BRANCH commitment and no abort — asserted by the channel the commitment is
    # rooted on, which is the branch's own observable. A fixture asserting an empty `ops` could not tell
    # "took the default branch" from "was never fired", which is precisely A6-companion's verdict.
    #
    # It must FAIL the day someone extends `probe-sentinel.nix` to cover that field. That is the correct
    # signal — the residual narrowed, and this arm is the thing that says so.
    test-a6-residual-field-outside-the-set-takes-the-default-branch = {
      expr =
        let
          ops = (compiledB { inherit tagPeer; }).tagPeer.ops;
        in
        {
          count = builtins.length ops;
          channel = (builtins.head ops).channel;
          derived = (builtins.head ops).derived.__derived;
        };
      expected = {
        count = 1;
        channel = "feat";
        derived = true;
      };
    };
    # …and its own companion, one line: the BARE read of the same absent field is loud at every wiring,
    # and loud UNCATCHABLY. `or` is the whole difference between this arm and the one above.
    test-a6-residual-bare-read-fails-uncatchably = {
      expr = (compiledB { inherit tagPeerBare; }).tagPeerBare.ops;
      expectedError = {
        type = "EvalError";
        msg = "^(?![\\s\\S]*den-compat)[\\s\\S]*attribute 'tags' missing";
      };
    };
  };
}
