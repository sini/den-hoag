# THE PROJECTED hasAspect ENTITY SURFACE (v1 PR #602 semantics; the den-hoag dissolution). The rung's
# frontier: nix-config axon-01's drvPath died at `attribute 'hasAspect' missing @
# modules/den/aspects/core/network/networking.nix:341:35` — `host.hasAspect den.aspects.core.network.manager`
# at delivery depth. Census (b0b20769): 13 reads, all `host.hasAspect`, all delivery-depth nixos bodies.
#
# THE LAW. v1 stamps a SHARED projected `hasAspect` onto every entity-kind ctx binding at the consuming
# scope (pin schema.nix:88-96), membership = `refKey ref ∈ pathSet`; under A-IDENT (Task 3) `refKey` is a
# SINGLE native-`.key` lookup + a NAMED throw for a keyless ref (never a silent false), surface
# class-invariant (`{ __functor; forClass; forAnyClass; }`). THE DISSOLUTION: den-hoag has no re-key
# machinery — a node's resolved-aspects (attribute 7) IS the projected set, so the surface is a pure lookup
# over the node's OWN resolved-aspects entry keys, keyed by the SAME gen-aspects.key identity (ref and node
# agree by construction — both carry the native `.key`). A ref is a `{ key = <path> }` value; `refKey` is a
# single `.key` lookup (no reconstruction).
#
# The witnesses split UNIT (refKey/mkEnrich directly — deterministic seam logic: W2/W3/W4/W6/W-throw/filter)
# and END-TO-END (the bridge's forcing terminal — the corpus path through bindingsAt: W1/W3-e2e/W5).
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  inherit (denCompat) refKey mkEnrich;

  # ── UNIT: refKey identity + the mkEnrich stamp ────────────────────────────────────────────────────
  # Native A-IDENT: a `den.aspects.core.network.manager` read (under the NAV binding OR off the compiled
  # registry) carries its OWN `.key`, so `refKey` is a single `.key` lookup — no reconstruction. The two
  # shapes below are the nav-view value and the registry value; both carry the SAME native `.key`.
  refNav = {
    key = "core/network/manager"; # native `.key` (nav binding)
  };
  refReg = {
    key = "core/network/manager"; # native `.key` (registry value)
  };

  # A fixture node's resolved-aspects (attribute-7 shape: `[ { key; content } ]`), keyed by the SAME
  # gen-aspects.key the resolved nodes carry — here the manager aspect is delivered.
  seenManager = [
    {
      key = "core/network/manager";
      content = { };
    }
  ];
  entHostUser = {
    host = true;
    user = true;
  };
  enrManager = mkEnrich entHostUser {
    id = "host:h";
    resolvedAspects = seenManager;
    bindings = {
      host = {
        id_hash = "h";
        name = "h";
      };
    };
  };

  # ── UNIT: entity-kind FILTER (host/user stamped; secretsConfig / channel NOT) ─────────────────────
  enrFilter = mkEnrich entHostUser {
    id = "host:h";
    resolvedAspects = [
      {
        key = "a";
        content = { };
      }
    ];
    bindings = {
      host = {
        id_hash = "h";
      };
      user = {
        id_hash = "u";
      };
      secretsConfig = {
        masterIdentities = [ ];
      }; # NOT a schema kind ⇒ never stamped
      feat = [
        1
        2
      ]; # a channel binding (list) ⇒ never stamped
    };
  };

  # ── UNIT: LAZINESS (A17) — a THROWING resolved-aspects thunk. Forcing the enriched spine (deepSeq) must
  #    NOT trip it; only CALLING a hasAspect closure may. Non-tautological (a real throwing thunk). ──
  lazyProbe = mkEnrich entHostUser {
    id = "host:h";
    resolvedAspects = throw "compat-has-aspect: resolved-aspects FORCED at stamp time (A17 violation)";
    bindings = {
      host = {
        id_hash = "h";
        name = "h";
      };
    };
  };

  # ── UNIT: W6 — a USER-cell node. `user.hasAspect` reads the CELL node's resolved-aspects (the per-node
  #    dissolution: the hook is handed THIS node's set, so the user binding answers for the cell). ──
  enrCell = mkEnrich entHostUser {
    id = "user:alice@host:h1";
    resolvedAspects = [
      {
        key = "userland";
        content = { };
      }
    ];
    bindings = {
      host = {
        id_hash = "h";
      };
      user = {
        id_hash = "u";
      };
    };
  };

  # ── UNIT: W2 — the by-construction agreement against a REAL resolved node. A self-named aspect
  #    `den.aspects.marker` auto-includes at host `marker` (R5); refKey of the navigated ref equals a key
  #    the host's resolved-aspects actually carries. ──
  w2Fleet = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.marker = { };
      den.aspects.marker = { };
    }
  ];
  w2Eval = w2Fleet.den.structural.eval;
  w2MarkerKeys = map (n: n.key) (w2Eval.get "host:marker" "resolved-aspects");

  # ── END-TO-END: the corpus path through bindingsAt (the compat-settings-binding forcing-terminal
  #    pattern). A per-host `instantiate` evaluator RUNS the wrapped class-modules through a real
  #    `evalModules` fixpoint, so the aspect body's `host.hasAspect` executes at delivery depth, with the
  #    `host` binding = `bindingsAt` (enriched with the projected surface). ──
  forceEval =
    args:
    (lib.evalModules {
      modules = args.modules ++ [ { freeformType = lib.types.lazyAttrsOf lib.types.raw; } ];
      specialArgs = args.specialArgs or { };
    }).config;
  channels.probe-chan.nixosSystem = forceEval;
  corpusKindModule =
    { config, ... }:
    {
      options.channel = lib.mkOption {
        type = lib.types.enum (builtins.attrNames channels);
        default = "probe-chan";
      };
      config.instantiate = lib.mkDefault channels.${config.channel}.nixosSystem;
    };
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    mkCrossNixos = _: throw "compat-has-aspect: mkCrossNixos unused (no den.nixpkgs)";
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  ev = lib.evalModules {
    modules = [
      flakeStub
      bridge
      {
        den.schema.host.isEntity = true;
        den.schema.host.imports = [ corpusKindModule ];
        den.hosts.x86_64-linux.withaspect = { };
        den.hosts.x86_64-linux.plain = { };
        # `withaspect`'s self-named aspect (auto-included at host withaspect, R5). Its nixos body reads
        # `host.hasAspect` at delivery depth — the corpus networking.nix:341 shape. Its includes carry a BARE
        # NAME REFERENCE (`{ name = "kid" }`) — the typed tree keys it positionally, and `stampIdentity` carries
        # its authored name `kid` (chain cleared), the transitive-delivery witness (W5). The `host.hasAspect`
        # refs carry native `.key` (a `{ key = <path> }` value — refKey is a single `.key` lookup).
        den.aspects.withaspect.includes = [
          { name = "kid"; }
        ];
        den.aspects.withaspect.nixos =
          { host, ... }:
          {
            hasSelf = host.hasAspect { key = "withaspect"; }; # delivered (self) → true
            hasChild = host.hasAspect { key = "kid"; }; # via nested include → true (W5)
            hasAbsent = host.hasAspect { key = "nope"; }; # not delivered → false
            # the corpus mkForce-false shape typechecks as a bool
            managerForced = lib.mkForce (host.hasAspect { key = "nope"; });
          };
        # `plain` has its own self-named aspect but NOT `withaspect` — the negative host (W3 end-to-end).
        den.aspects.plain.nixos =
          { host, ... }:
          {
            plainHasWithaspect = host.hasAspect { key = "withaspect"; }; # absent here → false
          };
      }
    ];
  };
  configs = ev.config.flake.nixosConfigurations;
in
{
  flake.tests.compat-has-aspect = {
    # ── W2: the load-bearing identity pin — refKey agreement + the by-construction node match ──────────
    test-w2-refkey-identity = {
      expr = {
        refKeyNav = refKey refNav;
        refKeyReg = refKey refReg;
        # refKey reads native `.key` directly — the ref key IS its `.key` (no reconstruction).
        navEqKey = refKey refNav == refNav.key;
        regEqKey = refKey refReg == refReg.key;
      };
      expected = {
        refKeyNav = "core/network/manager";
        refKeyReg = "core/network/manager";
        navEqKey = true;
        regEqKey = true;
      };
    };
    # refKey of the navigated ref is a key the REAL resolved-aspects of a self-named host carries.
    test-w2-refkey-matches-resolved-node = {
      expr = {
        refK = refKey {
          key = "marker"; # native `.key`
        };
        present = builtins.elem "marker" w2MarkerKeys;
      };
      expected = {
        refK = "marker";
        present = true;
      };
    };

    # ── W1-shape (unit): the stamp answers membership true at the binding (all three surface arms) ──────
    test-w1-stamp-true-at-binding = {
      expr = {
        functor = enrManager.host.hasAspect refNav;
        forClass = enrManager.host.hasAspect.forClass "nixos" refNav;
        forAnyClass = enrManager.host.hasAspect.forAnyClass refNav;
      };
      expected = {
        functor = true;
        forClass = true;
        forAnyClass = true;
      };
    };

    # ── W3 (negative, unit): a non-delivered ref is false; the corpus mkForce-false shape typechecks ────
    test-w3-absent-false = {
      expr = {
        absent = enrManager.host.hasAspect {
          key = "absent";
        };
        mkForceShape =
          (lib.mkForce (
            enrManager.host.hasAspect {
              key = "absent";
            }
          )).content;
      };
      expected = {
        absent = false;
        mkForceShape = false;
      };
    };

    # ── W-throw: a ref with no native `.key` ⇒ a NAMED throw (never a silent false). Task 3: the guard is
    #    now "carries `.key`"; a shapeless ref (`{ foo = 1; }`) still self-announces LOUD. ────────────────
    test-w-throw-unresolvable-ref = {
      expr =
        (builtins.tryEval (refKey {
          foo = 1;
        })).success;
      expected = false;
    };

    # ── W4 (laziness, A17): deepSeq the enriched spine WITHOUT calling hasAspect ⇒ resolved-aspects NOT
    #    forced (the throwing thunk survives); CALLING the closure DOES force it (the throw surfaces). ──
    test-w4-laziness = {
      expr = {
        spineSafe = (builtins.tryEval (builtins.deepSeq lazyProbe true)).success;
        callForces =
          (builtins.tryEval (
            lazyProbe.host.hasAspect {
              key = "x";
            }
          )).success;
      };
      expected = {
        spineSafe = true; # forcing the binding spine never forces resolved-aspects
        callForces = false; # calling the hasAspect closure DOES (the throw fires)
      };
    };

    # ── entity-kind FILTER: host/user stamped; secretsConfig (non-kind) / a channel (list) NOT ──────────
    test-entity-kind-filter = {
      expr = {
        hostStamped = enrFilter.host ? hasAspect;
        userStamped = enrFilter.user ? hasAspect;
        secretsNotStamped = !(enrFilter.secretsConfig ? hasAspect);
        channelUntouched =
          enrFilter.feat == [
            1
            2
          ];
      };
      expected = {
        hostStamped = true;
        userStamped = true;
        secretsNotStamped = true;
        channelUntouched = true;
      };
    };

    # ── W6 (breadth): user.hasAspect on a user-cell binding resolves against the CELL node's set; the
    #    host binding at the SAME node shares that set (one projected surface per node). ────────────────
    test-w6-user-cell = {
      expr = {
        userHas = enrCell.user.hasAspect {
          key = "userland";
        };
        userLacks = enrCell.user.hasAspect {
          key = "hostonly";
        };
        hostSharesSet = enrCell.host.hasAspect {
          key = "userland";
        };
      };
      expected = {
        userHas = true;
        userLacks = false;
        hostSharesSet = true;
      };
    };

    # ── W1 / W3 / W5 END-TO-END: the corpus path, host.hasAspect executed at delivery depth ────────────
    test-w1-e2e-delivered-true = {
      expr = {
        hasSelf = configs.withaspect.hasSelf; # W1 — self-delivered aspect
        hasChild = configs.withaspect.hasChild; # W5 — transitive via nested include (stampProvider lift)
      };
      expected = {
        hasSelf = true;
        hasChild = true;
      };
    };
    test-w3-e2e-absent-false = {
      expr = {
        withaspectAbsent = configs.withaspect.hasAbsent; # not delivered to this host
        withaspectMkForce = configs.withaspect.managerForced; # mkForce-false shape resolved
        plainLacksWithaspect = configs.plain.plainHasWithaspect; # a different host lacks it
      };
      expected = {
        withaspectAbsent = false;
        withaspectMkForce = false;
        plainLacksWithaspect = false;
      };
    };
  };
}
