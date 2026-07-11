# Dev-time P2 ship-gate SMOKE — the toplevel-drvPath comparison at n=1 (the ACTUAL P2 hash, stronger than
# parity-content-live's hostName). NOT a CI test: a real toplevel forces the full nixos module fixpoint and
# the fixture must be BOOTABLE. `boot.isContainer = true` skips the `fileSystems`/`boot.loader` assertions a
# real system asserts — a synthetic-smoke-only trick (real corpus hosts are bootable, so the full-fleet
# drvPath diff needs no such trick). Both arms CROSS (the item-4 terminal seam on the shim side); the
# `contentGate` record shape falls out. On divergence, `nix-diff` the two drvs; classify per the ledger.
#
# Run (dev-time, ~1-2s):
#   nix eval --impure --json --expr 'import ./parity/ship-gate.nix { flakePath = toString ./parity; }'
{ flakePath }:
let
  parity = builtins.getFlake flakePath;
  # den-v2 is a `path:..` input (its getFlake `.inputs.den-v2` indirection is brittle); resolve the parent
  # den-hoag flake directly instead. den-v1 / nixpkgs / home-manager are url inputs — read from parity.
  hoag = builtins.getFlake (builtins.dirOf flakePath);
  npkgs = parity.inputs.nixpkgs;
  nlib = import "${npkgs}/lib";
  v1flk = parity.inputs.den-v1;
  v1edge = import "${v1flk}/nix/lib/aspects/fx/edges/edge.nix" { lib = nlib; };
  P = hoag.compat.parity;
  v1arm = P.oracle.mkV1 {
    denV1Flake = v1flk;
    denV1Edge = v1edge;
    nixpkgsLib = nlib;
    nixpkgs = npkgs;
    homeManager = parity.inputs.home-manager;
  };
  crossNixos =
    (import "${hoag}/lib/output/terminal.nix" {
      inherit (hoag.lib.internal) bind flake;
    } { nixpkgs = npkgs; }).crossNixos;

  # A bootable container smoke fixture — content set via a den aspect (the shim path end-to-end).
  fixture = {
    den.hosts.x86_64-linux.igloo = { };
    den.aspects.igloo.nixos = {
      networking.hostName = "igloo";
      boot.isContainer = true;
    };
  };

  v1DrvPath = (v1arm.crossV1 { fixtureModule = fixture; }).igloo.config.system.build.toplevel.drvPath;
  shimDrvPath =
    (hoag.compat.mkDenWith [ fixture ] { nixosTerminal = crossNixos; })
    .nixosConfigurations.igloo.config.system.build.toplevel.drvPath;

  # ── M2.5 channel-binding smoke (the corpus collector shape at the real crossing) ──────────────────
  # Two quirk channels + the corpus's two bare channel-arg consumer shapes (firewall-collector /
  # secrets-collector, nix-config defaults.nix host includes): `igloo` EMITS a firewall fragment (the
  # value case); `bare` emits nothing on either channel (the totality case — pre-totality the shim arm
  # threw `called without required argument 'firewall'` here; den v1 injects every registered pipe
  # ctx-present-and-empty, pin 11866c16 assemble-pipes.nix:951). `age-secrets` is emitted NOWHERE
  # (totality for a fleet-wide-silent channel). Both hosts must be drvPath-equal across arms.
  channelFixture =
    { den, ... }:
    {
      den.hosts.x86_64-linux = {
        igloo = { };
        bare = { };
      };
      den.quirks.firewall.description = "smoke firewall channel";
      den.quirks.age-secrets.description = "smoke never-emitted channel";
      den.aspects.fw-collector.nixos = { firewall, lib, ... }: lib.mkMerge firewall;
      den.aspects.sec-collector.nixos = { age-secrets, lib, ... }: lib.mkMerge age-secrets;
      den.aspects.igloo = {
        includes = [
          den.aspects.fw-collector
          den.aspects.sec-collector
        ];
        firewall = {
          networking.firewall.allowedTCPPorts = [ 7654 ];
        };
        nixos = {
          networking.hostName = "igloo";
          boot.isContainer = true;
        };
      };
      den.aspects.bare = {
        includes = [
          den.aspects.fw-collector
          den.aspects.sec-collector
        ];
        nixos = {
          networking.hostName = "bare";
          boot.isContainer = true;
        };
      };
    };

  chanV1 = v1arm.crossV1 { fixtureModule = channelFixture; };
  chanShim =
    (hoag.compat.mkDenWith [ channelFixture ] { nixosTerminal = crossNixos; }).nixosConfigurations;
  chanHost = host: rec {
    v1DrvPath = chanV1.${host}.config.system.build.toplevel.drvPath;
    shimDrvPath = chanShim.${host}.config.system.build.toplevel.drvPath;
    equal = v1DrvPath == shimDrvPath;
    diffHint = "nix-diff ${v1DrvPath} ${shimDrvPath}";
  };
  channels = {
    emitting = chanHost "igloo"; # firewall fragment emitted + collected
    silent = chanHost "bare"; # zero emissions on both channels — the totality witness
  };
in
{
  configuration = "nixosConfigurations.igloo";
  inherit v1DrvPath shimDrvPath;
  equal = v1DrvPath == shimDrvPath;
  diffHint = "nix-diff ${v1DrvPath} ${shimDrvPath}";
  inherit channels;
  allEqual = (v1DrvPath == shimDrvPath) && channels.emitting.equal && channels.silent.equal;
}
