# Standalone (non-flake) entry. Flake consumers use the `.lib` output. This root supplies MATERIALS —
# one source path per dep — to `substrate.nix`, which is the ONE construction both roots go through; it
# constructs no dep value itself. Every material defaults to the lock-resolved source tree, so
# `import ./default.nix { }` keeps working exactly as before for every path that does not cross into
# flake-parts.
#
# The currency of the nineteen per-dep formals is a source PATH, not a lib VALUE. That is an external
# API change: a consumer holding an already-constructed gen lib can no longer inject it as
# `import ./default.nix { class = myClassLib; }`. That injection IS the per-root value channel this
# construction removes — a consumer could hand this root a merge-less gen-class and reproduce the very
# divergence the substrate exists to close. A consumer who needs a modified gen lib supplies a modified
# SOURCE, which the substrate then wires the same way on both roots; the override idiom this repo
# documents (`--override-input den-hoag/gen-flake path:<local>`) is already source-shaped.
#
# The two HOST materials are flake values, which a source path cannot produce, so they have no
# lock-resolved default. Their absence is DECLARED — a named throw — rather than null: omitting one says
# "this root has no such flake", which is a different statement from "this capability is unavailable",
# and null is neither (it is gen-flake's own capability-absent signal, and reaches its gate as foreign
# advice to a party that never imported gen-flake).
{
  lock ? builtins.fromJSON (builtins.readFile ./flake.lock),
  fetch ? name: builtins.fetchTree lock.nodes.${lock.nodes.root.inputs.${name}}.locked,
  genPreludeSrc ? fetch "gen-prelude",
  genAlgebraSrc ? fetch "gen-algebra",
  genTypesSrc ? fetch "gen-types",
  genMergeSrc ? fetch "gen-merge",
  genSchemaSrc ? fetch "gen-schema",
  genAspectsSrc ? fetch "gen-aspects",
  genGraphSrc ? fetch "gen-graph",
  genScopeSrc ? fetch "gen-scope",
  genResolveSrc ? fetch "gen-resolve",
  genSelectSrc ? fetch "gen-select",
  genBindSrc ? fetch "gen-bind",
  genDispatchSrc ? fetch "gen-dispatch",
  genClassSrc ? fetch "gen-class",
  genEdgeSrc ? fetch "gen-edge",
  genProductSrc ? fetch "gen-product",
  genSettingsSrc ? fetch "gen-settings",
  genDemandSrc ? fetch "gen-demand",
  genPipeSrc ? fetch "gen-pipe",
  genFlakeSrc ? fetch "gen-flake",
  nixpkgs ? throw "den-hoag: `nixpkgs` — the standalone root carries no nixpkgs FLAKE. Pass `nixpkgs = <nixpkgs>` to `import ./default.nix` to reach gen-flake's `terminals.nixosSystem`; den-hoag's own nixos crossing takes its nixpkgs at the crossing (`den.nixpkgs`) and does not need this.",
  flakeParts ? throw "den-hoag: `flakeParts` — the standalone root carries no flake-parts FLAKE. Pass `flakeParts = <flake-parts>` to `import ./default.nix` to reach `internal.mkFlakeTerminal`; the flake root passes `inputs.flake-parts`.",
}:
let
  s = import ./substrate.nix {
    inherit
      genPreludeSrc
      genAlgebraSrc
      genTypesSrc
      genMergeSrc
      genSchemaSrc
      genAspectsSrc
      genGraphSrc
      genScopeSrc
      genResolveSrc
      genSelectSrc
      genBindSrc
      genDispatchSrc
      genClassSrc
      genEdgeSrc
      genProductSrc
      genSettingsSrc
      genDemandSrc
      genPipeSrc
      genFlakeSrc
      nixpkgs
      flakeParts
      ;
  };
  lib = import ./lib s.kernel;
in
# Mirror of the flake outputs: the assembled lib, with the den-compat shim attached as `.compat`
# (the flake exposes `compat` as a sibling output; the standalone entry IS the lib, so `.compat`
# rides on it). Bare-lib consumers (`(import ./default.nix).mkDen`) are unaffected.
lib // { compat = import ./lib/compat/wiring.nix (s.compatArgs lib); }
