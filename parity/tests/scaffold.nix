# parity/scaffold — the dual-den-input resolution gate (Task 0). Proves the harness flake resolves
# BOTH arms and both expose the surface the differential consumes: the frozen v1 arm exposes the
# byte-contract edge surface (`edgeSortKey` + `assertEdgeParity`), and the den-hoag arm exposes
# `compat.parity`. The actual v1-vs-hoag diff (P1–P8) lands from Task 7; this just closes the loop
# so every later harness task has a working TDD flake.
{ lib, denCompat, denV1, ... }:
{
  flake.tests.scaffold = {
    # v1 arm resolves and carries the frozen edge byte contract (edge.nix / edges/parity.nix).
    test-v1-edge-surface = {
      expr = (denV1.edge ? edgeSortKey) && (denV1.parity ? assertEdgeParity);
      expected = true;
    };
    # ...and it is callable: `edgeSortKey` renders the frozen `T | P | S | M` string from a minimal
    # edge record (built with the arm's own S/T constructors), proving the surface is live, not just
    # present. This exact string is the whole structural oracle both arms key the diff by.
    test-v1-sortkey-string = {
      expr = denV1.edge.edgeSortKey {
        target = denV1.edge.rootTarget "h" "nixos";
        path = [ ];
        source = denV1.edge.collected "h" "nixos";
        mode = "merge";
      };
      expected = "root:h/nixos |  | collected:h/nixos | merge";
    };
    # den-hoag arm resolves (`path:..`) and exposes the parity helper slot.
    test-v2-compat-parity = {
      expr = denCompat ? parity;
      expected = true;
    };
  };
}
