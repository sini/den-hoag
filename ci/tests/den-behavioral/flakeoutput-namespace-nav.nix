# Behavioral witness — a nested aspect key whose NAME collides with a v1 flake-SYSTEM-OUTPUT name
# (`packages`/`apps`/`checks`/`devShells`/`legacyPackages`), used as an aspect NAMESPACE directory. Under den
# v2 those names are opt-in classes (`den.features.flakeOutputClasses`, default OFF), so a nested
# `<ns>.<output>.<leaf>` key types as a plain navigable NAMESPACE, not an opaque class-content terminal.
#
# Runs through the den-hoag BRIDGE (`_lib/den-compat-test.nix`, `evalFlakeModule`), which wires the
# `builtinsModule` (default OFF) — the LOAD-BEARING gate path (the mkDen-direct compileFull/evalV1 path wires
# only `flakeModuleCore` and never registers these classes at all). The include below is captured off the
# CONFIG-side `den` arg, which the bridge binds to the NAVIGATION view (`_module.args.den = annotatedViewNav`,
# bridge.nix:738) — the SAME surface a `with den.aspects; [ <ns>.<output>.<leaf> ]` include reads. So with the
# feature OFF the nav intermediate `<ns>.<output>` is a navigable namespace and the include resolves the leaf;
# MUTATION-PROVABLE end-to-end: flipping the feature ON registers the output name as a class, the nav
# intermediate types opaque, and this include's leaf becomes an (uncatchable) native miss that fails the build
# (the implicit-intermediate-under-a-registered-class shape). The ON side's structural mutation witness
# (re-registration) is `compat-feature-severed`'s `flakeOutputClasses` rows.
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
  flake.tests.den-flakeoutput-namespace-nav = {
    # DEFAULT (feature OFF): `apps` is NOT a class, so the nav view types `a.apps` as a NAMESPACE → the leaf
    # `c` (registered content keys: a quirk `q` + the `nixos` class, so it is unmistakably an aspect) navigates
    # and its content merges into the host that includes it.
    test-namespace-leaf-navigates = denTest (
      { den, igloo, ... }:
      {
        den.quirks.q = { };
        den.aspects.a.apps.c = {
          q = [ "x" ];
          nixos.environment.variables.FROM_C = "yes";
        };
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.includes = [ den.aspects.a.apps.c ];

        expr = {
          hasC = igloo.environment.variables ? FROM_C;
        };
        expected = {
          hasC = true;
        };
      }
    );
  };
}
