{ harness, ... }:
let
  inherit (harness) fixtures traceHoag;

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

  validFixtures = builtins.removeAttrs fixtures [ "spawnNegControl" ];
in
{
  flake.tests.parity-class-share = builtins.listToAttrs (
    map (name: {
      name = "test-class-share-parity-${name}";
      value = mkClassShareTest name validFixtures.${name};
    }) (builtins.attrNames validFixtures)
  );
}
