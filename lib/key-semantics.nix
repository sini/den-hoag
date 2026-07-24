# The ONE keySemantics vocabulary builder (gen-aspects `cnf.keySemantics`). gen-aspects builds
# every declared aspect key's option GENERICALLY from this map: `class → deferredModule`, `channel → raw
# passthrough`, `facet → the entry's own option/module`. den-hoag declares its whole aspect vocabulary
# through here, so an aspect key's semantics live in ONE place (a single source for the class + channel +
# facet vocabulary, from which `classifyKey` also reads a key's category).
#
# This file owns the CLASS + CHANNEL half (`mkClassChannelSemantics`) — the categories every consumer of the
# aspect schema shares (identical class + fleet-quirk vocabulary, so a quirk-channel key never falls to
# freeform) — AND the SHARED FACET-VOCABULARY half (`mkFacetSemantics`): the `neededBy`/`settings`/`artifact`
# facet keySemantics MODULES, in ONE source so the aspect concern and every typed-view consumer mount the SAME
# facet option types (a `.settings` block is `lazyAttrsOf raw` wherever the vocabulary is registered, never
# freeform-absorbed as a nested aspect). The `id_hash` facet is NOT shared here — its module carries a
# `config.id_hash = aspectIdHash config.key` injection (caller-specific authority, a config-bearing shape), so
# the aspect concern merges it in separately and the identity-view consumers omit it.
{ prelude }:
{
  # `mkClassChannelSemantics { classNames; quirkChannels; }` — the class + channel keySemantics entries.
  #   • each registered class name → `{ category = "class"; }` (gen-aspects → a deferredModule bucket)
  #   • each quirk channel name    → `{ category = "channel"; }` (gen-aspects → a raw passthrough option)
  # `quirkChannels` is a list of channel NAMES (not the `{ <name> = true; }` set) — the caller passes
  # whatever it has (`builtins.attrNames channelSet` / `builtins.attrNames (den.quirks or {})`).
  mkClassChannelSemantics =
    {
      classNames,
      quirkChannels ? [ ],
    }:
    (prelude.genAttrs classNames (_: {
      category = "class";
    }))
    // (prelude.genAttrs quirkChannels (_: {
      category = "channel";
    }));

  # `mkFacetSemantics { merge; }` — the `neededBy`/`settings`/`artifact` facet keySemantics entries (the
  # config-free facets). gen-aspects mounts each entry's `module` via `imports`, so a facet may declare an
  # option (and, for the id_hash facet the concern adds separately, config). `merge` = gen-merge's
  # mkOption/types. Each module is verbatim the type the aspect concern declares — the SINGLE definition, so a
  # typed-view consumer that registers this vocabulary types a `.settings` block as `lazyAttrsOf raw` exactly
  # as the concern does, and the facet surface can never drift between the two.
  mkFacetSemantics =
    { merge }:
    {
      # §B4a reverse injection — a list of aspect refs (literal form) or a single gen-select selector, held
      # `raw` (unmerged). Declared on the aspect submodule, not inside a parametric body.
      neededBy = {
        category = "facet";
        module =
          { ... }:
          {
            options.neededBy = merge.mkOption {
              type = merge.types.raw;
              default = [ ];
              description = "Reverse injection (§B4a): a list of aspect refs (literal form) or a gen-select selector.";
            };
          };
      };
      # Settings SCHEMA (§2.6 source 1) — the aspect's declared `{ <bare-field> = { default; merge ? }; }`. A
      # facet (§2.2), NOT a nested aspect: declared as a structured option so lib/settings.nix reads it as the
      # static field-spec for `gen-settings.mkSchema`. `raw` holds each field record unmerged.
      settings = {
        category = "facet";
        module =
          { ... }:
          {
            options.settings = merge.mkOption {
              type = merge.types.lazyAttrsOf merge.types.raw;
              default = { };
              description = "Settings schema (§2.6): `<bare-field> = { default; merge ? \"replace\"; }`.";
            };
          };
      };
      # The PREBUILT ARM (§4.1 value mode) — an aspect declaring `artifact = <value>` carries a prebuilt,
      # already-elaborated face injected VERBATIM at its receiver (never re-evaluated by den). A facet (§2.2),
      # NOT a nested aspect: declaring it a facet keeps it out of the class/channel branches so `classifyKey`
      # routes it as behaviour, not content. `raw` holds the value unmerged (opaque). Its EXCLUSIVITY with
      # class content is `artifactExclusive` (concern-aspects): a prebuilt aspect's class buckets must be
      # EMPTY. `null` (the default) marks an aspect with no prebuilt arm.
      artifact = {
        category = "facet";
        module =
          { ... }:
          {
            options.artifact = merge.mkOption {
              type = merge.types.raw;
              default = null;
              description = "Prebuilt arm (§4.1 value mode): an already-elaborated face injected verbatim; its class buckets must be empty (artifactExclusive).";
            };
          };
      };
    };
}
