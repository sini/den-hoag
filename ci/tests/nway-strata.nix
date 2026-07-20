# PHASE-2 N-way strata witness (Productions-substrate §11 Phase 2). den compiles an N-way stratum order
# (den.strata.insert over the seed [structural resolution collection demand]) and now threads it into
# gen-resolve's resolve as `strataOrder`, so the schedule's partition assert is N-way (not the shipped
# 2-way structural<resolution). This suite proves: (1) the compiled order flows into structural.schedule
# without a false violation; (2) strataChain maps a claim-kind precedence onto a dense insert chain (the
# N-way ENGINE acceptance of such an order is proven generically in gen-resolve's schedule tests, Task 1).
# Header is exactly resolution-refound.nix's — ci specialArgs provides `denHoag` (NOT `resolve`; gen-resolve.lib
# is not injected, so a `resolve` formal would eval-error the whole suite). See REFERENCE.md / spec §11.
{
  denHoag,
  ...
}:
let
  fleet = denHoag.mkDen [
    {
      config.den.schema.node.parent = null;
      config.den.strata.insert.closure = {
        after = "resolution";
      };
      config.den.node.a = { };
    }
  ];
  # the claim-kind precedence (spec §B2 / resume): route > database > secret > connect. In strictly-below
  # (compute-order) terms the LEAST-precedence claim resolves first, so the base-ward chain is the reverse.
  claimChain = denHoag.declare.strataChain {
    after = "resolution";
    chain = [
      "connect"
      "secret"
      "database"
      "route"
    ];
  };
  claimOrder = denHoag.declare.compileStrata { inserts = claimChain; };
in
{
  flake.tests.nway-strata = {
    # no-throw smoke: forcing the schedule computes the partition under the threaded 6-way order without a
    # false violation (the N-way DISCRIMINATION lives in gen-resolve's own schedule tests + test-compiled-order-nway;
    # this pins that den's real equation set schedules cleanly against compiledStrata). The `? "rel-accessor"`
    # probe is incidental — any forced attr witnesses the same no-throw.
    test-schedule-carries-nway-order = {
      expr = fleet.den.structural.schedule.equations ? "rel-accessor";
      expected = true;
    };
    # the order is the seeded four + the user insert (dense after resolution) + the framework `output` insert.
    test-compiled-order-nway = {
      expr = fleet.den.strata;
      expected = [
        "structural"
        "resolution"
        "closure"
        "collection"
        "demand"
        "output"
      ];
    };
    # B2: the precedence chain desugars to dense after-links.
    test-strata-chain-desugar = {
      expr = claimChain;
      expected = {
        connect.after = "resolution";
        secret.after = "connect";
        database.after = "secret";
        route.after = "database";
      };
    };
    # B2: compiled order places the chain strictly-below-ascending between resolution and collection —
    # so a `route` production reads database/secret/connect (all strictly-below); the N-way engine
    # (Task 1) accepts exactly that direction and rejects the reverse. NB: `declare.compileStrata` is the
    # RAW seed [structural resolution collection demand] + the claimChain inserts ONLY — it does NOT apply
    # the framework `output` insert (that merges only at default.nix's fleet-level compiledStrata). So NO
    # trailing "output" here (unlike fleet.den.strata in test-compiled-order-nway).
    test-claim-order-compiled = {
      expr = claimOrder;
      expected = [
        "structural"
        "resolution"
        "connect"
        "secret"
        "database"
        "route"
        "collection"
        "demand"
      ];
    };
  };
}
