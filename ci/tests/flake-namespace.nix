# den v1 `namespace` top-level output witness (denful/den nix/lib/namespace.nix; nix/default.nix:35).
# den-hoag exposes it at the flake top level (flake.nix → `// compat.flakeNamespace` →
# lib/compat/namespace.nix): a curried `name: sources: <flake-parts module>` a corpus config imports as
# `(inputs.den.namespace "<x>" <bool>)`. ZERO-COUPLING / first-to-cut: the namespace content is aliased into
# `den.aspects.<name>` (NOT v1's separate `den.ful.<name>`), so it rides the EXISTING aspect pipeline + the
# EXISTING den-brackets branch-2 resolver with no kernel touch. Feature-gated behind `den.features.namespace`
# (default on). Consumer-eval, additive; nothing in den-hoag's own CI/parity imports it — this synthetic
# witness is its only exercise.
#
# Two proofs (the `compat-feature-severed` discipline, adapted to a flake-OUTPUT selector like flake-dendritic):
#   (1) REMOVABILITY — flip `namespace` on the `mkFlakeNamespace` feature arg: ON the selector emits
#       `{ namespace = <fn>; }`, OFF it emits `{ }` (so `flake.nix`'s `// compat.flakeNamespace` adds nothing
#       and a corpus `inputs.den.namespace …` parks with a named `attribute 'namespace' missing`).
#       Mutation-provable: the surface follows the flag.
#   (2) FAITHFULNESS — drive the REAL factory end-to-end through the bridge (the `_lib/den-compat-test.nix`
#       scaffold). Import `(namespace "hw" false)`, author `hw.amdgpu` through the top-level ALIAS the factory
#       declares, and prove BOTH (a) the alias lands the content in `config.den.aspects.hw` and (b) a DEEP
#       3-level bracket `<hw/amdgpu/sea-islands>` (resolveWithProvidesFallback recursion, the corpus
#       `<hardware/amdgpu/sea-islands>` shape) resolves + DELIVERS the marker to the host's NixOS config. The
#       whole chain: factory → alias → den.aspects → deep bracket → delivered class content.
{
  denCompat,
  denHoagFlakeModule,
  homeManagerModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  # The gated selector over the feature record (pure — no eval).
  onSurface = denCompat.mkFlakeNamespace denCompat.defaultFeatures;
  offSurface = denCompat.mkFlakeNamespace (denCompat.defaultFeatures // { namespace = false; });
  # The REAL factory the ON surface exposes (den v1 `name: sources: module`).
  namespace = onSurface.namespace;

  denTest = import ./_lib/den-compat-test.nix {
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
  flake.tests.flake-namespace = {
    # (1) ON ⇒ the `namespace` output key is present …
    test-namespace-on-present = {
      expr = onSurface ? namespace;
      expected = true;
    };
    # … and its value is the curried `name: sources: module` factory (a function).
    test-namespace-on-is-fn = {
      expr = builtins.isFunction (onSurface.namespace or null) && builtins.isFunction (namespace "x");
      expected = true;
    };
    # (1) OFF ⇒ the key parks (the removability tooth — `compat.flakeNamespace` is `{ }`, so `flake.nix`'s
    # top-level `// compat.flakeNamespace` merge adds nothing → `inputs.den.namespace` is `attribute missing`).
    test-namespace-off-absent = {
      expr = offSurface ? namespace;
      expected = false;
    };

    # (2) FAITHFULNESS — the factory's alias lands content in `den.aspects.<name>`, and a deep 3-level bracket
    #     over that content delivers to the host. Non-vacuous: drives the real `namespace "hw" false` module.
    test-namespace-alias-deep-bracket-delivers = denTest (
      { den, igloo, ... }:
      {
        imports = [ (namespace "hw" false) ];
        # Author through the top-level alias the factory declares (it copies `hw.*` → `den.aspects.hw.*`),
        # exactly as a corpus namespace module authors `hardware.amdgpu = { … }`.
        hw.amdgpu = {
          nixos.environment.variables.HW_BASE = "base";
          provides.sea-islands.nixos.environment.variables.HW_DEEP = "deep";
        };
        den.hosts.x86_64-linux.igloo.users.tux = { };
        # The host self-aspect (R5) pulls the deep provides sub-aspect via the 3-level bracket.
        den.aspects.igloo.includes = [ (den.lib.__findFile null "hw/amdgpu/sea-islands") ];
        expr = {
          # (a) the alias put the authored content into the den.aspects tree the resolver reads.
          landedInDenAspects = den.aspects.hw.amdgpu ? nixos;
          # (b) the deep bracket resolved through resolveWithProvidesFallback and DELIVERED to the host.
          deepDelivered = igloo.environment.variables.HW_DEEP or "<missing>";
        };
        expected = {
          landedInDenAspects = true;
          deepDelivered = "deep";
        };
      }
    );
  };
}
