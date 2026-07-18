# The FLAKE-PARTS suite (vocabulary spec §4.1/§4.4, spec §12 step 4c-iii). `FlakeInfo` is a framework
# product — the OPAQUE transposed flake-outputs attrset a hosted flake-parts render produces, value-nested
# verbatim like `HiveInfo` (den never type-walks it). It is framework-reserved (its name rides
# `frameworkProducts`, so `reservedNames` auto-includes it): a `consumes = "FlakeInfo"` output family compiles
# with the derived artifact mode, and a user re-registration aborts NAMED. Corpus-inert — added-but-unconsumed,
# so parity is byte-untouched (the same posture `HiveInfo` sits in). See REFERENCE.md.
{
  denHoag,
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
  };
}
