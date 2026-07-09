# Foreign-topology tripwire (genericity witness) — the PERMANENT guard that den-hoag core is
# KIND-AGNOSTIC (assembly spec §2.2: kinds are USER-DECLARED schema, not built-in). Every other suite
# uses the built-in env/host/user/home vocabulary; this one declares a schema that shares NO kind name
# with them — `datacenter → rack → blade` — and drives the WHOLE four-concern assembly over it: a
# containment DAG, instances, membership cells, a per-kind contentClass, an aspect whose per-class
# content DESTRUCTURES the custom kind coordinates (`{ datacenter, rack, blade, ... }:`), a quirk channel,
# a policy firing on a custom kind, and an include at a custom entity. It asserts channels + edges +
# class-modules materialize exactly as the standard topology does. A core change that re-grows kind
# coupling (a `host`/`user` literal in a dispatch/moduleArg/scope path) breaks this suite.
{
  denHoag,
  nixpkgs,
  ...
}:
let
  # ── the foreign fleet — datacenter (root) → rack → blade (the leaf CELL) ──────────────────────────────
  schema = {
    config.den.schema = {
      datacenter.parent = null;
      rack.parent = "datacenter";
      blade.parent = "rack";
    };
  };
  instances = {
    config.den = {
      datacenter.dc1 = { };
      rack.r1 = { };
      blade.b1 = { };
    };
  };
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            datacenter = config.den.datacenter.dc1;
            rack = config.den.rack.r1;
          };
        }
        {
          coords = {
            rack = config.den.rack.r1;
            blade = config.den.blade.b1;
          };
        }
      ];
    };
  # blades produce the `nixos` class (datacenter/rack are class-neutral scope roots).
  classing.config.den.contentClass.blade = "nixos";
  # a quirk channel radiated to the blade cell.
  quirk.config.den.quirks.rack-peers = { };

  # the app aspect: nixos content DESTRUCTURING the custom kind coordinates (the kind-generic moduleArgs
  # witness — with a `host`/`user`-hardcoded allowlist, `{ datacenter, rack, blade, ... }` would not bind
  # and the crossing below would abort), plus a plain-list channel contribution.
  appMod =
    { config, ... }:
    {
      config.den.aspects.app = {
        # the blade cell's coordinates are its membership dims `{ rack, blade }` (a cell carries its own
        # coords, not the grandparent — the standard cell model); both are CUSTOM kinds, so a body binding
        # them + crossing to a real system witnesses that core resolves foreign-kind coordinates end-to-end.
        nixos =
          {
            rack,
            blade,
            ...
          }:
          {
            networking.hostName = "${rack.name}-${blade.name}";
            # the platform gate a NixOS eval needs to RESOLVE `networking.hostName` (never forces pkgs).
            nixpkgs.hostPlatform = "x86_64-linux";
          };
        rack-peers = [ "peer-a" ];
      };
      config.den.include = [
        {
          at = config.den.blade.b1;
          aspects = [ config.den.aspects.app ];
        }
      ];
    };

  # a policy firing on a CUSTOM kind (`rack`) — den-hoag's dispatch canTake is kind-generic (functionArgs),
  # so `{ rack, ... }:` gates on the rack coordinate exactly like `{ host, ... }:` would. It includes the
  # `rackTag` marker aspect wherever a rack coordinate is in scope (the rack root + the blade cell).
  policyMod =
    { config, ... }:
    {
      config.den.aspects.rackTag = { };
      config.den.policies.tag-rack =
        { rack, ... }:
        [ (denHoag.declare.edge config.den.aspects.rackTag) ];
    };

  base = [
    schema
    instances
    membership
    classing
    quirk
    appMod
    policyMod
  ];

  # nixpkgs-free structural arm — channels / edges / class-modules / resolved-aspects.
  den = (denHoag.mkDen base).den;
  bladeCell = "blade:b1@rack:r1";
  eval = den.structural.eval;
  raAt = id: map (n: n.key) (eval.get id "resolved-aspects");
  roots = builtins.attrNames den.scopeRoots;
  edges = builtins.concatMap (r: den.graph.edges r) roots;

  # nixpkgs-crossing arm — force the app aspect's nixos body APPLICATION so the custom-kind binding is
  # actually exercised (the collect terminal only COLLECTS the module; gen-bind supplies the coordinate
  # moduleArgs at the real crossing). `nixosConfigurations` is re-keyed to the member entity NAME — the
  # blade cell's __entry is the blade `b1`, so the crossed system is `nixosConfigurations.b1`.
  crossed = denHoag.mkDen (base ++ [ { config.den.nixpkgs = nixpkgs; } ]);
  bladeSystem = crossed.nixosConfigurations.b1;
in
{
  flake.tests.foreign-topology = {
    # ── the scope tree is the foreign topology (datacenter + rack are roots, blade is the leaf cell) ──
    test-foreign-scope-roots = {
      expr = builtins.sort (a: b: a < b) roots;
      expected = [
        "datacenter:dc1"
        "rack:r1"
      ];
    };

    # ── an include at a CUSTOM entity resolves the aspect at the blade cell (kind-generic include) ────
    test-include-at-custom-entity = {
      expr = builtins.elem "app" (raAt bladeCell);
      expected = true;
    };

    # ── a policy firing on a CUSTOM kind (`rack`) radiates its aspect to the rack-bearing scopes ──────
    test-policy-on-custom-kind = {
      expr = {
        atRackRoot = builtins.elem "rackTag" (raAt "rack:r1");
        atBladeCell = builtins.elem "rackTag" (raAt bladeCell);
      };
      expected = {
        atRackRoot = true;
        atBladeCell = true;
      };
    };

    # ── CLASS-MODULES materialize — the app aspect's `nixos` content folds into the blade cell's bucket ─
    test-class-modules-materialize = {
      expr = builtins.length ((eval.get bladeCell "class-modules").nixos or [ ]) >= 1;
      expected = true;
    };

    # ── CHANNELS materialize — the `rack-peers` quirk gathers at the blade cell ────────────────────────
    test-channels-materialize = {
      expr = builtins.attrNames (eval.get bladeCell "local-collection-data");
      expected = [ "rack-peers" ];
    };

    # ── EDGES materialize — the fold produces the blade cell's producing-class (nixos) edge ────────────
    test-edges-materialize = {
      expr = builtins.length edges >= 1;
      expected = true;
    };

    # ── CUSTOM-KIND COORDINATE BINDING — the nixos body `{ rack, blade, ... }:` evaluates through the real
    #    NixOS crossing, so `networking.hostName` reads the two CUSTOM kind coordinates end-to-end (the
    #    coords are supplied from the cell's enriched-context; the moduleArg allowlist — now kind-generic —
    #    admits the body regardless of built-in kind names). The sharpest witness that no assembly stage is
    #    host/user-coupled: a foreign-kind body materializes a real system reading its own coordinates. ───
    test-custom-kind-binding-crosses = {
      expr = bladeSystem.config.networking.hostName;
      expected = "r1-b1";
    };
  };
}
