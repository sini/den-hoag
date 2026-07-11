# hmModuleFor — the home-manager HOST-MODULE import, compile-side (ship-gate R6). den v1's hm battery
# imports the host's `home-manager.module` (the home-manager NixOS module) into the host class-module via a
# KEYED import (pin nix/lib/home-env.nix:74-86 `${host.class}.imports = [{ key = "den:home-manager-host-
# module"; imports = [ host.home-manager.module ]; }]`), so a HOST-scope aspect emitting `home-manager.*`
# content typechecks (corpus agenixHostAspect `home-manager.sharedModules`, batteries/agenix.nix:87 — the
# u9 re-probe frontier: "The option `home-manager' does not exist"). den-hoag can't reproduce the battery as
# an aspect: the module is a nixpkgs closure, excluded from deepSeq'd resolution state (ingest.nix:56-58,
# the `instantiate` invariant), so it rides the compile-side `hmModuleFor` id_hash map (twin of
# instantiateFor) and is IMPORTED terminal-side (the compat nixos wrapper, flake-module.nix mkNixosInstantiate).
#
# THE GATE (ingest.nix `hmModuleByHostId`): MODULE-PRESENCE + an explicit authored `home-manager.enable =
# false` opt-out. v1's `hostHasClass` (host-has-user-with-class — ≥1 hm user) is a DOCUMENTED CEILING: the
# corpus binds users via the STUBBED env fan-out (board #49), so the compat membership is empty for every
# corpus host; gating on it would suppress the import on every corpus host and defeat the rung. Across the
# corpus module-presence ⟺ v1's enable (every channel host has ≥1 hm user in v1). Witness 7 pins the ceiling.
#
# Two arms: (A) the ingest GRAIN via `denCompat.compile` (source invariant, gate, map-miss, ceiling); (B)
# the terminal WIRING via `denCompat.mkDenWith` — the keyed import lands in the host's modules AND the
# frontier's emit typechecks with the import / throws without it (the fix vs the unfixed frontier).
{
  denCompat,
  nixpkgsLib,
  ...
}:
let
  forceThrows = e: !(builtins.tryEval (builtins.deepSeq e null)).success;

  # ── (A) the ingest grain ─────────────────────────────────────────────────────────────────────────
  # value-identity golden: the harvested channel-resolved module (the `_hostHarvest.<h>.home-manager
  # .module` the corpus's kind module materializes, host.nix:329-334) is what hmModuleFor returns.
  compiledHarvest = denCompat.compile {
    hosts.x86_64-linux.h1 = { };
    _hostHarvest.h1.home-manager.module = {
      __hm = "chan";
    };
  };
  h1 = compiledHarvest.entities.registries.host.h1;

  # harvest-first: a host authoring a raw `home-manager.module` AND carrying a harvest → the HARVEST wins
  # (the harvest already folded the authored def at priority 100; the source invariant).
  compiledBoth = denCompat.compile {
    hosts.x86_64-linux.h2 = {
      home-manager.module = {
        __raw = true;
      };
    };
    _hostHarvest.h2.home-manager.module = {
      __hm = "chan";
    };
  };
  h2 = compiledBoth.entities.registries.host.h2;

  # raw fallback: NO harvest (mkDen-direct) → the authored field is the source.
  compiledRaw = denCompat.compile {
    hosts.x86_64-linux.h3 = {
      home-manager.module = {
        __raw = true;
      };
    };
  };
  h3 = compiledRaw.entities.registries.host.h3;

  # hm-less host: neither harvest nor authored module → null (no import, drv unshifted).
  compiledNone = denCompat.compile {
    hosts.x86_64-linux.h4 = { };
  };
  h4 = compiledNone.entities.registries.host.h4;

  # explicit disable: a module present but `home-manager.enable = false` → null (v1's explicit opt-out).
  compiledDisabled = denCompat.compile {
    hosts.x86_64-linux.h5 = {
      home-manager = {
        module = {
          __raw = true;
        };
        enable = false;
      };
    };
  };
  h5 = compiledDisabled.entities.registries.host.h5;

  # ── (B) the terminal wiring ──────────────────────────────────────────────────────────────────────
  # A reflect terminal exposes the host's assembled modules so the keyed import is inspectable.
  reflectTerminal = args: {
    __modules = args.hostModules;
  };
  hasHmKey =
    mods:
    builtins.any (
      m:
      builtins.isAttrs m
      && (m.imports or null) != null
      && builtins.any (
        i: builtins.isAttrs i && (i.key or null) == "den:home-manager-host-module"
      ) m.imports
    ) mods;
  # the inner `imports` of the keyed import module (v1's `imports = [ host.home-manager.module ]`).
  hmImportsOf =
    mods:
    let
      km = builtins.head (
        builtins.filter (
          m:
          builtins.isAttrs m
          && (m.imports or null) != null
          && builtins.any (i: (i.key or null) == "den:home-manager-host-module") m.imports
        ) mods
      );
      keyed = builtins.head (
        builtins.filter (i: (i.key or null) == "den:home-manager-host-module") km.imports
      );
    in
    keyed.imports;

  keyFixture = {
    den.hosts.x86_64-linux = {
      # authors a raw home-manager.module (mkDen-direct) → hmModuleFor non-null → keyed import.
      wk."home-manager".module = {
        __mod = true;
      };
      # no module → hmModuleFor null → no import.
      wn = { };
    };
    # self-named aspects give each host real nixos content so the terminal is invoked (the compat pattern).
    den.aspects.wk.nixos.marker = "x";
    den.aspects.wn.nixos.marker = "y";
  };
  fleetK = denCompat.mkDenWith [ keyFixture ] { nixosTerminal = reflectTerminal; };
  configsK = fleetK.nixosConfigurations;

  # THE FRONTIER, reproduced at the terminal. A stub "home-manager NixOS module" declaring the
  # `home-manager.sharedModules` option (the option the frontier reports missing); an aspect emits the
  # agenix-shape content into the host's nixos class. The evalTerminal is the lightweight stand-in for a
  # real nixosSystem: it evalModules the host's modules (+ a nixpkgs.hostPlatform.system stub for the
  # systemFor injection) and returns the config. With the hm module imported the emit typechecks; without
  # it, the SAME emit throws "option home-manager does not exist" — the u9 frontier.
  hmStub =
    { lib, ... }:
    {
      options.home-manager.sharedModules = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
      };
    };
  evalTerminal =
    args:
    (nixpkgsLib.evalModules {
      modules = args.hostModules ++ [
        {
          options.nixpkgs.hostPlatform.system = nixpkgsLib.mkOption {
            type = nixpkgsLib.types.raw;
            default = null;
          };
        }
      ];
    }).config;
  emitFixture = {
    den.hosts.x86_64-linux = {
      withHm."home-manager".module = hmStub;
      noHm = { };
    };
    den.aspects.withHm.nixos = _: {
      home-manager.sharedModules = [ "agenix-marker" ];
    };
    den.aspects.noHm.nixos = _: {
      home-manager.sharedModules = [ "agenix-marker" ];
    };
  };
  fleetE = denCompat.mkDenWith [ emitFixture ] { nixosTerminal = evalTerminal; };
  configsE = fleetE.nixosConfigurations;
in
{
  flake.tests.compat-hm-module = {
    # (A1) value-identity golden — hmModuleFor == the harvested channel module (the instantiateFor twin).
    test-value-identity-golden = {
      expr = compiledHarvest.entities.hmModuleFor h1;
      expected = {
        __hm = "chan";
      };
    };
    # (A2) harvest-first source invariant — harvest wins over the raw authored field.
    test-harvest-first = {
      expr = compiledBoth.entities.hmModuleFor h2;
      expected = {
        __hm = "chan";
      };
    };
    # (A3) raw fallback — no harvest (mkDen-direct) reads the authored field.
    test-raw-fallback = {
      expr = compiledRaw.entities.hmModuleFor h3;
      expected = {
        __raw = true;
      };
    };
    # (A4) hm-less host → null (gated-null: no module ⇒ no import).
    test-hm-less-null = {
      expr = compiledNone.entities.hmModuleFor h4;
      expected = null;
    };
    # (A5) explicit `home-manager.enable = false` → null (v1's explicit opt-out; corpus-inert).
    test-explicit-disable-null = {
      expr = compiledDisabled.entities.hmModuleFor h5;
      expected = null;
    };
    # (A6) map-miss (an id_hash that is not a registered host) → null, never a throw (the systemFor/
    # instantiateFor synthetic-adjacent arm).
    test-unknown-id-null = {
      expr = compiledNone.entities.hmModuleFor { id_hash = "«not-a-host»"; };
      expected = null;
    };
    # (A7) THE CEILING — module-presence, NOT user membership: h3 has a module and ZERO user members, yet
    # hmModuleFor is non-null (the corpus-frontier-clearing gate). Membership is empty (no den.homes /
    # host.users), so a membership gate would suppress it — this is why the gate is module-presence.
    test-membership-independent-ceiling = {
      expr = {
        nonNull = compiledRaw.entities.hmModuleFor h3 != null;
        noMembers = compiledRaw.entities.membership == [ ];
      };
      expected = {
        nonNull = true;
        noMembers = true;
      };
    };

    # (B1) the keyed import lands — the host with a module carries v1's exact `key` string, wrapping
    # exactly `[ host.home-manager.module ]`.
    test-keyed-import-present = {
      expr = {
        present = hasHmKey configsK.wk.__modules;
        wraps = hmImportsOf configsK.wk.__modules;
      };
      expected = {
        present = true;
        wraps = [
          {
            __mod = true;
          }
        ];
      };
    };
    # (B2) no import for an hm-less host — its module list carries no keyed import.
    test-no-import-hm-less = {
      expr = hasHmKey configsK.wn.__modules;
      expected = false;
    };
    # (B3) THE FIX — with the hm module imported, the agenix-shape `home-manager.sharedModules` emit
    # typechecks and lands (the frontier cleared).
    test-emit-typechecks-with-import = {
      expr = configsE.withHm.home-manager.sharedModules;
      expected = [ "agenix-marker" ];
    };
    # (B4) THE FRONTIER, unfixed — the SAME emit WITHOUT the hm import throws "option home-manager does
    # not exist" (self-announcing; the u9 re-probe error, reproduced in a unit).
    test-emit-throws-without-import = {
      expr = forceThrows configsE.noHm;
      expected = true;
    };
  };
}
