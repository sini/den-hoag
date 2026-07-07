# den-compat (L4) — the den v1 compatibility shim over the shipped den-hoag assembly. Pure
# vocabulary translation: `compile : v1Decls → den-hoag concern declarations` (Law C2 — no
# evaluation, no scope-graph reads, no resolved-state reads), fed to `denHoag.mkDen`. The legacy
# surfaces (`provides`, `forwards`) ride as self-contained tagged modules, removable without touching
# anything else (§2.1 — the severance surface is the entry-point list).
#
# `flakeModule = flakeModuleCore ++ [ legacy.provides legacy.forwards ]`: importing `flakeModule`
# gives the full v1 declaration surface; importing `flakeModuleCore` gives it MINUS the legacy
# surfaces (using a severed surface then becomes a definition-time error, Law C5).
{
  denHoag,
  prelude,
  schema,
  edge,
  ...
}@deps:
let
  errors = import ./errors.nix { inherit prelude; };
  compile = import ./compile.nix { inherit prelude; };
  legacy = {
    provides = import ./legacy/provides.nix (deps // { inherit errors; });
    forwards = import ./legacy/forwards.nix (deps // { inherit errors; });
  };
  # flakeModuleCore — the den-hoag module list that accepts the v1 option tree and compiles it to
  # `config.den.*` via `compile`, fed to `denHoag.mkDen` (spec-vs-reality flag 1: den-hoag has
  # `mkDen`, not a `flakeModule`). Empty in the Task 0 skeleton so `flakeModule` is well-formed now;
  # Tasks 1–3 replace this with `import ./flake-module.nix (deps // { inherit compile errors; })`.
  flakeModuleCore = [ ];
in
{
  inherit compile flakeModuleCore legacy;
  flakeModule = flakeModuleCore ++ [ legacy.provides legacy.forwards ];
  # parity — the two-sided harness helper functions (frozen edge schema, oracle, firstDivergent
  # triage), Task 7. Placeholder attrset until then so `compat.parity` is addressable (the scaffold
  # reachability gate); Task 7 replaces this with `import ./parity { inherit denHoag prelude edge; }`.
  parity = { };
}
