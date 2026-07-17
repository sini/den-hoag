# Class-modules stratum — HOAG attribute 9 (spec §2.10). At each scope node, dispatch every resolved
# aspect's content keys three-branch (class / channel / unregistered-error) via
# `concern-aspects.classifyKey`, collect the `class` keys' deferredModule content into per-class module
# lists, and apply the node's resolution-stratum `inject`/`reroute` declarations. The value is inert
# data — `{ <class> = [ <deferredModule> ]; }` — consumed by attribute 12 (`output-modules`) at the
# terminal crossing.
#
# NO EFFECT RUNTIME: the body is field reads + attrset assembly + list appends. classifyKey is table
# dispatch (no algorithm); a channel key is skipped here (its data flows through the collection stratum,
# attributes 10/11), a facet is behaviour (not content), an unregistered key aborts named (Law A1/A2).
#
# Deps: prelude (folds/filters/hasPrefix), resolve (attr). Instance args: classNames (the registered
# output classes = the buckets to collect); classifyKey (the §2.2 three-branch dispatch, which owns the
# unregistered-key abort).
{
  prelude,
  resolve,
}:
{
  classNames,
  classifyKey,
  # §4.1 the prebuilt-arm exclusivity (concern-aspects `artifactExclusive`): a pure per-aspect check that an
  # aspect declaring `artifact` carries no non-empty class content. Threaded into `assertKeysRegistered` (the
  # per-aspect totality gate forced at the projection terminal), so a malformed prebuilt aspect aborts on the
  # eval path. Defaults to the identity pass (`_: true`), so a caller not threading it is byte-identical.
  artifactExclusive ? (_: true),
}:
let
  emptyBuckets = prelude.genAttrs classNames (_: [ ]);

  # A class reference on an inject/reroute declaration is an entry (identity law) or, defensively, a
  # bare class-name string; resolve it to the bucket key (the class name).
  className =
    c:
    if builtins.isAttrs c then
      (c.name or (throw "den-hoag: class-modules: class reference carries no name (${builtins.toJSON c})")
      )
    else
      c;

  # `isEmptyDeferredModule` — under the single typed tree a class key's body is a deferredModule WRAP
  # `{ imports = [ … ]; }` (gen-merge `{ _file; imports }`), so an empty declaration is `{ imports = [ { } ]; }`
  # — NOT `== { }`. The shared `module-shape.nix` helper peels the wrap and judges emptiness (an empty wrap /
  # raw `{ }` body is a declared no-op; a fn/path leaf is real content). Dropping an empty class body keeps
  # bucket counts on REAL content (the F1/F4/F5 no-double-deliver witnesses), byte-parity with the raw walk's
  # `m == { }` drop.
  inherit (import ../module-shape.nix { inherit prelude; }) isEmptyDeferredModule;

  # THE ONE per-aspect class-slice extraction (Phase 2 Task 2, factored out of `classContentOf` below so
  # `class-modules` buckets AND `projectClass` — the reach-based projection — share EXACTLY one extraction).
  # `classSliceOf aspect class` = the `class`-C bucket contribution of a SINGLE resolved-aspect node
  # (`{ key; content; }`): the aspect's `content.${class}` deferredModule IFF that key is a registered
  # `class` key (via `classifyKey`, §2.2) and its body is a non-empty declaration. Returns a `[ { module; } ]`
  # list (0 or 1 entry — one class = one content key). A `_`-prefixed / channel / facet key is skipped; an
  # EMPTY body (`{ }` raw, or the typed `{ imports = [ { } ]; }` wrap) is a declared no-op, dropped so bucket
  # counts reflect real content. `projectClass` maps `.module` (bare, for the classSubtreeAt anchor).
  classSliceOf =
    aspect: class:
    let
      content = aspect.content;
    in
    if
      prelude.hasPrefix "_" class || !(content ? ${class}) || classifyKey content.name class != "class"
    then
      [ ]
    else
      let
        m = content.${class};
      in
      if isEmptyDeferredModule m then [ ] else [ { module = m; } ];

  # §2.2 TOTALITY at the projection terminal (ruling 2026-07-14). Classify EVERY non-`_` content key of an
  # aspect via `classifyKey` — a `facet`/`class`/`channel` key passes, a genuinely UNREGISTERED key (a typo
  # like `nixxos`) ABORTS NAMED (`errors.unknownAspectKey`, the identical message `classContentOf` raises).
  # `projectClass` forces this per REACHED aspect before returning its projected-class slice, so a typo'd key
  # on a reachable aspect can NEVER silently vanish on the drv path (`classSliceOf class` alone classifies
  # ONLY the projected class key — the totality hole this closes; spec §2.2/§5 silent-content-loss). Returns
  # `null` (forced for the abort side-effect only); the classify-all logic is `classContentOf`'s, shared.
  # NAME ROBUSTNESS: `classifyKey` takes the aspect NAME only to frame the `errors.unknownAspectKey` abort.
  # A reached aspect whose `content` lacks a populated `.name` (a synthetic/degenerate node) must STILL abort
  # with the NAMED `unknownAspectKey`-shaped message on a genuinely unregistered key — never a raw
  # `attribute 'name' missing` throw that masks the real (unregistered-key) fault. `content.name or "<unnamed>"`
  # supplies a key-only fallback name so the abort message stays the intended one.
  assertKeysRegistered =
    aspect:
    let
      content = aspect.content;
      aspectName = content.name or "<unnamed>";
      keys = builtins.filter (k: !(prelude.hasPrefix "_" k)) (builtins.attrNames content);
    in
    # §4.1: alongside the §2.2 key totality, force the prebuilt-arm EXCLUSIVITY over this aspect's content —
    # an aspect declaring `artifact` with non-empty class content aborts NAMED here (the same per-aspect,
    # terminal-forced gate). Inert (the identity pass) for the default `artifactExclusive`.
    builtins.seq (artifactExclusive content) (
      prelude.foldl' (acc: k: builtins.seq (classifyKey aspectName k) acc) null keys
    );

  # One resolved aspect's class-bucket contributions: iterate its content keys (skipping the module
  # system's own `_`-prefixed keys), and collect each `class` key's slice (via `classSliceOf` — THE ONE
  # extraction). A `channel`/`facet` key contributes `[ ]`; an unregistered key aborts inside `classifyKey`
  # (§2.2). Each collected entry is a `{ module; }` record; the public bucket strips back to the bare
  # `module` (`splitBuckets`).
  classContentOf =
    aspect:
    let
      content = aspect.content;
      keys = builtins.filter (k: !(prelude.hasPrefix "_" k)) (builtins.attrNames content);
    in
    prelude.foldl' (
      acc: k:
      let
        slice = classSliceOf aspect k;
      in
      if slice == [ ] then acc else acc // { ${k} = (acc.${k} or [ ]) ++ slice; }
    ) { } keys;

  mergeBuckets =
    acc: m:
    prelude.foldl' (acc': cn: acc' // { ${cn} = (acc'.${cn} or [ ]) ++ m.${cn}; }) acc (
      builtins.attrNames m
    );

  # Strip the record-carrying buckets (`{ <class> = [ { module; } ]; }`) to the PUBLIC attribute value:
  # the bare-module buckets `{ <class> = [ <deferredModule> ]; }` — every reader at output-modules reads
  # `.${class}` positionally.
  splitBuckets =
    recBuckets:
    prelude.foldl' (acc: cn: acc // { ${cn} = map (e: e.module) recBuckets.${cn}; }) { } (
      builtins.attrNames recBuckets
    );
in
{
  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, exported for `projectClass`
  # (output-modules Task 2/3). NEITHER is an equation record — the assembly (attributes/default.nix) selects
  # `class-modules` into the equations map and threads these to `mkOutputModules` separately (a bare function
  # would break gen-resolve's two-stratum equation classification if spread into the map).
  inherit classSliceOf assertKeysRegistered;

  class-modules = resolve.attr {
    name = "class-modules";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [
      "resolved-aspects"
      "declarations"
    ];
    compute =
      self: id:
      let
        resolvedAspects = self.get id "resolved-aspects";
        resolutionActs = (self.get id "declarations").actions.resolution or [ ];

        base = prelude.foldl' (acc: a: mergeBuckets acc (classContentOf a)) emptyBuckets resolvedAspects;

        # `inject { class; module }` (spec §2.3 resolution) — appends a module to a class bucket.
        injects = builtins.filter (a: a.__action == "inject") resolutionActs;
        withInject = prelude.foldl' (
          acc: inj:
          let
            cn = className inj.class;
          in
          acc
          // {
            ${cn} = (acc.${cn} or [ ]) ++ [ { module = inj.module; } ];
          }
        ) base injects;

        # `reroute { from; to }` (spec §2.3 resolution) — moves a class's collected content to another
        # class (v1 `forwards` tier-1 target). A no-op when nothing was collected for `from`.
        reroutes = builtins.filter (a: a.__action == "reroute") resolutionActs;
        withReroute = prelude.foldl' (
          acc: rr:
          let
            f = className rr.from;
            t = className rr.to;
          in
          acc
          // {
            ${t} = (acc.${t} or [ ]) ++ (acc.${f} or [ ]);
            ${f} = [ ];
          }
        ) withInject reroutes;
      in
      splitBuckets withReroute;
  };
}
