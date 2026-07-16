# Phase 6.2a projection witness (spec §7.1 / §6.2a — host-aspects opt-in → class-scoped reach-edge).
#
# The v1 corpus `host-aspects` battery opts a (user,host) CELL into its HOST's home-manager aspects. Under
# projection this is a class-scoped `reach-edge` from the cell to its host root: an opted-in cell REACHES the
# host's home-manager resolved-aspects (class-filtered — no nixos over-reach), a plain cell reaches only its
# own. This witness pins that TARGET behavior over a hand-built reach graph (the edge stands in for the
# retargeted compat producer — compile.nix's `translateEffect kind=="spawn"` classes-form arm); the producer
# is exercised end-to-end in compat-batteries.nix (3b).
#
# The reach/projectClass driver bindings come from the shared `_lib/projection-harness.nix`.
{
  denHoag,
  denHoagSrc,
  ...
}:
let
  # Shared reach/projectClass driver bindings, hoisted to a `/_`-skipped module (see the harness header).
  harness = import ./_lib/projection-harness.nix { inherit denHoag denHoagSrc; };
  inherit (harness)
    mkNode
    reachEdgeAct
    projectReach
    tags
    ;

  # A host root with BOTH a home-manager aspect and a nixos-only aspect; an OPTED-IN cell (amy) carrying a
  # class-scoped home-manager reach-edge to it; a PLAIN cell (bob) with no edge. THE class-scoping is the F9
  # gate: amy reaches host-hm but NOT host-nixos.
  graph = {
    "host:h".resolved = [
      (mkNode "host-hm" { home-manager.tag = "host-hm"; })
      (mkNode "host-nixos" { nixos.tag = "host-nixos"; })
    ];
    "user:amy@host:h" = {
      resolved = [ (mkNode "opted-own" { home-manager.tag = "opted"; }) ];
      edges = [ (reachEdgeAct "host:h" "home-manager") ];
    };
    "user:bob@host:h".resolved = [ (mkNode "plain-own" { home-manager.tag = "plain"; }) ];
  };
  hmTags =
    id:
    builtins.concatMap tags (projectReach {
      inherit graph id;
      class = "home-manager";
    });
in
{
  flake.tests.projection-host-aspects = {
    # An opted-in cell reaches its OWN home-manager slice FIRST (own-subtree order), THEN the host's
    # home-manager slice through the class-scoped reach-edge (spec §7.1 opt-in projection).
    test-opted-reaches-host-hm-class-scoped = {
      expr = hmTags "user:amy@host:h";
      expected = [
        "opted"
        "host-hm"
      ];
    };
    # F9 NO OVER-REACH: the home-manager-scoped edge does NOT pull the host's nixos-only aspect.
    test-opted-no-nixos-overreach = {
      expr = builtins.elem "host-nixos" (hmTags "user:amy@host:h");
      expected = false;
    };
    # A plain cell (no opt-in edge) reaches only its OWN aspects — no host gather.
    test-plain-cell-own-only = {
      expr = hmTags "user:bob@host:h";
      expected = [ "plain" ];
    };
  };
}
