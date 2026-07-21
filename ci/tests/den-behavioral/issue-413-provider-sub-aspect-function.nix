# den v1 BEHAVIORAL migration — deadbugs/issue-413-provider-sub-aspect-function.nix (denful/den
# templates/ci/modules/deadbugs/issue-413-provider-sub-aspect-function.nix, denful/den#413 simplified
# variant). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `nested-aspects` (a parametric parent aspect unconditionally includes its own `provides.sub`).
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
  flake.tests.den-nested-aspects = {

    # BLOCKED-WSB (missing surface): `den.aspects.foo` is a BARE-FUNCTION (parametric) aspect; a separate
    # module contributes `den.aspects.foo.provides.sub = { host, ... }: {...};`. den-hoag's legacy
    # `provides` desugar (lib/compat/legacy/provides.nix `desugar`) only recognizes `provides` on aspects
    # that are ATTRSETS (`declaring = filterAttrs (_: a: isAttrs a && (a.provides or null) != null) …`) —
    # a bare-function aspect is excluded from that filter. Empirically confirmed: forcing the resolved
    # config throws `den-hoag: aspect key (§2.2): aspect igloo:include:0 declares key provides, which is
    # neither a facet, a registered class, nor a quirk channel` — the `provides` key on a parametric
    # aspect reaches ordinary key-classification undesugared and aborts. Left in place, commented, per the
    # parking rule.
    # test-parametric-parent-parametric-sub = denTest (
    #   { den, igloo, ... }:
    #   {
    #     imports = [
    #       {
    #         den.aspects.foo =
    #           { host, ... }:
    #           {
    #             includes = [ den.aspects.foo.provides.sub ];
    #           };
    #       }
    #       {
    #         den.aspects.foo.provides.sub =
    #           { host, ... }:
    #           {
    #             nixos.networking.networkmanager.enable = true;
    #           };
    #       }
    #     ];
    #
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.aspects.igloo.includes = [ den.aspects.foo ];
    #
    #     expr = igloo.networking.networkmanager.enable;
    #     expected = true;
    #   }
    # );
  };
}
