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
  edgeCore,
  ...
}@deps:
let
  errors = import ./errors.nix { inherit prelude; };
  # Legacy-surface sentinels (Law C5's error half): the shim core's knowledge that `provides`/`forwards`
  # EXIST, so compile can refuse an un-desugared key when the legacy module is severed. Core file
  # (references only `errors`, never a legacy module) — severability holds.
  sentinels = import ./sentinels.nix { inherit errors; };
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
  # den-hoag's declaration-constructor vocabulary (the policy-effect translation targets, including the
  # `delivery` intent kind); the gen-edge record is rendered from that intent later, at the firing node.
  compile = import ./compile.nix {
    inherit
      prelude
      ingest
      errors
      sentinels
      ;
    inherit (denHoag) declare;
  };
  # The `deliver` surface (+ the permanent `route` / `provide` sugar): the v1 delivery-edge vocabulary
  # a corpus policy body calls. Produces inert delivery DESCRIPTORS `compile` desugars (Law C2).
  deliverLib = import ./deliver.nix { inherit prelude errors; };
  legacy = {
    provides = import ./legacy/provides.nix (deps // { inherit errors; });
    forwards = import ./legacy/forwards.nix (deps // { inherit errors; });
    defaults = import ./legacy/defaults.nix (deps // { inherit errors; });
  };
  # flakeModuleCore — the module(s) declaring the v1 option surface as `raw`, read by a v1-shaped eval
  # whose config `compile` desugars (the two-eval shape; den-hoag's own `mkDen` owns `den.*` typed, so
  # the v1 surface cannot share its eval). `mkFleetModule`/`mkDen` bridge the compiled output to
  # `denHoag.mkDen` (spec-vs-reality flag 1). Grows the C0 skeleton's empty core to length 1.
  # mkWiring — the den-hoag-facing driver builder PARAMETERISED by a legacy-module subset (the C5
  # severance handle, §2.1). `mkWiring legacy` = the full v1 surface; `mkWiring { }` = flakeModuleCore
  # ALONE (both `desugarLegacy` halves fall back to or-identity, so a residual legacy key trips its
  # compile sentinel); `mkWiring { inherit (legacy) provides; }` = a single-legacy combination. The
  # compile core, sentinels, and errors are SHARED across every wiring — only `desugarLegacy` (hence
  # `compileFull` / `mkDen`) differs. The severability suite (compat-legacy-severed) drives all four.
  mkWiring =
    legacyArg:
    import ./flake-module.nix {
      inherit
        denHoag
        prelude
        schema
        compile
        ;
      legacy = legacyArg;
    };
  flakeModuleWiring = mkWiring legacy;
  inherit (flakeModuleWiring) flakeModuleCore;
in
{
  inherit
    compile
    ingest
    flakeModuleCore
    legacy
    ;
  # The v1 delivery-edge surface (`deliver`/`route`/`provide`) a corpus policy body calls; the compat
  # twin of den v1's `den.lib.policy.{deliver,route,provide}`.
  inherit (deliverLib) deliver route provide;
  # The compat nixos instantiate wrapper builder (§2.5 carry-in), exposed as a seam: the parity harness
  # supplies `terminal = crossNixos` for a real build; the fleet wiring defaults it to `collect`.
  inherit (flakeModuleWiring) mkNixosInstantiate;
  inherit (flakeModuleWiring) mkFleetModule mkDen evalV1;
  # `compileFull` — the "through flakeModule" compile (apply the full legacy desugars, then compile), the
  # entry a v1 surface takes under `flakeModule`. For a non-legacy surface it equals `compile` (or-identity
  # desugars); the C1 witness suite drives every witness through it uniformly. `mkWiring` is the severed-
  # variant builder the C5 suite uses to prove each legacy module removable.
  inherit (flakeModuleWiring) compileFull;
  inherit mkWiring;
  flakeModule = flakeModuleWiring.flakeModule;
  # parity — the two-sided harness (frozen edge schema + the v1/hoag oracle + firstDivergent triage),
  # Task 7. `schema` is fully self-contained; `oracle.traceHoag` needs only this tree; `oracle.mkV1` is a
  # function of the dev-time-only harness inputs (den v1 flake + nixpkgs) the `parity/` flake supplies.
  parity = import ./parity { inherit denHoag prelude edgeCore; };
}
