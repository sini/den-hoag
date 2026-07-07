# Task 1 fixture — three kinds (env, host, user), a handful of instances, a membership
# list — shaped as a `denHoag.mkDen` module list so later tasks extend it in place.
# Kinds use gen-schema's raw string `parent` form; the den entry-valued
# `{ parent; contentClass; fields; }` surface compilation lands with the class wiring
# (Task 2). No aspects yet.
let
  schema = {
    config.den.schema = {
      env = {
        parent = null;
      };
      host = {
        parent = "env";
      };
      user = {
        parent = "host";
      };
    };
  };

  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      host.blade = { };
      user.alice = { };
      user.bob = { };
    };
  };

  # Both hosts sit in prod; alice is a member on axon; bob carries no membership tuple.
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
        }
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.blade;
          };
        }
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };

  # A `member` tuple emitted at a membership-derived scope (A5 violation). The declaration-
  # stratum classifier (Task 3) sets `membershipDerived`; Task 1 enforces the abort.
  memberAtCell =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.bob;
          };
          via = {
            policy = "grantStaff";
            scope = "cell:prod/axon/alice";
            membershipDerived = true;
          };
        }
      ];
    };

  # A second alice-on-axon tuple — membership is a relation, so this must not add a cell.
  duplicate =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  # ── the full r2 acceptance fleet (Task 11 / A11) ───────────────────────────────────────────────────
  # env:prod ⊇ { host:igloo, host:web-1 } (both nixos), user:tux on both + user:admin on igloo only,
  # cluster:k3s linking both hosts (a pure link/root kind — no membership tuple, so NOT a product axis).
  # Exercises every concern end to end: aspect radiation (neededBy), the projects facet (gruvbox-theme
  # projecting colorScheme onto `hasSetting "colorScheme"`), a host-scoped override + a `configure` policy
  # slot, two fleet-wide quirk channels (ssh-peers gathered at the cluster via the link; http-backends
  # with two same-position producers), and a `database` demand cascade emitted once at the cluster.
  #
  # A function of `{ denHoag; nixpkgs; permute }`: `denHoag` supplies the identity-law vocabulary
  # (sel/declare/classes/hasSetting); `nixpkgs` (when non-null) makes the nixos class cross to REAL NixOS
  # systems; `permute` reverses the UNRELATED policy modules (link/demand/configure) — an orthogonal
  # permutation the http-backends channel order must be invariant under (order is pinned by producer
  # identity, never policy declaration order). The `system` aspect sets `networking.hostName = host.name`,
  # so a crossed `nixosConfigurations.<host>` evaluates its hostName to the host entity name.
  acceptance =
    {
      denHoag,
      nixpkgs ? null,
      permute ? false,
    }:
    let
      inherit (denHoag) sel declare hasSetting;
      D = denHoag.internal.demand;

      accSchema = {
        config.den.schema = {
          env.parent = null;
          host.parent = "env";
          user.parent = "host";
          cluster.parent = null; # a link/root kind, not a containment (cell) dimension
        };
      };
      accInstances = {
        config.den = {
          env.prod = { };
          host.igloo = { };
          host.web-1 = { };
          user.tux = { };
          user.admin = { };
          cluster.k3s = { };
        };
      };
      accMembership =
        { config, ... }:
        {
          config.den.membership = [
            {
              coords = {
                env = config.den.env.prod;
                host = config.den.host.igloo;
              };
            }
            {
              coords = {
                env = config.den.env.prod;
                host = config.den.host.web-1;
              };
            }
            {
              coords = {
                host = config.den.host.igloo;
                user = config.den.user.tux;
              };
            }
            {
              coords = {
                host = config.den.host.web-1;
                user = config.den.user.tux;
              };
            }
            {
              coords = {
                host = config.den.host.igloo;
                user = config.den.user.admin;
              };
            }
          ];
        };
      accClassing.config.den.contentClass = {
        host = "nixos";
        user = "home-manager";
      };
      accNixpkgs.config.den.nixpkgs = nixpkgs;
      accQuirks.config.den.quirks = {
        ssh-peers = { };
        http-backends = { };
      };

      # The k8s-style demand cascade: database (depth 1) desugars into secret + connect (depth 0).
      cascadeKinds = {
        database = {
          below = [
            "secret"
            "connect"
          ];
          resolve = d: _ctx: {
            resources."db/${d.subject.id_hash}".engine = "postgres";
            demands = [
              (D.demand {
                kind = "secret";
                subject = d.subject;
              })
              (D.demand {
                kind = "connect";
                subject = d.subject;
              })
            ];
          };
        };
        secret = {
          resolve = d: ctx: {
            resources."secret/${d.subject.id_hash}".seed = ctx.secretSeed or "«none»";
          };
        };
        connect = {
          resolve = d: _ctx: {
            wiring.endpoint = "svc/${d.subject.id_hash}";
          };
        };
      };
      accDemandKinds = {
        config.den.demandKinds = cascadeKinds;
        config.den.demandContext.secretSeed = "prod-seed";
      };

      # ── aspects ──────────────────────────────────────────────────────────────────────────────────
      # `system` — the nixos-class content: `networking.hostName = host.name`, included at BOTH hosts, so
      # each host's nixos config binds its own name. This is the terminal-crossing assertion's target.
      # `nixpkgs.hostPlatform` is required for a NixOS eval to resolve (even reading `networking.hostName`
      # forces the platform gate); it stays inert unless `pkgs` is forced, which reading a hostName never does.
      systemMod =
        { config, ... }:
        {
          config.den.aspects.system.nixos =
            { host, ... }:
            {
              networking.hostName = host.name;
              nixpkgs.hostPlatform = "x86_64-linux";
            };
          config.den.include = [
            {
              at = config.den.host.igloo;
              aspects = [ config.den.aspects.system ];
            }
            {
              at = config.den.host.web-1;
              aspects = [ config.den.aspects.system ];
            }
          ];
        };

      # `app` — the projection TARGET: declares a `colorScheme` setting, radiates to every user cell under
      # prod (neededBy user). `gruvbox-theme` — the fleet-root PROJECTOR: projects colorScheme onto every
      # aspect declaring a colorScheme field (`hasSetting`), attached at env:prod (one fleet-scope layer).
      settingsMod =
        { config, ... }:
        {
          config.den.aspects.app = {
            neededBy = sel.kind config.den.schema.user;
            settings.colorScheme.default = "base";
          };
          config.den.aspects.gruvbox-theme.projects = [
            {
              select = hasSetting "colorScheme";
              set.colorScheme = "fleet-gruvbox";
            }
          ];
          config.den.include = [
            {
              at = config.den.env.prod;
              aspects = [
                config.den.aspects.app
                config.den.aspects.gruvbox-theme
              ];
            }
          ];
          # a host-scoped DIRECT override (wins by specificity over the fleet projection at the igloo cell).
          config.den.settings.layers = [
            {
              at.host = config.den.host.igloo;
              of = config.den.aspects.app;
              set.colorScheme = "igloo-host";
            }
          ];
        };

      # guard-activated neededBy (§B4b joint fixpoint): `guardG` activates wherever `system` is resolved
      # (its guard reads the path set only, A9.1); `needT`'s literal neededBy [ guardG ] then fires — so
      # a guard-arrived carrier drives reverse injection (presence is arrival-path independent). Both
      # resolve at the hosts (where `system` is included), neither at env (system absent there).
      guardMod =
        { config, ... }:
        {
          config.den.aspects = {
            guardG.meta.guard =
              { hasAspect, ... }:
              hasAspect config.den.aspects.system;
            needT.neededBy = [ config.den.aspects.guardG ];
          };
        };

      # fleet-wide quirks: ssh-peers emitted at each host (gathered at the cluster via the link);
      # http-backends emitted by TWO aspects at igloo (same-position producers, order pinned by identity).
      peersMod =
        { config, ... }:
        {
          config.den.aspects.peerIgloo.ssh-peers = [ "igloo-ip" ];
          config.den.aspects.peerWeb.ssh-peers = [ "web1-ip" ];
          config.den.aspects.backendA.http-backends = [ "backend-a" ];
          config.den.aspects.backendB.http-backends = [ "backend-b" ];
          config.den.include = [
            {
              at = config.den.host.igloo;
              aspects = [
                config.den.aspects.peerIgloo
                config.den.aspects.backendA
                config.den.aspects.backendB
              ];
            }
            {
              at = config.den.host.web-1;
              aspects = [ config.den.aspects.peerWeb ];
            }
          ];
        };

      # ── the unrelated policy modules (permuted by `permute`) ──────────────────────────────────────
      # clusterLink — the cluster imports both hosts (a structural `link`; one instantiate per host is the
      # invariant it must NOT violate). provisionDb — the `database` demand, emitted ONCE at the cluster's
      # single scope, subject = host igloo. setColor — a `configure` at the user cells (the terminal slot).
      clusterLinkMod =
        { config, ... }:
        {
          config.den.policies.clusterLink =
            { cluster, ... }:
            [
              (declare.link { target = config.den.host.igloo; })
              (declare.link { target = config.den.host.web-1; })
            ];
        };
      provisionDbMod =
        { config, ... }:
        {
          config.den.policies.provisionDb =
            { cluster, ... }:
            [
              (declare.demand {
                kind = "database";
                subject = config.den.host.igloo;
              })
            ];
        };
      setColorMod =
        { config, ... }:
        {
          config.den.policies.setColor =
            { user, ... }:
            [
              (declare.configure {
                of = config.den.aspects.app;
                set.colorScheme = "prod-policy";
              })
            ];
        };
      unrelatedPolicies =
        if permute then
          [
            setColorMod
            provisionDbMod
            clusterLinkMod
          ]
        else
          [
            clusterLinkMod
            provisionDbMod
            setColorMod
          ];
    in
    [
      accSchema
      accInstances
      accMembership
      accClassing
      accNixpkgs
      accQuirks
      accDemandKinds
      systemMod
      settingsMod
      guardMod
      peersMod
    ]
    ++ unrelatedPolicies;
in
{
  inherit
    schema
    instances
    membership
    memberAtCell
    duplicate
    acceptance
    ;
  base = [
    schema
    instances
    membership
  ];
  bad = [
    schema
    instances
    membership
    memberAtCell
  ];
  dup = [
    schema
    instances
    membership
    duplicate
  ];
}
