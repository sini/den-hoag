# Task 5 — same-position multi-producer order (Law A12) + declared dedup (B5). Two aspects emit to
# the same channel at the same scope; den pins their residual order by PRODUCER IDENTITY, not by the
# order the aspects/includes were declared in. Over a host that produces the nixos class:
#
#   producer-identity order — two aspects at one position order by producer identity; the order is
#     BYTE-IDENTICAL when the include list (and thus resolved-aspects order) is permuted — the A12
#     tie-break, not declaration order or attrset iteration.
#   declared dedup applies, undeclared never — a channel with an identity dedup policy collapses the
#     two same-position producers (same entity+scope identity) to one; a channel with no dedup keeps
#     both, in pinned order.
{ denHoag, ... }:
let
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
      ];
    };
  classing.config.den.contentClass.host = "nixos";
  # two channels: one plain (keeps duplicates), one with an identity dedup policy.
  quirks.config.den.quirks = {
    ssh-peers = { };
    deduped.channel.dedup = {
      key = "identity";
      keep = "first";
    };
  };
  base = [
    schema
    instances
    membership
    classing
    quirks
  ];

  axonId = "host:axon";

  # two aspects, each emitting to BOTH channels, included together at the host. `includeOrder`
  # controls the include-list order (⇒ the resolved-aspects order) so we can permute it.
  fleetWith =
    includeOrder:
    { config, ... }:
    {
      config.den.aspects = {
        alpha = {
          ssh-peers = [ "a" ];
          deduped = [ "a" ];
        };
        beta = {
          ssh-peers = [ "b" ];
          deduped = [ "b" ];
        };
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = includeOrder config;
        }
      ];
    };
  denFwd =
    (denHoag.mkDen (
      base
      ++ [
        (fleetWith (config: [
          config.den.aspects.alpha
          config.den.aspects.beta
        ]))
      ]
    )).den;
  denRev =
    (denHoag.mkDen (
      base
      ++ [
        (fleetWith (config: [
          config.den.aspects.beta
          config.den.aspects.alpha
        ]))
      ]
    )).den;

  # the producer (aspect) order of a channel's received contributions at the host.
  orderOf =
    den: chName:
    map (c: c.producer.aspect.name or null) (
      (den.structural.eval.get axonId "received-collections").${chName}.contributions
    );
  countOf =
    den: chName:
    builtins.length (den.structural.eval.get axonId "received-collections").${chName}.contributions;

  # ── neron ORDER pin (B5: self → imports → parent) ──────────────────────────────────────────────
  # A cell that IMPORTS one host (host:blade, via a `link`) while another is its P-parent (host:axon),
  # both contributing to the channel: the received order must be imports-before-parent, not just the
  # parent. `linkBlade` fires only where a `user` binding is present (the cell), so only the cell
  # imports blade; host:axon stays the cell's parent.
  neronBase = [
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
        host.blade = { };
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
        ];
      }
    )
    { config.den.contentClass.host = "nixos"; }
    { config.den.quirks.ssh-peers = { }; }
  ];
  neronMod =
    { config, ... }:
    {
      config.den.aspects = {
        parentA.ssh-peers = [ "parent" ];
        importA.ssh-peers = [ "import" ];
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.parentA ];
        }
        {
          at = config.den.host.blade;
          aspects = [ config.den.aspects.importA ];
        }
      ];
      config.den.policies.linkBlade = { user, ... }: [
        (denHoag.declare.link { target = config.den.host.blade; })
      ];
    };
  denNeron = (denHoag.mkDen (neronBase ++ [ neronMod ])).den;
  neronOrder = map (c: c.value) (
    (denNeron.structural.eval.get "user:alice@host:axon" "received-collections").ssh-peers.contributions
  );
in
{
  flake.tests.b5-channel-order = {
    # ── A12 producer-identity order ──
    # both producers land at the position, so the plain channel carries two contributions.
    test-two-producers-present = {
      expr = countOf denFwd "ssh-peers";
      expected = 2;
    };
    # the order is BYTE-IDENTICAL under include-list permutation — pinned by producer identity, not
    # by the order the aspects were included (which differs between denFwd and denRev).
    test-order-byte-identical-under-permutation = {
      expr = orderOf denFwd "ssh-peers" == orderOf denRev "ssh-peers";
      expected = true;
    };
    # the canonical winner is literally [alpha, beta] (self-documenting complement to the equality
    # above): producer identity — alpha's key sorts before beta's — decides, not include order.
    test-order-canonical-winner = {
      expr = orderOf denFwd "ssh-peers";
      expected = [
        "alpha"
        "beta"
      ];
    };

    # ── neron ORDER: self → imports → parent (B5) ──
    # the cell receives the IMPORTED host's contribution before its PARENT host's — imports precede
    # parent in the pinned traversal, not merely parent-only.
    test-neron-imports-before-parent = {
      expr = neronOrder;
      expected = [
        [ "import" ]
        [ "parent" ]
      ];
    };

    # ── declared dedup applies, undeclared never (B5) ──
    # the dedup channel collapses the two same-identity producers to one…
    test-declared-dedup-collapses = {
      expr = countOf denFwd "deduped";
      expected = 1;
    };
    # …while the un-deduped channel keeps both. Same producers, different discipline — never silent.
    test-undeclared-dedup-keeps-both = {
      expr = countOf denFwd "ssh-peers";
      expected = 2;
    };
    # the dedup outcome is itself permutation-stable (keep = "first" over the pinned order).
    test-dedup-permutation-stable = {
      expr = countOf denFwd "deduped" == countOf denRev "deduped";
      expected = true;
    };
  };
}
