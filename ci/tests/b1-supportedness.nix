# Context supportedness — Apt, Blair & Walker (1988), "Towards a Theory of Declarative Knowledge":
# supportedness (printed p. 95) and Theorem 7 (printed p. 111). The enrichment fixpoint (attribute 2
# of lib/attributes/structural.nix) publishes its delta by RE-DISPATCHING at the converged context. A
# policy whose guard reads the ABSENCE of a context key another policy writes fires during the
# iteration and is INERT in that final dispatch, so its key is produced and then dropped: the
# published context would carry a fact whose sole justification is not in it. A minimal supported
# model is a FIXED POINT of the immediate-consequence operator (printed p. 100), so the law is that
# the published context and the state the fixpoint reached AGREE, key by key — a fleet that violates
# it has no supported model to publish (ABW "Stratified Programs", Definition 3, p. 96; Lemma 1
# forbids a cycle THROUGH a negative edge) and is rejected, naming the keys and their policies.
#
# The agreement is decided on a comparison-total projection, because Nix's `==` is FALSE for any two
# distinct closures and the two sides come from two different dispatches. The projection compares
# every value Nix can compare and identifies functions that share a formals set; the fixtures below
# pin both what it judges and what it does not (lib/attributes/structural.nix, `project`/`agree`).
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
  # ── values Nix cannot compare ────────────────────────────────────────────────────────────────────
  # `d.enrich`'s value carries no type constraint, and a deferred module is the obvious thing to
  # enrich with. Nix's `==` is FALSE for any two distinct closures, so the two `enrichAt` calls the
  # law compares can never agree on a lambda by `==` alone — the law compares them on the
  # comparison-total projection instead (lib/attributes/structural.nix, `agree`). Every other fixture
  # in this file is a scalar or a string, which is why a `==`-only law measured green here.
  fnPol = _: [
    (d.enrich {
      key = "fn";
      value = (x: x + 1);
    })
  ];
  modPol = _: [
    (d.enrich {
      key = "m";
      value = {
        mod = { pkgs, ... }: { drv = pkgs; };
        n = 5;
      };
    })
  ];
  listPol = _: [
    (d.enrich {
      key = "l";
      value = [
        1
        (x: x)
      ];
    })
  ];
  # value drift INSIDE a function-carrying attrset: `box.n` moves while `box.mod` is a lambda in both
  # states. The projection must compare the comparable FIELDS of a value it cannot compare whole.
  boxN =
    {
      k ? 0,
      ...
    }:
    [
      (d.enrich {
        key = "box";
        value = {
          mod = { pkgs, ... }: { };
          n = if builtins.isInt k then k + 1 else 0;
        };
      })
    ];
  boxK =
    {
      box ? null,
      ...
    }:
    [
      (d.enrich {
        key = "k";
        value = if box ? n && builtins.isInt box.n then box.n * 10 else 0;
      })
    ];
  # FORMALS drift: the only lambda difference Nix exposes. Alternating on its own formals is the one
  # shape that keeps a function moving past keyset stabilisation — a PRESENCE-driven branch settles
  # within the fixpoint's own trailing step, and a VALUE-driven one needs a comparable co-key that
  # would itself drift.
  altFormals = ctx: [
    (d.enrich {
      key = "af";
      value =
        if !(ctx ? af && builtins.isFunction ctx.af) then
          ({ a, ... }: 1)
        else if builtins.functionArgs ctx.af ? a then
          ({ b, ... }: 2)
        else
          ({ a, ... }: 1);
    })
  ];
  # ★ THE STATED LIMIT of the law, as a fixture. Each dispatch wraps the previous context's function,
  # so the published closure answers one higher than the one the fixpoint's state carried — and the
  # two are indistinguishable, because a Nix closure exposes nothing below its formals.
  growFn = ctx: [
    (d.enrich {
      key = "gf";
      value = (_: 1 + (if ctx ? gf && builtins.isFunction ctx.gf then ctx.gf 0 else 0));
    })
  ];
  # ── a rule that fires only at the CONVERGED context ──────────────────────────────────────────────
  # `stepA` saturates: 0 -> 1 -> 2 -> 2. Its keyset stabilises one step BEFORE its value does, and
  # gen-scope's `circular` converges on the keyset, so `n` reaches 2 only in the returned iterate.
  # `lateN` is inert at every iterate and fires at that returned one, contributing a key the fixpoint's
  # state never carried. Both are total over the value-less stratum probe's attrset sentinels: `stepA`
  # emits its declaration on the non-int branch, and `lateN` emits on the branch a sentinel takes, so
  # neither is a value-less probe (which the per-declaration-stratum guard rejects outright).
  stepA =
    {
      n ? 0,
      ...
    }:
    [
      (d.enrich {
        key = "n";
        value =
          if !(builtins.isInt n) then
            1
          else if n < 2 then
            n + 1
          else
            n;
      })
    ];
  lateN =
    { n, ... }:
    if builtins.isInt n && n < 2 then
      [ ]
    else
      [
        (d.enrich {
          key = "z";
          value = "Z";
        })
      ];
  # ── an INHERITED key overwritten during iteration and inert at convergence ───────────────────────
  # The `dropped` shape over a key the node already carries. Because the published context still HAS
  # the key — `base`'s own value — no keyset arm can see it, and it is the one disagreement the law's
  # touched-key restriction does not reach; `untouchedAgree` is what catches it and widens the scan so
  # the key is named. `shadowNode` reads the ABSENCE of `flag`, so it fires once and is then inert.
  shadowNode =
    ctx:
    if ctx ? flag then
      [ ]
    else
      [
        (d.enrich {
          key = "node";
          value = "OVERWRITTEN";
        })
      ];
  flagPol = _: [
    (d.enrich {
      key = "flag";
      value = true;
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

    # ── values Nix cannot compare, which the law must still admit ────────────────────────────────
    # A bare lambda. The law forces `enrichments` before any key is readable, so a `==`-based law
    # aborts here on a fleet with ONE policy, no negation and no cycle; the published closure must
    # instead arrive intact and apply.
    test-function-value-enriches-and-applies = {
      expr = (ctxOf { inherit fnPol; }).fn 41;
      expected = 42;
    };

    test-function-value-publishes-its-key = {
      expr = keys { inherit fnPol; };
      expected = [
        "__entry"
        "fn"
        "node"
      ];
    };

    # A lambda nested inside an attrset — the deferred-module shape. Both the comparable field and
    # the module survive.
    test-nested-function-in-an-attrset-enriches = {
      expr =
        let
          m = (ctxOf { inherit modPol; }).m;
        in
        [
          m.n
          (m.mod { pkgs = "P"; }).drv
        ];
      expected = [
        5
        "P"
      ];
    };

    # A lambda nested inside a list — the projection's list arm.
    test-function-inside-a-list-enriches = {
      expr =
        let
          l = (ctxOf { inherit listPol; }).l;
        in
        [
          (builtins.head l)
          ((builtins.elemAt l 1) 7)
        ];
      expected = [
        1
        7
      ];
    };

    # ── the law is not vacuous on values that contain a function ─────────────────────────────────
    # ★ Drift beside a function value: the drift pair still aborts with an incomparable value in the
    # same context, so admitting the lambda did not disable the law for the rest of the context.
    test-drift-beside-a-function-value-still-aborts = {
      expr = aborts (vals {
        inherit driftY driftX fnPol;
      });
      expected = true;
    };

    # ★ Drift INSIDE the function-carrying value itself — the sharp one. `box.n` is the only
    # disagreement, so a projection that excused the whole value for containing a lambda would
    # publish it. Its differential is `test-nested-function-in-an-attrset-enriches` above: the same
    # value SHAPE with no drift evaluates clean, so this abort is `box.n`'s and not the lambda's.
    test-drift-inside-a-function-carrying-attrset-aborts = {
      expr = aborts (vals {
        inherit boxN boxK;
      });
      expected = true;
    };

    # Formals are the one lambda difference Nix exposes, and the projection keeps them: a policy
    # re-deriving a lambda of a DIFFERENT shape is a disagreement and is caught. Differential:
    # `test-function-value-enriches-and-applies`, where a lambda alone converges clean.
    test-function-formals-drift-aborts = {
      expr = aborts (keys {
        inherit altFormals;
      });
      expected = true;
    };

    # ★ THE STATED LIMIT, asserted so it cannot drift unnoticed. `growFn` publishes a closure
    # answering 3 while the state the fixpoint reached carried one answering 2 — an unsupported fact,
    # invisible because the two lambdas share their (empty) formals. Nothing in Nix can tell them
    # apart; this fixture records that, and fails the day something can.
    test-limit-of-the-law-a-lambda-body-is-not-compared = {
      expr = (ctxOf { inherit growFn; }).gf 0;
      expected = 3;
    };

    # ── the third disagreement arm: derived at the converged context, never in it ─────────────────
    # `lateN` fires only at the iterate `circular` returns, so `z` is published while the fixpoint's
    # state never carried it — the interpretation is not closed under T_P (ABW p. 100). Neither
    # `dropped` nor `drifted` covers it; without the `unclosed` arm the law still aborts but the
    # message names nothing at all. The asserter has no message-text channel, so what this pins is
    # that the arm ABORTS: a law checking only dropped ∪ drifted publishes this fleet.
    test-rule-firing-only-at-the-converged-context-aborts = {
      expr = aborts (keys {
        inherit stepA lateN;
      });
      expected = true;
    };

    # Its differential: `stepA` alone saturates and converges supported, so the abort above is
    # `lateN`'s contribution and not the saturating step's.
    test-saturating-step-alone-converges = {
      expr = builtins.toJSON (vals {
        inherit stepA;
      });
      expected = ''{"n":2}'';
    };

    # ★ The same defect over an INHERITED key, which no keyset arm can see: `node` is published with
    # the value it always had while the fixpoint's state carries the overwrite. This is the shape the
    # touched-key restriction excludes, so it is `untouchedAgree`'s own witness — that branch is
    # otherwise unexercised. Its differential is `test-no-policies-total`: the same node with no
    # policies publishes its bindings unchanged, so this abort is the overwrite's.
    test-inherited-key-overwritten-then-dropped-aborts = {
      expr = aborts (keys {
        inherit shadowNode flagPol;
      });
      expected = true;
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
