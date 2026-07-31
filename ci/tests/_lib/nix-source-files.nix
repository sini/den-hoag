# EVERY `.nix` source file in the tree, DERIVED by a recursive `readDir` walk from the repo root.
#
# Distinct from `core-files.nix`, which derives the KERNEL set (`lib/` minus `lib/compat/`) for the
# guards that measure the kernel against the shim. A rule about how source text is WRITTEN has no such
# boundary — a stale reference rots identically in a kernel file, in the shim, in a suite and in the
# parity harness — so its domain is the whole tree. It is derived here for exactly the reason
# `core-files.nix` gives: a hand-listed scan set omits files silently, and a scan covering less than it
# claims still reports green, so the coverage gap grows while the passing count rises.
#
# DOT-PREFIXED ENTRIES ARE SKIPPED, and that is load-bearing rather than cosmetic. The flake input is a
# `path:` copy of the working tree, so it can carry `.git`, `.direnv`, `.beads` (the tracker's export)
# and `.worktrees` (in-flight checkouts of THIS repo, whose files would otherwise be scanned as though
# they were the tree, making a scan's result depend on what happens to be checked out beside it). None
# of those are source, a leading `.` is the one property they share, and skipping on it needs no list.
{
  denHoagSrc,
  nixpkgsLib,
}:
let
  isNix = n: nixpkgsLib.hasSuffix ".nix" n;
  isHidden = n: nixpkgsLib.hasPrefix "." n;
  walk =
    rel:
    let
      entries = builtins.readDir "${denHoagSrc}/${rel}";
    in
    builtins.concatMap (
      n:
      if isHidden n then
        [ ]
      else if entries.${n} == "directory" then
        walk "${rel}${n}/"
      else if isNix n then
        [ "${rel}${n}" ]
      else
        [ ]
    ) (builtins.attrNames entries);
in
walk ""
