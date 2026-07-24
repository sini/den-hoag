# CLASS-NAME ⟂ ASPECT-NAME COLLISION ON THE evalV1 NAV VIEW (host.settings frontier). The corpus authors an
# aspect NAMED after a class — `den.aspects.core.users.home-manager` (nix-config core/users/home-manager/
# home-manager.nix) — carrying a `.settings` facet PLUS its own class content authored the v1 way (`os`,
# `nixos`, `darwin`, and `homeManager` camelCase). den-hoag grounds v1's `homeManager` class to the built-in
# kebab `home-manager` (v1-class-key-map.nix). When the nav/compile typed view (`typedCompileTree` →
# `mkCompileAspectsType`) keyed its class channels by the GROUNDED kebab name, a `home-manager` channel was
# materialized on every node — so the key `home-manager` under `core.users` resolved to the class-channel
# bucket `{ imports = [ … ]; }`, ABSORBING the child aspect: its `.settings` facet vanished, the corpus
# settings reflector (schema/_settings-type.nix) dropped it, and a bare `host.settings.core.users.home-manager`
# read threw `attribute 'home-manager' missing`.
#
# THE FIX this pins. The typed/nav view keys its class channels by the v1 SURFACE spelling (the spelling the
# corpus authors its class content as — `homeManager`), so the grounded kebab `home-manager` is NO LONGER a
# channel and the aspect named `home-manager` is not shadowed: it types freeform, keeping its `.settings`
# facet. Grounding to the kebab kernel class stays confined to compile (`translateAspect`'s `groundKeys`), so
# a `homeManager` body still routes to the `home-manager` class. v1 never collides (class `homeManager` ≠
# aspect `home-manager`); the grounding shadow manufactured it.
#
# This exercises the REAL nav view (`denCompat.evalV1`) reflected through the corpus `nodeModule` walk (not a
# hand-built tree), and the REAL `compileFull` grounding — red before the re-spelling, green after.
{
  denCompat,
  nixpkgsLib,
  denHoagSrc,
  ...
}:
let
  inherit (nixpkgsLib) mkOption types evalModules;

  # v1's structural-key set — the SAME source the corpus's `skipKey` reads (lib/compat/key-classification.nix),
  # imported from the den-hoag source so the reflection walks the aspect tree exactly as the corpus does.
  inherit (import "${denHoagSrc}/lib/compat/key-classification.nix" { }) structuralKeysSet;

  # ── The evalV1 nav view of the corpus home-manager aspect (an aspect NAMED after the grounded class). ──
  ev = denCompat.evalV1 [
    (
      { ... }:
      {
        den.aspects.core.users.home-manager = {
          settings.useGlobalPkgs = mkOption {
            type = types.bool;
            default = false;
          };
          nixos.services.foo.enable = true;
          # the v1 HM class content, spelled camelCase as the corpus authors it (grounds to `home-manager`).
          homeManager.programs.git.enable = true;
        };
      }
    )
  ];
  navAspects = ev.aspects;
  navNode = navAspects.core.users.home-manager;
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
  evalSettings =
    hostSettings:
    (evalModules {
      modules = [
        { options.settings = mkOption { type = settingsType; }; }
        { config.settings = hostSettings; }
      ];
    }).config.settings;

  # ── (b) grounding intact: a `homeManager`-authored class body routes to the grounded `home-manager` class
  #    through `compileFull` (the flakeModule path, which types the tree via the changed channel keySemantics).
  #    A TOP-LEVEL aspect (not stripped as a nested class-named child) surfaces the compiled record directly. ──
  compiled = denCompat.compileFull {
    aspects.myhm = {
      settings.useGlobalPkgs = mkOption {
        type = types.bool;
        default = false;
      };
      nixos.services.foo.enable = true;
      homeManager.programs.git.enable = true;
    };
  };
  hmRec = compiled.aspects.myhm;
in
{
  flake.tests.compat-settings-nav-hm-collision = {
    # ── (a) THE COLLISION FIX: the aspect named `home-manager` keeps its `.settings` facet on the nav node.
    #    Before the re-spelling the grounded `home-manager` channel absorbed it into `{ imports = [ … ]; }` and
    #    this was `false` (the settings reflector then dropped the node → the bare read threw). ──
    test-collided-node-keeps-settings = {
      expr = navNode ? settings;
      expected = true;
    };
    # ── (a) end-to-end through the corpus reflector: the settings LEAF reflects as its authored bool option,
    #    so a host value merges through. Before the fix the node had no `.settings` → no option was built →
    #    reading `.core.users.home-manager.useGlobalPkgs` threw `attribute 'home-manager' missing`. ──
    test-collided-settings-leaf-reflects = {
      expr =
        (evalSettings { core.users.home-manager.useGlobalPkgs = true; })
        .core.users.home-manager.useGlobalPkgs;
      expected = true;
    };
    # ── (b) GROUNDING INTACT: the `homeManager` class content still routes to the grounded `home-manager`
    #    class at compile — the typed record carries the kebab `home-manager` bucket and NO raw `homeManager`
    #    key (grounding is confined to compile, not the surface typing). ──
    test-homemanager-content-grounds = {
      expr = {
        grounded = hmRec ? "home-manager";
        rawHomeManagerLeaked = hmRec ? homeManager;
      };
      expected = {
        grounded = true;
        rawHomeManagerLeaked = false;
      };
    };
  };
}
