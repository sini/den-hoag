# A8 — `configure`-emitted layers occupy the terminal `policy` slot (authority-wins by position);
# the schema `default` layer is always first; neither sentinel is declarable (§2.7). Plus the A7
# corollary: the derived slice order is independent of policy declaration order.
#
# The discriminating fold (Spike 5, carried over): env sets `warn`, a `configure` policy sets
# `error` ⇒ `error` wins because the policy layer is terminal, not because of any strength dimension.
{ denHoag, ... }:
let
  sel = denHoag.sel;
  product = denHoag.internal.product;

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

  # ── discriminating fold: env warn, policy configure error ───────────────────────────────────────
  discMod =
    { config, ... }:
    {
      config.den.aspects.app = {
        neededBy = sel.kind config.den.schema.user;
        settings.logLevel = {
          default = "info";
        };
      };
      config.den.include = [
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
            logLevel = "warn";
          };
        }
      ];
      config.den.policies.setLevel =
        { user, ... }:
        [
          (denHoag.declare.configure {
            of = config.den.aspects.app;
            set = {
              logLevel = "error";
            };
          })
        ];
    };
  denDisc = (denHoag.mkDen (fleetBase ++ [ discMod ])).den;
  rsDisc = denDisc.structural.eval.get cellId "resolved-settings";
  levelProv = rsDisc.app.provenance.logLevel;

  # ── slice-order invariance under policy declaration permutation (A7) ─────────────────────────────
  # Two configure policies on different fields; the containment chain (the slice order) must not
  # depend on which policy is declared first.
  twoPolicies =
    order:
    { config, ... }:
    let
      p1 = {
        name = "pAlpha";
        value =
          { user, ... }:
          [
            (denHoag.declare.configure {
              of = config.den.aspects.app;
              set = {
                a = "1";
              };
            })
          ];
      };
      p2 = {
        name = "pBeta";
        value =
          { user, ... }:
          [
            (denHoag.declare.configure {
              of = config.den.aspects.app;
              set = {
                b = "2";
              };
            })
          ];
      };
      ordered =
        if order then
          [
            p1
            p2
          ]
        else
          [
            p2
            p1
          ];
    in
    {
      config.den.aspects.app = {
        neededBy = sel.kind config.den.schema.user;
        settings = {
          a.default = "a0";
          b.default = "b0";
        };
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.app ];
        }
      ];
      config.den.policies = builtins.listToAttrs ordered;
    };
  chainOf =
    den:
    let
      cell = builtins.head den.cells;
    in
    map (e: builtins.attrNames e.fixed) (product.containmentChain den.fleet cell den.linearization);
  denAB = (denHoag.mkDen (fleetBase ++ [ (twoPolicies true) ])).den;
  denBA = (denHoag.mkDen (fleetBase ++ [ (twoPolicies false) ])).den;
in
{
  flake.tests.policy-slot = {
    # ── A8 discriminating fold: policy (terminal) beats env by position ──
    test-policy-configure-wins = {
      expr = rsDisc.app.value.logLevel;
      expected = "error";
    };
    # the env override is present in the chain but shadowed (default < env < policy).
    test-provenance-crosses-env-and-policy = {
      expr = map (e: e.value) levelProv;
      expected = [
        "info"
        "warn"
        "error"
      ];
    };
    # the schema default layer is always first.
    test-default-layer-first = {
      expr = (builtins.head levelProv).rendered;
      expected = "default";
    };
    # the configure layer is always last (terminal `policy` slot).
    test-policy-layer-terminal = {
      expr = (builtins.elemAt levelProv 2).rendered;
      expected = "policy";
    };

    # ── A7: slice order independent of policy declaration order ──
    test-slice-order-invariant = {
      expr = chainOf denAB == chainOf denBA;
      expected = true;
    };
    # and the resolved value is likewise invariant (the two policies touch disjoint fields).
    test-value-invariant-under-permutation = {
      expr =
        (denAB.structural.eval.get cellId "resolved-settings").app.value
        == (denBA.structural.eval.get cellId "resolved-settings").app.value;
      expected = true;
    };
  };
}
