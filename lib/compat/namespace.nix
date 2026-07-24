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
in
{
  imports = [
    aliasModule
    outputModule
    classModule
  ]
  ++ sourceModules;
  # den nix/lib/namespace.nix:54 — inject the resolved namespace content as a module arg named `<name>`
  # (oceangreendev reads `ocean.overlays.nixpkgs` / `ocean.eclipse-plugins.mkFeaturePlugin` via this arg).
  config._module.args.${name} = config.den.aspects.${name} or { };
}
