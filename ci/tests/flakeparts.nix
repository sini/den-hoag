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
  };
}
