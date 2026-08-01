# THE DECLARATION MECHANISM, EXERCISED ON ITSELF — because an unused arm is an untested arm.
#
# Every shipped declaration is VALUE-form, so without this file the ERROR form would ship with no
# instance at all and its first real use would be its first execution. None of what follows uses
# `tryEval`: `tryEval` catches only `throw` and `assert`, so it cannot see a missing attribute, a type
# error or an abort — those propagate straight through it and kill the evaluation. The runner's native
# error channel catches all of them, compares the error KIND, and — the property a boolean lowering
# cannot have — FAILS when the expression does not throw at all.
#
# ★ THE REFUSAL LEAVES BELOW ARE NOT CENSUS ROWS, and the reason is structural rather than a
# convention: the leaf under test FAILS TO BUILD, so no `bead` key ever reaches the tree and the
# enclosing leaf carries only `expr` + `expectedError`. That is also why making `bead` required does
# not turn the mechanism's own negative tests into declarations.
#
# ★ EACH REFUSAL QUOTES A DISTINCTIVE FRAGMENT of the message it expects, so rewording a diagnostic
# without updating its test is a red rather than a silent weakening.
{ xfail, ... }:
let
  # raised by THIS file, so the error form is exercised against a throw whose text this file owns.
  selfThrow = throw "xfail-selftest: this throw is raised by this file so the error form has something real to catch";
in
{
  flake.tests.xfail-selftest = {
    # ── the ERROR form, positively, on the real wrapper and in every CI run ────────────────────
    test-error-form-catches-its-own-throw = xfail.error {
      bead = "den-hoag-9uv";
      construct = "xfailError";
      expr = selfThrow;
      type = "ThrownError";
      msg = "raised by this file";
    };

    # ── G1: the tracker id's shape, on BOTH forms ─────────────────────────────────────────────
    # The guards live on the shared constructor rather than being copied per form, and these two
    # assert that from opposite arms.
    test-malformed-bead-refused = {
      expr = xfail.value {
        bead = "TODO";
        construct = "pipeOps";
        expr = 0;
        actual = 0;
        correct = 3;
      };
      expectedError = {
        type = "ThrownError";
        msg = "not a den-hoag tracker id";
      };
    };
    # a bead-SHAPED English phrase. An unanchored regex would accept it; `builtins.match` is a full
    # match, so the pattern is anchored by construction.
    test-english-bead-shape-refused = {
      expr = xfail.error {
        bead = "den-hoag-absent";
        construct = "pipeOps";
        expr = 1;
        type = "ThrownError";
        msg = "boom";
      };
      expectedError = {
        type = "ThrownError";
        msg = "not a den-hoag tracker id";
      };
    };

    # ── G3: `construct` must be BOUND, not merely mentioned ───────────────────────────────────
    # The prose phrase the source itself uses for the defect behind two declarations — the most
    # natural value an author would reach for. Under a whole-file infix test it RESOLVES, at a
    # comment, and the anchor then survives the retirement it exists to witness.
    test-prose-construct-refused = {
      expr = xfail.value {
        bead = "den-hoag-9xo.75";
        construct = "empty codomain";
        expr = 0;
        actual = 0;
        correct = 1;
      };
      expectedError = {
        type = "ThrownError";
        msg = "not bound in the governed source";
      };
    };

    # ── the `msg` floor: reject EXACTLY the patterns that match every message ──────────────────
    # A pattern matches every message iff it can match the empty substring, which every string
    # contains. `x?` is the one that shows the old floor (`msg != ""`) was not the property.
    test-total-msg-star-refused = {
      expr = xfail.error {
        bead = "den-hoag-gb9";
        construct = "pipeOps";
        expr = 1;
        type = "ThrownError";
        msg = ".*";
      };
      expectedError = {
        type = "ThrownError";
        msg = "matches EVERY message";
      };
    };
    test-total-msg-optional-refused = {
      expr = xfail.error {
        bead = "den-hoag-gb9";
        construct = "pipeOps";
        expr = 1;
        type = "ThrownError";
        msg = "x?";
      };
      expectedError = {
        type = "ThrownError";
        msg = "matches EVERY message";
      };
    };
    # POSITIVE CONTROL for the floor, same run: it is not over-broad. `"."` is ACCEPTED — the stated
    # limit of the construction, asserted rather than described away, because no in-eval predicate
    # excludes it.
    test-dot-msg-accepted = {
      expr =
        (xfail.error {
          bead = "den-hoag-gb9";
          construct = "pipeOps";
          expr = 1;
          type = "ThrownError";
          msg = ".";
        }).expectedError.msg;
      expected = ".";
    };

    # ── the degenerate clause ─────────────────────────────────────────────────────────────────
    # A declaration whose `actual` equals its `correct` claims today's value is also the right one,
    # which is a test that really passes wearing a permanent known-fail attribution.
    test-degenerate-value-refused = {
      expr = xfail.value {
        bead = "den-hoag-9uv";
        construct = "xfailValue";
        expr = 1;
        actual = 1;
        correct = 1;
      };
      expectedError = {
        type = "ThrownError";
        msg = "degenerate xfail claims today's value";
      };
    };

    # ── the diagnosis ORDER, which `builtins.seq` fixes ───────────────────────────────────────
    # This leaf violates the attribution clause AND the form-specific clause at once. Without the
    # `seq` the form-specific clause is the `if` condition and therefore always wins, and the author
    # is told their `msg` is too broad when their real defect is that the bead names nothing.
    test-attribution-is-diagnosed-first = {
      expr = xfail.error {
        bead = "TODO";
        construct = "pipeOps";
        expr = 1;
        type = "ThrownError";
        msg = ".*";
      };
      expectedError = {
        type = "ThrownError";
        msg = "not a den-hoag tracker id";
      };
    };

    # ── POSITIVE CONTROL FOR THE WHOLE WIRING ─────────────────────────────────────────────────
    # Without this, every refusal above is equally satisfied by a constructor that refuses
    # everything. A compliant leaf BUILDS, and builds to its full shape with the whole claim on it.
    test-compliant-leaf-builds = {
      expr = xfail.value {
        bead = "den-hoag-9xo.75";
        construct = "recoverEmits";
        expr = 0;
        actual = 0;
        correct = 1;
      };
      expected = {
        bead = "den-hoag-9xo.75";
        construct = "recoverEmits";
        correct = 1;
        expected = 0;
        expr = 0;
      };
    };
    # ...and the forms are DISJOINT by construction: the error form cannot emit `expected`, which is
    # what stops a leaf carrying both keys from being run as a value-form test with its
    # `expectedError` silently ignored.
    test-error-form-has-no-expected = {
      expr =
        (xfail.error {
          bead = "den-hoag-gb9";
          construct = "pipeOps";
          expr = 0;
          type = "ThrownError";
          msg = "boom";
        }) ? expected;
      expected = false;
    };
  };
}
