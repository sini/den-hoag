# DELIVERY-DEPTH settings binding (board #59 — the host-settings entity-stamp rung). v1 binds the
# RESOLVED host config as the ctx entity (pin 11866c16 nix/lib/aspects/fx/assemble-pipes.nix:154), so
# corpus aspect class bodies read `host.settings.<path>` at the MODULE FIXPOINT inside the real
# nixosSystem — the corpus frontier error this rung closes:
#
#   error: attribute 'settings' missing
#   at nix-config modules/den/aspects/disk/xfs-disk-longhorn.nix:19
#     `cfg = host.settings.disk.xfs-disk-longhorn;`
#
# The fix chain under test, END-TO-END through the bridge: the per-host schema-typed instance-eval
# HARVEST materializes the corpus's merged `settings` (the corpus kind module declares the dynamic
# settings option — nix-config schema/host.nix:301-309 via _settings-type.nix — so aspect-declared
# option DEFAULTS merge under host-authored values, v1-faithful by construction) → ingest
# `hostEntityFields` (harvest-first, the source invariant) → the `instanceConfig` entity stamp
# (flake-module.nix) → the entity entry rides enriched-context → `bindingsAt` (output-modules.nix)
# binds it as the class-module `host` arg → gen-bind wrapAll injects it at the terminal crossing.
#
# The forcing terminal here is a corpus-SHAPED channel evaluator that actually RUNS the wrapped
# modules through a real `lib.evalModules` fixpoint (the `resolvedChannel.nixosSystem` seat, corpus
# host.nix:325) — so the aspect body executes at delivery depth, exactly where xfs-disk-longhorn
# reads. The `collect` terminal never forces bodies (binding-totality.nix), so a non-forcing arm
# would not witness this rung.
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  # ── the forcing evaluator: a real module fixpoint over the wrapped class-modules ────────────────
  # Receives the mkSystemTerminal contract (`{ modules; specialArgs; }`, like the corpus's
  # nixosSystem) and EVALUATES: the aspect body (wrapped by gen-bind with the `host` binding) runs,
  # its `host.settings.<path>` reads force, and the resulting config is inspectable. The freeform
  # absorbs the undeclared (nixpkgs-shaped) keys the pipeline prepends (nixpkgs.hostPlatform).
  forceEval =
    args:
    (lib.evalModules {
      modules = args.modules ++ [
        { freeformType = lib.types.lazyAttrsOf lib.types.raw; }
      ];
      specialArgs = args.specialArgs or { };
    }).config;

  channels.probe-chan = {
    nixosSystem = forceEval;
  };

  # The corpus kind module, faithful shape: channel table + the dynamic settings namespace with an
  # aspect-DECLARED default (mountPoint — corpus xfs-disk-longhorn.nix:9-13) alongside a
  # host-authored field (device_id — hosts/axon-01.nix:40).
  corpusKindModule =
    { config, ... }:
    {
      options = {
        channel = lib.mkOption {
          type = lib.types.enum (builtins.attrNames channels);
          default = "probe-chan";
        };
        settings = lib.mkOption {
          type = lib.types.submodule {
            options.disk = lib.mkOption {
              type = lib.types.submodule {
                options.probe = lib.mkOption {
                  type = lib.types.submodule {
                    options = {
                      device_id = lib.mkOption {
                        type = lib.types.str;
                        default = "";
                      };
                      mountPoint = lib.mkOption {
                        type = lib.types.str;
                        default = "/var/lib/probe";
                      };
                    };
                  };
                  default = { };
                };
              };
              default = { };
            };
          };
          default = { };
        };
      };
      config.instantiate = lib.mkDefault channels.${config.channel}.nixosSystem;
    };

  # ── the bridge, end-to-end (the compat-instance-eval bridge-arm pattern) ────────────────────────
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    # unused: no `den.nixpkgs` in this fixture, so the global-fallback grain is never built.
    mkCrossNixos = _: throw "compat-settings-binding: mkCrossNixos unused (no den.nixpkgs)";
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  ev = lib.evalModules {
    modules = [
      flakeStub
      bridge
      {
        den.schema.host.isEntity = true;
        den.schema.host.imports = [ corpusKindModule ];
        # `disko` authors ONE settings field; the other resolves to the aspect-declared DEFAULT.
        den.hosts.x86_64-linux.disko = {
          settings.disk.probe.device_id = "/dev/disk/by-id/probe-0001";
        };
        # `bare` authors NO settings: the body's read resolves to defaults alone.
        den.hosts.x86_64-linux.bare = { };
        # corpus-shaped aspect class bodies (self-named ⇒ auto-included, the compat fixture
        # pattern): read the aspect's OWN settings namespace at the module fixpoint — the exact
        # xfs-disk-longhorn.nix:16-19 shape (`nixos = { host, ... }: let cfg = host.settings.…`).
        den.aspects.disko.nixos =
          { host, ... }:
          let
            cfg = host.settings.disk.probe;
          in
          {
            probeMarker = {
              inherit (cfg) device_id mountPoint;
            };
          };
        den.aspects.bare.nixos =
          { host, ... }:
          {
            probeMarker.mountPoint = host.settings.disk.probe.mountPoint;
          };
      }
    ];
  };
  configs = ev.config.flake.nixosConfigurations;
in
{
  flake.tests.compat-settings-binding = {
    # THE RUNG'S WITNESS — the corpus frontier shape, in-repo: an aspect body reading
    # `host.settings.<path>` AT DELIVERY DEPTH resolves BOTH the host-authored value (device_id) AND
    # the aspect-declared option DEFAULT (mountPoint) — proof the harvest's merge (not the raw
    # authored subset) rides the delivery binding.
    test-settings-read-at-delivery-depth = {
      expr = configs.disko.probeMarker;
      expected = {
        device_id = "/dev/disk/by-id/probe-0001";
        mountPoint = "/var/lib/probe";
      };
    };
    # defaults-only: a host authoring NO settings still reads the aspect-declared default at the
    # fixpoint (v1's settingsType materializes the option tree for every host).
    test-settings-defaults-only-at-delivery-depth = {
      expr = configs.bare.probeMarker.mountPoint;
      expected = "/var/lib/probe";
    };
  };
}
