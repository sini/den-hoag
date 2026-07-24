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
  # The `den-aspect:` namespace-identity preimage (§A2), owned by the kernel single-authority
  # (lib/identity-preimage.nix). This is the aspect id_hash AUTHORITY — it calls the shared fn rather
  # than a local formula copy, so a downstream recompute can never drift from it.
  aspectIdHash,
}:
let
  # The shared keySemantics vocabulary builders. The SAME class + channel vocabulary feeds this concern AND
  # every other consumer of the aspect schema (so no channel key falls to freeform), and `mkFacetSemantics`
  # owns the config-free facet MODULES (neededBy/settings/artifact) so their option types live in ONE source
  # shared with the typed-view consumers — a `.settings` block types identically wherever it is registered.
  keySemanticsLib = import ./key-semantics.nix { inherit prelude; };
  # The deferredModule SHAPE helper — the one peel/emptiness rule (class-modules `classSliceOf` uses it too).
  # `artifactExclusive` reads it to decide whether a class content key is a real declaration or an empty no-op.
  inherit (import ./module-shape.nix { inherit prelude; }) isEmptyDeferredModule;

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
      config.id_hash = aspectIdHash config.key;
    };

  # cnf drives gen-aspects' `aspectType`: ONE `keySemantics` map declares every aspect key's
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
    # neededBy/settings/artifact — the config-free facets, from the SHARED vocabulary source (so a typed-view
    # consumer mounts the SAME option types; the settings block is `lazyAttrsOf raw` on both sides).
    // (keySemanticsLib.mkFacetSemantics { inherit merge; })
    // {
      # a MODULE (declares `options.id_hash` AND `config.id_hash` off `config.key`) — NOT a bare option, so it
      # stays local to this concern (the identity authority is caller-specific, unshared with the views).
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
    "artifact" # the §4.1 prebuilt-arm facet — behaviour (a value injection), not class content
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
      # Category off the single keySemantics source: a registered class → "class", a quirk channel
      # → "channel"; anything else is an unregistered key (a typo — freeform-absorbed by gen-aspects) → abort.
      let
        cat = keySemantics.${key}.category or null;
      in
      if cat != null then cat else errors.unknownAspectKey aspectName key;

  # §4.1 THE PREBUILT-ARM EXCLUSIVITY: an aspect declaring `artifact` (the value-mode prebuilt face) must
  # carry NO class content — "its class buckets must be empty; declaring both throws named". A pure decision
  # over an aspect's own CONTENT (the resolved-aspect `content` attrset, or a raw aspect declaration): if
  # `artifact` is present (non-null), every content key that `classifyKey` routes to a `class` category must
  # have an EMPTY deferredModule body (`isEmptyDeferredModule` — the same peel/emptiness rule `classSliceOf`
  # uses, so an all-empty class default from gen-aspects' materialization is NOT a real declaration). A single
  # non-empty class key alongside `artifact` aborts NAMED. Returns `true` on the clean case (a truthy sentinel
  # the caller may `seq`); an aspect with NO `artifact` is trivially exclusive. Total + pure (Law A1) — no
  # fixpoint, just a filter over the content keys. `content.name` frames the abort (a synthetic/degenerate
  # node with no populated name falls back to a key-only label, never a raw missing-attribute throw).
  artifactExclusive =
    content:
    let
      hasArtifact = (content.artifact or null) != null;
      aspectName = content.name or "<unnamed>";
      keys = builtins.filter (k: !(prelude.hasPrefix "_" k)) (builtins.attrNames content);
      # the content keys that are real (non-empty) class declarations — the buckets that must be empty.
      classKeys = builtins.filter (
        k: classifyKey aspectName k == "class" && !(isEmptyDeferredModule content.${k})
      ) keys;
    in
    if hasArtifact && classKeys != [ ] then
      errors.artifactBucketsNonEmpty aspectName (builtins.head classKeys)
    else
      true;
in
{
  inherit
    cnf
    aspectSchema
    classifyKey
    artifactExclusive
    facets
    ;
}
