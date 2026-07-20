# The ACL / resolution-facet suite (§5). A user registers a join-semilattice merge discipline on
# `den.disciplines.<name>` and consumes it from a `closure = true` derived — the general witness that the
# closure-capability laws-gate (guard (f), the SHARED edges closureMessage) accepts ANY registered join-
# semilattice discipline, not only the framework `reach-closure` instance. `set-union` is the first non-
# framework discipline instance (append-then-membership-dedup, idempotent up to the set the list induces);
# its algebraic laws are proved in the property-laws harness (it rides the compiled-table iteration). This
# suite proves the CONSUMPTION side: a user discipline passes guard (f). It ALSO proves the resolution facet
# COMPOSES + is relation-AGNOSTIC via two node.query witnesses — a reverse membership closure and a forward
# dependency closure, each folding set-union through a resolution product (§3 / §2.3 / §5). See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a fleet registering the USER discipline `set-union` (a join-semilattice, NOT framework-reserved) plus a
  # single `closure = true` derived that names it — the closure laws-gate (guard (f)) reads the compiled
  # disciplines registry, so the user instance must be present for the gate to accept it. The fleet also
  # carries TWO relation graphs (a membership chain + a non-membership dependency chain) and their
  # resolution products, so the capstone witnesses below prove the resolution facet is relation-AGNOSTIC:
  # the SAME machinery (node.query + a set-union discipline + a resolution product) composes over a reverse
  # membership closure AND a forward dependency closure (§3 / §2.3 / §5).
  mkAclFleet =
    name: deriv:
    denHoag.mkDen [
      (
        { config, ... }:
        {
          config.den.schema.node.parent = null;
          config.den.relations.memberOf = {
            inverse = "members";
          };
          # a non-membership relation (no inverse needed — the forward witness follows the forward kind).
          config.den.relations.dependsOn = { };
          config.den.strata.insert.closure = {
            after = "resolution";
          };
          # the resolution products the two witnesses provide (§5) — guard (e) validates each derive's
          # `provides` against this registry (distinct from the den.products materialization faces).
          config.den.resolutionProducts.AclInfo = { };
          config.den.resolutionProducts.DepInfo = { };
          # the user join-semilattice discipline: append-then-membership-dedup (idempotent up to the set the
          # list induces) — the same algebra the property-laws harness samples for its laws.
          config.den.disciplines.set-union = {
            laws = "join-semilattice";
            empty = [ ];
            combine = a: b: a ++ builtins.filter (x: !(builtins.elem x a)) b;
          };
          # a memberOf CHAIN a → b → c (reverse closure `members+` from c is the multi-hop set {b, a}) + a
          # dependsOn CHAIN x → y → z (forward closure `dependsOn+` from x is {y, z}).
          config.den.node.a.edges.memberOf = [ config.den.node.b ];
          config.den.node.b.edges.memberOf = [ config.den.node.c ];
          config.den.node.c = { };
          config.den.node.x.edges.dependsOn = [ config.den.node.y ];
          config.den.node.y.edges.dependsOn = [ config.den.node.z ];
          config.den.node.z = { };
          config.den.derived.${name} = deriv;
        }
      )
    ];

  # the shared set-union closure body (§3 fixpoint over the stratum-scoped query source): a `<label>+`
  # transitive closure folded through the INLINE set-union algebra. `discipline = "set-union"` on the derive
  # is the guard-(f) laws-gate DECLARATION only — the derive receives node/deps, never the disciplines table,
  # so the join-semilattice algebra is written here in `combine` (the registry certifies its laws, §5).
  # `valueOf = x: [ x ]` lifts each reached node-id into the list carrier (the fixpoint default `x: x` would
  # feed bare strings to the list fold).
  setUnionClosure =
    follow: node:
    node.query {
      from = node.id;
      inherit follow;
      mode = "fixpoint";
      empty = [ ];
      combine = acc: xs: acc ++ builtins.filter (x: !(builtins.elem x acc)) xs;
      valueOf = x: [ x ];
    };

  # WITNESS 1 — aclClosure (the spec instance): a REVERSE transitive membership closure over memberOf,
  # set-union-folded, providing an AclInfo resolution product. Exercises the swapped inverse-label arm
  # (`members` ∉ relationKinds — the total relationStratumOf resolves it via the inverse index).
  aclClosureFleet = mkAclFleet "aclClosure" {
    over = [ "memberOf" ];
    direction = "reverse";
    stratum = "closure";
    closure = true;
    discipline = "set-union";
    provides = "AclInfo";
    derive = node: _: setUnionClosure "members+" node;
  };

  # WITNESS 2 — a relation-AGNOSTIC witness: a FORWARD closure over a NON-membership relation (dependsOn),
  # a DIFFERENT resolution product (DepInfo). Same node.query + set-union + resolution-product machinery,
  # a different relation + direction + product ⇒ no memberOf/ACL assumption is baked into the facet.
  depClosureFleet = mkAclFleet "depClosure" {
    over = [ "dependsOn" ];
    direction = "forward";
    stratum = "closure";
    closure = true;
    discipline = "set-union";
    provides = "DepInfo";
    derive = node: _: setUnionClosure "dependsOn+" node;
  };

  # closure=true under the USER-registered join-semilattice discipline `set-union` — lawful (guard (f) accepts a
  # user JSL discipline, not only framework reach-closure). A trivial `derive` satisfies guard (g), so guard (f)
  # (not the missing-derive guard) is what this fixture exercises.
  userDisciplineFleet = mkAclFleet "userDiscipline" {
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
      expected = [ "userDiscipline" ];
    };

    # ── the resolution-facet capstone: two witnesses composing node.query + set-union + a resolution product ──
    # WITNESS 1 (aclClosure): the REVERSE transitive membership set `members+` from node:c over the a → b → c
    # chain = {b, a}, set-union-folded — MULTI-HOP (c ← b ← a; a 1-hop impl yields [node:b] only) and through
    # the swapped inverse-label arm.
    test-acl-closure-reverse-membership = {
      expr = builtins.sort builtins.lessThan (aclClosureFleet.den.derivedAt "aclClosure" "node:c");
      expected = [
        "node:a"
        "node:b"
      ];
    };
    # WITNESS 2 (relation-agnostic): the FORWARD transitive dependency set `dependsOn+` from node:x over the
    # x → y → z chain = {y, z} — the SAME machinery over a DIFFERENT relation + direction + product, proving
    # the resolution facet bakes in no memberOf/ACL assumption. MULTI-HOP (a 1-hop impl misses node:z).
    test-acl-agnostic-forward-dependency = {
      expr = builtins.sort builtins.lessThan (depClosureFleet.den.derivedAt "depClosure" "node:x");
      expected = [
        "node:y"
        "node:z"
      ];
    };
  };
}
