{
  description = "den-compat parity harness — the dual-den-input differential (v1 oracle vs den-hoag)";

  inputs = {
    gen.url = "github:sini/gen";
    den-v2.url = "path:.."; # this tree (its `.compat` output)
    den-v1.url = "github:denful/den/11866c16"; # the FROZEN pin (parity/PIN.md)
    # INTERIM corpus pin (owner decision dated 2026-07-07, the compat-phase start): frozen at the
    # then-current nix-config main so parity diffs are
    # reproducible during the compat build; bump deliberately at ship-gate. FOLLOW-UP (tracked):
    # the real harness migrates to a SYNTHETIC self-contained corpus (no live-fleet coupling).
    corpus.url = "github:sini/nix-config/b0b207693ce66fb57acf2bb09cf9549e1dbddec7";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    inputs@{
      gen,
      den-v1,
      den-v2,
      nixpkgs,
      ...
    }:
    let
      denCompat = den-v2.compat;
      nixpkgsLib = import "${nixpkgs}/lib";
      # den v1's FROZEN fx edge surface — the byte contract both harness arms render into. `edge.nix`
      # (`edgeSortKey`, the T|P|S|M sort key + S/T constructors) and `edges/parity.nix`
      # (`assertEdgeParity`) are `{ lib }`-only, so the harness imports them directly against the
      # pinned source; the full oracle (`edgeTrace` via `exposeEdges`) needs a den eval and lands in
      # Task 7. `den-v1.lib` itself is a `{ lib, config, inputs }` FUNCTION, not this surface — hence
      # the direct source import rather than `den-v1.lib`.
      denV1 = {
        edge = import "${den-v1}/nix/lib/aspects/fx/edges/edge.nix" { lib = nixpkgsLib; };
        parity = import "${den-v1}/nix/lib/aspects/fx/edges/parity.nix" { lib = nixpkgsLib; };
      };
    in
    gen.lib.mkCi {
      inherit inputs;
      name = "den-compat-parity";
      testModules = ./tests;
      specialArgs = {
        inherit denCompat denV1 nixpkgsLib;
        corpus = inputs.corpus;
      };
    };
}
