{ harness, ... }:
let
  inherit (harness) prelude fixtureNames fixtures;
  inherit (harness) traceHoag;

  # Create a modified fixture that sets share.core = true for all output classes
  shareCoreFixture = fixture: {
    module = { den, ... }: {
      imports = [ fixture.module ];
      den.classes.nixos.share.core = true;
      den.classes."home-manager".share.core = true;
      den.classes."k8s-manifests".share.core = true;
    };
    inherit (fixture) hostRoots flakeRoot;
  };

  # Check that traceHoag output is exactly the same whether share.core is true or false
  mkClassShareTest = name: fixture: {
    expr =
      let
        tracePlain = traceHoag fixture;
        traceShared = traceHoag (shareCoreFixture fixture);
      in
      tracePlain == traceShared;
    expected = true;
  };

in
{
  flake.tests.parity-class-share = {
    test-class-share-parity = prelude.genAttrs fixtureNames (
      name: mkClassShareTest name fixtures.${name}
    );
  };
}
