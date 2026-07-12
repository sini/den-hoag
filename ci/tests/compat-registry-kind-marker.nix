# NON-HOST REGISTRY INGEST (user-delivery R3) — the OPTION-reflecting kind marker (registry.nix
# `registryKindOf`/`identityKeysOf`) that lets a consumer-declared registry whose instances carry a
# DERIVED/INTERNAL primitive reach the fleet as ROOT entities.
#
# THE GAP this closes (ground-truth: nix-config @ b0b20769, `den.clusters.axon`): ingest's custom-kind
# discovery matched a namespace to its kind by recomputing the instance's id_hash through gen-schema's
# VALUE-reflecting `identityHashFor`. That reflection over-includes ANY primitive-VALUED field — so a
# kind carrying a derived/internal primitive (the corpus `cluster.sopsAgeRecipient`: a `readFile`
# string, `internal`) makes the recompute MISS the carried id_hash (which `mkIdentityModule` stamped
# EXCLUDING the internal field). The namespace then matched NO kind → `customInstances`/
# `registries.<kind>` stayed EMPTY → no env/cluster ROOT NODES → the staged env phase never ran. The
# DECLARED option surface carries what the value cannot (`internal`/`identity` flags); the
# OPTION-reflecting marker reflects the SAME primitive set `mkIdentityModule` hashed, so it resolves the
# namespace the value-reflecting marker misses. Computed at the bridge (option surface), it rides to
# ingest as `_registryKinds` and re-keys the passthrough stamps + builds the custom-kind registries.
#
# The `zone` kind reproduces the shape: `region` (a normal identity primitive) + `sopsTag` (a bare
# primitive marked `internal` — the sopsAgeRecipient twin, isolating the identity-FLAG exclusion). The
# suite pins: (a) `identityKeysOf` EXCLUDES the internal primitive; (b) the value-reflecting marker
# MISSES while `registryKindOf` HITS; (c) end-to-end the marker-keyed registry reaches the fleet as a
# root entity (name + `sha256("zone|name=<n>")` id_hash + the stamped fields), where the value-marker
# fallback alone leaves it empty; (d) genericity — a kind name the shim never spells.
{
  lib,
  denCompat,
  denHoag,
  ...
}:
let
  schema = denHoag.internal.schema;
  # The carried id_hash `mkIdentityModule` stamps: over the IDENTITY primitives (region + the injected
  # name), NEVER the internal `sopsTag`. `identityHashFor` over a name/region-only record reflects
  # exactly those two primitives — the same content-address the option-reflecting marker must reproduce.
  idFor = name: region: schema.identityHashFor "zone" { inherit name region; };

  # The consumer-declared registry — a PURE nixpkgs submodule (the shape a `mkInstanceRegistry` option
  # presents to the bridge's `getSubOptions`): `region` (identity) + `sopsTag` (internal, materialized
  # to a string, so `identityHashFor` over-includes it while `mkIdentityModule`/the carried hash do not).
  zoneModule =
    {
      name,
      config,
      ...
    }:
    {
      options.name = lib.mkOption {
        type = lib.types.str;
        default = name;
      };
      options.id_hash = lib.mkOption {
        type = lib.types.str;
        default = idFor name config.region;
      };
      options.region = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      options.sopsTag = lib.mkOption {
        type = lib.types.str;
        default = "";
        internal = true;
      };
    };
  ev = lib.evalModules {
    modules = [
      {
        options.den.zones = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.submoduleWith { modules = [ zoneModule ]; });
        };
      }
      {
        den.zones.z1 = {
          region = "west";
          sopsTag = "computed-west";
        };
      }
    ];
  };
  z1inst = ev.config.den.zones.z1;

  # The instance option surface the bridge reads (`subOptionsOf` → `type.getSubOptions`).
  zoneOpts = ev.options.den.zones.type.getSubOptions [
    "den"
    "zones"
  ];
  zoneTree = denCompat.registry.stampTreeOf zoneOpts;
  zoneStamps = builtins.mapAttrs (_: e: denCompat.registry.stampOf zoneTree e) ev.config.den.zones;

  # The robust marker (option-reflecting) — the bridge computes exactly this per consumer namespace.
  markerKind = denCompat.registry.registryKindOf {
    opts = zoneOpts;
    instances = ev.config.den.zones;
    candidateKinds = [
      "zone"
      "host"
      "user"
    ];
    inherit (schema) hashIdentity;
  };

  # End-to-end WITH the bridge marker map (`_registryKinds`): the namespace re-keys to kind `zone` and
  # the registry reaches the fleet as a ROOT entity (parentless kind → a root scope kind).
  withMarker =
    (denCompat.mkDen [
      {
        config.den = {
          schema.zone.parent = null;
          zones = ev.config.den.zones;
          _entityStamps.zones = zoneStamps;
          _registryKinds.zones = "zone";
        };
      }
    ]).den;

  # End-to-end WITHOUT the marker map: ingest falls back to the VALUE-reflecting id_hash discovery,
  # which MISSES (sopsTag over-includes) → `zones` maps to no kind → `registries.zone` stays EMPTY (the
  # pre-fix behavior). `zones` rides `_declaredKeys` so strict surface-totality still passes.
  withoutMarker =
    (denCompat.mkDen [
      {
        config.den = {
          schema.zone.parent = null;
          zones = ev.config.den.zones;
          _entityStamps.zones = zoneStamps;
          _declaredKeys = [ "zones" ];
        };
      }
    ]).den;
in
{
  flake.tests.compat-registry-kind-marker = {
    # (a) `identityKeysOf` reflects the primitive IDENTITY set `mkIdentityModule` hashes: `region` + the
    # injected `name`, EXCLUDING the internal `sopsTag` (identity-flag exclusion) and `id_hash` itself.
    test-identity-keys-exclude-internal = {
      expr = denCompat.registry.identityKeysOf zoneOpts;
      expected = [
        "name"
        "region"
      ];
    };
    # (b) THE MARKER DIVERGENCE: the value-reflecting `identityHashFor` MISSES (it hashes `sopsTag`,
    # which the carried id_hash excludes), while the option-reflecting `registryKindOf` HITS kind `zone`.
    test-value-marker-misses-option-marker-hits = {
      expr = {
        valueMarkerMatches = schema.identityHashFor "zone" z1inst == z1inst.id_hash;
        optionMarkerKind = markerKind;
      };
      expected = {
        valueMarkerMatches = false;
        optionMarkerKind = "zone";
      };
    };
    # (c) END-TO-END: with the marker map the registry reaches the fleet as a root entity — name + the
    # ingest-convention `sha256("zone|name=z1")` id_hash + the stamped fields (region data + the
    # internal-derived string), and a `zone:z1` root scope node exists.
    test-registry-reaches-fleet-with-marker = {
      expr = {
        names = builtins.attrNames (withMarker.registries.zone or { });
        idHash = (withMarker.registries.zone.z1 or { }).id_hash or null;
        nameOnly = builtins.hashString "sha256" "zone|name=z1";
        region = (withMarker.registries.zone.z1 or { }).region or null;
        sopsTag = (withMarker.registries.zone.z1 or { }).sopsTag or null;
        rootType = (withMarker.scopeRoots."zone:z1" or { }).type or null;
      };
      expected = {
        names = [ "z1" ];
        idHash = builtins.hashString "sha256" "zone|name=z1";
        nameOnly = builtins.hashString "sha256" "zone|name=z1";
        region = "west";
        sopsTag = "computed-west";
        rootType = "zone";
      };
    };
    # (c′) the value-reflecting fallback ALONE (no marker map) leaves the registry EMPTY — the gap.
    test-registry-empty-without-marker = {
      expr = builtins.attrNames (withoutMarker.registries.zone or { });
      expected = [ ];
    };
    # (d) GENERICITY: `registryKindOf` resolves by the id_hash marker over the DISCOVERED candidate set
    # — kind `zone` at namespace `zones`, a name the shim never spells, never a pluralization heuristic.
    test-genericity-marker-by-hash = {
      expr = denCompat.registry.registryKindOf {
        opts = zoneOpts;
        instances = ev.config.den.zones;
        candidateKinds = [
          "widget"
          "zone"
          "gadget"
        ];
        inherit (schema) hashIdentity;
      };
      expected = "zone";
    };
  };
}
