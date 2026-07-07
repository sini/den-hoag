# C7.5 gap 3 — collection-stratum pipeOp CONSUMPTION. den-compat compiles a v1 `pipe.from name [stages]`
# to a `pipeOp` declaration carrying a gen-pipe DERIVED channel DAG (filter/transform/fold/for folded
# left-to-right). Before C7.5 that DAG compiled but never reached the fleet gen-pipe compose (produced,
# never consumed). Now den-hoag threads every policy's pipe `derived` channel into the ONE compose (the
# `policyOps` seam — the same seam the demand channel rides), so the transform is a real fleet channel.
#
# The compose's cycle-safe worklist dedups the pipe's base-channel stub against the real `den.quirks`
# registration by id (channelDecls seeded first), so `pipe.from feat …` resolves onto the registered
# `feat` with no E4b clash and adds ONE derived channel (`feat.<op>.<idx>`). A pipe-free fleet composes
# byte-identically to before (no phantom channel). The `to`/`as` delivery routes + the `for` whole-list
# run semantics are the documented follow-ons (default.nix — route records + a gen-pipe whole-list op).
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
    # the pipe added its two deriving stages as TWO derived channels (the whole chain is declared so
    # gen-pipe E4a's declared-op-input check passes) — the transform+filter is CONSUMED into the fleet DAG.
    test-derived-channels-consumed = {
      expr = builtins.length derivedAdded;
      expected = 2;
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
  };
}
