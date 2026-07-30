# THE CONTAINMENT CYCLE GUARD IS FORCED BY EVERY PRODUCT OF THE PRE-PASS, not by the accident of which
# one a consumer happens to demand.
#
# THE DEFECT THIS PINS. The guard used to live inside `containmentAttachments`, so it was consulted on
# exactly ONE demand path. `membershipTuples` reaches the pre-pass through `tuples`, which walks the same
# `byTarget` edge pool and never touched the guard — measured: forcing `membershipTuples` on the cyclic
# fleet below exited 0 and published a clean answer over a cyclic containment topology, while forcing
# `scopeRoots` or `containsEdges` on the SAME fleet aborted. Soundness by demand order is not soundness:
# it holds only while nobody adds a consumer, and the consumer set is not a thing anyone re-verifies.
#
# THE CONSTRUCTION. One `cycleChecked` is computed per pass and applied across the export record with
# `mapAttrs`, so membership in the record IMPLIES guarding and a future sixth export cannot arrive
# unguarded. `rawContainEdges` stays private so the guard's own walk does not re-enter the guarded
# accessor.
#
# WHY A CYCLE IS AUTHORABLE AT ALL, and why this fixture uses `den.attach`. The POLICY route cannot build
# one: its containment edges are forced through `kindParent K -> K`, strictly descending the acyclic
# schema. The `den.attach` route builds `sourceSlice` directly, so a SELF-PARENT kind
# (`den.schema.node.parent = "node"`) plus mutual `ref`s closes the loop — `a` names `b` as its parent and
# `b` names `a`.
#
# ARMED AGAINST WRONG IMPLEMENTATIONS:
#   (a) the tuple path aborts        — fails an implementation that guards only the attachments map;
#   (b) the acyclic control attaches — fails an implementation that aborts on everything, which (a) alone
#                                      would pass, and proves the attach route is live rather than inert;
#   (c) the acyclic tuple demand     — the SAME demand as (a) on a fleet differing only in the cycle;
#   (d)+(e) the old paths still fire — fails an implementation that moved the guard and lost the coverage
#                                      it already had.
# The abort arms pin the MESSAGE, not a success boolean: a bare `tryEval` failure would be satisfied by
# any error at all, including one from the fixture being malformed.
{
  lib,
  denHoag,
  ...
}:
let
  # `peer` is `nullOr` with a null default, not a string with an empty default: the attach route treats a
  # null ref as "no attachment" and any other unresolvable value as a typo that aborts NAMED, so a
  # non-attaching entity must carry null rather than "".
  kindOpts = _: {
    options.peer = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  fleet =
    nodes:
    (denHoag.mkDen [
      {
        # SELF-PARENT: the schema's containment topology is a loop of length one at the KIND level, which
        # is what lets two INSTANCES of it contain each other.
        config.den.schema.node = {
          parent = "node";
          imports = [ kindOpts ];
        };
        config.den.attach.node.ref = "peer";
        config.den.node = nodes;
      }
    ]).den;

  cyclic = fleet {
    a.peer = "b";
    b.peer = "a";
  };
  # Identical in every respect but the closing edge: `b` names no parent, so the relation is the single
  # edge `a <- b` and the same machinery runs to completion.
  acyclic = fleet {
    a.peer = "b";
    b = { };
  };

  parentsOf = d: builtins.mapAttrs (_: v: v.parent) d.scopeRoots;
  cycleAbort = {
    type = "ThrownError";
    msg = "containment-relation ancestor chain revisits node";
  };
in
{
  flake.tests.containment-cycle-guard = {
    # (a) THE ARM THAT WAS RED. The tuple demand never touched the guard; it now aborts NAMED.
    test-membership-tuples-abort-on-cycle = {
      expr = builtins.deepSeq cyclic.membershipTuples "unreached";
      expectedError = cycleAbort;
    };

    # (b) THE POSITIVE CONTROL, and it is the one with teeth: the acyclic fleet resolves parentage to a
    # real edge. An implementation that aborted unconditionally, or one whose attach route emitted
    # nothing, fails here — so a green (a) cannot be a fixture that simply never built a relation.
    test-acyclic-control-attaches = {
      expr = parentsOf acyclic;
      expected = {
        "node:a" = "node:b";
        "node:b" = null;
      };
    };

    # (c) THE SAME DEMAND AS (a), on the fleet that differs only in the cycle. Pinned as a VALUE: no
    # policy emits a `member` here, so the derived tuple set is empty, and forcing it to compare against
    # the empty list still forces the guard.
    test-acyclic-control-tuples-resolve = {
      expr = acyclic.membershipTuples;
      expected = [ ];
    };

    # (d)+(e) THE PATHS THAT ALREADY ABORTED STILL ABORT. Moving a guard is the shape that silently trades
    # new coverage for old, so both previously-guarded demands are pinned by the same message.
    test-scope-roots-still-abort-on-cycle = {
      expr = builtins.deepSeq cyclic.scopeRoots "unreached";
      expectedError = cycleAbort;
    };
    test-contains-edges-still-abort-on-cycle = {
      expr = builtins.deepSeq cyclic.containsEdges "unreached";
      expectedError = cycleAbort;
    };
  };
}
