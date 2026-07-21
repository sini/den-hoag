# den v1 BEHAVIORAL migration — public-api/nested-aspects.nix (denful/den
# templates/ci/modules/public-api/nested-aspects.nix). Migrated by copy + arg-rename onto the
# `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + the assertion are BYTE-IDENTICAL to v1.
# HOST-scope nixos-only (the `igloo` helper, crossed via crossNixos). test-direct-nesting-nixos: a nested
# sub-aspect reached by explicit self-include (`den.aspects.igloo.servers`), forwarding to the host's real
# nixos config. (The multi-module attrset-merge proof lives in `multi-file-merge.nix`; the fn-vs-attrset
# parametric-parent collision — v1's `test-nested-scope-propagation` — is a bridge v1DeepMerge ceiling, see
# the report, so it is NOT migrated here.)
{
  denHoagFlakeModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit denHoagFlakeModule nixpkgs nixpkgsLib;
    flakeParts = genInputs.flake-parts;
  };
in
{
  flake.tests.den-nested-aspects = {

    # Direct nesting with nixos class key — requires explicit include
    test-direct-nesting-nixos = denTest (
      {
        den,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo = {
          includes = [ den.aspects.igloo.servers ];
          servers.nixos.networking.hostName = "nested-test";
        };

        expr = igloo.networking.hostName;
        expected = "nested-test";
      }
    );

  };
}
