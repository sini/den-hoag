# The class/nested NAME RESERVATION (v1 `nix/lib/aspects/fx/key-classification.nix:69-80` `isNestedKey`,
# pin 11866c16). A bare aspect key equal to a REGISTERED CLASS NAME is CLASS CONTENT by registry
# membership — the reservation — regardless of its content shape (a rich attrset or a plain scalar); it is
# NEVER stripped-as-nested. Classification is by NAME (does the key/sub-key name a registered class), not by
# value inspection. To author a NESTED aspect you use a NON-class name — a key that is neither a facet nor a
# registered class/channel, whose attrset value carries ≥1 registered-named sub-key, classifies NESTED and
# is stripped from its parent (activated only via an explicit `includes`); the corpus follows this by naming
# the shared-HM aspect `home-manager-shared` rather than the reserved class name `home-manager`.
#
# Witnesses:
#   (1)/(2) compile-level: a class-named key (`home-manager`) is CLASS CONTENT for both rich and plain
#           content; a NON-class name (`home-manager-shared`) carrying a class sub-key STRIPS as nested;
#   (3) end-to-end: a nested aspect under a legal (non-class) name, explicitly included at the host, delivers
#       its `nixos` half to the host terminal;
#   (4) the delivered per-user hm content carries NO class-keyed record (`nixos`/`os` absent inside
#       home-manager.users.<u>).
{ denCompat, nixpkgsLib, ... }:
let
  inherit (denCompat) route;

  # (1)/(2) compile-level: a class-named key stays class content (content-shape-agnostic); a non-class
  # aspect name carrying a class sub-key strips as nested.
  c = denCompat.compile {
    # `home-manager` names a registered class → CLASS CONTENT (the reservation), NOT stripped, whatever its
    # content shape.
    aspects.ns.home-manager = {
      programs.zsh.enable = true;
    };
    aspects.plainhm.home-manager.tag = "plain-hm";
    # `home-manager-shared` is a NON-class name → its class-named sub-key (`nixos`) makes it a NESTED aspect,
    # stripped from its parent.
    aspects.nested.home-manager-shared = {
      nixos.users.mutableUsers = false;
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

  # (3) end-to-end: the corpus roles-shape — a nested aspect under a LEGAL (non-class) name is explicitly
  # included at the host (navigated off den.aspects, the roles/default.nix:16 idiom) beside a genuine host hm
  # module; one hm user cell fires the parent-targeted forward.
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
          # a nested aspect named the LEGAL way (non-class) — its os/nixos halves split; activated via the
          # explicit include below. (`home-manager` would be a reserved class name → class content, not a
          # nested aspect — the reservation; the corpus renamed exactly this to `home-manager-shared`.)
          aspects.ns = {
            home-manager-shared = {
              os.programs.zsh.enable = true;
              nixos.tag = "nixos-from-nested";
              nixos.marker.deep = true; # attrset-valued class content
            };
          };
          aspects.roleish = {
            includes = [
              config.den.aspects.ns.home-manager-shared
            ];
          };
          schema.host.includes = [
            "hostc"
            "hmbase"
            "roleish"
          ];
          # the per-user hm cell content, authored the v1-SURFACE way (`homeManager`): v1 keys the hm class
          # camelCase; kebab `home-manager` is den-hoag's GROUNDED class name. A parametric aspect's RESULT has
          # no raw-splice, so a kebab class key freeform-mangles; the v1 spelling grounds to `home-manager` at
          # compile. (The STATIC kebab `home-manager` keys above — `hmbase.home-manager`, `plainhm.home-manager`
          # — are class content, accepted via the raw-splice.)
          aspects.acct =
            { user, ... }:
            {
              homeManager.tag = "hm-${user.name}";
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

  # LOUD RESERVATION-INCLUDE (Option 5 name-reservation): a class-named container navigated + INCLUDED as
  # an aspect. `microvm` names a registered class, so `aspects.virtualization.microvm` is CLASS CONTENT by
  # registry membership; navigating it off the `den` legacy binding (the typed navigation view, the
  # `with den.aspects; …` include surface) collapses it to a keyless `{ imports = … }` deferredModule (a
  # gen-aspects classOptions slot, no aspect `.key`/`.name` identity). Including that value AS an aspect
  # fires the loud reservation error (`errors.reservedClassInclude`) at the include boundary — a message-
  # refinement of the misdirected §2.2 child-key abort, on an input that already threw there. (`config.den`
  # would read the RAW pre-typed value — `{ nixos … }`, no collapse — which is NOT what a v1 `with
  # den.aspects` navigation produces; the `den` module arg is bound to the navigation view, flake-module.nix
  # bindLegacyEnv.)
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  redFleet = denCompat.mkDen [
    (
      { den, ... }:
      {
        den = {
          classes.microvm = { };
          hosts.x86_64-linux.igloo.class = "nixos";
          aspects.virtualization.microvm = {
            nixos.networking.firewall.enable = true;
          };
          aspects.rolec.includes = [ den.aspects.virtualization.microvm ];
          schema.host.includes = [ "rolec" ];
        };
      }
    )
  ];
  redTerm = redFleet.den.output.systems.nixos.${igloo}.modules or [ ];
in
{
  flake.tests.compat-nested-class-named-aspect = {
    # (1) a class-named key with rich content is CLASS CONTENT (present, not stripped) — the reservation is
    #     content-shape-agnostic (name membership, no value inspection).
    test-class-named-key-stays-class-content = {
      expr = c.aspects.ns ? home-manager;
      expected = true;
    };
    # (2) a plain-content class-named key is likewise class content (unchanged).
    test-plain-class-named-key-stays-class-content = {
      expr = c.aspects.plainhm ? home-manager;
      expected = true;
    };
    # (2b) a NON-class aspect name carrying a class sub-key IS a nested aspect → under Model C it PERSISTS as a
    #      typed node the closed gate admits (not stripped); the class-modules walk skips it. It is registered
    #      separately and re-reachable via `includes` — the legal nesting path.
    test-nonclass-named-aspect-persists-as-nested = {
      expr = c.aspects.nested ? home-manager-shared;
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
    # (5) LOUD reservation-include: a class-named aspect (`virtualization.microvm`, `microvm` ∈ classes)
    #     navigated and included AS an aspect collapses to a keyless `{ imports = … }` class-content module →
    #     the closed aspect type REJECTS it (`includesElemType` `rejectBareModuleInclude`, gen-aspects G-c),
    #     the type-native guardrail. The homegrown CI asserter has no message-text channel (no `expectedError`),
    #     so assert the THROW; the green nested-include siblings above prove the guard does NOT fire on a legit
    #     non-class nested include (no false-positive).
    test-reserved-class-named-include-throws-loud = {
      expr = throws redTerm;
      expected = true;
    };
  };
}
