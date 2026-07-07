# compat-scaffold — the den-compat skeleton addressability gate (Task 0). Proves the shim is wired
# into the flake and exposes the shapes every later shim task builds on: `compile` returns the
# five-key concern-DECLARATION attrset, and each legacy surface carries its `_denCompat.legacy` tag
# (so severability is testable from Task 4 onward, C5). The desugar itself lands in Tasks 1–5.
{ lib, denCompat, ... }:
{
  flake.tests.compat-scaffold = {
    test-compat-addressable = {
      expr = builtins.isAttrs denCompat;
      expected = true;
    };
    # `compile` is a pure v1Decls → den-hoag concern-declaration function (Law C2). The stub returns
    # the five declaration keys the four-concern API consumes; attrNames is sorted.
    test-compile-five-keys = {
      expr = builtins.attrNames (denCompat.compile { });
      expected = [
        "aspects"
        "channels"
        "classes"
        "entities"
        "policies"
      ];
    };
    test-legacy-provides-tag = {
      expr = denCompat.legacy.provides._denCompat.legacy;
      expected = "provides";
    };
    test-legacy-forwards-tag = {
      expr = denCompat.legacy.forwards._denCompat.legacy;
      expected = "forwards";
    };
    # flakeModule = flakeModuleCore ++ both legacy modules (the severance surface, §2.1): importing
    # it gives the full v1 surface. Empty core in the skeleton ⇒ exactly the two legacy modules.
    # SKELETON EXPECTATION: Tasks 1–3 grow flakeModuleCore — bump the expected length with them.
    test-flake-module-is-list = {
      expr = builtins.isList denCompat.flakeModule && builtins.length denCompat.flakeModule == 2;
      expected = true;
    };
  };
}
