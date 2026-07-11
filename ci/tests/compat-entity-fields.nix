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

  # ── broadcast-hub-peer settings-read PIN (ledger u6 / board #59) — the SOFT-read twin of the hard-read
  #    class the `system` stamp closed. The corpus gates the hub-peer broadcast on
  #    `host.settings.core.network.syncthing.isHub or false` (nix-config policies/pipes.nix:166) — a
  #    DISPATCH-time read of the host's SETTINGS off the ctx entity. v1 binds the full host config as ctx
  #    (the corpus declares `isHub = true` on the hub host's RAW config, hosts/uplink.nix:26), so the read
  #    is LIVE there; the shim's ctx entity carries ONLY the static stamped fields — the `or false` read
  #    silently degrades and the broadcast NEVER fires where v1 fires it. A hard bare-field read fails
  #    LOUD (self-announcing); this `or`-guarded read is the SILENT half, hence the pin. LOUD PIN: if #59
  #    lands (resolved settings on the ctx entity, or a static declared-layer derivation),
  #    `bodyDegradesAtStampedShape`/`realCtxLacksSettings` FLIP — update this test with ledger row u6.
  hubBody =
    { host, ... }:
    optionals (host.settings.core.network.syncthing.isHub or false) [
      (pipe.from "syncthing-peers" [ (pipe.broadcast ({ user, ... }: true)) ])
    ];
  # The EXACT shape the shim's real ctx host entity has today: the static stamped fields, no `settings`.
  stampedShapeCtx = {
    host = {
      id_hash = "h";
      name = "hub";
      class = "nixos";
      system = "x86_64-linux";
    };
  };
  # The corpus hub declaration, verbatim idiom (hosts/uplink.nix:26): the host FILE sets the settings value
  # on the raw host config. The declared layer is INGEST-KNOWN raw data (`flatHosts.hub.settings` — pinned
  # below), yet it does NOT reach the ctx entity — that gap is exactly what #59 adjudicates.
  hubHostDecls = {
    hosts.x86_64-linux.hub = {
      class = "nixos";
      settings.core.network.syncthing.isHub = true;
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

    # (u6/#59 pin) — the broadcast-hub-peer settings-read degrades SILENTLY today. Five facts pinned:
    #   bodyDegradesAtStampedShape — at the shim's real ctx shape (static fields, no settings) the `or
    #     false` gate reads false → the body emits NOTHING (the degraded branch, current behavior);
    #   bodyFiresWithSettings — with `settings…isHub = true` ON the ctx entity the SAME body emits the
    #     syncthing-peers pipe effect (the gap IS the missing settings view, nothing else);
    #   realCtxLacksSettings — at a REAL node whose host config declares `isHub = true` corpus-style, the
    #     ctx entity still carries NO `settings` (so the real dispatch takes the degraded branch);
    #   resolvesSilently — the degraded node resolves CLEAN (no throw): silent, NOT self-announcing —
    #     why this needs a ledger row + drv-hash verification rather than a loud abort;
    #   declaredLayerIngestKnown — the host-FILE-declared settings layer IS ingest-visible raw data
    #     (`entities.instances.host.hub.settings…`), the #59 static-derivation candidate's input.
    test-settings-read-policy-degrades = {
      expr = {
        bodyDegradesAtStampedShape = hubBody stampedShapeCtx == [ ];
        bodyFiresWithSettings =
          let
            r = hubBody (
              stampedShapeCtx
              // {
                host = stampedShapeCtx.host // {
                  settings.core.network.syncthing.isHub = true;
                };
              }
            );
          in
          builtins.length r == 1
          && (builtins.head r).__policyEffect == "pipe"
          && (builtins.head r).value.pipeName == "syncthing-peers";
        realCtxLacksSettings =
          !((settingsFleet.structural.eval.get "host:hub" "enriched-context").host ? settings);
        resolvesSilently =
          (builtins.tryEval (
            builtins.deepSeq (map (n: n.key) (
              settingsFleet.structural.eval.get "host:hub" "resolved-aspects"
            )) true
          )).success;
        declaredLayerIngestKnown =
          settingsCompiled.entities.instances.host.hub.settings.core.network.syncthing.isHub;
      };
      expected = {
        bodyDegradesAtStampedShape = true;
        bodyFiresWithSettings = true;
        realCtxLacksSettings = true;
        resolvesSilently = true;
        declaredLayerIngestKnown = true;
      };
    };
  };
}
