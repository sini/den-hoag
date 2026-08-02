# THE CENSUS — every declared known-failure in the tree, as one reviewed artifact.
#
# The constructors make a malformed declaration unbuildable on the sanctioned path. They cannot make it
# unbuildable on EVERY path: a leaf is a plain attrset, and one written by hand never touches a
# constructor. The census closes that, because carrying the attribution keys IS the definition of a
# declared known-failure — so selecting on them is total over the tree, and producing a row is what
# re-checks the guards.
#
# WHAT THE LITERAL BUYS THAT THE GUARDS DO NOT. The guards are predicates: they can say a declaration is
# well-formed, never that it is one anybody agreed to. The literal is the second artifact a human reads,
# so ADDING a known-failure is a reviewed diff hunk rather than a line in a file nobody opens, and a
# declaration that quietly changes which defect it names moves a row.
#
# `sites` is the file set that BINDS each `construct`, and it rides in the row for a reason: a PARTIAL
# retirement — one of several definitions deleted — leaves membership intact while the site set moves,
# so the row changes under review rather than the anchor silently weakening.
#
# ★ THE ERROR-FORM ROW CARRIES `type` AND `msg`. Both are bounded strings by construction, which is why
# they ride while `expected`/`correct` — test values of unbounded size — do not: a census carrying those
# would be the checked-in result set this design exists to avoid. It matters because the `msg` floor
# admits `"."`, which no in-eval predicate can reject; weakening a `msg` toward it is then a visible
# diff hunk here rather than an invisible relaxation at the leaf.
#
# ★ WHAT THIS CANNOT CHECK, stated rather than implied: that each `bead` EXISTS and is OPEN. Neither is
# decidable in a pure eval. And it is BLIND to the opt-in fail-open — an author facing a red may edit
# `expected` in place instead of declaring, and this output is byte-identical either way.
{ config, xfail, ... }:
{
  flake.tests.xfail-census = {
    # Reading `config.flake.tests` from a suite that is itself in `config.flake.tests` terminates: the
    # walk selects on key PRESENCE and never forces a leaf's `expr`, and no leaf here is a declaration.
    test-declared-known-failures = {
      expr = xfail.censusOf config.flake.tests;
      expected = [
        # the empty-recovery hazard: a value-conditional v1 policy's codomain recovers EMPTY, so the
        # policy classifies to no group and compiles to no rule — silently. The severed-belt row is the
        # same defect reached from the other side: `probeSentinel` OFF removes the sentinel's `class`
        # field, which is what makes the corpus shape `if host ? class` value-conditional at the probe.
        # Its attribution was RULED (den-hoag-8n1) rather than read off the fixture's comment.
        {
          id = "compat-feature-severed.test-probeSentinel-off-parks";
          bead = "den-hoag-9xo.75";
          construct = "recoverEmits";
          sites = [ "lib/compat/policy-recover.nix" ];
        }
        {
          id = "compat-scope-local-firing.test-expansion-collapses-to-one-rule";
          bead = "den-hoag-9xo.75";
          construct = "recoverEmits";
          sites = [ "lib/compat/policy-recover.nix" ];
        }
        {
          id = "compat-scope-local-firing.test-expansion-subrule-shape";
          bead = "den-hoag-9xo.75";
          construct = "recoverEmits";
          sites = [ "lib/compat/policy-recover.nix" ];
        }
        # four suites are `= { }` with their tests commented out in place, so each reports 0/0 and
        # exits 0 — a false pass reachable exactly when someone targets the suite.
        {
          id = "suite-completeness.test-no-empty-suite";
          bead = "den-hoag-6jo";
          construct = "emptySuites";
          sites = [ "ci/tests/_lib/xfail.nix" ];
        }
        # the mechanism's own error-form instance, so the arm ships exercised rather than merely
        # defined. Its `construct` is the constructor itself: retire that and the claim is void.
        {
          id = "xfail-selftest.test-error-form-catches-its-own-throw";
          bead = "den-hoag-9uv";
          construct = "xfailError";
          sites = [ "ci/tests/_lib/xfail.nix" ];
          type = "ThrownError";
          msg = "raised by this file";
        }
      ];
    };

    # ★ THE POSITIVE CONTROL, in the same run. Every clause above is a universal over the census, and a
    # universal over an EMPTY census holds vacuously — so an equality against a literal that had
    # silently become `[ ]` would still need something to say the walk reached anything at all. The row
    # count is asserted beside the literal for that reason, and the two guards are asserted to hold
    # across every row rather than only at the rows a reader happens to check.
    test-census-is-non-empty-and-every-row-passes-both-guards = {
      expr =
        let
          rows = xfail.censusOf config.flake.tests;
        in
        {
          rowCount = builtins.length rows;
          allBeadsWellShaped = builtins.all (r: xfail.beadShapeOk r.bead) rows;
          allConstructsResolve = builtins.all (r: xfail.anchorResolves r.construct) rows;
          allSitesNonEmpty = builtins.all (r: r.sites != [ ]) rows;
        };
      expected = {
        rowCount = 5;
        allBeadsWellShaped = true;
        allConstructsResolve = true;
        allSitesNonEmpty = true;
      };
    };
  };
}
