# #74 (the u22-family fix) — a CLASS-NAMED nested aspect follows V1'S AUTHORED spelling law. v1's
# `isClassKey k = classRegistry ? k` reads den.classes AS DECLARED (pin 11866c16
# key-classification.nix:101; the hm battery registers camelCase `homeManager`, home-manager.nix:33), so
# the kebab key `home-manager` is NOT a v1 class key — an aspect child so named (the corpus's
# `core.users.home-manager`, roles/default.nix:16 — value `{ os = …; nixos = …; darwin = …; }`) is a
# NESTED-ASPECT candidate and classifies NESTED (≥1 recognized class sub-key): stripped from its parent,
# activated via its explicit include, its class halves split. The shim's grounded classSet carried BOTH
# spellings, wrongly class-excluding the kebab key — the WHOLE record landed in the host's home-manager
# bucket (inert until #74a delivered that bucket per-user: `home-manager.users.<u>.darwin` does not
# exist, the re-probe abort). The fix: a grounded-ONLY spelling (v1ClassKeyMap values ∖ names) stays
# candidate-ELIGIBLE; content decides (compile.nix mkIsNestedAspectKey).
#
# Witnesses:
#   (1) the corpus shape: a namespace aspect's kebab `home-manager` child carrying class sub-keys is
#       STRIPPED from the parent (nested — never class content in any bucket);
#   (2) the native shape unchanged: a kebab `home-manager` key with PLAIN hm content (no recognized
#       sub-keys) stays CLASS CONTENT;
#   (3) end-to-end: with the nested child explicitly included at the host, its `nixos` half lands at
#       the host terminal AND the per-user delivered hm content carries NO class-keyed record
#       (`nixos`/`os` keys absent inside home-manager.users.<u>).
{ denCompat, nixpkgsLib, ... }:
let
  inherit (denCompat) route;

  # (1)/(2) compile-level: the nested child strips; the plain hm key stays.
  c = denCompat.compile {
    aspects.ns = {
      home-manager = {
        # class-LIKE content (attrset-valued — v1 looksLikeClassContent :49-56 rejects flat scalars)
        os.programs.zsh.enable = true;
        nixos.users.mutableUsers = false;
      };
    };
    aspects.plainhm = {
      home-manager.tag = "plain-hm";
    };
    hosts.x86_64-linux.igloo.class = "nixos";
  };

  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
  igloo = "host:igloo";

  # (3) end-to-end: the corpus roles-shape — the host explicitly includes the nested child (navigated
  # off den.aspects, the roles/default.nix:16 idiom) beside a genuine host hm module; one hm user cell
  # fires the parent-targeted forward.
  fleet = denCompat.mkDen [
    (
      { config, ... }:
      {
        den = {
          hosts.x86_64-linux.igloo = {
            class = "nixos";
            users.tux = { };
          };
          schema.user.parent = "host";
          aspects.hostc.nixos.tag = "nixos-host";
          aspects.hmbase.home-manager.tag = "hm-host-base";
          aspects.ns = {
            home-manager = {
              os.programs.zsh.enable = true;
              nixos.tag = "nixos-from-nested";
              nixos.marker.deep = true; # attrset-valued — class-like (v1 :49-56)
            };
          };
          aspects.roleish = {
            includes = [
              config.den.aspects.ns.home-manager
            ];
          };
          schema.host.includes = [
            "hostc"
            "hmbase"
            "roleish"
          ];
          aspects.acct =
            { user, ... }:
            {
              home-manager.tag = "hm-${user.name}";
            };
          schema.user.includes = [ "acct" ];
          policies.hm-forward =
            { user, host, ... }:
            [
              (route {
                fromClass = "home-manager";
                intoClass = host.class;
                intoPath = [
                  "home-manager"
                  "users"
                  user.name
                ];
                __extra.appendToParent = true;
              })
            ];
        };
      }
    )
  ];
  hostTerm = fleet.den.output.systems.nixos.${igloo}.modules or [ ];
  hostTermTags = builtins.concatMap tags hostTerm;
  # The delivered per-user hm content OBSERVED at the crossed config (a top-level freeform absorber — the
  # same `lazyAttrsOf raw` the terminal/placer use), not by walking the placed module's attr SHAPE (which the
  # arg-threading rewrite makes a top-level function). `home-manager.users.tux` = the cell's resolved hm.
  crossedHm =
    (nixpkgsLib.evalModules {
      modules = [
        { config._module.freeformType = nixpkgsLib.types.lazyAttrsOf nixpkgsLib.types.raw; }
      ]
      ++ hostTerm;
    }).config.home-manager or { };
  userHmTux = crossedHm.users.tux or { };
  userHmTags = tags userHmTux;
  userHmHasClassKeys = (userHmTux ? nixos) || (userHmTux ? os) || (userHmTux ? darwin);
in
{
  flake.tests.compat-nested-class-named-aspect = {
    # (1) the kebab class-named child with class sub-keys is STRIPPED from the parent (nested).
    test-nested-child-stripped = {
      expr = c.aspects.ns ? home-manager;
      expected = false;
    };
    # (2) a plain-content kebab hm key stays CLASS CONTENT (the native shape unchanged).
    test-plain-hm-key-stays-class-content = {
      expr = c.aspects.plainhm ? home-manager;
      expected = true;
    };
    # (3) end-to-end: the explicitly-included nested child's nixos half lands at the host terminal…
    test-nested-nixos-half-lands-at-host = {
      expr = builtins.elem "nixos-from-nested" hostTermTags;
      expected = true;
    };
    # …the delivered per-user hm content carries NO class-keyed record (the u22-family abort shape is
    #    impossible). R-ROOT-FILTER (ledger u23(b) → u25): `hm-host-base` is host SCOPE-OWN
    #    (schema.host.includes) and the cell owns home-manager, so it is DROPPED from the cell's gather —
    #    only the cell's own `hm-tux` survives (v1 filterRootModules; a den.default-shared host hm would
    #    survive, none here). Under Phase 4 the projection realizes this NATURALLY: the descendant-driven
    #    route's SOURCE is `reach cell` — the cell's OWN subtree, which does NOT include the host node, so
    #    the host-own `hm-host-base` is absent from the cell's gather and only the cell's own `hm-tux` remaps.
    #
    # PHASE 4 DELIVERED (the #10 hm-user-detect descendant-driven route, Task 2): terminalModulesAt =
    # projectClass; the per-user nested hm content reaches the HOST terminal via the hm-FORWARD route the
    # host gathers from its descendant cell (`parentTargetedRoutesAt`). `home-manager.users.tux` is present
    # with the cell's OWN `hm-tux` content, class-record CLEAN (hasClassKeys = false — the u22-family abort
    # shape is impossible). The mark-pending marker was mis-scoped (hm-forward content, not a host-aspects
    # reach-edge — that is Phase 5). (The sibling test-nested-nixos-half-lands-at-host STAYS GREEN — that
    # content is the descendant cell's OWN nixos slice, reached via the Task-1 structural-descendant edge.)
    test-user-hm-clean-of-class-records = {
      expr = {
        tags = userHmTags;
        hasClassKeys = userHmHasClassKeys;
      };
      expected = {
        tags = [ "hm-tux" ];
        hasClassKeys = false;
      };
    };
  };
}
