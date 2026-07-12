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
{ denCompat, ... }:
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
  userHm = builtins.concatMap (
    m: if builtins.isAttrs m && m ? home-manager then [ (m.home-manager.users.tux or { }) ] else [ ]
  ) hostTerm;
  userHmTags = builtins.concatMap tags userHm;
  userHmHasClassKeys = builtins.any (m: m ? nixos || m ? os || m ? darwin) userHm;
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
    # …the delivered per-user hm content = the genuine host hm base + the cell's own, and carries NO
    #    class-keyed record (the u22-family abort shape is impossible).
    test-user-hm-clean-of-class-records = {
      expr = {
        tags = userHmTags;
        hasClassKeys = userHmHasClassKeys;
      };
      expected = {
        tags = [
          "hm-host-base"
          "hm-tux"
        ];
        hasClassKeys = false;
      };
    };
  };
}
