# P2 LIVE content parity at n=1 — the ship-gate mechanism at n=1; the full fleet = runbook.
#
# WHY THIS EXISTS (the deeper reason, recorded here + in the M2 headers/PIN): the two arms' MATERIALIZED
# `.imports` are different KINDS — the hoag arm's are plain den-hoag class declaration data (freeform-
# foldable), the v1 arm's are REAL nixpkgs nixos modules meaningful only inside the full module-system
# fixpoint (a freeform fold infinite-recurses on `nixos/common.nix`). So a live v1-vs-hoag CONTENT
# comparison cannot fold — it must CROSS: build a real NixOS system on each arm and read a config value.
# Both crossings are eval-only (no store build) and cheap: measured 0.5s (config.networking.hostName) /
# 1.2s (system.build.toplevel.drvPath) cold — well within CI budget. This n=1 test is the ship-gate
# mechanism run on one fixture; the full-fleet drv-hash gate (contentGate over the real corpus) is the
# dev-time ship-gate script (runbook.md). networking.hostName is used in CI (no bootability needed); the
# drvPath comparison — the stronger P2 hash — rides the ship-gate script with a `boot.isContainer` fixture.
{
  harness,
  ...
}:
let
  # A minimal v1 fixture set via a den ASPECT (compile → fold → terminal end-to-end), NOT a literal placed
  # in nixos config: host `igloo`, self-named aspect delivering `networking.hostName`.
  fixtureModule = {
    den.hosts.x86_64-linux.igloo = { };
    den.aspects.igloo.nixos.networking.hostName = "igloo";
  };

  # Both arms CROSS to a real NixOS system (the terminal seam on the hoag arm; the v1 flake's crossing on
  # the v1 arm), then read the delivered config value — eval-only.
  v1Host = (harness.crossV1 { inherit fixtureModule; }).igloo.config.networking.hostName;
  hoagHost = (harness.crossHoag { inherit fixtureModule; }).igloo.config.networking.hostName;

  # BONUS (terminal value-preservation): the hoag FOLD value (the M2 cross-pipeline path — output.outputFor
  # → freeform fold) vs the hoag CROSSED value. Equal ⇒ the M2 fold-goldens are valid regression guards
  # (the terminal does not alter a plain delivered option value). Compared via the frozen content hash so
  # the same canonical rendering is used on both sides.
  foldFixture = {
    name = "live-n1";
    module = fixtureModule;
    observationSet = [
      {
        root = "host:igloo/nixos";
        rootNode = "host:igloo";
        system = "x86_64-linux";
        host = "igloo";
        class = "nixos";
        observedPaths = [
          [
            "networking"
            "hostName"
          ]
        ];
      }
    ];
  };
  foldHash = (builtins.head (harness.crossPipelineRecords foldFixture)).hoagHash;
  crossedHash = harness.canonHash { "networking.hostName" = hoagHost; };
in
{
  flake.tests.parity-content-live = {
    # LIVE v1-vs-hoag content parity at n=1: both arms cross to a real NixOS system; the shim-delivered
    # networking.hostName byte-matches v1's. This is the P2 content assertion the fold could never make.
    test-live-hostname-parity = {
      expr = {
        v1 = v1Host;
        hoag = hoagHost;
        equal = v1Host == hoagHost;
      };
      expected = {
        v1 = "igloo";
        hoag = "igloo";
        equal = true;
      };
    };
    # BONUS: hoag FOLD value == hoag CROSSED value → the M2 fold-goldens are valid regression guards.
    test-fold-equals-crossed = {
      expr = foldHash == crossedHash;
      expected = true;
    };
  };
}
