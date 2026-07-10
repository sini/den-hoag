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

  # ── den.policies v1-parity COERCION through the bridge: FORMAL-PRESERVATION + the DISCRIMINATOR ───────
  # THE MISSING FIXTURE CLASS. A v1 top-level policy fn `den.policies.<name> = { cluster, environment, ... }:
  # [ … ]` mounted through the REAL bridge submodule must KEEP its formals. Prior repros drove
  # `denCompat.compile` directly and MISSED this: the erasure happens in the flake-parts `anything` merge
  # (which wraps a TOP-LEVEL fn value in a bare `arg:` lambda, ERASING `functionArgs`), NOT in compile. The
  # bridge now COERCES `den.policies` to `{ __isPolicy; name; fn }` records (policy-type.nix parity), NESTING
  # the fn — a nested fn is NOT erased, so its declared coords survive to compile's `compilePolicy` gate — AND
  # restoring v1's policy-vs-parametric-aspect discriminator (the coerced value is a RECORD). This is the
  # analogue of the through-the-bridge crossed/collect witnesses above, for the policy surface.
  evalBridgeConfig =
    extra:
    (lib.evalModules {
      modules = [
        flakeStub
        bridge
        fleetBase
        extra
      ];
    }).config;
  # TWO SEPARATE policy modules mirror the built-in-provisioning + corpus split, so the cross-module union
  # is witnessed alongside formal-preservation.
  policyCfg = evalBridgeConfig {
    imports = [
      { den.policies.cluster-to-nixidy = { cluster, environment, ... }: [ ]; }
      {
        den.policies.user-to-host = {
          __denCanTake = "user-host";
          fn = { user, host, ... }: [ ];
        };
      }
    ];
  };
  # The load-bearing CONTRAST at the SAME nixpkgs lib: `anything.merge` ERASES a top-level fn's formals
  # (the root cause), while the coercion NESTS the fn in a `{ __isPolicy; fn }` record so `.fn` PRESERVES them.
  policyFn = { cluster, environment, ... }: [ ];
  anythingErased = builtins.functionArgs (
    lib.types.anything.merge
      [ "den" "policies" ]
      [
        {
          file = "m";
          value = policyFn;
        }
      ]
  );
  coercionPreserved = builtins.functionArgs (
    {
      __isPolicy = true;
      name = "p";
      fn = policyFn;
    }
    .fn
  );
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

    # THROUGH-THE-BRIDGE (the missing fixture class): a top-level policy fn is COERCED to a `{ __isPolicy }`
    # record (the discriminator) and keeps its DECLARED coords on the NESTED `.fn` when mounted through the
    # strict flake-parts bridge. Pre-fix, `anything` wrapped it in a bare `arg:` lambda → `functionArgs = {}`
    # → the kind-include rule dropped `environment` → concern-policies' value-less probe applied the fn
    # without it → the uncatchable `called without required argument 'environment'`.
    test-policy-formals-preserved-through-bridge = {
      expr = {
        isRecord = policyCfg.den.policies.cluster-to-nixidy.__isPolicy or false;
        fnArgs = builtins.functionArgs policyCfg.den.policies.cluster-to-nixidy.fn;
      };
      expected = {
        isRecord = true;
        fnArgs = {
          cluster = false;
          environment = false;
        };
      };
    };
    # The collector unions ACROSS modules (the built-in-provisioning + corpus split), and a record-valued
    # policy's nested fn rides through with formals intact (compileCanTake reads the `__denCanTake` shape,
    # not these formals — so it is unaffected either way, but the raw union preserves them cleanly).
    test-policy-cross-module-union = {
      expr = {
        names = builtins.sort (a: b: a < b) (builtins.attrNames policyCfg.den.policies);
        recordFnArgs = builtins.functionArgs policyCfg.den.policies.user-to-host.fn;
      };
      expected = {
        names = [
          "cluster-to-nixidy"
          "user-to-host"
        ];
        recordFnArgs = {
          host = false;
          user = false;
        };
      };
    };
    # THE PROOF the coercion is load-bearing: at the SAME nixpkgs lib, `anything.merge` ERASES a top-level
    # fn's formals (the root cause) while nesting the fn in the coerced `{ __isPolicy; fn }` record PRESERVES
    # them on `.fn`.
    test-coercion-preserves-anything-erases = {
      expr = {
        anything = anythingErased;
        coercion = coercionPreserved;
      };
      expected = {
        anything = { };
        coercion = {
          cluster = false;
          environment = false;
        };
      };
    };
  };
}
