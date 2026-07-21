# den v1 `denTest` EQUIVALENT, on the den-hoag FLAKE-PARTS BRIDGE — the behavioral-migration scaffold.
#
# Reproduces the semantics of den v1's `nix/denTest.nix` (denful/den) so a v1 BEHAVIORAL test migrates by
# copy + arg-rename: a test module `helpers: { <den config>; expr; expected; }` (or `{ …; expectedError; }`)
# is evaluated THROUGH den-hoag's real `flakeModule` (the `lib/compat/bridge.nix` flake-parts module the
# nix-config consumer imports), and the v1 helper args (`den`/`lib`/`igloo`/`apple`/`tuxHm`/`pinguHm`/
# `iceberg`) are read off the built flake — `igloo = config.flake.nixosConfigurations.igloo.config`, exactly
# as v1's denTest read them. Under a `/_`-infixed path so import-tree/mkCi SKIP it as a flake-parts module —
# it is a plain FUNCTION imported by the `den-behavioral/*` witnesses (the `_lib/projection-harness.nix`
# convention), not a test module itself.
#
# ── WHY THE BRIDGE (not the mkDen-direct path): the shim's internal v1-options eval declares `den.aspects`/
#    `den.default` as `raw` (single-def), so a v1 test spreading aspects across `imports` modules CONFLICTS.
#    The bridge (`options.den` submodule) folds them with v1's OWN deep-merge (`v1DeepMerge`: lists concat,
#    attrsets recurse, scalars/fns last-wins) — the same merge v1's `aspectsType`/`aspectType` did — so
#    multi-module `den.aspects`/`den.default` merge, and the crossed `config.flake.nixosConfigurations` face
#    carries a REAL NixOS system (`den.nixpkgs` set below drives the bridge's `crossNixos`, not `collect`).
#    This is den-hoag's ONE sanctioned crossing, reached the way the corpus reaches it.
#
# ── deviations from a literal denTest port (each forced by the substrate / the CI env):
#  1. Helper args are SPLICED by the scaffold, not sourced from the eval's `_module.args`: the den config is
#     read back through the bridge eval (which supplies the self-referential `den` arg) and the built
#     result's `igloo`/… are spliced into the test-fn args. The den config never forces the helpers (v1's
#     own laziness invariant: config ⊥ helpers), so the fleet is cycle-free.
#  2. PARTIAL MATCHING (denTest's `intersectAttrs`): den-hoag's `mkCi` asserts FULL `expr == expected`; v1
#     compared only the keys `expected` names. Reproduced: both attrsets → `intersectAttrs expected expr`.
#  3. expectedError → tryEval (mkCi has no error channel): `{ expr = (tryEval <erroring expr>).success;
#     expected = false; }` (precedent: compat-flat-host.nix). CEILING: `tryEval` catches `throw`/`assert`
#     only — an `abort`/"missing arg"/inf-recursion is UNCATCHABLE (v1 `Abort`/`MissingArgumentError` can't
#     ride this arm).
#  4. `apple`/`tuxHm`/`pinguHm` are EXPOSED but NOT realizable in den-hoag CI: no nix-darwin input (⇒
#     `darwinConfigurations.apple` has no `.config`) and no home-manager input (⇒ `igloo.home-manager` has
#     no option). ENVIRONMENTAL, not a path bug — a test forcing them throws in-CI. Left lazy so a
#     nixos-only test never trips them.
{
  denHoagFlakeModule,
  flakeParts,
  nixpkgs,
  nixpkgsLib,
}:
let
  lib = nixpkgsLib;

  # den v1 denTest defaults (nix/denTest.nix:107-111) + `den.nixpkgs` so the bridge crosses to a REAL NixOS
  # system (its `crossNixos` fold, ship-gate M1) instead of the nixpkgs-free `collect`. `mkDefault` keeps
  # the v1 defaults yielding to a migrated test's own def; the bridge's `v1DeepMerge` for `den.default`
  # folds them cross-module.
  defaultsModule = {
    den.schema.user.classes = lib.mkDefault [ "homeManager" ];
    den.default.nixos.system.stateVersion = lib.mkDefault "25.11";
    den.default.homeManager.home.stateVersion = lib.mkDefault "25.11";
    den.nixpkgs = nixpkgs;
  };

  # The builtinsModule `fleet-context-enrich` policy (lib/compat/builtins.nix → fleet-context.nix) enriches
  # every host node's ctx with its `environment` entity, resolving `host.environment or "prod"` against
  # `den.environments`. Its value-less stratum PROBE rides the default env "prod", so that env MUST be
  # registered — else the probe throws, is tryEval-caught, and the policy is mis-classified value-conditional
  # ("cannot contribute enrichment"). The corpus always carries a `den.environments` registry (a
  # consumer-declared kind); a minimal migration fixture declares none, so the scaffold DECLARES the sub-option
  # (so compile's surface-totality accepts `den.environments` — an undeclared key is rejected) and seeds an
  # empty `prod` env. The enrich then binds `environment = {}` at hosts, inert for a nixos-only witness; a
  # migrated test may add its own environments (they merge over this).
  envSeedModule =
    { lib, ... }:
    {
      options.den.environments = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.anything;
        default = { };
      };
      config.den.environments.prod = lib.mkDefault { };
    };

  denTest =
    testFn:
    let
      # The fleet as a flake-parts module. The bridge supplies the self-referential `den` arg
      # (`config._module.args.den`, v1's R1 binding); `lib` + the built-result helpers are SPLICED into the
      # test-fn args. The assertion keys are stripped — the bridge declares only `den`-shaped output, so a
      # stray top-level `expr`/`expected` would be an undeclared flake-parts option. A returned `imports`
      # list rides through (the multi-module `den.aspects` shape the bridge merge exists to support).
      fleetModule =
        {
          den,
          config,
          ...
        }@args:
        builtins.removeAttrs
          (testFn (
            args
            // {
              inherit
                lib
                igloo
                apple
                tuxHm
                pinguHm
                iceberg
                ;
            }
          ))
          [
            "expr"
            "expected"
            "expectedError"
          ];

      # THE BRIDGE EVAL — the real consumer path. `evalFlakeModule` returns the full module-system result,
      # so `eval.config.flake` is the crossed output face and `eval.config._module.args.den` is the bridge's
      # merged v1 navigation surface (the `den` a migrated `expr` reads).
      eval =
        flakeParts.lib.evalFlakeModule
          {
            inputs = { inherit nixpkgs; };
            self = {
              inputs = { inherit nixpkgs; };
            };
            moduleLocation = "<den-compat-test scaffold>";
          }
          {
            systems = [ "x86_64-linux" ];
            imports = [
              denHoagFlakeModule
              defaultsModule
              envSeedModule
              fleetModule
            ];
          };
      result = eval.config.flake;

      # The v1 helper surface (denTest.nix:114-122). Nixos helpers cross for real; the darwin / home-manager
      # helpers ride the same shape but are unrealizable in CI (deviation 4) — all lazy.
      igloo = result.nixosConfigurations.igloo.config;
      iceberg = result.nixosConfigurations.iceberg.config;
      apple = result.darwinConfigurations.apple.config;
      tuxHm = igloo.home-manager.users.tux;
      pinguHm = igloo.home-manager.users.pingu;

      helpers = {
        # The bridge's own merged v1 `den` navigation surface (lazy — forced only if `expr` reads `den`).
        den = eval.config._module.args.den or { };
        inherit
          lib
          igloo
          iceberg
          apple
          tuxHm
          pinguHm
          ;
        config = eval.config;
      };

      out = testFn helpers;
      expr = out.expr;
      hasExpectedError = out ? expectedError;
    in
    if hasExpectedError then
      {
        expr = (builtins.tryEval (builtins.deepSeq expr expr)).success;
        expected = false;
      }
    else
      let
        expected = out.expected;
      in
      # PARTIAL MATCHING (denTest.nix:20-24): compare only the keys `expected` names when both are attrsets.
      if builtins.isAttrs expected && builtins.isAttrs expr then
        {
          expr = builtins.intersectAttrs expected expr;
          inherit expected;
        }
      else
        {
          inherit expr expected;
        };
in
denTest
