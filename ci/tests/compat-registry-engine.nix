# REGISTRY ENGINE BOUNDARY — the check that a fixture's consumer-declared registry is built by the engine
# that builds it in the consumer, and that the gen-merge the suite reaches through is the one that
# implements the surface the bridge reads.
#
# WHY THIS EXISTS. `bridge.nix subOptionsOf` classifies a consumer-declared registry by reading
# `t.getSubOptions` off the DECLARED option's type. In the consumer that `t` is a gen-merge type
# (`mkInstanceRegistry` → `merge.types.attrsOf (mkInstanceType …)`). A fixture that declares the same
# registry as `lib.types.attrsOf (lib.types.submoduleWith { … })` reads nixpkgs' `getSubOptions` instead,
# which has always been implemented — so the fixture passes whatever gen-merge does, including nothing.
# That is not a hypothetical: gen-merge stubbed `getSubOptions` as `_prefix: { }` on every type, and no
# fixture in this suite could witness it.
#
# Two independent pins, because they fail for different reasons:
#   (a) ENGINE — what `ci/tests/_lib/instance-registry.nix` constructs is a gen-merge container, checked
#       against a nixpkgs container built in the SAME expression. A discriminant that has not been shown
#       to separate a known positive from a known negative proves nothing about an absence, so the
#       nixpkgs arm is not decoration: it is what licenses reading the gen arm.
#   (b) REV — `getSubOptions` actually reports the sub-option surface on den-hoag's OWN gen-merge
#       (`internal.merge`) and on the one gen-schema re-exports (`internal.schema.types`). These are two
#       distinct lock nodes that have historically carried different revs in one evaluation, so both are
#       pinned. Contents, never non-emptiness: `builtins.attrNames { }` is `[ ]`, so a membership check
#       passes against the exact regression it guards.
{
  lib,
  denCompat,
  denHoag,
  ...
}:
let
  registry = import ./_lib/instance-registry.nix { inherit denHoag lib; };
  merge = denHoag.internal.merge;
  schema = denHoag.internal.schema;

  # A kind authored the way a CONSUMER authors one — its own nixpkgs `lib` — carrying three fields
  # whose identity membership is decided by three DIFFERENT rules, so no one case can stand in for
  # another:
  #   slots    nixpkgs `int`  → IN.  `int`/`bool` are named identically by both type systems.
  #   region   nixpkgs `str`  → IN, and this is the case that has to be pinned: reflection dispatches
  #                            on the option's type NAME, and nixpkgs names a string `str` where
  #                            gen-types names it `string`. A reflection accepting only the gen-types
  #                            spelling drops it silently, and instances differing only in it collapse
  #                            to one id_hash. Kept nixpkgs-typed deliberately — gen-typing it would
  #                            make the fixture pass by ceasing to model how a consumer writes kinds.
  #   sopsTag  nixpkgs `str`, `internal` → OUT by FLAG. Its value is a string, so a VALUE-reflecting
  #                            recompute over-includes it — the miss the option-level twin exists to
  #                            avoid.
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
      slots = 7;
      region = "west";
      sopsTag = "computed-west";
    };
  };
  z1 = zoneReg.instances.z1;

  widgetReg = registry.mkRegistry {
    kindName = "widget";
    kind = {
      isEntity = true;
      parent = null;
      imports = [
        (_: {
          options.marker = lib.mkOption {
            type = lib.types.str;
            default = "M";
          };
        })
      ];
    };
    namespace = "widgets";
    instances.w1 = { };
  };

  # The nixpkgs look-alike the converted fixtures used to spell out — the KNOWN NEGATIVE the engine
  # discriminant is demonstrated against.
  nixpkgsLookAlike = lib.types.attrsOf (
    lib.types.submodule {
      options.marker = lib.mkOption {
        type = lib.types.str;
        default = "M";
      };
    }
  );

  # `functor.payload` is null on every gen-merge type and carries a value on a nixpkgs container;
  # `functor.name` separates them too (`attrsOf` vs nixpkgs' `attrsWith`). `name`/`_type` agree on both
  # sides, which is why neither alone can decide this.
  engineOf = t: {
    inherit (t) _type name;
    functorName = t.functor.name;
    payloadIsNull = (t.functor.payload or "carried") == null;
  };

  # A known module for the rev pin: one declared option, so an implemented `getSubOptions` reports
  # exactly `[ "y" ]` and the stub reports `[ ]`.
  probeModule = mkOption: types: { options.y = mkOption { type = types.str; }; };

  # The consumer-authoring case whose identity turns on the `str` spelling and NOTHING else: one
  # nixpkgs-`str` field, no `internal` one. Its id_hash covers `region`, so it is the regression guard
  # on the reflection agreeing across engines — if a gen-schema bump ever drops the nixpkgs spelling
  # again, this kind's instances collapse and both discovery paths stop finding them.
  plainKind = {
    isEntity = true;
    parent = null;
    imports = [
      (_: {
        options.region = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
      })
    ];
  };
  plainReg = registry.mkRegistry {
    kindName = "rack";
    kind = plainKind;
    namespace = "rackFarm";
    instances.r1.region = "west";
  };
  plainIngest = denCompat.ingest.ingest {
    schema.rack = plainKind;
    rackFarm = plainReg.instances;
  };
in
{
  flake.tests.compat-registry-engine = {
    # (a) THE ENGINE. The shared constructor yields a gen-merge container; the nixpkgs look-alike built
    # beside it yields a nixpkgs one. Both arms pinned, so a discriminant that stopped discriminating
    # fails here rather than silently passing the gen arm.
    test-shared-constructor-yields-gen-merge-container = {
      expr = {
        gen = engineOf widgetReg.option.type;
        nixpkgs = engineOf nixpkgsLookAlike;
      };
      expected = {
        gen = {
          _type = "option-type";
          name = "attrsOf";
          functorName = "attrsOf";
          payloadIsNull = true;
        };
        nixpkgs = {
          _type = "option-type";
          name = "attrsOf";
          functorName = "attrsWith";
          payloadIsNull = false;
        };
      };
    };
    # (a′) the surfaces the two engines report through the SAME read differ in contents, which is the
    # concrete reason a look-alike cannot stand in: `mkInstanceType`'s injections (`name`, `id_hash`,
    # `_identity`) are absent from the nixpkgs arm, and nixpkgs' `_module` is absent from the gen arm.
    test-sub-option-surfaces-differ = {
      expr = {
        gen = builtins.attrNames widgetReg.subOptions;
        nixpkgs = builtins.attrNames (nixpkgsLookAlike.getSubOptions [ ]);
      };
      expected = {
        gen = [
          "_identity"
          "id_hash"
          "marker"
          "name"
        ];
        nixpkgs = [
          "_module"
          "marker"
        ];
      };
    };
    # (b) THE REV. Both gen-merge names a fixture can reach report the declared surface. This fails on a
    # gen-merge whose `getSubOptions` is the `_prefix: { }` stub, so it is what keeps one lock node from
    # drifting behind its sibling unnoticed.
    test-getsuboptions-implemented-on-both-reachable-gen-merges = {
      expr = {
        internalMerge = builtins.attrNames (
          (merge.types.submodule (probeModule merge.mkOption merge.types)).getSubOptions [ ]
        );
        schemaTypes = builtins.attrNames (
          (schema.types.submodule (probeModule schema.mkOption schema.types)).getSubOptions [ ]
        );
        throughAttrsOf = builtins.attrNames (
          (merge.types.attrsOf (merge.types.submodule (probeModule merge.mkOption merge.types))).getSubOptions
            [ ]
        );
      };
      expected = {
        internalMerge = [ "y" ];
        schemaTypes = [ "y" ];
        throughAttrsOf = [ "y" ];
      };
    };
    # (c) THE REFLECTION DRIFT GUARD. gen-schema stamps `id_hash` from `mkIdentityModule`'s reflection
    # and exposes `identityHashForKind` as its option-level twin, and the twin's own comment says it
    # "can drift from neither". They are two SEPARATE hardcoded primitive-type-name lists, and they
    # have been unequal at other revs — so the claim is enforced here rather than trusted. This is the
    # property `registryKindOf` now rests on: recompute must equal the stamp, on a kind whose fields
    # are authored with nixpkgs types. If a gen-schema bump moves one list without the other, this
    # goes red and names the reason instead of silently reintroducing a marker miss.
    test-identity-reflection-agrees-with-the-stamp = {
      expr = {
        recomputeMatchesStamp = schema.identityHashForKind zoneReg.kindValue z1 == z1.id_hash;
        # The stamp's CONTENTS, not merely that the two agree — `slots` and `region` in, `sopsTag`
        # out. Equality alone is satisfied when both reflections degenerate TOGETHER: two that select
        # nothing agree perfectly while every instance collapses to a name-only hash, which is the
        # failure this guard exists to catch reappearing through the guard itself. Pinning what was
        # actually hashed is what separates agreement from shared blindness.
        stamped = z1.id_hash;
        # a VALUE-reflecting recompute over-includes both strings and therefore MISSES — the reason
        # the marker reads the kind's declared surface rather than the instance's fields.
        valueReflectionMisses = schema.identityHashFor "zone" z1 != z1.id_hash;
      };
      expected = {
        recomputeMatchesStamp = true;
        stamped = builtins.hashString "sha256" "zone|name=z1|region=west|slots=7";
        valueReflectionMisses = true;
      };
    };
    # (c″) A NIXPKGS-`str` IDENTITY FIELD RESOLVES ON BOTH DISCOVERY PATHS. The option-reflecting
    # marker the bridge computes and the value-reflecting discovery `ingest` falls back to must BOTH
    # find this namespace, and the carried id_hash must cover `region` — that is what makes the two
    # agree. Pinned together because a reflection that drops the nixpkgs spelling breaks all three at
    # once, and any one of them alone could be read as an unrelated fault.
    test-nixpkgs-str-identity-resolves-on-both-paths = {
      expr = {
        carried = plainReg.instances.r1.id_hash;
        overNameAndRegion = builtins.hashString "sha256" "rack|name=r1|region=west";
        bridgeMarker = denCompat.registry.registryKindOf {
          instances = plainReg.instances;
          candidateKinds = [
            "rack"
            "host"
          ];
          kindValues.rack = plainReg.kindValue;
          inherit (schema) identityHashForKind;
        };
        ingestKey = plainIngest.instanceKeyMap.rack or null;
        ingestInstances = builtins.attrNames (plainIngest.instances.rack or { });
      };
      expected = {
        carried = builtins.hashString "sha256" "rack|name=r1|region=west";
        overNameAndRegion = builtins.hashString "sha256" "rack|name=r1|region=west";
        bridgeMarker = "rack";
        ingestKey = "rackFarm";
        ingestInstances = [ "r1" ];
      };
    };
    # (c‴) THE WRONG-KIND CONTROL, and it is what makes the pins above mean anything. A recompute that always
    # matched would satisfy (c) and would classify every namespace as every kind. The same instance
    # against a kind value carrying a different `kind` must MISS, so the marker's discrimination is
    # pinned rather than its success.
    test-marker-rejects-a-wrong-kind = {
      expr = {
        rightKind = denCompat.registry.registryKindOf {
          instances = zoneReg.instances;
          candidateKinds = [
            "widget"
            "zone"
            "gadget"
          ];
          kindValues.zone = zoneReg.kindValue;
          inherit (schema) identityHashForKind;
        };
        # the true kind is absent from the candidate set ⇒ no candidate can reproduce the hash
        wrongCandidatesOnly = denCompat.registry.registryKindOf {
          instances = zoneReg.instances;
          candidateKinds = [
            "widget"
            "gadget"
          ];
          kindValues.widget = zoneReg.kindValue // {
            kind = "widget";
          };
          inherit (schema) identityHashForKind;
        };
        # an empty namespace has no instance to reflect
        emptyNamespace = denCompat.registry.registryKindOf {
          instances = { };
          candidateKinds = [ "zone" ];
          kindValues.zone = zoneReg.kindValue;
          inherit (schema) identityHashForKind;
        };
      };
      expected = {
        rightKind = "zone";
        wrongCandidatesOnly = null;
        emptyNamespace = null;
      };
    };
  };
}
