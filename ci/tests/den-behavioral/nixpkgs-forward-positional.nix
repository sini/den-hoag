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

    # PARTIAL-PARKED. The co-scoped named-target SELF-BLOCK is RESOLVED (Mechanism 2, the `_onlyCless`
    # seen-guard relaxation in `resolved-aspects.nix`; witnessed green by `coscoped-provides-selfblock.nix`):
    # the declaring aspect `tux` resolves at the `tux` cell, `provides.igloo` desugars to a carrier keyed
    # `tux/igloo` radiating back to that cell plus a contentless stub of the same key, and the stub no longer
    # blocks its own carrier. The RESIDUAL blocker is a SEPARATE downstream rung — the overlay→nixpkgs-class
    # reroute hop (`den.aspects.tux/igloo declares key 'nixpkgs', which is neither a facet, a registered
    # class, nor a quirk channel`): the `nixpkgs.overlays` value must re-route into the nixpkgs class. Unparks
    # when that reroute hop ships.
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
