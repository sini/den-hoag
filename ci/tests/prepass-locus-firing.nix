# The DELIVER firing LOCUS. `runPrePass` iterates `structuralNodes`, whose ids are bare because that
# population is built with no attachments; `containmentBindings` is keyed by the MINTED node ids. A firing
# at the bare id therefore reads `containmentBindings.<bare> or { }` — the EMPTY slice — at every target
# claimed by more than one source, and an empty slice is byte-identical to "this node has no bindings".
#
# ★★ THE LOSS IS NOT A MISSING ROW, IT IS A CLASSIFICATION FLIP, and that is why two things are pinned
# rather than one. `tupleDimKinds` is computed FROM `membershipTuples`, so an empty tuple set empties
# `cellKinds`, degenerates `dimKinds` to the all-registries product, and RE-MATERIALIZES the candidate
# kind's instances as ROOT nodes. A fixture asserting only the tuple would pass while the product stayed
# degenerate, so the node population is pinned separately from the tuple.
#
# TWO ARMS, because two body shapes reach the binding by different routes and only one of them is
# obviously at risk:
#   ARM-V  VALUE-CONDITIONAL — a bare `ctx:` body branching on the binding's presence. Its gate admits it
#          everywhere, so it fires at every locus and emits only where the value arrived.
#   ARM-G  REQUIRED FORMAL — `{ pick, ... }:`, the shape a v1 lowering produces. Here the binding is a
#          DISPATCH GATE, so a missing slice does not take a false branch, it declines the firing.
#
# TWO CONFOUND CONTROLS, each removing a different alternative explanation of a red arm:
#   SAME VALUE BOTH SOURCES  both zones bind the same value ⇒ the tuple must still be produced. If the
#                            loss were slice CONFLICT this arm would fail too; it does not, so the loss is
#                            the KEYING.
#   TWO ZONES, ONE ATTACHMENT  two sources exist but only one claims the target ⇒ N=1, and the emitter
#                            must fire. This says the variable is the ATTACHMENT COUNT, not the number of
#                            zones in the fleet.
#
# And the N=1 POSITIVE CONTROL runs the same predicate over the same topology at one attachment, so a red
# N=2 arm cannot be read as "the emitter never fired at all".
{ denHoag, ... }:
let
  inherit (denHoag) sel;
  inherit (denHoag) declare;

  # `zone <- rack <- blade`. `blade` is the CANDIDATE cell kind (childless, parented); `rack` is a
  # parent kind and therefore a pre-pass root the emitter fires at.
  schema = {
    config.den.schema = {
      zone.parent = null;
      rack.parent = "zone";
      blade.parent = "rack";
    };
  };

  instances = zones: {
    config.den = {
      zone = builtins.listToAttrs (
        map (z: {
          name = z;
          value = { };
        }) zones
      );
      rack.r1 = { };
      blade.b1 = { };
      blade.b2 = { };
    };
  };

  # THE CONTAINMENT SOURCE: each zone in `picks` claims rack r1 and carries a per-source binding. Two
  # claiming zones ⇒ two attachments on one target ⇒ two nodes, each with only its own claimer's slice. A
  # zone absent from `picks` exists in the fleet but claims nothing, which is how the attachment count is
  # varied independently of the zone count.
  claimRack =
    picks:
    { config, ... }:
    {
      config.den.policies.claim-rack = {
        emits = [ "member" ];
        selects = sel.star;
        binds = [ "pick" ];
        fn =
          { zone, ... }:
          if picks ? ${zone.name} then
            [
              (declare.member {
                coords = {
                  inherit zone;
                  rack = config.den.rack.r1;
                };
                bindings.pick = picks.${zone.name};
                containTo = "rack";
              })
            ]
          else
            [ ];
      };
    };

  # ARM-V — a bare `ctx:` body reading the binding as a VALUE. Fires wherever it is selected; emits only
  # where `pick` actually arrived.
  emitByValue =
    { config, ... }:
    {
      config.den.policies.seat-by-value = {
        selects = sel.attrs { type = "rack"; };
        emits = [ "member" ];
        binds = [ ];
        fn =
          ctx:
          if (ctx.pick or null) != null then
            [
              (declare.member {
                rack = ctx.rack;
                blade = config.den.blade.${ctx.pick};
              })
            ]
          else
            [ ];
      };
    };

  # ARM-G — the required-formal shape: `pick` is a DISPATCH GATE, so an absent slice declines the firing
  # rather than taking a false branch. Same emission, different reason for its absence.
  emitByFormal =
    { config, ... }:
    {
      config.den.policies.seat-by-formal = {
        selects = sel.attrs { type = "rack"; };
        emits = [ "member" ];
        binds = [ ];
        fn =
          { rack, pick, ... }:
          [
            (declare.member {
              inherit rack;
              blade = config.den.blade.${pick};
            })
          ];
      };
    };

  mk = mods: (denHoag.mkDen ([ schema ] ++ mods)).den;

  # The observable: which blade each tuple names, and at which LOCUS it was emitted.
  seatsOf =
    den:
    builtins.sort (a: b: a < b) (
      map (t: "${t.coords.blade.name}@${t.via.scope}") (
        builtins.filter (t: t.coords ? blade) den.membershipTuples
      )
    );
  # The classification observable: a targeted candidate must be a CELL, never a root scope node.
  bladeRootsOf =
    den:
    builtins.sort (a: b: a < b) (
      builtins.filter (id: builtins.substring 0 6 id == "blade:") (builtins.attrNames den.scopeRoots)
    );

  differing = {
    z1 = "b1";
    z2 = "b2";
  };
  same = {
    z1 = "b1";
    z2 = "b1";
  };

  n2Value = mk [
    (instances [
      "z1"
      "z2"
    ])
    (claimRack differing)
    emitByValue
  ];
  n2Formal = mk [
    (instances [
      "z1"
      "z2"
    ])
    (claimRack differing)
    emitByFormal
  ];
  n1Value = mk [
    (instances [ "z1" ])
    (claimRack differing)
    emitByValue
  ];
  n1Formal = mk [
    (instances [ "z1" ])
    (claimRack differing)
    emitByFormal
  ];
  n2Same = mk [
    (instances [
      "z1"
      "z2"
    ])
    (claimRack same)
    emitByValue
  ];
  # TWO zones in the fleet, ONE attachment on the target: the second confound control.
  twoZonesOneAttach = mk [
    (instances [
      "z1"
      "z2"
    ])
    (claimRack { z1 = "b1"; })
    emitByValue
  ];
in
{
  flake.tests.prepass-locus-firing = {
    # ── N≥2, BOTH ARMS: the emitter fires once per locus, against that locus's own slice, so each minted
    #    node contributes the seat ITS claimer's binding names. One firing at the bare root cannot produce
    #    this pair — it has one ctx and would emit one tuple or none. ─────────────────────────────────────
    test-both-arms-emit-per-locus = {
      expr = {
        value = seatsOf n2Value;
        formal = seatsOf n2Formal;
      };
      expected = {
        value = [
          "b1@rack:r1@zone:z1"
          "b2@rack:r1@zone:z2"
        ];
        formal = [
          "b1@rack:r1@zone:z1"
          "b2@rack:r1@zone:z2"
        ];
      };
    };

    # ── the N=1 POSITIVE CONTROLS, same predicate, same run: one attachment keeps the bare id, so the
    #    locus IS the root and both arms emit exactly as they always did. A red arm above is therefore
    #    about the multiplication and not about the emitter never having fired. ───────────────────────────
    test-single-attachment-controls = {
      expr = {
        value = seatsOf n1Value;
        formal = seatsOf n1Formal;
      };
      expected = {
        value = [ "b1@rack:r1" ];
        formal = [ "b1@rack:r1" ];
      };
    };

    # ── CONFOUND CONTROL 1 — SAME VALUE FROM BOTH SOURCES. The slices no longer disagree, so if the loss
    #    were a conflict between two candidate values this arm would still be empty. It is not: both loci
    #    fire and the UNION of their emissions is what reaches the fleet. ⇒ the variable is the KEYING. ───
    test-same-value-both-sources-produces-union = {
      expr = seatsOf n2Same;
      expected = [
        "b1@rack:r1@zone:z1"
        "b1@rack:r1@zone:z2"
      ];
    };

    # ── CONFOUND CONTROL 2 — TWO ZONES, ONE ATTACHMENT. The fleet has the same number of sources as the
    #    N=2 arms, but only one of them claims the target, so the node is not multiplied and the emitter
    #    fires at the bare id. ⇒ the variable is the ATTACHMENT COUNT, not the source count. ──────────────
    test-two-sources-one-attachment-fires = {
      expr = seatsOf twoZonesOneAttach;
      expected = [ "b1@rack:r1" ];
    };

    # ── THE CLASSIFICATION, pinned SEPARATELY because it is a different observable. An empty tuple set
    #    empties `cellKinds`, degenerates `dimKinds` to the all-registries product, and re-materializes the
    #    candidate kind's instances as ROOT nodes. A fixture asserting only the tuple would pass while the
    #    product stayed degenerate, so the node population and the dims are asserted in their own right. ──
    test-classification-restored-at-multiplied-root = {
      expr = {
        n2Roots = bladeRootsOf n2Value;
        n2Dims = n2Value.dimKinds;
        n1Roots = bladeRootsOf n1Value;
        n1Dims = n1Value.dimKinds;
      };
      expected = {
        n2Roots = [ ];
        n2Dims = [
          "blade"
          "rack"
        ];
        n1Roots = [ ];
        n1Dims = [
          "blade"
          "rack"
        ];
      };
    };

    # ── THE LOCUS IS RECORDED. `via.scope` is read at exactly one site — fleet.nix's `disciplineOk`, in
    #    the `errors.memberAtCell` abort text — so a bare id there would name a node that does not exist
    #    at a multiplied target. Pinned as node ids that ARE in `scopeRoots`, which is what makes the
    #    claim "names a real node" rather than "has the shape of one". ────────────────────────────────────
    test-via-scope-names-an-existing-node = {
      expr = map (t: n2Value.scopeRoots ? ${t.via.scope}) (
        builtins.filter (t: t.coords ? blade) n2Value.membershipTuples
      );
      expected = [
        true
        true
      ];
    };
  };
}
