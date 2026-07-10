# The per-class terminal — den-hoag's ONE sanctioned nixpkgs crossing (spec §2.10 attribute 12,
# Law A15 output completeness). Every other file under lib/** is nixpkgs-lib-free; this is the single
# declared exception (ci/tests/zero-machinery excludes it by name for exactly that reason). A terminal
# turns a class's per-member module list into a built artifact.
#
# TERMINAL CONTRACT (den-hoag's, honored by every terminal): `{ name; hostModules; bindings; classCfg }`
#   name        the member's scope-node id (string).
#   hostModules the member's per-class deferredModule list (attribute 9 `class-modules`).
#   bindings    the merged binding set handed to the modules (settings/aspects/channels/entities).
#   classCfg    the compiled class config (concern-classes): `defaultMergeStrategy`, `validators`,
#               `share`, and the A10 `coreStrategy` hook.
#
# gen-bind's `wrapAll` DI (the `wrap.mergeStrategy` → `defaultMergeStrategy` adapter + the split-return
# validator toggle, r2 consumer obligation 6) happens ONCE, here (or inside the gen-flake terminal for
# the crossing) — never re-run per member elsewhere.
{
  bind,
  flake,
}:
{
  nixpkgs ? null,
  darwin ? null,
}:
let
  # A10 seam: a class's core-injection strategy transforms the raw per-member module list before the
  # terminal wraps it. The default is identity (ordinary per-member merge). coreStrategy is
  # `modules -> modules-or-result`; gen-class's `applyCoreFixed` takes `{ core; modules; }`, so A10
  # plugs in an ADAPTER lambda — `modules: (class.applyCoreFixed { inherit core modules; }).config`
  # — never `applyCoreFixed` bare. The output path takes it without restructuring (Law A17: per
  # class, never a global fleet switch).
  prepareModules = classCfg: hostModules: (classCfg.coreStrategy or (m: m)) hostModules;

  # crossVia — the GENERIC per-class crossing (D7): the ONLY per-class difference between a nixos and a
  # darwin (or a droid, or any future system class) crossing is the EVALUATOR — the `{ modules, specialArgs
  # } -> system` builder (gen-flake's `mkSystemTerminal` contract, #48). den-hoag does its OWN `wrapAll`
  # first (so it controls the merge strategy + the validator toggle), then hands the already-wrapped
  # modules to the terminal with EMPTY bindings so the terminal's internal `wrapAll` is a no-op passthrough
  # — one wrap. A class's instantiation declaration supplies the evaluator (D7 declared instantiation); the
  # system knowledge lives THERE (in the declaration), never as a core constant. gen-flake names no system.
  crossVia =
    evaluator:
    {
      name,
      hostModules,
      bindings,
      classCfg,
    }:
    let
      prepared = prepareModules classCfg hostModules;
      wrapped = bind.wrapAll {
        modules = prepared;
        inherit bindings;
        defaultMergeStrategy = classCfg.defaultMergeStrategy;
      };
    in
    (flake.terminals.mkSystemTerminal { inherit evaluator; }) {
      modules = if classCfg.validators then wrapped.all else wrapped.modules;
      bindings = { };
      nodes = { };
      extraModules = [ ];
    };
in
{
  inherit crossVia;

  # crossNixos / crossDarwin — the built-in system crossings as thin `crossVia` sugar over their evaluators
  # (`nixpkgs.lib.nixosSystem` / `nix-darwin.lib.darwinSystem`). Kept as named sugar for the parity harness
  # + the nixos terminal seam; the default instantiation declarations (lib/default.nix) supply these exact
  # evaluators to `crossVia`, so a built-in and a user-declared system class share ONE mechanism.
  crossNixos = crossVia nixpkgs.lib.nixosSystem;
  crossDarwin = crossVia darwin.lib.darwinSystem;

  # collect — a nixpkgs-free default terminal. den-hoag's lib stays pure: absent a user or an external consumer
  # terminal carrying nixpkgs, a class instantiates to its wrapped-module artifact (inspectable,
  # forces no nixpkgs). The output map's spine (per-member keys) is forced without forcing an
  # artifact, so "one instantiate per member" is a spine count, and a real build swaps `crossNixos` in.
  collect =
    {
      name,
      hostModules,
      bindings,
      classCfg,
    }:
    let
      prepared = prepareModules classCfg hostModules;
      wrapped = bind.wrapAll {
        modules = prepared;
        inherit bindings;
        defaultMergeStrategy = classCfg.defaultMergeStrategy;
      };
    in
    {
      inherit name bindings;
      modules = if classCfg.validators then wrapped.all else wrapped.modules;
      __terminal = "collect";
    };
}
