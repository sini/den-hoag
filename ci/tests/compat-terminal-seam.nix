# den-compat nixos-terminal SEAM (C9 item 4). The shim bridges the nixos class to a terminal; by default
# that terminal is the nixpkgs-free `collect` (the pure fleet path). `mkDenWith … { nixosTerminal = … }`
# lets a consumer supply a DIFFERENT terminal — chiefly the nixpkgs-bound `crossNixos`, so
# `nixosConfigurations` are REAL NixOS systems with a `config` / a `system.build.toplevel.drvPath`. This is
# REQUIRED infrastructure, not a test convenience: contentGate's P2 ship-gate arm compares v1DrvPath vs
# shimDrvPath, and a collect-pinned shim can never produce a shimDrvPath; and a v1 user bumping the den
# input must get real nixosConfigurations, not collect artifacts. Shim-side seam, ZERO core edits;
# `mkDen` = `mkDenWith … { }` (the default terminal), byte-identical to the pre-seam bridge.
{
  denCompat,
  denHoag,
  denHoagSrc,
  nixpkgs,
  ...
}:
let
  # A minimal v1 fixture: host `igloo` with a self-named aspect setting nixos content. Both arms materialize
  # `networking.hostName = "igloo"` from the SHIM PATH (compile → fold → terminal).
  fixture = {
    den.hosts.x86_64-linux.igloo = { };
    den.aspects.igloo.nixos.networking.hostName = "igloo";
  };

  # The nixpkgs-bound crossNixos terminal, built harness-side from the den-hoag source (bind/flake from the
  # public `internal` surface) — no core edit, no shim edit. The parity harness builds it exactly this way.
  crossNixos =
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { inherit nixpkgs; }).crossNixos;

  # DEFAULT path (collect): `mkDen` = `mkDenWith … { }`. A nixpkgs-free collect artifact.
  defaultBuilt = denCompat.mkDen [ fixture ];
  # SEAM path (crossNixos): the supplied terminal crosses to a REAL NixOS system.
  crossedBuilt = denCompat.mkDenWith [ fixture ] { nixosTerminal = crossNixos; };
in
{
  flake.tests.compat-terminal-seam = {
    # DEFAULT UNCHANGED: with no seam argument, the nixos class instantiates via the collect terminal (the
    # `__terminal = "collect"` marker) — every existing fixture/test is on this path, untouched.
    test-default-is-collect = {
      expr = defaultBuilt.nixosConfigurations.igloo.__terminal or "<not-collect>";
      expected = "collect";
    };
    # SEAM CROSSES: the harness-supplied crossNixos produces a real NixOS system whose config resolves —
    # `networking.hostName` reads back through the full module-system fixpoint (a shimDrvPath now exists).
    test-seam-crosses = {
      expr = crossedBuilt.nixosConfigurations.igloo.config.networking.hostName;
      expected = "igloo";
    };
    # the DEFAULT build is byte-identical to `mkDenWith … { }` (mkDen IS that — the seam adds nothing on the
    # default path): the collect artifact's carried modules match.
    test-default-equals-mkDenWith-default = {
      expr =
        builtins.toJSON (defaultBuilt.nixosConfigurations.igloo.modules or null) == builtins.toJSON (
          (denCompat.mkDenWith [ fixture ] { }).nixosConfigurations.igloo.modules or null
        );
      expected = true;
    };
  };
}
