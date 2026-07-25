# inputs'/self' as inherited NODE attributes (the den.systemViews surface). An external per-system flake
# value is delivered to producers NOT via a `_module.args` battery but as a decl folded onto its
# system-bearing root node, carried down the P edges by `scope.inheritAll` (inherited-context, attr 1).
# A parametric quirk producer `{ inputs', ... }:` then discovers it through the ordinary inherited-attribute
# surface and resolves EAGERLY to concrete data — dissolving the nixpkgs↔config overlay recursion (a raw
# function riding into `nixpkgs.overlays` and applied against `_module.args.inputs'`, whose module needs
# `pkgs`, which needs the overlays…). Native fixture: a hand-crafted per-system view whose `inputs'` carries
# the NON-per-system `.overlays` field (the shape mergeInputs supplies at the compat boundary, read by the
# fault site linux-kernel.nix:9), so a producer reading `inputs'.<x>.overlays.<y>` cannot be masked by a
# bare (per-system-only) inputs'.
{ denHoag, ... }:
let
  system = "x86_64-linux";
  # A COMPARABLE sentinel overlay (a real nixpkgs overlay is `final: prev: {}`; here a marker value keeps the
  # assertion nixpkgs-free — the mechanism under test is the DELIVERY + eager resolution, not the overlay's
  # own semantics, which the works-on-den corpus eval exercises).
  sentinelOverlay = "CACHYOS_OVERLAY_SENTINEL";
  sentinelSelf = "SELF_PRIME_SENTINEL";

  systemViews = {
    ${system} = {
      inputs'.cachyos.overlays.default = sentinelOverlay;
      self' = sentinelSelf;
    };
  };

  schema.config.den.schema = {
    env.parent = null;
    host = {
      parent = "env";
      # a native kind is closed-world (strict) — the host's own `system` coordinate is a DECLARED option so
      # it rides on `__entry.system`, the coordinate the scopeRoots fold selects the per-system view by.
      options.system = denHoag.schema.mkOption {
        type = denHoag.schema.types.str;
        default = system;
      };
    };
    user.parent = "host";
  };
  instances.config.den = {
    env.prod = { };
    host.axon.system = system;
    user.alice = { };
  };
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  classing.config.den.contentClass.host = "nixos";
  # the nixpkgs-overlays quirk CHANNEL + a PARAMETRIC producer reading inputs' from the inherited attribute
  # surface (the corpus shape at linux-kernel.nix:9 `nixpkgs-overlays = { inputs', ... }: [ … ]`). The
  # channel content is the BARE function (a channel emission, resolved at the emitting node), never a
  # list-wrapped one.
  quirks.config.den.quirks."nixpkgs-overlays" = { };
  overlayAspect =
    { config, ... }:
    {
      config.den.aspects.kernel."nixpkgs-overlays" = { inputs', ... }: [
        inputs'.cachyos.overlays.default
      ];
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.kernel ];
        }
      ];
    };
  base = [
    schema
    instances
    membership
    classing
    quirks
    overlayAspect
  ];

  withViews = {
    config.den.systemViews = systemViews;
  };
  denWith = (denHoag.mkDen (base ++ [ withViews ])).den;
  # NO systemViews (the default `{ }`) — the fold is inert (the RED-before / removability state).
  denWithout = (denHoag.mkDen base).den;

  hostId = "host:axon";
  ctxAt = den: id: den.structural.eval.get id "enriched-context";
  cellIdOf = den: builtins.head (builtins.attrNames (den.structural.eval.get hostId "children"));
  # the emitting node's own resolved channel contribution: the parametric emit resolved EAGERLY (at
  # structural/collection time) to a CONCRETE value with `deferred = false` — no raw function riding into
  # nixpkgs.overlays, no `_module.args.inputs'` in the pkgs path (the cycle-dissolution witness).
  overlayContribAt =
    den: builtins.head (den.structural.eval.get hostId "local-collection-data")."nixpkgs-overlays";
in
{
  flake.tests.f1-inputs-self-nodes = {
    # the fold delivers inputs' to the host's enriched-context, carrying the NON-per-system `.overlays`
    # field (a bare per-system inputs' would lack it — the defect this reads through).
    test-host-ctx-has-inputs-overlays = {
      expr = (ctxAt denWith hostId).inputs'.cachyos.overlays.default or null;
      expected = sentinelOverlay;
    };
    # self' delivered BARE (no `self // …`), the same inherited surface.
    test-host-ctx-has-self-prime = {
      expr = (ctxAt denWith hostId).self' or null;
      expected = sentinelSelf;
    };
    # inheritAll carries the host's system view down the P edge to its user cell (attr 1 inheritance) —
    # the cell inherits its host's selection with no per-cell decl.
    test-cell-inherits-inputs = {
      expr = (ctxAt denWith (cellIdOf denWith)).inputs'.cachyos.overlays.default or null;
      expected = sentinelOverlay;
    };
    # the parametric quirk producer resolves EAGERLY against the inherited inputs' to CONCRETE DATA (the
    # overlay), reading `.overlays` — never riding the raw function to a `_module.args` consumer.
    test-overlay-quirk-resolved-to-data = {
      expr = (overlayContribAt denWith).value;
      expected = sentinelOverlay;
    };
    # the resolution is EAGER, not deferred to a class config (deferred = false is the cycle-dissolution
    # posture: the value is config-independent withSystem data, forced at structural time).
    test-overlay-quirk-not-deferred = {
      expr = (overlayContribAt denWith).deferred;
      expected = false;
    };
    # removability / flag-off: with no `den.systemViews` (the default `{ }`), the fold is INERT — inputs'
    # never enters enriched-context, so a fleet declaring no views is byte-neutral (the RED-before state,
    # where the producer would instead ride its raw function unresolved).
    test-no-views-is-inert = {
      expr = (ctxAt denWithout hostId) ? inputs';
      expected = false;
    };
  };
}
