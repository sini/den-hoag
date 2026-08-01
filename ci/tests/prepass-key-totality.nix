# THE PRE-PASS'S PRODUCTS ARE CONSUMED TOTALLY — the `scopeRoots` fold's two pre-pass-sourced injection
# arms, and the class rather than either instance.
#
# THE DEFECT THESE ARMS PIN. The staged pre-pass dispatches over `structuralNodes` — every instance of
# every DECLARED kind — and files each firing's emissions at that firing's own locus. The fold that
# injects them iterates `baseScopeRoots`, which spans `allKinds ∖ cellKinds`. The two key spaces differ in
# SHAPE and not merely in membership: a cell-kind locus is the bare `<kind>:<name>` on the producing side,
# while the node carrying that instance in the main run is `<kind>:<name>@<parent>`, minted by a second
# minter under a different id. So a produced key at a cell-kind locus is not a lookup that misses — it is
# a lookup in a space the key was never in, and before this check the emission was produced, keyed, and
# dropped with no abort anywhere.
#
# THE FIX IS A QUANTIFIER INVERSION, WHICH IS WHY THIS SUITE IS ABOUT A CLASS. `or { }` is correct as the
# CONSUMER's arm — a node with no injection is normal. The arm that was missing is the PRODUCER's: a key
# with no node is not. Both fixtures below are the same fixture with one emission changed, because the
# ruling is over the fold's injections and not over the payload either probe happens to carry.
#
# ★ WHY THE ROWS ARE FIXTURE-SHAPED AND ASSERT NO MESSAGE TEXT. This abort is a `throw`, and Nix cannot
# recover a caught throw's text — `builtins.tryEval` yields a bare `false`. So each row evaluates a fleet
# and reads whether it survives, and every refusal row is paired with a control that differs from it by
# ONE membership tuple. Without those controls a row asserting `false` is satisfied by any broken fixture.
#
# ★ WHY THE KINDS ARE SYNTHETIC. The classification this suite turns on is structural — a childless kind
# with a parent, targeted by a membership tuple — so naming the kinds `host`/`user` would invite the
# reading that the finding is about those kinds. It is about the classification: `env > box > seat`.
{ denHoag, ... }:
let
  inherit (denHoag) sel declare;

  schema.config.den.schema = {
    env.parent = null;
    box.parent = "env";
    seat.parent = "box"; # childless + parented => a CELL-KIND CANDIDATE
  };
  instances.config.den = {
    env.e1 = { };
    box.b1 = { };
    seat.st1 = { };
  };
  # THE TUPLE that flips `seat` from an ordinary root to a CELL kind. In every pair below it is the only
  # difference between the refusing fleet and its control.
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            box = config.den.box.b1;
            seat = config.den.seat.st1;
          };
        }
      ];
    };

  # ── the SUPPRESSIONS arm ─────────────────────────────────────────────────────────────────────────
  victim.config.den.policies.victim = {
    emits = [ ];
    selects = sel.any [ ];
    binds = [ ];
    fn = _ctx: [ ];
  };
  excluderWith = selects: {
    config.den.policies.drop-victim = {
      inherit selects;
      emits = [ "suppress" ];
      suppresses = [ "victim" ];
      binds = [ ];
      fn = _ctx: [ (declare.suppress { name = "victim"; }) ];
    };
  };

  # ── the CONTAINMENT-BINDINGS arm ─────────────────────────────────────────────────────────────────
  # A BINDINGS-ONLY containment emission (empty source slice — the pass's own documented legitimate
  # shape) mints NO attachment, so this arm is isolated from the attachment path.
  binderAt =
    dim:
    { config, ... }:
    {
      config.den.policies.bind-target = {
        selects = sel.attrs { type = "env"; };
        emits = [ "member" ];
        binds = [ "mark" ];
        fn = _ctx: [
          (declare.member {
            coords.${dim} = config.den.${dim}.${if dim == "seat" then "st1" else "b1"};
            containTo = dim;
            bindings.mark = "arrived";
          })
        ];
      };
    };

  base = [
    schema
    instances
  ];
  # Forcing the fold: every node's `decls` runs it, and `decls` is what the injections land on.
  survives =
    mods:
    (builtins.tryEval (
      builtins.deepSeq (
        let
          den = (denHoag.mkDen mods).den;
        in
        map (id: (den.structural.eval.node id).decls) (builtins.attrNames den.structural.eval.allNodes)
      ) true
    )).success;
in
{
  flake.tests.prepass-key-totality = {
    # ARM 1 — SUPPRESSIONS. An exclude-family emission whose locus is a cell-kind instance is keyed at
    # the bare id and no root claims it. Every row here is the same policy body and the same codomain;
    # only the selector and the membership tuple move.
    test-suppressions-at-a-cell-kind-locus-abort = {
      expr = {
        # THE REFUSAL: `seat` is a cell kind and the excluder selects exactly it. The pre-pass produces
        # `suppressions` at `seat:st1`; `baseScopeRoots` holds `env:e1` and `box:b1` only.
        cellKindLocus = survives (
          base
          ++ [
            membership
            victim
            (excluderWith (sel.attrs { type = "seat"; }))
          ]
        );
        # CONTROL — the SAME selector on a fleet whose only difference is the absent membership tuple, so
        # `seat` is an ordinary root and the key is claimed. This is what makes the row above a drop
        # rather than a fixture that could not evaluate.
        sameSelectorSeatIsARoot = survives (
          base
          ++ [
            victim
            (excluderWith (sel.attrs { type = "seat"; }))
          ]
        );
        # CONTROL — the same cell-kind fleet with the excluder at the PARENT kind: the root claims the
        # key, and the cell receives the suppression by inheritance. The mechanism works; the locus is
        # the whole question.
        parentKindLocus = survives (
          base
          ++ [
            membership
            victim
            (excluderWith (sel.attrs { type = "box"; }))
          ]
        );
      };
      expected = {
        cellKindLocus = false;
        sameSelectorSeatIsARoot = true;
        parentKindLocus = true;
      };
    };

    # ARM 2 — CONTAINMENT BINDINGS. The fold's SIBLING arm, and the reason the ruling is over the class:
    # `containmentBindings` keys off the pass's target index, which resolves through EVERY registry kind,
    # while the fold consuming it spans root kinds only. Identical shape, different payload.
    test-containment-bindings-at-a-cell-kind-target-abort = {
      expr = {
        # THE REFUSAL: the binding targets the `seat` instance in a fleet where a tuple made `seat` a
        # cell kind. `containmentBindings` is keyed at `seat:st1`, which no root claims.
        cellKindTarget = survives (
          base
          ++ [
            membership
            (binderAt "seat")
          ]
        );
        # CONTROL — the same emission where `seat` is a root.
        sameEmissionSeatIsARoot = survives (base ++ [ (binderAt "seat") ]);
        # CONTROL — the same cell-kind fleet, the same policy, a ROOT-kind target: it lands. So the pass
        # fires, the emission path resolves and the fold injects, in the fleet where the other vanishes.
        rootKindTarget = survives (
          base
          ++ [
            membership
            (binderAt "box")
          ]
        );
      };
      expected = {
        cellKindTarget = false;
        sameEmissionSeatIsARoot = true;
        rootKindTarget = true;
      };
    };

    # THE CLASS, ASSERTED AS A CLASS. The two arms above could each be discharged by a guard written at
    # its own payload; what the ruling states is that ONE helper covers every pre-pass-sourced injection,
    # so the two aborts must be the same construction and not two coincidences. The observable that says
    # so is that both fleets refuse under the SAME tuple and admit without it — and that `systemView`,
    # which is injected by the same fold from an authored surface keyed by SYSTEM rather than by node, is
    # NOT in the class and does not refuse on an unclaimed key.
    test-the-class-is-the-pre-pass-sourced-arms-only = {
      expr = {
        bothArmsRefuseUnderTheSameTuple =
          !(survives (
            base
            ++ [
              membership
              victim
              (excluderWith (sel.attrs { type = "seat"; }))
            ]
          ))
          && !(survives (
            base
            ++ [
              membership
              (binderAt "seat")
            ]
          ));
        # `den.systemViews` keyed at a system no node carries: an unclaimed key there is not a lost
        # emission, so the fold folds nothing and the fleet evaluates.
        systemViewWithNoCarrierIsNotInTheClass = survives (
          base
          ++ [
            membership
            { config.den.systemViews.nowhere-linux.injected = "x"; }
          ]
        );
      };
      expected = {
        bothArmsRefuseUnderTheSameTuple = true;
        systemViewWithNoCarrierIsNotInTheClass = true;
      };
    };
  };
}
