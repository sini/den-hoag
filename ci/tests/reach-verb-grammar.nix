# Reach-verb producer grammar (spec §7.1 class-scoped opt-in reachability). The reach engine
# (attributes/resolved-aspects.nix) already CONSUMES `reach-edge`/`reach-suppress` resolution-stratum
# records via reachEdgesOf/reachSuppressOf; these verbs are the declare-side PRODUCERS. STRING node-ids
# (no identity-law / requireEntry) — `reach` reads them via `self.get target "resolved-aspects"`.
{ denHoag, ... }:
let
  declare = denHoag.declare;
  re = declare.reach-edge { target = "user:amy@host:h"; };
  reF = declare.reach-edge {
    target = "h";
    classFilter = (n: true);
  };
  rs = declare.reach-suppress { edge = "h/u"; };
in
{
  flake.tests.reach-verb-grammar = {
    # reach-edge record shape matches reachEdgesOf: __action/target present, classFilter DEFAULTS to null.
    test-reach-edge-record = {
      expr = { inherit (re) __action target classFilter; };
      expected = {
        __action = "reach-edge";
        target = "user:amy@host:h";
        classFilter = null;
      };
    };

    # the classFilter default (null) is carried, and a supplied predicate is preserved verbatim.
    test-reach-edge-filter-carried = {
      expr = re.classFilter == null && reF.classFilter != null;
      expected = true;
    };

    # reach-suppress record shape matches reachSuppressOf: __action/edge present, `when` defaults to (_: true).
    test-reach-suppress-record = {
      expr = {
        inherit (rs) __action edge;
        whenTrue = rs.when { };
      };
      expected = {
        __action = "reach-suppress";
        edge = "h/u";
        whenTrue = true;
      };
    };

    # both verbs land in the resolution stratum.
    test-reach-edge-stratum = {
      expr = declare.stratumOf re;
      expected = "resolution";
    };
    test-reach-suppress-stratum = {
      expr = declare.stratumOf rs;
      expected = "resolution";
    };

    # a bare string target is NOT identity-law checked — it passes through unchanged (no requireEntry).
    test-string-target-no-throw = {
      expr = (declare.reach-edge { target = "plain-string"; }).target;
      expected = "plain-string";
    };
  };
}
