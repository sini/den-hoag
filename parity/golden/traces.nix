# parity/golden/traces.nix — the FIRST-CORPUS golden (the classified C7 boundary), captured by running
# the harness (oracle.nix) over parity/fixtures/topologies.nix under the frozen den v1 pin. Every string is
# a NORMALIZED (<kind>:<name>) frozen `T | P | S | M` sort key. This is a GOLDEN: a change to any list is a
# real parity shift — re-classify it in parity/ledger.md and bump deliberately. Regenerate per runbook.md.
#
# Cross-arm entries carry each arm's rendered key list, the assertEdgeParity diff (matched/missing/extra),
# and each arm's trace hash (P4). `spawnNeg` is the v1-internal P7 negative control's summary.
#
# THE LEDGER SEEDS (why every cross-arm diff is non-empty at C7): den v1 folds CLASS content as edges;
# den-hoag folds QUIRK CHANNELS + demand + the explicit deliver surface as edges (class content rides the
# class-module path). The domains are disjoint until the deliver-materialization completion (#44) + the
# default-fold reconciliation land — see parity/ledger.md.
{
  plainHostUser = {
    v1 = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    hoag = [ ];
    matched = [ ];
    missing = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [ ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945";
  };
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
    ];
    matched = [ ];
    missing = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [
      "root:host:igloo/feat |  | collected:host:igloo/feat | merge"
    ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "5b7009500063d6cb2b93c9881f59944bfc5ac6026a00a2bd6e610aadc9840fee";
  };
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
    hoag = [ ];
    matched = [ ];
    missing = [
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
    extra = [ ];
    v1Hash = "b723a06d6b3e7c6b1d4cbab992bd4048fe17321901fd6cb25a711ebaabf7a935";
    hoagHash = "4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945";
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
