# Law A1 zero-machinery source tripwire. den-hoag writes only wiring glue; every
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
  # The scan set is DERIVED from the tree (`_lib/core-files.nix`), shared with boundary.nix and
  # end-to-end.nix. It used to be a hand-written copy of boundary.nix's list, and it silently fell 17
  # files behind: a new kernel file was simply not named here, so it was NOT SCANNED and this suite
  # stayed green — a tripwire that keeps reporting success over a shrinking fraction of the kernel is
  # worse than none, because the coverage it claims never visibly drops.
  libFiles = import ./_lib/core-files.nix { inherit denHoagSrc nixpkgsLib; };
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
