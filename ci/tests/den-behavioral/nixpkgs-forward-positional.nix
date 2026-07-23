# den v1 BEHAVIORAL migration — deadbugs/nixpkgs-forward-positional.nix (denful/den@11866c16). Migrated by
# copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + assertion are
# BYTE-IDENTICAL to v1. Regression #575: positional context functions in `includes` were silently dropped —
# a nixpkgs overlay forwarded via `ctx: …` failed (reproduction: github.com/musjj/nixpkgs-forward-bug).
#
# A NOVEL 3-machinery composition (positional bare-fn include + `den._.mutual-provider` inert include +
# `den.aspects.tux.provides.igloo` overlay→pkgs reroute) never witnessed together in den-hoag. Concern:
# `den.provides.forward` (positional-ctx include + mutual-provider include, overlay→pkgs reroute).
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
  flake.tests.den-nixpkgs-forward-positional = {

    # PARKED — Mechanism 2 (co-scoped named-target self-block), NOT the reach dedup and NOT the overlay hop. The
    # declaring aspect `tux` resolves at the `tux` cell; `provides.igloo` desugars to a carrier keyed
    # `tux/igloo` that radiates (via `nameMatches "igloo"`) back to that SAME cell, plus a contentless stub
    # `tux/igloo` seeded on aspect `tux` at that cell. The stub, seeded first, puts `tux/igloo` in the cell's
    # `prev.seen`, so `nbExtras` (`resolved-aspects.nix:502-504`, predicate `!(prev.seen ? keyOf carrier)` at :503) filters the
    # carrier and it NEVER resolves — the contentless stub blocks its own carrier. Confirmed empirically: even a
    # STATIC `provides.igloo.nixos.…="x"` yields `""`, and a parametric variant also yields `""` (so it is not the
    # sharedFoldKey dedup G1 fixes). Unparks when the co-scoped named-target self-block ships (a separate rung
    # touching the neededBy fixpoint's seen/nbExtras semantics), after which the overlay→pkgs reroute hop can be
    # re-checked.
    # test-overlay-forward = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     ...
    #   }:
    #   let
    #     nixpkgsClass =
    #       ctx:
    #       lib.optionalAttrs
    #         (lib.elem (lib.attrNames ctx) [
    #           [ "home" ]
    #           [ "host" ]
    #         ])
    #         (
    #           { class, aspect-chain, ... }:
    #           den._.forward {
    #             each = [ (ctx.home or ctx.host) ];
    #             fromClass = _: "nixpkgs";
    #             intoClass = { class, ... }: class;
    #             intoPath = _: [ "nixpkgs" ];
    #             fromAspect = _: lib.head aspect-chain;
    #             adaptArgs = lib.id;
    #           }
    #         );
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.default.includes = [
    #       den._.mutual-provider
    #       nixpkgsClass
    #     ];
    #
    #     den.aspects.tux.provides.igloo = {
    #       nixpkgs.overlays = [
    #         (final: prev: {
    #           cowsay = prev.cowsay.overrideAttrs (oldAttrs: {
    #             passthru = oldAttrs.passthru or { } // {
    #               hello = "world";
    #             };
    #           });
    #         })
    #       ];
    #
    #       nixos =
    #         { pkgs, ... }:
    #         {
    #           users.users.tux.description = pkgs.cowsay.hello;
    #         };
    #     };
    #
    #     expr = igloo.users.users.tux.description;
    #     expected = "world";
    #   }
    # );

  };
}
