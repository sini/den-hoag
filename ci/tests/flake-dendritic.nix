# den v1 `flakeModules.dendritic` witness (denful/den nix/dendritic.nix). den-hoag exposes
# `flakeModules.dendritic` (flake.nix → `// compat.flakeDendritic` → lib/compat/flake-dendritic.nix): the den
# flakeModule dendritic-flavored — a flake-parts module whose sole load-bearing line is
# `imports = [ (inputs.den.flakeModule or { }) ]`, pulling in the full `den.*` option surface. Feature-gated
# behind `den.features.dendritic` (default on). Consumer-eval, additive; nothing in den-hoag's own CI imports
# it, so parity is untouched — this synthetic witness is its only exercise.
#
# Two proofs:
#   (1) REMOVABILITY (the `compat-feature-severed` discipline, adapted to a flake-OUTPUT selector): flip the
#       `dendritic` flag on the `mkFlakeDendritic` feature arg — ON the selector emits `{ dendritic = <fn>; }`,
#       OFF it emits `{ }` (the output key parks). Mutation-provable: the surface follows the flag.
#   (2) FAITHFULNESS — a MINIMAL flake-parts eval through the real `flakeModules.dendritic` + a one-host fleet.
#       Unlike flake-strict (which imports the bridge DIRECTLY), dendritic reads `inputs.den.flakeModule`, so
#       the eval MUST bind `inputs.den = { flakeModule = <den-hoag bridge>; }` — else the module's `or { }`
#       silently drops the den surface (exactly the corpus failure mode). Reading the host registry proves the
#       import actually landed the `den.*` options.
{
  denHoagFlakeModule,
  denCompat,
  genInputs,
  nixpkgs,
  denHoagSrc,
  ...
}:
let
  flakeParts = genInputs.flake-parts;
  dendriticModule = import "${denHoagSrc}/lib/compat/flake-dendritic.nix";

  # (1) removability — the gated selector over the feature record.
  onSurface = denCompat.mkFlakeDendritic denCompat.defaultFeatures;
  offSurface = denCompat.mkFlakeDendritic (denCompat.defaultFeatures // { dendritic = false; });

  # (2) faithfulness — dendritic imports `inputs.den.flakeModule`, so bind `inputs.den` to the den-hoag bridge
  # (the corpus's `--override-input den .` makes `inputs.den` = den-hoag itself). `self.inputs` carries nixpkgs
  # the same way flake-strict's witness does (the bridge's own eval needs it); no nixpkgs crossing here — a
  # host registry read is enough to force the den option surface to exist.
  evalDen =
    fleetModule:
    (flakeParts.lib.evalFlakeModule
      {
        inputs = {
          inherit nixpkgs;
          den = {
            flakeModule = denHoagFlakeModule;
          };
        };
        self = {
          inputs = { inherit nixpkgs; };
        };
        moduleLocation = "<flake-dendritic witness>";
      }
      {
        systems = [ "x86_64-linux" ];
        imports = [
          dendriticModule
          fleetModule
        ];
      }
    ).config;

  # a one-host fleet resolves `den.hosts.<sys>.<name>` iff dendritic landed the den option surface. Set the
  # host `class` (a declared host option) and read it back — a missing surface would `option 'den' does not
  # exist` / drop the value.
  hostClass =
    (evalDen { den.hosts.x86_64-linux.igloo.class = "nixos"; }).den.hosts.x86_64-linux.igloo.class;
in
{
  flake.tests.flake-dendritic = {
    # (1) ON ⇒ the `dendritic` output key is present …
    test-dendritic-on-present = {
      expr = onSurface ? dendritic;
      expected = true;
    };
    # … and its value is a flake-parts module (a function — the `{ inputs, ... }: …` form).
    test-dendritic-on-is-module = {
      expr = builtins.isFunction (onSurface.dendritic or null);
      expected = true;
    };
    # (1) OFF ⇒ the key parks (the removability tooth — `compat.flakeDendritic` is `{ }`, so `flake.nix`'s
    # `// compat.flakeDendritic` merge adds nothing).
    test-dendritic-off-absent = {
      expr = offSurface ? dendritic;
      expected = false;
    };
    # (2) faithfulness — the dendritic import lands the den surface; the one-host fleet resolves.
    test-dendritic-lands-den-surface = {
      expr = hostClass;
      expected = "nixos";
    };
  };
}
