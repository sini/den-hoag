# parity/golden/traces.nix — the FIRST-CORPUS golden (the classified C7 boundary), captured by running
# the harness (oracle.nix) over parity/fixtures/topologies.nix under the frozen den v1 pin. Every string is
# a NORMALIZED (<kind>:<name>) frozen `T | P | S | M` sort key. This is a GOLDEN: a change to any list is a
# real parity shift — re-classify it in parity/ledger.md and bump deliberately. Regenerate per runbook.md.
#
# Cross-arm entries carry each arm's rendered key list, the assertEdgeParity diff (matched/missing/extra),
# and each arm's trace hash (P4). `spawnNeg` is the v1-internal P7 negative control's summary.
#
# CONVERGENCE STATE (Task 8 M1): den-hoag matches v1 on the HOST-scoped edges — the producing-class
# nixos fold (R5 self-named-aspect) AND the os→host.class route (R3/R6 ambient batteries, formal-preserving
# canTake routes). Two residual boundary CLASSES remain, both the (user,host) CELL edge-root of Law A15:
#   (i)  `missing` — v1's USER-ROOT edges (`root:user:<u>/…`): v1 resolves a user as its OWN instantiation
#        root (v1 resolve.to), a scope-MODEL boundary den-hoag has no counterpart for. Plus v1's homeManager
#        default fold (the home-manager battery, not ported).
#   (ii) `extra`   — den-hoag EMITS the user-as-cell delivery edge `collected:user:<u>@host:<h>/user | nest`:
#        under Law A15 a (user,host) cell is its OWN edge-root under its host root, so the user's `user`
#        content folds at the CELL and renders as an edge that v1 (which folds a user at its own user root)
#        has no counterpart for. The twin `collected:user:<u>/user` therefore stays in `missing`. This is a
#        graph-SHAPE deviation only — P2 CONTENT parity is byte-identical (the user's config reaches the same
#        host terminal). See parity/ledger.md rows n + n2.
{
  # R5 + R3 CONVERGENCE — L3. `den.aspects.igloo` is a self-named aspect for host `igloo`: legacy/
  # self-provide auto-includes it (nixos fold matches), and the ambient os-class battery's os-to-host route
  # (a formal-preserving canTake route) fires at host:igloo → `collected:host:igloo/os | merge` matches v1
  # (matched 2). den-hoag additionally EMITS the user-as-cell edge `collected:user:tux@host:igloo/user` (Law
  # A15 — the (tux,igloo) cell edge-root), which v1 has no counterpart for → `extra` 1. The 4 residual
  # `missing` = v1's homeManager fold (unported battery) + the three USER-ROOT edges (v1 user-as-root vs
  # den-hoag user-as-cell — the scope-model boundary; the cell edge lands in `extra`, its user-root twin in
  # `missing`).
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
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
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
    extra = [
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
    ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "5b4ba247089ebbfcfe8a085da4c1251528d71a0b638671f093e4994c1f82ba9f";
  };
  # quirkChannel — the `seed` aspect rides `schema.host.includes`. Task 4a (single typed tree): host:igloo's
  # `nixos` producing-class default fold now emits `collected:host:igloo/nixos | merge`, matching v1 (matched
  # 2). The raw class-content walk was DROPPING this edge (an empty raw nixos bucket skipped the fold); the
  # single typed tree gives the class a deferredModule bucket so the fold fires — RE-BASELINED to restore v1
  # parity (verified: den v1 pin 11866c16 `traceV1 quirkChannel` DELIVERS `collected:host:igloo/nixos`; the
  # single tree restores it, not a spurious edge). The `feat` quirk-channel fold stays `extra` (v1 folds quirk
  # content into classes — the disjoint-domain witness), and den-hoag's user-as-cell edge
  # `collected:user:tux@host:igloo/user` (Law A15) joins it → `extra` 2. The 4 residual `missing` = v1's
  # homeManager fold + the three user-root edges (the scope-model boundary).
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
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
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
    extra = [
      "root:host:igloo/feat |  | collected:host:igloo/feat | merge"
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
    ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    # Task 4a — re-derived: the hoag edge set gained `collected:host:igloo/nixos` (the L7 restore); the
    # user-as-cell edge (Law A15) added the fourth edge and re-derived the hash.
    hoagHash = "f508f00ad94e4613895f23c560553094402c3949e0aade62287422d87a37320b";
  };
  # classFold — `base` aspect carries nixos content via `schema.host.includes` (nixos fold matches), and the
  # ambient os-to-host route fires (os edge matches): matched 2. den-hoag additionally emits the user-as-cell
  # edge `collected:user:tux@host:igloo/user` (Law A15) → `extra` 1. The 4 residual `missing` are the
  # homeManager fold + the three user-root edges (the scope-model boundary).
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
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
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
    extra = [
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
    ];
    v1Hash = "5c1b4d82045fece9b0289b9396b487fdc0db53183f795476eafec17d57271b8c";
    hoagHash = "5b4ba247089ebbfcfe8a085da4c1251528d71a0b638671f093e4994c1f82ba9f";
  };
  # multiHost — the two-host union: each host's nixos fold (R5) + os route (R3) matches (matched 4), and each
  # host's cell emits its user-as-cell edge (`collected:user:pingu@host:iceberg/user`,
  # `collected:user:tux@host:igloo/user`; Law A15) → `extra` 2. The 8 residual `missing` = per-host
  # homeManager fold ×2 + the six user-root edges (scope-model boundary).
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
      "root:host:iceberg/nixos | users/users/pingu | collected:user:pingu@host:iceberg/user | nest"
      "root:host:igloo/nixos |  | collected:host:igloo/nixos | merge"
      "root:host:igloo/nixos |  | collected:host:igloo/os | merge"
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
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
    extra = [
      "root:host:iceberg/nixos | users/users/pingu | collected:user:pingu@host:iceberg/user | nest"
      "root:host:igloo/nixos | users/users/tux | collected:user:tux@host:igloo/user | nest"
    ];
    v1Hash = "b723a06d6b3e7c6b1d4cbab992bd4048fe17321901fd6cb25a711ebaabf7a935";
    hoagHash = "f3285173117f8b457264f611b5073e245480000a55203a12ce370077d0702ee4";
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
