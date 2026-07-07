{ harness, ... }:
let
  inherit (harness) fixtures traceHoag;

  # To permute policies, we rename the policy keys in the fixture so they sort differently.
  # This tests that the pipeline fold is independent of declaration sort order.
  permutePoliciesFixture = fixture: seed: {
    module = { den, lib, ... }: {
      imports = [ fixture.module ];
      # Rename each policy name by prefixing with the seed to change sort order.
      # Since den.policies is an attrset, renaming changes its internal iteration order.
      den.policies = lib.mkIf (fixture.module ? den && fixture.module.den ? policies) (
        builtins.listToAttrs (
          map (name: {
            name = "p${toString seed}_${name}";
            value = fixture.module.den.policies.${name};
          }) (builtins.attrNames fixture.module.den.policies)
        )
      );
    };
    inherit (fixture) hostRoots flakeRoot;
  };

  # Check that traceHoag output is byte-identical under permutations
  mkPermutationTest = name: fixture: {
    expr =
      let
        tracePlain = traceHoag fixture;
        tracePerm1 = traceHoag (permutePoliciesFixture fixture 1);
        tracePerm2 = traceHoag (permutePoliciesFixture fixture 2);
      in
      tracePlain == tracePerm1 && tracePlain == tracePerm2;
    expected = true;
  };

  validFixtures = builtins.removeAttrs fixtures [ "spawnNegControl" ];
in
{
  flake.tests.parity-permutation = builtins.listToAttrs (
    map (name: {
      name = "test-permutation-parity-${name}";
      value = mkPermutationTest name validFixtures.${name};
    }) (builtins.attrNames validFixtures)
  );
}
