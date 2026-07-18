# The FLAKE-PARTS suite (vocabulary spec §4.1/§4.4, spec §12 step 4c-iii). `FlakeInfo` is a framework
# product — the OPAQUE transposed flake-outputs attrset a hosted flake-parts render produces, value-nested
# verbatim like `HiveInfo` (den never type-walks it). It is framework-reserved (its name rides
# `frameworkProducts`, so `reservedNames` auto-includes it): a `consumes = "FlakeInfo"` output family compiles
# with the derived artifact mode, and a user re-registration aborts NAMED. Corpus-inert — added-but-unconsumed,
# so parity is byte-untouched (the same posture `HiveInfo` sits in). See REFERENCE.md.
{
  denHoag,
  nixpkgs,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  inherit (denHoag.internal) products compileProducts;
  frameworkTable = compileProducts { };

  # an output family CONSUMING FlakeInfo — its mode derives from the product (artifact). At HEAD FlakeInfo is
  # unregistered, so `checkConsumes` aborts; the `FlakeInfo` framework row makes the family compile.
  flakeConsumerFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.outputs.flake = {
        at = _point: _e: [ ];
        consumes = "FlakeInfo";
      };
    }
  ];
  # a user re-registering the framework-reserved FlakeInfo name → the reserved-name NAMED abort.
  reRegisterFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.products.FlakeInfo = {
        mode = "artifact";
      };
    }
  ];

  # ── the SELF-KNOT (Case A): a render reading `self.<siblingFamily>.<leaf>` across the recursive familyOutputs
  # knot. TWO zero-member flake-parts collectors — `srcColl` (needsSelf=false) produces a KNOWN leaf, `selfColl`
  # (needsSelf=true) reads it back through the curried `self`. The output KEY SPINE is self-INDEPENDENT (static
  # family/leaf keys); only the LEAF VALUE reads self — so the knot is well-founded and TERMINATES, the leaf
  # resolving non-vacuously to the KNOWN string. (Case B — a spine derived from self — diverges with a
  # tryEval-UNCATCHABLE infinite recursion, so it is witnessed OUT OF BAND, never a ci oracle.)
  # THE LEAF IS A STRING DELIBERATELY (don't "improve" it to read `self.nixosConfigurations`): a hosted render
  # reading a built-in family would compare a collect ARTIFACT — module functions are `==`-incomparable — so this
  # MECHANISM witness uses a controlled string; the realistic built-in self-read rides the native-adapter witness.
  selfKnotFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.classes.flake = { };
      config.den.collectors.srcColl = {
        class = "flake";
        render = "srcRender";
      };
      config.den.collectors.selfColl = {
        class = "flake";
        render = "selfRender";
      };
      config.den.renders.srcRender = {
        evaluator = _memberMap: {
          v = "KNOWN";
        };
        produces = "FlakeInfo";
        aggregate = true;
        output = "fpA";
      };
      config.den.renders.selfRender = {
        evaluator =
          { self }:
          _memberMap: {
            readback = self.fpA.srcColl.v;
          };
        produces = "FlakeInfo";
        aggregate = true;
        needsSelf = true;
        output = "fpB";
      };
      config.den.outputs.fpA = {
        at = _point: e: [
          "fpA"
          e.name
        ];
        consumes = "FlakeInfo";
      };
      config.den.outputs.fpB = {
        at = _point: e: [
          "fpB"
          e.name
        ];
        consumes = "FlakeInfo";
      };
    }
  ];

  # ── the FLAKE-PARTS FAMILY MOUNT + root transposition (composes on the collector aggregate arm (§4.7) + the
  # self-knot curry — NO new mount code). A flake-parts family is a ZERO-MEMBER collector `fp` with an aggregate
  # render (needsSelf=true, produces FlakeInfo) whose `output` family declares `at = _: _: [ ]` — so the render's
  # transposed attrset merges FLAT AT ROOT (nest.nix `[ ]`⇒flat) alongside the built-in `nixosConfigurations`.
  # The flake-parts modules are CLOSED OVER in the stub evaluator (not a collector content bucket). Beside a
  # real nixos host `h`, the stub emits a DISJOINT key (`flakeOut`) AND a COLLIDING one (`nixosConfigurations.
  # fpExtra`) so both the flat-merge and the recursive familyMerge (collision → coexist, never last-wins) show.
  flakePartsFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.classes.flake = { };
      config.den.collectors.fp = {
        class = "flake";
        render = "fpRender";
      };
      config.den.renders.fpRender = {
        evaluator =
          { self }:
          _memberMap: {
            flakeOut = "TRANSPOSED";
            nixosConfigurations = {
              fpExtra = "COEXIST";
            };
          };
        produces = "FlakeInfo";
        aggregate = true;
        needsSelf = true;
        output = "fpFamily";
      };
      config.den.outputs.fpFamily = {
        at = _: _: [ ];
        consumes = "FlakeInfo";
      };
      config.den.nixosHost.h = { };
    }
    (
      { config, ... }:
      {
        config.den.aspects.hostContent.nixos.tag = "h-content";
        config.den.include = [
          {
            at = config.den.nixosHost.h;
            aspects = [ config.den.aspects.hostContent ];
          }
        ];
      }
    )
  ];

  # ── the THREE-ADAPTER genericity floor (the family ROW is an INTERFACE, not flake-parts-shaped). THREE
  # adapters express through ONE family-row surface, differing only in the ADAPTER MECHANISM (`render` + `at`)
  # and the PRODUCT each types (`consumes`): (1) flake-parts — an aggregate render (needsSelf) + `at = _: _: [ ]`
  # transposition; (2) plain-flake — a PLAIN aggregate render (needsSelf=false) + a direct-attrset `at` (no
  # transposition); (3) bare-root — the shipped built-in fold (the nixos family: no user render/at, params=[],
  # value-mode). `stripRow` drops the function-valued mechanism fields so the remainder is `==`-comparable.
  stripRow =
    row:
    removeAttrs row [
      "render"
      "at"
    ];
  adapterFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.classes.flake = { };
      config.den.collectors.fpColl = {
        class = "flake";
        render = "adapterFp";
      };
      config.den.collectors.pfColl = {
        class = "flake";
        render = "adapterPlain";
      };
      config.den.renders.adapterFp = {
        evaluator =
          { self }:
          _memberMap: {
            fpOut = "FP";
          };
        produces = "FlakeInfo";
        aggregate = true;
        needsSelf = true;
        output = "fp";
      };
      config.den.renders.adapterPlain = {
        evaluator = _memberMap: {
          pfOut = "PF";
        };
        produces = "FlakeInfo";
        aggregate = true;
        needsSelf = false;
        output = "pf";
      };
      config.den.outputs.fp = {
        at = _: _: [ ];
        consumes = "FlakeInfo";
      };
      config.den.outputs.pf = {
        at = _point: e: [
          "pf"
          e.name
        ];
        consumes = "FlakeInfo";
      };
      config.den.nixosHost.h = { };
    }
    (
      { config, ... }:
      {
        config.den.aspects.hc.nixos.tag = "t";
        config.den.include = [
          {
            at = config.den.nixosHost.h;
            aspects = [ config.den.aspects.hc ];
          }
        ];
      }
    )
  ];

  # ── THE REAL FLAKE-PARTS CROSSING (spec §12 step 4c-iii): the witnesses below exercise the aggregate
  # flake-parts render through gen-flake's REAL `terminals.mkFlakeTerminal` — a genuine `flake-parts.lib.
  # evalFlakeModule` inside gen-flake's sanctioned nixpkgs/flake-parts boundary — NOT the mechanism stubs above.
  # `mkFlakeTerminal` ships in gen-flake but is unpublished as of this rung, so den-hoag reaches it via
  # `--override-input den-hoag/gen-flake path:<local gen-flake>`. OVERRIDE-GATED: on a plain (unpinned) ci the
  # crossing is absent, so the two witnesses whose render `evaluator` CALLS `mkFlakeTerminal` — W1 (no-translation)
  # and W2 (real-knot) — hit the null `internal.mkFlakeTerminal` and fail; they are GREEN only under the override,
  # until the gen-flake push + den-hoag pin bump makes the pushed history plain-ci-green. W3 (adapter-mount) reads
  # NO mkFlakeTerminal — it builds a plain nixos fleet and mounts via the CORE `denHoag.flakeAdapter` (always
  # non-null), so it would pass plain ci on its own; it simply co-lives in this override-gated block. The
  # mechanism witnesses above (stub evaluators) stay plain-ci-green — they prove the mount/transposition/curry
  # with no flake-parts eval. PARITY never references any of this: the byte-identity gate drives mkDen directly,
  # names no render evaluator, and runs WITHOUT the override.
  mkFlakeTerminal = denHoag.internal.mkFlakeTerminal;

  # a SYNTHETIC ecosystem-shaped flake-parts module — the treefmt-nix SHAPE: it declares its OWN `perSystem`
  # option submodule via `flake-parts-lib.mkPerSystemOption`, sets it, and lifts a flake-level output. Hermetic
  # (no real treefmt-nix, no nixpkgs package build). It rides UNMODIFIED through the hosted eval — den never
  # rewrites an ecosystem module; the flake-parts crossing hosts it verbatim (NO-TRANSLATION).
  ecoModule =
    { flake-parts-lib, ... }:
    {
      options.perSystem = flake-parts-lib.mkPerSystemOption (
        { lib, ... }:
        {
          options.demoFmt = lib.mkOption {
            type = lib.types.str;
            default = "unset";
          };
        }
      );
      config.perSystem = _: { demoFmt = "treefmt-shaped"; };
      config.flake.ecosystemProof = "VERBATIM";
    };

  # W1 NO-TRANSLATION: `ecoModule` fed UNMODIFIED to the real flake-parts crossing. The render's `evaluator`
  # closes over `[ ecoModule ]` + the real flake `inputs`; mkFlakeTerminal hosts them and returns the transposed
  # `config.flake`, value-nested FLAT at root (`at = _: _: [ ]`). `outputs.ecosystemProof` is the module's own
  # flake output, byte-unchanged.
  noTranslationFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.classes.flake = { };
      config.den.collectors.eco = {
        class = "flake";
        render = "ecoRender";
      };
      config.den.renders.ecoRender = {
        evaluator =
          { self }:
          _memberMap:
          mkFlakeTerminal {
            inherit self;
            inputs = { inherit nixpkgs; };
            modules = [ ecoModule ];
            systems = [ "x86_64-linux" ];
          };
        produces = "FlakeInfo";
        aggregate = true;
        needsSelf = true;
        output = "ecoFamily";
      };
      config.den.outputs.ecoFamily = {
        at = _: _: [ ];
        consumes = "FlakeInfo";
      };
    }
  ];

  # W2 REAL-KNOT (Case A) on real flake-parts. `srcColl` (needsSelf=false) produces a KNOWN string leaf;
  # `knotColl`'s HOSTED flake-parts module reads `self.src.srcColl.v` across the recursive familyOutputs knot.
  # Here `self` is the flake-parts `self` MODULE ARG: mkFlakeTerminal threads the den knot as flake-parts' self,
  # and flake-parts uses the EXPLICITLY-passed `inputs` (never `self.inputs`, evalFlakeModule lib.nix:142), so
  # the knot rides through untouched. The leaf is a STRING (a built-in artifact leaf is module-fn-`==`-
  # incomparable — the string-leaf ruling). Terminates: the output KEY SPINE is self-independent, only the
  # leaf VALUE reads self.
  realKnotFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.classes.flake = { };
      config.den.collectors.srcColl = {
        class = "flake";
        render = "srcRender";
      };
      config.den.collectors.knotColl = {
        class = "flake";
        render = "knotRender";
      };
      config.den.renders.srcRender = {
        evaluator = _memberMap: {
          v = "KNOWN";
        };
        produces = "FlakeInfo";
        aggregate = true;
        output = "src";
      };
      config.den.renders.knotRender = {
        evaluator =
          { self }:
          _memberMap:
          mkFlakeTerminal {
            inherit self;
            inputs = { inherit nixpkgs; };
            modules = [ { flake.readback = self.src.srcColl.v; } ];
            systems = [ "x86_64-linux" ];
          };
        produces = "FlakeInfo";
        aggregate = true;
        needsSelf = true;
        output = "knot";
      };
      config.den.outputs.src = {
        at = _point: e: [
          "src"
          e.name
        ];
        consumes = "FlakeInfo";
      };
      config.den.outputs.knot = {
        at = _: _: [ ];
        consumes = "FlakeInfo";
      };
    }
  ];

  # W3 ADAPTER MOUNT: the THIN flake-adapter — a pure mount `builtFleet -> { config.flake = builtFleet.outputs; }`.
  # A greenfield v2 consumer calls mkDen DIRECTLY, then `imports = [ (den.flakeAdapter built) ]` hands the
  # transposed family map to flake-parts' `config.flake` (the transposition already happened INSIDE mkDen). It
  # coexists with bridge.nix (the v1-compat oracle) — zero shared splice. This fleet carries a real nixos member
  # so the mount is non-vacuous.
  adapterMountFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.nixosHost.h = { };
    }
    (
      { config, ... }:
      {
        config.den.aspects.hc.nixos.tag = "t";
        config.den.include = [
          {
            at = config.den.nixosHost.h;
            aspects = [ config.den.aspects.hc ];
          }
        ];
      }
    )
  ];
in
{
  flake.tests.flakeparts = {
    # FlakeInfo is a framework product with the artifact mode (OPAQUE, value-nested like HiveInfo).
    test-flakeinfo-is-artifact-product = {
      expr = products.modeOf frameworkTable "FlakeInfo";
      expected = "artifact";
    };
    # a `consumes = "FlakeInfo"` output family compiles, its mode derived as artifact.
    test-flakeinfo-family-compiles = {
      expr = flakeConsumerFleet.den.outputs.flake.mode;
      expected = "artifact";
    };
    # a user re-registering the reserved FlakeInfo name aborts CATCHABLE-NAMED.
    test-flakeinfo-reserved-reregister-aborts = {
      expr = throws reRegisterFleet.den.products;
      expected = true;
    };

    # THE SELF-KNOT (Case A, the ONLY executed knot oracle): `selfColl`'s render reads `self.fpA.srcColl.v`
    # across the recursive familyOutputs knot and RESOLVES to the KNOWN leaf — non-vacuous (a real value, not
    # merely key-present), and terminating (the output spine is self-independent, only the leaf reads self).
    test-self-knot-case-a-resolves = {
      expr = selfKnotFleet.outputs.fpB.selfColl.readback;
      expected = "KNOWN";
    };
    # the needsSelf=false path is BYTE-UNTOUCHED: `srcColl`'s render is called `evaluator memberMap` (no curry),
    # so a self-free collector produces its output exactly as the shipped HiveInfo/SystemInfo collectors do.
    test-needsself-false-untouched = {
      expr = selfKnotFleet.outputs.fpA.srcColl.v;
      expected = "KNOWN";
    };

    # the flake-parts render's transposed attrset merges FLAT AT ROOT (at = _: _: [ ]) — its disjoint key sits
    # at the fleet root alongside the built-in families.
    test-flakeparts-transposes-at-root = {
      expr = flakePartsFleet.outputs.flakeOut;
      expected = "TRANSPOSED";
    };
    # the built-in fold is INTACT — the nixos host still surfaces as nixosConfigurations.<host> (the guard-widen
    # composes the flake-parts arm ALONGSIDE the built-in fold, never replacing it).
    test-flakeparts-builtin-fold-intact = {
      expr = (flakePartsFleet.outputs.nixosConfigurations or { }) ? h;
      expected = true;
    };
    # KEY COLLISION: the transposed output shares the `nixosConfigurations` key with the built-in family →
    # `familyMerge` RECURSES and BOTH entries coexist (the built-in host `h` AND the flake-parts `fpExtra`),
    # never last-wins clobber — the spine-deepening merge path the disjoint-keys case doesn't exercise.
    test-flakeparts-collision-coexist = {
      expr =
        let
          nc = flakePartsFleet.outputs.nixosConfigurations or { };
        in
        (nc ? h) && (nc ? fpExtra);
      expected = true;
    };

    # THE THREE-ADAPTER FLOOR (a): for a FIXED product (FlakeInfo), flake-parts and plain-flake express through
    # the SAME family row — strip the mechanism fields `{ render, at }` and the remainder is EQUAL and
    # NON-VACUOUS (`{ consumes = "FlakeInfo"; contentClass = null; mode = "artifact"; params = [ ]; requires =
    # [ ] }`). So `render` + `at` are the SOLE adapter-mechanism differentiators; the row is adapter-agnostic.
    test-adapter-strip-equal-same-product = {
      expr = (stripRow adapterFleet.den.outputs.fp) == (stripRow adapterFleet.den.outputs.pf);
      expected = true;
    };
    # (b) the BARE-ROOT (the shipped built-in nixos fold, over SystemInfo) IS the third adapter over the
    # IDENTICAL family-row INTERFACE — all three rows carry exactly the 7-field surface. (Strip-equal can't be
    # 3/3: a bare no-render family can't PRODUCE a FlakeInfo, so the bare-root is over a different PRODUCT —
    # `consumes` differs; the SURFACE does not.)
    test-adapter-interface-identity-bare-root = {
      expr =
        (builtins.attrNames adapterFleet.den.outputs.nixosConfigurations)
        == (builtins.attrNames adapterFleet.den.outputs.fp);
      expected = true;
    };
    # (c) the bare-root differs from flake-parts ONLY in the mechanism (`render`/`at`, the stripped function
    # fields) + the PRODUCT (`consumes`): strip those and the remaining row is EQUAL (`{ contentClass; mode;
    # params; requires }`) — "differs only in mechanism + product" made explicit, no function comparison.
    test-adapter-bare-root-differs-only-in-product = {
      expr =
        (removeAttrs (stripRow adapterFleet.den.outputs.fp) [ "consumes" ])
        == (removeAttrs (stripRow adapterFleet.den.outputs.nixosConfigurations) [ "consumes" ]);
      expected = true;
    };

    # ── THE REAL FLAKE-PARTS CROSSING (override-gated — see the block comment in the `let`) ──
    # W1 NO-TRANSLATION: the synthetic ecosystem-shaped module rides UNMODIFIED through the real hosted eval; its
    # own flake output surfaces byte-unchanged at the fleet root (den translated nothing).
    test-flakeparts-no-translation-verbatim = {
      expr = noTranslationFleet.outputs.ecosystemProof;
      expected = "VERBATIM";
    };
    # W2 REAL-KNOT (Case A): a hosted flake-parts module reads a sibling family's leaf across the knot on the REAL
    # mkFlakeTerminal and resolves to the KNOWN string — the self-knot terminates on real flake-parts (de-risks
    # the L2 template capstone).
    test-flakeparts-real-knot-case-a = {
      expr = realKnotFleet.outputs.readback;
      expected = "KNOWN";
    };
    # W3 ADAPTER MOUNT: the thin `flakeAdapter` hands the built fleet's transposed family map to `config.flake` —
    # the nixos member surfaces under `config.flake.nixosConfigurations` and the built-in family keys are present.
    test-flake-adapter-mounts-outputs = {
      expr =
        let
          cf = (denHoag.flakeAdapter adapterMountFleet).config.flake;
        in
        ((cf.nixosConfigurations or { }) ? h) && (cf ? darwinConfigurations);
      expected = true;
    };
  };
}
