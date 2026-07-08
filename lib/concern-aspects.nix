# Compile the aspects concern (`den.aspects`) onto gen-aspects. gen-aspects supplies the aspect
# TYPE (structural identity + class-separated content + parametric wrap); den-hoag supplies the
# `neededBy`/`guard`/`drop` submodule surface (consumer obligation #1) via `cnf.aspectModules` /
# `cnf.metaModules`, and the §2.2 three-branch aspect-key dispatch. The resolution algorithm
# (forward expand + joint neededBy+guard fixpoint) lives in attributes/resolved-aspects.nix; this
# file is the TYPE + configuration surface only.
#
# NO EFFECT RUNTIME: an aspect is an inert submodule. `neededBy` (a list of aspect refs or a
# gen-select selector) and `meta.guard` (a `{ pathSet, hasAspect }: bool` predicate, A9.1) and
# `meta.drop` (aspect refs) are STATIC data on the outer submodule — readable without evaluating
# any parametric `__fn` (the §339 well-formedness rule). guards are the only callables, invoked by
# the fixpoint with the path set alone.
{
  prelude,
  aspects,
  merge,
  classNames,
  quirkChannels ? { },
  errors,
}:
let
  # §B4a reverse injection — declared on the aspect submodule (not inside a parametric body).
  # `raw` holds either a literal `[ aspectRef … ]` or a single gen-select selector unmerged.
  neededByModule =
    { ... }:
    {
      options.neededBy = merge.mkOption {
        type = merge.types.raw;
        default = [ ];
        description = "Reverse injection (§B4a): a list of aspect refs (literal form) or a gen-select selector.";
      };
    };

  # §B4b conditional activation — a predicate over the in-flight path set. A9.1: it receives
  # `{ pathSet, hasAspect }` ONLY (no settings, no entity context), so presence never depends on
  # resolved values. `null` (the default) marks an unconditional aspect.
  guardMetaModule =
    { ... }:
    {
      options.guard = merge.mkOption {
        type = merge.types.raw;
        default = null;
        description = "Activation predicate (§B4b): { pathSet, hasAspect }: bool — sees the path set only (A9.1).";
      };
    };

  # Aspect-level constraint — aspect refs pruned from the resolved set post-fixpoint (§Constraints).
  dropMetaModule =
    { ... }:
    {
      options.drop = merge.mkOption {
        type = merge.types.raw;
        default = [ ];
        description = "Aspect-level constraint: aspect refs pruned from this subtree's resolved set.";
      };
    };

  # Settings SCHEMA (§2.6 source 1) — the aspect's declared `{ <bare-field> = { default; merge ? }; }`.
  # A facet (§2.2), NOT a nested aspect: declared as a structured option so lib/settings.nix reads it
  # as the static field-spec for `gen-settings.mkSchema`. `raw` holds each field record unmerged.
  settingsModule =
    { ... }:
    {
      options.settings = merge.mkOption {
        type = merge.types.lazyAttrsOf merge.types.raw;
        default = { };
        description = "Settings schema (§2.6): `<bare-field> = { default; merge ? \"replace\"; }`.";
      };
    };

  # §2.2/§27 raw channel keys — each registered quirk channel is declared as a `raw`-typed option on
  # every aspect, so a channel emission (plain data, an attrset, OR a deferred config-thunk) rides
  # THROUGH the aspect submodule untouched instead of being freeform-absorbed (an attrset would become
  # a nested aspect, a config-fn a wrapped functor). `raw` = single-value passthrough, no merge attempt.
  # Empty when the fleet declares no quirks; `local-collection-data` reads `a.content.<channel>` back.
  channelModules = map (
    name:
    { ... }:
    {
      options.${name} = merge.mkOption {
        type = merge.types.raw;
        default = null;
        description = "Quirk channel `${name}` contribution (§2.5) — rides raw (never merged).";
      };
    }
  ) (builtins.attrNames quirkChannels);

  # Aspect identity (A2) — a content-stable id_hash derived from the structural `key`, so den-hoag
  # aspects are identity-law entries usable by gen-settings (mkSchema/resolveAll route by id_hash) and
  # by `ref` (E6 requires an id_hash-bearing target). Same key ⇒ same id_hash (dedup-coherent with the
  # resolved-aspects fixpoint, which dedups by key).
  idModule =
    { config, ... }:
    {
      options.id_hash = merge.mkOption {
        type = merge.types.str;
        internal = true;
        readOnly = true;
        description = "Content-stable aspect identity (sha256 over the structural key).";
      };
      config.id_hash = builtins.hashString "sha256" "den-aspect:${config.key}";
    };

  # cnf drives gen-aspects' `aspectType`. `classes` become clean deferredModule content buckets;
  # `moduleArgs` is the known-module-arg set gen-aspects uses to tell class-content module fns from
  # parametric guard fns; `aspectModules`/`metaModules` inject den's option surface into every
  # instance / every `meta`.
  cnf = {
    classes = prelude.genAttrs classNames (_: { });
    moduleArgs = {
      settings = true;
      aspects = true;
      env = true;
      host = true;
      user = true;
      # legacy flake-scope injected bindings
      lib = true;
      inputs = true;
      den = true;
      withSystem = true;
    };
    aspectModules = [
      neededByModule
      settingsModule
      idModule
    ]
    ++ channelModules;
    metaModules = [
      guardMetaModule
      dropMetaModule
    ];
    collections = { };
  };

  aspectSchema = aspects.mkAspectSchema cnf;

  # §2.2 three-branch key dispatch: an aspect key is a declared facet, a registered output class,
  # a registered quirk channel, or a definition-time error. (Channels arrive with the quirks
  # concern, Task 5; `quirkChannels` defaults empty until then.)
  facets = [
    "settings"
    "includes"
    "neededBy"
    "meta"
    "tags"
    "projects"
    "name"
    "description"
    "key"
    "id_hash" # injected by idModule — a structural facet, not content
  ];
  # §2.2 three-branch key dispatch — an aspect key is a declared facet, a registered output class, a
  # registered quirk channel, or a definition-time error. `class-modules` (attribute 9) reuses this to
  # route each resolved aspect's content keys: `class` keys collect module content, `channel`/`facet`
  # keys are handled by their own strata, an unregistered key (a typo — freeform-absorbed by gen-aspects)
  # aborts here naming the aspect and key.
  classifyKey =
    aspectName: key:
    if builtins.elem key facets then
      "facet"
    else if builtins.elem key classNames then
      "class"
    else if quirkChannels ? ${key} then
      "channel"
    else
      errors.unknownAspectKey aspectName key;
in
{
  inherit cnf aspectSchema classifyKey;
}
