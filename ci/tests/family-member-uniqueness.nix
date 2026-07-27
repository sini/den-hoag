# The family-product fold's MEMBER-UNIQUENESS guard (§4.4 face law, lib/default.nix `familyMergeAt`).
#
# The face law emits ONE entry per member, keyed by entity name and unique per class. The fold's merge used
# to ASSUME that in a comment while its recursion guard was `isAttrs a && isAttrs b` — and a built
# configuration IS an attrset, so two contributions to one member silently recursed INTO both artifacts and
# merged them attribute-by-attribute, letting whichever side landed second win on scalars. Measured on the
# corpus once environments materialised: `nixosConfigurations.axon-01` received two contributions, only one
# of which had passed the nixos terminal, so the merged result lost `nixpkgs.hostPlatform` entirely.
#
# The guard bounds recursion to the two levels the law actually defines — families merge their MEMBER SETS,
# a member's artifact is never descended — and a duplicate member ABORTS NAMED instead of merging.
{
  denHoag,
  ...
}:
let
  inherit (denHoag.internal) familyMerge;

  # The fold's real seed shape: every declared family present and empty.
  seed = {
    nixosConfigurations = { };
    darwinConfigurations = { };
  };
  cfgA = {
    _type = "configuration";
    config.marker = "A";
  };
  cfgB = {
    _type = "configuration";
    config.marker = "B";
  };

  # one contribution, the shape every single-attachment entity produces
  oneMember = familyMerge seed { nixosConfigurations.axon-01 = cfgA; };
  # a SECOND contribution naming a DIFFERENT member — legitimate, must not fire
  twoMembers = familyMerge oneMember { nixosConfigurations.blade = cfgB; };
  # a second contribution naming the SAME member — the defect, must fire
  duplicate = familyMerge oneMember { nixosConfigurations.axon-01 = cfgB; };
in
{
  flake.tests.family-member-uniqueness = {
    # ── the CONTROL half: the guard must NOT fire on any legitimate shape ────────────────────────────
    # Distinct members under one family merge, and the FIRST contribution's artifact survives intact —
    # pinning the value, not just the key set, so a guard that silently clobbered members would fail here.
    test-distinct-members-merge = {
      expr = {
        members = builtins.attrNames twoMembers.nixosConfigurations;
        firstIntact = twoMembers.nixosConfigurations.axon-01.config.marker;
        secondIntact = twoMembers.nixosConfigurations.blade.config.marker;
      };
      expected = {
        members = [
          "axon-01"
          "blade"
        ];
        firstIntact = "A";
        secondIntact = "B";
      };
    };

    # The same member NAME under a DIFFERENT family is not a duplicate — the guard keys on
    # `[ family, member ]`, so this must stay green. Without it, a guard keyed on the member name alone
    # would pass every other test here and still be wrong.
    test-same-name-different-family-ok = {
      expr =
        builtins.attrNames
          (familyMerge oneMember { darwinConfigurations.axon-01 = cfgB; }).darwinConfigurations;
      expected = [ "axon-01" ];
    };

    # ── the ARMED half: the guard must fire, and for ITS OWN reason ──────────────────────────────────
    # Forcing only `attrNames` is the load-bearing detail. The guard reads the KEY SETS, so it aborts
    # while the member VALUES are still unforced; any downstream/value-level failure would let
    # `attrNames` succeed. So a `true` here can only have come from this guard, not from something
    # deeper aborting first. Paired with `test-distinct-members-merge`, which differs ONLY in the second
    # contribution's member name, the abort is attributable to the duplication itself.
    test-duplicate-member-aborts-on-key-set = {
      expr = (builtins.tryEval (builtins.attrNames duplicate.nixosConfigurations)).success;
      expected = false;
    };

    # The negative twin of the above: the SAME forcing depth on the SAME shape minus the duplication
    # succeeds. Without this, a `success = false` above could equally mean "attrNames throws here for
    # some unrelated reason".
    test-control-succeeds-at-same-forcing-depth = {
      expr = (builtins.tryEval (builtins.attrNames twoMembers.nixosConfigurations)).success;
      expected = true;
    };
  };
}
