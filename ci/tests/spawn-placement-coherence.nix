# The SLICE/TARGET COHERENCE guard for a parked spawn (lib/default.nix `placementNamesNode`).
#
# A spawn slices `classSubtreeAt` at the node its spec is parked at and places the result at the spec's
# `intoAttr`. Those must name the same entity. A spec parked at A, slicing A, targeting a member of B
# publishes one node's content under another node's name — wrong whether or not anything else contributes
# to B. Measured live: an environment-parked spawn targeting a host emitted an EMPTY slice into that
# host's member, which presents as a missing output rather than as wrong content. That is the mild
# presentation of the defect, not a different one.
#
# The rule is LAST-SEGMENT identity, deliberately not one-to-one: a spec may fan one entity's content
# across an axis (`<family>.<system>.<entity>`), and every such placement still ends in the entity's own
# name. A one-to-one rule rejects that legitimate shape; a family-name rule misses entities in other
# families entirely.
{
  denHoag,
  ...
}:
let
  inherit (denHoag.internal) placementNamesNode;
in
{
  flake.tests.spawn-placement-coherence = {
    # ── SILENT on every legitimate shape ─────────────────────────────────────────────────────────────
    # The direct case (a host publishing its own capture) and the FAN-OUT case (one cluster's content
    # across a system axis) — the shape a one-to-one rule would have wrongly rejected.
    test-coherent-placements-pass = {
      expr = {
        direct = placementNamesNode "axon-01" [
          "colmenaModules"
          "axon-01"
        ];
        fanOut =
          map
            (
              system:
              placementNamesNode "axon" [
                "nixidyEnvs"
                system
                "axon"
              ]
            )
            [
              "x86_64-linux"
              "aarch64-linux"
              "aarch64-darwin"
            ];
        # an empty placement places verbatim and names no member, so there is nothing to disagree with
        verbatim = placementNamesNode "axon-01" [ ];
      };
      expected = {
        direct = true;
        fanOut = [
          true
          true
          true
        ];
        verbatim = true;
      };
    };

    # ── FIRES on a cross-entity target ───────────────────────────────────────────────────────────────
    # Both live shapes: an environment publishing a host's member, and the same across a third family.
    # Pinned as a SET rather than one case, so a rule that happened to reject only one still fails.
    test-cross-entity-placements-rejected = {
      expr = {
        envToHost = placementNamesNode "prod" [
          "nixosConfigurations"
          "axon-01"
        ];
        envToDroidHost = placementNamesNode "dev" [
          "nixOnDroidConfigurations"
          "slab"
        ];
        envToDarwinHost = placementNamesNode "dev" [
          "darwinConfigurations"
          "patch"
        ];
      };
      expected = {
        envToHost = false;
        envToDroidHost = false;
        envToDarwinHost = false;
      };
    };

    # ── the guard fails for ITS OWN reason, not by accident of shape ──────────────────────────────────
    # A near-miss pair differing ONLY in the last segment. If the rule were keyed on path LENGTH, on the
    # family name, or on the node name appearing ANYWHERE in the path, both of these would agree — they
    # disagree only because the last segment is what is compared.
    test-discriminates-on-the-last-segment-alone = {
      expr = {
        # same length, same family, entity name present EARLIER in the path but not last
        nameEarlierNotLast = placementNamesNode "axon" [
          "nixidyEnvs"
          "axon"
          "x86_64-linux"
        ];
        # the minimal pair: identical but for the final segment
        lastSegmentMatches = placementNamesNode "axon" [
          "nixidyEnvs"
          "x86_64-linux"
          "axon"
        ];
      };
      expected = {
        nameEarlierNotLast = false;
        lastSegmentMatches = true;
      };
    };
  };
}
