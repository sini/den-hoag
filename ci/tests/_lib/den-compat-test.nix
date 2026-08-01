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
#  3. expectedError rides nix-unit's NATIVE error channel: the leaf FORWARDS `{ type; msg; }` and the
#     RUNNER does the catching. That channel is strictly stronger than a `tryEval`-to-a-boolean lowering
#     on every axis — it catches `EvalError` (a missing attribute, which `tryEval` does NOT catch: that
#     one propagates and kills the evaluation), it FAILS when the expression does not throw at all
#     ("Expected error, but no error was caught"), and it matches `msg` as an unanchored substring. So a
#     witness naming ONE abort no longer passes on ANY error — which is the whole content of the
#     assertion. CEILING: a leaf carries `expected` XOR `expectedError` (see the tail's refusal).
#  4. `apple`/`tuxHm`/`pinguHm` are EXPOSED but NOT realizable in den-hoag CI: no nix-darwin input (⇒
#     `darwinConfigurations.apple` has no `.config`) and no home-manager input (⇒ `igloo.home-manager` has
#     no option). ENVIRONMENTAL, not a path bug — a test forcing them throws in-CI. Left lazy so a
#     nixos-only test never trips them.
{
  denHoag,
  denHoagFlakeModule,
  flakeParts,
  homeManagerModule,
  nixpkgs,
  nixpkgsLib,
}:
let
  lib = nixpkgsLib;
  registry = import ./instance-registry.nix { inherit denHoag lib; };

  # den v1 denTest defaults (nix/denTest.nix:107-111) + `den.nixpkgs` so the bridge crosses to a REAL NixOS
  # system (its `crossNixos` fold, ship-gate M1) instead of the nixpkgs-free `collect`. `mkDefault` keeps
  # the v1 defaults yielding to a migrated test's own def; the bridge's `v1DeepMerge` for `den.default`
  # folds them cross-module.
  #
  defaultsModule = {
    den.schema.user.classes = lib.mkDefault [ "homeManager" ];
    # v1's user entity is host-parented (the corpus declares `den.schema.user.parent = "host"`,
    # topology.nix:7): `den.hosts.<h>.users.<u>` is a CELL under its host, whose ctx carries BOTH `host` and
    # `user`, so a `{ host, user, … }:` policy/battery fires and the cell's content folds up to the host. The
    # scaffold's omission left users as ROOTS (a `user`-only ctx). Seeded here (a raw last-wins scalar the
    # bridge merges — no `mkDefault`; a migrated test setting its own `user.parent` still wins, imported
    # after). Safe now that the cross-scope shared-aspect fold dedups `den.default` (no host+cell double).
    den.schema.user.parent = "host";
    den.default.nixos.system.stateVersion = lib.mkDefault "25.11";
    den.default.homeManager.home.stateVersion = lib.mkDefault "25.11";
    den.nixpkgs = nixpkgs;
  };

  # FIX 2 (home-manager crossing). den v1's hm battery imports each host's CHANNEL `home-manager.module`
  # into the host's nixos class GATED on the host carrying an HM-classed user (`hostHasClass`, home-env.nix);
  # den-hoag CI has no channel, so the scaffold supplies the input's `home-manager.nixosModules.home-manager`
  # as that per-host module. It rides the compat terminal's `hmModuleFor` path (which imports a host's
  # `home-manager.module` when present, mkNixosInstantiate) via a HOST-KIND module: each host instance sets
  # `home-manager.module` IFF it has ≥1 user (with the `den.schema.user.classes = ["homeManager"]` default an
  # HM-classed user ⟺ any user). So a host WITH users realizes `igloo.home-manager.users.<u>` (tuxHm/pinguHm)
  # + the `home-manager.*` options (use-global-pkgs), and a USER-LESS host imports nothing —
  # `config ? home-manager` stays false (the v1 gate, kept intact). Gated per-instance (reads the host's own
  # `config.users`), never a fleet-level fixpoint.
  hmHostGateModule =
    { config, ... }:
    {
      # Unconditional module shape, mkIf'd VALUE (a conditional module STRUCTURE that reads `config` recurses
      # — the module system's `config in imports` trap). mkIf false ⇒ no def ⇒ `hmModuleFor` reads null ⇒ no
      # import (v1's user-less-host gate); mkIf true ⇒ the hm module is imported for the host.
      config.home-manager.module = lib.mkIf ((config.users or { }) != { }) homeManagerModule;
    };
  hmSeedModule = {
    den.schema.host.imports = [ hmHostGateModule ];
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
  #
  # The declaration goes through gen-schema's OWN `mkInstanceRegistry`, as the corpus writes it
  # (`options.den.environments = schemaLib.mkInstanceRegistry den.schema.environment`). A hand-rolled
  # `lazyAttrsOf anything` here has an EMPTY `getSubOptions` — the very surface the bridge reads to classify
  # a consumer-declared registry — so every fixture downstream of this scaffold would be modelling a
  # registry shape the consumer never declares. The kind carries `domain` because gen-schema's strict arm
  # needs a declared surface to check against: a kind with NO declared option reports the INSTANCE name as
  # the undeclared key (`STRICT MODE: "prod" is not declared on environment`).
  # ── AND THE KINDS ARE DECLARED THROUGH `den.schema`, which is what makes the bridge's own namespace→kind
  # discovery run at all. Read off `registry.kindValueOf` (a side eval) the kind is invisible to
  # `config.den.schema.__rawSchema`, so the bridge's candidate set contained only option-LESS kinds, its
  # marker resolved `{ }` for every scaffold fleet, and no fixture downstream of here exercised the
  # discovery the consumer depends on. Declared here the way the corpus declares it — the raw kind into
  # `den.schema.<kind>`, the registry over the PROCESSED `config.den.schema.<kind>`.
  #
  # TWO registries, not one, and with more than one instance between them: the map is folded per registry
  # key, so a fleet carrying a single key cannot distinguish a per-key fold from one that answers once and
  # reuses it. `groups` is a second kind whose option set is disjoint from `environment`'s, so the
  # cross-kind probe reads fields the instance lacks in both directions on every scaffold fleet.
  envKindDecl = {
    isEntity = true;
    parent = null;
    imports = [
      (_: {
        options.domain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      })
    ];
  };
  groupKindDecl = {
    isEntity = true;
    parent = null;
    imports = [
      (_: {
        options.description = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
        options.gid = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
        };
      })
    ];
  };
  envSeedModule =
    { config, lib, ... }:
    {
      options.den.environments = registry.mkInstanceRegistry config.den.schema.environment { };
      # `groups` also carries the corpus's DERIVED-PRIMITIVE shape (`nix-config schema/cluster.nix:97`): a
      # registry `derive` overlaying a string onto every instance after the module eval, declared
      # `internal` in the registry's own `extraModules` so it is absent from the kind value and from the
      # identity stamp while present on the instance. That is the one shape the value-reflecting discovery
      # cannot resolve, so it is what keeps the option-level marker load-bearing on this path rather than
      # merely running on it.
      options.den.groups = registry.mkInstanceRegistry config.den.schema.group {
        derive = insts: lib.mapAttrs (n: _: { derivedTag = "tag-${n}"; }) insts;
        extraModules = [
          (_: {
            options.derivedTag = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              readOnly = true;
              internal = true;
            };
          })
        ];
      };
      config.den.schema.environment = envKindDecl;
      config.den.schema.group = groupKindDecl;
      config.den.environments.prod = lib.mkDefault { };
      config.den.groups.wheel = lib.mkDefault { description = "wheel"; };
      config.den.groups.users = lib.mkDefault { description = "users"; };
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
          # the COMPLEMENT of the same partition, DERIVED from the one key list rather than repeated
          # as a second one. Two hand-written lists for one partition drift apart, and the direction
          # that drifts silently is this one: a key the leaf carries but the strip list forgets
          # becomes an undeclared flake-parts option on the fleet face.
          (builtins.attrNames assertionKeys);

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
              hmSeedModule
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
        # The merged v1 `den` navigation surface (lazy — forced only if `expr` reads `den`). SOURCED FROM
        # `eval.config.den`, NOT `eval.config._module.args.den`: flake-parts does not reflect a config-set
        # `_module.args` back through `config._module.args` (it reads `[ ]`), whereas `eval.config.den` is
        # the FULL merged v1 surface (hosts/aspects/schema/policies/… — the bridge's `options.den` submodule
        # output) — exactly what the bridge binds as the in-eval `den` arg. So a migrated test's `expr`
        # reading `den.hosts.<h>.name` / `den.aspects.<x>` resolves as it did in v1. (`den.lib` is NOT on
        # this surface — a config-time `den.lib.policy.*` read still resolves via the bridge's real in-eval
        # `den` module arg; no migrated `expr` reads `den.lib`.)
        den = eval.config.den;
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

      # ── THE LEAF IS A PROJECTION OF `out`, NOT A REBUILD OF IT ─────────────────────────────────────
      # `assertionKeys` is the leaf's key set, declared in ONE place. An arm may TRANSFORM a key it owns
      # (the value arm rewrites `expr` for partial matching); NO arm enumerates what to keep. The tail
      # previously constructed a fresh literal attrset in each arm, so every key an arm did not name was
      # ERASED — and each arm's list drifted independently of the other's, which is why the same defect
      # had to be found twice from two directions. A projection has no arm-local key list to drift:
      # a new leaf field is one edit HERE and reaches every arm by construction.
      # ★ THE ATTRIBUTION KEYS ARE IN THE LIST, AND LEAVING THEM OUT WAS AN ERASURE RATHER THAN AN
      # OMISSION. A declared known-failure carries `bead`/`construct` (and `correct`, the other half
      # of a value-form claim) ON THE LEAF, and the census that enforces the guards SELECTS leaves by
      # those very keys. A projection that dropped them did not merely lose metadata: a declaration
      # authored through this scaffold censused as no row at all and reported GREEN, so the one
      # enforcement point that is total over hand-written leaves could not see it. The runner
      # tolerates the extra keys.
      #
      # This list must agree with the declaration mechanism's own key set (`_lib/xfail.nix`), which
      # is where the partition is defined; it is repeated here rather than threaded because threading
      # it means an argument on all 58 importers of this scaffold.
      assertionKeys = {
        bead = null;
        construct = null;
        correct = null;
        expr = null;
        expected = null;
        expectedError = null;
      };
      projected = builtins.intersectAttrs assertionKeys out;
    in
    # `expected` and `expectedError` are MUTUALLY EXCLUSIVE at the leaf: nix-unit forces `expr` against
    # `expected` OUTSIDE its error channel, so a leaf carrying both lets the error escape uncaught and the
    # runner attributes the failure to the throw rather than to the leaf. REFUSED, not silently dropped —
    # a scaffold that quietly discards a declared assertion key is the exact defect this projection
    # removes, so the contradiction is named where it was written.
    if projected ? expectedError then
      if projected ? expected then
        throw (
          "den-compat-test: a leaf declares BOTH `expected` and `expectedError`. nix-unit carries one "
          + "assertion form per leaf — with both, `expr` is forced against `expected` outside the error "
          + "channel and the error escapes uncaught. Declare exactly one."
        )
      else
        # `expr` rides UNFORCED: nix-unit's native channel does the catching, and it is what compares
        # `type` and `msg`. Nothing here reshapes the error declaration.
        projected
    else
      let
        expected = out.expected;
      in
      # PARTIAL MATCHING (denTest.nix:20-24): compare only the keys `expected` names when both are attrsets.
      if builtins.isAttrs expected && builtins.isAttrs expr then
        projected // { expr = builtins.intersectAttrs expected expr; }
      else
        projected;
in
denTest
