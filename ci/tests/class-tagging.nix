# Task 5 — quirk-channel class tags (Law A13). Over an env/host/user fleet where hosts produce the
# `nixos` class and user cells the `home-manager` class (env is class-neutral):
#
#   dual inclusion — one aspect emitting to a channel, included at BOTH a host and a user, yields two
#     contributions with DISTINCT class tags (the producing scope's class): nixos at the host,
#     home-manager at the cell. This is the answer to the dual-inclusion question (r2 §233).
#   null-class + class-shaped — a config-demanding (deferred) emission at env (class-neutral) is a
#     definition-time abort (den-framed classAmbiguity, surfacing gen-pipe E1); a config-independent
#     emission at the same scope is legal (class-neutral, T3).
#   cross-class read — consuming a nixos-tagged contribution at class home-manager with no declared
#     adapter aborts (den-framed crossClassNoAdapter); with a nixos->home-manager adapter the value is
#     adapted and an "adapted" provenance hop is recorded.
{ denHoag, ... }:
let
  I = denHoag.internal;

  schema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
    };
  };
  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      user.alice = { };
    };
  };
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
        }
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  # class-tag vocabulary: hosts produce nixos, user cells home-manager, env is class-neutral.
  classing.config.den.contentClass = {
    host = "nixos";
    user = "home-manager";
  };
  # one quirk channel (no adapter, no dedup) as the shared base.
  quirk.config.den.quirks.ssh-peers = { };
  base = [
    schema
    instances
    membership
    classing
    quirk
  ];

  axonId = "host:axon";
  aliceCell = "user:alice@host:axon";
  envId = "env:prod";

  # class-tag names of a channel's local contributions at a node.
  tagNamesAt =
    den: id:
    map (c: (c.class or { }).name or null) (
      (den.structural.eval.get id "local-collection-data").ssh-peers or [ ]
    );

  # ── dual inclusion: one aspect, plain-list emission, included at host AND user ──────────────
  dualMod =
    { config, ... }:
    {
      config.den.aspects.peer.ssh-peers = [ "10.0.0.1" ];
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.peer ];
        }
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.peer ];
        }
      ];
    };
  denDual = (denHoag.mkDen (base ++ [ dualMod ])).den;

  # ── null-class scope: a config-demanding (deferred) emission at env aborts ───────────────────
  envDeferredMod =
    { config, ... }:
    {
      config.den.aspects.envq.ssh-peers = { config, ... }: [ config.foo ];
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.envq ];
        }
      ];
    };
  denEnvDeferred = (denHoag.mkDen (base ++ [ envDeferredMod ])).den;

  # …but a config-independent (plain) emission at the same class-neutral scope is legal (T3, null tag).
  envPlainMod =
    { config, ... }:
    {
      config.den.aspects.envq.ssh-peers = [ "neutral" ];
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.envq ];
        }
      ];
    };
  denEnvPlain = (denHoag.mkDen (base ++ [ envPlainMod ])).den;

  # ── cross-class read: a nixos contribution consumed at home-manager ─────────────────────────
  # peer emits at the host (tagged nixos); the cell (home-manager) receives it via the neron parent
  # walk. Read at class home-manager: without an adapter it aborts; with one it adapts.
  hostOnlyMod =
    { config, ... }:
    {
      config.den.aspects.peer.ssh-peers = [ "10.0.0.1" ];
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.peer ];
        }
      ];
    };
  denNoAdapter = (denHoag.mkDen (base ++ [ hostOnlyMod ])).den;

  # same fleet, but the quirk declares a nixos->home-manager adapter appending a marker.
  quirkAdapter.config.den.quirks.ssh-peers.adapters = [
    {
      from = denHoag.classes.nixos;
      to = denHoag.classes.home-manager;
      fn = value: _provenance: value ++ [ "ADAPTED" ];
    }
  ];
  denAdapter =
    (denHoag.mkDen (
      [
        schema
        instances
        membership
        classing
        quirkAdapter
      ]
      ++ [ hostOnlyMod ]
    )).den;

  readNoAdapter = I.consumeAt {
    outputs = denNoAdapter.receivedOutputs;
    at = aliceCell;
    channel = denNoAdapter.quirkDag.channels.ssh-peers;
    class = denNoAdapter.classes.home-manager;
  };
  readAdaptedValues = I.consumeAt {
    outputs = denAdapter.receivedOutputs;
    at = aliceCell;
    channel = denAdapter.quirkDag.channels.ssh-peers;
    class = denAdapter.classes.home-manager;
  };
  readAdaptedRecords = I.consumeAt {
    outputs = denAdapter.receivedOutputs;
    at = aliceCell;
    channel = denAdapter.quirkDag.channels.ssh-peers;
    class = denAdapter.classes.home-manager;
    mode = "records";
  };
  adaptedHops = builtins.concatMap (
    r: map (h: h.op) r.contribution.provenance.hops
  ) readAdaptedRecords;
in
{
  flake.tests.class-tagging = {
    # ── dual inclusion (A13) ──
    # the host emission is tagged the host's class…
    test-dual-host-tagged-nixos = {
      expr = tagNamesAt denDual axonId;
      expected = [ "nixos" ];
    };
    # …and the user-cell emission the cell's class — one aspect, two distinct tags.
    test-dual-cell-tagged-homemanager = {
      expr = tagNamesAt denDual aliceCell;
      expected = [ "home-manager" ];
    };

    # ── null-class scope (A13) ──
    # a class-shaped (config-demanding) emission at a class-neutral scope aborts, named.
    test-null-class-classshaped-aborts = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (denEnvDeferred.structural.eval.get envId "local-collection-data") true
        )).success;
      expected = false;
    };
    # a config-independent emission at the same scope is legal and class-neutral (null tag).
    test-null-class-neutral-ok = {
      expr = tagNamesAt denEnvPlain envId;
      expected = [ null ];
    };

    # ── cross-class read (A13) ──
    # consuming a nixos contribution at home-manager with no adapter aborts, named.
    test-cross-class-no-adapter-aborts = {
      expr = (builtins.tryEval (builtins.deepSeq readNoAdapter true)).success;
      expected = false;
    };
    # with a declared adapter the value is adapted (the marker the adapter appended appears)…
    test-cross-class-adapter-adapts-value = {
      expr = readAdaptedValues;
      expected = [
        [
          "10.0.0.1"
          "ADAPTED"
        ]
      ];
    };
    # …and the adaptation is recorded as an "adapted" provenance hop.
    test-cross-class-adapter-provenance-hop = {
      expr = builtins.elem "adapted" adaptedHops;
      expected = true;
    };
  };
}
