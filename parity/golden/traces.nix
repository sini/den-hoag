# parity/golden/traces.nix — the FIRST-CORPUS golden (the classified C7 boundary), captured by running
# the harness (oracle.nix) over parity/fixtures/topologies.nix under the frozen den v1 pin. Every string is
# a NORMALIZED (<kind>:<name>) frozen `T | P | S | M` sort key. This is a GOLDEN: a change to any list is a
# real parity shift — re-classify it in parity/ledger.md and bump deliberately. Regenerate per runbook.md.
#
# Cross-arm entries carry each arm's rendered key list, the assertEdgeParity diff (matched/missing/extra),
# and each arm's trace hash (P4). `spawnNeg` is the v1-internal P7 negative control's summary.
#
# CONVERGENCE STATE (Task 8 M1): den-hoag now matches v1 on the HOST-scoped edges — the producing-class
# nixos fold (R5 self-named-aspect) AND the os→host.class route (R3/R6 ambient batteries, formal-preserving
# canTake routes). The residual `missing` edges are all v1's USER-scoped edges (`root:user:<u>/…`): v1
# resolves a user as its OWN instantiation root (v1 resolve.to), while den-hoag models a user as a CELL
# under its host root — a scope-MODEL boundary, not a fold-content one (the os/user routes DO fire at the
# cell, but their edges target the host root, not a separate user root). Plus v1's homeManager default fold
# (the home-manager battery, not ported). See parity/ledger.md (L3/L5 R5+R3 convergence note).
{
  # R5 + R3 CONVERGENCE — L3. `den.aspects.igloo` is a self-named aspect for host `igloo`: legacy/
  # self-provide auto-includes it (nixos fold matches), and the ambient os-class battery's os-to-host route
  # (a formal-preserving canTake route) fires at host:igloo → `collected:host:igloo/os | merge` matches v1
  # (matched 2, extra 0). The 4 residual `missing` = v1's homeManager fold (unported battery) + the three
  # USER-scoped edges (v1 user-as-root vs den-hoag user-as-cell — the scope-model boundary).
  plainHostUser = {
    v1 = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    hoag = [
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    matched = [
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    missing = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [ ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "bfa2e1eb6abebbeefd74cfcba02e8fb4e0ab97013f606877d0ba35aa75f3843c";
  };
  # quirkChannel — no self-named aspect (the `seed` aspect rides `schema.host.includes`), so NO nixos fold;
  # but the ambient os-to-host route fires at host:igloo → `collected:host:igloo/os` matches v1 (matched 1).
  # The `feat` quirk-channel fold is `extra` (v1 folds quirk content into classes — the disjoint-domain
  # witness). The 5 `missing` = v1's host nixos/homeManager folds + the three user-scoped edges.
  quirkChannel = {
    v1 = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    hoag = [
      "root:host:igloo/feat |  | collected:host:igloo/feat | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    matched = [
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    missing = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [
      "root:host:igloo/feat |  | collected:host:igloo/feat | merge"
    ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "b30b135737039bf7e0a7787a7136b2f47278d7e996eb25c703fb9061a0109eef";
  };
  # classFold — `base` aspect carries nixos content via `schema.host.includes` (nixos fold matches), and the
  # ambient os-to-host route fires (os edge matches): matched 2, extra 0. The 4 residual `missing` are the
  # homeManager fold + the three user-scoped edges (the scope-model boundary).
  classFold = {
    v1 = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    hoag = [
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    matched = [
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    missing = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [ ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "bfa2e1eb6abebbeefd74cfcba02e8fb4e0ab97013f606877d0ba35aa75f3843c";
  };
  # multiHost — the two-host union: each host's nixos fold (R5) + os route (R3) matches (matched 4, extra 0).
  # The 8 residual `missing` = per-host homeManager fold ×2 + the six user-scoped edges (scope-model boundary).
  multiHost = {
    v1 = [
      "root:host:iceberg/homeManager |  | collected:host:iceberg/homeManager | merge"
      "root:host:iceberg/nixos |  | collected:host:iceberg/nixos | merge"
      "root:host:iceberg/nixos |  | collected:host:iceberg/os | merge"
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:pingu/nixos |  | collected:user:pingu/os | merge"
      "root:user:pingu/nixos | home-manager/users/pingu | synthesize:homeManager/nixos/home-manager/users/pingu/homeManager>nixos | nest"
      "root:user:pingu/nixos | users/users/pingu | collected:user:pingu/user | nest"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    hoag = [
      "root:host:iceberg/nixos |  | collected:host:iceberg/nixos | merge"
      "root:host:iceberg/nixos |  | collected:host:iceberg/os | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    matched = [
      "root:host:iceberg/nixos |  | collected:host:iceberg/nixos | merge"
      "root:host:iceberg/nixos |  | collected:host:iceberg/os | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
    ];
    missing = [
      "root:host:iceberg/homeManager |  | collected:host:iceberg/homeManager | merge"
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:user:pingu/nixos |  | collected:user:pingu/os | merge"
      "root:user:pingu/nixos | home-manager/users/pingu | synthesize:homeManager/nixos/home-manager/users/pingu/homeManager>nixos | nest"
      "root:user:pingu/nixos | users/users/pingu | collected:user:pingu/user | nest"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [ ];
    v1Hash = "b723a06d6b3e7c6b1d4cbab992bd4048fe17321901fd6cb25a711ebaabf7a935";
    hoagHash = "15ab99c6247d8125ed5d5ef4832c48ec349c1ff615f2ea2ceb8b22c0fa93c480";
  };
  # The P7 negative control (v1 production edgeTrace vs legacyEdgeTrace on a spawn topology). It MUST
  # diverge — the legacy rewalk arm undercounts the spawn (fewer edges) and carries suppressed twins.
  spawnNeg = {
    nProd = 18;
    nLegacy = 9;
    parity = false;
    matchedNonEmpty = true;
    firstDivergent = "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge";
  };
}
