# Shared gen-schema INSTANCE-REGISTRY constructor for the fixtures — the one place a suite builds a
# consumer-declared registry, and it does so by CALLING gen-schema's own `mkInstanceRegistry`
# (`gen-schema/lib/instance.nix`) rather than reproducing its shape.
#
# WHY A SHARED CONSTRUCTOR AND NOT A LOCAL SPELLING. A registry hand-rolled as
# `lib.types.attrsOf (lib.types.submoduleWith { … })` is a nixpkgs type where the consumer has a
# gen-merge one, so `type.getSubOptions` — the surface `bridge.nix subOptionsOf` reads to classify a
# consumer registry — resolves through nixpkgs' implementation and the fixture is structurally
# incapable of witnessing a gen-merge type-behaviour defect. It also silently drops what
# `mkInstanceType` injects per instance: the identity module (`id_hash`/`_identity`), the
# strict/freeform arm, `config._module.args.<kind>`, and `options.name`. Every fixture that
# reproduced the construction by hand had to re-stamp those by hand too, and each hand-stamp is an
# assumption about gen-schema that nothing checks.
#
# THE ENGINE SPLIT this preserves (it is the whole point, not an oversight):
#   * the REGISTRY is gen-schema's — `mkInstanceRegistry` yields a gen-merge `attrsOf`;
#   * the registry is DECLARED inside a nixpkgs `lib.evalModules`, because that is where the consumer
#     declares it (a flake-parts eval). gen types mounting inside nixpkgs' module system is the
#     supported direction;
#   * a KIND's own options stay nixpkgs-typed, because the consumer authors them with its own `lib`
#     (`den.schema.<kind>.imports` carrying `lib.mkOption`). A fixture that gen-types them would be
#     modelling something no consumer writes.
#
# `kindValueOf` runs the SAME processing eval `lib/compat/ingest.nix` runs — `mkSchemaOption` over a
# raw kind declaration, read back off the tree — so a fixture that has no bridge in its eval still
# gets a real kind value rather than a hand-built `{ kind; options; }` pair.
{ denHoag, lib }:
let
  schema = denHoag.internal.schema;
in
rec {
  # A raw v1-shaped kind declaration → the processed gen-schema KIND VALUE (`{ kind; options; refs;
  # … }`), the argument `mkInstanceRegistry` takes. Self-referential `tree` is gen-schema's documented
  # pattern; laziness ties the knot.
  kindValueOf =
    kindName: decl:
    (schema.evalModuleTree {
      modules = [
        { options.den.schema = schema.mkSchemaOption { }; }
        { config.den.schema.${kindName} = decl; }
      ];
    }).config.den.schema.${kindName};

  # THE constructor, re-exported rather than wrapped — a fixture whose kind value already exists in
  # its own eval (`config.den.schema.<kind>`, the bridge-processed surface) declares its registry with
  # this directly, exactly as the consumer writes `options.den.clusters = mkInstanceRegistry
  # den.schema.cluster { … }`.
  inherit (schema) mkInstanceRegistry;

  # The DECLARED option's own sub-option surface — the read `bridge.nix subOptionsOf` performs when it
  # classifies a consumer-declared registry. `loc` is the option path, which gen-merge threads into
  # the sub-options' own `loc`.
  subOptionsOf = option: loc: option.type.getSubOptions loc;

  # A whole registry fixture: declare `den.<namespace>` through the real constructor in a nixpkgs
  # eval, define `instances` into it, and hand back both halves the suites read — the merged config
  # view and the declared option surface.
  #
  #   kind         the raw kind declaration, processed here; or pass `kindValue` directly (a kind value
  #                a fixture's own eval already produced, e.g. the bridge-processed `den.schema.<kind>`)
  #   kindName     the kind's name; defaults to the kind value's own, so only the raw-declaration form
  #                needs to spell it
  #   namespace    the config-chosen registry key (arbitrary — never a pluralization of the kind)
  #   instances    definitions written into the registry
  #   registryArgs the second argument of `mkInstanceRegistry` (`extraModules`, `derive`, `refs`, …)
  #   extraModules additional modules for the surrounding nixpkgs eval
  mkRegistry =
    {
      kindName ? kindValue.kind,
      kind ? null,
      kindValue ? kindValueOf kindName kind,
      namespace ? kindName,
      instances ? { },
      registryArgs ? { },
      extraModules ? [ ],
    }:
    let
      option = mkInstanceRegistry kindValue registryArgs;
      eval = lib.evalModules {
        modules = [
          { options.den.${namespace} = option; }
          { den.${namespace} = instances; }
        ]
        ++ extraModules;
      };
    in
    {
      inherit eval kindValue;
      option = eval.options.den.${namespace};
      subOptions = subOptionsOf eval.options.den.${namespace} [
        "den"
        namespace
      ];
      instances = eval.config.den.${namespace};
    };
}
