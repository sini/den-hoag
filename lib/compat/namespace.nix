# den v1 `inputs.den.namespace` (denful/den nix/lib/namespace.nix; attrpath `namespace`, nix/default.nix:35)
# — a curried `name: sources: <flake-parts module>` registering a namespace of den aspects under a short
# top-level name. The corpus calls it `namespace "<name>" <bool>` (nixpedition/oceangreendev/quasigod/
# andrewix/adda/dotfiles/netadr/illusaen); `sources` is a scalar bool in every live call site.
#
# ZERO-COUPLING DIVERGENCE from v1: v1 aliases the top-level `<name>` into a SEPARATE `den.ful.<name>` tree
# (den nix/lib/namespace.nix:33 `mkAliasOptionModule [name] ["den" "ful" name]`, backed by the
# `namespaceType` option in modules/aspects.nix). den-hoag instead aliases into `den.aspects.<name>`, so the
# namespace content rides the EXISTING aspect ingest/compile/deliver pipeline AND the EXISTING den-brackets
# branch-2 resolver (lib/compat/den-brackets.nix:69-73 — `<ns/aspect>` → config.den.aspects.<ns>, with
# resolveWithProvidesFallback for deeper `<ns/aspect/provides-key>` paths) with NO kernel touch, no new
# `den.ful` option, no separate ingest. FIRST-TO-CUT surface: cutting = delete this file + drop
# `defaultFeatures.namespace` + drop the `// compat.flakeNamespace` output line + delete the gate fixture;
# everything else stays byte-green (nothing imports this file).
#
# The module runs in the CONSUMER's flake-parts eval (v1's namespace module did too), so `lib` here is the
# consumer's nixpkgs lib — the substrate's nixpkgs-lib-free `lib/**` purity is untouched (this file is a
# top-level flake OUTPUT, never part of the `import ./lib { … }` assembly).
#
# Threaded: `aspectIdHashFor origin key` (the origin-aware content-address, gen-native `aspectId`) + the
# aspect-key CATEGORY reader (`keyCategory` — the schema's single classification surface, `null` for an
# unregistered key) + the v1 STRUCTURAL keyset (`structuralKeysSet` — provides/policies/excludes/into/classes/
# __*/_module/_, the pipeline-internal surfaces). The latter two together tell a namespace's sub-aspect
# children (unregistered — carry an id) from its class-content / facet / structural keys (registered or
# pipeline-internal — do not), so the origin-stamp walk below descends exactly the aspect nodes.
{
  aspectIdHashFor,
  keyCategory,
  structuralKeysSet,
}:
name: sources:
{ config, lib, ... }:
let
  # den nix/lib/namespace.nix:4-5 — the public output bool + the flake-input mixin sources.
  from = lib.flatten [ sources ];
  isOutput = builtins.elem true from;
  externals = builtins.filter builtins.isAttrs from; # external flake inputs (multi-source mixin)

  # den nix/lib/namespace.nix:33 — top-level `<name>` aliases the namespace tree into `den.aspects.<name>`
  # (the resolver twin), rather than v1's `den.ful.<name>`. NOT `lib.mkAliasOptionModule`: that emits a
  # `mkMerge` definition sentinel, and the bridge's `den.aspects` is a freeform `anything` submodule
  # (lib/compat/bridge.nix — `freeformType = anything`, `v1DeepMerge`) that stores the sentinel RAW instead
  # of discharging it (v1's `den.ful` had a proper `namespaceType` submodule that resolved the merge). So
  # declare `<name>` as a freeform option and COPY its already-merged value into `den.aspects.<name>` — plain
  # data, no sentinel. A config that authors `den.aspects.<name>` DIRECTLY (andrewix my/office/default.nix
  # `den.aspects.my._.office._`) merges into the same tree with no collision (alias-target == authored-target;
  # top-level `<name>` unused there ⇒ contributes an empty attrset the v1DeepMerge folds away).
  aliasModule = {
    options.${name} = lib.mkOption {
      type = lib.types.anything;
      default = { };
    };
    config.den.aspects.${name} = config.${name};
  };

  # den nix/lib/namespace.nix:19-31,45 — external-namespace mixin (`namespace "ours" [ true inputs.mine ]`):
  # merge each external flake's `denful.<name>` into the local tree, stripping the `_`/`__functor` computed
  # aliases so a re-imported bundle does not collide with the recomputed one. CORPUS-ZERO (all live call
  # sites pass a scalar bool ⇒ `externals == [ ]` ⇒ these modules are inert `{ }` imports). Best-effort;
  # parked as a named ceiling if a real multi-source config appears.
  sourceModules = map (src: {
    config.den.aspects.${name} = builtins.removeAttrs (src.denful.${name} or { }) [
      "_"
      "__functor"
    ];
  }) externals;
  classModule = lib.optionalAttrs (externals != [ ]) {
    config.den.classes = lib.mkMerge (map (src: src.denful.${name}.classes or { }) externals);
  };

  # den nix/lib/namespace.nix:35-40 — the PUBLIC (`sources` contains `true`) cross-flake export. Declared
  # inline (self-contained). CEILING: exports the `den.aspects.<name>` subtree, where v1 exports the
  # provider-prefixed `den.ful.<name>` subtree — only diverges for a DOWNSTREAM flake consuming `denful.<name>`
  # by pkgs-by-name (out of single-config corpus scope); a public namespace builds correctly for its own config.
  outputModule = lib.optionalAttrs isOutput {
    options.flake.denful = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.raw;
    };
    config.flake.denful.${name} = config.den.aspects.${name} or { };
  };

  # ORIGIN-STAMP. A namespace IS a local ORIGIN: every aspect it contributes carries `origin=["<name>"]` in
  # its id_hash (via gen-aspects `aspectId` — routed through gen-schema's `hashIdentity`; see
  # aspectIdHashFor). Key + attr-placement stay UNCHANGED — the den-brackets nav, and include/dedup/delivery
  # (all BY-KEY, lib/attributes/resolved-aspects.nix), are byte-neutral; ONLY the internal, never-emitted
  # id_hash content-address shifts (drv-neutral, partition-gated).
  #
  # The walk RE-SOURCES off the RAW authored alias content (`config.${name}` — what aliasModule copies) and
  # NOT the typed merged `config.den.aspects.${name}`: enumerating that merged node's keyset to redefine the
  # same node structurally self-references its keyset → `infinite recursion`. Reading one option (the raw
  # keyset/values) to WRITE another (`den.aspects.<path>.id_hash`) is acyclic. Each node's key is its
  # ATTR-PATH (raw content carries no typed `.key`).
  #
  # Children fall in THREE buckets; only the third is a sub-aspect (recurse + stamp):
  #   • REGISTERED content — a facet/class/channel/structural key (`keyCategory ≠ null`): nixos/home-manager,
  #     settings/includes/meta/tags/… — carry no aspect id ⇒ SKIP.
  #   • STRUCTURAL — a pipeline-internal key (`structuralKeysSet`): `provides` (the sub-aspect CONTAINER, not
  #     an aspect itself), policies/excludes/into/classes/__*/_module/_ — not aspects, and stamping an
  #     id_hash STRING under `provides` would poison the legacy-provides walk's `attrNames provides` ⇒ SKIP.
  #     The `structuralKeysSet` guard is RETAINED even though `keyCategory` also returns `null` for these.
  #   • UNREGISTERED nested-aspect — a key the schema does not recognize (`keyCategory null`) that is not
  #     pipeline-internal ⇒ the actual sub-aspect ⇒ STAMP + recurse.
  # A wrapped-fn / guard aspect authored under a namespace is a bare FUNCTION (not an attrset) ⇒ fails the
  # `isAttrs` recurse-guard below ⇒ SKIP, a named ceiling (corpus-zero, sibling to the externals-mixin
  # ceiling above). id_hash is a `readOnly` option with a default, so one config def legally overrides it;
  # the stamp value reads only the path (never id_hash) ⇒ lazy-safe against its own contribution.
  isSubAspectKey = key: !(structuralKeysSet ? ${key}) && keyCategory key == null;
  stampNode =
    path: node:
    let
      key = builtins.concatStringsSep "/" ([ name ] ++ path);
      subKeys = builtins.filter (k: builtins.isAttrs (node.${k} or null) && isSubAspectKey k) (
        builtins.attrNames node
      );
    in
    {
      id_hash = aspectIdHashFor [ name ] key;
    }
    // lib.genAttrs subKeys (k: stampNode (path ++ [ k ]) node.${k});
  originStampModule = {
    config.den.aspects.${name} = stampNode [ ] (config.${name} or { });
  };
in
{
  imports = [
    aliasModule
    originStampModule # after aliasModule — the raw content exists to re-source + stamp against
    outputModule
    classModule
  ]
  ++ sourceModules;
  # den nix/lib/namespace.nix:54 — inject the resolved namespace content as a module arg named `<name>`
  # (oceangreendev reads `ocean.overlays.nixpkgs` / `ocean.eclipse-plugins.mkFeaturePlugin` via this arg).
  config._module.args.${name} = config.den.aspects.${name} or { };
}
