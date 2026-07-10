# The OUTPUT BRIDGE witness (ship-gate M1) — the permanent in-repo analogue of the corpus drop-in probe.
# It reconstructs the exported `flakeModule` (lib/compat/bridge.nix, wired exactly as flake.nix does) and
# evaluates it through a STRICT flake-parts-shaped `lib.evalModules` (the corpus imports it into real
# flake-parts, which is strict; den-hoag's own mkDen path is permissive — so ONLY a bridge-through-a-strict-
# eval witness proves the drop-in works end to end). The witness pins BOTH grains:
#   • crossed (den.nixpkgs set, the single-evaluator M1 grain): the bridge produces a REAL NixOS system —
#     `config.networking.hostName` resolves through the full module-system fixpoint AND a real
#     `system.build.toplevel.drvPath` is forced (eval-only, no build). This is the acceptance the corpus
#     probe can only reach once a real fleet + evaluator flow through the bridge.
#   • collect (no den.nixpkgs, the corpus grain at M1): member KEYS are present (non-empty
#     `nixosConfigurations`) as nixpkgs-free artifacts — the "NON-EMPTY under the override" acceptance.
# nixpkgs `lib`/`nixpkgs` come from the ci harness (ci/flake.nix specialArgs — the same real-nixpkgs seam
# the end-to-end + terminal-seam suites cross through).
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  nixpkgs,
  ...
}:
let
  # Reconstruct the bridge with the SAME deps flake.nix threads: `compat` + the `mkCrossNixos` closure
  # (built from `denHoag.internal.{bind,flake}` + the terminal source, exactly as the harness/flake do).
  mkCrossNixos =
    npkgs:
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { nixpkgs = npkgs; }).crossNixos;
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    inherit mkCrossNixos;
    schema = denHoag.internal.schema;
    # den-hoag's exported `lib` IS the migration lib surface (flake.nix); the harness receives it as denHoag.
    denLib = denHoag;
  };

  # A minimal BOOTABLE one-host nixos fleet — the single-evaluator (M1) fixture. Bootable so the crossed
  # arm can force a real `toplevel.drvPath` (root fs + bootloader + stateVersion, past NixOS's assertions).
  hostContent = {
    networking.hostName = "igloo";
    fileSystems."/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
    boot.loader.grub.devices = [ "/dev/sda" ];
    system.stateVersion = "24.11";
  };
  fleetBase = {
    den.hosts.x86_64-linux.igloo = { };
    den.aspects.igloo.nixos = hostContent;
  };

  # A flake-parts-shaped strict harness: declare `flake` as a merge option (as flake-parts core does) and
  # evaluate the bridge + fixture. `config.flake.*` reads back the mounted output faces.
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  evalBridge =
    extra:
    (lib.evalModules {
      modules = [
        flakeStub
        bridge
        fleetBase
        extra
      ];
    }).config.flake;

  crossed = evalBridge { den.nixpkgs = nixpkgs; };
  collected = evalBridge { };
in
{
  flake.tests.compat-bridge = {
    # CROSSED: real NixOS system whose config resolves through the full fixpoint.
    test-crossed-hostname-resolves = {
      expr = crossed.nixosConfigurations.igloo.config.networking.hostName;
      expected = "igloo";
    };
    # CROSSED: a real toplevel derivation is forced (eval-only) — the M1 acceptance. `.drv` suffix proves
    # it is a store derivation path, i.e. a buildable system, not a collect artifact.
    test-crossed-toplevel-is-real-drv = {
      expr =
        let
          drv = crossed.nixosConfigurations.igloo.config.system.build.toplevel.drvPath;
        in
        builtins.isString drv && lib.hasSuffix ".drv" drv;
      expected = true;
    };
    # COLLECT (the corpus grain): NON-EMPTY nixosConfigurations — member keys present as nixpkgs-free
    # artifacts, no build (the `den.nixpkgs`-absent path the corpus takes at M1).
    test-collect-nixosconfigs-nonempty = {
      expr = builtins.attrNames collected.nixosConfigurations;
      expected = [ "igloo" ];
    };
    # COLLECT: the artifact is the collect terminal (not a crossed system) — proves the fallback grain.
    test-collect-is-collect-terminal = {
      expr = collected.nixosConfigurations.igloo.__terminal or "<not-collect>";
      expected = "collect";
    };
  };
}
