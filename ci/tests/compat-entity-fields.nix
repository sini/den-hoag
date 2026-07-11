# REAL-NODE ENTITY-FIELD COVERAGE (ship-gate). v1 binds the FULL host config as the policy ctx entity, so a
# dispatch body reads `host.system`/`host.class` off it directly (nix-config classes/home-platform.nix:29 —
# `lib.hasPrefix "aarch64-" host.system`, a HARD read with no `or` fallback). den-hoag entities are field-less,
# so the shim must reproduce those STRUCTURAL fields on the entry: ingest.nix `buildSchema` declares them as
# host-kind `options` and flake-module.nix `instanceConfig` stamps them from the `hostClassName`/`hostSystemName`/
# `hostHostName` maps. C9 closed `class`; the `system` rung closed `system` (the demoted `den.hosts.<system>.<name>`
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

  # ── broadcast-hub-peer settings-read pin (ledger u6 / board #59) — FLIPPED by the host-settings
  #    entity-stamp rung. The ctx entity now CARRIES v1's settings view (ingest.nix
  #    `harvestedHostFields` → `hostEntityFields` → the instanceConfig stamp; harvest-first, raw
  #    authored fallback on this harvest-less mkDen-direct path), so the corpus's
  #    `host.settings.core.network.syncthing.isHub or false` (nix-config policies/pipes.nix:166) reads
  #    the REAL value at dispatch — the u6 silent degradation is CLOSED at the read. RESIDUAL
  #    (self-announcing, pinned below): broadcast-hub-peer is a VALUE-CONDITIONAL policy whose firing
  #    branch emits a `pipe.from` — the fleet pipe compose DAG seeds pre-eval from ctx-INDEPENDENT
  #    bodies (the concern-policies pipeOp law), so the now-live emission aborts NAMED at the hub node:
  #    u6's announcement class upgraded from SILENT-wrong-content to LOUD named abort. The late pipe
  #    contribution (v1 fires pipe stages scope-local wherever a policy fires) is the #59 dispatch-time
  #    remainder. The in-pipe broadcast PREDICATES (pipes.nix:147,157 — settings reads INSIDE an
  #    unconditionally-seeded `pipe.from` body) are fully served by the stamp.
  hubBody =
    { host, ... }:
    optionals (host.settings.core.network.syncthing.isHub or false) [
      (pipe.from "syncthing-peers" [ (pipe.broadcast ({ user, ... }: true)) ])
    ];
  # The corpus hub declaration, verbatim idiom (hosts/uplink.nix:26) — PLUS the rest of the stamped
  # field set (board #59, authored raw here: mkDen-direct has no harvest, so the stamp falls back to
  # the authored fields — the same values a harvest would carry for authored-only fields).
  hubHostDecls = {
    hosts.x86_64-linux.hub = {
      class = "nixos";
      settings.core.network.syncthing.isHub = true;
      environment = "prod";
      networking.interfaces.eth0.ipv4 = [ "10.0.0.1/24" ];
      secretPath = "/secrets/hosts/hub";
      public_key = "/secrets/hosts/hub/key.pub";
      system-owner = "op";
    };
  };
  settingsFleet =
    (mkDen [
      {
        config.den = hubHostDecls // {
          policies.broadcast-hub-peer = mkPolicy "broadcast-hub-peer" hubBody;
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

    # (u6/#59 pin, FLIPPED — the host-settings entity-stamp rung) five facts pinned:
    #   realCtxCarriesSettings — the REAL ctx entity now carries the settings view (the stamp; here the
    #     raw authored fallback — mkDen-direct has no harvest), so the u6 read gap is CLOSED;
    #   bodyFiresAtRealCtx — the corpus body applied to the REAL ctx entity takes the FIRING branch and
    #     emits the syncthing-peers pipe effect (v1's dispatch-time read, restored at the ctx level);
    #   firingNodeAbortsNamed — the RESIDUAL, self-announcing: the fired emission is a pipeOp from a
    #     VALUE-CONDITIONAL policy, which the pre-eval pipe-DAG seeding law rejects NAMED (catchable
    #     throw) — u6's silent-wrong-content upgraded to a LOUD abort; the late pipe contribution is
    #     the #59 dispatch-time remainder (this pin flips again when it lands);
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
          firingNodeAbortsNamed =
            !(builtins.tryEval (
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
        firingNodeAbortsNamed = true;
        declaredLayerIngestKnown = true;
      };
    };

    # (board #59, field-set coverage) — the full harvest-carried field record rides the ctx entity with
    # its real per-host values (raw authored fallback on this mkDen-direct path). `ipv4`/`ipv6` are
    # corpus-COMPUTED fields (schema/host.nix:181-206, readOnly — only a harvest carries them), so on
    # the harvest-less path they pin to the null fallback — the honest fallback ceiling.
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
          ipv4NullWithoutHarvest = h.ipv4 == null && h.ipv6 == null;
        };
      expected = {
        environment = "prod";
        networking.interfaces.eth0.ipv4 = [ "10.0.0.1/24" ];
        secretPath = "/secrets/hosts/hub";
        public_key = "/secrets/hosts/hub/key.pub";
        systemOwner = "op";
        ipv4NullWithoutHarvest = true;
      };
    };

    # (board #59, the unauthored default) — a host declaring NO settings carries the `{ }` fallback
    # (v1's empty settingsType default, corpus host.nix:304): soft `or`-reads degrade cleanly, and the
    # namespace is present (never a missing-attribute throw on the `host.settings` spine itself).
    test-unauthored-settings-empty = {
      expr =
        let
          h = ctxHostAt "host:pc";
        in
        {
          settings = h.settings;
          softReadDegrades = h.settings.core.network.syncthing.isHub or "absent";
        };
      expected = {
        settings = { };
        softReadDegrades = "absent";
      };
    };
  };
}
