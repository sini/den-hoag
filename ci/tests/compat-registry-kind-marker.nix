# NON-HOST REGISTRY INGEST (user-delivery R3) — the OPTION-reflecting kind marker
# (registry.nix `registryKindOf`) that lets a consumer-declared registry whose instances carry a
# DERIVED/INTERNAL primitive reach the fleet as ROOT entities.
#
# THE GAP this closes (ground-truth: nix-config @ b0b20769, `den.clusters.axon`): ingest's custom-kind
# discovery matched a namespace to its kind by recomputing the instance's id_hash through gen-schema's
# VALUE-reflecting `identityHashFor`. That reflection over-includes ANY primitive-VALUED field — so a
# kind carrying a derived/internal primitive (the corpus `cluster.sopsAgeRecipient`: a `readFile`
# string, `internal`) makes the recompute MISS the carried id_hash (which `mkIdentityModule` stamped
# EXCLUDING the internal field). The namespace then matched NO kind → `customInstances`/
# `registries.<kind>` stayed EMPTY → no env/cluster ROOT NODES → the staged env phase never ran. The
# kind's DECLARED surface carries what the value cannot (`internal`/`identity` flags), and gen-schema
# reflects that surface itself in `identityHashForKind` — the same reflection `mkIdentityModule` runs
# when it stamps. Recomputing through gen-schema's own export is what makes the marker resolve the
# namespace the value-reflecting one misses, and it is why the recompute cannot disagree with the
# stamp. Computed at the bridge, it rides to ingest as `_registryKinds` and re-keys the passthrough
# stamps + builds the custom-kind registries.
#
# The `zone` kind reproduces the shape through a REAL `mkInstanceRegistry`, so the id_hash under test
# is the one gen-schema stamped rather than one the fixture wrote for itself: `slots` (an identity
# primitive) + `sopsTag` (marked `internal` — the sopsAgeRecipient twin, isolating the identity-FLAG
# exclusion) + `region` (a nixpkgs-`str` field, excluded for the unrelated type-name reason, so the
# two exclusions cannot stand in for one another). The suite pins: (a) the STAMP excludes the internal
# primitive; (b) the value-reflecting marker MISSES while `registryKindOf` HITS; (c) end-to-end the
# marker-keyed registry reaches the fleet as a root entity, where the value-marker fallback alone
# leaves it empty; (d) genericity — a kind name the shim never spells.
{
  lib,
  denCompat,
  denHoag,
  ...
}:
let
  schema = denHoag.internal.schema;
  registry = import ./_lib/instance-registry.nix { inherit denHoag lib; };

  # The consumer-declared registry, built by gen-schema's OWN `mkInstanceRegistry` — the construction
  # the corpus writes. The kind's options are authored with the consumer's nixpkgs `lib`, because that
  # is how a consumer authors them; only the registry around them is gen-schema's.
  #   slots    an identity primitive (`int` — the one spelling both engines share)
  #   region   a `str` field, which under this gen-schema pin is NOT an identity key: the reflection
  #            matches type NAMES and nixpkgs spells a string `str` where gen-types spells it
  #            `string`. Kept nixpkgs-typed on purpose — gen-typing it would make this fixture pass by
  #            ceasing to model the consumer.
  #   sopsTag  the corpus `cluster.sopsAgeRecipient` twin: a derived/internal primitive whose VALUE is
  #            a string, so a value-reflecting recompute over-includes it while the carried id_hash —
  #            which `mkIdentityModule` stamped honouring `internal` — does not.
  zoneReg = registry.mkRegistry {
    kindName = "zone";
    kind = {
      isEntity = true;
      parent = null;
      imports = [
        (_: {
          options.slots = lib.mkOption {
            type = lib.types.int;
            default = 0;
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
        })
      ];
    };
    namespace = "zones";
    instances.z1 = {
      slots = 3;
      region = "west";
      sopsTag = "computed-west";
    };
  };
  z1inst = zoneReg.instances.z1;

  # The instance option surface the bridge reads (`subOptionsOf` → `type.getSubOptions`) — here it is
  # a gen-merge type's, as it is in the consumer.
  zoneOpts = zoneReg.subOptions;
  zoneTree = denCompat.registry.stampTreeOf zoneOpts;
  zoneStamps = builtins.mapAttrs (_: e: denCompat.registry.stampOf zoneTree e) zoneReg.instances;

  # The robust marker (option-reflecting) — the bridge computes exactly this per consumer namespace,
  # recomputing through gen-schema's own `identityHashForKind` over the processed KIND VALUE.
  markerOver =
    candidateKinds:
    denCompat.registry.registryKindOf {
      inherit candidateKinds;
      instances = zoneReg.instances;
      kindValues.zone = zoneReg.kindValue;
      inherit (schema) identityHashForKind;
    };
  markerKind = markerOver [
    "zone"
    "host"
    "user"
  ];

  # End-to-end WITH the bridge marker map (`_registryKinds`): the namespace re-keys to kind `zone` and
  # the registry reaches the fleet as a ROOT entity (parentless kind → a root scope kind).
  withMarker =
    (denCompat.mkDen [
      {
        config.den = {
          schema.zone.parent = null;
          zones = zoneReg.instances;
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
          zones = zoneReg.instances;
          _entityStamps.zones = zoneStamps;
          _declaredKeys = [ "zones" ];
        };
      }
    ]).den;
in
{
  flake.tests.compat-registry-kind-marker = {
    # (a) THE IDENTITY SET, read off the stamp gen-schema actually wrote: `slots` + `region` + the
    # injected `name`, EXCLUDING the internal `sopsTag` (the identity-FLAG exclusion) and `id_hash`
    # itself. `region` is a nixpkgs-`str` field and it must be IN — a reflection that accepts only
    # gen-types' `string` spelling drops it, and two instances differing only in it then collapse to
    # one id_hash. The two rules are pinned apart: `sopsTag` leaves by flag, `region` stays by name.
    test-identity-excludes-internal-primitive = {
      expr = {
        stamped = z1inst.id_hash;
        overSlotsRegionAndName = builtins.hashString "sha256" "zone|name=z1|region=west|slots=3";
        withSopsTag = builtins.hashString "sha256" "zone|name=z1|region=west|slots=3|sopsTag=computed-west";
      };
      expected = {
        stamped = builtins.hashString "sha256" "zone|name=z1|region=west|slots=3";
        overSlotsRegionAndName = builtins.hashString "sha256" "zone|name=z1|region=west|slots=3";
        withSopsTag = builtins.hashString "sha256" "zone|name=z1|region=west|slots=3|sopsTag=computed-west";
      };
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
      expr = markerOver [
        "widget"
        "zone"
        "gadget"
      ];
      expected = "zone";
    };
  };
}
