# THE SUPPRESSION STRATIFICATION — Apt, Blair & Walker (1988), "Stratified Programs".
#
# THE PROGRAM the suppression path is:
#   fires(P, n)      <- gate(P, n) AND NOT suppressed(P, n)
#   suppressed(Q, n) <- fires(P, m) AND emits-suppress(P, Q) AND contains*(m, n)
# The `contains*` arm is a POSITIVE same-stratum read (Definition 3 condition 1, p. 96, admits it). Only
# `NOT suppressed` is negative, and condition 2 requires ITS definition to sit strictly below the stratum
# of the rule reading it.
#
# ★★ WHAT THIS SUITE PINS IS THE MODEL, NOT MERELY THE ABSENCE OF AN ABORT. Firing the exclude feed once,
# against a ctx carrying no `suppressedPolicies`, evaluates the negative literal against the EMPTY
# extension of the relation being computed — ONE application of T_P, where the standard model is the
# per-stratum fixpoint M_i = T_{P_i}↑ω(M_{i-1}) (p. 108). The two agree exactly at depth ≤ 1 and diverge
# above it, so the depth-2 and depth-3 chains are the discriminating rows and the depth-1 chain is the
# control that says the instrument reads a suppression at all.
#
# THE CHAIN IS ACYCLIC. No cycle guard could catch a wrong model here — the input is a perfectly
# well-defined stratified program and the answer was simply the wrong one.
#
# ★ A NOTE ON WHAT THE GATE IS. The second clause's body contains `fires(P, m)`, so a SUPPRESSED policy
# contributes no suppression: `fires` is what the first clause defines. A policy body that does not
# consult `suppressedPolicies` has not written that clause down, and its suppressions are realized
# whatever its own state — which is why the unconditional arm below is pinned as a CONTRAST rather than
# omitted. Rank ordering supplies the negative literal's EXTENSION; the body still has to read it.
{ denHoag, ... }:
let
  inherit (denHoag) declare;
  I = denHoag.internal;

  schema = {
    config.den.schema.rack.parent = null;
  };
  instances = {
    config.den.rack.r1 = { };
  };

  # A GATED excluder — the `fires(P,n) <- ... AND NOT suppressed(P,n)` clause, written out. A suppressed
  # policy produces NOTHING, its own `suppress` included.
  gated = name: target: {
    selects = [ "rack" ];
    emits = [ "suppress" ];
    suppresses = [ target ];
    fn =
      ctx:
      if builtins.elem name (ctx.suppressedPolicies or [ ]) then
        [ ]
      else
        [ (declare.suppress { name = target; }) ];
  };

  # An UNCONDITIONAL excluder — the same head with no negative literal in its body. Kept as the contrast
  # arm: rank ordering delivers the extension, but a rule that never reads it cannot be gated by it.
  unconditional = target: {
    selects = [ "rack" ];
    emits = [ "suppress" ];
    suppresses = [ target ];
    fn = _ctx: [ (declare.suppress { name = target; }) ];
  };

  mk =
    policies:
    (denHoag.mkDen [
      schema
      instances
      { config.den.policies = policies; }
    ]).den;

  suppressedAt = den: den.structural.eval.get "rack:r1" "suppressed-policies";
  forced = den: (builtins.tryEval (builtins.deepSeq (suppressedAt den) true)).success;

  depth1 = mk { A = gated "A" "Z"; };
  depth2 = mk {
    A = gated "A" "B";
    B = gated "B" "C";
  };
  depth3 = mk {
    A = gated "A" "B";
    B = gated "B" "C";
    C = gated "C" "D";
  };
  depth3Unconditional = mk {
    A = unconditional "B";
    B = unconditional "C";
    C = unconditional "D";
  };
  noSuppressor = mk { };

  # A MUTUAL pair and a SELF-NEGATING policy: both are cycles through a negative edge, which Lemma 1
  # (p. 97) forbids outright — no stratification exists, so there is no model to compute.
  mutual = mk {
    A = gated "A" "B";
    B = gated "B" "A";
  };
  selfNeg = mk { A = gated "A" "A"; };
in
{
  flake.tests.suppression-stratification = {
    # ── THE DISCRIMINATING ROWS. A one-shot evaluator answers ["B","C"] and ["B","C","D"] here: it
    #    suppresses B and then realizes B's suppression of C anyway, because it collected every emission
    #    in the same pass that suppressed their author. The standard model suppresses B, which stops B
    #    firing, so C is never suppressed — and at depth 3 that lets C fire and suppress D. ──────────────
    test-chain-resolves-to-the-standard-model = {
      expr = {
        depth2 = suppressedAt depth2;
        depth3 = suppressedAt depth3;
      };
      expected = {
        depth2 = [ "B" ];
        depth3 = [
          "B"
          "D"
        ];
      };
    };

    # ── THE DEPTH-1 POSITIVE CONTROL: the one-shot and the fixpoint AGREE at depth 1, so this arm is
    #    green under both and says the instrument reads a delivered suppression at all. Without it, the
    #    rows above could be read as "no suppression is ever delivered". ───────────────────────────────
    test-depth-one-control = {
      expr = suppressedAt depth1;
      expected = [ "Z" ];
    };

    # ── THE NEGATIVE CONTROL: no excluder, no set. This says the values above are a DELIVERY rather than
    #    the shape of a default the reader would have got anyway. ─────────────────────────────────────
    test-no-suppressor-control = {
      expr = suppressedAt noSuppressor;
      expected = [ ];
    };

    # ── THE CONTRAST ARM, pinned rather than omitted. The same three-link chain written WITHOUT the
    #    negative literal in each body yields the full transitive set. Rank ordering hands every firing
    #    the completed extension of `suppressed`; a body that does not consult it has not written the
    #    `fires <- ... AND NOT suppressed` clause, and no schedule can supply a premise the rule declines
    #    to read. Pinning this keeps the row above from being read as a claim about the SCHEDULE alone. ──
    test-unconditional-bodies-realize-the-whole-chain = {
      expr = suppressedAt depth3Unconditional;
      expected = [
        "B"
        "C"
        "D"
      ];
    };

    # ── LEMMA 1 (p. 97): a cycle containing a negative edge has NO stratification, so it is refused at
    #    registration rather than resolved to some set. Both shapes abort, and the message is matched so
    #    a witness naming this abort cannot pass on any other error. ──────────────────────────────────
    test-mutual-suppression-aborts = {
      expr = suppressedAt mutual;
      expectedError = {
        type = "ThrownError";
        msg = "has a cycle through the NEGATIVE edge contributed by";
      };
    };
    test-self-negating-policy-aborts = {
      expr = suppressedAt selfNeg;
      expectedError = {
        type = "ThrownError";
        msg = "has a cycle through the NEGATIVE edge contributed by";
      };
    };

    # ── …and the ACYCLIC chain REGISTERS CLEANLY in the same suite, which is the paired control Lemma 1
    #    requires: a guard that rejected the stratified program too would be over-strict, not safe.
    #    `policyMessage` returns its message as a VALUE (`null` = clean), so this asserts the registration
    #    verdict directly rather than inferring it from the absence of a throw. ────────────────────────
    test-acyclic-chain-registers-clean = {
      expr = I.policyMessage {
        A = gated "A" "B";
        B = gated "B" "C";
        C = gated "C" "D";
      };
      expected = null;
    };
  };
}
