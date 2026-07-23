# den-hoag COMPAT witness (Mechanism 2 — co-scoped named-target self-block). An aspect that DECLARES a
# `provides.<name>` whose carrier radiates BACK to the declaring aspect's OWN cell: `den.aspects.tux`
# auto-applies at the `tux` cell (v1 `den.aspects ? config.name`); `provides.igloo` desugars to a content
# carrier keyed `tux/igloo` that radiates (`nameMatches "igloo"`) onto that host, PLUS a contentless
# visibility stub keyed `tux/igloo` seeded on aspect `tux` at the same cell.
#
# Pre-fix the stub, seeded FIRST, puts `tux/igloo` in the cell's `prev.seen`; `nbExtras`
# (`resolved-aspects.nix`, predicate `!(prev.seen ? keyOf carrier)`) then filters the content carrier —
# the stub blocks its OWN carrier and the delivered `description` resolves to `""`. The kernel fix
# distinguishes an `_onlyCless` key (held solely by `__contentless` stub nodes) and lets the co-scoped
# carrier past the seen-guard exactly once, dropping the spent stub before the first-wins dedup ⇒ `"x"`.
{
  denHoagFlakeModule,
  homeManagerModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };
in
{
  flake.tests.den-coscoped-provides-selfblock = {

    # Static direct-nixos content on a co-scoped `provides.<name>` (declaring aspect radiates onto its own
    # cell). Pre-fix the contentless visibility stub blocked its own content carrier ⇒ `""`; the M2
    # `_onlyCless` seen-guard relaxation keeps the carrier ⇒ `"x"`.
    test-coscoped-provides-selfblock-delivers = denTest (
      {
        den,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.tux.provides.igloo.nixos.users.users.tux.description = "x";

        expr = igloo.users.users.tux.description;
        expected = "x";
      }
    );

  };
}
