# Task 2 (partial) — the two-stratum partition (Law A4 / r2 §B2): a structural attribute
# may not demand a resolution attribute. The gen-resolve schedule (Vogt gate + stratum
# assert) is forced at resolve construction, so a violating grammar throws there. Task 2's
# real equations are all structural, so they schedule cleanly; the negative case builds a
# minimal structural→resolution grammar and asserts the abort. Completed with the resolution
# stratum in Task 4.
{ denHoag, ... }:
let
  I = denHoag.internal;
  inherit (I) runResolve resolve parseParent;

  roots = {
    "r:x" = {
      id = "r:x";
      type = "r";
      parent = null;
      decls = {
        __entry = { };
      };
    };
  };
  buildWith = equations: runResolve { inherit roots equations parseParent; };

  # a lone structural attribute schedules fine.
  goodEqs = {
    a = resolve.attr {
      name = "a";
      kind = "synthesized";
      stratum = "structural";
      readsAttrs = [ ];
      compute = _self: _id: 1;
    };
  };

  # a structural attribute that reads a resolution attribute violates the partition.
  badEqs = {
    res = resolve.attr {
      name = "res";
      kind = "synthesized";
      stratum = "resolution";
      readsAttrs = [ ];
      compute = _self: _id: 1;
    };
    bad = resolve.attr {
      name = "bad";
      kind = "synthesized";
      stratum = "structural";
      readsAttrs = [ "res" ];
      compute = self: id: self.get id "res";
    };
  };
in
{
  flake.tests.b2-two-stratum = {
    # the real Task 2 structural stratum schedules without a stratum/circularity throw.
    test-real-structural-schedules = {
      expr = (builtins.tryEval (denHoag.mkDen [ ]).den.structural.schedule).success;
      expected = true;
    };

    # a purely structural grammar schedules.
    test-structural-only-ok = {
      expr = (builtins.tryEval (buildWith goodEqs).schedule).success;
      expected = true;
    };

    # A4 — a structural attr demanding a resolution attr aborts at schedule time.
    test-structural-demands-resolution-aborts = {
      expr = (builtins.tryEval (buildWith badEqs).schedule).success;
      expected = false;
    };
  };
}
