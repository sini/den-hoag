# Task 1 — entity registries + fleet restricted product (Laws A5, partial A6).
# A6 coherence (P-chain == containmentChain tree-restriction) needs buildRoots and is
# added here in Task 2; this file asserts the A5 parts fully now.
{ denHoag, ... }:
let
  fx = import ./_fixtures/fleet.nix;
  sel = denHoag.sel;

  den = (denHoag.mkDen fx.base).den;
  denDup = (denHoag.mkDen fx.dup).den;
  denBad = (denHoag.mkDen fx.bad).den;

  # (a) sel.kind consumes den.schema.<kind> and matches every instance of the kind.
  userReg = den.registries.user;
  userCtx = sel.adapters.registry.mkContext {
    nodes = builtins.attrNames userReg;
    data = id: userReg.${id};
    parent = _: null;
    kind = den.schema.user;
  };
  userMatches = map (id: sel.matches (sel.kind den.schema.user) id userCtx) (
    builtins.attrNames userReg
  );

  # (b)/(c) cells reflect membership; render each cell's coords to instance names.
  cellNames = map (c: builtins.mapAttrs (_: e: e.name) c) den.cells;
  aliceCells = builtins.filter (c: (c.user or null) == "alice") cellNames;
  bobCells = builtins.filter (c: (c.user or null) == "bob") cellNames;
in
{
  flake.tests.entity-fleet = {
    # (a) — AC1: den.schema.<kind> is a gen-schema kind value usable by sel.kind.
    test-kind-value-shape = {
      expr = (den.schema.user ? kind) && (den.schema.user ? options);
      expected = true;
    };
    test-sel-kind-matches-all-instances = {
      expr = userMatches;
      expected = [
        true
        true
      ];
    };

    # (b) — AC2: a user with a membership tuple yields a cell; one without yields none.
    test-single-cell = {
      expr = builtins.length den.cells;
      expected = 1;
    };
    test-member-yields-cell = {
      expr = builtins.length aliceCells;
      expected = 1;
    };
    test-nonmember-no-cell = {
      expr = builtins.length bobCells;
      expected = 0;
    };
    test-cell-coords = {
      expr = builtins.head cellNames;
      expected = {
        env = "prod";
        host = "axon";
        user = "alice";
      };
    };

    # (c) — AC2: duplicate membership tuples are idempotent (relation, not collection).
    test-duplicate-tuple-idempotent = {
      expr = builtins.length denDup.cells;
      expected = 1;
    };

    # (d) — AC3: `member` at a membership-derived scope aborts at definition time.
    test-member-at-cell-aborts = {
      expr = (builtins.tryEval (builtins.length denBad.cells)).success;
      expected = false;
    };
  };
}
