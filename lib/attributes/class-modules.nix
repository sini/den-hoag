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

  # THE ONE per-aspect class-slice extraction (Phase 2 Task 2, factored out of `classContentOf` below so
  # `class-modules` buckets AND `projectClass` — the reach-based projection — share EXACTLY one extraction).
  # `classSliceOf aspect class` = the `class`-C bucket contribution of a SINGLE resolved-aspect node
  # (`{ key; content; __denShared }`): the aspect's `content.${class}` deferredModule IFF that key is a
  # registered `class` key (via `classifyKey`, §2.2) and its body is a non-empty declaration. Returns a
  # `[ { module; shared; } ]` list (0 or 1 entry — one class = one content key) — `shared` is the node's
  # `__denShared` flag (Track A rung 1: true iff the aspect roots/descends the radiated `den.default`
  # subtree). A `_`-prefixed / channel / facet key is skipped; a `{ }` body is a declared no-op, dropped so
  # bucket counts reflect real content. `projectClass` maps `.module` (bare, for the classSubtreeAt anchor).
  classSliceOf =
    aspect: class:
    let
      content = aspect.content;
      shared = aspect.__denShared or false;
    in
    if
      prelude.hasPrefix "_" class || !(content ? ${class}) || classifyKey content.name class != "class"
    then
      [ ]
    else
      let
        m = content.${class};
      in
      if m == { } then
        [ ]
      else
        [
          {
            module = m;
            inherit shared;
          }
        ];

  # One resolved aspect's class-bucket contributions: iterate its content keys (skipping the module
  # system's own `_`-prefixed keys), and collect each `class` key's slice (via `classSliceOf` — THE ONE
  # extraction). A `channel`/`facet` key contributes `[ ]`; an unregistered key aborts inside `classifyKey`
  # (§2.2). Each collected entry is a `{ module; shared; }` record; the public bucket strips back to the
  # bare `module` (byte-identical), the `shared` flag riding the `__shared` sidecar (R-ROOT-FILTER twin, A2).
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

  # Split the record-carrying buckets (`{ <class> = [ { module; shared; } ]; }`) into the PUBLIC
  # attribute value: the bare-module buckets `{ <class> = [ <deferredModule> ]; }` (byte-identical to
  # the pre-marker output — every existing reader at output-modules reads `.${class}` positionally) PLUS
  # the `__shared` sidecar `{ <class> = [ <bool> ]; }` positionally aligned with each class bucket. The
  # `__`-prefix keeps the sidecar OUT of every class-name read (readers access `.${class}` by name, never
  # `attrNames` the value expecting only classes — checked at output-modules `classModulesAt` consumers),
  # so this is purely additive (A1: no consumer behavior change yet — A2 reads the sidecar).
  splitBuckets =
    recBuckets:
    let
      cns = builtins.attrNames recBuckets;
    in
    (prelude.foldl' (acc: cn: acc // { ${cn} = map (e: e.module) recBuckets.${cn}; }) { } cns)
    // {
      __shared = prelude.foldl' (acc: cn: acc // { ${cn} = map (e: e.shared) recBuckets.${cn}; }) { } cns;
    };
in
{
  # THE ONE per-aspect class-slice extraction, exported for `projectClass` (output-modules Task 2). It is
  # NOT an equation record — the assembly (attributes/default.nix) selects `class-modules` into the equations
  # map and threads `classSliceOf` to `mkOutputModules` separately (a bare function would break gen-resolve's
  # two-stratum equation classification if spread into the map).
  inherit classSliceOf;

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

        # `inject { class; module }` (spec §2.3 resolution) — appends a module to a class bucket. A node's
        # own inject is a SCOPE-OWN declaration (`shared = false`); it is never `den.default`-radiated root
        # content, so it is never filtered by the R-ROOT-FILTER twin.
        injects = builtins.filter (a: a.__action == "inject") resolutionActs;
        withInject = prelude.foldl' (
          acc: inj:
          let
            cn = className inj.class;
          in
          acc
          // {
            ${cn} = (acc.${cn} or [ ]) ++ [
              {
                module = inj.module;
                shared = false;
              }
            ];
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
