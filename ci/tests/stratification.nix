# A9 / A10 — the stratification law and the narrow accessor (§2.8).
#
# A9 (stratification, load-bearing):
#   - the presence fixpoint (attribute 7) NEVER reads resolved settings — guards see only
#     `{ pathSet, hasAspect }`, so a guard probing for a `settings` arg receives none (activates);
#   - presence is independent of any settings VALUE change (arrival-path independent LFP);
#   - settings resolution runs AFTER presence and MAY read it — a followed `ref` resolves against
#     the present target (the batch = present aspects);
#   - policy dispatch context exposes no `hasAspect` — a `configure` policy destructuring it never
#     fires (presence routes to the guard system, not policy dispatch — §2.3 placement).
# A10 (narrow accessor): `aspects.<name>` is EXACTLY `{ present; settings; }`; reading `.settings`
#   of an absent aspect throws named; content→content is unexpressible (no path to another aspect's
#   content — the accessor exposes only these two projections).
{ denHoag, ... }:
let
  sel = denHoag.sel;
  ref = denHoag.ref;

  fleetBase = [
    {
      config.den.schema = {
        env.parent = null;
        host.parent = "env";
        user.parent = "host";
      };
    }
    {
      config.den = {
        env.prod = { };
        host.axon = { };
        user.alice = { };
      };
    }
    (
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
              host = config.den.host.axon;
              user = config.den.user.alice;
            };
          }
        ];
      }
    )
  ];
  cellId = "user:alice@host:axon";
  keysAt =
    den: id:
    builtins.sort (a: b: a < b) (map (n: n.key) (den.structural.eval.get id "resolved-aspects"));

  # ── narrow accessor shape + absent aspect (A10) ─────────────────────────────────────────────────
  accMod =
    { config, ... }:
    {
      config.den.aspects = {
        app = {
          neededBy = sel.kind config.den.schema.user;
          settings.k = {
            default = "v";
          };
        };
        ghost = { }; # declared, never included / needed ⇒ absent at the cell
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
      ];
    };
  denAcc = (denHoag.mkDen (fleetBase ++ [ accMod ])).den;
  acc = denAcc.aspectsAt cellId;

  # ── guard sees no settings (A9.1) — activates because no `settings` arg is passed ───────────────
  guardMod =
    { config, ... }:
    {
      config.den.aspects.probe.meta.guard = { pathSet, ... }@args: !(args ? settings);
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ ];
        }
      ];
    };
  denGuard = (denHoag.mkDen (fleetBase ++ [ guardMod ])).den;
  guardPresent =
    id: builtins.elem "probe" (map (n: n.key) (denGuard.structural.eval.get id "resolved-aspects"));

  # ── presence independent of a settings VALUE change ─────────────────────────────────────────────
  presenceMod =
    lvl:
    { config, ... }:
    {
      config.den.aspects = {
        base = { };
        gated.meta.guard = { hasAspect, ... }: hasAspect config.den.aspects.base;
        app = {
          neededBy = sel.kind config.den.schema.user;
          settings.level = {
            default = "info";
          };
        };
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.base ];
        }
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
      ];
      config.den.settings.layers = [
        {
          at = {
            env = config.den.env.prod;
          };
          of = config.den.aspects.app;
          set = {
            level = lvl;
          };
        }
      ];
    };
  denLvlA = (denHoag.mkDen (fleetBase ++ [ (presenceMod "aaa") ])).den;
  denLvlB = (denHoag.mkDen (fleetBase ++ [ (presenceMod "bbb") ])).den;

  # ── followed ref reads the present target (settings MAY read presence) ──────────────────────────
  refMod =
    { config, ... }:
    {
      config.den.aspects = {
        b = {
          neededBy = sel.kind config.den.schema.user;
          settings.y = {
            default = "B-Y";
          };
        };
        a = {
          neededBy = sel.kind config.den.schema.user;
          settings.x = {
            default = ref config.den.aspects.b [ "y" ];
          };
        };
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [
            config.den.aspects.a
            config.den.aspects.b
          ];
        }
      ];
    };
  denRef = (denHoag.mkDen (fleetBase ++ [ refMod ])).den;
  rsRef = denRef.structural.eval.get cellId "resolved-settings";

  # ── `configure` policy destructuring `hasAspect` never fires (§2.3 dispatch placement) ──────────
  noFireMod =
    { config, ... }:
    {
      config.den.aspects.app = {
        neededBy = sel.kind config.den.schema.user;
        settings.level = {
          default = "info";
        };
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
      ];
      # `hasAspect` is never a policy-dispatch ctx key (it routes to the guard system) ⇒ never fires.
      config.den.policies.wouldConfigure = {
        emits = [ "configure" ];
        fn =
          { hasAspect, ... }:
          [
            (denHoag.declare.configure {
              of = config.den.aspects.app;
              set = {
                level = "pwned";
              };
            })
          ];
      };
    };
  denNoFire = (denHoag.mkDen (fleetBase ++ [ noFireMod ])).den;
  rsNoFire = denNoFire.structural.eval.get cellId "resolved-settings";

  # ── the policy-dispatch gate is a PRESENCE gate over ctx, and the reserved `__` shape is not one of
  #    its inputs ─────────────────────────────────────────────────────────────────────────────────────
  # RETIRED HERE: a `configure` policy destructuring `__coords`, which asserted that the cell's
  # coordinate cache never reaches a policy-dispatch context. The coordinate-payload cutover deleted
  # `__coords` and `__containment` from the cell mint outright — a node's position is a query over the
  # `contains` pool, not a payload it carries — so the key that check guarded against can no longer
  # exist, and the assertion became one no fleet could violate.
  #
  # NOTHING REPLACES IT AS A RESERVED-KEY CHECK, because the law it claimed — reserved keys are graph
  # machinery, stripped from every policy-dispatch context — is false, and was already false when it was
  # written. `__entry` is reserved-shaped, is in the dispatch context at every node, and a policy
  # destructuring it FIRES; that is what the second arm below pins. Re-arming on a reserved-shaped but
  # unknown key would only restate the first arm under a name claiming a reserved-key law, since an
  # unknown `__key` and an unknown plain key are admitted alike.
  #
  # What survives is the gate itself. `gateOf v = v.gate or (builtins.functionArgs v.fn)`
  # (concern-policies.nix) is discharged by gen-dispatch's `fromFunctionMatch`, which admits a rule iff
  # every REQUIRED formal is a key of ctx. The two arms are one controlled experiment with the reserved
  # shape held constant, so presence is the only variable: absent ⇒ never fires, present ⇒ fires. The
  # second arm is the first's positive control — without it a dispatch that fired nothing at all would
  # read as a pass, which is the failure mode that made the retired check worth replacing rather than
  # deleting.
  pwn = config: [
    (denHoag.declare.configure {
      of = config.den.aspects.app;
      set.level = "pwned";
    })
  ];
  gateMod =
    policyFn:
    { config, ... }:
    {
      config.den.aspects.app = {
        neededBy = sel.kind config.den.schema.user;
        settings.level.default = "info";
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
      ];
      config.den.policies.wouldConfigure = {
        emits = [ "configure" ];
        fn = policyFn config;
      };
    };
  rsOf =
    mod: ((denHoag.mkDen (fleetBase ++ [ mod ])).den).structural.eval.get cellId "resolved-settings";
  # `__notAKey` is reserved-SHAPED and unknown to both node mints (`build-roots.nix` writes
  # `{ <kind>; __entry; }`, `fleet.nix` writes `{ <parentDim>; <leafDim>; __entry; }`) ⇒ never a ctx key.
  rsGateAbsent = rsOf (gateMod (config: { __notAKey, ... }: pwn config));
  # `__entry` is reserved-SHAPED and IS a ctx key at every node — the same two mints write it.
  rsGatePresent = rsOf (gateMod (config: { __entry, ... }: pwn config));
in
{
  flake.tests.stratification = {
    # ── A10 narrow accessor shape ──
    test-accessor-exactly-two-keys = {
      expr = builtins.attrNames acc.app;
      expected = [
        "present"
        "settings"
      ];
    };
    test-accessor-present-true = {
      expr = acc.app.present;
      expected = true;
    };
    test-accessor-settings-readable = {
      expr = acc.app.settings.k;
      expected = "v";
    };
    # ── A10 absent aspect ──
    test-absent-present-false = {
      expr = acc.ghost.present;
      expected = false;
    };
    test-absent-settings-throws = {
      expr = (builtins.tryEval (builtins.deepSeq acc.ghost.settings true)).success;
      expected = false;
    };

    # ── A9.1 guard sees no settings ──
    test-guard-sees-no-settings-activates = {
      expr = guardPresent "host:axon";
      expected = true;
    };

    # ── A9 presence independent of settings value ──
    test-presence-independent-of-settings-cell = {
      expr = keysAt denLvlA cellId == keysAt denLvlB cellId;
      expected = true;
    };
    test-presence-independent-of-settings-host = {
      expr = keysAt denLvlA "host:axon" == keysAt denLvlB "host:axon";
      expected = true;
    };
    # sanity: the guarded aspect actually resolved (presence is non-trivial here).
    test-presence-nontrivial = {
      expr = builtins.elem "gated" (keysAt denLvlA "host:axon");
      expected = true;
    };

    # ── A9 followed ref reads the present target ──
    test-followed-ref-resolves-to-present-target = {
      expr = rsRef.a.value.x;
      expected = "B-Y";
    };

    # ── A9 configure policy destructuring hasAspect never fires ──
    test-hasaspect-policy-never-fires = {
      expr = rsNoFire.app.value.level;
      expected = "info";
    };
    test-hasaspect-policy-no-policy-layer = {
      expr = map (e: e.rendered) rsNoFire.app.provenance.level;
      expected = [ "default" ];
    };

    # ── the dispatch gate is a presence gate; the reserved `__` shape is not a gate input ──
    # A gate key ABSENT from ctx ⇒ the rule never fires…
    test-gate-absent-key-never-fires = {
      expr = rsGateAbsent.app.value.level;
      expected = "info";
    };
    test-gate-absent-key-no-policy-layer = {
      expr = map (e: e.rendered) rsGateAbsent.app.provenance.level;
      expected = [ "default" ];
    };
    # …and the same rule keyed on a PRESENT ctx key fires. This is the pair's positive control: it
    # reddens in the same run if dispatch stopped firing, so the arm above cannot pass vacuously. It is
    # also the measurement that retired the `__coords` check — a reserved key does reach the context.
    test-gate-present-reserved-key-fires = {
      expr = rsGatePresent.app.value.level;
      expected = "pwned";
    };
    test-gate-present-reserved-key-policy-layer = {
      expr = map (e: e.rendered) rsGatePresent.app.provenance.level;
      expected = [
        "default"
        "policy"
      ];
    };
  };
}
