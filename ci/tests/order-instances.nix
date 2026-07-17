# The merge-order ORACLES (spec §6) — one file for the three framework discipline instances. Each
# instance DECLARES a merge order (`order = { tiers; withinTier; tieBreak }`); the oracle here proves the
# DECLARATION matches the LIVE fold — the byte-parity proof that "declare, not rewire" is honest. The
# fold code is UNCHANGED (an AC per instance); the oracle reads the production attribute's own provenance
# surface and asserts the order it observes is the order the instance declares. A drifted declaration (or
# a drifted `combine` reference) is caught here. See REFERENCE.md.
#
# T3 lands the `settings-layers` oracle; T4/T5 extend this file with the collections-neron and
# reach-closure oracles.
{
  denHoag,
  ...
}:
let
  sel = denHoag.sel;

  # ── settings-layers (§2.7): the per-(node, aspect) layer fold ────────────────────────────────────
  # A synthetic multi-level fleet: env prod ⊇ host axon ⊇ user alice, with an aspect carrying a schema
  # default and scoped-override layers at EVERY containment level (env, env+host, env+host+user) plus a
  # terminal `configure` policy. The live resolved-settings provenance lists every layer in §2.7 order;
  # the oracle classifies each into its tier and asserts the tier sequence matches the declaration.
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
  mod =
    { config, ... }:
    {
      config.den.aspects.app = {
        neededBy = sel.kind config.den.schema.user; # radiate to the user cell
        settings.level.default = "info"; # the schema-default tier
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
      ];
      # scoped overrides at each containment level (least → most specific) — the `contains` + `slice` tiers.
      config.den.settings.layers = [
        {
          at = {
            env = config.den.env.prod;
          };
          of = config.den.aspects.app;
          set = {
            level = "envlvl";
          };
        }
        {
          at = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
          of = config.den.aspects.app;
          set = {
            level = "hostlvl";
          };
        }
        {
          at = {
            env = config.den.env.prod;
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
          of = config.den.aspects.app;
          set = {
            level = "celllvl";
          };
        }
      ];
      # terminal `configure` policy → the `policy` tier (authority-wins by position, A8).
      config.den.policies.setLvl =
        { user, ... }:
        [
          (denHoag.declare.configure {
            of = config.den.aspects.app;
            set = {
              level = "policylvl";
            };
          })
        ];
    };

  den = (denHoag.mkDen (fleetBase ++ [ mod ])).den;
  settingsInst = den.disciplines.settings-layers;
  cellId = "user:alice@host:axon";
  prov = (den.structural.eval.get cellId "resolved-settings").app.provenance.level;
  renderedOrder = map (e: e.rendered) prov;

  # the cell's full product-dimension count (env, host, user) — a slice at the full coords is the cell's
  # OWN slice (`slice` tier); a strict-ancestor slice (fewer coords) is a containment layer (`contains`).
  fullDimCount = builtins.length den.dimKinds;
  # coordinate count of a slice's rendered label ("env=prod,host=axon" → 2). `builtins.split` interleaves
  # the separator matches (empty lists) between the string parts, so the STRING parts are the coordinates.
  coordCount = r: builtins.length (builtins.filter builtins.isString (builtins.split "," r));
  # classify one provenance `rendered` label into its declared tier.
  tierOf =
    r:
    if r == "default" then
      "schema-default"
    else if r == "policy" then
      "policy"
    else if coordCount r == fullDimCount then
      "slice"
    else
      "contains";
  # the tier of each layer, in fold order, with consecutive duplicates collapsed → the TIER SEQUENCE the
  # live fold realizes (e.g. [schema-default, contains, contains, slice, policy] → the 4-tier order).
  lastOf = xs: builtins.elemAt xs (builtins.length xs - 1);
  dedupConsecutive =
    xs: builtins.foldl' (acc: x: if acc != [ ] && lastOf acc == x then acc else acc ++ [ x ]) [ ] xs;
  liveTierSequence = dedupConsecutive (map tierOf renderedOrder);

  # ── the env-tier golden fleet: a ≥3-level containment chain, least-specific-first ────────────────
  # The same fleet exercises it (env ⊃ host ⊃ user is a 3-level chain); the golden pins that the ANCESTOR
  # slices (the `contains` tier) appear least-specific-first — env before host — never most-specific-first.
  # `containsRendered` = the rendered labels classified into the `contains` tier, in fold order.
  containsRendered = builtins.filter (r: tierOf r == "contains") renderedOrder;
in
{
  flake.tests.order-instances = {
    # ── settings-layers DECLARATION pins ──
    # the instance declares the ordered-monoid laws (order-bearing last-wins-per-field, NOT commutative).
    test-settings-instance-laws = {
      expr = settingsInst.laws;
      expected = "ordered-monoid";
    };
    # the declared tier order (§2.7): schema defaults, then the containment chain, then the scoped-override
    # slices, then the terminal policy layer.
    test-settings-instance-tiers = {
      expr = settingsInst.order.tiers;
      expected = [
        "schema-default"
        "contains"
        "slice"
        "policy"
      ];
    };
    # within-tier rank is the §2.7 linearization (product count-major in `slice`; containment depth
    # descending in `contains`); no producer ties at the layer fold (one layer per aspect/scope/rendered).
    test-settings-instance-within-tier = {
      expr = {
        withinTier = settingsInst.order.withinTier;
        tieBreak = settingsInst.order.tieBreak;
        dedup = settingsInst.dedup;
      };
      expected = {
        withinTier = "linearization";
        tieBreak = null;
        dedup = null;
      };
    };
    # the nominal engine reference (the fold ENGINE leg): the production fold is gen-algebra's traced fold.
    test-settings-instance-engine = {
      expr = settingsInst.engine;
      expected = "gen-algebra record.foldLayersTraced";
    };

    # ── THE ORDER ORACLE (byte-parity proof): the LIVE fold's layer order matches the DECLARATION ──
    # the raw provenance order the live settings attribute folds (default → containment chain → cell → policy).
    test-settings-oracle-rendered-order = {
      expr = renderedOrder;
      expected = [
        "default"
        "env=prod"
        "env=prod,host=axon"
        "env=prod,host=axon,user=alice"
        "policy"
      ];
    };
    # the DECLARED tier sequence IS the sequence the live fold realizes (each rendered label classified into
    # its tier, consecutive duplicates collapsed) — the declaration matches production, so a drift is caught.
    test-settings-oracle-tier-sequence-matches-declaration = {
      expr = liveTierSequence == settingsInst.order.tiers;
      expected = true;
    };

    # ── ENV-TIER GOLDEN (risk register #3): least-specific-first on a ≥3-level containment chain ──
    # the containment (`contains`-tier) slices appear LEAST-SPECIFIC-FIRST — the 1-coord env slice before
    # the 2-coord host slice — the §2.7 "least-specific first" order (an override at a broader scope is
    # laid down before a narrower one, so the narrower wins by position).
    test-golden-settings-env-tier-least-specific-first = {
      expr = containsRendered;
      expected = [
        "env=prod"
        "env=prod,host=axon"
      ];
    };
  };
}
