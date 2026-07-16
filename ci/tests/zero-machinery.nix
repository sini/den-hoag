# Task 2 — Law A1 zero-machinery source tripwire. den-hoag writes only wiring glue; every
# algorithm is a named lib call. This scans the lib source text for the hand-rolled-machinery
# markers a review would flag: no `builtins.genericClosure`, no `lib.fix`/`prelude.fix`
# fixpoint of its own. It is a TRIPWIRE, documented as a reviewer checklist — not a proof
# (a bespoke `rec`-fold with none of these tokens would slip through; code review owns that).
{
  genPrelude,
  denHoagSrc,
  nixpkgsLib,
  ...
}:
let
  libFiles = [
    "default.nix"
    "errors.nix"
    "entity.nix"
    "fleet.nix"
    "build-roots.nix"
    "scope-adapter.nix"
    "declarations.nix"
    "concern-policies.nix"
    "concern-aspects.nix"
    "concern-quirks.nix"
    "concern-classes.nix"
    "linearization.nix"
    "settings.nix"
    "projects.nix"
    "demand.nix"
    "graph-escape.nix"
    "attributes/default.nix"
    "attributes/structural.nix"
    "attributes/resolved-aspects.nix"
    "attributes/collections.nix"
    "attributes/resolved-settings.nix"
    "attributes/class-modules.nix"
    "attributes/output-modules.nix"
    "output/terminal.nix"
    "output/class-share.nix"
  ];
  forbidden = [
    "builtins.genericClosure"
    "lib.fix"
    "prelude.fix"
  ];
  read = f: builtins.readFile "${denHoagSrc}/lib/${f}";
  # every (file, forbidden-token) pair that appears — must be empty.
  offenders = builtins.concatMap (
    f:
    let
      t = read f;
    in
    map (tok: "${f}:${tok}") (builtins.filter (tok: genPrelude.hasInfix tok t) forbidden)
  ) libFiles;
in
{
  flake.tests.zero-machinery = {
    test-no-machinery-tokens = {
      expr = offenders;
      expected = [ ];
    };
  };
}
