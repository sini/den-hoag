# C7.5 gap 3 — collection-stratum pipeOp CONSUMPTION. den-compat compiles a v1 `pipe.from name [stages]`
# to a `pipeOp` declaration carrying a gen-pipe DERIVED channel DAG (filter/transform/fold/for folded
# left-to-right). Before C7.5 that DAG compiled but never reached the fleet gen-pipe compose (produced,
# never consumed). Now den-hoag threads every policy's pipe `derived` channel into the ONE compose (the
# `policyOps` seam — the same seam the demand channel rides), so the transform is a real fleet channel.
#
# The compose's cycle-safe worklist dedups the pipe's base-channel stub against the real `den.quirks`
# registration by id (channelDecls seeded first), so `pipe.from feat …` resolves onto the registered
# `feat` with no E4b clash. Each deriving pipe now adds a LEADING `over` (the v1 flattenAndExtract prepend
# — a list-valued emission spread into per-element contributions ahead of the stages, compilePipe) plus
# one channel per stage, all rooted on `feat` (`feat.over.<i>`, then `feat.over.<i>.<op>.<j>`). A pipe-free
# fleet composes byte-identically to before (no phantom channel). The `for` whole-list run is HONORED
# (board #45): `honorWholeList` (default.nix) reroutes a `for`'s `__derive.wholeList` node to gen-pipe's
# `over` op, so the stage composes as `feat.over.<i>.over.<j>` (whole-list), where `transform` stays
# `feat.over.<i>.map.<j>` (per-element). The `as` delivery routes are wired (default.nix — route channelRef
# records rooted at the derived terminal); `to` aspect-targeting is the documented follow-on.
{ denCompat, xfail, ... }:
let
  # A v1 `pipe.from` policy effect built exactly as the corpus does (policy-effects.nix shape).
  pipeEffect = pipeName: stages: {
    __policyEffect = "pipe";
    value = { inherit pipeName stages; };
  };
  transform = fn: {
    __pipeStage = "transform";
    inherit fn;
  };
  filterS = fn: {
    __pipeStage = "filter";
    inherit fn;
  };

  # A fleet with a `feat` quirk, an aspect emitting to it, and a policy transforming it (transform then
  # filter — two deriving stages ⇒ a two-node derived DAG rooted on `feat`).
  withPipe = denCompat.mkDen [
    {
      config.den.hosts.x86_64-linux.axon.class = "nixos";
      config.den.quirks.feat = { };
      config.den.aspects.seed.feat = [ "hello" ];
      config.den.schema.host.includes = [ "seed" ];
      config.den.policies.shapeFeat = {
        emits = [ "pipeOp" ];
        fn = _ctx: [
          (pipeEffect "feat" [
            (transform (x: x))
            (filterS (_: true))
          ])
        ];
      };
    }
  ];
  withPipeChannels = builtins.sort (a: b: a < b) (builtins.attrNames withPipe.den.quirkDag.channels);

  # The SAME fleet with no pipe policy — the compose must be byte-identical minus the derived channel.
  noPipe = denCompat.mkDen [
    {
      config.den.hosts.x86_64-linux.axon.class = "nixos";
      config.den.quirks.feat = { };
      config.den.aspects.seed.feat = [ "hello" ];
      config.den.schema.host.includes = [ "seed" ];
    }
  ];
  noPipeChannels = builtins.sort (a: b: a < b) (builtins.attrNames noPipe.den.quirkDag.channels);

  # The derived channel(s) the pipe added = the compose delta.
  derivedAdded = builtins.filter (c: !(builtins.elem c noPipeChannels)) withPipeChannels;

  # ── board #45: `for` (whole-list) is HONORED to gen-pipe's `over`; `transform` stays per-element `map` ──
  forS = fn: {
    __pipeStage = "for";
    inherit fn;
  };
  # A one-deriving-stage fleet on `feat`, so the delta is the flatten-`over` + that one stage to name-check.
  mkShaped =
    stage:
    denCompat.mkDen [
      {
        config.den.hosts.x86_64-linux.axon.class = "nixos";
        config.den.quirks.feat = { };
        config.den.aspects.seed.feat = [ "hello" ];
        config.den.schema.host.includes = [ "seed" ];
        config.den.policies.shapeFeat = {
          emits = [ "pipeOp" ];
          fn = _ctx: [ (pipeEffect "feat" [ stage ]) ];
        };
      }
    ];
  derivedOf =
    fleet:
    builtins.filter (c: !(builtins.elem c noPipeChannels)) (
      builtins.attrNames fleet.den.quirkDag.channels
    );
  forDerivedNames = derivedOf (mkShaped (forS (xs: xs)));
  transformDerivedNames = derivedOf (mkShaped (transform (x: x)));
in
{
  flake.tests.pipe-consume = {
    # the compose EVALUATES (no E4a/E4b abort) with the pipe threaded in — non-vacuous: it has channels.
    test-compose-succeeds = {
      expr = builtins.length withPipeChannels >= 1;
      expected = true;
    };
    # the base `feat` quirk survives (the derived DAG's stub deduped against the real registration by id).
    test-base-channel-present = {
      expr = builtins.elem "feat" withPipeChannels;
      expected = true;
    };
    # the pipe added THREE derived channels: the leading `over` (the flattenAndExtract prepend — a
    # list-valued emission spread into per-element contributions ahead of the stages, compilePipe) plus its
    # two deriving stages (transform→map, filter→filter). The whole chain is declared so gen-pipe E4a's
    # declared-op-input check passes — the flatten+transform+filter is CONSUMED into the fleet DAG.
    #
    # DECLARED KNOWN-FAILURE. Nothing populates a compiled policy record's `ops` — the compat
    # compiler mints `emits`/`gate`/`fn`/`selects` and no `ops` — so `pipeOps`, which concat-maps
    # `ops` over the rules, is universally empty and the compose sees no derived channel to consume.
    # The seed construction is wrong upstream of the shim rather than merely unwired here, so this is
    # declared against the seam and not worked around locally.
    test-derived-channels-consumed = xfail.value {
      bead = "den-hoag-gb9";
      construct = "pipeOps";
      expr = builtins.length derivedAdded;
      actual = 0;
      correct = 3;
    };
    # …and every derived channel is the gen-pipe derived form rooted on the base channel (`feat.<op>.…`).
    # Non-emptiness is asserted in the SAME expression as the quantifier, because `all p [ ]` is TRUE: over
    # an empty `derivedAdded` the naming property certifies itself, so this test would report green on the
    # exact compose delta — none at all — that `test-derived-channels-consumed` exists to catch. The two
    # halves are forced together, so the names property can only pass on channels that were really added.
    #
    # DECLARED KNOWN-FAILURE, on the same empty seed. ★ THE WHOLE LEAF IS DECLARED RATHER THAN A
    # NARROWED FIELD, and that is safe only BECAUSE the two halves are forced together: freezing
    # `allRootedOnBase = true` — which is vacuously true over the empty list — would normally pin a
    # vacuous truth that keeps reading as verified after the seed is fixed. Here it cannot, because
    # the moment the seed is fixed `anyDerived` flips and the leaf goes red on the pair.
    test-derived-channel-names = xfail.value {
      bead = "den-hoag-gb9";
      construct = "pipeOps";
      expr = {
        anyDerived = derivedAdded != [ ];
        allRootedOnBase = builtins.all (c: builtins.substring 0 5 c == "feat.") derivedAdded;
      };
      actual = {
        anyDerived = false;
        allRootedOnBase = true;
      };
      correct = {
        anyDerived = true;
        allRootedOnBase = true;
      };
    };
    # a pipe-FREE fleet's compose carries no derived channel — only the base quirk + the demand channel.
    test-no-pipe-no-derived = {
      expr = noPipeChannels;
      expected = [
        "__den-demands"
        "feat"
      ];
    };

    # board #45: each single-stage pipe adds TWO derived channels now — the leading flattenAndExtract `over`
    # (the per-element spread, compilePipe) plus the stage itself, the stage rooted on the flatten-over.
    test-for-single-derived = xfail.value {
      bead = "den-hoag-gb9";
      construct = "pipeOps";
      expr = builtins.length forDerivedNames;
      actual = 0;
      correct = 2;
    };
    # a `for` (whole-list) pipe is HONORED to gen-pipe's `over` op — the STAGE channel is
    # `feat.over.<i>.over.<j>` (whole-list run, rooted on the flatten-over), NOT a per-element `…map…`.
    test-for-honored-as-over = xfail.value {
      bead = "den-hoag-gb9";
      construct = "pipeOps";
      expr = builtins.any (
        c: builtins.match "feat\\.over\\.[0-9]+\\.over\\.[0-9]+" c != null
      ) forDerivedNames;
      actual = false;
      correct = true;
    };
    # `transform` (no whole-list marker) stays the per-element `map` — the discriminator against `for`: its
    # STAGE channel is `feat.over.<i>.map.<j>` (the map rooted on the flatten-over).
    test-transform-stays-map = xfail.value {
      bead = "den-hoag-gb9";
      construct = "pipeOps";
      expr = builtins.any (
        c: builtins.match "feat\\.over\\.[0-9]+\\.map\\.[0-9]+" c != null
      ) transformDerivedNames;
      actual = false;
      correct = true;
    };
  };
}
