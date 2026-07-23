# den-hoag COMPAT witness (Mechanism 1) — a DIRECT class facet (`nixos.users.users.<u>.description`) carried
# on a `provides.to-users` value, delivered host→users, must materialize on the delivered user's nixos face.
#
# The carrier (top-level synth aspect `igloo/to-users`, holding the nixos content) and its contentless
# visibility stub (seeded on the declaring aspect, same A-IDENT key `igloo/to-users`) both project `""`, so
# pre-fix they share the sharedFoldKey `igloo/to-users|`. The reach cross-scope dedup (`resolved-aspects.nix`
# `reach`, first-occurrence-wins) sees the HOST stub first and drops the CELL carrier that holds the content
# ⇒ the delivered `description` resolves to `""`. The fix marks the stub `meta.__contentless` and the kernel
# maps that to a null sharedFoldKey, so the stub keeps its cond-2 visibility role (`keyOf`) but no longer
# evicts the content carrier ⇒ the content delivers. Contrast `provides-to-users-fn-facet.nix` (content on a
# SEPARATELY-keyed included aspect — a shape that already greened, never hit this collision).
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
  flake.tests.den-provides-nixos-lift = {

    # A direct-nixos-content `provides.to-users` facet, host→users, lands on the delivered user's nixos
    # config. Pre-fix the contentless visibility stub evicted the content carrier at the reach dedup ⇒ `""`;
    # the `meta.__contentless` → null-sharedFoldKey fix keeps the carrier ⇒ `"x"`.
    test-direct-nixos-content-delivered-to-users = denTest (
      {
        den,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        den.aspects.igloo.provides.to-users.nixos.users.users.tux.description = "x";

        expr = igloo.users.users.tux.description;
        expected = "x";
      }
    );

  };
}
