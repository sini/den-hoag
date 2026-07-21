# The PROVIDER/CONSUMER witness (§5 resolution facet / productions substrate, §9 transpose reverse-read).
# T2 proved the FORWARD claim view (a source reads its egress, who-do-I-claim) is queryable over the §3 query
# spine. This suite proves the REVERSE view and the provider/consumer wiring built on it:
#   claim-accessor — the who-claims-me handle, the §9 transpose (Mokhov 2017 §4.3) of the leaf-claim forward
#     adjacency, delivered as a `resolution`-stratum `resolve.attr` (readsAttrs = [ ], a static-pool read).
#   provider — a `den.productions` attr at `resolution` reading `claim-accessor` at its OWN node (an INTRA-
#     stratum positive read, A9 — exactly the posture derived-accessor reads rel-accessor), building a
#     provider-config from the reverse claimers.
#   consumer — a `den.productions` attr at `resolution` reading the PROVIDER attr intra-stratum, building an
#     appWiring from the provider-config.
# Both are RESOLVED through `structural.eval.get id <attr>` (warm-served resolution values, never a
# materialized manifest). The handle carries the node.query (SILENT) / node.rel (THROWING) capability
# contract: a claim kind at/above the accessor's own `resolution` stratum is out of scope — `.query` yields
# `[ ]`, `.rel` NAMED-throws (the L4 throwing-gate a later negation consumes). Header mirrors claim-pool.nix's.
{
  denHoag,
  ...
}:
let
  # the provider/consumer fleet: the T2 leaf claims (connect/secret/database) BESIDE an out-of-scope claim at
  # `resolution` (the capability-boundary witness) + the provider + consumer productions. `lonely` is claimed
  # by nobody (the empty-reverse witness). The claim strata sit densely below `resolution` (structural <
  # connect < secret < database < route < resolution), so the provider at `resolution` reads them strictly
  # below (§2.3 L2) and the reverse-read is in scope for every claim kind EXCEPT the `resolution`-level one.
  fleet = denHoag.mkDen [
    {
      config.den.schema.node.parent = null;
      config.den.strata.insert = denHoag.declare.strataChain {
        after = "structural";
        chain = [
          "connect"
          "secret"
          "database"
          "route"
        ];
      };
      config.den.node.arr = { };
      config.den.node.prowlarr = { };
      config.den.node.lonely = { };

      # the connect leaf claim — the cyclic pair (arr claims prowlarr AND prowlarr claims arr), from = ∅ EDB.
      config.den.productions.connect = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:arr";
            to = "node:prowlarr";
          }
          {
            from = "node:prowlarr";
            to = "node:arr";
          }
        ];
      };
      # a secret leaf claim (edge-uniform across kinds) — in scope for the reverse-read (below resolution).
      config.den.productions.secret = {
        stratum = "secret";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:arr";
            to = "node:prowlarr";
          }
        ];
      };
      # an OUT-OF-SCOPE claim declared AT the accessor's own stratum (`resolution`) — NOT strictly below it, so
      # the reverse-read hides it via `.query` (silent) and NAMED-throws via `.rel` (the capability boundary).
      config.den.productions.oosclaim = {
        stratum = "resolution";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:arr";
            to = "node:prowlarr";
          }
        ];
      };

      # the PROVIDER (§5) — a `resolution` attr production reading `claim-accessor` at its OWN node (A9 intra-
      # stratum positive read). `from` declares the claim strata it reads (route, strictly below resolution —
      # L2-clean); it drives the L2 gate + documents the contract, it is not executed. The compute reads the
      # reverse `connect` claimers (who-claims-me) and packages them as a provider-config.
      config.den.productions.provider = {
        stratum = "resolution";
        from = [
          {
            kind = "reverse-query";
            stratum = "route";
          }
        ];
        emit = "attr";
        mode = "all";
        readsAttrs = [ "claim-accessor" ];
        compute = self: id: {
          connectClaimedBy = (self.get id "claim-accessor").query "connect";
        };
      };

      # the CONSUMER (§5) — a `resolution` attr production reading the PROVIDER attr intra-stratum (A9); it
      # reads NO claim stratum directly (from = ∅, L2-vacuous), only the provider-config, and builds an
      # appWiring value from it.
      config.den.productions.consumer = {
        stratum = "resolution";
        from = [ ];
        emit = "attr";
        mode = "all";
        readsAttrs = [ "provider" ];
        compute = self: id: {
          appWiring = map (c: "wire:${c}") (self.get id "provider").connectClaimedBy;
        };
      };
    }
  ];

  eval = fleet.den.structural.eval;
  # the claim-accessor handle read DIRECTLY (warm-served — the schedule includes it, provider references it),
  # for the silent/throwing capability witnesses.
  handleAt = id: eval.get id "claim-accessor";

  # the L2 gate over a synthetic provider (value-split: the NAMED message TEXT is CI-testable — tryEval cannot
  # capture a throw's text), on a two-stratum order. structural < resolution, so a from-source at `structural`
  # is strictly below (clean) and one at `resolution` is NOT (rejected).
  msgOf =
    prod:
    denHoag.internal.productions.productionMessage {
      strataOrder = [
        "structural"
        "resolution"
      ];
      disciplineNames = [ ];
    } { p = prod; };
  baseProvider = {
    stratum = "resolution";
    emit = "attr";
    mode = "all";
    readsAttrs = [ "claim-accessor" ];
    compute = _self: _id: { };
  };
  # a provider whose `from` reads a claim stratum NOT strictly below its own — the L2 rejection.
  badProvider = baseProvider // {
    from = [
      {
        kind = "reverse-query";
        stratum = "resolution";
      }
    ];
  };
  # a provider whose `from` reads a claim stratum strictly below its own — L2-clean.
  goodProvider = baseProvider // {
    from = [
      {
        kind = "reverse-query";
        stratum = "structural";
      }
    ];
  };
in
{
  flake.tests.claim-provider = {
    # ── the reverse-read: who-claims-me via the §9 transpose ──
    # a node CLAIMED by others sees them in its reverse view (connect: arr→prowlarr, so arr claims prowlarr).
    test-provider-reverse-claimed = {
      expr = eval.get "node:prowlarr" "provider";
      expected = {
        connectClaimedBy = [ "node:arr" ];
      };
    };
    # the cyclic other endpoint: prowlarr→arr, so prowlarr claims arr.
    test-provider-reverse-claimed-other = {
      expr = eval.get "node:arr" "provider";
      expected = {
        connectClaimedBy = [ "node:prowlarr" ];
      };
    };
    # a node claimed by NOBODY sees an EMPTY reverse view via `.query` (the silent posture) — never an attr-miss.
    test-provider-reverse-unclaimed-empty = {
      expr = eval.get "node:lonely" "provider";
      expected = {
        connectClaimedBy = [ ];
      };
    };

    # ── the consumer reads the provider-config intra-stratum → the appWiring ──
    test-consumer-appwiring = {
      expr = eval.get "node:prowlarr" "consumer";
      expected = {
        appWiring = [ "wire:node:arr" ];
      };
    };
    test-consumer-appwiring-unclaimed-empty = {
      expr = eval.get "node:lonely" "consumer";
      expected = {
        appWiring = [ ];
      };
    };

    # ── the node.query SILENT / node.rel THROWING capability contract over the claim-accessor handle ──
    # an IN-SCOPE claim kind reads through BOTH variants identically (connect is below resolution).
    test-handle-inscope-query = {
      expr = (handleAt "node:prowlarr").query "connect";
      expected = [ "node:arr" ];
    };
    test-handle-inscope-rel = {
      expr = (handleAt "node:prowlarr").rel.connect;
      expected = [ "node:arr" ];
    };
    # an OUT-OF-SCOPE claim kind (at the accessor's own `resolution` stratum) is SILENTLY empty via `.query`.
    test-handle-oos-query-silent = {
      expr = (handleAt "node:prowlarr").query "oosclaim";
      expected = [ ];
    };
    # a MISSING claim kind (never declared) is ALSO silently empty via `.query` (the exploratory-query mode).
    test-handle-missing-query-silent = {
      expr = (handleAt "node:prowlarr").query "nosuchkind";
      expected = [ ];
    };
    # the THROWING variant NAMED-throws on the SAME out-of-scope read — a capturable tryEval failure (the L4
    # throwing-gate a stratified negation consumes: it cannot mistake out-of-scope for absent).
    test-handle-oos-rel-throws = {
      expr = (builtins.tryEval (builtins.deepSeq (handleAt "node:prowlarr").rel.oosclaim null)).success;
      expected = false;
    };

    # ── the P5a L2 gate strictly-below the reverse-read (reused, value-split so the message is testable) ──
    # a provider whose `from` names a claim stratum NOT strictly below its own is a NAMED rejection.
    test-provider-l2-rejects-not-below = {
      expr = builtins.match ".*not strictly below.*" (msgOf badProvider) != null;
      expected = true;
    };
    # a provider whose `from` names a claim stratum strictly below its own is L2-clean (the false-reject guard).
    test-provider-l2-clean-below = {
      expr = msgOf goodProvider;
      expected = null;
    };
  };
}
