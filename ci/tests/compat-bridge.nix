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

  # ── den.default v1-parity cross-module FOLD through the bridge (R4 radiation, the THIRD declared-option) ──
  # v1's `den.default` is an aspectType SUBMODULE whose `includes` is a `listOf` (nix/lib/aspects/types.nix:
  # 696-699): TWO modules setting `den.default.includes` CONCATENATE in module-definition order. Through the
  # freeform `anything` the two lists CONFLICTED (`anything` never concatenates a nested list-valued key — the
  # SAME R4-radiation wall the `schema`/`policies` fixes hit); `options.default` reproduces v1's deep-merge fold
  # (nix/lib/aspects/types.nix:478-491): lists concat, attrsets recurse, scalars last-def-wins.
  defaultCfg = evalBridgeConfig {
    imports = [
      {
        den.default.includes = [
          { name = "a"; }
          { name = "b"; }
        ];
      }
      { den.default.includes = [ { name = "c"; } ]; }
    ];
  };
  # THE CORPUS SHAPE: a 5-entry base (modules/den/defaults.nix — define-user/hostname/primary-user/inputs'/
  # self') + a 1-entry append (modules/den/batteries/nix-on-droid.nix — the drop-user-to-host-on-droid policy)
  # fold into ONE 6-entry aspect, order preserved. This is exactly the RUNG's conflicting pair.
  corpusShapeCfg = evalBridgeConfig {
    imports = [
      {
        den.default.includes = [
          { name = "define-user"; }
          { name = "hostname"; }
          { name = "primary-user"; }
          { name = "inputs'"; }
          { name = "self'"; }
        ];
      }
      {
        den.default.includes = [
          {
            __isPolicy = true;
            name = "drop-user-to-host-on-droid";
          }
        ];
      }
    ];
  };
  # SINGLE-module: byte-stable — the merged value is exactly the raw def, no wrapping/synthesis at the bridge.
  singleCfg = evalBridgeConfig { den.default.includes = [ { name = "only"; } ]; };
  # NON-includes field surface: freeform class-key attrsets DEEP-MERGE across modules (v1 aspectKeyType) while
  # `includes` concatenates simultaneously, and a scalar (`description`) keeps last-def-wins (v1 str option).
  mixedCfg = evalBridgeConfig {
    imports = [
      {
        den.default = {
          includes = [ { name = "x"; } ];
          nixos.a = 1;
          description = "first";
        };
      }
      {
        den.default = {
          includes = [ { name = "y"; } ];
          nixos.b = 2;
          description = "second";
        };
      }
    ];
  };

  # ── den.batteries RAW-PRESERVATION through the bridge (the FOURTH declared-option; the bare-fn-battery RUNG) ──
  # A battery VALUE riding the freeform `anything` is mangled the SAME way a top-level policy fn is: a TOP-LEVEL
  # bare-fn battery (`den.batteries.primary-user = { user, host, ... }: …`, batteries.nix:119-150) hits nixpkgs'
  # `types.anything` LAMBDA-merge branch (lib/types.nix:353-359) → wrapped in a bare `arg:` lambda,
  # `functionArgs` ERASED to `{ }`. It then rides `den.default.includes` PRE-MANGLED, so compile's `callGated`
  # gate (v1 can-take.nix parity — reads `functionArgs`) sees `required = [ ]` and fires it UNCONDITIONALLY —
  # at a host scope (no `user`) the wrapper re-applies `userToHostContext { }` → the uncatchable RUNG throw
  # `called without required argument 'user'`. The declared `options.batteries` (a shallow raw-preserving union)
  # keeps the bare fn BYTE-IDENTICAL so its real formals survive to the gate. This surfaced only once 8cf3f31
  # unblocked the `den.default` cross-module fold so the primary-user element could radiate to a host scope.
  #
  # Reconstruct the REAL bridge WITH batteries.nix imported (the shim provisions the corpus batteries there,
  # exactly as flake.nix's `flakeModule` does); `withSystem`/`inputs`/`self` are stubbed — only inputs'/self'
  # force them, and those batteries are never referenced here.
  batteriesArgs = {
    _module.args = {
      withSystem = _sys: g: g { };
      inputs = { };
      self = { };
    };
  };
  batteriesBridgeCfg =
    (lib.evalModules {
      modules = [
        flakeStub
        bridge
        batteriesArgs
        "${denHoagSrc}/lib/compat/batteries.nix"
        fleetBase
      ];
    }).config;
  puThroughBridge = batteriesBridgeCfg.den.batteries.primary-user;
  defineUserNestedFn = builtins.head batteriesBridgeCfg.den.batteries.define-user.includes;
  # CONTRAST (the load-bearing proof): the SAME top-level bare-fn shape through `anything.merge` ERASES formals.
  batteryFn =
    { user, host, ... }:
    {
      nixos.users.users.${user.userName}.extraGroups = [ "wheel" ];
    };
  anythingErasedBattery = builtins.functionArgs (
    lib.types.anything.merge
      [ "den" "batteries" "primary-user" ]
      [
        {
          file = "m";
          value = batteryFn;
        }
      ]
  );
  # END-TO-END (the corpus path): primary-user, read through the bridge's `den.batteries` and placed in
  # `den.default.includes` (exactly as corpus modules/den/defaults.nix:28-34), radiated to a REAL crossed host
  # — GATED OUT at the host scope (no `user`), so the host builds and its hostName resolves through the full
  # fixpoint. Pre-fix this throws `userToHostContext called without required argument 'user'` (the RUNG's
  # verbatim blocker).
  batteriesE2ECrossed =
    (lib.evalModules {
      modules = [
        flakeStub
        bridge
        batteriesArgs
        "${denHoagSrc}/lib/compat/batteries.nix"
        (
          { den, ... }:
          {
            den.hosts.x86_64-linux.igloo = { };
            den.aspects.igloo.nixos = hostContent;
            den.default.includes = [ den.batteries.primary-user ];
            den.nixpkgs = nixpkgs;
          }
        )
      ];
    }).config.flake;

  # ── den.aspects RAW-PRESERVING DEEP-MERGE through the bridge (the FIFTH declared-option; the aspects RUNG) ──
  # The corpus drvPath blocker: the freeform `anything` sends a fn at ANY attrset depth through its
  # lambda-merge branch (nixpkgs lib/types.nix:353-359) — SINGLE-DEF INCLUDED, because `anything` always
  # recurses per-key — wrapping it in a bare `arg:` lambda and ERASING `functionArgs`. So EVERY corpus
  # aspect class fn crossed formals-erased, gen-bind's formals-driven wrapAll bound nothing, and the
  # corpus drvPath threw `function 'nixos' called without required argument 'firewall'`
  # (firewall-collector.nix:3) inside the real nixosSystem. The declared `options.aspects` folds with
  # v1's deep-merge (types.nix:478-490, pin 11866c16), which recurses ONLY on collision — a single-def
  # subtree rides raw, unrecursed, so a class fn's formals survive (v1 parity: aspectContentType stores
  # fn defs raw in `__contentValues`, types.nix:421).
  collectorFn =
    { firewall, lib, ... }:
    lib.mkMerge firewall;
  # CONTRAST (the load-bearing proof): the SAME nested single-def class-fn shape through `anything.merge`
  # ERASES formals — the erasure is NOT a multi-def artifact.
  anythingErasedAspect =
    builtins.functionArgs
      (lib.types.anything.merge
        [ "den" "aspects" ]
        [
          {
            file = "m";
            value = {
              core.fw.nixos = collectorFn;
            };
          }
        ]
      ).core.fw.nixos;
  # END-TO-END through the REAL bridge: the extra module's `core.fw` unions with fleetBase's `igloo`
  # (a genuine cross-module den.aspects merge), and the nested class fn keeps its declared formals.
  aspectsCfg = evalBridgeConfig { den.aspects.core.fw.nixos = collectorFn; };
  # THE CORPUS'S ONLY cross-module aspect path (corpus-zero pin, fork A): `core.impermanence` is defined
  # by TWO modules with DISJOINT keys (impermanence.nix: includes/settings/nixos/homeManager;
  # darwin.nix: darwin). The union must carry BOTH class fns raw + the includes list intact. This is the
  # ENTIRE corpus cross-module surface — a future same-key collision has no corpus witness and falls to
  # the last-wins ceiling below.
  impermanenceCfg = evalBridgeConfig {
    imports = [
      {
        den.aspects.core.impermanence = {
          includes = [
            { name = "btrfs"; }
            { name = "zfs"; }
          ];
          nixos = _: { imports = [ ]; };
          homeManager = {
            home.persistence = { };
          };
        };
      }
      {
        den.aspects.core.impermanence.darwin = _: { };
      }
    ];
  };
  # CEILING pin (fork A): fn-vs-fn at ONE class key is LAST-DEF-WINS (v1 collects BOTH via
  # `__contentValues`, types.nix:421 — adopt collect-both only when a real 2-module same-key class def
  # appears in the corpus). This test pins the current semantics so any change announces here.
  fnFnCfg = evalBridgeConfig {
    imports = [
      { den.aspects.col.nixos = { firewall, ... }: firewall; }
      {
        den.aspects.col.nixos =
          { age-secrets, ... }:
          age-secrets;
      }
    ];
  };
  # END-TO-END CROSSED (the corpus fail shape, in-repo): a registered channel + the bare-arg collector
  # aspect (firewall-collector verbatim) + an emitting host, through the REAL bridge into a REAL crossed
  # NixOS system. Pre-fix this threw the RUNG's verbatim blocker (`called without required argument
  # 'firewall'`); post-fix the binding flows and the emitted fragment lands in the built config.
  aspectsE2ECrossed =
    (lib.evalModules {
      modules = [
        flakeStub
        bridge
        (
          { den, ... }:
          {
            den.quirks.firewall.description = "bridge channel";
            den.aspects.fw-collector.nixos =
              { firewall, lib, ... }:
              lib.mkMerge firewall;
            den.aspects.igloo = {
              includes = [ den.aspects.fw-collector ];
              nixos = hostContent;
              firewall = {
                networking.firewall.allowedTCPPorts = [ 7654 ];
              };
            };
            den.hosts.x86_64-linux.igloo = { };
            den.nixpkgs = nixpkgs;
          }
        )
      ];
    }).config.flake;

  # ── #68: the schema belt carries the kind-decls' SHORTHAND CONFIG (the hm gate). The corpus's
  #    `den.schema.user.classes = mkDefault [ "homeManager" ]` (users.nix:103) must become a
  #    `config.classes` DEFINITION when the corpus registry imports the kind value (users.nix:45
  #    `imports = [ den.schema.user ]`), beating the registry option's own `default = [ "user" ]` —
  #    gen-schema's strippedDefs semantics (entry-type.nix), dropped by the original belt rebuild
  #    (bridge.nix `rawConfigModulesOf`). The witness imports the emitted kind value into a
  #    registry-shaped instance eval exactly as the corpus does. ──
  schemaShorthandDen =
    (lib.evalModules {
      modules = [
        flakeStub
        bridge
        {
          den.hosts.x86_64-linux.igloo = { };
          den.schema.user.isEntity = true;
          den.schema.user.classes = lib.mkDefault [ "homeManager" ];
        }
      ];
    }).config.den;
  registryInstanceClasses =
    kindValue:
    (lib.evalModules {
      modules = [
        {
          freeformType = lib.types.lazyAttrsOf lib.types.raw;
          imports = [ kindValue ]; # the corpus registryUserType shape (users.nix:41-46)
          options.classes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "user" ]; # the corpus registry default the shorthand def must BEAT
          };
          config._module.args.user = { };
        }
      ];
    }).config.classes;
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

    # den.default: two modules' `includes` CONCATENATE in module-definition order (v1 listOf semantics) —
    # the RUNG's conflict (the freeform `anything` threw "conflicting definition values") is now a clean fold.
    test-default-includes-concat-order = {
      expr = map (x: x.name) defaultCfg.den.default.includes;
      expected = [
        "a"
        "b"
        "c"
      ];
    };
    # The corpus shape (5-entry base + 1-entry droid append) folds into one ordered 6-entry aspect.
    test-default-corpus-shape = {
      expr = map (x: x.name) corpusShapeCfg.den.default.includes;
      expected = [
        "define-user"
        "hostname"
        "primary-user"
        "inputs'"
        "self'"
        "drop-user-to-host-on-droid"
      ];
    };
    # Single-module: byte-stable — the bridge folds one def to exactly its raw value (no synthesis here; the
    # shim's translateAspect derives provides/_/__functor downstream).
    test-default-single-module-bytestable = {
      expr = singleCfg.den.default;
      expected = {
        includes = [ { name = "only"; } ];
      };
    };
    # Full field surface: class-key attrsets deep-merge, includes concat, scalar last-def-wins — the fields
    # v1's aspectType submodule merges. (Corpus uses only `includes`; this pins the general v1-parity fold.)
    test-default-mixed-fields-merge = {
      expr = {
        includes = map (x: x.name) mixedCfg.den.default.includes;
        nixos = mixedCfg.den.default.nixos;
        description = mixedCfg.den.default.description;
      };
      expected = {
        includes = [
          "x"
          "y"
        ];
        nixos = {
          a = 1;
          b = 2;
        };
        description = "second";
      };
    };

    # den.batteries (the bare-fn-battery RUNG): a TOP-LEVEL bare-fn battery keeps its formals through the REAL
    # bridge (declared `options.batteries` preserves; the freeform `anything` erased them). A record battery's
    # nested include fn (define-user) and a `__functor` battery (unfree) ride byte-identical too.
    test-batteries-barefn-formals-preserved-through-bridge = {
      expr = {
        primaryUserIsFn = builtins.isFunction puThroughBridge;
        primaryUserFnArgs = builtins.functionArgs puThroughBridge;
        defineUserNestedFnArgs = builtins.functionArgs defineUserNestedFn;
        unfreeIsFunctor = batteriesBridgeCfg.den.batteries.unfree ? __functor;
      };
      expected = {
        primaryUserIsFn = true;
        primaryUserFnArgs = {
          host = false;
          user = false;
        };
        defineUserNestedFnArgs = {
          host = false;
          user = false;
        };
        unfreeIsFunctor = true;
      };
    };
    # THE PROOF the declared option is load-bearing: at the SAME nixpkgs lib, `anything.merge` ERASES a
    # top-level bare-fn battery's formals (the root cause) while `options.batteries` preserves them.
    test-batteries-anything-erases-declared-preserves = {
      expr = {
        anything = anythingErasedBattery;
        declared = builtins.functionArgs puThroughBridge;
      };
      expected = {
        anything = { };
        declared = {
          host = false;
          user = false;
        };
      };
    };
    # END-TO-END: primary-user (via `den.batteries`, in `den.default.includes`) radiated to a REAL crossed host
    # is GATED OUT at the host scope — the host builds and hostName resolves (pre-fix: the RUNG's throw).
    test-batteries-e2e-crossed-host-gated-resolves = {
      expr = batteriesE2ECrossed.nixosConfigurations.igloo.config.networking.hostName;
      expected = "igloo";
    };

    # den.aspects (the aspects RUNG): THE PROOF the declared option is load-bearing — at the SAME nixpkgs
    # lib, `anything.merge` ERASES a nested SINGLE-DEF class fn's formals (it always recurses per-key)
    # while the declared deep-merge rides the single-def subtree raw, unrecursed.
    test-aspects-anything-erases-declared-preserves = {
      expr = {
        anything = anythingErasedAspect;
        declared = builtins.functionArgs aspectsCfg.den.aspects.core.fw.nixos;
      };
      expected = {
        anything = { };
        declared = {
          firewall = false;
          lib = false;
        };
      };
    };
    # Cross-module union at the den.aspects ROOT: the extra module's `core.fw` merges beside fleetBase's
    # `igloo`, both subtrees raw (the corpus's one-aspect-per-file radiation shape).
    test-aspects-cross-module-root-union = {
      expr = {
        keys = builtins.sort (a: b: a < b) (builtins.attrNames aspectsCfg.den.aspects);
        iglooIntact = aspectsCfg.den.aspects.igloo.nixos.networking.hostName;
      };
      expected = {
        keys = [
          "core"
          "igloo"
        ];
        iglooIntact = "igloo";
      };
    };
    # THE CORPUS'S ONLY cross-module aspect path (corpus-zero pin): `core.impermanence`'s disjoint-key
    # union carries BOTH class fns as REAL fns and the includes list intact.
    test-aspects-impermanence-disjoint-union = {
      expr = {
        keys = builtins.sort (a: b: a < b) (
          builtins.attrNames impermanenceCfg.den.aspects.core.impermanence
        );
        nixosIsFn = builtins.isFunction impermanenceCfg.den.aspects.core.impermanence.nixos;
        darwinIsFn = builtins.isFunction impermanenceCfg.den.aspects.core.impermanence.darwin;
        includes = map (x: x.name) impermanenceCfg.den.aspects.core.impermanence.includes;
      };
      expected = {
        keys = [
          "darwin"
          "homeManager"
          "includes"
          "nixos"
        ];
        nixosIsFn = true;
        darwinIsFn = true;
        includes = [
          "btrfs"
          "zfs"
        ];
      };
    };
    # CEILING pin (fork A): fn-vs-fn at one class key = LAST-DEF-WINS, formals of the LAST def preserved.
    # v1 collects BOTH (`__contentValues`, types.nix:421) — flipping this test = adopting collect-both.
    test-aspects-fnfn-collision-lastwins-ceiling = {
      expr = builtins.functionArgs fnFnCfg.den.aspects.col.nixos;
      expected = {
        age-secrets = false;
      };
    };
    # END-TO-END CROSSED (the corpus fail shape): the bare-arg collector's binding flows through the REAL
    # bridge — the host builds AND the channel-emitted firewall fragment lands in the built config.
    # Pre-fix: `function 'nixos' called without required argument 'firewall'` (the RUNG's verbatim throw).
    test-aspects-e2e-crossed-collector-binds = {
      expr = {
        hostName = aspectsE2ECrossed.nixosConfigurations.igloo.config.networking.hostName;
        ports = aspectsE2ECrossed.nixosConfigurations.igloo.config.networking.firewall.allowedTCPPorts;
      };
      expected = {
        hostName = "igloo";
        ports = [ 7654 ];
      };
    };

    # ── #68: the schema belt's shorthand-config carry (the hm gate — see the fixture header above).
    #    The kind-decl's `classes = mkDefault [ "homeManager" ]` rides the emitted kind value as a
    #    config DEFINITION, so a corpus-shaped registry instance importing it evaluates
    #    `classes = [ "homeManager" ]` — beating its own `default = [ "user" ]` (v1's gen-schema
    #    strippedDefs semantics; the value the hm-user-detect gate reads). ──
    test-schema-shorthand-config-rides-kind-value = {
      expr = registryInstanceClasses schemaShorthandDen.schema.user;
      expected = [ "homeManager" ];
    };
  };
}
