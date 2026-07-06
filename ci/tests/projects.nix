# Task 7 — the `projects` facet (§2.9 / A14, v1 experimental). An aspect P projects settings onto
# OTHER aspects matching a STATIC aspect-schema selector; the projection compiles into `via`-carrying
# settings layers at P's attachment scope, folded by resolved-settings exactly like a hand-written
# `via` layer. This golden pins the four A14 laws:
#
#   attachment-scope-only (A14.1)  — a fleet-scope projection (P included at the top entity) yields
#     EXACTLY ONE layer per matching target, folded fleet-wide by the containment chain — never one
#     layer per descendant. A host-scope projection is more specific and wins.
#   direct beats projection (§2.7) — a direct `den.settings.layers` override at the same slice sorts
#     AFTER the projection (projection ++ direct), so the direct value wins.
#   static selector only (A14.2)   — a dynamic (scope-navigating) selector aborts at definition time.
#   same-scope collision (A14.3)   — two DISTINCT projectors onto one target at one scope abort,
#     naming both.
#   additive (experimental)        — removing the facet leaves every non-projected output byte-identical.
{ denHoag, ... }:
let
  sel = denHoag.sel;
  hasSetting = denHoag.hasSetting;

  # ── shared fleet: env prod ⊇ host axon ⊇ user alice (mirrors settings-attribute) ─────────────────
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

  # `app` is the projection TARGET (declares a `palette` field, radiates to the user cell). `other` is
  # a NON-target (declares `size`, no `palette`) — its resolved settings must be untouched by any
  # projection (the additive law).
  targetsMod =
    { config, ... }:
    {
      config.den.aspects = {
        app = {
          neededBy = sel.kind config.den.schema.user;
          settings.palette.default = "base";
        };
        other = {
          neededBy = sel.kind config.den.schema.user;
          settings.size.default = "M";
        };
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [
            config.den.aspects.app
            config.den.aspects.other
          ];
        }
      ];
    };

  # A projecting aspect included at ENTITY `at`, projecting `set` onto every aspect that declares
  # `field`. `theme` has no settings of its own — it exists only to carry the projection.
  projectorMod =
    {
      name,
      at,
      field,
      set,
    }:
    { config, ... }:
    {
      config.den.aspects.${name}.projects = [
        {
          select = hasSetting field;
          inherit set;
        }
      ];
      config.den.include = [
        {
          at = at config;
          aspects = [ config.den.aspects.${name} ];
        }
      ];
    };

  rsOf = den: den.structural.eval.get cellId "resolved-settings";
  viaNames = prov: map (e: if e.via == null then null else e.via.name) prov;

  # ── (A) fleet-scope projection: exactly one layer, folded fleet-wide ─────────────────────────────
  denFleet =
    (denHoag.mkDen (
      fleetBase
      ++ [
        targetsMod
        (projectorMod {
          name = "theme";
          at = c: c.den.env.prod;
          field = "palette";
          set.palette = "dark";
        })
      ]
    )).den;
  rsFleet = rsOf denFleet;

  # ── (B) host-scope projection wins by specificity over a fleet-scope one ─────────────────────────
  denSpecificity =
    (denHoag.mkDen (
      fleetBase
      ++ [
        targetsMod
        (projectorMod {
          name = "theme";
          at = c: c.den.env.prod;
          field = "palette";
          set.palette = "dark";
        })
        (projectorMod {
          name = "hostTheme";
          at = c: c.den.host.axon;
          field = "palette";
          set.palette = "light";
        })
      ]
    )).den;
  rsSpecificity = rsOf denSpecificity;

  # ── (C) a direct override at the same slice beats the projection there ───────────────────────────
  denDirect =
    (denHoag.mkDen (
      fleetBase
      ++ [
        targetsMod
        (projectorMod {
          name = "hostTheme";
          at = c: c.den.host.axon;
          field = "palette";
          set.palette = "light";
        })
        (
          { config, ... }:
          {
            config.den.settings.layers = [
              {
                at.host = config.den.host.axon;
                of = config.den.aspects.app;
                set.palette = "direct";
              }
            ];
          }
        )
      ]
    )).den;
  rsDirect = rsOf denDirect;
  directProv = rsDirect.app.provenance.palette;

  # ── (D) same-scope same-address collision aborts naming both projectors ──────────────────────────
  denCollision =
    (denHoag.mkDen (
      fleetBase
      ++ [
        targetsMod
        (projectorMod {
          name = "themeA";
          at = c: c.den.env.prod;
          field = "palette";
          set.palette = "a";
        })
        (projectorMod {
          name = "themeB";
          at = c: c.den.env.prod;
          field = "palette";
          set.palette = "b";
        })
      ]
    )).den;

  # ── (E) a dynamic (scope-navigating) selector aborts at definition time ──────────────────────────
  denDynamic =
    (denHoag.mkDen (
      fleetBase
      ++ [
        targetsMod
        (
          { config, ... }:
          {
            config.den.aspects.badTheme.projects = [
              {
                select = sel.within (sel.kind config.den.schema.host);
                set.palette = "x";
              }
            ];
            config.den.include = [
              {
                at = config.den.env.prod;
                aspects = [ config.den.aspects.badTheme ];
              }
            ];
          }
        )
      ]
    )).den;

  # ── (F) additive: removing the facet leaves the non-projected `other` byte-identical ─────────────
  denWithout = (denHoag.mkDen (fleetBase ++ [ targetsMod ])).den;
  rsWithout = rsOf denWithout;
in
{
  flake.tests.projects = {
    # ── (A) attachment-scope-only: one fleet-scope layer, no per-descendant duplication ──
    test-fleet-projection-value = {
      expr = rsFleet.app.value.palette;
      expected = "dark";
    };
    # exactly ONE projection (via) entry in the cell's provenance — a fleet-scope projection folds
    # fleet-wide through the containment chain, it is not re-emitted per descendant node (A14.1).
    test-fleet-projection-single-layer = {
      expr = builtins.length (builtins.filter (e: e.via != null) rsFleet.app.provenance.palette);
      expected = 1;
    };
    test-fleet-projection-via-is-theme = {
      expr = viaNames rsFleet.app.provenance.palette;
      expected = [
        null # default
        "theme" # projection at env=prod (via theme)
      ];
    };
    # the non-target aspect is never touched by the projection.
    test-fleet-nontarget-untouched = {
      expr = rsFleet.other.value.size;
      expected = "M";
    };

    # ── (B) host-scope wins by specificity ──
    test-host-projection-wins = {
      expr = rsSpecificity.app.value.palette;
      expected = "light";
    };
    # both projections are present, ordered least→most specific (env before host), both via-carrying.
    test-host-projection-both-layers = {
      expr = viaNames rsSpecificity.app.provenance.palette;
      expected = [
        null # default
        "theme" # env=prod projection
        "hostTheme" # host=axon projection (more specific ⇒ wins)
      ];
    };

    # ── (C) direct override beats projection at the same slice (§2.7 projection ++ direct) ──
    test-direct-beats-projection = {
      expr = rsDirect.app.value.palette;
      expected = "direct";
    };
    # at the host slice the projection (via hostTheme) sorts immediately before the direct (via null).
    test-direct-slice-order = {
      expr = viaNames directProv;
      expected = [
        null # default
        "hostTheme" # host=axon projection
        null # host=axon direct override (wins)
      ];
    };

    # ── (D) same-scope collision aborts ──
    test-collision-aborts = {
      expr = (builtins.tryEval (builtins.deepSeq (rsOf denCollision).app.value true)).success;
      expected = false;
    };

    # ── (E) dynamic selector aborts ──
    test-dynamic-selector-aborts = {
      expr = (builtins.tryEval (builtins.deepSeq (rsOf denDynamic).app.value true)).success;
      expected = false;
    };

    # ── (F) additive: non-projected output byte-identical with the facet removed ──
    test-additive-nontarget-byte-identical = {
      expr = rsFleet.other == rsWithout.other;
      expected = true;
    };
    # …and the projection is non-vacuous: WITH the projector the target changed, WITHOUT it is default.
    test-additive-target-changed = {
      expr = rsWithout.app.value.palette;
      expected = "base";
    };
  };
}
