# THE BRIDGE-REGISTRY PASSTHROUGH witnesses (the instance-eval harvest's successor — every behavior
# golden from the deleted compat-instance-eval suite re-pinned at the NEW source, values IDENTICAL).
#
# den v1 AUTO-DECLARES `options.den.hosts = types.hostsOption` (pin 11866c16 modules/options.nix:71;
# entities/host.nix:26-44), evaluating every `den.hosts.<sys>.<name>` through the host KIND's instance
# submodule — so the corpus's schema-declared per-host defaults MATERIALIZE (nix-config
# schema/host.nix:325 `instantiate = mkDefault resolvedChannel.nixosSystem`, channel table :117-142)
# at the module system's NATIVE priorities (authored 100 < mkDefault 1000 < base default 1500). The
# shim now declares that SAME option at the bridge (registry.nix mkHostsOption), and `config.den.hosts`
# IS the merged registry — the single source instantiateFor/hmModuleFor and the ctx-entity stamps read.
#
# Witnesses: (1) the channel-driven instantiate default materializes per host (evaluator identity by
# APPLICATION — the pin-oracle structural check); (2) v1's PRIORITY INTERPLAY, now the module system's
# native ladder; (3) GENERALITY — home-manager.module and secretPath materialize in the SAME eval;
# (4) the STRUCTURAL EXCLUSION stamp (settings golden IDENTICAL to the harvest-era golden; facts — the
# facter frontier's field — rides with NO census; instantiate/home-manager/listOf-raw containers
# ABSENT; identity never stamped); (5) the M2 WIRING end-to-end through the bridge (unchanged arms);
# (6) KIND-GENERICITY — a synthetic kind's entities ride the same passthrough into the built fleet's
# registry entries.
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
  # (:168-172), secretPath option (:273-280), the computed-config mkDefaults (:313-335 — instantiate
  # :325-327, home-manager.module :329-334, secretPath :319, facts :320), the dynamic settings
  # namespace (:301-309 via _settings-type.nix), and the STRUCTURAL-EXCLUSION probe fields: `facts`
  # (data-typed — the facter frontier's field) and a `microvm` group mixing a `listOf raw` container
  # (guests — host ENTRIES, the deepSeq hazard; corpus microvm.nix:39-44) with data-typed siblings.
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
        facts = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        microvm.guests = lib.mkOption {
          type = lib.types.listOf lib.types.raw;
          default = [ ];
        };
        microvm.passthrough = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
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
        facts = lib.mkDefault "/facts/${config.name}.json";
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

  # ── UNIT arm: the DECLARED registry itself (mkHostsOption — v1's hostsOption, the pin mirrored).
  # The option's `apply` is v1's two-phase eval; calling it on the raw authored decls is exactly what
  # the bridge's declared option does with the module-merged defs.
  hostsOpt = denCompat.registry.mkHostsOption {
    inherit lib;
    kindModule = corpusKindModule;
  };
  applied = hostsOpt.apply {
    x86_64-linux = {
      # default channel — the corpus's dominant case (channel omitted ⇒ "nixos-unstable"); authors ONE
      # settings field (device_id, the axon-01.nix:40 idiom) — the other (mountPoint) resolves to the
      # aspect-declared default in the SAME eval (the settings-merge golden below, values IDENTICAL
      # to the harvest-era golden).
      chan.settings.disk.probe.device_id = "/dev/disk/by-id/probe-0001";
      # explicit channel — per-host channel selection.
      master.channel = "nixpkgs-master";
      # authored evaluator — priority 100 beats the corpus mkDefault (1000), natively.
      authored.instantiate = authoredEval;
    };
    # darwin host — v1's class-from-system derivation (entities/host.nix:65-67) selects the
    # darwinSystem branch (host.nix:326). TWO-LEVEL group key rides as the `system` option default.
    aarch64-darwin.mac = { };
    # FLAT host (v1 `directHosts`, _types.nix:157-170): normalized into its system group by the
    # registry's preprocess — the v1 flat/two-level parity the option's apply owns.
    flatty.system = "x86_64-linux";
  };
  registry = denCompat.registry.flattenRegistry applied;
  # no corpus kind module at all — the no-override fleet: every schema default absent, the base
  # option default (1500) holds.
  bareOpt = denCompat.registry.mkHostsOption {
    inherit lib;
    kindModule = { };
  };
  bare = denCompat.registry.flattenRegistry (bareOpt.apply { x86_64-linux.plain = { }; });

  # ── the STRUCTURAL-EXCLUSION stamp (registry.nix stampTreeOf/stampOf — what the bridge computes
  # as `_entityStamps.hosts`) ───────────────────────────────────────────────────────────────────────
  stampTree = denCompat.registry.stampTreeOf (
    denCompat.registry.hostInstanceOptions {
      inherit lib;
      kindModule = corpusKindModule;
    }
  );
  stamps = builtins.mapAttrs (_: e: denCompat.registry.stampOf stampTree e) registry;

  # ── INGEST arm: instantiateFor reads the host ENTRY (the registry view on the bridge path) ──────
  compiledRegistry = denCompat.compile { hosts = applied; };
  chanEntry = compiledRegistry.entities.registries.host.chan;
  compiledNoRegistry = denCompat.compile {
    hosts.x86_64-linux.h1 = { };
  };

  # ── KIND-GENERICITY arm: a SYNTHETIC kind's entities ride the SAME passthrough (compile +
  # mkDen-direct with the stamps the bridge would compute; the compat-custom-kind id_hash marker
  # fixture, so discovery maps kind `rack` → namespace `rackFarm`). Zero rack-specific shim code.
  rackHash = "f25f73d7b74fa093bfe797d8fa7393952699b3fd60d76af714940a7612a62906";
  rackFixture = {
    schema.rack.parent = null;
    rackFarm.r1 = {
      name = "r1";
      slots = 12;
      id_hash = rackHash;
    };
    _entityStamps.rackFarm.r1 = {
      tier = 3;
      label = "edge";
    };
  };
  compiledRack = denCompat.compile rackFixture;
  rackFleet = (denCompat.mkDen [ { config.den = rackFixture; } ]).den;

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
  # same bridge, NO host-kind declaration: the pre-registry byte-path — the grain absent, members
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
  flake.tests.compat-host-registry = {
    # the corpus's channel-driven instantiate default MATERIALIZES per host in the DECLARED registry:
    # the entry's evaluator and the channel table's nixosSystem agree by application (evaluator
    # identity, the pin-oracle structural check). Value IDENTICAL to the harvest-era golden.
    test-channel-default-materializes = {
      expr = {
        viaRegistry = registry.chan.instantiate probe;
        agreesWithTable = registry.chan.instantiate probe == channels.nixos-unstable.nixosSystem probe;
      };
      expected = {
        viaRegistry = {
          __chan = "nixos-unstable";
          probe = true;
        };
        agreesWithTable = true;
      };
    };
    # per-host channel selection: an explicit `channel = "nixpkgs-master"` resolves ITS evaluator.
    test-per-host-channel-selection = {
      expr = registry.master.instantiate probe;
      expected = {
        __chan = "nixpkgs-master";
        probe = true;
      };
    };
    # v1's base derivations materialize on the instance (entities/host.nix: name injected as the
    # attr key, system :64 = the GROUP key, class :65-67) — the fields the corpus module's defaults
    # read. `flatty` (a FLAT v1 host) was normalized into its system group by the registry's
    # preprocess (v1 _types.nix:157-170) and carries the same derivations.
    test-base-fields-materialize = {
      expr = {
        name = registry.chan.name;
        system = registry.chan.system;
        class = registry.chan.class;
        macClass = registry.mac.class;
        flattySystem = registry.flatty.system;
        flattyGrouped = applied.x86_64-linux ? flatty;
      };
      expected = {
        name = "chan";
        system = "x86_64-linux";
        class = "nixos";
        macClass = "darwin";
        flattySystem = "x86_64-linux";
        flattyGrouped = true;
      };
    };
    # the darwin branch of the corpus default (host.nix:326) selects darwinSystem — materialized,
    # though inert until the class-B arm stamps the wrapper on the darwin class.
    test-darwin-branch-materializes = {
      expr = registry.mac.instantiate probe;
      expected = {
        __chan = "nixos-unstable-darwin";
        probe = true;
      };
    };
    # PRIORITY interplay, authored half: an authored `instantiate` (definition priority 100) beats
    # the corpus's mkDefault (1000) — v1's exact interplay, NATIVE in the registry merge (nothing
    # hand-rolled; the deleted harvest reproduced this ladder by hand).
    test-priority-authored-wins = {
      expr = registry.authored.instantiate probe;
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
    # the corpus's settings MERGE materializes in the SAME registry eval: the aspect-declared option
    # DEFAULT (mountPoint) under the host-authored value (device_id) — v1's merged `host.settings`
    # view. Values IDENTICAL to the deleted harvest suite's settings-merge golden (byte-identity of
    # the behavior across the source swap).
    test-settings-merge-materializes = {
      expr = registry.chan.settings.disk.probe;
      expected = {
        device_id = "/dev/disk/by-id/probe-0001";
        mountPoint = "/var/lib/probe";
      };
    };
    # GENERALITY: the SAME eval materializes the other schema-declared per-host defaults —
    # `home-manager.module` (channel-driven, corpus host.nix:329-334) and `secretPath` (name-driven,
    # :319) — the entries hmModuleFor/secretPathFor read, no re-eval, no side harvest.
    test-generality-other-defaults = {
      expr = {
        hmModule = registry.chan.home-manager.module;
        hmModuleMaster = registry.master.home-manager.module;
        secretPath = registry.chan.secretPath;
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

    # ── the STRUCTURAL-EXCLUSION stamp (the ctx-entity record the bridge passes as `_entityStamps`) ──
    # the settings golden rides the STAMP with values IDENTICAL to the registry (and to the deleted
    # harvest golden) — the stamp is a passthrough, not a re-merge.
    test-stamp-settings-golden = {
      expr = stamps.chan.settings.disk.probe;
      expected = {
        device_id = "/dev/disk/by-id/probe-0001";
        mountPoint = "/var/lib/probe";
      };
    };
    # `facts` — the facter frontier's field — rides the stamp because its DECLARED TYPE is data
    # (nullOr str; corpus host.nix `facts` is nullOr path), with NO census list to appear on.
    test-stamp-facts-rides = {
      expr = {
        chan = stamps.chan.facts;
        secretPath = stamps.chan.secretPath;
        channel = stamps.chan.channel;
      };
      expected = {
        chan = "/facts/chan.json";
        secretPath = "/secrets/hosts/chan";
        channel = "nixos-unstable";
      };
    };
    # THE ABSENCE PIN (structural exclusion, dedicated): `instantiate` (types.raw — the evaluator)
    # and the `home-manager` group (both children raw — the module tree) are ABSENT from the stamp;
    # `microvm.guests` (listOf RAW — host entries, the deepSeq hazard) is excluded while its
    # data-typed SIBLING (passthrough, listOf str) rides — the partial-group rule. Identity
    # (`name`/`id_hash`) is never stamped (the den-hoag registry owns it).
    test-stamp-exclusion-absence = {
      expr = {
        hasInstantiate = stamps.chan ? instantiate;
        hasHomeManager = stamps.chan ? home-manager;
        hasName = stamps.chan ? name;
        microvm = stamps.chan.microvm or null;
      };
      expected = {
        hasInstantiate = false;
        hasHomeManager = false;
        hasName = false;
        microvm = {
          passthrough = [ ];
        };
      };
    };

    # ── INGEST: instantiateFor reads the host ENTRY (the registry view is `v1Decls.hosts` on the
    # bridge path — ONE source, no side harvest) ─────────────────────────────────────────────────
    test-ingest-reads-registry = {
      expr = (compiledRegistry.entities.instantiateFor chanEntry) probe;
      expected = {
        __chan = "nixos-unstable";
        probe = true;
      };
    };
    # no registry eval (mkDen-direct path, raw authored decls): instantiateFor stays null — the
    # pre-registry byte-identity guard.
    test-ingest-no-registry-null = {
      expr = compiledNoRegistry.entities.instantiateFor compiledNoRegistry.entities.registries.host.h1;
      expected = null;
    };
    # an entry whose id_hash is not a registered host (the synthetic-adjacent map-miss arm) is null,
    # never a throw.
    test-ingest-unknown-id-null = {
      expr = compiledRegistry.entities.instantiateFor { id_hash = "«not-a-host»"; };
      expected = null;
    };

    # ── KIND-GENERICITY (the passthrough is one mechanism over ANY kind) ─────────────────────────
    # a SYNTHETIC kind's stamps re-key by the marker-DISCOVERED namespace (`rackFarm` → kind `rack`),
    # its kind DECLARES the stamped fields (raw+null — identity unperturbed: the entry still resolves
    # by the same id_hash), and the built fleet's registry ENTRY — the ctx entity — carries them.
    test-synthetic-kind-passthrough = {
      expr = {
        entityFields = compiledRack.entities.entityFields.rack;
        kindDeclares = builtins.sort (a: b: a < b) (
          builtins.attrNames (compiledRack.entities.schema.rack.options or { })
        );
        fleetEntry = {
          inherit (rackFleet.registries.rack.r1) tier label;
        };
      };
      expected = {
        entityFields.r1 = {
          tier = 3;
          label = "edge";
        };
        kindDeclares = [
          "label"
          "tier"
        ];
        fleetEntry = {
          tier = 3;
          label = "edge";
        };
      };
    };

    # ── the M2 WIRING, end-to-end through the bridge ──────────────────────────────────────────────
    # a schema-defaulted host crosses nixosConfigurations through its OWN channel evaluator (the
    # registry grain WINS over the class terminal — here `collect`, no den.nixpkgs), with the
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
    # end-to-end arm cannot carry it yet): the registry is keyed by the REGISTERED hosts alone
    # (a synthetic name-match target gains no entry, hence no phantom grain — see also
    # test-ingest-unknown-id-null for the map-miss arm), and the member set is exactly the
    # registered hosts.
    test-bridge-synthetic-no-phantom = {
      expr = {
        registryKeys = builtins.attrNames registry;
        members = builtins.attrNames configs;
      };
      expected = {
        registryKeys = [
          "authored"
          "chan"
          "flatty"
          "mac"
          "master"
        ];
        members = [ "chan" ];
      };
    };
    # a fleet with NO host-kind declaration evaluates base-only (every default null): the grain is
    # absent and the member falls to `collect` — byte-path of the pre-registry bridge.
    test-bridge-no-schema-collect = {
      expr = configsNoSchema.plain.__terminal or null;
      expected = "collect";
    };
  };
}
