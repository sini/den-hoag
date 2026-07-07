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
  # The ingestion boundary (Law C6): the ONE place v1 name-strings become id_hash-bearing entries.
  ingest = import ./ingest.nix {
    inherit
      denHoag
      prelude
      schema
      errors
      ;
  };
  # The pure compile core (Law C2): v1 declarations → den-hoag concern declarations. `declare` is
  # den-hoag's declaration-constructor vocabulary (the policy-effect translation targets).
  compile = import ./compile.nix {
    inherit prelude ingest errors;
    inherit (denHoag) declare;
  };
  legacy = {
    provides = import ./legacy/provides.nix (deps // { inherit errors; });
    forwards = import ./legacy/forwards.nix (deps // { inherit errors; });
  };
  # flakeModuleCore — the module(s) declaring the v1 option surface as `raw`, read by a v1-shaped eval
  # whose config `compile` desugars (the two-eval shape; den-hoag's own `mkDen` owns `den.*` typed, so
  # the v1 surface cannot share its eval). `mkFleetModule`/`mkDen` bridge the compiled output to
  # `denHoag.mkDen` (spec-vs-reality flag 1). Grows the C0 skeleton's empty core to length 1.
  flakeModuleWiring = import ./flake-module.nix {
    inherit
      denHoag
      prelude
      schema
      compile
      legacy
      ;
  };
  inherit (flakeModuleWiring) flakeModuleCore;
in
{
  inherit
    compile
    ingest
    flakeModuleCore
    legacy
    ;
  inherit (flakeModuleWiring) mkFleetModule mkDen evalV1;
  flakeModule = flakeModuleWiring.flakeModule;
  # parity — the two-sided harness helper functions (frozen edge schema, oracle, firstDivergent
  # triage), Task 7. Placeholder attrset until then so `compat.parity` is addressable (the scaffold
  # reachability gate); Task 7 replaces this with `import ./parity { inherit denHoag prelude edge; }`.
  parity = { };
}
