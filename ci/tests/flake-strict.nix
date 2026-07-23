# den v1 `flakeModules.strict` witness (denful/den nix/strict.nix + templates/ci/modules/public-api/
# strict.nix). den-hoag exposes `flakeModules.strict` (flake.nix → lib/compat/flake-strict.nix): an opt-in
# flake-parts module that puts every den schema kind into STRICT mode via `den.schema.<kind>.imports =
# [ den.lib.strict ]` — an entity option set with no explicit declaration aborts (`den.lib.strict`, the
# freeform-throw module, lib/compat/strict.nix). Consumer-eval, additive; nothing in den-hoag's own CI
# imports it, so parity is untouched — this synthetic witness is its only exercise.
#
# A MINIMAL flake-parts eval through den-hoag's real `flakeModule` (the bridge binds the self-referential
# `den` arg that `flake-strict.nix` reads for `den.lib.strict`) + `flakeModules.strict` + a one-host fleet.
# No nixpkgs crossing — reading the host registry forces the strict freeform on any set option. The full
# denTest scaffold is deliberately NOT used here: its seed modules set host options of their own (the hm
# host-gate's `home-manager.module`), which strict would itself abort — so the witness stays minimal.
{
  denHoagFlakeModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  denHoagSrc,
  ...
}:
let
  flakeParts = genInputs.flake-parts;
  lib = nixpkgsLib;
  strictModule = import "${denHoagSrc}/lib/compat/flake-strict.nix";

  evalDen =
    fleetModule:
    (flakeParts.lib.evalFlakeModule
      {
        inputs = { inherit nixpkgs; };
        self = {
          inputs = { inherit nixpkgs; };
        };
        moduleLocation = "<flake-strict witness>";
      }
      {
        systems = [ "x86_64-linux" ];
        imports = [
          denHoagFlakeModule
          strictModule
          fleetModule
        ];
      }
    ).config;

  # UNDECLARED arm: an option set on a host with no explicit declaration → strict aborts. Empirically the
  # thrown message is `STRICT MODE … Attempted to set the option "arbitrary" in "den.hosts.x86_64-linux.
  # igloo"` (a genuine strict-mode throw, not a freeform-merge conflict — strict's typeMerge absorbs the
  # base entity freeform).
  undeclaredThrows =
    !(builtins.tryEval (
      builtins.deepSeq
        (evalDen { den.hosts.x86_64-linux.igloo.arbitrary = "value"; })
        .den.hosts.x86_64-linux.igloo.arbitrary
        true
    )).success;

  # DECLARED arm: the SAME option, explicitly declared via `den.schema.host.options` → passes strict and
  # resolves to its set value.
  declaredValue =
    (evalDen {
      den.schema.host.options.declaredOpt = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      den.hosts.x86_64-linux.igloo.declaredOpt = "ok";
    }).den.hosts.x86_64-linux.igloo.declaredOpt;
in
{
  flake.tests.flake-strict = {
    # undeclared option → STRICT MODE abort (catchable throw).
    test-strict-undeclared-aborts = {
      expr = undeclaredThrows;
      expected = true;
    };
    # declared option → passes strict + resolves. This arm is the message-equivalent guard: a broken
    # `den.schema.host = den.lib.strict` (bare-fn) form is DROPPED by the schema collector's `filter
    # isAttrs` (so the undeclared arm would NOT abort) or breaks schema processing wholesale (so this
    # declared arm would NOT resolve) — either mis-wiring reddens one of the two arms, so the pair pins the
    # genuine strict wiring rather than a coincidental throw.
    test-strict-declared-passes = {
      expr = declaredValue;
      expected = "ok";
    };
  };
}
