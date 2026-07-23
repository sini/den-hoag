# den v1 `flakeOutputs` witness (denful/den nix/flakeOutputs.nix, see discussions/317). den-hoag exposes
# top-level `flakeOutputs` (flake.nix → lib/compat/flake-outputs.nix, verbatim): per-family flake-output
# MERGE modules a consumer imports (`imports = [ inputs.den.flakeOutputs.nixosConfigurations ]`) to give a
# multi-valued flake output MANY-merge semantics, overriding flake-parts' default per-key `unique` (whose
# conflict message the file quotes). 100% nixpkgs-lib, path-free, consumer-eval.
#
# Witnessed via an ISOLATED `lib.evalModules` (NOT a full flake-parts eval): flake-parts ALSO declares
# `flake.nixosConfigurations`, so importing the den module into a real flake-parts eval double-declares and
# aborts `already declared` — the isolated eval tests the module's OWN merge semantics without that clash.
#
# NOTE (verbatim-faithful): the file's `uniqueSubmodule` / `types.unique` / `message` let-bindings are DEAD
# in v1's own source — the exported family modules all use `manySubmodule` (`lazyAttrsOf unspecified`, the
# permissive many-merge). So a duplicate key does NOT throw a custom unique message; it merges by value
# type. This witness pins the ACTUAL exported behavior (distinct-key coexistence + same-key permissive
# merge), the property the module exists to provide.
{
  nixpkgsLib,
  denHoagSrc,
  ...
}:
let
  lib = nixpkgsLib;
  flakeOutputs = import "${denHoagSrc}/lib/compat/flake-outputs.nix";
  ev =
    defs:
    (lib.evalModules {
      modules = [ flakeOutputs.nixosConfigurations ] ++ defs;
    }).config.flake.nixosConfigurations;

  # two modules each define a DISTINCT nixosConfigurations key → both coexist (the multi-module output
  # contribution the module enables).
  distinctKeys = builtins.sort (a: b: a < b) (
    builtins.attrNames (ev [
      { flake.nixosConfigurations.a = "A"; }
      { flake.nixosConfigurations.b = "B"; }
    ])
  );

  # two modules BOTH contribute to the SAME key → the manySubmodule freeform merges them permissively (the
  # override of flake-parts' per-key `unique`), never a conflict or last-wins clobber.
  sameKeyMerged =
    (ev [
      {
        flake.nixosConfigurations.a = {
          x = 1;
        };
      }
      {
        flake.nixosConfigurations.a = {
          y = 2;
        };
      }
    ]).a;
in
{
  flake.tests.flake-outputs = {
    test-flakeoutputs-distinct-keys-merge = {
      expr = distinctKeys;
      expected = [
        "a"
        "b"
      ];
    };
    test-flakeoutputs-same-key-merges-permissive = {
      expr = sameKeyMerged;
      expected = {
        x = 1;
        y = 2;
      };
    };
  };
}
