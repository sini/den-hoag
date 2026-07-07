# compat-provides-desugar (C4) — the legacy `provides` surface desugars to §B4a `neededBy` (the
# self-contained tagged legacy/provides.nix), and its radiated positions REPRODUCE v1's registration-
# scoped provides dispatch (frozen pin denful/den@11866c16, aspect/provide.nix). Two layers:
#
#   (A) DESUGAR SHAPE (denCompat.legacy.provides.desugar) — pure v1-aspects → v1-aspects. Pins the two
#       parity-watch adjudications directly, plus self-provide meta + provides-stripping + seed stubs.
#   (B) RADIATED POSITIONS — the desugar OUTPUT fed to denHoag.mkDen with PRECISE `den.include`
#       placement (the b4-fixpoint pattern: env prod ⊇ {axon, blade}, alice@axon, bob@axon, carol@blade).
#       This is how §B4a scoping is tested faithfully: den-hoag cells are (host, user) and its native
#       `den.include` places a carrier at ONE scope, whereas the COMPAT `schema.<kind>.includes` fires
#       fleet-wide (a den-hoag compat-dispatch limitation, not the desugar's) — so precise placement
#       here isolates the desugar's own radiation. The SAME selectors the desugar emits are the ones
#       den-hoag's own b4-fixpoint proves registration-scoped; this re-pins them against v1's positions.
#   (C) WIRING — a `provides` fixture through the FULL denCompat.mkDen path radiates end-to-end, and the
#       Law-C5 SENTINEL fires when a `provides` key reaches compile un-desugared (severance half).
#
# ── THE ADJUDICATIONS (verdicts; v1 citations in legacy/provides.nix header) ────────────────────────
#   1. to-hosts ≡ to-users. v1 `mkCrossPolicy` gives both the identical `{ host, user, ... }` policy fn,
#      which `resolveArgsSatisfied` fires ONLY at deliverable (user) cells — so both reach the SAME
#      positions. The desugar radiates BOTH to `sel.kind user` (den-hoag's single deliverable kind). A
#      to-hosts → `sel.kind host` desugar is REJECTED on that evidence (it would deliver at host scopes).
#   2. Containment-based B4a ≡ v1 registration-scope. Host-included to-users reaches that host's users
#      ONLY (cross-host negative below); env-included reaches all users under the env; a named provide
#      reaches only the name-matching cell. The residual (a contentless stub key at the seed scope,
#      absent in v1) is compensated to be content-null — legacy/provides.nix ADJUDICATION 2.
{ denCompat, denHoag, ... }:
let
  inherit (denCompat.legacy.provides) desugar;
  sel = denHoag.sel;

  # ── (A) desugar shape fixtures ──────────────────────────────────────────────────────────────────
  shaped = desugar {
    A = {
      provides = {
        to-users = {
          "home-manager".u = 1;
        };
        to-hosts = {
          "home-manager".h = 2;
        };
        bob = {
          "home-manager".b = 3;
        };
        A = {
          "home-manager".self = 4;
        }; # self-provide (key == aspect name)
      };
      "home-manager".base = 0;
    };
    plain = {
      nixos.x = 9;
    }; # no provides — must pass through byte-identical
  };
  selOf = name: shaped.${name}.neededBy;

  # ── (B) radiated positions: desugar output → denHoag.mkDen with precise den.include ─────────────
  bFleet = desugar {
    hostProv.provides.to-users = {
      "home-manager".hp = 1;
    }; # placed at host:axon
    hostHosts.provides.to-hosts = {
      "home-manager".hh = 1;
    }; # placed at host:axon (adjudication 1)
    envProv.provides.to-users = {
      "home-manager".ep = 1;
    }; # placed at env:prod
    namedProv.provides.bob = {
      "home-manager".np = 1;
    }; # placed at env:prod (nameMatches bob)
    selfCarrier = {
      provides.selfCarrier = {
        "home-manager".sc = 1;
      }; # self-provide, placed at host:axon
      "home-manager".ownBase = 0;
    };
  };

  base = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
    };
    config.den = {
      env.prod = { };
      host.axon = { };
      host.blade = { };
      user.alice = { };
      user.bob = { };
      user.carol = { };
    };
  };
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
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.bob;
          };
        }
        {
          coords = {
            host = config.den.host.blade;
            user = config.den.user.carol;
          };
        }
      ];
    };
  placement =
    { config, ... }:
    {
      config.den.aspects = bFleet;
      config.den.include = [
        # host-scoped (to-users AND to-hosts) → seeded at host:axon
        {
          at = config.den.host.axon;
          aspects = [
            config.den.aspects.hostProv
            config.den.aspects.hostHosts
          ];
        }
        # env-scoped + named → seeded at env:prod
        {
          at = config.den.env.prod;
          aspects = [
            config.den.aspects.envProv
            config.den.aspects.namedProv
          ];
        }
        # self-provide carrier → seeded at host:axon
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.selfCarrier ];
        }
      ];
    };
  denB =
    (denHoag.mkDen [
      base
      membership
      placement
    ]).den;
  nodesAt = id: denB.structural.eval.get id "resolved-aspects";
  keysAt = id: map (n: n.key) (nodesAt id);
  hasAt = id: k: builtins.elem k (keysAt id);
  metaOf =
    id: k:
    let
      hit = builtins.filter (n: n.key == k) (nodesAt id);
    in
    if hit == [ ] then null else (builtins.head hit).content.meta or null;

  alice = "user:alice@host:axon";
  bob = "user:bob@host:axon";
  carol = "user:carol@host:blade";
  axon = "host:axon";

  # ── (C) full compat wiring: provides through denCompat.mkDen (flat host fleet) ───────────────────
  wired =
    (denCompat.mkDen [
      {
        config.den.hosts.x86_64-linux.axon = { };
        config.den.homes.x86_64-linux."alice@axon" = { };
        config.den.schema.host.includes = [ "carrier" ];
        config.den.aspects.carrier.provides.to-users = {
          "home-manager".w = 1;
        };
      }
    ]).den;
  wiredKeys = id: map (n: n.key) (wired.structural.eval.get id "resolved-aspects");

  # sentinel: a `provides` key reaching compile un-desugared (the severed path) is a named error. Force
  # the compiled aspect (the sentinel is a lazy `seq` inside translateAspect) so the throw is observed.
  sentinelTripped =
    (builtins.tryEval (
      builtins.seq (denCompat.compile { aspects.foo.provides.to-users = { }; }).aspects.foo null
    )).success;
in
{
  flake.tests.compat-provides-desugar = {
    # ── (A) DESUGAR SHAPE ──────────────────────────────────────────────────────────────────────────
    # to-users → sel.kind user.
    test-to-users-selector = {
      expr = (selOf "A/to-users").__sel == "kind" && (selOf "A/to-users").kind == "user";
      expected = true;
    };
    # ADJUDICATION 1: to-hosts desugars to the SAME selector as to-users (sel.kind user), NOT sel.kind host.
    test-to-hosts-equals-to-users = {
      expr = (selOf "A/to-hosts") == (selOf "A/to-users");
      expected = true;
    };
    test-to-hosts-not-host-kind = {
      expr = (selOf "A/to-hosts").kind == "user";
      expected = true;
    };
    # named → sel.and [ sel.kind user, nameMatches ] (a two-clause conjunction, kind first).
    test-named-is-conjunction = {
      expr = (selOf "A/bob").__sel == "and";
      expected = true;
    };
    test-named-kind-clause = {
      expr =
        let
          s = (selOf "A/bob").selectors;
        in
        (builtins.length s == 2) && (builtins.head s).__sel == "kind" && (builtins.head s).kind == "user";
      expected = true;
    };
    test-named-when-clause = {
      expr = (builtins.elemAt (selOf "A/bob").selectors 1).__sel == "when";
      expected = true;
    };
    # self-provide: merged into the carrier — provider chain grows by the name, selfProvide flag set.
    test-self-provide-meta-provider = {
      expr = shaped.A.meta.provider;
      expected = [ "A" ];
    };
    test-self-provide-flag = {
      expr = shaped.A.meta.selfProvide;
      expected = true;
    };
    # the `provides` key is STRIPPED from the declaring aspect (den-hoag never sees it).
    test-provides-stripped = {
      expr = shaped.A ? provides;
      expected = false;
    };
    # the declaring aspect's own content survives the self-merge (base + self both present).
    test-carrier-keeps-own-content = {
      expr = (shaped.A."home-manager".base or null) == 0 && (shaped.A."home-manager".self or null) == 4;
      expected = true;
    };
    # cross-entity carriers are seeded (contentless stubs) on the declaring aspect's includes.
    test-seed-stubs-on-includes = {
      expr = builtins.sort (a: b: a < b) (map (i: i.name) shaped.A.includes);
      expected = [
        "A/bob"
        "A/to-hosts"
        "A/to-users"
      ];
    };
    # an aspect WITHOUT provides passes through byte-identical.
    test-plain-untouched = {
      expr = shaped.plain == { nixos.x = 9; };
      expected = true;
    };

    # ── (B) RADIATED POSITIONS (adjudication 2, precise placement) ──────────────────────────────────
    # host-included to-users reaches THAT host's users …
    test-host-reaches-alice = {
      expr = hasAt alice "hostProv/to-users";
      expected = true;
    };
    test-host-reaches-bob = {
      expr = hasAt bob "hostProv/to-users";
      expected = true;
    };
    # … and NOT a user under another host (cross-host NEGATIVE).
    test-host-not-carol = {
      expr = hasAt carol "hostProv/to-users";
      expected = false;
    };
    # ADJUDICATION 1 end-to-end: to-hosts radiates to the SAME (user) positions as to-users.
    test-tohosts-reaches-alice = {
      expr = hasAt alice "hostHosts/to-hosts";
      expected = true;
    };
    test-tohosts-not-carol = {
      expr = hasAt carol "hostHosts/to-hosts";
      expected = false;
    };
    # env-included reaches EVERY user under the env (alice, bob under axon AND carol under blade).
    test-env-reaches-alice = {
      expr = hasAt alice "envProv/to-users";
      expected = true;
    };
    test-env-reaches-carol = {
      expr = hasAt carol "envProv/to-users";
      expected = true;
    };
    # named provide reaches ONLY the name-matching cell (bob), not alice or carol.
    test-named-reaches-bob = {
      expr = hasAt bob "namedProv/bob";
      expected = true;
    };
    test-named-not-alice = {
      expr = hasAt alice "namedProv/bob";
      expected = false;
    };
    test-named-not-carol = {
      expr = hasAt carol "namedProv/bob";
      expected = false;
    };
    # self-provide is LOCAL to the carrier's own resolution (present at its seed scope, host:axon) …
    test-self-present-at-seed = {
      expr = hasAt axon "selfCarrier";
      expected = true;
    };
    # … carrying the provider chain + selfProvide flag through den-hoag resolution.
    test-self-meta-through-resolution = {
      expr =
        let
          m = metaOf axon "selfCarrier";
        in
        m != null && (m.selfProvide or false) && m.provider == [ "selfCarrier" ];
      expected = true;
    };
    # … and it does NOT radiate (self-provide has no neededBy — absent at a bare user cell it was not seeded at).
    test-self-not-radiated = {
      expr = hasAt carol "selfCarrier";
      expected = false;
    };
    # residual (adjudication 2): the contentless seed stub key sits at the seed scope, content-null.
    test-seed-stub-key-at-scope = {
      expr = hasAt axon "hostProv/to-users";
      expected = true;
    };

    # ── (C) FULL COMPAT WIRING + SENTINEL ───────────────────────────────────────────────────────────
    # a provides fixture through the FULL denCompat.mkDen path radiates to a user cell (end-to-end wiring).
    test-compat-mkDen-radiates = {
      expr = builtins.elem "carrier/to-users" (wiredKeys "user:alice@host:axon");
      expected = true;
    };
    # Law C5: a `provides` key reaching compile UN-desugared (severed legacy module) is a named error.
    test-sentinel-fires-on-undesugared-provides = {
      expr = sentinelTripped;
      expected = false;
    };
  };
}
