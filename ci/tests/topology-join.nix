# §3c-UNIFIED — TOPOLOGY-FOLLOWING JOIN SEMANTICS + TUPLE-CARRIED BINDINGS (design note 2026-07-11 §3c).
# The rung's witnesses over a SYNTHETIC corpus-shaped topology `env <- host <- user` (the cell family)
# with a SIBLING root `env <- cluster` — the genericity pin (no corpus vocabulary drives the mechanism):
#
#   • TWO-SIBLING-FAMILY (NO CROSS-JOIN): `resolve.to`/`containTo` a registry-backed ROOT (cluster) is a
#     CONTAINMENT tuple, NEVER a product cell — the user cells carry ONLY {host,user} coords (no spurious
#     `cluster`/`env`), and the sibling `cluster` stays a readable ROOT scope. This is the cluster-flip
#     bug's grave: a single product cannot cross-join a sibling family that never enters it.
#   • SETTINGS CASCADE (the owner's requirement): default < env < host < user resolves IN THAT ORDER at a
#     user cell — with `env` arriving as a CHAIN-EXTENSION ancestor (a containment relation), NOT a product
#     dimension. The non-vacuous pin: WITHOUT the env→host containment tuple the `env` layer is INERT (the
#     chain extension is the ONLY thing that surfaces the env slice).
#   • BINDINGS RIDE THE TUPLE: the containment tuple's bindings reach the target root's ctx (the accessGroups
#     twin).
#   • CELL IDS UNCHANGED: the user cell keys `user:<n>@host:<h>` (no literal triples), env never a coordinate.
{ denHoag, ... }:
let
  inherit (denHoag) declare sel;

  sortStr = builtins.sort (a: b: a < b);

  # ── the synthetic topology: env <- host <- user (cell family) + env <- cluster (sibling root) ──────────
  schema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
      cluster.parent = "env";
    };
  };
  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      user.alice = { };
      cluster.k3s = { };
    };
  };
  # The user CELL is a STATIC {host,user} membership tuple — `env` is DELIBERATELY absent as a product dim
  # (it enters the settings chain via the containment relation ONLY, not a coordinate).
  cellMembership =
    { config, ... }:
    {
      config.den.contentClass.user = "nixos"; # collect terminal (den.nixpkgs = null)
      config.den.membership = [
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };

  # env→host CONTAINMENT tuple (§3c): carries `grant` into host:axon ctx AND records env as host's ancestor
  # (the settings-chain env slice). A resolve-family policy gated on the `env` coordinate — the pre-pass
  # fires it at env roots (parent-before-child). `containTo = "host"`.
  envToHost =
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
            bindings.grant = "g-${env.name}";
            containTo = "host";
          })
        ];
    };
  # env→cluster CONTAINMENT tuple — the SIBLING branch: cluster is a registry-backed root, so this is a
  # containment relation (env→cluster), NEVER a cell. It must NOT cross-join the user family.
  envToCluster =
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

  # The `app` aspect (settings-only) included DIRECTLY at the user cell's entity, so it is present there.
  appMod =
    { config, ... }:
    {
      config.den.aspects.app = {
        settings.mem.default = 0;
      };
      config.den.include = [
        {
          at = config.den.user.alice;
          aspects = [ config.den.aspects.app ];
        }
      ];
    };
  # The full default<env<host<user layer stack (each overrides `mem`).
  fullLayers =
    { config, ... }:
    {
      config.den.settings.layers = [
        {
          at.env = config.den.env.prod;
          of = config.den.aspects.app;
          set.mem = 1;
        }
        {
          at.host = config.den.host.axon;
          of = config.den.aspects.app;
          set.mem = 2;
        }
        {
          at = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
          of = config.den.aspects.app;
          set.mem = 3;
        }
      ];
    };
  # ONLY the env layer — to isolate whether the env slice is in the chain.
  envOnlyLayer =
    { config, ... }:
    {
      config.den.settings.layers = [
        {
          at.env = config.den.env.prod;
          of = config.den.aspects.app;
          set.mem = 1;
        }
      ];
    };

  base = [
    schema
    instances
    cellMembership
    appMod
  ];
  cellId = "user:alice@host:axon";
  rsOf = den: den.structural.eval.get cellId "resolved-settings";
  memProv = den: rendered: (rsOf den).app.provenance.mem;

  # (A) the FULL fleet — both containment tuples + the full cascade layer stack.
  full =
    (denHoag.mkDen (
      base
      ++ [
        envToHost
        envToCluster
        fullLayers
      ]
    )).den;
  # (B) env layer WITH the env→host containment → env slice IS in the cell chain.
  envWithContain =
    (denHoag.mkDen (
      base
      ++ [
        envToHost
        envOnlyLayer
      ]
    )).den;
  # (C) env layer WITHOUT the env→host containment → env slice is ABSENT (inert layer).
  envNoContain = (denHoag.mkDen (base ++ [ envOnlyLayer ])).den;
  # (D) NO containment tuples, NO layers — the native identity path (containmentRelations = { }).
  native = (denHoag.mkDen base).den;

  cellCoordDims = den: sortStr (builtins.attrNames (builtins.head den.cells));
in
{
  flake.tests.topology-join = {
    # ── TWO-SIBLING-FAMILY: NO CROSS-JOIN ────────────────────────────────────────────────────────────────
    # The user cell carries ONLY {host,user} coords — the sibling `cluster` (and `env`) never enter the
    # product. (Under the old member rendering `cluster` flipped to a cell and cross-joined, adding a
    # spurious `cluster`/`env` coord — the delivery blocker.)
    test-user-cell-no-sibling-coord = {
      expr = cellCoordDims full;
      expected = [
        "host"
        "user"
      ];
    };
    # exactly one user cell (no cross-join multiplication by the cluster/env families).
    test-single-user-cell = {
      expr = builtins.length full.cells;
      expected = 1;
    };
    # the product dimensions are the cell family axes only — env and cluster are NOT dims.
    test-dims-are-cell-family-only = {
      expr = sortStr full.dimKinds;
      expected = [
        "host"
        "user"
      ];
    };
    # the sibling `cluster` is a readable ROOT scope node (its k8s content is read off the root entity).
    test-sibling-cluster-is-root = {
      expr = full.scopeRoots ? "cluster:k3s";
      expected = true;
    };
    # the cell id is the 2-coord form `user:<n>@host:<h>` — no literal triple (addressing churn eliminated).
    test-cell-id-unchanged = {
      expr = (rsOf full) ? app; # the 2-coord cell id resolves
      expected = true;
    };

    # ── SETTINGS CASCADE: default < env < host < user (the owner's requirement) ───────────────────────────
    # The resolved value is the user override (most specific), and the provenance lists default → env →
    # host → user IN ORDER — env sitting between default and host proves the chain-extension env slice.
    test-cascade-value = {
      expr = (rsOf full).app.value.mem;
      expected = 3;
    };
    test-cascade-provenance-order = {
      expr = map (e: e.rendered) (memProv full null);
      expected = [
        "default"
        "env=prod"
        "host=axon"
        "host=axon,user=alice"
      ];
    };
    test-cascade-provenance-values = {
      expr = map (e: e.value) (memProv full null);
      expected = [
        0
        1
        2
        3
      ];
    };

    # ── NON-VACUOUS: the env slice arrives via the CONTAINMENT RELATION, nothing else ─────────────────────
    # WITH the env→host containment tuple, the env layer resolves (mem = 1, env in the chain).
    test-env-slice-present-with-containment = {
      expr = {
        value = (rsOf envWithContain).app.value.mem;
        prov = map (e: e.rendered) (memProv envWithContain null);
      };
      expected = {
        value = 1;
        prov = [
          "default"
          "env=prod"
        ];
      };
    };
    # WITHOUT it, the SAME env layer is INERT — the env slice is not in the cell's chain, so the value
    # stays the default and the provenance never mentions env (the chain extension is the ONLY surface).
    test-env-slice-absent-without-containment = {
      expr = {
        value = (rsOf envNoContain).app.value.mem;
        prov = map (e: e.rendered) (memProv envNoContain null);
      };
      expected = {
        value = 0;
        prov = [ "default" ];
      };
    };

    # ── BINDINGS RIDE THE TUPLE: the containment tuple's `grant` reaches the target root's ctx ────────────
    test-binding-reaches-target-root = {
      expr = (full.structural.eval.get "host:axon" "enriched-context").grant or null;
      expected = "g-prod";
    };
    # scoped to the target root only — the sibling cluster root never sees `grant`.
    test-binding-scoped-to-target = {
      expr = (full.structural.eval.get "cluster:k3s" "enriched-context") ? grant;
      expected = false;
    };

    # ── NATIVE IDENTITY: no containment tuples ⇒ containmentRelations = { } ⇒ the product chain is
    #    unchanged. The native cell resolves the default alone (no env slice, byte-identical to pre-§3c). ──
    test-native-no-env-slice = {
      expr = map (e: e.rendered) (rsOf native).app.provenance.mem;
      expected = [ "default" ];
    };
  };
}
