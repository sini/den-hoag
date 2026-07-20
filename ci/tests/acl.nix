# The ACL / resolution-facet suite (§5). A user registers a join-semilattice merge discipline on
# `den.disciplines.<name>` and consumes it from a `closure = true` derived — the general witness that the
# closure-capability laws-gate (guard (f), the SHARED edges closureMessage) accepts ANY registered join-
# semilattice discipline, not only the framework `reach-closure` instance. `set-union` is the first non-
# framework discipline instance (append-then-membership-dedup, idempotent up to the set the list induces);
# its algebraic laws are proved in the property-laws harness (it rides the compiled-table iteration). This
# suite proves the CONSUMPTION side: a user discipline passes guard (f). See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a fleet registering the USER discipline `set-union` (a join-semilattice, NOT framework-reserved) plus a
  # single `closure = true` derived that names it — the closure laws-gate (guard (f)) reads the compiled
  # disciplines registry, so the user instance must be present for the gate to accept it.
  mkAclFleet =
    deriv:
    denHoag.mkDen [
      (
        { config, ... }:
        {
          config.den.schema.node.parent = null;
          config.den.relations.memberOf = {
            inverse = "members";
          };
          config.den.strata.insert.closure = {
            after = "resolution";
          };
          # the user join-semilattice discipline: append-then-membership-dedup (idempotent up to the set the
          # list induces) — the same algebra the property-laws harness samples for its laws.
          config.den.disciplines.set-union = {
            laws = "join-semilattice";
            empty = [ ];
            combine = a: b: a ++ builtins.filter (x: !(builtins.elem x a)) b;
          };
          config.den.derived.foo = deriv;
        }
      )
    ];

  # closure=true under the USER-registered join-semilattice discipline `set-union` — lawful (guard (f) accepts a
  # user JSL discipline, not only framework reach-closure). A trivial `derive` satisfies guard (g), so guard (f)
  # (not the missing-derive guard) is what this fixture exercises.
  userDisciplineFleet = mkAclFleet {
    over = [ ];
    direction = "forward";
    stratum = "closure";
    closure = true;
    discipline = "set-union";
    derive = node: _: null;
  };
in
{
  flake.tests.acl = {
    # the closure=true derive naming a USER join-semilattice discipline registers cleanly — guard (f) (the
    # closure-capability laws-gate) accepts any registered join-semilattice, not only the framework instance.
    test-acl-user-discipline-closure-clean = {
      expr = throws userDisciplineFleet.den.derived;
      expected = false;
    };
    # non-vacuous: the derived is actually present (the fleet compiled, the discipline registered beside the
    # framework instances).
    test-acl-user-discipline-registers = {
      expr = builtins.attrNames userDisciplineFleet.den.derived;
      expected = [ "foo" ];
    };
  };
}
