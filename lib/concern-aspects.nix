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
  # The entity KIND names bindable as aspect moduleArgs (`{ host, user, datacenter, ... }:`). Kinds are
  # USER-DECLARED schema (assembly spec §2.2), so core is kind-AGNOSTIC: mkDen derives this from the
  # discovered schema (`entity.discoverKinds`) at assembly. REQUIRED (no default) so this file carries ZERO
  # kind-name literals — the standard `host`/`user` set arrives from the probe, never a core constant.
  kindNames,
  errors,
}:
let
  # Shape B — the shared class + channel keySemantics builder. The SAME class + channel vocabulary feeds
  # this concern AND every other consumer of the aspect schema, so no channel key falls to freeform.
  keySemanticsLib = import ./key-semantics.nix { inherit prelude; };
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

  # cnf drives gen-aspects' `aspectType` — Shape B: ONE `keySemantics` map declares every aspect key's
  # semantics. gen-aspects builds each key's option generically: `class → deferredModule` content bucket,
  # `channel → raw` passthrough (an emission — plain data, attrset, or config-thunk — rides untouched, never
  # freeform-absorbed), `facet → the entry's `module`` (a full module mounted via `imports`, so a facet may
  # declare an option AND config — `id_hash` derives from `config.key`). `moduleArgs` is the known-module-arg
  # set gen-aspects uses to tell a class-content module fn from a parametric guard fn; `metaModules` inject
  # den's `guard`/`drop` surface into every `meta`. (The old parallel `classes` + `channelModules` +
  # `aspectModules` split is gone — one vocabulary source, `key-semantics.nix`, shared across consumers.)
  keySemantics =
    (keySemanticsLib.mkClassChannelSemantics {
      inherit classNames;
      quirkChannels = builtins.attrNames quirkChannels;
    })
    // {
      neededBy = {
        category = "facet";
        module = neededByModule;
      };
      settings = {
        category = "facet";
        module = settingsModule;
      };
      # a MODULE (declares `options.id_hash` AND `config.id_hash` off `config.key`) — NOT a bare option.
      id_hash = {
        category = "facet";
        module = idModule;
      };
    };
  cnf = {
    inherit keySemantics;
    # `settings`/`aspects` are the FACET vocabulary (static, kind-independent); the entity coordinates are
    # the DECLARED kinds (kind-generic — zero kind-name literals; `datacenter`/`rack`/… bind exactly like
    # `host`/`user`). gen-aspects uses this set to tell a class-content module fn from a parametric guard fn.
    moduleArgs = {
      settings = true;
      aspects = true;
    }
    // prelude.genAttrs kindNames (_: true);
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
    # Structural facets FIRST — `name`/`includes`/`meta`/`tags`/`projects`/`key`/`description` are built-in
    # submodule options, NOT `keySemantics` entries; `settings`/`neededBy`/`id_hash` ARE keySemantics facet
    # entries but are listed here too, so the class-modules walk skips them without a keySemantics lookup.
    if builtins.elem key facets then
      "facet"
    else
      # Category off the single keySemantics source (Shape B): a registered class → "class", a quirk channel
      # → "channel"; anything else is an unregistered key (a typo — freeform-absorbed by gen-aspects) → abort.
      let
        cat = keySemantics.${key}.category or null;
      in
      if cat != null then cat else errors.unknownAspectKey aspectName key;
in
{
  inherit
    cnf
    aspectSchema
    classifyKey
    facets
    ;
}
