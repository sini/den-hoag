# SUITE COMPLETENESS — the guard for the tests that are not there.
#
# nix-unit detects tests by a `test` NAME-PREFIX and reports a target with no matching bindings as
# `0/0 successful`, EXIT 0. So the failure this guard exists to catch is invisible to every instrument
# that reads failures: a suite whose last test is parked stops being coverage and starts being a green
# no-op, and nothing in the run says so. The same prefix rule silently drops a mis-named leaf, and a
# nested group is invisible to the harness.
#
# A TOTAL-COUNT ASSERTION OVER TESTS IS REJECTED. It is a repair-shaped invariant: it must be
# re-applied on every added test, it turns the good act of adding a test into a gate failure, and a
# count cannot see a green-but-vacuous leaf anyway. These assert STRUCTURAL COMPLETENESS instead.
#
# (1)-(3) are MONOTONE — adding a test can never break them, emptying a suite always does — and no
# list is involved, so none can go stale. NO LEAF BODY IS FORCED anywhere here: every property reads
# `attrNames` and leaf keys only, so the guard costs one walk rather than one fleet evaluation per
# declaring file. Reading `config.flake.tests` from inside a suite that is itself in
# `config.flake.tests` terminates for exactly that reason.
{ config, xfail, ... }:
let
  tests = config.flake.tests;
in
{
  flake.tests.suite-completeness = {
    # (1) NON-EMPTINESS. A DECLARED KNOWN-FAILURE: four suites are `= { }` with their tests commented
    # out in place, so each reports `0/0 successful` and exits 0 — reachable exactly when a bisecting
    # agent targets the suite. The count is declared rather than the names, so a FIFTH suite emptying
    # is a new failure rather than a silent widening, and the day the four are repopulated this leaf
    # goes red to say the known-fail stopped failing.
    test-no-empty-suite = xfail.value {
      bead = "den-hoag-6jo";
      construct = "emptySuites";
      expr = builtins.length (xfail.emptySuites tests);
      actual = 4;
      correct = 0;
    };

    # (2) LEAF SHAPE. A leaf whose name lacks the prefix is not run and is not counted, so the
    # denominator itself under-reports — the printed total cannot reveal the omission.
    test-every-leaf-is-test-prefixed = {
      expr = xfail.badPrefixLeaves tests;
      expected = [ ];
    };

    # (3) DEPTH. A third nesting level is a group nix-unit does not descend into.
    test-no-nested-leaf-groups = {
      expr = xfail.nestedLeaves tests;
      expected = [ ];
    };

    # (4) THE FILE CENSUS, and it is REQUIRED rather than optional. Several suites are declared across
    # more than one file; for those, (1) does NOT see a whole file's contribution disappear, because
    # the suite stays non-empty via its siblings. This is the only guard that sees the file go — the
    # multi-file half of the emptiness property.
    #
    # The exclusion is the repo's OWN convention — a `_`-prefixed directory is what import-tree/mkCi
    # already skip as a flake-parts module — rather than a hand-kept list of directory names, which
    # mis-counts by however many such directories exist but were not written down.
    #
    # ★ THE COUNT IS A PROPERTY OF THE TREE AND MOVES WITH IT. It is not a coverage figure and must
    # not be read as one: it is the datum that makes a DELETED declaring file visible. Re-derive it
    # when files land, do not carry it forward.
    test-declaring-file-census = {
      expr = {
        count = builtins.length xfail.actualTestFiles;
        anyUnderscoreDir = builtins.any (
          f: xfail.hasInfix "_lib/" f || xfail.hasInfix "_fixtures/" f || xfail.hasInfix "_probes/" f
        ) xfail.actualTestFiles;
        hasKnownFile = builtins.elem "boundary.nix" xfail.actualTestFiles;
      };
      expected = {
        count = 225;
        anyUnderscoreDir = false;
        hasKnownFile = true;
      };
    };
  };
}
