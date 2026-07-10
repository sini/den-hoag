# P2 — content parity (the pipes blind spot). Two levels, per §4.4:
#   • the FLEET drv-hash gate (`contentGate`) — toplevel `.drvPath` under den v1 vs den v2 + shim,
#     byte-identical, inputs pinned equal except the den input. This is the SHIP-GATE arm: it evaluates
#     the real nix-config corpus + crosses nixpkgs/nix-darwin, so it CANNOT run purely in den-hoag's own
#     CI. It runs dev-time against the corpus flake (compat spec §7.3). This suite documents + exercises
#     the mechanism shape, not the full fleet.
#   • the CROSS-PIPELINE content hash — for synthetic pipe-/spawn-bearing fixtures with no buildable
#     toplevel: the per-root × class materialization fold output, projected onto a fixture-declared
#     observation set and canonically hashed, v1-materialized vs hoag-materialized (an intra-pipeline hash
#     would pass while hoag's DELIVERY of the value diverges — the blind spot P2 closes). This is the
#     CI-runnable content-parity arm.
#
# HONEST CI/SHIP-GATE SPLIT (plan Task 8 note): CI runs the cross-pipeline synthetic hashes + pins the
# hoag-side materialization hash as a regression baseline. The full-fleet drv-hash run is the ship-gate,
# dev-time against the real corpus. A v1-vs-hoag content divergence on a synthetic is a P2 ledger finding
# (P6 discipline — classified, never papered over), exactly like the structural suite's matched/extra/missing.
{
  harness,
  ...
}:
let
  # ── cross-pipeline synthetic fixtures (inline — never perturbs the structural/golden fixture set) ──────
  # A pipe channel (`ports`) feeding a host cell, alongside nixos class content: the pipe value rides the
  # channel while `networking.hostName` rides the class fold — the observation targets the DELIVERED class
  # content at the host root × nixos class.
  fleetPipeThroughEdge = {
    name = "fleet-pipe-through-edge";
    module = {
      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.quirks.ports = { };
      den.aspects.svc = {
        ports = [ 22 ];
        nixos.networking.hostName = "igloo";
      };
      den.schema.host.includes = [ { name = "svc"; } ];
    };
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

  # A host with a self-named aspect delivering nixos content (the dominant v1 spawn-of-host-aspects idiom):
  # the observation targets the spawned/delivered class content at the host root.
  hostAspectsSpawn = {
    name = "host-aspects-spawn";
    module = {
      den.hosts.x86_64-linux.igloo.users.tux = { };
      den.aspects.igloo.nixos.boot.isContainer = true;
    };
    observationSet = [
      {
        root = "host:igloo/nixos";
        rootNode = "host:igloo";
        system = "x86_64-linux";
        host = "igloo";
        class = "nixos";
        observedPaths = [
          [
            "boot"
            "isContainer"
          ]
        ];
      }
    ];
  };

  pipeRecords = harness.crossPipelineRecords fleetPipeThroughEdge;
  spawnRecords = harness.crossPipelineRecords hostAspectsSpawn;
  allRecords = pipeRecords ++ spawnRecords;

  # CI reads ONLY the hoag-side hash (never forces the v1 thunk). The v1-materialized arm forces the full
  # v1 pipeline — the home-manager battery `getModule` reaches `inputs.home-manager."${host.class}Modules"`,
  # a CORPUS input the parity harness deliberately does not carry (§4.4: "both evaluations pin identical
  # inputs (nixpkgs, home-manager, all corpus inputs)"). So `record.v1Hash` / `record.equal` are the SHIP-GATE
  # arm (dev-time, full inputs); Nix laziness keeps them unforced here. CI pins the hoag materialization hash
  # as a regression baseline: a hoag pipe/spawn content regression breaks it; a v1-vs-hoag divergence is a
  # ship-gate P2 finding classified in the ledger (P6), like the structural suite's matched/extra/missing.
  hoagHashOf = r: r.hoagHash;

  # GOLDEN — the hoag-materialized content hashes (re-derive by reading `.hoagHash`; a change is a hoag
  # materialization regression to explain, not silently re-baseline). These hash REAL delivered config
  # values (the FOLDED class content, not the raw module list) — verified non-null: fleet-pipe-through-edge
  # → networking.hostName = "igloo"; host-aspects-spawn → boot.isContainer = true.
  goldenPipe = "fa53e906ae006d11042e3363856bcc2e46841c25bf5a3ec1a6a23ebe20acae49";
  goldenSpawn = "6038256d17db4067e03a01650e5eeb7a1ca1c67d120ffc67f36c55422677f58a";

  # contentGate MECHANISM shape (§4.4, P2 fleet drv-hash) — exercised on a SYNTHETIC corpus of drvPath-bearing
  # toplevel stubs (no store build): equal iff the two toplevel drvPaths match, with a nix-diff `diffHint` on
  # inequality. The REAL fleet run supplies live `nixosConfigurations.<h>.config.system.build.toplevel` /
  # `darwinConfigurations.<h>.system` thunks under both den arms (ship-gate, dev-time).
  fakeCorpus = [
    {
      configuration = "nixosConfigurations.demo";
      v1Toplevel = {
        drvPath = "/nix/store/same.drv";
      };
      shimToplevel = {
        drvPath = "/nix/store/same.drv";
      };
    }
    {
      configuration = "darwinConfigurations.mac";
      v1Toplevel = {
        drvPath = "/nix/store/v1.drv";
      };
      shimToplevel = {
        drvPath = "/nix/store/shim.drv";
      };
    }
  ];
  contentRecs = harness.contentGate { corpus = fakeCorpus; };
in
{
  flake.tests.parity-content = {
    # ── cross-pipeline: hoag materialization is stable (the CI content-regression guard) ──
    # one record per observation (the two mandatory synthetics × their single observed root×class).
    test-crosspipeline-record-count = {
      expr = builtins.length allRecords;
      expected = 2;
    };
    # the fleet-pipe-through-edge hoag content hash matches its golden (pipe value delivered onto the edge).
    test-crosspipeline-pipe-hoag-golden = {
      expr = hoagHashOf (builtins.head pipeRecords);
      expected = goldenPipe;
    };
    # the host-aspects-spawn hoag content hash matches its golden (spawned host-aspect class content).
    test-crosspipeline-spawn-hoag-golden = {
      expr = hoagHashOf (builtins.head spawnRecords);
      expected = goldenSpawn;
    };
    # every record carries the §4.4 shape (fixture/root/observedPaths + a sha256 hoag hash).
    test-crosspipeline-record-shape = {
      expr = builtins.all (
        r:
        (r ? fixture)
        && (r ? root)
        && (r ? observedPaths)
        && builtins.match "[0-9a-f]{64}" r.hoagHash != null
      ) allRecords;
      expected = true;
    };

    # ── contentGate mechanism (P2 fleet drv-hash) shape ──
    # equal iff the two toplevel drvPaths are byte-identical (the ship-gate authority).
    test-contentgate-equal-on-match = {
      expr = (builtins.head contentRecs).equal;
      expected = true;
    };
    test-contentgate-unequal-on-mismatch = {
      expr = (builtins.elemAt contentRecs 1).equal;
      expected = false;
    };
    # the record carries configuration + both drvPaths + a nix-diff hint (dev-time, not evaluated).
    test-contentgate-record-shape = {
      expr =
        let
          r = builtins.elemAt contentRecs 1;
        in
        {
          hasConfig = r.configuration == "darwinConfigurations.mac";
          hasV1 = r.v1DrvPath == "/nix/store/v1.drv";
          hasShim = r.shimDrvPath == "/nix/store/shim.drv";
          hasHint = builtins.match "nix-diff .*" r.diffHint != null;
        };
      expected = {
        hasConfig = true;
        hasV1 = true;
        hasShim = true;
        hasHint = true;
      };
    };
  };
}
