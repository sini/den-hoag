# THE kernel core file set — `lib/` MINUS `lib/compat/`, DERIVED from the source tree by `readDir`.
#
# WHY THIS IS ONE FILE AND NOT THREE LISTS. Three source-scanning guards need this set: the compat/core
# boundary tripwire (boundary.nix), the Law A1 zero-machinery tripwire (zero-machinery.nix) and the
# fixpoint census (end-to-end.nix). Each carried its own hand-written copy, and only ONE of the three
# was checked against the tree. Adding `lib/coordinates.nix` measured the consequence: boundary went red
# and named the omission, while the other two simply did not scan the new file and stayed GREEN.
#
# That is the failure mode this project rejects — not "a list went stale", but a guard that keeps
# REPORTING SUCCESS while covering less than it claims. A scan set that omits a file is indistinguishable
# from a scan set over which that file is clean, so the coverage gap grows silently with every kernel file
# added and the rising green count reads as rising assurance.
#
# So the scan set is DERIVED, once, here. A new kernel file is scanned by all three guards the moment it
# exists, with no list to remember. boundary.nix additionally keeps a CHECKED-IN `coreFiles` declaration
# asserted equal to this set — that list is no longer any guard's scan input; its one remaining job is to
# make adding a kernel file force a visible, reviewed edit. A review trigger and a scan set are different
# obligations, and conflating them is what let the scans quietly under-cover.
#
# `lib/compat/**` is EXCLUDED: it is the shim, the thing the core is measured against. Every other
# directory under `lib/` is walked recursively, so a new subdirectory needs no edit either.
{
  denHoagSrc,
  nixpkgsLib,
}:
let
  isNix = n: nixpkgsLib.hasSuffix ".nix" n;
  walk =
    rel:
    let
      entries = builtins.readDir "${denHoagSrc}/lib/${rel}";
    in
    builtins.concatMap (
      n:
      if entries.${n} == "directory" then
        (if rel == "" && n == "compat" then [ ] else walk "${rel}${n}/")
      else if isNix n then
        [ "${rel}${n}" ]
      else
        [ ]
    ) (builtins.attrNames entries);
in
walk ""
