# den-compat-test LEAF-SHAPE witness — the scaffold's own instrument test.
#
# `_lib/den-compat-test.nix` sits between 57 behavioral witnesses and nix-unit: every one of them
# declares its assertion to the scaffold, and the scaffold declares a leaf to the runner. Nothing else
# checked that the second declaration still carries the first. It did not: the tail built a fresh literal
# attrset per arm, so the error arm lowered `{ expr; expectedError = { type; msg; }; }` to
# `{ expr = (tryEval (deepSeq expr expr)).success; expected = false; }` — `type` and `msg` never reached
# the runner, and a witness naming ONE abort passed on ANY error at all. The tail is now a PROJECTION
# onto a single declared `assertionKeys` set, so no arm can erase a key the author wrote.
#
# WHICH CHECKS HAVE TEETH (each is killed by restoring the rebuild):
#   · test-error-form-leaf-keys / test-error-form-forwards-type-and-msg — read the leaf SHAPE directly.
#     The rebuild emits `[ "expected" "expr" ]` and has no `expectedError` at all, so both go red.
#   · test-error-form-rides-native-channel — an `EvalError` (missing attribute). `tryEval` does NOT catch
#     that class, so under the rebuild this leaf does not fail, it KILLS the evaluation (☢️).
#   · test-both-assertion-forms-refused — the rebuild silently swallows the contradiction and no error is
#     raised, so the runner reports "Expected error, but no error was caught".
# The two value-form checks have no teeth against THIS change by design: they are the byte-stability
# guard for the arm the change does not intend to touch.
#
# Every `testFn` here IGNORES its helper argument, so the bridge eval is never forced — these read the
# scaffold's leaf construction, not a fleet.
{
  denHoag,
  denHoagFlakeModule,
  homeManagerModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ./_lib/den-compat-test.nix {
    inherit
      denHoag
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };

  errorForm = denTest (_: {
    expr = throw "den-compat-leaf witness: alpha-sentinel";
    expectedError = {
      type = "ThrownError";
      msg = "alpha-sentinel";
    };
  });
in
{
  flake.tests.den-compat-leaf = {
    # ══ the error form reaches nix-unit INTACT ══════════════════════════════════════════════════════
    # `expected` is absent BY NECESSITY, not by omission: nix-unit forces `expr` against `expected`
    # outside its error channel, so a leaf carrying both lets the error escape uncaught. attrNames sorts.
    test-error-form-leaf-keys = {
      expr = builtins.attrNames errorForm;
      expected = [
        "expectedError"
        "expr"
      ];
    };
    # BOTH fields survive verbatim. `msg` is what makes the assertion name an error rather than merely
    # count one — nix-unit matches it as an unanchored pattern and reports "Expected error msg pattern
    # '<declared>' does not match thrown error msg '<actual>'" when a different abort fires.
    test-error-form-forwards-type-and-msg = {
      expr = errorForm.expectedError;
      expected = {
        type = "ThrownError";
        msg = "alpha-sentinel";
      };
    };

    # ══ the forwarded leaf really rides the runner's error channel ══════════════════════════════════
    # A missing attribute is an `EvalError`, the class `tryEval` does NOT catch. The scaffold hands the
    # unforced expression to nix-unit and the RUNNER catches it, so the class the old lowering could not
    # express is now assertable — and it is asserted BY NAME, both type and message text.
    test-error-form-rides-native-channel = denTest (_: {
      expr = { a = 1; }.b;
      expectedError = {
        type = "EvalError";
        msg = "attribute 'b' missing";
      };
    });
    # The canonical migrated-witness usage: a throw, named. Its teeth are in the shape checks above (the
    # old lowering also went green here — which is precisely the defect: it went green on ANY error).
    test-error-form-names-the-throw = denTest (_: {
      expr = throw "den-compat-leaf witness: beta-sentinel";
      expectedError = {
        type = "ThrownError";
        msg = "beta-sentinel";
      };
    });

    # ══ the two assertion forms are mutually exclusive, and saying both is REFUSED ══════════════════
    # Not silently resolved in favour of one. A scaffold that drops a declared assertion key is the
    # defect this file exists to pin, so declaring both raises where it was written rather than
    # surfacing later as an uncaught throw attributed to the expression.
    test-both-assertion-forms-refused = {
      expr = denTest (_: {
        expr = 1;
        expected = 1;
        expectedError = {
          type = "ThrownError";
          msg = "unreachable";
        };
      });
      expectedError = {
        type = "ThrownError";
        msg = "declares BOTH";
      };
    };

    # ══ the leaf is a PROJECTION: the fleet declaration does not ride into it ═══════════════════════
    # The test module's `den.*` declarations are the fleet, not the assertion. They are stripped by the
    # projection (as `fleetModule`'s removeAttrs strips the assertion keys from the flake-parts face) —
    # the two directions of the same seam.
    test-leaf-drops-non-assertion-keys = {
      expr = builtins.attrNames (
        denTest (_: {
          den.hosts = { };
          imports = [ ];
          expr = 1;
          expected = 1;
        })
      );
      expected = [
        "expected"
        "expr"
      ];
    };

    # ══ value form unchanged (byte-stability for the arm this change does not target) ═══════════════
    # v1 denTest's partial match: when both sides are attrsets, only the keys `expected` names compare.
    test-value-form-partial-match-preserved = {
      expr = denTest (_: {
        expr = {
          a = 1;
          b = 2;
        };
        expected = {
          a = 1;
        };
      });
      expected = {
        expr = {
          a = 1;
        };
        expected = {
          a = 1;
        };
      };
    };
    # A non-attrset pair rides through untransformed.
    test-value-form-scalar-passthrough = {
      expr = denTest (_: {
        expr = 7;
        expected = 7;
      });
      expected = {
        expr = 7;
        expected = 7;
      };
    };
  };
}
