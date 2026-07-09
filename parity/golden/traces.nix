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
  # R5 (spec §10) CONVERGENCE — L3 flip. `den.aspects.igloo` is a self-named aspect for host `igloo`;
  # legacy/self-provide auto-includes it at host:igloo (den v1 resolve-entity.nix:48-63), so the nixos
  # bucket is non-empty and the producing-class default fold emits `collected:host:igloo/nixos | merge`,
  # BYTE-MATCHING v1's nixos class fold (matched 0→1, extra 0). The 5 residual `missing` v1 edges are the
  # class-model boundary NOT closed by R5 alone — v1's homeManager default fold, its os→host routes (R3,
  # unconditional at every host+user scope even with no os content), its hm→nixos synthesize forward, and
  # its user→nixos nest — the C8/C9 default-fold + forward reconciliation (parity/ledger.md L3).
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
    ];
    matched = [
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
    ];
    missing = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [ ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "0114d4c6655e981f477efe0706741e63dd63a3873e9a8aeca3845e30e172cac8";
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
  # #44 / C7.5 convergence witness — the FIRST cross-arm fixture with a non-empty `matched` set. den-hoag's
  # producing-class default fold emits `collected:host:igloo/nixos | merge`, which byte-matches v1's nixos
  # class fold. The 5 remaining `missing` v1 edges are the residual class-model boundary (v1's `os` base
  # class + class-composition routes + host homeManager default) — L6 in the ledger. `extra = [ ]`: the
  # producing-class scoping (never a phantom k8s/home-manager fold) keeps the hoag arm exact.
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
    ];
    matched = [
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
    ];
    missing = [
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:user:tux/nixos |  | collected:user:tux/os | merge"
      "root:user:tux/nixos | home-manager/users/tux | synthesize:homeManager/nixos/home-manager/users/tux/homeManager>nixos | nest"
      "root:user:tux/nixos | users/users/tux | collected:user:tux/user | nest"
    ];
    extra = [ ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "0114d4c6655e981f477efe0706741e63dd63a3873e9a8aeca3845e30e172cac8";
  };
  # R5 (spec §10) CONVERGENCE — L5 flip. The two-host union of the L3 boundary: each self-named host
  # aspect (`igloo`, `iceberg`) auto-includes at its own host, so BOTH producing-class nixos folds
  # byte-match v1 (matched 0→2, extra 0). The 10 residual `missing` edges are the per-host L3 residual ×2
  # (homeManager fold + os routes + hm synthesize + user nest), confirming the fan-out stays exact.
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
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
    ];
    matched = [
      "root:host:iceberg/nixos |  | collected:host:iceberg/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
    ];
    missing = [
      "root:host:iceberg/homeManager |  | collected:host:iceberg/homeManager | merge"
      "root:host:iceberg/nixos |  | collected:host:iceberg/os | merge"
      "root:host:igloo/homeManager |  | collected:host:igloo/homeManager | merge"
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
    hoagHash = "c3f652ee05a6e69b94e4f95f30c3ffb2e999a975a910bf197be0b27fbef13910";
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
