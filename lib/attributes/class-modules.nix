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

  # THE ONE per-aspect class-slice extraction (Phase 2 Task 2) so the `class-modules` buckets AND `projectClass`
  # — the reach-based projection — share EXACTLY one extraction.
  # `classSliceOf aspect class` = the `class`-C bucket contribution of a SINGLE resolved-aspect node
  # (`{ key; content; }`): the aspect's `content.${class}` deferredModule IFF that key is a registered
  # `class` key (via `classifyKey`, §2.2) and its body is a non-empty declaration. Returns a `[ { module; } ]`
  # list (0 or 1 entry — one class = one content key). A `_`-prefixed / channel / facet key is skipped; an
  # EMPTY body (`{ }` raw, or the typed `{ imports = [ { } ]; }` wrap) is a declared no-op, dropped so bucket
  # counts reflect real content. `projectClass` maps `.module` (bare, for the classSubtreeAt anchor).
  # ── FORWARD-SOURCE-CLASS ACCEPTANCE (iv-b, reach-sourced exemption). A live forward SOURCE class (an
  # unregistered `fromClass` a `meta.__forward` spec on a REACHED node names — output-modules
  # `forwardSourceClassesAt`) MATERIALIZES its bucket instead of aborting, so `routeRemapFor` can move it
  # (the collect-coupling: silencing the abort alone delivers nothing). A NON-exempt unregistered key STILL
  # aborts in `classifyKey` (Law A1/A2 typo-protection preserved). The `exempt` set (a keyset attrset) is
  # threaded per-node from the reach's forward specs; `{ }` for every non-forward node ⇒ byte-identical.
  forwardSourceClassesOf =
    nodes:
    prelude.foldl' (
      acc: n:
      let
        f = (n.content.meta or { }).__forward or null;
      in
      if f == null then acc else acc // { ${f.fromClass} = true; }
    ) { } nodes;

  classSliceOf =
    exempt: aspect: class:
    let
      content = aspect.content;
      # exempt short-circuits BEFORE classifyKey (a forward source never trips the typo-abort); a registered
      # non-class key (channel/facet) still yields `[ ]`; a non-exempt unregistered key aborts in classifyKey.
      isCollectable =
        !(prelude.hasPrefix "_" class)
        && content ? ${class}
        && ((exempt ? ${class}) || classifyKey content.name class == "class");
    in
    if !isCollectable then
      [ ]
    else
      let
        m = content.${class};
      in
      if isEmptyDeferredModule m then
        [ ]
      else
        # Carry the owning resolved-aspect node's `sharedFoldKey` (resolved-aspects.nix, ADDITIVE — `.module`
        # readers ignore it) so the `classSubtreeAt` output-fold can dedup a genuinely-shared host+user aspect
        # cross-scope, keyed identically to the reach/terminal fold. `null` for a node with no stamped key.
        [
          {
            module = m;
            sharedFoldKey = aspect.sharedFoldKey or null;
          }
        ];

  # §2.2 TOTALITY at the projection terminal (ruling 2026-07-14). Classify EVERY non-`_` content key of an
  # aspect via `classifyKey` — a `facet`/`class`/`channel` key passes, a genuinely UNREGISTERED key (a typo
  # like `nixxos`) ABORTS NAMED (`errors.unknownAspectKey`, the identical message the `classifyKey` pass raises).
  # `projectClass` forces this per REACHED aspect before returning its projected-class slice, so a typo'd key
  # on a reachable aspect can NEVER silently vanish on the drv path (`classSliceOf class` alone classifies
  # ONLY the projected class key — the totality hole this closes; spec §2.2/§5 silent-content-loss). Returns
  # `null` (forced for the abort side-effect only); shares its classify-all logic with `classifyAllKeysAt`.
  # NAME ROBUSTNESS: `classifyKey` takes the aspect NAME only to frame the `errors.unknownAspectKey` abort.
  # A reached aspect whose `content` lacks a populated `.name` (a synthetic/degenerate node) must STILL abort
  # with the NAMED `unknownAspectKey`-shaped message on a genuinely unregistered key — never a raw
  # `attribute 'name' missing` throw that masks the real (unregistered-key) fault. `content.name or "<unnamed>"`
  # supplies a key-only fallback name so the abort message stays the intended one.
  assertKeysRegistered =
    exempt: aspect:
    let
      content = aspect.content;
      aspectName = content.name or "<unnamed>";
      # EXEMPT forward-source keys are skipped (they materialize via `classSliceOf`, not abort); every other
      # non-`_` key is classified (a typo aborts NAMED — typo-protection preserved).
      keys = builtins.filter (k: !(prelude.hasPrefix "_" k) && !(exempt ? ${k})) (
        builtins.attrNames content
      );
    in
    # §4.1: alongside the §2.2 key totality, force the prebuilt-arm EXCLUSIVITY over this aspect's content —
    # an aspect declaring `artifact` with non-empty class content aborts NAMED here (the same per-aspect,
    # terminal-forced gate). Inert (the identity pass) for the default `artifactExclusive`.
    builtins.seq (artifactExclusive content) (
      prelude.foldl' (acc: k: builtins.seq (classifyKey aspectName k) acc) null keys
    );

  # inject/reroute (v1 `forwards` tier-1, spec §2.3 resolution) — the resolution-stratum WHOLE-MAP post-
  # transform over the direct per-node class-slice query base, applied HERE (not by `classSliceOf`), which is
  # why `classSubtreeAt` consumes the keyed form rather than re-slicing reach (a reroute/inject fleet would
  # otherwise diverge). WHOLE-MAP, not per-class: a chained reroute `[ {A→B}, {B→C} ]` must land A's content
  # in C via B, which a per-class-INDEPENDENT fold would miss — so this stays a sequential fold over the whole
  # map.
  applyInjectReroute =
    resolutionActs: base:
    let
      # `inject { class; module }` — appends a module to a class bucket. Node-local content (no owning shared
      # aspect), so `sharedFoldKey = null` ⇒ never cross-scope-deduped (v1 anon).
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
              sharedFoldKey = null;
            }
          ];
        }
      ) base injects;

      # `reroute { from; to }` — moves a class's collected content to another class (v1 `forwards` tier-1
      # target). A no-op when nothing was collected for `from`; sequential so a chained reroute composes.
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

  # THE direct per-node class-slice query base. One class's OWN keyed slice at a node = the concatMap of
  # `classSliceOf` (THE per-aspect extraction) over the node's resolved aspects — a DIRECT per-(node,class)
  # query, no whole-map materialization; `genAttrs` forces only the class actually queried (a class with no
  # content is `[ ]`). Same extraction / exempt / empty-drop the terminal projection (`projectClass`) uses.
  classSliceKeyedBaseAt =
    exempt: resolvedAspects: class:
    prelude.concatMap (a: classSliceOf exempt a class) resolvedAspects;

  # §2.2 TOTALITY classification side-effect (Law A1/A2). The direct per-class query base touches only the
  # `classNames` keys, so on its own it would silently skip a genuinely-unregistered typo key on some OTHER
  # content key. The edge/trace path (`classBucketsOf`/`contentsOf`, which forces the bucket spine, NOT
  # `projectClass`) requires that key to abort NAMED, so this pass classifies EVERY non-`_` content key of
  # every resolved aspect (force `classSliceOf` → `classifyKey`), WITHOUT building a bucket. Returns null
  # (forced for the abort side-effect only); `artifactExclusive` is NOT forced here (it rides
  # `assertKeysRegistered` at the projection terminal — the class-modules force path stays abort-faithful).
  classifyAllKeysAt =
    exempt: resolvedAspects:
    prelude.foldl' (
      acc: aspect:
      prelude.foldl' (acc2: k: builtins.seq (classSliceOf exempt aspect k) acc2) acc (
        builtins.filter (k: !(prelude.hasPrefix "_" k)) (builtins.attrNames aspect.content)
      )
    ) null resolvedAspects;

  # The keyed bucket map = the direct per-(node,class) query base + the shared inject/reroute post-transform.
  # `genAttrs classNames` keys ONLY over the registered classes (an exempt forward-source key outside
  # `classNames` is dropped; it is never read positionally, so byte-invisible). The SINGLE class-content
  # source both equations strip / carry, and the record `classSubtreeAt` reads through `class-modules-keyed`.
  keyedBucketsOf =
    self: id:
    let
      resolvedAspects = self.get id "resolved-aspects";
      resolutionActs = (self.get id "declarations").actions.resolution or [ ];
      exempt = forwardSourceClassesOf resolvedAspects;
      # force the §2.2 classification of every content key before returning the query base — so an unregistered
      # key aborts NAMED on the bucket-spine force path (the edge/trace consumers that never reach projectClass).
      base = builtins.seq (classifyAllKeysAt exempt resolvedAspects) (
        prelude.genAttrs classNames (classSliceKeyedBaseAt exempt resolvedAspects)
      );
    in
    applyInjectReroute resolutionActs base;

  # The DIRECT per-node class-slice query ATOM: one class's keyed slice at a node, inject/reroute applied
  # (projected off the whole keyed map so a chained reroute is faithful). The direct (own-node) accessor the
  # class-slice-as-query surface exposes; the REACHABLE descendant-closure (`classSubtreeAt`, output-modules)
  # folds it over `[ id ] ++ scope.descendants`. The equations build it through the shared `keyedBucketsOf`.
  classSliceKeyedAt =
    self: id: class:
    (keyedBucketsOf self id).${class} or [ ];
in
{
  # THE ONE per-aspect class-slice extraction + the §2.2 totality assertion, exported for `projectClass`
  # (output-modules Task 2/3). NEITHER is an equation record — the assembly (attributes/default.nix) selects
  # `class-modules` into the equations map and threads these to `mkOutputModules` separately (a bare function
  # would break gen-resolve's two-stratum equation classification if spread into the map).
  inherit
    classSliceOf
    assertKeysRegistered
    forwardSourceClassesOf
    classSliceKeyedAt
    ;

  class-modules = resolve.attr {
    name = "class-modules";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [
      "resolved-aspects"
      "declarations"
    ];
    # Strip the direct-query keyed map (`genAttrs classNames`, forcing only the bucket read per class) to the
    # bare `.module` lists every reader takes positionally.
    compute =
      self: id:
      let
        km = keyedBucketsOf self id;
      in
      prelude.genAttrs classNames (c: map (e: e.module) (km.${c} or [ ]));
  };

  # The KEYED twin of `class-modules` — the same buckets carrying each entry's `sharedFoldKey`, consumed
  # ONLY by `classSubtreeAt`'s cross-scope shared-aspect dedup (output-modules.nix). The PUBLIC attribute
  # (`class-modules`, read positionally as `[ <deferredModule> ]`) stays bare; this parallel attribute is
  # the record form (`[ { module; sharedFoldKey } ]`) so the output-fold + anchor collapse a shared host+user
  # aspect identically to the reach/terminal fold.
  class-modules-keyed = resolve.attr {
    name = "class-modules-keyed";
    kind = "synthesized";
    stratum = "resolution";
    readsAttrs = [
      "resolved-aspects"
      "declarations"
    ];
    compute = self: id: keyedBucketsOf self id;
  };
}
