# A7 — the linearization declaration surface (§2.7). `den.linearization.dims` (KIND entries) render
# to product dim-name strings and feed `gen-product.linearizeByDimOrder`; the derived SLICE order is
# `default < env < host < user < env∧host < env∧user < host∧user < cell` (default/policy sentinels
# bracket the chain and are not chain members); totality holds over any dim set; a missing, duplicate,
# or non-entry (identity law) dim is a named definition-time error.
{ denHoag, ... }:
let
  linLib = denHoag.internal.linearizationLib;
  product = denHoag.internal.product;

  # Kind-entry stand-ins: identity law only requires a `kind` field (the product dimension name).
  k = name: { kind = name; };
  dims3 = [
    (k "env")
    (k "host")
    (k "user")
  ];
  productDims = [
    "env"
    "host"
    "user"
  ];

  linOf =
    dims:
    builtins.tryEval (
      let
        r = linLib.linearization { inherit dims productDims; };
      in
      builtins.seq r.kind r
    );

  # ── golden slice order over a real fleet ────────────────────────────────────────────────────────
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
      user.alice = { };
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
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
  base = [
    schema
    instances
    membership
  ];

  den = (denHoag.mkDen base).den;
  cell = builtins.head den.cells;
  sliceDimsOf =
    d:
    let
      lin = linLib.linearization {
        dims = map k d;
        inherit productDims;
      };
    in
    map (e: builtins.attrNames e.fixed) (product.containmentChain den.fleet cell lin);

  defaultOrder = sliceDimsOf [
    "env"
    "host"
    "user"
  ];
  reversedOrder = sliceDimsOf [
    "user"
    "host"
    "env"
  ];
  uniqueList = xs: builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ] xs;
in
{
  flake.tests.linearization = {
    # ── the wrapper feeds gen-product with rendered NAMES (identity law: entries never cross) ──
    test-renders-to-dim-order = {
      expr = (linOf dims3).value.kind;
      expected = "dimOrder";
    };
    test-rendered-names = {
      expr = (linOf dims3).value.dims;
      expected = [
        "env"
        "host"
        "user"
      ];
    };

    # ── A7 golden: the derived slice order for the default dims ──
    test-slice-order-golden = {
      expr = defaultOrder;
      expected = [
        [ ]
        [ "env" ]
        [ "host" ]
        [ "user" ]
        [
          "env"
          "host"
        ]
        [
          "env"
          "user"
        ]
        [
          "host"
          "user"
        ]
        [
          "env"
          "host"
          "user"
        ]
      ];
    };

    # ── totality: any dim order yields a total order — 2^3 distinct slices, size non-decreasing ──
    test-totality-default-count = {
      expr = builtins.length defaultOrder;
      expected = 8;
    };
    test-totality-reversed-count = {
      expr = builtins.length reversedOrder;
      expected = 8;
    };
    test-totality-reversed-distinct = {
      expr = builtins.length (uniqueList reversedOrder);
      expected = 8;
    };
    # under a reversed dim order the fewer-fixed-dims slices still precede the more-fixed ones
    # (count-major key): first is the whole product (∅), last is the full cell.
    test-reversed-least-first = {
      expr = builtins.head reversedOrder;
      expected = [ ];
    };
    test-reversed-most-last = {
      expr = builtins.elemAt reversedOrder 7;
      expected = [
        "env"
        "host"
        "user"
      ];
    };

    # ── named definition-time errors ──
    test-missing-dim-aborts = {
      expr =
        (linOf [
          (k "env")
          (k "host")
        ]).success; # omits user
      expected = false;
    };
    test-duplicate-dim-aborts = {
      expr =
        (linOf [
          (k "env")
          (k "host")
          (k "host")
        ]).success;
      expected = false;
    };
    test-string-dim-aborts = {
      expr =
        (builtins.tryEval (
          let
            r = linLib.linearization {
              dims = [
                (k "env")
                "host"
                (k "user")
              ];
              inherit productDims;
            };
          in
          builtins.seq r.kind r
        )).success;
      expected = false;
    };
  };
}
