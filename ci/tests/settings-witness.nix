# SETTINGS WITNESS (§10 substrate demonstration, Phase 5a) — proof that `den.productions.settings`
# (the resolved-settings production, dogfooded through the productions surface) EXPRESSES every axis the
# gen-aspects `examples/demo` demonstrates, and EXCEEDS it on two. "Zero per-witness bespoke code": each
# axis is a LOAD-BEARING folded value read off the SAME resolved-settings attribute — no per-axis engine.
#
# The 8 demo axes (mirroring examples/demo/README.md:144-156 shapes) + 2 den supersets:
#   1  tier depth      — 4-tier default<env<host<policy; host beats env beats default (workers 4→16→32).
#   2  per-field       — replace (last-wins) / append (accumulate) / recursive (per-key deep-merge), one
#                        field each, the strategy's effect asserted across ≥2 layers.
#   3  nested schema   — a recursive field whose nested subtree is kept as a MERGE UNIT + a deep dotted read.
#   4  provenance      — per-field winner label AND per-subkey provenance on a recursive field
#                        ({schedule=policy; retention=policy; method=host} — the demo's dbBackup shape).
#   5  policy-as-layer — a `configure` policy patches a field and wins as the TERMINAL layer (over host).
#   6  injection       — a `{settings,...}` aspect's MATERIALISED nixos config reflects the folded winner
#                        (the sanctioned nixpkgs terminal crossing, mirrors settings-injection.nix).
#   7  multi-lattice   — SUPERSET: a scope order the demo's SINGLE neron chain cannot express — the slice
#                        set is `containmentChain` (gen-product, host<user) ⊔ `ancestorsOf'` (a containment
#                        RELATION, env→host) — TWO containment SOURCES + a sibling family sharing env with
#                        NO cross-join. Non-vacuous: without the relation the env layer is INERT.
#   8  schema ext      — gen-schema kind extension auto-attached per aspect (`id_hash`, content-stable, no
#                        manual wiring, distinct per aspect) + user metadata (`tags`) carried per aspect.
#   ref (SUPERSET)     — a settings field that `ref`s ANOTHER aspect's resolved setting (§2.8); the demo
#                        has NONE. Non-vacuous: the ref tracks the referenced aspect's host-tier winner.
{
  denHoag,
  nixpkgs,
  ...
}:
let
  inherit (denHoag) sel ref declare;
  last = l: builtins.elemAt l (builtins.length l - 1);

  # ── FLEET A — the demo-shaped fleet: env prod ⊇ host axon ⊇ user alice (axes 1-5, 8, ref) ───────────
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

  # `palette` is the cross-aspect `ref` TARGET (its `color` resolves at the same cell); `app` carries one
  # field per axis + a `themeColor` that refs palette's color. Both radiate to the user cell.
  mod =
    { config, ... }:
    {
      config.den.aspects = {
        palette = {
          neededBy = sel.kind config.den.schema.user;
          settings.color.default = "red";
        };
        app = {
          neededBy = sel.kind config.den.schema.user;
          tags = [
            "web"
            "public"
          ]; # axis 8 — user metadata carried per aspect
          settings = {
            workers.default = 4; # axis 1/2 replace: default 4, env 16, host 32
            ports = {
              default = [ 22 ];
              merge = "append";
            }; # axis 2 append: [22] ++ [80] ++ [443]
            level.default = "info"; # axis 5 replace: host "hostlvl", policy "pollvl" wins
            backup = {
              default = {
                schedule = "def";
                retention = "def";
                method = "def";
              };
              merge = "recursive";
            }; # axis 2/4 recursive: per-key deep-merge + per-subkey provenance
            store = {
              default = {
                db = {
                  host = "def";
                  port = 5432;
                };
                logging = "off";
              };
              merge = "recursive";
            }; # axis 3 nested: db subtree kept as a merge unit while logging merges
            themeColor.default = ref config.den.aspects.palette [ "color" ]; # ref SUPERSET
          };
        };
      };
      config.den.include = [
        {
          at = config.den.env.prod;
          aspects = [
            config.den.aspects.app
            config.den.aspects.palette
          ];
        }
      ];
      config.den.settings.layers = [
        {
          at.env = config.den.env.prod;
          of = config.den.aspects.app;
          set = {
            workers = 16;
            ports = [ 80 ];
          };
        }
        {
          at.host = config.den.host.axon;
          of = config.den.aspects.app;
          set = {
            workers = 32;
            ports = [ 443 ];
            level = "hostlvl";
            backup = {
              schedule = "host";
              retention = "host";
              method = "host";
            };
            store.logging = "on";
          };
        }
        {
          # the ref's non-vacuous discriminator: palette's `color` wins at the host tier (red → blue),
          # and `app.themeColor` (a ref to palette.color) must TRACK that resolved winner.
          at.host = config.den.host.axon;
          of = config.den.aspects.palette;
          set.color = "blue";
        }
      ];
      # axis 5 — a `configure` policy → the terminal `policy` slot (A8): patches `level` (beats host) and
      # `backup`'s schedule/retention subkeys (per-subkey provenance — schedule/retention=policy, method=host).
      config.den.policies.patch =
        { user, ... }:
        [
          (declare.configure {
            of = config.den.aspects.app;
            set = {
              level = "pollvl";
              backup = {
                schedule = "policy";
                retention = "policy";
              };
            };
          })
        ];
    };

  den = (denHoag.mkDen (fleetBase ++ [ mod ])).den;
  rs = den.structural.eval.get cellId "resolved-settings";
  app = rs.app;

  # per-subkey provenance for a recursive field (consumer-side, the demo's recursiveSubkeyProvenance shape
  # with e.rendered = the layer label): fold the field's provenance, each entry stamping its subkeys.
  subkeyProv =
    field:
    builtins.foldl' (
      acc: e: acc // builtins.mapAttrs (_k: _v: e.rendered) e.value
    ) { } app.provenance.${field};

  # ── FLEET B — axis 6: the nixpkgs terminal crossing (mirrors settings-injection.nix) ────────────────
  # env ⊇ host axon; `svc` is a `{settings,...}` aspect at the host nixos-producing class; a host-tier
  # layer wins over the schema default; the MATERIALISED config must reflect the folded winner ("won").
  injFleet = denHoag.mkDen [
    {
      config.den.schema = {
        env.parent = null;
        host.parent = "env";
      };
    }
    {
      config.den = {
        env.prod = { };
        host.axon = { };
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
        ];
      }
    )
    { config.den.contentClass.host = "nixos"; }
    (
      { config, ... }:
      {
        config.den.aspects.svc = {
          settings.level.default = "base";
          nixos =
            { settings, ... }:
            {
              networking.domain = settings.level;
              nixpkgs.hostPlatform = "x86_64-linux";
            };
        };
        config.den.include = [
          {
            at = config.den.host.axon;
            aspects = [ config.den.aspects.svc ];
          }
        ];
        config.den.settings.layers = [
          {
            at.host = config.den.host.axon;
            of = config.den.aspects.svc;
            set.level = "won";
          }
        ];
      }
    )
    { config.den.nixpkgs = nixpkgs; }
  ];
  injMaterialised = injFleet.nixosConfigurations.axon.config.networking.domain;

  # ── FLEET C — axis 7: multi-lattice scope order (SUPERSET, mirrors topology-join.nix) ───────────────
  # schema env <- host <- user (cell family) + a SIBLING env <- cluster. The user cell is a STATIC
  # {host,user} product tuple — `env` is DELIBERATELY not a product dim. A `containTo`-marked member routes
  # env as host's containment-RELATION ancestor, so the settings slice set is the gen-product chain
  # (host<user) ⊔ the ancestorsOf' relation (env). The demo's SINGLE neron chain cannot express this:
  # env enters as a SECOND containment source, and a sibling `cluster` shares env WITHOUT cross-joining.
  mlSchema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
      cluster.parent = "env";
    };
  };
  mlInstances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      user.alice = { };
      cluster.k3s = { };
    };
  };
  # STATIC {host,user} membership — env is DELIBERATELY not a product dim (enters via the relation only).
  mlMembership =
    { config, ... }:
    {
      config.den.contentClass.user = "nixos";
      config.den.membership = [
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  # env→host CONTAINMENT relation (source #2): records env as host's ancestor (the env settings slice).
  mlEnvToHost =
    { config, ... }:
    {
      config.den.policies.env-to-host =
        { env, ... }:
        [
          (declare.member {
            coords = {
              inherit env;
              host = config.den.host.axon;
            };
            containTo = "host";
          })
        ];
    };
  # env→cluster CONTAINMENT relation: the SIBLING family shares env but must NOT cross-join the user cell.
  mlEnvToCluster =
    { config, ... }:
    {
      config.den.policies.env-to-cluster =
        { env, ... }:
        [
          (declare.member {
            coords = {
              inherit env;
              cluster = config.den.cluster.k3s;
            };
            containTo = "cluster";
          })
        ];
    };
  mlApp =
    { config, ... }:
    {
      config.den.aspects.svc = {
        settings.mem.default = 0;
      };
      config.den.include = [
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.svc ];
        }
      ];
    };
  # the full default<env<host<user layer stack (env slice only surfaces via the containment relation).
  mlLayers =
    { config, ... }:
    {
      config.den.settings.layers = [
        {
          at.env = config.den.env.prod;
          of = config.den.aspects.svc;
          set.mem = 1;
        }
        {
          at.host = config.den.host.axon;
          of = config.den.aspects.svc;
          set.mem = 2;
        }
        {
          at = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
          of = config.den.aspects.svc;
          set.mem = 3;
        }
      ];
    };
  mlBase = [
    mlSchema
    mlInstances
    mlMembership
    mlApp
  ];
  mlCellId = "user:alice@host:axon";
  mlRsOf = d: d.structural.eval.get mlCellId "resolved-settings";
  # (with) both containment relations + the full cascade — env folds between default and host.
  mlWith =
    (denHoag.mkDen (
      mlBase
      ++ [
        mlEnvToHost
        mlEnvToCluster
        mlLayers
      ]
    )).den;
  # (without) the env→host relation → the env layer is INERT (env not in the cell's slice set).
  mlWithout = (denHoag.mkDen (mlBase ++ [ mlLayers ])).den;
  mlProv = d: map (e: e.rendered) (mlRsOf d).svc.provenance.mem;
in
{
  flake.tests.settings-witness = {
    # ── axis 1 — TIER DEPTH: 4-tier default<env<host<policy; host beats env beats default (workers) ──
    test-axis1-tier-depth-host-wins = {
      expr = app.value.workers;
      expected = 32;
    };
    test-axis1-tier-order = {
      expr = map (e: e.rendered) app.provenance.workers;
      expected = [
        "default"
        "env=prod"
        "host=axon"
      ];
    };
    test-axis1-tier-values = {
      expr = map (e: e.value) app.provenance.workers;
      expected = [
        4
        16
        32
      ];
    };

    # ── axis 2 — PER-FIELD STRATEGY across ≥2 layers ──
    # replace = last-wins (host over env over default); append = accumulate; recursive = per-key deep-merge.
    test-axis2-replace-last-wins = {
      expr = app.value.workers;
      expected = 32;
    };
    test-axis2-append-accumulates = {
      expr = app.value.ports;
      expected = [
        22
        80
        443
      ];
    };
    test-axis2-recursive-per-key = {
      # recursive: schedule/retention overridden by policy, method retained from host — a per-KEY merge,
      # not a wholesale replace (replace would drop method; the whole value would be the policy set).
      expr = app.value.backup;
      expected = {
        schedule = "policy";
        retention = "policy";
        method = "host";
      };
    };

    # ── axis 3 — NESTED SCHEMA: a recursive field's nested subtree kept as a MERGE UNIT + deep dotted read ──
    # host sets only `store.logging`; the `db` subtree survives INTACT from the default (host + port both),
    # while `logging` merges — the subtree is one merge unit, not deep-flattened.
    test-axis3-subtree-merge-unit = {
      expr = app.value.store;
      expected = {
        db = {
          host = "def";
          port = 5432;
        };
        logging = "on";
      };
    };
    test-axis3-deep-dotted-path = {
      expr = app.value.store.db.port;
      expected = 5432;
    };

    # ── axis 4 — PROVENANCE: per-field winner label AND per-subkey provenance on a recursive field ──
    test-axis4-field-winner-label = {
      expr = (last app.provenance.workers).rendered;
      expected = "host=axon";
    };
    # per-subkey provenance on the recursive `backup` (the demo's dbBackup shape): subkeys schedule +
    # retention won by the policy, method won by the host — DISTINCT winners on one field.
    test-axis4-per-subkey-provenance = {
      expr = subkeyProv "backup";
      expected = {
        schedule = "policy";
        retention = "policy";
        method = "host=axon";
      };
    };

    # ── axis 5 — POLICY-AS-LAYER: a `configure` policy wins as the TERMINAL layer over host ──
    test-axis5-policy-wins-terminal = {
      expr = app.value.level;
      expected = "pollvl";
    };
    test-axis5-policy-is-last-layer = {
      expr = (last app.provenance.level).rendered;
      expected = "policy";
    };
    # non-vacuous negative control: policy does NOT touch workers → host still wins (no phantom terminal).
    test-axis5-negative-control-host-wins = {
      expr = (last app.provenance.workers).rendered;
      expected = "host=axon";
    };

    # ── axis 6 — INJECTION: the MATERIALISED nixos config reflects the folded host-tier winner ──
    test-axis6-materialised-folded-winner = {
      expr = injMaterialised;
      expected = "won";
    };

    # ── axis 7 — MULTI-LATTICE (SUPERSET): slice set = gen-product chain (host<user) ⊔ containment
    #    relation (env→host). env sits BETWEEN default and host — a slice the product chain alone cannot
    #    produce (env is not a product dim of the cell). The demo's single neron chain cannot express it. ──
    test-axis7-multi-lattice-value = {
      expr = (mlRsOf mlWith).svc.value.mem;
      expected = 3;
    };
    test-axis7-multi-lattice-order = {
      expr = mlProv mlWith;
      expected = [
        "default"
        "env=prod" # ← the containment-RELATION slice (source #2), not a product dim
        "host=axon"
        "host=axon,user=alice"
      ];
    };
    # SUPERSET non-vacuous: the `env=prod` slice is present in the fold IFF the env→host relation exists.
    # WITH it env folds (source #2); WITHOUT it the SAME env layer is INERT (the product chain host<user
    # still folds, but env is not a product dim so it never enters). This gated second containment source
    # is exactly what the demo's single neron chain cannot reproduce.
    test-axis7-env-slice-gated-by-relation = {
      expr = {
        withRelation = builtins.elem "env=prod" (mlProv mlWith);
        withoutRelation = builtins.elem "env=prod" (mlProv mlWithout);
      };
      expected = {
        withRelation = true;
        withoutRelation = false;
      };
    };
    # …and the product-chain slices (host<user) fold either way — only the env RELATION slice is gated.
    test-axis7-product-chain-unrelated = {
      expr = mlProv mlWithout;
      expected = [
        "default"
        "host=axon"
        "host=axon,user=alice"
      ];
    };
    # the sibling `cluster` shares env yet the user cell carries ONLY {host,user} — no cross-join.
    test-axis7-sibling-no-cross-join = {
      expr = builtins.attrNames (builtins.head mlWith.cells);
      expected = [
        "host"
        "user"
      ];
    };

    # ── axis 8 — SCHEMA EXTENSION: gen-schema kind extension auto-attached per aspect (id_hash) + metadata ──
    # id_hash is declared ONCE on the aspect kind (idModule) and auto-derived (content-stable sha256 over
    # the key) on EVERY aspect instance — no manual wiring, distinct per aspect. `tags` is user metadata.
    test-axis8-id-hash-auto-attached = {
      expr =
        builtins.isString den.aspects.app.id_hash && builtins.stringLength den.aspects.app.id_hash == 64;
      expected = true;
    };
    test-axis8-id-hash-distinct = {
      expr = den.aspects.app.id_hash != den.aspects.palette.id_hash;
      expected = true;
    };
    test-axis8-tags-carried = {
      expr = den.aspects.app.tags;
      expected = [
        "web"
        "public"
      ];
    };

    # ── ref (SUPERSET, no demo counterpart) — `app.themeColor` refs `palette.color`; it resolves to
    #    palette's RESOLVED host-tier winner (red default → blue at host), tracking the target aspect. ──
    test-ref-cross-aspect-resolves = {
      expr = app.value.themeColor;
      expected = "blue";
    };
    # non-vacuous: the ref tracks the RESOLVED target — the palette default alone would be "red".
    test-ref-tracks-resolved-target = {
      expr = rs.palette.value.color;
      expected = "blue";
    };
  };
}
