# resolved-aspects joint neededBy+guard fixpoint (r2 §B4 / A11). Over a two-host fleet
# (env:prod ⊇ {axon, blade}; alice@axon, carol@blade):
#
#   check 2 (§B4a registration-scope visibility) — an aspect with `neededBy = sel.kind user`
#     included at host:axon reaches axon's user (alice) ONLY; the same shape included at env:prod
#     reaches every user under prod (alice AND carol).
#   check 3 (§B4b joint fixpoint) — a guard-activated aspect's neededBy fires: `needT.neededBy =
#     [ guardG ]` appears once guardG activates via its guard, even though guardG arrived via guard,
#     not include (presence is arrival-path independent).
#   A9.1 — a guard receives `{ pathSet, hasAspect }` ONLY: a guard probing for a `settings` arg
#     sees none, so it activates.
#   bonus — aspect-level `meta.drop` prunes a resolved aspect post-fixpoint.
{ denHoag, ... }:
let
  sel = denHoag.sel;

  # ── shared fleet: env prod, hosts axon + blade, alice@axon, carol@blade ──────────────────
  schema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
    };
  };
  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      host.blade = { };
      user.alice = { };
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
            host = config.den.host.blade;
            user = config.den.user.carol;
          };
        }
      ];
    };
  fleetBase = [
    schema
    instances
    membership
  ];

  aliceCell = "user:alice@host:axon";
  carolCell = "user:carol@host:blade";
  axonId = "host:axon";
  bladeId = "host:blade";

  keysOf = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  has =
    den: id: k:
    builtins.elem k (keysOf den id);

  # ── check 2 — registration-scope visibility ────────────────────────────────────────────────
  # webA included at host:axon; webB included at env:prod; both `neededBy = sel.kind user`.
  nbMod =
    { config, ... }:
    {
      config.den.aspects = {
        webA.neededBy = sel.kind config.den.schema.user;
        webB.neededBy = sel.kind config.den.schema.user;
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.webA ];
        }
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.webB ];
        }
      ];
    };
  denNB = (denHoag.mkDen (fleetBase ++ [ nbMod ])).den;

  # ── check 3 — guard-arrived trigger fires neededBy ──────────────────────────────────────────
  # baseX included at axon; guardG activates when baseX present; needT is neededBy guardG.
  guardMod =
    { config, ... }:
    {
      config.den.aspects = {
        baseX = { };
        guardG.meta.guard = { hasAspect, ... }: hasAspect config.den.aspects.baseX;
        needT.neededBy = [ config.den.aspects.guardG ];
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.baseX ];
        }
      ];
    };
  denGuard = (denHoag.mkDen (fleetBase ++ [ guardMod ])).den;

  # ── A9.1 — guard sees only { pathSet, hasAspect } ───────────────────────────────────────────
  # probeSettings activates iff no `settings` arg was passed to the guard.
  a91Mod =
    { config, ... }:
    {
      config.den.aspects.probeSettings.meta.guard = { pathSet, ... }@args: !(args ? settings);
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ ]; # probeSettings needs no include — its guard is unconditional
        }
      ];
    };
  denA91 = (denHoag.mkDen (fleetBase ++ [ a91Mod ])).den;

  # ── bonus — aspect-level meta.drop ──────────────────────────────────────────────────────────
  dropMod =
    { config, ... }:
    {
      config.den.aspects = {
        keepMe = { };
        dropMe = { };
        dropper.meta.drop = [ config.den.aspects.dropMe ];
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [
            config.den.aspects.keepMe
            config.den.aspects.dropMe
            config.den.aspects.dropper
          ];
        }
      ];
    };
  denDrop = (denHoag.mkDen (fleetBase ++ [ dropMod ])).den;
in
{
  flake.tests.b4-fixpoint = {
    # ── check 2 (§B4a) ──
    # webA is directly resolved at its registration scope (host:axon).
    test-nb-host-carrier-resolves = {
      expr = has denNB axonId "webA";
      expected = true;
    };
    # …and radiates to axon's user cell (selector matches + carrier resolved at ancestor).
    test-nb-host-reaches-own-user = {
      expr = has denNB aliceCell "webA";
      expected = true;
    };
    # …but NOT to a user under another host (webA is not in carol's ancestor sets).
    test-nb-host-not-other-user = {
      expr = has denNB carolCell "webA";
      expected = false;
    };
    # webB, included at env:prod, radiates to EVERY user under prod.
    test-nb-env-reaches-alice = {
      expr = has denNB aliceCell "webB";
      expected = true;
    };
    test-nb-env-reaches-carol = {
      expr = has denNB carolCell "webB";
      expected = true;
    };

    # ── check 3 (§B4b) ──
    # the guard-activated aspect enters the resolved set (its trigger baseX is present).
    test-guard-activates = {
      expr = has denGuard axonId "guardG";
      expected = true;
    };
    # its neededBy target appears — presence arrival-path independent (guardG arrived via guard).
    test-guard-arrived-neededby-fires = {
      expr = has denGuard axonId "needT";
      expected = true;
    };
    # genuinely gated: with no baseX present (blade), neither guardG nor needT resolves.
    test-guard-gated-off-when-trigger-absent = {
      expr = has denGuard bladeId "guardG" || has denGuard bladeId "needT";
      expected = false;
    };

    # ── A9.1 ──
    # the guard received no `settings` arg, so the settings-probe guard activated.
    test-guard-sees-no-settings = {
      expr = has denA91 axonId "probeSettings";
      expected = true;
    };

    # ── bonus: aspect-level meta.drop ──
    test-drop-prunes-target = {
      expr = has denDrop axonId "dropMe";
      expected = false;
    };
    test-drop-keeps-siblings = {
      expr = (has denDrop axonId "keepMe") && (has denDrop axonId "dropper");
      expected = true;
    };
  };
}
