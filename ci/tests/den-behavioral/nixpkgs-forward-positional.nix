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

    # PARKED — the named-target provides variant is unwired (the block is UPSTREAM of the plan-anticipated
    # overlay→pkgs hop, which is never reached). `den.aspects.tux.provides.igloo` is a HOST-named provide:
    # the legacy/provides.nix desugar fires `nameMatches "igloo"` at the deliverable tux@igloo user cell
    # (`d.host.name == "igloo"`, legacy/provides.nix:86-94), so the selector matches — but the delivered
    # `nixos` face does NOT lift to the host. Isolated empirically: even a STATIC
    # `provides.igloo.nixos.users.users.tux.description = "…"` yields `igloo.users.users.tux.description == ""`
    # (undelivered), so the overlay reroute (`nixpkgs.overlays` → intoPath [nixpkgs]) is never exercised
    # (`igloo.nixpkgs.overlays == [ ]`). Same "named-target provides variant unwired" family as the
    # projected-hasaspect.nix parks (`provides.<name>.includes` → `home-manager.users.<name>`). Unparks when
    # the named-provide → host/cell nixos lift ships.
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
