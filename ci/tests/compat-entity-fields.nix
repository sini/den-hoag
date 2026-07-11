# REAL-NODE ENTITY-FIELD COVERAGE (ship-gate). v1 binds the FULL host config as the policy ctx entity, so a
# dispatch body reads `host.system`/`host.class` off it directly (nix-config classes/home-platform.nix:29 —
# `lib.hasPrefix "aarch64-" host.system`, a HARD read with no `or` fallback). den-hoag entities are field-less,
# so the shim must reproduce those STRUCTURAL fields on the entry: ingest.nix `buildSchema` declares them as
# host-kind `options` and flake-module.nix `instanceConfig` stamps them from ingest's `entityFields`
# (the structural trio + the registry-passthrough stamp). C9 closed `class`; the `system` rung closed `system` (the demoted `den.hosts.<system>.<name>`
# path key); this rung closes `hostName` (v1 base-entity option `strOpt "Network hostname" config.name`, pin
# 11866c16 entities/host.nix:63 — the hostname battery reads it). The probe sentinel carries all three
# (`probeSentinelModule` {class, system, hostName}); the gap was the REAL entry.
#
# This is the END-TO-END witness through the FULL `mkDen` path: a home-platform-SHAPED value-conditional route
# (`hasPrefix "aarch64-" host.system`) fires at a real aarch64 host and is gated-empty at a real x86_64 host,
# and both stamped fields read their real values off the ctx entity. It fires at host scope — an equally real
# node where `host` is bound and `host.system` is read — rather than v1's user scope, because reproducing a
# user CELL (host bound at a user node) needs the full fleet membership machinery (env-users resolution +
# isEntity promotion); the user-scope firing is proven end-to-end by the frozen-corpus probe advancing past
# home-platform.nix:29. The probe-shape unit twin (value-less sentinel classification) lives in
# compat-policy-expansion `test-enriched-home-route-shapes`.
{ denCompat, nixpkgsLib, ... }:
let
  inherit (denCompat)
    mkDen
    include
    mkPolicy
    pipe
    compile
    ;
  inherit (nixpkgsLib) hasPrefix optional optionals;

  # The aspect the route gates in — resolved by name via compile.nix `resolveAspectRef` (`{ name }` arm).
  markerRef = {
    name = "aarch64-marker";
  };

  # The home-platform-SHAPED value-conditional route: reads `host.system` at DISPATCH with NO `or` fallback —
  # the exact hard-read shape of the frozen corpus. A field-less entry would throw uncatchably here, so a
  # passing routing assertion IS a field-presence proof. At the value-less stratum probe the sentinel
  # `system = "«probe»"` makes `hasPrefix` false → clean expansion (the fleet building proves it).
  markPolicy = mkPolicy "mark-aarch64" (
    { host, ... }: optional (hasPrefix "aarch64-" host.system) (include markerRef)
  );

  # A minimal v1-surface fleet: two hosts on DIFFERENT systems (the field the demoted path key becomes), the
  # route wired at host scope (den.schema.host.includes, where `host` is bound). Class is explicit on both.
  fleet =
    (mkDen [
      {
        config.den = {
          hosts.aarch64-linux.arm.class = "nixos";
          hosts.x86_64-linux.pc.class = "nixos";
          # `named` authors an EXPLICIT `hostName` (≠ its instance name) — v1's `hostName = strOpt
          # "Network hostname" config.name` (pin 11866c16 entities/host.nix:63) lets an author override the
          # name default. The stamp (`hostHostName = h.hostName or name`) must carry the override to the ctx.
          hosts.x86_64-linux.named = {
            class = "nixos";
            hostName = "custom-net";
          };
          aspects.aarch64-marker = { };
          schema.host.includes = [ markPolicy ];
        };
      }
    ]).den;

  eval = fleet.structural.eval;
  keysOf = id: map (n: n.key) (eval.get id "resolved-aspects");
  hasMarkerAt = id: builtins.elem "aarch64-marker" (keysOf id);
  # The ctx host entity as a dispatch body sees it — enriched-context binds the coord entities, `.host`
  # carrying the stamped structural fields (the exact value `{ host, ... }: … host.system` reads).
  ctxHostAt = id: (eval.get id "enriched-context").host;

  # ── broadcast-hub-peer settings-read pin (ledger u6 / u9) — the ctx entity carries v1's settings view
  #    (the bridge-registry passthrough: registry stampOf → `_entityStamps` → ingest `entityFields` →
  #    the instanceConfig stamp), so the corpus's
  #    `host.settings.core.network.syncthing.isHub or false` (nix-config policies/pipes.nix:166) reads
  #    the REAL value at dispatch (the u6 read gap, CLOSED). The now-LIVE firing branch emits a
  #    `pipe.from` — a value-conditional pipeOp. The SITE-MARK rung (this commit) recognizes it as per-
  #    node emission DATA: a broadcast site mark on a BARE channel ref (no deriving DAG, no route) is NOT
  #    a compose commitment, so it rides the `#collection` expansion sub-rule (`declare.isSiteMarkData`)
  #    and the hub node RESOLVES CLEAN — u6's LOUD named abort is now GONE (the corpus re-probe frontier
  #    at `__kindInclude__host__policy__11` clears). The site marks are still UNCONSUMED by lib wiring
  #    (ledger u9); delivery is the next rung. The in-pipe broadcast PREDICATES (pipes.nix:147,157 —
  #    settings reads INSIDE an unconditionally-seeded `pipe.from` body) are served by the stamp.
  hubBody =
    { host, ... }:
    optionals (host.settings.core.network.syncthing.isHub or false) [
      (pipe.from "syncthing-peers" [ (pipe.broadcast ({ user, ... }: true)) ])
    ];
  # The corpus hub declaration, verbatim idiom (hosts/uplink.nix:26) — PLUS the rest of the stamped
  # field set. The ctx-entity stamp is REGISTRY-SOURCED (the bridge-registry passthrough): the fixture
  # builds `_entityStamps.hosts` with the REAL registry machinery (denCompat.registry — mkHostsOption
  # over a corpus-shaped kind module, stampTreeOf/stampOf), exactly what the bridge computes and
  # passes; mkDen-direct fleets carry NO stamps otherwise (the raw-authored census fallback died with
  # the census). `bare` authors nothing — the registry materializes its option defaults.
  hubHostDecls = {
    hosts.x86_64-linux = {
      hub = {
        class = "nixos";
        settings.core.network.syncthing.isHub = true;
        environment = "prod";
        networking.interfaces.eth0.ipv4 = [ "10.0.0.1/24" ];
        secretPath = "/secrets/hosts/hub";
        public_key = "/secrets/hosts/hub/key.pub";
        system-owner = "op";
      };
      bare = {
        class = "nixos";
      };
    };
  };
  # The corpus-shaped host kind module (nix-config schema/host.nix): the dynamic settings namespace
  # (typed tree with the aspect-declared `isHub` default, :301-309), typed networking (:207-249), the
  # scalar fields, and the COMPUTED readOnly `ipv4` (:181-194 — never authored; ONLY the registry
  # carries it, the harvest-era "fallback ceiling" now a real value).
  fieldKindModule =
    { config, ... }:
    let
      inherit (nixpkgsLib) mkOption types;
      sub =
        opts:
        mkOption {
          type = types.submodule { options = opts; };
          default = { };
        };
      strOpt = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    in
    {
      options = {
        settings = sub {
          core = sub {
            network = sub {
              syncthing = sub {
                isHub = mkOption {
                  type = types.bool;
                  default = false;
                };
              };
            };
          };
        };
        networking = mkOption {
          type = types.attrsOf (types.attrsOf (types.attrsOf (types.listOf types.str)));
          default = { };
        };
        environment = strOpt;
        secretPath = strOpt;
        public_key = strOpt;
        system-owner = strOpt;
        ipv4 = mkOption {
          type = types.listOf types.str;
          readOnly = true;
        };
      };
      config.ipv4 = builtins.concatLists (
        map (i: i.ipv4 or [ ]) (builtins.attrValues (config.networking.interfaces or { }))
      );
    };
  registryLib = denCompat.registry;
  hubStampTree = registryLib.stampTreeOf (
    registryLib.hostInstanceOptions {
      lib = nixpkgsLib;
      kindModule = fieldKindModule;
    }
  );
  hubApplied =
    (registryLib.mkHostsOption {
      lib = nixpkgsLib;
      kindModule = fieldKindModule;
    }).apply
      hubHostDecls.hosts;
  hubStamps = builtins.mapAttrs (_: e: registryLib.stampOf hubStampTree e) (
    registryLib.flattenRegistry hubApplied
  );
  settingsFleet =
    (mkDen [
      {
        config.den = hubHostDecls // {
          policies.broadcast-hub-peer = mkPolicy "broadcast-hub-peer" hubBody;
          _entityStamps.hosts = hubStamps;
        };
      }
    ]).den;
  settingsCompiled = compile hubHostDecls;
in
{
  flake.tests.compat-entity-fields = {
    # (a) — the route FIRES at the aarch64 host (real `system` stamped, `hasPrefix` true → include).
    test-aarch64-route-fires = {
      expr = hasMarkerAt "host:arm";
      expected = true;
    };
    # (a) — and is GATED-EMPTY at the x86_64 host (real `system` = x86_64-linux, `hasPrefix` false → []).
    test-x86-route-gated-empty = {
      expr = hasMarkerAt "host:pc";
      expected = false;
    };

    # (b) — the stamped `system`/`hostName` (and pre-existing `class` + built-in `name`) are present on the
    #       REAL aarch64 host ctx entity at dispatch, carrying their real values (not the probe sentinel).
    #       `hostName` defaults to the instance name (v1 `strOpt "Network hostname" config.name`).
    test-arm-entity-fields = {
      expr =
        let
          h = ctxHostAt "host:arm";
        in
        {
          inherit (h)
            system
            class
            name
            hostName
            ;
        };
      expected = {
        system = "aarch64-linux";
        class = "nixos";
        name = "arm";
        hostName = "arm";
      };
    };
    # (b) — the x86_64 host entry carries its own distinct `system` (a per-host field, not a fleet constant)
    #       and its name-defaulted `hostName`.
    test-pc-entity-fields = {
      expr =
        let
          h = ctxHostAt "host:pc";
        in
        {
          inherit (h)
            system
            class
            name
            hostName
            ;
        };
      expected = {
        system = "x86_64-linux";
        class = "nixos";
        name = "pc";
        hostName = "pc";
      };
    };
    # (b/override) — `named` authored `hostName = "custom-net"` ≠ its instance name; the stamp carries the
    #       override to the ctx entity (v1 def-priority: authored beats the `config.name` base default).
    test-named-hostName-override = {
      expr =
        let
          h = ctxHostAt "host:named";
        in
        {
          inherit (h) name hostName;
        };
      expected = {
        name = "named";
        hostName = "custom-net";
      };
    };

    # (u6/u9 pin — the host-settings entity-stamp rung + the SITE-MARK rung) four facts pinned:
    #   realCtxCarriesSettings — the REAL ctx entity carries the settings view (the REGISTRY-sourced
    #     stamp — `_entityStamps.hosts` built by the real registry machinery), so the u6 read gap is
    #     CLOSED;
    #   bodyFiresAtRealCtx — the corpus body applied to the REAL ctx entity takes the FIRING branch and
    #     emits the syncthing-peers pipe effect (v1's dispatch-time read, restored at the ctx level);
    #   firingNodeResolvesClean — the SITE-MARK rung: the fired emission is a pure SITE-MARK pipeOp
    #     (broadcast mark on a bare channel ref), recognized as per-node DATA by `declare.isSiteMarkData`
    #     and allowed through the `#collection` expansion sub-rule, so the hub node RESOLVES CLEAN —
    #     u6's LOUD named abort is GONE (the corpus re-probe frontier clears). Site marks stay UNCONSUMED
    #     by lib wiring (ledger u9); delivery is the next rung (this pin flips again when it lands);
    #   declaredLayerIngestKnown — the host-FILE-declared settings layer stays ingest-visible raw data
    #     (`entities.instances.host.hub.settings…`), unchanged input surface;
    #   (the field-set coverage twin is test-stamped-field-set below.)
    test-settings-read-policy-fires = {
      expr =
        let
          realHubCtx = (settingsFleet.structural.eval.get "host:hub" "enriched-context").host;
          r = hubBody { host = realHubCtx; };
        in
        {
          realCtxCarriesSettings = realHubCtx.settings.core.network.syncthing.isHub or false;
          bodyFiresAtRealCtx =
            builtins.length r == 1
            && (builtins.head r).__policyEffect == "pipe"
            && (builtins.head r).value.pipeName == "syncthing-peers";
          firingNodeResolvesClean =
            (builtins.tryEval (
              builtins.deepSeq (map (n: n.key) (
                settingsFleet.structural.eval.get "host:hub" "resolved-aspects"
              )) true
            )).success;
          declaredLayerIngestKnown =
            settingsCompiled.entities.instances.host.hub.settings.core.network.syncthing.isHub;
        };
      expected = {
        realCtxCarriesSettings = true;
        bodyFiresAtRealCtx = true;
        firingNodeResolvesClean = true;
        declaredLayerIngestKnown = true;
      };
    };

    # (field-set coverage) — the full REGISTRY-stamped field record rides the ctx entity with its real
    # per-host values (goldens IDENTICAL to the harvest-era pins). `ipv4` is a corpus-COMPUTED field
    # (schema/host.nix:181-194, readOnly — never authored; ONLY the registry carries it): the stamp
    # now carries the REAL computed value where the census-fallback era pinned null — the honest
    # ceiling upgraded to the v1 value.
    test-stamped-field-set = {
      expr =
        let
          h = (settingsFleet.structural.eval.get "host:hub" "enriched-context").host;
        in
        {
          environment = h.environment;
          networking = h.networking;
          secretPath = h.secretPath;
          public_key = h.public_key;
          systemOwner = h.system-owner;
          ipv4Computed = h.ipv4;
        };
      expected = {
        environment = "prod";
        networking.interfaces.eth0.ipv4 = [ "10.0.0.1/24" ];
        secretPath = "/secrets/hosts/hub";
        public_key = "/secrets/hosts/hub/key.pub";
        systemOwner = "op";
        ipv4Computed = [ "10.0.0.1/24" ];
      };
    };

    # (the unauthored default) — a host declaring NO settings carries v1's MATERIALIZED settingsType
    # view (the aspect-declared defaults tree, corpus host.nix:301-309 — the registry materializes it;
    # the census era pinned the `{ }` shim fallback instead): soft `or`-reads read the REAL default,
    # and the namespace is present (never a missing-attribute throw on the `host.settings` spine).
    test-unauthored-settings-defaults = {
      expr =
        let
          h = (settingsFleet.structural.eval.get "host:bare" "enriched-context").host;
        in
        {
          settings = h.settings;
          softReadDegrades = h.settings.core.network.syncthing.isHub or "absent";
        };
      expected = {
        settings.core.network.syncthing.isHub = false;
        softReadDegrades = false;
      };
    };

    # THE STRUCTURAL-EXCLUSION ABSENCE PIN, end-to-end (the registry stamp's deepSeq law at the REAL
    # ctx entity): `instantiate` (the evaluator) and `home-manager` (the module tree) — both
    # `types.raw` — are ABSENT from the dispatched entity, while the data fields ride. The
    # resolution-state deepSeq (this fleet resolves) is itself the no-heavy-closure witness.
    test-ctx-entity-structural-exclusion = {
      expr =
        let
          h = (settingsFleet.structural.eval.get "host:hub" "enriched-context").host;
        in
        {
          hasInstantiate = h ? instantiate;
          hasHomeManager = h ? home-manager;
          hasSettings = h ? settings;
        };
      expected = {
        hasInstantiate = false;
        hasHomeManager = false;
        hasSettings = true;
      };
    };
  };
}
