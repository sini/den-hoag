# Context supportedness — Apt, Blair & Walker (1988), "Towards a Theory of Declarative Knowledge":
# supportedness (printed p. 95) and Theorem 7 (printed p. 111). The enrichment fixpoint (attribute 2
# of lib/attributes/structural.nix) publishes its delta by RE-DISPATCHING at the converged context. A
# policy whose guard reads the ABSENCE of a context key another policy writes fires during the
# iteration and is INERT in that final dispatch, so its key is produced and then dropped: the
# published context would carry a fact whose sole justification is not in it. A minimal supported
# model is a FIXED POINT of the immediate-consequence operator (printed p. 100), so the law is
# `published == converged` — a fleet that violates it has no supported model to publish (ABW
# "Stratified Programs", Definition 3, p. 96; Lemma 1 forbids a cycle THROUGH a negative edge) and is
# rejected, naming the key and the policy.
#
# Driven through the USER surface (`den.policies` via `mkDen`) rather than `denHoag.internal`, and
# read back BOTH at the enriched context and through the REAL nixpkgs crossing — the unsupported fact
# was measured landing in a materialized NixOS option value, not merely in an internal attribute.
#
# The abort idiom is `(builtins.tryEval …).success == false` (as at b1-single-writer.nix:141):
# `errors.fail` is a plain `throw` (lib/errors.nix:5), hence catchable. The asserter has no
# message-text channel (no `expectedError` — compat-nested-class-named-aspect.nix:209), so WHICH
# guard aborted is pinned DIFFERENTIALLY instead: `test-value-drift-aborts` is a fixture on which
# nothing else in the pipeline aborts (without this law it publishes a value), and
# `test-two-writers-still-abort-on-b1` pins that the pre-existing single-writer collision, forced
# first, keeps precedence.
{
  denHoag,
  nixpkgs,
  ...
}:
let
  d = denHoag.declare;

  # ── the one-node fleet: schema, one instance, the policies under test ────────────────────────────
  mk =
    policies:
    denHoag.mkDen [
      {
        config.den.schema.node.parent = null;
        config.den.node.h = { };
        config.den.policies = policies;
      }
    ];
  ctxOf = policies: (mk policies).den.structural.eval.get "node:h" "enriched-context";
  keys = policies: builtins.attrNames (ctxOf policies);
  # the enriched keys' VALUES, dropping `__entry`/`node` (which carry the whole node record).
  vals =
    policies:
    builtins.removeAttrs (ctxOf policies) [
      "__entry"
      "node"
    ];
  aborts = x: !(builtins.tryEval (builtins.deepSeq x x)).success;

  # ── the vocabulary of edges ──────────────────────────────────────────────────────────────────────
  # Every enrich VALUE is written total over den-hoag's value-less stratum probe (whose sentinel
  # values are attrsets), so these fixtures measure the supportedness law and not that constraint.
  #
  # a --NEGATIVE--> b (fires iff `b` is absent), b --POSITIVE--> a: the cycle through a negative edge.
  negA =
    ctx:
    if ctx ? b then
      [ ]
    else
      [
        (d.enrich {
          key = "a";
          value = 1;
        })
      ];
  posB = { a, ... }: [
    (d.enrich {
      key = "b";
      value = "from-a=${builtins.toJSON a}";
    })
  ];
  # self-referential NEGATIVE: one policy firing iff its own key is absent.
  selfNeg =
    ctx:
    if ctx ? r then
      [ ]
    else
      [
        (d.enrich {
          key = "r";
          value = "R";
        })
      ];
  # a positive chain that only closes across iterations of the fixpoint.
  seedS = _: [
    (d.enrich {
      key = "s";
      value = "S";
    })
  ];
  chainC = { s, ... }: [
    (d.enrich {
      key = "c";
      value = "c<${builtins.toJSON s}";
    })
  ];
  chainE = { c, ... }: [
    (d.enrich {
      key = "e";
      value = "e<${builtins.toJSON c}";
    })
  ];
  # positive-only cycle, ungrounded: `x` needs `y`, `y` needs `x`. ABW Definition 3 condition 1
  # ADMITS same-stratum positive reads, so this is legal and yields the empty model, not an abort.
  posCycX = { y, ... }: [
    (d.enrich {
      key = "x";
      value = "x<${builtins.toJSON y}";
    })
  ];
  posCycY = { x, ... }: [
    (d.enrich {
      key = "y";
      value = "y<${builtins.toJSON x}";
    })
  ];
  # defaulted formal — a negative edge that CONVERGES supported, and the shape shipped configuration
  # actually writes. It must not be caught.
  defG = _: [
    (d.enrich {
      key = "g";
      value = "G";
    })
  ];
  defH =
    {
      g ? "DEFAULT",
      ...
    }:
    [
      (d.enrich {
        key = "h";
        value = "h<${builtins.toJSON g}";
      })
    ];
  # value drift: the KEYSET stabilises while the values are still moving, so a keyset-level check
  # cannot see it and nothing else on the path aborts — without the law this publishes {x=110; y=11;}.
  driftY =
    {
      x ? 0,
      ...
    }:
    [
      (d.enrich {
        key = "y";
        value = if builtins.isInt x then x + 1 else 0;
      })
    ];
  driftX = { y, ... }: [
    (d.enrich {
      key = "x";
      value = if builtins.isInt y then y * 10 else 0;
    })
  ];
  # two writers of one key — the pre-existing B1 single-writer collision.
  w1 = _: [
    (d.enrich {
      key = "w";
      value = 1;
    })
  ];
  w2 = _: [
    (d.enrich {
      key = "w";
      value = 2;
    })
  ];

  # ── the materialization arm: the same cycle read through the REAL nixpkgs crossing ───────────────
  # `consumer` destructures the unsupported key and renders it into a NixOS option value, so forcing
  # `networking.domain` forces the crossing that was measured carrying the fact into built output.
  crossed =
    policies:
    denHoag.mkDen [
      {
        config.den.schema = {
          env.parent = null;
          host.parent = "env";
        };
      }
      {
        config.den = {
          env.prod = { };
          host.bare = { };
        };
      }
      (
        { config, ... }:
        {
          config.den.membership = [
            {
              coords = {
                env = config.den.env.prod;
                host = config.den.host.bare;
              };
            }
          ];
        }
      )
      { config.den.contentClass.host = "nixos"; }
      (
        { config, ... }:
        {
          config.den.aspects.consumer.nixos =
            { b, ... }:
            {
              networking.hostName = "bare";
              networking.domain = "SAW-${toString b}";
              nixpkgs.hostPlatform = "x86_64-linux";
            };
          config.den.include = [
            {
              at = config.den.host.bare;
              aspects = [ config.den.aspects.consumer ];
            }
          ];
        }
      )
      { config.den.policies = policies; }
      { config.den.nixpkgs = nixpkgs; }
    ];
  crossedDomain = policies: (crossed policies).nixosConfigurations.bare.config.networking.domain;
in
{
  flake.tests.b1-supportedness = {
    # ── the defects: a published context that is not the state the fixpoint reached ──────────────
    # The cycle through a negative edge. Without the law this publishes `b` while `a` — b's sole
    # justification — is absent (ABW Theorem 7, p. 111, violated).
    test-negative-cycle-aborts = {
      expr = aborts (keys {
        inherit negA posB;
      });
      expected = true;
    };

    # The one-policy variant: `r` is derivable and absent, so the published state is not even a
    # MODEL. One law catches both directions, because `published == converged` is their conjunction.
    test-self-negative-aborts = {
      expr = aborts (keys {
        inherit selfNeg;
      });
      expected = true;
    };

    # ★ POSITIVE CONTROL for the law's own reason. The keyset converges here, so no keyset-level
    # guard can fire, and on a tree without the law this fixture aborts NOWHERE — it publishes
    # {x = 110; y = 11;}. An abort on it is therefore this law's and no other's.
    test-value-drift-aborts = {
      expr = aborts (vals {
        inherit driftY driftX;
      });
      expected = true;
    };

    # ── the legal shapes, which the law must not touch (the false-positive surface) ──────────────
    # A positive chain firing across three iterations: every key and every value survives.
    test-positive-chain-unchanged = {
      expr = builtins.toJSON (vals {
        inherit seedS chainC chainE;
      });
      expected = ''{"c":"c<\"S\"","e":"e<\"c<\\\"S\\\"\"","s":"S"}'';
    };

    # ABW Definition 3 condition 1: a positive cycle is legal. It grounds nothing, so the right
    # answer is the EMPTY model — not an abort.
    test-positive-cycle-ungrounded-is-empty-not-error = {
      expr = keys { inherit posCycX posCycY; };
      expected = [
        "__entry"
        "node"
      ];
    };

    # A defaulted formal reads an absence and still converges supported; both keys publish.
    test-defaulted-formal-converges = {
      expr = builtins.toJSON (vals {
        inherit defG defH;
      });
      expected = ''{"g":"G","h":"h<\"G\""}'';
    };

    # ── precedence and totality ──────────────────────────────────────────────────────────────────
    # `owners` is forced FIRST, so a key with two writers still raises the B1 collision.
    test-two-writers-still-abort-on-b1 = {
      expr = aborts (keys {
        inherit w1 w2;
      });
      expected = true;
    };

    # Degenerate inputs are unchanged: no policies publishes exactly the node's own bindings.
    test-no-policies-total = {
      expr = keys { };
      expected = [
        "__entry"
        "node"
      ];
    };

    # A schema with no instances has no scope nodes at all, so the attribute is never computed.
    test-empty-fleet-total = {
      expr =
        builtins.attrNames
          (denHoag.mkDen [ { config.den.schema.node.parent = null; } ]).den.structural.eval.allNodes;
      expected = [ ];
    };

    # ── materialization: the fact was reaching a built NixOS option, so the law is read there too ──
    # Forcing `networking.domain` drives the real crossing. The consumer destructures `b`; with the
    # cycle in place the abort must reach the option value rather than a well-formed string.
    test-negative-cycle-aborts-at-the-crossing = {
      expr = aborts (crossedDomain {
        inherit negA posB;
      });
      expected = true;
    };

    # ★ The crossing's own control: the SAME consumer and the same fleet with `b` written by a plain
    # positive policy materializes normally, so the abort above is the cycle's and not the crossing's.
    test-crossing-materializes-supported-key = {
      expr = crossedDomain {
        plainB = _: [
          (d.enrich {
            key = "b";
            value = "ok";
          })
        ];
      };
      expected = "SAW-ok";
    };
  };
}
