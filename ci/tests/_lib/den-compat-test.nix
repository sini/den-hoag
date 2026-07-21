# den v1 `denTest` EQUIVALENT, on the den-hoag `denCompat` shim — the Phase-0 migration scaffold.
#
# Reproduces the semantics of den v1's `nix/denTest.nix` (denful/den) so a v1 BEHAVIORAL test migrates by
# copy + arg-rename: a test module `helpers: { <den config>; expr; expected; }` (or `{ …; expectedError; }`)
# is fed to `denCompat.mkDenWith`, and the v1 helper args (`den`/`lib`/`igloo`/`apple`/`tuxHm`/`pinguHm`/
# `iceberg`) are exposed off the built fleet. Under a `/_`-infixed path so import-tree/mkCi SKIP it as a
# flake-parts module — it is a plain `{ … }: denTest` FUNCTION imported by the `den-behavioral/*` witnesses,
# not a test module itself (the same convention as `_lib/projection-harness.nix`).
#
# ── FIVE deviations from a literal denTest port, each forced by the den-hoag substrate (Phase-0 findings):
#
#  1. TERMINAL = crossNixos, NOT the default `collect`. `denCompat.mkDen`'s default nixpkgs-free `collect`
#     terminal yields a `nixosConfigurations.<h>` ARTIFACT with NO `.config` (compat-terminal-seam.nix
#     test-default-is-collect). A v1 helper `igloo = …igloo.config.networking.hostName` needs a REAL NixOS
#     system, so the scaffold builds the nixpkgs-bound `crossNixos` terminal (the exact harness-side
#     construction compat-terminal-seam.nix uses) and drives `mkDenWith … { nixosTerminal = crossNixos; }`.
#
#  2. HELPER ARGS are spliced by the scaffold, not sourced from a module eval. den v1's denTest is ONE
#     flake-parts eval where `config.flake.nixosConfigurations.igloo.config` and `config.den` co-exist; the
#     shim's `mkDen` is a FUNCTION, so the scaffold rebuilds the fixpoint by hand — the den config is read
#     back through `mkDenWith` (bindLegacyEnv supplies the self-referential `den` arg inside that eval) and
#     the built result's `igloo`/… are spliced into the test-fn args. The den config never forces the
#     helpers (v1's own laziness invariant: config ⊥ helpers), so `result` is cycle-free.
#
#  3. PARTIAL MATCHING (denTest's `intersectAttrs`): den-hoag's `mkCi` asserts FULL `expr == expected`, but
#     v1 compared only the keys `expected` names. Reproduced: when `expected` and `expr` are both attrsets
#     the scaffold emits `{ expr = builtins.intersectAttrs expected expr; expected; }`, else verbatim.
#
#  4. expectedError → tryEval (mkCi has no error channel). A test carrying `expectedError` emits
#     `{ expr = (builtins.tryEval <the erroring expr>).success; expected = false; }` (precedent:
#     compat-flat-host.nix test-flat-host-no-system-aborts). CEILING: `tryEval` catches `throw`/`assert`
#     ONLY — an `abort`, a "called without required argument", or infinite recursion is UNCATCHABLE, so a
#     v1 test whose `expectedError.type` is `Abort`/`MissingArgumentError` cannot migrate through this arm.
#
#  5. `apple`/`tuxHm`/`pinguHm`/`iceberg` are EXPOSED but only `igloo`/`iceberg` (nixos) are realizable in
#     den-hoag CI: there is no home-manager input (⇒ `igloo.home-manager.users.<u>` has no option) and no
#     nix-darwin input (⇒ `darwinConfigurations.apple` is a nixpkgs-free `collect` artifact with no
#     `.config`). A migrated test that FORCES `apple`/`tuxHm`/`pinguHm` throws in-CI — a WS-B signal, not a
#     scaffold bug. Left lazy so a nixos-only test never trips them.
{
  denCompat,
  denHoag,
  denHoagSrc,
  nixpkgs,
  nixpkgsLib,
}:
let
  lib = nixpkgsLib;

  # The nixpkgs-bound `crossNixos` terminal, built harness-side from the den-hoag source (bind/flake off
  # the public `internal` surface) — no core edit, no shim edit. Identical construction to
  # compat-terminal-seam.nix / the parity harness. Built ONCE per scaffold import (shared across every
  # `denTest` in the importing witness file).
  crossNixos =
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { inherit nixpkgs; }).crossNixos;

  # den v1 denTest defaults (nix/denTest.nix:107-111), injected as a SEPARATE module so a migrated test may
  # still override them. `mkDefault` keeps them yielding to a test's own def, exactly as v1's testModule did.
  defaultsModule = {
    den.schema.user.classes = lib.mkDefault [ "homeManager" ];
    den.default.nixos.system.stateVersion = lib.mkDefault "25.11";
    den.default.homeManager.home.stateVersion = lib.mkDefault "25.11";
  };

  denTest =
    testFn:
    let
      # ── the fleet module handed to the shim ────────────────────────────────────────────────────────
      # A FUNCTION module so the compat eval binds the self-referential `den` arg (bindLegacyEnv) and the
      # module system's `config`. `lib` + the built-result helpers are SPLICED into the test-fn args (the
      # compat eval sources module-fn formals by NAME from its own moduleArgs/baseArgs — it carries neither
      # `lib` nor the helpers — so naming them as formals would throw; splicing sidesteps that). The
      # assertion keys are stripped: the compat v1-options eval declares only `den`, so a stray top-level
      # `expr`/`expected` would be an undeclared-option error.
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

      # The built fleet — REAL nixos systems via crossNixos.
      result = denCompat.mkDenWith [ defaultsModule fleetModule ] { nixosTerminal = crossNixos; };

      # The v1 helper surface (denTest.nix:114-122 helpersModule). Nixos helpers cross for real; the
      # home-manager / darwin helpers ride the same shape but are only realizable with those inputs (see
      # deviation 5) — all lazy, so a nixos-only test never forces the unrealizable ones.
      igloo = result.nixosConfigurations.igloo.config;
      iceberg = result.nixosConfigurations.iceberg.config;
      apple = result.darwinConfigurations.apple.config;
      tuxHm = igloo.home-manager.users.tux;
      pinguHm = igloo.home-manager.users.pingu;

      # The v1 navigation `den` surface (the read-back a `den.aspects.<path>` reference in `expr` would
      # read). Lazy — only forced if a migrated test's `expr`/`expected` references `den`.
      navDen = denCompat.evalV1 [
        defaultsModule
        fleetModule
      ];

      helpers = {
        den = navDen;
        inherit
          lib
          igloo
          iceberg
          apple
          tuxHm
          pinguHm
          ;
        # `config` — the v1 flake-parts config in denTest; only a few v1 tests read it in `expr`
        # (namespaces/packages — flake-output features den-hoag compat does not forward yet). Best-effort.
        config = {
          den = navDen;
          flake = { };
        };
      };

      out = testFn helpers;
      expr = out.expr;
      hasExpectedError = out ? expectedError;
    in
    if hasExpectedError then
      # tryEval the erroring expr → the shim's error channel (mkCi has none). See deviation 4 + its ceiling.
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
