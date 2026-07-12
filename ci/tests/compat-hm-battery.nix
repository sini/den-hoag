# #68 (ledger u18 Family A) — the v1-AMBIENT home-manager battery port: the USER-SCOPE emitter
# (`hm-user-detect`, the v1 userDetectFn ∘ userForward — legacy/batteries/home-manager.nix carries the
# full v1 census + cites; builtins.nix provisions the same record for the bridge path). The emitter fires
# at every (user,host) cell, gated v1-style (`isOsSupported && hasClass`, home-env.nix at the pin) via the
# probe-safe intoClass value-gate, and emits the tier-1 hm forward: `homeManager → host.class` at
# `[ home-manager users <userName> ]` with `appendToParent` (#53c) — so the cell's home-manager bucket
# lands NESTED in the host's nixos terminal (the #66 consumption law).
#
# Witnesses:
#   (1) the CORPUS SHAPE — a `resolve.to "user"`-derived cell (env-users, the userDetectFn path): the
#       resolved user entity carries `classes = [ "homeManager" ]` (the corpus registry shape; wrapLeaf
#       carries the FULL entity — ledger u11), the ambient emitter fires at the derived cell, and the
#       host terminal carries the nested hm module; the edge is host-rooted + appendToParent-annotated.
#   (2) the DECLARED-USER ceiling — a `host.users`-declared user (v1's policyFn population): on the
#       mkDen-DIRECT path the declared entity is FIELD-LESS (den-hoag core entities carry no authored
#       fields; only the BRIDGE's registry stamps ride them — the instantiateFor/hmModuleFor posture), so
#       `user.classes` is absent ⇒ hasClass false ⇒ the forward DROPS (the defined no-op). The corpus
#       path is unaffected (its humans arrive via resolve.to with full registry entities — witness 1);
#       a bridge-path declared-hm-user rides the registry stamp (corpus-zero: no corpus host declares
#       `host.users`). Pinned so the ceiling is a FACT, not a surprise.
#   (3) the NO-HM-USER identity — a resolved user withOUT the homeManager class (the corpus
#       identity-only `classes = [ ]` shape): the forward drops — no hm module at the terminal, no
#       hm edge at the host root.
{ denCompat, denHoag, ... }:
let
  R = denHoag.policy.resolve;

  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
  igloo = "host:igloo";
  # the nested hm modules the host nixos terminal carries: { home-manager.users.<n> = <module>; }.
  hostHmUsers =
    fleet:
    builtins.concatMap (
      m:
      if builtins.isAttrs m && m ? home-manager then
        builtins.attrNames (m.home-manager.users or { })
      else
        [ ]
    ) (fleet.den.output.systems.nixos.${igloo}.modules or [ ]);
  hostHmTagsOf =
    fleet: user:
    builtins.concatMap (
      m:
      if builtins.isAttrs m && m ? home-manager then tags (m.home-manager.users.${user} or { }) else [ ]
    ) (fleet.den.output.systems.nixos.${igloo}.modules or [ ]);
  hmEdgesAtHost =
    fleet:
    builtins.filter (
      e: (e.source.class or null) == "home-manager" && (e.target.class or null) == "nixos"
    ) (fleet.den.graph.trace igloo);

  # (1)/(3): the corpus shape — env-users (a resolve-family name, resolve-family-names.nix) resolves a
  # FULL user entity onto the firing host; `classes` toggles the hm class (the registry field).
  mkResolved =
    classes:
    denCompat.mkDen [
      {
        den.hosts.x86_64-linux.igloo.class = "nixos";
        den.schema.user.parent = "host";
        den.aspects.hostc.nixos.tag = "nixos-host";
        den.schema.host.includes = [ "hostc" ];
        den.aspects.acct =
          { user, ... }:
          {
            home-manager.tag = "hm-${user.name}";
          };
        den.schema.user.includes = [ "acct" ];
        den.policies.env-users =
          { host, ... }:
          [
            (R.to "user" {
              user = {
                name = "tux";
                userName = "tux";
                inherit classes;
              };
            })
          ];
      }
    ];
  resolved = mkResolved [ "homeManager" ];
  noHm = mkResolved [ ];

  # (2): a host.users-DECLARED user (the mkDen-direct field-less entity — the ceiling fixture).
  declared = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.igloo = {
        class = "nixos";
        users.tux.classes = [ "homeManager" ]; # authored field — NOT carried by the field-less entity
      };
      den.schema.user.parent = "host";
      den.aspects.hostc.nixos.tag = "nixos-host";
      den.schema.host.includes = [ "hostc" ];
      den.aspects.acct =
        { user, ... }:
        {
          home-manager.tag = "hm-${user.name}";
        };
      den.schema.user.includes = [ "acct" ];
    }
  ];
in
{
  flake.tests.compat-hm-battery = {
    # (1) the resolve.to-derived cell: the ambient emitter fires, the forward parent-targets the host,
    #     and the host's nixos terminal carries home-manager.users.tux with the cell's hm content.
    test-resolved-user-hm-lands-at-host-terminal = {
      expr = {
        users = hostHmUsers resolved;
        tags = hostHmTagsOf resolved "tux";
      };
      expected = {
        users = [ "tux" ];
        tags = [ "hm-tux" ];
      };
    };
    # …the edge is host-rooted (the #53c parent target) and appendToParent-annotated (v1 route.nix:813).
    test-resolved-user-edge-host-rooted = {
      expr = map (e: {
        root = e.target.root;
        a2p = e.annotations.appendToParent or false;
      }) (hmEdgesAtHost resolved);
      expected = [
        {
          root = igloo;
          a2p = true;
        }
      ];
    };

    # (2) the declared-user CEILING (mkDen-direct): the field-less entity carries no `classes`, so the
    #     forward drops — pinned as a fact. The corpus's humans ride witness 1's path; a bridge-path
    #     declared user rides the registry stamp (corpus-zero).
    test-declared-user-fieldless-drops = {
      expr = {
        users = hostHmUsers declared;
        edges = builtins.length (hmEdgesAtHost declared);
      };
      expected = {
        users = [ ];
        edges = 0;
      };
    };

    # (3) identity: a non-hm resolved user's forward DROPS (intoClass null ⇒ __dropped) — no hm module
    #     at the terminal, no hm edge at the host root.
    test-no-hm-user-terminal-clean = {
      expr = hostHmUsers noHm;
      expected = [ ];
    };
    test-no-hm-user-no-edge = {
      expr = builtins.length (hmEdgesAtHost noHm);
      expected = 0;
    };
  };
}
