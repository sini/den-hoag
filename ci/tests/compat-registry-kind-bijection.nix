# KIND RESOLUTION IS A BIJECTION OVER REGISTRY KEYS — the multi-registry shape, which is the only shape
# the consumer ever has and the one no fixture had.
#
# WHY THIS EXISTS. A fleet's namespace→kind map is folded once per registry key. Every fixture in this
# suite carried AT MOST ONE consumer-declared registry, so the fold ran with a single key everywhere: a
# fold that answered with one kind for EVERY key — the shape a careless hoist of the per-key computation
# produces — is indistinguishable from a correct one at n=1. Measured against a three-registry consumer,
# that same fold empties a whole registry and the two scope roots under it, and it does so SILENTLY: the
# host output face is unchanged, so neither a build nor an output enumeration can see it.
#
# The invariant, stated rather than implied: each registry key resolves to the kind ITS OWN instances
# were stamped by, independently of every other key. So the map's values are pairwise DISTINCT and no
# key's answer is reusable for another.
#
# WHAT MAKES THE OPTION-LEVEL MARKER LOAD-BEARING HERE, and it is not decoration: ingest falls back to
# the VALUE-reflecting discovery whenever the marker leaves a kind unresolved, and that fallback rescues
# an ordinary kind — so on ordinary kinds a broken marker is invisible. It cannot rescue a kind carrying
# a DERIVED primitive. `clusters` reproduces the corpus shape exactly (`nix-config schema/cluster.nix:97`
# — a registry `derive` overlaying a string field declared `internal` in the registry's own
# `extraModules`, hence absent from the KIND value's options and absent from the stamp, but PRESENT on
# the instance value): the value-reflection over-includes it and misses, and only the option-level marker
# can resolve the namespace. Pinned below in its own arm, because if that miss ever stopped happening
# the bijection pin would go green through the fallback and stop testing the marker at all.
#
# AND ITS KEY IS DELIBERATELY NOT THE FIRST ONE THE FOLD VISITS. `siteClusters` sorts after
# `environments`/`groups` (it is also the corpus's own property that a registry key is arbitrary and
# never a pluralization of its kind). A fold that reuses one key's answer takes the FIRST key's, so
# putting the fallback-proof registry first would let a broken fold answer correctly for the one kind
# that can detect it, and only the map pin would fail — the structural arms would stay green through the
# fallback. Measured, not reasoned: with `clusters` sorting first, exactly that happened.
#
# ── THE FALLBACK'S REACH, so the arms below are not read as stronger than they are: on a kind whose
# value-reflection succeeds, a broken marker is INVISIBLE end-to-end — ingest's fallback resolves the
# namespace anyway and the fleet is correct. That is not a gap in this fixture, it is the honest scope of
# the defect: only kinds carrying a derived/internal primitive lose their registry. The corpus behaves
# exactly this way (its `groups` survived a mis-keyed map while its `environments` did not).
#
# THREE DISJOINT KINDS, which is also what widens the cross-kind totality case: the probe reads each
# candidate kind's declared surface against an instance of another, so every one of the nine pairings
# reads fields the instance lacks. A missing attribute is not a `throw` and `tryEval` does not catch it.
{
  lib,
  denCompat,
  denHoag,
  ...
}:
let
  registry = import ./_lib/instance-registry.nix { inherit denHoag lib; };
  schema = denHoag.internal.schema;

  # ── three kinds with PAIRWISE DISJOINT option sets, authored with the consumer's own nixpkgs `lib` ──
  # Identity membership is decided per option by gen-schema's reflection: primitives in, everything else
  # out. Spelled out per kind below so the expected hashes are readable rather than asserted.
  environmentKind = {
    isEntity = true;
    parent = null;
    imports = [
      (_: {
        # identity: domain, envId, timezone (+ the injected `name`)
        options.domain = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
        options.envId = lib.mkOption {
          type = lib.types.int;
          default = 0;
        };
        options.timezone = lib.mkOption {
          type = lib.types.str;
          default = "UTC";
        };
        # NOT identity: a container and a nullable, the corpus's dominant option shapes
        options.networks = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.cidr = lib.mkOption {
                type = lib.types.str;
                default = "";
              };
            }
          );
          default = { };
        };
        options.secretPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      })
    ];
  };
  groupKind = {
    isEntity = true;
    parent = null;
    imports = [
      (_: {
        # identity: description (+ name)
        options.description = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
        options.gid = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
        };
        options.labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      })
    ];
  };
  clusterKind = {
    isEntity = true;
    parent = null;
    imports = [
      (_: {
        # identity: role (+ name). `settings` is a submodule, `kubeVersion` nullable — neither is hashed.
        options.role = lib.mkOption {
          type = lib.types.str;
          default = "worker";
        };
        options.kubeVersion = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        options.settings = lib.mkOption {
          type = lib.types.submodule {
            options.bootstrap = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
          default = { };
        };
      })
    ];
  };

  envReg = registry.mkRegistry {
    kindName = "environment";
    kind = environmentKind;
    namespace = "environments";
    instances = {
      dev = {
        domain = "dev.test";
        envId = 1;
      };
      prod = {
        domain = "prod.test";
        envId = 2;
        timezone = "Etc/UTC";
        networks.lan.cidr = "10.0.0.0/24";
      };
    };
  };
  # Three instances, and the FIRST BY KEY — the only one the probe reads — is the SPARSE one, which is
  # the corpus's own distribution (most groups leave `gid` null). A probe that happened to work only
  # because its single instance authored every field would not survive this.
  groupReg = registry.mkRegistry {
    kindName = "group";
    kind = groupKind;
    namespace = "groups";
    instances = {
      admins = {
        description = "administrators";
      };
      media = {
        description = "media";
        gid = 3001;
        labels = [ "posix" ];
      };
      wheel = {
        description = "wheel";
        gid = 10;
      };
    };
  };
  # THE CORPUS'S DERIVED-PRIMITIVE SHAPE. `sopsAgeRecipient` is declared in the REGISTRY's `extraModules`
  # — not in the kind — so it is absent from the kind value's `options` and from the identity stamp
  # (`internal`), while `derive` overlays a STRING onto every instance after the module eval. A
  # value-reflecting recompute sees that string and over-includes it; the option-level recompute cannot
  # see it at all. That asymmetry is the whole reason the option-level marker exists.
  clusterReg = registry.mkRegistry {
    kindName = "cluster";
    kind = clusterKind;
    namespace = "siteClusters";
    instances.axon = {
      role = "control-plane";
      settings.bootstrap = true;
    };
    registryArgs = {
      derive = insts: lib.mapAttrs (n: _: { sopsAgeRecipient = "age1${n}"; }) insts;
      extraModules = [
        (_: {
          options.sopsAgeRecipient = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            readOnly = true;
            internal = true;
          };
        })
      ];
    };
  };

  kindValues = {
    cluster = clusterReg.kindValue;
    environment = envReg.kindValue;
    group = groupReg.kindValue;
  };
  candidateKinds = [
    "cluster"
    "environment"
    "group"
  ];
  instancesByKey = {
    siteClusters = clusterReg.instances;
    environments = envReg.instances;
    groups = groupReg.instances;
  };
  registryKeys = builtins.attrNames instancesByKey;

  kindMap = denCompat.registry.registryKindsFor {
    inherit registryKeys candidateKinds kindValues;
    instancesOf = k: instancesByKey.${k};
    inherit (schema) identityHashForKind;
  };
  # The invariant itself, computed rather than eyeballed: as many distinct kinds as there are keys.
  distinctKindCount = builtins.length (
    builtins.attrNames (
      builtins.listToAttrs (map (v: lib.nameValuePair v null) (builtins.attrValues kindMap))
    )
  );

  # The whole thing again through the REAL mkDen-direct wiring: raw v1 declarations in, discovery done by
  # the lib. Nothing here hands the lib an answer it could agree with.
  v1Decls = {
    schema = {
      cluster = clusterKind;
      environment = environmentKind;
      group = groupKind;
    };
  }
  // instancesByKey;
  ing = denCompat.ingest.ingest v1Decls;
  fleet = (denCompat.mkDen [ { config.den = v1Decls; } ]).den;
  namesIn = kind: builtins.attrNames (fleet.registries.${kind} or { });

  firstCluster = clusterReg.instances.axon;
in
{
  flake.tests.compat-registry-kind-bijection = {
    # ── THE BIJECTION. Contents of the whole map, plus the distinctness that names what is being
    # protected. A fold that reuses one key's answer for the rest fails both halves; a fold that resolved
    # nothing fails the first and PASSES the second (one distinct value over an empty map is not three),
    # which is why the count is pinned against the key count rather than asserted non-trivial.
    test-kind-resolution-is-a-bijection-over-registry-keys = {
      expr = {
        map = kindMap;
        keyCount = builtins.length registryKeys;
        inherit distinctKindCount;
      };
      expected = {
        map = {
          environments = "environment";
          groups = "group";
          siteClusters = "cluster";
        };
        keyCount = 3;
        distinctKindCount = 3;
      };
    };

    # ── WHAT ARMS THE ABOVE. On `clusters` the value-reflecting fallback MISSES, so the bijection pin
    # rides the option-level marker there and cannot be satisfied by the fallback rescuing it. Pinned in
    # both directions on the SAME instance: the recompute that must miss, and the one that must hit.
    # `environments` is shown missing too — the fallback's rescue is not universal even off the derived
    # field, and pinning only the derived case would overstate how much the fallback covers.
    test-derived-primitive-defeats-the-value-reflecting-fallback = {
      expr = {
        clusterValueReflectionMisses =
          schema.identityHashFor "cluster" firstCluster != firstCluster.id_hash;
        clusterOptionReflectionHits =
          schema.identityHashForKind clusterReg.kindValue firstCluster == firstCluster.id_hash;
        # the derived string IS on the instance — the reason the value reflection over-includes
        derivedField = firstCluster.sopsAgeRecipient;
        # … and is NOT on the kind value's surface, which is why the option reflection cannot see it
        onKindSurface = clusterReg.kindValue.options ? sopsAgeRecipient;
        # … while the REGISTRY's own sub-option surface does declare it (extraModules)
        onRegistrySurface = clusterReg.subOptions ? sopsAgeRecipient;
        stamped = firstCluster.id_hash;
      };
      expected = {
        clusterValueReflectionMisses = true;
        clusterOptionReflectionHits = true;
        derivedField = "age1axon";
        onKindSurface = false;
        onRegistrySurface = true;
        stamped = builtins.hashString "sha256" "cluster|name=axon|role=control-plane";
      };
    };

    # ── CROSS-KIND TOTALITY AT WIDTH. Nine pairings, every off-diagonal one reading fields the instance
    # lacks (the three option sets are disjoint), and the sparse first `groups` instance lacks two of its
    # OWN kind's options as well. An untotalised probe aborts the evaluation here rather than failing.
    test-cross-kind-probe-total-over-three-disjoint-kinds = {
      expr = {
        perKey = builtins.mapAttrs (
          k: _:
          denCompat.registry.registryKindOf {
            instances = instancesByKey.${k};
            inherit candidateKinds kindValues;
            inherit (schema) identityHashForKind;
          }
        ) instancesByKey;
        # the option sets really are disjoint — a fixture whose kinds overlapped would be testing a
        # weaker shape than it claims
        overlaps = builtins.filter (
          o: builtins.length (builtins.filter (k: kindValues.${k}.options ? ${o}) candidateKinds) > 1
        ) (builtins.concatMap (k: builtins.attrNames kindValues.${k}.options) candidateKinds);
        firstGroupFields = builtins.attrNames (builtins.head (builtins.attrValues groupReg.instances));
      };
      expected = {
        perKey = {
          environments = "environment";
          groups = "group";
          siteClusters = "cluster";
        };
        overlaps = [ ];
        firstGroupFields = [
          "_identity"
          "description"
          "gid"
          "id_hash"
          "labels"
          "name"
        ];
      };
    };

    # ── THE SAME PROPERTY THROUGH THE REAL INGEST, not through hand-passed arguments. `instanceKeyMap`
    # is the inverse map, so it pins the bijection from the other side, and the instance names pin that
    # each kind received ITS OWN entries rather than merely receiving some.
    test-ingest-keys-every-registry-to-its-own-kind = {
      expr = {
        keyMap = {
          cluster = ing.instanceKeyMap.cluster or null;
          environment = ing.instanceKeyMap.environment or null;
          group = ing.instanceKeyMap.group or null;
        };
        clusters = builtins.attrNames (ing.instances.cluster or { });
        environments = builtins.attrNames (ing.instances.environment or { });
        groups = builtins.attrNames (ing.instances.group or { });
      };
      expected = {
        keyMap = {
          cluster = "siteClusters";
          environment = "environments";
          group = "groups";
        };
        clusters = [ "axon" ];
        environments = [
          "dev"
          "prod"
        ];
        groups = [
          "admins"
          "media"
          "wheel"
        ];
      };
    };

    # ── THE STRUCTURAL CONSEQUENCE, which is what a corpus actually loses. A mis-keyed registry does not
    # throw: its kind's registry comes back EMPTY and its scope roots are simply not there. Both pinned
    # by CONTENTS — an empty registry satisfies any membership check, and a scope-root COUNT alone is
    # satisfiable by roots of the wrong kind, so the root ids are pinned too.
    test-fleet-registries-and-scope-roots = {
      expr = {
        cluster = namesIn "cluster";
        environment = namesIn "environment";
        group = namesIn "group";
        scopeRoots = builtins.attrNames fleet.scopeRoots;
      };
      expected = {
        cluster = [ "axon" ];
        environment = [
          "dev"
          "prod"
        ];
        group = [
          "admins"
          "media"
          "wheel"
        ];
        scopeRoots = [
          "cluster:axon"
          "environment:dev"
          "environment:prod"
          "group:admins"
          "group:media"
          "group:wheel"
        ];
      };
    };
  };
}
