# The typed suppression control-fact carrier: `suppressedPolicies` is a first-class decls slot delivered
# by the `suppressed-policies` inherited attribute (gen-scope `inheritSet`, self ∪ ancestors down the
# P-edge parent chain, deduped) rather than the retired reserved-decls marker. Two properties are pinned
# here, driving the REAL structural equations over a hand-built P-edge chain (env → host → user cell, the
# containment shape a suppression is delivered along), suppression sets supplied directly on node decls
# (the pre-pass produce is a separate concern):
#
#   (A) DELIVERY — the carrier reaches every scope-subtree descendant of a suppressing root (the v1
#       scope+ancestors consult, dispatch-policies.nix:15-33): the user cell's `suppressed-policies`
#       carries its host's AND its env's suppression names.
#   (B) THE UNION FIX — two suppressing ancestors at DIFFERENT depths COMPOSE. A single-key `//`-shadow
#       (the generic inherited-context merge `layer // acc`, nearest-shadows-farthest) keeps only the
#       NEAREST ancestor's value for a one-key slot, silently dropping the farther; `inheritSet`'s true
#       union keeps both. The corpus is
#       sibling-isolated to ONE suppressor, so this is corpus-zero — the net-new multi-suppressor case the
#       union makes correct. The old-shadow result is computed inline (same inputs, old carrier) to witness
#       the drop the new carrier fixes (red-before / green-after in one file, no revert).
#   (C) NO RE-LEAK — the typed slot is stripped from the generic inherited-context (it rides ONLY its own
#       carrier), so a policy/settings read never sees the control-fact as an ordinary binding.
{ denHoag, ... }:
let
  I = denHoag.internal;
  # The structural feeds arrive KIND-INDEXED (`indexPolicyFeed kinds feed` -> `kind -> [rule]`), selecting
  # on each rule's declared `selects`. An empty kind list memoises nothing, so every lookup takes the
  # index's total fallback and computes the real selection — the fixture exercises the shipped predicate
  # rather than a hand-rolled stand-in of it.
  idxFeed = I.indexPolicyFeed [ ];
  inherit (I)
    structural
    runResolve
    parseParent
    ;

  # A hand-built P-edge chain (the `parent` field wires each node to its ancestor, the inheritAll walk):
  # env:e (grandparent, suppresses `p-far`) → host:h (parent, suppresses `p-near`) → user:u (leaf, none).
  # Two suppressing ancestors at DIFFERENT depths — the union case the corpus never exercises.
  envId = "env:e";
  hostId = "host:h";
  cellId = "user:u";
  roots = {
    ${envId} = {
      id = envId;
      type = "env";
      parent = null;
      decls = {
        suppressedPolicies = [ "p-far" ];
        __entry = { };
      };
    };
    ${hostId} = {
      id = hostId;
      type = "host";
      parent = envId;
      decls = {
        suppressedPolicies = [ "p-near" ];
        __entry = { };
      };
    };
    ${cellId} = {
      id = cellId;
      type = "user";
      parent = hostId;
      decls = {
        __entry = { };
      };
    };
  };
  noChildren = _self: _id: { };

  res = runResolve {
    inherit roots parseParent;
    equations = structural {
      policiesIndex = {
        enrich = idxFeed [ ];
        policy = idxFeed [ ];
      };
      fleetChildren = noChildren;
    };
  };
  suppressedAt = id: res.eval.get id "suppressed-policies";
  ctxAt = id: res.eval.get id "inherited-context";

  # The OLD single-key `//`-shadow reproduced over the SAME three layers (nearest-first, as
  # inherited-context folds `layer // acc` nearest-shadows-farthest): only one `suppressedPolicies` key
  # survives — the NEAREST ancestor's — silently dropping the farther. This is the latent bug the typed
  # union carrier fixes.
  oldShadow = builtins.foldl' (acc: layer: layer // acc) { } [
    roots.${cellId}.decls
    roots.${hostId}.decls
    roots.${envId}.decls
  ];
in
{
  flake.tests.suppression-inherit-set = {
    # (A) delivery: the user cell inherits BOTH ancestors' suppression names (self ∪ ancestors,
    #     nearest-first: host `p-near` then env `p-far`).
    test-cell-inherits-both-ancestors = {
      expr = builtins.sort (a: b: a < b) (suppressedAt cellId);
      expected = [
        "p-far"
        "p-near"
      ];
    };
    # (A) delivery at the intermediate host: its own `p-near` ∪ its env's `p-far`.
    test-host-inherits-self-and-env = {
      expr = builtins.sort (a: b: a < b) (suppressedAt hostId);
      expected = [
        "p-far"
        "p-near"
      ];
    };
    # (A) the root env carries only its own set.
    test-env-carries-own-only = {
      expr = suppressedAt envId;
      expected = [ "p-far" ];
    };
    # (B) the union FIX: the old `//`-shadow kept only the NEAREST ancestor (`p-near`), dropping the farther
    #     `p-far` — the latent single-key bug. inheritSet composes both. The two carriers DIFFER on the
    #     same input, witnessing the correction (corpus-zero: only reachable with ≥2 suppressing ancestors).
    test-old-shadow-drops-farther = {
      expr = oldShadow.suppressedPolicies;
      expected = [ "p-near" ];
    };
    test-union-composes-where-shadow-dropped = {
      expr = (builtins.length (suppressedAt cellId)) > (builtins.length oldShadow.suppressedPolicies);
      expected = true;
    };
    # (C) no re-leak: the typed control-fact is stripped from the generic inherited-context — a binding
    #     read at the cell never sees `suppressedPolicies` as an ordinary decl.
    test-slot-stripped-from-generic-context = {
      expr = (ctxAt cellId) ? suppressedPolicies;
      expected = false;
    };
  };
}
