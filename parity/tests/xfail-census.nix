# THE CENSUS OF THIS TREE — parity's declared known-failures, on the same terms as den-hoag's own.
#
# ★ WHY A SECOND CENSUS EXISTS AT ALL, since this file's expected list is empty. Totality is PER-TREE.
# `parity` is a separate flake with its own suites, and no census in `ci/` walks them — so a leaf
# carrying attribution here is a declaration that every guard in the mechanism would pass straight
# over. Measured before this landed: a hand-written `{ expr = 0; expected = 0; bead = "TODO";
# construct = "empty codomain"; }` dropped into a parity suite is ✅, 1/1, exit 0. The constructors
# refuse that leaf on the sanctioned path; nothing refused it here, because nothing looked.
#
# ★ THE EMPTY LIST IS AN ABSENCE CLAIM, SO IT SHIPS WITH A POSITIVE CONTROL. An equality against `[ ]`
# is satisfied just as well by a census that reached nothing at all — a walk over the wrong attribute,
# a mechanism that failed to resolve, an instrument that silently returns the empty list. That is the
# vacuous-quantifier shape the mechanism refuses everywhere else, and it would be self-defeating to
# ship it here. The second leaf runs the SAME function in the SAME evaluation over a fixture that DOES
# carry a declaration, so a green `[ ]` above means "there are none" rather than "nothing was read".
{ config, xfail, ... }:
let
  # a compliant declaration, built through the real constructor, over a construct that resolves in
  # den-hoag's governed source. It is a value INSIDE this leaf's `expr`, never a leaf of this suite,
  # so the census above cannot see it and the control cannot contaminate the claim it controls.
  syntheticallyDeclared = {
    probe = {
      test-probe = xfail.value {
        bead = "den-hoag-9uv";
        construct = "recoverEmits";
        expr = 0;
        actual = 0;
        correct = 1;
      };
    };
  };
in
{
  flake.tests.xfail-census = {
    # No parity suite declares a known-failure today. The day one does, it lands here as a reviewed
    # diff hunk carrying its tracker id and the binding whose retirement invalidates it.
    test-declared-known-failures = {
      expr = xfail.censusOf config.flake.tests;
      expected = [ ];
    };

    # THE CONTROL. Same function, same run, an input that is not empty — so the row above is the tree
    # being clean and not the instrument being blind.
    test-census-instrument-is-live-in-this-tree = {
      expr = xfail.censusOf syntheticallyDeclared;
      expected = [
        {
          id = "probe.test-probe";
          bead = "den-hoag-9uv";
          construct = "recoverEmits";
          # resolved against DEN-HOAG's governed roots, which is what makes a parity declaration a
          # claim about den-hoag rather than about this harness.
          sites = [ "lib/compat/policy-recover.nix" ];
        }
      ];
    };
  };
}
