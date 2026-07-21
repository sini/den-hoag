# The STRATIFIED CLAIM NEGATION witness (§5 resolution facet / productions substrate, L4, Apt–Blair–Walker
# stratified negation). This GENERALIZES the shipped `den.derived` `negates` contract (negation-gate.nix,
# concern-derived.nix) to the off-trace claim pool. A negation is NON-MONOTONE (it EXCLUDES), so it is
# disciplined by two soundness laws:
#   (a) THROWING-GATE ROUTING — a negated predicate must be read through the THROWING gate (claim-accessor
#       `.rel.<kind>`, which NAMED-throws on out-of-scope), NEVER the silent-empty `.query` (an out-of-scope
#       read yields [ ]). A negation over a silently-empty predicate cannot distinguish "absent" from "out-of-
#       scope" — unsound. This suite proves the `.rel` gate THROWS on an out-of-scope claim (capturable).
#   (b) STRICTLY-ABOVE — a negation reads a COMPLETE predicate, so the negating production must sit STRICTLY
#       ABOVE the max claim stratum (reading it before it is fully produced is non-monotone). The P5a L2 gate
#       (`from` strictly-below) enforces this — a not-strictly-above negation is NAMED-rejected.
#
# THE LOCKDOWN witness (the design's concrete negation): only ROOT claimants survive, `@self` excluded. A
# root is realized as a predicate over the reverse-read — a claimant with NO incoming claims (its own reverse
# view is empty) is a root (the `genGraphLib.roots` framework-accessor variant is the noted follow-on). The
# negation EXCLUDES a claimant that is `@self` (a self-claim) OR is not a root. Header mirrors claim-provider.nix's.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # the lockdown fleet: `hub` is claimed by `rootapp` (a ROOT — nobody claims it), `midapp` (a NON-root — `hub`
  # claims it back), and `hub` itself (a self-claim, `@self`). The `member` leaf claim sits at `connect`
  # (strictly below `resolution`), in scope for the reverse-read; an `oosclaim` sits AT `resolution` (out of
  # scope — the throwing-gate witness). All claim data is from = ∅ EDB, so the who-claims-whom cycle
  # (midapp↔hub) is sound at the acyclic `connect` stratum (a claim cycle is NOT a stratum cycle).
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
      config.den.node.hub = { };
      config.den.node.rootapp = { };
      config.den.node.midapp = { };

      # the `member` leaf claim (emit = edges, from = ∅ EDB): rootapp + midapp + hub claim hub (hub is the
      # self-claim); hub claims midapp (so midapp has an incoming claim ⇒ midapp is NOT a root).
      config.den.productions.member = {
        stratum = "connect";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:rootapp";
            to = "node:hub";
          }
          {
            from = "node:midapp";
            to = "node:hub";
          }
          {
            from = "node:hub";
            to = "node:hub";
          }
          {
            from = "node:hub";
            to = "node:midapp";
          }
        ];
      };
      # an OUT-OF-SCOPE claim AT `resolution` (NOT strictly below the accessor's own stratum) — the throwing-gate
      # witness: `.rel.oosclaim` NAMED-throws, `.query "oosclaim"` is silently empty (the L4 routing distinction).
      config.den.productions.oosclaim = {
        stratum = "resolution";
        from = [ ];
        emit = "edges";
        mode = "all";
        readsAttrs = [ ];
        compute = _self: _id: [
          {
            from = "node:rootapp";
            to = "node:hub";
          }
        ];
      };

      # THE LOCKDOWN negation (§5, L4) — a `resolution` attr production reading the negated `member` claim via
      # the THROWING `.rel` gate at its OWN node (A9 intra-stratum). `from` names the `member` stratum (connect,
      # strictly below resolution — L2-clean, the strictly-above law). NON-MONOTONE: it EXCLUDES `@self`
      # (a self-claim) and non-roots (a claimant whose OWN reverse view is non-empty), so only root claimants survive.
      config.den.productions.lockdown = {
        stratum = "resolution";
        from = [
          {
            kind = "reverse-query";
            stratum = "connect";
          }
        ];
        emit = "attr";
        mode = "all";
        readsAttrs = [ "claim-accessor" ];
        compute =
          self: id:
          let
            # THROWING gate (.rel): the claimants of `id` under negation — an out-of-scope kind would NAMED-throw.
            claimants = (self.get id "claim-accessor").rel.member;
            # a claimant is a ROOT iff its OWN reverse view is empty (nobody claims it) — the reverse-read predicate.
            isRoot = c: ((self.get c "claim-accessor").rel.member) == [ ];
            survivors = builtins.filter (c: c != id && isRoot c) claimants;
          in
          {
            lockdown = builtins.sort builtins.lessThan survivors;
          };
      };
    }
  ];

  eval = fleet.den.structural.eval;
  handleAt = id: eval.get id "claim-accessor";
  survivorsAt = id: (eval.get id "lockdown").lockdown;

  # ── the (b) strictly-above L2 gate (value-split: the NAMED message TEXT is CI-testable) over a synthetic negation ──
  msgOf =
    prod:
    denHoag.internal.productions.productionMessage {
      strataOrder = [
        "structural"
        "connect"
        "secret"
        "database"
        "route"
        "resolution"
      ];
      disciplineNames = [ ];
    } { p = prod; };
  baseNeg = {
    emit = "attr";
    mode = "all";
    readsAttrs = [ "claim-accessor" ];
    compute = _self: _id: { };
  };
  # a negation STRICTLY ABOVE the negated `member` claim (resolution > connect) — L2-clean.
  aboveNeg = baseNeg // {
    stratum = "resolution";
    from = [
      {
        kind = "reverse-query";
        stratum = "connect";
      }
    ];
  };
  # a negation NOT strictly above — reading `member` from AT the `member` stratum (connect), non-monotone. NAMED.
  notAboveNeg = baseNeg // {
    stratum = "connect";
    from = [
      {
        kind = "reverse-query";
        stratum = "connect";
      }
    ];
  };
in
{
  flake.tests.claim-negation = {
    # ── (1) the lockdown negation EXCLUDES correctly (only root claimants survive) — RESOLVED via eval.get ──
    # hub is claimed by rootapp (root), midapp (non-root), hub (@self) — only rootapp survives the lockdown.
    test-lockdown-survivors = {
      expr = survivorsAt "node:hub";
      expected = [ "node:rootapp" ];
    };
    # @self (the self-claim) is EXCLUDED — hub is not in its own lockdown survivors.
    test-lockdown-excludes-self = {
      expr = builtins.elem "node:hub" (survivorsAt "node:hub");
      expected = false;
    };
    # a NON-root claimant (midapp — claimed back by hub) is EXCLUDED (the negation is non-monotone).
    test-lockdown-excludes-nonroot = {
      expr = builtins.elem "node:midapp" (survivorsAt "node:hub");
      expected = false;
    };

    # ── (2) (a) throwing-gate routing: the negation reads via `.rel` (THROWING), proven by an out-of-scope throw ──
    # an out-of-scope `.rel` read NAMED-throws (a capturable tryEval failure) — the gate a negation consumes to
    # distinguish out-of-scope from absent. The silent `.query` on the SAME kind is empty (the routing distinction).
    test-negation-rel-oos-throws = {
      expr = throws (handleAt "node:hub").rel.oosclaim;
      expected = true;
    };
    test-negation-query-oos-silent = {
      expr = (handleAt "node:hub").query "oosclaim";
      expected = [ ];
    };
    # the IN-SCOPE `.rel` read the lockdown negation actually uses resolves (member is strictly below resolution).
    test-negation-rel-inscope-resolves = {
      expr = builtins.sort builtins.lessThan (handleAt "node:hub").rel.member;
      expected = [
        "node:hub"
        "node:midapp"
        "node:rootapp"
      ];
    };

    # ── (3) (b) strictly-above: a NOT-strictly-above negation is NAMED-rejected (L2/L4 fires) ──
    test-negation-not-above-rejected = {
      expr = builtins.match ".*not strictly below.*" (msgOf notAboveNeg) != null;
      expected = true;
    };
    # …and a strictly-above negation is L2-clean (the false-reject guard).
    test-negation-above-clean = {
      expr = msgOf aboveNeg;
      expected = null;
    };
  };
}
