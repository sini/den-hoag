{ harness, ... }:
let
  inherit (harness)
    fixtures
    contentHoag
    crossPipelineHoag
    contentV1
    crossPipelineV1
    ;

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

  validFixtures = builtins.removeAttrs fixtures [ "spawnNegControl" ];
in
{
  flake.tests.parity-content =
    builtins.listToAttrs (
      map (name: {
        name = "test-content-parity-${name}";
        value = mkContentTest name validFixtures.${name};
      }) (builtins.attrNames validFixtures)
    )
    // builtins.listToAttrs (
      map (name: {
        name = "test-cross-pipeline-parity-${name}";
        value = mkCrossPipelineTest name validFixtures.${name};
      }) (builtins.attrNames validFixtures)
    );
}
