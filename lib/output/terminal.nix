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
}:
let
  # A10 seam: a class's core-injection strategy transforms the raw per-member module list before the
  # terminal wraps it. The default is identity (ordinary per-member merge). gen-class tier-3
  # (`applyCoreFixed`) drops in here as `classCfg.coreStrategy` — the output path takes it without
  # restructuring (Law A17: per class, never a global fleet switch).
  prepareModules = classCfg: hostModules: (classCfg.coreStrategy or (m: m)) hostModules;
in
{
  # crossNixos — the real gen-flake crossing (gen-flake ships `terminals.nixosSystem`, NOT the spec's
  # placeholder `mkSystems`). den-hoag does its OWN `wrapAll` first (so it controls the merge strategy
  # and the validator toggle), then hands the already-wrapped modules to the terminal with empty
  # bindings so the terminal's internal `wrapAll` is a no-op passthrough — one wrap, one crossing.
  crossNixos =
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
    (flake.terminals.nixosSystem { inherit nixpkgs; }) {
      modules = if classCfg.validators then wrapped.all else wrapped.modules;
      bindings = { };
      nodes = { };
      extraModules = [ ];
    };

  # collect — a nixpkgs-free default terminal. den-hoag's lib stays pure: absent a user/den-compat
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
