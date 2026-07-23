# WS-B rung 4c WITNESS — the root-nav registry (`den._` / `den.provides`, lib/compat/provides-nav.nix).
# NOT a v1 migration: a den-hoag-native denTest proving (a) the `mutual-provider` shim is INERT, (d) the
# registry is a CLOSED 2-member lookup whose aliases resolve the same handles, and (NIT-1) an inert
# `mutual-provider` in `den.default.includes` does NOT break ordinary delivery.
#
# `den._`/`den.provides` are bound on the bridge's `den` MODULE ARG (config._module.args.den), NOT on
# `config.den` — so they resolve only at CONFIG-eval time (the fleetModule pass), not in the scaffold's
# `expr`-time `den` (= eval.config.den, which carries no `_`). The registry-shape checks are therefore
# computed inside the delivered host config and read back through `igloo.*` in `expr` (a real bridge
# crossing). `den._ == den.provides` is NOT asserted directly: the `forward` member is a FUNCTION and Nix
# `==` throws on functions — the shared-handle claim (D4) is witnessed via the comparable `mutual-provider`
# member (aliasMutualEq) plus both aliases carrying `forward`.
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
  flake.tests.den-provides-nav-registry = {

    test-registry-shape-and-inert-include = denTest (
      {
        den,
        igloo,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };

        # NIT-1: an INERT mutual-provider in den.default.includes — must contribute nothing.
        den.default.includes = [ den._.mutual-provider ];

        den.aspects.igloo.nixos = {
          # ordinary host content, alongside the inert include — must deliver UNCHANGED.
          networking.hostName = "ordinary-delivers";
          # registry-shape checks computed at CONFIG time (module-arg `den` carries `_`/`provides`),
          # surfaced as JSON on the host so `expr` can read them back off the built system.
          environment.etc."provnav-probe".text = builtins.toJSON {
            # (a) mutual-provider is INERT: name/description facets only, no class content, no includes.
            mpHasName = den._.mutual-provider ? name;
            mpHasIncludes = den._.mutual-provider ? includes;
            mpHasClassContent = den._.mutual-provider ? nixos;
            # (d) the registry is EXACTLY { forward, mutual-provider } — a typo is `!?` (⇒ its native miss
            # on access is guaranteed loud), and both `_`/`provides` aliases resolve the same members (D4).
            hasForward = den._ ? forward;
            hasMutual = den._ ? mutual-provider;
            hasTypo = den._ ? nonsenseProvider;
            providesHasForward = den.provides ? forward;
            providesHasMutual = den.provides ? mutual-provider;
            aliasMutualEq = den._.mutual-provider == den.provides.mutual-provider;
          };
        };

        expr = {
          ordinaryDelivers = igloo.networking.hostName;
          registry = builtins.fromJSON igloo.environment.etc."provnav-probe".text;
        };
        expected = {
          ordinaryDelivers = "ordinary-delivers";
          registry = {
            mpHasName = true;
            mpHasIncludes = false;
            mpHasClassContent = false;
            hasForward = true;
            hasMutual = true;
            hasTypo = false;
            providesHasForward = true;
            providesHasMutual = true;
            aliasMutualEq = true;
          };
        };
      }
    );

  };
}
