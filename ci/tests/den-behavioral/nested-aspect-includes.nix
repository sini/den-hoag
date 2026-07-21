# den v1 BEHAVIORAL migration — deadbugs/nested-aspect-includes.nix (denful/den templates/ci/modules/
# deadbugs/nested-aspect-includes.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix`
# scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1 (only the dropped
# `denTest`/`lib` module args differ — `lib` is spliced by the scaffold). Concern: `include` (including a
# nested aspect must NOT auto-walk its sub-aspects; explicit include is required). No numeric issue ID on
# the v1 source (its own header cites a placeholder `issues/XXX`), so the deadbug-origin suffix
# (migration rule 2) uses the source file's own basename: `-regression-nested-aspect-includes`.
{
  denHoagFlakeModule,
  homeManagerModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };
in
{
  flake.tests.den-include = {

    # Including dev-tools should NOT pull in dev-tools.foo
    test-nested-sub-aspect-not-auto-included-regression-nested-aspect-includes = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.apps.dev-tools = {
          nixos.environment.variables.DEV_TOOLS = "yes";
        };

        den.aspects.apps.dev-tools.foo = {
          nixos.environment.variables.DEV_TOOLS_FOO = "yes";
        };

        # Include only dev-tools, not foo
        den.aspects.igloo.includes = [ den.aspects.apps.dev-tools ];

        expr = {
          hasDevTools = igloo.environment.variables.DEV_TOOLS == "yes";
          # foo should NOT be included
          hasFoo = igloo.environment.variables ? DEV_TOOLS_FOO;
        };
        expected = {
          hasDevTools = true;
          hasFoo = false;
        };
      }
    );

    # Explicitly including the sub-aspect should work
    test-nested-sub-aspect-explicit-include-regression-nested-aspect-includes = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.apps.dev-tools = {
          nixos.environment.variables.DEV_TOOLS = "yes";
        };

        den.aspects.apps.dev-tools.foo = {
          nixos.environment.variables.DEV_TOOLS_FOO = "yes";
        };

        # Include both explicitly
        den.aspects.igloo.includes = [
          den.aspects.apps.dev-tools
          den.aspects.apps.dev-tools.foo
        ];

        expr = {
          hasDevTools = igloo.environment.variables.DEV_TOOLS == "yes";
          hasFoo = igloo.environment.variables.DEV_TOOLS_FOO == "yes";
        };
        expected = {
          hasDevTools = true;
          hasFoo = true;
        };
      }
    );

  };
}
