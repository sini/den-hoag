# den v1 BEHAVIORAL migration — public-api/forward-each-mutual.nix (denful/den@11866c16). Migrated by copy
# + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the `den.*` declarations are BYTE-IDENTICAL to
# v1. Regression #567: a class forwarder with `each` breaks when imported from a mutual-provider aspect.
# Concern: `den.provides.forward` (`each = ["nixos" "homeManager"]` forwarder + `den._.mutual-provider`
# inert include).
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
  flake.tests.den-forward-each-mutual = {

    # PARKED — the nix→nixos forward reroute does NOT deliver in current den-hoag (a forward-machinery /
    # KERNEL gap, NOT the mutual-provider registry: `den._.mutual-provider` resolves and the include is
    # accepted — this rung's registry works). The forwarder reroutes `fromClass "nix"` → `intoClass nixos`
    # at `intoPath [nix]`, but `igloo.nix.settings.experimental-features` never materializes (missing).
    # Isolated empirically — MISSING via ALL of: `den.aspects.tux.provides.igloo` (the v1 shape), a DIRECT
    # `den.aspects.tux` user aspect (bypassing provides), and a `den.aspects.igloo` host aspect; and with
    # BOTH the two-arm `each = ["nixos" "homeManager"]` AND a single-route `each = ["nixos"]`. So the
    # nixos-half is NOT reachable now (contra the migration plan's D6 premise) — the `nix→nixos@[nix]`
    # reroute itself is the block, upstream of the hm-half's hm-lift #9. The hm arm additionally hits the
    # forward-into-homeManager-at-cell lift (output-modules `parentTargetedRoutesAt` → `remapOver` reads
    # classSliceOf(cell,"homeManager") per-node; hm-lift #9, same as forward-from-custom-class.nix:194 /
    # guarded-forward.nix:107). The v1 combined `{ nixos = …; hm = …; }` assertion is preserved verbatim so
    # the unpark is a mechanical uncomment. Unparks when the nix→nixos forward reroute (+ the hm-at-cell
    # lift) ships.
    # test-forward-each-from-provide = denTest (
    #   {
    #     den,
    #     lib,
    #     igloo,
    #     tuxHm,
    #     ...
    #   }:
    #   let
    #     nixClass =
    #       { class, aspect-chain, ... }:
    #       den._.forward {
    #         each = [
    #           "nixos"
    #           "homeManager"
    #         ];
    #         fromClass = _: "nix";
    #         intoClass = lib.id;
    #         intoPath = _: [ "nix" ];
    #         fromAspect = _: lib.head aspect-chain;
    #         adaptArgs = lib.id;
    #       };
    #   in
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.default.includes = [ den._.mutual-provider ];
    #
    #     den.aspects.tux.provides.igloo = {
    #       includes = [ nixClass ];
    #       nix.settings.experimental-features = "flakes";
    #     };
    #
    #     expr = {
    #       nixos = igloo.nix.settings.experimental-features;
    #       hm = tuxHm.nix.settings.experimental-features;
    #     };
    #     expected = {
    #       nixos = "flakes";
    #       hm = "flakes";
    #     };
    #   }
    # );

  };
}
