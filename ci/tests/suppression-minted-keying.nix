# The pre-pass SUPPRESSION map's KEY SPACE. `runPrePass` iterates `structuralNodes`, which is built
# with no attachments, so its ids are always the bare `kind:name`. The consumer is a MEMBERSHIP TEST over
# `baseScopeRoots`, which IS built with `prePass.containmentAttachments` — so at N≥2 attachments the id it
# indexes with is the MINTED `kind:name@parent` and a bare-keyed map simply misses. No error, no warning:
# the suppression vanishes exactly where the node multiplies.
#
# Three arms over ONE topology (synthetic kinds, `zone <- rack`), differing only in the zone count and the
# presence of the suppressor:
#
#   N=2 (the fix)          two zones claim rack:r1 -> `rack:r1@zone:z1` + `rack:r1@zone:z2`, and the
#                          suppression must reach BOTH. The bare id names no node here, which is pinned
#                          alongside so a regression in minting cannot make this arm pass vacuously.
#   N=1 (positive control) one zone -> `mintedRootId` keeps the bare id, and the same suppression is read
#                          off it by the same predicate in the same run. This is what says a red N=2 arm is
#                          about the KEYING and not about the suppressor never having fired.
#   no suppressor          same two-zone topology with the policy removed -> both minted nodes carry the
#                          empty set, so a populated result in the arms above is a real delivery rather
#                          than a default the reader would have got anyway.
#
# Values are pinned, not presence: the defect's shape is a set that is silently EMPTY, and `? key` would be
# satisfied by an empty list arriving for the wrong reason.
{ denHoag, ... }:
let
  inherit (denHoag) sel;
  inherit (denHoag) declare;

  # `zone <- rack <- blade`. The third level is load-bearing rather than decorative: the pre-pass runs over
  # the NON-CANDIDATE kinds, and a candidate is a childless kind with a parent. Were `rack` the leaf it
  # would be a candidate, no pre-pass root would be a rack, and the suppressor would never fire — an arm
  # that reads exactly like the defect. `blade` needs no instances; declaring it makes `rack` a parent kind.
  schema = {
    config.den.schema = {
      zone.parent = null;
      rack.parent = "zone";
      blade.parent = "rack";
    };
  };

  oneZone = {
    config.den = {
      zone.z1 = { };
      rack.r1 = { };
    };
  };
  twoZones = {
    config.den = {
      zone.z1 = { };
      zone.z2 = { };
      rack.r1 = { };
    };
  };

  # THE CONTAINMENT SOURCE: every zone claims rack r1. With two zones that is two attachments on one
  # target, which is the whole condition under test — `buildRoots` multiplies the node rather than the
  # parent, and the ids stop being bare.
  claimRack =
    { config, ... }:
    {
      config.den.policies.claim-rack = {
        emits = [ "member" ];
        selects = sel.star;
        binds = [ ];
        fn =
          { zone, ... }:
          [
            (declare.member {
              coords = {
                inherit zone;
                rack = config.den.rack.r1;
              };
              containTo = "rack";
            })
          ];
      };
    };

  # THE SUPPRESSOR, firing at the rack. A `suppress`-emitting structural policy is the exclude family by
  # DERIVATION (concern-policies filters the rules on their declared codomain), so this lands in the
  # pre-pass's exclude feed without any name-set knob.
  suppressAtRack =
    { config, ... }:
    {
      config.den.policies.drop-victim = {
        selects = sel.attrs { type = "rack"; };
        emits = [ "suppress" ];
        suppresses = [ "victim" ];
        fn =
          { rack, ... }:
          builtins.seq rack [ (declare.suppress { name = "victim"; }) ];
      };
    };

  mk = mods: (denHoag.mkDen ([ schema ] ++ mods)).den;

  n1 = mk [
    oneZone
    claimRack
    suppressAtRack
  ];
  n2 = mk [
    twoZones
    claimRack
    suppressAtRack
  ];
  n2Bare = mk [
    twoZones
    claimRack
  ];

  suppressedAt = den: id: den.structural.eval.get id "suppressed-policies";
in
{
  flake.tests.suppression-minted-keying = {
    # ── N≥2: the suppression reaches BOTH minted nodes. `eval.get` throws on a node that does not exist,
    #    so a minting regression fails loudly here rather than reading as an absent suppression. ──────────
    test-suppression-reaches-both-minted-nodes = {
      expr = {
        z1 = suppressedAt n2 "rack:r1@zone:z1";
        z2 = suppressedAt n2 "rack:r1@zone:z2";
        bare = n2.scopeRoots ? "rack:r1";
      };
      expected = {
        z1 = [ "victim" ];
        z2 = [ "victim" ];
        bare = false;
      };
    };

    # ── the N=1 POSITIVE CONTROL, same predicate, same run: one attachment keeps the bare id, so the map's
    #    key and the node's id coincide and the suppression is read off the single node. ─────────────────
    test-single-attachment-keeps-bare-id = {
      expr = {
        bare = suppressedAt n1 "rack:r1";
        minted = n1.scopeRoots ? "rack:r1@zone:z1";
      };
      expected = {
        bare = [ "victim" ];
        minted = false;
      };
    };

    # ── the NEGATIVE CONTROL: drop the suppressor and the same two nodes carry nothing, so the populated
    #    sets above are a delivery and not the shape of an unconditioned default. ─────────────────────────
    test-no-suppressor-yields-empty = {
      expr = {
        z1 = suppressedAt n2Bare "rack:r1@zone:z1";
        z2 = suppressedAt n2Bare "rack:r1@zone:z2";
      };
      expected = {
        z1 = [ ];
        z2 = [ ];
      };
    };
  };
}
