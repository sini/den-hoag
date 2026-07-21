# The ACC (ascending-chain / finite-height carrier) discipline suite (§5, L3). A discipline may DECLARE an
# `acc` capability bit; a join-semilattice gets it FREE (acc = true — a JSL is a bounded-height lattice under
# the disciplines the framework admits), else it defaults false. The closure-capability gate (the SHARED
# edges closureGate/closureMessage) now requires BOTH join-semilattice laws AND acc = true: the ascending-
# chain condition is what bounds the reachable-set fixpoint iteration (Datafun's finite-domain restriction).
# reach-closure is JSL ⇒ acc = true, so every shipped closure edge / derived closure still passes the gate.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # the compiled framework disciplines table (no user registrations) — the acc slot is READ off it.
  compiled = denHoag.internal.compileDisciplines { };

  gate = denHoag.internal.edgeKinds.closureGate;
  msg = denHoag.internal.edgeKinds.closureMessage;

  # a RAW (non-compiled) disciplines table so a JSL-but-acc=false carrier is CONSTRUCTIBLE — the real
  # `entryOf` forces acc = true on every join-semilattice, so this hypothetical is only reachable by
  # handing the gate a hand-built table (exactly the gate's contract surface).
  rawDisciplines = {
    good-jsl = {
      laws = "join-semilattice";
      acc = true;
    };
    non-acc-jsl = {
      laws = "join-semilattice";
      acc = false;
    };
    non-jsl = {
      laws = "ordered-monoid";
    };
  };
  gateOf =
    disc:
    gate rawDisciplines {
      name = "myClosure";
      closure = true;
      discipline = disc;
    };
  msgOf =
    disc:
    msg rawDisciplines {
      name = "myClosure";
      closure = true;
      discipline = disc;
    };
in
{
  flake.tests.acc-discipline = {
    # ── the acc slot on the discipline record ──
    # reach-closure is a join-semilattice ⇒ acc = true FREE (so no regression to shipped closure edges).
    test-acc-reach-closure-true = {
      expr = compiled.reach-closure.acc;
      expected = true;
    };
    # the ordered-monoid framework instances default acc = false (ACC is a JSL-and-above property).
    test-acc-settings-layers-false = {
      expr = compiled.settings-layers.acc;
      expected = false;
    };
    test-acc-collections-neron-false = {
      expr = compiled.collections-neron.acc;
      expected = false;
    };

    # ── the closure gate now requires JSL AND acc ──
    # a JSL + acc discipline passes the gate (null message, no throw).
    test-acc-gate-good-jsl-clean = {
      expr = throws (gateOf "good-jsl");
      expected = false;
    };
    # reach-closure (the shipped instance) passes the gate against the REAL compiled table.
    test-acc-gate-reach-closure-clean = {
      expr = throws (
        gate compiled {
          name = "myClosure";
          closure = true;
          discipline = "reach-closure";
        }
      );
      expected = false;
    };
    # a JSL-but-non-ACC carrier is REJECTED NAMED (the new acc branch — never fires on the corpus, whose
    # only JSL discipline reach-closure is acc = true).
    test-acc-gate-non-acc-jsl-throws = {
      expr = throws (gateOf "non-acc-jsl");
      expected = true;
    };
    # …and the message NAMES the ACC obligation (a distinct string from the JSL-laws branch message).
    test-acc-msg-non-acc-jsl-named = {
      expr = builtins.match ".*ACC.*" (msgOf "non-acc-jsl") != null;
      expected = true;
    };
    # a non-JSL closure still throws (the existing laws branch — unchanged).
    test-acc-gate-non-jsl-throws = {
      expr = throws (gateOf "non-jsl");
      expected = true;
    };
  };
}
