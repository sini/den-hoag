# u8 PATH 2 — the cluster ctx ENTITY carries its registry view (the bridge-registry passthrough for a
# CONSUMER-DECLARED kind). Path 1 (ad2195b) restored the corpus's REGISTRY reads
# (`config.den.clusters.<c>.getAssignment`, k3s.nix:86,161) by re-injecting gen-schema's methods
# module through the belt; path 2 is the ENTITY half: a cluster-scoped aspect fn reads
# `cluster.networks`/`cluster.settings`/`cluster.getAssignment` off the ctx entity (v1 binds the FULL
# resolved config as the ctx entity, pin 11866c16 assemble-pipes.nix:154), and den-hoag entities were
# field-less. The passthrough closes it KIND-GENERICALLY: the corpus's OWN `mkInstanceRegistry`
# option (declared in the consumer eval) already materializes the merged view; the bridge stamps it
# minus the structural exclusion (`_entityStamps.<namespace>`), ingest re-keys by the marker-
# discovered kind, and the fleet's registry ENTRY — the ctx entity — carries the fields.
#
# ARMS. (a) The kind-value + methods module cross the BRIDGE (the compat-schema-processing pattern)
# and a corpus-style consumer-declared `options.den.clusters` materializes id_hash-bearing instances;
# (b) the stamp is computed with the REAL registry machinery over the DECLARED option's own
# `getSubOptions` — the exact reads the bridge's `_entityStamps` performs (`denSubOptions` →
# `subOptionsOf` → stampTreeOf/stampOf); (c) the stamped entities ride `mkDen` into the built fleet's
# cluster registry entries: networks + settings (data) and getAssignment (a METHOD lambda — a normal
# form, deepSeq-safe) present and LIVE, the raw-typed/anything-class fields absent. The bridge's own
# scan→fleet splice is host-proven end-to-end (compat-settings-binding) and corpus-proven by the
# ship-gate re-probe.
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    mkCrossNixos = _: throw "compat-cluster-entity: mkCrossNixos unused";
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  # gen-schema's instance identity, reproduced for the fixture instances (the compat-custom-kind
  # marker convention): id_hash over the instance's PRIMITIVE fields — `name` alone here (networks/
  # settings are attrsets, getAssignment a function; `environment` deliberately omitted to keep the
  # primitive census = {name}) — so ingest's marker discovery maps kind `cluster` → `clusters`.
  idFor = name: denHoag.internal.schema.identityHashFor "cluster" { inherit name; };
  ev = lib.evalModules {
    modules = [
      flakeStub
      bridge
      # The corpus-shaped cluster kind (nix-config schema/cluster.nix): typed networks (:51-94,
      # :229-233), a typed settings namespace (:246-255), and the getAssignment METHOD (:129-143,
      # `schemaFn <desc> (functionTo str) <fn>` — the fn takes its arg-names off the INSTANCE config).
      {
        den.schema.cluster = {
          isEntity = true;
          imports = [
            (_: {
              options = {
                networks = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.submodule {
                      options.assignments = lib.mkOption {
                        type = lib.types.attrsOf lib.types.str;
                        default = { };
                      };
                    }
                  );
                  default = { };
                };
                settings = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.attrsOf lib.types.bool);
                  default = { };
                };
              };
            })
          ];
          methods.getAssignment =
            denHoag.internal.schema.schemaFn "Look up an IP assignment across cluster networks"
              (lib.types.functionTo lib.types.str)
              (
                { networks, ... }:
                assignmentName:
                let
                  found = builtins.filter (n: networks.${n}.assignments ? ${assignmentName}) (
                    builtins.attrNames networks
                  );
                in
                if found != [ ] then
                  networks.${builtins.head found}.assignments.${assignmentName}
                else
                  throw "cluster assignment '${assignmentName}' not found"
              );
        };
      }
      # The CONSUMER-DECLARED instance registry (corpus schema/cluster.nix:97 `options.den.clusters =
      # schemaLib.mkInstanceRegistry den.schema.cluster` — here the same construction spelled out: the
      # emitted kind-value functor as the instance module + the identity module gen-schema injects).
      (
        { config, ... }:
        {
          options.den.clusters = lib.mkOption {
            default = { };
            type = lib.types.attrsOf (
              lib.types.submoduleWith {
                shorthandOnlyDefinesConfig = true;
                modules = [
                  config.den.schema.cluster
                  (
                    { name, ... }:
                    {
                      options.name = lib.mkOption {
                        type = lib.types.str;
                        default = name;
                      };
                      options.id_hash = lib.mkOption {
                        type = lib.types.str;
                        default = idFor name;
                      };
                    }
                  )
                ];
              }
            );
          };
        }
      )
      {
        den.clusters.c1 = {
          networks.lan.assignments.web = "10.0.0.7";
          settings.kubernetes.bootstrap = true;
        };
      }
    ];
  };
  # (b) the stamp, computed with the REAL machinery over the DECLARED option's own getSubOptions —
  # the exact reads bridge.nix's `_entityStamps` consumer-registry branch performs.
  clustersOption = (ev.options.den.type.getSubOptions [ ]).clusters;
  clusterTree = denCompat.registry.stampTreeOf (
    clustersOption.type.getSubOptions [
      "den"
      "clusters"
    ]
  );
  clusterStamps = builtins.mapAttrs (
    _: e: denCompat.registry.stampOf clusterTree e
  ) ev.config.den.clusters;
  # (c) the stamped entities ride mkDen — the marker-discovered `clusters` namespace re-keys to kind
  # `cluster`, its kind declares the stamped fields, and the fleet registry entry carries them.
  clusterFleet =
    (denCompat.mkDen [
      {
        config.den = {
          schema.cluster.parent = null;
          clusters = ev.config.den.clusters;
          _entityStamps.clusters = clusterStamps;
        };
      }
    ]).den;
  c1 = clusterFleet.registries.cluster.c1;
in
{
  flake.tests.compat-cluster-entity = {
    # (a) the consumer-declared registry materializes through the bridge: instances carry the merged
    # data AND the belt-injected METHOD, computed from the instance's OWN fields (path 1, re-pinned
    # at the fixture registry).
    test-registry-materializes = {
      expr = {
        networks = ev.config.den.clusters.c1.networks;
        method = ev.config.den.clusters.c1.getAssignment "web";
      };
      expected = {
        networks.lan.assignments.web = "10.0.0.7";
        method = "10.0.0.7";
      };
    };
    # (b) the structural inclusion tree over the DECLARED option surface: data fields + the
    # functionTo-data method ride; identity (name/id_hash) is never stamped.
    test-stamp-tree-shape = {
      expr = clusterTree;
      expected = {
        networks = true;
        settings = true;
        getAssignment = true;
      };
    };
    # (c) u8 PATH 2, at the entity level: the built fleet's cluster ENTITY — the ctx entity a
    # cluster-scoped aspect fn receives — carries networks + settings + a LIVE getAssignment.
    test-cluster-entity-carries-registry-view = {
      expr = {
        networks = c1.networks;
        settings = c1.settings;
        assignment = c1.getAssignment "web";
        identityStable = c1.id_hash == idFor "c1";
      };
      expected = {
        networks.lan.assignments.web = "10.0.0.7";
        settings.kubernetes.bootstrap = true;
        assignment = "10.0.0.7";
        identityStable = true;
      };
    };
  };
}
