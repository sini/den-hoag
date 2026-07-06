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

  # One resolved aspect's class-bucket contributions: iterate its content keys (skipping the module
  # system's own `_`-prefixed keys), classify each, and collect the non-empty `class` buckets. A
  # `channel`/`facet` key is skipped; an unregistered key aborts inside `classifyKey` (§2.2).
  classContentOf =
    aspect:
    let
      content = aspect.content;
      keys = builtins.filter (k: !(prelude.hasPrefix "_" k)) (builtins.attrNames content);
    in
    prelude.foldl' (
      acc: k:
      if classifyKey content.name k == "class" then
        let
          m = content.${k};
        in
        if m == { } then acc else acc // { ${k} = (acc.${k} or [ ]) ++ [ m ]; }
      else
        acc
    ) { } keys;

  mergeBuckets =
    acc: m:
    prelude.foldl' (acc': cn: acc' // { ${cn} = (acc'.${cn} or [ ]) ++ m.${cn}; }) acc (
      builtins.attrNames m
    );
in
{
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
          acc // { ${cn} = (acc.${cn} or [ ]) ++ [ inj.module ]; }
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
      withReroute;
  };
}
