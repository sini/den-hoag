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
  # The shared keySemantics vocabulary builders. The SAME class + channel vocabulary feeds this concern AND
  # every other consumer of the aspect schema (so no channel key falls to freeform), and `mkFacetSemantics`
  # owns the config-free facet MODULES (neededBy/settings/artifact) so their option types live in ONE source
  # shared with the typed-view consumers — a `.settings` block types identically wherever it is registered.
  keySemanticsLib = import ./key-semantics.nix { inherit prelude; };
  # The deferredModule SHAPE helper — the one peel/emptiness rule (class-modules `rawSliceOf` uses it too).
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
    // (keySemanticsLib.mkFacetSemantics { inherit merge; });
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

  # §2.2 key ROUTING (attribute 9 class-modules reuses this): map an aspect key to its routing bucket by
  # reading its category from the ONE authority — the schema (`aspectSchema.keyCategory`, the native-structural
  # + declared class/channel/facet surface). `class` keys collect module content, `channel` keys emit, and
  # `facet` covers the config-free facets, the native structural options, AND an unregistered key (`keyCategory
  # null`). NEVER throws — typo protection is the closed gate's job now, not the kernel's: a `null` verdict is
  # either a typo (already rejected AT the type) or a legit freeform nested-aspect key surviving in content
  # (the strip is retired), and a throw would abort on the latter (`artifactExclusive` iterates every content
  # key on every reached aspect). `aspectName` is unused (kept for the call signature).
  classifyKey =
    _aspectName: key:
    let
      cat = aspectSchema.keyCategory key;
    in
    if cat == "class" then
      "class"
    else if cat == "channel" then
      "channel"
    else
      "facet";

  # §4.1 THE PREBUILT-ARM EXCLUSIVITY: an aspect declaring `artifact` (the value-mode prebuilt face) must
  # carry NO class content — "its class buckets must be empty; declaring both throws named". A pure decision
  # over an aspect's own CONTENT (the resolved-aspect `content` attrset, or a raw aspect declaration): if
  # `artifact` is present (non-null), every content key that `classifyKey` routes to a `class` category must
  # have an EMPTY deferredModule body (`isEmptyDeferredModule` — the same peel/emptiness rule `rawSliceOf`
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
    ;
}
