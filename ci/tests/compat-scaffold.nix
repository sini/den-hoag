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
    # `compile` is a pure v1Decls → den-hoag concern-declaration function (Law C2). It returns the five
    # concern-declaration keys the four-concern API consumes, plus `include` — the §370 directAspects seam
    # the R5 self-named-aspect desugar (spec §10) appends onto (flake-module.nix `addSelfIncludes`); the
    # compile core emits it EMPTY, so bare `compile` is unchanged in content. attrNames is sorted.
    test-compile-concern-keys = {
      expr = builtins.attrNames (denCompat.compile { });
      expected = [
        "aspects"
        "channels"
        "classes"
        "entities"
        "include"
        "policies"
        # Shared-vs-own provenance (Track A rung 1): the `den.default` reserved-aspect key(s) whose class
        # content is radiated-shared, for the class-modules `__shared` sidecar (R-ROOT-FILTER). Empty here
        # (no `den.default` in `{ }`), non-empty `[ "__default" ]` when `den.default` is declared.
        "sharedAspectKeys"
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
    # flakeModule is the flake-parts IMPORT surface: ONLY `flakeModuleCore` (the single v1-options module
    # that DECLARES `options.den`). The `legacy.*` desugar-holders are consumed internally as attributes,
    # never imported as flake-parts modules — importing them leaked their top-level keys (`_denCompat`,
    # `desugar`, the forward primitives) as undeclared options into a consumer's strict flake-parts eval
    # (ship-gate G1′). So the list is length 1; the strict-eval leak is pinned by the witness below.
    test-flake-module-is-list = {
      expr = builtins.isList denCompat.flakeModule && builtins.length denCompat.flakeModule == 1;
      expected = true;
    };
    # The G1′ regression witness (ship-gate T3a): importing `flakeModule` into a STRICT (undeclared-option-
    # rejecting) module eval must leak NOTHING outside the declared `den` surface. The corpus imports this
    # list into real flake-parts, which is strict; den-hoag's own `mkDen` path is permissive (the v1-options
    # freeform absorbs stray `den.*` keys), so ONLY a strict eval catches an INTERNAL key — a `legacy.*`
    # severance marker or desugar closure — escaping into a consumer's option namespace. `lib.evalModules`
    # (strict by default via `_module.check`) reproduces that rejection without a real flake-parts dependency.
    # Forcing the config SPINE (`config ? den`) runs the top-level unmatched-definition check, which throws
    # "option `<k>' does not exist" on a leaked top-level key — WITHOUT descending into the gen-schema `den`
    # submodule (that value crossing is a distinct concern the corpus forces only through the output bridge).
    test-flakemodule-strict-eval-clean = {
      expr = (lib.evalModules { modules = denCompat.flakeModule; }).config ? den;
      expected = true;
    };
    # Teeth: the witness is non-vacuous — a module leaking a non-`den` top-level key MUST make the same strict
    # eval throw. This is exactly what the two legacy modules did before T3a removed them from the import
    # surface; re-adding any such module regresses `test-flakemodule-strict-eval-clean` to a throw.
    test-flakemodule-strict-eval-catches-leak = {
      expr =
        let
          leaked = lib.evalModules {
            modules = denCompat.flakeModule ++ [ { _denCompat.legacy = "probe"; } ];
          };
        in
        (builtins.tryEval (builtins.seq (leaked.config ? den) true)).success;
      expected = false;
    };
  };
}
