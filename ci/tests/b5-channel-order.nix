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
    # and it is genuinely the producer-identity order (both aspects present, deterministic pair).
    test-order-is-both-producers = {
      expr = builtins.sort (a: b: a < b) (orderOf denFwd "ssh-peers");
      expected = [
        "alpha"
        "beta"
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
