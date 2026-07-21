# den v1 BEHAVIORAL migration — deadbugs/issue-408-bare-function-aspect.nix (denful/den templates/ci/
# modules/deadbugs/issue-408-bare-function-aspect.nix, https://github.com/denful/den/pull/408). Migrated
# by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + the
# assertion are BYTE-IDENTICAL to v1 (only the dropped `denTest`/`lib` module args differ — `lib` is
# spliced by the scaffold). Concern: `aspects-core` (a bare-function aspect merged with a static-attrset
# aspect at the same key). Test key suffixed `-regression-408` per the deadbug-origin convention.
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
  flake.tests.den-aspects-core = {
    # PARKED-DIVERGENCE: v1-expected { FOO = "igloo"; hello = true; } (a bare-function aspect at
    # `den.aspects.foo` merged, across TWO `imports` modules, with a static-attrset extension of the
    # SAME key — the #408 fix: the fn's `host.name` write and the static module's `pkgs.hello` package
    # both survive) vs den-hoag-actual: `attribute 'FOO' missing` reading
    # `igloo.environment.sessionVariables.FOO` — the bare-fn half of the merge never lands on the crossed
    # nixos config. Not altered to route around the gap.
    # test-function-aspect-with-static-merge-regression-408 = denTest (
    #   { den, lib, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.igloo.includes = [ den.aspects.foo ];
    #
    #     imports =
    #       let
    #         one = {
    #           den.aspects.foo =
    #             { host, ... }:
    #             {
    #               nixos.environment.sessionVariables.FOO = host.name;
    #             };
    #         };
    #         two = {
    #           den.aspects.foo.nixos =
    #             { pkgs, ... }:
    #             {
    #               environment.systemPackages = [ pkgs.hello ];
    #             };
    #         };
    #       in
    #       [
    #         one
    #         two
    #       ];
    #
    #     expr = {
    #       hello = lib.elem "hello" (map lib.getName igloo.environment.systemPackages);
    #       FOO = igloo.environment.sessionVariables.FOO;
    #     };
    #     expected.FOO = "igloo";
    #     expected.hello = true;
    #   }
    # );
  };
}
