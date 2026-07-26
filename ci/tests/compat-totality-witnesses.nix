# Two witnesses for the closed-gate totality dissolution (design §9.5, §2.1).
#
# (1) LAZINESS — an UNRESOLVED typo aspect must not abort the build. With the raw discriminator retired and the
#     closed gate unmasked, a typo throws when its typed value is forced; the per-reached-aspect content force
#     (class-modules) + the static aspect-include walk's readiness-guard together ensure the force reaches only
#     RESOLVED aspects, so a fleet that declares a typo aspect it never includes still builds. A typo aborts
#     only when its aspect is actually resolved (the resolved case is covered by compat-nested-aspects).
#
# (2) CLASS-SET RECONCILIATION — the static typed-tree gate keys the fleet's declared class vocabulary; the
#     parametric-result gate must share the SAME vocabulary (`builtinClasses` includes the ambient legacy
#     battery classes `os`/`user`), or a parametric result authoring an `os`/`user` bucket would type-throw on
#     the parametric gate while the static path admits it. This witnesses BOTH paths admit an `os`/`user` bucket.
{ denCompat, ... }:
let
  # A parametric aspect compiles to a `__isWrappedFn` functor; firing it routes its result through the
  # parametric-result gate. The ctx carries the coords a `{ host, ... }:` body binds.
  fireParam =
    body:
    let
      para =
        (denCompat.compile {
          aspects.p = body;
          hosts.x86_64-linux.h.class = "nixos";
        }).aspects.p;
    in
    para {
      host = { };
      user = { };
      settings = { };
      aspects = { };
    };
  builds = e: (builtins.tryEval (builtins.deepSeq e true)).success;

  # (1) `bad` (a scalar typo) is declared but NEVER included; only `good` is resolved.
  lazyTypoFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects.good.nixos.ok = true;
          aspects.bad.nixxos = "x";
          hosts.x86_64-linux.h.class = "nixos";
          schema.host.includes = [ "good" ];
        };
      }
    ]).den;

  # (2) an `os` (battery-class) bucket on a STATIC aspect and on a PARAMETRIC result — both must be recognized
  # as a class bucket by their respective gate (not recursed as a freeform namespace whose leaf throws).
  staticOsCompiled = denCompat.compile {
    aspects.a.os.enable = true;
    hosts.x86_64-linux.h.class = "nixos";
  };
in
{
  flake.tests.compat-totality-witnesses = {
    test-unresolved-typo-does-not-abort-build = {
      expr = builds (builtins.attrNames (lazyTypoFleet.output.systems.nixos or { }));
      expected = true;
    };
    # the static typed-tree gate admits an `os` class bucket (recognized, not a freeform typo).
    test-static-os-class-bucket-admits = {
      expr = builds (staticOsCompiled.aspects.a.os or "ABSENT");
      expected = true;
    };
    # the parametric-result gate admits an `os` class bucket — the reconciliation (builtinClasses += os/user).
    test-parametric-os-class-bucket-admits = {
      expr = builds (fireParam ({ host, ... }: { os.enable = true; }));
      expected = true;
    };
    # the parametric gate STILL throws on a genuine scalar typo (the reconciliation didn't loosen the gate).
    test-parametric-scalar-typo-still-throws = {
      expr = builds (fireParam ({ host, ... }: { nixxos = "x"; }));
      expected = false;
    };
  };
}
