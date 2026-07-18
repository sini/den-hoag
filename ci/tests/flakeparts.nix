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
  };
}
