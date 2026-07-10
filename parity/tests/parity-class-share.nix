# P8 — class-share invisibility (implementation strategy, not semantics). den-hoag's DEFAULT fleet-build
# path composes each class's invariant core once and injects it via gen-class `applyCoreFixed` (den-hoag
# §2.10, Law A18). The parity gates run ON THAT SHARED PATH — the path users ship — never a share-disabled
# variant. This suite is the §4.6 `coreGate` sub-gate: for every producing class in a corpus fixture,
#   • `allGated`   — every member's share-ON artifact forces WITHOUT abort. den-hoag's own `authorize`
#                    (A18) aborts named on a byte-divergent core, so `gated` is the FLEET-PATH byte gate
#                    (the shipping authority — not a re-derived gateCore digest; the digest mechanism is
#                    covered directly by ci/tests/class-share-parity.nix's Arm A).
#   • `traceEqual` — E_hoag(T) byte-identical with `share.core` on vs off (share shapes only the terminal
#                    artifact, never the edge set: A18 structural invisibility).
#   • `configInvariant` — config(root) byte-identical with share on vs off (content invisibility).
# A deliberately-corrupted core fails the sub-gate LOUDLY, localized to its class (never an
# `intentional-v2-semantic` ledger row — class-share is a strategy, so any observable diff is a bug-in-hoag).
#
# ═══ ITEMS 3 & 4, STATED (parity-watch, plan Task 8) ═══
# Tier-2 `applyCoreFixed`'s spine-skip is GEN-MERGE-ONLY. The nixpkgs crossing (`crossNixos` →
# `terminals.nixosSystem`, and the new `crossDarwin`) cannot `coreShortCircuit`, so it sees IDENTICAL folded
# input whether the core was spine-skipped or re-merged — **A18 holds TRIVIALLY through the nixpkgs/nix-darwin
# crossing** (the P2 fleet drv-hash gate is share-invisible there). Two build paths, both share-invariant:
# `coreGate` runs on the PURE gen-merge build path (this suite); the fleet drv-hash P2 gate runs THROUGH the
# nixpkgs crossing (parity-content, ship-gate). MECHANISM (no re-hardcoded loc string here): `coreGate`
# gates each member by FORCING the share-ON fleet artifact (`deepSeq den.output.systems.<class>.<member>`,
# whose share arm reads the `denClassShareCore` loc internally via `internal.classShareCoreAttr` — the
# suite never names it) and asserts share-on/off trace + config invariance; the corruption arm drives
# `denHoag.internal.classShare.build` directly for the A18 gate teeth. The `denClassShareCore` string is
# never written in this suite, re-hardcoded or otherwise.
{
  harness,
  denHoag,
  ...
}:
let
  I = denHoag.internal;

  # A corpus fixture with a genuinely SHARED class-invariant core: two hosts, a `ports` quirk channel, and a
  # `svc` aspect emitting the channel value + nixos content, included at every host. Both hosts share the
  # `ports = [22 80]` contribution ⇒ a NON-EMPTY nixos core (a trivial empty core would gate vacuously).
  # Defined inline (not in topologies.nix) so it never perturbs the structural/golden fixture set.
  sharedCoreFixture = {
    name = "shared-core-fleet";
    module = {
      den.hosts.x86_64-linux.axon.users.u = { };
      den.hosts.x86_64-linux.blade.users.u = { };
      den.quirks.ports = { };
      den.aspects.svc = {
        ports = [
          22
          80
        ];
        nixos.boot.isContainer = true;
      };
      den.schema.host.includes = [ { name = "svc"; } ];
    };
  };

  records = harness.coreGate {
    fixture = sharedCoreFixture;
    shareClasses = [ "nixos" ];
  };
  nixosRec = builtins.head records;

  # ── the deliberately-corrupted-core teeth (A18), localized to its class ──
  # A synthetic two-member class with a shared core; a member whose REAL projection diverges from the core at
  # a shared key ⇒ the byte gate is RED and `authorize` ABORTS named (a stale/wrong core is never silently
  # reused). This is the loud-failure localization the sub-gate promises.
  members2 = {
    m1 = { };
    m2 = { };
  };
  classOf = _node: denHoag.classes.nixos;
  built = I.classShare.build {
    members = members2;
    inherit classOf;
    projectionOf = _id: {
      alpha = "A";
    };
    projectionPath = "denCore";
    shareCore = true;
  };
  tamperedReal = {
    alpha = "TAMPERED";
  };
  gateRed = built.gate "m1" tamperedReal;
  authorizeThrows =
    !(builtins.tryEval (builtins.deepSeq (built.authorize "m1" tamperedReal) true)).success;
in
{
  flake.tests.parity-class-share = {
    # the corpus fixture actually produces ≥1 nixos member (the gate below is not vacuous).
    test-coreGate-has-members = {
      expr = builtins.length nixosRec.members >= 2;
      expected = true;
    };
    # core-per-class byte identity: every member's share-ON artifact forces without abort (A18 authorize).
    test-coreGate-all-gated = {
      expr = nixosRec.allGated;
      expected = true;
    };
    # structural invisibility: E_hoag(T) is byte-identical with share.core on vs off.
    test-coreGate-trace-invariant = {
      expr = nixosRec.traceEqual;
      expected = true;
    };
    # content invisibility: config(root) is byte-identical with share.core on vs off.
    test-coreGate-config-invariant = {
      expr = nixosRec.configInvariant;
      expected = true;
    };
    # P8-clean overall: allGated ∧ traceEqual (∧ configInvariant).
    test-coreGate-p8-clean = {
      expr = nixosRec.allGated && nixosRec.traceEqual && nixosRec.configInvariant;
      expected = true;
    };

    # ── teeth (A18): a corrupted core fails LOUD, localized to its class ──
    # a member whose real projection diverges from the shared core is RED at the byte gate…
    test-corrupted-core-gate-red = {
      expr = gateRed.gate;
      expected = false;
    };
    # …and `authorize` ABORTS (a divergent core is never silently reused — the sub-gate has teeth).
    test-corrupted-core-authorize-throws = {
      expr = authorizeThrows;
      expected = true;
    };
  };
}
