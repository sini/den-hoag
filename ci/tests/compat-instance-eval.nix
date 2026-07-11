# Per-host SCHEMA-TYPED INSTANCE EVAL witnesses (ship-gate M2, fork (i)) — the instantiate-default
# gap. den v1 evaluates every `den.hosts.<sys>.<name>` through the host KIND's instance submodule
# (pin 11866c16 nix/lib/entities/host.nix:53-57), so the corpus's schema-declared per-host defaults
# MATERIALIZE (nix-config schema/host.nix:325 `instantiate = mkDefault resolvedChannel.nixosSystem`,
# channel table :117-142). The shim's bridge crossed RAW authored decls — the defaults never
# materialized, `instantiateFor` was null, every corpus member fell to `collect`. Fork (i)
# (lib/compat/instance-eval.nix) reproduces v1's instance eval at the bridge and stores the harvest
# (`den._hostHarvest`) for ingest's per-host maps.
#
# Witnesses here: (1) the channel-driven instantiate default materializes per host (evaluator
# identity vs the channel table by APPLICATION — Nix function equality is unobservable, so both
# arms are applied to one probe and the results compared; the corpus-pin arm is re-proven by the
# ship-gate drvPath probe); (2) v1's PRIORITY INTERPLAY (authored 100 < corpus mkDefault 1000 <
# base default 1500 — the base default is the D7 "fall to the lower grains" null, the ONE value
# deviation, priority-faithful); (3) GENERALITY — `home-manager.module` (v1 home-env.nix:49-53 via
# the hm battery hostConf) and `secretPath` (corpus host.nix:273,319) ALSO materialize in the SAME
# eval, ready for the later grains; (4) the M2 WIRING end-to-end through the bridge — a
# schema-defaulted host crosses `nixosConfigurations` through its OWN channel evaluator, a
# no-schema fleet still falls to `collect`, and the synthetic-host guard holds at the grain's
# seams (harvest keyed by registered flatHosts only; unknown-id map read is null, never a throw —
# the standalone `user@unregistered-host` fleet shape itself is den-hoag-absent, board #49).
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  # ── corpus-shaped channel machinery (nix-config schema/host.nix:117-142,160-338, faithful shape:
  # a PRIVATE let-bound table closing over "inputs", read via `resolvedChannel = channels.${config
  # .channel}`). TAGGED evaluators: each fake tags its application so the winning value is
  # observable as data.
  channels = {
    nixos-unstable = {
      nixosSystem = args: { __chan = "nixos-unstable"; } // args;
      darwinSystem = args: { __chan = "nixos-unstable-darwin"; } // args;
      home-manager-module.nixos = {
        __hm = "nixos-unstable";
      };
      home-manager-module.darwin = {
        __hm = "nixos-unstable-darwin";
      };
    };
    nixpkgs-master = {
      nixosSystem = args: { __chan = "nixpkgs-master"; } // args;
      darwinSystem = args: { __chan = "nixpkgs-master-darwin"; } // args;
      home-manager-module.nixos = {
        __hm = "nixpkgs-master";
      };
      home-manager-module.darwin = {
        __hm = "nixpkgs-master-darwin";
      };
    };
  };
  # The corpus kind module (the `den.schema.host.imports` entry, host.nix:160): channel option
  # (:168-172), secretPath option (:273-280), and the computed-config mkDefaults (:313-335 —
  # instantiate :325-327, home-manager.module :329-334, secretPath :319).
  corpusKindModule =
    { config, ... }:
    let
      resolvedChannel = channels.${config.channel};
    in
    {
      options = {
        channel = lib.mkOption {
          type = lib.types.enum (builtins.attrNames channels);
          default = "nixos-unstable";
        };
        secretPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        # the corpus's dynamic per-aspect settings namespace (host.nix:301-309 via _settings-type.nix),
        # faithful shape: a typed submodule tree mirroring an aspect path, carrying an aspect-DECLARED
        # option default (mountPoint — corpus xfs-disk-longhorn.nix:9-13) the host does not author.
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
      config = {
        secretPath = lib.mkDefault "/secrets/hosts/${config.name}";
        instantiate = lib.mkDefault (
          if config.class == "darwin" then resolvedChannel.darwinSystem else resolvedChannel.nixosSystem
        );
        home-manager.module = lib.mkDefault (
          if config.class == "darwin" then
            resolvedChannel.home-manager-module.darwin
          else
            resolvedChannel.home-manager-module.nixos
        );
      };
    };

  authoredEval = args: { __authored = true; } // args;
  probe = {
    probe = true;
  };

  # ── UNIT arm: the harvest builder directly ─────────────────────────────────────────────────────
  harvest = denCompat.instanceEval {
    inherit lib;
    kindModule = corpusKindModule;
    flatHosts = {
      # default channel — the corpus's dominant case (channel omitted ⇒ "nixos-unstable"); authors ONE
      # settings field (device_id, the axon-01.nix:40 idiom) — the other (mountPoint) resolves to the
      # aspect-declared default in the SAME eval (the board #59 merge golden below).
      chan = {
        system = "x86_64-linux";
        settings.disk.probe.device_id = "/dev/disk/by-id/probe-0001";
      };
      # explicit channel — per-host channel selection.
      master = {
        system = "x86_64-linux";
        channel = "nixpkgs-master";
      };
      # authored evaluator — priority 100 beats the corpus mkDefault (1000).
      authored = {
        system = "x86_64-linux";
        instantiate = authoredEval;
      };
      # darwin host — v1's class-from-system derivation (entities/host.nix:65-67) selects the
      # darwinSystem branch (host.nix:326). Materialized but INERT this rung: the compat
      # instantiate wrapper is stamped only on the nixos class (the class-B darwin arm).
      mac = {
        system = "aarch64-darwin";
      };
    };
  };
  # no corpus kind module at all — the no-override fleet: every schema default absent, the base
  # option default (1500) holds.
  bare = denCompat.instanceEval {
    inherit lib;
    kindModule = { };
    flatHosts = {
      plain = {
        system = "x86_64-linux";
      };
    };
  };

  # ── INGEST arm: the `_hostHarvest` read feeding instantiateFor ─────────────────────────────────
  compiledWithHarvest = denCompat.compile {
    hosts.x86_64-linux.h1 = { };
    _hostHarvest.h1.instantiate = args: { __harvested = true; } // args;
  };
  h1Entry = compiledWithHarvest.entities.registries.host.h1;
  compiledNoHarvest = denCompat.compile {
    hosts.x86_64-linux.h1 = { };
  };

  # ── BRIDGE arm (end-to-end): the M2 wiring — flake-parts eval, corpus-shaped schema, real member
  # crossing (the compat-schema-processing harness pattern).
  mkCrossNixos =
    npkgs:
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { nixpkgs = npkgs; }).crossNixos;
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    inherit mkCrossNixos;
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
        den.hosts.x86_64-linux.chan = { };
        # self-named aspect ⇒ real nixos content for the member (the compat fixture pattern).
        den.aspects.chan.nixos.marker = "c";
      }
    ];
  };
  configs = ev.config.flake.nixosConfigurations;
  # same bridge, NO host-kind declaration: the pre-harvest byte-path — the grain absent, members
  # fall to the class terminal (`collect`, no den.nixpkgs here).
  evNoSchema = lib.evalModules {
    modules = [
      flakeStub
      bridge
      {
        den.hosts.x86_64-linux.plain = { };
        den.aspects.plain.nixos.marker = "p";
      }
    ];
  };
  configsNoSchema = evNoSchema.config.flake.nixosConfigurations;
in
{
  flake.tests.compat-instance-eval = {
    # the corpus's channel-driven instantiate default MATERIALIZES per host: the harvested
    # evaluator and the channel table's nixosSystem agree by application (evaluator identity, the
    # pin-oracle structural check).
    test-channel-default-materializes = {
      expr = {
        viaHarvest = harvest.chan.instantiate probe;
        agreesWithTable = harvest.chan.instantiate probe == channels.nixos-unstable.nixosSystem probe;
      };
      expected = {
        viaHarvest = {
          __chan = "nixos-unstable";
          probe = true;
        };
        agreesWithTable = true;
      };
    };
    # per-host channel selection: an explicit `channel = "nixpkgs-master"` resolves ITS evaluator.
    test-per-host-channel-selection = {
      expr = harvest.master.instantiate probe;
      expected = {
        __chan = "nixpkgs-master";
        probe = true;
      };
    };
    # v1's base derivations materialize on the instance (entities/host.nix: name injected, system
    # :64, class :65-67) — the fields the corpus module's defaults read.
    test-base-fields-materialize = {
      expr = {
        name = harvest.chan.name;
        system = harvest.chan.system;
        class = harvest.chan.class;
        macClass = harvest.mac.class;
      };
      expected = {
        name = "chan";
        system = "x86_64-linux";
        class = "nixos";
        macClass = "darwin";
      };
    };
    # the darwin branch of the corpus default (host.nix:326) selects darwinSystem — materialized,
    # though inert until the class-B arm stamps the wrapper on the darwin class.
    test-darwin-branch-materializes = {
      expr = harvest.mac.instantiate probe;
      expected = {
        __chan = "nixos-unstable-darwin";
        probe = true;
      };
    };
    # PRIORITY interplay, authored half: an authored `instantiate` (definition priority 100) beats
    # the corpus's mkDefault (1000) — v1's exact interplay.
    test-priority-authored-wins = {
      expr = harvest.authored.instantiate probe;
      expected = {
        __authored = true;
        probe = true;
      };
    };
    # PRIORITY interplay, base half: no corpus override ⇒ the base option default (1500) holds —
    # null, the D7 "fall to the lower grains" slot (v1's slot holds den's own inputs there; den-hoag's
    # analog IS the lower grains — the one value deviation, priority-faithful).
    test-priority-base-default = {
      expr = {
        instantiate = bare.plain.instantiate;
        class = bare.plain.class;
      };
      expected = {
        instantiate = null;
        class = "nixos";
      };
    };
    # (board #59) the corpus's settings MERGE materializes in the SAME harvest: the aspect-declared
    # option DEFAULT (mountPoint) under the host-authored value (device_id) — v1's merged
    # `host.settings` view (corpus host.nix:301-309 / _settings-type.nix), the source the entity
    # stamp (ingest.nix hostEntityFields) reads. This is the harvest-check golden: the corpus's OWN
    # schema eval does the merging, v1-faithful by construction.
    test-settings-merge-materializes = {
      expr = harvest.chan.settings.disk.probe;
      expected = {
        device_id = "/dev/disk/by-id/probe-0001";
        mountPoint = "/var/lib/probe";
      };
    };
    # GENERALITY: the SAME eval materializes the other schema-declared per-host defaults —
    # `home-manager.module` (channel-driven, corpus host.nix:329-334) and `secretPath` (name-driven,
    # :319) — the entries the later hmModuleFor/secretPathFor grains read, no re-eval.
    test-generality-other-defaults = {
      expr = {
        hmModule = harvest.chan.home-manager.module;
        hmModuleMaster = harvest.master.home-manager.module;
        secretPath = harvest.chan.secretPath;
      };
      expected = {
        hmModule = {
          __hm = "nixos-unstable";
        };
        hmModuleMaster = {
          __hm = "nixpkgs-master";
        };
        secretPath = "/secrets/hosts/chan";
      };
    };
    # ingest's authored-or-harvest read: `_hostHarvest.<h>.instantiate` feeds instantiateFor (the
    # id_hash-keyed M2 map) when the host authors none.
    test-ingest-reads-harvest = {
      expr = (compiledWithHarvest.entities.instantiateFor h1Entry) probe;
      expected = {
        __harvested = true;
        probe = true;
      };
    };
    # no harvest (mkDen-direct path): instantiateFor stays null — the pre-fork byte-identity guard.
    test-ingest-no-harvest-null = {
      expr = compiledNoHarvest.entities.instantiateFor compiledNoHarvest.entities.registries.host.h1;
      expected = null;
    };
    # an entry whose id_hash is not a registered host (the synthetic-adjacent map-miss arm) is null,
    # never a throw.
    test-ingest-unknown-id-null = {
      expr = compiledWithHarvest.entities.instantiateFor { id_hash = "«not-a-host»"; };
      expected = null;
    };
    # ── the M2 WIRING, end-to-end through the bridge ──────────────────────────────────────────────
    # a schema-defaulted host crosses nixosConfigurations through its OWN channel evaluator (the
    # harvested grain WINS over the class terminal — here `collect`, no den.nixpkgs), with the
    # terminal contract intact (wrapped modules + specialArgs.nodes).
    test-bridge-channel-crossing = {
      expr = {
        chan = configs.chan.__chan or null;
        notCollect = (configs.chan.__terminal or null) != "collect";
        hasModules = configs.chan ? modules;
        hasNodes = (configs.chan.specialArgs or { }) ? nodes;
      };
      expected = {
        chan = "nixos-unstable";
        notCollect = true;
        hasModules = true;
        hasNodes = true;
      };
    };
    # SYNTHETIC `user@host` guard, at the grain's own seams (a standalone home under an
    # UNREGISTERED host is itself a den-hoag-absent fleet shape — den.homes / board #49, so the
    # end-to-end arm cannot carry it yet): the harvest is keyed by the REGISTERED flatHosts alone
    # (a synthetic name-match target gains no entry, hence no phantom grain — see also
    # test-ingest-unknown-id-null for the map-miss arm), and the member set is exactly the
    # registered hosts.
    test-bridge-synthetic-no-phantom = {
      expr = {
        harvestKeys = builtins.attrNames harvest;
        members = builtins.attrNames configs;
      };
      expected = {
        harvestKeys = [
          "authored"
          "chan"
          "mac"
          "master"
        ];
        members = [ "chan" ];
      };
    };
    # a fleet with NO host-kind declaration harvests base-only (every default null): the grain is
    # absent and the member falls to `collect` — byte-path of the pre-harvest bridge.
    test-bridge-no-schema-collect = {
      expr = configsNoSchema.plain.__terminal or null;
      expected = "collect";
    };
  };
}
