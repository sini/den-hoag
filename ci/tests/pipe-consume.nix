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
{ denCompat, ... }:
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
      config.den.policies.shapeFeat = _ctx: [
        (pipeEffect "feat" [
          (transform (x: x))
          (filterS (_: true))
        ])
      ];
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
        config.den.policies.shapeFeat = _ctx: [ (pipeEffect "feat" [ stage ]) ];
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
    test-derived-channels-consumed = {
      expr = builtins.length derivedAdded;
      expected = 3;
    };
    # …and every derived channel is the gen-pipe derived form rooted on the base channel (`feat.<op>.…`).
    test-derived-channel-names = {
      expr = builtins.all (c: builtins.substring 0 5 c == "feat.") derivedAdded;
      expected = true;
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
    test-for-single-derived = {
      expr = builtins.length forDerivedNames;
      expected = 2;
    };
    # a `for` (whole-list) pipe is HONORED to gen-pipe's `over` op — the STAGE channel is
    # `feat.over.<i>.over.<j>` (whole-list run, rooted on the flatten-over), NOT a per-element `…map…`.
    test-for-honored-as-over = {
      expr = builtins.any (
        c: builtins.match "feat\\.over\\.[0-9]+\\.over\\.[0-9]+" c != null
      ) forDerivedNames;
      expected = true;
    };
    # `transform` (no whole-list marker) stays the per-element `map` — the discriminator against `for`: its
    # STAGE channel is `feat.over.<i>.map.<j>` (the map rooted on the flatten-over).
    test-transform-stays-map = {
      expr = builtins.any (
        c: builtins.match "feat\\.over\\.[0-9]+\\.map\\.[0-9]+" c != null
      ) transformDerivedNames;
      expected = true;
    };
  };
}
