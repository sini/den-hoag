# SETTINGS-BLOCK LEAF TYPING ON THE evalV1 NAV VIEW (ship-gate). The corpus reflects a dynamic settings
# submodule over the NAVIGATION view of the aspect tree (nix-config schema/_settings-type.nix: a `nodeModule`
# walk of `_module.args.den.aspects`, which the shim binds to `annotatedViewNav config.den`). For each aspect
# node carrying a `.settings` block, every settings field's authored `mkOption { type = ...; }` becomes a
# LEAF option verbatim, so the host's value for that field is type-checked against the authored type.
#
# THE RUNG this pins. The nav view types the aspect tree through the compile view (`typedCompileTree` →
# `mkCompileAspectsType`). If that view does NOT register the `settings` FACET keySemantics the kernel
# declares (`lazyAttrsOf raw`), gen-aspects' freeform default absorbs a `.settings` block as a NESTED aspect
# submodule — so its `isHub = mkOption { type = bool; }` field reflects as an aspectSubmodule, not the authored
# bool option, and the host's `isHub = true` collides at merge (`expected a set but found a Boolean: true`).
# Registering the facet vocabulary in the compile/nav view types `.settings` as the kernel's `lazyAttrsOf raw`;
# the field's mkOption rides through untouched and the leaf types as the authored bool.
#
# This exercises the reflection over the REAL nav view (`denCompat.evalV1`), not a hand-built tree — the
# existing compat-entity-fields coverage hand-declares `settings` via a host-kind field module, bypassing the
# nodeModule-over-nav-view path, so it did not catch this. Red before the facet registration, green after.
{
  denCompat,
  nixpkgsLib,
  denHoagSrc,
  ...
}:
let
  inherit (nixpkgsLib) mkOption types evalModules;

  # v1's structural-key set, the SAME source the corpus's `skipKey` reads (lib/compat/key-classification.nix,
  # exported as `den.lib.aspects.fx.keyClassification.structuralKeysSet`) — imported from the den-hoag source
  # so the reflection walks the aspect tree exactly as the corpus does (`settings` is structural, so the walk
  # handles it as a settings block, never descends into it as a child aspect).
  inherit (import "${denHoagSrc}/lib/compat/key-classification.nix" { }) structuralKeysSet;

  # ── The evalV1 nav view of a settings-bearing aspect (the corpus shape). ──
  ev = denCompat.evalV1 [
    (
      { ... }:
      {
        den.aspects.core.network.syncthing.settings.isHub = mkOption {
          type = types.bool;
          default = false;
        };
      }
    )
  ];
  navAspects = ev.aspects;
  classKeys = ev.classes or { };
  quirkKeys = ev.quirks or { };
  skipKey = k: structuralKeysSet ? ${k} || classKeys ? ${k} || quirkKeys ? ${k};

  # The corpus reflector (nix-config schema/_settings-type.nix `nodeModule`), reproduced verbatim so the
  # fixture fails/passes exactly where the corpus does.
  reshapeSettings =
    raw:
    let
      imports' = raw.imports or [ ];
      config' = raw.config or { };
    in
    {
      imports = imports';
      config = config';
      options = removeAttrs raw [
        "imports"
        "config"
      ];
    };
  hasSettingsDeep =
    node:
    builtins.isAttrs node
    && (
      (node ? settings)
      || nixpkgsLib.any (k: !(skipKey k) && hasSettingsDeep (node.${k} or null)) (builtins.attrNames node)
    );
  nodeModule =
    node:
    let
      ownSettings =
        if node ? settings then
          reshapeSettings node.settings
        else
          {
            imports = [ ];
            config = { };
            options = { };
          };
      settingChildren = nixpkgsLib.filterAttrs (
        k: v: !(skipKey k) && builtins.isAttrs v && hasSettingsDeep v
      ) node;
      childOptions = nixpkgsLib.mapAttrs (
        name: child:
        mkOption {
          type = types.submodule (nodeModule child);
          default = { };
          description = "Settings under ${name}";
        }
      ) settingChildren;
      ownImports = ownSettings.imports or [ ];
      ownConfig = ownSettings.config or { };
    in
    {
      imports = ownImports;
      config = ownConfig;
      options = (ownSettings.options or { }) // childOptions;
    };

  settingsType = types.submodule (nodeModule navAspects);
  # Merge a host `settings.<path> = ...` against the reflected type (the `<entity>.settings` submodule).
  evalSettings =
    hostSettings:
    (evalModules {
      modules = [
        { options.settings = mkOption { type = settingsType; }; }
        { config.settings = hostSettings; }
      ];
    }).config.settings;
in
{
  flake.tests.compat-settings-nav-reflection = {
    # ── the authored bool is ACCEPTED: the settings field reflects as its `mkOption { type = bool; }` leaf,
    #    so the host bool merges through. Before the facet registration this THROWS (`expected a set but found
    #    a Boolean`) because the freeform-absorbed `.settings` typed the field as an aspectSubmodule. ──
    test-nav-settings-bool-accepted = {
      expr = (evalSettings { core.network.syncthing.isHub = true; }).core.network.syncthing.isHub;
      expected = true;
    };
    # ── the leaf is a REAL bool option, not a raw passthrough: a non-bool host value is REJECTED at merge. ──
    test-nav-settings-nonbool-rejected = {
      expr =
        let
          v = (evalSettings { core.network.syncthing.isHub = "not-a-bool"; }).core.network.syncthing.isHub;
        in
        (builtins.tryEval (builtins.deepSeq v v)).success;
      expected = false;
    };
  };
}
