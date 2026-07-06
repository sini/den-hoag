# A16 — resolved-settings as an attribute (§2.10 #13 / §2.7 / §2.8). Three guarantees:
#   value-identity  — `resolved-settings.value` is byte-identical to a plain `gen-algebra.foldLayers`
#                     over the SAME ordered layer values (the Spike-5 gate, now on the attribute).
#   provenance      — the provenance for one cell address lists every layer in §2.7 order, crossing
#                     default / env / host / projection (via) / cell / policy, with structured entries.
#   shadowed-ref    — a schema-default `ref` to an ABSENT aspect, overridden by a more-specific layer,
#                     resolves `.value` without aborting (§2.8, per-entry-lazy substitution).
#
# The fold + provenance shapes are gen-settings' own; this suite is a golden OVER that shape.
{ denHoag, ... }:
let
  sel = denHoag.sel;
  ref = denHoag.ref;
  foldLayers = denHoag.internal.algebra.record.foldLayers;

  # ── shared fleet: env prod ⊇ host axon ⊇ user alice ─────────────────────────────────────────────
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

  # ── the app aspect + a full layer stack: env, host, projection(via theme), cell, policy ─────────
  appFields = {
    level = {
      default = "info";
    }; # replace
    tcp = {
      default = [ 22 ];
      merge = "append";
    }; # append
  };
  strategies = {
    level = "replace";
    tcp = "append";
  };
  defaults = {
    level = "info";
    tcp = [ 22 ];
  };

  envSet = {
    level = "warn";
    tcp = [ 80 ];
  };
  hostSet = {
    level = "hostlvl";
    tcp = [ 443 ];
  };
  projSet = {
    level = "projlvl";
    tcp = [ 999 ];
  };
  cellSet = {
    level = "celllvl";
    tcp = [ 8080 ];
  };
  policySet = {
    level = "policylvl";
  }; # configure sets `level` only (tcp untouched → append skips it)

  mod =
    { config, ... }:
    {
      config.den.aspects = {
        # `theme` — the projecting aspect (the projection layer's `via`); needs an id_hash, no settings.
        theme = { };
        app = {
          neededBy = sel.kind config.den.schema.user; # radiate to the user cell
          settings = appFields;
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
          set = envSet;
        }
        {
          at = {
            host = config.den.host.axon;
          };
          of = config.den.aspects.app;
          set = hostSet;
        }
        {
          # projection layer — a `via`-carrying override at the {host,user} slice (sorts into the
          # projection slot for that slice, immediately before any direct override there).
          at = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
          of = config.den.aspects.app;
          via = config.den.aspects.theme;
          set = projSet;
        }
        {
          at = {
            env = config.den.env.prod;
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
          of = config.den.aspects.app;
          set = cellSet;
        }
      ];
      # policy `configure` → the terminal `policy` slot.
      config.den.policies.setAppLevel =
        { user, ... }:
        [
          (denHoag.declare.configure {
            of = config.den.aspects.app;
            set = policySet;
          })
        ];
    };

  den = (denHoag.mkDen (fleetBase ++ [ mod ])).den;
  ev = den.structural.eval;
  rs = ev.get cellId "resolved-settings";
  appProvLevel = rs.app.provenance.level;

  # ── byte-parity reference: foldLayers over the same ordered layer values ─────────────────────────
  orderedValues = [
    envSet
    hostSet
    projSet
    cellSet
    policySet
  ];
  expectedValue = foldLayers {
    inherit strategies defaults;
    layers = orderedValues;
  };

  # ── shadowed-ref: term.font default is a ref to an ABSENT aspect, overridden at the cell ─────────
  shadowMod =
    { config, ... }:
    {
      config.den.aspects = {
        absentTarget = { }; # declared (⇒ has an id_hash for `ref`), never present at the cell
        term = {
          neededBy = sel.kind config.den.schema.user;
          settings.font.default = ref config.den.aspects.absentTarget [ "gone" ];
        };
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [ config.den.aspects.term ];
        }
      ];
      config.den.settings.layers = [
        {
          at = {
            host = config.den.host.axon;
          };
          of = config.den.aspects.term;
          set = {
            font = "concrete";
          };
        }
      ];
    };
  denShadow = (denHoag.mkDen (fleetBase ++ [ shadowMod ])).den;
  rsShadow = denShadow.structural.eval.get cellId "resolved-settings";
in
{
  flake.tests.settings-attribute = {
    # ── value-identity gate (A16) ──
    test-value-byte-identical-to-foldLayers = {
      expr = rs.app.value;
      expected = expectedValue;
    };
    # the discriminating fields, spelled out (append accumulates in §2.7 order; replace = policy wins).
    test-append-accumulates-in-order = {
      expr = rs.app.value.tcp;
      expected = [
        22
        80
        443
        999
        8080
      ];
    };
    test-replace-policy-wins = {
      expr = rs.app.value.level;
      expected = "policylvl";
    };

    # ── provenance golden: default → env → host → projection → cell → policy (§2.7 order) ──
    test-provenance-rendered-order = {
      expr = map (e: e.rendered) appProvLevel;
      expected = [
        "default"
        "env=prod"
        "host=axon"
        "host=axon,user=alice"
        "env=prod,host=axon,user=alice"
        "policy"
      ];
    };
    test-provenance-values = {
      expr = map (e: e.value) appProvLevel;
      expected = [
        "info"
        "warn"
        "hostlvl"
        "projlvl"
        "celllvl"
        "policylvl"
      ];
    };
    # the projection entry carries `via` = the projecting aspect's identity; all others are null.
    test-provenance-projection-via = {
      expr = map (e: if e.via == null then null else e.via.id_hash) appProvLevel;
      expected = [
        null
        null
        null
        den.aspects.theme.id_hash
        null
        null
      ];
    };
    # gen-settings' own provenance shape — the default entry's scope is the aspect identity (§4.3).
    test-provenance-default-scope-aspect = {
      expr = (builtins.head appProvLevel).scope.aspect.id_hash;
      expected = den.aspects.app.id_hash;
    };

    # ── shadowed ref (§2.8, per-entry-lazy): default ref to an absent aspect, overridden ──
    test-shadowed-ref-value-resolves = {
      expr = rsShadow.term.value.font;
      expected = "concrete";
    };
    test-shadowed-ref-value-forceable = {
      expr = (builtins.tryEval (builtins.deepSeq rsShadow.term.value true)).success;
      expected = true;
    };
  };
}
