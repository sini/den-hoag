# The repo-root ENTRY guard. den-hoag has TWO roots — the flake (whose `compat` output every other suite
# drives) and the standalone `default.nix`, whose `.compat` rides on the returned lib for a non-flake
# consumer. Only the flake root was ever exercised, so a dep the standalone root failed to forward was
# invisible: its `.compat` threw "called without required argument" while the suites stayed green. Both
# roots now go through ONE construction (lib/compat/wiring.nix); these assertions pin that they do.
#
# FORCING DEPTH. The assertions read the compat attrset SPINE (`attrNames` / `?`) and nothing beneath it.
# That is the entire depth the missing-formal class needs: a required formal is checked when the shim
# function is APPLIED, and the spine cannot be read without applying it. The spine read forces NO
# substrate dep — the standalone entry's lock-fetched dep defaults stay unforced — so the guard costs no
# fetch and no assembly eval. It is correspondingly NOT a behavioral test of the standalone shim: any
# defect below the spine is out of its reach, and the suites that drive the flake root cover that.
#
# NON-VACUITY. The missing-formal error is NOT tryEval-catchable, so the teeth cannot ride here as a
# throwing companion assertion (it would abort the whole suite eval rather than report). The control is
# the same predicate on the pre-fix argument set — the shim's formals MINUS `graph` — which fails the
# eval outright; a root that stops supplying a formal therefore takes CI down with the named error at
# lib/compat/default.nix's argument list, never a silent pass.
{ denCompat, denHoagSrc, ... }:
let
  # The standalone root wired from its OWN defaults — verbatim the non-flake consumer path
  # `(import <den-hoag> { }).compat`, every dep resolving through the entry's own flake.lock.
  standalone = import "${denHoagSrc}/default.nix" { };
in
{
  flake.tests.root-entry = {
    # the standalone root's `.compat` APPLIES: a formal this root fails to forward throws right here.
    test-standalone-compat-applies = {
      expr = builtins.isAttrs standalone.compat;
      expected = true;
    };
    # ONE construction, two roots — the standalone root presents the SAME shim surface as the flake
    # output. A root wiring a divergent shim (a different dep set, a severed feature) moves this list.
    test-standalone-compat-surface-equals-flake = {
      expr = builtins.attrNames standalone.compat == builtins.attrNames denCompat;
      expected = true;
    };
    # `.compat` rides ON the lib (the standalone root IS the lib): the four-concern API and the shim
    # entry verbs are both reachable from the one returned value.
    test-standalone-lib-and-compat-reachable = {
      expr = (standalone ? mkDen) && (standalone.compat ? compile) && (standalone.compat ? mkDen);
      expected = true;
    };
  };
}
