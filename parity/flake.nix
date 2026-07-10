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
    # home-manager — the v1 hm battery's `getModule` reaches `inputs.home-manager."${host.class}Modules"`;
    # the CONTENT arm (P2 cross-pipeline live + the fleet drv-hash ship-gate) forces it. THE INVARIANT (§4.4):
    # hm's nixpkgs MUST equal the nixpkgs the crossings actually use — the TOP-LEVEL `nixpkgs` here — so a
    # host WITH hm users hashes to the same drv on both arms (a divergent hm nixpkgs would move the drv-hash
    # independently of the shim). `follows = "nixpkgs"` declares it; flake.lock pins hm's nixpkgs to the
    # top-level node (NOT `corpus`'s nixpkgs — they are DIFFERENT revs; a `nix flake update` dedup left it
    # on corpus's, so the lock is pinned to `["nixpkgs"]` explicitly). The EDGE arm (traceV1) never forces hm
    # (edge identity ≠ module content), so it was absent until the content arm landed.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

      # The fully-wired two-sided harness (Task 7). `denCompat.parity` ships the PURE pieces (the frozen
      # schema + the oracle BUILDERS); the parity flake is the only place with BOTH dev-time arms in scope,
      # so it applies the v1 builder (`mkV1`) to the frozen den v1 flake + nixpkgs and hands the tests a
      # ready `{ schema; traceHoag; traceV1; traceV1Legacy; fixtures; golden; }`. Every P-suite reads this
      # one surface — the tests never re-wire an arm.
      # The nixpkgs-bound crossNixos terminal, built harness-side from the den-hoag source (`bind`/`flake`
      # from the public `internal` surface) — the C9 item-4 seam supplies it to the shim's nixos class so
      # the HOAG arm crosses to a real NixOS system (`mkDenWith … { nixosTerminal = crossNixos; }`). No core
      # edit, no shim edit — the harness is the only place with both nixpkgs and the den-hoag source.
      crossNixos =
        (import "${den-v2}/lib/output/terminal.nix" {
          inherit (den-v2.lib.internal) bind flake;
        } { nixpkgs = inputs.nixpkgs; }).crossNixos;
      harness =
        let
          P = denCompat.parity;
          v1arm = P.oracle.mkV1 {
            denV1Flake = den-v1;
            denV1Edge = denV1.edge;
            inherit nixpkgsLib;
            nixpkgs = inputs.nixpkgs;
            homeManager = inputs.home-manager;
          };
        in
        {
          inherit (P) schema;
          traceHoag = P.oracle.traceHoag { inherit denCompat; };
          inherit (v1arm) traceV1 traceV1Legacy;
          # The entity-scope normalizer + its id_hash predicate, for the schema-guard suite's direct
          # mis-map test (a colon-bearing non-entity name must pass through unmapped).
          inherit (P.oracle) hoagNormName isIdHash nonEntityNameMap;
          # The content oracle (Task 8): the §4.4 cross-pipeline content record (P2 synthetics), the §4.6
          # class-share sub-gate (P8), and the §4.4 fleet drv-hash mechanism (P2 ship-gate). Each is the
          # BUILDER partially applied with the dev-time arms in scope, exactly like traceHoag/traceV1.
          crossPipelineRecords = P.oracle.crossPipelineRecords {
            inherit denCompat nixpkgsLib;
            inherit v1arm;
          };
          coreGate = P.oracle.coreGate { inherit denCompat; };
          # The §P3 permutation regression (Task 9): declaration-order-independence of the shim + fold.
          permutationGate = P.oracle.permutationGate { inherit denCompat nixpkgsLib; };
          inherit (P.oracle) contentGate canonHash;
          # C9 item-4 live content arms (the ship-gate mechanism at n=1): BOTH arms cross to a real NixOS
          # system. `crossV1 { fixtureModule }` → the v1 flake's nixosConfigurations (full nixpkgs crossing);
          # `crossHoag { fixtureModule }` → the shim's nixosConfigurations via the terminal seam (crossNixos).
          # A live v1-vs-hoag CONTENT comparison reads a config value off each (eval-only, no store build).
          inherit (v1arm) crossV1;
          crossHoag =
            { fixtureModule }:
            (denCompat.mkDenWith [ fixtureModule ] { nixosTerminal = crossNixos; }).nixosConfigurations;
          fixtures = import ./fixtures/topologies.nix { };
          golden = import ./golden/traces.nix;
        };
    in
    gen.lib.mkCi {
      inherit inputs;
      name = "den-compat-parity";
      testModules = ./tests;
      specialArgs = {
        inherit
          denCompat
          denV1
          nixpkgsLib
          harness
          ;
        # den-hoag's own lib (the four-concern API) — the P8 suite reaches `denHoag.internal.class`/
        # `.classShare` for the deliberately-corrupted-core teeth (the A18 gate mechanism, direct).
        denHoag = den-v2.lib;
        corpus = inputs.corpus;
      };
    };
}
