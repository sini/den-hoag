# The ERROR-CHANNEL suite — the instrument's own semantics, asserted as tests.
#
# Every `expectedError` leaf in this repository is an assertion about nix-unit's error channel, and every
# property that channel has was established by SELF-MEASUREMENT against whatever nix-unit happened to be
# installed. Two of those properties FAIL OPEN: an `expectedError` that omits `type` accepts an error of ANY
# kind, and one that omits `msg` accepts ANY message. So a silent relaxation in a future nix-unit would not
# break the suite — it would make the suite go GREENER, weakening every error assertion at once in the one
# direction nobody investigates.
#
# `.github/workflows/ci.yml` pins the instrument to this flake's lock, which stops the version from moving
# underneath the contract. A PIN PROTECTS AGAINST THE CHANGE; ONLY A FIXTURE DETECTS IT. That is this file:
# each leaf below states one measured property of the channel, so a nix-unit whose semantics have shifted
# turns these RED at the point of the shift instead of silently loosening the rest of the suite.
#
# ── DIRECTION, AND THE CEILING. These are canaries for TIGHTENING: every leaf passes today and fails if the
#    property it names goes away. The opposite direction — a channel that gets LOOSER — is NOT detectable
#    from inside a pure eval, because the assertion "this leaf must FAIL" is not expressible in nix-unit, and
#    a meta-run of nix-unit over a probe would need a builder. The `builtins.match` leaf at the end is the
#    part of the fail-open story that IS expressible in-eval: it pins the exact characterisation of which
#    `msg` patterns are vacuous, so a census can refuse them structurally rather than by taste.
#
# ── ON `checks.default`: gen's homegrown `assertTests` reads `t.expected` on every leaf and therefore cannot
#    evaluate an `expectedError` leaf at all. That instrument is already red on this repo's existing
#    expectedError leaves; these add to that set and do not change its status. nix-unit is the gate.
{
  ...
}:
let
  # One throw with a distinct prefix AND suffix, so a pattern drawn from its middle is a real test of
  # SEARCH semantics rather than an accidental full-match.
  canary = throw "den-hoag canary prefix: compose commitment: policy tail";
in
{
  flake.tests.error-channel = {
    # ★ THE ACUTE ONE. `type` omitted must keep meaning "an error of any kind". If a future nix-unit
    # required `type`, or defaulted it to some specific kind, this leaf goes red — and it is the only thing
    # standing between that change and the silent relaxation of every type-less expectedError in the suite.
    test-omitted-type-means-any-kind = {
      expr = canary;
      expectedError.msg = "compose commitment";
    };

    # The same fail-open, on the other axis: `msg` omitted must keep meaning "any message".
    test-omitted-msg-means-any-message = {
      expr = canary;
      expectedError.type = "ThrownError";
    };

    # `msg` is a REGEX, not a literal substring test. The character classes here match only under regex
    # interpretation, so a change to literal matching turns this red.
    test-msg-is-a-regex = {
      expr = canary;
      expectedError.msg = "c[o0]mpose c[a-z]+tment";
    };

    # …and it is matched by SEARCH, not full-match: the pattern is a strict interior substring of the real
    # message, with both a prefix and a suffix left unmatched.
    test-msg-matches-by-search-not-full-match = {
      expr = canary;
      expectedError.msg = "commitment: policy";
    };

    # THE TYPE VOCABULARY, one leaf per kind the suite relies on. A renamed or merged kind turns exactly the
    # affected leaf red, which localises the change instead of scattering it.
    test-type-thrown-error = {
      expr = canary;
      expectedError = {
        type = "ThrownError";
        msg = "compose commitment";
      };
    };

    # ★ The kind `tryEval` CANNOT catch: a missing attribute propagates through `builtins.tryEval` and kills
    # the evaluation, so a tryEval-to-a-boolean lowering cannot express this assertion at all. nix-unit can.
    # This leaf is why the error channel is used natively rather than lowered.
    test-type-eval-error-is-caught = {
      expr = { a = 1; }.b;
      expectedError.type = "EvalError";
    };

    test-type-assertion-error = {
      expr = (
        assert false;
        1
      );
      expectedError.type = "AssertionError";
    };

    # An abort is NOT recoverable in-eval either, and is likewise caught here.
    test-type-abort = {
      expr = builtins.abort "den-hoag canary abort";
      expectedError = {
        type = "Abort";
        msg = "canary abort";
      };
    };

    # EXTRA-KEY TOLERANCE. Attribution (a bead id, a construct name) rides ON the leaf rather than in a side
    # artifact, which only works because nix-unit ignores keys it does not know. If it started rejecting
    # them, every attributed leaf in the repo would fail at once; this one fails first and says why.
    test-extra-keys-are-tolerated-on-an-error-leaf = {
      expr = canary;
      expectedError.msg = "compose commitment";
      bead = "den-hoag-1rk";
      construct = "error-channel canary";
    };

    # `tryEval`'s classification, for the contrast the two leaves above rest on: it distinguishes "threw"
    # from "returned" and nothing finer. Only the two kinds it DOES catch are assertable here — the three it
    # does not (missing attribute, type error, division by zero) would take this suite down with them, which
    # is itself the reason the error channel is native.
    test-tryeval-catches-only-throw-and-assert = {
      expr = {
        throwCaught = !(builtins.tryEval (builtins.deepSeq (throw "x") true)).success;
        assertCaught =
          !(builtins.tryEval (
            builtins.deepSeq (
              assert false;
              1
            ) true
          )).success;
      };
      expected = {
        throwCaught = true;
        assertCaught = true;
      };
    };

    # ★ THE FAIL-OPEN AXIS, CHARACTERISED EXACTLY. Because `msg` is matched by search, a pattern accepts
    # EVERY message iff it can match the empty substring — which every string contains — i.e. iff
    # `builtins.match msg "" != null`. That is an equivalence, not a heuristic, and it is what lets a census
    # refuse a vacuous pattern structurally. Pinned here so the refusal predicate cannot drift away from the
    # regex engine underneath it. `"^$"` is the deliberate conservative edge: it matches only the empty
    # message and is refused anyway; `"."` is the stated limit of the floor, accepted though narrow.
    test-vacuous-msg-pattern-characterisation = {
      expr = builtins.map (m: builtins.match m "" != null) [
        ".*"
        "x?"
        ""
        "^$"
        "."
        "compose commitment"
      ];
      expected = [
        true
        true
        true
        true
        false
        false
      ];
    };
  };
}
