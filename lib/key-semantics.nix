# The ONE keySemantics vocabulary builder (gen-aspects `cnf.keySemantics`). gen-aspects builds
# every declared aspect key's option GENERICALLY from this map: `class → deferredModule`, `channel → raw
# passthrough`, `facet → the entry's own option/module`. den-hoag declares its whole aspect vocabulary
# through here, so an aspect key's semantics live in ONE place (a single source for the class + channel +
# facet vocabulary, from which `classifyKey` also reads a key's category).
#
# This file owns only the CLASS + CHANNEL half — the categories every consumer of the aspect schema shares
# (identical class + fleet-quirk vocabulary, so a quirk-channel key never falls to freeform). FACET entries
# (neededBy/settings/id_hash) carry caller-specific modules and are merged in by each caller (the aspects
# concern supplies its three facet modules; the identity-view consumers supply none).
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
}
