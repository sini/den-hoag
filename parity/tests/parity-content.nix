{ harness, ... }:
let
  inherit (harness) prelude fixtureNames fixtures;
  inherit (harness) contentHoag crossPipelineHoag contentV1 crossPipelineV1;

  mkContentTest = name: fixture: {
    expr =
      let
        v1Output = contentV1 fixture;
        hoagOutput = contentHoag fixture;
      in
      v1Output == hoagOutput;
    expected = true;
  };

  # Cross-pipeline hash equality (P2.2)
  mkCrossPipelineTest = name: fixture: {
    expr =
      let
        v1Hash = crossPipelineV1 fixture;
        hoagHash = crossPipelineHoag fixture;
      in
      v1Hash == hoagHash;
    expected = true;
  };

in
{
  flake.tests.parity-content = {
    # Content equality for all fixtures
    test-content-parity = prelude.genAttrs fixtureNames (
      name: mkContentTest name fixtures.${name}
    );

    # Cross-pipeline hash parity
    test-cross-pipeline-parity = prelude.genAttrs fixtureNames (
      name: mkCrossPipelineTest name fixtures.${name}
    );
  };
}
