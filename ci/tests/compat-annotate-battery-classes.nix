# #67 (ledger u17) — BATTERY-REGISTERED classes are excluded from the `__provider` annotation walk,
# exactly like the built-ins. v1's exclusion guard reads the fleet's REGISTERED `den.classes` (pin
# 11866c16 nix/lib/aspects/types.nix:540 `classReg = den.classes or { }`, consumed by `annotatedMerged`
# :559-574), and v1 always-imports the battery modules, so `os`/`user` are registered before any
# annotation runs — a v1 `os` class body is never stamped. The shim's walk runs on the PRE-desugar
# surface (bridge annotatedDen / flake-module annotatedView), where the battery desugar has not yet
# added os/user to `den.classes` — so the battery names are BAKED into the walker (annotate.nix
# `batteryClassNames`, static `registersClasses` data). Without the bake, the stamped os body reached
# the real nixpkgs terminal once #66 routed the delivered os content there: `The option __provider does
# not exist` (the u17 re-probe frontier).
#
# Witnesses:
#   (1) an `os`-keyed class body is NOT `__provider`-stamped (walk unit + the end-to-end mkDen
#       class-modules bucket — the value the #66 terminal gather delivers);
#   (2) a `user`-keyed body likewise (the os-user battery's class);
#   (3) a NON-class aspect/namespace key still gets its stamp — the #58 include-identity mechanism
#       is unbroken (the non-vacuous companion);
#   (4) the built-in exclusion is unchanged (a `nixos` body is not stamped, before and after).
{ denCompat, ... }:
let
  annotate = denCompat.annotateAspects {
    classNames = [ ];
    quirkNames = [ ];
  };

  # ── walk units: one aspect tree carrying a battery-class body, a built-in-class body, and a nested
  #    namespace child. Only the namespace child is a stamping candidate. ──
  annotated = annotate {
    mixed = {
      os.progB.enable = true; # battery class (os-class registersClasses) — excluded
      user.someUser = { }; # battery class (os-user registersClasses) — excluded
      nixos.progA.enable = true; # den-hoag built-in — excluded (unchanged)
      nested.child = { }; # unregistered namespace — STAMPED (the #58 mechanism)
    };
  };

  # ── end-to-end: the mkDen path (annotatedView → compile → class-modules). The os bucket module is
  #    the exact value the #66 terminal gather delivers to the nixpkgs terminal — it must be clean. ──
  fleet = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.igloo.class = "nixos";
      den.aspects.mixed = {
        nixos.progA.enable = true;
        os.progB.enable = true;
      };
      den.schema.host.includes = [ "mixed" ];
    }
  ];
  cm = fleet.den.structural.eval.get "host:igloo" "class-modules";
  bucketKeys = cls: builtins.concatMap builtins.attrNames (cm.${cls} or [ ]);
in
{
  flake.tests.compat-annotate-battery-classes = {
    # (1) the os body is not stamped — and not recursed into (progB stays untouched).
    test-os-body-not-stamped = {
      expr = annotated.mixed.os ? __provider;
      expected = false;
    };
    test-os-interior-not-recursed = {
      expr = annotated.mixed.os.progB ? __provider;
      expected = false;
    };
    # (2) the user body is not stamped (the os-user battery's class).
    test-user-body-not-stamped = {
      expr = annotated.mixed.user ? __provider;
      expected = false;
    };
    # (3) a NON-class namespace child still gets its provenance path — #58 identity unbroken.
    test-non-class-key-still-stamped = {
      expr = annotated.mixed.nested.__provider or null;
      expected = [
        "mixed"
        "nested"
      ];
    };
    # …and its interior keeps recursing (the walk's namespace behavior unchanged).
    test-non-class-interior-still-stamped = {
      expr = annotated.mixed.nested.child.__provider or null;
      expected = [
        "mixed"
        "nested"
        "child"
      ];
    };
    # (4) the built-in exclusion unchanged.
    test-builtin-body-not-stamped = {
      expr = annotated.mixed.nixos ? __provider;
      expected = false;
    };

    # end-to-end: the class-modules buckets the terminal reads are stamp-free — the os bucket carries
    # ONLY the content key (pre-#67 it was [ __provider progB ], the u17 terminal abort), the nixos
    # bucket is unchanged.
    test-e2e-os-bucket-clean = {
      expr = bucketKeys "os";
      expected = [ "progB" ];
    };
    test-e2e-nixos-bucket-unchanged = {
      expr = bucketKeys "nixos";
      expected = [ "progA" ];
    };
  };
}
