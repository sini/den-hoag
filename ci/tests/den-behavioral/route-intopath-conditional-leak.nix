# den v1 BEHAVIORAL migration — deadbugs/route-intopath-conditional-leak.nix (denful/den templates/ci/
# modules/deadbugs/route-intopath-conditional-leak.nix). Migrated by copy + arg-rename onto the
# `_lib/den-compat-test.nix` scaffold; the `den.*` declarations + the assertions are BYTE-IDENTICAL to v1.
# Concern: `route` (two related bugs in `policy.route`'s `intoPath` — den v1's forward-style target-path
# name — surfaced by a guarded route).
#
# Bug 1 (route/wrap.nix `guardModule`): a guarded route whose guard is false
# crashed with
#   error: The option `_file' does not exist. Definition values:
#     { _type = "if"; condition = false; content = "foo@igloo"; }
# because the raw collector module `{ key; _file; imports }` was merged under
# `config` (metadata mis-read as options) and gated with `mkIf` (which still
# requires the target option to exist). Fixed by gating with `optionalAttrs`
# (matching the forward path) and recursing into structural imports.
#
# Bug 2 (policy-effects.nix `route`): `intoPath` was silently dropped — only
# `path` was read — so content landed at the class root instead of nesting.
# Fixed by accepting `intoPath` as the public alias for `path`.
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
  mkBox =
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
  flake.tests.den-route = {

    # BLOCKED-WSB (surface-shape mismatch, throw): `expected a list but found a set: { __delivery = true;
    # … }` — v1 accepts a policy body returning a BARE single-effect record (not list-wrapped);
    # den-hoag's compat strictly requires a list. Every OTHER migrated route.nix case wraps its
    # `den.lib.policy.route {...}` in `[ ... ]`; this deadbug's own v1 shape does not. Left in place,
    # commented, per the parking rule (never altered to route around the gap — wrapping it in a list
    # would no longer be testing what this deadbug tests).
    # test-guarded-route-skips-cleanly-regression-route-intopath-conditional-leak = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo = { };
    #     den.classes.foo.description = "foo class";
    #
    #     den.policies.foo-to-host =
    #       { host, ... }:
    #       den.lib.policy.route {
    #         fromClass = "foo";
    #         intoClass = host.class;
    #         intoPath = [ "foo" ];
    #         guard = { options, ... }: options ? foo;
    #       };
    #
    #     den.schema.host.includes = [ den.policies.foo-to-host ];
    #
    #     den.aspects.igloo.foo.bar = "baz";
    #
    #     expr = igloo ? foo;
    #     expected = false;
    #   }
    # );

    # BLOCKED-WSB (same bare-record-vs-list surface-shape mismatch as
    # test-guarded-route-skips-cleanly-regression-route-intopath-conditional-leak above).
    # test-intopath-nests-regression-route-intopath-conditional-leak = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.classes.src.description = "src class";
    #
    #     den.policies.src-to-host =
    #       { host, ... }:
    #       den.lib.policy.route {
    #         fromClass = "src";
    #         intoClass = host.class;
    #         intoPath = [ "wrapper" ];
    #       };
    #
    #     den.default.includes = [ den.policies.src-to-host ];
    #
    #     den.aspects.igloo = {
    #       nixos.imports = [ (mkBox "wrapper") ];
    #       src.items = [ "routed" ];
    #     };
    #
    #     expr = igloo.wrapper.items;
    #     expected = [ "routed" ];
    #   }
    # );

  };
}
