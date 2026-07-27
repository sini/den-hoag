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
  denHoag,
  ...
}:
let
  registry = import ./_lib/instance-registry.nix { inherit denHoag lib; };
  merge = denHoag.internal.merge;
  schema = denHoag.internal.schema;

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
  };
}
