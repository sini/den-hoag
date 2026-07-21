# den v1 BEHAVIORAL migration — public-api/policy-provide.nix (denful/den templates/ci/modules/public-api/
# policy-provide.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold. Concern:
# `policy` (`den.lib.policy.provide` — direct module delivery into target classes).
#
# ALL FOUR cases empirically diverge/block on den-hoag; none currently executable. Left in place,
# commented, per the parking rule (never altered to route around the gap).
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
let
  mkListSubmodule =
    name:
    { lib, ... }:
    {
      options.${name} = lib.mkOption {
        type = lib.types.submoduleWith {
          modules = [
            {
              options.items = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            }
          ];
        };
        default = { };
      };
    };
in
{
  flake.tests.den-policy = {

    # PARKED-DIVERGENCE (genuine den-hoag-vs-den value mismatch → owner gate): v1 expected "provided-host"
    # (`den.lib.policy.provide { class; module; }`, path=[] merge, delivered from a `den.default.includes`
    # policy — the SAME firing shape `policies.nix` `test-policy-fires` proves works for `policy.include`);
    # den-hoag actual "nixos" — the provide descriptor evaluates cleanly (no throw) but delivers NOTHING;
    # `networking.hostName` stays at its class default. Looks like `policy.provide`'s deliver descriptor is
    # silently dropped rather than materialized (root cause unconfirmed — left for owner adjudication).
    # test-provide-direct = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.policies.provide-direct =
    #       { host, ... }:
    #       [
    #         (den.lib.policy.provide {
    #           class = host.class;
    #           module = {
    #             networking.hostName = "provided-host";
    #           };
    #         })
    #       ];
    #
    #     den.default.includes = [ den.policies.provide-direct ];
    #
    #     den.aspects.igloo = { };
    #
    #     expr = igloo.networking.hostName;
    #     expected = "provided-host";
    #   }
    # );

    # BLOCKED-WSB (missing/broken surface): `policy.provide` with a non-empty `path` (nest mode).
    # Empirically confirmed: forcing `igloo.provide-box.items` throws `The option provide-box.system does
    # not exist` — the nested submodule at the provide path appears to receive the HOST schema type
    # (`defaults.nixos` stateVersion merge lands there), not the plain `mkListSubmodule` type declared at
    # `nixos.imports`. Path-based `provide` is not correctly wired to the target submodule.
    # test-provide-with-path = denTest (
    #   { den, igloo, lib, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.policies.provide-with-path =
    #       { host, ... }:
    #       [
    #         (den.lib.policy.provide {
    #           class = host.class;
    #           module.items = [ "from-provide" ];
    #           path = [ "provide-box" ];
    #         })
    #       ];
    #
    #     den.default.includes = [ den.policies.provide-with-path ];
    #
    #     den.aspects.igloo = {
    #       nixos.imports = [ (mkListSubmodule "provide-box") ];
    #       nixos.provide-box.items = [ "from-aspect" ];
    #     };
    #
    #     expr = lib.sort (a: b: a < b) igloo.provide-box.items;
    #     expected = [
    #       "from-aspect"
    #       "from-provide"
    #     ];
    #   }
    # );

    # BLOCKED-WSB: same path-based `provide` symptom as test-provide-with-path, composed with `policy.route`.
    # test-provide-with-route = denTest (
    #   { den, igloo, lib, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.classes.extra.description = "Extra source class";
    #
    #     den.policies.provide-and-route =
    #       { host, ... }:
    #       [
    #         (den.lib.policy.provide {
    #           class = host.class;
    #           module.items = [ "from-provide" ];
    #           path = [ "combo-box" ];
    #         })
    #         (den.lib.policy.route {
    #           fromClass = "extra";
    #           intoClass = host.class;
    #           path = [ "combo-box" ];
    #         })
    #       ];
    #
    #     den.default.includes = [ den.policies.provide-and-route ];
    #
    #     den.aspects.igloo = {
    #       nixos.imports = [ (mkListSubmodule "combo-box") ];
    #       nixos.combo-box.items = [ "from-aspect" ];
    #       extra.items = [ "from-route" ];
    #     };
    #
    #     expr = lib.sort (a: b: a < b) igloo.combo-box.items;
    #     expected = [
    #       "from-aspect"
    #       "from-provide"
    #       "from-route"
    #     ];
    #   }
    # );

    # BLOCKED-WSB (missing surface): the resolved `host` ctx object has no `.users` accessor. Empirically
    # confirmed: forcing `host.users` throws `attribute 'users' missing` (inside `den.policies.user-routing`,
    # before `policy.resolve`/`policy.provide` are even reached).
    # test-provide-cross-class = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.aspects.igloo = { };
    #
    #     den.policies.user-routing =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) resolve include;
    #       in
    #       map (user: resolve { inherit user; }) (builtins.attrValues host.users)
    #       ++ [
    #         (include den.policies.provide-cross-class)
    #       ];
    #
    #     den.policies.provide-cross-class =
    #       { host, user, ... }:
    #       [
    #         (den.lib.policy.provide {
    #           class = "homeManager";
    #           module = {
    #             programs.direnv.enable = true;
    #           };
    #         })
    #       ];
    #
    #     den.default.includes = [ den.policies.user-routing ];
    #
    #     expr = tuxHm.programs.direnv.enable;
    #     expected = true;
    #   }
    # );

  };
}
